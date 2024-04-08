import threading

from counterpartylib.lib import transaction


def test_consecutive_deletes_throw_key_error():
    error = None
    locks = transaction.TransactionLocks(utxo_locks_max_addresses=1000)
    locks.utxo_p2sh_encoding_locks_cache["a"] = "b"

    def worker_1():
        locks.utxo_p2sh_encoding_locks_cache.__delitem__("a")

    def worker_2():
        try:
            locks.utxo_p2sh_encoding_locks_cache.__delitem__("a")
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


def test_with_thread_safe_cache():
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
