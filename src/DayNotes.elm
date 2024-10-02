module DayNotes exposing (..)

import DataModel exposing (TrackingEntry)
import DayNote
import Html exposing (Html, div, li, section, text, ul)
import Html.Attributes exposing (class)
import Time
import Utils


view : (Time.Posix -> msg) -> Time.Posix -> List TrackingEntry -> Html msg
view onDeleteNote day entries =
    section
        [ class "w-2/3 mt-2"
        , Utils.testId "goal-tracking-notes"
        ]
        [ div [ class "text-sm" ] [ text <| "Notes for " ++ Utils.formatDateFull day ]
        , ul
            [ class "divide-solid divide-y dark:divide-slate-600" ]
            (if List.isEmpty entries then
                [ li [ class "py-1 text-gray-500" ] [ text "No comments for this day" ] ]

             else
                List.map (DayNote.view onDeleteNote) entries
            )
        ]
