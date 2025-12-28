const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const Alignment = std.mem.Alignment;

pub const SparseOptions = struct {
    is_bit_masked: bool,
};

pub fn SparseSet(comptime T: type, comptime opt: ?SparseOptions) type {
    comptime {
        if (!@hasField(T, "id")) {
            @compileError("To use SparseSet the container T must ave an id field\n");
        }
    }

    const masked = if (opt) |o| o.is_bit_masked else false;

    return struct {
        const Self = @This();
        allocator: Allocator,
        count: usize,
        // Represent all the indices actually in memory
        dense: []T = undefined,

        // Represent the indices in which the entities are stored in the dense
        // array.
        sparse: []@FieldType(T, "id") = undefined,

        inline fn fetchBitMaskedIndex(id: @FieldType(T, "id")) @FieldType(T, "id") {
            if (masked) {
                const actual_id: @TypeOf(id) = @intCast(id & 0xFFFF_FFFF);
                return actual_id;
            } else {
                return id;
            }
        }

        pub fn init(allocator: Allocator) !Self {
            const dense_arr = try allocator.alloc(T, 1024);
            errdefer allocator.free(dense_arr);
            const sparse_arr = try allocator.alloc(@FieldType(T, "id"), 4096);
            errdefer allocator.free(sparse_arr);
            return Self{
                .allocator = allocator,
                .count = 0,
                .dense = dense_arr,
                .sparse = sparse_arr,
            };
        }

        pub fn deinit(self: *Self) void {
            self.count = 0;
            self.allocator.free(self.dense);
            self.allocator.free(self.sparse);

            self.dense = &[_]T{};
            self.sparse = &[_]@FieldType(T, "id"){};
        }

        // TODO: rework.
        pub fn contains(self: *Self, item: T) bool {
            const id = fetchBitMaskedIndex(item.id);

            if (id >= self.sparse.len) {
                return false;
            }

            const idx = self.sparse[id];
            return (idx < self.count and fetchBitMaskedIndex(self.dense[idx].id) == id);
        }

        pub fn insert(self: *Self, item: T) void {
            const id = fetchBitMaskedIndex(item.id);
            if (self.contains(item)) {
                return;
            }

            self.dense[self.count] = item;
            self.sparse[id] = self.count;
            self.count += 1;
        }

        pub fn remove(self: *Self, item: T) void {
            if (self.count == 0) {
                return;
            }

            if (!self.contains(item)) {
                return;
            }

            const id_to_remove = fetchBitMaskedIndex(item.id);

            const last_sparse = self.sparse[id_to_remove];
            const last_dense = self.dense[self.count - 1];

            self.dense[last_sparse] = last_dense;
            self.sparse[fetchBitMaskedIndex(last_dense.id)] = last_sparse;

            self.count -= 1;
        }
    };
}

test "basic insert" {
    const entity = @import("../entity.zig");

    const s_opt: SparseOptions = .{ .is_bit_masked = true };
    const EntitySparseSet = SparseSet(entity.Entity, s_opt);

    const alloc = std.testing.allocator;

    var sparse_set = try EntitySparseSet.init(alloc);
    defer sparse_set.deinit();

    var em = entity.EntityManager{};

    const en1 = em.new();
    try std.testing.expect(!sparse_set.contains(en1));
    sparse_set.insert(en1);
    try std.testing.expect(sparse_set.contains(en1));

    const en2 = em.new();
    try std.testing.expect(!sparse_set.contains(en2));
    sparse_set.insert(en2);
    try std.testing.expect(sparse_set.contains(en2));
    try std.testing.expect(sparse_set.contains(en1));
}

test "basic contains" {
    const entity = @import("../entity.zig");

    const s_opt: SparseOptions = .{ .is_bit_masked = true };
    const EntitySparseSet = SparseSet(entity.Entity, s_opt);

    const alloc = std.testing.allocator;

    var sparse_set = try EntitySparseSet.init(alloc);
    defer sparse_set.deinit();

    var em = entity.EntityManager{};

    const en1 = em.new();
    try std.testing.expect(!sparse_set.contains(en1));
    sparse_set.insert(en1);
    try std.testing.expect(sparse_set.contains(en1));

    const en2 = em.new();
    try std.testing.expect(!sparse_set.contains(en2));
    sparse_set.insert(en2);
    try std.testing.expect(sparse_set.contains(en2));
    try std.testing.expect(sparse_set.contains(en1));

    const en3 = em.new();
    const en4 = em.new();
    const en5 = em.new();
    const en6 = em.new();
    const en7 = em.new();
    try std.testing.expect(!sparse_set.contains(en3));
    try std.testing.expect(!sparse_set.contains(en4));
    try std.testing.expect(!sparse_set.contains(en5));
    try std.testing.expect(!sparse_set.contains(en6));
    try std.testing.expect(!sparse_set.contains(en7));

    sparse_set.insert(en3);
    sparse_set.insert(en4);
    sparse_set.insert(en5);
    sparse_set.insert(en6);
    sparse_set.insert(en7);

    try std.testing.expect(sparse_set.contains(en3));
    try std.testing.expect(sparse_set.contains(en4));
    try std.testing.expect(sparse_set.contains(en5));
    try std.testing.expect(sparse_set.contains(en6));
    try std.testing.expect(sparse_set.contains(en7));
}

test "basic removal" {
    const entity = @import("../entity.zig");

    const s_opt: SparseOptions = .{ .is_bit_masked = true };
    const EntitySparseSet = SparseSet(entity.Entity, s_opt);

    const alloc = std.testing.allocator;

    var sparse_set = try EntitySparseSet.init(alloc);
    defer sparse_set.deinit();

    var em = entity.EntityManager{};

    const en1 = em.new();
    const en2 = em.new();
    sparse_set.insert(en1);
    sparse_set.insert(en2);
    try std.testing.expect(sparse_set.contains(en1));
    try std.testing.expect(sparse_set.contains(en2));
    sparse_set.remove(en1);
    try std.testing.expect(!sparse_set.contains(en1));
    try std.testing.expect(sparse_set.contains(en2));
}
