const std = @import("std");
const Allocator = std.mem.Allocator;
const panic = std.debug.panic;
const DefaultMethod = @import("./DefaultMethod.zig").DefaultMethod;
const Method = @import("./Method.zig").Method;
const IokeObject = @import("./IokeObject.zig").IokeObject;
const IokeParser = @import("./parser/IokeParser.zig").IokeParser;
const IokeString = @import("./IokeString.zig").IokeString;
const Level = @import("./parser/Level.zig").Level;
const LexicalContext = @import("./LexicalContext.zig").LexicalContext;
const Message = @import("./Message.zig").Message;
const Number = @import("./Number.zig").Number;
const Runtime = @import("./Runtime.zig").Runtime;
const Symbol = @import("./Symbol.zig").Symbol;
const Text = @import("./Text.zig").Text;

pub const IokeDataType = enum {
    NONE, DEFAULT_METHOD, DEFAULT_MACRO, DEFAULT_SYNTAX, LEXICAL_MACRO, ALIAS_METHOD, NATIVE_METHOD, METHOD_PROTOTYPE, LEXICAL_BLOCK
};

pub const IokeDataTag = enum {
    None,
    Nil,
    False,
    True,
    DefaultMethod,
    Method,
    IokeObject,
    IokeParser,
    LexicalContext,
    Message,
    Runtime,
    Symbol,
    Text,
    Level,
    Internal,
    Number,
};

pub const IokeData = union(IokeDataTag) {
    None: ?IokeDataTag,
    Nil: ?*IokeObject,
    False: ?*IokeObject,
    True: ?*IokeObject,
    DefaultMethod: ?*DefaultMethod,
    Method: ?*Method,
    IokeObject: ?*IokeObject,
    IokeParser: ?*IokeParser,
    LexicalContext: ?*LexicalContext,
    Message: ?*Message,
    Runtime: ?*Runtime,
    Symbol: ?*Symbol,
    Text: ?*Text,
    Level: ?*Level,
    Internal: ?*IokeString,
    Number: ?*Number,
};

fn maybeObject(iokeData: *IokeData) ?*IokeObject {
    switch (iokeData.*) {
        IokeDataTag.IokeObject => {
            return iokeData.IokeObject.?;
        },
        IokeDataTag.Nil => {
            return iokeData.Nil.?;
        },
        IokeDataTag.False => {
            return iokeData.False.?;
        },
        IokeDataTag.True => {
            return iokeData.True.?;
        },
        else => {
            return null;
        },
    }
}

pub const IokeDataHelpers = struct {
    pub fn getDefaultMethod(iokeData: *IokeData) ?*const DefaultMethod {
        if (iokeData.DefaultMethod != null) {
            return iokeData.DefaultMethod.?;
        } else {
            return null;
        }
    }

    pub fn getObject(iokeData: *IokeData) ?*IokeObject {
        return maybeObject(iokeData);
    }

    pub fn as(iokeData: *IokeData, context: *IokeObject) ?*IokeObject {
        var ret = maybeObject(iokeData);
        if (ret != null) {
            return ret;
        } else {
            panic("Can't handle non-IokeObjects right now", .{});
            // return null;
        }
    }

    pub fn isMessage(iokeData: *IokeData) bool {
        switch (iokeData.*) {
            IokeDataTag.Message => {
                return true;
            },
            else => {
                return false;
            },
        }
    }

    pub fn getMessage(iokeData: *IokeData) ?*Message {
        switch (iokeData.*) {
            IokeDataTag.Message => {
                return iokeData.Message.?;
            },
            else => {
                return null;
            },
        }
    }

    pub fn getArguments(iokeData: *IokeData) ?*ArrayList(*IokeData) {
        if (IokeDataHelpers.isMessage(iokeData)) {
            return iokeData.Message.?.getArguments();
        } else {
            return null;
        }
    }

    pub fn isAssociatedCode(iokeData: *IokeData) bool {
        switch (iokeData.*) {
            IokeDataTag.DefaultMethod, IokeDataTag.Method => {
                return true;
            },
            else => {
                return false;
            },
        }
    }

    pub fn canRun(iokeData: *IokeData) bool {
        // TODO
        // return (@as(IokeDataTag, iokeData.*) == IokeDataTag.AssociatedCode);
        return false;
    }

    pub fn isNil(iokeData: *IokeData) bool {
        return (@as(IokeDataTag, iokeData.*) == IokeDataTag.Nil);
    }

    // the internal nul
    pub fn isNul(iokeData: *IokeData, runtime: *Runtime) bool {
        var obj = maybeObject(iokeData);
        if (obj != null) {
            return obj.? == runtime.nul.?;
        } else {
            return false;
        }
    }

    pub fn isIokeObject(iokeData: *IokeData) bool {
        switch (iokeData.*) {
            IokeDataTag.IokeObject, IokeDataTag.None, IokeDataTag.Nil, IokeDataTag.False, IokeDataTag.True => {
                return true;
            },
            else => {
                return false;
            },
        }
    }

    pub fn isBoolean(iokeData: *IokeData) bool {
        switch (iokeData.*) {
            IokeDataTag.False, IokeDataTag.True => {
                return true;
            },
            else => {
                return false;
            },
        }
    }

    pub fn deinit(iokeData: *IokeData) void {
        switch (iokeData.*) {
            IokeDataTag.IokeObject => {
                iokeData.IokeObject.?.deinit();
            },
            IokeDataTag.None => {
                iokeData.None.?.deinit();
            },
            IokeDataTag.Nil => {
                iokeData.Nil.?.deinit();
            },
            IokeDataTag.False => {
                iokeData.False.?.deinit();
            },
            IokeDataTag.True => {
                iokeData.True.?.deinit();
            },
            else => {},
        }
    }

    pub fn checkMimic(iokeData: *IokeData, message: *IokeObject, context: *IokeObject) void {
        switch (iokeData.*) {
            IokeDataTag.Nil, IokeDataTag.False, IokeDataTag.True => {
                // TODO can't mimic oddball!
            },
            else => {},
        }
    }

    pub fn toString(allocator: *Allocator, iokeData: *IokeData) []const u8 {
        // const buf: []u8 = allocator.alloc(u8, 256) catch unreachable;
        // var buf: [256]u8 = undefined;
        // var fbs = std.io.fixedBufferStream(buf);
        // var writer = fbs.writer();
        var string = IokeString.init(allocator);
        var string_writer = string.writer();
        switch (iokeData.*) {
            IokeDataTag.IokeObject => {
                if (iokeData.IokeObject.?.*.toString != null) {
                    std.fmt.format(string_writer, "#<{}:{*}>", .{ iokeData.IokeObject.?.*.toString.?, iokeData.IokeObject.? }) catch unreachable;
                } else if (iokeData.IokeObject.?.*.isNil()) {
                    std.fmt.format(string_writer, "#<nul:{*}>", .{iokeData.IokeObject.?}) catch unreachable;
                } else {
                    std.fmt.format(string_writer, "#<object:{*}>", .{iokeData.IokeObject.?}) catch unreachable;
                }
            },
            IokeDataTag.Message => {
                string.appendBytes(iokeData.Message.?.*.code());
            },
            IokeDataTag.Text => {
                string.appendBytes(iokeData.Text.?.*.text);
            },
            IokeDataTag.Symbol => {
                string.appendBytes(iokeData.Symbol.?.*.text);
            },
            IokeDataTag.Nil => {
                // std.fmt.format(string_writer, "#<nul:{*}>", .{iokeData.Nil.?}) catch unreachable;
                string.appendBytes("nul"[0..]);
            },
            IokeDataTag.None => {
                // std.fmt.format(string_writer, "#<nul:{*}>", .{iokeData.None.?}) catch unreachable;
                string.appendBytes("nul"[0..]);
            },
            IokeDataTag.False => {
                string.appendBytes("false"[0..]);
            },
            IokeDataTag.True => {
                string.appendBytes("true"[0..]);
            },
            IokeDataTag.DefaultMethod => {
                std.fmt.format(string_writer, "#<method:{*}>", .{iokeData.DefaultMethod.?}) catch unreachable;
            },
            IokeDataTag.Method => {
                std.fmt.format(string_writer, "#<method:{*}>", .{iokeData.Method.?}) catch unreachable;
            },
            // IokeParser,
            // LexicalContext,
            // Message,
            // Runtime,
            // Symbol,
            // Text,
            // Level,
            IokeDataTag.Level => {
                var typeStr = switch(iokeData.Level.?.type) {
                    Level.Type.REGULAR => "regular"[0..],
                    Level.Type.UNARY => "unary"[0..],
                    Level.Type.ASSIGNMENT => "assignment"[0..],
                    Level.Type.INVERTED => "inverted"[0..],
                };
                std.fmt.format(string_writer, "Level<{}, {}, {}, {}>", .{
                    iokeData.Level.?.precedence,
                    // "USE THAT ONE BELOW"[0..],
                    // if (iokeData.Level.?.operatorMessage != null) IokeDataHelpers.toString(allocator, IokeData{.IokeObject=iokeData.Level.?.operatorMessage.?}) else "nul"[0..],
                    "nul"[0..],
                    typeStr,
                    // "USE THAT ONE BELOW"[0..],
                    // if (iokeData.Level.?.parent != null) IokeDataHelpers.toString(allocator, iokeData.Level.?.parent.?) else "nul"[0..],
                    "nul"[0..],
                }) catch unreachable;
            },
            IokeDataTag.LexicalContext => {
                std.fmt.format(string_writer, "LexicalContext:{*}", .{iokeData.LexicalContext.?}) catch unreachable;
            },
            else => {
                // std.log.info("YES INDEED! {}", .{@TypeOf(string).Error});
                // string.appendBytes("PLZFINDME"[0..]);
                std.fmt.format(string_writer, "FIXME", .{}) catch unreachable;
                // var x = s.getBytes();
                // var u_ = fbs.write("nul"[0..]) catch unreachable;
                // std.fmt.format(writer, "fix", .{}) catch unreachable;
            },
        }
        // string.read(&writer);
        var ret = string.getBytes() catch unreachable;
        return ret;
        // TODO free the memory
        // return fbs.getWritten();
    }
};

// pub const IokeData = struct {
//     const Self = @This();
//     next: ?IokeObject = null,
//     prev: ?IokeObject = null,
//     type: IokeDataType = IokeDataType.NONE,
//     // pub fn data(self: *Self, on: anytype) IokeData {
//     //     return on.data;
//     // }
//     pub fn setNext(self: *Self, next: IokeObject) void {
//         self.next = next;
//     }
//     pub fn setPrev(self: *Self, prev: IokeObject) void {
//         self.prev = prev;
//     }
// };
