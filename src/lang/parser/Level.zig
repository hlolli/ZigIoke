const IokeObject = @import("../IokeObject.zig").IokeObject;

// const Level

pub const Level = struct {
    const Self = @This();
    pub const Type = enum {
        REGULAR,
        UNARY,
        ASSIGNMENT,
        INVERTED
    };

    precedence: i32 = -1,
    type: Level.Type,
    operatorMessage: ?IokeObject = null,
    parent: ?*Level = null,


    pub fn toString(self: *Self) []uint8 {
        return "Level<" +
            self.precedence ++ ", " ++
            self.operatorMessage ++ ", " ++
            self.type ++ ", " ++
            self.parent ++ ">";
    }
};
