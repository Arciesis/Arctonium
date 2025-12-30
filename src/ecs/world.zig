const std = @import("std");
const entity = @import("entity.zig");
const sparse_set = @import("datastructure/sparse_set.zig");
const Options = sparse_set.SparseOptions;
const EntitySparseSet = sparse_set.SparseSet(entity.Entity, Options{ .is_bit_masked = true });

const Self = @This();

const WorldIdType = u32;

allocator: std.mem.Allocator,
registry: EntitySparseSet,

pub fn init(allocator: std.mem.Allocator) !Self {
    return Self{
        .allocator = allocator,
        .registry = try EntitySparseSet.init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.registry.deinit();
}
