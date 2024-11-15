from locust import HttpUser, TaskSet, between, task
import random

# Define headers for JSON-RPC requests
headers = {"Content-Type": "application/json"}


# Load hard-coded list of addresses and transaction hashes from files
def load_list_from_file(filename):
    try:
        with open(filename, 'r') as file:
            return [line.strip() for line in file if line.strip()]
    except FileNotFoundError:
        print(f"File {filename} not found.")
        return []

HARDCODED_TX_HASHES = load_list_from_file('data/tx_hashes.csv')
HARDCODED_ADDRESSES = load_list_from_file('data/addresses.csv')
print(HARDCODED_TX_HASHES)
print(HARDCODED_ADDRESSES)

def get_random_tx_hash():
    return random.choice(HARDCODED_TX_HASHES)

def get_random_address():
    return random.choice(HARDCODED_ADDRESSES)


# 1. Counterparty API Root
class CounterpartyApiRootTasks(TaskSet):
    @task
    def get_server_info(self):
        """Get Server Information."""
        self.client.get("/v2/", headers=headers)


# 2. Blocks
class BlocksTasks(TaskSet):
    block_hash = None  # Store block_hash for reuse

    @task
    def get_last_block(self):
        """Get information of the last block and store the block_hash."""
        with self.client.get(
            "/v2/blocks/last?verbose=true&show_unconfirmed=false",
            headers=headers,
            catch_response=True,
        ) as response:
            if response.status_code == 200:
                result = response.json().get("result")
                if result:
                    BlocksTasks.block_hash = result.get("block_hash")  # Store block_hash for reuse

    @task
    def get_block_by_hash(self):
        """Get block by stored block_hash."""
        if BlocksTasks.block_hash:
            self.client.get(
                f"/v2/blocks/{BlocksTasks.block_hash}?verbose=true&show_unconfirmed=false",
                headers=headers,
            )


# 3. Transactions
class TransactionsTasks(TaskSet):

    @task
    def get_transaction_info(self):
        """Get transaction info by a random tx_hash."""
        self.client.get(
            f"/v2/transactions/{get_random_tx_hash()}?verbose=true", headers=headers
        )

    @task
    def get_sends_by_transaction_hash(self):
        """Get sends by a random tx_hash."""
        self.client.get(f"/v2/transactions/{get_random_tx_hash()}/sends", headers=headers)


# 4. Addresses (using source_address from Transactions)
class AddressesTasks(TaskSet):
    @task
    def get_balances_by_address(self):
        """Get balances by a random source address."""
        self.client.get(
            f"/v2/addresses/{get_random_address()}/balances?limit=10&cursor=200",
            headers=headers,
        )

    @task
    def get_transactions_by_address(self):
        """Get transactions by a random source address."""
        self.client.get(
            f"/v2/addresses/{get_random_address()}/transactions?limit=10&cursor=200",
            headers=headers,
        )


# 5. UTXOs
class UtxosTasks(TaskSet):
    @task
    def get_utxo_balances(self):
        self.client.get("/v2/utxos/balances?limit=10&cursor=200", headers=headers)

    @task
    def get_utxos_by_address(self):
        if HARDCODED_ADDRESSES:
            self.client.get(
                f"/v2/utxos/{HARDCODED_ADDRESSES[0]}?limit=10&cursor=200", headers=headers
            )


# 6. Compose
class ComposeTasks(TaskSet):
    @task
    def compose_bet(self):
        self.client.post(
            "/v2/compose/bet",
            json={
                "wager": 1000,
                "odds": 2,
                "counterparty": get_random_address(),
            },
            headers=headers,
        )

    @task
    def compose_broadcast(self):
        self.client.post(
            "/v2/compose/broadcast",
            json={
                "value": 1.23,
                "source": get_random_address(),
                "text": "Test Broadcast",
            },
            headers=headers,
        )


# 7. Assets
class AssetsTasks(TaskSet):
    @task
    def get_valid_assets(self):
        self.client.get("/v2/assets", headers=headers)

    @task
    def get_asset_info(self):
        asset = "XCP"  # Replace with actual asset symbol
        self.client.get(f"/v2/assets/{asset}", headers=headers)


# 8. Orders (using tx_hash as order_id and source_address as address)
class OrdersTasks(TaskSet):
    @task
    def get_order_by_id(self):
        """Get specific order by a random tx_hash (used as order_id)."""
        self.client.get(f"/v2/orders/{get_random_tx_hash()}", headers=headers)

    @task
    def get_orders_by_address(self):
        """Get orders by a random source address."""
        self.client.get(f"/v2/orders?source={get_random_address()}", headers=headers)


# 9. Order Matches
class OrderMatchesTasks(TaskSet):
    @task
    def get_all_order_matches(self):
        self.client.get("/v2/order_matches?limit=10&cursor=200", headers=headers)


# 10. Bets
class BetsTasks(TaskSet):
    @task
    def get_bets(self):
        self.client.get("/v2/bets?limit=10&cursor=200", headers=headers)


# 11. Burns
class BurnsTasks(TaskSet):
    @task
    def get_all_burns(self):
        self.client.get("/v2/burns?limit=10&cursor=200", headers=headers)


# 12. Dispensers
class DispensersTasks(TaskSet):
    @task
    def get_dispensers(self):
        self.client.get("/v2/dispensers?limit=10&cursor=200", headers=headers)


# 13. Dividends
class DividendsTasks(TaskSet):
    @task
    def get_dividends(self):
        self.client.get("/v2/dividends?limit=10&cursor=200", headers=headers)


# 14. Events
class EventsTasks(TaskSet):
    @task
    def get_all_events(self):
        self.client.get("/v2/events?limit=10&cursor=200", headers=headers)


# 15. Dispenses (using tx_hash and source address)
class DispensesTasks(TaskSet):
    @task
    def get_dispenses_by_transaction_hash(self):
        """Get dispenses by a random tx_hash."""
        self.client.get(f"/v2/transactions/{get_random_tx_hash()}/dispenses", headers=headers)

    @task
    def get_dispenses_by_source(self):
        """Get dispenses by a random source address."""
        self.client.get(f"/v2/dispenses/source/{get_random_address()}", headers=headers)


# 16. Sends
class SendsTasks(TaskSet):
    @task
    def get_sends(self):
        self.client.get("/v2/sends?limit=10&cursor=200", headers=headers)


# 17. Issuances
class IssuancesTasks(TaskSet):
    @task
    def get_issuances(self):
        self.client.get("/v2/issuances?limit=10&cursor=200", headers=headers)


# 18. Sweeps
class SweepsTasks(TaskSet):
    @task
    def get_sweeps(self):
        self.client.get("/v2/sweeps?limit=10&cursor=200", headers=headers)


# 19. Broadcasts
class BroadcastsTasks(TaskSet):
    @task
    def get_valid_broadcasts(self):
        self.client.get("/v2/broadcasts?limit=10&cursor=200", headers=headers)


# 20. Fairminters
class FairmintersTasks(TaskSet):
    @task
    def get_all_fairminters(self):
        self.client.get("/v2/fairminters?limit=10&cursor=200", headers=headers)


# 21. Fairmints
class FairmintsTasks(TaskSet):
    @task
    def get_all_fairmints(self):
        self.client.get("/v2/fairmints?limit=10&cursor=200", headers=headers)


# 22. Bitcoin
class BitcoinTasks(TaskSet):
    @task
    def get_unspent_txouts_by_address(self):
        self.client.get(
            f"/v2/bitcoin/{TransactionsTasks.get_random_address()}/utxos", headers=headers
        )


# 23. Mempool
class MempoolTasks(TaskSet):
    @task
    def get_all_mempool_events(self):
        self.client.get("/v2/mempool/events", headers=headers)


# 24. Routes
class RoutesTasks(TaskSet):
    @task
    def get_routes(self):
        self.client.get("/v2/routes", headers=headers)


# Main User Class
class CounterpartyCoreUser(HttpUser):
    tasks = {
        CounterpartyApiRootTasks: 1,
        BlocksTasks: 2,
        TransactionsTasks: 3,
        AddressesTasks: 4,
        # UtxosTasks: 5,
        # ComposeTasks: 6,
        AssetsTasks: 7,
        OrdersTasks: 8,
        OrderMatchesTasks: 9,
        BetsTasks: 10,
        BurnsTasks: 11,
        DispensersTasks: 12,
        DividendsTasks: 13,
        # EventsTasks: 14,
        DispensesTasks: 15,
        SendsTasks: 16,
        IssuancesTasks: 17,
        SweepsTasks: 18,
        BroadcastsTasks: 19,
        FairmintersTasks: 20,
        FairmintsTasks: 21,
        # BitcoinTasks: 22,
        MempoolTasks: 23,
        RoutesTasks: 24,
    }
    wait_time = between(1, 3)
