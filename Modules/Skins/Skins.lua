local W, F, E, L = unpack(select(2, ...))
local LSM = E.Libs.LSM
local S = W:GetModule('Skins')

local _G = _G
local tinsert, xpcall, next, assert, format = tinsert, xpcall, next, assert, format
local CreateFrame = CreateFrame

S.allowBypass = {}
S.addonsToLoad = {}
S.nonAddonsToLoad = {}

function S:CreateShadow(frame, size, r, g, b)
    if not frame or frame.windStyle or frame.shadow then return end

    if frame:GetObjectType() == "Texture" then frame = frame:GetParent() end

    r = r or E.private.WT.skins.color.r or 0
    g = g or E.private.WT.skins.color.g or 0
    b = b or E.private.WT.skins.color.b or 0

    local shadow = CreateFrame('Frame', nil, frame)
    shadow:SetFrameLevel(1)
    shadow:SetFrameStrata(frame:GetFrameStrata())
    shadow:SetOutside(frame, size or 4, size or 4)
    shadow:SetBackdrop({edgeFile = LSM:Fetch('border', 'ElvUI GlowBorder'), edgeSize = E:Scale(size or 5)})
    shadow:SetBackdropColor(r, g, b, 0)
    shadow:SetBackdropBorderColor(r, g, b, 0.618)

    frame.shadow = shadow
    frame.windStyle = true
end

function S:CreateBackdropShadow(frame)
    if not frame or frame.windStyle then return end
    if noBackdrop then
        S:CreateShadow(frame)
    else
        if frame.backdrop then
            frame.backdrop:SetTemplate("Transparent")
            S:CreateShadow(frame.backdrop)
            frame.windStyle = true
        else
            F.DebugMessage(S, format("[1]无法找到 %s 的ElvUI美化背景！", frame:GetName() or "无名框体"))
        end
    end
end

function S:CreateBackdropShadowAfterElvUISkins(frame, tried)
    if not frame or frame.windStyle then return end

    tried = tried or 20

    if frame.backdrop then
        frame.backdrop:SetTemplate("Transparent")
        S:CreateShadow(frame.backdrop)
        frame.windStyle = true
    else
        if tried >= 0 then
            E:Delay(0.1, function() S:CreateBackdropShadowAfterElvUISkins(frame, tried - 1) end)
        else
            F.DebugMessage(S, format("[2]无法找到 %s 的ElvUI美化背景！", frame:GetName()))
        end
    end
end

function S:SetTransparentBackdrop(frame)
    if frame.backdrop then
        backdrop:SetTemplate("Transparent")
    else
        frame:CreateBackdrop("Transparent")
    end
end

function S:AddCallback(name, func, position)
    local load = (name == 'function' and name) or (not func and S[name])
    S:RegisterSkin('ElvUI_WindUI', load or func, nil, nil, position)
end

function S:AddCallbackForAddon(addonName, name, func, forceLoad, bypass, position)
    local load = (name == 'function' and name) or (not func and (S[name] or S[addonName]))
    S:RegisterSkin(addonName, load or func, forceLoad, bypass, position)
end

local function errorhandler(err) return _G.geterrorhandler()(err) end

function S:RegisterSkin(addonName, func, forceLoad, bypass, position)
    if bypass then self.allowBypass[addonName] = true end

    if forceLoad then
        xpcall(func, errorhandler)
        self.addonsToLoad[addonName] = nil
    elseif addonName == 'ElvUI_WindUI' then
        if position then
            tinsert(self.nonAddonsToLoad, position, func)
        else
            tinsert(self.nonAddonsToLoad, func)
        end
    else
        local addon = self.addonsToLoad[addonName]
        if not addon then
            self.addonsToLoad[addonName] = {}
            addon = self.addonsToLoad[addonName]
        end

        if position then
            tinsert(addon, position, func)
        else
            tinsert(addon, func)
        end
    end
end

function S:CallLoadedAddon(addonName, object)
    for _, func in next, object do xpcall(func, errorhandler) end

    self.addonsToLoad[addonName] = nil
end

function S:ADDON_LOADED(_, addonName)
    if not self.allowBypass[addonName] and not E.initialized then return end

    local object = self.addonsToLoad[addonName]
    if object then S:CallLoadedAddon(addonName, object) end
end

function S:Initialize()
    for index, func in next, self.nonAddonsToLoad do
        xpcall(func, errorhandler)
        self.nonAddonsToLoad[index] = nil
    end

    for addonName, object in pairs(self.addonsToLoad) do
        local isLoaded, isFinished = IsAddOnLoaded(addonName)
        if isLoaded and isFinished then S:CallLoadedAddon(addonName, object) end
    end
end

S:RegisterEvent('ADDON_LOADED')
W:RegisterModule(S:GetName())