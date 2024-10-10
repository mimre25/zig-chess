const std = @import("std");
const pieces = @import("pieces.zig");

const TPiece = pieces.TPiece;
const Piece = pieces.Piece;
var Empty = pieces.Empty;

pub const A = 0;
pub const B = 1;
pub const C = 2;
pub const D = 3;
pub const E = 4;
pub const F = 5;
pub const G = 6;
pub const H = 7;

pub const Position = struct {
    rank: u4,
    file: u4,

    pub fn eq(self: Position, other: Position) bool {
        return self.rank == other.rank and self.file == other.file;
    }
};

pub const Rank = struct {
    files: []*Piece,
    num: u4,

    pub fn new(rankNumber: u4, allocator: std.mem.Allocator) !Rank {
        const rank = Rank{ .files = try allocator.alloc(*Piece, 8), .num = rankNumber };
        std.mem.copyForwards(*Piece, rank.files, &[_]*Piece{
            &Empty,
        } ** 8);
        return rank;
    }

    pub fn destroy(self: Rank, allocator: std.mem.Allocator) void {
        allocator.free(self.files);
    }

    pub fn evictField(self: Rank, file: u4) void {
        self.files[file] = &Empty;
    }

    pub fn putPiece(self: Rank, piece: *Piece) void {
        self.files[piece.file()] = piece;
    }

    pub fn print(self: Rank, writer: anytype) !void {
        for (self.files[0..], 0..) |c, idx| {
            // if (c != BS and c != WS) {
            if (@mod(idx + self.num, 2) == 0) {
                // white background
                try writer.print("\u{001b}[47m", .{});
            } else {
                // black background
                try writer.print("\u{001b}[40m", .{});
            }

            try writer.print("{u}", .{c.icon()});
            try writer.print(" ", .{});
            try writer.print("\u{001b}[0m", .{});
        }
        try writer.print("\n", .{});
    }

    pub fn isEmpty(self: Rank, file: u4) bool {
        return self.files[file] == &Empty;
    }
};

pub const Board = struct {
    ranks: []Rank,
    allocator: std.mem.Allocator,

    pub fn new(allocator: std.mem.Allocator) !Board {
        var board = Board{
            .ranks = try allocator.alloc(Rank, 9),
            .allocator = allocator,
        };
        // hack ~ using 9 ranks so that we can denote ranks 1-indexed without
        // useing @"1" as variable name
        for (0..9) |i| {
            board.ranks[i] = try Rank.new(@intCast(i), allocator);
        }
        return board;
    }

    pub fn destory(self: Board) void {
        for (self.ranks) |row| {
            row.destroy(self.allocator);
        }
        self.allocator.free(self.ranks);
    }

    pub fn evictField(self: Board, file: u4, rank: u4) void {
        self.ranks[rank].evictField(file);
    }

    pub fn putPiece(self: Board, piece: *Piece) void {
        const currentPiece = self.getPiece(piece.file(), piece.rank());
        switch (currentPiece.*) {
            .empty => {},
            inline else => |*case| {
                case.file = std.math.maxInt(u4);
                case.rank = std.math.maxInt(u4);
            },
        }
        self.ranks[piece.rank()].putPiece(piece);
    }

    pub fn getPiece(self: Board, file: u4, rank: u4) *Piece {
        return self.ranks[rank].files[file];
    }

    pub fn print(self: Board, writer: anytype) !void {
        var i: usize = 9;
        while (i > 1) {
            i -= 1;
            try writer.print("{} ", .{i});
            try self.ranks[i].print(writer);
        }
        try writer.print("  A B C D E F G H\n", .{});
    }

    pub fn isEmpty(self: Board, file: u4, rank: u4) bool {
        return self.ranks[rank].isEmpty(file);
    }
};
