module DataModel exposing (..)

import Json.Decode as JD
import Json.Encode as Encode
import Time


type alias TrackingEntry =
    { timestamp : Time.Posix
    , note : String
    }


type alias Goal =
    { goal : String
    , trackingEntries : List TrackingEntry
    }


trackingEntryDecoder : JD.Decoder TrackingEntry
trackingEntryDecoder =
    JD.map2 TrackingEntry
        (JD.field "timestamp" <| JD.map Time.millisToPosix JD.int)
        (JD.field "note" JD.string)


trackingEntryEncoder : TrackingEntry -> Encode.Value
trackingEntryEncoder entry =
    Encode.object
        [ ( "timestamp", Encode.int <| Time.posixToMillis entry.timestamp )
        , ( "note", Encode.string entry.note )
        ]


goalDecoder : JD.Decoder Goal
goalDecoder =
    JD.map2 Goal
        (JD.field "goal" JD.string)
        (JD.field "trackingEntries" <| JD.list trackingEntryDecoder)


goalEncoder : Goal -> Encode.Value
goalEncoder data =
    Encode.object
        [ ( "goal", Encode.string data.goal )
        , ( "trackingEntries", Encode.list trackingEntryEncoder data.trackingEntries )
        ]
