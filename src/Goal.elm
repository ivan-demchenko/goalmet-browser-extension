module Goal exposing (..)

import Calendar
import Html exposing (Html, button, div, li, section, span, text, textarea, ul)
import Html.Attributes exposing (class, classList, title, value)
import Html.Events exposing (onClick, onInput)
import Icons
import Json.Decode as D
import Json.Encode as E
import Time
import Utils


type UiMsg
    = ShowTrackingModal
    | CancelTracking
    | ShowDeleteModal
    | CancelDeletion
    | SelectDay Time.Posix
    | SetTrackingNoteText String


type Msg
    = CommitGoalTracking Time.Posix
    | DeleteGoal
    | Ui UiMsg


type alias TrackingRecord =
    { time : Time.Posix
    , note : String
    }


type alias GoalContext =
    { daysOfMonth : List Time.Posix
    , today : Time.Posix
    }


type alias UiModel =
    { showDeleteDialog : Bool
    , showTrackingDialog : Bool
    , selectedDay : Maybe Time.Posix
    , noteText : String
    }


type alias Goal =
    { text : String
    , trackingRecords : List TrackingRecord
    , ui : UiModel
    }


newUiModel : UiModel
newUiModel =
    UiModel False False Nothing ""


newGoal : String -> Goal
newGoal newGoalText =
    Goal newGoalText [] newUiModel


shouldUiStayOpen : UiModel -> Bool
shouldUiStayOpen ui =
    let
        showNotes =
            case ui.selectedDay of
                Just _ ->
                    True

                _ ->
                    False
    in
    ui.showDeleteDialog || ui.showTrackingDialog || showNotes


updateUi : UiMsg -> UiModel -> UiModel
updateUi uiMsg uiModel =
    case uiMsg of
        SetTrackingNoteText str ->
            { uiModel | noteText = str }

        SelectDay selectedDay ->
            let
                dayToView =
                    case uiModel.selectedDay of
                        Just openedDay ->
                            if Utils.isSameDay openedDay selectedDay then
                                Nothing

                            else
                                Just selectedDay

                        _ ->
                            Just selectedDay
            in
            { uiModel
                | showDeleteDialog = False
                , showTrackingDialog = False
                , selectedDay = dayToView
            }

        ShowDeleteModal ->
            { uiModel
                | showDeleteDialog = True
                , showTrackingDialog = False
            }

        CancelDeletion ->
            { uiModel | showDeleteDialog = False }

        ShowTrackingModal ->
            { uiModel
                | showTrackingDialog = True
                , showDeleteDialog = False
            }

        CancelTracking ->
            { uiModel | showTrackingDialog = False }


update : Msg -> Goal -> Goal
update msg goal =
    case msg of
        Ui uiMsg ->
            { goal | ui = updateUi uiMsg goal.ui }

        DeleteGoal ->
            goal

        CommitGoalTracking now ->
            let
                oldUI =
                    goal.ui

                newUI =
                    { oldUI | showTrackingDialog = False, noteText = "" }
            in
            { goal
                | trackingRecords = TrackingRecord now goal.ui.noteText :: goal.trackingRecords
                , ui = newUI
            }


isDeleteRequest : Msg -> Bool
isDeleteRequest msg =
    case msg of
        DeleteGoal ->
            True

        _ ->
            False


goalsDecoder : D.Decoder (List Goal)
goalsDecoder =
    D.list goalDecoder


trackingRecordDecoder : D.Decoder TrackingRecord
trackingRecordDecoder =
    D.map2 TrackingRecord
        (D.field "time" <| D.map Time.millisToPosix D.int)
        (D.field "notes" D.string)


goalDecoder : D.Decoder Goal
goalDecoder =
    D.map3 Goal
        (D.field "text" D.string)
        (D.field "daysTracked" (D.list trackingRecordDecoder))
        (D.succeed newUiModel)


goalsEncoder : List Goal -> E.Value
goalsEncoder items =
    E.list goalEncoder items


trackingRecordEncoder : TrackingRecord -> E.Value
trackingRecordEncoder { time, note } =
    E.object
        [ ( "time", E.int <| Time.posixToMillis time )
        , ( "notes", E.string note )
        ]


goalEncoder : Goal -> E.Value
goalEncoder goal =
    E.object
        [ ( "text", E.string goal.text )
        , ( "daysTracked", E.list trackingRecordEncoder goal.trackingRecords )
        ]


getGoalId : Goal -> String
getGoalId goal =
    goal.text


renderGoalBody : GoalContext -> Goal -> Html Msg
renderGoalBody ctx goal =
    let
        calendarViewModel =
            Calendar.ViewModel
                ctx.daysOfMonth
                ctx.today
                (Ui << SelectDay)
                (List.map .time goal.trackingRecords)
                goal.ui.selectedDay

        calendarView =
            Calendar.view calendarViewModel

        renderedNotes : Html Msg
        renderedNotes =
            case goal.ui.selectedDay of
                Just day ->
                    let
                        notesOfSelectedDay =
                            List.filter (\d -> Utils.isSameDay day d.time) goal.trackingRecords
                    in
                    renderListOfNotes day notesOfSelectedDay

                Nothing ->
                    div [] []
    in
    div [ class "flex-1 flex flex-col p-3 justify-between items-center" ]
        [ span
            [ class "font-thin text-4xl pb-3 text-center" ]
            [ text goal.text ]
        , calendarView
        , renderedNotes
        ]


renderDeleteAction : Goal -> Html Msg
renderDeleteAction goal =
    button
        [ classList
            [ ( "flex justify-center w-16 items-center transition-opacity opacity-0 group-hover:opacity-100", True )
            , ( "bg-red-100 animate-pulse", goal.ui.showDeleteDialog )
            ]
        , title "Delete this goal"
        , onClick <| Ui ShowDeleteModal
        ]
        [ Icons.deleteIcon ]


renderTrackAction : Goal -> Html Msg
renderTrackAction goal =
    button
        [ classList
            [ ( "flex justify-center w-16 items-center transition-opacity opacity-0 group-hover:opacity-100", True )
            , ( "bg-green-100 animate-pulse", goal.ui.showTrackingDialog )
            ]
        , title "Track this goal for today"
        , onClick <| Ui ShowTrackingModal
        ]
        [ Icons.plusIcon ]


renderTrackingDialog : Time.Posix -> Goal -> Html Msg
renderTrackingDialog now goal =
    div
        [ classList
            [ ( "flex flex-col justify-center items-center p-2 absolute w-full h-full text-center bg-white/70 backdrop-blur-sm", True )
            , ( "hidden", not goal.ui.showTrackingDialog )
            ]
        ]
        [ span [] [ text <| "Record the " ++ Utils.formatDateFull now ++ ". Any comments?" ]
        , textarea
            [ class "border border-gray-200 mb-1 w-full"
            , value goal.ui.noteText
            , onInput (Ui << SetTrackingNoteText)
            ]
            []
        , div [ class "text-center" ]
            [ button
                [ onClick (CommitGoalTracking now)
                , class "px-2 py bg-green-100 rounded mr-1"
                ]
                [ text "Commit" ]
            , button
                [ onClick <| Ui CancelTracking
                , class "px-2 py bg-gray-100 rounded"
                ]
                [ text "Cancel" ]
            ]
        ]


renderDeletionDialog : Goal -> Html Msg
renderDeletionDialog goal =
    div
        [ classList
            [ ( "flex flex-col justify-center absolute w-full h-full text-center bg-white/70 backdrop-blur-sm", True )
            , ( "hidden", not goal.ui.showDeleteDialog )
            ]
        ]
        [ span [] [ text "Are you sure you want to delete it?" ]
        , div [ class "text-center" ]
            [ button
                [ onClick DeleteGoal
                , class "px-2 py bg-red-100 rounded mr-1"
                ]
                [ text "Delete" ]
            , button
                [ onClick <| Ui CancelDeletion
                , class "px-2 py bg-gray-100 rounded"
                ]
                [ text "Cancel" ]
            ]
        ]


renderListOfNotes : Time.Posix -> List TrackingRecord -> Html Msg
renderListOfNotes day records =
    let
        commentView =
            \{ note } -> li [ class "p-1" ] [ text note ]
    in
    section [ class "w-2/3 text-center mt-2" ]
        [ div [] [ text <| Utils.formatDateFull day ]
        , ul
            [ class "divide-solid divide-y" ]
            (if List.isEmpty records then
                [ li [ class "p-1" ] [ text "No comments for this day" ] ]

             else
                List.map commentView records
            )
        ]


renderGoal : GoalContext -> Goal -> Html Msg
renderGoal ctx goal =
    li
        [ classList
            [ ( "mb-1 flex hover:shadow-lg group transition-shadow hover:bg-slate-50 relative", True )
            , ( "shadow-lg bg-slate-50", shouldUiStayOpen goal.ui )
            ]
        ]
        [ renderDeleteAction goal
        , renderGoalBody ctx goal
        , renderTrackAction goal
        , renderTrackingDialog ctx.today goal
        , renderDeletionDialog goal
        ]
