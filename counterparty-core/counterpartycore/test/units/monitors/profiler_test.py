import os
import shutil
import tempfile
import time

from counterpartycore.lib import config
from counterpartycore.lib.monitors.profiler import PeriodicProfilerThread


class TestPeriodicProfilerThread:
    @classmethod
    def setup_class(cls):
        """Prepare the test environment with a temporary folder."""
        # Create a temporary directory for tests
        cls.temp_dir = tempfile.mkdtemp()
        # Save the old CACHE_DIR
        if hasattr(config, "CACHE_DIR"):
            cls.original_cache_dir = config.CACHE_DIR
        else:
            cls.original_cache_dir = None
            config.CACHE_DIR = cls.temp_dir

        # Replace CACHE_DIR with our temporary directory
        config.CACHE_DIR = cls.temp_dir

    @classmethod
    def teardown_class(cls):
        """Clean up the environment after all tests."""
        # Restore the old CACHE_DIR
        if cls.original_cache_dir is not None:
            config.CACHE_DIR = cls.original_cache_dir
        else:
            delattr(config, "CACHE_DIR")

        # Delete the temporary directory
        shutil.rmtree(cls.temp_dir)

    def setup_method(self):
        """Prepare a new instance for each test."""
        # Create a new profiling thread instance for each test
        # Use a very short interval to speed up tests
        self.profiler_thread = PeriodicProfilerThread(
            interval_minutes=0.02
        )  # 0.02 minutes = 1.2 seconds

        # Ensure the cache directory exists
        os.makedirs(config.CACHE_DIR, exist_ok=True)

    def teardown_method(self):
        """Clean up after each test."""
        # Make sure the thread is stopped after each test
        if hasattr(self, "profiler_thread") and self.profiler_thread.is_alive():
            self.profiler_thread.stop()
            self.profiler_thread.join(timeout=1)

        # Clean up created files
        for file in os.listdir(config.CACHE_DIR):
            os.remove(os.path.join(config.CACHE_DIR, file))

    def test_init(self):
        """Test the initialization of the class with a custom interval."""
        assert self.profiler_thread.interval_minutes == 0.02
        assert self.profiler_thread.daemon is True
        assert self.profiler_thread.stop_event.is_set() is False
        assert self.profiler_thread.profiler is None
        assert self.profiler_thread.active_profiling is False

    def test_init_default_interval(self):
        """Test initialization with the default interval."""
        profiler = PeriodicProfilerThread()
        assert profiler.interval_minutes == 15

    def test_start_profiling(self):
        """Test starting profiling."""
        self.profiler_thread.start_profiling()
        assert self.profiler_thread.active_profiling is True
        assert self.profiler_thread.profiler is not None

        # Calling start_profiling again should not change anything
        profiler = self.profiler_thread.profiler
        self.profiler_thread.start_profiling()
        assert self.profiler_thread.profiler is profiler  # same instance

    def test_stop_profiling_and_save(self):
        """Test stopping profiling and generating a report."""
        self.profiler_thread.start_profiling()
        self.profiler_thread.stop_profiling_and_save()

        # Check that a file was created in the cache directory
        files = os.listdir(config.CACHE_DIR)
        assert len(files) == 1
        assert files[0].startswith("profile_") and files[0].endswith(".prof")

        # Check that the profiling state was reset
        assert self.profiler_thread.active_profiling is False
        assert self.profiler_thread.profiler is None

    def test_stop_profiling_and_save_not_active(self):
        """Test stopping profiling when no profiling is active."""
        self.profiler_thread.active_profiling = False
        self.profiler_thread.stop_profiling_and_save()

        # Check that no file was created
        files = os.listdir(config.CACHE_DIR)
        assert len(files) == 0

    def test_stop_profiling_and_save_profiler_none(self):
        """Test stopping profiling when the profiler is None."""
        self.profiler_thread.active_profiling = True
        self.profiler_thread.profiler = None
        self.profiler_thread.stop_profiling_and_save()

        # Check that no file was created
        files = os.listdir(config.CACHE_DIR)
        assert len(files) == 0

    def test_stop_profiling_and_save_with_error(self):
        """Test stopping profiling with an error when writing the file."""
        self.profiler_thread.start_profiling()

        # Save the current directory
        original_cache_dir = config.CACHE_DIR

        try:
            # Replace with a directory that doesn't exist to cause an error
            config.CACHE_DIR = "/path/that/does/not/exist"

            # This should raise an exception but the method is designed to catch it
            self.profiler_thread.stop_profiling_and_save()

            # Check that the state was reset despite the error
            assert self.profiler_thread.active_profiling is False
            assert self.profiler_thread.profiler is None
        finally:
            # Restore the original directory
            config.CACHE_DIR = original_cache_dir

    def test_run_cycle(self):
        """Test the execution cycle of the thread with periodic report generation."""
        # Start the thread
        self.profiler_thread.start()

        # Wait for the thread to start running
        time.sleep(0.1)
        assert self.profiler_thread.is_alive()
        assert self.profiler_thread.active_profiling is True

        # Wait until the interval is well exceeded for a report to be generated
        time.sleep(5)

        # Check that a report file was created
        # If no file is found, display useful diagnostics
        files = os.listdir(config.CACHE_DIR)
        if len(files) == 0:
            print(f"No file found in {config.CACHE_DIR}")
            print(f"Profiler interval: {self.profiler_thread.interval_minutes} minutes")
            print(f"Active profiling: {self.profiler_thread.active_profiling}")
        assert len(files) >= 1, f"No profiling file found in {config.CACHE_DIR}"

        # Wait for another complete cycle to verify the creation of a new report
        time.sleep(1.2)
        new_files = os.listdir(config.CACHE_DIR)
        assert len(new_files) > len(files), (
            f"No new files created. Before: {len(files)}, After: {len(new_files)}"
        )

        # Stop the thread
        self.profiler_thread.stop()

        # Check that the thread is properly stopped
        assert self.profiler_thread.stop_event.is_set() is True
        self.profiler_thread.join(timeout=2)  # Increased timeout
        assert not self.profiler_thread.is_alive()

    def test_stop(self):
        """Test stopping the thread with generation of a final report."""
        # Start the thread
        self.profiler_thread.start()

        # Wait for the thread to start running
        time.sleep(0.1)
        assert self.profiler_thread.is_alive()
        assert self.profiler_thread.active_profiling is True

        # Stop the thread
        self.profiler_thread.stop()

        # Check that the thread is properly stopped
        assert self.profiler_thread.stop_event.is_set() is True
        self.profiler_thread.join(timeout=2)  # Increased timeout
        assert not self.profiler_thread.is_alive()

        # Check that a final report was generated
        files = os.listdir(config.CACHE_DIR)
        if len(files) == 0:
            print(f"No file found in {config.CACHE_DIR} after stop()")
        assert len(files) >= 1, f"No profiling file found in {config.CACHE_DIR} after stop()"

    def test_stop_without_active_profiling(self):
        """Test stopping the thread when no profiling is active."""
        # Ensure the cache directory is empty at the start of the test
        for file in os.listdir(config.CACHE_DIR):
            os.remove(os.path.join(config.CACHE_DIR, file))

        # Start the thread
        self.profiler_thread.start()

        # Wait for the thread to start running
        time.sleep(0.1)
        assert self.profiler_thread.is_alive()

        # Modify the state to simulate inactive profiling
        self.profiler_thread.active_profiling = False

        # Wait a bit to ensure the thread has taken the change into account
        time.sleep(0.1)

        # Stop the thread
        self.profiler_thread.stop()

        # Check that the thread is properly stopped
        assert self.profiler_thread.stop_event.is_set() is True
        self.profiler_thread.join(timeout=2)
        assert not self.profiler_thread.is_alive()

        # Check that no final report was generated
        files = os.listdir(config.CACHE_DIR)
        assert len(files) == 0, f"Files were found when none were expected: {files}"
