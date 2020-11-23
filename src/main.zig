const std = @import("std");
// const IokeIO = @import("lang/IokeIO.zig").IokeIO;
const Message = @import("./lang/Message.zig");
const Readline = @import("./lang/extensions/readline/Readline.zig").Readline;
const Runtime = @import("./lang/Runtime.zig").Runtime;
const Utf8View = std.unicode.Utf8View;
const Allocator = std.mem.Allocator;
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);


pub fn main() void {
    defer arena.deinit();
    var allocator = &arena.allocator;

    // var buf = "💯hello".*;
    var buf = "arg = '(bar quux)".*;
    var stringBuf = Utf8View.init(&buf) catch unreachable;
    var iterator = stringBuf.iterator();

    var runtime: Runtime = Runtime{
        .allocator = allocator
    };

    runtime.init();
    var readline = Readline{.allocator = allocator};
    readline.readline();
    var res = runtime.parseStream(iterator);

    // _ = Message.newFromStream(&runtime, iterator);

    std.log.info("All your codebase are belong to us.\n{}\n", .{res});
}
