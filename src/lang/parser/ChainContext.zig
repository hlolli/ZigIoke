const std = @import("std");
const Allocator = std.mem.Allocator;
const BufferedChain = @import("./BufferedChain.zig").BufferedChain;
const Level = @import("./Level.zig").Level;
const Message = @import("../Message.zig").Message;
const IokeData = @import("../IokeData.zig").IokeData;
const IokeDataHelpers = @import("../IokeData.zig").IokeDataHelpers;
const IokeObject = @import("../IokeObject.zig").IokeObject;

pub const ChainContext = struct {
    const Self = @This();
    allocator: *Allocator,
    chains: ?*BufferedChain = null,
    currentLevel: ?*Level = null,
    parent: ?*ChainContext = null,
    last: ?*IokeObject = null,
    head: ?*IokeObject = null,

    pub fn init(self: *Self) void {
        var bufferedChain = self.allocator.create(BufferedChain) catch unreachable;
        bufferedChain.init(self.allocator);
        bufferedChain.* = BufferedChain{};
        self.chains = bufferedChain;
        var currLevel = self.allocator.create(Level) catch unreachable;
        currLevel.* = Level{
            .type = Level.Type.REGULAR,
            .precedence = -1,
        };
        self.currentLevel = currLevel;
    }

    pub fn add(self: *Self, msg: *IokeObject) void {
        if (self.head == null) {
            self.last = msg;
            self.head = msg;
        } else if (self.last != null) {
            self.last.?.data.Message.?.setNext(msg);
            msg.data.Message.?.setNext(msg);
            self.last = msg;
        }
        if (self.currentLevel != null and self.currentLevel.?.type == Level.Type.UNARY) {
            // std.log.info("\n DANGER DANGER \n", .{});
            var poppedVal = self.pop();
            if (poppedVal != null) {
                var argAsData = self.allocator.create(IokeData) catch unreachable;
                argAsData.* = IokeData{.IokeObject = poppedVal};
                self.currentLevel.?.operatorMessage.?.getArguments().?.append(argAsData) catch unreachable;
            }
            self.currentLevel = self.currentLevel.?.parent;
        }
    }

    pub fn push(self: *Self, precedence: i32, op: *IokeObject, levelType: Level.Type) void {
        if (self.currentLevel == null) {
            std.log.info("\n internal-fatal: chain context was uninitialized\n", .{});
            return;
        }
        std.log.info("\n head-3 {*}\n", .{op.runtime});
        var currLevel = self.allocator.create(Level) catch unreachable;
        currLevel.* = Level{
            .type = levelType,
            .precedence = precedence,
            .parent = self.currentLevel,
            .operatorMessage = op,
        };
        self.currentLevel = currLevel;
        // self.currentLevel.?.type = levelType;
        // self.currentLevel.?.precedence = precedence;
        // self.currentLevel.?.parent = self.currentLevel;
        // self.currentLevel.?.operatorMessage = op;
        // = Level{
        //     .type = levelType,
        //     .precedence = precedence,
        //     .parent = &self.currentLevel,
        //     .operatorMessage = op,
        // };
        self.chains.?.parent = self.chains;
        self.chains.?.last = self.last;
        self.chains.?.head = self.head;
        self.last = self.head;
        // if (self.head != null) {
        //     self.head.?.free();
        // }
        self.head = null;
    }

    pub fn pop(self: *Self) ?*IokeObject {
        if (self.head != null) {
            var headMessage = IokeDataHelpers.getMessage(self.head.?.data);
            while (headMessage != null and headMessage.?.isTerminator and headMessage.?.next != null) {
                // head = Message.next(head);
                // Message.setPrev(head, null);
                self.head = headMessage.?.next;
                headMessage.?.setPrev(null);
                if (self.head != null) {
                    headMessage = IokeDataHelpers.getMessage(self.head.?.data);
                }
            }
        }

        // if (self.head != null) {
        //     if () {
        //         self.head = headMessage.?.next;
        //         headMessage.?.setPrev(self.head);
        //         return pop(self);
        //     }
        // }


        // const headToReturn = self.allocator.create(IokeObject) catch unreachable;
        // if (self.head != null) {
        //     headToReturn.* = self.head.?.*;
        // }
        const headToReturn = self.head;

        self.head = self.chains.?.head;
        self.last = self.chains.?.last;
        self.chains = self.chains.?.parent;

        // if (self.chains.?.parent != null) {}

        return headToReturn;
    }

    pub fn popOperatorsTo(self: *Self, precedence: i32) void {
        if (self.currentLevel == null) {
            std.log.info("\n internal-fatal: chain context was uninitialized\n", .{});
            return;
        }

        while ((self.currentLevel.?.precedence != -1 or self.currentLevel.?.type == Level.Type.UNARY) and self.currentLevel.?.precedence <= precedence) {
            std.log.info("popping operators to {}\n", .{precedence});
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

            const op = self.currentLevel.?.operatorMessage;
            const opMessage = if (op != null) IokeDataHelpers.getMessage(op.?.data) else null;

            if (opMessage != null and self.currentLevel.?.type == Level.Type.INVERTED and opMessage.?.prev != null) {
                var opMsgPrev = IokeDataHelpers.getMessage(opMessage.?.prev.?.data);
                if (opMsgPrev == null) {
                    std.log.err("ChainContext.popOperatorsTo failed: missing link\n", .{});
                    return;
                }
                opMsgPrev.?.setNext(null);
                self.head = arg_;
                if (self.head != null) {
                    // opMsgPrev.?.appendArgument(self.head.?);
                    var headMsg = IokeDataHelpers.getMessage(self.head.?.data);
                    headMsg.?.setNextOfLast(op);
                }
                self.last = op;

            } else {
                if (arg_ != null) {
                    var argAsData = self.allocator.create(IokeData) catch unreachable;
                    argAsData.* = IokeData{.IokeObject = arg_};
                    opMessage.?.getArguments().?.append(argAsData) catch unreachable;
                }
            }

            self.currentLevel = self.currentLevel.?.parent;
            // self.popOperatorsTo(precedence);
        }
    }
};

// Tests
const expect = std.testing.expect;

test "ChainContext" {
    var fakeObj: IokeObject = IokeObject{};
    var fakeChain: ChainContext = ChainContext{};
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
