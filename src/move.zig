const std = @import("std");
const MBoard = @import("board.zig");
const MPieces = @import("pieces.zig");
const expect = std.testing.expect;
const Position = MBoard.Position;

const A = MBoard.A;
const B = MBoard.B;
const C = MBoard.C;
const D = MBoard.D;
const E = MBoard.E;
const F = MBoard.F;
const G = MBoard.G;
const H = MBoard.H;

const MoveType = enum {
    piece_move,
    castling,
    castling_long,
    resign,
    draw_offer,
    draw_accept,
    draw_decline,
};

pub const Move = union(MoveType) {
    piece_move: PieceMove,
    castling: bool,
    castling_long: bool,
    resign: bool,
    draw_offer: bool,
    draw_accept: bool,
    draw_decline: bool,
};

pub const PieceMove = struct {
    rank: u4,
    file: u4,
    piece: MPieces.PieceID,
    source_rank: ?u4 = null,
    source_file: ?u4 = null,
    promote_to: ?MPieces.PieceID = null,

    pub fn pos(self: PieceMove) Position {
        return Position{ .file = self.file, .rank = self.rank };
    }
    pub fn srcPos(self: PieceMove) Position {
        return Position{ .file = self.source_file.?, .rank = self.source_rank.? };
    }

    pub fn format(self: *const PieceMove, comptime fmt: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        if (fmt.len != 0) {
            std.fmt.invalidFmtError(fmt, self);
        }
        const a: u8 = 'a';
        var src_file: u8 = self.source_file orelse '!';
        if (src_file != ' ') {
            src_file += 'a';
        }
        return writer.print("{u} from {u}{any} to {u}{any}", .{ @intFromEnum(self.piece), src_file, self.source_rank, self.file + a, self.rank });
    }
};

pub const ParseError = error{
    InvalidPiece,
    InvalidRank,
    InvalidFile,
    InvalidCastling,
    InvalidMove,
};

pub const Map = std.StaticStringMap(u8);
const piece_map = Map.initComptime(.{
    .{ "K", 'K' },
    .{ "Q", 'Q' },
    .{ "R", 'R' },
    .{ "B", 'B' },
    .{ "N", 'N' },
});

fn parsePiece(input: u8) ParseError!u8 {
    const tmp = [_]u8{input};
    if (piece_map.has(&tmp)) {
        return piece_map.get(&tmp).?;
    } else if (input < 'a' and input > 'h') {
        return ParseError.InvalidPiece;
    }
    return 'P';
}

fn parseRank(input: u8) ParseError!u4 {
    const tmp = [_]u8{
        input,
    };
    const rank = std.fmt.parseInt(u4, &tmp, 10) catch {
        return ParseError.InvalidRank;
    };
    if (rank < 1 or rank > 8) {
        return ParseError.InvalidRank;
    }
    return rank;
}

fn parseFile(input: u8) ParseError!u4 {
    return switch (input) {
        'a' => A,
        'b' => B,
        'c' => C,
        'd' => D,
        'e' => E,
        'f' => F,
        'g' => G,
        'h' => H,
        else => ParseError.InvalidPiece,
    };
}

fn parsePieceMove(input: []const u8) ParseError!Move {
    const piece = try parsePiece(input[0]);
    var start_idx: u4 = 0;
    var source_file: ?u4 = null;
    var promote_to: ?MPieces.PieceID = null;
    if (piece == 'P') {
        // "dxc6"
        if (input[1] == 'x') {
            source_file = try parseFile(input[0]);
            start_idx = 2;
        }
        if (input[input.len - 2] == '=') {
            promote_to = @enumFromInt(input[input.len - 1]);
        }
    } else {
        start_idx = 1;
    }
    if (input[start_idx] == 'x') {
        // "Kxc6"
        start_idx += 1;
    }

    if ((input[start_idx] >= 'a' and input[start_idx] <= 'h') and (input[start_idx + 1] >= 'a' and input[start_idx + 1] <= 'h')) {
        // "Rfe8"
        source_file = try parseFile(input[start_idx]);
        start_idx += 1;
    }
    const file = try parseFile(input[start_idx]);
    const rank = try parseRank(input[start_idx + 1]);
    return Move{ .piece_move = PieceMove{
        .rank = rank,
        .file = file,
        .piece = @enumFromInt(piece),
        .source_file = source_file,
        .promote_to = promote_to,
    } };
}

fn parseCastling(input: []const u8) ParseError!Move {
    if (std.mem.eql(u8, input, "O-O")) {
        return Move{ .castling = true };
    } else if (std.mem.eql(u8, input, "O-O-O")) {
        return Move{ .castling_long = true };
    } else {
        return ParseError.InvalidCastling;
    }
}

pub fn parseMove(input: []const u8) ParseError!Move {
    //0-0
    //0-0-0
    // Regex: ^([KNQRB])?([a-h])?x?([a-h])([1-8]).*
    // Screw regex x)
    const trimmed_input = std.mem.sliceTo(input, '\n');
    if (trimmed_input.len < 2) {
        return ParseError.InvalidMove;
    }
    if (std.mem.eql(u8, trimmed_input, "resign")) {
        return Move{ .resign = true };
    } else if (std.mem.eql(u8, trimmed_input, "draw")) {
        return Move{ .draw_offer = true };
    } else if (std.mem.eql(u8, trimmed_input, "accept")) {
        return Move{ .draw_accept = true };
    } else if (std.mem.eql(u8, trimmed_input, "decline")) {
        return Move{ .draw_decline = true };
    } else if (input[0] == 'O') {
        return parseCastling(trimmed_input);
    } else {
        return try parsePieceMove(trimmed_input);
    }
}

test "parse algebraic notation" {
    try expect(std.meta.eql(parseMove("e4"), Move{ .piece_move = PieceMove{ .rank = 4, .file = E, .piece = MPieces.PieceID.pawn } }));
    try expect(std.meta.eql(parseMove("Nf3"), Move{ .piece_move = PieceMove{ .rank = 3, .file = F, .piece = MPieces.PieceID.knight } }));
    try expect(std.meta.eql(parseMove("Bb5"), Move{ .piece_move = PieceMove{ .rank = 5, .file = B, .piece = MPieces.PieceID.bishop } }));
    try expect(std.meta.eql(parseMove("Kxc6"), Move{ .piece_move = PieceMove{ .rank = 6, .file = C, .piece = MPieces.PieceID.king } }));
    try expect(std.meta.eql(parseMove("dxc6"), Move{ .piece_move = PieceMove{ .rank = 6, .file = C, .piece = MPieces.PieceID.pawn, .source_file = D } }));
    try expect(std.meta.eql(parseMove("Rb4+"), Move{ .piece_move = PieceMove{ .rank = 4, .file = B, .piece = MPieces.PieceID.rook } }));
    try expect(std.meta.eql(parseMove("Rfe8"), Move{ .piece_move = PieceMove{ .rank = 8, .file = E, .piece = MPieces.PieceID.rook, .source_file = F } }));
    try expect(std.meta.eql(parseMove("O-O"), Move{ .castling = true }));
    try expect(std.meta.eql(parseMove("O-O-O"), Move{ .castling_long = true }));
    try expect(std.meta.eql(parseMove("Qc2#"), Move{ .piece_move = PieceMove{ .rank = 2, .file = C, .piece = MPieces.PieceID.queen } }));
}
