# File: src/operations/padding_oracle_chaggpt.py

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
    blocks = [ciphertext[i:i+16] for i in range(0, len(ciphertext), 16)]
    plaintext_blocks = []

    for b in range(len(blocks)):
        if b == 0:
            Cb_prev = iv
        else:
            Cb_prev = blocks[b-1]
        Cb = blocks[b]
        # Perform the attack on the current block
        Dk_Cb = attack_block(hostname, port, Cb)
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

def attack_block(hostname, port, Cb):
    s = [0] * 16  # Intermediate decrypted bytes Dk(Cb)
    for i in range(15, -1, -1):
        padding_length = 16 - i
        found = False
        for v in range(256):
            Q = [0]*16
            Q[i] = v
            for j in range(i+1, 16):
                Q[j] = s[j] ^ padding_length
            Q_block = bytes(Q)
            # Open a new connection per query if necessary
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
                sock.connect((hostname, port))
                # Send initial ciphertext (16 bytes)
                sock.sendall(Cb)
                # Prepare the length field (2 bytes, big-endian)
                length_bytes = struct.pack('>H', 1)
                sock.sendall(length_bytes)
                # Send the Q-block
                sock.sendall(Q_block)
                # Receive 1 byte response
                response = sock.recv(1)
                while len(response) < 1:
                    chunk = sock.recv(1 - len(response))
                    if not chunk:
                        raise Exception("Connection closed by server")
                    response += chunk
            # Process response
            if response[0] == 1:
                s[i] = v ^ padding_length
                found = True
                break
        if not found:
            raise Exception(f"Padding oracle attack failed at byte {i}")
    Dk_Cb = bytes(s)
    return Dk_Cb
