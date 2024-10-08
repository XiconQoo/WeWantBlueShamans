local addonName,addonTable = ...

if CUSTOM_CLASS_COLORS then
    return
end

addonTable.postLoadFunctions = {}
CUSTOM_CLASS_COLORS = {}

local meta = {}

function meta:RegisterCallback(method, handler)
    -- Not Implemented, because changes don't happen currently
end

function meta:UnregisterCallback(method, handler)
    -- Not Implemented, because changes don't happen currently
end

local classes = {}
for class in pairs(RAID_CLASS_COLORS) do
    tinsert(classes, class)
end
sort(classes)

local classTokens = {}
for token, class in pairs(LOCALIZED_CLASS_NAMES_MALE) do
    classTokens[class] = token
end
for token, class in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
    classTokens[class] = token
end

function meta:GetClassToken(className)
    return className and classTokens[className]
end

function meta:ColorTextByClassToken(text, className)
    return self:ColorTextByClass(text, self:GetClassToken(className))
end

function meta:ColorTextByClass(text, class)
    local color = CUSTOM_CLASS_COLORS[class]
    if color then
        return color:WrapTextInColorCode(text)
    end
end

setmetatable(CUSTOM_CLASS_COLORS, { __index = meta })

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, addon)
    if addon ~= addonName then return end
    for i= 1, #classes do
        local class = classes[i]
        local color = RAID_CLASS_COLORS[class]
        local r, g, b = color.r, color.g, color.b

        if class == "SHAMAN" then
            r,g,b = 0,.44,.87
        end

        CUSTOM_CLASS_COLORS[class] = CreateColor(r,g,b)
        CUSTOM_CLASS_COLORS[class].colorStr = CUSTOM_CLASS_COLORS[class]:GenerateHexColor()
    end
    for _,func in pairs(addonTable.postLoadFunctions) do
        func()
    end
end)