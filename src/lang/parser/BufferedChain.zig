const IokeObject = @import("@ioke/ioke_object").IokeObject;

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
