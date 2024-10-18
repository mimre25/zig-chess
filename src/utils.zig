const std = @import("std");

pub fn ask_user(buf: []u8) ![]u8 {
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
