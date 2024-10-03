module UI.Dialog exposing (..)

import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Utils


type ActionStyle
    = Danger
    | Success
    | Neutral


type alias ActionConfig msg =
    { style : ActionStyle
    , label : String
    , onClick : msg
    }


type alias Config msg =
    { primaryAction : ActionConfig msg
    , secondaryAction : ActionConfig msg
    , content : List (Html msg)
    }


classByActionType : ActionStyle -> String
classByActionType actionType =
    case actionType of
        Danger ->
            "dialog-action-danger"

        Success ->
            "dialog-action-success"

        Neutral ->
            "dialog-action-neutral"


view : Config msg -> Html msg
view conf =
    div
        [ class "dialog"
        , Utils.testId "goal-tracking-dialog"
        ]
        [ div
            [ class "p-4" ]
            conf.content
        , div
            [ class "dialog-controls" ]
            [ button
                [ onClick conf.primaryAction.onClick
                , class <| classByActionType conf.primaryAction.style
                ]
                [ text conf.primaryAction.label ]
            , button
                [ onClick conf.secondaryAction.onClick
                , class <| classByActionType conf.secondaryAction.style
                ]
                [ text conf.secondaryAction.label ]
            ]
        ]
