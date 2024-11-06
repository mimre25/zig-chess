const std = @import("std");

pub const MGame = @import("game.zig");

pub fn main() !void {
    const test_game = @import("test_game.zig").game1;
    try MGame.playGame(false, &test_game);

    try MGame.playGame(true, null);
}

pub fn clearLine(writer: anytype) !void {
    try writer.print("\x1b[1A\x1b[2K", .{});
}
