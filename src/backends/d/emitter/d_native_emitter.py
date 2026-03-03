"""EAST3 -> D native emitter."""

from __future__ import annotations

from pytra.std.typing import Any


_D_KEYWORDS = {
    "abstract", "alias", "align", "asm", "assert", "auto",
    "body", "bool", "break", "byte",
    "case", "cast", "catch", "char", "class", "const", "continue",
    "dchar", "debug", "default", "delegate", "delete", "deprecated", "do", "double",
    "else", "enum", "export", "extern",
    "false", "final", "finally", "float", "for", "foreach", "foreach_reverse",
    "function",
    "goto",
    "idouble", "if", "ifloat", "immutable", "import", "in", "inout", "int",
    "interface", "invariant", "ireal", "is",
    "lazy", "long",
    "macro", "mixin", "module",
    "new", "nothrow", "null",
    "out", "override",
    "package", "pragma", "private", "protected", "public", "pure",
    "real", "ref", "return",
    "scope", "shared", "short", "static", "string", "struct", "super",
    "switch", "synchronized",
    "template", "this", "throw", "true", "try", "typeid", "typeof",
    "ubyte", "uint", "ulong", "union", "unittest", "ushort",
    "version", "void", "volatile",
    "wchar", "while", "with",
    "__FILE__", "__LINE__", "__gshared", "__traits",
}

def _safe_ident(name: Any, fallback: str = "value") -> str:
    if not isinstance(name, str) or name == "":
        return fallback
    chars: list[str] = []
    i = 0
    while i < len(name):
        ch = name[i]
        if ch.isalnum() or ch == "_":
            chars.append(ch)
        else:
            chars.append("_")
        i += 1
    out = "".join(chars)
    if out == "":
        out = fallback
    if out[0].isdigit():
        out = "v" + out
    if out in _D_KEYWORDS:
        out = out + "_"
    return out

def _d_string(text: str) -> str:
    out = text.replace("\\", "\\\\")
    out = out.replace('"', '\\"')
    out = out.replace("\n", "\\n")
    return '"' + out + '"'

def _binop_symbol(op: str) -> str:
    if op == "Add": return "+"
    if op == "Sub": return "-"
    if op == "Mult": return "*"
    if op == "Div": return "/"
    if op == "FloorDiv": return "/"
    if op == "Mod": return "%"
    return "+"

def _cmp_symbol(op: str) -> str:
    if op == "Eq": return "=="
    if op == "NotEq": return "!="
    if op == "Lt": return "<"
    if op == "LtE": return "<="
    if op == "Gt": return ">"
    if op == "GtE": return ">="
    return "=="

class DNativeEmitter:
    def __init__(self, east_doc: dict[str, Any]) -> None:
        self.east_doc = east_doc
        self.lines: list[str] = []
        self.indent = 0
        self.class_names: set[str] = set()
        self.current_class: str = ""
        self.self_replacement: str = ""
        self.imported_modules: set[str] = set()
        self.declared_vars: set[str] = set()

    def transpile(self) -> str:
        self.lines.append("import py_runtime;")
        self.lines.append("import std.stdio;")
        self.lines.append("import std.math;")
        self.lines.append("import std.conv;")
        self.lines.append("import std.array;")
        self.lines.append("import std.algorithm;")
        self.lines.append("")

        body = self.east_doc.get("body")
        if isinstance(body, list):
            for stmt in body:
                if isinstance(stmt, dict) and stmt.get("kind") == "ClassDef":
                    self.class_names.add(_safe_ident(stmt.get("name")))

            self.declared_vars = set()
            for stmt in body:
                if isinstance(stmt, dict):
                    self._emit_stmt(stmt)

        main_guard = self.east_doc.get("main_guard_body")
        if isinstance(main_guard, list) and len(main_guard) > 0:
            self.lines.append("")
            self.lines.append("void main() {")
            self.indent += 1
            for stmt in main_guard:
                if isinstance(stmt, dict):
                    self._emit_stmt(stmt)
            self.indent -= 1
            self.lines.append("}")

        return "\n".join(self.lines).rstrip() + "\n"

    def _emit_line(self, text: str) -> None:
        self.lines.append("    " * self.indent + text)

    def _map_type(self, py_type: Any) -> str:
        if not isinstance(py_type, str):
            return "auto"
        t = py_type.strip()
        if t in {"int", "int64"}: return "long"
        if t in {"float", "float64"}: return "double"
        if t == "str": return "string"
        if t == "bool": return "bool"
        if t == "None": return "void"
        if t == "bytearray": return "ubyte[]"
        if t.startswith("list["):
            inner = self._map_type(t[5:-1])
            return f"{inner}[]"
        if t.startswith("dict["):
            parts = t[5:-1].split(",", 1)
            if len(parts) == 2:
                k = self._map_type(parts[0])
                v = self._map_type(parts[1])
                return f"{v}[{k}]"
            return "auto"
        if t.startswith("tuple["):
            parts = t[6:-1].split(",")
            mapped = [self._map_type(p.strip()) for p in parts]
            return f"Tuple!({', '.join(mapped)})"
        if t in self.class_names:
            return t
        return "auto"

    def _emit_stmt(self, stmt: dict[str, Any]) -> None:
        kind = stmt.get("kind")
        if kind == "FunctionDef":
            self._emit_function_def(stmt)
        elif kind == "ClassDef":
            self._emit_class_def(stmt)
        elif kind == "Expr":
            self._emit_expr_stmt(stmt)
        elif kind == "Assign":
            self._emit_assign(stmt)
        elif kind == "AnnAssign":
            self._emit_ann_assign(stmt)
        elif kind == "AugAssign":
            self._emit_aug_assign(stmt)
        elif kind == "Return":
            val_node = stmt.get("value")
            val = self._render_expr(val_node) if val_node else ""
            if val:
                self._emit_line("return " + val + ";")
            else:
                self._emit_line("return;")
        elif kind == "If":
            self._emit_if(stmt)
        elif kind == "While":
            self._emit_while(stmt)
        elif kind == "ForCore":
            self._emit_for(stmt)
        elif kind == "Raise":
            self._emit_raise(stmt)
        elif kind == "Pass":
            self._emit_line("// pass")
        elif kind == "Import":
            self._emit_import(stmt)
        elif kind == "ImportFrom":
            self._emit_import_from(stmt)
        else:
            self._emit_line("// unsupported stmt: " + str(kind))

    def _emit_import(self, stmt: dict[str, Any]) -> None:
        pass

    def _emit_import_from(self, stmt: dict[str, Any]) -> None:
        pass

    def _emit_function_def(self, stmt: dict[str, Any]) -> None:
        raw_name = stmt.get("name")
        name = _safe_ident(raw_name, "fn")
        arg_order = stmt.get("arg_order", [])
        arg_types = stmt.get("arg_types", {})
        ret_type = self._map_type(stmt.get("returns"))

        args = []
        old_vars = self.declared_vars
        self.declared_vars = set()

        for a in arg_order:
            safe_a = _safe_ident(a)
            self.declared_vars.add(safe_a)
            if self.current_class and safe_a == "self":
                continue
            else:
                t = self._map_type(arg_types.get(a))
                args.append(f"{t} {safe_a}")

        old_self_replacement = self.self_replacement
        is_init = raw_name == "__init__"
        if is_init:
            name = "this"
            ret_type = "void"
            self.self_replacement = "this"
            self.declared_vars.add("this")

        if self.current_class:
            header = f"{ret_type} {name}({', '.join(args)})"
        else:
            header = f"{ret_type} {name}({', '.join(args)})"
        self._emit_line(header + " {")

        self.indent += 1
        body = stmt.get("body", [])
        if not body:
            self._emit_line("// empty")
        else:
            for s in body:
                if isinstance(s, dict):
                    self._emit_stmt(s)
        self.indent -= 1
        self._emit_line("}")
        self.self_replacement = old_self_replacement
        self.declared_vars = old_vars
        self.lines.append("")

    def _emit_class_def(self, stmt: dict[str, Any]) -> None:
        name = _safe_ident(stmt.get("name"), "Class")
        self.current_class = name

        self._emit_line(f"class {name} {{")
        self.indent += 1
        body = stmt.get("body", [])
        for s in body:
            if isinstance(s, dict) and s.get("kind") == "AnnAssign":
                target = s.get("target")
                if isinstance(target, dict) and target.get("kind") == "Name":
                    field_name = _safe_ident(target.get("id"))
                    field_type = self._map_type(s.get("annotation"))
                    self._emit_line(f"{field_type} {field_name};")

        for s in body:
            if isinstance(s, dict) and s.get("kind") == "FunctionDef":
                self._emit_function_def(s)

        self.indent -= 1
        self._emit_line("}")
        self.lines.append("")

        self.current_class = ""

    def _emit_expr_stmt(self, stmt: dict[str, Any]) -> None:
        expr = self._render_expr(stmt.get("value"))
        self._emit_line(expr + ";")

    def _emit_assign(self, stmt: dict[str, Any]) -> None:
        target_node = stmt.get("target")
        if not isinstance(target_node, dict):
            targets = stmt.get("targets", [])
            if targets:
                target_node = targets[0]

        target = self._render_expr(target_node)
        value = self._render_expr(stmt.get("value"))

        if isinstance(target_node, dict) and target_node.get("kind") == "Name":
            vname = _safe_ident(target_node.get("id"))
            if vname not in self.declared_vars:
                self.declared_vars.add(vname)
                self._emit_line(f"auto {target} = {value};")
                return

        self._emit_line(f"{target} = {value};")

    def _emit_ann_assign(self, stmt: dict[str, Any]) -> None:
        target_node = stmt.get("target")
        target = self._render_expr(target_node)
        t = self._map_type(stmt.get("annotation"))
        value_node = stmt.get("value")

        if isinstance(target_node, dict) and target_node.get("kind") == "Name":
            vname = _safe_ident(target_node.get("id"))
            if vname not in self.declared_vars:
                self.declared_vars.add(vname)
                if value_node:
                    value = self._render_expr(value_node)
                    self._emit_line(f"{t} {target} = {value};")
                else:
                    self._emit_line(f"{t} {target};")
                return

        if value_node:
            value = self._render_expr(value_node)
            self._emit_line(f"{target} = {value};")
        else:
            self._emit_line(f"// {target}: {t}")

    def _emit_aug_assign(self, stmt: dict[str, Any]) -> None:
        target = self._render_expr(stmt.get("target"))
        op = _binop_symbol(stmt.get("op", "Add"))
        value = self._render_expr(stmt.get("value"))
        self._emit_line(f"{target} {op}= {value};")

    def _emit_if(self, stmt: dict[str, Any]) -> None:
        test = self._render_truthy_expr(stmt.get("test"))
        self._emit_line(f"if ({test}) {{")
        self.indent += 1
        for s in stmt.get("body", []):
            if isinstance(s, dict):
                self._emit_stmt(s)
        self.indent -= 1
        orelse = stmt.get("orelse", [])
        if orelse:
            if len(orelse) == 1 and isinstance(orelse[0], dict) and orelse[0].get("kind") == "If":
                self._emit_line("} else")
                self._emit_elif(orelse[0])
            else:
                self._emit_line("} else {")
                self.indent += 1
                for s in orelse:
                    if isinstance(s, dict):
                        self._emit_stmt(s)
                self.indent -= 1
                self._emit_line("}")
        else:
            self._emit_line("}")

    def _emit_elif(self, stmt: dict[str, Any]) -> None:
        test = self._render_truthy_expr(stmt.get("test"))
        self._emit_line(f"if ({test}) {{")
        self.indent += 1
        for s in stmt.get("body", []):
            if isinstance(s, dict):
                self._emit_stmt(s)
        self.indent -= 1
        orelse = stmt.get("orelse", [])
        if orelse:
            if len(orelse) == 1 and isinstance(orelse[0], dict) and orelse[0].get("kind") == "If":
                self._emit_line("} else")
                self._emit_elif(orelse[0])
            else:
                self._emit_line("} else {")
                self.indent += 1
                for s in orelse:
                    if isinstance(s, dict):
                        self._emit_stmt(s)
                self.indent -= 1
                self._emit_line("}")
        else:
            self._emit_line("}")

    def _emit_while(self, stmt: dict[str, Any]) -> None:
        test = self._render_truthy_expr(stmt.get("test"))
        self._emit_line(f"while ({test}) {{")
        self.indent += 1
        for s in stmt.get("body", []):
            if isinstance(s, dict):
                self._emit_stmt(s)
        self.indent -= 1
        self._emit_line("}")

    def _emit_for(self, stmt: dict[str, Any]) -> None:
        target_plan = stmt.get("target_plan")
        target_name = "it"
        if isinstance(target_plan, dict) and target_plan.get("kind") == "NameTarget":
            target_name = _safe_ident(target_plan.get("id"))

        self.declared_vars.add(target_name)

        iter_plan = stmt.get("iter_plan")
        if isinstance(iter_plan, dict) and iter_plan.get("kind") == "StaticRangeForPlan":
            start = self._render_expr(iter_plan.get("start"))
            stop = self._render_expr(iter_plan.get("stop"))
            self._emit_line(f"foreach ({target_name}; {start} .. {stop}) {{")
        else:
            expr = self._render_expr(iter_plan.get("iter_expr") if isinstance(iter_plan, dict) else None)
            self._emit_line(f"foreach ({target_name}; {expr}) {{")

        self.indent += 1
        for s in stmt.get("body", []):
            if isinstance(s, dict):
                self._emit_stmt(s)
        self.indent -= 1
        self._emit_line("}")

    def _emit_raise(self, stmt: dict[str, Any]) -> None:
        exc = self._render_expr(stmt.get("exc"))
        self._emit_line(f"throw new Exception({exc});")

    def _render_truthy_expr(self, expr_node: Any) -> str:
        if not isinstance(expr_node, dict):
            return "false"
        kind = expr_node.get("kind")
        if kind == "Compare":
            return self._render_expr(expr_node)
        if kind == "Constant":
            val = expr_node.get("value")
            if isinstance(val, bool):
                return "true" if val else "false"

        rendered = self._render_expr(expr_node)
        return f"pyTruthy({rendered})"

    def _render_expr(self, expr: Any) -> str:
        if not isinstance(expr, dict):
            return "null"
        kind = expr.get("kind")
        if kind == "Constant":
            val = expr.get("value")
            if isinstance(val, str): return _d_string(val)
            if isinstance(val, bool): return "true" if val else "false"
            if val is None: return "null"
            if isinstance(val, float):
                s = repr(val)
                if "." not in s and "e" not in s and "E" not in s:
                    s = s + ".0"
                return s
            return str(val)
        elif kind == "Name":
            name = expr.get("id")
            if name == "self" and self.self_replacement:
                return self.self_replacement
            return _safe_ident(name)
        elif kind == "UnaryOp":
            op = expr.get("op")
            if op == "Not":
                operand = self._render_truthy_expr(expr.get("operand"))
                return f"(!{operand})"
            operand = self._render_expr(expr.get("operand"))
            if op == "USub": return f"(-{operand})"
            return operand
        elif kind == "BinOp":
            left_node = expr.get("left")
            right_node = expr.get("right")
            left = self._render_expr(left_node)
            right = self._render_expr(right_node)
            op_raw = expr.get("op")

            if op_raw == "Div":
                return f"(cast(double)({left}) / cast(double)({right}))"

            if op_raw == "FloorDiv":
                return f"pyFloorDiv({left}, {right})"

            if op_raw == "Mod":
                return f"pyMod({left}, {right})"

            symbol = _binop_symbol(op_raw)
            if op_raw == "Add":
                resolved = expr.get("resolved_type")
                if isinstance(resolved, str) and resolved == "str":
                    symbol = "~"
            return f"({left} {symbol} {right})"
        elif kind == "BoolOp":
            op = "&&" if expr.get("op") == "And" else "||"
            values = [self._render_truthy_expr(v) for v in expr.get("values", [])]
            return f"({f' {op} '.join(values)})"
        elif kind == "Compare":
            left = self._render_expr(expr.get("left"))
            ops = expr.get("ops", [])
            comps = expr.get("comparators", [])
            if not ops: return left
            op = ops[0]
            right = self._render_expr(comps[0])
            symbol = _cmp_symbol(op)
            return f"({left} {symbol} {right})"
        elif kind == "Call":
            return self._render_call(expr)
        elif kind == "List":
            elts = [self._render_expr(e) for e in expr.get("elements", [])]
            return f"[{', '.join(elts)}]"
        elif kind == "Tuple":
            elements = expr.get("elements", [])
            elts = [self._render_expr(e) for e in elements]
            return f"tuple({', '.join(elts)})"
        elif kind == "Dict":
            entries = expr.get("entries", [])
            if not entries:
                return "null /* empty dict */"
            pairs = []
            for entry in entries:
                k = self._render_expr(entry.get("key"))
                v = self._render_expr(entry.get("value"))
                pairs.append(f"{k}: {v}")
            return f"[{', '.join(pairs)}]"
        elif kind == "ListComp":
            return "null /* ListComp */"
        elif kind == "Subscript":
            value = self._render_expr(expr.get("value"))
            slice_node = expr.get("slice")
            if isinstance(slice_node, dict) and slice_node.get("kind") == "Slice":
                lower_node = slice_node.get("lower")
                upper_node = slice_node.get("upper")
                lower = self._render_expr(lower_node) if lower_node else "0"
                upper = self._render_expr(upper_node) if upper_node else f"cast(long)({value}.length)"
                return f"{value}[{lower} .. {upper}]"
            idx = self._render_expr(slice_node)
            return f"{value}[{idx}]"
        elif kind == "Attribute":
            value_node = expr.get("value")
            value = self._render_expr(value_node)
            attr = _safe_ident(expr.get("attr"))
            if value in ("png", "v_png") and attr == "write_rgb_png": return "writeRgbPng"
            return f"{value}.{attr}"
        return f"/* unknown expr {kind} */"

    def _render_call(self, expr: dict[str, Any]) -> str:
        func = expr.get("func")
        args = [self._render_expr(a) for a in expr.get("args", [])]
        if isinstance(func, dict) and func.get("kind") == "Name":
            name = func.get("id")
            if name == "print":
                if len(args) == 0:
                    return 'writeln("")'
                return f"writeln({', '.join(args)})"
            if name == "len":
                return f"cast(long)({args[0]}.length)"
            if name == "int":
                return f"to!long({args[0]})"
            if name == "float":
                return f"to!double({args[0]})"
            if name == "str":
                return f"to!string({args[0]})"
            if name == "range":
                if len(args) == 1: return f"iota(0, {args[0]})"
                if len(args) == 2: return f"iota({args[0]}, {args[1]})"
            if name == "perf_counter":
                return "pyPerfCounter()"
            if name == "bytearray":
                return "cast(ubyte[])[]"
            if name in self.class_names:
                return f"new {name}({', '.join(args)})"

        if isinstance(func, dict) and func.get("kind") == "Attribute":
            value_node = func.get("value")
            value = self._render_expr(value_node)
            attr = func.get("attr")
            if attr == "append":
                return f"{value} ~= {', '.join(args)}"

        func_expr = self._render_expr(func)
        if func_expr == "math.sqrt": return f"sqrt(cast(double)({args[0]}))"
        if func_expr == "math.fabs": return f"abs(cast(double)({args[0]}))"

        return f"{func_expr}({', '.join(args)})"

def transpile_to_d_native(east_doc: dict[str, Any]) -> str:
    emitter = DNativeEmitter(east_doc)
    return emitter.transpile()
