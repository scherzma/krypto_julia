import base64
import os
import socket
import threading
import time
import random

from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives import padding
from src.testing.padding_oracle_server import PaddingOracleServer
from src.operations.padding_oracle_chaggpt import padding_oracle


def generate_random_bytes(length):
    """Generate random bytes of specified length."""
    return os.urandom(length)


def encrypt_message(key: bytes, iv: bytes, message: bytes) -> bytes:
    """Encrypt a message using AES-CBC with PKCS7 padding."""
    padder = padding.PKCS7(128).padder()
    padded_data = padder.update(message) + padder.finalize()

    cipher = Cipher(algorithms.AES(key), modes.CBC(iv))
    encryptor = cipher.encryptor()
    return encryptor.update(padded_data) + encryptor.finalize()


def create_test_case(plaintext: bytes, port: int = 18652) -> dict:
    """Create a complete test case with known plaintext."""
    # Generate random key and IV
    key = generate_random_bytes(16)
    iv = generate_random_bytes(16)

    # Encrypt the plaintext
    ciphertext = encrypt_message(key, iv, plaintext)

    # Create test case in required format
    return {
        "action": "padding_oracle",
        "arguments": {
            "hostname": "localhost",
            "port": port,
            "iv": base64.b64encode(iv).decode('utf-8'),
            "ciphertext": base64.b64encode(ciphertext).decode('utf-8')
        },
        "expected": {
            "plaintext": base64.b64encode(plaintext).decode('utf-8'),
            "key": base64.b64encode(key).decode('utf-8')
        }
    }


def run_server_thread(key: bytes, port: int):
    """Run the padding oracle server in a separate thread."""
    server = PaddingOracleServer(key, port=port)
    server_thread = threading.Thread(target=server.start)
    server_thread.daemon = True
    server_thread.start()
    return server_thread


def wait_for_server(port: int, retries: int = 5):
    """Wait for server to start accepting connections."""
    for _ in range(retries):
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.connect(("localhost", port))
            sock.close()
            return True
        except ConnectionRefusedError:
            time.sleep(0.5)
    return False


def generate_test_suite():
    """Generate a suite of test cases with varying complexity."""
    test_cases = []
    base_port = 18652

    x = 1

    test_cases.append({
        "name": str(x),
        "plaintext": base64.b64decode(
            "AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0BBQkNERUZHSElKS0xNTk8="),
        "port": base_port + x
    })
    x += 1

    test_cases.append({
        "name": str(x),
        "plaintext": base64.b64decode("AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0BBQkNERUZHSElKS0xNTk8="),
        "port": base_port + x
    })
    x += 1

    test_cases.append({
        "name": str(x),
        "plaintext": base64.b64decode("CSnvU7FHnSeheBxw9L7D/VP/nnX6vuylh+z0iEmhqI2K7kehy0PKhZO20ffYrkbEz+akrgGIBzPdwTBMcndMBXmN02dQUNgyhgrWSjhj+r5DS/zX7Mr1XiIuPQoufCxl"),
        "port": base_port + x
    })

    x += 1

    # Test case 1: Simple ASCII message
    test_cases.append({
        "name": "simple_ascii",
        "plaintext": b"Hello, World!",
        "port": base_port + x
    })
    x += 1

    # Test case 2: Multiple blocks
    test_cases.append({
        "name": "multiple_blocks",
        "plaintext": b"This is a longer message that will span multiple blocks in the encryption.",
        "port": base_port + x
    })

    x += 1

    # Test case 3: Special characters
    test_cases.append({
        "name": "special_chars",
        "plaintext": b"Special chars: !@#$%^&*()",
        "port": base_port + x
    })

    x += 1

    # Test case 4: Binary data
    for j in range(10):
        test_cases.append({
            "name": "binary_data" + str(j),
            "plaintext": bytes([i % 256 for i in range(80)]),
            "port": base_port + x
        })
        x += 1

    for j in range(50):
        test_cases.append({
            "name": "binary_data_random" + str(j),
            "plaintext": bytes([i % 256 for i in range(random.randint(0, 33))]),
            "port": base_port + x
        })
        x += 1

    # Test case 5: Padding oracle attack
    test_cases.append({
        "name": "padding_oracle",
        "plaintext": b"aeg4923gja34g8jadf8adfb80a7fg",
        "port": base_port + x
    })
    x += 1

    # Generate complete test cases
    return {case["name"]: create_test_case(case["plaintext"], case["port"])
            for case in test_cases}


def run_tests(test_cases: dict):
    """Run all test cases and verify results."""
    results = {}

    for name, test_case in test_cases.items():
        print(f"\nRunning test: {name}")
        print(f"  test_case: {test_case}")

        # Start server with the test case's key
        key = base64.b64decode(test_case["expected"]["key"])
        port = test_case["arguments"]["port"]

        server_thread = run_server_thread(key, port)
        if not wait_for_server(port):
            print(f"Failed to start server for test {name}")
            continue

        try:
            # Run the padding oracle attack
            result = padding_oracle(test_case)

            # Verify result
            expected_plaintext = test_case["expected"]["plaintext"]
            actual_plaintext = result["plaintext"]

            success = expected_plaintext == actual_plaintext
            results[name] = {
                "success": success,
                "expected": expected_plaintext,
                "actual": actual_plaintext
            }

            print(f"Test {name}: {'✅ Passed' if success else '❌ Failed'}")
            if not success:
                print(f"  Expected: {expected_plaintext}")
                print(f"  Actual:   {actual_plaintext}")

        except Exception as e:
            results[name] = {
                "success": False,
                "error": str(e)
            }
            print(f"Test {name}: ❌ Failed with error: {e}")

    return results


if __name__ == "__main__":
    print("Generating test cases...")
    test_cases = generate_test_suite()
    print(f"\nTest cases: {test_cases}")

    print("\nRunning tests...")
    results = run_tests(test_cases)

    # Print summary
    total = len(results)
    passed = sum(1 for r in results.values() if r["success"])
    print(f"\nTest Summary: {passed}/{total} passed")