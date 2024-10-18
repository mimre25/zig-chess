const std = @import("std");

const Board = @import("board.zig").Board;
const Player = @import("player.zig").Player;
const Color = @import("player.zig").Color;
pub const MGame = @import("game.zig");

pub fn main() !void {
    const testGame = @import("test_game.zig").game1;
    try MGame.playGame(false, &testGame);

    try MGame.playGame(true, null);
}

pub fn clearLine(writer: anytype) !void {
    try writer.print("\x1b[1A\x1b[2K", .{});
}
