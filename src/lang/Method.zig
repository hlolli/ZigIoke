const ArgumentsDefinition = @import("./ArgumentsDefinition.zig").ArgumentsDefinition;
const IokeData = @import("./IokeData.zig").IokeData;
const IokeObject = @import("./IokeObject.zig").IokeObject;

// pub const MethodTag = enum {};

// pub const Method = union(MethodTag) {};

pub const Method = struct {
    const Self = @This();
    arguments: *ArgumentsDefinition,
    code: *IokeObject,
    method: *IokeObject,

    pub fn init(self: *Self) void {
        self.method.setKind("Method");
    }

    pub fn activateFixed(self: *IokeObject, context: *IokeObject, message: *IokeObject, on: *IokeData) *IokeObject {
        var names = [_][]const u8{
            "Error",
            "Invocation",
            "NotActivatable",
        };
        context.runtime.condition.getCellChain(message, names);
        // TODO FIXME!!
        return self;

        // IokeObject condition = IokeObject.as(IokeObject.getCellChain(context.runtime.condition,
        //                                                              message,
        //                                                              context,
        //                                                              "Error",
        //                                                              "Invocation",
        //                                                              "NotActivatable"), context).mimic(message, context);
        // condition.setCell("message", message);
        // condition.setCell("context", context);
        // condition.setCell("receiver", on);
        // condition.setCell("method", self);
        // condition.setCell("reportMsg", context.runtime.newText("You tried to activate a method (" + ((Method)self.data).name +") without any code - did you by any chance activate the Method kind by referring to it without wrapping it inside a call to cell?"));
        // context.runtime.errorCondition(condition);

        // return self.runtime.nil;
    }
};
