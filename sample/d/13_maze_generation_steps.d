import py_runtime;
import std.stdio;
import std.math;
import std.conv;
import std.array;
import std.algorithm;

auto capture(long[][] grid, long w, long h, long scale) {
    auto width = (w * scale);
    auto height = (h * scale);
    auto frame = cast(ubyte[])[];
    foreach (y; 0 .. h) {
        foreach (x; 0 .. w) {
            auto v = /* unknown expr IfExp */;
            foreach (yy; 0 .. scale) {
                auto base = ((((y * scale) + yy) * width) + (x * scale));
                foreach (xx; 0 .. scale) {
                    frame[(base + xx)] = v;
                }
            }
        }
    }
    return bytes(frame);
}

auto run_13_maze_generation_steps() {
    auto cell_w = 89;
    auto cell_h = 67;
    auto scale = 5;
    auto capture_every = 20;
    auto out_path = "sample/out/13_maze_generation_steps.gif";
    auto start = pyPerfCounter();
    long[][] grid = null /* ListComp */;
    Tuple!(long, long)[] stack = [tuple(1, 1)];
    grid[1][1] = 0;
    Tuple!(long, long)[] dirs = [tuple(2, 0), tuple((-2), 0), tuple(0, 2), tuple(0, (-2))];
    auto[] frames = [];
    auto step = 0;
    while (pyTruthy(stack)) {
        tuple(x, y) = stack[(-1)];
        Tuple!(long, long, long, long)[] candidates = [];
        foreach (k; 0 .. 4) {
            tuple(dx, dy) = dirs[k];
            auto nx = (x + dx);
            auto ny = (y + dy);
            if (pyTruthy(((nx >= 1) && (nx < (cell_w - 1)) && (ny >= 1) && (ny < (cell_h - 1)) && (grid[ny][nx] == 1)))) {
                if ((dx == 2)) {
                    candidates ~= tuple(nx, ny, (x + 1), y);
                } else
                if ((dx == (-2))) {
                    candidates ~= tuple(nx, ny, (x - 1), y);
                } else
                if ((dy == 2)) {
                    candidates ~= tuple(nx, ny, x, (y + 1));
                } else {
                    candidates ~= tuple(nx, ny, x, (y - 1));
                }
            }
        }
        if ((cast(long)(candidates.length) == 0)) {
            stack.pop();
        } else {
            auto sel = candidates[pyMod((((x * 17) + (y * 29)) + (cast(long)(stack.length) * 13)), cast(long)(candidates.length))];
            tuple(nx, ny, wx, wy) = sel;
            grid[wy][wx] = 0;
            grid[ny][nx] = 0;
            stack ~= tuple(nx, ny);
        }
        if ((pyMod(step, capture_every) == 0)) {
            frames ~= capture(grid, cell_w, cell_h, scale);
        }
        step += 1;
    }
    frames ~= capture(grid, cell_w, cell_h, scale);
    save_gif(out_path, (cell_w * scale), (cell_h * scale), frames, grayscale_palette());
    auto elapsed = (pyPerfCounter() - start);
    writeln("output:", out_path);
    writeln("frames:", cast(long)(frames.length));
    writeln("elapsed_sec:", elapsed);
}


void main() {
    run_13_maze_generation_steps();
}
