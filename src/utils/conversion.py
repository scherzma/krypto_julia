import base64

def frombase64(s: str) -> int:
    """Convert base64 string to integer using little-endian."""
    return int.from_bytes(base64.b64decode(s), byteorder='little')

def frombase64b(s: str) -> int:
    """Convert base64 string to integer using big-endian."""
    return int.from_bytes(base64.b64decode(s), byteorder='big')

def tobase64l(number: int) -> str:
    """Convert integer to base64 string using little-endian."""
    return base64.b64encode(number.to_bytes(16, byteorder='little')).decode('utf-8')

def tobase64b(number: int) -> str:
    """Convert integer to base64 string using big-endian."""
    return base64.b64encode(number.to_bytes(16, byteorder='big')).decode('utf-8')

def reverse_endian(num: int, bytes_length: int = 16) -> int:
    """Reverse the endianness of a number."""
    return int.from_bytes(num.to_bytes(bytes_length, byteorder='little'), byteorder='big')

def reverse_bits(num: int, length: int = 128) -> int:
    """Reverse the bits of a number."""
    res = 0
    for i in range(length):
        if num & (1 << i):
            res |= 1 << (length-1 - i)
    return res