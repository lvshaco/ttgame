local shaco = require "shaco"

shaco.start(function()
    local db = assert(shaco.uniqueservice("db"))
    shaco.register("db", db)

    local game = assert(shaco.uniqueservice("game"))
    shaco.register("game", game)

    shaco.call(game, 'lua', 'open', {
        db = db,
        host = assert(shaco.getenv("host")),
        node_host = assert(shaco.getenv("node_host"))
    })
end)
