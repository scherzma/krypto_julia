import base64
from sys import byteorder
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from src.utils.conversion import tobase64b, reverse_endian
from src.operations.galois import gfmul_int_xex, gfmul_int_gcm, gfmul_int_gcm_bytes


def sea128_int(mode: str, key_bytes: bytes, input_bytes: bytes) -> int:
    """SEA-128 encryption/decryption implementation."""
    sea128_const = 0xc0ffeec0ffeec0ffeec0ffeec0ffee11
    cipher = Cipher(algorithms.AES(key_bytes), modes.ECB())

    if mode == "encrypt":
        encryptor = cipher.encryptor()
        aes_result = encryptor.update(input_bytes) + encryptor.finalize()
        int_result = int.from_bytes(aes_result, byteorder='big') ^ sea128_const
    elif mode == "decrypt":
        input_int = int.from_bytes(input_bytes, byteorder='big')
        xored = input_int ^ sea128_const
        xored_bytes = xored.to_bytes(16, byteorder='big')
        decryptor = cipher.decryptor()
        final_bytes = decryptor.update(xored_bytes) + decryptor.finalize()
        int_result = int.from_bytes(final_bytes, byteorder='big')

    return int_result

def sea128(case: dict) -> dict:
    """Wrapper function for SEA-128 operation."""
    arguments = case["arguments"]
    key_bytes = base64.b64decode(arguments["key"])
    input_bytes = base64.b64decode(arguments["input"])
    return {"output": tobase64b(sea128_int(arguments["mode"], key_bytes, input_bytes))}

def fde_xex(key_bytes: bytes, tweak_bytes: bytes, input_bytes: bytes, mode: str) -> bytes:
    """Full Disk Encryption XEX mode implementation."""
    if len(key_bytes) != 32:
        raise ValueError("Key must be 256 bits (32 bytes) for XEX.")

    k1 = key_bytes[:16]
    k2 = key_bytes[16:]
    mask = sea128_int("encrypt", k2, tweak_bytes)
    output_bytes = bytearray()

    for i in range(len(input_bytes) // 16):
        block = input_bytes[i * 16:(i + 1) * 16]
        block_int = int.from_bytes(block, byteorder='big')
        temp = block_int ^ mask
        temp_bytes = temp.to_bytes(16, byteorder='big')
        temp_encrypted_int = sea128_int(mode, k1, temp_bytes)
        plaintext = temp_encrypted_int ^ mask
        output_bytes += plaintext.to_bytes(16, byteorder='big')
        mask = reverse_endian(gfmul_int_xex(reverse_endian(mask), 2))

    return output_bytes

def xex(case: dict) -> dict:
    """Wrapper function for XEX operation."""
    args = case["arguments"]
    key_bytes = base64.b64decode(args["key"])
    tweak_bytes = base64.b64decode(args["tweak"])
    input_bytes = base64.b64decode(args["input"])
    result = fde_xex(key_bytes, tweak_bytes, input_bytes, args["mode"])
    return {"output": base64.b64encode(result).decode('utf-8')}


def encrypt_block(key: bytes, plaintext: bytes, algo: str) -> bytes:
    """Encrypt a single block using the specified algorithm."""
    if algo == "aes128":
        cipher = Cipher(algorithms.AES(key), modes.ECB())
        encryptor = cipher.encryptor()
        return encryptor.update(plaintext) + encryptor.finalize()
    elif algo == "sea128":
        temp = sea128_int("encrypt", key, plaintext)
        return temp.to_bytes(16, byteorder='big')

def ghash(text: bytes, auth_key: bytes, aad: bytes) -> (bytes, bytes):
    aad_len = (len(aad) * 8).to_bytes(8, byteorder='big')
    text_len = (len(text) * 8).to_bytes(8, byteorder='big')
    L = aad_len + text_len

    if len(aad) % 16 != 0:
        aad = aad + b'\x00' * ((16 - len(aad) % 16) % 16)
    if len(text) % 16 != 0:
        text = text + b'\x00' * ((16 - len(text) % 16) % 16)

    tag = bytearray(x ^ y for x, y in zip(b'\x00' * 16, aad))
    tag = gfmul_int_gcm_bytes(auth_key, tag)

    for i in range(len(text) // 16):
        block = text[i * 16: (i + 1) * 16]
        tag = bytearray(x ^ y for x, y in zip(tag, block))
        tag = gfmul_int_gcm_bytes(auth_key, tag)

    tag = bytearray(x ^ y for x, y in zip(tag, L))
    tag = gfmul_int_gcm_bytes(auth_key, tag)

    return (tag, L)

def gcm_encrypt_int(key: bytes, nonce: bytes, plaintext: bytes, ad: bytes, algo: str) -> (bytes, bytes, bytes, bytes):
    """
    Perform GCM decryption using specified algorithm.
    The Nonce is 96 Bit Long.
    """

    H = encrypt_block(key, b'\x00' * 16, algo)
    B0 = encrypt_block(key, nonce + b'\x00\x00\x00\x01', algo)

    counter = 2
    ciphertext = bytearray()
    for i in range(len(plaintext) + 15 // 16):
        plaintext_block = plaintext[i*16: (i+1)*16]
        Yi = nonce + counter.to_bytes(4, byteorder='big')
        xor = encrypt_block(key, Yi, algo)
        ciphertext += bytearray(x ^ y for x, y in zip(plaintext_block, xor))
        counter += 1

    auth_tag, L = ghash(ciphertext, H, ad)
    auth_tag = bytearray(x ^ y for x, y in zip(auth_tag, B0))

    return (ciphertext, auth_tag, L, H)



def gcm_encrypt(case: dict) -> dict:
    """Wrapper function for GCM encryption operation."""
    algorithm = case["arguments"]["algorithm"]
    nonce = case["arguments"]["nonce"]
    key = case["arguments"]["key"]
    plaintext = case["arguments"]["plaintext"]
    ad = case["arguments"]["ad"]

    nonce = base64.b64decode(nonce)
    key = base64.b64decode(key)
    plaintext = base64.b64decode(plaintext)
    ad = base64.b64decode(ad)

    result = gcm_encrypt_int(key, nonce, plaintext, ad, algorithm)
    return {
            "ciphertext": base64.b64encode(result[0]).decode('utf-8'),
            "tag": base64.b64encode(result[1]).decode('utf-8'),
            "L": base64.b64encode(result[2]).decode('utf-8'),
            "H": base64.b64encode(result[3]).decode('utf-8')
            }

def gcm_decrypt(case: dict) -> dict:
    """Wrapper function for GCM decryption operation."""
    algorithm = case["arguments"]["algorithm"]
    nonce = case["arguments"]["nonce"]
    key = case["arguments"]["key"]
    ciphertext = case["arguments"]["ciphertext"]
    ad = case["arguments"]["ad"]
    tag = case["arguments"]["tag"]

    nonce = base64.b64decode(nonce)
    key = base64.b64decode(key)
    ciphertext = base64.b64decode(ciphertext)
    ad = base64.b64decode(ad)
    tag = base64.b64decode(tag)

    result = gcm_encrypt_int(key, nonce, ciphertext, ad, algorithm)


    auth_key = encrypt_block(key, b'\x00' * 16, algorithm)
    res = ghash(ciphertext, auth_key, ad)

    B0 = encrypt_block(key, nonce + b'\x00\x00\x00\x01', algorithm)

    auth_tag = res[0]
    auth_tag = bytearray(x ^ y for x, y in zip(auth_tag, B0))

    print("my tag ", auth_tag.hex())
    print("tag    ", tag.hex())

    plaintext = result[0]

    return {
        "authentic": auth_tag == tag,
        "plaintext": base64.b64encode(plaintext).decode('utf-8'),
    }
