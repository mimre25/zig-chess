const std = @import("std");
const MBoard = @import("board.zig");
const MPieces = @import("pieces.zig");
const MPlayer = @import("player.zig");
const Player = MPlayer.Player;
const Board = MBoard.Board;
const expect = std.testing.expect;
const Color = MPlayer.Color;
const Position = MBoard.Position;
const askUser = @import("utils.zig").askUser;

const A = MBoard.A;
const B = MBoard.B;
const C = MBoard.C;
const D = MBoard.D;
const E = MBoard.E;
const F = MBoard.F;
const G = MBoard.G;
const H = MBoard.H;

fn absDiff(a: u4, b: u4) i5 {
    return @intCast(@abs(a - @as(i5, b)));
}

const GameResult = enum {
    draw,
    white_wins,
    black_wins,
    ongoing,
};

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

pub const Map = std.StaticStringMap(u8);
const piece_map = Map.initComptime(.{
    .{ "K", 'K' },
    .{ "Q", 'Q' },
    .{ "R", 'R' },
    .{ "B", 'B' },
    .{ "N", 'N' },
});

const ParseError = error{
    InvalidPiece,
    InvalidRank,
    InvalidFile,
    InvalidCastling,
    InvalidMove,
};

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
//TODO: make File and Rank type aliases
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

fn isCastlingPossible(player: *const Player, board: *const Board) bool {
    const rank = player.king.rank;
    std.debug.print("{},{},{},{},{},{}\n", .{ player.castlingPossible, player.king.file == E, player.rooks.items.len >= 1, player.rooks.items[0].file == H, board.isEmpty(F, rank), board.isEmpty(G, rank) });
    return player.castlingPossible and player.king.file == E and player.rooks.items.len >= 2 and player.rooks.items[1].file == H and board.isEmpty(F, rank) and board.isEmpty(G, rank);
}

fn isLongCastlingPossible(player: *const Player, board: *const Board) bool {
    const rank = player.king.rank;
    return player.castlingPossible and player.king.file == E and player.rooks.items.len >= 1 and player.rooks.items[0].file == A and board.isEmpty(B, rank) and board.isEmpty(C, rank) and board.isEmpty(D, rank);
}

fn isPieceMovePossible(player: *const Player, board: *const Board, move: *const PieceMove) bool {
    if (move.source_file == null or move.source_rank == null) {
        return false;
    }
    return switch (move.piece) {
        MPieces.PieceID.king => isKingMoveLegal(player, board, move),
        MPieces.PieceID.queen => isQueenMoveLegal(player, board, move),
        MPieces.PieceID.rook => isRookMoveLegal(player, board, move, true),
        MPieces.PieceID.knight => isKnightMoveLegal(player, move),
        MPieces.PieceID.bishop => isBishopMoveLegal(player, board, move, true),
        MPieces.PieceID.pawn => isPawnMoveLegal(player, board, move),
        inline else => unreachable,
    };
}

fn checkSourcePosition(src_pos: Position, pieces: std.ArrayList(*MPieces.Piece)) bool {
    var source_correct = false;
    for (pieces.items) |piece| {
        source_correct = source_correct or piece.pos().eq(src_pos);
    }
    return source_correct;
}

fn isKingMoveLegal(player: *const Player, board: *const Board, move: *const PieceMove) bool {
    const file_diff: i5 = absDiff(move.file, player.king.file);
    const rank_diff: i5 = absDiff(move.rank, player.king.rank);
    if (file_diff > 1 or rank_diff > 1) {
        return false;
    }
    const target_piece = board.getSquare(move.file, move.rank);
    if (target_piece.piece == MPieces.PieceID.empty) {
        return true;
    } else {
        return target_piece.color != player.color;
    }
    return false;
}
fn isQueenMoveLegal(player: *const Player, board: *const Board, move: *const PieceMove) bool {
    if (!checkSourcePosition(move.srcPos(), player.queens)) {
        return false;
    }

    return isRookMoveLegal(player, board, move, false) or isBishopMoveLegal(player, board, move, false);
}
fn isRookMoveLegal(player: *const Player, board: *const Board, move: *const PieceMove, checkPiece: bool) bool {
    if (checkPiece and !checkSourcePosition(move.srcPos(), player.rooks)) {
        return false;
    }
    var rank: i5 = move.source_rank.?;
    var file: i5 = move.source_file.?;
    if (move.rank == move.source_rank) {
        const file_dir: i4 = if (move.file > move.source_file.?) 1 else -1;
        file += file_dir;
        while (file < move.file) : (file += file_dir) {
            if (!board.isEmpty(@intCast(file), @intCast(rank))) {
                return false;
            }
        }
    } else if (move.file == move.source_file) {
        const rank_dir: i4 = if (move.rank > move.source_rank.?) 1 else -1;
        rank += rank_dir;
        while (rank < move.rank) : (rank += rank_dir) {
            if (!board.isEmpty(@intCast(file), @intCast(rank))) {
                return false;
            }
        }
    } else {
        return false;
    }
    return board.isEmpty(move.file, move.rank) or board.getSquare(move.file, move.rank).color != player.color;
}
fn isKnightMoveLegal(player: *const Player, move: *const PieceMove) bool {
    if (!checkSourcePosition(move.srcPos(), player.knights)) {
        return false;
    }
    const file_diff: i5 = absDiff(move.file, move.source_file.?);
    const rank_diff: i5 = absDiff(move.rank, move.source_rank.?);
    return (file_diff == 2 and rank_diff == 1) or (file_diff == 1 and rank_diff == 2);
}

fn isBishopMoveLegal(player: *const Player, board: *const Board, move: *const PieceMove, checkPiece: bool) bool {
    if (checkPiece and !checkSourcePosition(move.srcPos(), player.bishops)) {
        return false;
    }
    const rank_diff: i5 = absDiff(move.source_rank.?, move.rank);
    const file_diff: i5 = absDiff(move.source_file.?, move.file);
    if (rank_diff != file_diff) {
        // not a diagonal
        return false;
    }
    const rank_dir: i4 = if (move.rank > move.source_rank.?) 1 else -1;
    const file_dir: i4 = if (move.file > move.source_file.?) 1 else -1;
    var rank: i5 = @intCast(move.source_rank.?);
    var file: i5 = @intCast(move.source_file.?);
    rank += rank_dir;
    file += file_dir;
    while (rank != move.rank and file != move.file) {
        if (!board.isEmpty(@intCast(file), @intCast(rank))) {
            return false;
        }
        rank += rank_dir;
        file += file_dir;
    }

    return board.isEmpty(move.file, move.rank) or board.getSquare(move.file, move.rank).color != player.color;
}
fn isPawnMoveLegal(player: *const Player, board: *const Board, move: *const PieceMove) bool {
    // TODO: make sure player has a pawn on the source square
    //normal move
    if (move.source_file == move.file) {
        if (move.rank == 8 or move.rank == 1) {
            //promotion move
            return true;
        }
        if (board.isEmpty(move.file, move.rank)) {
            if (absDiff(move.rank, move.source_rank.?) == 1) {
                return true;
            }
            if (absDiff(move.rank, move.source_rank.?) == 2) {
                return (player.color == Color.white and move.source_rank == 2 and board.isEmpty(move.file, 3)) or (player.color == Color.black and move.source_rank == 7 and board.isEmpty(move.file, 6));
            }
        }
    } else {
        if (move.rank == 8 or move.rank == 1) {
            return true;
        }
        if (board.getSquare(move.file, move.rank).color != player.color and absDiff(move.source_file.?, move.file) == 1) {
            //capture move
            return true;
        }
    }
    return false;
}

fn isMoveLegal(move: Move, board: *Board, player: *Player) bool {
    //player is the player that tries to make the move
    switch (move) {
        .piece_move => return isPieceMovePossible(player, board, &move.piece_move),
        .castling => return isCastlingPossible(player, board),
        .castling_long => return isLongCastlingPossible(player, board),
        inline else => unreachable,
    }

    return true;
}

fn findPawnSourcePosition(move: *PieceMove, player: *Player) void {
    if (move.source_file == null) {
        move.source_file = move.file; // otherwise source file is given
    }
    if (move.source_rank == null) {
        if (player.color == Color.white and move.rank == 4) {
            for (player.pawns.items) |pawn| {
                if (pawn.file == move.file and pawn.rank == 2) {
                    move.source_rank = 2;
                }
            }
        } else if (player.color == Color.black and move.rank == 5) {
            for (player.pawns.items) |pawn| {
                if (pawn.file == move.file and pawn.rank == 7) {
                    move.source_rank = 7;
                }
            }
        }
        if (move.source_rank == null) {
            move.source_rank = if (player.color == Color.white) move.rank - 1 else move.rank + 1;
        }
    }
}

fn findQueenSourcePosition(move: *PieceMove, player: *Player, board: *Board) void {
    for (player.queens.items) |queen| {
        if (queen.file == move.file) {
            move.source_file = queen.file;
            move.source_rank = queen.rank;
            if (isRookMoveLegal(player, board, move, false)) {
                return;
            }
        }
        if (queen.rank == move.rank) {
            move.source_file = queen.file;
            move.source_rank = queen.rank;
            if (isRookMoveLegal(player, board, move, false)) {
                return;
            }
        }
        const rank_diff1: i5 = absDiff(queen.rank, move.rank);
        const file_diff1: i5 = absDiff(queen.file, move.file);

        if (rank_diff1 == file_diff1) {
            move.source_file = queen.file;
            move.source_rank = queen.rank;
            if (isBishopMoveLegal(player, board, move, false)) {
                return;
            }
        }
    }
}
fn findRookSourcePosition(move: *PieceMove, player: *Player, board: *Board) void {
    //TODO: "Rb1" is legal input if we have a rook both on A1 and F1 and
    //// there is a piece on C1 or D1 or E1, becuase then I can only be the rook form A1
    for (player.rooks.items) |rook| {
        if (rook.file == move.file) {
            move.source_file = rook.file;
            move.source_rank = rook.rank;
            if (isRookMoveLegal(player, board, move, false)) {
                return;
            }
        }
        if (rook.rank == move.rank) {
            move.source_file = rook.file;
            move.source_rank = rook.rank;
            if (isRookMoveLegal(player, board, move, false)) {
                return;
            }
        }
    }
}
fn findKnightSourcePosition(move: *PieceMove, player: *Player) void {
    for (player.knights.items) |knight| {
        const file_diff1: i5 = absDiff(move.file, knight.file);
        const rank_diff1: i5 = absDiff(move.rank, knight.rank);
        if ((file_diff1 == 2 and rank_diff1 == 1) or (file_diff1 == 1 and rank_diff1 == 2)) {
            move.source_file = knight.file;
            move.source_rank = knight.rank;
            return;
        }
    }
}
fn findBishopSourcePosition(move: *PieceMove, player: *Player) void {
    for (player.bishops.items) |bishop| {
        const rank_diff1: i5 = absDiff(bishop.rank, move.rank);
        const file_diff1: i5 = absDiff(bishop.file, move.file);

        if (rank_diff1 == file_diff1) {
            move.source_file = bishop.file;
            move.source_rank = bishop.rank;
            return;
        }
    }
}

fn findSourcePosition(move: *Move, player: *Player, board: *Board) void {
    switch (move.*) {
        .castling => return,
        .castling_long => return,
        .piece_move => {
            var _move = &move.piece_move;
            if (_move.source_file != null and _move.source_rank != null) {
                return;
            }
            switch (_move.piece) {
                MPieces.PieceID.king => {
                    _move.source_file = player.king.file;
                    _move.source_rank = player.king.rank;
                },
                MPieces.PieceID.queen => findQueenSourcePosition(_move, player, board),
                MPieces.PieceID.rook => findRookSourcePosition(_move, player, board),
                MPieces.PieceID.knight => findKnightSourcePosition(_move, player),
                MPieces.PieceID.bishop => findBishopSourcePosition(_move, player),
                MPieces.PieceID.pawn => findPawnSourcePosition(_move, player),
                inline else => unreachable,
            }
            return;
        },
        inline else => unreachable,
    }
}

// general algo:
// 1. parse move
// 2. find source if not given
// 3. check legality
// 4. execute move
// 5. log move

test "Is Move Legal" {
    const allocator = std.testing.allocator;

    // init TODO: make function
    var white = try Player.new(Color.white, allocator);
    var black = try Player.new(Color.black, allocator);
    var board = try Board.new(allocator, &white, &black);
    defer board.destroy();
    try white.initPieces();
    try black.initPieces();
    defer white.destroy();
    defer black.destroy();
    for (0..16) |idx| {
        board.putPiece(&white.pieces[idx]);
        board.putPiece(&black.pieces[idx]);
    }

    // done init

    try expect(!isMoveLegal(Move{ .castling = true }, &board, &white));
    try expect(!isMoveLegal(Move{ .castling = true }, &board, &white));
    try expect(isMoveLegal(Move{ .piece_move = PieceMove{ .rank = 4, .file = E, .piece = MPieces.PieceID.pawn, .source_rank = 2, .source_file = E } }, &board, &white));
    try expect(isMoveLegal(Move{ .piece_move = PieceMove{ .rank = 4, .file = A, .piece = MPieces.PieceID.pawn, .source_rank = 2, .source_file = A } }, &board, &white));
    try expect(isMoveLegal(Move{ .piece_move = PieceMove{ .rank = 3, .file = A, .piece = MPieces.PieceID.pawn, .source_rank = 2, .source_file = A } }, &board, &white));
    try expect(isMoveLegal(Move{ .piece_move = PieceMove{ .rank = 3, .file = C, .piece = MPieces.PieceID.knight, .source_rank = 1, .source_file = B } }, &board, &white));
    var board2 = try Board.new(allocator, &white, &black);
    defer board2.destroy();
    board2.putPiece(white.rooks.items[0]);
    try expect(isMoveLegal(Move{ .piece_move = PieceMove{ .rank = 7, .file = A, .piece = MPieces.PieceID.rook, .source_rank = 1, .source_file = A } }, &board2, &white));
    board2.putPiece(black.pawns.items[0]);
    try expect(isMoveLegal(Move{ .piece_move = PieceMove{ .rank = 7, .file = A, .piece = MPieces.PieceID.rook, .source_rank = 1, .source_file = A } }, &board2, &white));
    white.pawns.items[0].rank = 7;
    board2.putPiece(white.pawns.items[0]);
    try expect(!isMoveLegal(Move{ .piece_move = PieceMove{ .rank = 7, .file = A, .piece = MPieces.PieceID.rook, .source_rank = 1, .source_file = A } }, &board2, &white));

    board2.putPiece(white.bishops.items[0]);
    try expect(isMoveLegal(Move{ .piece_move = PieceMove{ .rank = 5, .file = G, .piece = MPieces.PieceID.bishop, .source_rank = 1, .source_file = C } }, &board2, &white));
    try expect(!isMoveLegal(Move{ .piece_move = PieceMove{ .rank = 5, .file = H, .piece = MPieces.PieceID.bishop, .source_rank = 1, .source_file = C } }, &board2, &white));
}

fn makeMove(move: *Move, player: *Player, board: *Board) !void {
    switch (move.*) {
        .piece_move => |pmove| {
            var piece = try player.findPiece(&pmove.srcPos());
            board.evictField(piece.file, piece.rank);
            if (pmove.promote_to != null) {
                try player.promote(piece, pmove.promote_to.?);
            }
            piece.file = (move.piece_move.file);
            piece.rank = (move.piece_move.rank);
            board.putPiece(piece);
        },
        .castling => {
            board.evictField(player.king.file, player.king.rank);
            board.evictField(player.rooks.items[1].file, player.rooks.items[1].rank);
            player.king.file = G;
            player.rooks.items[1].file = F;
            board.putPiece(player.king);
            board.putPiece(player.rooks.items[1]);
        },
        .castling_long => {
            board.evictField(player.king.file, player.king.rank);
            board.evictField(player.rooks.items[0].file, player.rooks.items[0].rank);
            player.king.file = C;
            player.rooks.items[0].file = D;
            board.putPiece(player.king);
            board.putPiece(player.rooks.items[0]);
        },
        inline else => unreachable,
    }
}

fn playRound(move_input: []const u8, current_player: *Player, board: *Board, stdout: anytype) !GameResult {
    std.debug.print("Move: {s}\n", .{move_input});
    var move = try parseMove(move_input);
    switch (move) {
        .draw_offer => {
            try stdout.print("{s} offers a draw\n", .{@tagName(current_player.color)});
            return GameResult.ongoing;
        },
        .draw_accept => {
            try stdout.print("Draw accepted\n", .{});
            return GameResult.draw;
        },
        .draw_decline => {
            try stdout.print("Draw declined\n", .{});
            return GameResult.ongoing;
        },
        .resign => {
            try stdout.print("{s} resigns\n", .{@tagName(current_player.color)});
            switch (current_player.color) {
                Color.white => return GameResult.black_wins,
                Color.black => return GameResult.white_wins,
            }
        },
        inline else => {},
    }
    findSourcePosition(&move, current_player, board);
    try expect(isMoveLegal(move, board, current_player));

    try makeMove(&move, current_player, board);

    return GameResult.ongoing;
}

pub fn playGame(interactive: bool, game: ?[]const []const u8) !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // init TODO: make function
    var white = try Player.new(Color.white, allocator);
    var black = try Player.new(Color.black, allocator);
    var board = try Board.new(allocator, &white, &black);
    defer board.destroy();
    try white.initPieces();
    try black.initPieces();
    defer white.destroy();
    defer black.destroy();
    for (0..16) |idx| {
        board.putPiece(&white.pieces[idx]);
        board.putPiece(&black.pieces[idx]);
    }
    var i: u8 = 0;
    var current_player: *Player = undefined;
    var game_result: GameResult = GameResult.ongoing;
    if (interactive) {
        while (game_result == GameResult.ongoing) {
            try board.print(stdout);
            try bw.flush();
            var input_buffer: [10]u8 = undefined;
            const move_input = try askUser(&input_buffer);

            if (@mod(i, 2) == 0) {
                current_player = &white;
            } else {
                current_player = &black;
            }
            game_result = playRound(move_input, current_player, &board, stdout) catch |err| {
                switch (err) {
                    ParseError.InvalidRank => try stdout.print("Parser error: {}\n", .{err}),
                    ParseError.InvalidFile => try stdout.print("Parser error: {}\n", .{err}),
                    ParseError.InvalidPiece => try stdout.print("Parser error: {}\n", .{err}),
                    ParseError.InvalidCastling => try stdout.print("Parser error: {}\n", .{err}),
                    inline else => try stdout.print("Unknown error {}\n", .{err}),
                }
                continue;
            };
            i += 1;
        }
    } else {
        for (game.?) |move_input| {
            try board.print(stdout);
            try bw.flush();

            if (@mod(i, 2) == 0) {
                current_player = &white;
            } else {
                current_player = &black;
            }
            game_result = try playRound(move_input, current_player, &board, stdout);
            i += 1;
        }
    }
    try board.print(stdout);
    try stdout.print("Game Over. {s}\n", .{@tagName(game_result)});
    try bw.flush();
}

test "parse game1" {
    const game = @import("test_game.zig").game1;
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    const allocator = std.testing.allocator;

    // init TODO: make function
    var white = try Player.new(Color.white, allocator);
    var black = try Player.new(Color.black, allocator);
    var board = try Board.new(allocator, &white, &black);
    defer board.destroy();
    try white.initPieces();
    try black.initPieces();
    defer white.destroy();
    defer black.destroy();
    for (0..16) |idx| {
        board.putPiece(&white.pieces[idx]);
        board.putPiece(&black.pieces[idx]);
    }
    var i: u4 = 0;
    var current_player: *Player = undefined;
    for (game) |move_input| {
        try board.print(stdout);
        try bw.flush();

        std.debug.print("Move: {s}\n", .{move_input});
        var move = try parseMove(move_input);

        if (@mod(i, 2) == 0) {
            current_player = &white;
        } else {
            current_player = &black;
        }
        findSourcePosition(&move, current_player, &board);
        std.debug.print("Move: {}\n", .{move});
        try expect(isMoveLegal(move, &board, current_player));

        try makeMove(&move, current_player, &board);
        i += 1;
    }
}
