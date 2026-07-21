# Trusted public keys used to verify the signatures of the bootstrap snapshots.
#
# A snapshot is accepted only if its detached signature is verified by one of the
# keys below AND that key is still valid (GnuPG treats a signature made by an
# expired key as EXPKEYSIG -> not valid). Keep only non-expired keys here, and
# renew / rotate well before a key's expiration date.

# Primary signing key (Counterparty Core), ed25519, expires 2036-06-28.
# Fingerprint: A02A 3231 1E3A 1D43 758B 28B0 002B F56C F597 8E8B
PUBLIC_KEY_COUNTERPARTY_CORE = """-----BEGIN PGP PUBLIC KEY BLOCK-----

mDMEakWKaRYJKwYBBAHaRw8BAQdAZ62+cPaNCI2YCpC9r0O8kngwZT/Qzw2Ur6cS
BhhjR7a0J0NvdW50ZXJwYXJ0eSBDb3JlIDxkZXZAY291bnRlcnBhcnR5LmlvPoiW
BBMWCAA+FiEEoCoyMR46HUN1iyiwACv1bPWXjosFAmpFimkCGwMFCRLMAwAFCwkI
BwIGFQoJCAsCBBYCAwECHgECF4AACgkQACv1bPWXjovW4wD+LW9X/3ISiBCSM69h
kVaKIkYiMM1mliijDD15483HQCYA/3k7Ew60fvY7e7o3eaxJWXXVHDpSc9x0UzMH
y39BPBIOuDgEakWKaRIKKwYBBAGXVQEFAQEHQM0B3ZG4axNTvGXmp3pM6rjN3Isb
buqbllHCB1S1ddUPAwEIB4h+BBgWCAAmFiEEoCoyMR46HUN1iyiwACv1bPWXjosF
AmpFimkCGwwFCRLMAwAACgkQACv1bPWXjovohAD+NwZefsALGG/LGM/Zqkxb6Wj5
R1kMzE6yKeg/BSj6/dsBAN6cbaHoPLLDrAad/znDkaJ1vvNFjKZxm1OjpxZZ4wEH
=vSrV
-----END PGP PUBLIC KEY BLOCK-----
"""

# Backup signing key (Ouziel Slama <ouziel@counterparty.io>), ed25519, expires 2034-05-05.
PUBLIC_KEY_COUNTERPARTY_IO = """-----BEGIN PGP PUBLIC KEY BLOCK-----

mDMEZjnlZhYJKwYBBAHaRw8BAQdA7sRVMFGIu4NQYvK6frj/pKst5RO6SkxoFnTm
zZoe9Qa0JU91emllbCBTbGFtYSA8b3V6aWVsQGNvdW50ZXJwYXJ0eS5pbz6ImQQT
FgoAQRYhBIJRtuFJfKCtMCtAftYURn6xtoynBQJmOeVmAhsDBQkSzAMABQsJCAcC
AiICBhUKCQgLAgQWAgMBAh4HAheAAAoJENYURn6xtoynkFAA/jdwCyIgitt2r8qH
qv5T3q8fUVk4o6CNqk47lkzm7mUUAP4hzT93rWwZxfXxfDgxMfLc/z/NZf2ZptqM
uwAb2WR9D7g4BGY55WYSCisGAQQBl1UBBQEBB0BS6nt1NN04uz0y6yWlFS+H68UB
BOt/FUUYvPmWCgrTfgMBCAeIfgQYFgoAJhYhBIJRtuFJfKCtMCtAftYURn6xtoyn
BQJmOeVmAhsMBQkSzAMAAAoJENYURn6xtoyndG8A/RVbAUX9/rOCzm/eaaNVglT2
WF9jyYnWo70VAg8+AutzAQCi6cSlZxfrF/rK/xMuwsu2msrefzy4bFYiPGQIFHSY
Aw==
=8mni
-----END PGP PUBLIC KEY BLOCK-----
"""

PUBLIC_KEYS = [PUBLIC_KEY_COUNTERPARTY_CORE, PUBLIC_KEY_COUNTERPARTY_IO]
