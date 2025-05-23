local scale = ScrW() >= 1600 and 1 or 0.8

surface.CreateFont('lrp-selectorFont', {
    font = "Calibri",
    size = 26 * scale,
    weight = 400,
    antialias = true,
    extended = true
})

surface.CreateFont('lrp-selectorFontSmall', {
    font = "Calibri",
    size = 22 * 0.8 * scale,
    weight = 400,
    antialias = true,
    extended = true
})

local curTab = 0
local curSlot = 1
local alpha = 0
local lastAction = -math.huge
local loadout = {}
local slide = {}

local specialWeaponSlot = {
	-- wepClass = { slot, slotPos }
	weapon_physgun = { 0, 0 },

	weapon_crowbar = { 0, -2 },
    weapon_stunstick = { 0, -2 },
	weapon_physcannon = { 0, -1 },
    
    weapon_pistol = { 1, 0 },
    weapon_357 = { 1, 1 },
    
    weapon_smg1 = { 2, 0 },
    weapon_ar2 = { 2, 1 },

    weapon_shotgun = { 3, 0 },
    weapon_crossbow = { 3, 1 },
    
    weapon_frag = { 4, 0 },
	weapon_rpg = { 4, 1 },
    weapon_slam = { 4, 2 },
}

local function findcurrent()
	if alpha <= 0 then
		table.Empty(slide)
		local class = IsValid(LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon():GetClass()
		for k1, v1 in pairs(loadout) do
			for k2, v2 in pairs(v1) do
				if v2.classname == class then
					curTab = k1
					curSlot = k2
					return
				end
			end
		end
	end
end

local function update()
	table.Empty(loadout)

	for _, wep in pairs(LocalPlayer():GetWeapons()) do
		local classname = wep:GetClass()
		local Slot = specialWeaponSlot[classname] and specialWeaponSlot[classname][1] or wep.Slot or 0

		loadout[Slot] = loadout[Slot] or {}

		table.insert(loadout[Slot], {
			classname = classname,
			name = wep:GetPrintName(),
			new = (CurTime() - wep:GetCreationTime()) < 30,
			slotpos = specialWeaponSlot[classname] and specialWeaponSlot[classname][2] or wep.SlotPos or 0
		})
	end

	for _, v in pairs(loadout) do
		table.sort(v, function(a, b) return a.slotpos < b.slotpos end)
	end
end

local function SetNewWeapon(ply)
	if ply:GetActiveWeapon() and loadout[curTab][curSlot] then
		RunConsoleCommand('use', loadout[curTab][curSlot].classname)
	end
end

local FKeyBinds = {
	["gm_showhelp"] = "ShowHelp",
	["gm_showteam"] = "ShowTeam",
	["gm_showspare1"] = "ShowSpare1",
	["gm_showspare2"] = "ShowSpare2"
}

local soundSwitch = 'ambient/water/rain_drip1.wav'
local soundSelect = 'ambient/water/rain_drip3.wav'

hook.Add("PlayerBindPress", 'lrpSelector.bind', function(ply, bind, pressed)
    if GetConVar('cl_lrp_hud_type'):GetInt() == 1 then return end

	local bnd = bind:lower():match("gm_[a-z]+[12]?")
	if bnd and FKeyBinds[bnd] then
		hook.Call(FKeyBinds[bnd], GAMEMODE)
	end

	if not pressed or ply:InVehicle() or not ply:Alive() then return end

	bind = bind:lower()
	if bind:sub(1, 4) == "slot" then
		local n = tonumber(bind:sub(5, 5) or 1) or 1
		if n < 1 or n > 6 then return true end

		n = n - 1

		update()

		if not loadout[n] then return true end

		findcurrent()
		
		if curTab == n and loadout[curTab] and (alpha > 0 or GetConVar("hud_fastswitch"):GetInt() > 0) then
			curSlot = curSlot + 1

			if curSlot > #loadout[curTab] then
				curSlot = 1
			end
		else
			curTab = n
			curSlot = 1
		end

		if GetConVar("hud_fastswitch"):GetInt() > 0 then
			SetNewWeapon(ply)
		else
			alpha = 1
			lastAction = RealTime()
		end

		surface.PlaySound(GetConVar("hud_fastswitch"):GetInt() == 1 and soundSelect or soundSwitch)

		return true
	elseif bind:find("invnext", nil, true) and not (ply:GetActiveWeapon():IsValid() and ply:GetActiveWeapon():GetClass() == "weapon_physgun" and ply:KeyDown(IN_ATTACK)) then
		update()

		if #loadout < 0 then return true end

		findcurrent()

		curSlot = curSlot + 1

		if curSlot > (loadout[curTab] and #loadout[curTab] or -1) then
			repeat
				curTab = curTab + 1
				if curTab > 5 then
					curTab = 0
				end
			until loadout[curTab]
			curSlot = 1
		end

		if GetConVar("hud_fastswitch"):GetInt() > 0 then
			SetNewWeapon(ply)
		else
			lastAction = RealTime()
			alpha = 1
		end

		surface.PlaySound(GetConVar("hud_fastswitch"):GetInt() == 1 and soundSelect or soundSwitch)

		return true
	elseif bind:find("invprev", nil, true) and not (ply:GetActiveWeapon():IsValid() and ply:GetActiveWeapon():GetClass() == "weapon_physgun" and ply:KeyDown(IN_ATTACK)) then
		update()

		if #loadout < 0 then return true end

		findcurrent()

		curSlot = curSlot - 1

		if curSlot < 1 then
			repeat
				curTab = curTab - 1
				if curTab < 0 then
					curTab = 5
				end
			until loadout[curTab]
			curSlot = #loadout[curTab]
		end

		if GetConVar("hud_fastswitch"):GetInt() > 0 then
			SetNewWeapon(ply)
		else
			lastAction = RealTime()
			alpha = 1
		end

		surface.PlaySound(GetConVar("hud_fastswitch"):GetInt() == 1 and soundSelect or soundSwitch)

		return true
	elseif bind:find("+attack", nil, true) and alpha > 0 then
		if loadout[curTab] and loadout[curTab][curSlot] and not bind:find("+attack2", nil, true) then
			SetNewWeapon(ply)
		end

        SetNewWeapon(ply)
		surface.PlaySound(soundSelect)
		alpha = 0

		return true
	end
end)

local width = ScrW() * 0.09
local height = ScrH() * 0.03
local margin = height * 0.2 * scale
local colorMain = Color(0, 80, 65)
local colorSelect = Color(0, 125, 100)

hook.Add('HUDPaint', 'lrpSelector.paint', function()
	if not IsValid(LocalPlayer()) then return end

	if alpha < 1e-02 then
		if alpha ~= 0 then
			alpha = 0
		end
		
		return
	end

	update()

	if RealTime() - lastAction > 2 then
		alpha = Lerp(FrameTime() * 8, alpha, 0)
	end

	surface.SetAlphaMultiplier(alpha)

	-- surface.SetDrawColor(colorMain)
	-- surface.SetTextColor(color_white)
	-- surface.SetFont("lrp-selectorFont")

	local thisWidth = 0
	for i, v in pairs(loadout) do
		thisWidth = thisWidth + width + margin
	end

	local offx = ScrW() * 0.5 - thisWidth / 2

	for i, v in SortedPairs(loadout) do
		local offy = margin

		-- draw.RoundedBox(8, offx, offy, height, height, colorMain)

		-- local w, h = surface.GetTextSize(i + 1)
		-- surface.SetTextPos(offx  + (height - w) / 2, offy + (height - h) / 2)
		-- surface.DrawText(i + 1)
		-- offy = offy + h + margin

		for j, wep in pairs(v) do
			local selected = curTab == i and curSlot == j

			local height = height + (height + margin) * (slide[wep.classname] or 0)

			slide[wep.classname] = Lerp(FrameTime() * 10, slide[wep.classname] or 0, selected and 1 or 0)

			draw.RoundedBox(8, offx, offy, width, height, wep.new and Color(0, 80, math.abs(math.sin(RealTime() * 2.5)) * 65) or colorMain)
            if selected and colorSelect then
				draw.RoundedBox(8, offx + 4, offy + 4, width - 8, height - 8, colorSelect)
			end

			surface.SetFont("lrp-selectorFont")
			local w, h = surface.GetTextSize(wep.name)
			if w > width then
				surface.SetFont('lrp-selectorFontSmall')
				w, h = surface.GetTextSize(wep.name)
			end
			surface.SetTextColor(color_white)
			surface.SetTextPos(offx + (width - w) / 2, offy + (height - h) / 2)
			surface.DrawText(wep.name)

			offy = offy + height + margin
		end

		offx = offx + width + margin
	end

	surface.SetAlphaMultiplier(1)
end)

hook.Add("HUDShouldDraw", 'lrpSelector.hide', function(element)
    if GetConVar('cl_lrp_hud_type'):GetInt() == 1 then return end
    if element == "CHudWeaponSelection" then return false end
end)

hook.Add("OnScreenSizeChanged", 'lrpSelector.onScreenSizeChanged', function()
	scale = ScrW() >= 1600 and 1 or 0.8
	width = ScrW() * 0.09
	height = ScrH() * 0.03
	margin = height * 0.2 * scale
	
	surface.CreateFont('lrp-selectorFont', {
		font = "Calibri",
		size = 26 * scale,
		weight = 400,
		antialias = true,
		extended = true
	})

	surface.CreateFont('lrp-selectorFontSmall', {
		font = "Calibri",
		size = 22 * 0.8 * scale,
		weight = 400,
		antialias = true,
		extended = true
	})
end)