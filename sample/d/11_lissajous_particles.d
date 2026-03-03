import py_runtime;
import std.stdio;
import std.math;
import std.conv;
import std.array;
import std.algorithm;

auto color_palette() {
    auto p = cast(ubyte[])[];
    foreach (i; 0 .. 256) {
        auto r = i;
        auto g = pyMod((i * 3), 256);
        auto b = (255 - i);
        p ~= r;
        p ~= g;
        p ~= b;
    }
    return bytes(p);
}

auto run_11_lissajous_particles() {
    auto w = 320;
    auto h = 240;
    auto frames_n = 360;
    auto particles = 48;
    auto out_path = "sample/out/11_lissajous_particles.gif";
    auto start = pyPerfCounter();
    auto[] frames = [];
    foreach (t; 0 .. frames_n) {
        auto frame = cast(ubyte[])[];
        double __hoisted_cast_1 = to!double(t);
        foreach (p; 0 .. particles) {
            auto phase = (p * 0.261799);
            auto x = to!long(((w * 0.5) + ((w * 0.38) * sin(cast(double)(((0.11 * __hoisted_cast_1) + (phase * 2.0)))))));
            auto y = to!long(((h * 0.5) + ((h * 0.38) * sin(cast(double)(((0.17 * __hoisted_cast_1) + (phase * 3.0)))))));
            auto color = (30 + pyMod((p * 9), 220));
            foreach (dy; (-2) .. 3) {
                foreach (dx; (-2) .. 3) {
                    auto xx = (x + dx);
                    auto yy = (y + dy);
                    if (pyTruthy(((xx >= 0) && (xx < w) && (yy >= 0) && (yy < h)))) {
                        auto d2 = ((dx * dx) + (dy * dy));
                        if ((d2 <= 4)) {
                            auto idx = ((yy * w) + xx);
                            auto v = (color - (d2 * 20));
                            v = /* unknown expr Unbox */;
                            if ((v > frame[idx])) {
                                frame[idx] = /* unknown expr Unbox */;
                            }
                        }
                    }
                }
            }
        }
        frames ~= bytes(frame);
    }
    save_gif(out_path, w, h, frames, color_palette());
    auto elapsed = (pyPerfCounter() - start);
    writeln("output:", out_path);
    writeln("frames:", frames_n);
    writeln("elapsed_sec:", elapsed);
}


void main() {
    run_11_lissajous_particles();
}
