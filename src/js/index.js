
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
                nickname: "$nickname",
                endpoints: {
                    api : "http://api.com/",
                    websocket : "ws:///websocket.com"
                },
                room_id : "$room-id"
            }
        });

app.ports.log.subscribe((msg) => console.log(msg))

app.ports.sendVote.subscribe(msg => console.log("New Vote => ", msg))

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