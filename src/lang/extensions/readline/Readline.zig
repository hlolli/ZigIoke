const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const gnu_readline = @cImport({
    @cInclude("readline/readline.h");
    @cInclude("readline/history.h");
});


pub const Readline = struct {
    const Self = @This();
    allocator: *Allocator,
    buffer: ?ArrayList(u8) = null,

    pub fn readline(self: *Self) void {
        self.buffer = gnu_readline.readline(">> ");

        while (self.buffer != null) {
            if (self.buffer.count() > 0) {
                add_history(self.buffer);
            }

            // printf("[%s]\n", buf);

            // readline malloc's a new buffer every time.
            // free(buf);
            buffer.clear();
        }
    }
};
