from counterpartycore.lib import cli


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
        "testnet": False,
        "testnet4": False,
        "regtest": True,
        "api_limit_rows": 1000,
        "backend_name": "addrindex",
        "backend_connect": "localhost",
        "backend_port": None,
        "backend_user": "rpc",
        "backend_password": "rpc",
        "backend_ssl": False,
        "backend_ssl_no_verify": False,
        "backend_poll_interval": 3.0,
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
        "db_connection_pool_size": 20,
        "json_logs": False,
        "wsgi_server": "waitress",
        "waitress_threads": 10,
        "gunicorn_workers": 2,
        "gunicorn_threads_per_worker": 2,
        "bootstrap_url": None,
        "electrs_url": "http://localhost:3002",
        "refresh_state_db": False,
        "rebuild_state_db": False,
        "action": "start",
        "config_file": None,
        "catch_up": "normal",
    }
