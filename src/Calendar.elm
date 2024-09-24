module Calendar exposing (..)

import CalendarDay
import Derberos.Date.Calendar as C
import Derberos.Date.Utils as DU
import Html exposing (Html, header, section, text)
import Html.Attributes exposing (class)
import Time
import Utils


type alias Model =
    { now : Time.Posix
    , trackedDays : List Time.Posix
    , daysOfMonth : List Time.Posix
    , selectedDay : Maybe CalendarDay.Model
    }


type Msg
    = SelectDay Time.Posix


updateTrackedDays : List Time.Posix -> Model -> Model
updateTrackedDays days model =
    { model | trackedDays = days }


initModel : Time.Posix -> List Time.Posix -> Model
initModel now trackedDays =
    let
        daysOfMonth =
            List.map DU.resetTime (C.getCurrentMonthDates Time.utc now)
    in
    Model now trackedDays daysOfMonth Nothing


renderCalendarDay : CalendarDay.Model -> Html Msg
renderCalendarDay dayModel =
    CalendarDay.view SelectDay dayModel


isDayTracked : Time.Posix -> List Time.Posix -> Bool
isDayTracked day =
    List.any (\dayN -> Utils.isSameDay day dayN)


getDayStatus : Model -> Time.Posix -> CalendarDay.Status
getDayStatus model day =
    if isDayTracked day model.trackedDays then
        CalendarDay.Tracked

    else
        CalendarDay.Empty


view : Model -> Html Msg
view model =
    let
        monthName =
            Utils.monthToStr <| Time.toMonth Time.utc model.now

        calendarDays =
            List.map
                (\day -> CalendarDay.Model day (getDayStatus model day))
                model.daysOfMonth
    in
    section
        [ class "flex items-center gap-1 transition-opacity opacity-0 group-hover:opacity-100"
        ]
        (header [ class "font-bold" ] [ text monthName ]
            :: List.map renderCalendarDay calendarDays
        )
