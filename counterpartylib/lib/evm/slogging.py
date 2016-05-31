import logging
import inspect


def get_logger(prefix):
    return SLoggerWithTrace(prefix)


def log_dict(d):
    return " ".join("{}={!s}".format(k, v) for k, v in d.items())


class SLoggerWithTrace(object):
    def __init__(self, prefix=None):
        self.prefix = prefix

        name = __name__
        for frame in inspect.stack():
            module = inspect.getmodule(frame[0])

            if module is not None:
                name = module.__name__
                if name != __name__:
                    break

        self.logger = logging.getLogger(name)
        if prefix is not None:
            self.logger = self.logger.getChild(prefix)

    def is_active(self, level):
        if level == 'trace':
            return True
        else:
            return True

    def trace(self, msg, **kwargs):
        self.debug(msg, **kwargs)

    def warn(self, msg, **kwargs):
        if len(list(kwargs.keys())) > 0:
            self.logger.warn("{} {}".format(msg, log_dict(kwargs)))
        else:
            self.logger.warn(msg, **kwargs)

    def debug(self, msg, **kwargs):
        if len(list(kwargs.keys())) > 0:
            self.logger.debug("{} {}".format(msg, log_dict(kwargs)))
        else:
            self.logger.debug(msg, **kwargs)
