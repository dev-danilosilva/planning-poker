module Game exposing ( Player
                     , Vote
                     , VoteStatus(..)
                     , addNewPlayer
                     , defaultScale
                     , emptyVotes
                     , newPlayer
                     , removePlayer
                     , updatePlayerVoteStatus
                     , validate
                     )

type alias Player =
    { nickname : String
    , voteStatus : VoteStatus
    }

type alias Vote =
    { value : Float
    , representation : String
    }

type VoteStatus
    = EmptyVote
    | BlankVote
    | ValidVote Vote

type alias Validation = List Player -> Result (List ValidationError) (List Player)
type alias VoteScale = List Vote

type ValidationError
    = EveryoneShouldVoteError
    | VoteOutOfSelectedScaleError

stringfyErrors : ValidationError -> String
stringfyErrors error =
    case error of
        EveryoneShouldVoteError ->
            "Everyone Should Vote"
        VoteOutOfSelectedScaleError ->
            "Someone Has Voted"

newPlayer : String -> Player
newPlayer nickname =
    { nickname = nickname
    , voteStatus = EmptyVote
    }

addNewPlayer : String -> List Player -> List Player
addNewPlayer nickname players =
    (newPlayer nickname) :: players

removePlayer : String -> List Player -> List Player
removePlayer nickname players =
    case players of
        [] ->
            players
        (player::restOfPlayers) ->
            if player.nickname == nickname then
                removePlayer nickname restOfPlayers
            else
                player :: removePlayer nickname restOfPlayers

updatePlayerVoteStatus : String -> VoteStatus -> List Player -> List Player
updatePlayerVoteStatus nickname newVote =
    let
        updateVoteStatus : Player -> Player
        updateVoteStatus player =
            if player.nickname == nickname then
                { player | voteStatus = newVote }
            else
                player

    in
        List.map updateVoteStatus

emptyVotes : List Player -> List Player
emptyVotes =
    List.map (\player ->
                { player | voteStatus = EmptyVote })

defaultScale : VoteScale
defaultScale =
    [ {value = 1.0,  representation = "1"}
    , {value = 2.0,  representation = "2"}
    , {value = 3.0,  representation = "3"}
    , {value = 5.0,  representation = "5"}
    , {value = 8.0,  representation = "8"}
    , {value = 13.0, representation = "13"}
    , {value = 21.0, representation = "21"}
    ]

-- createScale : List (Float, String) -> VoteScale
-- createScale ls =
--     List.map (\t -> Vote (Tuple.first t) (Tuple.second t)) ls

-- createScaleByRepresentation : List String -> VoteScale
-- createScaleByRepresentation sortedRepresentations =
--     sortedRepresentations
--         |> List.map2 Tuple.pair ( List.map toFloat (List.range 1
--                                                                (List.length sortedRepresentations)))
--         |> createScale

validations : List Validation
validations =
    [ everyoneShouldVote
    , allVotesAreWithinTheSameScale defaultScale
    , removeNullAndEmptyVotes
    ]

validate : List Player -> Result (List String) (List Player)
validate players =
    let
        validationResult = validate_ validations [] players
    in
        case validationResult of
            Ok ps ->
                Ok ps
            Err errors ->
                errors
                    |> List.map stringfyErrors
                    |> Err

validate_ : List Validation -> List ValidationError -> List Player -> Result (List ValidationError) (List Player)
validate_ validationList errorList playerList =
    case validationList of
        [] ->
            if List.isEmpty errorList then
                Ok playerList
            else
                Err errorList
        (validation::restOfValidations) ->
            let
                validationResult = validation playerList
            in
                case validationResult of
                    Ok resultantPlayerList ->
                        validate_ restOfValidations errorList resultantPlayerList
                    Err currentValidationErrors ->
                        currentValidationErrors
                            |> List.append errorList
                            |> Err

everyoneShouldVote : Validation
everyoneShouldVote players =
    let
        validationSuceeded = 
            List.foldl
                (\player result -> (player.voteStatus == EmptyVote)
                                        |> not
                                        |> (&&) result)
                True 
                players  
    in
        if validationSuceeded then
            Ok players
        else
            Err [EveryoneShouldVoteError]

allVotesAreWithinTheSameScale : VoteScale -> Validation
allVotesAreWithinTheSameScale scale players=
    let
        scaleValues : List Float
        scaleValues = List.map .value scale

        voteInScale : VoteStatus -> Bool
        voteInScale voteStatus =
                    case voteStatus of
                        ValidVote x ->
                            List.member x.value scaleValues
                        _  -> False
    in
        players
            |> List.map .voteStatus
            |> List.foldl (\status result -> result && voteInScale status) True
            |> (\result ->
                    if result then
                        Ok players
                    else
                        Err [VoteOutOfSelectedScaleError])

removeNullAndEmptyVotes : Validation
removeNullAndEmptyVotes playerList =
    let
        isNotNullOrEmpty player = case player.voteStatus of
                                    ValidVote _ -> True
                                    _       -> False
    in
        Ok <| List.filter isNotNullOrEmpty playerList

