// D runtime for Pytra
module py_runtime;

import std.stdio;
import std.math;
import std.conv;
import std.file;
import std.path;
import core.time;

double pyPerfCounter() {
    auto t = MonoTime.currTime;
    return t.total!"nsecs" / 1_000_000_000.0;
}

// Pytra built-ins
long pyInt(T)(T v) {
    return to!long(v);
}

double pyFloat(T)(T v) {
    return to!double(v);
}

string pyStr(T)(T v) {
    return to!string(v);
}

long pyLen(T)(T v) {
    return cast(long)(v.length);
}

bool pyTruthy(T)(T v) {
    static if (is(T == bool)) {
        return v;
    } else static if (is(T == long) || is(T == int) || is(T == double) || is(T == float)) {
        return v != 0;
    } else static if (is(T == string)) {
        return v.length > 0;
    } else static if (is(T : Object)) {
        return v !is null;
    } else {
        return v.length > 0;
    }
}

// Python-style floor division
long pyFloorDiv(long a, long b) {
    if (b == 0) return 0;
    long r = a / b;
    if ((a ^ b) < 0 && r * b != a) r -= 1;
    return r;
}

double pyFloorDiv(double a, double b) {
    if (b == 0.0) return 0.0;
    return floor(a / b);
}

// Python-style modulo
long pyMod(long a, long b) {
    if (b == 0) return 0;
    long r = a % b;
    if ((r > 0 && b < 0) || (r < 0 && b > 0)) r += b;
    return r;
}

double pyMod(double a, double b) {
    if (b == 0.0) return 0.0;
    double r = a % b;
    if ((r > 0.0 && b < 0.0) || (r < 0.0 && b > 0.0)) r += b;
    return r;
}

// -------- PNG helper --------

private ubyte[4] u32be(uint v) {
    return [
        cast(ubyte)((v >> 24) & 0xFF),
        cast(ubyte)((v >> 16) & 0xFF),
        cast(ubyte)((v >> 8) & 0xFF),
        cast(ubyte)(v & 0xFF),
    ];
}

private ubyte[2] u16le(uint v) {
    return [
        cast(ubyte)(v & 0xFF),
        cast(ubyte)((v >> 8) & 0xFF),
    ];
}

private uint pyCrc32(const ubyte[] data) {
    enum uint poly = 0xEDB8_8320;
    uint crc = 0xFFFF_FFFF;
    foreach (b; data) {
        crc ^= b;
        foreach (_; 0 .. 8) {
            if ((crc & 1) != 0)
                crc = (crc >> 1) ^ poly;
            else
                crc = crc >> 1;
        }
    }
    return crc ^ 0xFFFF_FFFF;
}

private uint pyAdler32(const ubyte[] data) {
    enum uint mod = 65521;
    uint s1 = 1;
    uint s2 = 0;
    foreach (b; data) {
        s1 += b;
        if (s1 >= mod) s1 -= mod;
        s2 += s1;
        s2 %= mod;
    }
    return ((s2 << 16) | s1) & 0xFFFF_FFFF;
}

private ubyte[] pyZlibDeflateStore(const ubyte[] data) {
    ubyte[] out_;
    out_ ~= [cast(ubyte)0x78, cast(ubyte)0x01];
    size_t n = data.length;
    size_t pos = 0;
    while (pos < n) {
        size_t remain = n - pos;
        size_t chunkLen = remain > 65535 ? 65535 : remain;
        ubyte finalFlag = (pos + chunkLen >= n) ? 1 : 0;
        out_ ~= finalFlag;
        uint cl = cast(uint) chunkLen;
        out_ ~= u16le(cl);
        out_ ~= u16le(0xFFFF ^ cl);
        out_ ~= data[pos .. pos + chunkLen];
        pos += chunkLen;
    }
    out_ ~= u32be(pyAdler32(data));
    return out_;
}

private ubyte[] pyPngChunk(const ubyte[4] chunkType, const ubyte[] data) {
    ubyte[] out_;
    out_ ~= u32be(cast(uint) data.length);
    out_ ~= chunkType[];
    out_ ~= data;
    ubyte[] crcData;
    crcData ~= chunkType[];
    crcData ~= data;
    out_ ~= u32be(pyCrc32(crcData));
    return out_;
}

private void pyWriteFileBytes(string path_, const ubyte[] data) {
    string dir = dirName(path_);
    if (dir.length > 0 && dir != ".") {
        mkdirRecurse(dir);
    }
    std.file.write(path_, data);
}

void writeRgbPng(string path_, long width, long height, ubyte[] pixels) {
    int w = cast(int) width;
    int h = cast(int) height;
    int expected = w * h * 3;
    if (pixels.length != expected) {
        throw new Exception("pixels length mismatch");
    }

    ubyte[] scanlines;
    int rowBytes = w * 3;
    foreach (y; 0 .. h) {
        scanlines ~= cast(ubyte) 0;
        int start = y * rowBytes;
        scanlines ~= pixels[start .. start + rowBytes];
    }

    ubyte[] ihdr;
    ihdr ~= u32be(cast(uint) w);
    ihdr ~= u32be(cast(uint) h);
    ihdr ~= [cast(ubyte) 8, cast(ubyte) 2, cast(ubyte) 0, cast(ubyte) 0, cast(ubyte) 0];

    ubyte[] idat = pyZlibDeflateStore(scanlines);

    ubyte[] png;
    png ~= [cast(ubyte) 0x89, cast(ubyte) 0x50, cast(ubyte) 0x4E, cast(ubyte) 0x47,
            cast(ubyte) 0x0D, cast(ubyte) 0x0A, cast(ubyte) 0x1A, cast(ubyte) 0x0A];
    png ~= pyPngChunk(cast(ubyte[4])[0x49, 0x48, 0x44, 0x52], ihdr);
    png ~= pyPngChunk(cast(ubyte[4])[0x49, 0x44, 0x41, 0x54], idat);
    png ~= pyPngChunk(cast(ubyte[4])[0x49, 0x45, 0x4E, 0x44], cast(ubyte[])[] );

    pyWriteFileBytes(path_, png);
}

// -------- GIF helper --------

private ubyte[] pyGifLzwEncode(const ubyte[] data, int minCodeSize = 8) {
    if (data.length == 0) return [];

    int clearCode = 1 << minCodeSize;
    int endCode = clearCode + 1;
    int codeSize = minCodeSize + 1;

    ubyte[] out_;
    int bitBuffer = 0;
    int bitCount = 0;

    void writeCode(int code) {
        bitBuffer |= (code << bitCount);
        bitCount += codeSize;
        while (bitCount >= 8) {
            out_ ~= cast(ubyte)(bitBuffer & 0xFF);
            bitBuffer >>= 8;
            bitCount -= 8;
        }
    }

    writeCode(clearCode);
    foreach (b; data) {
        writeCode(b & 0xFF);
        writeCode(clearCode);
    }
    writeCode(endCode);
    if (bitCount > 0) out_ ~= cast(ubyte)(bitBuffer & 0xFF);
    return out_;
}

void saveGif(string path_, long width, long height, ubyte[][] frames,
             ubyte[] palette, int delayCentiseconds = 4, int loop = 0) {
    int w = cast(int) width;
    int h = cast(int) height;
    int framePixels = w * h;

    if (palette.length != 256 * 3)
        throw new Exception("palette must be 256*3 bytes");

    ubyte[] out_;
    // GIF89a header
    out_ ~= [cast(ubyte) 0x47, cast(ubyte) 0x49, cast(ubyte) 0x46,
             cast(ubyte) 0x38, cast(ubyte) 0x39, cast(ubyte) 0x61];
    out_ ~= u16le(cast(uint) w);
    out_ ~= u16le(cast(uint) h);
    out_ ~= [cast(ubyte) 0xF7, cast(ubyte) 0, cast(ubyte) 0];
    out_ ~= palette;

    // NETSCAPE2.0 extension (looping)
    out_ ~= [cast(ubyte) 0x21, cast(ubyte) 0xFF, cast(ubyte) 0x0B];
    out_ ~= cast(ubyte[])"NETSCAPE2.0";
    out_ ~= [cast(ubyte) 0x03, cast(ubyte) 0x01];
    out_ ~= u16le(cast(uint) loop);
    out_ ~= cast(ubyte) 0;

    foreach (fr; frames) {
        if (fr.length != framePixels)
            throw new Exception("frame size mismatch");

        // Graphic Control Extension
        out_ ~= [cast(ubyte) 0x21, cast(ubyte) 0xF9,
                 cast(ubyte) 0x04, cast(ubyte) 0x00];
        out_ ~= u16le(cast(uint) delayCentiseconds);
        out_ ~= [cast(ubyte) 0x00, cast(ubyte) 0x00];

        // Image Descriptor
        out_ ~= cast(ubyte) 0x2C;
        out_ ~= u16le(0);
        out_ ~= u16le(0);
        out_ ~= u16le(cast(uint) w);
        out_ ~= u16le(cast(uint) h);
        out_ ~= cast(ubyte) 0;

        // LZW minimum code size
        out_ ~= cast(ubyte) 8;
        ubyte[] compressed = pyGifLzwEncode(fr, 8);
        size_t pos = 0;
        while (pos < compressed.length) {
            size_t remain = compressed.length - pos;
            size_t chunkLen = remain > 255 ? 255 : remain;
            out_ ~= cast(ubyte) chunkLen;
            out_ ~= compressed[pos .. pos + chunkLen];
            pos += chunkLen;
        }
        out_ ~= cast(ubyte) 0;
    }

    out_ ~= cast(ubyte) 0x3B;
    pyWriteFileBytes(path_, out_);
}
