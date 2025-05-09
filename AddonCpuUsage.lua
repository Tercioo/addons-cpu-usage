
ACU = LibStub ("AceAddon-3.0"):NewAddon ("AddonCpuUsage", "AceConsole-3.0", "AceTimer-3.0")

local ACU = ACU
local LDB = LibStub ("LibDataBroker-1.1", true)
local LDBIcon = LDB and LibStub ("LibDBIcon-1.0", true)
local SharedMedia = LibStub:GetLibrary("LibSharedMedia-3.0")

local Loc = LibStub ("AceLocale-3.0"):GetLocale ("AddonCpuUsage")
local GameTooltip = GameTooltip

--local debugmode = true
local debugmode = false

GetNumSpecializationsForClassID = GetNumSpecializationsForClassID or C_SpecializationInfo.GetNumSpecializationsForClassID

local GetAddOnInfo   		= C_AddOns and C_AddOns.GetAddOnInfo or GetAddOnInfo
local GetNumAddOns   		= C_AddOns and C_AddOns.GetNumAddOns or GetNumAddOns
local GetAddOnCPUUsage		= GetAddOnCPUUsage
local UpdateAddOnCPUUsage	= UpdateAddOnCPUUsage

local CPUResetUsage = ResetCPUUsage
ResetCPUUsage = function()
    return print (Loc ["STRING_WARNING_COMMANDINUSE"])
end

local EventFrame = CreateFrame ("frame", "ACUEventFrame", UIParent)
local TimeFrame = CreateFrame ("frame", "ACUTimeFrame", UIParent)

ACU.DataPool = {}
local ENABLED = false

local default_db = {
	profile = {
		Minimap = {hide = false, radius = 160, minimapPos = 220},
		start_delay = 2,
		sample_size = 180,
		data_pool = {},
		first_run = false,
		auto_run = false,
		auto_run_delay = 1,
		auto_run_time = 9999,
	},
}

local OptionsTable = {
	name = "AddonCpuUsage",
	type = "group",
	args = {
		ShowMiniMap = {
			type = "toggle",
			name = Loc ["STRING_OPTIONS_MINIMAP"],
			desc = Loc ["STRING_OPTIONS_MINIMAP_DESC"],
			order = 3,
			get = function() return not ACU.db.profile.Minimap.hide end,
			set = function (self, val)
				ACU.db.profile.Minimap.hide = not ACU.db.profile.Minimap.hide
				LDBIcon:Refresh ("AddonCpuUsage", ACU.db.profile.Minimap.hide)
				if (not ACU.db.profile.Minimap.hide) then
					LDBIcon:Show ("AddonCpuUsage")
				else
					LDBIcon:Hide ("AddonCpuUsage")
				end
			end,
		},
		AutoRun = {
			type = "toggle",
			name = Loc ["STRING_OPTIONS_CAPTUREONLOGIN"],
			desc = Loc ["STRING_OPTIONS_CAPTUREONLOGIN_DESC"],
			order = 4,
			get = function() return ACU.db.profile.auto_run end,
			set = function (self, val)
				ACU.db.profile.auto_run = not ACU.db.profile.auto_run
			end,
		},
		AutoRunDelay = {
			type = "range",
			name = Loc ["STRING_OPTIONS_CAPTUREONLOGIN_DELAY"],
			desc = Loc ["STRING_OPTIONS_CAPTUREONLOGIN_DELAY_DESC"],
			min = 0,
			max = 60,
			step = 0.1,
			get = function() return ACU.db.profile.auto_run_delay end,
			set = function (self, val) ACU.db.profile.auto_run_delay = val end,
			order = 5,
		},
		AutoRunTime = {
			type = "range",
			name = Loc ["STRING_OPTIONS_CAPTUREONLOGIN_TIME"],
			desc = Loc ["STRING_OPTIONS_CAPTUREONLOGIN_TIME_DESC"],
			min = 1,
			max = 9999,
			step = 1,
			get = function() return ACU.db.profile.auto_run_time end,
			set = function (self, val) ACU.db.profile.auto_run_time = val end,
			order = 6,
		},

		StartDelay = {
			type = "range",
			name = Loc ["STRING_OPTIONS_STARTDELAY"],
			desc = Loc ["STRING_OPTIONS_STARTDELAY_DESC"],
			min = 0,
			max = 5,
			step = 1,
			get = function() return ACU.db.profile.start_delay end,
			set = function (self, val) ACU.db.profile.start_delay = val end,
			order = 1,
		},
		SampleSize = {
			type = "range",
			name = Loc ["STRING_OPTIONS_GATHERTIME"],
			desc = Loc ["STRING_OPTIONS_GATHERTIME_DESC"],
			min = 120,
			max = 300,
			step = 1,
			get = function() return ACU.db.profile.sample_size end,
			set = function (self, val) ACU.db.profile.sample_size = val end,
			order = 1,
		},
	}
}

function ACU:DoBenchmark()
	local benchmarkFrame = AddonsCPUUsageBenchmarkFrame or CreateFrame ("frame", "AddonsCPUUsageBenchmarkFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
	benchmarkFrame.texture = benchmarkFrame.texture or benchmarkFrame:CreateTexture(nil, "overlay")
	benchmarkFrame.fontstring = benchmarkFrame.fontstring or benchmarkFrame:CreateFontString(nil, "overlay", "GameFontNormal")
	local stringText = "dhaksjerkjrkjsdnsadjhalkjahdfgkjlhasjkgharjasejksdhfkjlerklaklzlkeorerwehjrwgrwegasmnbdauioiqwueui,mcxvjqweuiysdlmivrtnyhwx,oicro.lcvfto.lhjkmvsyhgsrhjgsaekjgklhkjlhkjliopepwoweop´q~sçd;.,xcv,.mvcbmbvjkdfhg"

	if (DetailsFramework) then
		DetailsFramework:ApplyStandardBackdrop(benchmarkFrame)
	end

	benchmarkFrame:SetSize(200, 60)
	benchmarkFrame.performingString = benchmarkFrame.performingString or benchmarkFrame:CreateFontString(nil, "overlay", "GameFontNormal")
	benchmarkFrame.performingString:SetPoint("center")
	benchmarkFrame.performingString:SetText("Calculating CPU Score")
	benchmarkFrame:SetPoint("center")
	benchmarkFrame:SetFrameStrata("FULLSCREEN")

	benchmarkFrame:Show()

	local fontString = benchmarkFrame.fontstring
	local texture = benchmarkFrame.texture
	local texturePath = [[Interface\ICONS\6OR_Garrison_metaltrim_02]]
	local scores = {}

	--start
	C_Timer.After(0, function()
		local startTime = debugprofilestop()

		--> math
			for i = 1, 10^7 do
				i = i * i / 2 + i
			end
			local deltaTime = debugprofilestop() - startTime
			scores[#scores+1] = deltaTime
			startTime = debugprofilestop()

		--> table allocation
			local myTable = {}
			for i = 1, 10^5 do
				for o = 1, 33 do
					myTable[o] = true
				end
				for o = 33, 1, -1 do
					myTable[o] = nil
				end
			end
			local deltaTime = debugprofilestop() - startTime
			scores[#scores+1] = deltaTime
			startTime = debugprofilestop()

		--> string manipulation
			for i = 1, 10^2 do
				for o = 1, #stringText do
					fontString:SetText(stringText:sub(1, -o))
					fontString:GetStringWidth()
				end
			end
			local deltaTime = debugprofilestop() - startTime
			scores[#scores+1] = deltaTime
			startTime = debugprofilestop()

		--> texture manipulation
			for i = 0.00001, 1, 0.00001 do
				texture:SetTexture(texturePath)
				texture:SetTexCoord(i, -i, -i, i, -i, -i, i, -i)
				--texture:SetColorTexture(i, i, i, i) --too expensive
				texture:SetVertexColor(i, i, i, i)
			end
			local deltaTime = debugprofilestop() - startTime
			scores[#scores+1] = deltaTime

		ACU.CPUBeachmarkResults = {}

		local totalTime = 0
		for i = 1, #scores do
			totalTime = totalTime + scores[i]
			ACU.CPUBeachmarkResults[i] = scores[i]
		end

		ACU.CPUBeachmarkTotalTime = totalTime
		ACU.BenchmarkDone = true

		benchmarkFrame:Hide()
		ACU:UpdateCPUScoreOnScreenPanel()
	end)
end

function ACU:OnInitialize()

	self.db = LibStub ("AceDB-3.0"):New ("AddonCpuUsageDB", default_db, true)

	LibStub ("AceConfig-3.0"):RegisterOptionsTable ("AddonCpuUsage", OptionsTable)
	ACU.OptionsFrame1 = LibStub ("AceConfigDialog-3.0"):AddToBlizOptions ("AddonCpuUsage", "AddonCpuUsage")
	--sub tab
	LibStub ("AceConfig-3.0"):RegisterOptionsTable ("AddonCpuUsage-Profiles", LibStub ("AceDBOptions-3.0"):GetOptionsTable (self.db))
	ACU.OptionsFrame2 = LibStub ("AceConfigDialog-3.0"):AddToBlizOptions ("AddonCpuUsage-Profiles", "Profiles", "AddonCpuUsage")

	if (LDB) then
		local databroker = LDB:NewDataObject ("AddonCpuUsage", {
			type = "launcher",
			icon = [[Interface\AddOns\ACU\icon]],
			OnClick = function (self, button)
				if (button == "LeftButton") then
					if (not ACUMainFrame) then
						ACU:CreateMainWindow()
					else
						ACUMainFrame:Show()
					end
				else
					InterfaceOptionsFrame_OpenToCategory ("AddonCpuUsage")
					InterfaceOptionsFrame_OpenToCategory ("AddonCpuUsage")
				end
			end,
			OnTooltipShow = function (tooltip)
				GameTooltip:AddLine ("Addon CPU Usage")
				GameTooltip:AddLine (Loc ["STRING_DATABROKER_HELP_LEFTBUTTON"])
				GameTooltip:AddLine (Loc ["STRING_DATABROKER_HELP_RIGHTBUTTON"])
			end
		})

		if (databroker and not LDBIcon:IsRegistered ("AddonCpuUsage")) then
			LDBIcon:Register ("AddonCpuUsage", databroker, ACU.db.profile.Minimap)
		end
	end

	ENABLED = ACU:IsProfileEnabled()

	if (ACU:IsProfileEnabled() and not ACU.db.profile.auto_open) then
		print ("-------------------------")
		ACU:Msg (Loc ["STRING_WARNING_PROFILERISENABLED"])
		print ("-------------------------")
	end

	C_Timer.After(1, function()
		--debug
		if (debugmode or ACU.db.profile.auto_open) then
			function ACU:ShowMe()
				ACUMainFrame:Show()
			end

			ACU:CreateMainWindow()
			ACUMainFrame:Show()
			--ACU:ScheduleTimer ("ShowMe", 1)

			ACU.db.profile.auto_open = nil

			if (debugmode) then
				ACU.DataPool = ACU.db.profile.data_pool
			end
		end

		if (ACU.db.profile.auto_run) then
			if (ACU:IsProfileEnabled()) then
				function ACU:AutoStart()
					if (ACU.RealTimeTick) then
						ACU.StopRealTime()
					end
					ACU:StartRealTime (ACU.db.profile.auto_run_time)
				end
				ACU:ScheduleTimer ("AutoStart", ACU.db.profile.auto_run_delay)
			end
		end
	end)
end

function ACU.StopRealTime()
	if (ACU.RealTimeTick) then
		ACU.RealTimeTick:Cancel()
		ACU.RealTimeTick = nil
		ACU:Msg ("real time ended.")
	end
	if (ACU.RealTimeTimer) then
		ACU.RealTimeTimer:Cancel()
	end
	ACU.RealTimeTimer = nil
	ACU.realtime_timer_string:SetText ("")
end

ACU:RegisterChatCommand ("cpu", function (command)

	if (command == "debug") then
		debugmode = true
		ACU:Msg ("debug mode turned on.")
		EventFrame:RegisterEvent ("PLAYER_REGEN_DISABLED")
		EventFrame:RegisterEvent ("PLAYER_REGEN_ENABLED")

	elseif (command == "realtime" or command:find ("realtime")) then

		local command, timer = command:match("^(%S*)%s*(.-)$")
		timer = tonumber (timer)

		if (ACU:IsProfileEnabled()) then
			if (ACU.RealTimeTick) then
				ACU.StopRealTime()
				return
			end
			ACU:Msg ("real time started.")
			ACU:StartRealTime (timer)
		else
			ACU:Msg (Loc ["STRING_PROFILING_NOT_ENABLED"])
		end
	else
		if (not ACUMainFrame) then
			ACU:CreateMainWindow()
		else
			ACUMainFrame:Show()
		end
	end
end)


function ACU:Msg (msg)
	print ("|cFFFFCC00AddOns CPU Usage|r:", msg)
end

function ACU:IsProfileEnabled()
	return GetCVar("scriptProfile") == "1"
end

function ACU:SetProfileEnabled (enabled)
	SetCVar ("scriptProfile", enabled and 1 or 0)
	if (enabled) then
		ACU.db.profile.auto_open = true
	end
	ReloadUI()
end

local highlight = "|cFFFFFF00"
local tutorial_phrases = {
	Loc ["STRING_TUTORIAL_LINE_1"],
	Loc ["STRING_TUTORIAL_LINE_2"],
	Loc ["STRING_TUTORIAL_LINE_3"],
	Loc ["STRING_TUTORIAL_LINE_4"],
	Loc ["STRING_TUTORIAL_LINE_5"],
	Loc ["STRING_TUTORIAL_LINE_6"],
}

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--> events

	local sort_func = function (t1, t2)
		return t1[2] > t2[2]
	end

	local min_time = 120

	function ACU:TimerEnd()
		ACU.CurrentEncounter.incombat = false

		if (ACU.CurrentEncounter.delay_thread) then
			ACU:CancelTimer (ACU.CurrentEncounter.delay_thread)
		end
		if (ACU.CurrentEncounter.tick_thread) then
			ACU:CancelTimer (ACU.CurrentEncounter.tick_thread)
		end

		local elapsed_time = GetTime() - ACU.CurrentEncounter.start

		TimeFrame:SetScript ("OnUpdate", nil)

		ACU.CurrentEncounter.cpu_time = TimeFrame.cpu_time
		ACU.CurrentEncounter.addons_time = TimeFrame.addons_time

		if (debugmode) then
			min_time = 0
		end

		ACU.capture_panel:Hide()

		if (elapsed_time >= min_time) then
			local addons = ACU.CurrentEncounter.addons
			local ordered = {}
			for name, addon in pairs (addons) do
				ordered [#ordered+1] = {name, addon.total, addon}
			end
			table.sort (ordered, sort_func)
			ordered.elapsed_time = elapsed_time

			ordered.showing = {}
			for i = 1, min (#ordered, 3) do
				ordered.showing [ordered[i][1]] = true
			end

			ordered.total_cpu_by_addons = ACU.CurrentEncounter.total
			ordered.cpu_time = ACU.CurrentEncounter.cpu_time
			ordered.addons_time = ACU.CurrentEncounter.addons_time

			if (debugmode) then
				table.wipe (ACU.DataPool)
				tinsert (ACU.DataPool, 1, ordered)
				ACU.db.profile.data_pool = ACU.DataPool

				if (ACU.CurrentEncounter.tick_thread) then
					ACU:CancelTimer (ACU.CurrentEncounter.tick_thread)
				end
			else
				tinsert (ACU.DataPool, 1, ordered)
			end

			ACU:Msg (Loc ["STRING_FINISHED_SUCCESSFUL"])
		else
			ACU:Msg (Loc ["STRING_FINISHED_NOTENOUGHTIME"])
		end

		if (not InCombatLockdown() and not UnitAffectingCombat ("player")) then
			if (not ACUMainFrame) then
				ACU:CreateMainWindow()
			else
				ACUMainFrame:Show()
			end
		else
			ACU:Msg (Loc ["STRING_FINISHED_INCOMBAT"])
		end

	end

	local function calc_cpu_intervals (self, elapsed)
		UpdateAddOnCPUUsage()

		local delay = 0

		local addons = self.addons
		for addon_name, last_value in pairs (addons) do
			local usage = GetAddOnCPUUsage (addon_name)
			delay = delay + (usage - last_value)
			addons [addon_name] = usage
		end

		local game_time = elapsed - delay
		local addons_time = elapsed - game_time

		self.cpu_time = self.cpu_time + game_time
		self.addons_time = self.addons_time + addons_time

		--should pre create these tables on another place
		if (not self.addons_selftimer) then
			self.addons_selftimer = {}
			self.addons_gametick = {}
		end
		self.addons_selftimer [addon_name] = (self.addons_selftimer [addon_name] or 0) + game_time
		if (self.addons_selftimer [addon_name] > 0.016) then
			self.addons_gametick [addon_name] = (self.addons_gametick [addon_name] or 0) + 1
		end
	end

	function ACU:Tick (t)
		--check timeout
		local elapsed_time = GetTime() - ACU.CurrentEncounter.start

		if (elapsed_time >= ACU.db.profile.sample_size) then
			ACU.show_on_encounter_end = true
			return ACU:TimerEnd()
		end

		local percent = elapsed_time / ACU.db.profile.sample_size * 100
		ACU.capture_panel.statusbar:SetValue (percent)
		ACU.capture_panel.percent:SetText (floor (percent) .. "%")
		ACU.capture_panel.statusbar.spark:SetPoint ("center", ACU.capture_panel.statusbar, "left", ACU.capture_panel.statusbar:GetWidth()/100*percent, -1)

		UpdateAddOnCPUUsage()

		-- calc addons cpu usage
		local total_usage = 0

		for name, addon in pairs (ACU.CurrentEncounter.addons) do

			local cpu = GetAddOnCPUUsage (name)
			local diff = cpu - addon.last_value

			addon [#addon+1] = diff
			addon.last_value = cpu
			addon.total = cpu

			total_usage = total_usage + diff

			if (diff > addon.max_value) then
				addon.max_value = diff
			end
		end

		ACU.CurrentEncounter.total = ACU.CurrentEncounter.total + total_usage
	end

	function ACU:StartTicker()
		if (ACU.CurrentEncounter.incombat) then
			ACU.CurrentEncounter.delay_thread = false

			UpdateAddOnCPUUsage()

			local addons = ACU.CurrentEncounter.addons
			local total_addons = GetNumAddOns()
			TimeFrame.addons = {}

			for i = 1, total_addons do
				local name, title, notes, loadable, reason, security, newVersion = GetAddOnInfo (i)
				if (GetAddOnCPUUsage (name) > 0 and name ~= "ACU") then
					addons [name] = {max_value = 0, total = 0, last_value = 0, index = i}
					TimeFrame.addons [name] = 0
				end
			end

			CPUResetUsage()

			ACU.CurrentEncounter.tick_thread = ACU:ScheduleRepeatingTimer ("Tick", 1)

			TimeFrame.cpu_time = 0
			TimeFrame.addons_time = 0

			if (ACU.CalculateGameTime) then
				TimeFrame:SetScript ("OnUpdate", calc_cpu_intervals)
			end

			if (debugmode) then
				ACU:Msg ("loop started.")
			end

			ACU.capture_panel:Show()
			ACU.capture_panel.statusbar:SetValue (0)
			ACU.capture_panel.percent:SetText ("0%")

			if (ACUMainFrame and ACUMainFrame:IsShown()) then
				ACUMainFrame:Hide()
			end

		end
	end

	EventFrame:SetScript ("OnEvent", function (self, event, ...)

		if ((event == "ENCOUNTER_START" and not debugmode) or event == "PLAYER_REGEN_DISABLED") then

			if (debugmode) then
				ACU:Msg ("encounter started.")
			end

			if (ACU:IsProfileEnabled()) then
				ACU.CurrentEncounter = {
					delay = ACU.db.profile.start_delay,
					start = GetTime() + ACU.db.profile.start_delay,
					addons = {},
					incombat = true,
					total = 0,

				}
				ACU.CurrentEncounter.delay_thread = ACU:ScheduleTimer ("StartTicker", ACU.db.profile.start_delay)

				if (debugmode) then
					ACU:Msg ("delay tick thread created, waiting " .. ACU.db.profile.start_delay .. " seconds to start.")
				end
			end

		elseif ((event == "ENCOUNTER_END" and not debugmode) or event == "PLAYER_REGEN_ENABLED") then

			if (debugmode) then
				ACU:Msg ("encounter ended.")
			end

			if (ACU:IsProfileEnabled() and ACU.CurrentEncounter and ACU.CurrentEncounter.incombat) then
				if (debugmode) then
					ACU:Msg ("starting timerend().")
				end
				ACU:TimerEnd()
			end

			if (ACU.show_on_encounter_end) then
				if (not ACUMainFrame) then
					ACU:CreateMainWindow()
				else
					ACUMainFrame:Show()
				end
				ACU.show_on_encounter_end = nil
			end

		elseif (event == "ZONE_CHANGED_NEW_AREA") then

			--verifica se o profiling ta ativo
				-- se tiver pergunta se quer desativar
				-- dispara depois de um /reload?

		end
	end)

	EventFrame:RegisterEvent ("ENCOUNTER_START")
	EventFrame:RegisterEvent ("ENCOUNTER_END")
	EventFrame:RegisterEvent ("ZONE_CHANGED_NEW_AREA")

	--debug
	if (debugmode) then
		EventFrame:RegisterEvent ("PLAYER_REGEN_DISABLED")
		EventFrame:RegisterEvent ("PLAYER_REGEN_ENABLED")
	end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	function ACU:CreateMainWindow()

		-- main frame
		local f = CreateFrame ("frame", "ACUMainFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
		f:SetSize (780, 475)
		f:SetPoint ("center", UIParent, "center")
		f:EnableMouse (true)
		f:SetMovable (true)
		f:SetBackdrop ({bgFile = [[Interface\AddOns\ACU\background]], tileSize = 64, edgeFile = [[Interface\AddOns\ACU\border_2]], edgeSize = 16, insets = {left = 1, right = 1, top = 1, bottom = 1}})
		tinsert (UISpecialFrames, "ACUMainFrame")
		f:SetBackdropColor (0, 0, 0, 0.6)
		f:SetScript ("OnMouseDown", function (self, button)
			if (not self.isMoving and button == "LeftButton") then
				self.isMoving = true
				self:StartMoving()
			end
		end)
		f:SetScript ("OnMouseUp", function (self, button)
			if (self.isMoving) then
				self.isMoving = nil
				self:StopMovingOrSizing()
			end
		end)

		local DF = _G.DetailsFramework
		if (DF) then
			DF:ApplyStandardBackdrop(f)
		end

		-- close button
		local c = CreateFrame ("Button", nil, f, "UIPanelCloseButton", BackdropTemplateMixin and "BackdropTemplate")
		c:SetWidth (32)
		c:SetHeight (32)
		c:SetPoint ("topright",  f, "topright", -3, -8)
		c:SetFrameLevel (f:GetFrameLevel()+1)
		c:SetAlpha (1)
		--c:Hide()

		--title
		local icon = f:CreateTexture (nil, "overlay")
		icon:SetTexture ([[Interface\AddOns\ACU\icon]])
		icon:SetSize (24, 24)
		icon:SetPoint ("topleft", f, "topleft", 10, -10)
		local title = f:CreateFontString (nil, "overlay", "GameFontNormal")
		title:SetText ("Addons CPU Usage")
		title:SetPoint ("left", icon, "right", 6, 0)

		--total usage:
		local totalusage = f:CreateFontString (nil, "overlay", "GameFontNormal")
		totalusage:SetText (Loc ["STRING_LISTPANEL_TOTAL"])
		totalusage:SetTextColor (1, 1, 1)
		totalusage:SetPoint ("left", title, "right", 24, 0)
		local totalusage2 = f:CreateFontString (nil, "overlay", "GameFontNormal")
		totalusage2:SetText ("--x--x--")
		totalusage2:SetPoint ("left", totalusage, "right", 3, 0)
		ACU.totalusage2 = totalusage2

		local totalusage_tooltip = CreateFrame ("frame", nil, f, BackdropTemplateMixin and "BackdropTemplate")
		totalusage_tooltip:SetFrameLevel (f:GetFrameLevel()+1)
		totalusage_tooltip:SetPoint ("left", totalusage, "left")
		totalusage_tooltip:SetSize (100, 20)
		totalusage_tooltip:SetScript ("OnEnter", function (self)
			GameTooltip:SetOwner (self, "ANCHOR_CURSOR")
			GameTooltip:AddLine (Loc ["STRING_LISTPANEL_TOTAL_DESC_TITLE"])
			GameTooltip:AddLine (" ")
			GameTooltip:AddLine (Loc ["STRING_LISTPANEL_TOTAL_DESC"])
			if (ACU.DataPool [1] and ACU.DataPool [1].total_cpu_by_addons) then
				--GameTooltip:AddLine (" ")
				--GameTooltip:AddLine ("Total Frames Lost: " .. floor (ACU.DataPool [1].total_cpu_by_addons / 16))
				--local total = ACU.DataPool [1].total_cpu_by_addons / 1000
				--ACU.totalusage2:SetText (format ("%.2fs", total) .. " (" .. format ("%.1f", total / ACU.DataPool [1].elapsed_time * 100) .. "%)")
				--local average = ACU.DataPool [1].total_cpu_by_addons / ACU.DataPool [1].elapsed_time
				--ACU.averageusage2:SetText (format ("%.2fms", average))
				--ACU.fpsloss2:SetText (format ("%.2ffps", average/16.6))
			end
			GameTooltip:Show()
		end)
		totalusage_tooltip:SetScript ("OnLeave", function (self)
			GameTooltip:Hide()
		end)

		local averageusage = f:CreateFontString (nil, "overlay", "GameFontNormal")
		averageusage:SetText (Loc ["STRING_LISTPANEL_AVERAGE"])
		averageusage:SetTextColor (1, 1, 1)
		averageusage:SetPoint ("left", title, "right", 130, 0)
		local averageusage2 = f:CreateFontString (nil, "overlay", "GameFontNormal")
		averageusage2:SetText ("--x--x--")
		averageusage2:SetPoint ("left", averageusage, "right", 3, 0)
		ACU.averageusage2 = averageusage2

		local averageusage_tooltip = CreateFrame ("frame", nil, f, BackdropTemplateMixin and "BackdropTemplate")
		averageusage_tooltip:SetFrameLevel (f:GetFrameLevel()+1)
		averageusage_tooltip:SetPoint ("left", averageusage, "left")
		averageusage_tooltip:SetSize (100, 20)
		averageusage_tooltip:SetScript ("OnEnter", function (self)
			GameTooltip:SetOwner (self, "ANCHOR_CURSOR")
			GameTooltip:AddLine (Loc ["STRING_LISTPANEL_AVERAGE_DESC_TITLE"])
			GameTooltip:AddLine (" ")
			GameTooltip:AddLine (Loc ["STRING_LISTPANEL_AVERAGE_DESC"])
			GameTooltip:Show()
		end)
		averageusage_tooltip:SetScript ("OnLeave", function (self)
			GameTooltip:Hide()
		end)

		--> cpu score
		local cpu_score_text = f:CreateFontString (nil, "overlay", "GameFontNormal")
		cpu_score_text:SetText ("Cpu Score:")
		cpu_score_text:SetTextColor (1, 1, 1)
		cpu_score_text:SetPoint ("left", title, "right", 260, 0)
		local cpu_score_text2 = f:CreateFontString (nil, "overlay", "GameFontNormal")
		cpu_score_text2:SetText ("--x--x--")
		cpu_score_text2:SetPoint ("left", cpu_score_text, "right", 3, 0)
		ACU.cpu_score_text2 = cpu_score_text2

		local getFormattedCpuScore = function()
			return ceil(math.max(abs(2000 - ACU.CPUBeachmarkTotalTime, 0)))
		end

		local getFormattedTestResult = function(testId)
			local score = ACU.CPUBeachmarkResults[testId]
			local percent = score / ACU.CPUBeachmarkTotalTime

			local formattedTotalScore = getFormattedCpuScore()
			return ceil(formattedTotalScore * percent)
		end

		local cpu_score_frame = CreateFrame ("frame", nil, f, BackdropTemplateMixin and "BackdropTemplate")
		cpu_score_frame:SetFrameLevel (f:GetFrameLevel()+1)
		cpu_score_frame:SetPoint ("left", cpu_score_text, "left")
		cpu_score_frame:SetSize (100, 20)
		cpu_score_frame:SetScript ("OnEnter", function (self)
			GameTooltip:SetOwner (self, "ANCHOR_CURSOR")
			GameTooltip:AddLine ("Cpu Score")
			GameTooltip:AddLine (Loc ["STRING_CPUSCORE_DESC"])
			GameTooltip:AddLine(" ")
			GameTooltip:AddDoubleLine("Test 1:", getFormattedTestResult(1))
			GameTooltip:AddDoubleLine("Test 2:", getFormattedTestResult(2))
			GameTooltip:AddDoubleLine("Test 3:", getFormattedTestResult(3))
			GameTooltip:AddDoubleLine("Test 4:", getFormattedTestResult(4))
			GameTooltip:Show()
		end)
		cpu_score_frame:SetScript ("OnLeave", function (self)
			GameTooltip:Hide()
		end)

		function ACU:UpdateCPUScoreOnScreenPanel()
			if (ACU.CPUBeachmarkResults) then
				ACU.cpu_score_text2:SetText(getFormattedCpuScore())
			end
		end

		--run the beachmark when the window is created
		ACU:DoBenchmark()

		local fpsloss = f:CreateFontString (nil, "overlay", "GameFontNormal")
		fpsloss:SetText ("Loss:")
		fpsloss:SetTextColor (1, 1, 1)
		fpsloss:SetPoint ("left", title, "right", 305, 0)
		local fpsloss2 = f:CreateFontString (nil, "overlay", "GameFontNormal")
		fpsloss2:SetText ("--x--x--")
		fpsloss2:SetPoint ("left", fpsloss, "right", 3, 0)
		ACU.fpsloss2 = fpsloss2

		local fpsloss_tooltip = CreateFrame ("frame", nil, f, BackdropTemplateMixin and "BackdropTemplate")
		fpsloss_tooltip:SetFrameLevel (f:GetFrameLevel()+1)
		fpsloss_tooltip:SetPoint ("left", fpsloss, "left")
		fpsloss_tooltip:SetSize (100, 20)
		fpsloss_tooltip:SetScript ("OnEnter", function (self)
			GameTooltip:SetOwner (self, "ANCHOR_CURSOR")
			GameTooltip:AddLine (Loc ["STRING_DROPFRAMES_TITLE"])
			GameTooltip:AddLine (" ")

			if (ACU.DataPool [1] and ACU.DataPool [1].cpu_time) then
				GameTooltip:AddLine (" ")
				GameTooltip:AddLine ("CPU Time: " .. ACU.DataPool [1].cpu_time)
				GameTooltip:AddLine ("Addons Time: " .. ACU.DataPool [1].addons_time)
			end

			GameTooltip:Show()
		end)
		fpsloss_tooltip:SetScript ("OnLeave", function (self)
			GameTooltip:Hide()
		end)

		--isn't working / not accuracy result
		fpsloss:Hide()
		fpsloss2:Hide()
		fpsloss_tooltip:Hide()

		--help tooltip
		local help_str = f:CreateFontString (nil, "overlay", "GameFontNormal")
		help_str:SetText ("")
		help_str:SetTextColor (.7, .7, .7)
		help_str:SetPoint ("left", title, "right", 410, 0)

		local help_image = f:CreateTexture (nil, "overlay")
		help_image:SetTexture ([[Interface\Calendar\EventNotification]])
		help_image:SetPoint ("left", help_str, "right")
		help_image:SetSize (24, 24)
		help_image:SetDesaturated (true)

		local help_tooltip = CreateFrame ("frame", nil, f, BackdropTemplateMixin and "BackdropTemplate")
		help_tooltip:SetFrameLevel (f:GetFrameLevel()+1)
		help_tooltip:SetPoint ("left", help_str, "left")
		help_tooltip:SetSize (100, 20)
		help_tooltip:SetScript ("OnEnter", function (self)
			help_image:SetDesaturated (false)
			help_str:SetTextColor (1, 1, 1)
			GameTooltip:SetOwner (self, "ANCHOR_CURSOR")

			GameTooltip:AddLine (Loc ["STRING_TUTORIAL_TITLE"])
			GameTooltip:AddLine (" ")

			for _, phrase in ipairs (tutorial_phrases) do
				GameTooltip:AddLine (phrase)
			end

			GameTooltip:Show()
		end)
		help_tooltip:SetScript ("OnLeave", function (self)
			help_image:SetDesaturated (true)
			help_str:SetTextColor (.7, .7, .7)
			GameTooltip:Hide()
		end)

		--chart frame
		local chart = CreateACUChartPanel (f, 765, 370, "ACUChartFrame")
		chart:SetPoint ("topleft", f, "topleft", 10, -50)
		chart:SetBackdrop ({bgFile = [[Interface\AddOns\ACU\background]], tileSize = 64, edgeFile = [[Interface\AddOns\ACU\border_2]], edgeSize = 16, insets = {left = 1, right = 1, top = 1, bottom = 1}})
		chart:SetBackdropColor (0, 0, 0, 0.2)
		chart:SetBackdropBorderColor (0, 0, 0, 0)
		chart:SetScript ("OnMouseDown", function (self, button)
			if (not f.isMoving and button == "LeftButton") then
				f.isMoving = true
				f:StartMoving()
			end
		end)
		chart:SetScript ("OnMouseUp", function (self, button)
			if (f.isMoving) then
				f.isMoving = nil
				f:StopMovingOrSizing()
			end
		end)

		chart.CloseButton:Hide()
		chart.Graphic:SetBackdropColor (0, 0, 0, 0)
		chart.Graphic:SetBackdropBorderColor (0, 0, 0, 0)

		--table frame
		local table_frame = CreateFrame ("frame", "ACUTableFrame", f, BackdropTemplateMixin and "BackdropTemplate")
		table_frame:SetPoint ("topleft", f, "topleft", 10, -50)
		table_frame:SetSize (765, 370)
		table_frame:SetBackdrop ({bgFile = [[Interface\AddOns\ACU\background]], tileSize = 64, edgeFile = [[Interface\AddOns\ACU\border_2]], edgeSize = 16, insets = {left = 1, right = 1, top = 1, bottom = 1}})
		table_frame:SetBackdropColor (0, 0, 0, 0.2)
		table_frame:SetBackdropBorderColor (0, 0, 0, 0)
		table_frame:SetScript ("OnMouseDown", function (self, button)
			if (not f.isMoving and button == "LeftButton") then
				f.isMoving = true
				f:StartMoving()
			end
		end)
		table_frame:SetScript ("OnMouseUp", function (self, button)
			if (f.isMoving) then
				f.isMoving = nil
				f:StopMovingOrSizing()
			end
		end)

		table_frame.lines = {}

		local on_click_checkbox = function (self)
			if (ACU.DataPool [1] and ACU.DataPool [1].showing and ACU.DataPool [1].showing) then
				ACU.DataPool [1].showing [self.addon] = not ACU.DataPool [1].showing [self.addon]
			end
		end

		--titles
		local index_string_title = table_frame:CreateFontString (nil, "overlay", "GameFontNormal")
		local name_string_title = table_frame:CreateFontString (nil, "overlay", "GameFontNormal")
		local total_usage_string_title = table_frame:CreateFontString (nil, "overlay", "GameFontNormal")
		local total_psec_string_title = table_frame:CreateFontString (nil, "overlay", "GameFontNormal")
		local total_percent_string_title = table_frame:CreateFontString (nil, "overlay", "GameFontNormal")
		local peak_string_title = table_frame:CreateFontString (nil, "overlay", "GameFontNormal")
		local graphic_checkbox_title = table_frame:CreateFontString (nil, "overlay", "GameFontNormal")

		local function CreateTooltipAnchor (anchor, title, tooltip)
			local tframe = CreateFrame ("frame", nil, f, BackdropTemplateMixin and "BackdropTemplate")
			tframe:SetFrameLevel (f:GetFrameLevel()+3)
			tframe:SetPoint ("left", anchor, "left")
			tframe:SetSize (80, 20)
			tframe:SetScript ("OnEnter", function (self)
				GameTooltip:SetOwner (self, "ANCHOR_CURSOR")
				GameTooltip:AddLine (title)
				GameTooltip:AddLine (" ")
				GameTooltip:AddLine (tooltip)
				GameTooltip:Show()
			end)
			tframe:SetScript ("OnLeave", function (self)
				GameTooltip:Hide()
			end)
		end

		CreateTooltipAnchor (total_usage_string_title, Loc ["STRING_LISTPANEL_TOTALUSAGE"], Loc ["STRING_LISTPANEL_TOTALUSAGE_DESC"])
		CreateTooltipAnchor (total_psec_string_title, Loc ["STRING_LISTPANEL_MS"], Loc ["STRING_LISTPANEL_MS_DESC"])
		CreateTooltipAnchor (peak_string_title, Loc ["STRING_LISTPANEL_PEAK"], Loc ["STRING_LISTPANEL_PEAK_DESC"])

		index_string_title:SetPoint ("topleft", table_frame, "topleft", 7, 0)
		name_string_title:SetPoint ("topleft", table_frame, "topleft", 24, 0)
		total_usage_string_title:SetPoint ("topleft", table_frame, "topleft", 204, 0)
		total_psec_string_title:SetPoint ("topleft", table_frame, "topleft", 303, 0)
		total_percent_string_title:SetPoint ("topleft", table_frame, "topleft", 405, 0)
		peak_string_title:SetPoint ("topleft", table_frame, "topleft", 505, 0)
		graphic_checkbox_title:SetPoint ("topleft", table_frame, "topleft", 655, 0)

		index_string_title:SetText ("#")
		name_string_title:SetText (Loc ["STRING_LISTPANEL_ADDONNAME"])
		total_usage_string_title:SetText (Loc ["STRING_LISTPANEL_TOTALUSAGE"])
		total_psec_string_title:SetText (Loc ["STRING_LISTPANEL_MS"])
		total_percent_string_title:SetText (Loc ["STRING_LISTPANEL_PERCENT"])
		peak_string_title:SetText (Loc ["STRING_LISTPANEL_PEAK"])
		graphic_checkbox_title:SetText (Loc ["STRING_SWITCH_SHOWGRAPHIC"])

		local on_enter = function (self)
			self:SetBackdropColor (1, 1, 1, 0.5)
		end

		local on_leave = function (self)
			self:SetBackdropColor (unpack (self.background_color))
		end

		local background1 = {1, 1, 1, 0.3}
		local background2 = {1, 1, 1, 0.0}

		for i = 1, 16 do
			local line = CreateFrame ("frame", "ACUTableFrameLine" .. i, table_frame, BackdropTemplateMixin and "BackdropTemplate")
			local y = (i-0) * 21 * -1
			line:SetPoint ("topleft", table_frame, "topleft", 5, y)
			line:SetPoint ("topright", table_frame, "topright", -25, y)
			line:SetHeight (20)
			line:SetScript ("OnEnter", on_enter)
			line:SetScript ("OnLeave", on_leave)

			if (i % 2 == 0) then
				line:SetBackdrop ({bgFile = [[Interface\AddOns\ACU\background]], tileSize = 64})
				line:SetBackdropColor (unpack (background1))
				line.background_color = background1
			else
				line:SetBackdrop ({bgFile = [[Interface\AddOns\ACU\background]], tileSize = 64})
				line:SetBackdropColor (unpack (background2))
				line.background_color = background2
			end

			table_frame.lines [i] = line

			local index_string = line:CreateFontString (nil, "overlay", "GameFontHighlightSmall")
			local name_string = line:CreateFontString (nil, "overlay", "GameFontHighlightSmall")
			local total_usage_string = line:CreateFontString (nil, "overlay", "GameFontHighlightSmall")
			local total_psec_string = line:CreateFontString (nil, "overlay", "GameFontHighlightSmall")
			local total_percent_string = line:CreateFontString (nil, "overlay", "GameFontHighlightSmall")
			local peak_string = line:CreateFontString (nil, "overlay", "GameFontHighlightSmall")

			local icon = line:CreateTexture (nil, "overlay")
			icon:SetSize (16, 16)

			local graphic_checkbox = CreateFrame ("CheckButton", "ACUTableFrameLineCB" .. i, line, "ChatConfigCheckButtonTemplate")
			graphic_checkbox:SetScript ("OnClick", on_click_checkbox)
			graphic_checkbox:SetHitRectInsets (0, 0, 0, 0)
			graphic_checkbox:Hide()

			index_string:SetPoint ("left", line, "left", 2, 0)
			icon:SetPoint ("left", line, "left", 20, 0)
			name_string:SetPoint ("left", icon, "right", 2, 0)
			total_usage_string:SetPoint ("left", line, "left", 200, 0)
			total_psec_string:SetPoint ("left", line, "left", 300, 0)
			total_percent_string:SetPoint ("left", line, "left", 400, 0)
			peak_string:SetPoint ("left", line, "left", 500, 0)
			graphic_checkbox:SetPoint ("left", line, "left", 650, 0)

			line.index = index_string
			line.name = name_string
			line.icon = icon
			line.total_usage = total_usage_string
			line.total_psec = total_psec_string
			line.total_percent = total_percent_string
			line.peak = peak_string
			line.graphic_checkbox = graphic_checkbox
		end

		local update_line = function (t, line, data, index, total_time)
			line.index:SetText (index)

			local addon_name = data [1]
			if (data [4]) then
				line.icon:SetTexture (data [4])
			else
				line.icon:SetTexture (nil)
			end

			line.name:SetText (data [1])

			local psec = data [2] / total_time / 1000
			--local color = ACU:GetColor (psec)
			--local pcolor = ACU:GetPercentColor (psec)
			local milliseconds = psec * 1000

			if (ACU.RealTimeTick) then
				line.total_usage:SetText (format ("%.8f", data [2] / 1000) .. "|r")
			else
				line.total_usage:SetText (format ("%.2fs", data [2] / 1000) .. "|r")
			end

			if (ACU.RealTimeTick) then
				--line.total_psec:SetText (format ("%.10f", data [2]/total_time/1000))
				line.total_psec:SetText (format ("%.8f", milliseconds))
			else
				line.total_psec:SetText (format ("%.2f", milliseconds) .. "|r")
			end
			line.total_percent:SetText (format ("%.2f%%", data [2] / t.total_cpu_by_addons * 100) .. "|r")

			line.graphic_checkbox:SetChecked (t.showing [data [1]])
			line.graphic_checkbox.addon = data [1]
			line.graphic_checkbox:Show()

			--line.peak:SetText (format ("%.4fms", data[3].max_value / 1000))
			line.peak:SetText (format ("%.4fms", data[3].max_value))

			line:Show()
		end

		local refresh_table_frame = function (self)

			local t = ACU.DataPool [1]

			local offset = FauxScrollFrame_GetOffset (self)

			for name, dataobj in LibStub ("LibDataBroker-1.1"):DataObjectIterator() do
				for i, addon in ipairs (t) do
					if (addon[1] == name) then
						addon[4] = dataobj.icon
						break
					end
				end
			end

			for bar_index = 1, 16 do
				local line = table_frame.lines [bar_index]
				local data = t [offset + bar_index]
				if (data and data[2] > 0) then
					update_line (t, line, data, offset + bar_index, t.elapsed_time)
				else
					line:Hide()
				end
			end

			FauxScrollFrame_Update (self, #t, 16, 21)

		end

		local tfscroll = CreateFrame ("scrollframe", "ACUTableFrameScroll", table_frame, "FauxScrollFrameTemplate")
		tfscroll:SetPoint ("topleft", table_frame, "topleft")
		tfscroll:SetPoint ("bottomright", table_frame, "bottomright", -27, 0)
		tfscroll:SetScript ("OnVerticalScroll", function (self, offset) FauxScrollFrame_OnVerticalScroll (self, offset, 21, refresh_table_frame) end)
		tfscroll.Refresh = refresh_table_frame

		table_frame:Hide()

		local DF = _G.DetailsFramework
		if (DF) then
			DF:ReskinSlider(tfscroll)
			local statusBar = DF:CreateStatusBar(f)
			statusBar.text = statusBar:CreateFontString(nil, "overlay", "GameFontNormal")
			statusBar.text:SetPoint("left", statusBar, "left", 5, 0)
			statusBar.text:SetText("An addon by Terciob | Built with Details! Framework")
			DF:SetFontSize(statusBar.text, 11)
			DF:SetFontColor(statusBar.text, "gray")
			statusBar.text:SetText("An addon by Terciob")
		end

		--switch button
		local switch_frames = CreateFrame ("button", "ACUSwapFramesButton", f, BackdropTemplateMixin and "BackdropTemplate")
		switch_frames:SetBackdrop ({bgFile = [[Interface\AddOns\ACU\background]], tileSize = 64, edgeFile = [[Interface\AddOns\ACU\border_2]], edgeSize = 16, insets = {left = 1, right = 1, top = 1, bottom = 1}})
		switch_frames:SetBackdropColor (0, 0, 0, 0.4)
		switch_frames:SetBackdropBorderColor (1, 1, 1, 1)
		switch_frames:SetFrameLevel (f:GetFrameLevel()+10)
		switch_frames:SetPoint ("topright", f, "topright", -45, -15)
		switch_frames:SetSize (120, 16)
		switch_frames:SetScript ("OnClick", function (self, button)
			if (table_frame:IsShown()) then
				table_frame:Hide()
				chart:Show()
				self.text:SetText (Loc ["STRING_SWITCH_SHOWLIST"])
				ACU:UpdateChart()
			else
				table_frame:Show()
				chart:Hide()
				self.text:SetText (Loc ["STRING_SWITCH_SHOWGRAPHIC"])
				ACU:UpdateTableFrame()
			end
		end)

		local t = switch_frames:CreateFontString (nil, "overlay", "GameFontNormal")
		t:SetPoint ("center", switch_frames, "center")
		t:SetText (Loc ["STRING_SWITCH_SHOWLIST"])
		switch_frames.text = t

		--enable profiler button
		local profilerIcon = f:CreateTexture (nil, "overlay")
		profilerIcon:SetPoint ("bottomleft", f, "bottomleft", 10, 21)
		profilerIcon:SetTexture ([[Interface\DialogFrame\UI-Dialog-Icon-AlertNew]])
		profilerIcon:SetSize (16, 16)

		local profilerText = f:CreateFontString (nil, "overlay", "GameFontNormal")
		profilerText:SetPoint ("left", profilerIcon, "right", 5, -1)
		profilerText:SetJustifyH ("left")

		local cpuUsageText = f:CreateFontString (nil, "overlay", "GameFontNormal")
		cpuUsageText:SetPoint ("bottomleft", profilerIcon, "topright", 0, 0)
		cpuUsageText:SetJustifyH ("left")
		if (DetailsFramework) then
			DetailsFramework:SetFontSize(cpuUsageText, 10)
		end
		cpuUsageText:SetText (Loc ["STRING_RESULT_HELP"])

		f.profiler_icon = profilerIcon
		f.profiler_text = profilerText

		function ACU:ShowProfilerText(flag)
			if (flag) then
				f.profiler_icon:Show()
				f.profiler_text:Show()
			else
				f.profiler_icon:Hide()
				f.profiler_text:Hide()
			end
		end

		local enableDisableProfillerButton = CreateFrame("button", "ACUProfilerButton", f, BackdropTemplateMixin and "BackdropTemplate")
		enableDisableProfillerButton:SetBackdrop ({bgFile = [[Interface\AddOns\ACU\background]], tileSize = 64, edgeFile = [[Interface\AddOns\ACU\border_2]], edgeSize = 16, insets = {left = 1, right = 1, top = 1, bottom = 1}})
		enableDisableProfillerButton:SetBackdropColor (0, 0, 0, 0.4)
		enableDisableProfillerButton:SetBackdropBorderColor (1, 1, 1, 1)
		enableDisableProfillerButton:SetFrameLevel (f:GetFrameLevel()+10)
		enableDisableProfillerButton:SetPoint ("bottomright", f, "bottomright", -10, 2)
		enableDisableProfillerButton:SetSize (120, 16)
		enableDisableProfillerButton:SetScript ("OnClick", function (self, button)
			if (ACU:IsProfileEnabled()) then
				ACU:SetProfileEnabled (false)
				ReloadUI()
			else
				ACU:SetProfileEnabled(true)
				ReloadUI()
			end
		end)

		local enableRealTimeProfiling = CreateFrame("button", "ACUProfilerButton", f, BackdropTemplateMixin and "BackdropTemplate")
		enableRealTimeProfiling:SetBackdrop ({bgFile = [[Interface\AddOns\ACU\background]], tileSize = 64, edgeFile = [[Interface\AddOns\ACU\border_2]], edgeSize = 16, insets = {left = 1, right = 1, top = 1, bottom = 1}})
		enableRealTimeProfiling:SetBackdropColor (0, 0, 0, 0.4)
		enableRealTimeProfiling:SetBackdropBorderColor (1, 1, 1, 1)
		enableRealTimeProfiling:SetFrameLevel (f:GetFrameLevel()+10)
		enableRealTimeProfiling:SetPoint ("right", enableDisableProfillerButton, "left", -5, 0)
		enableRealTimeProfiling:SetSize (200, 16)
		enableRealTimeProfiling:SetScript ("OnClick", function (self, button)
			if (ACU:IsProfileEnabled()) then
				if (not ACU.RealTimeTick) then
					ACU:StartRealTime()
					ACU:Msg ("real time started")
				else
					ACU:StopRealTime()
					ACU:Msg (Loc ["STRING_REALTIME_DONE"])
				end
			else
				ACU:Msg (Loc ["STRING_PROFILING_NOT_ENABLED"])
			end
		end)

		local enableRealTimeProfilingText = enableRealTimeProfiling:CreateFontString (nil, "overlay", "GameFontNormal")
		enableRealTimeProfilingText:SetPoint ("center", enableRealTimeProfiling, "center")
		enableRealTimeProfilingText:SetText (Loc ["STRING_REALTIME_START"])


		--real time debug
		do
			local buttonScale = 1

			local resetRealTime = CreateFrame ("button", "ACUResetRealTimeButton", f, BackdropTemplateMixin and "BackdropTemplate")
			resetRealTime:SetPoint ("bottomleft", enableDisableProfillerButton, "topleft", -190, 2)
			resetRealTime:SetSize (100*buttonScale, 20*buttonScale)

			local resetRealTimeIcon = resetRealTime:CreateTexture (nil, "overlay")
			resetRealTimeIcon:SetTexture ([[Interface\BUTTONS\UI-RefreshButton]])
			resetRealTimeIcon:SetSize (14*buttonScale, 14*buttonScale)
			resetRealTimeIcon:SetPoint ("left", resetRealTime, "left", 2, 0)

			resetRealTime:SetScript ("OnClick", function()
				if (ACU:IsProfileEnabled()) then
					if (ACU.RealTimeTick) then
						ACU.StopRealTime()
						ACU:StartRealTime()
						ACU:Msg (Loc ["STRING_DATA_RESET"])
						return
					else
						--todo: add a msg here telling no realtime tick is ongoing
					end
				else
					ACU:Msg (Loc ["STRING_PROFILING_NOT_ENABLED"])
				end
			end)

			--create a fontstring to show the text within the button instead of the tooltip
			local resetRealTimeText = resetRealTime:CreateFontString(nil, "overlay", "GameFontNormal")
			resetRealTimeText:SetPoint("left", resetRealTimeIcon, "right", 5, 0)
			resetRealTimeText:SetText("Reset data")

			if (DetailsFramework) then
				DetailsFramework:ApplyStandardBackdrop(resetRealTime)
			end

			resetRealTime:SetScript ("OnEnter", function (self)
				GameTooltip:SetOwner (self, "ANCHOR_CURSOR")
				GameTooltip:AddLine ("reset data")
				GameTooltip:Show()
			end)
			resetRealTime:SetScript ("OnLeave", function (self)
				GameTooltip:Hide()
			end)

			resetRealTime:Hide()
			ACU.ResetRealTime = resetRealTime
			--
			local startRealTime = CreateFrame ("button", "ACUStartRealTimeButton", f, BackdropTemplateMixin and "BackdropTemplate")
			startRealTime:SetPoint ("left", resetRealTime, "right", 10, 0)
			startRealTime:SetSize (120*buttonScale, 20*buttonScale)

			local startRealTimeIcon = startRealTime:CreateTexture (nil, "overlay")
			startRealTimeIcon:SetTexture ([[Interface\BUTTONS\UI-SpellbookIcon-NextPage-Up]])
			startRealTimeIcon:SetSize (18*buttonScale, 18*buttonScale)
			startRealTimeIcon:SetPoint ("left", startRealTime, "left", 2, 0)

			startRealTime:SetScript ("OnClick", function()
				if (ACU:IsProfileEnabled()) then
					if (not ACU.RealTimeTick) then
						ACU:StartRealTime()
						ACU:Msg ("real time started")
						return
					else
						--todo: add a msg here telling real time is already ongoing
					end
				else
					ACU:Msg (Loc ["STRING_PROFILING_NOT_ENABLED"])
				end
			end)

			--create a fontstring to show the text within the button instead of the tooltip
			local startRealTimeText = startRealTime:CreateFontString(nil, "overlay", "GameFontNormal")
			startRealTimeText:SetPoint("left", startRealTimeIcon, "right", 5, 0)
			startRealTimeText:SetText("Start Real Time")

			if (DetailsFramework) then
				DetailsFramework:ApplyStandardBackdrop(startRealTime)
			end

			startRealTime:SetScript ("OnEnter", function (self)
				GameTooltip:SetOwner (self, "ANCHOR_CURSOR")
				GameTooltip:AddLine (Loc ["STRING_REALTIME_START"])
				GameTooltip:Show()
			end)
			startRealTime:SetScript ("OnLeave", function (self)
				GameTooltip:Hide()
			end)

			startRealTime:Hide()
			ACU.BeginRealTime = startRealTime
			--
			local stopRealTime = CreateFrame ("button", "ACUStopRealTimeButton", f, BackdropTemplateMixin and "BackdropTemplate")
			stopRealTime:SetPoint ("left", startRealTime, "right", 10, -1)
			stopRealTime:SetSize (100*buttonScale, 20*buttonScale)

			local stopRealTimeIcon = stopRealTime:CreateTexture (nil, "overlay")
			stopRealTimeIcon:SetTexture ([[Interface\BUTTONS\CancelButton-Up]])
			stopRealTimeIcon:SetSize (26*buttonScale, 26*buttonScale)
			stopRealTimeIcon:SetPoint ("left", stopRealTime, "left", 2, 0)

			stopRealTime:SetScript ("OnClick", function()
				if (ACU:IsProfileEnabled()) then
					if (ACU.RealTimeTick) then
						ACU:StopRealTime()
						ACU:Msg (Loc ["STRING_REALTIME_DONE"])
						return
					else
						--todo: add a msg here telling no real time is ongoing
					end
				else
					ACU:Msg (Loc ["STRING_PROFILING_NOT_ENABLED"])
				end
			end)

			--create a fontstring to show the text within the button instead of the tooltip
			local stopRealTimeText = stopRealTime:CreateFontString(nil, "overlay", "GameFontNormal")
			stopRealTimeText:SetPoint("left", stopRealTimeIcon, "right", 5, 0)
			stopRealTimeText:SetText("Stop")

			if (DetailsFramework) then
				DetailsFramework:ApplyStandardBackdrop(stopRealTime)
			end

			stopRealTime:SetScript ("OnEnter", function (self)
				GameTooltip:SetOwner (self, "ANCHOR_CURSOR")
				GameTooltip:AddLine (Loc ["STRING_REALTIME_STOP"])
				GameTooltip:Show()
			end)
			stopRealTime:SetScript ("OnLeave", function (self)
				GameTooltip:Hide()
			end)

			stopRealTime:Hide()
			ACU.EndRealTime = stopRealTime
		end

		local realtime_timer_string = f:CreateFontString (nil, "overlay", "GameFontNormal")
		realtime_timer_string:SetPoint ("right", enableDisableProfillerButton, "left", -10, 0)
		ACU.realtime_timer_string = realtime_timer_string

		local t = enableDisableProfillerButton:CreateFontString (nil, "overlay", "GameFontNormal")
		t:SetPoint ("center", enableDisableProfillerButton, "center")
		enableDisableProfillerButton.text = t

		-- on show events
		f:SetScript ("OnShow", function(self)
			if (ACU:IsProfileEnabled()) then
				profilerText:SetText (Loc ["STRING_PROFILE_ENABLED"])
				profilerText:SetTextColor (0.4, 1, 0.4)
				if (DetailsFramework) then
					DetailsFramework:SetFontSize(profilerText, 11)
				end
				enableDisableProfillerButton.text:SetText (Loc ["STRING_PROFILE_STOP"])

				if (table_frame:IsShown()) then
					ACU:UpdateTableFrame()
				elseif (chart:IsShown()) then
					ACU:UpdateChart()
				end
			else
				profilerText:SetText (Loc ["STRING_PROFILE_DISABLED"])
				profilerText:SetTextColor (1, 0.4, 0.4)
				enableDisableProfillerButton.text:SetText (Loc ["STRING_PROFILE_START"])

				if (table_frame:IsShown()) then
					ACU:UpdateTableFrame()
				elseif (chart:IsShown()) then
					ACU:UpdateChart()
				end
			end
		end)

		--tutorial
		local got_tutorial = ACU.db.profile.first_run
		if (not got_tutorial) then
			local t = CreateFrame ("frame", "ACUProfilerTutorial", f, BackdropTemplateMixin and "BackdropTemplate")
			t:SetSize (500, 300)
			t:SetPoint ("center", f, "center")
			t:SetFrameLevel (f:GetFrameLevel()+15)
			t:SetBackdrop ({bgFile = [[Interface\AddOns\ACU\background]], tileSize = 64, edgeFile = [[Interface\AddOns\ACU\border_2]], edgeSize = 16, insets = {left = 1, right = 1, top = 1, bottom = 1}})
			t:SetBackdropColor (0, 0, 0, 0.85)

			local title_text = t:CreateFontString (nil, "overlay", "GameFontHighlightHuge")
			title_text:SetPoint ("topleft", t, "topleft", 10, -10)
			title_text:SetText ("How to use:")
			title_text:SetTextColor (1, 1, 0)
			local desc_text = t:CreateFontString (nil, "overlay", "GameFontNormal")
			desc_text:SetPoint ("topleft", t, "topleft", 10, -45)
			desc_text:SetJustifyH ("left")
			desc_text:SetWidth (480)
			--title_text:SetTextColor (1, 1, 0)

			local l = ""
			for _, phrase in ipairs (tutorial_phrases) do
				l = l .. phrase .. "\n\n"
			end
			desc_text:SetText (l)

			local close = CreateFrame ("button", "ACUProfilerTutorialClose", t, BackdropTemplateMixin and "BackdropTemplate")
			close:SetBackdrop ({bgFile = [[Interface\AddOns\ACU\background]], tileSize = 64, edgeFile = [[Interface\AddOns\ACU\border_2]], edgeSize = 16, insets = {left = 1, right = 1, top = 1, bottom = 1}})
			close:SetBackdropColor (0, 0, 0, 0.4)
			close:SetBackdropBorderColor (1, 1, 1, 1)
			close:SetFrameLevel (t:GetFrameLevel()+1)
			close:SetPoint ("bottomleft", t, "bottomleft", 10, 5)
			close:SetSize (120, 16)
			close:SetScript ("OnClick", function (self, button)
				t:Hide()
			end)
			local close_text = close:CreateFontString (nil, "overlay", "GameFontNormal")
			close_text:SetPoint ("center", close, "center")
			close_text:SetText (Loc ["STRING_CLOSE"])

			local cb = CreateFrame ("CheckButton", "ACUProfilerTutorialCheckBox", t, "ChatConfigCheckButtonTemplate")
			cb:SetScript ("OnClick", function (self)
				if (self:GetChecked()) then
					ACU.db.profile.first_run = true
				else
					ACU.db.profile.first_run = false
				end
			end)
			cb:SetPoint ("left", close, "right", 10, 0)
			ACUProfilerTutorialCheckBoxText:SetText (Loc ["STRING_HELP_DONTSHOWAGAIN"])
			cb:SetHitRectInsets (0, -200, 0, 0)

			ACU:Msg ("AddOn Authors: you may use /cpu realtime to measure your addons at real time.")
		end

		--

		table_frame:Show()
		chart:Hide()
		switch_frames.text:SetText (Loc ["STRING_SWITCH_SHOWGRAPHIC"])

		f:Hide()
		f:Show()
	end

	-- ~capture
		local on_capturing_screen = CreateFrame ("frame", "ACUProfilerCaptureScreen", UIParent, BackdropTemplateMixin and "BackdropTemplate")
		on_capturing_screen:Hide()
		on_capturing_screen:SetFrameStrata ("TOOLTIP")
		on_capturing_screen:SetSize (205, 65)
		on_capturing_screen:SetBackdrop ({bgFile = [[Interface\AddOns\ACU\background]], tileSize = 64, edgeFile = [[Interface\AddOns\ACU\border_2]], edgeSize = 16, insets = {left = 1, right = 1, top = 1, bottom = 1}})
		on_capturing_screen:SetBackdropColor (0, 0, 0, 0.4)
		on_capturing_screen:SetPoint ("bottomleft", UIParent, "bottomleft", 1, 200)

		local icon = on_capturing_screen:CreateTexture (nil, "overlay")
		icon:SetTexture ([[Interface\AddOns\ACU\icon]])
		icon:SetSize (16, 16)
		icon:SetPoint ("topleft", on_capturing_screen, "topleft", 10, -10)
		local title = on_capturing_screen:CreateFontString (nil, "overlay", "GameFontNormal")
		title:SetText (Loc ["STRING_CAPTURING_CPU"])
		title:SetPoint ("left", icon, "right", 6, 0)

		local statusbar = CreateFrame ("statusbar", "ACUProfilerCaptureScreenStatusbar", on_capturing_screen, BackdropTemplateMixin and "BackdropTemplate")
		statusbar:SetPoint ("bottomleft", on_capturing_screen, "bottomleft", 10, 2)
		statusbar:SetPoint ("bottomright", on_capturing_screen, "bottomright", -10, 2)
		statusbar:SetHeight (14)
		statusbar:SetMinMaxValues (0, 100)
		statusbar:SetValue (40)

		local sparkTexture = statusbar:CreateTexture (nil, "overlay")
		sparkTexture:SetTexture ([[Interface\CastingBar\UI-CastingBar-Spark]])
		sparkTexture:SetBlendMode ("ADD")
		statusbar.spark = sparkTexture

		local bg = statusbar:CreateTexture (nil, "background")
		bg:SetAllPoints()
		bg:SetColorTexture (0, 0, 0, 0.4)

		local percentString = statusbar:CreateFontString (nil, "overlay", "GameFontNormal")
		percentString:SetPoint ("right", statusbar, "right", -2, 0)
		percentString:SetText ("40%")

		statusbar.texture = statusbar:CreateTexture (nil, "overlay")
		statusbar.texture:SetTexture ([[Interface\AddOns\ACU\bar_skyline]])
		statusbar:SetStatusBarTexture (statusbar.texture)
		on_capturing_screen.statusbar = statusbar
		on_capturing_screen.percent = percentString

		local notIntended = on_capturing_screen:CreateFontString (nil, "overlay", "GameFontHighlightSmall")
		notIntended:SetText (Loc ["STRING_NO_INTENDED"])
		notIntended:SetPoint ("center", statusbar, "center", 0, 0)
		notIntended:SetPoint ("bottom", statusbar, "top", 0, 6)
		local disable_profiler = CreateFrame ("button", "ACUProfilerCaptureScreenStopProfilerButton", on_capturing_screen, BackdropTemplateMixin and "BackdropTemplate")
		disable_profiler:SetPoint ("topleft", notIntended, "topleft")
		disable_profiler:SetPoint ("bottomright", notIntended, "bottomright")
		disable_profiler:SetScript ("OnClick", function()
			ACU:SetProfileEnabled (false)
		end)

		ACU.capture_panel = on_capturing_screen
	--

	function ACU:UpdateTotalIndicators()
		local total = ACU.DataPool [1].total_cpu_by_addons / 1000
		ACU.totalusage2:SetText (format ("%.2fs", total)) -- .. " (" .. format ("%.1f", total / ACU.DataPool [1].elapsed_time * 100) .. "%)"
		local average = ACU.DataPool [1].total_cpu_by_addons / ACU.DataPool [1].elapsed_time
		ACU.averageusage2:SetText (format ("%.2fms", average))
		ACU.fpsloss2:SetText (format ("%.2ffps", average/16.6))
	end

	local real_time_table
	local do_realtime_tick = function()

		UpdateAddOnCPUUsage()

		-- calc addons cpu usage
		local total_usage = 0

		for name, addon in pairs (real_time_table.addons) do

			local cpu = GetAddOnCPUUsage (name)
			local diff = cpu - addon.last_value

			addon [#addon+1] = diff
			addon.last_value = cpu
			addon.total = cpu

			total_usage = total_usage + diff

			if (diff > addon.max_value) then
				addon.max_value = diff
			end
		end

		--ACU.CurrentEncounter.total = ACU.CurrentEncounter.total + total_usage

		real_time_table.total_cpu_by_addons = real_time_table.total_cpu_by_addons + total_usage
		real_time_table.elapsed_time = real_time_table.elapsed_time + 1

		local t = {}

		local addons = real_time_table.addons
		local ordered = {}
		for name, addon in pairs (addons) do
			ordered [#ordered+1] = {name, addon.total, addon}
		end
		table.sort (ordered, sort_func)
		ordered.elapsed_time = real_time_table.elapsed_time

		ordered.showing = {}
		for i = 1, min (#ordered, 3) do
			ordered.showing [ordered[i][1]] = true
		end

		ordered.total_cpu_by_addons = real_time_table.total_cpu_by_addons
		ordered.cpu_time = 0
		ordered.addons_time = 0

		ACU.DataPool [1] = ordered
		ACU:UpdateTableFrame()

		if (ACU.RealTimeTimer) then
			ACU.realtime_timer_string:SetText (floor (ACU.RealTimeTimer.FinishesAt - GetTime()))
		end
	end
	function ACU:StartRealTime (amount_of_time)
		real_time_table = {}
		real_time_table.addons = {}
		real_time_table.total = 0
		real_time_table.start = GetTime()
		real_time_table.total_cpu_by_addons = 0
		real_time_table.elapsed_time = 0
		UpdateAddOnCPUUsage()

		local addons = real_time_table.addons
		local total_addons = GetNumAddOns()

		for i = 1, total_addons do
			local name, title, notes, loadable, reason, security, newVersion = GetAddOnInfo (i)
			if (GetAddOnCPUUsage (name) > 0 and name ~= "ACU") then
				addons [name] = {max_value = 0, total = 0, last_value = 0, index = i}
			end
		end

		if (not ACUMainFrame) then
			ACU:CreateMainWindow()
		else
			ACUMainFrame:Show()
		end

		CPUResetUsage()

		if (ACU.RealTimeTimer) then
			ACU.RealTimeTimer:Cancel()
		end
		if (ACU.RealTimeTick) then
			ACU.RealTimeTick:Cancel()
		end

		ACU.RealTimeTick = C_Timer.NewTicker (1, do_realtime_tick)
		ACU.RealTimeTimer = nil

		if (amount_of_time) then
			ACU.RealTimeTimer = C_Timer.NewTimer (amount_of_time, ACU.StopRealTime)
			ACU.RealTimeTimer.TotalTime = amount_of_time
			ACU.RealTimeTimer.FinishesAt = GetTime() + amount_of_time
		end

		--show control buttons
		ACU.ResetRealTime:Show()
		ACU.BeginRealTime:Show()
		ACU.EndRealTime:Show()

	end

	function ACU:UpdateTableFrame()

		local t = ACU.DataPool [1]
		if (not t) then
			return
		end

		ACUTableFrameScroll.Refresh (ACUTableFrameScroll)
		ACU:UpdateTotalIndicators()
	end

	local colors = {
		{1, 1, 1}, --white
		{1, 0.8, .4}, --orange
		{.4, 1, .4}, --green
		{1, .4, .4}, --red
		{.4, .4, 1}, --blue
		{.5, 1, 1}, --cyan
		{1, 0.75, 0.79}, --pink
		{0.98, 0.50, 0.44}, --salmon
		{0.75, 0.75, 0.75}, --silver
		{0.60, 0.80, 0.19}, --yellow
		{1, .4, 1}, --magenta
	}
	local default_color = {1, 1, 1}

	function ACU:UpdateChart()

		local t = ACU.DataPool [1]
		if (not t) then
			return
		end

		local elapsed_time = t.elapsed_time

		ACUChartFrame:Reset()

		local i = 1
		for index, addon in ipairs (t) do
			if (t.showing [addon [1]]) then
				ACUChartFrame:AddLine (addon[3], colors [i] or default_color, addon [1], elapsed_time, nil, "SMA")
				i = i + 1
			end
		end

		ACU:UpdateTotalIndicators()
	end

	--> if an addon uses a total of %amt percent
	function ACU:GetPercentColor (amt)
		if (amt >= 10) then
			return "|cFFa31313"
		elseif (amt >= 8) then
			return "|cFFff9c00"
		elseif (amt >= 7) then
			return "|cFFfff000"
		elseif (amt >= 6) then
			return "|cFFd8ff00"
		elseif (amt >= 5) then
			return "|cFFa2ff00"
		elseif (amt >= 4) then
			return "|cFF36ff00"
		else
			return "|cFFc7c7c7"
		end
	end

	function ACU:GetColor (amt)
		if (amt >= 0.016) then
			return "|cFFa31313"
		elseif (amt >= 0.012) then
			return "|cFFff9c00"
		elseif (amt >= 0.009) then
			return "|cFFfff000"
		elseif (amt >= 0.006) then
			return "|cFFd8ff00"
		elseif (amt >= 0.004) then
			return "|cFFa2ff00"
		elseif (amt >= 0.002) then
			return "|cFF36ff00"
		else
			return "|cFFc7c7c7"
		end
	end

--> stop auto complate: endd doe
