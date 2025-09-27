const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

const Width = 640;
const Height = 480;

pub fn main() !void {
    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) {
        std.debug.print("SDL_Init failed: {s}\n", .{c.SDL_GetError()});
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
