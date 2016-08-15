module Don't.Worry.I.Know.What.I'm.Doing exposing (..)

{-|
Sometimes you need to tell the compiler that everything will be alright.

Usually this happens when you are case matching on something,
you can prove that certain cases cannot happen,
but elm still wants you to handle the cases that cannot happen anyway.

@docs believe_me
-}

{-|
This is just [`Debug.crash`](http://package.elm-lang.org/packages/elm-lang/core/latest/Debug#crash) with a prefixed error message.

If you use this, pass in a string of your module name and the name of the function where you think you're smarter than the compiler.
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
