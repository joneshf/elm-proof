module Main exposing (main)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.App

import Equality exposing (..)
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
    ModelUser proof _ ->
      Sub.map (symmCast proof) User.subscriptions
    ModelMod proof _ ->
      Sub.map (symmCast proof) Mod.subscriptions
    ModelAdmin proof _ ->
      Sub.map (symmCast proof) Admin.subscriptions

-- Model

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

-- Update

update : permissions -> Model permissions -> (Model permissions, Cmd permissions)
update perms model =
  case model of
    ModelUser proof _ ->
      model ! [Cmd.map (symmCast proof) (User.commands (cast proof perms))]

    ModelMod proof _ ->
      model ! [Cmd.map (symmCast proof) (Mod.commands (cast proof perms))]

    ModelAdmin proof _ ->
      model ! [Cmd.map (symmCast proof) (Admin.commands (cast proof perms))]

-- View

view : Model permissions -> Html permissions
view model =
  case model of
    ModelUser _ { name } ->
      viewName name

    ModelMod proof { name } ->
      div
        [vertical]
        [ viewName name
        , Html.App.map (symmCast proof) (Mod.view Mod.Warn)
        ]

    ModelAdmin proof { name } ->
      div
        [vertical]
        [ viewName name
        , Html.App.map (symmCast proof) (Admin.view Admin.Delete)
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
