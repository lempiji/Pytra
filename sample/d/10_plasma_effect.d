import py_runtime;
import std.stdio;
import std.math;
import std.conv;
import std.array;
import std.algorithm;

auto run_10_plasma_effect() {
    auto w = 320;
    auto h = 240;
    auto frames_n = 216;
    auto out_path = "sample/out/10_plasma_effect.gif";
    auto start = pyPerfCounter();
    auto[] frames = [];
    foreach (t; 0 .. frames_n) {
        auto frame = cast(ubyte[])[];
        foreach (y; 0 .. h) {
            auto row_base = (y * w);
            foreach (x; 0 .. w) {
                auto dx = (x - 160);
                auto dy = (y - 120);
                auto v = (((math.sin(((x + (t * 2.0)) * 0.045)) + math.sin(((y - (t * 1.2)) * 0.05))) + math.sin((((x + y) + (t * 1.7)) * 0.03))) + math.sin(((sqrt(cast(double)(((dx * dx) + (dy * dy)))) * 0.07) - (t * 0.18))));
                auto c = to!long(((v + 4.0) * (cast(double)(255.0) / cast(double)(8.0))));
                if ((c < 0)) {
                    c = 0;
                }
                if ((c > 255)) {
                    c = 255;
                }
                frame[(row_base + x)] = c;
            }
        }
        frames ~= bytes(frame);
    }
    save_gif(out_path, w, h, frames, grayscale_palette());
    auto elapsed = (pyPerfCounter() - start);
    writeln("output:", out_path);
    writeln("frames:", frames_n);
    writeln("elapsed_sec:", elapsed);
}


void main() {
    run_10_plasma_effect();
}
