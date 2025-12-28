const std = @import("std");
const Entity = @import("entity.zig");

const WorldIdType = u32;

const World = struct {
    id: WorldIdType,
    entities_table: ?[]Entity = null,


};

pub const WorldManager = struct {
    next_id: std.atomic.Value(WorldIdType) = std.atomic.Value(WorldIdType).init(1),
    pub fn createWorld(self: *WorldManager) World {
        const id = self.next_id.fetchAdd(1, .seq_cst);

        return World{
            .id = id,
            .entities_table = null,
        };
    }
};

test "first draft world system" {
    var wm = WorldManager{};
    const one = wm.createWorld();
    const two = wm.createWorld();

    try std.testing.expectEqual(1, one.id);
    try std.testing.expectEqual(2, two.id);
}
