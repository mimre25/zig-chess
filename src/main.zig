const std = @import("std");

const Board = @import("board.zig").Board;
const Player = @import("player.zig").Player;
const Color = @import("player.zig").Color;
pub const game = @import("game.zig");

// fn read_input(stdout: anytype, bw: anytype) ![]u8 {
//     try stdout.print("Your move?\n", .{});
//     try bw.flush(); // don't forget to flush!
//     const stdin = std.io.getStdIn().reader();
//     var buf: [10]u8 = undefined;
//     const res = stdin.readUntilDelimiterOrEof(buf[0..], '\n') catch {
//         try stdout.print("Invalid Move.\nYour move?\n", .{});
//         return "e4";
//     };
//     return res.?;
// }
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
    try game.playGame(testGame);

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
        board.putPiece(white.pieces[idx]);
        board.putPiece(black.pieces[idx]);
    }
    try board.print(stdout);

    try bw.flush(); // don't forget to flush!
    var input_buffer: [10]u8 = undefined;
    const res = try ask_user(&input_buffer);
    const move = try game.parse_move(res);
    try stdout.print("your move: {}\n", .{move});
    try bw.flush(); // don't forget to flush!
}

pub fn clearLine(writer: anytype) !void {
    try writer.print("\x1b[1A\x1b[2K", .{});
}
