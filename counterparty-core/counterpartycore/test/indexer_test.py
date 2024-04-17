from time import sleep

import pytest
from counterparty_rs import indexer


@pytest.mark.skip()
def test_indexer():
    i = indexer.Indexer({})
    i.start()
    sleep(186400)
    i.stop()

    with pytest.raises(RuntimeError):
        i.start()

    with pytest.raises(RuntimeError):
        i.stop()
