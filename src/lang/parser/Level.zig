const IokeObject = @import("../IokeObject.zig").IokeObject;

pub const Level = struct {
    const Self = @This();
    pub const Type = enum {
        REGULAR, UNARY, ASSIGNMENT, INVERTED
    };

    precedence: i32 = -1,
    type: Level.Type,
    operatorMessage: ?*IokeObject = null,
    parent: ?*Level = null,
};
