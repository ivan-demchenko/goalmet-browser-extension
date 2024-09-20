module Goal exposing (..)

import Goal.Calendar as GC
import Goal.Utils
import Html exposing (Html, li, span, text)
import Html.Attributes exposing (class)
import Time


type Msg
    = Noop


type alias Goal =
    { text : String
    , daysTracked : List Time.Posix
    }


renderGoal : Goal.Utils.GoalContext -> Goal -> Html Msg
renderGoal ctx goal =
    li
        [ class "flex flex-col p-3 hover:shadow-lg group transition-shadow" ]
        [ span [ class "font-thin text-4xl p-3 text-center" ] [ text goal.text ]
        , Html.map (\_ -> Noop) <| GC.view ctx.daysOfMonth goal.daysTracked ctx.now
        ]
