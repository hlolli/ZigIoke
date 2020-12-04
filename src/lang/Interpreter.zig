const std = @import("std");
const ArrayList = std.ArrayList;
const Cell = @import("./Cell.zig").Cell;
const CellHelpers = @import("./Cell.zig").CellHelpers;
const DefaultMethod = @import("./DefaultMethod.zig").DefaultMethod;
const IokeData = @import("./IokeData.zig").IokeData;
const IokeDataType = @import("./IokeDataType.zig").IokeDataType;
const IokeDataHelpers = @import("./IokeData.zig").IokeDataHelpers;
const IokeObject = @import("./IokeObject.zig").IokeObject;
const Message = @import("./Message.zig").Message;
const Runtime = @import("./Runtime.zig").Runtime;
const String = @import("./String.zig").String;

pub const Interpreter = struct {
    const Self = @This();

    // @static
    pub fn evaluate(self: *Self, message: ?*IokeObject, ctx: *IokeObject, receiver: *IokeObject, lastReal_: ?*IokeObject) *IokeObject {

        var lastReal: *IokeObject = if (lastReal_ == null) ctx.runtime.getNil() else lastReal_.?;
        if (message == null or !IokeDataHelpers.isMessage(message.?.data)) {
            return lastReal;
        }

        var maybeCached = message.?.data.Message.?.cached;

        if (maybeCached != null) {
            var unwrapped = IokeDataHelpers.getObject(maybeCached.?);
            if (unwrapped == null) {
                std.log.err("Something went wrong in evaluation.\n", .{});
                return lastReal;
            } else {
                return self.evaluate(message.?.next, unwrapped.?, unwrapped.?, unwrapped.?);
            }
        } else if (String.equals(message.?.data.Message.?.name, "."[0..])) {
            return self.evaluate(message.?.next, ctx, ctx, lastReal);
        } else if (message.?.data.Message.?.name.len > 0 and
                       (message.?.data.Message.?.arguments == null or
                            message.?.data.Message.?.arguments.?.items.len == 0) and
                       message.?.data.Message.?.name[0] == ':') {
            var lastRealObj = message.?.runtime.getSymbol(message.?.data.Message.?.name[1..]);

            return self.evaluate(message.?.next, ctx, lastRealObj, lastRealObj);

        } else {

            var perf_ret_ = self.perform5(receiver, receiver, ctx, message.?, message.?.data.Message.?.name);
            if (perf_ret_ == null) {
                std.log.err("Something went wrong in evaluation.\n", .{});
                return lastReal;
            } else {
                return self.evaluate(message.?.next, ctx, perf_ret_.?, perf_ret_.?);

            }
        }
    }

    fn shouldActivate(self: *Self, obj: *IokeObject, message: *IokeObject) bool {
        return obj.isActivatable() or
            ((IokeDataHelpers.isAssociatedCode(obj.data)) and message.getArguments().?.items.len > 0);
    }

    fn findCell(self: *Self, message: *IokeObject, ctx: *IokeObject, obj: *IokeObject, name: []const u8, recv: *IokeObject) ?*Cell {
        var runtime = ctx.runtime;
        var cell = recv.findCell(name);
        var passed: ?*Cell = null;
        if (cell != null) {
            while (cell.?.value != null and cell.?.value == runtime.nul.?.data) {
                passed = recv.findCell("pass"[1..]);
                cell =  passed;
                if(passed != null and
                       passed.?.value != null and
                       passed.?.value.? != runtime.nul.?.data and
                       self.isApplicable(passed.?.value.?, message, ctx)) {
                    return cell;
                }
                // FIXME!
                // cell = signalNoSuchCell(message, ctx, obj, name, cell, recv);
            }
        }
        return cell;
    }

    pub fn send0(self: *Self, message: *IokeObject, context: *IokeObject, recv: *IokeData) ?*IokeObject {
        if (message.data != null and IokeDataHelpers.isMessage(message.data) and message.data.Message.cached != null) {
            return message.data.Message.cached.?;
        } else {
            return self.perform4(recv, context, message);
        }
    }

    pub fn send1(self: *Self, message: *IokeObject, context: *IokeObject, recv: *IokeData, argument: *IokeData) ?*IokeObject {
        if (IokeDataHelpers.isMessage(message.data) and message.data.Message.?.cached != null and message.data.Message.?.cached.?.IokeObject != null) {
            return message.data.Message.?.cached.?.IokeObject.?;
        } else {
            var m = message.allocateCopy(message, context);
            m.singleMimicsWithoutCheck(context.runtime.message.?);
            // TODO arguments
            // m.Arguments.Clear();
            // m.Arguments.Add(argument);
            return self.perform4(recv, context, message);
        }
    }

    pub fn sendAll(self: *Self, obj: *IokeData, context: *IokeObject, recv: *IokeData, args: *ArrayList(IokeData)) ?*IokeObject {
        if (IokeDataHelpers.isMessage(obj)) {
            var result = IokeDataHelpers.getMessage(obj.?);
            if (result != null) {
                return result.?.cached.?;
            }
        }
        var m = obj.?.data;
        if (IokeDataHelpers.isMessage(m)) {
            var current_args = IokeDataHelpers.getArguments(m.?);
            if (current_args != null) {
                for (current_args.?) |arg_obj| {
                    arg_obj.deinit();
                }
                current_args.?.deinit();
                current_args = &args;
            }
        }
        return self.perform4(cell, obj, recv, context, m);
    }

    // since there's no wrap, refer to c#'s implementation for reference
    pub fn perform4(self: *Self, obj: *IokeData, ctx: *IokeObject, message: *IokeObject) ?*IokeObject {
        var recv = IokeDataHelpers.as(obj, ctx);
        var msg = IokeDataHelpers.getMessage(message.data);
        var name = if (msg != null) msg.?.name else ""[0..];
        return self.perform5(recv.?, recv.?, ctx, message, name);
    }

    pub fn perform5(self: *Self, obj: *IokeObject, recv: *IokeObject, ctx: *IokeObject, message: *IokeObject, name: []const u8) ?*IokeObject {
        var cell = self.findCell(message, ctx, obj, name, recv);
        if (cell == null) {
            return ctx.runtime.nul.?;
        } else {
            return self.getOrActivate(cell.?, ctx, message, obj);
        }
    }

    fn isApplicable(self: *Self, pass: *IokeData, message: *IokeObject, ctx: *IokeObject) bool {
        if(pass != ctx.runtime.nul.?.data) {
            var recv = IokeDataHelpers.as(pass, ctx);
            if (recv != null) {
                var applicable_q = recv.?.findCell("applicable?");
                if (applicable_q != null and applicable_q.?.value != null and applicable_q.?.value.? != ctx.runtime.nul.?.data) {
                    // var applicableMsgDataAsMsg = IokeData{.IokeObject = ctx.runtime.isApplicableMessage.?};
                    var arg = ctx.runtime.createMessage(Message.wrap1(message)).data;
                    // self: *Self, message: *IokeObject, context: *IokeObject, recv: *IokeData, argument: *IokeData
                    // TODO error check the null below
                    return IokeObject.isTrue(self.send1(ctx.runtime.isApplicableMessage.?, ctx, pass, arg).?);
                }
            }
        }
        return true;
    }

    pub fn getOrActivate(self: *Self, cell: *Cell, context: *IokeObject, message: *IokeObject, on: *IokeObject) ?*IokeObject {
        var cell_unwrapped = CellHelpers.getObject(cell);
        if (cell_unwrapped != null and self.shouldActivate(cell_unwrapped.?, message)) {
            return self.activate(cell_unwrapped.?, context, message, on);
        } else {
            return null;
        }
    }

    pub fn activate(self: *Self, receiver: *IokeObject, context: *IokeObject, message: *IokeObject, on: *IokeObject) ?*IokeObject {
        return DefaultMethod.activateFixed(receiver, context, message, on);
    }
};
