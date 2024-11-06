# File: src/operations/padding_oracle_optimized.py

import base64
import socket
import struct
from typing import Dict, Any
from cryptography.hazmat.primitives import padding

def padding_oracle(case: Dict[str, Any]) -> Dict[str, Any]:
    hostname = case["arguments"]["hostname"]
    port = case["arguments"]["port"]
    iv = base64.b64decode(case["arguments"]["iv"])
    ciphertext = base64.b64decode(case["arguments"]["ciphertext"])
    blocks = [iv] + [ciphertext[i:i+16] for i in range(0, len(ciphertext), 16)]
    plaintext_blocks = []

    # Process each block
    for b in range(1, len(blocks)):
        Cb_prev = blocks[b - 1]
        Cb = blocks[b]
        # Establish a new connection per block
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            sock.connect((hostname, port))
            sock.settimeout(5)
            # Send initial ciphertext (16 bytes)
            sock.sendall(Cb)
            # Perform the attack on the current block
            Dk_Cb = attack_block(sock)
        # Recover plaintext block
        P_b = bytes(x ^ y for x, y in zip(Dk_Cb, Cb_prev))
        plaintext_blocks.append(P_b)

    plaintext = b''.join(plaintext_blocks)

    # Remove PKCS#7 padding
    try:
        unpadder = padding.PKCS7(128).unpadder()
        plaintext = unpadder.update(plaintext)
        plaintext += unpadder.finalize()
    except ValueError:
        # Padding is incorrect, return as is
        pass

    plaintext_base64 = base64.b64encode(plaintext).decode('utf-8')
    return {"plaintext": plaintext_base64}

def attack_block(sock):
    s = [0] * 16  # Intermediate decrypted bytes Dk(Cb)
    for i in range(15, -1, -1):
        padding_length = 16 - i
        found = False

        # Prepare all 256 queries for the current byte
        Q_blocks = []
        for v in range(256):
            Q = [0]*16
            Q[i] = v
            for j in range(i+1, 16):
                Q[j] = s[j] ^ padding_length
            Q_blocks.append(bytes(Q))

        # Send all Q_blocks in one batch
        length_bytes = struct.pack('>H', len(Q_blocks))
        sock.sendall(length_bytes)
        sock.sendall(b''.join(Q_blocks))

        # Receive responses
        responses = recv_all(sock, len(Q_blocks))
        # Process responses
        for idx, response_byte in enumerate(responses):
            if response_byte == 1:
                v = idx
                s[i] = v ^ padding_length
                found = True
                break

        if not found:
            raise Exception(f"Padding oracle attack failed at byte {i}")
    Dk_Cb = bytes(s)
    return Dk_Cb

def recv_all(sock, total_length):
    data = b''
    while len(data) < total_length:
        packet = sock.recv(total_length - len(data))
        if not packet:
            raise Exception("Connection closed by server")
        data += packet
    return data
