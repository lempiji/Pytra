"""D emitter helpers (native only)."""

from __future__ import annotations

from pytra.std.typing import Any

from backends.js.emitter.js_emitter import load_js_profile

from .d_native_emitter import transpile_to_d_native


def load_d_profile() -> dict[str, Any]:
    """D backend 用 profile を返す。"""
    return load_js_profile()


def transpile_to_d(east_doc: dict[str, Any], js_entry_path: str = "program.js") -> str:
    """互換 API: native emitter へ委譲する。"""
    _ = js_entry_path
    return transpile_to_d_native(east_doc)


__all__ = ["load_d_profile", "transpile_to_d", "transpile_to_d_native"]
