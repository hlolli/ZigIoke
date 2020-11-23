const std = @import("std");
const Allocator = std.mem.Allocator;
const Message = @import("./Message.zig").Message;
const types = @import("../types.zig");
const StringIterator = types.StringIterator;

pub fn IokeIO(allocator: *Allocator, Reader) type {
    return struct {
        var io = IokeIO(allocator);

        const Self = @This();

        pub fn init(self: *Self) i64 {
            _ = self.io.init();
        }

    }
}
