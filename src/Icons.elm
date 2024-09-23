module Icons exposing (..)

import Html exposing (Html)
import Svg exposing (path, svg)
import Svg.Attributes exposing (cx, cy, d, fill, height, r, stroke, strokeLinecap, strokeLinejoin, strokeWidth, viewBox, width)


plusIcon : Html ()
plusIcon =
    svg
        [ width "24px"
        , height "24px"
        , viewBox "0 0 24 24"
        , fill "none"
        ]
        [ Svg.g
            [ strokeWidth "0"
            ]
            []
        , Svg.g
            [ strokeLinecap "round"
            , strokeLinejoin "round"
            ]
            []
        , Svg.g
            []
            [ path
                [ d "M7 13L10 16L17 9"
                , stroke "#000000"
                , strokeWidth "2"
                , strokeLinecap "round"
                , strokeLinejoin "round"
                ]
                []
            , Svg.circle
                [ cx "12"
                , cy "12"
                , r "9"
                , stroke "#000000"
                , strokeWidth "2"
                , strokeLinecap "round"
                , strokeLinejoin "round"
                ]
                []
            ]
        ]


deleteIcon : Html ()
deleteIcon =
    svg
        [ width "24px"
        , height "24px"
        , viewBox "0 0 24 24"
        , fill "none"
        ]
        [ Svg.g
            [ strokeWidth "0"
            ]
            []
        , Svg.g
            [ strokeLinecap "round"
            , strokeLinejoin "round"
            ]
            []
        , Svg.g
            []
            [ path
                [ d "M10 11V17"
                , stroke "#000000"
                , strokeWidth "2"
                , strokeLinecap "round"
                , strokeLinejoin "round"
                ]
                []
            , path
                [ d "M14 11V17"
                , stroke "#000000"
                , strokeWidth "2"
                , strokeLinecap "round"
                , strokeLinejoin "round"
                ]
                []
            , path
                [ d "M4 7H20"
                , stroke "#000000"
                , strokeWidth "2"
                , strokeLinecap "round"
                , strokeLinejoin "round"
                ]
                []
            , path
                [ d "M6 7H12H18V18C18 19.6569 16.6569 21 15 21H9C7.34315 21 6 19.6569 6 18V7Z"
                , stroke "#000000"
                , strokeWidth "2"
                , strokeLinecap "round"
                , strokeLinejoin "round"
                ]
                []
            , path
                [ d "M9 5C9 3.89543 9.89543 3 11 3H13C14.1046 3 15 3.89543 15 5V7H9V5Z"
                , stroke "#000000"
                , strokeWidth "2"
                , strokeLinecap "round"
                , strokeLinejoin "round"
                ]
                []
            ]
        ]
