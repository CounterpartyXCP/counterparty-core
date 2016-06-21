import logging
import inspect


def get_logger(prefix, logger=None):
    return SLoggerWithTrace(prefix, logger=logger)


def log_dict(d, msg=None):
    order = dict(nonce=-10, sender=-9, startgas=-8, value=-7, to=-6, data=-5, gasprice=-4)

    kargsalpha = list(sorted(d.keys()))
    return ", ".join("%s=%s" % (k, d[k]) for k in sorted(d.keys(), key=lambda x: order.get(x, kargsalpha.index(x))))


class SLoggerWithTrace(object):
    def __init__(self, prefix=None, logger=None):
        self.prefix = prefix

        name = __name__
        for frame in inspect.stack():
            module = inspect.getmodule(frame[0])

            if module is not None:
                name = module.__name__
                if name != __name__:
                    break

        if logger:
            self.logger = logger
        else:
            self.logger = logging.getLogger(name)

        if prefix is not None:
            self.logger = self.logger.getChild(prefix)

    def is_active(self, level):
        if level == 'trace':
            return True
        else:
            return True

    def trace(self, msg, **kwargs):
        self.debug(msg, type='debug', **kwargs)

    def warn(self, msg, **kwargs):
        self.debug(msg, type='warn', **kwargs)

    def debug(self, msg, type='debug', **kwargs):
        if len(list(kwargs.keys())) > 0:
            m = msg.format(**kwargs)
            getattr(self.logger, type)("{} {}".format(m, log_dict(kwargs, m)))
        else:
            getattr(self.logger, type)(msg, **kwargs)
