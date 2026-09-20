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
                tooltip:AddLine("Левый клик: Вывести сообщение в чат", 0.7, 0.7, 0.7)
                tooltip:AddLine("Правый клик: Скрыть иконку", 0.7, 0.7, 0.7)
            end,

            OnClick = function(_, button)
                if button == "LeftButton" then
                    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Artisan]:|r Привет! Ты нажал на кнопку!")

                    if Artisan.window then
                        if Artisan.window:IsShown() then
                            Artisan.window:Hide()
                        else
                            Artisan.window:Show()
                        end
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