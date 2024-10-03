module Calendar exposing (Model, Msg(..), getSelectedDay, init, setStayOpen, update, updateDays, view)

import DataModel exposing (TrackingEntry)
import Day
import Html exposing (Html, header, section, text)
import Html.Attributes exposing (class, classList)
import Time
import Utils


type alias Model =
    { days : List Day.Model
    , monthName : String
    , stayOpen : Bool
    }


type Msg
    = ClickOnDay Time.Posix


init : Time.Posix -> List TrackingEntry -> Bool -> Model
init today trackingEntries stayOpen =
    let
        timeFound : Time.Posix -> Bool
        timeFound =
            \timestamp -> List.any (\entry -> Utils.isSameDay timestamp entry.timestamp) trackingEntries

        days : List Day.Model
        days =
            Utils.getDaysOfMonth today
                |> List.map
                    (\timestamp ->
                        Day.initEmpty (timeFound timestamp) timestamp
                    )

        monthName : String
        monthName =
            Utils.monthToStr <| Time.toMonth Time.utc today
    in
    Model days monthName stayOpen


setStayOpen : Bool -> Model -> Model
setStayOpen val model =
    { model | stayOpen = val }


update : Msg -> Model -> Model
update msg model =
    case msg of
        ClickOnDay timestamp ->
            let
                updateDay : Day.Model -> Day.Model
                updateDay =
                    \day ->
                        case ( Day.isSelected day, Day.matchTime timestamp day ) of
                            ( True, True ) ->
                                Day.unSelect day

                            ( True, False ) ->
                                Day.unSelect day

                            ( False, True ) ->
                                Day.select day

                            _ ->
                                day

                updatedDays : List Day.Model
                updatedDays =
                    List.map updateDay model.days
            in
            { model
                | days = updatedDays
                , stayOpen = List.any Day.isSelected updatedDays
            }


updateDays : List TrackingEntry -> Model -> Model
updateDays entries model =
    let
        updateDay : Day.Model -> Day.Model
        updateDay =
            \day ->
                List.any (\entry -> Utils.isSameDay (Day.getId day) entry.timestamp) entries
                    |> Day.setHasHistory day
    in
    { model | days = List.map updateDay model.days }


getSelectedDay : Model -> Maybe Day.Model
getSelectedDay model =
    List.filter Day.isSelected model.days |> List.head


view : Model -> Html Msg
view model =
    section
        [ classList
            [ ( "flex items-center gap-1 transition-opacity opacity-0 group-hover:opacity-100", True )
            , ( "opacity-100", model.stayOpen )
            ]
        , Utils.testId "calendar-body"
        ]
        (header [ class "font-bold" ] [ text model.monthName ]
            :: List.map (Day.view ClickOnDay) model.days
        )
