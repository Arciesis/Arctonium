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

test "all features availability" {
    const allocator = std.testing.allocator;
    var first_world = try world.World.init(allocator);
    defer first_world.deinit();

    var em = entity.EntityManager{};
    const first_entity = em.new();

    try first_world.registry.insert(first_entity);
    try std.testing.expect(first_world.registry.contains(first_entity));

    first_world.registry.remove(first_entity);
    try std.testing.expect(first_world.registry.count == 0);
}
