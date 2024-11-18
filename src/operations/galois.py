from functools import reduce
from src.utils.conversion import frombase64, tobase64l, tobase64b, reverse_bits, reverse_endian, frombase64b
from src.operations.polynomial import num_to_coef_gcm

def gfmul_int_xex(a: int, b: int, modulus: int = 0x100000000000000000000000000000087) -> int:
    """Perform Galois field multiplication using XEX semantics."""
    res = reduce(lambda x, i: x ^ ((a << i) if b & (1 << i) else 0), range(b.bit_length()), 0)
    return reduce(lambda x, i: x ^ ((modulus << (i - 128)) if x & (1 << i) else 0),
                 range(res.bit_length()-1, 127, -1), res)


def gfmul_int_gcm_bytes(a: bytes, b: bytes, modulus: int = 0x100000000000000000000000000000087) -> bytes:
    a_int = int.from_bytes(a, byteorder='big')
    b_int = int.from_bytes(b, byteorder='big')
    return int.to_bytes(gfmul_int_gcm(a_int, b_int, modulus), 16, byteorder='big')


def gfmul_int_gcm(a: int, b: int, modulus: int = 0x100000000000000000000000000000087) -> int:
    """Perform Galois field multiplication using GCM semantics."""
    a_r = reverse_bits(a)
    b_r = reverse_bits(b)

    product = reverse_bits(gfmul_int_xex(a_r, b_r, modulus))
    return product


def gfmul(case: dict, modulus: int = 0x100000000000000000000000000000087) -> dict:
    """Wrapper function for Galois field multiplication."""
    if case["arguments"]["semantic"] == "xex":
        a, b = frombase64(case["arguments"]["a"]), frombase64(case["arguments"]["b"])
        return {"product": tobase64l(gfmul_int_xex(a, b, modulus))}
    elif case["arguments"]["semantic"] == "gcm":
        a = frombase64b(case["arguments"]["a"])
        b = frombase64b(case["arguments"]["b"])
        return {"product": tobase64b(gfmul_int_gcm(a, b, modulus))}