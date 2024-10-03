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


type alias Args msg =
    { toSelf : Msg -> msg
    , onShowTrackingDialog : String -> Maybe Time.Posix -> msg
    , onShowDeleteDialog : String -> msg
    }


init : Time.Posix -> List DataModel.Goal -> Model
init today goalsData =
    List.map (Goal.init today) goalsData


toDataModel : Model -> List DataModel.Goal
toDataModel model =
    List.map Goal.toDataModel model


isGoalExist : String -> Model -> Bool
isGoalExist goalText model =
    List.any (\goal -> goal.goal == goalText) model


deleteGoal : String -> Model -> Model
deleteGoal id model =
    List.filter (\g -> id /= g.goal) model


setGoalStayOpen : Bool -> String -> Model -> Model
setGoalStayOpen val goalId model =
    List.map
        (\goal ->
            if goalId == Goal.getId goal then
                Goal.setStayOpen val goal

            else
                goal
        )
        model


addTrackingEntry : String -> Time.Posix -> String -> Model -> Model
addTrackingEntry goalId time note model =
    List.map
        (\g ->
            if goalId == Goal.getId g then
                Goal.addTrackingEntry time note g

            else
                g
        )
        model


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FromGoal id goalMsg ->
            let
                ( newGoals, cmds ) =
                    List.map
                        (\goal ->
                            if id == Goal.getId goal then
                                Tuple.mapSecond
                                    (Cmd.map (FromGoal (Goal.getId goal)))
                                    (Goal.update goalMsg goal)

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


view : Args msg -> Model -> Html msg
view args model =
    case model of
        [] ->
            section
                [ class "text-gray-400 dark:text-gray-700 text-3xl font-thin" ]
                [ text "Add your first goal" ]

        goals ->
            ul [ class "flex-1 flex flex-col justify-center" ] <|
                List.map
                    (\goal ->
                        Goal.view
                            { toSelf = args.toSelf << FromGoal (Goal.getId goal)
                            , onShowDeleteDialog = args.onShowDeleteDialog
                            , onShowTrackingDialog = args.onShowTrackingDialog
                            }
                            goal
                    )
                    goals
