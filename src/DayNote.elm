module DayNote exposing (..)

import DataModel exposing (TrackingEntry)
import Html exposing (Html, button, div, span, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Json.Decode as JD
import Json.Encode as JE
import Time
import Utils


decoder : JD.Decoder TrackingEntry
decoder =
    JD.map2 TrackingEntry
        (JD.field "timestamp" <| JD.map Time.millisToPosix JD.int)
        (JD.field "note" JD.string)


encoder : TrackingEntry -> JE.Value
encoder model =
    JE.object
        [ ( "timestamp", JE.int <| Time.posixToMillis model.timestamp )
        , ( "note", JE.string model.note )
        ]


getTimestamp : TrackingEntry -> Time.Posix
getTimestamp =
    .timestamp



-- type Msg = UpdateNote String


view : (Time.Posix -> msg) -> TrackingEntry -> Html msg
view deleteNote model =
    div
        [ class "py-1 flex gap-1" ]
        [ span [ class "grow" ] [ text model.note ]
        , button
            [ class "text-sm text-blue-400 dark:text-sky-700"
            , onClick (deleteNote model.timestamp)
            , Utils.testId "delete-note-btn"
            ]
            [ text "Delete" ]
        ]
