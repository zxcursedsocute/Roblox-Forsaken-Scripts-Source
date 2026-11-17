-- This file was generated at discord.gg/syncrypt

local env = getfenv and getfenv() or _ENV
local unpack_ = unpack or table.unpack
local v5

if developermode == "luau_is_cool" then
	print("Welcome Developer!")
	v5 = true
else
	v5 = false
end

local t2 = {
	value1 = 1,
	value2 = nil,
	value3 = nil,
	value4 = false,
	value5 = 2.5,
	value6 = game:GetService("Players")
}

t2.value7 = t2.value6.LocalPlayer
t2.value8 = t2.value7.Character or t2.value7.CharacterAdded:Wait()

local value8 = t2.value8

t2.value9 = value8.WaitForChild(value8, "HumanoidRootPart")
t2.value10 = 0.1
t2.value11 = 2000
t2.value12 = 0
t2.value13 = 0
t2.value14 = nil
t2.value15 = nil
t2.value16 = 0.5
t2.value17 = nil
t2.value18 = "Character"
t2.value19 = 2
t2.value20 = 3
t2.value21 = "Teleport"
t2.value22 = 100
t2.value23 = false
t2.value24 = require(cloneref(game:GetService("ReplicatedStorage")).Systems.Character.Game.Sprinting)
task.spawn(function()
	while true do
		repeat
			wait(t2.value5)
		until t2.value4

		local v7, v8, v9 = pairs(game.Workspace.Map.Ingame.Map:GetChildren())

		while true do
			local v10

			v9, v10 = v7(v8, v9)

			if not v9 then
				break
			end

			local v11 = v10.Name == "Generator"

			if v11 then
				v11 = v10:FindFirstChild("Remotes")

				if v11 then
					v11 = v10.Remotes:FindFirstChild("RE")
				end
			end

			if v11 then
				v10.Remotes.RE:FireServer()
			end
		end
	end
end)
task.spawn(function()
	while task.wait(1e-18) do
		local value23 = t2.value23

		if value23 then
			value23 = t2.value24.Stamina <= 1
		end

		if value23 then
			t2.value24.MinStamina = -1
			t2.value24.Stamina = 1
		end
	end
end)
t2.value25 = 0.05

local RunService = game:GetService("RunService")

t2.value26 = game:GetService("Players").LocalPlayer
t2.value27 = false
t2.value28 = false
t2.value29 = nil
t2.value29 = {}

function t2.value30(p1)
	local v14 = t2.value29[p1]

	if not v14 then
		local _ = env.pYTF6ju9mXeJp

		return
	end

	if v14.HealthConnection then
		v14.HealthConnection:Disconnect()
	end

	if v14.AncestryConnection then
		v14.AncestryConnection:Disconnect()
	end

	if v14.Highlight then
		v14.Highlight:Destroy()
	end

	if not v14.Billboard then
		t2.value29[p1] = nil

		return
	end

	v14.Billboard:Destroy()
	t2.value29[p1] = nil
end
function t2.value31(p2, p3)
	if p2 == t2.value26.Character then
		return
	end

	if t2.value29[p2] then
		return
	end

	local HumanoidRootPart = p2:FindFirstChild("HumanoidRootPart")
	local Humanoid = p2:FindFirstChildOfClass("Humanoid")

	if not (HumanoidRootPart and Humanoid) then
		local _ = env.BFyDVRaQLg0yS

		return
	end

	if p3 then
		p3 = Color3.fromRGB(255, 0, 0)
	end

	local color3 = p3 or Color3.fromRGB(0, 255, 0)
	local Highlight = Instance.new("Highlight")

	Highlight.Adornee = p2
	Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	Highlight.FillTransparency = 0.5
	Highlight.OutlineTransparency = 0
	Highlight.FillColor = color3
	Highlight.OutlineColor = color3
	Highlight.Parent = p2

	local BillboardGui = Instance.new("BillboardGui")

	BillboardGui.Name = "ESP"
	BillboardGui.Adornee = HumanoidRootPart
	BillboardGui.AlwaysOnTop = true
	BillboardGui.Size = UDim2.new(0, 150, 0, 22)
	BillboardGui.StudsOffset = Vector3.new(0, 3, 0)
	BillboardGui.Parent = p2

	local TextLabel = Instance.new("TextLabel")

	TextLabel.Size = UDim2.fromScale(1, 1)
	TextLabel.BackgroundTransparency = 1
	TextLabel.TextScaled = false
	TextLabel.TextSize = 14
	TextLabel.Font = Enum.Font.Bodoni
	TextLabel.TextStrokeTransparency = 0
	TextLabel.TextStrokeColor3 = color3
	TextLabel.TextColor3 = color3
	TextLabel.Parent = BillboardGui

	local function v23(p4)
		if p4 % 1 == 0 then
			return tostring(unpack_({ math.floor(p4) }))
		else
			return string.format("%.1f", p4)
		end
	end
	local function v24()
		if not Humanoid.Parent then
			return
		end

		TextLabel.Text = string.format("%s (%s/%s)", p2.Name, v23(Humanoid.Health), v23(Humanoid.MaxHealth))
	end

	v24()

	local connection = Humanoid.HealthChanged:Connect(v24)
	local connection2 = nil

	connection2 = p2.AncestryChanged:Connect(function(_, parent)
		if parent then
			return
		end

		connection:Disconnect()
		connection2:Disconnect()
		t2.value29[p2] = nil
	end)

	local t3 = {
		Highlight = Highlight,
		Billboard = BillboardGui,
		HealthConnection = connection,
		AncestryConnection = connection2
	}

	t2.value29[p2] = t3
end

RunService.Heartbeat:Connect(function()
	local Players = workspace:FindFirstChild("Players")

	if not Players then
		return
	end

	local Killers = Players:FindFirstChild("Killers")

	if Killers then
		local v30, v31, v32 = ipairs(Killers:GetChildren())

		while true do
			local v33

			v32, v33 = v30(v31, v32)

			if not v32 then
				break
			end

			if t2.value27 then
				t2.value31(v33, true)
			else
				t2.value30(v33)
			end
		end
	end

	local Survivors = Players:FindFirstChild("Survivors")

	if not Survivors then
		return
	end

	local GetChildren = Survivors.GetChildren
	local v36, v37, v38 = ipairs(GetChildren(Survivors))

	while true do
		local v39

		v38, v39 = v36(v37, v38)

		if not v38 then
			break
		end

		if t2.value28 then
			t2.value31(v39, false)
		else
			t2.value30(v39)
		end
	end
end)

local function v40(p5)
	t2.value27 = p5

	if p5 then
		return
	end

	local Players = workspace:FindFirstChild("Players")

	if Players then
		Players = workspace.Players:FindFirstChild("Killers")
	end

	if not Players then
		return
	end

	local GetChildren = Players.GetChildren
	local v43, v44, v45 = ipairs(GetChildren(Players))

	while true do
		local v46

		v45, v46 = v43(v44, v45)

		if not v45 then
			break
		end

		t2.value30(v46)
	end
end
local function v47(p6)
	t2.value28 = p6

	if p6 then
		return
	end

	local Players = workspace:FindFirstChild("Players")

	if Players then
		Players = workspace.Players:FindFirstChild("Survivors")
	end

	if not Players then
		return
	end

	local v49, v50, v51 = ipairs(Players:GetChildren())

	while true do
		local v52

		v51, v52 = v49(v50, v51)

		if not v51 then
			break
		end

		t2.value30(v52)
	end
end

local loadstring_ = loadstring
local game_ = game

t2.value32 = loadstring_(game_.HttpGet(game_, "https://raw.githubusercontent.com/randomforsakenscripter/UILibrary/refs/heads/main/Gemini/V1.0"))()
t2.value33 = nil

function t2.value33()
	local Character = t2.value7.Character

	if Character then
		local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")

		if HumanoidRootPart then
			local Position = HumanoidRootPart.Position
			local huge = math.huge
			local players = t2.value6:GetPlayers()
			local v60 = nil

			for i = 1, #players do
				local v62 = players[i]

				if v62 ~= t2.value7 then
					local Character2 = v62.Character

					if Character2 then
						local Humanoid = Character2:FindFirstChildOfClass("Humanoid")

						if Humanoid then
							local Health = Humanoid.Health
							local v66 = Health > 0

							if v66 then
								if Health == 999 then
									v66 = false
								else
									v66 = Humanoid.MaxHealth > 999.1
								end
							end

							if v66 then
								local HumanoidRootPart2 = Character2:FindFirstChild("HumanoidRootPart")

								if HumanoidRootPart2 then
									local v68 = HumanoidRootPart2.Position - Position
									local v69 = v68.X * v68.X + v68.Y * v68.Y + v68.Z * v68.Z

									if v69 < huge then
										v60 = HumanoidRootPart2
										huge = v69
									end
								end
							end
						end
					end
				end
			end

			local _ = env.RrCZsasrY6ns8

			return v60
		else
			return
		end
	end
end
function t2.value34(p7)
	task.wait(t2.value25)
	t2.value14 = false
	t2.value3 = t2.value33()

	if not t2.value3 then
		local _ = env.DZtnBIWikRxi5

		return
	end

	t2.value8 = t2.value7.Character or t2.value7.CharacterAdded:Wait()
	t2.value9 = t2.value7.Character:WaitForChild("HumanoidRootPart")
	t2.value17 = CFrame.new((t2.value9.CFrame * CFrame.new(0, 0, 0)).Position) * (t2.value9.CFrame - t2.value9.CFrame.Position)

	if bruh then
		t2.value9.CFrame = t2.value9.CFrame + Vector3.new(t2.value13, t2.value11, t2.value12)
	end

	wait(t2.value10)
	t2.value14 = tick() + t2.value16

	while tick() < t2.value14 do
		t2.value9.CFrame = CFrame.new((t2.value3.CFrame * CFrame.new(0, 0, p7)).Position) * (t2.value3.CFrame - t2.value3.CFrame.Position)
		task.wait(1e-31)
	end

	if not tpbackenabled then
		return
	end

	t2.value9.CFrame = t2.value17
end
function t2.value35(p8)
	task.wait(t2.value25)
	t2.value3 = t2.value33()

	if t2.value3 then
		t2.value8 = t2.value7.Character or t2.value7.CharacterAdded:Wait()
		t2.value9 = t2.value7.Character:WaitForChild("HumanoidRootPart")

		local now = tick()

		while true do
			local v73 = tick() - now
			local value16 = t2.value16
			local _ = value16 <= v73 and 8019578 or false

			if value16 <= v73 or not (t2.value3 and t2.value3.Parent) then
				break
			end

			local v76 = task.wait()
			local v77 = t2.value3.Position - t2.value3.CFrame.LookVector * p8
			local Magnitude = (v77 - t2.value9.Position).Magnitude

			if Magnitude > 0 then
				local v79 = t2.value22 * v76 / Magnitude
				local v80 = math.min(v79, 1)
				local v81 = t2.value9.Position:Lerp(v77, v80)

				t2.value9.CFrame = CFrame.new(v81, v81 + t2.value3.CFrame.LookVector)
			end
		end
	end
end

t2.value36 = nil

function t2.value36(p9)
	t2.value3 = t2.value33()

	if t2.value3 then
		t2.value8 = t2.value7.Character or t2.value7.CharacterAdded:Wait()
		t2.value9 = t2.value8:WaitForChild("HumanoidRootPart")

		local value18 = t2.value18
		local _ = value18 == "Character" and 2093346 or false
		local value82

		if value18 == "Character" then
			value82 = t2.value8
		else
			if t2.value18 ~= "Root" then
				print("nope")

				return
			end

			value82 = t2.value9
		end

		local Part = Instance.new("Part")

		Part.Name = "broom"
		Part.Size = Vector3.new(1, 1, 1)
		Part.Transparency = t2.value1
		Part.Anchored = true
		Part.CanCollide = false
		Part.Parent = value82
		task.wait(t2.value25)

		local PrimaryPart = t2.value8.PrimaryPart

		t2.value8.PrimaryPart = Part

		local now = tick()

		while tick() - now < t2.value16 do
			t2.value3 = t2.value33()
			t2.value9.AssemblyLinearVelocity = Vector3.zero
			t2.value9.AssemblyAngularVelocity = Vector3.zero
			t2.value9.Velocity = Vector3.zero
			t2.value9.RotVelocity = Vector3.zero

			local CFrame_ = Part.CFrame
			local cFrame = CFrame.new((t2.value3.CFrame * CFrame.new(0, 0, p9)).Position)
			local CFrame_2 = t2.value3.CFrame
			local Position = t2.value3.CFrame.Position
			local math_ = math

			Part.CFrame = CFrame_:Lerp(cFrame * (CFrame_2 - Position), math_.clamp(t2.value22 * 0.016666666666667, 0, 1))

			if t2.value15 then
				value82:PivotTo(Part.CFrame)
			end

			task.wait()
		end

		t2.value8.PrimaryPart = PrimaryPart
		Part:Destroy()
	else
		print("no killer noob")
	end
end
function t2.value37(p10)
	if enabled then
		if t2.value21 == "Teleport" then
			t2.value34(p10)

			return
		else
			local value21 = t2.value21
			local _ = value21 == "Lerp" and 177893 or false

			if value21 == "Lerp" then
				t2.value35(p10)

				return
			elseif t2.value21 == "PrimaryPart" then
				t2.value36(p10)

				return
			else
				print("wtf what mode are u using brah")

				return
			end
		end
	else
		print("how wtf")
	end
end

t2.value38 = {}
t2.value38.stab = {
	["106086955212611"] = true,
	["100725497418533"] = true
}
t2.value38.crouchstab = {
	["89448354637442"] = true,
	["107640065977686"] = true
}

local function v95(character)
	local function v96(p11)
		local Animation = p11.Animation

		if not Animation then
			return
		end

		local match = Animation.AnimationId:match("%d+")
		local enabled_ = t2.value38.stab[match]

		if enabled_ then
			enabled_ = enabled
		end

		if enabled_ then
			t2.value2 = t2.value19 or 3
			t2.value37(t2.value2)

			return
		end

		local enabled_2 = t2.value38.crouchstab[match]

		if enabled_2 then
			enabled_2 = enabled
		end

		if not enabled_2 then
			return
		end

		t2.value2 = t2.value20 or 3
		t2.value37(t2.value2)
	end

	character:WaitForChild("Humanoid"):WaitForChild("Animator").AnimationPlayed:Connect(v96)
end

if t2.value7.Character then
	v95(t2.value7.Character)
end

t2.value7.CharacterAdded:Connect(v95)

if not t2.value32 then
	print("GUI Library is not exist")

	return
end

local t1 = {
	value1 = t2.value32,
	value2 = UDim2.new(0, 50, 0, 50),
	value3 = UDim2.new(0.85, 0, 0.8, 0)
}

t1.value1:SetToggleButton({
	Text = "AB",
	Size = t1.value2,
	Position = t1.value3
})
t2.value32:SetTitle("Auto Backstab V1.4 By RFS")
t2.value32:AddLabelBox({
	Name = "ATTENTION!",
	Description = "This script is still in working process, some things may not working for a while until it updated"
})
t1.value4 = t2.value32
t1.value5 = t1.value4.AddToggle

function t1.value6(p12)
	enabled = p12
end

t1.value5(t1.value4, {
	Name = "Auto Backstab",
	Value = false,
	Callback = t1.value6
})
t1.value7 = t2.value32
t1.value8 = t1.value7.AddTextbox
t1.value9 = t2.value19

function t1.value10(p13)
	tonumber(p13)

	local _ = env.PllQ5BL8C0MBN5
end

t1.value8(t1.value7, {
	Name = "NormalStab Range",
	Placeholder = "none",
	Value = t1.value9,
	Callback = t1.value10
})
t1.value11 = t2.value32
t1.value12 = t1.value11.AddTextbox
t1.value13 = t2.value20

function t1.value14(p14)
	tonumber(p14)

	local _ = env.iIfwBTeax81lUo
end

t1.value12(t1.value11, {
	Name = "CrouchStab Range",
	Placeholder = "none",
	Value = t1.value13,
	Callback = t1.value14
})
t1.value15 = t2.value32
t1.value16 = t2.value16

function t1.value17(p15)
	tonumber(p15)
end

t1.value15:AddTextbox({
	Name = "Duration (All)",
	Placeholder = "none",
	Value = t1.value16,
	Callback = t1.value17
})
t1.value18 = t2.value32
t1.value19 = t1.value18.AddTextbox
t1.value20 = t2.value25

function t1.value21(p16)
	tonumber(p16)
end

t1.value19(t1.value18, {
	Name = "Delay (All)",
	Placeholder = "none",
	Value = t1.value20,
	Callback = t1.value21
})
t1.value22 = t2.value32
t1.value23 = t1.value22.AddDropdown
t1.value24 = { "Teleport", "Lerp", "PrimaryPart" }

function t1.value25(p17)
	tostring(p17)
end

t1.value23(t1.value22, {
	Name = "Auto Backstab Method",
	Options = t1.value24,
	Default = "Teleport",
	Callback = t1.value25
})
t1.value26 = t2.value32
t1.value27 = t2.value22
t1.value28 = t1.value26.AddTextbox

function t1.value29(p18)
	tonumber(p18)
end

t1.value28(t1.value26, {
	Name = "Lerp/PrimaryPart Speed",
	Placeholder = "none",
	Value = t1.value27,
	Callback = t1.value29
})
t2.value32:AddLabelBox({
	Name = "PrimaryPart"
})
t1.value30 = t2.value32
t1.value31 = { "Character", "Root" }
t1.value32 = t1.value30.AddDropdown

function t1.value33(p19)
	tostring(p19)
end

t1.value32(t1.value30, {
	Name = "PrimaryPart Method",
	Options = t1.value31,
	Default = "Character",
	Callback = t1.value33
})
t1.value34 = t2.value32

function t1.value35(p20)
	t2.value15 = p20
end

t1.value34:AddToggle({
	Name = "PivotTo (PrimaryPart)",
	Value = false,
	Callback = t1.value35
})

if v5 then
	t1.value36 = t2.value32

	function t1.value37(p21)
		t2.value1 = p21
	end

	t1.value36:AddSlider({
		Name = "Part Transparency",
		Min = 0,
		Max = 1,
		Default = 1,
		Callback = t1.value37
	})
end

t2.value32:AddLabelBox({
	Name = "Teleport"
})
t1.value38 = t2.value32
t1.value39 = t1.value38.AddToggle

function t1.value40(p22)
	tpbackenabled = p22
end

t1.value39(t1.value38, {
	Name = "Teleport Back (Teleport)",
	Value = false,
	Callback = t1.value40
})
t1.value41 = t2.value32
t1.value42 = t1.value41.AddToggle

function t1.value43(p23)
	bruh = p23
end

t1.value42(t1.value41, {
	Name = "Instant TP Hitbox (Teleport)",
	Value = false,
	Callback = t1.value43
})
t1.value44 = t2.value32
t1.value45 = t1.value44.AddTextbox
t1.value46 = t2.value10

function t1.value47(p24)
	tonumber(p24)
end

t1.value45(t1.value44, {
	Name = "TP Bypass Delay (Teleport)",
	Placeholder = "none",
	Value = t1.value46,
	Callback = t1.value47
})

if v5 then
	t1.value52 = t2.value32
	t1.value53 = t2.value11

	function t1.value54(p25)
		t2.value13 = tonumber(p25) or t2.value11
	end

	t1.value52:AddTextbox({
		Name = "Bypass Strength X (Teleport)",
		Placeholder = "none",
		Value = t1.value53,
		Callback = t1.value54
	})
	t1.value55 = t2.value32
	t1.value56 = t2.value13
	t1.value57 = t1.value55.AddTextbox

	function t1.value58(p26)
		tonumber(p26)
	end

	t1.value57(t1.value55, {
		Name = "Bypass Strength Y (Teleport)",
		Placeholder = "none",
		Value = t1.value56,
		Callback = t1.value58
	})
	t1.value59 = t2.value32
	t1.value60 = t2.value12

	function t1.value61(p27)
		tonumber(p27)
	end

	t1.value59:AddTextbox({
		Name = "Bypass Strength Z (Teleport)",
		Placeholder = "none",
		Value = t1.value60,
		Callback = t1.value61
	})
else
	t1.value48 = t2.value32
	t1.value49 = t2.value11
	t1.value50 = t1.value48.AddTextbox

	function t1.value51(p28)
		t2.value11 = tonumber(p28) or t2.value11
	end

	t1.value50(t1.value48, {
		Name = "Bypass Strength (Teleport)",
		Placeholder = "none",
		Value = t1.value49,
		Callback = t1.value51
	})
end

t2.value32:AddLabelBox({
	Name = "More Scripts",
	Description = "more thing i guess"
})
t1.value62 = t2.value32
t1.value63 = not v5

function t1.value64(p29)
	t2.value23 = p29

	if p29 then
		v125 = env.AL0SADkLLBBacV

		return
	end

	t2.value24.MinStamina = 0

	local AL0SADkLLBBacV = env.AL0SADkLLBBacV
end

t1.value62:AddToggle({
	Name = "Infinite Stamina",
	Value = false,
	Callback = t1.value64
})
t1.value65 = t2.value32
t1.value66 = t1.value65.AddToggle

function t1.value67(p30)
	t2.value4 = p30
end

t1.value66(t1.value65, {
	Name = "Auto Generator",
	Value = false,
	Callback = t1.value67
})
t1.value68 = t2.value32
t1.value69 = t1.value68.AddTextbox
t1.value70 = t2.value5

function t1.value71(p31)
	tonumber(p31)
end

t1.value69(t1.value68, {
	Name = "Gen Delay",
	Placeholder = "none",
	Value = t1.value70,
	Callback = t1.value71
})
t1.value72 = t2.value32
t1.value73 = t1.value72.AddToggle

function t1.value74(p32)
	v47(p32)
end

t1.value73(t1.value72, {
	Name = "Survivor ESP",
	Value = false,
	Callback = t1.value74
})
t1.value75 = t2.value32
t1.value76 = t1.value75.AddToggle

function t1.value77(p33)
	v40(p33)
end

t1.value76(t1.value75, {
	Name = "Killer ESP",
	Value = false,
	Callback = t1.value77
})
t1.value78 = t2.value32

function t1.value79()
	if setclipboard then
		setclipboard("https://discord.gg/6ukDzYB9Zx")
		t2.value32:SendNotification({
			Title = "Copied",
			Message = "Successfully Copied to clipboard!",
			Duration = 10
		})
	else
		t2.value32:SendNotification({
			Title = "bruh",
			Message = "you have some shitty executor there ✌😔🥀",
			Duration = 99
		})
	end
end

t1.value78:AddButton({
	Name = "Join Our Discord!",
	Callback = t1.value79
})
print("Auto Backstab v1.47 By RFS\ndear everyone, i did not skid the auto backstab v4 by skibidi scripts/skibidisaken, i just copy the idea and try making a better one.\n\nGui, Button, Textbox and whole menu (not the scripts) is created by GEMINI AI FLASH, the script functions i created them myself\n\nJoin Our Discord for questions/bug report!\nhttps://discord.gg/6ukDzYB9Zx\n")

if t1.value63 then
	t2.value32:SendNotification({
		Title = "Hello!",
		Message = "tysm for running this script :D",
		Duration = 5
	})
else
	t2.value32:SendNotification({
		Title = "Welcome.",
		Message = "You are a developer, you can access all the hidden script.",
		Duration = 15
	})
end
