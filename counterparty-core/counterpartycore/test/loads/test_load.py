import gevent
import locust
import locustfile
from locust.log import setup_logging
from locust.stats import stats_history, stats_printer


def test_load():
    setup_logging("INFO")

    user_count = 5
    spawn_rate = 2
    test_duration = 60

    env = locust.env.Environment(user_classes=[locustfile.CounterpartyCoreUser])
    env.create_local_runner()

    # start a greenlet that periodically outputs the current stats
    gevent.spawn(stats_printer(env.stats))
    # start a greenlet that save current stats to history
    gevent.spawn(stats_history, env.runner)
    # start the test
    env.runner.start(user_count, spawn_rate=spawn_rate)
    # in test_duration seconds stop the runner
    gevent.spawn_later(test_duration, lambda: env.runner.quit())
    env.runner.greenlet.join()

    assert env.stats.total.avg_response_time < 30  # ms
    assert env.stats.total.num_failures == 0
    assert env.stats.total.get_response_time_percentile(0.95) < 50  # ms
