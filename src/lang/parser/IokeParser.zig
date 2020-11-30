const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const builtin = @import("builtin");
const Utf8View = std.unicode.Utf8View;
const StringIterator = std.unicode.Utf8Iterator;
const Level = @import("./Level.zig").Level;
const ChainContext = @import("./ChainContext.zig").ChainContext;
const OperatorsNS = @import("./Operators.zig");
// const OpEntry = OperatorsNS.OpEntry;
// const OpArity = OperatorsNS.OpArity;
const OpUnion = OperatorsNS.OpUnion;
const Operators = OperatorsNS.Operators;
const IokeObject = @import("../IokeObject.zig").IokeObject;
const Message = @import("../Message.zig").Message;
const Runtime = @import("../Runtime.zig").Runtime;

pub const IokeParser = struct {
    allocator: *Allocator,
    iterator: StringIterator,
    context: *IokeObject,
    currentCharacter: u32 = 0,
    lineNumber: u32 = 1,
    message: *IokeObject,
    runtime: *Runtime,
    saved: i64 = -2,
    saved2: i64 = -2,
    skipLF: bool = false,
    top: ?*ChainContext = null,
    operatorTable: ?AutoHashMap([]const u8, OpUnion) = null,
    trinaryOperatorTable: ?AutoHashMap([]const u8, OpUnion) = null,
    invertedOperatorTable: ?AutoHashMap([]const u8, OpUnion) = null,
    // TODO: use HashSet when implemented
    // https://github.com/ziglang/zig/issues/6919
    unaryOperators: ?AutoHashMap([]const u8, []const u8) = null,
    onlyUnaryOperators: ?AutoHashMap([]const u8, []const u8) = null,

    const Self = @This();

    pub fn deinit(self: *Self) void {
        if (self.operatorTable != null) {
            self.operatorTable.?.deinit();
            self.operatorTable = null;
        }
        if (self.trinaryOperatorTable != null) {
            self.trinaryOperatorTable.?.deinit();
            self.trinaryOperatorTable = null;
        }
        if (self.invertedOperatorTable != null) {
            self.invertedOperatorTable.?.deinit();
            self.invertedOperatorTable = null;
        }
        if (self.unaryOperators != null) {
            self.unaryOperators.?.deinit();
            self.unaryOperators = null;
        }
        if (self.onlyUnaryOperators != null) {
            self.onlyUnaryOperators.?.deinit();
            self.onlyUnaryOperators = null;
        }
    }

    pub fn init(self: *Self) void {

        self.operatorTable = AutoHashMap([]const u8, OpUnion).init(self.allocator);
        self.trinaryOperatorTable = AutoHashMap([]const u8, OpUnion).init(self.allocator);
        self.invertedOperatorTable = AutoHashMap([]const u8, OpUnion).init(self.allocator);
        self.unaryOperators = AutoHashMap([]const u8, []const u8).init(self.allocator);
        self.onlyUnaryOperators = AutoHashMap([]const u8, []const u8).init(self.allocator);
        // self.operatorTable.?.ensureCapacity(1) catch unreachable;
        var operators = Operators{};
        operators.createOrGetOpTables(self);
    }


    fn read(self: *Self) i64 {
        if (self.saved > -2) {
            var tmp = self.saved;
            self.saved = self.saved2;
            self.saved2 = -2;

            if (self.skipLF) {
                self.skipLF = false;
                if (tmp == '\n') {
                    return tmp;
                }
            }

            self.currentCharacter += 1;
            _ = switch(tmp) {
                '\r' => {
                    self.skipLF = true;
                },
                '\n' => {
                    self.lineNumber += 1;
                    self.currentCharacter = 0;
                },
                else => {}
            };

            return tmp;
        }

        var tmp2_ = self.iterator.nextCodepoint();

        if (tmp2_ == null) {
            return -1;
        }

        var tmp2 = @as(i64, tmp2_.?);

        if (self.skipLF) {
            self.skipLF = false;
            if (tmp2 == '\n') {
                return tmp2;
            }
        }

        self.currentCharacter += 1;

        _ = switch(tmp2) {
            '\r' => self.skipLF = true,
            '\n' => {
                self.lineNumber += 1;
                self.currentCharacter = 0;
            },
            else => null
        };

        return tmp2;
    }

    // From Vexu/bog's tokenizer
    // https://github.com/Vexu/bog/blob/master/src/tokenizer.zig
    fn isWhiteSpace(self: *Self, c: i64) bool {
        return switch (c) {
            ' ', '\t', '\r',
            // NO-BREAK SPACE
            0x00A0,
            // OGHAM SPACE MARK
            0x1680,
            // MONGOLIAN VOWEL SEPARATOR
            0x180E,
            // EN QUAD
            0x2000,
            // EM QUAD
            0x2001,
            // EN SPACE
            0x2002,
            // EM SPACE
            0x2003,
            // THREE-PER-EM SPACE
            0x2004,
            // FOUR-PER-EM SPACE
            0x2005,
            // SIX-PER-EM SPACE
            0x2006,
            // FIGURE SPACE
            0x2007,
            // PUNCTUATION SPACE
            0x2008,
            // THIN SPACE
            0x2009,
            // HAIR SPACE
            0x200A,
            // ZERO WIDTH SPACE
            0x200B,
            // NARROW NO-BREAK SPACE
            0x202F,
            // MEDIUM MATHEMATICAL SPACE
            0x205F,
            // IDEOGRAPHIC SPACE
            0x3000,
            // ZERO WIDTH NO-BREAK SPACE
            0xFEFF,
            // HALFWIDTH HANGUL FILLER
            0xFFA0 => true,
            else => false,
        };
    }

    fn readWhiteSpace(self: *Self) void {

        var rr: i64 = self.peek();
        var currentIsWhiteSpace: bool = self.isWhiteSpace(rr);
        while (currentIsWhiteSpace) {
            _ = self.read();
            rr = self.peek();
            currentIsWhiteSpace = self.isWhiteSpace(rr);
        }
    }

    fn isIDDigit(self: *Self, c: i64) bool {
        return switch (c) {
            '0'...'9',
            // unicode identifiers
            0x0660...0x0669,
            0x06F0...0x06F9,
            0x0966...0x096F,
            0x09E6...0x09EF,
            0x0A66...0x0A6F,
            0x0AE6...0x0AEF,
            0x0B66...0x0B6F,
            0x0BE7...0x0BEF,
            0x0C66...0x0C6F,
            0x0CE6...0x0CEF,
            0x0D66...0x0D6F,
            0x0E50...0x0E59,
            0x0ED0...0x0ED9,
            0x1040...0x1049
                => true,
            else => false
        };
    }

    // Also from Vexu/bog's tokenizer
    // https://github.com/Vexu/bog/blob/master/src/tokenizer.zig
    fn isLetter(self: *Self, c: i64) bool {
        return switch (c) {
            'a'...'z',
            'A'...'Z',
            '_',
            // '0'...'9', // ??
            // unicode identifiers
            0x00A8,
            0x00AA,
            0x00AD,
            0x00AF,
            0x00B2...0x00B5,
            0x00B7...0x00BA,
            0x00BC...0x00BE,
            0x00C0...0x00D6,
            0x00D8...0x00F6,
            0x00F8...0x167F,
            0x1681...0x180D,
            0x180F...0x1FFF,
            0x200B...0x200D,
            0x202A...0x202E,
            0x203F...0x2040,
            0x2054,
            0x2060...0x218F,
            0x2460...0x24FF,
            0x2776...0x2793,
            0x2C00...0x2DFF,
            0x2E80...0x2FFF,
            0x3004...0x3007,
            0x3021...0x302F,
            0x3031...0xD7FF,
            0xF900...0xFD3D,
            0xFD40...0xFDCF,
            0xFDF0...0xFE44,
            0xFE47...0xFFFD,
            0x10000...0x1FFFD,
            0x20000...0x2FFFD,
            0x30000...0x3FFFD,
            0x40000...0x4FFFD,
            0x50000...0x5FFFD,
            0x60000...0x6FFFD,
            0x70000...0x7FFFD,
            0x80000...0x8FFFD,
            0x90000...0x9FFFD,
            0xA0000...0xAFFFD,
            0xB0000...0xBFFFD,
            0xC0000...0xCFFFD,
            0xD0000...0xDFFFD,
            0xE0000...0xEFFFD,
            => true,
            else => false,
        };
    }

    fn peek(self: *Self) i64 {
        if (self.saved == -2) {
            if (self.saved2 != -2) {
                self.saved = self.saved2;
                self.saved2 = -2;
            } else {
                var tmp_ = self.iterator.nextCodepoint();
                if (tmp_ == null) {
                    return -1;
                }
                var tmp = @as(i64, tmp_.?);

                self.saved = tmp;
            }
        }
        return self.saved;
    }

    fn peek2(self: *Self) i64 {

        if(self.saved == -2) {
            var tmp_ = self.iterator.nextCodepoint();
            if (tmp_ == null) {
                return -1;
            }
            var tmp = @as(i64, tmp_.?);

            self.saved = tmp;
        }

        if(self.saved2 == -2) {
            var tmp_ = self.iterator.nextCodepoint();
            if (tmp_ == null) {
                return -1;
            }
            var tmp = @as(i64, tmp_.?);

            self.saved2 = tmp;
        }

        return self.saved2;

    }

    pub fn parseFully(self: *Self) ?*IokeObject {
        return self.parseMessageChain();
    }

    fn parseMessageChain(self: *Self) ?*IokeObject {
        var newTop: ChainContext =
            if (self.top == null)  ChainContext{} else
            ChainContext{ .parent = self.top, };

        self.top = &newTop;
        while(self.parseMessage()) {}

        newTop.popOperatorsTo(999999);
        const retPtr = newTop.pop();

        if (self.top.?.*.parent != null) {
            self.top = self.top.?.*.parent;
        }

        return retPtr;
    }

    pub fn charDesc(self: *Self, c: i64) []u8 {
        var buf: [12]u8 = undefined;
        var fbs = std.io.fixedBufferStream(&buf);
        const writer = fbs.writer();

        switch(c) {
            -1 => std.fmt.format(writer, "EOF", .{}) catch unreachable,
            9 => std.fmt.format(writer, "TAB", .{}) catch unreachable,
            10, 13 => std.fmt.format(writer, "EOL", .{}) catch unreachable,
            else =>
                std.fmt.format(writer, "'{}'", .{c}) catch unreachable,
        }

        return fbs.getWritten();
    }

    fn parseCharacter(self: *Self, char: i64) void {
        const l = self.lineNumber;
        const cc = self.currentCharacter;

        self.readWhiteSpace();
        const rr = self.read();
        if(rr != char) {
            var buf: [100]u8 = undefined;
            var fbs = std.io.fixedBufferStream(&buf);
            const writer = fbs.writer();
            std.fmt.format(
                writer,
                "Expected: '{}' got: {}", .{char, self.charDesc(rr)}
            ) catch unreachable;
            self.parseFail(l, cc, fbs.getWritten());
        }
    }

    fn parseOperatorChars(self: *Self, indicator: i64) void {
        const l = self.lineNumber;
        const cc = self.currentCharacter;

        var buf: [12]u8 = undefined;
        var fbs = std.io.fixedBufferStream(&buf);
        const writer = fbs.writer();
        std.fmt.format(writer, "{}" , .{indicator} ) catch unreachable;

        var rr: i64 = -1;
        rr = self.peek();

        while(true) {

            switch(rr) {
                '+', '-', '*', '%',
                '<', '>', '!', '?',
                '~', '&', '|', '^',
                '$', '=', '@', '\'',
                '`', ',', '#' => {
                    _ = self.read();
                    std.fmt.format(writer, "{}" , .{rr} ) catch unreachable;
                    break;
                },
                else => {
                    if (rr == '/' and indicator != '#') {
                        _ = self.read();
                        std.fmt.format(writer, "{}" , .{rr} ) catch unreachable;
                        break;
                    }

                    var m = Message{
                        .runtime = self.runtime,
                        .name = fbs.getWritten(),
                        .line = l,
                        .position = cc,
                    };

                    var mx = self.runtime.createMessage(&m);

                    if(rr == '(') {
                        _ = self.read();
                        var args = self.parseCommaSeparatedMessageChains();
                        self.parseCharacter(')');
                        mx.data.?.Message.?.setArguments(args);
                        self.top.?.*.add(mx);
                    } else {
                        self.possibleOperator(mx);
                    }
                    return;
                }
            }
        }
    }

    fn parseFail(self: *Self, line: u32, char: u32, msg: []u8) void {
        std.log.err("file TODO:{}:{}:{}", .{line, char, msg});
    }

    fn parseCommaSeparatedMessageChains(self: *Self) *ArrayList(IokeObject) {
        var chain: ArrayList(IokeObject) = ArrayList(IokeObject).init(self.allocator);
        // return chain;

        var curr: ?*IokeObject = parseMessageChain(self);
        while (curr != null) {
            chain.append(curr.?.*) catch unreachable;
            self.readWhiteSpace();
            var rr: i64 = self.peek();
            if(rr == ',') {
                _ = self.read();
                curr = self.parseMessageChain();
                if(curr == null) {
                    var buf: [100]u8 = undefined;
                    var fbs = std.io.fixedBufferStream(&buf);
                    const writer = fbs.writer();
                    std.fmt.format( writer, "Expected expression following comma" , .{} ) catch unreachable;
                    self.parseFail(self.lineNumber, self.currentCharacter, fbs.getWritten());
                    break;
                }
            } else {
                if(curr != null and curr.?.data.?.Message.?.isTerminator and curr.?.data.?.Message.?.next == null) {
                    _ = chain.orderedRemove(chain.items.len - 1);
                }
                curr = null;
            }
        }
        return &chain;
    }


    fn isUnary(self: *Self, name: []const u8) bool {
        if (self.unaryOperators.?.contains(name) and
                (self.top.?.*.head == null or
                     self.top.?.*.last != null and self.top.?.last.?.data.?.Message.?.isTerminator)) {
            return true;
        } else {
            return false;
        }
    }

    fn possibleOperatorPrecedence(self: *Self, name: []const u8) i16 {
        if (name.length > 0) {
            var first: u8 = name[0];
            switch (first) {
                '|' => {
                    return 9;
                },
                '^' => {
                    return 8;
                },
                '&' => {
                    return 7;
                },
                '=', '!', '?',
                '~', '$' => {
                    return 6;
                },
                '>', '<' => {
                    return 5;
                },
                '+', '-' => {
                    return 3;
                },
                '*', '/', '%' => {
                    return 2;
                },
                else => {
                    return -1;
                }
            }
        }
    }

    fn possibleOperator(self: *Self, mx: *IokeObject) void {
        var maybeName: ?[]const u8 = mx.data.?.Message.?.getName();
        var name: []const u8 = "";
        if (maybeName != null) {
            name = maybeName.?;
        } else {
            return;
        }

        if(self.isUnary(name) or self.onlyUnaryOperators.?.contains(name)) {
            self.top.?.add(mx);
            self.top.?.push(-1, mx, Level.Type.UNARY);
            return;
        }


    }

    fn parseEmptyMessageSend(self: *Self) void {
        const l: u32 = self.lineNumber;
        const cc: u32 = self.currentCharacter - 1;
        var args = self.parseCommaSeparatedMessageChains();
        self.parseCharacter(')');

        var m: Message = Message{
            .runtime = self.runtime,
            .name = ""[0..]
        };
        m.setLine(l);
        m.setPosition(cc);
        var mx = self.runtime.createMessage(&m);
        mx.data.?.Message.?.setArguments(args);
        self.top.?.*.add(mx);
    }

    fn parseOpenCloseMessageSend(self: *Self, end: i64, name: []const u8) void {
        const l: u32 = self.lineNumber;
        const cc: u32 = self.currentCharacter - 1;

        const rr: i64 = self.peek();
        const r2: i64 = self.peek2();

        var m = Message{
            .runtime = self.runtime,
            .name = name,
            .line = l,
            .position = cc,
        };

        var mx = self.runtime.createMessage(&m);

        if(rr == end and r2 == '(') {
            _ = self.read();
            _ = self.read();
            var args = self.parseCommaSeparatedMessageChains();
            self.parseCharacter(')');
            mx.data.?.Message.?.setArguments(args);
        } else {
            var args = self.parseCommaSeparatedMessageChains();
            self.parseCharacter(end);
            mx.data.?.Message.?.setArguments(args);
        }
        self.top.?.*.add(mx);
    }

    pub fn parseRegularMessageSend(self: *Self, indicator: i64) void {
        const l: u32 = self.lineNumber;
        const cc: u32 = self.currentCharacter - 1;

        var buf: [256]u8 = undefined;
        var fbs = std.io.fixedBufferStream(&buf);
        const writer = fbs.writer();
        std.fmt.format(writer, "{}" , .{indicator} ) catch unreachable;

        var rr: i64 = -1;
        rr = self.peek();

        while(self.isLetter(rr) or
                  self.isIDDigit(rr) or
                  rr == ':' or
                  rr == '!' or
                  rr == '?' or
                  rr == '$') {
            _ = self.read();
            std.fmt.format(writer, "{}" , .{rr} ) catch unreachable;
            rr = self.peek();
        }
        var m: Message = Message{
            .runtime = self.runtime,
            .name = fbs.getWritten(),
        };

        m.setLine(l);
        m.setPosition(cc);

        var mx = self.runtime.createMessage(&m);

        if(rr == '(') {
            _ = self.read();
            var args = self.parseCommaSeparatedMessageChains();
            self.parseCharacter(')');
            // mx.data should always be there after createMessage!
            mx.data.?.Message.?.setArguments(args);
            self.top.?.*.add(mx);
        } else {
            // FINISH
            self.possibleOperator(mx);
        }
    }

    pub fn parseMessage(self: *Self) bool {

        while (true) {

            var rr = self.peek();

            if (rr == -1) {
                _ = self.read();
                return false;
            }

            switch(rr) {
                ',', ')', ']', '}' => return false,
                '(' => {
                    _ = self.read();
                    self.parseEmptyMessageSend();
                    return true;
                },
                '[' => {
                    self.parseOpenCloseMessageSend(']', "[]"[0..]);
                    return true;
                },
                '{' => {
                    self.parseOpenCloseMessageSend('}', "{}"[0..]);
                    return true;
                },
                '+', '-', '*', '%',
                '<', '>', '!', '?',
                '~', '&','|', '^',
                '$', '=', '@', '\'',
                '`', '/' => {
                    _ = self.read();
                    self.parseOperatorChars(rr);
                    return true;

                },
                else => {
                    _ = self.read();
                    self.parseRegularMessageSend(rr);

                    return true;
                },
            }
            return false;
        }
    }
};



// Tests

test "lang.parser.IokeParser" {
    const expect = std.testing.expect;
    // var fixed_buffer_mem: [4 * 1024 * 1024]u8 = undefined;
    // var fixed_allocator = std.heap.FixedBufferAllocator.init(fixed_buffer_mem[0..]);
    // var failing_allocator = std.testing.FailingAllocator.init(&fixed_allocator.allocator, 0);
    var failing_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // var buf = "x = 'foo".*;
    var buf = "arg = '(bar quux)".*;
    var stringBuf = std.unicode.Utf8View.init(&buf) catch unreachable;
    var iterator = stringBuf.iterator();
    const runtime: *const *Runtime = &(Runtime{
        .allocator = &failing_allocator.allocator,
    }).init();
    var parser = IokeParser{
        .allocator = &failing_allocator.allocator,
        .iterator = iterator,
        .runtime = runtime,
    };
    parser.init();
    defer parser.deinit();

    var ret = parser.parseFully();

    if (ret == null) {
        std.log.err("ret is null \n", .{});
    } else {
        std.log.err("parsedfullt \n", .{});
    }

    expect(true);
}
