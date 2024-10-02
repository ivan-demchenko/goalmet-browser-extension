module Main exposing (..)

import Browser
import DataModel exposing (Goal)
import Derberos.Date.Utils as DU
import Goal
import Goals
import Html exposing (Html, a, button, div, footer, header, input, main_, p, section, text)
import Html.Attributes exposing (class, classList, disabled, href, target, value)
import Html.Events exposing (onClick, onInput)
import Json.Encode as E
import Rpc
import Task
import Time as T
import Utils exposing (testId)


type alias Model =
    { goals : Goals.Model
    , now : T.Posix
    , newGoalText : String
    , canAddGoal : Bool
    , showAbout : Bool
    }


type Msg
    = SetNewGoalsText String
    | GotModel Model
    | AddGoal
    | ToggleAbout
    | FromGoals Goals.Msg
    | Noop


main : Program E.Value Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }


init : E.Value -> ( Model, Cmd Msg )
init rpcCommand =
    let
        cmd =
            T.now
                |> Task.map
                    (\now ->
                        let
                            recoveredGoals =
                                case Rpc.decodeRawCommand rpcCommand of
                                    Ok (Rpc.InitialGoals goals) ->
                                        goals

                                    Err _ ->
                                        []
                        in
                        { goals = Goals.init now recoveredGoals
                        , newGoalText = ""
                        , now = DU.resetTime now
                        , canAddGoal = False
                        , showAbout = False
                        }
                    )
                |> Task.perform GotModel

        model =
            { goals = []
            , newGoalText = ""
            , now = T.millisToPosix 0
            , canAddGoal = False
            , showAbout = False
            }
    in
    ( model, cmd )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleAbout ->
            ( { model | showAbout = not model.showAbout }, Cmd.none )

        FromGoals goalsMsg ->
            let
                ( updatedGoals, goalsCmd ) =
                    Goals.update goalsMsg model.goals
            in
            ( { model | goals = updatedGoals }
            , Cmd.batch
                [ Rpc.sendCommand <| Rpc.SaveGoals << Goals.toDataModel <| updatedGoals
                , Cmd.map FromGoals goalsCmd
                ]
            )

        GotModel newModel ->
            ( newModel, Cmd.none )

        SetNewGoalsText str ->
            ( { model
                | newGoalText = str
                , canAddGoal = not <| String.isEmpty str || Goals.isGoalExist str model.goals
              }
            , Cmd.none
            )

        AddGoal ->
            let
                goal =
                    Goal model.newGoalText []

                newGoals =
                    Goals.addGoal model.now goal model.goals
            in
            ( { model
                | newGoalText = ""
                , goals = newGoals
                , canAddGoal = False
              }
            , Rpc.sendCommand <| Rpc.SaveGoals <| List.map Goal.toDataModel newGoals
            )

        Noop ->
            ( model, Cmd.none )


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
            ]
        , main_
            [ class "flex-1 flex flex-col items-center justify-center"
            , testId "app-body"
            ]
            [ Html.map FromGoals (Goals.view model.goals) ]
        , renderAbout model
        , footer
            [ class "flex gap-4 justify-center p-4" ]
            [ button
                [ class "text-sm text-sky-700"
                , onClick ToggleAbout
                ]
                [ text "Support me ☕️" ]
            , a
                [ class "text-sm text-sky-700"
                , href "https://forms.gle/A8on4awiXMEmnAeh8"
                , target "blank"
                ]
                [ text "Leave feedback" ]
            ]
        ]
