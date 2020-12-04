const std = @import("std");
const BufferedChain = @import("./BufferedChain.zig").BufferedChain;
const Level = @import("./Level.zig").Level;
const Message = @import("../Message.zig").Message;
const IokeDataHelpers = @import("../IokeData.zig").IokeDataHelpers;
const IokeObject = @import("../IokeObject.zig").IokeObject;

pub const ChainContext = struct {
    const Self = @This();

    chains: BufferedChain = BufferedChain.init(),
    currentLevel: Level = Level{
        .type = Level.Type.REGULAR,
        .precedence = -1,
    },
    parent: ?*ChainContext = null,
    last: ?*IokeObject = null,
    head: ?*IokeObject = null,

    pub fn add(self: *Self, msg: *IokeObject) void {

        if (self.head == null) {
            self.last = msg;
            self.head = msg;
        } else if (self.last != null) {
            self.last.?.data.Message.?.setNext(msg);
            msg.data.Message.?.setNext(msg);
            self.last = msg;
        }
        if (self.currentLevel.type == Level.Type.UNARY) {
            // TODO
            // self.currentLevel.operatorMessage.add(self.pop());
            // currentLevel = currentLevel.parent;
        }
    }

    pub fn push(self: *Self, precedence: i32, op: *IokeObject, levelType: Level.Type) void {
        std.log.info("\n head-3 {*}\n", .{op.runtime});
        self.currentLevel = Level{
            .type = levelType,
            .precedence = precedence,
            .parent = &self.currentLevel,
            .operatorMessage = op,
        };
        self.chains = BufferedChain{
            .parent = &self.chains,
            .last = self.last,
            .head = self.head,
        };
        self.last = self.head;
        self.head = null;
    }

    pub fn pop(self: *Self) ?*IokeObject {
        if (self.head != null) {
            const headMessage = IokeDataHelpers.getMessage(self.head.?.data);
            if (headMessage != null and headMessage.?.isTerminator and headMessage.?.next != null) {
                headMessage.?.setPrev(self.head);
                return self.pop();
            }
        }

        const headToReturn = self.head;

        if (headToReturn != null) {
            headToReturn.?.runtime.* = self.head.?.runtime.*;
            std.log.info("\n head-1 {*}\n", .{headToReturn.?.runtime});
            std.log.info("\n head-2 {*}\n", .{self.head.?.runtime});
        }

        self.head = if (self.chains.head != null) self.chains.head.? else null;
        self.last = if (self.chains.last != null) self.chains.last.? else null;
        if (self.chains.parent != null) {
            self.chains = self.chains.parent.?.*;
        }
        return headToReturn;
    }

    pub fn popOperatorsTo(self: *Self, precedence: i32) void {
        if((self.currentLevel.precedence != -1
                or self.currentLevel.type == Level.Type.UNARY)
                  and self.currentLevel.precedence <= precedence) {
            const arg = self.pop();
            if (arg == null) {
                std.log.err("ChainContext.popOperatorsTo failed\n", .{});
                return;
            }
            const currentMessage = IokeDataHelpers.getMessage(arg.?.data);

            if (currentMessage == null) {
                std.log.err("ChainContext.popOperatorsTo failed: empty data\n", .{});
                return;
            }

            const isTerminator: bool = currentMessage.?.isTerminator;
            const nextMsg = currentMessage.?.next;
            const arg_ = if (arg != null and isTerminator and nextMsg == null) null else arg;

            const op = self.currentLevel.operatorMessage;
            const opMessage = if(op != null) IokeDataHelpers.getMessage(op.?.data) else null;

            if (opMessage != null and self.currentLevel.type == Level.Type.INVERTED and opMessage.?.prev != null) {

                var opMsgPrev = IokeDataHelpers.getMessage(opMessage.?.prev.?.data);
                if (opMsgPrev == null) {
                    std.log.err("ChainContext.popOperatorsTo failed: missing link\n", .{});
                    return;
                }
                opMsgPrev.?.*.setNext(null);
                if (self.head != null) {
                    opMsgPrev.?.appendArgument(self.head.?);
                }
                self.head = arg_;
            }
            self.popOperatorsTo(precedence);
        }
    }
};

// Tests
const expect = std.testing.expect;

test "ChainContext" {
    var fakeObj: IokeObject = IokeObject {};
    var fakeChain: ChainContext = ChainContext {};
    // silly but I dont get logs printer otherwise
    var ret1 = fakeChain.add(&fakeObj);
    var ret2 = fakeChain.add(&fakeObj);
    expect(@TypeOf(ret1) == void);
    expect(@TypeOf(ret2) == void);
    expect(fakeChain.head != null);
    expect(fakeChain.last != null);
    var ret3 = fakeChain.pop();
    // std.log.err("RET {}\n", .{ret3});
}
