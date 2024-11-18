from src.utils.conversion import tobase64l, frombase64, reverse_endian
import base64

def coef_to_num_gcm(coefficients: list) -> int:
    """Convert coefficients to number using GCM semantics."""
    res = 0
    for coefficient in coefficients:
        if coefficient < 128:
            res |= 1 << 127 - coefficient
    return res

def num_to_coef_gcm(number: int) -> list:
    """Convert number to coefficients using GCM semantics."""
    coefficients = []
    for i in range(number.bit_length()):
        if number & 1 << i:
            coefficients.append(127 - i)
    coefficients.sort()
    return coefficients

def coef_to_num_xex(coefficients: list) -> int:
    """Convert coefficients to number using XEX semantics."""
    return sum(1 << i for i in coefficients)

def num_to_coef_xex(number: int) -> list:
    """Convert number to coefficients using XEX semantics."""
    return [i for i in range(number.bit_length()) if number & (1 << i)]

def poly2block(case: dict) -> dict:
    """Convert polynomial to block based on semantics."""
    if case["arguments"]["semantic"] == "xex":
        return {"block": tobase64l(coef_to_num_xex(case["arguments"]["coefficients"]))}
    elif case["arguments"]["semantic"] == "gcm":
        res = coef_to_num_gcm(case["arguments"]["coefficients"])
        res_bytes = res.to_bytes(16, byteorder='big')
        return {"block": base64.b64encode(res_bytes).decode('utf-8')}

def block2poly(case: dict) -> dict:
    """Convert block to polynomial based on semantics."""
    if case["arguments"]["semantic"] == "xex":
        return {"coefficients": num_to_coef_xex(frombase64(case["arguments"]["block"]))}
    elif case["arguments"]["semantic"] == "gcm":
        number = reverse_endian(frombase64(case["arguments"]["block"]))
        return {"coefficients": num_to_coef_gcm(number)}