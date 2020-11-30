const IokeData = @import("./IokeData.zig").IokeData;
const IokeDataHelpers = @import("./IokeData.zig").IokeDataHelpers;
const IokeObject = @import("./IokeObject.zig").IokeObject;

// Cell(String name, int hash)
pub const Cell = struct {
    name: []const u8,
    value: ?*IokeData = null,
    next: ?*Cell = null, // next in hash table bucket
    orderedNext: ?*Cell = null, // next in linked list
};

pub const CellHelpers = struct {
    pub fn getObject(cell: *Cell) ?*IokeObject {
        if (cell.value == null) {
            return null;
        } else {
            return IokeDataHelpers.getObject(cell.value.?);
        }
    }
};
