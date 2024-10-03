module DayNote exposing (..)

import DataModel exposing (TrackingEntry)
import Html exposing (Html, button, div, span, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Time
import Utils


getTimestamp : TrackingEntry -> Time.Posix
getTimestamp =
    .timestamp


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
