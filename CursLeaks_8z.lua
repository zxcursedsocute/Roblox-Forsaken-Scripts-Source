local xpcallSuccess, xpcallErr = xpcall(function()

-- Discord Server & Key Configuration
local DISCORD_URL = "https://discord.gg/4cy7tpTHND"
local CORRECT_KEY = "hrp.CFrametarget.CFramepart.Namehrp.CFramehrp.CFrametarget.CFramepart.Name"
local KEY_FILE = "forsaken_plus_key.txt"

-- Auto Copy Discord Link to Clipboard on Execute
if setclipboard then
    pcall(function() setclipboard(DISCORD_URL) end)
end

-- Safe CoreGui Container
local gethui = gethui or function() return game:GetService("CoreGui") end
local safeContainer
pcall(function() safeContainer = gethui() end)
if not safeContainer then safeContainer = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end

-- Cleanup previous instances & create loading screen indicator on top right
local loadingGui, loadingLabel
pcall(function()
    if safeContainer:FindFirstChild("plus") then safeContainer.plus:Destroy() end
    local flag = Instance.new("BoolValue")
    flag.Name = "plus"
    flag.Parent = safeContainer

    loadingGui = Instance.new("ScreenGui")
    loadingGui.Name = "ForsakenLoadingScreen"
    loadingGui.ResetOnSpawn = false
    loadingGui.Parent = safeContainer

    loadingLabel = Instance.new("TextLabel")
    loadingLabel.Name = "LoadingText"
    loadingLabel.Size = UDim2.new(0, 140, 0, 35)
    loadingLabel.Position = UDim2.new(1, -150, 0, 15)
    loadingLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    loadingLabel.BackgroundTransparency = 0.3
    loadingLabel.TextColor3 = Color3.fromRGB(255, 180, 220)
    loadingLabel.TextStrokeTransparency = 0.5
    loadingLabel.TextSize = 16
    loadingLabel.Font = Enum.Font.GothamBold
    loadingLabel.Text = "loading.."
    loadingLabel.Parent = loadingGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = loadingLabel
end)

-- UI Library Loader
local windui
local success, err = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)

if success and type(err) == "table" then
    windui = err
else
    local fallbackSuccess, fallbackErr = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Orionservice-hub/Windui-boreal/refs/heads/main/WindUI%20boreal"))()
    end)
    if fallbackSuccess and type(fallbackErr) == "table" then
        windui = fallbackErr
    end
end

if not windui then
    warn("🐾 Catboy Error: Could not load WindUI library!")
    if loadingGui then pcall(function() loadingGui:Destroy() end) end
    return
end

-- Executor Compatibility Checks (runs first, right after WindUI loads so it can notify)
do
    local function getGlobal(name)
        if type(getgenv) == "function" then
            local success, env = pcall(getgenv)
            if success and type(env) == "table" and env[name] ~= nil then
                return env[name]
            end
        end
        return _G[name]
    end

    local failedChecks = {}
    local function check(name, callback)
        local success, result = pcall(callback)
        if not (success and result) then
            table.insert(failedChecks, name)
        end
    end

    local checks = {
        "setclipboard", "gethui", "isfile", "readfile", "writefile", "loadstring",
        "firesignal", "getconnections", "fireclickdetector", "fireproximityprompt",
        "hookmetamethod", "getrawmetatable", "setreadonly", "newcclosure",
        "getnamecallmethod", "hookfunction", "getgenv"
    }
    for _, name in ipairs(checks) do
        check(name, function()
            return type(getGlobal(name)) == "function"
        end)
    end

    check("HttpGet", function()
        return type(game.HttpGet) == "function" or type(game.HttpGetAsync) == "function"
    end)

    check("continue", function()
        assert(type(loadstring) == "function")
        local fn = loadstring([[
            local n = 0
            for i = 1, 3 do
                if i == 2 then
                    continue
                end
                n += 1
            end
            return n == 2
        ]])
        assert(type(fn) == "function")
        return fn()
    end)

    check("buffer", function()
        return type(buffer) == "table"
    end)

    check("buffer.fromstring", function()
        return type(buffer) == "table" and type(buffer.fromstring) == "function"
    end)

    if #failedChecks > 0 then
        pcall(function()
            windui:Notify({
                Title = "unsupported functions",
                Content = "your executor doesnt support: " .. table.concat(failedChecks, ", ") .. ". some features will break",
                Duration = 3
            })
        end)
    end
end

-- Key Storage Helper Functions
local function IsKeySaved()
    if isfile and isfile(KEY_FILE) then
        local successRead, content = pcall(function() return readfile(KEY_FILE) end)
        if successRead and content == CORRECT_KEY then
            return true
        end
    end
    return false
end

local function SaveKey(key)
    if writefile then
        pcall(function() writefile(KEY_FILE, key) end)
    end
end

-- Main Script Loader Function
local function LoadMainScript()

    -- Core Services
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Lighting = game:GetService("Lighting")
    local UIS = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local LP = Players.LocalPlayer

    -- Wait patiently for character and game to fully load first so features never fail!
    if not LP.Character then
        LP.CharacterAdded:Wait()
    end

    -- Lifecycle Trackers
    local Connections = {}
    local ScriptRunning = true

    local function TrackConnection(conn)
        if conn then table.insert(Connections, conn) end
        return conn
    end

    -- Direct Remote Event Fetcher
    local function GetRemoteEvent()
        local modules = ReplicatedStorage:FindFirstChild("Modules")
        local net = modules and modules:FindFirstChild("Network")
        local netSub = net and net:FindFirstChild("Network")
        return netSub and netSub:FindFirstChild("RemoteEvent")
    end

    -- Cooldown Checker Helper Function
    local function IsAbilityOnCooldown(abilityName)
        local pg = LP:FindFirstChild("PlayerGui")
        local mUI = pg and pg:FindFirstChild("MainUI")
        local ac = mUI and mUI:FindFirstChild("AbilityContainer")
        local ab = ac and ac:FindFirstChild(abilityName)
        local cd = ab and ab:FindFirstChild("CooldownTime")
        if cd and cd:IsA("TextLabel") then
            return cd.Text ~= "" and cd.Text:match("^%s*$") == nil
        end
        return false
    end

    -- Anti-AFK
    TrackConnection(LP.Idled:Connect(function() 
        pcall(function() game:GetService("VirtualUser"):ClickButton2(Vector2.new()) end)
    end))

    -- Roman Numerals Converter Helper
    local romanMap = {
        I = 1, II = 2, III = 3, IV = 4, V = 5,
        VI = 6, VII = 7, VIII = 8, IX = 9, X = 10,
        XI = 11, XII = 12, XIII = 13, XIV = 14, XV = 15,
        XVI = 16, XVII = 17, XVIII = 18, XIX = 19, XX = 20
    }
    local function RomanToNumber(str)
        if not str then return 0 end
        str = str:gsub("%s+", ""):upper()
        return romanMap[str] or 0
    end

    -- String & Time Helpers
    local function CleanDisplayName(str)
        if not str then return "" end
        if str == "TwoTime" or str:find("TwoTime") then return "Two Time" end
        if str == "BloxyCola" or str == "Bloxy Cola" then return "Bloxy Cola" end
        if str == "JohnDoe" or str:find("JohnDoe") then return "John Doe" end
        if str == "Medkit" or str:find("MedKit") then return "Medkit" end
        return str:gsub("(%l)(%u)", "%1 %2")
    end

    local function FormatPlaytime(sec)
        sec = math.floor(tonumber(sec) or 0)
        local days = math.floor(sec / 86400)
        local hours = math.floor((sec % 86400) / 3600)
        local mins = math.floor((sec % 3600) / 60)
        local secs = sec % 60
        
        local parts = {}
        if days > 0 then table.insert(parts, days .. (days == 1 and " day" or " days")) end
        if hours > 0 then table.insert(parts, hours .. (hours == 1 and " hour" or " hours")) end
        if mins > 0 then table.insert(parts, mins .. (mins == 1 and " minute" or " minutes")) end
        if secs > 0 or #parts == 0 then table.insert(parts, secs .. (secs == 1 and " second" or " seconds")) end
        return table.concat(parts, ", ")
    end

    -- Full Script State
    local State = {
        -- Legit Bloodhook Escape
        EnableBloodhook = false,
        BloodhookTargetTime = 2.0,

        -- Dusekkar Section States
        DusekkarSurvivorAim = false,
        DusekkarKillerAim = false,

        -- Generator & Automation
        AutoGenerator = false,
        GeneratorCooldown = 1,
        AutoGiveOrangeFood = false,
        AutoGenNew = false,
        AutoGenDuration = 3,
        -- Helperbot
        AutoUseInspiration = false,
        AutoPulseLowHealth = false,
        PulseHealthThreshold = 50,
        PulseCrasher = false,
        -- Auto Block
        AutoBlock = false,
        AutoBlockRange = 9.5,
        AutoBlockNoDash = false,
        NoobVisible = false,
        AutoPunch = false,
        AutoPunchDelay = 0.5,
        PrivateItemEsp = false,
        PrivateItemNameEsp = false,
        AutoGhostburgerLMS = false,
        RemoveC00lguiAnim = false,
        NoC00lguiSlow = false,
        AutoCloneLMS = false,
        AutoC00lguiLMS = false,
        Auto007Block = false,
        CloneBlockRange = 9.5,
        DeviceSpoof = nil,
        HitboxPusher = false,
        HitboxExpander = false,
        AutoFarm = false,
        AutoFarmHop = true,
        AutoFarmCandies = false,
        AutoFarmAvoidKiller = false,
        AutoUseAbilities = false,
        Invisibility = false,
        EspCandies = false,
        CandyNameESP = false,
        AimPunch = false,
        -- Stamina & Speed
        EnableCustomSpeed = false,
        SprintSpeedValue = 21.6,
        InfiniteStamina = false,
        MinStaminaValue = 0,
        MaxStaminaValue = 100,
        DrainStaminaValue = 10,
        -- Features
        AntiSlowness = false,
        EnableJumping = false,
        RemoveSpikes = false,
        DisableKillerWalls = false,
        DisableToxicTrails = false,
        NoFog = false,
        FullBright = false,
        SilentFootsteps = false,
        MapBoundsBypass = false,
        RemoveKillerDoors = false,
        InstantGenPrompt = false,
        AutoNotifyKillerESP = false,
        HidePlayerIconAndName = false,
        LessLagHitboxes = false,
        -- Effects Tab States
        AntiSubspaceEffects = false,
        AntiExhausted = false,
        AntiNausea = false,
        AntiOblivious = false,
        AntiVignette = false,
        AntiSlateskin = false,
        NoGlitchCorrupted = false,
        AntiBlindness = false,
        AntiConfusion = false,
        AntiStun = false,
        AntiUndetectable = false,
        RemoveInsaneVignette = false,
        AntiGlitchedNew = false,
        AntiGlitchedOld = false,
        AntiHandSlowdown = false,
        -- Survivors Tab States
        AutoTrick = false,
        Sk8Anywhere = false,
        NotifyC00lgui = false,
        Make007n7Visible = false,
        LoopDelete007n7Clones = false,
        AutoGetPizzas = false,
        EspElliotPizza = false,
        TwoTimeAutoBackstab = false,
        TwoTimeBackstabRange = 14,
        AntiBaitBlock = false,
        -- Chance Section
        AutoCoinflip = false,
        AutoReroll = false,
        TurnOnAutoHatFix = false,
        AutoHatFixNumber = 5,
        -- Elliot Section
        EnableAutoRushHour = false,
        AutoRushHourRange = 25,
        EspInjuredPlayers = false,
        -- Items
        ItemESP = false,
        CompileCoords = "",
        BlacklistItems = {},
        -- Visual Highlights
        KillerESP = false,
        SurvivorESP = false,
        GeneratorESP = false,
        FakeGeneratorESP = false,
        RitualESP = false,
        CoolkiddMinionESP = false,
        OneByOneMinionESP = false,
        AzureBulbESP = false,
        AzureVineESP = false,
        TaphTripwireESP = false,
        SubspaceTripmineESP = false,
        VeeronicaGraffitiESP = false,
        EspBuildermanSentries = false,
        EspBuildermanDispensers = false,
        Esp007n7Clones = false,
        EspJohnDoesDF = false,
        EspElliotPizza = false,
        Esp1x1Swords = false,
        Esp1x1Shockwave = false,
        EspFakeNoli = false,
        EspGears = false,
        GearNameESP = false,
        SelectedColor = Color3.fromRGB(255, 180, 220),
        -- ESP Names
        KillerNameESP = false,
        SurvivorNameESP = false,
        GenNameESP = false,
        ItemNameESP = false,
        RitualNameESP = false,
        MinionNameESP = false,
        AzureBulbNameESP = false,
        AzureVineNameESP = false,
        TripwireNameESP = false,
        SubspaceNameESP = false,
        VeeronicaGraffitiNameESP = false,
        SentriesNameESP = false,
        DispensersNameESP = false,
        Fake007n7NameESP = false,
        JohnDoesDFNameESP = false,
        FakeNoliNameESP = false,
        -- Killers Tab
        EspAzuresPlantState = false,
        SurvivorAtropaOblation = false,
        SixerPursuitFreeMove = false,
        SixerPursuitSpeed = 78,
        NosferatuOriginalVisible = false,
        NosferatuFlyNotify = false,
        AutoDisarmVines = false,
        AzureAutoHit = false,
        AzureHitRange = 7.1,
        AzureAutoGrab = false,
        AzureGrabRange = 26,
        -- Nosferatu New States
        NosAutoLacerate = false,
        NosLacerateRange = 7.5,
        NosAutoBloodhook = false,
        NosBloodhookRange = 50,
        NosAutoHuntersFeast = false,
        NosHuntersFeastRange = 26.5,
        -- Sixer New States
        SixerCarvingSlash = false,
        SixerCarvingRange = 7.1,
        SixerPursuitAimbot = false,
        SixerInfernalCryAuto = false,
        SixerInfernalCryAim = false,
        -- Noli States
        VoidRushController = false,
        AntiNoliClones = false,
        NoliAutoStab = false,
        NoliStabRange = 6.2,
        NoliAutoNova = false,
        NoliNovaRange = 26.5,
        AntiNovaExplosion = false,
        StopVoidRush = false,
        LagServerNova = false,
        NotifyNoliNova = false,
        AntiGuestBlockBait = false,
        NoliBaitDistance = 20,
        -- c00lkidd & Slasher Aimbots
        KillerAimbot = false,
        CorruptNatureAimbot = false,
        WalkspeedOverrideAimbot = false,
        TagAutoHit = false,
        TagHitDistance = 7.1,
        AutoSlashSlasher = false,
        SlasherLockDuration = 0.2,
        AutoBehead = false,
        AutoRagingPace = false,
        RagingPaceStaminaThreshold = 35,
        CorruptEnergyCamLock = false,
        AutoSlashAimLock = false,
        EntanglementCamLock = false,
        MassInfectionCamLock = false,
        -- New features
        FruitNameESP = false,
        EspFruits = false,
        DusekkarProtectWalls = false,
        Guest1337ChargeAim = false,
        ChanceGunAim = false,
        JaneHatchetTP = false,
        JaneHatchetTPBehind = 2.5,
        JaneCrystalSurvivor = false,
        JaneCrystalKiller = false,
        JaneHatchetAim = false,
        JaneHatchetAimDistance = 30,
        ShedSwordTP = false,
        ShedAutoSlash = false,
        ShedSlashRange = 19,

        -- Extras (antis / misc)
        AntiFallSlowness = false,
        DisableDirectionalSpeed = false,
        DisableDirectionalMovement = false,
        AntiPull = false,
        WalkablePuddles = false,
        AntiBleeding = false,
        AntiHallucination = false,
        AntiHacked = false,
        AntiCorrupted = false,
        AntiSubspaced = false,
        AutoCloseEndScreen = false,
        DisableAFKInsanity = false,
        SidebarVisible = false,
        CustomFOVMultiplier = 1,
        AntiFootsteps = false,
        Noclip = false,
        FakeClone = false,
    }

    -- Optimized Event-Driven Map & Dynamic Object Cache with safe waiting
    local MapCache = {
        Spikes = {},
        KillerWalls = {},
        ToxicTrails = {},
        SpecialESP = {},
        JohnDoeDF = {},
        Clones007 = {},
        Pizzas = {},
        Swords1x1 = {},
        Shockwaves1x1 = {}
    }

    local function RegisterMapItem(v)
        if not v or not v.Parent then return end
        local lowerName = v.Name:lower()

        if lowerName:find("spike") then
            table.insert(MapCache.Spikes, v)
            if State.RemoveSpikes then pcall(function() v:Destroy() end) end
        elseif lowerName:find("killerwall") or lowerName:find("invisiblewall") then
            table.insert(MapCache.KillerWalls, v)
            if State.DisableKillerWalls and v:IsA("BasePart") then v.CanCollide = false end
        elseif lowerName:find("toxic") or lowerName:find("puddle") or lowerName:find("trail") then
            table.insert(MapCache.ToxicTrails, v)
            if State.DisableToxicTrails then pcall(function() v:Destroy() end) end
        end

        if v.Name == "GroundBulbModel" or v.Name == "VineModel" or lowerName:find("taphtripwire") 
           or v.Name == "SubspaceTripmine" or lowerName:find("grafitti") 
           or v.Name == "PizzaDeliveryRig" or v.Name == "Zombie" 
           or lowerName:find("respawnlocation") or lowerName:find("ritual") then
            table.insert(MapCache.SpecialESP, v)
        end

        if lowerName:find("shadow") then
            table.insert(MapCache.JohnDoeDF, v)
        end

        if v.Name == "007n7" then
            table.insert(MapCache.Clones007, v)
        end

        if v.Name == "Pizza" then
            table.insert(MapCache.Pizzas, v)
        end

        if v.Name == "Swords" then
            table.insert(MapCache.Swords1x1, v)
        end

        if v.Name == "shockwave" then
            table.insert(MapCache.Shockwaves1x1, v)
        end
    end

    local function ScanAndSetupMap()
        MapCache = { Spikes = {}, KillerWalls = {}, ToxicTrails = {}, SpecialESP = {}, JohnDoeDF = {}, Clones007 = {}, Pizzas = {}, Swords1x1 = {}, Shockwaves1x1 = {} }
        local mapFolder = Workspace:WaitForChild("Map", 15)
        local ingame = mapFolder and mapFolder:WaitForChild("Ingame", 15)
        if ingame then
            for _, v in ipairs(ingame:GetDescendants()) do
                RegisterMapItem(v)
            end
            TrackConnection(ingame.DescendantAdded:Connect(RegisterMapItem))
        end
    end

    ScanAndSetupMap()

    TrackConnection(Workspace.ChildAdded:Connect(function(child)
        if child.Name == "Map" then
            task.wait(1)
            ScanAndSetupMap()
        end
    end))

    -- Legit Bloodhook QTE Solver
    local function triggerButton(element)
        if typeof(firesignal) == "function" then
            pcall(function() firesignal(element.Activated) end)
            pcall(function() firesignal(element.MouseButton1Click) end)
        elseif typeof(getconnections) == "function" then
            for _, connection in ipairs(getconnections(element.Activated)) do
                pcall(function() connection:Fire() end)
            end
            for _, connection in ipairs(getconnections(element.MouseButton1Click)) do
                pcall(function() connection:Fire() end)
            end
        end
    end

    local function solveLegitQTE(qteContainer)
        task.spawn(function()
            local activeButtons = {}
            for _, element in ipairs(qteContainer:GetDescendants()) do
                if element:IsA("GuiButton") and element.Visible then
                    table.insert(activeButtons, element)
                end
            end

            local totalPrompts = #activeButtons
            if totalPrompts == 0 then return end

            local targetTime = State.BloodhookTargetTime or 2.0
            local delayPerStep = targetTime / totalPrompts

            for _, btn in ipairs(activeButtons) do
                local jitter = math.random(-80, 80) / 1000
                local waitTime = math.max(0.1, delayPerStep + jitter)

                task.wait(waitTime)

                if btn and btn.Parent and btn.Visible then
                    triggerButton(btn)
                end
            end
        end)
    end

    TrackConnection(LP:WaitForChild("PlayerGui", 10).ChildAdded:Connect(function(child)
        if not State.EnableBloodhook then return end
        local name = child.Name:lower()
        if name:find("bloodhook") or name:find("qte") then
            solveLegitQTE(child)
        end
    end))

    -- Neuter Exhausted Module Hook
    task.spawn(function()
        pcall(function()
            local modules = ReplicatedStorage:WaitForChild("Modules", 10)
            local schematics = modules:WaitForChild("Schematics", 10)
            local statusEffects = schematics:WaitForChild("StatusEffects", 10)
            local Exhausted = require(statusEffects:WaitForChild("Exhausted", 10))
            
            local origApp = Exhausted.Applied
            local origRem = Exhausted.Removed
            
            Exhausted.Applied = function(p1)
                if State.AntiExhausted then return end
                if origApp then origApp(p1) end
            end
            
            Exhausted.Removed = function(p2)
                if State.AntiExhausted then return end
                if origRem then origRem(p2) end
            end
        end)
    end)

    local function IsGeneratorFinished(gen)
        if not gen or not gen:IsA("Model") then return true end
        local main = gen:FindFirstChild("Main")
        if main and main:FindFirstChild("generatorActivate") then return true end
        local progress = gen:FindFirstChild("Progress")
        if progress and progress.Value >= 100 then return true end
        return false
    end

    -- Highlight & Billboard Renderers
    local function IsRagdoll(model)
        local ragdolls = Workspace:FindFirstChild("Ragdolls")
        return ragdolls and (model:IsDescendantOf(ragdolls) or model.Parent == ragdolls)
    end

    local function CreateHighlight(model, color, name)
        if not model or model:FindFirstChild(name) or IsRagdoll(model) then return end
        pcall(function()
            local highlight = Instance.new("Highlight")
            highlight.Name = name
            highlight.Adornee = model
            highlight.FillColor = color
            highlight.OutlineColor = color
            highlight.FillTransparency = 0.7
            highlight.OutlineTransparency = 0.3
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = model
        end)
    end

    local function RemoveHighlight(model, name)
        if not model then return end
        pcall(function()
            local h = model:FindFirstChild(name)
            if h then h:Destroy() end
        end)
    end

    local function CreateBillboardText(model, text, name, customColor)
        if not model or model:FindFirstChild(name) then return end
        local primaryPart = model:IsA("Model") and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")) or model
        if not primaryPart or not primaryPart:IsA("BasePart") then return end
        
        pcall(function()
            local bgui = Instance.new("BillboardGui")
            bgui.Name = name
            bgui.Adornee = primaryPart
            bgui.Size = UDim2.new(0, 150, 0, 30)
            bgui.StudsOffset = Vector3.new(0, 2.5, 0)
            bgui.AlwaysOnTop = true
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = customColor or Color3.fromRGB(255, 255, 255)
            label.TextStrokeTransparency = 0
            label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            label.TextSize = 14
            label.Font = Enum.Font.Gotham
            label.Text = CleanDisplayName(text)
            label.Parent = bgui
            bgui.Parent = model
        end)
    end

    local function RemoveBillboardText(model, name)
        if not model then return end
        pcall(function()
            local b = model:FindFirstChild(name)
            if b then b:Destroy() end
        end)
    end

    -- Shared auto-aim helper (november 7th, 2026): movement-aware lead + frame-rate independent smoothing.
    -- Every camera auto aim in this script goes through this so they all track the same, much better.
    local AimUtil = {}
    do
        local velocityCache = setmetatable({}, { __mode = "k" })

        -- one-way network latency in seconds (falls back to a sane default)
        function AimUtil.Ping()
            local ok, ping = pcall(function() return LP:GetNetworkPing() end)
            if ok and type(ping) == "number" and ping == ping then return math.clamp(ping, 0, 0.3) end
            return 0.05
        end

        -- smoothed velocity: removes one-frame spikes (dashes, teleports) that make aim jitter
        function AimUtil.Velocity(part)
            local raw = part.AssemblyLinearVelocity
            local now = os.clock()
            local entry = velocityCache[part]
            if not entry then
                velocityCache[part] = { v = raw, t = now }
                return raw
            end
            local dt = now - entry.t
            if dt <= 0.0005 then return entry.v end
            if raw.Magnitude > 140 then return entry.v end
            entry.v = entry.v:Lerp(raw, 1 - math.exp(-dt * 20))
            entry.t = now
            return entry.v
        end

        -- where the target will be when the hit/projectile lands: position + velocity * (lead + latency)
        function AimUtil.Point(part, lead, maxLead)
            if not part then return Vector3.zero end
            if not part.Parent then return part.Position end
            local vel = AimUtil.Velocity(part)
            vel = Vector3.new(vel.X, math.clamp(vel.Y, -10, 10) * 0.4, vel.Z)
            local offset = vel * ((lead or 0.06) + AimUtil.Ping() * 0.5)
            local cap = maxLead or 6
            if offset.Magnitude > cap then offset = offset.Unit * cap end
            return part.Position + offset
        end

        -- frame-rate independent smoothing; `strength` keeps the old 0..1 meaning but is tighter than before
        function AimUtil.Smooth(current, desired, dt, strength)
            local s = math.clamp((strength or 0.35) * 1.8 + 0.2, 0.3, 0.97)
            local frames = math.clamp((dt or (1 / 60)) * 60, 0.25, 4)
            return current:Lerp(desired, 1 - math.pow(1 - s, frames))
        end
    end

    local function AimLockToKiller()
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local kFolder = Workspace:FindFirstChild("Players") and Workspace.Players:FindFirstChild("Killers")
        if hrp and kFolder then
            for _, k in ipairs(kFolder:GetChildren()) do
                local kHRP = k:FindFirstChild("HumanoidRootPart")
                if kHRP and (kHRP.Position - hrp.Position).Magnitude < 100 then
                    hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(kHRP.Position.X, kHRP.Position.Y, kHRP.Position.Z))
                    local aimCam = Workspace.CurrentCamera
                    if aimCam then aimCam.CFrame = CFrame.lookAt(aimCam.CFrame.Position, AimUtil.Point(kHRP, 0.04, 4)) end
                    break
                end
            end
        end
    end

    -- Single Execution Item Teleport Helper
    local function SingleTeleportAndClick(itemName)
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local ingame = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Ingame")
        local mainMap = ingame and ingame:FindFirstChild("Map")
        
        if hrp and mainMap then
            for _, obj in ipairs(mainMap:GetChildren()) do
                if obj.Name:lower():find(itemName:lower()) then
                    local targetPart = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or (obj:IsA("BasePart") and obj)
                    if targetPart then
                        local origCFrame = hrp.CFrame
                        hrp.CFrame = targetPart.CFrame
                        
                        local cd = obj:FindFirstChildWhichIsA("ClickDetector", true) or obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if cd then
                            if cd:IsA("ClickDetector") then 
                                pcall(function() fireclickdetector(cd) end)
                            elseif cd:IsA("ProximityPrompt") and fireproximityprompt then 
                                pcall(function() fireproximityprompt(cd) end)
                            end
                        end
                        
                        task.wait(0.15)
                        if hrp then hrp.CFrame = origCFrame end
                        return true
                    end
                end
            end
        end
        return false
    end

    -- World Hazards, Lighting, Movement
    local function ApplyNoFog()
        Lighting.FogStart = 0
        Lighting.FogEnd = 1000000
        local Atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
        if Atmosphere then
            Atmosphere.Density = 0
            Atmosphere.Haze = 0
            Atmosphere.Glare = 0
        end
    end

    local function ApplyFullBright()
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1000000
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    end

    -- Lighting Listener for Subspace
    TrackConnection(Lighting.ChildAdded:Connect(function(v)
        if State.AntiSubspaceEffects then
            if v.Name == "SubspaceVFXBlur" or v.Name == "SubspaceVFXColorCorrection" or v.Name == "BlindnessBlur" then
                task.wait()
                v:Destroy()
            end
        end
    end))

    -- Chance Abilities Loop
    task.spawn(function()
        while ScriptRunning do
            task.wait(0.1)
            pcall(function()
                local remote = GetRemoteEvent()
                if remote then
                    if State.AutoCoinflip and not IsAbilityOnCooldown("CoinFlip") then
                        remote:FireServer("UseActorAbility", { buffer.fromstring("\3\8\0\0\0CoinFlip") })
                    end
                    if State.AutoReroll and not IsAbilityOnCooldown("Reroll") then
                        remote:FireServer("UseActorAbility", { buffer.fromstring("\3\6\0\0\0Reroll") })
                    end
                end
            end)
        end
    end)

    -- Auto Hat Fix Loop
    task.spawn(function()
        while ScriptRunning do
            task.wait(0.25)
            if State.TurnOnAutoHatFix and not IsAbilityOnCooldown("HatFix") then
                pcall(function()
                    local mainUI = LP:WaitForChild("PlayerGui"):FindFirstChild("MainUI")
                    local statusContainer = mainUI and mainUI:FindFirstChild("StatusContainer")
                    local vulnerable = statusContainer and statusContainer:FindFirstChild("Vulnerable")
                    local title = vulnerable and vulnerable:FindFirstChild("Title")
                    if title and title.Text then
                        local currentVal = RomanToNumber(title.Text)
                        if currentVal >= (State.AutoHatFixNumber or 1) then
                            local remote = GetRemoteEvent()
                            if remote then
                                remote:FireServer("UseActorAbility", { buffer.fromstring("\3\6\0\0\0HatFix") })
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Elliot Auto Rush Hour Loop
    task.spawn(function()
        while ScriptRunning do
            task.wait(0.25)
            if State.EnableAutoRushHour and not IsAbilityOnCooldown("RushHour") then
                pcall(function()
                    local char = LP.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local killers = Workspace:FindFirstChild("Players") and Workspace.Players:FindFirstChild("Killers")
                    if hrp and killers then
                        for _, k in ipairs(killers:GetChildren()) do
                            local kHRP = k:FindFirstChild("HumanoidRootPart")
                            if kHRP and (kHRP.Position - hrp.Position).Magnitude <= (State.AutoRushHourRange or 25) then
                                local remote = GetRemoteEvent()
                                if remote then
                                    remote:FireServer("UseActorAbility", { buffer.fromstring("\3\8\0\0\0RushHour") })
                                end
                                break
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Remove Insane Vignette Loop
    task.spawn(function()
        while ScriptRunning do
            task.wait(0.2)
            if State.RemoveInsaneVignette then
                pcall(function()
                    local mainUI = LP:WaitForChild("PlayerGui"):FindFirstChild("MainUI")
                    local vignette = mainUI and mainUI:FindFirstChild("InsaneVignette")
                    if vignette then vignette:Destroy() end
                end)
            end
        end
    end)

    -- Anti Glitched (New) Loop
    task.spawn(function()
        while ScriptRunning do
            task.wait(0.5)
            if State.AntiGlitchedNew then
                pcall(function()
                    local playerGui = LP:WaitForChild("PlayerGui")
                    local UI = playerGui:FindFirstChild("TemporaryUI")
                    local Frame = UI and UI:FindFirstChild("Frame")
                    if Frame and Frame:FindFirstChild("Glitched") then
                        Frame.Visible = false
                    end
                end)
            end
        end
    end)

    -- Anti Glitched (Old) Loop
    task.spawn(function()
        while ScriptRunning do
            task.wait(0.2)
            if State.AntiGlitchedOld then
                pcall(function()
                    local glitch = Workspace:FindFirstChild("GlitchParts")
                    while glitch do
                        glitch.Name = "byebye_nya"
                        glitch:Destroy()
                        glitch = Workspace:FindFirstChild("GlitchParts")
                    end
                end)
            end
        end
    end)
    TrackConnection(Workspace.ChildAdded:Connect(function(child)
        if State.AntiGlitchedOld and (child.Name == "GlitchParts" or child.Name == "byebye_nya") then
            task.defer(function() pcall(function() child:Destroy() end) end)
        end
    end))

    -- auto get pizzas Loop
    task.spawn(function()
        while ScriptRunning do
            if State.AutoGetPizzas then
                pcall(function()
                    local pizza = workspace:FindFirstChild("Map") 
                        and workspace.Map:FindFirstChild("Ingame") 
                        and workspace.Map.Ingame:FindFirstChild("Pizza")

                    if pizza then
                        local char = LP.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local originalCFrame = hrp.CFrame
                            hrp.CFrame = pizza.CFrame + Vector3.new(0, 1, 0)
                            task.wait(0.05)
                            hrp.CFrame = originalCFrame
                        end
                    end
                end)
            end
            task.wait(0.1)
        end
    end)

    -- Anti Noli Clones Loop
    task.spawn(function()
        while ScriptRunning do
            if State.AntiNoliClones then
                pcall(function()
                    if workspace:FindFirstChild("Hitboxes") and workspace.Hitboxes:FindFirstChild("SIKE&Hitbox") then
                        workspace.Hitboxes["SIKE&Hitbox"]:Destroy()
                    end
                    local map = workspace:FindFirstChild("Map")
                    local ingame = map and map:FindFirstChild("Ingame")
                    if ingame and ingame:FindFirstChild("TheEvilNoliOOOOO") then
                        ingame.TheEvilNoliOOOOO:Destroy()
                    end
                end)
            end
            task.wait(0.1)
        end
    end)

    -- Lag/Crash a server using Nova
    task.spawn(function()
        while ScriptRunning do
            if State.LagServerNova then
                for i = 1, 400 do
                    game:GetService("ReplicatedStorage").Modules.Network.Network.RemoteEvent:FireServer("UseActorAbility", { buffer.fromstring("\3\4\0\0\0Nova") })
                end
                task.wait(0.01)
            else
                task.wait(0.2)
            end
        end
    end)

    -- Notify if Noli's Nova is near you
    task.spawn(function()
        while ScriptRunning do
            if State.NotifyNoliNova then
                pcall(function()
                    local map = workspace:FindFirstChild("Map")
                    local ingame = map and map:FindFirstChild("Ingame")
                    local voidstar = ingame and ingame:FindFirstChild("Voidstar")
                    local char = LP.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if voidstar and hrp then
                        local dist = (voidstar.Position - hrp.Position).Magnitude
                        if dist <= 15 then
                            windui:Notify({ Title = "Noli Nova Alert", Content = "nova is near you!!!", Duration = 3 })
                            task.wait(3)
                        end
                    end
                end)
            end
            task.wait(0.2)
        end
    end)

    -- Active Loop for Effects, Features, and Mechanics
    task.spawn(function()
        while ScriptRunning and task.wait(0.2) do
            pcall(function()
                if State.NoFog then ApplyNoFog() end
                if State.FullBright then ApplyFullBright() end

                local char = LP.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then
                    if State.AntiSlowness and hum.WalkSpeed < 16 then
                        hum.WalkSpeed = 16
                    end
                    if State.EnableJumping then
                        hum.UseJumpPower = true
                        hum.JumpPower = 50
                    end
                end

                -- Less lag when hitboxes turned on
                if State.LessLagHitboxes then
                    pcall(function()
                        local hitboxesFolder = Workspace:FindFirstChild("Hitboxes")
                        if hitboxesFolder then
                            for _, hb in ipairs(hitboxesFolder:GetChildren()) do
                                if hb:IsA("BasePart") then
                                    hb.Transparency = 0.9
                                end
                            end
                        end
                    end)
                end

                -- Effects Handlers & New Anti-Stun/Anti-Undetectable Logic
                if char then
                    if State.AntiStun then
                        if char:GetAttribute("Stunned") then
                            char:SetAttribute("Stunned", nil)
                        end
                    end
                    if State.AntiUndetectable then
                        if char:GetAttribute("Undetectable") then
                            char:SetAttribute("Undetectable", nil)
                        end
                    end
                    if State.AntiOblivious or State.AntiSubspaceEffects then
                        if char:GetAttribute("MuteChaseThemes") then
                            char:SetAttribute("MuteChaseThemes", false)
                        end
                    end
                    if State.SilentFootsteps then
                        if not char:GetAttribute("FootstepsMuted") then
                            char:SetAttribute("FootstepsMuted", true)
                        end
                    end
                    if State.AntiSlateskin then
                        for _, child in ipairs(char:GetChildren()) do
                            if child:IsA("NumberValue") or child:IsA("ObjectValue") then
                                if child.Name:find("Slowed") or child.Name:find("Slateskin") or child.Name:find("Speed") then
                                    if child:IsA("NumberValue") then child.Value = 1 end
                                end
                            end
                        end
                    end
                end

                -- Hide Player Icon and Name Feature
                local tempUI = LP:WaitForChild("PlayerGui"):FindFirstChild("TemporaryUI")
                if tempUI then
                    local playerInfo = tempUI:FindFirstChild("PlayerInfo")
                    if playerInfo then
                        local currentSurvivors = playerInfo:FindFirstChild("CurrentSurvivors")
                        local playerIcon = playerInfo:FindFirstChild("PlayerIcon")
                        if currentSurvivors then currentSurvivors.Visible = not State.HidePlayerIconAndName end
                        if playerIcon then playerIcon.Visible = not State.HidePlayerIconAndName end
                    end
                end

                -- Anti Subspace Clear Existing
                if State.AntiSubspaceEffects then
                    for _, child in ipairs(Lighting:GetChildren()) do
                        if child.Name == "SubspaceVFXColorCorrection" or child.Name == "SubspaceVFXBlur" then
                            child:Destroy()
                        end
                    end
                end

                -- Anti Blindness
                if State.AntiBlindness then
                    local blur = Lighting:FindFirstChild("BlindnessBlur")
                    if blur then blur:Destroy() end
                    Lighting.ExposureCompensation = 0
                end

                -- Screen Effects Cleaners
                if tempUI then
                    if State.AntiVignette then
                        for _, child in ipairs(tempUI:GetChildren()) do
                            if child.Name == "Vignette" or (child:IsA("ImageLabel") and child.Name:find("Vignette")) then
                                child:Destroy()
                            end
                        end
                    end
                    if State.NoGlitchCorrupted then
                        for _, child in ipairs(tempUI:GetChildren()) do
                            if child.Name:find("Glitch") or child.Name:find("Vignette") or child.Name:find("Corrupt") then
                                child:Destroy()
                            end
                        end
                    end
                end

                -- Map & Hazards (Cleaned via cached arrays for zero lag)
                if State.RemoveSpikes then
                    for i = #MapCache.Spikes, 1, -1 do
                        local v = MapCache.Spikes[i]
                        if v and v.Parent then v:Destroy() end
                        table.remove(MapCache.Spikes, i)
                    end
                end
                if State.DisableKillerWalls then
                    for _, v in ipairs(MapCache.KillerWalls) do
                        if v and v.Parent and v:IsA("BasePart") then v.CanCollide = false end
                    end
                end
                if State.DisableToxicTrails then
                    for i = #MapCache.ToxicTrails, 1, -1 do
                        local v = MapCache.ToxicTrails[i]
                        if v and v.Parent then v:Destroy() end
                        table.remove(MapCache.ToxicTrails, i)
                    end
                end

                local mapObj = Workspace:FindFirstChild("Map")
                local ingame = mapObj and mapObj:FindFirstChild("Ingame")
                if ingame then
                    -- Loop Delete 007n7 Clones Feature (Optimized via MapCache)
                    if State.LoopDelete007n7Clones then
                        for i = #MapCache.Clones007, 1, -1 do
                            local cloneObj = MapCache.Clones007[i]
                            if cloneObj and cloneObj.Parent then
                                pcall(function() cloneObj:Destroy() end)
                            end
                            table.remove(MapCache.Clones007, i)
                        end
                    end

                    -- Remove Killer Doors & Killer Only Boundaries Loop
                    if State.RemoveKillerDoors then
                        local mainMap = ingame:FindFirstChild("Map")
                        if mainMap and mainMap:FindFirstChild("MapBoundaries") then
                            local mb = mainMap.MapBoundaries
                            if mb:FindFirstChild("KillerDoors") then mb.KillerDoors:Destroy() end
                            if mb:FindFirstChild("KillerOnly") then mb.KillerOnly:Destroy() end
                        end
                    end

                    -- Instant Generator Prompt HoldDuration Loop
                    if State.InstantGenPrompt then
                        local mainMap = ingame:FindFirstChild("Map")
                        if mainMap then
                            for _, obj in ipairs(mainMap:GetChildren()) do
                                if obj:IsA("Model") and obj.Name:lower():find("generator") then
                                    local main = obj:FindFirstChild("Main")
                                    local prompt = main and main:FindFirstChildOfClass("ProximityPrompt")
                                    if prompt then prompt.HoldDuration = 0 end
                                end
                            end
                        end
                    end
                end

                -- Anticheat Bounds Bypass Loop
                if State.MapBoundsBypass then
                    pcall(function() Workspace:SetAttribute("sv_anticheat_disabled", true) end)
                    pcall(function() LP:SetAttribute("anticheat_disabled", true) end)
                end
            end)
        end
    end)

    -- RenderStepped Loop for Anti-Confusion & Anti-Nausea & Make 007n7 Visible / Nosferatu Original Form
    local lastMakeVisibleCheck = 0
    TrackConnection(RunService.RenderStepped:Connect(function()
        if State.AntiNausea then
            pcall(function() RunService:UnbindFromRenderStep("PreDistort") end)
            pcall(function() RunService:UnbindFromRenderStep("DistortCamera") end)
        end
        if State.AntiConfusion then
            pcall(function()
                local playerScripts = LP:WaitForChild("PlayerScripts")
                local controls = require(playerScripts:WaitForChild("PlayerModule")):GetControls()
                if controls.moveFunction ~= LP.Move then
                    controls.moveFunction = LP.Move
                end
            end)
        end

        local now = os.clock()
        if now - lastMakeVisibleCheck >= 0.1 then
            lastMakeVisibleCheck = now
            pcall(function()
                -- Make 007n7 visible if he's using clones
                if State.Make007n7Visible then
                    local target007 = Workspace:FindFirstChild("Players") and Workspace.Players:FindFirstChild("Survivors") and Workspace.Players.Survivors:FindFirstChild("007n7")
                    if target007 then
                        local blacklist = {
                            ["TheThing"] = true,
                            ["HumanoidRootPart"] = true,
                            ["QueryHitbox"] = true,
                            ["ExpressionHolder"] = true
                        }
                        for _, obj in ipairs(target007:GetDescendants()) do
                            if obj:IsA("BasePart") or obj:IsA("Decal") or obj:IsA("Texture") then
                                if blacklist[obj.Name] then
                                    obj.Transparency = 1
                                    if obj:IsA("BasePart") then obj.LocalTransparencyModifier = 1 end
                                else
                                    obj.Transparency = 0
                                    if obj:IsA("BasePart") then obj.LocalTransparencyModifier = 0 end
                                end
                            end
                        end
                    end
                end

                -- Make Nosferatu's original form visible if he's a bat
                if State.NosferatuOriginalVisible then
                    local nos = Workspace:FindFirstChild("Players") and Workspace.Players:FindFirstChild("Killers") and Workspace.Players.Killers:FindFirstChild("Nosferatu")
                    if nos then
                        local bat = nos:FindFirstChild("Bat")
                        local isBatActive = bat and bat.Transparency == 0
                        if isBatActive then
                            for _, part in ipairs(nos:GetDescendants()) do
                                if part:IsA("BasePart") or part:IsA("Decal") or part:IsA("Texture") then
                                    if part.Name ~= "HumanoidRootPart" and part.Name ~= "QueryHitbox" and part.Name ~= "CollisionHitbox" then
                                        part.Transparency = 0
                                        if part:IsA("BasePart") then part.LocalTransparencyModifier = 0 end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
    end))

    -- Auto Trick Loop (Veeronica)
    local lastTrick = 0
    TrackConnection(RunService.Heartbeat:Connect(function()
        if not State.AutoTrick then return end
        pcall(function()
            local modules = ReplicatedStorage:FindFirstChild("Modules")
            local systems = ReplicatedStorage:FindFirstChild("Systems")
            if not modules or not systems then return end

            local actorsModule = modules:FindFirstChild("Gameplay") and modules.Gameplay:FindFirstChild("Actors")
            local sprintModule = systems:FindFirstChild("Character") and systems.Character:FindFirstChild("Game") and systems.Character.Game:FindFirstChild("Sprinting")
            if not actorsModule or not sprintModule then return end

            local actors = require(actorsModule)
            local sprinting = require(sprintModule)
            
            local actor = actors.CurrentActors[LP]
            if not actor or not actor.State or not actor.State.isSkating then return end

            local highlight = actor.Instances and actor.Instances.Sk8Highlight
            if not highlight or not highlight.Adornee then return end

            if os.clock() - lastTrick < 1.1 then return end
            lastTrick = os.clock()

            if sprinting.MobileButton and sprinting.MobileButton.Parent then
                for _, conn in pairs(getconnections(sprinting.MobileButton.MouseButton1Down)) do
                    pcall(conn.Function)
                end
                task.wait(0.05)
                for _, conn in pairs(getconnections(sprinting.MobileButton.MouseButton1Up)) do
                    pcall(conn.Function)
                end
            end
        end)
    end))

    -- Sk8 Anywhere Loop (FULLY REPAIRED & FAST - Using Descendants)
    task.spawn(function()
        local processed = setmetatable({}, {__mode = "k"})
        local Targets = {"spray", "graffiti"}

        local function isTarget(itemName)
            local name = string.lower(itemName)
            for _, target in ipairs(Targets) do
                if string.find(name, target) then return true end
            end
            return false
        end

        while ScriptRunning do
            task.wait(0.3)
            if State.Sk8Anywhere and not IsAbilityOnCooldown("Sk8") then
                pcall(function()
                    local char = LP.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if not root then return end

                    local ingameFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Ingame")
                    if not ingameFolder then return end

                    local remoteEvent = GetRemoteEvent()
                    if not remoteEvent then return end

                    for _, item in ipairs(ingameFolder:GetDescendants()) do
                        if isTarget(item.Name) and not processed[item] then
                            processed[item] = true

                            local targetCFrame = nil
                            if item:IsA("BasePart") then
                                targetCFrame = item.CFrame
                            elseif item:IsA("Model") then
                                targetCFrame = item:GetPivot()
                            end

                            if targetCFrame then
                                local originalCFrame = root.CFrame
                                root.CFrame = targetCFrame * CFrame.new(0, 0, -4)
                                task.wait(0.05)
                                remoteEvent:FireServer("UseActorAbility", { buffer.fromstring("\3\3\0\0\0Sk8") })
                                task.wait(0.1)
                                if root and root.Parent then
                                    root.CFrame = originalCFrame
                                end
                                break
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Snappy Void Rush Drifter Controller (Noli)
    local function getKiller()
        local actors = require(ReplicatedStorage.Modules.Gameplay.Actors)
        for _, actor in pairs(actors.CurrentActors or {}) do
            if actor.Player == LP and actor.ActorType == "Killer" then
                return actor
            end
        end
    end

    RunService:BindToRenderStep("SnappyVoidRush", Enum.RenderPriority.Character.Value + 10, function()
        if not State.VoidRushController then return end
        local killer = getKiller()
        if not killer or not killer.Rig or not killer.Rig.PrimaryPart then return end

        local state = killer.Rig:GetAttribute("VoidRushState")
        if state ~= "Dashing" and state ~= "Charging" then return end

        local look = workspace.CurrentCamera.CFrame.LookVector
        local flat = Vector3.new(look.X, 0, look.Z).Unit

        killer.Rig.Humanoid:Move(flat)
    end)

    -- Noli Auto Stab Logic
    local stabIsLocking = false
    local stabTargetCharacter = nil
    local stabLockStartTime = 0
    local stabSavedCameraType = nil
    local stabSavedCameraSubject = nil

    local function isStabReady()
        local cooldown = LP.PlayerGui.MainUI.AbilityContainer.Stab.CooldownTime
        if not cooldown or not cooldown:IsA("TextLabel") then return false end
        return cooldown.Text:match("^%s*$") ~= nil
    end

    local function fireStabRemote()
        game:GetService("ReplicatedStorage").Modules.Network.Network.RemoteEvent:FireServer("UseActorAbility", { buffer.fromstring("\3\4\0\0\0Stab") })
    end

    local function getTorso(character)
        return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    end

    local function restoreStabCamera()
        local camera = workspace.CurrentCamera
        if camera then
            camera.CameraType = stabSavedCameraType or Enum.CameraType.Custom
            if stabSavedCameraSubject and stabSavedCameraSubject.Parent then
                camera.CameraSubject = stabSavedCameraSubject
            end
        end
        stabIsLocking = false
        stabTargetCharacter = nil
        stabSavedCameraType = nil
        stabSavedCameraSubject = nil
    end

    local function getClosestSurvivorStab()
        local survivorsFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Survivors")
        if not survivorsFolder then return nil end

        local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return nil end

        local closest, closestDist = nil, State.NoliStabRange
        for _, survivor in ipairs(survivorsFolder:GetChildren()) do
            if survivor:IsA("Model") then
                local humanoid = survivor:FindFirstChildOfClass("Humanoid")
                local root = survivor:FindFirstChild("HumanoidRootPart")
                if humanoid and humanoid.Health > 0 and root then
                    local dist = (root.Position - myRoot.Position).Magnitude
                    if dist <= closestDist then
                        closestDist = dist
                        closest = survivor
                    end
                end
            end
        end
        return closest
    end

    local function startStabCameraLock(character)
        if stabIsLocking or not isStabReady() then return end

        local camera = workspace.CurrentCamera
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local torso = getTorso(character)
        if not camera or not humanoid or humanoid.Health <= 0 or not torso then return end

        fireStabRemote()

        stabSavedCameraType = camera.CameraType
        stabSavedCameraSubject = camera.CameraSubject
        stabTargetCharacter = character
        stabLockStartTime = os.clock()
        stabIsLocking = true
    end

    RunService.RenderStepped:Connect(function()
        if not State.NoliAutoStab then return end
        if stabIsLocking or not isStabReady() then return end
        local target = getClosestSurvivorStab()
        if target then
            startStabCameraLock(target)
        end
    end)

    RunService:BindToRenderStep("StabCameraLock", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not State.NoliAutoStab or not stabIsLocking then return end

        if not isStabReady() or os.clock() - stabLockStartTime >= 0.35 then
            restoreStabCamera()
            return
        end

        local camera = workspace.CurrentCamera
        local character = stabTargetCharacter
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local torso = character and getTorso(character)

        if not camera or not character or not character.Parent or not humanoid or humanoid.Health <= 0 or not torso then
            restoreStabCamera()
            return
        end

        camera.CameraType = Enum.CameraType.Scriptable
        local desired = CFrame.lookAt(camera.CFrame.Position, AimUtil.Point(torso))
        camera.CFrame = AimUtil.Smooth(camera.CFrame, desired, dt, 0.65)
    end)

    -- Noli Auto Nova Logic
    local novaIsLocking = false
    local novaTargetCharacter = nil
    local novaLockStartTime = 0
    local novaSavedCameraType = nil
    local novaSavedCameraSubject = nil

    local function isNovaReady()
        local cooldown = LP.PlayerGui.MainUI.AbilityContainer.Nova.CooldownTime
        if not cooldown or not cooldown:IsA("TextLabel") then return false end
        return cooldown.Text:match("^%s*$") ~= nil
    end

    local function fireNovaRemote()
        game:GetService("ReplicatedStorage").Modules.Network.Network.RemoteEvent:FireServer("UseActorAbility", { buffer.fromstring("\3\4\0\0\0Nova") })
    end

    local function restoreNovaCamera()
        local camera = workspace.CurrentCamera
        if camera then
            camera.CameraType = novaSavedCameraType or Enum.CameraType.Custom
            if novaSavedCameraSubject and novaSavedCameraSubject.Parent then
                camera.CameraSubject = novaSavedCameraSubject
            end
        end
        novaIsLocking = false
        novaTargetCharacter = nil
        novaSavedCameraType = nil
        novaSavedCameraSubject = nil
    end

    local function getClosestSurvivorNova()
        local survivorsFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Survivors")
        if not survivorsFolder then return nil end

        local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return nil end

        local closest, closestDist = nil, State.NoliNovaRange
        for _, survivor in ipairs(survivorsFolder:GetChildren()) do
            if survivor:IsA("Model") then
                local humanoid = survivor:FindFirstChildOfClass("Humanoid")
                local root = survivor:FindFirstChild("HumanoidRootPart")
                if humanoid and humanoid.Health > 0 and root then
                    local dist = (root.Position - myRoot.Position).Magnitude
                    if dist <= closestDist then
                        closestDist = dist
                        closest = survivor
                    end
                end
            end
        end
        return closest
    end

    local function startNovaCameraLock(character)
        if novaIsLocking or not isNovaReady() then return end

        local camera = workspace.CurrentCamera
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local torso = getTorso(character)
        if not camera or not humanoid or humanoid.Health <= 0 or not torso then return end

        fireNovaRemote()

        novaSavedCameraType = camera.CameraType
        novaSavedCameraSubject = camera.CameraSubject
        novaTargetCharacter = character
        novaLockStartTime = os.clock()
        novaIsLocking = true
    end

    RunService.RenderStepped:Connect(function()
        if not State.NoliAutoNova then return end
        if novaIsLocking or not isNovaReady() then return end
        local target = getClosestSurvivorNova()
        if target then
            startNovaCameraLock(target)
        end
    end)

    RunService:BindToRenderStep("NovaCameraLock", Enum.RenderPriority.Camera.Value + 1, function(dt)
        if not State.NoliAutoNova or not novaIsLocking then return end

        if not isNovaReady() or os.clock() - novaLockStartTime >= 0.25 then
            restoreNovaCamera()
            return
        end

        local camera = workspace.CurrentCamera
        local character = novaTargetCharacter
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local torso = character and getTorso(character)

        if not camera or not character or not character.Parent or not humanoid or humanoid.Health <= 0 or not torso then
            restoreNovaCamera()
            return
        end

        camera.CameraType = Enum.CameraType.Scriptable
        local desired = CFrame.lookAt(camera.CFrame.Position, AimUtil.Point(torso))
        camera.CFrame = AimUtil.Smooth(camera.CFrame, desired, dt, 0.65)
    end)

    -- Anti Nova Explosion Effect
    task.spawn(function()
        local Terrain = workspace:WaitForChild("Terrain")
        local function kill(obj)
            if State.AntiNovaExplosion and obj.Name == "Explosion" then
                obj:Destroy()
            end
        end
        for _, c in ipairs(Terrain:GetChildren()) do
            kill(c)
        end
        Terrain.ChildAdded:Connect(kill)
    end)

    -- Killer Aimbot Loop
    local killerAimbotConnection = nil
    local function getClosestSurvivorTorsoForKillerAimbot()
        local closest = nil
        local shortest = math.huge
        local survivorsFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Survivors")
        local Camera = workspace.CurrentCamera
        
        if not survivorsFolder then return nil end
        
        for _, survivor in pairs(survivorsFolder:GetChildren()) do
            if survivor:IsA("Model") and survivor ~= LP.Character then
                local torso = survivor:FindFirstChild("Torso") 
                    or survivor:FindFirstChild("UpperTorso") 
                    or survivor:FindFirstChild("HumanoidRootPart")
                
                if torso then
                    local dist = (Camera.CFrame.Position - torso.Position).Magnitude
                    if dist < shortest then
                        shortest = dist
                        closest = torso
                    end
                end
            end
        end
        return closest
    end

    -- Corrupt Nature Aimbot (c00lkidd)
    local corruptTarget = nil
    local corruptLockStart = 0
    local corruptIsLocking = false
    local corruptOrigCamType = Workspace.CurrentCamera and Workspace.CurrentCamera.CameraType or Enum.CameraType.Custom

    local function getCorruptTorso(character)
        return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
    end

    local function isCorruptRunning(humanoid)
        return humanoid.WalkSpeed >= 20 or (humanoid.MoveDirection.Magnitude > 0.8 and humanoid.WalkSpeed > 16)
    end

    local function getCorruptPredictedPosition(torso, humanoid)
        local root = torso.Parent:FindFirstChild("HumanoidRootPart") or torso
        local velocity = root.AssemblyLinearVelocity
        local speed = velocity.Magnitude
        if speed < 1 then return torso.Position end
        local moveDir = velocity.Unit
        local side = math.abs(moveDir:Dot(root.CFrame.RightVector))
        if side < 0.35 then return torso.Position end
        local predictStuds = isCorruptRunning(humanoid) and 6.7 or 4.5
        return torso.Position + moveDir * predictStuds
    end

    local function getNearestCorruptSurvivor()
        local pf = Workspace:FindFirstChild("Players")
        local sf = pf and pf:FindFirstChild("Survivors")
        if not sf then return nil end
        local closest, closestDist = nil, 80
        local cam = Workspace.CurrentCamera
        for _, s in ipairs(sf:GetChildren()) do
            if s:IsA("Model") and s ~= LP.Character then
                local hum = s:FindFirstChildOfClass("Humanoid")
                local torso = getCorruptTorso(s)
                if hum and hum.Health > 0 and torso and cam then
                    local dist = (torso.Position - cam.CFrame.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closest = s
                    end
                end
            end
        end
        return closest
    end

    TrackConnection(RunService.RenderStepped:Connect(function(dt)
        if not State.CorruptNatureAimbot then return end
        local cam = Workspace.CurrentCamera
        if not cam then return end

        if IsAbilityOnCooldown("CorruptNature") then
            if corruptIsLocking then
                corruptIsLocking = false
                corruptTarget = nil
                cam.CameraType = corruptOrigCamType
            end
            return
        end

        local target = getNearestCorruptSurvivor()
        local now = tick()
        local remote = GetRemoteEvent()

        if target then
            if not corruptIsLocking then
                corruptIsLocking = true
                corruptLockStart = now
                corruptTarget = target
                corruptOrigCamType = cam.CameraType
                if remote then
                    pcall(function()
                        remote:FireServer("UseActorAbility", { buffer.fromstring("\3\r\0\0\0CorruptNature") })
                    end)
                end
            end

            if now - corruptLockStart <= 1.0 then
                cam.CameraType = Enum.CameraType.Scriptable
                local hum = corruptTarget and corruptTarget:FindFirstChildOfClass("Humanoid")
                local torso = corruptTarget and getCorruptTorso(corruptTarget)
                if torso and hum then
                    local aimPos = getCorruptPredictedPosition(torso, hum)
                    local lookCF = CFrame.lookAt(cam.CFrame.Position, aimPos)
                    cam.CFrame = AimUtil.Smooth(cam.CFrame, lookCF, dt, 0.18)
                end
            else
                if cam.CameraType == Enum.CameraType.Scriptable then
                    cam.CameraType = corruptOrigCamType
                end
                corruptIsLocking = false
                corruptTarget = nil
            end
        else
            if corruptIsLocking then
                corruptIsLocking = false
                corruptTarget = nil
                cam.CameraType = corruptOrigCamType
            end
        end
    end))

    -- Walkspeed Override Aimbot (c00lkidd)
    local wsTarget = nil
    local wsLockStart = 0
    local wsIsLocking = false
    local wsSavedCamType = nil
    local wsSavedCamSubject = nil

    local function getWSTorso(character)
        return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    end

    local function isWSAbilityReady()
        return not IsAbilityOnCooldown("WalkspeedOverride")
    end

    local function hasWSLineOfSight(character, torso)
        local cam = Workspace.CurrentCamera
        if not cam or not torso or not torso:IsDescendantOf(Workspace) then return false end
        local origin = cam.CFrame.Position
        local dir = torso.Position - origin
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { LP.Character, cam }
        params.IgnoreWater = true
        local res = Workspace:Raycast(origin, dir, params)
        return res ~= nil and res.Instance:IsDescendantOf(character)
    end

    local function getNearestWSSurvivor()
        local pf = Workspace:FindFirstChild("Players")
        local sf = pf and pf:FindFirstChild("Survivors")
        if not sf then return nil end
        local cam = Workspace.CurrentCamera
        if not cam then return nil end
        local closest, closestDist = nil, 80
        for _, s in ipairs(sf:GetChildren()) do
            if s:IsA("Model") and s ~= LP.Character then
                local hum = s:FindFirstChildOfClass("Humanoid")
                local torso = getWSTorso(s)
                if hum and hum.Health > 0 and torso then
                    local dist = (torso.Position - cam.CFrame.Position).Magnitude
                    if dist < closestDist and hasWSLineOfSight(s, torso) then
                        closestDist = dist
                        closest = s
                    end
                end
            end
        end
        return closest
    end

    local function restoreWSCamera()
        local cam = Workspace.CurrentCamera
        if cam then
            cam.CameraType = wsSavedCamType or Enum.CameraType.Custom
            if wsSavedCamSubject and wsSavedCamSubject.Parent then
                cam.CameraSubject = wsSavedCamSubject
            end
        end
        wsTarget = nil
        wsIsLocking = false
        wsSavedCamType = nil
        wsSavedCamSubject = nil
    end

    TrackConnection(RunService.RenderStepped:Connect(function(dt)
        if not State.WalkspeedOverrideAimbot then return end
        local cam = Workspace.CurrentCamera
        if not cam then return end

        if not isWSAbilityReady() then
            if wsIsLocking then restoreWSCamera() end
            return
        end

        if wsIsLocking then
            local target = wsTarget
            local hum = target and target:FindFirstChildOfClass("Humanoid")
            local torso = target and getWSTorso(target)
            if not target or not target.Parent or not hum or hum.Health <= 0 or not torso or not hasWSLineOfSight(target, torso) or (os.clock() - wsLockStart >= 1.0) then
                restoreWSCamera()
                return
            end

            cam.CameraType = Enum.CameraType.Scriptable
            local desiredCF = CFrame.lookAt(cam.CFrame.Position, AimUtil.Point(torso))
            cam.CFrame = AimUtil.Smooth(cam.CFrame, desiredCF, dt, 0.18)
            return
        end

        local target = getNearestWSSurvivor()
        if target and isWSAbilityReady() then
            wsSavedCamType = cam.CameraType
            wsSavedCamSubject = cam.CameraSubject
            wsTarget = target
            wsLockStart = os.clock()
            wsIsLocking = true
            pcall(function()
                local remote = GetRemoteEvent()
                if remote then
                    remote:FireServer("UseActorAbility", { buffer.fromstring("\3\17\0\0\0WalkspeedOverride") })
                end
            end)
        end
    end))

    -- Tag Auto Hit Survivors (c00lkidd)
    local tagHitboxCache = {}
    local tagFiredThisApproach = {}
    local tagPendingLocks = {}
    local tagIsLocking = false
    local tagCurrentTarget = nil
    local tagLockStart = 0
    local tagSavedCamType = nil
    local tagSavedCamSubject = nil

    local function isTagReady()
        return not IsAbilityOnCooldown("Tag")
    end

    local function findTagQueryHitbox(survivor)
        for _, d in ipairs(survivor:GetDescendants()) do
            if d.Name == "QueryHitbox" and d:IsA("BasePart") then return d end
        end
    end

    local function cacheTagSurvivor(survivor)
        if not survivor:IsA("Model") then return end
        tagHitboxCache[survivor] = findTagQueryHitbox(survivor)
        tagFiredThisApproach[survivor] = false

        survivor.DescendantAdded:Connect(function(d)
            if d.Name == "QueryHitbox" and d:IsA("BasePart") then
                tagHitboxCache[survivor] = d
            end
        end)
        survivor.DescendantRemoving:Connect(function(d)
            if tagHitboxCache[survivor] == d then tagHitboxCache[survivor] = nil end
        end)
    end

    local survivorsFolder = Workspace:FindFirstChild("Players") and Workspace.Players:FindFirstChild("Survivors")
    if survivorsFolder then
        for _, s in ipairs(survivorsFolder:GetChildren()) do cacheTagSurvivor(s) end
        TrackConnection(survivorsFolder.ChildAdded:Connect(cacheTagSurvivor))
        TrackConnection(survivorsFolder.ChildRemoved:Connect(function(s)
            tagHitboxCache[s] = nil
            tagFiredThisApproach[s] = nil
            tagPendingLocks[s] = nil
        end))
    end

    local function getTagSurfaceDistance(root, hitbox)
        local localPos = hitbox.CFrame:PointToObjectSpace(root.Position)
        local halfSize = hitbox.Size * 0.5
        local closestPt = Vector3.new(
            math.clamp(localPos.X, -halfSize.X, halfSize.X),
            math.clamp(localPos.Y, -halfSize.Y, halfSize.Y),
            math.clamp(localPos.Z, -halfSize.Z, halfSize.Z)
        )
        local worldPt = hitbox.CFrame:PointToWorldSpace(closestPt)
        return (root.Position - worldPt).Magnitude
    end

    local function restoreTagCamera()
        local cam = Workspace.CurrentCamera
        if cam then
            cam.CameraType = tagSavedCamType or Enum.CameraType.Custom
            if tagSavedCamSubject and tagSavedCamSubject.Parent then
                cam.CameraSubject = tagSavedCamSubject
            end
        end
        tagIsLocking = false
        tagCurrentTarget = nil
        tagSavedCamType = nil
        tagSavedCamSubject = nil
    end

    TrackConnection(RunService.Heartbeat:Connect(function()
        if not State.TagAutoHit then return end
        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local now = os.clock()

        for survivor, hitbox in pairs(tagHitboxCache) do
            if not survivor.Parent then
                tagHitboxCache[survivor] = nil
                tagFiredThisApproach[survivor] = nil
                tagPendingLocks[survivor] = nil
                continue
            end
            if not hitbox or not hitbox:IsDescendantOf(survivor) then
                tagFiredThisApproach[survivor] = false
                continue
            end

            local close = getTagSurfaceDistance(root, hitbox) <= (State.TagHitDistance or 4)
            if close and not tagFiredThisApproach[survivor] then
                tagFiredThisApproach[survivor] = true
                if isTagReady() then
                    pcall(function()
                        local remote = GetRemoteEvent()
                        if remote then
                            remote:FireServer("UseActorAbility", { buffer.fromstring("\3\3\0\0\0Tag") })
                        end
                    end)
                    tagPendingLocks[survivor] = now + 0.05
                end
            elseif not close then
                tagFiredThisApproach[survivor] = false
            end

            local sched = tagPendingLocks[survivor]
            if sched and now >= sched then
                tagPendingLocks[survivor] = nil
                if close and isTagReady() then
                    local cam = Workspace.CurrentCamera
                    local hum = survivor:FindFirstChildOfClass("Humanoid")
                    local torso = getCorruptTorso(survivor)
                    if cam and hum and hum.Health > 0 and torso then
                        tagSavedCamType = cam.CameraType
                        tagSavedCamSubject = cam.CameraSubject
                        tagCurrentTarget = survivor
                        tagLockStart = os.clock()
                        tagIsLocking = true
                    end
                end
            end
        end
    end))

    TrackConnection(RunService.RenderStepped:Connect(function(dt)
        if not State.TagAutoHit or not tagIsLocking then return end
        if not isTagReady() then
            restoreTagCamera()
            return
        end
        local cam = Workspace.CurrentCamera
        local target = tagCurrentTarget
        local hum = target and target:FindFirstChildOfClass("Humanoid")
        local torso = target and getCorruptTorso(target)
        if not cam or not target or not target.Parent or not hum or hum.Health <= 0 or not torso or (os.clock() - tagLockStart >= 0.3) then
            restoreTagCamera()
            return
        end
        cam.CameraType = Enum.CameraType.Scriptable
        local desiredCF = CFrame.lookAt(cam.CFrame.Position, AimUtil.Point(torso))
        cam.CFrame = AimUtil.Smooth(cam.CFrame, desiredCF, dt, 0.35)
    end))

    -- Slasher Automation Loops (Auto Slash, Auto Behead, Auto Raging Pace)
    local slasherIsLocking = false
    local slasherTargetChar = nil
    local slasherLockStart = 0
    local slasherSavedCamType = nil
    local slasherSavedCamSubject = nil

    local function isCurrentSlasher()
        local s = Workspace:FindFirstChild("Players") and Workspace.Players:FindFirstChild("Killers") and Workspace.Players.Killers:FindFirstChild("Slasher")
        return s and s:GetAttribute("Username") == LP.Name
    end

    local function isSlashReady()
        return not IsAbilityOnCooldown("Slash")
    end

    local function getClosestSlasherSurvivor()
        local pf = Workspace:FindFirstChild("Players")
        local survivors = pf and pf:FindFirstChild("Survivors")
        local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not survivors or not myRoot then return nil end
        local closest, closestDist = nil, 7.5
        for _, char in ipairs(survivors:GetChildren()) do
            if char:IsA("Model") then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and root then
                    local dist = (root.Position - myRoot.Position).Magnitude
                    if dist <= closestDist then
                        closest = char
                        closestDist = dist
                    end
                end
            end
        end
        return closest
    end

    local function restoreSlasherCamera()
        local cam = Workspace.CurrentCamera
        if cam and slasherIsLocking then
            cam.CameraType = slasherSavedCamType or Enum.CameraType.Custom
            if slasherSavedCamSubject and slasherSavedCamSubject.Parent then
                cam.CameraSubject = slasherSavedCamSubject
            end
        end
        slasherIsLocking = false
        slasherTargetChar = nil
        slasherSavedCamType = nil
        slasherSavedCamSubject = nil
    end

    TrackConnection(RunService.Heartbeat:Connect(function()
        if not State.AutoSlashSlasher or not isCurrentSlasher() then return end
        if slasherIsLocking or LP:GetAttribute("CameraLockPriority") == "Behead" or not isSlashReady() then return end
        local target = getClosestSlasherSurvivor()
        if target then
            local cam = Workspace.CurrentCamera
            local hum = target:FindFirstChildOfClass("Humanoid")
            local torso = target:FindFirstChild("UpperTorso") or target:FindFirstChild("Torso")
            if not cam or not hum or hum.Health <= 0 or not torso then return end
            slasherSavedCamType = cam.CameraType
            slasherSavedCamSubject = cam.CameraSubject
            slasherTargetChar = target
            slasherLockStart = os.clock()
            slasherIsLocking = true
            pcall(function()
                local remote = GetRemoteEvent()
                if remote then
                    remote:FireServer("UseActorAbility", { buffer.fromstring("\3\5\0\0\0Slash") })
                end
            end)
        end
    end))

    TrackConnection(RunService.RenderStepped:Connect(function(dt)
        if not State.AutoSlashSlasher or not slasherIsLocking then return end
        if not isCurrentSlasher() or LP:GetAttribute("CameraLockPriority") == "Behead" or not isSlashReady() or (os.clock() - slasherLockStart >= (State.SlasherLockDuration or 0.2)) then
            restoreSlasherCamera()
            return
        end
        local cam = Workspace.CurrentCamera
        local char = slasherTargetChar
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local torso = char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"))
        if not cam or not char or not char.Parent or not hum or hum.Health <= 0 or not torso then
            restoreSlasherCamera()
            return
        end
        cam.CameraType = Enum.CameraType.Scriptable
        local desired = CFrame.lookAt(cam.CFrame.Position, AimUtil.Point(torso))
        cam.CFrame = AimUtil.Smooth(cam.CFrame, desired, dt, 0.35)
    end))

    -- Auto Behead Loop
    task.spawn(function()
        while ScriptRunning do
            task.wait(0.2)
            if State.AutoBehead and isCurrentSlasher() and not IsAbilityOnCooldown("Behead") then
                pcall(function()
                    local target = getClosestSlasherSurvivor()
                    if target then
                        local remote = GetRemoteEvent()
                        if remote then
                            remote:FireServer("UseActorAbility", { buffer.fromstring("\3\6\0\0\0Behead") })
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Raging Pace Loop
    task.spawn(function()
        while ScriptRunning do
            task.wait(0.2)
            if State.AutoRagingPace and isCurrentSlasher() and not IsAbilityOnCooldown("RagingPace") then
                pcall(function()
                    local pg = LP:FindFirstChild("PlayerGui")
                    local tUI = pg and pg:FindFirstChild("TemporaryUI")
                    local pInfo = tUI and tUI:FindFirstChild("PlayerInfo")
                    local bars = pInfo and pInfo:FindFirstChild("Bars")
                    local staminaBar = bars and bars:FindFirstChild("Stamina")
                    local amount = staminaBar and staminaBar:FindFirstChild("Amount")
                    if amount and amount:IsA("TextLabel") then
                        local val = tonumber(amount.Text)
                        if val and val <= (State.RagingPaceStaminaThreshold or 35) then
                            local remote = GetRemoteEvent()
                            if remote then
                                remote:FireServer("UseActorAbility", { buffer.fromstring("\3\n\0\0\0RagingPace") })
                                task.wait(1)
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- Corrupt Energy Camera Lock (John Doe)
    local johnDoeLockConn = nil
    local function getClosestSurvivorTorsoForJohnDoe()
        local closest = nil
        local shortest = math.huge
        local survivorsFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Survivors")
        local Camera = workspace.CurrentCamera
        
        if not survivorsFolder then return nil end
        
        for _, survivor in pairs(survivorsFolder:GetChildren()) do
            if survivor:IsA("Model") and survivor ~= LP.Character then
                local torso = survivor:FindFirstChild("Torso")
                    or survivor:FindFirstChild("UpperTorso")
                    or survivor:FindFirstChild("HumanoidRootPart")
                
                if torso then
                    local dist = (Camera.CFrame.Position - torso.Position).Magnitude
                    if dist < shortest then
                        shortest = dist
                        closest = torso
                    end
                end
            end
        end
        return closest
    end

    local function startJohnDoeCameraLock()
        if johnDoeLockConn then return end
        local Camera = workspace.CurrentCamera
        Camera.CameraType = Enum.CameraType.Scriptable
        Camera.CameraSubject = nil
        
        johnDoeLockConn = RunService.RenderStepped:Connect(function()
            local target = getClosestSurvivorTorsoForJohnDoe()
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if target and hrp then
                Camera.CFrame = CFrame.lookAt(hrp.Position + Vector3.new(0, 1.5, 0), AimUtil.Point(target))
            end
        end)
    end

    local function stopJohnDoeCameraLock()
        if johnDoeLockConn then
            johnDoeLockConn:Disconnect()
            johnDoeLockConn = nil
        end
        local Camera = workspace.CurrentCamera
        Camera.CameraType = Enum.CameraType.Custom
        if LP.Character then
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                Camera.CameraSubject = hum
            end
        end
    end

    task.spawn(function()
        while ScriptRunning do
            if State.CorruptEnergyCamLock then
                local corruptEnergy = workspace:FindFirstChild("Players")
                    and workspace.Players:FindFirstChild("Killers")
                    and workspace.Players.Killers:FindFirstChild("JohnDoe")
                    and workspace.Players.Killers.JohnDoe:FindFirstChild("SpeedMultipliers")
                    and workspace.Players.Killers.JohnDoe.SpeedMultipliers:FindFirstChild("CorruptEnergy")
                
                if corruptEnergy then
                    startJohnDoeCameraLock()
                else
                    stopJohnDoeCameraLock()
                end
            else
                stopJohnDoeCameraLock()
            end
            task.wait(0.1)
        end
    end)

    -- John Doe Slash Cam Lock
    local jdSlashIsLocking = false
    local jdSlashTargetChar = nil
    local jdSlashLockStartTime = 0
    local jdSlashSavedCamType = nil
    local jdSlashSavedCamSubject = nil

    local function isJDSlashReady()
        return not IsAbilityOnCooldown("Slash")
    end

    local function fireJDSlashRemote()
        local remote = GetRemoteEvent()
        if remote then
            remote:FireServer(
                "UseActorAbility",
                { buffer.fromstring("\3\5\0\0\0Slash") }
            )
        end
    end

    local function getJDTorso(character)
        return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    end

    local function restoreJDSlashCamera()
        local camera = workspace.CurrentCamera
        if camera then
            camera.CameraType = jdSlashSavedCamType or Enum.CameraType.Custom
            if jdSlashSavedCamSubject and jdSlashSavedCamSubject.Parent then
                camera.CameraSubject = jdSlashSavedCamSubject
            end
        end
        jdSlashIsLocking = false
        jdSlashTargetChar = nil
        jdSlashSavedCamType = nil
        jdSlashSavedCamSubject = nil
    end

    local function getClosestJDSurvivor()
        local survivorsFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Survivors")
        if not survivorsFolder then return nil end

        local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return nil end

        local closest, closestDist = nil, 4.5
        for _, survivor in ipairs(survivorsFolder:GetChildren()) do
            if survivor:IsA("Model") then
                local humanoid = survivor:FindFirstChildOfClass("Humanoid")
                local root = survivor:FindFirstChild("HumanoidRootPart")
                if humanoid and humanoid.Health > 0 and root then
                    local dist = (root.Position - myRoot.Position).Magnitude
                    if dist <= closestDist then
                        closestDist = dist
                        closest = survivor
                    end
                end
            end
        end
        return closest
    end

    TrackConnection(RunService.RenderStepped:Connect(function()
        if not State.AutoSlashAimLock or jdSlashIsLocking or not isJDSlashReady() then return end
        local target = getClosestJDSurvivor()
        if target then
            local camera = workspace.CurrentCamera
            local humanoid = target:FindFirstChildOfClass("Humanoid")
            local torso = getJDTorso(target)
            if not camera or not humanoid or humanoid.Health <= 0 or not torso then return end

            fireJDSlashRemote()

            jdSlashSavedCamType = camera.CameraType
            jdSlashSavedCamSubject = camera.CameraSubject
            jdSlashTargetChar = target
            jdSlashLockStartTime = os.clock()
            jdSlashIsLocking = true
        end
    end))

    TrackConnection(RunService.RenderStepped:Connect(function(dt)
        if not State.AutoSlashAimLock or not jdSlashIsLocking then return end

        if not isJDSlashReady() or os.clock() - jdSlashLockStartTime >= 0.35 then
            restoreJDSlashCamera()
            return
        end

        local camera = workspace.CurrentCamera
        local character = jdSlashTargetChar
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local torso = character and getJDTorso(character)

        if not camera or not character or not character.Parent or not humanoid or humanoid.Health <= 0 or not torso then
            restoreJDSlashCamera()
            return
        end

        camera.CameraType = Enum.CameraType.Scriptable
        local desired = CFrame.lookAt(camera.CFrame.Position, AimUtil.Point(torso))
        camera.CFrame = AimUtil.Smooth(camera.CFrame, desired, dt, 0.65)
    end))

    -- 1x1x1x1 Camera Lock Helpers
    local lock1x1Conn = nil
    local function getClosestSurvivorTorsoFor1x1()
        local closest = nil
        local shortest = math.huge
        local survivorsFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Survivors")
        local Camera = workspace.CurrentCamera
        
        if not survivorsFolder then return nil end
        
        for _, survivor in pairs(survivorsFolder:GetChildren()) do
            if survivor:IsA("Model") and survivor ~= LP.Character then
                local torso = survivor:FindFirstChild("Torso")
                    or survivor:FindFirstChild("UpperTorso")
                    or survivor:FindFirstChild("HumanoidRootPart")
                
                if torso then
                    local dist = (Camera.CFrame.Position - torso.Position).Magnitude
                    if dist < shortest then
                        shortest = dist
                        closest = torso
                    end
                end
            end
        end
        return closest
    end

    local function start1x1CameraLock()
        if lock1x1Conn then return end
        local Camera = workspace.CurrentCamera
        Camera.CameraType = Enum.CameraType.Scriptable
        Camera.CameraSubject = nil
        
        lock1x1Conn = RunService.RenderStepped:Connect(function()
            local target = getClosestSurvivorTorsoFor1x1()
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if target and hrp then
                Camera.CFrame = CFrame.lookAt(hrp.Position + Vector3.new(0, 1.5, 0), AimUtil.Point(target))
            end
        end)
    end

    local function stop1x1CameraLock()
        if lock1x1Conn then
            lock1x1Conn:Disconnect()
            lock1x1Conn = nil
        end
        local Camera = workspace.CurrentCamera
        Camera.CameraType = Enum.CameraType.Custom
        if LP.Character then
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                Camera.CameraSubject = hum
            end
        end
    end

    -- Entanglement Cam Lock Loop
    task.spawn(function()
        while ScriptRunning do
            if State.EntanglementCamLock then
                local entanglement = workspace:FindFirstChild("Players")
                    and workspace.Players:FindFirstChild("Killers")
                    and workspace.Players.Killers:FindFirstChild("1x1x1x1")
                    and workspace.Players.Killers["1x1x1x1"]:FindFirstChild("SpeedMultipliers")
                    and workspace.Players.Killers["1x1x1x1"].SpeedMultipliers:FindFirstChild("Entanglement")
                
                if entanglement then
                    start1x1CameraLock()
                else
                    stop1x1CameraLock()
                end
            else
                stop1x1CameraLock()
            end
            task.wait(0.1)
        end
    end)

    -- Mass Infection Cam Lock Loop
    task.spawn(function()
        while ScriptRunning do
            if State.MassInfectionCamLock then
                local massInfection = workspace:FindFirstChild("Players")
                    and workspace.Players:FindFirstChild("Killers")
                    and workspace.Players.Killers:FindFirstChild("1x1x1x1")
                    and workspace.Players.Killers["1x1x1x1"]:FindFirstChild("FOVMultipliers")
                    and workspace.Players.Killers["1x1x1x1"].FOVMultipliers:FindFirstChild("MassInfection")
                
                if massInfection then
                    start1x1CameraLock()
                else
                    stop1x1CameraLock()
                end
            else
                stop1x1CameraLock()
            end
            task.wait(0.1)
        end
    end)

    -- Stamina Engine
    task.spawn(function()
        local staminaModule
        pcall(function()
            local sys = ReplicatedStorage:WaitForChild("Systems", 10)
            local charSys = sys and sys:WaitForChild("Character", 10)
            local gameSys = charSys and charSys:WaitForChild("Game", 10)
            local sprintObj = gameSys and gameSys:WaitForChild("Sprinting", 10)
            if sprintObj then staminaModule = require(sprintObj) end
        end)
        
        while ScriptRunning and task.wait(0.1) do
            if staminaModule then
                pcall(function()
                    if State.EnableCustomSpeed then
                        staminaModule.SprintSpeed = State.SprintSpeedValue
                    end
                    if State.InfiniteStamina then
                        staminaModule.MinStamina = State.MinStaminaValue
                        staminaModule.MaxStamina = State.MaxStaminaValue
                        if staminaModule.StaminaDrain ~= nil then staminaModule.StaminaDrain = State.DrainStaminaValue end
                        if staminaModule.StaminaLoss ~= nil then staminaModule.StaminaLoss = State.DrainStaminaValue end
                        staminaModule.StaminaLossDisabled = false
                        if staminaModule.Stamina and staminaModule.Stamina <= 2 then
                            staminaModule.Stamina = staminaModule.MaxStamina or State.MaxStaminaValue
                        end
                    end
                end)
            end
        end
    end)

    -- Auto Give Orange Food Background Loop
    task.spawn(function()
        local CollectionService = game:GetService("CollectionService")
        local TextChatService = game:GetService("TextChatService")
        local ORANGE_POS = Vector3.new(2055, 152, 10195)
        local FORCE = nil
        local KEYWORDS = {
            { words = { "acid", "sour", "tart" }, fruit = "lemon" },
            { words = { "cool" }, fruit = "passion" },
        }
        local FRUITS = { "lemon", "blueberr", "cherr", "grape", "mango", "orange", "passion", "watermelon" }
        local craving = FORCE
        local holding = nil

        local function setCraving(text)
            if FORCE then return end
            text = text:lower()
            if text:find("plentiful") then
                craving = "any"
                return
            end
            for _, f in ipairs(FRUITS) do
                if text:find(f) then craving = f return end
            end
            for _, e in ipairs(KEYWORDS) do
                for _, w in ipairs(e.words) do
                    if text:find(w) then craving = e.fruit return end
                end
            end
            craving = nil
        end

        pcall(function()
            local old
            old = hookmetamethod(game, "__namecall", function(self, ...)
                if self == TextChatService and getnamecallmethod() == "DisplayBubble" then
                    local _, text = ...
                    if typeof(text) == "string" then task.defer(setCraving, text) end
                end
                return old(self, ...)
            end)
        end)

        local function root()
            local c = LP.Character
            return c and c:FindFirstChild("HumanoidRootPart")
        end

        local function press(p)
            p.HoldDuration = 0
            if fireproximityprompt then
                fireproximityprompt(p)
            else
                p:InputHoldBegin(); task.wait(); p:InputHoldEnd()
            end
        end

        local function tp(pos)
            local r = root()
            if r then r.CFrame = CFrame.new(pos) end
        end

        local function heldTool()
            for _, c in ipairs({ LP.Character, LP:FindFirstChild("Backpack") }) do
                if c then
                    for _, t in ipairs(c:GetChildren()) do
                        if t:IsA("Tool") and t.Name:lower():find("fruit") then return t end
                    end
                end
            end
        end

        local function getOrange()
            local best, bd
            for _, o in ipairs(CollectionService:GetTagged("BINDER_ORANGE")) do
                local d = (o:GetPivot().Position - ORANGE_POS).Magnitude
                if not bd or d < bd then best, bd = o, d end
            end
            if best then return best end
            local m = workspace:FindFirstChild("Mouth", true)
            return m and m:FindFirstAncestorOfClass("Model")
        end

        local function fruitFolder()
            local ok, f = pcall(function()
                return workspace.Map.Ingame.Map.OrangeFruits
            end)
            return ok and f or nil
        end

        while ScriptRunning do
            task.wait(0.5)
            if not State.AutoGiveOrangeFood then continue end
            pcall(function()
                if not root() then return end
                local tool = heldTool()

                if not tool then
                    holding = nil
                    if not craving then return end
                    local folder = fruitFolder()
                    if not folder then return end
                    for _, fruit in ipairs(folder:GetChildren()) do
                        local prompt = fruit:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt and (craving == "any" or prompt.ActionText:lower():find(craving)) then
                            tp(fruit:GetPivot().Position + Vector3.new(0, 3, 0))
                            task.wait(0.25)
                            press(prompt)
                            task.wait(0.5)
                            tool = heldTool()
                            if tool then
                                holding = craving
                                break
                            end
                        end
                    end
                    if not tool then return end
                end

                if craving ~= "any" and holding ~= craving then return end

                local orange = getOrange()
                if not orange then return end
                local hum = LP.Character:FindFirstChildOfClass("Humanoid")
                if hum and tool.Parent ~= LP.Character then hum:EquipTool(tool) end
                tp(orange:GetPivot().Position + Vector3.new(0, 3, 4))
                task.wait(0.3)
                for _, d in ipairs(orange:GetDescendants()) do
                    if d:IsA("ProximityPrompt") then press(d) end
                end
                task.wait(1.5)
                if not heldTool() then
                    holding = nil
                    craving = FORCE
                end
            end)
        end
    end)

    -- Auto Gen (NEW) Background Hooks (FIXED DURATION BUG)
    task.spawn(function()
        pcall(function()
            local RS = game:GetService("ReplicatedStorage")
            local RunService = game:GetService("RunService")

            local SUBMIT_DELAY = 1.0
            local LOCK_MARGIN = 0.33

            local Controller = require(RS.Systems.Player.MinigameController)
            local Boards = RS.Modules.Minigames
            local ConnectBoard = require(Boards.ConnectBoard)
            local FlowBoard = require(Boards.FlowBoard)
            local LockBoard = require(Boards.LockBoard)
            local GearsHandler = require(RS.Systems.Player.Game.Spawners.GearsClientHandler)

            local lastLock
            local origLockNew = LockBoard.new
            LockBoard.new = function(...)
                local b = origLockNew(...)
                lastLock = b
                return b
            end

            local function hookGen(name, handler)
                local mod = Controller:GetMinigame(name)
                if not mod then return end
                local origSession = mod.Session
                rawset(mod, "Session", function(self, ...)
                    local s = origSession(self, ...)
                    local origStart, origStop = s.Start, s.Stop
                    s.Start = function(sess, ...)
                        if origStart then origStart(sess, ...) end
                        task.spawn(function()
                            if not State.AutoGenNew then return end
                            local props = sess.Network.Properties
                            if props:Get("FixerUserId") ~= LP.UserId then return end
                            local ok, err = pcall(handler, sess, props)
                            if not ok then warn("[AutoGen]", name, err) end
                        end)
                    end
                    s.Stop = function(sess, ...)
                        sess.__dead = true
                        if origStop then return origStop(sess, ...) end
                    end
                    return s
                end)
            end

            hookGen("GearClientMinigame", function(s)
                if not State.AutoGenNew then return end
                local ok, n = pcall(function() return GearsHandler:Get() end)
                if ok and n < 1 then return end
                task.wait(State.AutoGenDuration or 3)
                if s.__dead then return end
                s.Network:FireServer("Screwed")
            end)

            hookGen("ConnectClientMinigame", function(s, props)
                if not State.AutoGenNew then return end
                local board = ConnectBoard.new(props:Get("Blobs"))
                for i in pairs(board.Blobs) do
                    local mate = board:GetMate(i)
                    if mate then board:Connect(i, mate) end
                end
                if not board:IsSolved() then return end
                local export = board:Export()
                local ok, why = ConnectBoard.Validate(board.Blobs, export)
                if not ok then return end
                task.wait(State.AutoFarm and (State.AutoGenDuration or 2.57) or SUBMIT_DELAY)
                if s.__dead then return end
                s.Network:FireServer("Submit", export)
            end)

            local function shuffled(list)
                local t = table.clone(list)
                for i = #t, 2, -1 do
                    local j = math.random(i)
                    t[i], t[j] = t[j], t[i]
                end
                return t
            end

            local function solveFlow(size, pairsTbl)
                local neighbors, dotOwner = {}, {}
                for cell = 1, size * size do
                    local r, c = FlowBoard.ToRowCol(size, cell)
                    local list = {}
                    for _, d in ipairs({ {-1, 0}, {1, 0}, {0, -1}, {0, 1} }) do
                        local nr, nc = r + d[1], c + d[2]
                        if nr >= 1 and nr <= size and nc >= 1 and nc <= size then
                            table.insert(list, FlowBoard.ToIndex(size, nr, nc))
                        end
                    end
                    neighbors[cell] = list
                end
                local keys = {}
                for k, p in pairs(pairsTbl) do
                    table.insert(keys, k)
                    dotOwner[p[1]] = k
                    dotOwner[p[2]] = k
                end

                local function attempt(order)
                    local used, result = {}, {}
                    for _, key in ipairs(order) do
                        local a, b = pairsTbl[key][1], pairsTbl[key][2]
                        local prev, queue, head, found = { [a] = false }, { a }, 1, false
                        while head <= #queue and not found do
                            local cur = queue[head]
                            head += 1
                            for _, n in ipairs(shuffled(neighbors[cur])) do
                                if prev[n] == nil then
                                    if n == b then
                                        prev[n] = cur
                                        found = true
                                        break
                                    end
                                    if not used[n] and not dotOwner[n] then
                                        prev[n] = cur
                                        queue[#queue + 1] = n
                                    end
                                end
                            end
                        end
                        if not found then return nil end
                        local path, cur = {}, b
                        while cur do
                            table.insert(path, 1, cur)
                            cur = prev[cur]
                        end
                        for _, cell in ipairs(path) do used[cell] = true end
                        result[key] = path
                    end
                    return result
                end

                for i = 1, 5000 do
                    local sol = attempt(shuffled(keys))
                    if sol then return sol end
                    if i % 100 == 0 then task.wait() end
                end
            end

            hookGen("FlowClientMinigame", function(s, props)
                if not State.AutoGenNew then return end
                local board = FlowBoard.new(props:Get("GridSize"), props:Get("Pairs"))
                local sol = solveFlow(board.Size, board.Pairs)
                if not sol then return end
                for k, path in pairs(sol) do board.Paths[k] = path end
                board:__rebuild()
                if not board:IsSolved() then return end
                local export = board:Export()
                local ok, why = FlowBoard.Validate(board.Size, board.Pairs, export)
                if not ok then return end
                task.wait(State.AutoFarm and (State.AutoGenDuration or 2.57) or SUBMIT_DELAY)
                if s.__dead then return end
                s.Network:FireServer("Submit", export)
            end)

            hookGen("LockClientMinigame", function(s, props)
                if not State.AutoGenNew then return end
                task.wait(0.3)
                local board = lastLock
                if not board then
                    board = LockBoard.new(props:Get("Config"))
                    local st = props:Get("State")
                    if type(st) == "table" and st.Presses then board:Apply(st) end
                end
                local cfg = board.Config
                while State.AutoGenNew and not s.__dead and not board:IsBroken() do
                    local now = workspace:GetServerTimeNow()
                    if now >= cfg.StartTime then
                        local angle = board:AngleAt(now)
                        local d = (angle - board.State.Target) % 360
                        d = math.min(d, 360 - d)
                        if d <= cfg.TargetSize * LOCK_MARGIN then
                            local res = board:Press(now)
                            if res then
                                s.Network:FireServer("Press", now)
                                pcall(function() s.__renderer:Play(res) end)
                            end
                        end
                    end
                    RunService.Heartbeat:Wait()
                end
            end)
        end)
    end)

    -- Auto Use Inspiration Loop (Helperbot)
    task.spawn(function()
        local remote = ReplicatedStorage:WaitForChild("Modules", 10)
        remote = remote and remote:WaitForChild("Network", 10)
        remote = remote and remote:WaitForChild("Network", 10)
        remote = remote and remote:WaitForChild("RemoteEvent", 10)

        local playersFolder = workspace:FindFirstChild("Players")
        local survivors = playersFolder and playersFolder:FindFirstChild("Survivors")

        local data = string.char(3, 11, 0, 0, 0) .. "Inspiration"
        local RANGE, COOLDOWN = 25, 2
        local lastUse = 0

        while ScriptRunning do
            task.wait(0.1)
            if not State.AutoUseInspiration then continue end
            if not (remote and survivors) then continue end
            local char = LP.Character
            if char then
                local myPos = char:GetPivot().Position
                for _, s in ipairs(survivors:GetChildren()) do
                    if s ~= char and s:IsA("Model") then
                        local dist = (s:GetPivot().Position - myPos).Magnitude
                        if dist <= RANGE and os.clock() - lastUse >= COOLDOWN then
                            lastUse = os.clock()
                            pcall(function()
                                remote:FireServer("UseActorAbility", { buffer.fromstring(data) })
                            end)
                            break
                        end
                    end
                end
            end
        end
    end)

    -- Auto Use Pulse When Survivor Has Low Health Loop
    task.spawn(function()
        local function getRemote()
            return ReplicatedStorage:WaitForChild("Modules")
                :WaitForChild("Network")
                :WaitForChild("Network")
                :WaitForChild("RemoteEvent")
        end

        while ScriptRunning do
            task.wait(0.2)
            if not State.AutoPulseLowHealth then continue end
            pcall(function()
                local remote = getRemote()
                local survivorsFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Survivors")
                if not survivorsFolder or not remote then return end

                local threshold = State.PulseHealthThreshold or 50
                local foundLowHealth = false

                for _, survivor in ipairs(survivorsFolder:GetChildren()) do
                    if survivor:IsA("Model") then
                        local hum = survivor:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 and hum.Health < threshold then
                            foundLowHealth = true
                            break
                        end
                    end
                end

                if foundLowHealth then
                    remote:FireServer("UseActorAbility", { buffer.fromstring("\3\5\0\0\0Pulse") })
                    task.wait(2.5)
                end
            end)
        end
    end)

    -- Pulse Server Crasher/Lagger Loop
    task.spawn(function()
        while ScriptRunning do
            task.wait(0.01)
            if State.PulseCrasher then
                for i = 1, 777 do
                    pcall(function()
                        game:GetService("ReplicatedStorage").Modules.Network.Network.RemoteEvent:FireServer("UseActorAbility", { buffer.fromstring("\3\5\0\0\0Pulse") })
                    end)
                end
            end
        end
    end)

    -- Anti Hand Slowdown Loop
    task.spawn(function()
        while ScriptRunning do
            task.wait(5)
            if State.AntiHandSlowdown then
                pcall(function()
                    local arms = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Ingame") and Workspace.Map.Ingame:FindFirstChild("Map") and Workspace.Map.Ingame.Map:FindFirstChild("Slowdown") and Workspace.Map.Ingame.Map.Slowdown:FindFirstChild("Arms")
                    if arms then arms:Destroy() end
                end)
            end
        end
    end)

    -- Anti Bait (Block) for Guest 1337 Loop
    task.spawn(function()
        while ScriptRunning do
            task.wait(0.05)
            if not State.AntiBaitBlock then continue end
            pcall(function()
                local playerGui = LP:WaitForChild("PlayerGui")
                local survivors = workspace:WaitForChild("Players"):WaitForChild("Survivors")
                local TARGET_VALUE = 100
                local MAX_DISTANCE = 20
                local abilityContainer = playerGui:FindFirstChild("MainUI") and playerGui.MainUI:FindFirstChild("AbilityContainer")
                local character = LP.Character
                local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
                local guest = survivors:FindFirstChild("Guest1337")
                local guestRoot = guest and guest:FindFirstChild("HumanoidRootPart")
                local multipliers = guest and guest:FindFirstChild("ResistanceMultipliers")
                local status = multipliers and multipliers:FindFirstChild("ResistanceStatus")

                local shouldHide = playerRoot
                    and guestRoot
                    and status
                    and status.Value == TARGET_VALUE
                    and (playerRoot.Position - guestRoot.Position).Magnitude <= MAX_DISTANCE

                if abilityContainer then
                    abilityContainer.Visible = not shouldHide
                end
            end)
        end
    end)

    -- AutoDisarm Loop for Azure Vines
    task.spawn(function()
        pcall(function()
            local RS = game:GetService("ReplicatedStorage")
            local RunService = game:GetService("RunService")
            local CONFIG = {
                Enabled = true,
                Debug = false,
                Margin = 0.015,
                MinGap = 0.25,
            }
            local qte = require(RS:WaitForChild("Assets"):WaitForChild("Killers"):WaitForChild("Azure")
                :WaitForChild("Config"):WaitForChild("cl_WorkaroundModules"):WaitForChild("cl_ConstructQTE"))
            local rng = Random.new()
            local function newBounds()
                for _ = 1, 30 do
                    local t = {}
                    for _ = 1, 3 do
                        local s = rng:NextNumber(0.05, 0.8)
                        table.insert(t, NumberRange.new(s, s + 0.15))
                    end
                    table.sort(t, function(a, b) return a.Min < b.Min end)
                    local ok = true
                    for j = 2, #t do
                        if t[j].Min - t[j - 1].Max < 0.09 then ok = false break end
                    end
                    if ok then return t end
                end
                return { NumberRange.new(0.16, 0.31), NumberRange.new(0.46, 0.61), NumberRange.new(0.76, 0.91) }
            end
            local function zoneAt(obj)
                local v = obj.Value
                for i, r in ipairs(obj.QTEBounds) do
                    if not obj.CompletedZones[i] and v >= r.Min + CONFIG.Margin and v <= r.Max - CONFIG.Margin then
                        return i
                    end
                end
            end
            local function press(obj, idx)
                obj.CompletedZones[idx] = true
                obj.MarkerSpeedBoost = 4
                obj.Clicked = false
                if obj.UI and obj.UI.PlayHitSound then obj.UI:PlayHitSound() end
                local n = 0
                for _, done in pairs(obj.CompletedZones) do
                    if done then n += 1 end
                end
                if n >= 3 then
                    obj.QTEBounds = newBounds()
                    table.clear(obj.CompletedZones)
                    obj.MarkerSpeedBoost = 0
                    obj:AddProgress(100 / 3)
                end
            end
            local function solve(obj)
                local last = 0
                local conn
                conn = RunService.RenderStepped:Connect(function()
                    if not State.AutoDisarmVines then conn:Disconnect() return end
                    if not obj.QTEBounds or not obj.CompletedZones then
                        conn:Disconnect()
                        return
                    end
                    if os.clock() - last < CONFIG.MinGap then return end
                    local idx = zoneAt(obj)
                    if idx then
                        last = os.clock()
                        press(obj, idx)
                    end
                end)
            end
            local origNew = qte.new
            qte.new = function(...)
                local obj = origNew(...)
                if obj and State.AutoDisarmVines then task.spawn(solve, obj) end
                return obj
            end
        end)
    end)

    -- Azure Auto Hit Survivors Loop
    task.spawn(function()
        local LOCK_DURATION = 0.8
        local locking = false
        local lockUntil = 0
        local targetPart = nil

        local function isCooldownReady()
            local success, slash = pcall(function()
                return LP.PlayerGui.MainUI.AbilityContainer.Slash
            end)
            if not success or not slash then return false end
            local cooldown = slash:FindFirstChild("CooldownTime")
            if cooldown and cooldown:IsA("TextLabel") then
                return cooldown.Text == "" or cooldown.Text == nil
            end
            return true
        end

        local function getClosestSurvivor()
            local folder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Survivors")
            if not folder then return nil end
            local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if not myRoot then return nil end
            local closest, closestDist = nil, State.AzureHitRange or 7.1
            for _, survivor in pairs(folder:GetChildren()) do
                local root = survivor:FindFirstChild("HumanoidRootPart") or survivor.PrimaryPart
                if root then
                    local dist = (root.Position - myRoot.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closest = root
                    end
                end
            end
            return closest
        end

        while ScriptRunning do
            RunService.RenderStepped:Wait()
            if not State.AzureAutoHit then continue end
            if locking then
                if tick() > lockUntil or not targetPart or not targetPart.Parent then
                    locking = false
                    targetPart = nil
                    continue
                end
                local camPos = Workspace.CurrentCamera.CFrame.Position
                Workspace.CurrentCamera.CFrame = CFrame.lookAt(camPos, AimUtil.Point(targetPart))
                continue
            end

            if not isCooldownReady() then continue end

            local target = getClosestSurvivor()
            if target then
                locking = true
                targetPart = target
                lockUntil = tick() + LOCK_DURATION
                local remote = GetRemoteEvent()
                if remote then
                    remote:FireServer("UseActorAbility", { buffer.fromstring("\3\5\0\0\0Slash") })
                end
            end
        end
    end)

    -- Azure Auto Grab and Shoot Loop
    task.spawn(function()
        local GRAB_DELAY = 0.3
        local TOTAL_DURATION = 0.9
        local busy = false

        local function getGrabButton()
            local playerGui = LP:FindFirstChild("PlayerGui")
            local mainUI = playerGui and playerGui:FindFirstChild("MainUI")
            local container = mainUI and mainUI:FindFirstChild("AbilityContainer")
            local grab = container and container:FindFirstChild("Grab")
            if grab and grab:IsA("ImageButton") then return grab end
            return nil
        end

        local function isGrabReady()
            local grab = getGrabButton()
            if not grab then return false end
            for _, obj in ipairs(grab:GetDescendants()) do
                if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                    return obj.Text:match("^%s*$") ~= nil
                end
            end
            return false
        end

        local function getNearestSurvivor()
            local character = LP.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if not root then return nil end
            local playersFolder = workspace:FindFirstChild("Players")
            local survivors = playersFolder and playersFolder:FindFirstChild("Survivors")
            if not survivors then return nil end
            local nearest, nearestDistance = nil, State.AzureGrabRange or 26
            for _, survivor in ipairs(survivors:GetChildren()) do
                local targetRoot = survivor:FindFirstChild("HumanoidRootPart")
                local humanoid = survivor:FindFirstChildOfClass("Humanoid")
                if targetRoot and humanoid and humanoid.Health > 0 then
                    local distance = (targetRoot.Position - root.Position).Magnitude
                    if distance < nearestDistance then
                        nearest = targetRoot
                        nearestDistance = distance
                    end
                end
            end
            return nearest
        end

        local function useAbility(name)
            local remote = GetRemoteEvent()
            if not remote then return end
            local payload
            if name == "Grab" then
                payload = buffer.fromstring("\3\4\0\0\0Grab")
            elseif name == "Slash" then
                payload = buffer.fromstring("\3\5\0\0\0Slash")
            else
                return
            end
            remote:FireServer("UseActorAbility", {payload})
        end

        local function aimAt(target)
            if not target or not target.Parent then return end
            local camera = workspace.CurrentCamera
            if not camera then return end
            camera.CFrame = CFrame.lookAt(camera.CFrame.Position, AimUtil.Point(target))
        end

        local function runCombo(target)
            if busy or not isGrabReady() then return end
            busy = true
            pcall(function()
                local started = os.clock()
                useAbility("Grab")
                while os.clock() - started < GRAB_DELAY do
                    if not target.Parent then break end
                    aimAt(target)
                    RunService.RenderStepped:Wait()
                end
                useAbility("Slash")
                while os.clock() - started < TOTAL_DURATION do
                    if not target.Parent then break end
                    aimAt(target)
                    RunService.RenderStepped:Wait()
                end
            end)
            busy = false
        end

        while ScriptRunning do
            RunService.Heartbeat:Wait()
            if not State.AzureAutoGrab then continue end
            if busy or not isGrabReady() then continue end
            local target = getNearestSurvivor()
            if target then
                task.spawn(runCombo, target)
            end
        end
    end)

    -- Nosferatu New Feature: Auto Lacerate (Slash)
    task.spawn(function()
        local locking = false
        local lockUntil = 0
        local targetPart = nil

        local function isCooldownReady()
            local success, ability = pcall(function()
                return LP.PlayerGui.MainUI.AbilityContainer.Slash
            end)
            if not success or not ability then return false end
            local cooldown = ability:FindFirstChild("CooldownTime")
            if cooldown and cooldown:IsA("TextLabel") then
                return cooldown.Text == "" or cooldown.Text == nil
            end
            return true
        end

        local function getClosestSurvivor()
            local folder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Survivors")
            if not folder then return nil end
            local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if not myRoot then return nil end
            local closest, closestDist = nil, State.NosLacerateRange or 7.5
            for _, survivor in pairs(folder:GetChildren()) do
                local root = survivor:FindFirstChild("HumanoidRootPart") or survivor.PrimaryPart
                if root then
                    local dist = (root.Position - myRoot.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closest = root
                    end
                end
            end
            return closest
        end

        while ScriptRunning do
            RunService.RenderStepped:Wait()
            if not State.NosAutoLacerate then continue end
            if locking then
                if tick() > lockUntil or not targetPart or not targetPart.Parent then
                    locking = false
                    targetPart = nil
                else
                    local camPos = Workspace.CurrentCamera.CFrame.Position
                    Workspace.CurrentCamera.CFrame = CFrame.lookAt(camPos, AimUtil.Point(targetPart))
                end
                continue
            end

            if not isCooldownReady() then continue end
            local target = getClosestSurvivor()
            if target then
                locking = true
                targetPart = target
                lockUntil = tick() + 0.8
                local remote = GetRemoteEvent()
                if remote then
                    remote:FireServer("UseActorAbility", { buffer.fromstring("\3\5\0\0\0Slash") })
                end
            end
        end
    end)

    -- Nosferatu New Feature: Auto Bloodhook (Uppercut)
    task.spawn(function()
        local locking = false
        local lockUntil = 0
        local targetPart = nil

        local function isCooldownReady()
            local success, ability = pcall(function()
                return LP.PlayerGui.MainUI.AbilityContainer.Uppercut
            end)
            if not success or not ability then return false end
            local cooldown = ability:FindFirstChild("CooldownTime")
            if cooldown and cooldown:IsA("TextLabel") then
                return cooldown.Text == "" or cooldown.Text == nil
            end
            return true
        end

        local function getClosestSurvivor()
            local folder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Survivors")
            if not folder then return nil end
            local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if not myRoot then return nil end
            local closest, closestDist = nil, State.NosBloodhookRange or 50
            for _, survivor in pairs(folder:GetChildren()) do
                local root = survivor:FindFirstChild("HumanoidRootPart") or survivor.PrimaryPart
                if root then
                    local dist = (root.Position - myRoot.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closest = root
                    end
                end
            end
            return closest
        end

        while ScriptRunning do
            RunService.RenderStepped:Wait()
            if not State.NosAutoBloodhook then continue end
            if locking then
                if tick() > lockUntil or not targetPart or not targetPart.Parent then
                    locking = false
                    targetPart = nil
                else
                    local camPos = Workspace.CurrentCamera.CFrame.Position
                    Workspace.CurrentCamera.CFrame = CFrame.lookAt(camPos, AimUtil.Point(targetPart))
                end
                continue
            end

            if not isCooldownReady() then continue end
            local target = getClosestSurvivor()
            if target then
                locking = true
                targetPart = target
                lockUntil = tick() + 0.8
                local remote = GetRemoteEvent()
                if remote then
                    remote:FireServer("UseActorAbility", { buffer.fromstring("\3\8\0\0\0Uppercut") })
                end
            end
        end
    end)

    -- Nosferatu New Feature: Auto Hunters Feast (Bats)
    task.spawn(function()
        local locking = false
        local lockUntil = 0
        local targetPart = nil

        local function isCooldownReady()
            local success, ability = pcall(function()
                return LP.PlayerGui.MainUI.AbilityContainer.Bats
            end)
            if not success or not ability then return false end
            local cooldown = ability:FindFirstChild("CooldownTime")
            if cooldown and cooldown:IsA("TextLabel") then
                return cooldown.Text == "" or cooldown.Text == nil
            end
            return true
        end

        local function getClosestSurvivor()
            local folder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Survivors")
            if not folder then return nil end
            local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if not myRoot then return nil end
            local closest, closestDist = nil, State.NosHuntersFeastRange or 26.5
            for _, survivor in pairs(folder:GetChildren()) do
                local root = survivor:FindFirstChild("HumanoidRootPart") or survivor.PrimaryPart
                if root then
                    local dist = (root.Position - myRoot.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closest = root
                    end
                end
            end
            return closest
        end

        while ScriptRunning do
            RunService.RenderStepped:Wait()
            if not State.NosAutoHuntersFeast then continue end
            if locking then
                if tick() > lockUntil or not targetPart or not targetPart.Parent then
                    locking = false
                    targetPart = nil
                else
                    local camPos = Workspace.CurrentCamera.CFrame.Position
                    Workspace.CurrentCamera.CFrame = CFrame.lookAt(camPos, AimUtil.Point(targetPart))
                end
                continue
            end

            if not isCooldownReady() then continue end
            local target = getClosestSurvivor()
            if target then
                locking = true
                targetPart = target
                lockUntil = tick() + 0.8
                local remote = GetRemoteEvent()
                if remote then
                    remote:FireServer("UseActorAbility", { buffer.fromstring("\3\4\0\0\0Bats") })
                end
            end
        end
    end)

    -- Dusekkar Aimbot Loops (Survivors & Killers)
    task.spawn(function()
        RunService.RenderStepped:Connect(function()
            if State.DusekkarSurvivorAim then
                pcall(function()
                    if LP.Character and LP.Character.Name == "Dusekkar" then
                        local pb = workspace.Players.Survivors.Dusekkar.SpeedMultipliers:FindFirstChild("PlasmaBeam")
                        if pb then
                            local folder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Survivors")
                            if folder then
                                local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                                if myRoot then
                                    local closest, closestDist = nil, math.huge
                                    for _, survivor in pairs(folder:GetChildren()) do
                                        if survivor ~= LP.Character then
                                            local root = survivor:FindFirstChild("HumanoidRootPart") or survivor.PrimaryPart
                                            if root then
                                                local dist = (root.Position - myRoot.Position).Magnitude
                                                if dist < closestDist then
                                                    closestDist = dist
                                                    closest = root
                                                end
                                            end
                                        end
                                    end
                                    if closest then
                                        local camPos = Workspace.CurrentCamera.CFrame.Position
                                        Workspace.CurrentCamera.CFrame = CFrame.lookAt(camPos, AimUtil.Point(closest))
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end)
    end)

    task.spawn(function()
        RunService.RenderStepped:Connect(function()
            if State.DusekkarKillerAim then
                pcall(function()
                    if LP.Character and LP.Character.Name == "Dusekkar" then
                        local pb = workspace.Players.Survivors.Dusekkar.SpeedMultipliers:FindFirstChild("PlasmaBeam")
                        if pb then
                            local folder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers")
                            if folder then
                                local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                                if myRoot then
                                    local closest, closestDist = nil, math.huge
                                    for _, killer in pairs(folder:GetChildren()) do
                                        local root = killer:FindFirstChild("HumanoidRootPart") or killer.PrimaryPart
                                        if root then
                                            local dist = (root.Position - myRoot.Position).Magnitude
                                            if dist < closestDist then
                                                closestDist = dist
                                                closest = root
                                            end
                                        end
                                    end
                                    if closest then
                                        local camPos = Workspace.CurrentCamera.CFrame.Position
                                        Workspace.CurrentCamera.CFrame = CFrame.lookAt(camPos, AimUtil.Point(closest))
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end)
    end)

    -- Sixer / Guest 666 New Features: Carving Slash, Pursuit Aimbot, Infernal Cry
    task.spawn(function()
        local locking = false
        local lockUntil = 0
        local targetPart = nil

        local function isCooldownReady()
            local success, ability = pcall(function()
                return LP.PlayerGui.MainUI.AbilityContainer["Carving Slash"]
            end)
            if not success or not ability then return false end
            local cooldown = ability:FindFirstChild("CooldownTime")
            if cooldown and cooldown:IsA("TextLabel") then
                return cooldown.Text == "" or cooldown.Text == nil
            end
            return true
        end

        local function getClosestSurvivor()
            local folder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Survivors")
            if not folder then return nil end
            local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if not myRoot then return nil end
            local closest, closestDist = nil, State.SixerCarvingRange or 7.1
            for _, survivor in pairs(folder:GetChildren()) do
                local root = survivor:FindFirstChild("HumanoidRootPart") or survivor.PrimaryPart
                if root then
                    local dist = (root.Position - myRoot.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closest = root
                    end
                end
            end
            return closest
        end

        while ScriptRunning do
            RunService.RenderStepped:Wait()
            if not State.SixerCarvingSlash then continue end
            if locking then
                if tick() > lockUntil or not targetPart or not targetPart.Parent then
                    locking = false
                    targetPart = nil
                else
                    local camPos = Workspace.CurrentCamera.CFrame.Position
                    Workspace.CurrentCamera.CFrame = CFrame.lookAt(camPos, AimUtil.Point(targetPart))
                end
                continue
            end

            if not isCooldownReady() then continue end
            local target = getClosestSurvivor()
            if target then
                locking = true
                targetPart = target
                lockUntil = tick() + 0.8
                local remote = GetRemoteEvent()
                if remote then
                    remote:FireServer("UseActorAbility", { buffer.fromstring("\3\r\0\0\0Carving Slash") })
                end
            end
        end
    end)

    task.spawn(function()
        RunService.RenderStepped:Connect(function()
            if State.SixerPursuitAimbot then
                pcall(function()
                    local ok, obj = pcall(function()
                        return workspace.Players.Killers.Sixer.SpeedMultipliers:FindFirstChild("666PursuitStart")
                    end)
                    if ok and obj then
                        local folder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Survivors")
                        if folder then
                            local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                            if myRoot then
                                local closest, closestDist = nil, math.huge
                                for _, survivor in pairs(folder:GetChildren()) do
                                    local root = survivor:FindFirstChild("HumanoidRootPart") or survivor.PrimaryPart
                                    if root then
                                        local dist = (root.Position - myRoot.Position).Magnitude
                                        if dist < closestDist then
                                            closestDist = dist
                                            closest = root
                                        end
                                    end
                                end
                                if closest then
                                    local camPos = Workspace.CurrentCamera.CFrame.Position
                                    Workspace.CurrentCamera.CFrame = CFrame.lookAt(camPos, AimUtil.Point(closest))
                                end
                            end
                        end
                    end
                end)
            end
        end)
    end)

    task.spawn(function()
        local hasFired = false
        RunService.RenderStepped:Connect(function()
            if not State.SixerInfernalCryAuto then
                hasFired = false
                return
            end
            pcall(function()
                local ok, obj = pcall(function()
                    return workspace.Players.Killers.Sixer.SpeedMultipliers:FindFirstChild("666CryCast")
                end)
                if not ok or not obj then
                    hasFired = false
                    return
                end

                local folder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Survivors")
                if folder then
                    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    if myRoot then
                        local closest, closestDist = nil, math.huge
                        for _, survivor in pairs(folder:GetChildren()) do
                            local root = survivor:FindFirstChild("HumanoidRootPart") or survivor.PrimaryPart
                            if root then
                                local dist = (root.Position - myRoot.Position).Magnitude
                                if dist < closestDist then
                                    closestDist = dist
                                    closest = root
                                end
                            end
                        end
                        if closest then
                            local camPos = Workspace.CurrentCamera.CFrame.Position
                            Workspace.CurrentCamera.CFrame = CFrame.lookAt(camPos, AimUtil.Point(closest))
                        end
                    end
                end

                if not hasFired then
                    local success, ability = pcall(function()
                        return LP.PlayerGui.MainUI.AbilityContainer.InfernalCry
                    end)
                    if success and ability then
                        local cooldown = ability:FindFirstChild("CooldownTime")
                        local isReady = not cooldown or not cooldown:IsA("TextLabel") or cooldown.Text == ""
                        if isReady then
                            local remote = GetRemoteEvent()
                            if remote then
                                remote:FireServer("UseActorAbility", { buffer.fromstring("\3\11\0\0\0InfernalCry") })
                                hasFired = true
                            end
                        end
                    end
                end
            end)
        end)
    end)

    task.spawn(function()
        RunService.RenderStepped:Connect(function()
            if State.SixerInfernalCryAim then
                pcall(function()
                    local ok, obj = pcall(function()
                        return workspace.Players.Killers.Sixer.SpeedMultipliers:FindFirstChild("666CryCast")
                    end)
                    if ok and obj then
                        local folder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Survivors")
                        if folder then
                            local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                            if myRoot then
                                local closest, closestDist = nil, math.huge
                                for _, survivor in pairs(folder:GetChildren()) do
                                    local root = survivor:FindFirstChild("HumanoidRootPart") or survivor.PrimaryPart
                                    if root then
                                        local dist = (root.Position - myRoot.Position).Magnitude
                                        if dist < closestDist then
                                            closestDist = dist
                                            closest = root
                                        end
                                    end
                                end
                                if closest then
                                    local camPos = Workspace.CurrentCamera.CFrame.Position
                                    Workspace.CurrentCamera.CFrame = CFrame.lookAt(camPos, AimUtil.Point(closest))
                                end
                            end
                        end
                    end
                end)
            end
        end)
    end)

    -- Visual ESP Master Loop
    task.spawn(function()
        while ScriptRunning and task.wait(0.4) do
            pcall(function()
                local pf = Workspace:FindFirstChild("Players")
                if pf then
                    local kf = pf:FindFirstChild("Killers")
                    local sf = pf:FindFirstChild("Survivors")
                    
                    if kf then
                        for _, k in ipairs(kf:GetChildren()) do
                            if k ~= LP.Character and not IsRagdoll(k) then
                                if State.KillerESP then CreateHighlight(k, State.SelectedColor, "Killer_ESP") else RemoveHighlight(k, "Killer_ESP") end
                                if State.KillerNameESP then CreateBillboardText(k, k.Name, "KillerName_ESP") else RemoveBillboardText(k, "KillerName_ESP") end
                            end
                        end
                    end
                    
                    if sf then
                        for _, s in ipairs(sf:GetChildren()) do
                            if s ~= LP.Character and not IsRagdoll(s) then
                                local hum = s:FindFirstChildOfClass("Humanoid")
                                if State.EspInjuredPlayers and hum and hum.Health < 60 then
                                    CreateHighlight(s, Color3.fromRGB(0, 255, 0), "Injured_ESP")
                                else
                                    RemoveHighlight(s, "Injured_ESP")
                                end

                                if State.SurvivorESP then CreateHighlight(s, Color3.fromRGB(100, 255, 100), "Survivor_ESP") else RemoveHighlight(s, "Survivor_ESP") end
                                if State.SurvivorNameESP then CreateBillboardText(s, s.Name, "SurvivorName_ESP") else RemoveBillboardText(s, "SurvivorName_ESP") end
                            end
                        end
                    end
                end

                local ingame = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Ingame")
                if ingame then
                    local gearsTestFolder = ingame:FindFirstChild("Map") and ingame.Map:FindFirstChild("GearsTest")
                    if gearsTestFolder then
                        for _, child in ipairs(gearsTestFolder:GetChildren()) do
                            if child.Name == "Gear" then
                                if State.EspGears then
                                    CreateHighlight(child, Color3.fromRGB(128, 128, 128), "Gear_ESP")
                                else
                                    RemoveHighlight(child, "Gear_ESP")
                                end
                                if State.GearNameESP then
                                    CreateBillboardText(child, "Gear", "GearName_ESP", Color3.fromRGB(128, 128, 128))
                                else
                                    RemoveBillboardText(child, "GearName_ESP")
                                end
                            end
                        end
                    end

                    local fakeNoliObj = ingame:FindFirstChild("TheEvilNoliOOOOO")
                    if fakeNoliObj then
                        if State.EspFakeNoli then
                            CreateHighlight(fakeNoliObj, Color3.fromRGB(0, 0, 255), "FakeNoli_ESP")
                        else
                            RemoveHighlight(fakeNoliObj, "FakeNoli_ESP")
                        end
                        if State.FakeNoliNameESP then
                            CreateBillboardText(fakeNoliObj, "fake noli!!!", "FakeNoliName_ESP", Color3.fromRGB(0, 0, 255))
                        else
                            RemoveBillboardText(fakeNoliObj, "FakeNoliName_ESP")
                        end
                    end

                    for i = #MapCache.Pizzas, 1, -1 do
                        local pizzaObj = MapCache.Pizzas[i]
                        if not pizzaObj or not pizzaObj.Parent then
                            table.remove(MapCache.Pizzas, i)
                        else
                            if State.EspElliotPizza then
                                CreateHighlight(pizzaObj, Color3.fromRGB(255, 255, 0), "ElliotPizza_ESP")
                            else
                                RemoveHighlight(pizzaObj, "ElliotPizza_ESP")
                            end
                        end
                    end

                    for i = #MapCache.Swords1x1, 1, -1 do
                        local swordObj = MapCache.Swords1x1[i]
                        if not swordObj or not swordObj.Parent then
                            table.remove(MapCache.Swords1x1, i)
                        else
                            if State.Esp1x1Swords then
                                CreateHighlight(swordObj, Color3.fromRGB(0, 255, 0), "Sword1x1_ESP")
                            else
                                RemoveHighlight(swordObj, "Sword1x1_ESP")
                            end
                        end
                    end

                    for i = #MapCache.Shockwaves1x1, 1, -1 do
                        local shockObj = MapCache.Shockwaves1x1[i]
                        if not shockObj or not shockObj.Parent then
                            table.remove(MapCache.Shockwaves1x1, i)
                        else
                            if State.Esp1x1Shockwave then
                                CreateHighlight(shockObj, Color3.fromRGB(0, 255, 0), "Shockwave1x1_ESP")
                            else
                                RemoveHighlight(shockObj, "Shockwave1x1_ESP")
                            end
                        end
                    end

                    for i = #MapCache.Clones007, 1, -1 do
                        local clone007 = MapCache.Clones007[i]
                        if not clone007 or not clone007.Parent then
                            table.remove(MapCache.Clones007, i)
                        else
                            if State.Esp007n7Clones then
                                local highlight = clone007:FindFirstChild("CatboyRedHighlight")
                                if not highlight then
                                    highlight = Instance.new("Highlight")
                                    highlight.Name = "CatboyRedHighlight"
                                    highlight.Adornee = clone007
                                    highlight.Parent = clone007
                                end
                                highlight.FillColor = Color3.fromRGB(255, 0, 0)
                                highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
                                highlight.FillTransparency = 0.4
                                highlight.OutlineTransparency = 0
                            else
                                RemoveHighlight(clone007, "CatboyRedHighlight")
                            end

                            if State.Fake007n7NameESP then
                                CreateBillboardText(clone007, "fake", "Fake007n7Name_ESP", Color3.fromRGB(255, 0, 0))
                            else
                                RemoveBillboardText(clone007, "Fake007n7Name_ESP")
                            end
                        end
                    end

                    for i = #MapCache.JohnDoeDF, 1, -1 do
                        local obj = MapCache.JohnDoeDF[i]
                        if not obj or not obj.Parent then
                            table.remove(MapCache.JohnDoeDF, i)
                        else
                            if State.EspJohnDoesDF then
                                CreateHighlight(obj, Color3.fromRGB(120, 0, 0), "JohnDoeDF_ESP")
                            else
                                RemoveHighlight(obj, "JohnDoeDF_ESP")
                            end
                            if State.JohnDoesDFNameESP then
                                CreateBillboardText(obj, "Shadow", "JohnDoeDFName_ESP", Color3.fromRGB(120, 0, 0))
                            else
                                RemoveBillboardText(obj, "JohnDoeDFName_ESP")
                            end
                        end
                    end

                    local sentryObj = ingame:FindFirstChild("BuildermanSentry")
                    if sentryObj then
                        if State.EspBuildermanSentries then CreateHighlight(sentryObj, Color3.fromRGB(128, 128, 128), "Sentry_ESP") else RemoveHighlight(sentryObj, "Sentry_ESP") end
                        if State.SentriesNameESP then CreateBillboardText(sentryObj, "Sentry", "SentryName_ESP", Color3.fromRGB(128, 128, 128)) else RemoveBillboardText(sentryObj, "SentryName_ESP") end
                    end

                    local dispenserObj = ingame:FindFirstChild("BuildermanDispenser")
                    if dispenserObj then
                        if State.EspBuildermanDispensers then CreateHighlight(dispenserObj, Color3.fromRGB(255, 105, 180), "Dispenser_ESP") else RemoveHighlight(dispenserObj, "Dispenser_ESP") end
                        if State.DispensersNameESP then CreateBillboardText(dispenserObj, "Dispenser", "DispenserName_ESP", Color3.fromRGB(255, 105, 180)) else RemoveBillboardText(dispenserObj, "DispenserName_ESP") end
                    end

                    for i = #MapCache.SpecialESP, 1, -1 do
                        local obj = MapCache.SpecialESP[i]
                        if not obj or not obj.Parent then
                            table.remove(MapCache.SpecialESP, i)
                        else
                            if obj.Name == "GroundBulbModel" then
                                if State.AzureBulbESP then CreateHighlight(obj, Color3.fromRGB(160, 32, 240), "AzureBulb_ESP") else RemoveHighlight(obj, "AzureBulb_ESP") end
                                if State.AzureBulbNameESP then CreateBillboardText(obj, "Azure Bulb", "AzureBulbName_ESP") else RemoveBillboardText(obj, "AzureBulbName_ESP") end
                            elseif obj.Name == "VineModel" then
                                if State.AzureVineESP then CreateHighlight(obj, Color3.fromRGB(160, 32, 240), "AzureVine_ESP") else RemoveHighlight(obj, "AzureVine_ESP") end
                                if State.AzureVineNameESP then CreateBillboardText(obj, "Azure Vine", "AzureVineName_ESP") else RemoveBillboardText(obj, "AzureVineName_ESP") end
                            elseif obj.Name:find("TaphTripwire") then
                                if State.TaphTripwireESP then CreateHighlight(obj, Color3.fromRGB(255, 0, 0), "Tripwire_ESP") else RemoveHighlight(obj, "Tripwire_ESP") end
                                if State.TripwireNameESP then CreateBillboardText(obj, "Taph Tripwire", "TripwireName_ESP") else RemoveBillboardText(obj, "TripwireName_ESP") end
                            elseif obj.Name == "SubspaceTripmine" then
                                if State.SubspaceTripmineESP then CreateHighlight(obj, Color3.fromRGB(255, 0, 0), "Subspace_ESP") else RemoveHighlight(obj, "Subspace_ESP") end
                                if State.SubspaceNameESP then CreateBillboardText(obj, "Subspace Tripmine", "SubspaceName_ESP") else RemoveBillboardText(obj, "SubspaceName_ESP") end
                            elseif obj.Name:find(" Grafitti") or obj.Name:find("Grafitti") then
                                if State.VeeronicaGraffitiESP then CreateHighlight(obj, Color3.fromRGB(255, 105, 180), "VeeGraffiti_ESP") else RemoveHighlight(obj, "VeeGraffiti_ESP") end
                                if State.VeeronicaGraffitiNameESP then CreateBillboardText(obj, "Veeronica Graffiti", "VeeGraffitiName_ESP") else RemoveBillboardText(obj, "VeeGraffitiName_ESP") end
                            elseif obj.Name == "PizzaDeliveryRig" or obj.Name == "Zombie" then
                                if State.CoolkiddMinionESP or State.OneByOneMinionESP then CreateHighlight(obj, Color3.fromRGB(255, 0, 0), "Minion_ESP") else RemoveHighlight(obj, "Minion_ESP") end
                                if State.MinionNameESP then CreateBillboardText(obj, "Minion", "MinionName_ESP") else RemoveBillboardText(obj, "MinionName_ESP") end
                            elseif obj.Name:find("RespawnLocation") or obj.Name:lower():find("ritual") then
                                if State.RitualESP then CreateHighlight(obj, Color3.fromRGB(255, 255, 255), "Ritual_ESP") else RemoveHighlight(obj, "Ritual_ESP") end
                                if State.RitualNameESP then CreateBillboardText(obj, "Ritual", "RitualName_ESP") else RemoveBillboardText(obj, "RitualName_ESP") end
                            end
                        end
                    end

                    local mainMap = ingame:FindFirstChild("Map")
                    if mainMap then
                        for _, obj in ipairs(mainMap:GetChildren()) do
                            if obj:IsA("Model") then
                                if obj.Name:lower():find("generator") and obj.Name ~= "FakeGenerator" then
                                    local finished = IsGeneratorFinished(obj)
                                    if State.GeneratorESP and not finished then CreateHighlight(obj, Color3.fromRGB(255, 255, 0), "Gen_ESP") else RemoveHighlight(obj, "Gen_ESP") end
                                    if State.GenNameESP and not finished then CreateBillboardText(obj, "Generator", "GenName_ESP") else RemoveBillboardText(obj, "GenName_ESP") end
                                elseif obj.Name == "FakeGenerator" then
                                    if State.FakeGeneratorESP then CreateHighlight(obj, Color3.fromRGB(255, 80, 0), "FakeGen_ESP") else RemoveHighlight(obj, "FakeGen_ESP") end
                                end
                            end

                            if obj.Name == "Medkit" or obj.Name == "MedKit" then
                                if State.ItemESP then CreateHighlight(obj, Color3.fromRGB(255, 0, 0), "Medkit_ESP") else RemoveHighlight(obj, "Medkit_ESP") end
                                if State.ItemNameESP then CreateBillboardText(obj, "Medkit", "MedkitName_ESP") else RemoveBillboardText(obj, "MedkitName_ESP") end
                            elseif obj.Name == "BloxyCola" or obj.Name == "Bloxy Cola" then
                                if State.ItemESP then CreateHighlight(obj, Color3.fromRGB(139, 69, 19), "Cola_ESP") else RemoveHighlight(obj, "Cola_ESP") end
                                if State.ItemNameESP then CreateBillboardText(obj, "Bloxy Cola", "ColaName_ESP") else RemoveBillboardText(obj, "ColaName_ESP") end
                            end
                        end
                    end
                end
            end)
        end
    end)

    -- Azure Plant State & Survivor Atropa ESP Loop
    local plantDrawings = {}
    local atropaDrawings = {}
    local lastPlantUpdate = 0

    TrackConnection(RunService.Heartbeat:Connect(function()
        local now = os.clock()
        if now - lastPlantUpdate < 0.25 then return end
        lastPlantUpdate = now

        pcall(function()
            if not State.EspAzuresPlantState then
                for m, d in pairs(plantDrawings) do
                    if d.bill then d.bill:Destroy() end
                end
                plantDrawings = {}
            else
                local mapObj = Workspace:FindFirstChild("Map")
                local ingame = mapObj and mapObj:FindFirstChild("Ingame")
                if ingame then
                    for _, model in pairs(ingame:GetChildren()) do
                        if model:IsA("Model") and (model.Name:find("GroundBulb") or model.Name:find("Vine") or model:FindFirstChild("AzureTrapOwnerHighlight")) then
                            if not plantDrawings[model] or not plantDrawings[model].bill or not plantDrawings[model].bill.Parent then
                                local bill = Instance.new("BillboardGui")
                                bill.Name = "AzurePlantESP"
                                bill.AlwaysOnTop = true
                                bill.Size = UDim2.new(0, 160, 0, 40)
                                bill.StudsOffset = Vector3.new(0, 4, 0)
                                bill.Adornee = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
                                bill.Parent = model

                                local text = Instance.new("TextLabel")
                                text.Size = UDim2.new(1, 0, 1, 0)
                                text.BackgroundTransparency = 1
                                text.TextColor3 = Color3.fromRGB(187, 98, 255)
                                text.TextStrokeTransparency = 0.4
                                text.Font = Enum.Font.Gotham
                                text.TextSize = 14
                                text.Text = "..."
                                text.Parent = bill

                                plantDrawings[model] = {bill = bill, text = text}
                            end

                            local state = "Unknown"
                            local animController = model:FindFirstChild("AnimationController")
                            if animController then
                                local animator = animController:FindFirstChild("Animator")
                                if animator then
                                    for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                                        if track.Name:find("Wither") or track.Name:find("Sleep") then
                                            state = "WITHER"
                                            break
                                        elseif track.Name:find("Active") or track.Name:find("Idle") or track.Name:find("Wake") then
                                            state = "BLOOMING"
                                            break
                                        end
                                    end
                                end
                            end

                            for _, v in pairs(model:GetChildren()) do
                                if v:GetAttribute("BloomingVFX") == true and v.Enabled then
                                    state = "BLOOMING"
                                    break
                                end
                            end

                            if plantDrawings[model] and plantDrawings[model].text then
                                plantDrawings[model].text.Text = state
                            end
                        end
                    end
                end
            end

            if not State.SurvivorAtropaOblation then
                for c, d in pairs(atropaDrawings) do
                    if d.bill then d.bill:Destroy() end
                end
                atropaDrawings = {}
            else
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= LP and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        local char = plr.Character
                        if not atropaDrawings[char] or not atropaDrawings[char].bill or not atropaDrawings[char].bill.Parent then
                            local bill = Instance.new("BillboardGui")
                            bill.Name = "AzureESP"
                            bill.AlwaysOnTop = true
                            bill.Size = UDim2.new(0, 200, 0, 50)
                            bill.StudsOffset = Vector3.new(0, 3.2, 0)
                            bill.Adornee = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
                            bill.Parent = char

                            local text = Instance.new("TextLabel")
                            text.Size = UDim2.new(1, 0, 1, 0)
                            text.BackgroundTransparency = 1
                            text.TextColor3 = Color3.new(1, 1, 1)
                            text.TextStrokeTransparency = 0.4
                            text.Font = Enum.Font.Gotham
                            text.TextSize = 14
                            text.Text = "Loading..."
                            text.Parent = bill

                            atropaDrawings[char] = {bill = bill, text = text}
                        end

                        local atropa = char:GetAttribute("Atropa") or 0
                        local status = char:FindFirstChild("Statuses") and char.Statuses:FindFirstChild("Atropa")
                        if status then
                            atropa = status:GetAttribute("Level") or atropa
                        end

                        if atropaDrawings[char] and atropaDrawings[char].text then
                            atropaDrawings[char].text.Text = string.format("Atropa: %d", atropa)
                        end
                    end
                end
            end
        end)
    end))

    -- Guest 1337 Auto Block - updated (post-update): every melee windup from every killer + every skin
    -- Blacklist: projectiles + Corrupt Energy + Cataclysm
    local DANGER, DASH_IDS = {}, {}
    local function addDanger(ids, dash)
        for _, id in ipairs(ids) do
            local key = "rbxassetid://" .. id
            DANGER[key] = true
            if dash then DASH_IDS[key] = true end
        end
    end
    -- noli
    addDanger({
            "93366464803829", "92567970681901", "84549159308650", "77375846492436",
            "128557115409603", "80398233021916", "106538427162796",
    })
    -- c00lkidd
    addDanger({
            "121858217776572", "84069821282466", "70785407091644", "70371667919898",
            "121080480916189", "99824350842479", "114126519127454", "130321333480982",
            "80277760801310", "114266653674439", "110978267403871", "18885909645",
    })
    -- nosferatu
    addDanger({
            "88451353906104", "124269076578545", "111985378056728", "91628732643385",
    })
    -- 1x1x1x1
    addDanger({
            "83829782357897", "106427068964975", "70948173568515", "121293883585738",
            "127245564598429", "90620531468240", "114506382930939", "126171487400618",
            "124705663396411", "99829427721752", "129405885079224",
    })
    -- guest 666
    addDanger({
            "122709416391891", "129638875679599",
    })
    -- new jason
    addDanger({
            "126830014841198", "126355327951215", "125403313786645", "79292672452687",
            "122059627114171", "105249651793722", "83684013007336", "110499297401042",
            "92231737384093", "126681776859538", "109667959938617", "74119697474847",
            "110640834973139", "82259780706234", "94735038402665", "126727756047566",
            "119062842291223", "106860049270347", "130958529065375", "102111078266527",
            "93965949706424", "103684883268194", "120950360130737", "75664524392308",
            "89182710199063", "134466224176351", "107466643450438", "109572851772132",
            "116250166603410", "108196996477620", "112063718195851", "116489150265990",
            "129921445546291", "133336594357903", "74707328554358", "92682098522474",
            "122915005018166", "92527444206709", "80640560792047", "84856423728667",
            "103806241180745", "77548169329982", "94113398437420", "139113610178750",
    })
    -- john doe
    addDanger({
            "105458270463374", "93069721274110", "88970503168421", "138938529389204",
            "81299297965542",
    })
    -- azure
    addDanger({
            "123556520269026", "112366541922769", "123172382755876", "82843272472677",
            "105458267857995",
    })
    -- shedletsky (funny)
    addDanger({
            "117173212095661",
    })
    -- slasher swift
    addDanger({
            "126830014841198", "126355327951215",
    })
    -- optional noli (void rush) (turned off by the "make auto block not block things like nolis void rush" toggle)
    addDanger({
            "93841120533318", "85379652729528", "76312020299624", "103526858588753",
    }, true)
    -- optional c00lkidd (walkspeed override) (turned off by the "make auto block not block things like nolis void rush" toggle)
    addDanger({
            "103079163311325", "102638845899011", "121369993837377", "18885932392",
            "18885939653", "135283134632311", "127846074966393", "71231909569291",
            "112748196946666", "81292728088654", "99135633258223", "97167027849946",
            "83340833895310", "118919403162061", "103772923355314", "134883911849369",
            "98590570796574", "128028377470509", "131219306779772", "109486609489179",
            "132243194360714", "123019923277556", "123345437821399", "137488556769630",
            "76092296412044", "119769761814461", "134667750748539", "91295703752812",
            "117599696256206", "81984082503549", "121442074282306", "80112431813739",
            "96090109816772", "98456918873918", "106776364623742",
    }, true)
    -- optional 1x1x1x1 (turned off by the "make auto block not block things like nolis void rush" toggle)
    addDanger({
            "96789868247953", "100592913030351", "101101433684051", "109777684604906",
            "83685305553364", "116814116277716", "104897856211468", "92901068575421",
            "99050723653468",
    }, true)
    -- optional guest 666 (demonic pursuit) (turned off by the "make auto block not block things like nolis void rush" toggle)
    addDanger({
            "116185978204544", "84305479484858", "108901210586307", "106647770195831",
            "100452671741436", "111259375133560", "109020938870671", "88543288871550",
            "122202689314030", "139309647473555", "71834552297085",
    }, true)
    -- optional new jason (gashing wound) (turned off by the "make auto block not block things like nolis void rush" toggle)
    addDanger({
            "112431608335447", "106847695270773", "93754478962374", "84274896493972",
            "72425554233832", "129849160785034", "95425798066509", "127793641088496",
            "129976080405072", "97903954245002", "70483423693126", "76959687420003",
            "118447338594560", "86494585504534", "93284670378212", "86833981571073",
            "71310583817000", "72424711616474", "133465310944510", "127774626396280",
            "135349868049670", "107875832752356", "83403561088276", "86204001129974",
            "90222552005724", "104980456408239", "136728245733659", "102228729296384",
            "123058272691729", "136472903819214", "105439607414777", "121086746534252",
    }, true)
    -- when on: void rush / demonic pursuit / walkspeed override ids are set to false (not blocked)
    local function ApplyDashFilter(on)
        for key in pairs(DASH_IDS) do
            DANGER[key] = not on
        end
    end

    local function getKillersFolder()
        local p = workspace:FindFirstChild("Players")
        return p and p:FindFirstChild("Killers")
    end

    local function isNear(char)
        if not State.AutoBlock then return false end
        local folder = getKillersFolder()
        if not folder then return false end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        for _, k in folder:GetChildren() do
            local khrp = k:FindFirstChild("HumanoidRootPart")
            if khrp and (khrp.Position - hrp.Position).Magnitude <= (State.AutoBlockRange or 9.5) then
                return true
            end
        end
        return false
    end

    local function doBlock()
        if not State.AutoBlock then return end
        local remote = GetRemoteEvent()
        if remote then
            remote:FireServer("UseActorAbility", { buffer.fromstring("\3\5\0\0\0Block") })
        end
        if State.AimPunch then AimLockToKiller() end
    end

    -- ===== accurate auto block engine =====
    -- every melee windup becomes a "threat" that is re-checked EVERY FRAME for 0.7s (killers that dash in after the
    -- animation starts used to be missed), killers' playing tracks are scanned every frame as well so no animation
    -- is missed, and the distance check leads by your ping.
    local blockConsumers = {
        { enabled = function() return State.AutoBlock end, range = function() return State.AutoBlockRange or 9.5 end, fire = doBlock },
    }
    local threats = {}
    local seenTracks = setmetatable({}, { __mode = "k" })
    local THREAT_WINDOW = 0.7

    local function pingLead()
        local ok, ping = pcall(function() return LP:GetNetworkPing() end)
        return 0.08 + ((ok and type(ping) == "number") and math.clamp(ping, 0, 0.3) or 0.05)
    end

    local function evaluateThreat(th)
        local myChar = LP.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local kRoot = th.model and th.model:FindFirstChild("HumanoidRootPart")
        if not myRoot or not kRoot then return end
        local offset = kRoot.Position - myRoot.Position
        local distance = offset.Magnitude
        local closing = 0
        if distance > 0.01 then
            local rel = kRoot.AssemblyLinearVelocity - myRoot.AssemblyLinearVelocity
            closing = math.max(0, -rel:Dot(offset / distance))
        end
        local nearest = math.min(distance, distance - closing * pingLead())
        for index, consumer in ipairs(blockConsumers) do
            if not th.fired[index] and consumer.enabled() and nearest <= consumer.range() then
                th.fired[index] = true
                pcall(consumer.fire)
            end
        end
    end

    local function registerThreat(model, track)
        if seenTracks[track] then return end
        seenTracks[track] = true
        local th = { model = model, track = track, t0 = os.clock(), fired = {} }
        table.insert(threats, th)
        evaluateThreat(th) -- check right now, not on the next frame
    end

    TrackConnection(RunService.Heartbeat:Connect(function()
        local any = false
        for _, consumer in ipairs(blockConsumers) do
            if consumer.enabled() then any = true break end
        end
        if not any then
            if #threats > 0 then table.clear(threats) end
            return
        end
        local folder = getKillersFolder()
        if folder then
            for _, k in ipairs(folder:GetChildren()) do
                local hum = k:FindFirstChildOfClass("Humanoid")
                local animator = hum and hum:FindFirstChildOfClass("Animator")
                if animator then
                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                        local anim = track.Animation
                        if anim and DANGER[anim.AnimationId] and not seenTracks[track] then
                            registerThreat(k, track)
                        end
                    end
                end
            end
        end
        local now = os.clock()
        for i = #threats, 1, -1 do
            local th = threats[i]
            if now - th.t0 > THREAT_WINDOW or not th.model or not th.model.Parent then
                table.remove(threats, i)
            else
                evaluateThreat(th)
            end
        end
    end))

    local function onKillerAnim(hum, track)
        local anim = track.Animation
        if not (anim and DANGER[anim.AnimationId]) then return end
        local model = hum.Parent
        if model == LP.Character then
            -- your own windup animation (old behaviour)
            if State.AutoBlock then
                local myChar = LP.Character
                if myChar and isNear(myChar) then doBlock() end
            end
        else
            registerThreat(model, track)
        end
    end

    local function watchHumanoid(hum)
        if not hum or hum:GetAttribute("AutoBlockWatched") then return end
        hum:SetAttribute("AutoBlockWatched", true)
        hum.AnimationPlayed:Connect(function(track) onKillerAnim(hum, track) end)
        local animator = hum:FindFirstChildOfClass("Animator")
        if animator then animator.AnimationPlayed:Connect(function(track) onKillerAnim(hum, track) end) end
    end

    local function onChar(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then watchHumanoid(hum) end
    end
    if LP.Character then onChar(LP.Character) end
    TrackConnection(LP.CharacterAdded:Connect(onChar))

    local hookedFolders = setmetatable({}, { __mode = "k" })
    local function setupKillers()
        local folder = getKillersFolder()
        if not folder then return end
        for _, k in folder:GetChildren() do
            local hum = k:FindFirstChildOfClass("Humanoid")
            if hum then watchHumanoid(hum) end
        end
        if not hookedFolders[folder] then
            hookedFolders[folder] = true
            TrackConnection(folder.ChildAdded:Connect(function(k)
                local hum = k:FindFirstChildOfClass("Humanoid") or k:WaitForChild("Humanoid", 3)
                if hum then watchHumanoid(hum) end
            end))
        end
    end

    setupKillers()
    TrackConnection(workspace.ChildAdded:Connect(function(c)
        if c.Name == "Players" then
            task.wait(0.3)
            setupKillers()
        end
    end))

    task.spawn(function()
        while ScriptRunning do
            task.wait(0.5)
            setupKillers()
        end
    end)

    -- Auto Generator Engine
    task.spawn(function()
        while ScriptRunning do
            task.wait(State.GeneratorCooldown or 1)
            if State.AutoGenerator then
                pcall(function()
                    local ingame = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Ingame")
                    local mainMap = ingame and ingame:FindFirstChild("Map")
                    if mainMap then
                        for _, obj in ipairs(mainMap:GetChildren()) do
                            if obj:IsA("Model") and obj.Name:lower():find("generator") and obj.Name ~= "FakeGenerator" then
                                if not IsGeneratorFinished(obj) then
                                    local remotes = obj:FindFirstChild("Remotes")
                                    local re = remotes and remotes:FindFirstChild("RE")
                                    if re then re:FireServer() end
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)

    ----------------------------------------------------------------------
    -- Fruits: ESP (green highlight) + name labels
    ----------------------------------------------------------------------
    do
        local FRUIT_TAG = "FruitNameLabel"
        local FRUIT_GREEN = Color3.fromRGB(0, 255, 0)
        local espWasOn, namesWereOn = false, false

        local function getFruitContainer()
            local map = Workspace:FindFirstChild("Map")
            local ingame = map and map:FindFirstChild("Ingame")
            local inner = ingame and ingame:FindFirstChild("Map")
            return inner and inner:FindFirstChild("OrangeFruits")
        end

        task.spawn(function()
            while ScriptRunning do
                task.wait(0.4)
                pcall(function()
                    local container = getFruitContainer()
                    if not container then return end

                    -- esp fruits
                    if State.EspFruits then
                        espWasOn = true
                        for _, fruit in ipairs(container:GetChildren()) do
                            CreateHighlight(fruit, FRUIT_GREEN, "Fruit_ESP")
                        end
                    elseif espWasOn then
                        espWasOn = false
                        for _, fruit in ipairs(container:GetChildren()) do
                            RemoveHighlight(fruit, "Fruit_ESP")
                        end
                    end

                    -- fruits name esp
                    if State.FruitNameESP then
                        namesWereOn = true
                        for _, d in ipairs(container:GetDescendants()) do
                            if d:IsA("ProximityPrompt") then
                                local root = d.Parent
                                if root and root.Name == "ItemRoot" then
                                    local gui = root:FindFirstChild(FRUIT_TAG)
                                    if not gui then
                                        gui = Instance.new("BillboardGui")
                                        gui.Name = FRUIT_TAG
                                        gui.Adornee = root
                                        gui.AlwaysOnTop = true
                                        gui.Size = UDim2.new(0, 200, 0, 40)
                                        gui.StudsOffset = Vector3.new(0, 2, 0)
                                        gui.MaxDistance = math.huge
                                        gui.Parent = root

                                        local label = Instance.new("TextLabel")
                                        label.Name = "NameLabel"
                                        label.Size = UDim2.new(1, 0, 1, 0)
                                        label.BackgroundTransparency = 1
                                        label.Font = Enum.Font.Gotham
                                        label.TextSize = 20
                                        label.TextColor3 = Color3.fromRGB(255, 255, 255)
                                        label.TextStrokeTransparency = 0.4
                                        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                        label.Text = d.ActionText
                                        label.Parent = gui
                                    else
                                        local label = gui:FindFirstChild("NameLabel")
                                        if label and label.Text ~= d.ActionText then
                                            label.Text = d.ActionText
                                        end
                                    end
                                end
                            end
                        end
                    elseif namesWereOn then
                        namesWereOn = false
                        for _, d in ipairs(container:GetDescendants()) do
                            if d.Name == FRUIT_TAG and d:IsA("BillboardGui") then
                                d:Destroy()
                            end
                        end
                    end
                end)
            end
        end)
    end

    ----------------------------------------------------------------------
    -- Halloween currency (candy): orange highlight + name
    ----------------------------------------------------------------------
    do
        local CANDY_ORANGE = Color3.fromRGB(255, 140, 0)
        local espWasOn, namesWereOn = false, false
        task.spawn(function()
            while ScriptRunning do
                task.wait(0.4)
                pcall(function()
                    local map = Workspace:FindFirstChild("Map")
                    local ingame = map and map:FindFirstChild("Ingame")
                    local inner = ingame and ingame:FindFirstChild("Map")
                    local spawns = inner and inner:FindFirstChild("CurrencySpawns")
                    if not spawns then return end
                    local candies = {}
                    for _, candy in ipairs(spawns:GetChildren()) do
                        if candy.Name == "C00lCandy" then table.insert(candies, candy) end
                    end
                    if State.EspCandies then
                        espWasOn = true
                        for _, candy in ipairs(candies) do
                            CreateHighlight(candy, CANDY_ORANGE, "Candy_ESP")
                        end
                    elseif espWasOn then
                        espWasOn = false
                        for _, candy in ipairs(candies) do
                            RemoveHighlight(candy, "Candy_ESP")
                        end
                    end
                    if State.CandyNameESP then
                        namesWereOn = true
                        for _, candy in ipairs(candies) do
                            CreateBillboardText(candy, "Candy", "CandyName_ESP", CANDY_ORANGE)
                        end
                    elseif namesWereOn then
                        namesWereOn = false
                        for _, candy in ipairs(candies) do
                            RemoveBillboardText(candy, "CandyName_ESP")
                        end
                    end
                end)
            end
        end)
    end

    ----------------------------------------------------------------------
    -- Dusekkar: protect through walls
    ----------------------------------------------------------------------
    local ApplyDusekkarWallConfig
    do
        local origWallTime = nil

        task.spawn(function()
            pcall(function()
                local util = require(ReplicatedStorage.Modules.Utilities.Util)
                local old
                old = hookfunction(util.IsOnScreen, function(self, target, flag, ...)
                    if State.DusekkarProtectWalls and flag == true then
                        return true
                    end
                    return old(self, target, flag, ...)
                end)
            end)
        end)

        ApplyDusekkarWallConfig = function(on)
            pcall(function()
                local config = require(ReplicatedStorage.Assets.Survivors.Dusekkar.Config)
                if origWallTime == nil then
                    origWallTime = config.SpawnProtectionTimeUntilBrokenByWallInterference
                end
                if setreadonly then setreadonly(config, false) end
                if make_writeable then make_writeable(config) end
                if on then
                    config.SpawnProtectionTimeUntilBrokenByWallInterference = math.huge
                elseif origWallTime ~= nil then
                    config.SpawnProtectionTimeUntilBrokenByWallInterference = origWallTime
                end
            end)
        end
    end

    ----------------------------------------------------------------------
    -- Guest 1337: auto aim at killer while charging
    ----------------------------------------------------------------------
    do
        local MAX_DISTANCE = 120
        local AIM_PART = "HumanoidRootPart"
        local PREDICT = 0
        local FIRST_PERSON = true

        local aiming = false
        local prevCameraMode

        local function getGuest()
            local plrs = workspace:FindFirstChild("Players")
            local survivors = plrs and plrs:FindFirstChild("Survivors")
            return survivors and survivors:FindFirstChild("Guest1337")
        end

        local function isCharging(guest)
            local mults = guest:FindFirstChild("FOVMultipliers")
            return mults and mults:FindFirstChild("Guest1337Charge") ~= nil
        end

        local function getTarget(fromPos)
            local plrs = workspace:FindFirstChild("Players")
            local killers = plrs and plrs:FindFirstChild("Killers")
            if not killers then return end
            local best, bestDist = nil, MAX_DISTANCE
            for _, k in ipairs(killers:GetChildren()) do
                local root = k:FindFirstChild("HumanoidRootPart") or k.PrimaryPart
                if root then
                    local d = (root.Position - fromPos).Magnitude
                    if d <= bestDist then best, bestDist = k, d end
                end
            end
            return best
        end

        local function startAim(hum)
            if aiming then return end
            aiming = true
            prevCameraMode = LP.CameraMode
            if FIRST_PERSON then LP.CameraMode = Enum.CameraMode.LockFirstPerson end
            if hum then hum.AutoRotate = false end
        end

        local function stopAim(hum)
            if not aiming then return end
            aiming = false
            if FIRST_PERSON then LP.CameraMode = prevCameraMode or Enum.CameraMode.Classic end
            if hum then hum.AutoRotate = true end
        end

        RunService:BindToRenderStep("Guest1337Aim", Enum.RenderPriority.Camera.Value + 1, function()
            local char = LP.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local guest = getGuest()

            if not State.Guest1337ChargeAim or not char or not hum or not guest or char ~= guest or not isCharging(guest) then
                stopAim(hum)
                return
            end

            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then stopAim(hum) return end

            local killer = getTarget(root.Position)
            if not killer then stopAim(hum) return end

            local part = killer:FindFirstChild(AIM_PART) or killer:FindFirstChild("HumanoidRootPart")
            if not part then stopAim(hum) return end

            startAim(hum)

            local aimPos = AimUtil.Point(part, PREDICT, 14)

            local flat = Vector3.new(aimPos.X, root.Position.Y, aimPos.Z)
            if (flat - root.Position).Magnitude > 0.1 then
                root.CFrame = CFrame.lookAt(root.Position, flat)
            end

            local cam = workspace.CurrentCamera
            cam.CFrame = CFrame.lookAt(cam.CFrame.Position, aimPos)
        end)
    end

    ----------------------------------------------------------------------
    -- Chance: auto aim (gun)
    ----------------------------------------------------------------------
    do
        local MAX_DISTANCE = 120
        local AIM_PART = "Head"
        local PREDICT = 0

        local aiming = false
        local prevCameraMode

        local function getChance()
            local plrs = workspace:FindFirstChild("Players")
            local survivors = plrs and plrs:FindFirstChild("Survivors")
            return survivors and survivors:FindFirstChild("Chance")
        end

        local function isShooting(chance)
            local mults = chance:FindFirstChild("SpeedMultipliers")
            return mults and mults:FindFirstChild("ShootingGun") ~= nil
        end

        local function getTarget(fromPos)
            local plrs = workspace:FindFirstChild("Players")
            local killers = plrs and plrs:FindFirstChild("Killers")
            if not killers then return end
            local best, bestDist = nil, MAX_DISTANCE
            for _, k in ipairs(killers:GetChildren()) do
                local root = k:FindFirstChild("HumanoidRootPart") or k.PrimaryPart
                if root then
                    local d = (root.Position - fromPos).Magnitude
                    if d <= bestDist then best, bestDist = k, d end
                end
            end
            return best
        end

        local function startAim(hum)
            if aiming then return end
            aiming = true
            prevCameraMode = LP.CameraMode
            LP.CameraMode = Enum.CameraMode.LockFirstPerson
            if hum then hum.AutoRotate = false end
        end

        local function stopAim(hum)
            if not aiming then return end
            aiming = false
            LP.CameraMode = prevCameraMode or Enum.CameraMode.Classic
            if hum then hum.AutoRotate = true end
        end

        RunService:BindToRenderStep("ChanceAim", Enum.RenderPriority.Camera.Value + 1, function()
            local char = LP.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local chance = getChance()

            if not State.ChanceGunAim or not char or not hum or not chance or char ~= chance or not isShooting(chance) then
                stopAim(hum)
                return
            end

            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then stopAim(hum) return end

            local killer = getTarget(root.Position)
            if not killer then stopAim(hum) return end

            local part = killer:FindFirstChild(AIM_PART) or killer:FindFirstChild("HumanoidRootPart")
            if not part then stopAim(hum) return end

            startAim(hum)

            local aimPos = AimUtil.Point(part, PREDICT, 14)

            local flat = Vector3.new(aimPos.X, root.Position.Y, aimPos.Z)
            if (flat - root.Position).Magnitude > 0.1 then
                root.CFrame = CFrame.lookAt(root.Position, flat)
            end

            local cam = workspace.CurrentCamera
            cam.CFrame = CFrame.lookAt(cam.CFrame.Position, aimPos)
        end)
    end

    ----------------------------------------------------------------------
    -- Jane Doe: hatchet hitbox TP, crystal auto aim (survivor/killer), hatchet auto aim
    ----------------------------------------------------------------------
    do
        local CHAR_NAME = "JaneDoe"

        local function getJane()
            local plrs = workspace:FindFirstChild("Players")
            local survivors = plrs and plrs:FindFirstChild("Survivors")
            return survivors and survivors:FindFirstChild(CHAR_NAME)
        end

        local function isJane()
            local v = LP:FindFirstChild("Character")
            if v and v:IsA("ValueBase") then
                local val = v.Value
                if val == CHAR_NAME or (typeof(val) == "Instance" and val.Name == CHAR_NAME) then
                    return true
                end
            end
            if LP:GetAttribute("Character") == CHAR_NAME then return true end
            local jane = getJane()
            return jane ~= nil and LP.Character == jane
        end

        local function getMyModel()
            local jane = getJane()
            return (jane and jane:FindFirstChild("HumanoidRootPart") and jane) or LP.Character
        end

        -------------------- hatchet hitbox TP --------------------
        do
            local DELAY = 0.65
            local STAY = 0.09
            local RETURN_HOLD = 0.1
            local MAX_DISTANCE = 300

            local busySince = nil

            local function getMyRoot()
                local model = getMyModel()
                return model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
            end

            local function getNearestKillerRoot(fromPos)
                local plrs = workspace:FindFirstChild("Players")
                local killers = plrs and plrs:FindFirstChild("Killers")
                if not killers then return end
                local best, bestDist = nil, MAX_DISTANCE
                for _, k in ipairs(killers:GetChildren()) do
                    local root = k:FindFirstChild("HumanoidRootPart") or k.PrimaryPart
                    if root then
                        local d = (root.Position - fromPos).Magnitude
                        if d <= bestDist then best, bestDist = root, d end
                    end
                end
                return best
            end

            local function hold(root, cf, duration)
                local t0 = os.clock()
                repeat
                    if not root.Parent then return end
                    root.CFrame = cf
                    root.AssemblyLinearVelocity = Vector3.zero
                    RunService.Heartbeat:Wait()
                until os.clock() - t0 >= duration
            end

            local function hop()
                local root = getMyRoot()
                if not root then return end
                local killerRoot = getNearestKillerRoot(root.Position)
                if not killerRoot then return end

                local origin = root.CFrame
                local killerPos = killerRoot.Position
                local target = killerRoot.CFrame * CFrame.new(0, 0, State.JaneHatchetTPBehind or 2.5)
                local dest = CFrame.lookAt(target.Position, Vector3.new(killerPos.X, target.Position.Y, killerPos.Z))

                hold(root, dest, STAY)
                hold(root, origin, RETURN_HOLD)
            end

            local function onJdaw()
                if busySince and os.clock() - busySince < 2 then return end
                if not State.JaneHatchetTP or not isJane() then return end

                busySince = os.clock()
                local ok, err = pcall(function()
                    task.wait(DELAY)
                    if State.JaneHatchetTP and isJane() then hop() end
                end)
                busySince = nil
                if not ok then warn("[JaneTP]", err) end
            end

            local lastJd = nil
            TrackConnection(RunService.Heartbeat:Connect(function()
                local jane = getJane()
                local mults = jane and jane:FindFirstChild("SpeedMultipliers")
                local jd = mults and mults:FindFirstChild("jdaw")
                if jd and jd ~= lastJd then
                    task.spawn(onJdaw)
                end
                lastJd = jd
            end))
        end

        -------------------- crystal auto aim (survivor / killer) --------------------
        do
            local TRIGGER_NAME = "JDCrystalChargeFOV"

            local SURV_MAX_DISTANCE = 110
            local KILL_MAX_DISTANCE = 250
            local MIN_AIM_DOT = 0.5
            local AIM_PART = "HumanoidRootPart"
            local CAM_BACK = 12
            local GRAVITY = 40
            local MIN_SPEED, MAX_SPEED = 35, 250
            local MIN_CHARGE = 0.25 / 2
            local MOBILE_TILT = math.atan(1 / 3)

            local active = false
            local aimU = nil
            local prevCamType = nil
            local locked = nil

            local function rootOf(m)
                return m and (m:FindFirstChild(AIM_PART) or m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart)
            end

            local function isValid(m)
                if not m or not m.Parent then return false end
                local hum = m:FindFirstChildOfClass("Humanoid")
                return rootOf(m) ~= nil and (not hum or hum.Health > 0)
            end

            local function pickSurvivor(myPos, me)
                local plrs = workspace:FindFirstChild("Players")
                local folder = plrs and plrs:FindFirstChild("Survivors")
                if not folder then return end

                local cam = workspace.CurrentCamera
                local camPos, look = cam.CFrame.Position, cam.CFrame.LookVector

                local bestAim, bestDot = nil, MIN_AIM_DOT
                local bestNear, bestDist = nil, SURV_MAX_DISTANCE
                for _, m in ipairs(folder:GetChildren()) do
                    if m ~= me and m ~= LP.Character and isValid(m) then
                        local r = rootOf(m)
                        local dist = (r.Position - myPos).Magnitude
                        if dist <= SURV_MAX_DISTANCE then
                            local dot = look:Dot((r.Position - camPos).Unit)
                            if dot > bestDot then bestAim, bestDot = m, dot end
                            if dist < bestDist then bestNear, bestDist = m, dist end
                        end
                    end
                end
                return bestAim or bestNear
            end

            local function nearestKillerPart(fromPos)
                local plrs = workspace:FindFirstChild("Players")
                local folder = plrs and plrs:FindFirstChild("Killers")
                if not folder then return end
                local best, bestDist = nil, KILL_MAX_DISTANCE
                for _, m in ipairs(folder:GetChildren()) do
                    if m ~= LP.Character and isValid(m) then
                        local r = rootOf(m)
                        local d = (r.Position - fromPos).Magnitude
                        if d <= bestDist then best, bestDist = r, d end
                    end
                end
                return best
            end

            local function solve(origin, target, speed)
                local delta = target - origin
                local flat = Vector3.new(delta.X, 0, delta.Z)
                local d, h = flat.Magnitude, delta.Y
                if d < 0.1 then return (delta.Magnitude > 0 and delta.Unit or Vector3.yAxis), 0 end
                local v2 = speed * speed
                local disc = v2 * v2 - GRAVITY * (GRAVITY * d * d + 2 * h * v2)
                local tan = disc >= 0 and (v2 - math.sqrt(disc)) / (GRAVITY * d) or 1
                local dir = (flat.Unit + Vector3.new(0, tan, 0)).Unit
                return dir, d * math.sqrt(1 + tan * tan) / speed
            end

            local function toU(dir, off)
                local o = off / 500
                local dd = dir:Dot(o)
                local s = -dd + math.sqrt(dd * dd + 1 - o:Dot(o))
                return (dir * s + o).Unit
            end

            local function stopAim()
                locked = nil
                if not active then return end
                active = false
                aimU = nil
                local cam = workspace.CurrentCamera
                if cam then
                    cam.CameraType = (prevCamType and prevCamType ~= Enum.CameraType.Scriptable) and prevCamType or Enum.CameraType.Custom
                end
                local char = LP.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.AutoRotate = true end
            end

            -- PC: the game aims at util:GetPlayerMousePosition(player)
            pcall(function()
                local util = require(ReplicatedStorage.Modules.Utilities.Util)
                local orig
                local function hooked(self, plr, ...)
                    if active and aimU and plr == LP then
                        local model = getMyModel()
                        local root = model and (model.PrimaryPart or model:FindFirstChild("HumanoidRootPart"))
                        if root then return root.Position + aimU * 100 end
                    end
                    return orig(self, plr, ...)
                end
                if hookfunction then
                    orig = hookfunction(util.GetPlayerMousePosition, hooked)
                else
                    orig = util.GetPlayerMousePosition
                    util.GetPlayerMousePosition = hooked
                end
            end)

            RunService:BindToRenderStep("JaneCrystalAim", Enum.RenderPriority.Camera.Value - 1, function()
                local mode = (State.JaneCrystalSurvivor and "Survivors") or (State.JaneCrystalKiller and "Killers") or nil
                if not mode then stopAim() return end

                local jane = getJane()
                local fovm = jane and jane:FindFirstChild("FOVMultipliers")
                local trig = fovm and fovm:FindFirstChild(TRIGGER_NAME)
                if not trig or not isJane() then stopAim() return end

                local model = getMyModel()
                local root = model and (model.PrimaryPart or model:FindFirstChild("HumanoidRootPart"))
                local hum = model and model:FindFirstChildOfClass("Humanoid")
                if not root then stopAim() return end

                local part
                if mode == "Survivors" then
                    if not isValid(locked) or (rootOf(locked).Position - root.Position).Magnitude > SURV_MAX_DISTANCE then
                        locked = pickSurvivor(root.Position, model)
                    end
                    part = rootOf(locked)
                else
                    locked = nil
                    part = nearestKillerPart(root.Position)
                end
                if not part then stopAim() return end

                local charge = MIN_CHARGE
                if trig:IsA("ValueBase") and typeof(trig.Value) == "number" then
                    charge = math.clamp((1 - trig.Value) / 0.04, MIN_CHARGE, 1)
                end
                local speed = MIN_SPEED + (MAX_SPEED - MIN_SPEED) * charge

                local off = Vector3.new(0, ((hum and hum.HipHeight or 2) + root.Size.Y / 2) / 2, 0)
                local origin = root.Position + off

                local vel = part.AssemblyLinearVelocity
                local aimPos, dir = part.Position, nil
                for _ = 1, 4 do
                    local t
                    dir, t = solve(origin, aimPos, speed)
                    aimPos = part.Position + vel * t
                end
                dir = solve(origin, aimPos, speed)

                local u = toU(dir, off)
                aimU = u

                local cam = workspace.CurrentCamera
                if not active then
                    active = true
                    prevCamType = cam.CameraType
                    if hum then hum.AutoRotate = false end
                end
                cam.CameraType = Enum.CameraType.Scriptable

                local look
                if LP:GetAttribute("Device") == "Mobile" then
                    local flat = Vector3.new(u.X, 0, u.Z)
                    flat = flat.Magnitude > 0.001 and flat.Unit or Vector3.zAxis
                    local pitch = math.asin(math.clamp(u.Y, -1, 1)) - MOBILE_TILT
                    look = flat * math.cos(pitch) + Vector3.new(0, math.sin(pitch), 0)
                else
                    look = (aimPos - root.Position).Unit
                end

                local pivot = root.Position + Vector3.new(0, 1.5, 0)
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                local plrs = workspace:FindFirstChild("Players")
                params.FilterDescendantsInstances = plrs and { plrs } or {}
                local hit = workspace:Raycast(pivot, -look * CAM_BACK, params)
                local back = hit and math.max(hit.Distance - 0.5, 0) or CAM_BACK

                cam.CFrame = CFrame.lookAt(pivot - look * back, pivot - look * back + look)
            end)
        end

        -------------------- hatchet auto aim (camera) --------------------
        do
            local TRIGGER_NAME = "jdaw"
            local AIM_PART = "HumanoidRootPart"
            local PREDICT = 0.08
            local SMOOTHING = 1
            local TURN_BODY = true

            local aiming = false

            local function getMyRoot()
                local model = getMyModel()
                return model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
            end

            local function getNearestKiller(fromPos)
                local plrs = workspace:FindFirstChild("Players")
                local killers = plrs and plrs:FindFirstChild("Killers")
                if not killers then return end
                local best, bestDist = nil, State.JaneHatchetAimDistance or 30
                for _, k in ipairs(killers:GetChildren()) do
                    local root = k:FindFirstChild("HumanoidRootPart") or k.PrimaryPart
                    if root then
                        local d = (root.Position - fromPos).Magnitude
                        if d <= bestDist then best, bestDist = k, d end
                    end
                end
                return best
            end

            local function getHum()
                local char = LP.Character
                return char and char:FindFirstChildOfClass("Humanoid")
            end

            local function stopAim()
                if not aiming then return end
                aiming = false
                local hum = getHum()
                if hum then hum.AutoRotate = true end
            end

            RunService:BindToRenderStep("JaneDoeAim", Enum.RenderPriority.Camera.Value + 1, function(dt)
                if not State.JaneHatchetAim then stopAim() return end

                local jane = getJane()
                local mults = jane and jane:FindFirstChild("SpeedMultipliers")
                local trig = mults and mults:FindFirstChild(TRIGGER_NAME)
                if not trig or not isJane() then stopAim() return end

                local root = getMyRoot()
                if not root then stopAim() return end

                local killer = getNearestKiller(root.Position)
                if not killer then stopAim() return end

                local part = killer:FindFirstChild(AIM_PART) or killer:FindFirstChild("HumanoidRootPart") or killer.PrimaryPart
                if not part then stopAim() return end

                local hum = getHum()
                if not aiming then
                    aiming = true
                    if hum and TURN_BODY then hum.AutoRotate = false end
                end

                local aimPos = AimUtil.Point(part, PREDICT, 14)

                if TURN_BODY then
                    local flat = Vector3.new(aimPos.X, root.Position.Y, aimPos.Z)
                    if (flat - root.Position).Magnitude > 0.1 then
                        root.CFrame = CFrame.lookAt(root.Position, flat)
                    end
                end

                local cam = workspace.CurrentCamera
                local goal = CFrame.lookAt(cam.CFrame.Position, aimPos)
                cam.CFrame = SMOOTHING >= 1 and goal or AimUtil.Smooth(cam.CFrame, goal, dt, SMOOTHING)
            end)
        end
    end

    ----------------------------------------------------------------------
    -- Shedletsky: sword hitbox TP + auto use and aim slash
    ----------------------------------------------------------------------
    do
        local CHAR_NAME = "Shedletsky"
        local TRIGGER_NAME = "StunningKiller"

        local DELAY = 0.35
        local STAY = 0.09
        local RETURN_HOLD = 0.1
        local MAX_DISTANCE = 300
        local BEHIND_OFFSET = 0.1

        local function getChar()
            local plrs = workspace:FindFirstChild("Players")
            local survivors = plrs and plrs:FindFirstChild("Survivors")
            return survivors and survivors:FindFirstChild(CHAR_NAME)
        end

        local function isMe()
            local v = LP:FindFirstChild("Character")
            if v and v:IsA("ValueBase") then
                local val = v.Value
                if val == CHAR_NAME or (typeof(val) == "Instance" and val.Name == CHAR_NAME) then
                    return true
                end
            end
            if LP:GetAttribute("Character") == CHAR_NAME then return true end
            local model = getChar()
            return model ~= nil and LP.Character == model
        end

        local function getMyRoot()
            local model = getChar()
            model = (model and model:FindFirstChild("HumanoidRootPart") and model) or LP.Character
            return model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
        end

        local function getNearestKillerRoot(fromPos)
            local plrs = workspace:FindFirstChild("Players")
            local killers = plrs and plrs:FindFirstChild("Killers")
            if not killers then return end
            local best, bestDist = nil, MAX_DISTANCE
            for _, k in ipairs(killers:GetChildren()) do
                local root = k:FindFirstChild("HumanoidRootPart") or k.PrimaryPart
                if root then
                    local d = (root.Position - fromPos).Magnitude
                    if d <= bestDist then best, bestDist = root, d end
                end
            end
            return best
        end

        local function hold(root, cf, duration)
            local t0 = os.clock()
            repeat
                if not root.Parent then return end
                root.CFrame = cf
                root.AssemblyLinearVelocity = Vector3.zero
                RunService.Heartbeat:Wait()
            until os.clock() - t0 >= duration
        end

        local function hop()
            local root = getMyRoot()
            if not root then return end
            local killerRoot = getNearestKillerRoot(root.Position)
            if not killerRoot then return end

            local origin = root.CFrame
            local killerPos = killerRoot.Position
            local target = killerRoot.CFrame * CFrame.new(0, 0, BEHIND_OFFSET)
            local dest = CFrame.lookAt(target.Position, Vector3.new(killerPos.X, target.Position.Y, killerPos.Z))

            hold(root, dest, STAY)
            hold(root, origin, RETURN_HOLD)
        end

        local busySince = nil
        local function onTrigger()
            if busySince and os.clock() - busySince < 2 then return end
            if not State.ShedSwordTP or not isMe() then return end

            busySince = os.clock()
            local ok, err = pcall(function()
                task.wait(DELAY)
                if State.ShedSwordTP and isMe() then hop() end
            end)
            busySince = nil
            if not ok then warn("[ShedTP]", err) end
        end

        local lastObj = nil
        TrackConnection(RunService.Heartbeat:Connect(function()
            local model = getChar()
            local mults = model and model:FindFirstChild("SpeedMultipliers")
            local obj = mults and mults:FindFirstChild(TRIGGER_NAME)
            if obj and obj ~= lastObj then
                task.spawn(onTrigger)
            end
            lastObj = obj
        end))

        -------------------- auto use and aim slash --------------------
        local LOCK_DURATION = 0.8
        local locking = false
        local lockUntil = 0
        local targetPart = nil

        local function slashReady()
            local ok, text = pcall(function()
                return LP.PlayerGui.MainUI.AbilityContainer.Slash.CooldownTime.Text
            end)
            if not ok then return false end
            return text == "" or text == nil
        end

        local function getClosestKiller()
            local folder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers")
            if not folder then return nil end
            local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if not myRoot then return nil end

            local closest, closestDist = nil, State.ShedSlashRange or 19
            for _, killer in pairs(folder:GetChildren()) do
                local root = killer:FindFirstChild("HumanoidRootPart") or killer.PrimaryPart
                if root then
                    local dist = (root.Position - myRoot.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closest = root
                    end
                end
            end
            return closest
        end

        TrackConnection(RunService.RenderStepped:Connect(function()
            if not State.ShedAutoSlash or not isMe() then
                locking = false
                targetPart = nil
                return
            end

            if locking then
                if tick() > lockUntil or not targetPart or not targetPart.Parent then
                    locking = false
                    targetPart = nil
                    return
                end
                local cam = Workspace.CurrentCamera
                cam.CFrame = CFrame.lookAt(cam.CFrame.Position, AimUtil.Point(targetPart))
                return
            end

            if not slashReady() then return end

            local target = getClosestKiller()
            if target then
                locking = true
                targetPart = target
                lockUntil = tick() + LOCK_DURATION

                local remote = GetRemoteEvent()
                if remote then
                    remote:FireServer("UseActorAbility", { buffer.fromstring("\3\5\0\0\0Slash") })
                end
            end
        end))
    end

    ----------------------------------------------------------------------
    -- EXTRA FEATURES (ported from the Cursedsaken script)
    --   antis  : movement/status-effect/pull/puddle protections
    --   misc   : end screen, AFK, chat, sidebar, zoom, fov, timer, etc.
    -- Each feature reads its on/off flag from State and cleans up after itself.
    ----------------------------------------------------------------------
    local Extras = {}
    do
        local PlayerGui = LP:WaitForChild("PlayerGui")
        local UserInputService = game:GetService("UserInputService")
        local TextChatService = game:GetService("TextChatService")
        local TeleportService = game:GetService("TeleportService")

        ------------------------------------------------------------------
        -- helpers
        ------------------------------------------------------------------
        local function Ingame()
            local map = Workspace:FindFirstChild("Map")
            return map and map:FindFirstChild("Ingame")
        end

        local function GetNetworkModule()
            local ok, result = pcall(function()
                return require(ReplicatedStorage.Modules.Network.Network)
            end)
            return ok and result or nil
        end

        local function IsKiller(model)
            local plrs = Workspace:FindFirstChild("Players")
            local killers = plrs and plrs:FindFirstChild("Killers")
            return killers ~= nil and model ~= nil and model:IsDescendantOf(killers)
        end

        -- Runs `step` every `interval` seconds while State[flag] is true.
        local function LoopWhile(flag, interval, step)
            task.spawn(function()
                while ScriptRunning and State[flag] do
                    pcall(step)
                    task.wait(interval)
                end
            end)
        end

        -- Disconnects a stored connection and returns nil (use: conn = Drop(conn)).
        local function Drop(conn)
            if conn then conn:Disconnect() end
            return nil
        end

        ------------------------------------------------------------------
        -- ANTIS: movement
        ------------------------------------------------------------------
        function Extras.SetAntiFallSlowness(on)
            State.AntiFallSlowness = on
            if on then
                LoopWhile("AntiFallSlowness", 1, function()
                    local char = LP.Character
                    if char and char:GetAttribute("NoFallSlow") ~= true then
                        char:SetAttribute("NoFallSlow", true)
                    end
                end)
            elseif LP.Character then
                LP.Character:SetAttribute("NoFallSlow", false)
            end
        end

        function Extras.SetDirectionalMovementDisabled(on)
            State.DisableDirectionalMovement = on
            if on then
                LoopWhile("DisableDirectionalMovement", 0.2, function()
                    if LP.Character then
                        LP.Character:SetAttribute("DirectionalMovementDisabled", true)
                    end
                end)
            elseif LP.Character then
                LP.Character:SetAttribute("DirectionalMovementDisabled", false)
            end
        end

        function Extras.SetDirectionalSpeedDisabled(on)
            State.DisableDirectionalSpeed = on
            pcall(function()
                local module = require(ReplicatedStorage.Systems.Character.QualityOfLife.DirectionalSpeed)
                if on then module:Destroy() else module:Start() end
            end)
        end

        ------------------------------------------------------------------
        -- ANTIS: status effects
        -- Wraps every function of the effect's module so it does nothing
        -- while the matching State flag is on.
        ------------------------------------------------------------------
        local wrappedEffects = {}

        local function FindStatusEffectModule(effectName)
            local modules = ReplicatedStorage:FindFirstChild("Modules")
            local effects = modules and modules:FindFirstChild("Schematics")
            effects = effects and effects:FindFirstChild("StatusEffects")
            if not effects then return nil end

            if effects:FindFirstChild(effectName) then
                return effects[effectName]
            end
            for _, group in ipairs({ "KillerExclusive", "SurvivorExclusive" }) do
                local folder = effects:FindFirstChild(group)
                if folder and folder:FindFirstChild(effectName) then
                    return folder[effectName]
                end
            end
            return nil
        end

        function Extras.BlockStatusEffect(effectName, stateKey)
            local moduleScript = FindStatusEffectModule(effectName)
            if not moduleScript or wrappedEffects[moduleScript] then return end

            local ok, effectModule = pcall(require, moduleScript)
            if not (ok and type(effectModule) == "table") then return end

            for key, original in pairs(effectModule) do
                if type(original) == "function" then
                    effectModule[key] = function(...)
                        if State[stateKey] then return end
                        return original(...)
                    end
                end
            end
            wrappedEffects[moduleScript] = true
        end

        ------------------------------------------------------------------
        -- ANTIS: anti pull (bloodhook, void star, azure tentacles)
        ------------------------------------------------------------------
        local pullChildConn, pullCharConn

        local PULL_CLASSES = { "AlignPosition", "LinearVelocity", "BodyVelocity", "BodyPosition" }

        local function StripPullForces(instance)
            if IsKiller(LP.Character) then return end
            if instance.Name == "CatchVelocity" then
                instance:Destroy()
                return
            end
            for _, className in ipairs(PULL_CLASSES) do
                if instance:IsA(className) then
                    instance:Destroy()
                    return
                end
            end
        end

        local function WatchCharacterForPull(character)
            pullChildConn = Drop(pullChildConn)
            local root = character and character:WaitForChild("HumanoidRootPart", 5)
            if not root then return end

            for _, child in ipairs(root:GetChildren()) do
                StripPullForces(child)
            end
            pullChildConn = root.ChildAdded:Connect(function(child)
                task.wait()
                if State.AntiPull and child.Parent then
                    StripPullForces(child)
                end
            end)
        end

        function Extras.SetAntiPull(on)
            State.AntiPull = on
            pullChildConn = Drop(pullChildConn)
            pullCharConn = Drop(pullCharConn)
            if on then
                WatchCharacterForPull(LP.Character)
                pullCharConn = LP.CharacterAdded:Connect(WatchCharacterForPull)
            end
        end

        ------------------------------------------------------------------
        -- ANTIS: walkable puddles (john doe / nosferatu)
        ------------------------------------------------------------------
        local puddleConn

        local function IsPuddlePart(inst)
            return inst:IsA("BasePart") and (inst.Name == "Shadow" or inst.Name:sub(-6) == "Puddle")
        end

        function Extras.SetWalkablePuddles(on)
            State.WalkablePuddles = on
            puddleConn = Drop(puddleConn)

            local root = Ingame()
            if not root then return end

            for _, inst in ipairs(root:GetDescendants()) do
                if IsPuddlePart(inst) then inst.CanTouch = not on end
            end

            if on then
                puddleConn = root.DescendantAdded:Connect(function(inst)
                    if not IsPuddlePart(inst) then return end
                    task.wait()
                    if State.WalkablePuddles and inst.Parent then inst.CanTouch = false end
                end)
            end
        end

        ------------------------------------------------------------------
        -- MISC: end screen / AFK / chat / sidebar
        ------------------------------------------------------------------
        local endScreenConn

        local function PressReturn(endScreen)
            local button = endScreen:FindFirstChild("Return", true)
            if button then firesignal(button.MouseButton1Click) end
        end

        function Extras.SetAutoCloseEndScreen(on)
            State.AutoCloseEndScreen = on
            endScreenConn = Drop(endScreenConn)
            if not on then return end

            for _, child in ipairs(PlayerGui:GetChildren()) do
                if child.Name == "EndScreen" then
                    task.wait(0.1)
                    PressReturn(child)
                end
            end
            endScreenConn = PlayerGui.ChildAdded:Connect(function(child)
                if child.Name == "EndScreen" then
                    task.wait(0.2)
                    PressReturn(child)
                end
            end)
        end

        function Extras.SetDisableAFKInsanity(on)
            State.DisableAFKInsanity = on
            if on then
                LoopWhile("DisableAFKInsanity", 5, function()
                    firesignal(UserInputService.InputEnded, {})
                end)
            end
        end

        local chatConfig, chatEnabledConn, chatAddedConn

        local function ForceChatEnabled()
            chatConfig = chatConfig or TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
            if chatConfig and not chatConfig.Enabled then
                chatConfig.Enabled = true
            end
        end

        function Extras.SetChatAlwaysOn(on)
            chatEnabledConn = Drop(chatEnabledConn)
            chatAddedConn = Drop(chatAddedConn)
            if not on then return end

            ForceChatEnabled()
            if chatConfig then
                chatEnabledConn = chatConfig:GetPropertyChangedSignal("Enabled"):Connect(ForceChatEnabled)
            end
            chatAddedConn = TextChatService.ChildAdded:Connect(function(child)
                if not child:IsA("ChatWindowConfiguration") then return end
                chatConfig = child
                ForceChatEnabled()
                chatEnabledConn = Drop(chatEnabledConn)
                chatEnabledConn = chatConfig:GetPropertyChangedSignal("Enabled"):Connect(ForceChatEnabled)
            end)
        end

        function Extras.SetSidebarVisible(on)
            State.SidebarVisible = on

            local function Sidebar()
                local mainUI = PlayerGui:FindFirstChild("MainUI")
                return mainUI and mainUI:FindFirstChild("Sidebar")
            end

            local function SetButtons(visible)
                pcall(function()
                    local handler = require(ReplicatedStorage.Systems.Player.UI.SidebarHandler)
                    handler:ToggleSidebarButtons(visible)
                end)
            end

            if not on then
                SetButtons(false)
                local sidebar = Sidebar()
                if sidebar then sidebar.Visible = false end
                return
            end

            LoopWhile("SidebarVisible", 0.2, function()
                SetButtons(true)
                local sidebar = Sidebar()
                if sidebar and not sidebar.Visible then sidebar.Visible = true end
            end)
        end

        ------------------------------------------------------------------
        -- MISC: camera
        ------------------------------------------------------------------
        -- Zoom out as far as you like and stop the camera being pushed in by walls
        function Extras.SetInfiniteZoom(on)
            LP.CameraMaxZoomDistance = on and 10000 or 12

            local setConstant = (debug and debug.setconstant) or setconstant
            local getConstants = (debug and debug.getconstants) or getconstants
            if not (setConstant and getConstants and getgc) then return end

            pcall(function()
                local popper = LP.PlayerScripts.PlayerModule.CameraModule.ZoomController.Popper
                for _, fn in ipairs(getgc()) do
                    if type(fn) == "function" and getfenv(fn).script == popper then
                        for index, constant in pairs(getConstants(fn)) do
                            local value = tonumber(constant)
                            if on and value == 0.25 then
                                setConstant(fn, index, 0)
                            elseif not on and value == 0 then
                                setConstant(fn, index, 0.25)
                            end
                        end
                    end
                end
            end)
        end

        local fovConn

        local function ApplyFOV()
            local char = LP.Character
            if not char then return end
            pcall(function()
                char.FOVMultipliers.FOVSetting.Value = State.CustomFOVMultiplier
            end)
        end

        function Extras.SetCustomFOV(on)
            fovConn = Drop(fovConn)
            if on then
                fovConn = RunService.RenderStepped:Connect(ApplyFOV)
                TrackConnection(fovConn)
            else
                pcall(function() LP.Character.FOVMultipliers.FOVSetting.Value = 1 end)
            end
        end

        ------------------------------------------------------------------
        -- MISC: round timer position
        ------------------------------------------------------------------
        local TIMER_X = { Left = 0.1, Middle = 0.5, Right = 0.9 }

        function Extras.SetTimerPosition(side)
            local timer = PlayerGui:FindFirstChild("RoundTimer")
            if timer and timer:FindFirstChild("Main") then
                timer.Main.Position = UDim2.new(TIMER_X[side] or 0.5, 0, -0.018, 0)
            end
        end

        ------------------------------------------------------------------
        -- MISC: movement / character
        ------------------------------------------------------------------
        -- Anti footsteps: stop the "FootSP" packet from being sent.
        local footstepsHooked = false

        function Extras.SetAntiFootsteps(on)
            State.AntiFootsteps = on
            if footstepsHooked then return end

            local network = GetNetworkModule()
            if not (network and network.FireServerConnection) then return end

            local original = network.FireServerConnection
            network.FireServerConnection = function(self, name, ...)
                if name == "FootSP" and State.AntiFootsteps then return end
                return original(self, name, ...)
            end
            footstepsHooked = true
        end

        function Extras.SetFakeInjured(on)
            local ok, actors = pcall(function()
                return require(ReplicatedStorage.Modules.Gameplay.Actors)
            end)
            local mine = ok and actors.CurrentActors[LP]
            if not mine then return end

            mine.AnimationType = on and "Injured" or nil

            -- poke the humanoid so the game re-evaluates the animation
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = hum.Health end
        end

        -- Fake clone: plays the clone-run animation while you move.
        local FAKE_CLONE_ANIM = "rbxassetid://136252471123500"

        function Extras.SetFakeClone(on)
            State.FakeClone = on
            if not on then return end

            task.spawn(function()
                local track
                while ScriptRunning and State.FakeClone do
                    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
                    local animator = hum and hum:FindFirstChildOfClass("Animator")

                    if track and not track.IsPlaying then track = nil end

                    if animator then
                        local moving = hum.MoveDirection.Magnitude > 0.1
                        if moving and not track then
                            local ok, newTrack = pcall(function()
                                local anim = Instance.new("Animation")
                                anim.AnimationId = FAKE_CLONE_ANIM
                                local t = animator:LoadAnimation(anim)
                                t.Priority = Enum.AnimationPriority.Action4
                                t.Looped = true
                                t:Play(0.1)
                                return t
                            end)
                            track = ok and newTrack or nil
                        elseif not moving and track then
                            pcall(function() track:Stop(); track:Destroy() end)
                            track = nil
                        end
                    end
                    task.wait(0.25)
                end
                if track then pcall(function() track:Stop(); track:Destroy() end) end
            end)
        end

        -- Noclip: turns collision off on the body parts (re-applied each second).
        local NOCLIP_PARTS = { "Torso", "HumanoidRootPart", "Head", "CollisionHitbox" }

        function Extras.SetNoclip(on)
            State.Noclip = on
            local function Apply(canCollide)
                local char = LP.Character
                if not char then return end
                for _, name in ipairs(NOCLIP_PARTS) do
                    local part = char:FindFirstChild(name)
                    if part then part.CanCollide = canCollide end
                end
            end

            if not on then
                Apply(true)
                return
            end
            LoopWhile("Noclip", 1, function() Apply(false) end)
            Apply(false)
        end

        function Extras.TurnOnJump()
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = 50 end
        end

        function Extras.ResetCharacter()
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = 0 end
        end

        function Extras.Rejoin()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
        end

        ------------------------------------------------------------------
        -- Hook up the status-effect antis once the effect modules exist
        ------------------------------------------------------------------
        local STATUS_ANTIS = {
            { Effect = "Bleeding",      Key = "AntiBleeding" },
            { Effect = "Hallucination", Key = "AntiHallucination" },
            { Effect = "Hacked",        Key = "AntiHacked" },
            { Effect = "Corrupted",     Key = "AntiCorrupted" },
            { Effect = "Subspaced",     Key = "AntiSubspaced" },
        }
        Extras.StatusAntis = STATUS_ANTIS
    end

    -- Window UI Creation
    local window = windui:CreateWindow({
        Title = "forsaken8z",
        Icon = "shield-alert",
        Author = "xane",
        Folder = "forsaken_plus_delta"
    })

    -- UI Tabs
    local gen_tab = window:Tab({ Title = "generator", Icon = "zap" })
    local block_tab = window:Tab({ Title = "auto block", Icon = "shield" })
    local stamina_tab = window:Tab({ Title = "stamina", Icon = "battery-charging" })
    local feat_tab = window:Tab({ Title = "features", Icon = "sparkles" })
    local effects_tab = window:Tab({ Title = "effects", Icon = "wand" })
    local survivors_tab = window:Tab({ Title = "survivors", Icon = "user-check" })
    local killers_tab = window:Tab({ Title = "killers", Icon = "skull" })
    survivors_tab:Paragraph({ Title = "november 7th, 2026: improved auto aims. (now, its much/ better)" })
    killers_tab:Paragraph({ Title = "november 7th, 2026: improved auto aims. (now, its much/ better)" })
    local items_tab = window:Tab({ Title = "items", Icon = "package" })
    local esp_tab = window:Tab({ Title = "visuals (esp)", Icon = "eye" })
    local esp_names_tab = window:Tab({ Title = "esp names", Icon = "tag" })
    local players_tab = window:Tab({ Title = "players tab", Icon = "users" })
    local settings_tab = window:Tab({ Title = "settings", Icon = "settings" })

    -- automation tab (autopilot): hands-free generators, dodging, abilities, ally assist
    do
        local function CreateAutopilot()
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local UserInputService = game:GetService("UserInputService")
        local LocalPlayer = Players.LocalPlayer
        assert(RunService:IsClient() and LocalPlayer, "Forsaken Autopilot must run on the client.")

        local env = _G
        if type(getgenv) == "function" then
            local ok, value = pcall(getgenv)
            if ok and type(value) == "table" then env = value end
        end
        if env.ForsakenAutopilot and type(env.ForsakenAutopilot.Destroy) == "function" then
            pcall(function() env.ForsakenAutopilot:Destroy() end)
        end

        local DebugHook = {fn = nil}
        local function debugLog(message)
            local hook = DebugHook.fn
            if hook then pcall(hook, message) end
        end
        local Bot = {Enabled = false, Destroyed = false, State = "DISABLED", LastNotice = "Ready. Enable when a round starts."}
        env.ForsakenAutopilot = Bot
        local Settings = {
            Objectives = true,
            Abilities = true,
            CharacterCombos = true,
            DodgeAttacks = true,
            Items = true,
            AssistAllies = true,
            AssistMinHealth = 0.6,
            AssistMinStaminaMargin = 15,
            AssistWindow = 5,
            AssistRest = 10,
            AssistGuardTime = 18,
            AvoidKiller = true,
            RequireThreat = true,
            Jump = true,
            AllowDrops = true,
            MaxDropHeight = 80,
            EmergencySprint = true,
            Reserve = 25,
            Resume = 42,
            KillerReserve = 5,
            KillerResume = 20,
            VeeronicaReserve = 40,
            VeeronicaResume = 50,
            EmergencyDistance = 12,
            LongSprintDistance = 40,
            DetectionDistance = 62,
            ContactDistance = 18,
            RoamMinDistance = 50,
            RoamMaxDistance = 100,
            BackupMinDistance = 100,
            BackupMaxDistance = 150,
            CornerReactionTime = 0.75,
            SafeDistance = 80,
            FleeMultiplier = 1.5,
            MinFleeTime = 6,
            AntiCircle = true,
            DebugNotifications = true,
        }
        Bot.Settings = Settings
        local connections = {}
        local function connect(signal, callback)
            local c = signal:Connect(callback)
            table.insert(connections, c)
            return c
        end
        local function notify(message)
            Bot.LastNotice = tostring(message)
        end
        Bot.DebugHook = DebugHook

        -- Hold/release input at transitions. Movement itself has one frame writer.
        local Input = {held = {}, backends = {}, virtual = nil, manager = nil}
        pcall(function() Input.virtual = UserInputService:CreateVirtualInput() end)
        pcall(function() Input.manager = game:GetService("VirtualInputManager") end)
        function Input:SetKey(key, down)
            if self.held[key] == down then return true end
            local function send(backend)
                if backend == "virtual" then
                    self.virtual:SendKey(down, key, false)
                elseif backend == "manager" then
                    self.manager:SendKeyEvent(down, key, false, game)
                elseif backend == "host" then
                    local special = {LeftShift = 0xA0, RightShift = 0xA1, LeftControl = 0xA2, RightControl = 0xA3, LeftAlt = 0xA4, RightAlt = 0xA5, Space = 0x20, Return = 0x0D}
                    local code = special[key.Name]
                    if not code and #key.Name == 1 then code = string.byte(key.Name:upper()) end
                    local f = tonumber(key.Name:match("^F(%d+)$"))
                    if not code and f and f >= 1 and f <= 24 then code = 0x6F + f end
                    assert(code, "Unsupported host input key")
                    if down then keypress(code) else keyrelease(code) end
                end
            end
            local backend = self.backends[key]
            if backend then
                local ok = pcall(send, backend)
                if ok then self.held[key] = down; return true end
            end
            local available = {}
            if self.virtual then table.insert(available, "virtual") end
            if self.manager then table.insert(available, "manager") end
            if type(keypress) == "function" and type(keyrelease) == "function" then table.insert(available, "host") end
            for _, candidate in ipairs(available) do
                if pcall(send, candidate) then
                    self.backends[key], self.held[key] = candidate, down
                    return true
                end
            end
            return false
        end
        function Input:ReleaseAll()
            for key, down in pairs(self.held) do
                if down then self:SetKey(key, false) end
            end
        end

        local ctx = {
            player = LocalPlayer, settings = Settings, input = Input,
            ReplicatedStorage = ReplicatedStorage, notify = notify,
        }
        ctx.face = function(targetRoot, duration)
            if Bot.Enabled and Bot.Movement and Bot.Movement.Face then Bot.Movement:Face(targetRoot, duration) end
        end
        ctx.getMovement = function() return Bot.Movement end
        ctx.cameraAim = function(target, duration)
            if Bot.Enabled and Bot.Movement and Bot.Movement.AimCamera then Bot.Movement:AimCamera(target, duration) end
        end
        ctx.attackFace = function(target, duration, predictor)
            if Bot.Enabled and Bot.Movement then return Bot.Movement:LockAim(target, duration, predictor) end
        end
        ctx.clearAttackFace = function()
            if Bot.Movement then Bot.Movement:ClearAttackAim() end
        end

        local function findPath(root, parts)
            local cursor = root
            for _, name in ipairs(parts) do
                cursor = cursor and cursor:FindFirstChild(name)
            end
            return cursor
        end
        local function flat(v) return Vector3.new(v.X, 0, v.Z) end
        local function unit(v, fallback)
            return v.Magnitude > 0.01 and v.Unit or (fallback or Vector3.new(1, 0, 0))
        end
        local function body(model)
            if not model or not model:IsA("Model") then return nil end
            local h = model:FindFirstChildOfClass("Humanoid")
            local r = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
            if h and r and h.Health > 0 and model.Parent then return r, h end
        end

        local ray = RaycastParams.new()
        ray.FilterType = Enum.RaycastFilterType.Exclude
        ray.RespectCanCollide = true
        local function filters(character)
            local result = {character}
            local folder = workspace:FindFirstChild("Players")
            if folder then table.insert(result, folder) end
            return result
        end
        local function visible(a, b, character)
            ray.FilterDescendantsInstances = filters(character)
            local offset = b - a
            return workspace:Raycast(a + Vector3.new(0, 1, 0), offset, ray) == nil
        end
        local function ground(point, character)
            ray.FilterDescendantsInstances = filters(character)
            local dropHeight = Settings.AllowDrops and math.clamp(tonumber(Settings.MaxDropHeight) or 40, 10, 80) or 20
            local hit = workspace:Raycast(point + Vector3.new(0, 12, 0), Vector3.new(0, -(dropHeight + 16), 0), ray)
            if hit and hit.Normal.Y >= 0.5 then
                local root, humanoid = body(character)
                local standHeight = root and humanoid and (humanoid.HipHeight + root.Size.Y * 0.5) or 2.5
                if humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 then
                    local leg = character:FindFirstChild("Left Leg") or character:FindFirstChild("Right Leg")
                    if leg and leg:IsA("BasePart") then standHeight += leg.Size.Y end
                end
                local position = hit.Position + Vector3.new(0, standHeight, 0)
                if point.Y - position.Y <= dropHeight then return position end
            end
        end


        local Movement = (function()
        -- Movement adapter for the inspected place. All speed and stamina changes remain
        -- inside the game's Sprinting module. No CFrame teleporting or WalkSpeed writes.
        local Movement = {}
        Movement.__index = Movement

        local ZERO = Vector3.zero
        local UP = Vector3.yAxis
        local function flat(v)
            return Vector3.new(v.X, 0, v.Z)
        end
        local function unit(v)
            local f = flat(v)
            return f.Magnitude > 0.001 and f.Unit or ZERO
        end
        local function find(parent, ...)
            for _, name in ipairs({...}) do
                parent = parent and parent:FindFirstChild(name)
            end
            return parent
        end

        function Movement.new(ctx)
            local self = setmetatable({}, Movement)
            self.ctx = ctx
            self.player = ctx.player or game:GetService("Players").LocalPlayer
            self.settings = ctx.settings or {}
            self.workspace = game:GetService("Workspace")
            self.pathfinding = game:GetService("PathfindingService")
            self.runService = game:GetService("RunService")
            self.options = {}
            self.sense = {}
            self.direction = ZERO
            self.route = nil
            self.routeIndex = 1
            self.revision = 0
            self.nextPlan = 0
            self.nextRay = 0
            self.nextJump = 0
            self.goalReached = false
            self.status = "Idle"
            self.pathStatus = "Idle"
            self.recovering = false
            self.lastProgress = os.clock()
            self.lastStamina = nil
            self.bindName = "ForsakenBotMovement_" .. tostring(math.random(100000, 999999))
            local sprintModule = find(game:GetService("ReplicatedStorage"), "Systems", "Character", "Game", "Sprinting")
            if sprintModule then
                local ok, result = pcall(require, sprintModule)
                if ok and type(result) == "table" then
                    self.sprint = result
                end
            end
            local shiftModule = find(game:GetService("ReplicatedStorage"), "Systems", "Player", "Game", "SmoothShiftLock")
            if shiftModule then
                local ok, result = pcall(require, shiftModule)
                if ok and type(result) == "table" then self.shiftlock = result end
            end
            self.runService:BindToRenderStep(self.bindName, Enum.RenderPriority.Input.Value + 2, function(dt)
                self:_step(math.min(dt, 0.1))
            end)
            self.cameraBindName, self.aimBindName = self.bindName .. "_Camera", self.bindName .. "_Aim"
            local cameraPriority = Enum.RenderPriority.Camera and Enum.RenderPriority.Camera.Value or 200
            local lastPriority = Enum.RenderPriority.Last and Enum.RenderPriority.Last.Value or 2000
            -- Native dash steering reads the camera after its normal update. Apply the
            -- avatar's attack facing after the character's own animation/dash callbacks.
            self.runService:BindToRenderStep(self.cameraBindName, cameraPriority + 1, function(dt)
                self:_cameraStep(os.clock(), math.min(dt, 0.1))
            end)
            self.runService:BindToRenderStep(self.aimBindName, lastPriority + 1, function(dt)
                self:_attackAimStep(math.min(dt, 0.1))
            end)
            return self
        end

        function Movement:_controls()
            if self.controls then return self.controls end
            local module = find(self.player, "PlayerScripts", "PlayerModule")
            if module then
                local ok, result = pcall(require, module)
                if ok and type(result.GetControls) == "function" then
                    self.controls = result:GetControls()
                end
            end
            return self.controls
        end

        function Movement:_takeControl()
            if self.ownsMovement then return end
            self.ownsMovement = true
            local controls = self:_controls()
            if controls then
                self.previousControlEnabled = controls.controlsEnabled ~= false
                controls:Disable()
            end
            self:_suspendShiftLock()
        end

        function Movement:_releaseControl()
            if not self.ownsMovement then return end
            self.ownsMovement = false
            if self.controls and self.previousControlEnabled then
                self.controls:Enable()
            end
            self.previousControlEnabled = nil
            self:_restoreShiftLock()
        end

        function Movement:_suspendShiftLock()
            local shiftlock = self.shiftlock
            if not shiftlock or type(shiftlock.Enabled) ~= "boolean" or not shiftlock._shiftlockMaid
                or type(shiftlock.ToggleShiftLock) ~= "function" then return end
            if self.previousShiftLockEnabled == nil then self.previousShiftLockEnabled = shiftlock.Enabled end
            if shiftlock.Enabled then
                -- Its RenderStepped callback otherwise rotates toward the camera every
                -- frame and competes with flight/pursuit direction and short melee aim.
                pcall(shiftlock.ToggleShiftLock, shiftlock, false)
            end
        end

        function Movement:_restoreShiftLock()
            local shiftlock = self.shiftlock
            local previous = self.previousShiftLockEnabled
            if previous ~= nil and shiftlock and type(shiftlock.Enabled) == "boolean" and shiftlock._shiftlockMaid
                and type(shiftlock.ToggleShiftLock) == "function" and shiftlock.Enabled ~= previous then
                pcall(shiftlock.ToggleShiftLock, shiftlock, previous)
            end
            self.previousShiftLockEnabled = nil
        end

        function Movement:_installSprintFallback()
            local sprint = self.sprint
            if not sprint or self.sprintWrapper then return end
            if type(sprint.IsSprintKeyHeld) ~= "function" then return end
            self.originalSprintQuery = sprint.IsSprintKeyHeld
            local original = self.originalSprintQuery
            self.sprintWrapper = function(module)
                -- The inspected game polls this method every Heartbeat. Returning the
                -- bot's held-key intent preserves all normal sprint restrictions.
                if self.ownsMovement and not self.destroyed then
                    return self.sprintHeld == true
                end
                return original(module)
            end
            sprint.IsSprintKeyHeld = self.sprintWrapper
            self.sprintMode = "Game sprint input adapter"
        end

        function Movement:_restoreSprintFallback()
            if self.sprint and self.sprintWrapper and self.sprint.IsSprintKeyHeld == self.sprintWrapper then
                self.sprint.IsSprintKeyHeld = self.originalSprintQuery
            end
            self.sprintWrapper = nil
            self.originalSprintQuery = nil
        end

        function Movement:_setSprint(want)
            want = want == true
            if self.sprintHeld == want then return end
            self.sprintHeld = want
            local input = self.ctx.input
            local ok, accepted = false, false
            if input and type(input.SetKey) == "function" then
                ok, accepted = pcall(input.SetKey, input, Enum.KeyCode.LeftShift, want)
            end
            if ok and accepted == true then
                self.sprintMode = "Hold LeftShift"
            elseif want then
                self:_installSprintFallback()
            end
            -- Do not call Toggle directly: the game's key polling would undo it and
            -- repeatedly restart the speed tween, causing visible sprint animation jitter.
        end

        function Movement:GetStamina()
            local sprint = self.sprint
            if sprint and type(sprint.Stamina) == "number" then
                self.lastStamina = sprint.Stamina
                return sprint.Stamina, sprint.MaxStamina or 100
            end
            local sense = self.sense
            if type(sense.stamina) == "number" then return sense.stamina, 100 end
            return nil, nil
        end

        function Movement:_sprintPolicy(moving, now)
            local role = self.sense.role == "Killer" and "Killer" or "Survivor"
            if self.staminaRole ~= role then
                self.staminaRole = role
                self.recovering = false
                self.emergencyUntil = nil
            end
            local sprint = self.sprint
            local requested = self.options.sprint
            if self.evasion or self.evasionContext then requested = true end
            if requested == nil then
                local root = self.character and self.character:FindFirstChild("HumanoidRootPart")
                local distance = root and self.goal and flat(self.goal - root.Position).Magnitude or 0
                requested = self.options.mode == "flee" or self.options.mode == "chase"
                    or distance > (tonumber(self.settings.LongSprintDistance) or 40)
            end
            if self.sense.noSprint or not moving or not requested or (sprint and (not sprint.CanSprint or not sprint.BindsEnabled)) then
                self:_setSprint(false)
                return
            end
            local value = self:GetStamina()
            if not value then
                self:_setSprint(false)
                return
            end
            if sprint and sprint.StaminaLossDisabled and value > (sprint.MinStamina or 0) then
                self.recovering = false
                self:_setSprint(true)
                return
            end
            local reserve, resume = self:_reservePolicy()
            local loss = sprint and tonumber(sprint.StaminaLoss) or 10
            -- Leave headroom for one control tick and the game's stamina update.
            local stopAt = reserve + math.max(1.5, loss * 0.18)
            local dangerDistance = tonumber(self.settings.EmergencyDistance) or 12
            local killerDistance = tonumber(self.sense.killerDistance) or math.huge
            local emergency = (self.options.emergency == true or (self.evasion and self.evasion.emergency)) and self.sense.role ~= "Killer"
                and killerDistance < dangerDistance and (self.sense.fleeing == true or self.sense.underAttack == true)
            if emergency and value > math.max(2, loss * 0.2) then
                self.emergencyUntil = now + 0.8
            end
            local canSpendReserve = role ~= "Killer" and (emergency or (self.emergencyUntil or 0) > now)
            if canSpendReserve and value > 2 then
                self:_setSprint(true)
                return
            end
            if self.sprintHeld then
                if value <= stopAt then
                    self.recovering = true
                    self:_setSprint(false)
                end
            elseif value >= (self.recovering and resume or stopAt + 2) then
                self.recovering = false
                self:_setSprint(true)
            end
        end

        function Movement:_reservePolicy()
            local killer = self.sense.role == "Killer"
            local reserve, resume
            if killer then
                reserve = tonumber(self.settings.KillerReserve) or 5
                resume = tonumber(self.settings.KillerResume) or 20
            elseif self.sense.actor and self.sense.actor.ActorName == "Veeronica" then
                if self.sense.actor.State and self.sense.actor.State.isSkating then return 0, 0 end
                reserve = tonumber(self.settings.VeeronicaReserve) or 40
                resume = tonumber(self.settings.VeeronicaResume) or 50
            else
                reserve = tonumber(self.settings.Reserve) or 25
                resume = tonumber(self.settings.Resume) or 42
            end
            return reserve, math.max(reserve + 6, resume)
        end

        function Movement:_clearRoute()
            if self.blockedConnection then self.blockedConnection:Disconnect() end
            self.blockedConnection = nil
            if self.path then self.path:Destroy() end
            self.route = nil
            self.routeIndex = 1
            self.path = nil
            self.routeCommitted = false
            self.committedGoal = nil
            self.routeBlocked = false
        end

        function Movement:SetGoal(position, options)
            if self.destroyed or typeof(position) ~= "Vector3" then return end
            options = options or {}
            local previousMode = self.options.mode
            if self.routeCommitted and (previousMode ~= options.mode or not self.committedGoal
                or (position - self.committedGoal).Magnitude > 3) then
                self.routeCommitted = false
                self.committedGoal = nil
                self.forcePlan, self.nextPlan, self.nextRay = true, 0, 0
            end
            if not self.goal or (position - self.goal).Magnitude > 2 then
                self.goalReached = false
            end
            self.goal = position
            self.options = options
            if previousMode ~= options.mode then
                self.evasion, self.evasionContext, self.finishedEvasion = nil, nil, nil
                self.drop = nil
                self.airDirection = nil
                self.revision += 1
                self:_clearRoute()
                self.nextPlan = 0
                self.nextRay = 0
            end
            self:_takeControl()
        end

        function Movement:AimCamera(target, duration)
            self.cameraTarget, self.cameraUntil = target, os.clock() + math.clamp(tonumber(duration) or 0.3, 0.05, 1.5)
        end

        function Movement:SetEvasion(plan)
            if self.destroyed then return end
            if plan and typeof(plan.goal) == "Vector3" then
                if plan == self.finishedEvasion then return end
                if type(plan.expires) ~= "number" or plan.expires <= os.clock() then return end
                local character = self.player.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                if not root then return end
                local context = self.evasionContext
                if not context or context.character ~= character then
                    context = {character = character, origin = root.Position, trail = {root.Position},
                        route = self.route, routeIndex = self.routeIndex, goal = self.goal,
                        temporary = not self.ownsMovement, phase = "dodge"}
                    self.evasionContext = context
                    -- A computation started before the dodge has a stale starting
                    -- position. Keep its existing route, but reject its pending result.
                    self.revision += 1
                end
                context.phase, context.plan = "dodge", plan
                self.evasion = plan
                self:_takeControl()
            else
                self.evasion = nil
                if self.evasionContext then self:_beginEvasionRejoin(os.clock())
                else self.finishedEvasion = nil end
            end
        end

        function Movement:_recordEvasionPoint(root)
            local context = self.evasionContext
            if not context then return end
            local last = context.trail[#context.trail]
            if not last or (root.Position - last).Magnitude >= 1.25 then
                table.insert(context.trail, root.Position)
                if #context.trail > 32 then table.remove(context.trail, 2) end
            end
        end

        function Movement:_beginEvasionRejoin(now)
            local context = self.evasionContext
            if not context or context.phase == "rejoin" then return end
            self.finishedEvasion = context.plan
            self.evasion = nil
            context.phase, context.returnIndex, context.untilTime = "rejoin", #context.trail, now + 3
        end

        function Movement:_finishEvasion(humanoid)
            local context = self.evasionContext
            self.evasion, self.evasionContext = nil, nil
            if context and context.temporary and not self.goal then
                self.direction = ZERO
                humanoid:Move(ZERO, false)
                self:_setSprint(false)
                self:_restoreSprintFallback()
                self:_releaseControl()
                self.status = "Idle"
            end
        end

        function Movement:_joinAfterEvasion(root, params)
            local route = self.route
            if not route then
                return self.goal and self:_clearLine(root.Position, self.goal, params) or false
            end
            if self.plannedGoal and self.goal and (self.plannedGoal - self.goal).Magnitude > 7 then return false end
            local context = self.evasionContext
            local startIndex = context and context.route == route and math.max(self.routeIndex, context.routeIndex) or self.routeIndex
            local best, bestDistance
            for index = startIndex, #route do
                -- A visible point beyond a jump does not prove the jump was performed.
                -- Only ordinary route progression may advance past its takeoff point.
                if index > startIndex and route[index - 1].Action == Enum.PathWaypointAction.Jump then break end
                local point = route[index].Position
                local d = (point - root.Position).Magnitude
                if (not bestDistance or d < bestDistance) and self:_clearLine(root.Position, point, params) then
                    best, bestDistance = index, d
                end
            end
            if best then self.routeIndex = best; return true end
            return false
        end

        function Movement:_writeEvasion(root, humanoid, point, params, now, dt, returning)
            local desired = unit(point - root.Position)
            local blend = self.direction:Lerp(desired, 1 - math.exp(-18 * dt))
            self.direction = blend.Magnitude > 0.05 and blend.Unit or desired
            if self.direction:Dot(desired) < 0.1 or not self:_clearLine(root.Position,
                root.Position + self.direction * math.max(1.5, humanoid.WalkSpeed * dt * 2), params) then
                self.direction = desired
            end
            humanoid:Move(self.direction, false)
            self:_sprintPolicy(true, now)
            self.goalReached = false
            self.status = returning and "Rejoining retained route" or "Dodging / " .. tostring(self.evasion and self.evasion.label or "attack")
        end

        function Movement:_evasionStep(root, humanoid, params, now, dt, airborne)
            local context = self.evasionContext
            if not context then return false end
            local plan = self.evasion
            if context.phase == "dodge" then
                self:_recordEvasionPoint(root)
                if not plan or now >= plan.expires or not self:_clearLine(root.Position, plan.goal, params)
                    or flat(plan.goal - root.Position).Magnitude <= 1 then
                    self:_beginEvasionRejoin(now)
                elseif not airborne and not self.drop then
                    self:_writeEvasion(root, humanoid, plan.goal, params, now, dt, false)
                    return true
                end
            end
            if context.phase ~= "rejoin" or self.drop then return false end
            if not self.goal then self:_finishEvasion(humanoid); return true end
            if airborne then return false end
            if self:_joinAfterEvasion(root, params) then
                self:_finishEvasion(humanoid)
                self.nextRay = 0
                return false
            end
            local index = context.returnIndex
            while index >= 1 and (context.trail[index] - root.Position).Magnitude < 1.4 do index -= 1 end
            context.returnIndex = index
            if now < context.untilTime then
                for candidate = index, 1, -1 do
                    local point = context.trail[candidate]
                    if self:_clearLine(root.Position, point, params) then
                        context.returnIndex = candidate
                        self:_writeEvasion(root, humanoid, point, params, now, dt, true)
                        return true
                    end
                end
            end
            -- A door or obstacle may have moved since the dodge. Retain the destination
            -- and normal controls, discard only the obsolete waypoints, and let the
            -- normal planner/local corridor recover without issuing Stop().
            self:_finishEvasion(humanoid)
            self:_clearRoute()
            self.forcePlan, self.nextPlan, self.nextRay = true, 0, 0
            self.routeFailure = "Dodge rejoin obstructed; finding a new route"
            return false
        end

        function Movement:_cameraStep(now, dt)
            if self.destroyed then return end
            local point
            if self.attackAim then
                -- Native hook/dash constraints and the avatar must use the same lead,
                -- including target motion between the slower decision-loop updates.
                point = self:_attackPoint(self.attackAim)
                if not point then return end
            else
                if not self.cameraTarget then return end
                if now >= (self.cameraUntil or 0) then self.cameraTarget = nil; return end
                local target = self.cameraTarget
                point = typeof(target) == "Vector3" and target or target.Parent and target.Position
            end
            local camera = self.workspace.CurrentCamera
            if not camera or not point or (point - camera.CFrame.Position).Magnitude < 0.1 then return end
            -- The native dash/skate callbacks steer from the real camera. Retain the
            -- camera's position, type, and subject; temporarily turn its look direction.
            camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(camera.CFrame.Position, point), 1 - math.exp(-22 * dt))
        end

        function Movement:FollowRoute(goal, metadata, options)
            if self.destroyed or typeof(goal) ~= "Vector3" or type(metadata) ~= "table" or type(metadata.route) ~= "table" then return false end
            local character = self.player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if not root or not humanoid or humanoid.Health <= 0 or #metadata.route < 2 or #metadata.route > 160 then return false end
            if metadata.character and metadata.character ~= character then return false end
            local route = {}
            for index, point in ipairs(metadata.route) do
                if typeof(point) ~= "Vector3" or point.X ~= point.X or point.Y ~= point.Y or point.Z ~= point.Z
                    or point.Magnitude > 1000000 then return false end
                local rawAction = metadata.actions and metadata.actions[index]
                local jumping = rawAction == Enum.PathWaypointAction.Jump or rawAction == "Jump"
                if jumping and (self.settings.Jump == false or not humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)
                    or (humanoid.UseJumpPower and humanoid.JumpPower <= 0)
                    or (not humanoid.UseJumpPower and humanoid.JumpHeight <= 0)) then return false end
                table.insert(route, {Position = point, Action = jumping and Enum.PathWaypointAction.Jump or Enum.PathWaypointAction.Walk})
            end
            if (route[#route].Position - goal).Magnitude > 12 then return false end
            local nextIndex = 1
            while nextIndex < #route and flat(route[nextIndex].Position - root.Position).Magnitude < 2
                and math.abs(route[nextIndex].Position.Y - root.Position.Y) < 2.25
                and route[nextIndex].Action ~= Enum.PathWaypointAction.Jump do
                nextIndex += 1
            end
            -- A stale route may start a few steps behind a moving player. Skip only
            -- genuinely reachable initial points; never select a nearest point through
            -- the corner wall or skip the planned jump around it.
            local params = self:_rayParams(character)
            local joined = self:_clearLine(root.Position, route[nextIndex].Position, params)
            if not joined and (route[1].Position - root.Position).Magnitude <= 4 then
                -- Trust a nearby native navmesh start when its center segment is clear,
                -- while still rejecting a stale start on the other side of a wall.
                joined = self.workspace:Raycast(root.Position, route[nextIndex].Position - root.Position, params) == nil
            end
            local closest = joined and flat(route[nextIndex].Position - root.Position).Magnitude or math.huge
            for index = nextIndex + 1, #route do
                if route[index - 1].Action == Enum.PathWaypointAction.Jump then
                    local takeoff, landing = route[index - 1].Position, route[index].Position
                    local jumpDirection = unit(landing - takeoff)
                    local beyondLanding = flat(root.Position - landing)
                    local along = beyondLanding:Dot(jumpDirection)
                    local lateral = (beyondLanding - jumpDirection * along).Magnitude
                    local alreadyLanded = jumpDirection.Magnitude > 0.1 and along >= -0.5 and lateral < 4
                        and math.abs(root.Position.Y - landing.Y) < 2.5
                        and humanoid.FloorMaterial ~= Enum.Material.Air
                    if not alreadyLanded then break end
                end
                local point = route[index].Position
                local d = flat(point - root.Position).Magnitude
                if d < closest and self:_clearLine(root.Position, point, params) then
                    closest, nextIndex, joined = d, index, true
                end
            end
            if not joined then return false end
            self:SetGoal(goal, options or {mode = metadata.kind == "escape" and "flee" or "travel", sprint = true})
            self.revision += 1 -- Any old asynchronous ComputeAsync result is obsolete.
            self:_clearRoute()
            self.character = character
            self.route, self.routeIndex = route, nextIndex
            self.routeCommitted, self.committedGoal = true, goal
            self.plannedGoal, self.lastPlan = goal, os.clock()
            self.pathStatus, self.direct = "Following validated escape route", false
            self.lastRouteAdopted, self.lastProgress = os.clock(), os.clock()
            self.lastPosition = root.Position
            self.progressDistance, self.framePosition = 0, root.Position
            self.localStep, self.routeFailure = nil, nil
            if humanoid.FloorMaterial == Enum.Material.Air and route[nextIndex].Action == Enum.PathWaypointAction.Jump then
                self.routeJumpUntil = os.clock() + 1.5
            end
            self.goalReached = false
            return true
        end

        function Movement:Update(_, sense)
            self.sense = sense or self.sense
        end

        function Movement:Reached()
            return self.goalReached
        end

        function Movement:Face(target, duration)
            if self.destroyed then return false end
            local kind = typeof(target)
            if kind ~= "Vector3" and (kind ~= "Instance" or not target:IsA("BasePart")) then return false end
            self.faceTarget = target
            self.faceUntil = os.clock() + math.clamp(tonumber(duration) or 0.25, 0.05, 1)
            self.faceCharacter = self.player.Character
            return true
        end

        function Movement:LockAim(target, duration, predictor)
            if self.destroyed then return false end
            local kind = typeof(target)
            if kind ~= "Vector3" and (kind ~= "Instance" or not target:IsA("BasePart")) then return false end
            local previous = self.attackAim
            self.attackAim = {target = target, character = self.player.Character,
                expires = os.clock() + math.clamp(tonumber(duration) or 0.4, 0.05, 15),
                predictor = type(predictor) == "function" and predictor or nil}
            -- The normal ability callback may read LookVector immediately. Align once
            -- before that request; subsequent frames track moving targets continuously.
            if not previous or previous.target ~= target or previous.character ~= self.player.Character then
                self:_attackAimStep(0, true)
            end
            return self.attackAim ~= nil
        end

        function Movement:_restoreAttackFacing(force)
            if self.attackFacingHumanoid and not force and self.sense.movementLocked then return end
            local humanoid, saved = self.attackFacingHumanoid, self.attackSavedAutoRotate
            if humanoid and saved ~= nil then
                pcall(function() if humanoid.AutoRotate == false then humanoid.AutoRotate = saved end end)
            end
            self.attackFacingHumanoid, self.attackSavedAutoRotate = nil, nil
            if not self.ownsMovement then self:_restoreShiftLock() end
        end

        function Movement:ClearAttackAim()
            self.attackAim = nil
            self:_restoreAttackFacing(false)
        end

        function Movement:_attackPoint(aim)
            if not aim or aim.character ~= self.player.Character or os.clock() >= aim.expires then return nil end
            local ownHumanoid = aim.character and aim.character:FindFirstChildOfClass("Humanoid")
            if not ownHumanoid or ownHumanoid.Health <= 0 then return nil end
            local target, point = aim.target
            if typeof(target) == "Vector3" then point = target
            elseif target.Parent then
                local targetHumanoid = target.Parent:FindFirstChildOfClass("Humanoid")
                if targetHumanoid and targetHumanoid.Health <= 0 then return nil end
                point = target.Position
            else return nil end
            if aim.predictor then
                local ok, predicted = pcall(aim.predictor)
                if not ok or typeof(predicted) ~= "Vector3" then return nil end
                point = predicted
            end
            if point.X ~= point.X or point.Y ~= point.Y or point.Z ~= point.Z
                or math.abs(point.X) == math.huge or math.abs(point.Y) == math.huge or math.abs(point.Z) == math.huge then return nil end
            return point
        end

        function Movement:_attackAimStep(dt, immediate)
            if self.destroyed then return end
            local aim, character = self.attackAim, self.player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if self.attackFacingHumanoid and self.attackFacingHumanoid ~= humanoid then self:_restoreAttackFacing(true) end
            if not humanoid or not root or humanoid.Health <= 0 or (aim and aim.character ~= character) then
                self.attackAim = nil
                self:_restoreAttackFacing(true)
                return
            end
            if not aim then self:_restoreAttackFacing(false); return end
            local point = self:_attackPoint(aim)
            if not point then self:ClearAttackAim(); return end
            if root.Anchored or humanoid.PlatformStand or character:GetAttribute("Ragdolling") then return end
            local delta = flat(point - root.Position)
            if delta.Magnitude < 0.05 then return end
            if self.attackFacingHumanoid ~= humanoid then
                self:_restoreAttackFacing(true)
                local previous = humanoid.AutoRotate
                if self.facingHumanoid == humanoid then
                    previous = self.savedAutoRotate
                    self.facingHumanoid, self.savedAutoRotate = nil, nil
                    self.faceTarget, self.faceUntil, self.faceCharacter = nil, nil, nil
                else self:_restoreFacing() end
                self.attackFacingHumanoid, self.attackSavedAutoRotate = humanoid, previous
            end
            self:_suspendShiftLock()
            -- A native mode may finish while this attack's follow-through is still
            -- active. Preserve its decision to restore rotation instead of saving false.
            if humanoid.AutoRotate == true then self.attackSavedAutoRotate = true end
            humanoid.AutoRotate = false
            local desired = CFrame.lookAt(root.Position, root.Position + delta.Unit)
            root.CFrame = immediate and desired or root.CFrame:Lerp(desired, 1 - math.exp(-40 * dt))
        end

        function Movement:_restoreFacing()
            local humanoid = self.facingHumanoid
            if humanoid and self.savedAutoRotate ~= nil then
                -- Preserve a later controller's decision to re-enable AutoRotate.
                pcall(function()
                    if humanoid.AutoRotate == false then humanoid.AutoRotate = self.savedAutoRotate end
                end)
            end
            self.facingHumanoid, self.savedAutoRotate = nil, nil
            self.faceTarget, self.faceUntil, self.faceCharacter = nil, nil, nil
        end

        function Movement:_faceStep(root, humanoid, now, dt)
            if self.attackAim or self.attackFacingHumanoid then return end
            -- A dash/grab may manage both velocity and AutoRotate. Do not write either
            -- during that lock, including a deferred AutoRotate restoration.
            if self.sense.movementLocked then return end
            if not self.faceTarget or now >= (self.faceUntil or 0) then
                if self.facingHumanoid then self:_restoreFacing() end
                return
            end
            if root.Anchored then return end
            local target = self.faceTarget
            local position
            if typeof(target) == "Vector3" then
                position = target
            elseif target.Parent then
                position = target.Position
            end
            if not position then self:_restoreFacing(); return end
            local delta = flat(position - root.Position)
            if delta.Magnitude < 0.05 then return end
            if self.facingHumanoid ~= humanoid then
                -- Retain this request while restoring an old character's rotation.
                local untilTime, requestedCharacter = self.faceUntil, self.faceCharacter
                self:_restoreFacing()
                self.faceTarget, self.faceUntil, self.faceCharacter = target, untilTime, requestedCharacter
                self.facingHumanoid = humanoid
                self.savedAutoRotate = humanoid.AutoRotate
            end
            humanoid.AutoRotate = false
            local desired = CFrame.lookAt(root.Position, root.Position + delta.Unit)
            root.CFrame = root.CFrame:Lerp(desired, 1 - math.exp(-20 * dt))
        end

        function Movement:_rayParams(character)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            local ignore = { character }
            local actors = self.workspace:FindFirstChild("Players")
            if actors then table.insert(ignore, actors) end
            -- Live character rigs are not navigation obstacles; map walls still are.
            for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
                if player.Character and player.Character ~= character then
                    table.insert(ignore, player.Character)
                end
            end
            params.FilterDescendantsInstances = ignore
            params.RespectCanCollide = true
            return params
        end

        function Movement:_supported(position, params)
            local hit = self.workspace:Raycast(position + UP * 2, -UP * 9, params)
            return hit ~= nil and hit.Normal.Y >= 0.35
        end

        function Movement:_standHeight(root, humanoid)
            local height = humanoid.HipHeight + root.Size.Y * 0.5
            local character = humanoid.Parent or root.Parent or self.character or self.player.Character
            local rigTypes = Enum.HumanoidRigType
            local r6 = rigTypes and humanoid.RigType == rigTypes.R6
            local r15 = rigTypes and humanoid.RigType == rigTypes.R15
            if character and not r15 then
                local leg = character:FindFirstChild("Left Leg") or character:FindFirstChild("Right Leg")
                if r6 or leg then height += leg and leg.Size.Y or 2 end
            end
            return math.max(1, height)
        end

        function Movement:_safeSurface(hit)
            if not hit or not hit.Position or not hit.Normal or hit.Normal.Y < 0.55 then return false end
            local fallen = tonumber(self.workspace.FallenPartsDestroyHeight) or -500
            if hit.Position.Y <= fallen + 10 then return false end
            local object = hit.Instance
            self.surfaceCache = self.surfaceCache or setmetatable({}, {__mode = "k"})
            local time = os.clock()
            local cached = object and self.surfaceCache[object]
            if cached and time < cached.expires then return cached.safe end
            local original = object
            local function result(safe)
                if original then self.surfaceCache[original] = {safe = safe, expires = time + 0.8} end
                return safe
            end
            for _ = 1, 6 do
                if not object then break end
                local name = string.lower(object.Name or "")
                for _, token in ipairs({"killbrick", "killfloor", "killplane", "killzone", "deathfloor", "deathplane", "deathzone", "lava", "voidfloor"}) do
                    if string.find(name, token, 1, true) then return result(false) end
                end
                if type(object.GetAttribute) == "function" then
                    for _, attribute in ipairs({"KillOnTouch", "Lethal", "KillBrick", "InstantKill", "Deadly", "KillsPlayers"}) do
                        if object:GetAttribute(attribute) == true then return result(false) end
                    end
                end
                object = object.Parent
            end
            return result(true)
        end

        function Movement:_rootGoal(position, root, humanoid, params)
            local height = self:_standHeight(root, humanoid)
            local hit = self.workspace:Raycast(position + UP * 2, -UP * (height + 6), params)
            return self:_safeSurface(hit) and hit.Position + UP * height or position
        end

        function Movement:_bodyClear(a, b, direction, height, bodyHeight, radius, params)
            if (b - a).Magnitude < 0.05 then return true end
            local side = direction:Cross(UP) * radius
            for _, offset in ipairs({ZERO, side, -side}) do
                for _, y in ipairs({-height + 0.35, 0, bodyHeight - height - 0.2}) do
                    if self.workspace:Raycast(a + offset + UP * y, b - a, params) then return false end
                end
            end
            return true
        end

        -- Validate an actual walk-off corridor. High horizontal approach rays clear the
        -- lip; vertical columns beyond the lip check the fall volume. A diagonal from
        -- the roof to the floor would incorrectly intersect the roof itself.
        function Movement:_dropCandidate(root, humanoid, destination, params, now)
            if self.settings.AllowDrops == false or humanoid.FloorMaterial == Enum.Material.Air then return nil end
            local mode = self.options.mode
            if mode ~= "chase" and mode ~= "flee" and self.options.sprint ~= true then return nil end
            if destination.Y >= root.Position.Y - 2.8 then return nil end
            local height = self:_standHeight(root, humanoid)
            local bodyHeight = math.max(height + root.Size.Y * 0.5 + 0.75, 4)
            local maxDrop = math.clamp(tonumber(self.settings.MaxDropHeight) or 40, 3, 80)
            local radius = math.clamp(math.max(root.Size.X, root.Size.Z) * 0.5 + 0.35, 1.25, 3)
            local floor = self.workspace:Raycast(root.Position + UP * 2, -UP * (height + 6), params)
            if not self:_safeSurface(floor) then return nil end
            local startY = floor.Position.Y
            local displacement = flat(destination - root.Position)
            local heading = unit(displacement)
            local sameColumn = displacement.Magnitude < 1
            if sameColumn then
                heading = self.direction.Magnitude > 0.1 and self.direction or unit(flat(root.CFrame.LookVector))
            end
            if heading.Magnitude < 0.1 then return nil end
            local angles = sameColumn and {0, 45, -45, 90, -90, 180} or {0, 20, -20}
            local speed = math.clamp(math.max(humanoid.WalkSpeed, self.sprint and self.sprint.CurrentSprintSpeed or 0), 6, 40)
            local gravity = math.max(1, tonumber(self.workspace.Gravity) or 196.2)
            local desiredRange = math.clamp(displacement.Magnitude, 18, 32)
            local bestCandidate, bestScore
            for _, degrees in ipairs(angles) do
                local angle = math.rad(degrees)
                local direction = Vector3.new(heading.X * math.cos(angle) - heading.Z * math.sin(angle), 0,
                    heading.X * math.sin(angle) + heading.Z * math.cos(angle))
                local side = direction:Cross(UP) * radius
                local profile, rejected, edgeDistance, neededDistance = {}, false, nil, desiredRange
                local previousY = startY
                for distance = 0, 64, 2 do
                    local center = root.Position + direction * distance
                    local low, high, centerHit = math.huge, -math.huge, nil
                    for index, offset in ipairs({ZERO, side, -side}) do
                        local top = Vector3.new(center.X, startY + 2, center.Z) + offset
                        local hit = self.workspace:Raycast(top, -UP * (maxDrop + 4), params)
                        if not self:_safeSurface(hit) then rejected = true; break end
                        if index == 1 then centerHit = hit end
                        low, high = math.min(low, hit.Position.Y), math.max(high, hit.Position.Y)
                    end
                    if rejected or high - low > 1.75 or high > previousY + 1.25
                        or startY - low > maxDrop or high > startY + 0.75 then rejected = true; break end
                    local floorY = centerHit.Position.Y
                    local point = Vector3.new(center.X, floorY + height, center.Z)
                    table.insert(profile, {position = point, distance = distance, floorY = floorY})
                    if startY - floorY >= 3 then
                        edgeDistance = edgeDistance or distance
                        local flight = math.sqrt(2 * (startY - floorY) / gravity)
                        neededDistance = math.max(neededDistance, edgeDistance + speed * flight + radius * 2 + 2)
                    end
                    previousY = floorY
                    if edgeDistance and distance >= neededDistance then break end
                end
                local last = profile[#profile]
                if not rejected and edgeDistance and last and last.distance >= neededDistance
                    and last.floorY + height >= destination.Y - 3.5 then
                    local landing = last.position
                    -- Check the whole approach at the current elevation, then body
                    -- clearance on the lower floor and down columns beyond the lip.
                    local highEnd = Vector3.new(landing.X, root.Position.Y, landing.Z)
                    local clear = self:_bodyClear(root.Position, highEnd, direction, height, bodyHeight, radius, params)
                    local previous = profile[1]
                    for _, point in ipairs(profile) do
                        if not clear then break end
                        if point.distance >= edgeDistance + radius + 0.5 then
                            local highPoint = Vector3.new(point.position.X, root.Position.Y, point.position.Z)
                            clear = self:_bodyClear(highPoint, point.position, direction, height, bodyHeight, radius, params)
                        end
                        if clear and previous and math.abs(previous.floorY - point.floorY) < 1.75 then
                            clear = self:_bodyClear(previous.position, point.position, direction, height, bodyHeight, radius, params)
                        end
                        previous = point
                    end
                    if clear then
                        local candidate = {landing = landing, direction = direction, startY = root.Position.Y,
                            started = now, expires = now + math.clamp(last.distance / speed + math.sqrt(2 * maxDrop / gravity) + 1, 2, 6),
                            leftGround = false, descended = false}
                        if not sameColumn then return candidate end
                        local score = edgeDistance + last.distance * 0.05 + (1 - direction:Dot(heading)) * 1.5
                        if not bestScore or score < bestScore then bestCandidate, bestScore = candidate, score end
                    end
                end
            end
            return bestCandidate
        end

        function Movement:_advanceDrop(root, humanoid, now)
            local drop = self.drop
            if not drop then return nil end
            local airborne = humanoid.FloorMaterial == Enum.Material.Air
            drop.leftGround = drop.leftGround or airborne
            drop.descended = drop.descended or root.Position.Y < drop.startY - 1.8
            if (drop.descended and not airborne and (drop.leftGround or root.Position.Y < drop.startY - 3)) or now > drop.expires then
                if airborne then self.airDirection = drop.direction end
                self.drop = nil
                self.forcePlan, self.nextPlan, self.nextRay = true, 0, 0
                self:_clearRoute()
                return nil
            end
            self.pathStatus = airborne and "Dropping toward landing" or "Running off ledge"
            local remaining = flat(drop.landing - root.Position):Dot(drop.direction)
            return remaining > 2 and drop.landing or root.Position + drop.direction * 6
        end

        function Movement:_clearLine(from, to, params)
            local delta = to - from
            local planar = flat(delta)
            if math.abs(delta.Y) > 5 then return false end
            if planar.Magnitude < 0.5 then return math.abs(delta.Y) < 1.5 end
            local side = unit(planar):Cross(UP) * 1.25
            for _, offset in ipairs({ZERO, side, -side}) do
                local start = from + offset
                if self.workspace:Raycast(start, delta, params) then return false end
            end
            -- A clear line through empty air is not a walkable shortcut.
            local samples = math.clamp(math.ceil(planar.Magnitude / 7), 1, 12)
            for i = 1, samples do
                if not self:_supported(from:Lerp(to, i / samples), params) then return false end
            end
            return true
        end

        function Movement:_plan(root, humanoid, now)
            if self.drop or self.routeCommitted or humanoid.FloorMaterial == Enum.Material.Air then return end
            if self.planning or not self.goal or now < self.nextPlan then return end
            local mode = self.options.mode
            local interval = mode == "chase" and 0.65 or (mode == "flee" and 1.0 or 1.5)
            local moved = not self.plannedGoal or (self.plannedGoal - self.goal).Magnitude > (mode == "chase" and 5 or 7)
            -- Static destinations retain their route until blocked or changed. Replacing
            -- a good roaming route every three seconds could join a point behind us.
            local dynamic = mode == "chase" or mode == "assist" or mode == "combo"
            local expired = dynamic and now - (self.lastPlan or 0) > (mode == "chase" and 1.5 or 3)
            if not self.forcePlan and self.route and not moved and not expired then return end
            self.forcePlan = false
            self.planning = true
            self.nextPlan = now + interval
            local goal = self.goal
            local start = root.Position
            local revision = self.revision
            local character = self.character
            local radius = math.clamp(math.max(root.Size.X, root.Size.Z) * 0.5 + 0.5, 1.5, 3)
            local agentHeight = math.clamp(self:_standHeight(root, humanoid) + root.Size.Y * 0.5 + 1, 4, 10)
            local jumpEnabled = self.settings.Jump ~= false and humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)
                and ((humanoid.UseJumpPower and humanoid.JumpPower > 0) or (not humanoid.UseJumpPower and humanoid.JumpHeight > 0))
            local path = self.pathfinding:CreatePath({AgentRadius = radius, AgentHeight = agentHeight,
                AgentCanJump = jumpEnabled, AgentCanClimb = true, WaypointSpacing = 4})
            self.pathStatus = "Computing"
            task.spawn(function()
                local ok = pcall(path.ComputeAsync, path, start, goal)
                self.planning = false
                if self.destroyed or revision ~= self.revision or character ~= self.character or not self.goal then path:Destroy(); return end
                if (self.goal - goal).Magnitude > 20 then
                    self.forcePlan = true
                    self.nextPlan = 0
                    path:Destroy()
                    return
                end
                if ok and path.Status == Enum.PathStatus.Success then
                    local route = {}
                    local routeParams = self:_rayParams(character)
                    for _, waypoint in ipairs(path:GetWaypoints()) do
                        table.insert(route, {Position = self:_rootGoal(waypoint.Position, root, humanoid, routeParams),
                            Action = waypoint.Action, Label = waypoint.Label})
                    end
                    if #route >= 2 then
                        self:_clearRoute()
                        self.route = route
                        self.path = path
                        self.plannedGoal = goal
                        self.lastPlan = os.clock()
                        self.pathStatus = "Following"
                        -- Skip already-passed initial waypoints after ComputeAsync yields.
                        local closestIndex, closestDistance = 2, math.huge
                        local params = self:_rayParams(character)
                        for i = 2, math.min(#route, 8) do
                            local d = flat(route[i].Position - root.Position).Magnitude
                            if route[i].Action == Enum.PathWaypointAction.Jump then break end
                            if d < closestDistance and self:_clearLine(root.Position, route[i].Position, params) then
                                closestIndex, closestDistance = i, d
                            end
                        end
                        self.routeIndex = closestIndex
                        self.blockedConnection = path.Blocked:Connect(function(index)
                            if index >= self.routeIndex then
                                self.routeBlocked = true
                                self.forcePlan = true
                                self.nextPlan = math.min(self.nextPlan, os.clock() + 0.15)
                            end
                        end)
                    else
                        self.pathStatus = "Empty route; retrying"
                        self.forcePlan = true
                        path:Destroy()
                    end
                else
                    self.pathStatus = "No route; retrying"
                    self.forcePlan = true
                    path:Destroy()
                end
            end)
        end

        function Movement:_localCorridor(root, goal, params, now)
            local old = self.localStep
            if old and now < old.expires and flat(old.point - root.Position).Magnitude > 2
                and self:_clearLine(root.Position, old.point, params) then return old.point end
            local toward = unit(goal - root.Position)
            if toward.Magnitude < 0.1 then toward = unit(root.CFrame.LookVector) end
            local best, bestScore
            for _, degrees in ipairs({0, 35, -35, 70, -70, 110, -110, 150, -150, 180}) do
                local angle = math.rad(degrees)
                local heading = Vector3.new(toward.X * math.cos(angle) - toward.Z * math.sin(angle), 0,
                    toward.X * math.sin(angle) + toward.Z * math.cos(angle))
                local point = root.Position + heading * 8
                if self:_clearLine(root.Position, point, params) then
                    local score = heading:Dot(toward) * 5 + heading:Dot(self.direction) * 3
                    if not bestScore or score > bestScore then best, bestScore = point, score end
                end
            end
            self.localStep = best and {point = best, expires = now + 0.7} or nil
            if best then self.pathStatus = "Following local exit while planning" end
            return best
        end

        -- Anti-circling: long travel with almost no net progress means we are orbiting
        -- a waypoint/goal (or oscillating). Break out, replan, and tell the planner.
        local function measureHistory(history, since)
            local path, minX, maxX, minZ, maxZ, count, first, previous, lastSample = 0, math.huge, -math.huge, math.huge, -math.huge, 0, nil, nil, nil
            for _, sample in ipairs(history) do
                if sample.t >= since then
                    count += 1
                    first = first or sample
                    if previous then path += flat(sample.p - previous.p).Magnitude end
                    previous, lastSample = sample, sample
                    minX, maxX = math.min(minX, sample.p.X), math.max(maxX, sample.p.X)
                    minZ, maxZ = math.min(minZ, sample.p.Z), math.max(maxZ, sample.p.Z)
                end
            end
            if count < 2 then return 0, 0, 0, count, 0 end
            return path, flat(lastSample.p - first.p).Magnitude, math.max(maxX - minX, maxZ - minZ), count, lastSample.t - first.t
        end

        -- Anti-circling. Three independent checks:
        --   dwell  : close to the goal for a while but never "arrived"
        --   orbit  : lots of travel inside a small area (running in circles)
        --   jitter : moving back and forth / spinning but going nowhere
        -- Jumping or airborne frames do NOT reset the history (jumping in circles is still circling).
        function Movement:_circleWatch(root, humanoid, now, params)
            if self.settings.AntiCircle == false then return false end
            local goal = self.goal
            local history = self.circleHistory
            if not history or self.circleCharacter ~= self.character then
                history = {}
                self.circleHistory, self.circleCharacter, self.nearGoalSince = history, self.character, nil
            end
            if not goal or self.drop or self.sense.movementLocked or self.goalReached then
                table.clear(history)
                self.nearGoalSince = nil
                return false
            end
            if now < (self.circleCooldown or 0) then return false end

            local arrival = tonumber(self.options.arrival) or 3
            local goalFlat = flat(goal - root.Position).Magnitude
            local dwellIgnored = self.dwellIgnore and self.dwellIgnore.goal == goal and now < self.dwellIgnore.untilT
            if not dwellIgnored and self.options.mode == "travel" and goalFlat <= arrival + 6 and math.abs(goal.Y - root.Position.Y) <= 8 then
                self.nearGoalSince = self.nearGoalSince or now
                if now - self.nearGoalSince >= 2.2 then
                    return self:_breakLoop(root, humanoid, now, params, "dwell")
                end
            else
                self.nearGoalSince = nil
            end

            local last = history[#history]
            if not last or now - last.t >= 0.15 then table.insert(history, {t = now, p = root.Position}) end
            while #history > 0 and now - history[1].t > 5.2 do table.remove(history, 1) end
            if #history < 10 then return false end

            local path, net, spread, count, span = measureHistory(history, now - 3.0)
            if span >= 2.6 and count >= 10 and path >= 24 and net <= path * 0.3 and spread <= 20 then
                return self:_breakLoop(root, humanoid, now, params, "orbit")
            end
            path, net, spread, count, span = measureHistory(history, now - 4.6)
            if span >= 4.2 and path >= 10 and spread <= 6 and goalFlat > arrival + 3 then
                return self:_breakLoop(root, humanoid, now, params, "jitter")
            end
            return false
        end

        function Movement:_breakLoop(root, humanoid, now, params, kind)
            table.clear(self.circleHistory)
            self.nearGoalSince = nil
            self.circleCooldown = now + 2.0
            self.circleEvents = (self.circleEvents or 0) + 1
            self.circleFlagAt = now
            local recent = self.circleRecent or {}
            self.circleRecent = recent
            table.insert(recent, now)
            while #recent > 0 and now - recent[1] > 20 do table.remove(recent, 1) end
            self.revision += 1
            self:_clearRoute()
            self.localStep, self.direction = nil, ZERO
            self.direct, self.forcePlan, self.nextPlan, self.nextRay = false, true, 0, 0
            self.lastProgress = now
            local goal = self.goal
            local goalDistance = goal and flat(goal - root.Position).Magnitude or math.huge
            local arrival = tonumber(self.options.arrival) or 3
            local ignored = self.dwellIgnore and self.dwellIgnore.goal == goal and now < self.dwellIgnore.untilT
            if not ignored and self.options.mode == "travel" and goalDistance <= math.max(12, arrival * 3) then
                -- Orbiting / hovering around its own destination: count it as arrived (briefly, then move on).
                self.forcedArrival = {goal = goal, untilT = now + 1.2}
                self.status, self.pathStatus = "Arrived (stopped circling)", "Broke out of a loop at the goal"
                debugLog("plr was looping at the destination, counting it as reached")
                return true
            end
            if #recent >= 2 or ignored then
                -- Replanning did not help: wander off in the freest direction for a moment to reset the geometry.
                local bestDirection, bestScore = nil, -math.huge
                local toGoal = goal and flat(goal - root.Position) or ZERO
                for i = 0, 7 do
                    local angle = i * math.pi / 4 + math.random() * 0.3
                    local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
                    local hit = self.workspace:Raycast(root.Position, direction * 12, params)
                    local free = hit and (hit.Position - root.Position).Magnitude or 12
                    local score = free - (toGoal.Magnitude > 0.1 and direction:Dot(toGoal.Unit) * 3 or 0)
                    if score > bestScore then bestDirection, bestScore = direction, score end
                end
                self.breakoutDir, self.breakoutUntil = bestDirection, now + 1.1
                self:_jump(humanoid, now)
                self.pathStatus = "Breaking out of a loop"
                debugLog("plr is still looping, wandering off to break out")
                return true
            end
            self.pathStatus = "Broke out of a loop; replanning"
            debugLog("plr got stuck in a loop (" .. kind .. "), replanning")
            self:_jump(humanoid, now)
            return false
        end

        function Movement:TakeCircleFlag()
            if self.circleFlagAt and os.clock() - self.circleFlagAt < 1.5 then
                self.circleFlagAt = nil
                return true
            end
            return false
        end

        function Movement:_jump(humanoid, now)
            if self.settings.Jump == false then return end
            if now < self.nextJump or humanoid.FloorMaterial == Enum.Material.Air then return end
            if not humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping) then return end
            if (humanoid.UseJumpPower and humanoid.JumpPower <= 0) or (not humanoid.UseJumpPower and humanoid.JumpHeight <= 0) then return end
            humanoid.Jump = true
            self.nextJump = now + 1.05
        end

        function Movement:_step(dt)
            if self.destroyed then return end
            if (not self.goal or not self.ownsMovement) and not self.evasionContext
                and not self.faceTarget and not self.facingHumanoid and not self.cameraTarget then return end
            local now = os.clock()
            local character = self.player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if not humanoid or not root or humanoid.Health <= 0 then
                local temporaryEvasion = self.evasionContext and self.evasionContext.temporary and not self.goal
                self.cameraTarget, self.cameraUntil = nil, nil
                self.evasion, self.evasionContext, self.finishedEvasion = nil, nil, nil
                self.drop, self.airDirection, self.wasAirborne = nil, nil, nil
                self.recovering, self.emergencyUntil, self.staminaRole = false, nil, nil
                if self.character then
                    self.character = nil
                    self.revision += 1
                    self:_clearRoute()
                end
                self:_restoreFacing()
                self:_setSprint(false)
                if temporaryEvasion then self:_restoreSprintFallback(); self:_releaseControl() end
                self.direction = ZERO
                self.status = "Waiting for character"
                return
            end
            if self.character ~= character then
                local faceTarget, faceUntil, faceCharacter = self.faceTarget, self.faceUntil, self.faceCharacter
                self:_restoreFacing()
                if faceCharacter == character then
                    self.faceTarget, self.faceUntil, self.faceCharacter = faceTarget, faceUntil, faceCharacter
                end
                self.character = character
                if self.evasionContext and self.evasionContext.character ~= character then
                    self:_finishEvasion(humanoid)
                    self.finishedEvasion = nil
                end
                self.drop, self.airDirection, self.wasAirborne = nil, nil, nil
                self.recovering, self.emergencyUntil, self.staminaRole = false, nil, nil
                self.revision += 1
                self:_clearRoute()
                self.nextPlan, self.nextRay = 0, 0
                self.lastPosition = root.Position
                self.framePosition = root.Position
                self.lastProgress = now
            end
            if self.framePosition then
                local displacement = (root.Position - self.framePosition).Magnitude
                if displacement > math.max(35, (humanoid.WalkSpeed or 16) * dt * 5) then
                    -- Native teleports can reuse the same rig. Routes, dodge returns and
                    -- ledge commitments computed at the previous location are obsolete.
                    self.revision += 1
                    self:_clearRoute()
                    self.evasion, self.evasionContext, self.finishedEvasion = nil, nil, nil
                    self.drop, self.airDirection, self.wasAirborne, self.hazardRoute = nil, nil, nil, nil
                    self.direct, self.forcePlan, self.nextPlan, self.nextRay = false, true, 0, 0
                    self.localStep, self.direction = nil, ZERO
                    self.lastPosition, self.lastProgress = root.Position, now
                end
                self.progressDistance = (self.progressDistance or 0) + flat(root.Position - self.framePosition).Magnitude
            end
            self.framePosition = root.Position
            if not self.lastPosition or flat(root.Position - self.lastPosition).Magnitude > 1 then
                self.lastPosition, self.lastProgress = root.Position, now
            end
            local jumpSetting = self.settings.Jump ~= false
            if self.lastJumpSetting ~= jumpSetting then
                if self.lastJumpSetting ~= nil then
                    self.revision += 1
                    self:_clearRoute()
                    self.nextPlan = 0
                end
                self.lastJumpSetting = jumpSetting
            end
            if self.sense.movementLocked then
                -- Ability dashes/grabs own movement temporarily. In particular, sending
                -- Move(Vector3.zero) here would fight their velocity/steering controller.
                self:_setSprint(false)
                if self.drop then self.drop.expires += dt end
                self.lastProgress = now
                self.status = "Ability controls movement"
                return
            end
            if self.ownsMovement then self:_suspendShiftLock() end
            self:_faceStep(root, humanoid, now, dt)
            if not self.ownsMovement or (not self.goal and not self.evasionContext) then return end
            local committedPosition = self:_advanceDrop(root, humanoid, now)
            local airborne = humanoid.FloorMaterial == Enum.Material.Air
            if airborne then
                if not self.wasAirborne then
                    local airborneGoal = self.goal or (self.evasion and self.evasion.goal) or root.Position
                    self.airDirection = self.drop and self.drop.direction or (self.direction.Magnitude > 0.1 and self.direction or unit(airborneGoal - root.Position))
                    if not self.drop and not self.routeCommitted then
                        self.revision += 1
                        self:_clearRoute()
                    end
                end
            elseif self.wasAirborne then
                self.airDirection = nil
                self.forcePlan, self.nextPlan, self.nextRay = true, 0, 0
            end
            self.wasAirborne = airborne
            if not self.goal and self.evasionContext and (self.evasionContext.phase == "rejoin"
                or not self.evasion or now >= self.evasion.expires) then
                self:_beginEvasionRejoin(now)
                self:_finishEvasion(humanoid)
                return
            end
            if root.Anchored or character:GetAttribute("Ragdolling") or humanoid.WalkSpeed <= 0.1 then
                humanoid:Move(ZERO, false)
                self:_setSprint(false)
                self.direction = ZERO
                self.lastProgress = now
                self.status = "Movement locked by game"
                return
            end
            local params = self:_rayParams(character)
            if self.breakoutUntil and now < self.breakoutUntil and self.breakoutDir then
                self:_setSprint(false)
                humanoid:Move(self.breakoutDir, false)
                return
            end
            if self:_circleWatch(root, humanoid, now, params) then return end
            if self:_evasionStep(root, humanoid, params, now, dt, airborne) then return end
            if not self.goal then return end
            if self.forcedArrival then
                local forced = self.forcedArrival
                if forced.goal == self.goal and now < (forced.untilT or 0) then
                    humanoid:Move(ZERO, false)
                    self:_setSprint(false)
                    self.direction, self.goalReached, self.lastProgress = ZERO, true, now
                    self.status = "Arrived"
                    return
                end
                if forced.goal == self.goal then
                    -- Stood here long enough without the goal completing: stop treating it as reachable,
                    -- and count a strike so the planner drops this target.
                    self.dwellIgnore = {goal = forced.goal, untilT = now + 8}
                    self.circleEvents = (self.circleEvents or 0) + 1
                    self.goalReached = false
                    debugLog("plr couldnt finish at the destination, moving on")
                end
                self.forcedArrival = nil
            end
            local destination = self:_rootGoal(self.goal, root, humanoid, params)
            local goalDelta = destination - root.Position
            local arrival = tonumber(self.options.arrival) or 3
            local finalRouteLeg = not self.routeCommitted or (self.route and self.routeIndex >= #self.route)
            if not self.drop and not airborne and finalRouteLeg and flat(goalDelta).Magnitude <= arrival
                and math.abs(goalDelta.Y) < 2.25 and self:_clearLine(root.Position, destination, params) then
                self.routeCommitted, self.committedGoal = false, nil
                self.goalReached = true
                self.direction = ZERO
                humanoid:Move(ZERO, false)
                self:_setSprint(false)
                self.status = "Arrived"
                self.lastProgress = now
                return
            end
            self.goalReached = false
            if not self.drop and not airborne and not self.routeCommitted and now >= self.nextRay then
                self.direct = flat(goalDelta).Magnitude < 80 and self:_clearLine(root.Position, destination, params)
                self.nextRay = now + 0.18
                if not self.direct and now >= (self.nextDropScan or 0) then
                    self.nextDropScan = now + 0.45
                    local candidate = self:_dropCandidate(root, humanoid, destination, params, now)
                    if candidate then
                        self.drop = candidate
                        self.revision += 1
                        self:_clearRoute()
                        self.airDirection = candidate.direction
                        committedPosition = self:_advanceDrop(root, humanoid, now)
                    end
                end
            end
            if not self.direct and not self.drop and not airborne then self:_plan(root, humanoid, now) end
            local nextPosition = nil
            if committedPosition then
                nextPosition = committedPosition
            elseif airborne then
                if self.routeCommitted and (self.routeJumpUntil or 0) > now and self.route then
                    local waypoint = self.route[self.routeIndex]
                    if waypoint and waypoint.Action == Enum.PathWaypointAction.Jump and self.route[self.routeIndex + 1] then
                        self.routeIndex += 1
                        waypoint = self.route[self.routeIndex]
                    end
                    nextPosition = waypoint and waypoint.Position
                    self.pathStatus = "Following planned jump landing"
                end
                if not nextPosition then
                    local heading = self.airDirection or self.direction
                    nextPosition = root.Position + heading * 8
                    self.pathStatus = "Maintaining airborne direction"
                end
            elseif self.direct then
                nextPosition = destination
                self.pathStatus = "Direct corridor"
            elseif self.route then
                local waypoint = self.route[self.routeIndex]
                local reach = math.max(2.5, humanoid.WalkSpeed * dt * 1.5)
                local function reachDistance(index)
                    if not self.routeCommitted then return reach end
                    local previous, current, following = self.route[index - 1], self.route[index], self.route[index + 1]
                    if previous and current and following then
                        local incoming, outgoing = unit(current.Position - previous.Position), unit(following.Position - current.Position)
                        if incoming:Dot(outgoing) < 0.8 then return math.max(1.6, humanoid.WalkSpeed * dt * 1.25, humanoid.WalkSpeed * 0.06) end
                    end
                    return 2.25
                end
                local function passed(index)
                    local previous, current = self.route[index - 1], self.route[index]
                    if not previous or not current or current.Action == Enum.PathWaypointAction.Jump then return false end
                    local segment = flat(current.Position - previous.Position)
                    local toWaypoint = flat(current.Position - root.Position)
                    if segment.Magnitude < 0.5 or toWaypoint.Magnitude > 5 then return false end
                    return toWaypoint:Dot(segment.Unit) <= 0 and math.abs(current.Position.Y - root.Position.Y) < 2.5
                        and self.workspace:Raycast(root.Position, current.Position - root.Position, params) == nil
                end
                while waypoint and (passed(self.routeIndex) or (flat(waypoint.Position - root.Position).Magnitude < reachDistance(self.routeIndex)
                    and math.abs(waypoint.Position.Y - root.Position.Y) < 2.5
                    and (not self.routeCommitted or self.workspace:Raycast(root.Position, waypoint.Position - root.Position, params) == nil))) do
                    if waypoint.Action == Enum.PathWaypointAction.Jump then
                        self:_jump(humanoid, now)
                        self.routeJumpUntil = now + 1.5
                    end
                    self.routeIndex += 1
                    waypoint = self.route[self.routeIndex]
                end
                if waypoint then
                    nextPosition = waypoint.Position
                    if waypoint.Action == Enum.PathWaypointAction.Jump and flat(waypoint.Position - root.Position).Magnitude < 7 then
                        self:_jump(humanoid, now)
                        self.routeJumpUntil = now + 1.5
                    end
                else
                    self.routeCommitted, self.committedGoal = false, nil
                    self.route = nil
                    self.forcePlan = true
                    self.nextPlan = 0
                end
            end
            if not nextPosition then
                -- Keep momentum during a replacement computation only when the next
                -- short segment is safe. Never run blindly into a wall or over a cliff.
                local ahead = root.Position + self.direction * 5
                if self.direction.Magnitude > 0.1 and self:_clearLine(root.Position, ahead, params) then
                    nextPosition = ahead
                elseif self:_clearLine(root.Position, root.Position + unit(goalDelta) * 4, params) then
                    nextPosition = root.Position + unit(goalDelta) * 4
                elseif not airborne then
                    nextPosition = self:_localCorridor(root, destination, params, now)
                end
            end
            if nextPosition and not airborne and not self.drop and self._hazardWaypoint then
                nextPosition = self:_hazardWaypoint(root, humanoid, nextPosition, params, now)
            end
            local desired, waypointDistance = ZERO, math.huge
            if nextPosition then
                local flatDelta = flat(nextPosition - root.Position)
                waypointDistance = flatDelta.Magnitude
                if waypointDistance > 0.05 then desired = flatDelta.Unit end
            end
            if desired.Magnitude > 0.1 then
                if not self.lastPosition or flat(root.Position - self.lastPosition).Magnitude > 1 then
                    self.lastPosition = root.Position
                    self.lastProgress = now
                elseif not airborne and not self.drop and now - self.lastProgress > 1.1
                    and now - (self.lastRecovery or 0) > 0.9 then
                    self:_jump(humanoid, now)
                    self.forcePlan = true
                    self.nextPlan = 0
                    self.lastRecovery = now
                    self.pathStatus = "Recovering from obstacle"
                    if self.routeCommitted and now - self.lastProgress > 2.4 then
                        self.routeCommitted, self.committedGoal = false, nil
                        self.routeFailure = "Validated route blocked; requesting replacement"
                    end
                end
                if airborne or self.drop then self.lastProgress = now end
                -- Exponential steering removes direction flicker without interpolating
                -- the speed through zero, which would restart running animations.
                local alpha = 1 - math.exp(-12 * dt)
                local blend = self.direction:Lerp(desired, alpha)
                self.direction = blend.Magnitude > 0.05 and blend.Unit or desired
                -- If the turn is sharp, retain speed but commit to the new heading.
                if self.direction:Dot(desired) < 0.1 then self.direction = desired end
                -- Close to the target the smoothing lag is wider than the arrival radius,
                -- which makes the character orbit it instead of reaching it.
                if waypointDistance < math.max(5, humanoid.WalkSpeed * 0.3) then self.direction = desired end
                if self.HazardPenalty and self:HazardPenalty(root.Position,
                    root.Position + self.direction * math.max(2, humanoid.WalkSpeed * dt * 2)) > 0 then
                    -- Smooth turning must not cut back through a trap's trigger circle.
                    self.direction = desired
                end
                if self.routeCommitted and not airborne and not self:_clearLine(root.Position,
                    root.Position + self.direction * math.max(1.5, humanoid.WalkSpeed * dt * 2), params) then
                    self.direction = desired
                end
            else
                self.direction = ZERO
            end
            humanoid:Move(self.direction, false)
            self:_sprintPolicy(self.direction.Magnitude > 0.1, now)
            self.status = self.options.mode == "flee" and "Escaping" or (self.options.mode == "chase" and "Pursuing" or "Travelling")
        end

        function Movement:GetDiagnostics()
            local stamina, maximum = self:GetStamina()
            local reserve, resume = self:_reservePolicy()
            local stalledFor = self.ownsMovement and self.goal and math.max(0, os.clock() - (self.lastProgress or os.clock())) or 0
            return {status = self.status, path = self.pathStatus, sprinting = self.sprintHeld == true,
                sprintMode = self.sprintMode, stamina = stamina, maxStamina = maximum,
                recovering = self.recovering, reached = self.goalReached, reserve = reserve, resume = resume,
                dropping = self.drop ~= nil, stalledFor = stalledFor, routeIndex = self.routeIndex,
                routeCount = self.route and #self.route or 0, routeCommitted = self.routeCommitted == true,
                blocked = self.routeBlocked == true or stalledFor > 1.1, routeFailure = self.routeFailure,
                noRoute = self.goal ~= nil and not self.route and not self.direct and not self.drop,
                progressDistance = self.progressDistance or 0}
        end

        function Movement:Stop()
            self.evasion, self.evasionContext, self.finishedEvasion = nil, nil, nil
            self.cameraTarget, self.cameraUntil = nil, nil
            self.attackAim = nil
            self:_restoreAttackFacing(true)
            self:_restoreFacing()
            self.goal = nil
            self.drop, self.airDirection, self.wasAirborne = nil, nil, nil
            self.recovering, self.emergencyUntil, self.staminaRole = false, nil, nil
            self.nextDropScan = 0
            self.localStep, self.routeFailure, self.lastRecovery = nil, nil, nil
            self.hazardRoute, self.nextHazardPlan = nil, nil
            self.routeJumpUntil = nil
            self.framePosition, self.progressDistance = nil, 0
            self.revision += 1
            self.direction = ZERO
            self.goalReached = false
            self:_clearRoute()
            self:_setSprint(false)
            self:_restoreSprintFallback()
            local character = self.player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid and self.ownsMovement then humanoid:Move(ZERO, false) end
            self:_releaseControl()
            self.status, self.pathStatus = "Idle", "Idle"
            self.lastPosition = nil
            self.lastProgress = os.clock()
            self.nextPlan = 0
        end

        function Movement:Destroy()
            if self.destroyed then return end
            self:Stop()
            self.destroyed = true
            self.runService:UnbindFromRenderStep(self.bindName)
            self.runService:UnbindFromRenderStep(self.cameraBindName)
            self.runService:UnbindFromRenderStep(self.aimBindName)
        end

        return Movement

        end)()


        -- Soft avoidance for replicated gameplay hazards. Keep the navigator's route;
        -- follow a checked detour around the hazard before rejoining its next waypoint.
        local function installHazardNavigation(Movement)
            local UP = Vector3.new(0, 1, 0)
            local function flat(v) return Vector3.new(v.X, 0, v.Z) end
            local function center(h)
                if h.model and not h.model.Parent then return nil end
                return h.root and h.root.Parent and h.root.Position or h.position
            end
            function Movement:HazardPenalty(from, to, hazards)
                local cost, first, nearest = 0, nil, math.huge
                for _, h in ipairs(hazards or self.sense.hazards or {}) do
                    local p = center(h)
                    if h.avoid ~= false and p and math.abs(p.Y - from.Y) < (h.height or 8) then
                        local delta = flat(to - from)
                        local r = math.max(1, tonumber(h.radius) or 4) + 1.6
                        local start, finish = flat(from - p).Magnitude, flat(to - p).Magnitude
                        local t = delta:Dot(delta) > 0.001 and math.clamp(flat(p - from):Dot(delta) / delta:Dot(delta), 0, 1) or 0
                        local d = flat(from + delta * t - p).Magnitude
                        -- An actor already inside a danger circle must be able to leave.
                        local exiting = start < r and finish > start + 0.5 and d >= start - 0.2
                        if d < r and not exiting then
                            cost += (r - d + 1) * (h.dynamic and 90 or 60)
                            if start < nearest then first, nearest = h, start end
                        end
                    end
                end
                return cost, first
            end

            function Movement:_hazardWaypoint(root, humanoid, destination, params, now)
                local hazards = self.sense.hazards or {}
                local cost, hazard = self:HazardPenalty(root.Position, destination, hazards)
                if cost <= 0 then self.hazardRoute = nil; return destination end
                local retained = self.hazardRoute
                if retained then
                    local p = center(retained.hazard)
                    if now > retained.expires or not p or flat(p - retained.center).Magnitude > 4
                        or flat(destination - retained.destination).Magnitude > 24 then
                        self.hazardRoute = nil
                        self.nextHazardPlan = 0
                    else
                        while retained.points[retained.index] and flat(retained.points[retained.index] - root.Position).Magnitude < 1.5 do
                            retained.index += 1
                        end
                        local point = retained.points[retained.index]
                        if point and self:HazardPenalty(root.Position, point, hazards) == 0
                            and self:_clearLine(root.Position, point, params) then return point end
                        self.hazardRoute = nil
                        self.nextHazardPlan = 0
                    end
                end
                if not hazard or now < (self.nextHazardPlan or 0) then return destination end
                self.nextHazardPlan = now + 0.35
                local origin, p = root.Position, center(hazard)
                if not p or flat(p - origin).Magnitude > 55 then return destination end
                local radius = (math.max(1, tonumber(hazard.radius) or 4) + 1.6) * 1.25 + 1
                local height = self:_standHeight(root, humanoid)
                local nodes = {origin, destination}
                local angle = math.atan2(origin.Z - p.Z, origin.X - p.X)
                for i = 0, 7 do
                    local theta = angle + i * math.pi / 4
                    local probe = Vector3.new(p.X + math.cos(theta) * radius, origin.Y, p.Z + math.sin(theta) * radius)
                    local hit = self.workspace:Raycast(probe + UP * 3, -UP * (height + 7), params)
                    if self:_safeSurface(hit) then
                        local point = hit.Position + UP * height
                        if math.abs(point.Y - origin.Y) < 3 then nodes[i + 3] = point end
                    end
                end
                local dist, previous, visited, edges = {[1] = 0}, {}, {}, {}
                local function edge(a, b)
                    if not nodes[a] or not nodes[b] then return false end
                    local key = math.min(a, b) * 20 + math.max(a, b)
                    if edges[key] ~= nil then return edges[key] end
                    local safe = self:HazardPenalty(nodes[a], nodes[b], hazards) == 0
                        and self:_clearLine(nodes[a], nodes[b], params)
                    edges[key] = safe
                    return safe
                end
                -- Eight perimeter samples and the two endpoints form a small visibility
                -- graph. Only neighboring perimeter links are needed, limiting raycasts.
                for _ = 1, 10 do
                    local current, best
                    for i = 1, 10 do if nodes[i] and not visited[i] and dist[i] and (not best or dist[i] < best) then current, best = i, dist[i] end end
                    if not current or current == 2 then break end
                    visited[current] = true
                    for nextIndex = 1, 10 do
                        local adjacent = current <= 2 or nextIndex <= 2 or math.abs(current - nextIndex) == 1 or math.abs(current - nextIndex) == 7
                        if adjacent and not visited[nextIndex] and edge(current, nextIndex) then
                            local length = (nodes[nextIndex] - nodes[current]).Magnitude
                            local candidate = best + length
                            if not dist[nextIndex] or candidate < dist[nextIndex] then dist[nextIndex], previous[nextIndex] = candidate, current end
                        end
                    end
                end
                if dist[2] then
                    local points, index = {}, previous[2]
                    while index and index ~= 1 do table.insert(points, 1, nodes[index]); index = previous[index] end
                    if #points > 0 then
                        self.hazardRoute = {points = points, index = 1, hazard = hazard, center = p, destination = destination,
                            expires = now + math.clamp(dist[2] / math.max(humanoid.WalkSpeed or 12, 6) + 2, 3, 9)}
                        self.pathStatus = "Going around " .. tostring(hazard.kind or "hazard")
                        return points[1]
                    end
                end
                -- Keep the usable navigation route if every checked detour is blocked.
                -- This allows a necessary mine crossing instead of freezing in a corner.
                return destination
            end
        end

        installHazardNavigation(Movement)


        local Ability = (function()
        -- Ability policy built from this place's Assets/*/Behavior and ActorNetwork.
        -- Only the ordinary input-side ClientCallback and UseActorAbility request are used.
        local Ability = {}
        Ability.__index = Ability

        local function loadModule(root, path)
            local node = root
            for word in string.gmatch(path, "[^/]+") do
                node = node and node:FindFirstChild(word)
            end
            if not node or not node:IsA("ModuleScript") then return nil end
            local ok, result = pcall(require, node)
            return ok and type(result) == "table" and result or nil
        end

        local function rootOf(model)
            return model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
        end

        local function horizontal(v)
            return Vector3.new(v.X, 0, v.Z)
        end

        local function value(config, key, fallback)
            local v = config and config[key]
            return type(v) == "number" and v or fallback
        end

        local function nested(config, group, key, fallback)
            local t = config and config[group]
            return type(t) == "table" and value(t, key, fallback) or fallback
        end

        local function isAlive(model)
            local hum = model and model:FindFirstChildOfClass("Humanoid")
            return hum and hum.Health > 0 and rootOf(model) ~= nil
        end

        function Ability.new(ctx)
            local self = setmetatable({}, Ability)
            self.ctx = ctx
            self.player = ctx.player or game:GetService("Players").LocalPlayer
            self.rs = ctx.ReplicatedStorage or game:GetService("ReplicatedStorage")
            self.actors = ctx.actors or loadModule(self.rs, "Modules/Gameplay/Actors")
            self.network = ctx.network or loadModule(self.rs, "Modules/Network/Network")
            self.sprinting = loadModule(self.rs, "Systems/Character/Game/Sprinting")
            self.statuses = loadModule(self.rs, "Modules/Gameplay/Statuses")
            self.lastAttempt = {}
            self.held = {}
            self.nextAction = 0
            self.actionSerial = 0
            self.sequence = nil
            self.nativeControlUntil = 0
            self.inputReleases = {}
            self.aimUntil = 0
            self.destroyed = false
            self.animCache = setmetatable({}, {__mode = "k"})
            self:InstallTargeting()
            return self
        end

        function Ability:GetActor(model)
            if not self.actors or not self.actors.CurrentActors then return nil end
            if not model then
                return self.actors.CurrentActors[self.player] or self.actors.CurrentActors[self.player.Character]
            end
            local actors = self.actors.CurrentActors
            if actors[model] then return actors[model] end
            for _, actor in pairs(actors) do
                if actor.Rig == model then return actor end
            end
            return nil
        end

        function Ability:Abilities(actor)
            local list = {}
            for name, def in pairs(actor and actor.Behavior and actor.Behavior.Abilities or {}) do list[name] = def end
            for name, def in pairs(actor and actor.CustomBehavior and actor.CustomBehavior.Abilities or {}) do list[name] = def end
            return list
        end

        function Ability:LOS(a, b)
            if not a or not b then return false end
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {a.Parent, b.Parent}
            params.RespectCanCollide = true
            params.IgnoreWater = true
            local hit = workspace:Raycast(a.Position, b.Position - a.Position, params)
            return hit == nil
        end

        function Ability:HasStatus(model, status)
            if model and model:GetAttribute(status) then return true end
            if self.statuses and self.statuses.PlayerHasStatus then
                local subject = game:GetService("Players"):GetPlayerFromCharacter(model)
                if subject then
                    local ok, result = pcall(self.statuses.PlayerHasStatus, self.statuses, subject, status)
                    return ok and result ~= nil and result ~= false
                end
            end
            return false
        end

        function Ability:Ready(actor, name, now)
            local d = self:Abilities(actor)[name]
            local confirmedParry = actor.ActorName == "Guest1337" and name == "Punch" and self:GetDefenseState(actor.Rig).parry
            if not d or (d.Disabled and not confirmedParry) or actor.AbilitiesDisabled == true then return false end
            if actor.DisabledAbilities and actor.DisabledAbilities[name] and not confirmedParry then return false end
            local char = actor.Rig
            if not char or char:GetAttribute("AbilitiesDisabled") or char:GetAttribute("Ragdolling")
                or char:GetAttribute("Stunned") or self:HasStatus(char, "Helpless") then return false end
            -- Successful melee Block resets Punch on the server before the parry icon
            -- arrives. That confirmed mode must not wait for stale local cooldown UI.
            -- Only send the ordinary Punch request; never edit cooldown state.
            if confirmedParry then return now >= (self.lastAttempt[name] or 0) + 0.15 end
            local combo = self.noliCombo
            if name == "VoidRush" and combo and combo.actor == actor and not combo.sent
                and now >= combo.readyAt and now <= combo.expires then
                return now >= (self.lastAttempt[name] or 0) + 0.25
            end
            local charges = d.CurrentCharges
            if charges == nil and type(d.Charges) == "number" then charges = d.Charges end
            if type(charges) == "number" and charges <= 0
                and not (d.ChargesOptional or d.ChargesDisabled or workspace:GetAttribute("ChargesDisabled")) then return false end
            local cd = actor.Cooldowns and actor.Cooldowns[name]
            if type(cd) == "table" then
                if type(cd.Duration) == "number" and (cd.TimePast or 0) < cd.Duration then return false end
                local branch = cd[d.UsingCooldown or "Default"]
                if type(branch) == "table" and type(branch[1]) == "number"
                    and branch[1] > workspace:GetServerTimeNow() then return false end
            end
            -- Replicated cooldowns determine legal attack speed; this only prevents
            -- duplicate requests before the first server acknowledgement arrives.
            return now >= (self.lastAttempt[name] or 0) + 0.25
        end

        -- This is the game's shared mouse query provider, used by its existing network
        -- callbacks. Keep normal behavior outside a short bot aim window and restore it.
        function Ability:InstallTargeting()
            local mouse = loadModule(self.rs, "Systems/Player/Miscellaneous/GetPlayerMousePosition")
            if not mouse or self.ctx.enableTargeting == false then return end
            self.mouse = mouse
            self.originalMouse = mouse.GetMousePos
            self.originalCamera = mouse.GetCameraCFrame
            local function getPoint()
                if self.destroyed or os.clock() > self.aimUntil then return nil end
                if self.aimPosition then return self.aimPosition end
                local target = self.aimRoot
                local own = rootOf(self.player.Character)
                if not target or not target.Parent or not own then return nil end
                local windup = math.max(0, (self.aimWindup or 0) - (os.clock() - (self.aimBegan or os.clock())))
                return self:Predict(target, self.projectileSpeed or 150, windup, self.aimGravity)
            end
            self.mouseWrapper = function(module, ...)
                local point = getPoint()
                if point then return point end
                return self.originalMouse(module, ...)
            end
            self.cameraWrapper = function(module, ...)
                local point = getPoint()
                local camera = workspace.CurrentCamera
                if point and camera and (point - camera.CFrame.Position).Magnitude > 0.01 then
                    return CFrame.lookAt(camera.CFrame.Position, point)
                end
                return self.originalCamera(module, ...)
            end
            if type(self.originalMouse) == "function" then mouse.GetMousePos = self.mouseWrapper end
            if type(self.originalCamera) == "function" then mouse.GetCameraCFrame = self.cameraWrapper end
        end

        function Ability:Predict(target, speed, windup, gravity)
            local own = rootOf(self.player.Character)
            if not own or not target then return nil end
            local velocity = target.AssemblyLinearVelocity or Vector3.new(0, 0, 0)
            local delay = math.max(0, windup or 0)
            local relative = target.Position + velocity * delay - own.Position
            local s = math.max(1, speed or 150)
            local a, b, c = velocity:Dot(velocity) - s * s, 2 * relative:Dot(velocity), relative:Dot(relative)
            local travel = relative.Magnitude / s
            if math.abs(a) < 0.0001 then
                if b < -0.0001 then travel = -c / b end
            else
                local discriminant = b * b - 4 * a * c
                if discriminant >= 0 then
                    local t1, t2 = (-b - math.sqrt(discriminant)) / (2 * a), (-b + math.sqrt(discriminant)) / (2 * a)
                    if t1 > 0 and t2 > 0 then travel = math.min(t1, t2)
                    elseif t1 > 0 then travel = t1 elseif t2 > 0 then travel = t2 end
                end
            end
            travel = math.clamp(travel, 0, 2.2)
            return target.Position + velocity * math.clamp(delay + travel, 0, 2.2)
                + Vector3.new(0, math.max(0, gravity or 0) * travel * travel / 2, 0)
        end

        function Ability:Windup(actor, ability)
            local cfg = actor.Config or {}
            if actor.ActorName == "Chance" and ability == "Shoot" then return 0.9 end
            if (actor.ActorName == "JohnDoe" or actor.ActorName == "!JohnDoe_MARCH") and ability == "CorruptEnergy" then return 1.917 end
            if ability == "VoidRush" then return value(cfg, "VoidRushChargeLength", 1) end
            if ability == "DemonicPursuit" then return cfg.PursuitHold and cfg.PursuitHold.Max or 1.25 end
            if ability == "InfernalCry" then return value(cfg, "CryWindup", 0.7) end
            if ability == "Punch" and actor.ActorName == "Guest1337" and self:GetDefenseState(actor.Rig).parry then
                return value(cfg, "ParryWindupTime", 0.4)
            end
            -- These two windups are documented in the extracted config text and
            -- animation callbacks, rather than separate numeric config fields.
            if actor.ActorName == "1x1x1x1" then
                if ability == "MassInfection" then return value(cfg, "MassInfectionWindup", 1.7) end
                if ability == "Entanglement" then return value(cfg, "EntanglementWindup", 0.75) end
            end
            return value(cfg, ability .. "Windup", value(cfg, ability .. "WindupTime", nested(cfg, ability, "Windup", 0.1)))
        end

        function Ability:TravelSpeed(actor, ability, fallback)
            local cfg = actor.Config or {}
            if ability == "CorruptEnergy" and (actor.ActorName == "JohnDoe" or actor.ActorName == "!JohnDoe_MARCH") then
                return value(cfg, "DistanceBetweenSpikes", 4) / math.max(0.005, value(cfg, "DelayBetweenSpikeSummons", 0.045))
            end
            local aliases = {VoidRush = "VoidRushDashSpeed", Charge = "ChargingSpeed",
                Entanglement = "EntanglementSpeed", MassInfection = "MassInfectionShockwaveSpeed"}
            return value(cfg, aliases[ability] or ability .. "Speed",
                value(cfg, ability .. "ProjectileSpeed", nested(cfg, ability, "ProjectileSpeed", fallback or 150)))
        end

        function Ability:Aim(target, seconds, speed, windup, gravity)
            if not target then return end
            self.aimPosition = nil
            self.aimRoot = target
            self.aimUntil = os.clock() + (seconds or 1.5)
            self.projectileSpeed = speed or 150
            self.aimWindup = windup or 0
            self.aimBegan, self.aimGravity = os.clock(), gravity or 0
            if self.ctx.aim then pcall(self.ctx.aim, target, seconds or 1.5) end
        end

        function Ability:AimPoint(point, seconds)
            self.aimRoot, self.aimPosition = nil, point
            self.aimUntil = os.clock() + (seconds or 0.6)
            if self.ctx.face then pcall(self.ctx.face, point, math.min(seconds or 0.6, 1)) end
        end

        function Ability:_ClearAttackFacing()
            if self.faceCast and self.ctx.clearAttackFace then pcall(self.ctx.clearAttackFace) end
            self.faceCast = nil
        end

        function Ability:_TrackAttack(target, seconds, speed, windup, gravity)
            if not target or not target.Parent or not isAlive(target.Parent) then self:_ClearAttackFacing(); return end
            local now = os.clock()
            local face = {target = target, character = self.player.Character, untilTime = now + seconds,
                speed = speed or 150, windup = windup or 0, gravity = gravity or 0, began = now}
            -- The movement writer evaluates this every frame, so body lock follows a
            -- moving target between thought ticks instead of aiming at a stale point.
            face.predictor = function()
                if self.destroyed or self.faceCast ~= face or self.player.Character ~= face.character
                    or os.clock() >= face.untilTime or not target.Parent or not isAlive(target.Parent) then return nil end
                local remainingWindup = math.max(0, face.windup - (os.clock() - face.began))
                return self:Predict(target, face.speed, remainingWindup, face.gravity)
            end
            self.faceCast = face
            if self.ctx.attackFace then
                pcall(self.ctx.attackFace, target, seconds, face.predictor)
            elseif self.ctx.face then
                local predicted = face.predictor()
                if predicted then pcall(self.ctx.face, predicted, math.min(seconds, 1)) end
            end
        end

        function Ability:_TrackAttackPoint(point, seconds)
            local face = {target = point, character = self.player.Character, untilTime = os.clock() + seconds}
            face.predictor = function()
                if self.destroyed or self.faceCast ~= face or self.player.Character ~= face.character
                    or os.clock() >= face.untilTime then return nil end
                return point
            end
            self.faceCast = face
            if self.ctx.attackFace then pcall(self.ctx.attackFace, point, seconds, face.predictor)
            elseif self.ctx.face then pcall(self.ctx.face, point, math.min(seconds, 1)) end
        end

        function Ability:Use(actor, name, sense, target, hold, minInterval, speed)
            local now = sense.now or os.clock()
            if not self.network or not self:Ready(actor, name, now) then return false end
            if minInterval and now < (self.lastAttempt[name] or 0) + minInterval then return false end
            local d = self:Abilities(actor)[name]
            self.lastAttempt[name] = now
            speed = self:TravelSpeed(actor, name, speed)
            local windup = self:Windup(actor, name)
            local gravity = name == "Crystal" and nested(actor.Config, "Crystal", "ProjectileArc", 40) or 0
            if name == "Crystal" then windup += hold or 0 end
            local facingTime
            if target then
                self:Aim(target, math.max((hold or 0) + 1, windup + 0.6, 2.5), speed, windup, gravity)
                facingTime = name == "Shoot" and 1.25 or math.min(3, windup + (hold or 0) + 0.45)
                if name == "VoidRush" then facingTime = value(actor.Config, "VoidRushChargeLength", 1) + value(actor.Config, "VoidRushDashLength", 3.5) + 0.5 end
                if name == "DemonicPursuit" then facingTime = (hold or 1.25) + value(actor.Config, "PursuitLength", 0.8) + 0.6 end
                if name == "Charge" then facingTime = value(actor.Config, "ChargingDuration", 1.5) + 0.3 end
                if name == "WalkspeedOverride" then facingTime = value(actor.Config, "WalkspeedOverrideDuration", 2.5) + windup end
                if name == "CorruptEnergy" and (actor.ActorName == "JohnDoe" or actor.ActorName == "!JohnDoe_MARCH") then
                    facingTime = math.max(3.6, windup + value(actor.Config, "SpikeAmount", 31) * value(actor.Config, "DelayBetweenSpikeSummons", 0.045) + 0.3)
                end
                self:_TrackAttack(target, facingTime, speed, windup, gravity)
            end
            local payload
            if type(d.ClientCallback) == "function" then
                local ok, result = pcall(d.ClientCallback, actor)
                if not ok or result == false then
                    if target then self:_ClearAttackFacing() end
                    return false
                end
                payload = result
            end
            actor.HeldAbilities = actor.HeldAbilities or {}
            actor.HeldAbilities[name] = true
            self.held[name] = {actor = actor, releaseAt = now + (hold or 0.15)}
            local ok, err = pcall(self.network.FireServerConnection, self.network,
                "UseActorAbility", "REMOTE_EVENT", name, payload)
            if not ok then
                actor.HeldAbilities[name] = nil
                self.held[name] = nil
                self.lastError = tostring(err)
                if target then self:_ClearAttackFacing() end
                return false
            end
            self.nextAction = now + math.max(hold or 0, 0.25)
            -- VoidRush must remain held during its dash. Its replicated state owns
            -- movement/action gating, so a successful early hit can still re-rush.
            if name == "VoidRush" then self.nextAction = now + 0.25 end
            self.lastAction = name
            self.actionSerial += 1
            self.lastActionRecord = {serial = self.actionSerial, name = name, time = now,
                assisting = sense.assisting == true, targetRoot = target}
            if actor.ActorName == "Guest1337" and name == "Block" then
                self.guestBlockUntil = now + value(actor.Config, "BlockDuration", 1) + 0.1
            end
            if actor.ActorName == "Veeronica" and name == "Sk8" then self.skateOwned = actor end
            if name == "CorruptEnergy" and target and (actor.ActorName == "JohnDoe" or actor.ActorName == "!JohnDoe_MARCH") then
                self.corruptSteerUntil = now + facingTime
                self.nextAction = math.max(self.nextAction, self.corruptSteerUntil)
            end
            if target and (name == "Charge" or name == "WalkspeedOverride") then
                self.nativeControlUntil = math.max(self.nativeControlUntil, now + facingTime)
            end
            return true
        end

        function Ability:MovementLocked()
            local actor = self:GetActor()
            local char = actor and actor.Rig
            if not char then return false end
            if os.clock() < (self.nativeControlUntil or 0) then return true end
            if char.PrimaryPart and char.PrimaryPart.Anchored then return true end
            if self.sprinting and self.sprinting.isSpeedLocked then return true end
            local rush = char:GetAttribute("VoidRushState")
            if rush == "Charging" or rush == "Dashing" then return true end
            local pursuit = char:GetAttribute("PursuitState")
            if pursuit and pursuit ~= "Idle" and pursuit ~= "None" and pursuit ~= "Cancelled" then return true end
            if actor.State and (actor.State.isSkating or actor.State.IsCrystalEquipped) then return true end
            if actor.State and (actor.State.InFlight or (actor.State.DescentStoppers and next(actor.State.DescentStoppers))) then return true end
            if actor.State and (actor.State.GrabAimingSequence or actor.State.GrabbedRoot) then return true end
            -- RevertObservance removes Generators but leaves Observing true in this copy.
            if actor.Behavior and actor.Behavior.Observing and actor.Behavior.Generators ~= nil then return true end
            return false
        end

        local meleeWords = {"slash", "stab", "attack", "tag", "behead", "gashing", "carving", "bite", "punch", "grab", "claw"}
        local rangedWords = {"corrupt", "massinfection", "entanglement", "nova", "bats", "uppercut", "spire", "sow", "blossom", "fire", "dismantle"}
        local dashWords = {"voidrush", "demonicpursuit", "walkspeedoverride", "charge", "lunge", "dash"}
        local function containsAny(name, words)
            name = string.lower(tostring(name)):gsub("[^%w]", "")
            for _, word in ipairs(words) do if string.find(name, word, 1, true) then return true end end
            return false
        end

        function Ability:Threat(killerModel)
            local killer = self:GetActor(killerModel)
            local own = rootOf(self.player.Character)
            local other = rootOf(killerModel)
            if not own or not other or not killer then return false, nil, 0 end
            local delta = horizontal(own.Position - other.Position)
            local distance = delta.Magnitude
            if distance < 0.1 then return true, "Contact", 10 end
            local facing = horizontal(other.CFrame.LookVector):Dot(delta.Unit)
            if facing < 0.3 or not self:LOS(other, own) then return false, nil, 0 end
            local map = self.animCache[killer]
            if not map then
                map = {}
                local function add(t, prefix, depth)
                    if depth > 3 then return end
                    for k, v in pairs(t or {}) do
                        local name = prefix .. tostring(k)
                        if type(v) == "string" and v:match("%d%d%d+") then
                            local range
                            if containsAny(name, dashWords) then range = 95
                            elseif containsAny(name, rangedWords) then range = 100
                            elseif containsAny(name, meleeWords) then range = 13 end
                            if range then map[v:match("%d+")] = {name, range} end
                        elseif type(v) == "table" then add(v, name, depth + 1) end
                    end
                end
                add(killer.Config and killer.Config.Animations, "", 0)
                self.animCache[killer] = map
            end
            local hum = killerModel:FindFirstChildOfClass("Humanoid")
            local animator = hum and hum:FindFirstChildOfClass("Animator")
            if animator then
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    local animation = track.Animation
                    local info = animation and map[animation.AnimationId:match("%d+")]
                    if info and track.IsPlaying and track.WeightCurrent > 0.05 and distance <= info[2] then
                        return true, info[1], info[2]
                    end
                end
            end
            for _, key in ipairs({"VoidRushState", "PursuitState"}) do
                local state = killerModel:GetAttribute(key)
                if state and (state == "Dashing" or state == "Charging" or state == "Rushing") and distance < 95 then
                    return true, key, 95
                end
            end
            return false, nil, 0
        end

        function Ability:Teammate(actor, origin, maxDistance, injured)
            local best, bestD
            for _, candidate in pairs(self.actors and self.actors.CurrentActors or {}) do
                if candidate ~= actor and candidate.ActorType == "Survivor" and isAlive(candidate.Rig) then
                    local root = rootOf(candidate.Rig)
                    local hum = candidate.Rig:FindFirstChildOfClass("Humanoid")
                    local d = (root.Position - origin.Position).Magnitude
                    if d <= maxDistance and (not injured or hum.Health <= hum.MaxHealth - 12)
                        and (not bestD or d < bestD) and self:LOS(origin, root) then best, bestD = root, d end
                end
            end
            return best, bestD
        end

        function Ability:GetLastAction()
            return self.lastActionRecord
        end

        function Ability:GetDefenseState(model)
            local actor = self:GetActor(model)
            local result = {blocking = false, parry = false}
            if not actor or actor.ActorName ~= "Guest1337" or not model then return result end
            local punch = self:Abilities(actor).Punch
            result.parry = actor.Blocked == true or (punch and punch.Icon == "rbxassetid://76339130778616") or false
            result.blocking = actor.Blocking == true or model:GetAttribute("Blocking") == true
            local block = actor.Animations and actor.Animations.Block
            if block and block.IsPlaying then result.blocking = true end
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
            local blockId = actor.Config and actor.Config.Animations and actor.Config.Animations.Block
            if animator and type(blockId) == "string" then
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    if track.IsPlaying and track.Animation and track.Animation.AnimationId == blockId and track.WeightCurrent > 0.05 then
                        result.blocking = true
                    end
                end
            end
            return result
        end

        function Ability:IsBlocking(model)
            return self:GetDefenseState(model).blocking
        end

        function Ability:_GuestIncoming(sense)
            local target, own = sense.killerRoot, sense.root
            if not target or not own or not self:LOS(own, target) then return false end
            local delta = horizontal(own.Position - target.Position)
            local distance = delta.Magnitude
            if distance < 0.1 then return true end
            local attack = sense.incomingAttack or (sense.killerModel and self:Threat(sense.killerModel))
            if attack and distance <= 20 then return true end
            local facing = horizontal(target.CFrame.LookVector):Dot(delta.Unit)
            if facing < 0.25 then return false end
            local closing = horizontal(target.AssemblyLinearVelocity or Vector3.new(0, 0, 0)):Dot(delta.Unit)
            -- Block lasts one second. Lead a closing melee threat rather than waiting
            -- until the hitbox is already inside the old 14-stud reaction boundary.
            return closing > 2 and distance <= math.clamp(9 + closing * 0.4, 12, 19)
        end

        function Ability:_UpdateNoli(sense, actor)
            if actor.ActorName ~= "Noli" and actor.ActorName ~= "#NoliRacing" then self.noliCombo = nil; return false end
            local now, cfg = sense.now or os.clock(), actor.Config or {}
            local state = actor.Rig:GetAttribute("VoidRushState")
            local active = state == "Charging" or state == "Dashing"
            if self.noliWasRushing and not active then
                if actor.HeldAbilities then actor.HeldAbilities.VoidRush = nil end
                self.held.VoidRush = nil
                self:_ClearAttackFacing()
            end
            self.noliWasRushing = active
            local ui = actor.Behavior and actor.Behavior.VoidRushUI
            local text = ui and ui.Text and ui.Text.Text
            local hitText = cfg.VoidRushStopMessages and cfg.VoidRushStopMessages.Hit
            local hit = ui and not ui.Dead and hitText and text == hitText
            if hit and (self.noliHitUI ~= ui or self.noliHitCounter ~= ui.Counter) then
                self.noliHitUI, self.noliHitCounter = ui, ui.Counter
                local endlag = value(cfg, "VoidRushHitEndlag", 0.85)
                self.noliCombo = {actor = actor, ui = ui, counter = ui.Counter,
                    readyAt = now + endlag, expires = now + endlag + value(cfg, "VoidRushComboWindow", 2)}
            end
            local combo = self.noliCombo
            if combo and (combo.actor ~= actor or not hit or ui ~= combo.ui or ui.Counter ~= combo.counter or now > combo.expires) then
                self.noliCombo = nil; combo = nil
            end
            if not combo then return false end
            if combo.sent then return now - combo.sent < 0.4 end
            if now < combo.readyAt or active then return true end
            local target = sense.targetRoot
            if not sense.evading and target and isAlive(target.Parent) and not self:IsBlocking(target.Parent)
                and (target.Position - sense.root.Position).Magnitude < 120 and self:LOS(sense.root, target) then
                local hold = value(cfg, "VoidRushChargeLength", 1) + value(cfg, "VoidRushDashLength", 3.5) + 0.3
                if self:Use(actor, "VoidRush", sense, target, hold) then combo.sent = now end
            end
            return true
        end

        function Ability:GetGraffiti(actor)
            local list, seen = {}, {}
            for object, visual in pairs(actor and actor.SprayVisuals or {}) do
                local paint = visual.Root or object
                if paint and paint.Parent and not seen[paint] and (not visual.Owner or visual.Owner == self.player)
                    and (not paint.GetAttribute or paint:GetAttribute("Destroyed") ~= true) then
                    seen[paint] = true
                    local point = paint.GetPivot and paint:GetPivot().Position or paint.Position or (rootOf(paint) and rootOf(paint).Position)
                    local complete = not paint.GetAttribute or paint:GetAttribute("Completed") == true
                        or (paint:GetAttribute("Progression") or 0) >= 100
                    table.insert(list, {model = paint, point = point, complete = complete})
                end
            end
            return list
        end

        function Ability:_GraffitiEscape(sense, actor)
            local now = sense.now or os.clock()
            local state = actor.State or {}
            if state.isSkating or state.InZone or state.ClosestSpray or not sense.killerRoot
                or sense.evading or sense.selfCornered or (sense.killerDistance or math.huge) > 65
                or not (sense.fleeing or sense.underAttack or sense.damaged or sense.killerDistance < 30)
                or not self:Ready(actor, "Sk8", now) then self.graffitiEscape = nil; return nil end
            local route = self.graffitiEscape
            if route and (now >= route.expires or not route.source.Parent or route.source:GetAttribute("Destroyed")
                or horizontal(route.goal - sense.root.Position).Magnitude < 4) then self.graffitiEscape = nil; route = nil end
            if not route and now >= (self.nextGraffitiEscape or 0) then
                local movement = self.ctx.getMovement and self.ctx.getMovement()
                if not movement or not movement._clearLine then return nil end
                local params, best, scoreBest = movement:_rayParams(sense.character)
                local entries = self:GetGraffiti(actor)
                local candidates = {}
                for _, entry in ipairs(entries) do
                    if entry.complete and entry.point then table.insert(candidates, {point = entry.point, source = entry.model}) end
                end
                if #candidates >= 3 then
                    local center = (candidates[1].point + candidates[2].point + candidates[3].point) * (1 / 3)
                    table.insert(candidates, 1, {point = center, source = candidates[1].source})
                end
                for _, candidate in ipairs(candidates) do
                    local delta = horizontal(candidate.point - sense.root.Position)
                    local distance = delta.Magnitude
                    if distance > 6 and distance < 100 then
                        local point = candidate.point - delta.Unit * math.min(8, distance * 0.25)
                        local floor = workspace:Raycast(point + Vector3.new(0, 8, 0), Vector3.new(0, -20, 0), params)
                        if floor and floor.Normal.Y > 0.5 then
                            point = floor.Position + Vector3.new(0, movement:_standHeight(sense.root, sense.humanoid), 0)
                            local leg = horizontal(point - sense.root.Position)
                            local toKiller = horizontal(sense.killerRoot.Position - sense.root.Position)
                            local fraction = leg.Magnitude > 0 and math.clamp(toKiller:Dot(leg) / leg:Dot(leg), 0, 1) or 0
                            local clearance = (toKiller - leg * fraction).Magnitude
                            if clearance >= 12 and (point - sense.killerRoot.Position).Magnitude >= 20
                                and movement:_clearLine(sense.root.Position, point, params) then
                                local score = (point - sense.killerRoot.Position).Magnitude - distance * 0.6
                                if not scoreBest or score > scoreBest then best, scoreBest = {goal = point, source = candidate.source}, score end
                            end
                        end
                    end
                end
                if best then
                    best.expires = now + 8
                    self.graffitiEscape, self.nextGraffitiEscape = best, now + 18
                    route = best
                end
            end
            if route then return {kind = "escapeZone", priority = 90, goal = route.goal, sprint = true, arrival = 3,
                label = "ESCAPING TO GRAFFITI", expires = route.expires} end
        end

        function Ability:_NormalInput(actor, suffix, ...)
            if not self.network or not actor or not actor.Player then return false end
            return pcall(self.network.FireServerConnection, self.network, actor.Player.Name .. suffix, "REMOTE_EVENT", ...)
        end

        function Ability:_StatePress(actor, ability, sense)
            -- These native buttons change meaning in a server-confirmed mode. Their
            -- ordinary attack cooldown need not be the mode-specific input cooldown.
            local valid = actor.ActorName == "Azure" and actor.State
                and ((ability == "Slash" and (actor.State.GrabAimingSequence or actor.State.GrabbedRoot))
                    or (ability == "Grab" and actor.State.GrabAimingSequence))
                or actor.ActorName == "Noli" and ability == "Observant" and actor.Behavior and actor.Behavior.Observing
            if not valid or not self.network or not self:Abilities(actor)[ability] then return false end
            local now = sense.now or os.clock()
            if now < (self.statePressAt or 0) + 0.35 then return false end
            self.statePressAt = now
            actor.HeldAbilities = actor.HeldAbilities or {}
            actor.HeldAbilities[ability] = true
            self.held[ability] = {actor = actor, releaseAt = now + 0.15}
            local ok = pcall(self.network.FireServerConnection, self.network, "UseActorAbility", "REMOTE_EVENT", ability, nil)
            if ok then
                self.actionSerial += 1
                self.lastAction = ability
                self.lastActionRecord = {serial = self.actionSerial, name = ability, time = now, stateTransition = true}
            end
            return ok
        end

        function Ability:_SprayInput(actor, state)
            if not actor.State or actor.State.SprayState == nil or actor.State.SprayState == state then return false end
            -- Exact same transition as Veeronica's native SprayInput/WipeInput handler.
            actor.State.SprayState, actor.State.LastSprayState = state, state
            local behavior = actor.CustomBehavior and actor.CustomBehavior.OnSprayStateChanged and actor.CustomBehavior or actor.Behavior
            if behavior and behavior.OnSprayStateChanged then pcall(behavior.OnSprayStateChanged, behavior, actor, state) end
            return self:_NormalInput(actor, "UpdateSprayInput", state)
        end

        function Ability:_FindWall(sense, maximum)
            local params = RaycastParams.new()
            params.FilterType, params.RespectCanCollide = Enum.RaycastFilterType.Exclude, true
            local players = workspace:FindFirstChild("Players")
            params.FilterDescendantsInstances = players and {sense.character, players} or {sense.character}
            local root, best = sense.root
            for index = 0, 11 do
                local angle = index * math.pi / 6
                local ray = Vector3.new(math.cos(angle), 0, math.sin(angle))
                local hit = workspace:Raycast(root.Position, ray * maximum, params)
                if hit and math.abs(hit.Normal.Y) < 0.25 and hit.Instance and hit.Instance.CanCollide then
                    local d = (hit.Position - root.Position).Magnitude
                    if d > 2 and (not best or d < best.distance) then
                        local stand = hit.Position + hit.Normal * 4
                        local floor = workspace:Raycast(stand + Vector3.new(0, 3, 0), Vector3.new(0, -10, 0), params)
                        if floor and floor.Normal.Y >= 0.5 then
                            best = {position = hit.Position, normal = hit.Normal, goal = Vector3.new(stand.X, root.Position.Y, stand.Z), distance = d}
                        end
                    end
                end
            end
            return best
        end

        function Ability:_Danger(sense)
            local humanoid = sense.humanoid
            return sense.evading == true or sense.selfCornered == true or sense.incomingAttack == true
                or sense.underAttack == true or sense.damaged == true
                or (humanoid and humanoid.Health < humanoid.MaxHealth * 0.38)
        end

        function Ability:_PlanSequence(sense)
            local actor = self:GetActor()
            if not actor or not sense.root or not sense.humanoid then return nil end
            local now = sense.now or os.clock()
            local sequence = self.sequence
            local enabled = not self.ctx.settings or self.ctx.settings.CharacterCombos ~= false
            if sequence and (not enabled or sequence.actor ~= actor or now > sequence.expires or self:_Danger(sense)
                or (sequence.target and (not sequence.target.Parent or not isAlive(sequence.target.Parent)))) then
                sequence.cancelled = true
                return sequence
            end
            if sequence then return sequence end
            if not enabled then return nil end
            local target = sense.killerRoot
            local distance = target and (target.Position - sense.root.Position).Magnitude or math.huge
            if actor.ActorName == "TwoTime" and target and distance >= 9 and distance <= 55
                and not self:_Danger(sense) and (sense.stamina or 100) >= 30
                and self:Ready(actor, "Dagger", now) and (actor.Rig:GetAttribute("Crouching") or self:Ready(actor, "Crouch", now)) then
                self.sequence = {kind = "TwoTime", actor = actor, target = target, began = now, expires = now + 8,
                    phase = actor.Rig:GetAttribute("Crouching") and "approach" or "crouch", crouchedAt = now}
            elseif actor.ActorName == "Taph" and distance > 70 and not self:_Danger(sense)
                and now >= (self.nextTripwire or 0) and self:Ready(actor, "Tripwire", now) then
                local forward = horizontal(sense.root.CFrame.LookVector)
                local side = Vector3.new(-forward.Z, 0, forward.X)
                local goal = sense.root.Position + side * 10
                local params = RaycastParams.new()
                params.FilterType, params.RespectCanCollide = Enum.RaycastFilterType.Exclude, true
                params.FilterDescendantsInstances = {sense.character}
                local support = workspace:Raycast(goal + Vector3.new(0, 3, 0), Vector3.new(0, -10, 0), params)
                if support and support.Normal.Y >= 0.5 and not workspace:Raycast(sense.root.Position, goal - sense.root.Position, params) then
                    self.sequence = {kind = "Tripwire", actor = actor, phase = "start", goal = goal,
                        began = now, expires = now + 8}
                end
            elseif actor.ActorName == "Veeronica" and not self:_Danger(sense) and distance > 70
                and self:Ready(actor, "Vandalism", now) and now >= (self.nextGraffiti or 0)
                and #self:GetGraffiti(actor) < 3
                and not (actor.State and (actor.State.isSkating or actor.State.SprayState)) then
                local wall = self:_FindWall(sense, 22)
                if wall then self.sequence = {kind = "Graffiti", actor = actor, wall = wall,
                    phase = "approach", began = now, expires = now + 12, activeBefore = actor.ActiveSprays} end
            end
            return self.sequence
        end

        function Ability:GetTacticalIntent(sense)
            local actor = self:GetActor()
            if actor and actor.ActorName == "Guest1337" and sense.killerRoot and sense.root
                and self:GetDefenseState(actor.Rig).parry and self:Ready(actor, "Punch", sense.now or os.clock())
                and (sense.killerRoot.Position - sense.root.Position).Magnitude <= 10.5
                and self:LOS(sense.root, sense.killerRoot) then
                return {kind = "hold", hold = true, faceTarget = sense.killerRoot, cameraTarget = sense.killerRoot,
                    label = "PARRY COUNTERATTACK", priority = 100, expires = (sense.now or os.clock()) + 0.4}
            end
            if actor and actor.ActorName == "Guest1337" and self:_GuestIncoming(sense)
                and self:Ready(actor, "Block", sense.now or os.clock()) then
                return {kind = "hold", hold = true, faceTarget = sense.killerRoot, cameraTarget = sense.killerRoot,
                    label = "BLOCKING INCOMING ATTACK", priority = 100, expires = (sense.now or os.clock()) + 0.35}
            end
            if actor and actor.ActorName == "Guest1337" and sense.killerRoot and sense.root
                and not sense.damaged and (sense.now or os.clock()) < (self.guestBlockUntil or 0)
                and (sense.killerRoot.Position - sense.root.Position).Magnitude <= 20
                and self:LOS(sense.root, sense.killerRoot) then
                return {kind = "hold", hold = true, faceTarget = sense.killerRoot, cameraTarget = sense.killerRoot,
                    label = "HOLDING BLOCK FOR PARRY", priority = 100, expires = self.guestBlockUntil}
            end
            if actor and actor.ActorName == "Veeronica" and (not self.ctx.settings or self.ctx.settings.CharacterCombos ~= false) then
                local escape = self:_GraffitiEscape(sense, actor)
                if escape then return escape end
            end
            local sequence = self:_PlanSequence(sense)
            if sequence and not sequence.cancelled then
                if sequence.kind == "TwoTime" then
                    local target = sequence.target
                    if not target or not target.Parent then return nil end
                    local behind = target.Position - horizontal(target.CFrame.LookVector).Unit * 5
                    return {kind = "approach", goal = behind, faceTarget = target, sprint = true, arrival = 2.5,
                        hold = sequence.phase == "crouch" or sequence.phase == "waiting",
                        label = sequence.phase == "crouch" and "CROUCHING FOR LUNGE" or "CROUCHED BACKSTAB APPROACH",
                        priority = 50, expires = sequence.expires}
                elseif sequence.kind == "Graffiti" then
                    return {kind = "placement", goal = sequence.wall.goal, faceTarget = sequence.wall.position,
                        hold = sequence.phase == "spraying" or sequence.phase == "equipping",
                        sprint = false, arrival = 1.5, label = "PAINTING GRAFFITI", priority = 30, expires = sequence.expires}
                elseif sequence.kind == "Tripwire" then
                    return {kind = "placement", goal = sequence.phase == "move" and sequence.goal or sense.root.Position,
                        sprint = false, arrival = 1.5, label = "PLACING TWO-POINT TRIPWIRE", priority = 25, expires = sequence.expires}
                end
            end
            if actor and actor.ActorName == "Veeronica" and actor.State and actor.State.isSkating then
                local root = sense.root
                local away = sense.killerRoot and horizontal(root.Position - sense.killerRoot.Position) or horizontal(root.CFrame.LookVector)
                if away.Magnitude > 0.01 then
                    self.nativeSteerGoal = root.Position + away.Unit * 60
                    return {kind = "approach", goal = self.nativeSteerGoal, cameraTarget = self.nativeSteerGoal,
                        sprint = true, arrival = 3, label = "SKATING / WALL TRICKS", priority = 55,
                        expires = (sense.now or os.clock()) + 0.6}
                end
            end
            if actor and actor.ActorName == "Azure" and actor.State and actor.State.GrabAimingSequence and sense.targetRoot then
                return {kind = "hold", hold = true, faceTarget = sense.targetRoot, cameraTarget = sense.targetRoot,
                    label = "AIMING ENSTRANGLE", priority = 65, expires = (sense.now or os.clock()) + 0.5}
            end
            if actor and actor.ActorName == "Builderman" and actor.CarryingBuilding then
                if not self.carryGoal then
                    local ally = self:Teammate(actor, sense.root, 60, true)
                    self.carryGoal = ally and ally.Position or sense.root.Position + horizontal(sense.root.CFrame.LookVector) * 12
                end
                return {kind = "placement", goal = self.carryGoal, sprint = false, arrival = 2,
                    label = "RELOCATING BUILDING", priority = 25, expires = (sense.now or os.clock()) + 0.5}
            else self.carryGoal = nil end
            if actor and actor.ActorType == "Killer" and sense.targetRoot and self:IsBlocking(sense.targetModel) then
                local target = sense.targetRoot
                local side = Vector3.new(-target.CFrame.LookVector.Z, 0, target.CFrame.LookVector.X)
                return {kind = "approach", goal = target.Position + side * 7 - horizontal(target.CFrame.LookVector) * 4,
                    faceTarget = target, sprint = true, arrival = 2, label = "WAITING OUT GUEST BLOCK", priority = 60,
                    expires = (sense.now or os.clock()) + 0.5}
            end
            return nil
        end

        Ability.GetCombatIntent = Ability.GetTacticalIntent

        function Ability:_UpdateSequence(sense, actor, own)
            local sequence = self:_PlanSequence(sense)
            if not sequence then return false end
            local now, cfg = sense.now or os.clock(), actor.Config or {}
            if sequence.cancelled then
                if sequence.actor ~= actor then
                    -- An old character's toggle must never become an input on a new one.
                    self.sequence = nil
                    return false
                end
                local cleaned = true
                if sequence.kind == "Graffiti" then
                    self:_SprayInput(actor, "Idle")
                    if actor.State and actor.State.SprayState then cleaned = self:Use(actor, "Vandalism", sense)
                    elseif sequence.equippedAt and now - sequence.equippedAt < 2 then cleaned = false end
                end
                if sequence.kind == "Tripwire" and actor.Rig:GetAttribute("TripwireOrigin") then
                    cleaned = self:Use(actor, "Tripwire", sense)
                end
                if sequence.kind == "TwoTime" and sequence.ownedCrouch then
                    if actor.Rig:GetAttribute("Crouching") then cleaned = self:Use(actor, "Crouch", sense)
                    elseif sequence.phase == "waiting" and now - sequence.requestedAt < 2 then cleaned = false end
                end
                -- Keep cleanup pending if the native cooldown has not permitted the
                -- ordinary mode-exit input yet; suppress additional combo work meanwhile.
                if not cleaned then return true end
                self.sequence = nil
                self.nextGraffiti = now + 12
                return false
            end
            if sequence.kind == "TwoTime" then
                local target = sequence.target
                if not target or not target.Parent then self.sequence = nil; return false end
                if sequence.phase == "crouch" then
                    if self:Use(actor, "Crouch", sense) then
                        sequence.phase, sequence.ownedCrouch, sequence.requestedAt = "waiting", true, now
                    end
                elseif sequence.phase == "waiting" then
                    if actor.Rig:GetAttribute("Crouching") then sequence.phase, sequence.crouchedAt = "approach", now
                    elseif now - sequence.requestedAt > 1.8 then self.sequence = nil end
                elseif sequence.phase == "approach" then
                    if not actor.Rig:GetAttribute("Crouching") then self.sequence = nil; return false end
                    local distance = (target.Position - own.Position).Magnitude
                    local elapsed = now - sequence.crouchedAt
                    local toward = horizontal(target.Position - own.Position)
                    local behind = distance > 0.1 and horizontal(own.Position - target.Position).Unit:Dot(horizontal(target.CFrame.LookVector)) < -0.25
                    local charged = elapsed >= math.min(value(cfg, "DaggerCrouchStunChargeTime", 3), 3)
                    if distance <= 22 and self:LOS(own, target) and (behind or charged or distance < 9) then
                        self:Aim(target, 1.5, value(cfg, "DaggerLungeForce", 110), value(cfg, "DaggerWindup", 0.3))
                        if toward.Magnitude > 0.05 and horizontal(own.CFrame.LookVector):Dot(toward.Unit) < 0.65 then
                            if self.ctx.face then pcall(self.ctx.face, target, 0.5) end
                        elseif self:Use(actor, "Dagger", sense, target, nil, nil, value(cfg, "DaggerLungeForce", 110)) then
                            self.nativeControlUntil, self.sequence = now + 1.2, nil
                        end
                    end
                end
                return true
            end
            if sequence.kind == "Tripwire" then
                if sequence.phase == "start" then
                    if self:Use(actor, "Tripwire", sense) then sequence.phase, sequence.requestedAt = "waiting", now end
                elseif sequence.phase == "waiting" then
                    if actor.Rig:GetAttribute("TripwireOrigin") then sequence.phase = "move"
                    elseif now - sequence.requestedAt > 2 then self.sequence = nil; self.nextTripwire = now + 10 end
                elseif sequence.phase == "move" then
                    if not actor.Rig:GetAttribute("TripwireOrigin") then self.sequence = nil; self.nextTripwire = now + 25
                    elseif horizontal(own.Position - sequence.goal).Magnitude < 2
                        and now - sequence.requestedAt >= value(cfg, "TripwireCooldownWhilePlacing", 2.5)
                        and self:Use(actor, "Tripwire", sense) then
                        self.sequence, self.nextTripwire = nil, now + value(cfg, "TripwireCooldown", 25)
                    end
                end
                return true
            end
            if sequence.kind == "Graffiti" then
                local wall = sequence.wall
                self:AimPoint(wall.position, 0.7)
                if sequence.phase == "approach" and horizontal(own.Position - wall.goal).Magnitude <= 2 then
                    if self:Use(actor, "Vandalism", sense) then sequence.phase, sequence.equippedAt = "equipping", now end
                elseif sequence.phase == "equipping" then
                    if actor.State and actor.State.SprayState and now - sequence.equippedAt >= value(cfg, "VandalismSprayWait", 0.35) then
                        self:_SprayInput(actor, "Spraying")
                        sequence.phase, sequence.sprayAt = "spraying", now
                    elseif now - sequence.equippedAt > 2 then self.sequence = nil; self.nextGraffiti = now + 12 end
                elseif sequence.phase == "spraying" then
                    local completed = false
                    for model, visual in pairs(actor.SprayVisuals or {}) do
                        local paint = visual.Root or model
                        if paint and paint.GetAttribute then
                            local part = rootOf(paint)
                            if part and (part.Position - wall.position).Magnitude < 10 then
                                completed = paint:GetAttribute("Completed") == true or (paint:GetAttribute("Progression") or 0) >= 100
                                if completed then break end
                            end
                        end
                    end
                    if completed or now - sequence.sprayAt >= value(cfg, "VandalismSprayTime", 5) + 3 then
                        self:_SprayInput(actor, "Idle")
                        self:Use(actor, "Vandalism", sense)
                        self.lastGraffitiCompleted = completed
                        self.sequence, self.nextGraffiti = nil, now + value(cfg, "VandalismPostCooldown", 12)
                    elseif not actor.State or not actor.State.SprayState then self.sequence = nil; self.nextGraffiti = now + 10 end
                end
                return true
            end
            return false
        end

        function Ability:_NativeControls(actor)
            if self.nativeControls then return self.nativeControls end
            local scripts = self.player.FindFirstChild and self.player:FindFirstChild("PlayerScripts")
            local module = scripts and loadModule(scripts, "PlayerModule")
            if module and module.GetControls then
                local ok, controls = pcall(module.GetControls, module)
                if ok and controls and type(controls.GetMoveVector) == "function" then self.nativeControls = controls end
            end
            return self.nativeControls
        end

        function Ability:_RestoreNativeInput()
            if self.nativeControls and self.moveVectorWrapper and self.nativeControls.GetMoveVector == self.moveVectorWrapper then
                self.nativeControls.GetMoveVector = self.originalMoveVector
            end
            self.moveVectorWrapper, self.originalMoveVector = nil, nil
        end

        function Ability:_UpdateNative(sense, actor)
            local now = sense.now or os.clock()
            if actor.ActorType == "Survivor" and (self:_Danger(sense) or (sense.killerDistance or math.huge) < 35) then
                for _, ability in ipairs({"Pray", "Crystal"}) do
                    if self.held[ability] then
                        if actor.HeldAbilities then actor.HeldAbilities[ability] = nil end
                        self.held[ability] = nil
                    end
                end
            end
            for key, releaseAt in pairs(self.inputReleases) do
                if now >= releaseAt then
                    if self.ctx.input and self.ctx.input.SetKey then pcall(self.ctx.input.SetKey, self.ctx.input, key, false) end
                    self.inputReleases[key] = nil
                end
            end
            if actor.ActorName == "Azure" and actor.State and actor.State.GrabbedRoot
                and self.azureHeldRoot ~= actor.State.GrabbedRoot then
                -- Once caught, the victim is the throw origin. Do not keep the prior
                -- hook lock aimed back at that origin while choosing a throw direction.
                self:_ClearAttackFacing()
            end
            local face = self.faceCast
            local predicted = face and face.predictor and face.predictor()
            if predicted and not actor.Rig:GetAttribute("Ragdolling") then
                if self.ctx.attackFace then pcall(self.ctx.attackFace, face.target, math.min(0.4, face.untilTime - now), face.predictor)
                elseif self.ctx.face and not self:MovementLocked() then pcall(self.ctx.face, predicted, 0.4) end
                if predicted and self.ctx.cameraAim then pcall(self.ctx.cameraAim, predicted, 0.4) end
            else self:_ClearAttackFacing() end
            if actor.Behavior and actor.Behavior.Observing and actor.Behavior.Generators ~= nil then
                local target = sense.targetRoot
                local best, bestDistance
                for generator, info in pairs(actor.Behavior.Generators or {}) do
                    local object = info.Instance or generator
                    if object and object.Parent and object.GetPivot then
                        local point = object:GetPivot().Position
                        if (point - sense.root.Position).Magnitude >= value(actor.Config, "ObservantMinDistance", 50) then
                            local d = target and (point - target.Position).Magnitude or (point - sense.root.Position).Magnitude
                            if not bestDistance or d < bestDistance then best, bestDistance = object, d end
                        end
                    end
                end
                if best and now >= (self.nextObservantChoice or 0) then
                    -- This is precisely the native generator button's OnClicked request.
                    self:_NormalInput(actor, "ObservantTeleport", best)
                    self.nextObservantChoice = now + 1.5
                elseif not best and now >= (self.nextObservantChoice or 0) then
                    self:_StatePress(actor, "Observant", sense)
                    self.nextObservantChoice = now + 1.5
                end
            end
            if actor.ActorName == "Azure" and actor.State then
                if actor.State.GrabAimingSequence then
                    self.azureGrabBegan = self.azureGrabBegan or now
                    if sense.targetRoot then
                        self:Aim(sense.targetRoot, 0.6, nested(actor.Config, "Grab", "HookSpeed", 270))
                        self:_TrackAttack(sense.targetRoot, 0.6, nested(actor.Config, "Grab", "HookSpeed", 270),
                            math.max(0, nested(actor.Config, "Grab", "Windup", 1) - (now - self.azureGrabBegan)))
                        if self.ctx.cameraAim then pcall(self.ctx.cameraAim, sense.targetRoot, 0.5) end
                        if now - self.azureGrabBegan >= nested(actor.Config, "Grab", "Windup", 1) + 0.1
                            and now >= (self.azureNextThrow or 0) and not self:IsBlocking(sense.targetModel) then
                            if self:LOS(sense.root, sense.targetRoot) and (sense.targetRoot.Position - sense.root.Position).Magnitude <= nested(actor.Config, "Grab", "HookRange", 60) then
                                if self:_StatePress(actor, "Slash", sense) then self.azureNextThrow = now + 1 end
                            elseif now - self.azureGrabBegan > 3 then self:_StatePress(actor, "Grab", sense) end
                        end
                    elseif now - self.azureGrabBegan > 3 then self:_StatePress(actor, "Grab", sense) end
                else self.azureGrabBegan = nil end
                if actor.State.GrabbedRoot then
                    if self.azureHeldRoot ~= actor.State.GrabbedRoot then
                        self.azureHeldRoot, self.azureHeldAt = actor.State.GrabbedRoot, now
                        self.azureThrowPoint = sense.root.Position + horizontal(sense.root.CFrame.LookVector) * 35 + Vector3.new(0, 5, 0)
                    end
                    local point = self.azureThrowPoint
                    self:_TrackAttackPoint(point, 0.6)
                    self:AimPoint(point, 0.6)
                    if self.ctx.cameraAim then pcall(self.ctx.cameraAim, point, 0.4) end
                    if now - self.azureHeldAt >= 0.5 and now >= (self.azureNextThrow or 0) then
                        if self:_StatePress(actor, "Slash", sense) then self.azureNextThrow = now + 1 end
                    end
                else self.azureHeldAt, self.azureHeldRoot, self.azureThrowPoint = nil, nil, nil end
            end
            if actor.State and actor.State.InFlight and (actor.ActorName == "Nosferatu" or actor.ActorName == "#Nosferatwo") then
                self.flightBegan = self.flightBegan or now
                if sense.targetRoot then
                    self:_TrackAttack(sense.targetRoot, 0.5, self:TravelSpeed(actor, "Ascent", 100))
                    if self.ctx.cameraAim then pcall(self.ctx.cameraAim, sense.targetRoot, 0.4) end
                end
                if now - self.flightBegan >= 1.15 and not self.flightExitRequested then
                    actor.HeldAbilities = actor.HeldAbilities or {}
                    local dive = sense.targetRoot and not self:IsBlocking(sense.targetModel)
                    local key = dive and "Slash" or "Ascent"
                    actor.HeldAbilities[key] = true
                    self.held[key] = {actor = actor, releaseAt = now + 0.6}
                    self.flightExitRequested, self.nativeControlUntil = true, now + 2
                end
            else self.flightBegan, self.flightExitRequested = nil, nil end
            local skating = actor.ActorName == "Veeronica" and actor.State and actor.State.isSkating
            if not skating then self.stoppingSkate = nil; self:_RestoreNativeInput(); return end
            if self.ctx.settings and self.ctx.settings.CharacterCombos == false then
                -- Stop only a skate started by this adapter. A player's native skate
                -- keeps its own input handling when automatic combinations are disabled.
                self:_RestoreNativeInput()
                self.nativeSteerGoal = nil
                for key in pairs(self.inputReleases) do
                    if self.ctx.input and self.ctx.input.SetKey then pcall(self.ctx.input.SetKey, self.ctx.input, key, false) end
                    self.inputReleases[key] = nil
                end
                if self.skateOwned == actor and not self.stoppingSkate then
                    actor.HeldAbilities = actor.HeldAbilities or {}
                    actor.HeldAbilities.Sk8 = true
                    self.stoppingSkate = true
                end
                return
            end
            local root = sense.root
            local away = sense.killerRoot and horizontal(root.Position - sense.killerRoot.Position) or horizontal(root.CFrame.LookVector)
            if away.Magnitude > 0.01 then self.nativeSteerGoal = root.Position + away.Unit * 60 end
            local controls = self:_NativeControls(actor)
            if controls and not self.moveVectorWrapper then
                self.originalMoveVector = controls.GetMoveVector
                local original = self.originalMoveVector
                self.moveVectorWrapper = function(module, ...)
                    if not self.destroyed and actor.State and actor.State.isSkating and self.nativeSteerGoal and workspace.CurrentCamera then
                        local delta = horizontal(self.nativeSteerGoal - rootOf(actor.Rig).Position)
                        if delta.Magnitude > 0.01 then return workspace.CurrentCamera.CFrame:VectorToObjectSpace(delta.Unit) end
                    end
                    return original(module, ...)
                end
                controls.GetMoveVector = self.moveVectorWrapper
            end
            if self.ctx.cameraAim and self.nativeSteerGoal then pcall(self.ctx.cameraAim, self.nativeSteerGoal, 0.4) end
            local highlight = actor.Instances and actor.Instances.Sk8Highlight
            if highlight and highlight.Adornee == actor.Rig and now >= (self.nextSkateTrick or 0)
                and self.ctx.input and self.ctx.input.SetKey and Enum.KeyCode.Space then
                local ok, accepted = pcall(self.ctx.input.SetKey, self.ctx.input, Enum.KeyCode.Space, true)
                if ok and accepted ~= false then
                    self.inputReleases[Enum.KeyCode.Space] = now + 0.1
                    self.nextSkateTrick = now + value(actor.Config, "Sk8TrickCooldown", 1) + 0.12
                end
            end
            -- The native skate callback ends at its actual minimum (normally zero).
            -- Space tricks replenish stamina through that callback, so do not stop at
            -- the ordinary walking/sprinting reserve while a skate is still active.
        end

        -- Healing needs an injured teammate; a counterattack needs a killer actually
        -- threatening someone else. A ready attack alone is not a reason to seek danger.
        function Ability:GetAssistIntent(sense, previous)
            local actor = self:GetActor()
            local own, now = sense.root, sense.now or os.clock()
            if not actor or actor.ActorType ~= "Survivor" or not own or now < self.nextAction then return nil end
            local cfg, name = actor.Config or {}, actor.ActorName
            local profiles = {}
            local function add(ability, kind, range, need, gap, options)
                if not self:Ready(actor, ability, now) or now < (self.lastAttempt[ability] or -math.huge) + (gap or 0) then return end
                local p = options or {}
                p.ability, p.kind, p.range, p.need, p.gap = ability, kind, range, need, gap
                table.insert(profiles, p)
            end
            if name == "Elliot" then
                add("ThrowPizza", "support", 30, "injured", 30, {speed = value(cfg, "PizzaThrowForce", 60), face = true})
            elseif name == "Dusekkar" then
                -- PlasmaBeam grants speed and overhealth to a survivor. Protection's
                -- normal client selector also requires the ally under the screen cursor.
                add("SpawnProtection", "support", value(cfg, "SpawnProtectionEffectMaxDistance", 95), "pressured", 30, {screenTarget = true})
                add("PlasmaBeam", "support", value(cfg, "PlasmaBeamHitboxRange", 75), "either", nil, {speed = 200, face = true})
            elseif name == "Helperbot" then
                local pulseRadii = cfg.SonicPulse and cfg.SonicPulse.Radius
                local inspireRadii = cfg.Inspiration and cfg.Inspiration.Radius
                add("Pulse", "support", math.max(5, (type(pulseRadii) == "table" and pulseRadii[1] or 30) - 2), "either", 35, {area = true})
                add("Inspiration", "support", math.max(5, (type(inspireRadii) == "table" and inspireRadii[1] or 14) - 2), "pressured", 40, {area = true})
            elseif name == "Builderman" then
                -- Construction takes six seconds. Choose a safe rally point near an
                -- ally, never interrupt a chase to build directly beside the killer.
                add("Dispenser", "support", math.max(5, value(cfg, "DispenserHealingRadius", 16) - 4), "injured", 90,
                    {minDistance = 55, preferredDistance = 65, building = true, face = true})
                add("Sentry", "support", 24, "pressured", 90,
                    {minDistance = 55, preferredDistance = 65, building = true, face = true})
            elseif name == "Shedletsky" then
                add("Slash", "counterattack", 10.5, "pressured")
            elseif name == "Guest1337" then
                add("Punch", "counterattack", 9.5, "pressured")
                if sense.incomingAttack or (sense.killerModel and self:Threat(sense.killerModel)) then
                    add("Block", "counterattack", 14, "pressured", nil, {canCounterIncoming = true})
                end
            elseif name == "TwoTime" then
                add("Dagger", "counterattack", actor.Rig:GetAttribute("Crouching") and 22 or 8, "pressured")
            elseif name == "JaneDoe" then
                add("Axe", "counterattack", 9, "pressured")
            elseif name == "Chance" then
                local shoot = self:Abilities(actor).Shoot
                if shoot and (shoot.CurrentCharges or 0) >= 2 then
                    add("Shoot", "counterattack", math.min(value(cfg, "ShootHitboxRange", 90), 65), "pressured", nil,
                        {minDistance = 20, preferredDistance = 38, speed = 500})
                end
            end
            if #profiles == 0 then return nil end
            local allies, seen = {}, {}
            local function include(model)
                if model and model ~= actor.Rig and model.Parent and not seen[model] and isAlive(model) then
                    seen[model] = true
                    table.insert(allies, model)
                end
            end
            for _, model in ipairs(sense.survivors or {}) do include(model) end
            for _, other in pairs(self.actors and self.actors.CurrentActors or {}) do
                if other.ActorType == "Survivor" then include(other.Rig) end
            end
            local killers = sense.killers or (sense.killerModel and {sense.killerModel} or {})
            local best, bestScore
            for _, ally in ipairs(allies) do
                local allyRoot = rootOf(ally)
                local hum = ally:FindFirstChildOfClass("Humanoid")
                local distance = (allyRoot.Position - own.Position).Magnitude
                if distance <= 80 then
                    local injured = hum.MaxHealth - hum.Health >= 12
                    local pressureKiller, pressureRoot, pressureDistance
                    for _, killer in ipairs(killers) do
                        local kr = rootOf(killer)
                        if killer ~= ally and isAlive(killer) and kr then
                            local delta = horizontal(allyRoot.Position - kr.Position)
                            local kd = delta.Magnitude
                            local facing = kd < 0.1 or horizontal(kr.CFrame.LookVector):Dot(delta.Unit) > 0.15
                            local closing = kd > 0.1 and horizontal(kr.AssemblyLinearVelocity):Dot(delta.Unit) > 2
                            if kd < 38 and (facing or closing or kd < 14) and self:LOS(kr, allyRoot)
                                and (not pressureDistance or kd < pressureDistance) then
                                pressureKiller, pressureRoot, pressureDistance = killer, kr, kd
                            end
                        end
                    end
                    for index, p in ipairs(profiles) do
                        local needed = p.need == "injured" and injured or p.need == "pressured" and pressureRoot ~= nil
                            or p.need == "either" and (injured or pressureRoot ~= nil)
                        local kr, km = pressureRoot or sense.killerRoot, pressureKiller or sense.killerModel
                        local attackInReach = p.kind ~= "counterattack" or (kr and (kr.Position - own.Position).Magnitude <= 72)
                        local stable = not previous or (previous.allyModel == ally and previous.ability == p.ability
                            and (p.kind ~= "counterattack" or previous.killerModel == km))
                        if needed and attackInReach and stable and (not p.screenTarget or self:CanShield(allyRoot, cfg)) then
                            local score = (pressureRoot and 45 or 0) + (injured and 25 or 0) - distance * 0.4 - index * 3
                            if not bestScore or score > bestScore then
                                best = table.clone(p)
                                best.allyRoot, best.allyModel, best.killerRoot, best.killerModel = allyRoot, ally, kr, km
                                best.minDistance = p.minDistance or (p.kind == "support" and 20 or 3)
                                best.preferredDistance = p.preferredDistance or (p.kind == "support" and 36 or math.max(4, p.range - 2))
                                best.castSerial = self.actionSerial
                                bestScore = score
                            end
                        end
                    end
                end
            end
            return best
        end

        function Ability:CanShield(target, cfg)
            local camera = workspace.CurrentCamera
            if not camera or not target then return false end
            local ok, result = pcall(function()
                local point, onScreen = camera:WorldToViewportPoint(target.Position)
                if not onScreen then return false end
                local cursor = game:GetService("UserInputService"):GetMouseLocation()
                local radius = camera.ViewportSize.Y * value(cfg, "SpawnProtectionScaleRadius", 0.4)
                return (Vector2.new(point.X, point.Y) - cursor - Vector2.new(0, radius / 100)).Magnitude <= radius / 2
            end)
            return ok and result == true
        end

        function Ability:PerformAssist(sense, actor, own)
            local intent = sense.assistIntent
            if not intent or not isAlive(intent.allyModel) or not self:Ready(actor, intent.ability, sense.now) then return nil end
            local target = intent.kind == "counterattack" and intent.killerRoot or intent.allyRoot
            if not target or not target.Parent or (target.Position - own.Position).Magnitude > intent.range
                or not self:LOS(own, target) then return nil end
            if intent.kind == "counterattack" and self:IsBlocking(target.Parent) then return nil end
            -- Recheck spacing at cast time; the killer may have moved during approach.
            if intent.kind == "support" and (sense.killerDistance or math.huge) < intent.minDistance then return nil end
            if intent.screenTarget and not self:CanShield(target, actor.Config) then return nil end
            if intent.kind == "counterattack" or intent.face then
                self:Aim(target, 2.5, intent.speed)
                local direction = horizontal(target.Position - own.Position)
                if direction.Magnitude > 0.1 and horizontal(own.CFrame.LookVector):Dot(direction.Unit) < 0.55 then
                    if self.ctx.face then pcall(self.ctx.face, target, 0.65) end
                    return nil
                end
            end
            if self:Use(actor, intent.ability, sense, target, nil, intent.gap, intent.speed) then return self.lastAction end
            return nil
        end

        function Ability:Update(sense)
            if self.destroyed then return nil end
            local now = sense.now or os.clock()
            for name, held in pairs(self.held) do
                if now >= held.releaseAt then
                    if held.actor.HeldAbilities then held.actor.HeldAbilities[name] = nil end
                    self.held[name] = nil
                end
            end
            local actor = self:GetActor()
            local own = sense.root or rootOf(actor and actor.Rig)
            local hum = sense.humanoid or (actor and actor.Rig and actor.Rig:FindFirstChildOfClass("Humanoid"))
            if not actor or not own or not hum or hum.Health <= 0 then self:_ClearAttackFacing(); return nil end
            self:_UpdateNative(sense, actor)
            if self:_UpdateNoli(sense, actor) then return self.lastActionRecord and self.lastActionRecord.time == now and self.lastAction or nil end
            if actor.ActorName == "Guest1337" and sense.killerRoot and self:GetDefenseState(actor.Rig).parry then
                if not self.guestParryUsed and (sense.killerRoot.Position - own.Position).Magnitude <= 12
                    and self:LOS(own, sense.killerRoot) and self:Use(actor, "Punch", sense, sense.killerRoot) then
                    self.guestParryUsed = true
                    return self.lastAction
                end
            else self.guestParryUsed = nil end
            local pending = self.sequence and self:_PlanSequence(sense)
            if pending and pending.cancelled and self:_UpdateSequence(sense, actor, own) then return nil end
            if now < self.nextAction then return nil end
            if self:_UpdateSequence(sense, actor, own) then return self.lastActionRecord and self.lastActionRecord.time == now and self.lastAction or nil end
            if self:MovementLocked() then return nil end
            -- A new dash/channel can lock movement and erase the selected sidestep.
            -- Lifecycle work above still runs, and Guest may answer an actual threat
            -- with Block or its server-confirmed parry instead.
            if sense.evading and actor.ActorName ~= "Guest1337" then return nil end
            if not sense.evading and sense.assisting and sense.assistIntent then
                -- A support approach reserves its intended action rather than spending
                -- it on an unrelated automatic attack or self-heal on the same tick.
                return self:PerformAssist(sense, actor, own)
            end
            local cfg = actor.Config or {}
            local name = actor.ActorName
            local isKiller = actor.ActorType and actor.ActorType:find("Killer") ~= nil
            local target = isKiller and sense.targetRoot or sense.killerRoot
            local distance = target and (target.Position - own.Position).Magnitude or math.huge
            local visible = target and self:LOS(own, target)
            local hp = hum.Health / math.max(hum.MaxHealth, 1)
            local fleeing = sense.fleeing == true
            local safe = distance > 65 and not fleeing
            local function use(ability, aimRoot, hold, gap, speed)
                return self:Use(actor, ability, sense, aimRoot, hold, gap, speed)
            end
            local function attack(ability, range, hold, gap, speed)
                if not self:Ready(actor, ability, now) then return false end
                if not target or distance > range or not visible then return false end
                if self:IsBlocking(target.Parent) then return false end
                self:Aim(target, 2.5, speed)
                local direction = horizontal(target.Position - own.Position)
                if direction.Magnitude > 0.1 and horizontal(own.CFrame.LookVector):Dot(direction.Unit) < 0.55 then
                    if self.ctx.face then pcall(self.ctx.face, target, 0.65) end
                    return false
                end
                return use(ability, target, hold, gap, speed)
            end
            if isKiller and sense.structureTarget then
                local structure = sense.structureTarget
                local objectRoot = structure.targetRoot or structure.root
                if objectRoot and objectRoot.Parent and (objectRoot.Position - own.Position).Magnitude <= 7.1 and self:LOS(own, objectRoot) then
                    for ability, definition in pairs(self:Abilities(actor)) do
                        if definition.KeybindType == "MainAbility" and containsAny(ability, meleeWords) and self:Ready(actor, ability, now) then
                            -- Tripwires need not have a Humanoid. Aim at their physical
                            -- root and request only the normal primary melee hitbox.
                            self:AimPoint(objectRoot.Position, 0.7)
                            self:_TrackAttackPoint(objectRoot.Position, self:Windup(actor, ability) + 0.4)
                            if use(ability, nil, ability == "Carving Slash" and 0.3 or nil) then return self.lastAction end
                        end
                    end
                end
                return nil
            end
            local function sowBulb()
                if not target or distance > 65 or not self:Ready(actor, "Sow", now) then return false end
                local toward = horizontal(target.Position - own.Position)
                if toward.Magnitude < 0.1 then return false end
                local reach = nested(cfg, "Sow", "Range", 12)
                local p = own.Position + toward.Unit * math.max(3, reach - 1)
                local params = RaycastParams.new()
                params.FilterType, params.RespectCanCollide = Enum.RaycastFilterType.Exclude, true
                params.FilterDescendantsInstances = {actor.Rig, target.Parent}
                local floor = workspace:Raycast(p + Vector3.new(0, 2, 0), Vector3.new(0, -10, 0), params)
                if not floor or floor.Normal.Y < 0.5 then return false end
                self:AimPoint(floor.Position, 1.4)
                if self.ctx.cameraAim then pcall(self.ctx.cameraAim, floor.Position, 1) end
                return use("Sow", nil, nil, 10)
            end
            local acted = false
            if isKiller then
                if target and self:IsBlocking(target.Parent) then return nil end
                -- Primary attacks are discovered at runtime, including skin substitutions.
                for ability, def in pairs(self:Abilities(actor)) do
                    if def.KeybindType == "MainAbility" and containsAny(ability, meleeWords) then
                        if attack(ability, 7.1, ability == "Carving Slash" and 0.3 or nil) then acted = true break end
                    end
                end
                if not acted and target then
                    if name == "Slasher" or name == "SlasherSwift" or name == "Jason" or name == "!Slasher_FRIDAY" then
                        acted = attack("Behead", 9) or attack("GashingWound", 6.5)
                            or (distance > 40 and use("RagingPace", target, nil, 25))
                    elseif name == "c00lkidd" or name == "Irisc00lkiddOverhaul" then
                        acted = attack("CorruptNature", 110, nil, nil, value(cfg, "CorruptNatureSpeed", 100))
                            or (distance > 18 and distance < 90 and visible and use("WalkspeedOverride", target, 0.3))
                            or (distance > 20 and use("PizzaDelivery", target, nil, 15))
                    elseif name == "JohnDoe" or name == "!JohnDoe_MARCH" then
                        acted = attack("CorruptEnergy", 60) or (distance < 50 and distance > 13 and use("DigitalFootprint", target, nil, 18))
                            or (distance > 75 and use("404Error", nil, nil, 20))
                    elseif name == "1x1x1x1" then
                        acted = attack("Entanglement", 100, nil, nil, value(cfg, "EntanglementProjectileSpeed", 125))
                            or attack("MassInfection", 80) or (distance > 35 and use("UnstableEye", nil, nil, 20))
                            or (distance > 15 and use("RejuvenateTheRotten", nil, nil, 30))
                    elseif name == "Noli" or name == "#NoliRacing" then
                        acted = attack("Nova", 100, nil, nil, value(cfg, "NovaProjectileSpeed", 80))
                            or (distance > 22 and distance < 100 and visible
                                and use("VoidRush", target, value(cfg, "VoidRushChargeLength", 1) + value(cfg, "VoidRushDashLength", 3.5) + 0.3))
                            or (distance > 80 and use("Observant", nil, nil, 25))
                    elseif name == "Sixer" or name == "#SixerHunt" then
                        local hold = cfg.PursuitHold and cfg.PursuitHold.Max or 1.25
                        acted = attack("InfernalCry", 32) or (distance > 20 and distance < 100 and visible
                            and use("DemonicPursuit", target, hold)) or (distance > 35 and use("BloodHunt", nil, nil, 30))
                    elseif name == "Azure" then
                        local golems = actor.State and actor.State.Golems
                        local hasGolem = type(golems) == "table" and next(golems) ~= nil
                        local controlling = actor.State and actor.State.ControllingGolem
                        local oblation = actor.Rig:GetAttribute("Oblation") or 0
                        acted = (not controlling and distance > 18 and (hasGolem or oblation >= nested(cfg, "Oblation", "Max", 15))
                                and use("Unravel", nil, nil, hasGolem and nested(cfg, "Golem", "TransferCooldown", 2.5) or 12))
                            or (controlling and attack("Sow", nested(cfg, "GolemShockwave", "Radius", 17)))
                            or (not controlling and attack("Grab", nested(cfg, "Grab", "HookRange", 60), nil, nil, nested(cfg, "Grab", "HookSpeed", 270)))
                            or (not controlling and sowBulb()) or attack("Blossom", 35)
                    elseif name == "Nosferatu" or name == "#Nosferatwo" then
                        local ascent = self:Abilities(actor).Ascent
                        local ascentCharged = ascent and (ascent.CurrentCharges == nil or ascent.CurrentCharges > 0)
                        acted = attack("Uppercut", nested(cfg, "Uppercut", "WeakDistance", 24))
                            or attack("Spire", 35) or attack("Bats", 90, nil, nil, nested(cfg, "Bats", "ProjectileSpeed", 30))
                            or (distance > 30 and distance < 85 and ascentCharged and use("Ascent", target, nil, 25))
                    elseif name == "ShedletskyFunny" then
                        acted = attack("Lunge", 28) or attack("Launch", 25) or attack("DinnerBlast", 100, nil, nil, 250)
                    elseif name == "!Brimstone" then
                        acted = attack("Fire", 22) or attack("BURN", 15) or attack("Ashes", 65)
                            or (distance > 18 and distance < 70 and attack("Dash", 70))
                    elseif name == "!SukunaKiller" then
                        acted = attack("Cleave", 12) or attack("Dismantle", 90) or attack("MalShrine", 35, nil, 190)
                    elseif name == "!Cat" then
                        acted = attack("ColtPython", value(cfg, "ShootHitboxRange", 90), nil, nil, 500)
                    elseif name == "!Horse" then
                        acted = attack("WalkspeedOverride", 100)
                    elseif name == "!Fog" then
                        acted = distance > 15 and use("Vanish", nil, nil, 20)
                    elseif name == "!DoppelgangerShedletsky" then
                        acted = (hp < 0.7 and distance > 45 and use("FriedChicken", nil, nil, 45))
                            or (distance > 25 and use("Vanish", nil, nil, 20))
                    else
                        -- Specials have different state machines. Only their known ordinary
                        -- primary attack is requested above; no guessed ability packets.
                        acted = false
                    end
                end
            else
                if name == "Noob" or name == "!NoobTheWorld" then
                    acted = (fleeing and distance > 15 and distance < 65 and use("BloxyCola", nil, nil, 35))
                        or (fleeing and hp < 0.55 and distance < 15 and use("SlateskinPotion", nil, nil, 35))
                        or (fleeing and distance > 30 and use("Ghostburger", nil, nil, 30))
                        or (name == "!NoobTheWorld" and fleeing and distance < 25 and use("Timestop", nil, nil, 20))
                elseif name == "Shedletsky" then
                    acted = attack("Slash", 10.5) or (safe and hp < 0.72 and use("FriedChicken", nil, nil, 60))
                elseif name == "007n7" then
                    local inject = self:Abilities(actor).Inject
                    local mode = inject and string.lower(inject.FlavorText or "") or ""
                    acted = (distance > 35 and inject and not mode:find("pathfind", 1, true) and use("Inject", nil, nil, 2))
                        or (fleeing and distance < 55 and use("Clone", nil, nil, 25))
                        or (fleeing and distance > 80 and use("c00lgui", nil, nil, 50))
                elseif name == "Guest1337" then
                    local incoming = self:_GuestIncoming(sense)
                    local parry = self:GetDefenseState(actor.Rig).parry
                    acted = (parry and not self.guestParryUsed and attack("Punch", 12))
                        or (incoming and distance <= 20 and use("Block", nil, nil, value(cfg, "BlockDuration", 1) + 0.3))
                        or (not parry and not sense.evading and (not self.guestBlockUntil or now > self.guestBlockUntil) and attack("Punch", 9.5))
                        or (not sense.evading and fleeing and distance > 10 and distance < 24 and attack("Charge", 24))
                elseif name == "Chance" then
                    local shoot = self:Abilities(actor).Shoot
                    local charges = shoot and (shoot.CurrentCharges or 0) or 0
                    acted = (charges >= 2 and attack("Shoot", math.min(value(cfg, "ShootHitboxRange", 90), 65), nil, nil, 500))
                        or (safe and hp < 0.45 and use("Reroll", nil, nil, 20))
                        or (safe and self:HasStatus(actor.Rig, "Weakness") and use("HatFix", nil, nil, 50))
                        or (distance > 35 and charges < 3 and use("CoinFlip", nil, nil, 2.2))
                elseif name == "TwoTime" then
                    acted = (safe and hp < 0.75 and actor.isCompletedWithBlood and use("Pray", nil, math.min(10, value(cfg, "PrayFullConversionTime", 10)), 15))
                        or attack("Dagger", 8)
                        or (safe and not actor.Rig:GetAttribute("RitualOrigin") and use("Ritual", nil, nil, 60))
                elseif name == "Taph" then
                    -- Mines need arming time and can hit their owner. Place while safe.
                    acted = (safe and use("SubspaceTripmine", nil, nil, 45))
                elseif name == "Builderman" then
                    -- Avoid endlessly replacing active buildings (base cooldown is zero).
                    local carrying = actor.CarryingBuilding
                    local highlight = actor.CarryableBuildingHighlight
                    local building = highlight and highlight.Adornee
                    local bh = building and building:FindFirstChildOfClass("Humanoid")
                    acted = (carrying ~= nil and safe and self.carryGoal and horizontal(own.Position - self.carryGoal).Magnitude < 3 and use("Move", nil, nil, 2))
                        or (safe and bh and bh.Health < bh.MaxHealth * 0.5 and use("Move", nil, nil, 8))
                        or (not carrying and safe and use("Sentry", nil, nil, 90))
                        or (not carrying and safe and hp < 0.8 and use("Dispenser", nil, nil, 90))
                elseif name == "Elliot" then
                    local teammate = self:Teammate(actor, own, 30, true)
                    acted = (fleeing and use("RushHour", nil, nil, 25))
                        or (teammate ~= nil and not fleeing and use("ThrowPizza", teammate, nil, 30, value(cfg, "PizzaThrowForce", 60)))
                elseif name == "Dusekkar" then
                    local teammate = self:Teammate(actor, own, value(cfg, "SpawnProtectionEffectMaxDistance", 95), false)
                    acted = (teammate ~= nil and distance < 60 and not fleeing and self:CanShield(teammate, cfg) and use("SpawnProtection", teammate, nil, 30))
                        or attack("PlasmaBeam", value(cfg, "PlasmaBeamHitboxRange", 75), nil, nil, 200)
                elseif name == "Helperbot" then
                    local teammate = self:Teammate(actor, own, 30, true)
                    acted = ((distance < 32 or teammate ~= nil) and use("Pulse", nil, nil, 35))
                        or (safe and self:Teammate(actor, own, 28, false) ~= nil and use("Inspiration", nil, nil, 40))
                elseif name == "JaneDoe" then
                    local fraction = math.clamp(distance / 120, 0.3, 0.8)
                    local crystalHold = nested(cfg, "Crystal", "ChannelTime", 0.2) + nested(cfg, "Crystal", "MaxChargeTime", 2) * fraction + 0.1
                    local crystalSpeed = nested(cfg, "Crystal", "MinSpeed", 35)
                        + (nested(cfg, "Crystal", "MaxSpeed", 250) - nested(cfg, "Crystal", "MinSpeed", 35)) * fraction
                    acted = attack("Axe", 9)
                        or (distance > 22 and distance < 90 and visible and not self:_Danger(sense)
                            and not (actor.State and actor.State.KillerCrystalDisabled)
                            and use("Crystal", target, crystalHold, nil, crystalSpeed))
                elseif name == "Veeronica" then
                    local battery = actor.Rig:GetAttribute("BatteryPercent")
                    local channel = actor.Meta and actor.Meta.CurrentChannel
                    local canSkate = (not self.ctx.settings or self.ctx.settings.CharacterCombos ~= false)
                        and actor.State and (actor.State.InZone or actor.State.ClosestSpray)
                    acted = (safe and hp < 0.82 and type(battery) == "number" and battery > 0 and use("ActivateBattery", nil, nil, 30))
                        or (fleeing and canSkate and channel ~= 1 and use("Broadcast", nil, nil, 0.6))
                        or (fleeing and canSkate and channel == 1 and self:_NativeControls(actor) ~= nil and use("Sk8", nil, nil, 5))
                elseif name == "#MArtist" then
                    acted = attack("SuperDeathKillCombo", 12) or attack("Combo", 10) or attack("QuickAttack", 8)
                elseif name == "#SWATOfficer" then
                    acted = fleeing and attack("Flashbang", 35)
                elseif name == "1xFunny" then
                    acted = attack("Entanglement", 75) or (distance > 35 and use("UnstableEye", nil, nil, 25))
                elseif name == "JohnDoeFunny" then
                    acted = attack("CorruptEnergy", 65, 1.5) or (fleeing and distance < 50 and use("DigitalFootprint", nil, nil, 28))
                elseif name == "c00lkiddFunny" then
                    acted = (fleeing and use("WalkspeedOverride", target, nil, 2))
                        or (distance < 65 and use("PizzaDelivery", target, nil, 10))
                        or (safe and actor.State and next(actor.State.ActiveRobots or {}) and use("c00lgui", nil, nil, 30))
                end
            end
            return acted and self.lastAction or nil
        end

        function Ability:Maintain(sense)
            -- Repair and item-use phases must not start combat actions, but they still
            -- release adapter-owned input and finish pending normal mode exits.
            local now = sense.now or os.clock()
            self:_ClearAttackFacing()
            for name, held in pairs(self.held) do
                if held.actor.HeldAbilities then held.actor.HeldAbilities[name] = nil end
                self.held[name] = nil
            end
            for key in pairs(self.inputReleases) do
                if self.ctx.input and self.ctx.input.SetKey then pcall(self.ctx.input.SetKey, self.ctx.input, key, false) end
                self.inputReleases[key] = nil
            end
            self:_RestoreNativeInput()
            self.nativeSteerGoal = nil
            local actor = self:GetActor()
            if self.sequence then
                self.sequence.cancelled = true
                if actor then self:_UpdateSequence(sense, actor, sense.root)
                else self.sequence = nil end
            end
            if self.skateOwned == actor and actor and actor.State and actor.State.isSkating and not self.stoppingSkate then
                actor.HeldAbilities = actor.HeldAbilities or {}
                actor.HeldAbilities.Sk8 = true
                self.stoppingSkate = true
            end
            if now >= self.aimUntil then self.aimRoot, self.aimPosition, self.faceCast = nil, nil, nil end
        end

        function Ability:Reset()
            self:_ClearAttackFacing()
            local sequence = self.sequence
            local sameActor = sequence and sequence.actor == self:GetActor()
            if sameActor and sequence.kind == "Graffiti" then
                self:_SprayInput(sequence.actor, "Idle")
                if sequence.actor.State and sequence.actor.State.SprayState then self:Use(sequence.actor, "Vandalism", {now = os.clock()}) end
            end
            if sameActor and sequence.ownedCrouch and sequence.actor.Rig:GetAttribute("Crouching") then
                self:Use(sequence.actor, "Crouch", {now = os.clock()})
            end
            for key in pairs(self.inputReleases) do
                if self.ctx.input and self.ctx.input.SetKey then pcall(self.ctx.input.SetKey, self.ctx.input, key, false) end
            end
            table.clear(self.inputReleases)
            self:_RestoreNativeInput()
            for name, held in pairs(self.held) do
                if held.actor.HeldAbilities then held.actor.HeldAbilities[name] = nil end
            end
            table.clear(self.held)
            local skatingActor = self.skateOwned
            if skatingActor and skatingActor.State and skatingActor.State.isSkating then
                -- The native skate controller treats another held Sk8 press as stop.
                skatingActor.HeldAbilities = skatingActor.HeldAbilities or {}
                skatingActor.HeldAbilities.Sk8 = true
            end
            self.skateOwned = nil
            table.clear(self.lastAttempt)
            self.aimRoot = nil
            self.aimPosition, self.faceCast, self.sequence = nil, nil, nil
            self.nativeControlUntil, self.stoppingSkate = 0, nil
            self.noliCombo, self.noliHitUI, self.noliHitCounter, self.noliWasRushing = nil, nil, nil, nil
            self.guestParryUsed, self.corruptSteerUntil, self.graffitiEscape, self.nextGraffitiEscape = nil, nil, nil, nil
            self.azureHeldAt, self.azureHeldRoot, self.azureThrowPoint = nil, nil, nil
            self.aimUntil = 0
            self.nextAction = 0
        end

        function Ability:Destroy()
            self:Reset()
            self.destroyed = true
            if self.mouse then
                if self.mouse.GetMousePos == self.mouseWrapper then self.mouse.GetMousePos = self.originalMouse end
                if self.mouse.GetCameraCFrame == self.cameraWrapper then self.mouse.GetCameraCFrame = self.originalCamera end
            end
        end

        return Ability

        end)()


        -- Generator adapter for the inspected Place_83645629621104 snapshot.
        -- Uses the game's existing binder and FlowInput, including its normal validation
        -- and OnSolved callback. No completion flags or puzzle counters are changed.
        local function solveFlow(size, pairs, cancelled, budget)
            if cancelled() then return nil, "Flow search cancelled" end
            if type(size) ~= "number" or size < 2 or size > 12 then
                return nil, "Unsupported Flow grid size"
            end
            local count = size * size
            local neighbors, endpoints, occupied, done, paths = {}, {}, {}, {}, {}
            local pairCount = 0
            for cell = 1, count do
                local row, col = math.floor((cell - 1) / size) + 1, (cell - 1) % size + 1
                local list = {}
                if row > 1 then table.insert(list, cell - size) end
                if col > 1 then table.insert(list, cell - 1) end
                if row < size then table.insert(list, cell + size) end
                if col < size then table.insert(list, cell + 1) end
                neighbors[cell] = list
            end
            for color, pair in pairs do
                if type(pair) ~= "table" or #pair ~= 2 then return nil, "Invalid Flow pair" end
                for _, cell in pair do
                    if type(cell) ~= "number" or cell % 1 ~= 0 or cell < 1 or cell > count
                        or endpoints[cell] ~= nil then
                        return nil, "Invalid or overlapping Flow endpoints"
                    end
                    endpoints[cell] = color
                end
                pairCount += 1
            end
            if pairCount == 0 then return nil, "Flow board is not ready" end

            local deadline = os.clock() + (budget or 8)
            local nodes, expired = 0, false
            local function checkBudget()
                nodes += 1
                if nodes == 1 or nodes % 600 == 0 then
                    task.wait()
                    expired = cancelled() or os.clock() > deadline or nodes > 1000000
                end
                return not expired
            end
            local function passable(cell, color, start, goal)
                return cell == start or cell == goal
                    or (occupied[cell] == nil and endpoints[cell] == nil)
            end
            -- Breadth-first reachability both prunes impossible branches and orders the
            -- remaining pairs by how few usable cells they have.
            local function distances(color, start, goal)
                local distance = {[goal] = 0}
                local queue, first = {goal}, 1
                while first <= #queue do
                    local cell = queue[first]
                    first += 1
                    for _, nextCell in neighbors[cell] do
                        if distance[nextCell] == nil and passable(nextCell, color, start, goal) then
                            distance[nextCell] = distance[cell] + 1
                            table.insert(queue, nextCell)
                        end
                    end
                end
                return distance, #queue
            end
            local connectNext
            connectNext = function(remaining)
                if remaining == 0 then return true end
                if not checkBudget() then return false end
                local selected, bestScore
                for color, pair in pairs do
                    if not done[color] then
                        local distance, area = distances(color, pair[1], pair[2])
                        if distance[pair[1]] == nil then return false end
                        local exits = 0
                        for _, cell in neighbors[pair[1]] do
                            if passable(cell, color, pair[1], pair[2]) then exits += 1 end
                        end
                        local score = exits * 1000 + area - distance[pair[1]]
                        if bestScore == nil or score < bestScore then selected, bestScore = color, score end
                    end
                end
                local pair = pairs[selected]
                local start, goal = pair[1], pair[2]
                local path = {start}
                occupied[start] = selected
                local walk
                walk = function(head)
                    if not checkBudget() then return false end
                    if head == goal then
                        done[selected], paths[selected] = true, table.clone(path)
                        if connectNext(remaining - 1) then return true end
                        done[selected], paths[selected] = nil, nil
                        return false
                    end
                    local distance = distances(selected, head, goal)
                    if distance[head] == nil then return false end
                    -- Every unfinished color must still have a route around this wire.
                    for color, other in pairs do
                        if color ~= selected and not done[color] then
                            local reach = distances(color, other[1], other[2])
                            if reach[other[1]] == nil then return false end
                        end
                    end
                    local choices = {}
                    for _, cell in neighbors[head] do
                        if occupied[cell] == nil and (endpoints[cell] == nil or cell == goal)
                            and distance[cell] ~= nil then table.insert(choices, cell) end
                    end
                    table.sort(choices, function(a, b)
                        if distance[a] == distance[b] then return a < b end
                        return distance[a] < distance[b]
                    end)
                    for _, cell in choices do
                        occupied[cell] = selected
                        table.insert(path, cell)
                        if walk(cell) then return true end
                        path[#path] = nil
                        occupied[cell] = nil
                        if expired then return false end
                    end
                    return false
                end
                if walk(start) then return true end
                occupied[start] = nil
                return false
            end
            if connectNext(pairCount) then return paths end
            return nil, expired and "Flow search timed out; will retry" or "No non-overlapping Flow solution found"
        end

        local function generatorWait(seconds, cancelled)
            local finish = os.clock() + seconds
            repeat
                if cancelled() then return false end
                task.wait(math.min(0.035, math.max(0.01, finish - os.clock())))
            until os.clock() >= finish
            return not cancelled()
        end

        local function drawConnectPuzzle(session, cancelled)
            local input, renderer = session.__input, session.__renderer
            local board = input and input.Board
            if not board or not renderer then return false, "Connect UI is not ready" end
            for index in ipairs(board.Blobs) do
                if cancelled() then return false, "Cancelled" end
                if not board:GetLink(index) then
                    local mate = board:GetMate(index)
                    if not mate or mate == index or board:GetColor(index) ~= board:GetColor(mate) then
                        return false, "Connect board has an unmatched square"
                    end
                    local from = renderer:ScreenCenter(index)
                    local target = renderer:ScreenCenter(mate)
                    input:__begin(index, from)
                    if input.Dragging ~= index then return false, "Connect drag did not begin" end
                    for step = 1, 10 do
                        if cancelled() then return false, "Cancelled" end
                        from = renderer:ScreenCenter(index)
                        target = renderer:ScreenCenter(mate)
                        input:__drag(from:Lerp(target, step / 10))
                        if not generatorWait(0.035, cancelled) then return false, "Cancelled" end
                    end
                    input:__release(renderer:ScreenCenter(mate))
                    if not board:GetLink(index) then return false, "Connect square did not attach" end
                    if board:IsSolved() then return true, "Connect submitted; waiting for server" end
                    if not generatorWait(0.1, cancelled) then return false, "Cancelled" end
                end
            end
            return board:IsSolved(), "Connect submitted; waiting for server"
        end

        local function turnGearPuzzle(session, cancelled)
            if session.__spunAt then return true, "Gear turned; waiting for server" end
            local input, renderer = session.__input, session.__renderer
            if not input or not renderer then return false, "Gear UI is not ready" end
            -- Present waits 0.45s, then flies the Gear for 0.6s before the ordinary
            -- OnTurn callback accepts input. Never change the present/cast state.
            if not generatorWait(1.15, cancelled) then return false, "Cancelled" end
            local presentationDeadline = os.clock() + 3
            while renderer.__flight do
                if cancelled() or os.clock() > presentationDeadline then return false, "Gear presentation did not finish" end
                task.wait(0.035)
            end
            local turns = session.Network.Properties:Get("Turns")
            turns = type(turns) == "number" and math.clamp(turns, 1, 30) or 6
            local steps = math.ceil(turns * 24)
            for step = 0, steps + 24 do
                if cancelled() then return false, "Cancelled" end
                if session.__spunAt then return true, "Gear turned; waiting for server" end
                local center = renderer:GetCenter()
                local size = renderer.CenterGear and renderer.CenterGear.AbsoluteSize
                local radius = math.clamp(size and size.X * 0.35 or 48, 24, 90)
                local angle = math.rad(step * 15)
                -- Screen Y increases downward; increasing angle is clockwise. The
                -- existing input object derives <=15 degree deltas from these points.
                input:__onPointer(center + Vector2.new(math.cos(angle), math.sin(angle)) * radius)
                if not generatorWait(0.03, cancelled) then return false, "Cancelled" end
            end
            return session.__spunAt ~= nil, "Gear did not accept a full clockwise turn sequence"
        end

        local function pressLockPuzzle(session, cancelled)
            local input = session.__input
            local board = session.__renderer and session.__renderer.Board
            if not input or not board then return false, "Lock UI is not ready" end
            local config = board.Config
            if type(config.Speed) ~= "number" or config.Speed <= 0 then return false, "Lock speed is unavailable" end
            local duration = math.clamp((tonumber(config.Hits) or 5) * 360 / config.Speed + 8, 12, 90)
            local finish = os.clock() + duration
            while not board:IsBroken() do
                if cancelled() then return false, "Cancelled" end
                if os.clock() > finish then return false, "Lock timing search timed out" end
                local now = workspace:GetServerTimeNow()
                if now >= config.StartTime then
                    local angle = board:AngleAt(now)
                    local difference = (angle - board.State.Target + 180) % 360 - 180
                    local innerWindow = math.max(2, (tonumber(config.TargetSize) or 12) * 0.3)
                    if math.abs(difference) <= innerWindow and board:IsOnTarget(angle) then
                        -- __press invokes the game's normal Board:Press(actual server
                        -- time), animation and network request. No fabricated timestamp.
                        input:__press()
                        if not board:IsBroken() and not generatorWait(0.06, cancelled) then return false, "Cancelled" end
                    end
                end
                task.wait(0.01)
            end
            return true, "Lock submitted; waiting for server"
        end

        local function createGenerators(ctx)
            local rs = game:GetService("ReplicatedStorage")
            local player = ctx.player or game:GetService("Players").LocalPlayer
            local binderClass, flowBoard
            local puzzleClasses = {}
            local errorText
            local adapter = {Available = false, Status = "Loading generator modules"}
            local epoch, activeModel, workerSession = 0, nil, nil
            local retryAt, enterAt, enterStartedAt, solving, destroyed = 0, 0, 0, false, false
            local unavailableUntil = setmetatable({}, {__mode = "k"})
            local puzzleFailures = setmetatable({}, {__mode = "k"})
            local activeBinder
            local function getRoot(value)
                if typeof(value) ~= "Instance" then
                    return type(value) == "table" and (value.root or value.Root) or nil
                end
                if value:IsA("BasePart") then return value end
                return value:FindFirstChild("HumanoidRootPart") or value.PrimaryPart
            end
            local function binder(model)
                return binderClass and model and binderClass:FromInstance(model)
            end
            local function puzzleKind(model)
                local puzzle = model:GetAttribute("Puzzle")
                if puzzle == nil or puzzle == "" then return "Flow" end
                if type(puzzle) ~= "string" then return nil end
                puzzle = string.lower(puzzle)
                for _, kind in ipairs({"Flow", "Connect", "Gear", "Lock"}) do
                    if string.find(puzzle, string.lower(kind), 1, true) then return kind end
                end
                return nil
            end
            local function property(bound, key, fallback)
                if not bound then return fallback end
                local success, value = pcall(function() return bound.Network.Properties:Get(key) end)
                if success and value ~= nil then return value end
                return fallback
            end
            local function complete(bound)
                if property(bound, "Completed", false) == true then return true end
                -- The verified replicated counters drive the native generator progress
                -- bar; a full counter is final even if Completed replicates one tick later.
                local counter, maximum = property(bound, "Counter", nil), property(bound, "MaxCounter", nil)
                return type(counter) == "number" and type(maximum) == "number" and maximum > 0 and counter >= maximum
            end
            local function gearCount()
                local ok, value = pcall(function() return player:GetAttribute("Gears") end)
                return ok and type(value) == "number" and math.max(0, value) or 0
            end
            local function occupiedByMe(bound)
                for _, userId in property(bound, "Occupants", {}) do
                    if userId == player.UserId then return true end
                end
                return bound and bound.__sitting ~= nil or false
            end
            local function runningPuzzle()
                -- Minigame_Client stores its live session table under this ordinary key.
                -- Read existing sessions; never create a session or alter its lifecycle.
                for _, kind in ipairs({"Flow", "Connect", "Gear", "Lock"}) do
                    for key, value in pairs(puzzleClasses[kind] or {}) do
                        if tostring(key) == "MinigameKey(Running)" and type(value) == "table" then
                            for _, session in pairs(value) do
                                local input = session.__input
                                if input and not input.Ended and property(session, "FixerUserId", 0) == player.UserId then
                                    return session, kind
                                end
                            end
                        end
                    end
                end
                return nil
            end
            local function promptFor(model, bound)
                local main = model:FindFirstChild("Main")
                return bound and bound.__prompt or main and main:FindFirstChildOfClass("ProximityPrompt"), main
            end
            local function clearApproach(character, model, from, goal)
                local delta = goal - from
                if delta.Magnitude < 0.05 then return true end
                local params = RaycastParams.new()
                params.FilterType, params.RespectCanCollide = Enum.RaycastFilterType.Exclude, true
                local exclusions = {}
                if character then table.insert(exclusions, character) end
                local actors = workspace:FindFirstChild("Players")
                if actors then table.insert(exclusions, actors) end
                local positions = model:FindFirstChild("Positions")
                if positions then table.insert(exclusions, positions) end
                params.FilterDescendantsInstances = exclusions
                -- Check the actual approach to the free work position, even though the
                -- game's broad prompt does not require camera line of sight.
                return workspace:Raycast(from, delta, params) == nil
            end
            local function seatGoal(model)
                local root = getRoot(player.Character)
                local bound, best, bestDistance = binder(model), nil, math.huge
                local occupants = property(bound, "Occupants", {})
                local positions = model:FindFirstChild("Positions")
                if positions then
                    for _, position in positions:GetChildren() do
                        if position:IsA("BasePart") and (occupants[position.Name] == nil
                            or occupants[position.Name] == 0 or occupants[position.Name] == player.UserId) then
                            local distance = root and (root.Position - position.Position).Magnitude or 0
                            if distance < bestDistance then best, bestDistance = position.Position, distance end
                        end
                    end
                end
                return best -- No free work side must never fall back to the machine's center.
            end
            local function canEnter(model, bound, character, root, goal)
                local prompt, main = promptFor(model, bound)
                if not prompt or not main then return false, "Waiting for generator prompt" end
                if prompt.Enabled == false or (tonumber(prompt.MaxActivationDistance) or 0) <= 0 then
                    return false, "Generator prompt unavailable"
                end
                local delta = root.Position - goal
                if math.sqrt(delta.X * delta.X + delta.Z * delta.Z) > 2.25 or math.abs(delta.Y) > 2.5 then
                    return false, "Approaching generator work position"
                end
                if (root.Position - main.Position).Magnitude > math.max(0, prompt.MaxActivationDistance - 0.1) then
                    return false, "Approaching generator prompt"
                end
                if not clearApproach(character, model, root.Position, goal) then return false, "Approaching clear generator side" end
                return true
            end
            function adapter:GetStatus(model)
                if destroyed then return "Stopped" end
                if not self.Available then return "Loading" end
                if not model or not model.Parent or not model:IsDescendantOf(workspace) then return "Missing" end
                local bound = binder(model)
                if not bound then return "Waiting for binder" end
                if complete(bound) then return "Complete" end
                local kind = puzzleKind(model)
                if not kind or not puzzleClasses[kind] then return "Unsupported puzzle" end
                if (unavailableUntil[model] or 0) > os.clock() then return "Retry delay" end
                if kind == "Gear" and gearCount() < 1 then return "Needs gear" end
                if occupiedByMe(bound) then return "Repairing" end
                local prompt = promptFor(model, bound)
                if not prompt then return "Waiting for generator prompt" end
                if prompt.Enabled == false or (tonumber(prompt.MaxActivationDistance) or 0) <= 0 then return "Generator prompt unavailable" end
                if not seatGoal(model) then return "Occupied" end
                return "Available"
            end
            local banned = setmetatable({}, {__mode = "k"})
            function adapter:Ban(model, seconds)
                if model then banned[model] = os.clock() + (tonumber(seconds) or 25) end
            end
            function adapter:Find(root, killers)
                if destroyed or not self.Available then return nil end
                local position = typeof(root) == "Vector3" and root or root and root.Position
                if not position then return nil end
                local best, bestScore = nil, math.huge
                for model, bound in pairs(binderClass:GetAll()) do
                    if self:IsAvailable(model) and not (banned[model] and banned[model] > os.clock()) then
                        local goal = self:GetGoal(model)
                        if goal then
                            local score = (position - goal).Magnitude
                            for _, killer in killers or {} do
                                local threat = getRoot(killer)
                                if threat then
                                    local distance = (threat.Position - goal).Magnitude
                                    score += math.max(0, 80 - distance) * 3
                                    if distance < 25 then score += 500 end
                                end
                            end
                            if score < bestScore then best, bestScore = model, score end
                        end
                    end
                end
                -- A tag by itself is insufficient: wait for the real binder to initialize.
                return best
            end
            function adapter:IsBusy()
                if not activeModel or not self:IsAvailable(activeModel) then
                    if activeModel or activeBinder then self:Cancel() end
                    return false
                end
                return solving or occupiedByMe(activeBinder)
            end
            function adapter:IsAvailable(model)
                local status = self:GetStatus(model)
                return status == "Available" or status == "Repairing"
            end
            function adapter:GetGoal(model)
                return self:IsAvailable(model) and seatGoal(model) or nil
            end
            function adapter:NeedsGear()
                if destroyed or not self.Available or gearCount() > 0 or not puzzleClasses.Gear then return false end
                for model, bound in pairs(binderClass:GetAll()) do
                    if model.Parent and model:IsDescendantOf(workspace) and puzzleKind(model) == "Gear" and not complete(bound) then return true end
                end
                return false
            end
            function adapter:Cancel()
                epoch += 1
                solving, workerSession = false, nil
                if activeBinder and (occupiedByMe(activeBinder) or enterStartedAt > 0) then
                    pcall(function()
                        if activeBinder.__sitting then
                            activeBinder:__leave()
                        else
                            -- Cancel an Enter request that is still awaiting replication.
                            activeBinder.Network:FireServer("Leave")
                        end
                    end)
                end
                activeBinder, activeModel = nil, nil
                enterAt, enterStartedAt, retryAt = 0, 0, 0
            end
            function adapter:Update(sense, model)
                if destroyed or not self.Available then return false, errorText or self.Status end
                local status = self:GetStatus(model)
                if status ~= "Available" and status ~= "Repairing" then
                    self:Cancel()
                    return false, status == "Complete" and "Generator complete" or status
                end
                if activeModel ~= model then self:Cancel(); activeModel = model end
                activeBinder = binder(model)
                if not activeBinder then return false, "Waiting for generator binder" end
                if complete(activeBinder) then
                    self:Cancel()
                    return false, "Generator complete"
                end
                local root = sense and (sense.root or sense.Root) or getRoot(player.Character)
                if not root then return false, "Waiting for character" end
                if not occupiedByMe(activeBinder) then
                    if enterStartedAt > 0 and os.clock() - enterStartedAt >= 7 then
                        unavailableUntil[model] = os.clock() + 15
                        self:Cancel()
                        self.Status = "Generator entry timed out; choosing another route"
                        return false, self.Status
                    end
                    local goal = self:GetGoal(model)
                    if not goal then return false, "Generator sides occupied" end
                    local nearby, reason = canEnter(model, activeBinder, sense and sense.character or player.Character, root, goal)
                    if not nearby then
                        if enterStartedAt > 0 then self:Cancel() end
                        return false, reason
                    end
                    if os.clock() >= enterAt then
                        -- Identical request to GeneratorClientBinder's prompt Triggered.
                        -- The server still checks range, role, completion, and free seats.
                        local success, failure = pcall(function() activeBinder.Network:FireServer("Enter") end)
                        if not success then
                            unavailableUntil[model] = os.clock() + 15
                            self:Cancel()
                            self.Status = "Generator entry unavailable: " .. tostring(failure)
                            return false, self.Status
                        end
                        if enterStartedAt == 0 then enterStartedAt = os.clock() end
                        enterAt = os.clock() + 2
                    end
                    -- Keep ordinary approach movement until Occupants/__sitting confirms
                    -- entry; a sent request alone is not a repair session.
                    return false, "Waiting for generator entry"
                end
                enterStartedAt = 0
                local session, kind = runningPuzzle()
                if session and session ~= workerSession and os.clock() >= retryAt then
                    workerSession, solving = session, true
                    local token = epoch
                    local function cancelled()
                        return destroyed or token ~= epoch or not model.Parent
                            or complete(activeBinder)
                            or not occupiedByMe(activeBinder) or session.__input.Ended
                    end
                    task.spawn(function()
                        local puzzleFailed = false
                        local success, err = pcall(function()
                            local input = session.__input
                            if kind == "Connect" then
                                self.Status = "Dragging matching connector squares"
                                local solved, message = drawConnectPuzzle(session, cancelled)
                                puzzleFailed = not solved and not cancelled()
                                if not cancelled() then self.Status = message end
                                return
                            elseif kind == "Gear" then
                                self.Status = "Turning repair gear clockwise"
                                local solved, message = turnGearPuzzle(session, cancelled)
                                puzzleFailed = not solved and not cancelled()
                                if not cancelled() then self.Status = message end
                                return
                            elseif kind == "Lock" then
                                self.Status = "Timing lock target presses"
                                local solved, message = pressLockPuzzle(session, cancelled)
                                puzzleFailed = not solved and not cancelled()
                                if not cancelled() then self.Status = message end
                                return
                            end
                            local board = input.Board
                            self.Status = "Solving Flow puzzle"
                            local paths, failure = solveFlow(board.Size, board.Pairs, cancelled, 8)
                            if cancelled() then return end
                            if not paths then self.Status = failure; puzzleFailed = true; return end
                            local valid, why = flowBoard.Validate(board.Size, board.Pairs, paths)
                            if not valid then self.Status = "Flow validation failed: " .. tostring(why); puzzleFailed = true; return end
                            -- Draw every adjacent cell through the existing input object.
                            -- Its __release checks IsSolved and invokes the normal callback.
                            for color, path in pairs(paths) do
                                if cancelled() then return end
                                input:__begin(path[1])
                                for index = 2, #path do
                                    if cancelled() then return end
                                    input:__step(path[index])
                                    task.wait(0.035)
                                end
                                input:__release()
                                task.wait(0.08)
                            end
                            self.Status = "Flow submitted; waiting for server"
                        end)
                        if token == epoch then
                            solving = false
                            retryAt = os.clock() + (success and 3 or 5)
                            if not success then self.Status = "Generator puzzle: " .. tostring(err) end
                            if not success or puzzleFailed then
                                puzzleFailures[model] = (puzzleFailures[model] or 0) + 1
                                if puzzleFailures[model] >= 2 then
                                    local failure = self.Status
                                    unavailableUntil[model] = os.clock() + 15
                                    self:Cancel()
                                    self.Status = "Puzzle unavailable; trying another generator: " .. tostring(failure)
                                    return
                                end
                            else puzzleFailures[model] = nil end
                            if session.__input and not session.__input.Ended then workerSession = nil end
                        end
                    end)
                end
                if session then return true, self.Status end
                return true, "Repairing generator / waiting for puzzle"
            end
            function adapter:Destroy()
                self:Cancel()
                destroyed = true
            end
            -- A require may yield while the game's initialization is incomplete. Keep the
            -- bot and its UI responsive while those existing modules load independently.
            task.spawn(function()
                local success, reason = pcall(function()
                    binderClass = require(rs.Systems.Player.Game.Generators.GeneratorClientBinder)
                    local group = rs.Systems.Player.Game.Minigames
                    for _, kind in ipairs({"Flow", "Connect", "Gear", "Lock"}) do
                        local found, module = pcall(function() return group[kind .. "ClientMinigame"] end)
                        if found and module then
                            local loaded, class = pcall(require, module)
                            if loaded and type(class) == "table" then puzzleClasses[kind] = class end
                        end
                    end
                    local loaded, board = pcall(function() return require(rs.Modules.Minigames.FlowBoard) end)
                    if loaded then flowBoard = board end
                    if not flowBoard then puzzleClasses.Flow = nil end
                    if not next(puzzleClasses) then error("No compatible client minigames loaded") end
                end)
                if destroyed then return end
                if success then
                    adapter.Available, adapter.Status = true, "Ready"
                else
                    errorText = "Generator adapter unavailable: " .. tostring(reason)
                    adapter.Status = errorText
                end
            end)
            task.delay(12, function()
                if not destroyed and not adapter.Available and not errorText then
                    adapter.Status = "Generator modules still loading; check game initialization"
                end
            end)
            return adapter
        end



        -- Asynchronous destination search. This chooses goals; the movement adapter
        -- keeps sole ownership of motion and continues its existing route throughout.
        local function createDestinationPlanner(ctx)
            local planner = {generation = 0, busy = false, workerRunning = false, destroyed = false}
            local player = ctx.player or game:GetService("Players").LocalPlayer
            local settings = ctx.settings or {}
            local world = game:GetService("Workspace")
            local pathfinding = game:GetService("PathfindingService")
            local UP, ZERO = Vector3.yAxis, Vector3.zero
            local function flat(v) return Vector3.new(v.X, 0, v.Z) end
            local function direction(v, fallback)
                local f = flat(v)
                return f.Magnitude > 0.01 and f.Unit or (fallback or Vector3.new(1, 0, 0))
            end
            local function distance(a, b) return (a - b).Magnitude end

            function planner:IsBusy()
                return self.busy and not self.destroyed
            end

            function planner:Cancel()
                self.generation += 1
                self.request = nil
                self.busy = false
                -- ComputeAsync cannot reliably be interrupted. One serial worker drains
                -- it, discards its result, and then handles the newest queued request.
            end

            function planner:Destroy()
                self:Cancel()
                self.destroyed = true
            end

            function planner:_current(request)
                if self.destroyed or self.request ~= request or self.generation ~= request.generation then return false end
                if player.Character ~= request.character or request.humanoid.Health <= 0 then return false end
                local parent = request.character.Parent
                local name = parent and parent.Name or ""
                local role = name:find("Killer") and "Killer" or (name:find("Survivor") and "Survivor" or nil)
                if role and role ~= request.role then return false end
                if request.isCurrent then
                    local ok, current = pcall(request.isCurrent)
                    if not ok or current == false then return false end
                end
                return true
            end

            local function ground(request, point)
                -- Prefer the current floor level beneath room ceilings. Starting every
                -- probe far overhead would choose an unreachable roof over a valid room.
                local hit = world:Raycast(point + UP * 2, -UP * (request.maxDrop + 10), request.params)
                if not hit then hit = world:Raycast(point + UP * 24, -UP * (request.maxDrop + 32), request.params) end
                if not request.movement:_safeSurface(hit) then return nil end
                local floor = hit.Position
                local rootPoint = floor + UP * request.height
                local actualDistance = distance(rootPoint, request.origin)
                if actualDistance < request.minimum or actualDistance > request.maximum then return nil end
                for _, old in ipairs(request.urgent and {} or request.avoidGoals) do
                    if typeof(old) == "Vector3" and flat(old - rootPoint).Magnitude < 22 then return nil end
                end
                -- Require room for the full footprint and standing body at the endpoint.
                local side = Vector3.new(request.radius, 0, 0)
                local front = Vector3.new(0, 0, request.radius)
                for _, offset in ipairs({ZERO, side, -side, front, -front}) do
                    local support = world:Raycast(rootPoint + offset + UP * 1, -UP * (request.height + 3), request.params)
                    if not request.movement:_safeSurface(support) or math.abs(support.Position.Y - floor.Y) > 1.5 then return nil end
                    local low = floor + offset + UP * 0.3
                    if world:Raycast(low, UP * (request.bodyHeight - 0.3), request.params) then return nil end
                end
                return rootPoint
            end

            function planner:_candidates(request)
                local away = request.kind == "roam" and request.heading
                    or request.killer and direction(request.origin - request.killer.Position) or direction(request.root.CFrame.LookVector)
                local baseAngle = math.atan2(away.Z, away.X)
                local factors = request.urgent and {0.16, 0.5, 0.84} or {0.5, 0.7, 0.3, 0.5}
                local angleCount = request.urgent and 32 or 16
                local radiusCount = request.urgent and #factors or 1
                local candidates = {}
                for index = 0, angleCount - 1 do
                    if not self:_current(request) then break end
                    local angle = baseAngle + index * math.pi * 2 / angleCount
                    for radialIndex = 1, radiusCount do
                        -- Stagger the three rings so the same ray grid does not miss
                        -- a narrow exit at every radius (96 distinct rescue headings).
                        local sampleAngle = angle + (request.urgent and (radialIndex - 1) * math.pi * 2 / angleCount / radiusCount or 0)
                        local heading = Vector3.new(math.cos(sampleAngle), 0, math.sin(sampleAngle))
                        local factor = request.urgent and factors[radialIndex] or factors[index % 4 + 1]
                        local radius = request.minimum + (request.maximum - request.minimum) * factor
                        local point = ground(request, request.origin + heading * radius)
                        if point then
                            local separation = request.killer and distance(point, request.killer.Position) or radius
                            local score = request.kind == "escape" and separation * 0.5
                                + heading:Dot(away) * (request.allowKillerPass and 2 or 12)
                                or heading:Dot(request.heading) * 35 + math.random() * 8
                            -- Failed destinations are a preference during rescue. The
                            -- only connected exit may share their endpoint region.
                            for _, old in ipairs(request.avoidGoals) do
                                if typeof(old) == "Vector3" and flat(old - point).Magnitude < 22 then score -= 90 end
                            end
                            table.insert(candidates, {point = point, score = score, sector = math.floor(index / (angleCount / 4)) + 1})
                        end
                    end
                end
                table.sort(candidates, function(a, b) return a.score > b.score end)
                -- Inspect every quadrant before spending the two remaining path slots.
                -- Disconnected attractive islands must not consume the entire budget.
                local ordered, selected = {}, {}
                local sectors = request.urgent and {1, 3, 2, 4} or {1, 2, 3, 4}
                for _, sector in ipairs(sectors) do
                    for _, candidate in ipairs(candidates) do
                        if candidate.sector == sector then
                            table.insert(ordered, candidate)
                            selected[candidate] = true
                            break
                        end
                    end
                end
                if request.urgent then
                    -- Continue round-robin across the circle instead of spending every
                    -- remaining query on attractive disconnected points ahead.
                    local left = true
                    while left do
                        left = false
                        for _, sector in ipairs(sectors) do
                            for _, candidate in ipairs(candidates) do
                                if candidate.sector == sector and not selected[candidate] then
                                    table.insert(ordered, candidate)
                                    selected[candidate], left = true, true
                                    break
                                end
                            end
                        end
                    end
                else
                    for _, candidate in ipairs(candidates) do
                        if not selected[candidate] then table.insert(ordered, candidate) end
                    end
                end
                return ordered, #candidates
            end

            local function closestDistance(a, b, point)
                local delta = b - a
                local lengthSquared = delta:Dot(delta)
                local t = lengthSquared > 0.001 and math.clamp((point - a):Dot(delta) / lengthSquared, 0, 1) or 0
                return distance(a + delta * t, point)
            end

            function planner:_validateRoute(request, raw, candidate)
                if #raw < 2 or #raw > 160 then return nil end
                local route, actions, total, risk, minimum, early = {}, {}, 0, 0, math.huge, nil
                local hazardRisk = 0
                local killerPosition = request.killer and request.killer.Parent and request.killer.Position or nil
                -- ComputeAsync returns a path from its saved start. Movement adopts a
                -- reachable forward suffix if the character advanced while it yielded.
                local previous, previousAction = candidate.start or request.origin, Enum.PathWaypointAction.Walk
                for _, waypoint in ipairs(raw) do
                    if waypoint.Action == Enum.PathWaypointAction.Jump and not request.allowJump then return nil end
                    -- Engine versions and map navmeshes may supply floor-level or
                    -- standing-height points. Resolve their supporting floor once.
                    local support = world:Raycast(waypoint.Position + UP, -UP * (request.height + 4), request.params)
                    if not request.movement:_safeSurface(support) then return nil end
                    local point = support.Position + UP * request.height
                    if math.abs(point.Y - waypoint.Position.Y) > request.height + 2 then return nil end
                    if point.Y - previous.Y > request.maxJumpRise then return nil end
                    if previous.Y - point.Y > request.maxDrop then return nil end
                    local delta = point - previous
                    local segmentLength = delta.Magnitude
                    if segmentLength > 0.05 then
                        if request.movement.HazardPenalty then
                            hazardRisk += request.movement:HazardPenalty(previous, point, request.hazards)
                        end
                        local jumpSegment = waypoint.Action == Enum.PathWaypointAction.Jump or previousAction == Enum.PathWaypointAction.Jump
                        if not jumpSegment and not request.urgent then
                            if not request.movement:_bodyClear(previous, point, direction(delta), request.height,
                                request.bodyHeight, request.radius, request.params) then return nil end
                        elseif jumpSegment then
                            -- The normal pathfinder supplies a jump arc. Endpoints still
                            -- need clear body space, and a low ceiling must reject it.
                            for _, endpoint in ipairs({previous, point}) do
                                local overhead = request.urgent and math.max(0.5, request.bodyHeight - request.height - 0.1)
                                    or request.bodyHeight - request.height + 1
                                if world:Raycast(endpoint, UP * overhead, request.params) then return nil end
                            end
                        elseif delta.Y >= -2.5 then
                            -- The normal pathfinder already accounts for its agent
                            -- radius around tight corners. Do not sweep an enlarged
                            -- straight body across that corner a second time. Still
                            -- reject unsupported walk segments and hazardous floors.
                            local samples = math.clamp(math.ceil(segmentLength / 4), 1, 24)
                            for step = 1, samples do
                                local probe = previous:Lerp(point, step / samples)
                                local floorHit = world:Raycast(probe + UP, -UP * (request.height + 3), request.params)
                                if not request.movement:_safeSurface(floorHit) then return nil end
                                if math.abs(floorHit.Position.Y + request.height - probe.Y) > 2.5 then return nil end
                            end
                        end
                        if killerPosition then
                            minimum = math.min(minimum, closestDistance(previous, point, killerPosition))
                            local steps = math.clamp(math.ceil(segmentLength / 4), 1, 12)
                            for step = 1, steps do
                                local p = previous:Lerp(point, step / steps)
                                local near = math.max(0, 24 - distance(p, killerPosition))
                                local earlyWeight = total + segmentLength * step / steps < 30 and 2 or 0.7
                                risk += near * near * earlyWeight * math.min(4, segmentLength / steps)
                            end
                        end
                        if not early and total + segmentLength >= 12 then early = previous:Lerp(point, (12 - total) / segmentLength) end
                        total += segmentLength
                        if total > request.maximum * 6 then return nil end
                    end
                    table.insert(route, point)
                    table.insert(actions, waypoint.Action or Enum.PathWaypointAction.Walk)
                    previous, previousAction = point, waypoint.Action
                end
                local final = route[#route]
                if distance(final, candidate.point) > 7 then return nil end
                local finalDistance = distance(final, request.origin)
                local liveDistance = distance(final, request.root.Position)
                if finalDistance < request.minimum - 0.05 or finalDistance > request.maximum + 0.05
                    or (not request.urgent and (liveDistance < request.minimum * 0.45 or liveDistance > request.maximum + 35)) then return nil end
                for _, old in ipairs(request.urgent and {} or request.avoidGoals) do
                    if typeof(old) == "Vector3" and flat(old - final).Magnitude < 22 then return nil end
                end
                local score = candidate.score - total * 0.13
                local initialGain = 0
                if killerPosition then
                    if request.kind == "escape" then
                        local liveAway = direction(request.root.Position - killerPosition)
                        score = distance(final, killerPosition) * 0.5
                            + direction(final - request.root.Position):Dot(liveAway) * (request.allowKillerPass and 2 or 12) - total * 0.13
                    end
                    early = early or final
                    initialGain = distance(early, killerPosition) - distance(request.root.Position, killerPosition)
                    score += initialGain * (request.allowKillerPass and 1.5 or 7)
                        + math.min(minimum, 60) * (request.allowKillerPass and 0.2 or 1.5)
                        - risk * (request.allowKillerPass and 0.006 or 0.06)
                end
                score -= hazardRisk * 0.4
                return {goal = final, score = score, length = total, minSeparation = minimum,
                    initialGain = initialGain, route = route, actions = actions, routeOrigin = candidate.start or request.origin}
            end

            function planner:_search(request)
                local candidates, count = self:_candidates(request)
                local metadata = {status = "No reachable destination", kind = request.kind, origin = request.origin,
                    minDistance = request.minimum, maxDistance = request.maximum, candidates = count, paths = 0,
                    urgent = request.urgent, allowKillerPass = request.allowKillerPass, character = request.character}
                local function ready(best)
                    metadata.status, metadata.length = "Ready", best.length
                    metadata.minSeparation, metadata.initialGain = best.minSeparation, best.initialGain
                    metadata.route, metadata.actions = best.route, best.actions
                    metadata.routeOrigin, metadata.score = best.routeOrigin, best.score
                    return best.goal, metadata
                end
                local checked = {}
                for index, candidate in ipairs(candidates) do
                    if index > (request.urgent and 12 or 6) or not self:_current(request) then break end
                    if os.clock() - request.started > (request.urgent and 4.5 or 5.5) then metadata.status = "Planning budget reached"; break end
                    if (settings.Jump ~= false) ~= request.jumpSetting then metadata.status = "Settings changed"; break end
                    local path = pathfinding:CreatePath({AgentRadius = request.radius, AgentHeight = request.bodyHeight,
                        AgentCanJump = request.allowJump, AgentCanClimb = true, WaypointSpacing = 5})
                    metadata.paths += 1
                    candidate.start = request.root.Position
                    local ok = pcall(path.ComputeAsync, path, candidate.start, candidate.point)
                    local firstValid
                    if self:_current(request) and ok and path.Status == Enum.PathStatus.Success then
                        local raw = path:GetWaypoints()
                        local valid = self:_validateRoute(request, raw, candidate)
                        if valid then
                            if request.urgent then firstValid = valid
                            else table.insert(checked, {raw = raw, candidate = candidate}) end
                        end
                    end
                    pcall(function() path:Destroy() end)
                    if not self:_current(request) then break end
                    -- A trapped survivor needs the first legal way out immediately.
                    -- Waiting for five more comparisons can consume the whole chase.
                    if firstValid and (settings.Jump ~= false) == request.jumpSetting then return ready(firstValid) end
                end
                local best
                if self:_current(request) and (settings.Jump ~= false) == request.jumpSetting then
                    -- Every candidate now uses the same live killer/root positions and
                    -- fresh ground/body rays. Earlier queries cannot retain an obsolete
                    -- advantage after the killer moves onto that route during a yield.
                    for _, result in ipairs(checked) do
                        local valid = self:_validateRoute(request, result.raw, result.candidate)
                        if valid and (not best or valid.score > best.score) then best = valid end
                    end
                end
                if best and self:_current(request) then
                    local liveDistance = distance(best.goal, request.root.Position)
                    if request.urgent or (liveDistance >= request.minimum * 0.45 and liveDistance <= request.maximum + 35) then return ready(best) end
                    metadata.status = "Origin moved; retry"
                end
                return nil, metadata
            end

            function planner:_work()
                while not self.destroyed and self.request do
                    local request = self.request
                    local ok, goal, metadata = pcall(self._search, self, request)
                    local publish = self:_current(request)
                    if self.request == request then self.request, self.busy = nil, false end
                    if publish then
                        if not ok then
                            metadata, goal = {status = "Planner unavailable: " .. tostring(goal), kind = request.kind,
                                origin = request.origin, minDistance = request.minimum, maxDistance = request.maximum}, nil
                        end
                        local delivered, err = pcall(request.callback, goal, metadata)
                        if not delivered and ctx.notify then ctx.notify("Destination callback: " .. tostring(err)) end
                    end
                end
                self.workerRunning = false
            end

            function planner:Request(sense, options, callback)
                if self.destroyed or self.busy or type(callback) ~= "function" then return false end
                if not sense or not sense.character or not sense.root or not sense.humanoid or sense.humanoid.Health <= 0 then return false end
                if player.Character ~= sense.character then return false end
                local movement = ctx.getMovement and ctx.getMovement()
                if not movement or type(movement._rayParams) ~= "function" or type(movement._standHeight) ~= "function" then return false end
                options = options or {}
                local kind = options.kind == "escape" and "escape" or "roam"
                local minimum = math.clamp(tonumber(options.minDistance) or (kind == "escape" and 100 or 50), 10, 300)
                local maximum = math.clamp(tonumber(options.maxDistance) or (kind == "escape" and 150 or 100), minimum + 5, 400)
                local allowJump = settings.Jump ~= false and sense.humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)
                    and ((sense.humanoid.UseJumpPower and sense.humanoid.JumpPower > 0)
                        or (not sense.humanoid.UseJumpPower and sense.humanoid.JumpHeight > 0))
                self.generation += 1
                local height = movement:_standHeight(sense.root, sense.humanoid)
                local request = {generation = self.generation, callback = callback, isCurrent = options.isCurrent,
                    kind = kind, minimum = minimum, maximum = maximum, origin = sense.root.Position,
                    heading = direction(options.heading or sense.root.AssemblyLinearVelocity, direction(sense.root.CFrame.LookVector)),
                    urgent = kind == "escape" and options.urgent == true,
                    allowKillerPass = kind == "escape" and options.allowKillerPass == true,
                    character = sense.character, root = sense.root, humanoid = sense.humanoid, role = sense.role,
                    movement = movement, params = movement:_rayParams(sense.character), height = height,
                    bodyHeight = math.clamp(height + sense.root.Size.Y * 0.5 + 1, 4, 10),
                    radius = math.clamp(math.max(sense.root.Size.X, sense.root.Size.Z) * 0.5 + 0.4, 1.5, 3),
                    maxDrop = math.clamp(tonumber(settings.MaxDropHeight) or 40, 3, 80),
                    maxJumpRise = allowJump and math.max(2, (sense.humanoid.UseJumpPower
                        and sense.humanoid.JumpPower ^ 2 / (2 * math.max(1, world.Gravity or 196.2))
                        or sense.humanoid.JumpHeight) + 0.75) or 2,
                    allowJump = allowJump, jumpSetting = settings.Jump ~= false, avoidGoals = table.clone(options.avoidGoals or {}),
                    killer = sense.killerRoot, hazards = sense.hazards or {}, started = os.clock()}
                self.request, self.busy = request, true
                if not self.workerRunning then
                    self.workerRunning = true
                    task.spawn(function() self:_work() end)
                end
                return true
            end
            return planner
        end



        -- Choose teammate-help and cover positions. The shared navigator owns movement.
        local function createAssistController(ctx)
            local helper = {}
            local settings = ctx.settings or {}
            local active, restUntil, destroyed = nil, 0, false
            local UP = Vector3.yAxis
            local function flat(v) return Vector3.new(v.X, 0, v.Z) end
            local function unit(v) return v.Magnitude > 0.01 and v.Unit or Vector3.new(1, 0, 0) end
            local function alive(model)
                local h = model and model.Parent and model:FindFirstChildOfClass("Humanoid")
                return h and h.Health > 0 and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
            end
            local function restTime() return math.clamp(tonumber(settings.AssistRest) or 10, 8, 15) end
            local function finish(now)
                if active then restUntil = math.max(restUntil, now + restTime()) end
                active = nil
            end
            local function serial(ability) return ability.actionSerial or ability.castSerial or 0 end
            local function spacing(s, intent, point)
                local nearest, seen = math.huge, {}
                for _, killer in ipairs(s.killers or {}) do
                    local root = alive(killer)
                    if root then nearest, seen[root] = math.min(nearest, flat(point - root.Position).Magnitude), true end
                end
                local function include(root)
                    if root and root.Parent and not seen[root] then nearest = math.min(nearest, flat(point - root.Position).Magnitude) end
                end
                include(intent.killerRoot)
                include(s.killerRoot)
                return nearest
            end
            local function usefulCover(s, intent, ability)
                local allyRoot = alive(intent.allyModel)
                local killerModel = intent.killerModel or (intent.killerRoot and intent.killerRoot.Parent)
                local killerRoot = alive(killerModel)
                if not allyRoot or not killerRoot or not killerRoot.Parent then return false end
                if flat(allyRoot.Position - s.root.Position).Magnitude > 85 then return false end
                local delta = flat(allyRoot.Position - killerRoot.Position)
                if delta.Magnitude > 55 then return false end
                local h = intent.allyModel:FindFirstChildOfClass("Humanoid")
                local injured = (h.MaxHealth or 100) - h.Health >= 12
                local toward = unit(delta)
                local facing = flat(killerRoot.CFrame.LookVector):Dot(toward) > 0.15
                local closing = flat(killerRoot.AssemblyLinearVelocity):Dot(toward) > 2
                local visible = not ability.LOS or ability:LOS(killerRoot, allyRoot)
                local pressured = visible and delta.Magnitude < 38 and (facing or closing or delta.Magnitude < 14)
                return injured or pressured
            end

            local function goalFor(s, intent, passive)
                local movement = ctx.getMovement and ctx.getMovement()
                if not movement then return nil end
                local params = movement:_rayParams(s.character)
                local height = movement:_standHeight(s.root, s.humanoid)
                local target = not passive and intent.kind == "counterattack" and intent.killerRoot or intent.allyRoot
                if not target or not target.Parent then return nil end
                local desired = passive and 30 or (intent.preferredDistance or 30)
                local minimum = passive and 20 or (intent.minDistance or 20)
                local range = passive and 32 or intent.range
                if type(range) ~= "number" or range < 1 then return nil end
                local anchor = target.Position
                local away = unit(flat(s.root.Position - anchor))
                if (passive or intent.kind == "support") and intent.killerRoot then away = unit(flat(anchor - intent.killerRoot.Position)) end
                local best, scoreBest
                local function consider(point, current)
                    if not current then
                        local hit = workspace:Raycast(point + UP * 8, -UP * 24, params)
                        if not movement:_safeSurface(hit) then return end
                        point = hit.Position + UP * height
                        local feet = point - UP * height + UP * 0.3
                        if workspace:Raycast(feet, UP * (height + s.root.Size.Y * 0.5 + 0.5), params) then return end
                    end
                    local distance = (point - anchor).Magnitude
                    if distance > range - (passive and 0 or 0.5) then return end
                    local kd = spacing(s, intent, point)
                    if kd < minimum or (passive and kd > 42) then return end
                    local sight = movement:_clearLine(point, anchor, params)
                    if not passive and not sight then return end
                    local travel = flat(point - s.root.Position).Magnitude
                    local corridor = movement:_clearLine(s.root.Position, point, params)
                    local score = -travel * 0.8 - (corridor and 0 or 35)
                    if passive then
                        score -= math.abs(kd - desired) * 2 + math.abs(distance - 16) * 0.35
                        if not sight then score -= 8 end
                    elseif intent.kind == "support" then score += math.min(kd, desired) * 1.5
                    else
                        score -= math.abs(distance - desired) * 2
                        score -= math.max(0, unit(flat(point - anchor)):Dot(flat(target.CFrame.LookVector))) * 9
                    end
                    if current then score += 8 end
                    if active and active.goal then score -= math.min(flat(point - active.goal).Magnitude, 25) * 0.3 end
                    if not scoreBest or score > scoreBest then best, scoreBest = point, score end
                end
                if s.humanoid.FloorMaterial ~= Enum.Material.Air then consider(s.root.Position, true) end
                local radii = passive and {12, 18, 24, 30}
                    or {intent.kind == "support" and math.min(range * 0.65, 24) or desired}
                for _, radius in ipairs(radii) do
                    for _, degrees in ipairs({0, 35, -35, 70, -70, 110, -110, 180}) do
                        local angle = math.rad(degrees)
                        local heading = Vector3.new(away.X * math.cos(angle) - away.Z * math.sin(angle), 0,
                            away.X * math.sin(angle) + away.Z * math.cos(angle))
                        consider(anchor + heading * radius)
                    end
                end
                return best
            end

            local function enterCover(s, ability)
                if not active or not usefulCover(s, active.intent, ability) then return false end
                local now = s.now or os.clock()
                local deadline = active.guardUntil or now + math.clamp(tonumber(settings.AssistGuardTime) or 18, 6, 25)
                if now >= deadline then return false end
                local goal = goalFor(s, active.intent, true)
                if not goal then return false end
                active.phase, active.passive, active.kind = "escort", true, "escort"
                active.guardUntil, active.expires, active.goal = deadline, deadline, goal
                active.nextGoal, active.nextReady, active.coverBegan = now + 0.7, now + 0.7, now
                active.castSerial = serial(ability)
                active.label, active.arrival = "COVER / " .. active.intent.allyModel.Name, 3
                restUntil = math.max(restUntil, now + restTime())
                return true
            end

            function helper:Update(s, ability)
                local now = s.now or os.clock()
                if destroyed then return nil end
                local h, root, character = s.humanoid, s.root, s.character
                local allowed = settings.AssistAllies ~= false and settings.Abilities ~= false
                    and s.role == "Survivor" and h and root and character and character.Parent
                    and ability and ability.GetAssistIntent
                if not allowed then finish(now); return nil end
                if active and active.character ~= character then finish(now); return nil end
                local danger = h.Health / math.max(h.MaxHealth or 100, 1) < (settings.AssistMinHealth or 0.6)
                    or type(s.stamina) ~= "number" or s.stamina < (settings.Reserve or 25) + (settings.AssistMinStaminaMargin or 15)
                    or s.damaged or s.incomingAttack or s.underAttack or s.selfCornered
                    or character:GetAttribute("Ragdolling") or character:GetAttribute("Stunned")
                if danger then
                    finish(now)
                    if s.damaged then restUntil = math.max(restUntil, now + restTime()) end
                    return nil
                end
                if active and not alive(active.intent.allyModel) then finish(now); return nil end
                -- A normal jump or one's own cast animation cannot cancel an established
                -- help session. They never initiate a new approach or move the player.
                local temporarilyLocked = h.FloorMaterial == Enum.Material.Air or s.movementLocked or root.Anchored
                if not active and temporarilyLocked then return nil end

                if active and active.phase == "approach" then
                    local used = serial(ability) ~= active.castSerial
                    local intent = not used and ability:GetAssistIntent(s, active.intent) or nil
                    if used or now >= active.expires or not intent then
                        if not enterCover(s, ability) then finish(now); return nil end
                    else active.intent = intent end
                end
                if active and active.phase == "escort" then
                    if now >= active.guardUntil or not usefulCover(s, active.intent, ability) then finish(now); return nil end
                    -- A close-range cast first retreats to cover. If that retreat cannot
                    -- leave melee range promptly, ordinary escape takes over.
                    if now - active.coverBegan > 2.5 and spacing(s, active.intent, root.Position) < 12 then finish(now); return nil end
                    if not temporarilyLocked and now >= restUntil and now >= active.nextReady then
                        active.nextReady = now + 0.7
                        local ready = ability:GetAssistIntent(s, active.intent)
                        if ready and ready.allyModel == active.intent.allyModel then
                            local goal = goalFor(s, ready, false)
                            if goal then
                                active.phase, active.passive, active.kind = "approach", false, ready.kind
                                active.intent, active.goal = ready, goal
                                active.castSerial, active.nextGoal = serial(ability), now + 0.7
                                active.expires = math.min(active.guardUntil, now + math.clamp(settings.AssistWindow or 5, 1, 8))
                                active.label, active.arrival = ready.ability .. " / " .. ready.allyModel.Name,
                                    ready.kind == "counterattack" and 1 or 2
                            end
                        end
                    end
                    if active.phase == "escort" then
                        if temporarilyLocked or now < active.nextGoal then return active end
                        local goal = goalFor(s, active.intent, true)
                        if not goal then finish(now); return nil end
                        active.goal, active.nextGoal = goal, now + 0.7
                        return active
                    end
                end
                if active then
                    if temporarilyLocked or now < active.nextGoal then return active end
                elseif now < restUntil then return nil end
                local intent = active and active.intent or ability:GetAssistIntent(s)
                if not intent or not alive(intent.allyModel)
                    or (s.killerDistance or math.huge) < (intent.minDistance or 20) then finish(now); return nil end
                local goal = goalFor(s, intent, false)
                if not goal then finish(now); return nil end
                if not active then
                    active = {phase = "approach", passive = false, started = now,
                        expires = now + math.clamp(settings.AssistWindow or 5, 1, 8),
                        character = character, castSerial = serial(ability)}
                end
                active.goal, active.nextGoal, active.intent = goal, now + 0.7, intent
                active.kind, active.label = intent.kind, intent.ability .. " / " .. intent.allyModel.Name
                active.arrival = intent.kind == "counterattack" and 1 or 2
                return active
            end
            function helper:Reset() active, restUntil = nil, 0 end
            function helper:Destroy() self:Reset(); destroyed = true end
            return helper
        end



        -- Read-only combat sensing and short, grounded sidesteps. The movement adapter
        -- applies the result without throwing away its chase/escape/roaming route.
        local function createCombatNavigation(ctx)
            local combat = {animations = setmetatable({}, {__mode = "k"})}
            local settings = ctx.settings or {}
            local active, nextStep, lastSide, destroyed = nil, 0, 1, false
            local UP = Vector3.new(0, 1, 0)
            local function flat(v) return Vector3.new(v.X, 0, v.Z) end
            local function unit(v)
                local f = flat(v)
                return f.Magnitude > 0.001 and f.Unit or Vector3.new(1, 0, 0)
            end
            local function rootOf(model)
                return model and model.Parent and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
            end
            local function alive(model)
                local h = model and model:FindFirstChildOfClass("Humanoid")
                return h and h.Health > 0
            end
            local function includes(text, list)
                for _, word in ipairs(list) do if text:find(word, 1, true) then return true end end
                return false
            end
            local ranged = {"aimgun", "gunfire", "shoot", "staffshot", "plasmabeam", "corruptnature", "corruptenergy",
                "entanglement", "massinfection", "nova", "bats", "uppercut", "fireball", "dismantle", "sow", "blossom", "spire"}
            local melee = {"slash", "stab", "punch", "axe", "hatchet", "dagger", "behead", "gashing", "carving", "claw", "bite", "grab", "tag", "attack"}
            local dash = {"voidrush", "demonicpursuit", "walkspeedoverride", "charge", "lunge"}
            local function number(config, key, fallback)
                return type(config[key]) == "number" and config[key] or fallback
            end
            local function describe(key, config)
                local n = key:lower():gsub("[^%w]", "")
                if n:match("idle$") or n:match("walk$") or n:match("run$")
                    or includes(n, {"fail", "explode", "victim", "execution", "end", "hitreact", "blockbroken"}) then return nil end
                if n == "block" then return {kind = "block", range = 12, duration = number(config, "BlockDuration", 1) + 0.2, name = key} end
                local kind = includes(n, ranged) and "ranged" or includes(n, dash) and "dash" or includes(n, melee) and "melee"
                if not kind then return nil end
                local windup = number(config, key .. "WindupTime", number(config, key .. "Windup", 0.55))
                if n == "aimgun" or n == "gunfire" then windup = 0.95 end
                local range = kind == "ranged" and number(config, "ShootHitboxRange", 100) or kind == "dash" and 45 or 12
                return {kind = kind, range = range, duration = kind == "dash" and 2.5 or windup + 0.45, name = key}
            end
            function combat:_animationMap(actor)
                if self.animations[actor] then return self.animations[actor] end
                local map, config = {}, actor.Config or {}
                local function walk(t, prefix, depth)
                    if depth > 3 then return end
                    for name, value in pairs(t or {}) do
                        if type(value) == "string" then
                            local id = value:match("%d%d%d+")
                            local info = describe(prefix .. tostring(name), config)
                            if id and info then map[id] = info end
                        elseif type(value) == "table" then walk(value, prefix .. tostring(name), depth + 1) end
                    end
                end
                walk(config.Animations, "", 0)
                self.animations[actor] = map
                return map
            end
            function combat:_actorThreat(s, ability, model)
                local root = rootOf(model)
                if not root or model == s.character or not alive(model) then return nil end
                local delta = flat(s.root.Position - root.Position)
                local distance = delta.Magnitude
                if distance > 120 then return nil end
                local actor = ability:GetActor(model)
                if not actor or not ability:LOS(root, s.root) then return nil end
                local facing = unit(root.CFrame.LookVector):Dot(unit(delta))
                local hum = model:FindFirstChildOfClass("Humanoid")
                local animator = hum and hum:FindFirstChildOfClass("Animator")
                local best
                if animator then
                    local map = self:_animationMap(actor)
                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                        local id = track.Animation and track.Animation.AnimationId:match("%d+")
                        local info = id and map[id]
                        if info and track.IsPlaying and (track.WeightCurrent or 1) > 0.05
                            and (track.TimePosition or 0) <= info.duration and distance <= info.range then
                            if info.kind == "block" then
                                if s.role == "Killer" then s.enemyBlocking = s.targetModel == model or s.enemyBlocking end
                                if s.role == "Killer" and distance < 10 then
                                    best = {kind = "block", root = root, position = root.Position, direction = unit(root.CFrame.LookVector),
                                        model = model, range = 12, urgency = 1, name = "Waiting out block", token = track}
                                end
                            elseif facing > (info.kind == "ranged" and 0.65 or 0.1) then
                                best = {kind = info.kind, root = root, position = root.Position, direction = unit(root.CFrame.LookVector),
                                    model = model, range = info.range, urgency = info.kind == "ranged" and 5 or 4,
                                    name = info.name, token = track}
                                break
                            end
                        end
                    end
                end
                -- Native rush states supplement animation replication.
                for _, key in ipairs({"VoidRushState", "PursuitState", "DemonicPursuitState"}) do
                    local state = model:GetAttribute(key)
                    if (state == "Dashing" or state == "Charging" or state == "Rushing") and facing > 0.3 and distance < 65 then
                        return {kind = "dash", root = root, position = root.Position, direction = unit(root.CFrame.LookVector),
                            model = model, range = 45, urgency = 5, name = key, token = model}
                    end
                end
                if best then return best end
                -- At melee spacing, make one committed lateral cut instead of running
                -- straight ahead until the server has already reported damage.
                if s.role == "Survivor" and distance < 13 and facing > 0.25
                    and flat(root.AssemblyLinearVelocity):Dot(unit(delta)) > 2 then
                    return {kind = "close", root = root, position = root.Position, direction = unit(root.CFrame.LookVector),
                        model = model, range = 12, urgency = 2, name = "Close pursuit", token = model}
                end
                return nil
            end
            function combat:_projectileThreat(s)
                local best
                for id, projectile in pairs(self.projectiles and self.projectiles.Projectiles or {}) do
                    local model = projectile.Model
                    if projectile.Running and model and model.Parent then
                        local position = model:GetPivot().Position
                        local velocity = projectile.CurrentVelocity or projectile.InitialVelocity
                        if typeof(velocity) == "Vector3" and (position - s.root.Position).Magnitude < 140 then
                            local relative = velocity - s.root.AssemblyLinearVelocity
                            local delta = s.root.Position - position
                            local speed2 = relative:Dot(relative)
                            local t = speed2 > 1 and delta:Dot(relative) / speed2 or -1
                            if t > 0 and t < 0.9 then
                                local miss = position + relative * t + UP * (0.5 * (projectile.Gravity or 0) * t * t) - s.root.Position
                                if flat(miss).Magnitude < 5.5 and math.abs(miss.Y) < 5 then
                                    local urgency = 8 + (0.9 - t) * 4
                                    if not best or urgency > best.urgency then
                                        best = {kind = "projectile", position = position, direction = unit(velocity),
                                            range = 6, urgency = urgency, name = "Incoming projectile", token = id, impact = t}
                                    end
                                end
                            end
                        end
                    end
                end
                return best
            end
            function combat:_goal(s, threat)
                local movement = ctx.getMovement and ctx.getMovement()
                if not movement then return nil end
                local params = movement:_rayParams(s.character)
                local height = movement:_standHeight(s.root, s.humanoid)
                local away = unit(s.root.Position - threat.position)
                local side = unit(threat.direction:Cross(UP))
                local travel = unit(movement.direction or s.root.CFrame.LookVector)
                local best, scoreBest
                for _, length in ipairs({10, 7, 4}) do
                    for _, weights in ipairs({{1, 0.3}, {-1, 0.3}, {1, 0.8}, {-1, 0.8}, {0, 1}}) do
                        local direction = unit(side * weights[1] + away * weights[2])
                        local point = s.root.Position + direction * length
                        local hit = workspace:Raycast(point + UP * 2, -UP * (height + 5), params)
                        if movement:_safeSurface(hit) then
                            point = hit.Position + UP * height
                            if math.abs(point.Y - s.root.Position.Y) < 3 and movement:_clearLine(s.root.Position, point, params)
                                and (not movement.HazardPenalty or movement:HazardPenalty(s.root.Position, point, s.hazards) == 0) then
                                local delta = flat(point - threat.position)
                                local separation = delta.Magnitude
                                local offLine = (delta - threat.direction * delta:Dot(threat.direction)).Magnitude
                                local rangedThreat = threat.kind == "ranged" or threat.kind == "projectile" or threat.kind == "dash"
                                local score = (rangedThreat and offLine * 4 or separation * 2)
                                    + direction:Dot(travel) * 5 + (weights[1] == lastSide and 0 or 2) + length * 0.15
                                if s.role == "Survivor" and not rangedThreat then score += math.abs(direction:Dot(side)) * 12 end
                                if threat.kind == "block" then score = -math.abs(separation - 13) * 4 + direction:Dot(away) * 3 end
                                if not scoreBest or score > scoreBest then best, scoreBest = point, score end
                            end
                        end
                    end
                end
                if best then lastSide = unit(best - s.root.Position):Dot(side) >= 0 and 1 or -1 end
                return best
            end
            function combat:Update(s, ability)
                if destroyed or settings.DodgeAttacks == false or not ability or not ability.GetActor
                    or not s.root or not s.humanoid then active = nil; return nil end
                local now = s.now or os.clock()
                local best
                for _, model in ipairs(s.role == "Killer" and (s.survivors or {}) or (s.killers or {})) do
                    local threat = self:_actorThreat(s, ability, model)
                    if threat and (not best or threat.urgency > best.urgency) then best = threat end
                end
                local projectile = self:_projectileThreat(s)
                if projectile and (not best or projectile.urgency > best.urgency) then best = projectile end
                s.combatThreat = best
                if best and best.kind ~= "block" then s.incomingAttack = best.kind ~= "close"; s.underAttack = true end
                if s.movementLocked or s.root.Anchored or s.humanoid.FloorMaterial == Enum.Material.Air
                    or s.character:GetAttribute("Ragdolling") then active = nil; return nil end
                if active and now < active.expires then
                    -- Keep one side through a dodge. A new immediate projectile can
                    -- supersede it; repeated thought ticks cannot zigzag in place.
                    if not best or best.token == active.token or best.urgency <= active.urgency then return active end
                end
                active = nil
                if not best or now < nextStep then return nil end
                local goal = self:_goal(s, best)
                if not goal then return nil end -- leave the main escape/path active
                local duration = best.kind == "projectile" and 0.55 or best.kind == "block" and 0.45 or 0.65
                active = {goal = goal, expires = now + duration, token = best.token, urgency = best.urgency,
                    kind = best.kind, label = best.name, emergency = s.role ~= "Killer"}
                nextStep = now + duration + 0.12
                return active
            end
            function combat:Reset()
                active, nextStep, lastSide = nil, 0, 1
            end
            function combat:Destroy()
                self:Reset()
                destroyed = true
            end
            -- This ordinary client module exposes the visual projectile registry. Its
            -- records intentionally omit owners, so only intersecting motion is used.
            task.spawn(function()
                local ok, module = pcall(function()
                    return require(game:GetService("ReplicatedStorage").Systems.Player.Game.ProjectileReplication)
                end)
                if ok and type(module) == "table" and not destroyed then combat.projectiles = module end
            end)
            return combat
        end



        -- Uses actual ItemEntity prompts, GearClientBinder spawners, normal inventory
        -- equip requests and Tool:Activate. All healing, gear counts and buffs remain
        -- server-authoritative. FakeMedkit/FakeBloxyCola are deliberately not selected.
        local function createItems(ctx)
            local player = ctx.player or game:GetService("Players").LocalPlayer
            local rs = ctx.ReplicatedStorage or game:GetService("ReplicatedStorage")
            local world = game:GetService("Workspace")
            local collection = game:GetService("CollectionService")
            local settings = ctx.settings or {}
            local adapter = {Available = true, Status = "Ready"}
            local network, gearBinder
            local configs = {
                Medkit = {HealTime = 7, HealAmount = 80},
                BloxyCola = {DrinkTime = 4, SpeedDuration = 10},
            }
            local active, approach, heldPrompt, heldKey, holdBackend
            local destroyed, nextScan = false, 0
            local cached = {}
            local retry = setmetatable({}, {__mode = "k"})
            local itemRetry = {Medkit = 0, BloxyCola = 0}
            local function now() return os.clock() end
            local skipCount = setmetatable({}, {__mode = "k"})
            local pickupPause = 0
            local lastFull = false
            -- 1st failure: short pause, then longer; after the 3rd the item is ignored until it respawns.
            local function penalize(object, base)
                local count = (skipCount[object] or 0) + 1
                skipCount[object] = count
                retry[object] = count >= 3 and math.huge or now() + (tonumber(base) or 12) * 2 ^ (count - 1)
                pickupPause = now() + 3
                debugLog(count >= 3 and "plr gave up on an item for good" or "plr gave up on an item for now")
            end
            local function attr(object, name, fallback)
                local ok, value = pcall(function() return object:GetAttribute(name) end)
                if ok and value ~= nil then return value end
                return fallback
            end
            local function gears() return tonumber(attr(player, "Gears", 0)) or 0 end
            local function rootOf(model)
                if not model then return nil end
                if model:IsA("BasePart") then return model end
                return model:FindFirstChild("ItemRoot", true) or model:FindFirstChild("Root")
                    or model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
            end
            local function normalize(name)
                return string.lower((tostring(name):gsub("[^%w]", "")))
            end
            -- Roblox's built-in hotbar: counts populated slots (catches items that are not plain Tools in the Backpack)
            local function hotbarCount()
                local total = 0
                pcall(function()
                    local gui = game:GetService("CoreGui"):FindFirstChild("RobloxGui")
                    local backpackGui = gui and gui:FindFirstChild("Backpack")
                    local hotbar = backpackGui and backpackGui:FindFirstChild("Hotbar")
                    if not hotbar then return end
                    for _, slot in ipairs(hotbar:GetChildren()) do
                        local label, icon = slot:FindFirstChild("ToolName"), slot:FindFirstChild("ToolIcon")
                        local named = label and label:IsA("TextLabel") and label.Text ~= ""
                        local iconed = icon and icon:IsA("ImageLabel") and icon.Image ~= ""
                        if named or iconed then total += 1 end
                    end
                end)
                return total
            end
            local function inventory(character)
                local result, count, names = {}, 0, {}
                local parents = {}
                local backpack = player:FindFirstChildOfClass("Backpack")
                if backpack then table.insert(parents, backpack) end
                if character then table.insert(parents, character) end
                for _, parent in ipairs(parents) do
                    if parent then
                        for _, tool in ipairs(parent:GetChildren()) do
                            if tool:IsA("Tool") then
                                count += 1
                                local key = normalize(tool.Name)
                                names[key] = true
                                if key == "medkit" then result.Medkit = tool end
                                if key == "bloxycola" then result.BloxyCola = tool end
                            end
                        end
                    end
                end
                count = math.max(count, hotbarCount())
                return result, count, names
            end
            local function allowed(sense)
                return not destroyed and settings.Items ~= false and sense and sense.role == "Survivor"
                    and sense.character == player.Character and sense.root and sense.humanoid
                    and sense.humanoid.Health > 0
            end
            local function emergency(sense, usingKind)
                if not allowed(sense) or sense.damaged or sense.underAttack or sense.incomingAttack
                    or sense.movementLocked or sense.root.Anchored then return true end
                if attr(sense.character, "NoItems", false) or attr(sense.character, "UsingItemsDisabled", false) then return true end
                local minimum = usingKind == "Medkit" and 35 or 24
                if (tonumber(sense.killerDistance) or math.huge) < minimum then return true end
                return usingKind == "Medkit" and sense.fleeing == true
            end
            local function los(sense, target)
                local delta = target.Position - sense.root.Position
                local params = RaycastParams.new()
                params.FilterType, params.RespectCanCollide = Enum.RaycastFilterType.Exclude, true
                params.FilterDescendantsInstances = {sense.character, target.Parent}
                local actors = world:FindFirstChild("Players")
                if actors then table.insert(params.FilterDescendantsInstances, actors) end
                return world:Raycast(sense.root.Position, delta, params) == nil
            end
            local function releasePrompt()
                if holdBackend == "prompt" and heldPrompt then pcall(function() heldPrompt:InputHoldEnd() end) end
                if holdBackend == "key" and heldKey and ctx.input then pcall(ctx.input.SetKey, ctx.input, heldKey, false) end
                heldPrompt, heldKey, holdBackend = nil, nil, nil
            end
            local function unequip(tool, character)
                if tool and tool.Parent == character then
                    if network and type(network.FireServerConnection) == "function" then
                        pcall(network.FireServerConnection, network, "UpdateItemParent", "REMOTE_EVENT", tool)
                    else
                        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                        if humanoid then pcall(humanoid.UnequipTools, humanoid) end
                    end
                end
            end
            function adapter:GiveUp()
                if approach and approach.intent and approach.intent.target then penalize(approach.intent.target, 12) end
                if active and active.kind == "pickup" and active.target then penalize(active.target, 12) end
            end
            function adapter:Cancel(reason)
                releasePrompt()
                local previous = active
                active, approach = nil, nil
                if previous and previous.kind == "use" then unequip(previous.target, previous.character) end
                if reason then self.Status = reason end
            end
            function adapter:IsBusy() return not destroyed and active ~= nil end
            function adapter:GetStatus() return self.Status end
            function adapter:Skip(intent, seconds)
                if intent and intent.target then penalize(intent.target, seconds) end
                if active and intent and active.target == intent.target then self:Cancel("Trying another pickup")
                elseif approach and intent and approach.intent.target == intent.target then approach = nil end
            end
            local function refresh()
                if now() < nextScan then return end
                nextScan = now() + 1.25
                cached = {}
                local seen = {}
                local function add(object, kind)
                    if seen[object] or not object.Parent or not object:IsDescendantOf(world) then return end
                    local root = rootOf(object)
                    local prompt = object:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if root and prompt and prompt.Enabled and prompt.MaxActivationDistance > 0 then
                        seen[object] = true
                        table.insert(cached, {target = object, itemKind = kind, root = root, prompt = prompt})
                    end
                end
                for _, object in ipairs(collection:GetTagged("ItemEntity")) do
                    if object.Name == "Medkit" or object.Name == "BloxyCola" then add(object, object.Name) end
                end
                if gearBinder and type(gearBinder.GetAll) == "function" then
                    for spawner in pairs(gearBinder:GetAll()) do
                        if spawner.Parent and spawner:IsDescendantOf(world) then
                            for _, child in ipairs(spawner:GetChildren()) do if child.Name == "Gear" then add(child, "Gear") end end
                        end
                    end
                end
                -- The inspected map places Gear models below its GearsTest container.
                -- Bounded fallback discovery also covers a late binder initialization.
                if not gearBinder then
                    local map = world:FindFirstChild("Map")
                    map = map and map:FindFirstChild("Ingame")
                    local queue = map and {{map, 0}} or {}
                    local index = 1
                    while index <= #queue and index <= 1200 do
                        local object, depth = queue[index][1], queue[index][2]
                        index += 1
                        if object.Name == "Gear" and object:IsA("Model") then add(object, "Gear")
                        elseif depth < 3 then
                            for _, child in ipairs(object:GetChildren()) do
                                if child:IsA("Folder") or child:IsA("Model") then table.insert(queue, {child, depth + 1}) end
                            end
                        end
                    end
                end
            end
            function adapter:GetIntent(sense, options)
                options = options or {}
                if not allowed(sense) then self:Cancel("Items inactive"); return nil end
                if active then
                    if active.character ~= sense.character then self:Cancel("Character changed"); return nil end
                    local damaged = sense.humanoid.Health < active.lastHealth - 0.05
                    local overheal = tonumber(attr(sense.humanoid, "Overheal", 0)) or 0
                    local lostOverheal = active.itemKind == "Medkit" and overheal + 5 < active.lastOverheal
                    if emergency(sense, active.itemKind) or damaged or lostOverheal then
                        if active.kind == "use" then itemRetry[active.itemKind] = now() + 8 end
                        self:Cancel("Item use cancelled by danger or damage")
                        return nil
                    end
                    active.lastHealth, active.lastOverheal = sense.humanoid.Health, overheal
                    return active
                end
                if emergency(sense) then return nil end
                local owned, count, names = inventory(sense.character)
                if (count >= 2) ~= lastFull then
                    lastFull = count >= 2
                    debugLog(lastFull and "plr's inventory is full, ignoring items" or "plr has inventory room, items allowed again")
                end
                local actorName = sense.actor and sense.actor.ActorName or sense.character.Name
                local ratio = sense.humanoid.Health / math.max(1, sense.humanoid.MaxHealth)
                local medkit = owned.Medkit
                if medkit and actorName ~= "Veeronica" and not sense.fleeing and ratio <= 0.7
                    and (tonumber(sense.killerDistance) or math.huge) >= 65 and now() >= itemRetry.Medkit then
                    return {kind = "use", itemKind = "Medkit", target = medkit, holdMovement = true,
                        windup = tonumber(configs.Medkit.HealTime) or 7, status = "Using medkit"}
                end
                local cola = owned.BloxyCola
                local killerDistance = tonumber(sense.killerDistance) or math.huge
                if cola and killerDistance >= 45 and killerDistance <= 100 and now() >= itemRetry.BloxyCola
                    and (sense.fleeing or options.wantSpeed == true) then
                    return {kind = "use", itemKind = "BloxyCola", target = cola, holdMovement = false,
                        windup = tonumber(configs.BloxyCola.DrinkTime) or 4, status = "Drinking Bloxy Cola"}
                end
                refresh()
                local needGear = options.needGear == true and gears() < 1
                if approach then
                    local intent = approach.intent
                    local target, kind = intent.target, intent.itemKind
                    local needed = (kind == "Gear" and needGear) or (kind ~= "Gear" and count < 2 and not names[string.lower(kind)])
                    if not target.Parent or not target:IsDescendantOf(world) or not intent.prompt.Enabled
                        or intent.prompt.MaxActivationDistance <= 0 or not needed then approach = nil
                    else
                        local itemRoot = rootOf(target)
                        local gap = itemRoot and (itemRoot.Position - sense.root.Position).Magnitude or math.huge
                        if gap < approach.bestGap - 1 then
                            approach.bestGap, approach.lastProgress = gap, now()
                        end
                        local reach = math.max(1, (tonumber(intent.prompt.MaxActivationDistance) or 6) - 1.25)
                        if gap <= reach + 3 then approach.nearSince = approach.nearSince or now() else approach.nearSince = nil end
                        if now() - approach.started > 14 or now() - approach.lastProgress > 3.5
                            or (approach.nearSince and now() - approach.nearSince > 4.5) then
                            self:Skip(intent, 12)
                        else return intent end
                    end
                end
                if now() < pickupPause then return nil end
                local best, bestScore
                for _, candidate in ipairs(cached) do
                    local object, kind = candidate.target, candidate.itemKind
                    if object.Parent and candidate.prompt.Enabled and (retry[object] or 0) <= now()
                        and ((kind == "Gear" and needGear) or (kind ~= "Gear" and count < 2 and not names[string.lower(kind)]
                            and (kind ~= "Medkit" or actorName ~= "Veeronica"))) then
                        local distance = (candidate.root.Position - sense.root.Position).Magnitude
                        if distance <= (tonumber(settings.ItemSearchDistance) or 180) then
                            local priority = kind == "Gear" and 90 or (kind == "Medkit" and (1 - ratio) * 70 or 12)
                            local score = priority - distance * 0.45
                            if not bestScore or score > bestScore then best, bestScore = candidate, score end
                        end
                    end
                end
                if best then
                    local intent = {kind = "pickup", itemKind = best.itemKind, target = best.target, prompt = best.prompt,
                        goal = best.root.Position, holdMovement = false, status = "Collecting " .. best.itemKind}
                    approach = {intent = intent, started = now(), lastProgress = now(), lastPosition = sense.root.Position,
                        bestGap = (best.root.Position - sense.root.Position).Magnitude}
                    return intent
                end
                return nil
            end
            function adapter:Update(sense, intent)
                if not allowed(sense) then self:Cancel("Items inactive"); return false, self.Status end
                intent = active or intent
                if not intent then return false, self.Status end
                if active and active.character ~= sense.character then self:Cancel("Character changed"); return false, self.Status end
                if emergency(sense, intent.itemKind) then self:Cancel("Item interrupted by danger"); return false, self.Status end
                if active and (sense.humanoid.Health < active.lastHealth - 0.05
                    or (active.itemKind == "Medkit" and (tonumber(attr(sense.humanoid, "Overheal", 0)) or 0) + 5 < active.lastOverheal)) then
                    itemRetry[active.itemKind] = now() + 8
                    self:Cancel("Item cancelled by damage")
                    return false, self.Status
                end
                if active then active.lastHealth = sense.humanoid.Health end
                if intent.kind == "pickup" then
                    local prompt, object = intent.prompt, intent.target
                    if active and (not object.Parent or not object:IsDescendantOf(world) or not prompt.Enabled
                        or (intent.itemKind == "Gear" and gears() > active.gearsBefore)) then
                        releasePrompt(); active = nil; self.Status = "Pickup finished"; nextScan = 0
                        return false, self.Status
                    end
                    if not object.Parent or not prompt.Parent or not prompt.Enabled or prompt.MaxActivationDistance <= 0 then
                        self:Cancel("Pickup unavailable"); return false, self.Status
                    end
                    local targetRoot = rootOf(object)
                    if not targetRoot then self:Cancel("Pickup disappeared"); return false, self.Status end
                    intent.goal = targetRoot.Position
                    local distance = (targetRoot.Position - sense.root.Position).Magnitude
                    if not active then
                        if distance > math.max(1, prompt.MaxActivationDistance - 1.25) then return false, intent.status end
                        if prompt.RequiresLineOfSight and not los(sense, targetRoot) then return false, "Approaching pickup line of sight" end
                        active = intent
                        approach = nil
                        active.character, active.started, active.gearsBefore = sense.character, now(), gears()
                        active.lastHealth, active.lastOverheal = sense.humanoid.Health, tonumber(attr(sense.humanoid, "Overheal", 0)) or 0
                        active.holdMovement = true
                        local ok = pcall(function() prompt:InputHoldBegin() end)
                        if ok then heldPrompt, holdBackend = prompt, "prompt"
                        elseif ctx.input and type(ctx.input.SetKey) == "function" then
                            local key = prompt.KeyboardKeyCode or Enum.KeyCode.F
                            local accepted, value = pcall(ctx.input.SetKey, ctx.input, key, true)
                            if not accepted or value ~= true then
                                penalize(object, 12)
                                active = nil
                                return false, "Pickup input unavailable"
                            end
                            heldKey, holdBackend = key, "key"
                        else
                            penalize(object, 12)
                            active = nil
                            return false, "Pickup input unavailable"
                        end
                    end
                    if now() - active.started >= math.max(0.12, prompt.HoldDuration + 0.06) then releasePrompt() end
                    if now() - active.started > math.max(3, prompt.HoldDuration + 2) then
                        penalize(object, 12)
                        self:Cancel("Pickup timed out; trying another item")
                        return false, self.Status
                    end
                    self.Status = "Picking up " .. intent.itemKind
                    return true, self.Status
                end
                local tool = intent.target
                if not active then
                    if not tool or not tool.Parent or tool.Enabled == false then return false, "Item unavailable" end
                    active = intent
                    approach = nil
                    active.character, active.requested, active.stage = sense.character, now(), "equipping"
                    active.lastHealth, active.lastOverheal = sense.humanoid.Health, tonumber(attr(sense.humanoid, "Overheal", 0)) or 0
                    if tool.Parent ~= sense.character then
                        local ok = false
                        if network and type(network.FireServerConnection) == "function" then
                            ok = pcall(network.FireServerConnection, network, "UpdateItemParent", "REMOTE_EVENT", tool)
                        elseif sense.humanoid.EquipTool then ok = pcall(sense.humanoid.EquipTool, sense.humanoid, tool) end
                        if not ok then
                            itemRetry[intent.itemKind] = now() + 5
                            active = nil
                            return false, "Item equip unavailable"
                        end
                    end
                end
                if not tool.Parent then
                    active = nil; self.Status = intent.itemKind .. " consumed"; nextScan = 0
                    return false, self.Status
                end
                if active.stage == "equipping" then
                    if tool.Parent == sense.character then
                        local ok, failure = pcall(function() tool:Activate() end)
                        if not ok then
                            itemRetry[intent.itemKind] = now() + 5
                            self:Cancel("Activation unavailable: " .. tostring(failure))
                            return false, self.Status
                        end
                        active.stage, active.started = "using", now()
                        active.finish = now() + intent.windup
                        itemRetry[intent.itemKind] = active.finish + 4
                    elseif now() - active.requested > 2.5 then
                        itemRetry[intent.itemKind] = now() + 5
                        self:Cancel("Item equip timed out"); return false, self.Status
                    end
                elseif now() > active.finish + 1.5 then
                    self:Cancel("Item windup ended; waiting for server consumption")
                    return false, self.Status
                end
                self.Status = intent.status
                return true, self.Status
            end
            function adapter:Destroy() self:Cancel(); destroyed = true; self.Available = false end
            task.spawn(function()
                local ok, value = pcall(function() return require(rs.Modules.Network.Network) end)
                if ok then network = value end
                local loaded, binder = pcall(function() return require(rs.Systems.Player.Game.Spawners.GearClientBinder) end)
                if loaded then gearBinder = binder end
                for _, kind in ipairs({"Medkit", "BloxyCola"}) do
                    local success, config = pcall(function() return require(rs.Assets.Items[kind].Config) end)
                    if success and type(config) == "table" then configs[kind] = config end
                end
            end)
            return adapter
        end



        -- Normal world awareness: replicated constructs, pickups and active support
        -- effects. This component chooses destinations; it never moves or damages rigs.
        local function createWorldTactics(ctx)
            local adapter = {}
            local world = ctx.workspace or workspace
            local settings = ctx.settings or {}
            local collection = ctx.collectionService
            if not collection then pcall(function() collection = game:GetService("CollectionService") end) end
            local objects, scanAt, active, destroyed = {}, 0, nil, false
            local retry = setmetatable({}, {__mode = "k"})
            local episodeCharacter, episodeRole
            local UP = Vector3.new(0, 1, 0)
            local function flat(v) return Vector3.new(v.X, 0, v.Z) end
            local function unit(v, fallback)
                local f = flat(v)
                return f.Magnitude > 0.001 and f.Unit or fallback or Vector3.new(1, 0, 0)
            end
            local function attr(object, key, fallback)
                local result = object and object.GetAttribute and object:GetAttribute(key)
                return result == nil and fallback or result
            end
            local function rootOf(object)
                if not object or not object.Parent then return nil end
                if object:IsA("BasePart") then return object end
                return object.PrimaryPart or object:FindFirstChild("HumanoidRootPart") or object:FindFirstChild("Root")
                    or object:FindFirstChild("RootPart") or object:FindFirstChildWhichIsA("BasePart", true)
            end
            local function humanoidOf(object)
                return object and object.FindFirstChildOfClass and object:FindFirstChildOfClass("Humanoid")
            end
            local function intact(object)
                if not object or not object.Parent or attr(object, "Destroyed") or attr(object, "Consumed") then return false end
                local hum = humanoidOf(object)
                return not hum or hum.Health > 0
            end
            local function number(value, fallback) return type(value) == "number" and value or fallback end
            local function indexed(value, level, fallback)
                return type(value) == "table" and number(value[level], number(value[1], fallback)) or number(value, fallback)
            end
            local function actorFor(ability, model)
                return ability and ability.GetActor and ability:GetActor(model)
            end
            local function pulseTrack(actor, model)
                local direct = actor.Animations and actor.Animations.Pulse
                if direct and direct.IsPlaying then return direct end
                local config = actor.Config or {}
                local id = config.Animations and config.Animations.Pulse
                id = type(id) == "string" and id:match("%d+") or nil
                local hum = humanoidOf(model)
                local animator = id and hum and hum:FindFirstChildOfClass("Animator")
                if animator then
                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                        if track.IsPlaying and track.Animation and track.Animation.AnimationId:match("%d+") == id then return track end
                    end
                end
                return nil
            end
            local function visible(s, root)
                local params = RaycastParams.new()
                params.FilterType, params.RespectCanCollide = Enum.RaycastFilterType.Exclude, true
                params.FilterDescendantsInstances = {s.character, root.Parent, world:FindFirstChild("Players")}
                return world:Raycast(s.root.Position, root.Position - s.root.Position, params) == nil
            end
            local function ground(s, point)
                local movement = ctx.getMovement and ctx.getMovement()
                if not movement then return nil end
                local params = movement:_rayParams(s.character)
                local hit = world:Raycast(point + UP * 7, -UP * 18, params)
                if not movement:_safeSurface(hit) then return nil end
                local goal = hit.Position + UP * movement:_standHeight(s.root, s.humanoid)
                if math.abs(goal.Y - point.Y) > 9 then return nil end
                return goal
            end
            local function scan(s)
                local found, seen = {}, {}
                local function add(object)
                    if object and object.Parent and not seen[object] and (object:IsA("Model") or object:IsA("BasePart")) then
                        seen[object] = true; table.insert(found, object)
                    end
                end
                local function children(folder, depth)
                    if not folder or depth < 0 then return end
                    for _, object in ipairs(folder:GetChildren()) do
                        add(object)
                        -- The map itself is a Model; don't mistake decorative scene
                        -- shadows or held accessories for freshly placed ability objects.
                        if object:IsA("Folder") then children(object, depth - 1) end
                    end
                end
                local map = world:FindFirstChild("Map")
                children(map and map:FindFirstChild("Ingame"), 2)
                local playerFolder = world:FindFirstChild("Players")
                if playerFolder then
                    for _, folder in ipairs(playerFolder:GetChildren()) do
                        if folder.Name ~= "Survivors" and folder.Name ~= "Killers" and folder.Name ~= "Spectating" then children(folder, 1) end
                    end
                end
                if collection and collection.GetTagged then
                    for _, object in ipairs(collection:GetTagged("SurvivorConstruct")) do add(object) end
                end
                objects, scanAt = found, s.now + 0.6
            end
            local function profiles(s, ability)
                local p = {names = {}, minionNames = {}, pulse = {}, actors = {}}
                local function register(template, kind, data)
                    if template and template.Name then p.names[template.Name] = {kind = kind, data = data} end
                end
                local function minion(template, kind, radius, config)
                    if not template then return end
                    local data = {kind = kind, radius = radius, config = config}
                    if template:IsA("Folder") then
                        for _, child in ipairs(template:GetChildren()) do if child:IsA("Model") then p.minionNames[child.Name] = data end end
                    else p.minionNames[template.Name] = data end
                end
                for _, list in ipairs({s.killers or {}, s.survivors or {}}) do
                    for _, model in ipairs(list) do
                        p.actors[model] = true
                        local actor = actorFor(ability, model)
                        if actor then
                            local name, config = actor.ActorName, actor.Config or {}
                            local instances = config.Instances or {}
                            if name == "Azure" then
                                register(instances.GroundBulbModel, "azureBulb", config.ConstructConfigs and config.ConstructConfigs.GroundBulb)
                                register(instances.VineModel, "azureVine", config.ConstructConfigs and config.ConstructConfigs.Vine)
                            elseif name == "JohnDoe" or name == "!JohnDoe_MARCH" then register(instances.Shadow, "footprint", config)
                            elseif name == "c00lkidd" or name == "Irisc00lkiddOverhaul" then
                                minion(instances.PizzaDeliveryRig or config.PizzaDeliveryRig, "deliveryMinion", number(config.PizzaDeliveryGuyAttackRadius, 6) + 5, config)
                            elseif name == "1x1x1x1" then
                                minion(instances.ZombieTemplate, "zombie", number(config.ZombieAttackRange, 5) + 5, config)
                            elseif name == "Builderman" then p.builder = config
                            elseif name == "Taph" then p.taph = config
                            elseif name == "Elliot" then register(instances.CustomPizza, "pizza", config)
                            elseif name == "Helperbot" then
                                local pulse = pulseTrack(actor, model)
                                if pulse and pulse.IsPlaying then
                                    local cfg = config.SonicPulse or {}
                                    local level = actor.State and actor.State.ChargeLevels and actor.State.ChargeLevels.Pulse or 1
                                    local radius = indexed(cfg.Radius, level, 30)
                                    local untilEmit = number(cfg.Windup, 2) + 0.6 - number(pulse.TimePosition, 0)
                                    if untilEmit > 0 then table.insert(p.pulse, {model = model, root = rootOf(model), kind = "pulse", radius = radius,
                                        duration = untilEmit, config = cfg}) end
                                end
                            end
                        end
                    end
                end
                return p
            end
            local function classify(object, p)
                local name = object.Name
                if p.actors[object] or not intact(object) then return nil end
                if attr(object, "Fake") or attr(object, "Hallucination") or name:lower():find("fake", 1, true) then return nil end
                if name == "BuildermanSentry" then return "sentry" end
                if name == "BuildermanDispenser" then return "dispenser" end
                if name:find("TaphTripwire", 1, true) and humanoidOf(object) then return "tripwire" end
                if attr(object, "TripmineId") ~= nil then return "tripmine" end
                local match = p.names[name]
                if match then return match.kind, match.data end
                if name == "GroundBulbModel" then return "azureBulb" end
                if name == "VineModel" then return "azureVine" end
                if name == "Shadow" or name == "DigitalFootprint" then
                    -- Runtime Shadow is a loose Part in Map.Ingame with the glitch
                    -- number emitter; scenery shadows live inside the Map model.
                    if object:IsA("BasePart") and object:FindFirstChild("Number") then return "footprint" end
                end
                local minion = p.minionNames[name]
                if humanoidOf(object) and attr(object, "Team") ~= "Survivors" and (minion or attr(object, "Team") == "Killers") then
                    return minion and minion.kind or "killerMinion", minion
                end
                if name == "Pizza" and object:IsA("BasePart") and object.CollisionGroup == "Items"
                    and not object:FindFirstChild("PizzaJoint") then return "pizza" end
                return nil
            end
            local function targetRoot(object, kind, s)
                local result = rootOf(object)
                if kind == "tripwire" then
                    for _, key in ipairs({"Hook1", "Hook2"}) do
                        local hook = object:FindFirstChild(key)
                        if hook and hook:IsA("BasePart") and (not result or (hook.Position - s.root.Position).Magnitude < (result.Position - s.root.Position).Magnitude) then
                            result = hook
                        end
                    end
                end
                return result
            end
            local function hazardRisk(point, hazards)
                local score = 0
                for _, h in ipairs(hazards) do
                    local d = flat(point - h.position).Magnitude
                    if math.abs(point.Y - h.position.Y) < 9 and d < h.radius + 3 then
                        score += (h.radius + 3 - d) * (h.walkOnly and 1 or 8)
                    end
                end
                return score
            end
            local function escape(s, minion, hazards)
                if active and active.intent.kind == "hazardEscape" and s.now < active.untilTime
                    and (active.intent.goal - s.root.Position).Magnitude > 3 then return active.intent end
                local movement = ctx.getMovement and ctx.getMovement()
                if not movement then return nil end
                local params = movement:_rayParams(s.character)
                local away = unit(s.root.Position - minion.position)
                local best, bestScore
                for _, radius in ipairs({28, 20, 12}) do
                    for _, degrees in ipairs({0, 35, -35, 70, -70, 110, -110, 150, -150, 180}) do
                        local a = math.rad(degrees)
                        local direction = Vector3.new(away.X * math.cos(a) - away.Z * math.sin(a), 0, away.X * math.sin(a) + away.Z * math.cos(a))
                        local goal = ground(s, s.root.Position + direction * radius)
                        if goal and movement:_clearLine(s.root.Position, goal, params) then
                            local score = flat(goal - minion.position).Magnitude * 3 - hazardRisk(goal, hazards)
                            if s.killerRoot then score += math.min((goal - s.killerRoot.Position).Magnitude, 80) end
                            if not bestScore or score > bestScore then best, bestScore = goal, score end
                        end
                    end
                end
                if not best then return nil end
                local intent = {kind = "hazardEscape", goal = best, sprint = true, arrival = 2,
                    targetModel = minion.model, targetRoot = minion.root, label = "AVOIDING MINION", priority = 85}
                active = {intent = intent, untilTime = s.now + 1.1}
                return intent
            end
            local function destination(s, entry)
                local root = entry.root
                if not root or not root.Parent then return nil end
                if entry.kind == "pizza" then return ground(s, root.Position) end
                local offset = (entry.kind == "dispenser" or entry.kind == "pulse")
                    and math.max(3, entry.radius - 3) or 4.5
                return ground(s, root.Position + unit(s.root.Position - root.Position) * offset)
            end
            local function intentFor(s, entry, kind)
                local goal = destination(s, entry)
                if not goal then return nil end
                local distance = (entry.root.Position - s.root.Position).Magnitude
                local hold = kind == "heal" and entry.kind ~= "pizza" and distance <= entry.radius - 1 and visible(s, entry.root)
                return {kind = kind, goal = hold and s.root.Position or goal, targetRoot = entry.root, targetModel = entry.model,
                    source = entry.kind, holdMovement = hold, sprint = distance > 20, arrival = entry.kind == "pizza" and 0.6 or 1.2,
                    label = kind == "destroy" and "CLEARING " .. entry.kind:upper() or entry.kind == "pizza" and "COLLECTING PIZZA"
                        or entry.kind == "pulse" and "SEEKING HEALING PULSE" or "HEALING AT DISPENSER",
                    priority = kind == "destroy" and 40 or 35}
            end
            function adapter:Update(s, ability)
                local result = {hazards = {}, noSprint = false, quietAbilities = false}
                if destroyed or not s.root or not s.humanoid or s.humanoid.Health <= 0 then self:Reset(); return result end
                if episodeCharacter ~= s.character or episodeRole ~= s.role then
                    self:Reset(); episodeCharacter, episodeRole = s.character, s.role
                end
                if s.now >= scanAt then scan(s) end
                local p = profiles(s, ability)
                local heals, destructibles, byModel, minion, minionDistance = {}, {}, {}, nil, math.huge
                for _, object in ipairs(objects) do
                    local kind, data = classify(object, p)
                    local root = kind and targetRoot(object, kind, s)
                    if root then
                        local distance = (root.Position - s.root.Position).Magnitude
                        if distance < 180 then
                            local entry = {kind = kind, model = object, root = root, radius = 0, distance = distance}
                            byModel[object] = entry
                            if s.role == "Survivor" then
                                if kind == "azureBulb" or kind == "azureVine" or kind == "footprint" or kind:find("Minion") or kind == "deliveryMinion" or kind == "zombie" then
                                    local isPlant = kind == "azureBulb" or kind == "azureVine"
                                    local dynamic = kind:find("Minion") ~= nil or kind == "deliveryMinion" or kind == "zombie"
                                    local radius = isPlant and number(data and data.Radius, kind == "azureBulb" and 30 or 20)
                                        or dynamic and number(data and data.radius, 11)
                                        or math.max(4, root.Size and math.max(root.Size.X, root.Size.Z) * 0.5 + 2 or 6)
                                    local hazard = {kind = kind, model = object, root = root, position = root.Position, radius = radius,
                                        avoid = true, walkOnly = isPlant, dynamic = dynamic, soft = false}
                                    table.insert(result.hazards, hazard)
                                    if isPlant and distance <= radius + 3 and (s.killerDistance or math.huge) > 24 then
                                        result.noSprint, result.quietAbilities = true, true
                                    end
                                    if dynamic and distance < minionDistance and distance < 23 and visible(s, root) then minion, minionDistance = hazard, distance end
                                elseif kind == "dispenser" and attr(object, "Constructed") == true and not attr(object, "Disabled") and not attr(object, "Carrying") then
                                    entry.radius = number(attr(object, "EffectRadiusSize"), number(p.builder and p.builder.DispenserHealingRadius, 16)) * 0.5
                                    entry.healable = true
                                    table.insert(heals, entry)
                                elseif kind == "pizza" then entry.radius, entry.healable = 1, true; table.insert(heals, entry) end
                            elseif s.role == "Killer" then
                                if kind == "tripmine" then
                                    table.insert(result.hazards, {kind = kind, model = object, root = root, position = root.Position,
                                        radius = number(p.taph and p.taph.SubspaceRange, 19) * 0.5 + 2, avoid = true, soft = true})
                                elseif kind == "sentry" or kind == "dispenser" or kind == "tripwire" then
                                    if humanoidOf(object) and not attr(object, "Carrying") then entry.destructible = true; table.insert(destructibles, entry) end
                                end
                            end
                        end
                    end
                end
                local canHeal = s.role == "Survivor" and s.humanoid.Health < s.humanoid.MaxHealth - 1
                    and not (s.actor and s.actor.ActorName == "Veeronica") and not attr(s.humanoid, "Clanker")
                    and not s.incomingAttack and not s.underAttack and not s.damaged and not s.evading
                    and (s.killerDistance or math.huge) > 45 and not minion
                if canHeal then
                    for _, entry in ipairs(p.pulse) do
                        if entry.root and entry.root.Parent and intact(entry.model) then
                            entry.distance = (entry.root.Position - s.root.Position).Magnitude
                            local enterTime = math.max(0, entry.distance - entry.radius + 3) / math.max(s.humanoid.WalkSpeed or 12, 6)
                            if entry.distance < entry.radius + 20 and enterTime < entry.duration and visible(s, entry.root) then
                                entry.healable = true
                                byModel[entry.model] = entry; table.insert(heals, entry)
                            end
                        end
                    end
                end
                if minion and not s.movementLocked then
                    result.minionThreat = minion
                    result.intent = escape(s, minion, result.hazards)
                    return result
                end
                if active and active.intent.kind == "hazardEscape" then active = nil end
                if active then
                    local entry = byModel[active.intent.targetModel]
                    local kind = active.intent.kind
                    local valid = entry and intact(entry.model) and (kind == "heal" and canHeal and entry.healable or kind == "destroy" and entry.destructible)
                        and not s.movementLocked and not s.evading and not s.incomingAttack
                    if kind == "destroy" and (s.targetDistance or math.huge) < 8 then valid = false end
                    if valid then
                        local progress = (s.root.Position - active.lastPosition).Magnitude >= 3
                        local health = kind == "heal" and s.humanoid.Health or humanoidOf(entry.model).Health
                        if progress or (kind == "heal" and health > active.lastHealth + 0.1) or (kind == "destroy" and health < active.lastHealth - 0.1) then
                            active.lastProgress, active.lastPosition, active.lastHealth = s.now, s.root.Position, health
                        end
                        if s.now - active.lastProgress > (kind == "heal" and 6 or 5) or s.now - active.started > 60 then
                            retry[entry.model] = s.now + 12; valid = false
                        end
                    end
                    if valid then
                        local intent = intentFor(s, entry, kind)
                        if intent then active.intent = intent; result.intent = intent; return result end
                    end
                    active = nil
                end
                if s.movementLocked or s.evading or s.incomingAttack then return result end
                local candidates, intentKind = canHeal and heals or {}, "heal"
                if s.role == "Killer" and (s.targetDistance or math.huge) >= 8 then candidates, intentKind = destructibles, "destroy" end
                local best, bestScore
                for _, entry in ipairs(candidates) do
                    local limit = intentKind == "destroy" and ((s.targetDistance or math.huge) < 25 and 10 or 18) or 100
                    local danger = s.role == "Survivor" and s.killerRoot and (entry.root.Position - s.killerRoot.Position).Magnitude < 32
                    if entry.distance <= limit and not danger and (retry[entry.model] or 0) <= s.now
                        and (intentKind ~= "destroy" or visible(s, entry.root)) then
                        local score = entry.distance + hazardRisk(entry.root.Position, result.hazards)
                        if entry.kind == "pulse" then score -= 18 elseif entry.kind == "pizza" then score -= 12 end
                        if not bestScore or score < bestScore then best, bestScore = entry, score end
                    end
                end
                if best then
                    local intent = intentFor(s, best, intentKind)
                    if intent then
                        active = {intent = intent, started = s.now, lastProgress = s.now, lastPosition = s.root.Position,
                            lastHealth = intentKind == "heal" and s.humanoid.Health or humanoidOf(best.model).Health}
                        result.intent = intent
                    end
                end
                return result
            end
            function adapter:Reset()
                objects, scanAt, active = {}, 0, nil
                retry = setmetatable({}, {__mode = "k"})
                episodeCharacter, episodeRole = nil, nil
            end
            function adapter:Destroy() self:Reset(); destroyed = true end
            return adapter
        end


        -- Headless UI stub: the autopilot's own GUI was removed, controls live in the "automation" tab.
        local UI = {Destroyed = false}
        function UI:UpdateEnabled() end
        function UI:Destroy() self.Destroyed = true end
        Bot.UI = UI
        local fit = function() end
        local statusLabel, actorLabel, targetLabel = {Text = ""}, {Text = ""}, {Text = ""}
        local staminaLabel, noticeLabel, diagnosticsLabel = {Text = ""}, {Text = ""}, {Text = ""}
        local fill = {Size = UDim2.fromScale(0, 1)}
        Bot.Labels = {status = statusLabel, actor = actorLabel, target = targetLabel, stamina = staminaLabel,
            notice = noticeLabel, diagnostics = diagnosticsLabel, fill = fill}

        local activeCharacter, targetModel, generatorModel, roamGoal, fleeGoal, fleeingKiller
        local activeRole
        local lastHealth, previousKiller, previousDistance, previousSenseAt
        local fleeStart, fleeExit, nextFleeGoal, nextRoamGoal, nextGeneratorScan, lastThreat = 0, 0, 0, 0, 0, 0
        local lastCircleEvents, circleStrikes = 0, {}
        local idleAnchor, idleSince = nil, 0
        local targetChangedAt = 0
        local componentGeneration = 0
        local componentStatus = {}
        local lastSense, lastAbility = {}, "—"
        local activeHelp
        local searchEpoch, escapeEpisode = 0, 0
        local pendingKind, pendingAt = nil, 0
        local nextBackupSearch, nextRoamSearch = 0, 0
        local fleeProgressPoint, fleeProgressAt, roamProgressPoint, roamProgressAt
        local fleeBackupActive = false
        local fleeTransitActive, fleeTransitUntil, nextTransitProbe = false, 0, 0
        local failedEscapes, recentRoam = {}, {}
        local queuedRoam, roamProvisional

        local function safely(object, method)
            if object and object[method] then pcall(object[method], object) end
        end
        local function cancelSearch()
            searchEpoch += 1
            pendingKind, pendingAt = nil, 0
            safely(Bot.Planner, "Cancel")
            queuedRoam = nil
        end
        local function resetNavigation()
            cancelSearch()
            escapeEpisode += 1
            fleeBackupActive = false
            fleeTransitActive, fleeTransitUntil, nextTransitProbe = false, 0, 0
            fleeProgressPoint, fleeProgressAt, roamProgressPoint, roamProgressAt = nil, nil, nil, nil
            failedEscapes, recentRoam = {}, {}
            queuedRoam, roamProvisional = nil, false
            nextBackupSearch, nextRoamSearch = 0, 0
            activeHelp = nil
            safely(Bot.Assist, "Reset")
            safely(Bot.Combat, "Reset")
            safely(Bot.Items, "Cancel")
            safely(Bot.World, "Reset")
        end
        local function remember(list, point)
            if not point then return end
            for _, old in ipairs(list) do
                if flat(point - old).Magnitude < 18 then return end
            end
            table.insert(list, point)
            if #list > 6 then table.remove(list, 1) end
        end
        local function cancelObjectives()
            if Bot.Generators then Bot.Generators:Cancel() end
            generatorModel = nil
        end
        function Bot:SetEnabled(enabled)
            if self.Destroyed then return end
            self.Enabled = enabled == true
            if not self.Enabled then
                resetNavigation()
                safely(self.Movement, "Stop")
                safely(self.Generators, "Cancel")
                safely(self.Ability, "Reset")
                Input:ReleaseAll()
                self.State = "DISABLED"
                fleeGoal, fleeingKiller, generatorModel, targetModel, roamGoal = nil, nil, nil, nil, nil
                activeCharacter, activeRole, lastHealth = nil, nil, nil
                previousKiller, previousDistance, previousSenseAt = nil, nil, nil
            else
                notify("Autopilot enabled. Waiting for an active character.")
            end
        end
        function Bot:Destroy()
            if self.Destroyed then return end
            self:SetEnabled(false)
            self.Destroyed = true
            componentGeneration += 1
            safely(self.Movement, "Destroy")
            safely(self.Ability, "Destroy")
            safely(self.Generators, "Destroy")
            safely(self.Planner, "Destroy")
            safely(self.Assist, "Destroy")
            safely(self.Combat, "Destroy")
            safely(self.Items, "Destroy")
            safely(self.World, "Destroy")
            safely(self.UI, "Destroy")
            for _, connection in ipairs(connections) do connection:Disconnect() end
            Input:ReleaseAll()
            if env.ForsakenAutopilot == self then env.ForsakenAutopilot = nil end
        end
        function Bot:LoadIntegrations()
            if self.Destroyed then return end
            resetNavigation()
            componentGeneration += 1
            local generation = componentGeneration
            safely(self.Movement, "Destroy")
            safely(self.Ability, "Destroy")
            safely(self.Generators, "Destroy")
            safely(self.Planner, "Destroy")
            safely(self.Assist, "Destroy")
            safely(self.Combat, "Destroy")
            safely(self.Items, "Destroy")
            safely(self.World, "Destroy")
            self.Movement, self.Ability, self.Generators, self.Planner, self.Assist = nil, nil, nil, nil, nil
            self.Combat, self.Items = nil, nil
            self.World = nil
            componentStatus = {Movement = "loading", Ability = "loading", Generators = "loading", Planner = "loading", Assist = "loading"}
            local constructors = {
                Movement = function() return Movement.new(ctx) end,
                Ability = function() return Ability.new(ctx) end,
                Generators = function() return createGenerators(ctx) end,
                Planner = function() return createDestinationPlanner(ctx) end,
                Assist = function() return createAssistController(ctx) end,
                Combat = function() return createCombatNavigation(ctx) end,
                Items = function() return createItems(ctx) end,
                World = function() return createWorldTactics(ctx) end,
            }
            for name, constructor in pairs(constructors) do
                task.spawn(function()
                    local ok, result = pcall(constructor)
                    if self.Destroyed or generation ~= componentGeneration then
                        if ok then safely(result, "Destroy") end
                        return
                    end
                    if ok then
                        self[name] = result
                        componentStatus[name] = "ready"
                    else
                        componentStatus[name] = "unavailable"
                        notify(name .. ": " .. tostring(result))
                    end
                end)
            end
        end

        local function modelsIn(name)
            local folder = workspace:FindFirstChild("Players")
            folder = folder and folder:FindFirstChild(name)
            return folder and folder:GetChildren() or {}
        end
        local function nearest(models, root, preferred)
            local best, bestRoot, bestDistance = nil, nil, math.huge
            local oldRoot = body(preferred)
            local oldDistance = oldRoot and (oldRoot.Position - root.Position).Magnitude or math.huge
            for _, model in ipairs(models) do
                if model ~= root.Parent then
                    local r = body(model)
                    if r then
                        local distance = (r.Position - root.Position).Magnitude
                        if distance < bestDistance then best, bestRoot, bestDistance = model, r, distance end
                    end
                end
            end
            -- A small advantage is insufficient to switch targets every thought tick.
            if oldRoot and best and best ~= preferred and oldDistance < bestDistance * 1.4 then
                return preferred, oldRoot, oldDistance
            end
            if oldRoot and os.clock() - targetChangedAt < 2 and oldDistance < bestDistance + 24 then
                return preferred, oldRoot, oldDistance
            end
            return best, bestRoot, bestDistance
        end

        local function chooseFleeGoal(sense)
            local root, killer = sense.root, sense.killerRoot
            if not killer then return nil end
            local away = unit(flat(root.Position - killer.Position), unit(flat(root.CFrame.LookVector)))
            local momentum = unit(flat(root.AssemblyLinearVelocity), away)
            local best, bestScore, bestCorridor, bestGain = nil, -math.huge, false, 0
            for _, radius in ipairs({40, 25, 15}) do
                for _, degrees in ipairs({0, 22, -22, 45, -45, 70, -70, 100, -100}) do
                    local theta = math.rad(degrees)
                    local dir = Vector3.new(away.X * math.cos(theta) - away.Z * math.sin(theta), 0, away.X * math.sin(theta) + away.Z * math.cos(theta))
                    local p = ground(root.Position + dir * radius, sense.character)
                    if p then
                        local gain = (p - killer.Position).Magnitude - sense.killerDistance
                        local corridor = visible(root.Position, p, sense.character)
                        local score = gain * 3 + dir:Dot(momentum) * 18 + (corridor and 80 or 0) + radius * 0.08
                        if gain < -3 then score -= 60 end
                        if score > bestScore then best, bestScore, bestCorridor, bestGain = p, score, corridor, gain end
                    end
                end
                if best and bestScore > 15 then break end
            end
            return best, not best or not bestCorridor or bestGain < 4
        end
        local function chooseRoamGoal(sense)
            local best, bestScore
            local low = tonumber(Settings.RoamMinDistance) or 50
            local high = math.max(low, tonumber(Settings.RoamMaxDistance) or 100)
            local heading = unit(flat(sense.root.AssemblyLinearVelocity), unit(flat(sense.root.CFrame.LookVector)))
            for _ = 1, 16 do
                local theta = math.random() * math.pi * 2
                local radius = math.random(low, high)
                local p = ground(sense.root.Position + Vector3.new(math.cos(theta) * radius, 0, math.sin(theta) * radius), sense.character)
                if p then
                    local score = (visible(sense.root.Position, p, sense.character) and 30 or 0) + radius * 0.15
                    score += unit(flat(p - sense.root.Position)):Dot(heading) * 40
                    if sense.killerRoot then score += math.min((p - sense.killerRoot.Position).Magnitude, 100) * 0.3 end
                    for _, old in ipairs(recentRoam) do
                        if flat(p - old).Magnitude < 25 then score -= 120 end
                    end
                    if not bestScore or score > bestScore then best, bestScore = p, score end
                end
            end
            return best
        end

        -- A corner exit may initially lead toward or past the killer. Check the actual
        -- walkable corridor in every direction rather than waiting against the wall.
        local function chooseExitStep(sense)
            local movement = Bot.Movement
            local params = movement and movement._rayParams and movement:_rayParams(sense.character)
            local away = sense.killerRoot and unit(flat(sense.root.Position - sense.killerRoot.Position))
                or unit(flat(sense.root.CFrame.LookVector))
            local momentum = unit(flat(sense.root.AssemblyLinearVelocity), away)
            local best, bestScore
            for _, degrees in ipairs({0, 30, -30, 60, -60, 90, -90, 120, -120, 150, -150, 180}) do
                local angle = math.rad(degrees)
                local direction = Vector3.new(away.X * math.cos(angle) - away.Z * math.sin(angle), 0,
                    away.X * math.sin(angle) + away.Z * math.cos(angle))
                for _, radius in ipairs({32, 24, 16, 8}) do
                    local point = ground(sense.root.Position + direction * radius, sense.character)
                    if point then
                        local clear
                        if params and movement._clearLine then clear = movement:_clearLine(sense.root.Position, point, params)
                        else clear = visible(sense.root.Position, point, sense.character) end
                        if clear and params and movement._safeSurface and workspace.Raycast then
                            local height = movement:_standHeight(sense.root, sense.humanoid)
                            clear = movement:_safeSurface(workspace:Raycast(point + Vector3.new(0, 1, 0), Vector3.new(0, -(height + 3), 0), params))
                        end
                        if clear then
                            -- Separation is a preference here. A needed exit through
                            -- the killer's side must beat an unusable goal in a wall.
                            local score = radius * 3 + direction:Dot(momentum) * 12 + direction:Dot(away) * 4
                            if not bestScore or score > bestScore then best, bestScore = point, score end
                            break
                        end
                    end
                end
            end
            return best
        end

        local function canMeasureProgress(sense)
            if sense.movementLocked or sense.root.Anchored then return false end
            local h = sense.humanoid
            if h.WalkSpeed and h.WalkSpeed <= 0.1 then return false end
            if h.FloorMaterial == Enum.Material.Air then return false end
            if sense.character.GetAttribute and sense.character:GetAttribute("Ragdolling") then return false end
            local m = Bot.Movement
            local d = m and m.GetDiagnostics and m:GetDiagnostics()
            return not (d and d.dropping)
        end
        local function stalled(sense, escaping)
            local movement = Bot.Movement
            if movement and movement.TakeCircleFlag and movement:TakeCircleFlag() then
                if escaping then fleeProgressPoint, fleeProgressAt = sense.root.Position, sense.now
                else roamProgressPoint, roamProgressAt = sense.root.Position, sense.now end
                return true
            end
            local point, at
            if escaping then point, at = fleeProgressPoint, fleeProgressAt
            else point, at = roamProgressPoint, roamProgressAt end
            if not point or not at or not canMeasureProgress(sense) or flat(sense.root.Position - point).Magnitude >= 3 then
                if escaping then fleeProgressPoint, fleeProgressAt = sense.root.Position, sense.now
                else roamProgressPoint, roamProgressAt = sense.root.Position, sense.now end
                return false
            end
            local reaction = (sense.killerDistance or math.huge) <= 24 and (Settings.CornerReactionTime or 0.75) or 1.5
            return sense.now - at >= (escaping and reaction or 4)
        end
        local function beginDestination(sense, kind)
            local planner = Bot.Planner
            if not planner then return false end
            if pendingKind then
                if sense.now - pendingAt < 8 then return false end
                cancelSearch()
            end
            if planner:IsBusy() then return false end
            local escaping = kind == "escape"
            if sense.now < (escaping and nextBackupSearch or nextRoamSearch) then return false end
            local epoch, episode, character = searchEpoch + 1, escapeEpisode, sense.character
            local origin = sense.root.Position
            searchEpoch, pendingKind, pendingAt = epoch, kind, sense.now
            local options = {
                kind = kind,
                minDistance = escaping and (Settings.BackupMinDistance or 100) or (Settings.RoamMinDistance or 50),
                maxDistance = escaping and (Settings.BackupMaxDistance or 150) or (Settings.RoamMaxDistance or 100),
                avoidGoals = escaping and failedEscapes or recentRoam,
                urgent = escaping,
                allowKillerPass = escaping,
                heading = not escaping and roamGoal and flat(roamGoal - sense.root.Position) or flat(sense.root.AssemblyLinearVelocity),
                isCurrent = function()
                    return not Bot.Destroyed and Bot.Enabled and searchEpoch == epoch and LocalPlayer.Character == character
                        and (not escaping or (escapeEpisode == episode and fleeingKiller ~= nil))
                end,
            }
            if escaping then nextBackupSearch = sense.now + 0.75 else nextRoamSearch = sense.now + 3 end
            local accepted = planner:Request(sense, options, function(goal, metadata)
                if searchEpoch ~= epoch then return end
                pendingKind, pendingAt = nil, 0
                local currentRoot, currentHumanoid = body(LocalPlayer.Character)
                if Bot.Destroyed or not Bot.Enabled or LocalPlayer.Character ~= character or not currentRoot or not currentHumanoid then return end
                local now = os.clock()
                if escaping then
                    if escapeEpisode ~= episode or not fleeingKiller or lastSense.role ~= "Survivor" then return end
                    local killerRoot = body(fleeingKiller)
                    if goal and killerRoot and (goal - killerRoot.Position).Magnitude < 35 then goal = nil end
                    local adoptionFailed = false
                    if goal and Bot.Movement and Bot.Movement.FollowRoute and metadata and metadata.route then
                        local adopted = Bot.Movement:FollowRoute(goal, metadata, {mode = "flee", sprint = true,
                            emergency = Settings.EmergencySprint and (lastSense.killerDistance or math.huge) < Settings.EmergencyDistance,
                            arrival = 3, target = fleeingKiller})
                        if not adopted then goal, adoptionFailed = nil, true end
                    end
                    if goal then
                        fleeGoal, fleeBackupActive = goal, true
                        fleeTransitActive, fleeTransitUntil = false, 0
                        nextFleeGoal = math.huge
                        fleeProgressPoint, fleeProgressAt = currentRoot.Position, now
                        notify("Corner exit: following the escape route, including past the killer when needed.")
                    else
                        nextBackupSearch = now + (adoptionFailed and 0.35 or 0.75)
                        notify("Checking another distant exit; continuing through the open corridor.")
                    end
                else
                    if fleeingKiller or activeHelp then return end
                    if goal then
                        remember(recentRoam, origin)
                        -- Prefetch the next leg, but don't turn back toward it halfway
                        -- through a perfectly good current route.
                        queuedRoam = {goal = goal, metadata = metadata, origin = origin, at = now}
                        if roamProvisional or not roamGoal then nextRoamGoal = 0 end
                    else
                        nextRoamSearch = now + 3
                        if not roamGoal then notify("Searching for a reachable roaming destination.") end
                    end
                end
            end)
            if not accepted and searchEpoch == epoch then pendingKind, pendingAt = nil, 0 end
            return accepted
        end
        local function roam(sense)
            local movement = Bot.Movement
            local reached = roamGoal and movement:Reached()
            local blocked = roamGoal and stalled(sense, false)
            if reached then remember(recentRoam, roamGoal) end
            if queuedRoam and (not roamGoal or reached or blocked or roamProvisional) then
                local nextLeg = queuedRoam
                local adopted = true
                if movement.FollowRoute and nextLeg.metadata and nextLeg.metadata.route then
                    adopted = movement:FollowRoute(nextLeg.goal, nextLeg.metadata, {mode = "travel",
                        sprint = sense.role == "Killer" or (nextLeg.goal - sense.root.Position).Magnitude > Settings.LongSprintDistance, arrival = 4})
                end
                queuedRoam = nil
                if adopted then
                    roamProvisional = false
                    roamGoal, nextRoamGoal = nextLeg.goal, math.huge
                    roamProgressPoint, roamProgressAt = sense.root.Position, sense.now
                    reached, blocked = false, false
                else
                    nextRoamSearch = 0
                end
            end
            local nearFinish = roamGoal and flat(roamGoal - sense.root.Position).Magnitude < 22
                and visible(sense.root.Position, roamGoal, sense.character)
            if not queuedRoam and (not roamGoal or reached or blocked or nearFinish) then
                if blocked then remember(recentRoam, roamGoal) end
                beginDestination(sense, "roam")
                -- Keep an existing route while the background search tests alternatives.
                -- The initial local choice also stays inside the requested 50–100 ring.
                if not roamGoal or reached or blocked then
                    roamGoal = chooseRoamGoal(sense)
                    roamProvisional = Bot.Planner ~= nil
                    nextRoamGoal = math.huge
                    roamProgressPoint, roamProgressAt = sense.root.Position, sense.now
                end
            end
            if roamGoal then
                movement:SetGoal(roamGoal, {mode = "travel", sprint = sense.role == "Killer" or (roamGoal - sense.root.Position).Magnitude > Settings.LongSprintDistance, arrival = 4})
            elseif not pendingKind then
                movement:Stop()
                notify("Waiting for reachable map ground.")
            end
        end

        local function senseWorld()
            local character = LocalPlayer.Character
            local root, humanoid = body(character)
            if not root then return nil end
            if activeCharacter ~= character then
                resetNavigation()
                safely(Bot.Movement, "Stop")
                safely(Bot.Generators, "Cancel")
                safely(Bot.Ability, "Reset")
                activeCharacter, activeRole, lastHealth = character, nil, humanoid.Health
                targetModel, generatorModel, roamGoal, fleeGoal, fleeingKiller = nil, nil, nil, nil, nil
                previousKiller, previousDistance, previousSenseAt = nil, nil, nil
                nextGeneratorScan, nextRoamGoal = 0, 0
            end
            local actor = Bot.Ability and Bot.Ability:GetActor()
            local role = actor and actor.ActorType or (character.Parent and character.Parent.Name)
            if role and role:find("Killer") then role = "Killer"
            elseif role and role:find("Survivor") then role = "Survivor"
            else role = "Lobby" end
            if activeRole and activeRole ~= role then
                resetNavigation()
                safely(Bot.Movement, "Stop")
                safely(Bot.Generators, "Cancel")
                safely(Bot.Ability, "Reset")
                targetModel, generatorModel, roamGoal, fleeGoal, fleeingKiller = nil, nil, nil, nil, nil
                previousKiller, previousDistance, previousSenseAt = nil, nil, nil
                nextGeneratorScan, nextRoamGoal = 0, 0
                lastHealth = humanoid.Health
            end
            activeRole = role
            local now = os.clock()
            local killers = modelsIn("Killers")
            local killerModel, killerRoot, killerDistance = nearest(killers, root, fleeingKiller)
            local victim, victimRoot, victimDistance
            if role == "Killer" then victim, victimRoot, victimDistance = nearest(modelsIn("Survivors"), root, targetModel) end
            local stamina = Bot.Movement and Bot.Movement:GetStamina()
            local s = {
                character = character, root = root, humanoid = humanoid, role = role, actor = actor,
                now = now, stamina = stamina, killers = killers, survivors = modelsIn("Survivors"),
                killerModel = killerModel, killerRoot = killerRoot, killerDistance = killerDistance,
                targetModel = victim, targetRoot = victimRoot, targetDistance = victimDistance,
                damaged = lastHealth and humanoid.Health < lastHealth - 0.1,
                fleeing = fleeingKiller ~= nil,
                movementLocked = Bot.Ability and Bot.Ability:MovementLocked() or false,
            }
            local dt = previousSenseAt and math.max(now - previousSenseAt, 0.05) or 0.15
            local diagnostics = Bot.Movement and Bot.Movement.GetDiagnostics and Bot.Movement:GetDiagnostics()
            s.selfCornered = not s.movementLocked and diagnostics and diagnostics.blocked
                and not diagnostics.reached and (diagnostics.stalledFor or 0) > 1.2 and killerDistance < 30 or false
            s.approachSpeed = previousKiller == killerModel and previousDistance and (previousDistance - killerDistance) / dt or 0
            previousKiller, previousDistance, previousSenseAt, lastHealth = killerModel, killerDistance, now, humanoid.Health
            return s
        end

        local function think()
            if not Bot.Enabled or Bot.Destroyed then return end
            local movement = Bot.Movement
            if not movement then Bot.State = "WAITING FOR MOVEMENT"; return end
            local s = senseWorld()
            if not s or s.role == "Lobby" then
                resetNavigation()
                movement:Stop()
                safely(Bot.Generators, "Cancel")
                safely(Bot.Ability, "Reset")
                -- Some round systems reuse the same rig. Reset round-local memory even
                -- when CharacterAdded does not fire before the next round starts.
                activeCharacter, activeRole, lastHealth = nil, nil, nil
                targetModel, generatorModel, roamGoal, fleeGoal, fleeingKiller = nil, nil, nil, nil, nil
                previousKiller, previousDistance, previousSenseAt = nil, nil, nil
                lastSense = {}
                Bot.State = "WAITING FOR ROUND"
                return
            end
            lastSense = s
            local worldPolicy = Bot.World and Bot.World:Update(s, Bot.Ability) or {}
            s.hazards, s.noSprint, s.quietAbilities = worldPolicy.hazards or {}, worldPolicy.noSprint, worldPolicy.quietAbilities
            local worldIntent = worldPolicy.intent
            local evasion = Bot.Combat and Bot.Combat:Update(s, Bot.Ability)
            s.evading = evasion ~= nil
            local finishingItem = Settings.Items ~= false and Bot.Items and Bot.Items.IsBusy and Bot.Items:IsBusy()
                and not s.incomingAttack and not s.underAttack and not s.damaged and s.killerDistance > 24
                and not (worldIntent and worldIntent.kind == "hazardEscape")
            local healing = not finishingItem and worldIntent and worldIntent.kind == "heal"
                and not s.incomingAttack and not s.underAttack and not s.damaged and s.killerDistance > 24
            local worldEscape = worldIntent and worldIntent.kind == "hazardEscape"
            local tactical = not finishingItem and not healing and not worldEscape and not s.quietAbilities
                and Settings.Abilities and Settings.CharacterCombos ~= false and Bot.Ability
                and Bot.Ability.GetTacticalIntent and Bot.Ability:GetTacticalIntent(s)
            local itemUsing = false
            if tactical and tactical.priority and tactical.priority >= 100 and tactical.kind == "hold" then
                evasion, s.evading = nil, false
            end
            if s.role == "Survivor" then
                local attack, attackName = false, nil
                if Bot.Ability and s.killerRoot then attack, attackName = Bot.Ability:Threat(s.killerModel) end
                attack = attack or s.incomingAttack
                attackName = attackName or (s.combatThreat and s.combatThreat.name)
                local pursuing = false
                if s.killerRoot and s.killerDistance < 34 then
                    local toward = unit(flat(s.root.Position - s.killerRoot.Position))
                    local facing = flat(s.killerRoot.CFrame.LookVector):Dot(toward) > 0.4
                    local velocity = flat(s.killerRoot.AssemblyLinearVelocity):Dot(toward)
                    pursuing = facing and velocity > 3 and (s.approachSpeed > 0.5 or s.killerDistance < 17)
                        and visible(s.root.Position, s.killerRoot.Position, s.character)
                end
                local contact = s.killerRoot and (s.killerDistance <= 5
                    or (s.killerDistance <= (Settings.ContactDistance or 18) and visible(s.root.Position, s.killerRoot.Position, s.character)))
                local proximity = not Settings.RequireThreat and s.killerDistance < Settings.DetectionDistance
                local threatened = Settings.AvoidKiller and s.killerRoot and (attack or pursuing or s.damaged or proximity or contact)
                s.incomingAttack, s.underAttack = attack, pursuing or s.underAttack
                local wasHelping = activeHelp ~= nil
                local help = not finishingItem and not healing and not worldEscape and not s.quietAbilities
                    and not tactical and Bot.Assist and Bot.Assist:Update(s, Bot.Ability)
                if help then
                    if not wasHelping then
                        cancelSearch()
                        escapeEpisode += 1
                        cancelObjectives()
                        fleeGoal, fleeingKiller, roamGoal = nil, nil, nil
                        fleeBackupActive, fleeTransitActive = false, false
                        fleeProgressPoint, fleeProgressAt = nil, nil
                    end
                    s.assisting, s.assistIntent = true, not help.passive and help.intent or nil
                    threatened = false
                elseif wasHelping then
                    -- Once the useful action is spent or the short window expires,
                    -- regain separation even if the killer hasn't turned toward us yet.
                    threatened = threatened or (Settings.AvoidKiller and s.killerRoot and s.killerDistance < Settings.DetectionDistance)
                    nextGeneratorScan = 0
                end
                activeHelp = help
                local comboApproach = tactical and not evasion and not s.damaged and not attack
                    and not pursuing and (tactical.kind == "approach" or tactical.kind == "placement")
                if comboApproach then threatened = false end
                if threatened then
                    lastThreat = s.now
                    if not fleeingKiller then
                        cancelSearch()
                        escapeEpisode += 1
                        fleeingKiller = s.killerModel
                        fleeStart = s.now
                        fleeExit = math.max(Settings.SafeDistance, s.killerDistance * Settings.FleeMultiplier)
                        fleeGoal, nextFleeGoal = nil, 0
                        fleeBackupActive, failedEscapes = false, {}
                        fleeTransitActive, fleeTransitUntil, nextTransitProbe = false, 0, 0
                        fleeProgressPoint, fleeProgressAt = s.root.Position, s.now
                        nextBackupSearch = 0
                        cancelObjectives()
                        notify(attack and ("Evading " .. tostring(attackName or "ability")) or contact and "Killer contact detected. Escaping." or "Killer pursuit detected. Escaping.")
                    end
                end
                if fleeingKiller and (not s.killerRoot or not Settings.AvoidKiller
                    or (s.killerDistance >= fleeExit and s.now - fleeStart >= Settings.MinFleeTime and s.now - lastThreat > 2)) then
                    fleeingKiller, fleeGoal, roamGoal = nil, nil, nil
                    cancelSearch()
                    escapeEpisode += 1
                    fleeBackupActive = false
                    fleeTransitActive, fleeTransitUntil = false, 0
                    fleeProgressPoint, fleeProgressAt = nil, nil
                    nextGeneratorScan = 0
                end
                if comboApproach and fleeingKiller then
                    cancelSearch()
                    escapeEpisode += 1
                    fleeingKiller, fleeGoal = nil, nil
                    fleeBackupActive, fleeTransitActive = false, false
                end
                s.fleeing = fleeingKiller ~= nil
                if help then
                    safely(Bot.Items, "Cancel")
                    Bot.State = help.passive and "COVERING TEAMMATE" or help.kind == "support" and "HELPING TEAMMATE" or "COUNTERATTACKING"
                    movement:SetGoal(help.goal, {mode = "assist", sprint = (help.goal - s.root.Position).Magnitude > 12,
                        arrival = help.arrival or 1, target = help.intent.kind == "counterattack" and help.intent.killerModel or help.intent.allyModel})
                elseif s.fleeing then
                    safely(Bot.Items, "Cancel")
                    Bot.State = "ESCAPING"
                    local unsafeBackup = fleeBackupActive and fleeGoal and s.killerRoot
                        and (fleeGoal - s.killerRoot.Position).Magnitude < 35
                    if unsafeBackup then
                        remember(failedEscapes, fleeGoal)
                        if pendingKind == "escape" then cancelSearch() end
                        fleeBackupActive, fleeGoal, nextFleeGoal, nextBackupSearch = false, nil, 0, 0
                        fleeTransitActive = false
                    end
                    local blocked = stalled(s, true)
                    local reached = fleeGoal and movement:Reached()
                    if fleeTransitActive and (reached or s.now >= fleeTransitUntil) then
                        fleeTransitActive, nextFleeGoal = false, 0
                    end
                    if fleeBackupActive and reached then
                        remember(failedEscapes, fleeGoal)
                        fleeBackupActive, fleeGoal, nextFleeGoal = false, nil, 0
                        fleeProgressPoint, fleeProgressAt = s.root.Position, s.now
                    end
                    local pinched = false
                    if not fleeBackupActive and not fleeTransitActive and (s.now >= nextFleeGoal or not fleeGoal or reached) then
                        local localGoal
                        localGoal, pinched = chooseFleeGoal(s)
                        fleeGoal = localGoal or fleeGoal
                        nextFleeGoal = s.now + 1.5
                    end
                    local rescuing = blocked or pinched or not fleeGoal or unsafeBackup
                    if rescuing then
                        if blocked and fleeBackupActive then remember(failedEscapes, fleeGoal) end
                        if s.now >= nextTransitProbe and canMeasureProgress(s) then
                            local exitStep = chooseExitStep(s)
                            nextTransitProbe = s.now + 0.6
                            if exitStep then
                                fleeGoal, fleeBackupActive, fleeTransitActive = exitStep, false, true
                                fleeTransitUntil = s.now + math.max(2, (exitStep - s.root.Position).Magnitude / math.max(s.humanoid.WalkSpeed or 12, 6) + 1)
                                nextFleeGoal = fleeTransitUntil
                            end
                        end
                        beginDestination(s, "escape")
                    end
                    if fleeGoal then
                        movement:SetGoal(fleeGoal, {mode = "flee", sprint = true, emergency = Settings.EmergencySprint and (attack or s.damaged or s.killerDistance < Settings.EmergencyDistance), arrival = fleeTransitActive and 0.8 or 3, target = s.killerModel})
                    else
                        -- Never release movement solely because a rescue query is
                        -- pending or failed. Retain the existing navigator and let a
                        -- normal jump help with low obstacles while testing exits.
                        if Settings.Jump ~= false and movement._jump and canMeasureProgress(s) then movement:_jump(s.humanoid, s.now) end
                        notify("Finding the open exit; passing the killer is allowed.")
                    end
                elseif evasion then
                    cancelObjectives()
                    safely(Bot.Items, "Cancel")
                    Bot.State = "DODGING"
                elseif tactical then
                    cancelObjectives()
                    safely(Bot.Items, "Cancel")
                    if pendingKind then cancelSearch() end
                    Bot.State = tactical.label or "CHARACTER COMBO"
                elseif worldEscape or healing then
                    cancelObjectives()
                    safely(Bot.Items, "Cancel")
                    if pendingKind then cancelSearch() end
                    Bot.State = worldIntent.label or (worldEscape and "AVOIDING MINION" or "FINDING HEALING")
                    movement:SetGoal(worldIntent.holdMovement and s.root.Position or worldIntent.goal, {mode = worldEscape and "flee" or "heal",
                        sprint = worldIntent.sprint == true and not worldIntent.holdMovement,
                        arrival = worldIntent.arrival or 1.5, target = worldIntent.targetModel})
                else
                    local generators = Bot.Generators
                    if Settings.Items == false then safely(Bot.Items, "Cancel") end
                    local itemIntent
                    if Settings.Items ~= false and Bot.Items and not evasion
                        and not (generators and generators.IsBusy and generators:IsBusy()) then
                        itemIntent = Bot.Items:GetIntent(s, {needGear = Settings.Objectives and generators
                            and generators.NeedsGear and generators:NeedsGear(), wantSpeed = true})
                    end
                    if itemIntent then
                        cancelObjectives()
                        if pendingKind then cancelSearch() end
                        local busy, status = Bot.Items:Update(s, itemIntent)
                        itemUsing = busy or itemIntent.kind == "use"
                        Bot.State = itemIntent.kind == "pickup" and "COLLECTING " .. string.upper(itemIntent.itemKind) or "USING " .. string.upper(itemIntent.itemKind)
                        notify(status or itemIntent.status)
                        if busy and itemIntent.holdMovement then
                            movement:Stop()
                        elseif itemIntent.kind == "pickup" and itemIntent.goal then
                            local pickupReach = itemIntent.prompt and tonumber(itemIntent.prompt.MaxActivationDistance) or 6
                            local pickupGap = (itemIntent.goal - s.root.Position).Magnitude
                            movement:SetGoal(itemIntent.goal, {mode = "travel", sprint = pickupGap > 18,
                                arrival = math.clamp(pickupReach - 1.5, 2, 5)})
                        else
                            roam(s)
                        end
                    else
                    if not Settings.Objectives or not generators or not generators.Available then
                        cancelObjectives()
                    elseif generatorModel and (not generatorModel.Parent
                        or (generators.IsAvailable and not generators:IsAvailable(generatorModel))) then
                        cancelObjectives()
                        nextGeneratorScan = 0
                    end
                    local circleEvents = movement.circleEvents or 0
                    if circleEvents ~= lastCircleEvents then
                        lastCircleEvents = circleEvents
                        table.insert(circleStrikes, s.now)
                        while #circleStrikes > 0 and s.now - circleStrikes[1] > 25 do table.remove(circleStrikes, 1) end
                        if #circleStrikes >= 2 and generatorModel and generators and generators.Ban then
                            generators:Ban(generatorModel, 30)
                            cancelObjectives()
                            generatorModel, nextGeneratorScan, circleStrikes = nil, 0, {}
                            debugLog("plr gave up on this generator for a bit")
                        end
                    end
                    if Settings.Objectives and generators and generators.Available then
                        if s.now >= nextGeneratorScan then
                            local candidate = Bot.Generators:Find(s.root, s.killers)
                            if candidate ~= generatorModel and not generators:IsBusy() then
                                cancelObjectives()
                                generatorModel = candidate
                            end
                            nextGeneratorScan = s.now + 4
                        end
                    end
                    local busy = false
                    local goal = generatorModel and Bot.Generators and Bot.Generators:GetGoal(generatorModel)
                    if goal then
                        if pendingKind == "roam" then cancelSearch() end
                        local status
                        busy, status = Bot.Generators:Update(s, generatorModel)
                        if busy then
                            movement:Stop()
                            Bot.State = "REPAIRING"
                            notify(status)
                        else
                            -- Update can finish, time out, or lose its free seat. Never
                            -- keep the old position after the adapter invalidates it.
                            goal = status ~= "Generator complete" and generators:GetGoal(generatorModel) or nil
                            if goal then
                                Bot.State = "TO GENERATOR"
                                movement:SetGoal(goal, {mode = "travel", sprint = (goal - s.root.Position).Magnitude > Settings.LongSprintDistance, arrival = 1.25})
                            end
                        end
                    end
                    if not busy and not goal then
                        if generatorModel then
                            cancelObjectives()
                            nextGeneratorScan = 0
                        end
                        Bot.State = "ROAMING"
                        roam(s)
                    end
                    end
                end
            else
                safely(Bot.Items, "Cancel")
                if pendingKind == "escape" then cancelSearch() end
                cancelObjectives()
                if worldIntent and worldIntent.kind == "destroy" and not evasion and not s.movementLocked then
                    if pendingKind then cancelSearch() end
                    tactical = nil
                    s.structureTarget = worldIntent
                    Bot.State = worldIntent.label or "CLEARING CONSTRUCT"
                    movement:SetGoal(worldIntent.goal, {mode = "structure", sprint = false,
                        arrival = worldIntent.arrival or 3.5, target = worldIntent.targetModel})
                elseif s.targetRoot then
                    if targetModel ~= s.targetModel then targetChangedAt = s.now end
                    targetModel = s.targetModel
                    Bot.State = "PURSUING"
                    if pendingKind == "roam" then cancelSearch() end
                    -- Lead only a short time; pathfinding handles walls and vertical routes.
                    local lead = math.clamp(s.targetDistance / 160, 0.05, 0.4)
                    local predicted = s.targetRoot.Position + flat(s.targetRoot.AssemblyLinearVelocity) * lead
                    if not visible(s.targetRoot.Position, predicted, s.character) then predicted = s.targetRoot.Position end
                    movement:SetGoal(predicted, {mode = "chase", sprint = true, arrival = 2.7, target = s.targetModel})
                else
                    targetModel = nil
                    Bot.State = "SEARCHING"
                    roam(s)
                end
            end
            -- Tactical actions share the same writer. Immediate danger keeps its short
            -- sidestep; confirmed native abilities keep their own movement locks.
            if tactical and not evasion and not itemUsing and (not s.fleeing or tactical.priority and tactical.priority >= 90) then
                if tactical.hold or tactical.kind == "hold" then
                    movement:SetGoal(s.root.Position, {mode = "combo", sprint = false, arrival = 1})
                elseif tactical.goal then
                    movement:SetGoal(tactical.goal, {mode = "combo", sprint = tactical.sprint == true, arrival = tactical.arrival or 2})
                end
                if tactical.faceTarget and ctx.face then ctx.face(tactical.faceTarget, 0.4) end
                if tactical.cameraTarget and ctx.cameraAim then ctx.cameraAim(tactical.cameraTarget, 0.4) end
                if tactical.jump and movement._jump then movement:_jump(s.humanoid, s.now) end
                Bot.State = tactical.label or "CHARACTER COMBO"
            end
            if evasion then
                safely(Bot.Items, "Cancel")
                cancelObjectives()
                if movement.SetEvasion then movement:SetEvasion(evasion) end
                Bot.State = evasion.kind == "block" and "WAITING OUT BLOCK" or "DODGING"
            elseif movement.SetEvasion then movement:SetEvasion(nil) end
            if Settings.Abilities and Bot.Ability then
                if Bot.State == "REPAIRING" or itemUsing or s.quietAbilities or healing then
                    -- Ordinary work can start while a prior mode-exit input is still
                    -- cooling down. Keep releasing owned inputs without choosing a cast.
                    if Bot.Ability.Maintain then Bot.Ability:Maintain(s) end
                else
                    local action = Bot.Ability:Update(s)
                    if action then lastAbility = tostring(action) end
                end
            end
            s.movementLocked = Bot.Ability and Bot.Ability:MovementLocked() or false
            -- Softlock watchdog: standing still for too long while not doing a stationary task -> reset targets.
            do
                local stationaryTask = Bot.State == "REPAIRING" or Bot.State == "WAITING OUT BLOCK" or Bot.State == "DISABLED"
                    or string.sub(Bot.State, 1, 5) == "USING" or itemUsing or healing or s.movementLocked
                    or (s.humanoid and (s.humanoid.Sit or s.humanoid.PlatformStand))
                local position = s.root.Position
                if stationaryTask or not idleAnchor or (position - idleAnchor).Magnitude > 3 then
                    idleAnchor, idleSince = position, s.now
                elseif s.now - idleSince > 6 then
                    idleAnchor, idleSince = position, s.now
                    safely(Bot.Items, "GiveUp")
                    safely(Bot.Items, "Cancel")
                    if generatorModel and Bot.Generators and Bot.Generators.Ban then Bot.Generators:Ban(generatorModel, 25) end
                    cancelObjectives()
                    generatorModel, nextGeneratorScan, roamGoal, nextRoamGoal = nil, 0, nil, 0
                    movement:Stop()
                    debugLog("plr was standing still, resetting")
                end
            end
            movement:Update(0.15, s)
        end

        local uiElapsed, resizeElapsed = 0, 0
        connect(RunService.Heartbeat, function(dt)
            uiElapsed += dt
            resizeElapsed += dt
            if resizeElapsed > 1 then resizeElapsed = 0; fit() end
            if uiElapsed < 0.25 then return end
            uiElapsed = 0
            if Bot.UI then Bot.UI:UpdateEnabled(Bot.Enabled) end
            statusLabel.Text = "STATE  /  " .. Bot.State
            local actor = lastSense.actor
            actorLabel.Text = "CHARACTER  /  " .. tostring(actor and (actor.ActorName .. "  ·  " .. actor.ActorType) or lastSense.role or "WAITING")
            targetLabel.Text = "TARGET  /  " .. tostring(activeHelp and activeHelp.label or fleeingKiller and ((fleeBackupActive and "BACKUP ESCAPE  /  " or "ESCAPE ") .. fleeingKiller.Name) or targetModel and targetModel.Name or generatorModel and generatorModel.Name or "ROAM")
            local d = Bot.Movement and Bot.Movement:GetDiagnostics() or {}
            staminaLabel.Text = "STAMINA  /  " .. (d.stamina and string.format("%.0f", d.stamina) or "—") .. (d.recovering and "  ·  RECOVERING" or d.sprinting and "  ·  SPRINT" or "") .. (d.reserve and ("  ·  MIN " .. tostring(d.reserve)) or "")
            fill.Size = UDim2.fromScale(d.stamina and math.clamp(d.stamina / math.max(d.maxStamina or 100, 1), 0, 1) or 0, 1)
            noticeLabel.Text = Bot.LastNotice
            local generatorStatus = Bot.Generators and (Bot.Generators.Available and "ready" or Bot.Generators.Status) or componentStatus.Generators
            diagnosticsLabel.Text = "Movement: " .. tostring(d.status or componentStatus.Movement) .. "  /  " .. tostring(d.path or "idle")
                .. "\nSprint: " .. tostring(d.sprintMode or "waiting for input")
                .. "\nGenerators: " .. tostring(generatorStatus)
                .. "\nAbilities: " .. tostring(Bot.Ability and Bot.Ability.actors and Bot.Ability.network and "ready" or componentStatus.Ability)
                .. "\nLast ability: " .. lastAbility
                .. "\nRoute: " .. tostring(d.routeIndex or 0) .. " / " .. tostring(d.routeCount or 0)
        end)
        Bot:LoadIntegrations()
        task.spawn(function()
            while not Bot.Destroyed do
                local ok, err = pcall(think)
                if not ok then
                    Bot:SetEnabled(false)
                    notify("Autopilot paused: " .. tostring(err))
                    warn("[Forsaken Autopilot] " .. tostring(err))
                end
                task.wait(0.15)
            end
        end)
        return Bot

        end

        local automation_tab = window:Tab({ Title = "automation", Icon = "bot" })
        local okBot, Bot = pcall(CreateAutopilot)
        if not okBot or type(Bot) ~= "table" then
            automation_tab:Paragraph({ Title = "autopilot failed to load", Desc = tostring(Bot) })
            warn("[forsaken8z] autopilot failed: " .. tostring(Bot))
        else
            local S = Bot.Settings
            local masterToggle

            local function SetEnabled(v)
                pcall(function() Bot:SetEnabled(v) end)
            end
            local function Tog(key, title, desc)
                automation_tab:Toggle({ Title = title, Desc = desc, Value = S[key], Callback = function(v) S[key] = v end })
            end
            local function Sld(key, title, desc, min, max, step)
                automation_tab:Slider({
                    Title = title, Desc = desc,
                    Value = { Min = min, Max = max, Default = S[key], Step = step },
                    Callback = function(v) S[key] = tonumber(v) or S[key] end
                })
            end

            automation_tab:Section({ Title = "autopilot" })
            masterToggle = automation_tab:Toggle({
                Title = "enable autopilot",
                Desc = "plays the round for you. turn on once a round starts (hotkey: F6)",
                Value = false,
                Callback = SetEnabled
            })
            local statusPara = automation_tab:Paragraph({ Title = "status", Desc = "disabled" })
            Tog("DebugNotifications", "debug notifications", "short lowercase logs: running to / on / off a generator, loops, giving up on targets")

            automation_tab:Section({ Title = "features" })
            Tog("Objectives", "objectives", "does generators / objectives automatically")
            Tog("Abilities", "abilities", "uses your character's abilities when useful")
            Tog("CharacterCombos", "character combos", "chains character-specific ability combos")
            Tog("DodgeAttacks", "dodge attacks", "dodges incoming killer attacks")
            Tog("Items", "use items", "picks up and uses items")
            Tog("AssistAllies", "assist allies", "helps teammates that are in trouble")
            Tog("AvoidKiller", "avoid killer", "keeps its distance from the killer")
            Tog("Jump", "allow jumping", "lets the pathfinder jump over obstacles")
            Tog("AllowDrops", "allow drops", "lets the pathfinder drop off ledges")
            Tog("EmergencySprint", "emergency sprint", "sprints regardless of reserve when the killer is close")
            Tog("AntiCircle", "anti-circling", "detects when it is running in circles, then replans or moves on")

            automation_tab:Section({ Title = "stamina" })
            Sld("Reserve", "sprint reserve", "stops sprinting when stamina falls below this", 0, 100, 1)
            Sld("Resume", "sprint resume", "starts sprinting again once stamina is above this", 0, 100, 1)
            Sld("KillerReserve", "reserve (playing killer)", "sprint reserve while you are the killer", 0, 100, 1)
            Sld("KillerResume", "resume (playing killer)", "sprint resume while you are the killer", 0, 100, 1)
            Sld("VeeronicaReserve", "reserve (veeronica)", "sprint reserve for veeronica", 0, 100, 1)
            Sld("VeeronicaResume", "resume (veeronica)", "sprint resume for veeronica", 0, 100, 1)

            automation_tab:Section({ Title = "detection & fleeing" })
            Sld("DetectionDistance", "detection distance", "how far away it notices the killer (studs)", 20, 150, 1)
            Sld("ContactDistance", "contact distance", "distance treated as being in contact", 5, 60, 1)
            Sld("EmergencyDistance", "emergency distance", "distance that triggers emergency sprint", 4, 40, 1)
            Sld("LongSprintDistance", "long sprint distance", "minimum trip length before it sprints (studs)", 10, 120, 1)
            Sld("SafeDistance", "safe distance", "how far it must be from the killer to stop fleeing", 30, 200, 1)
            Sld("FleeMultiplier", "flee multiplier", "how much farther it flees than the detection range", 1, 3, 0.1)
            Sld("MinFleeTime", "min flee time", "minimum seconds to keep fleeing", 1, 15, 0.5)
            Sld("CornerReactionTime", "corner reaction time", "seconds before it reacts to being cornered", 0.1, 3, 0.05)

            automation_tab:Section({ Title = "roaming & movement" })
            Sld("RoamMinDistance", "roam min distance", "shortest roam trip (studs)", 10, 150, 1)
            Sld("RoamMaxDistance", "roam max distance", "longest roam trip (studs)", 20, 250, 1)
            Sld("BackupMinDistance", "backup min distance", "shortest backup-escape trip (studs)", 50, 200, 1)
            Sld("BackupMaxDistance", "backup max distance", "longest backup-escape trip (studs)", 80, 300, 1)
            Sld("MaxDropHeight", "max drop height", "highest ledge it is willing to drop from (studs)", 10, 200, 1)

            automation_tab:Section({ Title = "ally assist" })
            Sld("AssistMinHealth", "min health to assist", "only assists when your health is above this fraction", 0.1, 1, 0.05)
            Sld("AssistMinStaminaMargin", "stamina margin", "extra stamina required before assisting", 0, 50, 1)
            Sld("AssistWindow", "assist window", "seconds spent trying to help one ally", 1, 15, 0.5)
            Sld("AssistRest", "assist rest", "seconds to wait between assists", 1, 30, 0.5)
            Sld("AssistGuardTime", "assist guard time", "seconds it guards an ally after helping", 5, 60, 1)

            -- live status readout
            task.spawn(function()
                while ScriptRunning and not Bot.Destroyed do
                    local L = Bot.Labels
                    if L then
                        local text = L.status.Text .. "\n" .. L.actor.Text .. "\n" .. L.target.Text .. "\n"
                            .. L.stamina.Text .. "\n" .. tostring(L.notice.Text)
                        pcall(function() statusPara:SetDesc(text) end)
                    end
                    task.wait(0.5)
                end
            end)

            -- debug notifications (lowercase, 2.3s): generator state + what the autopilot is doing
            local lastDebug = {}
            local function debugNotify(message)
                if not S.DebugNotifications then return end
                local t = os.clock()
                if lastDebug[message] and t - lastDebug[message] < 1.5 then return end
                lastDebug[message] = t
                pcall(function() windui:Notify({ Title = "debug", Content = message, Duration = 2.3 }) end)
            end
            Bot.DebugHook.fn = debugNotify

            local function stateMessage(state)
                if state == "TO GENERATOR" then return "plr is running to a generator" end
                if state == "ESCAPING" then return "plr is running from the killer" end
                if state == "DODGING" then return "plr is dodging an attack" end
                if state == "ROAMING" then return "plr is roaming around" end
                if state == "HELPING TEAMMATE" then return "plr is helping a teammate" end
                if state == "COVERING TEAMMATE" then return "plr is covering a teammate" end
                if state == "COUNTERATTACKING" then return "plr is counterattacking" end
                local collecting = state:match("^COLLECTING (.+)$")
                if collecting then return "plr is running to a " .. collecting:lower() end
                local using = state:match("^USING (.+)$")
                if using then return "plr is using a " .. using:lower() end
                return nil
            end

            task.spawn(function()
                local onGenerator, lastState = false, nil
                while ScriptRunning and not Bot.Destroyed do
                    -- PuzzleUI.Container spawning in = on a generator; spawning out = off it (once per change)
                    local present = false
                    pcall(function()
                        local puzzle = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("PuzzleUI")
                        present = puzzle ~= nil and puzzle:FindFirstChild("Container") ~= nil
                    end)
                    if present and not onGenerator then
                        onGenerator = true
                        debugNotify("plr is on a generator")
                    elseif not present and onGenerator then
                        onGenerator = false
                        debugNotify("plr is off generator")
                    end

                    local state = Bot.Enabled and Bot.State or nil
                    if state ~= lastState then
                        lastState = state
                        local text = state and stateMessage(state)
                        if text then debugNotify(text) end
                    end
                    task.wait(0.4)
                end
            end)

            -- F6 hotkey (kept from the standalone version)
            local UIS = game:GetService("UserInputService")
            table.insert(Connections, UIS.InputBegan:Connect(function(input, processed)
                if processed or UIS:GetFocusedTextBox() then return end
                if input.KeyCode == Enum.KeyCode.F6 and not Bot.Destroyed then
                    local nv = not Bot.Enabled
                    SetEnabled(nv)
                    pcall(function() masterToggle:Set(nv) end)
                end
            end))
        end
    end
    local autofarm_tab = window:Tab({ Title = "autofarm", Icon = "repeat" })

    -- Generator Tab Controls
    gen_tab:Toggle({ Title = "auto generator(s)", Desc = "auto do generators", Value = State.AutoGenerator, Callback = function(val) State.AutoGenerator = val end })
    gen_tab:Slider({ Title = "generator cooldown", Desc = "delay in auto do generator", Value = { Min = 0.1, Max = 5, Default = State.GeneratorCooldown, Step = 0.1 }, Callback = function(val) State.GeneratorCooldown = val end })
    gen_tab:Toggle({ Title = "auto give the orange food", Desc = "automatically the orange food (what he wants), you have to have it in your inventory first", Value = State.AutoGiveOrangeFood, Callback = function(val) State.AutoGiveOrangeFood = val end })
    gen_tab:Toggle({ Title = "auto gen (NEW)", Desc = "current auto gen for oct 17, 2026 (when they updated it)", Value = State.AutoGenNew, Callback = function(val) State.AutoGenNew = val end })
    gen_tab:Slider({ Title = "change auto gen duration", Desc = "i recommend to set it at like 3", Value = { Min = 1, Max = 7, Default = State.AutoGenDuration, Step = 0.5 }, Callback = function(val) State.AutoGenDuration = val end })

    -- Generator List & TP System
    -- (the old refresh called dropdown:SetValues, which this WindUI doesnt have; Refresh is the real method)
    local generatorList = {}
    local generatorMap = {}
    local selectedGenLabels = {}

    local function RefreshDropdown(drop, values, default)
        if not drop then return end
        for _, method in ipairs({ "Refresh", "SetValues", "SetOptions", "Update" }) do
            if type(drop[method]) == "function" then
                if pcall(drop[method], drop, values) then break end
            end
        end
        if default ~= nil then
            for _, method in ipairs({ "Select", "Set" }) do
                if type(drop[method]) == "function" then
                    pcall(drop[method], drop, default)
                    break
                end
            end
        end
    end

    local function GeneratorCFrame(model)
        local positions = model:FindFirstChild("Positions")
        local center = positions and positions:FindFirstChild("Center")
        if center then
            if center:IsA("BasePart") then return center.CFrame end
            if center:IsA("Attachment") then return center.WorldCFrame end
            if center:IsA("Model") then return center:GetPivot() end
        end
        local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
        return part and part.CFrame or nil
    end

    local function FetchGenerators()
        generatorList = {}
        generatorMap = {}
        local ingame = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Ingame")
        local mainMap = ingame and ingame:FindFirstChild("Map")
        if mainMap then
            local count = 0
            for _, obj in ipairs(mainMap:GetChildren()) do
                if obj:IsA("Model") and obj.Name ~= "FakeGenerator" and obj.Name:lower():find("generator") then
                    count += 1
                    local label = "Generator " .. count
                    table.insert(generatorList, label)
                    generatorMap[label] = obj
                end
            end
        end
        if #generatorList == 0 then
            table.insert(generatorList, "no generators found")
        end
    end

    FetchGenerators()

    local genDropdown = gen_tab:Dropdown({
        Title = "tp to generators",
        Desc = "select the generators you want to teleport to",
        Values = generatorList,
        Value = {},
        Multi = true,
        AllowNone = true,
        Callback = function(selected)
            selectedGenLabels = {}
            if type(selected) == "table" then
                for _, v in pairs(selected) do
                    local label = type(v) == "table" and (v.Title or v.Name) or v
                    if type(label) == "string" then selectedGenLabels[label] = true end
                end
            elseif type(selected) == "string" then
                selectedGenLabels[selected] = true
            end
        end
    })

    gen_tab:Button({
        Title = "refresh generator list",
        Desc = "refreshes the list",
        Callback = function()
            FetchGenerators()
            selectedGenLabels = {}
            RefreshDropdown(genDropdown, generatorList)
            windui:Notify({ Title = "generators refreshed", Content = "found " .. tostring(generatorMap["Generator 1"] and #generatorList or 0) .. " generator option(s)", Duration = 3 })
        end
    })

    -- keep the list in sync when the map loads in (the first fetch usually happens in the lobby)
    task.spawn(function()
        local lastSignature = table.concat(generatorList, "|")
        while ScriptRunning do
            task.wait(3)
            pcall(function()
                FetchGenerators()
                local signature = table.concat(generatorList, "|")
                if signature ~= lastSignature then
                    lastSignature = signature
                    selectedGenLabels = {}
                    RefreshDropdown(genDropdown, generatorList)
                end
            end)
        end
    end)

    gen_tab:Button({
        Title = "teleport to selected generators",
        Desc = "teleports to the center of every selected generator, one after another",
        Callback = function()
            local targets = {}
            for _, label in ipairs(generatorList) do
                if selectedGenLabels[label] and generatorMap[label] then
                    table.insert(targets, generatorMap[label])
                end
            end
            if #targets == 0 then
                windui:Notify({ Title = "teleport failed", Content = "select a generator", Duration = 4 })
                return
            end
            task.spawn(function()
                local visited = 0
                for _, model in ipairs(targets) do
                    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    local cf = model.Parent and GeneratorCFrame(model)
                    if hrp and cf then
                        hrp.CFrame = cf * CFrame.new(0, 3, 0)
                        visited += 1
                        task.wait(0.4)
                    end
                end
                windui:Notify({ Title = "teleported", Content = "teleported to " .. visited .. " generator(s)", Duration = 3 })
            end)
        end
    })

    ----------------------------------------------------------------------
    -- Autofarm: runs the desync + invisibility script first, then loops gear -> generator
    ----------------------------------------------------------------------
    do
        local okFarm, errFarm = pcall(function()
            local RS = game:GetService("RunService")
            local UIS = game:GetService("UserInputService")
            local PPS = game:GetService("ProximityPromptService")
            local PFS = game:GetService("PathfindingService")
            local Mouse = LP:GetMouse()
            local HttpService = game:GetService("HttpService")
            local TeleportService = game:GetService("TeleportService")

            -- queue_on_teleport re-runs this script in the next server. It needs to know where the script lives:
            --  * put a raw link to it here (loadstring(game:HttpGet(url))()), OR
            --  * save it as AUTOFARM_SCRIPT_FILE inside your executor's workspace folder
            local AUTOFARM_SCRIPT_URL = ""
            local AUTOFARM_SCRIPT_FILE = "forsaken_full_v3_automation.lua"
            local SETTINGS_FILE = "forsaken_autofarm_settings.json"

            local function farmNotify(message)
                pcall(function() windui:Notify({ Title = "autofarm", Content = message, Duration = 2.3 }) end)
            end

            ------------------------------------------------------------------
            -- Desync script (your file, wrapped so it can be started / stopped)
            ------------------------------------------------------------------
            local PAUSE_KEY = Enum.KeyCode.V
            local AUTO_INTERACT = true
            local RESUME_DELAY = 0.45
            local PAUSE_WHILE_PROMPT_SHOWN = true
            local HOLD_AFTER_TRIGGER = true
            local LEAVE_DISTANCE = 7
            local HOLD_MAX_TIME = 50
            local HOVER_CLICKDETECTOR = true
            local PUZZLE_GUI_NAMES = {}
            local HIDE_MOVEMENT_ANIMS = true
            local BLOCK_KEYWORDS = {"run", "walk", "sprint", "jog", "jump", "fall", "climb", "swim", "land"}
            local TRAVEL_SPEED = 19371917291281928198726923718918271
            local USE_PATHFINDING = true
            local DEBUG = false

            -- Exact asset ids to delete from workspace.Players.Survivors.Noob
            local DELETE_SET = {}
            for id in string.gmatch([[
0 7074972 7317691 8560915 10548112 10678193 10722059 11998777 12222208 12222225
12544690 21391849 41410287 94215314 128277497 255661850 256382824 256388309 423041164 423041209
423041247 423041300 423041325 423041356 609342351 942973921 1263090303 1956271358 2226293507 2573860412
3604152746 4550018759 5711961181 5989939664 6242625019 6299532110 6468210747 6821047585 7032036549 7130144078
7156832143 7256249627 7261571589 7261572328 8028421882 8090403894 8327314343 8595977193 8595983255 9089408772
9113225979 9113764330 10355182867 12760197441 13471740561 17529931596 17837549788 18564431123 18568553101 18881308827
18900008907 70402408192827 70423758102853 70464405571480 70516835851294 70604533638725 70640809524819 70788234584765 70855524430662 70949384791600
70958740828039 70984181094047 71074420468361 71087236659896 71190646367497 71201508203974 71281834720197 71323060627839 71379131145990 71391743657290
71475106359341 71514553107882 71561439233294 71594761843010 71636405369668 71640745259238 71686132533816 71727431771393 71927803626701 71965954515638
71991190682108 72007882634344 72016425892214 72084261602255 72116588104863 72143510449321 72182155407310 72315045096036 72319029654999 72328070969518
72375476095033 72439453650953 72542321209887 72580423982328 72595439342517 72598430601318 72605297365438 72633929527688 72639622937721 72670126521838
72685103823181 72722244508749 72736205341592 72750155331982 72972561927094 73014110721599 73063323190052 73071917243802 73085228427688 73098458945878
73104086317379 73280568217690 73382131761590 73389590491782 73390172375623 73406070551423 73411029228748 73426893697661 73458741315046 73475069436571
73502073176819 73607724401212 73616579504991 73627360224698 73680428315389 73731686138225 73737871217870 73809422260865 73851637329792 73908019523515
73912105303951 73950884525991 73958366945004 73976951487681 74102121414727 74112747802354 74245315057760 74262782582471 74291573260497 74306209947167
74361938461769 74365320396651 74489677235257 74567457943307 74578038351959 74803012944991 75166098880077 75250671298406 75261279373801 75314813646782
75356450551706 75413259888151 75470298885549 75692421314641 75807490379653 75842556102864 75885853059441 75933799572381 76019802445172 76162627701005
76278644860145 76306441308604 76338995278812 76433387788656 76438652263299 76515682105758 76560123130048 76561653320647 76566955859844 76582410716101
76594464793761 76627178482045 76628784276396 76654441985090 76714811998932 76723736177705 76822379808155 76856432084658 76857793498210 76867040662924
76901297103434 76954086937837 77158592331445 77284390655061 77358618977776 77438818635589 77448521277146 77502772227445 77577482028526 77604250548935
77738786488132 77771083601296 77817063460858 77828190408297 77869943633054 78057638144592 78107970648310 78167401662429 78267113234809 78339948440228
78375071864149 78414969679671 78440860685556 78516670245244 78520156813388 78595500409647 78616501079755 78652009699331 78655920424241 78680133644436
78806573295142 78824025538872 78918000282223 79076862058586 79195542840549 79217819346478 79252080001782 79256835909228 79269110094848 79456783016040
79481865543343 79487251166292 79493490374673 79536660231409 79544586556492 79590324637795 79686908367142 79693718892952 79695653208105 79721273338556
79826954889065 79858289936230 79884018218388 80045805137271 80141211265471 80150066035365 80156405968805 80181117067538 80257085359227 80408800188539
80411900860276 80498687770809 80582253682651 80658290866888 80673114168388 80694060854519 80704466791340 80739538264996 80804654389360 80814146491540
80893723634320 80899169903619 80915591642676 80992973879290 81114852524420 81172624801748 81222040920998 81236613009365 81520336947107 81714228693719
81788257504996 81905101227053 81908437365398 81913071734313 81961825024047 81976396729343 82036084568393 82128447153000 82137285150006 82140916169047
82187199226538 82348057401947 82420741706761 82468051909737 82534500165385 82550164988577 82605295530067 82697414467415 82712417512317 82720307615593
82725098197595 82772022662025 82861395881003 82897399254558 82905881089319 82910673819235 83036817079068 83081359372957 83161312898155 83200527402711
83215585828136 83225720352538 83237998576689 83292623942655 83316337098377 83417577055886 83427016908467 83460160883451 83508806897237 83520827282576
83526511547968 83535246653828 83567189345589 83635532949992 83771466963811 83880906074371 83881497063844 83931229833168 84062077525700 84170427362863
84276174030368 84330166007642 84333678178330 84347971543470 84454460069607 84524602183280 84548456158706 84676799882403 84861673473294 84878252222448
84919518451803 84957003529034 84981771311298 85009449670354 85033956233708 85203210001378 85265746475777 85277510975809 85282571177550 85306261619895
85338266462873 85376379564671 85393834593045 85477421247789 85569373455776 85695241472154 85769898501013 85823449033480 86055747090521 86082782562485
86096387000557 86174714158513 86208973578215 86233912600212 86246906616092 86377125017185 86444820132288 86457751397140 86535502112498 86601826124266
86604259115585 86620258582476 86626042206073 86671979030848 86685906144138 86709774283672 86820472941769 86839544397712 86860566106510 86936166426860
86948608222210 87044039142515 87074262085245 87080902257875 87082144606957 87162770938367 87191713862748 87259391926321 87305226288451 87451970500470
87505945297314 87520501554781 87614442534377 87716232019856 87716278630738 87763521676021 87786875181085 87814928106387 87853956205128 87901906956309
88070477681231 88105585367993 88131606622133 88132060723548 88166434841925 88221899777663 88254755071894 88287038085804 88313116424190 88416014902654
88431374611011 88434195095726 88449910724799 88513804015364 88529635581791 88557287105521 88562010194964 88600118696353 88616449890484 88693227531088
88709547877633 88732089534799 88777386425491 88872377533673 88874371473678 88884843280417 88885759378936 88906458194661 89006656535356 89082613289818
89089149117403 89113865833052 89132295831884 89158177589094 89241211916108 89313792925308 89329978246464 89505927364514 89667062545561 89756967510321
89781734256043 89796139014135 89824749905155 89942886045681 89985456328032 89986165728023 90014568607892 90035121639530 90072481102185 90074809626194
90114989663793 90236426054359 90280461790500 90302848115077 90311043311697 90318481007675 90343727457381 90532579450255 90587843408896 90604236361267
90653897607402 90738871790220 90785263625884 90837774996564 90882348400144 90890269120839 90923929039755 90970641235403 91007278418977 91035913785114
91066961339610 91072183222560 91165993312513 91267353686628 91321390832970 91338304117141 91482447879766 91507036086268 91522546229765 91663464934592
91729596070965 91730605416216 91794561199608 91810464218576 91830732867282 91831017187876 91904170026803 92042078070663 92048849626016 92358361263968
92389524852814 92507066744612 92568211045673 92600255426654 92602405866107 92695554469718 92698787105448 92755417369448 92826343575353 92827059719722
92831180929659 92845354055292 92845598666493 92860419785835 92922996444755 92985093938191 93141011495688 93174258574581 93208116034525 93333349905005
93559491032852 93635625434679 93657361241077 93660509869964 93712847953609 93767956907309 93908860214532 93953241955696 93973780156584 94003072685598
94011607687600 94014663572548 94024664508973 94108188461382 94118414338991 94229131092213 94245829151472 94290901685985 94528367009252 94575115016279
94783304425795 94842093540638 94974318126981 95018513804769 95113582596056 95135835034592 95313929182191 95421685049902 95456196443587 95483212511743
95560845168729 95683403248319 95684206633889 95786984433000 95789382584253 95802026624883 95822826165542 95836773740282 95848980465493 95930346495989
95988328299682 96030459022181 96081316447759 96098672256735 96120652264646 96173857867228 96256233494897 96353717013216 96411590446247 96457051803733
96621349191908 96642041189722 96704496510087 96713780691415 96730847431500 96787467085724 96795830260636 96807811261960 96953261090003 96959123077498
96972018543904 97012684885002 97154422752912 97216249743044 97280660636692 97288199640988 97307835906954 97315880968792 97343408124558 97463419427510
97519641378064 97521462422489 97612910871751 97613852288589 97623143664485 97643703791119 97690896670367 97738886670245 97810190906261 98027107618114
98031287364865 98055043535080 98121638141462 98244556967112 98302261167759 98322393239481 98479210674659 98566841867356 98574286322994 98649235539704
98711481420471 99002580763000 99100240941590 99127941563341 99159420513149 99360387424301 99383278437162 99422325754526 99510388830414 99536372883190
99556386801636 99628926500394 99653070274841 99718270135049 99780634905737 99862832334513 100004698566970 100126973934769 100129666722695 100184164753080
100185862847690 100330100817533 100360184176571 100418696357421 100433801577950 100449968742044 100505444434161 100535808517665 100562293382104 100587720921666
100662400255518 100689817115712 100727708379297 100792164613005 100844099640259 100863021259365 100918679787313 100926346851492 100958641158438 100979750429295
101011091728600 101038406269050 101107769924397 101124864542865 101131225943316 101137590137627 101146506140249 101161724557326 101165291450658 101227223247973
101229838123819 101275706634623 101377198088541 101446627880909 101466218614404 101490746801561 101504664673797 101507384132867 101612945938425 101781008026396
101795918868022 101938379339785 102125653264018 102177189829699 102343031936929 102352225830762 102517104852347 102544142014981 102549761959594 102641690959309
102674439625660 102729422823196 102757620248285 102758342993383 102808968188291 102813423311119 102817331366158 102923788301986 103056415211127 103176130742096
103260283077991 103289482976739 103292990933419 103448979252927 103496931496850 103586532241388 103616375410111 103661860023060 103739208028088 103909502408963
103925565298804 103956409434165 104081508620172 104180159480198 104248882545478 104254513227640 104452346305080 104483411955928 104541323860658 104633189834734
104656300300910 104716933591771 104872332016188 104881107477997 105140997102220 105142250700664 105145888100154 105229794708783 105277238434710 105289983764854
105339078669994 105370566505088 105382710555154 105482581116066 105527428740757 105614318732282 105739736253604 105755570483008 105774669595129 105841843462049
105846247896311 105905509045149 105933568415141 105937652127383 105977753794181 106008345326448 106014898528300 106030806891127 106107224125679 106129032532373
106131284872147 106151126926219 106154026040818 106208630407805 106251670395946 106349755833810 106409651791512 106482721095567 106488639225374 106517440208819
106562236722352 106595769617073 106623041186548 106628559713142 106633739940156 106699736662148 106763351206476 106799417603219 106869940043552 106980603015934
107036209300329 107074146593306 107160664457901 107161401337422 107171490975735 107398039634404 107435254765086 107458537039487 107643202594318 107671705266046
107772628162407 107898734387760 107960195144450 108005981863216 108018357044094 108084160579608 108094780314611 108123219065565 108124484075404 108248140801770
108266310513313 108366160811699 108440796949215 108444546629545 108472611655274 108521949644860 108531034992099 108584276806383 108600286132003 108620394282196
108731842286834 108772835409879 108773914369470 108805365263129 108807732150251 108810519694719 108890300089897 108904019076297 108911997126897 108988033471192
109007298197345 109052067985306 109156291984672 109329946130252 109350865867316 109402953259825 109497901209658 109518844930618 109535906315282 109573304254178
109741745972617 109783473904542 109920543027803 109931874166612 109963485310944 109990020345327 109995168389155 110056356354033 110263345381098 110278521132536
110299202997804 110304724778199 110317794646812 110343006435147 110400453990786 110510639468128 110681480366666 110732472861893 110742040919293 110758360963976
110759247982382 110799080912779 110807982053462 110811188234116 110840548362382 110871500527047 110871574906642 110880674717938 110883574501258 110912850533407
110935672851191 110965459998666 111006906961899 111037927085829 111080436135501 111129783683261 111182313403215 111203648826755 111270184603402 111293430242362
111334452749804 111338625384777 111339742631508 111506119023639 111582638139192 111586873525578 111704558370678 111770922203613 111827633192801 111829368976008
111910850942168 111939882228484 111956270003244 112035527459586 112081768119093 112128078253701 112139222041975 112213311883815 112298281479110 112363202904390
112433853643233 112452475192280 112547374697556 112577441488610 112619930138620 112706821141906 112753111309180 112791779158899 112815146017917 112822140371148
112827553875973 112836858002827 112869172742116 112904982368692 112945208623352 113001790502202 113005197134511 113007192288714 113024326630119 113066446110533
113087139742576 113099224373034 113103123109135 113113921926445 113155851733764 113227444179810 113292657343777 113467646580727 113472827755743 113700503533465
113726305782080 113738724573022 113741835225737 113796925192046 113899931890882 113904176464519 113920788489796 113936304594883 113962549708483 114112448829407
114122993572584 114191841925439 114259903538572 114294293966030 114296711476186 114474437643571 114588085596711 114602649996606 114634196965846 114748889503159
114755213905341 114853152317540 114860846955704 114882706303122 114904253860911 114970797246230 114975236395509 115019627913322 115210067469569 115231607256205
115244745042677 115245058023169 115267992424648 115280655936396 115331324585445 115397341225506 115423973500553 115488613914589 115592364988731 115649732793927
115669731360584 115706752305794 115877419084531 115916325346963 115917082488171 116004579351604 116060873290625 116105832874776 116147842114879 116148389421581
116162786785505 116289221071582 116291380884655 116295397687006 116380096681358 116427323741607 116506900864624 116558762558660 116592343144939 116616310968045
116686060909875 116692934183605 116771243266481 116784388951272 116842350341304 116857456272381 116876848522132 116900970230089 116910472741587 116941020589452
116942597286276 116972927817958 117006549202011 117173309592781 117222397116397 117292839019411 117324430494132 117410914314764 117412191148848 117504211604219
117550538145043 117587689359268 117590713655707 117615068025951 117717185619339 117723823631560 117828699507982 117849847882762 117870902749616 118234760889759
118257572369595 118311931183482 118339092741614 118366638077635 118402226127708 118488418483563 118517357251391 118571108101797 118621831662624 118804038666870
118867709440631 118880050663363 119067766354147 119074604149986 119168484373396 119188404948569 119209070572723 119280598684081 119288199682449 119327778708918
119335325175321 119345889564465 119346326910381 119462383658044 119519779879023 119611779691026 119624136068010 119643341407067 119646900646638 119679953768418
119699677339293 119738065164632 119850211147676 119935296649038 119943481988273 119996766986503 120013120426329 120032946472791 120148745136181 120218270793456
120389969121738 120412592360072 120476654166010 120539568812218 120665596356938 120718854472934 120725067908621 120748030255574 120767595546905 120773807614836
120776499310398 120817989918857 120825852019892 120902177402976 120924829056350 120929352398867 120960166545157 120988856869654 121006122669349 121058158887314
121166515120077 121185159212180 121243593961836 121255898612475 121309347003506 121347891120512 121367367704342 121380039303197 121390518225974 121443570579177
121459017607517 121473775534539 121536104967960 121699116574964 121717335514560 121781457295101 121898013469984 122007244120551 122151761156753 122162078197296
122213414206009 122264528794818 122302055355236 122319401934245 122371962597502 122429588373929 122487789432724 122503338277352 122529946855033 122557436618775
122559533202915 122560631718612 122565664861298 122573016073427 122597925233813 122608370066930 122690682987092 122912345398725 122946899281458 123142632470371
123157542848164 123171670878298 123215129529409 123253862012946 123293735177090 123320742161759 123419384803000 123498156538896 123520731647486 123527193752797
123548100869928 123569125830560 123594002459596 123698899800216 123699411767976 123708868452429 123777065685689 123814156880552 123825742002486 124032131134329
124033675853489 124068414067276 124119642679500 124215532829131 124270187386488 124272002745957 124622205682529 124707593649558 124791211614843 124872243546447
124960868758116 124986118696489 125023930482967 125030915988785 125161391464027 125192226174994 125204001568810 125319410206353 125362224367917 125366373801277
125437978106706 125438766513876 125440117259194 125671509058339 125743545948365 125768208949629 125798702096756 125840420233446 125854302746190 125900201216441
125931556541861 125957479722199 125985833335143 125999365316763 126054148464508 126098985250932 126109030290814 126140120178341 126238975283672 126281176589943
126332385197848 126382092382759 126523253248611 126570676614497 126606438039912 126620220725231 126814334954192 126825962075234 126909391115892 126923434178018
126938496789917 126983189124181 126983620703106 126984348148249 127013752168616 127022809880143 127040663332045 127106009973162 127130503594686 127139293480515
127141858350104 127231918563786 127253513515514 127298039793229 127306124223541 127324570265084 127401767293762 127506392754179 127536323817623 127573013841267
127594288458441 127652291827389 127755530615996 127777649118195 127786484164408 127790648288632 127791028527272 127973722365937 128035165547157 128084099365004
128168550673446 128183645442888 128255186877150 128298774463005 128320279762347 128320899215819 128328543441836 128340135534942 128394931942436 128400334757243
128512023248213 128551783267342 128587195479653 128799808092863 128850884706341 128880489187549 128908220116267 128919214051473 128921240595828 128975771999344
129005517677659 129006653115391 129117517211151 129119015496835 129152302298405 129173440043280 129181017641524 129190223230056 129195907130411 129350172653792
129385375997832 129406840176459 129477097133087 129521236287349 129588448585084 129620494969251 129631229460661 129634982268553 129787667723372 129820760266934
129843313690921 129910951313709 129945283266632 129951576127614 129971518622380 130001924616418 130041116394309 130098380563502 130287513138153 130290330916522
130392873815756 130502403364635 130524259632311 130606537450289 130637552077954 130659079955389 130754645470907 130771506470880 130917881974177 131082534135875
131199967126038 131257799030455 131277199680672 131327728887237 131328695448733 131362419608184 131396110927766 131442454114300 131453511625694 131472561580432
131481480691520 131512754101525 131517563873292 131523151782623 131533837041399 131568949178449 131616054685226 131696603025265 131704266460608 131736920206666
131781003912308 131781769879852 131789483021570 131826829778794 131836099627326 131891646802916 132010205222516 132038000256659 132060267650421 132074513251213
132122303610827 132159915700259 132234729944716 132245165667069 132298811847315 132300571328745 132511963182877 132515778394079 132519841143928 132584304532267
132610373037400 132724199941456 132772604766434 132794617032594 132829879655568 132847725386071 132947923470676 132948941669566 132993020983006 133127386399235
133156018431415 133195189578014 133204680956240 133260413018826 133292581373127 133312964070618 133313588241722 133355512418731 133398613783505 133405346709387
133436091713413 133488226792675 133496028081556 133523585529503 133545740458046 133602240732132 133602861880000 133714643570372 133723874069726 133801665981270
133983199176293 133994175153795 134038889511252 134041789900971 134115817576843 134221911406611 134225353237902 134227654572911 134227986260466 134293890565912
134296643761585 134318927811837 134323061188067 134391584994174 134406821688199 134437588126870 134537726966893 134546269326701 134579734137320 134687733365612
134695927009240 134747327262638 134759930605040 134836573014987 134851489464566 134917565187480 135067042655617 135100566264809 135167321078448 135209101640984
135330945802598 135371326491771 135418077255514 135437332314609 135456048923760 135472759112928 135562195148584 135588399072589 135626741115206 135658787753253
135661855835864 135695234002356 135766691703038 135936325011103 135970805422705 136007065400978 136060118510214 136106402892156 136143672498521 136152446719436
136213531829439 136252471123500 136362816997199 136393635685544 136411067377679 136427440487648 136514718850513 136564250872683 136660554586636 136678670049060
136708307742843 136716355967349 136726781289720 136740433360810 136772360775696 136849669900291 136876267994377 136899955921358 136925336395970 136961392444760
136982789776031 136987580707812 137044452306020 137055525435518 137115211481256 137127760483627 137197426302952 137221846503057 137297988168052 137322348468553
137551068213426 137564936043838 137581208033807 137655948227177 137709145156087 137711318144524 137943140212229 137972547366382 137985729278304 137986503339593
137994742279360 137998458253365 138008143986439 138040001965654 138046998128577 138127525232410 138129255700311 138243988286187 138257665334500 138375608358086
138407964761603 138481836562542 138492033527860 138508696181809 138546550159758 138556280723907 138724366893238 138727870113683 138861646822832 138936949998619
138989768117753 139007792784628 139041901204844 139112552825195 139207526053934 139225455829885 139238867747195 139291482794398 139359093114009 139435697248883
139481203631891 139514621219974 139560239820993 139566434036629 139568471938605 139603808545339 139658388720431 139719339704282 139868856317735 139882767322674
139929192105374 139937274908362 139952764344686 140017967270879 140018281208085 140454226744911 140497421620908 140514036075978 140564251020059 140619277510407
140671644163156 140703210927645 140716236419825 140728535975340 127802146383565 82691533602949
]], "%d+") do
                DELETE_SET["rbxassetid://" .. id] = true
            end

            local Desync = {}
            local running, ready = false, false
            local startToken = 0
            local conns = {}
            local hbConn, addedConn, watchedNoob = nil, nil, nil
            local savedCFrame, realCFrame, repCFrame = nil, nil, nil
            local realVelocity = Vector3.zero
            local swapped = false
            local lastChar = nil
            local forceReal = false
            local graceUntil = 0
            local externalHoldUntil = 0
            local pendingTeleport = nil
            local shownPrompts, holds = {}, {}
            local anchorPos, anchorExpire = nil, 0
            local lastReason = "init"

            local function dbg(msg)
                if DEBUG then print("[desync] " .. msg) end
            end

            local function containerExists()
                local playerGui = LP:FindFirstChildOfClass("PlayerGui")
                local mainUI = playerGui and playerGui:FindFirstChild("MainUI")
                return mainUI ~= nil and mainUI:FindFirstChild("AbilityContainer") ~= nil
            end

            local function puzzleGuiOpen()
                if #PUZZLE_GUI_NAMES == 0 then return false end
                local playerGui = LP:FindFirstChildOfClass("PlayerGui")
                if not playerGui then return false end
                for _, name in ipairs(PUZZLE_GUI_NAMES) do
                    local g = playerGui:FindFirstChild(name)
                    if g and g:IsA("ScreenGui") and g.Enabled then return true end
                end
                return false
            end

            local function hoveringClickDetector()
                if not HOVER_CLICKDETECTOR or not UIS.MouseEnabled then return false end
                local inst = Mouse.Target
                if not inst then return false end
                return inst:FindFirstChildWhichIsA("ClickDetector") ~= nil
                    or (inst.Parent ~= nil and inst.Parent:FindFirstChildWhichIsA("ClickDetector") ~= nil)
            end

            local function currentHRP()
                local char = LP.Character
                return char and char:FindFirstChild("HumanoidRootPart")
            end

            local function startHold(hrp)
                if HOLD_AFTER_TRIGGER and hrp then
                    anchorPos = hrp.Position
                    anchorExpire = os.clock() + HOLD_MAX_TIME
                end
            end

            -- Animation handling
            local animator, animConn = nil, nil
            local animateScript = nil
            local idleTrack, runTrack = nil, nil
            local moveIds = {}
            local animMode = "off"

            local function isMovementTrack(track)
                local anim = track.Animation
                if anim and moveIds[anim.AnimationId] then return true end
                local n = ((anim and anim.Name) or track.Name or ""):lower()
                for _, k in ipairs(BLOCK_KEYWORDS) do
                    if n:find(k, 1, true) then return true end
                end
                return false
            end

            local function loadTrack(id)
                if not id or not animator then return nil end
                local ok, track = pcall(function()
                    local anim = Instance.new("Animation")
                    anim.AnimationId = id
                    return animator:LoadAnimation(anim)
                end)
                return ok and track or nil
            end

            local function releaseAnimations()
                if animMode ~= "off" then
                    animMode = "off"
                    if idleTrack then pcall(function() idleTrack:Stop(0.2) end) end
                    if runTrack then pcall(function() runTrack:Stop(0.2) end) end
                    if animateScript and animateScript.Parent then animateScript.Disabled = false end
                end
                if animConn then animConn:Disconnect() animConn = nil end
                animator, animateScript, idleTrack, runTrack = nil, nil, nil, nil
                moveIds = {}
            end

            local function findAnimId(char, folderName, keywords)
                if animateScript then
                    local f = animateScript:FindFirstChild(folderName)
                    local a = f and f:FindFirstChildWhichIsA("Animation")
                    if a and a.AnimationId ~= "" then return a.AnimationId end
                end
                for _, d in ipairs(char:GetDescendants()) do
                    if d:IsA("Animation") and d.AnimationId ~= "" then
                        local n = d.Name:lower()
                        for _, k in ipairs(keywords) do
                            if n:find(k, 1, true) then return d.AnimationId end
                        end
                    end
                end
                return nil
            end

            local function setupAnimations(char, hum)
                releaseAnimations()
                if not HIDE_MOVEMENT_ANIMS then return end
                animator = hum:FindFirstChildOfClass("Animator")
                animateScript = char:FindFirstChild("Animate")
                if not animator then return end
                moveIds = {}
                if animateScript then
                    for _, folderName in ipairs({"run", "walk", "jump", "fall", "climb", "swim", "swimidle"}) do
                        local f = animateScript:FindFirstChild(folderName)
                        if f then
                            for _, a in ipairs(f:GetChildren()) do
                                if a:IsA("Animation") then moveIds[a.AnimationId] = true end
                            end
                        end
                    end
                end
                idleTrack = loadTrack(findAnimId(char, "idle", {"idle", "stand"}))
                runTrack = loadTrack(findAnimId(char, "run", {"run", "sprint"}))
                animConn = animator.AnimationPlayed:Connect(function(track)
                    if track == idleTrack or track == runTrack then return end
                    local move = isMovementTrack(track)
                    if animMode ~= "off" and move then
                        track:Stop(0)
                    end
                end)
            end

            local function setAnimMode(mode)
                if not HIDE_MOVEMENT_ANIMS or not animator or mode == animMode then return end
                local prev = animMode
                animMode = mode
                if mode == "off" then
                    if idleTrack then pcall(function() idleTrack:Stop(0.2) end) end
                    if runTrack then pcall(function() runTrack:Stop(0.2) end) end
                    if animateScript and animateScript.Parent then animateScript.Disabled = false end
                    return
                end
                if prev == "off" then
                    if animateScript and animateScript.Parent then animateScript.Disabled = true end
                    for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
                        if t ~= idleTrack and t ~= runTrack and isMovementTrack(t) then t:Stop(0.1) end
                    end
                end
                if mode == "run" and runTrack then
                    if idleTrack then pcall(function() idleTrack:Stop(0.15) end) end
                    pcall(function()
                        runTrack:Play(0.15)
                        runTrack:AdjustSpeed(math.clamp(TRAVEL_SPEED / 16, 0.5, 2))
                    end)
                else
                    if runTrack then pcall(function() runTrack:Stop(0.15) end) end
                    if idleTrack then pcall(function() idleTrack:Play(0.15) end) end
                end
            end

            -- Pathfinding
            local pathPoints, pathIndex, pathDest = nil, 1, nil
            local pathYOffset = 3
            local pathBusy = false
            local lastPathAt = 0
            local wasTraveling = false
            local tripStart = 0

            local function resetPath()
                pathPoints, pathIndex, pathDest = nil, 1, nil
            end

            local function requestPathIfNeeded(from, to, now)
                if not USE_PATHFINDING or pathBusy then return end
                if pathDest and (pathDest - to).Magnitude < 8 then return end
                if now - lastPathAt < 1.5 then return end
                pathBusy = true
                lastPathAt = now
                task.spawn(function()
                    local path = PFS:CreatePath({
                        AgentRadius = 2,
                        AgentHeight = 5,
                        AgentCanJump = true,
                        WaypointSpacing = 6,
                    })
                    local ok = pcall(function() path:ComputeAsync(from, to) end)
                    if ok and path.Status == Enum.PathStatus.Success then
                        local wps = path:GetWaypoints()
                        if #wps >= 2 then
                            pathPoints, pathIndex, pathDest = wps, 2, to
                            pathYOffset = math.clamp(to.Y - wps[#wps].Position.Y, 1, 6)
                        end
                    else
                        pathPoints, pathDest = nil, to
                    end
                    pathBusy = false
                end)
            end

            -- Pause logic (server sees the real position while interacting)
            local function pauseReason(currentPos)
                local now = os.clock()
                if forceReal then return "manual toggle (V)" end
                if now < externalHoldUntil then return "autofarm interaction" end
                if not AUTO_INTERACT then return nil end

                for prompt, startedAt in pairs(holds) do
                    if prompt.Parent == nil or now - startedAt > 8 then
                        holds[prompt] = nil
                    else
                        return "holding a prompt"
                    end
                end

                if now < graceUntil then return "grace after interaction" end
                if puzzleGuiOpen() then return "puzzle gui open" end

                if anchorPos then
                    if now > anchorExpire or (currentPos - anchorPos).Magnitude > LEAVE_DISTANCE then
                        anchorPos = nil
                        graceUntil = now + RESUME_DELAY
                    else
                        return "holding after trigger"
                    end
                end

                if PAUSE_WHILE_PROMPT_SHOWN then
                    for prompt in pairs(shownPrompts) do
                        if prompt.Parent == nil or not prompt.Enabled then
                            shownPrompts[prompt] = nil
                        else
                            return "prompt on screen"
                        end
                    end
                end

                if hoveringClickDetector() then return "hovering ClickDetector" end
                return nil
            end

            -- Invis
            local invisTrack, invisAnim = nil, nil
            local function applyInvis()
                local character = LP.Character
                if not character then return end
                local parts = {
                    character:FindFirstChild("Torso"),
                    character:FindFirstChild("UpperTorso"),
                    character:FindFirstChild("LowerTorso"),
                    character:FindFirstChild("HumanoidRootPart"),
                    character:FindFirstChild("Head"),
                }
                for _, part in ipairs(parts) do
                    if part then part.CanCollide = false end
                end
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                local invisAnimator = humanoid and humanoid:FindFirstChildOfClass("Animator")
                if invisAnimator then
                    if not invisAnim then
                        invisAnim = Instance.new("Animation")
                        invisAnim.AnimationId = "rbxassetid://75804462760596"
                    end
                    if invisTrack then invisTrack:Stop() end
                    invisTrack = invisAnimator:LoadAnimation(invisAnim)
                    invisTrack:Play()
                    invisTrack:AdjustSpeed(0)
                end
            end

            -- Main desync loop
            local function onHeartbeat(dt)
                if not containerExists() then return end

                local char = LP.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if not hrp or not hum then
                    savedCFrame, repCFrame = nil, nil
                    swapped = false
                    releaseAnimations()
                    return
                end

                if char ~= lastChar then
                    lastChar = char
                    savedCFrame, repCFrame = nil, nil
                    anchorPos = nil
                    setupAnimations(char, hum)
                end

                -- teleports requested by the autofarm are applied HERE so the desync restore step cannot undo them
                if pendingTeleport then
                    hrp.CFrame = pendingTeleport
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    pendingTeleport = nil
                end

                local realNow = hrp.CFrame
                if not savedCFrame then savedCFrame = realNow end
                if not repCFrame then repCFrame = realNow end

                local reason = pauseReason(hrp.Position)
                if reason ~= lastReason then
                    lastReason = reason or "active"
                    dbg(reason and ("going to real position: " .. reason) or "going back to saved spot")
                end

                local target = reason and realNow or savedCFrame

                local now = os.clock()
                local pos = repCFrame.Position
                local finalPos = target.Position
                local distFinal = (finalPos - pos).Magnitude
                local traveling = false
                local dir = Vector3.zero
                local travelSpeed = TRAVEL_SPEED

                if distFinal <= TRAVEL_SPEED * dt then
                    repCFrame = target
                    resetPath()
                    wasTraveling = false
                else
                    if not wasTraveling then tripStart = now end
                    wasTraveling = true
                    requestPathIfNeeded(pos, finalPos, now)

                    travelSpeed = TRAVEL_SPEED * math.clamp(0.55 + 0.45 * ((now - tripStart) / 0.6), 0.55, 1)
                    travelSpeed = travelSpeed * math.clamp(distFinal / 4, 0.55, 1)
                    local step = travelSpeed * dt
                    local goal = finalPos

                    if pathPoints then
                        local yOff = Vector3.new(0, pathYOffset, 0)
                        while pathIndex < #pathPoints
                            and (pathPoints[pathIndex].Position + yOff - pos).Magnitude <= math.max(step, 2) do
                            pathIndex += 1
                        end
                        local wp = pathPoints[pathIndex]
                        if wp then goal = wp.Position + yOff end
                    end

                    local toGoal = goal - pos
                    local gd = toGoal.Magnitude
                    dir = gd > 1e-3 and toGoal / gd or Vector3.zero
                    local newPos = pos + dir * math.min(step, gd)
                    local flat = Vector3.new(dir.X, 0, dir.Z)
                    if flat.Magnitude > 0.01 then
                        repCFrame = CFrame.lookAt(newPos, newPos + flat)
                    else
                        repCFrame = CFrame.new(newPos)
                    end
                    traveling = true
                end

                if reason and not traveling then
                    swapped = false
                    repCFrame = realNow
                    setAnimMode("off")
                    return
                end

                setAnimMode(traveling and "run" or "idle")
                realCFrame = realNow
                realVelocity = hrp.AssemblyLinearVelocity
                hrp.CFrame = repCFrame
                hrp.AssemblyLinearVelocity = traveling and (dir * travelSpeed) or Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                swapped = true
            end

            -- Noob asset cleanup
            local function getNoob()
                local players = workspace:FindFirstChild("Players")
                local survivors = players and players:FindFirstChild("Survivors")
                return survivors and survivors:FindFirstChild("Noob")
            end

            local function sweep(noob)
                for _, child in ipairs(noob:GetChildren()) do
                    if DELETE_SET[child.Name] then
                        pcall(function() child:Destroy() end)
                    end
                end
            end

            function Desync.Start()
                if running then return end
                running = true
                startToken += 1
                local token = startToken
                -- clean a previous standalone run of the original file, if there was one
                pcall(function()
                    local env = (type(getgenv) == "function" and getgenv()) or _G
                    if env.DesyncCleanup then pcall(env.DesyncCleanup) end
                end)
                pcall(function() RS:UnbindFromRenderStep("DesyncRestore") end)

                task.spawn(function()
                    if not containerExists() then farmNotify("waiting for abilitycontainer...") end
                    while running and token == startToken and not containerExists() do
                        task.wait(0.25)
                    end
                    if not running or token ~= startToken then return end
                    farmNotify("abilitycontainer found, desync started")

                    table.insert(conns, PPS.PromptShown:Connect(function(p) shownPrompts[p] = true end))
                    table.insert(conns, PPS.PromptHidden:Connect(function(p)
                        shownPrompts[p] = nil
                        graceUntil = os.clock() + RESUME_DELAY
                    end))
                    table.insert(conns, PPS.PromptButtonHoldBegan:Connect(function(p)
                        holds[p] = os.clock()
                        startHold(currentHRP())
                    end))
                    table.insert(conns, PPS.PromptButtonHoldEnded:Connect(function(p)
                        holds[p] = nil
                        graceUntil = os.clock() + RESUME_DELAY
                    end))
                    table.insert(conns, PPS.PromptTriggered:Connect(function(p)
                        holds[p] = nil
                        startHold(currentHRP())
                        graceUntil = os.clock() + RESUME_DELAY
                    end))
                    table.insert(conns, UIS.InputBegan:Connect(function(input, processed)
                        if processed then return end
                        if input.KeyCode == PAUSE_KEY then
                            forceReal = not forceReal
                            if not forceReal then graceUntil = os.clock() + RESUME_DELAY end
                        end
                    end))

                    pcall(applyInvis)
                    table.insert(conns, LP.CharacterAdded:Connect(function()
                        task.wait(0.4)
                        if running then pcall(applyInvis) end
                    end))

                    hbConn = RS.Heartbeat:Connect(onHeartbeat)
                    RS:BindToRenderStep("DesyncRestore", Enum.RenderPriority.First.Value, function()
                        if not swapped then return end
                        swapped = false
                        local hrp = currentHRP()
                        if hrp and realCFrame then
                            hrp.CFrame = realCFrame
                            hrp.AssemblyLinearVelocity = realVelocity
                        end
                    end)
                    ready = true

                    -- loop-delete the Noob assets
                    while running and token == startToken do
                        local noob = getNoob()
                        if noob then
                            if noob ~= watchedNoob then
                                if addedConn then addedConn:Disconnect() end
                                watchedNoob = noob
                                addedConn = noob.ChildAdded:Connect(function(child)
                                    if DELETE_SET[child.Name] then
                                        pcall(function() child:Destroy() end)
                                    end
                                end)
                            end
                            sweep(noob)
                        end
                        task.wait(0.1)
                    end
                end)
            end

            function Desync.Stop()
                if not running then return end
                running = false
                ready = false
                startToken += 1
                -- put the real character back where the client is, instead of the replicated spot
                if swapped and realCFrame then
                    local hrp = currentHRP()
                    if hrp then
                        hrp.CFrame = realCFrame
                        hrp.AssemblyLinearVelocity = realVelocity
                    end
                end
                swapped = false
                if hbConn then hbConn:Disconnect() hbConn = nil end
                if addedConn then addedConn:Disconnect() addedConn = nil end
                for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
                conns = {}
                pcall(function() RS:UnbindFromRenderStep("DesyncRestore") end)
                if invisTrack then pcall(function() invisTrack:Stop() end) invisTrack = nil end
                releaseAnimations()
                savedCFrame, repCFrame, realCFrame, lastChar = nil, nil, nil, nil
                pendingTeleport, watchedNoob, anchorPos = nil, nil, nil
                externalHoldUntil, forceReal = 0, false
            end

            -- keep the server seeing the REAL position for a while (needed to interact with prompts)
            function Desync.Hold(seconds)
                externalHoldUntil = math.max(externalHoldUntil, os.clock() + (seconds or 1))
            end

            -- teleport that survives the desync restore step
            function Desync.Teleport(cf)
                local hrp = currentHRP()
                if not hrp then return false end
                if running and ready and containerExists() then
                    pendingTeleport = cf
                    task.delay(0.3, function()
                        if pendingTeleport == cf then
                            pendingTeleport = nil
                            local h = currentHRP()
                            if h then h.CFrame = cf end
                        end
                    end)
                else
                    hrp.CFrame = cf
                    hrp.AssemblyLinearVelocity = Vector3.zero
                end
                return true
            end

            ------------------------------------------------------------------
            -- Autofarm loop: gear -> generator, with generatorwarning handling
            ------------------------------------------------------------------
            local Farm = { running = false, token = 0 }
            local finished = setmetatable({}, { __mode = "k" })
            local blacklist = setmetatable({}, { __mode = "k" })
            local previous = {}
            local MIN_CYCLE = 2.57
            local lastTeleportAt = 0

            -- never teleport more than once every 0.45s (constant teleporting is what cancelled the puzzle)
            local function farmTeleport(cf)
                local gap = os.clock() - lastTeleportAt
                if gap < 0.45 then task.wait(0.45 - gap) end
                lastTeleportAt = os.clock()
                Desync.Teleport(cf)
            end

            -- the server needs a moment to see the new position; firing a prompt before that gives
            -- "move a bit closer to an available side of the generator"
            local function settleDelay()
                local ok, ping = pcall(function() return LP:GetNetworkPing() end)
                ping = (ok and type(ping) == "number" and ping == ping) and ping or 0.08
                return math.clamp(ping * 2 + 0.15, 0.25, 0.8)
            end

            local function press(prompt)
                pcall(function() prompt.HoldDuration = 0 end)
                if fireproximityprompt then
                    pcall(fireproximityprompt, prompt)
                else
                    pcall(function() prompt:InputHoldBegin(); task.wait(); prompt:InputHoldEnd() end)
                end
            end

            local function mapFolder()
                local map = Workspace:FindFirstChild("Map")
                local ingame = map and map:FindFirstChild("Ingame")
                return ingame and ingame:FindFirstChild("Map")
            end

            local function instanceCFrame(inst)
                if not inst then return nil end
                if inst:IsA("BasePart") then return inst.CFrame end
                if inst:IsA("Attachment") then return inst.WorldCFrame end
                if inst:IsA("Model") then return inst:GetPivot() end
                return nil
            end

            local function spotCFrame(gen, name)
                local positions = gen:FindFirstChild("Positions")
                return instanceCFrame(positions and positions:FindFirstChild(name))
            end

            local function generatorPrompt(gen)
                local main = gen:FindFirstChild("Main")
                return main and main:FindFirstChild("Prompt")
            end

            local function getRoot()
                local char = LP.Character
                return char and char:FindFirstChild("HumanoidRootPart")
            end

            local function isKiller()
                local char = LP.Character
                return char ~= nil and char.Parent ~= nil and char.Parent.Name == "Killers"
            end

            local function warningGui()
                local playerGui = LP:FindFirstChildOfClass("PlayerGui")
                local temporary = playerGui and playerGui:FindFirstChild("TemporaryUI")
                return temporary and temporary:FindFirstChild("GeneratorWarning")
            end

            local function puzzleOpen()
                local playerGui = LP:FindFirstChildOfClass("PlayerGui")
                local puzzle = playerGui and playerGui:FindFirstChild("PuzzleUI")
                return puzzle ~= nil and puzzle:FindFirstChild("Container") ~= nil
            end

            -- step 1: teleport to a gear and fire its prompt continuously for 0.15s
            local function grabGear()
                local map = mapFolder()
                local folder = map and map:FindFirstChild("GearsTest")
                local root = getRoot()
                if not folder or not root then return false end
                local best, bestPrompt, bestDistance
                for _, d in ipairs(folder:GetDescendants()) do
                    if (d.Name == "Gear" or d.Parent == folder) and (d:IsA("Model") or d:IsA("BasePart")) then
                        local prompt = d:FindFirstChildWhichIsA("ProximityPrompt", true)
                        local cf = instanceCFrame(d)
                        if prompt and prompt.Enabled and cf then
                            local distance = (cf.Position - root.Position).Magnitude
                            if not bestDistance or distance < bestDistance then
                                best, bestPrompt, bestDistance = d, prompt, distance
                            end
                        end
                    end
                end
                if not best then return false end
                Desync.Hold(1.5)
                farmTeleport(instanceCFrame(best) * CFrame.new(0, 3, 0))
                task.wait(settleDelay())
                local startedAt = os.clock()
                repeat
                    press(bestPrompt)
                    task.wait()
                until os.clock() - startedAt >= 0.15 or not Farm.running or not bestPrompt.Parent
                return true
            end

            -- generators with a killer close to them (workspace.Players.Killers)
            local KILLER_NEAR = 45
            local noSafeSince = nil
            local function killerNear(position)
                local players = workspace:FindFirstChild("Players")
                local killers = players and players:FindFirstChild("Killers")
                if not killers then return false end
                for _, killer in ipairs(killers:GetChildren()) do
                    local hrp = killer:FindFirstChild("HumanoidRootPart")
                    if hrp and (hrp.Position - position).Magnitude <= KILLER_NEAR then return true end
                end
                return false
            end

            local function pickGenerator()
                local map = mapFolder()
                local root = getRoot()
                if not map or not root then return nil end
                local now = os.clock()
                local total, finishedCount, candidates = 0, 0, {}
                for _, obj in ipairs(map:GetChildren()) do
                    if obj:IsA("Model") and obj.Name ~= "FakeGenerator" and obj.Name:lower():find("generator") then
                        total += 1
                        -- same check the generator esp uses (an unfinished generator is the highlighted one)
                        if IsGeneratorFinished(obj) then
                            finished[obj] = true
                        end
                        if finished[obj] then
                            finishedCount += 1
                        elseif not (blacklist[obj] and blacklist[obj] > now) then
                            local cf = spotCFrame(obj, "Center") or instanceCFrame(obj)
                            if cf then
                                table.insert(candidates, {
                                    gen = obj,
                                    distance = (cf.Position - root.Position).Magnitude,
                                    nearKiller = killerNear(cf.Position),
                                })
                            end
                        end
                    end
                end

                -- "ignore generators when the killer is near it": skipped, unless almost every generator is already done
                -- (e.g. 3/5), or there has been nothing else to do for a while - then go to the ones near the killer
                local avoidKiller = State.AutoFarmAvoidKiller
                local almostDone = total > 0 and (finishedCount / total) >= 0.6
                local best, bestDistance, skipped = nil, nil, false
                for _, candidate in ipairs(candidates) do
                    if avoidKiller and candidate.nearKiller and not almostDone
                        and not (noSafeSince and now - noSafeSince > 15) then
                        skipped = true
                    elseif not bestDistance or candidate.distance < bestDistance then
                        best, bestDistance = candidate.gen, candidate.distance
                    end
                end
                if best then
                    noSafeSince = nil
                elseif skipped then
                    noSafeSince = noSafeSince or now
                else
                    noSafeSince = nil
                end
                return best
            end

            -- step 2: teleport to the generator, interact, and handle generatorwarning
            local function farmGenerator(gen)
                local prompt = generatorPrompt(gen)
                local center = spotCFrame(gen, "Center")
                if not prompt or not center then
                    blacklist[gen] = os.clock() + 30
                    return
                end

                grabGear()
                if not Farm.running or not gen.Parent then return end

                Desync.Hold(2)
                farmTeleport(center * CFrame.new(0, 3, 0))
                task.wait(settleDelay())

                -- a warning left over from the previous attempt stays up for 10+ seconds: clear it, dont count it
                local stale = warningGui()
                if stale then pcall(function() stale:Destroy() end) end

                local startedAt, lastFire = os.clock(), 0
                local warnings, pending, wasOn = 0, nil, false
                local offSince = os.clock()

                while Farm.running and gen.Parent do
                    local now = os.clock()
                    if IsGeneratorFinished(gen) then
                        finished[gen] = true
                        break
                    end

                    local onGen = puzzleOpen()
                    local warning = warningGui()
                    if onGen then
                        wasOn = true
                        offSince = now
                        Desync.Hold(0.8)
                        pending = nil -- never move while the puzzle is open (moving is what closed it)
                        if warning then pcall(function() warning:Destroy() end) end
                    elseif wasOn then
                        break -- got off the generator: go grab a fresh gear
                    else
                        Desync.Hold(0.8)
                        if not pending and now - lastFire >= 0.3 then
                            lastFire = now
                            press(prompt)
                        end

                        -- generatorwarning: delete after 0.5s, move after 0.6s (center -> left -> right -> give up)
                        if warning and not pending then
                            warnings += 1
                            if warnings >= 3 then
                                task.delay(0.5, function() pcall(function() warning:Destroy() end) end)
                                blacklist[gen] = os.clock() + 60
                                farmNotify("plr gave up on a generator (generatorwarning)")
                                break
                            end
                            pending = { seenAt = now, gui = warning, deleted = false }
                        end
                        if pending then
                            if not pending.deleted and now - pending.seenAt >= 0.5 then
                                pending.deleted = true
                                pcall(function() pending.gui:Destroy() end)
                            end
                            if now - pending.seenAt >= 0.6 then
                                local spot = spotCFrame(gen, warnings == 1 and "Left" or "Right")
                                pending = nil
                                if spot and not puzzleOpen() then
                                    Desync.Hold(2)
                                    farmTeleport(spot * CFrame.new(0, 3, 0))
                                    task.wait(settleDelay())
                                end
                                lastFire = os.clock()
                            end
                        end
                    end

                    -- never get stuck on one generator
                    if not onGen and now - offSince > 7 then
                        blacklist[gen] = os.clock() + 25
                        break
                    end
                    if now - startedAt > 45 then
                        blacklist[gen] = os.clock() + 25
                        break
                    end
                    task.wait(0.05)
                end
                Desync.Hold(0.4)
            end

            ------------------------------------------------------------------
            -- queue_on_teleport: re-run the script (and autofarm) in the next server
            ------------------------------------------------------------------
            local STUB = [[
if not game:IsLoaded() then game.Loaded:Wait() end
local settingsFile = %q
if type(isfile) ~= "function" or type(readfile) ~= "function" or not isfile(settingsFile) then return end
local okRead, raw = pcall(function() return readfile(settingsFile) end)
if not okRead then return end
local okJson, settings = pcall(function() return game:GetService("HttpService"):JSONDecode(raw) end)
if not okJson or type(settings) ~= "table" or settings.autofarm ~= true then return end
local env = (type(getgenv) == "function" and getgenv()) or _G
env.__f8z_autofarm_resume = settings
local url, file = %q, %q
local ok, err = true, nil
if url ~= "" then
    ok, err = pcall(function() loadstring(game:HttpGet(url))() end)
elseif type(isfile) == "function" and isfile(file) then
    ok, err = pcall(function() loadstring(readfile(file))() end)
else
    warn("[forsaken8z] autofarm: cant re-run, save the script as " .. file .. " in your workspace folder or set AUTOFARM_SCRIPT_URL")
    return
end
if not ok then warn("[forsaken8z] autofarm re-run failed: " .. tostring(err)) end
]]

            local queuedThisSession = false
            -- everything in the autofarm tab is saved here; the queued stub only restores it if autofarm was ON
            local function saveSettings()
                if not writefile then return end
                local data = {
                    autofarm = State.AutoFarm == true,
                    hop = State.AutoFarmHop == true,
                    candies = State.AutoFarmCandies == true,
                    avoidKiller = State.AutoFarmAvoidKiller == true,
                    abilities = State.AutoUseAbilities == true,
                }
                pcall(function() writefile(SETTINGS_FILE, HttpService:JSONEncode(data)) end)
            end

            local function queueRerun()
                if queuedThisSession then return end
                local queueFn = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
                if not queueFn then
                    farmNotify("queue_on_teleport is unsupported, autofarm wont re-run after a serverhop")
                    return
                end
                local hasSource = AUTOFARM_SCRIPT_URL ~= "" or (isfile and isfile(AUTOFARM_SCRIPT_FILE))
                if not hasSource then
                    pcall(function()
                        windui:Notify({
                            Title = "autofarm",
                            Content = "to re-run after serverhop, save this script as " .. AUTOFARM_SCRIPT_FILE .. " in your workspace folder (or set AUTOFARM_SCRIPT_URL)",
                            Duration = 5
                        })
                    end)
                end
                local stub = string.format(STUB, SETTINGS_FILE, AUTOFARM_SCRIPT_URL, AUTOFARM_SCRIPT_FILE)
                if pcall(queueFn, stub) then queuedThisSession = true end
            end

            ------------------------------------------------------------------
            -- serverhop: random server out of the best-ping ones
            ------------------------------------------------------------------
            local hopping = false

            local function fetchServers()
                local servers, cursor = {}, nil
                for _ = 1, 3 do
                    local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true"):format(game.PlaceId)
                    if cursor then url = url .. "&cursor=" .. cursor end
                    local okGet, body = pcall(function() return game:HttpGet(url) end)
                    if not okGet then break end
                    local okJson, data = pcall(function() return HttpService:JSONDecode(body) end)
                    if not okJson or type(data) ~= "table" or type(data.data) ~= "table" then break end
                    for _, server in ipairs(data.data) do table.insert(servers, server) end
                    cursor = data.nextPageCursor
                    if not cursor then break end
                end
                return servers
            end

            local function serverHop()
                if hopping then return end
                hopping = true
                farmNotify("all generators are done, looking for a new server")
                local candidates = {}
                for _, server in ipairs(fetchServers()) do
                    if type(server) == "table" and server.id and server.id ~= game.JobId
                        and (tonumber(server.playing) or 0) < (tonumber(server.maxPlayers) or 0) - 1 then
                        table.insert(candidates, server)
                    end
                end
                if #candidates == 0 then
                    farmNotify("serverhop: no servers found, retrying in 10s")
                    hopping = false
                    task.wait(10)
                    return
                end
                -- best ping first, then pick randomly among the 5 best so repeated hops dont all land on the same server
                table.sort(candidates, function(a, b)
                    return (tonumber(a.ping) or 9e9) < (tonumber(b.ping) or 9e9)
                end)
                local pool = {}
                for i = 1, math.min(5, #candidates) do pool[i] = candidates[i] end
                while #pool > 0 and Farm.running do
                    local server = table.remove(pool, math.random(1, #pool))
                    local failed = false
                    local failConn = TeleportService.TeleportInitFailed:Connect(function(player)
                        if player == LP then failed = true end
                    end)
                    farmNotify("serverhop: joining a server (" .. tostring(math.floor(tonumber(server.ping) or 0)) .. " ms)")
                    local okTeleport = pcall(function()
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LP)
                    end)
                    local waited = 0
                    while okTeleport and not failed and waited < 15 and Farm.running do
                        task.wait(0.25)
                        waited += 0.25
                    end
                    failConn:Disconnect()
                end
                hopping = false
                task.wait(5)
            end

            local function allGeneratorsFinished()
                local map = mapFolder()
                if not map then return false end
                local total = 0
                for _, obj in ipairs(map:GetChildren()) do
                    if obj:IsA("Model") and obj.Name ~= "FakeGenerator" and obj.Name:lower():find("generator") then
                        total += 1
                        if not IsGeneratorFinished(obj) then return false end
                    end
                end
                return total > 0
            end

            ------------------------------------------------------------------
            -- candies (halloween currency): visited one by one, blacklisted once tried
            ------------------------------------------------------------------
            local candyAttempts = setmetatable({}, { __mode = "k" })
            local MAX_CANDY_ATTEMPTS = 2

            local function pickCandy()
                local map = mapFolder()
                local spawns = map and map:FindFirstChild("CurrencySpawns")
                local root = getRoot()
                if not spawns or not root then return nil end
                local best, bestAttempts, bestDistance
                for _, candy in ipairs(spawns:GetChildren()) do
                    local attempts = candyAttempts[candy] or 0
                    local part = candy.Name == "C00lCandy" and candy:FindFirstChild("Root")
                    if part and attempts < MAX_CANDY_ATTEMPTS then
                        local cf = instanceCFrame(part)
                        if cf then
                            local distance = (cf.Position - root.Position).Magnitude
                            if not best or attempts < bestAttempts or (attempts == bestAttempts and distance < bestDistance) then
                                best, bestAttempts, bestDistance = candy, attempts, distance
                            end
                        end
                    end
                end
                return best
            end

            -- a different candy every 0.15s, firing its prompt
            local function collectCandy(candy)
                candyAttempts[candy] = (candyAttempts[candy] or 0) + 1
                local part = candy:FindFirstChild("Root")
                local prompt = part and part:FindFirstChild("ProximityPrompt")
                if not prompt then
                    candyAttempts[candy] = 99 -- nothing to collect: blacklisted
                    return
                end
                Desync.Hold(0.6)
                Desync.Teleport(instanceCFrame(part) * CFrame.new(0, 3, 0))
                local startedAt = os.clock()
                repeat
                    press(prompt)
                    task.wait()
                until os.clock() - startedAt >= 0.15 or not Farm.running or not prompt.Parent
            end

            local joinedAt = os.clock()
            local doneSince = nil

            local function farmLoop(token)
                while ScriptRunning and Farm.running and token == Farm.token do
                    if not (containerExists() and getRoot()) or isKiller() then
                        doneSince = nil
                        task.wait(0.5)
                    else
                        local gen = pickGenerator()
                        if gen then
                            doneSince = nil
                            local cycleStart = os.clock()
                            local okCycle, errCycle = pcall(farmGenerator, gen)
                            if not okCycle then
                                warn("[autofarm] " .. tostring(errCycle))
                                task.wait(0.5)
                            end
                            -- each generator step no faster than every 2.57s (the server kicks you for going faster)
                            local remaining = MIN_CYCLE - (os.clock() - cycleStart)
                            if remaining > 0 and Farm.running then task.wait(remaining) end
                        elseif State.AutoFarmHop and allGeneratorsFinished() then
                            local candy = State.AutoFarmCandies and pickCandy() or nil
                            if candy then
                                -- candies first: only serverhop once every candy has been blacklisted
                                doneSince = nil
                                local okCandy, errCandy = pcall(collectCandy, candy)
                                if not okCandy then
                                    warn("[autofarm] " .. tostring(errCandy))
                                    task.wait(0.15)
                                end
                            else
                                doneSince = doneSince or os.clock()
                                if os.clock() - doneSince >= 2 and os.clock() - joinedAt >= 20 then
                                    serverHop()
                                    doneSince = nil
                                end
                                task.wait(0.5)
                            end
                        else
                            -- serverhop is off: still collect candies when everything is done
                            if State.AutoFarmCandies and allGeneratorsFinished() then
                                local candy = pickCandy()
                                if candy then
                                    pcall(collectCandy, candy)
                                else
                                    task.wait(0.5)
                                end
                            else
                                doneSince = nil
                                task.wait(0.5)
                            end
                        end
                    end
                end
            end

            local function startFarm()
                if Farm.running then return end
                Farm.running = true
                Farm.token += 1
                previous.AutoGenNew, previous.AutoGenDuration = State.AutoGenNew, State.AutoGenDuration
                State.AutoGenNew = true          -- run auto gen (NEW)
                State.AutoGenDuration = 2.57     -- 2.57s between each solve
                State.AutoFarm = true
                saveSettings()
                queueRerun()                     -- re-run this script after a serverhop / teleport
                Desync.Start()                   -- runs the desync script first
                task.spawn(farmLoop, Farm.token)
                farmNotify("autofarm started")
            end

            local function stopFarm()
                if not Farm.running then return end
                Farm.running = false
                Farm.token += 1
                State.AutoFarm = false
                saveSettings()
                Desync.Stop()
                if previous.AutoGenNew ~= nil then State.AutoGenNew = previous.AutoGenNew end
                if previous.AutoGenDuration ~= nil then State.AutoGenDuration = previous.AutoGenDuration end
                farmNotify("autofarm stopped")
            end

            -- clean up when the script is destroyed
            task.spawn(function()
                while ScriptRunning do task.wait(0.5) end
                stopFarm()
            end)

            -- coming back from a serverhop: restore the autofarm tab settings (only if autofarm was on)
            local resumeSettings = nil
            pcall(function()
                local env = (type(getgenv) == "function" and getgenv()) or _G
                if type(env.__f8z_autofarm_resume) == "table" then resumeSettings = env.__f8z_autofarm_resume end
                env.__f8z_autofarm_resume = nil
            end)
            if resumeSettings and resumeSettings.autofarm == true then
                State.AutoFarm = true
                State.AutoFarmHop = resumeSettings.hop ~= false
                State.AutoFarmCandies = resumeSettings.candies == true
                State.AutoFarmAvoidKiller = resumeSettings.avoidKiller == true
                State.AutoUseAbilities = resumeSettings.abilities == true
            else
                resumeSettings = nil
            end

            autofarm_tab:Toggle({
                Title = "autofarm",
                Desc = "this makes you be invisible and desynced while tping to generators and doing them",
                Value = State.AutoFarm,
                Callback = function(val)
                    State.AutoFarm = val
                    if val then startFarm() else stopFarm() end
                    saveSettings()
                end
            })
            autofarm_tab:Toggle({
                Title = "autofarm serverhop",
                Desc = "when every generator is done, hops to a random server out of the best ping ones (autofarm re-runs itself there)",
                Value = State.AutoFarmHop,
                Callback = function(val)
                    State.AutoFarmHop = val
                    saveSettings()
                end
            })
            autofarm_tab:Toggle({
                Title = "ignore generators when the killer is near it",
                Desc = "this ignores generators when a killer is near it, if it detects that almost all (for example, 3/5 generators are done and one is full of players) it will tp to generators that are near the killer for the round to progress faster",
                Value = State.AutoFarmAvoidKiller,
                Callback = function(val)
                    State.AutoFarmAvoidKiller = val
                    saveSettings()
                end
            })
            autofarm_tab:Toggle({
                Title = "auto collect candies (halloween currencies) when autofarming",
                Desc = "this auto collects them when all generators are done for more efficiency i guess",
                Value = State.AutoFarmCandies,
                Callback = function(val)
                    State.AutoFarmCandies = val
                    saveSettings()
                end
            })

            -- auto use abilities (moved here from the automation tab): fires every ability remote every 0.3s
            local abilityNames = {
                "Block", "Charge", "Punch", "Slash", "FriedChicken", "ThrowPizza", "RushHour", "Clone", "c00lgui",
                "Pulse", "Inspiration", "SubspaceTripmine", "Tripwire", "CoinFlip", "Shoot", "Reroll", "HatFix",
                "Dagger", "Crouch", "Pray", "Ritual", "PlasmaBeam", "SpawnProtection", "BloxyCola", "SlateskinPotion",
                "Ghostburger", "Crystal", "Axe"
            }
            autofarm_tab:Toggle({
                Title = "auto use abilities",
                Desc = "fires every ability remote (guest, shedletsky, elliot, 007n7, helperbot, taph, chance, two time, dusekkar, noob, jane doe) every 0.3 seconds",
                Value = State.AutoUseAbilities,
                Callback = function(val)
                    State.AutoUseAbilities = val
                    saveSettings()
                end
            })
            task.spawn(function()
                while ScriptRunning do
                    if State.AutoUseAbilities and containerExists() then
                        pcall(function()
                            local remote = game:GetService("ReplicatedStorage").Modules.Network.Network.RemoteEvent
                            for _, name in ipairs(abilityNames) do
                                remote:FireServer("UseActorAbility", { name })
                            end
                        end)
                    end
                    task.wait(0.3)
                end
            end)

            -- after a serverhop: only start autofarming automatically once MainUI.AbilityContainer exists
            if resumeSettings then
                task.spawn(function()
                    while ScriptRunning and State.AutoFarm and not Farm.running do
                        if containerExists() then
                            startFarm()
                            break
                        end
                        task.wait(0.5)
                    end
                end)
            end
        end)
        if not okFarm then warn("[forsaken8z] autofarm failed to load: " .. tostring(errFarm)) end
    end

    -- Auto Block Controls
    block_tab:Toggle({ Title = "auto block", Desc = "Triggers guard/block when killer attacks near you", Value = State.AutoBlock, Callback = function(val) State.AutoBlock = val end })
    block_tab:Toggle({
        Title = "make auto block not block things like nolis void rush or demonic pursuit",
        Desc = "this originally had things like void rush marked to block but the FUCKING forsaken devs nerfed guest so you cant block them now (you can still block all of them on fangames though i think)",
        Value = State.AutoBlockNoDash,
        Callback = function(val)
            State.AutoBlockNoDash = val
            ApplyDashFilter(val)
        end
    })
    block_tab:Toggle({ Title = "auto punch", Desc = "punches for you when the guest parry icon shows up (also locks the camera to the killer when punching)", Value = State.AutoPunch, Callback = function(val)
        State.AutoPunch = val
        State.AimPunch = val
    end })
    block_tab:Slider({
        Title = "auto punch delay",
        Desc = "seconds to wait before punching (default 0.5)",
        Value = { Min = 0, Max = 1.5, Default = State.AutoPunchDelay, Step = 0.05 },
        Callback = function(val) State.AutoPunchDelay = tonumber(val) or 0.5 end
    })
    task.spawn(function()
        local okPunch, errPunch = pcall(function()
--[[
	Auto Punch (raw, no GUI)
	Punches automatically when the "1337 Parry" icon event fires for you.
	Extracted from Guesting Hub v2.8.
]]


-- ===== CONFIG =====

-- ===== SERVICES =====
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = game:GetService("Players").LocalPlayer

local networkFolder = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Network"):WaitForChild("Network")
local remoteEvent = networkFolder:WaitForChild("RemoteEvent")
local Network = require(networkFolder)

local function punch()
	remoteEvent:FireServer("UseActorAbility", { "Punch" })
end

-- ===== HOOK =====
local parryEventName = localPlayer.Name .. "1337ParryIcon"
local originalSetConnection = Network.SetConnection

Network.SetConnection = function(self, name, kind, callback)
	if name == parryEventName and kind == "REMOTE_EVENT" then
		return originalSetConnection(self, name, kind, function(triggered)
			if callback then
				pcall(callback, triggered)
			end

			if triggered and State.AutoPunch then
				if (State.AutoPunchDelay or 0.5) > 0 then
					task.wait(State.AutoPunchDelay or 0.5)
				end
				pcall(punch)
			end
		end)
	end

	return originalSetConnection(self, name, kind, callback)
end

        end)
        if not okPunch then warn("[forsaken8z] auto punch hook failed: " .. tostring(errPunch)) end
    end)
    block_tab:Slider({ Title = "range detection", Desc = "distance (in studs) required to trigger block", Value = { Min = 4, Max = 20, Default = State.AutoBlockRange, Step = 0.5 }, Callback = function(val) State.AutoBlockRange = val end })
    block_tab:Toggle({
        Title = "007n7 auto block",
        Desc = "blocks using his clones i guess, this has the same functions as the guest auto block but just a little bit different",
        Value = State.Auto007Block,
        Callback = function(val) State.Auto007Block = val end
    })
    block_tab:Slider({
        Title = "change when to block using ur clones (007n7) in studs",
        Desc = "uhh, i recommend like 11 or something idk",
        Value = { Min = 2, Max = 20, Default = State.CloneBlockRange, Step = 0.5 },
        Callback = function(val) State.CloneBlockRange = tonumber(val) or 9.5 end
    })
    -- 007n7 auto block joins the accurate auto block engine (same threat tracking as the guest auto block)
    table.insert(blockConsumers, {
        enabled = function() return State.Auto007Block end,
        range = function() return State.CloneBlockRange or 9.5 end,
        fire = function()
            pcall(function()
                game:GetService("ReplicatedStorage").Modules.Network.Network.RemoteEvent:FireServer("UseActorAbility", { "Clone" })
            end)
        end,
    })

    -- Stamina Controls
    stamina_tab:Toggle({ Title = "enable custom sprint speed", Desc = "must be on to use custom sprint speed", Value = State.EnableCustomSpeed, Callback = function(val) State.EnableCustomSpeed = val end })
    stamina_tab:Slider({ Title = "sprint speed", Desc = "speed while sprinting", Value = { Min = 16, Max = 50, Default = State.SprintSpeedValue, Step = 0.5 }, Callback = function(val) State.SprintSpeedValue = val end })
    stamina_tab:Slider({ Title = "stamina drain rate", Desc = "adjust how fast stamina drains", Value = { Min = 0, Max = 30, Default = State.DrainStaminaValue, Step = 1 }, Callback = function(val) State.DrainStaminaValue = val end })
    stamina_tab:Toggle({ Title = "infinite stamina", Desc = "", Value = State.InfiniteStamina, Callback = function(val) State.InfiniteStamina = val end })

    -- World & Character Features Tab
    feat_tab:Slider({ Title = "legit nosferatu auto bloodhook escape", Desc = "target QTE solver duration (seconds)", Value = { Min = 1, Max = 5, Default = State.BloodhookTargetTime, Step = 0.1 }, Callback = function(val) State.BloodhookTargetTime = val end })
    feat_tab:Toggle({ Title = "enable it", Desc = "enables legit nosferatu auto bloodhook escape", Value = State.EnableBloodhook, Callback = function(val) State.EnableBloodhook = val end })

    feat_tab:Toggle({ Title = "anti slowness", Desc = "removes slowness effect", Value = State.AntiSlowness, Callback = function(val) State.AntiSlowness = val end })
    feat_tab:Toggle({ Title = "enable jumping", Desc = "forces jumping on a round", Value = State.EnableJumping, Callback = function(val) State.EnableJumping = val end })
    feat_tab:Toggle({ Title = "remove map spikes", Desc = "Automatically destroys hazard spikes across the active map", Value = State.RemoveSpikes, Callback = function(val) State.RemoveSpikes = val end })
    feat_tab:Toggle({ Title = "disable killer walls", Desc = "disables killer only walls", Value = State.DisableKillerWalls, Callback = function(val) State.DisableKillerWalls = val end })
    feat_tab:Toggle({ Title = "disable john does trail", Desc = "disables john does trail (client sided) and doesnt damage you", Value = State.DisableToxicTrails, Callback = function(val) State.DisableToxicTrails = val end })
    feat_tab:Toggle({ Title = "no fog", Desc = "", Value = State.NoFog, Callback = function(val) State.NoFog = val end })
    feat_tab:Toggle({ Title = "fullbright", Desc = "", Value = State.FullBright, Callback = function(val) State.FullBright = val end })
    feat_tab:Toggle({ Title = "silent footsteps", Desc = "", Value = State.SilentFootsteps, Callback = function(val) State.SilentFootsteps = val end })
    feat_tab:Toggle({ Title = "map bounds anticheat bypass", Desc = "", Value = State.MapBoundsBypass, Callback = function(val) State.MapBoundsBypass = val end })
    feat_tab:Toggle({ Title = "remove killer only and killer doors", Desc = "", Value = State.RemoveKillerDoors, Callback = function(val) State.RemoveKillerDoors = val end })
    feat_tab:Toggle({ Title = "instant generator pp (proximityprompyt)", Desc = "makes it so that the hold duration to generator is instant instead of 0.25s", Value = State.InstantGenPrompt, Callback = function(val) State.InstantGenPrompt = val end })
    feat_tab:Toggle({ Title = "get less lag when you have hitboxes turn on", Value = State.LessLagHitboxes, Callback = function(val) State.LessLagHitboxes = val end })
    
    feat_tab:Toggle({ 
        Title = "auto notify you when the killer uses an esp ability", 
        Desc = "only works on nosferatu, john doe, 1x1, slasher, and noli", 
        Value = State.AutoNotifyKillerESP, 
        Callback = function(val) 
            State.AutoNotifyKillerESP = val 
        end 
    })

    feat_tab:Toggle({ 
        Title = "hide player icon and name", 
        Value = State.HidePlayerIconAndName, 
        Callback = function(val) 
            State.HidePlayerIconAndName = val 
        end 
    })

    feat_tab:Button({
        Title = "disable sixer/guest 666 tail physics",
        Desc = "disables tail physics on Sixer",
        Callback = function()
            pcall(function()
                local sixer = Workspace:FindFirstChild("Players") and Workspace.Players:FindFirstChild("Killers") and Workspace.Players.Killers:FindFirstChild("Sixer")
                if sixer then
                    sixer:SetAttribute("TailPhysicsEnabled", false)
                    windui:Notify({ Title = "Sixer", Content = "tail physics disabled successfully, nya~!", Duration = 3 })
                else
                    windui:Notify({ Title = "Sixer", Content = "Sixer not found in game!", Duration = 3 })
                end
            end)
        end
    })
    
    feat_tab:Button({
        Title = "stamina anticheat kick bypass",
        Desc = "forsaken added a max stamina limit so if it detects that your above that it kicks you idk",
        Callback = function()
            local oldKick
            if hookfunction then
                oldKick = hookfunction(LP.Kick, function(self, message)
                    if typeof(message) == "string" and string.find(message, "Stamina exceeds max possible cap") then
                        return
                    end
                    return oldKick(self, message)
                end)
            end

            local mt = getrawmetatable(game)
            if mt then
                local oldNamecall = mt.__namecall
                setreadonly(mt, false)

                mt.__namecall = newcclosure(function(self, ...)
                    local method = getnamecallmethod()
                    if method == "Kick" and self == LP then
                        local args = {...}
                        if typeof(args[1]) == "string" and string.find(args[1], "Stamina exceeds max possible cap") then
                            return
                        end
                    end
                    return oldNamecall(self, ...)
                end)

                setreadonly(mt, true)
            end
            windui:Notify({ Title = "stamina kick bypass", Content = "NEUTRALIZED HAHA 🐾", Duration = 3 })
        end
    })

    -- Effects Tab
    effects_tab:Toggle({ Title = "anti subspace tripmine effects", Desc = "removes the subspace tripmine effect", Value = State.AntiSubspaceEffects, Callback = function(val) State.AntiSubspaceEffects = val end })
    effects_tab:Toggle({ Title = "anti exhausted", Desc = "makes it so that your stamina drain is back to normal when having the effect", Value = State.AntiExhausted, Callback = function(val) State.AntiExhausted = val end })
    effects_tab:Toggle({ Title = "anti nausea effects", Desc = "", Value = State.AntiNausea, Callback = function(val) State.AntiNausea = val end })
    effects_tab:Toggle({ Title = "anti oblivious", Desc = "makes it so that you still hear the chase theme", Value = State.AntiOblivious, Callback = function(val) State.AntiOblivious = val end })
    effects_tab:Toggle({ Title = "anti vignette", Desc = "removes vignette (burning and creatures)", Value = State.AntiVignette, Callback = function(val) State.AntiVignette = val end })
    effects_tab:Toggle({ Title = "anti slateskin", Desc = "makes it so that you dont get slowed down when using slateskin", Value = State.AntiSlateskin, Callback = function(val) State.AntiSlateskin = val end })
    effects_tab:Toggle({ Title = "no glitch/corrupted effects on screen", Desc = "", Value = State.NoGlitchCorrupted, Callback = function(val) State.NoGlitchCorrupted = val end })
    effects_tab:Toggle({ Title = "anti blindness", Desc = "", Value = State.AntiBlindness, Callback = function(val) State.AntiBlindness = val end })

    -- invisibility (frozen animation trick) - effects tab
    do
        local invisTrack, invisAnim
        local function stopInvis()
            if invisTrack then pcall(function() invisTrack:Stop() end) end
            invisTrack = nil
        end
        local function applyInvis()
            local character = LP.Character
            if not character then return end
            for _, name in ipairs({ "Torso", "UpperTorso", "LowerTorso", "HumanoidRootPart", "Head" }) do
                local part = character:FindFirstChild(name)
                if part then part.CanCollide = false end
            end
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
            if animator then
                if not invisAnim then
                    invisAnim = Instance.new("Animation")
                    invisAnim.AnimationId = "rbxassetid://75804462760596"
                end
                if invisTrack then invisTrack:Stop() end
                invisTrack = animator:LoadAnimation(invisAnim)
                invisTrack:Play()
                invisTrack:AdjustSpeed(0)
            end
        end
        effects_tab:Toggle({
            Title = "invisibility",
            Desc = "this is serversided i guess",
            Value = State.Invisibility,
            Callback = function(val)
                State.Invisibility = val
                if val then pcall(applyInvis) else stopInvis() end
            end
        })
        TrackConnection(LP.CharacterAdded:Connect(function()
            task.wait(0.4)
            if State.Invisibility then pcall(applyInvis) end
        end))
    end
    effects_tab:Toggle({ Title = "anti confusion", Desc = "", Value = State.AntiConfusion, Callback = function(val) State.AntiConfusion = val end })
    effects_tab:Toggle({ Title = "anti stun", Value = State.AntiStun, Callback = function(val) State.AntiStun = val end })
    effects_tab:Toggle({ Title = "anti undetectable", Value = State.AntiUndetectable, Callback = function(val) State.AntiUndetectable = val end })
    effects_tab:Toggle({ Title = "remove insane vignette", Desc = "removes the vignette you get when you do nothing for too long", Value = State.RemoveInsaneVignette, Callback = function(val) State.RemoveInsaneVignette = val end })
    effects_tab:Toggle({ Title = "anti glitched (new)", Value = State.AntiGlitchedNew, Callback = function(val) State.AntiGlitchedNew = val end })
    effects_tab:Toggle({ Title = "anti glitched (old)", Value = State.AntiGlitchedOld, Callback = function(val) State.AntiGlitchedOld = val end })
    effects_tab:Toggle({ Title = "anti hand slowdown", Value = State.AntiHandSlowdown, Callback = function(val) State.AntiHandSlowdown = val end })

    -- Survivors Tab
    survivors_tab:Section({ Title = "guest 1337" })
    do
        local okBait, errBait = pcall(function()
-- Anti Bait Features (raw, no GUI) - run on top of the auto block engine


-- Auto Block engine (extracted from Guesting Hub v2.8)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer
local RemoteEvent = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Network"):WaitForChild("Network"):WaitForChild("RemoteEvent")

getgenv().BlockAnimations = {
	["72722244508749"] = true, ["96959123077498"] = true, ["99625520747974"] = true, ["72182155407310"] = true,
	["95802026624883"] = true, ["87547792346658"] = true, ["88557287105521"] = true, ["82605295530067"] = true,
	["115706752305794"] = true, ["98105697395689"] = true, ["88287038085804"] = true, ["100926346851492"] = true,
	["140671644163156"] = true, ["120748030255574"] = true, ["82036084568393"] = true, ["123548100869928"] = true,
	["127040663332045"] = true,
}

local S = {
	autoBlock = false,
	autoBlockDelay = 0,
	autoBlockMode = "Guest1337", -- "Guest1337" = Block, "007n7" = Clone
	soundTimerValue = 0.32,
	detectionRange = 15,
	defaultRangeRequireFacing = false,
	customFacingDot = -0.1,
	wallCheckEnabled = false,
	hitboxDraggingEnabled = false,
	hitboxDraggingDuration = 0.3,
	customVisualizerVisible = false,
	defaultVisualizerVisible = false,
	customRangeSettings = { enabled = false, frontRange = 12, sideRange = 12, height = 8 },
	soundHooks = {},
}

local killerSounds = {
	["74809026448465"]="1x1x1x1",["85853080745515"]="1x1x1x1",["95079963655241"]="1x1x1x1",["98111231282218"]="1x1x1x1",
	["101199185291628"]="1x1x1x1",["115026634746636"]="1x1x1x1",["117173212095661"]="1x1x1x1",["119089145505438"]="1x1x1x1",
	["119942598489800"]="1x1x1x1",["121954639447247"]="1x1x1x1",["128856426573270"]="1x1x1x1",["135319730390518"]="1x1x1x1",
	["109570290393196"]="1x1x1x1",["88589682639517"]="1x1x1x1",["133709029886490"]="Azure",
	["86174610237192"]="JohnDoe",["98675142200448"]="JohnDoe",["105204810054381"]="JohnDoe",["123923371062204"]="JohnDoe",
	["131123355704017"]="JohnDoe",["140242176732868"]="JohnDoe",
	["89004992452376"]="Noli",["96117920303138"]="Noli",["108610718831698"]="Noli",["109348678063422"]="Noli",
	["112395455254818"]="Noli",["114742322778642"]="Noli",["115678417928765"]="Noli",["128367348686124"]="Noli",
	["131406927389838"]="Noli",["136323728355613"]="Noli",["70739368096233"]="Noli",
	["104910828105172"]="Nosferatu",["119664480754070"]="Nosferatu",
	["71805956520207"]="Sixer",["74842815979546"]="Sixer",["79980897195554"]="Sixer",["96594507550917"]="Sixer",
	["101553872555606"]="Sixer",["101698569375359"]="Sixer",["108651070773439"]="Sixer",["117231507259853"]="Sixer",
	["119583605486352"]="Sixer",["125213046326879"]="Sixer",["127557531826290"]="Sixer",["139996647355899"]="Sixer",
	["75330693422988"]="c00lkidd",["79391273191671"]="c00lkidd",["80516583309685"]="c00lkidd",["82221759983649"]="c00lkidd",
	["84307400688050"]="c00lkidd",["98733709078792"]="c00lkidd",["105516183226360"]="c00lkidd",["113413858159336"]="c00lkidd",
	["124234993291213"]="c00lkidd",["128195973631079"]="c00lkidd",
}
local slasherAnims = {
	["94958041603347"]=true,["106860049270347"]=true,["108196996477620"]=true,["109667959938617"]=true,
	["118298475669935"]=true,["125403313786645"]=true,["126830014841198"]=true,["130958529065375"]=true,
}

local killers, killerSet, timers, visuals, conns = {}, {}, {}, {}, {}
local running = false
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Exclude
rp.IgnoreWater = true

local function idOf(x) return x and string.match(tostring(x), "%d+") end
local function hrp(m) return m and m:FindFirstChild("HumanoidRootPart") end
local function isLocal(m)
	if not m then return false end
	return Players:GetPlayerFromCharacter(m) == lp or m.Name == (lp and lp.Name)
end
local function modelOf(i)
	local m = i and i:FindFirstAncestorOfClass("Model")
	if m and m:FindFirstChildOfClass("Humanoid") then return m end
end
local function queryHitbox(m)
	if not m then return end
	local q = m:FindFirstChild("QueryHitbox")
	if q and q:IsA("BasePart") then return q end
	for _, c in ipairs(m:GetChildren()) do
		local q2 = c:FindFirstChild("QueryHitbox")
		if q2 and q2:IsA("BasePart") then return q2 end
	end
	return m:FindFirstChild("HumanoidRootPart")
end
local function inBox(cf, size, point)
	local p = cf:PointToObjectSpace(point)
	local h = size * 0.5
	return math.abs(p.X) <= h.X + 0.001 and math.abs(p.Y) <= h.Y + 0.001 and math.abs(p.Z) <= h.Z + 0.001
end
local function firstAliveKiller()
	for _, k in ipairs(killers) do
		local h = k:FindFirstChildOfClass("Humanoid")
		if h and hrp(k) and h.Health > 0 then return k end
	end
end

-- ===== Hitbox Dragging =====
local function hitboxDrag()
	if not S.hitboxDraggingEnabled or not running or not S.autoBlock then return end
	task.spawn(function()
		local char = lp.Character
		if not char or not firstAliveKiller() then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		local oldPrimary = char.PrimaryPart or root
		if not root then return end
		local p = Instance.new("Part")
		p.Size = Vector3.new(2, 2, 2); p.Transparency = 1; p.CanCollide = false; p.Anchored = true
		p.CFrame = root.CFrame; p.Parent = char
		char.PrimaryPart = p
		local t0 = os.clock()
		local dur = S.hitboxDraggingDuration or 0.5
		while os.clock() - t0 < dur and S.hitboxDraggingEnabled and running and S.autoBlock do
			local k = firstAliveKiller()
			local kr = k and hrp(k)
			if kr then
				p.CFrame = CFrame.new((kr.CFrame * CFrame.new(0, 0, -3)).Position) * root.CFrame.Rotation
				root.AssemblyLinearVelocity = Vector3.zero
			end
			RunService.PreRender:Wait()
		end
		if p and p.Parent then p:Destroy() end
		if char and char.Parent then char.PrimaryPart = oldPrimary end
	end)
end

-- ===== Facing / Wall checks =====
local function facingOk(myRoot, kRoot)
	if not S.defaultRangeRequireFacing or not myRoot or not kRoot then return true end
	local d = myRoot.Position - kRoot.Position
	if d.Magnitude < 0.1 then return true end
	local flat = Vector3.new(d.X, 0, d.Z).Unit
	local look = kRoot.CFrame.LookVector
	return Vector3.new(look.X, 0, look.Z).Unit:Dot(flat) > (S.customFacingDot or -0.1)
end
local function wallBlocked(myRoot, kRoot, char)
	if not S.wallCheckEnabled then return false end
	local o = myRoot.Position + Vector3.new(0, 1.5, 0)
	local dir = kRoot.Position + Vector3.new(0, 1.5, 0) - o
	local filter = { char }
	if kRoot.Parent then table.insert(filter, kRoot.Parent) end
	rp.FilterDescendantsInstances = filter
	local hit = workspace:Raycast(o, dir, rp)
	return hit and hit.Instance and hit.Instance.CanCollide
end

-- ===== Block firing =====
local function fireBlock()
	if S.autoBlockMode == "007n7" then
		RemoteEvent:FireServer("UseActorAbility", { buffer.fromstring("\3\5\0\0\0Clone") })
	else
		RemoteEvent:FireServer("UseActorAbility", { buffer.fromstring("\3\5\0\0\0Block") })
	end
end
local function triggerBlock()
	if not running or not S.autoBlock then return end
	if tonumber(S.autoBlockDelay) and S.autoBlockDelay > 0 then
		task.delay(S.autoBlockDelay, function() pcall(fireBlock) end)
	else
		pcall(fireBlock)
	end
end

local checkLoop
local seenTracks = setmetatable({}, { __mode = "k" })
local function markTimer(k, dur, noCheck)
	if not k or isLocal(k) then return end
	timers[k] = { expiry = os.clock() + dur, blocked = false }
	if not noCheck and checkLoop then pcall(checkLoop) end -- check right away, not on the next frame
end

-- ===== Sound / animation detection =====
local function onSound(snd, owner)
	if not running or not S.autoBlock or not snd or not snd:IsA("Sound") then return end
	local id = idOf(snd.SoundId)
	if not id or not killerSounds[id] then return end
	owner = owner or modelOf(snd)
	if not owner or isLocal(owner) then return end
	markTimer(owner, tonumber(S.soundTimerValue) or 0.32)
end
local function hookSound(snd, owner)
	if not snd or not snd:IsA("Sound") or S.soundHooks[snd] then return end
	local m = owner or modelOf(snd)
	if m and isLocal(m) then return end
	local played = snd.Played:Connect(function() onSound(snd, m) end)
	local destroy
	destroy = snd.Destroying:Connect(function()
		played:Disconnect(); destroy:Disconnect()
		S.soundHooks[snd] = nil
	end)
	S.soundHooks[snd] = { played, destroy }
	if snd.IsPlaying then task.defer(onSound, snd, m) end
end
local function hookKillerAnim(k)
	if not k or isLocal(k) then return end
	task.spawn(function()
		local hum = k:WaitForChild("Humanoid", 5)
		if not hum then return end
		local c = (hum:WaitForChild("Animator", 5) or hum).AnimationPlayed:Connect(function(track)
			if not running or not S.autoBlock then return end
			local id = track.Animation and idOf(track.Animation.AnimationId)
			if id and (slasherAnims[id] or DANGER["rbxassetid://" .. id]) then markTimer(k, tonumber(S.soundTimerValue) or 0.32) end
		end)
		table.insert(conns, c)
	end)
end

-- ===== Visualizers =====
local function removeVis(k, which)
	if visuals[k] and visuals[k][which] then
		visuals[k][which]:Destroy()
		visuals[k][which] = nil
	end
end
local function updateVisuals()
	if not running or not S.autoBlock then return end
	local cr = S.customRangeSettings
	local now = os.clock()
	for _, k in ipairs(killers) do
		local r = hrp(k)
		if r then
			visuals[k] = visuals[k] or {}
			if not cr.enabled and S.defaultVisualizerVisible then
				if not visuals[k].Default then
					local a = Instance.new("CylinderHandleAdornment")
					a.Name = "DefaultRangeVisualizer"; a.Adornee = r; a.Color3 = Color3.fromRGB(255, 100, 100)
					a.AlwaysOnTop = true; a.ZIndex = 1; a.Transparency = 0.5; a.Height = 0.12; a.Parent = r
					visuals[k].Default = a
				end
				local a = visuals[k].Default
				a.Radius = tonumber(S.detectionRange) or 15
				a.CFrame = CFrame.new(0, -(r.Size.Y / 2 + 0.05), 0) * CFrame.Angles(math.pi / 2, 0, 0)
			else
				removeVis(k, "Default")
			end
			if cr.enabled and S.customVisualizerVisible and timers[k] and now <= timers[k].expiry then
				if not visuals[k].Custom then
					local b = Instance.new("BoxHandleAdornment")
					b.Name = "CustomRangeVisualizer"; b.Adornee = r; b.Color3 = Color3.fromRGB(255, 255, 102)
					b.AlwaysOnTop = true; b.ZIndex = 1; b.Transparency = 0.7; b.Parent = r
					visuals[k].Custom = b
				end
				local b = visuals[k].Custom
				local fr, sd, ht = tonumber(cr.frontRange) or 12, tonumber(cr.sideRange) or 12, tonumber(cr.height) or 8
				b.Adornee = queryHitbox(k) or r
				b.Size = Vector3.new(sd, ht, fr)
				b.CFrame = CFrame.new(0, 0, -(fr / 2))
			else
				removeVis(k, "Custom")
			end
		end
	end
end

-- ===== Range check loop =====
checkLoop = function()
	if not running or not S.autoBlock then return end
	local char = lp.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local now = os.clock()
	local cr = S.customRangeSettings
	-- scan every killer's playing tracks every frame (all the auto block ids count) so no windup is missed
	for _, k in ipairs(killers) do
		if not isLocal(k) then
			local khum = k:FindFirstChildOfClass("Humanoid")
			local kan = khum and khum:FindFirstChildOfClass("Animator")
			if kan then
				for _, track in ipairs(kan:GetPlayingAnimationTracks()) do
					if not seenTracks[track] then
						local tid = track.Animation and idOf(track.Animation.AnimationId)
						if tid and (slasherAnims[tid] or DANGER["rbxassetid://" .. tid]) then
							seenTracks[track] = true
							markTimer(k, tonumber(S.soundTimerValue) or 0.32, true)
						end
					end
				end
			end
		end
	end
	for k, t in pairs(timers) do
		if not k or not k.Parent or now > t.expiry then
			timers[k] = nil
		else
			local kr = hrp(k)
			if kr then
				local inRange
				if cr.enabled then
					local hb = queryHitbox(k) or kr
					local fr, sd, ht = tonumber(cr.frontRange) or 12, tonumber(cr.sideRange) or 12, tonumber(cr.height) or 8
					inRange = inBox(hb.CFrame * CFrame.new(0, 0, -(fr / 2)), Vector3.new(sd, ht, fr), root.Position)
				else
					inRange = (root.Position - kr.Position).Magnitude <= (tonumber(S.detectionRange) or 15)
				end
				if inRange and not t.blocked and facingOk(root, kr) and not wallBlocked(root, kr, char) then
					t.blocked = true
					triggerBlock()
				end
			end
		end
	end
end

-- ===== Killer tracking =====
local function addKiller(m)
	if not m or not m:IsA("Model") or killerSet[m] then return end
	killerSet[m] = true
	table.insert(killers, m)
	if not isLocal(m) then
		pcall(function()
			for _, d in ipairs(m:GetDescendants()) do
				if d:IsA("Sound") then pcall(hookSound, d, m) end
			end
		end)
		table.insert(conns, m.DescendantAdded:Connect(function(d)
			if d:IsA("Sound") and not isLocal(m) then pcall(hookSound, d, m) end
		end))
		hookKillerAnim(m)
	end
end
local function removeKiller(m)
	if not m or not killerSet[m] then return end
	killerSet[m] = nil
	for i = #killers, 1, -1 do
		if killers[i] == m then table.remove(killers, i) break end
	end
	timers[m] = nil
	removeVis(m, "Default"); removeVis(m, "Custom")
end

local function hookLocalChar(char)
	if not char then return end
	local hum = char:WaitForChild("Humanoid", 5)
	if not hum then return end
	local c = (hum:WaitForChild("Animator", 5) or hum).AnimationPlayed:Connect(function(track)
		if not S.hitboxDraggingEnabled or not track or not track.Animation then return end
		local id = idOf(track.Animation.AnimationId)
		if id and getgenv().BlockAnimations[id] then hitboxDrag() end
	end)
	table.insert(conns, c)
end

local function StartEngine()
	if running then return end
	running = true
	if lp.Character then task.spawn(hookLocalChar, lp.Character) end
	table.insert(conns, lp.CharacterAdded:Connect(hookLocalChar))
	local pf = workspace:FindFirstChild("Players")
	local kf = pf and pf:FindFirstChild("Killers")
	local function watch(folder)
		for _, c in ipairs(folder:GetChildren()) do if c:IsA("Model") then pcall(addKiller, c) end end
		table.insert(conns, folder.ChildAdded:Connect(function(c) if c:IsA("Model") then pcall(addKiller, c) end end))
		table.insert(conns, folder.ChildRemoved:Connect(function(c) pcall(removeKiller, c) end))
	end
	if kf then
		watch(kf)
	else
		table.insert(conns, workspace.DescendantAdded:Connect(function(d)
			if d:IsA("Folder") and d.Name == "Killers" and d.Parent and d.Parent.Name == "Players" then watch(d) end
		end))
	end
	table.insert(conns, RunService.Heartbeat:Connect(checkLoop))
	table.insert(conns, RunService.RenderStepped:Connect(updateVisuals))
end
local function StopEngine()
	running = false
	for _, c in ipairs(conns) do if c then c:Disconnect() end end
	table.clear(conns); table.clear(timers)
	for _, k in ipairs(killers) do removeVis(k, "Default"); removeVis(k, "Custom") end
end



	-- ===== controls =====
	S.autoBlock = false
	local function tog(title, desc, getter, setter)
		survivors_tab:Toggle({ Title = title, Desc = desc, Value = getter(), Callback = setter })
	end
	local function sld(title, desc, min, max, default, step, setter)
		survivors_tab:Slider({ Title = title, Desc = desc, Value = { Min = min, Max = max, Default = default, Step = step },
			Callback = function(val) setter(tonumber(val) or default) end })
	end
	survivors_tab:Toggle({
		Title = "anti guest block bait",
		Desc = "blocks incoming attacks and counters baits (hitbox dragging, wall + facing checks). from guesting hub",
		Value = false,
		Callback = function(val)
			S.autoBlock = val
			if val then StartEngine() else StopEngine() end
		end
	})
	survivors_tab:Dropdown({
		Title = "anti bait block mode",
		Desc = "guest 1337 blocks with block, 007n7 blocks with his clones",
		Values = { "guest 1337", "007n7" },
		Callback = function(option)
			if type(option) == "table" then option = option.Title or option[1] end
			S.autoBlockMode = (option == "007n7") and "007n7" or "Guest1337"
		end
	})
	sld("anti bait detection range (studs)", "how close a killer has to be to block", 5, 30, 15, 0.5, function(v) S.detectionRange = v end)
	sld("anti bait sound timer", "how long a killer attack counts as dangerous after its sound/animation (seconds)", 0.1, 1, 0.32, 0.01, function(v) S.soundTimerValue = v end)
	sld("anti bait block delay", "seconds to wait before blocking", 0, 0.5, 0, 0.01, function(v) S.autoBlockDelay = v end)
	tog("anti bait default range facing check", "only blocks if the killer is facing you", function() return S.defaultRangeRequireFacing end, function(v) S.defaultRangeRequireFacing = v end)
	sld("anti bait facing dot", "how strictly the killer has to face you (-1 = any direction, 1 = straight at you)", -1, 1, -0.1, 0.05, function(v) S.customFacingDot = v end)
	tog("anti bait wall check", "doesnt block through walls", function() return S.wallCheckEnabled end, function(v) S.wallCheckEnabled = v end)
	tog("anti bait hitbox dragging", "drags your server hitbox behind the killer while you block", function() return S.hitboxDraggingEnabled end, function(v) S.hitboxDraggingEnabled = v end)
	sld("anti bait hitbox dragging duration", "how long the hitbox drags (seconds)", 0.1, 1, 0.3, 0.05, function(v) S.hitboxDraggingDuration = v end)
	tog("anti bait default range visualizer", "shows the default block range around killers", function() return S.defaultVisualizerVisible end, function(v) S.defaultVisualizerVisible = v end)
	tog("anti bait custom range", "uses a box range (front, side, height) instead of a circle", function() return S.customRangeSettings.enabled end, function(v) S.customRangeSettings.enabled = v end)
	tog("anti bait custom range visualizer", "shows the custom range box (needs custom range)", function() return S.customVisualizerVisible end, function(v) S.customVisualizerVisible = v end)
	sld("anti bait custom range front", "front range of the custom box (studs)", 2, 30, 12, 0.5, function(v) S.customRangeSettings.frontRange = v end)
	sld("anti bait custom range side", "side range of the custom box (studs)", 2, 30, 12, 0.5, function(v) S.customRangeSettings.sideRange = v end)
	sld("anti bait custom range height", "height of the custom box (studs)", 2, 20, 8, 0.5, function(v) S.customRangeSettings.height = v end)

        end)
        if not okBait then warn("[forsaken8z] anti guest block bait failed: " .. tostring(errBait)) end
    end
    survivors_tab:Button({
        Title = "make charge be snappy (controllable)",
        Desc = "makes it so that charge is like void rush (but snappier)",
        Callback = function()
            pcall(function()
                local Config = require(ReplicatedStorage.Assets.Survivors.Guest1337.Config)
                Config.ChargingTurnSpeed = 25
                windui:Notify({ Title = "Guest 1337", Content = "charge direction is now controllable + snappy :3", Duration = 3 })
            end)
        end
    })

    survivors_tab:Toggle({
        Title = "auto aim (to the killer) when using charge",
        Desc = "this only aims for u",
        Value = State.Guest1337ChargeAim,
        Callback = function(val) State.Guest1337ChargeAim = val end
    })

    survivors_tab:Section({ Title = "helperbot" })
    survivors_tab:Toggle({ Title = "auto use inspiration", Desc = "auto uses inspiration when a survivor gets close (it also blacklists yourself, only works on other survivors)", Value = State.AutoUseInspiration, Callback = function(val) State.AutoUseInspiration = val end })
    survivors_tab:Button({
        Title = "auto collect gears",
        Callback = function()
            pcall(function()
                local MAX_GEARS = 5
                local INTERVAL = 0.2
                local gearsFolder = workspace:WaitForChild("Map", 5)
                    :WaitForChild("Ingame", 5)
                    :WaitForChild("Map", 5)
                    :WaitForChild("GearsTest", 5)
                if not gearsFolder then
                    windui:Notify({ Title = "auto collect gears", Content = "Gears folder not found!", Duration = 3 })
                    return
                end
                local function getRoot()
                    local char = LP.Character or LP.CharacterAdded:Wait()
                    return char:WaitForChild("HumanoidRootPart", 5)
                end
                local function getCFrame(obj)
                    if obj:IsA("BasePart") then
                        return obj.CFrame
                    elseif obj:IsA("Model") then
                        return obj:GetPivot()
                    end
                    local part = obj:FindFirstChildWhichIsA("BasePart", true)
                    return part and part.CFrame
                end
                local function activate(prompt)
                    prompt.HoldDuration = 0
                    prompt.RequiresLineOfSight = false
                    if fireproximityprompt then
                        fireproximityprompt(prompt)
                    else
                        prompt:InputHoldBegin()
                        task.wait()
                        prompt:InputHoldEnd()
                    end
                end
                task.spawn(function()
                    local visited = {}
                    local collected = 0
                    while collected < MAX_GEARS do
                        local available = {}
                        for _, child in ipairs(gearsFolder:GetChildren()) do
                            if child.Name == "Gear" and not visited[child] then
                                table.insert(available, child)
                            end
                        end
                        if #available == 0 then break end
                        local gear = available[math.random(1, #available)]
                        local prompt = gear:FindFirstChildWhichIsA("ProximityPrompt", true)
                        local root = getRoot()
                        local cf = getCFrame(gear)
                        if root and cf and prompt then
                            root.CFrame = cf + Vector3.new(0, 1, 0)
                            task.wait(INTERVAL)
                            if gear.Parent then
                                activate(prompt)
                                visited[gear] = true
                                collected += 1
                            end
                        else
                            visited[gear] = true
                        end
                        task.wait(INTERVAL)
                    end
                    windui:Notify({ Title = "auto collect gears", Content = "Collected " .. collected .. " gears!", Duration = 3 })
                end)
            end)
        end
    })
    survivors_tab:Toggle({ Title = "auto use pulse when a survivor has low health", Desc = "FIXED: now checks teammates properly!", Value = State.AutoPulseLowHealth, Callback = function(val) State.AutoPulseLowHealth = val end })
    survivors_tab:Slider({ Title = "change when to use pulse (health)", Value = { Min = 1, Max = 85, Default = State.PulseHealthThreshold, Step = 1 }, Callback = function(val) State.PulseHealthThreshold = val end })
    survivors_tab:Toggle({ Title = "pulse server crasher/lagger", Desc = "ONLY WORKS ON ABILITES COOLDOWN DISABLED", Value = State.PulseCrasher, Callback = function(val) State.PulseCrasher = val end })

    -- Dusekkar Section (New)
    survivors_tab:Section({ Title = "dusekkar" })
    survivors_tab:Toggle({
        Title = "auto aim when using plasma beam on (nearest) survivors",
        Desc = "i recommend to like to on first person (optional but it 100% lands the hit on first person) THIS DOES NOT DO THEM AUTOMATICALLY!!! THIS ONLY AIMS FOR U!!!",
        Value = State.DusekkarSurvivorAim,
        Callback = function(val) State.DusekkarSurvivorAim = val end
    })
    survivors_tab:Toggle({
        Title = "auto aim when using plasma beam on (nearest) killer(s)",
        Desc = "i ALSO recommend u to go on first person",
        Value = State.DusekkarKillerAim,
        Callback = function(val) State.DusekkarKillerAim = val end
    })

    survivors_tab:Toggle({
        Title = "protect through walls",
        Desc = "makes it so that the survivors are always marked as visible so u can protect them behind walls",
        Value = State.DusekkarProtectWalls,
        Callback = function(val)
            State.DusekkarProtectWalls = val
            ApplyDusekkarWallConfig(val)
        end
    })

    survivors_tab:Section({ Title = "veeronica" })
    survivors_tab:Toggle({ Title = "auto trick (veeronica)", Desc = "", Value = State.AutoTrick, Callback = function(val) State.AutoTrick = val end })
    survivors_tab:Toggle({ Title = "sk8 anywhere you want", Desc = "FIXED: now scans all map descendants properly!", Value = State.Sk8Anywhere, Callback = function(val) State.Sk8Anywhere = val end })

    -- Veeronica Spray TP System
    local sprayList = {}
    local sprayMap = {}
    local selectedSprayObj = nil

    local function FetchSprays()
        sprayList = {}
        sprayMap = {}
        selectedSprayObj = nil
        local ingame = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Ingame")
        if ingame then
            local count = 1
            for _, obj in ipairs(ingame:GetDescendants()) do
                local nameLower = obj.Name:lower()
                if nameLower:find("spray") or nameLower:find("grafitti") or nameLower:find("graffiti") then
                    if obj:IsA("BasePart") or obj:IsA("Model") then
                        local label = "Spray " .. count .. " (" .. obj.Name .. ")"
                        table.insert(sprayList, label)
                        sprayMap[label] = obj
                        count = count + 1
                    end
                end
            end
        end
        if #sprayList == 0 then
            table.insert(sprayList, "no sprays found")
        end
    end

    FetchSprays()

    local sprayDropdown = survivors_tab:Dropdown({
        Title = "teleport to a spray",
        Desc = "select a spray from the list",
        Values = sprayList,
        Value = sprayList[1],
        Callback = function(selected)
            selectedSprayObj = sprayMap[selected]
        end
    })

    -- the first fetch usually runs in the lobby (no map yet), so keep the list synced while the map is loaded
    task.spawn(function()
        local lastSignature = table.concat(sprayList, "|")
        while ScriptRunning do
            task.wait(6)
            pcall(function()
                local keep = selectedSprayObj
                FetchSprays()
                local signature = table.concat(sprayList, "|")
                if signature ~= lastSignature then
                    lastSignature = signature
                    RefreshDropdown(sprayDropdown, sprayList)
                else
                    selectedSprayObj = keep
                end
            end)
        end
    end)

    survivors_tab:Button({
        Title = "refresh spray list",
        Desc = "refreshes the spray list",
        Callback = function()
            FetchSprays()
            RefreshDropdown(sprayDropdown, sprayList)
            windui:Notify({ Title = "sprays refreshed", Content = "found " .. tostring(#sprayList) .. " spray option(s)", Duration = 3 })
        end
    })

    survivors_tab:Button({
        Title = "teleport to selected spray",
        Desc = "teleports to the chosen spray",
        Callback = function()
            if selectedSprayObj then
                local char = LP.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local targetPart = selectedSprayObj:IsA("Model") and (selectedSprayObj.PrimaryPart or selectedSprayObj:FindFirstChildWhichIsA("BasePart")) or selectedSprayObj
                if hrp and targetPart and targetPart:IsA("BasePart") then
                    hrp.CFrame = targetPart.CFrame * CFrame.new(0, 3, 0)
                    windui:Notify({ Title = "teleported", Content = "teleported to spray", Duration = 3 })
                end
            else
                windui:Notify({ Title = "teleport failed", Content = "select a spray first", Duration = 3 })
            end
        end
    })

    -- Section: 007n7
    survivors_tab:Section({ Title = "007n7" })
    survivors_tab:Toggle({
        Title = "notify if 007n7 is using c00lgui",
        Value = State.NotifyC00lgui,
        Callback = function(val)
            State.NotifyC00lgui = val
            if val then
                task.spawn(function()
                    while State.NotifyC00lgui and ScriptRunning do
                        task.wait(0.2)
                        pcall(function()
                            local s007 = Workspace:FindFirstChild("Players") and Workspace.Players:FindFirstChild("Survivors") and Workspace.Players.Survivors:FindFirstChild("007n7")
                            if s007 and s007:FindFirstChild("c00lgui") then
                                windui:Notify({ Title = "007n7 Alert", Content = "cg detected!!!!! (007n7)", Duration = 3 })
                                task.wait(3)
                            end
                        end)
                    end
                end)
            end
        end
    })

    survivors_tab:Toggle({
        Title = "make 007n7 visible if hes using his clones",
        Value = State.Make007n7Visible,
        Callback = function(val)
            State.Make007n7Visible = val
        end
    })

    survivors_tab:Toggle({
        Title = "loop delete 007n7 clones",
        Value = State.LoopDelete007n7Clones,
        Callback = function(val)
            State.LoopDelete007n7Clones = val
        end
    })

    -- Section: two time
    -- 007n7 extras + noob section (shared LMS watcher)
    do
        local okNoob, errNoob = pcall(function()
            local RS = game:GetService("RunService")
            local RemoteHolder = game:GetService("ReplicatedStorage")

            local function fireAbility(name)
                pcall(function()
                    RemoteHolder.Modules.Network.Network.RemoteEvent:FireServer("UseActorAbility", { name })
                end)
            end

            -- LMS starts when the LMS gui (LMSFrame) from LMSEffectHandler.BasicLMS is on screen and visible
            local seenLMS = setmetatable({}, { __mode = "k" })
            task.spawn(function()
                while ScriptRunning do
                    task.wait(0.2)
                    if State.AutoGhostburgerLMS or State.AutoCloneLMS or State.AutoC00lguiLMS then
                        local playerGui = LP:FindFirstChildOfClass("PlayerGui")
                        if playerGui then
                            for _, gui in ipairs(playerGui:GetChildren()) do
                                if gui:IsA("ScreenGui") and not seenLMS[gui] then
                                    local frame = gui:FindFirstChild("LMSFrame")
                                    if frame and frame:IsA("GuiObject") and gui.Enabled and frame.Visible then
                                        seenLMS[gui] = true
                                        if State.AutoGhostburgerLMS then fireAbility("Ghostburger") end
                                        if State.AutoCloneLMS then fireAbility("Clone") end
                                        if State.AutoC00lguiLMS then fireAbility("c00lgui") end
                                    end
                                end
                            end
                        end
                    end
                end
            end)

            ------------------------------------------------------------------
            -- 007n7
            ------------------------------------------------------------------
            -- remove the c00lgui animation
            local C00LGUI_ANIM_ID = "123915228705093"
            local animConns = {}
            local function disconnectAnim()
                for _, c in ipairs(animConns) do pcall(function() c:Disconnect() end) end
                animConns = {}
            end
            local function killC00lguiStart(character)
                if not character then return end
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
                if not animator then return end
                table.insert(animConns, animator.AnimationPlayed:Connect(function(track)
                    if not State.RemoveC00lguiAnim then return end
                    local id = tostring(track.Animation and track.Animation.AnimationId or "")
                    if id:find(C00LGUI_ANIM_ID) then
                        track:Stop(0)
                        track:Destroy()
                    end
                end))
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    local id = tostring(track.Animation and track.Animation.AnimationId or "")
                    if id:find(C00LGUI_ANIM_ID) then track:Stop(0) end
                end
            end
            local function renameFailText(obj)
                if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                    local t = obj.Text
                    if t == "TP: F41L!!! L0L" or t:lower():find("guitest") or t:find("F41L") then
                        obj.Text = "forsaken8z fuck you"
                    end
                end
            end
            local animCharConn, animGuiConn
            survivors_tab:Toggle({
                Title = "remove the c00lgui animation",
                Desc = "recommended to use with no speed penalty when using c00lgui!!!!!! uhh, it removes the c00lgui animations, only use this if you dont want killers when they use a esp ability to know that ur teleporting.",
                Value = State.RemoveC00lguiAnim,
                Callback = function(val)
                    State.RemoveC00lguiAnim = val
                    disconnectAnim()
                    if animCharConn then animCharConn:Disconnect() animCharConn = nil end
                    if animGuiConn then animGuiConn:Disconnect() animGuiConn = nil end
                    if val then
                        killC00lguiStart(LP.Character)
                        animCharConn = LP.CharacterAdded:Connect(function(char)
                            disconnectAnim()
                            killC00lguiStart(char)
                        end)
                        local playerGui = LP:FindFirstChildOfClass("PlayerGui")
                        if playerGui then
                            for _, d in ipairs(playerGui:GetDescendants()) do renameFailText(d) end
                            animGuiConn = playerGui.DescendantAdded:Connect(function(obj)
                                task.defer(function() if State.RemoveC00lguiAnim then renameFailText(obj) end end)
                            end)
                        end
                    end
                end
            })

            -- dont get slowed down when using c00lgui
            local speedConn
            local function nukeC00lgui()
                local players = workspace:FindFirstChild("Players")
                local survivors = players and players:FindFirstChild("Survivors")
                local char = survivors and survivors:FindFirstChild("007n7")
                local multipliers = char and char:FindFirstChild("SpeedMultipliers")
                local c00l = multipliers and multipliers:FindFirstChild("c00lgui")
                if c00l then c00l:Destroy() end
            end
            survivors_tab:Toggle({
                Title = "dont get sloweed down when using c00lgui",
                Desc = "recommended to use with remove c00lgui animations i guess, this only makes it less obvious that your using it.",
                Value = State.NoC00lguiSlow,
                Callback = function(val)
                    State.NoC00lguiSlow = val
                    if speedConn then speedConn:Disconnect() speedConn = nil end
                    if val then
                        speedConn = RS.Heartbeat:Connect(function() pcall(nukeC00lgui) end)
                    end
                end
            })

            survivors_tab:Toggle({
                Title = "auto use clone when lms starts",
                Desc = "will also be improved in the next update",
                Value = State.AutoCloneLMS,
                Callback = function(val) State.AutoCloneLMS = val end
            })
            survivors_tab:Toggle({
                Title = "auto use c00lgui when lms starts",
                Desc = "recommended to use when the killer is like far from you, or ur gonna die (probably)",
                Value = State.AutoC00lguiLMS,
                Callback = function(val) State.AutoC00lguiLMS = val end
            })

            ------------------------------------------------------------------
            -- noob
            ------------------------------------------------------------------
            survivors_tab:Section({ Title = "noob" })

            local NOOB_BLACKLIST = {
                ["ExpressionHolder"] = true, ["CollisionHitbox"] = true, ["QueryHitbox"] = true,
                ["Ghostburger"] = true, ["HumanoidRootPart"] = true, ["Slateskin"] = true,
            }
            local noobConn
            local function forceNoobVisible()
                local players = workspace:FindFirstChild("Players")
                local survivors = players and players:FindFirstChild("Survivors")
                local noob = survivors and survivors:FindFirstChild("Noob")
                if not noob then return end
                for _, desc in ipairs(noob:GetDescendants()) do
                    if (desc:IsA("BasePart") or desc:IsA("MeshPart")) and not NOOB_BLACKLIST[desc.Name] then
                        -- catch 0.915 and any tiny floating point weirdness
                        if desc.Transparency > 0.9 and desc.Transparency < 0.93 then
                            desc.Transparency = 0
                        end
                    end
                end
            end
            survivors_tab:Toggle({
                Title = "make noob visible if hes using ghost burger",
                Desc = "makes him visible so u can always see him i guess",
                Value = State.NoobVisible,
                Callback = function(val)
                    State.NoobVisible = val
                    if noobConn then noobConn:Disconnect() noobConn = nil end
                    if val then noobConn = RS.Heartbeat:Connect(forceNoobVisible) end
                end
            })
            survivors_tab:Toggle({
                Title = "auto use ghostburger on lms",
                Desc = "auto uses ghostburger when its lms, this will get improved in the next update.",
                Value = State.AutoGhostburgerLMS,
                Callback = function(val) State.AutoGhostburgerLMS = val end
            })
        end)
        if not okNoob then warn("[forsaken8z] noob/007n7 features failed: " .. tostring(errNoob)) end
    end

    survivors_tab:Section({ Title = "two time" })
    do
        local okStab, errStab = pcall(function()
--[[
	Two Time Backstab (raw, no GUI)
	When Two Time's backstab animation plays, slides your server-side hitbox
	behind the nearest killer for a short time. Extracted from Guesting Hub v2.8.
]]


-- ===== CONFIG =====
local ENABLED       = false
local TP_RANGE      = 10   -- only trigger if a killer is within this many studs
local START_DELAY   = 0.05 -- seconds to wait before moving
local STAY_DURATION = 0.5  -- seconds to stay behind the killer
local BEHIND_OFFSET = 4    -- studs behind the killer (positive Z = behind)
local BACKSTAB_ANIM = "100725497418533"

-- ===== SERVICES =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

local busy = false

-- ===== HELPERS =====
local function getCharacter()
	return localPlayer.Character or localPlayer.CharacterAdded:Wait()
end

local function getKillersFolder()
	local players = workspace:FindFirstChild("Players")
	return players and players:FindFirstChild("Killers")
end

local function getAliveKiller()
	local folder = getKillersFolder()
	if not folder then
		return nil
	end

	for _, descendant in ipairs(folder:GetDescendants()) do
		if descendant:IsA("Model") then
			local humanoid = descendant:FindFirstChildOfClass("Humanoid")
			local root = descendant:FindFirstChild("HumanoidRootPart")
			if humanoid and root and humanoid.Health > 0 then
				return descendant
			end
		end
	end

	return nil
end

local function killerInRange()
	local root = getCharacter():FindFirstChild("HumanoidRootPart")
	local killer = getAliveKiller()
	local killerRoot = killer and killer:FindFirstChild("HumanoidRootPart")
	if not root or not killerRoot then
		return false, nil
	end
	return (root.Position - killerRoot.Position).Magnitude <= TP_RANGE, killer
end

-- ===== BACKSTAB =====
local function backstab()
	if not ENABLED or busy then
		return
	end

	local inRange, killer = killerInRange()
	if not inRange or not killer then
		return
	end

	busy = true
	local character = getCharacter()
	local root = character:WaitForChild("HumanoidRootPart")
	task.wait(START_DELAY)

	if not character.Parent then
		busy = false
		return
	end

	local anchor = Instance.new("Part")
	anchor.Name = "place"
	anchor.Size = Vector3.new(2, 2, 2)
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.Anchored = true
	anchor.Parent = character

	local oldPrimary = character.PrimaryPart
	character.PrimaryPart = anchor
	local startTime = os.clock()

	while os.clock() - startTime < STAY_DURATION do
		if not character.Parent or not anchor.Parent or not ENABLED then
			break
		end

		local target = getAliveKiller()
		local targetRoot = target and target:FindFirstChild("HumanoidRootPart")
		if targetRoot then
			anchor.CFrame = targetRoot.CFrame * CFrame.new(0, 0, BEHIND_OFFSET)
			root.AssemblyLinearVelocity = Vector3.zero
		end

		RunService.PreRender:Wait()
	end

	if anchor.Parent then
		anchor:Destroy()
	end
	if character.Parent then
		character.PrimaryPart = oldPrimary
	end

	busy = false
end

-- ===== ANIMATION HOOK =====
local function hookCharacter(character)
	local animator = character:WaitForChild("Humanoid"):WaitForChild("Animator")
	animator.AnimationPlayed:Connect(function(track)
		if not ENABLED or not track or not track.Animation then
			return
		end

		local id = tostring(track.Animation.AnimationId or ""):gsub("%D", "")
		if id == BACKSTAB_ANIM then
			task.spawn(backstab)
		end
	end)
end

if localPlayer.Character then
	task.spawn(hookCharacter, localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(hookCharacter)

	-- ===== controls =====
	survivors_tab:Toggle({
		Title = "auto stab v2",
		Desc = "slides your server-side hitbox behind the nearest killer when two time's backstab animation plays",
		Value = false,
		Callback = function(val) ENABLED = val end
	})
	survivors_tab:Slider({ Title = "auto stab v2 range (studs)", Desc = "only triggers if a killer is within this many studs", Value = { Min = 2, Max = 30, Default = TP_RANGE, Step = 0.5 }, Callback = function(val) TP_RANGE = tonumber(val) or 10 end })
	survivors_tab:Slider({ Title = "auto stab v2 start delay", Desc = "seconds to wait before moving", Value = { Min = 0, Max = 0.5, Default = START_DELAY, Step = 0.01 }, Callback = function(val) START_DELAY = tonumber(val) or 0.05 end })
	survivors_tab:Slider({ Title = "auto stab v2 stay duration", Desc = "seconds to stay behind the killer", Value = { Min = 0.1, Max = 2, Default = STAY_DURATION, Step = 0.05 }, Callback = function(val) STAY_DURATION = tonumber(val) or 0.5 end })
	survivors_tab:Slider({ Title = "auto stab v2 behind offset (studs)", Desc = "studs behind the killer", Value = { Min = 0, Max = 10, Default = BEHIND_OFFSET, Step = 0.5 }, Callback = function(val) BEHIND_OFFSET = tonumber(val) or 4 end })

        end)
        if not okStab then warn("[forsaken8z] auto stab v2 failed: " .. tostring(errStab)) end
    end
    survivors_tab:Toggle({
        Title = "auto backstab",
        Desc = "no, this doesnt trickstab",
        Value = State.TwoTimeAutoBackstab,
        Callback = function(val)
            State.TwoTimeAutoBackstab = val
        end
    })
    survivors_tab:Slider({
        Title = "change auto backstab range",
        Desc = "i recommend to set it at like 16.5",
        Value = { Min = 3.5, Max = 26.5, Default = State.TwoTimeBackstabRange, Step = 0.5 },
        Callback = function(val)
            State.TwoTimeBackstabRange = val
        end
    })
    survivors_tab:Button({
        Title = "place your ritual on spots that are blocked",
        Desc = "⚠️YOU CAN GET BANNED FOR EXPLOITING/BUG ABUSING⚠️",
        Callback = function()
            pcall(function()
                local ingame = Workspace:WaitForChild("Map"):WaitForChild("Ingame")
                local remote = GetRemoteEvent()
                local conveyors = {}
                
                local function collectConveyors(parent)
                    for _, child in ipairs(parent:GetChildren()) do
                        if child.Name:lower() == "conveyor" and child:IsA("BasePart") then
                            table.insert(conveyors, child)
                        else
                            collectConveyors(child)
                        end
                    end
                end
                
                local mapBoundaries = ingame:FindFirstChild("Map") and ingame.Map:FindFirstChild("MapBoundaries")
                if mapBoundaries and mapBoundaries:FindFirstChild("Conveyors") then
                    collectConveyors(mapBoundaries.Conveyors)
                end

                if #conveyors > 0 then
                    local targetConv = conveyors[math.random(1, #conveyors)]
                    local char = LP.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if root then
                        local origCF = root.CFrame
                        local noclipConn
                        noclipConn = RunService.Stepped:Connect(function()
                            if char then
                                for _, part in ipairs(char:GetDescendants()) do
                                    if part:IsA("BasePart") then
                                        part.CanCollide = false
                                    end
                                end
                            end
                        end)

                        task.spawn(function()
                            local startTime = os.clock()
                            while os.clock() - startTime < 1.5 do
                                if root and targetConv then
                                    root.CFrame = targetConv.CFrame + Vector3.new(0, 3, 0)
                                end
                                task.wait(0.05)
                            end
                        end)

                        task.wait(0.05)
                        if remote then
                            remote:FireServer("UseActorAbility", { buffer.fromstring("\3\6\0\0\0Ritual") })
                        end

                        task.wait(1.5)
                        if noclipConn then noclipConn:Disconnect() end
                        if root then
                            root.CFrame = origCF
                        end
                        windui:Notify({ Title = "Two Time", Content = "ritual placed on conveyor successfully!", Duration = 3 })
                    end
                else
                    windui:Notify({ Title = "Two Time", Content = "no conveyors found!", Duration = 3 })
                end
            end)
        end
    })

    -- Two Time Auto Backstab Background Loop
    task.spawn(function()
        local lastFire = 0
        local COOLDOWN = 0.35
        while ScriptRunning do
            task.wait(0.05)
            if State.TwoTimeAutoBackstab then
                pcall(function()
                    local char = LP.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end

                    local killersFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers")
                    if not killersFolder then return end

                    for _, killer in ipairs(killersFolder:GetChildren()) do
                        local kHRP = killer:FindFirstChild("HumanoidRootPart")
                        if not kHRP then continue end

                        local dist = (hrp.Position - kHRP.Position).Magnitude
                        if dist > State.TwoTimeBackstabRange then continue end

                        local killerLook = kHRP.CFrame.LookVector
                        local fromKillerToMe = (hrp.Position - kHRP.Position).Unit
                        local isBehind = killerLook:Dot(fromKillerToMe) < -0.2

                        local myLook = hrp.CFrame.LookVector
                        local fromMeToKiller = (kHRP.Position - hrp.Position).Unit
                        local amIFacingThem = myLook:Dot(fromMeToKiller) > 0.4

                        local remote = GetRemoteEvent()
                        if isBehind and amIFacingThem and (tick() - lastFire) > COOLDOWN and remote then
                            lastFire = tick()

                            remote:FireServer("UseActorAbility", {
                                buffer.fromstring("\3\6\0\0\0Crouch")
                            })

                            remote:FireServer("UseActorAbility", {
                                buffer.fromstring("\3\6\0\0\0Dagger")
                            })
                        end
                    end
                end)
            end
        end
    end)

    -- Section: chance
    survivors_tab:Section({ Title = "chance" })
    survivors_tab:Toggle({ Title = "auto coinflip (chance)", Desc = "automatically uses coinflip ability", Value = State.AutoCoinflip, Callback = function(val) State.AutoCoinflip = val end })
    survivors_tab:Toggle({ Title = "auto reroll (chance)", Desc = "automatically uses reroll ability", Value = State.AutoReroll, Callback = function(val) State.AutoReroll = val end })
    survivors_tab:Toggle({ Title = "turn on auto hat fix", Desc = "enables auto hat fix logic", Value = State.TurnOnAutoHatFix, Callback = function(val) State.TurnOnAutoHatFix = val end })
    survivors_tab:Slider({ Title = "auto hat fix when at a specific vulnerable (weakness) number", Desc = "vulnerable number threshold (1-20)", Value = { Min = 1, Max = 20, Default = State.AutoHatFixNumber, Step = 1 }, Callback = function(val) State.AutoHatFixNumber = val end })

    survivors_tab:Toggle({
        Title = "auto aim (gun)",
        Desc = "this only aims for u",
        Value = State.ChanceGunAim,
        Callback = function(val) State.ChanceGunAim = val end
    })

    -- Section: elliot
    survivors_tab:Section({ Title = "elliot" })
    survivors_tab:Toggle({ Title = "enable auto rush hour", Desc = "enables auto rush hour when killers near", Value = State.EnableAutoRushHour, Callback = function(val) State.EnableAutoRushHour = val end })
    survivors_tab:Slider({ Title = "auto rush hour when killers near", Desc = "distance threshold to activate rush hour", Value = { Min = 5, Max = 100, Default = State.AutoRushHourRange, Step = 1 }, Callback = function(val) State.AutoRushHourRange = val end })
    survivors_tab:Toggle({ Title = "esp injured players", Desc = "highlights survivors under 60 HP green", Value = State.EspInjuredPlayers, Callback = function(val) State.EspInjuredPlayers = val end })
    survivors_tab:Toggle({ Title = "auto get pizzas", Desc = "might be a little bit weird, but it works", Value = State.AutoGetPizzas, Callback = function(val) State.AutoGetPizzas = val end })
    survivors_tab:Toggle({ Title = "esp elliot pizza", Value = State.EspElliotPizza, Callback = function(val) State.EspElliotPizza = val end })
    survivors_tab:Button({
        Title = "give pizza to nearest player",
        Desc = "throws pizza to nearest visible survivor under 75 HP",
        Callback = function()
            pcall(function()
                local char = LP.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local sf = Workspace:FindFirstChild("Players") and Workspace.Players:FindFirstChild("Survivors")
                if hrp and sf then
                    local nearestPlr = nil
                    local minDist = math.huge
                    for _, s in ipairs(sf:GetChildren()) do
                        if s ~= char then
                            local hum = s:FindFirstChildOfClass("Humanoid")
                            local sHRP = s:FindFirstChild("HumanoidRootPart")
                            if hum and hum.Health < 75 and sHRP then
                                local dist = (sHRP.Position - hrp.Position).Magnitude
                                if dist < minDist then
                                    minDist = dist
                                    nearestPlr = s
                                end
                            end
                        end
                    end
                    if nearestPlr then
                        local remote = GetRemoteEvent()
                        if remote then
                            remote:FireServer("UseActorAbility", { buffer.fromstring("\3\n\0\0\0ThrowPizza") })
                            windui:Notify({ Title = "elliot pizza", Content = "threw pizza to nearest injured survivor nya~! 🍕", Duration = 3 })
                        end
                    else
                        windui:Notify({ Title = "elliot pizza", Content = "no visible survivor under 75 HP found!", Duration = 3 })
                    end
                end
            end)
        end
    })

    survivors_tab:Section({ Title = "jane doe" })
    survivors_tab:Toggle({
        Title = "tp the hatchets hitbox to the killer (when you use it)",
        Desc = "VERY EXPERIMENTAL, OTHER PLAYERS WILL NOT SEE YOU DO ANYTHING DURING THAT TIME",
        Value = State.JaneHatchetTP,
        Callback = function(val) State.JaneHatchetTP = val end
    })
    survivors_tab:Slider({
        Title = "studs behind the killer (hitbox hatchet tp)",
        Desc = "uhh i recommend like 0.2 but the normal is 2.5 so idk",
        Value = { Min = 0.2, Max = 5, Default = State.JaneHatchetTPBehind, Step = 0.1 },
        Callback = function(val) State.JaneHatchetTPBehind = val end
    })
    survivors_tab:Toggle({
        Title = "auto aim (crystal pitch) to a survivor",
        Desc = "this only aims for u, nothing else",
        Value = State.JaneCrystalSurvivor,
        Callback = function(val) State.JaneCrystalSurvivor = val end
    })
    survivors_tab:Toggle({
        Title = "auto aim (crystal pitch) to killer",
        Desc = "this only aims for u, nothing else",
        Value = State.JaneCrystalKiller,
        Callback = function(val) State.JaneCrystalKiller = val end
    })
    survivors_tab:Toggle({
        Title = "auto aim (hatchet) to the killer",
        Desc = "this only aims for u, nothing else",
        Value = State.JaneHatchetAim,
        Callback = function(val) State.JaneHatchetAim = val end
    })
    survivors_tab:Slider({
        Title = "change max distance (hatchet auto aim)",
        Desc = "i recommend like 24.5 if theyre moving or idk",
        Value = { Min = 5, Max = 50, Default = State.JaneHatchetAimDistance, Step = 0.5 },
        Callback = function(val) State.JaneHatchetAimDistance = val end
    })

    survivors_tab:Section({ Title = "shedletsky" })
    survivors_tab:Toggle({
        Title = "sword hitbox tp (to the killer)",
        Desc = "EXPERIMENTAL, YOU NEED GOOD PING FOR THIS",
        Value = State.ShedSwordTP,
        Callback = function(val) State.ShedSwordTP = val end
    })
    survivors_tab:Toggle({
        Title = "auto use and aim slash (when near a killer)",
        Value = State.ShedAutoSlash,
        Callback = function(val) State.ShedAutoSlash = val end
    })
    survivors_tab:Slider({
        Title = "change range (when to slash)",
        Desc = "uhhh i recommend like 19 or something, since its predicting the killer (when they sprint/move)",
        Value = { Min = 5, Max = 30, Default = State.ShedSlashRange, Step = 0.5 },
        Callback = function(val) State.ShedSlashRange = val end
    })

    -- Killers Tab
    killers_tab:Paragraph({ Title = "⚠️ Note", Desc = "some killers have the the same remotes as others, (causing it to break when you use a killer feature while not being that killer) so DO NOT use a killer feature while not being that killer. only use it when you ARE that killer." })
    local setKillerAimbotGui
    do
        local KA_gui, KA_building = nil, false
        setKillerAimbotGui = function(enabled)
            task.spawn(function()
                if not KA_gui and not KA_building and enabled then
                    KA_building = true
                    local okKA, errKA = pcall(function()
		local Players = game:GetService("Players")
		local RunService = game:GetService("RunService")
		local UserInputService = game:GetService("UserInputService")
		local TweenService = game:GetService("TweenService")
		local currentCamera2 = workspace.CurrentCamera
		local localPlayer = Players.LocalPlayer
		local flag10 = false
		local connection = nil
		local flag11 = false
		local v41 = nil
		local character = nil
		local humanoid = nil
		local humanoidRootPart = nil
		local screenGui = nil
		local screenGui2 = nil
		local textButton = nil
		local textLabel = nil
		local frame2 = nil
		local flag12 = true
		local connection2 = nil
		local thread = nil
		local tbl11 = { MAX_DIST_FROM_CROSSHAIR = 350 }

		local function fn23()
			character = localPlayer.Character

			if character then
				humanoid = character:FindFirstChildOfClass("Humanoid")
				humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			end
		end

		local function fn24()
			if flag10 then
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			else
				UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			end
		end

		local function fn25(arg)
			flag10 = arg

			if connection then
				connection:Disconnect()
				connection = nil
			end

			if flag10 then
				fn24()

				connection = RunService.RenderStepped:Connect(function()
					fn23()

					if character and humanoid and humanoidRootPart and humanoidRootPart.Parent then
						humanoid.AutoRotate = false

						if not humanoid.Sit and not humanoidRootPart.Anchored then
							local v42, v43 = currentCamera2.CFrame:ToOrientation()
							humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position) * CFrame.Angles(0, v43, 0)
						end
					end
				end)
			else
				fn24()
				fn23()

				if humanoid and humanoid.Parent then
					humanoid.AutoRotate = true
				end
			end
		end

		local function fn26()
			local players = workspace:FindFirstChild("Players")
			return players and players:FindFirstChild("Survivors")
		end

		local function fn27()
			local v42 = fn26()
			if not v42 then
				return nil
			end
			local vector2 = Vector2.new(currentCamera2.ViewportSize.X / 2, currentCamera2.ViewportSize.Y / 2)
			local huge = math.huge
			local v43 = nil

			for _, child in ipairs(v42:GetChildren()) do
				if child:IsA("Model") then
					local humanoidRootPart2 = child:FindFirstChild("HumanoidRootPart")
					local humanoid2 = child:FindFirstChildOfClass("Humanoid")

					if Players:GetPlayerFromCharacter(child) ~= localPlayer and humanoidRootPart2 and humanoid2 and humanoid2.Health > 0 then
						local v44, v45 = currentCamera2:WorldToViewportPoint(humanoidRootPart2.Position)

						if v45 then
							local magnitude = (vector2 - Vector2.new(v44.X, v44.Y)).Magnitude

							if magnitude < huge and magnitude <= tbl11.MAX_DIST_FROM_CROSSHAIR then
								huge = magnitude
								v43 = child
							end
						end
					end
				end
			end

			return v43
		end

		local function fn28()
			if not flag11 or not v41 then
				return
			end
			local v42 = v41

			if not v42 or not v42.Parent then
				v41 = nil

				if textLabel then
					textLabel.Text = "Aimbot : No target :("
				end

				if flag10 then
					fn25(false)
				end

				return
			end

			local humanoid2 = v42:FindFirstChildOfClass("Humanoid")

			if humanoid2 and humanoid2.Health <= 0 then
				v41 = nil

				if textLabel then
					textLabel.Text = "Aimbot : No target :("
				end

				if flag10 then
					fn25(false)
				end

				return
			end

			local humanoidRootPart2 = v42:FindFirstChild("HumanoidRootPart")

			if humanoidRootPart2 then
				currentCamera2.CFrame = currentCamera2.CFrame:Lerp(CFrame.lookAt(currentCamera2.CFrame.Position, humanoidRootPart2.Position), 0.65)

				if textLabel then
					textLabel.Text = "Aimbot : On - Locked"
				end
			else
				v41 = nil

				if textLabel then
					textLabel.Text = "Aimbot : No target :("
				end

				if flag10 then
					fn25(false)
				end
			end
		end

		local function fn29()
			if flag11 then
				if v41 and v41.Parent and v41:FindFirstChild("HumanoidRootPart") then
					local humanoid2 = v41:FindFirstChildOfClass("Humanoid")
					if humanoid2 and humanoid2.Health > 0 then
						return
					end
				end

				local v42 = fn27()

				if v42 then
					v41 = v42

					if textLabel then
						textLabel.Text = "Aimbot : On - Locked"
					end

					if not flag10 then
						fn25(true)
					end
				else
					v41 = nil

					if textLabel then
						textLabel.Text = "Aimbot : No target :("
					end

					if flag10 then
						fn25(false)
					end
				end
			end
		end

		local function fn30()
			if not flag12 then
				return
			end
			flag11 = not flag11

			if flag11 then
				v41 = fn27()

				if textLabel then
					textLabel.Text = v41 and "Aimbot : On - Locked" or "Aimbot : No target :("
				end

				fn25(v41 ~= nil)

				if frame2 then
					frame2.Visible = true
				end

				RunService:UnbindFromRenderStep("KillerAimbotLock")
				RunService:BindToRenderStep("KillerAimbotLock", Enum.RenderPriority.Camera.Value + 100, fn28)

				if thread then
					task.cancel(thread)
				end

				thread = task.spawn(function()
					while flag11 do
						task.wait(0.1)

						if flag11 then
							fn29()
						end
					end
				end)
			else
				if textLabel then
					textLabel.Text = "Aimbot : Off"
				end

				v41 = nil
				fn25(false)

				if frame2 then
					frame2.Visible = false
				end

				RunService:UnbindFromRenderStep("KillerAimbotLock")

				if thread then
					task.cancel(thread)
					thread = nil
				end
			end
		end

		local function fn31()
			screenGui2 = Instance.new("ScreenGui")
			screenGui2.Name = "KillerAimbotCrosshair"
			screenGui2.ResetOnSpawn = false
			screenGui2.IgnoreGuiInset = true
			screenGui2.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			screenGui2.Parent = localPlayer:WaitForChild("PlayerGui")
			frame2 = Instance.new("Frame")
			frame2.Name = "Crosshair"
			frame2.Size = UDim2.new(0, 6, 0, 6)
			frame2.Position = UDim2.new(0.5, 0, 0.5, 0)
			frame2.AnchorPoint = Vector2.new(0.5, 0.5)
			frame2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			frame2.BackgroundTransparency = 0
			frame2.BorderSizePixel = 0
			frame2.Visible = false
			frame2.ZIndex = 60
			frame2.Parent = screenGui2
			local uiCorner = Instance.new("UICorner")
			uiCorner.CornerRadius = UDim.new(1, 0)
			uiCorner.Parent = frame2
			screenGui = Instance.new("ScreenGui")
			screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
			screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			screenGui.ResetOnSpawn = false
			screenGui.DisplayOrder = 50
			screenGui.Enabled = false
			textButton = Instance.new("TextButton")
			textButton.Parent = screenGui
			textButton.BorderSizePixel = 0
			textButton.TextSize = 14
			textButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			textButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			textButton.Font = Enum.Font.SourceSansBold
			textButton.Size = UDim2.new(0.21705, 0, 0.15205, 0)
			textButton.Text = ""
			textButton.Name = "MAIN"
			textButton.Position = UDim2.new(0.312, 0, 0.25731, 0)
			textButton.ZIndex = 1000
			Instance.new("UICorner", textButton)
			local uiGradient = Instance.new("UIGradient", textButton)
			local colorSequence = ColorSequence.new
			local tbl12 = {}
			local v42 = ColorSequenceKeypoint.new(0, Color3.fromRGB(33, 33, 33))
			local v43 = ColorSequenceKeypoint.new(0.793, Color3.fromRGB(171, 0, 0))
			local new = ColorSequenceKeypoint.new
			local color2 = Color3.fromRGB
			tbl12[1] = v42
			tbl12[2] = v43

			do
				local values = table.pack(new(1, color2(171, 0, 0)))
				table.move(values, 1, values.n, 3, tbl12)
			end

			uiGradient.Color = colorSequence(tbl12)
			local frame3 = Instance.new("Frame", textButton)
			frame3.BorderSizePixel = 0
			frame3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			frame3.Size = UDim2.new(1, 0, 0.46154, 0)
			frame3.Position = UDim2.new(0, 0, -0.5, 0)
			frame3.Name = "title"
			Instance.new("UICorner", frame3)
			local textLabel2 = Instance.new("TextLabel", frame3)
			textLabel2.BorderSizePixel = 0
			textLabel2.TextSize = 14
			textLabel2.BackgroundTransparency = 1
			textLabel2.Text = "Killers Aimbot"
			textLabel2.Font = Enum.Font.SourceSansBold
			textLabel2.TextColor3 = Color3.fromRGB(255, 255, 255)
			textLabel2.Size = UDim2.new(1, 0, 1.4, 0)
			textLabel2.Position = UDim2.new(0, 0, -0.3, 0)
			local uiGradient2 = Instance.new("UIGradient", frame3)
			local colorSequence2 = ColorSequence.new
			local tbl13 = {}
			local v44 = ColorSequenceKeypoint.new(0, Color3.fromRGB(57, 6, 6))
			local v45 = ColorSequenceKeypoint.new(0.288, Color3.fromRGB(94, 11, 11))
			local new2 = ColorSequenceKeypoint.new
			local color3 = Color3.fromRGB
			tbl13[1] = v44
			tbl13[2] = v45

			do
				local values = table.pack(new2(1, color3(206, 22, 22)))
				table.move(values, 1, values.n, 3, tbl13)
			end

			uiGradient2.Color = colorSequence2(tbl13)
			textLabel = Instance.new("TextLabel", textButton)
			textLabel.BorderSizePixel = 0
			textLabel.TextSize = 16
			textLabel.BackgroundTransparency = 1
			textLabel.Font = Enum.Font.SourceSansBold
			textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			textLabel.Size = UDim2.new(0.35227, 0, 0.30769, 0)
			textLabel.Text = "Aimbot : Off"
			textLabel.Name = "aimTEXT"
			textLabel.Position = UDim2.new(0.32955, 0, 0.30769, 0)
			Instance.new("UIAspectRatioConstraint", textButton).AspectRatio = 3.38462
			local flag13 = nil
			local v46 = nil
			local position = nil
			local position2 = nil

			textButton.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					flag13 = true
					position = input.Position
					position2 = textButton.Position

					input.Changed:Connect(function(arg)
						if arg.UserInputState == Enum.UserInputState.End then
							flag13 = false
						end
					end)
				end
			end)

			textButton.InputChanged:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
					v46 = input
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if input == v46 and flag13 then
					local n24 = input.Position - position
					textButton.Position = UDim2.new(position2.X.Scale, position2.X.Offset + n24.X, position2.Y.Scale, position2.Y.Offset + n24.Y)
				end
			end)

			textButton.MouseButton1Click:Connect(fn30)

			task.spawn(function()
				while task.wait(1) do
					if textButton and textButton.Parent then
						local random = math.random

						local tbl14 = {
							BackgroundColor3 = Color3.fromRGB(math.random(80, 255), math.random(80, 255), random(80, 255)),
						}

						TweenService:Create(textButton, TweenInfo.new(1, Enum.EasingStyle.Linear), tbl14):Play()
					end
				end
			end)
		end

		local function fn32()
			if connection2 then
				connection2:Disconnect()
			end

			connection2 = UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if gameProcessed then
					return
				end

				if input.KeyCode == Enum.KeyCode.V and flag12 then
					fn30()
				end
			end)
		end

		local function fn33()
			if screenGui then
				screenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
					flag12 = screenGui.Enabled

					if not flag12 and flag11 then
						fn30()
					end
				end)
			end
		end

		localPlayer.CharacterAdded:Connect(function()
			fn23()
			task.wait(0.6)

			if flag11 then
				v41 = fn27()

				if textLabel then
					textLabel.Text = v41 and "Aimbot : On - Locked" or "Aimbot : No target :("
				end

				fn25(v41 ~= nil)

				if frame2 then
					frame2.Visible = true
				end
			else
				fn25(false)

				if frame2 then
					frame2.Visible = false
				end
			end
		end)

		fn23()
		fn31()
		fn32()
		fn33()
		KA_gui = screenGui
                    end)
                    KA_building = false
                    if not okKA then warn("[forsaken8z] killers aimbot gui failed: " .. tostring(errKA)) end
                end
                if KA_gui then KA_gui.Enabled = enabled end
            end)
        end
    end
    killers_tab:Toggle({ Title = "killer aimbot", Desc = "no, this does not automatically attack for you.", Value = State.KillerAimbot, Callback = function(val)
        State.KillerAimbot = val
        setKillerAimbotGui(val)
    end })

    -- Killers Tab - noli Section
    killers_tab:Section({ Title = "noli" })
    killers_tab:Toggle({ Title = "void rush controller", Value = State.VoidRushController, Callback = function(val) State.VoidRushController = val end })
    killers_tab:Toggle({ Title = "anti noli clones", Desc = "removes (nolis clones", Value = State.AntiNoliClones, Callback = function(val) State.AntiNoliClones = val end })
    killers_tab:Toggle({ Title = "auto stab", Desc = "this attacks for you", Value = State.NoliAutoStab, Callback = function(val) State.NoliAutoStab = val end })
    killers_tab:Slider({ Title = "change auto stab range", Desc = "i recommend to set it at like 6.9", Value = { Min = 2.5, Max = 9.5, Default = State.NoliStabRange, Step = 0.1 }, Callback = function(val) State.NoliStabRange = val end })
    killers_tab:Toggle({ Title = "auto nova", Value = State.NoliAutoNova, Callback = function(val) State.NoliAutoNova = val end })
    killers_tab:Slider({ Title = "change auto nova range", Desc = "uhh i recommend to set it at like 32.5", Value = { Min = 5.5, Max = 75, Default = State.NoliNovaRange, Step = 0.5 }, Callback = function(val) State.NoliNovaRange = val end })
    killers_tab:Toggle({ Title = "remove the explosion effects from when a nova explodes", Desc = " this is for lower end devices", Value = State.AntiNovaExplosion, Callback = function(val) State.AntiNovaExplosion = val end })
    killers_tab:Toggle({ Title = "stop void rush at any time", Value = State.StopVoidRush, Callback = function(val)
        State.StopVoidRush = val
        if val then
            pcall(function()
                local remote = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Network"):WaitForChild("Network"):WaitForChild("RemoteEvent")
                remote:FireServer(LP.Name .. "VoidRushCollision", { buffer.fromstring("\1\1") })
            end)
        end
    end })
    killers_tab:Toggle({ Title = "lag/crash a server using nova", Desc = "THIS ONLY WORKS WHEN COOLDOWN IS DISABLED", Value = State.LagServerNova, Callback = function(val) State.LagServerNova = val end })
    killers_tab:Toggle({ Title = "notify if nolis nova is near you", Value = State.NotifyNoliNova, Callback = function(val) State.NotifyNoliNova = val end })
    killers_tab:Toggle({ Title = "anti guest block bait", Desc = "this auto stops your voidrush when a guest blocks near you (works both on mobile and pc)", Value = State.AntiGuestBlockBait, Callback = function(val) State.AntiGuestBlockBait = val end })
    killers_tab:Slider({ Title = "change the duration when to stop the void rush (studs)", Desc = "i recommend to set it at like 20, maybe 30 if your lagging(?)", Value = { Min = 5, Max = 50, Default = State.NoliBaitDistance, Step = 1 }, Callback = function(val) State.NoliBaitDistance = val end })

    -- Killers Tab - c00lkidd Section
    killers_tab:Section({ Title = "c00lkidd" })
    killers_tab:Button({
        Title = "c00lkidd walkspeed override controller",
        Desc = "makes it so that your able to move freely when using walkspeed override",
        Callback = function()
            pcall(function()
                local Behavior = require(ReplicatedStorage.Assets.Killers.c00lkidd.Behavior)
                Behavior.Abilities.WalkspeedOverride.Callback = function(p3)
                    p3.Animations.WalkspeedOverrideStart:Play()
                    p3.Rig:SetAttribute("FootstepsMuted", true)

                    task.wait(0.35)

                    if not p3.Rig or not p3.Rig.PrimaryPart then return end

                    p3.Animations.WalkspeedOverrideLoop.Looped = true
                    p3.Animations.WalkspeedOverrideLoop:Play()

                    local start = os.clock()
                    local conn
                    local bv = Instance.new("BodyVelocity")
                    bv.MaxForce = Vector3.new(9e9, 0, 9e9) 
                    bv.P = 1e5
                    bv.Parent = LP.Character:WaitForChild("HumanoidRootPart")

                    conn = RunService.Heartbeat:Connect(function()
                        if os.clock() - start >= 1.6 or not p3.Rig or not p3.Rig.PrimaryPart then
                            conn:Disconnect()
                            bv:Destroy()
                            return
                        end

                        local cam = workspace.CurrentCamera
                        local look = cam.CFrame.LookVector
                        look = Vector3.new(look.X, 0, look.Z).Unit

                        local move = Vector3.zero
                        if UIS:IsKeyDown(Enum.KeyCode.W) then move += look end
                        if UIS:IsKeyDown(Enum.KeyCode.S) then move -= look end
                        if UIS:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
                        if UIS:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end

                        if move.Magnitude > 0 then
                            move = move.Unit
                        else
                            move = look
                        end

                        bv.Velocity = move * 150
                    end)

                    task.wait(1.6)

                    if conn then conn:Disconnect() end
                    if bv then bv:Destroy() end

                    p3.Rig:SetAttribute("FootstepsMuted", nil)
                    p3.Animations.WalkspeedOverrideStart:Stop()
                    p3.Animations.WalkspeedOverrideLoop:Stop()

                    if p3.Animations.WalkspeedOverrideMiss then
                        p3.Animations.WalkspeedOverrideMiss:Play(0.05)
                    end

                    local Hum = LP.Character:FindFirstChildOfClass("Humanoid")
                    if Hum then
                        local oldWS = Hum.WalkSpeed
                        Hum.WalkSpeed = oldWS * 0.35
                        task.wait(0.4)
                        Hum.WalkSpeed = oldWS
                    end
                end
                windui:Notify({ Title = "c00lkidd controller", Content = "c00lkidd walkspeed override controller active! 🐾", Duration = 3 })
            end)
        end
    })

    killers_tab:Toggle({ Title = "corrupt nature aimbot", Desc = "Smooth Survivor Camera Lock + CorruptNature (1s lock limit)", Value = State.CorruptNatureAimbot, Callback = function(val) State.CorruptNatureAimbot = val end })
    killers_tab:Toggle({ Title = "walkspeed override aimbot", Desc = "this automatically does it for you without having to press an ability", Value = State.WalkspeedOverrideAimbot, Callback = function(val) State.WalkspeedOverrideAimbot = val end })
    killers_tab:Toggle({ Title = "tag auto hit survivors", Desc = "this automatically does it for you, you don't have to click an ability.", Value = State.TagAutoHit, Callback = function(val) State.TagAutoHit = val end })
    killers_tab:Slider({ Title = "adjust when to hit (studs)", Desc = "i recommend to set it at 7.1", Value = { Min = 2, Max = 8.5, Default = State.TagHitDistance, Step = 0.1 }, Callback = function(val) State.TagHitDistance = val end })

    -- Section: slasher
    killers_tab:Section({ Title = "slasher" })
    killers_tab:Toggle({ Title = "auto slash at survivor(s)", Desc = "automatically slashes at survivors. DO NOT TURN THIS FEATURE ON IF YOUR OTHER KILLERS. ONLY TURN THIS ON IF YOUR SLASHER AND IS IN THE ROUND.", Value = State.AutoSlashSlasher, Callback = function(val) State.AutoSlashSlasher = val end })
    killers_tab:Slider({ Title = "change camera locking to survivors duration", Value = { Min = 0, Max = 0.7, Default = State.SlasherLockDuration, Step = 0.05 }, Callback = function(val) State.SlasherLockDuration = val end })
    killers_tab:Toggle({ Title = "auto behead", Desc = "automatically uses behead at survivors when near. DO NOT TURN THIS FEATURE ON IF YOUR OTHER KILLERS. ONLY TURN THIS ON IF YOUR SLASHER AND IS IN THE ROUND.", Value = State.AutoBehead, Callback = function(val) State.AutoBehead = val end })
    killers_tab:Toggle({ Title = "auto raging pace at low stamina", Desc = "automatically uses raging pace without clicking it at a specific stamina amount", Value = State.AutoRagingPace, Callback = function(val) State.AutoRagingPace = val end })
    killers_tab:Slider({ Title = "stamina amount to use raging pace", Value = { Min = 5, Max = 95, Default = State.RagingPaceStaminaThreshold, Step = 1 }, Callback = function(val) State.RagingPaceStaminaThreshold = val end })

    -- Section: sixer/guest 666
    killers_tab:Section({ Title = "sixer/guest 666" })
    killers_tab:Toggle({
        Title = "demonic pursuit infinite hitbox trail and control EXTREMELY OP",
        Desc = "⚠️ YOU WILL GET BANNED FOR BUG ABUSE/EXPLOITING, THIS IS EXTREMELY OBVIOUS ⚠️",
        Value = State.SixerPursuitFreeMove,
        Callback = function(val)
            State.SixerPursuitFreeMove = val
            if val then
                task.spawn(function()
                    local active = false
                    local conn
                    local function getCharData()
                        local c = LP.Character
                        if not c then return false end
                        local hrp = c:FindFirstChild("HumanoidRootPart")
                        local hum = c:FindFirstChild("Humanoid")
                        return hrp and hum and hum.Health > 0, hrp, hum
                    end

                    local function getMoveDir(hum)
                        if not hum then return Vector3.zero end
                        local md = hum.MoveDirection
                        local vertical = 0
                        if UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:IsKeyDown(Enum.KeyCode.ButtonA) then vertical = 1 end
                        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.ButtonB) then vertical = -1 end
                        if UIS.TouchEnabled and hum.Jump then vertical = 1 end
                        local dir = Vector3.new(md.X, vertical, md.Z)
                        if dir.Magnitude > 0.05 then return dir.Unit end
                        return Vector3.zero
                    end

                    local function stopFree()
                        active = false
                        if conn then conn:Disconnect(); conn = nil end
                    end

                    local function startFree()
                        if active then return end
                        active = true
                        pcall(function()
                            RunService:UnbindFromRenderStep("666PursuitCharge")
                            RunService:UnbindFromRenderStep("666PursuitPrepare")
                        end)
                        conn = RunService.Heartbeat:Connect(function()
                            if not State.SixerPursuitFreeMove then stopFree(); return end
                            local ok, hrp, hum = getCharData()
                            if not ok then stopFree(); return end
                            local state = LP.Character:GetAttribute("PursuitState")
                            if not state or state == "" or state == "Cancelled" then stopFree(); return end

                            pcall(function()
                                RunService:UnbindFromRenderStep("666PursuitCharge")
                                RunService:UnbindFromRenderStep("666PursuitPrepare")
                            end)

                            local dir = getMoveDir(hum)
                            if dir.Magnitude > 0.05 then
                                hrp.AssemblyLinearVelocity = dir * (State.SixerPursuitSpeed or 78)
                            else
                                hrp.AssemblyLinearVelocity = Vector3.new(0, 3, 0)
                            end
                        end)
                    end

                    local function watcher(c)
                        c:GetAttributeChangedSignal("PursuitState"):Connect(function()
                            if not State.SixerPursuitFreeMove then return end
                            local st = c:GetAttribute("PursuitState")
                            if st == "Charging" or st == "Lunging" or st == "Dashing" then
                                task.wait(0.03)
                                startFree()
                            else
                                stopFree()
                            end
                        end)
                    end

                    if LP.Character then watcher(LP.Character) end
                    LP.CharacterAdded:Connect(watcher)
                end)
            end
        end
    })

    killers_tab:Slider({
        Title = "change demonic pursuit infinite hitbox speed",
        Value = { Min = 15, Max = 100, Default = State.SixerPursuitSpeed, Step = 1 },
        Callback = function(val)
            State.SixerPursuitSpeed = val
        end
    })

    -- Sixer / Guest 666 New Features Added Here
    killers_tab:Toggle({
        Title = "auto use carving slash (m1) when a survivor is near",
        Value = State.SixerCarvingSlash,
        Callback = function(val) State.SixerCarvingSlash = val end
    })
    killers_tab:Slider({
        Title = "change range (studs) when to use it",
        Desc = "i recommend to set it at like 7.1(?) idk",
        Value = { Min = 2, Max = 15, Default = State.SixerCarvingRange, Step = 0.1 },
        Callback = function(val) State.SixerCarvingRange = val end
    })
    killers_tab:Toggle({
        Title = "auto aim (to nearest survivor) when using demonic pursuit",
        Desc = "this doesnt do it automatically for u!!!!!",
        Value = State.SixerPursuitAimbot,
        Callback = function(val) State.SixerPursuitAimbot = val end
    })
    killers_tab:Toggle({
        Title = "auto use infernal cry and aim on (nearest) survivor",
        Value = State.SixerInfernalCryAuto,
        Callback = function(val) State.SixerInfernalCryAuto = val end
    })
    killers_tab:Toggle({
        Title = "auto aim when using infernal cry",
        Desc = "this doesnt do it automatically for u!!!!!",
        Value = State.SixerInfernalCryAim,
        Callback = function(val) State.SixerInfernalCryAim = val end
    })

    -- Section: nosferatu
    killers_tab:Section({ Title = "nosferatu" })
    killers_tab:Toggle({
        Title = "make nosferatus original form be visible if hes a bat",
        Value = State.NosferatuOriginalVisible,
        Callback = function(val)
            State.NosferatuOriginalVisible = val
        end
    })

    killers_tab:Toggle({
        Title = "notify if hes flying",
        Value = State.NosferatuFlyNotify,
        Callback = function(val)
            State.NosferatuFlyNotify = val
            if val then
                task.spawn(function()
                    while State.NosferatuFlyNotify and ScriptRunning do
                        task.wait(0.2)
                        pcall(function()
                            local nos = Workspace:FindFirstChild("Players") and Workspace.Players:FindFirstChild("Killers") and Workspace.Players.Killers:FindFirstChild("Nosferatu")
                            if nos and nos:FindFirstChild("SpeedMultipliers") and nos.SpeedMultipliers:FindFirstChild("NosFlying") then
                                windui:Notify({ Title = "Nosferatu Alert", Content = "nos is flying (nosferatu)", Duration = 3 })
                                task.wait(3)
                            end
                        end)
                    end
                end)
            end
        end
    })

    -- Nosferatu New Features Added Here
    killers_tab:Toggle({
        Title = "auto use lacerate on survivors",
        Value = State.NosAutoLacerate,
        Callback = function(val) State.NosAutoLacerate = val end
    })
    killers_tab:Slider({
        Title = "change range when to lacerate",
        Desc = "uhh i recommend like 7.5",
        Value = { Min = 2, Max = 15, Default = State.NosLacerateRange, Step = 0.5 },
        Callback = function(val) State.NosLacerateRange = val end
    })
    killers_tab:Toggle({
        Title = "auto use bloodhook on survivors",
        Desc = "auto aims at survivors (the nearest one) and grabs them",
        Value = State.NosAutoBloodhook,
        Callback = function(val) State.NosAutoBloodhook = val end
    })
    killers_tab:Slider({
        Title = "change range (studs) when to grab them",
        Desc = "i recommend like 50 if your chasing them idk",
        Value = { Min = 5, Max = 120, Default = State.NosBloodhookRange, Step = 1 },
        Callback = function(val) State.NosBloodhookRange = val end
    })
    killers_tab:Toggle({
        Title = "auto use hunters feast on (nearest) survivors",
        Desc = "i recommend like 26.5 or something",
        Value = State.NosAutoHuntersFeast,
        Callback = function(val) State.NosAutoHuntersFeast = val end
    })
    killers_tab:Slider({
        Title = "change the range (studs) when 2 use hunters feast",
        Desc = "i recommend like 26.5 or something",
        Value = { Min = 5, Max = 120, Default = State.NosHuntersFeastRange, Step = 0.5 },
        Callback = function(val) State.NosHuntersFeastRange = val end
    })

    killers_tab:Section({ Title = "azure" })
    killers_tab:Toggle({ Title = "esp azures plant state", Desc = "shows plant state (blooming/wither)", Value = State.EspAzuresPlantState, Callback = function(val) State.EspAzuresPlantState = val end })
    killers_tab:Toggle({ Title = "survivor atropa and oblation value (azure)", Desc = "shows atropa level above survivors", Value = State.SurvivorAtropaOblation, Callback = function(val) State.SurvivorAtropaOblation = val end })
    killers_tab:Toggle({ Title = "auto disarm azures vines", Desc = "run it BEFORE you start disarming a plant. completes the skillcheck automatically.", Value = State.AutoDisarmVines, Callback = function(val) State.AutoDisarmVines = val end })
    killers_tab:Toggle({ Title = "auto hit survivors", Desc = "automatically hits survivors", Value = State.AzureAutoHit, Callback = function(val) State.AzureAutoHit = val end })
    killers_tab:Slider({ Title = "change survivor range (when to hit them)", Desc = "uh i recommend to set it at like 7.1", Value = { Min = 2, Max = 15, Default = State.AzureHitRange, Step = 0.1 }, Callback = function(val) State.AzureHitRange = val end })
    killers_tab:Toggle({ Title = "auto grab and shoot survivors", Desc = "automatically grabs and shoots survivors (idk how to explain it)", Value = State.AzureAutoGrab, Callback = function(val) State.AzureAutoGrab = val end })
    killers_tab:Slider({ Title = "change when to grab and shoot the survivors (studs)", Desc = "i recommend to set it at like 26(?) idk", Value = { Min = 5, Max = 80, Default = State.AzureGrabRange, Step = 1 }, Callback = function(val) State.AzureGrabRange = val end })

    -- Section: john doe
    killers_tab:Section({ Title = "john doe" })
    killers_tab:Toggle({ Title = "aim to survivors when using corrupt energy", Desc = "no, this does not automatically use the ability for you.", Value = State.CorruptEnergyCamLock, Callback = function(val) State.CorruptEnergyCamLock = val end })
    killers_tab:Toggle({ Title = "auto slash aim lock", Desc = "this automatically attacks for you", Value = State.AutoSlashAimLock, Callback = function(val) State.AutoSlashAimLock = val end })
    killers_tab:Button({
        Title = "place digital footprint on two times spawnpoint",
        Desc = "teleports to one respawnlocation/ritual once and fires digital footprint",
        Callback = function()
            pcall(function()
                local ingame = Workspace:WaitForChild("Map"):WaitForChild("Ingame")
                local remote = GetRemoteEvent()
                local activatedOnce = false

                for _, obj in ipairs(ingame:GetDescendants()) do
                    if string.find(string.lower(obj.Name), "respawnlocation", 1, true) ~= nil and not activatedOnce then
                        local char = LP.Character
                        local root = char and char:FindFirstChild("HumanoidRootPart")
                        local targetPart = nil
                        if obj:IsA("BasePart") then
                            targetPart = obj
                        elseif obj:IsA("Model") then
                            targetPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
                        end

                        if root and targetPart then
                            activatedOnce = true
                            root.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                            if remote and not IsAbilityOnCooldown("DigitalFootprint") then
                                remote:FireServer("UseActorAbility", { buffer.fromstring("\3\16\0\0\0DigitalFootprint") })
                            end
                            windui:Notify({ Title = "John Doe", Content = "placed digital footprint on spawnpoint! 🐾", Duration = 3 })
                            break
                        end
                    end
                end

                if not activatedOnce then
                    windui:Notify({ Title = "John Doe", Content = "no two times spawnpoint found!", Duration = 3 })
                end
            end)
        end
    })

    -- Section: 1x1x1x1
    killers_tab:Section({ Title = "1x1x1x1" })
    killers_tab:Toggle({ Title = "esp 1x1s swords (entanglement)", Value = State.Esp1x1Swords, Callback = function(val) State.Esp1x1Swords = val end })
    killers_tab:Toggle({ Title = "esp 1x1s shockwave (mass infection)", Value = State.Esp1x1Shockwave, Callback = function(val) State.Esp1x1Shockwave = val end })
    killers_tab:Toggle({ Title = "auto aim to the nearest survivor when using entanglement", Desc = "no, this do do the ability automatically", Value = State.EntanglementCamLock, Callback = function(val) State.EntanglementCamLock = val end })
    killers_tab:Toggle({ Title = "auto aim to the nearest survivor when using mass infection", Desc = "no, this doesnt do the ability automatically.", Value = State.MassInfectionCamLock, Callback = function(val) State.MassInfectionCamLock = val end })

    -- Items Tab
    items_tab:Toggle({ Title = "items esp", Desc = "highlights medkits (red) and colas (brown)", Value = State.ItemESP, Callback = function(val) State.ItemESP = val end })

    items_tab:Button({
        Title = "teleport to medkit",
        Desc = "teleports to a medkit and grabs it (move your camera down before using it otherwise it wont work)",
        Callback = function()
            local result = SingleTeleportAndClick("medkit")
            if result then
                windui:Notify({ Title = "item teleport", Content = "grabbed", Duration = 3 })
            else
                windui:Notify({ Title = "item teleport", Content = "no medkit found", Duration = 3 })
            end
        end
    })

    items_tab:Button({
        Title = "teleport to cola",
        Desc = "teleports to a cola and grabs it (move your camera down before using it otherwise it wont work)",
        Callback = function()
            local result = SingleTeleportAndClick("bloxycola")
            if result then
                windui:Notify({ Title = "item teleport", Content = "grabbed", Duration = 3 })
            else
                windui:Notify({ Title = "item teleport", Content = "no bloxy cola", Duration = 3 })
            end
        end
    })

    items_tab:Button({
        Title = "copy your coords location",
        Callback = function()
            pcall(function()
                local char = LP.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and setclipboard then
                    setclipboard(tostring(hrp.CFrame))
                    windui:Notify({ Title = "coords", Content = "exact position copied nya~ :3", Duration = 3 })
                end
            end)
        end
    })

    items_tab:Input({
        Title = "where to compile the items",
        Desc = "enter CFrame string or coordinates",
        Value = "",
        Placeholder = "CFrame...",
        Callback = function(val)
            State.CompileCoords = val
        end
    })

    items_tab:Button({
        Title = "compile items at a coordinate",
        Callback = function()
            pcall(function()
                local remote = GetRemoteEvent()
                if not remote then return end
                local char = LP.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local origCFrame = hrp.CFrame
                if State.CompileCoords ~= "" then
                    local success, parsedCF = pcall(function()
                        return loadstring("return " .. State.CompileCoords)()
                    end)
                    if success and typeof(parsedCF) == "CFrame" then
                        hrp.CFrame = parsedCF
                        task.wait(0.1)
                    end
                end

                for _, tool in ipairs(LP.Backpack:GetChildren()) do
                    if tool:IsA("Tool") then
                        local isBlacklisted = false
                        for _, bName in ipairs(State.BlacklistItems) do
                            if bName == tool.Name then
                                isBlacklisted = true
                                break
                            end
                        end
                        if not isBlacklisted and (tool.Name == "Medkit" or tool.Name == "BloxyCola" or tool.Name == "MedKit" or tool.Name == "Bloxy Cola") then
                            remote:FireServer("DropItem", { tool })
                            task.wait(0.05)
                        end
                    end
                end

                task.wait(0.1)
                hrp.CFrame = origCFrame
                windui:Notify({ Title = "compile items", Content = "items compiled once successfully!", Duration = 3 })
            end)
        end
    })

    local function GetBackpackItemNames()
        local list = {}
        pcall(function()
            for _, t in ipairs(LP.Backpack:GetChildren()) do
                if t:IsA("Tool") then
                    table.insert(list, t.Name)
                end
            end
        end)
        if #list == 0 then
            table.insert(list, "none yet")
        end
        return list
    end

    items_tab:Dropdown({
        Title = "blacklist items to compile",
        Values = GetBackpackItemNames(),
        Value = "none yet",
        Callback = function(selected)
            if selected ~= "none yet" then
                table.insert(State.BlacklistItems, selected)
            end
        end
    })

    -- inf bloxy cola + private server items
    do
        local okInf, errInf = pcall(function()
local v40 = nil

local function startBloxy(arg)
		if arg then
			getgenv().infBloxySettings = getgenv().infBloxySettings or { cooldownDuration = 3 }

			local function fn22()
				local Players = game:GetService("Players")
				local ReplicatedStorage = game:GetService("ReplicatedStorage")
				local RunService = game:GetService("RunService")
				local localPlayer = Players.LocalPlayer
				local str5 = "rbxassetid://102123566838185"
				local statuses = game:GetService("ReplicatedStorage").Modules.Gameplay.Statuses
				local statusContainer = statuses.StatusContainer
				local statusDisplay = statuses.StatusDisplay
				local speed = ReplicatedStorage.Modules.Schematics.StatusEffects:FindFirstChild("Speed")
				local humanoid = nil
				local v41 = nil
				local connection = nil
				local connection2 = nil
				local flag10 = false
				local flag11 = false
				local v42 = nil
				local v43 = nil
				local connection3 = nil
				local now2 = nil
				local flag12 = false
				local fieldOfView = nil
				local currentCamera2 = workspace.CurrentCamera
				local tbl11 = nil
				local v44 = nil
				local flag13 = false

				local function fn23()
					if flag13 then
						return
					end
					flag13 = true

					v44 = hookmetamethod(game, "__newindex", function(arg2, arg3, arg4)
						return v44(arg2, arg3, arg4)
					end)
				end

				local function fn24()
					if v44 then
						hookmetamethod(game, "__newindex", v44)
						v44 = nil
						flag13 = false
					end
				end

				local function fn25(arg2)
					local n24 = math.floor(arg2 / 60)
					local n25 = math.floor(arg2 % 60)
					return string.format("%02d:%02d", n24, n25)
				end

				local function fn26()
					if currentCamera2 and not fieldOfView then
						fieldOfView = currentCamera2.FieldOfView
					end
				end

				local function fn27()
					if currentCamera2 and fieldOfView then
						if currentCamera2.FieldOfView ~= fieldOfView then
							currentCamera2.FieldOfView = fieldOfView
						end
					end
				end

				local function fn28(arg2)
					if not speed then
						return
					end
					local ok, result = pcall(require, speed)
					if not ok or not result then
						return
					end

					if tbl11 then
						pcall(function()
							result.Removed(tbl11)
						end)
					end

					tbl11 = { Player = localPlayer, Level = arg2, Data = result.Data }

					pcall(function()
						result.Applied(tbl11)
					end)
				end

				local function fn29()
					if not speed then
						return
					end
					local ok, result = pcall(require, speed)
					if not ok or not result then
						return
					end

					if tbl11 then
						pcall(function()
							result.Removed(tbl11)
						end)

						tbl11 = nil
					end

					if fieldOfView and currentCamera2 then
						task.delay(1, function()
							if currentCamera2 then
								currentCamera2.FieldOfView = fieldOfView
							end
						end)
					end
				end

				local function fn30()
					if connection3 then
						connection3:Disconnect()
						connection3 = nil
					end

					if v43 and v43.Parent then
						v43:Destroy()
					end

					v43 = nil
					flag10 = false
					flag11 = false
					v42 = nil
					flag12 = false
					fn24()
				end

				local function fn31()
					local bloxyCola = localPlayer.PlayerGui.MainUI.Backpack:FindFirstChild("BloxyCola")

					if bloxyCola then
						local v45 = getconnections(bloxyCola.MouseButton1Click)

						if v45 and v45[1] and typeof(v45[1].Function) == "function" then
							pcall(v45[1].Function)
						end
					end
				end

				local function fn32(name, arg2)
					local statusContainer2 = localPlayer.PlayerGui.MainUI:FindFirstChild("StatusContainer") or statusContainer:Clone()
					statusContainer2.Parent = localPlayer.PlayerGui.MainUI
					local v45 = statusContainer2:FindFirstChild(name)

					if v45 then
						v45:Destroy()
					end

					local clone = statusDisplay:Clone()
					clone.Name = name
					clone.Title.Text = name
					clone.Timer.Text = fn25(arg2)
					clone.Visible = true
					clone.Parent = statusContainer2
					local n24 = tick() + arg2
					local connection4 = nil

					connection4 = RunService.Heartbeat:Connect(function()
						if not clone or not clone.Parent then
							connection4:Disconnect()
							return
						end
						local n25 = math.max(0, n24 - tick())
						clone.Timer.Text = fn25(n25)

						if n25 <= 0 then
							clone:Destroy()
							connection4:Disconnect()
						end
					end)

					return clone
				end

				local function fn33()
					if connection3 then
						connection3:Disconnect()
						connection3 = nil
					end

					local n24 = 10
					now2 = tick()
					flag12 = false
					fn26()
					fn23()
					local statusContainer2 = localPlayer.PlayerGui.MainUI:FindFirstChild("StatusContainer") or statusContainer:Clone()
					statusContainer2.Parent = localPlayer.PlayerGui.MainUI
					local speed2 = statusContainer2:FindFirstChild("Speed")

					if speed2 then
						speed2:Destroy()
					end

					local clone = statusDisplay:Clone()
					clone.Name = "Speed"
					clone.Title.Text = "Speed II"
					clone.Timer.Text = fn25(10)
					clone.Visible = true
					clone.Parent = statusContainer2
					v43 = clone
					fn28(2)
					local n25 = 2

					connection3 = RunService.Heartbeat:Connect(function()
						local n26 = tick() - now2
						local n27 = math.max(0, n24 - n26)

						if v43 and v43.Parent then
							v43.Timer.Text = fn25(n27)
						end

						fn27()
						if n27 <= 0 then
							fn30()
							return
						end

						if n26 < 5 then
							if n25 ~= 2 then
								fn28(2)
								n25 = 2
							end
						elseif n26 < 6.5 then
							if n25 ~= 1 then
								fn28(1)
								n25 = 1
							end
						elseif n26 < 9 then
							if n25 ~= 2 then
								fn28(2)
								n25 = 2
							end
						elseif not flag12 then
							flag12 = true
							n25 = nil
							fn29()
						end
					end)
				end

				local function fn34()
					if not humanoid then
						return
					end

					for _, v45 in pairs(humanoid:GetPlayingAnimationTracks()) do
						if v45.Animation and v45.Animation.AnimationId == str5 then
							if v45 == v42 then
								return
							end
							v42 = v45
							local v46 = flag10
							local v47

							if flag10 then
								v47 = v46
							else
								v47 = flag11
							end

							if v47 then
								fn32("Dude DON'T do this..", 1)

								task.delay(1, function()
									fn32("People may notice u (angry) Follow the tutorial", 3)
									fn31()
								end)

								return
							end

							flag11 = true
							local v48 = fn32("Wait!", 3.4)
							local connection4 = nil

							connection4 = v45.Stopped:Connect(function()
								if v48 then
									v48:Destroy()
								end

								fn30()

								if connection4 then
									connection4:Disconnect()
								end
							end)

							task.delay(3.4, function()
								if not v45.IsPlaying then
									if v48 then
										v48:Destroy()
									end

									fn30()

									if connection4 then
										connection4:Disconnect()
									end

									return
								end

								if v48 then
									v48:Destroy()
								end

								if connection4 then
									connection4:Disconnect()
								end

								fn31()
								flag11 = false
								flag10 = true
								fn33()
							end)
						end
					end
				end

				local function fn35()
					if connection2 then
						connection2:Disconnect()
					end

					connection2 = RunService.Heartbeat:Connect(function()
						if flag10 then
							fn27()
						end
					end)
				end

				local function fn36()
					if connection then
						connection:Disconnect()
						connection = nil
					end

					pcall(fn34)
					fn35()

					task.delay(1.5, function()
						if connection then
							return
						end

						connection = RunService.Heartbeat:Connect(function()
							if humanoid and humanoid.Parent then
								fn34()
							else
								fn30()
							end
						end)
					end)
				end

				local function fn37(character)
					humanoid = character:WaitForChild("Humanoid")
					fn30()
					fn36()
				end

				if localPlayer.Character then
					fn37(localPlayer.Character)
				end

				if v41 then
					v41:Disconnect()
				end

				local connection4 = localPlayer.CharacterAdded:Connect(fn37)

				return { Disconnect = function()
					if connection then
						connection:Disconnect()
						connection = nil
					end

					if connection4 then
						connection4:Disconnect()
						connection4 = nil
					end

					if connection2 then
						connection2:Disconnect()
						connection2 = nil
					end

					fn29()
					fn30()
				end }
			end

			v40 = fn22(getgenv().infBloxySettings)
		elseif v40 then
			pcall(function()
				v40:Disconnect()
			end)

			v40 = nil
		end
end


            items_tab:Toggle({
                Title = "inf bloxy cola",
                Desc = "be careful when using this, use at your own risk. this can get you banned if someone reports u",
                Value = false,
                Callback = function(val) startBloxy(val) end
            })
        end)
        if not okInf then warn("[forsaken8z] inf bloxy cola failed: " .. tostring(errInf)) end
    end

    items_tab:Section({ Title = "private server items" })
    do
        local okPriv, errPriv = pcall(function()
            local RS = game:GetService("RunService")
            local UI_PARENT = (gethui and gethui()) or game:GetService("CoreGui")
            local ITEMS = {
                WitchesBrew   = {Color3.fromRGB(0, 255, 0),     Color3.fromRGB(0, 90, 0)},
                SprayBottle   = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0)},
                Slateskin     = {Color3.fromRGB(128, 128, 128), Color3.fromRGB(128, 128, 128)},
                Glock         = {Color3.fromRGB(0, 0, 0),       Color3.fromRGB(0, 0, 0)},
                Ghostburger   = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(205, 205, 205)},
                Flashlight    = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0)},
                FakeMedkit    = {Color3.fromRGB(255, 0, 0),     Color3.fromRGB(255, 0, 0)},
                FakeBloxyCola = {Color3.fromRGB(255, 0, 0),     Color3.fromRGB(255, 0, 0)},
                Epicsauce     = {Color3.fromRGB(255, 0, 0),     Color3.fromRGB(255, 140, 0)},
                Broadsword    = {Color3.fromRGB(255, 120, 0),   Color3.fromRGB(255, 190, 110)},
                BloxyColaTest = {Color3.fromRGB(128, 128, 128), Color3.fromRGB(128, 128, 128)},
                Bloxiade      = {Color3.fromRGB(120, 200, 255), Color3.fromRGB(0, 60, 180)},
                AssaultRifle  = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(110, 110, 110)},
            }
            local ORDER = { "AssaultRifle", "Bloxiade", "BloxyColaTest", "Broadsword", "Epicsauce", "FakeBloxyCola",
                "FakeMedkit", "Flashlight", "Ghostburger", "Glock", "Slateskin", "SprayBottle", "WitchesBrew" }

            local function ingameFolder()
                local map = workspace:FindFirstChild("Map")
                return map and map:FindFirstChild("Ingame")
            end

            ------------------------------------------------------------------
            -- auto get items list: only items that exist (parent of Ingame.<item>.ItemRoot.ProximityPrompt)
            ------------------------------------------------------------------
            local function existingItems()
                local out, ingame = {}, ingameFolder()
                if not ingame then return out end
                for _, name in ipairs(ORDER) do
                    local item = ingame:FindFirstChild(name)
                    local root = item and item:FindFirstChild("ItemRoot")
                    if root and root:FindFirstChildWhichIsA("ProximityPrompt") then table.insert(out, name) end
                end
                return out
            end

            local itemList = existingItems()
            if #itemList == 0 then itemList = { "no items found" } end
            local selectedItems = {}

            local itemDropdown = items_tab:Dropdown({
                Title = "auto get items list",
                Desc = "only shows private server items that exist right now. pick some, then press the button below",
                Values = itemList,
                Value = {},
                Multi = true,
                AllowNone = true,
                Callback = function(selected)
                    selectedItems = {}
                    if type(selected) == "table" then
                        for _, v in pairs(selected) do
                            local label = type(v) == "table" and (v.Title or v.Name) or v
                            if type(label) == "string" then selectedItems[label] = true end
                        end
                    elseif type(selected) == "string" then
                        selectedItems[selected] = true
                    end
                end
            })

            task.spawn(function()
                local last = table.concat(itemList, "|")
                while ScriptRunning do
                    task.wait(3)
                    pcall(function()
                        local list = existingItems()
                        if #list == 0 then list = { "no items found" } end
                        local signature = table.concat(list, "|")
                        if signature ~= last then
                            last = signature
                            itemList = list
                            selectedItems = {}
                            RefreshDropdown(itemDropdown, list)
                        end
                    end)
                end
            end)

            local collecting = false
            local function collectItem(name)
                local ingame = ingameFolder()
                local item = ingame and ingame:FindFirstChild(name)
                local itemRoot = item and item:FindFirstChild("ItemRoot")
                local prompt = itemRoot and itemRoot:FindFirstChildWhichIsA("ProximityPrompt")
                local char = LP.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not (item and prompt and hrp) then return false end
                local original = hrp.CFrame
                local target = item:IsA("PVInstance") and item:GetPivot() or itemRoot.CFrame
                hrp.CFrame = target * CFrame.new(0, 3, 0)
                local startedAt = os.clock()
                repeat
                    pcall(function() prompt.HoldDuration = 0 end)
                    if fireproximityprompt then pcall(fireproximityprompt, prompt) end
                    task.wait(0.1)
                until os.clock() - startedAt >= 0.2
                local h = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if h then h.CFrame = original end
                return true
            end

            items_tab:Button({
                Title = "get selected items",
                Desc = "teleports to each selected item, fires its prompt every 0.1s for 0.2s, then teleports you back",
                Callback = function()
                    if collecting then return end
                    local names = {}
                    for _, name in ipairs(ORDER) do
                        if selectedItems[name] then table.insert(names, name) end
                    end
                    if #names == 0 then
                        windui:Notify({ Title = "private server items", Content = "select an item first", Duration = 3 })
                        return
                    end
                    collecting = true
                    task.spawn(function()
                        local got = 0
                        for _, name in ipairs(names) do
                            if pcall(collectItem, name) then got += 1 end
                            task.wait(0.2)
                        end
                        collecting = false
                        windui:Notify({ Title = "private server items", Content = "tried " .. got .. " item(s)", Duration = 3 })
                    end)
                end
            })

            ------------------------------------------------------------------
            -- items esp / items name esp (private server ones only)
            ------------------------------------------------------------------
            local FACES = { Enum.NormalId.Top, Enum.NormalId.Bottom, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }
            local painted = setmetatable({}, { __mode = "k" })
            local highlights = setmetatable({}, { __mode = "k" })
            local nameTags = setmetatable({}, { __mode = "k" })
            local espObjects, nameObjects, gradients = {}, {}, {}

            local function brightness(c) return (c.R + c.G + c.B) / 3 end

            local function paintPart(part, c1, c2)
                local guis = {}
                for _, face in ipairs(FACES) do
                    local sg = Instance.new("SurfaceGui")
                    sg.Name = "GradESP"
                    sg.Adornee = part
                    sg.Face = face
                    sg.AlwaysOnTop = true
                    sg.LightInfluence = 0
                    sg.ResetOnSpawn = false
                    sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
                    sg.PixelsPerStud = 50
                    local frame = Instance.new("Frame")
                    frame.Size = UDim2.fromScale(1, 1)
                    frame.BackgroundColor3 = Color3.new(1, 1, 1)
                    frame.BackgroundTransparency = 0.25
                    frame.BorderSizePixel = 0
                    frame.Parent = sg
                    local grad = Instance.new("UIGradient")
                    grad.Color = ColorSequence.new(c1, c2)
                    grad.Rotation = 90
                    grad.Parent = frame
                    table.insert(gradients, grad)
                    sg.Parent = UI_PARENT
                    table.insert(guis, sg)
                    table.insert(espObjects, sg)
                end
                painted[part] = guis
            end

            local function isPainted(part)
                local guis = painted[part]
                return guis and guis[1] and guis[1].Parent ~= nil and part:IsDescendantOf(workspace)
            end

            local function highlightItem(item, c1)
                local h = highlights[item]
                if h and h.Parent then return end
                h = Instance.new("Highlight")
                h.Adornee = item
                h.FillTransparency = 1
                h.OutlineTransparency = 0
                h.OutlineColor = c1
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent = UI_PARENT
                highlights[item] = h
                table.insert(espObjects, h)
            end

            local function getAdornee(item)
                if item:IsA("BasePart") then return item end
                if item:IsA("Model") and item.PrimaryPart then return item.PrimaryPart end
                local handle = item:FindFirstChild("Handle", true)
                if handle and handle:IsA("BasePart") then return handle end
                return item:FindFirstChildWhichIsA("BasePart", true)
            end

            local function nameTag(item, name, c1, c2)
                local existing = nameTags[item]
                if existing and existing.Parent and existing.Adornee and existing.Adornee:IsDescendantOf(workspace) then return end
                if existing then existing:Destroy() end
                local adornee = getAdornee(item)
                if not adornee then return end
                local bb = Instance.new("BillboardGui")
                bb.Name = "GradName"
                bb.Adornee = adornee
                bb.AlwaysOnTop = true
                bb.Size = UDim2.fromOffset(200, 20)
                bb.StudsOffset = Vector3.new(0, 2, 0)
                bb.ResetOnSpawn = false
                local label = Instance.new("TextLabel")
                label.Size = UDim2.fromScale(1, 1)
                label.BackgroundTransparency = 1
                label.Text = name
                label.Font = Enum.Font.Gotham
                label.TextSize = 14
                label.TextColor3 = Color3.new(1, 1, 1)
                label.Parent = bb
                local stroke = Instance.new("UIStroke")
                stroke.Thickness = 1
                stroke.Color = (brightness(c1) + brightness(c2)) / 2 < 0.35 and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
                stroke.Parent = label
                local grad = Instance.new("UIGradient")
                grad.Color = ColorSequence.new(c1, c2)
                grad.Rotation = 0
                grad.Parent = label
                table.insert(gradients, grad)
                bb.Parent = UI_PARENT
                nameTags[item] = bb
                table.insert(nameObjects, bb)
            end

            local function clearObjects(list)
                for _, obj in ipairs(list) do pcall(function() obj:Destroy() end) end
                table.clear(list)
            end

            local espWasOn, namesWereOn = false, false
            task.spawn(function()
                while ScriptRunning do
                    pcall(function()
                        local ingame = ingameFolder()
                        if State.PrivateItemEsp and ingame then
                            espWasOn = true
                            for name, cols in pairs(ITEMS) do
                                local item = ingame:FindFirstChild(name)
                                if item then
                                    highlightItem(item, cols[1])
                                    local parts = {}
                                    if item:IsA("BasePart") then table.insert(parts, item) end
                                    for _, d in ipairs(item:GetDescendants()) do
                                        if d:IsA("BasePart") then table.insert(parts, d) end
                                    end
                                    for _, part in ipairs(parts) do
                                        if not isPainted(part) then paintPart(part, cols[1], cols[2]) end
                                    end
                                end
                            end
                        elseif espWasOn and not State.PrivateItemEsp then
                            espWasOn = false
                            clearObjects(espObjects)
                        end
                        if State.PrivateItemNameEsp and ingame then
                            namesWereOn = true
                            for name, cols in pairs(ITEMS) do
                                local item = ingame:FindFirstChild(name)
                                if item then nameTag(item, name, cols[1], cols[2]) end
                            end
                        elseif namesWereOn and not State.PrivateItemNameEsp then
                            namesWereOn = false
                            clearObjects(nameObjects)
                        end
                    end)
                    task.wait(1)
                end
                clearObjects(espObjects)
                clearObjects(nameObjects)
            end)

            -- slow gradient shimmer (parts and name text)
            RS.RenderStepped:Connect(function()
                if #gradients == 0 then return end
                local r = (tick() * 45) % 360
                for i = #gradients, 1, -1 do
                    local g = gradients[i]
                    if g.Parent then g.Rotation = r else table.remove(gradients, i) end
                end
            end)

            items_tab:Toggle({
                Title = "items esp (private server ones only)",
                Desc = "only esps things like firebrand, glock, and etc (this doesnt esp items you can get normally in public servers)",
                Value = State.PrivateItemEsp,
                Callback = function(val) State.PrivateItemEsp = val end
            })
            items_tab:Toggle({
                Title = "items name esp (private server ones only)",
                Value = State.PrivateItemNameEsp,
                Callback = function(val) State.PrivateItemNameEsp = val end
            })
        end)
        if not okPriv then warn("[forsaken8z] private server items failed: " .. tostring(errPriv)) end
    end

    -- Antis (added to the effects tab)
    effects_tab:Section({ Title = "movement antis" })
    effects_tab:Toggle({ Title = "anti fall slowness", Desc = "removes the slowdown after falling", Value = State.AntiFallSlowness, Callback = Extras.SetAntiFallSlowness })
    effects_tab:Toggle({ Title = "disable directional speed", Desc = "no speed change when walking backwards/sideways", Value = State.DisableDirectionalSpeed, Callback = Extras.SetDirectionalSpeedDisabled })
    effects_tab:Toggle({ Title = "disable directional movement", Desc = "", Value = State.DisableDirectionalMovement, Callback = Extras.SetDirectionalMovementDisabled })
    effects_tab:Toggle({ Title = "anti pull", Desc = "bloodhook, void star and azure tentacles", Value = State.AntiPull, Callback = Extras.SetAntiPull })
    effects_tab:Toggle({ Title = "walkable john doe and nosferatu puddles", Desc = "puddles can no longer touch you", Value = State.WalkablePuddles, Callback = Extras.SetWalkablePuddles })

    effects_tab:Section({ Title = "more debuff antis" })
    local statusAntiTitles = {
        AntiBleeding = "anti bleeding (low hp)",
        AntiHallucination = "anti hallucination (noli)",
        AntiHacked = "anti hacked (1x1x1x1)",
        AntiCorrupted = "anti corrupted (john doe)",
        AntiSubspaced = "anti subspaced (taph)",
    }
    for _, anti in ipairs(Extras.StatusAntis) do
        effects_tab:Toggle({
            Title = statusAntiTitles[anti.Key],
            Desc = "",
            Value = State[anti.Key],
            Callback = function(val)
                State[anti.Key] = val
                if val then Extras.BlockStatusEffect(anti.Effect, anti.Key) end
            end
        })
    end

    -- Misc tab
    local misc_tab = window:Tab({ Title = "misc", Icon = "wrench" })

    do
        local okMisc, errMisc = pcall(function()
            local RS = game:GetService("RunService")
            local RepStorage = game:GetService("ReplicatedStorage")

            -- device spoofer
            local deviceHooked = false
            misc_tab:Dropdown({
                Title = "device spoofer",
                Desc = "client sided, (i think) this spoofs your device on forsakens profile feature",
                Values = { "PC", "Mobile", "Console" },
                Callback = function(option)
                    if type(option) == "table" then option = option.Title or option[1] end
                    if type(option) ~= "string" then return end
                    State.DeviceSpoof = option
                    if deviceHooked then return end
                    if type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" then
                        windui:Notify({ Title = "device spoofer", Content = "your executor doesnt support hookmetamethod", Duration = 4 })
                        return
                    end
                    deviceHooked = true
                    local old
                    local function handler(self, ...)
                        if State.DeviceSpoof and self == LP and getnamecallmethod() == "GetAttribute" and (...) == "Device" then
                            return State.DeviceSpoof
                        end
                        return old(self, ...)
                    end
                    old = hookmetamethod(game, "__namecall", type(newcclosure) == "function" and newcclosure(handler) or handler)
                end
            })

            ------------------------------------------------------------------
            misc_tab:Section({ Title = "hitboxes" })

            -- hitbox pusher (spoofs your replicated position by your ping while you move) - creds to catsaken script owner
            local pusherInstalled = false
            local function installPusher()
                if pusherInstalled then return end
                pusherInstalled = true
                task.spawn(function()
                    local ok, err = pcall(function()
                        local env = (type(getgenv) == "function" and getgenv()) or _G
                        env.ForsakenSpoof = { Enabled = true, MaxOffset = 4, PingDivisor = 1400 }
                        local folder = RepStorage:WaitForChild("Systems", 10):WaitForChild("Player", 10):WaitForChild("Game", 10)
                        local module = require(folder:WaitForChild("CharacterReplication", 10))
                        if not env.OldSerialize then env.OldSerialize = module.Serialize end
                        function module.Serialize(p1, p2)
                            if not State.HitboxPusher then return env.OldSerialize(p1, p2) end
                            local Character = LP.Character
                            local PrimaryPart = Character and Character.PrimaryPart
                            local humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
                            if not (PrimaryPart and humanoid and (p1.Position - PrimaryPart.Position).Magnitude < 15) then
                                return env.OldSerialize(p1, p2)
                            end
                            local MoveDirection = humanoid.MoveDirection
                            if MoveDirection.Magnitude <= 0.1 then return env.OldSerialize(p1, p2) end
                            local speed = math.max(PrimaryPart.AssemblyLinearVelocity.Magnitude, humanoid.WalkSpeed)
                            local offset = math.min(speed * (LP:GetNetworkPing() * 1000) / env.ForsakenSpoof.PingDivisor, env.ForsakenSpoof.MaxOffset)
                            local flatDirection = Vector3.new(MoveDirection.X, 0, MoveDirection.Z)
                            if flatDirection.Magnitude <= 0 then return env.OldSerialize(p1, p2) end
                            return env.OldSerialize(p1 + flatDirection.Unit * offset, p2)
                        end
                    end)
                    if not ok then
                        pusherInstalled = false
                        warn("[forsaken8z] hitbox pusher failed: " .. tostring(err))
                    end
                end)
            end
            misc_tab:Toggle({
                Title = "hitbox pusher (makes your hitbox as accurate as possible by spoofing your ping when your lagging)",
                Desc = "creds to catsaken script owner",
                Value = State.HitboxPusher,
                Callback = function(val)
                    State.HitboxPusher = val
                    if val then installPusher() end
                end
            })

            -- hitbox expander - creds to catsaken
            local EXP_RANGE, EXPAND_MODE, TARGET_MODE, AUTO_ROTATE, HITBOX_DURATION = 15, "Dynamic", "Facing", true, 0.36
            local function expKillerGroup()
                local players = workspace:FindFirstChild("Players")
                return players and players:FindFirstChild("Killers"), players and players:FindFirstChild("Survivors")
            end
            local function isKillerChar()
                local killers = expKillerGroup()
                return LP.Character ~= nil and killers ~= nil and LP.Character.Parent == killers
            end
            local function scanTargets(rootPart, range, mode)
                local bestTarget, bestScore = nil, math.huge
                local lookVector = rootPart.CFrame.LookVector
                local killers, survivors = expKillerGroup()
                local group = (isKillerChar() and survivors or killers)
                if not group then return nil end
                for _, char in ipairs(group:GetChildren()) do
                    if char ~= LP.Character then
                        local hrp, hum = char:FindFirstChild("HumanoidRootPart"), char:FindFirstChild("Humanoid")
                        if hrp and hum and hum.Health > 0 then
                            local diff = hrp.Position - rootPart.Position
                            local dist = diff.Magnitude
                            if dist > 0 and dist <= range then
                                local score
                                if mode == "Facing" then score = -lookVector:Dot(diff.Unit)
                                elseif mode == "Nearest" then score = dist
                                else score = hum.Health end
                                if score < bestScore then bestScore, bestTarget = score, char end
                            end
                        end
                    end
                end
                return bestTarget
            end
            local function onExpanderAnimation(track)
                if not State.HitboxExpander then return end
                local char = LP.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                if tostring(char) ~= "Shedletsky" and not isKillerChar() then return end
                local startTime, lastAngle, animLength = tick(), 0, track.Length
                local connection
                connection = RS.Heartbeat:Connect(function()
                    if not char.Parent or tick() - startTime > animLength or not State.HitboxExpander then
                        connection:Disconnect()
                        return
                    end
                    local elapsed = tick() - startTime
                    local windup = 0.1
                    if elapsed < windup or elapsed > windup + HITBOX_DURATION then
                        local jitter = math.atan((math.random() * 2 - 1) * 0.02)
                        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, jitter - lastAngle, 0)
                        lastAngle = jitter
                        return
                    end
                    local fov = char:FindFirstChild("FOVMultipliers")
                    if fov and fov:FindFirstChild("HitRegistered") then return end
                    local target = scanTargets(hrp, EXP_RANGE, TARGET_MODE)
                    local offsetZ, sizeZ = 4, 8
                    local originalCFrame = hrp.CFrame
                    local progress = (elapsed - windup) / HITBOX_DURATION
                    local newCFrame
                    if EXPAND_MODE == "Dynamic" and target and target:FindFirstChild("QueryHitbox") then
                        local queryCFrame = target.QueryHitbox.CFrame
                        local velocity = target.Humanoid:GetMoveVelocity() / 3.5
                        if AUTO_ROTATE then
                            newCFrame = queryCFrame + velocity - queryCFrame.LookVector * (offsetZ / 2)
                        else
                            newCFrame = CFrame.new(queryCFrame.Position + velocity) * originalCFrame.Rotation
                        end
                    else
                        local push = (EXP_RANGE / sizeZ) * progress * sizeZ
                        newCFrame = originalCFrame + (originalCFrame.LookVector * push)
                    end
                    hrp.CFrame = newCFrame
                    local restore
                    restore = RS.RenderStepped:Connect(function()
                        restore:Disconnect()
                        local jitter = math.atan((math.random() * 2 - 1) * 0.02)
                        hrp.CFrame = originalCFrame * CFrame.Angles(0, jitter - lastAngle, 0)
                        lastAngle = jitter
                    end)
                end)
            end
            local expanderAnimConn, expanderCharConn
            local function hookExpanderCharacter(char)
                if expanderAnimConn then expanderAnimConn:Disconnect() expanderAnimConn = nil end
                local humanoid = char and char:WaitForChild("Humanoid", 5)
                local animator = humanoid and humanoid:WaitForChild("Animator", 5)
                if animator then expanderAnimConn = animator.AnimationPlayed:Connect(onExpanderAnimation) end
            end
            misc_tab:Toggle({
                Title = "hitbox expander",
                Desc = "creds to catsaken (thx)",
                Value = State.HitboxExpander,
                Callback = function(val)
                    State.HitboxExpander = val
                    if expanderAnimConn then expanderAnimConn:Disconnect() expanderAnimConn = nil end
                    if expanderCharConn then expanderCharConn:Disconnect() expanderCharConn = nil end
                    if val then
                        task.spawn(hookExpanderCharacter, LP.Character)
                        expanderCharConn = LP.CharacterAdded:Connect(function(char) task.spawn(hookExpanderCharacter, char) end)
                    end
                end
            })
        end)
        if not okMisc then warn("[forsaken8z] misc features failed: " .. tostring(errMisc)) end
    end

    misc_tab:Section({ Title = "gameplay" })
    misc_tab:Toggle({ Title = "auto close end game screen", Desc = "", Value = State.AutoCloseEndScreen, Callback = Extras.SetAutoCloseEndScreen })
    misc_tab:Toggle({ Title = "disable afk insanity", Desc = "", Value = State.DisableAFKInsanity, Callback = Extras.SetDisableAFKInsanity })
    misc_tab:Toggle({ Title = "turn on chat", Desc = "keeps the chat window enabled", Value = false, Callback = Extras.SetChatAlwaysOn })
    misc_tab:Toggle({ Title = "enable sidebar visibility", Desc = "", Value = State.SidebarVisible, Callback = Extras.SetSidebarVisible })

    misc_tab:Section({ Title = "camera" })
    misc_tab:Toggle({ Title = "infinite zoom + noclip camera", Desc = "zoom out forever and the camera ignores walls", Value = false, Callback = Extras.SetInfiniteZoom })
    misc_tab:Toggle({ Title = "enable custom fov", Desc = "", Value = false, Callback = Extras.SetCustomFOV })
    misc_tab:Slider({
        Title = "fov multiplier",
        Desc = "",
        Value = { Min = 0.5, Max = 3, Default = State.CustomFOVMultiplier, Step = 0.1 },
        Callback = function(val) State.CustomFOVMultiplier = val end
    })

    misc_tab:Section({ Title = "movement" })
    misc_tab:Toggle({ Title = "anti footsteps", Desc = "silently walk/run", Value = State.AntiFootsteps, Callback = Extras.SetAntiFootsteps })
    misc_tab:Toggle({ Title = "noclip", Desc = "", Value = State.Noclip, Callback = Extras.SetNoclip })
    misc_tab:Toggle({ Title = "fake injured", Desc = "", Value = false, Callback = Extras.SetFakeInjured })
    misc_tab:Toggle({ Title = "fake clone", Desc = "plays the clone run animation while you move", Value = State.FakeClone, Callback = Extras.SetFakeClone })

    misc_tab:Section({ Title = "round timer" })
    misc_tab:Dropdown({
        Title = "timer position",
        Values = { "Left", "Middle", "Right" },
        Value = "Middle",
        Callback = Extras.SetTimerPosition
    })

    misc_tab:Section({ Title = "character and servers" })
    misc_tab:Button({ Title = "turn on jump", Desc = "", Callback = Extras.TurnOnJump })
    misc_tab:Button({ Title = "reset", Desc = "", Callback = Extras.ResetCharacter })
    misc_tab:Button({ Title = "rejoin", Desc = "", Callback = Extras.Rejoin })

    -- Visuals (ESP) Tab
    esp_tab:Toggle({ Title = "esp killer", Desc = "highlights killer", Value = State.KillerESP, Callback = function(val) State.KillerESP = val end })
    esp_tab:Toggle({ Title = "esp survivor", Desc = "highlights survivor", Value = State.SurvivorESP, Callback = function(val) State.SurvivorESP = val end })
    esp_tab:Toggle({ Title = "esp generator", Desc = "highlights unfinished generators", Value = State.GeneratorESP, Callback = function(val) State.GeneratorESP = val end })
    esp_tab:Toggle({ Title = "esp fake generator", Desc = "Highlights fake/trap generators orange", Value = State.FakeGeneratorESP, Callback = function(val) State.FakeGeneratorESP = val end })
    esp_tab:Toggle({ Title = "esp two time spawnpoint", Desc = "hightlights two times ritual", Value = State.RitualESP, Callback = function(val) State.RitualESP = val end })
    esp_tab:Toggle({ Title = "esp minions", Desc = "hightlights coolkidd and 1x1 minions", Value = State.CoolkiddMinionESP, Callback = function(val) State.CoolkiddMinionESP = val; State.OneByOneMinionESP = val end })
    esp_tab:Toggle({ Title = "esp azures bulb", Desc = "hightlights azures bulb", Value = State.AzureBulbESP, Callback = function(val) State.AzureBulbESP = val end })
    esp_tab:Toggle({ Title = "esp azures vine", Desc = "hightlights azures vines", Value = State.AzureVineESP, Callback = function(val) State.AzureVineESP = val end })
    esp_tab:Toggle({ Title = "esp taphs tripwire", Desc = "highlights taphs tripwires", Value = State.TaphTripwireESP, Callback = function(val) State.TaphTripwireESP = val end })
    esp_tab:Toggle({ Title = "esp taphs subspace tripmine", Desc = "highlights taphs tripmines", Value = State.SubspaceTripmineESP, Callback = function(val) State.SubspaceTripmineESP = val end })
    esp_tab:Toggle({ Title = "esp veeronicas grafitti", Desc = "highlights vees graffiti(s) as pink", Value = State.VeeronicaGraffitiESP, Callback = function(val) State.VeeronicaGraffitiESP = val end })
    esp_tab:Toggle({ Title = "esp builderman sentries", Desc = "highlights builderman sentry gray", Value = State.EspBuildermanSentries, Callback = function(val) State.EspBuildermanSentries = val end })
    esp_tab:Toggle({ Title = "esp builderman dispensers", Desc = "highlights builderman dispenser pink", Value = State.EspBuildermanDispensers, Callback = function(val) State.EspBuildermanDispensers = val end })
    esp_tab:Toggle({ Title = "esp 007n7 clones", Value = State.Esp007n7Clones, Callback = function(val) State.Esp007n7Clones = val end })
    esp_tab:Toggle({ Title = "esp fake noli", Value = State.EspFakeNoli, Callback = function(val) State.EspFakeNoli = val end })
    esp_tab:Toggle({ Title = "esp gears", Value = State.EspGears, Callback = function(val) State.EspGears = val end })
    esp_tab:Toggle({ Title = "gear(s) name esp", Value = State.GearNameESP, Callback = function(val) State.GearNameESP = val end })
    esp_tab:Toggle({ 
        Title = "esp john does df", 
        Desc = "highlights digital footprints ad dark red", 
        Value = State.EspJohnDoesDF, 
        Callback = function(val) 
            State.EspJohnDoesDF = val 
        end 
    })

    esp_tab:Toggle({
        Title = "candy esp (halloween currency)",
        Value = State.EspCandies,
        Callback = function(val) State.EspCandies = val end
    })
    esp_tab:Toggle({
        Title = "esp fruits",
        Desc = "highlights everything in OrangeFruits green",
        Value = State.EspFruits,
        Callback = function(val) State.EspFruits = val end
    })

    -- ESP Names Tab
    esp_names_tab:Toggle({ Title = "killer name esp", Desc = "displays killer names", Value = State.KillerNameESP, Callback = function(val) State.KillerNameESP = val end })
    esp_names_tab:Toggle({ Title = "survivor name esp", Desc = "displags survivor names", Value = State.SurvivorNameESP, Callback = function(val) State.SurvivorNameESP = val end })
    esp_names_tab:Toggle({ Title = "generator name esp", Desc = "displays generator names", Value = State.GenNameESP, Callback = function(val) State.GenNameESP = val end })
    esp_names_tab:Toggle({ Title = "item name esp", Desc = "displays item names", Value = State.ItemNameESP, Callback = function(val) State.ItemNameESP = val end })
    esp_names_tab:Toggle({ Title = "spawnpoint name esp", Desc = "displays two times spawnpoint names", Value = State.RitualNameESP, Callback = function(val) State.RitualNameESP = val end })
    esp_names_tab:Toggle({ Title = "minion name esp", Desc = "displays minion names", Value = State.MinionNameESP, Callback = function(val) State.MinionNameESP = val end })
    esp_names_tab:Toggle({ Title = "azures bulb name esp", Desc = "displays azures bulbs names", Value = State.AzureBulbNameESP, Callback = function(val) State.AzureBulbNameESP = val end })
    esp_names_tab:Toggle({ Title = "azures vine name esp", Desc = "displays azures vine names", Value = State.AzureVineNameESP, Callback = function(val) State.AzureVineNameESP = val end })
    esp_names_tab:Toggle({ Title = "taphs tripwire name esp", Desc = "displays taphs tripwire names", Value = State.TripwireNameESP, Callback = function(val) State.TripwireNameESP = val end })
    esp_names_tab:Toggle({ Title = "subspace tripmine name esp", Desc = "displays taphs tripwire names", Value = State.SubspaceNameESP, Callback = function(val) State.SubspaceNameESP = val end })
    esp_names_tab:Toggle({ Title = "esp veeronicas grafitti name", Desc = "highlights vees graffiti(s) as pink", Value = State.VeeronicaGraffitiNameESP, Callback = function(val) State.VeeronicaGraffitiNameESP = val end })
    esp_names_tab:Toggle({ Title = "sentries name esp", Desc = "displays Sentry name in gray", Value = State.SentriesNameESP, Callback = function(val) State.SentriesNameESP = val end })
    esp_names_tab:Toggle({ Title = "dispensers name esp", Desc = "displays Dispenser name in pink", Value = State.DispensersNameESP, Callback = function(val) State.DispensersNameESP = val end })
    esp_names_tab:Toggle({ Title = "fake 007n7 name esp", Value = State.Fake007n7NameESP, Callback = function(val) State.Fake007n7NameESP = val end })
    esp_names_tab:Toggle({ Title = "fake noli name esp", Value = State.FakeNoliNameESP, Callback = function(val) State.FakeNoliNameESP = val end })
    esp_names_tab:Toggle({ Title = "john does df name esp", Value = State.JohnDoesDFNameESP, Callback = function(val) State.JohnDoesDFNameESP = val end })

    esp_names_tab:Toggle({
        Title = "candy name esp",
        Value = State.CandyNameESP,
        Callback = function(val) State.CandyNameESP = val end
    })
    esp_names_tab:Toggle({
        Title = "fruits name esp",
        Desc = "displays the name of every fruit",
        Value = State.FruitNameESP,
        Callback = function(val) State.FruitNameESP = val end
    })

    -- Players Tab
    players_tab:Button({
        Title = "view who has the most playtime",
        Desc = "notifies a players highest playtime",
        Callback = function()
            local topPlayer = "None"
            local topTime = -1
            for _, p in ipairs(Players:GetPlayers()) do
                pcall(function()
                    local timeVal = p.PlayerData.Stats.General.TimePlayed.Value
                    if timeVal and timeVal > topTime then
                        topTime = timeVal
                        topPlayer = p.DisplayName .. " (@" .. p.Name .. ")"
                    end
                end)
            end
            if topTime >= 0 then
                local timeString = FormatPlaytime(topTime)
                windui:Notify({ Title = "most playtime", Content = topPlayer .. " has " .. timeString .. " played", Duration = 6 })
            else
                windui:Notify({ Title = "most playtime", Content = "error", Duration = 5 })
            end
        end
    })

    players_tab:Button({
        Title = "view the highest malice",
        Desc = "notifies a players highest malice.",
        Callback = function()
            local topPlayer = "None"
            local topChance = -1
            for _, p in ipairs(Players:GetPlayers()) do
                pcall(function()
                    local chanceVal = p.leaderstats.KillerChance.Value
                    if chanceVal and chanceVal > topChance then
                        topChance = chanceVal
                        topPlayer = p.DisplayName .. " (@" .. p.Name .. ")"
                    end
                end)
            end
            if topChance >= 0 then
                windui:Notify({ Title = "highest malice", Content = topPlayer .. " has " .. tostring(topChance) .. " killer chance", Duration = 6 })
            else
                windui:Notify({ Title = "highest malice", Content = "error", Duration = 5 })
            end
        end
    })

    -- Killer ESP Ability Notifier Watcher Loop
    task.spawn(function()
        while ScriptRunning do
            task.wait(0.2)
            if State.AutoNotifyKillerESP then
                pcall(function()
                    local killersFolder = Workspace:FindFirstChild("Players") and Workspace.Players:FindFirstChild("Killers")
                    if killersFolder then
                        local k1x1 = killersFolder:FindFirstChild("1x1x1x1")
                        if k1x1 and k1x1:FindFirstChild("FOVMultipliers") and k1x1.FOVMultipliers:FindFirstChild("UnstableEye") then
                            windui:Notify({ Title = "Killer ESP Alert", Content = "killer esp used!!!", Duration = 3 })
                            task.wait(4)
                        end
                        local kSlasher = killersFolder:FindFirstChild("Slasher")
                        if kSlasher and kSlasher:FindFirstChild("SpeedMultipliers") and kSlasher.SpeedMultipliers:FindFirstChild("ENRAGED") then
                            windui:Notify({ Title = "Killer ESP Alert", Content = "killer esp used!!!", Duration = 3 })
                            task.wait(4)
                        end
                        local kNos = killersFolder:FindFirstChild("Nosferatu")
                        if kNos and kNos:FindFirstChild("SpeedMultipliers") and kNos.SpeedMultipliers:FindFirstChild("NosFlying") then
                            windui:Notify({ Title = "Killer ESP Alert", Content = "killer esp used!!!", Duration = 3 })
                            task.wait(4)
                        end
                        local kNoli = killersFolder:FindFirstChild("Noli")
                        if kNoli and kNoli:FindFirstChild("SpeedMultipliers") and kNoli.SpeedMultipliers:FindFirstChild("ObservantTeleporting") then
                            windui:Notify({ Title = "Killer ESP Alert", Content = "killer esp used!!!", Duration = 3 })
                            task.wait(4)
                        end
                        local kJohn = killersFolder:FindFirstChild("JohnDoe") or killersFolder:FindFirstChild("John Doe")
                        if kJohn and kJohn:FindFirstChild("FOVMultipliers") and kJohn.FOVMultipliers:FindFirstChild("404Error") then
                            windui:Notify({ Title = "Killer ESP Alert", Content = "killer esp used!!!", Duration = 3 })
                            task.wait(4)
                        end
                    end
                end)
            end
        end
    end)

    -- Settings Tab (With Theme Picker)
    settings_tab:Dropdown({
        Title = "theme picker",
        Desc = "picks a color for the menu",
        Values = { "Dark", "Light", "Rose", "Aqua", "Emerald", "Midnight", "Catppuccin", "Ruby", "Amber" },
        Value = "Dark",
        Callback = function(theme)
            pcall(function()
                if window and window.SetTheme then
                    window:SetTheme(theme)
                elseif windui and windui.SetTheme then
                    windui:SetTheme(theme)
                end
            end)
        end
    })

    settings_tab:Button({
        Title = "destroy script",
        Desc = "closes the script and disables all features",
        Callback = function()
            ScriptRunning = false
            pcall(function()
                local e = (type(getgenv) == "function" and getgenv()) or _G
                if e.ForsakenAutopilot then e.ForsakenAutopilot:Destroy() end
            end)
            for _, conn in ipairs(Connections) do pcall(function() conn:Disconnect() end) end
            pcall(function() window:Destroy() end)
        end
    })

    pcall(function()
        if loadingGui then
            loadingGui:Destroy()
        end
    end)

    windui:Notify({ Title = "forsaken", Content = "script loaded and updated successfully, nya~! 🐾", Duration = 5 })
end

-- Key System Flow
if IsKeySaved() then
    LoadMainScript()
else
    pcall(function() if loadingGui then loadingGui:Destroy() end end)

    local keyWindow = windui:CreateWindow({
        Title = "key system",
        Icon = "key",
        Author = "xane",
        Folder = "forsaken_plus_delta"
    })
    
    local keyTab = keyWindow:Tab({ Title = "key verification", Icon = "lock" })
    local enteredKey = ""

    keyTab:Input({
        Title = "enter key",
        Desc = "paste key here",
        Value = "",
        Placeholder = "enter key...",
        Callback = function(val)
            enteredKey = val
        end
    })

    keyTab:Button({
        Title = "submit key",
        Desc = "submits the key",
        Callback = function()
            if enteredKey == CORRECT_KEY then
                SaveKey(enteredKey)
                windui:Notify({ Title = "key verified", Content = "execute the script again", Duration = 3 })
                task.wait(0.5)
                pcall(function() keyWindow:Destroy() end)
                LoadMainScript()
            else
                windui:Notify({ Title = "invalid key", Content = "incorrect key, try again.", Duration = 4 })
            end
        end
    })

    keyTab:Button({
        Title = "copy discord server link",
        Desc = "copies invite: " .. DISCORD_URL,
        Callback = function()
            if setclipboard then
                pcall(function() setclipboard(DISCORD_URL) end)
                windui:Notify({ Title = "clipboard", Content = "discord link copied!", Duration = 3 })
            end
        end
    })
end

end, function(err)
    warn("Error: " .. tostring(err))
end)
