-- VERSÃO FINAL - LIMPA E FUNCIONAL
ClickMorph = {}
CM = ClickMorph
CM.isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
CM.project = CM.isRetail and "Live" or "Classic"
local FileData

-- inventory type -> equipment slot -> slot name
CM.SlotNames = {
	[INVSLOT_HEAD] = "head", -- 1
	[INVSLOT_SHOULDER] = "shoulder", -- 3
	[INVSLOT_BODY] = "shirt", -- 4
	[INVSLOT_CHEST] = "chest", -- 5
	[INVSLOT_WAIST] = "belt", -- 6
	[INVSLOT_LEGS] = "legs", -- 7
	[INVSLOT_FEET] = "feet", -- 8
	[INVSLOT_WRIST] = "wrist", -- 9
	[INVSLOT_HAND] = "hands", -- 10
	[INVSLOT_BACK] = "cloak", -- 15
	[INVSLOT_MAINHAND] = "mainhand", -- 16
	[INVSLOT_OFFHAND] = "offhand", -- 17
	[INVSLOT_RANGED] = "ranged", -- 18
	[INVSLOT_TABARD] = "tabard", -- 19
}

local InvTypeToSlot = {
	INVTYPE_HEAD = INVSLOT_HEAD, -- 1
	INVTYPE_SHOULDER = INVSLOT_SHOULDER, -- 3
	INVTYPE_BODY = INVSLOT_BODY, -- 4
	INVTYPE_CHEST = INVSLOT_CHEST, -- 5
	INVTYPE_ROBE = INVSLOT_CHEST, -- 5 (cloth)
	INVTYPE_WAIST = INVSLOT_WAIST, -- 6
	INVTYPE_LEGS = INVSLOT_LEGS, -- 7
	INVTYPE_FEET = INVSLOT_FEET, -- 8
	INVTYPE_WRIST = INVSLOT_WRIST, -- 9
	INVTYPE_HAND = INVSLOT_HAND, -- 10
	INVTYPE_CLOAK = INVSLOT_BACK, -- 15
	INVTYPE_2HWEAPON = INVSLOT_MAINHAND, -- 16
	INVTYPE_WEAPON = INVSLOT_MAINHAND, -- 16
	INVTYPE_WEAPONMAINHAND = INVSLOT_MAINHAND, -- 16
	INVTYPE_WEAPONOFFHAND = INVSLOT_OFFHAND, -- 17
	INVTYPE_HOLDABLE = INVSLOT_OFFHAND, -- 17
	INVTYPE_RANGED = INVSLOT_RANGED, -- 18
	INVTYPE_THROWN = INVSLOT_RANGED, -- 18
	INVTYPE_RANGEDRIGHT = INVSLOT_RANGED, -- 18
	INVTYPE_SHIELD = INVSLOT_OFFHAND, -- 17
	INVTYPE_TABARD = INVSLOT_TABARD, -- 19
}

local GearSlots = {
	INVSLOT_HEAD, INVSLOT_SHOULDER, INVSLOT_BODY, INVSLOT_CHEST, INVSLOT_WAIST,
	INVSLOT_LEGS, INVSLOT_FEET, INVSLOT_WRIST, INVSLOT_HAND, INVSLOT_BACK, INVSLOT_TABARD
}

local lastWeaponSlot = INVSLOT_OFFHAND
local DualWieldSlot = {
	[INVSLOT_MAINHAND] = INVSLOT_OFFHAND,
	[INVSLOT_OFFHAND] = INVSLOT_MAINHAND,
}

-- Função para prints condicionais (respeita silent mode)
function CM:PrintChat(msg, r, g, b)
	local silentMode = ClickMorphCommands and ClickMorphCommands.config and ClickMorphCommands.config.silentMode
	if not silentMode and (not ClickMorphDB or not ClickMorphDB.silent) then
		DEFAULT_CHAT_FRAME:AddMessage(format("|cff7fff00ClickMorph|r: |r%s", msg), r, g, b)
	end
end

function CM:GetFileData(frame)
	if not FileData then
		local addon = "ClickMorphData"
		local loaded, reason = LoadAddOn(addon)
		if not loaded then
			if reason == "DISABLED" then
				EnableAddOn(addon, true)
				LoadAddOn(addon)
			else
				if frame then
					frame:SetScript("OnUpdate", nil)
				end
				self:PrintChat("The ClickMorphData folder could not be found. Using basic functionality.", 1, 1, 0)
				FileData = {
					Live = { ItemAppearance = {}, ItemVisuals = {} },
					Classic = { ItemSet = {}, Mount = {}, Npc = {} }
				}
				return FileData
			end
		end
		FileData = _G[addon]
	end
	return FileData
end

function CM:CanMorph(override)
	if IsAltKeyDown() or override then
		for _, morpher in pairs(self.morphers) do
			if morpher.loaded() then
				return morpher
			end
		end
		local name = "iMorph"
		self:PrintChat("Could not find |cffFFFF00"..name.."|r. Make sure iMorph is loaded and injected.", 1, 1, 0)
	end
end

function CM:CanMorphMount()
	local isMounted = IsMounted()
	local onTaxi = UnitOnTaxi("player")
	if isMounted and not onTaxi then
		return true
	else
		if onTaxi then
			CM:PrintChat("You need to be not on a flight path", 1, 1, 0)
		elseif not isMounted then
			CM:PrintChat("You need to be mounted", 1, 1, 0)
		end
	end
end

CM.morphers = {
	iMorph = {
		loaded = function() return IMorphInfo end,
		reset = function()
			if iMorphFrame then iMorphFrame:Reset() end
			if ClickMorph_iMorphV1 then wipe(ClickMorph_iMorphV1) end
		end,
		model = function(_, displayID)
			if Morph then Morph(displayID) end
		end,
		race = function(_, raceID, genderID)
			if SetRace then SetRace(raceID, genderID) end
		end,
		enchant = function(_, slotID, visualID)
			if SetEnchant then 
				local command = string.format("enchant %d %d", slotID, visualID)
				ChatFrame1EditBox:SetText("." .. command)
				ChatEdit_SendText(ChatFrame1EditBox, 0)
			end
		end,
		mount = function(_, displayID)
			if CM:CanMorphMount() and SetMount then
				SetMount(displayID)
				return true
			end
		end,
		item = function(_, slotID, itemID, itemModID)
			if SetItem then
				if itemModID and itemModID > 0 then
					-- Usar itemModID real do WoW (156, 158, 160, etc.)
					SetItem(slotID, itemID, itemModID)
				else
					-- Comando simples sem modifier
					SetItem(slotID, itemID)
				end
			end
		end,
		scale = function(_, value)
			if SetScale then
				SetScale(value)
				if ClickMorph_iMorphV1 then
					ClickMorph_iMorphV1.tempscale = value
				end
			end
		end,
	},
}

function CM:ResetMorph()
	local morph = self:CanMorph(true)
	if morph and morph.reset then
		morph.reset()
	end
end

function CM:Undress(unit)
	local morph = self:CanMorph(true)
	if morph and morph.item then
		for _, invSlot in pairs(GearSlots) do
			morph.item(unit, invSlot, 0)
		end
	end
end

function CM:GetItemInfo(item)
	if type(item) == "string" then
		local itemID = tonumber(item:match("item:(%d+)"))
		local equipLoc = select(9, GetItemInfo(itemID))
		return itemID, item, equipLoc
	else
		local itemLink, _, _, _, _, _, _, equipLoc = select(2, GetItemInfo(item))
		return item, itemLink, equipLoc
	end
end

function CM:GetDualWieldSlot(slot)
	if DualWieldSlot[slot] and IsDualWielding() then
		lastWeaponSlot = DualWieldSlot[lastWeaponSlot]
		return lastWeaponSlot
	else
		return slot
	end
end

local function IsLooting()
	if ElvLootSlot1 then
		return ElvLootSlot1:IsShown()
	else
		return LootFrame:IsShown()
	end
end

function CM:MorphItem(unit, item, silent)
	local morph = CM:CanMorph()
	if item and morph and morph.item and not IsLooting() then
		-- Verificação de segurança
		local success, itemID, itemLink, equipLoc = pcall(CM.GetItemInfo, CM, item)
		if not success or not itemID then
			return -- Sai silenciosamente se não conseguir processar o item
		end
		
		local slotID = InvTypeToSlot[equipLoc]
		if slotID then
			slotID = CM:GetDualWieldSlot(slotID)
			morph.item(unit, slotID, itemID)
			if not silent and not WardrobeCollectionFrame:IsShown() then
				CM:PrintChat(format("%s -> %d %s", CM.SlotNames[slotID], itemID, itemLink))
			end
		end
	end
end

-- Hook para bags (Alt+Shift+Click)
hooksecurefunc("HandleModifiedItemClick", function(item)
	if IsShiftKeyDown() then
		CM:MorphItem("player", item)
	end
end)

-- Mounts
function CM:MorphMount(unit, mountID)
	local morph = self:CanMorph(true)
	if morph and morph.mount then
		local mountName, spellID, icon = C_MountJournal.GetMountInfoByID(mountID)
		local displayID = C_MountJournal.GetMountInfoExtraByID(mountID)
		if not displayID then
			local multipleIDs = C_MountJournal.GetMountAllCreatureDisplayInfoByID(mountID)
			if multipleIDs and #multipleIDs > 0 then
				displayID = multipleIDs[math.random(#multipleIDs)].creatureDisplayID
			end
		end
		
		if displayID then
			morph.mount(unit, displayID)
			
			-- GetSpellLink seguro para WoW 11.x, com fallback para nome da montaria
			local spellLink
			local success, result = pcall(GetSpellLink, spellID)
			if success and result then
				spellLink = result
			elseif mountName then
				spellLink = mountName
			else
				spellLink = "Mount ID: " .. mountID
			end
			
			CM:PrintChat(format("mount -> %d %s", displayID, spellLink))
		else
			CM:PrintChat("Failed to morph mount - no display ID found", 1, 1, 0)
		end
	end
end

function CM.MorphMountModelScene()
	local mountID = MountJournal.selectedMountID
	if mountID then
		CM:MorphMount("player", mountID)
	end
end

function CM.MorphMountScrollFrame(frame)
	if frame.index then
		local mountID = select(12, C_MountJournal.GetDisplayedMountInfo(frame.index))
		if mountID then
			CM:MorphMount("player", mountID)
		end
	end
end

-- Sets
function CM.MorphTransmogSet()
	local morph = CM:CanMorph()
	if morph and morph.item then
		local setID = WardrobeCollectionFrame.SetsCollectionFrame.selectedSetID
		if not setID then
			CM:PrintChat("No set selected", 1, 1, 0)
			return
		end
		
		local setInfo = C_TransmogSets.GetSetInfo(setID)
		if not setInfo then
			CM:PrintChat("Could not get set info", 1, 1, 0)
			return
		end

		local sourceIDs = C_TransmogSets.GetAllSourceIDs(setID)
		if sourceIDs then
			-- Undress inteligente
			local slotsToUndress = {}
			for _, sourceID in pairs(sourceIDs) do
				local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID)
				if sourceInfo and sourceInfo.itemID then
					local slotID = C_Transmog.GetSlotForInventoryType(sourceInfo.invType)
					if slotID then
						slotsToUndress[slotID] = true
					end
				end
			end
			
			local morphForUndress = CM:CanMorph(true)
			if morphForUndress and morphForUndress.item then
				for slotID in pairs(slotsToUndress) do
					morphForUndress.item("player", slotID, 0)
				end
			end
			
			-- Aplicar conjunto com ModIDs corretos
			for _, sourceID in pairs(sourceIDs) do
				local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID)
				if sourceInfo and sourceInfo.itemID then
					local slotID = C_Transmog.GetSlotForInventoryType(sourceInfo.invType)
					if slotID then
						local itemModID = sourceInfo.itemModID or 0
						morph.item("player", slotID, sourceInfo.itemID, itemModID)
					end
				end
			end
			
			-- Print melhorado
			local description = setInfo.description or "Normal"
			CM:PrintChat(format("set -> %s (%s)", setInfo.name, description))
		else
			CM:PrintChat("Could not get set sources", 1, 1, 0)
		end
	end
end

-- Individual transmog items with variant detection
function CM.MorphTransmogItem(frame)
	local loc = WardrobeCollectionFrame.ItemsCollectionFrame.transmogLocation
	local visualID = frame.visualInfo.visualID

	if loc:IsAppearance() then
		local sources = C_TransmogCollection.GetAllAppearanceSources(visualID)
		
		if sources and #sources > 0 then
			local sourceInfo = C_TransmogCollection.GetSourceInfo(sources[1])
			if sourceInfo then
				local itemID = sourceInfo.itemID
				local itemModID = sourceInfo.itemModID or 0
				
				local morph = CM:CanMorph()
				if morph and morph.item then
					local slotID = C_Transmog.GetSlotForInventoryType(sourceInfo.invType)
					if slotID then
						slotID = CM:GetDualWieldSlot(slotID)
						
						morph.item("player", slotID, itemID, itemModID)
						
						if itemModID > 0 then
							CM:PrintChat(format("%s -> %d:%d %s", 
								CM.SlotNames[slotID], itemID, itemModID, sourceInfo.name))
						else
							CM:PrintChat(format("%s -> %d %s", 
								CM.SlotNames[slotID], itemID, sourceInfo.name))
						end
					end
				end
			end
		end
	elseif loc:IsIllusion() then
		local slotToName = {
			[16] = "MainHandSlot",
			[17] = "SecondaryHandSlot"
		}
		
		local slotName = slotToName[loc.slotID]
		if slotName then
			local slotID = GetInventorySlotInfo(slotName)
			local enchantSlot = (slotID == 16) and 1 or 2
			
			local morph = CM:CanMorph()
			if morph and morph.enchant then
				morph.enchant("player", enchantSlot, visualID)
				local enchantName = C_TransmogCollection.GetIllusionStrings(frame.visualInfo.sourceID)
				if enchantName then
					-- Extrair só o nome antes do [
					enchantName = enchantName:match("([^%[]+)") or enchantName
					CM:PrintChat(format("enchant -> %s", enchantName))
				else
					CM:PrintChat(format("enchant -> applied (visual %d)", visualID))
				end
			end
		else
			CM:PrintChat("Unsupported enchant slot: " .. tostring(loc.slotID))
		end
	end
end

-- Hooks initialization - com prevenção de hooks duplos
local hooksInitialized = false
local function InitializeHooks()
	if hooksInitialized then
		return -- Previne hooks duplos
	end
	hooksInitialized = true
	-- Mount Journal hooks (Alt+Shift) - com verificação robusta para WoW 11.x
	if MountJournal then
		local mountHooksSuccess = true
		
		-- Hook do ModelScene
		if MountJournal.MountDisplay and MountJournal.MountDisplay.ModelScene then
			MountJournal.MountDisplay.ModelScene:HookScript("OnMouseUp", function(self, button)
				if button == "LeftButton" and IsAltKeyDown() and IsShiftKeyDown() then
					CM.MorphMountModelScene()
				end
			end)
		else
			mountHooksSuccess = false
		end
		
		-- Hook dos botões de lista - com verificação mais robusta
		local listFrame = MountJournal.ListScrollFrame or MountJournal.scrollFrame
		if listFrame then
			-- Tentar diferentes estruturas para WoW 11.x
			local buttons = listFrame.buttons or listFrame.Buttons or listFrame.ScrollTarget and listFrame.ScrollTarget.buttons
			
			if buttons then
				for _, button in pairs(buttons) do
					if button and button.HookScript then
						button:HookScript("OnClick", function(self, btn)
							if btn == "LeftButton" and IsAltKeyDown() and IsShiftKeyDown() then
								CM.MorphMountScrollFrame(self)
							end
						end)
					end
				end
			else
				-- Fallback para nova estrutura do WoW 11.x
				mountHooksSuccess = false
			end
		else
			mountHooksSuccess = false
		end
		
		if mountHooksSuccess then
			CM:PrintChat("Mount Journal hooks initialized (Alt+Shift)")
		else
			-- Warning apenas se não conseguir nenhum hook
			if not (MountJournal.MountDisplay and MountJournal.MountDisplay.ModelScene) then
				CM:PrintChat("Mount Journal: Using basic functionality (some UI changes in WoW 11.x)", 1, 1, 0)
			else
				CM:PrintChat("Mount Journal hooks initialized with basic functionality")
			end
		end
	end
	
	-- Wardrobe Set hooks (Alt+Shift)
	if WardrobeCollectionFrame and WardrobeCollectionFrame.SetsCollectionFrame then
		local setsFrame = WardrobeCollectionFrame.SetsCollectionFrame
		
		if setsFrame.Model then
			setsFrame.Model:HookScript("OnMouseUp", function(self, button)
				if button == "LeftButton" and IsAltKeyDown() and IsShiftKeyDown() then
					CM.MorphTransmogSet()
				end
			end)
		end
		
		CM:PrintChat("Wardrobe Sets hooks initialized (Alt+Shift)")
	end
	
	-- Wardrobe individual items hooks (Alt+Shift)
	if WardrobeCollectionFrame and WardrobeCollectionFrame.ItemsCollectionFrame then
		local itemsFrame = WardrobeCollectionFrame.ItemsCollectionFrame
		
		if itemsFrame.Models then
			for _, model in pairs(itemsFrame.Models) do
				if model then
					model:HookScript("OnMouseUp", function(self, button)
						if button == "LeftButton" and IsAltKeyDown() and IsShiftKeyDown() then
							CM.MorphTransmogItem(self)
						end
					end)
				end
			end
		end
		
		CM:PrintChat("Wardrobe Items hooks initialized (Alt+Shift)")
	end
	
	CM:PrintChat("All hooks standardized to Alt+Shift+Click")
end

-- Debug system
function CM:Debug()
	self:PrintChat("=== ClickMorph Debug ===")
	self:PrintChat("Version: WoW 11.x Compatible - All Alt+Shift+Click")
	self:PrintChat("Project: " .. self.project)
	self:PrintChat("IsRetail: " .. tostring(self.isRetail))
	
	for name, morpher in pairs(self.morphers) do
		local status = morpher.loaded() and "[OK] LOADED" or "[FAIL] NOT LOADED"
		self:PrintChat("Morpher " .. name .. ": " .. status)
	end
	
	local uis = {
		["MountJournal"] = MountJournal,
		["WardrobeCollectionFrame"] = WardrobeCollectionFrame,
		["Collections"] = C_AddOns.IsAddOnLoaded("Blizzard_Collections")
	}
	
	for name, obj in pairs(uis) do
		local status = obj and "[OK] AVAILABLE" or "[FAIL] NOT AVAILABLE"
		self:PrintChat("UI " .. name .. ": " .. status)
	end
	
	local morpher = self:CanMorph(true)
	if morpher then
		self:PrintChat("[OK] Ready to morph!")
	else
		self:PrintChat("[FAIL] No morpher found - load iMorph first")
	end
	
	-- Debug silent mode
	local silentMode = ClickMorphCommands and ClickMorphCommands.config and ClickMorphCommands.config.silentMode
	self:PrintChat("Silent Mode: " .. (silentMode and "ON" or "OFF"))
end

-- Commands
SLASH_CLICKMORPH_DEBUG1 = "/cmdebug"
SlashCmdList.CLICKMORPH_DEBUG = function()
	CM:Debug()
end

-- Initialization frame
local mainFrame = CreateFrame("Frame")
mainFrame:RegisterEvent("ADDON_LOADED")
mainFrame:SetScript("OnEvent", function(self, event, addonName)
	if addonName == "ClickMorph" then
		CM:PrintChat("Loaded! All functions use Alt+Shift+Click. Use /cmdebug to check status.")
	elseif addonName == "Blizzard_Collections" then
		if not hooksInitialized then
			C_Timer.After(0.5, InitializeHooks)
		end
		self:UnregisterEvent(event)
	end
end)

-- Fallback initialization - apenas se ainda não inicializou
C_Timer.After(2, function()
	if C_AddOns.IsAddOnLoaded("Blizzard_Collections") and not hooksInitialized then
		InitializeHooks()
	end
end)