{-# LANGUAGE OverloadedStrings #-}
import Control.Monad
import Data.Text
import Network.WebSockets

main :: IO ()
main =
    runServer "127.0.0.1" 8080 server

server :: PendingConnection -> IO ()
server pending = do
    connection <- acceptRequest pending
    putStrLn "Client connected!"
    forever (echoData connection)

echoData :: Connection -> IO ()
echoData connection = do
    msg <- receiveData connection
    sendTextData connection (append "Echo: " msg)
