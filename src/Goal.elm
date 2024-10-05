module Goal exposing (..)

import Calendar
import DataModel exposing (Goal, TrackingEntry)
import Day
import DayNotes
import Html exposing (Html, button, div, li, span, text)
import Html.Attributes exposing (class, classList, title)
import Html.Events exposing (onClick)
import Icons
import Time
import Utils


type alias Model =
    { goal : String
    , calendar : Calendar.Model
    , trackingEntries : List TrackingEntry
    , today : Time.Posix
    , stayOpen : Bool
    }


type alias Args msg =
    { toSelf : Msg -> msg
    , onShowTrackingDialog : String -> Maybe Time.Posix -> msg
    , onShowDeleteDialog : String -> msg
    }


type Msg
    = FromCalendar Calendar.Msg
    | DeleteDayNote Time.Posix


toDataModel : Model -> Goal
toDataModel model =
    Goal model.goal model.trackingEntries


init : Time.Posix -> Goal -> Model
init today goalData =
    Model goalData.goal (Calendar.init today goalData.trackingEntries False) goalData.trackingEntries today False


setStayOpen : Bool -> Model -> Model
setStayOpen val model =
    { model
        | stayOpen = val
        , calendar = Calendar.setStayOpen val model.calendar
    }


addTrackingEntry : Time.Posix -> String -> Model -> Model
addTrackingEntry time note model =
    let
        newEntries : List TrackingEntry
        newEntries =
            TrackingEntry time note :: model.trackingEntries
    in
    { model
        | trackingEntries = newEntries
        , calendar = Calendar.updateDays newEntries model.calendar
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FromCalendar calendarMsg ->
            let
                newCalendarModel : Calendar.Model
                newCalendarModel =
                    Calendar.update calendarMsg model.calendar
            in
            ( { model
                | calendar = newCalendarModel
                , stayOpen = Calendar.getSelectedDay newCalendarModel |> Maybe.map (always True) |> Maybe.withDefault False
              }
            , Cmd.none
            )

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
            )


getId : Model -> String
getId =
    .goal


renderGoalBody : Args msg -> Model -> Html msg
renderGoalBody args model =
    div
        [ class "flex-1 flex flex-col p-3 justify-between items-center"
        , Utils.testId "goal-goal-body"
        ]
        [ span
            [ class "font-thin text-4xl pb-3 text-center" ]
            [ text model.goal ]
        , Calendar.view model.calendar |> Html.map (args.toSelf << FromCalendar)
        , renderSelectedDayNotes args model
        ]


renderDeleteAction : Args msg -> String -> Html msg
renderDeleteAction args goal =
    button
        [ class "flex justify-center w-16 items-center transition-opacity opacity-0 group-hover:opacity-100"
        , title "Delete this goal"
        , onClick (args.onShowDeleteDialog goal)
        , Utils.testId "goal-delete-action"
        ]
        [ Icons.deleteIcon ]


renderTrackAction : Args msg -> Model -> Html msg
renderTrackAction args model =
    let
        dayTimestamp : Maybe Time.Posix
        dayTimestamp =
            Calendar.getSelectedDay model.calendar |> Maybe.map Day.getId
    in
    button
        [ class "flex justify-center w-16 items-center transition-opacity opacity-0 group-hover:opacity-100"
        , title "Track this goal for today"
        , onClick (args.onShowTrackingDialog model.goal dayTimestamp)
        , Utils.testId "goal-track-action"
        ]
        [ Icons.plusIcon ]


renderSelectedDayNotes : Args msg -> Model -> Html msg
renderSelectedDayNotes args model =
    Calendar.getSelectedDay model.calendar
        |> Maybe.map
            (\day ->
                DayNotes.view (args.toSelf << DeleteDayNote) (Day.getId day) <|
                    List.filter (Utils.isSameDay (Day.getId day) << .timestamp) model.trackingEntries
            )
        |> Maybe.withDefault (div [] [])


view : Args msg -> Model -> Html msg
view args model =
    li
        [ classList
            [ ( "group goal", True )
            , ( "goal-open", model.stayOpen )
            ]
        ]
        [ renderDeleteAction args model.goal
        , renderGoalBody args model
        , renderTrackAction args model
        ]
