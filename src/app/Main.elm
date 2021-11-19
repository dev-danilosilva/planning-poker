port module Main exposing (..)

import Browser

import Html exposing ( Html
                     , div
                     , h3
                     , p
                     , text
                     )
import Html.Attributes exposing ( class
                                )
import Json.Decode
import Flags
import Game

type alias Model =
    { documentTitle  : String
    , endpointsConfig : Flags.Endpoints
    , players        : List Game.Player
    , roomId         : String
    }

type Msg
    = AddPlayer String
    | RemovePlayer String
    | GotSocketMessage Json.Decode.Value
    | InvalidSocketMessage

type SocketEventType
    = AddPlayerEvent
    | RemovePlayerEvent
    | InvalidSocketEvent

port getSocketMessage : (Json.Decode.Value -> msg) -> Sub msg


main : Program Json.Decode.Value Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

init : Json.Decode.Value -> (Model, Cmd Msg)
init flagsValue = 
    case Json.Decode.decodeValue Flags.decode flagsValue of
        Ok flags ->
            ( Model flags.documentTitle
                    flags.endpoints
                    []
                    flags.roomId
            , Cmd.none
            )
        Err _ ->
            ( Model (Flags.default |> .documentTitle)
                    (Flags.default |> .endpoints)
                    []
                    (Flags.default |> .roomId)
            , Cmd.none
            )

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AddPlayer nickname ->
            ( { model | players = Game.addNewPlayer nickname model.players }
            , Cmd.none
            )
        
        RemovePlayer nickname ->
            ( { model | players = Game.removePlayer nickname model.players}
            , Cmd.none
            )
        
        GotSocketMessage json ->
            case (Json.Decode.decodeValue socketMessageDecoder json) of
                Ok newMsg ->
                    update newMsg model
                Err _ ->
                    (model, Cmd.none)

        InvalidSocketMessage->
            (model, Cmd.none)
-- port sendMessage : String -> Cmd msg

subscriptions : Model -> Sub Msg
subscriptions _ =
    getSocketMessage GotSocketMessage
    

view : Model -> Browser.Document Msg
view model =
    { title = model.documentTitle
    , body  = [ stripe
              , applicationBody model
              ]
    }

applicationBody : Model -> Html Msg
applicationBody model =
    div [class "main-view"]
        [playerListView model.players]

stripe : Html Msg
stripe =
    div [class "stripe"]
        []

playerListView : List Game.Player -> Html Msg
playerListView players =
    div [class "player-list"]
        <| List.append  [ div [] [ h3 [] [text "ONLINE"] ]
                        ]
                        (List.map playerView players)

playerView : Game.Player -> Html Msg
playerView player =
    div [class "player-view"]
        [p [] [text player.nickname]]

-- Decoders and Decoder Helpers
socketMessageDecoder : Json.Decode.Decoder Msg
socketMessageDecoder =
    Json.Decode.field "event" Json.Decode.string
        |> Json.Decode.andThen payloadDecoder

payloadDecoder : String -> Json.Decode.Decoder Msg
payloadDecoder eventType =
    case parseEventType eventType of
        AddPlayerEvent ->
            Json.Decode.map
                AddPlayer
                (Json.Decode.at ["payload", "nickname"] Json.Decode.string)
        RemovePlayerEvent ->
            Json.Decode.map
                RemovePlayer
                (Json.Decode.at ["payload", "nickname"] Json.Decode.string)
        InvalidSocketEvent ->
            Json.Decode.succeed InvalidSocketMessage

parseEventType : String -> SocketEventType
parseEventType eventType =
    case eventType of
        "addPlayer" ->
            AddPlayerEvent
        "removePlayer" ->
            RemovePlayerEvent
        _ ->
            InvalidSocketEvent
