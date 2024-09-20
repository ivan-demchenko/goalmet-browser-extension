module Goal.Utils exposing (..)

import Time as T


type alias GoalContext =
    { daysOfMonth : List T.Posix
    , now : T.Posix
    }


isDayTracked : T.Posix -> List T.Posix -> Bool
isDayTracked day =
    let
        isMatch =
            \( d1, d2 ) -> (T.toMonth T.utc d1 == T.toMonth T.utc d2) && (T.toDay T.utc d1 == T.toDay T.utc d2)
    in
    List.any (\d -> isMatch ( day, d ))


monthToStr : T.Month -> String
monthToStr month =
    case month of
        T.Jan ->
            "Jan"

        T.Feb ->
            "Feb"

        T.Mar ->
            "Mar"

        T.Apr ->
            "Apr"

        T.May ->
            "May"

        T.Jun ->
            "Jun"

        T.Jul ->
            "Jul"

        T.Aug ->
            "Aug"

        T.Sep ->
            "Sep"

        T.Oct ->
            "Oct"

        T.Nov ->
            "Nov"

        T.Dec ->
            "Dec"
