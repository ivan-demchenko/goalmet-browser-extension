module Main exposing (..)

import Browser
import Derberos.Date.Calendar as C
import Derberos.Date.Core as DC
import Derberos.Date.Utils as DU
import Goal
import GoalCalendar
import Html exposing (Html, button, div, header, input, li, main_, section, span, text, ul)
import Html.Attributes exposing (class, value)
import Html.Events exposing (onClick, onInput)
import Task
import Time as T
import Utils


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }


init : () -> ( Model, Cmd Msg )
init _ =
    let
        timeCmd =
            Task.perform GotTime T.now

        today =
            DC.civilToPosix <| DC.posixToCivil <| DU.resetTime <| T.millisToPosix 0

        model =
            { goals = []
            , newGoalText = ""
            , daysOfMonth = []
            , now = today
            }
    in
    ( model, timeCmd )


type alias Model =
    { goals : List Goal.Goal
    , now : T.Posix
    , daysOfMonth : List T.Posix
    , newGoalText : String
    }


type Msg
    = SetNewGoalsText String
    | GotTime T.Posix
    | AddGoal
    | Noop


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Noop ->
            ( model, Cmd.none )

        GotTime now ->
            let
                daysOfMonth =
                    List.map DU.resetTime (C.getCurrentMonthDates T.utc now)
            in
            ( { model | now = DU.resetTime now, daysOfMonth = daysOfMonth }, Cmd.none )

        SetNewGoalsText str ->
            ( { model | newGoalText = str }, Cmd.none )

        AddGoal ->
            let
                ng =
                    Goal.Goal model.newGoalText Utils.mockedHistory

                nm =
                    { model | newGoalText = "", goals = ng :: model.goals }
            in
            ( nm, Cmd.none )


renderGoal : Model -> Goal.Goal -> Html Msg
renderGoal model goal =
    li
        []
        [ span [ class "font-thin text-4xl p-3 text-center hover:font-light" ] [ text goal.text ]
        , Html.map (\_ -> Noop) <| GoalCalendar.view model.daysOfMonth goal.daysTracked model.now
        ]


renderGoals : Model -> List Goal.Goal -> Html Msg
renderGoals model items =
    case items of
        [] ->
            section [] [ text "Add your first goal" ]

        goals ->
            ul [ class "flex-1 flex flex-col" ] <|
                List.map (renderGoal model) goals


view : Model -> Html Msg
view model =
    div [ class "h-full flex flex-col" ]
        [ header [ class "p-4 border bottom-1" ]
            [ input
                [ class "w-1/3 p-1 border-b border-gray-400 focus:border-b-green-500 focus:outline-none"
                , onInput SetNewGoalsText
                , value model.newGoalText
                ]
                []
            , button
                [ class "px-4 py-1 rounded"
                , onClick AddGoal
                ]
                [ text "Add a goal" ]
            ]
        , main_
            [ class "flex-1 flex flex-col items-center justify-center" ]
            [ renderGoals model model.goals
            ]
        ]
