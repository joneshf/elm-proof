module Equivalence exposing (..)

{-|
A module providing primitives for proving type equivalence.

@docs Equiv, refl, symm, trans
-}

{-|
We represent type equivalence by a type isomorphism.

If we want to say two types are equivalent,
we need to provide a way to convert between them.

N.B. This is different from type equality in important ways.
For more information, see:
Parametricity, Type Equality and Higher-order Polymorphism (Vytiniotis, Weirich)
http://repository.upenn.edu/cgi/viewcontent.cgi?article=1675&context=cis_papers
-}
type alias Equiv a b =
  (a -> b, b -> a)

{-|
Type equivalences are reflexive.

Every type is equivalent to itself.

That is to say:
`Int` is equivalent to `Int`,
`Maybe a` is equivalent to `Maybe a`,
and so on.
-}
refl : Equiv a a
refl =
  (identity, identity)

{-|
Type equivalences are symmetric.

If we know `a` is equivalent to `b`, then we also know `b` is equivalent to `a`.
-}
symm : Equiv a b -> Equiv b a
symm (f, g) =
  (g, f)

{-|
Type equivalences are transitive.

If we know `a` is equivalent to `b`, and if we know `b` is equivalent to `c`,
then we also know `a` is equivalent to `c`.
-}
trans : Equiv a b -> Equiv b c -> Equiv a c
trans (f, g) (h, i) =
  (f >> h, g << i)
