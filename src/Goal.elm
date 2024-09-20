module Goal exposing (..)

import Time


type alias Goal =
    { text : String
    , daysTracked : List Time.Posix
    }
