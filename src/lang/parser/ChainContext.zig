const std = @import("std");
const Message = @import("@ioke/message").Message;
const IokeObject = @import("@ioke/ioke_object").IokeObject;
const BufferedChain = @import("./BufferedChain.zig").BufferedChain;
const Level = @import("./Level.zig").Level;

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
        // std.log.err("EMMESSGJE {} \n", .{msg});
        if (self.head == null) {
            self.last = msg;
            self.head = msg;
        } else if (self.last != null) {
            Message.setNextStatic(
                self.last.?,
                msg
            );
            Message.setPrevStatic(
                msg,
                self.last.?
            );
            self.last = msg;
        }
        if (self.currentLevel.type == Level.Type.UNARY) {
            // TODO
            // self.currentLevel.operatorMessage.add(self.pop());
            // currentLevel = currentLevel.parent;
        }
    }

    pub fn push(self: *Self, precedence: i32, op: *IokeObject, levelType: Level.Type) void {
        self.currentLevel = Level{
            .type = levelType,
            .precedence = precedence,
            .parent = &self.currentLevel,
            .operatorMessage = op.*,
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
        if(self.head != null) {
            while(
                Message.isTerminatorStatic(self.head.?) and
                    Message.getNextStatic(self.head.?) != null
            ) {
                // std.log.err("POP! \n", .{});
                self.head = Message.getNextStatic(self.head.?);
                Message.setPrevStatic(self.head.?, self.head.?);
                if (self.head == null) {
                    break;
                }
            }
        }

        var headToReturn = self.head;
        self.head = if (self.chains.head != null) self.chains.head.? else null;
        self.last = if (self.chains.last != null) self.chains.last.? else null;
        if (self.chains.parent != null) {
            self.chains = self.chains.parent.?.*;
        }
        return headToReturn;
    }

    pub fn popOperatorsTo(self: *Self, precedence: i32) void {
        while((self.currentLevel.precedence != -1
                   or self.currentLevel.type == Level.Type.UNARY)
                  and self.currentLevel.precedence <= precedence) {
            // std.log.err("popOOT \n", .{});
            var arg = self.pop();
            var isTerminator: bool = Message.isTerminatorStatic(arg.?);
            var nextMsg = Message.getNextStatic(arg.?);
            if (arg != null and isTerminator and nextMsg == null) {
                arg = null;
            }
            var op: ?IokeObject = self.currentLevel.operatorMessage;

            if (op != null and self.currentLevel.type == Level.Type.INVERTED and Message.prevStatic(&op.?) != null) {
                var prev = Message.prevStatic(&op.?);
                if (prev != null) {
                    Message.setNextStatic(prev.?, null);
                }

            }
            // IokeObject op = currentLevel.operatorMessage;
            // if(currentLevel.type == Level.Type.INVERTED && Message.prev(op) != null) {
            //     Message.setNext(Message.prev(op), null);
            //     op.getArguments().add(head);
            //     head = arg;
            //     Message.setNextOfLast(head, op);
            //     last = op;
            // } else {
            //     if(arg != null) {
            //         op.getArguments().add(arg);
            //     }
            // }
            // currentLevel = currentLevel.parent;
        }
    }
    // std.math.maxInt(u32);

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
