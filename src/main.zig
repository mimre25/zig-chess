const std = @import("std");

const Board = @import("board.zig").Board;
const Player = @import("player.zig").Player;
const Color = @import("player.zig").Color;

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    // try clearLine(stdout);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const board = try Board.new(allocator);
    defer board.destory();
    var white = Player.new(Color.white);
    var black = Player.new(Color.black);
    Player.initPiecePointer(&white);
    Player.initPiecePointer(&black);
    for (0..16) |idx| {
        board.putPiece(white.pieces[idx].*);
        board.putPiece(black.pieces[idx].*);
    }
    try board.print(stdout);

    try bw.flush(); // don't forget to flush!
}

pub fn clearLine(writer: anytype) !void {
    try writer.print("\x1b[1A\x1b[2K", .{});
}
