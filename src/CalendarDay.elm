module CalendarDay exposing (ViewModel, view)

import Html exposing (Html, button, text)
import Html.Attributes exposing (classList)
import Html.Events exposing (onClick)
import Time


type alias ViewModel =
    { hasNotes : Bool
    , isSelected : Bool
    , day : Time.Posix
    }


classOfStatus : ViewModel -> String
classOfStatus model =
    if model.isSelected then
        "bg-blue-300"

    else if model.hasNotes then
        "bg-green-300"

    else
        "bg-gray-200"


view : (Time.Posix -> msg) -> ViewModel -> Html msg
view handleClick model =
    let
        dayStr =
            String.fromInt << Time.toDay Time.utc <| model.day
    in
    button
        [ classList
            [ ( "text-center text-xs text-gray-600 font-bold rounded w-6 py-1 ", True )
            , ( classOfStatus model, True )
            ]
        , onClick (handleClick model.day)
        ]
        [ text dayStr ]
