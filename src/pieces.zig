const Color = @import("player.zig").Color;
const MBoard = @import("board.zig");
const Position = MBoard.Position;

const A = MBoard.A;
const B = MBoard.B;
const C = MBoard.C;
const D = MBoard.D;
const E = MBoard.E;
const F = MBoard.F;
const G = MBoard.G;
const H = MBoard.H;

pub const Icon = enum(u16) {
    black_king = '♔',
    black_queen = '♕',
    black_knight = '♘',
    black_bishop = '♗',
    black_pawn = '♙',
    black_rook = '♖',
    white_king = '♚',
    white_queen = '♛',
    white_knight = '♞',
    white_bishop = '♝',
    white_pawn = '♟',
    white_rook = '♜',
    empty = ' ',
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
    icon: Icon,
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
                PieceID.queen => Icon.white_queen,
                PieceID.rook => Icon.white_rook,
                PieceID.knight => Icon.white_knight,
                PieceID.bishop => Icon.white_bishop,
                inline else => unreachable,
            };
        } else {
            self.icon = switch (promoteTo) {
                PieceID.queen => Icon.black_queen,
                PieceID.rook => Icon.black_rook,
                PieceID.knight => Icon.black_knight,
                PieceID.bishop => Icon.black_bishop,
                inline else => unreachable,
            };
        }
    }
};

pub fn newKing(color: Color) Piece {
    switch (color) {
        Color.white => return Piece{ .piece = PieceID.king, .icon = Icon.white_king, .rank = 1, .file = E, .color = color },
        Color.black => return Piece{ .piece = PieceID.king, .icon = Icon.black_king, .rank = 8, .file = E, .color = color },
    }
}
pub fn newPawn(color: Color, file: u4) Piece {
    switch (color) {
        Color.white => return Piece{ .piece = PieceID.pawn, .icon = Icon.white_pawn, .rank = 2, .file = file, .color = color },
        Color.black => return Piece{ .piece = PieceID.pawn, .icon = Icon.black_pawn, .rank = 7, .file = file, .color = color },
    }
}
pub fn newRook(color: Color, file: u4) Piece {
    switch (color) {
        Color.white => return Piece{ .piece = PieceID.rook, .icon = Icon.white_rook, .rank = 1, .file = file, .color = color },
        Color.black => return Piece{ .piece = PieceID.rook, .icon = Icon.black_rook, .rank = 8, .file = file, .color = color },
    }
}
pub fn newKnight(color: Color, file: u4) Piece {
    switch (color) {
        Color.white => return Piece{ .piece = PieceID.knight, .icon = Icon.white_knight, .rank = 1, .file = file, .color = color },
        Color.black => return Piece{ .piece = PieceID.knight, .icon = Icon.black_knight, .rank = 8, .file = file, .color = color },
    }
}
pub fn newBishop(color: Color, file: u4) Piece {
    switch (color) {
        Color.white => return Piece{ .piece = PieceID.bishop, .icon = Icon.white_bishop, .rank = 1, .file = file, .color = color },
        Color.black => return Piece{ .piece = PieceID.bishop, .icon = Icon.black_bishop, .rank = 8, .file = file, .color = color },
    }
}
pub fn newQueen(color: Color) Piece {
    switch (color) {
        Color.white => return Piece{ .piece = PieceID.queen, .icon = Icon.white_queen, .rank = 1, .file = D, .color = color },
        Color.black => return Piece{ .piece = PieceID.queen, .icon = Icon.black_queen, .rank = 8, .file = D, .color = color },
    }
}

pub var __Empty = Piece{
    .icon = Icon.empty,
    .piece = PieceID.empty,
    //below doesn't matter
    .file = 0,
    .rank = 0,
    .color = Color.white,
};
