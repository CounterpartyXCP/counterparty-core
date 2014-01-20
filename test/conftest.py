# content of conftest.py
import pytest

#Parse any command line args
def pytest_addoption(parser):
    parser.addoption("--sourceaddr", action="store", default="mn6q3dS2EnDUx3bmyWc6D4szJNVGtaR7zc",
        help="the testnet source address to use")

@pytest.fixture
def sourceaddr(request):
    return request.config.getoption("--sourceaddr")
