import base64
import socket
import struct
import time
from typing import Dict, Any, List, Tuple


def create_socket(hostname: str, port: int, retries: int = 3, delay: float = 0.1) -> socket.socket:
    """Create and connect socket with retry logic."""
    for attempt in range(retries):
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.connect((hostname, port))
            return sock
        except (ConnectionRefusedError, socket.error) as e:
            if attempt == retries - 1:
                raise
            time.sleep(delay)


def send_and_receive(sock: socket.socket, q_blocks: List[bytes], retries: int = 3) -> List[bool]:
    """Send Q blocks and receive responses with retry logic and validation."""
    for attempt in range(retries):
        try:
            # Send length
            length_bytes = struct.pack('<H', len(q_blocks))
            sock.sendall(length_bytes)

            # Send blocks
            for block in q_blocks:
                sock.sendall(block)

            # Receive responses with timeout
            sock.settimeout(2.0)  # 2 second timeout
            responses = bytearray()
            expected_length = len(q_blocks)

            while len(responses) < expected_length:
                chunk = sock.recv(expected_length - len(responses))
                if not chunk:
                    raise ConnectionError("Connection closed by server")
                responses.extend(chunk)

            return [b == 1 for b in responses]

        except (socket.timeout, ConnectionError) as e:
            if attempt == retries - 1:
                raise
            time.sleep(0.2 * (attempt + 1))  # Exponential backoff

            # Try to recreate socket if needed
            try:
                sock.close()
                sock = create_socket(sock.getpeername()[0], sock.getpeername()[1])
            except:
                pass


def find_byte(sock: socket.socket, known_bytes: bytes, byte_pos: int,
              ciphertext_block: bytes, retries: int = 3) -> int:
    """Find a single byte using padding oracle with improved error handling."""
    block_size = 16
    padding_value = block_size - byte_pos
    base_q = bytearray([0] * byte_pos)

    # Add known bytes XORed with padding value
    for i in range(len(known_bytes)):
        base_q.append(known_bytes[i] ^ padding_value)

    # Fill remaining positions
    base_q.extend([0] * (block_size - len(base_q) - 1))

    # Test values in smaller batches to reduce network load
    batch_size = 32  # Reduced batch size for better reliability

    for batch_start in range(0, 256, batch_size):
        q_blocks = []
        q_values = []

        for guess in range(batch_start, min(batch_start + batch_size, 256)):
            test_q = bytearray(base_q)
            test_q.append(guess)
            q_blocks.append(bytes(test_q))
            q_values.append(guess)

        try:
            responses = send_and_receive(sock, q_blocks, retries)

            for i, is_valid in enumerate(responses):
                if is_valid:
                    guess_value = q_values[i]

                    # Special handling for last byte to avoid false positives
                    if byte_pos == block_size - 1:
                        # Verify by modifying second-to-last byte
                        verify_q = bytearray(base_q)
                        verify_q.append(guess_value)
                        verify_q[-2] ^= 1

                        verify_responses = send_and_receive(sock, [bytes(verify_q)], retries)

                        if verify_responses[0]:
                            continue  # False positive, keep searching

                        return guess_value ^ 1  # Valid padding found

                    # For other positions, verify it's not a false positive
                    elif byte_pos < block_size - 1:
                        verify_q = bytearray(base_q)
                        verify_q.append(guess_value)
                        verify_q[-2] ^= 1

                        verify_responses = send_and_receive(sock, [bytes(verify_q)], retries)

                        if not verify_responses[0]:
                            return guess_value ^ padding_value
                    else:
                        return guess_value ^ padding_value

        except (socket.error, ConnectionError) as e:
            # If we hit a network error, retry with a fresh socket
            sock.close()
            sock = create_socket(sock.getpeername()[0], sock.getpeername()[1])
            continue

    raise Exception(f"Failed to find byte at position {byte_pos}")


def decrypt_block(sock: socket.socket, ciphertext_block: bytes) -> bytes:
    """Decrypt a single block with improved error handling."""
    block_size = 16
    plaintext = bytearray()

    for i in range(block_size):
        byte_pos = block_size - i - 1
        max_retries = 3

        for attempt in range(max_retries):
            try:
                byte_val = find_byte(sock, plaintext, byte_pos, ciphertext_block)
                plaintext.insert(0, byte_val)
                break
            except Exception as e:
                if attempt == max_retries - 1:
                    raise
                time.sleep(0.5)  # Wait before retry
                # Recreate socket for next attempt
                sock.close()
                sock = create_socket(sock.getpeername()[0], sock.getpeername()[1])

    return bytes(plaintext)


def padding_oracle(case: Dict[str, Any]) -> Dict[str, Any]:
    """Main padding oracle attack function with improved reliability."""
    hostname = case["arguments"]["hostname"]
    port = case["arguments"]["port"]
    iv = base64.b64decode(case["arguments"]["iv"])
    ciphertext = base64.b64decode(case["arguments"]["ciphertext"])

    # Split ciphertext into blocks
    blocks = [ciphertext[i:i + 16] for i in range(0, len(ciphertext), 16)]
    plaintext = bytearray()

    for b in range(len(blocks)):
        # Create new socket for each block to ensure fresh connection
        with create_socket(hostname, port) as sock:
            # Send initial ciphertext block
            sock.sendall(blocks[b])

            # Decrypt the block with the improved method
            try:
                Dk_Cb = decrypt_block(sock, blocks[b])
            except Exception as e:
                # If a block fails, retry once more after a delay
                time.sleep(1)
                with create_socket(hostname, port) as retry_sock:
                    retry_sock.sendall(blocks[b])
                    Dk_Cb = decrypt_block(retry_sock, blocks[b])

            # XOR with previous block or IV
            prev_block = iv if b == 0 else blocks[b - 1]
            plaintext_block = bytes(x ^ y for x, y in zip(Dk_Cb, prev_block))
            plaintext.extend(plaintext_block)

            # Signal completion of this block
            try:
                sock.sendall(struct.pack('<H', 0))
            except:
                pass  # Ignore errors during cleanup

    return {"plaintext": base64.b64encode(bytes(plaintext)).decode('utf-8')}