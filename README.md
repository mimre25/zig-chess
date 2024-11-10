# Zig Chess

A small chess game in the CLI implemented in zig.

> [!NOTE]
> This project was implemented to try zig and has some rough edges, missing features ([google en passant](https://www.reddit.com/r/AnarchyChess/)), and probably bugs.

This project uses `zig 0.13.0`.

## Build
With zig installed, just run
```cli
zig build
```

## Test
This has a few tests implemented that can be run either via
```cli
zig test src/test.zig
```
or with
```cli
zig build test
```
> [!NOTE]
> One of the tests plays a test game ([Bertholee Rob - Judit Polgar (1990)](https://www.chess.com/games/view/470442)) that hangs when run via `zig build test` for some reason :man_shrugging:

## Running
To play a game just run
```cli
zig build run
```

The game is played by inputting moves in algebraic chess notation.
There are a few extra inputs that are possible:
- `resign` - to resign
- `draw` - to offer a draw
- `accept` - to accept a draw offer
- `decline` - to decline a draw offer

