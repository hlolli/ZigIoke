const std = @import("std");
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const StringIterator = std.unicode.Utf8Iterator;
const Interpreter = @import("./Interpreter.zig").Interpreter;
const IokeData = @import("./IokeData.zig").IokeData;
const IokeIO = @import("./IokeIO.zig").IokeIO;
const IokeObjectNS = @import("./IokeObject.zig");
const IokeObject = @import("./IokeObject.zig").IokeObject;
const LexicalContext = @import("./LexicalContext.zig").LexicalContext;
const Body = @import("./Body.zig").Body;
const Message = @import("./Message.zig").Message;
const Symbol = @import("./Symbol.zig").Symbol;
const Text = @import("./Text.zig").Text;

pub var nextId: u32 = 1;

pub fn getNextId_() u32 {
    const ret: u32 = nextId;
    nextId += 1;
    return ret;
}

pub const Runtime = struct {
    const Self = @This();
    pub const id = getNextId_();
    symbolTable: ?AutoHashMap([]const u8, IokeObject) = null,

    nul: ?IokeObject = null,

    allocator: *Allocator,
    interpreter: *Interpreter,

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

    pub fn getNil(self: *Self) *IokeObject {
        std.log.info("\n nil self {*}\n", .{self});
        return &self.nil.?;
    }

    pub fn newMessage(self: *Self, name: []u8) IokeObject {
        var newMsg = Message{.runtime = self, .name = name};
        return createMessage(&newMsg);
    }

    pub fn createMessage(self: *Self, m: *Message) *IokeObject {
        var objCopy: IokeObject = self.message.?;
        objCopy.init();
        var iokeData: IokeData = IokeData{
            .Message = m
        };
        objCopy.singleMimicsWithoutCheck(&self.message.?);
        objCopy.setData(&iokeData);
        return &objCopy;
    }

    pub fn newText(self: *Self, text_: []const u8) *IokeObject {
        var obj: IokeObject = self.text.?;
        obj.init();
        obj.singleMimicsWithoutCheck(&self.text.?);
        var newText_ = Text{.text = text_};
        var newData_ = IokeData {.Text = &newText_};
        obj.setData(&newData_);
        return &obj;
    }

    pub fn parseStream(self: *Self, reader: StringIterator, message: *IokeObject, context: *IokeObject) *IokeObject {
        return Message.newFromStreamStatic(self, reader, message, context);
    }

    pub fn evaluateStream(self: *Self, reader: StringIterator, message: *IokeObject, context: *IokeObject) *IokeObject {
        var parsedObj = self.parseStream(reader, message, context);
        return self.interpreter.*.evaluate(parsedObj, &self.ground.?, &self.ground.?, &self.ground.?);
    }


    pub fn getSymbol(self: *Self, name_: []const u8) *IokeObject {
        var maybeSymbol = self.symbolTable.?.get(name_);
        if (maybeSymbol == null) {
            var _symbolObj = Symbol{.text = name_};
            var _symbolData = IokeData {.Symbol = &_symbolObj};
            maybeSymbol = IokeObject{
                .runtime = self,
                .data = &_symbolData,
            };
            maybeSymbol.?.init();
            maybeSymbol.?.singleMimicsWithoutCheck(&self.symbol.?);
            self.symbolTable.?.put(name_, maybeSymbol.?) catch unreachable;
        }
        return &maybeSymbol.?;
    }

    pub fn deinit(self: *Self) void {

        if (self.symbolTable != null) {
            self.symbolTable.?.deinit();
            self.symbolTable = null;
        }

        if (self.nul != null and !self.nul.?.deinitialized) {
            self.nul.?.deinit();
            self.nul = null;
        }

        if (self.message != null and !self.message.?.deinitialized) {
            self.message.?.deinit();
            self.message = null;
        }

        if (self.base != null and !self.base.?.deinitialized) {
            self.base.?.deinit();
            self.base = null;
        }

        if (self.iokeGround != null and !self.iokeGround.?.deinitialized) {
            self.iokeGround.?.deinit();
            self.iokeGround = null;
        }

        if (self.ground != null and !self.ground.?.deinitialized) {
            self.ground.?.deinit();
            self.ground = null;
        }

        if (self.system != null and !self.system.?.deinitialized) {
            self.system.?.deinit();
            self.system = null;
        }

        if (self.runtime != null and !self.runtime.?.deinitialized) {
            self.runtime.?.deinit();
            self.runtime = null;
        }

        if (self.defaultBehavior != null and !self.defaultBehavior.?.deinitialized) {
            self.defaultBehavior.?.deinit();
            self.defaultBehavior = null;
        }

        if (self.origin != null and !self.origin.?.deinitialized) {
            self.origin.?.deinit();
            self.origin = null;
        }

        if (self.text != null and !self.text.?.deinitialized) {
            self.text.?.deinit();
            self.text = null;
        }

        if (self.nil != null and !self.nil.?.deinitialized) {
            self.nil.?.deinit();
            self.nil = null;
        }

        if (self._true != null and !self._true.?.deinitialized) {
            self._true.?.deinit();
            self._true = null;
        }

        if (self._false != null and !self._false.?.deinitialized) {
            self._false.?.deinit();
            self._false = null;
        }

        // defer nilObj.deinit();
        // defer _trueObj.deinit();
        // defer _falseObj.deinit();
    }

    pub fn init(self: *Self) void {
        self.symbolTable = AutoHashMap([]const u8, IokeObject).init(self.allocator);

        self.nul = IokeObject{
            .runtime = self,
            .documentation = "NOT TO BE EXPOSED TO Ioke - used for internal usage only",
        };
        self.nul.?.init();

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

        self.base = IokeObject{
            .runtime = self,
            .documentation = (
                "Base is the top of the inheritance structure. " ++
                    "Most of the objects in the system are derived from this instance. " ++
                    "Base should keep its cells to the bare minimum needed for the system.")[0..],
        };
        self.base.?.init();


        self.iokeGround = IokeObject{
            .runtime = self,
            .documentation = "IokeGround is the place that mimics default behavior, and where most global objects are defined.."[0..],
        };
        self.iokeGround.?.init();


        self.ground = IokeObject{
            .runtime = self,
            .documentation = "Ground is the default place code is evaluated in."[0..],
        };
        self.ground.?.init();

        // TODO missing IokeSystem in .data
        self.system = IokeObject{
            .runtime = self,
            .documentation = "System defines things that represents the currently running system, such as the load path."[0..],
        };
        self.system.?.init();

        // nil needs to be initialized before text
        var nilBody = Body{
            .allocator = self.allocator,
            .flags = IokeObjectNS.NIL_F | IokeObjectNS.FALSY_F,
        };

        var nilObj = IokeObject{
            .runtime = self,
            .body = &nilBody,
            .toString = "nil"[0..],
        };
        nilObj.init();

        std.log.info("\n ground ptr {*}\n", .{self.ground.?.runtime});
        var nilData = IokeData{
            .IokeObject = &nilObj,
        };

        self.nil = IokeObject{
            .runtime = self,
            .documentation = "nil is an oddball object that always represents itself. It can not be mimicked and (alongside false) is one of the two false values."[0..],
            .data = &nilData,
        };
        self.nil.?.init();

        // Needs to be initialized early for
        // setKind to work without null checks
        var _textObj = Text{.text = ""[0..]};
        var _textData = IokeData {.Text = &_textObj};

        self.text = IokeObject{
            .runtime = self,
            .documentation = "Contains an immutable piece of text."[0..],
            .data = &_textData,
        };
        self.text.?.init();

        // setKind can be called now
        var nilKindStr = "nil"[0..];
        nilObj.setKind(nilKindStr);

        var runtimeData: IokeData = IokeData{
            .Runtime = self
        };

        self.runtime = IokeObject{
            .runtime = self,
            .documentation = "Runtime gives meta-circular access to the currently executing Ioke runtime."[0..],
            .data = &runtimeData,
        };
        self.runtime.?.init();


        self.defaultBehavior = IokeObject{
            .runtime = self,
            .documentation = "DefaultBehavior is a mixin that provides most of the methods shared by most instances in the system."[0..],
        };
        self.defaultBehavior.?.init();


        self.origin = IokeObject{
            .runtime = self,
            .documentation = "Any object created from scratch should usually be derived from Origin."[0..],
        };
        self.origin.?.init();

        // std.log.info("\n nil1 {} {*}\n", .{self.nil == null, self});
        // std.log.info("\n nil1 {}\n", .{self.nil == null});
        var _trueObj = IokeObject{
            .runtime = self,
            .toString = "true"[0..],
        };

        _trueObj.init();

        _trueObj.setKind("true"[0..]);

        var _trueData = IokeData{
            .IokeObject = &_trueObj,
        };

        self._true = IokeObject{
            .runtime = self,
            .documentation = "true is an oddball object that always represents itself. It can not be mimicked and represents the a true value."[0..],
            .data = &_trueData,
        };
        self._true.?.init();

        var _falseBody = Body{
            .allocator = self.allocator,
            .flags = IokeObjectNS.FALSY_F,
        };

        var _falseObj = IokeObject{
            .body = &_falseBody,
            .runtime = self,
            .toString = "false"[0..]
        };
        _falseObj.init();

        _falseObj.setKind("false"[0..]);

        var _falseData = IokeData{
            .IokeObject = &_falseObj,
        };

        self._false = IokeObject{
            .runtime = self,
            .documentation = "false is an oddball object that always represents itself. It can not be mimicked and (alongside nil) is one of the two false values."[0..],
            .data = &_falseData,
        };
        self._false.?.init();

        var _symbolObj = Symbol{.text = ""[0..]};
        var _symbolData = IokeData {.Symbol = &_symbolObj};

        self.symbol = IokeObject{
            .runtime = self,
            .documentation = "Represents a symbol - an object that always represents itself."[0..],
            .data = &_symbolData,
        };
        self.symbol.?.init();

        var _lexicalCtx = LexicalContext{.ground = self.ground.?.getRealContext(), surroundingContext = self.ground.? };
        var _lexicalCtxData = IokeData {.LexicalContext = &_lexicalCtx};

        self.lexicalContext = IokeObject{
            .runtime = self,
            .documentation = "A lexical activation context."[0..],
            .data = &_lexicalCtxData,
        };
        self.lexicalContext.?.init();

        std.log.info("self message null end of init?? {} \n", .{self.message.?.body == null});

    }

    // pub fn newStatic() { }
};
