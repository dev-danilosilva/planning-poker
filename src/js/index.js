
function main(params) {
    const app = Elm.Main.init({
        node: params.entry_node,
        flags: params.config
    })

    return app;
}

const app = 
    main({
            entry_node : document.querySelector('#app'),
            config : {
                document_title : "Scrum Tools",
                nickname: "danilos.silva",
                endpoints: {
                    api : "http://api.com/",
                    websocket : "ws:///websocket.com"
                },
                room_id : "#123"
            }
        });

app.ports.log.subscribe((msg) => console.log(msg))

app.ports.sendVote.subscribe(msg => console.log("New Vote => ", msg))

setTimeout(() => {
    app.ports.getSocketMessage.send({ event : "addPlayer", payload : {nickname : "maria.joaquina"}})
}, 5000);

setTimeout(() => {
    app.ports.getSocketMessage.send({ event : "addPlayer", payload : {nickname : "cirilo.joao"}})
}, 8000);

setTimeout(() => {
    app.ports.getSocketMessage.send(
        { event : "updatePlayerVote"
        , payload : { nickname : "cirilo.joao"
                    , vote: { representation: "3"
                            , value : 3.0
                            }
                    }
        })
}, 12000);

setTimeout(() => {
    app.ports.getSocketMessage.send(
        { event : "updatePlayerVote"
        , payload : { nickname : "cirilo.joao"
                    , vote: "blank"
                    }
        })
}, 14000);

setTimeout(() => {
    app.ports.getSocketMessage.send(
        { event : "updatePlayerVote"
        , payload : { nickname : "maria.joaquina"
                    , vote: { representation: "3"
                            , value : 3.0
                            }
                    }
        })
}, 16000);

setTimeout(() => {
    app.ports.getSocketMessage.send({ event : "removePlayer", payload : {nickname : "cirilo.joao"}})
}, 18000);

// Event Contract
// 
// WEBSOCKET CONNECTION STATUS
// 
// { event : "connected" | "disconnected"}
// 
// ADD PLAYER
//
//  { event : "addPlayer"
//  , payload : {nickname : "danilo.silva"}}
//
// 
// REMOVE PLAYER
//
//  { event : "removePlayer"
//  , payload : {nickname : "danilo.silva"}}
//
// 
// UPDATE PLAYER VOTE (IN/OUT)
// 
// { event : "updatePlayerVote"
// , payload : { nickname : "danilo.silva"
//             , vote: { representation: "M"
//                     , value : 3.0
//                     }
//             }
// }
//
//Obs. The payload.vote must have a null value for empty votes and a string "blank" for blank votes
//