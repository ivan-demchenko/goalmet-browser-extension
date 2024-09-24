module CalendarDay exposing (..)

import Html exposing (Html, button, text)
import Html.Attributes exposing (classList)
import Html.Events exposing (onClick)
import Time


type Status
    = Empty
    | Tracked
    | Selected


type alias Model =
    { day : Time.Posix
    , status : Status
    }


classOfStatus : Status -> String
classOfStatus status =
    case status of
        Empty ->
            "bg-gray-200"

        Tracked ->
            "bg-green-300"

        Selected ->
            "bg-blue-300"


view : (Time.Posix -> msg) -> Model -> Html msg
view handleClick model =
    let
        dayStr =
            String.fromInt << Time.toDay Time.utc <| model.day
    in
    button
        [ classList
            [ ( "text-center text-xs text-gray-600 font-bold rounded w-6 py-1 ", True )
            , ( classOfStatus model.status, True )
            ]
        , onClick (handleClick model.day)
        ]
        [ text dayStr ]
