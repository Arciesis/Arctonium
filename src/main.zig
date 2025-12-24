const std = @import("std");
const builtin = @import("builtin");
const Arctonium = @import("Arctonium");
const zglfw = @import("zglfw");
const zbgfx = @import("zbgfx");
const bgfx = zbgfx.bgfx;
const ztracy = @import("ztracy");

var bgfx_clbs = zbgfx.callbacks.CCallbackInterfaceT{
    .vtable = &zbgfx.callbacks.DefaultZigCallbackVTable.toVtbl(),
};

pub fn main() !void {
    std.log.info("start of main", .{});
    defer std.log.info("End of main", .{});

    try zglfw.init();
    defer zglfw.terminate();

    zglfw.windowHint(.client_api, .no_api);

    const window = try zglfw.Window.create(1280, 720, "Arctonium", null);
    defer window.destroy();

    window.setSizeLimits(400, 400, -1, -1);

    var bgfx_init: bgfx.Init = undefined;
    bgfx.initCtor(&bgfx_init);

    // force vulkan for now as I'm on Linux to dev.
    bgfx_init.type = .Vulkan;

    const framebufferSize = window.getFramebufferSize();

    bgfx_init.resolution.width = @intCast(framebufferSize[0]);
    bgfx_init.resolution.height = @intCast(framebufferSize[1]);
    bgfx_init.platformData.ndt = null;
    bgfx_init.debug = true;

    // TODO: read note in zbgfx.callbacks.ZigAllocator
    //
    //bgfx_alloc = zbgfx.callbacks.ZigAllocator.init(&_allocator);
    //bgfx_init.allocator = &bgfx_alloc;

    bgfx_init.callback = &bgfx_clbs;
    //
    // Set native handles
    //
    switch (builtin.target.os.tag) {
        .linux => {
            bgfx_init.platformData.type = bgfx.NativeWindowHandleType.Wayland;
            bgfx_init.platformData.nwh = zglfw.getWaylandWindow(window);
            bgfx_init.platformData.ndt = zglfw.getWaylandDisplay();
        },
        .windows => {
            bgfx_init.platformData.nwh = zglfw.getWin32Window(window);
        },
        else => |v| if (v.isDarwin()) {
            bgfx_init.platformData.nwh = zglfw.getCocoaWindow(window);
        } else undefined,
    }
    if (!bgfx.init(&bgfx_init)) {
        std.process.exit(1);
    }
    defer bgfx.shutdown();

    // zglfw.makeContextCurrent(window);

    //
    // Default state
    //
    const state = 0 | bgfx.StateFlags_WriteRgb | bgfx.StateFlags_WriteA | bgfx.StateFlags_WriteZ | bgfx.StateFlags_DepthTestLess | bgfx.StateFlags_CullCcw | bgfx.StateFlags_Msaa;
    while (!window.shouldClose()) {
        // const tracy_zone = ztracy.ZoneN(@src(), "compute magic");
        // defer tracy_zone.End();
        zglfw.pollEvents();


        bgfx.setState(state, 0);
        // render your things here
        bgfx.touch(0);
        _ = bgfx.frame(false);

        window.swapBuffers();
    }
}
