--[[
    ZaykoRAGEUI - menu natif simple (style RAGE UI), sans dependance externe.

    API (exports) :
        exports.ZaykoRAGEUI:CreateMenu(id, title, subtitle)
        exports.ZaykoRAGEUI:AddButton(id, label, description, data)
        exports.ZaykoRAGEUI:ClearButtons(id)
        exports.ZaykoRAGEUI:Open(id)
        exports.ZaykoRAGEUI:Close()
        exports.ZaykoRAGEUI:IsOpen(id)

    Evenements client emis :
        'ZaykoRAGEUI:onSelect' (menuId, data, index) -> quand un bouton est valide
        'ZaykoRAGEUI:onClose'  (menuId)              -> quand le menu est ferme
]]

local Menus = {}
local currentMenu = nil

local Keys = {
    up = 172,     -- INPUT_FRONTEND_UP
    down = 173,   -- INPUT_FRONTEND_DOWN
    select = 201, -- INPUT_FRONTEND_ACCEPT
    back = 202,   -- INPUT_FRONTEND_CANCEL
}

local MENU_X = 0.80
local MENU_WIDTH = 0.22
local HEADER_HEIGHT = 0.07
local ROW_HEIGHT = 0.035
local DESC_HEIGHT = 0.08
local GAP = 0.006
local TOP_Y = 0.30

local COLOR_HEADER = { 30, 150, 90, 255 }
local COLOR_ITEM = { 25, 25, 30, 210 }
local COLOR_ITEM_SELECTED = { 45, 180, 110, 255 }
local COLOR_DESC_BG = { 0, 0, 0, 200 }
local COLOR_TEXT = { 255, 255, 255, 255 }

local function drawRect(x, y, w, h, color)
    DrawRect(x, y, w, h, color[1], color[2], color[3], color[4])
end

local function drawText(text, x, y, scale, color, center)
    SetTextFont(4)
    SetTextScale(scale, scale)
    SetTextColour(color[1], color[2], color[3], color[4])
    SetTextEntry('STRING')
    SetTextCentre(center or false)
    AddTextComponentString(text)
    DrawText(x, y)
end

local function drawMenu(menu)
    local headerCenter = TOP_Y + HEADER_HEIGHT / 2
    drawRect(MENU_X, headerCenter, MENU_WIDTH, HEADER_HEIGHT, COLOR_HEADER)
    drawText(menu.title, MENU_X, TOP_Y + 0.008, 0.42, COLOR_TEXT, true)
    if menu.subtitle ~= '' then
        drawText(menu.subtitle, MENU_X, TOP_Y + 0.034, 0.25, { 230, 230, 230, 255 }, true)
    end

    local listTop = TOP_Y + HEADER_HEIGHT + GAP

    for i, btn in ipairs(menu.buttons) do
        local rowCenter = listTop + ROW_HEIGHT * (i - 1) + ROW_HEIGHT / 2
        local bg = (i == menu.selected) and COLOR_ITEM_SELECTED or COLOR_ITEM
        drawRect(MENU_X, rowCenter, MENU_WIDTH, ROW_HEIGHT, bg)
        drawText(btn.label, MENU_X - MENU_WIDTH / 2 + 0.012, rowCenter - 0.011, 0.30, COLOR_TEXT, false)
    end

    local listBottom = listTop + ROW_HEIGHT * #menu.buttons
    local selectedBtn = menu.buttons[menu.selected]

    if selectedBtn and selectedBtn.description and selectedBtn.description ~= '' then
        local descCenter = listBottom + GAP + DESC_HEIGHT / 2
        drawRect(MENU_X, descCenter, MENU_WIDTH, DESC_HEIGHT, COLOR_DESC_BG)

        SetTextFont(4)
        SetTextScale(0.26, 0.26)
        SetTextColour(220, 220, 220, 255)
        SetTextEntry('STRING')
        SetTextWrap(MENU_X - MENU_WIDTH / 2 + 0.012, MENU_X + MENU_WIDTH / 2 - 0.012)
        AddTextComponentString(selectedBtn.description)
        DrawText(MENU_X - MENU_WIDTH / 2 + 0.012, listBottom + GAP + 0.008)
    end
end

local function closeCurrent()
    if not currentMenu then return end
    local closedId = currentMenu
    currentMenu = nil
    TriggerEvent('ZaykoRAGEUI:onClose', closedId)
end

CreateThread(function()
    while true do
        local sleep = 300

        if currentMenu then
            sleep = 0
            local menu = Menus[currentMenu]

            if menu and #menu.buttons > 0 then
                drawMenu(menu)

                if IsControlJustPressed(0, Keys.up) then
                    menu.selected = menu.selected - 1
                    if menu.selected < 1 then menu.selected = #menu.buttons end
                    PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
                elseif IsControlJustPressed(0, Keys.down) then
                    menu.selected = menu.selected + 1
                    if menu.selected > #menu.buttons then menu.selected = 1 end
                    PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
                elseif IsControlJustPressed(0, Keys.select) then
                    local btn = menu.buttons[menu.selected]
                    PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
                    TriggerEvent('ZaykoRAGEUI:onSelect', currentMenu, btn.data, menu.selected)
                elseif IsControlJustPressed(0, Keys.back) then
                    PlaySoundFrontend(-1, 'BACK', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
                    closeCurrent()
                end
            end
        end

        Wait(sleep)
    end
end)

local function ensureMenu(id)
    if not Menus[id] then
        Menus[id] = { title = '', subtitle = '', buttons = {}, selected = 1 }
    end
    return Menus[id]
end

exports('CreateMenu', function(id, title, subtitle)
    local menu = ensureMenu(id)
    menu.title = title or ''
    menu.subtitle = subtitle or ''
    menu.buttons = {}
    menu.selected = 1
end)

exports('AddButton', function(id, label, description, data)
    local menu = ensureMenu(id)
    menu.buttons[#menu.buttons + 1] = { label = label, description = description, data = data }
end)

exports('ClearButtons', function(id)
    local menu = ensureMenu(id)
    menu.buttons = {}
    menu.selected = 1
end)

exports('Open', function(id)
    if Menus[id] then
        currentMenu = id
        Menus[id].selected = 1
    end
end)

exports('Close', function()
    closeCurrent()
end)

exports('IsOpen', function(id)
    if id then
        return currentMenu == id
    end
    return currentMenu ~= nil
end)
