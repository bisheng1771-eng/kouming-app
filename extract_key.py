import base64

pk_b64 = 'MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDpGnK7DlK/l7/dzl86JCEaNqaNT9bpzTAMl1g3siuwnxB9CH09/VGn6q9w1PQcfLRoFYlLwvZTnP8LqHXhOxagrrZmYqHZf28ArQ62UFaZy8HAg+TzPDT6xbl9kkbma9pymFJ2K6CLeLSyPM4DZqATmrNoNt7KfSbbXm1b3s8hfPvg6+zVkN7PFXN5nLdpNl5wV07Z2JjkMJRy5YPtRpsI6sWPcGQbHolX/Fzafqy0fZveRFO7/mPeE1nvm3d3Z97y1QqMjHv2mpvOiseEbTNontMqmRxCzhcYMctNDWcvxeA6DJnLsW8OZm6WcvKCnFLnVHKuanWpMt+tx8g1RCqfAgMBAAECggEAfA/XgDbfU5kwRJzRkeAovgrYGd2kREswh4MFMJ9jIV2HKQSbo6JvEy+UsDims4Krgbn0mJ3q/BVSqKHAG1+Xa22RJmzYNynbqkBw1Bdt/+yx8gRAljQ0/kK9tldj5L8CRHtNaBdQGurjQPmbq7Oy/rwXQB/z81EonRhkm8C5/NfD9Tvz1dI11RwKO0iscMD0JaxY2OZXAI4tHbyBwdlN4Og6BPanbyO4q+8z+kd+VC04UwTO1AOlotFSTv26InIAfkYVapEVJInXYfhcgPrUM6wsMTw2XymbfKR/BaLCk6VZGrFu2rsZa0/l3awTFWontRqVjWmoFs3zXeaxD4hIAQKBgQD+tsOQ9GKV/77m/O7HAcpZySr3OcW/udN07XOwAVb0uJBeWr01rm+X05OAyae8Ar07iDjYx1CCnUzHMYRQHfRZQqn+1W+YqzCVqz6CjmPOJ2imX1zhOO33OgNlbFV/i3XpJFCEJ+X1i+W8QSL1YTkWIiVDKF7RhKj3EbAsGZ+mjwKBgQDqR8A/kNBBAXerUVN12qQdQ9KiviRYpSimAo4/+GuKpIGpkzoi368e9zMTqJgNJPvwijSRUgTTWUSKDOLygQ3OJCRTOeIspdf4Mb5sd4Jt1pTTVJFuCaQJ+tWm3D4vlIS3M7hBtGWhn8rJfCr+DxaxgJZyZpRoe/sJo2qkKkDC8QKBgHKsU5VyAORpFEgn/VQJAVG02KwfDWFIxuNwd9H4eG6KnSxti5ucYc8nyNOFdgeV8B3aMUWfTibPrJ5NM7ViFv0Mnz4EV06TW7c2NllOw64vXdTxP/6Bw9i2/Ipv4HogjkAdQkaNM+F9TzuW06dHUw0c6Eu45B9Nq0g4ZWklTBQPAoGAGqK7tb5mHu3myCB/56dK/1TFruEFStrEK1OhDp7Uwzd+0mO9uVdLFq8uLG7/kocA6dEctuTnTYwZocRjTQTlJ+muA5RSJZdZXYtyRey0dH5v/zLfMe6Aqu3MuqLRoyE0kYucyEOVRnHfYVbvoGDgyJ+A+1K0TsjBus/MgQuYv1ECgYEArXupM/rJRgwDQA8uuqN38qbtERlBKFLo/iUd7Tg+pol+if5Qr2pLTCqLkeO3NNZPbT0nqQwgYCcVJPoqfRegbVu/51wAUaWQVvci3Arlys+Fy3hcbCExSJy1p4Bir0ane8ophUFBqziXGws2bLBlvA8rQpoCBRaa5Y0Ht43W4Gw='

der = base64.b64decode(pk_b64)

def read_len(data, pos):
    b = data[pos]
    if b < 0x80:
        return b, pos + 1
    n = b & 0x7f
    return int.from_bytes(data[pos+1:pos+1+n], 'big'), pos + 1 + n

pos = 1  # skip 0x30 SEQUENCE tag
slen, pos = read_len(der, pos)

# version INTEGER
assert der[pos] == 0x02
pos += 1
vlen, pos = read_len(der, pos)
if der[pos] == 0x00:
    pos += 1
    vlen -= 1
version = int.from_bytes(der[pos:pos+vlen], 'big')
pos += vlen

# AlgorithmIdentifier SEQUENCE
assert der[pos] == 0x30
pos += 1
alen, pos = read_len(der, pos)
pos += alen

# PrivateKey OCTET STRING
assert der[pos] == 0x04
pos += 1
klen, pos = read_len(der, pos)
key_der = der[pos:pos+klen]

# Parse inner RSAPrivateKey
pos2 = 1  # skip 0x30
inner_len, pos2 = read_len(key_der, pos2)

# version
assert key_der[pos2] == 0x02
pos2 += 1
vlen2, pos2 = read_len(key_der, pos2)
if key_der[pos2] == 0x00:
    pos2 += 1
    vlen2 -= 1
pos2 += vlen2

names = ['n', 'e', 'd', 'p', 'q', 'dp', 'dq', 'qi']
vals = {}

for name in names:
    assert key_der[pos2] == 0x02, f'{name}: got {hex(key_der[pos2])} at {pos2}'
    pos2 += 1
    ilen, pos2 = read_len(key_der, pos2)
    if key_der[pos2] == 0x00:
        pos2 += 1
        ilen -= 1
    vals[name] = int.from_bytes(key_der[pos2:pos2+ilen], 'big')
    pos2 += ilen
    h = hex(vals[name])[2:]
    print(f'{name}: {len(h)} hex chars')
    print(f'  = "{h}"')

print(f'Key bits: {vals["n"].bit_length()}')
print()
print('=== DART CODE ===')
for name in names:
    h = hex(vals[name])[2:]
    print(f'final {name} = BigInt.parse("0x{h}", radix: 16);')