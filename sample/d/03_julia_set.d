import py_runtime;
import std.stdio;
import std.math;
import std.conv;
import std.array;
import std.algorithm;

auto render_julia(long width, long height, long max_iter, double cx, double cy) {
    ubyte[] pixels = cast(ubyte[])[];
    double __hoisted_cast_1 = to!double((height - 1));
    double __hoisted_cast_2 = to!double((width - 1));
    double __hoisted_cast_3 = to!double(max_iter);
    foreach (y; 0 .. height) {
        double zy0 = ((-1.2) + (2.4 * (cast(double)(y) / cast(double)(__hoisted_cast_1))));
        foreach (x; 0 .. width) {
            double zx = ((-1.8) + (3.6 * (cast(double)(x) / cast(double)(__hoisted_cast_2))));
            double zy = zy0;
            long i = 0;
            while ((i < max_iter)) {
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
                double t = (cast(double)(i) / cast(double)(__hoisted_cast_3));
                r = to!long((255.0 * (0.2 + (0.8 * t))));
                g = to!long((255.0 * (0.1 + (0.9 * (t * t)))));
                b = to!long((255.0 * (1.0 - t)));
            }
            pixels ~= r;
            pixels ~= g;
            pixels ~= b;
        }
    }
    return pixels;
}

auto run_julia() {
    long width = 3840;
    long height = 2160;
    long max_iter = 20000;
    string out_path = "sample/out/03_julia_set.png";
    double start = pyPerfCounter();
    ubyte[] pixels = render_julia(width, height, max_iter, (-0.8), 0.156);
    writeRgbPng(out_path, width, height, pixels);
    double elapsed = (pyPerfCounter() - start);
    writeln("output:", out_path);
    writeln("size:", width, "x", height);
    writeln("max_iter:", max_iter);
    writeln("elapsed_sec:", elapsed);
}


void main() {
    run_julia();
}
