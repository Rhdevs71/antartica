--[[
    ===================================================================
    ❄️ ANTARTICA HUB - MOUNTAIN MINING & UTILITY (v5.0 Sultan Sniper & Excavation Release)
    ===================================================================
    UI Library: WindUI (https://github.com/Footagesus/WindUI)
    Dibuat untuk: Owner Game, Map Tester & Player (Roblox Mountain Mining)
    
    Kelengkapan Tab WindUI (8 Tabs Lengkap):
      1. 🏃 Movement (Fly Toggle, D-Pad Toggle, Fly Speed, WalkSpeed, GodMode, Anti-Fall, Noclip)
      2. ⛏️ Mining & Dig (Auto Dig + Vector3 DigRequest, Surface Snapping Terrain Carver, Auto-Clear Dirt)
      3. ⚡ Remote Hacks (Starfall, Meteor Event, Mountain Regen, Super Luck, Redeem Code)
      4. 👥 Target Player (Player List, TP to Target, Auto Follow, Bring Player Test)
      5. 🎒 Bag & Crystals (Global Sultan Sniper $1k-$1Qa, Size & Luck Filter, Equip-Drop Plot Stacker)
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

saveLocalFile("antartica_logs.txt", "=== Antartica Hub v4.9 Stability Release Dijalankan ===", true)

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
    CarveSpeed = 0.55,
    DigVectorDistance = 5,
    
    -- Target Player
    SelectedPlayerName = nil,
    LoopFollowPlayer = false,

    -- Auto Mine & Gem Magnet
    AutoMineMostExpensive = false,
    AutoPickupGem = false,
    StrictPlotFilter = true,
    SelectedRarityFilter = "Semua (All)",
    CurrentBag = 0,
    MaxBagCapacity = 60000,
    AutoReturnWhenFull = false,
    InstantRemoteSell = true,
    IsReturning = false,
    LastSellTick = 0,

    -- Global Crystal Sniper ($1K - $1Qa, Size, Luck)
    AutoSnipeGlobal = false,
    SnipeMinPrice = 0,
    SnipeMinPriceDisplay = "Semua ($0+)",
    SnipeMinSizeRank = 1,
    SnipeMinSizeDisplay = "Semua Ukuran",
    SnipeMinLuck = 0,
    SnipeMinLuckDisplay = "Semua Luck (0%+)",
    AutoClearDirtRadius = 15,
    IsSniping = false,
    
    -- Anti-Self Drop & Plot Crystal Features
    LastSelfDropTick = 0,
    DroppedGemsCooldown = {},
    AutoTakePlotCrystals = false,
    PlotWideRadius = 200,
    ManualCrystalId = 2481,
    
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

-- HELPER PENCARI REMOTE DINAMIS (ANTI NIL KARENA DELAY REPLIKASI GAME)
local function getRemote(folderName, remoteName)
    local f = ReplicatedStorage:FindFirstChild(folderName) or ReplicatedStorage:WaitForChild(folderName, 1)
    if f then
        local r = f:FindFirstChild(remoteName) or f:WaitForChild(remoteName, 1)
        if r then return r end
    end
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if (desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction")) and desc.Name == remoteName then
            return desc
        end
    end
    return nil
end

-- REMOTES REFERENCE DARI EVENT.TXT (103 REMOTES)
local Remotes = setmetatable({
    DigRequest        = getRemote("DigRemotes", "DigRequest"),
    PickupGem         = getRemote("GemSignals", "PickupGem"),
    GemCollected      = getRemote("GemSignals", "GemCollected"),
    MineHit           = getRemote("GemSignals", "MineHit"),
    SetLuck           = getRemote("GemSignals", "SetLuck"),
    DropCrystal       = getRemote("GemSignals", "DropCrystal"),
    RequestSell       = getRemote("GemRemotes", "RequestSell"),
    OpenSellerMenu    = getRemote("GemRemotes", "OpenSellerMenu"),
    RequestOpenSeller = getRemote("GemRemotes", "RequestOpenSeller"),
    OpenBombShop      = getRemote("BombRemotes", "OpenShop"),
    ExplodeBomb       = getRemote("BombRemotes", "Explode"),
    OpenRadarShop     = getRemote("RadarRemotes", "OpenShop"),
    Starfall          = getRemote("WeatherRemotes", "Starfall"),
    MeteorEvent       = getRemote("MeteorRemotes", "Event"),
    MountainRegen     = getRemote("MountainRemotes", "Regen"),
    AdminControl      = getRemote("MountainRemotes", "AdminControl"),
    RedeemCode        = ReplicatedStorage:FindFirstChild("RedeemCode") or getRemote("RedeemCode", "RedeemCode"),
    GroupVerify       = getRemote("GroupRewardRemotes", "Verify"),
    AdminAbuseTrigger = getRemote("AdminAbuseRemotes", "Trigger"),
    
    -- PLOT REMOTES
    PlaceCrystal      = getRemote("PlotRemotes", "PlaceCrystal"),
    TakeCrystal       = getRemote("PlotRemotes", "TakeCrystal"),
    TakeOut           = getRemote("PlotRemotes", "TakeOut"),
    
    -- BACKPACK TELEPORTS
    TeleportPlot      = getRemote("BackpackRemotes", "TeleportPlot"),
    TeleportSell      = getRemote("BackpackRemotes", "TeleportSell"),
}, {
    __index = function(tbl, key)
        local found = getRemote(key, key)
        if found then rawset(tbl, key, found) return found end
        return nil
    end
})

-- PENCATAT WAKTU DROP SENDIRI (ANTI-MAGNET LANGSUNG)
if Remotes.DropCrystal then
    pcall(function()
        Remotes.DropCrystal.OnClientEvent:Connect(function(dropObj)
            State.LastSelfDropTick = tick()
            if dropObj then
                State.DroppedGemsCooldown[dropObj] = tick()
            end
        end)
    end)
end

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
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("ProximityPrompt") then
                pcall(function() fireproximityprompt(obj) end)
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
-- FUNGSI DETEKSI PLOT SENDIRI & MANAJEMEN KRISTAL PLOT (ISOLASI KETAT)
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
            if minDist < 150 then return closestPlot end
        end
    end
    return nil
end

local function isInsidePlot(obj)
    if not State.StrictPlotFilter then return false end
    if not obj or obj == Workspace or obj == Workspace.Terrain then return false end

    local current = obj
    while current and current ~= Workspace do
        local n = current.Name:lower()
        if (n:find("plot") or n:find("kebun") or n:find("garden") or n:find("farm") or n:find("pajangan") or n:find("display")) and not n:find("baseplate") then
            return true
        end
        current = current.Parent
    end

    local pos = obj:IsA("Model") and obj:GetPivot().Position or (obj:IsA("BasePart") and obj.Position)
    if pos then
        local plotsFolder = Workspace:FindFirstChild("Plots")
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

-- TOGGLE AUTO AMBIL KRISTAL PLOT (ISOLASI TOTAL - TANPA FALLBACK WORKSPACE)
local function sweepAndTakePlotCrystals()
    if not State.AutoTakePlotCrystals then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local myPlot = getMyPlot()
    if not myPlot then return end -- KETAT: Jika bukan di plot sendiri, jangan sentuh apapun!

    for _, obj in ipairs(myPlot:GetDescendants()) do
        if not State.AutoTakePlotCrystals then break end
        if obj:IsA("ProximityPrompt") then
            local pPos = obj.Parent and obj.Parent:IsA("BasePart") and obj.Parent.Position
            if pPos and (pPos - hrp.Position).Magnitude <= State.PlotWideRadius then
                pcall(function() fireproximityprompt(obj) end)
            end
        elseif (obj:IsA("BasePart") or obj:IsA("Model")) then
            local pos = obj:IsA("Model") and obj:GetPivot().Position or obj.Position
            if pos and (pos - hrp.Position).Magnitude <= State.PlotWideRadius then
                local crystalId = obj:GetAttribute("Id") or obj:GetAttribute("CrystalId") or tonumber(obj.Name)
                if crystalId then
                    if Remotes.TakeCrystal then pcall(function() Remotes.TakeCrystal:FireServer(crystalId) end) end
                    if Remotes.TakeOut then pcall(function() Remotes.TakeOut:FireServer(crystalId) end) end
                end
            end
        end
    end
end

task.spawn(function()
    while true do
        if State.AutoTakePlotCrystals then
            sweepAndTakePlotCrystals()
            task.wait(0.6)
        else
            task.wait(1.2)
        end
    end
end)

-- ===================================================================
-- TUMPUK KRISTAL DI PLOT: EQUIP-THEN-DROP (SESUAI MEKANISME GAME)
-- ===================================================================
local function stackGoodCrystalsAtCurrentPosition()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then
        WindUI:Notify({ Title = "⚠️ Karakter Tidak Ada", Content = "Pastikan karakter aktif saat menumpuk kristal!", Duration = 3 })
        return 0
    end

    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    local currentStandPos = hrp.Position
    local itemsToPlace = {}

    -- Simpan referensi pickaxe/alat tambang asli agar bisa di-equip kembali
    local originalPickaxe = nil
    local heldTool = char:FindFirstChildOfClass("Tool")
    if heldTool then
        local hName = heldTool.Name:lower()
        if hName:find("pick") or hName:find("inti") or hName:find("beliung") or hName:find("drill") then
            originalPickaxe = heldTool
        else
            table.insert(itemsToPlace, heldTool)
        end
    end

    -- Pindai seluruh tool kristal di Backpack
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") then
                local iName = item.Name:lower()
                -- Kristal di game ini dinamai berdasarkan bobot kg (misal "124 kilogram", "612 kilogram") atau kata crystal
                if iName:find("kilo") or iName:find("kg") or iName:find("crystal") or iName:find("kristal") or iName:find("gem") or item:GetAttribute("Weight") or item:GetAttribute("Id") then
                    table.insert(itemsToPlace, item)
                elseif not originalPickaxe and (iName:find("pick") or iName:find("inti") or iName:find("beliung") or iName:find("drill")) then
                    originalPickaxe = item
                end
            end
        end
    end

    -- Sortir: Kristal dengan bobot (KG) terbesar atau Luck tertinggi didahulukan
    table.sort(itemsToPlace, function(a, b)
        local wA = tonumber(a.Name:match("([%d%.]+)")) or a:GetAttribute("Weight") or 0
        local wB = tonumber(b.Name:match("([%d%.]+)")) or b:GetAttribute("Weight") or 0
        return wA > wB
    end)

    if #itemsToPlace == 0 and State.ManualCrystalId and State.ManualCrystalId > 0 then
        -- Fallback manual jika di tas tidak ada item tool kristal
        local stackPos = Vector3.new(currentStandPos.X, currentStandPos.Y + 0.5, currentStandPos.Z)
        if Remotes.PlaceCrystal then
            pcall(function() Remotes.PlaceCrystal:FireServer(State.ManualCrystalId, stackPos) end)
        end
        return 1
    end

    if #itemsToPlace == 0 then
        WindUI:Notify({ Title = "⚠️ Kristal Kosong", Content = "Tidak ada kristal terdeteksi di tas (contoh: 124 kilogram)!", Duration = 3 })
        return 0
    end

    local placedCount = 0
    for index, tool in ipairs(itemsToPlace) do
        -- 1. WAJIB PEGANG (EQUIP) KRISTAL KE TANGAN SEBELUM DROP/PLACE KE PLOT
        if tool.Parent == bp then
            hum:EquipTool(tool)
            task.wait(0.18)
        end

        local crystalId = tool:GetAttribute("Id") or tool:GetAttribute("CrystalId") or tonumber(tool.Name:match("%d+")) or State.ManualCrystalId or 2481
        local stackPos = Vector3.new(currentStandPos.X, currentStandPos.Y + ((index - 1) * 0.35), currentStandPos.Z)

        -- 2. Pemicu Place & Drop ke Plot
        if Remotes.PlaceCrystal then
            pcall(function() Remotes.PlaceCrystal:FireServer(crystalId, stackPos) end)
        end
        if Remotes.DropCrystal then
            pcall(function() Remotes.DropCrystal:FireServer(crystalId) end)
        end

        placedCount = placedCount + 1
        task.wait(0.12)
    end

    -- 3. Kembalikan pegangan ke Pickaxe Tambang Utama
    if originalPickaxe and originalPickaxe.Parent == bp then
        hum:EquipTool(originalPickaxe)
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
-- DETEKSI KAPASITAS RANSEL PRESISI (HANYA FORMAT KILOGRAM/KG ASLI GAME)
-- ===================================================================
local function detectActualBagCount()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then return end

    for _, lbl in ipairs(pg:GetDescendants()) do
        if lbl:IsA("TextLabel") and lbl.Visible and lbl.Text ~= "" then
            -- 1. Abaikan mutlak GUI milik script sendiri (WindUI, D-Pad, ErgoControls)
            local pName = lbl.Parent and lbl.Parent.Name:lower() or ""
            local ancestorGui = lbl:FindFirstAncestorOfClass("ScreenGui")
            local guiName = ancestorGui and ancestorGui.Name:lower() or ""
            if guiName:find("wind") or guiName:find("antartica") or pName:find("wind") or pName:find("antartica") then
                continue
            end

            -- 2. Cari format kapasitas ransel game asli: "736.0 / 61267.0 kilogram"
            local raw = lbl.Text
            local cur, max = raw:match("([%d%,%.]+)%s*/%s*([%d%,%.]+)")
            if cur and max then
                local txtLower = raw:lower()
                -- HANYA terima jika benar-benar ada kata kilogram/kg atau parent berlabel ransel/bag
                if txtLower:find("kilo") or txtLower:find("kg") or pName:find("ransel") or pName:find("bag") or pName:find("weight") then
                    local cleanCur = cur:gsub(",", "")
                    local cleanMax = max:gsub(",", "")
                    local cNum = tonumber(cleanCur)
                    local mNum = tonumber(cleanMax)
                    if cNum and mNum and mNum > 100 then
                        State.CurrentBag = cNum
                        State.MaxBagCapacity = mNum
                        return
                    end
                end
            end
        end
    end
end

-- ===================================================================
-- ===================================================================
-- SISTEM PEMBERSIH TANAH & DETEKSI KRISTAL TERTIMBUN (AUTO-CLEAR DIRT)
-- ===================================================================
local function clearDirtAroundPosition(targetPos, repeatCount)
    repeatCount = repeatCount or 3
    if not Remotes.DigRequest then return end

    local offsets = {
        Vector3.new(0, 0, 0),
        Vector3.new(0, -1.2, 0),
        Vector3.new(0, 1.2, 0),
        Vector3.new(1.2, 0, 0),
        Vector3.new(-1.2, 0, 0),
        Vector3.new(0, 0, 1.2),
        Vector3.new(0, 0, -1.2)
    }

    for i = 1, math.min(repeatCount, #offsets) do
        local digVector = targetPos + offsets[i]
        pcall(function() Remotes.DigRequest:FireServer(digVector) end)
        if Remotes.MineHit then pcall(function() Remotes.MineHit:FireServer() end) end
        task.wait(0.04)
    end
end

-- ===================================================================
-- PARSER HARGA BER-SUFFIX ($1K s/d $1Qa), UKURAN & KEBERUNTUNGAN (LUCK)
-- ===================================================================
local priceSuffixes = {
    ["k"]  = 1e3,
    ["m"]  = 1e6,
    ["b"]  = 1e9,
    ["t"]  = 1e12,
    ["qa"] = 1e15,
    ["qi"] = 1e18,
    ["sx"] = 1e21,
    ["sp"] = 1e24,
    ["oc"] = 1e27,
    ["no"] = 1e30,
    ["dc"] = 1e33
}

local function parseNumberWithSuffix(str)
    if not str then return 0, "$0" end
    local clean = tostring(str):gsub("[%,%$%s]", ""):lower()
    local numStr, sufStr = clean:match("([%d%.]+)%s*([a-z]*)")
    if not numStr then return 0, tostring(str) end
    local val = tonumber(numStr) or 0
    if sufStr and priceSuffixes[sufStr] then
        val = val * priceSuffixes[sufStr]
    end
    return val, tostring(str)
end

local sizeRanks = {
    ["tiny"]     = 1,
    ["kecil"]    = 1,
    ["small"]    = 2,
    ["medium"]   = 3,
    ["normal"]   = 3,
    ["sedang"]   = 3,
    ["large"]    = 4,
    ["besar"]    = 4,
    ["huge"]     = 5,
    ["giant"]    = 5,
    ["raksasa"]  = 5,
    ["colossal"] = 6,
    ["kolosus"]  = 6,
    ["massive"]  = 6,
    ["titan"]    = 7,
    ["godly"]    = 7,
    ["mythic"]   = 7
}

local function parseSizeRank(str)
    if not str then return 1, "Normal" end
    local s = tostring(str):lower()
    for name, rank in pairs(sizeRanks) do
        if s:find(name) then
            return rank, name:upper()
        end
    end
    return 1, "Normal"
end

local function parseLuck(str)
    if not str then return 0 end
    local clean = tostring(str)
    local lStr = clean:match("[Kk]eberuntungan:%s*%+?([%d%.]+)") or clean:match("%+([%d%.]+)%%")
    if lStr then
        return tonumber(lStr) or 0
    end
    return 0
end

local function isCrystalCandidate(obj)
    if not obj or obj == Workspace.Terrain then return false end
    local n = obj.Name:lower()
    if n:find("crystal") or n:find("kristal") or n:find("gem") or n:find("ore") or n:find("sundial") or n:find("heart") or n:find("batu") or n:find("drop") then
        return true
    end

    local prompt = obj:FindFirstChildOfClass("ProximityPrompt", true)
    if prompt then
        local act = prompt.ActionText:lower()
        local objT = prompt.ObjectText:lower()
        if act:find("ambil") or act:find("take") or act:find("pick") or objT:find("$") or objT:find("kg") then
            return true
        end
    end

    return false
end

local function extractCrystalInfo(obj)
    if not obj then return nil end
    local cf = obj:IsA("Model") and obj:GetPivot() or (obj:IsA("BasePart") and obj.CFrame)
    if not cf then return nil end

    local prompt = obj:IsA("ProximityPrompt") and obj or obj:FindFirstChildOfClass("ProximityPrompt", true)
    local fullText = ""
    local objText = ""
    local actionText = ""

    if prompt then
        objText = prompt.ObjectText or ""
        actionText = prompt.ActionText or ""
        fullText = objText .. " " .. actionText .. " " .. obj.Name
    else
        fullText = obj.Name
    end

    for _, gui in ipairs(obj:GetChildren()) do
        if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
            for _, lbl in ipairs(gui:GetDescendants()) do
                if lbl:IsA("TextLabel") and lbl.Text ~= "" then
                    fullText = fullText .. " " .. lbl.Text
                end
            end
        end
    end

    -- Ekstrak Harga ($)
    local priceVal = 0
    local priceDisplay = "$0"
    local rawPrice = fullText:match("%$([%d%.,%a]+)")
    if rawPrice then
        priceVal, priceDisplay = parseNumberWithSuffix(rawPrice)
        priceDisplay = "$" .. rawPrice
    else
        local attrPrice = obj:GetAttribute("Price") or obj:GetAttribute("Harga") or obj:GetAttribute("Value")
        if attrPrice then
            priceVal, priceDisplay = parseNumberWithSuffix(attrPrice)
        end
    end

    -- Ekstrak Ukuran (Size)
    local sizeTag = fullText:match("%[([%w%s]+)%]") or ""
    local sizeRank, sizeName = parseSizeRank(sizeTag ~= "" and sizeTag or fullText)

    -- Ekstrak Berat (Weight KG)
    local weightVal = 0
    local rawWeight = fullText:match("([%d%.]+)%s*[Kk][Gg]") or fullText:match("([%d%.]+)%s*kilo")
    if rawWeight then
        weightVal = tonumber(rawWeight) or 0
    else
        local attrW = obj:GetAttribute("Weight") or obj:GetAttribute("Berat")
        if attrW then weightVal = tonumber(attrW) or 0 end
    end

    -- Ekstrak Keberuntungan (Luck %)
    local luckVal = parseLuck(fullText)
    if luckVal == 0 then
        local attrL = obj:GetAttribute("Luck") or obj:GetAttribute("Keberuntungan")
        if attrL then luckVal = tonumber(attrL) or 0 end
    end

    -- Nama Tampilan
    local displayName = obj.Name
    if objText ~= "" then
        displayName = objText:match("%[%w+%]%s*(.-)%s*•") or objText
    end

    return {
        Instance = obj,
        Prompt = prompt,
        CFrame = cf,
        Position = cf.Position,
        Name = displayName,
        FullText = fullText,
        Price = priceVal,
        PriceDisplay = priceDisplay,
        SizeRank = sizeRank,
        SizeName = sizeName,
        Weight = weightVal,
        Luck = luckVal
    }
end

-- ===================================================================
-- PENCARIAN KRISTAL GLOBAL MAP (EXCLUDE PLOT & EXCLUDE DROP SENDIRI)
-- ===================================================================
-- ===================================================================
-- PENCARIAN KRISTAL GLOBAL MAP (EXCLUDE PLOT & EXCLUDE DROP SENDIRI)
-- ===================================================================
local function findCrystalsInMap()
    local list = {}
    local searched = {}

    -- 1. CARI SEMUA PROXIMITYPROMPT DI WORKSPACE (CARA PALING PRESISI UNTUK KRISTAL GAME INI)
    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            local act = (prompt.ActionText or ""):lower()
            local objT = prompt.ObjectText or ""
            -- Kristal di game ini memiliki prompt bertuliskan "AMBIL" atau mengandung "$" atau "KG"
            if act:find("ambil") or act:find("take") or objT:find("%$") or objT:find("kg") or objT:find("kilogram") then
                local crystalObj = prompt.Parent
                if crystalObj and not searched[crystalObj] and not isInsidePlot(crystalObj) then
                    searched[crystalObj] = true
                    local info = extractCrystalInfo(crystalObj)
                    if info then
                        table.insert(list, info)
                    end
                end
            end
        end
    end

    -- 2. CARI DI FOLDER LAINNYA DI WORKSPACE (TERRAIN, GEMS, DEBRIS, ORES, DLL)
    local namedFolders = {
        Workspace:FindFirstChild("Gems"),
        Workspace:FindFirstChild("Crystals"),
        Workspace:FindFirstChild("Drops"),
        Workspace:FindFirstChild("Debris"),
        Workspace:FindFirstChild("Ores"),
        Workspace:FindFirstChild("Map")
    }
    for _, folder in ipairs(namedFolders) do
        if folder then
            for _, obj in ipairs(folder:GetChildren()) do
                if (obj:IsA("Model") or obj:IsA("BasePart")) and not searched[obj] then
                    if isCrystalCandidate(obj) and not isInsidePlot(obj) then
                        searched[obj] = true
                        local info = extractCrystalInfo(obj)
                        if info then
                            table.insert(list, info)
                        end
                    end
                end
            end
        end
    end

    -- Sortir: Harga Dolar ($) Tertinggi > Keberuntungan (Luck) > Ukuran
    table.sort(list, function(a, b)
        if a.Price ~= b.Price then
            return a.Price > b.Price
        elseif a.Luck ~= b.Luck then
            return a.Luck > b.Luck
        else
            return a.SizeRank > b.SizeRank
        end
    end)

    return list
end

-- ===================================================================
-- SCAN & TAMPILKAN KRISTAL TERMAHAL DI MAP (NOTIFIKASI WINDUI)
-- ===================================================================
local function scanAndShowTopCrystal()
    local crystals = findCrystalsInMap()
    if #crystals == 0 then
        WindUI:Notify({
            Title = "🔍 Scan Map",
            Content = "Ditemukan 0 kristal liar di permukaan gunung.\n(Catatan: Di game ini kristal baru muncul dari server saat lereng gunung digali dengan AFK Dig).",
            Duration = 5
        })
        return
    end

    local top = crystals[1]
    WindUI:Notify({
        Title = "💎 Kristal Termahal di Map!",
        Content = string.format("Nama: %s\nHarga: %s\nUkuran: %s\nBobot: %.1f KG\nLuck: +%.1f%%",
            top.Name, top.PriceDisplay, top.SizeName, top.Weight, top.Luck),
        Duration = 6
    })
end

-- ===================================================================
-- DIG ENGINE AFK DENGAN DETEKSI TERTIMBUN & SURFACE SNAPPING
-- ===================================================================
local function triggerDigAction()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local lookDir = Camera.CFrame.LookVector
    local flatDir = Vector3.new(lookDir.X, 0, lookDir.Z).Unit
    if flatDir.Magnitude < 0.1 then flatDir = hrp.CFrame.LookVector end

    -- 1. DETEKSI & AMBIL KRISTAL TERTIMBUN DI DEKAT PEMAIN (RADIUS 15 STUD)
    -- HANYA proses objek non-karakter dan di luar plot
    for _, prompt in ipairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            local pPart = prompt.Parent
            if pPart and not pPart:IsDescendantOf(char) and not isInsidePlot(pPart) then
                local pPos = pPart:IsA("BasePart") and pPart.Position or (pPart:IsA("Model") and pPart:GetPivot().Position)
                if pPos and (pPos - hrp.Position).Magnitude <= 15 then
                    -- Bersihkan tanah timbunan di sekeliling kristal
                    clearDirtAroundPosition(pPos, 2)
                    if type(fireproximityprompt) == "function" then
                        pcall(function() fireproximityprompt(prompt) end)
                    end
                    if Remotes.PickupGem then pcall(function() Remotes.PickupGem:FireServer(pPart) end) end
                    if Remotes.GemCollected then pcall(function() Remotes.GemCollected:FireServer(pPart) end) end
                end
            end
        end
    end

    -- 2. PENGGALIAN NORMAL KE DEPAN LERENG GUNUNG (DIG REQUEST VECTOR3)
    local targetDigVector = hrp.Position + (flatDir * State.DigVectorDistance)
    if Remotes.DigRequest then
        pcall(function() Remotes.DigRequest:FireServer(targetDigVector) end)
    end
    if Remotes.MineHit then
        pcall(function() Remotes.MineHit:FireServer() end)
    end

    -- Pemicu Tool jika dipegang
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then tool:Activate() end

    -- 3. PERGERAKAN MAJU & PANJAT GUNUNG AFK: SURFACE SNAPPING MULUS (TIDAK FREEZE)
    if State.AutoAdvanceMountain and State.AutoDig then
        -- Gerakkan humanoid berjalan ke depan
        hum:Move(flatDir, false)

        local downParams = RaycastParams.new()
        downParams.FilterAncestorsInstances = { char }
        downParams.FilterType = Enum.RaycastFilterType.Exclude

        -- Cek kontur tanah lereng di depan
        local stepAheadPos = hrp.Position + (flatDir * State.CarveSpeed) + Vector3.new(0, 3.5, 0)
        local groundHit = Workspace:Raycast(stepAheadPos, Vector3.new(0, -10, 0), downParams)
        if groundHit then
            local surfaceY = groundHit.Position.Y + 3.0
            local targetPos = Vector3.new(stepAheadPos.X, surfaceY, stepAheadPos.Z)
            -- Gunakan CFrame Lerp agar pergerakan tetap berkesinambungan dan tidak mereset fisika karakter
            hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(targetPos, targetPos + flatDir), 0.5)
        else
            -- Cek tebing di depan untuk lompat otomatis
            local forwardHit = Workspace:Raycast(hrp.Position, flatDir * 3.5, downParams)
            if forwardHit then
                hum.Jump = true
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
            task.wait(0.08)
        else
            task.wait(0.3)
        end
    end
end)

-- ===================================================================
-- GLOBAL CRYSTAL SNIPER (AMBIL KRISTAL MEWAH DI SELURUH MAP)
-- ===================================================================
local function autoSnipeGlobalLoop()
    if not State.AutoSnipeGlobal or State.IsSniping or State.IsReturning then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local crystals = findCrystalsInMap()
    if #crystals == 0 then return end

    for _, c in ipairs(crystals) do
        if not State.AutoSnipeGlobal then break end

        local passPrice = (c.Price >= State.SnipeMinPrice)
        local passSize = (c.SizeRank >= State.SnipeMinSizeRank)
        local passLuck = (c.Luck >= State.SnipeMinLuck)

        if passPrice and passSize and passLuck then
            State.IsSniping = true
            State.LastMiningPosition = hrp.CFrame

            WindUI:Notify({
                Title = "🎯 Sniping Kristal!",
                Content = string.format("Teleport ke %s (%s | %s)!", c.Name, c.PriceDisplay, c.SizeName),
                Duration = 2
            })

            teleportTo(c.CFrame + Vector3.new(0, 1.5, -2))
            task.wait(0.2)

            -- Bersihkan tanah timbunan di sekeliling kristal
            clearDirtAroundPosition(c.Position, 4)
            task.wait(0.1)

            if c.Prompt and type(fireproximityprompt) == "function" then
                pcall(function() fireproximityprompt(c.Prompt) end)
            end
            if Remotes.PickupGem then pcall(function() Remotes.PickupGem:FireServer(c.Instance) end) end
            if Remotes.GemCollected then pcall(function() Remotes.GemCollected:FireServer(c.Instance) end) end

            task.wait(0.3)
            State.IsSniping = false
            break
        end
    end
end

-- ===================================================================
-- AUTO PICKUP & MAGNET GEM DENGAN RARITY FILTER & PROTEKSI DROP
-- ===================================================================
local function autoPickupGemLoop()
    if not State.AutoPickupGem then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if tick() - State.LastSelfDropTick < 6 then return end

    local rarityRank = {
        ["Mythic"] = 6,
        ["Legendary"] = 5,
        ["Epic"] = 4,
        ["Rare"] = 3,
        ["Uncommon"] = 2,
        ["Common"] = 1,
        ["Semua (All)"] = 0
    }
    local filterMinRank = rarityRank[State.SelectedRarityFilter] or 0

    local targetContainer = Workspace:FindFirstChild("Gems") or Workspace:FindFirstChild("Drops") or Workspace
    for _, obj in ipairs(targetContainer:GetChildren()) do
        if not State.AutoPickupGem then break end
        
        if State.DroppedGemsCooldown[obj] and (tick() - State.DroppedGemsCooldown[obj] < 8) then
            continue
        end

        if not isInsidePlot(obj) then
            local n = obj.Name:lower()
            if n:find("gem") or n:find("crystal") or n:find("drop") or n:find("kristal") then
                if obj:IsA("BasePart") or obj:IsA("Model") then
                    local pos = obj:IsA("Model") and obj:GetPivot().Position or obj.Position
                    local dist = (hrp.Position - pos).Magnitude
                    if dist < 45 then
                        local itemRarityRank = 1
                        for rName, rData in pairs(State.RarityConfig) do
                            if n:find(rName:lower()) then
                                itemRarityRank = rData.Priority
                                break
                            end
                        end

                        if itemRarityRank >= filterMinRank then
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
end

-- ===================================================================
-- AUTO-RETURN / INSTANT REMOTE SELL SAAT RANSEL PENUH
-- ===================================================================
local function executeAutoReturnToSell()
    if State.IsReturning or (tick() - State.LastSellTick < 6) then return end
    State.IsReturning = true
    State.LastSellTick = tick()

    if State.InstantRemoteSell then
        if Remotes.RequestSell then
            pcall(function() Remotes.RequestSell:FireServer("All") end)
            pcall(function() Remotes.RequestSell:FireServer() end)
        end
        State.CurrentBag = 0
        WindUI:Notify({ Title = "⚡ Instant Sell (All)", Content = "Ransel Penuh! Kristal berhasil dijual via Remote!", Duration = 2 })
    else
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            State.LastMiningPosition = hrp.CFrame
            WindUI:Notify({ Title = "🎒 Ransel Penuh!", Content = "Teleport ke Toko Jual (Sell)...", Duration = 3 })

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

        if State.AutoPickupGem then
            autoPickupGemLoop()
        end

        if State.AutoReturnWhenFull and not State.IsReturning and (tick() - State.LastSellTick >= 6) then
            if State.MaxBagCapacity > 100 and State.CurrentBag > 0 and State.CurrentBag >= State.MaxBagCapacity then
                executeAutoReturnToSell()
            end
        end

        -- GLOBAL CRYSTAL SNIPER
        if State.AutoSnipeGlobal and not State.IsSniping and not State.IsReturning then
            autoSnipeGlobalLoop()
        end

        -- TP KE KRISTAL TERMAHAL
        if State.AutoMineMostExpensive and not State.IsReturning and not State.IsSniping then
            local crystals = findCrystalsInMap()
            if #crystals > 0 then
                local targetCrystal = crystals[1]
                teleportTo(targetCrystal.CFrame + Vector3.new(0, 1.5, -2))
                clearDirtAroundPosition(targetCrystal.Position, 3)
                
                if targetCrystal.Prompt and type(fireproximityprompt) == "function" then
                    pcall(function() fireproximityprompt(targetCrystal.Prompt) end)
                end
                if Remotes.PickupGem then pcall(function() Remotes.PickupGem:FireServer(targetCrystal.Instance) end) end
                if Remotes.GemCollected then pcall(function() Remotes.GemCollected:FireServer(targetCrystal.Instance) end) end
            end
        end
        task.wait(0.5)
    end
end)

-- ===================================================================
-- PLAYER TARGET & FOLLOW & EXPERIMENTAL BRING PLAYER LOOP
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

    -- STABILITAS TINGGI: HANYA aktifkan noclip jika user secara sengaja meng-ON kan Noclip!
    -- Tidak akan pernah mematikan tabrakan tanah otomatis di AutoDig agar tidak jatuh ke void!
    if State.Noclip and char then
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
    Title = "❄️ Antartica Mining Hub (v5.0)",
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
    Title = "👻 Noclip (Tembus Objek Manual)",
    Desc = "Menembus tebing & bebatuan gunung secara manual",
    Default = false,
    Callback = function(state) State.Noclip = state end
})

-- TAB 2: MINING & DIG
local AutoTab = Window:Tab({ Title = "Mining & Dig", Icon = "zap" })

AutoTab:Toggle({
    Title = "⛏️ Auto Dig Continuous (Vector3 DigRequest)",
    Desc = "AFK Penggalian berulang di lereng gunung menggunakan Payload Vector3",
    Default = false,
    Callback = function(state) State.AutoDig = state end
})

AutoTab:Toggle({
    Title = "🧗 Maju & Panjat Gunung (Surface Snapping)",
    Desc = "Karakter otomatis MAJU & MEMANJAT permukaan tanah lereng gunung tanpa tembus void",
    Default = true,
    Callback = function(state) State.AutoAdvanceMountain = state end
})

AutoTab:Slider({
    Title = "⚡ Kecepatan Maju Carve Gunung",
    Desc = "Atur seberapa jauh langkah maju setiap kali ketukan dig",
    Step = 0.05,
    Value = { Min = 0.1, Max = 1.2, Default = 0.55 },
    Callback = function(val) State.CarveSpeed = val end
})

AutoTab:Slider({
    Title = "📏 Jarak Galian Dig ke Depan",
    Desc = "Jarak jangkauan titik penggalian dari posisi karakter (studs)",
    Step = 1,
    Value = { Min = 2, Max = 15, Default = 5 },
    Callback = function(val) State.DigVectorDistance = val end
})

-- TAB 3: REMOTE HACKS & UTILITIES
local RemoteTab = Window:Tab({ Title = "Remote Hacks", Icon = "cpu" })

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

PlayerTab:Button({
    Title = "🧲 Bring Player Target (Test Client POV)",
    Desc = "Mencoba membawa player target ke posisi Anda (Tampak di Client POV)",
    Callback = function()
        if State.SelectedPlayerName then
            local targetP = Players:FindFirstChild(State.SelectedPlayerName)
            local char = LocalPlayer.Character
            local myHrp = char and char:FindFirstChild("HumanoidRootPart")
            if targetP and targetP.Character and targetP.Character:FindFirstChild("HumanoidRootPart") and myHrp then
                pcall(function()
                    targetP.Character.HumanoidRootPart.CFrame = myHrp.CFrame + Vector3.new(0, 0, 3)
                end)
                WindUI:Notify({ 
                    Title = "🧲 Bring Test (Client POV)", 
                    Content = "Player " .. State.SelectedPlayerName .. " dipindah di Client POV (Catatan: Server Roblox FE membatasi tampilan ke layar player lain).", 
                    Duration = 4 
                })
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

-- TAB 5: BAG & CRYSTALS & SULTAN SNIPER
local BagTab = Window:Tab({ Title = "Bag & Crystals", Icon = "gem" })

BagTab:Toggle({
    Title = "🎯 Auto Snipe Kristal Sultan (Global Map)",
    Desc = "Memindai seluruh map & teleport instan mengambil kristal mewah galian siapapun di gunung",
    Default = false,
    Callback = function(state) State.AutoSnipeGlobal = state end
})

local priceMap = {
    ["Semua ($0+)"]  = 0,
    ["$100K+"]       = 1e5,
    ["$1M+"]         = 1e6,
    ["$10M+"]        = 1e7,
    ["$100M+"]       = 1e8,
    ["$1B+"]         = 1e9,
    ["$100B+"]       = 1e11,
    ["$1T+"]         = 1e12,
    ["$1Qa+"]        = 1e15
}

BagTab:Dropdown({
    Title = "💵 Min. Harga Snipe ($)",
    Desc = "Filter harga minimal kristal yang disnipe ($1K s/d $1Qa)",
    Values = { "Semua ($0+)", "$100K+", "$1M+", "$10M+", "$100M+", "$1B+", "$100B+", "$1T+", "$1Qa+" },
    Default = "Semua ($0+)",
    Callback = function(val)
        State.SnipeMinPriceDisplay = val
        State.SnipeMinPrice = priceMap[val] or 0
    end
})

local sizeRankMap = {
    ["Semua Ukuran"]         = 1,
    ["Medium+ (Sedang)"]     = 3,
    ["Large+ (Besar)"]       = 4,
    ["Giant+ (Raksasa)"]     = 5,
    ["Colossal+ (Kolosus)"]  = 6
}

BagTab:Dropdown({
    Title = "📏 Min. Ukuran Kristal",
    Desc = "Filter ukuran minimal kristal yang diambil",
    Values = { "Semua Ukuran", "Medium+ (Sedang)", "Large+ (Besar)", "Giant+ (Raksasa)", "Colossal+ (Kolosus)" },
    Default = "Semua Ukuran",
    Callback = function(val)
        State.SnipeMinSizeDisplay = val
        State.SnipeMinSizeRank = sizeRankMap[val] or 1
    end
})

local luckMap = {
    ["Semua Luck (0%+)"] = 0,
    ["+0.5%+"]           = 0.5,
    ["+1.0%+"]           = 1.0,
    ["+3.0%+"]           = 3.0,
    ["+5.0%+"]           = 5.0,
    ["+10.0%+"]          = 10.0
}

BagTab:Dropdown({
    Title = "🍀 Min. Keberuntungan (Luck)",
    Desc = "Filter persentase Keberuntungan minimal kristal",
    Values = { "Semua Luck (0%+)", "+0.5%+", "+1.0%+", "+3.0%+", "+5.0%+", "+10.0%+" },
    Default = "Semua Luck (0%+)",
    Callback = function(val)
        State.SnipeMinLuckDisplay = val
        State.SnipeMinLuck = luckMap[val] or 0
    end
})

BagTab:Button({
    Title = "🔍 Scan & Cek Kristal Termahal di Map",
    Desc = "Pindai seluruh map sekarang & tampilkan info kristal termahal via notifikasi",
    Callback = function() scanAndShowTopCrystal() end
})

BagTab:Toggle({
    Title = "💎 Auto Mine Kristal Termahal (Liar)",
    Desc = "Mencari & TP ke kristal termahal liar di gunung (Abaikan Plot & Drop Sendiri)",
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
    Title = "⚡ Instant Remote Sell (RequestSell 'All')",
    Desc = "Jual langsung dari mana saja via RequestSell('All') tanpa teleport balik",
    Default = true,
    Callback = function(state) State.InstantRemoteSell = state end
})

BagTab:Toggle({
    Title = "🎒 Auto Sell Saat Ransel Penuh",
    Desc = "Otomatis memicu RequestSell('All') saat ransel terdeteksi penuh",
    Default = false,
    Callback = function(state) State.AutoReturnWhenFull = state end
})

BagTab:Toggle({
    Title = "🧲 Auto Ambil / Magnet Gem",
    Desc = "Menyedot gem liar (Strict Toggle: Mati Total saat OFF, Menghormati Filter & Cooldown Drop)",
    Default = false,
    Callback = function(state) State.AutoPickupGem = state end
})

BagTab:Dropdown({
    Title = "Filter Kelangkaan Magnet (Rarity Filter)",
    Desc = "Pilih level kristal minimal yang disedot oleh Magnet Gem",
    Values = { "Semua (All)", "Uncommon+", "Rare+", "Epic+", "Legendary+", "Mythic" },
    Default = "Semua (All)",
    Callback = function(val) State.SelectedRarityFilter = val end
})

BagTab:Toggle({
    Title = "🧹 Toggle Auto Ambil Kristal Plot (Wide Radius)",
    Desc = "Hanya menyedot kristal di plot sendiri (Tidak ada kebocoran ke Workspace liar)",
    Default = false,
    Callback = function(state) State.AutoTakePlotCrystals = state end
})

BagTab:Slider({
    Title = "📡 Jangkauan Wide Radius Sedot Plot",
    Desc = "Jarak radius menyedot kristal plot dari posisi berdiri (Default: 200)",
    Step = 10,
    Value = { Min = 50, Max = 500, Default = 200 },
    Callback = function(val) State.PlotWideRadius = val end
})

BagTab:Input({
    Title = "🎯 ID Kristal untuk Ditumpuk (Manual / Custom)",
    Desc = "Masukkan ID kristal yang ingin di-spam tumpuk (Default: 2481)",
    Placeholder = "2481",
    Callback = function(val)
        local n = tonumber(val)
        if n and n > 0 then State.ManualCrystalId = n end
    end
})

BagTab:Button({
    Title = "🥞 Tumpuk Kristal Terbaik (Equip-Then-Drop)",
    Desc = "Pegang kristal terbaik di tas satu per satu lalu tumpuk di titik berdiri saat ini",
    Callback = function()
        local count = stackGoodCrystalsAtCurrentPosition()
        WindUI:Notify({ Title = "Plot Crystal Stacker", Content = string.format("Memproses penumpukan %d kristal di posisi berdiri saat ini!", count), Duration = 3 })
    end
})

BagTab:Button({
    Title = "💰 Jual Semua Kristal Sekarang (Sell All)",
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

print("❄️ Antartica Mining Hub (v5.0 Sultan Sniper & Excavation Release) Berhasil Dimuat!")
WindUI:Notify({
    Title = "❄️ Antartica Hub v5.0 Active",
    Content = "Global Sultan Sniper ($1k-$1Qa) + Auto-Clear Dirt + Equip-Drop Stacker Ready!",
    Duration = 5
})
