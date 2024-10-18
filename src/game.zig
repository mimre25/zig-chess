const std = @import("std");
const MBoard = @import("board.zig");
const MPieces = @import("pieces.zig");
const MPlayer = @import("player.zig");
const Player = MPlayer.Player;
const Board = MBoard.Board;
const expect = std.testing.expect;
const Color = MPlayer.Color;
const Position = MBoard.Position;

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

const MoveType = enum {
    pieceMove,
    castling,
    castlingLong,
    resign,
    drawOffer,
    drawAccept,
    drawDecline,
};

pub const Move = union(MoveType) {
    pieceMove: PieceMove,
    castling: bool,
    castlingLong: bool,
    resign: bool,
    drawOffer: bool,
    drawAccept: bool,
    drawDecline: bool,
};

pub const PieceMove = struct {
    rank: u4,
    file: u4,
    piece: MPieces.PieceID,
    sourceRank: ?u4 = null,
    sourceFile: ?u4 = null,
    promoteTo: ?MPieces.PieceID = null,

    pub fn pos(self: PieceMove) Position {
        return Position{ .file = self.file, .rank = self.rank };
    }
    pub fn srcPos(self: PieceMove) Position {
        return Position{ .file = self.sourceFile.?, .rank = self.sourceRank.? };
    }

    pub fn format(self: *const PieceMove, comptime fmt: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        if (fmt.len != 0) {
            std.fmt.invalidFmtError(fmt, self);
        }
        const a: u8 = 'a';
        var srcFile: u8 = self.sourceFile orelse '!';
        if (srcFile != ' ') {
            srcFile += 'a';
        }
        return writer.print("{u} from {u}{any} to {u}{any}", .{ @intFromEnum(self.piece), srcFile, self.sourceRank, self.file + a, self.rank });
    }
};

pub const Map = std.StaticStringMap(u8);
const pieceMap = Map.initComptime(.{
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
};

fn parse_piece(input: u8) ParseError!u8 {
    const tmp = [_]u8{input};
    if (pieceMap.has(&tmp)) {
        return pieceMap.get(&tmp).?;
    } else if (input < 'a' and input > 'h') {
        return ParseError.InvalidPiece;
    }
    return 'P';
}

fn parse_rank(input: u8) ParseError!u4 {
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

fn parse_file(input: u8) ParseError!u4 {
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
fn parse_piece_move(input: []const u8) ParseError!Move {
    const piece = try parse_piece(input[0]);
    var startIdx: u4 = 0;
    var sourceFile: ?u4 = null;
    var promoteTo: ?MPieces.PieceID = null;
    if (piece == 'P') {
        // "dxc6"
        if (input[1] == 'x') {
            sourceFile = try parse_file(input[0]);
            startIdx = 2;
        }
        if (input[input.len - 2] == '=') {
            promoteTo = @enumFromInt(input[input.len - 1]);
        }
    } else {
        startIdx = 1;
    }
    if (input[startIdx] == 'x') {
        // "Kxc6"
        startIdx += 1;
    }

    if ((input[startIdx] >= 'a' and input[startIdx] <= 'h') and (input[startIdx + 1] >= 'a' and input[startIdx + 1] <= 'h')) {
        // "Rfe8"
        sourceFile = try parse_file(input[startIdx]);
        startIdx += 1;
    }
    const file = try parse_file(input[startIdx]);
    const rank = try parse_rank(input[startIdx + 1]);
    return Move{ .pieceMove = PieceMove{
        .rank = rank,
        .file = file,
        .piece = @enumFromInt(piece),
        .sourceFile = sourceFile,
        .promoteTo = promoteTo,
    } };
}

fn parse_castling(input: []const u8) ParseError!Move {
    if (std.mem.eql(u8, input, "O-O")) {
        return Move{ .castling = true };
    } else if (std.mem.eql(u8, input, "O-O-O")) {
        return Move{ .castlingLong = true };
    } else {
        return ParseError.InvalidCastling;
    }
}

pub fn parse_move(input: []const u8) ParseError!Move {
    //0-0
    //0-0-0
    // Regex: ^([KNQRB])?([a-h])?x?([a-h])([1-8]).*
    // Screw regex x)
    const trimmed_input = std.mem.sliceTo(input, '\n');
    if (std.mem.eql(u8, trimmed_input, "resign")) {
        return Move{ .resign = true };
    } else if (std.mem.eql(u8, trimmed_input, "draw")) {
        return Move{ .drawOffer = true };
    } else if (std.mem.eql(u8, trimmed_input, "accept")) {
        return Move{ .drawAccept = true };
    } else if (std.mem.eql(u8, trimmed_input, "decline")) {
        return Move{ .drawDecline = true };
    } else if (input[0] == 'O') {
        return parse_castling(trimmed_input);
    } else {
        return try parse_piece_move(trimmed_input);
    }
}

test "parse algebraic notation" {
    try expect(std.meta.eql(parse_move("e4"), Move{ .pieceMove = PieceMove{ .rank = 4, .file = E, .piece = 'P' } }));
    try expect(std.meta.eql(parse_move("Nf3"), Move{ .pieceMove = PieceMove{ .rank = 3, .file = F, .piece = 'N' } }));
    try expect(std.meta.eql(parse_move("Bb5"), Move{ .pieceMove = PieceMove{ .rank = 5, .file = B, .piece = 'B' } }));
    try expect(std.meta.eql(parse_move("Kxc6"), Move{ .pieceMove = PieceMove{ .rank = 6, .file = C, .piece = 'K' } }));
    try expect(std.meta.eql(parse_move("dxc6"), Move{ .pieceMove = PieceMove{ .rank = 6, .file = C, .piece = 'P', .sourceFile = D } }));
    try expect(std.meta.eql(parse_move("Rb4+"), Move{ .pieceMove = PieceMove{ .rank = 4, .file = B, .piece = 'R' } }));
    try expect(std.meta.eql(parse_move("Rfe8"), Move{ .pieceMove = PieceMove{ .rank = 8, .file = E, .piece = 'R', .sourceFile = F } }));
    try expect(std.meta.eql(parse_move("O-O"), Move{ .castling = true }));
    try expect(std.meta.eql(parse_move("O-O-O"), Move{ .castlingLong = true }));
    try expect(std.meta.eql(parse_move("Qc2#"), Move{ .pieceMove = PieceMove{ .rank = 2, .file = C, .piece = 'Q' } }));
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

fn checkSourcePosition(srcPos: Position, pieces: std.ArrayList(*MPieces.Piece)) bool {
    var sourceCorrect = false;
    for (pieces.items) |piece| {
        sourceCorrect = sourceCorrect or piece.pos().eq(srcPos);
    }
    return sourceCorrect;
}

fn isKingMoveLegal(player: *const Player, board: *const Board, move: *const PieceMove) bool {
    const fileDiff: i5 = absDiff(move.file, player.king.file);
    const rankDiff: i5 = absDiff(move.rank, player.king.rank);
    if (fileDiff > 1 or rankDiff > 1) {
        return false;
    }
    const targetPiece = board.getSquare(move.file, move.rank);
    if (targetPiece.piece == MPieces.PieceID.empty) {
        return true;
    } else {
        return targetPiece.color != player.color;
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
    var rank: i5 = move.sourceRank.?;
    var file: i5 = move.sourceFile.?;
    if (move.rank == move.sourceRank) {
        const fileDir: i4 = if (move.file > move.sourceFile.?) 1 else -1;
        file += fileDir;
        while (file < move.file) : (file += fileDir) {
            if (!board.isEmpty(@intCast(file), @intCast(rank))) {
                return false;
            }
        }
    } else if (move.file == move.sourceFile) {
        const rankDir: i4 = if (move.rank > move.sourceRank.?) 1 else -1;
        rank += rankDir;
        while (rank < move.rank) : (rank += rankDir) {
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
    const fileDiff: i5 = absDiff(move.file, move.sourceFile.?);
    const rankDiff: i5 = absDiff(move.rank, move.sourceRank.?);
    return (fileDiff == 2 and rankDiff == 1) or (fileDiff == 1 and rankDiff == 2);
}

fn isBishopMoveLegal(player: *const Player, board: *const Board, move: *const PieceMove, checkPiece: bool) bool {
    if (checkPiece and !checkSourcePosition(move.srcPos(), player.bishops)) {
        return false;
    }
    const rankDiff: i5 = absDiff(move.sourceRank.?, move.rank);
    const fileDiff: i5 = absDiff(move.sourceFile.?, move.file);
    if (rankDiff != fileDiff) {
        // not a diagonal
        return false;
    }
    const rankDir: i4 = if (move.rank > move.sourceRank.?) 1 else -1;
    const fileDir: i4 = if (move.file > move.sourceFile.?) 1 else -1;
    var rank: i5 = @intCast(move.sourceRank.?);
    var file: i5 = @intCast(move.sourceFile.?);
    rank += rankDir;
    file += fileDir;
    while (rank != move.rank and file != move.file) {
        if (!board.isEmpty(@intCast(file), @intCast(rank))) {
            return false;
        }
        rank += rankDir;
        file += fileDir;
    }

    return board.isEmpty(move.file, move.rank) or board.getSquare(move.file, move.rank).color != player.color;
}
fn isPawnMoveLegal(player: *const Player, board: *const Board, move: *const PieceMove) bool {
    // TODO: make sure player has a pawn on the source square
    //normal move
    if (move.sourceFile == move.file) {
        if (move.rank == 8 or move.rank == 1) {
            //promotion move
            return true;
        }
        if (board.isEmpty(move.file, move.rank)) {
            if (absDiff(move.rank, move.sourceRank.?) == 1) {
                return true;
            }
            if (absDiff(move.rank, move.sourceRank.?) == 2) {
                return (player.color == Color.white and move.sourceRank == 2 and board.isEmpty(move.file, 3)) or (player.color == Color.black and move.sourceRank == 7 and board.isEmpty(move.file, 6));
            }
        }
    } else {
        if (move.rank == 8 or move.rank == 1) {
            return true;
        }
        if (board.getSquare(move.file, move.rank).color != player.color and absDiff(move.sourceFile.?, move.file) == 1) {
            //capture move
            return true;
        }
    }
    return false;
}

fn isMoveLegal(move: Move, board: *Board, player: *Player) bool {
    //player is the player that tries to make the move
    switch (move) {
        .pieceMove => return isPieceMovePossible(player, board, &move.pieceMove),
        .castling => return isCastlingPossible(player, board),
        .castlingLong => return isLongCastlingPossible(player, board),
        inline else => unreachable,
    }

    return true;
}

fn findPawnSourcePosition(move: *PieceMove, player: *Player) void {
    if (move.sourceFile == null) {
        move.sourceFile = move.file; // otherwise source file is given
    }
    if (move.sourceRank == null) {
        if (player.color == Color.white and move.rank == 4) {
            for (player.pawns.items) |pawn| {
                if (pawn.file == move.file and pawn.rank == 2) {
                    move.sourceRank = 2;
                }
            }
        } else if (player.color == Color.black and move.rank == 5) {
            for (player.pawns.items) |pawn| {
                if (pawn.file == move.file and pawn.rank == 7) {
                    move.sourceRank = 7;
                }
            }
        }
        if (move.sourceRank == null) {
            move.sourceRank = if (player.color == Color.white) move.rank - 1 else move.rank + 1;
        }
    }
}

fn findQueenSourcePosition(move: *PieceMove, player: *Player, board: *Board) void {
    for (player.queens.items) |queen| {
        if (queen.file == move.file) {
            move.sourceFile = queen.file;
            move.sourceRank = queen.rank;
            if (isRookMoveLegal(player, board, move, false)) {
                return;
            }
        }
        if (queen.rank == move.rank) {
            move.sourceFile = queen.file;
            move.sourceRank = queen.rank;
            if (isRookMoveLegal(player, board, move, false)) {
                return;
            }
        }
        const rankDiff1: i5 = absDiff(queen.rank, move.rank);
        const fileDiff1: i5 = absDiff(queen.file, move.file);

        if (rankDiff1 == fileDiff1) {
            move.sourceFile = queen.file;
            move.sourceRank = queen.rank;
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
            move.sourceFile = rook.file;
            move.sourceRank = rook.rank;
            if (isRookMoveLegal(player, board, move, false)) {
                return;
            }
        }
        if (rook.rank == move.rank) {
            move.sourceFile = rook.file;
            move.sourceRank = rook.rank;
            if (isRookMoveLegal(player, board, move, false)) {
                return;
            }
        }
    }
}
fn findKnightSourcePosition(move: *PieceMove, player: *Player) void {
    for (player.knights.items) |knight| {
        const fileDiff1: i5 = absDiff(move.file, knight.file);
        const rankDiff1: i5 = absDiff(move.rank, knight.rank);
        if ((fileDiff1 == 2 and rankDiff1 == 1) or (fileDiff1 == 1 and rankDiff1 == 2)) {
            move.sourceFile = knight.file;
            move.sourceRank = knight.rank;
            return;
        }
    }
}
fn findBishopSourcePosition(move: *PieceMove, player: *Player) void {
    for (player.bishops.items) |bishop| {
        const rankDiff1: i5 = absDiff(bishop.rank, move.rank);
        const fileDiff1: i5 = absDiff(bishop.file, move.file);

        if (rankDiff1 == fileDiff1) {
            move.sourceFile = bishop.file;
            move.sourceRank = bishop.rank;
            return;
        }
    }
}

fn findSourcePosition(move: *Move, player: *Player, board: *Board) void {
    switch (move.*) {
        .castling => return,
        .castlingLong => return,
        .pieceMove => {
            var _move = &move.pieceMove;
            if (_move.sourceFile != null and _move.sourceRank != null) {
                return;
            }
            switch (_move.piece) {
                MPieces.PieceID.king => {
                    _move.sourceFile = player.king.file;
                    _move.sourceRank = player.king.rank;
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
    try expect(isMoveLegal(Move{ .pieceMove = PieceMove{ .rank = 4, .file = E, .piece = 'P', .sourceRank = 2, .sourceFile = E } }, &board, &white));
    try expect(isMoveLegal(Move{ .pieceMove = PieceMove{ .rank = 4, .file = A, .piece = 'P', .sourceRank = 2, .sourceFile = A } }, &board, &white));
    try expect(isMoveLegal(Move{ .pieceMove = PieceMove{ .rank = 3, .file = A, .piece = 'P', .sourceRank = 2, .sourceFile = A } }, &board, &white));
    try expect(isMoveLegal(Move{ .pieceMove = PieceMove{ .rank = 3, .file = C, .piece = 'N', .sourceRank = 1, .sourceFile = B } }, &board, &white));
    var board2 = try Board.new(allocator, &white, &black);
    defer board2.destroy();
    board2.putPiece(white.rooks.items[0]);
    try expect(isMoveLegal(Move{ .pieceMove = PieceMove{ .rank = 7, .file = A, .piece = 'R', .sourceRank = 1, .sourceFile = A } }, &board2, &white));
    board2.putPiece(black.pawns.items[0]);
    try expect(isMoveLegal(Move{ .pieceMove = PieceMove{ .rank = 7, .file = A, .piece = 'R', .sourceRank = 1, .sourceFile = A } }, &board2, &white));
    white.pawns.items[0].rank = 7;
    board2.putPiece(white.pawns.items[0]);
    try expect(!isMoveLegal(Move{ .pieceMove = PieceMove{ .rank = 7, .file = A, .piece = 'R', .sourceRank = 1, .sourceFile = A } }, &board2, &white));

    board2.putPiece(white.bishops.items[0]);
    try expect(isMoveLegal(Move{ .pieceMove = PieceMove{ .rank = 5, .file = G, .piece = 'B', .sourceRank = 1, .sourceFile = C } }, &board2, &white));
    try expect(!isMoveLegal(Move{ .pieceMove = PieceMove{ .rank = 5, .file = H, .piece = 'B', .sourceRank = 1, .sourceFile = C } }, &board2, &white));
}

fn makeMove(move: *Move, player: *Player, board: *Board) !void {
    switch (move.*) {
        .pieceMove => |pmove| {
            var piece = player.findPiece(&pmove.srcPos());
            board.evictField(piece.file, piece.rank);
            if (pmove.promoteTo != null) {
                try player.promote(piece, pmove.promoteTo.?);
            }
            piece.file = (move.pieceMove.file);
            piece.rank = (move.pieceMove.rank);
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
        .castlingLong => {
            board.evictField(player.king.file, player.king.rank);
            board.evictField(player.rooks.items[0].file, player.rooks.items[0].rank);
            player.king.file = C;
            player.rooks.items[0].file = D;
            board.putPiece(player.king);
            board.putPiece(player.rooks.items[0]);
        },
    }
}

pub fn playGame(game: anytype) !void {
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
    for (game) |move_input| {
        try board.print(stdout);
        try bw.flush();

        std.debug.print("Move: {s}\n", .{move_input});
        var move = try parse_move(move_input);

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
    try board.print(stdout);
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
        var move = try parse_move(move_input);

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
