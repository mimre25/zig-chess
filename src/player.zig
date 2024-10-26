const MPieces = @import("pieces.zig");
const MBoard = @import("board.zig");
const Position = MBoard.Position;
const std = @import("std");

pub const Color = enum { black, white };
const A = MBoard.A;
const B = MBoard.B;
const C = MBoard.C;
const D = MBoard.D;
const E = MBoard.E;
const F = MBoard.F;
const G = MBoard.G;
const H = MBoard.H;

pub const PlayerError = error{
    NoPieceFound,
};

pub const Player = struct {
    pieces: []MPieces.Piece,
    castlingPossible: bool = true,
    color: Color,
    allocator: std.mem.Allocator,
    king: *MPieces.Piece,
    queens: std.ArrayList(*MPieces.Piece),
    rooks: std.ArrayList(*MPieces.Piece),
    bishops: std.ArrayList(*MPieces.Piece),
    knights: std.ArrayList(*MPieces.Piece),
    pawns: std.ArrayList(*MPieces.Piece),

    pub fn new(color: Color, allocator: std.mem.Allocator) !Player {
        var playerPieces = try allocator.alloc(MPieces.Piece, 16);
        playerPieces[0] = MPieces.newPawn(color, A);
        playerPieces[1] = MPieces.newPawn(color, B);
        playerPieces[2] = MPieces.newPawn(color, C);
        playerPieces[3] = MPieces.newPawn(color, D);
        playerPieces[4] = MPieces.newPawn(color, E);
        playerPieces[5] = MPieces.newPawn(color, F);
        playerPieces[6] = MPieces.newPawn(color, G);
        playerPieces[7] = MPieces.newPawn(color, H);
        playerPieces[8] = MPieces.newRook(color, A);
        playerPieces[9] = MPieces.newRook(color, H);
        playerPieces[10] = MPieces.newKnight(color, B);
        playerPieces[11] = MPieces.newKnight(color, G);
        playerPieces[12] = MPieces.newBishop(color, C);
        playerPieces[13] = MPieces.newBishop(color, F);
        playerPieces[14] = MPieces.newQueen(color);
        playerPieces[15] = MPieces.newKing(color);
        const player = Player{
            .pieces = playerPieces,
            .color = color,
            .allocator = allocator,
            .king = &playerPieces[15],
            .queens = std.ArrayList(*MPieces.Piece).init(allocator),
            .rooks = std.ArrayList(*MPieces.Piece).init(allocator),
            .bishops = std.ArrayList(*MPieces.Piece).init(allocator),
            .knights = std.ArrayList(*MPieces.Piece).init(allocator),
            .pawns = std.ArrayList(*MPieces.Piece).init(allocator),
        };
        return player;
    }

    pub fn initPieces(player: *Player) !void {
        try player.queens.append(&player.pieces[14]);
        try player.rooks.append(&player.pieces[8]);
        try player.rooks.append(&player.pieces[9]);
        try player.bishops.append(&player.pieces[12]);
        try player.bishops.append(&player.pieces[13]);
        try player.knights.append(&player.pieces[10]);
        try player.knights.append(&player.pieces[11]);
        for (player.pieces[0..8]) |*pawn| {
            try player.pawns.append(pawn);
        }
    }

    pub fn destroy(self: Player) void {
        self.allocator.free(self.pieces);
        self.queens.deinit();
        self.rooks.deinit();
        self.bishops.deinit();
        self.knights.deinit();
        self.pawns.deinit();
    }

    pub fn findPiece(self: Player, pos: *const Position) !*MPieces.Piece {
        for (self.pieces) |*piece| {
            if (pos.eq(piece.pos())) {
                return piece;
            }
        }
        return PlayerError.NoPieceFound;
    }

    pub fn takePiece(self: *Player, piece: *MPieces.Piece) void {
        const list = switch (piece.piece) {
            MPieces.PieceID.pawn => &self.pawns,
            MPieces.PieceID.queen => &self.queens,
            MPieces.PieceID.rook => &self.rooks,
            MPieces.PieceID.knight => &self.knights,
            MPieces.PieceID.bishop => &self.bishops,
            inline else => unreachable,
        };
        var idx: i5 = -1;
        for (list.items, 0..) |pawn, i| {
            if (pawn == piece) {
                idx = @intCast(i);
            }
        }
        if (idx == -1) {
            unreachable;
        }
        _ = list.orderedRemove(@intCast(idx));
        piece.file = std.math.maxInt(u4);
        piece.rank = std.math.maxInt(u4);
    }

    pub fn promote(self: *Player, piece: *MPieces.Piece, promoteTo: MPieces.PieceID) !void {
        self.takePiece(piece);
        piece.promote(promoteTo);

        switch (promoteTo) {
            MPieces.PieceID.queen => try self.queens.append(piece),
            MPieces.PieceID.rook => try self.rooks.append(piece),
            MPieces.PieceID.knight => try self.knights.append(piece),
            MPieces.PieceID.bishop => try self.bishops.append(piece),
            inline else => unreachable,
        }
    }
};
