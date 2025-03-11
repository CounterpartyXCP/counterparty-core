import cProfile
import logging
import os
import pstats
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
        logger.info(f"Periodic profiler initialized with an interval of {interval_minutes} minutes")

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
            # Save profiling data
            self.profiler.dump_stats(profile_path)
            logger.info(f"Profiling report saved to {profile_path}")

            # Display a summary in the logs
            stats = pstats.Stats(self.profiler)
            stats_path = os.path.join(config.CACHE_DIR, f"profile_{timestamp}.txt")

            with open(stats_path, "w") as stats_file:
                # Functions most expensive in cumulative time
                stats_file.write("=== Top 20 functions (cumulative time) ===\n")
                stats.sort_stats("cumtime").print_stats(20, file=stats_file)

                # Functions most expensive in total time
                stats_file.write("\n=== Top 20 functions (total time) ===\n")
                stats.sort_stats("tottime").print_stats(20, file=stats_file)

            logger.info(f"Profiling summary saved to {stats_path}")

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

            # Check every second if stop is requested
            time.sleep(1)

        # Generate a final report on shutdown
        if self.active_profiling:
            logger.info("Generating final profiling report before shutdown")
            self.stop_profiling_and_save()

    def stop(self):
        """Stops the profiling thread"""
        logger.info("Stopping periodic profiler thread...")
        self.stop_event.set()
        self.join()
        logger.info("Periodic profiler thread stopped.")
