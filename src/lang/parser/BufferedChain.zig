// const IokeObject = @import("@ioke/ioke_object").IokeObject;
const std = @import("std");
const Allocator = std.mem.Allocator;
const IokeObject = @import("../IokeObject.zig").IokeObject;

pub const BufferedChain = struct {
    const Self = @This();
    parent: ?*BufferedChain = null,
    last: ?*IokeObject = null,
    head: ?*IokeObject = null,

    pub fn init(self: *Self, allocator: *Allocator) void {
        self.last = allocator.create(IokeObject) catch unreachable;
        self.head = allocator.create(IokeObject) catch unreachable;
    }
};
