module Main exposing (..)

import Browser
import Html exposing (Html, button, div, header, input, li, main_, section, text, ul)
import Html.Attributes exposing (class, value)
import Html.Events exposing (onClick, onInput)


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { goals = [], newGoalText = "" }
    , Cmd.none
    )


type alias Model =
    { goals : List Goal
    , newGoalText : String
    }


type alias Goal =
    { text : String
    , progress : Int
    }


type Msg
    = SetNewGoalsText String
    | AddGoal


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetNewGoalsText str ->
            let
                nm =
                    { model | newGoalText = str }
            in
            ( nm, Cmd.none )

        AddGoal ->
            let
                ng =
                    { text = model.newGoalText, progress = 0 }

                nm =
                    { model | newGoalText = "", goals = ng :: model.goals }
            in
            ( nm, Cmd.none )


renderGoal : String -> Html msg
renderGoal goalText =
    li
        [ class "font-thin text-4xl p-3 text-center hover:font-light" ]
        [ text goalText ]


renderGoals : List Goal -> Html msg
renderGoals items =
    case items of
        [] ->
            section [] [ text "Add your first goal" ]

        goals ->
            ul [ class "flex-1 flex flex-col" ] <|
                List.map
                    (\g -> renderGoal g.text)
                    goals


view : Model -> Html Msg
view model =
    div [ class "h-full flex flex-col" ]
        [ header [ class "p-4 border bottom-1" ]
            [ input
                [ class "w-1/3 p-1 border-b border-gray-400 focus:border-b-green-500 focus:outline-none"
                , onInput SetNewGoalsText
                , value model.newGoalText
                ]
                []
            , button
                [ class "px-4 py-1 rounded"
                , onClick AddGoal
                ]
                [ text "Add a goal" ]
            ]
        , main_
            [ class "flex-1 flex items-center justify-center" ]
            [ renderGoals model.goals
            ]
        ]
