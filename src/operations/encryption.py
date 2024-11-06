import base64
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from src.utils.conversion import tobase64b, reverse_endian
from src.operations.galois import gfmul_int_xex

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