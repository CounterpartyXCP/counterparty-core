import threading

from counterpartylib.lib import transaction


# This is a pretty contrived case as we never call
# delete directly on the cache.  I can't trigger the
# KeyError by setting 0 expiry and attempting to set
# recently expireed keys
def test_fails_when_calling_delete_directly_on_underlying_cache():
    error = None

    cache = transaction.ThreadSafeTTLCache(1, 10)
    cache.set("a", "b")

    # delete item
    def worker_1():
        cache._get_cache().__delitem__("a")

    # set recently expired
    def worker_2():
        try:
            cache._get_cache().__delitem__("a")
        except Exception as e:
            nonlocal error
            error = e

    thread1 = threading.Thread(target=worker_1)
    thread2 = threading.Thread(target=worker_2)

    thread1.start()
    thread2.start()

    thread1.join()
    thread2.join()

    assert isinstance(error, KeyError)


def test_does_not_through_when_calling_delete_on_wrapper():
    cache = transaction.ThreadSafeTTLCache(1000, 600)
    cache.set("a", "b")

    def worker():
        cache.delete("a")

    thread1 = threading.Thread(target=worker)
    thread2 = threading.Thread(target=worker)

    thread1.start()
    thread2.start()

    thread1.join()
    thread2.join()

    assert True
