
import base64
import json
import sys
from functools import reduce
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes


def poly2block(case):
    res = coefficients2number(case["arguments"]["coefficients"])
    res_bytes = res.to_bytes((res.bit_length() + 7) // 8, byteorder='little')
    return {"block": base64.b64encode(res_bytes).decode('utf-8')}


def block2poly(case):
    return {"coefficients": number2coefficients(frombase64(case["arguments"]["block"]))}

coefficients2number = lambda coefficients: sum(1 << i for i in coefficients)
number2coefficients = lambda number: [i for i in range(number.bit_length()) if number & (1 << i)]
add_numbers = lambda case: {"sum": case["arguments"]["number1"] + case["arguments"]["number2"]}
subtract_numbers = lambda case: {"difference": case["arguments"]["number1"] - case["arguments"]["number2"]}
frombase64 = lambda s: int.from_bytes(base64.b64decode(s), byteorder='little')
tobase64l = lambda number: base64.b64encode(number.to_bytes(16, byteorder='little')).decode('utf-8')
tobase64b = lambda number: base64.b64encode(number.to_bytes(16, byteorder='big')).decode('utf-8')


def gfmul(case, modulus=0x100000000000000000000000000000087):
    a, b = frombase64(case["arguments"]["a"]), frombase64(case["arguments"]["b"])
    res = reduce(lambda x,i: x ^ ((a << i) if b & (1 << i) else 0), range(b.bit_length()), 0)
    res = reduce(lambda x,i: x ^ ((modulus << (i - 128)) if x & (1 << i) else 0), range(res.bit_length()-1, 127, -1), res)

    return {"product": tobase64l(res)}

def sea128(case):
    arguments = case["arguments"]
    mode = arguments["mode"]
    key = arguments["key"]
    input_data = arguments["input"]

    sea128_const = 0xc0ffeec0ffeec0ffeec0ffeec0ffee11

    key_bytes = base64.b64decode(key)
    input_bytes = base64.b64decode(input_data)

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

    return {"output": tobase64b(int_result)}


def xex(case):
    from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
    arguments = case["arguments"]
    mode = arguments["mode"]
    key = arguments["key"]
    tweak = arguments["tweak"]
    input_data = arguments["input"]

    key_bytes = base64.b64decode(key)
    tweak_bytes = base64.b64decode(tweak)
    input_bytes = base64.b64decode(input_data)

    if len(key_bytes) != 32:
        raise ValueError("Key must be 256 bits (32 bytes) for XEX.")

    k1 = key_bytes[:16]
    k2 = key_bytes[16:]

    # Helper functions for SEA-128 encryption and decryption
    def sea128_encrypt(key_bytes, input_bytes):
        sea128_const = 0xc0ffeec0ffeec0ffeec0ffeec0ffee11
        cipher = Cipher(algorithms.AES(key_bytes), modes.ECB())
        encryptor = cipher.encryptor()
        aes_result = encryptor.update(input_bytes) + encryptor.finalize()
        aes_int = int.from_bytes(aes_result, byteorder='big')
        int_result = aes_int ^ sea128_const
        result_bytes = int_result.to_bytes(16, byteorder='big')
        return result_bytes

    def sea128_decrypt(key_bytes, input_bytes):
        sea128_const = 0xc0ffeec0ffeec0ffeec0ffeec0ffee11
        input_int = int.from_bytes(input_bytes, byteorder='big')
        xored = input_int ^ sea128_const
        xored_bytes = xored.to_bytes(16, byteorder='big')
        cipher = Cipher(algorithms.AES(key_bytes), modes.ECB())
        decryptor = cipher.decryptor()
        final_bytes = decryptor.update(xored_bytes) + decryptor.finalize()
        return final_bytes

    # Compute L = E_k2(tweak)
    L_bytes = sea128_encrypt(k2, tweak_bytes)
    L_int = int.from_bytes(L_bytes, byteorder='big')

    # Process input in blocks of 16 bytes
    num_blocks = len(input_bytes) // 16
    output_bytes = b''

    modulus = 0x87  # x^7 + x^2 + x + 1

    M_int = L_int
    for i in range(num_blocks):
        # Compute M_i
        M_i_int = M_int

        # Get the block
        block = input_bytes[i*16:(i+1)*16]
        block_int = int.from_bytes(block, byteorder='big')

        # For encryption or decryption
        if mode == "encrypt":
            temp = block_int ^ M_i_int
            # Encrypt with SEA-128 and k1
            temp_bytes = temp.to_bytes(16, byteorder='big')
            temp_encrypted_bytes = sea128_encrypt(k1, temp_bytes)
            temp_encrypted_int = int.from_bytes(temp_encrypted_bytes, byteorder='big')
            output_int = temp_encrypted_int ^ M_i_int
        elif mode == "decrypt":
            temp = block_int ^ M_i_int
            # Decrypt with SEA-128 and k1
            temp_bytes = temp.to_bytes(16, byteorder='big')
            temp_decrypted_bytes = sea128_decrypt(k1, temp_bytes)
            temp_decrypted_int = int.from_bytes(temp_decrypted_bytes, byteorder='big')
            output_int = temp_decrypted_int ^ M_i_int
        else:
            raise ValueError("Invalid mode for xex.")

        # Append output
        output_bytes += output_int.to_bytes(16, byteorder='big')

        # Update M_int for next block (multiply by alpha)
        msb = (M_int >> 127) & 1
        M_int = (M_int << 1) & ((1 << 128) - 1)
        if msb:
            M_int ^= modulus

    # Encode output
    output_base64 = base64.b64encode(output_bytes).decode('utf-8')

    return {"output": output_base64}




def main():
    file = "./sample.json"
    if len(sys.argv) > 1:
        file = sys.argv[1]

    with open(file, "r") as f:
        data = json.load(f)

    action_functions = {
        "add_numbers": add_numbers,
        "subtract_numbers": subtract_numbers,
        "poly2block": poly2block,
        "block2poly": block2poly,
        "gfmul": gfmul,
        "sea128": sea128,
        "xex": xex,
    }

    response = {}
    for id, testcase in data["testcases"].items():
        action = testcase["action"]
        func = action_functions.get(action)
        if func:
            response[id] = func(testcase)
        else:
            print(f"Warning: Unknown action '{action}' for testcase {id}")

    print(json.dumps(response, indent=2))


if __name__ == "__main__":
    main()
