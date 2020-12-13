const std = @import("std");
const Cell = @import("./Cell.zig");
const Interpreter = @import("./Interpreter.zig").Interpreter;
const IokeObject = @import("./IokeObject.zig").IokeObject;
const IokeData = @import("./IokeData.zig").IokeData;
const IokeDataType = @import("./IokeData.zig").IokeDataType;
const IokeDataHelpers = @import("./IokeData.zig").IokeDataHelpers;
const ArgumentsDefinition = @import("./ArgumentsDefinition.zig").ArgumentsDefinition;

pub const DefaultMethod = struct {
    const Self = @This();
    arguments: *ArgumentsDefinition,
    code: *IokeObject,
    method: *IokeObject,

    pub fn init(self: *Self) void {
        self.method.setKind(IokeDataType.DEFAULT_METHOD);
    }

    // receiver, context, message, on
    // @static
    pub fn activateFixed(receiver: *IokeObject, context: *IokeObject, message: *IokeObject, on: *IokeObject) ?*IokeObject {
        std.log.info("activating \n", .{});
        if (IokeDataHelpers.getDefaultMethod(receiver.data) == null) {
            // TODO THROW ERROR
            std.log.err("TODO throw error on NonActivable\n", .{});
            return null;
        }

        var dm = IokeDataHelpers.getDefaultMethod(receiver.data).?;
        var c = context.runtime.locals.?.mimic(message, context);
        c.setCellFromObject("self"[0..], on);
        c.setCellFromObject("@"[0..], on);

        // TODO registerMethod code is missing here!
        c.setCellFromObject("currentMessage", message);
        c.setCellFromObject("surroundingContext", context);
        // TODO
        // c.setCellFromObject("super", createSuperCallFor(self, context, message, on, dm.name));
        // dm.arguments.assignArgumentValues(c, context, message, on);

        return Interpreter.evaluate(dm.code, c, c);
    }
};
