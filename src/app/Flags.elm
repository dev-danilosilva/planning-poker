module Flags exposing (Flags, Endpoints, default, decode)
import Json.Decode

type alias Endpoints =
    { api : String }

type alias Flags =
    { documentTitle : String
    , endpoints : Endpoints
    , roomId    : String
    }

default : Flags
default =
    { documentTitle = "Fallback Configuration - Planning Poker"
    , endpoints = { api = "api endpoint" }
    , roomId = "Test Room"
    }

decode : Json.Decode.Decoder Flags
decode =
    Json.Decode.map3
        Flags
        (Json.Decode.field "document_title" Json.Decode.string)
        (Json.Decode.field "endpoints" endpointsDecoder)
        (Json.Decode.field "room_id"   Json.Decode.string)

endpointsDecoder : Json.Decode.Decoder Endpoints
endpointsDecoder =
    Json.Decode.map
        Endpoints
        (Json.Decode.field "api" Json.Decode.string)
