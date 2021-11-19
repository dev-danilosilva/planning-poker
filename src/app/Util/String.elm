module Util.String exposing (cleanString)

cleanString : String -> String
cleanString str = str
                    |> String.trim
                    |> String.toLower
