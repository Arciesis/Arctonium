const std = @import("std");

// flags type reserved for maybe later use.
const RESERVED_0 = 0;
const DIRTY = 1;
const RESERVED_2 = 2;
const RESERVED_3 = 3;
const RESERVED_4 = 4;
const RESERVED_5 = 5;
const RESERVED_6 = 6;
const RESERVED_7 = 7;
const RESERVED_8 = 8;
const RESERVED_9 = 9;
const RESERVED_10 = 10;
const RESERVED_11 = 11;
const RESERVED_12 = 2;
const RESERVED_13 = 13;
const RESERVED_14 = 14;
const RESERVED_15 = 15;

const LOWER_INDEXING_BITS = u32;
const UPPER_GENRETAION_BITS = u16;
const UPPER_FUTURE_PROOF_BITS = u12;
const UPPER_FLAGS_TYPE_BITS = u4;
const TOTAL_INDEXING_BITS = u64;

/// Entity system.
/// 32 lo bits -> entity id
/// 16 upper hi bits -> version
/// 4 lower hi bits -> flag type
pub const Entity = packed struct {
    id: TOTAL_INDEXING_BITS,

    pub inline fn fetchIndex(_: Entity, id: TOTAL_INDEXING_BITS) LOWER_INDEXING_BITS {
        const actual: u32 = @intCast(id & 0xFFFF_FFFF);
        return actual;
    }
};

pub const EntityManager = struct {
    next_id: LOWER_INDEXING_BITS = 0,

    pub fn new(self: *EntityManager) Entity {
        // TODO: check if there is dirty ones !

        const id = self.next_id;
        self.next_id += 1;

        return Entity{ .id = @as(TOTAL_INDEXING_BITS, id) };
    }
};

test "first draft entity system" {
    var em = EntityManager{};
    const one = em.new();
    const two = em.new();

    try std.testing.expectEqual(one.fetchIndex(one.id), one.id);
    try std.testing.expectEqual(two.fetchIndex(two.id), two.id);
}
