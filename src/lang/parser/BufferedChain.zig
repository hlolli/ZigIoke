// const IokeObject = @import("@ioke/ioke_object").IokeObject;
const IokeObject = @import("../IokeObject.zig").IokeObject;

pub const BufferedChain = struct {
    parent: ?*BufferedChain = null,
    last: ?*IokeObject = null,
    head: ?*IokeObject = null,

    pub fn init() BufferedChain {
        return BufferedChain{
            .parent = null,
            .last = null,
            .head = null
        };
    }
};

// // const IokeObject = @import("@ioke/ioke_object").IokeObject;
// const std = @import("std");
// const Allocator = std.mem.Allocator;
// const IokeObject = @import("../IokeObject.zig").IokeObject;

// pub const BufferedChain = struct {
//     parent: ?*BufferedChain() = null,
//     last: ?*IokeObject = null,
//     head: ?*IokeObject = null,
// };
