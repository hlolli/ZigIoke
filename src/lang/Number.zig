const std = @import("std");


pub const Number = struct {
    const Self = @This();

    // @static
    pub fn intToHexString(int: u16) []u8 {
        var buf: [64]u8 = undefined;
        var fbs = std.io.fixedBufferStream(&buf);
        const writer = fbs.writer();
        std.fmt.format(writer, "{x}" , .{int} ) catch unreachable;
        return fbs.getWritten();
    }
};
