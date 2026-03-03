import py_runtime;
import std.stdio;
import std.math;
import std.conv;
import std.array;
import std.algorithm;

auto palette() {
    auto p = cast(ubyte[])[];
    foreach (i; 0 .. 256) {
        auto r = min(255, to!long((20 + (i * 0.9))));
        auto g = min(255, to!long((10 + (i * 0.7))));
        auto b = min(255, (30 + i));
        p ~= r;
        p ~= g;
        p ~= b;
    }
    return bytes(p);
}

auto scene(double x, double y, double light_x, double light_y) {
    auto x1 = (x + 0.45);
    auto y1 = (y + 0.2);
    auto x2 = (x - 0.35);
    auto y2 = (y - 0.15);
    auto r1 = sqrt(cast(double)(((x1 * x1) + (y1 * y1))));
    auto r2 = sqrt(cast(double)(((x2 * x2) + (y2 * y2))));
    auto blob = (math.exp((((-7.0) * r1) * r1)) + math.exp((((-8.0) * r2) * r2)));
    auto lx = (x - light_x);
    auto ly = (y - light_y);
    auto l = sqrt(cast(double)(((lx * lx) + (ly * ly))));
    auto lit = (cast(double)(1.0) / cast(double)((1.0 + ((3.5 * l) * l))));
    auto v = to!long((((255.0 * blob) * lit) * 5.0));
    return min(255, max(0, v));
}

auto run_14_raymarching_light_cycle() {
    auto w = 320;
    auto h = 240;
    auto frames_n = 84;
    auto out_path = "sample/out/14_raymarching_light_cycle.gif";
    auto start = pyPerfCounter();
    auto[] frames = [];
    double __hoisted_cast_1 = to!double(frames_n);
    double __hoisted_cast_2 = to!double((h - 1));
    double __hoisted_cast_3 = to!double((w - 1));
    foreach (t; 0 .. frames_n) {
        auto frame = cast(ubyte[])[];
        auto a = (((cast(double)(t) / cast(double)(__hoisted_cast_1)) * math.pi) * 2.0);
        auto light_x = (0.75 * math.cos(a));
        auto light_y = (0.55 * math.sin((a * 1.2)));
        foreach (y; 0 .. h) {
            auto row_base = (y * w);
            auto py = (((cast(double)(y) / cast(double)(__hoisted_cast_2)) * 2.0) - 1.0);
            foreach (x; 0 .. w) {
                auto px = (((cast(double)(x) / cast(double)(__hoisted_cast_3)) * 2.0) - 1.0);
                frame[(row_base + x)] = scene(px, py, light_x, light_y);
            }
        }
        frames ~= bytes(frame);
    }
    save_gif(out_path, w, h, frames, palette());
    auto elapsed = (pyPerfCounter() - start);
    writeln("output:", out_path);
    writeln("frames:", frames_n);
    writeln("elapsed_sec:", elapsed);
}


void main() {
    run_14_raymarching_light_cycle();
}
