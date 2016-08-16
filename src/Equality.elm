module Equality exposing (Equal, refl, symm, trans, inj, symmInj, cast, symmCast)

{-|
A module providing primitives for proving type equalities.

Type equality is stronger than type equivalence.
With equivalence, we assert that there is some way to get from one type to the other (and back again).
With equality, we assert that there is exactly one type we're even talking about!

@docs Equal, refl, symm, trans, inj, symmInj, cast, symmCast
-}

{-|
A type that expresses two types being equal.

The only reason this works is that the value constructor is not exposed from the module.
If the value constructor is exposed, we end up with only being able to express equivalence.
-}
type Equal a b
  = Eq (a -> b) (b -> a)

{-|
Type equalities are reflexive.

Trivially, every type is equal to itself.
-}
refl : Equal a a
refl =
  Eq identity identity

{-|
Type equalities are symmetric.

If we know `a` is equal to `b`, then we also know `b` is equal to `a`.
-}
symm : Equal a b -> Equal b a
symm (Eq f g) =
  Eq g f

{-|
Type equalities are transitive.

If we know `a` is equal to `b`, and if we know `b` is equal to `c`,
then we also know `a` is equal to `c`.
-}
trans : Equal a b -> Equal b c -> Equal a c
trans (Eq f g) (Eq h i) =
  Eq (f >> h) (g << i)

{-|
Type equalities are injective.

If we know `a` is equal to `c`, and if we know `b` is equal to `c`,
then we also know `a` is equal to `b`.
-}
inj : Equal a c -> Equal b c -> Equal a b
inj ac bc =
  trans ac (symm bc)

{-|
Type equalities are injective in a symmetric way.

If we know `a` is equal to `b`, and if we know `a` is equal to `c`,
then we also know `b` is equal to `c`.
-}
symmInj : Equal a b -> Equal a c -> Equal b c
symmInj ab ac =
  trans (symm ab) ac

{-|
If we know that `a` is equal to `b`, and we have an `a`,
then we can get a `b`.
-}
cast : Equal a b -> a -> b
cast (Eq f _) =
  f

{-|
If we know that `a` is equal to `b`, and we have a `b`,
then we can get an `a`.
-}
symmCast : Equal a b -> b -> a
symmCast (Eq _ g) =
  g
