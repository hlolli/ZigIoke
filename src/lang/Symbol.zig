const std = @import("std");

// Text(String text)
pub const Symbol = struct {
    const Self = @This();
    text: []const u8,
};
