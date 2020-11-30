// DELETEME!!
// const std = @import("std");
// const IokeData = @import("./IokeData.zig").IokeData;
// const IokeDataHelpers = @import("./IokeData.zig").IokeDataHelpers;
// const IokeObject = @import("./IokeObject.zig").IokeObject;
// const Runtime = @import("./Runtime.zig").Runtime;
// pub const IokeRegistry = struct {
//     const Self = @This();
//     runtime: *Runtime,
//     pub fn wrap(self: *Self, on: ?*IokeData) *const IokeObject {
//         if (on == null) {
//             return self.runtime.nil.?;
//         } else if(IokeDataHelpers.isBoolean(on.?)) {
//             return ((Boolean)on).booleanValue() ? runtime._true : runtime._false;
//         }
//         if(!wrappedObjects.containsKey(on)) {
//             IokeObject val = runtime.createJavaWrapper(on);
//             wrappedObjects.put(on, val);
//             return val;
//         }
//         return wrappedObjects.get(on);
//     }
// }
