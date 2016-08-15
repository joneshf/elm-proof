module Permissions.Mod exposing (..)

import Html exposing (..)
import Html.Events exposing (..)
import WebSocket

type Mod
  = Subscribe
  | Warn

url : String
url =
  "ws://localhost:8080/mod"

commands : Mod -> Cmd Mod
commands mod =
  case mod of
    Subscribe ->
      Cmd.none

    Warn ->
      WebSocket.send url "warn"

subscriptions : Sub Mod
subscriptions =
  WebSocket.listen url (\_ -> Subscribe)

view : Mod -> Html Mod
view permission =
  case permission of
    Warn ->
      button [ onClick Warn ]
        [ text "Warn all users" ]

    Subscribe ->
      text "Loading..."
