const panic = @import("std").debug.panic;
const DefaultMethod = @import("./DefaultMethod.zig").DefaultMethod;
const Method = @import("./Method.zig").Method;
const IokeObject = @import("./IokeObject.zig").IokeObject;
const IokeParser = @import("./parser/IokeParser.zig").IokeParser;
// const AssociatedCode = @import("./AssociatedCode.zig").AssociatedCode;
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
    None,
    Nil,
    False,
    True,
    // AssociatedCode,
    DefaultMethod,
    Method,
    IokeObject,
    IokeParser,
    LexicalContext,
    Message,
    Runtime,
    Symbol,
    Text,
};

pub const IokeData = union(IokeDataTag) {
    None: ?IokeDataTag,
    Nil: ?*IokeObject,
    False: ?*IokeObject,
    True: ?*IokeObject,
    // AssociatedCode: ?*AssociatedCode,
    DefaultMethod: ?*DefaultMethod,
    Method: ?* Method,
    IokeObject: ?*IokeObject,
    IokeParser: ?*IokeParser,
    LexicalContext: ?*LexicalContext,
    Message: ?*Message,
    Runtime: ?*Runtime,
    Symbol: ?*Symbol,
    Text: ?*Text,
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
        }
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
            }
        }
    }

    pub fn getMessage(iokeData: *IokeData) ?*Message {
        switch (iokeData.*) {
            IokeDataTag.Message => {
                return iokeData.Message.?;
            },
            else => {
                return null;
            }
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
            IokeDataTag.DefaultMethod,
            IokeDataTag.Method => {
                return true;
            },
            else => {
                return false;
            }
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
            IokeDataTag.IokeObject,
            IokeDataTag.None,
            IokeDataTag.Nil,
            IokeDataTag.False,
            IokeDataTag.True => {
                return true;
            },
            else => {
                return false;
            }
        }
    }

    pub fn isBoolean(iokeData: *IokeData) bool {
        switch (iokeData.*) {
            IokeDataTag.False,
            IokeDataTag.True => {
                return true;
            },
            else => {
                return false;
            }
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
            else => {}
        }
    }

    pub fn checkMimic(iokeData: *IokeData, message: *IokeObject, context: *IokeObject) void {
        switch (iokeData.*) {
            IokeDataTag.Nil,
            IokeDataTag.False,
            IokeDataTag.True => {
                // TODO can't mimic oddball!
            },
            else => {}
        }
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
