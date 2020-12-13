const std = @import("std");
// const IntManaged = std.math.big.int.Managed;
const Allocator = std.mem.Allocator;
const IokeObject = @import("./IokeObject.zig").IokeObject;
const Rational = std.math.big.Rational;

pub const Number = struct {
    const Self = @This();
    allocator: *Allocator,
    value: *Rational,

    pub fn init(allocator: *Allocator, initVal: ?[]const u8) *Number {
        var _number = allocator.create(Number) catch unreachable;
        var _rational = allocator.create(Rational) catch unreachable;
        _rational.* = Rational.init(allocator) catch unreachable;
        if (initVal == null or initVal.?.len == 0) {
            _rational.setFloatString("0"[0..]) catch unreachable;
        } else {
            _rational.setFloatString(initVal.?) catch unreachable;
        }
        _number.* = Number{
            .allocator = allocator,
            .value = _rational,
        };
        return _number;
    }


    // @static
    // pub fn intToHexString(int: u16) []u8 {
    //     var buf: [64]u8 = undefined;
    //     var fbs = std.io.fixedBufferStream(&buf);
    //     const writer = fbs.writer();
    //     std.fmt.format(writer, "{x}", .{int}) catch unreachable;
    //     return fbs.getWritten();
    // }

};
