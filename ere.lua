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
    local direction = (targetPos - root.Position)
    if direction.Magnitude < 1 then return end
    direction = direction.Unit
    local nudgePos = root.Position + direction * nudgeStep
    tryJump(humanoid)
    tryMoveTo(humanoid, nudgePos, 1.2)
end

-- This version will always move towards the target in small steps until it's close
local function moveCloserAndCloser(humanoid, root, targetPos, stepSize, tolerance)
    tolerance = tolerance or 8
    stepSize = math.min(stepSize or 90, 250) -- never let a single move exceed 250 studs
    while (root.Position - targetPos).Magnitude > tolerance and goToShelbyEnabled do
        local currentPos = root.Position
        local direction = (targetPos - currentPos)
        local dist = direction.Magnitude
        if dist < 1 then break end
        direction = direction.Unit
        local nextPos = (dist < stepSize) and targetPos or (currentPos + direction * stepSize)

        -- Try pathfinding for this step, but if it fails, just nudge forward and jump if needed
        local path = PathfindingService:CreatePath({
            AgentRadius = 2,
            AgentHeight = 4,
            AgentCanJump = true,
            AgentJumpHeight = 16,
            AgentMaxSlope = 45,
        })
        path:ComputeAsync(currentPos, nextPos)
        if path.Status == Enum.PathStatus.Success then
            local waypoints = path:GetWaypoints()
            for _, waypoint in ipairs(waypoints) do
                if not goToShelbyEnabled then break end
                local reached = tryMoveTo(humanoid, waypoint.Position, 2.5)
                if not reached then
                    tryJump(humanoid)
                    fallbackNudge(humanoid, root, waypoint.Position, 8)
                end
            end
        else
            fallbackNudge(humanoid, root, nextPos, 10)
        end

        task.wait(0.1)
    end
end

Tabs.Main:Toggle({
    Title = "Go To Shelby (Get Closer and Closer)",
    Icon = "pointer",
    Default = false,
    Callback = function(state)
        goToShelbyEnabled = state
        if state then
            if goToShelbyThread then return end
            goToShelbyThread = task.spawn(function()
                local targetPos = Vector3.new(702, -4, -1772)
                while goToShelbyEnabled do
                    local character = LocalPlayer.Character
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    local root = getRootPart(character)
                    if not humanoid or not root then
                        task.wait(0.5)
                        continue
                    end

                    -- Try to home in on Shelby's live position if possible
                    local shelby = getShelby()
                    local shelbyRoot = getRootPart(shelby)
                    local destination = shelbyRoot and shelbyRoot.Position or targetPos

                    moveCloserAndCloser(humanoid, root, destination, 100, 8)
                    task.wait(0.3)
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








local running = false
local thread

Tabs.Main:Toggle({
    Title = "Auto Collect XP",
    Icon = "recycle",
    Default = false,
    Callback = function(state)
        running = state
        if running then
            thread = task.spawn(function()
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                local buffer = rawget(_G, "buffer") or getgenv().buffer
                if not buffer then
                    local bufferModule = ReplicatedStorage:FindFirstChild("buffer") or ReplicatedStorage:FindFirstChild("Buffer")
                    if bufferModule then
                        buffer = require(bufferModule)
                    else
                        return
                    end
                end
                local ByteNetReliable = ReplicatedStorage:WaitForChild("ByteNetReliable")
                while running do
                    local args = {
                        buffer.fromstring("\184\000\020\000\000")
                    }
                    ByteNetReliable:FireServer(unpack(args))
                    task.wait(1)
                end
            end)
        else
            if thread then
                task.cancel(thread)
                thread = nil
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
