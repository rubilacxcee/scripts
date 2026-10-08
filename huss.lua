--// Huss Valley — Intouchable (Xeno/Delta)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

local CONFIG = {
    shrink_hitbox = true,
    offset_hrp = true,
    desync = false,
    shrink_size = 0.01,
    offset_distance = 5000,
    offset_axis = "Y",
}

local originals = { size = {}, hrp_cframe = nil }

local function get_char()
    return LP.Character or LP.CharacterAdded:Wait()
end

local function shrink_hitbox(enable)
    local char = get_char()
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            if enable then
                if not originals.size[part] then
                    originals.size[part] = part.Size
                end
                part.Size = Vector3.new(CONFIG.shrink_size, CONFIG.shrink_size, CONFIG.shrink_size)
                part.CanCollide = false
                part.Massless = true
            else
                if originals.size[part] then
                    part.Size = originals.size[part]
                end
            end
        end
    end
end

local function offset_hrp(enable)
    local char = get_char()
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if enable then
        originals.hrp_cframe = originals.hrp_cframe or hrp.CFrame
        local vec = Vector3.zero
        if CONFIG.offset_axis == "Y" then vec = Vector3.new(0, CONFIG.offset_distance, 0)
        elseif CONFIG.offset_axis == "X" then vec = Vector3.new(CONFIG.offset_distance, 0, 0)
        else vec = Vector3.new(0, 0, CONFIG.offset_distance) end
        hrp.CFrame = originals.hrp_cframe + vec
    else
        if originals.hrp_cframe then hrp.CFrame = originals.hrp_cframe end
    end
end

local function desync(enable)
    if not CONFIG.desync then return end
    pcall(function()
        local char = get_char()
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then sethiddenproperty(hrp, "NetworkIsSleeping", enable) end
    end)
end

-- Hook via hookmetamethod (plus stable que getrawmetatable)
local old_namecall
old_namecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" and typeof(self) == "Instance" and self.Name == "Damage" then
        return
    end
    return old_namecall(self, ...)
end))

local function apply()
    shrink_hitbox(CONFIG.shrink_hitbox)
    offset_hrp(CONFIG.offset_hrp)
    desync(CONFIG.desync)
end

LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    apply()
end)

RunService.Heartbeat:Connect(function()
    if CONFIG.shrink_hitbox then
        local char = LP.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        if part.Size.X > CONFIG.shrink_size * 2 then
                            part.Size = Vector3.new(CONFIG.shrink_size, CONFIG.shrink_size, CONFIG.shrink_size)
                        end
                    end
                end
            end
        end
    end
end)

task.wait(1)
apply()

print("[K] Huss Valley — Intouchable activé (Xeno/Delta)")
