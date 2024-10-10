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

pub const Empty = __Empty.new();

pub const Piece = union(enum) {
    pawn: Pawn,
    rook: Rook,
    knight: Knight,
    bishop: Bishop,
    queen: Queen,
    king: King,
    empty: __Empty,

    pub fn icon(self: Piece) TPiece {
        switch (self) {
            inline else => |case| return case.icon,
        }
    }
    pub fn file(self: Piece) u4 {
        switch (self) {
            .empty => unreachable,
            inline else => |case| return case.file,
        }
    }

    pub fn rank(self: Piece) u4 {
        switch (self) {
            .empty => unreachable,
            inline else => |case| return case.rank,
        }
    }
    pub fn color(self: Piece) Color {
        switch (self) {
            .empty => unreachable,
            inline else => |case| return case.color,
        }
    }

    pub fn pos(self: Piece) Position {
        return Position{ .file = self.file(), .rank = self.rank() };
    }

    pub fn setFile(self: *Piece, file_: u4) void {
        switch (self.*) {
            .rook => self.rook.file = file_,
            .pawn => self.pawn.file = file_,
            .knight => self.knight.file = file_,
            .bishop => self.bishop.file = file_,
            .queen => self.queen.file = file_,
            .king => self.king.file = file_,
            .empty => unreachable,
        }
    }

    pub fn setRank(self: *Piece, rank_: u4) void {
        switch (self.*) {
            .rook => self.rook.rank = rank_,
            .pawn => self.pawn.rank = rank_,
            .knight => self.knight.rank = rank_,
            .bishop => self.bishop.rank = rank_,
            .queen => self.queen.rank = rank_,
            .king => self.king.rank = rank_,
            .empty => unreachable,
        }
    }
};

pub const King = struct {
    icon: TPiece,
    file: u4,
    rank: u4,
    color: Color,

    pub fn new(color: Color) Piece {
        switch (color) {
            Color.white => return Piece{ .king = King{ .icon = WHITE_KING, .rank = 1, .file = E, .color = color } },
            Color.black => return Piece{ .king = King{ .icon = BLACK_KING, .rank = 8, .file = E, .color = color } },
        }
    }
};
pub const Pawn = struct {
    icon: TPiece,
    file: u4,
    rank: u4,
    color: Color,

    pub fn new(color: Color, file: u4) Piece {
        switch (color) {
            Color.white => return Piece{ .pawn = Pawn{ .icon = WHITE_PAWN, .rank = 2, .file = file, .color = color } },
            Color.black => return Piece{ .pawn = Pawn{ .icon = BLACK_PAWN, .rank = 7, .file = file, .color = color } },
        }
    }
};
pub const Rook = struct {
    icon: TPiece,
    file: u4,
    rank: u4,
    color: Color,

    pub fn new(color: Color, file: u4) Piece {
        switch (color) {
            Color.white => return Piece{ .rook = Rook{ .icon = WHITE_ROOK, .rank = 1, .file = file, .color = color } },
            Color.black => return Piece{ .rook = Rook{ .icon = BLACK_ROOK, .rank = 8, .file = file, .color = color } },
        }
    }
};
pub const Knight = struct {
    icon: TPiece,
    file: u4,
    rank: u4,
    color: Color,

    pub fn new(color: Color, file: u4) Piece {
        switch (color) {
            Color.white => return Piece{ .knight = Knight{ .icon = WHITE_KNIGHT, .rank = 1, .file = file, .color = color } },
            Color.black => return Piece{ .knight = Knight{ .icon = BLACK_KNIGHT, .rank = 8, .file = file, .color = color } },
        }
    }
};
pub const Bishop = struct {
    icon: TPiece,
    file: u4,
    rank: u4,
    color: Color,

    pub fn new(color: Color, file: u4) Piece {
        switch (color) {
            Color.white => return Piece{ .bishop = Bishop{ .icon = WHITE_BISHOP, .rank = 1, .file = file, .color = color } },
            Color.black => return Piece{ .bishop = Bishop{ .icon = BLACK_BISHOP, .rank = 8, .file = file, .color = color } },
        }
    }
};
pub const Queen = struct {
    icon: TPiece,
    file: u4,
    rank: u4,
    color: Color,

    pub fn new(color: Color) Piece {
        switch (color) {
            Color.white => return Piece{ .queen = Queen{ .icon = WHITE_QUEEN, .rank = 1, .file = D, .color = color } },
            Color.black => return Piece{ .queen = Queen{ .icon = BLACK_QUEEN, .rank = 8, .file = D, .color = color } },
        }
    }
};

pub const __Empty = struct {
    icon: TPiece = ' ',

    pub fn new() Piece {
        return Piece{ .empty = __Empty{} };
    }
};
