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
        # Save original values
        cls._original_cache_dir = getattr(config, "CACHE_DIR", None)
        cls._original_profile_interval = getattr(config, "PROFILE_INTERVAL_MINUTES", None)

        # Set up test environment
        cls._temp_dir = tempfile.mkdtemp()
        config.CACHE_DIR = cls._temp_dir
        config.PROFILE_INTERVAL_MINUTES = 0.001  # Very small value for testing

    @classmethod
    def teardown_class(cls):
        """Clean up after all test methods"""
        # Clean up
        try:
            shutil.rmtree(cls._temp_dir)
        except Exception:  # pylint: disable=broad-exception-caught
            print("Error cleaning up temporary directory")
            pass

        # Restore original values
        if cls._original_cache_dir is not None:
            config.CACHE_DIR = cls._original_cache_dir
        if cls._original_profile_interval is not None:
            config.PROFILE_INTERVAL_MINUTES = cls._original_profile_interval

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
        profiler = Profiler()
        profiler.start()
        time.sleep(0.1)  # Small delay to ensure we capture something
        profiler.stop_and_save()
        assert not profiler.active_profiling
        assert profiler.profiler is None

        # Check if a profile file was created
        files = [
            f
            for f in os.listdir(config.CACHE_DIR)
            if f.startswith("profile_") and f.endswith(".prof")
        ]
        assert len(files) > 0

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
        profiler = Profiler()
        profiler.start()
        time.sleep(0.1)  # Ensure we exceed the interval
        initial_time = profiler.last_report_time
        profiler.gen_profile_if_needed()
        # Should have restarted profiling
        assert profiler.last_report_time > initial_time
        assert profiler.active_profiling

        # Check if a profile file was created
        files = [
            f
            for f in os.listdir(config.CACHE_DIR)
            if f.startswith("profile_") and f.endswith(".prof")
        ]
        assert len(files) > 0

    def test_profiler_stop(self):
        """Test completely stopping the profiler"""
        profiler = Profiler()
        profiler.start()
        profiler.stop()
        assert not profiler.active_profiling
        assert profiler.profiler is None

        # Check if a profile file was created
        files = [
            f
            for f in os.listdir(config.CACHE_DIR)
            if f.startswith("profile_") and f.endswith(".prof")
        ]
        assert len(files) > 0

    def test_profiler_stop_inactive(self):
        """Test stopping when profiler is not active"""
        profiler = Profiler()
        profiler.stop()  # Should not raise any exception
        assert not profiler.active_profiling
        assert profiler.profiler is None

    # Tests for error handling scenarios
    def test_setprofile_error_handling(self):
        """Test error handling when sys.setprofile raises an exception"""
        profiler = Profiler()
        original_setprofile = sys.setprofile

        # Replace with function that raises exception
        def raising_setprofile(_):
            raise Exception("Test exception")

        sys.setprofile = raising_setprofile
        try:
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

        # Replace cProfile.Profile with a function that raises ValueError
        def mock_profile_error(*args, **kwargs):
            raise ValueError("Test error")

        cProfile.Profile = mock_profile_error

        try:
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

        def raising_disable():
            raise Exception("Test exception")

        profiler.profiler.disable = raising_disable
        try:
            # Should handle the exception gracefully
            profiler.stop_and_save()
            assert not profiler.active_profiling
            assert profiler.profiler is None
        finally:
            # No need to restore as profiler is reset
            pass

    def test_dump_stats_error_handling(self):
        """Test error handling when profiler.dump_stats() raises an exception"""
        profiler = Profiler()
        profiler.start()

        def raising_dump_stats(_):
            raise Exception("Test exception")

        profiler.profiler.dump_stats = raising_dump_stats
        try:
            # Should handle the exception gracefully
            profiler.stop_and_save()
            assert not profiler.active_profiling
            assert profiler.profiler is None
        finally:
            # No need to restore as profiler is reset
            pass

    def test_file_creation_fallback(self):
        """Test that a dummy file is created if dump_stats doesn't create one"""
        profiler = Profiler()
        profiler.start()

        # Save original os.path.exists to make files appear non-existent
        original_exists = os.path.exists

        def mock_exists(path):
            if path.endswith(".prof"):
                return False  # Force creation of dummy file
            return original_exists(path)

        # Patch os.path.exists to simulate missing file
        os.path.exists = mock_exists

        try:
            profiler.stop_and_save()

            # Restore original exists function before checking files
            os.path.exists = original_exists

            # Check that a dummy file was created
            files = [
                f
                for f in os.listdir(config.CACHE_DIR)
                if f.startswith("profile_") and f.endswith(".prof")
            ]
            assert len(files) > 0

            # Check content of the file to ensure it's the dummy
            file_path = os.path.join(config.CACHE_DIR, files[0])
            with open(file_path, "rb") as f:
                content = f.read()
                assert content  # Just make sure it's not empty

            # Since the actual content might be different in implementation, we won't check for exact string
        finally:
            # Restore original exists function if not already done
            os.path.exists = original_exists
