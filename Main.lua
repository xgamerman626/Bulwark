--[[

.______    __    __   __      ____    __    ____  ___      .______       __  ___ 
|   _  \  |  |  |  | |  |     \   \  /  \  /   / /   \     |   _  \     |  |/  / 
|  |_)  | |  |  |  | |  |      \   \/    \/   / /  ^  \    |  |_)  |    |  '  /  
|   _  <  |  |  |  | |  |       \            / /  /_\  \   |      /     |    <   
|  |_)  | |  `--'  | |  `----.   \    /\    / /  _____  \  |  |\  \----.|  .  \  
|______/   \______/  |_______|    \__/  \__/ /__/     \__\ | _| `._____||__|\__\ 
                                                                                 

Features:

[+] Kill Aura:
    [-] Riposte/Parry Checker
    [-] Distance Value
    [-] Delay Value
    [-] Body Part Selection

[+] Hitbox Extender:
    [-] Body Part Selection
    [-] Custom Size

[+] Infinite Stamina

--]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Run = game:GetService("RunService")

-- Requires

-- Variables
local LPlayer = Players.LocalPlayer
local DelayHit = false

local ToServer = ReplicatedStorage.RemoteEvents.ToServer
local StanceRemote = ToServer.ChangeStance
local StaminaRemote = ToServer.Stamina
local HitRemote = ToServer.Hit

_G.Connections = {
    RS = nil,
}

_G.HitboxExtender = {
    Enabled = true,
    Type = "Head", -- This can be any R6 body part such as Head, Torso, Right Arm, Left Arm etc. 
    Size = 3, -- NOTE: I don't know if this can be any size or not so.
}

-- _G.AutoRiposte = {
--     Enabled = false,
--     MaxDistance = 5,
--     Delay = 0,
-- }

_G.InfiniteStamina = {
    Enabled = true,
}

_G.KillAura = {
    Enabled = true,
    RiposteCheck = true,
    MaxDistance = 8, -- I find this works best.
    Delay = .3, -- I also find this works best (I've barely tested anything under it) (they have anti remote spamming on server and will kick you if no delay.)
    BodyPart = "Torso" -- This can be any R6 body part such as Head, Torso, Right Arm, Left Arm etc.
}

-- _G.NoFlinch = {
--     Enabled = false
-- }

-- _G.NoSlow = {
--     Enabled = false
-- }

-- Local Functions
local function GetDistance(Position1: Vector3, Position2: Vector3): number

    return (Position1 - Position2).Magnitude

end

local function HasWeaponEquipped(): boolean

    return LPlayer.Character:FindFirstChildOfClass("Tool") ~= nil

end

local function CheckForParryRiposte(Character: Model): boolean

    local Tool = Character:FindFirstChildOfClass("Tool")

    if Tool then
        
        if Tool.Stance.Value == "Parrying" then return true end
        if Tool.Stance.Value == "Riposte" then return true end

    end

    return false

end

-- Main
if _G.Connections.RS ~= nil then -- If reexecuted then destroy previous connection.

    _G.Connections.RS:Disconnect()
    _G.Connections.RS = nil

end

_G.Connections.RS = Run.RenderStepped:Connect(function()

    local LCharacter = LPlayer.Character
    local LHumanoid = LCharacter and LCharacter:FindFirstChild("Humanoid")

    if LHumanoid and LHumanoid.Health <= 0 then return end

    local LRootPart = LCharacter:FindFirstChild("HumanoidRootPart")

    if LRootPart == nil or not LRootPart then return end

    local LRootPos = LRootPart.Position
    
    -- Hitbox Extender & Kill Aura & Auto Riposte.
    for _, Player in pairs(Players:GetPlayers()) do

        if Player == LPlayer then continue end

        local PCharacter = Player.Character
        local PTarget = PCharacter:FindFirstChild(_G.KillAura.BodyPart)

        if PTarget == nil or not PTarget then continue end
        
        if Player and PCharacter then -- Character exists.

            if _G.HitboxExtender.Enabled == true then
                
                local Size = _G.HitboxExtender.Size
    
                PCharacter[_G.HitboxExtender.Type].Size = Vector3.new(Size, Size, Size)

            end

            local Distance: number = GetDistance(LRootPos, PTarget.Position)

            if Distance < _G.KillAura.MaxDistance and Player:GetAttribute("PVP") == true and DelayHit == false and HasWeaponEquipped() then

                -- Riposte/Parry check if they have it enabled.
                if _G.KillAura.RiposteCheck then
                    if CheckForParryRiposte(PCharacter) == true then continue end
                end
            
                -- Set our killaura debounce to not trigger remote spam on server.
                DelayHit = true
                
                -- Reset the delay using settings.
                coroutine.wrap(function()

                    task.wait(_G.KillAura.Delay)
                    DelayHit = false

                end)()

                -- Before we fire the remote we must change our stance to windup then release.
                -- NOTE: You have to do windup first then release because the server most likely
                -- doesn't change the stance to release unless its on windup, not idle.
                StanceRemote:FireServer("Windup")
                StanceRemote:FireServer("Release")

                -- Fire the remote to server since everything checks out.
                HitRemote:FireServer(LCharacter:FindFirstChildOfClass("Tool"), PTarget, PCharacter.Humanoid)

            end

        end

    end

end)

-- Block stamina remote if infinite stamina is enabled.
local OldStaminaFireServer
OldStaminaFireServer = hookfunction(StaminaRemote.FireServer, newcclosure(function(Event, ...)

    if not checkcaller() then
    
        if _G.InfiniteStamina.Enabled == true then
            
            return nil

        else

            return OldStaminaFireServer(Event, ...)

        end

    end

end))