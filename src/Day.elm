module Day exposing (..)

import Html exposing (Html, button, text)
import Html.Attributes exposing (classList)
import Html.Events exposing (onClick)
import Time
import Utils


type alias Model =
    { timestamp : Time.Posix
    , isSelected : Bool
    , hasHistory : Bool
    }


initEmpty : Bool -> Time.Posix -> Model
initEmpty isEmpty timestamp =
    Model timestamp False isEmpty


getId : Model -> Time.Posix
getId =
    .timestamp


matchTime : Time.Posix -> Model -> Bool
matchTime test day =
    Utils.isSameDay day.timestamp test


isSelected : Model -> Bool
isSelected =
    .isSelected


select : Model -> Model
select day =
    { day | isSelected = True }


unSelect : Model -> Model
unSelect day =
    { day | isSelected = False }


setHasHistory : Model -> Bool -> Model
setHasHistory day val =
    { day | hasHistory = val }


classOfStatus : Model -> String
classOfStatus model =
    if model.isSelected then
        "bg-blue-300 dark:bg-blue-700"

    else if model.hasHistory then
        "bg-green-300 dark:bg-green-700"

    else
        "bg-gray-200 dark:bg-gray-700"


view : (Time.Posix -> msg) -> Model -> Html msg
view handleClick model =
    let
        dayStr : String
        dayStr =
            String.fromInt <| Time.toDay Time.utc <| model.timestamp
    in
    button
        [ classList
            [ ( "text-center text-xs font-bold rounded w-6 py-1 ", True )
            , ( classOfStatus model, True )
            ]
        , onClick (handleClick model.timestamp)
        , Utils.testId "calendar-day"
        ]
        [ text dayStr ]
