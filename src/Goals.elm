module Goals exposing (..)

import DataModel
import Goal
import Html exposing (Html, section, text, ul)
import Html.Attributes exposing (class)
import Time


type alias Model =
    List Goal.Model


type Msg
    = FromGoal String Goal.Msg


init : Time.Posix -> List DataModel.Goal -> Model
init today goalsData =
    List.map (Goal.init today) goalsData


toDataModel : Model -> List DataModel.Goal
toDataModel model =
    List.map Goal.toDataModel model


isGoalExist : String -> Model -> Bool
isGoalExist goalText model =
    List.any (\goal -> goal.goal == goalText) model


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FromGoal id goalMsg ->
            if Goal.isDeleteRequest goalMsg then
                ( List.filter (\g -> id /= g.goal) model
                , Cmd.none
                )

            else
                let
                    ( newGoals, cmds ) =
                        List.map
                            (\goal ->
                                if id == Goal.getId goal then
                                    let
                                        ( newGoal, goalCmd ) =
                                            Goal.update goalMsg goal
                                    in
                                    ( newGoal, Cmd.map (FromGoal (Goal.getId goal)) goalCmd )

                                else
                                    ( goal, Cmd.none )
                            )
                            model
                            |> List.unzip
                in
                ( newGoals, Cmd.batch cmds )


addGoal : Time.Posix -> DataModel.Goal -> Model -> Model
addGoal timestamp goal model =
    Goal.init timestamp goal :: model


view : Model -> Html Msg
view model =
    case model of
        [] ->
            section [ class "text-gray-400 dark:text-gray-700 text-3xl font-thin" ] [ text "Add your first goal" ]

        goals ->
            let
                render : Goal.Model -> Html Msg
                render =
                    \goal -> Html.map (FromGoal (Goal.getId goal)) (Goal.view goal)
            in
            ul [ class "flex-1 flex flex-col justify-center" ] <|
                List.map render goals
