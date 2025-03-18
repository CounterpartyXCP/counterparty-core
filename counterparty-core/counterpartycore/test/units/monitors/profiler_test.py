import cProfile
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

    def test_profiler_start(self):
        """Test starting the profiler"""
        profiler = Profiler()
        profiler.start()
        assert profiler.profiler is not None
        assert profiler.active_profiling
        assert profiler.last_report_time is not None

    def test_profiler_start_already_active(self):
        """Test starting the profiler when it's already active"""
        profiler = Profiler()
        profiler.start()
        initial_time = profiler.last_report_time
        time.sleep(0.1)  # Small delay
        profiler.start()  # Call start again
        # Should remain the same since we're already profiling
        assert profiler.last_report_time == initial_time

    def test_profiler_stop_and_save(self):
        """Test stopping and saving the profiler data"""
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

    def test_setprofile_error_handling(self):
        """Test error handling when sys.setprofile raises an exception"""
        profiler = Profiler()
        original_setprofile = sys.setprofile

        # Replace with function that raises exception
        def raising_setprofile(_):
            raise Exception("Test exception")

        try:
            sys.setprofile = raising_setprofile
            # Should handle the exception gracefully
            profiler.start()
            assert profiler.active_profiling
        finally:
            # Restore original function
            sys.setprofile = original_setprofile

    def test_profile_creation_error(self):
        """Test error handling when cProfile.Profile raises ValueError"""
        profiler = Profiler()

        # Save original cProfile.Profile to restore later
        original_profile = cProfile.Profile

        try:
            # Replace cProfile.Profile with a function that raises ValueError
            def mock_profile_error(*args, **kwargs):
                raise ValueError("Test error")

            cProfile.Profile = mock_profile_error

            # This should not raise an exception - error should be caught
            profiler.start()
            # Verify error was handled properly
            assert not profiler.active_profiling
            assert profiler.profiler is None
        finally:
            # Restore original Profile
            cProfile.Profile = original_profile

    def test_disable_error_handling(self):
        """Test error handling when profiler.disable() raises an exception"""
        profiler = Profiler()
        profiler.start()

        try:

            def raising_disable():
                raise Exception("Test exception")

            profiler.profiler.disable = raising_disable

            # Should handle the exception gracefully
            profiler.stop_and_save()
            assert not profiler.active_profiling
            assert profiler.profiler is None
        finally:
            # No restoration needed as the profiler object is reset
            pass

    def test_dump_stats_error_handling(self):
        """Test error handling when profiler.dump_stats() raises an exception"""
        profiler = Profiler()
        profiler.start()

        try:

            def raising_dump_stats(_):
                raise Exception("Test exception")

            profiler.profiler.dump_stats = raising_dump_stats

            # Should handle the exception gracefully
            profiler.stop_and_save()
            assert not profiler.active_profiling
            assert profiler.profiler is None
        finally:
            # No restoration needed as the profiler object is reset
            pass

    def test_file_creation_fallback(self):
        """Test that a dummy file is created if dump_stats doesn't create one"""
        # Ensure directory exists
        os.makedirs(config.CACHE_DIR, exist_ok=True)

        profiler = Profiler()
        profiler.start()

        # Save original os.path.exists
        original_exists = os.path.exists

        try:
            # Mock os.path.exists to simulate missing profile file
            def mock_exists(path):
                if path.endswith(".prof"):
                    return False
                return original_exists(path)

            os.path.exists = mock_exists

            # Execute the stop_and_save method
            profiler.stop_and_save()

            # Restore original os.path.exists before checking
            os.path.exists = original_exists

            # Check if profile files exist
            files = [
                f
                for f in os.listdir(config.CACHE_DIR)
                if f.startswith("profile_") and f.endswith(".prof")
            ]
            assert len(files) > 0, (
                f"No profile files found in {config.CACHE_DIR}: {os.listdir(config.CACHE_DIR)}"
            )
        finally:
            # Ensure original function is restored
            os.path.exists = original_exists
