module Permissions.Admin exposing (Admin(..), commands, subscriptions, view)

import Html exposing (..)
import Html.Events exposing (..)
import WebSocket

type Admin
  = Subscribe
  | Delete

url : String
url =
  "ws://localhost:8080/admin"

commands : Admin -> Cmd Admin
commands admin =
  case admin of
    Subscribe ->
      Cmd.none

    Delete ->
      WebSocket.send url "delete"

subscriptions : Sub Admin
subscriptions =
  WebSocket.listen url (\_ -> Subscribe)

view : Admin -> Html Admin
view permission =
  case permission of
    Delete ->
      button [ onClick Delete ]
        [ text "Delete all users" ]

    Subscribe ->
      text "Loading..."
