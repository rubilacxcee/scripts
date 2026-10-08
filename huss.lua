--// Huss Valley — Intouchable
--// Méthode : hitbox shrink + HRP offset + desync léger

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

local CONFIG = {
    shrink_hitbox = true,
    offset_hrp = true,
    desync = false,
    shrink_size = 0.01,        -- taille de la hitbox (0.01 = quasi invisible)
    offset_distance = 5000,    -- distance de l'offset HRP
    offset_axis = "Y",         -- Y = vers le haut, X/Z = latéral
}

--// Sauvegarde des valeurs originales
local originals = {
    size = nil,
    hrp_cframe = nil,
    connections = {},
}

--// Récupère le personnage
local function get_char()
    return LP.Character or LP.CharacterAdded:Wait()
end

--// 1. RÉTRÉCIR LA HITBOX
local function shrink_hitbox(enable)
    local char = get_char()
    if not char then return end

    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            if enable then
                if not originals.size then
                    originals.size = originals.size or {}
                    originals.size[part] = part.Size
                end
                part.Size = Vector3.new(
                    CONFIG.shrink_size,
                    CONFIG.shrink_size,
                    CONFIG.shrink_size
                )
                part.CanCollide = false
                part.Massless = true
            else
                if originals.size and originals.size[part] then
                    part.Size = originals.size[part]
                end
            end
        end
    end
end

--// 2. DÉCALER LE HRP (hitbox réelle loin de toi)
local function offset_hrp(enable)
    local char = get_char()
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if enable then
        originals.hrp_cframe = originals.hrp_cframe or hrp.CFrame
        local offset = Vector3.zero
        if CONFIG.offset_axis == "Y" then
            offset = Vector3.new(0, CONFIG.offset_distance, 0)
        elseif CONFIG.offset_axis == "X" then
            offset = Vector3.new(CONFIG.offset_distance, 0, 0)
        else
            offset = Vector3.new(0, 0, CONFIG.offset_distance)
        end
        hrp.CFrame = originals.hrp_cframe + offset
    else
        if originals.hrp_cframe then
            hrp.CFrame = originals.hrp_cframe
        end
    end
end

--// 3. DESYNC LÉGER (optionnel)
local function desync(enable)
    if not CONFIG.desync then return end
    pcall(function()
        local char = get_char()
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            sethiddenproperty(hrp, "NetworkIsSleeping", enable)
        end
    end)
end

--// 4. HOOK DES DÉGÂTS
local function hook_damage()
    local mt = getrawmetatable(game)
    local old = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        -- Bloque les dégâts entrants
        if method == "FireServer" and self.Name == "Damage" then
            return
        end
        if method == "TakeDamage" or method == "ApplyDamage" then
            return
        end

        return old(self, ...)
    end)
    setreadonly(mt, true)
end

--// APPLIQUER
local function apply()
    shrink_hitbox(CONFIG.shrink_hitbox)
    offset_hrp(CONFIG.offset_hrp)
    desync(CONFIG.desync)
end

--// RESET
local function reset()
    shrink_hitbox(false)
    offset_hrp(false)
    desync(false)
end

--// AUTO-APPLY
LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    apply()
end)

--// LOOP (maintient la hitbox shrink si le jeu la reset)
RunService.Heartbeat:Connect(function()
    if CONFIG.shrink_hitbox then
        local char = LP.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                -- check rapide si une part a été reset
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        if part.Size.X > CONFIG.shrink_size * 2 then
                            part.Size = Vector3.new(
                                CONFIG.shrink_size,
                                CONFIG.shrink_size,
                                CONFIG.shrink_size
                            )
                        end
                    end
                end
            end
        end
    end
end)

--// HOOK
hook_damage()

--// APPLY INITIAL
task.wait(1)
apply()

print("[K] Huss Valley — Intouchable activé")
print("[K] hitbox shrink: " .. tostring(CONFIG.shrink_hitbox))
print("[K] offset HRP: " .. tostring(CONFIG.offset_hrp))
print("[K] desync: " .. tostring(CONFIG.desync))
