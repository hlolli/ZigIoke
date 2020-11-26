const std = @import("std");
// const IokeIO = @import("lang/IokeIO.zig").IokeIO;
const Message = @import("./lang/Message.zig").Message;
const IokeObject = @import("./lang./IokeObject.zig").IokeObject;
// const Readline = @import("./lang/extensions/readline/Readline.zig").Readline;
const Runtime = @import("./lang/Runtime.zig").Runtime;
const Interpreter = @import("./lang/Interpreter.zig").Interpreter;
const Utf8View = std.unicode.Utf8View;
const Allocator = std.mem.Allocator;
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);


pub fn main() void {
    var allocator = &arena.allocator;
    // var buf = "💯hello".*;
    var buf = "arg = '(bar quux)".*;
    var stringBuf = Utf8View.init(&buf) catch unreachable;
    var iterator = stringBuf.iterator();
    var interpreter: Interpreter = Interpreter{};
    var runtime: Runtime = Runtime{
        .allocator = allocator,
        .interpreter = &interpreter,
    };
    std.log.info("\n nil0 {*}\n", .{&runtime});
    runtime.init();

    // root context
    const context = &runtime.ground.?;

    // root message
    var mx = Message{
        .runtime = &runtime,
        .name = "."[0..],
        .isTerminator = true,
    };

    var message = runtime.createMessage(&mx);

    var ret = runtime.evaluateStream(iterator, message, context);

    // _ = Message.newFromStream(&runtime, iterator);

    std.log.info("\nAll your codebase are belong to us.\n", .{});
    // var readline = Readline{.allocator = allocator};
    // _ = readline.readline();
    defer runtime.deinit();
    defer arena.deinit();
}
