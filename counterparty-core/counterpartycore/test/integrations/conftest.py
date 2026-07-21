"""
Pytest configuration for integration tests.
"""

import cache_manager


def pytest_addoption(parser):
    """Add custom command line options for integration tests."""
    parser.addoption(
        "--clean-integration-cache",
        action="store_true",
        default=False,
        help="Clear the integration test cache before running tests",
    )
    parser.addoption(
        "--clean-integration-cache-network",
        action="store",
        default=None,
        metavar="NETWORK",
        help="Clear the integration test cache for a specific network (signet, testnet4, mainnet)",
    )


def pytest_configure(config):
    """Handle cache cleaning options before tests run."""
    clean_all = config.getoption("--clean-integration-cache")
    clean_network = config.getoption("--clean-integration-cache-network")

    if clean_all:
        print("\n=== Clearing all integration test caches ===")
        cache_manager.clear_cache()
    elif clean_network:
        print(f"\n=== Clearing integration test cache for {clean_network} ===")
        cache_manager.clear_cache(network=clean_network)
