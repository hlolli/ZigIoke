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

    allocator: *Allocator,
    interpreter: *Interpreter,

    nul: ?*IokeObject = null,

    base: ?*IokeObject = null,
    iokeGround: ?*IokeObject = null,
    ground: ?*IokeObject = null,
    system: ?*IokeObject = null,
    runtime: ?*IokeObject = null,
    defaultBehavior: ?*IokeObject = null,
    origin: ?*IokeObject = null,
    nil: ?*IokeObject = null,
    _true: ?*IokeObject = null,
    _false: ?*IokeObject = null,
    text: ?*IokeObject = null,
    symbol: ?*IokeObject = null,
    number: ?*IokeObject = null,
    method: ?*IokeObject = null,
    defaultMethod: ?*IokeObject = null,
    nativeMethod: ?*IokeObject = null,
    lexicalBlock: ?*IokeObject = null,
    defaultMacro: ?*IokeObject = null,
    lexicalMacro: ?*IokeObject = null,
    defaultSyntax: ?*IokeObject = null,
    arity: ?*IokeObject = null,
    mixins: ?*IokeObject = null,
    message: ?*IokeObject = null,
    restart: ?*IokeObject = null,
    list: ?*IokeObject = null,
    dict: ?*IokeObject = null,
    set: ?*IokeObject = null,
    range: ?*IokeObject = null,
    pair: ?*IokeObject = null,
    tuple: ?*IokeObject = null,
    call: ?*IokeObject = null,
    lexicalContext: ?*IokeObject = null,
    dateTime: ?*IokeObject = null,
    locals: ?*IokeObject = null,
    condition: ?*IokeObject = null,
    rescue: ?*IokeObject = null,
    handler: ?*IokeObject = null,
    io: ?*IokeObject = null,
    fileSystem: ?*IokeObject = null,
    regexp: ?*IokeObject = null,
    sequence: ?*IokeObject = null,
    iteratorSequence: ?*IokeObject = null,
    keyValueIteratorSequence: ?*IokeObject = null,
    integer: ?*IokeObject = null,
    decimal: ?*IokeObject = null,
    ratio: ?*IokeObject = null,
    infinity: ?*IokeObject = null,

    // Core messages
    asText: ?*IokeObject = null,
    asRational: ?*IokeObject = null,
    asDecimal: ?*IokeObject = null,
    asSymbol: ?*IokeObject = null,
    asTuple: ?*IokeObject = null,
    mimic: ?*IokeObject = null,
    spaceShip: ?*IokeObject = null,
    succ: ?*IokeObject = null,
    pred: ?*IokeObject = null,
    setValue: ?*IokeObject = null,
    nilMessage: ?*IokeObject = null,
    name: ?*IokeObject = null,
    callMessage: ?*IokeObject = null,
    closeMessage: ?*IokeObject = null,
    code: ?*IokeObject = null,
    each: ?*IokeObject = null,
    textMessage: ?*IokeObject = null,
    conditionsMessage: ?*IokeObject = null,
    handlerMessage: ?*IokeObject = null,
    reportMessage: ?*IokeObject = null,
    printMessage: ?*IokeObject = null,
    printlnMessage: ?*IokeObject = null,
    outMessage: ?*IokeObject = null,
    currentDebuggerMessage: ?*IokeObject = null,
    invokeMessage: ?*IokeObject = null,
    errorMessage: ?*IokeObject = null,
    ErrorMessage: ?*IokeObject = null,
    FileMessage: ?*IokeObject = null,
    inspectMessage: ?*IokeObject = null,
    noticeMessage: ?*IokeObject = null,
    removeCellMessage: ?*IokeObject = null,
    plusMessage: ?*IokeObject = null,
    minusMessage: ?*IokeObject = null,
    multMessage: ?*IokeObject = null,
    divMessage: ?*IokeObject = null,
    modMessage: ?*IokeObject = null,
    expMessage: ?*IokeObject = null,
    binAndMessage: ?*IokeObject = null,
    binOrMessage: ?*IokeObject = null,
    binXorMessage: ?*IokeObject = null,
    lshMessage: ?*IokeObject = null,
    rshMessage: ?*IokeObject = null,
    ltMessage: ?*IokeObject = null,
    lteMessage: ?*IokeObject = null,
    gtMessage: ?*IokeObject = null,
    gteMessage: ?*IokeObject = null,
    eqMessage: ?*IokeObject = null,
    eqqMessage: ?*IokeObject = null,
    testMessage: ?*IokeObject = null,
    isApplicableMessage: ?*IokeObject = null,
    useWhatMessage: ?*IokeObject = null,
    cellAddedMessage: ?*IokeObject = null,
    cellChangedMessage: ?*IokeObject = null,
    cellRemovedMessage: ?*IokeObject = null,
    cellUndefinedMessage: ?*IokeObject = null,
    mimicAddedMessage: ?*IokeObject = null,
    mimicRemovedMessage: ?*IokeObject = null,
    mimicsChangedMessage: ?*IokeObject = null,
    mimickedMessage: ?*IokeObject = null,
    seqMessage: ?*IokeObject = null,
    hashMessage: ?*IokeObject = null,
    nextPMessage: ?*IokeObject = null,
    nextMessage: ?*IokeObject = null,
    kindMessage: ?*IokeObject = null,

    pub fn getNextId() u32 {
        return getNextId_();
    }

    pub fn getNil(self: *Self) ?*IokeObject {
        if (self.nil == null) {
            std.log.err("\n very very bad {*}\n", .{self});
            return null;
        } else {
            return self.nil;
        }
    }

    pub fn newMessage(self: *Self, name: []const u8) *IokeObject {
        var newMsg = Message{.runtime = self, .name = name};
        return self.createMessage(&newMsg);
    }

    pub fn createMessage(self: *Self, m: *Message) *IokeObject {
        var objCopy = self.message.?.allocateCopy(null, null);
        var iokeData: IokeData = IokeData{
            .Message = m,
        };
        objCopy.singleMimicsWithoutCheck(self.message.?);
        objCopy.setData(&iokeData);
        return objCopy;
    }

    pub fn newText(self: *Self, text_: []const u8) *IokeObject {
        var objCopy: IokeObject = self.text.?.*;
        objCopy.singleMimicsWithoutCheck(self.text.?);
        var newText_ = Text{.text = text_};
        var newData_ = IokeData {.Text = &newText_};
        objCopy.setData(&newData_);
        return &objCopy;
    }

    pub fn parseStream(self: *Self, reader: StringIterator, message: *IokeObject, context: *IokeObject) *IokeObject {
        return Message.newFromStreamStatic(self, reader, message, context);
    }

    pub fn evaluateStream(self: *Self, reader: StringIterator, message: *IokeObject, context: *IokeObject) *IokeObject {
        var parsedObj = self.parseStream(reader, message, context);
        // defer parsedObj.deinit();
        return self.interpreter.evaluate(parsedObj, self.ground.?, self.ground.?, null);
    }


    pub fn getSymbol(self: *Self, name_: []const u8) *IokeObject {
        var maybeSymbol = self.symbolTable.?.get(name_);
        if (maybeSymbol == null) {
            var _symbolObj = Symbol{.text = name_};
            var _symbolData = IokeData {.Symbol = &_symbolObj};
            var _symbolBody = Body{.allocator = self.allocator};
            maybeSymbol = IokeObject{
                .body = &_symbolBody,
                .runtime = self,
                .data = &_symbolData,
            };
            maybeSymbol.?.singleMimicsWithoutCheck(self.symbol.?);
            self.symbolTable.?.put(name_, maybeSymbol.?) catch unreachable;
        }
        return &maybeSymbol.?;
    }

    pub fn deinit(self: *Self) void {

        if (self.symbolTable != null) {
            self.symbolTable.?.deinit();
            self.symbolTable = null;
        }

        if (self.base != null) {
            self.base.?.deinit();
            self.base = null;
        }

        if (self.iokeGround != null) {
            self.iokeGround.?.deinit();
            self.iokeGround = null;
        }

        if (self.ground != null) {
            self.ground.?.deinit();
            self.ground = null;
        }

        if (self.system != null) {
            self.system.?.deinit();
            self.system = null;
        }

        if (self.runtime != null) {
            self.runtime.?.deinit();
            self.runtime = null;
        }

        if (self.defaultBehavior != null) {
            self.defaultBehavior.?.deinit();
            self.defaultBehavior = null;
        }

        if (self.origin != null) {
            self.origin.?.deinit();
            self.origin = null;
        }

        if (self.text != null) {
            self.text.?.deinit();
            self.text = null;
        }

        if (self.nil != null) {
            self.nil.?.deinit();
            self.nil = null;
        }

        if (self._true != null) {
            self._true.?.deinit();
            self._true = null;
        }

        if (self._false != null) {
            self._false.?.deinit();
            self._false = null;
        }

        if (self.message != null) {
            self.message.?.deinit();
            self.message = null;
        }

        if (self.nul != null) {
            self.nul.?.deinit();
            self.nul = null;
        }
    }

    pub fn init(self: *Self) void {
        self.symbolTable = AutoHashMap([]const u8, IokeObject).init(self.allocator);

        var groundBody = Body{.allocator = self.allocator};
        var newGround = IokeObject{
            .body = &groundBody,
            .runtime = self,
            .documentation = "Ground is the default place code is evaluated in."[0..],
        };

        self.ground = &newGround;
        // self.ground.?.init();

        var nulBody = Body{.allocator = self.allocator};
        var newNul = IokeObject{
            .body = &nulBody,
            .runtime = self,
            .documentation = "NOT TO BE EXPOSED TO Ioke - used for internal usage only",
        };
        self.nul = &newNul;
        // self.nul.?.init();

        var messageMsg: Message = Message{
            .runtime = self,
            .name = ""[0..]
        };

        var messageData: IokeData = IokeData{
            .Message = &messageMsg
        };

        var _messageBody = Body{.allocator = self.allocator};
        var _newMessage = IokeObject{
            .body = &_messageBody,
            .runtime = self,
            .documentation = "A Message is the basic code unit in Ioke."[0..],
            .data = &messageData,
        };
        self.message = &_newMessage;
        // self.message.?.init();

        var _baseBody = Body{.allocator = self.allocator};
        var newBase = IokeObject{
            .body = &_baseBody,
            .runtime = self,
            .documentation = (
                "Base is the top of the inheritance structure. " ++
                    "Most of the objects in the system are derived from this instance. " ++
                    "Base should keep its cells to the bare minimum needed for the system.")[0..],
        };
        self.base = &newBase;
        // self.base.?.init();

        var _iokeGroundBody = Body{.allocator = self.allocator};
        var newIokeGround = IokeObject{
            .body = &_iokeGroundBody,
            .runtime = self,
            .documentation = "IokeGround is the place that mimics default behavior, and where most global objects are defined.."[0..],
        };
        self.iokeGround = &newIokeGround;
        // self.iokeGround.?.init();

        var _conditionBody = Body{.allocator = self.allocator};
        var newCondition = IokeObject{
            .body = &_conditionBody,
            .runtime = self,
            .documentation = "The root mimic of all the conditions in the system."[0..],
        };
        self.condition = &newCondition;
        // self.condition.?.init();

        var _localsBody = Body{.allocator = self.allocator};
        var newLocals = IokeObject{
            .body = &_localsBody,
            .runtime = self,
            .documentation = "Contains all the locals for a specific invocation."[0..],
        };
        self.locals = &newLocals;

        // TODO missing IokeSystem in .data
        var _systemBody = Body{.allocator = self.allocator};
        var newSystem = IokeObject{
            .body = &_systemBody,
            .runtime = self,
            .documentation = "System defines things that represents the currently running system, such as the load path."[0..],
        };
        self.system = &newSystem;
        // self.system.?.init();

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
        // nilObj.init();

        std.log.info("\n ground ptr {*}\n", .{self.ground.?.runtime});
        var nilData = IokeData{
            .Nil = &nilObj,
        };

        var _nilBody = Body{.allocator = self.allocator};
        var newNil = IokeObject{
            .body = &_nilBody,
            .runtime = self,
            .documentation = "nil is an oddball object that always represents itself. It can not be mimicked and (alongside false) is one of the two false values."[0..],
            .data = &nilData,
        };
        self.nil = &newNil;
        // self.nil.?.*.init();

        // Needs to be initialized early for
        // setKind to work without null checks
        var _textBody = Body{.allocator = self.allocator};
        var _textObj = Text{.text = ""[0..]};
        var _textData = IokeData {.Text = &_textObj};

        var _newText = IokeObject{
            .body = &_textBody,
            .runtime = self,
            .documentation = "Contains an immutable piece of text."[0..],
            .data = &_textData,
        };
        self.text = &_newText;
        // self.text.?.init();

        // setKind can be called now
        var nilKindStr = "nil"[0..];
        nilObj.setKind(nilKindStr);

        var runtimeData: IokeData = IokeData{
            .Runtime = self
        };
        var _runtimeBody = Body{.allocator = self.allocator};
        var newRuntime = IokeObject{
            .body = &_runtimeBody,
            .runtime = self,
            .documentation = "Runtime gives meta-circular access to the currently executing Ioke runtime."[0..],
            .data = &runtimeData,
        };
        self.runtime = &newRuntime;
        // self.runtime.?.init();


        var _defaultBehaviorBody = Body{.allocator = self.allocator};
        var newDefaultBehavior = IokeObject{
            .body = &_defaultBehaviorBody,
            .runtime = self,
            .documentation = "DefaultBehavior is a mixin that provides most of the methods shared by most instances in the system."[0..],
        };
        self.defaultBehavior = &newDefaultBehavior;
        // self.defaultBehavior.?.init();


        var _originBody = Body{.allocator = self.allocator};
        var newOrigin = IokeObject{
            .body = &_originBody,
            .runtime = self,
            .documentation = "Any object created from scratch should usually be derived from Origin."[0..],
        };
        self.origin = &newOrigin;
        // self.origin.?.init();

        // std.log.info("\n nil1 {} {*}\n", .{self.nil == null, self});
        // std.log.info("\n nil1 {}\n", .{self.nil == null});
        var _trueBody = Body{.allocator = self.allocator};
        var _trueObj = IokeObject{
            .body = &_trueBody,
            .runtime = self,
            .toString = "true"[0..],
        };

        // _trueObj.init();

        _trueObj.setKind("true"[0..]);

        var _trueData = IokeData{
            .True = &_trueObj,
        };

        var __trueBody = Body{.allocator = self.allocator};
        var newTrue = IokeObject{
            .body = &__trueBody,
            .runtime = self,
            .documentation = "true is an oddball object that always represents itself. It can not be mimicked and represents the a true value."[0..],
            .data = &_trueData,
        };
        self._true = &newTrue;
        // self._true.?.init();

        var _falseBody = Body{
            .allocator = self.allocator,
            .flags = IokeObjectNS.FALSY_F,
        };

        var _falseObj = IokeObject{
            .body = &_falseBody,
            .runtime = self,
            .toString = "false"[0..]
        };
        // _falseObj.init();

        _falseObj.setKind("false"[0..]);

        var _falseData = IokeData{
            .False = &_falseObj,
        };

        var __falseBody = Body{.allocator = self.allocator};
        var newFalse = IokeObject{
            .body = &__falseBody,
            .runtime = self,
            .documentation = "false is an oddball object that always represents itself. It can not be mimicked and (alongside nil) is one of the two false values."[0..],
            .data = &_falseData,
        };
        self._false = &newFalse;
        // self._false.?.init();

        var _symbolObj = Symbol{.text = ""[0..]};
        var _symbolData = IokeData {.Symbol = &_symbolObj};

        var _symbolBody = Body{.allocator = self.allocator};
        var _newSymbol = IokeObject{
            .body = &_symbolBody,
            .runtime = self,
            .documentation = "Represents a symbol - an object that always represents itself."[0..],
            .data = &_symbolData,
        };
        self.symbol = &_newSymbol;
        // self.symbol.?.init();

        var _lexicalCtx = LexicalContext{
            .ground = self.ground.?.getRealContext(),
            .surroundingContext = self.ground.?
        };
        var _lexicalCtxData = IokeData {.LexicalContext = &_lexicalCtx};

        var _lexicalContextBody = Body{.allocator = self.allocator};
        var _newLexicalContext = IokeObject{
            .body = &_lexicalContextBody,
            .runtime = self,
            .documentation = "A lexical activation context."[0..],
            .data = &_lexicalCtxData,
        };
        self.lexicalContext = &_newLexicalContext;
        // self.lexicalContext.?.init();

        // MESSAGES
        self.isApplicableMessage = self.newMessage("applicable?"[0..]);
        std.log.info("self message null end of init\n", .{});

    }

    // pub fn newStatic() { }
};
