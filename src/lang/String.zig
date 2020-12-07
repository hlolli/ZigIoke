const std = @import("std");
const mem = std.mem;
const autoHash = std.hash.autoHash;
const Wyhash = std.hash.Wyhash;

const ascii_upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
const ascii_lower = "abcdefghijklmnopqrstuvwxyz";

const ascii_upper_start: usize = 65;
const ascii_upper_end: usize = 90;
const ascii_lower_start: usize = 97;
const ascii_lower_end: usize = 122;

pub const String = struct {
    const Self = @This();

    fn upper_map(c: u8) usize {
        return c - ascii_upper_start;
    }

    fn lower_map(c: u8) usize {
        return c - ascii_lower_start;
    }

    // @static
    pub fn toUpperCase(string: []u8) void {
        for (string) |c, i| {
            if (ascii_lower_start <= c and c <= ascii_lower_end) {
                string[i] = ascii_upper[@call(.{ .modifier = .always_inline }, lower_map, .{c})];
            }
        }
    }

    // @static
    pub fn equals(s1: []const u8, s2: []const u8) bool {
        return mem.eql(u8, s1, s2);
    }
};
