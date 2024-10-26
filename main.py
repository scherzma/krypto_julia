
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

def xes(case):
    arguments = case["arguments"]
    mode = arguments["mode"]
    key = arguments["key"]
    tweak = arguments["tweak"]
    input_data = arguments["input"]




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
        "xex": xes,
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
