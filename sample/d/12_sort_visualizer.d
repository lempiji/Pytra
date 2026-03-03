import py_runtime;
import std.stdio;
import std.math;
import std.conv;
import std.array;
import std.algorithm;

auto render(long[] values, long w, long h) {
    auto frame = cast(ubyte[])[];
    auto n = cast(long)(values.length);
    auto bar_w = (cast(double)(w) / cast(double)(n));
    double __hoisted_cast_1 = to!double(n);
    double __hoisted_cast_2 = to!double(h);
    foreach (i; 0 .. n) {
        auto x0 = to!long((i * bar_w));
        auto x1 = to!long(((i + 1) * bar_w));
        if ((x1 <= x0)) {
            x1 = (x0 + 1);
        }
        auto bh = to!long(((cast(double)(values[i]) / cast(double)(__hoisted_cast_1)) * __hoisted_cast_2));
        auto y = (h - bh);
        foreach (y; y .. h) {
            foreach (x; x0 .. x1) {
                frame[((y * w) + x)] = 255;
            }
        }
    }
    return bytes(frame);
}

auto run_12_sort_visualizer() {
    auto w = 320;
    auto h = 180;
    auto n = 124;
    auto out_path = "sample/out/12_sort_visualizer.gif";
    auto start = pyPerfCounter();
    long[] values = [];
    foreach (i; 0 .. n) {
        values ~= pyMod(((i * 37) + 19), n);
    }
    auto[] frames = [render(values, w, h)];
    auto frame_stride = 16;
    auto op = 0;
    foreach (i; 0 .. n) {
        auto swapped = false;
        foreach (j; 0 .. ((n - i) - 1)) {
            if ((values[j] > values[(j + 1)])) {
                tuple(values[j], values[(j + 1)]) = tuple(values[(j + 1)], values[j]);
                swapped = true;
            }
            if ((pyMod(op, frame_stride) == 0)) {
                frames ~= render(values, w, h);
            }
            op += 1;
        }
        if (pyTruthy((!pyTruthy(swapped)))) {
            break_;
        }
    }
    save_gif(out_path, w, h, frames, grayscale_palette());
    auto elapsed = (pyPerfCounter() - start);
    writeln("output:", out_path);
    writeln("frames:", cast(long)(frames.length));
    writeln("elapsed_sec:", elapsed);
}


void main() {
    run_12_sort_visualizer();
}
