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


type UpdateStrategy
    = SelectDay Time.Posix
    | AlterTracking (List TrackingEntry)


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


updateDay : UpdateStrategy -> Day.Model -> Day.Model
updateDay strategy day =
    case strategy of
        SelectDay timestamp ->
            case ( Day.isSelected day, Day.matchTime timestamp day ) of
                ( True, True ) ->
                    Day.unSelect day

                ( True, False ) ->
                    Day.unSelect day

                ( False, True ) ->
                    Day.select day

                _ ->
                    day

        AlterTracking entries ->
            List.any (\entry -> Day.matchTime entry.timestamp day) entries
                |> Day.setHasHistory day


update : Msg -> Model -> Model
update msg model =
    case msg of
        ClickOnDay timestamp ->
            let
                updatedDays : List Day.Model
                updatedDays =
                    List.map (updateDay (SelectDay timestamp)) model.days
            in
            { model
                | days = updatedDays
                , stayOpen = List.any Day.isSelected updatedDays
            }


updateDays : List TrackingEntry -> Model -> Model
updateDays entries model =
    { model | days = List.map (updateDay <| AlterTracking entries) model.days }


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
