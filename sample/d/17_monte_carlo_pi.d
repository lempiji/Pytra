import py_runtime;
import std.stdio;
import std.math;
import std.conv;
import std.array;
import std.algorithm;

auto run_integer_grid_checksum(long width, long height, long seed) {
    long mod_main = 2147483647;
    long mod_out = 1000000007;
    long acc = pyMod(seed, mod_out);
    foreach (y; 0 .. height) {
        long row_sum = 0;
        foreach (x; 0 .. width) {
            long v = pyMod((((x * 37) + (y * 73)) + seed), mod_main);
            v = pyMod(((v * 48271) + 1), mod_main);
            row_sum += pyMod(v, 256);
        }
        acc = pyMod((acc + (row_sum * (y + 1))), mod_out);
    }
    return acc;
}

auto run_integer_benchmark() {
    long width = 7600;
    long height = 5000;
    double start = pyPerfCounter();
    long checksum = run_integer_grid_checksum(width, height, 123456789);
    double elapsed = (pyPerfCounter() - start);
    writeln("pixels:", (width * height));
    writeln("checksum:", checksum);
    writeln("elapsed_sec:", elapsed);
}


void main() {
    run_integer_benchmark();
}
