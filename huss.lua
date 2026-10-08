--// Huss Valley — Intouchable (skin intact, hitbox déplacée)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

local CONFIG = {
    godmode = true,
    offset_hrp = true,       -- décale la hitbox réelle
    no_collide = true,       -- les autres te traversent
    desync = false,
    offset_distance = 5000,  -- distance de l'offset (studs)
    offset_axis = "Y",       -- Y = au-dessus de toi
}

local originals = { hrp_cframe = nil }

local function get_char()
    return LP.Character or LP.CharacterAdded:Wait()
end

--// GODMODE — vie infinie
local function godmode(enable)
    local char = get_char()
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        if enable then
            hum.MaxHealth = math.huge
            hum.Health = math.huge
        else
            hum.MaxHealth = 100
            hum.Health = 100
        end
    end
end

--// NO COLLIDE — les autres te traversent (skin intact)
local function no_collide(enable)
    local char = get_char()
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.CanCollide = not enable
        end
    end
end

--// OFFSET HRP — déplace la hitbox réelle du serveur, garde ton skin visible
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

--// DESYNC
local function desync(enable)
    if not CONFIG.desync then return end
    pcall(function()
        local char = get_char()
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then sethiddenproperty(hrp, "NetworkIsSleeping", enable) end
    end)
end

--// HOOK DEGATS
local old_namecall
old_namecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" and typeof(self) == "Instance" and self.Name == "Damage" then
        return
    end
    return old_namecall(self, ...)
end))

--// APPLY / RESET
local function apply()
    godmode(CONFIG.godmode)
    no_collide(CONFIG.no_collide)
    offset_hrp(CONFIG.offset_hrp)
    desync(CONFIG.desync)
end

local function reset()
    godmode(false)
    no_collide(false)
    offset_hrp(false)
    desync(false)
end

--// UI PANEL
local gui = Instance.new("ScreenGui")
gui.Name = "K_Panel"
gui.ResetOnSpawn = false
gui.Parent = LP:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 220, 0, 300)
main.Position = UDim2.new(0, 20, 0.5, -150)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
title.Text = "[K] Huss Valley"
title.TextColor3 = Color3.fromRGB(120, 200, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.BorderSizePixel = 0
title.Parent = main

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = title

local function makeToggle(name, y, key)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = CONFIG[key] and Color3.fromRGB(40, 120, 60) or Color3.fromRGB(50, 50, 60)
    btn.Text = name .. ": " .. (CONFIG[key] and "ON" or "OFF")
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.Parent = main

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    btn.MouseButton1Click:Connect(function()
        CONFIG[key] = not CONFIG[key]
        btn.BackgroundColor3 = CONFIG[key] and Color3.fromRGB(40, 120, 60) or Color3.fromRGB(50, 50, 60)
        btn.Text = name .. ": " .. (CONFIG[key] and "ON" or "OFF")
        apply()
    end)
end

makeToggle("Godmode", 45, "godmode")
makeToggle("No Collide", 85, "no_collide")
makeToggle("Offset HRP", 125, "offset_hrp")
makeToggle("Desync", 165, "desync")

local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(1, -20, 0, 35)
resetBtn.Position = UDim2.new(0, 10, 0, 210)
resetBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
resetBtn.Text = "RESET"
resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
resetBtn.Font = Enum.Font.GothamBold
resetBtn.TextSize = 13
resetBtn.BorderSizePixel = 0
resetBtn.Parent = main

local rc = Instance.new("UICorner")
rc.CornerRadius = UDim.new(0, 6)
rc.Parent = resetBtn

resetBtn.MouseButton1Click:Connect(function()
    reset()
    gui:Destroy()
end)

--// AUTO-APPLY
LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    apply()
end)

--// LOOP — maintien godmode et offset si le jeu les reset
RunService.Heartbeat:Connect(function()
    if CONFIG.godmode then
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = hum.MaxHealth end
    end
end)

task.wait(1)
apply()

print("[K] Huss Valley — Panel chargé (skin intact)")
