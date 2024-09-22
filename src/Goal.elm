module Goal exposing (..)

import Goal.Calendar as GC
import Goal.Utils
import Html exposing (Html, button, div, li, span, text)
import Html.Attributes exposing (class, title)
import Html.Events exposing (onClick)
import Json.Decode as D
import Json.Encode as E
import Svg exposing (path, svg)
import Svg.Attributes as SvgAttr
import Time


type Msg
    = TrackGoal Time.Posix
    | AskToDeleteGoal
    | DeleteGoal
    | Noop


type alias Goal =
    { text : String
    , confirmDelete : Bool
    , daysTracked : List Time.Posix
    }


update : Msg -> Goal -> Goal
update msg goal =
    case msg of
        AskToDeleteGoal ->
            { goal | confirmDelete = not goal.confirmDelete }

        DeleteGoal ->
            goal

        Noop ->
            goal

        TrackGoal now ->
            { goal | daysTracked = now :: goal.daysTracked }


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


goalDecoder : D.Decoder Goal
goalDecoder =
    D.map3 Goal
        (D.field "text" D.string)
        (D.succeed True)
        (D.field "daysTracked" <| D.list <| D.map Time.millisToPosix D.int)


goalsEncoder : List Goal -> E.Value
goalsEncoder items =
    E.list goalEncoder items


goalEncoder : Goal -> E.Value
goalEncoder goal =
    E.object
        [ ( "text", E.string goal.text )
        , ( "daysTracked", E.list E.int <| List.map Time.posixToMillis goal.daysTracked )
        ]


getGoalId : Goal -> String
getGoalId goal =
    goal.text


renderGoalBody : Goal.Utils.GoalContext -> Goal -> Html Msg
renderGoalBody ctx goal =
    div [ class "flex-1 flex flex-col p-3 justify-between items-center" ]
        [ span
            [ class "font-thin text-4xl pb-3 text-center" ]
            [ text goal.text ]
        , Html.map (\_ -> Noop) <| GC.view ctx.daysOfMonth goal.daysTracked ctx.now
        ]


renderDeleteAction : Html Msg
renderDeleteAction =
    button
        [ class "flex justify-center bg-pink-100 hover:animate-pulse w-16 items-center transition-opacity opacity-0 group-hover:opacity-100"
        , title "Delete this goal"
        , onClick DeleteGoal
        ]
        [ deleteIcon ]


renderTrackAction : Time.Posix -> Html Msg
renderTrackAction now =
    button
        [ class "flex justify-center bg-green-100 hover:animate-pulse w-16 items-center transition-opacity opacity-0 group-hover:opacity-100"
        , title "Track this goal for today"
        , onClick (TrackGoal now)
        ]
        [ plusIcon ]


renderGoal : Goal.Utils.GoalContext -> Goal -> Html Msg
renderGoal ctx goal =
    li
        [ class "flex hover:shadow-lg group transition-shadow hover:bg-slate-50" ]
        [ renderDeleteAction
        , renderGoalBody ctx goal
        , renderTrackAction ctx.now
        ]


plusIcon : Html Msg
plusIcon =
    svg
        [ SvgAttr.width "24px"
        , SvgAttr.height "24px"
        , SvgAttr.viewBox "0 0 24 24"
        , SvgAttr.fill "none"
        ]
        [ Svg.g
            [ SvgAttr.id "SVGRepo_bgCarrier"
            , SvgAttr.strokeWidth "0"
            ]
            []
        , Svg.g
            [ SvgAttr.id "SVGRepo_tracerCarrier"
            , SvgAttr.strokeLinecap "round"
            , SvgAttr.strokeLinejoin "round"
            ]
            []
        , Svg.g
            [ SvgAttr.id "SVGRepo_iconCarrier"
            ]
            [ path
                [ SvgAttr.opacity "0.5"
                , SvgAttr.d "M22 12C22 17.5228 17.5228 22 12 22C6.47715 22 2 17.5228 2 12C2 6.47715 6.47715 2 12 2C17.5228 2 22 6.47715 22 12Z"
                , SvgAttr.fill "#1C274C"
                ]
                []
            , path
                [ SvgAttr.d "M16.0303 8.96967C16.3232 9.26256 16.3232 9.73744 16.0303 10.0303L11.0303 15.0303C10.7374 15.3232 10.2626 15.3232 9.96967 15.0303L7.96967 13.0303C7.67678 12.7374 7.67678 12.2626 7.96967 11.9697C8.26256 11.6768 8.73744 11.6768 9.03033 11.9697L10.5 13.4393L12.7348 11.2045L14.9697 8.96967C15.2626 8.67678 15.7374 8.67678 16.0303 8.96967Z"
                , SvgAttr.fill "#1C274C"
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
        ]
        [ Svg.g
            [ SvgAttr.id "SVGRepo_bgCarrier"
            , SvgAttr.strokeWidth "0"
            ]
            []
        , Svg.g
            [ SvgAttr.id "SVGRepo_tracerCarrier"
            , SvgAttr.strokeLinecap "round"
            , SvgAttr.strokeLinejoin "round"
            ]
            []
        , Svg.g
            [ SvgAttr.id "SVGRepo_iconCarrier"
            ]
            [ path
                [ SvgAttr.d "M3 6.38597C3 5.90152 3.34538 5.50879 3.77143 5.50879L6.43567 5.50832C6.96502 5.49306 7.43202 5.11033 7.61214 4.54412C7.61688 4.52923 7.62232 4.51087 7.64185 4.44424L7.75665 4.05256C7.8269 3.81241 7.8881 3.60318 7.97375 3.41617C8.31209 2.67736 8.93808 2.16432 9.66147 2.03297C9.84457 1.99972 10.0385 1.99986 10.2611 2.00002H13.7391C13.9617 1.99986 14.1556 1.99972 14.3387 2.03297C15.0621 2.16432 15.6881 2.67736 16.0264 3.41617C16.1121 3.60318 16.1733 3.81241 16.2435 4.05256L16.3583 4.44424C16.3778 4.51087 16.3833 4.52923 16.388 4.54412C16.5682 5.11033 17.1278 5.49353 17.6571 5.50879H20.2286C20.6546 5.50879 21 5.90152 21 6.38597C21 6.87043 20.6546 7.26316 20.2286 7.26316H3.77143C3.34538 7.26316 3 6.87043 3 6.38597Z"
                , SvgAttr.fill "#1C274C"
                ]
                []
            , path
                [ SvgAttr.fillRule "evenodd"
                , SvgAttr.clipRule "evenodd"
                , SvgAttr.d "M9.42543 11.4815C9.83759 11.4381 10.2051 11.7547 10.2463 12.1885L10.7463 17.4517C10.7875 17.8855 10.4868 18.2724 10.0747 18.3158C9.66253 18.3592 9.29499 18.0426 9.25378 17.6088L8.75378 12.3456C8.71256 11.9118 9.01327 11.5249 9.42543 11.4815Z"
                , SvgAttr.fill "#1C274C"
                ]
                []
            , path
                [ SvgAttr.fillRule "evenodd"
                , SvgAttr.clipRule "evenodd"
                , SvgAttr.d "M14.5747 11.4815C14.9868 11.5249 15.2875 11.9118 15.2463 12.3456L14.7463 17.6088C14.7051 18.0426 14.3376 18.3592 13.9254 18.3158C13.5133 18.2724 13.2126 17.8855 13.2538 17.4517L13.7538 12.1885C13.795 11.7547 14.1625 11.4381 14.5747 11.4815Z"
                , SvgAttr.fill "#1C274C"
                ]
                []
            , path
                [ SvgAttr.opacity "0.5"
                , SvgAttr.d "M11.5956 22.0001H12.4044C15.1871 22.0001 16.5785 22.0001 17.4831 21.1142C18.3878 20.2283 18.4803 18.7751 18.6654 15.8686L18.9321 11.6807C19.0326 10.1037 19.0828 9.31524 18.6289 8.81558C18.1751 8.31592 17.4087 8.31592 15.876 8.31592H8.12405C6.59127 8.31592 5.82488 8.31592 5.37105 8.81558C4.91722 9.31524 4.96744 10.1037 5.06788 11.6807L5.33459 15.8686C5.5197 18.7751 5.61225 20.2283 6.51689 21.1142C7.42153 22.0001 8.81289 22.0001 11.5956 22.0001Z"
                , SvgAttr.fill "#1C274C"
                ]
                []
            ]
        ]
