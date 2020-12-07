const std = @import("std");
// const IokeIO = @import("lang/IokeIO.zig").IokeIO;
const Message = @import("./lang/Message.zig").Message;
const IokeObject = @import("./lang./IokeObject.zig").IokeObject;
// const Readline = @import("./lang/extensions/readline/Readline.zig").Readline;
const Runtime = @import("./lang/Runtime.zig").Runtime;
const Interpreter = @import("./lang/Interpreter.zig").Interpreter;
const IokeRegistry = @import("./lang/IokeRegistry.zig").IokeRegistry;
const Utf8View = std.unicode.Utf8View;
const Allocator = std.mem.Allocator;
var fixed_buffer_mem: [10 * 1024 * 1024]u8 = undefined;

pub fn main() void {
    // var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // var allocator = &arena.allocator;
    var fixed_buf_alloc = std.heap.FixedBufferAllocator.init(fixed_buffer_mem[0..]);
    var allocator = &fixed_buf_alloc.allocator;

    // var buf = "💯hello".*;
    var buf = "arg = '(bar quux)".*;
    var stringBuf = Utf8View.init(&buf) catch unreachable;
    var iterator = stringBuf.iterator();
    var interpreter: Interpreter = Interpreter{};
    var runtime = allocator.create(Runtime) catch unreachable;
    // errdefer allocator.destroy(runtime);

    runtime.* = Runtime{
        .allocator = allocator,
        .interpreter = &interpreter,
    };
    // std.log.info("\n nil0 {*}\n", .{&runtime});
    // std.log.info("\n allocator! {*}\n", .{&allocator});
    runtime = runtime.init();

    std.log.info("SELFMSGBODYFLAGS 11 {}\n", .{runtime.message.?.body.flags});
    // root context
    const context = runtime.ground.?;

    // root message
    var mx = Message{
        .runtime = runtime,
        .name = "."[0..],
        .isTerminator = true,
    };
    mx.setLine(0);
    mx.setPosition(0);
    var message = runtime.createMessage(&mx);

    var ret = runtime.evaluateStream(iterator, message, context);

    // _ = Message.newFromStream(&runtime, iterator);

    std.log.info("\nAll your codebase are belong to us.\n", .{});
    // var readline = Readline{.allocator = allocator};
    // _ = readline.readline();
    // defer runtime.deinit();
    // defer fixed_buf_alloc.deinit();
}
