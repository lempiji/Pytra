import py_runtime;
import std.stdio;
import std.math;
import std.conv;
import std.array;
import std.algorithm;

class Token {
    string kind;
    string text;
    long pos;
    long number_value;
}

class ExprNode {
    string kind;
    long value;
    string name;
    string op;
    long left;
    long right;
    long kind_tag;
    long op_tag;
}

class StmtNode {
    string kind;
    string name;
    long expr_index;
    long kind_tag;
}

auto tokenize(string[] lines) {
    long[string] single_char_token_tags = ["+": 1, "-": 2, "*": 3, "/": 4, "(": 5, ")": 6, "=": 7];
    string[] single_char_token_kinds = ["PLUS", "MINUS", "STAR", "SLASH", "LPAREN", "RPAREN", "EQUAL"];
    Token[] tokens = [];
    foreach (it; enumerate(lines)) {
        long i = 0;
        long n = cast(long)(source.length);
        while ((i < n)) {
            string ch = source[i];
            if ((ch == " ")) {
                i += 1;
                continue_;
            }
            long single_tag = /* unknown expr Unbox */;
            if ((single_tag > 0)) {
                tokens ~= new Token(single_char_token_kinds[(single_tag - 1)], ch, i, 0);
                i += 1;
                continue_;
            }
            if (pyTruthy(ch.isdigit())) {
                long start = i;
                while (pyTruthy(((i < n) && pyTruthy(source[i].isdigit())))) {
                    i += 1;
                }
                string text = source[start .. i];
                tokens ~= new Token("NUMBER", text, start, to!long(text));
                continue_;
            }
            if (pyTruthy((pyTruthy(ch.isalpha()) || (ch == "_")))) {
                start = i;
                while (pyTruthy(((i < n) && pyTruthy((pyTruthy((pyTruthy(source[i].isalpha()) || (source[i] == "_"))) || pyTruthy(source[i].isdigit())))))) {
                    i += 1;
                }
                text = source[start .. i];
                if ((text == "let")) {
                    tokens ~= new Token("LET", text, start, 0);
                } else
                if ((text == "print")) {
                    tokens ~= new Token("PRINT", text, start, 0);
                } else {
                    tokens ~= new Token("IDENT", text, start, 0);
                }
                continue_;
            }
            throw new Exception(RuntimeError(((((("tokenize error at line=" ~ to!string(line_index)) ~ " pos=") ~ to!string(i)) ~ " ch=") ~ ch)));
        }
        tokens ~= new Token("NEWLINE", "", n, 0);
    }
    tokens ~= new Token("EOF", "", cast(long)(lines.length), 0);
    return tokens;
}

class Parser {
    auto new_expr_nodes() {
        return [];
    }

    void this(Token[] tokens) {
        this.tokens = tokens;
        this.pos = 0;
        this.expr_nodes = this.new_expr_nodes();
    }

    auto current_token() {
        return self.tokens[self.pos];
    }

    auto previous_token() {
        return self.tokens[(self.pos - 1)];
    }

    auto peek_kind() {
        return self.current_token().kind;
    }

    auto match(string kind) {
        if ((self.peek_kind() == kind)) {
            self.pos += 1;
            return true;
        }
        return false;
    }

    auto expect(string kind) {
        Token token = self.current_token();
        if ((token.kind != kind)) {
            throw new Exception(RuntimeError(((((("parse error at pos=" ~ /* unknown expr ObjStr */) ~ ", expected=") ~ kind) ~ ", got=") + token.kind)));
        }
        self.pos += 1;
        return token;
    }

    auto skip_newlines() {
        while (pyTruthy(self.match("NEWLINE"))) {
            // pass
        }
    }

    auto add_expr(ExprNode node) {
        self.expr_nodes ~= node;
        return (cast(long)(self.expr_nodes.length) - 1);
    }

    auto parse_program() {
        StmtNode[] stmts = [];
        self.skip_newlines();
        while ((self.peek_kind() != "EOF")) {
            StmtNode stmt = self.parse_stmt();
            stmts ~= stmt;
            self.skip_newlines();
        }
        return stmts;
    }

    auto parse_stmt() {
        if (pyTruthy(self.match("LET"))) {
            string let_name = /* unknown expr Unbox */;
            self.expect("EQUAL");
            long let_expr_index = self.parse_expr();
            return new StmtNode("let", let_name, let_expr_index, 1);
        }
        if (pyTruthy(self.match("PRINT"))) {
            long print_expr_index = self.parse_expr();
            return new StmtNode("print", "", print_expr_index, 3);
        }
        string assign_name = /* unknown expr Unbox */;
        self.expect("EQUAL");
        long assign_expr_index = self.parse_expr();
        return new StmtNode("assign", assign_name, assign_expr_index, 2);
    }

    auto parse_expr() {
        return self.parse_add();
    }

    auto parse_add() {
        long left = self.parse_mul();
        while (true) {
            if (pyTruthy(self.match("PLUS"))) {
                long right = self.parse_mul();
                left = self.add_expr(new ExprNode("bin", 0, "", "+", left, right, 3, 1));
                continue_;
            }
            if (pyTruthy(self.match("MINUS"))) {
                right = self.parse_mul();
                left = self.add_expr(new ExprNode("bin", 0, "", "-", left, right, 3, 2));
                continue_;
            }
            break_;
        }
        return left;
    }

    auto parse_mul() {
        long left = self.parse_unary();
        while (true) {
            if (pyTruthy(self.match("STAR"))) {
                long right = self.parse_unary();
                left = self.add_expr(new ExprNode("bin", 0, "", "*", left, right, 3, 3));
                continue_;
            }
            if (pyTruthy(self.match("SLASH"))) {
                right = self.parse_unary();
                left = self.add_expr(new ExprNode("bin", 0, "", "/", left, right, 3, 4));
                continue_;
            }
            break_;
        }
        return left;
    }

    auto parse_unary() {
        if (pyTruthy(self.match("MINUS"))) {
            long child = self.parse_unary();
            return self.add_expr(new ExprNode("neg", 0, "", "", child, (-1), 4, 0));
        }
        return self.parse_primary();
    }

    auto parse_primary() {
        if (pyTruthy(self.match("NUMBER"))) {
            Token token_num = self.previous_token();
            return self.add_expr(new ExprNode("lit", token_num.number_value, "", "", (-1), (-1), 1, 0));
        }
        if (pyTruthy(self.match("IDENT"))) {
            Token token_ident = self.previous_token();
            return self.add_expr(new ExprNode("var", 0, token_ident.text, "", (-1), (-1), 2, 0));
        }
        if (pyTruthy(self.match("LPAREN"))) {
            long expr_index = self.parse_expr();
            self.expect("RPAREN");
            return expr_index;
        }
        auto t = self.current_token();
        throw new Exception(RuntimeError(((("primary parse error at pos=" ~ /* unknown expr ObjStr */) ~ " got=") + t.kind)));
    }

}

auto eval_expr(long expr_index, ExprNode[] expr_nodes, long[string] env) {
    ExprNode node = expr_nodes[expr_index];
    if ((node.kind_tag == 1)) {
        return node.value;
    }
    if ((node.kind_tag == 2)) {
        if (pyTruthy((!(node.name == env)))) {
            throw new Exception(RuntimeError(("undefined variable: " + node.name)));
        }
        return env[node.name];
    }
    if ((node.kind_tag == 4)) {
        return (-eval_expr(node.left, expr_nodes, env));
    }
    if ((node.kind_tag == 3)) {
        long lhs = eval_expr(node.left, expr_nodes, env);
        long rhs = eval_expr(node.right, expr_nodes, env);
        if ((node.op_tag == 1)) {
            return (lhs + rhs);
        }
        if ((node.op_tag == 2)) {
            return (lhs - rhs);
        }
        if ((node.op_tag == 3)) {
            return (lhs * rhs);
        }
        if ((node.op_tag == 4)) {
            if ((rhs == 0)) {
                throw new Exception(RuntimeError("division by zero"));
            }
            return pyFloorDiv(lhs, rhs);
        }
        throw new Exception(RuntimeError(("unknown operator: " + node.op)));
    }
    throw new Exception(RuntimeError(("unknown node kind: " + node.kind)));
}

auto execute(StmtNode[] stmts, ExprNode[] expr_nodes, bool trace) {
    long[string] env = null /* empty dict */;
    long checksum = 0;
    long printed = 0;
    foreach (stmt; stmts) {
        if ((stmt.kind_tag == 1)) {
            env[stmt.name] = eval_expr(stmt.expr_index, expr_nodes, env);
            continue_;
        }
        if ((stmt.kind_tag == 2)) {
            if (pyTruthy((!(stmt.name == env)))) {
                throw new Exception(RuntimeError(("assign to undefined variable: " + stmt.name)));
            }
            env[stmt.name] = eval_expr(stmt.expr_index, expr_nodes, env);
            continue_;
        }
        long value = eval_expr(stmt.expr_index, expr_nodes, env);
        if (pyTruthy(trace)) {
            writeln(value);
        }
        long norm = pyMod(value, 1000000007);
        if ((norm < 0)) {
            norm += 1000000007;
        }
        checksum = pyMod(((checksum * 131) + norm), 1000000007);
        printed += 1;
    }
    if (pyTruthy(trace)) {
        writeln("printed:", printed);
    }
    return checksum;
}

auto build_benchmark_source(long var_count, long loops) {
    string[] lines = [];
    foreach (i; 0 .. var_count) {
        lines ~= ((("let v" ~ to!string(i)) ~ " = ") ~ to!string((i + 1)));
    }
    foreach (i; 0 .. loops) {
        long x = pyMod(i, var_count);
        long y = pyMod((i + 3), var_count);
        long c1 = (pyMod(i, 7) + 1);
        long c2 = (pyMod(i, 11) + 2);
        lines ~= ((((((((("v" ~ to!string(x)) ~ " = (v") ~ to!string(x)) ~ " * ") ~ to!string(c1)) ~ " + v") ~ to!string(y)) ~ " + 10000) / ") ~ to!string(c2));
        if ((pyMod(i, 97) == 0)) {
            lines ~= ("print v" ~ to!string(x));
        }
    }
    lines ~= "print (v0 + v1 + v2 + v3)";
    return lines;
}

auto run_demo() {
    string[] demo_lines = [];
    demo_lines ~= "let a = 10";
    demo_lines ~= "let b = 3";
    demo_lines ~= "a = (a + b) * 2";
    demo_lines ~= "print a";
    demo_lines ~= "print a / b";
    Token[] tokens = tokenize(demo_lines);
    Parser parser = new Parser(tokens);
    StmtNode[] stmts = parser.parse_program();
    long checksum = execute(stmts, parser.expr_nodes, true);
    writeln("demo_checksum:", checksum);
}

auto run_benchmark() {
    string[] source_lines = build_benchmark_source(32, 120000);
    double start = pyPerfCounter();
    Token[] tokens = tokenize(source_lines);
    Parser parser = new Parser(tokens);
    StmtNode[] stmts = parser.parse_program();
    long checksum = execute(stmts, parser.expr_nodes, false);
    double elapsed = (pyPerfCounter() - start);
    writeln("token_count:", cast(long)(tokens.length));
    writeln("expr_count:", /* unknown expr ObjLen */);
    writeln("stmt_count:", cast(long)(stmts.length));
    writeln("checksum:", checksum);
    writeln("elapsed_sec:", elapsed);
}

auto __pytra_main() {
    run_demo();
    run_benchmark();
}


void main() {
    main();
}
