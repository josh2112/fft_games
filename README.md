# Foster Family Times Games

Experimenting with Flutter by building a suite of mobile games similar to those from NYT. Stats are tracked and stored locally on your device; I neither use nor request any of your personal information.

So far we have Fosterdle (a clone of Wordle) and Fosteroes (a clone of Pips). More games and game modes coming as time and motivation allow!

All games are online at `https://joshuafoster.info/fftgames`.

## Fosterdle

If you're familiar with Wordle you'll be able to figure this one out. The 'official' daily word and guess dictionaries are used, so if a guess is accepted in Wordle it'll be accepted here, but we choose a different daily word.

## Fosteroes

Scratches the itch if you want more than 3 Pips puzzles in a day. Puzzles are automatically generated and never match NYT's. A new puzzle is available daily. There's also a randomly-generated puzzle option that allows for unlimited play. 

At the moment only easy-difficulty puzzles are generated. Until my puzzle generator is tweaked, these are usually exceedingly easy (although some can be surprisingly difficult!)

##  fft_games_lib

I'm in the process of moving some of the data structures and utilities (puzzle generators and solvers) to a separate library, [fft_games_lib](https://github.com/josh2112/fft_games_lib). This is pure dart and doesn't require Flutter. You can clone this repo and solve Fosteroes (and NYT Pips) puzzles on the command line.