module Goal exposing (..)

import Html exposing (Html, button, div, header, li, section, span, text, textarea, ul)
import Html.Attributes exposing (class, classList, title, value)
import Html.Events exposing (onClick, onInput)
import Json.Decode as D
import Json.Encode as E
import Svg exposing (path, svg)
import Svg.Attributes as SvgAttr
import Time


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


initUIModel : UiModel
initUIModel =
    UiModel False False Nothing ""


newGoal : String -> Goal
newGoal newGoalText =
    Goal newGoalText [] initUIModel


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
                            if isSameDay openedDay day then
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
        (D.succeed initUIModel)


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
                    renderListOfComments day <|
                        List.filter (\d -> isSameDay day d.time) goal.daysTracked

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
        [ deleteIcon ]


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
        [ plusIcon ]


renderTrackingDialog : Time.Posix -> Goal -> Html Msg
renderTrackingDialog now goal =
    div
        [ classList
            [ ( "flex flex-col justify-center items-center p-2 absolute w-full h-full text-center bg-white/70 backdrop-blur-sm", True )
            , ( "hidden", not goal.ui.showTrackingDialog )
            ]
        ]
        [ span [] [ text <| "Record the " ++ formatDateFull now ++ ". Any comments?" ]
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


formatDateFull : Time.Posix -> String
formatDateFull t =
    let
        day =
            Time.toDay Time.utc t |> String.fromInt

        month =
            Time.toMonth Time.utc t |> monthToStr
    in
    day ++ ". " ++ month


renderListOfComments : Time.Posix -> List TrackingRecord -> Html Msg
renderListOfComments day records =
    let
        commentView =
            \{ note } -> li [ class "p-1" ] [ text note ]
    in
    section [ class "w-2/3 text-center mt-2" ]
        [ div []
            [ text <| formatDateFull day ]
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


isSameDay : Time.Posix -> Time.Posix -> Bool
isSameDay t1 t2 =
    let
        isMatchingMonths =
            \( d1, d2 ) -> Time.toMonth Time.utc d1 == Time.toMonth Time.utc d2

        isMatchingDays =
            \( d1, d2 ) -> Time.toDay Time.utc d1 == Time.toDay Time.utc d2
    in
    isMatchingMonths ( t1, t2 ) && isMatchingDays ( t1, t2 )


isDayTracked : Time.Posix -> List TrackingRecord -> Bool
isDayTracked day =
    List.any (\rec -> isSameDay day rec.time)


renderCalendarDay : List TrackingRecord -> Time.Posix -> Html Msg
renderCalendarDay trackedDays day =
    let
        dayStr =
            String.fromInt << Time.toDay Time.utc <| day

        isTracked =
            isDayTracked day trackedDays

        colorClass =
            if isTracked then
                "bg-green-300"

            else
                "bg-gray-200"
    in
    button
        [ class ("text-center text-xs text-gray-600 font-bold rounded w-6 py-1 " ++ colorClass)
        , onClick <| Ui (ToggleDaysNotes day)
        ]
        [ text dayStr ]


monthToStr : Time.Month -> String
monthToStr month =
    case month of
        Time.Jan ->
            "Jan"

        Time.Feb ->
            "Feb"

        Time.Mar ->
            "Mar"

        Time.Apr ->
            "Apr"

        Time.May ->
            "May"

        Time.Jun ->
            "Jun"

        Time.Jul ->
            "Jul"

        Time.Aug ->
            "Aug"

        Time.Sep ->
            "Sep"

        Time.Oct ->
            "Oct"

        Time.Nov ->
            "Nov"

        Time.Dec ->
            "Dec"


trackingCalendar : GoalContext -> Goal -> Html Msg
trackingCalendar { daysOfMonth, now } goal =
    let
        monthName =
            monthToStr <| Time.toMonth Time.utc now
    in
    section
        [ classList
            [ ( "flex items-center gap-1 transition-opacity opacity-0 group-hover:opacity-100", True )
            , ( "opacity-100", shouldUiStayOpen goal.ui )
            ]
        ]
        (header [ class "font-bold" ] [ text monthName ]
            :: List.map (renderCalendarDay goal.daysTracked) daysOfMonth
        )


plusIcon : Html Msg
plusIcon =
    svg
        [ SvgAttr.width "24px"
        , SvgAttr.height "24px"
        , SvgAttr.viewBox "0 0 24 24"
        , SvgAttr.fill "none"
        ]
        [ Svg.g
            [ SvgAttr.strokeWidth "0"
            ]
            []
        , Svg.g
            [ SvgAttr.strokeLinecap "round"
            , SvgAttr.strokeLinejoin "round"
            ]
            []
        , Svg.g
            []
            [ path
                [ SvgAttr.d "M7 13L10 16L17 9"
                , SvgAttr.stroke "#000000"
                , SvgAttr.strokeWidth "2"
                , SvgAttr.strokeLinecap "round"
                , SvgAttr.strokeLinejoin "round"
                ]
                []
            , Svg.circle
                [ SvgAttr.cx "12"
                , SvgAttr.cy "12"
                , SvgAttr.r "9"
                , SvgAttr.stroke "#000000"
                , SvgAttr.strokeWidth "2"
                , SvgAttr.strokeLinecap "round"
                , SvgAttr.strokeLinejoin "round"
                ]
                []
            ]
        ]


deleteIcon : Html Msg
deleteIcon =
    svg
        [ SvgAttr.width "24px"
        , SvgAttr.height "24px"
        , SvgAttr.viewBox "0 0 24 24"
        , SvgAttr.fill "none"
        ]
        [ Svg.g
            [ SvgAttr.strokeWidth "0"
            ]
            []
        , Svg.g
            [ SvgAttr.strokeLinecap "round"
            , SvgAttr.strokeLinejoin "round"
            ]
            []
        , Svg.g
            []
            [ path
                [ SvgAttr.d "M10 11V17"
                , SvgAttr.stroke "#000000"
                , SvgAttr.strokeWidth "2"
                , SvgAttr.strokeLinecap "round"
                , SvgAttr.strokeLinejoin "round"
                ]
                []
            , path
                [ SvgAttr.d "M14 11V17"
                , SvgAttr.stroke "#000000"
                , SvgAttr.strokeWidth "2"
                , SvgAttr.strokeLinecap "round"
                , SvgAttr.strokeLinejoin "round"
                ]
                []
            , path
                [ SvgAttr.d "M4 7H20"
                , SvgAttr.stroke "#000000"
                , SvgAttr.strokeWidth "2"
                , SvgAttr.strokeLinecap "round"
                , SvgAttr.strokeLinejoin "round"
                ]
                []
            , path
                [ SvgAttr.d "M6 7H12H18V18C18 19.6569 16.6569 21 15 21H9C7.34315 21 6 19.6569 6 18V7Z"
                , SvgAttr.stroke "#000000"
                , SvgAttr.strokeWidth "2"
                , SvgAttr.strokeLinecap "round"
                , SvgAttr.strokeLinejoin "round"
                ]
                []
            , path
                [ SvgAttr.d "M9 5C9 3.89543 9.89543 3 11 3H13C14.1046 3 15 3.89543 15 5V7H9V5Z"
                , SvgAttr.stroke "#000000"
                , SvgAttr.strokeWidth "2"
                , SvgAttr.strokeLinecap "round"
                , SvgAttr.strokeLinejoin "round"
                ]
                []
            ]
        ]
