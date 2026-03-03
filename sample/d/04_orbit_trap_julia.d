import py_runtime;
import std.stdio;
import std.math;
import std.conv;
import std.array;
import std.algorithm;

auto render_orbit_trap_julia(long width, long height, long max_iter, double cx, double cy) {
    ubyte[] pixels = cast(ubyte[])[];
    double __hoisted_cast_1 = to!double((height - 1));
    double __hoisted_cast_2 = to!double((width - 1));
    double __hoisted_cast_3 = to!double(max_iter);
    foreach (y; 0 .. height) {
        double zy0 = ((-1.3) + (2.6 * (cast(double)(y) / cast(double)(__hoisted_cast_1))));
        foreach (x; 0 .. width) {
            double zx = ((-1.9) + (3.8 * (cast(double)(x) / cast(double)(__hoisted_cast_2))));
            double zy = zy0;
            double trap = 1000000000.0;
            long i = 0;
            while ((i < max_iter)) {
                double ax = zx;
                if ((ax < 0.0)) {
                    ax = (-ax);
                }
                double ay = zy;
                if ((ay < 0.0)) {
                    ay = (-ay);
                }
                double dxy = (zx - zy);
                if ((dxy < 0.0)) {
                    dxy = (-dxy);
                }
                if ((ax < trap)) {
                    trap = ax;
                }
                if ((ay < trap)) {
                    trap = ay;
                }
                if ((dxy < trap)) {
                    trap = dxy;
                }
                double zx2 = (zx * zx);
                double zy2 = (zy * zy);
                if (((zx2 + zy2) > 4.0)) {
                    break_;
                }
                zy = (((2.0 * zx) * zy) + cy);
                zx = ((zx2 - zy2) + cx);
                i += 1;
            }
            long r = 0;
            long g = 0;
            long b = 0;
            if ((i >= max_iter)) {
                r = 0;
                g = 0;
                b = 0;
            } else {
                double trap_scaled = (trap * 3.2);
                if ((trap_scaled > 1.0)) {
                    trap_scaled = 1.0;
                }
                if ((trap_scaled < 0.0)) {
                    trap_scaled = 0.0;
                }
                double t = (cast(double)(i) / cast(double)(__hoisted_cast_3));
                long tone = to!long((255.0 * (1.0 - trap_scaled)));
                r = to!long((tone * (0.35 + (0.65 * t))));
                g = to!long((tone * (0.15 + (0.85 * (1.0 - t)))));
                b = to!long((255.0 * (0.25 + (0.75 * t))));
                if ((r > 255)) {
                    r = 255;
                }
                if ((g > 255)) {
                    g = 255;
                }
                if ((b > 255)) {
                    b = 255;
                }
            }
            pixels ~= r;
            pixels ~= g;
            pixels ~= b;
        }
    }
    return pixels;
}

auto run_04_orbit_trap_julia() {
    long width = 1920;
    long height = 1080;
    long max_iter = 1400;
    string out_path = "sample/out/04_orbit_trap_julia.png";
    double start = pyPerfCounter();
    ubyte[] pixels = render_orbit_trap_julia(width, height, max_iter, (-0.7269), 0.1889);
    writeRgbPng(out_path, width, height, pixels);
    double elapsed = (pyPerfCounter() - start);
    writeln("output:", out_path);
    writeln("size:", width, "x", height);
    writeln("max_iter:", max_iter);
    writeln("elapsed_sec:", elapsed);
}


void main() {
    run_04_orbit_trap_julia();
}
