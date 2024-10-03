module Goal exposing (..)

import Calendar
import DataModel exposing (Goal, TrackingEntry)
import Day
import DayNotes
import Html exposing (Html, button, div, li, span, text, textarea)
import Html.Attributes exposing (class, classList, title, value)
import Html.Events exposing (onClick, onInput)
import Icons
import Task
import Time
import Utils


type alias Model =
    { goal : String
    , calendar : Calendar.Model
    , trackingEntries : List TrackingEntry
    , today : Time.Posix
    , showingDeleteDialog : Bool
    , showingTrackingDialog : Bool
    , showingNotes : Bool
    , noteText : String
    }


type Msg
    = CommitGoalTracking
    | FinishGoalTracking Time.Posix
    | DeleteGoal String
    | DeleteDayNote Time.Posix
    | FromCalendar Calendar.Msg
    | ShowTrackingModal
    | CancelTracking
    | ShowDeleteModal
    | CancelDeletion
    | SetTrackingNoteText String


toDataModel : Model -> Goal
toDataModel model =
    Goal model.goal model.trackingEntries


init : Time.Posix -> Goal -> Model
init today goalData =
    Model goalData.goal (Calendar.init today goalData.trackingEntries) goalData.trackingEntries today False False False ""


shouldUiStayOpen : Model -> Bool
shouldUiStayOpen model =
    model.showingDeleteDialog || model.showingTrackingDialog || Calendar.hasSelectedDay model.calendar


update : Msg -> Model -> ( Model, Cmd Msg, Maybe String )
update msg model =
    case msg of
        SetTrackingNoteText str ->
            ( { model | noteText = str }, Cmd.none, Nothing )

        ShowDeleteModal ->
            ( { model
                | showingDeleteDialog = True
                , showingTrackingDialog = False
              }
            , Cmd.none
            , Nothing
            )

        CancelDeletion ->
            ( { model | showingDeleteDialog = False }, Cmd.none, Nothing )

        ShowTrackingModal ->
            ( { model
                | showingTrackingDialog = True
                , showingDeleteDialog = False
              }
            , Cmd.none
            , Nothing
            )

        CancelTracking ->
            ( { model | showingTrackingDialog = False }, Cmd.none, Nothing )

        DeleteGoal id ->
            ( model, Cmd.none, Just id )

        FromCalendar calendarMsg ->
            ( { model | calendar = Calendar.update calendarMsg model.calendar }, Cmd.none, Nothing )

        FinishGoalTracking now ->
            let
                timestamp : Time.Posix
                timestamp =
                    Calendar.getSelectedDay model.calendar
                        |> Maybe.map (\selectedDay -> Utils.setTimeOfDay (Day.getId selectedDay) now)
                        |> Maybe.withDefault now

                newNotes : List TrackingEntry
                newNotes =
                    TrackingEntry timestamp model.noteText :: model.trackingEntries
            in
            ( { model
                | showingTrackingDialog = False
                , noteText = ""
                , trackingEntries = newNotes
                , calendar = Calendar.updateDays newNotes model.calendar
              }
            , Cmd.none
            , Nothing
            )

        CommitGoalTracking ->
            ( model, Task.perform FinishGoalTracking Time.now, Nothing )

        DeleteDayNote noteId ->
            let
                newNotes : List TrackingEntry
                newNotes =
                    List.filter (\entry -> not <| Utils.isSamePosix noteId entry.timestamp) model.trackingEntries
            in
            ( { model
                | trackingEntries = newNotes
                , calendar = Calendar.updateDays newNotes model.calendar
              }
            , Cmd.none
            , Nothing
            )



-- isDeleteRequest : Msg -> Bool
-- isDeleteRequest msg =
--     case msg of
--         DeleteGoal ->
--             True
--         _ ->
--             False


getId : Model -> String
getId =
    .goal


renderGoalBody : Model -> Html Msg
renderGoalBody model =
    div
        [ class "flex-1 flex flex-col p-3 justify-between items-center"
        , Utils.testId "goal-goal-body"
        ]
        [ span
            [ class "font-thin text-4xl pb-3 text-center" ]
            [ text model.goal ]
        , Html.map FromCalendar (Calendar.view model.calendar)
        , renderSelectedDayNotes model
        ]


renderDeleteAction : Model -> Html Msg
renderDeleteAction model =
    button
        [ classList
            [ ( "flex justify-center w-16 items-center transition-opacity opacity-0 group-hover:opacity-100", True )
            , ( "bg-red-100 dark:bg-red-900 opacity-100", model.showingDeleteDialog )
            ]
        , title "Delete this goal"
        , onClick ShowDeleteModal
        , Utils.testId "goal-delete-action"
        ]
        [ Icons.deleteIcon ]


renderTrackAction : Model -> Html Msg
renderTrackAction goal =
    button
        [ classList
            [ ( "flex justify-center w-16 items-center transition-opacity opacity-0 group-hover:opacity-100", True )
            , ( "bg-green-100 dark:bg-green-900 opacity-100", goal.showingTrackingDialog )
            ]
        , title "Track this goal for today"
        , onClick ShowTrackingModal
        , Utils.testId "goal-track-action"
        ]
        [ Icons.plusIcon ]


renderTrackingDialog : Model -> Html Msg
renderTrackingDialog goal =
    let
        trackingDay : Time.Posix
        trackingDay =
            Calendar.getSelectedDay goal.calendar
                |> Maybe.map Day.getId
                |> Maybe.withDefault goal.today
    in
    div
        [ classList
            [ ( "dialog", True )
            , ( "dialog-hidden", not goal.showingTrackingDialog )
            ]
        , Utils.testId "goal-tracking-dialog"
        ]
        [ span [] [ text <| "Record the " ++ Utils.formatDateFull trackingDay ++ ". Any comments?" ]
        , textarea
            [ class "textarea"
            , value goal.noteText
            , onInput SetTrackingNoteText
            ]
            []
        , div [ class "text-center" ]
            [ button
                [ onClick CommitGoalTracking
                , class "dialog-green"
                ]
                [ text "Commit" ]
            , button
                [ onClick CancelTracking
                , class "dialog-neutral"
                ]
                [ text "Cancel" ]
            ]
        ]


renderDeletionDialog : Model -> Html Msg
renderDeletionDialog model =
    div
        [ classList
            [ ( "dialog", True )
            , ( "dialog-hidden", not model.showingDeleteDialog )
            ]
        , Utils.testId "goal-deletion-dialog"
        ]
        [ div [ class "mb-2" ] [ text "Are you sure you want to delete it?" ]
        , div [ class "text-center" ]
            [ button
                [ onClick (DeleteGoal model.goal)
                , class "dialog-danger"
                ]
                [ text "Delete" ]
            , button
                [ onClick CancelDeletion
                , class "dialog-neutral"
                ]
                [ text "Cancel" ]
            ]
        ]


renderSelectedDayNotes : Model -> Html Msg
renderSelectedDayNotes model =
    let
        selectedDay : Maybe Day.Model
        selectedDay =
            Calendar.getSelectedDay model.calendar
    in
    case selectedDay of
        Just day ->
            let
                dayId : Time.Posix
                dayId =
                    Day.getId day
            in
            DayNotes.view
                DeleteDayNote
                dayId
                (List.filter (Utils.isSameDay dayId << .timestamp) model.trackingEntries)

        Nothing ->
            div [] []


view : Model -> Html Msg
view model =
    li
        [ classList
            [ ( "group goal", True )
            , ( "goal-open", shouldUiStayOpen model )
            ]
        ]
        [ renderDeleteAction model
        , renderGoalBody model
        , renderTrackAction model
        , renderTrackingDialog model
        , renderDeletionDialog model
        ]
