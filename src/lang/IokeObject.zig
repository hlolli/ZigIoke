const std = @import("std");
const panic = std.debug.panic;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const IokeData = @import("./IokeData.zig").IokeData;
const IokeDataType = @import("./IokeData.zig").IokeDataType;
const IokeDataTag = @import("./IokeData.zig").IokeDataTag;
const IokeDataHelpers = @import("./IokeData.zig").IokeDataHelpers;
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

// IokeObject(Runtime runtime, String documentation, IokeData data)
pub const IokeObject = struct {
    const Self = @This();
    runtime: *Runtime,
    documentation: ?[]const u8 = null,
    body: *Body,
    data: *IokeData,
    next: ?*IokeObject = null,
    data_type: IokeDataType = IokeDataType.NONE,
    toString: ?[]const u8 = null,

    pub fn deinit(self: *Self) void {
        self.body.deinit();
    }

    pub fn isNil(self: *Self) bool {
        return (self.body.flags & NIL_F) != 0;
    }

    pub fn isTrue(self: *Self) bool {
        return (self.body.flags & FALSY_F) == 0;
    }

    pub fn isFrozen(self: *Self) bool {
        return (self.body.flags & FROZEN_F) != 0;
    }

    pub fn setFrozen(self: *Self, frozen: bool) void {
        if (frozen) {
            self.body.flags |= FROZEN_F;
        } else {
            self.body.flags &= ~FROZEN_F;
        }
    }

    fn checkFrozen(self: *Self, modification: []const u8, message: *IokeObject, context: *IokeObject) void {
        if (self.isFrozen()) {
            const names = [_][]const u8{
                "Error",
                "ModifyOnFrozen",
            };
            var maybe_cell_chain = self.runtime.condition.?.getCellChain(message, context, &names);
            // var condition__ = if (maybe_cell_chain != null) IokeDataHelpers.as(maybe_cell_chain.?, context) else null;
            if (maybe_cell_chain != null) {
                var cond_obj = IokeDataHelpers.getObject(maybe_cell_chain.?);
                if (cond_obj != null) {
                    var condition =  cond_obj.?.mimic(message, context);
                    condition.setCellFromObject("message"[0..], message);
                    condition.setCellFromObject("context"[0..], context);
                    condition.setCellFromObject("receiver"[0..], self);
                    condition.setCellFromObject("modification"[0..], context.runtime.getSymbol(modification));
                } else {
                    std.log.err("internal: Possibly fatal error, cellChain data isn't of IokeObject type", .{});
                }
            }
            // TODO!
            // context.runtime.errorCondition(condition);
        }
    }

    pub fn isActivatable(self: *Self) bool {
        return (self.body.flags & ACTIVATABLE_F) != 0;
    }

    pub fn isSetActivatable(self: *Self) bool {
        return (self.body.flags & HAS_ACTIVATABLE_F) != 0;
    }

    pub fn setActivatable(self: *Self, activatable: bool) void {
        self.body.flags |= HAS_ACTIVATABLE_F;
        if (activatable) {
            self.body.flags |= ACTIVATABLE_F;
        } else {
            self.body.flags &= ~ACTIVATABLE_F;
        }
    }

    pub fn isLexical(self: *Self) bool {
        return (self.body.flags & LEXICAL_F) != 0;
    }

    pub fn parseMessage(self: *Self) bool {}

    pub fn getArguments(self: *Self) ?*ArrayList(*IokeData) {
        var maybeMessage = IokeDataHelpers.getMessage(self.data);
        if (maybeMessage != null) {
            var maybeArgz = maybeMessage.?.getArguments();
            return if (maybeArgz == null) null else maybeArgz.?;
        } else {
            std.log.err("Tried to get arguments on non-message type Object and failed!\n", .{});
            return null;
        }
    }

    pub fn getData(self: *Self) *IokeData {
        return self.data;
    }

    pub fn setData(self: *Self, _data: *IokeData) void {
        self.data = _data;
    }

    pub fn allocateCopy(self: *Self, msg: ?*IokeObject, context: ?*IokeObject) *IokeObject {
        // std.log.info("allbymyself {*} \n", .{self.runtime.allocator});
        var _newBody = self.runtime.allocator.create(Body) catch unreachable;
        _newBody.* = Body{ .allocator = self.runtime.allocator };
        var copiedMsg = if (IokeDataHelpers.isMessage(self.data))
            Message.cloneData(self.data.Message, self)
            else
            Message.cloneData(null, self);

        var copied = self.runtime.allocator.create(IokeObject) catch unreachable;
        copied.* = IokeObject{
            .body = _newBody,
            .runtime = self.runtime,
            .data = copiedMsg,
        };
        return copied;
    }

    fn containsMimic(self: *Self, obj: *IokeObject) bool {
        if (self.body.mimicCount == 1) {
            return obj == self.body.mimic;
        }
        if (self.body.mimic != null) {
            return self.body.mimic == obj;
        } else if (self.body.mimics != null) {
            var i: usize = 0;
            while (i < self.body.mimicCount) {
                if(self.body.mimics.?.items[i] == obj) {
                    return true;
                }
                i += 1;
            }
        }
        return false;
    }

    // TODO everything's missing here
    fn addMimic(self: *Self, mimic_: *IokeObject) void {}

    fn transplantActivation(self: *Self, mimic_: *IokeObject) void {
        // _ = self.isSetActivatable();
        // _ = mimic_.isSetActivatable();
        if(!self.isSetActivatable() and mimic_.isSetActivatable()) {
            self.setActivatable(mimic_.isActivatable());
        }
    }

    pub fn singleMimicsWithoutCheck(self: *Self, mimic_: *IokeObject) void {
        // std.log.info("self__{*}\n", .{self.body});
        // std.log.info("mimic__{}\n", .{self.body});
        // std.log.info("BODYFLAGS 22 {}\n", .{mimic_.body.flags});
        self.body.mimic = mimic_;
        self.body.mimicCount = 1;
        self.transplantActivation(mimic_);
    }

    pub fn mimicsWithoutCheck(self: *Self, mimic_: *IokeObject) void {
        if(!self.containsMimic(mimic_)) {
            self.addMimic(mimic_);
            self.transplantActivation(mimic_);
        }
    }

    pub fn singleMimics(self: *Self, message: *IokeObject, context: *IokeObject) void {
        self.checkFrozen("mimic!", message, context);
        IokeDataHelpers.checkMimic(self.data, message, context);
        self.body.mimic = self;
        self.body.mimicCount = 1;
        self.transplantActivation(self);
        if (self.body.hooks != null) {
            // TODO
            // Hook.fireMimicked(mimic, message, context, this);
            // Hook.fireMimicsChanged(this, message, context, mimic);
            // Hook.fireMimicAdded(this, message, context, mimic);
        }
        // if(body.hooks != null) {}
    }

    // we skip .as here
    pub fn mimic(self: *Self, message: *IokeObject, context: *IokeObject) *IokeObject {
        self.checkFrozen("mimic!", message, context);
        var clone = self.allocateCopy(message, context);
        clone.singleMimics(message, context);
        return clone;
    }

    pub fn setKind(self: *Self, kind: []const u8) void {
        var textObj: *IokeObject = self.runtime.newText(kind);
        var kindData: IokeData = IokeData{
            .IokeObject = textObj,
        };
        self.body.put("kind"[0..], &kindData);
    }

    pub fn getRealContext(self: *Self) *IokeData {
        if (self.isLexical()) {
            return self.data.LexicalContext.?.ground;
        } else {
            var ret = IokeData{ .IokeObject = self };
            return &ret;
        }
    }

    pub fn registerCell(self: *Self, name: []const u8, data: *IokeData) void {
        self.body.put(name, data);
    }

    pub fn findCell(self: *Self, name: []const u8) ?*Cell {
        var nul = self.runtime.none.?;
        var cell = self.body.get(name);

        while (true) {
            var c = self;
            var b = c.body;
            if (cell != null and cell.?.value != null) {
                if (cell.?.value.? == nul and c.isLexical()) {
                    c = c.data.LexicalContext.?.surroundingContext;
                } else {
                    return cell;
                }
            } else {
                if (b.mimic != null) {
                    if (c.isLexical()) {
                        cell = b.mimic.?.findCell(name);
                        if (cell != null and
                            cell.?.value != null and
                            cell.?.value.? != nul)
                        {
                            return cell;
                        }
                        c = c.data.LexicalContext.?.surroundingContext;
                    } else {
                        c = b.mimic.?;
                    }
                } else {
                    if (b.mimics != null) {
                        for (b.mimics.?.items) |mimic_| {
                            cell = mimic_.findCell(name);
                            if (cell != null and
                                cell.?.value != null and
                                !IokeDataHelpers.isNul(cell.?.value.?, self.runtime))
                            {
                                return cell;
                            }
                        }
                    }
                    if (c.isLexical()) {
                        c = c.data.LexicalContext.?.surroundingContext;
                    } else {
                        return null;
                    }
                }
            }
        }
    }

    // current == self (there's no on it's always IokeObject)
    pub fn getCellChain(self: *Self, message: *IokeObject, context: *IokeObject, names: []const []const u8) ?*IokeData {
        var current: ?*Cell = null;
        for (names) |name| {
            current = self.getCell(message, context, name);
        }
        if (current != null) {
            return current.?.value;
        } else {
            return null;
        }
    }

    pub fn getCell(self: *Self, message: *IokeObject, context: *IokeObject, name: []const u8) ?*Cell {
        var cell = self.findCell(name);
        var newCell: ?*Cell = null;
        const names = [_][]const u8{
            "Error",
            "Invocation",
            "NotActivatable",
        };
        while (cell != null and cell.?.value != null and !IokeDataHelpers.isNul(cell.?.value.?, self.runtime)) {
            var maybe_condition = self.runtime.condition.?.getCellChain(message, context, &names);
            if (maybe_condition != null) {
                var condition__ = IokeDataHelpers.as(maybe_condition.?, context).?;
                var condition = condition__.mimic(message, context);
                condition.setCellFromObject("message"[0..], message);
                condition.setCellFromObject("context"[0..], context);
                condition.setCellFromObject("receiver"[0..], self);
                condition.setCellFromObject("cellName"[0..], self.runtime.getSymbol(name));
                newCell = cell.?;
                // newCell = &newCell;
            }
        }
        if (newCell == null) {
            if (cell == null) {
                return null;
            } else {
                return cell;
            }
        } else {
            return newCell;
        }
    }

    pub fn setCell(self: *Self, name: []const u8, value: *IokeData) void {
        self.body.put(name, value);
    }

    pub fn setCellFromObject(self: *Self, name: []const u8, iokeObject: *IokeObject) void {
        var wrapper = IokeData{ .IokeObject = iokeObject };
        self.body.put(name, &wrapper);
    }
};
