const IokeObject = @import("./IokeObject.zig").IokeObject;
// DefaultMethod extends Method implements AssociatedCode
// LexicalBlock extends IokeData implements AssociatedCode
// LexicalMacro extends IokeData implements AssociatedCode, Named, Inspectable

pub const AssociatedCodeTag = enum {};

pub const AssociatedCode = union(AssociatedCodeTag) {};

// public interface AssociatedCode extends CanRun
// @static - everything here below
pub const AssociatedCodeHelpers = struct {};
// pub fn getCode() IokeObject { }
// public IokeObject getCode();
// public String getArgumentsCode();
// public String getFormattedCode(Object self) throws ControlFlow;
// AssociatedCode
