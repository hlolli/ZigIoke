const IokeObject = @import("./IokeObject.zig").IokeObject;
const IokeParser = @import("./parser/IokeParser.zig").IokeParser;
const Message = @import("./Message.zig").Message;
const Runtime = @import("./Runtime.zig").Runtime;
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
    Text
};

pub const IokeData = union(IokeDataTag) {
    IokeObject: ?*IokeObject,
    IokeParser: ?*IokeParser,
    Message: ?*Message,
    Runtime: ?*Runtime,
    Text: ?*Text,
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
