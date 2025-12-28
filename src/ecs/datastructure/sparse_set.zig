const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const Alignment = std.mem.Alignment;

/// Representation of a sparse set for a u64.
const MAX_U32 = 4_294_967_295;

pub fn SparseSet(comptime T: type) type {
    comptime {
        if (u64 != @FieldType(T, "id")) {
            @compileError("Anything passed to the SparseSet inside of the ECS " ++
                "module must have an `id` field!\n");
        }

        if (!@hasDecl(T, "fetchIndex")) {
            @compileError("And A fetchIndex function that translate the " ++
                "desired indexing\n");
        }
    }

    return struct {
        const Self = @This();
        allocator: Allocator,
        count: usize,
        // Represent all the indices actually in memory
        dense: []T = undefined,

        // Represent the indices in which the entities are stored in the dense
        // array.
        sparse: []@FieldType(T, "id") = undefined,

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
            const id: u32 = item.fetchIndex(item.id);

            if (id >= self.sparse.len) {
                return false;
            }

            const idx = self.sparse[id];
            return (idx < self.count and self.dense[idx].fetchIndex(self.dense[idx].id) == id);
        }

        pub fn insert(self: *Self, item: T) void {
            const id = item.fetchIndex(item.id);
            if (self.contains(item)) {
                return;
            }

            self.dense[self.count] = item;
            self.sparse[id] = self.count;
            self.count += 1;
        }

        pub fn remove(self: *Self, item: T) void {
            std.debug.print("{d}\n", .{item.fetchIndex(item.id)});

            if (self.count == 0) {
                return;
            }

            if (!self.contains(item)) {
                std.debug.print("here", .{});
                return;
            }

            const id_to_remove = item.fetchIndex(item.id);

            const last_sparse = self.sparse[id_to_remove];
            const last_dense = self.dense[self.count - 1];

            self.dense[last_sparse] = last_dense;
            self.sparse[last_dense.fetchIndex(last_dense.id)] = last_sparse;

            self.count -= 1;
        }
    };
}

test "basic insert" {
    const entity = @import("../entity.zig");
    const EntitySparseSet = SparseSet(entity.Entity);

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
    const EntitySparseSet = SparseSet(entity.Entity);

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
    const EntitySparseSet = SparseSet(entity.Entity);

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
