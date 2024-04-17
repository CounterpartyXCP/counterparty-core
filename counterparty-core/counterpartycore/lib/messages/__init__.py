# Each message gets identified by its first byte.
# The only exception is send.version1 which is 0 the first to fourth byte.
#
# Used IDs for messages:
#
# 0 send.version1
# 1 send.enhanced_send
# 10 order
# 11 btcpay
# 12 dispenser
# 20 issuance
# 21 issuance.subasset
# 30 broadcast
# 40 bet
# 50 dividend
# 60 burn
# 70 cancel
# 80 rps
# 81 rpsresolve
# 110 destroy
#
# Allocate each new type of message within the "logical" 10 number boundary
# Only allocate a 10 number boundary if it makes sense
