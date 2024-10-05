module Main exposing (..)

import Browser
import DataModel exposing (Goal)
import Derberos.Date.Utils as DU
import Goals
import Html exposing (Html, a, button, div, footer, header, input, main_, p, section, span, text, textarea)
import Html.Attributes exposing (class, classList, disabled, href, target, value)
import Html.Events exposing (onClick, onInput)
import Json.Encode as E
import Rpc
import Task
import Time as T
import UI.Dialog as UiDialog
import Utils exposing (testId)


type alias TrackingDialogView =
    { goal : String
    , trackingDay : T.Posix
    }


type alias Model =
    { goals : Goals.Model
    , today : T.Posix
    , newGoalText : String
    , canAddGoal : Bool
    , showAbout : Bool
    , goalToDelete : Maybe String
    , goalToTrack : Maybe TrackingDialogView
    , noteText : String
    }


type Msg
    = SetNewGoalsText String
    | GotModel Model
    | AddGoal
    | ToggleAbout
    | FromGoals Goals.Msg
    | ShowDeleteDialog String
    | HideDeleteDialog
    | DeleteGoal String
    | ShowTrackingDialog String (Maybe T.Posix)
    | HideTrackingDialog
    | StartGoalTracking
    | GotTrackingTime T.Posix
    | SetNoteText String


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
        cmd : Cmd Msg
        cmd =
            T.now
                |> Task.map
                    (\now ->
                        let
                            recoveredGoals : List Goal
                            recoveredGoals =
                                case Rpc.decodeRawCommand rpcCommand of
                                    Ok (Rpc.InitialGoals goals) ->
                                        goals

                                    _ ->
                                        []
                        in
                        { goals = Goals.init now recoveredGoals
                        , newGoalText = ""
                        , today = DU.resetTime now
                        , canAddGoal = False
                        , showAbout = False
                        , goalToDelete = Nothing
                        , goalToTrack = Nothing
                        , noteText = ""
                        }
                    )
                |> Task.perform GotModel

        model : Model
        model =
            { goals = []
            , newGoalText = ""
            , today = T.millisToPosix 0
            , canAddGoal = False
            , showAbout = False
            , goalToDelete = Nothing
            , goalToTrack = Nothing
            , noteText = ""
            }
    in
    ( model, cmd )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetNoteText str ->
            ( { model | noteText = str }
            , Cmd.none
            )

        ShowDeleteDialog goalId ->
            ( { model
                | goalToDelete = Just goalId
                , goals = Goals.setGoalStayOpen True goalId model.goals
              }
            , Cmd.none
            )

        HideDeleteDialog ->
            ( { model
                | goalToDelete = Nothing
                , goals =
                    model.goalToDelete
                        |> Maybe.map (\goalId -> Goals.setGoalStayOpen False goalId model.goals)
                        |> Maybe.withDefault model.goals
              }
            , Cmd.none
            )

        DeleteGoal goalId ->
            let
                updatedGoals : Goals.Model
                updatedGoals =
                    Goals.deleteGoal goalId model.goals
            in
            ( { model
                | goals = updatedGoals
                , goalToDelete = Nothing
              }
            , Rpc.sendCommand <| Rpc.SaveGoals <| Goals.toDataModel updatedGoals
            )

        ShowTrackingDialog goalId maybeSelectedDay ->
            let
                timestamp : T.Posix
                timestamp =
                    maybeSelectedDay
                        |> Maybe.withDefault model.today
            in
            ( { model
                | goalToTrack = Just (TrackingDialogView goalId timestamp)
                , goals = Goals.setGoalStayOpen True goalId model.goals
              }
            , Cmd.none
            )

        HideTrackingDialog ->
            ( { model
                | goalToTrack = Nothing
                , goals =
                    model.goalToTrack
                        |> Maybe.map (\goalToTrack -> Goals.setGoalStayOpen False goalToTrack.goal model.goals)
                        |> Maybe.withDefault model.goals
              }
            , Cmd.none
            )

        StartGoalTracking ->
            ( model
            , Task.perform GotTrackingTime T.now
            )

        GotTrackingTime time ->
            case model.goalToTrack of
                Just { goal, trackingDay } ->
                    let
                        timestamp : T.Posix
                        timestamp =
                            Utils.setTimeOfDay time trackingDay

                        updatedGoals : Goals.Model
                        updatedGoals =
                            Goals.addTrackingEntry goal timestamp model.noteText model.goals
                    in
                    ( { model
                        | goals = updatedGoals
                        , noteText = ""
                        , goalToTrack = Nothing
                      }
                    , Rpc.sendCommand <| Rpc.SaveGoals <| Goals.toDataModel updatedGoals
                    )

                Nothing ->
                    ( model, Cmd.none )

        ToggleAbout ->
            ( { model | showAbout = not model.showAbout }, Cmd.none )

        FromGoals goalsMsg ->
            let
                ( updatedGoals, goalsCmd ) =
                    Goals.update goalsMsg model.goals
            in
            ( { model | goals = updatedGoals }
            , Cmd.batch
                [ Rpc.sendCommand <| Rpc.SaveGoals <| Goals.toDataModel <| updatedGoals
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
                goal : Goal
                goal =
                    Goal model.newGoalText []

                updatedGoals : Goals.Model
                updatedGoals =
                    Goals.addGoal model.today goal model.goals
            in
            ( { model
                | newGoalText = ""
                , goals = updatedGoals
                , canAddGoal = False
              }
            , Rpc.sendCommand <| Rpc.SaveGoals <| Goals.toDataModel updatedGoals
            )


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


deleteGoalDialog : String -> Html Msg
deleteGoalDialog goalName =
    UiDialog.view
        { testId = "delete-note-dialog"
        , primaryAction =
            { onClick = DeleteGoal goalName
            , label = "Yes, delete"
            , style = UiDialog.Danger
            }
        , secondaryAction =
            { onClick = HideDeleteDialog
            , label = "No, dismiss"
            , style = UiDialog.Neutral
            }
        , content =
            [ span [] [ text <| "Are you sure you want to delete the goal " ++ goalName ]
            ]
        }


trackGoalDialog : TrackingDialogView -> Html Msg
trackGoalDialog { goal, trackingDay } =
    let
        trackingDayStr : String
        trackingDayStr =
            Utils.formatDateFull trackingDay
    in
    UiDialog.view
        { testId = "track-goal-dialog"
        , primaryAction =
            { onClick = StartGoalTracking
            , label = "Commit"
            , style = UiDialog.Success
            }
        , secondaryAction =
            { onClick = HideTrackingDialog
            , label = "Cancel"
            , style = UiDialog.Neutral
            }
        , content =
            [ p [ class "text-xl mb-2 text-gray-200 text-center" ] [ text goal ]
            , p [ class "text-gray-200 text-center" ] [ text <| "Track your progress " ++ trackingDayStr ]
            , textarea
                [ class "textarea"
                , onInput SetNoteText
                ]
                []
            ]
        }


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
            [ Goals.view
                { toSelf = FromGoals
                , onShowDeleteDialog = ShowDeleteDialog
                , onShowTrackingDialog = ShowTrackingDialog
                }
                model.goals
            ]
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
        , model.goalToDelete
            |> Maybe.map deleteGoalDialog
            |> Maybe.withDefault (div [] [])
        , model.goalToTrack
            |> Maybe.map trackGoalDialog
            |> Maybe.withDefault (div [] [])
        ]
