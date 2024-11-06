import socket
import base64
import struct
from typing import List


def connect_to_oracle(hostname: str, port: int) -> socket.socket:
    """Establish connection to the padding oracle server."""
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect((hostname, port))
    return sock


def send_q_blocks(sock: socket.socket, q_blocks: List[bytes]) -> List[bool]:
    """
    Send Q blocks to the oracle and get responses.
    Returns a list of boolean values indicating valid/invalid padding.
    """
    # Send number of Q blocks (2 bytes, little endian)
    sock.send(struct.pack('<H', len(q_blocks)))

    # Send all Q blocks concatenated
    for block in q_blocks:
        sock.send(block)

    # Receive responses (1 byte per block)
    responses = sock.recv(len(q_blocks))
    return [b == 1 for b in responses]


def find_byte(sock: socket.socket, known_bytes: bytes, byte_position: int, block_size: int = 16) -> int:
    """
    Find a single byte of plaintext using the padding oracle.
    Uses parallel queries to speed up the search.
    """
    padding_value = block_size - byte_position

    # Create base Q block with known bytes XORed with padding value
    base_q = bytearray([0] * byte_position)
    for i in range(len(known_bytes)):
        base_q.append(known_bytes[i] ^ padding_value)
    base_q.extend([0] * (block_size - len(base_q) - 1))  # Leave last byte for guesses

    # Test all possible bytes in parallel batches
    batch_size = 64  # Test 64 values at once
    for batch_start in range(0, 256, batch_size):
        q_blocks = []
        for guess in range(batch_start, min(batch_start + batch_size, 256)):
            test_q = bytearray(base_q)
            test_q.append(guess)
            q_blocks.append(bytes(test_q))

        responses = send_q_blocks(sock, q_blocks)

        # Check which value gave valid padding
        for i, is_valid in enumerate(responses):
            if is_valid:
                guess_value = batch_start + i

                # For the last byte (byte_position == 15), we need special handling
                # because we might have found a valid 0x01 padding
                if byte_position == 15:
                    # Try to verify by setting the second-to-last byte to a different value
                    verify_q = bytearray(base_q)
                    verify_q.append(guess_value)
                    verify_q[-2] ^= 1  # Modify second-to-last byte
                    verify_responses = send_q_blocks(sock, [bytes(verify_q)])

                    if verify_responses[0]:
                        # If it's still valid, this is a 0x02 0x02 padding
                        # Keep searching for 0x01 padding
                        continue

                    # This is our 0x01 padding
                    return guess_value ^ 1  # XOR with padding value 1

                # For all other positions, we need to verify it's not a false positive
                elif byte_position > 0:
                    verify_q = bytearray(base_q)
                    verify_q.append(guess_value)
                    verify_q[-2] ^= 1  # Modify second-to-last byte
                    verify_responses = send_q_blocks(sock, [bytes(verify_q)])

                    if not verify_responses[0]:  # Valid padding confirmed
                        return guess_value ^ padding_value
                else:
                    # For subsequent bytes after the last one, we trust the padding
                    return guess_value ^ padding_value

    raise Exception(f"Could not find byte at position {byte_position}")


def decrypt_block(sock: socket.socket) -> bytes:
    """Decrypt a single block of ciphertext."""
    block_size = 16
    plaintext = bytearray()

    for i in range(block_size):
        byte_pos = block_size - i - 1
        byte_val = find_byte(sock, plaintext, byte_pos)
        plaintext.insert(0, byte_val)

    return bytes(plaintext)


def padding_oracle(case: dict) -> dict:
    """
    Main function to perform the padding oracle attack.
    Takes hostname, port, IV, and ciphertext as input.
    Returns the decrypted plaintext.
    """
    # Extract parameters
    hostname = case["arguments"]["hostname"]
    port = case["arguments"]["port"]
    iv = base64.b64decode(case["arguments"]["iv"])
    ciphertext = base64.b64decode(case["arguments"]["ciphertext"])

    # Split ciphertext into blocks
    blocks = [ciphertext[i:i + 16] for i in range(0, len(ciphertext), 16)]

    # Connect to oracle server
    sock = connect_to_oracle(hostname, port)
    plaintext = bytearray()

    try:
        prev_block = iv

        # Process each ciphertext block
        for block in blocks:
            # Send the current ciphertext block to the server
            sock.send(block)

            # Decrypt the block
            decrypted = decrypt_block(sock)

            # XOR with previous ciphertext block to get plaintext
            plaintext.extend(bytes(a ^ b for a, b in zip(prev_block, decrypted)))
            prev_block = block

        return {
            "plaintext": base64.b64encode(bytes(plaintext)).decode('utf-8')
        }

    finally:
        # Send termination signal (length = 0)
        sock.send(struct.pack('<H', 0))
        sock.close()