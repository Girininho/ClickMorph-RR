local CM = ClickMorph
if not CM.isRetail then return end

local f = CreateFrame("Frame")
local active


function f:InitMountJournal()
	-- Aguardar carregamento completo com verificação robusta
	if not MountJournal then
		C_Timer.After(0.5, function() self:InitMountJournal() end)
		return
	end
	
	-- only load once the mounts tab is opened
	MountJournal:HookScript("OnShow", function(frame)
		if active then
			return
		end
		active = true
		
		-- Verificações robustas para WoW 11.x
		--local success = true
		
		-- Verificar e criar hook do ModelScene
		--if MountJournal.MountDisplay and MountJournal.MountDisplay.ModelScene then
			--pcall(function()
				--MountJournal.MountDisplay.ModelScene:HookScript("OnMouseUp", CM.MorphMountModelScene)
			--end)
		--else
			--print("|cffFFFF00ClickMorph:|r Warning - MountDisplay.ModelScene not found")
			--success = false
		--end
		
		-- Verificar e criar hooks dos botões do ScrollFrame
		--if MountJournal.ListScrollFrame and MountJournal.ListScrollFrame.buttons then
			--for i, button in pairs(MountJournal.ListScrollFrame.buttons) do
				--if button and button.HookScript then
					--pcall(function()
						--button:HookScript("OnClick", CM.MorphMountScrollFrame)
					--end)
				--end
			--end
		--else
			--print("|cffFFFF00ClickMorph:|r Warning - ListScrollFrame.buttons not found")
			--success = false
		--end
		
		--self:CreateUnlockButton()
		
		--if success then
			--CM:PrintChat("Mount Journal hooks initialized successfully!")
		--else
			--CM:PrintChat("Mount Journal hooks had some issues - check debug", 1, 1, 0)
		--end
	end)
end

--function f:CreateUnlockButton()
	--local btn = CreateFrame("Button", nil, MountJournal, "UIPanelButtonTemplate")
	--btn:SetPoint("LEFT", MountJournal.MountCount, "RIGHT", 5, 0) -- topleft corner of the frame
	--btn:SetWidth(100)
	--btn:SetText(UNLOCK)
	--btn:SetScript("OnClick", function(frame)
		--self:UnlockMounts()
		--frame:Hide()
	--end)
--end

function f:UnlockMounts()
	local mountIDs = C_MountJournal.GetMountIDs()
	local searchMountIDs = {}
	local activeSearch
	-- sort alphabetically
	sort(mountIDs, function(a, b)
		local name1, _, _, _, _, _, isFavorite1 = C_MountJournal.GetMountInfoByID(a)
		local name2, _, _, _, _, _, isFavorite2 = C_MountJournal.GetMountInfoByID(b)
		-- show favorites first, cant favorite an uncollected mount btw
		if isFavorite1 ~= isFavorite2 then
			return isFavorite1
		else
			return name1 < name2
		end
	end)

	local function GetActiveMountIDs()
		return activeSearch and searchMountIDs or mountIDs
	end

	-- replace api, pray nothing explodes
	function C_MountJournal.GetNumDisplayedMounts()
		return #GetActiveMountIDs()
	end

	function C_MountJournal.GetDisplayedMountInfo(index)
		local ids = GetActiveMountIDs()
		local args = {C_MountJournal.GetMountInfoByID(ids[index])}
		args[5] = true -- fake isUsable
		return unpack(args)
	end

	-- set mount count fontstring
	hooksecurefunc("MountJournal_UpdateMountList", self.UpdateMountCount)
	hooksecurefunc(MountJournal.ListScrollFrame, "update", self.UpdateMountCount) -- OnMouseWheel
	self.UpdateMountCount()

	-- roll our own search function since default search (server side) is restricted to the normal subset
	MountJournal.searchBox:HookScript("OnTextChanged", function(self)
		local text = self:GetText():trim():lower()
		if #text > 0 then
			wipe(searchMountIDs)
			activeSearch = true
			for _, v in pairs(mountIDs) do
				-- should probably optimize this with a cache
				if C_MountJournal.GetMountInfoByID(v):lower():find(text) then
					tinsert(searchMountIDs, v)
				end
			end
			-- dont wait for MOUNT_JOURNAL_SEARCH_UPDATED
			MountJournal_UpdateMountList()
		else
			activeSearch = false
		end
	end)

	local function ClearSearch()
		wipe(searchMountIDs)
		activeSearch = false
	end
	MountJournal.searchBox:HookScript("OnHide", ClearSearch)
	MountJournal.searchBox.clearButton:HookScript("OnClick", ClearSearch)
	MountJournal_FullUpdate(MountJournal)
end

function f.UpdateMountCount()
	local ids = C_MountJournal.GetMountIDs()
	MountJournal.MountCount.Count:SetText(#ids)
end

-- Registrar evento para carregar quando Blizzard_Collections estiver disponível
if C_AddOns.IsAddOnLoaded("Blizzard_Collections") then
    f:InitMountJournal()
else
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self, event, addon)
        if addon == "Blizzard_Collections" then
            self:InitMountJournal()
            self:UnregisterEvent(event)
        end
    end)
end