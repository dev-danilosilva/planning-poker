
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
                document_title : "Squad Tools",
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

setTimeout(() => app.ports.getSocketMessage.send({event: "addPlayer", payload: {nickname : "danilo"}}), 2000)
setTimeout(() => app.ports.getSocketMessage.send({event: "addPlayer", payload: {nickname : "mayara"}}), 4000)
setTimeout(() => app.ports.getSocketMessage.send({event: "addPlayer", payload: {nickname : "lucas"}}), 5000)
setTimeout(() => app.ports.getSocketMessage.send({event: "updatePlayerVote", payload: {nickname : "danilo", vote : {representation : "XS", value: 1.0}}}), 5000)
setTimeout(() => app.ports.getSocketMessage.send({event: "addPlayer", payload: {nickname : "pedro"}}), 6000)
setTimeout(() => app.ports.getSocketMessage.send({event: "updatePlayerVote", payload: {nickname : "mayara", vote: {representation : "S", value: 2.0}}}), 6000)
setTimeout(() => app.ports.getSocketMessage.send({event: "addPlayer", payload: {nickname : "cassia"}}), 7000)
setTimeout(() => app.ports.getSocketMessage.send({event: "updatePlayerVote", payload: {nickname : "pedro", vote: {representation : "XS", value: 1.0}}}), 7000)
setTimeout(() => app.ports.getSocketMessage.send({event: "addPlayer", payload: {nickname : "luana"}}), 8000)
setTimeout(() => app.ports.getSocketMessage.send({event: "updatePlayerVote", payload: {nickname : "luana", vote: {representation : "L", value: 4.0}}}), 11000)


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