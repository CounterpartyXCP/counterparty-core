import cProfile
import logging
import os
import threading
import time
from datetime import datetime

from counterpartycore.lib import config

logger = logging.getLogger(config.LOGGER_NAME)


class PeriodicProfilerThread(threading.Thread):
    def __init__(self, interval_minutes=15):
        """
        Thread to generate profiling reports at regular intervals

        Args:
            interval_minutes (int): Interval in minutes between each profiling report
        """
        threading.Thread.__init__(self, name="PeriodicProfiler")
        self.daemon = True
        self.interval_minutes = interval_minutes
        self.stop_event = threading.Event()
        self.profiler = None
        self.active_profiling = False
        logger.info(
            "Periodic profiler initialized with an interval of %s minutes", interval_minutes
        )

    def start_profiling(self):
        """Starts a profiling session"""
        if self.active_profiling:
            return

        self.profiler = cProfile.Profile()
        self.profiler.enable()
        self.active_profiling = True
        logger.info("Profiling session started")

    def stop_profiling_and_save(self):
        """Stops the profiling session and generates a report"""
        if not self.active_profiling or self.profiler is None:
            return

        self.profiler.disable()
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        profile_path = os.path.join(config.CACHE_DIR, f"profile_{timestamp}.prof")

        try:
            # Ensure the directory exists
            os.makedirs(os.path.dirname(profile_path), exist_ok=True)

            # Save profiling data
            self.profiler.dump_stats(profile_path)
            logger.info(f"Profiling report saved to {profile_path}")

        except Exception as e:
            logger.error(f"Error generating profiling report: {e}")

        self.profiler = None
        self.active_profiling = False

    def run(self):
        """Runs the periodic profiling thread"""
        self.start_profiling()
        last_report_time = time.time()

        while not self.stop_event.is_set():
            current_time = time.time()
            elapsed_minutes = (current_time - last_report_time) / 60

            # If the interval has elapsed, generate a new report
            if elapsed_minutes >= self.interval_minutes:
                logger.info(f"Generating profiling report after {elapsed_minutes:.2f} minutes")
                self.stop_profiling_and_save()
                self.start_profiling()
                last_report_time = time.time()

            # Adjust sleep time based on interval for better precision with short intervals
            # Small intervals get shorter sleep times for more frequent checks
            sleep_time = min(1.0, max(0.1, self.interval_minutes * 60 / 10))
            time.sleep(sleep_time)

    def stop(self):
        """Stops the profiling thread"""
        logger.info("Stopping periodic profiler thread...")
        if self.active_profiling:
            self.stop_profiling_and_save()
        self.stop_event.set()
        self.join()
        logger.info("Periodic profiler thread stopped.")
