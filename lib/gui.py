import sys
import os.path
import cherrypy
import decimal
import json
import threading

from . import (config, api, util, exceptions, bitcoin, blocks)
from . import (send, order, btcpay, issuance, broadcast, bet, dividend, burn, cancel, callback)

D = decimal.Decimal

#set_options()

class DecimalEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o,  decimal.Decimal):
            return str(o)
        return super(DecimalEncoder, self).default(o)

class XCPGUI(threading.Thread):

    def __init__ (self):
        threading.Thread.__init__(self)

    def run(self):

        current_dir = os.path.dirname(os.path.abspath(__file__))
        db = util.connect_to_db()
    
        def get_param(key):
            try:
                return cherrypy.request.params[key]
            except:
                return None

        def index():        
            path = os.path.abspath(os.path.join(current_dir, '..', 'static/gui.html'))
            return cherrypy.lib.static.serve_file(path)        
        
        def wallet():
            wallet = {'addresses': {}}
            totals = {}

            for group in bitcoin.rpc('listaddressgroupings', []):
                for bunch in group:
                    address, btc_balance = bunch[:2]
                    #print(address)
                    get_address = util.get_address(db, address=address)
                   
                    balances = get_address['balances']
                    assets =  {}
                    empty = True
                    if btc_balance:
                        assets['BTC'] = btc_balance
                        if 'BTC' in totals.keys(): totals['BTC'] += btc_balance
                        else: totals['BTC'] = btc_balance
                        empty = False
                    for balance in balances:
                        asset = balance['asset']
                        balance = D(util.devise(db, balance['amount'], balance['asset'], 'output'))
                        if balance:
                            if asset in totals.keys(): totals[asset] += balance
                            else: totals[asset] = balance
                            #table.add_row([asset, balance])
                            assets[asset] = balance
                            empty = False
                    if not empty:
                        wallet['addresses'][address] = assets

            wallet['totals'] = totals
            #print(wallet)
            
            cherrypy.response.headers['Content-Type'] = 'application/json'
            return json.dumps(wallet, cls=DecimalEncoder).encode("utf-8")

        def action(**kwargs):

            unsigned = True if get_param('unsigned')!=None and get_param('unsigned')=="1" else False
            #print("unsigned:"+str(unsigned))
            try:
                action = get_param('action')

                if action=='send':
                    source = get_param('source')
                    destination = get_param('destination')
                    asset = get_param('asset')  
                    quantity = util.devise(db, get_param('quantity'), asset, 'input')      
                    unsigned_tx_hex = send.create(db, source, destination, quantity, asset, unsigned=unsigned)
                    result = {'success':True, 'message':str(unsigned_tx_hex)}       

                elif action=='order':
                    source = get_param('source')
                    give_asset = get_param('give_asset')
                    get_asset = get_param('get_asset')
                    give_quantity = util.devise(db, get_param('give_quantity'), give_asset, 'input')
                    get_quantity = util.devise(db, get_param('get_quantity'), get_asset, 'input')
                    expiration = int(get_param('expiration')) 
                    fee_required = 0
                    fee_provided = config.MIN_FEE
                    if give_asset == 'BTC':
                        fee_required = 0
                        fee_provided = util.devise(db, get_param('fee_provided'), 'BTC', 'input')
                    elif get_asset == 'BTC':
                        fee_required = util.devise(db, get_param('fee_required'), 'BTC', 'input')
                        fee_provided = config.MIN_FEE
                 
                    unsigned_tx_hex = order.create(db, source, give_asset,
                                                   give_quantity, get_asset,
                                                   get_quantity, expiration,
                                                   fee_required, fee_provided,
                                                   unsigned=unsigned)

                    result = {'success':True, 'message':str(unsigned_tx_hex)}       

                elif action=='btcpay':
                    order_match_id = get_param('order_match_id')         
                    unsigned_tx_hex = btcpay.create(db, order_match_id, unsigned=unsigned)
                    result = {'success':True, 'message':str(unsigned_tx_hex)}          

                elif action=='cancel':
                    offer_hash = get_param('offer_hash')           
                    unsigned_tx_hex = cancel.create(db, offer_hash, unsigned=unsigned)
                    result = {'success':True, 'message':str(unsigned_tx_hex)}

                elif action=='issuance':
                    source = get_param('source')
                    destination = get_param('destination')
                    asset_name = get_param('asset_name')
                    divisible = True if get_param('divisible')=="1" else False
                    quantity = util.devise(db, get_param('quantity'), None, 'input', divisible=divisible)

                    callable_ = True if get_param('callable')=="1" else False
                    call_date = get_param('call_date')
                    call_price = get_param('call_price')
                    description = get_param('description')
                
                    if callable_:
                        call_date = round(datetime.timestamp(dateutil.parser.parse(call_date)))
                        call_price = float(call_price)
                    else:
                        call_date, call_price = 0, 0

                    issuance.create(db, source, destination, asset_name, quantity, divisible, 
                                    callable_, call_date, call_price, description, unsigned=unsigned)
                    result = {'success':True, 'message':str(unsigned_tx_hex)}
                
                elif action=='dividend':
                    source = get_param('source')
                    asset = get_param('asset') 
                    quantity_per_share = util.devise(db, get_param('quantity_per_share'), 'XCP', 'input')
                    unsigned_tx_hex = dividend.create(db, source, quantity_per_share, asset, unsigned=unsigned)
                    result = {'success':True, 'message':str(unsigned_tx_hex)}

                elif action=='callback':
                    source = get_param('source')
                    asset = get_param('asset')
                    fraction_per_share = float(get_param('fraction_per_share'))
                    unsigned_tx_hex = callback.create(db, source, fraction_per_share, asset, unsigned=unsigned)
                    result = {'success':True, 'message':str(unsigned_tx_hex)}

                elif action=='broadcast':
                    source = get_param('source')
                    text = get_param('text')
                    value = util.devise(db, get_param('value'), 'value', 'input')
                    fee_multiplier = get_param('fee_multiplier')
                    unsigned_tx_hex = broadcast.create(db, source, int(time.time()), value, fee_multiplier, text, unsigned=unsigned)
                    result = {'success':True, 'message':str(unsigned_tx_hex)}

                elif action=='bet':
                    source = get_param('source')
                    feed_address = get_param('feed_address')
                    bet_type = int(get_param('bet_type'))
                    deadline = calendar.timegm(dateutil.parser.parse(get_param('deadline')).utctimetuple())
                    wager = util.devise(db, get_param('wager'), 'XCP', 'input')
                    counterwager = util.devise(db, get_param('counterwager'), 'XCP', 'input')
                    target_value = util.devise(db, get_param('target_value'), 'value', 'input')
                    leverage = util.devise(db, get_param('leverage'), 'leverage', 'input')

                    expiration = get_param('expiration')
                    unsigned_tx_hex = bet.create(db, source, feed_address, bet_type, deadline,
                                                wager, counterwager, target_value,
                                                leverage, expiration, unsigned=unsigned)
                    result = {'success':True, 'message':str(unsigned_tx_hex)}

                else:
                    result = {'success':False, 'message':'Unknown action.'} 

                if result['success']==True and unsigned==False:
                    tx_hash = bitcoin.transmit(unsigned_tx_hex, ask=False);
                    result['message'] = "Transaction transmited: "+tx_hash

            except Exception as e:
                result = {'success':False, 'message':str(e)} 

            cherrypy.response.headers['Content-Type'] = 'application/json'
            return json.dumps(result, cls=DecimalEncoder).encode("utf-8")

        
        d = cherrypy.dispatch.RoutesDispatcher()
        d.connect(name='index', route='/', controller=index)
        d.connect(name='wallet', route='/wallet', controller=wallet)
        d.connect(name='action', route='/action', controller=action)

        checkpassword = cherrypy.lib.auth_basic.checkpassword_dict({config.GUI_USER: config.GUI_PASSWORD})

        conf = {
            '/': {
                'request.dispatch': d,
                'tools.auth_basic.on': True,
                'tools.auth_basic.realm': 'counterpartyd GUI',
                'tools.auth_basic.checkpassword': checkpassword,
            },
            '/static': {
                'tools.staticdir.on': True, 
                'tools.staticdir.dir': os.path.join(current_dir, '..', 'static')
            }
        } 
        cherrypy.tree.mount(self, '/', config=conf)

        cherrypy.config.update({
            'server.socket_host': config.GUI_HOST,
            'server.socket_port': config.GUI_PORT
        })

        cherrypy.engine.start()

#XCPGUI().run()
