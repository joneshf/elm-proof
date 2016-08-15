module Main exposing (main)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.App

import Equivalence exposing (..)
import Permissions.Admin as Admin exposing (Admin)
import Permissions.Mod as Mod exposing (Mod)
import Permissions.User as User exposing (User)

main : Program Never
main =
  Html.App.program
    { init = modelAdmin "Pat" ! []
    , subscriptions = subscriptions
    , update = update
    , view = view
    }

-- Subscriptions

subscriptions : Model permissions -> Sub permissions
subscriptions model =
  case model of
    ModelUser (_, from) _ ->
      Sub.map from User.subscriptions
    ModelMod (_, from) _ ->
      Sub.map from Mod.subscriptions
    ModelAdmin (_, from) _ ->
      Sub.map from Admin.subscriptions

-- Model

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

-- Update

update : permissions -> Model permissions -> (Model permissions, Cmd permissions)
update perms model =
  case model of
    ModelUser (to, from) _ ->
      model ! [Cmd.map from (User.commands (to perms))]

    ModelMod (to, from) _ ->
      model ! [Cmd.map from (Mod.commands (to perms))]

    ModelAdmin (to, from) _ ->
      model ! [Cmd.map from (Admin.commands (to perms))]

-- View

view : Model permissions -> Html permissions
view model =
  case model of
    ModelUser _ { name } ->
      viewName name

    ModelMod (_, from) { name } ->
      div
        [vertical]
        [ viewName name
        , Html.App.map from (Mod.view Mod.Warn)
        ]

    ModelAdmin (_, from) { name } ->
      div
        [vertical]
        [ viewName name
        , Html.App.map from (Admin.view Admin.Delete)
        ]

vertical : Attribute a
vertical =
  style
    [ ("align-items", "center")
    , ("display", "flex")
    , ("flex-direction", "column")
    ]

viewName : String -> Html a
viewName name =
  text ("Welcome " ++ name ++ "!")
