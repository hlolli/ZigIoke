const std = @import("std");
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;
const IokeData = @import("./IokeData.zig").IokeData;
const IokeObject = @import("./IokeObject.zig").IokeObject;
const String = @import("./String.zig").String;

const INITIAL_CELL_SIZE: u8 = 4;

// Cell(String name, int hash)
pub const Cell = struct {
    name: []const u8,
    value: ?*IokeData = null,
    next: ?*Cell = null, // next in hash table bucket
    orderedNext: ?*Cell = null, // next in linked list
};

pub const Body = struct {
    const Self = @This();
    allocator: *Allocator,
    documentation: ?[]i8 = null,
    mimic: ?*IokeObject = null,
    mimics: ?ArrayList(IokeObject) = null,
    mimicCount: u32 = 0,
    flags: u8 = 0,
    cells: ?AutoHashMap([]const u8, Cell) = null,
    count: u16 = 0,
    firstAdded: ?*Cell = null,
    lastAdded: ?*Cell = null,

    pub fn deinit(self: *Self) void {
        if (self.cells != null) {
            self.cells.?.deinit();
        }

        if (self.mimics != null) {
            self.mimics.?.deinit();
        }
    }


    pub fn put(self: *Self, name: []const u8, value: *IokeData) void {
        var cell: ?Cell = self.getCell(name, false);
        if (cell != null) {
            cell.?.value = value;
        }
    }

    fn getCell(self: *Self, name: []const u8, query: bool) ?Cell {
        // Cell[] cellsLocalRef = cells;
        if(self.cells == null and query == true) {
            return null;
        }

        // var hash = String.getHashCode(name);

        if(self.cells != null) {
            return self.cells.?.get(name);
            // var cellIndex = self.getCellIndex(self.cells.?.items.len, hash);
                // var cell: ?Cell = self.cells.?.items[cellIndex];
                // while(cell != null) {
                //     var sname = cell.?.name;
                //     if (String.equals(sname, name)) {
                //         break;
                //     }
                //     cell = cell.?.next.?.*;
                // }
                // if(query == true or (query == false and cell != null)) {
                //     return cell;
                // } else {
                //     return null;
                // }
        } else {
            return self.createCell(name);
        }
    }

    // fn getCellIndex(self: *Self, tableSize: u64, hash: u64) u64 {
    //     return hash & (tableSize - 1);
    // }

    fn createCell(self: *Self, name: []const u8) Cell {
        var cellsLocalRef = self.cells;

        if (self.count == 0) {
            cellsLocalRef = AutoHashMap([]const u8, Cell).init(self.allocator);
            self.cells = cellsLocalRef;
        }

        // else {
        //     var tableSize = cellsLocalRef.?.count();
        //     var prev: ?Cell = cellsLocalRef.?.items[insertPos];
        //     var cell: ?Cell = prev;
        //     while (cell != null) {
        //         if (String.equals(name, cell.?.name)) {
        //             break;
        //         }
        //         prev = cell;
        //         cell = cell.?.next.?.*;
        //     }
        //     if(cell != null) {
        //         return cell.?;
        //     } else {
        //         if (INITIAL_CELL_SIZE * (self.count + 1) > 3 * cellsLocalRef.?.items.len) {
        //             cellsLocalRef = ArrayList(Cell).initCapacity(self.allocator, cellsLocalRef.?.items.len * 2) catch unreachable;
        //             // copyTable(cells, cellsLocalRef, count);
        //             self.cells = cellsLocalRef;
        //             insertPos = self.getCellIndex(cellsLocalRef.?.items.len, hash);
        //         }
        //     }
        // }

        var newCell = Cell{.name = name};

        self.count += 1;

        if(self.lastAdded != null) {
            self.lastAdded.?.orderedNext = &newCell;
        }

        if(self.firstAdded == null) {
            self.firstAdded = &newCell;
        }

        self.lastAdded = &newCell;

        // addKnownAbsentCell(cellsLocalRef, newCell, insertPos);
        return newCell;
    }
};
