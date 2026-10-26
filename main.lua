-- [[ Blox Fruits Update 30: Ultimate Fruit Sniper & Server Hop ]]
-- [[ Optimized for Delta Emulator ]]
-- [[ Instant Start Version - No Delay ]]

local Fluent = loadstring(game:HttpGet("https://github.com"))()
local SaveManager = loadstring(game:HttpGet("https://githubusercontent.com"))()
local InterfaceManager = loadstring(game:HttpGet("https://githubusercontent.com"))()

local Window = Fluent:CreateWindow({
    Title = "Blox Fruits - Fruit Sniper GUI",
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

-- All Fruits up to Update 30 categorized by Rarity
local FruitList = {
    Common = {"Rocket", "Spin", "Chop", "Spring", "Bomb", "Smoke", "Spike"},
    Uncommon = {"Flame", "Falcon", "Ice", "Sand", "Dark", "Diamond", "Light"},
    Rare = {"Rubber", "Barrier", "Ghost", "Magma", "Quake", "Buddha", "Love", "Spider"},
    Legendary = {"Sound", "Phoenix", "Portal", "Rumble", "Pain", "Blizzard", "Gravity"},
    Mythical = {"Mammoth", "T-Rex", "Dough", "Shadow", "Venom", "Control", "Spirit", "Dragon", "Leopard", "Kitsune"}
}

-- Populate filter with false by default
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

local function TeleportUnderMap(targetPos)
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local root = character:WaitForChild("HumanPart") or character:WaitForChild("HumanoidRootPart")
    
    if root then
        -- Safe execution under the map textures
        local safePos = Vector3.new(targetPos.X, targetPos.Y - 50, targetPos.Z)
        local distance = (root.Position - safePos).Magnitude
        local duration = distance / 250 -- Speed: 250 studs/sec
        
        local tweenService = game:GetService("TweenService")
        local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
        local tween = tweenService:Create(root, tweenInfo, {CFrame = CFrame.new(safePos)})
        
        tween:Play()
        tween.Completed:Wait()
        
        -- Bring slightly up to grab the item securely
        root.CFrame = CFrame.new(targetPos)
        task.wait(0.5)
    end
end

local function SmartServerHop()
    Fluent:Notify({ Title = "Server Hop", Content = "Initiating server hop in 5 seconds...", Duration = 4 })
    task.wait(5)
    
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local PlaceId = game.PlaceId
    
    local success, result = pcall(function()
        local servers = HttpService:JSONDecode(game:HttpGet("https://roblox.com" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        for _, server in pairs(servers.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(PlaceId, server.id, game.Players.LocalPlayer)
                break
            end
        end
    end)
    
    if not success then
        Fluent:Notify({ Title = "Error", Content = "Failed to hop server, retrying...", Duration = 3 })
        task.wait(2)
        SmartServerHop()
    end
end

-- [[ Sniper Thread Logic ]]
task.spawn(function()
    while task.wait(1) do
        if _G.AutoFindFruits then
            local fruitFound = false
            local workspaceItems = workspace:GetChildren()
            
            for _, item in ipairs(workspaceItems) do
                if item:IsA("Tool") and string.find(item.Name, "Fruit") then
                    if IsFilteredFruit(item.Name) then
                        fruitFound = true
                        Fluent:Notify({ Title = "Target Found", Content = "Flying to: " .. item.Name, Duration = 5 })
                        
                        local handle = item:FindFirstChild("Handle")
                        if handle then
                            TeleportUnderMap(handle.Position)
                            -- Store Fruit logic execution
                            game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("StoreFruit", item.Name, item)
                            task.wait(1)
                        end
                    end
                end
            end
            
            if not fruitFound then
                SmartServerHop()
            end
        end
    end
end)

-- [[ Fruit Filter Tab Elements ]]
local function CreateRaritySection(rarityName, fruits)
    Tabs.Filter:AddParagraph({ Title = rarityName .. " Fruits", Content = "Toggle targeted pickups" })
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
Tabs.Settings:AddParagraph({ Title = "Manual Navigation", Content = "Control your server migration process manually if needed." })
Tabs.Settings:AddButton({
    Title = "Instant Server Hop",
    Description = "Instantly migrate to another active public server",
    Callback = function()
        SmartServerHop()
    end
})

Window:SelectTab(1)
Fluent:Notify({ Title = "Interface Loaded", Content = "Enjoy your secure fruit hunting!", Duration = 5 })
