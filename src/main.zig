const std = @import("std");
const Arctonium = @import("Arctonium");
const glfw = @import("zglfw");
const opengl = @import("zopengl");

pub fn main() !void {
    try glfw.init();
    defer glfw.terminate();

    glfw.WindowHint.context_version_major.set(4);
    glfw.WindowHint.context_version_minor.set(3);
    glfw.WindowHint.opengl_profile.set(glfw.OpenGLProfile.opengl_core_profile);

    const window = try glfw.Window.create(1280, 720, "Arctomium", null);
    defer window.destroy();
    glfw.makeContextCurrent(window);

    try opengl.loadCoreProfile(getProcAddress, 4, 3);
    const gl = opengl.bindings;
    _ = gl;

    while (!window.shouldClose()) {
        glfw.pollEvents();

        // render your things here

        window.swapBuffers();
    }
}

fn getProcAddress(name: [*:0]const u8) callconv(.c) ?*const anyopaque {
    return glfw.getProcAddress(name);
}
