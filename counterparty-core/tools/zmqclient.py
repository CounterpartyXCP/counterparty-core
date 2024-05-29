import asyncio
import json
import logging
import signal
import time
import traceback

import zmq
import zmq.asyncio

logger = logging.getLogger(__name__)

ZMQ_PORT = 4001


class CounterpartyWatcher:
    def __init__(self):
        print("Initializing Counterparty watcher...")
        self.loop = asyncio.get_event_loop()
        self.connect_to_zmq()

    def connect_to_zmq(self):
        self.zmq_context = zmq.asyncio.Context()
        self.zmq_sub_socket = self.zmq_context.socket(zmq.SUB)
        self.zmq_sub_socket.setsockopt(zmq.RCVHWM, 0)
        # "" => Subscribe to all events
        self.zmq_sub_socket.setsockopt_string(zmq.SUBSCRIBE, "")
        self.zmq_sub_socket.connect(f"tcp://localhost:{ZMQ_PORT}")

    async def handle(self):
        try:
            event_name, event = await self.zmq_sub_socket.recv_multipart(flags=zmq.NOBLOCK)
            event = json.loads(event.decode("utf-8"))
            print(event)
        except zmq.ZMQError:
            time.sleep(1)
        except Exception as e:
            logger.error(traceback.format_exc())
            self.stop()
            raise e
        # schedule ourselves to receive the next message
        asyncio.ensure_future(self.handle())

    def start(self):
        print("Starting Counterparty watcher...")
        self.loop.add_signal_handler(signal.SIGINT, self.stop)
        self.loop.create_task(self.handle())
        self.loop.run_forever()

    def stop(self):
        print("Stopping Counterparty watcher...")
        self.loop.stop()
        self.zmq_context.destroy()


watcher = CounterpartyWatcher()
watcher.start()
