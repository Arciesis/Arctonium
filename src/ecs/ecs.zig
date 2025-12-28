const std = @import("std");

const world = @import("world.zig");
const entity = @import("entity.zig");
const sparse_set = @import("datastructure/sparse_set.zig");

pub const WorldManager = world.WorldManager;

test "ALL ECS" {
    std.testing.refAllDecls(world);
    std.testing.refAllDecls(entity);
    std.testing.refAllDecls(sparse_set);
}
