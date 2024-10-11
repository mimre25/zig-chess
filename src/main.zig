const std = @import("std");

const Board = @import("board.zig").Board;
const Player = @import("player.zig").Player;
const Color = @import("player.zig").Color;
pub const MGame = @import("game.zig");

fn ask_user(buf: []u8) ![]u8 {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    try stdout.print("Your move?\n", .{});

    const res = stdin.readUntilDelimiter(buf[0..], '\n') catch |err| {
        // handle stream to long error
        std.debug.print("error: {}\n", .{err});
        return buf;
    };
    std.debug.print("values: {s}\n", .{res});
    return buf;
}

pub fn main() !void {
    const testGame = @import("test_game.zig").game1;
    try MGame.playGame(testGame);

    // const stdout_file = std.io.getStdOut().writer();
    // var bw = std.io.bufferedWriter(stdout_file);
    // const stdout = bw.writer();
    //
    // // try clearLine(stdout);
    //
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // const allocator = gpa.allocator();
    //
    // var white = try Player.new(Color.white, allocator);
    // var black = try Player.new(Color.black, allocator);
    // const board = try Board.new(allocator, &white, &black);
    // defer board.destroy();
    // try white.initPieces();
    // try black.initPieces();
    // for (0..16) |idx| {
    //     board.putPiece(&white.pieces[idx]);
    //     board.putPiece(&black.pieces[idx]);
    // }
    // try board.print(stdout);
    //
    // try bw.flush(); // don't forget to flush!
    // var input_buffer: [10]u8 = undefined;
    // const res = try ask_user(&input_buffer);
    // const move = try MGame.parse_move(res);
    // try stdout.print("your move: {}\n", .{move});
    // try bw.flush(); // don't forget to flush!
}

pub fn clearLine(writer: anytype) !void {
    try writer.print("\x1b[1A\x1b[2K", .{});
}
