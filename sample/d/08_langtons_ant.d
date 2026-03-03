import py_runtime;
import std.stdio;
import std.math;
import std.conv;
import std.array;
import std.algorithm;

auto capture(long[][] grid, long w, long h) {
    auto frame = cast(ubyte[])[];
    foreach (y; 0 .. h) {
        auto row_base = (y * w);
        foreach (x; 0 .. w) {
            frame[(row_base + x)] = /* unknown expr IfExp */;
        }
    }
    return bytes(frame);
}

auto run_08_langtons_ant() {
    auto w = 420;
    auto h = 420;
    auto out_path = "sample/out/08_langtons_ant.gif";
    auto start = pyPerfCounter();
    long[][] grid = null /* ListComp */;
    auto x = pyFloorDiv(w, 2);
    auto y = pyFloorDiv(h, 2);
    auto d = 0;
    auto steps_total = 600000;
    auto capture_every = 3000;
    auto[] frames = [];
    foreach (i; 0 .. steps_total) {
        if ((grid[y][x] == 0)) {
            d = pyMod((d + 1), 4);
            grid[y][x] = 1;
        } else {
            d = pyMod((d + 3), 4);
            grid[y][x] = 0;
        }
        if ((d == 0)) {
            y = pyMod(((y - 1) + h), h);
        } else
        if ((d == 1)) {
            x = pyMod((x + 1), w);
        } else
        if ((d == 2)) {
            y = pyMod((y + 1), h);
        } else {
            x = pyMod(((x - 1) + w), w);
        }
        if ((pyMod(i, capture_every) == 0)) {
            frames ~= capture(grid, w, h);
        }
    }
    save_gif(out_path, w, h, frames, grayscale_palette());
    auto elapsed = (pyPerfCounter() - start);
    writeln("output:", out_path);
    writeln("frames:", cast(long)(frames.length));
    writeln("elapsed_sec:", elapsed);
}


void main() {
    run_08_langtons_ant();
}
