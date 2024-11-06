# File: src/operations/padding_oracle.py

import base64
import socket
import struct
from typing import Dict, Any

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
        # Open a new connection per block
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            sock.connect((hostname, port))
            # Send initial ciphertext (16 bytes)
            sock.sendall(Cb)
            # Perform the attack
            Dk_Cb = attack_block(sock)
        # Recover plaintext block
        P_b = bytes(x ^ y for x, y in zip(Dk_Cb, Cb_prev))
        plaintext_blocks.append(P_b)

    plaintext = b''.join(plaintext_blocks)
    plaintext_base64 = base64.b64encode(plaintext).decode('utf-8')
    return {"plaintext": plaintext_base64}

def attack_block(sock):
    s = [0] * 16  # Intermediate decrypted bytes Dk(Cb)
    for i in range(15, -1, -1):
        padding_length = 16 - i
        found = False
        Q_blocks = []
        Q_values = []
        for v in range(256):
            Q = [0]*16
            Q[i] = v
            for j in range(i+1, 16):
                Q[j] = s[j] ^ padding_length
            Q_blocks.append(bytes(Q))
            Q_values.append(v)
        # Prepare the length field (2 bytes, little endian)
        l = len(Q_blocks)
        length_bytes = struct.pack('<H', l)
        sock.sendall(length_bytes)
        # Send all Q-blocks
        sock.sendall(b''.join(Q_blocks))
        # Receive l bytes response
        responses = sock.recv(l)
        # Ensure we have all responses
        while len(responses) < l:
            chunk = sock.recv(l - len(responses))
            if not chunk:
                raise Exception("Connection closed by server")
            responses += chunk
        # Process responses
        for idx, response_byte in enumerate(responses):
            if response_byte == 1:
                v = Q_values[idx]
                s[i] = v ^ padding_length
                found = True
                break
        if not found:
            raise Exception("Padding oracle attack failed at byte {}".format(i))
    Dk_Cb = bytes(s)
    return Dk_Cb
