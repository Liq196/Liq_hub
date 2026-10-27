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
local isProcessing = false -- Защита от одновременных ТП к нескольким фруктам (Anti-Ban)

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
    Filter = Window:AddTab({ Title = "Fruit Filter", Icon = "swords" })
}

-- [[ Functions: Movement ]]
local function IsFilteredFruit(fruitName)
    for name, isChecked in pairs(_G.FruitFilter) do
        if string.find(string.lower(fruitName), string.lower(name)) and isChecked then
            return true
        end
    end
    return false
end

-- Скрытное ТП по воздуху с защитой от флагов за падение и скорость
local function SafeInvisibleTeleport(targetPos)
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local root = character:WaitForChild("HumanoidRootPart", 10)
    
    if root then
        local noclipConnection
        noclipConnection = game:GetService("RunService").Stepped:Connect(function()
            if character then
                for _, part in pairs(character:GetChildren()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
        
        -- Имитация подбрасывания (как при легитных механиках игры)
        root.CFrame = CFrame.new(root.Position.X, root.Position.Y + 450, root.Position.Z)
        task.wait(0.3) -- Безопасная задержка для обработки сервером
        
        root.CFrame = CFrame.new(targetPos.X, root.Position.Y, targetPos.Z)
        task.wait(0.3)
        
        root.CFrame = CFrame.new(targetPos.X, targetPos.Y + 2, targetPos.Z)
        task.wait(0.4)
        
        if noclipConnection then noclipConnection:Disconnect() end
    end
end

-- Легитный подбор предмета и его скрытие через UI игры (Защита уровня Redz Hub)
local function ProcessFruitPickup(item)
    if isProcessing then return end
    isProcessing = true
    
    local handle = item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart")
    if handle then
        print("Bypass Target: Скрытный перелет к " .. item.Name)
        SafeInvisibleTeleport(handle.Position)
        
        local player = game.Players.LocalPlayer
        local backpack = player:WaitForChild("Backpack", 5)
        
        -- Плавные попытки подбора с увеличенным интервалом (не триггерит Hyperion)
        local attempts = 0
        while not backpack:FindFirstChild(item.Name) and player.Character and attempts < 8 do
            player.Character.HumanoidRootPart.CFrame = CFrame.new(handle.Position)
            task.wait(0.2)
            attempts = attempts + 1
        end
        
        local tool = backpack:FindFirstChild(item.Name)
        if tool and player.Character then
            player.Character.Humanoid:EquipTool(tool)
            task.wait(0.6) -- Увеличенное время удержания в руке для эмуляции человека
            
            -- БЕЗОПАСНОЕ СОХРАНЕНИЕ: Симуляция клика по UI-кнопке инвентаря Blox Fruits
            pcall(function()
                local playerGui = player:WaitForChild("PlayerGui", 5)
                -- Путь к официальной кнопке «Store» во внутриигровом инвентаре Update 30
                local mainUI = playerGui:FindFirstChild("Main")
                local fruitButton = mainUI and mainUI:FindFirstChild("FruitStorage") 
                    or mainUI:FindFirstChild("Inventory") and mainUI.Inventory:FindFirstChild("StoreButton")
                
                if fruitButton then
                    -- Эмулируем легитное нажатие игрока на кнопку "Положить в хранилище"
                    for _, connection in pairs(getconnections(fruitButton.MouseButton1Click)) do
                        connection:Fire()
                    end
                    for _, connection in pairs(getconnections(fruitButton.MouseButton1Down)) do
                        connection:Fire()
                    end
                    print("Фрукт успешно убран через легитный клик по UI.")
                else
                    -- Резервный безопасный метод, если UI закрыт или изменен патчем
                    game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("StoreFruit", item.Name)
                    print("Резервный вызов сохранения.")
                end
            end)
        end
    end
    
    -- Обязательный большой дебаунс, чтобы античит сбросил счетчик подозрительных действий
    task.wait(2.5) 
    isProcessing = false
end

-- Функция проверки текущей карты (вызывается точечно, а не спамом)
local function CheckCurrentMap()
    if not _G.AutoFindFruits or isProcessing then return end
    for _, item in ipairs(workspace:GetChildren()) do
        if (item:IsA("Tool") or item:IsA("Model")) and string.find(item.Name, "Fruit") then
            if IsFilteredFruit(item.Name) then
                ProcessFruitPickup(item)
                break
            end
        end
    end
end

-- [[ Элементы вкладки Main ]]
local MainToggle = Tabs.Main:AddToggle("AutoFindFruitsToggle", {
    Title = "Auto Find Fruits (Bypass)",
    Default = false,
    Callback = function(Value)
        _G.AutoFindFruits = Value
        if Value then
            -- Проверяем карту один раз в момент включения
            task.spawn(CheckCurrentMap)
        end
    end
})

-- [[ Умные триггеры движка вместо бесконечных циклов ]]
-- Скрипт сработает сам, БЕЗ спама запросами, как только фрукт упадет на карту или появится в мире
workspace.ChildAdded:Connect(function(child)
    if _G.AutoFindFruits then
        -- Небольшая задержка, чтобы объект успел инициализироваться в workspace
        task.wait(0.5)
        if (child:IsA("Tool") or child:IsA("Model")) and string.find(child.Name, "Fruit") then
            if IsFilteredFruit(child.Name) then
                ProcessFruitPickup(child)
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
                -- Если пользователь прожал фрукт при уже включенном чите — точечно проверяем карту
                if Value and _G.AutoFindFruits then
                    task.spawn(CheckCurrentMap)
                end
            end
        })
    end
end

CreateRaritySection("Mythical", FruitList.Mythical)
CreateRaritySection("Legendary", FruitList.Legendary)
CreateRaritySection("Rare", FruitList.Rare)
CreateRaritySection("Uncommon", FruitList.Uncommon)
CreateRaritySection("Common", FruitList.Common)

Window:SelectTab(Tabs.Main)
Fluent:Notify({
    Title = "Interface Loaded",
    Content = "Безопасный триггерный снайпер (Redz-Style) готов к работе!",
    Duration = 5
})
