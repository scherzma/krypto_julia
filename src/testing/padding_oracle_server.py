import socket
import sys
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives import padding
import base64
import struct


class PaddingOracleServer:
    def __init__(self, key, host='localhost', port=18652):
        """Initialize the Padding Oracle Server."""
        self.key = base64.b64decode(key) if isinstance(key, str) else key
        self.host = host
        self.port = port
        self.ciphertext = None
        self.block_size = 16

    def check_padding(self, q_block: bytes) -> bool:
        """
        Check if the padding is valid for a given Q block combined with stored ciphertext.
        """
        try:
            # Create AES cipher in CBC mode with zero IV
            cipher = Cipher(algorithms.AES(self.key), modes.CBC(bytes(16)))
            decryptor = cipher.decryptor()

            # Decrypt the data
            decrypted = decryptor.update(self.ciphertext) + decryptor.finalize()

            # XOR with Q block
            decrypted = bytes(a ^ b for a, b in zip(decrypted, q_block))

            # Check PKCS7 padding
            unpadder = padding.PKCS7(128).unpadder()
            unpadder.update(decrypted)
            unpadder.finalize()

            return True
        except (ValueError, Exception):
            return False

    def handle_client(self, client_socket):
        """Handle a single client connection."""
        print(f"Client connected: {client_socket.getpeername()}")
        try:
            # Step 1: Receive initial 16 bytes ciphertext
            self.ciphertext = client_socket.recv(16)
            if len(self.ciphertext) != 16:
                return
            print(f"Received ciphertext: {self.ciphertext}")

            while True:
                # Step 2: Receive 2-byte length field
                length_bytes = client_socket.recv(2)
                if len(length_bytes) != 2:
                    return
                print(f"Received length: {length_bytes}")

                length = struct.unpack('<H', length_bytes)[0]  # little endian
                print(f"Length: {length}")

                # Check for termination
                if length == 0:
                    return

                if length > 256:
                    return

                # Step 3: Receive Q blocks
                q_blocks_total = b''
                remaining = length * 16
                while remaining > 0:
                    chunk = client_socket.recv(remaining)
                    if not chunk:
                        return
                    q_blocks_total += chunk
                    remaining -= len(chunk)
                # print(f"Received Q blocks: {q_blocks_total.hex()}")

                # Process each Q block and prepare response
                response = bytearray()
                for i in range(length):
                    q_block = q_blocks_total[i * 16:(i + 1) * 16]
                    is_valid = self.check_padding(q_block)
                    response.append(0x01 if is_valid else 0x00)

                # Step 4: Send response
                client_socket.send(response)
                print(f"Sent response: {response}")

        except Exception as e:
            print(f"Error handling client: {e}")
        finally:
            client_socket.close()

    def start(self):
        """Start the server."""
        server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            server_socket.bind((self.host, self.port))
            server_socket.listen(1)
            print(f"Server listening on {self.host}:{self.port}")

            while True:
                client_socket, addr = server_socket.accept()
                print(f"Accepted connection from {addr}")
                self.handle_client(client_socket)

        except KeyboardInterrupt:
            print("\nShutting down server...")
        except Exception as e:
            print(f"Server error: {e}")
        finally:
            server_socket.close()


if __name__ == "__main__":
    # Example usage with random key
    if len(sys.argv) != 2:
        print("Usage: python server.py <base64_key>")
        sys.exit(1)

    key = sys.argv[1]
    server = PaddingOracleServer(key)
    server.start()