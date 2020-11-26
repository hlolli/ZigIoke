// const IokeObject = @import("@ioke/ioke_object").IokeObject;
const IokeObject = @import("../IokeObject.zig").IokeObject;

pub const BufferedChain = struct {
    parent: ?*BufferedChain,
    last: ?*IokeObject,
    head: ?*IokeObject,

    pub fn init() BufferedChain {
        return BufferedChain{
            .parent = null,
            .last = null,
            .head = null
        };
    }
};
