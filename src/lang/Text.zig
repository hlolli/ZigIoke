const std = @import("std");

// Text(String text)
pub const Text = struct {
    const Self = @This();
    text: []const u8,
};
