port module Main exposing (..)

import Browser
import Derberos.Date.Calendar as C
import Derberos.Date.Core as DC
import Derberos.Date.Utils as DU
import Goal
import Goal.Utils
import Html exposing (Html, button, div, header, input, main_, section, text, ul)
import Html.Attributes exposing (class, value)
import Html.Events exposing (onClick, onInput)
import Json.Decode as D
import Json.Encode as E
import Task
import Time as T


type alias Model =
    { goals : List Goal.Goal
    , now : T.Posix
    , daysOfMonth : List T.Posix
    , newGoalText : String
    }


type alias PortDataModel =
    { goals : List Goal.Goal }


port saveData : E.Value -> Cmd msg


type Msg
    = SetNewGoalsText String
    | GotTime T.Posix
    | AddGoal
    | FromGoal String Goal.Msg


main : Program E.Value Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }


init : E.Value -> ( Model, Cmd Msg )
init savedGoalsJSON =
    let
        timeCmd =
            Task.perform GotTime T.now

        today =
            DC.civilToPosix <| DC.posixToCivil <| DU.resetTime <| T.millisToPosix 0

        recoveredGoals =
            case D.decodeValue Goal.goalsDecoder savedGoalsJSON of
                Ok goals ->
                    goals

                Err _ ->
                    []

        model =
            { goals = recoveredGoals
            , newGoalText = ""
            , daysOfMonth = []
            , now = today
            }
    in
    ( model, timeCmd )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FromGoal id goalMsg ->
            let
                mapUpdate =
                    \g ->
                        if g.text == id then
                            Goal.update goalMsg g

                        else
                            g

                updatedGoals =
                    List.map mapUpdate model.goals
            in
            ( { model | goals = updatedGoals }
            , Cmd.batch [ saveData (Goal.goalsEncoder updatedGoals) ]
            )

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
                newGoal =
                    Goal.Goal model.newGoalText []

                goals =
                    newGoal :: model.goals
            in
            ( { model | newGoalText = "", goals = goals }
            , Cmd.batch [ saveData (Goal.goalsEncoder goals) ]
            )


renderGoals : Model -> List Goal.Goal -> Html Msg
renderGoals model items =
    case items of
        [] ->
            section [] [ text "Add your first goal" ]

        goals ->
            let
                ctx =
                    Goal.Utils.GoalContext model.daysOfMonth model.now

                render =
                    \g -> Html.map (FromGoal (Goal.getGoalId g)) <| Goal.renderGoal ctx g
            in
            ul [ class "flex-1 flex flex-col" ] <|
                List.map render goals


view : Model -> Html Msg
view model =
    div [ class "h-full flex flex-col" ]
        [ header [ class "p-4 mb-4 flex justify-center" ]
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
