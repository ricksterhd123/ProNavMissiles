local function LOSRate(rm, rt, vm, vt)
    local R = {rt[1] - rm[1], rt[2] - rm[2], rt[3] - rm[3]}
    local r = (R[1] ^ 2 + R[2] ^ 2 + R[3] ^ 2) ^ (1 / 2)
    local vcl = {vm[1] - vt[1], vm[2] - vt[2], vm[3] - vt[3]}
    local abVcl = (vcl[1]^2 + vcl[2]^2 + vcl[3]^2) ^ (1 / 2)

    local LOSRate = {}
    for i = 1, 3 do
        LOSRate[i] = r > 0 and ((vt[i] - vm[i]) / r) + (R[i] * abVcl) / r^2 or 0
    end
    return LOSRate
end

local prevVel = false   -- Used to calculate acceleration
local function proportionalNavigation(missile, target, NAV_CONST)
    local playerPosition = Vector3(getElementPosition(target))
    local playerVelocity = Vector3(getElementVelocity(target))
    if not prevVel then
        prevVel = playerVelocity
    end
    local playerAccel = playerVelocity - prevVel
    local missilePosition = Vector3(getElementPosition(missile))
    local missileVelocity = Vector3(getElementVelocity(missile))
    -- local maxSpeed = 1 -- m/s
    -- missileVelocity = missileVelocity:getNormalized() * math.min(maxSpeed, missileVelocity:getLength())
    local closingVelocity = missileVelocity - playerVelocity
    local x, y, z = missilePosition:getX(), missilePosition:getY(), missilePosition:getZ()
    local px, py, pz = playerPosition:getX(), playerPosition:getY(), playerPosition:getZ()
    local vx, vy, vz = missileVelocity:getX(), missileVelocity:getY(), missileVelocity:getZ()
    local pvx, pvy, pvz = playerVelocity:getX(), playerVelocity:getY(), playerVelocity:getZ()
    --iprint("missile, target", missileVelocity:getLength(), playerVelocity:getLength())
    local LOSRate = LOSRate({x, y, z}, {px, py, pz}, {vx, vy, vz}, {pvx, pvy, pvz})
    return NAV_CONST * closingVelocity:getLength() * Vector3(unpack(LOSRate))
end

-- Utility function which makes the projectile p face towards vector forward.
local function setProjectileMatrix(p, forward)
    forward = -forward:getNormalized()
    forward = Vector3(forward:getX(), forward:getY(), - forward:getZ())
    local up = Vector3(0, 0, 1)
    local left = forward:cross(up)

    local ux, uy, uz = left:getX(), left:getY(), left:getZ()
    local vx, vy, vz = forward:getX(), forward:getY(), forward:getZ()
    local wx, wy, wz = up:getX(), up:getY(), up:getZ()
    local x, y, z = getElementPosition(p)

    setElementMatrix(p, {{ux, uy, uz, 0}, {vx, vy, vz, 0}, {wx, wy, wz, 0}, {x, y, z, 1}})
    return true
end

local missiles = {}

function createProjectile(creator, target, x, y, z)
    if element == getPedOccupiedVehicle(localPlayer) then
        local p = createProjectile(localPlayer, 20, x, y, z)
        missiles[element]= {p, getTickCount()}
    end
end

local function update(deltaTime)
    for target, missileData in pairs(missiles) do
        local missile = missileData[1]
        local start = missileData[2]

        if target and missile and isElement(missile) and getTickCount() - start >= 1000 then
            local acceleration = proportionalNavigation(missile, target, 5)
            setElementVelocity(missile, missileVelocity + acceleration)
            setProjectileMatrix(missile, missileVelocity)
        end
    end
end
addEventHandler("onClientPreRender", root, render)
