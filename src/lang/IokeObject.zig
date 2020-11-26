// IokeData is mostly refered to the Message namespace
const std = @import("std");
const Allocator = std.mem.Allocator;
const IokeData = @import("./IokeData.zig").IokeData;
const IokeDataType = @import("./IokeData.zig").IokeDataType;
const IokeDataTag = @import("./IokeData.zig").IokeDataTag;
const Message = @import("./Message.zig").Message;
const Number = @import("./Number.zig").Number;
const Runtime = @import("./Runtime.zig").Runtime;
const String = @import("./String.zig").String;
const Body = @import("./Body.zig").Body;
const Cell = @import("./Cell.zig").Cell;

pub const FALSY_F: u8 = 1 << 0;
pub const NIL_F: u8 = 1 << 1;
pub const FROZEN_F: u8 = 1 << 2;
pub const ACTIVATABLE_F: u8 = 1 << 3;
pub const HAS_ACTIVATABLE_F: u8 = 1 << 4;
pub const LEXICAL_F: u8 = 1 << 5;

// pub fn defaultToString(self: *IokeObject) []const u8 {
//     const h = self.hashCode();
//     var hash: []u8 = Number.intToHexString(h);
//     String.toUpperCase(hash);
//     var buf: [256]u8 = undefined;
//     var fbs = std.io.fixedBufferStream(&buf);
//     const writer = fbs.writer();
//     if (self.isNil()) {
//         std.fmt.format(writer, "#<nul:{}>" , .{hash} ) catch unreachable;
//     } else {
//         // Object obj = Interpreter.send(self.runtime.kindMessage, self.runtime.ground, self);
//         // String kind = ((Text)IokeObject.data(obj)).getText();
//         // return "#<" + kind + ":" + hash + ">";
//         std.fmt.format(writer, "#<FIXME:{}>" , .{hash} ) catch unreachable;
//     }
//     return fbs.getWritten();
// }

// IokeObject(Runtime runtime, String documentation, IokeData data)
pub const IokeObject = struct {
    const Self = @This();
    deinitialized: bool = false,
    runtime: *Runtime,
    documentation: ?[]const u8 = null,
    body: ?*Body = null,
    data: ?*IokeData = null,
    next: ?*IokeObject = null,
    dataType: IokeDataType = IokeDataType.NONE,
    toString: ?[]const u8 = null,
    // toString: fn(*IokeObject) []const u8 = defaultToString,


    pub fn init(self: *Self) void {
        if (self.body == null) {
            var defaultBody = Body{.allocator = self.runtime.*.allocator};
            self.body = &defaultBody;
        }
    }

    pub fn deinit(self: *Self) void {
        if (self.deinitialized != true) {
            self.deinitialized = true;
            if (self.body != null) {
                self.body.?.*.deinit();
                self.body = null;
            }
            // if (self.data != null) {
            //     switch (self.data.?.*) {
            //         IokeDataTag.IokeObject => {
            //             if (self.data.?.*.IokeObject != null and !self.data.?.*.IokeObject.?.deinitialized) {
            //                 self.data.?.*.IokeObject.?.deinit();
            //             }
            //         },
            //         IokeDataTag.Message => {
            //             self.data.?.Message.?.*.arguments.deinit();
            //         },
            //         else => {}
            //     }
            //     self.data = null;
            // }
        }
    }

    pub fn isNil(self: *Self) bool {
        return (self.body.?.*.flags & NIL_F) != 0;
    }

    pub fn isTrue(self: *Self) bool {
        return (self.body.?.*.flags & FALSY_F) == 0;
    }

    pub fn isFrozen(self: *Self) bool {
        return (self.body.?.*.flags & FROZEN_F) != 0;
    }

    pub fn setFrozen(self: *Self, frozen: bool) void {
        if (frozen) {
            self.body.?.*.flags |= FROZEN_F;
        } else {
            self.body.?.*.flags &= ~FROZEN_F;
        }
    }

    pub fn isActivatable(self: *Self) bool {
        return (self.body.?.*.flags & ACTIVATABLE_F) != 0;
    }

    pub fn isSetActivatable(self: *Self) bool {
        return (self.body.?.*.flags & HAS_ACTIVATABLE_F) != 0;
    }

    pub fn setActivatable(self: *Self, activatable: bool) void {
        self.body.?.*.flags |= HAS_ACTIVATABLE_F;
        if (activatable) {
            self.body.?.*.flags |= ACTIVATABLE_F;
        } else {
            self.body.?.*.flags &= ~ACTIVATABLE_F;
        }
    }

    pub fn isLexical(self: *Self) bool {
        return (self.body.?.*.flags & LEXICAL_F) != 0;
    }

    pub fn parseMessage(self: *Self) bool {}

    pub fn getArguments(self: *Self) []IokeData {
        return self.data.getArguments();
    }

    pub fn getData(self: *Self) ?*IokeData {
        return self.data;
    }

    pub fn setData(self: *Self, data_: *IokeData) void {
        self.data = data_;
    }

    pub fn allocateCopy(self: *Self) *IokeObject {
        // DONT USE, assigning to var copies anything in zig
        var copyOfObj = self;
        return copyOfObj;
    }

    fn transplantActivation(self: *Self, mimic: *IokeObject) void {
        if(!self.isSetActivatable() and mimic.isSetActivatable()) {
            self.setActivatable(mimic.isActivatable());
        }
    }

    pub fn singleMimicsWithoutCheck(self: *Self, mimic: *IokeObject) void {
        self.body.?.*.mimic = mimic;
        self.body.?.*.mimicCount = 1;
        self.transplantActivation(mimic);
    }

    pub fn setKind(self: *Self, kind: []const u8) void {
        var textObj: *IokeObject = self.runtime.*.newText(kind);
        var kindData: IokeData = IokeData{
            .IokeObject = textObj,
        };
        self.body.?.*.put("kind"[0..], &kindData);
    }

    pub fn getRealContext(self: *Self) *IokeData {
        if (self.isLexical()) {
            return self.data.?.LexicalContext.ground;
        } else {
            var ret = IokeData{.IokeObject = self};
            return &ret;
        }
    }

    pub fn findCell(self: *Self, name: []const u8) *Cell {
        // Object cell;
        // IokeObject nul = on.runtime.nul;
        var nul = on.runtime.?.nul;
        // var c: IokeObject = on.*;

        while(true) {
            // Body b = c.body;
            // var b = self.body.?;
            var cell = self.body.?.get(name);
            var c = self;
            var b = c.body;
            if(cell != null) {
                if(cell == nul and c.isLexical()) {
                    c = c.data.?.LexicalContext.surroundingContext;
                } else {
                    return cell;
                }
            } else {
                if(b.?.mimic != null) {
                    if(c.isLexical()) {
                        cell = b.?.mimic.?.findCell(name);
                        if(cell != nul) {
                            return cell;
                        }
                        c = c.data.?.LexicalContext.surroundingContext;
                    } else {
                        c = b.?.mimic.?;
                    }
                } else {
                    for(0...b.?.mimicCount) |i| {
                        cell = b.?.mimics[i].findCell(name);
                        if(cell != nul) {
                            return cell;
                        }
                    }
                    if(c.isLexical()) {
                        c = c.data.?.LexicalContext.surroundingContext;
                    } else {
                        return nul;
                    }
                }
            }
        }
    }

    pub fn hashCode(self: *Self) u16 {
        // TODO
        return 123;
        // Object cell = IokeObject.findCell(self, "hash");
        // if(cell == self.runtime.nul) {
        //     return System.identityHashCode(self.body);
        // } else {
        //     return Number.extractInt(Interpreter.send(self.runtime.hashMessage, self.runtime.ground, self), self.runtime.hashMessage, self.runtime.ground);
        // }
    }


};
