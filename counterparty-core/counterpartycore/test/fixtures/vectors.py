"""
This structure holds the unit test vectors. They are used to generate test cases in conftest.py.
The results are computed using check_outputs in util_test.py.
The function supports three types of output checks:
- Return values - 'out'
- Errors raised - 'error'
- Database changes - 'records'
- PRAGMA changes - 'pragma'
"""

from .contract_vectors.address import ADDRESS_VECTOR
from .contract_vectors.api_v1 import API_V1_VECTOR
from .contract_vectors.blocks import BLOCKS_VECTOR
from .contract_vectors.composer import COMPOSER_VECTOR
from .contract_vectors.database import DATABASE_VECTOR
from .contract_vectors.gettxinfo import GETTXINFO_VECTOR
from .contract_vectors.ledger import LEDGER_VECTOR
from .contract_vectors.message_type import MESSAGE_TYPE_VECTOR
from .contract_vectors.messages.attach import ATTACH_VECTOR
from .contract_vectors.messages.bet import BET_VECTOR
from .contract_vectors.messages.broadcast import BROADCAST_VECTOR
from .contract_vectors.messages.burn import BURN_VECTOR
from .contract_vectors.messages.cancel import CANCEL_VECTOR
from .contract_vectors.messages.destroy import DESTROY_VECTOR
from .contract_vectors.messages.detach import DETACH_VECTOR
from .contract_vectors.messages.dispenser import DISPENSER_VECTOR
from .contract_vectors.messages.dividend import DIVIDEND_VECTOR
from .contract_vectors.messages.enhanced_send import ENHANCED_SEND_VECTOR
from .contract_vectors.messages.fairmint import FAIRMINT_VECTOR
from .contract_vectors.messages.fairminter import FAIRMINTER_VECTOR
from .contract_vectors.messages.gas import GAS_VECTOR
from .contract_vectors.messages.issuance import ISSUANCE_VECTOR
from .contract_vectors.messages.move import MOVE_VECTOR
from .contract_vectors.messages.mpma import MPMA_VECTOR
from .contract_vectors.messages.order import ORDER_VECTOR
from .contract_vectors.messages.send import SEND_VECTOR
from .contract_vectors.messages.sweep import SWEEP_VECTOR
from .contract_vectors.messages.utxo import UTXO_VECTOR
from .contract_vectors.script import SCRIPT_VECTOR
from .contract_vectors.util import UTIL_VECTOR

# UNITTEST_VECTOR = COMPOSER_VECTOR

UNITTEST_VECTOR = (
    ADDRESS_VECTOR
    | API_V1_VECTOR
    | BLOCKS_VECTOR
    | COMPOSER_VECTOR
    | DATABASE_VECTOR
    | GETTXINFO_VECTOR
    | LEDGER_VECTOR
    | MESSAGE_TYPE_VECTOR
    | SCRIPT_VECTOR
    | UTIL_VECTOR
    # Messages
    | ATTACH_VECTOR
    | BET_VECTOR
    | BROADCAST_VECTOR
    | BURN_VECTOR
    | CANCEL_VECTOR
    | DESTROY_VECTOR
    | DETACH_VECTOR
    | DISPENSER_VECTOR
    | DIVIDEND_VECTOR
    | ENHANCED_SEND_VECTOR
    | FAIRMINTER_VECTOR
    | FAIRMINT_VECTOR
    | GAS_VECTOR
    | ISSUANCE_VECTOR
    | MOVE_VECTOR
    | MPMA_VECTOR
    | ORDER_VECTOR
    | SEND_VECTOR
    | SWEEP_VECTOR
    | UTXO_VECTOR
)
