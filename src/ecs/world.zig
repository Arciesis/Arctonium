const std = @import("std");
const entity = @import("entity.zig");
const sparse_set = @import("datastructure/sparse_set.zig");
const Options = sparse_set.SparseOptions;
const EntitySparseSet = sparse_set.SparseSet(entity.Entity, Options{.is_bit_masked = true});

const WorldIdType = u32;

pub const World = struct {
    allocator: std.mem.Allocator,
    registry: EntitySparseSet,

    pub fn init(allocator: std.mem.Allocator) !World {
        return World {
            .allocator = allocator,
            .registry = try EntitySparseSet.init(allocator),
        };
    }

    pub fn deinit(self: *World) void {
        self.registry.deinit();
    }

};
