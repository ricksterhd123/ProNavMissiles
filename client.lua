local missiles = {}

function createMissile(creator, posX, posY, posZ, force, target, rotX, rotY, rotZ, velX, velY, velZ, model)
    local projectile = createProjectile(creator, 20, posX, posY, posZ, force, target, rotX, rotY, rotZ, velX, velY velZ, model)
    
    if projectile then
        missiles[projectile] = target                    
    end

    return projectile
end

-- Calculate rate of line of sight
-- rm = Missile position
-- rt = Target position
-- vm = Missile velocity
-- vt = Target velocity
-- Return dλ/dT
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

-- Calculate the acceleration needed to hit the target 
local function proportionalNavigation(missilePosition, missileVelocity, playerPosition, playerVelocity, NAV_CONST)
    -- Get the parameters for calculating LOS rate between missile and target
    local closingVelocity = missileVelocity - playerVelocity
    local x, y, z = missilePosition:getX(), missilePosition:getY(), missilePosition:getZ()
    local px, py, pz = playerPosition:getX(), playerPosition:getY(), playerPosition:getZ()
    local vx, vy, vz = missileVelocity:getX(), missileVelocity:getY(), missileVelocity:getZ()
    local pvx, pvy, pvz = playerVelocity:getX(), playerVelocity:getY(), playerVelocity:getZ()

    local LOSRate = LOSRate({x, y, z}, {px, py, pz}, {vx, vy, vz}, {pvx, pvy, pvz}) * deltaTime/20  -- i.e, 1000/50 = 20
    
    -- Command acceleration = N * Vc * dλ/dT
    -- where N  = Navigational constant
    --       Vc = Closing velocity
    --       λ  = Line of sight
    --       T  = Time in 1/50 seconds
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

local function update(deltaTime)
    for missile, target in pairs(missiles) do
        if missile and isElement(missile) and target and isElement(target) and missile.counter > 0 then
            local playerPosition = target.position
            local playerVelocity = target.velocity     -- m/ (s/50)
            local missilePosition = missile.position
            local missileVelocity = missile.velocity   -- m/ (s/50)
            local acceleration = proportionalNavigation(missile, target, 5)
            setElementVelocity(missile, missileVelocity + acceleration * deltaTime/20) -- m/(s/50)
            setProjectileMatrix(missile, missileVelocity)
        else
            missiles[missile] = nil -- free
        end
    end
end
addEventHandler("onClientPreRender", root, update)
