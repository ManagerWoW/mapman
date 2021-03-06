local aName, aTable = ...
local mmf -- MapMan Frame
local selectedCity, currentSearchTable
local SEARCH_TEXT = "Search: City Name"
local SRC_NUM_LINES = 20    -- how many cities to display
local SRC_LINE_HEIGHT = 15  -- spacing between city names
local DEST_NUM_LINES = 20
local DEST_LINE_HEIGHT = 15
local HISTORY_LENGTH = 10
-- Sorted table of all the cities. More info in Cities.lua
aTable.sortedCities, aTable.cityAlphabetTable = aTable.createSortedTable(aTable.cities, 1)
-- Sorted table of paths between cities
aTable.sortedPaths = aTable.createSortedTable(aTable.paths)


--print(aTable.paths["Stormwind"]["Ironforge"]["flying"].dist)

function aTable.createFrames()

	--------------------------------------
	--------------------------------------
	--          Frames/Buttons          --
	--------------------------------------
	--------------------------------------

	mmf = CreateFrame("Frame", "MapManFrame", UIParent)

	-- Setup background frame
	mmf:SetPoint("CENTER",0,0)
	mmf:SetBackdrop({
		bgFile="Interface\\Addons\\MapMan\\media\\White", 
		edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", 
		tile=1, tileSize=32, edgeSize=32, 
		insets={left=11, right=12, top=12, bottom=11}})
	mmf:SetBackdropColor(0.1,0.1,0.1,1)
	mmf:SetSize(900,660)
	mmf:SetFrameStrata("MEDIUM")
	mmf:SetToplevel(true)
	mmf:EnableMouse(true)
	mmf:SetMovable(true)
	mmf:RegisterForDrag("LeftButton")
	mmf:SetScript("OnDragStart", function(self) self:StartMoving() end)
	mmf:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    mmf:Hide()


	-- Title text for main frame
	mmf.Title = mmf:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	mmf.Title:SetPoint("TOP",0,-15)
	mmf.Title:SetFont("Fonts\\MORPHEUS.ttf",20)
	mmf.Title:SetTextColor(1,.7,0,1)
	mmf.Title:SetText("MapMan")

	-- Close button for main frame
	mmf.Close = CreateFrame("Button", "MapManClose", mmf, "UIPanelCloseButton")
	mmf.Close:SetPoint("TOPRIGHT", -9, -9)
	
	-- Home frame (for showing/hiding)
	mmf.HomeFrame = CreateFrame("Frame", "MapMan_HomeFrame", mmf)
	mmf.HomeFrame:SetPoint("TOPLEFT")
	mmf.HomeFrame:SetSize(mmf:GetSize())
	-- Update source/dest city tables when HomeFrame is shown
	mmf.HomeFrame:SetScript("OnShow", aTable.sourceScrollFrameUpdate)
	
	-- Home tab
	mmf.MainTab = CreateFrame("Button", "MapMan_HomeTab", mmf, "UIPanelButtonTemplate")
	mmf.MainTab:SetPoint("TOPLEFT", 13, -15)
	mmf.MainTab:SetFrameLevel(mmf:GetFrameLevel()+1)
	mmf.MainTab:SetScript("OnClick", function(self, button)
		mmf.HomeFrame:Show() end)
	-- Font String
	mmf.MainTab.Text = mmf.MainTab.Text or mmf:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	mmf.MainTab.Text:SetText("Home")
	mmf.MainTab.Text:SetPoint("CENTER", MapMan_HomeTab, "CENTER")
	mmf.MainTab:SetFontString(mmf.MainTab.Text)
	mmf.MainTab:SetSize(mmf.MainTab.Text:GetStringWidth()+10,mmf.MainTab.Text:GetStringHeight()+10)
	
	-- Routes frame (for showing/hiding)
	mmf.RoutesFrame = CreateFrame("Frame", "MapMan_RoutesFrame", mmf)
	mmf.RoutesFrame:SetPoint("TOPLEFT")
	mmf.RoutesFrame:SetSize(mmf:GetSize())

	-- Routes tab
	mmf.RoutesTab = CreateFrame("Button", "MapMan_RoutesTab", mmf.MainTab, "UIPanelButtonTemplate")
	mmf.RoutesTab:SetPoint("TOPLEFT", mmf.MainTab, "TOPRIGHT")
	mmf.RoutesTab:SetFrameLevel(mmf:GetFrameLevel()+1)
	mmf.RoutesTab:SetScript("OnClick", function(self, button)
		mmf.HomeFrame:Hide() end)
	-- Font String
	mmf.RoutesTab.Text = mmf.RoutesTab.Text or mmf:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	mmf.RoutesTab.Text:SetText("Routes")
	mmf.RoutesTab.Text:SetPoint("CENTER", MapMan_RoutesTab, "CENTER")
	mmf.RoutesTab:SetFontString(mmf.RoutesTab.Text)
	mmf.RoutesTab:SetSize(mmf.RoutesTab.Text:GetStringWidth()+10,mmf.RoutesTab.Text:GetStringHeight()+10)
	
	
	-- Search bar
	mmf.SearchBar = CreateFrame("EditBox", "MapMan_SearchBarFrame", mmf.HomeFrame, "InputBoxTemplate")
	mmf.SearchBar:SetFontObject(GameFontHighlight)
	mmf.SearchBar:SetPoint("TOPLEFT", mmf.MainTab, "BOTTOMLEFT", 10, -10)
	mmf.SearchBar:SetSize(180,15)
	-- Textures for the search bar. Probably unused / delete later
	--MapMan_SearchBarFrame.Middle:SetHeight(20)
	--MapMan_SearchBarFrame.Left:SetSize(8,20)
	--MapMan_SearchBarFrame.Right:SetSize(200,50)
	mmf.SearchBar:SetText(SEARCH_TEXT)
	mmf.SearchBar.Text = mmf.SearchBar:GetFontObject()
	mmf.SearchBar:SetAutoFocus(false)
	mmf.SearchBar:SetScript("OnTextChanged", aTable.searchCity)
	mmf.SearchBar:Show()
	
	-- History Buttons
	mmf.historyButtons = {} -- list of buttons for history
	for i=1,HISTORY_LENGTH do
		-- button size is determined when a city is selected,
		-- see addHistory(city) method
		mmf.HistoryButton = CreateFrame("Button", nil, mmf.HomeFrame, "UIPanelButtonTemplate")
		mmf.HistoryButton:SetPoint("TOPLEFT", mmf.SearchBar, "BOTTOMLEFT", -5, -8)
		mmf.HistoryButton:SetFrameLevel(mmf:GetFrameLevel()+1)
		mmf.HistoryButton.Text = mmf.HistoryButton.Text or mmf:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		mmf.HistoryButton.Text:SetText("")
		mmf.HistoryButton.Text:SetPoint("CENTER", mmf.HistoryButton, "CENTER")
		mmf.HistoryButton.Text:SetWordWrap(false)
		mmf.HistoryButton:SetFontString(mmf.HistoryButton.Text)
		mmf.HistoryButton:Hide()
		mmf.historyButtons[i] = mmf.HistoryButton
	end
	
	-- We needed to create button #1 first, to anchor to it
	-- Change anchors / positioning of button #2+
	for i=2,HISTORY_LENGTH do
		local button = mmf.historyButtons[i]
		button:SetPoint("TOPLEFT", mmf.historyButtons[i-1], "TOPRIGHT")
	end
	
	
	
	-- FauxScrollframe for sources
	mmf.SourceScrollFrame = CreateFrame("ScrollFrame", "MapMan_SourceScrollFrame", mmf.HomeFrame, "FauxScrollFrameTemplate")
	mmf.SourceScrollFrame:SetPoint("TOPLEFT", 20, -100)
	mmf.SourceScrollFrame:SetPoint("BOTTOMRIGHT", -700, 20)
	mmf.SourceScrollFrame:SetBackdrop({
		bgFile="Interface\\Addons\\MapMan\\media\\White",
		edgeFile="Interface\\ChatFrame\\ChatFrameBackground",
		tile=1, tileSize=1, edgeSize=1, 
		insets={left=12, right=12, top=12, bottom=12}})
	mmf.SourceScrollFrame:SetBackdropColor(0.1,0.1,0.1,1)
	mmf.SourceScrollFrame:SetBackdropBorderColor(0.3,0.3,0.3,1)
    mmf.SourceScrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, SRC_LINE_HEIGHT, aTable.sourceScrollFrameUpdate)
    end)
    
	-- Buttons for SourceScrollFrame
	mmf.SourceScrollFrame.sources = {} -- list of source cities
	for i=1,SRC_NUM_LINES do
		local sourceCity = CreateFrame("Button", "$parentCity"..i, mmf.SourceScrollFrame, "UIPanelButtonTemplate")
        sourceCity:SetHeight(SRC_LINE_HEIGHT)
        sourceCity:SetWidth(mmf.SourceScrollFrame:GetWidth())
		sourceCity:SetPoint("TOPLEFT", 0, -(i-1)*SRC_LINE_HEIGHT-4)
        sourceCity:DisableDrawLayer("BACKGROUND") -- remove background
        sourceCity:Disable() -- disable until it is needed
		mmf.SourceScrollFrame.sources[i] = sourceCity
	end
	
	-- FauxScrollframe for destinations
	mmf.DestScrollFrame = CreateFrame("ScrollFrame", "MapMan_DestinationScrollFrame", mmf.HomeFrame, "FauxScrollFrameTemplate")
	mmf.DestScrollFrame:SetPoint("TOPLEFT", mmf.SourceScrollFrame, "TOPRIGHT", 30, 0)
	mmf.DestScrollFrame:SetPoint("BOTTOMRIGHT", -480, 20)
	mmf.DestScrollFrame:SetBackdrop({
		bgFile="Interface\\Addons\\MapMan\\media\\White",
		edgeFile="Interface\\ChatFrame\\ChatFrameBackground",
		tile=1, tileSize=1, edgeSize=1, 
		insets={left=1, right=1, top=1, bottom=1}})
	mmf.DestScrollFrame:SetBackdropColor(0.1,0.1,0.1,1)
	mmf.DestScrollFrame:SetBackdropBorderColor(0.3,0.3,0.3,1)
    mmf.DestScrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, DEST_LINE_HEIGHT, destScrollFrameUpdate)
    end)
	
	-- Buttons for DestScrollFrame
	mmf.DestScrollFrame.destinations = {} -- list of destination cities
	for i=1,DEST_NUM_LINES do
		local destCity = CreateFrame("Button", "$parentCity"..i, mmf.DestScrollFrame, "UIPanelButtonTemplate")
        destCity:SetHeight(DEST_LINE_HEIGHT)
        destCity:SetWidth(mmf.DestScrollFrame:GetWidth())
		destCity:SetPoint("TOPLEFT", 6, -(i-1)*DEST_LINE_HEIGHT-4)
        -- removes the button background
        destCity:DisableDrawLayer("BACKGROUND")
        -- disable the button until it is needed
        destCity:Disable()
		mmf.DestScrollFrame.destinations[i] = destCity
	end
    
    
	
    function mmf.OnEvent(self, event)
        mmf.SourceScrollFrame.ScrollBar:SetValue(0)
        mmf.DestScrollFrame.ScrollBar:SetValue(0)
    end

    mmf:SetScript("OnEvent", mmf.OnEvent)
    mmf:HookScript("OnShow", mmf.OnEvent)

end






	--------------------------------------
	--------------------------------------
	--          Helper Methods          --
	--------------------------------------
	--------------------------------------

-- Hide all destination cities
local function destScrollFrameHide()
	for i=1,DEST_NUM_LINES do
		local button = mmf.DestScrollFrame.destinations[i]
		button:Hide()
	end
end


-- Clear highlight from all cities
local function unlockButtonHighlights()
	for i=1,SRC_NUM_LINES do
		local button = mmf.SourceScrollFrame.sources[i]
		button:UnlockHighlight()
	end
end


-- Clear history
local function clearHistory()
	for i=1,HISTORY_LENGTH do
		mmf.historyButtons[i].Text:SetText("")
		mmf.historyButtons[i]:Hide()
	end
end


-- Add city to history
local function addHistory(city)
	local width, height -- size of city text
	for i=1,HISTORY_LENGTH do
		if not mmf.historyButtons[i]:GetText() then
			mmf.historyButtons[i]:Show()
			mmf.historyButtons[i].Text:SetText(city)
			
			width = math.min(100, mmf.historyButtons[i].Text:GetStringWidth()+10)
			height = mmf.historyButtons[i].Text:GetStringHeight()+10
			
			mmf.historyButtons[i].Text:SetWidth(width)
			mmf.historyButtons[i]:SetSize(width, height)
			break
		end
	end
end







local function destScrollFrameUpdate(source)
	local offset = FauxScrollFrame_GetOffset(mmf.DestScrollFrame)
	FauxScrollFrame_Update(mmf.DestScrollFrame, #aTable.sortedPaths, 
	  DEST_NUM_LINES, DEST_LINE_HEIGHT)
	-- Blizzard bug: FSF_U hides the scroll frame not scroll bar,
	-- so we have to manually show it again
	mmf.DestScrollFrame:Show() 
	
	local paths = aTable.createSortedTable(aTable.paths[source])
	
	if paths ~= nil then
		for i=1, DEST_NUM_LINES do
			local idx = offset+i
			local button = mmf.DestScrollFrame.destinations[i]
			
			if idx <= #paths then
				button:SetScript("OnClick", function(self, buttonPress)
					selectedCity = paths[idx]
					destScrollFrameUpdate(selectedCity) end)
				button.text = button:GetFontString() or button:CreateFontString(nil,"ARTWORK","GameFontNormal")
				button.text:SetPoint("LEFT", button, "LEFT")
				button.text:SetWidth(mmf.DestScrollFrame:GetWidth()-10)
				button.text:SetJustifyH("LEFT")
				button.text:SetWordWrap(false)
				button.text:SetText(paths[idx])
				button.text:SetTextColor(1,.7,0,1)
				----
				---- PH
				----
				button.tooltipText = "PH: Will contain route info\nfor getting to this city"
				-- button was disable on creation until ready to be used
				button:Enable()
				button:Show()
			else
				button:Hide()
			end
		end
	else
		destScrollFrameHide()
	end
end


function aTable.sourceScrollFrameUpdate(table, searching)
	-- keep track of city table used to search
	if searching == true then 
		currentSearchTable = table
	end
	
	-- if something is being searched, use the stored table
	if (mmf.SearchBar:GetText() ~= SEARCH_TEXT) and 
	  (mmf.SearchBar:GetText() ~= "") then
		table = currentSearchTable
	else -- else default to all cities
		table = aTable.sortedCities
		currentSearchTable = nil
	end
	
	local offset = FauxScrollFrame_GetOffset(mmf.SourceScrollFrame)
	FauxScrollFrame_Update(mmf.SourceScrollFrame, #table, SRC_NUM_LINES, SRC_LINE_HEIGHT)
	-- Blizzard bug: FSF_U hides the scroll frame not scroll bar,
	-- so we have to manually show it again
	mmf.SourceScrollFrame:Show() 
	
	for i=1, SRC_NUM_LINES do
		local idx = offset+i
		local button = mmf.SourceScrollFrame.sources[i]
		if idx <= #table then
			-- button was disable on creation until ready to be used
			button:Enable()
			button:UnlockHighlight()
			button:SetScript("OnClick", function(self, buttonPress)
				selectedCity = table[idx]
				unlockButtonHighlights() -- clear previous highlight
				button:LockHighlight()
				addHistory(selectedCity)
				-- update dest cities for the clicked city
				destScrollFrameUpdate(selectedCity)
				end)
			-- keep the selectedCity highlighted on scroll
			if table[idx] == selectedCity then
				button:LockHighlight() 
			end
			button.text = button:GetFontString() or button:CreateFontString(nil,"ARTWORK","GameFontNormal")
			button.text:SetPoint("LEFT", button, "LEFT", 6, 0)
			button.text:SetWidth(mmf.SourceScrollFrame:GetWidth()-10)
			button.text:SetJustifyH("LEFT")
			button.text:SetWordWrap(false)
			button.text:SetText(table[idx])
			button.text:SetTextColor(1,.7,0,1)
			button:Show()
		else
			button:Hide()
		end
	end
end


function FauxScrollFrame_OnVerticalScroll(self, value, itemHeight, updateFunction)
	local scrollbar = _G[self:GetName().."ScrollBar"]
	scrollbar:SetValue(value);
	self.offset = floor((value / itemHeight) + 0.5)
	-- if not enough cities for scrolling, set offset to 0
	if currentSearchTable and (#currentSearchTable < SRC_NUM_LINES) then
		scrollbar:SetValue(0)
		self.offset = 0
		aTable.sourceScrollFrameUpdate()
	end
	if (updateFunction) then
		updateFunction()
	end
end



	--------------------------------------
	--------------------------------------
	--          Slash Commands          --
	--------------------------------------
	--------------------------------------
	
function aTable.slashCommands()
	SLASH_MAPMAN1 = "/mapman"
	SLASH_MAPMAN2 = "/mman"
	SlashCmdList["MAPMAN"] = function(message)
		if mmf:IsShown() then mmf:Hide() else mmf:Show() end
	end
end


























