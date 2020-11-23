const std = @import("std");
const Allocator = std.mem.Allocator;
const IokeDataTag = @import("./IokeData.zig").IokeDataTag;
const IokeDataType = @import("./IokeData.zig").IokeDataType;
const IokeData = @import("./IokeData.zig").IokeData;
const IokeObject = @import("./IokeObject.zig").IokeObject;
const IokeParser = @import("./parser/IokeParser.zig").IokeParser;
const Runtime = @import("./Runtime.zig").Runtime;
const StringIterator = std.unicode.Utf8Iterator;
const ArrayList = std.ArrayList;

// fake static
// pub fn setNext(next: ?IokeObject) void {
//     if (next != null) {
//         next.?.next = next;
//     }
// }


const Argument = struct {};

pub const Message = struct {
    const Self = @This();

    // extends IokeData
    type: IokeDataType = IokeDataType.NONE,
    line: ?u32 = null,
    position: ?u32 = null,
    isTerminator: bool = false,
    next: ?*IokeObject = null,
    prev: ?*IokeObject = null,
    name: []const u8,
    arguments: ArrayList(IokeObject) = undefined,
    runtime: *Runtime,

    pub fn getName(self: *Self) []const u8 {
        return self.name;
    }

    pub fn getNameStatic(msg: *IokeObject) ?[]const u8 {
        var maybeData = msg.*.getData();
        var ret: ?[]const u8 = null;
        if (maybeData != null and @as(IokeDataTag, maybeData.?.*) == IokeDataTag.Message) {
            ret = maybeData.?.Message.?.getName();
        }
        return ret;
    }

    pub fn getArguments(self: *Self) *ArrayList(IokeObject) {
        return &self.arguments;
    }

    pub fn setArguments(self: *Self, args: *ArrayList(IokeObject)) void {
        self.arguments = args.*;
    }

    pub fn setArgumentsStatic(msg: *IokeObject, args: *ArrayList(IokeObject)) void {
        var maybeData = msg.*.getData();
        if (maybeData != null and @as(IokeDataTag, maybeData.?.*) == IokeDataTag.Message) {
            maybeData.?.*.Message.?.*.setArguments(args);
        }
    }

    pub fn setLine(self: *Self, line: u32) void {
        self.line = line;
    }

    pub fn setPosition(self: *Self, currentChar: u32) void {
        self.position = currentChar;
    }

    pub fn setNext(self: *Self, next_: ?*IokeObject) void {
        if (next_ != null) {
            self.next = next_.?;
        } else {
            self.next = null;
        }
    }

    pub fn setPrev(self: *Self, prev_: ?*IokeObject) void {
        if (prev_ != null) {
            self.prev = prev_;
        } else {
            self.prev = null;
        }
    }

    pub fn setPrevStatic(on: *IokeObject, prev_: ?*IokeObject) void {
        var maybeData = on.*.getData();
        if (maybeData != null and @as(IokeDataTag, maybeData.?.*) == IokeDataTag.Message) {
            maybeData.?.Message.?.setPrev(prev_);
        }
    }

    pub fn setNextStatic(on: *IokeObject, next_: ?*IokeObject) void {
        var maybeData = on.*.getData();
        if (maybeData != null and @as(IokeDataTag, maybeData.?.*) == IokeDataTag.Message) {
            if (next_ == null) {
                maybeData.?.Message.?.setNext(null);
            } else {
                maybeData.?.Message.?.setNext(next_);
            }
        } else {
            std.log.err("PANIC: non message Object passed too setNext\n", .{});
        }
    }

    pub fn getIsTerminator(self: *Self) bool {
        return self.isTerminator;
    }

    pub fn isTerminatorStatic(on: *IokeObject) bool {
        var maybeData = on.*.getData();
        if (maybeData != null and @as(IokeDataTag, maybeData.?.*) == IokeDataTag.Message) {
            return maybeData.?.Message.?.*.getIsTerminator();
        } else {
            return false;
        }
    }

    pub fn getNext(self: *Self) ?*IokeObject {
        return self.next;
    }

    pub fn getNextStatic(on: *IokeObject) ?*IokeObject {
        var maybeData = on.*.getData();
        if (maybeData != null and @as(IokeDataTag, maybeData.?.*) == IokeDataTag.Message) {
            return maybeData.?.Message.?.*.getNext();
        } else {
            return null;
        }
    }

    pub fn getPrev(self: *Self) ?*IokeObject {
        return self.prev;
    }

    pub fn prevStatic(on: *IokeObject) ?*IokeObject {
        var maybeData = on.*.getData();
        if (maybeData != null and @as(IokeDataTag, maybeData.?.*) == IokeDataTag.Message) {
            return maybeData.?.Message.?.*.getPrev();
        } else {
            return null;
        }
    }

    pub fn newFromStreamStatic(runtime: *Runtime, iterator: StringIterator) IokeObject {
        var parser = IokeParser{
            .allocator = runtime.*.allocator,
            .runtime = runtime,
            .iterator = iterator,
        };
        parser.init();
        defer parser.deinit();

        // _ = parser.parseFully() catch |err| {
        //     std.log.info("Parse error {}\n", .{err});
        // };
        var m = parser.parseFully();
        if (m == null) {
            var mx = Message{
                .runtime = runtime,
                .name = "."[0..],
                .isTerminator = true,
            };
            mx.setLine(0);
            mx.setPosition(0);
            m = &(runtime.*.createMessage(&mx));
        }
        return m.?.*;
    }
};


// Tests
const expect = std.testing.expect;

test "lang.Message.newFromStream" {
    var fixed_buffer_mem: [100 * 1024]u8 = undefined;
    var fixed_allocator = std.heap.FixedBufferAllocator.init(fixed_buffer_mem[0..]);
    var failing_allocator = std.testing.FailingAllocator.init(&fixed_allocator.allocator, 0);
    var buf = "testStr".*;
    var stringBuf = std.unicode.Utf8View.init(&buf) catch unreachable;
    var iterator = stringBuf.iterator();

    var ret = newFromStream(&failing_allocator.allocator, iterator);
    // std.log.err("RET {}\n", .{ret});
    expect(@TypeOf(ret) == Message);
}
