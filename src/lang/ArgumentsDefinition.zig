// public interface ArgumentsDefinition {
//     void assignArgumentValues(final IokeObject locals, final IokeObject context, final IokeObject message, final Object on, final Call call) throws ControlFlow;
//     void assignArgumentValues(final IokeObject locals, final IokeObject context, final IokeObject message, final Object on) throws ControlFlow;
//     String getCode();
//     String getCode(boolean lastComma);
//     Collection<String> getKeywords();
//     List<DefaultArgumentsDefinition.Argument> getArguments();
//     boolean isEmpty();
//     String getRestName();
//     String getKrestName();
// }

const DefaultMethod = @import("./DefaultMethod.zig").DefaultMethod;

pub const ArgumentsDefinitionTag = enum {
    DefaultMethod,

};

pub const ArgumentsDefinition = union(ArgumentsDefinitionTag) {
    DefaultMethod
};


pub const ArgumentsDefinitionHelpers = struct {};
