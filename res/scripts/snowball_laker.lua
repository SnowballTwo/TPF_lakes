local vec4 = require "vec4"
local transf = require "transf"

local vec2 = require "snowball_laker_vec2"
local mat2 = require "snowball_laker_mat2"
local polygon = require "snowball_laker_polygon"
local plan = require "snowball_laker_planner"
local laker = {}

laker.markerStore = nil
laker.finisherStore = nil
laker.markerId = "asset/snowball_laker_marker.mdl"
laker.finisherId = "asset/snowball_laker_finisher.mdl"

function laker.getObjects()

    if not laker.markerStore then
        laker.markerStore = {}
    end
    if not laker.finisherStore then
        laker.finisherStore = {}
    end

    local built = plan.updateEntityLists(laker.markerId, laker.markerStore, laker.finisherId, laker.finisherStore)  
    
    return {
        built = built,
        markers = laker.markerStore,
        finishers = laker.finisherStore
    }
end

function laker.getPolygon(position)
    if not position then
        return nil
    end

    local delta = 5
    local max = 15000
    local count = 0
    local points = {}

    local desiredHeight = position[3]
    local start = {position[1], position[2]}
    local pos = start
    local last = nil

    points[#points + 1] = position

    while (count < max) and (count < 3 or vec2.dist(start, pos) > delta * 1.5) do
        local next = nil
        local minDeviation = nil

        local dir = {delta, 0}
        local parts = 72
        local imin = 0
        local imax = parts

        if last then
            dir = vec2.sub(pos, last)
            imin = -0.25 * parts
            imax = 0.25 * parts
        end

        for i = imin, imax do
            local p = vec2.add(pos, mat2.mul(mat2.rot(2 * math.pi / parts * i), dir))
            local h = game.interface.getHeight(p)

            local deviation = math.abs(h - desiredHeight)

            if (not minDeviation) or (deviation < minDeviation) then
                minDeviation = deviation
                p[3] = desiredHeight
                next = p
            end
        end

        if not next then
            return nil
        end
       
        last = pos
        pos = next

        points[#points + 1] = pos
        count = count + 1
    end

    if count >= max - 1 or #points < 3 or polygon.isSelfIntersecting(points) then
        return nil
    end

    return points
end

function laker.clearMarkers()

    for i = 1, #laker.markerStore do
        local entity = laker.markerStore[i]
        game.interface.bulldoze(entity.id)
    end

    laker.markerStore = {}
end

function laker.clearFinishers()

    for i = 1, #laker.finisherStore do
        local entity = laker.finisherStore[i]
        game.interface.bulldoze(entity.id)
    end

    laker.finisherStore = {}
end

function laker.marker(result)
    result.models[#result.models + 1] = {
        id = "asset/snowball_laker_marker.mdl",
        transf = {0.01, 0, 0, 0, 0, 0.01, 0, 0, 0, 0, 0.01, 0, 0, 0, 0, 1}
    }
end

function laker.finisher(result)
    result.models[#result.models + 1] = {
        id = "asset/snowball_laker_finisher.mdl",
        transf = {0.01, 0, 0, 0, 0, 0.01, 0, 0, 0, 0, 0.01, 0, 0, 0, 0, 1}
    }
end

function laker.set(map, x, y, value)
    if (not map[x]) then
        map[x] = {}
    end

    map[x][y] = value
end

function laker.get(map, x, y)
    if (not map) or (not map[x]) then
        return nil
    end

    return map[x][y]
end

function laker.placeOrDivide(x, y, z, size, minSize, checkMap, outline, bounds, models)

    local tilex = math.floor((x - bounds.x) / size) * size
    local tiley = math.floor((y - bounds.y) / size) * size
    local divide = laker.get(checkMap[size], tilex, tiley)

    if size == minSize then
        divide = false
    end

    local scale = 16

    if divide then
        laker.placeOrDivide(x, y, z, 0.5 * size, minSize, checkMap, outline, bounds, models)
        laker.placeOrDivide(x + 0.5 * size, y, z, 0.5 * size, minSize, checkMap, outline, bounds, models)
        laker.placeOrDivide(x + 0.5 * size, y + 0.5 * size, z, 0.5 * size, minSize, checkMap, outline, bounds, models)
        laker.placeOrDivide(x, y + 0.5 * size, z, 0.5 * size, minSize, checkMap, outline, bounds, models)
    else
        local draw =
            polygon.contains(outline, {x, y}, bounds) or polygon.contains(outline, {x + size, y}, bounds) or
            polygon.contains(outline, {x + size, y + size}, bounds) or
            polygon.contains(outline, {x, y + size}, bounds)

        if draw then
            local transform =
                transf.new(
                vec4.new(scale, .0, .0, .0),
                vec4.new(.0, scale, .0, .0),
                vec4.new(.0, .0, scale, .0),
                vec4.new(x, y, z, 1.0)
            )

            models[#models + 1] = {
                id = "asset/snowball_laker_water_" .. size .. ".mdl",
                transf = transform
            }
        end
    end
end

function laker.lock(interactive)
    local player = nil
    if interactive then
        player = game.interface.getPlayer()
    end

    local lakes =
        game.interface.getEntities(
        {pos = {0, 0}, radius = 100000},
        {type = "CONSTRUCTION", fileName = "asset/snowball_laker_lake.con"}
    )
    for i = 1, #lakes do
        game.interface.setPlayer(lakes[i], player)
    end
end

return laker