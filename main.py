import base64
import json
import sys


def add_numbers(case):
    args = case["arguments"]
    return {"sum": args["number1"] + args["number2"]}

def subtract_numbers(case):
    args = case["arguments"]
    return {"difference": args["number1"] - args["number2"]}


def poly2block(case):
    res = 0
    for i in case["arguments"]["coefficients"]:
        res |= 1 << i

    res_bytes = res.to_bytes((res.bit_length() + 7) // 8, byteorder='little')
    res_b64 = base64.b64encode(res_bytes).decode('utf-8')
    return {"block": res_b64}


def block2poly(case):
    res_bytes = base64.b64decode(case["arguments"]["block"])
    coefficients = []

    byte_length = len(res_bytes)

    for byte_index in range(byte_length):
        current_byte = res_bytes[byte_index]
        for bit_index in range(8):  # 8 bits in a byte
            if current_byte & (1 << bit_index):
                coefficients.append(byte_index * 8 + bit_index)

    return {"coefficients": coefficients}

def block2poly2(case):
    res_bytes = base64.b64decode(case["arguments"]["block"])
    res_int = int.from_bytes(res_bytes, byteorder='little')
    coefficients = []

    for i in range(res_int.bit_length()):
        if res_int & (1 << i):
            coefficients.append(i)

    return {"coefficients": coefficients}


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
        "block2poly": block2poly2,
    }

    response = {}
    for id, testcase in data["testcases"].items():
        action = testcase["action"]
        func = action_functions.get(action)
        if func:
            response[id] = func(testcase)
        else:
            print(f"Warning: Unknown action '{action}' for testcase {id}")

    print(json.dumps(response))


if __name__ == "__main__":
    main()
