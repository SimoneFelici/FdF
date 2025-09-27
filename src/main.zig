const std = @import("std");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

const Width: i32 = 800;
const Height: i32 = 600;
const Tile: f32 = 24.0;

fn draw_square(cx: f32, cy: f32, renderer: ?*c.SDL_Renderer) void {
    _ = c.SDL_SetRenderDrawColor(renderer, 0, 0, 255, 255);
    var rect: c.SDL_FRect = .{ .x = cx - Tile * 0.5, .y = cy - Tile * 0.5, .w = Tile, .h = Tile };
    _ = c.SDL_RenderRect(renderer, &rect);
}

fn gridDims(map: []const u8) struct { rows: usize, cols: usize } {
    var rows: usize = 0;
    var max_cols: usize = 0;

    var it = std.mem.tokenizeAny(u8, map, "\r\n");
    while (it.next()) |line| {
        if (line.len == 0) continue;
        rows += 1;

        var cols_this_row: usize = 0;
        var tok = std.mem.tokenizeAny(u8, line, " \t");
        while (tok.next()) |_| {
            cols_this_row += 1;
        }
        if (cols_this_row > max_cols) max_cols = cols_this_row;
    }

    return .{ .rows = rows, .cols = max_cols };
}

pub fn main() !void {
    var event: c.SDL_Event = undefined;
    var renderer: ?*c.SDL_Renderer = undefined;
    var window: ?*c.SDL_Window = undefined;
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const args = try std.process.argsAlloc(arena);
    defer std.process.argsFree(arena, args);

    if (args.len != 2) {
        std.debug.print("Wrong number of arguments\n", .{});
        std.process.exit(1);
    }
    const map = try std.fs.cwd().readFileAlloc(arena, args[1], 8 * 1024 * 1024);
    const map_specs = gridDims(map);

    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) {
        std.debug.print("SDL_Init failed: {s}\n", .{c.SDL_GetError().?});
        return error.SDLInitFailed;
    }
    defer c.SDL_Quit();

    if (!c.SDL_CreateWindowAndRenderer("FdF", Width, Height, 0, &window, &renderer)) {
        std.debug.print("Failed to create Window and Renderer: {s}\n", .{c.SDL_GetError().?});
        return error.SDLCreateFailed;
    }
    defer c.SDL_DestroyWindow(window);
    defer c.SDL_DestroyRenderer(renderer);
    _ = c.SDL_SetWindowResizable(window, true);

    var running: bool = true;
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

        _ = c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        _ = c.SDL_RenderClear(renderer);

        const grid_w: f32 = @as(f32, @floatFromInt(map_specs.cols)) * Tile;
        const grid_h: f32 = @as(f32, @floatFromInt(map_specs.rows)) * Tile;

        const origin_x: f32 = (@as(f32, Width) - grid_w) * 0.5 + Tile * 0.5;
        const origin_y: f32 = (@as(f32, Height) - grid_h) * 0.5 + Tile * 0.5;

        const step: f32 = Tile;

        var row: usize = 0;
        var it = std.mem.tokenizeAny(u8, map, "\r\n");
        while (it.next()) |line| : (row += 1) {
            if (line.len == 0) continue;
            var col: usize = 0;
            var tok = std.mem.tokenizeAny(u8, line, " \t");
            while (tok.next()) |num_str| : (col += 1) {
                const z = std.fmt.parseInt(i32, num_str, 10) catch 0;
                const x = origin_x + @as(f32, @floatFromInt(col)) * step;
                const y = origin_y + @as(f32, @floatFromInt(row)) * step - @as(f32, @floatFromInt(z));
                draw_square(x, y, renderer);
            }
        }

        _ = c.SDL_RenderPresent(renderer);
        c.SDL_Delay(10);
    }
}
