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

auto dot(double ax, double ay, double az, double bx, double by, double bz) {
    return (((ax * bx) + (ay * by)) + (az * bz));
}

auto length(double x, double y, double z) {
    return sqrt(cast(double)((((x * x) + (y * y)) + (z * z))));
}

auto normalize(double x, double y, double z) {
    auto l = length(x, y, z);
    if ((l < 1e-09)) {
        return tuple(0.0, 0.0, 0.0);
    }
    return tuple((cast(double)(x) / cast(double)(l)), (cast(double)(y) / cast(double)(l)), (cast(double)(z) / cast(double)(l)));
}

auto reflect(double ix, double iy, double iz, double nx, double ny, double nz) {
    auto d = (dot(ix, iy, iz, nx, ny, nz) * 2.0);
    return tuple((ix - (d * nx)), (iy - (d * ny)), (iz - (d * nz)));
}

auto refract(double ix, double iy, double iz, double nx, double ny, double nz, double eta) {
    auto cosi = (-dot(ix, iy, iz, nx, ny, nz));
    auto sint2 = ((eta * eta) * (1.0 - (cosi * cosi)));
    if ((sint2 > 1.0)) {
        return reflect(ix, iy, iz, nx, ny, nz);
    }
    auto cost = sqrt(cast(double)((1.0 - sint2)));
    auto k = ((eta * cosi) - cost);
    return tuple(((eta * ix) + (k * nx)), ((eta * iy) + (k * ny)), ((eta * iz) + (k * nz)));
}

auto schlick(double cos_theta, double f0) {
    auto m = (1.0 - cos_theta);
    return (f0 + ((1.0 - f0) * ((((m * m) * m) * m) * m)));
}

auto sky_color(double dx, double dy, double dz, double tphase) {
    auto t = (0.5 * (dy + 1.0));
    auto r = (0.06 + (0.2 * t));
    auto g = (0.1 + (0.25 * t));
    auto b = (0.16 + (0.45 * t));
    auto band = (0.5 + (0.5 * sin(cast(double)((((8.0 * dx) + (6.0 * dz)) + tphase)))));
    r += /* unknown expr Unbox */;
    g += /* unknown expr Unbox */;
    b += /* unknown expr Unbox */;
    return tuple(clamp01(r), clamp01(g), clamp01(b));
}

auto sphere_intersect(double ox, double oy, double oz, double dx, double dy, double dz, double cx, double cy, double cz, double radius) {
    auto lx = (ox - cx);
    auto ly = (oy - cy);
    auto lz = (oz - cz);
    auto b = (((lx * dx) + (ly * dy)) + (lz * dz));
    auto c = ((((lx * lx) + (ly * ly)) + (lz * lz)) - (radius * radius));
    auto h = ((b * b) - c);
    if ((h < 0.0)) {
        return (-1.0);
    }
    auto s = sqrt(cast(double)(h));
    auto t0 = ((-b) - s);
    if ((t0 > 0.0001)) {
        return t0;
    }
    auto t1 = ((-b) + s);
    if ((t1 > 0.0001)) {
        return t1;
    }
    return (-1.0);
}

auto palette_332() {
    auto p = cast(ubyte[])[];
    double __hoisted_cast_1 = to!double(7);
    double __hoisted_cast_2 = to!double(3);
    foreach (i; 0 .. 256) {
        auto r = ((i + 5) + 7);
        auto g = ((i + 2) + 7);
        auto b = (i + 3);
        p[((i * 3) + 0)] = to!long((cast(double)((255 * r)) / cast(double)(__hoisted_cast_1)));
        p[((i * 3) + 1)] = to!long((cast(double)((255 * g)) / cast(double)(__hoisted_cast_1)));
        p[((i * 3) + 2)] = to!long((cast(double)((255 * b)) / cast(double)(__hoisted_cast_2)));
    }
    return bytes(p);
}

auto quantize_332(double r, double g, double b) {
    auto rr = to!long((clamp01(r) * 255.0));
    auto gg = to!long((clamp01(g) * 255.0));
    auto bb = to!long((clamp01(b) * 255.0));
    return ((((rr + 5) + 5) + ((gg + 5) + 2)) + (bb + 6));
}

auto render_frame(long width, long height, long frame_id, long frames_n) {
    auto t = (cast(double)(frame_id) / cast(double)(frames_n));
    auto tphase = ((2.0 * PI) * t);
    auto cam_r = 3.0;
    auto cam_x = (cam_r * cos(cast(double)((tphase * 0.9))));
    auto cam_y = (1.1 + (0.25 * sin(cast(double)((tphase * 0.6)))));
    auto cam_z = (cam_r * sin(cast(double)((tphase * 0.9))));
    auto look_x = 0.0;
    auto look_y = 0.35;
    auto look_z = 0.0;
    tuple(fwd_x, fwd_y, fwd_z) = normalize((look_x - cam_x), (look_y - cam_y), (look_z - cam_z));
    tuple(right_x, right_y, right_z) = normalize(fwd_z, 0.0, (-fwd_x));
    tuple(up_x, up_y, up_z) = normalize(((right_y * fwd_z) - (right_z * fwd_y)), ((right_z * fwd_x) - (right_x * fwd_z)), ((right_x * fwd_y) - (right_y * fwd_x)));
    auto s0x = (0.9 * cos(cast(double)((1.3 * tphase))));
    auto s0y = (0.15 + (0.35 * sin(cast(double)((1.7 * tphase)))));
    auto s0z = (0.9 * sin(cast(double)((1.3 * tphase))));
    auto s1x = (1.2 * cos(cast(double)(((1.3 * tphase) + 2.094))));
    auto s1y = (0.1 + (0.4 * sin(cast(double)(((1.1 * tphase) + 0.8)))));
    auto s1z = (1.2 * sin(cast(double)(((1.3 * tphase) + 2.094))));
    auto s2x = (1.0 * cos(cast(double)(((1.3 * tphase) + 4.188))));
    auto s2y = (0.2 + (0.3 * sin(cast(double)(((1.5 * tphase) + 1.9)))));
    auto s2z = (1.0 * sin(cast(double)(((1.3 * tphase) + 4.188))));
    auto lr = 0.35;
    auto lx = (2.4 * cos(cast(double)((tphase * 1.8))));
    auto ly = (1.8 + (0.8 * sin(cast(double)((tphase * 1.2)))));
    auto lz = (2.4 * sin(cast(double)((tphase * 1.8))));
    auto frame = cast(ubyte[])[];
    auto aspect = (cast(double)(width) / cast(double)(height));
    auto fov = 1.25;
    double __hoisted_cast_3 = to!double(height);
    double __hoisted_cast_4 = to!double(width);
    foreach (py; 0 .. height) {
        auto row_base = (py * width);
        auto sy = (1.0 - (cast(double)((2.0 * (py + 0.5))) / cast(double)(__hoisted_cast_3)));
        foreach (px; 0 .. width) {
            auto sx = (((cast(double)((2.0 * (px + 0.5))) / cast(double)(__hoisted_cast_4)) - 1.0) * aspect);
            auto rx = (fwd_x + (fov * ((sx * right_x) + (sy * up_x))));
            auto ry = (fwd_y + (fov * ((sx * right_y) + (sy * up_y))));
            auto rz = (fwd_z + (fov * ((sx * right_z) + (sy * up_z))));
            tuple(dx, dy, dz) = normalize(rx, ry, rz);
            auto best_t = 1000000000.0;
            auto hit_kind = 0;
            auto r = 0.0;
            auto g = 0.0;
            auto b = 0.0;
            if ((dy < (-1e-06))) {
                auto tf = (cast(double)(((-1.2) - cam_y)) / cast(double)(dy));
                if (pyTruthy(((tf > 0.0001) && (tf < best_t)))) {
                    best_t = /* unknown expr Unbox */;
                    hit_kind = 1;
                }
            }
            auto t0 = sphere_intersect(cam_x, cam_y, cam_z, dx, dy, dz, s0x, s0y, s0z, 0.65);
            if (pyTruthy(((t0 > 0.0) && (t0 < best_t)))) {
                best_t = t0;
                hit_kind = 2;
            }
            auto t1 = sphere_intersect(cam_x, cam_y, cam_z, dx, dy, dz, s1x, s1y, s1z, 0.72);
            if (pyTruthy(((t1 > 0.0) && (t1 < best_t)))) {
                best_t = t1;
                hit_kind = 3;
            }
            auto t2 = sphere_intersect(cam_x, cam_y, cam_z, dx, dy, dz, s2x, s2y, s2z, 0.58);
            if (pyTruthy(((t2 > 0.0) && (t2 < best_t)))) {
                best_t = t2;
                hit_kind = 4;
            }
            if ((hit_kind == 0)) {
                tuple(r, g, b) = sky_color(dx, dy, dz, tphase);
            } else
            if ((hit_kind == 1)) {
                auto hx = (cam_x + (best_t * dx));
                auto hz = (cam_z + (best_t * dz));
                auto cx = to!long(to!long(floor(cast(double)((hx * 2.0)))));
                auto cz = to!long(to!long(floor(cast(double)((hz * 2.0)))));
                auto checker = /* unknown expr IfExp */;
                auto base_r = /* unknown expr IfExp */;
                auto base_g = /* unknown expr IfExp */;
                auto base_b = /* unknown expr IfExp */;
                auto lxv = (lx - hx);
                auto lyv = (ly - (-1.2));
                auto lzv = (lz - hz);
                tuple(ldx, ldy, ldz) = normalize(lxv, lyv, lzv);
                auto ndotl = max(ldy, 0.0);
                auto ldist2 = (((lxv * lxv) + (lyv * lyv)) + (lzv * lzv));
                auto glow = (cast(double)(8.0) / cast(double)((1.0 + ldist2)));
                r = /* unknown expr Unbox */;
                g = /* unknown expr Unbox */;
                b = /* unknown expr Unbox */;
            } else {
                cx = 0.0;
                auto cy = 0.0;
                cz = 0.0;
                auto rad = 1.0;
                if ((hit_kind == 2)) {
                    cx = /* unknown expr Unbox */;
                    cy = /* unknown expr Unbox */;
                    cz = /* unknown expr Unbox */;
                    rad = 0.65;
                } else
                if ((hit_kind == 3)) {
                    cx = /* unknown expr Unbox */;
                    cy = /* unknown expr Unbox */;
                    cz = /* unknown expr Unbox */;
                    rad = 0.72;
                } else {
                    cx = /* unknown expr Unbox */;
                    cy = /* unknown expr Unbox */;
                    cz = /* unknown expr Unbox */;
                    rad = 0.58;
                }
                hx = (cam_x + (best_t * dx));
                auto hy = (cam_y + (best_t * dy));
                hz = (cam_z + (best_t * dz));
                tuple(nx, ny, nz) = normalize((cast(double)((hx - cx)) / cast(double)(rad)), (cast(double)((hy - cy)) / cast(double)(rad)), (cast(double)((hz - cz)) / cast(double)(rad)));
                tuple(rdx, rdy, rdz) = reflect(dx, dy, dz, nx, ny, nz);
                tuple(tdx, tdy, tdz) = refract(dx, dy, dz, nx, ny, nz, (cast(double)(1.0) / cast(double)(1.45)));
                tuple(sr, sg, sb) = sky_color(rdx, rdy, rdz, tphase);
                tuple(tr, tg, tb) = sky_color(tdx, tdy, tdz, (tphase + 0.8));
                auto cosi = max((-(((dx * nx) + (dy * ny)) + (dz * nz))), 0.0);
                auto fr = schlick(cosi, 0.04);
                r = /* unknown expr Unbox */;
                g = /* unknown expr Unbox */;
                b = /* unknown expr Unbox */;
                lxv = (lx - hx);
                lyv = (ly - hy);
                lzv = (lz - hz);
                tuple(ldx, ldy, ldz) = normalize(lxv, lyv, lzv);
                ndotl = max((((nx * ldx) + (ny * ldy)) + (nz * ldz)), 0.0);
                tuple(hvx, hvy, hvz) = normalize((ldx - dx), (ldy - dy), (ldz - dz));
                auto ndoth = max((((nx * hvx) + (ny * hvy)) + (nz * hvz)), 0.0);
                auto spec = (ndoth * ndoth);
                spec = (spec * spec);
                spec = (spec * spec);
                spec = (spec * spec);
                glow = (cast(double)(10.0) / cast(double)((((1.0 + (lxv * lxv)) + (lyv * lyv)) + (lzv * lzv))));
                r += (((0.2 * ndotl) + (0.8 * spec)) + (0.45 * glow));
                g += (((0.18 * ndotl) + (0.6 * spec)) + (0.35 * glow));
                b += (((0.26 * ndotl) + (1.0 * spec)) + (0.65 * glow));
                if ((hit_kind == 2)) {
                    r *= 0.95;
                    g *= 1.05;
                    b *= 1.1;
                } else
                if ((hit_kind == 3)) {
                    r *= 1.08;
                    g *= 0.98;
                    b *= 1.04;
                } else {
                    r *= 1.02;
                    g *= 1.1;
                    b *= 0.95;
                }
            }
            r = /* unknown expr Unbox */;
            g = /* unknown expr Unbox */;
            b = /* unknown expr Unbox */;
            frame[(row_base + px)] = quantize_332(r, g, b);
        }
    }
    return bytes(frame);
}

auto run_16_glass_sculpture_chaos() {
    auto width = 320;
    auto height = 240;
    auto frames_n = 72;
    auto out_path = "sample/out/16_glass_sculpture_chaos.gif";
    auto start = pyPerfCounter();
    auto[] frames = [];
    foreach (i; 0 .. frames_n) {
        frames ~= render_frame(width, height, i, frames_n);
    }
    save_gif(out_path, width, height, frames, palette_332());
    auto elapsed = (pyPerfCounter() - start);
    writeln("output:", out_path);
    writeln("frames:", frames_n);
    writeln("elapsed_sec:", elapsed);
}


void main() {
    run_16_glass_sculpture_chaos();
}
