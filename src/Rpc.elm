port module Rpc exposing (InboundCommand(..), OutboundCommand(..), decodeRawCommand, sendCommand)

import DataModel
import Json.Decode as D
import Json.Encode as E


type InboundCommand
    = InitialGoals (List DataModel.Goal)


type OutboundCommand
    = SaveGoals (List DataModel.Goal)


port sendRPC : E.Value -> Cmd msg


inboundCommandDecoder : D.Decoder InboundCommand
inboundCommandDecoder =
    D.field "command" D.string
        |> D.andThen
            (\command ->
                case command of
                    "initial-goals" ->
                        D.field "payload" <| D.map InitialGoals (D.list DataModel.goalDecoder)

                    _ ->
                        D.fail ("Unknown PRC command: " ++ command)
            )


decodeRawCommand : E.Value -> Result D.Error InboundCommand
decodeRawCommand raw =
    D.decodeValue inboundCommandDecoder raw


outboundCommandEncoder : OutboundCommand -> E.Value
outboundCommandEncoder cmd =
    case cmd of
        SaveGoals goals ->
            E.object
                [ ( "command", E.string "save-goals" )
                , ( "payload", E.list DataModel.goalEncoder goals )
                ]


sendCommand : OutboundCommand -> Cmd msg
sendCommand cmd =
    outboundCommandEncoder cmd |> sendRPC
