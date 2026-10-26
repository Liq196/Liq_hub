-- [[ Blox Fruits Update 30: Ultimate Fruit Sniper & Server Hop ]]
-- [[ Полная адаптация под патч от 26.10.2026 ]]

local Fluent = loadstring(game:HttpGet("https://github.com"))()

local Window = Fluent:CreateWindow({
    Title = "Blox Fruits (Update 30) - Fruit Sniper GUI",
    SubTitle = "by AI Developer",
    TabWidth = 200,
    Size = Vector2.new(580, 460),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- [[ Config & States ]]
local Options = Fluent.Options
_G.AutoFindFruits = false
_G.FruitFilter = {}

-- ИСПРАВЛЕНО: Актуальный список фруктов Update 30 (Добавлен Magnet, Leopard заменен на Tiger)
local FruitList = {
    Common = {"Rocket", "Spin", "Chop", "Spring", "Bomb", "Smoke", "Spike"},
    Uncommon = {"Flame", "Falcon", "Ice", "Sand", "Dark", "Diamond", "Light"},
    Rare = {"Rubber", "Barrier", "Ghost", "Magma", "Quake", "Buddha", "Love", "Spider"},
    Legendary = {"Sound", "Phoenix", "Portal", "Rumble", "Pain", "Blizzard", "Gravity"},
    Mythical = {"Mammoth", "T-Rex", "Dough", "Shadow", "Venom", "Control", "Spirit", "Dragon", "Tiger", "Kitsune", "Magnet"}
}

for _, rarityGroup in pairs(FruitList) do
    for _, fruitName in ipairs(rarityGroup) do
        _G.FruitFilter[fruitName] = false
    end
end

-- [[ Tabs Setup ]]
local Tabs = {
    Main = Window:AddTab({ Title = "Main Sniper", Icon = "home" }),
    Filter = Window:AddTab({ Title = "Fruit Filter", Icon = "check-square" }),
    Settings = Window:AddTab({ Title = "Server Hop Settings", Icon = "settings" })
}

local ToggleSniper = Tabs.Main:AddToggle("AutoFindFruits", {Title = "Auto Find Fruits", Default = false})
ToggleSniper:OnChanged(function()
    _G.AutoFindFruits = Options.AutoFindFruits.Value
end)

-- [[ Functions ]]
local function IsFilteredFruit(fruitName)
    for name, isChecked in pairs(_G.FruitFilter) do
        if string.find(string.lower(fruitName), string.lower(name)) and isChecked then
            return true
        end
    end
    return false
end

-- ИСПРАВЛЕНО: Безопасный полет к фрукту во избежание детекта античитом Update 30
local function SafeFlyToFruit(targetPos)
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local root = character:WaitForChild("HumanoidRootPart", 10)
    
    if root then
        -- Летим чуть выше фрукта (на 3 студа), а не под текстурами карты
        local safePos = Vector3.new(targetPos.X, targetPos.Y + 3, targetPos.Z)
        local distance = (root.Position - safePos).Magnitude
        local duration = distance / 300 -- Оптимальная скорость для обхода проверки на телепорт
        
        local tweenService = game:GetService("TweenService")
        local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
        local tween = tweenService:Create(root, tweenInfo, {CFrame = CFrame.new(safePos)})
        
        tween:Play()
        tween.Completed:Wait()
        task.wait(0.3)
    end
end

-- ИСПРАВЛЕНО: Рабочий Server Hop через RoProxy для обхода блокировок Roblox API
local function SmartServerHop()
    Fluent:Notify({ Title = "Server Hop", Content = "Поиск подходящего сервера...", Duration = 4 })
    task.wait(2)
    
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local PlaceId = game.PlaceId
    
    local success, result = pcall(function()
        local url = string.format("https://roproxy.com", tostring(PlaceId))
        local response = game:HttpGet(url)
        local servers = HttpService:JSONDecode(response)
        
        for _, server in pairs(servers.data) do
            if server.playing and server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(PlaceId, server.id, game.Players.LocalPlayer)
                return
            end
        end
    end)
    
    if not success then
        Fluent:Notify({ Title = "Error", Content = "Ошибка поиска сервера. Повтор через 5 сек...", Duration = 3 })
        task.wait(5)
        SmartServerHop()
    end
end

-- [[ Sniper Thread Logic ]]
task.spawn(function()
    while task.wait(2) do -- Задержка в 2 секунды необходима для прогрузки Workspace после прыжка
        if _G.AutoFindFruits then
            local fruitFound = false
            local workspaceItems = workspace:GetChildren()
            
            for _, item in ipairs(workspaceItems) do
                -- ИСПРАВЛЕНО: Поиск как по типу Tool, так и по типу Model (спавн на земле)
                if (item:IsA("Tool") or item:IsA("Model")) and string.find(item.Name, "Fruit") then
                    if IsFilteredFruit(item.Name) then
                        local handle = item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart")
                        if handle then
                            fruitFound = true
                            Fluent:Notify({ Title = "Fruit Target", Content = "Обнаружен фрукт: " .. item.Name, Duration = 5 })
                            
                            -- Безопасное перемещение
                            SafeFlyToFruit(handle.Position)
                            
                            -- ИСПРАВЛЕНО: Безопасный вызов ремоута хранения через pcall (передается только имя)
                            pcall(function()
                                game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("StoreFruit", item.Name)
                            end)
                            task.wait(0.5)
                        end
                    end
                end
            end
            
            -- Если на сервере чисто — уходим на следующий
            if not fruitFound then
                SmartServerHop()
                break
            end
        end
    end
end)

-- [[ Fruit Filter Tab ]]
local function CreateRaritySection(rarityName, fruits)
    Tabs.Filter:AddParagraph({ Title = rarityName .. " Fruits", Content = "Нажмите для автосбора:" })
    for _, fruit in ipairs(fruits) do
        local toggle = Tabs.Filter:AddToggle(fruit, {Title = fruit .. " Fruit", Default = false})
        toggle:OnChanged(function()
            _G.FruitFilter[fruit] = Options[fruit].Value
        end)
    end
end

CreateRaritySection("Mythical", FruitList.Mythical)
CreateRaritySection("Legendary", FruitList.Legendary)
CreateRaritySection("Rare", FruitList.Rare)
CreateRaritySection("Uncommon", FruitList.Uncommon)
CreateRaritySection("Common", FruitList.Common)

-- [[ Settings Tab ]]
Tabs.Settings:AddButton({
    Title = "Instant Server Hop",
    Description = "Принудительно сменить сервер прямо сейчас",
    Callback = function()
        SmartServerHop()
    end
})

Window:SelectTab(1)
Fluent:Notify({ Title = "Interface Loaded", Content = "Снайпер готов к работе в Update 30!", Duration = 5 })
