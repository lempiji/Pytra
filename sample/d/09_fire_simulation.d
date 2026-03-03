import py_runtime;
import std.stdio;
import std.math;
import std.conv;
import std.array;
import std.algorithm;

auto fire_palette() {
    auto p = cast(ubyte[])[];
    foreach (i; 0 .. 256) {
        auto r = 0;
        auto g = 0;
        auto b = 0;
        if ((i < 85)) {
            r = (i * 3);
            g = 0;
            b = 0;
        } else
        if ((i < 170)) {
            r = 255;
            g = ((i - 85) * 3);
            b = 0;
        } else {
            r = 255;
            g = 255;
            b = ((i - 170) * 3);
        }
        p ~= r;
        p ~= g;
        p ~= b;
    }
    return bytes(p);
}

auto run_09_fire_simulation() {
    auto w = 380;
    auto h = 260;
    auto steps = 420;
    auto out_path = "sample/out/09_fire_simulation.gif";
    auto start = pyPerfCounter();
    long[][] heat = null /* ListComp */;
    auto[] frames = [];
    foreach (t; 0 .. steps) {
        foreach (x; 0 .. w) {
            auto val = (170 + pyMod(((x * 13) + (t * 17)), 86));
            heat[(h - 1)][x] = val;
        }
        foreach (y; 1 .. h) {
            foreach (x; 0 .. w) {
                auto a = heat[y][x];
                auto b = heat[y][pyMod(((x - 1) + w), w)];
                auto c = heat[y][pyMod((x + 1), w)];
                auto d = heat[pyMod((y + 1), h)][x];
                auto v = pyFloorDiv((((a + b) + c) + d), 4);
                auto cool = (1 + pyMod(((x + y) + t), 3));
                auto nv = (v - cool);
                heat[(y - 1)][x] = /* unknown expr IfExp */;
            }
        }
        auto frame = cast(ubyte[])[];
        foreach (yy; 0 .. h) {
            auto row_base = (yy * w);
            foreach (xx; 0 .. w) {
                frame[(row_base + xx)] = heat[yy][xx];
            }
        }
        frames ~= bytes(frame);
    }
    save_gif(out_path, w, h, frames, fire_palette());
    auto elapsed = (pyPerfCounter() - start);
    writeln("output:", out_path);
    writeln("frames:", steps);
    writeln("elapsed_sec:", elapsed);
}


void main() {
    run_09_fire_simulation();
}
