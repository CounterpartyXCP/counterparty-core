from reparsetest import prepare


def test_rebuild():
    sh_counterparty_server, _db_file, _api_url = prepare("testnet4")
    sh_counterparty_server("rebuild")
