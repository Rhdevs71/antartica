--[[
    ===================================================================
    ❄️ ANTARTICA HUB - MOUNTAIN MINING & UTILITY (v4.6 Plot Stacker & Sell All)
    ===================================================================
    UI Library: WindUI (https://github.com/Footagesus/WindUI)
    Dibuat untuk: Owner Game, Map Tester & Player (Roblox Mountain Mining)
    
    Kelengkapan Tab WindUI (8 Tabs Lengkap):
      1. 🏃 Movement (Fly Toggle, D-Pad Toggle, Fly Speed, WalkSpeed, GodMode, Anti-Fall, Noclip)
      2. ⛏️ Mining & Dig (Auto Dig + Maju Hancurkan Gunung, Power Boost Slider 20k, Auto Equip)
      3. ⚡ Remote Hacks (Jetpack Thrust, Plasma Drill, Bomb Explode, Radar Pulse, Starfall, Meteor, Code Redeem)
      4. 👥 Target Player (Player List Dropdown, Refresh List, TP to Target, Auto Follow/Spectate)
      5. 🎒 Bag & Crystals (Auto Mine Termahal, Filter Plot Strict, Instant Sell All, Ambil & Tumpuk Kristal Plot)
      6. 📍 Teleports & Shops (TP & Buka UI Toko Jual, Bom, Pickaxe, Upgrade, Radar, Peak, CFrame Copy)
      7. ☀️ Map Inspector (TimeOfDay Slider 0-24, Fullbright, No Fog, Infinite Jump)
      8. 🔍 Dev Scanner (Scan Remotes ke File/Clipboard, Count Crystals, Open Shop UI Remote Test)
    ===================================================================
]]

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Camera = Workspace.CurrentCamera

-- VIRTUAL INPUT (Untuk Executor)
local VirtualInputManager = nil
pcall(function() VirtualInputManager = game:GetService("VirtualInputManager") end)

-- SAFE GUI CONTAINER
local function getSafeGuiParent()
    if type(gethui) == "function" then return gethui() end
    local s, cg = pcall(function() return CoreGui end)
    if s and cg then
        local ok = pcall(function()
            local test = Instance.new("Folder", cg)
            test:Destroy()
        end)
        if ok then return cg end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- ===================================================================
-- SISTEM LOGGING FILE LOKAL HP & CLIPBOARD
-- ===================================================================
local function saveLocalFile(fileName, content, isAppend)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local formatted = string.format("[%s] %s\n", timestamp, content)
    pcall(function()
        if isAppend and type(appendfile) == "function" then
            appendfile(fileName, formatted)
        elseif type(writefile) == "function" then
            local prev = ""
            if isAppend and type(isfile) == "function" and isfile(fileName) and type(readfile) == "function" then
                prev = readfile(fileName)
            end
            writefile(fileName, prev .. formatted)
        end
    end)
end

local function copyToRealClipboard(text)
    local copied = false
    if type(setclipboard) == "function" then
        local ok = pcall(function() setclipboard(text) end)
        if ok then copied = true end
    end
    if not copied and type(toclipboard) == "function" then
        local ok = pcall(function() toclipboard(text) end)
        if ok then copied = true end
    end
    saveLocalFile("antartica_logs.txt", "Teks disalin ke clipboard (" .. #text .. " karakter)", true)
    return copied
end

saveLocalFile("antartica_logs.txt", "=== Antartica Hub v4.6 Plot Stacker & Sell All Edition Dijalankan ===", true)

-- ===================================================================
-- LOAD WINDUI LIBRARY
-- ===================================================================
local WindUI = nil
local loadUrls = {
    "https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua",
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua",
    "https://tree-hub.vercel.app/api/library/windui"
}

for _, url in ipairs(loadUrls) do
    local ok, res = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if ok and res then
        WindUI = res
        break
    end
end

if not WindUI then
    warn("❌ Gagal memuat WindUI dari internet! Pastikan koneksi executor aktif.")
    return
end

-- ===================================================================
-- STATE DAN VARIABEL FITUR
-- ===================================================================
local State = {
    -- Fly & Movement
    Flying = false,
    FlySpeed = 50,
    WalkSpeed = 16,
    ShowDpad = true,
    Noclip = false,
    InfiniteJump = false,
    FlyKeys = { W = false, A = false, S = false, D = false, Up = false, Down = false },
    
    -- Health & Godmode
    GodMode = true,
    AntiFallDamage = true,
    
    -- Auto Dig & Mountain Carver
    AutoDig = false,
    AutoAdvanceMountain = true,
    CarveSpeed = 0.45,
    PickaxePowerBoost = 5000,
    EnablePowerBoost = true,
    
    -- Special Hacks & Remotes
    JetpackThrust = false,
    AutoPlasmaDrill = false,
    AutoRadarPulse = false,

    -- Target Player
    SelectedPlayerName = nil,
    LoopFollowPlayer = false,

    -- Auto Mine & Gem Magnet
    AutoMineMostExpensive = false,
    AutoMineGeneral = false,
    AutoPickupGem = true,
    StrictPlotFilter = true,
    SelectedRarityFilter = "Semua (All)",
    CurrentBag = 0,
    MaxBagCapacity = 20,
    AutoReturnWhenFull = true,
    InstantRemoteSell = true, -- Instant Sell tanpa perlu TP jika berada di atas gunung
    IsReturning = false,
    
    -- Waypoints Toko Asli
    Waypoints = {
        ["🏪 Toko Jual (Sell)"]     = CFrame.new(433.42, 65.16, -844.76),
        ["💣 Toko Bom (Bomb)"]       = CFrame.new(369.68, 65.17, -840.77),
        ["⛏️ Toko Pickaxes"]         = CFrame.new(368.23, 65.17, -823.66),
        ["⚡ Toko Upgrade"]          = CFrame.new(368.55, 65.17, -804.89),
        ["📡 Toko Radars"]           = CFrame.new(370.82, 65.17, -789.87),
        ["🏔️ Puncak Gunung (Peak)"]  = CFrame.new(220.00, 330.00, 480.00),
    },
    LastMiningPosition = nil,
    
    -- Lighting & Atmosphere
    Fullbright = false,
    NoFog = false,
    TimeOfDay = 14,

    RarityConfig = {
        ["Mythic"]    = { Price = 1500, Priority = 6 },
        ["Legendary"] = { Price = 500,  Priority = 5 },
        ["Epic"]      = { Price = 180,  Priority = 4 },
        ["Rare"]      = { Price = 65,   Priority = 3 },
        ["Uncommon"]  = { Price = 25,   Priority = 2 },
        ["Common"]    = { Price = 10,   Priority = 1 },
    }
}

-- REMOTES REFERENCE DARI EVENT.TXT (103 REMOTES)
local Remotes = {
    DigRequest        = ReplicatedStorage:FindFirstChild("DigRemotes") and ReplicatedStorage.DigRemotes:FindFirstChild("DigRequest"),
    SetDigPower       = ReplicatedStorage:FindFirstChild("DigRemotes") and ReplicatedStorage.DigRemotes:FindFirstChild("SetDigPower"),
    PickupGem         = ReplicatedStorage:FindFirstChild("GemSignals") and ReplicatedStorage.GemSignals:FindFirstChild("PickupGem"),
    GemCollected      = ReplicatedStorage:FindFirstChild("GemSignals") and ReplicatedStorage.GemSignals:FindFirstChild("GemCollected"),
    MineHit           = ReplicatedStorage:FindFirstChild("GemSignals") and ReplicatedStorage.GemSignals:FindFirstChild("MineHit"),
    SetLuck           = ReplicatedStorage:FindFirstChild("GemSignals") and ReplicatedStorage.GemSignals:FindFirstChild("SetLuck"),
    RequestSell       = ReplicatedStorage:FindFirstChild("GemRemotes") and ReplicatedStorage.GemRemotes:FindFirstChild("RequestSell"),
    OpenSellerMenu    = ReplicatedStorage:FindFirstChild("GemRemotes") and ReplicatedStorage.GemRemotes:FindFirstChild("OpenSellerMenu"),
    RequestOpenSeller = ReplicatedStorage:FindFirstChild("GemRemotes") and ReplicatedStorage.GemRemotes:FindFirstChild("RequestOpenSeller"),
    OpenBombShop      = ReplicatedStorage:FindFirstChild("BombRemotes") and ReplicatedStorage.BombRemotes:FindFirstChild("OpenShop"),
    ExplodeBomb       = ReplicatedStorage:FindFirstChild("BombRemotes") and ReplicatedStorage.BombRemotes:FindFirstChild("Explode"),
    BuyBomb           = ReplicatedStorage:FindFirstChild("BombRemotes") and ReplicatedStorage.BombRemotes:FindFirstChild("BuyBomb"),
    OpenRadarShop     = ReplicatedStorage:FindFirstChild("RadarRemotes") and ReplicatedStorage.RadarRemotes:FindFirstChild("OpenShop"),
    RadarUsed         = ReplicatedStorage:FindFirstChild("RadarRemotes") and ReplicatedStorage.RadarRemotes:FindFirstChild("RadarUsed"),
    PowerFired        = ReplicatedStorage:FindFirstChild("RadarRemotes") and ReplicatedStorage.RadarRemotes:FindFirstChild("PowerFired"),
    ShopState         = ReplicatedStorage:FindFirstChild("ShopRemotes") and ReplicatedStorage.ShopRemotes:FindFirstChild("ShopState"),
    UpgradeState      = ReplicatedStorage:FindFirstChild("UpgradeRemotes") and ReplicatedStorage.UpgradeRemotes:FindFirstChild("UpgradeState"),
    ThrustState       = ReplicatedStorage:FindFirstChild("JetpackSystem") and ReplicatedStorage.JetpackSystem:FindFirstChild("Remotes") and ReplicatedStorage.JetpackSystem.Remotes:FindFirstChild("ThrustState"),
    DrillEvent        = ReplicatedStorage:FindFirstChild("DrillTools") and ReplicatedStorage.DrillTools:FindFirstChild("Plasma Drill") and ReplicatedStorage.DrillTools["Plasma Drill"]:FindFirstChild("DrillEvent"),
    Starfall          = ReplicatedStorage:FindFirstChild("WeatherRemotes") and ReplicatedStorage.WeatherRemotes:FindFirstChild("Starfall"),
    MeteorEvent       = ReplicatedStorage:FindFirstChild("MeteorRemotes") and ReplicatedStorage.MeteorRemotes:FindFirstChild("Event"),
    MountainRegen     = ReplicatedStorage:FindFirstChild("MountainRemotes") and ReplicatedStorage.MountainRemotes:FindFirstChild("Regen"),
    AdminControl      = ReplicatedStorage:FindFirstChild("MountainRemotes") and ReplicatedStorage.MountainRemotes:FindFirstChild("AdminControl"),
    RedeemCode        = ReplicatedStorage:FindFirstChild("RedeemCode"),
    UsePotion         = ReplicatedStorage:FindFirstChild("UsePotion"),
    SyncAllPotions    = ReplicatedStorage:FindFirstChild("SyncAllPotions"),
    PlaceRune         = ReplicatedStorage:FindFirstChild("RuneRemotes") and ReplicatedStorage.RuneRemotes:FindFirstChild("PlaceRune"),
    DropRune          = ReplicatedStorage:FindFirstChild("RuneRemotes") and ReplicatedStorage.RuneRemotes:FindFirstChild("DropRune"),
    BoulderBroken     = ReplicatedStorage:FindFirstChild("BoulderRemotes") and ReplicatedStorage.BoulderRemotes:FindFirstChild("Broken"),
    GroupVerify       = ReplicatedStorage:FindFirstChild("GroupRewardRemotes") and ReplicatedStorage.GroupRewardRemotes:FindFirstChild("Verify"),
    AdminAbuseTrigger = ReplicatedStorage:FindFirstChild("AdminAbuseRemotes") and ReplicatedStorage.AdminAbuseRemotes:FindFirstChild("Trigger"),
    
    -- PLOT REMOTES (PLACE, TAKE, CONFIG)
    PlaceCrystal      = ReplicatedStorage:FindFirstChild("PlotRemotes") and ReplicatedStorage.PlotRemotes:FindFirstChild("PlaceCrystal"),
    TakeCrystal       = ReplicatedStorage:FindFirstChild("PlotRemotes") and ReplicatedStorage.PlotRemotes:FindFirstChild("TakeCrystal"),
    TakeOut           = ReplicatedStorage:FindFirstChild("PlotRemotes") and ReplicatedStorage.PlotRemotes:FindFirstChild("TakeOut"),
    PopulatePlot      = ReplicatedStorage:FindFirstChild("PlotRemotes") and ReplicatedStorage.PlotRemotes:FindFirstChild("Populate"),
}

-- ===================================================================
-- FUNGSI UTILITAS BUKA UI TOKO & PROXIMITY PROMPT
-- ===================================================================
local function openShopUIByName(keywords, targetCFrame)
    if targetCFrame then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = targetCFrame + Vector3.new(0, 3, 0)
        end
        task.wait(0.3)
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                local part = obj.Parent
                if part and part:IsA("BasePart") then
                    if (part.Position - hrp.Position).Magnitude < 25 then
                        if type(fireproximityprompt) == "function" then
                            fireproximityprompt(obj)
                        end
                    end
                end
            end
        end
    end

    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then return end

    for _, gui in ipairs(pg:GetChildren()) do
        if gui:IsA("ScreenGui") then
            local gName = gui.Name:lower()
            for _, kw in ipairs(keywords) do
                if gName:find(kw:lower()) then
                    gui.Enabled = true
                    for _, child in ipairs(gui:GetDescendants()) do
                        if child:IsA("Frame") or child:IsA("ImageLabel") then
                            if child.Name:lower():find("shop") or child.Name:lower():find("menu") or child.Name:lower():find("main") then
                                child.Visible = true
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ===================================================================
-- FUNGSI DETEKSI PLOT SENDIRI & MANAJEMEN KRISTAL PLOT
-- ===================================================================
local function getMyPlot()
    local plotsFolder = Workspace:FindFirstChild("Plots") or Workspace:FindFirstChild("Bases") or Workspace:FindFirstChild("Kebun")
    if plotsFolder then
        for _, plot in ipairs(plotsFolder:GetChildren()) do
            local owner = plot:FindFirstChild("Owner") or plot:GetAttribute("Owner")
            if (owner and (owner.Value == LocalPlayer or owner.Value == LocalPlayer.Name or owner == LocalPlayer.Name)) or plot.Name:find(LocalPlayer.Name) then
                return plot
            end
        end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local closestPlot = nil
            local minDist = 9999
            for _, plot in ipairs(plotsFolder:GetChildren()) do
                local pos = plot:IsA("Model") and plot:GetPivot().Position or (plot:IsA("BasePart") and plot.Position)
                if pos then
                    local dist = (hrp.Position - pos).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closestPlot = plot
                    end
                end
            end
            if minDist < 100 then return closestPlot end
        end
    end
    return nil
end

local function takeAllPlotCrystals()
    local myPlot = getMyPlot()
    local count = 0
    if myPlot then
        for _, obj in ipairs(myPlot:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                pcall(function() fireproximityprompt(obj) end)
                count = count + 1
            elseif obj:IsA("BasePart") or obj:IsA("Model") then
                local crystalId = obj:GetAttribute("Id") or obj:GetAttribute("CrystalId") or tonumber(obj.Name)
                if crystalId then
                    if Remotes.TakeCrystal then pcall(function() Remotes.TakeCrystal:FireServer(crystalId) end) end
                    if Remotes.TakeOut then pcall(function() Remotes.TakeOut:FireServer(crystalId) end) end
                    count = count + 1
                end
            end
        end
    else
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    local pPos = obj.Parent and obj.Parent:IsA("BasePart") and obj.Parent.Position
                    if pPos and (pPos - hrp.Position).Magnitude < 40 then
                        pcall(function() fireproximityprompt(obj) end)
                        count = count + 1
                    end
                end
            end
        end
    end
    return count
end

local function stackGoodCrystalsOnMyPlot(minRarityName)
    minRarityName = minRarityName or "Rare"
    local rarityRank = {
        ["Mythic"] = 6,
        ["Legendary"] = 5,
        ["Epic"] = 4,
        ["Rare"] = 3,
        ["Uncommon"] = 2,
        ["Common"] = 1
    }
    local minRank = rarityRank[minRarityName] or 3

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return 0 end

    local myPlot = getMyPlot()
    local baseVector = hrp.Position + (hrp.CFrame.LookVector * 4)
    if myPlot then
        local pPos = myPlot:IsA("Model") and myPlot:GetPivot().Position or (myPlot:IsA("BasePart") and myPlot.Position)
        if pPos then baseVector = pPos + Vector3.new(0, 3, 0) end
    end

    local itemsToPlace = {}
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            local iName = item.Name:lower()
            local rRank = 1
            for rName, rVal in pairs(State.RarityConfig) do
                if iName:find(rName:lower()) then
                    rRank = rVal.Priority
                    break
                end
            end

            local itemLuck = item:GetAttribute("Luck") or item:GetAttribute("Rarity")
            if type(itemLuck) == "number" and itemLuck > 10 then
                rRank = math.max(rRank, 4)
            end

            if rRank >= minRank then
                local crystalId = item:GetAttribute("Id") or item:GetAttribute("CrystalId") or tonumber(item.Name) or item
                table.insert(itemsToPlace, { Item = item, Id = crystalId, Rank = rRank })
            end
        end
    end

    table.sort(itemsToPlace, function(a, b) return a.Rank > b.Rank end)

    local placedCount = 0
    for index, data in ipairs(itemsToPlace) do
        -- Tumpuk di posisi Vector3 yang sama dengan sedikit offset ketinggian Y (bertumpuk rapi)
        local stackPos = Vector3.new(baseVector.X, baseVector.Y + ((index - 1) * 0.35), baseVector.Z)
        if Remotes.PlaceCrystal then
            pcall(function()
                Remotes.PlaceCrystal:FireServer(data.Id, stackPos)
            end)
            placedCount = placedCount + 1
            task.wait(0.08)
        end
    end

    return placedCount
end

-- ===================================================================
-- FUNGSI TELEPORT & PLAYER LIST
-- ===================================================================
local function teleportTo(cf)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = cf + Vector3.new(0, 3, 0)
    end
end

local function getPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.Name)
        end
    end
    if #list == 0 then table.insert(list, "Tidak ada player lain") end
    return list
end

-- ===================================================================
-- DETEKSI KAPASITAS TAS
-- ===================================================================
local function detectActualBagCount()
    local ls = LocalPlayer:FindFirstChild("leaderstats") or LocalPlayer:FindFirstChild("Stats") or LocalPlayer:FindFirstChild("Data")
    if ls then
        for _, v in ipairs(ls:GetChildren()) do
            local n = v.Name:lower()
            if n:find("bag") or n:find("crystal") or n:find("ore") or n:find("capacity") or n:find("inv") then
                if v:IsA("IntValue") or v:IsA("NumberValue") then State.CurrentBag = v.Value end
            end
            if n:find("max") or n:find("maxbag") or n:find("bagmax") or n:find("maxcapacity") then
                if v:IsA("IntValue") or v:IsA("NumberValue") then State.MaxBagCapacity = v.Value end
            end
        end
    end

    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if pg then
        for _, lbl in ipairs(pg:GetDescendants()) do
            if lbl:IsA("TextLabel") and lbl.Visible and lbl.Text ~= "" then
                local cur, max = lbl.Text:match("(%d+)%s*/%s*(%d+)")
                if cur and max then
                    local cNum = tonumber(cur)
                    local mNum = tonumber(max)
                    if cNum and mNum and mNum > 0 and mNum <= 5000 then
                        State.CurrentBag = cNum
                        State.MaxBagCapacity = mNum
                        break
                    end
                end
            end
        end
    end
end

-- ===================================================================
-- BOOST DAYA HANCUR PICKAXE & MOUNTAIN ADVANCE ENGINE
-- ===================================================================
local function boostPickaxePower()
    if not State.EnablePowerBoost then return end
    if Remotes.SetDigPower then
        pcall(function() Remotes.SetDigPower:FireServer(State.PickaxePowerBoost) end)
    end

    local char = LocalPlayer.Character
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    local tools = {}
    
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") then table.insert(tools, t) end
        end
    end
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then table.insert(tools, t) end
        end
    end

    for _, tool in ipairs(tools) do
        for _, v in ipairs(tool:GetDescendants()) do
            local vn = v.Name:lower()
            if (v:IsA("NumberValue") or v:IsA("IntValue")) and 
               (vn:find("power") or vn:find("damage") or vn:find("strength") or vn:find("speed") or vn:find("dig") or vn:find("mine") or vn:find("multi")) then
                v.Value = State.PickaxePowerBoost
            end
        end
        pcall(function()
            for attrName, _ in pairs(tool:GetAttributes()) do
                local an = attrName:lower()
                if an:find("power") or an:find("damage") or an:find("strength") or an:find("dig") or an:find("mine") then
                    tool:SetAttribute(attrName, State.PickaxePowerBoost)
                end
            end
        end)
    end
end

local function triggerDigAction()
    if Remotes.DigRequest then pcall(function() Remotes.DigRequest:FireServer() end) end
    if Remotes.MineHit then pcall(function() Remotes.MineHit:FireServer() end) end

    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if pg then
        for _, obj in ipairs(pg:GetDescendants()) do
            if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and obj.Visible then
                local text = (obj:IsA("TextButton") and obj.Text) or ""
                local name = obj.Name:lower()
                if text:upper() == "DIG" or name:find("dig") or name:find("mine") then
                    pcall(function()
                        if typeof(firesignal) == "function" then
                            firesignal(obj.MouseButton1Down)
                            firesignal(obj.MouseButton1Click)
                            firesignal(obj.Activated)
                        end
                    end)
                end
            end
        end
    end

    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            tool:Activate()
        else
            local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
            if bp then
                local myPick = bp:FindFirstChildOfClass("Tool")
                if myPick then myPick.Parent = char end
            end
        end

        -- LOGIC MAJU & PANJAT GUNUNG (CARVING TERRAIN FORWARD INTO MOUNTAIN)
        if State.AutoAdvanceMountain and State.AutoDig then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hrp and hum then
                local lookDir = Camera.CFrame.LookVector
                local flatDir = Vector3.new(lookDir.X, 0, lookDir.Z).Unit
                if flatDir.Magnitude < 0.1 then flatDir = hrp.CFrame.LookVector end

                local rayOrigin = hrp.Position
                local rayDirection = flatDir * 3.5
                local raycastParams = RaycastParams.new()
                raycastParams.FilterAncestorsInstances = { char }
                raycastParams.FilterType = Enum.RaycastFilterType.Exclude

                local result = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
                local stepUp = 0.15
                if result then
                    stepUp = 0.45
                    hum.Jump = true
                end

                hrp.CFrame = hrp.CFrame + (flatDir * State.CarveSpeed) + Vector3.new(0, stepUp, 0)
            end
        end
    end

    if VirtualInputManager then
        pcall(function()
            local vp = Camera.ViewportSize
            VirtualInputManager:SendMouseButtonEvent(vp.X * 0.85, vp.Y * 0.75, 0, true, game, 0)
            task.wait(0.01)
            VirtualInputManager:SendMouseButtonEvent(vp.X * 0.85, vp.Y * 0.75, 0, false, game, 0)
        end)
    end
end

task.spawn(function()
    while true do
        if State.AutoDig then
            triggerDigAction()
            task.wait(0.05)
        else
            task.wait(0.3)
        end
    end
end)

-- ===================================================================
-- PENCARIAN KRISTAL DENGAN FILTER KEBUN / PLOT PLAYER STRICT
-- ===================================================================
local function isInsidePlot(obj)
    if not State.StrictPlotFilter then return false end
    local current = obj
    while current and current ~= Workspace do
        local n = current.Name:lower()
        if n:find("plot") or n:find("kebun") or n:find("garden") or n:find("farm") or n:find("base") or n:find("pajangan") or n:find("display") then
            return true
        end
        current = current.Parent
    end

    local pos = obj:IsA("Model") and obj:GetPivot().Position or (obj:IsA("BasePart") and obj.Position)
    if pos then
        local plotsFolder = Workspace:FindFirstChild("Plots") or Workspace:FindFirstChild("Bases")
        if plotsFolder then
            for _, plot in ipairs(plotsFolder:GetChildren()) do
                local plotPos = plot:IsA("Model") and plot:GetPivot().Position or (plot:IsA("BasePart") and plot.Position)
                if plotPos and (pos - plotPos).Magnitude < 35 then
                    return true
                end
            end
        end
    end

    return false
end

local function findCrystalsInMap()
    local list = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if not isInsidePlot(obj) then
            local n = obj.Name:lower()
            if (obj:IsA("BasePart") or obj:IsA("Model")) and 
               (n:find("crystal") or n:find("kristal") or n:find("ore") or n:find("gem")) then
                local cf = obj:IsA("Model") and obj:GetPivot() or obj.CFrame
                local r = "Common"
                for rName in pairs(State.RarityConfig) do
                    if n:find(rName:lower()) then r = rName break end
                end
                table.insert(list, {
                    Instance = obj,
                    CFrame = cf,
                    Rarity = r,
                    Price = State.RarityConfig[r].Price,
                    Priority = State.RarityConfig[r].Priority
                })
            end
        end
    end
    table.sort(list, function(a, b) return a.Priority > b.Priority end)
    return list
end

-- ===================================================================
-- AUTO PICKUP & MAGNET GEM
-- ===================================================================
local function autoPickupGemLoop()
    if not State.AutoPickupGem then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if not isInsidePlot(obj) then
            local n = obj.Name:lower()
            if n:find("gem") or n:find("crystal") or n:find("drop") then
                if obj:IsA("BasePart") or obj:IsA("Model") then
                    local pos = obj:IsA("Model") and obj:GetPivot().Position or obj.Position
                    local dist = (hrp.Position - pos).Magnitude
                    if dist < 60 then
                        if Remotes.PickupGem then pcall(function() Remotes.PickupGem:FireServer(obj) end) end
                        if Remotes.GemCollected then pcall(function() Remotes.GemCollected:FireServer(obj) end) end

                        local prompt = obj:FindFirstChildOfClass("ProximityPrompt", true)
                        if prompt and type(fireproximityprompt) == "function" then
                            fireproximityprompt(prompt)
                        end
                    end
                end
            end
        end
    end
end

-- ===================================================================
-- AUTO-RETURN TO SELL DENGAN REMOTE REQUESTSELL ("ALL")
-- ===================================================================
local function executeAutoReturnToSell()
    if State.IsReturning then return end
    State.IsReturning = true

    if State.InstantRemoteSell then
        -- Sell langsung dari posisi manapun tanpa perlu teleport ke toko!
        if Remotes.RequestSell then
            pcall(function() Remotes.RequestSell:FireServer("All") end)
            pcall(function() Remotes.RequestSell:FireServer() end)
        end
        State.CurrentBag = 0
        WindUI:Notify({ Title = "⚡ Instant Sell (All)", Content = "Kristal dijual via Remote RequestSell('All')!", Duration = 2 })
    else
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            State.LastMiningPosition = hrp.CFrame
            WindUI:Notify({ Title = "🎒 Tas Penuh!", Content = "Teleport ke Toko Jual (Sell)...", Duration = 3 })

            teleportTo(State.Waypoints["🏪 Toko Jual (Sell)"])
            task.wait(1.0)

            openShopUIByName({ "sell", "jual", "seller" })
            if Remotes.RequestSell then
                pcall(function() Remotes.RequestSell:FireServer("All") end)
                pcall(function() Remotes.RequestSell:FireServer() end)
            end

            State.CurrentBag = 0
            task.wait(1.5)

            if State.LastMiningPosition then
                teleportTo(State.LastMiningPosition)
                WindUI:Notify({ Title = "💎 Lanjut Menambang", Content = "Kembali ke posisi gunung sebelumnya!", Duration = 2 })
            end
        end
    end
    State.IsReturning = false
end

task.spawn(function()
    while true do
        detectActualBagCount()
        autoPickupGemLoop()

        if State.AutoReturnWhenFull and not State.IsReturning then
            if State.CurrentBag > 0 and State.CurrentBag >= State.MaxBagCapacity then
                executeAutoReturnToSell()
            end
        end

        if (State.AutoMineMostExpensive or State.AutoMineGeneral) and not State.IsReturning then
            local crystals = findCrystalsInMap()
            if #crystals > 0 then
                local targetCrystal = crystals[1]
                teleportTo(targetCrystal.CFrame)
                
                local prompt = targetCrystal.Instance:FindFirstChildOfClass("ProximityPrompt", true)
                if prompt and type(fireproximityprompt) == "function" then
                    fireproximityprompt(prompt)
                end
                triggerDigAction()
            end
        end
        task.wait(0.3)
    end
end)

-- ===================================================================
-- PLAYER TARGET & FOLLOW LOOP
-- ===================================================================
task.spawn(function()
    while true do
        if State.LoopFollowPlayer and State.SelectedPlayerName then
            local targetP = Players:FindFirstChild(State.SelectedPlayerName)
            if targetP and targetP.Character and targetP.Character:FindFirstChild("HumanoidRootPart") then
                teleportTo(targetP.Character.HumanoidRootPart.CFrame + Vector3.new(0, 0, 3))
            end
        end
        task.wait(0.2)
    end
end)

-- ===================================================================
-- SPECIAL REMOTES LOOPS (Jetpack, Plasma Drill, Radar)
-- ===================================================================
task.spawn(function()
    while true do
        if State.JetpackThrust and Remotes.ThrustState then
            pcall(function() Remotes.ThrustState:FireServer(true) end)
        end
        if State.AutoPlasmaDrill and Remotes.DrillEvent then
            pcall(function() Remotes.DrillEvent:FireServer() end)
        end
        if State.AutoRadarPulse and Remotes.RadarUsed then
            pcall(function() Remotes.RadarUsed:FireServer() end)
            if Remotes.PowerFired then pcall(function() Remotes.PowerFired:FireServer() end) end
        end
        task.wait(0.15)
    end
end)

-- ===================================================================
-- DARAH PENUH & INFINITE JUMP
-- ===================================================================
local function applyHealthGuard(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end

    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    end)

    hum.HealthChanged:Connect(function(health)
        if State.GodMode and health < hum.MaxHealth and health > 0 then
            pcall(function() hum.Health = hum.MaxHealth end)
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(applyHealthGuard)
if LocalPlayer.Character then applyHealthGuard(LocalPlayer.Character) end

UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hrp and hum then
        if State.WalkSpeed > 16 and hum.WalkSpeed ~= State.WalkSpeed then hum.WalkSpeed = State.WalkSpeed end
        if State.AntiFallDamage and hrp.AssemblyLinearVelocity.Y < -55 then
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, -20, hrp.AssemblyLinearVelocity.Z)
        end
        if State.GodMode and hum.Health < hum.MaxHealth and hum.Health > 0 then hum.Health = hum.MaxHealth end
    end

    if (State.Noclip or (State.AutoDig and State.AutoAdvanceMountain)) and char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- ===================================================================
-- FLY ENGINE & ERGONOMIC D-PAD CONTROLS
-- ===================================================================
local dpadParent = getSafeGuiParent()
local oldDpad = dpadParent:FindFirstChild("AntarticaErgoControls")
if oldDpad then oldDpad:Destroy() end

local ControlGui = Instance.new("ScreenGui")
ControlGui.Name = "AntarticaErgoControls"
ControlGui.ResetOnSpawn = false
ControlGui.Parent = dpadParent

local QuickFlyBtn = Instance.new("TextButton")
QuickFlyBtn.Name = "QuickFlyToggle"
QuickFlyBtn.Size = UDim2.new(0, 84, 0, 38)
QuickFlyBtn.Position = UDim2.new(0.86, 0, 0.44, 0)
QuickFlyBtn.BackgroundColor3 = Color3.fromRGB(30, 34, 44)
QuickFlyBtn.TextColor3 = Color3.fromRGB(240, 245, 255)
QuickFlyBtn.Text = "🕊️ FLY"
QuickFlyBtn.Font = Enum.Font.GothamBold
QuickFlyBtn.TextSize = 13
QuickFlyBtn.Active = true
QuickFlyBtn.Draggable = true
QuickFlyBtn.Parent = ControlGui

local QuickCorner = Instance.new("UICorner")
QuickCorner.CornerRadius = UDim.new(0, 10)
QuickCorner.Parent = QuickFlyBtn

local LeftFrame = Instance.new("Frame")
LeftFrame.Name = "LeftHorizontalPad"
LeftFrame.Size = UDim2.new(0, 135, 0, 135)
LeftFrame.Position = UDim2.new(0.03, 0, 0.60, 0)
LeftFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
LeftFrame.BackgroundTransparency = 0.4
LeftFrame.Active = true
LeftFrame.Draggable = true
LeftFrame.Visible = false
LeftFrame.Parent = ControlGui

local RightFrame = Instance.new("Frame")
RightFrame.Name = "RightVerticalPad"
RightFrame.Size = UDim2.new(0, 75, 0, 135)
RightFrame.Position = UDim2.new(0.87, 0, 0.60, 0)
RightFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
RightFrame.BackgroundTransparency = 0.4
RightFrame.Active = true
RightFrame.Draggable = true
RightFrame.Visible = false
RightFrame.Parent = ControlGui

local function createTouchBtn(parent, text, pos, size, key)
    local btn = Instance.new("TextButton")
    btn.Text = text
    btn.Position = pos
    btn.Size = size
    btn.BackgroundColor3 = Color3.fromRGB(38, 44, 58)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.Parent = parent

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            State.FlyKeys[key] = true
            btn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            State.FlyKeys[key] = false
            btn.BackgroundColor3 = Color3.fromRGB(38, 44, 58)
        end
    end)
    return btn
end

createTouchBtn(LeftFrame, "W", UDim2.new(0, 48, 0, 8),  UDim2.new(0, 38, 0, 38), "W")
createTouchBtn(LeftFrame, "A", UDim2.new(0, 8, 0, 48),  UDim2.new(0, 38, 0, 38), "A")
createTouchBtn(LeftFrame, "S", UDim2.new(0, 48, 0, 88), UDim2.new(0, 38, 0, 38), "S")
createTouchBtn(LeftFrame, "D", UDim2.new(0, 88, 0, 48), UDim2.new(0, 38, 0, 38), "D")

createTouchBtn(RightFrame, "▲ NAIK",  UDim2.new(0, 8, 0, 10), UDim2.new(0, 58, 0, 52), "Up")
createTouchBtn(RightFrame, "▼ TURUN", UDim2.new(0, 8, 0, 72), UDim2.new(0, 58, 0, 52), "Down")

local flyBv, flyBg = nil, nil

local function updateControlPads()
    local shouldShow = State.Flying and State.ShowDpad
    LeftFrame.Visible = shouldShow
    RightFrame.Visible = shouldShow
    QuickFlyBtn.BackgroundColor3 = State.Flying and Color3.fromRGB(36, 145, 75) or Color3.fromRGB(30, 34, 44)
    QuickFlyBtn.Text = State.Flying and "🕊️ FLY: ON" or "🕊️ FLY: OFF"
end

local function setFlying(active)
    State.Flying = active
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    if active then
        hum.PlatformStand = true
        flyBv = Instance.new("BodyVelocity")
        flyBv.Velocity = Vector3.zero
        flyBv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBv.Parent = hrp

        flyBg = Instance.new("BodyGyro")
        flyBg.CFrame = hrp.CFrame
        flyBg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyBg.P = 9e4
        flyBg.Parent = hrp
    else
        hum.PlatformStand = false
        if flyBv then flyBv:Destroy() flyBv = nil end
        if flyBg then flyBg:Destroy() flyBg = nil end
        for k in pairs(State.FlyKeys) do State.FlyKeys[k] = false end
    end
    updateControlPads()
end

QuickFlyBtn.MouseButton1Click:Connect(function() setFlying(not State.Flying) end)

RunService.RenderStepped:Connect(function()
    if not State.Flying or not flyBv or not flyBg then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local forward = Camera.CFrame.LookVector
    local right = Camera.CFrame.RightVector
    local dir = Vector3.zero

    if State.FlyKeys.W then dir = dir + forward end
    if State.FlyKeys.S then dir = dir - forward end
    if State.FlyKeys.A then dir = dir - right end
    if State.FlyKeys.D then dir = dir + right end
    if State.FlyKeys.Up then dir = dir + Vector3.new(0, 1, 0) end
    if State.FlyKeys.Down then dir = dir - Vector3.new(0, 1, 0) end

    if dir.Magnitude > 0 then flyBv.Velocity = dir.Unit * State.FlySpeed else flyBv.Velocity = Vector3.zero end
    flyBg.CFrame = Camera.CFrame
end)

-- Keyboard PC Sync
UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not State.Flying then return end
    if input.KeyCode == Enum.KeyCode.W then State.FlyKeys.W = true
    elseif input.KeyCode == Enum.KeyCode.S then State.FlyKeys.S = true
    elseif input.KeyCode == Enum.KeyCode.A then State.FlyKeys.A = true
    elseif input.KeyCode == Enum.KeyCode.D then State.FlyKeys.D = true
    elseif input.KeyCode == Enum.KeyCode.Space then State.FlyKeys.Up = true
    elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.LeftControl then State.FlyKeys.Down = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then State.FlyKeys.W = false
    elseif input.KeyCode == Enum.KeyCode.S then State.FlyKeys.S = false
    elseif input.KeyCode == Enum.KeyCode.A then State.FlyKeys.A = false
    elseif input.KeyCode == Enum.KeyCode.D then State.FlyKeys.D = false
    elseif input.KeyCode == Enum.KeyCode.Space then State.FlyKeys.Up = false
    elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.LeftControl then State.FlyKeys.Down = false
    end
end)

-- ===================================================================
-- MEMBUAT WINDOW DAN 8 TABS LENGKAP DENGAN WINDUI
-- ===================================================================
local Window = WindUI:CreateWindow({
    Title = "❄️ Antartica Mining Hub (v4.6)",
    Icon = "mountain",
    Author = "by Rhdevs",
    Folder = "AntarticaHub",
    Size = UDim2.fromOffset(660, 520),
    Theme = "Dark",
})

-- TAB 1: MOVEMENT (PERGERAKAN)
local MoveTab = Window:Tab({ Title = "Movement", Icon = "navigation" })

MoveTab:Toggle({
    Title = "🕊️ Mode Terbang (Fly)",
    Desc = "Aktifkan kemampuan melayang karakter di lereng gunung",
    Default = false,
    Callback = function(state) setFlying(state) end
})

MoveTab:Toggle({
    Title = "🕹️ Tampilkan D-Pad Sentuh HP",
    Desc = "Kiri: WASD | Kanan: Naik/Turun",
    Default = true,
    Callback = function(state) State.ShowDpad = state updateControlPads() end
})

MoveTab:Slider({
    Title = "Kecepatan Terbang (Fly Speed)",
    Desc = "Atur kecepatan melayang karakter",
    Step = 5,
    Value = { Min = 10, Max = 200, Default = 50 },
    Callback = function(val) State.FlySpeed = val end
})

MoveTab:Slider({
    Title = "🏃 Kecepatan Lari (WalkSpeed)",
    Desc = "Atur kecepatan lari karakter",
    Step = 2,
    Value = { Min = 16, Max = 150, Default = 16 },
    Callback = function(val)
        State.WalkSpeed = val
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = val end
    end
})

MoveTab:Toggle({
    Title = "❤️ Darah Penuh (God Mode)",
    Desc = "Darah selalu penuh & tidak bisa mati",
    Default = true,
    Callback = function(state) State.GodMode = state end
})

MoveTab:Toggle({
    Title = "🛡️ Anti-Fall Damage (Kebal Jatuh)",
    Desc = "Mencegah mati saat jatuh dari tebing tinggi",
    Default = true,
    Callback = function(state) State.AntiFallDamage = state end
})

MoveTab:Toggle({
    Title = "👻 Noclip (Tembus Objek)",
    Desc = "Menembus tebing & bebatuan gunung",
    Default = false,
    Callback = function(state) State.Noclip = state end
})

-- TAB 2: MINING & DIG
local AutoTab = Window:Tab({ Title = "Mining & Dig", Icon = "zap" })

AutoTab:Toggle({
    Title = "⛏️ Auto Dig Continuous (Ketuk Gunung)",
    Desc = "AFK Penggalian berulang di tebing gunung",
    Default = false,
    Callback = function(state) State.AutoDig = state end
})

AutoTab:Toggle({
    Title = "🧗 Maju & Panjat Gunung Saat Dig (Terrain Carver)",
    Desc = "Karakter otomatis MAJU & MANJAT tebing gunung saat dig, menghancurkan tanah step-by-step",
    Default = true,
    Callback = function(state) State.AutoAdvanceMountain = state end
})

AutoTab:Slider({
    Title = "⚡ Kecepatan Maju Carve Gunung",
    Desc = "Atur seberapa jauh langkah maju setiap kali ketukan dig",
    Step = 0.05,
    Value = { Min = 0.1, Max = 1.2, Default = 0.45 },
    Callback = function(val) State.CarveSpeed = val end
})

AutoTab:Toggle({
    Title = "💥 Aktifkan Pickaxe Power Boost",
    Desc = "Meningkatkan daya hancur pickaxe",
    Default = true,
    Callback = function(state)
        State.EnablePowerBoost = state
        if state then boostPickaxePower() end
    end
})

AutoTab:Slider({
    Title = "⚡ Daya Hancur Pickaxe Boost",
    Desc = "Atur nilai kekuatan hancur pickaxe (Default: 5.000)",
    Step = 500,
    Value = { Min = 500, Max = 20000, Default = 5000 },
    Callback = function(val)
        State.PickaxePowerBoost = val
        if State.EnablePowerBoost then boostPickaxePower() end
    end
})

AutoTab:Button({
    Title = "⛏️ Auto Equip Pickaxe / Tool",
    Desc = "Ambil pickaxe dari tas ke tangan secara otomatis",
    Callback = function()
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        local char = LocalPlayer.Character
        if bp and char then
            local tool = bp:FindFirstChildOfClass("Tool")
            if tool then
                tool.Parent = char
                boostPickaxePower()
                WindUI:Notify({ Title = "Tool Dipegang", Content = tool.Name .. " siap digunakan!", Duration = 2 })
            end
        end
    end
})

-- TAB 3: REMOTE HACKS & TOOLS
local RemoteTab = Window:Tab({ Title = "Remote Hacks", Icon = "cpu" })

RemoteTab:Toggle({
    Title = "🚀 Jetpack Thrust Auto Boost",
    Desc = "Memicu JetpackSystem.Remotes.ThrustState untuk terbang jetpack terus menerus",
    Default = false,
    Callback = function(state) State.JetpackThrust = state end
})

RemoteTab:Toggle({
    Title = "⚡ Auto Plasma Drill Beam",
    Desc = "Memicu DrillTools.Plasma Drill.DrillEvent secara otomatis",
    Default = false,
    Callback = function(state) State.AutoPlasmaDrill = state end
})

RemoteTab:Toggle({
    Title = "📡 Auto Mining Radar Pulse",
    Desc = "Memicu RadarRemotes.RadarUsed & PowerFired untuk memindai ore",
    Default = false,
    Callback = function(state) State.AutoRadarPulse = state end
})

RemoteTab:Button({
    Title = "💣 Meledakkan Bom (Bomb Explode)",
    Desc = "Panggil BombRemotes.Explode:FireServer()",
    Callback = function()
        if Remotes.ExplodeBomb then
            pcall(function() Remotes.ExplodeBomb:FireServer() end)
            WindUI:Notify({ Title = "Remote Bom", Content = "Remote Bomb Explode dipicu!", Duration = 2 })
        end
    end
})

RemoteTab:Button({
    Title = "🌟 Panggil Event Weather Starfall",
    Desc = "Panggil WeatherRemotes.Starfall:FireServer()",
    Callback = function()
        if Remotes.Starfall then
            pcall(function() Remotes.Starfall:FireServer() end)
            WindUI:Notify({ Title = "Weather Event", Content = "Remote Weather Starfall dipicu!", Duration = 2 })
        end
    end
})

RemoteTab:Button({
    Title = "☄️ Panggil Event Meteor Shower",
    Desc = "Panggil MeteorRemotes.Event:FireServer()",
    Callback = function()
        if Remotes.MeteorEvent then
            pcall(function() Remotes.MeteorEvent:FireServer() end)
            WindUI:Notify({ Title = "Meteor Event", Content = "Remote Meteor Event dipicu!", Duration = 2 })
        end
    end
})

RemoteTab:Button({
    Title = "🗻 Reset / Regen Gunung (Mountain Regen)",
    Desc = "Panggil MountainRemotes.Regen:FireServer()",
    Callback = function()
        if Remotes.MountainRegen then
            pcall(function() Remotes.MountainRegen:FireServer() end)
            WindUI:Notify({ Title = "Mountain Regen", Content = "Remote Mountain Regen dipicu!", Duration = 2 })
        end
    end
})

RemoteTab:Button({
    Title = "🍀 Set Super Luck (GemSignals.SetLuck)",
    Desc = "Panggil GemSignals.SetLuck:FireServer(9999)",
    Callback = function()
        if Remotes.SetLuck then
            pcall(function() Remotes.SetLuck:FireServer(9999) end)
            WindUI:Notify({ Title = "Super Luck", Content = "Remote SetLuck (9999) dipicu!", Duration = 2 })
        end
    end
})

RemoteTab:Button({
    Title = "🎁 Klaim Hadiah Grup (Group Reward Verify)",
    Desc = "Panggil GroupRewardRemotes.Verify:FireServer()",
    Callback = function()
        if Remotes.GroupVerify then
            pcall(function() Remotes.GroupVerify:FireServer() end)
            WindUI:Notify({ Title = "Group Reward", Content = "Remote Group Reward Verify dipicu!", Duration = 2 })
        end
    end
})

RemoteTab:Button({
    Title = "⚡ Admin Abuse Trigger",
    Desc = "Panggil AdminAbuseRemotes.Trigger:FireServer()",
    Callback = function()
        if Remotes.AdminAbuseTrigger then
            pcall(function() Remotes.AdminAbuseTrigger:FireServer() end)
            WindUI:Notify({ Title = "Admin Abuse", Content = "Remote AdminAbuse Trigger dipicu!", Duration = 2 })
        end
    end
})

RemoteTab:Input({
    Title = "🎟️ Redeem Promo Code",
    Desc = "Masukkan kode redeem lalu tekan Enter",
    Placeholder = "Ketik kode di sini...",
    Callback = function(code)
        if code and code ~= "" and Remotes.RedeemCode then
            pcall(function() Remotes.RedeemCode:FireServer(code) end)
            WindUI:Notify({ Title = "Redeem Code", Content = "Mencoba redeem kode: " .. code, Duration = 3 })
        end
    end
})

-- TAB 4: TARGET PLAYER
local PlayerTab = Window:Tab({ Title = "Target Player", Icon = "user" })

local playerDropdown = PlayerTab:Dropdown({
    Title = "🎯 Pilih Player Target",
    Desc = "Pilih pemain aktif di server untuk teleport atau di-follow",
    Values = getPlayerList(),
    Default = nil,
    Callback = function(val) State.SelectedPlayerName = val end
})

PlayerTab:Button({
    Title = "🔄 Refresh List Player",
    Desc = "Perbarui daftar nama pemain di server",
    Callback = function()
        local newList = getPlayerList()
        playerDropdown:SetValues(newList)
        WindUI:Notify({ Title = "Player List", Content = "Daftar pemain diperbarui!", Duration = 2 })
    end
})

PlayerTab:Button({
    Title = "⚡ Teleport ke Player Target",
    Desc = "Berpindah langsung ke posisi player target",
    Callback = function()
        if State.SelectedPlayerName then
            local targetP = Players:FindFirstChild(State.SelectedPlayerName)
            if targetP and targetP.Character and targetP.Character:FindFirstChild("HumanoidRootPart") then
                teleportTo(targetP.Character.HumanoidRootPart.CFrame)
                WindUI:Notify({ Title = "Teleport Success", Content = "Berpindah ke " .. State.SelectedPlayerName, Duration = 2 })
            end
        end
    end
})

PlayerTab:Toggle({
    Title = "🔄 Auto Follow / Spectate Player",
    Desc = "Melayang & mengikuti pergerakan player target",
    Default = false,
    Callback = function(state) State.LoopFollowPlayer = state end
})

-- TAB 5: BAG & CRYSTALS & PLOT STACKER
local BagTab = Window:Tab({ Title = "Bag & Crystals", Icon = "gem" })

BagTab:Toggle({
    Title = "💎 Auto Mine Kristal Termahal (Liar)",
    Desc = "Mencari & TP ke kristal termahal liar di gunung",
    Default = false,
    Callback = function(state) State.AutoMineMostExpensive = state end
})

BagTab:Toggle({
    Title = "🛡️ Filter Strict Plot Kebun Player",
    Desc = "Mengabaikan kristal di dalam area plot/kebun milik pemain lain",
    Default = true,
    Callback = function(state) State.StrictPlotFilter = state end
})

BagTab:Toggle({
    Title = "⚡ Instant Remote Sell (Tanpa TP ke Toko)",
    Desc = "Jual langsung dari atas gunung via RequestSell('All') tanpa teleport balik",
    Default = true,
    Callback = function(state) State.InstantRemoteSell = state end
})

BagTab:Toggle({
    Title = "🧲 Auto Ambil / Magnet Gem",
    Desc = "Otomatis menyedot gem jatuh di sekitar tanpa perlu disentuh",
    Default = true,
    Callback = function(state) State.AutoPickupGem = state end
})

BagTab:Dropdown({
    Title = "Filter Kelangkaan (Rarity)",
    Desc = "Pilih level kristal yang ingin diprioritaskan",
    Values = { "Semua (All)", "Uncommon+", "Rare+", "Epic+", "Legendary+", "Mythic" },
    Default = "Semua (All)",
    Callback = function(val) State.SelectedRarityFilter = val end
})

BagTab:Toggle({
    Title = "🎒 Auto Sell Saat Tas Penuh",
    Desc = "Otomatis memicu RequestSell('All') saat tas penuh",
    Default = true,
    Callback = function(state) State.AutoReturnWhenFull = state end
})

BagTab:Slider({
    Title = "Batas Kapasitas Tas (Manual Override)",
    Desc = "Batas kapasitas tas jika tidak terdeteksi otomatis oleh GUI",
    Step = 1,
    Value = { Min = 5, Max = 100, Default = 20 },
    Callback = function(val) State.MaxBagCapacity = val end
})

BagTab:Button({
    Title = "💰 Jual Semua Kristal Sekarang (RequestSell 'All')",
    Desc = "Memicu RemoteEvent GemRemotes.RequestSell:FireServer('All')",
    Callback = function()
        State.CurrentBag = 0
        if Remotes.RequestSell then
            pcall(function() Remotes.RequestSell:FireServer("All") end)
            pcall(function() Remotes.RequestSell:FireServer() end)
        end
        WindUI:Notify({ Title = "Jual Kristal", Content = "Remote RequestSell('All') berhasil dipicu!", Duration = 2 })
    end
})

BagTab:Button({
    Title = "🧹 Ambil Semua Kristal di Plot Sendiri",
    Desc = "Mengambil seluruh kristal yang terpajang di plot Anda",
    Callback = function()
        local count = takeAllPlotCrystals()
        WindUI:Notify({ Title = "Plot Crystal", Content = string.format("Memproses pencabutan %d kristal dari plot...", count), Duration = 3 })
    end
})

BagTab:Button({
    Title = "🥞 Tumpuk Kristal Bagus (Luck Tinggi) di Plot",
    Desc = "Memasang kristal terbaik (Rare/Epic/Legendary/Mythic) menumpuk di 1 titik plot sendiri",
    Callback = function()
        local count = stackGoodCrystalsOnMyPlot("Rare")
        WindUI:Notify({ Title = "Plot Crystal Stacker", Content = string.format("Menumpuk %d kristal terbaik di plot sendiri!", count), Duration = 3 })
    end
})

-- TAB 6: TELEPORTS & SHOPS
local TpTab = Window:Tab({ Title = "Teleports & Shops", Icon = "map-pin" })

TpTab:Button({
    Title = "🏪 TP & Buka Toko Jual (Sell Area)",
    Desc = "Teleport & buka GUI Toko Jual",
    Callback = function()
        openShopUIByName({ "sell", "jual", "seller" }, State.Waypoints["🏪 Toko Jual (Sell)"])
        WindUI:Notify({ Title = "Toko Jual", Content = "Membuka UI Toko Jual...", Duration = 2 })
    end
})

TpTab:Button({
    Title = "💣 TP & Buka Toko Bom",
    Desc = "Teleport & buka GUI Toko Bom",
    Callback = function()
        openShopUIByName({ "bomb", "bom" }, State.Waypoints["💣 Toko Bom (Bomb)"])
        WindUI:Notify({ Title = "Toko Bom", Content = "Membuka UI Toko Bom...", Duration = 2 })
    end
})

TpTab:Button({
    Title = "⛏️ TP & Buka Toko Pickaxes",
    Desc = "Teleport & buka GUI Toko Pickaxes",
    Callback = function()
        openShopUIByName({ "pick", "pickaxe" }, State.Waypoints["⛏️ Toko Pickaxes"])
        WindUI:Notify({ Title = "Toko Pickaxe", Content = "Membuka UI Toko Pickaxe...", Duration = 2 })
    end
})

TpTab:Button({
    Title = "⚡ TP & Buka Toko Upgrade",
    Desc = "Teleport & buka GUI Toko Upgrade",
    Callback = function()
        openShopUIByName({ "upgrade", "stat" }, State.Waypoints["⚡ Toko Upgrade"])
        WindUI:Notify({ Title = "Toko Upgrade", Content = "Membuka UI Toko Upgrade...", Duration = 2 })
    end
})

TpTab:Button({
    Title = "📡 TP & Buka Toko Radars",
    Desc = "Teleport & buka GUI Toko Radar",
    Callback = function()
        openShopUIByName({ "radar" }, State.Waypoints["📡 Toko Radars"])
        WindUI:Notify({ Title = "Toko Radar", Content = "Membuka UI Toko Radar...", Duration = 2 })
    end
})

TpTab:Button({
    Title = "🏔️ TP: Puncak Gunung (Peak)",
    Desc = "Teleportasi ke puncak gunung",
    Callback = function() teleportTo(State.Waypoints["🏔️ Puncak Gunung (Peak)"]) end
})

TpTab:Button({
    Title = "💎 TP: Kristal Terdekat",
    Desc = "Berpindah ke lokasi kristal terdekat",
    Callback = function()
        local list = findCrystalsInMap()
        if #list > 0 then
            teleportTo(list[1].CFrame)
            WindUI:Notify({ Title = "Teleport Kristal", Content = "Berpindah ke kristal (" .. list[1].Rarity .. ")", Duration = 2 })
        end
    end
})

TpTab:Button({
    Title = "📍 Salin CFrame Posisi Saat Ini",
    Desc = "Menyalin koordinat ke Clipboard HP & antartica_cframes.txt",
    Callback = function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local p = char.HumanoidRootPart.Position
            local cfText = string.format('["Waypoint_%s"] = CFrame.new(%.2f, %.2f, %.2f),', os.date("%H%M%S"), p.X, p.Y, p.Z)
            copyToRealClipboard(cfText)
            saveLocalFile("antartica_cframes.txt", cfText, true)
            WindUI:Notify({ Title = "📍 CFrame Disalin!", Content = "Koordinat berhasil disalin!", Duration = 2 })
        end
    end
})

-- TAB 7: MAP INSPECTOR
local MapTab = Window:Tab({ Title = "Map Inspector", Icon = "sun" })

MapTab:Slider({
    Title = "☀️ Waktu Siang / Malam (TimeOfDay)",
    Desc = "Atur pencahayaan map dari jam 0 - 24",
    Step = 1,
    Value = { Min = 0, Max = 24, Default = 14 },
    Callback = function(val) Lighting.TimeOfDay = string.format("%02d:00:00", val) end
})

MapTab:Toggle({
    Title = "💡 Fullbright (Terangkan Gua/Gunung)",
    Desc = "Menghilangkan kegelapan pada map",
    Default = false,
    Callback = function(state)
        State.Fullbright = state
        Lighting.Ambient = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(128, 128, 128)
        Lighting.OutdoorAmbient = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(128, 128, 128)
    end
})

MapTab:Toggle({
    Title = "🌫️ No Fog (Hapus Kabut Tebal)",
    Desc = "Menghilangkan kabut tebal di gunung",
    Default = false,
    Callback = function(state) Lighting.FogEnd = state and 9e9 or 1000 end
})

MapTab:Toggle({
    Title = "🦘 Infinite Jump (Lompat Udara)",
    Desc = "Lompat terus-menerus di udara",
    Default = false,
    Callback = function(state) State.InfiniteJump = state end
})

-- TAB 8: DEV SCANNER & REMOTES
local DevTab = Window:Tab({ Title = "Dev Scanner", Icon = "code" })

DevTab:Button({
    Title = "🔍 Scan Semua RemoteEvent & Function (103 Remotes)",
    Desc = "Mencatat semua nama remote ke antartica_remotes.txt & Salin ke Clipboard",
    Callback = function()
        local total = 0
        local logData = {}
        table.insert(logData, "=== DAFTAR REMOTE EVENT & FUNCTION ===")
        for _, c in ipairs({ ReplicatedStorage, Workspace }) do
            for _, obj in ipairs(c:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    total = total + 1
                    table.insert(logData, string.format("[%03d] [%s] %s -> %s", total, obj.ClassName, obj.Name, obj:GetFullName()))
                end
            end
        end
        local fullText = table.concat(logData, "\n")
        copyToRealClipboard(fullText)
        saveLocalFile("antartica_remotes.txt", fullText, false)
        WindUI:Notify({ Title = "Scan Selesai", Content = total .. " Remote berhasil di-scan!", Duration = 3 })
    end
})

DevTab:Button({
    Title = "📊 Hitung Kristal di Workspace (Exclude Plot)",
    Desc = "Menghitung kristal aktif liar di gunung",
    Callback = function()
        local list = findCrystalsInMap()
        WindUI:Notify({ Title = "Jumlah Kristal", Content = string.format("Ditemukan %d kristal liar aktif.", #list), Duration = 3 })
    end
})

DevTab:Button({
    Title = "🛍️ Test Buka UI Toko Jual",
    Desc = "Test Direct PlayerGui Opening Toko Jual",
    Callback = function()
        openShopUIByName({ "sell", "jual", "seller" })
        WindUI:Notify({ Title = "UI Remote", Content = "Buka UI Seller Fired!", Duration = 2 })
    end
})

print("❄️ Antartica Mining Hub (v4.6 Plot Stacker & Sell All) Berhasil Dimuat!")
WindUI:Notify({
    Title = "❄️ Antartica Hub v4.6 Active",
    Content = "Instant Sell Remote ('All') + Plot Stacker Kristal Terbaik Ready!",
    Duration = 4
})
