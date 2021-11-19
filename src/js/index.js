
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
                    endpoints: {
                        api : "http://api.com/",
                        websocket : "ws:///websocket.com"
                    },
                    room_id : "#123"
                }
            });

app.ports.log.subscribe((msg) => console.log(msg))

setTimeout(() => {
    app.ports.getSocketMessage.send({ event : "addPlayer", payload : {nickname : "maria.joaquina"}})
}, 5000);

setTimeout(() => {
    app.ports.getSocketMessage.send({ event : "addPlayer", payload : {nickname : "cirilo.joao"}})
}, 8000);

setTimeout(() => {
    app.ports.getSocketMessage.send({ event : "removePlayer", payload : {nickname : "cirilo.joao"}})
}, 10000);

// Event Contract
// 
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
// UPDATE PLAYER VOTE
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
