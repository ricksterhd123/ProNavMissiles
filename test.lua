--[[
    For testing purposes
]]

local x, y, z = 91.20548, 1764.03809, 17.64063
local radius = 100
local height = 50
local colTube = createColTube(x, y, z, radius, height)

function hitTube(element, matchingDimension)
    if element == localPlayer or element == localPlayer.vehicle then
        createMissile(localPlayer, x, y, z + 10, 1, localPlayer or localPlayer.vehicle)
    end
end

addEventHandler("onClientColShapeHit", root, hitTube)