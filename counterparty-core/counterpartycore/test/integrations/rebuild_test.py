from reparsetest import bootstrap, prepare


def test_rebuild():
    sh_counterparty_server, _server_args, _db_file, _api_url = prepare("testnet4")
    bootstrap(sh_counterparty_server, "testnet4")
    sh_counterparty_server("build-state-db")
