const std = @import("std");
const Allocator = std.mem.Allocator;
const StringIterator = std.unicode.Utf8Iterator;
const IokeData = @import("./IokeData.zig").IokeData;
const IokeIO = @import("./IokeIO.zig").IokeIO;
const IokeObjectNS = @import("./IokeObject.zig");
const IokeObject = @import("./IokeObject.zig").IokeObject;
const Body = @import("./Body.zig").Body;
const Message = @import("./Message.zig").Message;
const Text = @import("./Text.zig").Text;

pub var nextId: u32 = 1;

pub fn getNextId_() u32 {
    const ret: u32 = nextId;
    nextId += 1;
    return ret;
}

fn nilToString(self: *IokeObject) []const u8 {
    return "nil"[0..];
}

fn trueToString(self: *IokeObject) []const u8 {
    return "true"[0..];
}

fn falseToString(self: *IokeObject) []const u8 {
    return "false"[0..];
}

pub const Runtime = struct {
    const Self = @This();
    pub const id = getNextId_();

    nul: ?IokeObject = null,

    allocator: *Allocator,


    base: ?IokeObject = null,
    iokeGround: ?IokeObject = null,
    ground: ?IokeObject = null,
    system: ?IokeObject = null,
    runtime: ?IokeObject = null,
    defaultBehavior: ?IokeObject = null,
    origin: ?IokeObject = null,
    nil: ?IokeObject = null,
    _true: ?IokeObject = null,
    _false: ?IokeObject = null,
    text: ?IokeObject = null,
    symbol: ?IokeObject = null,
    number: ?IokeObject = null,
    method: ?IokeObject = null,
    defaultMethod: ?IokeObject = null,
    nativeMethod: ?IokeObject = null,
    lexicalBlock: ?IokeObject = null,
    defaultMacro: ?IokeObject = null,
    lexicalMacro: ?IokeObject = null,
    defaultSyntax: ?IokeObject = null,
    arity: ?IokeObject = null,
    mixins: ?IokeObject = null,
    message: ?IokeObject = null,
    restart: ?IokeObject = null,
    list: ?IokeObject = null,
    dict: ?IokeObject = null,
    set: ?IokeObject = null,
    range: ?IokeObject = null,
    pair: ?IokeObject = null,
    tuple: ?IokeObject = null,
    call: ?IokeObject = null,
    lexicalContext: ?IokeObject = null,
    dateTime: ?IokeObject = null,
    locals: ?IokeObject = null,
    condition: ?IokeObject = null,
    rescue: ?IokeObject = null,
    handler: ?IokeObject = null,
    io: ?IokeObject = null,
    fileSystem: ?IokeObject = null,
    regexp: ?IokeObject = null,
    sequence: ?IokeObject = null,
    iteratorSequence: ?IokeObject = null,
    keyValueIteratorSequence: ?IokeObject = null,
    integer: ?IokeObject = null,
    decimal: ?IokeObject = null,
    ratio: ?IokeObject = null,
    infinity: ?IokeObject = null,

    // Core messages
    asText: ?IokeObject = null,
    asRational: ?IokeObject = null,
    asDecimal: ?IokeObject = null,
    asSymbol: ?IokeObject = null,
    asTuple: ?IokeObject = null,
    mimic: ?IokeObject = null,
    spaceShip: ?IokeObject = null,
    succ: ?IokeObject = null,
    pred: ?IokeObject = null,
    setValue: ?IokeObject = null,
    nilMessage: ?IokeObject = null,
    name: ?IokeObject = null,
    callMessage: ?IokeObject = null,
    closeMessage: ?IokeObject = null,
    code: ?IokeObject = null,
    each: ?IokeObject = null,
    textMessage: ?IokeObject = null,
    conditionsMessage: ?IokeObject = null,
    handlerMessage: ?IokeObject = null,
    reportMessage: ?IokeObject = null,
    printMessage: ?IokeObject = null,
    printlnMessage: ?IokeObject = null,
    outMessage: ?IokeObject = null,
    currentDebuggerMessage: ?IokeObject = null,
    invokeMessage: ?IokeObject = null,
    errorMessage: ?IokeObject = null,
    ErrorMessage: ?IokeObject = null,
    FileMessage: ?IokeObject = null,
    inspectMessage: ?IokeObject = null,
    noticeMessage: ?IokeObject = null,
    removeCellMessage: ?IokeObject = null,
    plusMessage: ?IokeObject = null,
    minusMessage: ?IokeObject = null,
    multMessage: ?IokeObject = null,
    divMessage: ?IokeObject = null,
    modMessage: ?IokeObject = null,
    expMessage: ?IokeObject = null,
    binAndMessage: ?IokeObject = null,
    binOrMessage: ?IokeObject = null,
    binXorMessage: ?IokeObject = null,
    lshMessage: ?IokeObject = null,
    rshMessage: ?IokeObject = null,
    ltMessage: ?IokeObject = null,
    lteMessage: ?IokeObject = null,
    gtMessage: ?IokeObject = null,
    gteMessage: ?IokeObject = null,
    eqMessage: ?IokeObject = null,
    eqqMessage: ?IokeObject = null,
    testMessage: ?IokeObject = null,
    isApplicableMessage: ?IokeObject = null,
    useWhatMessage: ?IokeObject = null,
    cellAddedMessage: ?IokeObject = null,
    cellChangedMessage: ?IokeObject = null,
    cellRemovedMessage: ?IokeObject = null,
    cellUndefinedMessage: ?IokeObject = null,
    mimicAddedMessage: ?IokeObject = null,
    mimicRemovedMessage: ?IokeObject = null,
    mimicsChangedMessage: ?IokeObject = null,
    mimickedMessage: ?IokeObject = null,
    seqMessage: ?IokeObject = null,
    hashMessage: ?IokeObject = null,
    nextPMessage: ?IokeObject = null,
    nextMessage: ?IokeObject = null,
    kindMessage: ?IokeObject = null,

    pub fn getNextId() u32 {
        return getNextId_();
    }

    pub fn newMessage(self: *Self, name: []u8) IokeObject {
        var newMsg = Message{.runtime = self, .name = name};
        return createMessage(&newMsg);
    }

    pub fn createMessage(self: *Self, m: *Message) IokeObject {
        var objCopy: IokeObject = self.message.?;
        var iokeData: IokeData = IokeData{
            .Message = m
        };
        objCopy.singleMimicsWithoutCheck(&self.message.?);
        objCopy.setData(&iokeData);
        return objCopy;
    }

    pub fn newText(self: *Self, text_: []const u8) *IokeObject {
        var obj: IokeObject = self.text.?;
        obj.singleMimicsWithoutCheck(&self.text.?);
        var newText_ = Text{.text = text_};
        var newData_ = IokeData {.Text = &newText_};
        obj.setData(&newData_);
        return &obj;
    }

    // TODO: missing context: IokeObject
    pub fn parseStream(self: *Self, reader: StringIterator) IokeObject {
        return Message.newFromStreamStatic(self, reader);
    }


    pub fn init(self: *Self) void {

        self.nul = IokeObject{
            .runtime = self,
            .documentation = "NOT TO BE EXPOSED TO Ioke - used for internal usage only",
        };
        self.nul.?.init();
        defer self.nul.?.deinit();

        var messageMsg: Message = Message{
            .runtime = self,
            .name = ""[0..]
        };

        var messageData: IokeData = IokeData{
            .Message = &messageMsg
        };

        self.message = IokeObject{
            .runtime = self,
            .documentation = "A Message is the basic code unit in Ioke."[0..],
            .data = &messageData,
        };
        self.message.?.init();
        defer self.message.?.deinit();

        self.base = IokeObject{
            .runtime = self,
            .documentation = (
                "Base is the top of the inheritance structure. " ++
                    "Most of the objects in the system are derived from this instance. " ++
                    "Base should keep its cells to the bare minimum needed for the system.")[0..],
        };
        self.base.?.init();
        defer self.base.?.deinit();

        self.iokeGround = IokeObject{
            .runtime = self,
            .documentation = "IokeGround is the place that mimics default behavior, and where most global objects are defined.."[0..],
        };
        self.iokeGround.?.init();
        defer self.iokeGround.?.deinit();

        self.ground = IokeObject{
            .runtime = self,
            .documentation = "Ground is the default place code is evaluated in."[0..],
        };
        self.ground.?.init();
        defer self.ground.?.deinit();

        // TODO missing IokeSystem in .data
        self.system = IokeObject{
            .runtime = self,
            .documentation = "System defines things that represents the currently running system, such as the load path."[0..],
        };
        self.system.?.init();
        defer self.system.?.deinit();

        var runtimeData: IokeData = IokeData{
            .Runtime = self
        };

        self.runtime = IokeObject{
            .runtime = self,
            .documentation = "Runtime gives meta-circular access to the currently executing Ioke runtime."[0..],
            .data = &runtimeData,
        };
        self.runtime.?.init();
        defer self.runtime.?.deinit();

        self.defaultBehavior = IokeObject{
            .runtime = self,
            .documentation = "DefaultBehavior is a mixin that provides most of the methods shared by most instances in the system."[0..],
        };
        self.defaultBehavior.?.init();
        defer self.defaultBehavior.?.deinit();

        self.origin = IokeObject{
            .runtime = self,
            .documentation = "Any object created from scratch should usually be derived from Origin."[0..],
        };
        self.origin.?.init();
        defer self.origin.?.deinit();

        var _textObj = Text{.text = ""[0..]};
        var _textData = IokeData {.Text = &_textObj};

        self.text = IokeObject{
            .runtime = self,
            .documentation = "Contains an immutable piece of text."[0..],
            .data = &_textData,
        };
        self.text.?.init();
        defer self.text.?.deinit();

        var nilBody = Body{
            .allocator = self.allocator,
            .flags = IokeObjectNS.NIL_F | IokeObjectNS.FALSY_F,
        };

        var nilObj = IokeObject{
            .runtime = self,
            .body = &nilBody,
            .toString = nilToString,
        };
        nilObj.init();
        defer nilObj.deinit();
        nilObj.setKind("nil");

        var nilData = IokeData{
            .IokeObject = &nilObj,
        };

        self.nil = IokeObject{
            .runtime = self,
            .documentation = "nil is an oddball object that always represents itself. It can not be mimicked and (alongside false) is one of the two false values."[0..],
            .data = &nilData,
        };
        self.nil.?.init();
        defer self.nil.?.deinit();


        var _trueObj = IokeObject{
            .runtime = self,
            .toString = trueToString,
        };
        _trueObj.init();
        defer _trueObj.deinit();
        _trueObj.setKind("true");

        var _trueData = IokeData{
            .IokeObject = &_trueObj,
        };

        self._true = IokeObject{
            .runtime = self,
            .documentation = "true is an oddball object that always represents itself. It can not be mimicked and represents the a true value."[0..],
            .data = &_trueData,
        };
        self._true.?.init();
        defer self._true.?.deinit();

        var _falseBody = Body{
            .allocator = self.allocator,
            .flags = IokeObjectNS.FALSY_F,
        };

        var _falseObj = IokeObject{
            .body = &_falseBody,
            .runtime = self,
            .toString = falseToString,
        };
        _falseObj.init();
        defer _falseObj.deinit();
        _falseObj.setKind("false");

        var _falseData = IokeData{
            .IokeObject = &_falseObj,
        };

        self._false = IokeObject{
            .runtime = self,
            .documentation = "false is an oddball object that always represents itself. It can not be mimicked and (alongside nil) is one of the two false values."[0..],
            .data = &_falseData,
        };
        self._false.?.init();
        defer self._false.?.deinit();


    }

    // pub fn newStatic() { }
};
