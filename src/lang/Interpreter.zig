const std = @import("std");
// const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const IokeData = @import("./IokeData.zig").IokeData;
const IokeDataHelpers = @import("./IokeData.zig").IokeDataHelpers;
const IokeObject = @import("./IokeObject.zig").IokeObject;
const String = @import("./String.zig").String;

pub const Interpreter = struct {
    const Self = @This();
    // allocator: *Allocator,

    pub fn evaluate(self: *Self, that: *IokeObject, ctx: *IokeObject, ground: *IokeData, receiver: *IokeData) *IokeData {
        std.log.info("\n ground ptr 2 {*}\n", .{that.runtime});
        var current = receiver;
        var lastReal: *IokeObject = that.runtime.*.getNil();
        var m: ?IokeObject = that.*;
        var tmp: ?*IokeObject = null;
        var msg: ?*IokeData = null;
        // std.log.err("M{}\n", .{m});
        while (m != null) {
            msg = m.?.getData();
            if (msg == null or !IokeDataHelpers.isMessage(msg.?)) {
                std.log.err("\nError: not a message (should never happen)!\n {}\n", .{m});
                return ground;
            }
            if (msg != null) {
                tmp = msg.?.*.Message.?.*.cached;
            } else {
                tmp = null;
            }

            if (tmp != null) {
                current = tmp.?;
                lastReal = current;
            } else if (String.equals(msg.?.*.Message.?.*.name, "."[0..])) {
                current = ctx;
            } else if (msg.?.*.Message.?.*.name.len > 0 and
                           msg.?.*.Message.?.*.arguments.items.len == 0 and
                           msg.?.*.Message.?.*.name[0] == ':') {
                // lastReal = msg.cached = current = runtime.getSymbol(name.substring(1));
                current = that.runtime.getSymbol(msg.?.*.Message.?.*.name[1..]);
                msg.?.*.Message.?.*.cached = current;
                lastReal = current;
            }

            if (msg.?.*.Message.?.*.next != null) {
                m = msg.?.*.Message.?.*.next.?.*;
            } else {
                m = null;
            }

        }

        return lastReal;
    }

    fn findCell(self: *Self, message: *IokeObject, ctx: *IokeObject, obj: *IokeObject, name: []const u8, recv: *IokeObject) {
        var runtime = ctx.runtime;
        var cell: *Cell = recv.findCell(name);
        var passed: *Cell = null;
        while(cell == runtime.nul) {
            passed = recv.findCell("pass"[0..]);
            cell =  passed;
            if(passed != runtime.nul and self.isApplicable(passed, message, ctx)) {
                return cell;
            }
            cell = signalNoSuchCell(message, ctx, obj, name, cell, recv);
        }
        return cell;
    }

    pub fn send(self: *Self, obj: *IokeObject, context: *IokeObject, recv: *IokeData, args: ArrayList(*IokeData)) *IokeData {
        Object result;
        if((result = ((Message)self.data).cached) != null) {
            return result;
        }

        IokeObject m = self.allocateCopy(self, context);
        m.getArguments().clear();
        m.getArguments().addAll(args);
        return perform(recv, context, m);
    }

    pub fn perform(self: *Self, obj: *IokeObject, recv: *IokeObject, ctx: *IokeObject, message: *IokeObject, name: []const u8) {
        Object cell = findCell(message, ctx, obj, name, recv);
        return getOrActivate(cell, ctx, message, obj);
    }

    fn isApplicable(self: *Self, pass: *Cell, message: *IokeObject, ctx: *IokeObject) bool {
        if(pass != null and pass != ctx.runtime.nul) {
            var recv = IokeDataHelpers.as(pass, ctx);
            if (recv != null) {
                var applicable_q = recv.?.findCell("applicable?");
                if (applicable_q != ctx.runtime.nul) {
                    var sent = ctx.runtime.isApplicableMessage.send(ctx, pass, ctx.runtime.createMessage(Message.wrap(message)));
                    return sent.isTrue();
                }
            }
        }
        return true;
    }
};
