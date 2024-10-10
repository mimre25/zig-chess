const pieces = @import("pieces.zig");
const board = @import("board.zig");
const Position = board.Position;

pub const Color = enum { black, white };
const A = board.A;
const B = board.B;
const C = board.C;
const D = board.D;
const E = board.E;
const F = board.F;
const G = board.G;
const H = board.H;

pub const Player = struct {
    aPawn: pieces.Piece,
    bPawn: pieces.Piece,
    cPawn: pieces.Piece,
    dPawn: pieces.Piece,
    ePawn: pieces.Piece,
    fPawn: pieces.Piece,
    gPawn: pieces.Piece,
    hPawn: pieces.Piece,
    rook1: pieces.Piece,
    rook2: pieces.Piece,
    knight1: pieces.Piece,
    knight2: pieces.Piece,
    bishop1: pieces.Piece,
    bishop2: pieces.Piece,
    queen: pieces.Piece,
    king: pieces.Piece,
    pieces: [16]*pieces.Piece = undefined,
    castlingPossible: bool = true,
    color: Color,

    pub fn new(color: Color) Player {
        const player = Player{
            .aPawn = pieces.Pawn.new(color, A),
            .bPawn = pieces.Pawn.new(color, B),
            .cPawn = pieces.Pawn.new(color, C),
            .dPawn = pieces.Pawn.new(color, D),
            .ePawn = pieces.Pawn.new(color, E),
            .fPawn = pieces.Pawn.new(color, F),
            .gPawn = pieces.Pawn.new(color, G),
            .hPawn = pieces.Pawn.new(color, H),
            .rook1 = pieces.Rook.new(color, A),
            .rook2 = pieces.Rook.new(color, H),
            .knight1 = pieces.Knight.new(color, B),
            .knight2 = pieces.Knight.new(color, G),
            .bishop1 = pieces.Bishop.new(color, C),
            .bishop2 = pieces.Bishop.new(color, F),
            .queen = pieces.Queen.new(color),
            .king = pieces.King.new(color),
            .color = color,
        };
        return player;
    }

    pub fn initPiecePointer(self: *Player) void {
        self.pieces[0] = &self.aPawn;
        self.pieces[1] = &self.bPawn;
        self.pieces[2] = &self.cPawn;
        self.pieces[3] = &self.dPawn;
        self.pieces[4] = &self.ePawn;
        self.pieces[5] = &self.fPawn;
        self.pieces[6] = &self.gPawn;
        self.pieces[7] = &self.hPawn;
        self.pieces[8] = &self.rook1;
        self.pieces[9] = &self.rook2;
        self.pieces[10] = &self.knight1;
        self.pieces[11] = &self.knight2;
        self.pieces[12] = &self.bishop1;
        self.pieces[13] = &self.bishop2;
        self.pieces[14] = &self.queen;
        self.pieces[15] = &self.king;
    }

    pub fn findPiece(self: Player, pos: *const Position) *pieces.Piece {
        for (self.pieces) |piece| {
            if (pos.eq(piece.pos())) {
                return piece;
            }
        }
        unreachable;
    }
};
