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
    | InvalidOperation String

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
                    (Game.updatePlayerVoteStatus "danilo.silva " Game.Null  [ Game.newPlayer "danilo.silva"
                                                                           , Game.newPlayer "fulano.ciclano"
                                                                           , Game.newPlayer "kiko.dochaves"])
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

        InvalidOperation errorMessage->
            let
                _ = Debug.log "Application Log: " ("Invalid Operation - " ++ errorMessage)
            in
                (model, Cmd.none)

-- port sendMessage : String -> Cmd msg

port extraConfig : (Json.Decode.Value -> msg) -> Sub msg

type alias OutMsg =
    { message : String
    , status : String}

subscriptions : Model -> Sub Msg
subscriptions _ =
    let
        msgDecoder = Json.Decode.map2 OutMsg
                                      (Json.Decode.field "message" Json.Decode.string)
                                      (Json.Decode.field "status"  Json.Decode.string)
        decodeValue message =
            case Json.Decode.decodeValue msgDecoder message of
                Ok m -> AddPlayer m.message
                Err _ -> InvalidOperation "Error Parsing Socket Message"

    in
        extraConfig decodeValue
    

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
