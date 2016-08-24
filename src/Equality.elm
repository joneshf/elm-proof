module Equality exposing (Equal, refl, symm, trans, inj, symmInj, cast, symmCast)

{-|
A module providing primitives for proving type equalities.

Type equality is stronger than type equivalence.
With equivalence, we assert that there is some way to get from one type to the other (and back again).
With equality, we assert that there is exactly one type we're even talking about!

@docs Equal, refl, symm, trans, inj, symmInj, cast, symmCast

# Example

The [Equivalence example][] left a bad taste at the end with the realization that we weren't able to protect the generation of the view at compile time.
Fortunately all is not lost.
We can use a type very similar to [Equiv a b][], and not export its constructor.
Then, a malicious user cannot attempt to create their own "proof" ad-hoc.

[Equal a b][] is just such a type.
Let's start by replacing all occurrences of [Equiv a b][] with [Equal a b][]:

```elm
type Model permissions
  = ModelUser (Equal permissions User) { name : String }
  | ModelMod (Equal permissions Mod) { name : String }
  | ModelAdmin (Equal permissions Admin) { name : String }
```

We have a very similar API, so we can reuse the function [refl][] when creating `modelUser` and friends.

When we go to dispatch on the proofs, we can't destructure so we use [cast][] and [symmCast][] instead.

```elm
view : Model permissions -> Html permissions
view model =
  case model of
    ModelUser proof record ->
      Html.App.map (symmCast proof) (viewUser Comment)

    ModelMod proof record ->
      Html.App.map (symmCast proof) (viewMod Warn)

    ModelAdmin proof record ->
      Html.App.map (symmCast proof) (viewAdmin Delete)
```

That's it!

Now, if a malicious user tries to use `viewAdmin` in the `ModelMod` case, we get a compile time error!
Finally, we have elm helping us in a way that is even more productive than before!
Also, If we attempt to use any view at the top level (like in `main`), then the top level will only work for a certain permission level.
Like if we wanted to use `viewUser` at the top level, then the model could only work for `Model User`, and the current update would not typecheck at all!

If removing whole classes of bugs isn't pragmatic, I don't know what is.

Let's see it all together for completeness sake:

```elm
type User
  = Comment

type Mod
  = Warn

type Admin
  = Delete

type Model permissions
  = ModelUser (Equal permissions User) { name : String }
  | ModelMod (Equal permissions Mod) { name : String }
  | ModelAdmin (Equal permissions Admin) { name : String }

modelUser : String -> Model User
modelUser name =
  ModelUser refl { name = name }

modelMod : String -> Model Mod
modelMod name =
  ModelMod refl { name = name }

modelAdmin : String -> Model Admin
modelAdmin name =
  ModelAdmin refl { name = name }

view : Model permissions -> Html permissions
view model =
  case model of
    ModelUser proof record ->
      Html.App.map (symmCast proof) (viewUser Comment)

    ModelMod proof record ->
      Html.App.map (symmCast proof) (viewMod Warn)

    ModelAdmin proof record ->
      Html.App.map (symmCast proof) (viewAdmin Delete)

viewUser : User -> Html User
viewUser Comment =
  text "Welcome friend!"

viewMod : Mod -> Html Mod
viewMod Warn =
  button [ onClick Warn ]
    [ text "Warn all users" ]

viewAdmin : Admin -> Html Admin
viewAdmin Delete =
  button [ onClick Delete ]
    [ text "Delete all users" ]
```

[cast]: http://package.elm-lang.org/packages/joneshf/elm-proof/latest/Equality#cast
[Equal a b]: http://package.elm-lang.org/packages/joneshf/elm-proof/latest/Equality#Equal
[Equiv a b]: http://package.elm-lang.org/packages/joneshf/elm-proof/latest/Equivalence#Equiv
[Equivalence example]: http://package.elm-lang.org/packages/joneshf/elm-proof/latest/Equivalence#example
[refl]: http://package.elm-lang.org/packages/joneshf/elm-proof/latest/Equality#refl
[symmCast]: http://package.elm-lang.org/packages/joneshf/elm-proof/latest/Equality#symmCast
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
