const Color = @import("player.zig").Color;
const board = @import("board.zig");
const Position = board.Position;

const A = board.A;
const B = board.B;
const C = board.C;
const D = board.D;
const E = board.E;
const F = board.F;
const G = board.G;
const H = board.H;

pub const TPiece = enum(u16) {
    BLACK_KING = '♔',
    BLACK_QUEEN = '♕',
    BLACK_KNIGHT = '♘',
    BLACK_BISHOP = '♗',
    BLACK_PAWN = '♙',
    BLACK_ROOK = '♖',
    WHITE_KING = '♚',
    WHITE_QUEEN = '♛',
    WHITE_KNIGHT = '♞',
    WHITE_BISHOP = '♝',
    WHITE_PAWN = '♟',
    WHITE_ROOK = '♜',
    EMPTY = ' ',
};

pub const Empty = __Empty{};

pub const PieceID = enum(u8) {
    pawn = 'P',
    rook = 'R',
    knight = 'N',
    bishop = 'B',
    queen = 'Q',
    king = 'K',
    empty = ' ',
};

pub const Piece = struct {
    piece: PieceID,
    icon: TPiece,
    file: u4,
    rank: u4,
    color: Color,

    pub fn pos(self: Piece) Position {
        return Position{ .file = self.file, .rank = self.rank };
    }

    pub fn promote(self: *Piece, promoteTo: PieceID) void {
        if (promoteTo == PieceID.king or promoteTo == PieceID.pawn or promoteTo == PieceID.empty) {
            unreachable;
        }
        self.piece = promoteTo;
        if (self.color == Color.white) {
            self.icon = switch (promoteTo) {
                PieceID.queen => TPiece.WHITE_QUEEN,
                PieceID.rook => TPiece.WHITE_ROOK,
                PieceID.knight => TPiece.WHITE_KNIGHT,
                PieceID.bishop => TPiece.WHITE_BISHOP,
                inline else => unreachable,
            };
        } else {
            self.icon = switch (promoteTo) {
                PieceID.queen => TPiece.BLACK_QUEEN,
                PieceID.rook => TPiece.BLACK_ROOK,
                PieceID.knight => TPiece.BLACK_KNIGHT,
                PieceID.bishop => TPiece.BLACK_BISHOP,
                inline else => unreachable,
            };
        }
    }
};

pub fn newKing(color: Color) Piece {
    switch (color) {
        Color.white => return Piece{ .piece = PieceID.king, .icon = TPiece.WHITE_KING, .rank = 1, .file = E, .color = color },
        Color.black => return Piece{ .piece = PieceID.king, .icon = TPiece.BLACK_KING, .rank = 8, .file = E, .color = color },
    }
}
pub fn newPawn(color: Color, file: u4) Piece {
    switch (color) {
        Color.white => return Piece{ .piece = PieceID.pawn, .icon = TPiece.WHITE_PAWN, .rank = 2, .file = file, .color = color },
        Color.black => return Piece{ .piece = PieceID.pawn, .icon = TPiece.BLACK_PAWN, .rank = 7, .file = file, .color = color },
    }
}
pub fn newRook(color: Color, file: u4) Piece {
    switch (color) {
        Color.white => return Piece{ .piece = PieceID.rook, .icon = TPiece.WHITE_ROOK, .rank = 1, .file = file, .color = color },
        Color.black => return Piece{ .piece = PieceID.rook, .icon = TPiece.BLACK_ROOK, .rank = 8, .file = file, .color = color },
    }
}
pub fn newKnight(color: Color, file: u4) Piece {
    switch (color) {
        Color.white => return Piece{ .piece = PieceID.knight, .icon = TPiece.WHITE_KNIGHT, .rank = 1, .file = file, .color = color },
        Color.black => return Piece{ .piece = PieceID.knight, .icon = TPiece.BLACK_KNIGHT, .rank = 8, .file = file, .color = color },
    }
}
pub fn newBishop(color: Color, file: u4) Piece {
    switch (color) {
        Color.white => return Piece{ .piece = PieceID.bishop, .icon = TPiece.WHITE_BISHOP, .rank = 1, .file = file, .color = color },
        Color.black => return Piece{ .piece = PieceID.bishop, .icon = TPiece.BLACK_BISHOP, .rank = 8, .file = file, .color = color },
    }
}
pub fn newQueen(color: Color) Piece {
    switch (color) {
        Color.white => return Piece{ .piece = PieceID.queen, .icon = TPiece.WHITE_QUEEN, .rank = 1, .file = D, .color = color },
        Color.black => return Piece{ .piece = PieceID.queen, .icon = TPiece.BLACK_QUEEN, .rank = 8, .file = D, .color = color },
    }
}

pub var __Empty = Piece{
    .icon = TPiece.EMPTY,
    .piece = PieceID.empty,
    //below doesn't matter
    .file = 0,
    .rank = 0,
    .color = Color.white,
};
