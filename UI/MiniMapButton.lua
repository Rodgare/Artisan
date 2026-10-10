local addonName, Artisan = ...

local mainFrame = CreateFrame("Frame")

mainFrame:RegisterEvent("ADDON_LOADED")

mainFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "Artisan" then
        if not ArtisanDB then
            ArtisanDB = {
                minimap = { hide = false }
            }
        end
        local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("Artisan", {
            type = "data source",
            text = "Artisan",
            icon = "Interface\\AddOns\\Artisan\\Textures\\minimap_icon_coin.tga",

            OnTooltipShow = function(tooltip)
                tooltip:AddLine("Artisan", 1, 1, 1)
                tooltip:AddLine("ЛКМ: Открыть главное окно ", 0.7, 0.7, 0.7)
                -- tooltip:AddLine("Правый клик: Скрыть иконку", 0.7, 0.7, 0.7)
            end,

            OnClick = function(_, button)
                if button == "LeftButton" then
                    if not (Artisan.UI and Artisan.UI.MainFrame) then
                        Artisan.UI:CreateMainWindow()
                    end

                    local frame = Artisan.UI.MainFrame
                    if frame:IsShown() then
                        frame:Hide()
                    else
                        frame:Show()
                    end
                elseif button == "RightButton" then
                    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Artisan]:|r Иконку можно вернуть командой в чате.")
                end
            end,
        })

        local iconLib = LibStub("LibDBIcon-1.0")
        iconLib:Register("Artisan", LDB, ArtisanDB.minimap)
    end
end)
