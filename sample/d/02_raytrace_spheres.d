import py_runtime;
import std.stdio;
import std.math;
import std.conv;
import std.array;
import std.algorithm;

auto clamp01(double v) {
    if ((v < 0.0)) {
        return 0.0;
    }
    if ((v > 1.0)) {
        return 1.0;
    }
    return v;
}

auto hit_sphere(double ox, double oy, double oz, double dx, double dy, double dz, double cx, double cy, double cz, double r) {
    double lx = (ox - cx);
    double ly = (oy - cy);
    double lz = (oz - cz);
    double a = (((dx * dx) + (dy * dy)) + (dz * dz));
    double b = (2.0 * (((lx * dx) + (ly * dy)) + (lz * dz)));
    double c = ((((lx * lx) + (ly * ly)) + (lz * lz)) - (r * r));
    double d = ((b * b) - ((4.0 * a) * c));
    if ((d < 0.0)) {
        return (-1.0);
    }
    double sd = /* unknown expr Unbox */;
    double t0 = (cast(double)(((-b) - sd)) / cast(double)((2.0 * a)));
    double t1 = (cast(double)(((-b) + sd)) / cast(double)((2.0 * a)));
    if ((t0 > 0.001)) {
        return t0;
    }
    if ((t1 > 0.001)) {
        return t1;
    }
    return (-1.0);
}

auto render(long width, long height, long aa) {
    ubyte[] pixels = cast(ubyte[])[];
    double ox = 0.0;
    double oy = 0.0;
    double oz = (-3.0);
    double lx = (-0.4);
    double ly = 0.8;
    double lz = (-0.45);
    double __hoisted_cast_1 = to!double(aa);
    double __hoisted_cast_2 = to!double((height - 1));
    double __hoisted_cast_3 = to!double((width - 1));
    double __hoisted_cast_4 = to!double(height);
    foreach (y; 0 .. height) {
        foreach (x; 0 .. width) {
            long ar = 0;
            long ag = 0;
            long ab = 0;
            foreach (ay; 0 .. aa) {
                foreach (ax; 0 .. aa) {
                    auto fy = (cast(double)((y + (cast(double)((ay + 0.5)) / cast(double)(__hoisted_cast_1)))) / cast(double)(__hoisted_cast_2));
                    auto fx = (cast(double)((x + (cast(double)((ax + 0.5)) / cast(double)(__hoisted_cast_1)))) / cast(double)(__hoisted_cast_3));
                    double sy = (1.0 - (2.0 * fy));
                    double sx = (((2.0 * fx) - 1.0) * (cast(double)(width) / cast(double)(__hoisted_cast_4)));
                    double dx = sx;
                    double dy = sy;
                    double dz = 1.0;
                    double inv_len = /* unknown expr Unbox */;
                    dx *= inv_len;
                    dy *= inv_len;
                    dz *= inv_len;
                    double t_min = 1e+30;
                    long hit_id = (-1);
                    double t = hit_sphere(ox, oy, oz, dx, dy, dz, (-0.8), (-0.2), 2.2, 0.8);
                    if (pyTruthy(((t > 0.0) && (t < t_min)))) {
                        t_min = t;
                        hit_id = 0;
                    }
                    t = hit_sphere(ox, oy, oz, dx, dy, dz, 0.9, 0.1, 2.9, 0.95);
                    if (pyTruthy(((t > 0.0) && (t < t_min)))) {
                        t_min = t;
                        hit_id = 1;
                    }
                    t = hit_sphere(ox, oy, oz, dx, dy, dz, 0.0, (-1001.0), 3.0, 1000.0);
                    if (pyTruthy(((t > 0.0) && (t < t_min)))) {
                        t_min = t;
                        hit_id = 2;
                    }
                    long r = 0;
                    long g = 0;
                    long b = 0;
                    if ((hit_id >= 0)) {
                        double px = (ox + (dx * t_min));
                        double py = (oy + (dy * t_min));
                        double pz = (oz + (dz * t_min));
                        double nx = 0.0;
                        double ny = 0.0;
                        double nz = 0.0;
                        if ((hit_id == 0)) {
                            nx = (cast(double)((px + 0.8)) / cast(double)(0.8));
                            ny = (cast(double)((py + 0.2)) / cast(double)(0.8));
                            nz = (cast(double)((pz - 2.2)) / cast(double)(0.8));
                        } else
                        if ((hit_id == 1)) {
                            nx = (cast(double)((px - 0.9)) / cast(double)(0.95));
                            ny = (cast(double)((py - 0.1)) / cast(double)(0.95));
                            nz = (cast(double)((pz - 2.9)) / cast(double)(0.95));
                        } else {
                            nx = 0.0;
                            ny = 1.0;
                            nz = 0.0;
                        }
                        double diff = (((nx * (-lx)) + (ny * (-ly))) + (nz * (-lz)));
                        diff = clamp01(diff);
                        double base_r = 0.0;
                        double base_g = 0.0;
                        double base_b = 0.0;
                        if ((hit_id == 0)) {
                            base_r = 0.95;
                            base_g = 0.35;
                            base_b = 0.25;
                        } else
                        if ((hit_id == 1)) {
                            base_r = 0.25;
                            base_g = 0.55;
                            base_b = 0.95;
                        } else {
                            long checker = (to!long(((px + 50.0) * 0.8)) + to!long(((pz + 50.0) * 0.8)));
                            if ((pyMod(checker, 2) == 0)) {
                                base_r = 0.85;
                                base_g = 0.85;
                                base_b = 0.85;
                            } else {
                                base_r = 0.2;
                                base_g = 0.2;
                                base_b = 0.2;
                            }
                        }
                        double shade = (0.12 + (0.88 * diff));
                        r = to!long((255.0 * clamp01((base_r * shade))));
                        g = to!long((255.0 * clamp01((base_g * shade))));
                        b = to!long((255.0 * clamp01((base_b * shade))));
                    } else {
                        double tsky = (0.5 * (dy + 1.0));
                        r = to!long((255.0 * (0.65 + (0.2 * tsky))));
                        g = to!long((255.0 * (0.75 + (0.18 * tsky))));
                        b = to!long((255.0 * (0.9 + (0.08 * tsky))));
                    }
                    ar += r;
                    ag += g;
                    ab += b;
                }
            }
            auto samples = (aa * aa);
            pixels ~= pyFloorDiv(ar, samples);
            pixels ~= pyFloorDiv(ag, samples);
            pixels ~= pyFloorDiv(ab, samples);
        }
    }
    return pixels;
}

auto run_raytrace() {
    long width = 1600;
    long height = 900;
    long aa = 2;
    string out_path = "sample/out/02_raytrace_spheres.png";
    double start = pyPerfCounter();
    ubyte[] pixels = render(width, height, aa);
    writeRgbPng(out_path, width, height, pixels);
    double elapsed = (pyPerfCounter() - start);
    writeln("output:", out_path);
    writeln("size:", width, "x", height);
    writeln("elapsed_sec:", elapsed);
}


void main() {
    run_raytrace();
}
