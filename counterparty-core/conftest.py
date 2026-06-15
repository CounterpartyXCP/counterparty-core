import pytest


def pytest_addoption(parser):
    parser.addoption(
        "--skip-slow-tests",
        action="store_true",
        default=False,
        help="Skip tests marked as slow.",
    )


def pytest_configure(config):
    config.addinivalue_line("markers", "slow: marks tests as slow")


def pytest_collection_modifyitems(config, items):
    if not config.getoption("--skip-slow-tests"):
        return

    skip_slow = pytest.mark.skip(reason="Skipped because --skip-slow-tests was set.")
    for item in items:
        if "slow" in item.keywords:
            item.add_marker(skip_slow)
