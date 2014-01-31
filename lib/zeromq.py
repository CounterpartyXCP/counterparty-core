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

from . import (config, bitcoin, exceptions, util)

class ZeroMQPublisher(threading.Thread):

    def __init__ (self):
        threading.Thread.__init__(self)
        self.queue = queue.Queue()
        self.active = False
        
    def run (self):
        #logging.debug("Initializing realtime event publisher interface...")
        zmq_context = zmq.Context()
        publisher = zmq_context.socket(zmq.PUB)
        publisher.bind('tcp://%s:%s' % (config.ZEROMQ_HOST, config.ZEROMQ_PORT))
        
        #wait for things to be put into our queue and send them out to any subscribers (e.g. couterwalletd, etc)
        while True:
            self.active = True
            msg = self.queue.get()
            publisher.send_json(msg)

    def push_to_subscribers(self, msg_event, msg):
        assert isinstance(msg, dict)
        msg['_EVENT'] = msg_event #_EVENT is a reserved field
        msg['_TIME'] = time.time() #UNIX time

        # NOTE: This isn’t very useful, and it’s a bit slow. (It can be done on the other end.)
        """
        if 'block_index' in msg:
            #we can provide a timestamp - use the block time as the timestamp
            block_hash = bitcoin.rpc('getblockhash', [msg['block_index'],])
            block = bitcoin.rpc('getblock', [block_hash,])
            msg['_BLOCKTIME'] = block['time'] #UNIX time
        else:
            # msg['_BLOCKTIME'] = None #unknown
        """
        self.queue.put(msg)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
