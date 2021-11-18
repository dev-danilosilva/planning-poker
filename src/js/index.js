
function main(params) {
    const app = Elm.Main.init({
        node: params.entry_node,
        flags: params.config
    })

    return app;
}

function makeid(length) {
    let result           = '';
    const characters       = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.-#$%&!';
    const charactersLength = characters.length;
    for ( var i = 0; i < length; i++ ) {
      result += characters.charAt(Math.floor(Math.random() * charactersLength));
   }
   return result;
}

const app = 
        main({
                entry_node : document.querySelector('#app'),
                config : {
                    document_title : "Collections Team",
                    endpoints: {
                        api : "http://api.com/",
                        websocket : "ws:///websocket.com"
                    },
                    room_id : "#123"
                }
            });


setInterval(() => {
    app.ports.extraConfig.send({message : makeid(10), status: "200"});
}, 10000);
