const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});
const dir = std.fs.cwd();

const Width = 640;
const Height = 480;

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const args = try std.process.argsAlloc(arena);
    defer std.process.argsFree(arena, args);

    if (args.len != 2) {
        std.debug.print("Wrong number of arguments\n", .{});
        std.process.exit(1);
    }
    const data = try std.fs.cwd().readFileAlloc(arena, args[1], 8 * 1024 * 1024);
    try stdout.print("File content:\n{s}\n", .{data});
    try stdout.flush();

    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) {
        std.debug.print("SDL_Init failed: {s}\n", .{c.SDL_GetError().?});
        return error.SDLInitFailed;
    }
    defer c.SDL_Quit();

    const win: ?*c.SDL_Window = c.SDL_CreateWindow("SDL3 Tutorial: Hello SDL3", Width, Height, c.SDL_WINDOW_RESIZABLE);
    if (win == null) {
        std.debug.print("SDL_CreateWindow failed: {s}\n", .{c.SDL_GetError()});
        return error.CreateWindowFailed;
    }
    defer c.SDL_DestroyWindow(win);

    const render: ?*c.SDL_Renderer = c.SDL_CreateRenderer(win.?, null);
    if (render == null) {
        std.debug.print("SDL_CreateRenderer failed: {s}\n", .{c.SDL_GetError()});
        return error.CreateRendererFailed;
    }
    defer c.SDL_DestroyRenderer(render);

    var running: bool = true;
    var event: c.SDL_Event = undefined;
    while (running) {
        while (c.SDL_PollEvent(&event)) {
            switch (event.type) {
                c.SDL_EVENT_QUIT => running = false,
                c.SDL_EVENT_KEY_DOWN => switch (event.key.key) {
                    c.SDLK_ESCAPE => running = false,
                    else => {},
                },
                else => {},
            }
        }
        _ = c.SDL_SetRenderDrawColor(render, 0, 0, 255, 0);
        _ = c.SDL_RenderClear(render);
        _ = c.SDL_RenderPresent(render);
    }
}
