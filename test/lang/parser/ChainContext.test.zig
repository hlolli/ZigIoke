// Tests
usingnamespace @import("std.testing");
// const expect = std.testing.expect;

test "ChainContext" {
    var fakeObj: IokeObject = IokeObject {};
    var fakeChain: ChainContext = ChainContext {};

    expect(@TypeOf(fakeChain.add(fakeObj)) == void);
}
