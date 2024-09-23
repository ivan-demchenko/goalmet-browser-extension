module Utils exposing (..)

import Time


isSameDay : Time.Posix -> Time.Posix -> Bool
isSameDay t1 t2 =
    let
        isMatchingMonths =
            \( d1, d2 ) -> Time.toMonth Time.utc d1 == Time.toMonth Time.utc d2

        isMatchingDays =
            \( d1, d2 ) -> Time.toDay Time.utc d1 == Time.toDay Time.utc d2
    in
    isMatchingMonths ( t1, t2 ) && isMatchingDays ( t1, t2 )


monthToStr : Time.Month -> String
monthToStr month =
    case month of
        Time.Jan ->
            "Jan"

        Time.Feb ->
            "Feb"

        Time.Mar ->
            "Mar"

        Time.Apr ->
            "Apr"

        Time.May ->
            "May"

        Time.Jun ->
            "Jun"

        Time.Jul ->
            "Jul"

        Time.Aug ->
            "Aug"

        Time.Sep ->
            "Sep"

        Time.Oct ->
            "Oct"

        Time.Nov ->
            "Nov"

        Time.Dec ->
            "Dec"


formatDateFull : Time.Posix -> String
formatDateFull t =
    let
        day =
            Time.toDay Time.utc t |> String.fromInt

        month =
            Time.toMonth Time.utc t |> monthToStr
    in
    day ++ ". " ++ month
