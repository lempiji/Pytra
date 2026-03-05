import py_runtime;
import std.stdio;
import std.math;
import std.conv;
import std.array;
import std.algorithm;

auto next_state(long[][] grid, long w, long h) {
    long[][] nxt = [];
    foreach (y; 0 .. h) {
        long[] row = [];
        foreach (x; 0 .. w) {
            auto cnt = 0;
            foreach (dy; (-1) .. 2) {
                foreach (dx; (-1) .. 2) {
                    if (pyTruthy(((dx != 0) || (dy != 0)))) {
                        auto nx = pyMod(((x + dx) + w), w);
                        auto ny = pyMod(((y + dy) + h), h);
                        cnt += grid[ny][nx];
                    }
                }
            }
            auto alive = grid[y][x];
            if (pyTruthy(((alive == 1) && pyTruthy(((cnt == 2) || (cnt == 3)))))) {
                row ~= 1;
            } else
            if (pyTruthy(((alive == 0) && (cnt == 3)))) {
                row ~= 1;
            } else {
                row ~= 0;
            }
        }
        nxt ~= row;
    }
    return nxt;
}

auto render(long[][] grid, long w, long h, long cell) {
    auto width = (w * cell);
    auto height = (h * cell);
    auto frame = cast(ubyte[])[];
    foreach (y; 0 .. h) {
        foreach (x; 0 .. w) {
            auto v = /* unknown expr IfExp */;
            foreach (yy; 0 .. cell) {
                auto base = ((((y * cell) + yy) * width) + (x * cell));
                foreach (xx; 0 .. cell) {
                    frame[(base + xx)] = v;
                }
            }
        }
    }
    return bytes(frame);
}

auto run_07_game_of_life_loop() {
    auto w = 144;
    auto h = 108;
    auto cell = 4;
    auto steps = 105;
    auto out_path = "sample/out/07_game_of_life_loop.gif";
    auto start = pyPerfCounter();
    long[][] grid = null /* ListComp */;
    foreach (y; 0 .. h) {
        foreach (x; 0 .. w) {
            auto noise = pyMod(((((x * 37) + (y * 73)) + pyMod((x * y), 19)) + pyMod((x + y), 11)), 97);
            if ((noise < 3)) {
                grid[y][x] = 1;
            }
        }
    }
    auto glider = [[0, 1, 0], [0, 0, 1], [1, 1, 1]];
    auto r_pentomino = [[0, 1, 1], [1, 1, 0], [0, 1, 0]];
    auto lwss = [[0, 1, 1, 1, 1], [1, 0, 0, 0, 1], [0, 0, 0, 0, 1], [1, 0, 0, 1, 0]];
    foreach (gy; 8 .. (h - 8)) {
        foreach (gx; 8 .. (w - 8)) {
            auto kind = pyMod(((gx * 7) + (gy * 11)), 3);
            if ((kind == 0)) {
                auto ph = cast(long)(glider.length);
                foreach (py; 0 .. ph) {
                    auto pw = cast(long)(glider[py].length);
                    foreach (px; 0 .. pw) {
                        if ((glider[py][px] == 1)) {
                            grid[pyMod((gy + py), h)][pyMod((gx + px), w)] = 1;
                        }
                    }
                }
            } else
            if ((kind == 1)) {
                ph = cast(long)(r_pentomino.length);
                foreach (py; 0 .. ph) {
                    pw = cast(long)(r_pentomino[py].length);
                    foreach (px; 0 .. pw) {
                        if ((r_pentomino[py][px] == 1)) {
                            grid[pyMod((gy + py), h)][pyMod((gx + px), w)] = 1;
                        }
                    }
                }
            } else {
                ph = cast(long)(lwss.length);
                foreach (py; 0 .. ph) {
                    pw = cast(long)(lwss[py].length);
                    foreach (px; 0 .. pw) {
                        if ((lwss[py][px] == 1)) {
                            grid[pyMod((gy + py), h)][pyMod((gx + px), w)] = 1;
                        }
                    }
                }
            }
        }
    }
    auto[] frames = [];
    foreach (_; 0 .. steps) {
        frames ~= render(grid, w, h, cell);
        grid = next_state(grid, w, h);
    }
    save_gif(out_path, (w * cell), (h * cell), frames, grayscale_palette());
    auto elapsed = (pyPerfCounter() - start);
    writeln("output:", out_path);
    writeln("frames:", steps);
    writeln("elapsed_sec:", elapsed);
}


void main() {
    run_07_game_of_life_loop();
}
