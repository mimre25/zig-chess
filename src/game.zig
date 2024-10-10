const std = @import("std");
const boardModule = @import("board.zig");
const pieceModule = @import("pieces.zig");
const playerModule = @import("player.zig");
const Player = playerModule.Player;
const Board = boardModule.Board;
const expect = std.testing.expect;
const Color = playerModule.Color;
const Position = boardModule.Position;

const A = boardModule.A;
const B = boardModule.B;
const C = boardModule.C;
const D = boardModule.D;
const E = boardModule.E;
const F = boardModule.F;
const G = boardModule.G;
const H = boardModule.H;

fn absDiff(a: u4, b: u4) i5 {
    return @intCast(@abs(a - @as(i5, b)));
}

const MoveType = enum {
    pieceMove,
    castling,
    castlingLong,
};

pub const Move = union(MoveType) {
    pieceMove: PieceMove,
    castling: bool,
    castlingLong: bool,
};

pub const PieceMove = struct {
    rank: u4,
    file: u4,
    piece: u8,
    sourceRank: ?u4 = null,
    sourceFile: ?u4 = null,
    promoteTo: ?u8 = null,

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
        return writer.print("{u} from {u}{any} to {u}{any}", .{ self.piece, srcFile, self.sourceRank, self.file + a, self.rank });
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
    var promoteTo: ?u8 = null;
    if (piece == 'P') {
        // "dxc6"
        if (input[1] == 'x') {
            sourceFile = try parse_file(input[0]);
            startIdx = 2;
        }
        if (input[input.len - 2] == '=') {
            promoteTo = input[input.len - 1];
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
        .piece = piece,
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
    if (input[0] == 'O') {
        return parse_castling(input);
    } else {
        return try parse_piece_move(input);
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
    const rank = player.king.rank();
    return player.castlingPossible and player.king.file() == E and player.rook2.file() == H and board.isEmpty(F, rank) and board.isEmpty(G, rank);
}

fn isLongCastlingPossible(player: *const Player, board: *const Board) bool {
    const rank = player.king.rank();
    return player.castlingPossible and player.king.file() == E and player.rook2.file() == A and board.isEmpty(B, rank) and board.isEmpty(C, rank) and board.isEmpty(D, rank);
}

fn isPieceMovePossible(player: *const Player, board: *const Board, move: *const PieceMove) bool {
    return switch (move.piece) {
        'K' => isKingMoveLegal(player, board, move),
        'Q' => isQueenMoveLegal(player, board, move),
        'R' => isRookMoveLegal(player, board, move, true),
        'N' => isKnightMoveLegal(player, move),
        'B' => isBishopMoveLegal(player, board, move, true),
        'P' => isPawnMoveLegal(player, board, move),
        inline else => unreachable,
    };
}

fn isKingMoveLegal(player: *const Player, board: *const Board, move: *const PieceMove) bool {
    const fileDiff: i5 = absDiff(move.file, player.king.file());
    const rankDiff: i5 = absDiff(move.rank, player.king.rank());
    if (fileDiff > 1 or rankDiff > 1) {
        return false;
    }
    const targetPiece = board.getPiece(move.file, move.rank);
    switch (targetPiece.*) {
        //TODO: implement check for covered squares
        .empty => return true,
        else => return targetPiece.color() != player.color,
    }
    std.debug.print("foo {}", .{board.allocator});
    return false;
}
fn isQueenMoveLegal(player: *const Player, board: *const Board, move: *const PieceMove) bool {
    if (!player.queen.pos().eq(move.srcPos())) {
        return false;
    }

    return isRookMoveLegal(player, board, move, false) or isBishopMoveLegal(player, board, move, false);
}
fn isRookMoveLegal(player: *const Player, board: *const Board, move: *const PieceMove, checkPiece: bool) bool {
    if (checkPiece) {
        if (!player.rook1.pos().eq(move.srcPos()) and !player.rook2.pos().eq(move.srcPos())) {
            return false;
        }
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
    return board.isEmpty(move.file, move.rank) or board.getPiece(move.file, move.rank).color() != player.color;
}
fn isKnightMoveLegal(player: *const Player, move: *const PieceMove) bool {
    if (!player.knight1.pos().eq(move.srcPos()) and !player.knight2.pos().eq(move.srcPos())) {
        return false;
    }
    const fileDiff: i5 = absDiff(move.file, move.sourceFile.?);
    const rankDiff: i5 = absDiff(move.rank, move.sourceRank.?);
    return (fileDiff == 2 and rankDiff == 1) or (fileDiff == 1 and rankDiff == 2);
}
fn isBishopMoveLegal(player: *const Player, board: *const Board, move: *const PieceMove, checkPiece: bool) bool {
    if (checkPiece) {
        if (!player.bishop1.pos().eq(move.srcPos()) and !player.bishop2.pos().eq(move.srcPos())) {
            return false;
        }
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

    return board.isEmpty(move.file, move.rank) or board.getPiece(move.file, move.rank).color() != player.color;
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
            //promotion move
            //TODO:
            return false;
        }
        if (board.getPiece(move.file, move.rank).color() != player.color and absDiff(move.sourceFile.?, move.file) == 1) {
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
    }

    return true;
}

fn findPawnSourcePosition(move: *PieceMove, player: *Player) void {
    if (move.sourceFile == null) {
        move.sourceFile = move.file; // otherwise source file is given
    }
    if (move.sourceRank == null) {
        if (player.color == Color.white and move.rank == 4) {
            switch (move.file) {
                A => {
                    if (player.aPawn.rank() == 2) move.sourceRank = 2;
                },
                B => {
                    if (player.bPawn.rank() == 2) move.sourceRank = 2;
                },
                C => {
                    if (player.cPawn.rank() == 2) move.sourceRank = 2;
                },
                D => {
                    if (player.dPawn.rank() == 2) move.sourceRank = 2;
                },
                E => {
                    if (player.ePawn.rank() == 2) move.sourceRank = 2;
                },
                F => {
                    if (player.fPawn.rank() == 2) move.sourceRank = 2;
                },
                G => {
                    if (player.gPawn.rank() == 2) move.sourceRank = 2;
                },
                H => {
                    if (player.hPawn.rank() == 2) move.sourceRank = 2;
                },
                else => unreachable,
            }
        } else if (player.color == Color.black and move.rank == 5) {
            switch (move.file) {
                A => {
                    if (player.aPawn.rank() == 7) move.sourceRank = 7;
                },
                B => {
                    if (player.bPawn.rank() == 7) move.sourceRank = 7;
                },
                C => {
                    if (player.cPawn.rank() == 7) move.sourceRank = 7;
                },
                D => {
                    if (player.dPawn.rank() == 7) move.sourceRank = 7;
                },
                E => {
                    if (player.ePawn.rank() == 7) move.sourceRank = 7;
                },
                F => {
                    if (player.fPawn.rank() == 7) move.sourceRank = 7;
                },
                G => {
                    if (player.gPawn.rank() == 7) move.sourceRank = 7;
                },
                H => {
                    if (player.hPawn.rank() == 7) move.sourceRank = 7;
                },
                else => unreachable,
            }
        }
        if (move.sourceRank == null) {
            move.sourceRank = if (player.color == Color.white) move.rank - 1 else move.rank + 1;
        }
    }
}

fn findRookSourcePosition(move: *PieceMove, player: *Player, board: *Board) void {
    //TODO: "Rb1" is legal input if we have a rook both on A1 and F1 and
    //// there is a piece on C1 or D1 or E1, becuase then I can only be the rook form A1
    if (player.rook1.file() == move.file) {
        move.sourceFile = player.rook1.file();
        move.sourceRank = player.rook1.rank();
        if (isRookMoveLegal(player, board, move, false)) {
            return;
        }
    }
    if (player.rook2.file() == move.file) {
        move.sourceFile = player.rook2.file();
        move.sourceRank = player.rook2.rank();
        if (isRookMoveLegal(player, board, move, false)) {
            return;
        }
    }
    if (player.rook1.rank() == move.rank) {
        move.sourceFile = player.rook1.file();
        move.sourceRank = player.rook1.rank();
        if (isRookMoveLegal(player, board, move, false)) {
            return;
        }
    }
    if (player.rook2.rank() == move.rank) {
        move.sourceFile = player.rook2.file();
        move.sourceRank = player.rook2.rank();
        if (isRookMoveLegal(player, board, move, false)) {
            return;
        }
    }
}
fn findKnightSourcePosition(move: *PieceMove, player: *Player) void {
    const fileDiff1: i5 = absDiff(move.file, player.knight1.file());
    const rankDiff1: i5 = absDiff(move.rank, player.knight1.rank());
    if ((fileDiff1 == 2 and rankDiff1 == 1) or (fileDiff1 == 1 and rankDiff1 == 2)) {
        move.sourceFile = player.knight1.file();
        move.sourceRank = player.knight1.rank();
        return;
    }
    const fileDiff2: i5 = absDiff(move.file, player.knight2.file());
    const rankDiff2: i5 = absDiff(move.rank, player.knight2.rank());
    if ((fileDiff2 == 2 and rankDiff2 == 1) or (fileDiff2 == 1 and rankDiff2 == 2)) {
        move.sourceFile = player.knight2.file();
        move.sourceRank = player.knight2.rank();
    }
}
fn findBishopSourcePosition(move: *PieceMove, player: *Player) void {
    const rankDiff1: i5 = absDiff(player.bishop1.rank(), move.rank);
    const fileDiff1: i5 = absDiff(player.bishop1.file(), move.file);

    if (rankDiff1 == fileDiff1) {
        move.sourceFile = player.bishop1.file();
        move.sourceRank = player.bishop1.rank();
        return;
    }
    const rankDiff2: i5 = absDiff(player.bishop2.rank(), move.rank);
    const fileDiff2: i5 = absDiff(player.bishop2.file(), move.file);
    if (rankDiff2 == fileDiff2) {
        move.sourceFile = player.bishop2.file();
        move.sourceRank = player.bishop2.rank();
        return;
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
                'K' => {
                    _move.sourceFile = player.king.file();
                    _move.sourceRank = player.king.rank();
                },
                'Q' => {
                    //FIXME: could be any piece not just 'player.queen'
                    _move.sourceFile = player.queen.file();
                    _move.sourceRank = player.queen.rank();
                },
                'R' => findRookSourcePosition(_move, player, board),
                'N' => findKnightSourcePosition(_move, player),
                'B' => findBishopSourcePosition(_move, player),
                'P' => findPawnSourcePosition(_move, player),
                inline else => unreachable,
            }
            return;
        },
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
    var board = try Board.new(allocator);
    defer board.destory();
    var white = Player.new(Color.white);
    var black = Player.new(Color.black);
    Player.initPiecePointer(&white);
    Player.initPiecePointer(&black);
    for (0..16) |idx| {
        board.putPiece(white.pieces[idx]);
        board.putPiece(black.pieces[idx]);
    }

    // done init

    try expect(!isMoveLegal(Move{ .castling = true }, &board, &white));
    try expect(!isMoveLegal(Move{ .castling = true }, &board, &white));
    try expect(isMoveLegal(Move{ .pieceMove = PieceMove{ .rank = 4, .file = E, .piece = 'P', .sourceRank = 2, .sourceFile = E } }, &board, &white));
    try expect(isMoveLegal(Move{ .pieceMove = PieceMove{ .rank = 4, .file = A, .piece = 'P', .sourceRank = 2, .sourceFile = A } }, &board, &white));
    try expect(isMoveLegal(Move{ .pieceMove = PieceMove{ .rank = 3, .file = A, .piece = 'P', .sourceRank = 2, .sourceFile = A } }, &board, &white));
    try expect(isMoveLegal(Move{ .pieceMove = PieceMove{ .rank = 3, .file = C, .piece = 'N', .sourceRank = 1, .sourceFile = B } }, &board, &white));
    var board2 = try Board.new(allocator);
    defer board2.destory();
    board2.putPiece(&white.rook1);
    try expect(isMoveLegal(Move{ .pieceMove = PieceMove{ .rank = 7, .file = A, .piece = 'R', .sourceRank = 1, .sourceFile = A } }, &board2, &white));
    board2.putPiece(&black.aPawn);
    try expect(isMoveLegal(Move{ .pieceMove = PieceMove{ .rank = 7, .file = A, .piece = 'R', .sourceRank = 1, .sourceFile = A } }, &board2, &white));
    white.aPawn.pawn.rank = 7;
    board2.putPiece(&white.aPawn);
    try expect(!isMoveLegal(Move{ .pieceMove = PieceMove{ .rank = 7, .file = A, .piece = 'R', .sourceRank = 1, .sourceFile = A } }, &board2, &white));

    board2.putPiece(&white.bishop1);
    try expect(isMoveLegal(Move{ .pieceMove = PieceMove{ .rank = 5, .file = G, .piece = 'B', .sourceRank = 1, .sourceFile = C } }, &board2, &white));
    try expect(!isMoveLegal(Move{ .pieceMove = PieceMove{ .rank = 5, .file = H, .piece = 'B', .sourceRank = 1, .sourceFile = C } }, &board2, &white));
}

fn makeMove(move: *Move, player: *Player, board: *Board) void {
    switch (move.*) {
        .pieceMove => |pmove| {
            var piece = player.findPiece(&pmove.srcPos());
            board.evictField(piece.file(), piece.rank());
            if (pmove.promoteTo != null) {
                piece.* = switch (pmove.promoteTo.?) {
                    'Q' => pieceModule.Queen.new(player.color),
                    'R' => pieceModule.Rook.new(player.color, pmove.file),
                    'N' => pieceModule.Knight.new(player.color, pmove.file),
                    'B' => pieceModule.Bishop.new(player.color, pmove.file),
                    inline else => unreachable,
                };
            }
            piece.setFile(move.pieceMove.file);
            piece.setRank(move.pieceMove.rank);
            board.putPiece(piece);
        },
        .castling => {
            board.evictField(player.king.file(), player.king.rank());
            board.evictField(player.rook2.file(), player.rook2.rank());
            player.king.setFile(G);
            player.rook2.setFile(F);
            board.putPiece(&player.king);
            board.putPiece(&player.rook2);
        },
        .castlingLong => {
            board.evictField(player.king.file(), player.king.rank());
            board.evictField(player.rook1.file(), player.rook1.rank());
            player.king.setFile(C);
            player.rook1.setFile(D);
            board.putPiece(&player.king);
            board.putPiece(&player.rook1);
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
    var board = try Board.new(allocator);
    defer board.destory();
    var white = Player.new(Color.white);
    var black = Player.new(Color.black);
    Player.initPiecePointer(&white);
    Player.initPiecePointer(&black);
    for (0..16) |idx| {
        board.putPiece(white.pieces[idx]);
        board.putPiece(black.pieces[idx]);
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

        makeMove(&move, current_player, &board);
        i += 1;
    }
}

test "parse game1" {
    const game = @import("test_game.zig").game1;
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    const allocator = std.testing.allocator;

    // init TODO: make function
    var board = try Board.new(allocator);
    defer board.destory();
    var white = Player.new(Color.white);
    var black = Player.new(Color.black);
    Player.initPiecePointer(&white);
    Player.initPiecePointer(&black);
    for (0..16) |idx| {
        board.putPiece(white.pieces[idx]);
        board.putPiece(black.pieces[idx]);
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

        makeMove(&move, current_player, &board);
        i += 1;
    }
}
