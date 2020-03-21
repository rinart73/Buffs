package.path = package.path .. ";data/scripts/lib/?.lua"
include("callable")
include("utility")
local Azimuth, Config, Log, ConfigOptions = unpack(include("buffsinit"))
local Helper = include("BuffsHelper")

-- namespace BuffsMod
BuffsMod = {}

local buffPrefixes = {"BM_", "M_", "MB_", "AB_", "_B"} -- client/server
local playerTab, shipTab, shipBonusesRows, shipStatsRows, playerStatsRows, playerBuffsContainer, shipBuffsContainer, playerBufsfList, shipBufsfList, shipOverlayCheckBox, playerOverlayCheckBox -- client UI
local data, pending, isReady, isFirstLaunch -- server
local buffDescriptions, buffs, buffsCount, shipBuffsCopy, iconsRenderer, hoveredBuffTooltip, prevHoveredName, playerTabPrevHoveredName, playerTabHoveredBuffTooltip, shipTabPrevHoveredName, shipTabHoveredBuffTooltip -- client


if onClient() then


include("azimuthlib-uiproportionalsplitter")
buffDescriptions = include("BuffsIntegration")

-- PREDEFINED --

function BuffsMod.getUpdateInterval()
    return 0.2
end

function BuffsMod.initialize()
    buffs = {}
    buffsCount = 0

    -- initUI
    playerTab = PlayerWindow():createTab("Buffs & Stats"%_t, "data/textures/icons/blockstats.png", "Buffs & Stats"%_t)
    playerTab.onShowFunction = "onShowPlayerTab"
    local playerFrame = playerTab:createScrollFrame(Rect(playerTab.size))
    playerFrame.scrollSpeed = 40
    local playerLister = UIVerticalLister(Rect(playerTab.size), 10, 10)
    playerLister.marginRight = 30

    shipTab = ShipWindow():createTab("Buffs & Stats"%_t, "data/textures/icons/blockstats.png", "Buffs & Stats"%_t)
    shipTab.onShowFunction = "onShowShipTab"
    local shipFrame = shipTab:createScrollFrame(Rect(shipTab.size))
    shipFrame.scrollSpeed = 40
    local shipLister = UIVerticalLister(Rect(shipTab.size), 10, 10)
    shipLister.marginRight = 30

    -- StatsBonuses (entity)
    local rect = shipLister:placeCenter(vec2(shipLister.inner.width, 30))
    local partitions = UIVerticalProportionalSplitter(rect, 10, 0, {0.55, 0.225, 0.225})
    shipFrame:createLabel(partitions[1], "Stat"%_t, 15)
    shipFrame:createLabel(partitions[2], "Base value"%_t, 15)
    shipFrame:createLabel(partitions[3], "Result"%_t, 15)
    shipBonusesRows = {}
    local shipDiffColor = true
    for _, bonus in ipairs(Helper.SortedBonuses) do
        local pair = Helper.BonusesDisplay[bonus]
        if pair.value or pair.stat or pair.crew or pair.func then -- don't show stat if there is no way to get base value
            rect = shipLister:placeCenter(vec2(shipLister.inner.width, 25))
            partitions = UIVerticalProportionalSplitter(rect, 10, 0, {0.55, 0.225, 0.225})
            local nameLabel = shipFrame:createLabel(partitions[1], pair.name, 15)
            local baseLabel = shipFrame:createLabel(partitions[2], "", 15)
            local resultLabel = shipFrame:createLabel(partitions[3], "", 15)
            if shipDiffColor then
                nameLabel.color = ColorInt(0xff797979)
                baseLabel.color = ColorInt(0xff696969)
                resultLabel.color = ColorInt(0xff696969)
            end
            shipDiffColor = not shipDiffColor
            shipBonusesRows[#shipBonusesRows+1] = {
              bonus = bonus,
              baseLabel = baseLabel,
              resultLabel = resultLabel
            }
        end
    end

    -- Custom Stats
    shipStatsRows = {}
    playerStatsRows = {}
    local playerDiffColor = true
    local firstPlayerStat = true
    for enumName, stat in pairs(Helper.Stats) do
        if stat.displayName and stat.showInStats and stat.statsFunc then
            if stat.showInStats ~= Helper.Target.Player then
                rect = shipLister:placeCenter(vec2(shipLister.inner.width, 25))
                partitions = UIVerticalProportionalSplitter(rect, 10, 0, {0.55, 0.225, 0.225})
                local nameLabel = shipFrame:createLabel(partitions[1], stat.displayName, 13)
                local baseLabel = shipFrame:createLabel(partitions[2], "", 13)
                local resultLabel = shipFrame:createLabel(partitions[3], "", 13)
                if shipDiffColor then
                    nameLabel.color = ColorInt(0xff797979)
                    baseLabel.color = ColorInt(0xff696969)
                    resultLabel.color = ColorInt(0xff696969)
                end
                shipDiffColor = not shipDiffColor
                shipStatsRows[#shipStatsRows+1] = {
                  stat = enumName,
                  baseLabel = baseLabel,
                  resultLabel = resultLabel
                }
            end
            if stat.showInStats == Helper.Target.Player or stat.showInStats == Helper.Target.Both then
                if firstPlayerStat then
                    firstPlayerStat = false
                    rect = playerLister:placeCenter(vec2(playerLister.inner.width, 30))
                    partitions = UIVerticalProportionalSplitter(rect, 10, 0, {0.55, 0.225, 0.225})
                    playerFrame:createLabel(partitions[1], "Stat"%_t, 15)
                    playerFrame:createLabel(partitions[2], "Base value"%_t, 15)
                    playerFrame:createLabel(partitions[3], "Result"%_t, 15)
                end
                rect = playerLister:placeCenter(vec2(playerLister.inner.width, 25))
                partitions = UIVerticalProportionalSplitter(rect, 10, 0, {0.55, 0.225, 0.225})
                local nameLabel = playerFrame:createLabel(partitions[1], stat.displayName, 13)
                local baseLabel = playerFrame:createLabel(partitions[2], "", 13)
                local resultLabel = playerFrame:createLabel(partitions[3], "", 13)
                if playerDiffColor then
                    nameLabel.color = ColorInt(0xff797979)
                    baseLabel.color = ColorInt(0xff696969)
                    resultLabel.color = ColorInt(0xff696969)
                end
                playerDiffColor = not playerDiffColor
                playerStatsRows[#playerStatsRows+1] = {
                  stat = enumName,
                  baseLabel = baseLabel,
                  resultLabel = resultLabel
                }
            end
        end
    end
    
    -- separators
    rect = shipLister:placeCenter(vec2(shipLister.inner.width, 1))
    shipFrame:createLine(rect.topLeft + vec2(30, 0), rect.topRight - vec2(30, 0))
    if not firstPlayerStat then
        rect = playerLister:placeCenter(vec2(playerLister.inner.width, 1))
        playerFrame:createLine(rect.topLeft + vec2(30, 0), rect.topRight - vec2(30, 0))
    end
    -- display checkboxes
    shipOverlayCheckBox = shipFrame:createCheckBox(shipLister:placeCenter(vec2(shipLister.inner.width, 25)), "Hide buffs icons overlay"%_t, "onShipOverlayCheckBox")
    shipOverlayCheckBox.captionLeft = false
    shipOverlayCheckBox:setCheckedNoCallback(Config.HideShipIconsOverlay)
    playerOverlayCheckBox = playerFrame:createCheckBox(playerLister:placeCenter(vec2(playerLister.inner.width, 25)), "Hide buffs icons overlay"%_t, "onPlayerOverlayCheckBox")
    playerOverlayCheckBox.captionLeft = false
    playerOverlayCheckBox:setCheckedNoCallback(Config.HidePlayerIconsOverlay)

    -- containers for player & ships full buffs lists
    playerBuffsContainer = playerFrame:createContainer(playerLister:placeCenter(vec2(playerLister.inner.width, 1)))
    shipBuffsContainer = shipFrame:createContainer(shipLister:placeCenter(vec2(shipLister.inner.width, 1)))

    Player():registerCallback("onShipChanged", "onShipChanged")
    Player():registerCallback("onPostRenderHud", "onPostRenderHud")

    invokeServerFunction("refreshData")
end

function BuffsMod.update(timePassed)
    local player = Player()
    local mouse = Mouse().position
    local noClientUpdate = false
    local res
    if buffsCount == 0 or Config.HidePlayerIconsOverlay or (player.state ~= PlayerStateType.Fly and player.state ~= PlayerStateType.Interact) then
        noClientUpdate = true
    else
        iconsRenderer = UIRenderer()
        res = getResolution()
    end
    -- check if player/ship buffs tabs are shown and hovered
    local hud = Hud()
    local isPlayerTab, isPlayerTabBuffsHovered
    if hud.playerWindowVisible then
        isPlayerTab = playerTab and playerTab.isActiveTab
        if isPlayerTab then
            if mouse.x >= playerBuffsContainer.lower.x and mouse.x <= playerBuffsContainer.upper.x
              and mouse.y >= playerBuffsContainer.lower.y and mouse.y <= playerBuffsContainer.upper.y then
                isPlayerTabBuffsHovered = true
            end
        end
    end
    local isShipTab, isShipTabBuffsHovered
    if hud.shipWindowVisible then
        isShipTab = shipTab and shipTab.isActiveTab
        if isShipTab and not isShipTabBuffsHovered then
            if mouse.x >= shipBuffsContainer.lower.x and mouse.x <= shipBuffsContainer.upper.x
              and mouse.y >= shipBuffsContainer.lower.y and mouse.y <= shipBuffsContainer.upper.y then
                isShipTabBuffsHovered = true
            end
        end
    end
    if not isShipTab then
        shipBuffsCopy = nil
    end

    local found = false -- if at least one buff was hovered
    local playerBuffFound = false
    -- player buffs
    if buffsCount > 0 then
        for i, buff in ipairs(buffs) do
            -- decay buffs
            if buff.duration ~= -1 then
                buff.redraw = math.floor(buff.duration)
                buff.duration = math.max(0, buff.duration - timePassed)
                buff.redraw = buff.redraw - math.floor(buff.duration)
                -- update player window tab duration and color
                if isPlayerTab and buff.redraw == 1 then
                    local row = playerBufsfList and playerBufsfList[buff.fullname]
                    if row then
                        row.icon.color = Helper.getBuffColor(buff)
                        row.duration.caption = Helper.formatTimeShort(buff.duration)
                    end
                end
            end
            -- check for mouse hover for player buffs overlay & redraw icons
            if not noClientUpdate then
                local rx = res.x / 2 - 300 - math.floor((i - 1) / 2) * 30
                local ry = res.y - 65 + ((i - 1) % 2) * 30
                -- check mouse hover
                if not found and mouse.x >= rx and mouse.x <= rx + 25 and mouse.y >= ry and mouse.y <= ry + 25 then
                    found = true
                    if buff.redraw == 1 or prevHoveredName ~= buff.fullname then
                        prevHoveredName = buff.fullname
                        hoveredBuffTooltip = TooltipRenderer(Helper.createBuffTooltip(true, buff))
                    end
                end
                -- redraw icons 5 times per second instead of FPS time per second
                if rx + 35 <= res.x then
                    iconsRenderer:renderPixelIcon(vec2(rx, ry), Helper.getBuffColor(buff), buff.icon)
                end
            end
            -- check for mouse hover for player buffs in the player window tab
            if not found and isPlayerTab and not playerBuffFound and isPlayerTabBuffsHovered then
                local row = playerBufsfList and playerBufsfList[buff.fullname]
                if row and row.frame.mouseOver then
                    playerBuffFound = true
                    if buff.redraw == 1 or playerTabPrevHoveredName ~= buff.fullname then
                        playerTabPrevHoveredName = buff.fullname
                        playerTabHoveredBuffTooltip = TooltipRenderer(Helper.createBuffTooltip(true, buff))
                    end
                end
            end
        end
    end
    -- copy of ship buffs
    local shipBuffFound = false
    if shipBuffsCopy then
        for i, buff in ipairs(shipBuffsCopy) do
            -- decay buffs
            if buff.duration ~= -1 then
                buff.redraw = math.floor(buff.duration)
                buff.duration = math.max(0, buff.duration - timePassed)
                buff.redraw = buff.redraw - math.floor(buff.duration)
                -- update player window tab duration and color
                if buff.redraw == 1 then
                    local row = shipBufsfList and shipBufsfList[buff.fullname]
                    if row then
                        row.icon.color = Helper.getBuffColor(buff)
                        row.duration.caption = Helper.formatTimeShort(buff.duration)
                    end
                end
            end
            -- check for mouse hover for ship buffs in the ship window tab
            if not found and not playerBuffFound and not shipBuffFound and isShipTabBuffsHovered then
                local row = shipBufsfList and shipBufsfList[buff.fullname]
                if row and row.frame.mouseOver then
                    shipBuffFound = true
                    if buff.redraw == 1 or shipTabPrevHoveredName ~= buff.fullname then
                        shipTabPrevHoveredName = buff.fullname
                        shipTabHoveredBuffTooltip = TooltipRenderer(Helper.createBuffTooltip(false, buff))
                    end
                end
            end
        end
    end
    if not found then
        prevHoveredName = nil
        hoveredBuffTooltip = nil
    end
    if not playerBuffFound then
        playerTabPrevHoveredName = nil
        playerTabHoveredBuffTooltip = nil
    end
    if not shipBuffFound then
        shipTabPrevHoveredName = nil
        shipTabHoveredBuffTooltip = nil
    end
end

-- CALLBACKS --

function BuffsMod.onShipChanged(playerIndex, craftId)
    if craftId then
        local entity = Entity(craftId)
        if entity and (entity.isShip or entity.isStation) then
            ShipWindow():activateTab(shipTab)
            return
        end
    end
    ShipWindow():deactivateTab(shipTab)
end

function BuffsMod.onShowPlayerTab()
    local player = Player()
    -- custom stats
    for _, group in ipairs(playerStatsRows) do
        local stat = Helper.Stats[group.stat]
        if stat then
            local base, result = stat.statsFunc(player)
            if not base then
                base = '?'
            end
            if not result then
                result = '?'
            end
            group.baseLabel.caption = base
            group.resultLabel.caption = result
        end
    end
    -- dynamically generated full buffs list
    playerBufsfList = {}
    playerBuffsContainer:clear()
    playerBuffsContainer.height = 1
    if buffsCount > 0 then
        playerBuffsContainer.height = buffsCount * 34 + 35
        local hPartitions = UIHorizontalProportionalSplitter(Rect(playerBuffsContainer.size), 10, 0, {30, 0.5})
        local partitions = UIVerticalProportionalSplitter(hPartitions[1], 20, 2, {25, 0.7, 0.3})
        local label = playerBuffsContainer:createLabel(partitions[2], "Name"%_t, 14)
        label:setCenterAligned()
        label = playerBuffsContainer:createLabel(partitions[3], "Duration"%_t, 14)
        label:setCenterAligned()
        local splitter = UIHorizontalMultiSplitter(hPartitions[2], 5, 0, buffsCount - 1)
        for k, buff in ipairs(buffs) do
            local rect = splitter:partition(k - 1)
            local frame = playerBuffsContainer:createFrame(rect)
            partitions = UIVerticalProportionalSplitter(rect, 20, 2, {25, 0.7, 0.3})
            local icon = playerBuffsContainer:createPicture(partitions[1], buff.icon)
            icon.flipped = true
            icon.color = Helper.getBuffColor(buff)
            local name = playerBuffsContainer:createLabel(partitions[2], buff.name, 12)
            name:setLeftAligned()
            local duration = playerBuffsContainer:createLabel(partitions[3], buff.duration ~= -1 and Helper.formatTimeShort(buff.duration) or "Permanent"%_t, 12)
            duration:setCenterAligned()
            playerBufsfList[buff.fullname] = {
              frame = frame,
              icon = icon,
              duration = duration
            }
        end
    end
end

function BuffsMod.onShowShipTab()
    local player = Player()
    local ship = getPlayerCraft()
    if not ship or not (ship.type == EntityType.Ship or ship.type == EntityType.Station) then
        ship = nil
    end

    -- basic stats
    if ship then
        local crew = ship.crew
        local planStats = ship:getFullPlanCopy():getStats()
        for _, group in ipairs(shipBonusesRows) do
            local bonus = Helper.BonusesDisplay[group.bonus]
            if bonus then
                local value
                if bonus.value then
                    value = bonus.value
                elseif bonus.stat then
                    value = planStats[bonus.stat]
                elseif bonus.crew then
                    value = crew[bonus.crew]
                elseif bonus.func then
                    value = bonus.func(planStats)
                end
                local bonusId = StatsBonuses[group.bonus]
                if value then
                    group.baseLabel.caption = Helper.formatBonusStat(4, bonusId, value, true)
                else
                    group.baseLabel.caption = '?'
                    value = 1
                end
                value = ship:getBoostedValue(bonusId, value)
                group.resultLabel.caption = Helper.formatBonusStat(4, bonusId, value, true)
            end
        end
        -- custom stats
        for _, group in ipairs(shipStatsRows) do
            local stat = Helper.Stats[group.stat]
            if stat then
                local base, result = stat.statsFunc(nil, ship)
                if not base then
                    base = '?'
                end
                if not result then
                    result = '?'
                end
                group.baseLabel.caption = base
                group.resultLabel.caption = result
            end
        end
    end
    -- dynamically generated full buffs list
    shipBufsfList = {}
    shipBuffsContainer:clear()
    shipBuffsContainer.height = 1
    if ship then
        shipBuffsCopy = Helper.getBuffs(ship)
    else
        shipBuffsCopy = nil
    end
    local shipBuffsCount = shipBuffsCopy and #shipBuffsCopy or 0
    if shipBuffsCount == 0 then
        shipBuffsCopy = nil
    else
        shipBuffsContainer.height = shipBuffsCount * 34 + 35
        local hPartitions = UIHorizontalProportionalSplitter(Rect(shipBuffsContainer.size), 10, 0, {30, 0.5})
        local partitions = UIVerticalProportionalSplitter(hPartitions[1], 20, 2, {15, 25, 0.7, 0.3})
        local label = shipBuffsContainer:createLabel(partitions[3], "Name"%_t, 14)
        label:setCenterAligned()
        label = shipBuffsContainer:createLabel(partitions[4], "Duration"%_t, 14)
        label:setCenterAligned()
        local splitter = UIHorizontalMultiSplitter(hPartitions[2], 5, 0, shipBuffsCount - 1)
        for k, buff in ipairs(shipBuffsCopy) do
            local rect = splitter:partition(k - 1)
            local frame = shipBuffsContainer:createFrame(rect)
            partitions = UIVerticalProportionalSplitter(rect, 20, 2, {15, 25, 0.7, 0.3})
            if buff.player then -- tied buff (from a player)
                rect = partitions[1]
                local tiedIcon = shipBuffsContainer:createPicture(Rect(rect.lower, rect.lower + vec2(25, 25)), "data/textures/icons/buffs/ui/player-tied.png")
                tiedIcon.flipped = true
                if buff.player == player.index then -- you're the captain of the ship, so the buff comes from you
                    tiedIcon.color = ColorInt(0xff66F066)
                end
            end
            local icon = shipBuffsContainer:createPicture(partitions[2], buff.icon)
            icon.flipped = true
            icon.color = Helper.getBuffColor(buff)
            local name = shipBuffsContainer:createLabel(partitions[3], buff.name, 12)
            name:setLeftAligned()
            local duration = shipBuffsContainer:createLabel(partitions[4], buff.duration ~= -1 and Helper.formatTimeShort(buff.duration) or "Permanent"%_t, 12)
            duration:setCenterAligned()
            shipBufsfList[buff.fullname] = {
              frame = frame,
              icon = icon,
              duration = duration
            }
        end
    end
end

function BuffsMod.onPostRenderHud(state)
    if state ~= PlayerStateType.Fly and state ~= PlayerStateType.Interact then return end
    if not Config.HidePlayerIconsOverlay then
        if iconsRenderer then
            iconsRenderer:display()
        end
        if hoveredBuffTooltip then
            hoveredBuffTooltip:draw(Mouse().position)
        end
    end
    if playerTabHoveredBuffTooltip then
        playerTabHoveredBuffTooltip:draw(Mouse().position)
    end
    if shipTabHoveredBuffTooltip then
        shipTabHoveredBuffTooltip:draw(Mouse().position)
    end
end

function BuffsMod.onShipOverlayCheckBox(checkBox, value)
    Config.HideShipIconsOverlay = value
    Azimuth.saveConfig("Buffs", Config, ConfigOptions)
    local craft = getPlayerCraft()
    if craft and (craft.isStation or craft.isShip) then
        craft:invokeFunction("buffs.lua", "setHideShipIconsOverlay", value)
    end
end

function BuffsMod.onPlayerOverlayCheckBox(checkBox, value)
    Config.HidePlayerIconsOverlay = value
    Azimuth.saveConfig("Buffs", Config, ConfigOptions)
end

-- CALLABLE --

function BuffsMod.receiveData(_buffs)
    local player = Player()
    Log:Debug("'%s'(%i): receiveData: %s", player.name, player.index, _buffs)
    buffsCount = 0
    --buffs = _buffs
    local newbuffs = {}
    for fullname, buff in pairs(_buffs) do
        buff.fullname = fullname
        buffsCount = buffsCount + 1
        -- custom color
        if buff.color then
            buff.color = ColorInt(buff.color)
        else
            buff.color = nil
        end
        if buff.lowColor then
            buff.lowColor = ColorInt(buff.lowColor)
        else
            buff.lowColor = nil
        end
        -- icon
        if buff.type == 5 then
            buff.icon = "data/textures/icons/buffs/" .. (buff.icon and buff.icon or "Buff") .. ".png"
        else
            buff.icon = "data/textures/icons/buffs/" .. (buff.icon and buff.icon or Helper.BonusNameByIndex[buff.stat]) .. ".png"
            -- check if it's a debuff, only simple buffs can be detected as positive/negative
            if buff.stat == StatsBonuses.HyperspaceCooldown
              or buff.stat == StatsBonuses.HyperspaceRechargeEnergy
              or buff.stat == StatsBonuses.ShieldTimeUntilRechargeAfterHit
              or buff.stat == StatsBonuses.ShieldTimeUntilRechargeAfterDepletion
              or buff.stat == StatsBonuses.PilotsPerFighter
              or buff.stat == StatsBonuses.MinersPerTurret
              or buff.stat == StatsBonuses.GunnersPerTurret
              or buff.stat == StatsBonuses.MechanicsPerTurret then
                if buff.type == 2 then
                    buff.isDebuff = buff.value > 1
                else
                    buff.isDebuff = buff.value > 0
                end
            else
                if buff.type == 2 then
                    buff.isDebuff = buff.value < 1
                else
                    buff.isDebuff = buff.value < 0
                end
            end
        end
        -- description
        if not buff.desc then
            buff.desc = buffDescriptions[buff.name]
        else
            buff.desc = buff.desc%_t
        end
        if buff.desc then
            if buff.descArgs then
                buff.desc = buff.desc % buff.descArgs
            end
            buff.desc = buff.desc:split("\n")
        end
        -- name
        buff.name = buff.name%_t
        newbuffs[buffsCount] = buff
    end
    -- sort buffs by priority
    table.sort(newbuffs, function(a, b)
        local aprio = a.prio or 0
        local bprio = b.prio or 0
        if aprio > bprio then
            return true
        elseif aprio == bprio then
            return a.name < b.name
        end
    end)
    buffs = newbuffs
end

-- FUNCTIONS --

function BuffsMod.getHideShipIconsOverlay()
    return Config.HideShipIconsOverlay
end

-- API --

function BuffsMod.getBuffs()
    return buffs and table.deepcopy(buffs) or {}
end

function BuffsMod.getBuff(name, type)
    if type and buffPrefixes[type] then
        name = buffPrefixes[type] .. name
        local buff = buffs[name]
        return buff and table.deepcopy(buff) or nil
    end
    for _, buff in pairs(buffs) do
        if buff.name == name then
            return table.deepcopy(buff)
        end
    end
end


else -- onServer


data = {
  buffs = {}
}
pending = {} -- functions that modders tried to call before `restore`

-- PREDEFINED --

function BuffsMod.getUpdateInterval()
    return Config.UpdateInterval
end

function BuffsMod.initialize()
    local player = Player()
    -- if script was just added, it will not have 
    isReady = player:getValue("Buffs") == nil
    if isReady then
        isFirstLaunch = true
        player:setValue("Buffs", true)
        player:sendCallback("onBuffsReady", player.index, {}, true, false)
    end
end

function BuffsMod.onRemove()
    local player = Player()
    Log:Info("'%s'(%i): onRemove fired for some reason", player.name, player.index)
    -- in case something happens and script will be removed, reset 'Buffs'
    player:setValue("Buffs")
end

function BuffsMod.update(timePassed)
    local canFixEffects = true
    for name, buff in pairs(data.buffs) do
        if buff.duration ~= -1 then -- decay duration and remove buffs
            buff.duration = math.max(0, buff.duration - timePassed)
            if buff.duration == 0 then
                BuffsMod.removeBuffWithType(name)
            end
        end
        -- check if player should have any custom effects
        if data.fixEffects and canFixEffects and buff and buff.duration ~= 0 and buff.type == 5 then
            for _, effect in ipairs(buff.effects) do
                if effect.playerScript then
                    canFixEffects = false
                    break
                end
            end
        end
    end
    if data.fixEffects and canFixEffects then -- some custom effect scripts weren't removed when needed, trying to fix this
        local player = Player()
        Log:Info("'%s'(%i): Trying to remove old custom effects", player.name, player.index)
        local scripts = player:getScripts()
        for index, path in pairs(scripts) do
            if string.find(path, "data/scripts/player/buffs/", 1, true) then
                Log:Debug("'%s'(%i): Removing old effect script %i: %s", player.name, player.index, index, path)
                player:removeScript(path)
            end
        end
        data.fixEffects = nil
    end
end

function BuffsMod.secure()
    local player = Player()
    Log:Debug("'%s'(%i): Secure", player.name, player.index)

    return data
end

function BuffsMod.restore(_data)
    local player = Player()
    Log:Debug("'%s'(%i): Restore", player.name, player.index)
    data = _data or {
      buffs = {}
    }
    if not isReady then -- check for pending buffs
        -- apply pending buffs
        isReady = true
        for _, v in ipairs(pending) do
            BuffsMod[v.func](unpack(v.args))
        end
        pending = nil
        player:sendCallback("onBuffsReady", player.index, table.deepcopy(data.buffs), false, false)
        BuffsMod.refreshData()
    end
end

-- CALLABLE --

function BuffsMod.refreshData()
    invokeClientFunction(Player(), "receiveData", BuffsMod.prepareClientBuffs())
end
callable(BuffsMod, "refreshData")

-- FUNCTIONS --

function BuffsMod.prepareClientBuffs()
    local clientBuffs = {}
    for fullname, buff in pairs(data.buffs) do
        if buff.prio ~= -1000 then -- don't send hidden buffs
            clientBuffs[fullname] = buff
        end
    end
    return clientBuffs
end

-- NEVER call this function via 'BuffsMod._addBuff'. Use 'BuffsHelper.addBuff' from the BuffsHelper.lua
function BuffsMod._addBuff(name, effects, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority)
    if not isReady then -- add to pending operations
        pending[#pending+1] = {
          func = "_addBuff",
          args = {name, effects, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority}
        }
        return nil, 0
    end
    if string.find(name, '.', 1, true) then return nil, 1 end -- names can't contain '.'
    if not duration or duration < 0 then duration = -1 end
    if not applyMode then applyMode = 1 end
    if duration == -1 then -- can't use 'Combine' when duration is infinite
        if applyMode == 3 then applyMode = 2
        elseif applyMode == 5 then applyMode = 4 end
    end
    local fullname = "B_"..name
    if string.sub(name, 1, 1) == "_" then -- if a buff name starts with _, it's a hidden buff
        priority = -1000
    end

    local buff = data.buffs[fullname]
    if applyMode == 1 and buff then return false end -- already exists
    if applyMode >= 4 and not buff then return false end -- doesn't exist
    local player = Player()
    if not buff then
        local scripts
        local shipEffects = {}
        for i, effect in ipairs(effects) do
            if effect[1] then -- support for a short-hand for vanilla stats
                effect = { type = effect[1], stat = effect[2], value = effect[3] }
                effects[i] = effect
            end
            if effect.playerScript then -- custom player script
                if not effect.args then effect.args = {} end
                if not scripts then scripts = player:getScripts() end
                player:addScript("data/scripts/player/buffs/"..effect.playerScript..".lua", unpack(effect.args))
                local newScripts = player:getScripts()
                for j, _ in pairs(newScripts) do -- check the difference between old and new script indexes
                    if not scripts[j] then
                        effect.index = j
                        break
                    end
                end
                Log:Debug("'%s'(%i): _addBuff, script effect.index: %i", player.name, player.index, effect.index or -1)
                scripts = newScripts
            elseif effect.customStat and (effect.target == Helper.Target.Player or effect.target == Helper.Target.Both) then -- custom stat
                local playerStat = Helper.Stats[effect.customStat]
                if playerStat then
                    playerStat.onApply(player, nil, unpack(effect.args))
                end
            end
            if effect.type or effect.script or (effect.customStat and effect.target ~= Helper.Target.Player) then -- effects that will be transferred to a piloted ship
                shipEffects[#shipEffects + 1] = effect
            end
        end
        buff = {
          name = name,
          effects = effects,
          shipEffects = shipEffects,
          duration = duration,
          --isAbsolute = nil, -- Player-buffs don't support that
          icon = icon,
          desc = description,
          descArgs = descArgs,
          color = color,
          lowColor = lowDurationColor,
          prio = priority,
          type = 5
        }
        data.buffs[fullname] = buff
        player:sendCallback("onBuffApplied", player.index, 5, applyMode, table.deepcopy(buff))
    else
        local modified = {
          duration = buff.duration
        }
        if applyMode == 2 or applyMode == 4 then
            buff.duration = duration
        elseif applyMode == 3 or applyMode == 5 then
            buff.duration = buff.duration + duration
        end
        -- refresh other stats just in case
        if icon then
            modified.icon = buff.icon
            buff.icon = icon
        end
        if description then
            modified.desc = buff.desc
            buff.desc = description
        end
        if descArgs then
            modified.descArgs = buff.descArgs
            buff.descArgs = descArgs
        end
        if color then
            modified.color = buff.color
            buff.color = color
        end
        if lowDurationColor then
            modified.lowColor = buff.lowColor
            buff.lowColor = lowDurationColor
        end
        if priority then
            modified.prio = buff.prio
            buff.prio = priority
        end
        player:sendCallback("onBuffApplied", player.index, 5, applyMode, table.deepcopy(buff), modified)
    end
    BuffsMod.addTiedBuff(buff) -- Apply buff to the current entity
    BuffsMod.refreshData()
    return true
end

-- NEVER call this function via 'BuffsMod._addBaseMultiplier'. Use 'BuffsHelper.addBaseMultiplier' from the BuffsHelper.lua
function BuffsMod._addBaseMultiplier(name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority)
    if not isReady then -- add to pending operations
        pending[#pending+1] = {
          func = "_addBaseMultiplier",
          args = {name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority}
        }
        return nil, 0
    end
    if string.find(name, '.', 1, true) then return nil, 1 end -- names can't contain '.'
    if not duration or duration < 0 then duration = -1 end
    if not applyMode then applyMode = 1 end
    if duration == -1 then
        if applyMode == 3 then applyMode = 2
        elseif applyMode == 5 then applyMode = 4 end
    end
    local fullname = "BM_"..name
    if string.sub(name, 1, 1) == "_" then -- if a buff name starts with _, it's a hidden buff
        priority = -1000
    end

    local buff = data.buffs[fullname]
    if applyMode == 1 and buff then return false end -- already exists
    if applyMode >= 4 and not buff then return false end -- doesn't exist
    local player = Player()
    if not buff then
        buff = {
          name = name,
          stat = stat,
          value = value,
          duration = duration,
          --isAbsolute = isAbsoluteDecay and true or nil,
          icon = icon,
          desc = description,
          descArgs = descArgs,
          color = color,
          lowColor = lowDurationColor,
          prio = priority,
          type = 1
        }
        data.buffs[fullname] = buff
        player:sendCallback("onBuffApplied", player.index, 1, applyMode, table.deepcopy(buff))
    else
        local modified = {
          duration = buff.duration
        }
        if applyMode == 2 or applyMode == 4 then
            buff.duration = duration
        elseif applyMode == 3 or applyMode == 5 then
            buff.duration = buff.duration + duration
        end
        -- refresh other stats just in case
        if icon then
            modified.icon = buff.icon
            buff.icon = icon
        end
        if description then
            modified.desc = buff.desc
            buff.desc = description
        end
        if descArgs then
            modified.descArgs = buff.descArgs
            buff.descArgs = descArgs
        end
        if color then
            modified.color = buff.color
            buff.color = color
        end
        if lowDurationColor then
            modified.lowColor = buff.lowColor
            buff.lowColor = lowDurationColor
        end
        if priority then
            modified.prio = buff.prio
            buff.prio = priority
        end
        player:sendCallback("onBuffApplied", player.index, 1, applyMode, table.deepcopy(buff), modified)
    end
    BuffsMod.addTiedBuff(buff) -- Apply buff to the current entity
    BuffsMod.refreshData()
    return true
end

-- NEVER call this function via 'BuffsMod._addMultiplier'. Use 'BuffsHelper.addMultiplier' from the BuffsHelper.lua
function BuffsMod._addMultiplier(name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority)
    if not isReady then -- add to pending operations
        pending[#pending+1] = {
          func = "_addMultiplier",
          args = {name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority}
        }
        return nil, 0
    end
    if string.find(name, '.', 1, true) then return nil, 1 end -- names can't contain '.'
    if not duration or duration < 0 then duration = -1 end
    if not applyMode then applyMode = 1 end
    if duration == -1 then
        if applyMode == 3 then applyMode = 2
        elseif applyMode == 5 then applyMode = 4 end
    end
    local fullname = "M_"..name
    if string.sub(name, 1, 1) == "_" then -- if a buff name starts with _, it's a hidden buff
        priority = -1000
    end

    local buff = data.buffs[fullname]
    if applyMode == 1 and buff then return false end -- already exists
    if applyMode >= 4 and not buff then return false end -- doesn't exist
    local player = Player()
    if not buff then
        buff = {
          name = name,
          stat = stat,
          value = value,
          duration = duration,
          --isAbsolute = isAbsoluteDecay and true or nil,
          icon = icon,
          desc = description,
          descArgs = descArgs,
          color = color,
          lowColor = lowDurationColor,
          prio = priority,
          type = 2
        }
        data.buffs[fullname] = buff
        player:sendCallback("onBuffApplied", player.index, 2, applyMode, table.deepcopy(buff))
    else
        local modified = {
          duration = buff.duration
        }
        if applyMode == 2 or applyMode == 4 then
            buff.duration = duration
        elseif applyMode == 3 or applyMode == 5 then
            buff.duration = buff.duration + duration
        end
        -- refresh other stats just in case
        if icon then
            modified.icon = buff.icon
            buff.icon = icon
        end
        if description then
            modified.desc = buff.desc
            buff.desc = description
        end
        if descArgs then
            modified.descArgs = buff.descArgs
            buff.descArgs = descArgs
        end
        if color then
            modified.color = buff.color
            buff.color = color
        end
        if lowDurationColor then
            modified.lowColor = buff.lowColor
            buff.lowColor = lowDurationColor
        end
        if priority then
            modified.prio = buff.prio
            buff.prio = priority
        end
        player:sendCallback("onBuffApplied", player.index, 2, applyMode, table.deepcopy(buff), modified)
    end
    BuffsMod.addTiedBuff(buff)
    BuffsMod.refreshData()
    return true
end

-- NEVER call this function via 'BuffsMod._addMultiplyableBias'. Use 'BuffsHelper.addMultiplyableBias' from the BuffsHelper.lua
function BuffsMod._addMultiplyableBias(name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority)
    if not isReady then -- add to pending operations
        pending[#pending+1] = {
          func = "_addMultiplyableBias",
          args = {name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority}
        }
        return nil, 0
    end
    if string.find(name, '.', 1, true) then return nil, 1 end -- names can't contain '.'
    if not duration or duration < 0 then duration = -1 end
    if not applyMode then applyMode = 1 end
    if duration == -1 then
        if applyMode == 3 then applyMode = 2
        elseif applyMode == 5 then applyMode = 4 end
    end
    local fullname = "MB_"..name
    if string.sub(name, 1, 1) == "_" then -- if a buff name starts with _, it's a hidden buff
        priority = -1000
    end

    local buff = data.buffs[fullname]
    if applyMode == 1 and buff then return false end -- already exists
    if applyMode >= 4 and not buff then return false end -- doesn't exist
    local player = Player()
    if not buff then
        buff = {
          name = name,
          stat = stat,
          value = value,
          duration = duration,
          --isAbsolute = isAbsoluteDecay and true or nil,
          icon = icon,
          desc = description,
          descArgs = descArgs,
          color = color,
          lowColor = lowDurationColor,
          prio = priority,
          type = 3
        }
        data.buffs[fullname] = buff
        player:sendCallback("onBuffApplied", player.index, 3, applyMode, table.deepcopy(buff))
    else
        local modified = {
          duration = buff.duration
        }
        if applyMode == 2 or applyMode == 4 then
            buff.duration = duration
        elseif applyMode == 3 or applyMode == 5 then
            buff.duration = buff.duration + duration
        end
        -- refresh other stats just in case
        if icon then
            modified.icon = buff.icon
            buff.icon = icon
        end
        if description then
            modified.desc = buff.desc
            buff.desc = description
        end
        if descArgs then
            modified.descArgs = buff.descArgs
            buff.descArgs = descArgs
        end
        if color then
            modified.color = buff.color
            buff.color = color
        end
        if lowDurationColor then
            modified.lowColor = buff.lowColor
            buff.lowColor = lowDurationColor
        end
        if priority then
            modified.prio = buff.prio
            buff.prio = priority
        end
        player:sendCallback("onBuffApplied", player.index, 3, applyMode, table.deepcopy(buff), modified)
    end
    BuffsMod.addTiedBuff(buff)
    BuffsMod.refreshData()
    return true
end

-- NEVER call this function via 'BuffsMod._addAbsoluteBias'. Use 'BuffsHelper.addAbsoluteBias' from the BuffsHelper.lua
function BuffsMod._addAbsoluteBias(name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority)
    if not isReady then -- add to pending operations
        pending[#pending+1] = {
          func = "_addAbsoluteBias",
          args = {name, stat, value, duration, applyMode, isAbsoluteDecay, icon, description, descArgs, color, lowDurationColor, priority}
        }
        return nil, 0
    end
    if string.find(name, '.', 1, true) then return nil, 1 end -- names can't contain '.'
    if not duration or duration < 0 then duration = -1 end
    if not applyMode then applyMode = 1 end
    if duration == -1 then
        if applyMode == 3 then applyMode = 2
        elseif applyMode == 5 then applyMode = 4 end
    end
    local fullname = "AB_"..name
    if string.sub(name, 1, 1) == "_" then -- if a buff name starts with _, it's a hidden buff
        priority = -1000
    end

    local buff = data.buffs[fullname]
    if applyMode == 1 and buff then return false end -- already exists
    if applyMode >= 4 and not buff then return false end -- doesn't exist
    local player = Player()
    if not buff then
        buff = {
          name = name,
          stat = stat,
          value = value,
          duration = duration,
          --isAbsolute = isAbsoluteDecay and true or nil,
          icon = icon,
          desc = description,
          descArgs = descArgs,
          color = color,
          lowColor = lowDurationColor,
          prio = priority,
          type = 4
        }
        data.buffs[fullname] = buff
        player:sendCallback("onBuffApplied", player.index, 4, applyMode, table.deepcopy(buff))
    else
        local modified = {
          duration = buff.duration
        }
        if applyMode == 2 or applyMode == 4 then
            buff.duration = duration
        elseif applyMode == 3 or applyMode == 5 then
            buff.duration = buff.duration + duration
        end
        -- refresh other stats just in case
        if icon then
            modified.icon = buff.icon
            buff.icon = icon
        end
        if description then
            modified.desc = buff.desc
            buff.desc = description
        end
        if descArgs then
            modified.descArgs = buff.descArgs
            buff.descArgs = descArgs
        end
        if color then
            modified.color = buff.color
            buff.color = color
        end
        if lowDurationColor then
            modified.lowColor = buff.lowColor
            buff.lowColor = lowDurationColor
        end
        if priority then
            modified.prio = buff.prio
            buff.prio = priority
        end
        player:sendCallback("onBuffApplied", player.index, 4, applyMode, table.deepcopy(buff), modified)
    end
    BuffsMod.addTiedBuff(buff)
    BuffsMod.refreshData()
    return true
end

function BuffsMod.addTiedBuff(buff)
    local player = Player()
    local entity = player.craft
    if not entity or not (entity.type == EntityType.Ship or entity.type == EntityType.Station) then return end

    if buff.type == 5 then -- complex buff
        if #buff.shipEffects > 0 then
            Helper.addBuff(entity, buff.name, buff.shipEffects, buff.duration, Helper.Mode.AddOrRefresh, nil, buff.icon, buff.desc, buff.descArgs, buff.color, buff.lowColor, buff.prio, player.index)
        end
    else
        local funcs = {"addBaseMultiplier", "addMultiplier", "addMultiplyableBias", "addAbsoluteBias"}
        Helper[funcs[buff.type]](entity, buff.name, buff.stat, buff.value, buff.duration, Helper.Mode.AddOrRefresh, nil, buff.icon, buff.desc, buff.descArgs, buff.color, buff.lowColor, buff.prio, player.index)
    end
end

-- API --
-- The following functions CAN be used directly ('BuffsMod.removeBuff') and via BuffsHelper.lua (BuffsHelper.removeBuff)
function BuffsMod.removeBuff(name)
    return BuffsMod.removeBuffWithType("B_"..name)
end

function BuffsMod.removeBaseMultiplier(name)
    return BuffsMod.removeBuffWithType("BM_"..name)
end

function BuffsMod.removeMultiplier(name)
    return BuffsMod.removeBuffWithType("M_"..name)
end

function BuffsMod.removeMultiplyableBias(name)
    return BuffsMod.removeBuffWithType("MB_"..name)
end

function BuffsMod.removeAbsoluteBias(name)
    return BuffsMod.removeBuffWithType("AB_"..name)
end

function BuffsMod.removeBuffWithType(fullname, buffType)
    if not isReady then -- add to pending operations
        pending[#pending+1] = {
          func = "removeBuffWithType",
          args = {fullname, buffType}
        }
        return nil, 0
    end
    if string.find(fullname, '.', 1, true) then return nil, 1 end -- names can't contain '.'
    if buffType then
        local prefix = buffPrefixes[buffType]
        if prefix then
            fullname = prefix..fullname
        end
    end
    local buff = data.buffs[fullname]
    if not buff then return false end -- can't find
    local player = Player()
    if buff.type == 5 then -- remove all bonuses
        local scripts
        for _, effect in ipairs(buff.effects) do
            if effect.playerScript then -- custom player script
                if effect.index then
                    if not scripts then scripts = player:getScripts() end
                    local effectScript = "data/scripts/player/buffs/"..effect.playerScript..".lua"
                    local script = scripts[effect.index]
                    if script and string.find(script, effectScript, 1, true) then
                        player:removeScript(effect.index)
                        Log:Debug("'%s'(%i): Removing buff script: %i", player.name, player.index, effect.index)
                    else
                        Log:Error("'%s'(%i): Couldn't remove buff script '%i', paths don't match: '%s' ~= '%s' - will be automatically fixed when possible", player.name, player.index, effect.index, effectScript, script or "")
                        data.fixEffects = true
                    end
                end
            elseif effect.customStat and (effect.target == Helper.Target.Player or effect.target == Helper.Target.Both) then -- custom stat
                local playerStat = Helper.Stats[effect.customStat]
                if playerStat then
                    playerStat.onRemove(player, nil, unpack(effect.args))
                end
            end
        end
    end
    player:sendCallback("onBuffRemoved", player.index, buff.type, table.deepcopy(buff))

    -- remove tied buff
    local entity = player.craft
    if entity and (entity.type == EntityType.Ship or entity.type == EntityType.Station) then
        if buff.type == 5 then -- complex buff
            if #buff.shipEffects > 0 then
                Helper.removeBuffWithType(entity, "B_"..buff.name)
            end
        else
            Helper.removeBuffWithType(entity, buff.name, buff.type)
        end
    end

    data.buffs[fullname] = nil
    BuffsMod.refreshData()
    return true
end

function BuffsMod.getBuffs()
    if not isReady then return {}, 0 end
    local r = {}
    for _, buff in pairs(data.buffs) do
        r[#r+1] = table.deepcopy(buff)
    end
    return r
end

function BuffsMod.getBuff(name, type)
    if not isReady then return nil, 0 end
    if string.find(name, '.', 1, true) then return nil, 1 end -- names can't contain '.'
    if type and buffPrefixes[type] then
        name = buffPrefixes[type] .. name
        local buff = data.buffs[name]
        return buff and table.deepcopy(buff) or nil
    end
    for _, buff in pairs(data.buffs) do
        if buff.name == name then
            return table.deepcopy(buff)
        end
    end
end

function BuffsMod.isReady()
    return isReady
end


end