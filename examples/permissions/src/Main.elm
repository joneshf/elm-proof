module Main exposing (main)

import Html exposing (..)
import Html.App
import Html.Events exposing (..)
import Html.Attributes exposing (..)

import WebSocket exposing (..)

import Equivalence exposing (..)

main : Program Never
main =
  Html.App.program (program (modelAdmin "Steve"))

program
  : Model permissions
  ->
    { init : (Model permissions, Cmd permissions)
    , update : permissions -> Model permissions -> (Model permissions, Cmd permissions)
    , subscriptions : Model permissions -> Sub permissions
    , view : Model permissions -> Html permissions
    }
program model =
  { init = model ! []
  , subscriptions = subscriptions
  , update = update
  , view = view
  }

-- Subscriptions

subscriptions : Model permissions -> Sub permissions
subscriptions model =
  case model of
    ModelUser (_, from) _ ->
      Sub.map from subscriptionsUser
    ModelMod (_, from) _ ->
      Sub.map from subscriptionsMod
    ModelAdmin (_, from) _ ->
      Sub.map from subscriptionsAdmin

subscriptionsUser : Sub User
subscriptionsUser =
  listen "ws://localhost:8080/user" (\_ -> SubscribeUser)

subscriptionsMod : Sub Mod
subscriptionsMod =
  listen "ws://localhost:8080/mod" (\_ -> SubscribeMod)

subscriptionsAdmin : Sub Admin
subscriptionsAdmin =
  listen "ws://localhost:8080/admin" (\_ -> SubscribeAdmin)

-- Commands

type User
  = SubscribeUser
  | NewComment String

commandsUser : User -> Cmd User
commandsUser user =
  case user of
    SubscribeUser ->
      Cmd.none

    NewComment comment ->
      send "ws://localhost:8080/user" comment

type Mod
  = SubscribeMod
  | Warn

commandsMod : Mod -> Cmd Mod
commandsMod mod =
  case mod of
    SubscribeMod ->
      Cmd.none

    Warn ->
      send "ws://localhost:8080/mod" "warn"

type Admin
  = SubscribeAdmin
  | Delete

commandsAdmin : Admin -> Cmd Admin
commandsAdmin admin =
  case admin of
    SubscribeAdmin ->
      Cmd.none

    Delete ->
      send "ws://localhost:8080/admin" "delete"

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
      model ! [Cmd.map from (commandsUser (to perms))]

    ModelMod (to, from) _ ->
      model ! [Cmd.map from (commandsMod (to perms))]

    ModelAdmin (to, from) _ ->
      model ! [Cmd.map from (commandsAdmin (to perms))]

-- View

view : Model permissions -> Html permissions
view model =
  case model of
    ModelUser _ { name } ->
      viewUser name

    ModelMod (_, from) { name } ->
      div
        [vertical]
        [ viewUser name
        , Html.App.map from (viewMod Warn)
        ]

    ModelAdmin (_, from) { name } ->
      div
        [vertical]
        [ viewUser name
        , Html.App.map from (viewAdmin Delete)
        ]

vertical : Attribute a
vertical =
  style
    [ ("align-items", "center")
    , ("display", "flex")
    , ("flex-direction", "column")
    ]

viewUser : String -> Html a
viewUser name =
  text ("Welcome " ++ name ++ "!")

viewMod : Mod -> Html Mod
viewMod permission =
  case permission of
    Warn ->
      button [ onClick Warn ]
        [ text "Warn all users" ]

    SubscribeMod ->
      text "Loading..."

viewAdmin : Admin -> Html Admin
viewAdmin permission =
  case permission of
    Delete ->
      button [ onClick Delete ]
        [ text "Delete all users" ]

    SubscribeAdmin ->
      text "Loading..."
