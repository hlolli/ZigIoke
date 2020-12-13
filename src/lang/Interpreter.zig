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
    // const Self = @This();

    // @static
    pub fn evaluate(that: *IokeObject, ctx: *IokeObject, receiver: *IokeObject) *IokeObject {
        var lastReal: *IokeObject = ctx.runtime.getNil();
        var current: ?*IokeObject = receiver;
        var m: ?*IokeObject = that;
        while (m != null) {
            var msg = IokeDataHelpers.getMessage(m.?.data);
            var tmp = if (msg != null) msg.?.cached else null;

            if (tmp != null) {
                current = tmp;
                lastReal = current.?;
            } else if (msg != null and String.equals(msg.?.name, "."[0..])) {
                current = ctx;
            } else if (msg != null and msg.?.name.len > 0 and msg.?.arguments != null and msg.?.arguments.?.items.len == 0 and msg.?.name[0] == ':') {
                current = that.runtime.getSymbol(msg.?.name[1..]);
                msg.?.cached = current;
                lastReal = current.?;
            } else {
                const recv = current.?;
                tmp = Interpreter.perform5(recv, recv, ctx, m.?, msg.?.name);
                current = tmp;
                lastReal = current.?;
                std.log.info("\n emmmm {} \n", .{tmp.?.data});
            }
            m = msg.?.getNext();
        }
        return lastReal;
    }

    // pub fn evaluate(self: *Self, message: *IokeObject, ctx: *IokeObject, receiver: *IokeObject, lastReal_: ?*IokeObject) *IokeObject {
    //     var lastReal: *IokeObject = if (lastReal_ == null) ctx.runtime.getNil() else lastReal_.?;
    //     // if (message != null) {
    //     //     std.log.info("\n message.data {}\n", .{
    //     //         // String.equals(message.?.data.Message.?.name, "."[0..])
    //     //         message.?.data.Message.?.name
    //     //     });
    //     // }
    //     // std.log.info("\n lastReadl {}\n", .{lastReal.data});
    //     if (!IokeDataHelpers.isMessage(message.data)) {
    //         std.log.info("DIDNT EVEN TRY :( {*}\n", .{message});
    //         return lastReal;
    //     }

    //     var maybeCached = message.data.Message.?.cached;

    //     if (maybeCached != null) {
    //         var unwrapped = IokeDataHelpers.getObject(maybeCached.?);
    //         if (unwrapped == null) {
    //             std.log.err("Something went wrong in evaluation.\n", .{});
    //             return lastReal;
    //         } else {
    //             return self.evaluate(message.next, unwrapped.?, unwrapped.?, unwrapped.?);
    //         }
    //     } else if (String.equals(message.data.Message.?.name, "."[0..])) {
    //         return self.evaluate(message.next, ctx, ctx, lastReal);
    //     } else if (message.data.Message.?.name.len > 0 and
    //                    (message.data.Message.?.arguments == null or
    //                         message.data.Message.?.arguments.?.items.len == 0) and
    //                    message.data.Message.?.name[0] == ':')
    //         {
    //             var lastRealObj = message.runtime.getSymbol(message.?.data.Message.?.name[1..]);

    //             return self.evaluate(message.next, ctx, lastRealObj, lastRealObj);
    //     } else {
    //             var perf_ret_ = self.perform5(receiver, receiver, ctx, message, message.data.Message.?.name);
    //             if (perf_ret_ == null) {
    //                 std.log.err("Something went wrong in evaluation.\n", .{});
    //                 return lastReal;
    //             } else {
    //                 return self.evaluate(message.next, ctx, perf_ret_.?, perf_ret_.?);
    //             }
    //     }
    // }

    fn shouldActivate(obj: *IokeObject, message: *IokeObject) bool {
        return obj.isActivatable() or
            ((IokeDataHelpers.isAssociatedCode(obj.data)) and message.getArguments().?.items.len > 0);
    }

    fn findCell(message: *IokeObject, ctx: *IokeObject, obj: *IokeObject, name: []const u8, recv: *IokeObject) ?*Cell {
        var runtime = ctx.runtime;
        var cell = recv.findCell(name);
        // std.log.err("work work {}\n", .{cell});
        // var passed: ?*Cell = null;
        if (cell != null) {
            while (cell.?.value == null and IokeDataHelpers.isNul(cell.?.value.?, message.runtime)) {
                var passed = recv.findCell("pass"[0..]);
                cell = passed;
                if (passed != null and
                        passed.?.value != null and
                        passed.?.value.? != runtime.nul.?.data and
                        Interpreter.isApplicable(passed.?.value.?, message, ctx))
                    {
                        return cell;
                }
                // FIXME!
                // cell = signalNoSuchCell(message, ctx, obj, name, cell, recv);
            }
        }
        return cell;
    }

    pub fn send0(message: *IokeObject, context: *IokeObject, recv: *IokeData) ?*IokeObject {
        if (message.data != null and IokeDataHelpers.isMessage(message.data) and message.data.Message.cached != null) {
            return message.data.Message.cached.?;
        } else {
            return Interpreter.perform4(recv, context, message);
        }
    }

    pub fn send1(message: *IokeObject, context: *IokeObject, recv: *IokeData, argument: *IokeData) ?*IokeObject {
        if (IokeDataHelpers.isMessage(message.data) and message.data.Message.?.cached != null) {
            return message.data.Message.?.cached;
        } else {
            var m = message.allocateCopy(message, context);
            m.singleMimicsWithoutCheck(context.runtime.message.?);
            // TODO arguments
            // m.Arguments.Clear();
            // m.Arguments.Add(argument);
            return Interpreter.perform4(recv, context, message);
        }
    }

    pub fn sendAll(obj: *IokeData, context: *IokeObject, recv: *IokeData, args: *ArrayList(IokeData)) ?*IokeObject {
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
        return Interpreter.perform4(cell, obj, recv, context, m);
    }

    // since there's no wrap, refer to c#'s implementation for reference
    pub fn perform4(obj: *IokeData, ctx: *IokeObject, message: *IokeObject) ?*IokeObject {
        var recv = IokeDataHelpers.as(obj, ctx);
        var msg = IokeDataHelpers.getMessage(message.data);
        var name = if (msg != null) msg.?.name else ""[0..];
        return Interpreter.perform5(recv.?, recv.?, ctx, message, name);
    }

    pub fn perform5(obj: *IokeObject, recv: *IokeObject, ctx: *IokeObject, message: *IokeObject, name: []const u8) ?*IokeObject {
        var cell = Interpreter.findCell(message, ctx, obj, name, recv);
        std.log.info("\n foundCell {}\n", .{cell});
        if (cell == null) {
            return ctx.runtime.nul.?;
        } else {
            return Interpreter.getOrActivate(cell.?, ctx, message, obj);
        }
    }

    fn isApplicable(pass: *IokeData, message: *IokeObject, ctx: *IokeObject) bool {
        if (pass != ctx.runtime.nul.?.data) {
            var recv = IokeDataHelpers.as(pass, ctx);
            if (recv != null) {
                var applicable_q = recv.?.findCell("applicable?");
                if (applicable_q != null and applicable_q.?.value != null and applicable_q.?.value.? != ctx.runtime.nul.?.data) {
                    // var applicableMsgDataAsMsg = IokeData{.IokeObject = ctx.runtime.isApplicableMessage.?};
                    var arg = ctx.runtime.createMessage(Message.wrap1(message)).data;
                    // self: *Self, message: *IokeObject, context: *IokeObject, recv: *IokeData, argument: *IokeData
                    // TODO error check the null below
                    return IokeObject.isTrue(Interpreter.send1(ctx.runtime.isApplicableMessage.?, ctx, pass, arg).?);
                }
            }
        }
        return true;
    }

    pub fn getOrActivate(cell: *Cell, context: *IokeObject, message: *IokeObject, on: *IokeObject) ?*IokeObject {
        var cell_unwrapped = CellHelpers.getObject(cell);
        std.log.info("\n cell_unwrapped {}\n", .{cell_unwrapped});
        if (cell_unwrapped != null and Interpreter.shouldActivate(cell_unwrapped.?, message)) {
            return Interpreter.activate(cell_unwrapped.?, context, message, on);
        } else {
            return null;
        }
    }

    pub fn activate(receiver: *IokeObject, context: *IokeObject, message: *IokeObject, on: *IokeObject) ?*IokeObject {
        return DefaultMethod.activateFixed(receiver, context, message, on);
    }
};
