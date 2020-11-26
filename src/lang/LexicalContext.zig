const std = @import("std");
const IokeData = @import("./IokeData.zig").IokeData;
const IokeObject = @import("./IokeObject.zig").IokeObject;

pub const LexicalContext = struct {
    const Self = @This();
    // pass ground to the struct like this:
    // ground = IokeObject.getRealContext(ground);
    ground: *IokeData,
    surroundingContext: *IokeObject,
};
