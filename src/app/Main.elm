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
import Json.Encode
import Util.String

type alias Model =
    { documentTitle  : String
    , endpointsConfig : Flags.Endpoints
    , players        : List Game.Player
    , roomId         : String
    }

type Msg
    = AddPlayer String
    | RemovePlayer String
    | UpdatePlayerVote String Game.VoteStatus
    | ResetAllVotes
    | GotSocketMessage Json.Decode.Value
    | InvalidSocketMessage

type SocketEventType
    = AddPlayerEvent
    | RemovePlayerEvent
    | UpdatePlayerVoteEvent
    | ResetAllVotesEvent
    | InvalidSocketEvent

port getSocketMessage : (Json.Decode.Value -> msg) -> Sub msg

port log : Json.Encode.Value -> Cmd msg

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
            ( { model | players = Game.addNewPlayer (String.trim nickname) model.players }
            , Cmd.none
            )
        
        RemovePlayer nickname ->
            ( { model | players = Game.removePlayer (String.trim nickname) model.players}
            , Cmd.none
            )
        
        UpdatePlayerVote nickname newVoteStatus ->
            ( { model | players = Game.updatePlayerVoteStatus nickname newVoteStatus model.players}
            , Cmd.none
            )
        
        GotSocketMessage json ->
            case (Json.Decode.decodeValue socketMessageDecoder json) of
                Ok newMsg ->
                    update newMsg model
                        |> Tuple.mapSecond (\_ -> log json)
                Err err ->
                    let
                        _ = Debug.log "Decode Error: " err
                    in
                    
                        (model, log json)
        
        ResetAllVotes ->
            ( { model | players = Game.emptyVotes model.players }
            , Cmd.none
            )
        
        InvalidSocketMessage->
            (model, Cmd.none)

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

        UpdatePlayerVoteEvent ->
            Json.Decode.map2
                UpdatePlayerVote
                (Json.Decode.at ["payload", "nickname"] Json.Decode.string)
                (Json.Decode.at ["payload", "vote"] voteStatusDecoder)

        ResetAllVotesEvent ->
            Json.Decode.succeed ResetAllVotes

        InvalidSocketEvent ->
            Json.Decode.succeed InvalidSocketMessage

voteStatusDecoder : Json.Decode.Decoder Game.VoteStatus
voteStatusDecoder =
    Json.Decode.oneOf
        [ validVoteDecoder
        , emptyVoteDecoder
        , Json.Decode.string |> Json.Decode.andThen blankVoteDecoder
        , Json.Decode.fail "Invalid Vote Status. The vote you sent does not follow the Vote Status contract."
        ]

emptyVoteDecoder : Json.Decode.Decoder Game.VoteStatus
emptyVoteDecoder =
    Json.Decode.null Game.EmptyVote

blankVoteDecoder : String -> Json.Decode.Decoder Game.VoteStatus
blankVoteDecoder decodedString =
    if Util.String.cleanString decodedString == "blank" then
        Json.Decode.succeed Game.BlankVote
    else
        Json.Decode.fail "The string given is not equals to `blank`"

validVoteDecoder : Json.Decode.Decoder Game.VoteStatus
validVoteDecoder =
    Json.Decode.map
        Game.ValidVote
        voteDecoder

voteDecoder : Json.Decode.Decoder Game.Vote
voteDecoder =
    Json.Decode.map2
        Game.Vote
        (Json.Decode.field "value" Json.Decode.float)
        (Json.Decode.field "representation" Json.Decode.string)        

parseEventType : String -> SocketEventType
parseEventType eventType =
    case String.trim eventType of
            "addPlayer" ->
                AddPlayerEvent
            "removePlayer" ->
                RemovePlayerEvent
            "updatePlayerVote" ->
                UpdatePlayerVoteEvent
            _ ->
                InvalidSocketEvent
