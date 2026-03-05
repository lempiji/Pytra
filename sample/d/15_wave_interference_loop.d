import py_runtime;
import std.stdio;
import std.math;
import std.conv;
import std.array;
import std.algorithm;

auto run_15_wave_interference_loop() {
    auto w = 320;
    auto h = 240;
    auto frames_n = 96;
    auto out_path = "sample/out/15_wave_interference_loop.gif";
    auto start = pyPerfCounter();
    auto[] frames = [];
    foreach (t; 0 .. frames_n) {
        auto frame = cast(ubyte[])[];
        auto phase = (t * 0.12);
        foreach (y; 0 .. h) {
            auto row_base = (y * w);
            foreach (x; 0 .. w) {
                auto dx = (x - 160);
                auto dy = (y - 120);
                auto v = (((sin(cast(double)(((x + (t * 1.5)) * 0.045))) + sin(cast(double)(((y - (t * 1.2)) * 0.04)))) + sin(cast(double)((((x + y) * 0.02) + phase)))) + sin(cast(double)(((sqrt(cast(double)(((dx * dx) + (dy * dy)))) * 0.08) - (phase * 1.3)))));
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
    run_15_wave_interference_loop();
}
