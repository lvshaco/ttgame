local shaco = require "shaco"

shaco.start(function()
    --local db = assert(shaco.uniqueservice("db"))
    --shaco.register("db", db)

    local rd = assert(shaco.uniqueservice("rd"))
    shaco.register("rd", rd)

    local game = assert(shaco.uniqueservice("game"))
    shaco.register("game", game)

    shaco.call(game, 'lua', 'open', {
        --db = db,
        rd = rd,
        host = assert(shaco.getenv("host")),
        node_host = assert(shaco.getenv("node_host"))
    })
end)
