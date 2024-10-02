module Utils exposing (..)

import Derberos.Date.Calendar as DDC
import Derberos.Date.Core as TimeCore
import Derberos.Date.Utils as DDU
import Html exposing (Attribute)
import Html.Attributes exposing (attribute)
import Random
import Time
import UUID


strToUUID : String -> UUID.UUID
strToUUID str =
    str |> String.toList |> List.map Char.toCode |> List.sum |> (\seed -> Random.step UUID.generator (Random.initialSeed seed) |> Tuple.first)


getDaysOfMonth : Time.Posix -> List Time.Posix
getDaysOfMonth day =
    DDC.getCurrentMonthDates Time.utc day
        |> List.map DDU.resetTime


testId : String -> Attribute msg
testId val =
    attribute "data-testid" val


isSamePosix : Time.Posix -> Time.Posix -> Bool
isSamePosix t1 t2 =
    Time.posixToMillis t1 == Time.posixToMillis t2


isSameDay : Time.Posix -> Time.Posix -> Bool
isSameDay t1 t2 =
    (Time.toYear Time.utc t1 == Time.toYear Time.utc t2)
        && (Time.toMonth Time.utc t1 == Time.toMonth Time.utc t2)
        && (Time.toDay Time.utc t1 == Time.toDay Time.utc t2)


setTimeOfDay : Time.Posix -> Time.Posix -> Time.Posix
setTimeOfDay dest src =
    let
        { year, month, day } =
            TimeCore.posixToCivil dest |> Debug.log "T1"

        { hour, minute, second, millis } =
            TimeCore.posixToCivil src |> Debug.log "T2"
    in
    TimeCore.civilToPosix <| TimeCore.newDateRecord year month day hour minute second millis Time.utc


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
