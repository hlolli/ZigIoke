const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const gnu_readline = @cImport({
    @cInclude("stdio.h");
    @cInclude("readline/readline.h");
});


pub const Readline = struct {
    const Self = @This();
    allocator: *Allocator,
    buffer: ?ArrayList(u8) = null,

    pub fn readline(self: *Self) bool {
        // var x = gnu_readline.readline(">> ");
        // std.mem.free(x);
        // std.log.err("\n TYPE? {} \n", .{x});
        while(gnu_readline.readline(">> ").* > 0) {

        }
        return true;
        // while (self.buffer != null) {
        //     if (self.buffer.count() > 0) {
        //         // add_history(self.buffer);
        //     }

        //     // printf("[%s]\n", buf);

        //     // readline malloc's a new buffer every time.
        //     // free(buf);
        //     buffer.clear();
        // }
    }
};
