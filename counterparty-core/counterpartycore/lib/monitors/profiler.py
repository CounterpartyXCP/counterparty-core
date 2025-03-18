import cProfile
import logging
import os
import sys
import time
from datetime import datetime

from counterpartycore.lib import config

logger = logging.getLogger(config.LOGGER_NAME)


class Profiler:
    def __init__(self):
        """
        Non-threaded profiler that can be used within a function
        to generate profiling reports at regular intervals
        """
        self.profiler = None
        self.active_profiling = False
        self.last_report_time = None
        logger.info(
            "Profiler initialized with configured interval of %s minutes",
            config.PROFILE_INTERVAL_MINUTES,
        )

    def start(self):
        """Starts a profiling session"""
        if self.active_profiling:
            return

        # Reset any active profiler in Python 3.12+
        try:
            # This disables any active system-wide profiler
            sys.setprofile(None)
        except Exception:  # pylint: disable=broad-exception-caught
            logger.warning("Failed to reset profiler state before starting new profiler")

        try:
            self.profiler = cProfile.Profile()
            self.profiler.enable()
            self.active_profiling = True
            self.last_report_time = time.time()
            logger.info("Profiling session started")
        except ValueError as e:
            logger.error("Error starting profiling: %s", e)
            self.profiler = None

    def stop_and_save(self):
        """Stops the profiling session and generates a report"""
        if not self.active_profiling or self.profiler is None:
            return

        try:
            self.profiler.disable()
        except Exception as e:  # pylint: disable=broad-exception-caught
            logger.error("Error disabling profiler: %s", e)

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        profile_path = os.path.join(config.CACHE_DIR, f"profile_{timestamp}.prof")

        try:
            # Ensure the directory exists
            os.makedirs(os.path.dirname(profile_path), exist_ok=True)

            # Save profiling data
            self.profiler.dump_stats(profile_path)

            # Ensure a file exists even if dump_stats didn't create one (Python 3.12+ compatibility)
            if not os.path.exists(profile_path):
                logger.warning(
                    "No profile file was created by dump_stats, creating a dummy file for compatibility"
                )
                with open(profile_path, "wb") as f:
                    f.write(b"# Empty profile file\n")

            logger.info("Profiling report saved to %s", profile_path)

        except Exception as e:  # pylint: disable=broad-exception-caught
            logger.error("Error generating profiling report: %s", e)

        # Explicitly reset the profiler state
        try:
            sys.setprofile(None)
        except Exception:  # pylint: disable=broad-exception-caught
            logger.warning("Failed to reset profiler state")

        self.profiler = None
        self.active_profiling = False

    def gen_profile_if_needed(self):
        """
        Checks if it's time to generate a profile report based on the configured interval.
        If the interval has elapsed, generates a report and restarts profiling.
        """
        if not self.active_profiling or self.last_report_time is None:
            return

        current_time = time.time()
        elapsed_minutes = (current_time - self.last_report_time) / 60

        # If the interval has elapsed, generate a new report
        if elapsed_minutes >= config.PROFILE_INTERVAL_MINUTES:
            logger.info("Generating profiling report after %s minutes", elapsed_minutes)
            self.stop_and_save()
            self.start()

    def stop(self):
        """Stops profiling completely"""
        logger.info("Stopping profiler...")
        if self.active_profiling:
            self.stop_and_save()
        logger.info("Profiler stopped.")


# Example usage:
"""
def my_function():
    profiler = Profiler()
    profiler.start()
    
    while some_condition:
        # Your code here
        
        # Check if we need to generate a profile report
        profiler.gen_profile_if_needed()
    
    # Final cleanup
    profiler.stop()
"""
