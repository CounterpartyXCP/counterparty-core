#! /usr/bin/python3
"""
zeroMQ publisher for realtime event notification to clients
"""

import sys
import os
import threading
import time
import json
import queue
import logging

import zmq

from . import (config, exceptions, util)

class ZeroMQPublisher(threading.Thread):

    def __init__ (self):
        threading.Thread.__init__(self)
        self.queue = queue.Queue()
        
    def run (self):
        #logging.debug("Initializing realtime event publisher interface...")
        zmq_context = zmq.Context()
        publisher = zmq_context.socket(zmq.PUB)
        publisher.bind('tcp://%s:%s' % (config.ZEROMQ_HOST, config.ZEROMQ_PORT))
        
        #wait for things to be put into our queue and send them out to any subscribers (e.g. couterwalletd, etc)
        while True:
            msg = self.queue.get()
            publisher.send_json(msg)

    def push_to_subscribers(self, msg_type, msg):
        assert isinstance(msg, dict)
        msg['_TYPE'] = msg_type
        self.queue.put(msg)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
