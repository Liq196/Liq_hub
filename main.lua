-- [[ Blox Fruits Update 30: Ultimate Fruit Sniper & Server Hop ]]
-- [[ Полная адаптация и исправление под патч от 26.10.2026 ]]
-- [[ Оптимизировано для Delta Emulator и ПК-исполнителей ]]

-- ИСПРАВЛЕНО: Прямые и рабочие ссылки на официальные репозитории библиотек Fluent
local Fluent = loadstring(game:HttpGet("https://github.com"))()
local SaveManager = loadstring(game:HttpGet("https://githubusercontent.com"))()
local InterfaceManager = loadstring(game:HttpGet("https://githubusercontent.com"))()

local Window = Fluent:CreateWindow({
    Title = "Blox Fruits (Update 30) - Fruit Sniper GUI",
    SubTitle = "by Liq_hub Fixed",
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

-- ИСПРАВЛЕНО: Актуальный список фруктов Update 30 (Добавлен Magnet, Leopard заменен на Tiger из-за копирайтов)
local FruitList = {
    Common = {"Rocket", "Spin", "Chop", "Spring", "Bomb", "Smoke", "Spike"},
    Uncommon = {"Flame", "Falcon", "Ice", "Sand", "Dark", "Diamond", "Light"},
    Rare = {"Rubber", "Barrier", "Ghost", "Magma", "Quake", "Buddha", "Love", "Spider"},
    Legendary = {"Sound", "Phoenix", "Portal", "Rumble", "Pain", "Blizzard", "Gravity"},
    Mythical = {"Mammoth", "T-Rex", "Dough", "Shadow", "Venom", "Control", "Spirit", "Dragon", "Tiger", "Kitsune", "Magnet"}
}

-- Инициализация фильтра фруктов со значением false по умолчанию
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

-- [[ Main Tab Elements ]]
local ToggleSniper = Tabs.Main:AddToggle("AutoFindFruits", {Title = "Auto Find Fruits", Default = false})
ToggleSniper:OnChanged(function()
    _G.AutoFindFruits = Options.AutoFindFruits.Value
end)

-- [[ Functions: Movement & Server Hop ]]
local function IsFilteredFruit(fruitName)
    for name, isChecked in pairs(_G.FruitFilter) do
        if string.find(string.lower(fruitName), string.lower(name)) and isChecked then
            return true
        end
    end
    return false
end

-- ИСПРАВЛЕНО: Безопасный полет над землей (на 3 студа выше цели) для обхода жесткого античита Update 30
local function SafeFlyToFruit(targetPos)
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    -- ИСПРАВЛЕНО: Заменено несуществующее "HumanPart" на стандартный "HumanoidRootPart" с таймаутом
    local root = character:WaitForChild("HumanoidRootPart", 10)
    
    if root then
        local safePos = Vector3.new(targetPos.X, targetPos.Y + 3, targetPos.Z)
        local distance = (root.Position - safePos).Magnitude
        local duration = distance / 300 -- Скорость 300 условных единиц в секунду для минимизации флагов античита
        
        local tweenService = game:GetService("TweenService")
        local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
        local tween = tweenService:Create(root, tweenInfo, {CFrame = CFrame.new(safePos)})
        
        tween:Play()
        tween.Completed:Wait()
        task.wait(0.3)
    end
end

-- ИСПРАВЛЕНО: Перевод запросов на RoProxy API, так как Roblox блокирует прямые HTTP-запросы из игры
local function SmartServerHop()
    Fluent:Notify({ Title = "Server Hop", Content = "Поиск подходящего публичного сервера...", Duration = 4 })
    task.wait(2)
    
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local PlaceId = game.PlaceId
    
    local success, result = pcall(function()
        -- Корректный эндпоинт и использование прокси-сервера
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
        Fluent:Notify({ Title = "Error", Content = "Не удалось сменить сервер. Повторная попытка...", Duration = 3 })
        task.wait(4)
        SmartServerHop()
    end
end

-- [[ Sniper Thread Logic ]]
task.spawn(function()
    while task.wait(2) do -- Увеличена задержка до 2 сек, чтобы Workspace успевал прогрузиться при заходе на сервер
        if _G.AutoFindFruits then
            local fruitFound = false
            local workspaceItems = workspace:GetChildren()
            
            for _, item in ipairs(workspaceItems) do
                -- ИСПРАВЛЕНО: Сканирование как инструментов (Tool), так и спавнящихся на земле моделей (Model)
                if (item:IsA("Tool") or item:IsA("Model")) and string.find(item.Name, "Fruit") then
                    if IsFilteredFruit(item.Name) then
                        local handle = item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart")
                        if handle then
                            fruitFound = true
                            Fluent:Notify({ Title = "Target Found", Content = "Движение к: " .. item.Name, Duration = 5 })
                            
                            -- Плавное и безопасное перемещение
                            SafeFlyToFruit(handle.Position)
                            
                            -- ИСПРАВЛЕНО: Безопасное сохранение фрукта через pcall без передачи лишних аргументов
                            pcall(function()
                                game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("StoreFruit", item.Name)
                            end)
                            task.wait(0.5)
                        end
                    end
                end
            end
            
            -- Если на сервере нет целевых фруктов — автоматически уходим на другой
            if not fruitFound then
                SmartServerHop()
                break
            end
        end
    end
end)

-- [[ Fruit Filter Tab Elements ]]
local function CreateRaritySection(rarityName, fruits)
    Tabs.Filter:AddParagraph({ Title = rarityName .. " Fruits", Content = "Выберите фрукты для автоматического подбора" })
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

-- [[ Settings Tab Elements ]]
Tabs.Settings:AddParagraph({ Title = "Manual Navigation", Content = "Принудительное управление миграцией между серверами." })
Tabs.Settings:AddButton({
    Title = "Instant Server Hop",
    Description = "Мгновенно найти и переключиться на другой активный сервер",
    Callback = function()
        SmartServerHop()
    end
})

Window:SelectTab(1)
Fluent:Notify({ Title = "Interface Loaded", Content = "Скрипт успешно запущен и готов к работе!", Duration = 5 })
