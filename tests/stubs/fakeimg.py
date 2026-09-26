"""Real, decodable PNG and JPEG files of any size, standard library only (tests run without Pillow)."""
import struct
import zlib


def png(path, w, h, rgb=(200, 90, 40)):
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
    row = b"\x00" + bytes(rgb) * w
    body = zlib.compress(row * h, 9)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
                + chunk(b"IDAT", body) + chunk(b"IEND", b""))


def jpeg(path, w, h, comment=b""):
    """Baseline grayscale JPEG of mid-gray: every 8x8 block is DC 0 plus end-of-block, 2 bits each."""
    def seg(marker, data):
        return b"\xff" + marker + struct.pack(">H", len(data) + 2) + data
    one_symbol = bytes([1] + [0] * 15) + b"\x00"  # a Huffman table holding one 1-bit code for symbol 0
    blocks = ((w + 7) // 8) * ((h + 7) // 8)
    nbits = 2 * blocks
    scan = b"\x00" * (nbits // 8)
    if nbits % 8:
        scan += bytes([(1 << (8 - nbits % 8)) - 1])
    out = b"\xff\xd8"
    if comment:
        out += seg(b"\xfe", comment)
    out += seg(b"\xdb", b"\x00" + b"\x01" * 64)
    out += seg(b"\xc0", struct.pack(">BHHB", 8, h, w, 1) + b"\x01\x11\x00")
    out += seg(b"\xc4", b"\x00" + one_symbol) + seg(b"\xc4", b"\x10" + one_symbol)
    out += seg(b"\xda", b"\x01\x01\x00\x00\x3f\x00") + scan + b"\xff\xd9"
    with open(path, "wb") as f:
        f.write(out)


def dims(path):
    """(format, w, h) read from the file header: png, jpeg or ('?', 0, 0)."""
    d = open(path, "rb").read()
    if d[:8] == b"\x89PNG\r\n\x1a\n":
        return ("png",) + struct.unpack(">II", d[16:24])
    if d[:2] == b"\xff\xd8":
        i = 2
        while i + 9 < len(d):
            if d[i] != 0xFF:
                i += 1
                continue
            m = d[i + 1]
            if 0xC0 <= m <= 0xCF and m not in (0xC4, 0xC8, 0xCC):
                h, w = struct.unpack(">HH", d[i + 5:i + 9])
                return ("jpeg", w, h)
            i += 2 + struct.unpack(">H", d[i + 2:i + 4])[0]
    return ("?", 0, 0)
