const Color = @import("player.zig").Color;
const board = @import("board.zig");

const A = board.A;
const B = board.B;
const C = board.C;
const D = board.D;
const E = board.E;
const F = board.F;
const G = board.G;
const H = board.H;

pub const TPiece = u16;
const BLACK_KING: TPiece = '♔';
const BLACK_QUEEN: TPiece = '♕';
const BLACK_KNIGHT: TPiece = '♘';
const BLACK_BISHOP: TPiece = '♗';
const BLACK_PAWN: TPiece = '♙';
const BLACK_ROOK: TPiece = '♖';
const WHITE_KING: TPiece = '♚';
const WHITE_QUEEN: TPiece = '♛';
const WHITE_KNIGHT: TPiece = '♞';
const WHITE_BISHOP: TPiece = '♝';
const WHITE_PAWN: TPiece = '♟';
const WHITE_ROOK: TPiece = '♜';

pub const Piece = union(enum) {
    pawn: Pawn,
    rook: Rook,
    knight: Knight,
    bishop: Bishop,
    queen: Queen,
    king: King,

    pub fn icon(self: Piece) TPiece {
        switch (self) {
            inline else => |case| return case.icon,
        }
    }
    pub fn file(self: Piece) u4 {
        switch (self) {
            inline else => |case| return case.file,
        }
    }

    pub fn rank(self: Piece) u4 {
        switch (self) {
            inline else => |case| return case.rank,
        }
    }
};

pub const King = struct {
    icon: TPiece,
    file: u4,
    rank: u4,

    pub fn new(color: Color) Piece {
        switch (color) {
            Color.white => return Piece{ .king = King{ .icon = WHITE_KING, .rank = 1, .file = E } },
            Color.black => return Piece{ .king = King{ .icon = BLACK_KING, .rank = 8, .file = E } },
        }
    }
};
pub const Pawn = struct {
    icon: TPiece,
    file: u4,
    rank: u4,

    pub fn new(color: Color, file: u4) Piece {
        switch (color) {
            Color.white => return Piece{ .pawn = Pawn{ .icon = WHITE_PAWN, .rank = 2, .file = file } },
            Color.black => return Piece{ .pawn = Pawn{ .icon = BLACK_PAWN, .rank = 7, .file = file } },
        }
    }
};
pub const Rook = struct {
    icon: TPiece,
    file: u4,
    rank: u4,

    pub fn new(color: Color, file: u4) Piece {
        switch (color) {
            Color.white => return Piece{ .rook = Rook{ .icon = WHITE_ROOK, .rank = 1, .file = file } },
            Color.black => return Piece{ .rook = Rook{ .icon = BLACK_ROOK, .rank = 8, .file = file } },
        }
    }
};
pub const Knight = struct {
    icon: TPiece,
    file: u4,
    rank: u4,

    pub fn new(color: Color, file: u4) Piece {
        switch (color) {
            Color.white => return Piece{ .knight = Knight{ .icon = WHITE_KNIGHT, .rank = 1, .file = file } },
            Color.black => return Piece{ .knight = Knight{ .icon = BLACK_KNIGHT, .rank = 8, .file = file } },
        }
    }
};
pub const Bishop = struct {
    icon: TPiece,
    file: u4,
    rank: u4,

    pub fn new(color: Color, file: u4) Piece {
        switch (color) {
            Color.white => return Piece{ .bishop = Bishop{ .icon = WHITE_BISHOP, .rank = 1, .file = file } },
            Color.black => return Piece{ .bishop = Bishop{ .icon = BLACK_BISHOP, .rank = 8, .file = file } },
        }
    }
};
pub const Queen = struct {
    icon: TPiece,
    file: u4,
    rank: u4,

    pub fn new(color: Color) Piece {
        switch (color) {
            Color.white => return Piece{ .queen = Queen{ .icon = WHITE_QUEEN, .rank = 1, .file = D } },
            Color.black => return Piece{ .queen = Queen{ .icon = BLACK_QUEEN, .rank = 8, .file = D } },
        }
    }
};
