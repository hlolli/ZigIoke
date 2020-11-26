const panic = @import("std").debug.panic;
const IokeObject = @import("./IokeObject.zig").IokeObject;
const IokeParser = @import("./parser/IokeParser.zig").IokeParser;
const LexicalContext = @import("./LexicalContext.zig").LexicalContext;
const Message = @import("./Message.zig").Message;
const Runtime = @import("./Runtime.zig").Runtime;
const Symbol = @import("./Symbol.zig").Symbol;
const Text = @import("./Text.zig").Text;

pub const IokeDataType = enum {
    NONE,
    DEFAULT_METHOD,
    DEFAULT_MACRO,
    DEFAULT_SYNTAX,
    LEXICAL_MACRO,
    ALIAS_METHOD,
    NATIVE_METHOD,
    METHOD_PROTOTYPE,
    LEXICAL_BLOCK
};

pub const IokeDataTag = enum {
    IokeObject,
    IokeParser,
    Message,
    Runtime,
    Symbol,
    Text,
    LexicalContext
};

pub const IokeData = union(IokeDataTag) {
    IokeObject: ?*IokeObject,
    IokeParser: ?*IokeParser,
    Message: ?*Message,
    Runtime: ?*Runtime,
    Symbol: ?*Symbol,
    Text: ?*Text,
    LexicalContext: ?*LexicalContext,
};

pub const IokeDataHelpers = struct {
    pub fn as(iokeData: *IokeData, context: *IokeObject) ?*IokeObject {
        if(@as(IokeDataTag, iokeData.*) == IokeDataTag.IokeObject) {
            return iokeData.IokeObject.?;
        } else {
            panic("Can't handle non-IokeObjects right now");
            return null;
        }
    }

    pub fn isMessage(iokeData: *IokeData) bool {
        return (@as(IokeDataTag, iokeData.*) == IokeDataTag.Message);
    }
    pub fn toString(iokeData: *IokeData) []const u8 {
        var buf: [256]u8 = undefined;
        var fbs = std.io.fixedBufferStream(&buf);
        const writer = fbs.writer();

        switch (iokeData.*) {
            IokeDataTag.IokeObject => {
                if (iokeData.IokeObject.?.*.toString != null) {
                    std.fmt.format(writer, "#<{}:{*}>" , .{iokeData.IokeObject.?.*.toString.?, iokeData.IokeObject.?} ) catch unreachable;
                } else if (iokeData.IokeObject.?.*.isNil()) {
                    std.fmt.format(writer, "#<nul:{*}>" , .{iokeData.IokeObject.?} ) catch unreachable;
                } else {
                    std.fmt.format(writer, "#<object:{*}>" , .{iokeData.IokeObject.?} ) catch unreachable;
                }

            },
            IokeDataTag.Message => {
                std.fmt.format(writer, "{}" , .{iokeData.Message.?.*.code()} ) catch unreachable;
            },
            IokeDataTag.Text => {
                std.fmt.format(writer, "{}" , .{iokeData.Text.?.*.text} ) catch unreachable;
            },
            IokeDataTag.Symbol => {
                std.fmt.format(writer, "{}" , .{iokeData.Symbol.?.*.text} ) catch unreachable;
            },
            IokeDataTag.Level => {
                std.fmt.format(writer, "Level<{}, {}, {}, {}>" , .{
                    iokeData.Level.?.*.precedence,
                    iokeData.Level.?.*.operatorMessage,
                    iokeData.Level.?.*.type,
                    iokeData.Level.?.*.parent,
                }) catch unreachable;
            },
            IokeDataTag.LexicalContext => {
                std.fmt.format(writer, "LexicalContext:{*}" , .{iokeData.LexicalContext.?} ) catch unreachable;
            },
            else => {
                std.fmt.format(writer, "FIXME!!" , .{} ) catch unreachable;
            }
        }
        return fbs.getWritten();
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
