module Calendar exposing (ViewModel, view)

import CalendarDay
import Html exposing (Html, header, section, text)
import Html.Attributes exposing (class)
import Time
import Utils


isDayTracked : Time.Posix -> List Time.Posix -> Bool
isDayTracked day1 history =
    List.any (Utils.isSameDay day1) history


isDaySelected : Maybe Time.Posix -> Time.Posix -> Bool
isDaySelected maybeDay day =
    case maybeDay of
        Just d ->
            Utils.isSameDay d day

        Nothing ->
            False


type alias ViewModel msg =
    { daysOfMonth : List Time.Posix
    , today : Time.Posix
    , handleDayClick : Time.Posix -> msg
    , trackingHistory : List Time.Posix
    , selectedDay : Maybe Time.Posix
    }


view : ViewModel msg -> Html msg
view vm =
    let
        monthName =
            Utils.monthToStr <| Time.toMonth Time.utc vm.today
    in
    section
        [ class "flex items-center gap-1 transition-opacity opacity-0 group-hover:opacity-100"
        , Utils.testId "calendar-body"
        ]
        (header [ class "font-bold" ] [ text monthName ]
            :: List.map
                (CalendarDay.view vm.handleDayClick)
                (List.map (\day -> CalendarDay.ViewModel (isDayTracked day vm.trackingHistory) (isDaySelected vm.selectedDay day) day) vm.daysOfMonth)
        )
