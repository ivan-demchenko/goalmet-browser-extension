port module Main exposing (..)

import Browser
import Derberos.Date.Calendar as C
import Derberos.Date.Core as DC
import Derberos.Date.Utils as DU
import Goal
import Goal.Utils
import Html exposing (Html, button, div, header, input, main_, section, text, ul)
import Html.Attributes exposing (class, disabled, value)
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
    , canAddGoal : Bool
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
            , canAddGoal = False
            }
    in
    ( model, timeCmd )


deleteGoal : String -> List Goal.Goal -> List Goal.Goal
deleteGoal id goals =
    List.filter (\g -> id /= Goal.getGoalId g) goals


updateGoals : Goal.Msg -> String -> List Goal.Goal -> List Goal.Goal
updateGoals goalMsg id goals =
    let
        updateGoalFn =
            \g ->
                if g.text == id then
                    Goal.update goalMsg g

                else
                    g
    in
    List.map updateGoalFn goals


isGoalExist : List Goal.Goal -> String -> Bool
isGoalExist goals newGoalText =
    List.any (\g -> g.text == newGoalText) goals


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FromGoal id goalMsg ->
            if Goal.isDeleteRequest goalMsg then
                let
                    updatedGoals =
                        deleteGoal id model.goals
                in
                ( { model | goals = updatedGoals }
                , Cmd.batch [ saveData (Goal.goalsEncoder updatedGoals) ]
                )

            else
                let
                    newGoals =
                        updateGoals goalMsg id model.goals
                in
                ( { model | goals = newGoals }
                , Cmd.batch [ saveData (Goal.goalsEncoder newGoals) ]
                )

        GotTime now ->
            let
                daysOfMonth =
                    List.map DU.resetTime (C.getCurrentMonthDates T.utc now)
            in
            ( { model | now = DU.resetTime now, daysOfMonth = daysOfMonth }, Cmd.none )

        SetNewGoalsText str ->
            ( { model
                | newGoalText = str
                , canAddGoal = not <| String.isEmpty str || isGoalExist model.goals str
              }
            , Cmd.none
            )

        AddGoal ->
            let
                newGoal =
                    Goal.Goal model.newGoalText []

                goals =
                    newGoal :: model.goals
            in
            ( { model
                | newGoalText = ""
                , goals = goals
                , canAddGoal = False
              }
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
            ul [ class "flex-1 flex flex-col justify-center" ] <|
                List.map render goals


view : Model -> Html Msg
view model =
    div [ class "h-full flex flex-col" ]
        [ header [ class "p-4 mb-4 flex justify-center gap-1" ]
            [ input
                [ class "w-1/3 p-1 border-b border-gray-400 focus:border-b-green-500 focus:outline-none"
                , onInput SetNewGoalsText
                , value model.newGoalText
                ]
                []
            , button
                [ class "px-4 py-1 rounded bg-slate-200 hover:bg-slate-300 disabled:bg-white disabled:text-gray-400"
                , onClick AddGoal
                , disabled <| not model.canAddGoal
                ]
                [ text "Add a goal" ]
            ]
        , main_
            [ class "flex-1 flex flex-col items-center justify-center" ]
            [ renderGoals model model.goals
            ]
        ]
