const std = @import("std");

// Text(String text)
pub const Text = struct {
    const Self = @This();
    text: []const u8,
    // @static

    pub fn toString(self: *Self) []const u8 {
        return self.text;
    }
};
