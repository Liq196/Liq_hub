-- [[ Blox Fruits Update 30: Ultimate Fruit Sniper & Server Hop ]]
-- [[ Полная адаптация и исправление под патч от 26.10.2026 ]]
-- [[ Переведено на Fluent UI Library специально для Delta / ПК-исполнителей ]]

-- Загрузка Fluent UI (Используем стабильный релиз dawid-scripts)
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Создание главного окна во Fluent UI
local Window = Fluent:CreateWindow({
    Title = "Premium BF Hub",
    SubTitle = "2026 Update (Fruit Sniper)",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false, -- Выключено для повышения FPS на мобильных устройствах
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl -- Кнопка сворачивания для ПК
})

-- [[ Config & States ]]
_G.AutoFindFruits = false
_G.FruitFilter = {}

-- Актуальный список фруктов Update 30
local FruitList = {
    Common = {"Rocket", "Spin", "Chop", "Spring", "Bomb", "Smoke", "Spike"},
    Uncommon = {"Flame", "Falcon", "Ice", "Sand", "Dark", "Diamond", "Light"},
    Rare = {"Rubber", "Barrier", "Ghost", "Magma", "Quake", "Buddha", "Love", "Spider"},
    Legendary = {"Sound", "Phoenix", "Portal", "Rumble", "Pain", "Blizzard", "Gravity"},
    Mythical = {"Mammoth", "T-Rex", "Dough", "Shadow", "Venom", "Control", "Spirit", "Dragon", "Tiger", "Kitsune", "Magnet"}
}

-- Инициализация фильтра фруктов
for _, rarityGroup in pairs(FruitList) do
    for _, fruitName in ipairs(rarityGroup) do
        _G.FruitFilter[fruitName] = false
    end
end

-- [[ Вкладки интерфейса Fluent ]]
local Tabs = {
    Main = Window:AddTab({ Title = "Main Sniper", Icon = "scroll" }),
    Filter = Window:AddTab({ Title = "Fruit Filter", Icon = "swords" }),
    Settings = Window:AddTab({ Title = "Server Hop", Icon = "user" })
}

-- [[ Элементы вкладки Main ]]
local MainToggle = Tabs.Main:AddToggle("AutoFindFruitsToggle", {
    Title = "Auto Find Fruits",
    Default = false,
    Callback = function(Value)
        _G.AutoFindFruits = Value
    end
})

-- [[ Functions: Movement & Server Hop ]]
local function IsFilteredFruit(fruitName)
    for name, isChecked in pairs(_G.FruitFilter) do
        if string.find(string.lower(fruitName), string.lower(name)) and isChecked then
            return true
        end
    end
    return false
end

-- Безопасный полет над землей для обхода жесткого античита Update 30
local function SafeFlyToFruit(targetPos)
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local root = character:WaitForChild("HumanoidRootPart", 10)
    
    if root then
        local safePos = Vector3.new(targetPos.X, targetPos.Y + 3, targetPos.Z)
        local distance = (root.Position - safePos).Magnitude
        local duration = distance / 300 -- Скорость 300 для минимизации флагов античита
        
        local tweenService = game:GetService("TweenService")
        local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
        local tween = tweenService:Create(root, tweenInfo, {CFrame = CFrame.new(safePos)})
        
        tween:Play()
        tween.Completed:Wait()
        task.wait(0.3)
    end
end

-- Перевод запросов на RoProxy API
local function SmartServerHop()
    print("Server Hop: Поиск подходящего публичного сервера...")
    task.wait(1)
    
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local PlaceId = game.PlaceId
    
    local success, result = pcall(function()
        -- Запрос через прокси (так как Roblox блокирует прямые запросы к своему API изнутри игры)
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
        print("Server Hop Error: ", result)
        task.wait(4)
        SmartServerHop()
    end
end

-- [[ Sniper Thread Logic ]]
task.spawn(function()
    while task.wait(2) do 
        if _G.AutoFindFruits then
            local fruitFound = false
            local workspaceItems = workspace:GetChildren()
            
            for _, item in ipairs(workspaceItems) do
                if (item:IsA("Tool") or item:IsA("Model")) and string.find(item.Name, "Fruit") then
                    if IsFilteredFruit(item.Name) then
                        local handle = item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart")
                        if handle then
                            fruitFound = true
                            print("Target Found: Движение к " .. item.Name)
                            
                            SafeFlyToFruit(handle.Position)
                            
                            pcall(function()
                                game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("StoreFruit", item.Name)
                            end)
                            task.wait(0.5)
                        end
                    end
                end
            end
            
            if not fruitFound then
                SmartServerHop()
                break
            end
        end
    end
end)

-- [[ Создание разделов фильтрации во вкладке Filter ]]
local function CreateRaritySection(rarityName, fruits)
    Tabs.Filter:AddParagraph({
        Title = "⚡ " .. rarityName .. " Fruits",
        Content = "Выберите фрукты для автоматического подбора"
    })
    for _, fruit in ipairs(fruits) do
        Tabs.Filter:AddToggle(fruit .. "FruitToggle", {
            Title = fruit .. " Fruit",
            Default = false,
            Callback = function(Value)
                _G.FruitFilter[fruit] = Value
            end
        })
    end
end

CreateRaritySection("Mythical", FruitList.Mythical)
CreateRaritySection("Legendary", FruitList.Legendary)
CreateRaritySection("Rare", FruitList.Rare)
CreateRaritySection("Uncommon", FruitList.Uncommon)
CreateRaritySection("Common", FruitList.Common)

-- [[ Настройки Server Hop ]]
Tabs.Settings:AddParagraph({
    Title = "Manual Navigation",
    Content = "Принудительное управление миграцией между серверами."
})

Tabs.Settings:AddButton({
    Title = "Instant Server Hop",
    Callback = function()
        SmartServerHop()
    end
})

-- Выбор первой вкладки при старте во Fluent UI
Window:SelectTab(Tabs.Main)
Fluent:Notify({
    Title = "Interface Loaded",
    Content = "Скрипт на базе Fluent UI успешно запущен!",
    Duration = 5
})
