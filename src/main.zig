const std = @import("std");
const Arctonium = @import("Arctonium");
const glfw = @import("zglfw");
const opengl = @import("zopengl");
const ztracy = @import("ztracy");

pub fn main() !void {
    try glfw.init();
    defer glfw.terminate();
    std.log.info("start of main", .{});
    defer std.log.info("End of main", .{});

    glfw.WindowHint.context_version_major.set(4);
    glfw.WindowHint.context_version_minor.set(3);
    glfw.WindowHint.opengl_profile.set(glfw.OpenGLProfile.opengl_core_profile);

    const window = try glfw.Window.create(1280, 720, "Arctonium", null);
    defer window.destroy();
    glfw.makeContextCurrent(window);

    try opengl.loadCoreProfile(getProcAddress, 4, 3);
    const gl = opengl.bindings;
    _ = gl;

    while (!window.shouldClose()) {
        // const tracy_zone = ztracy.ZoneN(@src(), "compute magic");
        // defer tracy_zone.End();
        glfw.pollEvents();
        std.log.debug("prt must be high", .{});

        // render your things here

        window.swapBuffers();
    }
}

fn getProcAddress(name: [*:0]const u8) callconv(.c) ?*const anyopaque {
    return glfw.getProcAddress(name);
}
