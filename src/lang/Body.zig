const std = @import("std");
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;
const Cell = @import("./Cell.zig").Cell;
const IokeData = @import("./IokeData.zig").IokeData;
const IokeDataHelpers = @import("./IokeData.zig").IokeDataHelpers;
const IokeObject = @import("./IokeObject.zig").IokeObject;
const String = @import("./String.zig").String;

const INITIAL_CELL_SIZE: u8 = 4;

pub const Body = struct {
    const Self = @This();
    allocator: *Allocator,
    documentation: ?[]i8 = null,
    mimic: ?*IokeObject = null,
    mimics: ?*ArrayList(*IokeObject) = null,
    mimicCount: u32 = 0,
    flags: u8 = 0,
    hooks: ?*ArrayList(*IokeObject) = null,
    cells: ?*AutoHashMap([]const u8, *Cell) = null,
    count: u16 = 0,
    firstAdded: ?*Cell = null,
    lastAdded: ?*Cell = null,

    pub fn deinit(self: *Self) void { }


    pub fn put(self: *Self, name: []const u8, value: *IokeData) void {
        var cell = self.getCell(name, false);
        cell.value = value;
    }

    fn getCell(self: *Self, name: []const u8, query: bool) *Cell {
        if(self.cells == null and query == true) {
            return self.createCell(name);
        }

        var maybeCell = if (self.cells != null) self.cells.?.getEntry(name) else null;
        if (maybeCell != null) {
            return maybeCell.?.value;
        } else {
            return self.createCell(name);
        }
    }

    pub fn get(self: *Self, name: []const u8) ?*Cell {
        return self.getCell(name, true);
    }

    fn createCell(self: *Self, name: []const u8) *Cell {
        if (self.count == 0) {
            var newCells = AutoHashMap([]const u8, *Cell).init(self.allocator);
            self.cells = &newCells;
        }

        var newCell: Cell = Cell{.name = name};

        self.count += 1;

        if(self.lastAdded != null) {
            // TODO segfault fix
            // self.lastAdded.?.*.orderedNext = &newCell;
        }

        if(self.firstAdded == null) {
            self.firstAdded = &newCell;
        }

        self.lastAdded = &newCell;

        // addKnownAbsentCell(cellsLocalRef, newCell, insertPos);
        return &newCell;
    }
};
