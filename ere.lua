local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Window = WindUI:CreateWindow({
    Folder = "Ringta Scripts",
    Title = "RINGTA",
    Icon = "star",
    Author = "discord.gg/ringta",
    Theme = "Dark",
    Size = UDim2.fromOffset(500, 350),
    Transparent = false,
    HasOutline = true,
})

Window:EditOpenButton({
    Title = "Open RINGTA SCRIPTS",
    Icon = "pointer",
    CornerRadius = UDim.new(0, 6),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromRGB(200, 0, 255), Color3.fromRGB(0, 200, 255)),
    Draggable = true,
})

local Tabs = {
    Main = Window:Tab({ Title = "Main", Icon = "star" }),
    Hide = Window:Tab({ Title = "Autofarm", Icon = "eye-off" }),
    Jump = Window:Tab({ Title = "Autoheal", Icon = "shopping-basket" }),
    Random = Window:Tab({ Title = "Random Features", Icon = "dices" }),
    Brainrot = Window:Tab({ Title = "Auto Pickup?", Icon = "brain" }), 
}






local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local goToShelbyEnabled = false
local goToShelbyThread = nil

local function getShelby()
    local Critters = workspace:FindFirstChild("Critters")
    return Critters and Critters:FindFirstChild("Shelby")
end

local function getRootPart(model)
    if not model then return nil end
    return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
end

local function tryMoveTo(humanoid, position, timeout)
    timeout = timeout or 2
    local reached = false
    local finished = false

    local function onFinish(reach)
        finished = true
        reached = reach
    end

    local conn = humanoid.MoveToFinished:Connect(onFinish)
    humanoid:MoveTo(position)
    local startTime = tick()
    while not finished and tick() - startTime < timeout do
        task.wait(0.1)
    end
    conn:Disconnect()
    return reached
end

local function tryJump(humanoid)
    if humanoid:GetState() ~= Enum.HumanoidStateType.Jumping and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
        humanoid.Jump = true
    end
end

local function fallbackNudge(humanoid, root, targetPos, nudgeStep)
    nudgeStep = nudgeStep or 6
    local direction = (targetPos - root.Position).Unit
    local nudgePos = root.Position + direction * nudgeStep
    tryJump(humanoid)
    tryMoveTo(humanoid, nudgePos, 1.2)
end

local function chunkTowards(humanoid, startPart, endPos, chunkSize)
    local currentPos = startPart.Position
    local direction = (endPos - currentPos).Unit
    local totalDist = (endPos - currentPos).Magnitude
    local steps = math.ceil(totalDist / chunkSize)
    for i = 1, steps do
        if not goToShelbyEnabled then break end
        local nextPos = (i == steps) and endPos or (currentPos + direction * chunkSize * i)
        local path = PathfindingService:CreatePath({
            AgentRadius = 2,
            AgentHeight = 4,
            AgentCanJump = true,
            AgentJumpHeight = 16,
            AgentMaxSlope = 45,
        })
        path:ComputeAsync(startPart.Position, nextPos)
        if path.Status == Enum.PathStatus.Success then
            local waypoints = path:GetWaypoints()
            for _, waypoint in ipairs(waypoints) do
                if not goToShelbyEnabled then break end
                local reached = tryMoveTo(humanoid, waypoint.Position, 2.5)
                if not reached then
                    -- Try to jump or nudge if stuck
                    tryJump(humanoid)
                    fallbackNudge(humanoid, startPart, waypoint.Position, 8)
                end
            end
            currentPos = nextPos
        else
            -- fallback: nudge forward and try to jump
            fallbackNudge(humanoid, startPart, nextPos, 12)
            currentPos = nextPos
        end
    end
end

Tabs.Main:Toggle({
    Title = "Go To Shelby (Robust Path)",
    Icon = "pointer",
    Default = false,
    Callback = function(state)
        goToShelbyEnabled = state
        if state then
            if goToShelbyThread then return end
            goToShelbyThread = task.spawn(function()
                local targetPos = Vector3.new(702, -4, -1772)
                local reachedShelbyArea = false
                while goToShelbyEnabled do
                    local character = LocalPlayer.Character
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    local root = getRootPart(character)
                    if not humanoid or not root then
                        task.wait(0.5)
                        continue
                    end
                    if not reachedShelbyArea then
                        chunkTowards(humanoid, root, targetPos, 150) -- smaller chunks, more frequent pathing
                        reachedShelbyArea = true
                    else
                        local shelby = getShelby()
                        local shelbyRoot = getRootPart(shelby)
                        if shelbyRoot then
                            chunkTowards(humanoid, root, shelbyRoot.Position, 120)
                        end
                        task.wait(0.5)
                    end
                end
                goToShelbyThread = nil
            end)
        else
            goToShelbyEnabled = false
            if goToShelbyThread then
                task.cancel(goToShelbyThread)
                goToShelbyThread = nil
            end
        end
    end
})




local VirtualInputManager = game:GetService("VirtualInputManager")
local autoMineEnabled = false
local autoMineThread = nil

Tabs.Main:Toggle({
    Title = "Auto Mine",
    Icon = "pickaxe",
    Default = false,
    Callback = function(state)
        autoMineEnabled = state
        if state then
            if autoMineThread then return end
            autoMineThread = task.spawn(function()
                while autoMineEnabled do
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                    task.wait(0.018)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                    task.wait(0.12)
                end
            end)
        else
            autoMineEnabled = false
            if autoMineThread then
                task.cancel(autoMineThread)
                autoMineThread = nil
            end
        end
    end
})
