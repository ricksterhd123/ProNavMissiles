local missiles = {}

function createMissile(creator, posX, posY, posZ, force, target, rotX, rotY, rotZ, velX, velY, velZ, model)
    local projectile = createProjectile(creator, 20, posX, posY, posZ, force, target, rotX, rotY, rotZ, velX, velY velZ, model)
    if projectile then
        missiles[projectile] = target                    
    end
    return projectile
end

-- Calculates the line of sight rate
-- rm = Missile position
-- rt = Target position
-- vm = Missile velocity
-- vt = Target velocity
-- Returns dλ/dT
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

-- Calculates the acceleration needed to hit the target, i.e. command acceleration
local function proportionalNavigation(missilePosition, missileVelocity, targetPosition, targetVelocity, NAV_CONST)
    -- Get the parameters for calculating LOS rate between missile and target
    -- TODO: remove Vector3 where possible
    local closingVelocity = missileVelocity - targetVelocity
    local x, y, z = missilePosition.x, missilePosition.y, missilePosition.z
    local px, py, pz = targetPosition.x, targetPosition.y, targetPosition.z
    local vx, vy, vz = missileVelocity.x, missileVelocity.y, missileVelocity.z
    local pvx, pvy, pvz = targetVelocity.z, targetVelocity.y, targetVelocity.z

    -- Command acceleration = N * Vc * dλ/dT
    -- where N  = Navigational constant
    --       Vc = Closing velocity
    --       λ  = Line of sight
    --       T  = Time in 1/50 seconds

    -- calculate dλ/dT
    local LOSRate = LOSRate({x, y, z}, {px, py, pz}, {vx, vy, vz}, {pvx, pvy, pvz}) * deltaTime/20  -- i.e, 1000/50 = 20
    -- return command
    return NAV_CONST * closingVelocity:getLength() * Vector3(unpack(LOSRate))
end

-- Utility function which makes the projectile p face towards vector forward.
local function setProjectileMatrix(projectile, forward)
    forward = -forward:getNormalized()
    forward = Vector3(forward.x, forward.y, - forward.z)
    local up = Vector3(0, 0, 1)
    local left = forward:cross(up)

    local ux, uy, uz = left.x, left.y, left.z
    local vx, vy, vz = forward.x, forward.y, forward.z
    local wx, wy, wz = up.x, up.y, up.z
    local x, y, z = projectile.position

    setElementMatrix(projectile, {{ux, uy, uz, 0}, {vx, vy, vz, 0}, {wx, wy, wz, 0}, {x, y, z, 1}})
    return true
end

-- Non creator client will pick up a new projectile (if it's streamed in) and hopefully the projectile packet will contain the target
-- as long as it's the right projectile type (20) and the creator exists.
local function syncMissiles(creator)
    local projectile = source

    if projectile and projecitle.type == 20 and projectile.target and creator then
        -- target  => sets target
        -- no target => sets to previous target or nil
        missiles[projectile] = projectile.target or missiles[projectile]
        iprint("Synced missile")
    end
end
addEventHandler("onClientProjectileCreation", root, syncMissiles)

-- Go through list of missiles and pronav them towards their destined targets.
local function update(deltaTime)
    for missile, target in pairs(missiles) do
        -- assume missile type = 20
        -- check it won't explode this frame
        if missile and missile.counter > 0 and target then
            local targetPosition = target.position
            local targetVelocity = target.velocity     -- m/ (s/50)
            local missilePosition = missile.position
            local missileVelocity = missile.velocity   -- m/ (s/50)
            local acceleration = proportionalNavigation(missile, target, 5)
            missile:setVelocity(missileVelocity + acceleration * deltaTime/20) -- m/(s/50)
            local x, y = getScreenFromWorldPosition(missilePosition)
            if x and y then dxDrawText("Missile", x, y) end
            missile:setMatrix(missileVelocity)
        else
            missiles[missile] = nil -- free
        end
    end
end
addEventHandler("onClientPreRender", root, update)
