# elm-proof

A library for writing and verifying proofs in elm programs.

> Person A: Proofs in elm?!? But elm is a pragmatic language. Surely, you jest!
>
> Person B: Nay! Proofs are pragmatic.

## Example

**tl;dr** There's a more fleshed out example in the repo: [permissions][]

We can motivate this library by stealing the example from [elm-proxy][].
We've got different permission levels in our program that we want to enforce:

```elm
type Permissions
  = User
  | Mod
  | Admin
```

The simple thing to do is throw this into a field in a `Model`:

```elm
type alias Model =
  { name : String
  , permissions : Permissions
  }
```

But, then elm gives us no help when we mess up:

```elm
view : Model -> Html Msg
view model =
  case model.permissions of
    User ->
      viewUser

    Mod ->
      viewAdmin

    Admin ->
      viewMod

viewUser : Html msg
viewUser =
  text "Welcome friend!"

viewMod : Html Msg
viewMod =
  button [ onClick Mod ]
    [ text "Warn all users" ]

viewAdmin : Html Msg
viewAdmin =
  button [ onClick Admin ]
    [ text "Delete all users" ]
```

Elm happily compiles this program, and the `Mod`s can now delete all the users while the `Admin`s can't do anything to stop them!

With the solution proposed by [elm-proxy][] we have compile time guarantees that we can't accidentally use `Mod` as a `User` or some such. It's a very light weight start to getting more confidence in our codebase.

For all its good, it has one important drawback.
If we're not careful, we can [`reproxy`][reproxy] to an illegal state.
So while [elm-proxy][] is a great first step toward ensuring some confidence in our program, it's just that: a first step.
Let's take another step :).

## Equivalences

We want to take a slightly different approach to solving this problem than [elm-proxy][].
We want to use type equivalences as proofs rather than passing around dummy arguments.

Type equivalences are represented here as a pair of functions between two types.
The definition, is exactly that:

```elm
type alias Equiv a b =
  (a -> b, b -> a)
```

We are stating that `a` is equivalent to `b` when we have a function that maps `a`s to `b`s and a function that maps `b`s to `a`s.

We can use `Equiv a b` to express the differences in each permission of our program.

Again, let's start by bumping our value level permission constructors to the type level:

```elm
type User
  = User

type Mod
  = Mod

type Admin
  = Admin
```

Now that we have different types, let's talk about how we want to use the types.
We'd like to be able to have each view depend on the permission level and send messages of the same level as well.
We want functions with the types like: `User -> Html User`, `Mod -> Html Mod`, and `Admin -> Html Admin`.
Let's define these:

```elm
viewUser : User -> Html User
viewUser User =
  text "Welcome friend!"

viewMod : Mod -> Html Mod
viewMod Mod =
  button [ onClick Mod ]
    [ text "Warn all users" ]

viewAdmin : Admin -> Html Admin
viewAdmin Admin =
  button [ onClick Admin ]
    [ text "Delete all users" ]
```

Those value level constructors are a bit weird.
Let's rename them:

```elm
type User
  = Comment

type Mod
  = Warn

type Admin
  = Delete

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

That's a little better :).

Now that we have views for each individual permission level we'll need some way to combine each view into one top-level view.
The way that will play out will make more sense if we define our model first.

## Defining the model

Think about what we want.
We want to express that the permissions are exactly one of three levels.
Our model should not be a record, as records do not model exclusive cases.
We should model this as a union type with each case holding the appropriate type we want each case to handle:

```elm
type Model
  = ModelUser User { name : String }
  | ModelMod Mod { name : String }
  | ModelAdmin Admin { name : String }
```

However, this just puts us in the same boat as the [elm-proxy][] solution.
We want to express at the type level that, "No matter what case in the model we're looking at, we only use the appropriate view function".
We need to lift up to the type level what each case contains.
In some sense, we want to "index" the model based on the type it contains.

For example, in the `ModelUser` case, we want to "index" it based on the fact that it is a `User`.
But elm doesn't let us express that concept clearly, we have to fake it with type equivalences:

```elm
type Model permissions
  = ModelUser (Equiv permissions User) { name : String }
  | ModelMod (Equiv permissions Mod) { name : String }
  | ModelAdmin (Equiv permissions Admin) { name : String }
```

We are expressing that whatever case the `Model permissions` takes on has a proof of its equivalence in the respective case.

It might make more sense if we look at how we can construct one of these cases.
To make a `ModelUser`, we need to provide it two things:

1. An equivalence between some `permissions` and `User`.
1. A record with a `name` field that is a `String`.

The latter part is easy:

```elm
modelUser =
  ModelUser _ { name = "Pat" }
```

But what can we provide as the equivalence?
That's up to us to decide!
We need a pair of functions that go from `permissions -> User` and `User -> permissions`.
The first function is easy—we could always return `Comment`.
The second function is harder (actually it's impossible in general for all `permissions`).

Rather than trying to think through what possible implementations we can make, let's instead think about the type we want `modelUser` to have.
We're trying to construct a `Model User`, so that's the type we want `modelUser` to have!

```elm
modelUser : Model User
modelUser =
  ModelUser _ { name = "Pat" }
```

Since we've chosen a **specific** `permissions`—namely `User`—we have all the information we need.
We have specified that we want the equivalence to have the type `Equiv User User`.
In other words, we need to provide a pair of functions with type `User -> User` and `User -> User`.
Well that's easy, just return the argument in each case:

```elm
modelUser : Model User
modelUser =
  ModelUser (\x -> x, \x -> x) { name = "Pat" }
```

So, we've manage to construct a "proof" that we have a "model" with "permissions" equivalent to "User".
Cool!

Since this case is so common, this library provides an equivalence between the same type like we've defined up above: [`refl : Equiv a a`][refl].

# Defining the Unified View Function

Now, we can move on to displaying our model in a unified way.
We want to be able to say that for any `Model permissions` we're given, we can convert it to an `Html permissions`:

```elm
view : Model permissions -> Html permissions
```

Let's start implementing it, taking it one case at a time:

```elm
view : Model permissions -> Html permissions
view model =
  case model of
    ModelUser eq record ->
      viewUser Comment
    _ ->
      text ""
```

If we attempt to compile this, we end up getting an error.
Elm is rightly inferring that the type is actually `Model permissions -> Html User`.
We've stated that in the `ModelUser` case we want to return an `Html User`.
But we've annotated the type as returning an `Html permissions`.

This is great!
We still have the ability to say that we will not accidentally return the wrong thing.
And we cannot return any particular html value, we have to return one with `permissions` that match the `permissions` of the model.

What we need is a way to change the `Html User` to `Html permissions`.
Thankfully, `Html.App` provides a function `map : (a -> b) -> Html a -> Html b`.
So, if we can find a function `User -> permissions`, we can use `map` to get the type we want.
We have a `Model permissions`, and the case we're in is the `ModelUser` case.
That means we have an `Equiv permissions User`.
And remember that `Equiv permissions User` is just an alias for `(permissions -> User, User -> permissions)`.

We're carrying around just the very function we're looking for!
How lucky, ;).

```elm
view : Model permissions -> Html permissions
view model =
  case model of
    ModelUser (to, from) record ->
      Html.App.map from (viewUser Comment)
    _ ->
      text ""
```

And we can fill in the rest of the function:

```elm
view : Model permissions -> Html permissions
view model =
  case model of
    ModelUser (to, from) record ->
      Html.App.map from (viewUser Comment)

    ModelMod (to, from) record ->
      Html.App.map from (viewMod Warn)

    ModelAdmin (to, from) record ->
      Html.App.map from (viewAdmin Delete)
```

So, where are we now?
Can we still accidentally mess up and use the wrong view function:

```elm
view : Model permissions -> Html permissions
view model =
  case model of
    ModelUser (to, from) record ->
      Html.App.map from (viewUser Comment)

    ModelMod (to, from) record ->
      Html.App.map from (viewAdmin Delete)

    ModelAdmin (to, from) record ->
      Html.App.map from (viewMod Warn)
```

If we try to compile this, we get an error that `map` is given the wrong argument.
It's expecting an `Html Mod` but receiving an `Html Admin` or vice versa.
This is because we have `from : Mod -> permissions` and not `from : Admin -> permissions` or whatever.
So each case carries with it only the equivalence it can use, and not some other equivalence.

## Success!!

We did it!
We made a type level assertion that we wanted to only display the appropriate view in each case, and elm made sure we didn't mess up!

Of course, this solution isn't perfect, but it's safer than the [elm-proxy][] solution!

What if we try to be malicious and provide a different `from` function?

```elm
view : Model permissions -> Html permissions
view model =
  case model of
    ModelUser (to, from) record ->
      Html.App.map from (viewUser Comment)

    ModelMod (to, from) record ->
      let
        malicious : Admin -> permissions
        malicious _ =
          from Warn
      in
        Html.App.map malicious (viewAdmin Delete)

    ModelAdmin (to, from) record ->
      let
        malicious : Mod -> permissions
        malicious _ =
          from Delete
      in
        Html.App.map malicious (viewMod Warn)
```

Well first of all, that won't typecheck, as there's no sense of type variable scoping in elm.
But, assuming we comment out the type signatures, it'll type check fine.
Sounds kind of bad initially.
But think about it in depth a bit more.

This malicious function allows the view to be displayed, but any `permissions` coming from said view are still being translated into the appropriate level.
Meaning, that even if a `Mod` can see what an `Admin` sees, they can't actually do any of the actions that view says they can.

In other words, if a `Mod` had this "malicious" view, they would see a button that said "Delete all users".
But when they press the button, they would only be warning users not deleting them.
Obviously that's bad for its own reasons, but this example was contrived anyway :).

We still have a guarantee that each level respects their permission level.
And really that's all we wanted to begin with.

## Finally

After a little clean up, we have the following solution:

```elm
type User
  = Comment

type Mod
  = Warn

type Admin
  = Delete

type Model permissions
  = ModelUser (Equiv permissions User) { name : String }
  | ModelMod (Equiv permissions Mod) { name : String }
  | ModelAdmin (Equiv permissions Admin) { name : String }

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
    ModelUser (_, from) record ->
      Html.App.map from (viewUser Comment)

    ModelMod (_, from) record ->
      Html.App.map from (viewAdmin Delete)

    ModelAdmin (_, from) record ->
      Html.App.map from (viewMod Warn)

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

[elm-proxy]: http://package.elm-lang.org/packages/joneshf/elm-proxy/latest
[Proxy]: http://package.elm-lang.org/packages/joneshf/elm-proxy/latest/Proxy#Proxy
[permissions]: https://github.com/joneshf/elm-proof/tree/master/examples/permissions
[refl]: http://package.elm-lang.org/packages/joneshf/elm-proof/latest/Equivalence#refl
[reproxy]: http://package.elm-lang.org/packages/joneshf/elm-proxy/latest/Proxy#reproxy
