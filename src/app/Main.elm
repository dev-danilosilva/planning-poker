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
import Html.Events exposing (onClick)

type alias Model =
    { documentTitle  : String
    , endpointsConfig : Flags.Endpoints
    , me             : Game.Player
    , players        : List Game.Player
    , roomId         : String
    }

type Msg
    = AddPlayer String
    | RemovePlayer String
    | UpdatePlayerVote String Game.VoteStatus
    | SendVote Game.VoteStatus
    | ResetAllVotes
    | GotSocketMessage Json.Decode.Value
    | InvalidSocketMessage Json.Decode.Value

type SocketEventType
    = AddPlayerEvent
    | RemovePlayerEvent
    | UpdatePlayerVoteEvent
    | ResetAllVotesEvent
    | InvalidSocketEvent

port getSocketMessage : (Json.Decode.Value -> msg) -> Sub msg

port log : Json.Encode.Value -> Cmd msg

port sendVote : Json.Encode.Value -> Cmd msg

logString : String -> Cmd msg
logString = log << Json.Encode.string

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
            let
                player = Game.newPlayer flags.nickname
            in
                ( Model flags.documentTitle
                        flags.endpoints
                        player
                        []
                        flags.roomId
                , logString <| "Me as " ++ player.nickname
                )
        Err err ->
            let
                error = err
                         |> Json.Decode.errorToString
                         |> Json.Encode.string
            in
            
                ( Model (.documentTitle <| Flags.default)
                        (.endpoints     <| Flags.default)
                        (Game.newPlayer <| .nickname <| Flags.default)
                        []
                        (.roomId <| Flags.default)
                , log error
                )

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AddPlayer nickname ->
            ( { model | players = Game.addNewPlayer (String.trim nickname) model.players }
            , logString <| "ADD -> " ++ nickname
            )
        
        RemovePlayer nickname ->
            ( { model | players = Game.removePlayer (String.trim nickname) model.players}
            , logString <| "DELETE -> " ++ nickname
            )
        
        UpdatePlayerVote nickname newVoteStatus ->
            ( { model | players = Game.updatePlayerVoteStatus nickname newVoteStatus model.players}
            , logString <| "UPDATE -> " ++ nickname ++ " vote to " ++ Game.voteStatusToString newVoteStatus
            )
        
        GotSocketMessage json ->
            case (Json.Decode.decodeValue socketMessageDecoder json) of
                Ok newMsg ->
                    update newMsg model
                Err err ->
                    let
                        error = Json.Decode.errorToString err
                    in
                        (model, logString error)
        
        SendVote voteStatus ->
            let
                me = model.me
                newMe = { me | voteStatus = voteStatus }
                newModel = { model | me = newMe }
                encodedMessage = socketMessageEncoder voteUpdatePayloadEncoder newMe "updatePlayerVote"
            in
                ( newModel
                , sendVote encodedMessage
                )

        ResetAllVotes ->
            ( { model | players = Game.emptyVotes model.players }
            , Cmd.none
            )
        
        InvalidSocketMessage json ->
            (model, log json)

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
    div [class "stripe", onClick <| SendVote Game.BlankVote]
        []

playerListView : List Game.Player -> Html Msg
playerListView players =
    div [class "player-list"]
        <| List.append  [ div [] [ h3 [] [text "ONLINE"] ]
                        ]
                        (List.map playerView players)

playerView : Game.Player -> Html Msg
playerView player =
    div [ class "player-view"]
        [ p []
            [ text player.nickname
            , text <| "  ->  " ++ Game.voteStatusToString player.voteStatus
            ]
        ]

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
            Json.Decode.value |> Json.Decode.andThen invalidSocketEventDecoder

invalidSocketEventDecoder : Json.Decode.Value -> Json.Decode.Decoder Msg
invalidSocketEventDecoder json =
    Json.Decode.succeed <| InvalidSocketMessage json

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
    if cleanString decodedString == "blank" then
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

cleanString : String -> String
cleanString str = str
                    |> String.trim
                    |> String.toLower


---- Encoders and Encoder Helpers

socketMessageEncoder : (a -> Json.Encode.Value) -> a -> String -> Json.Encode.Value
socketMessageEncoder payloadEncoder value eventName =
    Json.Encode.object
        [ ("event", Json.Encode.string eventName)
        , ("payload", payloadEncoder value)]

voteUpdatePayloadEncoder : Game.Player -> Json.Encode.Value
voteUpdatePayloadEncoder player =
    Json.Encode.object
        [ ("nickname", Json.Encode.string player.nickname)
        , ("vote", voteStatusEncoder player.voteStatus)
        ]

voteStatusEncoder : Game.VoteStatus -> Json.Encode.Value
voteStatusEncoder voteStatus =
    case voteStatus of
        Game.EmptyVote ->
            Json.Encode.null
        Game.BlankVote ->
            Json.Encode.string "blank"
        Game.ValidVote vote ->
            validVoteEncoder vote

validVoteEncoder : Game.Vote -> Json.Encode.Value
validVoteEncoder vote =
    Json.Encode.object
        [ ("representation", Json.Encode.string vote.representation)
        , ("value", Json.Encode.float vote.value)
        ]
