#! /usr/bin/env python3
import os
from prettytable import PrettyTable
from counterpartycli import wallet, util

def get_view(view_name, args):
    if view_name == 'balances':
        return wallet.balances(args.address)
    elif view_name == 'asset':
        return wallet.asset(args.asset)
    elif view_name == 'wallet':
        return wallet.wallet()
    elif view_name == 'pending':
        return wallet.pending()
    elif view_name == 'getinfo':
        return util.api('get_running_info')

def print_balances(balances):
    lines = []
    lines.append('')
    lines.append('Balances')
    table = PrettyTable(['Asset', 'Amount'])
    for asset in balances:
        table.add_row([asset, balances[asset]])
    lines.append(table.get_string())
    lines.append('')
    print(os.linesep.join(lines))

def print_asset(asset):
    lines = []
    lines.append('')
    lines.append('Informations')
    table = PrettyTable(header=False, align='l')
    table.add_row(['Asset Name:', asset['asset']])
    table.add_row(['Asset ID:', asset['asset_id']])
    table.add_row(['Divisible:', asset['divisible']])
    table.add_row(['Locked:', asset['locked']])
    table.add_row(['Supply:', asset['supply']])
    table.add_row(['Issuer:', asset['issuer']])
    table.add_row(['Description:', '‘' + asset['description'] + '’'])
    table.add_row(['Balance:', asset['balance']])
    lines.append(table.get_string())

    if asset['addresses']:
        lines.append('')
        lines.append('Addresses')
        table = PrettyTable(['Address', 'Balance'])
        for address in asset['addresses']:
            balance = asset['addresses'][address]
            table.add_row([address, balance])
        lines.append(table.get_string())

    if asset['sends']:
        lines.append('')
        lines.append('Sends')
        table = PrettyTable(['Type', 'Quantity', 'Source', 'Destination'])
        for send in asset['sends']:
            table.add_row([send['type'], send['quantity'], send['source'], send['destination']])
        lines.append(table.get_string())

    lines.append('')
    print(os.linesep.join(lines))

def print_wallet(wallet):
    lines = [] 
    for address in wallet['addresses']:
        table = PrettyTable(['Asset', 'Balance'])
        for asset in wallet['addresses'][address]:
            balance = wallet['addresses'][address][asset]
            table.add_row([asset, balance])
        lines.append(address)
        lines.append(table.get_string())
        lines.append('')
    total_table = PrettyTable(['Asset', 'Balance'])
    for asset in wallet['assets']:
        balance = wallet['assets'][asset]
        total_table.add_row([asset, balance])
    lines.append('TOTAL')
    lines.append(total_table.get_string())
    lines.append('')
    print(os.linesep.join(lines))

def print_pending(awaiting_btcs):
    table = PrettyTable(['Matched Order ID', 'Time Left'])
    for order_match in awaiting_btcs:
        order_match = format_order_match(order_match)
        table.add_row(order_match)
    print(table)

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
