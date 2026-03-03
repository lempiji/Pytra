// D runtime for Pytra
module py_runtime;

import std.stdio;
import std.math;
import std.conv;
import std.datetime;
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

// Runtime helper stubs
void writeRgbPng(string path, long width, long height, ubyte[] pixels) {
    // stub
}
