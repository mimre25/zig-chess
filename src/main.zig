const std = @import("std");

pub const MGame = @import("game.zig");

pub fn main() !void {
    try MGame.playGame(true, null);
}

pub fn clearLine(writer: anytype) !void {
    try writer.print("\x1b[1A\x1b[2K", .{});
}
