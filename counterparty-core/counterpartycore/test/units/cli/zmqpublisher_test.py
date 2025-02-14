import json
import time

import zmq.green as zmq
from counterpartycore.lib import config
from counterpartycore.lib.cli import log

context = zmq.Context()


def test_zmqpublisher_test(test_helpers, caplog):
    config.ENABLE_ZMQ_PUBLISHER = True
    config.ZMQ_PUBLISHER_PORT = 44001

    log.ZmqPublisher()

    block_index = 1000
    event_index = 2000
    event_name = "ANICEEVENT"
    bindings = {"key": "value", "counter": 1}

    socket = context.socket(zmq.SUB)
    socket.connect(f"tcp://localhost:{config.ZMQ_PUBLISHER_PORT}")
    socket.setsockopt(zmq.RCVHWM, 0)
    socket.setsockopt(zmq.SUBSCRIBE, b"")
    time.sleep(0.1)
    # bindings["counter"] += 1
    with test_helpers.capture_log(caplog, f"ANICEEVENT [key=value counter={bindings['counter']}]"):
        log.log_event(block_index, event_index, event_name, bindings)

    while True:
        _event_name, event = socket.recv_multipart()
        event = json.loads(event.decode("utf-8"))
        print(event)
        assert event["block_index"] == block_index
        assert event["event_index"] == event_index
        assert event["event"] == event_name
        assert event["params"]["key"] == "value"
        assert event["params"]["counter"] == bindings["counter"]
        time.sleep(1)
        bindings["counter"] += 1
        with test_helpers.capture_log(
            caplog, f"ANICEEVENT [key=value counter={bindings['counter']}]"
        ):
            log.log_event(block_index, event_index, event_name, bindings)
        if bindings["counter"] == 10:
            break

    socket.close(linger=0)
    context.term()
