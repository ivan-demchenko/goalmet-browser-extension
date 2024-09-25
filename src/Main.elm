port module Main exposing (..)

import Browser
import Derberos.Date.Calendar as C
import Derberos.Date.Core as DC
import Derberos.Date.Utils as DU
import Goal
import Html exposing (Html, a, button, div, header, input, main_, p, section, text, ul)
import Html.Attributes exposing (class, classList, disabled, href, id, target, value)
import Html.Events exposing (onClick, onInput)
import Json.Decode as D
import Json.Encode as E
import Task
import Time as T
import Utils exposing (testId)


type alias Model =
    { goals : List Goal.Goal
    , now : T.Posix
    , daysOfMonth : List T.Posix
    , newGoalText : String
    , canAddGoal : Bool
    , showAbout : Bool
    }


type alias PortDataModel =
    { goals : List Goal.Goal }


port saveData : E.Value -> Cmd msg


type Msg
    = SetNewGoalsText String
    | GotTime T.Posix
    | AddGoal
    | ToggleAbout
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
            , showAbout = False
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
        ToggleAbout ->
            ( { model | showAbout = not model.showAbout }, Cmd.none )

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
                goals =
                    Goal.newGoal model.newGoalText :: model.goals
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
            section [ class "text-gray-400 text-3xl font-thin" ] [ text "Add your first goal" ]

        goals ->
            let
                ctx =
                    Goal.GoalContext model.daysOfMonth model.now

                render =
                    \g -> Html.map (FromGoal (Goal.getGoalId g)) (Goal.renderGoal ctx g)
            in
            ul [ class "flex-1 flex flex-col justify-center" ] <|
                List.map render goals


myStory : String
myStory =
    """I use the browser all the time (like all of us) and I often find myself
opening a new tab and navigating to time-consuming websites almost automatically.
I created this extension because I wanted to stop and remind myself of my priorities.
"""


myStory2 : String
myStory2 =
    """I sincerely hope you find this extension useful, and if you do, please consider supporting my work.
"""


renderAbout : Model -> Html Msg
renderAbout model =
    div
        [ classList
            [ ( "bg-gray-300/50 dark:bg-gray-800/50 flex absolute w-full h-full items-center justify-center", True )
            , ( "hidden", not model.showAbout )
            ]
        ]
        [ div
            [ class "w-1/3 h-2/3 rounded-xl shadow-xl flex flex-col justify-center bg-white dark:bg-slate-800 dark:text-gray-400 text-center p-4" ]
            [ p [ class "mb-4" ] [ text "Greetings from the author of this extension! 👋" ]
            , p [ class "mb-4" ] [ text myStory ]
            , p [ class "mb-4" ] [ text myStory2 ]
            , a
                [ href "https://buymeacoffee.com/ivan.demchenko"
                , target "blank"
                , class "block mb-4 rounded-md bg-yellow-500 dark:bg-yellow-700 dark:text-yellow-200 self-center px-3 py-1"
                ]
                [ text "Buy me a coffee ☕️" ]
            , button
                [ onClick ToggleAbout
                , class "text-gray-600 dark:text-gray-400"
                ]
                [ text "Close" ]
            ]
        ]


view : Model -> Html Msg
view model =
    div [ class "h-full flex flex-col", testId "app-root" ]
        [ header [ class "p-4 mb-4 flex justify-center align-center gap-1", testId "app-header" ]
            [ section
                [ class "flex-1 flex justify-center gap-1" ]
                [ input
                    [ class "add-goal-input"
                    , onInput SetNewGoalsText
                    , value model.newGoalText
                    ]
                    []
                , button
                    [ class "add-goal-button"
                    , onClick AddGoal
                    , disabled <| not model.canAddGoal
                    ]
                    [ text "Add a goal" ]
                ]
            , button
                [ class "text-xs dark:text-blue-300"
                , onClick ToggleAbout
                ]
                [ text "Support me ☕️" ]
            ]
        , main_
            [ class "flex-1 flex flex-col items-center justify-center"
            , testId "app-body"
            ]
            [ renderGoals model model.goals ]
        , renderAbout model
        ]
