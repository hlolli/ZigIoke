const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const IokeDataTag = @import("./IokeData.zig").IokeDataTag;
const IokeDataType = @import("./IokeData.zig").IokeDataType;
const IokeData = @import("./IokeData.zig").IokeData;
const IokeDataHelpers = @import("./IokeData.zig").IokeDataHelpers;
const IokeObject = @import("./IokeObject.zig").IokeObject;
const IokeParser = @import("./parser/IokeParser.zig").IokeParser;
const Cell = @import("./Cell.zig").Cell;
const Runtime = @import("./Runtime.zig").Runtime;
const StringIterator = std.unicode.Utf8Iterator;


// fake static
// pub fn setNext(next: ?IokeObject) void {
//     if (next != null) {
//         next.?.next = next;
//     }
// }


pub const Message = struct {
    const Self = @This();

    // extends IokeData
    type: IokeDataType = IokeDataType.NONE,
    line: ?u32 = null,
    position: ?u32 = null,
    isTerminator: bool = false,
    cached: ?*IokeData = null,
    next: ?*IokeObject = null,
    prev: ?*IokeObject = null,
    name: []const u8,
    file: []const u8 = "FIXME"[0..],
    arguments: ?*ArrayList(*IokeObject) = null,
    runtime: *Runtime,

    pub fn deinit(self: *Self) void { }

    pub fn getName(self: *Self) []const u8 {
        return self.name;
    }

    // pub fn getNameStatic(msg: *IokeObject) ?[]const u8 {
    //     var maybeData = msg.*.getData();
    //     var ret: ?[]const u8 = null;
    //     if (maybeData != null and IokeDataHelpers.isMessage(maybeData.?)) {
    //         ret = maybeData.?.Message.?.getName();
    //     }
    //     return ret;
    // }

    pub fn getArguments(self: *Self) ?*ArrayList(*IokeObject) {
        return self.arguments;
    }

    pub fn setArguments(self: *Self, args: *ArrayList(*IokeObject)) void {
        self.arguments = args;
    }

    pub fn appendArgument(self: *Self, arg: *IokeObject) void {
        if (self.arguments == null) {
            var newArgz = ArrayList(*IokeObject).init(self.runtime.allocator);
            self.arguments = &newArgz;
        }
        self.arguments.?.append(arg) catch unreachable;
    }

    // pub fn setArgumentsStatic(msg: *IokeObject, args: *ArrayList(IokeObject)) void {
    //     var maybeData = msg.*.getData();
    //     if (maybeData != null and @as(IokeDataTag, maybeData.?.*) == IokeDataTag.Message) {
    //         maybeData.?.*.Message.?.*.setArguments(args);
    //     }
    // }

    pub fn setLine(self: *Self, line: u32) void {
        self.line = line;
    }
    pub fn setPosition(self: *Self, currentChar: u32) void {
        self.position = currentChar;
    }

    pub fn cloneData(self: ?*Self, obj: *IokeObject) *IokeData {
        // var oldMessage = if (obj.data != null and IokeDataHelpers.isMessage(obj.data.?)) IokeDataHelpers.getMessage(obj.data.?) else null;
        var newMessage = Message{
            .runtime = obj.runtime,
            .name = if (self != null) self.?.name else ""[0..],
        };
        if (IokeDataHelpers.isMessage(obj.data)) {
            var newArgz = ArrayList(*IokeObject).init(obj.runtime.allocator);
            newMessage.arguments = &newArgz;
            var objMsg = IokeDataHelpers.getMessage(obj.data);

            if (objMsg.?.arguments != null) {
                const slice = objMsg.?.arguments.?.items[0..objMsg.?.arguments.?.items.len];
                newArgz.insertSlice(0, slice) catch unreachable;
            }
            newMessage.isTerminator = objMsg.?.isTerminator;
            newMessage.file = objMsg.?.file;
            newMessage.line = objMsg.?.line;
            newMessage.position = objMsg.?.position;
        }
        var newMessageData: IokeData = IokeData{
            .Message = &newMessage,
        };
        return &newMessageData;
    }


    pub fn setNext(self: *Self, next_: ?*IokeObject) void {
        self.next = next_;
    }

    pub fn setNextOfLast(self: *Self, next_: ?*IokeObject) void {
        if (self.next != null) {
            var next__ = IokeDataHelpers.getMessage(next_.?);
            if (next__ == null) {
                std.log.err("Message.setNextOfLast failed: empty data\n", .{});
                return;
            }
            return next__.setNextOfLast(next_);
        } else {
            self.next = next_;
        }
    }

    pub fn setPrev(self: *Self, prev_: ?*IokeObject) void {
        self.prev = prev_;
    }

    // pub fn setPrevStatic(on: *IokeObject, prev_: ?*IokeData) void {
    //     var maybeData = on.*.getData();
    //     if (maybeData != null and @as(IokeDataTag, maybeData.?.*) == IokeDataTag.Message) {
    //         maybeData.?.Message.?.setPrev(prev_);
    //     }
    // }

    // pub fn setNextStatic(on: *IokeObject, next_: ?*IokeData) void {
    //     var maybeData = on.*.getData();
    //     if (maybeData != null and @as(IokeDataTag, maybeData.?.*) == IokeDataTag.Message) {
    //         if (next_ == null) {
    //             maybeData.?.Message.?.setNext(null);
    //         } else {
    //             maybeData.?.Message.?.setNext(next_);
    //         }
    //     } else {
    //         std.log.err("PANIC: non message Object passed too setNext\n", .{});
    //     }
    // }

    pub fn getIsTerminator(self: *Self) bool {
        return self.isTerminator;
    }

    // pub fn isTerminatorStatic(on: *IokeObject) bool {
    //     var maybeData = on.*.getData();
    //     if (maybeData != null and @as(IokeDataTag, maybeData.?.*) == IokeDataTag.Message) {
    //         return maybeData.?.Message.?.*.getIsTerminator();
    //     } else {
    //         return false;
    //     }
    // }

    pub fn getNext(self: *Self) ?*IokeData {
        return self.next;
    }

    // pub fn getNextStatic(on: *IokeObject) ?*IokeData {
    //     var maybeData = on.*.getData();
    //     if (maybeData != null and @as(IokeDataTag, maybeData.?.*) == IokeDataTag.Message) {
    //         return maybeData.?.Message.?.*.getNext();
    //     } else {
    //         return null;
    //     }
    // }

    pub fn getPrev(self: *Self) ?*IokeData {
        return self.prev;
    }

    // pub fn prevStatic(on: *IokeObject) ?*IokeData {
    //     var maybeData = on.*.getData();
    //     if (maybeData != null and @as(IokeDataTag, maybeData.?.*) == IokeDataTag.Message) {
    //         return maybeData.?.Message.?.*.getPrev();
    //     } else {
    //         return null;
    //     }
    // }

    // @static
    pub fn wrap1(cachedResult: *IokeObject) *Message {
        var cacheAsMsg = IokeData{.IokeObject = cachedResult};
        return Message.wrap3("cachedResult"[0..], &cacheAsMsg, cachedResult.runtime);
    }

    // @static
    pub fn wrap3(name: []const u8, cachedResult: *IokeData, runtime: *Runtime) *Message {
        var newMessage = Message{
            .runtime = runtime,
            .name = name,
        };
        newMessage.cached = cachedResult;
        return &newMessage;
    }

    pub fn newFromStreamStatic(runtime: *Runtime, iterator: StringIterator, message: *IokeObject, context: *IokeObject) *IokeObject {
        var parser = IokeParser{
            .allocator = runtime.allocator,
            .context = context,
            .message = message,
            .runtime = runtime,
            .iterator = iterator,
        };
        parser.init();

        // _ = parser.parseFully() catch |err| {
        //     std.log.info("Parse error {}\n", .{err});
        // };
        var maybeObj = parser.parseFully();
        if (maybeObj != null) {
            var mx = Message{
                .runtime = runtime,
                .name = "."[0..],
                .isTerminator = true,
                .line = 0,
                .position = 0,
            };
            return runtime.createMessage(&mx);
        } else {
            return maybeObj.?;
        }

        // if (mx != null) {
        //     mx.?.line = 0;
        //     mx.?.position = 0;
        // }
        // std.log.info("\n nil-2.5 {*}\n", .{m.?.runtime});
        // if (maybeObj == null) {
        //     mx = Message{
        //         .runtime = runtime,
        //         .name = "."[0..],
        //         .isTerminator = true,
        //     };
        //     // std.log.info("\n nil-3 {*}\n", .{mx.runtime});
        // }
        // std.log.info("\n nil-1 {*}\n", .{runtime});
        // std.log.info("\n nil-2 {*}\n", .{m.?.runtime});
        // std.log.info("\n nil-3 {*}\n", .{parser.runtime});
        // defer parser.deinit();
        // return m.?;
        // m =
        // std.log.info("\n nil!!444 {*}\n", .{m.?.runtime});
        // if (maybeObj != null) {
        //     return maybeObj.?;
        // } else {
        //     return newMsg;
        //     // msg.runtime.* = runtime.*;
        //     // return msg;
        //     // std.log.info("\n BAD STUFF!!! \n", .{});
        // }
    }

    pub fn code(self: *Self) []const u8 {
        var buf: [256]u8 = undefined;
        var fbs = std.io.fixedBufferStream(&buf);
        const writer = fbs.writer();

        // currentCode(base);

        if(self.next != null) {
            if(!self.isTerminator) {
                std.fmt.format(writer, " " , .{} ) catch unreachable;
            }
            std.fmt.format(writer, "{}" , .{self.next.?.code()} ) catch unreachable;
            // base.append(Message.code(next));
        }

        return fbs.getWritten();
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
