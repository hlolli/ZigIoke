const std = @import("std");
const AutoHashMap = std.AutoHashMap;
const IokeParser = @import("./IokeParser.zig").IokeParser;

pub const OpEntry = struct {
    name: []const u8,
    precedence: u16
};

pub const OpArity = struct {
    name: []const u8,
    arity: u16
};

pub const OpUnion = union {
    entry: OpEntry,
    arity: OpArity,
};

// var map = AutoHashMap(u32, u32).init(std.testing.allocator);
pub const Operators = struct {
    const Self = @This();
    // fn getOpTable() {}

    fn addOpEntry(self: *Self, name: []const u8, precedence: u16, current: *AutoHashMap([]const u8, OpUnion)) void {
        current.put(name, OpUnion{.entry = OpEntry{.name = name, .precedence = precedence}}) catch unreachable;
    }

    fn addOpArity(self: *Self, name: []const u8, arity: u16, current: *AutoHashMap([]const u8, OpUnion)) void {
        current.put(name, OpUnion{.arity = OpArity{.name = name, .arity = arity}}) catch unreachable;
    }

    fn addSetEntry(self: *Self, name: []const u8, id: []const u8, current: *AutoHashMap([]const u8, []const u8)) void {
        current.put(id, id) catch unreachable;
    }

    // fn addOpEntryComptime(self: *Self, comptime name: [] const u8, precedence: i32, current: AutoHashMap([]u8, OpUnion)) void {
    //     current.put(name, OpUnion{.entry = OpEntry{.name = name, .precedence = precedence}});
    // }

    pub fn createOrGetOpTables(self: *Self, parser: *IokeParser) void {
        self.addSetEntry("-"[0..], "-"[0..], &parser.*.unaryOperators.?);
        self.addSetEntry("~"[0..], "~"[0..], &parser.*.unaryOperators.?);
        self.addSetEntry("$"[0..], "$"[0..], &parser.*.unaryOperators.?);

        self.addSetEntry("'"[0..], "'"[0..], &parser.*.onlyUnaryOperators.?);
        self.addSetEntry("''"[0..], "''"[0..], &parser.*.onlyUnaryOperators.?);
        self.addSetEntry("`"[0..], "`"[0..], &parser.*.onlyUnaryOperators.?);
        self.addSetEntry(":"[0..], ":"[0..], &parser.*.onlyUnaryOperators.?);

        self.addOpEntry("!"[0..], 0, &parser.*.operatorTable.?);
        self.addOpEntry("?"[0..], 0, &parser.*.operatorTable.?);
        self.addOpEntry("$"[0..], 0, &parser.*.operatorTable.?);
        self.addOpEntry("~"[0..], 0, &parser.*.operatorTable.?);
        self.addOpEntry("#"[0..], 0, &parser.*.operatorTable.?);

        self.addOpEntry("**"[0..], 1, &parser.*.operatorTable.?);

        self.addOpEntry("*"[0..], 2, &parser.*.operatorTable.?);
        self.addOpEntry("/"[0..], 2, &parser.*.operatorTable.?);
        self.addOpEntry("%"[0..], 2, &parser.*.operatorTable.?);

        self.addOpEntry("+"[0..], 3, &parser.*.operatorTable.?);
        self.addOpEntry("-"[0..], 3, &parser.*.operatorTable.?);
        self.addOpEntry("∩"[0..], 3, &parser.*.operatorTable.?);
        self.addOpEntry("∪"[0..], 3, &parser.*.operatorTable.?);

        self.addOpEntry("<<"[0..], 4, &parser.*.operatorTable.?);
        self.addOpEntry(">>"[0..], 4, &parser.*.operatorTable.?);

        self.addOpEntry("<=>"[0..], 5, &parser.*.operatorTable.?);
        self.addOpEntry(">"[0..], 5, &parser.*.operatorTable.?);
        self.addOpEntry("<"[0..], 5, &parser.*.operatorTable.?);
        self.addOpEntry("<="[0..], 5, &parser.*.operatorTable.?);
        self.addOpEntry("≤"[0..], 5, &parser.*.operatorTable.?);
        self.addOpEntry(">="[0..], 5, &parser.*.operatorTable.?);
        self.addOpEntry("≥"[0..], 5, &parser.*.operatorTable.?);
        self.addOpEntry("<>"[0..], 5, &parser.*.operatorTable.?);
        self.addOpEntry("<>>"[0..], 5, &parser.*.operatorTable.?);
        self.addOpEntry("⊂"[0..], 5, &parser.*.operatorTable.?);
        self.addOpEntry("⊃"[0..], 5, &parser.*.operatorTable.?);
        self.addOpEntry("⊆"[0..], 5, &parser.*.operatorTable.?);
        self.addOpEntry("⊇"[0..], 5, &parser.*.operatorTable.?);

        self.addOpEntry("=="[0..], 6, &parser.*.operatorTable.?);
        self.addOpEntry("!="[0..], 6, &parser.*.operatorTable.?);
        self.addOpEntry("≠"[0..], 6, &parser.*.operatorTable.?);
        self.addOpEntry("==="[0..], 6, &parser.*.operatorTable.?);
        self.addOpEntry("=~"[0..], 6, &parser.*.operatorTable.?);
        self.addOpEntry("!~"[0..], 6, &parser.*.operatorTable.?);

        self.addOpEntry("&"[0..], 7, &parser.*.operatorTable.?);

        self.addOpEntry("&"[0..], 8, &parser.*.operatorTable.?);

        self.addOpEntry("^"[0..], 9, &parser.*.operatorTable.?);

        self.addOpEntry("&&"[0..], 10, &parser.*.operatorTable.?);
        self.addOpEntry("?&"[0..], 10, &parser.*.operatorTable.?);

        self.addOpEntry("||"[0..], 11, &parser.*.operatorTable.?);
        self.addOpEntry("?|"[0..], 11, &parser.*.operatorTable.?);


        self.addOpEntry(".."[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("..."[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("=>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("<->"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("->"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("∘"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("+>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("!>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("&>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("%>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("#>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("@>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("/>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("*>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("?>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("|>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("^>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("~>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("->>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("+>>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("!>>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("&>>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("%>>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("#>>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("@>>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("/>>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("*>>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("?>>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("|>>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("^>>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("~>>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("=>>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("**>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("**>>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("&&>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("&&>>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("||>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("||>>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("$>"[0..], 12, &parser.*.operatorTable.?);
        self.addOpEntry("$$>>"[0..], 12, &parser.*.operatorTable.?);

        self.addOpEntry("and"[0..], 13, &parser.*.operatorTable.?);
        self.addOpEntry("nand"[0..], 13, &parser.*.operatorTable.?);
        self.addOpEntry("or"[0..], 13, &parser.*.operatorTable.?);
        self.addOpEntry("xor"[0..], 13, &parser.*.operatorTable.?);
        self.addOpEntry("nor"[0..], 13, &parser.*.operatorTable.?);

        self.addOpEntry("<-"[0..], 14, &parser.*.operatorTable.?);
        self.addOpEntry("return"[0..], 14, &parser.*.operatorTable.?);
        self.addOpEntry("import"[0..], 14, &parser.*.operatorTable.?);


        self.addOpArity("++"[0..], 1, &parser.*.trinaryOperatorTable.?);
        self.addOpArity("--"[0..], 1, &parser.*.trinaryOperatorTable.?);

        self.addOpArity("="[0..], 2, &parser.*.trinaryOperatorTable.?);
        self.addOpArity("+="[0..], 2, &parser.*.trinaryOperatorTable.?);
        self.addOpArity("-="[0..], 2, &parser.*.trinaryOperatorTable.?);
        self.addOpArity("/="[0..], 2, &parser.*.trinaryOperatorTable.?);
        self.addOpArity("*="[0..], 2, &parser.*.trinaryOperatorTable.?);
        self.addOpArity("**="[0..], 2, &parser.*.trinaryOperatorTable.?);
        self.addOpArity("%="[0..], 2, &parser.*.trinaryOperatorTable.?);
        self.addOpArity("&="[0..], 2, &parser.*.trinaryOperatorTable.?);
        self.addOpArity("&&="[0..], 2, &parser.*.trinaryOperatorTable.?);
        self.addOpArity("|="[0..], 2, &parser.*.trinaryOperatorTable.?);
        self.addOpArity("||="[0..], 2, &parser.*.trinaryOperatorTable.?);
        self.addOpArity("^="[0..], 2, &parser.*.trinaryOperatorTable.?);
        self.addOpArity("<<="[0..], 2, &parser.*.trinaryOperatorTable.?);
        self.addOpArity(">>="[0..], 2, &parser.*.trinaryOperatorTable.?);

        self.addOpEntry("∈"[0..], 12, &parser.*.invertedOperatorTable.?);
        self.addOpEntry("∉"[0..], 12, &parser.*.invertedOperatorTable.?);
        self.addOpEntry("::"[0..], 12, &parser.*.invertedOperatorTable.?);
        self.addOpEntry(":::"[0..], 12, &parser.*.invertedOperatorTable.?);


        // invertedOperatorTable;
        // final ioke.lang.Runtime runtime = parser.runtime;
            // IokeObject opTable = IokeObject.as(IokeObject.findCell(runtime.message, "OperatorTable"), null);
            // if(opTable == runtime.nul) {
            //     opTable = runtime.newFromOrigin();
            //     opTable.setKind("Message OperatorTable");
            //     runtime.message.setCell("OperatorTable", opTable);
            // }

    }


};
