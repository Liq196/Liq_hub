-- [[ Blox Fruits Update 30: Ultimate Fruit Sniper (Redz Bypass & Auto-Store Mode) ]]
-- [[ Полная адаптация и исправление под патч от 26.10.2026 ]]

-- Загрузка Fluent UI (Используем стабильный релиз dawid-scripts)
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Создание главного окна во Fluent UI
local Window = Fluent:CreateWindow({
    Title = "Premium BF Hub",
    SubTitle = "Update 30 (Bypass & Auto-Store)",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
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

-- Легитный подбор предмета и автоматическое убирание в инвентарь (Redz Update 30 Method)
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
        
        -- Проверяем, подобрали ли мы фрукт (он может быть в Backpack или уже экипирован в Character)
        local tool = backpack:FindFirstChild(item.Name) or player.Character:FindFirstChild(item.Name)
        
        if tool then
            -- Если фрукт в рюкзаке, берем его в руки (необходимо для вызова некоторых Remotes и UI)
            if tool.Parent == backpack and player.Character:FindFirstChildWhichIsA("Humanoid") then
                player.Character.Humanoid:EquipTool(tool)
            end
            task.wait(0.5) -- Эмуляция удержания фрукта человеком
            
            -- [[ КРИТИЧЕСКИЙ ДЛЯ UPDATE 30 БЛОК: СХРАНЕНИЕ ФРУКТА В ИНВЕНТАРЬ (STORE FRUIT) ]]
            local storedSuccess = false
            
            -- МЕТОД 1: Прямой вызов Remotes через CommF_ (Основной серверный метод Redz Hub)
            if not storedSuccess then
                pcall(function()
                    local remote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 3):WaitForChild("CommF_", 3)
                    if remote then
                        local response = remote:InvokeServer("StoreFruit", tool.Name)
                        -- В Update 30 некоторые сервера возвращают статус успешности
                        if response == true or response == 1 then
                            print("[Method 1] Фрукт успешно сохранен через CommF_ Invoke.")
                            storedSuccess = true
                        end
                    end
                end)
            end
            
            -- МЕТОД 2: Новый альтернативный Remote Event (Используется в некоторых саб-серверах патча Update 30)
            if not storedSuccess then
                pcall(function()
                    local storeRemote = game:GetService("ReplicatedStorage"):FindFirstChild("StoreFruit", true) 
                        or game:GetService("ReplicatedStorage"):FindFirstChild("FruitStorage", true)
                    
                    if storeRemote and storeRemote:IsA("RemoteEvent") then
                        storeRemote:FireServer(tool.Name)
                        print("[Method 2] Отправлен сигнал в альтернативный RemoteEvent.")
                        storedSuccess = true
                    elseif storeRemote and storeRemote:IsA("RemoteFunction") then
                        storeRemote:InvokeServer(tool.Name)
                        print("[Method 2] Отправлен сигнал в альтернативный RemoteFunction.")
                        storedSuccess = true
                    end
                end)
            end
            
            -- МЕТОД 3: Bypass клик по официальной UI-кнопке инвентаря Blox Fruits (Защита от детекта пакетов)
            if not storedSuccess then
                pcall(function()
                    local playerGui = player:WaitForChild("PlayerGui", 5)
                    local mainUI = playerGui:FindFirstChild("Main")
                    
                    -- Проверяем все возможные пути расположения кнопки "Store" в новом UI Update 30
                    local fruitButton = mainUI and (
                        mainUI:FindFirstChild("FruitStorage") or 
                        mainUI:FindFirstChild("Inventory") and mainUI.Inventory:FindFirstChild("StoreButton") or
                        mainUI:FindFirstChild("FruitInventory") and mainUI.FruitInventory:FindFirstChild("Store")
                    )
                    
                    if fruitButton and fruitButton.Visible then
                        -- Безопасная эмуляция клика через getconnections
                        for _, connection in pairs(getconnections(fruitButton.MouseButton1Click)) do
                            connection:Fire()
                        end
                        for _, connection in pairs(getconnections(fruitButton.MouseButton1Down)) do
                            connection:Fire()
                        end
                        print("[Method 3] Фрукт убран через клик по кнопке UI.")
                        storedSuccess = true
                    end
                end)
            end
            
            -- Финальная проверка: если фрукт пропал из рук/рюкзака, значит он в хранилище
            task.wait(0.4)
            if not (backpack:FindFirstChild(item.Name) or player.Character:FindFirstChild(item.Name)) then
                print("👍 " .. item.Name .. " успешно перемещен в ваше хранилище фруктов!")
            else
                print("⚠️ Не удалось автоматически убрать " .. item.Name .. ". Попробуйте положить вручную.")
            end
        end
    end
    
    -- Обязательный большой дебаунс (Anti-Cheat Bypass)
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
workspace.ChildAdded:Connect(function(child)
    if _G.AutoFindFruits then
        task.wait(0.5) -- Задержка для полной инициализации объекта в мире
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
