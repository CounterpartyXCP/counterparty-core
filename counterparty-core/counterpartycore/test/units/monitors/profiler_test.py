import os
import shutil
import sys
import tempfile
import time

# Import the module to test
from counterpartycore.lib import config
from counterpartycore.lib.monitors.profiler import Profiler


class TestProfiler:
    """
    Test suite for the Profiler class
    """

    @classmethod
    def setup_class(cls):
        """Set up test environment once for all test methods"""
        # Save original profile interval
        cls._original_profile_interval = getattr(config, "PROFILE_INTERVAL_MINUTES", None)
        # Set very small interval for testing
        config.PROFILE_INTERVAL_MINUTES = 0.001  # Very small value for testing

    @classmethod
    def teardown_class(cls):
        """Clean up after all test methods"""
        # Restore original profile interval
        if cls._original_profile_interval is not None:
            config.PROFILE_INTERVAL_MINUTES = cls._original_profile_interval

    def setup_method(self, method):
        """Set up the test environment before each test method"""
        # Create a unique temp directory for each test
        self._test_temp_dir = tempfile.mkdtemp()
        # Save the original CACHE_DIR
        self._original_test_cache_dir = getattr(config, "CACHE_DIR", None)
        # Set the test-specific CACHE_DIR
        config.CACHE_DIR = self._test_temp_dir

    def teardown_method(self, method):
        """Clean up after each test method"""
        # Restore original CACHE_DIR
        if self._original_test_cache_dir is not None:
            config.CACHE_DIR = self._original_test_cache_dir
        # Clean up the test-specific temp directory
        try:
            shutil.rmtree(self._test_temp_dir)
        except Exception:
            print(f"Failed to remove temp directory: {self._test_temp_dir}")
            pass

    def test_profiler_init(self):
        """Test Profiler initialization"""
        profiler = Profiler()
        assert profiler.profiler is None
        assert not profiler.active_profiling
        assert profiler.last_report_time is None

        # Check Python version-specific behavior
        if sys.version_info >= (3, 12):
            assert profiler._is_supported is False
        else:
            assert profiler._is_supported is True

    def test_profiler_start(self):
        """Test starting the profiler"""
        # Skip test on Python 3.12+
        if sys.version_info >= (3, 12):
            return

        profiler = Profiler()
        profiler.start()
        assert profiler.profiler is not None
        assert profiler.active_profiling
        assert profiler.last_report_time is not None

    def test_profiler_start_already_active(self):
        """Test starting the profiler when it's already active"""
        # Skip test on Python 3.12+
        if sys.version_info >= (3, 12):
            return

        profiler = Profiler()
        profiler.start()
        initial_time = profiler.last_report_time
        time.sleep(0.1)  # Small delay
        profiler.start()  # Call start again
        # Should remain the same since we're already profiling
        assert profiler.last_report_time == initial_time

    def test_profiler_stop_and_save(self):
        """Test stopping and saving the profiler data"""
        # Skip test on Python 3.12+
        if sys.version_info >= (3, 12):
            return

        # Ensure directory exists
        os.makedirs(config.CACHE_DIR, exist_ok=True)

        profiler = Profiler()
        profiler.start()
        time.sleep(0.1)  # Small delay to ensure we capture something

        # Execute the function
        profiler.stop_and_save()

        assert not profiler.active_profiling
        assert profiler.profiler is None

        # Check if profile files exist
        files = [
            f
            for f in os.listdir(config.CACHE_DIR)
            if f.startswith("profile_") and f.endswith(".prof")
        ]

        assert len(files) > 0, (
            f"No profile files found in {config.CACHE_DIR}: {os.listdir(config.CACHE_DIR)}"
        )

    def test_profiler_stop_and_save_inactive(self):
        """Test stopping and saving when profiler is not active"""
        profiler = Profiler()
        profiler.stop_and_save()  # Should not raise any exception
        assert not profiler.active_profiling
        assert profiler.profiler is None

    def test_profiler_gen_profile_if_needed_inactive(self):
        """Test generating profile when profiler is not active"""
        profiler = Profiler()
        profiler.gen_profile_if_needed()  # Should not do anything
        assert not profiler.active_profiling

    def test_profiler_gen_profile_if_needed_not_elapsed(self):
        """Test generating profile when interval hasn't elapsed"""
        # Skip test on Python 3.12+
        if sys.version_info >= (3, 12):
            return

        profiler = Profiler()
        profiler.start()
        old_interval = config.PROFILE_INTERVAL_MINUTES
        config.PROFILE_INTERVAL_MINUTES = 60  # Set to a large value
        initial_time = profiler.last_report_time
        profiler.gen_profile_if_needed()
        # Nothing should change
        assert profiler.last_report_time == initial_time
        assert profiler.active_profiling
        config.PROFILE_INTERVAL_MINUTES = old_interval  # Restore original value

    def test_profiler_gen_profile_if_needed_elapsed(self):
        """Test generating profile when interval has elapsed"""
        # Skip test on Python 3.12+
        if sys.version_info >= (3, 12):
            return

        # Ensure directory exists
        os.makedirs(config.CACHE_DIR, exist_ok=True)

        profiler = Profiler()
        profiler.start()
        time.sleep(0.1)  # Ensure we exceed the interval
        initial_time = profiler.last_report_time

        # Execute the function
        profiler.gen_profile_if_needed()

        # Should have restarted profiling
        assert profiler.last_report_time > initial_time
        assert profiler.active_profiling

        # Check if profile files exist
        files = [
            f
            for f in os.listdir(config.CACHE_DIR)
            if f.startswith("profile_") and f.endswith(".prof")
        ]
        assert len(files) > 0, (
            f"No profile files found in {config.CACHE_DIR}: {os.listdir(config.CACHE_DIR)}"
        )

    def test_profiler_stop(self):
        """Test completely stopping the profiler"""
        # Skip test on Python 3.12+
        if sys.version_info >= (3, 12):
            return

        # Ensure directory exists
        os.makedirs(config.CACHE_DIR, exist_ok=True)

        profiler = Profiler()
        profiler.start()

        # Execute the function
        profiler.stop()

        assert not profiler.active_profiling
        assert profiler.profiler is None

        # Check if profile files exist
        files = [
            f
            for f in os.listdir(config.CACHE_DIR)
            if f.startswith("profile_") and f.endswith(".prof")
        ]
        assert len(files) > 0, (
            f"No profile files found in {config.CACHE_DIR}: {os.listdir(config.CACHE_DIR)}"
        )

    def test_profiler_stop_inactive(self):
        """Test stopping when profiler is not active"""
        profiler = Profiler()
        profiler.stop()  # Should not raise any exception
        assert not profiler.active_profiling
        assert profiler.profiler is None

    def test_py312_compatibility(self):
        """Test that profiler gracefully handles Python 3.12+ environments"""
        if sys.version_info >= (3, 12):
            profiler = Profiler()
            # Should be disabled on Python 3.12+
            assert profiler._is_supported is False

            # All operations should be no-ops
            profiler.start()
            assert profiler.active_profiling is False

            profiler.stop_and_save()  # Should not raise exceptions
            profiler.gen_profile_if_needed()  # Should not raise exceptions
            profiler.stop()  # Should not raise exceptions
