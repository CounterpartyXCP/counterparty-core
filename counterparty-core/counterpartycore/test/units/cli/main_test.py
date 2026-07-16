import configparser
import os
import unittest.mock as mock

import pytest
from counterpartycore.lib import cli, config
from counterpartycore.lib.cli import initialise, main, setup


@pytest.fixture
def preserve_config():
    """Snapshot and restore module-level `config` attributes around tests
    that call `initialise_config` directly. Without this, tests pollute the
    global config (DATABASE, DATA_DIR, NETWORK_NAME, ...) and break later
    tests relying on the regtest paths set up by the session-scoped
    `build_dbs` fixture.
    """
    snapshot = {k: v for k, v in vars(config).items() if not k.startswith("__")}
    snapshot_keys = set(snapshot.keys())
    yield
    current_keys = {k for k in vars(config) if not k.startswith("__")}
    for key in current_keys - snapshot_keys:
        delattr(config, key)
    for key, value in snapshot.items():
        setattr(config, key, value)


def test_argparser_multiple_electrs_urls():
    """Test that --electrs-url can be specified multiple times."""
    parser = cli.main.arg_parser(no_config_file=True, app_name="counterparty-test")
    args = parser.parse_args(
        [
            "--regtest",
            "--electrs-url=http://first:3000",
            "--electrs-url=http://second:3000",
            "start",
        ]
    )
    assert vars(args)["electrs_url"] == ["http://first:3000", "http://second:3000"]


def test_argparser_no_electrs_url():
    """Test that omitting --electrs-url results in None."""
    parser = cli.main.arg_parser(no_config_file=True, app_name="counterparty-test")
    args = parser.parse_args(
        [
            "--regtest",
            "start",
        ]
    )
    assert vars(args)["electrs_url"] is None


def test_argparser_accepts_bootstrap_once_catch_up():
    parser = cli.main.arg_parser(no_config_file=True, app_name="counterparty-test")
    args = parser.parse_args(["start", "--catch-up=bootstrap-once"])

    assert args.catch_up == "bootstrap-once"


def test_argparser():
    parser = cli.main.arg_parser(no_config_file=True, app_name="counterparty-test")
    args = parser.parse_args(
        [
            "--regtest",
            "--data-dir=datadir",
            "--wsgi-server=waitress",
            "--gunicorn-workers=2",
            "--no-telemetry",
            "--electrs-url=http://localhost:3002",
            "start",
            "-vv",
        ]
    )
    assert vars(args) == {
        "help": False,
        "verbose": 2,
        "quiet": False,
        "mainnet": True,
        "testnet3": False,
        "testnet4": False,
        "regtest": True,
        "signet": False,
        "api_limit_rows": 1000,
        "backend_name": "addrindex",
        "backend_connect": "localhost",
        "backend_port": None,
        "backend_user": "rpc",
        "backend_password": "rpc",
        "backend_cookie_file": os.path.expanduser("~/.bitcoin/.cookie"),
        "backend_ssl": False,
        "backend_ssl_no_verify": False,
        "backend_poll_interval": 3.0,
        "backend_api_key": None,
        "skip_asset_conservation_check": False,
        "p2sh_dust_return_pubkey": None,
        "rpc_host": "127.0.0.1",
        "rpc_port": None,
        "rpc_user": "rpc",
        "rpc_password": "rpc",
        "rpc_no_allow_cors": False,
        "rpc_batch_size": 20,
        "api_host": "127.0.0.1",
        "api_port": None,
        "api_user": None,
        "api_password": None,
        "api_no_allow_cors": False,
        "requests_timeout": 20,
        "force": False,
        "no_confirm": False,
        "data_dir": "datadir",
        "cache_dir": None,
        "disable_api_cache": False,
        "api_cache_max_rows": 50000,
        "log_file": False,
        "api_log_file": False,
        "no_log_files": False,
        "max_log_file_size": 41943040,
        "max_log_file_rotations": 20,
        "log_exclude_filters": None,
        "log_include_filters": None,
        "utxo_locks_max_addresses": 1000,
        "utxo_locks_max_age": 3.0,
        "no_mempool": False,
        "no_telemetry": True,
        "enable_zmq_publisher": False,
        "zmq_publisher_port": None,
        "db_connection_pool_size": 10,
        "db_max_connections": 50,
        "json_logs": False,
        "wsgi_server": "waitress",
        "waitress_threads": 10,
        "gunicorn_workers": 2,
        "gunicorn_threads_per_worker": 2,
        "no_healthz_server": False,
        "healthz_port": None,
        "healthz_saturation_grace": config.DEFAULT_HEALTHZ_SATURATION_GRACE_SECONDS,
        "bootstrap_url": None,
        "electrs_url": ["http://localhost:3002"],
        "refresh_state_db": False,
        "rebuild_state_db": False,
        "action": "start",
        "config_file": None,
        "catch_up": "normal",
        "api_only": False,
        "profile": False,
        "api_cache_size": 1000,
        "memory_profile": False,
        "memory_profile_tracemalloc": False,
        "enable_all_protocol_changes": False,
    }


def test_argparser_disable_api_cache():
    parser = cli.main.arg_parser(no_config_file=True, app_name="counterparty-test")
    args = parser.parse_args(["--regtest", "--disable-api-cache", "start"])

    assert vars(args)["disable_api_cache"] is True


WELCOME_MSG_CONFIG_STUBS = [
    ("VERBOSE", 0),
    ("QUIET", False),
    ("NETWORK_NAME", "mainnet"),
    ("DATABASE", "test.db"),
    ("STATE_DATABASE", "state.db"),
    ("FETCHER_DB", "fetcher.db"),
    ("LOG", "test.log"),
    ("API_LOG", "api.log"),
]


def test_welcome_message_default_urls_warning(preserve_config):
    """Test that welcome_message prints a warning when using default Electrs URLs."""
    config.ELECTRS_URLS_IS_DEFAULT = True
    for attr, val in WELCOME_MSG_CONFIG_STUBS:
        if not hasattr(config, attr):
            setattr(config, attr, val)

    with mock.patch("counterpartycore.lib.cli.main.cprint") as mock_cprint:
        main.welcome_message("start", "server.conf")
        warning_calls = [c for c in mock_cprint.call_args_list if "default Electrs URLs" in str(c)]
        assert len(warning_calls) == 1
        assert warning_calls[0][0][1] == "yellow"


def test_welcome_message_no_warning_when_custom_urls(preserve_config):
    """Test that welcome_message does not warn when user provided custom URLs."""
    config.ELECTRS_URLS_IS_DEFAULT = False
    for attr, val in WELCOME_MSG_CONFIG_STUBS:
        if not hasattr(config, attr):
            setattr(config, attr, val)

    with mock.patch("counterpartycore.lib.cli.main.cprint") as mock_cprint:
        main.welcome_message("start", "server.conf")
        warning_calls = [c for c in mock_cprint.call_args_list if "default Electrs URLs" in str(c)]
        assert len(warning_calls) == 0


INITIALISE_DEFAULTS = {
    "backend_password": "rpc",
    "backend_connect": "localhost",
}


def test_initialise_config_electrs_mainnet_defaults(tmp_path, preserve_config):
    """Test that mainnet defaults set ELECTRS_URLS and IS_DEFAULT correctly."""
    initialise.initialise_config(
        electrs_url=None, data_dir=str(tmp_path), cache_dir=str(tmp_path), **INITIALISE_DEFAULTS
    )

    assert config.ELECTRS_URLS == config.DEFAULT_ELECTRS_URLS_MAINNET
    assert config.ELECTRS_URLS_IS_DEFAULT is True


def test_initialise_config_electrs_custom_list(tmp_path, preserve_config):
    """Test that a custom URL list sets IS_DEFAULT to False."""
    initialise.initialise_config(
        electrs_url=["http://my-server:3000"],
        data_dir=str(tmp_path),
        cache_dir=str(tmp_path),
        **INITIALISE_DEFAULTS,
    )

    assert config.ELECTRS_URLS == ["http://my-server:3000"]
    assert config.ELECTRS_URLS_IS_DEFAULT is False


def test_initialise_config_electrs_string_coerced_to_list(tmp_path, preserve_config):
    """Test that a plain string electrs_url is coerced to a list."""
    initialise.initialise_config(
        electrs_url="http://my-server:3000",
        data_dir=str(tmp_path),
        cache_dir=str(tmp_path),
        **INITIALISE_DEFAULTS,
    )

    assert config.ELECTRS_URLS == ["http://my-server:3000"]
    assert config.ELECTRS_URLS_IS_DEFAULT is False


def test_initialise_config_disable_api_cache(tmp_path, preserve_config):
    initialise.initialise_config(
        disable_api_cache=True,
        electrs_url=None,
        data_dir=str(tmp_path),
        cache_dir=str(tmp_path),
        **INITIALISE_DEFAULTS,
    )

    assert config.DISABLE_API_CACHE is True


def test_initialise_config_electrs_regtest_none(tmp_path, preserve_config):
    """Test that regtest with no electrs_url sets ELECTRS_URLS to None."""
    initialise.initialise_config(
        electrs_url=None,
        regtest=True,
        data_dir=str(tmp_path),
        cache_dir=str(tmp_path),
        **INITIALISE_DEFAULTS,
    )

    assert config.ELECTRS_URLS is None
    assert config.ELECTRS_URLS_IS_DEFAULT is False


def test_add_config_arguments_append_action():
    """Test that add_config_arguments wraps append-action values from config file in a list."""
    parser = cli.main.argparse.ArgumentParser()
    configfile = configparser.ConfigParser()
    configfile["Default"] = {"electrs-url": "http://from-config:3000"}

    config_args = [
        [
            ("--electrs-url",),
            {
                "action": "append",
                "help": "test",
            },
        ],
    ]

    setup.add_config_arguments(parser, config_args, configfile, add_default=True)
    args = parser.parse_args([])
    assert args.electrs_url == ["http://from-config:3000"]
