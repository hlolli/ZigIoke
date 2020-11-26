const IokeData = @import("./IokeData.zig").IokeData;

// Cell(String name, int hash)
pub const Cell = struct {
    name: []const u8,
    value: ?*IokeData = null,
    next: ?*Cell = null, // next in hash table bucket
    orderedNext: ?*Cell = null, // next in linked list
};
