module Don't.Worry.I.Know.What.I'm.Doing exposing (..)

{-|
@docs believe_me
-}

{-|
-}
believe_me : String -> a
believe_me location =
  Debug.crash <| """
Congratulations, you broke the compiler!

In actuality, while it is possible the compiler did break,
probably the library writer did not handle all the cases.

Please report this error to the library writer
instead of escalating to the compiler writer.

The error occurred in:
""" ++ location
