--// i fixed it - luna <3 //
--// FLEX SAKEN v1.1 - By Ethan and Luna //
--// Elliot, Veeronica, Auto Generator, Animations, Music, Chance, Nova, Dusekkar, Candy ESP, Jane Doe, Backstab, G1337 Auto Block //

--// Wait for game to reach minimum distributed time, with a generous cap //
local _waitStart = os.clock()
while workspace.DistributedGameTime < 4 and os.clock() - _waitStart < 15 do
    task.wait(0.5)
end

local CoreGui = game:GetService("CoreGui")

--// Clean up any leftover instance from a previous run //
local existing = CoreGui:FindFirstChild("FlexSaken")
if existing then
    existing:Destroy()
    --// Remove leftover GUIs from the previous run //
    local PlayerGui = game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if PlayerGui then
        for _, v in ipairs(PlayerGui:GetChildren()) do
            if v.Name == "PingDisplay" or v.Name == "FlexSakenSparkles" then
                v:Destroy()
            end
        end
    end
    --// Remove leftover WindUI window if present //
    for _, v in ipairs(CoreGui:GetChildren()) do
        if v.Name == "WindUI" or v.Name == "FlexSaken_UI" then
            v:Destroy()
        end
    end
    task.wait(0.2)
end

--// Wait up to 3 s for the correct game ID or ServerType attribute to appear //
--// (handles cases where the game hasn't fully replicated yet at inject time) //
do
    local _gidStart = os.clock()
    while not (game.GameId == 6331902150 or game.GameId == 7464167604 or workspace:GetAttribute("ServerType")) do
        if os.clock() - _gidStart > 3 then
            warn("[FlexSaken] Game ID check timed out — loading anyway (features may be limited)")
            break
        end
        task.wait(0.25)
    end
end

pcall(function() Instance.new("BoolValue", CoreGui).Name = "FlexSaken" end)

--// SERVICES //

local Players          = game:GetService("Players")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local Lighting         = game:GetService("Lighting")
local TextChatService  = game:GetService("TextChatService")
local TeleportService  = game:GetService("TeleportService")
local SoundService     = game:GetService("SoundService")
local Stats            = game:GetService("Stats")
local Workspace        = workspace

local LocalPlayer = Players.LocalPlayer

--// EXECUTOR COMPATIBILITY SHIM //
--// Supported PC      : Opiumware, Volcano, Real, Potassium, Volt, Wave (macOS) //
--// Supported Mobile  : Delta (Android/iOS), Codex (Android) //
--//
--// API surface per executor (UNC = standard names, alt = alternate name exposed) //
--//  Opiumware  : UNC + hookfunction + debug.getupvalues/setupvalue/info + getconnections //
--//  Volcano    : UNC + hookfunction + debug.* + getconnections + getcustomasset //
--//  Real       : UNC + hookfunction + debug.* + getconnections //
--//  Potassium  : UNC + hookfunction + debug.* + getconnections + getcustomasset //
--//  Volt       : UNC + hookfunction + debug.* + getconnections //
--//  Wave (mac) : UNC + hookfunction + debug.* + getconnections; http via request() //
--//  Delta      : UNC + replaceclosure + debug.* + getconnections; toclipboard alias //
--//  Codex      : UNC + hookfunction + debug.* + getconnections //

do
    --// ── Detect executor ── //
    local execName = ""
    for _, fn in ipairs({ getexecutorname, identifyexecutor }) do
        if typeof(fn) == "function" then
            local ok, n = pcall(fn)
            if ok and type(n) == "string" and n ~= "" then execName = n:lower(); break end
        end
    end
    local isWave     = execName:find("wave")     ~= nil
    local isDelta    = execName:find("delta")    ~= nil
    local isCodex    = execName:find("codex")    ~= nil
    local isVolt     = execName:find("volt")     ~= nil
    local isPotassium= execName:find("potassium")~= nil
    local isReal     = execName:find("real")     ~= nil
    local isVolcano  = execName:find("volcano")  ~= nil
    local isOpium    = execName:find("opium")    ~= nil

    --// ── gethui ── //
    --// All executors: CoreGui fallback if gethui missing //
    if typeof(gethui) ~= "function" then
        gethui = function() return game:GetService("CoreGui") end
    end

    --// ── File I/O ── //
    --// Standard: readfile, writefile, isfile, isfolder, makefolder, appendfile, deletefile //
    --// Alternate names some executors use:                                                 //
    --//   read_file, write_file, io_read, io_write, folder_exists, file_exists, mkdir       //
    --//   Wave (macOS): same standard UNC names, no special shim needed                    //
    if typeof(readfile) ~= "function" then
        readfile   = typeof(read_file)   == "function" and read_file   or
                     typeof(io_read)     == "function" and io_read     or
                     function() return nil end
    end
    if typeof(writefile) ~= "function" then
        writefile  = typeof(write_file)  == "function" and write_file  or
                     typeof(io_write)    == "function" and io_write    or
                     function() end
    end
    if typeof(isfile) ~= "function" then
        isfile     = typeof(file_exists) == "function" and file_exists or
                     typeof(check_file)  == "function" and check_file  or
                     function(p) local ok = pcall(readfile, p); return ok end
    end
    if typeof(isfolder) ~= "function" then
        isfolder   = typeof(folder_exists) == "function" and folder_exists or
                     typeof(dir_exists)    == "function" and dir_exists    or
                     function() return false end
    end
    if typeof(makefolder) ~= "function" then
        makefolder = typeof(create_folder) == "function" and create_folder or
                     typeof(mkdir)         == "function" and mkdir         or
                     function() end
    end
    if typeof(appendfile) ~= "function" then
        appendfile = function(path, data)
            local ok, existing = pcall(readfile, path)
            pcall(writefile, path, (ok and type(existing)=="string" and existing or "") .. data)
        end
    end
    if typeof(deletefile) ~= "function" then
        deletefile = typeof(remove_file) == "function" and remove_file or
                     typeof(delete_file) == "function" and delete_file or
                     function() end
    end
    if typeof(listfiles) ~= "function" then
        listfiles  = typeof(list_files) == "function" and list_files or
                     typeof(dir)        == "function" and dir        or
                     function() return {} end
    end

    --// ── getcustomasset ── //
    --// Volcano, Potassium: native. Others: safe no-op. //
    if typeof(getcustomasset) ~= "function" then
        getcustomasset = function() return "" end
    end

    --// ── Clipboard ── //
    --// All PC executors + Codex: setclipboard                 //
    --// Delta: setclipboard OR toclipboard (alias both ways)   //
    --// Wave (macOS): setclipboard ✓                           //
    if typeof(setclipboard) ~= "function" then
        setclipboard = typeof(toclipboard)   == "function" and toclipboard   or
                       typeof(set_clipboard) == "function" and set_clipboard or
                       typeof(copystring)    == "function" and copystring    or
                       function() end
    end
    if typeof(toclipboard) ~= "function" then
        toclipboard = setclipboard
    end

    --// ── HTTP ── //
    --// All executors support game:HttpGet natively.                       //
    --// Wave (macOS): also exposes request() as the low-level function.    //
    --// Fallback chain: syn.request → http.request → request → no-op.     //
    if typeof(game.HttpGet) ~= "function" then
        pcall(function()
            if typeof(syn)  == "table" and typeof(syn.request)  == "function" then
                game.HttpGet = function(_, url) local r = syn.request({Url=url,Method="GET"}); return r and r.Body or "" end
            elseif typeof(http) == "table" and typeof(http.request) == "function" then
                game.HttpGet = function(_, url) local r = http.request({Url=url,Method="GET"}); return r and r.Body or "" end
            elseif typeof(request) == "function" then
                game.HttpGet = function(_, url) local r = request({Url=url,Method="GET"}); return r and r.Body or "" end
            end
        end)
    end
    --// Expose a unified http_request shim for scripts that call it directly //
    if typeof(http_request) ~= "function" then
        http_request = typeof(request)      == "function" and request      or
                       (typeof(syn) == "table" and typeof(syn.request) == "function" and syn.request) or
                       (typeof(http) == "table" and typeof(http.request) == "function" and http.request) or
                       function() return {Body="",StatusCode=0} end
    end
    if typeof(request) ~= "function" then
        request = http_request
    end

    --// ── hookfunction / replaceclosure ── //
    --// Opiumware, Volcano, Real, Potassium, Volt, Wave, Codex: hookfunction  //
    --// Delta: replaceclosure (also hookfunction on newer builds)             //
    if typeof(hookfunction) ~= "function" then
        hookfunction = typeof(replaceclosure)  == "function" and replaceclosure  or
                       typeof(detour_function) == "function" and detour_function or
                       function(f, r) return f end
    end
    if typeof(replaceclosure) ~= "function" then
        replaceclosure = hookfunction
    end
    if typeof(newcclosure) ~= "function" then
        newcclosure = function(f) return f end
    end

    --// ── getconnections ── //
    --// All 8 executors expose getconnections. Safe no-op if somehow absent. //
    if typeof(getconnections) ~= "function" then
        getconnections = function() return {} end
    end

    --// ── setreadonly ── //
    --// All PC executors + Codex: setreadonly ✓                             //
    --// Delta: setreadonly or make_writeable depending on build             //
    --// Wave (macOS): setreadonly ✓                                         //
    if typeof(setreadonly) ~= "function" then
        setreadonly = typeof(make_writeable) == "function" and function(t, ro)
            if not ro then pcall(make_writeable, t) end
        end or function() end
    end
    if typeof(isreadonly) ~= "function" then
        isreadonly = function() return false end
    end

    --// ── debug upvalue API ── //
    --// All 8 executors are UNC-compliant here.                             //
    --// Wave (macOS): debug.getupvalues / debug.setupvalue ✓               //
    --// Delta: same (also exposes top-level getupvalues/setupvalue aliases) //
    if type(debug) ~= "table" then debug = {} end
    if typeof(debug.getupvalues) ~= "function" then
        debug.getupvalues = typeof(getupvalues) == "function" and getupvalues or function() return {} end
    end
    if typeof(debug.getupvalue) ~= "function" then
        debug.getupvalue = typeof(getupvalue) == "function" and getupvalue or function() end
    end
    if typeof(debug.setupvalue) ~= "function" then
        debug.setupvalue = typeof(setupvalue) == "function" and setupvalue or function() end
    end
    if typeof(debug.info) ~= "function" then
        debug.info = typeof(debuginfo) == "function" and debuginfo or function() return 0 end
    end
    if typeof(debug.getconstants) ~= "function" then
        debug.getconstants = typeof(getconstants) == "function" and getconstants or function() return {} end
    end
    if typeof(debug.getproto) ~= "function" then
        debug.getproto = typeof(getproto) == "function" and getproto or function() return nil end
    end

    --// ── getgenv / getsenv / getrenv ── //
    if typeof(getgenv) ~= "function" then
        getgenv = function() return getfenv and getfenv(0) or {} end
    end
    if typeof(getsenv) ~= "function" then
        getsenv = function() return {} end
    end
    if typeof(getrenv) ~= "function" then
        getrenv = function() return {} end
    end

    --// ── firetouchinterest / fireclickdetector ── //
    --// Used by some movement/ESP features. All executors expose these; safe shim if not. //
    if typeof(firetouchinterest) ~= "function" then
        firetouchinterest = function() end
    end
    if typeof(fireclickdetector) ~= "function" then
        fireclickdetector = function() end
    end

    --// ── mouse1click / mouse1press / mouse1release ── //
    --// All executors. Delta exposes mouse_click on some builds. //
    if typeof(mouse1click) ~= "function" then
        mouse1click   = typeof(mouse_click)   == "function" and mouse_click   or function() end
    end
    if typeof(mouse1press) ~= "function" then
        mouse1press   = typeof(mouse_press)   == "function" and mouse_press   or function() end
    end
    if typeof(mouse1release) ~= "function" then
        mouse1release = typeof(mouse_release) == "function" and mouse_release or function() end
    end

    --// ── keystroke shims ── //
    if typeof(keypress) ~= "function" then
        keypress   = function() end
    end
    if typeof(keyrelease) ~= "function" then
        keyrelease = function() end
    end

    --// ── VirtualUser anti-idle ── //
    pcall(function() game:GetService("VirtualUser") end)

    --// ── Wave macOS: extra safety for missing Roblox-internal services ── //
    --// Wave runs on macOS Roblox which may have different CoreGui structure //
    if isWave then
        pcall(function()
            local cg = game:GetService("CoreGui")
            if not cg then gethui = function() return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end end
        end)
    end
end

--// flashError: visible GUI so load failures are never silent //
local function flashError(Message)
    local Ok, Err = pcall(function()
        local Parent
        pcall(function() Parent = gethui() end)
        Parent = Parent or CoreGui
        pcall(function()
            for _, Old in ipairs(Parent:GetChildren()) do
                if Old.Name == "FlexSaken_Error" then Old:Destroy() end
            end
        end)
        local Gui = Instance.new("ScreenGui")
        Gui.Name = "FlexSaken_Error"
        Gui.ResetOnSpawn = false
        Gui.DisplayOrder = 999
        Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        if not pcall(function() Gui.Parent = Parent end) or not Gui.Parent then
            Gui.Parent = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
        end
        local Frame = Instance.new("Frame")
        Frame.AnchorPoint = Vector2.new(0.5, 0)
        Frame.Position = UDim2.new(0.5, 0, 0.12, 0)
        Frame.Size = UDim2.new(0.92, 0, 0, 130)
        Frame.BackgroundColor3 = Color3.fromRGB(30, 0, 6)
        Frame.BackgroundTransparency = 0.1
        Frame.BorderSizePixel = 0
        Frame.Parent = Gui
        Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
        local Constraint = Instance.new("UISizeConstraint")
        Constraint.MaxSize = Vector2.new(500, 130)
        Constraint.Parent = Frame
        local Stroke = Instance.new("UIStroke")
        Stroke.Color = Color3.fromRGB(220, 20, 60)
        Stroke.Thickness = 2
        Stroke.Parent = Frame
        local Label = Instance.new("TextLabel")
        Label.BackgroundTransparency = 1
        Label.Position = UDim2.new(0, 10, 0, 8)
        Label.Size = UDim2.new(1, -20, 1, -50)
        Label.Font = Enum.Font.GothamBold
        Label.TextSize = 14
        Label.TextWrapped = true
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.TextYAlignment = Enum.TextYAlignment.Top
        Label.TextColor3 = Color3.fromRGB(255, 210, 215)
        Label.Text = "Flex Saken ERROR\n\n" .. tostring(Message):sub(1, 180)
        Label.Parent = Frame
        local Dismiss = Instance.new("TextButton")
        Dismiss.AnchorPoint = Vector2.new(1, 1)
        Dismiss.Position = UDim2.new(1, -8, 1, -8)
        Dismiss.Size = UDim2.new(0, 80, 0, 28)
        Dismiss.Text = "Dismiss"
        Dismiss.Font = Enum.Font.GothamBold
        Dismiss.TextSize = 13
        Dismiss.TextColor3 = Color3.new(1, 1, 1)
        Dismiss.BackgroundColor3 = Color3.fromRGB(140, 10, 30)
        Dismiss.BorderSizePixel = 0
        Dismiss.Parent = Frame
        Instance.new("UICorner", Dismiss).CornerRadius = UDim.new(0, 4)
        Dismiss.Activated:Connect(function() Gui:Destroy() end)
        task.delay(15, function() pcall(function() Gui:Destroy() end) end)
    end)
    if not Ok then warn("[FlexSaken] flashError itself failed: " .. tostring(Err)) end
    warn("[FlexSaken] " .. tostring(Message))
end

LocalPlayer.Idled:Connect(function()
    pcall(function() game:GetService("VirtualUser"):ClickButton2(Vector2.new()) end)
end)

local Version      = "1.1"
local OfficialGame = game.GameId == 6331902150 or game.GameId == 7464167604 or game.GameId == 7919224306

local PlayerGui       = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 10)
local PlayersFolder   = workspace:FindFirstChild("Players") or workspace:WaitForChild("Players", 5)
local KillersFolder   = PlayersFolder and PlayersFolder:FindFirstChild("Killers")
local SurvivorsFolder = PlayersFolder and PlayersFolder:FindFirstChild("Survivors")
local AssetsFolder    = ReplicatedStorage:FindFirstChild("Assets") or ReplicatedStorage:WaitForChild("Assets", 3)
local SurvivorAssets  = AssetsFolder and AssetsFolder:FindFirstChild("Survivors")
local ModulesFolder   = ReplicatedStorage:FindFirstChild("Modules")
local NetworkModule   = ModulesFolder and ModulesFolder:FindFirstChild("Network", true)
local NetworkFolder   = NetworkModule and (NetworkModule:FindFirstChild("Network") or NetworkModule)
local Remote          = NetworkFolder and NetworkFolder:FindFirstChildOfClass("RemoteEvent")
--// MapHolder and InGame: FindFirstChild only — never block script init for round folders //
local MapHolder       = workspace:FindFirstChild("Map")
local InGame          = MapHolder and MapHolder:FindFirstChild("Ingame")

local LocalCharacter, LocalHumanoid, LocalRoot, SpeedMultipliers
local CharacterCallbacks = {}

--// Lazy-resolve folders that may not exist at inject time (lobby) //
local function RefreshFolders()
    if not PlayersFolder then
        PlayersFolder = workspace:FindFirstChild("Players")
    end
    if PlayersFolder then
        if not KillersFolder   then KillersFolder   = PlayersFolder:FindFirstChild("Killers")   end
        if not SurvivorsFolder then SurvivorsFolder = PlayersFolder:FindFirstChild("Survivors") end
    end
    if not MapHolder then MapHolder = workspace:FindFirstChild("Map") end
    if MapHolder and not InGame then InGame = MapHolder:FindFirstChild("Ingame") end
    if not AssetsFolder    then AssetsFolder    = ReplicatedStorage:FindFirstChild("Assets") end
    if not SurvivorAssets  then SurvivorAssets  = AssetsFolder and AssetsFolder:FindFirstChild("Survivors") end
    if not ModulesFolder   then ModulesFolder   = ReplicatedStorage:FindFirstChild("Modules") end
    if not Remote then
        local nm = ModulesFolder and ModulesFolder:FindFirstChild("Network", true)
        local nf = nm and (nm:FindFirstChild("Network") or nm)
        Remote = nf and nf:FindFirstChildOfClass("RemoteEvent")
    end
end

local function OnCharacter(Character)
    RefreshFolders()
    LocalCharacter = Character
    LocalHumanoid  = Character:FindFirstChildOfClass("Humanoid") or Character:WaitForChild("Humanoid", 5)
    LocalRoot      = (LocalHumanoid and LocalHumanoid.RootPart) or Character:FindFirstChild("HumanoidRootPart") or Character:WaitForChild("HumanoidRootPart", 5)
    SpeedMultipliers = Character:FindFirstChild("SpeedMultipliers") or Character:WaitForChild("SpeedMultipliers", 5)
    for _, Callback in CharacterCallbacks do task.spawn(Callback) end
end
LocalPlayer.CharacterAdded:Connect(OnCharacter)

--// Also refresh folders every few seconds in background for late-joining lobby //
task.spawn(function()
    for _ = 1, 10 do task.wait(3); RefreshFolders() end
end)

--// SETTINGS / SAVE (FluxSaken system) //

local State = {}
local Saved = {}
local FilesSupported = typeof(readfile)=="function" and typeof(writefile)=="function" and typeof(isfile)=="function" and typeof(isfolder)=="function" and typeof(makefolder)=="function"
local SettingsFolder = "FlexSaken"
local SettingsFile   = SettingsFolder .. "/Settings.json"
local SavePending    = false

if FilesSupported then
    pcall(function()
        if not isfolder(SettingsFolder) then makefolder(SettingsFolder) end
        if isfile(SettingsFile) then
            local Data = HttpService:JSONDecode(readfile(SettingsFile))
            if type(Data) == "table" then Saved = Data end
        end
    end)
end

local function SaveSettings()
    if not FilesSupported or SavePending then return end
    SavePending = true
    task.delay(0.5, function()
        SavePending = false
        pcall(function() writefile(SettingsFile, HttpService:JSONEncode(Saved)) end)
    end)
end

--// LOAD UI //

local WindUI
local _cacheFile = "FlexSaken_WindUI.lua"
local _uiUrls = {
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua",
    "https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua",
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua",
}

--// Try loading from disk cache first (avoids network entirely on re-runs) //
local _cached = pcall(function()
    if isfile and isfile(_cacheFile) then
        local src = readfile(_cacheFile)
        if src and #src > 500 then
            local lib = loadstring(src)()
            if lib then WindUI = lib end
        end
    end
end)

--// If cache missed, try each URL //
if not WindUI then
    for _, url in ipairs(_uiUrls) do
        local ok, result = pcall(function()
            local src = game:HttpGet(url, true)
            if not src or #src < 500 then error("empty response") end
            --// Save to disk for next run //
            pcall(function() if writefile then writefile(_cacheFile, src) end end)
            return loadstring(src)()
        end)
        if ok and result then WindUI = result; break end
        task.wait(1)
    end
end

--// If WindUI still not loaded, retry up to 3 more times before giving up //
if not WindUI then
    for _retry = 1, 3 do
        warn("[FlexSaken] WindUI load attempt " .. _retry .. " of 3 — retrying in 3s...")
        task.wait(3)
        for _, url in ipairs(_uiUrls) do
            local ok, result = pcall(function()
                local src = game:HttpGet(url, true)
                if not src or #src < 500 then error("empty response") end
                pcall(function() if writefile then writefile(_cacheFile, src) end end)
                return loadstring(src)()
            end)
            if ok and result then WindUI = result; break end
        end
        if WindUI then break end
    end
end

local UsingStub = false

--// Stub UI: accepts every call and does nothing, so features keep running when WindUI fails //
local function MakeStub()
    return setmetatable({}, {
        __index = function(_, Key)
            if Key == "Flags" then return {} end
            return function() return MakeStub() end
        end,
        __call = function() return MakeStub() end,
    })
end

local function MakeStubUI()
    local UI = MakeStub()
    rawset(UI, "Notify", function(_, Info)
        print("[FlexSaken] " .. tostring(Info and Info.Title) .. ": " .. tostring(Info and Info.Content))
    end)
    return UI
end

if not WindUI then
    flashError("WindUI failed to load - running without the menu. Saved settings still apply. Check your internet and HttpGet permissions.")
    WindUI = MakeStubUI()
    UsingStub = true
end

local LogoId     = "rbxassetid://121959674354252"
local DiscordLink= "https://discord.gg/rA3Vm8u9U"

--// CRIMSON THEME //

local ThemeAdded = pcall(function()
    WindUI:AddTheme({
        Name        = "Crimson",
        Accent      = Color3.fromRGB(220, 20, 60),
        Dialog      = Color3.fromRGB(18, 6, 8),
        Outline     = Color3.fromRGB(255, 50, 80),
        Text        = Color3.fromRGB(255, 220, 225),
        Placeholder = Color3.fromRGB(180, 100, 110),
        Background  = Color3.fromRGB(12, 4, 6),
        Button      = Color3.fromRGB(140, 10, 30),
        Icon        = Color3.fromRGB(255, 80, 100),
    })
end)

local TouchOnly = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local WindowOptions = ({
    Title       = "Flex Saken",
    Icon        = LogoId,
    Author      = "By Ethan and Luna",
    Folder      = "FlexSaken",
    Size        = TouchOnly and UDim2.fromOffset(500, 340) or UDim2.fromOffset(600, 460),
    Transparent = true,
    Theme       = ThemeAdded and "Crimson" or "Dark",
    SideBarWidth= 190,
    HasOutline  = true,
})

local Window
do
    local Created, Result = pcall(function() return WindUI:CreateWindow(WindowOptions) end)
    if Created and Result then
        Window = Result
    else
        flashError("WindUI CreateWindow failed: " .. tostring(Result))
        WindUI = MakeStubUI()
        UsingStub = true
        Window = WindUI:CreateWindow(WindowOptions)
    end
end

pcall(function() WindUI:SetTheme("Crimson") end)
pcall(function() Window:Tag({ Title = "V" .. Version, Color = Color3.fromRGB(220, 20, 60) }) end)

--// OPEN BUTTON with crimson sparkle gradient //

pcall(function()
    Window:EditOpenButton({
        Title         = "Flex Saken",
        Icon          = LogoId,
        CornerRadius  = UDim.new(0, 16),
        StrokeThickness = 2,
        Color         = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 30,  60)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 0,   40)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 80, 100)),
        }),
        Draggable = true,
    })
end)

pcall(function() Window:SetToggleKey(Enum.KeyCode.RightShift) end)

--// HELPERS //

local function Notify(Title, Content, Duration)
    pcall(function()
        WindUI:Notify({ Title = Title, Content = Content, Duration = Duration or 4, Icon = "bell" })
    end)
end

local function CopyText(Text)
    local Copy = setclipboard or toclipboard
    if typeof(Copy) ~= "function" then return false end
    return (pcall(Copy, Text))
end

local Registry = {}

--// SafeCall / Risky: every feature runs inside its own pcall (no outer wrapper) //
local function SafeCall(Name, Callback, ...)
    local Ok, Err = pcall(Callback, ...)
    if not Ok then warn("[FlexSaken] " .. tostring(Name) .. " failed: " .. tostring(Err)) end
    return Ok
end

local function Risky(Name, Body)
    local Ok, Err = pcall(Body)
    if not Ok then warn("[FlexSaken] " .. tostring(Name) .. " failed to load: " .. tostring(Err)) end
    return Ok
end

local function AddSection(Tab, Title) pcall(function() Tab:Section({ Title = Title }) end) end

local function AddToggle(Tab, Key, Title, Default, Callback)
    --// Restore saved value or use default //
    local Value = Saved[Key]
    if type(Value) ~= "boolean" then Value = Default end
    State[Key] = Value
    local Element
    local Ok, Err = pcall(function()
        Element = Tab:Toggle({ Title = Title, Value = Value, Callback = function(New)
            State[Key] = New
            Saved[Key] = New
            SaveSettings()
            if Callback then task.spawn(SafeCall, Key, Callback, New) end
        end })
    end)
    if not Ok then warn("Toggle " .. Title .. ": " .. tostring(Err)) end
    Registry[Key] = { Kind = "toggle", Default = Default, Callback = Callback, Element = Element }
    --// Fire callback immediately so saved-on features activate on load //
    if Callback and Value then task.defer(SafeCall, Key, Callback, Value) end
    return Element
end

local function AddSlider(Tab, Key, Title, Min, Max, Default, Step, Callback)
    local Value = Saved[Key]; if type(Value) ~= "number" then Value = Default end
    State[Key] = Value
    local Element
    pcall(function()
        Element = Tab:Slider({ Title = Title, Step = Step or 1, Value = { Min = Min, Max = Max, Default = Value }, Callback = function(New)
            State[Key] = New; Saved[Key] = New; SaveSettings()
            if Callback then task.spawn(SafeCall, Key, Callback, New) end
        end })
    end)
    if Callback then task.defer(SafeCall, Key, Callback, Value) end
    Registry[Key] = { Kind = "slider", Default = Default, Callback = Callback, Element = Element }
    return Element
end

local function AddDropdown(Tab, Key, Title, Values, Default, Callback)
    local Value = Saved[Key]
    if type(Value) ~= "string" or not table.find(Values, Value) then Value = Default end
    State[Key] = Value
    local Element
    pcall(function()
        Element = Tab:Dropdown({ Title = Title, Values = Values, Value = Value, Callback = function(New)
            State[Key] = New; Saved[Key] = New; SaveSettings()
            if Callback then task.spawn(SafeCall, Key, Callback, New) end
        end })
    end)
    if Callback then task.defer(SafeCall, Key, Callback, Value) end
    Registry[Key] = { Kind = "dropdown", Default = Default, Callback = Callback, Element = Element }
    return Element
end

local function AddInput(Tab, Key, Title, Default, Callback)
    State[Key] = Default
    local Element
    pcall(function()
        Element = Tab:Input({ Title = Title, Value = Default, Placeholder = Default, Callback = function(New)
            State[Key] = New
            if Callback then task.spawn(SafeCall, Key, Callback, New) end
        end })
    end)
    Registry[Key] = { Kind = "input", Default = Default, Callback = Callback, Element = Element }
    return Element
end

local function AddButton(Tab, Title, Callback)
    pcall(function() Tab:Button({ Title = Title, Callback = Callback }) end)
end

local function HasAsset(Folder, Name)
    return Folder ~= nil and (Folder:FindFirstChild(Name) ~= nil or Folder:FindFirstChild("!" .. Name) ~= nil)
end

local function IdSet(List)
    local Set = {}
    for _, Id in List do Set["rbxassetid://" .. Id] = true end
    return Set
end

local function FireAbility(Name)
    if not Remote then return end
    Remote:FireServer("UseActorAbility", { Name })
    if not OfficialGame then Remote:FireServer("UseActorAbility", Name) end
end

local function GetClosestKiller(Distance)
    local Best; local BestDistance = Distance or 55
    if not KillersFolder or not LocalRoot then return nil, BestDistance end
    for _, Killer in KillersFolder:GetChildren() do
        local Root     = Killer:FindFirstChild("HumanoidRootPart")
        local Humanoid = Killer:FindFirstChildOfClass("Humanoid")
        if Root and Humanoid and Humanoid.Health > 0 then
            local Magnitude = (Root.Position - LocalRoot.Position).Magnitude
            if Magnitude < BestDistance then Best = Killer; BestDistance = Magnitude end
        end
    end
    return Best, BestDistance
end

--// Shared RemoteFunction silent-aim dispatcher (RemoteFunction.OnClientInvoke hook) //
local rfDispatch = {
    Hooks = {},
    Order = {},
    Installed = false,
    Original = nil,
    Remote = nil,
    Intercept = { GetMousePosition = true, GetCameraCF = true },
}

function rfDispatch:Register(Id, Callback)
    if not self.Hooks[Id] then table.insert(self.Order, Id) end
    self.Hooks[Id] = Callback
end

function rfDispatch:Unregister(Id)
    self.Hooks[Id] = nil
    local Index = table.find(self.Order, Id)
    if Index then table.remove(self.Order, Index) end
end

function rfDispatch:Count()
    return #self.Order
end

function rfDispatch:Install(Target)
    if not Target then return false end
    if self.Installed and self.Remote == Target then return true end
    if self.Installed then self:Uninstall() end
    local Ok, Original = pcall(function()
        if typeof(getcallbackvalue) == "function" then return getcallbackvalue(Target, "OnClientInvoke") end
        return Target.OnClientInvoke
    end)
    self.Original = Ok and Original or nil
    if not Ok then warn("[FlexSaken] rfDispatch: could not read the original OnClientInvoke callback") end
    self.Remote = Target
    Target.OnClientInvoke = function(RequestName, ...)
        if self.Intercept[RequestName] then
            for _, Id in ipairs(self.Order) do
                local Hook = self.Hooks[Id]
                if Hook then
                    local HookOk, Result = pcall(Hook, RequestName, ...)
                    if HookOk and Result ~= nil then return Result end
                end
            end
        end
        local Previous = self.Original
        if Previous then return Previous(RequestName, ...) end
    end
    self.Installed = true
    return true
end

function rfDispatch:Uninstall()
    if not self.Installed then return end
    local Target = self.Remote
    if Target then pcall(function() Target.OnClientInvoke = self.Original end) end
    self.Hooks = {}
    self.Order = {}
    self.Original = nil
    self.Remote = nil
    self.Installed = false
end

local function GetSharedRF(Timeout)
    Timeout = Timeout or 5
    local Ok, Found = pcall(function()
        return ReplicatedStorage:WaitForChild("Modules", Timeout)
            :WaitForChild("Network", Timeout)
            :WaitForChild("Network", Timeout)
            :WaitForChild("RemoteFunction", Timeout)
    end)
    if Ok and Found then return Found end
    local Modules = ReplicatedStorage:FindFirstChild("Modules")
    local NetworkRoot = Modules and Modules:FindFirstChild("Network")
    if NetworkRoot then
        for _, Object in ipairs(NetworkRoot:GetDescendants()) do
            if Object:IsA("RemoteFunction") then return Object end
        end
    end
    return nil
end

--// Silent aim factory (Nova, Dusekkar) built on rfDispatch //
local SA = {}

function SA.Ping()
    local Ok, Value = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
    if Ok and type(Value) == "number" then return Value / 1000 end
    local Ok2, Value2 = pcall(function() return LocalPlayer:GetNetworkPing() end)
    return Ok2 and Value2 or 0.1
end

function SA.HasLineOfSight(Origin, Model, Root)
    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = { LocalCharacter }
    Params.IgnoreWater = true
    local Result = workspace:Raycast(Origin, Root.Position - Origin, Params)
    return Result == nil or Result.Instance:IsDescendantOf(Model)
end

function SA.Create(Id, DefaultTeam, GateName)
    local Aim = {
        Id = Id, Enabled = false, Prediction = 0.12, Offset = 0, Range = 500,
        Mode = "Nearest", Team = DefaultTeam, WallCheck = false, PingComp = false,
        Gate = false, GateName = GateName,
        Motion = setmetatable({}, { __mode = "k" }),
    }

    --// smoothed velocity: measured from position deltas, falls back to AssemblyLinearVelocity //
    function Aim:Velocity(Root)
        local Now = os.clock()
        local Position = Root.Position
        local Data = self.Motion[Root]
        if not Data then
            self.Motion[Root] = { Pos = Position, Time = Now, Vel = Root.AssemblyLinearVelocity }
            return Root.AssemblyLinearVelocity
        end
        local Delta = Now - Data.Time
        if Delta >= 0.03 then
            Data.Vel = Data.Vel:Lerp((Position - Data.Pos) / Delta, 0.6)
            Data.Pos = Position
            Data.Time = Now
        end
        local Assembly = Root.AssemblyLinearVelocity
        if Data.Vel.Magnitude < 0.5 and Assembly.Magnitude > 0.5 then return Assembly end
        return Data.Vel
    end

    function Aim:Target()
        if not LocalRoot then return nil end
        RefreshFolders()
        local Folders = {}
        if self.Team ~= "Killers" and SurvivorsFolder then table.insert(Folders, SurvivorsFolder) end
        if self.Team ~= "Survivors" and KillersFolder then table.insert(Folders, KillersFolder) end
        local Camera = workspace.CurrentCamera
        local Best, BestScore
        for _, Folder in ipairs(Folders) do
            for _, Model in ipairs(Folder:GetChildren()) do
                if Model ~= LocalCharacter then
                    local Root = Model:FindFirstChild("HumanoidRootPart")
                    local Humanoid = Model:FindFirstChildOfClass("Humanoid")
                    if Root and Humanoid and Humanoid.Health > 0 then
                        local Distance = (Root.Position - LocalRoot.Position).Magnitude
                        if Distance <= self.Range and (not self.WallCheck or SA.HasLineOfSight(LocalRoot.Position, Model, Root)) then
                            local Score = Distance
                            if self.Mode == "Lowest Health" then
                                Score = Humanoid.Health
                            elseif self.Mode == "Closest To Crosshair" and Camera then
                                local Screen, OnScreen = Camera:WorldToViewportPoint(Root.Position)
                                Score = (Vector2.new(Screen.X, Screen.Y) - Camera.ViewportSize / 2).Magnitude + (OnScreen and 0 or 10000)
                            end
                            if not BestScore or Score < BestScore then Best = Root; BestScore = Score end
                        end
                    end
                end
            end
        end
        return Best
    end

    function Aim:Hook(RequestName)
        if RequestName ~= "GetMousePosition" or not self.Enabled then return nil end
        if self.Gate and not (LocalCharacter and LocalCharacter.Name:lower() == self.GateName:lower()) then return nil end
        local Root = self:Target()
        if not Root then return nil end
        local Lead = self.Prediction
        if self.PingComp then Lead += SA.Ping() * 0.5 end
        return Root.Position + self:Velocity(Root) * Lead + Vector3.new(0, self.Offset, 0)
    end

    function Aim:SetEnabled(On)
        self.Enabled = On and true or false
        if self.Enabled then
            task.spawn(function()
                local Target = GetSharedRF(10)
                if not self.Enabled then return end
                if not Target then Notify(Id, "Shared RemoteFunction not found", 4); return end
                rfDispatch:Install(Target)
                rfDispatch:Register(Id, function(RequestName, ...) return self:Hook(RequestName, ...) end)
            end)
        else
            rfDispatch:Unregister(Id)
            if rfDispatch:Count() == 0 then rfDispatch:Uninstall() end
        end
    end

    return Aim
end

SA.Nova     = SA.Create("Nova", "Survivors", "Nova")
SA.Dusekkar = SA.Create("Dusekkar", "Killers", "Dusekkar")

function SA.AddUI(Tab, Aim, Key, Label)
    AddSection(Tab, Label .. " Silent Aim")
    AddToggle(Tab, Key .. "Aim", "Enable " .. Label .. " Silent Aim", false, function(On) Aim:SetEnabled(On) end)
    AddSlider(Tab, Key .. "Prediction", "Prediction (s)", 0, 0.5, 0.12, 0.01, function(V) Aim.Prediction = V end)
    AddSlider(Tab, Key .. "Offset", "Aim Height Offset", -5, 5, 0, 0.1, function(V) Aim.Offset = V end)
    AddSlider(Tab, Key .. "Range", "Max Range (studs)", 20, 1000, 500, 10, function(V) Aim.Range = V end)
    AddDropdown(Tab, Key .. "Priority", "Target Priority", { "Nearest", "Lowest Health", "Closest To Crosshair" }, "Nearest", function(V) Aim.Mode = V end)
    AddDropdown(Tab, Key .. "Team", "Target Team", { "Survivors", "Killers", "Both" }, Aim.Team, function(V) Aim.Team = V end)
    AddToggle(Tab, Key .. "WallCheck", "Wall Check", false, function(V) Aim.WallCheck = V end)
    AddToggle(Tab, Key .. "PingComp", "Ping Compensation", false, function(V) Aim.PingComp = V end)
    AddToggle(Tab, Key .. "Gate", "Only While Playing As " .. Label, false, function(V) Aim.Gate = V end)
    AddButton(Tab, "Unload " .. Label .. " Hook", function()
        Aim:SetEnabled(false)
        pcall(function()
            State[Key .. "Aim"] = false
            Saved[Key .. "Aim"] = false
            SaveSettings()
            local Entry = Registry[Key .. "Aim"]
            if Entry and Entry.Element and Entry.Element.Set then Entry.Element:Set(false) end
        end)
        Notify(Label, "Silent aim hook unloaded", 3)
    end)
end

--// FLUX AUTO BLOCK (QueryHitbox / sound / animation based) //

local AttackSounds = IdSet({
    "100600301396617","101199185291628","101553872555606","101698569375359","104910828105172","105204810054381","105207247877248","105516183226360","105840448036441","106836941416453",
    "107345261604889","107401225947000","108360420637223","108610718831698","108651070773439","108907358619313","109348678063422","109570290393196","111295935549452","112809109188560",
    "113413858159336","114481520550129","115026634746636","115343460993527","115678417928765","116468089135195","116581754553533","117173212095661","117231507259853","118562842802948",
    "119583605486352","119664480754070","119942598489800","120749612844426","121853342688333","121954639447247","12222208","12222216","122398404613193","123835423223220",
    "123923371062204","124234993291213","124903763333174","125213046326879","126469686116453","127557531826290","128195973631079","128367348686124","128856426573270","131123355704017",
    "132160759837000","132581672170205","133709029886490","134720314512566","135256560060972","135319730390518","136323728355613","137809737339569","138047522440301","139996647355899",
    "140242176732868","18511965048","70626755789950","70739368096233","71805956520207","72085713525541","73662192846371","74809026448465","74842815979546","75330693422988",
    "77649238882198","79391273191671","79612713897495","79980897195554","80516583309685","82221759983649","82843272472677","84307400688050","85853080745515","86174610237192",
    "86506028049034","88589682639517","89004992452376","92869747208256","93299090238530","94273783714662","94317217837143","94632255644411","95079963655241","95863147467940",
    "96117920303138","96594507550917","98111231282218","98675142200448","98733709078792","98742773509325","98866992038428","99215225043220","99856718263455","99918466107008"})
local AttackAnimations = IdSet({"87259391926321","140703210927645","136007065400978","129843313690921","86709774283672","108807732150251","138040001965654","86096387000557","96959123077498","72722244508749","100725497418533","89448354637442","114159864966636","128647082364719","111415926592375","144729402831182","149382754027381","152406193748293","155783209463712","158934728164927","161204837592841","164527384912036","167849203748192","170284936182745","173562849103728","176849203718492","179284736192845","182563748192037","185849273618492","188284736192845","191562849103728","137294836274819","139572948362741","142851739482716","146129483729104","149407362817394","152685274910382","155963182749103","159241073628471","162518947361928","165796836274819","169074729103728","172352618294736","175630507382641","178908396471532","182186285362741","185464174273819","188742063182736","192019952091647","195297840982736","198575729873641","102228729296384","140242176732868","112809109188560","136323728355613","115026634746636","84116622032112","108907358619313","127793641088496","86174610237192","95079963655241","101199185291628","119942598489800","84307400688050","113037804008732","105200830849301","75330693422988","82221759983649","81702359653578","108610718831698","112395455254818","109431876587852","109348678063422","85853080745515","98733709078792","105840448036441","114742322778642","105415540898010","106300477136129","80516583309685","116581754553533","71834552297085","119583605486352","117173212095661","104910828105172","79980897195554","116527305931161","131406927389838","94317217837143","121954639447247","128856426573270","131123355704017","107444859834748","133709029886490","183948573829104","184857362910485","185766251091826","186675140182207","187584039273648","188492928364089","189401817455420","190310706546861","191219595638202","192128484729543"})
local PunchAnimations = IdSet({"87259391926321","140703210927645","136007065400978","129843313690921","86709774283672","108807732150251","138040001965654","86096387000557","144729402831182","149382754027381","152406193748293","155783209463712"})

local LastBlock = 0

local VisualCheckBeam = Instance.new("Part")
VisualCheckBeam.Name         = "FlexVisualCheckBeam"
VisualCheckBeam.Anchored     = true
VisualCheckBeam.CanCollide   = false
VisualCheckBeam.CanQuery     = false
VisualCheckBeam.CanTouch     = false
VisualCheckBeam.Transparency = 1
VisualCheckBeam.Parent       = workspace
local beamAtt0 = Instance.new("Attachment"); local beamAtt1 = Instance.new("Attachment")
beamAtt0.Parent = LocalRoot or VisualCheckBeam; beamAtt1.Parent = VisualCheckBeam
local VisualBeam = Instance.new("Beam")
VisualBeam.Attachment0  = beamAtt0; VisualBeam.Attachment1 = beamAtt1
VisualBeam.Width0       = 0.05; VisualBeam.Width1 = 0.05
VisualBeam.FaceCamera   = true; VisualBeam.LightEmission = 1
VisualBeam.Color        = ColorSequence.new(Color3.fromRGB(220, 20, 60))
VisualBeam.Enabled      = false; VisualBeam.Parent = VisualCheckBeam

local DragToken = 0
local function DragToward(KillerRoot)
    if not State.HitboxDrag or not LocalRoot or not KillerRoot then return end
    local Distance = (KillerRoot.Position - LocalRoot.Position).Magnitude
    if Distance > (State.HitboxDragRange or 30) then return end
    DragToken += 1; local MyToken = DragToken; local Speed = State.DragSpeed or 14
    local Start = os.clock(); local Duration = 0.35
    task.spawn(function()
        while MyToken == DragToken and os.clock() - Start < Duration do
            local Delta = RunService.Heartbeat:Wait()
            if not LocalRoot or not KillerRoot.Parent or not LocalHumanoid then break end
            local Direction = KillerRoot.Position - LocalRoot.Position
            Direction = Vector3.new(Direction.X, 0, Direction.Z)
            if Direction.Magnitude <= 3 then break end
            local Ramp = math.sin(math.pi * (os.clock() - Start) / Duration)
            LocalHumanoid:Move(Direction.Unit, false)
            LocalRoot.CFrame = LocalRoot.CFrame + Direction.Unit * Speed * Ramp * Delta
            LocalRoot.CFrame = CFrame.lookAt(LocalRoot.Position, LocalRoot.Position + Direction.Unit)
        end
        if LocalHumanoid and State.AutoBlock then LocalHumanoid:Move(Vector3.zero, false) end
    end)
end

local function DoBlock(KillerRoot)
    if os.clock() - LastBlock < 0.05 then return end
    LastBlock = os.clock()
    if State.HitboxDrag and KillerRoot then DragToward(KillerRoot) end
    local Delay = (State.BlockDelay or 0) / 1000
    if Delay > 0 then
        task.delay(Delay, function()
            if LocalRoot and LocalCharacter and LocalCharacter.Parent then FireAbility("Block") end
        end)
    else FireAbility("Block") end
end

local BlockWatchers = {}
local HitboxFolder = Instance.new("Folder"); HitboxFolder.Name = "FlexSakenHitboxes"; HitboxFolder.Parent = workspace
local CustomHitboxSize   = Vector3.new(5.2, 6, 5.65)
local CustomHitboxOffset = CFrame.new(0, 0, -3.5)

local function GetLocalQueryHitbox()
    if not LocalCharacter then return nil end
    return LocalCharacter:FindFirstChild("QueryHitbox")
end

local function TriggerBlockWithHitbox(Killer, QueryHitbox)
    if not State.AutoBlock or not LocalRoot then return end
    local LocalQuery = GetLocalQueryHitbox(); if not LocalQuery then return end
    local Params = OverlapParams.new(); Params.MaxParts = 1; Params.BruteForceAllSlow = true; Params.IncludeInstances = { LocalQuery }
    for i = 1, 10 do
        if not State.AutoBlock or not QueryHitbox.Parent then break end
        local boxCFrame = QueryHitbox.CFrame * CustomHitboxOffset; local boxSize = CustomHitboxSize * 2.2
        local Hit = workspace:GetPartBoundsInBox(boxCFrame, boxSize, Params)
        if #Hit > 0 then DoBlock(QueryHitbox); break end
        task.wait(0.02)
    end
end

local function WatchKiller(Killer)
    if BlockWatchers[Killer] then return end
    local Humanoid   = Killer:FindFirstChildOfClass("Humanoid") or Killer:WaitForChild("Humanoid", 5)
    if not Humanoid then return end
    local QueryHitbox = Killer:FindFirstChild("QueryHitbox") or Killer:WaitForChild("QueryHitbox", 5)
    local Animator   = Humanoid:FindFirstChildOfClass("Animator")
    local Connections = {}; local Hooked = {}
    local function Trigger()
        if QueryHitbox and State.AutoBlock then task.spawn(TriggerBlockWithHitbox, Killer, QueryHitbox) end
    end
    if Animator then
        table.insert(Connections, Animator.AnimationPlayed:Connect(function(Track)
            if not State.AutoBlock or not Track or not Track.Animation then return end
            local AnimId = tostring(Track.Animation.AnimationId or ""):match("%d+")
            if AnimId and AttackAnimations["rbxassetid://" .. AnimId] then Trigger() end
        end))
    end
    local function HookSound(Sound)
        if Hooked[Sound] or not AttackSounds[Sound.SoundId] then return end
        Hooked[Sound] = true; table.insert(Connections, Sound.Played:Connect(Trigger))
    end
    table.insert(Connections, Killer.DescendantAdded:Connect(function(Descendant)
        if Descendant:IsA("Sound") and AttackSounds[Descendant.SoundId] then Trigger(); HookSound(Descendant) end
    end))
    table.insert(Connections, Killer.AncestryChanged:Connect(function(_, Parent)
        if not Parent then
            for _, Connection in Connections do Connection:Disconnect() end
            table.clear(Connections); BlockWatchers[Killer] = nil
        end
    end))
    for _, Descendant in Killer:GetDescendants() do if Descendant:IsA("Sound") then HookSound(Descendant) end end
    BlockWatchers[Killer] = function()
        for _, Connection in Connections do Connection:Disconnect() end
        table.clear(Connections); BlockWatchers[Killer] = nil
    end
end

local KillerAddedConnection
local function SetAutoBlock(Enabled)
    State.AutoBlock = Enabled
    if Enabled then
        if not KillersFolder then return end
        for _, Killer in KillersFolder:GetChildren() do task.spawn(WatchKiller, Killer) end
        if not KillerAddedConnection then
            KillerAddedConnection = KillersFolder.ChildAdded:Connect(function(Killer)
                if State.AutoBlock then task.spawn(WatchKiller, Killer) end
            end)
        end
    else
        if KillerAddedConnection then KillerAddedConnection:Disconnect(); KillerAddedConnection = nil end
        for _, Stop in pairs(BlockWatchers) do pcall(Stop) end; table.clear(BlockWatchers)
    end
end

--// VisualCheck beam loop //
local _visualTick = 0
RunService.Heartbeat:Connect(function()
    _visualTick += 1
    if _visualTick < 5 then return end
    _visualTick = 0
    if State.StrictVisualCheck and LocalRoot and KillersFolder then
        local Killer = GetClosestKiller(150)
        if Killer then
            local krp = Killer:FindFirstChild("HumanoidRootPart")
            if krp then
                if beamAtt0.Parent ~= LocalRoot then beamAtt0.Parent = LocalRoot end
                if beamAtt1.Parent ~= krp then beamAtt1.Parent = krp end
                local Offset = LocalRoot.Position - krp.Position
                local Look   = Vector3.new(krp.CFrame.LookVector.X, 0, krp.CFrame.LookVector.Z)
                local ToMe   = Vector3.new(Offset.X, 0, Offset.Z)
                local IsSeeing = false
                if Look.Magnitude > 0.01 and ToMe.Magnitude > 0.01 then
                    if Look.Unit:Dot(ToMe.Unit) > 0.6 then IsSeeing = true end
                end
                VisualBeam.Color   = ColorSequence.new(IsSeeing and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(220, 20, 60))
                VisualBeam.Enabled = true
            else VisualBeam.Enabled = false end
        else VisualBeam.Enabled = false end
    else VisualBeam.Enabled = false end
end)

--// Punch aimbot //
local AimConnection
local function StopAiming()
    if AimConnection then AimConnection:Disconnect(); AimConnection = nil end
end
local function GetNearestHeavyRoot()
    if not LocalRoot then return nil end
    local Best; local BestDistance = math.huge
    for _, Player in Players:GetPlayers() do
        if Player ~= LocalPlayer and Player.Character then
            local Humanoid = Player.Character:FindFirstChildOfClass("Humanoid")
            local Root     = Player.Character:FindFirstChild("HumanoidRootPart")
            if Humanoid and Root and Humanoid.MaxHealth > 500 then
                local Magnitude = (LocalRoot.Position - Root.Position).Magnitude
                if Magnitude < BestDistance then Best = Root; BestDistance = Magnitude end
            end
        end
    end
    return Best
end
local function StartAiming()
    StopAiming()
    AimConnection = RunService.Heartbeat:Connect(function()
        if not State.PunchAimbot or not LocalRoot then return end
        local Target = GetNearestHeavyRoot(); if not Target then return end
        local Direction = Target.Position - LocalRoot.Position
        Direction = Vector3.new(Direction.X, 0, Direction.Z)
        if Direction.Magnitude < 0.01 then return end
        LocalRoot.CFrame = CFrame.new(LocalRoot.Position, LocalRoot.Position + Direction.Unit)
        local Camera = workspace.CurrentCamera
        if Camera then Camera.CFrame = CFrame.new(Camera.CFrame.Position, Target.Position) end
    end)
end
local AnimationConnection
local function HookAnimations()
    if AnimationConnection then AnimationConnection:Disconnect(); AnimationConnection = nil end
    StopAiming(); if not LocalHumanoid then return end
    AnimationConnection = LocalHumanoid.AnimationPlayed:Connect(function(Track)
        local Animation = Track.Animation; if not Animation then return end
        local Id = Animation.AnimationId
        if PunchAnimations[Id] and State.PunchAimbot then StartAiming(); Track.Stopped:Connect(StopAiming) end
    end)
end
table.insert(CharacterCallbacks, HookAnimations)
table.insert(CharacterCallbacks, function()
    if not LocalCharacter then return end
    LocalCharacter:GetAttributeChangedSignal("TimesHit"):Connect(function()
        if State.AutoPunch and SpeedMultipliers and SpeedMultipliers:FindFirstChild("GuestBlocking") and LocalHumanoid and (LocalHumanoid:GetAttribute("Overheal") or 0) >= 10 and GetClosestKiller(55) then
            task.wait(0.08); FireAbility("Punch")
        end
    end)
end)

--// PING DISPLAY //

local PingGui; local PingToken = 0
local function GetPingColor(Ping)
    if Ping <= 60 then return Color3.fromRGB(60, 220, 80)
    elseif Ping <= 120 then return Color3.fromRGB(255, 220, 50)
    elseif Ping <= 200 then return Color3.fromRGB(255, 150, 40)
    else return Color3.fromRGB(220, 20, 60) end
end
local function SetShowPing(Enabled)
    PingToken += 1; if PingGui then PingGui:Destroy(); PingGui = nil end; if not Enabled then return end
    local Token = PingToken
    local Gui   = Instance.new("ScreenGui"); Gui.Name = "PingDisplay"; Gui.ResetOnSpawn = false; Gui.Parent = PlayerGui
    local Box   = Instance.new("Frame"); Box.Size = UDim2.new(0, 82, 0, 28); Box.Position = UDim2.new(0, 6, 0, 6)
    Box.BackgroundColor3 = Color3.fromRGB(18, 4, 6); Box.BackgroundTransparency = 0.15; Box.BorderSizePixel = 0; Box.Parent = Gui
    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 6)
    local Stroke = Instance.new("UIStroke"); Stroke.Thickness = 1; Stroke.Color = Color3.fromRGB(220, 20, 60); Stroke.Transparency = 0.35; Stroke.Parent = Box
    local Label  = Instance.new("TextLabel"); Label.Size = UDim2.new(1, 0, 1, 0); Label.BackgroundTransparency = 1
    Label.TextColor3 = Color3.fromRGB(255, 220, 225); Label.TextSize = 14; Label.Font = Enum.Font.GothamBold
    Label.Text = "Ping: 0 ms"; Label.Parent = Box; PingGui = Gui
    task.spawn(function()
        local LastPing = nil
        while Token == PingToken and Gui.Parent do
            local Success, Ping = pcall(function() return LocalPlayer:GetNetworkPing() end)
            if Success and typeof(Ping) == "number" and Ping >= 0 then
                Ping = math.round(Ping * 1000)
                if Ping ~= LastPing then LastPing = Ping; Label.Text = "Ping: " .. Ping .. " ms"; Label.TextColor3 = GetPingColor(Ping) end
            end
            task.wait(2)
        end
    end)
end

--// SPRINTING / INFINITE STAMINA //

local SprintingModule; local SprintingHooked = false
local function GetSprinting()
    if SprintingModule then return SprintingModule end
    local Success, Module = pcall(function() return require(ReplicatedStorage.Systems.Character.Game.Sprinting) end)
    if Success and type(Module) == "table" then SprintingModule = Module end
    return SprintingModule
end
local function SetInfiniteStamina(Enabled)
    local Sprinting = GetSprinting()
    if not Sprinting then Notify("Infinite Stamina", "Could not find the sprinting module", 4); return end
    if not SprintingHooked and typeof(Sprinting.Init) == "function" then
        SprintingHooked = true; local OldInit = Sprinting.Init
        Sprinting.Init = function(...)
            local Result = OldInit(...)
            if State.InfiniteStamina then Sprinting.StaminaLossDisabled = true end
            return Result
        end
    end
    Sprinting.StaminaLossDisabled = Enabled and true or false
end

--// Fix credits: luna <3 //

--// Fixed path: round folder is Workspace.Map.Ingame, not Workspace.Ingame //
--// New: generators live in Workspace.Map.Ingame.Map //
--// New: fires cb whenever a new Workspace.Map.Ingame appears (new round / new map) //
--// Fixed dup check: only skips if a parent is already highlighted, no more hiding sibling items //
--// Fixed generators: scan Ingame.Map instead of the wrong folder //
--// Fixed items: workspace-wide scan + live hook for BloxyCola and Medkit //
--// Fixed items: start the item hook and initial scan //
--// Fixed items: disconnect the item hook on stop //
--// Fixed map watcher: listens on Map.Ingame so ESP restarts every round //
--// Fixed plant watcher: rebinds on new Map.Ingame //
--// Fixed minions: rebind and rescan every round //

pcall(function()
    local tabESP = Window:Tab({ Title = "ESP", Icon = "eye" })
    local lp = LocalPlayer

    local svc = {
        Players = Players,
        WS      = workspace,
        Run     = RunService,
    }

    local esp = {
        enabled = true,
        highlights = {},
        billboards = {},
        connections = {},
        healthConnections = {},
        scanThread = nil,
        labelThread = nil,
        labelCache = {},
        showKillers = true,
        showSurvivors = true,
        showGenerators = true,
        showItems = true,
        showStructures = true,
        maxDistance = 400,
        transparency = 0.5,
        scanRate = 0.75,
    }

    local _cuiRoot = nil
    local _cuiFolder = nil

    local lp = game:GetService("Players").LocalPlayer
    local function getUIRoot()
        local ok, hui = pcall(function() return gethui and gethui() or nil end)
        if ok and hui then return hui end
        local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
        if ok2 and cg then return cg end
        return lp:FindFirstChild("PlayerGui")
    end

    local function getUIFolder()
        if _cuiFolder and _cuiFolder.Parent then return _cuiFolder end
        _cuiRoot = _cuiRoot or getUIRoot()
        if not _cuiRoot then return nil end
        local existing = _cuiRoot:FindFirstChild("V1PR_ESP_Holder")
        if existing then
            _cuiFolder = existing
        else
            local f = Instance.new("Folder")
            f.Name = "V1PR_ESP_Holder"
            pcall(function() f.Parent = _cuiRoot end)
            _cuiFolder = f
        end
        return _cuiFolder
    end

    local function ingameFolder()
        local m = svc.WS:FindFirstChild("Map")
        return m and m:FindFirstChild("Ingame")
    end

    local function mapContent()
        local ig = ingameFolder()
        return ig and ig:FindFirstChild("Map")
    end

    local function onIngameAdded(cb)
        local function hookMap(m)
            m.ChildAdded:Connect(function(c)
                if c.Name == "Ingame" then cb() end
            end)
        end
        local m = svc.WS:FindFirstChild("Map")
        if m then hookMap(m) end
        svc.WS.ChildAdded:Connect(function(c)
            if c.Name == "Map" then
                hookMap(c)
                task.wait(0.5)
                if c:FindFirstChild("Ingame") then cb() end
            end
        end)
    end

    local function getTeam(name)
        local root = svc.WS:FindFirstChild("Players")
        return root and root:FindFirstChild(name)
    end

    local espColors = {
        killer = Color3.fromRGB(255, 50, 50),
        survivor = Color3.fromRGB(50, 255, 50),
        generator = Color3.fromRGB(255, 200, 50),
        item = Color3.fromRGB(50, 200, 255),
        structure = Color3.fromRGB(255, 150, 50),
    }

    local genLabels = {}
    local genConns = {}

    local function readProg(obj)
        if not obj or not obj.Parent then return 0 end
        local pv = obj:FindFirstChild("Progress")
        if pv and (pv:IsA("NumberValue") or pv:IsA("IntValue")) then return pv.Value end
        local av = obj:GetAttribute("Progress") or obj:GetAttribute("Charge")
        if type(av) == "number" then return av end
        return 0
    end

    local function fmtGen(progress)
        local pct = math.floor(progress)
        local col = (pct >= 100) and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 200, 50)
        return string.format("Generator | %d%%", pct), col
    end

    local function cleanGen(obj)
        if genConns[obj] then
            for _, c in ipairs(genConns[obj]) do pcall(function() c:Disconnect() end) end
            genConns[obj] = nil
        end
        genLabels[obj] = nil
    end

    local function refreshGen(obj)
        if not obj or not obj.Parent then return end
        local progress = readProg(obj)
        if progress >= 100 then
            if esp.highlights[obj] then pcall(function() esp.highlights[obj]:Destroy() end) esp.highlights[obj] = nil end
            if esp.billboards[obj] then pcall(function() esp.billboards[obj]:Destroy() end) esp.billboards[obj] = nil end
            cleanGen(obj)
            return
        end
        local label = genLabels[obj]
        if not label or not label.Parent then
            --// Try the tracked billboard first (set by addTarget), then fall back to a child search //
            local bb = esp.billboards[obj] or obj:FindFirstChildWhichIsA("BillboardGui")
            if bb then
                label = bb:FindFirstChildWhichIsA("TextLabel")
            end
            if label then
                --// Make sure the billboard is configured for generator display //
                local bb2 = label.Parent
                if bb2 and bb2:IsA("BillboardGui") then
                    bb2.Enabled       = true
                    bb2.AlwaysOnTop   = true
                    bb2.Size          = UDim2.new(0, 160, 0, 18)
                    bb2.StudsOffset   = Vector3.new(0, 4, 0)
                    bb2.MaxDistance   = esp.maxDistance
                end
                genLabels[obj] = label
            else
                return  --// billboard not ready yet, will be called again on next attribute change //
            end
        end
        local txt, col = fmtGen(progress)
        label.Text = txt
        label.TextColor3 = col
        label.TextSize = 10
        label.Font = Enum.Font.Code
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.TextStrokeTransparency = 0.5
        label.Visible = true
    end

    local function watchGen(obj)
        if not obj then return end
        if genConns[obj] then
            for _, c in ipairs(genConns[obj]) do pcall(function() c:Disconnect() end) end
            genConns[obj] = nil
        end
        local conns = {}
        local pv = obj:FindFirstChild("Progress")
        if pv and (pv:IsA("NumberValue") or pv:IsA("IntValue")) then
            table.insert(conns, pv:GetPropertyChangedSignal("Value"):Connect(function()
                pcall(refreshGen, obj)
            end))
        end
        table.insert(conns, obj.ChildAdded:Connect(function(c)
            if c.Name == "Progress" and (c:IsA("NumberValue") or c:IsA("IntValue")) then
                table.insert(conns, c:GetPropertyChangedSignal("Value"):Connect(function()
                    pcall(refreshGen, obj)
                end))
                pcall(refreshGen, obj)
            end
        end))
        table.insert(conns, obj.AttributeChanged:Connect(function(a)
            if a == "Progress" or a == "Charge" then pcall(refreshGen, obj) end
        end))
        genConns[obj] = conns
        --// Deferred so addTarget has time to parent the BillboardGui before we try to find it //
        task.defer(function() pcall(refreshGen, obj) end)
        task.delay(0.2, function() pcall(refreshGen, obj) end)
    end

    local function setupGen(obj, label)
        if not obj or not label then return end
        genLabels[obj] = label
        local bb = label.Parent
        if bb and bb:IsA("BillboardGui") then
            bb.Enabled = true
            bb.AlwaysOnTop = true
            bb.Size = UDim2.new(0, 160, 0, 18)
            bb.StudsOffset = Vector3.new(0, 4, 0)
        end
        local txt, col = fmtGen(readProg(obj))
        label.Text = txt
        label.TextColor3 = col
        label.TextSize = 10
        label.Font = Enum.Font.Code
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.TextStrokeTransparency = 0.5
        label.Visible = true
        watchGen(obj)
    end

    local function wipeGens()
        for obj in pairs(genConns) do
            for _, c in ipairs(genConns[obj]) do pcall(function() c:Disconnect() end) end
        end
        genLabels = {}
        genConns = {}
    end

    local function makeHl(obj, color)
        if not obj or not obj.Parent then return nil end
        local folder = getUIFolder()
        if not folder then return nil end
        local hl = Instance.new("Highlight")
        hl.Name = "V1PR_Highlight"
        hl.FillColor = color
        hl.FillTransparency = esp.transparency
        hl.OutlineColor = color
        hl.OutlineTransparency = 0.1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = obj
        pcall(function() hl.Parent = folder end)
        return hl
    end

    local function isDup(obj)
        local p = obj and obj.Parent
        while p and p ~= svc.WS do
            if esp.highlights[p] then return true end
            p = p.Parent
        end
        return false
    end

    local function wipeESP()
        for _, hl in pairs(esp.highlights) do pcall(function() hl:Destroy() end) end
        esp.highlights = {}
        for _, bb in pairs(esp.billboards) do pcall(function() bb:Destroy() end) end
        esp.billboards = {}
        for _, c in pairs(esp.healthConnections) do pcall(function() c:Disconnect() end) end
        esp.healthConnections = {}
        for _, c in ipairs(esp.connections) do pcall(function() c:Disconnect() end) end
        esp.connections = {}
        esp.labelCache = {}
        wipeGens()
    end

    local function addTarget(obj, color, labelText, isChar)
        if not obj or not obj.Parent then return end
        if esp.highlights[obj] and esp.highlights[obj].Parent then return end
        if esp.highlights[obj] then
            pcall(function() esp.highlights[obj]:Destroy() end)
            esp.highlights[obj] = nil
        end
        if isDup(obj) then return end
        local attach = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
            or obj:FindFirstChildWhichIsA("BasePart") or obj:FindFirstChildOfClass("BasePart")
        if not attach then return end
        local hl = makeHl(obj, color)
        if not hl then return end
        local bb = Instance.new("BillboardGui")
        bb.Adornee = attach
        bb.Size = UDim2.new(0, 140, 0, 18)
        bb.StudsOffset = Vector3.new(0, 4, 0)
        bb.AlwaysOnTop = true
        bb.MaxDistance = esp.maxDistance
        bb.Parent = obj
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        if isChar then
            local plr = svc.Players:GetPlayerFromCharacter(obj)
            local uname = plr and plr.Name or obj.Name
            label.Text = uname .. " | " .. obj.Name
        else
            label.Text = labelText or obj.Name
        end
        label.TextColor3 = color
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.TextStrokeTransparency = 0.5
        label.TextSize = 10
        label.Font = Enum.Font.Code
        label.Parent = bb
        esp.highlights[obj] = hl
        esp.billboards[obj] = bb
        if labelText == "Generator" or (not isChar and obj.Name == "Generator") then
            if readProg(obj) >= 100 then
                pcall(function() hl:Destroy() end)
                pcall(function() bb:Destroy() end)
                esp.highlights[obj] = nil
                esp.billboards[obj] = nil
                return
            end
            setupGen(obj, label)
        end
        if isChar then
            local plr = svc.Players:GetPlayerFromCharacter(obj)
            esp.labelCache[obj] = {
                label = label,
                uname = plr and plr.Name or obj.Name,
                cname = obj.Name,
                hum = obj:FindFirstChildOfClass("Humanoid"),
                lastH = -1,
            }
            local anc
            anc = obj.AncestryChanged:Connect(function()
                if obj.Parent then return end
                if esp.highlights[obj] then pcall(function() esp.highlights[obj]:Destroy() end) end
                if esp.billboards[obj] then pcall(function() esp.billboards[obj]:Destroy() end) end
                if esp.healthConnections[obj] then pcall(function() esp.healthConnections[obj]:Disconnect() end) end
                cleanGen(obj)
                esp.highlights[obj] = nil
                esp.billboards[obj] = nil
                esp.healthConnections[obj] = nil
                esp.labelCache[obj] = nil
                pcall(function() anc:Disconnect() end)
            end)
        end
    end

    local function refreshLabel(obj, data)
        local hum, label = data.hum, data.label
        if not obj.Parent or not hum or not hum.Parent or not label or not label.Parent then
            esp.labelCache[obj] = nil
            return
        end
        if hum.Health > 0 then
            local hR = math.floor(hum.Health)
            if hR ~= data.lastH then
                data.lastH = hR
                label.Text = data.uname .. " | " .. data.cname .. " | " .. hR .. "Hp"
            end
        else
            if esp.highlights[obj] then pcall(function() esp.highlights[obj]:Destroy() end) esp.highlights[obj] = nil end
            if esp.billboards[obj] then pcall(function() esp.billboards[obj]:Destroy() end) esp.billboards[obj] = nil end
            if esp.healthConnections[obj] then pcall(function() esp.healthConnections[obj]:Disconnect() end) esp.healthConnections[obj] = nil end
            esp.labelCache[obj] = nil
        end
    end

    local function labelLoop()
        if esp.labelThread then return end
        esp.labelThread = svc.Run.Heartbeat:Connect(function()
            if not esp.enabled then return end
            for obj, data in pairs(esp.labelCache) do
                refreshLabel(obj, data)
            end
        end)
    end

    local function stopLabels()
        if esp.labelThread then
            esp.labelThread:Disconnect()
            esp.labelThread = nil
        end
    end

    local function pollTeams()
        if not esp.enabled or not lp then return end
        local myChar = lp.Character
        local dead = {}
        for obj in pairs(esp.highlights) do
            if not obj or not obj.Parent then table.insert(dead, obj) end
        end
        for _, obj in ipairs(dead) do
            if esp.highlights[obj] then pcall(function() esp.highlights[obj]:Destroy() end) end
            if esp.billboards[obj] then pcall(function() esp.billboards[obj]:Destroy() end) end
            if esp.healthConnections[obj] then pcall(function() esp.healthConnections[obj]:Disconnect() end) end
            cleanGen(obj)
            esp.highlights[obj] = nil
            esp.billboards[obj] = nil
            esp.healthConnections[obj] = nil
            esp.labelCache[obj] = nil
        end
        local function addPlayer(obj, color, label)
            if not obj or not obj.Parent or esp.highlights[obj] then return end
            if obj == myChar then return end
            local h = obj:FindFirstChildOfClass("Humanoid")
            if not h or h.Health <= 0 then return end
            addTarget(obj, color, label, true)
        end
        if esp.showKillers then
            local kf = getTeam("Killers")
            if kf then
                for _, m in ipairs(kf:GetChildren()) do
                    if m:IsA("Model") then addPlayer(m, espColors.killer, m.Name) end
                end
            end
        end
        if esp.showSurvivors then
            local sf = getTeam("Survivors")
            if sf then
                for _, m in ipairs(sf:GetChildren()) do
                    if m:IsA("Model") then addPlayer(m, espColors.survivor, m.Name) end
                end
            end
        end
        if esp.showGenerators then
            local mc = mapContent() or ingameFolder()
            if mc then
                for _, o in ipairs(mc:GetChildren()) do
                    if o.Name == "Generator" and o.Parent and not esp.highlights[o] then
                        if readProg(o) < 100 then
                            addTarget(o, espColors.generator, "Generator")
                        end
                    end
                end
            end
        end
    end

    local function isItemName(n) return n == "BloxyCola" or n == "Medkit" end

    local function hookItems()
        if esp._itemHook then return end
        esp._itemHook = svc.WS.DescendantAdded:Connect(function(o)
            if not esp.enabled or not esp.showItems or not isItemName(o.Name) then return end
            task.defer(function()
                if esp.enabled and o.Parent and not esp.highlights[o] then
                    addTarget(o, espColors.item, o.Name)
                end
            end)
        end)
    end

    local function unhookItems()
        if esp._itemHook then pcall(function() esp._itemHook:Disconnect() end) esp._itemHook = nil end
    end

    local function scanItems()
        task.spawn(function()
            local root = svc.WS
            local stack = { root }
            local steps = 0
            while #stack > 0 and esp.enabled and esp.showItems do
                local cur = table.remove(stack)
                for _, c in ipairs(cur:GetChildren()) do
                    local nm = c.Name
                    if isItemName(nm) then
                        if not esp.highlights[c] then pcall(addTarget, c, espColors.item, nm) end
                    elseif not c:IsA("BasePart") and not (cur == root and (nm == "Players" or c:IsA("Terrain") or c:IsA("Camera"))) then
                        table.insert(stack, c)
                    end
                    steps += 1
                    if steps % 300 == 0 then task.wait() end
                end
            end
        end)
    end

    local function bindIngame()
        if not lp then return end
        local function removeObj(obj)
            if esp.highlights[obj] then pcall(function() esp.highlights[obj]:Destroy() end) end
            if esp.billboards[obj] then pcall(function() esp.billboards[obj]:Destroy() end) end
            if esp.healthConnections[obj] then pcall(function() esp.healthConnections[obj]:Disconnect() end) end
            cleanGen(obj)
            esp.highlights[obj] = nil
            esp.billboards[obj] = nil
            esp.healthConnections[obj] = nil
            esp.labelCache[obj] = nil
        end
        local ig = ingameFolder()
        if ig then
            table.insert(esp.connections, ig.DescendantAdded:Connect(function(o)
                if not esp.enabled then return end
                if o.Name == "Generator" and esp.showGenerators then
                    task.defer(function()
                        if esp.enabled and o.Parent and not esp.highlights[o] and readProg(o) < 100 then
                            addTarget(o, espColors.generator, "Generator")
                        end
                    end)
                elseif esp.showStructures and (o.Name == "BuildermanSentry"
                    or o.Name == "SubspaceTripmine" or o.Name == "BuildermanDispenser") then
                    task.defer(function()
                        if esp.enabled and o.Parent and not esp.highlights[o] then
                            local tag = (o.Name == "BuildermanSentry" and "Sentry")
                                or (o.Name == "BuildermanDispenser" and "Dispenser")
                                or (o.Name == "SubspaceTripmine" and "Tripmine")
                                or o.Name
                            addTarget(o, espColors.structure, tag)
                        end
                    end)
                end
            end))
            table.insert(esp.connections, ig.DescendantRemoving:Connect(function(o)
                if not (esp.highlights[o] or esp.billboards[o]) then return end
                task.delay(0.5, function()
                    if o and o.Parent then return end
                    removeObj(o)
                end)
            end))
        end
    end

    local function startESP()
        wipeESP()
        esp.enabled = true
        labelLoop()
        pcall(bindIngame)
        pcall(hookItems)
        pcall(pollTeams)
        if esp.showItems then scanItems() end
        task.defer(function()
            if not esp.enabled then return end
            local ig = ingameFolder()
            if not ig then return end
            for _, o in ipairs(ig:GetDescendants()) do
                if not esp.enabled then return end
                if o.Name == "Generator" and esp.showGenerators then
                    if not esp.highlights[o] and readProg(o) < 100 then
                        addTarget(o, espColors.generator, "Generator")
                    end
                elseif esp.showStructures and (o.Name == "BuildermanSentry"
                    or o.Name == "SubspaceTripmine" or o.Name == "BuildermanDispenser") then
                    if not esp.highlights[o] then
                        local tag = (o.Name == "BuildermanSentry" and "Sentry")
                            or (o.Name == "BuildermanDispenser" and "Dispenser")
                            or (o.Name == "SubspaceTripmine" and "Tripmine")
                            or o.Name
                        addTarget(o, espColors.structure, tag)
                    end
                end
            end
        end)
        if esp.scanThread then task.cancel(esp.scanThread) end
        esp.scanThread = task.spawn(function()
            while esp.enabled do
                pcall(pollTeams)
                task.wait(esp.scanRate)
            end
            esp.scanThread = nil
        end)
    end

    local function stopESP()
        esp.enabled = false
        unhookItems()
        if esp.scanThread then task.cancel(esp.scanThread) end
        esp.scanThread = nil
        stopLabels()
        wipeESP()
    end

    if not esp._mapWatch then
        esp._mapWatch = true
        onIngameAdded(function()
            if not esp.enabled then return end
            task.wait(1.5)
            if esp.enabled then pcall(startESP) end
        end)
    end

    local plantOpts = {
        groundbulb = true,
        vine = true,
        hlColor = Color3.fromRGB(170, 0, 255),
        fillAlpha = 0.4,
        lineAlpha = 0.1,
    }

    local plant = {
        enabled = false,
        tracked = {},
        objects = {},
        addConn = nil,
        rmConn = nil,
        watchConn = nil,
    }

    local function topPart(model)
        local best = model.PrimaryPart
        local y = best and best.Position.Y or -math.huge
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("BasePart") then
                if d.Name:find("Flower") or d.Position.Y > y then
                    y = d.Position.Y
                    best = d
                end
            end
        end
        return best
    end

    local function markPlant(model, displayName)
        if not model or not model:IsA("Model") then return end
        if plant.tracked[model] then return end
        for _, child in ipairs(model:GetChildren()) do
            if child:IsA("Highlight") then child:Destroy() end
        end
        local oldHl = model:FindFirstChild("GvHighlight")
        if oldHl then oldHl:Destroy() end
        local oldBb = model:FindFirstChild("GvTag")
        if oldBb then oldBb:Destroy() end
        local attach = topPart(model)
        if not attach then
            for _, d in ipairs(model:GetDescendants()) do
                if d:IsA("BasePart") and d.Name ~= "Handle" then attach = d; break end
            end
        end
        if not attach then return end
        if not model.PrimaryPart then model.PrimaryPart = attach end
        local hl = Instance.new("Highlight")
        hl.Name = "GvHighlight"
        hl.Adornee = model
        hl.FillColor = plantOpts.hlColor
        hl.FillTransparency = plantOpts.fillAlpha
        hl.OutlineColor = plantOpts.hlColor
        hl.OutlineTransparency = plantOpts.lineAlpha
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Enabled = true
        hl.Parent = model
        local bb = Instance.new("BillboardGui")
        bb.Name = "GvTag"
        bb.Size = UDim2.new(0, 160, 0, 22)
        bb.Adornee = attach
        bb.StudsOffset = Vector3.new(0, 0.5, 0)
        bb.MaxDistance = 150
        bb.AlwaysOnTop = true
        bb.Parent = model
        local lbl = Instance.new("TextLabel")
        lbl.Name = "Label"
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = displayName
        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        lbl.TextStrokeTransparency = 0.5
        lbl.Font = Enum.Font.Code
        lbl.TextSize = 11
        lbl.Parent = bb
        plant.tracked[model] = true
        plant.objects[model] = { highlight = hl, billboard = bb }
    end

    local function checkPlant(child)
        if not child:IsA("Model") then return end
        local n = child.Name:lower()
        if n == "groundbulbmodel" then
            if plantOpts.groundbulb and not plant.tracked[child] then markPlant(child, "GroundBulb") end
        elseif n == "vinemodel" then
            if plantOpts.vine and not plant.tracked[child] then markPlant(child, "Vine") end
        end
    end

    local function clearPlant(model)
        if plant.objects[model] then
            if plant.objects[model].highlight then pcall(function() plant.objects[model].highlight:Destroy() end) end
            if plant.objects[model].billboard then pcall(function() plant.objects[model].billboard:Destroy() end) end
            plant.objects[model] = nil
        end
        plant.tracked[model] = nil
    end

    local function bindPlants()
        for model in pairs(plant.tracked) do
            if not model or not model.Parent then clearPlant(model) end
        end
        local ig = ingameFolder()
        if not ig then return false end
        if plant.addConn then plant.addConn:Disconnect() plant.addConn = nil end
        if plant.rmConn then plant.rmConn:Disconnect() plant.rmConn = nil end
        for _, obj in ipairs(ig:GetDescendants()) do
            if obj:IsA("Model") then checkPlant(obj) end
        end
        plant.addConn = ig.DescendantAdded:Connect(function(child)
            if plant.enabled and child:IsA("Model") then
                task.defer(function()
                    if plant.enabled and child.Parent then checkPlant(child) end
                end)
            end
        end)
        plant.rmConn = ig.DescendantRemoving:Connect(function(child)
            if plant.tracked[child] then clearPlant(child) end
        end)
        return true
    end

    local function startPlants()
        if plant.enabled then return end
        plant.enabled = true
        bindPlants()
        if not plant._mapWatch then
            plant._mapWatch = true
            onIngameAdded(function()
                if not plant.enabled then return end
                task.wait(1)
                if plant.enabled then bindPlants() end
            end)
        end
    end

    local function stopPlants()
        plant.enabled = false
        if plant.addConn then plant.addConn:Disconnect() plant.addConn = nil end
        if plant.rmConn then plant.rmConn:Disconnect() plant.rmConn = nil end
        if plant.watchConn then plant.watchConn:Disconnect() plant.watchConn = nil end
        for _, data in pairs(plant.objects) do
            if data.highlight then pcall(function() data.highlight:Destroy() end) end
            if data.billboard then pcall(function() data.billboard:Destroy() end) end
        end
        plant.objects = {}
        plant.tracked = {}
    end

    local mobOpts = { pizza = false, zombie = false, puddle = false, alpha = 0.25 }
    local mobTrack = { pizza = {}, zombie = {}, puddle = {} }

    local function isPlayer(obj)
        for _, p in ipairs(svc.Players:GetPlayers()) do
            if p.Character == obj or (p.Character and obj:IsDescendantOf(p.Character)) then return true end
        end
        return false
    end

    local function syncMobAlpha()
        for tag, tbl in pairs(mobTrack) do
            for obj in pairs(tbl) do
                local h = obj:FindFirstChild(tag .. "_HL")
                if h then h.FillTransparency = mobOpts.alpha end
            end
        end
    end

    local function clearMob(tag)
        for obj in pairs(mobTrack[tag]) do
            local h = obj:FindFirstChild(tag .. "_HL")
            if h then h:Destroy() end
            local b = obj:FindFirstChild(tag .. "_BB")
            if b then b:Destroy() end
            if tag == "puddle" then
                local h2 = obj:FindFirstChild("PuddleHolder")
                if h2 then h2:Destroy() end
            end
        end
        mobTrack[tag] = {}
    end

    local function markMob(obj, color, tag, label, offset)
        if not obj or mobTrack[tag][obj] or isPlayer(obj) then return end
        mobTrack[tag][obj] = true
        local root = obj
        if obj:IsA("Model") then
            root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj.PrimaryPart
            if not root then
                for _, c in ipairs(obj:GetChildren()) do
                    if c:IsA("BasePart") then root = c; break end
                end
            end
        end
        local hl = Instance.new("Highlight")
        hl.Name = tag .. "_HL"
        hl.FillColor = color
        hl.FillTransparency = mobOpts.alpha
        hl.OutlineColor = color
        hl.OutlineTransparency = 0.1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = obj
        hl.Parent = obj
        if root then
            local bb = Instance.new("BillboardGui")
            bb.Name = tag .. "_BB"
            bb.Adornee = root
            bb.Size = UDim2.new(0, 140, 0, 20)
            bb.StudsOffset = Vector3.new(0, offset or 3, 0)
            bb.AlwaysOnTop = true
            bb.Parent = obj
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = label
            lbl.TextColor3 = color
            lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            lbl.TextStrokeTransparency = 0.5
            lbl.TextSize = 11
            lbl.Font = Enum.Font.Code
            lbl.Parent = bb
        end
        obj.AncestryChanged:Connect(function()
            if obj.Parent then return end
            local h2 = obj:FindFirstChild(tag .. "_HL")
            if h2 then h2:Destroy() end
            local b2 = obj:FindFirstChild(tag .. "_BB")
            if b2 then b2:Destroy() end
            mobTrack[tag][obj] = nil
        end)
    end

    local function markPuddle(part, color, tag, label)
        if not part or mobTrack[tag][part] or isPlayer(part) then return end
        mobTrack[tag][part] = true
        local hl = Instance.new("Highlight")
        hl.Name = tag .. "_HL"
        hl.FillColor = color
        hl.FillTransparency = mobOpts.alpha
        hl.OutlineColor = color
        hl.OutlineTransparency = 0.1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = part
        hl.Parent = part
        task.wait(0.05)
        local radius = math.max(math.max(part.Size.X, part.Size.Z) * 0.5, 3)
        local holder = Instance.new("Part")
        holder.Name = "PuddleHolder"
        holder.Size = Vector3.new(1, 0.1, 1)
        holder.Transparency = 1
        holder.CanCollide = false
        holder.Anchored = true
        holder.Position = part.Position + Vector3.new(0, 0.05, 0)
        holder.Parent = part
        local bc = Instance.new("CylinderHandleAdornment")
        bc.Name = "PuddleBlack"
        bc.Adornee = holder
        bc.Color3 = Color3.fromRGB(0, 0, 0)
        bc.Transparency = 0.2
        bc.Radius = radius
        bc.Height = 0.02
        bc.CFrame = CFrame.Angles(math.rad(90), 0, 0)
        bc.ZIndex = 5
        bc.AlwaysOnTop = true
        bc.Parent = holder
        local ro = Instance.new("CylinderHandleAdornment")
        ro.Name = "PuddleRed"
        ro.Adornee = holder
        ro.Color3 = Color3.fromRGB(255, 0, 0)
        ro.Transparency = 0.4
        ro.Radius = radius + 0.8
        ro.Height = 0.02
        ro.CFrame = CFrame.Angles(math.rad(90), 0, 0)
        ro.ZIndex = 4
        ro.AlwaysOnTop = true
        ro.Parent = holder
        local bb = Instance.new("BillboardGui")
        bb.Name = tag .. "_BB"
        bb.Adornee = holder
        bb.Size = UDim2.new(0, 130, 0, 18)
        bb.StudsOffset = Vector3.new(0, 1.5, 0)
        bb.AlwaysOnTop = true
        bb.Parent = holder
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        lbl.TextStrokeTransparency = 0.5
        lbl.TextSize = 10
        lbl.Font = Enum.Font.Code
        lbl.Parent = bb
        part:GetPropertyChangedSignal("Size"):Connect(function()
            if not part.Parent then return end
            local nr = math.max(math.max(part.Size.X, part.Size.Z) * 0.5, 3)
            bc.Radius = nr
            ro.Radius = nr + 0.8
        end)
        part.AncestryChanged:Connect(function()
            if part.Parent then return end
            hl:Destroy()
            holder:Destroy()
            mobTrack[tag][part] = nil
        end)
    end

    local function isJDPuddle(o)
        if not o:IsA("BasePart") or o.Name ~= "Shadow" then return false end
        local p = o.Parent
        return p and p.Name:find("Shadows$") ~= nil
    end

    local function findPizza()
        if not mobOpts.pizza then return end
        local ig = ingameFolder()
        if not ig then return end
        for _, o in ipairs(ig:GetDescendants()) do
            if o.Name == "PizzaDeliveryRig" and o:IsA("Model") and not isPlayer(o) and not mobTrack.pizza[o] then
                markMob(o, Color3.fromRGB(255, 100, 0), "pizza", "PizzaMinion", 3)
            end
        end
    end

    local function findZombies()
        if not mobOpts.zombie then return end
        local ig = ingameFolder()
        if not ig then return end
        for _, o in ipairs(ig:GetDescendants()) do
            if o.Name == "1x1x1x1Zombie" and o:IsA("Model") and not isPlayer(o) and not mobTrack.zombie[o] then
                markMob(o, Color3.fromRGB(80, 255, 120), "zombie", "ZombieMinion", 3)
            end
        end
    end

    local function findPuddles()
        if not mobOpts.puddle then return end
        local ig = ingameFolder()
        if not ig then return end
        for _, o in ipairs(ig:GetDescendants()) do
            if isJDPuddle(o) and not mobTrack.puddle[o] then
                markPuddle(o, Color3.fromRGB(255, 50, 50), "puddle", "DigitalFootprint")
            end
        end
    end

    local function bindMobs()
        local ig = ingameFolder()
        if not ig then return end
        ig.DescendantAdded:Connect(function(o)
            if o.Name == "PizzaDeliveryRig" and o:IsA("Model") then
                if mobOpts.pizza and not isPlayer(o) and not mobTrack.pizza[o] then
                    markMob(o, Color3.fromRGB(255, 100, 0), "pizza", "PizzaMinion", 3)
                end
            elseif o.Name == "1x1x1x1Zombie" and o:IsA("Model") then
                if mobOpts.zombie and not isPlayer(o) and not mobTrack.zombie[o] then
                    markMob(o, Color3.fromRGB(80, 255, 120), "zombie", "ZombieMinion", 3)
                end
            elseif isJDPuddle(o) then
                if mobOpts.puddle and not mobTrack.puddle[o] then
                    markPuddle(o, Color3.fromRGB(255, 50, 50), "puddle", "DigitalFootprint")
                end
            end
        end)
    end
    bindMobs()
    onIngameAdded(function()
        task.wait(1)
        bindMobs()
        findPizza() findZombies() findPuddles()
    end)

    local mainSection
    pcall(function() mainSection = tabESP:Section({ Title = "Main Settings", Opened = true }) end)
    pcall(function() if mainSection then mainSection:Toggle({ Title = "Enable ESP", Type = "Checkbox", Flag = "espEnabled", Default = esp.enabled, Callback = function(on) esp.enabled = on if on then startESP() else stopESP() end end }) end end)

    local catSection
    pcall(function() catSection = tabESP:Section({ Title = "Categories", Opened = true }) end)
    pcall(function() if catSection then catSection:Toggle({ Title = "Killers", Type = "Checkbox", Flag = "espKillers", Default = esp.showKillers, Callback = function(on) esp.showKillers = on if esp.enabled then startESP() end end }) end end)
    pcall(function() if catSection then catSection:Toggle({ Title = "Survivors", Type = "Checkbox", Flag = "espSurvivors", Default = esp.showSurvivors, Callback = function(on) esp.showSurvivors = on if esp.enabled then startESP() end end }) end end)
    pcall(function() if catSection then catSection:Toggle({ Title = "Generators", Type = "Checkbox", Flag = "espGenerators", Default = esp.showGenerators, Callback = function(on) esp.showGenerators = on if esp.enabled then startESP() end end }) end end)
    pcall(function() if catSection then catSection:Toggle({ Title = "Items", Type = "Checkbox", Flag = "espItems", Default = esp.showItems, Callback = function(on) esp.showItems = on if esp.enabled then startESP() end end }) end end)
    pcall(function() if catSection then catSection:Toggle({ Title = "Structures", Type = "Checkbox", Flag = "espStructures", Default = esp.showStructures, Callback = function(on) esp.showStructures = on if esp.enabled then startESP() end end }) end end)
    pcall(function() if catSection then catSection:Toggle({ Title = "Groundbulb & Vine", Type = "Checkbox", Flag = "gvEspOn", Default = plant.enabled, Callback = function(on) if on then startPlants() else stopPlants() end end }) end end)

    local secPlants
    pcall(function() secPlants = tabESP:Section({ Title = "Groundbulb & Vine Settings", Opened = false }) end)
    pcall(function() if secPlants then secPlants:Toggle({ Title = "Show Groundbulb", Type = "Checkbox", Flag = "gvShowGroundbulb", Default = plantOpts.groundbulb, Callback = function(on) plantOpts.groundbulb = on end }) end end)
    pcall(function() if secPlants then secPlants:Toggle({ Title = "Show Vine", Type = "Checkbox", Flag = "gvShowVine", Default = plantOpts.vine, Callback = function(on) plantOpts.vine = on end }) end end)
    pcall(function() if secPlants then secPlants:Slider({ Title = "Highlight Transparency", Flag = "gvTransparency", Step = 0.05, Value = { Min = 0.1, Max = 1.0, Default = plantOpts.fillAlpha }, Callback = function(v) plantOpts.fillAlpha = v for _, data in pairs(plant.objects) do if data.highlight and data.highlight.Parent then data.highlight.FillTransparency = v end end end }) end end)
    pcall(function() if secPlants then secPlants:Button({ Title = "Refresh ESP", Callback = function() if plant.enabled then stopPlants() task.wait(0.1) startPlants() end end }) end end)
    pcall(function() if secPlants then secPlants:Button({ Title = "Clear All Highlights", Callback = function() stopPlants() plant.tracked = {} plant.objects = {} end }) end end)

    local visSection
    pcall(function() visSection = tabESP:Section({ Title = "Visual Settings", Opened = true }) end)
    pcall(function() if visSection then visSection:Slider({ Title = "Max Distance", Flag = "espMaxDistance", Step = 10, Value = { Min = 50, Max = 1000, Default = esp.maxDistance }, Callback = function(v) esp.maxDistance = v if esp.enabled then startESP() end end }) end end)
    pcall(function() if visSection then visSection:Slider({ Title = "Highlight Opacity", Flag = "espTransparency", Step = 0.05, Value = { Min = 0.1, Max = 1.0, Default = esp.transparency }, Callback = function(v) esp.transparency = v if esp.enabled then startESP() end end }) end end)
    pcall(function() if visSection then visSection:Button({ Title = "Refresh ESP", Callback = function() if esp.enabled then startESP() end end }) end end)
    pcall(function() if visSection then visSection:Button({ Title = "Refresh Generator Labels", Callback = function()
        for obj in pairs(genLabels) do
            if obj and obj.Parent then watchGen(obj) else cleanGen(obj) end
        end
        local ig = ingameFolder()
        if ig then
            for _, o in ipairs(ig:GetChildren()) do
                if o.Name == "Generator" and o.Parent and readProg(o) < 100 then
                    if not genLabels[o] then
                        if esp.enabled and not esp.highlights[o] then addTarget(o, espColors.generator, "Generator") end
                    else
                        watchGen(o)
                    end
                end
            end
        end
    end }) end end)

    local secMobs
    pcall(function() secMobs = tabESP:Section({ Title = "Minion & Ability ESP", Opened = true }) end)
    pcall(function() if secMobs then secMobs:Toggle({ Title = "c00lkidd Pizza Bots", Type = "Checkbox", Flag = "espPizza", Default = mobOpts.pizza, Callback = function(on) mobOpts.pizza = on if on then findPizza() else clearMob("pizza") end end }) end end)
    pcall(function() if secMobs then secMobs:Toggle({ Title = "1x1x1x1 Zombies", Type = "Checkbox", Flag = "espZombie", Default = mobOpts.zombie, Callback = function(on) mobOpts.zombie = on if on then findZombies() else clearMob("zombie") end end }) end end)
    pcall(function() if secMobs then secMobs:Toggle({ Title = "JD Digital Footprints", Type = "Checkbox", Flag = "espPuddle", Default = mobOpts.puddle, Callback = function(on) mobOpts.puddle = on if on then findPuddles() else clearMob("puddle") end end }) end end)
    pcall(function() if secMobs then secMobs:Slider({ Title = "Highlight Transparency", Flag = "espMinionTrans", Step = 0.05, Value = { Min = 0, Max = 1, Default = mobOpts.alpha }, Callback = function(v) mobOpts.alpha = v syncMobAlpha() end }) end end)
    pcall(function() if secMobs then secMobs:Button({ Title = "Force Rescan", Callback = function() clearMob("pizza") clearMob("zombie") clearMob("puddle") task.wait(0.1) findPizza() findZombies() findPuddles() end }) end end)

    getgenv()._flexsakenESP = {
        applyConfig = function()
            if not (Window and Window.Flags) then return end
            if Window.Flags.espEnabled ~= nil then
                esp.enabled = Window.Flags.espEnabled
                if esp.enabled then startESP() else stopESP() end
            end
            if Window.Flags.espKillers ~= nil then esp.showKillers = Window.Flags.espKillers end
            if Window.Flags.espSurvivors ~= nil then esp.showSurvivors = Window.Flags.espSurvivors end
            if Window.Flags.espGenerators ~= nil then esp.showGenerators = Window.Flags.espGenerators end
            if Window.Flags.espItems ~= nil then esp.showItems = Window.Flags.espItems end
            if Window.Flags.espStructures ~= nil then esp.showStructures = Window.Flags.espStructures end
            if type(Window.Flags.espMaxDistance) == "number" then esp.maxDistance = Window.Flags.espMaxDistance end
            if type(Window.Flags.espTransparency) == "number" then esp.transparency = Window.Flags.espTransparency end
            if Window.Flags.gvEspOn ~= nil then
                if Window.Flags.gvEspOn then startPlants() else stopPlants() end
            end
            if Window.Flags.gvShowGroundbulb ~= nil then plantOpts.groundbulb = Window.Flags.gvShowGroundbulb end
            if Window.Flags.gvShowVine ~= nil then plantOpts.vine = Window.Flags.gvShowVine end
            if type(Window.Flags.gvTransparency) == "number" then plantOpts.fillAlpha = Window.Flags.gvTransparency end
            if Window.Flags.espPizza ~= nil then mobOpts.pizza = Window.Flags.espPizza end
            if Window.Flags.espZombie ~= nil then mobOpts.zombie = Window.Flags.espZombie end
            if Window.Flags.espPuddle ~= nil then mobOpts.puddle = Window.Flags.espPuddle end
            if type(Window.Flags.espMinionTrans) == "number" then mobOpts.alpha = Window.Flags.espMinionTrans syncMobAlpha() end
        end,
    }

    if esp.enabled then task.wait(2) startESP() end

    --// Candy ESP (c00lkidd candy) - original by luna <3 //
    do
        local Candy = { Enabled = false, Tracked = {}, Thread = nil, AddedConnection = nil }

        local function CandyCleanup(Model)
            local Data = Candy.Tracked[Model]
            if not Data then return end
            if Data.Highlight then pcall(function() Data.Highlight:Destroy() end) end
            if Data.Billboard then pcall(function() Data.Billboard:Destroy() end) end
            Candy.Tracked[Model] = nil
        end

        local function CandyAttach(Model)
            if not Model or not Model.Parent or Candy.Tracked[Model] then return end
            local Part = Model:FindFirstChildWhichIsA("BasePart", true)
            if not Part then return end
            local Highlight = Instance.new("Highlight")
            Highlight.Name = "FlexSakenCandyHL"
            Highlight.FillColor = Color3.fromRGB(220, 20, 60)
            Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            Highlight.FillTransparency = 0.35
            Highlight.OutlineTransparency = 0
            Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            Highlight.Adornee = Model
            Highlight.Parent = Model
            local Billboard = Instance.new("BillboardGui")
            Billboard.Name = "FlexSakenCandyTag"
            Billboard.Size = UDim2.new(0, 110, 0, 18)
            Billboard.StudsOffset = Vector3.new(0, 2, 0)
            Billboard.AlwaysOnTop = true
            Billboard.MaxDistance = 9999
            Billboard.Adornee = Part
            Billboard.Parent = Model
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, 0, 1, 0)
            Label.BackgroundTransparency = 1
            Label.Text = "Candy"
            Label.TextColor3 = Color3.fromRGB(220, 20, 60)
            Label.TextStrokeColor3 = Color3.new(0, 0, 0)
            Label.TextStrokeTransparency = 0.2
            Label.TextSize = 14
            Label.Font = Enum.Font.GothamBold
            Label.Parent = Billboard
            Candy.Tracked[Model] = { Highlight = Highlight, Billboard = Billboard, Label = Label, Part = Part }
        end

        local function CandyScan()
            if not Candy.Enabled then return end
            for Model in pairs(Candy.Tracked) do
                if not Model.Parent then CandyCleanup(Model) end
            end
            local MapFolder = svc.WS:FindFirstChild("Map")
            local Ingame = MapFolder and MapFolder:FindFirstChild("Ingame")
            local InnerMap = Ingame and Ingame:FindFirstChild("Map")
            local Spawns = InnerMap and InnerMap:FindFirstChild("CurrencySpawns")
            if Spawns then
                for _, Object in ipairs(Spawns:GetChildren()) do
                    if Object.Name == "C00lCandy" and Object:IsA("Model") then CandyAttach(Object) end
                end
            end
            local Root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if Root then
                for _, Data in pairs(Candy.Tracked) do
                    if Data.Part and Data.Part.Parent and Data.Label then
                        Data.Label.Text = "Candy [" .. math.floor((Data.Part.Position - Root.Position).Magnitude) .. "]"
                    end
                end
            end
        end

        local function CandyStart()
            Candy.Enabled = true
            if Candy.AddedConnection then Candy.AddedConnection:Disconnect() end
            Candy.AddedConnection = svc.WS.DescendantAdded:Connect(function(Object)
                if Candy.Enabled and Object.Name == "C00lCandy" and Object:IsA("Model") then
                    task.wait(0.1)
                    CandyAttach(Object)
                end
            end)
            if Candy.Thread then task.cancel(Candy.Thread) end
            Candy.Thread = task.spawn(function()
                while Candy.Enabled do
                    pcall(CandyScan)
                    task.wait(0.5)
                end
            end)
        end

        local function CandyStop()
            Candy.Enabled = false
            if Candy.AddedConnection then Candy.AddedConnection:Disconnect(); Candy.AddedConnection = nil end
            if Candy.Thread then task.cancel(Candy.Thread); Candy.Thread = nil end
            for Model in pairs(Candy.Tracked) do CandyCleanup(Model) end
        end

        local SecCandy
        pcall(function() SecCandy = tabESP:Section({ Title = "Candy ESP", Opened = true }) end)
        pcall(function() if SecCandy then SecCandy:Toggle({ Title = "Candy ESP", Type = "Checkbox", Flag = "espCandy", Default = false,
            Callback = function(on) if on then CandyStart() else CandyStop() end end }) end end)
        pcall(function() if SecCandy then SecCandy:Button({ Title = "Force Rescan", Callback = function()
            if Candy.Enabled then pcall(CandyScan) end
        end }) end end)
    end

    --// Gear ESP //
    --// Credits: Luna/Emily //
    do
        local GEAR_PATH = { "Map", "Ingame", "Map", "GearsTest", "Gear" }
        local gearESP = { enabled = false, highlight = nil, billboard = nil, current = nil, conn = nil }

        local function gearResolvePath()
            local node = workspace
            for _, name in ipairs(GEAR_PATH) do
                node = node:FindFirstChild(name)
                if not node then return nil end
            end
            return node
        end

        local function gearCleanup()
            if gearESP.highlight and gearESP.highlight.Parent then pcall(function() gearESP.highlight:Destroy() end) end
            if gearESP.billboard and gearESP.billboard.Parent then pcall(function() gearESP.billboard:Destroy() end) end
            gearESP.highlight = nil; gearESP.billboard = nil; gearESP.current = nil
        end

        local function gearMakeHighlight(gear)
            local hl = Instance.new("Highlight")
            hl.Name = "GrayGearHighlight"
            hl.FillColor = Color3.fromRGB(128, 128, 128)
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.FillTransparency = 0.4
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Adornee = gear
            hl.Parent = gear
            return hl
        end

        local function gearMakeBillboard(gear)
            local bb = Instance.new("BillboardGui")
            bb.Name = "GearLabel"
            bb.Size = UDim2.new(0, 60, 0, 20)
            bb.StudsOffset = Vector3.new(0, 1.5, 0)
            bb.AlwaysOnTop = true
            bb.MaxDistance = math.huge
            bb.Adornee = gear
            bb.Parent = gear
            local lbl = Instance.new("TextLabel")
            lbl.Name = "Label"
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = "Gear"
            lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            lbl.TextStrokeTransparency = 0
            lbl.TextScaled = false
            lbl.TextSize = 16
            lbl.Font = Enum.Font.GothamBlack
            lbl.Parent = bb
            Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 4)
            return bb
        end

        local function checkGear()
            if not gearESP.enabled then return end
            local gear = gearResolvePath()
            if gear then
                if gear ~= gearESP.current then
                    gearCleanup()
                    gearESP.current = gear
                    gearESP.highlight = gearMakeHighlight(gear)
                    gearESP.billboard = gearMakeBillboard(gear)
                end
            else
                if gearESP.current then gearCleanup() end
            end
        end

        local function startGearESP()
            if gearESP.enabled then return end
            gearESP.enabled = true
            if gearESP.conn then pcall(function() gearESP.conn:Disconnect() end) end
            gearESP.conn = RunService.Heartbeat:Connect(checkGear)
            checkGear()
        end

        local function stopGearESP()
            gearESP.enabled = false
            if gearESP.conn then pcall(function() gearESP.conn:Disconnect() end) gearESP.conn = nil end
            gearCleanup()
        end

        local secGear
        pcall(function() secGear = tabESP:Section({ Title = "Gear ESP", Opened = true }) end)
        pcall(function() if secGear then secGear:Toggle({ Title = "Gear ESP", Type = "Checkbox", Flag = "espGear", Default = false,
            Callback = function(on) if on then startGearESP() else stopGearESP() end end }) end end)
        pcall(function() if secGear then secGear:Button({ Title = "Force Rescan", Callback = function()
            if gearESP.enabled then gearCleanup() checkGear() end
        end }) end end)
    end
end)

--// MISC FEATURES //

local function CheckSlowness(ValueInstance)
    if not State.AntiSlowness or not ValueInstance or not ValueInstance:IsA("NumberValue") then return end
    local Name = ValueInstance.Name
    if Name == "Sprinting" or Name:lower() == "emoting" then return end
    if Name == "DirectionalMovement" or Name == "FixingGenerator" or Name:upper() == "ENRAGED" then
        if ValueInstance.Value < 1 then ValueInstance.Value = 1 end
        ValueInstance:GetPropertyChangedSignal("Value"):Connect(function() if ValueInstance.Value < 1 then ValueInstance.Value = 1 end end)
    elseif ValueInstance.Value > 0.03 and ValueInstance.Value < 1 then ValueInstance:Destroy()
    else ValueInstance:GetPropertyChangedSignal("Value"):Connect(function() if ValueInstance.Value > 0.03 and ValueInstance.Value < 1 then ValueInstance:Destroy() end end) end
end
local function SetAntiSlowness(Enabled) if Enabled and SpeedMultipliers then for _, Child in SpeedMultipliers:GetChildren() do CheckSlowness(Child) end end end
table.insert(CharacterCallbacks, function()
    if SpeedMultipliers then SpeedMultipliers.ChildAdded:Connect(CheckSlowness); SetAntiSlowness(State.AntiSlowness) end
end)

local function ApplyJumping()
    if not LocalHumanoid then return end
    if State.EnableJumping then
        if LocalHumanoid:GetAttribute("SAB_JumpPower") == nil then LocalHumanoid:SetAttribute("SAB_JumpPower", LocalHumanoid.JumpPower) end
        LocalHumanoid.UseJumpPower = true; LocalHumanoid.JumpPower = 47
    elseif LocalHumanoid:GetAttribute("SAB_JumpPower") ~= nil then
        LocalHumanoid.JumpPower = LocalHumanoid:GetAttribute("SAB_JumpPower"); LocalHumanoid:SetAttribute("SAB_JumpPower", nil)
    end
end
table.insert(CharacterCallbacks, function() task.wait(0.25); ApplyJumping() end)

local function ApplyInjury()
    local TempUI = PlayerGui:FindFirstChild("TemporaryUI")
    if TempUI then
        for _, Object in TempUI:GetDescendants() do
            if Object.Name == "redFlash" or Object.Name == "injuredVignette" then Object.Visible = not State.HideInjury end
        end
    end
    local Desaturation = Lighting:FindFirstChild("HealthDesaturation")
    if Desaturation then Desaturation.Enabled = not State.HideInjury end
end
local function ApplyBlindness()
    local Blur = Lighting:FindFirstChild("BlindnessBlur")
    if Blur and Blur:IsA("BlurEffect") then Blur.Enabled = not State.DisableBlindness end
end
Lighting.ChildAdded:Connect(function(Child)
    if Child.Name == "HealthDesaturation" and State.HideInjury then Child.Enabled = false
    elseif Child.Name == "BlindnessBlur" and Child:IsA("BlurEffect") and State.DisableBlindness then Child.Enabled = false end
end)

local DefaultZoom      = LocalPlayer.CameraMaxZoomDistance
local DefaultOcclusion = LocalPlayer.DevCameraOcclusionMode
local function SetFreeZoom(Enabled) LocalPlayer.CameraMaxZoomDistance = Enabled and math.huge or DefaultZoom end
local function SetCameraNoclip(Enabled) LocalPlayer.DevCameraOcclusionMode = Enabled and Enum.DevCameraOcclusionMode.Invisicam or DefaultOcclusion end

local LightingSaved; local FullbrightToken = 0
local function SetFullbright(Enabled)
    FullbrightToken += 1
    if Enabled then
        if not LightingSaved then LightingSaved = { Brightness = Lighting.Brightness, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, GlobalShadows = Lighting.GlobalShadows } end
        local Token = FullbrightToken
        task.spawn(function()
            while Token == FullbrightToken do
                Lighting.Brightness = 2; Lighting.Ambient = Color3.new(1, 1, 1); Lighting.OutdoorAmbient = Color3.new(1, 1, 1); Lighting.GlobalShadows = false; task.wait(1)
            end
        end)
    elseif LightingSaved then
        Lighting.Brightness = LightingSaved.Brightness; Lighting.Ambient = LightingSaved.Ambient; Lighting.OutdoorAmbient = LightingSaved.OutdoorAmbient; Lighting.GlobalShadows = LightingSaved.GlobalShadows; LightingSaved = nil
    end
end

local RagdollConnection
local function SetDeleteRagdolls(Enabled)
    if RagdollConnection then RagdollConnection:Disconnect(); RagdollConnection = nil end
    local Folder = workspace:FindFirstChild("Ragdolls"); if not Enabled or not Folder then return end
    Folder:ClearAllChildren()
    RagdollConnection = Folder.ChildAdded:Connect(function(Child) task.defer(function() Child:Destroy() end) end)
end

local function FirePrompt(Prompt)
    if typeof(fireproximityprompt) == "function" then fireproximityprompt(Prompt)
    else Prompt:InputHoldBegin(); Prompt:InputHoldEnd() end
end

local SpeedToken = 0
local function SetSpeedBoost(Enabled)
    SpeedToken += 1; if not Enabled then return end; local Token = SpeedToken
    task.spawn(function()
        while Token == SpeedToken do
            local Delta = RunService.Heartbeat:Wait()
            if LocalCharacter and LocalHumanoid and LocalHumanoid.MoveDirection.Magnitude > 0 then
                LocalCharacter:TranslateBy(LocalHumanoid.MoveDirection * (State.SpeedValue or 1) * Delta)
            end
        end
    end)
end

local FlightConnection
local function StopFlight()
    if FlightConnection then FlightConnection:Disconnect(); FlightConnection = nil end
    if LocalHumanoid then LocalHumanoid.PlatformStand = false end
    local Head = LocalCharacter and LocalCharacter:FindFirstChild("Head"); if Head then Head.Anchored = false end
end
local function StartFlight()
    StopFlight()
    local Character = LocalCharacter; local Humanoid = LocalHumanoid; local Head = Character and Character:FindFirstChild("Head")
    if not Humanoid or not Head then return end
    Humanoid.PlatformStand = true; Head.Anchored = true
    FlightConnection = RunService.Heartbeat:Connect(function(Delta)
        if not Character.Parent then StopFlight(); return end
        local Camera = workspace.CurrentCamera; if not Camera then return end
        local Move   = Humanoid.MoveDirection * ((State.FlightSpeed or 1) * Delta)
        local HeadCF = Head.CFrame; local CamCF = Camera.CFrame
        local Offset = HeadCF:ToObjectSpace(CamCF).Position
        CamCF        = CamCF * CFrame.new(-Offset.X, -Offset.Y, -Offset.Z + 1)
        local CamPos = CamCF.Position; local HeadPos = HeadCF.Position
        local Moved  = CFrame.new(CamPos, Vector3.new(HeadPos.X, CamPos.Y, HeadPos.Z)):VectorToObjectSpace(Move)
        Head.CFrame  = CFrame.new(HeadPos) * (CamCF - CamPos) * CFrame.new(Moved)
    end)
end
local function SetFlight(Enabled) if Enabled then StartFlight() else StopFlight() end end
table.insert(CharacterCallbacks, function() if State.Flight then task.wait(0.5); StartFlight() end end)

local function FakeNoliStep()
    if not State.DeleteFakeNoli or not KillersFolder then return end
    for _, Model in KillersFolder:GetChildren() do
        if Model:IsA("Model") and Model:GetAttribute("IsFakeNoli") == true then Model:Destroy() end
    end
end

if InGame then
    InGame.ChildAdded:Connect(function(Child)
        if Child:IsA("Tool") then
            Child:SetAttribute("JustDropped", true)
            task.delay(1.5, function() if Child then Child:SetAttribute("JustDropped", nil) end end)
        end
    end)
end

local function AutoPickupStep()
    if not State.AutoPickup or not LocalRoot or not LocalCharacter then return end
    local Backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    local Params   = OverlapParams.new(); Params.FilterType = Enum.RaycastFilterType.Exclude; Params.FilterDescendantsInstances = { LocalCharacter, PlayersFolder }
    local Parts    = workspace:GetPartBoundsInRadius(LocalRoot.Position, 15, Params)
    for _, Part in ipairs(Parts) do
        local Tool = Part.Parent
        if Tool and Tool:IsA("Tool") and not Tool:GetAttribute("JustDropped") then
            if not LocalCharacter:FindFirstChild(Tool.Name) and not (Backpack and Backpack:FindFirstChild(Tool.Name)) then
                local Prompt = Tool:FindFirstChildWhichIsA("ProximityPrompt", true); if Prompt then FirePrompt(Prompt) end
            end
        end
    end
end

local function TPToItem(ItemName)
    if not LocalRoot or not LocalCharacter then return end
    local TargetItem = nil
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored and obj.Name:lower():find(ItemName:lower()) then TargetItem = obj; break end
    end
    if TargetItem then
        local OldCFrame = LocalRoot.CFrame; local OldAutoPickup = State.AutoPickup
        State.AutoPickup = true; LocalRoot.CFrame = TargetItem.CFrame * CFrame.new(0, 1.5, 0); task.wait(0.3)
        LocalRoot.CFrame = OldCFrame; task.wait(0.5); if not OldAutoPickup then State.AutoPickup = false end
    else Notify("Items", "Could not find " .. ItemName .. " nearby", 3) end
end

local LastEscape = 0
local function AutoEscapeStep()
    if not State.AutoEscape or not Remote or not KillersFolder or os.clock() - LastEscape < (State.EscapeCooldown or 0.5) then return end
    local TempUI = PlayerGui:FindFirstChild("TemporaryUI"); local QTE = TempUI and TempUI:FindFirstChild("QTE")
    if QTE and QTE.Visible then
        LastEscape = os.clock()
        for _, Killer in KillersFolder:GetChildren() do
            if Killer.Name:lower() == "nosferatu" then
                local Player = Players:GetPlayerFromCharacter(Killer)
                if Player then Remote:FireServer(Player.Name .. "NosHookQTE", { true }) end
            end
        end
    end
end

local CurrentQTEAzure; local AzureHooked = false
local function SetAutoDisarm(Enabled)
    if Enabled and typeof(CurrentQTEAzure) == "table" and typeof(CurrentQTEAzure.AddProgress) == "function" then
        CurrentQTEAzure:AddProgress(100); CurrentQTEAzure = nil
    end
    if AzureHooked or not Enabled or typeof(hookfunction) ~= "function" then return end
    pcall(function()
        local Killers = ReplicatedStorage.Assets.Killers
        local Azure   = Killers:FindFirstChild("Azure") or Killers:FindFirstChild("!Azure")
        local QTEModule = Azure and Azure:FindFirstChild("cl_ConstructQTE", true); if not QTEModule then return end
        local Required  = require(QTEModule)
        if typeof(Required) ~= "table" or typeof(Required.new) ~= "function" then return end
        local Original; Original = hookfunction(Required.new, function(...)
            local Result = Original(...)
            task.delay(0.05, function()
                if typeof(Result) == "table" and typeof(Result.AddProgress) == "function" then
                    if State.AutoDisarm then Result:AddProgress(100) else CurrentQTEAzure = Result end
                end
            end)
            return Result
        end)
        AzureHooked = typeof(Original) == "function"
    end)
end

local function ApplyInGameObjects()
    if not InGame then return end
    for _, Object in InGame:GetChildren() do
        local Lower = Object.Name:lower()
        if Object:IsA("Folder") and Object.Name:find("JohnDoeTrail") then
            for _, Part in Object:GetChildren() do if Part:IsA("BasePart") then Part.CanTouch = not State.DisableTrails end end
        elseif Object:IsA("Folder") and (Lower:find("shadows") or Lower:find("footprint")) then
            for _, Part in Object:GetChildren() do if Part:IsA("BasePart") then Part.CanTouch = not State.DisableFootprints end end
        elseif Object.Name == "SpikeCollision" then
            Object.Size  = State.SmallSpikes and Vector3.new(11, 3.5, 3.5) or Vector3.new(11, 5, 5)
            Object.Shape = State.SmallSpikes and Enum.PartType.Cylinder or Enum.PartType.Block
        end
    end
end

local function HandleNoliNPC()
    if not KillersFolder or not InGame then return end
    if State.DisableNoliNPC then
        for _, Model in KillersFolder:GetChildren() do
            if Model.Name:lower() == "noli" and not Players:GetPlayerFromCharacter(Model) then
                Model.Parent = Lighting; pcall(function() Model:PivotTo(Model:GetPivot() * CFrame.new(0, -100, 0)) end)
            end
        end
        local Themes = workspace:FindFirstChild("Themes")
        if Themes then for _, Sound in Themes:GetChildren() do if Sound.Name:find("FakeLayer") and Sound:IsA("Sound") then Sound:Destroy() end end end
    else
        for _, Model in Lighting:GetChildren() do
            if Model.Name:lower() == "noli" then Model.Parent = InGame; pcall(function() Model:PivotTo(Model:GetPivot() * CFrame.new(0, 100, 0)) end) end
        end
    end
end

local function Handle007n7NPC()
    if not InGame then return end
    if State.Disable007n7NPC then
        for _, Model in InGame:GetChildren() do
            if Model.Name:lower() == "007n7" and not Players:GetPlayerFromCharacter(Model) then
                Model.Parent = Lighting
                local Root = Model:FindFirstChild("HumanoidRootPart")
                if Root then Root.ChildAdded:Connect(function(Child) if Child:IsA("Sound") and State.Disable007n7NPC then Child:Destroy() end end) end
            end
        end
    else for _, Model in Lighting:GetChildren() do if Model.Name:lower() == "007n7" then Model.Parent = InGame end end end
end

if KillersFolder then KillersFolder.ChildAdded:Connect(function() task.wait(0.5); HandleNoliNPC() end) end
if InGame then InGame.ChildAdded:Connect(function() task.wait(0.1); Handle007n7NPC() end) end

local PrivacyKeys     = { "HideKillerWins", "HidePlaytime", "HideSurvivorWins" }
local PrivacyOriginals= {}
local function ApplyHiddenStats(Player)
    local Data     = Player:FindFirstChild("PlayerData"); local Settings = Data and Data:FindFirstChild("Settings"); local Privacy = Settings and Settings:FindFirstChild("Privacy"); if not Privacy then return end
    local Originals = PrivacyOriginals[Player.UserId]; if not Originals then Originals = {}; PrivacyOriginals[Player.UserId] = Originals end
    for _, Key in PrivacyKeys do
        local Setting = Privacy:FindFirstChild(Key)
        if Setting then
            if State.AntiHiddenStats then if Originals[Key] == nil then Originals[Key] = Setting.Value end; Setting.Value = false
            elseif Originals[Key] ~= nil then Setting.Value = Originals[Key]; Originals[Key] = nil end
        end
    end
end
local function SetAntiHiddenStats() for _, Player in Players:GetPlayers() do ApplyHiddenStats(Player) end end
Players.PlayerAdded:Connect(function(Player) task.delay(2, function() if State.AntiHiddenStats then ApplyHiddenStats(Player) end end) end)

local function SetKillerWalls(Enabled)
    for _, Object in workspace:GetDescendants() do
        if Object.Name == "KillerDoors" then for _, Wall in Object:GetChildren() do if Wall:IsA("BasePart") then Wall.CanCollide = not Enabled end end end
    end
end

local ChatToken = 0
local function SetShowChat(Enabled)
    ChatToken += 1; if not Enabled then return end; local Token = ChatToken
    task.spawn(function()
        while Token == ChatToken do
            local Config = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration"); if Config then Config.Enabled = true end; task.wait(0.25)
        end
    end)
end

local DefaultFov; local FovToken = 0
local function SetFov(Enabled)
    FovToken += 1; local Camera = workspace.CurrentCamera
    if Enabled then
        if Camera and not DefaultFov then DefaultFov = Camera.FieldOfView end
        local Token = FovToken
        task.spawn(function()
            while Token == FovToken do local Current = workspace.CurrentCamera; if Current then Current.FieldOfView = State.FovValue or 70 end; task.wait(0.1) end
        end)
    elseif Camera and DefaultFov then Camera.FieldOfView = DefaultFov; DefaultFov = nil end
end

local function RejoinServer()
    Notify("Rejoin", "Rejoining...", 3)
    if workspace:GetAttribute("ServerType") == "VIP" then TeleportService:Teleport(game.PlaceId)
    else TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId) end
end

task.spawn(function()
    while task.wait(0.5) do
        if State.AutoPickup then pcall(AutoPickupStep) end
        if State.AutoEscape then pcall(AutoEscapeStep) end
        if State.DeleteFakeNoli then pcall(FakeNoliStep) end
        if State.DisableTrails or State.DisableFootprints or State.SmallSpikes then pcall(ApplyInGameObjects) end
    end
end)

--// FEATURE TABLE (Chance, Shadows, Fog, Stamina, DashTurn, Azure, Config, Emotes, Anim, Music, Tricks, TT, Minigame, PlusAnim, PlusMisc) //

local Feature = {}

Feature.EmoteNames = { "None" }
Feature.AnimNames = { "None" }
Feature.MusicNames = { "None" }
Feature.StaminaToggle = function() return function() end end
Feature.CreateConfigId = function() return "unavailable", false end
Feature.LoadConfig = function() return false end
Feature.RefreshAnimations = function() return { "None" } end
Feature.JD_HookCrystalPitch = function() end
Feature.JD_UnhookCrystalPitch = function() end

Risky("Chance shoot & coin flip", function()
    local ChanceShootConnection; local ChanceCoinToken = 0
    --// Chance aim upgrade: velocity / ping / look prediction with anti-bait speed cap //
    local ChanceMotion = setmetatable({}, { __mode = "k" })
    local KillerRunSpeed = { Slasher = 28, c00lkidd = 28, JohnDoe = 27.25, ["1x1x1x1"] = 27, Noli = 27.5, Guest666 = 27, Nosferatu = 27.5, Doombringer = 27, JaneDoe = 27, Builderman = 27.5, Dusekkar = 27.5 }
    local function ChanceSample(Root)
        local Now = os.clock()
        local Position = Root.Position
        local Data = ChanceMotion[Root]
        if not Data then
            Data = { Pos = Position, Time = Now, Vel = Root.AssemblyLinearVelocity, Acc = Vector3.zero }
            ChanceMotion[Root] = Data
            return Data.Vel, Data.Acc
        end
        local Delta = Now - Data.Time
        if Delta > 0.001 then
            local Velocity = Data.Vel:Lerp((Position - Data.Pos) / Delta, 0.5)
            Data.Acc = Data.Acc:Lerp((Velocity - Data.Vel) / Delta, 0.3)
            Data.Vel = Velocity
            Data.Pos = Position
            Data.Time = Now
        end
        return Data.Vel, Data.Acc
    end
    local function ChancePredictPosition(Root)
        local Mode = State.ChancePredMode or "Velocity"
        local Position = Root.Position
        if Mode == "Look (Original)" then
            return Position + Root.CFrame.LookVector * (tonumber(State.ChancePrediction) or 4)
        end
        local Velocity, Acceleration = ChanceSample(Root)
        local Speed = Velocity.Magnitude
        if State.ChanceAntiBait ~= false then
            local Cap = (KillerRunSpeed[Root.Parent and Root.Parent.Name or ""] or 28) + 2
            if Speed > Cap then Velocity = Velocity.Unit * Cap; Speed = Cap end
        end
        if Speed < 0.5 then return Position end
        local Distance = LocalRoot and (Position - LocalRoot.Position).Magnitude or 0
        local Lead = tonumber(State.ChanceLead) or 0.35
        if Mode == "Ping" then Lead = SA.Ping() + Lead * 0.5 end
        Lead += Distance * 0.003
        local Extra = Acceleration * Lead * Lead * 0.5
        if Extra.Magnitude > Speed * 0.4 then Extra = Extra.Unit * (Speed * 0.4) end
        return Position + Velocity * Lead + Extra
    end
    local function SetupChanceShoot(Button)
        if ChanceShootConnection then ChanceShootConnection:Disconnect() end
        ChanceShootConnection = Button.Activated:Connect(function()
            if not State.ChanceAim or not LocalRoot or not LocalHumanoid or not KillersFolder then return end
            local Target = GetClosestKiller(1000)
            local TargetRoot = Target and (Target:FindFirstChild("HumanoidRootPart") or Target.PrimaryPart); if not TargetRoot then return end
            local Humanoid = LocalHumanoid; local Root = LocalRoot; local AutoRotate = Humanoid.AutoRotate; local Start = os.clock(); local Connection
            Humanoid.AutoRotate = false
            Connection = RunService.RenderStepped:Connect(function()
                if os.clock() - Start >= 2 or not Root.Parent or not TargetRoot.Parent then Humanoid.AutoRotate = AutoRotate; Connection:Disconnect(); return end
                local Position = ChancePredictPosition(TargetRoot)
                Root.CFrame = CFrame.lookAt(Root.Position, Vector3.new(Position.X, Root.Position.Y, Position.Z))
            end)
        end)
    end
    local function HookChanceShoot()
        local Button = PlayerGui:FindFirstChild("Shoot", true)
        if Button and Button:IsA("ImageButton") then SetupChanceShoot(Button) end
    end
    PlayerGui.DescendantAdded:Connect(function(Descendant)
        if Descendant:IsA("ImageButton") and Descendant.Name == "Shoot" then SetupChanceShoot(Descendant) end
    end)
    task.spawn(HookChanceShoot)
    table.insert(CharacterCallbacks, function() task.wait(1); HookChanceShoot() end)
    Feature.SetChanceCoinFlip = function(Enabled)
        ChanceCoinToken += 1; if not Enabled then return end; local Token = ChanceCoinToken
        task.spawn(function()
            while Token == ChanceCoinToken do
                task.wait(0.1)
                local MainUI = PlayerGui:FindFirstChild("MainUI"); local Container = MainUI and MainUI:FindFirstChild("AbilityContainer")
                local Reroll = Container and Container:FindFirstChild("Reroll"); local Charges = Reroll and Reroll:FindFirstChild("Charges")
                if LocalRoot and KillersFolder and Remote and Charges and Charges:IsA("TextLabel") and Charges.Text ~= "3" then
                    local Near = false
                    for _, Killer in KillersFolder:GetChildren() do
                        local Root = Killer:FindFirstChild("HumanoidRootPart")
                        if Root and (LocalRoot.Position - Root.Position).Magnitude <= 50 then Near = true; break end
                    end
                    if not Near then Remote:FireServer("UseActorAbility", { "CoinFlip" }) end
                end
            end
        end)
    end
end)

Risky("Shadows & Fog", function()
    local ShadowsToken = 0; local ShadowsSaved; local FogToken = 0; local FogSaved
    Feature.SetNoShadows = function(Enabled)
        ShadowsToken += 1
        if Enabled then
            if ShadowsSaved == nil then ShadowsSaved = Lighting.GlobalShadows end; local Token = ShadowsToken
            task.spawn(function() while Token == ShadowsToken do Lighting.GlobalShadows = false; task.wait(1) end end)
        elseif ShadowsSaved ~= nil then Lighting.GlobalShadows = ShadowsSaved; ShadowsSaved = nil end
    end
    Feature.SetNoFog = function(Enabled)
        FogToken += 1
        if Enabled then
            if not FogSaved then
                local Atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
                FogSaved = { Start = Lighting.FogStart, Finish = Lighting.FogEnd, Density = Atmosphere and Atmosphere.Density }
            end
            local Token = FogToken
            task.spawn(function()
                while Token == FogToken do
                    Lighting.FogStart = 1000000; Lighting.FogEnd = 1000000
                    local Atmosphere = Lighting:FindFirstChildOfClass("Atmosphere"); if Atmosphere then Atmosphere.Density = 0 end; task.wait(1)
                end
            end)
        elseif FogSaved then
            Lighting.FogStart = FogSaved.Start; Lighting.FogEnd = FogSaved.Finish
            local Atmosphere = Lighting:FindFirstChildOfClass("Atmosphere"); if Atmosphere and FogSaved.Density then Atmosphere.Density = FogSaved.Density end; FogSaved = nil
        end
    end
end)

Risky("Stamina modifiers", function()
    local Originals = {}
    local Fields = {{"ModifyMaxStamina","MaxStamina","MaxStaminaValue"},{"ModifyStaminaGain","StaminaGain","StaminaGainValue"},{"ModifyStaminaLoss","StaminaLoss","StaminaLossValue"},{"ModifySprintSpeed","SprintSpeed","SprintSpeedValue"}}
    Feature.StaminaToggle = function(Field)
        return function(Enabled)
            local Module = GetSprinting(); if not Module then return end
            if Enabled then if Originals[Field] == nil then Originals[Field] = Module[Field] end
            elseif Originals[Field] ~= nil then pcall(function() Module[Field] = Originals[Field] end); Originals[Field] = nil end
        end
    end
    task.spawn(function()
        while task.wait(0.5) do
            local Module = GetSprinting()
            if Module then for _, Data in Fields do if State[Data[1]] and type(State[Data[3]]) == "number" then pcall(function() Module[Data[2]] = State[Data[3]] end) end end end
        end
    end)
end)

Risky("DashTurn, AutoBreakFree, AutoPullRope, AzureQte, AutoTrick, ShiftLock, Sk8, FastSpray", function()
    local DashTurnConnection; local QteEnabled = false; local OriginalHitZone; local HookSlot
    Feature.SetDashTurn = function(Enabled)
        if DashTurnConnection then DashTurnConnection:Disconnect(); DashTurnConnection = nil end
        if not Enabled then return end
        DashTurnConnection = RunService.RenderStepped:Connect(function(Delta)
            local Character = LocalCharacter; local Root = LocalRoot
            if not Character or not Root or Character.Name ~= "c00lkidd" or Character:GetAttribute("FootstepsMuted") ~= true then return end
            local Direction = LocalHumanoid and LocalHumanoid.MoveDirection or Vector3.zero
            if Direction.Magnitude < 0.01 then
                local Camera = workspace.CurrentCamera; if not Camera then return end
                Direction = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z)
            end
            if Direction.Magnitude < 0.01 then return end; Direction = Direction.Unit
            local Velocity = Root:FindFirstChildWhichIsA("LinearVelocity"); if Velocity then Velocity.LineDirection = Direction end
            local TargetRotation = CFrame.new(Root.Position, Root.Position + Direction).Rotation
            Root.CFrame = CFrame.new(Root.Position) * Root.CFrame.Rotation:Lerp(TargetRotation, math.min(Delta * 16, 1))
        end)
    end
    local function BreakFreeStep()
        if not State.AutoBreakFree or not Remote or not KillersFolder then return end
        local TempUI = PlayerGui:FindFirstChild("TemporaryUI"); if not (TempUI and TempUI:FindFirstChild("QTE")) then return end
        for _, Killer in KillersFolder:GetChildren() do
            if Killer:IsA("Model") and Killer.Name == "Nosferatu" then
                local Username = Killer:GetAttribute("Username")
                if Username and Username ~= LocalPlayer.Name then Remote:FireServer(Username .. "NosHookQTE", { buffer.fromstring("\x01\x01") }); break end
            end
        end
    end
    local function PullRopeStep()
        if not State.AutoPullRope or not Remote or not KillersFolder or not LocalHumanoid then return end
        local IsNosferatu = false
        for _, Killer in KillersFolder:GetChildren() do
            if Killer:IsA("Model") and Killer.Name == "Nosferatu" and Killer:GetAttribute("Username") == LocalPlayer.Name then IsNosferatu = true; break end
        end
        if not IsNosferatu then return end
        for _, Track in LocalHumanoid:GetPlayingAnimationTracks() do
            local AnimationId = Track.Animation and Track.Animation.AnimationId
            if AnimationId and AnimationId:match("%d+") == "113403615979705" then Remote:FireServer(LocalPlayer.Name .. "NosHookQTE", { buffer.fromstring("\x01\x01") }); break end
        end
    end
    task.spawn(function() while task.wait(0.1) do pcall(BreakFreeStep); pcall(PullRopeStep) end end)
    local function GetQteModule()
        local Assets = ReplicatedStorage:FindFirstChild("Assets"); local Killers = Assets and Assets:FindFirstChild("Killers"); local Azure = Killers and Killers:FindFirstChild("Azure"); local Config = Azure and Azure:FindFirstChild("Config"); local Workaround = Config and Config:FindFirstChild("cl_WorkaroundModules"); return Workaround and Workaround:FindFirstChild("cl_ConstructQTE")
    end
    Feature.SetAzureQte = function(Enabled)
        if Enabled then
            if QteEnabled then return end
            if typeof(debug.getupvalues) ~= "function" or typeof(debug.setupvalue) ~= "function" then Notify("Auto Azure QTE", "Your executor does not support this", 4); return end
            QteEnabled = true; local Module = GetQteModule(); local Loaded, Behavior = pcall(function() return Module and require(Module) end)
            if not Loaded or type(Behavior) ~= "table" or not Behavior.new then QteEnabled = false; Notify("Auto Azure QTE", "QTE module not found", 4); return end
            local function PickZone(_, _, Completed) if type(Completed) == "table" then for Index = 1, 3 do if not Completed[Index] then return Index end end end; return 1 end
            for Slot, Value in debug.getupvalues(Behavior.new) do
                if type(Value) == "function" and debug.info(Value, "a") == 3 then OriginalHitZone = Value; HookSlot = Slot; debug.setupvalue(Behavior.new, Slot, PickZone); Notify("Auto Azure QTE", "Hooked", 3); return end
            end
        else
            QteEnabled = false
            if HookSlot and OriginalHitZone then
                local Module = GetQteModule(); local Loaded, Behavior = pcall(function() return Module and require(Module) end)
                if Loaded and type(Behavior) == "table" and Behavior.new then pcall(debug.setupvalue, Behavior.new, HookSlot, OriginalHitZone) end
                HookSlot = nil; OriginalHitZone = nil
            end
        end
    end
    local TrickMonitors = {}; local TrickConnection; local TrickFolder
    task.spawn(function()
        local Ok, Folder = pcall(function() return ReplicatedStorage:WaitForChild("Assets", 10):WaitForChild("Survivors", 10):WaitForChild("Veeronica", 10):WaitForChild("Behavior", 10) end)
        if Ok and Folder then TrickFolder = Folder end
    end)
    local function MonitorHighlight(Highlight)
        if not Highlight or TrickMonitors[Highlight] then return end
        local Connections = {}; local Previous = false
        local function Cleanup() for _, Connection in Connections do if Connection.Connected then Connection:Disconnect() end end; TrickMonitors[Highlight] = nil end
        local function Changed()
            if not State.AutoTrick then return end; if not Highlight.Parent then Cleanup(); return end
            local Adornee = Highlight.Adornee; local Current = Adornee ~= nil and LocalCharacter ~= nil and (Adornee == LocalCharacter or Adornee:IsDescendantOf(LocalCharacter))
            if Current and not Previous then
                local MainUI = PlayerGui:FindFirstChild("MainUI"); local Button = MainUI and MainUI:FindFirstChild("SprintingButton")
                if Button and typeof(getconnections) == "function" then for _, Connection in getconnections(Button.MouseButton1Down) do pcall(function() Connection:Fire() end) end end
            end
            Previous = Current
        end
        table.insert(Connections, Highlight:GetPropertyChangedSignal("Adornee"):Connect(Changed))
        table.insert(Connections, Highlight.AncestryChanged:Connect(function(_, Parent) if not Parent then Cleanup() else Changed() end end))
        TrickMonitors[Highlight] = Cleanup; task.spawn(Changed)
    end
    Feature.SetAutoTrick = function(Enabled)
        if Enabled then
            if not TrickFolder or TrickConnection then return end
            for _, Descendant in TrickFolder:GetDescendants() do if Descendant:IsA("Highlight") then MonitorHighlight(Descendant) end end
            TrickConnection = TrickFolder.DescendantAdded:Connect(function(Child) if Child:IsA("Highlight") then MonitorHighlight(Child) end end)
        else
            if TrickConnection then TrickConnection:Disconnect(); TrickConnection = nil end
            for _, Cleanup in table.clone(TrickMonitors) do pcall(Cleanup) end; TrickMonitors = {}
        end
    end
    local ShiftConnection; local ControlActive = false; local ControlConnection; local SavedHumanoid = {}
    local function SetShiftlock(Enabled)
        if ShiftConnection then ShiftConnection:Disconnect(); ShiftConnection = nil end
        if Enabled then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
            ShiftConnection = RunService.RenderStepped:Connect(function()
                local Camera = workspace.CurrentCamera
                if LocalRoot and Camera then local Look = Camera.CFrame.LookVector; LocalRoot.CFrame = CFrame.new(LocalRoot.Position, Vector3.new(Look.X + LocalRoot.Position.X, LocalRoot.Position.Y, Look.Z + LocalRoot.Position.Z)) end
            end)
        else UserInputService.MouseBehavior = Enum.MouseBehavior.Default end
    end
    local function StartOverride()
        if ControlActive or not LocalHumanoid then return end; ControlActive = true; local Humanoid = LocalHumanoid
        SavedHumanoid[Humanoid] = { WalkSpeed = Humanoid.WalkSpeed, AutoRotate = Humanoid.AutoRotate }
        pcall(function() Humanoid.WalkSpeed = 60; Humanoid.AutoRotate = false end); SetShiftlock(true)
        ControlConnection = RunService.RenderStepped:Connect(function()
            local Root = LocalRoot; if not Humanoid.Parent or not Root then return end
            pcall(function() Humanoid.WalkSpeed = 60; Humanoid.AutoRotate = false end)
            local Look = Root.CFrame.LookVector; local Flat = Vector3.new(Look.X, 0, Look.Z)
            if Flat.Magnitude > 0 then Humanoid:Move(Flat.Unit) end
        end)
    end
    local function StopOverride()
        if not ControlActive then return end; ControlActive = false
        if ControlConnection then ControlConnection:Disconnect(); ControlConnection = nil end; SetShiftlock(false)
        local Humanoid = LocalHumanoid
        if Humanoid then pcall(function() local Saved = SavedHumanoid[Humanoid]; if Saved then Humanoid.WalkSpeed = Saved.WalkSpeed; SavedHumanoid[Humanoid] = nil end; Humanoid.AutoRotate = true; Humanoid:Move(Vector3.zero) end) end
    end
    local function IsPlayingAnimation(TargetId)
        if not LocalHumanoid then return false end
        for _, Track in LocalHumanoid:GetPlayingAnimationTracks() do local Id = Track.Animation and tostring(Track.Animation.AnimationId or ""):match("%d+"); if Id == TargetId then return true end end; return false
    end
    local SprayPhase = 0; local SprayBase
    RunService.RenderStepped:Connect(function(Delta)
        if State.Sk8Control then if IsPlayingAnimation("117058860640843") then StartOverride() else StopOverride() end elseif ControlActive then StopOverride() end
        if not State.FastSpray or not IsPlayingAnimation("96618767275101") or not LocalRoot then SprayPhase = 0; SprayBase = nil; return end
        if not SprayBase or math.abs(math.sin(SprayPhase)) < 0.05 then SprayBase = LocalRoot.CFrame end
        SprayPhase += Delta * (math.pi * (State.SpraySpeed or 0.5))
        LocalRoot.CFrame = SprayBase + SprayBase.LookVector * (-math.sin(SprayPhase) * 2)
    end)
    table.insert(CharacterCallbacks, function() if ShiftConnection then ShiftConnection:Disconnect(); ShiftConnection = nil end; ControlActive = false; SavedHumanoid = {}; SprayPhase = 0; SprayBase = nil end)
end)

Risky("Config system", function()
    local ConfigVersion = "30"
    local B64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"; local B64Map = {}
    for i = 1, #B64Chars do B64Map[B64Chars:sub(i, i)] = i - 1 end
    local function ToBase64(Str)
        local Bytes = { string.byte(Str, 1, -1) }; local Result = {}; local Pad = (3 - (#Bytes % 3)) % 3
        for _ = 1, Pad do table.insert(Bytes, 0) end
        for i = 1, #Bytes, 3 do
            local b1, b2, b3 = Bytes[i], Bytes[i + 1], Bytes[i + 2]; local n = b1 * 65536 + b2 * 256 + b3
            local c1 = math.floor(n / 262144) % 64; local c2 = math.floor(n / 4096) % 64; local c3 = math.floor(n / 64) % 64; local c4 = n % 64
            table.insert(Result, B64Chars:sub(c1 + 1, c1 + 1)); table.insert(Result, B64Chars:sub(c2 + 1, c2 + 1)); table.insert(Result, B64Chars:sub(c3 + 1, c3 + 1)); table.insert(Result, B64Chars:sub(c4 + 1, c4 + 1))
        end
        return table.concat(Result), Pad
    end
    local function FromBase64(Str, Pad)
        local Result = {}
        for i = 1, #Str, 4 do
            local c1 = B64Map[Str:sub(i, i)] or 0; local c2 = B64Map[Str:sub(i + 1, i + 1)] or 0; local c3 = B64Map[Str:sub(i + 2, i + 2)] or 0; local c4 = B64Map[Str:sub(i + 3, i + 3)] or 0
            local n = c1 * 262144 + c2 * 4096 + c3 * 64 + c4
            table.insert(Result, string.char(math.floor(n / 65536) % 256)); table.insert(Result, string.char(math.floor(n / 256) % 256)); table.insert(Result, string.char(n % 256))
        end
        for _ = 1, Pad do table.remove(Result) end; return table.concat(Result)
    end
    local function Encode()
        local Data = {}
        for Key, Entry in Registry do if State[Key] ~= nil and State[Key] ~= Entry.Default then Data[Key] = State[Key] end end
        local Json = HttpService:JSONEncode(Data); local B64, Pad = ToBase64(Json); local Sum = 0
        for i = 1, #Json do Sum += string.byte(Json, i) end; local Check = Sum % 97
        return ConfigVersion .. B64 .. tostring(Pad) .. string.format("%02d", Check)
    end
    local function Decode(Text)
        if type(Text) ~= "string" or #Text < 8 then return nil end; if Text:sub(1, 2) ~= ConfigVersion then return nil end
        local Pad = tonumber(Text:sub(-3, -3)); local Check = tonumber(Text:sub(-2)); if not Pad or not Check then return nil end
        local B64 = Text:sub(3, -4); local Json = FromBase64(B64, Pad); local Sum = 0
        for i = 1, #Json do Sum += string.byte(Json, i) end; if Sum % 97 ~= Check then return nil end
        local Ok, Data = pcall(function() return HttpService:JSONDecode(Json) end); if not Ok or type(Data) ~= "table" then return nil end; return Data
    end
    Feature.CreateConfigId = function() local Id = Encode(); return Id, CopyText(Id) end
    Feature.LoadConfig = function(Text)
        local Data = Decode(Text); if not Data then return false end
        for Key, Entry in Registry do
            local Target = Data[Key]; if Target == nil then Target = Entry.Default end
            if type(Target) == type(Entry.Default) and State[Key] ~= Target then
                State[Key] = Target; Saved[Key] = Target
                pcall(function() local Element = Entry.Element; if Element then if Entry.Kind == "dropdown" and Element.Select then Element:Select(Target) elseif Element.Set then Element:Set(Target) end end end)
                if Entry.Callback then task.spawn(SafeCall, "Config", Entry.Callback, Target) end
            end
        end
        SaveSettings(); if Feature.AfterLoad then Feature.AfterLoad() end; return true
    end
end)

Risky("Emotes", function()
    local EmoteState = { Emoting = false, Track = nil, Speed = 16, Jump = 50, Rotation = nil }; local EmoteModules = {}
    local EmotesFolder = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Emotes")
    if EmotesFolder then for _, Object in EmotesFolder:GetDescendants() do if Object:IsA("ModuleScript") then table.insert(EmoteModules, Object) end end; table.sort(EmoteModules, function(A, B) return A.Name < B.Name end) end
    Feature.EmoteNames = {}; for _, Module in EmoteModules do table.insert(Feature.EmoteNames, Module.Name) end; if #Feature.EmoteNames == 0 then Feature.EmoteNames = { "None" } end
    Feature.StopEmote = function()
        if not EmoteState.Emoting then return end; EmoteState.Emoting = false
        if EmoteState.Rotation then EmoteState.Rotation:Disconnect(); EmoteState.Rotation = nil end
        local Character = LocalCharacter
        if Character then
            local Root = Character:FindFirstChild("HumanoidRootPart") or Character.PrimaryPart; local Humanoid = Character:FindFirstChildOfClass("Humanoid"); local Effects = Character:FindFirstChild("PlayerEmoteVFX"); if Effects then Effects:Destroy() end
            if Root then Root.Anchored = false; local Sound = Root:FindFirstChild("EmoteSound"); if Sound then Sound:Destroy() end; local Attachment = Root:FindFirstChild("SAB_EmoteAttachment"); if Attachment then Attachment:Destroy() end end
            if Humanoid then Humanoid.WalkSpeed = EmoteState.Speed; Humanoid.JumpPower = EmoteState.Jump end
        end
        if EmoteState.Track then pcall(function() EmoteState.Track:Stop() end); EmoteState.Track = nil end
    end
    Feature.PlayEmote = function()
        local Module; for _, Candidate in EmoteModules do if Candidate.Name == State.EmoteSelect then Module = Candidate; break end end; if not Module then return end
        if EmoteState.Emoting then Feature.StopEmote(); task.wait(0.1) end
        local Character = LocalCharacter; local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid"); local Root = Character and (Character:FindFirstChild("HumanoidRootPart") or Character.PrimaryPart); local Animator = Humanoid and Humanoid:WaitForChild("Animator", 2)
        if not Humanoid or not Root or not Animator then return end
        local Loaded, Data = pcall(require, Module); if not Loaded or type(Data) ~= "table" or not Data.AssetID then return end
        EmoteState.Emoting = true; EmoteState.Speed = Humanoid.WalkSpeed; EmoteState.Jump = Humanoid.JumpPower; Humanoid.WalkSpeed = 0; Humanoid.JumpPower = 0; Root.Anchored = true
        local Animation = Instance.new("Animation"); Animation.AnimationId = tostring(Data.AssetID); EmoteState.Track = Animator:LoadAnimation(Animation); EmoteState.Track.Looped = true; EmoteState.Track:Play()
        if EmoteState.Rotation then EmoteState.Rotation:Disconnect() end
        EmoteState.Rotation = RunService.RenderStepped:Connect(function()
            local Camera = workspace.CurrentCamera; if not EmoteState.Emoting or not Camera or not LocalRoot or LocalPlayer.CameraMode ~= Enum.CameraMode.LockFirstPerson then return end
            local _, CameraY = Camera.CFrame:ToEulerAnglesYXZ(); LocalRoot.CFrame = CFrame.new(LocalRoot.Position) * CFrame.Angles(0, CameraY, 0)
        end)
        if Data.SFX then local Old = Root:FindFirstChild("EmoteSound"); if Old then Old:Destroy() end; local Sound = Instance.new("Sound"); Sound.Name = "EmoteSound"; Sound.SoundId = tostring(Data.SFX); Sound.Volume = 1; Sound.Looped = true; Sound.Parent = Root; Sound:Play() end
        local Attachment = Instance.new("Attachment"); Attachment.Name = "SAB_EmoteAttachment"; Attachment.Parent = Root; local Burst = Instance.new("ParticleEmitter"); Burst.Name = "EmoteBurst"; Burst.Texture = "rbxassetid://635533604"; Burst.Rate = 60; Burst.Speed = NumberRange.new(2, 5); Burst.Lifetime = NumberRange.new(0.5, 1.2); Burst.Drag = 5; Burst.Parent = Attachment
    end
    LocalPlayer.CharacterRemoving:Connect(function() if EmoteState.Emoting then Feature.StopEmote() end end)
    table.insert(CharacterCallbacks, function() task.wait(0.5); if EmoteState.Emoting then Feature.StopEmote() end end)
end)

Risky("Animations", function()
    local BaseAnimations = {}; local Entries = {}; local CurrentTracks = {}; local MoveConnection
    local function AnimId(Value) return Value and tostring(Value) or nil end
    local function CollectBase()
        BaseAnimations = {}; local Assets = ReplicatedStorage:FindFirstChild("Assets"); if not Assets then return end
        for _, Role in { "Killers", "Survivors" } do
            local Folder = Assets:FindFirstChild(Role)
            if Folder then
                for _, CharFolder in Folder:GetChildren() do
                    local Config = CharFolder:IsA("Folder") and CharFolder:FindFirstChild("Config")
                    if Config and Config:IsA("ModuleScript") then
                        local Loaded, Data = pcall(require, Config)
                        if Loaded and type(Data) == "table" and Data.Animations then local Anims = Data.Animations; BaseAnimations[CharFolder.Name] = { Idle = AnimId(Anims.Idle), Walk = AnimId(Anims.Walk), Run = AnimId(Anims.Run), DisplayName = Data.DisplayName or CharFolder.Name } end
                    end
                end
            end
        end
    end
    local function BuildEntries()
        Entries = {}; local Seen = {}; local NameCount = {}
        local function Add(Name, Idle, Walk, Run)
            local Key = Idle .. "|" .. Walk .. "|" .. Run; if Seen[Key] then return end; Seen[Key] = true; NameCount[Name] = (NameCount[Name] or 0) + 1; if NameCount[Name] > 1 then Name = Name .. " (" .. NameCount[Name] .. ")" end
            table.insert(Entries, { Name = Name, Idle = Idle, Walk = Walk, Run = Run })
        end
        for CharName, Data in BaseAnimations do Add(Data.DisplayName or CharName, Data.Idle or "", Data.Walk or "", Data.Run or "") end
        local Assets = ReplicatedStorage:FindFirstChild("Assets"); local Skins = Assets and Assets:FindFirstChild("Skins"); if not Skins then return end
        for _, Role in { "Killers", "Survivors" } do
            local RoleFolder = Skins:FindFirstChild(Role)
            if RoleFolder then
                for _, CharFolder in RoleFolder:GetChildren() do
                    if CharFolder:IsA("Folder") then
                        local BaseData = BaseAnimations[CharFolder.Name]
                        for _, Skin in CharFolder:GetChildren() do
                            local Config = Skin:IsA("Folder") and Skin:FindFirstChild("Config")
                            if Config and Config:IsA("ModuleScript") then
                                local Loaded, Data = pcall(require, Config)
                                if Loaded and type(Data) == "table" and Data.Animations then
                                    local Anims = Data.Animations; local Idle = AnimId(Anims.Idle) or (BaseData and BaseData.Idle); local Walk = AnimId(Anims.Walk) or (BaseData and BaseData.Walk); local Run = AnimId(Anims.Run) or (BaseData and BaseData.Run)
                                    if Idle and Walk and Run then Add(Data.DisplayName or Skin.Name, Idle, Walk, Run) end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    local function Names() local List = {}; for _, Entry in Entries do table.insert(List, Entry.Name) end; return #List > 0 and List or { "None" } end
    Feature.StopAnimation = function()
        if MoveConnection then MoveConnection:Disconnect(); MoveConnection = nil end
        for _, Track in CurrentTracks do pcall(function() Track:Stop(); Track:Destroy() end) end; CurrentTracks = {}
    end
    Feature.ApplyAnimation = function()
        Feature.StopAnimation(); local Entry; for _, Candidate in Entries do if Candidate.Name == State.AnimSelect then Entry = Candidate; break end end
        local Character = LocalCharacter; local Humanoid = LocalHumanoid; if not Entry or not Character or not Humanoid then return end
        local Animator = Humanoid:FindFirstChildOfClass("Animator"); if not Animator then Animator = Instance.new("Animator"); Animator.Parent = Humanoid end
        local Loaded = {}
        for _, Kind in { "Idle", "Walk", "Run" } do
            local Id = Entry[Kind]; if Id and Id ~= "" then local Animation = Instance.new("Animation"); Animation.AnimationId = Id; local Track = Animator:LoadAnimation(Animation); Track.Priority = Enum.AnimationPriority.Movement; Loaded[Kind] = Track end
        end
        CurrentTracks = Loaded
        MoveConnection = RunService.RenderStepped:Connect(function()
            if not Character.Parent then Feature.StopAnimation(); return end
            local NewTrack
            if Humanoid.MoveDirection.Magnitude > 0.1 then NewTrack = Humanoid.WalkSpeed >= 20 and (Loaded.Run or Loaded.Walk) or (Loaded.Walk or Loaded.Run)
            else NewTrack = Loaded.Idle end
            for _, Track in Loaded do if Track.IsPlaying and Track ~= NewTrack then Track:Stop() end end
            if NewTrack and not NewTrack.IsPlaying then NewTrack:Play() end
        end)
    end
    Feature.RefreshAnimations = function() CollectBase(); BuildEntries(); return Names() end
    CollectBase(); BuildEntries(); Feature.AnimNames = Names()
    table.insert(CharacterCallbacks, function() task.wait(0.5); if next(CurrentTracks) then Feature.StopAnimation() end end)
end)

Risky("Music", function()
    local MusicTracks = {["MADE JUST 4 U"]="https://raw.githubusercontent.com/FixFox550/FixFox/refs/heads/main/IMG_7277.mp3",["Hello"]="https://raw.githubusercontent.com/FixFox550/FixFox/refs/heads/main/IMG_7280.mp3",["APOCOOLYPSE"]="https://raw.githubusercontent.com/FixFox550/FixFox/refs/heads/main/IMG_7282.mp3",["A BRAVE SOUL"]="https://raw.githubusercontent.com/FixFox550/FixFox/refs/heads/main/IMG_7283.mp3",["Profitable Passion"]="https://raw.githubusercontent.com/FixFox550/FixFox/refs/heads/main/IMG_7287.mp3",["ARTIST BLOCK:Reprise"]="https://raw.githubusercontent.com/FixFox550/FixFox/refs/heads/main/IMG_7290.mp3",["Faith's Answer"]="https://raw.githubusercontent.com/FixFox550/FixFox/refs/heads/main/IMG_7292.mp3",["Teapot Palace"]="https://raw.githubusercontent.com/FixFox550/FixFox/refs/heads/main/IMG_7295.mp3",["Ready To Die"]="https://raw.githubusercontent.com/FixFox550/FixFox/refs/heads/main/IMG_7309.mp3",["Escape The Necrobloxians"]="https://raw.githubusercontent.com/FixFox550/FixFox/refs/heads/main/Hwoowowow.mp3"}
    Feature.MusicNames = {}; for Name in MusicTracks do table.insert(Feature.MusicNames, Name) end; table.sort(Feature.MusicNames)
    local MusicFolder   = SettingsFolder .. "/Music"
    local FileSupport   = FilesSupported and typeof(getcustomasset) == "function"
    if FileSupport then pcall(function() if not isfolder(MusicFolder) then makefolder(MusicFolder) end end) end
    local Music = { On = false, Cached = {}, OriginalId = nil, Token = 0, CachedSound = nil, LastCheck = 0, Preview = nil }; local InFlight = {}
    local function Fetch(Name)
        if not FileSupport then return nil end; if Music.Cached[Name] then return Music.Cached[Name] end
        local Url  = MusicTracks[Name]; if not Url then return nil end
        local Path = MusicFolder .. "/" .. Name:gsub("[^%w]", "_") .. ".mp3"
        if not isfile(Path) then local Ok, Data = pcall(function() return game:HttpGet(Url) end); if not Ok or not Data then return nil end; writefile(Path, Data) end
        local Ok, Asset = pcall(getcustomasset, Path); if Ok and Asset then Music.Cached[Name] = Asset; return Asset end; return nil
    end
    local function FetchAsync(Name, Callback)
        if Music.Cached[Name] then if Callback then Callback(Music.Cached[Name]) end; return end
        if InFlight[Name] then return end; InFlight[Name] = true
        task.spawn(function() local Asset = Fetch(Name); InFlight[Name] = nil; if Asset and Callback then Callback(Asset) end end)
    end
    local function GetSound()
        local Now = os.clock()
        if Music.CachedSound and Music.CachedSound.Parent and Now - Music.LastCheck < 0.5 then return Music.CachedSound end
        Music.LastCheck = Now; local Themes = workspace:FindFirstChild("Themes"); local Sound = (Themes and Themes:FindFirstChild("LastSurvivor")) or workspace:FindFirstChild("LastSurvivor", true) or SoundService:FindFirstChild("LastSurvivor", true)
        if Sound and Sound:IsA("Sound") then Music.CachedSound = Sound; return Sound end; Music.CachedSound = nil; return nil
    end
    local function Replace(Sound, Asset)
        if not Music.OriginalId then Music.OriginalId = Sound.SoundId end
        if Sound.SoundId ~= Asset then Sound.SoundId = Asset; Sound:Stop(); task.wait(0.05); Sound:Play() elseif not Sound.IsPlaying then Sound:Play() end
    end
    Feature.SetLms = function(Enabled)
        Music.Token += 1; Music.On = Enabled
        if Enabled then
            local Token = Music.Token; FetchAsync(State.LmsTrack)
            task.spawn(function()
                while Token == Music.Token do
                    pcall(function() local Sound = GetSound(); if Sound then local Asset = Music.Cached[State.LmsTrack]; if Asset then Replace(Sound, Asset) else FetchAsync(State.LmsTrack) end end end); task.wait(1)
                end
            end)
        else pcall(function() local Sound = GetSound(); if Sound and Music.OriginalId then Sound.SoundId = Music.OriginalId; Sound:Stop(); task.wait(0.05); Sound:Play() end end) end
    end
    Feature.PreloadMusic = function()
        task.spawn(function()
            if not FileSupport then Notify("Music", "Your executor does not support custom audio", 4); return end
            for _, Name in Feature.MusicNames do FetchAsync(Name); task.wait(0.05) end; Notify("Music", "Preload complete", 3)
        end)
    end
    Feature.StopPreview = function() if Music.Preview then Music.Preview:Stop(); Music.Preview:Destroy(); Music.Preview = nil; Notify("Music", "Preview stopped", 2) end end
    Feature.StartPreview = function()
        task.spawn(function()
            local Asset = Fetch(State.LmsTrack); if not Asset then Notify("Music", "Failed to load the song", 3); return end
            if Music.Preview then Music.Preview:Stop(); Music.Preview:Destroy() end
            local Sound = Instance.new("Sound"); Sound.Name = "FlexSakenPreview"; Sound.SoundId = Asset; Sound.Volume = 1; Sound.Parent = SoundService; Sound:Play(); Music.Preview = Sound; Notify("Music", "Playing: " .. State.LmsTrack, 2)
        end)
    end
end)

--// GENERATOR SOLVER //

local MinigameFolder, FlowBoardModule, LockBoardModule, FlowInputModule, GearInputModule, LockInputModule, ConnectInputModule
Risky("GeneratorModules", function()
    local ok1, v1 = pcall(function() return ReplicatedStorage.Systems.Player.Game.Minigames end)
    if ok1 then MinigameFolder = v1 end

    local ok2, v2 = pcall(function() return require(ReplicatedStorage.Modules.Minigames.FlowBoard) end)
    if ok2 then FlowBoardModule = v2 end

    local ok3, v3 = pcall(function() return require(ReplicatedStorage.Modules.Minigames.LockBoard) end)
    if ok3 then LockBoardModule = v3 end

    if MinigameFolder then
        local ok4, v4 = pcall(function() return require(MinigameFolder.FlowClientMinigame.FlowInput) end)
        if ok4 then FlowInputModule = v4 end

        local ok5, v5 = pcall(function() return require(MinigameFolder.GearClientMinigame.GearInput) end)
        if ok5 then GearInputModule = v5 end

        local ok6, v6 = pcall(function() return require(MinigameFolder.LockClientMinigame.LockInput) end)
        if ok6 then LockInputModule = v6 end

        local ok7, v7 = pcall(function() return require(MinigameFolder.ConnectClientMinigame.ConnectInput) end)
        if ok7 then ConnectInputModule = v7 end
    end

    if not (FlowBoardModule and LockBoardModule and FlowInputModule and ConnectInputModule) then
        warn("[FlexSaken] Generator solver modules not found — Auto Generator will be disabled")
    end
end)

local GenConfig = {
    StartDelay   = 1.5,
    ActionDelay  = 0.05,
    ConnectDelay = 1.0,
    GearDelay    = 0.03,
}

local MinigameSolver = {
    Enabled       = false,
    ManualEnabled = false,
    AutoEnabled   = false,
    Generation    = 0,
    LockBoard     = nil,
    Installed     = false,
}

local function solverDelay()       return math.max(0, GenConfig.ActionDelay  or 0.05) end
local function connectSolverDelay() return math.max(0, GenConfig.ConnectDelay or 1)   end
local function solverIsEnabled()   return MinigameSolver.ManualEnabled or MinigameSolver.AutoEnabled end

local function stillSolving(token, object)
    return solverIsEnabled()
        and MinigameSolver.Generation == token
        and object and not object.Ended
end

local function waitForSolver(object)
    while object and not object.Ended and not solverIsEnabled() do
        task.wait(0.05)
    end
    if not (object and not object.Ended and solverIsEnabled()) then return false end
    local started = os.clock()
    while object and not object.Ended and solverIsEnabled() and os.clock() - started < GenConfig.StartDelay do
        task.wait(0.05)
    end
    return object and not object.Ended and solverIsEnabled()
end

local function solveFlowBoard(board)
    local size, pairMap = board.Size, board.Pairs
    local occupied, answer = {}, {}
    local directions = { {-1,0},{1,0},{0,-1},{0,1} }
    local endpointOwner = {}
    for color, pair in pairs(pairMap) do
        endpointOwner[pair[1]], endpointOwner[pair[2]] = color, color
    end
    local remaining = {}
    for color in pairs(pairMap) do table.insert(remaining, color) end

    local function candidates(color, limit)
        local pair = pairMap[color]
        local from, target = pair[1], pair[2]
        local results, path, seen = {}, {from}, {[from]=true}
        local function distance(cell)
            local r,  c  = FlowBoardModule.ToRowCol(size, cell)
            local tr, tc = FlowBoardModule.ToRowCol(size, target)
            return math.abs(r-tr)+math.abs(c-tc)
        end
        local function walk(cell)
            if #results >= limit then return end
            if cell == target then table.insert(results, table.clone(path)); return end
            local row, col = FlowBoardModule.ToRowCol(size, cell)
            local nextCells = {}
            for _, d in ipairs(directions) do
                local nr, nc = row+d[1], col+d[2]
                if nr>=1 and nr<=size and nc>=1 and nc<=size then
                    local n = FlowBoardModule.ToIndex(size, nr, nc)
                    local owner = endpointOwner[n]
                    if not seen[n] and not occupied[n] and (not owner or (owner==color and n==target)) then
                        table.insert(nextCells, n)
                    end
                end
            end
            table.sort(nextCells, function(a,b) return distance(a)<distance(b) end)
            for _, n in ipairs(nextCells) do
                seen[n]=true; table.insert(path,n)
                walk(n)
                path[#path]=nil; seen[n]=nil
                if #results>=limit then break end
            end
        end
        walk(from)
        table.sort(results, function(a,b) return #a<#b end)
        return results
    end

    local function search(colors)
        if #colors==0 then return true end
        local bestIndex, bestPaths
        for i, color in ipairs(colors) do
            local list = candidates(color, 300)
            if #list==0 then return false end
            if not bestPaths or #list<#bestPaths then bestIndex, bestPaths = i, list end
        end
        local color = colors[bestIndex]
        local nextColors = table.clone(colors); table.remove(nextColors, bestIndex)
        for _, path in ipairs(bestPaths) do
            for _, cell in ipairs(path) do occupied[cell]=true end
            answer[color]=path
            if search(nextColors) then return true end
            answer[color]=nil
            for _, cell in ipairs(path) do occupied[cell]=nil end
        end
        return false
    end

    return search(remaining) and answer or nil
end

local function installMinigameHooks()
    if MinigameSolver.Installed then return end
    if not (FlowBoardModule and LockBoardModule and FlowInputModule and ConnectInputModule) then
        warn("[FlexSaken] Cannot install minigame hooks — required modules missing")
        return
    end
    MinigameSolver.Installed = true

    local oldLockBoardNew = LockBoardModule.new
    LockBoardModule.new = function(...)
        local board = oldLockBoardNew(...)
        MinigameSolver.LockBoard = board
        return board
    end

    local oldFlowNew = FlowInputModule.new
    FlowInputModule.new = function(board, renderer, callbacks)
        local object = oldFlowNew(board, renderer, callbacks)
        local token = MinigameSolver.Generation
        task.spawn(function()
            if not waitForSolver(object) then return end
            task.wait(solverDelay())
            if not stillSolving(token, object) then return end
            local paths = solveFlowBoard(board)
            if not paths then warn('[Generator Solver] Flow solution was not found'); return end
            for color, path in pairs(paths) do
                if not stillSolving(token, object) then return end
                local ok, drawing = pcall(function() return board:Begin(path[1]) end)
                if ok and drawing then
                pcall(function() renderer:Render() end); task.wait(solverDelay())
                for index = 2, #path do
                    if not stillSolving(token, object) then return end
                    pcall(function() board:Step(drawing, path[index], 0) end)
                    pcall(function() renderer:Render() end); task.wait(solverDelay())
                end
                pcall(function() board:Release(drawing, true) end)
                pcall(function() renderer:Render() end); task.wait(solverDelay())
                end --// close if ok and drawing //
            end
            if stillSolving(token, object) then
                local solved = pcall(function() return board:IsSolved() end) and board:IsSolved()
                if solved then
                    MinigameSolver.Generation += 1
                    pcall(function() object:__finish() end)
                    pcall(function() callbacks.OnSolved() end)
                end
            end
        end)
        return object
    end

    local oldConnectNew = ConnectInputModule.new
    ConnectInputModule.new = function(board, renderer, callbacks)
        local object = oldConnectNew(board, renderer, callbacks)
        local token = MinigameSolver.Generation
        task.spawn(function()
            if not waitForSolver(object) then return end
            task.wait(connectSolverDelay())
            if not stillSolving(token, object) then return end
            for blob in pairs(board.Blobs) do
                if not stillSolving(token, object) then return end
                local linked = pcall(function() return board:GetLink(blob) end) and board:GetLink(blob)
                if not linked then
                    local ok, mate = pcall(function() return board:GetMate(blob) end)
                    if ok and mate then
                        pcall(function() board:Connect(blob, mate) end)
                        pcall(function() renderer:Render() end); task.wait(connectSolverDelay())
                    end
                end
            end
            if stillSolving(token, object) then
                local solved = pcall(function() return board:IsSolved() end) and board:IsSolved()
                if solved then
                    MinigameSolver.Generation += 1
                    pcall(function() object:__finish() end)
                    pcall(function() callbacks.OnSolved() end)
                end
            end
        end)
        return object
    end

    local oldGearNew = GearInputModule.new
    GearInputModule.new = function(getCenter, callbacks, enabled)
        local object = oldGearNew(getCenter, callbacks, enabled)
        local token = MinigameSolver.Generation
        task.spawn(function()
            if not waitForSolver(object) then return end
            task.wait(math.max(0.55, solverDelay()))
            local deadline = os.clock() + 30  --// hard timeout: never spin forever //
            for _ = 1, 400 do
                if not stillSolving(token, object) then return end
                if os.clock() > deadline then return end
                --// Stop as soon as the minigame object signals completion //
                if object.Ended then
                    MinigameSolver.Generation += 1
                    return
                end
                pcall(function() callbacks.OnTurn(90) end)
                task.wait(math.max(0, GenConfig.GearDelay or 0.03))
            end
            --// Finished all turns — bump generation so we don't re-enter //
            MinigameSolver.Generation += 1
        end)
        return object
    end

    local oldLockNew = LockInputModule.new
    LockInputModule.new = function(ui, callbacks)
        local object = oldLockNew(ui, callbacks)
        local board  = MinigameSolver.LockBoard
        local token  = MinigameSolver.Generation
        task.spawn(function()
            if not waitForSolver(object) then return end
            local deadline = os.clock() + 30  --// hard timeout //
            while stillSolving(token, object) and board do
                if os.clock() > deadline or object.Ended then
                    MinigameSolver.Generation += 1
                    return
                end
                local broken = pcall(function() return board:IsBroken() end) and board:IsBroken()
                if broken then break end
                local ok, onTarget = pcall(function()
                    local now = workspace:GetServerTimeNow()
                    return board:IsOnTarget(board:AngleAt(now))
                end)
                if ok and onTarget then
                    pcall(function() callbacks.OnPress() end)
                    task.wait(math.max(0.08, solverDelay()))
                else
                    RunService.Heartbeat:Wait()
                end
            end
            MinigameSolver.Generation += 1
        end)
        return object
    end
end

pcall(installMinigameHooks)

--// FOURTH BLOCK BUTTON (in-game on/off button for Auto Block) //

local FourthBlock = { running = false, connections = {}, instance = nil, cachedPos = nil, cachedSize = nil, sourceName = nil, applyTint = nil }

local function StartFourthButton()
    if FourthBlock.running then return end
    FourthBlock.running = true
    FourthBlock.connections = {}

    --// Destroy any leftover instance from a previous run //
    do
        local m = PlayerGui:FindFirstChild("MainUI")
        if m then
            local c = m:FindFirstChild("AbilityContainer", true)
            if c then
                local old = c:FindFirstChild("FourthBlockAbility")
                if old then pcall(function() old:Destroy() end) end
            end
        end
    end

    --// Tint function: green when AutoBlock is on, red when off //
    FourthBlock.applyTint = function()
        local b = FourthBlock.instance
        if not b or not b.Parent then return end
        local col = State.AutoBlock and Color3.fromRGB(0, 255, 60) or Color3.fromRGB(255, 0, 0)
        if b:IsA("ImageButton") or b:IsA("ImageLabel") then b.ImageColor3 = col end
        for _, d in ipairs(b:GetDescendants()) do
            if d:IsA("ImageLabel") or d:IsA("ImageButton") then
                d.ImageColor3 = col
            elseif d:IsA("Frame") and d.BackgroundTransparency < 1 then
                d.BackgroundColor3 = col
            end
        end
    end

    --// Debounced toggle: flips State.AutoBlock via SetAutoBlock //
    --// and syncs the UI toggle so the tab reflects the real state //
    local toggleLastTick = 0
    local TOGGLE_COOLDOWN = 0.15
    local function Toggle()
        local now = tick()
        if now - toggleLastTick < TOGGLE_COOLDOWN then return end
        toggleLastTick = now
        local newVal = not State.AutoBlock
        SetAutoBlock(newVal)
        --// Sync the tab toggle so it matches button state //
        pcall(function()
            local reg = Registry["AutoBlock"]
            if reg and reg.Element and typeof(reg.Element.Set) == "function" then
                reg.Element:Set(newVal)
            end
        end)
        --// Start or stop the block system //
        if newVal then
            StartFourthButton()
        else
            StopFourthButton()
        end
        --// Tint after start/stop settles //
        task.defer(function()
            if FourthBlock.applyTint then FourthBlock.applyTint() end
        end)
        Notify("Auto Block", newVal and "Auto Block ON" or "Auto Block OFF", 2)
    end

    --// Cache absolute position/size every frame for hit-testing fallback //
    table.insert(FourthBlock.connections, RunService.RenderStepped:Connect(function()
        if not FourthBlock.running then return end
        local b = FourthBlock.instance
        if b and b.Parent then
            local ok, p  = pcall(function() return b.AbsolutePosition end)
            local ok2, s = pcall(function() return b.AbsoluteSize end)
            if ok and ok2 then FourthBlock.cachedPos = p; FourthBlock.cachedSize = s end
        else
            FourthBlock.cachedPos = nil; FourthBlock.cachedSize = nil
        end
    end))

    --// Hit-test helper using GetGuiObjectsAtPosition with AABB fallback //
    local function IsOnButton(pos)
        local btn = FourthBlock.instance
        if not btn or not btn.Parent then return false end
        local ok, objs = pcall(function() return UserInputService:GetGuiObjectsAtPosition(pos.X, pos.Y) end)
        if ok and objs and #objs > 0 then
            local top = objs[1]
            return top == btn or top:IsDescendantOf(btn)
        end
        if not FourthBlock.cachedPos or not FourthBlock.cachedSize then return false end
        local p, s = FourthBlock.cachedPos, FourthBlock.cachedSize
        return pos.X >= p.X and pos.X <= p.X + s.X and pos.Y >= p.Y and pos.Y <= p.Y + s.Y
    end

    --// Touch/click detection: track press start, fire Toggle on release if short tap //
    local downPos, downTime = nil, 0
    table.insert(FourthBlock.connections, UserInputService.InputBegan:Connect(function(input)
        if not FourthBlock.running then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if not IsOnButton(input.Position) then return end
        downPos = input.Position; downTime = tick()
    end))
    table.insert(FourthBlock.connections, UserInputService.InputEnded:Connect(function(input)
        if not FourthBlock.running then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if not downPos then return end
        local held = tick() - downTime; downPos = nil
        if held > 0.5 then return end   --// ignore long-press //
        if not IsOnButton(input.Position) then return end
        Toggle()
    end))

    --// Bind click events to every GuiButton in the clone //
    local function BindAll(root)
        if not root then return end
        local function tb(obj)
            if not obj or not obj:IsA("GuiButton") then return end
            pcall(function() obj.Active = true; obj.Selectable = true end)
            pcall(function() obj.MouseButton1Click:Connect(Toggle) end)
            pcall(function() obj.Activated:Connect(Toggle) end)
        end
        tb(root)
        for _, d in ipairs(root:GetDescendants()) do if d:IsA("GuiObject") then tb(d) end end
    end

    --// Background loop: creates / refreshes the clone button every 0.5 s //
    task.spawn(function()
        while FourthBlock.running do
            task.wait(0.5)
            if not FourthBlock.running then break end
            local m = PlayerGui:FindFirstChild("MainUI")
            if m then
                local c = m:FindFirstChild("AbilityContainer", true)
                if c then
                    --// Pick source: Block button (most skins) or Clone button (007n7) //
                    local blockBtn = c:FindFirstChild("Block")
                    local cloneBtn = c:FindFirstChild("Clone")
                    local orig = blockBtn or cloneBtn
                    --// prefer Clone for 007n7 character //
                    if blockBtn and cloneBtn and LocalCharacter and LocalCharacter.Name == "007n7" then
                        orig = cloneBtn
                    end

                    local e = c:FindFirstChild("FourthBlockAbility")
                    local needsRecreate = false

                    if not e then
                        needsRecreate = (orig ~= nil)
                    elseif not orig then
                        needsRecreate = false
                    elseif FourthBlock.sourceName ~= orig.Name then
                        needsRecreate = true
                    elseif FourthBlock.instance ~= e then
                        FourthBlock.instance = e
                        BindAll(e)
                        if FourthBlock.applyTint then FourthBlock.applyTint() end
                    end

                    if needsRecreate and orig then
                        if e then pcall(function() e:Destroy() end) end
                        local clone = orig:Clone()
                        clone.Name = "FourthBlockAbility"
                        clone.LayoutOrder = 4
                        if clone:IsA("GuiObject") then clone.ZIndex = 50 end
                        --// Clear any Block/Clone text labels so it looks like a plain button //
                        for _, d in ipairs(clone:GetDescendants()) do
                            if d:IsA("TextLabel") or d:IsA("TextButton") then
                                local t = d.Text:lower()
                                if t:find("block") or t:find("clone") then
                                    d.Text = ""; d.Visible = false
                                end
                            end
                            if d:IsA("GuiObject") then
                                d.ZIndex = math.max(d.ZIndex, 50)
                                d.Active = true
                            end
                        end
                        clone.Parent = c
                        FourthBlock.instance = clone
                        FourthBlock.sourceName = orig.Name
                        BindAll(clone)
                        if FourthBlock.applyTint then FourthBlock.applyTint() end
                        print("[FlexSaken] ✅ 4th block button created from:", orig.Name)
                    end
                end
            end
        end
    end)

    print("[FlexSaken] AutoBlockButton ON")
end

local function StopFourthButton()
    if not FourthBlock.running then return end
    FourthBlock.running = false
    for _, c in ipairs(FourthBlock.connections) do pcall(function() c:Disconnect() end) end
    FourthBlock.connections = {}
    --// Keep the button visible — tint red to show it's off //
    local b = FourthBlock.instance
    if b and b.Parent then
        local redCol = Color3.fromRGB(255, 0, 0)
        pcall(function()
            if b:IsA("ImageButton") or b:IsA("ImageLabel") then b.ImageColor3 = redCol end
            for _, d in ipairs(b:GetDescendants()) do
                if d:IsA("ImageLabel") or d:IsA("ImageButton") then
                    d.ImageColor3 = redCol
                elseif d:IsA("Frame") and d.BackgroundTransparency < 1 then
                    d.BackgroundColor3 = redCol
                end
            end
        end)
    end
    --// Do NOT nil or destroy instance — button stays on screen //
    print("[FlexSaken] AutoBlockButton OFF")
end

--// JANE DOE — Crystal / Aimbot / Axe Lock //

local JD = {
    Enabled = false, Aimbot = false, Axe = false,
    InstaThrow = false, InfHold = false,
    AimOffset = -0.3, Prediction = 0.6, AxeDuration = 1.7,
    Patched = false, Unloaded = false, AxeLocked = false,
    CrystalHooked = false, CrystalOrig = nil, CrystalBackup = {},
    Motion = {}, EventConn = nil,
}

Risky("JaneDoe", function()
    local function GetCamera() return Workspace.CurrentCamera end

    --// Crystal config (instant charge / infinite hold) //
    local function ApplyCrystalCfg(Cfg)
        pcall(function()
            if setreadonly then setreadonly(Cfg, false) end
            if not JD.CrystalBackup[Cfg] then
                JD.CrystalBackup[Cfg] = { Min = Cfg.MinChargeTime, Max = Cfg.MaxChargeTime, Hold = Cfg.MaximumHoldTime }
            end
            local Bak = JD.CrystalBackup[Cfg]
            if JD.InstaThrow then
                Cfg.MinChargeTime = 0.01
                Cfg.MaxChargeTime = 0.01
            else
                Cfg.MinChargeTime = Bak.Min
                Cfg.MaxChargeTime = Bak.Max
            end
            --// huge finite value instead of 1/0 so charge math never hits inf/NaN //
            Cfg.MaximumHoldTime = JD.InfHold and 1e9 or Bak.Hold
        end)
    end

    local function HookCrystal()
        if JD.CrystalHooked then return true end
        if typeof(hookfunction) ~= "function" then return false end
        local Ok, Behavior = pcall(function()
            return require(ReplicatedStorage.Assets.Survivors.JaneDoe.Behavior)
        end)
        if not Ok or type(Behavior) ~= "table" then return false end
        local Crystal = Behavior.Abilities and Behavior.Abilities.Crystal
        if not Crystal or type(Crystal.Callback) ~= "function" then return false end
        JD.CrystalOrig = hookfunction(Crystal.Callback, function(F, C, ...)
            if type(F) == "table" and type(F.Config) == "table" and type(F.Config.Crystal) == "table" then
                ApplyCrystalCfg(F.Config.Crystal)
            end
            return JD.CrystalOrig(F, C, ...)
        end)
        JD.CrystalHooked = true
        return true
    end

    local function CrystalStart()
        if not HookCrystal() then
            Notify("Jane Doe", "Could not hook the Crystal ability", 4)
        end
    end

    local function CrystalRefresh()
        for Cfg in pairs(JD.CrystalBackup) do ApplyCrystalCfg(Cfg) end
    end

    --// Killer helpers //
    local function KillerVelocity(Root)
        if not Root then return Vector3.zero end
        local Now, Pos = tick(), Root.Position
        local Data = JD.Motion[Root]
        if not Data then
            JD.Motion[Root] = { Pos = Pos, Time = Now, Velocity = Vector3.zero }
            return Vector3.zero
        end
        local Dt = Now - Data.Time
        if Dt <= 0 then return Data.Velocity end
        Data.Velocity = (Pos - Data.Pos) / Dt
        Data.Pos, Data.Time = Pos, Now
        return Data.Velocity
    end

    local function NearestKillerRoot(MyRoot)
        local Players_ = Workspace:FindFirstChild("Players")
        local Folder = Players_ and Players_:FindFirstChild("Killers")
        if not Folder then return nil end
        local Best, BestDist = nil, math.huge
        for _, Killer in ipairs(Folder:GetChildren()) do
            local Root = Killer:FindFirstChild("HumanoidRootPart")
            local Hum = Killer:FindFirstChildOfClass("Humanoid")
            if Root and Hum and Hum.Health > 0 then
                local D = (Root.Position - MyRoot.Position).Magnitude
                if D < BestDist then Best, BestDist = Root, D end
            end
        end
        return Best
    end

    --// Axe lock-on //
    local function AxeLock()
        local Ok = pcall(function()
            if JD.AxeLocked then return end
            local Char = LocalPlayer.Character
            local MyRoot = Char and Char:FindFirstChild("HumanoidRootPart")
            local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
            if not MyRoot or not Hum then return end
            local Target = NearestKillerRoot(MyRoot)
            if not Target then return end

            JD.AxeLocked = true
            local SavedRotate = Hum.AutoRotate
            Hum.AutoRotate = false
            local Deadline = tick() + JD.AxeDuration
            local Conn
            local function Finish()
                if Conn then Conn:Disconnect() end
                pcall(function() Hum.AutoRotate = SavedRotate end)
                JD.AxeLocked = false
            end
            Conn = RunService.RenderStepped:Connect(function()
                local StepOk = pcall(function()
                    if tick() >= Deadline or not JD.Axe or JD.Unloaded or not MyRoot.Parent or not Target.Parent then
                        Finish()
                        return
                    end
                    local Dir = Vector3.new(Target.Position.X - MyRoot.Position.X, 0, Target.Position.Z - MyRoot.Position.Z)
                    if Dir.Magnitude > 0 then
                        MyRoot.CFrame = CFrame.new(MyRoot.Position, MyRoot.Position + Dir.Unit)
                    end
                end)
                if not StepOk then Finish() end
            end)
        end)
        if not Ok then JD.AxeLocked = false end
    end

    --// Silent aim camera solver (ballistic arc) //
    local function BuildCameraCF(MyRoot, KillerRoot, V0, G)
        local Ok, Result = pcall(function()
            local Cam = GetCamera()
            local Hum = MyRoot.Parent and MyRoot.Parent:FindFirstChildOfClass("Humanoid")
            local HipH = Hum and Hum.HipHeight or 1.35
            local Lift = (HipH + MyRoot.Size.Y / 2) / 2
            local Spawn = MyRoot.CFrame.Position + Vector3.new(0, Lift, 0)
            local Vel = KillerVelocity(KillerRoot)
            local Target = KillerRoot.Position + Vel * JD.Prediction + Vector3.new(0, JD.AimOffset, 0)
            local Delta = Target - Spawn
            local Flat = Vector3.new(Delta.X, 0, Delta.Z)
            local Dx, Dy = Flat.Magnitude, Delta.Y
            if Dx < 0.01 then
                local D = Dy >= 0 and Vector3.new(0, 1, 0) or Vector3.new(0, -1, 0)
                return CFrame.new(Cam.CFrame.Position, Cam.CFrame.Position + D)
            end
            local FlatDir = Flat.Unit
            local V2 = V0 * V0
            local Disc = V2 * V2 - G * (G * Dx * Dx + 2 * Dy * V2)
            local Theta = Disc < 0 and math.atan2(Dy, Dx) or math.atan2(V2 - math.sqrt(Disc), G * Dx)
            local T = math.tan(Theta)
            local Denom = 3 + T
            local Alpha = math.abs(Denom) < 0.0001 and -math.pi / 2 or math.atan2(3 * T - 1, Denom)
            local YawCF = CFrame.new(Cam.CFrame.Position, Cam.CFrame.Position + FlatDir)
            return YawCF * CFrame.Angles(Alpha, 0, 0)
        end)
        return Ok and Result or nil
    end

    local function ApplyPatch()
        if JD.Patched then return end
        local RF = GetSharedRF(3)
        if not RF then return end
        rfDispatch:Install(RF)
        rfDispatch:Register("jd", function(RequestName, ...)
            if not (JD.Enabled and JD.Aimbot) then return nil end
            local Char = LocalPlayer.Character
            local MyRoot = Char and Char:FindFirstChild("HumanoidRootPart")
            if not MyRoot then return nil end
            local Best = NearestKillerRoot(MyRoot)
            if not Best then return nil end
            if RequestName == "GetMousePosition" then
                return Best.Position + KillerVelocity(Best) * JD.Prediction + Vector3.new(0, JD.AimOffset, 0)
            end
            if RequestName == "GetCameraCF" then
                return BuildCameraCF(MyRoot, Best, 250, 40)
            end
            return nil
        end)
        JD.Patched = true
    end

    local function RemovePatch()
        if not JD.Patched then return end
        rfDispatch:Unregister("jd")
        if rfDispatch:Count() == 0 then rfDispatch:Uninstall() end
        JD.Patched = false
    end

    --// Watch for the Axe ability firing //
    task.spawn(function()
        local Event
        pcall(function()
            Event = ReplicatedStorage:WaitForChild("Modules", 10):WaitForChild("Network", 10)
                :WaitForChild("Network", 10):WaitForChild("RemoteEvent", 10)
        end)
        if not Event or JD.Unloaded then return end
        JD.EventConn = Event.OnClientEvent:Connect(function(...)
            if not (JD.Enabled and JD.Axe) then return end
            local Args = { ... }
            if Args[1] == "UseActorAbility" and Args[2] and Args[2][1] then
                local Ok, Text = pcall(function() return buffer.tostring(Args[2][1]) end)
                if Ok and Text and Text:find("Axe") then task.spawn(AxeLock) end
            end
        end)
    end)

    --// Reset killer motion cache when the character changes //
    LocalPlayer.CharacterAdded:Connect(function() JD.Motion = {} end)

    --// Exposed to the UI //
    Feature.JD_SetEnabled = function(On)
        JD.Enabled = On
        if On and not JD.Patched then ApplyPatch() end
    end
    Feature.JD_SetAimbot = function(On)
        JD.Aimbot = On
        if On and not JD.Patched then ApplyPatch() end
    end
    Feature.JD_SetInstaThrow = function(On)
        JD.InstaThrow = On
        if On then CrystalStart() else CrystalRefresh() end
    end
    Feature.JD_SetInfHold = function(On)
        JD.InfHold = On
        if On then CrystalStart() else CrystalRefresh() end
    end
    Feature.JD_Unload = function()
        if JD.Unloaded then return end
        JD.Unloaded = true
        JD.Enabled, JD.Aimbot, JD.Axe = false, false, false
        JD.InstaThrow, JD.InfHold = false, false
        pcall(CrystalRefresh)
        pcall(RemovePatch)
        if JD.EventConn then pcall(function() JD.EventConn:Disconnect() end); JD.EventConn = nil end
        Notify("Jane Doe", "Unloaded", 3)
    end
end)

--// AUTO BACKSTAB v4 (Two-Time) //
--// Credits: auto_backstab_v4 //

local BS = {
    --// toggles //
    isEnabled          = false,
    isAutoStudsEnabled = false,
    isDetectPingEnabled= false,
    moredirectenabled  = false,
    moredirectrn       = false,
    moredirectend      = false,
    distcheck          = false,
    isDashstabEnabled  = false,
    --// values //
    startdelay         = 0.05,
    duration           = 0.2,
    behindstuds        = 4,
    distcheckstud      = 7,
    autoStandStuds     = 5.5,
    autoRunStuds       = 3.4,
    dsStartDelay       = 0.1,
    --// runtime //
    running            = false,
    doitmate           = false,
    speed              = nil,  --// set after character loads //
    --// auto-studs smoothing //
    lastKillerModel    = nil,
    lastKillerPos      = nil,
    smoothedSpeed      = 0,
}

local TARGET_ANIMATION_ID = "100725497418533"
local DASHSTAB_ANIM_ID    = "89448354637442"

function BS.getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

function BS.getKillerFolder()
    local pf = workspace:FindFirstChild("Players")
    return pf and pf:FindFirstChild("Killers")
end

function BS.getFirstValidKiller()
    local kf = BS.getKillerFolder(); if not kf then return nil end
    for _, inst in ipairs(kf:GetDescendants()) do
        if inst:IsA("Model") then
            local hum = inst:FindFirstChildOfClass("Humanoid")
            local hrp = inst:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then return inst end
        end
    end
    return nil
end

function BS.getPing()
    local ok, v = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
    if ok and v then return v end
    local ok2, v2 = pcall(function() return LocalPlayer:GetNetworkPing() * 1000 end)
    if ok2 and v2 then return v2 end
    return 20
end

function BS.runPlaceSequence()
    if not BS.isEnabled or BS.running then return end
    BS.running = true
    local character = BS.getCharacter()
    local hrp = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)
    task.wait(BS.startdelay)
    if not character.Parent then BS.running = false; return end

    local place = Instance.new("Part")
    place.Name = "place"; place.Size = Vector3.new(2,2,2)
    place.Transparency = 0; place.CanCollide = false
    place.Anchored = true; place.Parent = character

    local origPP = character.PrimaryPart
    local oldspeed = BS.speed and BS.speed.Value or 0

    if BS.moredirectenabled then BS.moredirectrn = true; task.wait(0.01); BS.moredirectrn = false end

    local t0 = os.clock()
    local _preRenderSignal = pcall(function() return RunService.PreRender end) and RunService.PreRender or RunService.RenderStepped
    while os.clock() - t0 < BS.duration do
        if not character.Parent or not place.Parent or not BS.isEnabled then break end
        if BS.speed then BS.speed.Value = 0 end
        BS.doitmate = true
        _preRenderSignal:Wait()
    end

    if place and place.Parent then place:Destroy() end
    if character and character.Parent then character.PrimaryPart = origPP end
    if BS.speed then BS.speed.Value = oldspeed end
    BS.doitmate = false

    if BS.moredirectenabled then
        BS.moredirectrn = true; task.wait(0.01)
        BS.moredirectend = true; BS.moredirectrn = false; task.wait(0.01)
        BS.moredirectend = false
    end
    BS.running = false
end

function BS.runDashstabSequence()
    if not BS.isDashstabEnabled or BS.running then return end
    BS.running = true
    local character = BS.getCharacter()
    task.wait(BS.dsStartDelay)
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not character.Parent or not hrp then BS.running = false; return end

    local place = Instance.new("Part")
    place.Name = "place"; place.Size = Vector3.new(2,2,2)
    place.Transparency = 0; place.CanCollide = false
    place.Anchored = true; place.Parent = character

    local origPP = character.PrimaryPart
    local oldspeed = BS.speed and BS.speed.Value or 0

    if BS.moredirectenabled then BS.moredirectrn = true; task.wait(0.01); BS.moredirectrn = false end

    local _preRenderSignal2 = pcall(function() return RunService.PreRender end) and RunService.PreRender or RunService.RenderStepped
    local t0 = os.clock()
    while os.clock() - t0 < BS.duration do
        if not character.Parent or not place.Parent or not BS.isDashstabEnabled then break end
        if BS.speed then BS.speed.Value = 0 end
        BS.doitmate = true
        _preRenderSignal2:Wait()
    end

    if BS.speed then BS.speed.Value = oldspeed end
    BS.doitmate = false

    if BS.moredirectenabled then
        BS.moredirectrn = true; task.wait(0.001)
        BS.moredirectend = true; BS.moredirectrn = false; task.wait(0.001)
        BS.moredirectend = false
    end
    if place and place.Parent then place:Destroy() end
    if character and character.Parent then character.PrimaryPart = origPP end
    BS.running = false
end

--// Hook FireServerConnection to spoof position during backstab //
BS.NetworkModule = nil
BS.oldFireServer  = nil

function BS.hookNetwork()
    if BS.oldFireServer then return end
    local ok, nm = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Network"):WaitForChild("Network"))
    end)
    if not ok or type(nm) ~= "table" then return end
    if typeof(hookfunction) ~= "function" then return end
    BS.NetworkModule = nm

    BS.oldFireServer = hookfunction(nm.FireServerConnection, function(self, connectionName, eventType, ...)
        local args = {...}
        if connectionName == "UpdateCharacterPosition" then
            local character = LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local killerModel = BS.getFirstValidKiller()
            if killerModel and hrp then
                local killerHrp = killerModel:FindFirstChild("HumanoidRootPart")
                if killerHrp then
                    local CharRep
                    pcall(function()
                        CharRep = require(ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Player"):WaitForChild("Game"):WaitForChild("CharacterReplication"))
                    end)
                    if CharRep then
                        local targetCFrame    = killerHrp.CFrame * CFrame.new(0, 0, BS.behindstuds)
                        local targetDirect    = hrp.CFrame * CFrame.new(0, -90000, 0)
                        local targetDirectEnd = hrp.CFrame * CFrame.new(0, 0, 0)
                        if BS.moredirectrn then
                            args[1] = CharRep.Serialize(targetDirect, hrp.AssemblyLinearVelocity)
                        elseif BS.moredirectend then
                            args[1] = CharRep.Serialize(targetDirectEnd, hrp.AssemblyLinearVelocity)
                        elseif BS.doitmate then
                            args[1] = CharRep.Serialize(targetCFrame, hrp.AssemblyLinearVelocity)
                        end
                    end
                end
            end
        end
        return BS.oldFireServer(self, connectionName, eventType, unpack(args))
    end)
end

function BS.hookCharacter(character)
    local humanoid = character:WaitForChild("Humanoid")
    local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid:WaitForChild("Animator", 5)
    if not animator then return end

    --// Cache the speed multiplier //
    local sm = character:FindFirstChild("SpeedMultipliers")
    if sm then BS.speed = sm:FindFirstChild("Sprinting") end

    animator.AnimationPlayed:Connect(function(track)
        if not track or not track.Animation then return end
        local killer = BS.getFirstValidKiller()
        if not killer then return end
        local id = tostring(track.Animation.AnimationId or ""):gsub("%D", "")

        if (id == TARGET_ANIMATION_ID or id == "106086955212611") and BS.isEnabled then
            if BS.distcheck then
                local hrp1 = character:FindFirstChild("HumanoidRootPart")
                local hrp2 = killer:FindFirstChild("HumanoidRootPart")
                if not hrp1 or not hrp2 then return end
                if (hrp1.Position - hrp2.Position).Magnitude > BS.distcheckstud then return end
            end
            task.spawn(BS.runPlaceSequence)
        elseif (id == DASHSTAB_ANIM_ID or id == "107640065977686") and BS.isDashstabEnabled then
            if BS.distcheck then
                local hrp1 = character:FindFirstChild("HumanoidRootPart")
                local hrp2 = killer:FindFirstChild("HumanoidRootPart")
                if not hrp1 or not hrp2 then return end
                if (hrp1.Position - hrp2.Position).Magnitude > BS.distcheckstud then return end
            end
            task.spawn(BS.runDashstabSequence)
        end
    end)
end

--// Auto-studs heartbeat //
RunService.Heartbeat:Connect(function(dt)
    if not BS.isAutoStudsEnabled then
        BS.lastKillerModel = nil; BS.smoothedSpeed = 0; return
    end
    local killerModel = BS.getFirstValidKiller()
    if killerModel then
        local killerHrp = killerModel:FindFirstChild("HumanoidRootPart")
        if killerHrp then
            local currentPos = killerHrp.Position
            local rawSpeed   = 0
            if BS.lastKillerModel == killerModel and BS.lastKillerPos then
                local hd = Vector3.new(currentPos.X, 0, currentPos.Z) - Vector3.new(BS.lastKillerPos.X, 0, BS.lastKillerPos.Z)
                rawSpeed = hd.Magnitude / dt
            end
            BS.lastKillerModel = killerModel; BS.lastKillerPos = currentPos
            BS.smoothedSpeed = BS.smoothedSpeed + (rawSpeed - BS.smoothedSpeed) * math.min(dt * 15, 1)
            local finalSpeed = math.clamp(BS.smoothedSpeed, 0, 30)
            local studsAtRun = BS.autoRunStuds
            if BS.isDetectPingEnabled then
                local ping = BS.getPing()
                local cp = math.max(ping, 20)
                studsAtRun = math.max(BS.autoRunStuds - ((cp - 20) / 100) * 1.5, 1.0)
            end
            local slope = (BS.autoStandStuds - studsAtRun) / 26.0
            BS.behindstuds = BS.autoStandStuds - (finalSpeed * slope)
        else
            BS.lastKillerModel = nil
        end
    else
        BS.lastKillerModel = nil; BS.smoothedSpeed = 0
    end
end)

--// Boot: hook network + character //
task.spawn(function()
    task.wait(1)
    pcall(BS.hookNetwork)
    local char = LocalPlayer.Character
    if char then pcall(BS.hookCharacter, char) end
    LocalPlayer.CharacterAdded:Connect(function(c)
        task.wait(0.5)
        pcall(BS.hookCharacter, c)
    end)
end)

--// GUEST 1337 AUTO BLOCK STATE (for Auto Block tab) //

local G1337 = {}
G1337.killersFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers")
G1337.killersList = {"Sixer", "Slasher", "Noli", "JohnDoe", "c00lkidd", "1x1x1x1", "Nosferatu"}
G1337.attackSoundIds = {
    ["100600301396617"]=true, ["101199185291628"]=true, ["101553872555606"]=true, ["101698569375359"]=true, ["104910828105172"]=true,
    ["105204810054381"]=true, ["105207247877248"]=true, ["105516183226360"]=true, ["105840448036441"]=true, ["106836941416453"]=true,
    ["107345261604889"]=true, ["107401225947000"]=true, ["108360420637223"]=true, ["108610718831698"]=true, ["108651070773439"]=true,
    ["108907358619313"]=true, ["109348678063422"]=true, ["109570290393196"]=true, ["111295935549452"]=true, ["112809109188560"]=true,
    ["113413858159336"]=true, ["114481520550129"]=true, ["115026634746636"]=true, ["115343460993527"]=true, ["115678417928765"]=true,
    ["116468089135195"]=true, ["116581754553533"]=true, ["117173212095661"]=true, ["117231507259853"]=true, ["118562842802948"]=true,
    ["119583605486352"]=true, ["119664480754070"]=true, ["119942598489800"]=true, ["120749612844426"]=true, ["121853342688333"]=true,
    ["121954639447247"]=true, ["12222208"]=true, ["12222216"]=true, ["122398404613193"]=true, ["123835423223220"]=true,
    ["123923371062204"]=true, ["124234993291213"]=true, ["124903763333174"]=true, ["125213046326879"]=true, ["126469686116453"]=true,
    ["127557531826290"]=true, ["128195973631079"]=true, ["128367348686124"]=true, ["128856426573270"]=true, ["131123355704017"]=true,
    ["132160759837000"]=true, ["132581672170205"]=true, ["133709029886490"]=true, ["134720314512566"]=true, ["135256560060972"]=true,
    ["135319730390518"]=true, ["136323728355613"]=true, ["137809737339569"]=true, ["138047522440301"]=true, ["139996647355899"]=true,
    ["140242176732868"]=true, ["18511965048"]=true, ["70626755789950"]=true, ["70739368096233"]=true, ["71805956520207"]=true,
    ["72085713525541"]=true, ["73662192846371"]=true, ["74809026448465"]=true, ["74842815979546"]=true, ["75330693422988"]=true,
    ["77649238882198"]=true, ["79391273191671"]=true, ["79612713897495"]=true, ["79980897195554"]=true, ["80516583309685"]=true,
    ["82221759983649"]=true, ["82843272472677"]=true, ["84307400688050"]=true, ["85853080745515"]=true, ["86174610237192"]=true,
    ["86506028049034"]=true, ["88589682639517"]=true, ["89004992452376"]=true, ["92869747208256"]=true, ["93299090238530"]=true,
    ["94273783714662"]=true, ["94317217837143"]=true, ["94632255644411"]=true, ["95079963655241"]=true, ["95863147467940"]=true,
    ["96117920303138"]=true, ["96594507550917"]=true, ["98111231282218"]=true, ["98675142200448"]=true, ["98733709078792"]=true,
    ["98742773509325"]=true, ["98866992038428"]=true, ["99215225043220"]=true, ["99856718263455"]=true, ["99918466107008"]=true,
}
G1337.special1x1Sound = "70845653728841"
G1337.PUNCH_ANIM_IDS = {
    ["87259391926321"] = true, ["140703210927645"] = true, ["136007065400978"] = true,
    ["129843313690921"] = true, ["86709774283672"] = true, ["108807732150251"] = true,
    ["138040001965654"] = true, ["86096387000557"] = true
}
G1337.settings = {
    autoblock = false, hd = false, onlyLooking = true, wallCheck = true,
    sphereRange = 11, sphereEsp = false, customEsp = false,
    boxLength = 15, boxWidth = 6, hdSpeed = 12,
    reactTime = 0.01,
}
getgenv().PunchAimbot = getgenv().PunchAimbot or { Enabled = true, Mode = "Camera", Smoothness = 0.14, Prediction = 0.133 }
getgenv().AutoPunch   = getgenv().AutoPunch   or { Enabled = false, Range = 50, ShowRange = false, TrueDash = false }
G1337.spheres, G1337.boxes = {}, {}
G1337.inSphere, G1337.inBox, G1337.hasLos = {}, {}, {}
G1337.lastSoundTime, G1337.advicePart, G1337.pulling = {}, nil, false

G1337.CurrentConn, G1337.CurrentTarget = nil, nil
G1337.PunchSphere = nil
G1337.dashing = false
Risky("G1337Remote", function()
    local ok, r = pcall(function()
        return ReplicatedStorage.Modules.Network.RemoteEvent
    end)
    if ok and r then
        G1337.remote = r
    else
        --// Fallback: try the same remote already found by the main script //
        G1337.remote = Remote
    end
end)

G1337.rayParams = RaycastParams.new()
G1337.rayParams.FilterType = Enum.RaycastFilterType.Exclude
G1337.rayParams.IgnoreWater = true

function G1337.isHelpless()
    local ok, obj = pcall(function()
        return LocalPlayer.PlayerGui.MainUI.AbilityContainer.Block:FindFirstChild("Helpless")
    end)
    return ok and obj ~= nil
end
function G1337.canUseBlock()
    if G1337.isHelpless() then return false end
    --// Try the Clipping size check first //
    local ok, clip = pcall(function()
        return LocalPlayer.PlayerGui.MainUI.AbilityContainer.Block.Clipping
    end)
    if ok and clip then
        --// Clipping at full size = block is off cooldown //
        if clip.Size == UDim2.new(1,0,1,0) then return true end
        --// Also accept if clip is >= 0.95 in Y (nearly full = ready) //
        if clip.Size.Y.Scale >= 0.95 then return true end
        --// If clipping exists but is at 0,0 = fully on cooldown — block not ready //
        if clip.Size.Y.Scale <= 0.01 then return false end
        --// Otherwise treat partial clip as ready (conservative fallback) //
        return true
    end
    --// Fallback: if we can't find the clip element, check for a CooldownTime value //
    local ok2, btn = pcall(function()
        return LocalPlayer.PlayerGui.MainUI.AbilityContainer.Block
    end)
    if ok2 and btn then
        local cd = btn:FindFirstChild("CooldownTime") or btn:FindFirstChild("Cooldown")
            or btn:FindFirstChildWhichIsA("NumberValue")
        if cd and type(cd.Value) == "number" then
            return cd.Value <= 0.05
        end
        --// No cooldown child found — assume block is usable //
        return true
    end
    --// Can't determine state at all — allow it and let server reject if needed //
    return true
end
function G1337.hasLineOfSight(targetRoot)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return false end
    local origin = LocalPlayer.Character.HumanoidRootPart.Position
    local direction = targetRoot.Position - origin
    G1337.rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    local result = workspace:Raycast(origin, direction, G1337.rayParams)
    return not result or result.Instance:IsDescendantOf(targetRoot.Parent)
end
function G1337.show1x1Advice(root)
    if G1337.advicePart then G1337.advicePart:Destroy() end
    G1337.advicePart = Instance.new("Part")
    G1337.advicePart.Size = Vector3.new(14,5,14)
    G1337.advicePart.Material = Enum.Material.Neon
    G1337.advicePart.Color = Color3.fromRGB(255,0,255)
    G1337.advicePart.Transparency = 0.3
    G1337.advicePart.Anchored = true
    G1337.advicePart.CanCollide = false
    G1337.advicePart.CFrame = CFrame.lookAt(root.Position - root.CFrame.LookVector * 10, root.Position)
    G1337.advicePart.Parent = workspace
    task.delay(0.5, function() if G1337.advicePart then G1337.advicePart:Destroy() G1337.advicePart = nil end end)
end
function G1337.doHDPull(targetPos)
    if G1337.pulling then return end
    G1337.pulling = true
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildWhichIsA("Humanoid")
    if not hrp or not hum then G1337.pulling = false return end
    local savedSpeed = hum.WalkSpeed
    pcall(function() hum.WalkSpeed = G1337.settings.hdSpeed * 5 end)
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not hrp or not hum or not hum.Parent then
            if conn then conn:Disconnect() end
            G1337.pulling = false
            return
        end
        local vec = targetPos - hrp.Position
        local flat = Vector3.new(vec.X, 0, vec.Z)
        if flat.Magnitude < 4 then
            hum:Move(Vector3.zero, false)
            pcall(function() hum.WalkSpeed = savedSpeed end)
            if conn then conn:Disconnect() end
            G1337.pulling = false
            return
        end
        hum:Move(flat.Unit, false)
    end)
    task.delay(0.5, function()
        if conn then conn:Disconnect() end
        pcall(function()
            if hum and hum.Parent then
                hum:Move(Vector3.zero, false)
                hum.WalkSpeed = savedSpeed
            end
        end)
        G1337.pulling = false
    end)
end
G1337.lastDashTime = 0
local DASH_COOLDOWN = 0.4  --// seconds between allowed dashes, covers dash duration + punch cooldown //

function G1337.TrueDash()
    --// Guard: TrueDash toggle must be on AND AutoPunch must be on //
    if not getgenv().AutoPunch.TrueDash then return end
    if not getgenv().AutoPunch.Enabled then return end
    if G1337.dashing then return end
    local now = os.clock()
    if now - G1337.lastDashTime < DASH_COOLDOWN then return end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    G1337.dashing = true
    G1337.lastDashTime = now
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5, 0, 1e5)
    bv.Velocity = hrp.CFrame.LookVector * 200
    bv.Parent = hrp
    task.delay(0.25, function()
        if bv and bv.Parent then bv:Destroy() end
        G1337.dashing = false
    end)
end
function G1337.getNearestKiller()
    local closest, shortest = nil, math.huge
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot or not G1337.killersFolder then return nil end
    for _, name in ipairs(G1337.killersList) do
        local killer = G1337.killersFolder:FindFirstChild(name)
        if killer and killer:FindFirstChild("HumanoidRootPart") and killer:FindFirstChild("Humanoid") and killer.Humanoid.Health > 0 then
            local dist = (killer.HumanoidRootPart.Position - myRoot.Position).Magnitude
            if dist < shortest then shortest = dist; closest = killer end
        end
    end
    return closest
end
function G1337.startAiming(target)
    if G1337.CurrentConn then G1337.CurrentConn:Disconnect() end
    G1337.CurrentTarget = target
    G1337.CurrentConn = RunService.RenderStepped:Connect(function()
        if not getgenv().PunchAimbot.Enabled or not G1337.CurrentTarget or not G1337.CurrentTarget:FindFirstChild("HumanoidRootPart") then
            if G1337.CurrentConn then G1337.CurrentConn:Disconnect() G1337.CurrentConn = nil end
            G1337.CurrentTarget = nil return
        end
        local tRoot = G1337.CurrentTarget.HumanoidRootPart
        local pred = tRoot.Position + tRoot.AssemblyLinearVelocity * getgenv().PunchAimbot.Prediction
        if getgenv().PunchAimbot.Mode == "Camera" then
            workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(CFrame.new(workspace.CurrentCamera.CFrame.Position, pred), getgenv().PunchAimbot.Smoothness)
        else
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myRoot then myRoot.CFrame = CFrame.lookAt(myRoot.Position, pred) end
        end
    end)
end
function G1337.stopAiming()
    if G1337.CurrentConn then G1337.CurrentConn:Disconnect() G1337.CurrentConn = nil end
    G1337.CurrentTarget = nil
end
function G1337.setupPunchAimbot(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.AnimationPlayed:Connect(function(track)
        local id = track.Animation.AnimationId:match("%d+$")
        if G1337.PUNCH_ANIM_IDS[id] and getgenv().PunchAimbot.Enabled then
            local target = G1337.getNearestKiller()
            if target then G1337.startAiming(target) track.Stopped:Connect(G1337.stopAiming) end
        end
    end)
end
if LocalPlayer.Character then G1337.setupPunchAimbot(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(G1337.setupPunchAimbot)

function G1337.updateESP()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    if not G1337.killersFolder then
        G1337.killersFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers")
        if not G1337.killersFolder then return end
    end
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    for _, killerName in ipairs(G1337.killersList) do
        local killer = G1337.killersFolder:FindFirstChild(killerName)
        local root = killer and killer:FindFirstChild("HumanoidRootPart")
        if not root then
            G1337.inSphere[killerName], G1337.inBox[killerName], G1337.hasLos[killerName] = false, false, false
        else
        local distance = (myPos - root.Position).Magnitude
        local los = G1337.hasLineOfSight(root)
        G1337.hasLos[killerName] = los
        G1337.inSphere[killerName] = distance <= G1337.settings.sphereRange
        if G1337.settings.sphereEsp then
            local sphere = G1337.spheres[killerName] or Instance.new("Part")
            if not G1337.spheres[killerName] then
                sphere.Name = "G1337Sphere_"..killerName
                sphere.Shape = Enum.PartType.Ball
                sphere.Material = Enum.Material.Neon
                sphere.Anchored = true; sphere.CanCollide = false; sphere.Transparency = 0.85
                sphere.Size = Vector3.new(G1337.settings.sphereRange*2, G1337.settings.sphereRange*2, G1337.settings.sphereRange*2)
                sphere.Parent = workspace
                G1337.spheres[killerName] = sphere
            end
            sphere.CFrame = root.CFrame
            sphere.Color = (distance <= G1337.settings.sphereRange and (not G1337.settings.wallCheck or los)) and Color3.new(0,1,0) or Color3.new(1,0,0)
        end
        if G1337.settings.customEsp then
            local box = G1337.boxes[killerName] or Instance.new("Part")
            if not G1337.boxes[killerName] then
                box.Name = "G1337Box_"..killerName
                box.Material = Enum.Material.Neon; box.Anchored = true; box.CanCollide = false; box.Transparency = 0.85
                box.Parent = workspace; G1337.boxes[killerName] = box
            end
            local yOffset = (killerName == "Sixer") and -2 or 0
            local forward = root.CFrame.LookVector * (G1337.settings.boxLength/2 + 3 - 4)
            local boxPos = root.Position + forward + Vector3.new(0, yOffset, 0)
            box.Size = Vector3.new(G1337.settings.boxWidth, 3, G1337.settings.boxLength)
            box.CFrame = CFrame.lookAt(boxPos, boxPos + root.CFrame.LookVector * 100)
            local relative = myPos - box.Position
            local localSpace = box.CFrame:VectorToObjectSpace(relative)
            local half = box.Size / 2
            local inside = math.abs(localSpace.X) <= half.X and math.abs(localSpace.Y) <= half.Y and math.abs(localSpace.Z) <= half.Z
            G1337.inBox[killerName] = inside
            box.Color = (inside and (not G1337.settings.wallCheck or los)) and Color3.new(0,1,0) or Color3.new(1,0,0)
        end
        end --// close else (root exists) //
    end
end

function G1337.UpdatePunchESP()
    if not getgenv().AutoPunch.ShowRange then
        if G1337.PunchSphere then G1337.PunchSphere:Destroy() G1337.PunchSphere = nil end
        return
    end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if not G1337.PunchSphere then
        G1337.PunchSphere = Instance.new("CylinderHandleAdornment")
        G1337.PunchSphere.Name = "G1337_PunchRange"
        G1337.PunchSphere.Adornee = hrp
        G1337.PunchSphere.Color3 = Color3.fromRGB(255, 0, 100)
        G1337.PunchSphere.Transparency = 0.6
        G1337.PunchSphere.AlwaysOnTop = true
        G1337.PunchSphere.ZIndex = 10
        G1337.PunchSphere.Height = 0.1
        G1337.PunchSphere.CFrame = CFrame.Angles(math.rad(90), 0, 0)
        G1337.PunchSphere.Parent = hrp
    end
    G1337.PunchSphere.Radius = getgenv().AutoPunch.Range / 1.5
end

function G1337.Step()
    G1337.updateESP()
    G1337.UpdatePunchESP()
    if not G1337.killersFolder then return end
    --// Auto punch handled by original TimesHit watcher (see CharacterCallbacks) //
    if not (G1337.settings.autoblock or G1337.settings.hd) or not G1337.canUseBlock() then return end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    for _, killerName in ipairs(G1337.killersList) do
        local killer = G1337.killersFolder:FindFirstChild(killerName)
        if killer then
            local root = killer:FindFirstChild("HumanoidRootPart")
            local head = killer:FindFirstChild("Head")
            if root and head then
                local dist = (myPos - root.Position).Magnitude
                local facingOk = not G1337.settings.onlyLooking or head.CFrame.LookVector:Dot((myPos - head.Position).Unit) >= 0.5
                if dist <= G1337.settings.sphereRange + 20 and facingOk then
                    local los = G1337.hasLos[killerName] or G1337.hasLineOfSight(root)
                    local inRange = G1337.inSphere[killerName] or dist <= G1337.settings.sphereRange
                    local inCustomBox = G1337.inBox[killerName] or false
                    local inDangerZone = (G1337.settings.sphereEsp and inRange and (not G1337.settings.wallCheck or los)) or
                                         (G1337.settings.customEsp and inCustomBox and (not G1337.settings.wallCheck or los)) or
                                         (not G1337.settings.sphereEsp and not G1337.settings.customEsp and inRange and (not G1337.settings.wallCheck or los))
                    if inDangerZone then
                        local now = os.clock()
                        for _, sound in pairs(killer:GetDescendants()) do
                            if sound:IsA("Sound") and sound.Playing then
                                local id = sound.SoundId:match("%d+") or ""
                                if killerName == "1x1x1x1" and id == G1337.special1x1Sound then
                                    if not G1337.lastSoundTime[id] or now - G1337.lastSoundTime[id] > 1 then
                                        G1337.lastSoundTime[id] = now
                                        G1337.show1x1Advice(root)
                                        task.spawn(function()
                                            task.wait(0.65 + (G1337.settings.reactTime or 0.01))
                                            if G1337.settings.autoblock and G1337.canUseBlock() then
                                                G1337.remote:FireServer("UseActorAbility", {"Block"})
                                            end
                                            if G1337.settings.hd and G1337.canUseBlock() then G1337.doHDPull(root.Position) end
                                        end)
                                    end
                                    break
                                end
                                if G1337.attackSoundIds[id] and (not G1337.lastSoundTime[id] or now - G1337.lastSoundTime[id] > 0.2) then
                                    G1337.lastSoundTime[id] = now
                                    task.spawn(function()
                                        task.wait(G1337.settings.reactTime or 0.01)
                                        if G1337.settings.autoblock and G1337.canUseBlock() then
                                            G1337.remote:FireServer("UseActorAbility", {"Block"})
                                        end
                                        if G1337.settings.hd and G1337.canUseBlock() then G1337.doHDPull(root.Position) end
                                    end)
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

RunService.Heartbeat:Connect(function() pcall(G1337.Step) end)

--// Sound hook: catch attack sounds the instant they play, not on next Heartbeat poll //
--// This fixes the race condition where sound.Playing is already false by the time Step runs //
local G1337_soundConns = {}
local function G1337_hookKillerSounds(killerModel)
    if not killerModel then return end
    local name = killerModel.Name
    --// Hook all existing sounds //
    local function hookSound(sound)
        if not sound:IsA("Sound") then return end
        local conn = sound.Played:Connect(function()
            if not G1337.settings.autoblock and not G1337.settings.hd then return end
            local id = sound.SoundId:match("%d+") or ""
            local now = os.clock()
            --// 1x1 special sound //
            if name == "1x1x1x1" and id == G1337.special1x1Sound then
                if not G1337.lastSoundTime[id] or now - G1337.lastSoundTime[id] > 1 then
                    G1337.lastSoundTime[id] = now
                    local root = killerModel:FindFirstChild("HumanoidRootPart")
                    if root then G1337.show1x1Advice(root) end
                    task.spawn(function()
                        task.wait(0.65 + (G1337.settings.reactTime or 0.01))
                        if G1337.settings.autoblock and G1337.canUseBlock() then
                            G1337.remote:FireServer("UseActorAbility", {"Block"})
                        end
                        local root2 = killerModel:FindFirstChild("HumanoidRootPart")
                        if G1337.settings.hd and G1337.canUseBlock() and root2 then
                            G1337.doHDPull(root2.Position)
                        end
                    end)
                end
                return
            end
            --// Normal attack sound //
            if G1337.attackSoundIds[id] and (not G1337.lastSoundTime[id] or now - G1337.lastSoundTime[id] > 0.2) then
                G1337.lastSoundTime[id] = now
                task.spawn(function()
                    task.wait(G1337.settings.reactTime or 0.01)
                    if G1337.settings.autoblock and G1337.canUseBlock() then
                        G1337.remote:FireServer("UseActorAbility", {"Block"})
                    end
                    local root2 = killerModel:FindFirstChild("HumanoidRootPart")
                    if G1337.settings.hd and G1337.canUseBlock() and root2 then
                        G1337.doHDPull(root2.Position)
                    end
                end)
            end
        end)
        table.insert(G1337_soundConns, conn)
    end
    --// Hook existing sounds //
    for _, d in ipairs(killerModel:GetDescendants()) do hookSound(d) end
    --// Hook sounds added later (some killers stream them in) //
    local dc = killerModel.DescendantAdded:Connect(hookSound)
    table.insert(G1337_soundConns, dc)
end

--// Hook killers already in the folder //
local function G1337_hookAllKillers()
    local kf = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers")
    if not kf then return end
    for _, k in ipairs(kf:GetChildren()) do G1337_hookKillerSounds(k) end
    kf.ChildAdded:Connect(G1337_hookKillerSounds)
end

--// Run once folder is available, retry until it exists //
task.spawn(function()
    local kf
    for _ = 1, 60 do
        kf = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers")
        if kf then break end
        task.wait(1)
    end
    if kf then G1337_hookAllKillers() end
end)

--// VEERONICA AUTO TRICK (from DoomSaken) //

local VR = {}
VR.behaviorFolder = nil
pcall(function()
    VR.behaviorFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Survivors"):WaitForChild("Veeronica"):WaitForChild("Behavior")
end)
VR.enabled = false
VR.activeMonitors = {}
VR.descendantAddedConn = nil
function VR.safeConnectPropertyChanged(instance, prop, fn)
    local ok, signal = pcall(function() return instance:GetPropertyChangedSignal(prop) end)
    if ok and signal then return signal:Connect(fn) end
    return nil
end
function VR.monitorHighlight(h)
    if not h or VR.activeMonitors[h] then return end
    local connections = {}
    local prevState = false
    local function cleanup()
        for _, conn in ipairs(connections) do
            if conn and conn.Connected then conn:Disconnect() end
        end
        VR.activeMonitors[h] = nil
    end
    local function adorneeIsPlayerCharacter()
        if not h.Adornee then return false end
        local char = LocalPlayer.Character
        if not char then return false end
        return h.Adornee == char or h.Adornee:IsDescendantOf(char)
    end
    local function onChanged()
        if not VR.enabled or not h.Parent then cleanup(); return end
        local currState = adorneeIsPlayerCharacter()
        if prevState ~= currState and currState then
            local success, btn = pcall(function()
                return LocalPlayer.PlayerGui:WaitForChild("MainUI"):WaitForChild("SprintingButton")
            end)
            if success and btn then
                for _, v in pairs(getconnections(btn.MouseButton1Down)) do
                    pcall(v.Fire, v)
                end
            end
        end
        prevState = currState
    end
    local c = VR.safeConnectPropertyChanged(h, "Adornee", onChanged)
    if c then table.insert(connections, c) end
    table.insert(connections, h.AncestryChanged:Connect(function(_, parent)
        if not parent then cleanup() else onChanged() end
    end))
    table.insert(connections, LocalPlayer.CharacterAdded:Connect(onChanged))
    table.insert(connections, LocalPlayer.CharacterRemoving:Connect(onChanged))
    VR.activeMonitors[h] = cleanup
    task.spawn(onChanged)
end
function VR.startManager()
    if VR.descendantAddedConn or not VR.behaviorFolder then return end
    for _, desc in ipairs(VR.behaviorFolder:GetDescendants()) do
        if desc:IsA("Highlight") then VR.monitorHighlight(desc) end
    end
    VR.descendantAddedConn = VR.behaviorFolder.DescendantAdded:Connect(function(child)
        if child:IsA("Highlight") then VR.monitorHighlight(child) end
    end)
end
function VR.stopManager()
    if VR.descendantAddedConn and VR.descendantAddedConn.Connected then
        VR.descendantAddedConn:Disconnect()
    end
    VR.descendantAddedConn = nil
    for _, cleanup in pairs(VR.activeMonitors) do pcall(cleanup) end
    VR.activeMonitors = {}
end

--// ELLIOT INFINITE RUSH HOUR (from DoomSaken) //

local EL = {}
EL.rushFrame = nil
EL.rushEnabled = false
EL.isOnCooldown = false
EL.cooldownTime = 6
EL.sprintModule = nil
EL.defaultSprintSpeed = 22
pcall(function()
    EL.sprintModule = require(ReplicatedStorage.Systems.Character.Game.Sprinting)
    EL.defaultSprintSpeed = EL.sprintModule.SprintSpeed
end)
function EL.createRushUI()
    if EL.rushFrame then return end
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "EL_RushHourUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = LocalPlayer.PlayerGui
    local DragFrame = Instance.new("Frame")
    DragFrame.Size = UDim2.fromOffset(68, 68)
    DragFrame.Position = UDim2.new(0.5, 0, 0, -4)
    DragFrame.AnchorPoint = Vector2.new(0.5, 0)
    DragFrame.BackgroundTransparency = 1
    DragFrame.Visible = false
    DragFrame.Parent = ScreenGui
    EL.rushFrame = DragFrame
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    local function updateInput(input)
        local delta = input.Position - dragStart
        DragFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    DragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = DragFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    DragFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then updateInput(input) end
    end)
    local Button = Instance.new("ImageButton")
    Button.Size = UDim2.fromScale(1, 1)
    Button.BackgroundTransparency = 1
    Button.Image = "rbxassetid://128250550180598"
    Button.Parent = DragFrame; Button.ZIndex = 2
    local CoolLabel = Instance.new("TextLabel")
    CoolLabel.Size = UDim2.fromScale(1, 1)
    CoolLabel.BackgroundTransparency = 1
    CoolLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    CoolLabel.TextScaled = false; CoolLabel.TextSize = 68 * 0.175
    CoolLabel.Text = ""; CoolLabel.ZIndex = 3; CoolLabel.Parent = Button
    pcall(function() CoolLabel.FontFace = Font.fromEnum(Enum.Font.LithiumWeb) end)
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(0, 0, 0); Stroke.Thickness = 2.8; Stroke.Parent = CoolLabel
    local NoChargeOverlay = Instance.new("ImageLabel")
    NoChargeOverlay.Size = UDim2.fromScale(1,1); NoChargeOverlay.BackgroundTransparency = 1
    NoChargeOverlay.Image = ""; NoChargeOverlay.Visible = false
    NoChargeOverlay.Parent = Button; NoChargeOverlay.ZIndex = 1
    Button.MouseButton1Click:Connect(function()
        if EL.isOnCooldown then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        if not hum then return end
        local activationSound = Instance.new("Sound")
        activationSound.SoundId = "rbxassetid://84766394210518"
        activationSound.Volume = 0.7
        activationSound.Parent = SoundService
        activationSound:Play()
        activationSound.Ended:Connect(function() activationSound:Destroy() end)
        EL.isOnCooldown = true
        local startTime = tick()
        NoChargeOverlay.Visible = true
        CoolLabel.Text = tostring(EL.cooldownTime)
        Button.ImageTransparency = 0.5
        if EL.sprintModule then EL.sprintModule.SprintSpeed = 33.4 end
        pcall(function()
            workspace.Players.Survivors.Elliot.FOVMultipliers.Sprinting.Value = 1.35
        end)
        local conn
        conn = RunService.RenderStepped:Connect(function()
            local elapsed = tick() - startTime
            local remaining = EL.cooldownTime - elapsed
            if elapsed >= EL.cooldownTime then
                if EL.sprintModule then EL.sprintModule.SprintSpeed = EL.defaultSprintSpeed end
                pcall(function() workspace.Players.Survivors.Elliot.FOVMultipliers.Sprinting.Value = 1 end)
                CoolLabel.Text = ""; NoChargeOverlay.Visible = false; Button.ImageTransparency = 0
                task.spawn(function()
                    if hum then
                        hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
                        task.wait()
                        hum:ChangeState(Enum.HumanoidStateType.Running)
                    end
                end)
                conn:Disconnect(); EL.isOnCooldown = false
            else
                CoolLabel.Text = tostring(math.ceil(remaining))
            end
        end)
    end)
end

--// ELLIOT AIMBOT (from DoomSaken) //

EL.trackedAnimationId = "114155003741146"
EL.DetectionEnabled = false
EL.Connection = nil
EL.originalAutoRotate = nil
EL.predictionStuds = 5
EL.frontOffset = 2
EL.movementThreshold = 16
EL.aimType = "HRP Aimbot"
function EL.setupCharacter(char)
    EL.Humanoid = char:WaitForChild("Humanoid")
    EL.HRP = char:WaitForChild("HumanoidRootPart")
end
if LocalPlayer.Character then task.spawn(EL.setupCharacter, LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(EL.setupCharacter)
function EL.getPlayingAnimationIds()
    local ids = {}
    if EL.Humanoid then
        for _, track in ipairs(EL.Humanoid:GetPlayingAnimationTracks()) do
            if track.Animation and track.Animation.AnimationId then
                local id = track.Animation.AnimationId:match("%d+")
                if id then ids[id] = true end
            end
        end
    end
    return ids
end
function EL.getValidTarget()
    local survivorsFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Survivors")
    if not survivorsFolder or not EL.HRP then return nil end
    local bestTarget, bestValue = nil, math.huge
    for _, target in ipairs(survivorsFolder:GetChildren()) do
        if target ~= LocalPlayer.Character then
            local hum = target:FindFirstChildOfClass("Humanoid")
            local hrp = target:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 and hum.Health < hum.MaxHealth then
                if hum.Health < bestValue then bestTarget, bestValue = hrp, hum.Health end
            end
        end
    end
    return bestTarget
end
function EL.AimAt(targetHRP)
    if not targetHRP or not targetHRP.Parent then return end
    local targetVel = targetHRP.AssemblyLinearVelocity
    local targetPos = targetHRP.Position
    local baseTargetPos = targetPos + targetHRP.CFrame.LookVector * EL.frontOffset
    local predictedPos = baseTargetPos
    if targetVel.Magnitude > EL.movementThreshold then
        predictedPos = baseTargetPos + targetVel.Unit * EL.predictionStuds
    end
    if EL.HRP then
        if not EL.originalAutoRotate then EL.originalAutoRotate = EL.Humanoid.AutoRotate end
        EL.Humanoid.AutoRotate = false
        EL.HRP.AssemblyAngularVelocity = Vector3.new(0,0,0)
        local direction = (predictedPos - EL.HRP.Position).Unit
        local yRot = math.atan2(-direction.X, -direction.Z)
        local currentCFrame = EL.HRP.CFrame
        local currentYRot = select(2, currentCFrame:ToEulerAnglesYXZ())
        local lerpedYRot = currentYRot + (yRot - currentYRot) * 0.3
        EL.HRP.CFrame = CFrame.new(currentCFrame.Position) * CFrame.Angles(0, lerpedYRot, 0)
    end
    if EL.aimType == "Camera Aimbot" then
        workspace.CurrentCamera.CFrame = CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, predictedPos)
    end
end

--// TABS //

local function UnloadScript()
    for Key, Entry in pairs(Registry) do
        if Entry.Kind == "toggle" and State[Key] and Entry.Callback then pcall(Entry.Callback, false) end
    end
    pcall(function() rfDispatch:Uninstall() end)
    pcall(function() HitboxFolder:Destroy() end)
    pcall(function() VisualCheckBeam:Destroy() end)
    pcall(function() Window:Destroy() end)
    pcall(function()
        local Marker = CoreGui:FindFirstChild("FlexSaken")
        if Marker then Marker:Destroy() end
    end)
    pcall(function() getgenv()._flexsakenESP = nil end)
end

local TabAutoBlock = Window:Tab({ Title = "Auto Block", Icon = "shield" })
local TabVeeronica = Window:Tab({ Title = "Veeronica",  Icon = "star" })
local TabElliot    = Window:Tab({ Title = "Elliot",     Icon = "zap" })
local TabMisc      = Window:Tab({ Title = "Misc",       Icon = "settings" })
local TabVisual    = Window:Tab({ Title = "Visual",     Icon = "sparkles" })
local TabMovement  = Window:Tab({ Title = "Movement",   Icon = "arrow-up" })
local TabSurvivor  = Window:Tab({ Title = "Survivor",   Icon = "user" })
local TabKiller    = Window:Tab({ Title = "Killer",     Icon = "skull" })
local TabTwoTime   = Window:Tab({ Title = "Two Time",   Icon = "sword" })
local TabExtra     = Window:Tab({ Title = "Extra",      Icon = "zap" })

--// Auto Block (Original FluxSaken — QueryHitbox / Sound / Anim based) //
AddSection(TabAutoBlock, "Original Auto Block")
AddToggle(TabAutoBlock, "AutoBlock", "Auto Block", false, function(v)
    SetAutoBlock(v)
    if v then
        StartFourthButton()
        --// tint green once button is live //
        task.defer(function()
            if FourthBlock and FourthBlock.applyTint then FourthBlock.applyTint() end
        end)
    else
        --// tint red first so button shows as off, then stop //
        if FourthBlock and FourthBlock.applyTint then
            pcall(FourthBlock.applyTint)
        end
        --// Keep the button visible but visually off (red); only fully stop after a frame //
        task.defer(function()
            StopFourthButton()
            --// If the button instance still exists after stop, force red tint //
            if FourthBlock and FourthBlock.instance and FourthBlock.instance.Parent then
                local b = FourthBlock.instance
                local redCol = Color3.fromRGB(255, 0, 0)
                pcall(function()
                    if b:IsA("ImageButton") or b:IsA("ImageLabel") then b.ImageColor3 = redCol end
                    for _, d in ipairs(b:GetDescendants()) do
                        if d:IsA("ImageLabel") or d:IsA("ImageButton") then
                            d.ImageColor3 = redCol
                        elseif d:IsA("Frame") and d.BackgroundTransparency < 1 then
                            d.BackgroundColor3 = redCol
                        end
                    end
                end)
            end
        end)
    end
end)
AddToggle(TabAutoBlock, "StrictVisualCheck", "Strict Visual Check (Beam)", false)
AddToggle(TabAutoBlock, "HitboxDrag",        "Hitbox Drag",                false)
AddSlider(TabAutoBlock, "HitboxDragRange",   "Drag Range (studs)",   5,  60,  30,  1)
AddSlider(TabAutoBlock, "DragSpeed",         "Drag Speed",           1,  40,  14,  1)
AddSlider(TabAutoBlock, "BlockDelay",        "Block Delay (ms)",     0,  200, 0,   1)
AddSection(TabAutoBlock, "Punch (Original)")
AddToggle(TabAutoBlock, "PunchAimbot", "Punch Aimbot (Two-Time)", false)
AddToggle(TabAutoBlock, "AutoPunch",   "Auto Punch Counter",       false)

--// Auto Block (Guest 1337 Features) //
AddSection(TabAutoBlock, "Auto Block Alt (G1337)")
AddToggle(TabAutoBlock, "G1337_AutoBlock", "Autoblock", false, function(v) G1337.settings.autoblock = v end)
AddToggle(TabAutoBlock, "G1337_OnlyLooking", "Only When Looking", true, function(v) G1337.settings.onlyLooking = v end)
AddToggle(TabAutoBlock, "G1337_WallCheck", "Wall Check", true, function(v) G1337.settings.wallCheck = v end)
AddSlider(TabAutoBlock, "G1337_ReactTime", "React Time (s)", 0.001, 0.5, 0.01, 0.001, function(v) G1337.settings.reactTime = v end)
AddSection(TabAutoBlock, "Auto Punch Settings")
AddToggle(TabAutoBlock, "G1337_PunchAimbot", "Punch Aimbot (Locks on Killer)", true, function(v) getgenv().PunchAimbot.Enabled = v end)
AddDropdown(TabAutoBlock, "G1337_AimMode", "Aim Mode", {"Camera (Smooth)", "RootPart (Instant)"}, "Camera (Smooth)", function(o)
    getgenv().PunchAimbot.Mode = (o:find("Camera") and "Camera" or "RootPart")
end)
AddSlider(TabAutoBlock, "G1337_Smoothness", "Smoothness", 1, 100, 14, 1, function(v) getgenv().PunchAimbot.Smoothness = v / 100 end)
AddSlider(TabAutoBlock, "G1337_Prediction", "Prediction", 0, 50, 14, 1, function(v) getgenv().PunchAimbot.Prediction = v / 100 end)
AddToggle(TabAutoBlock, "G1337_AutoPunch", "Auto Punch (Spams on Killers)", false, function(v) getgenv().AutoPunch.Enabled = v end)
AddToggle(TabAutoBlock, "G1337_TrueDash", "True Dash Punch", false, function(v) getgenv().AutoPunch.TrueDash = v end)
AddToggle(TabAutoBlock, "G1337_ShowPunchRange", "Show Punch Range ESP", false, function(v) getgenv().AutoPunch.ShowRange = v end)
AddSlider(TabAutoBlock, "G1337_AutoPunchRange", "Auto Punch Range (studs)", 10, 120, 50, 1, function(v) getgenv().AutoPunch.Range = v end)
AddSection(TabAutoBlock, "HD Tech")
AddToggle(TabAutoBlock, "G1337_HDPull", "Enable HD Pull", false, function(v) G1337.settings.hd = v end)
AddSlider(TabAutoBlock, "G1337_HDSpeed", "HD Speed", 1, 20, 12, 1, function(v) G1337.settings.hdSpeed = v end)
AddSection(TabAutoBlock, "Sphere ESP")
AddSlider(TabAutoBlock, "G1337_SphereRange", "Range (studs)", 5, 50, 11, 1, function(v) G1337.settings.sphereRange = v end)
AddToggle(TabAutoBlock, "G1337_SphereESP", "Sphere ESP", false, function(v)
    G1337.settings.sphereEsp = v
    if not v then for _,s in pairs(G1337.spheres) do pcall(function() s:Destroy() end) end G1337.spheres = {} end
end)
AddSection(TabAutoBlock, "Custom Box ESP")
AddToggle(TabAutoBlock, "G1337_CustomESP", "Custom ESP", false, function(v)
    G1337.settings.customEsp = v
    if not v then for _,b in pairs(G1337.boxes) do pcall(function() b:Destroy() end) end G1337.boxes = {} end
end)
AddSlider(TabAutoBlock, "G1337_BoxLength", "Length (studs)", 1, 50, 15, 1, function(v) G1337.settings.boxLength = v end)
AddSlider(TabAutoBlock, "G1337_BoxWidth", "Width (studs)", 1, 50, 6, 1, function(v) G1337.settings.boxWidth = v end)

--// Veeronica //
AddSection(TabVeeronica, "Veeronica Scripts")
AddToggle(TabVeeronica, "VR_AutoTrick", "Auto Trick", false, function(v)
    VR.enabled = v
    if v then VR.startManager() else VR.stopManager() end
end)
AddButton(TabVeeronica, "Skate Controller", function()
    loadstring(game:HttpGet("https://pastebin.com/raw/MzKS5uvm"))()
end)

--// Elliot //
AddSection(TabElliot, "Elliot - Infinite Rush Hour")
AddSlider(TabElliot, "EL_CooldownTime", "Rush Hour Cooldown (s)", 1, 30, 6, 1, function(v) EL.cooldownTime = v end)
AddToggle(TabElliot, "EL_EnableRush", "Enable Infinite Rush Hour", false, function(v)
    EL.rushEnabled = v
    if v then
        EL.createRushUI()
        if EL.rushFrame then EL.rushFrame.Visible = true end
    else
        if EL.rushFrame then EL.rushFrame.Visible = false end
    end
end)
AddSection(TabElliot, "Elliot Aimbot")
AddSlider(TabElliot, "EL_PredictionStuds", "Prediction Studs", 0, 20, 5, 1, function(v) EL.predictionStuds = v end)
AddDropdown(TabElliot, "EL_AimType", "Aimbot Type", {"HRP Aimbot", "Camera Aimbot"}, "HRP Aimbot", function(v) EL.aimType = v end)
AddToggle(TabElliot, "EL_AimbotEnabled", "Elliot Aimbot V1.1", false, function(v)
    EL.DetectionEnabled = v
    if v then
        EL.Connection = RunService.RenderStepped:Connect(function()
            if not EL.DetectionEnabled or not EL.Humanoid or not EL.HRP then return end
            if not EL.getPlayingAnimationIds()[EL.trackedAnimationId] then
                if EL.originalAutoRotate ~= nil then EL.Humanoid.AutoRotate = EL.originalAutoRotate; EL.originalAutoRotate = nil end
                return
            end
            local target = EL.getValidTarget()
            if target then pcall(EL.AimAt, target) end
        end)
    else
        if EL.Connection then EL.Connection:Disconnect() end
        if EL.originalAutoRotate ~= nil then EL.Humanoid.AutoRotate = EL.originalAutoRotate; EL.originalAutoRotate = nil end
    end
end)

--// Misc //
AddSection(TabMisc, "Quality of Life")
AddToggle(TabMisc, "AutoPickup", "Auto Pickup Items", false)
AddToggle(TabMisc, "AutoEscape", "Auto Escape (Nosferatu hook)", false)
AddToggle(TabMisc, "AntiSlowness", "Anti Slowness", false, SetAntiSlowness)
AddToggle(TabMisc, "AntiHiddenStats", "Anti Hidden Stats", false, SetAntiHiddenStats)
AddToggle(TabMisc, "DeleteRagdolls", "Delete Ragdolls", false, SetDeleteRagdolls)
AddToggle(TabMisc, "DeleteFakeNoli", "Delete Fake Noli", false)
AddToggle(TabMisc, "DisableNoliNPC", "Disable Noli NPC", false, HandleNoliNPC)
AddToggle(TabMisc, "Disable007n7NPC", "Disable 007n7 NPC", false, Handle007n7NPC)
AddToggle(TabMisc, "ShowPing", "Show Ping", false, SetShowPing)
AddSection(TabMisc, "Chat")
AddToggle(TabMisc, "ShowChat", "Force Show Chat", false, SetShowChat)
AddSection(TabMisc, "Rejoin")
AddButton(TabMisc, "Rejoin Server", RejoinServer)
AddSection(TabMisc, "System")
AddButton(TabMisc, "Unload Flex Saken", UnloadScript)
AddSection(TabMisc, "Config")
AddButton(TabMisc, "Copy Config ID", function()
    local Id, Copied = Feature.CreateConfigId()
    if Copied then Notify("Config", "Copied! ID: " .. Id:sub(1, 12) .. "...", 4)
    else Notify("Config", "Could not copy: " .. Id, 4) end
end)
AddInput(TabMisc, "ConfigLoad", "Load Config ID", "", function(Text)
    if Feature.LoadConfig(Text) then Notify("Config", "Config loaded!", 3)
    else Notify("Config", "Invalid config ID", 3) end
end)

--// Visual //
AddSection(TabVisual, "Lighting")
AddToggle(TabVisual, "Fullbright", "Fullbright", false, SetFullbright)
AddToggle(TabVisual, "NoShadows", "No Shadows", false, Feature.SetNoShadows)
AddToggle(TabVisual, "NoFog",     "No Fog",     false, Feature.SetNoFog)
AddSection(TabVisual, "Camera")
AddToggle(TabVisual, "FreeZoom",     "Free Zoom",      false, SetFreeZoom)
AddToggle(TabVisual, "CameraNoclip", "Camera Noclip",  false, SetCameraNoclip)
AddToggle(TabVisual, "CustomFov",    "Custom FOV",     false, SetFov)
AddSlider(TabVisual, "FovValue",     "FOV Value", 50, 120, 70, 1, function() if State.CustomFov then SetFov(true) end end)
AddSection(TabVisual, "Effects")
AddToggle(TabVisual, "HideInjury",      "Hide Injury Effect", false, ApplyInjury)
AddToggle(TabVisual, "DisableBlindness","Disable Blindness",  false, ApplyBlindness)
AddToggle(TabVisual, "SmallSpikes",     "Small Spikes",       false)
AddToggle(TabVisual, "DisableTrails",   "Disable Trails",     false)
AddToggle(TabVisual, "DisableFootprints","Disable Footprints",false)
AddSection(TabVisual, "Emotes")
AddDropdown(TabVisual, "EmoteSelect", "Emote", Feature.EmoteNames, Feature.EmoteNames[1] or "None")
AddButton(TabVisual, "Play Emote", Feature.PlayEmote)
AddButton(TabVisual, "Stop Emote", Feature.StopEmote)

--// Movement //
AddSection(TabMovement, "Speed")
AddToggle(TabMovement, "SpeedBoost", "Speed Boost", false, SetSpeedBoost)
AddSlider(TabMovement, "SpeedValue", "Speed Extra (studs/s)", 0, 60, 10, 1)
AddSection(TabMovement, "Flight")
AddToggle(TabMovement, "Flight", "Flight", false, SetFlight)
AddSlider(TabMovement, "FlightSpeed", "Flight Speed", 1, 100, 20, 1)
AddSection(TabMovement, "Jumping")
AddToggle(TabMovement, "EnableJumping", "Enable Jumping", false, ApplyJumping)
AddSection(TabMovement, "Sprinting")
AddToggle(TabMovement, "InfiniteStamina", "Infinite Stamina", false, SetInfiniteStamina)
AddToggle(TabMovement, "ModifyMaxStamina", "Modify Max Stamina", false, Feature.StaminaToggle("MaxStamina"))
AddSlider(TabMovement, "MaxStaminaValue", "Max Stamina", 50, 500, 100, 1)
AddToggle(TabMovement, "ModifyStaminaGain", "Modify Stamina Gain", false, Feature.StaminaToggle("StaminaGain"))
AddSlider(TabMovement, "StaminaGainValue", "Stamina Gain", 1, 50, 10, 1)
AddToggle(TabMovement, "ModifyStaminaLoss", "Modify Stamina Loss", false, Feature.StaminaToggle("StaminaLoss"))
AddSlider(TabMovement, "StaminaLossValue", "Stamina Loss", 1, 50, 10, 1)
AddToggle(TabMovement, "ModifySprintSpeed", "Modify Sprint Speed", false, Feature.StaminaToggle("SprintSpeed"))
AddSlider(TabMovement, "SprintSpeedValue", "Sprint Speed", 10, 50, 22, 1)

--// Survivor //
AddSection(TabSurvivor, "Generator")
AddToggle(TabSurvivor, "AutoGeneratorMinigame", "Auto Generator", false, function(enabled)
    MinigameSolver.ManualEnabled = enabled
    MinigameSolver.Enabled       = enabled
    MinigameSolver.Generation    += 1
    if enabled then
        pcall(installMinigameHooks)
    end
end)
AddSlider(TabSurvivor, "MinGameStartDelay",   "Start Delay (s)",          0,   5,    1.5,   0.1, function(v) GenConfig.StartDelay   = v         end)
AddSlider(TabSurvivor, "MinGameFlowSpeed",    "Flow Cell Speed (ms)",      0,   250,  50,    1,   function(v) GenConfig.ActionDelay  = v / 1000  end)
AddSlider(TabSurvivor, "MinGameConnectDelay", "Connect Pair Delay (ms)",   100, 3000, 1000,  1,   function(v) GenConfig.ConnectDelay = v / 1000  end)
AddSlider(TabSurvivor, "MinGameGearSpeed",    "Gear Turn Speed (ms)",      0,   150,  30,    1,   function(v) GenConfig.GearDelay    = v / 1000  end)
AddSection(TabSurvivor, "Veeronica")
AddToggle(TabSurvivor, "AutoTrick", "Auto Trick (Veeronica)", false, Feature.SetAutoTrick)
AddSection(TabSurvivor, "Disarm")
AddToggle(TabSurvivor, "AutoDisarm", "Auto Disarm (Azure QTE)", false, SetAutoDisarm)
AddSection(TabSurvivor, "Animation")
AddDropdown(TabSurvivor, "AnimSelect", "Animation", Feature.AnimNames, Feature.AnimNames[1] or "None")
AddButton(TabSurvivor, "Apply Animation", Feature.ApplyAnimation)
AddButton(TabSurvivor, "Stop Animation", Feature.StopAnimation)
AddButton(TabSurvivor, "Refresh Animation List", function()
    local Names = Feature.RefreshAnimations()
    Notify("Animations", "Refreshed " .. #Names .. " entries", 3)
end)
AddSection(TabSurvivor, "Music (Last Survivor)")
AddDropdown(TabSurvivor, "LmsTrack", "Track", Feature.MusicNames, Feature.MusicNames[1] or "None")
AddToggle(TabSurvivor, "LmsMusic", "Replace Last Survivor Music", false, Feature.SetLms)
AddButton(TabSurvivor, "Preview Track", Feature.StartPreview)
AddButton(TabSurvivor, "Stop Preview",  Feature.StopPreview)
AddButton(TabSurvivor, "Preload All",   Feature.PreloadMusic)

AddSection(TabSurvivor, "Chance")
AddToggle(TabSurvivor, "ChanceAim", "Chance Shoot Aim", false)
AddDropdown(TabSurvivor, "ChancePredMode", "Prediction Mode", { "Velocity", "Ping", "Look (Original)" }, "Velocity")
AddSlider(TabSurvivor, "ChancePrediction", "Look Prediction (studs)", 0, 20, 4, 0.5)
AddSlider(TabSurvivor, "ChanceLead", "Lead Time (s)", 0, 1.5, 0.35, 0.05)
AddToggle(TabSurvivor, "ChanceAntiBait", "Anti-Bait Speed Cap", true)
AddToggle(TabSurvivor, "ChanceCoinFlip", "Auto Coin Flip (away from killers)", false, Feature.SetChanceCoinFlip)
SA.AddUI(TabSurvivor, SA.Dusekkar, "Dusekkar", "Dusekkar")

--// Jane Doe //
AddSection(TabSurvivor, "Jane Doe — Crystal Auto-Fire")
AddToggle(TabSurvivor, "JD_Enabled", "Enable Jane Doe Aimbot", false, function(On) Feature.JD_SetEnabled(On) end)
AddToggle(TabSurvivor, "JD_SilentAim", "Aimbot (Silent Aim)", false, function(On) Feature.JD_SetAimbot(On) end)
AddSlider(TabSurvivor, "JD_AimOffset", "Aim Offset (Y)", -5, 5, -0.3, 0.1, function(v) JD.AimOffset = v end)
AddSlider(TabSurvivor, "JD_Prediction", "Prediction", 0, 1, 0.6, 0.01, function(v) JD.Prediction = v end)

AddSection(TabSurvivor, "Jane Doe — Instant Max Charge Crystal")
AddToggle(TabSurvivor, "JD_InstaThrow", "Instant Max Charge Crystal", false, function(On) Feature.JD_SetInstaThrow(On) end)
pcall(function()
    TabSurvivor:Paragraph({ Title = "Info", Desc = "Sets the Crystal min/max charge time to 0.01s each time the ability fires. Turning it off restores the original values." })
end)
AddToggle(TabSurvivor, "JD_InfHold", "Infinite Crystal Hold", false, function(On) Feature.JD_SetInfHold(On) end)
pcall(function()
    TabSurvivor:Paragraph({ Title = "Info", Desc = "Removes the max hold time so the crystal stays held until you release it. Releasing still throws normally." })
end)

AddSection(TabSurvivor, "Jane Doe — Axe Lock-On")
AddToggle(TabSurvivor, "JD_AxeEnabled", "Enable Axe Lock-On", false, function(On) JD.Axe = On end)
AddSlider(TabSurvivor, "JD_AxeLockDur", "Lock Duration (s)", 0.5, 3, 1.7, 0.1, function(v) JD.AxeDuration = v end)

AddSection(TabSurvivor, "Jane Doe — Control")
AddButton(TabSurvivor, "Unload Jane Doe", function() Feature.JD_Unload() end)

--// Killer Tab //

AddSection(TabKiller, "Nova Silent Aim")
SA.AddUI(TabKiller, SA.Nova, "Nova", "Nova")

AddSection(TabKiller, "c00lkidd")
AddToggle(TabKiller, "DashTurn", "Dash Turn Fix (c00lkidd)", false, Feature.SetDashTurn)


AddSection(TabKiller, "Veeronica (Killer Side)")


AddSection(TabKiller, "Azure QTE (Killer)")
AddToggle(TabKiller, "AutoDisarmKiller", "Auto Disarm Azure QTE", false, SetAutoDisarm)

--// Two Time Tab //

-- ===== Auto Backstab (TP) State =====
local ABTP = {
    enabled         = false,
    daggerEnabled   = false,
    predEnabled     = false,
    aimingEnabled   = true,
    directBehind    = false,
    rangeMode       = "Around",
    backstabType    = "lerp",
    lerpSpeed       = 0.37,
    behindDist      = 1.7,
    checkInterval   = 0.12,
    cooldown        = 5,
    defaultProximity= 8,
    defaultDuration = 0.7,
    delayBeforeStab = 0.08,
    predStrength    = 0.6,
    predTime        = 0.12,
    lastTrigger     = 0,
    aimRefCount     = 0,
    killerTrack     = {},
}

-- killerTrack heartbeat (separate from BS tracker)
RunService.Heartbeat:Connect(function(dt)
    local kf = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers")
    if not kf then return end
    local now = os.clock()
    for _, killer in pairs(kf:GetChildren()) do
        local khrp = killer:FindFirstChild("HumanoidRootPart")
        if khrp then
            local state = ABTP.killerTrack[khrp]
            local pos  = khrp.Position
            local look = khrp.CFrame.LookVector
            if state and state.t and state.pos then
                local dtS = now - state.t
                if dtS > 0 then
                    local vel = (pos - state.pos) / dtS
                    local sv  = state.vel and state.vel:Lerp(vel, math.clamp(dtS*10,0,1)) or vel
                    ABTP.killerTrack[khrp] = {pos=pos,look=look,vel=sv,t=now,prevLook=state.look}
                else
                    ABTP.killerTrack[khrp] = {pos=pos,look=look,vel=Vector3.new(0,0,0),t=now,prevLook=state and state.look or look}
                end
            else
                ABTP.killerTrack[khrp] = {pos=pos,look=look,vel=Vector3.new(0,0,0),t=now,prevLook=look}
            end
        end
    end
end)

local function ABTP_setAutoRotate(val)
    local char = LocalPlayer.Character; if not char then return end
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if hum then pcall(function() hum.AutoRotate = val end) end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    ABTP.aimRefCount = 0
    local hum = char:WaitForChild("Humanoid",5)
    if hum then pcall(function() hum.AutoRotate = true end) end
end)

local function ABTP_getDaggerBtn()
    local pg = LocalPlayer:FindFirstChild("PlayerGui"); if not pg then return nil end
    local ui = pg:FindFirstChild("MainUI"); if not ui then return nil end
    local c  = ui:FindFirstChild("AbilityContainer"); if not c then return nil end
    return c:FindFirstChild("Dagger")
end

local function ABTP_getDaggerCooldown(btn)
    if not btn then return nil end
    local cd = btn:FindFirstChild("CooldownTime") or btn:FindFirstChild("Cooldown")
        or btn:FindFirstChildWhichIsA("NumberValue") or btn:FindFirstChildWhichIsA("StringValue")
    if cd then return cd end
    return btn:FindFirstChild("CooldownLabel") or btn:FindFirstChild("Timer") or btn:FindFirstChild("CD")
end

local function ABTP_readCD(cdObj)
    if not cdObj then return nil end
    if cdObj:IsA("NumberValue") then return cdObj.Value end
    if cdObj:IsA("StringValue") then return tonumber(cdObj.Value) end
    if cdObj:IsA("TextLabel") or cdObj:IsA("TextBox") then return tonumber(cdObj.Text) end
    if cdObj.Value ~= nil then
        if type(cdObj.Value)=="number" then return cdObj.Value end
        if type(cdObj.Value)=="string" then return tonumber(cdObj.Value) end
    end
    if cdObj.Text ~= nil then return tonumber(cdObj.Text) end
    return nil
end

local function ABTP_tryActivate(btn)
    if not btn then return false end
    pcall(function() if btn.Activate then btn:Activate() end end)
    local ok, conns = pcall(function()
        if type(getconnections)=="function" and btn.MouseButton1Click then
            return getconnections(btn.MouseButton1Click)
        end
    end)
    if ok and conns then
        for _, conn in ipairs(conns) do
            pcall(function()
                if conn.Function then conn.Function()
                elseif conn.func then conn.func()
                elseif conn.Fire then conn.Fire() end
            end)
        end
    end
    pcall(function() if btn.Activated then btn.Activated:Fire() end end)
    return true
end

local function ABTP_isValidKiller(model)
    if not model then return false end
    local hrp = model:FindFirstChild("HumanoidRootPart")
    local hum = model:FindFirstChildWhichIsA("Humanoid")
    return hrp and hum and hum.Health and hum.Health > 0
end

local function ABTP_activateForKiller(killerModel, duration)
    if not killerModel then return end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum  = char and char:FindFirstChildWhichIsA("Humanoid")
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local khrp = killerModel:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp or not khrp then return end

    local didAim = false
    if ABTP.aimingEnabled then
        ABTP.aimRefCount += 1
        didAim = true
        if ABTP.aimRefCount == 1 then pcall(function() hum.AutoRotate = false end) end
    end

    local function finish()
        if didAim then
            ABTP.aimRefCount = math.max(0, ABTP.aimRefCount - 1)
            if ABTP.aimRefCount == 0 then ABTP_setAutoRotate(true) end
        end
    end

    if not ABTP.aimingEnabled then task.delay(duration or ABTP.defaultDuration, finish) return end

    local function computeCF()
        local kCF = khrp.CFrame
        local behindPos = kCF.Position - (kCF.LookVector.Unit * ABTP.behindDist)
        behindPos = Vector3.new(behindPos.X, kCF.Position.Y, behindPos.Z)
        if not ABTP.predEnabled then
            return CFrame.new(behindPos, behindPos + kCF.LookVector.Unit)
        end
        if ABTP.backstabType ~= "lerp" and ABTP.backstabType ~= "teleport" then
            return CFrame.new(behindPos, behindPos + kCF.LookVector.Unit)
        end
        local tracked = ABTP.killerTrack[khrp]
        local vel = Vector3.new(0,0,0)
        if tracked and tracked.vel then vel = tracked.vel
        else pcall(function() vel = khrp.Velocity or Vector3.new(0,0,0) end) end
        local hVel = Vector3.new(vel.X,0,vel.Z)
        local pm   = hVel * ABTP.predTime * ABTP.predStrength
        local fwd  = kCF.LookVector; local right = kCF.RightVector
        local fwdC = fwd * (pm:Dot(fwd)); local latC = right * (pm:Dot(right))
        local turnC = Vector3.new(0,0,0)
        if tracked and tracked.prevLook then
            local dLook = fwd - tracked.prevLook
            turnC = right * (dLook:Dot(right) * 3.0 * ABTP.predStrength)
        end
        local offset = fwdC + latC + turnC
        local finalPos = behindPos + Vector3.new(offset.X, 0, offset.Z)
        return CFrame.new(finalPos, finalPos + kCF.LookVector.Unit)
    end

    if hrp.Anchored then hrp.Anchored = false end

    if ABTP.backstabType == "lerp" then
        local goal = computeCF()
        local ok, tw = pcall(function()
            return TweenService:Create(hrp, TweenInfo.new(0.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {CFrame=goal})
        end)
        if ok and tw then pcall(function() tw:Play() end) else pcall(function() hrp.CFrame = goal end) end
        local t0 = os.clock(); local conn
        conn = RunService.Heartbeat:Connect(function()
            if not conn then return end
            if os.clock()-t0 >= (duration or ABTP.defaultDuration) then conn:Disconnect(); conn=nil; finish(); return end
            if not khrp or not hrp then return end
            hrp.CFrame = hrp.CFrame:Lerp(computeCF(), ABTP.lerpSpeed)
        end)

    elseif ABTP.backstabType == "teleport" then
        pcall(function() hrp.CFrame = computeCF() end)
        local t0 = os.clock(); local conn
        conn = RunService.Heartbeat:Connect(function()
            if not conn then return end
            if os.clock()-t0 >= (duration or ABTP.defaultDuration) then conn:Disconnect(); conn=nil; finish(); return end
            if not khrp or not hrp then return end
            pcall(function() hrp.CFrame = computeCF() end)
        end)

    elseif ABTP.backstabType == "just auto stab (if its on)" then
        local t0 = os.clock(); local conn
        conn = RunService.Heartbeat:Connect(function()
            if not conn then return end
            if os.clock()-t0 >= (duration or ABTP.defaultDuration) then conn:Disconnect(); conn=nil; finish(); return end
            if not khrp or not hrp then return end
            local lv = khrp.CFrame.LookVector; local cp = hrp.Position
            pcall(function() hrp.CFrame = CFrame.new(cp, cp+lv) end)
        end)
    end
end

-- Main watcher loop
task.spawn(function()
    while true do
        task.wait(ABTP.checkInterval)
        if not ABTP.enabled then continue end
        local range = ABTP.defaultProximity
        local kf = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers")
        if not kf then continue end
        local char = LocalPlayer.Character; if not char then continue end
        local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then continue end
        for _, killer in pairs(kf:GetChildren()) do
            if ABTP_isValidKiller(killer) then
                local khrp = killer:FindFirstChild("HumanoidRootPart")
                if khrp then
                    local dist = (khrp.Position - hrp.Position).Magnitude
                    local shouldTrigger = false
                    if ABTP.rangeMode == "Around" then
                        shouldTrigger = dist <= range
                    else
                        local rel = hrp.Position - khrp.Position
                        local fwdDot = rel:Dot(khrp.CFrame.LookVector)
                        local behindDist = -fwdDot
                        local angleDot = rel.Magnitude > 0 and (rel.Unit):Dot(khrp.CFrame.LookVector) or 0
                        local passedDot = ABTP.directBehind and angleDot <= -0.85 or fwdDot < 0.3
                        shouldTrigger = passedDot and behindDist <= range and dist <= range
                    end
                    if shouldTrigger and os.clock()-ABTP.lastTrigger >= ABTP.cooldown then
                        local btn = ABTP_getDaggerBtn()
                        local cdObj = ABTP_getDaggerCooldown(btn)
                        local cdNum = ABTP_readCD(cdObj)
                        if not cdNum or cdNum <= 0.1 then
                            ABTP.lastTrigger = os.clock()
                            task.spawn(function()
                                ABTP_activateForKiller(killer, ABTP.defaultDuration)
                                if ABTP.daggerEnabled then
                                    task.wait(ABTP.delayBeforeStab)
                                    ABTP_tryActivate(btn)
                                end
                            end)
                        end
                        break
                    end
                end
            end
        end
    end
end)
-- ===== End Auto Backstab (TP) =====

AddSection(TabTwoTime, "Auto Backstab (TP)")
AddToggle(TabTwoTime, "ABTP_Enabled",      "Enable Auto Backstab (TP)",     false, function(v) ABTP.enabled       = v end)
AddToggle(TabTwoTime, "ABTP_AutoStab",     "Auto Stab",                     false, function(v) ABTP.daggerEnabled  = v end)
AddToggle(TabTwoTime, "ABTP_Aiming",       "Aiming",                        true,  function(v) ABTP.aimingEnabled  = v end)
AddToggle(TabTwoTime, "ABTP_DirectBehind", "Stricter Behind Check",         false, function(v) ABTP.directBehind   = v end)
AddToggle(TabTwoTime, "ABTP_Prediction",   "Prediction",                    false, function(v) ABTP.predEnabled    = v end)
AddDropdown(TabTwoTime, "ABTP_RangeMode",  "Range Mode", {"Around","Behind"}, "Around", function(v) ABTP.rangeMode = v end)
AddDropdown(TabTwoTime, "ABTP_Type",       "Backstab Type", {"lerp","teleport","just auto stab (if its on)"}, "lerp", function(v) ABTP.backstabType = v end)
AddSlider(TabTwoTime, "ABTP_Range",        "Range (studs)",     1,  30,  8,    0.5,  function(v) ABTP.defaultProximity = v end)
AddSlider(TabTwoTime, "ABTP_BehindDist",   "Behind Distance",   0.5, 6,  1.7,  0.1,  function(v) ABTP.behindDist       = v end)
AddSlider(TabTwoTime, "ABTP_LerpSpeed",    "Lerp Speed",        0.01,1,  0.37, 0.01, function(v) ABTP.lerpSpeed        = v end)
AddSlider(TabTwoTime, "ABTP_Delay",        "Delay Before Stab", 0,   0.5,0.08, 0.01, function(v) ABTP.delayBeforeStab  = v end)
AddSlider(TabTwoTime, "ABTP_Cooldown",     "Cooldown (s)",      0.5, 10, 5,    0.5,  function(v) ABTP.cooldown         = v end)
AddSlider(TabTwoTime, "ABTP_PredStr",      "Pred Strength",     0,   1,  0.6,  0.05, function(v) ABTP.predStrength     = v end)
AddSlider(TabTwoTime, "ABTP_PredTime",     "Pred Time (s)",     0.01,0.5,0.12, 0.01, function(v) ABTP.predTime         = v end)

AddSection(TabTwoTime, "Auto Backstab")
AddToggle(TabTwoTime, "BS_Enabled",        "Enable Auto Backstab",          false, function(v) BS.isEnabled          = v end)
AddToggle(TabTwoTime, "BS_Dashstab",       "Enable Dashstab",               false, function(v) BS.isDashstabEnabled  = v end)
AddToggle(TabTwoTime, "BS_AutoStuds",      "Auto Studs (Distance Adapts)",  false, function(v) BS.isAutoStudsEnabled = v end)
AddToggle(TabTwoTime, "BS_DetectPing",     "Ping Compensation",             false, function(v) BS.isDetectPingEnabled = v end)
AddToggle(TabTwoTime, "BS_MoreDirect",     "More Direct (Position Spoof)",  false, function(v) BS.moredirectenabled  = v end)
AddToggle(TabTwoTime, "BS_DistCheck",      "Distance Check",                false, function(v) BS.distcheck          = v end)
AddSection(TabTwoTime, "Timing")
AddSlider(TabTwoTime, "BS_StartDelay",     "Start Delay (s)",    0,   1,   0.05, 0.01, function(v) BS.startdelay       = v end)
AddSlider(TabTwoTime, "BS_Duration",       "Duration (s)",       0,   1,   0.2,  0.01, function(v) BS.duration         = v end)
AddSlider(TabTwoTime, "BS_DsStartDelay",   "Dashstab Delay (s)", 0,   0.5, 0.1,  0.01, function(v) BS.dsStartDelay     = v end)
AddSection(TabTwoTime, "Position")
AddSlider(TabTwoTime, "BS_BehindStuds",    "Behind Studs",       1,   10,  4,    0.1,  function(v) BS.behindstuds      = v end)
AddSlider(TabTwoTime, "BS_DistCheckStuds", "Dist Check Studs",   1,   20,  7,    0.5,  function(v) BS.distcheckstud    = v end)
AddSection(TabTwoTime, "Auto Studs")
AddSlider(TabTwoTime, "BS_AutoStandStuds", "Stand Studs",        1,   12,  5.5,  0.1,  function(v) BS.autoStandStuds   = v end)
AddSlider(TabTwoTime, "BS_AutoRunStuds",   "Run Studs",          1,   8,   3.4,  0.1,  function(v) BS.autoRunStuds     = v end)

--// Extra Tab //

AddSection(TabExtra, "Sk8 / Spray")
AddToggle(TabExtra, "Sk8Control",  "Sk8 Control Override",   false, function(v) State.Sk8Control = v end)
AddToggle(TabExtra, "FastSpray",   "Fast Spray (Back & Forth)", false, function(v) State.FastSpray = v end)
AddSlider(TabExtra, "SpraySpeed",  "Spray Speed Multiplier", 0.1, 3, 0.5, 0.05, function(v) State.SpraySpeed = v end)

AddSection(TabExtra, "Break Free / Pull Rope")
AddToggle(TabExtra, "AutoBreakFree", "Auto Break Free (Nosferatu)", false, function(v) State.AutoBreakFree = v end)
AddToggle(TabExtra, "AutoPullRope",  "Auto Pull Rope (Nosferatu)", false, function(v) State.AutoPullRope = v end)

AddSection(TabExtra, "In-Game NPC")
AddToggle(TabExtra, "KillerWalls",   "Noclip Killer Doors",   false, SetKillerWalls)
AddToggle(TabExtra, "DisableTrailsExt",  "Disable Trails",    false, function(v) State.DisableTrails = v end)
AddToggle(TabExtra, "DisableFootprintsExt", "Disable JD Footprints", false, function(v) State.DisableFootprints = v end)
AddToggle(TabExtra, "SmallSpikesExt","Small Spikes",          false, function(v) State.SmallSpikes = v end)

AddSection(TabExtra, "Items")
AddButton(TabExtra, "TP to BloxyCola",  function() TPToItem("BloxyCola") end)
AddButton(TabExtra, "TP to Medkit",     function() TPToItem("Medkit") end)

AddSection(TabExtra, "Generator Auto-Solver (Extra)")
AddToggle(TabExtra, "AutoGen2", "Auto Generator (Mirror)", false, function(enabled)
    MinigameSolver.AutoEnabled = enabled
    MinigameSolver.Generation += 1
    if enabled then pcall(installMinigameHooks) end
end)

--// Shedletsky Tab //

local TabShedletsky = Window:Tab({ Title = "Shedletsky", Icon = "sword" })

-- state
local _Shed = {
    enabled  = false,
    dist     = 10,
    cd       = 1.1,          -- per-killer cooldown
    last     = {},            -- [model] = os.clock()
    slashConn = nil,
    rotConn   = nil,
    charAdd   = nil,
    charRem   = nil,
    running   = false,        -- guard: prevents re-entrant start
}

local function _ShedSlashReady()
    -- returns true when the Slash ability button cooldown label is empty (ability ready)
    local ok, result = pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if not pg then return true end
        local ui = pg:FindFirstChild("MainUI")
        if not ui then return true end
        local ac = ui:FindFirstChild("AbilityContainer")
        if not ac then return true end
        local btn = ac:FindFirstChild("Slash")
        if not btn then return true end
        local lbl = btn:FindFirstChild("CooldownTime")
        if not lbl then return true end
        return lbl.Text == ""
    end)
    if not ok then return true end
    return result
end

local function _ShedFaceKiller(hrp, khrp)
    pcall(function()
        local dir  = khrp.Position - hrp.Position
        local flat = Vector3.new(dir.X, 0, dir.Z)
        if flat.Magnitude < 0.01 then return end
        hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + flat.Unit)
    end)
end

local function _ShedStopRot()
    if _Shed.rotConn then
        _Shed.rotConn:Disconnect()
        _Shed.rotConn = nil
    end
end

local function _ShedSmoothRot()
    _ShedStopRot()
    local token = {}
    _Shed.rotConn = RunService.Heartbeat:Connect(function()
        if not _Shed.enabled or _Shed.rotConn == nil then
            _ShedStopRot(); return
        end
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then _ShedStopRot(); return end

        local kf  = workspace:FindFirstChild("Players")
        kf = kf and kf:FindFirstChild("Killers")
        if not kf then _ShedStopRot(); return end

        local best, bestD = nil, math.huge
        for _, m in pairs(kf:GetChildren()) do
            if m:IsA("Model") then
                local khrp = m:FindFirstChild("HumanoidRootPart")
                if khrp then
                    local d = (khrp.Position - hrp.Position).Magnitude
                    if d < bestD and d < 50 then best = khrp; bestD = d end
                end
            end
        end
        if not best then return end

        pcall(function()
            local dir  = best.Position - hrp.Position
            local flat = Vector3.new(dir.X, 0, dir.Z)
            if flat.Magnitude < 0.01 then return end
            local goal = CFrame.new(hrp.Position, hrp.Position + flat.Unit)
            hrp.CFrame = hrp.CFrame:Lerp(goal, 0.3)
        end)
    end)
    -- auto-stop after 1.2 s
    task.delay(1.2, function()
        _ShedStopRot()
    end)
end

local function _ShedFireForKiller(killerModel)
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local khrp = killerModel and killerModel:FindFirstChild("HumanoidRootPart")
    if hrp and khrp then
        _ShedFaceKiller(hrp, khrp)
    end
    if Remote then
        pcall(function()
            Remote:FireServer("UseActorAbility", { buffer.fromstring("\3\5\0\0\0Slash") })
        end)
    end
    _ShedSmoothRot()
end

local function _ShedStopLoop()
    if _Shed.slashConn then
        _Shed.slashConn:Disconnect()
        _Shed.slashConn = nil
    end
    _Shed.running = false
    for k in pairs(_Shed.last) do _Shed.last[k] = nil end
end

local function _ShedStartLoop()
    if _Shed.running then return end
    _Shed.running = true
    _Shed.slashConn = RunService.Heartbeat:Connect(function()
        if not _Shed.enabled then
            -- clean stop — schedule disconnect outside this callback to avoid self-GC
            task.defer(function()
                if _Shed.slashConn then
                    _Shed.slashConn:Disconnect()
                    _Shed.slashConn = nil
                end
                _Shed.running = false
            end)
            return
        end

        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local kf = workspace:FindFirstChild("Players")
        kf = kf and kf:FindFirstChild("Killers")
        if not kf then return end

        if not _ShedSlashReady() then return end

        local now = os.clock()
        for _, v in pairs(kf:GetChildren()) do
            if v:IsA("Model") then
                local khrp = v:FindFirstChild("HumanoidRootPart")
                if khrp then
                    local dist = (hrp.Position - khrp.Position).Magnitude
                    if dist <= _Shed.dist then
                        local last = _Shed.last[v] or 0
                        if now - last >= _Shed.cd then
                            _Shed.last[v] = now
                            task.spawn(_ShedFireForKiller, v)
                        end
                    end
                end
            end
        end
    end)
end

local function Shedletsky_AutoSlash_FUNC()
    if _Shed.charAdd then _Shed.charAdd:Disconnect(); _Shed.charAdd = nil end
    if _Shed.charRem then _Shed.charRem:Disconnect(); _Shed.charRem = nil end
    _ShedStopLoop()
    _ShedStopRot()

    if not _Shed.enabled then return end

    -- start immediately if already Shedletsky
    local char = LocalPlayer.Character
    if char and char.Name == "Shedletsky" then
        _ShedStartLoop()
    end

    _Shed.charAdd = LocalPlayer.CharacterAdded:Connect(function(newChar)
        task.wait(1.5)
        if newChar.Name ~= "Shedletsky" then return end
        _ShedStopLoop()
        _ShedStartLoop()
    end)

    _Shed.charRem = LocalPlayer.CharacterRemoving:Connect(function()
        _ShedStopLoop()
    end)
end

AddSection(TabShedletsky, "Auto Slash")
AddToggle(TabShedletsky, "ShedAutoSlash", "Auto Slash", false, function(v)
    _Shed.enabled = v
    Shedletsky_AutoSlash_FUNC()
end)
AddSlider(TabShedletsky, "ShedAutoSlashDist", "Slash Distance (studs)", 1, 20, 10, 1, function(v)
    _Shed.dist = v
end)

--// Freeze Hitbox Tab //

local TabFreezeHitbox = Window:Tab({ Title = "Freeze Hitbox", Icon = "crosshair" })

do
    local FH = {
        Running   = false,
        Thread    = nil,
        Interval  = 0.1,
        Size      = 1,
        Offset    = Vector3.new(0, 0, 0),
        Token     = 0,
    }

    local function RunFreezeHitbox()
        FH.Token += 1
        local Token = FH.Token
        task.spawn(function()
            while FH.Running and Token == FH.Token do
                pcall(function()
                    local char = LocalPlayer.Character
                    if not char then return end
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end

                    local p = Instance.new("Part")
                    p.Name        = "FreezeHitbox"
                    p.Size        = Vector3.new(FH.Size, FH.Size, FH.Size)
                    p.Transparency= 1
                    p.Anchored    = true
                    p.CanCollide  = false
                    p.CFrame      = hrp.CFrame + FH.Offset
                    p.Parent      = char

                    char.PrimaryPart = p

                    task.wait(FH.Interval)

                    if p and p.Parent then p:Destroy() end
                    if char and char.PrimaryPart == p then
                        char.PrimaryPart = hrp
                    end
                end)
                task.wait(FH.Interval + 0.05)
            end
        end)
    end

    local function StopFreezeHitbox()
        FH.Running = false
        FH.Token  += 1
        -- Restore PrimaryPart if still set to our part
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp and char.PrimaryPart ~= hrp then
                char.PrimaryPart = hrp
            end
            for _, v in ipairs(char:GetChildren()) do
                if v.Name == "FreezeHitbox" then v:Destroy() end
            end
        end)
    end

    AddSection(TabFreezeHitbox, "Freeze Hitbox")
    AddToggle(TabFreezeHitbox, "FreezeHitboxEnabled", "Enable Freeze Hitbox", false, function(on)
        FH.Running = on
        if on then RunFreezeHitbox() else StopFreezeHitbox() end
    end)

    AddSection(TabFreezeHitbox, "Settings")
    AddSlider(TabFreezeHitbox, "FH_Size",     "Hitbox Size",          0.1, 10,  1,   0.1,  function(v) FH.Size     = v end)
    AddSlider(TabFreezeHitbox, "FH_Interval", "Interval (s)",         0.05, 1,  0.1, 0.01, function(v) FH.Interval = v end)
    AddSlider(TabFreezeHitbox, "FH_OffsetX",  "Offset X (studs)",    -10, 10,  0,   0.5,  function(v) FH.Offset = Vector3.new(v, FH.Offset.Y, FH.Offset.Z) end)
    AddSlider(TabFreezeHitbox, "FH_OffsetY",  "Offset Y (studs)",    -10, 10,  0,   0.5,  function(v) FH.Offset = Vector3.new(FH.Offset.X, v, FH.Offset.Z) end)
    AddSlider(TabFreezeHitbox, "FH_OffsetZ",  "Offset Z (studs)",    -10, 10,  0,   0.5,  function(v) FH.Offset = Vector3.new(FH.Offset.X, FH.Offset.Y, v) end)

    AddSection(TabFreezeHitbox, "Manual")
    AddButton(TabFreezeHitbox, "Fire Once", function()
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:WaitForChild("HumanoidRootPart", 3)
            if not hrp then return end
            local p = Instance.new("Part")
            p.Name        = "test"
            p.Size        = Vector3.new(1, 1, 1)
            p.Transparency= 1
            p.Anchored    = true
            p.CFrame      = hrp.CFrame
            p.Parent      = char
            char.PrimaryPart = p
            task.wait(0.1)
            p:Destroy()
        end)
    end)

    -- Clean up on character removal
    LocalPlayer.CharacterRemoving:Connect(StopFreezeHitbox)
    table.insert(CharacterCallbacks, function()
        if State.FreezeHitboxEnabled then RunFreezeHitbox() end
    end)
end

--// Info //
local TabInfo = Window:Tab({ Title = "Info", Icon = "info" })

AddSection(TabInfo, "Credits")
pcall(function()
    TabInfo:Paragraph({ Title = "Owner", Desc = "Ethan" })
end)
pcall(function()
    TabInfo:Paragraph({ Title = "Helpers", Desc = "luna" })
end)

AddSection(TabInfo, "Community")
AddButton(TabInfo, "Copy Discord Link", function()
    local Copied = CopyText(DiscordLink)
    if Copied then
        Notify("Discord", "Link copied to clipboard!", 3)
    else
        Notify("Discord", "Could not copy — executor may not support clipboard", 3)
    end
end)

--// BOOTSTRAP CHARACTER //

if LocalPlayer.Character then task.spawn(OnCharacter, LocalPlayer.Character) end

Notify("Flex Saken", "Loaded v" .. Version .. " — Crimson Edition ✦", 5)
