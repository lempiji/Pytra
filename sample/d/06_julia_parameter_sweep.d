import py_runtime;
import std.stdio;
import std.math;
import std.conv;
import std.array;
import std.algorithm;

auto julia_palette() {
    auto palette = cast(ubyte[])[];
    palette[0] = 0;
    palette[1] = 0;
    palette[2] = 0;
    foreach (i; 1 .. 256) {
        auto t = (cast(double)((i - 1)) / cast(double)(254.0));
        auto r = to!long((255.0 * ((((9.0 * (1.0 - t)) * t) * t) * t)));
        auto g = to!long((255.0 * ((((15.0 * (1.0 - t)) * (1.0 - t)) * t) * t)));
        auto b = to!long((255.0 * ((((8.5 * (1.0 - t)) * (1.0 - t)) * (1.0 - t)) * t)));
        palette[((i * 3) + 0)] = r;
        palette[((i * 3) + 1)] = g;
        palette[((i * 3) + 2)] = b;
    }
    return bytes(palette);
}

auto render_frame(long width, long height, double cr, double ci, long max_iter, long phase) {
    auto frame = cast(ubyte[])[];
    double __hoisted_cast_1 = to!double((height - 1));
    double __hoisted_cast_2 = to!double((width - 1));
    foreach (y; 0 .. height) {
        auto row_base = (y * width);
        auto zy0 = ((-1.2) + (2.4 * (cast(double)(y) / cast(double)(__hoisted_cast_1))));
        foreach (x; 0 .. width) {
            auto zx = ((-1.8) + (3.6 * (cast(double)(x) / cast(double)(__hoisted_cast_2))));
            auto zy = zy0;
            auto i = 0;
            while ((i < max_iter)) {
                auto zx2 = (zx * zx);
                auto zy2 = (zy * zy);
                if (((zx2 + zy2) > 4.0)) {
                    break_;
                }
                zy = (((2.0 * zx) * zy) + ci);
                zx = ((zx2 - zy2) + cr);
                i += 1;
            }
            if ((i >= max_iter)) {
                frame[(row_base + x)] = 0;
            } else {
                auto color_index = (1 + pyMod((pyFloorDiv((i * 224), max_iter) + phase), 255));
                frame[(row_base + x)] = color_index;
            }
        }
    }
    return bytes(frame);
}

auto run_06_julia_parameter_sweep() {
    auto width = 320;
    auto height = 240;
    auto frames_n = 72;
    auto max_iter = 180;
    auto out_path = "sample/out/06_julia_parameter_sweep.gif";
    auto start = pyPerfCounter();
    auto[] frames = [];
    auto center_cr = (-0.745);
    auto center_ci = 0.186;
    auto radius_cr = 0.12;
    auto radius_ci = 0.1;
    auto start_offset = 20;
    auto phase_offset = 180;
    double __hoisted_cast_3 = to!double(frames_n);
    foreach (i; 0 .. frames_n) {
        auto t = (cast(double)(pyMod((i + start_offset), frames_n)) / cast(double)(__hoisted_cast_3));
        auto angle = ((2.0 * math.pi) * t);
        auto cr = (center_cr + (radius_cr * math.cos(angle)));
        auto ci = (center_ci + (radius_ci * math.sin(angle)));
        auto phase = pyMod((phase_offset + (i * 5)), 255);
        frames ~= render_frame(width, height, cr, ci, max_iter, phase);
    }
    save_gif(out_path, width, height, frames, julia_palette());
    auto elapsed = (pyPerfCounter() - start);
    writeln("output:", out_path);
    writeln("frames:", frames_n);
    writeln("elapsed_sec:", elapsed);
}


void main() {
    run_06_julia_parameter_sweep();
}
