**Notes about the Optional `sat_per_vbyte` Parameter.**

To calculate the fees required for a transaction, we do not know the final size of the transaction before signing it.
So the  composer injects fake script_sig and witnesses into the transaction before calculating the vsize.
Two remarks:

1. this only works for standard scripts

1. the size of DER signatures can vary by a few bytes and it is impossible to predict it. The composer uses a fixed size of 70 bytes so there may be a discrepancy of a few satoshis with the fees requested with `sat_per_vbyte` (for example if a DER signature is 72 bytes with `sat_per_vbyte=2` there will be an error of 4 sats in the calculated fees).
