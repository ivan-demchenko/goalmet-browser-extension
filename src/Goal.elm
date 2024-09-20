module Goal exposing (..)

import Goal.Calendar as GC
import Goal.Utils
import Html exposing (Html, li, span, text)
import Html.Attributes exposing (class)
import Json.Decode as D
import Json.Encode as E
import Time


type Msg
    = Noop


type alias Goal =
    { text : String
    , daysTracked : List Time.Posix
    }


goalsDecoder : D.Decoder (List Goal)
goalsDecoder =
    D.list goalDecoder


goalDecoder : D.Decoder Goal
goalDecoder =
    D.map2 Goal
        (D.field "text" D.string)
        (D.field "daysTracked" <| D.list <| D.map Time.millisToPosix D.int)


goalsEncoder : List Goal -> E.Value
goalsEncoder items =
    E.list goalEncoder items


goalEncoder : Goal -> E.Value
goalEncoder goal =
    E.object
        [ ( "text", E.string goal.text )
        , ( "daysTracked", E.list E.int <| List.map Time.posixToMillis goal.daysTracked )
        ]


renderGoal : Goal.Utils.GoalContext -> Goal -> Html Msg
renderGoal ctx goal =
    li
        [ class "flex flex-col p-3 hover:shadow-lg group transition-shadow" ]
        [ span [ class "font-thin text-4xl p-3 text-center" ] [ text goal.text ]
        , Html.map (\_ -> Noop) <| GC.view ctx.daysOfMonth goal.daysTracked ctx.now
        ]
