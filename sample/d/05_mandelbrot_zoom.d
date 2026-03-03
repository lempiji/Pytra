import py_runtime;
import std.stdio;
import std.math;
import std.conv;
import std.array;
import std.algorithm;

auto render_frame(long width, long height, double center_x, double center_y, double scale, long max_iter) {
    auto frame = cast(ubyte[])[];
    double __hoisted_cast_1 = to!double(max_iter);
    foreach (y; 0 .. height) {
        auto row_base = (y * width);
        auto cy = (center_y + ((y - (height * 0.5)) * scale));
        foreach (x; 0 .. width) {
            auto cx = (center_x + ((x - (width * 0.5)) * scale));
            auto zx = 0.0;
            auto zy = 0.0;
            auto i = 0;
            while ((i < max_iter)) {
                auto zx2 = (zx * zx);
                auto zy2 = (zy * zy);
                if (((zx2 + zy2) > 4.0)) {
                    break_;
                }
                zy = (((2.0 * zx) * zy) + cy);
                zx = ((zx2 - zy2) + cx);
                i += 1;
            }
            frame[(row_base + x)] = to!long((cast(double)((255.0 * i)) / cast(double)(__hoisted_cast_1)));
        }
    }
    return bytes(frame);
}

auto run_05_mandelbrot_zoom() {
    auto width = 320;
    auto height = 240;
    auto frame_count = 48;
    auto max_iter = 110;
    auto center_x = (-0.743643887037151);
    auto center_y = 0.13182590420533;
    auto base_scale = (cast(double)(3.2) / cast(double)(width));
    auto zoom_per_frame = 0.93;
    auto out_path = "sample/out/05_mandelbrot_zoom.gif";
    auto start = pyPerfCounter();
    auto[] frames = [];
    auto scale = base_scale;
    foreach (_; 0 .. frame_count) {
        frames ~= render_frame(width, height, center_x, center_y, scale, max_iter);
        scale *= zoom_per_frame;
    }
    save_gif(out_path, width, height, frames, grayscale_palette());
    auto elapsed = (pyPerfCounter() - start);
    writeln("output:", out_path);
    writeln("frames:", frame_count);
    writeln("elapsed_sec:", elapsed);
}


void main() {
    run_05_mandelbrot_zoom();
}
