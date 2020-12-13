const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const FixedBufferStream = std.io.FixedBufferStream;
const Utf8View = std.unicode.Utf8View;
const Writer_ = std.io.Writer;

const initial_buffer_size: usize = 2;

pub const IokeString = struct {
    const Self = @This();
    pub const ReadError = error{};
    pub const WriteError = error{};
    pub const Error = error{};
    pub const Writer = Writer_(*Self, WriteError, write);
    allocator: *Allocator,
    buffer: *ArrayList([]const u8),
    capacity: usize = 0,

    pub fn getBytes(self: *Self) ![]const u8 {
        // var byte_buffer = self.allocator.alloc(u8, self.capacity + 1);
        // var index = 0;
        // for (self.buffer.items) |char| {
        //     byte_buffer
        //         _ = writer_.write(char) catch unreachable;
        // }
        const items =  self.buffer.items;
        return std.mem.concat(self.allocator, u8, items);
    }

    // provide a buffer and get the bytes
    pub fn read(self: *Self, writer_: anytype) void {
        for (self.buffer.items) |char| {
            _ = writer_.write(char) catch |e| {
                return;
            };
        }
    }

    // a way to fool the formatter, don't call directly!
    pub fn writeAll(self: *Self, chars: []const u8) !void {
        self.capacity += chars.len;
        return self.buffer.append(chars);
    }

    pub fn write(self: *Self, bytes: []const u8) WriteError!usize {
        self.buffer.append(bytes) catch |e| {
            return 0;
        };
        self.capacity += bytes.len;
        return bytes.len;
    }

    pub fn appendBytes(self: *Self, chars: []const u8) void {
        var utf8Buf = Utf8View.init(chars) catch unreachable;
        var iterator = utf8Buf.iterator();
        while (iterator.nextCodepointSlice()) |slice| {
            const char = self.allocator.dupe(u8, slice) catch unreachable;
            // char.* = ArrayList([]const u8).init(allocator);
            self.buffer.append(char) catch unreachable;
            self.capacity += slice.len;
            // switch (slice.len) {
            //     1 => {
            //         self.buffer.append(@as(u21, slice[0])) catch unreachable;
            //     },
            //     2 => {
            //         self.buffer.append(std.unicode.utf8Decode2(slice) catch unreachable) catch unreachable;
            //     },
            //     3 => {
            //         self.buffer.append(std.unicode.utf8Decode3(slice) catch unreachable) catch unreachable;
            //     },
            //     4 => {
            //         self.buffer.append(std.unicode.utf8Decode4(slice) catch unreachable) catch unreachable;
            //     },
            //     else => {
            //         std.log.err("invalid character in utf8 string \n", .{});
            //     },
            // }
        }
    }


    pub fn writer(self: *Self) Writer {
        return .{ .context = self };
    }

    pub fn init(allocator: *Allocator) *IokeString {
        var new_buffer = allocator.create(ArrayList([]const u8)) catch unreachable;
        new_buffer.* = ArrayList([]const u8).init(allocator);
        // const buffer = allocator.alloc(u8, initial_buffer_size) catch unreachable;
        // var fbs = std.io.fixedBufferStream(buffer);
        var str_return = allocator.create(IokeString) catch unreachable;
        str_return.* = IokeString{
            .allocator = allocator,
            .buffer = new_buffer,
        };

        return str_return;
    }
};
