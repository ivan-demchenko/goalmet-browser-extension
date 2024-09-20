module Goal.Calendar exposing (view)

import Goal.Utils
import Html exposing (Html, div, header, section, text)
import Html.Attributes exposing (class)
import Time as T


renderDay : List T.Posix -> T.Posix -> Html ()
renderDay trackedDays day =
    let
        dayStr =
            Debug.toString <| T.toDay T.utc day

        isTracked =
            Goal.Utils.isDayTracked day trackedDays

        colorClass =
            if isTracked then
                "bg-green-200"

            else
                "bg-gray-200"
    in
    div
        [ class ("text-center text-xs text-gray-600 font-bold rounded w-6 py-1 " ++ colorClass) ]
        [ text dayStr ]


view : List T.Posix -> List T.Posix -> T.Posix -> Html ()
view daysOfMonth tracked today =
    let
        monthName =
            Goal.Utils.monthToStr <| T.toMonth T.utc today
    in
    section
        [ class "flex flex gap-1 transition-opacity opacity-20 group-hover:opacity-100" ]
    <|
        header [ class "font-bold" ] [ text monthName ]
            :: List.map (renderDay tracked) daysOfMonth
