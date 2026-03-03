import py_runtime;
import std.stdio;
import std.math;
import std.conv;
import std.array;
import std.algorithm;

auto escape_count(double cx, double cy, long max_iter) {
    double x = 0.0;
    double y = 0.0;
    foreach (i; 0 .. max_iter) {
        double x2 = (x * x);
        double y2 = (y * y);
        if (((x2 + y2) > 4.0)) {
            return i;
        }
        y = (((2.0 * x) * y) + cy);
        x = ((x2 - y2) + cx);
    }
    return max_iter;
}

auto color_map(long iter_count, long max_iter) {
    if ((iter_count >= max_iter)) {
        return tuple(0, 0, 0);
    }
    double t = (cast(double)(iter_count) / cast(double)(max_iter));
    long r = to!long((255.0 * (t * t)));
    long g = to!long((255.0 * t));
    long b = to!long((255.0 * (1.0 - t)));
    return tuple(r, g, b);
}

auto render_mandelbrot(long width, long height, long max_iter, double x_min, double x_max, double y_min, double y_max) {
    ubyte[] pixels = cast(ubyte[])[];
    double __hoisted_cast_1 = to!double((height - 1));
    double __hoisted_cast_2 = to!double((width - 1));
    double __hoisted_cast_3 = to!double(max_iter);
    foreach (y; 0 .. height) {
        double py = (y_min + ((y_max - y_min) * (cast(double)(y) / cast(double)(__hoisted_cast_1))));
        foreach (x; 0 .. width) {
            double px = (x_min + ((x_max - x_min) * (cast(double)(x) / cast(double)(__hoisted_cast_2))));
            long it = escape_count(px, py, max_iter);
            long r;
            long g;
            long b;
            if ((it >= max_iter)) {
                r = 0;
                g = 0;
                b = 0;
            } else {
                double t = (cast(double)(it) / cast(double)(__hoisted_cast_3));
                r = to!long((255.0 * (t * t)));
                g = to!long((255.0 * t));
                b = to!long((255.0 * (1.0 - t)));
            }
            pixels ~= r;
            pixels ~= g;
            pixels ~= b;
        }
    }
    return pixels;
}

auto run_mandelbrot() {
    long width = 1600;
    long height = 1200;
    long max_iter = 1000;
    string out_path = "sample/out/01_mandelbrot.png";
    double start = pyPerfCounter();
    ubyte[] pixels = render_mandelbrot(width, height, max_iter, (-2.2), 1.0, (-1.2), 1.2);
    writeRgbPng(out_path, width, height, pixels);
    double elapsed = (pyPerfCounter() - start);
    writeln("output:", out_path);
    writeln("size:", width, "x", height);
    writeln("max_iter:", max_iter);
    writeln("elapsed_sec:", elapsed);
}


void main() {
    run_mandelbrot();
}
