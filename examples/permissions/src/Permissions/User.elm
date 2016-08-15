module Permissions.User exposing (..)

import WebSocket

type User
  = Subscribe
  | NewComment String

url : String
url =
  "ws://localhost:8080/user"

commands : User -> Cmd User
commands user =
  case user of
    Subscribe ->
      Cmd.none

    NewComment comment ->
      WebSocket.send url comment

subscriptions : Sub User
subscriptions =
  WebSocket.listen url (\_ -> Subscribe)
