module Goal exposing (..)

import CalendarDay as CalD
import Html exposing (Html, button, div, header, li, section, span, text, textarea, ul)
import Html.Attributes exposing (class, classList, title, value)
import Html.Events exposing (onClick, onInput)
import Icons
import Json.Decode as D
import Json.Encode as E
import Time
import Utils exposing (monthToStr)


type UiMsg
    = ShowTrackingModal
    | CancelTracking
    | ShowDeleteModal
    | CancelDeletion
    | ToggleDaysNotes Time.Posix
    | SetTrackingNoteText String


type Msg
    = CommitGoalTracking Time.Posix
    | DeleteGoal
    | Ui UiMsg
    | Noop


type alias TrackingRecord =
    { time : Time.Posix
    , note : String
    }


type alias GoalContext =
    { daysOfMonth : List Time.Posix
    , now : Time.Posix
    }


type alias UiModel =
    { showDeleteDialog : Bool
    , showTrackingDialog : Bool
    , notesOfDay : Maybe Time.Posix
    , noteText : String
    }


type alias Goal =
    { text : String
    , daysTracked : List TrackingRecord
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
            case ui.notesOfDay of
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

        ToggleDaysNotes day ->
            let
                dayToView =
                    case uiModel.notesOfDay of
                        Just openedDay ->
                            if Utils.isSameDay openedDay day then
                                Nothing

                            else
                                Just day

                        _ ->
                            Just day
            in
            { uiModel
                | showDeleteDialog = False
                , showTrackingDialog = False
                , notesOfDay = dayToView
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

        Noop ->
            goal

        CommitGoalTracking now ->
            let
                oldUI =
                    goal.ui

                newUI =
                    { oldUI | showTrackingDialog = False, noteText = "" }
            in
            { goal
                | daysTracked = TrackingRecord now goal.ui.noteText :: goal.daysTracked
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
        , ( "daysTracked", E.list trackingRecordEncoder goal.daysTracked )
        ]


getGoalId : Goal -> String
getGoalId goal =
    goal.text


renderGoalBody : GoalContext -> Goal -> Html Msg
renderGoalBody ctx goal =
    let
        notesView =
            case goal.ui.notesOfDay of
                Just day ->
                    renderListOfNotes day <|
                        List.filter (\d -> Utils.isSameDay day d.time) goal.daysTracked

                Nothing ->
                    div [] []
    in
    div [ class "flex-1 flex flex-col p-3 justify-between items-center" ]
        [ span
            [ class "font-thin text-4xl pb-3 text-center" ]
            [ text goal.text ]
        , trackingCalendar ctx goal
        , notesView
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
        [ Html.map (\_ -> Noop) Icons.deleteIcon ]


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
        [ Html.map (\_ -> Noop) Icons.plusIcon ]


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
            , onInput (\s -> Ui <| SetTrackingNoteText s)
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
        [ div []
            [ text <| Utils.formatDateFull day ]
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
        , renderTrackingDialog ctx.now goal
        , renderDeletionDialog goal
        ]


isDayTracked : Time.Posix -> List TrackingRecord -> Bool
isDayTracked day =
    List.any (\rec -> Utils.isSameDay day rec.time)


renderCalendarDay : CalD.Model -> Html Msg
renderCalendarDay dayModel =
    CalD.view (Ui << ToggleDaysNotes) dayModel


getDayStatus : List TrackingRecord -> Time.Posix -> CalD.Status
getDayStatus trackingHistory day =
    if isDayTracked day trackingHistory then
        CalD.Tracked

    else
        CalD.Empty


trackingCalendar : GoalContext -> Goal -> Html Msg
trackingCalendar { daysOfMonth, now } goal =
    let
        monthName =
            monthToStr <| Time.toMonth Time.utc now

        calendarDays =
            List.map
                (\t -> CalD.Model t (getDayStatus goal.daysTracked t))
                daysOfMonth
    in
    section
        [ classList
            [ ( "flex items-center gap-1 transition-opacity opacity-0 group-hover:opacity-100", True )
            , ( "opacity-100", shouldUiStayOpen goal.ui )
            ]
        ]
        (header [ class "font-bold" ] [ text monthName ]
            :: List.map renderCalendarDay calendarDays
        )
