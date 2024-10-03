module Goals exposing (..)

import DataModel
import Goal
import Html exposing (Html, section, text, ul)
import Html.Attributes exposing (class)
import Task
import Time


type alias Model =
    List Goal.Model


type Msg
    = FromGoal String Goal.Msg
    | DeleteGoal String


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
        DeleteGoal id ->
            ( List.filter (\g -> id /= g.goal) model
            , Cmd.none
            )

        FromGoal id goalMsg ->
            let
                ( newGoals, cmds ) =
                    List.map
                        (\goal ->
                            if id == Goal.getId goal then
                                let
                                    goalId : String
                                    goalId =
                                        Goal.getId goal

                                    ( newGoal, goalCmd, toDelete ) =
                                        Goal.update goalMsg goal

                                    followUp : Cmd Msg
                                    followUp =
                                        Maybe.map (Task.perform DeleteGoal << Task.succeed) toDelete
                                            |> Maybe.withDefault Cmd.none
                                in
                                ( newGoal
                                , Cmd.batch [ Cmd.map (FromGoal goalId) goalCmd, followUp ]
                                )

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
