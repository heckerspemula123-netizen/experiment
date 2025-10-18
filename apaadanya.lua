
-- =============================
-- UI Loader
-- =============================
local Players   = game:GetService("Players")
local LP        = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

local UI
do
    local ok, err = pcall(function()
        local src = game:HttpGet("https://raw.githubusercontent.com/IkantTongkol/Gui/refs/heads/main/test2")
        UI = loadstring(src)()
        assert(type(UI) == "table" and UI.CreateWindow, "UI lib missing CreateWindow")
    end)
    if not ok then
        warn("[UI] Gagal load:", err)
        local sg = Instance.new("ScreenGui")
        sg.Name = "AutoPlant_FallbackUI"
        sg.ResetOnSpawn = false
        sg.Parent = PlayerGui
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.fromOffset(330, 80)
        lbl.Position = UDim2.fromScale(0.03, 0.1)
        lbl.BackgroundColor3 = Color3.fromRGB(25,25,25)
        lbl.TextColor3 = Color3.fromRGB(255,255,255)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 14
        lbl.TextWrapped = true
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextYAlignment = Enum.TextYAlignment.Top
        lbl.Text = "UI gagal dimuat.\nCek koneksi/GitHub.\nScript berhenti."
        lbl.Parent = sg
        return
    end
end

-- =============================
-- Window & Tabs
-- =============================
local win      = UI:CreateWindow({ Name = "IkanTongkolHUB", Title = "Ikan Tongkol | V0.1" })
local tabPlant = win:CreateTab({ Name = "Main" })
local tabEvent = win:CreateTab({ Name = "Event" })
local tabGarden= win:CreateTab({ Name = "Garden" })
local tabPack  = win:CreateTab({ Name = "Backpack" })
local tabCombat= win:CreateTab({ Name = "Combat" })
local tabShop  = win:CreateTab({ Name = "Shop" })
local tabUtil  = win:CreateTab({ Name = "Utility" })
local function notify(t, m, d)
    if win and win.Notify then win:Notify(t, m, d or 2.0) else print(("[UI] %s: %s"):format(t, m)) end
end

-- =============================
-- Services & Remotes (packed)
-- =============================
local S = {
  Players    = Players,
  RS         = game:GetService("ReplicatedStorage"),
  Debris     = game:GetService("Debris"),
  Run        = game:GetService("RunService"),
  UIS        = game:GetService("UserInputService"),
  VU         = game:GetService("VirtualUser"),
  Plots      = workspace:WaitForChild("Plots"),
  Scripted   = workspace:WaitForChild("ScriptedMap"),
}
local RM = (function(RS)
  local r = RS:WaitForChild("Remotes")
  local a = r:FindFirstChild("AttacksServer")
  return {
    EquipItem      = r:WaitForChild("EquipItem"),
    PlaceItem      = r:WaitForChild("PlaceItem"),
    RemoveItem     = r:WaitForChild("RemoveItem"),
    BuyItem        = r:WaitForChild("BuyItem"),
    BuyGear        = r:WaitForChild("BuyGear"),
    EquipBest      = r:WaitForChild("EquipBestBrainrots"),
    GiftItem       = r:WaitForChild("GiftItem"),
    AcceptGift     = r:WaitForChild("AcceptGift"),
    Favorite       = r:WaitForChild("FavoriteItem"),
    ItemSell       = r:WaitForChild("ItemSell"),
    UseItem        = r:WaitForChild("UseItem"),
    PromptFuse     = r:FindFirstChild("PromptFuse"),
    PlacePlantEval = r:FindFirstChild("PlacePlantMachine"),
    SpawnBR        = r:FindFirstChild("SpawnBrainrot"),
    DeleteBR       = r:FindFirstChild("DeleteBrainrot"),
    OpenUI         = r:FindFirstChild("OpenUI"),
    WeaponAttack   = a and a:FindFirstChild("WeaponAttack"),
  }
end)(S.RS)

-- Optional Util
local Modules  = S.RS:FindFirstChild("Modules")
local Utility  = Modules and Modules:FindFirstChild("Utility")
local Util     = Utility and require(Utility:WaitForChild("Util"))

-- =============================
-- Shared helpers (F)
-- =============================
local F = {}

function F.norm(s) return (tostring(s or "")):lower() end
function F.stripBrackets(s) local out=tostring(s or ""); repeat local prev=out; out=out:gsub("^%b[]%s*","") until out==prev; return out end
function F.safeName(inst)
  local raw=(typeof(inst)=="Instance" and inst.GetAttribute and inst:GetAttribute("ItemName")) or (typeof(inst)=="Instance" and inst.Name) or tostring(inst)
  return tostring(raw):gsub("^%b[]%s*","")
end
function F.partCFrame(inst)
  if inst:IsA("BasePart") then return inst.CFrame end
  if inst:IsA("Model") then return (inst.PrimaryPart and inst.PrimaryPart.CFrame) or inst:GetPivot() end
  return CFrame.new()
end
function F.setToggleState(tg, state)
  if not tg then return end
  pcall(function()
    if tg.Set then tg:Set(state)
    elseif tg.SetState then tg.SetState(state)
    elseif tg.SetValue then tg.SetValue(state)
    elseif tg.Toggle and tg.State ~= state then tg:Toggle() end
  end)
end
function F.updateDropdown(drop, options)
  if drop.Refresh     and pcall(function() drop:Refresh(options,true) end) then return end
  if drop.SetOptions  and pcall(function() drop:SetOptions(options) end) then return end
  if drop.SetItems    and pcall(function() drop:SetItems(options) end) then return end
  if drop.ClearOptions and drop.AddOption then pcall(function() drop:ClearOptions(); for _,n in ipairs(options) do drop:AddOption(n) end end) return end
  drop.Options = options
end
function F.myPlayerFolder() local wp=workspace:FindFirstChild("Players"); return wp and wp:FindFirstChild(LP.Name) or nil end
function F.worldPosOf(node)
  if not node then return nil end
  if node:IsA("BasePart") then return node.Position end
  if node:IsA("Model") then local ok,cf=pcall(node.GetPivot,node); if ok and cf then return cf.Position end; if node.PrimaryPart then return node.PrimaryPart.Position end end
  local adornee=(node.Adornee and node.Adornee) or (node:FindFirstChild("Adornee") and node.Adornee)
  if typeof(adornee)=="Instance" then return F.worldPosOf(adornee) end
  local p=node.Parent; if p then return F.worldPosOf(p) end
  return nil
end
function F.readModelSize(m) local sz=m:GetAttribute("Size"); if type(sz)=="number" then return sz end local ok,_,bbox=pcall(m.GetBoundingBox,m); return (ok and bbox) and math.max(bbox.X,bbox.Y,bbox.Z) or 0 end
function F.readModelHP(m) local hum=m:FindFirstChildOfClass("Humanoid"); if hum and hum.Health then return hum.Health end local hp=m:GetAttribute("Health") or m:GetAttribute("HP") or m:GetAttribute("MaxHealth"); return type(hp)=="number" and hp or 0 end

-- HRP/Hum (shared)
local HRP = (LP.Character or LP.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart", 15)
local Hum = (LP.Character or LP.CharacterAdded:Wait()):WaitForChild("Humanoid", 15)
LP.CharacterAdded:Connect(function(ch)
  task.defer(function()
    HRP = ch:WaitForChild("HumanoidRootPart", 15)
    Hum = ch:WaitForChild("Humanoid", 15)
  end)
end)

-- Plot helpers
local function findMyPlot()
  for _, p in ipairs(S.Plots:GetChildren()) do if p:GetAttribute("OwnerUserId")==LP.UserId then return p end end
  for _, p in ipairs(S.Plots:GetChildren()) do if p:GetAttribute("Owner")==LP.Name then return p end end
end
local function gotoCFrame(cf) if HRP and cf then HRP.AssemblyLinearVelocity = Vector3.zero; HRP.CFrame = cf end end

-- =============================
-- [UTILITY] QoL Tools
-- =============================
do
  tabPlant:CreateSectionFold({ Title = "Movement" })
  local ws, jp = 16, 50
  local function getHum() local ch = LP.Character or LP.CharacterAdded:Wait(); return ch:FindFirstChildOfClass("Humanoid") end
  tabPlant:Slider({ Name="WalkSpeed", Min=10, Max=120, Default=16, Callback=function(v) ws=v; local h=getHum(); if h then pcall(function() h.WalkSpeed=ws end) end end })
  tabPlant:Slider({ Name="JumpPower", Min=20, Max=200, Default=50, Callback=function(v) jp=v; local h=getHum(); if h then pcall(function() h.JumpPower=jp end) end end })
end


-- =============================
-- [UTILITY] Reconnect / Rejoin / Hop (simple controls)
-- =============================
do
  local Players         = game:GetService("Players")
  local TeleportService = game:GetService("TeleportService")
  local CoreGui         = game:GetService("CoreGui")
  local HttpService     = game:GetService("HttpService")
  local RS              = game:GetService("RunService")
  local LP              = Players.LocalPlayer

  tabPlant:CreateSectionFold({ Title = "Server" })

  -- ====== STATE & CONFIG ======
  local cfg = {
    autoReconnect = false,     -- toggle #1
    rejoinDelay   = 2.0,       -- input #1 (detik)
    loopRejoin    = false,     -- toggle #2
    hopDelay      = 5.0,       -- input #2 (detik)
    loopHop       = false,     -- toggle #3
    preferSame    = true,      -- tetap coba server yang sama dulu
  }

  local busy = false -- guard supaya tidak double-teleport

  local function sleep(sec)
    local t0 = os.clock() + (tonumber(sec) or 0)
    while os.clock() < t0 do RS.Heartbeat:Wait() end
  end

  local function getCandidateServers()
    local ok, body = pcall(function()
      return game:HttpGet(
        ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
      )
    end)
    if not ok then return {} end
    local data; pcall(function() data = HttpService:JSONDecode(body) end)
    local list = {}
    for _, s in ipairs((data and data.data) or {}) do
      if s.id ~= game.JobId and s.playing < s.maxPlayers then
        table.insert(list, s.id)
      end
    end
    return list
  end

  local function rejoin(sameFirst)
    if busy then return end
    busy = true
    -- jeda sesuai timer rejoin
    sleep(cfg.rejoinDelay)

    local ok = pcall(function()
      if sameFirst ~= false then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
      else
        TeleportService:Teleport(game.PlaceId, LP)
      end
    end)

    if not ok then
      -- fallback: coba hop
      local servers = getCandidateServers()
      if #servers > 0 then
        local id = servers[Random.new():NextInteger(1, #servers)]
        pcall(function()
          TeleportService:TeleportToPlaceInstance(game.PlaceId, id, LP)
        end)
      else
        -- fallback terakhir
        pcall(function()
          TeleportService:Teleport(game.PlaceId, LP)
        end)
      end
    end
    busy = false
  end

  local function hopNewServer()
    if busy then return end
    busy = true
    sleep(cfg.hopDelay)
    local servers = getCandidateServers()
    if #servers > 0 then
      local id = servers[Random.new():NextInteger(1, #servers)]
      pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, id, LP)
      end)
    else
      pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
    end
    busy = false
  end

  -- ====== AUTO RECONNECT (event-driven) ======
  local function hookErrorPrompt(gui)
    local function scan()
      if not cfg.autoReconnect or busy then return end
      for _, d in ipairs(gui:GetDescendants()) do
        if (d:IsA("TextLabel") or d:IsA("TextBox")) and typeof(d.Text)=="string" then
          local t = d.Text:lower()
          if t:find("disconnected") or t:find("you were kicked")
             or t:find("lost connection") or t:find("please check your internet") then
            rejoin(cfg.preferSame)
            break
          end
        end
      end
    end
    gui.DescendantAdded:Connect(scan)
    gui:GetPropertyChangedSignal("Enabled"):Connect(scan)
    task.defer(scan)
  end

  do
    local prompt = CoreGui:FindFirstChild("RobloxPromptGui")
    if prompt then hookErrorPrompt(prompt) end
    CoreGui.ChildAdded:Connect(function(c)
      if c.Name == "RobloxPromptGui" then hookErrorPrompt(c) end
    end)
  end

  TeleportService.TeleportInitFailed:Connect(function(_, result)
    if cfg.autoReconnect and not busy then
      task.defer(function() rejoin(cfg.preferSame) end)
    end
  end)

  -- ====== LOOPS ======
  task.spawn(function()
    while true do
      if cfg.loopRejoin and not busy then rejoin(cfg.preferSame) end
      sleep(0.25) -- loop ringan; jeda utama pakai cfg.rejoinDelay di rejoin()
    end
  end)

  task.spawn(function()
    while true do
      if cfg.loopHop and not busy then hopNewServer() end
      sleep(0.25) -- jeda utama pakai cfg.hopDelay di hopNewServer()
    end
  end)

  -- ====== UI KONTROL (sesuai permintaan) ======
  tabPlant:Toggle({
    Name   = "Auto Reconnect",
    Flag   = "ar_enable",
    Default= false,
    Callback = function(on) cfg.autoReconnect = on end
  })

  tabPlant:Input({
    Name = "Timer Rejoin (detik)",
    PlaceholderText = tostring(cfg.rejoinDelay),
    NumbersOnly = true,
    Flag = "ar_rejoin_delay",
    Callback = function(txt)
      local v = tonumber(txt)
      if v and v >= 0 then cfg.rejoinDelay = v end
    end
  })

  tabPlant:Toggle({
    Name   = "Rejoin (loop)",
    Flag   = "ar_loop_rejoin",
    Default= false,
    Callback = function(on) cfg.loopRejoin = on end
  })

  tabPlant:Input({
    Name = "Hop Server ke Server Baru (detik)",
    PlaceholderText = tostring(cfg.hopDelay),
    NumbersOnly = true,
    Flag = "ar_hop_delay",
    Callback = function(txt)
      local v = tonumber(txt)
      if v and v >= 0 then cfg.hopDelay = v end
    end
  })

  tabPlant:Toggle({
    Name   = "Hop Server (loop)",
    Flag   = "ar_loop_hop",
    Default= false,
    Callback = function(on) cfg.loopHop = on end
  })
end


-- ========== TAB MAIN: Auto Plant / Anti-AFK / Auto Fuse ==========
do
  -- --- Anti-AFK ---
  tabPlant:CreateSectionFold({ Title = "Anti-AFK" })
  local antiAFKEnabled, idleKickSeconds, lastActivity = false, 120, os.clock()
  S.UIS.InputBegan:Connect(function() lastActivity = os.clock() end)
  S.UIS.InputChanged:Connect(function() lastActivity = os.clock() end)
  local function tinyWiggle() pcall(function() S.VU:CaptureController(); S.VU:ClickButton2(Vector2.new(0,0)) end) end
  local function antiAFKLoop()
    while antiAFKEnabled do
      if os.clock() - lastActivity >= idleKickSeconds - 1 then
        tinyWiggle(); lastActivity=os.clock(); notify("Anti-AFK","Ping kecil (reset AFK)",1.0); task.wait(0.1)
      end
      task.wait(1.0)
    end
  end
  tabPlant:Toggle({ Name="Enable Anti-AFK (otomatis saat idle ~2 menit)", Default=false,Flag="anti_afk",Callback=function(on) antiAFKEnabled=on; if on then task.spawn(antiAFKLoop) end end })

end

-- =============================
-- Tab Main ▸ Card Event — Auto TP + Claim + Return (One Toggle)
-- =============================
do
  -- [UI] Seksi + komponen di tab Event
  local sec = tabEvent:CreateSectionFold({ Title = "Defeate Brainrot Event" })

  local statusRow = tabEvent:Label("Status: Menunggu…")
  local statusText = statusRow -- pegangan label
  local autoToggle -- dideklarasi dulu, diisi setelah fungsi

  -- ====== Services & locals ======
  local Players = game:GetService("Players")
  local ReplicatedStorage = game:GetService("ReplicatedStorage")
  local RunService = game:GetService("RunService")

  local LP = Players.LocalPlayer

  -- ====== Wait helper untuk path bertingkat ======
  local function waitFor(pathTbl)
    local node = pathTbl[1]
    for i = 2, #pathTbl do
      repeat RunService.Heartbeat:Wait() until node:FindFirstChild(pathTbl[i])
      node = node[pathTbl[i]]
    end
    return node
  end

  -- ====== World refs / remotes ======
  local Remotes         = waitFor({ReplicatedStorage,"Remotes"})
  local CardUpdateEvent = waitFor({Remotes,"CardUpdateEvent"})

  local ScriptedMap     = waitFor({workspace,"ScriptedMap"})
  local Event           = waitFor({ScriptedMap,"Event"})
  local EventRewards    = waitFor({Event,"EventRewards"})
  local TalkPart        = waitFor({EventRewards,"TalkPart"})
  local ProximityPrompt = waitFor({TalkPart,"ProximityPrompt"})

  -- (opsional) indikator dari billboard dunia
  local TomadeFloor     = waitFor({Event,"TomadeFloor"})
  local Billboard       = waitFor({TomadeFloor,"GuiAttachment","Billboard"})
  local Display         = waitFor({Billboard,"Display"})
  local Checkmark       = waitFor({Billboard,"Checkmark"})

  -- ====== Utils karakter / TP ======
  local function getParts()
    local ch = LP.Character or LP.CharacterAdded:Wait()
    return ch, ch:WaitForChild("Humanoid"), ch:WaitForChild("HumanoidRootPart")
  end

  local function hasClearLOS(fromPos, toPart)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LP.Character}
    local dir = (toPart.Position - fromPos)
    local hit = workspace:Raycast(fromPos, dir, params)
    return not hit or hit.Instance:IsDescendantOf(toPart)
  end

  local function computeTargetPos()
    local base = TalkPart
    local halfY = (base.Size and base.Size.Y or 4)/2
    local ringR = math.max((ProximityPrompt.MaxActivationDistance or 10) - 1, 5)
    local candidates = { base.Position + Vector3.new(0, halfY + 3, 0) }
    for i=0,7 do
      local ang = (math.pi*2) * (i/8)
      local offset = Vector3.new(math.cos(ang), 0, math.sin(ang)) * ringR
      table.insert(candidates, base.Position + offset + Vector3.new(0, 2, 0))
    end
    for _,pos in ipairs(candidates) do
      if hasClearLOS(pos, base) then return pos end
    end
    return candidates[1]
  end

  -- Simpan & balik posisi
  local savedPivotCFrame = nil
  local function saveCurrentPivot()
    local ch = LP.Character or LP.CharacterAdded:Wait()
    savedPivotCFrame = ch:GetPivot()
  end
  local function returnToSavedPivot()
    if savedPivotCFrame then
      local ch = LP.Character
      if ch then ch:PivotTo(savedPivotCFrame) end
    end
    savedPivotCFrame = nil
  end

  local function tpToTalkPart()
    local ch, hum = getParts()
    if not (ch and hum and TalkPart) then return end
    hum.Sit = false; hum.PlatformStand = false; hum:Move(Vector3.zero)
    local target = computeTargetPos()
    ch:PivotTo(CFrame.new(target, TalkPart.Position))
    RunService.Heartbeat:Wait()
  end

  local function pressPromptOnce()
    if not ProximityPrompt.Enabled then return false end
    if not ProximityPrompt:IsDescendantOf(workspace) then return false end
    local _,_,hrp = getParts(); if not hrp then return false end
    local dist = (hrp.Position - TalkPart.Position).Magnitude
    local maxD = (ProximityPrompt.MaxActivationDistance or 10) + 0.5
    if dist > maxD then return false end
    if ProximityPrompt.ActionText ~= "Claim" then return false end
    ProximityPrompt:InputHoldBegin()
    task.delay((ProximityPrompt.HoldDuration or 0) + 0.05, function()
      ProximityPrompt:InputHoldEnd()
    end)
    return true
  end

  local function autoClaimRetry()
    for _=1,3 do
      if pressPromptOnce() then return true end
      RunService.Heartbeat:Wait()
    end
    return false
  end

  -- ====== State & flow ======
  local running = false
  local function setStatus(txt, green)
    if statusText and statusText.Text then
      statusText.Text = txt
      statusText.TextColor3 = green and Color3.fromRGB(0,255,128) or Color3.fromRGB(255,200,0)
    end
  end

  -- ALUR: SAVE -> TP -> delay 2s -> CLAIM -> RETURN
  local function runOnce()
    if running then return end
    running = true

    setStatus("Menyimpan posisi…", false)
    saveCurrentPivot()

    setStatus("Teleport…", false)
    tpToTalkPart()

    setStatus("Tunggu 2 detik…", false)
    task.wait(2)

    setStatus("Claim…", true)
    autoClaimRetry()

    task.wait(0.1)

    setStatus("Balik posisi…", false)
    returnToSavedPivot()

    setStatus("Selesai. Menunggu lagi…", false)
    running = false
  end

  -- Toggle UI (pakai kontrol TongkolUI)
  autoToggle = tabEvent:Toggle({ Name = "Auto Claim Defeat Brainrot", Default = false, Flag = "auto_card_event", Callback = function(on)
      if on then
        setStatus("Menunggu sinyal Claim…", false)
      else
        setStatus("Status: OFF", false)
      end
    end
  })

  -- Trigger dari server (paling akurat)
  CardUpdateEvent.OnClientEvent:Connect(function(tag, ...)
    if tag ~= "updateDefeatedVisual" then return end
    local canClaim = ...
    if autoToggle:Get() and canClaim == true then
      runOnce()
    end
  end)

  -- Tambahan: trigger dari billboard world (kalau terlihat “Claim”)
  local function isClaimFromGui()
    return Display.Text == "Claim" and Checkmark.Visible == true and ProximityPrompt.ActionText == "Claim"
  end
  local function guiChanged()
    if autoToggle:Get() and isClaimFromGui() then
      runOnce()
    end
  end
  Display:GetPropertyChangedSignal("Text"):Connect(guiChanged)
  Checkmark:GetPropertyChangedSignal("Visible"):Connect(guiChanged)
  ProximityPrompt:GetPropertyChangedSignal("ActionText"):Connect(guiChanged)

  -- Init status
  setStatus("Menunggu…", false)
  if isClaimFromGui() then setStatus("Claim terdeteksi (toggle OFF).", true) end
end


-- =============================
-- Daily Brainrot — Needed + Auto Place (TP) with safe-skip
-- =============================
do
  local Players = game:GetService("Players")
  local RS      = game:GetService("ReplicatedStorage")
  local LP      = Players.LocalPlayer
  local HRP,Hum
  local function bindChar(ch)
    task.defer(function()
      HRP = ch:WaitForChild("HumanoidRootPart",15)
      Hum = ch:WaitForChild("Humanoid",15)
    end)
  end
  bindChar(LP.Character or LP.CharacterAdded:Wait())
  LP.CharacterAdded:Connect(bindChar)

  -- UI
  tabEvent:CreateSectionFold({ Title = "Daily Brainrot Event" })
  local dayLbl   = tabEvent:Label("Day: (loading...)")
  local needLbl  = tabEvent:Paragraph("Needed: (loading...)")
  local slotsLbl = tabEvent:Label("Slots: -1: —  |  -2: —  |  -3: —  |  -4: —")
  tabEvent:Divider()
  local statusLb = tabEvent:Label("Status: OFF")

  -- Config
  local ORDER = {"-1","-2","-3","-4"}
  local TP_Y=3; local PROMPT_TIMEOUT=4; local TRY_PAUSE=0.15

  -- Helpers
  local function norm(s) s=tostring(s or ""):lower():gsub("^%b[]%s*",""); return s end
 
  local function myPlot()
    local P = workspace:FindFirstChild("Plots"); if not P then return nil end
    for _,p in ipairs(P:GetChildren()) do
      if p:GetAttribute("OwnerUserId")==LP.UserId or p:GetAttribute("Owner")==LP.Name then return p end
    end
  end

  local function getNode(plot,key)
    local ep = plot and plot:FindFirstChild("EventPlatforms"); if not ep then return end
    return ep:FindFirstChild(key)
  end

  local function getPrompt(plot,key)
    local node = getNode(plot,key); if not node then return nil,nil end
    local hb = node:FindFirstChild("Hitbox")
    local pp = hb and hb:FindFirstChildWhichIsA("ProximityPrompt", true)
    return pp, node
  end

  -- cek posisi brainrot di dunia (untuk centang)
  local BR_SEARCH = (function()
    local list = {}
    local sm = workspace:FindFirstChild("ScriptedMap")
    if sm and sm:FindFirstChild("Brainrots") then table.insert(list, sm.Brainrots) end
    if workspace:FindFirstChild("Brainrots") then table.insert(list, workspace.Brainrots) end
    if workspace:FindFirstChild("Brainrot")  then table.insert(list, workspace.Brainrot)  end
    return list
  end)()

  local function slotCenter(plot,key)
    local node = getNode(plot,key); if not node then return nil end
    local hb = node:FindFirstChild("Hitbox")
    if hb and hb:IsA("BasePart") then return hb.Position end
    local ok,cf = pcall(node.GetPivot,node); return ok and cf.Position or nil
  end
  local function modelPos(m)
    if m:IsA("BasePart") then return m.Position end
    if m:IsA("Model") then
      local pp = m.PrimaryPart or m:FindFirstChild("HumanoidRootPart")
      if pp then return pp.Position end
      local ok,cf = pcall(m.GetPivot,m); if ok then return cf.Position end
    end
  end
  local function isPlacedOnSlot(plot,key,needName)
    local pos = slotCenter(plot,key); if not pos or not needName then return false end
    local want = norm(needName); local R = 11
    for _,folder in ipairs(BR_SEARCH) do
      for _,m in ipairs(folder:GetChildren()) do
        local nm = norm(m:GetAttribute("Brainrot") or m.Name)
        if nm==want then
          local mp = modelPos(m); if mp and (mp-pos).Magnitude<=R then return true end
        end
      end
    end
    return false
  end

  -- reader Daily (robust)
  local function getDaily()
    local okDG,DailyGetter = pcall(function()
      return require(RS:WaitForChild("Modules"):WaitForChild("Library")
                       :WaitForChild("Events"):WaitForChild("DailyGetter"))
    end)
    if not okDG or type(DailyGetter)~="table" then return {day="(N/A)", list={}, slots={}} end
    local okTab,root = pcall(DailyGetter.GetTables)
    if not okTab or type(root)~="table" then return {day="(N/A)", list={}, slots={}} end

    local function toName(v)
      if type(v)=="string" then return v end
      if typeof(v)=="Instance" then return v.Name end
      if type(v)=="table" then
        if v.Name then return tostring(v.Name) end
        if type(v[1])=="string" then return v[1] end
      end
      return tostring(v)
    end
    local slots={["-1"]=nil,["-2"]=nil,["-3"]=nil,["-4"]=nil}
    local function scan(t,d)
      if d>5 or type(t)~="table" then return end
      for k,v in pairs(t) do
        if type(k)=="string" and k:match("^%-%d$") and slots[k]==nil then slots[k]=toName(v) end
        if type(v)=="table" then scan(v,d+1) end
      end
    end
    if type(root[1])=="table" then scan(root[1],1) end
    if type(root.Slots)=="table" then scan(root.Slots,1) end
    scan(root,1)

    local seen, list = {}, {}
    for _,n in pairs(slots) do if n and not seen[n] then seen[n]=true; table.insert(list,n) end end
    table.sort(list)
    return {day=tostring(root[3] or root.Day or "Day?"), list=list, slots=slots}
  end

  -- alat & TP
  local Remotes = RS:FindFirstChild("Remotes")
  local EquipRemote = Remotes and Remotes:FindFirstChild("EquipItem")
  local BrainrotNames=(function()
    local set={}; local ok,folder=pcall(function() return RS.Assets.Brainrots end)
    if ok and folder then for _,ch in ipairs(folder:GetChildren()) do set[ch.Name:lower()]=true end end
    return set
  end)()
  local function isBRTool(t)
    if not (t and t:IsA("Tool")) then return false end
    local nm = norm(t:GetAttribute("ItemName") or t.Name)
    return BrainrotNames[nm] or (t:GetAttribute("Category") or ""):lower()=="brainrot" or t:GetAttribute("Brainrot")==true
  end
  local function findToolByName(name)
    local want=norm(name)
    local function match(t)
      if not t:IsA("Tool") or not isBRTool(t) then return false end
      local n1=norm(t.Name); local n2=norm(t:GetAttribute("ItemName") or t.Name)
      return n1==want or n2==want or n1:find(want,1,true) or n2:find(want,1,true)
    end
    local ch=LP.Character; if ch then for _,t in ipairs(ch:GetChildren()) do if match(t) then return t end end end
    local bp=LP:FindFirstChild("Backpack"); if bp then for _,t in ipairs(bp:GetChildren()) do if match(t) then return t end end end
    local pf=workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild(LP.Name)
    if pf then for _,t in ipairs(pf:GetChildren()) do if match(t) then return t end end end
    return nil
  end
  local function hardEquip(tool)
    local ch=LP.Character or LP.CharacterAdded:Wait()
    local hum=ch and ch:FindFirstChildOfClass("Humanoid")
    if not (tool and hum) then return false end
    for _=1,8 do
      pcall(function() hum:EquipTool(tool) end)
      if EquipRemote then pcall(function() EquipRemote:FireServer(tool) end) end
      if tool.Parent==ch then return true end
      task.wait(0.06)
    end
    return tool.Parent==ch
  end
  local function tpAbove(node,pp)
    if not (HRP and node) then return false end
    local pos
    if node:FindFirstChild("Hitbox") and node.Hitbox:IsA("BasePart") then
      pos = node.Hitbox.Position
    else
      local ok,cf=pcall(node.GetPivot,node)
      pos = ok and cf.Position or (pp and pp.Parent.Position)
    end
    if not pos then return false end
    local cam=workspace.CurrentCamera; local look=cam and cam.CFrame.LookVector or Vector3.new(0,0,-1)
    HRP.AssemblyLinearVelocity=Vector3.zero
    HRP.CFrame=CFrame.new(pos+Vector3.new(0,TP_Y,0), pos+look)
    return true
  end

  -- ===== Return-to-Home helpers =====
local function captureHomeCF()
  return HRP and HRP.CFrame or nil
end

local function returnHomeCF(homeCF)
  if not (HRP and homeCF) then return false end
  HRP.AssemblyLinearVelocity = Vector3.zero
  -- naikkan sedikit biar nggak nyangkut permukaan
  local cf = homeCF + Vector3.new(0, 0.5, 0)
  HRP.CFrame = cf
  return true
end


  local function holdPrompt(pp)
    if not pp then return false end
    local fpp=rawget(getfenv(),"fireproximityprompt"); local tEnd=time()+PROMPT_TIMEOUT
    if typeof(fpp)=="function" then
      repeat pcall(fpp,pp,math.max(pp.HoldDuration or 0,0.25)); task.wait(TRY_PAUSE) until time()>tEnd or pp.Enabled==false
      return true
    end
    repeat
      if pp.InputHoldBegin then pcall(function() pp:InputHoldBegin() end); task.wait(pp.HoldDuration or 0.5); pcall(function() pp:InputHoldEnd() end)
      else pcall(function() pp:TriggerEnded(LP) end) end
      task.wait(TRY_PAUSE)
    until time()>tEnd
    return true
  end

  -- slotAvailable: TRUE hanya jika prompt "Place" ADA & Enabled
  local function slotAvailable(plot,key)
    local pp,node = getPrompt(plot,key)
    if not pp then return false, pp, node end           -- prompt hilang = sudah terpasang
    if pp.Enabled == false then return false, pp, node end
    local txt = tostring(pp.ActionText or ""):lower()
    if txt~="" and not txt:find("place") then
      -- jika actionText bukan "Place", treat sebagai tidak tersedia
      return false, pp, node
    end
    return true, pp, node
  end

  -- render GUI sekali
  local function renderOnce()
    local info = getDaily()
    dayLbl:Set("Day: "..tostring(info.day))

    local plot = myPlot()
    local lines = {}
    for _,name in ipairs(info.list) do
      local tick = ""
      if plot then
        local placed=false
        for _,k in ipairs(ORDER) do
          if info.slots[k]==name then
            -- jika prompt tidak ada ATAU posisi cocok → dianggap terpasang
            local avail = select(1, slotAvailable(plot,k))  -- true kalau masih kosong
            if (not avail) or isPlacedOnSlot(plot,k,name) then placed=true break end
          end
        end
        tick = placed and "✓ " or "  "
      end
      table.insert(lines, tick..name)
    end
    needLbl:Set("Needed:\n"..(#lines>0 and table.concat(lines, "\n") or "(none)"))

    local slotTxt = {}
    for _,k in ipairs(ORDER) do
      local nm = info.slots[k]
      local avail = plot and select(1, slotAvailable(plot,k))
      local placed = (plot and nm) and (not avail or isPlacedOnSlot(plot,k,nm)) or false
      local mark = placed and "✓ " or ""
      table.insert(slotTxt, string.format("%s: %s%s", k, mark, tostring(nm or "—")))
    end
    slotsLbl:Set("Slots: "..table.concat(slotTxt, "  |  "))

    return info, plot
  end

  local enabled=false
  -- toggle
  tabEvent:Toggle({
    Name="Auto Place Daily Brainrots (TP)",
    Default=false,
    Flag="auto_daily_brainrot",
    Callback=function(on)
      enabled = on
      statusLb:Set(on and "Status: ON (scanning…)" or "Status: OFF")
      if on then
        task.spawn(function()
          while enabled do
            local info, plot = renderOnce()
            if plot and HRP and Hum then
              for _,k in ipairs(ORDER) do
                if not enabled then break end
                local need = info.slots[k]
                if need and #need>0 then
                  local avail, pp, node = slotAvailable(plot,k)
                  -- SKIP kalau sudah terpasang (avail=false) atau terdeteksi ada brainrot di slot
                  if (not avail) or isPlacedOnSlot(plot,k,need) then
                    -- tidak TP
                  else
                    local tool = findToolByName(need)
                    if tool then
                      statusLb:Set(string.format("Status: %s (%s) → tp & place", k, need))
                      if hardEquip(tool) and tpAbove(node,pp) then
                        task.wait(0.07); holdPrompt(pp)
                      else
                        statusLb:Set(string.format("Status: %s → prompt/equip fail", k))
                      end
                      task.wait(0.25)
                    else
                      statusLb:Set(string.format("Status: %s → no tool for '%s'", k, need))
                    end
                  end
                end
              end
            end
            task.wait(0.6)
          end
        end)
      end
    end
  })

  -- refresh pasif saat OFF
  task.spawn(function()
    while true do
      if not enabled then renderOnce() end
      task.wait(1.0)
    end
  end)
end



-- =============================
-- TAB: Garden (FULL)
-- =============================
do

  -- ===== util plot/tile =====
  local function findMyPlot()
    for _, p in ipairs(S.Plots:GetChildren()) do
      if p:GetAttribute("OwnerUserId")==LP.UserId or p:GetAttribute("Owner")==LP.Name then return p end
    end
  end
  local function tileIsFree(tile)
    if not tile then return false end
    if tile:GetAttribute("Occupied")==true then return false end
    if tile:FindFirstChild("Plant") or tile:FindFirstChild("Crop") then return false end
    return true
  end
  local function rowModel(plot, n)
    local rows = plot and plot:FindFirstChild("Rows")
    return rows and rows:FindFirstChild(tostring(n))
  end
  local function grassOfRow(plot, n)
    local r = rowModel(plot, n); return r and r:FindFirstChild("Grass")
  end
  local function resolveTileByIndexOrName(grass, idx, name)
    if not grass then return nil end
    if name then return grass:FindFirstChild(tostring(name)) end
    -- coba cocokan ke nama angka dulu, jika tidak ada, baru urutkan by Name
    local byName = grass:FindFirstChild(tostring(idx))
    if byName then return byName end
    local kids = grass:GetChildren()
    table.sort(kids, function(a,b) return a.Name < b.Name end)
    return kids[idx]
  end
  local function partCFrame(inst)
    if not inst then return CFrame.new() end
    if inst:IsA("BasePart") then return inst.CFrame end
    if inst:IsA("Model")   then return inst:GetPivot() end
    return CFrame.new()
  end

  

  -- ======== SECTION: Auto Plant Seed (pindahan dari Main) ========
  tabGarden:CreateSectionFold({ Title = "Auto Plant Seed" })
  tabGarden:Paragraph("Klik 'Refresh Seed' → pilih seed → (opsi) Only Free Tiles → toggle 'Auto Plant'.")

  local SeedsFolder = S.RS:WaitForChild("Assets"):WaitForChild("Seeds")
  local function getSeedSet()
    local set = {}
    for _,inst in ipairs(SeedsFolder:GetChildren()) do
      set[inst.Name:gsub("%s+Seed$","")] = true
    end
    return set
  end
  local SEED_WHITELIST = getSeedSet()

  local function scanBackpackSeeds()
    local bag = LP:WaitForChild("Backpack")
    local byType, seen = {}, {}
    for _,inst in ipairs(bag:GetDescendants()) do
      local id = inst.GetAttribute and inst:GetAttribute("ID")
      if id and not seen[id] then
        local itemName = (inst.GetAttribute and inst:GetAttribute("ItemName")) or inst.Name
        if itemName:find("Seed") then
          local plant = itemName:gsub("^%b[]%s*",""):gsub("%s*Seed%s*$","")
          if SEED_WHITELIST[plant] then
            byType[plant] = byType[plant] or { stacks = {} }
            table.insert(byType[plant].stacks, { id = id, inst = inst })
            seen[id] = true
          end
        end
      end
    end
    return byType
  end

  local function waitSeedInWorkspaceByID(id, plantName, timeout)
    local pf = workspace:FindFirstChild("Players")
    pf = pf and pf:FindFirstChild(LP.Name)
    if not pf then return false end
    local deadline = os.clock() + (timeout or 2)
    repeat
      for _,c in ipairs(pf:GetChildren()) do
        local ok,v = pcall(c.GetAttribute,c,"ID")
        if ok and v ~= nil and tostring(v) == tostring(id) then return true end
      end
      if plantName then
        for _,t in ipairs(pf:GetChildren()) do
          if t:IsA("Tool") and t.Name:find("Seed") and t.Name:find(plantName) then return true end
        end
      end
      task.wait(0.05)
    until os.clock() > deadline
    return false
  end

  local function equipSeedIntoWorkspace(stack)
    local id, inst = stack.id, stack.inst
    local plantName = (inst and ((inst.GetAttribute and inst:GetAttribute("ItemName")) or inst.Name) or "")
    plantName = plantName:gsub("^%b[]%s*",""):gsub("%s*Seed%s*$","")

    local char = LP.Character or LP.CharacterAdded:Wait()
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if hum and inst and inst.Parent then pcall(function() hum:EquipTool(inst) end) end

    pcall(function()
      if RM.EquipItem:IsA("RemoteEvent") then
        RM.EquipItem:FireServer({ ID=id, Instance=inst, ItemName=inst and inst.Name or nil })
      elseif RM.EquipItem:IsA("BindableEvent") then
        RM.EquipItem:Fire(inst or id)
      elseif RM.EquipItem:IsA("RemoteFunction") then
        RM.EquipItem:InvokeServer({ ID=id })
      end
    end)

    if waitSeedInWorkspaceByID(id, plantName, 2) then return true end

    local pf = workspace:FindFirstChild("Players")
    pf = pf and pf:FindFirstChild(LP.Name)
    if pf and inst and inst.Parent and not inst:IsDescendantOf(pf) then
      pcall(function() inst.Parent = pf end)
      if waitSeedInWorkspaceByID(id, plantName, 1) then return true end
    end
    return false
  end

  local function sendPlant(stack, tile, plantName)
    local payload = { ID = stack.id, CFrame = partCFrame(tile), Item = plantName, Floor = tile }
    pcall(function() RM.PlaceItem:FireServer(payload) end)
  end
  local function prepareAndSendPlant(stack, tile, plantName)
    equipSeedIntoWorkspace(stack); sendPlant(stack, tile, plantName)
  end

  local ownedSeeds, selectedSeeds, onlyFree, running = {}, {}, true, false
  local ddSeeds = tabGarden:Dropdown({
    Name="Select Seed", Options={"(Klik 'Refresh Seed')"}, MultiSelection=true, Search=true,
    Callback=function(values)
      if typeof(values)=="table" then selectedSeeds=values
      elseif typeof(values)=="string" then selectedSeeds={values}
      else selectedSeeds={} end
    end
  })
  local function refreshSeeds()
    ownedSeeds = scanBackpackSeeds()
    local names = {}; for k in pairs(ownedSeeds) do names[#names+1]=k end
    table.sort(names)
    F.updateDropdown(ddSeeds, names)
    notify("Seed List", ("%d jenis ditemukan"):format(#names), 1.2)
  end
  tabGarden:Button({ Name="Refresh Seed (sekali)", Callback=refreshSeeds })
  tabGarden:Toggle({ Name="Only Free Tiles", Default=true, Flag="only_free_tiles", Callback=function(v) onlyFree=v end })

  local function collectGrassTiles(plot)
    local out, rows = {}, plot and plot:FindFirstChild("Rows")
    if not rows then return out end
    for _,r in ipairs(rows:GetChildren()) do
      local g = r:FindFirstChild("Grass")
      if g then for _,t in ipairs(g:GetChildren()) do out[#out+1]=t end end
    end
    return out
  end
  local function getEmptyTiles(plot)
    local tiles = collectGrassTiles(plot)
    if onlyFree then
      local free={}
      for _,t in ipairs(tiles) do if tileIsFree(t) then free[#free+1]=t end end
      tiles = free
    end
    return tiles
  end

  local DELAY_BETWEEN = 0.10
  local startToggle
  local function runPlantAllMulti(seedList)
    local plot = findMyPlot()
    if not plot then notify("Error","Plot tidak ditemukan",1.6); F.setToggleState(startToggle,false); return 0 end
    local tiles = getEmptyTiles(plot)
    if #tiles == 0 then F.setToggleState(startToggle,false); return 0 end

    local rng=Random.new()
    for i=#tiles,2,-1 do local j=rng:NextInteger(1,i) tiles[i],tiles[j]=tiles[j],tiles[i] end

    ownedSeeds = scanBackpackSeeds()
    local order = {} for _,name in ipairs(seedList) do if ownedSeeds[name] then order[#order+1]=name end end
    if #order==0 then notify("Error","Semua pilihan tidak ada stok",1.6); F.setToggleState(startToggle,false); return 0 end

    local sIdx = {}; for _,n in ipairs(order) do sIdx[n]=1 end
    local planted,i,seedIdx = 0,1,1

    while running and i<=#tiles and #order>0 do
      local name = order[seedIdx]
      local bucket = ownedSeeds[name]
      if (not bucket) or (#bucket.stacks==0) then
        table.remove(order,seedIdx); if seedIdx>#order then seedIdx=1 end
      else
        local idx=sIdx[name]; if idx>#bucket.stacks then idx=1 end
        local stack=bucket.stacks[idx]; sIdx[name]=(idx%#bucket.stacks)+1
        local tile=tiles[i]; i=i+1
        prepareAndSendPlant(stack,tile,name)
        planted=planted+1
        seedIdx=seedIdx+1; if seedIdx>#order then seedIdx=1 end
        task.wait(DELAY_BETWEEN)
      end
    end
    return planted
  end

  startToggle = tabGarden:Toggle({
    Name="Auto Plant", Default=false,
    Flag="auto_plant_seed",
    Callback=function(state)
      if state then
        if running then return end
        if (not selectedSeeds) or (#selectedSeeds==0) or (#selectedSeeds==1 and selectedSeeds[1]=="(Klik 'Refresh Seed')") then
          notify("Info","Pilih seed dulu (multi)",1.4); F.setToggleState(startToggle,false); return
        end
        running=true
        task.spawn(function()
          local ok,err=pcall(function()
            local planted=runPlantAllMulti(selectedSeeds)
            if planted>0 then notify("Selesai",("Planted %d total"):format(planted),1.6) end
          end)
          if not ok then notify("Error",tostring(err),2.0) end
          running=false; F.setToggleState(startToggle,false)
        end)
      else
        running=false
      end
    end
  })

-- =============================
-- TAB: Garden (Pickup Only) — no 'goto'  (FIXED with SafeRemove)
-- =============================
do
  local RS, Plots = S.RS, S.Plots
  local SeedsFolder = RS:WaitForChild("Assets"):WaitForChild("Seeds")

  -- cari plot milik kita
  local function findMyPlot()
    for _, p in ipairs(Plots:GetChildren()) do
      if p:GetAttribute("OwnerUserId")==LP.UserId or p:GetAttribute("Owner")==LP.Name then
        return p
      end
    end
  end

  -- ===== deep attribute helpers =====
  local function deepAttr(inst, key)
    if inst and inst.GetAttribute then
      local ok, v = pcall(inst.GetAttribute, inst, key)
      if ok and v ~= nil then return v end
    end
    for _, d in ipairs(inst:GetDescendants()) do
      local ok, v = pcall(d.GetAttribute, d, key)
      if ok and v ~= nil then return v end
    end
    return nil
  end
  local function getPlantIDDeep(m)
    local v = deepAttr(m, "ID")
    return v and tostring(v) or nil
  end

  -- ===== whitelist nama plant (hindari ambil tulisan rarity/angka) =====
  local KNOWN_PLANTS = {}
  for _,inst in ipairs(SeedsFolder:GetChildren()) do
    local base = (inst.Name or ""):gsub("%s+Seed$","")
    if base ~= "" then KNOWN_PLANTS[base] = true end
  end
  local RARITY_WORDS = { rare=true, epic=true, mythic=true, legendary=true, limited=true, secret=true, godly=true }
  local function cleanLabel(s) return (tostring(s or "")):gsub("^%b[]%s*",""):gsub("%s*Seed$","") end
  local function candidateIsPlant(label)
    if not label or label=="" then return false end
    local l = label:lower()
    if l:match("^%d+$") or RARITY_WORDS[l] then return false end
    return KNOWN_PLANTS[label] == true
  end
  local function guessPlantName(node)
    for _,k in ipairs({"PlantName","ItemName","Species","Type","Item"}) do
      local v = node.GetAttribute and node:GetAttribute(k)
      if type(v)=="string" then v = cleanLabel(v); if candidateIsPlant(v) then return v end end
    end
    for _,d in ipairs(node:GetDescendants()) do
      if d:IsA("TextLabel") or d:IsA("TextBox") then
        local tag = ((d.Name or "").." "..(d.Parent and d.Parent.Name or "")):lower()
        if tag:find("plant") or tag:find("seed") or tag:find("name") then
          local v = cleanLabel(d.Text); if candidateIsPlant(v) then return v end
        end
      end
    end
    local nm = cleanLabel(node.Name)
    if candidateIsPlant(nm) then return nm end
    local low = nm:lower()
    for base,_ in pairs(KNOWN_PLANTS) do
      if low:find(base:lower(), 1, true) then return base end
    end
    return nil
  end

  -- ===== Shovel (kebanyakan server wajib di-equip saat remove) =====
  local function isShovel(tool)
    if not (tool and tool:IsA("Tool")) then return false end
    local n = (tool:GetAttribute("ItemName") or tool.Name):lower():gsub("^%b[]%s*","")
    return n:find("shovel", 1, true) ~= nil
  end
  local function findShovel()
    local ch = LP.Character
    if ch then for _,t in ipairs(ch:GetChildren()) do if isShovel(t) then return t end end end
    local bp = LP:FindFirstChild("Backpack")
    if bp then for _,t in ipairs(bp:GetChildren()) do if isShovel(t) then return t end end end
    local pf = F.myPlayerFolder()
    if pf then for _,t in ipairs(pf:GetChildren()) do if isShovel(t) then return t end end end
    return nil
  end
  local function ensureEquipped(tool)
    if not tool then return false end
    local ch = LP.Character or LP.CharacterAdded:Wait()
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if hum and tool.Parent ~= ch then pcall(function() hum:EquipTool(tool) end) end
    return tool.Parent == ch
  end
  local function ensureShovelEquipped()
    local sh = findShovel()
    if not sh then return false end
    return ensureEquipped(sh)
  end

  -- ===== SafeRemove (learn & cache best payload) =====
  local function waitBackpackToolByID(id, timeout)
    local bag = LP:WaitForChild("Backpack")
    local tEnd = os.clock() + (timeout or 2.0)
    repeat
      for _,t in ipairs(bag:GetChildren()) do
        if t:IsA("Tool") then
          local ok,v = pcall(t.GetAttribute, t, "ID")
          if ok and v and tostring(v) == tostring(id) then return true end
        end
      end
      task.wait(0.05)
    until os.clock() > tEnd
    return false
  end
  local function waitPlantGoneByID(id, timeout)
    local plot = findMyPlot()
    local plants = plot and plot:FindFirstChild("Plants")
    local tEnd = os.clock() + (timeout or 2.0)
    repeat
      local present = false
      if plants then
        for _,m in ipairs(plants:GetChildren()) do
          local ok,v = pcall(m.GetAttribute, m, "ID")
          if ok and v and tostring(v)==tostring(id) then present=true break end
        end
      end
      if not present then return true end
      task.wait(0.05)
    until os.clock() > tEnd
    return false
  end

  local _REMOVE_ENCODER_OK -- cache varian payload yang sukses

  local function fireRemove(payload)
    local r = RM.RemoveItem
    if not r then return false end
    if r:IsA("RemoteEvent") then
      return pcall(function() r:FireServer(payload) end)
    elseif r:IsA("RemoteFunction") then
      local ok, _ = pcall(function() return r:InvokeServer(payload) end)
      return ok
    else
      -- beberapa game punya BindableEvent fallback
      if r.Fire then local ok = pcall(function() r:Fire(payload) end); if ok then return true end end
      return false
    end
  end

  local function SafeRemoveByID(id, modelHint)
    if not id then return false, "no-id" end
    -- pastikan shovel sudah equip
    if not ensureShovelEquipped() then return false, "no-shovel" end

    local formats = {
      function() return tostring(id) end,                    -- "uuid"
      function() return {ID = tostring(id)} end,             -- {ID="uuid"}
      function() return {id = tostring(id)} end,             -- {id="uuid"}
      function() return { tostring(id) } end,                -- {"uuid"}
    }

    -- coba varian yang pernah sukses lebih dulu
    if _REMOVE_ENCODER_OK then
      fireRemove(formats[_REMOVE_ENCODER_OK]()); task.wait(0.05)
      if waitBackpackToolByID(id, 0.35) or waitPlantGoneByID(id, 0.35) then return true end
    end

    -- brute force semua varian
    for i=1,#formats do
      fireRemove(formats[i]()); task.wait(0.06)
      if waitBackpackToolByID(id, 0.45) or waitPlantGoneByID(id, 0.45) then _REMOVE_ENCODER_OK = i; return true end
    end

    -- fallback terakhir: sebagian server minta 2 argumen (uncommon)
    local r = RM.RemoveItem
    if r and r:IsA("RemoteEvent") then
      local ok = pcall(function() r:FireServer(tostring(id), true) end)
      if ok and (waitBackpackToolByID(id, 0.45) or waitPlantGoneByID(id, 0.45)) then _REMOVE_ENCODER_OK = -1; return true end
    end

    -- masih gagal
    return false, "remote-failed"
  end

  -- ================= UI =================
  tabGarden:CreateSectionFold({ Title = "Pickup Plants (Plot)" })
  tabGarden:Paragraph("Klik Refresh Types → pilih jenis plant → Toggle Auto Pickup.")

  local ddTypes, selectedSet = nil, {}
  ddTypes = tabGarden:Dropdown({
    Name = "Plant Types in Plot",
    Options = {},
    MultiSelection = true, Search = true,
    Callback = function(values)
      local set = {}
      if typeof(values)=="table" then
        for _,v in ipairs(values) do set[tostring(v)] = true end
      elseif typeof(values)=="string" and values~="" then
        set[values] = true
      end
      selectedSet = set
    end
  })

  local function refreshTypes()
    local plot = findMyPlot()
    if not plot then notify("Garden","Plot tidak ditemukan",1.2); return end
    local plantsFolder = plot:FindFirstChild("Plants") or plot:FindFirstChild("Plants")
    if not plantsFolder then notify("Garden","Folder Plants kosong",1.1); return end

    local uniq = {}
    for _,m in ipairs(plantsFolder:GetChildren()) do
      if m:IsA("Model") then
        local name = guessPlantName(m)
        if name then uniq[name] = true end
      end
    end
    local list = {}
    for name in pairs(uniq) do list[#list+1] = name end
    table.sort(list)
    if #list==0 then list = {"(No plants found)"} end
    F.updateDropdown(ddTypes, list)
    notify("Garden", ("Types: %d ditemukan"):format((list[1] == "(No plants found)" and 0) or #list), 1.0)
  end

  tabGarden:Button({ Name = "Refresh Types (scan plot)", Callback = refreshTypes })

  -- delay input (opsional)
  local delay = 0.15
  tabGarden:Input({
    Name = "Pickup delay (detik)",
    PlaceholderText = tostring(delay),
    NumbersOnly = true,
    Flag = "pickup_delay",
    Callback = function(txt)
      local v = tonumber(txt)
      if v and v >= 0 then delay = v; notify("Pickup", ("Delay set: %.2fs"):format(delay), 1.0) end
    end
  })

  -- loop tanpa 'goto'
  local autoPickup = false
  tabGarden:Toggle({
    Name = "Auto Pickup (Selected)",
    Default = false,
    Flag = "auto_pickup_plants",
    Callback = function(on)
      autoPickup = on
      if on then
        refreshTypes()
        task.spawn(function()
          while autoPickup do
            local plot = findMyPlot()
            if plot then
              local plantsFolder = plot:FindFirstChild("Plants")
              if plantsFolder then
                local matchAll = (next(selectedSet) == nil)

                -- pastikan shovel equip SEKALI di awal pass
                ensureShovelEquipped()

                for _,m in ipairs(plantsFolder:GetChildren()) do
                  if not autoPickup then break end
                  if m:IsA("Model") then
                    local name = guessPlantName(m)
                    if name and (matchAll or selectedSet[name]) then
                      local id = getPlantIDDeep(m)
                      if id then
                        local ok = SafeRemoveByID and SafeRemoveByID(id, m) or false
                        if not ok then
                          -- fallback kalau _G belum terdefinisi
                          ok = select(1, SafeRemoveByID(id, m))
                        end
                        task.wait(delay)
                      end
                    end
                  end
                end
              end
            end
            task.wait(0.20)
          end
        end)
      end
    end
  })
end





-- ======== SECTION: Merapihkan plant (Auto 35) — PICK FIRST, SNAPSHOT BACKPACK (plots 1–6) ========
tabGarden:CreateSectionFold({ Title = "Merapihkan plant" })
tabGarden:Paragraph("cuma ngerapihin plant doang njir gak ada yang lain, sama ngurutin plant dameg tertinggi dari kanan ke kiri")

-- Layout per-plot (pakai GetChildren()[idx] atau nama "1"/"2"/"3")
local BEST_LAYOUTS = {
  [1] = {
    {row=7, idx=8},{row=5, idx=9},{row=2, idx=9},{row=1, idx=9},{row=3, idx=6},
    {row=4, name="1"},{row=6, idx=4},{row=7, idx=9},{row=5, idx=8},{row=2, idx=8},

    {row=1, idx=8},{row=3, idx=8},{row=4, idx=7},{row=6, name="1"},{row=7, idx=4},
    {row=5, idx=5},{row=2, idx=6},{row=1, idx=6},{row=3, idx=5},{row=4, idx=4},

    {row=6, idx=6},{row=7, idx=7},{row=5, idx=6},{row=2, idx=7},{row=1, idx=7},
    {row=3, idx=7},{row=4, name="3"},{row=6, idx=9},{row=7, idx=6},{row=5, idx=7},

    {row=2, idx=2},{row=1, idx=5},{row=3, idx=4},{row=4, idx=8},{row=6, idx=5},
  },
  [2] = {
    {row=7, idx=6},{row=5, idx=4},{row=2, idx=5},{row=1, idx=5},{row=3, name="2"},{row=4, idx=9},{row=6, idx=6},

    {row=7, name="1"},{row=5, idx=5},{row=2, idx=7},{row=1, idx=7},{row=3, idx=2},{row=4, name="3"},{row=6, idx=7},

    {row=7, idx=7},{row=5, idx=3},{row=2, idx=3},{row=1, name="1"},{row=3, idx=5},{row=4, idx=6},{row=6, name="2"},

    {row=7, idx=3},{row=5, name="3"},{row=2, name="1"},{row=1, name="3"},{row=3, idx=3},{row=4, idx=8},{row=6, name="1"},

    {row=7, idx=4},{row=5, name="1"},{row=2, idx=9},{row=1, idx=4},{row=3, idx=7},{row=4, idx=2},{row=6, idx=5},
  },
  [3] = {
    {row=7, idx=8},{row=5, idx=6},{row=2, idx=9},{row=1, idx=7},{row=3, idx=5},{row=4, idx=9},{row=6, idx=7},

    {row=7, idx=3},{row=5, idx=3},{row=2, idx=4},{row=1, name="3"},{row=3, name="1"},{row=4, idx=7},{row=6, idx=5},

    {row=7, idx=7},{row=5, idx=8},{row=2, idx=6},{row=1, name="1"},{row=3, idx=4},{row=4, idx=6},{row=6, idx=2},

    {row=7, idx=6},{row=5, idx=9},{row=2, idx=5},{row=1, idx=8},{row=3, idx=8},{row=4, idx=8},{row=6, name="1"},

    {row=7, name="2"},{row=5, idx=7},{row=2, idx=7},{row=1, idx=2},{row=3, name="2"},{row=4, idx=3},{row=6, idx=6},
  },
  [4] = {
    {row=7, idx=3},{row=5, idx=7},{row=2, idx=5},{row=1, name="1"},{row=3, idx=7},{row=4, idx=4},{row=6, idx=4},

    {row=7, idx=4},{row=5, name="3"},{row=2, idx=3},{row=1, idx=8},{row=3, name="1"},{row=4, idx=8},{row=6, idx=9},

    {row=7, idx=6},{row=5, idx=5},{row=2, idx=9},{row=1, idx=5},{row=3, idx=4},{row=4, idx=9},{row=6, idx=7},

    {row=7, name="1"},{row=5, idx=4},{row=2, idx=6},{row=1, name="3"},{row=3, idx=5},{row=4, idx=7},{row=6, idx=6},

    {row=7, idx=9},{row=5, idx=9},{row=2, idx=7},{row=1, idx=4},{row=3, idx=6},{row=4, name="1"},{row=6, idx=5},
  },
  [5] = {
    {row=7, idx=5},{row=5, idx=3},{row=2, idx=5},{row=1, idx=6},{row=3, idx=5},{row=4, name="1"},{row=6, idx=7},

    {row=7, idx=8},{row=5, idx=7},{row=2, idx=9},{row=1, idx=4},{row=3, idx=9},{row=4, idx=8},{row=6, idx=5},

    {row=7, idx=3},{row=5, idx=8},{row=2, idx=8},{row=1, idx=3},{row=3, name="2"},{row=4, idx=2},{row=6, idx=8},

    {row=7, name="1"},{row=5, idx=4},{row=2, name="1"},{row=1, name="3"},{row=3, idx=8},{row=4, idx=4},{row=6, idx=9},

    {row=7, idx=4},{row=5, idx=6},{row=2, name="2"},{row=1, name="1"},{row=3, idx=6},{row=4, idx=7},{row=6, idx=3},
  },
  [6] = {
    {row=7, idx=5},{row=5, idx=4},{row=2, idx=4},{row=1, idx=8},{row=3, idx=3},{row=4, idx=2},{row=6, idx=8},

    {row=7, idx=9},{row=5, idx=9},{row=2, name="1"},{row=1, name="3"},{row=3, idx=9},{row=4, idx=8},{row=6, idx=7},

    {row=7, idx=4},{row=5, idx=8},{row=2, idx=9},{row=1, idx=5},{row=3, idx=8},{row=4, name="1"},{row=6, idx=6},

    {row=7, idx=8},{row=5, name="3"},{row=2, idx=8},{row=1, idx=3},{row=3, name="1"},{row=4, idx=5},{row=6, idx=5},

    {row=7, idx=6},{row=5, idx=5},{row=2, idx=5},{row=1, idx=4},{row=3, name="2"},{row=4, idx=4},{row=6, idx=2},
  },
}

-- === helpers khusus fitur ini ===
local function deepAttr(inst,key)
  if inst and inst.GetAttribute then
    local ok,v=pcall(inst.GetAttribute,inst,key)
    if ok and v~=nil then return v end
  end
  for _,d in ipairs(inst:GetDescendants()) do
    local ok,v=pcall(d.GetAttribute,d,key); if ok and v~=nil then return v end
  end
  return nil
end
local function safeID(inst) local v=deepAttr(inst,"ID"); return v and tostring(v) or nil end
local function plantDamageFromAny(inst)
  for _,k in ipairs({"Damage","DPS","Power"}) do
    local v=deepAttr(inst,k); if type(v)=="number" then return v end
  end
  return 0
end
local function isLikelySeedTool(t)
  local n=(t:GetAttribute("ItemName") or t.Name):lower():gsub("^%[%s*%d+x%s*%]%s*","")
  return n:find("seed",1,true) ~= nil
end
local function isPlantTool(t)
  if not (t and t:IsA("Tool")) then return false end
  if isLikelySeedTool(t) then return false end
  local cat=deepAttr(t,"Category"); if type(cat)=="string" and cat:lower()=="plant" then return true end
  if deepAttr(t,"Plant")==true then return true end
  if deepAttr(t,"Gear")==true then return false end
  if deepAttr(t,"Brainrot")==true then return false end
  return true
end

local function grassOfRow(plot, n)
  local rows=plot and plot:FindFirstChild("Rows")
  local rowM=rows and rows:FindFirstChild(tostring(n))
  return rowM and rowM:FindFirstChild("Grass")
end
local function resolveTile(grass, slot)
  if not grass then return nil end
  if slot.name then return grass:FindFirstChild(tostring(slot.name)) end
  local kids=grass:GetChildren() -- TIDAK di-sort: pakai urutan GetChildren() asli
  return kids and kids[slot.idx] or nil
end
local function tileIsFree(tile)
  if not tile then return false end
  if tile:GetAttribute("Occupied")==true then return false end
  if tile:FindFirstChild("Plant") or tile:FindFirstChild("Crop") then return false end
  return true
end

local function ensureEquipped(tool)
  if not tool then return false end
  local char=LP.Character or LP.CharacterAdded:Wait()
  if tool.Parent~=char then
    local hum=char:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum:EquipTool(tool) end) end
  end
  return tool.Parent==char
end
local function placePlantToolOnTile(tool,tile)
  if not (tool and tile) then return false end
  ensureEquipped(tool)
  local id=safeID(tool)
  local name=(tool:GetAttribute("ItemName") or tool.Name):gsub("^%[%s*%d+x%s*%]%s*","")
  if not id or not name then return false end
  pcall(function() RM.PlaceItem:FireServer({ID=id, CFrame=F.partCFrame(tile), Item=name, Floor=tile}) end)
  return true
end

-- tunggu tool hasil pickup masuk backpack (lebih stabil)
local function waitBackpackToolByID(id, timeout)
  local bag = LP:WaitForChild("Backpack")
  local deadline = os.clock() + (timeout or 4)
  repeat
    for _,t in ipairs(bag:GetChildren()) do
      if t:IsA("Tool") then
        local ok,v = pcall(t.GetAttribute, t, "ID")
        if ok and v and tostring(v) == tostring(id) then return t end
      end
    end
    task.wait(0.1)
  until os.clock() > deadline
  return nil
end

-- snapshot Backpack/Character/Players-folder → daftar kandidat + map id->tool
local function snapshotBackpack()
  local id2tool, candidates = {}, {}
  for _,container in ipairs({LP.Character, LP:FindFirstChild("Backpack"), F.myPlayerFolder()}) do
    if container then
      for _,t in ipairs(container:GetChildren()) do
        if t:IsA("Tool") and isPlantTool(t) then
          local id=safeID(t)
          if id and not id2tool[id] then
            id2tool[id]=t
            table.insert(candidates, { id=id, dmg=plantDamageFromAny(t) })
          end
        end
      end
    end
  end
  return candidates, id2tool
end

local function findMyPlot()
  for _, p in ipairs(S.Plots:GetChildren()) do
    if p:GetAttribute("OwnerUserId")==LP.UserId or p:GetAttribute("Owner")==LP.Name then
      return p
    end
  end
end

-- pickup semua plant: kirim STRING UUID langsung
local function pickUpAllFromPlot(plot)
  local plantsFolder=plot and plot:FindFirstChild("Plants")
  if not plantsFolder then return 0 end
  local picked=0
  for _,m in ipairs(plantsFolder:GetChildren()) do
    local id=safeID(m)
    if id then
      pcall(function()
        RM.RemoveItem:FireServer(tostring(id)) -- <<— string UUID saja
      end)
      picked+=1
      waitBackpackToolByID(id, 2.5) -- tunggu masuk backpack biar rapi
      task.wait(0.06)
    end
  end
  return picked
end

local function runTop35_PickThenSnapshot()
  local plot=findMyPlot()
  if not plot then notify("Garden","Plot tidak ditemukan",1.3); return end

  -- AUTO: pilih layout sesuai nomor plot (fallback ke [1] kalau tidak ketemu)
  local myPlotIndex = tonumber(plot.Name) or 1
  local LAYOUT = BEST_LAYOUTS[myPlotIndex] or BEST_LAYOUTS[1]

  -- 1) PICKUP DULU semua plant di plot
  local picked = pickUpAllFromPlot(plot)
  if picked>0 then task.wait(0.25) end  -- beri waktu tool masuk ke Backpack

  -- 2) SNAPSHOT Backpack (termasuk sisa lama + hasil pickup)
  local candidates, id2tool = snapshotBackpack()
  if #candidates==0 then
    notify("Garden","Tidak ada kandidat plant di Backpack.",1.2)
    return
  end

  -- 3) Sort by damage desc
  table.sort(candidates, function(a,b) return (a.dmg or 0) > (b.dmg or 0) end)

  -- 4) Tanam top 35 mengikuti layout plot aktif
  local placed, limit = 0, math.min(35, #LAYOUT)
  local slotIdx, candIdx = 1, 1

  while placed < limit and slotIdx <= #LAYOUT and candIdx <= #candidates do
    local slot = LAYOUT[slotIdx]
    local grass = grassOfRow(plot, slot.row)
    local tile  = resolveTile(grass, slot)

    if tile and tileIsFree(tile) then
      -- cari kandidat berikut yang tool-nya ada
      local tool=nil; local chosen=nil; local i=candIdx
      while i <= #candidates and (not tool) do
        local c = candidates[i]
        tool = id2tool[c.id]
        if tool then chosen=c; candIdx=i+1 else i=i+1 end
      end
      if tool and chosen then
        placePlantToolOnTile(tool, tile)
        id2tool[chosen.id]=nil -- jangan dipakai lagi
        placed = placed + 1
        task.wait(1)
      else
        break -- habis tool valid
      end
    end

    slotIdx = slotIdx + 1 -- lanjut slot berikutnya (slot tetap maju)
  end

  notify("Garden", ("Plant Terbaik selesai: %d ditanam. (Plot %d)"):format(placed, myPlotIndex), 1.6)
end

tabGarden:Button({
  Name = "Plant Terbaik (Auto 35)",
  Callback = function()
    local ok,err=pcall(runTop35_PickThenSnapshot)
    if not ok then warn("[Top35-PickThenSnapshot]",err) end
  end
})
end


 -- ========== TAB SHOP: Auto Buy Seed/Gear, Auto Sell ==========
do
  local AUTO_BUY_INTERVAL = 0.10

  -- Seeds
  local SeedsFolder = S.RS:WaitForChild("Assets"):WaitForChild("Seeds")
  tabShop:CreateSectionFold({ Title = "Auto Buy Seed" })
  local function getAllSeedNamesFull()
    local list={}
    for _,inst in ipairs(SeedsFolder:GetChildren()) do list[#list+1]=inst.Name end
    table.sort(list); return list
  end
  local function buySeedOnce(name) pcall(function() RM.BuyItem:FireServer(name) end) end
  local shopSeedList, autoBuyingSeed = {}, false
  tabShop:Dropdown({ Name="Select Seed", Options=getAllSeedNamesFull(), MultiSelection=true, Search=true, Flag="shop_seed",
    Callback=function(v) if typeof(v)=="table" then shopSeedList=v elseif typeof(v)=="string" then shopSeedList={v} else shopSeedList={} end end })
  tabShop:Toggle({ Name="Auto Buy Seed", Flag="auto_buy_seed", Default=false, Callback=function(state)
    autoBuyingSeed=state
    if not state then return end
    task.spawn(function()
      local idx=1
      while autoBuyingSeed do
        if not shopSeedList or #shopSeedList==0 then task.wait(1)
        else
          if idx>#shopSeedList then idx=1 end
          buySeedOnce(shopSeedList[idx]); idx=idx+1; task.wait(AUTO_BUY_INTERVAL)
        end
      end
    end)
  end })

  -- Auto Buy ALL Seeds
local autoBuyAllSeeds = false
tabShop:Toggle({
  Name = "Auto Buy ALL Seeds",
  Default = false,
  Flag="auto_buy_all_seeds",
  Callback = function(state)
    autoBuyAllSeeds = state
    if autoBuyAllSeeds then
      -- hindari bentrok dengan loop per-pilihan
      autoBuyingSeed = false
      task.spawn(function()
        local seedListAll = getAllSeedNamesFull()
        local idx = 1
        while autoBuyAllSeeds do
          -- refresh list bila kosong atau index melewati batas
          if #seedListAll == 0 or idx > #seedListAll then
            seedListAll = getAllSeedNamesFull()
            idx = 1
          end

          if #seedListAll > 0 then
            pcall(function() RM.BuyItem:FireServer(seedListAll[idx]) end)
            idx += 1
            task.wait(AUTO_BUY_INTERVAL)
          else
            -- tidak ada item: recheck berkala
            task.wait(0.5)
          end
        end
      end)
    end
  end
})

  -- Gear
  tabShop:CreateSectionFold({ Title = "Auto Buy Gear" })
  local function getAllGearNames()
    local list = {}
    local ok, gearStocks = pcall(function() return require(S.RS.Modules.Library.GearStocks) end)
    if ok and type(gearStocks)=="table" then
      for gearName in pairs(gearStocks) do if type(gearName)=="string" then list[#list+1]=gearName end end
    end
    if #list==0 then list={"Water Bucket","Frost Blower","Frost Grenade","Carrot Launcher","Banana Gun"} end
    table.sort(list); return list
  end
  local function buyGearOnce(gear) pcall(function() RM.BuyGear:FireServer(gear) end) end
  local shopGearList, autoBuyingGear = {}, false
  tabShop:Dropdown({ Name="Select Gear", Options=getAllGearNames(), MultiSelection=true, Search=true, Flag="shop_gear",
    Callback=function(v) if typeof(v)=="table" then shopGearList=v elseif typeof(v)=="string" then shopGearList={v} else shopGearList={} end end })
  tabShop:Toggle({ Name="Auto Buy Gear", Default=false, Flag="auto_buy_gear", Callback=function(state)
    autoBuyingGear=state
    if not autoBuyingGear then return end
    task.spawn(function()
      local idx=1
      while autoBuyingGear do
        if not shopGearList or #shopGearList==0 then task.wait(1)
        else
          if idx>#shopGearList then idx=1 end
          buyGearOnce(shopGearList[idx]); idx=idx+1; task.wait(AUTO_BUY_INTERVAL)
        end
      end
    end)
  end })

-- Auto Buy ALL Gear
local autoBuyAllGear = false
tabShop:Toggle({
  Name = "Auto Buy ALL Gear",
  Default = false,
  Callback = function(state)
    autoBuyAllGear = state
    if autoBuyAllGear then
      -- hindari bentrok dengan loop per-pilihan
      autoBuyingGear = false
      task.spawn(function()
        local gearListAll = getAllGearNames()
        local idx = 1
        while autoBuyAllGear do
          -- refresh list bila kosong atau index melewati batas
          if #gearListAll == 0 or idx > #gearListAll then
            gearListAll = getAllGearNames()
            idx = 1
          end

          if #gearListAll > 0 then
            pcall(function() RM.BuyGear:FireServer(gearListAll[idx]) end)
            idx += 1
            task.wait(AUTO_BUY_INTERVAL)
          else
            -- tidak ada item: recheck berkala
            task.wait(0.5)
          end
        end
      end)
    end
  end
})

  -- Sell
  tabShop:CreateSectionFold({ Title = "Auto Sell" })
  local sellInterval, autoSellBrainrots, autoSellPlants = 1.0, false, false
  tabShop:Input({ Name="Sell Interval (detik)", PlaceholderText=tostring(sellInterval), NumbersOnly=true, Flag="sell_interval",
    Callback=function(txt) local v=tonumber(txt); if v and v>=0.1 then sellInterval=v; notify("OK",("Sell interval diatur ke %.1fs"):format(sellInterval),1.2) else notify("Info","Minimal 0.1 detik",1.2) end end })
  tabShop:Toggle({ Name="Auto Sell Brainrots", Default=false, Flag="auto_sell_brainrots", Callback=function(state)
    autoSellBrainrots=state; if not state then return end
    task.spawn(function() while autoSellBrainrots do pcall(function() RM.ItemSell:FireServer() end) task.wait(sellInterval) end end)
  end })
  tabShop:Toggle({ Name="Auto Sell Plants", Default=false, Flag="auto_sell_plants", Callback=function(state)
    autoSellPlants=state; if not state then return end
    task.spawn(function() while autoSellPlants do pcall(function() RM.ItemSell:FireServer(nil,true) end) task.wait(sellInterval) end end)
  end })
end

-- ========== TAB UTILITY: Auto Equip Best + Auto Water ==========
do
  tabUtil:CreateSectionFold({ Title = "Auto Equip Best Brainrots" })
  local autoEquipBR, brInterval = false, 5
  tabUtil:Input({ Name="Timer", PlaceholderText=tostring(brInterval), NumbersOnly=true, Flag="auto_equip_br_timer",
    Callback=function(txt) local v=tonumber(txt); if v and v>=0.5 then brInterval=v; notify("OK",("Interval set ke %.2fs"):format(v),1.0) else notify("Info","Minimal 0.5s",1.1) end end })
  tabUtil:Toggle({ Name="Auto Equip Best Brainrots", Default=false, Flag="auto_equip_br", Callback=function(state)
    autoEquipBR=state; if not state then return end
    task.spawn(function() while autoEquipBR do pcall(function() RM.EquipBest:FireServer() end) task.wait(brInterval) end end)
  end })

  tabUtil:CreateSectionFold({ Title = "Auto Water" })
  local Countdowns = S.Scripted:WaitForChild("Countdowns")
  local waterDelay, waterPulse, autoWater = 0.15, 0.20, false
  tabUtil:Input({ Name="Jeda Siram (s)", PlaceholderText=tostring(waterDelay), NumbersOnly=true, Flag="auto_water_delay",
    Callback=function(txt) local v=tonumber(txt); if v and v>=0 then waterDelay=v; notify("Water",("Delay set: %.2fs"):format(v),1.0) else notify("Water","Masukkan angka ≥ 0",1.0) end end })
  local function isWaterBucket(t) if not (t and t:IsA("Tool")) then return false end local n=(t:GetAttribute("ItemName") or t.Name):lower():gsub("^%b[]%s*",""); return n:find("water") and n:find("bucket") end
  local function getWaterBucket()
    local char=LP.Character; if char then for _,t in ipairs(char:GetChildren()) do if isWaterBucket(t) then return t end end end
    local bp=LP:FindFirstChild("Backpack"); if bp then for _,t in ipairs(bp:GetChildren()) do if isWaterBucket(t) then return t end end end
    local pf=F.myPlayerFolder(); if pf then for _,t in ipairs(pf:GetChildren()) do if isWaterBucket(t) then return t end end end
    return nil
  end
  local function ensureEquipped(tool) if not tool then return false end local char=LP.Character or LP.CharacterAdded:Wait(); if tool.Parent~=char then local hum=char:FindFirstChildOfClass("Humanoid"); if hum then pcall(function() hum:EquipTool(tool) end) end end return tool.Parent==char end
  local function waterAt(pos)
    local tool=getWaterBucket(); if not tool then return false end
    ensureEquipped(tool)
    local payload={ Toggle=true, Tool=tool, Pos=Vector3.new(pos.X,pos.Y,pos.Z), Time=waterPulse }
    local ok = pcall(function() RM.UseItem:FireServer(payload) end)
    if not ok then pcall(function() RM.UseItem:FireServer({ Toggle=true, Tool=tool, Pos=payload.Pos }) end) end
    return true
  end
  local justWatered = {}
  local function rid(inst) return inst and tostring(inst:GetDebugId()) or "nil" end
  local function runAutoWater()
    while autoWater do
      local children = Countdowns:GetChildren()
      if #children>0 then
        local tool=getWaterBucket(); if tool then ensureEquipped(tool) end
        for _, inst in ipairs(children) do
          local r = rid(inst); local now=time()
          if (justWatered[r] or 0) <= now then
            local pos = F.worldPosOf(inst)
            if pos then waterAt(pos); justWatered[r]=now+math.max(0.75,waterDelay); task.wait(waterDelay) end
          end
        end
      end
      task.wait(0.10)
    end
  end
  tabUtil:Toggle({ Name="Auto Water", Default=false, Flag="auto_water", Callback=function(state)
    autoWater=state; if state then task.spawn(function() local ok,err=pcall(runAutoWater); if not ok then warn("[AutoWater]",err) end end) end
  end })
end



-- ========== TAB BACKPACK: Gifting + Spy Kills → Auto-Fav ==========
do
  local SeedsFolder = S.RS:WaitForChild("Assets"):WaitForChild("Seeds")
  local SEED_SET = (function()
    local s={}
    for _,inst in ipairs(SeedsFolder:GetChildren()) do
      s[inst.Name:gsub("%s+Seed$","")] = true
    end
    return s
  end)()
  local function isSeedName(name)
    if name:match("Seed%s*$") then return true end
    if SEED_SET[name:gsub("%s+Seed$","")] then return true end
    return false
  end

  local function collectGiftables()
    local out={}
    local function push(inst)
      if not inst:IsA("Tool") then return end
      local name=F.safeName(inst)
      if isSeedName(name) then return end
      out[name]=out[name] or {tools={}}
      table.insert(out[name].tools,inst)
    end
    local bp=LP:FindFirstChild("Backpack"); if bp then for _,t in ipairs(bp:GetChildren()) do push(t) end end
    local char=LP.Character; if char then for _,t in ipairs(char:GetChildren()) do push(t) end end
    local pf=F.myPlayerFolder(); if pf then for _,t in ipairs(pf:GetChildren()) do push(t) end end
    return out
  end
  local function giftTool(tool,targetUsername)
    return pcall(function() RM.GiftItem:FireServer({ Item=tool, ToGift=targetUsername }) end)
  end

  tabPack:CreateSectionFold({ Title = "Gifting" })
  local function buildGiftItemOptions()
    local inv = collectGiftables()
    local list = {}
    for name in pairs(inv) do table.insert(list, name) end
    table.sort(list)
    return list
  end

  local selectedGiftNames = {}
  local ddGift = tabPack:Dropdown({
    Name = "Select Items to Gift",
    Options = buildGiftItemOptions(),
    MultiSelection = true, 
    Search = true,
    Flag = "gift_item",
    Callback = function(values)
      if typeof(values) == "table" then
        selectedGiftNames = values
      elseif typeof(values) == "string" then
        selectedGiftNames = { values }
      else
        selectedGiftNames = {}
      end
    end
  })

  local playerLabelMap, giftTargetUsername = {}, ""
  local function buildPlayerOptions()
    local opts, map = {}, {}
    for _, p in ipairs(S.Players:GetPlayers()) do
      if p ~= LP then
        local uname = p.Name
        local dname = p.DisplayName or uname
        local label = string.format("%s = @%s", dname, uname)
        table.insert(opts, label)
        map[label] = uname
      end
    end
    table.sort(opts)
    return opts, map
  end

  do
    local opts, map = buildPlayerOptions(); playerLabelMap = map
    tabPack:Dropdown({
      Name = "Players Online (Recipient)",
      Options = opts, 
      MultiSelection = false, 
      Search = true,
      Flag = "gift_recipient",
      Callback = function(label)
        if type(label) == "string" and #label > 0 then
          local uname = playerLabelMap[label]
          if uname and #uname > 0 then
            giftTargetUsername = uname
            notify("Recipient", "Set to: "..label, 1.0)
          end
        end
      end
    })
  end

  tabPack:Button({
    Name = "Refresh Players",
    Callback = function()
      local opts, map = buildPlayerOptions()
      playerLabelMap = map
      notify("Players", "Daftar player di-refresh", 1.0)
    end
  })
  tabPack:Button({
    Name = "Refresh Giftables",
    Callback = function()
      F.updateDropdown(ddGift, buildGiftItemOptions())
      notify("Gift", "Daftar giftables di-refresh", 1.0)
    end
  })

  local giftDelay = 0.20
  tabPack:Input({
    Name = "Jeda Gift (detik)",
    PlaceholderText = tostring(giftDelay),
    NumbersOnly = true,
    Flag = "gift_delay",
    Callback = function(txt)
      local v = tonumber(txt)
      if v and v >= 0.05 then
        giftDelay = v
        notify("Gift", ("Delay set: %.2fs"):format(giftDelay), 1.0)
      else
        notify("Gift", "Minimal 0.05 detik", 1.0)
      end
    end
  })

  local autoGift = false
  local function autoGiftLoop()
    while autoGift do
      if giftTargetUsername == "" then
        notify("Gift", "Pilih recipient dulu.", 1.0)
        task.wait(1.0)
      elseif not selectedGiftNames or #selectedGiftNames == 0 then
        notify("Gift", "Pilih item yang ingin di-gift.", 1.0)
        task.wait(1.0)
      else
        local inv = collectGiftables()
        for _, name in ipairs(selectedGiftNames) do
          if not autoGift then break end
          local bucket = inv[name]
          if bucket and #bucket.tools > 0 then
            local tool = bucket.tools[1]
            local char = LP.Character or LP.CharacterAdded:Wait()
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if hum and tool then pcall(function() hum:EquipTool(tool) end) end
            giftTool(tool, giftTargetUsername)
            task.wait(giftDelay)
          end
        end
      end
      task.wait(0.05)
    end
  end

  tabPack:Toggle({
    Name = "Auto Gift (loop)",
    Default = false,
    Flag = "auto_gift_loop",
    Callback = function(state)
      autoGift = state
      if autoGift then
        task.spawn(function()
          local ok, err = pcall(autoGiftLoop)
          if not ok then warn("[Gift] loop error:", err) end
        end)
      end
    end
  })

  tabPack:Paragraph("Auto Accept Gift")
  local autoAcceptGift = false
  tabPack:Toggle({
    Name = "Auto Accept Gift",
    Default = autoAcceptGift,
    Flag = "auto_accept_gift",
    Callback = function(state) autoAcceptGift = state end
  })
  if RM.GiftItem then
    RM.GiftItem.OnClientEvent:Connect(function(payload)
      if not autoAcceptGift then return end
      if type(payload) ~= "table" or not payload.ID then return end
      pcall(function() RM.AcceptGift:FireServer({ ID = payload.ID }) end)
      pcall(function()
        local main = LP.PlayerGui:FindFirstChild("Main")
        if main and RM.OpenUI then RM.OpenUI:Fire(main:FindFirstChild("Gifting"), false) end
      end)
    end)
  end
end

  -- ========== TAB BACKPACK: Spy Kills → Auto-Fav (rarity + size threshold 0=off) ==========
do
  tabPack:CreateSectionFold({ Title = "Kills → Auto-Fav" })
  tabPack:Paragraph("auto fav brainrot yang di kalahkan tidak fav yang sudah ada di backpack \n note: masukan angka size ya bukan kg saran 5 termasuk huge paling 100kg")
  -- ===== UI & state =====
  local autoSpy = false
  local statusLbl = tabPack:Label("Status: OFF")

  local RARITY_OPTS = { "Rare","Epic","Legendary","Mythic","Godly","Secret","Limited" }
  local chosenRarity = {}
  for _, r in ipairs(RARITY_OPTS) do chosenRarity[F.norm(r)] = true end

  tabPack:Dropdown({
    Name = "Rarity Filter (Multi)",
    Options = RARITY_OPTS,
    MultiSelection = true,
    Flag = "spy_kill_rarity",
    Search = false,
    Callback = function(values)
      chosenRarity = {}
      if typeof(values) == "table" then
        for _, v in ipairs(values) do chosenRarity[F.norm(v)] = true end
      elseif typeof(values) == "string" then
        chosenRarity[F.norm(values)] = true
      end
    end
  })

  -- Size threshold: fav HANYA jika size > threshold; 0 = filter nonaktif
  local sizeThreshold = 0
  tabPack:Input({
    Name = "Size fav",
    PlaceholderText = "Input number",
    NumbersOnly = true,
    Flag = "spy_kill_size_threshold",
    Callback = function(txt)
      local v = tonumber(txt)
      if v and v >= 0 then
        sizeThreshold = v
        if v == 0 then
          notify("Spy", "Size filter NONAKTIF (0).", 1.0)
        else
          notify("Spy", "Threshold size = "..v.." (fav jika >)", 1.0)
        end
      end
    end
  })

  tabPack:Toggle({
    Name = "auto fav",
    Default = false,
    Flag = "spy_kill_auto_fav",
    Callback = function(state)
      autoSpy = state
      if statusLbl and statusLbl.Set then statusLbl:Set("Status: "..(state and "ON" or "OFF")) end
      notify("Spy", state and "ON" or "OFF", 1.0)
    end
  })

  -- ===== Brainrot lookup =====
  local BrainrotNames
  local function buildBrainrotSetOnce()
    if BrainrotNames ~= nil then return end
    BrainrotNames = {}
    local ok, folder = pcall(function() return S.RS.Assets.Brainrots end)
    if ok and folder then
      for _, ch in ipairs(folder:GetChildren()) do BrainrotNames[ch.Name:lower()] = true end
    end
  end
  buildBrainrotSetOnce()

  -- ===== helpers =====
  local function getCoreNode(tool)
    if not (tool and tool:IsA("Tool")) then return nil end
    local base = F.stripBrackets(tool.Name)
    return tool:FindFirstChild(base) or tool:FindFirstChild(F.safeName(tool))
  end

  local function findAttrDeep(tool, key)
    local function read(inst)
      if inst and inst.GetAttribute then
        local ok, v = pcall(inst.GetAttribute, inst, key)
        if ok and v ~= nil then return v end
      end
    end
    local core = getCoreNode(tool)
    local v = read(tool) or read(core)
    if v ~= nil then return v end
    for _, d in ipairs(tool:GetDescendants()) do
      local vv = read(d); if vv ~= nil then return vv end
    end
    return nil
  end

  local function isBrainrotTool(tool)
    if not (tool and tool:IsA("Tool")) then return false end
    local nm = F.safeName(tool):lower()
    if nm:find("brainrot") then return true end
    if BrainrotNames and BrainrotNames[nm] then return true end
    local cat = findAttrDeep(tool, "Category")
    if type(cat) == "string" and F.norm(cat) == "brainrot" then return true end
    if findAttrDeep(tool, "Brainrot") == true then return true end
    return false
  end

  local FavCache = {}
  local function isFavorited(tool) return findAttrDeep(tool, "Favorited") == true end
  local function getID(tool) local v = findAttrDeep(tool, "ID"); return v and tostring(v) or nil end
  local function getRarity(tool) local v = findAttrDeep(tool, "Rarity"); return v and tostring(v) or nil end
  local function getSize(tool)
    local v = findAttrDeep(tool, "Size")
          or findAttrDeep(tool, "Scale")
          or findAttrDeep(tool, "ModelSize")
          or findAttrDeep(tool, "BRSize")
    return (type(v) == "number") and v or nil
  end

  local function favoriteByID(id, tool)
    if not id then return false end
    if FavCache[id] or isFavorited(tool) then FavCache[id] = true; return true end
    if RM.Favorite then
      pcall(function() RM.Favorite:FireServer(id) end); task.wait(0.08)
      if not isFavorited(tool) then pcall(function() RM.Favorite:FireServer({ ID = id }) end); task.wait(0.08) end
      if not isFavorited(tool) and tool then pcall(function() RM.Favorite:FireServer({ ID = id, Instance = tool }) end); task.wait(0.08) end
    end
    if isFavorited(tool) then FavCache[id] = true; return true end
    return false
  end

  -- ===== Kill window =====
  local KILL_GRACE, killActiveUntil = 10.0, 0
  local function markKill() killActiveUntil = math.max(killActiveUntil, os.clock() + KILL_GRACE) end
  if RM.DeleteBR then
    RM.DeleteBR.OnClientEvent:Connect(function(...) if autoSpy then markKill() end end)
  end

  -- Track BR deaths/despawns
  local BRFolder = S.Scripted:WaitForChild("Brainrots")
  local function watchBRModel(m)
    if not (m and m:IsA("Model")) then return end
    local hum = m:FindFirstChildOfClass("Humanoid")
    if hum then hum.Died:Connect(function() if autoSpy then markKill() end end) end
    m.AncestryChanged:Connect(function(_, parent) if autoSpy and (not parent) then markKill() end end)
  end
  for _, m in ipairs(BRFolder:GetChildren()) do watchBRModel(m) end
  BRFolder.ChildAdded:Connect(watchBRModel)

  -- ===== Main: proses tool baru masuk backpack/char/playerFolder =====
  local function processNewContainer(node)
    if not autoSpy or os.clock() > killActiveUntil then return end

    local tool = node
    if not (tool and tool:IsA("Tool")) then
      for _, d in ipairs(node:GetDescendants()) do if d:IsA("Tool") then tool = d; break end end
    end
    if not (tool and tool:IsA("Tool")) then return end

    local deadline = os.clock() + 8
    local id, rarity
    repeat
      id     = getID(tool)
      rarity = getRarity(tool)
      if id and rarity then break end
      task.wait(0.15)
    until os.clock() > deadline

    if not isBrainrotTool(tool) then return end
    if rarity and (next(chosenRarity) ~= nil) and not chosenRarity[F.norm(rarity)] then return end

    -- ===== size rule =====
    local sz = getSize(tool)
    if (sizeThreshold or 0) > 0 then
      -- filter aktif: wajib ada size dan harus > threshold
      if not sz or sz <= sizeThreshold then
        return -- jangan fav
      end
    else
      -- threshold = 0 → filter size nonaktif
    end
    -- =====================

    favoriteByID(id, tool)
  end

  LP:WaitForChild("Backpack").ChildAdded:Connect(processNewContainer)
  local function hookChar(c) if c then c.ChildAdded:Connect(processNewContainer) end end
  hookChar(LP.Character or LP.CharacterAdded:Wait())
  LP.CharacterAdded:Connect(hookChar)
  local pf = F.myPlayerFolder(); if pf then pf.ChildAdded:Connect(processNewContainer) end
end


-- ========== TAB COMBAT: Auto Move / Auto Hit / Gear / Combo ==========
do
  local ALL_RARITIES={ "Rare","Epic","Mythic","Legendary","Limited","Secret","Godly" }
  local CMB_MOVE = { enabled=false, triggers={ godly=true, secret=true, limited=true, boss=true }, minSize=0, minHP=0, maxPlants=10 }
  local CMB_HIT  = { autoTP_enabled=false, lockFreeze=true, autoEquipBat=true, yOffset=0, stickYOffset=0, bufferDelay=0.12, hitInterval=0.20,
                     allowedRarity={ godly=true, secret=true, limited=true }, minSize=0, minHP=0, gearFire_enabled=false, gearChoice="Banana Gun",
                     combo_enabled=false, comboPeriod=2.0 }

  tabCombat:CreateSectionFold({ Title = "Auto Move Plants" })
  tabCombat:Paragraph("max plant nya jangan di ubah (lupa gw hapus jir) kalo mau di ubah ya silahkan aja, sisa nya atur sesuka kalian")
  tabCombat:Dropdown({ 
    Name="Trigger Rarity/Boss (multi)", 
    Options={"Godly","Secret","Limited","Boss"}, 
    MultiSelection=true, 
    Flag="cmb_move_triggers",
    Search=false,
    Callback=function(values) local m={} if typeof(values)=="table" then for _,v in ipairs(values) do m[F.norm(v)]=true end elseif typeof(values)=="string" then m[F.norm(values)]=true end CMB_MOVE.triggers=m end })
  tabCombat:Input({ Name="Max Plants to Move", PlaceholderText=tostring(CMB_MOVE.maxPlants), NumbersOnly=true, Flag="cmb_move_max_plants", Callback=function(txt) local v=tonumber(txt); if v and v>=1 then CMB_MOVE.maxPlants=math.floor(v); notify("Move","Max="..CMB_MOVE.maxPlants,1.0) end end })
  tabCombat:Input({ Name="Min Size (trigger)", PlaceholderText=tostring(CMB_MOVE.minSize), NumbersOnly=true, Flag="cmb_move_min_size", Callback=function(txt) CMB_MOVE.minSize=tonumber(txt) or 0 end })
  tabCombat:Input({ Name="Min HP (trigger)",   PlaceholderText=tostring(CMB_MOVE.minHP),   NumbersOnly=true, Flag="cmb_move_min_hp",   Callback=function(txt) CMB_MOVE.minHP  =tonumber(txt) or 0 end })
  tabCombat:Toggle({ Name="Auto Move ON/OFF", Default=false, Flag="cmb_move_enabled", Callback=function(v) CMB_MOVE.enabled=v end })

  tabCombat:CreateSectionFold({ Title = "Auto Hit" })
  tabCombat:Dropdown({ Name="Target Rarity (multi)", Options=ALL_RARITIES, MultiSelection=true, Search=false, CurrentOption={"Godly","Secret","Limited"},
    Callback=function(arr) local set={} if typeof(arr)=="table" then for _,v in ipairs(arr) do set[F.norm(v)]=true end elseif typeof(arr)=="string" then set[F.norm(arr)]=true end CMB_HIT.allowedRarity=set end })
  tabCombat:Input({ Name="Min Size (target)", PlaceholderText=tostring(CMB_HIT.minSize), NumbersOnly=true, Flag="cmb_hit_min_size", Callback=function(txt) CMB_HIT.minSize=tonumber(txt) or 0 end })
  tabCombat:Input({ Name="Min HP (target)",   PlaceholderText=tostring(CMB_HIT.minHP),   NumbersOnly=true, Flag="cmb_hit_min_hp",   Callback=function(txt) CMB_HIT.minHP  =tonumber(txt) or 0 end })

  -- freeze helpers
  local HRP = (LP.Character or LP.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart", 15)
  local Hum = (LP.Character or LP.CharacterAdded:Wait()):WaitForChild("Humanoid", 15)
  LP.CharacterAdded:Connect(function(ch)
    task.defer(function()
      HRP = ch:WaitForChild("HumanoidRootPart", 15)
      Hum = ch:WaitForChild("Humanoid", 15)
    end)
  end)
  local DEFAULT_WALKSPEED, DEFAULT_JUMPPOWER, DEFAULT_JUMPHEIGHT = 16, 50, 7.2
  local function cmbUnfreeze() if not Hum then return end Hum.AutoRotate=true; Hum.PlatformStand=false; if Hum.UseJumpPower~=nil then Hum.JumpPower=DEFAULT_JUMPPOWER else pcall(function() Hum.JumpHeight=DEFAULT_JUMPHEIGHT end) end; Hum.WalkSpeed=DEFAULT_WALKSPEED end
  local function cmbFreeze() if not Hum then return end Hum.AutoRotate=false; if CMB_HIT.lockFreeze then if Hum.UseJumpPower~=nil then Hum.JumpPower=0 end; Hum.WalkSpeed=0; Hum.PlatformStand=false end end

  -- stick
  local stick = { cons={}, model=nil, id=nil }
  local function cmbDetachStick() for _,o in ipairs(stick.cons) do if typeof(o)=="Instance" and o.Destroy then pcall(function() o:Destroy() end) end end stick.cons, stick.model, stick.id = {}, nil, nil; cmbUnfreeze() end
  local function cmbWaitModelReady(m,t) t=t or 5; local t0=os.clock(); while os.clock()-t0<t do if m and m.Parent and m:IsDescendantOf(workspace) then local ok=pcall(m.GetBoundingBox,m); if ok then return true end end task.wait(0.05) end return false end
  local function cmbTPAbove(m) if not (m and HRP) then return end if not cmbWaitModelReady(m,5) then return end local ok,cf,size=pcall(m.GetBoundingBox,m); if not ok then return end local top=cf.Position+Vector3.new(0,size.Y+(CMB_HIT.yOffset or 0),0); HRP.AssemblyLinearVelocity=Vector3.zero; local cam=workspace.CurrentCamera; local look=cam and cam.CFrame.LookVector or Vector3.new(0,0,-1); HRP.CFrame=CFrame.new(top, top+look) end
  local function cmbAttachStick(m,id)
    cmbDetachStick(); if not (HRP and m and m.PrimaryPart) then return end
    local a0 = HRP:FindFirstChild("CMB_Att0") or Instance.new("Attachment"); a0.Name="CMB_Att0"; a0.Parent=HRP
    local a1 = m.PrimaryPart:FindFirstChild("CMB_Att1") or Instance.new("Attachment"); a1.Name="CMB_Att1"; a1.Parent=m.PrimaryPart; a1.Position=Vector3.new(0,(CMB_HIT.stickYOffset or 0),0)
    local ap = Instance.new("AlignPosition"); ap.Attachment0,ap.Attachment1=a0,a1; ap.RigidityEnabled=true; ap.MaxForce=math.huge; ap.Responsiveness=300; ap.ApplyAtCenterOfMass=true; ap.Parent=HRP
    local ao = Instance.new("AlignOrientation"); ao.Attachment0,ao.Attachment1=a0,a1; ao.RigidityEnabled=true; ao.MaxTorque=math.huge; ao.Responsiveness=300; ao.Parent=HRP
    stick.cons, stick.model, stick.id = {a0,a1,ap,ao}, m, id; cmbFreeze()
  end

  -- tools
  local function moveToolToBackpack(tool) if not (tool and tool:IsA("Tool")) then return end local bp=LP:FindFirstChild("Backpack"); if bp and tool.Parent~=bp then pcall(function() tool.Parent=bp end) end end
  local function findToolByPartials(partials)
    local char,bp=LP.Character,LP:FindFirstChild("Backpack")
    local function match(t) local n=F.norm(t.Name); for _,k in ipairs(partials) do if not n:find(k,1,true) then return false end end return true end
    if char then for _,t in ipairs(char:GetChildren()) do if t:IsA("Tool") and match(t) then return t,"Character" end end end
    if bp   then for _,t in ipairs(bp:GetChildren())   do if t:IsA("Tool") and match(t) then return t,"Backpack" end end end
    return nil
  end
  local function ensureBlowerOff() local t=findToolByPartials({"frost","blow"}); if t then pcall(function() RM.UseItem:FireServer({Tool=t,Toggle=false}) end) end end
  local function cmbStashAllExcept(char,bp,keep) if not char or not bp then return end for _,t in ipairs(char:GetChildren()) do if t:IsA("Tool") and t~=keep then pcall(function() t.Parent=bp end) end end end
  local function ensureEquippedExclusive(tool,timeout)
    if not tool then return false end
    local char=LP.Character or LP.CharacterAdded:Wait(); local bp=LP:FindFirstChild("Backpack")
    ensureBlowerOff(); cmbStashAllExcept(char,bp,tool)
    if tool.Parent~=char then if RM.EquipItem then pcall(function() RM.EquipItem:FireServer(tool) end); pcall(function() RM.EquipItem:FireServer(tool.Name) end) end if tool.Parent~=char and tool.Parent~=nil then pcall(function() tool.Parent=char end) end end
    local t0,lim=os.clock(),(timeout or 1.0)
    while os.clock()-t0<lim do
      local onlyThis=(tool.Parent==char)
      if onlyThis then for _,t in ipairs(char:GetChildren()) do if t:IsA("Tool") and t~=tool then onlyThis=false break end end end
      if onlyThis then return true end
      cmbStashAllExcept(char,bp,tool); task.wait(0.05)
    end
    return (tool.Parent==char)
  end
  local function findBatInBackpack() local bp=LP:FindFirstChild("Backpack"); if not bp then return nil end for _,tool in ipairs(bp:GetChildren()) do if tool:IsA("Tool") and F.norm(tool.Name):find("bat") then return tool end end return nil end
  local function cmbEquipBat() if not CMB_HIT.autoEquipBat then return end local t=findBatInBackpack(); if t then ensureEquippedExclusive(t,1.0) end end

  -- rarity lookup & filters
  local Modules  = S.RS:FindFirstChild("Modules")
  local Utility  = Modules and Modules:FindFirstChild("Utility") or Modules and Modules:FindFirstChild("Utility")
  local Util     = Utility and require(Utility:WaitForChild("Util"))
  local function cmbGetBRName(model) local keys={"Brainrot","BrainRot","brainrot","Name","Title"} for _,k in ipairs(keys) do local v=model:GetAttribute(k); if type(v)=="string" and #v>0 then return v end end return model.Name end
  local function cmbGetRarityModel(model)
    if not Util or not Util.GetBrainrotEntry then return model:GetAttribute("Rarity") end
    local nm=cmbGetBRName(model); local ok,entry=pcall(Util.GetBrainrotEntry,Util,nm)
    if ok and entry and entry.Rarity then return entry.Rarity end
    return model:GetAttribute("Rarity")
  end
-- TRIGGER MOVE: rarity/boss ATAU size >= minSize ATAU hp >= minHP
-- Hanya threshold; rarity/boss diabaikan
local function passMoveTrigger(isBoss, rarity, sizeVal, hpVal)
  local minSize = tonumber(CMB_MOVE.minSize) or 0
  local minHP   = tonumber(CMB_MOVE.minHP)   or 0

  -- 0 & 0 = tidak move (meski toggle ON)
  if minSize <= 0 and minHP <= 0 then
    return false
  end

  -- kalau di-set, harus lolos batas minimal
  if minHP   > 0 and (hpVal   or 0) < minHP   then return false end
  if minSize > 0 and (sizeVal or 0) < minSize then return false end

  -- lolos semua syarat → pindah
  return true
end


  local function passHitFilter(rarity, sizeVal, hpVal)
    local okR = rarity and (CMB_HIT.allowedRarity[F.norm(rarity)]==true) or false
    return okR and (sizeVal>=(CMB_HIT.minSize or 0)) and (hpVal>=(CMB_HIT.minHP or 0))
  end

  -- hit loop + visuals
  local hitToken=0
  local function cmbVisualHit(model)
    if not (model and model.PrimaryPart) then return end
    local att=Instance.new("Attachment",model.PrimaryPart)
    local pe=Instance.new("ParticleEmitter"); pe.Rate=0; pe.Lifetime=NumberRange.new(0.2,0.35); pe.Speed=NumberRange.new(6,10); pe.SpreadAngle=Vector2.new(60,60); pe.Texture="rbxassetid://243660364"; pe.Parent=att; pe:Emit(14)
    S.Debris:AddItem(att,1)
  end
  local function startHitLoop()
    if not RM.WeaponAttack then return end
    hitToken += 1; local my=hitToken
    task.spawn(function()
      while my==hitToken do
        if stick.model and stick.model.Parent then
          local id = stick.id or stick.model:GetAttribute("ID") or stick.model.Name
          pcall(function() RM.WeaponAttack:FireServer({ tostring(id) }) end)
          cmbVisualHit(stick.model)
        end
        task.wait(CMB_HIT.hitInterval or 0.2)
      end
    end)
  end
  local function stopHitLoop() hitToken += 1 end

  -- ACTIVE tracking & lock logic
  local ACTIVE, CURRENT, preferredRarity, locked = {}, {id=nil,model=nil,rarity=nil}, nil, false
  local buf, bufScheduled, handled = {}, false, {}
  local function setCurrent(id, m) CURRENT.id, CURRENT.model = id, m; local r=cmbGetRarityModel(m); CURRENT.rarity=r and F.norm(r) or nil; preferredRarity=CURRENT.rarity end
  local function pickSameRarity(rWanted)
    if not rWanted then return nil,nil end
    local char=LP.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart")
    local bestId,bestModel,bestDist=nil,nil,math.huge
    for id,m in pairs(ACTIVE) do
      if m and m.Parent and m.PrimaryPart then
        local r=cmbGetRarityModel(m)
        if r and F.norm(r)==rWanted then
          local d=hrp and (m.PrimaryPart.Position-hrp.Position).Magnitude or 0
          if d<bestDist then bestId,bestModel,bestDist=id,m,d end
        end
      end
    end
    return bestId,bestModel
  end
  local function chooseBestFromBuf()
    local cam=workspace.CurrentCamera
    local best,bestRank,bestDist=nil,-1,1e9
    for _,it in ipairs(buf) do
      local m=it.model
      if m and m.Parent then
        local rarity=cmbGetRarityModel(m)
        local sizeVal=F.readModelSize(m)
        local hpVal  =F.readModelHP(m)
        if passHitFilter(rarity,sizeVal,hpVal) then
          local rank=({rare=1,epic=2,mythic=3,legendary=4,limited=4,secret=5,godly=6})[F.norm(rarity)] or 0
          local dist=1e9; local ok,cf=pcall(m.GetBoundingBox,m); if ok and cam then dist=(cf.Position-cam.CFrame.Position).Magnitude end
          if rank>bestRank or (rank==bestRank and dist<bestDist) then best,bestRank,bestDist=it,rank,dist end
        end
      end
    end
    return best
  end
  local function lockOn(pick) cmbEquipBat(); cmbTPAbove(pick.model); cmbAttachStick(pick.model, pick.id); setCurrent(pick.id,pick.model); locked=true; startHitLoop() end
  local function processBuf() bufScheduled=false; if locked or not CMB_HIT.autoTP_enabled or #buf==0 then buf={} return end local pick=chooseBestFromBuf(); buf={}; if not pick or not pick.model or not pick.model.Parent then return end task.defer(function() lockOn(pick) end) end
  local function markHandled(id) handled[id]=true end
  local function isHandled(id) return handled[id]==true end
  local function enqueue(m,id) if isHandled(id) or locked or not CMB_HIT.autoTP_enabled then return end markHandled(id); buf[#buf+1]={model=m,id=id}; if not bufScheduled then bufScheduled=true; task.delay(CMB_HIT.bufferDelay or 0.12, processBuf) end end
  local function relockFromWorld()
    if locked or not CMB_HIT.autoTP_enabled then return end
    local sid,sm=pickSameRarity(preferredRarity); if sid and sm then lockOn({id=sid,model=sm}); return end
    local char=LP.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart")
    local bestId,bestM,bestD
    for id,m in pairs(ACTIVE) do
      if m and m.Parent and m.PrimaryPart then
        local rarity=cmbGetRarityModel(m); local sz=F.readModelSize(m); local hp=F.readModelHP(m)
        if passHitFilter(rarity,sz,hp) then local d=hrp and (m.PrimaryPart.Position-hrp.Position).Magnitude or 0; if not bestD or d<bestD then bestId,bestM,bestD=id,m,d end end
      end
    end
    if bestId and bestM then lockOn({id=bestId, model=bestM}) end
  end
  local function unlock() stopHitLoop(); cmbDetachStick(); locked=false; relockFromWorld() end

  tabCombat:Toggle({ Name="Enable Auto TP + Hit (Freeze On Lock)", Default=false, Callback=function(on)
    CMB_HIT.autoTP_enabled=on; CMB_HIT.lockFreeze=on; CMB_HIT.autoEquipBat=on
    if not on then buf,bufScheduled={},false; if locked then unlock() end; stopHitLoop(); cmbUnfreeze(); local t=findToolByPartials({"frost","blow"}); if t then pcall(function() RM.UseItem:FireServer({Tool=t,Toggle=false}) end) end
    else task.defer(function() relockFromWorld() end) end
  end })

  -- Gear
  tabCombat:Label("Auto Hit Gear")
  local REG = {
    ["Frost Grenade"]   = { keys={"frost","gren"}, time=0.50, kind="pulse" },
    ["Banana Gun"]      = { keys={"banana","gun"}, time=0.04, kind="pulse" },
    ["Carrot Launcher"] = { keys={"carrot","launc"}, time=0.23, kind="pulse" },
    ["Frost Blower"]    = { keys={"frost","blow"}, time=0.10, kind="toggle" },
  }
  tabCombat:Dropdown({ 
    Name="Gear", 
    Options={"Frost Grenade","Banana Gun","Carrot Launcher","Frost Blower"}, 
    MultiSelection=false, 
    Flag="cmb_hit_gear_choice",
    CurrentOption=CMB_HIT.gearChoice, 
    Callback=function(v) CMB_HIT.gearChoice = type(v)=="table" and v[1] or v end })
  local lastUseAt, gearFireToken = 0, 0
  local function safeUse(payload)
    if time() - lastUseAt < 0.06 then task.wait(0.06) end
    lastUseAt = time()
    local ok = pcall(function() RM.UseItem:FireServer(payload) end); if ok then return true end
    ok = pcall(function() RM.UseItem:FireServer(unpack({payload})) end); if ok then return true end
    ok = pcall(function() local a={}; a[1]=payload; RM.UseItem:FireServer(table.unpack(a)) end); return ok
  end
  local function chooseTargetPos()
    local char=LP.Character or LP.CharacterAdded:Wait(); local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return Vector3.zero end
    local bestAny,bestD
    for _,m in pairs(ACTIVE) do
      if m and m.Parent and m.PrimaryPart then
        local r=cmbGetRarityModel(m); local sz=F.readModelSize(m); local hp=F.readModelHP(m)
        if passHitFilter(r,sz,hp) then local pos=m.PrimaryPart.Position; local d=(pos-hrp.Position).Magnitude; if not bestD or d<bestD then bestAny,bestD=pos,d end end
      end
    end
    return bestAny or hrp.Position
  end
  local function startGearFireLoop()
    gearFireToken += 1; local my=gearFireToken
    task.spawn(function()
      while CMB_HIT.gearFire_enabled and my==gearFireToken do
        local entry=REG[CMB_HIT.gearChoice]
        if entry then
          local tool=findToolByPartials(entry.keys)
          if tool and ensureEquippedExclusive(tool,1.0) then
            local pos=chooseTargetPos()
            if entry.kind=="pulse" then
              safeUse({ Toggle=true, Time=entry.time, Tool=tool, Pos=pos })
              if CMB_HIT.gearChoice=="Frost Grenade" then
                local hum=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid"); if hum then pcall(function() hum:UnequipTools() end) end
                local bp=LP:FindFirstChild("Backpack"); if bp then cmbStashAllExcept(LP.Character,bp,nil) end
              end
            else safeUse({ Tool=tool, Toggle=true }) end
          end
        else task.wait(0.2) end
        task.wait(0.10)
      end
      if CMB_HIT.gearChoice=="Frost Blower" then
        local t=findToolByPartials(REG["Frost Blower"].keys); if t then safeUse({ Tool=t, Toggle=false }) end
      end
    end)
  end
  local function stopGearFireLoop() gearFireToken += 1 end
  tabCombat:Toggle({ Name="Enable Auto Hit Gear", Default=false, Flag="cmb_hit_enable_auto_gear", Callback=function(on) CMB_HIT.gearFire_enabled=on; if on then startGearFireLoop() else stopGearFireLoop(); local t=findToolByPartials(REG["Frost Blower"].keys); if t then safeUse({ Tool=t, Toggle=false }) end end end })

  -- Combo
  tabCombat:Label("Combo Gear")
  tabCombat:Paragraph("Frost×1 → Banana×4 → Carrot×2 (bila tidak ada skip gear)")
  local comboToken=0
  local function runComboCycle()
    local char=LP.Character or LP.CharacterAdded:Wait(); local bp=LP:FindFirstChild("Backpack")
    do local e=REG["Frost Grenade"]; local t=findToolByPartials(e.keys)
      if t and ensureEquippedExclusive(t,1.0) then local pos=chooseTargetPos(); safeUse({ Toggle=true, Time=e.time, Tool=t, Pos=pos }); task.wait(0.12); local hum=char and char:FindFirstChildOfClass("Humanoid"); if hum then pcall(function() hum:UnequipTools() end) end; cmbStashAllExcept(char,bp,nil); task.wait(0.03) end
    end
    do local e=REG["Banana Gun"]; local t=findToolByPartials(e.keys)
      if t and ensureEquippedExclusive(t,1.0) then local pos=chooseTargetPos(); for i=1,4 do safeUse({ Toggle=true, Time=e.time, Tool=t, Pos=pos }); task.wait(0.06) end; local hum=char and char:FindFirstChildOfClass("Humanoid"); if hum then pcall(function() hum:UnequipTools() end) end; cmbStashAllExcept(char,bp,nil); task.wait(0.03) end
    end
    do local e=REG["Carrot Launcher"]; local t=findToolByPartials(e.keys)
      if t and ensureEquippedExclusive(t,1.0) then local pos=chooseTargetPos(); for i=1,2 do safeUse({ Toggle=true, Time=e.time, Tool=t, Pos=pos }); task.wait(0.08) end; local hum=char and char:FindFirstChildOfClass("Humanoid"); if hum then pcall(function() hum:UnequipTools() end) end; cmbStashAllExcept(char,bp,nil) end
    end
  end
  tabCombat:Toggle({ Name="Enable Combo", Default=false, Callback=function(on)
    CMB_HIT.combo_enabled=on
    if on then comboToken += 1; local my=comboToken; task.spawn(function() while my==comboToken and CMB_HIT.combo_enabled do local t0=os.clock(); runComboCycle(); local rest=(CMB_HIT.comboPeriod or 2.0)-(os.clock()-t0); if rest>0 then task.wait(rest) end end end)
    else comboToken += 1; local t=findToolByPartials({"frost","blow"}); if t then safeUse({ Tool=t, Toggle=false }); moveToolToBackpack(t) end end
  end })

  -- world hooks (spawn/delete + relock)
  local function getRowModel(plot,rowNo) local rows=plot and plot:FindFirstChild("Rows"); if not rows then return nil end return rows:FindFirstChild(tostring(rowNo)) end
  local function isTileFree(tile) if tile:GetAttribute("Occupied")==true then return false end if tile:FindFirstChild("Plant") or tile:FindFirstChild("Crop") then return false end return true end
  -- urutkan tile kosong di 1 row berdasarkan jarak dari anchor (aman terhadap nil/tipe aneh)
local function getRowEmptyTilesSorted(rowModel)
    if not rowModel then return {} end
    local grass = rowModel:FindFirstChild("Grass")
    if not grass then return {} end

    -- anchor bisa Part/Model/Attachment; pakai helper F.worldPosOf supaya aman
    local anchor = rowModel:FindFirstChild("BrainrotWalkto") or rowModel:FindFirstChild("BrainrotEnd")
    local posA = F.worldPosOf(anchor)
    if not posA then
        local ok, cf = pcall(rowModel.GetPivot, rowModel)
        posA = (ok and cf and cf.Position) or (rowModel.PrimaryPart and rowModel.PrimaryPart.Position) or Vector3.zero
    end

    local out = {}
    for _, tile in ipairs(grass:GetChildren()) do
        if (tile:IsA("BasePart") or tile:IsA("Model")) and isTileFree(tile) then
            local p = F.worldPosOf(tile)
            if p then
                out[#out+1] = { tile = tile, dist = (p - posA).Magnitude }
            end
        end
    end

    -- comparator defensif: paksa ke number, kalau gagal pakai math.huge
    table.sort(out, function(a, b)
        local da = tonumber(a and a.dist) or math.huge
        local db = tonumber(b and b.dist) or math.huge
        return da < db
    end)

    local only = {}
    for i = 1, #out do
        only[#only+1] = out[i].tile
    end
    return only
end

  local function allPlotTiles(plot) local list={} local rows=plot and plot:FindFirstChild("Rows"); if not rows then return list end for _,row in ipairs(rows:GetChildren()) do local grass=row:FindFirstChild("Grass"); if grass then for _,t in ipairs(grass:GetChildren()) do list[#list+1]=t end end end return list end
  local function nearestTileToPos(plot,pos) local best,bd=nil,1/0 for _,t in ipairs(allPlotTiles(plot)) do local p=t:IsA("BasePart") and t.Position or t:GetPivot().Position local d=(p-pos).Magnitude if d<bd then bd=d; best=t end end return best end
  local function getPlantID(plantInst) local ok,v=pcall(plantInst.GetAttribute,plantInst,"ID"); if ok and v then return tostring(v) end return nil end
  local function getPlantDamage(plantInst) local keys={"Damage","DPS","Power"} for _,k in ipairs(keys) do local ok,v=pcall(plantInst.GetAttribute,plantInst,k); if ok and type(v)=="number" then return v end end return 0 end
  local function getPlantWorldPos(plantInst) local cf if plantInst.PrimaryPart then cf=plantInst.PrimaryPart.CFrame elseif plantInst:IsA("Model") then cf=plantInst:GetPivot() elseif plantInst:IsA("BasePart") then cf=plantInst.CFrame end return cf and cf.Position or nil end
  local function getToolByBaseName(base) if not base or #base==0 then return nil end base=tostring(base):lower()
    local function pick(container) if not container then return end for _,t in ipairs(container:GetChildren()) do if t:IsA("Tool") then local n1=t.Name:lower():gsub("^%b[]%s*",""); local n2=F.safeName(t):lower(); if n1==base or n2==base or n1:find(base,1,true) or n2:find(base,1,true) then return t end end end end
    local ch=LP.Character; return pick(ch) or pick(LP:FindFirstChild("Backpack")) or pick(F.myPlayerFolder()) end
  local function equipTool(tool) if not tool or not tool.Parent then return false end local char=LP.Character or LP.CharacterAdded:Wait(); local hum=char:FindFirstChildOfClass("Humanoid"); if hum then pcall(function() hum:EquipTool(tool) end) end return tool.Parent==char end
  local function equipShovel() local s=getToolByBaseName("Shovel [Pick Up Plants]") or getToolByBaseName("Shovel"); if not s then return false end return equipTool(s) end
  local function waitToolByID(id,timeout) local deadline=os.clock()+(timeout or 4) local bag=LP:WaitForChild("Backpack") repeat for _,t in ipairs(bag:GetChildren()) do if t:IsA("Tool") then local ok,v=pcall(t.GetAttribute,t,"ID"); if ok and v and tostring(v)==tostring(id) then return t end end end task.wait(0.1) until os.clock()>deadline return nil end
  local function plantNameFromTool(tool) local n=F.safeName(tool) n=n:gsub("^%[%s*%d+x%s*%]%s*","") return n end
  local function pickupPlantByID(plantID) if not equipShovel() then return false,"no shovel" end local ok=pcall(function() RM.RemoveItem:FireServer(plantID) end); if not ok then return false,"remote error" end local tool=waitToolByID(plantID,6); return tool~=nil, tool end
  local function placePlantToolOnTile(tool,tile)
    if not tool or not tool:IsA("Tool") then return false end
    if tool.Parent~=(LP.Character or LP.CharacterAdded:Wait()) then equipTool(tool) end
    local id=tool:GetAttribute("ID"); local itemName=plantNameFromTool(tool); if not id or not itemName then return false end
    pcall(function() RM.PlaceItem:FireServer({ ID=id, CFrame=F.partCFrame(tile), Item=itemName, Floor=tile }) end)
    return true
  end

  local activeMoves, movingFlag = {}, false
  local function startMoveForRow(brID,rowModel)
    if movingFlag then return end
    movingFlag=true
    task.spawn(function()
      local function findMyPlot()
        for _, p in ipairs(S.Plots:GetChildren()) do if p:GetAttribute("OwnerUserId")==LP.UserId then return p end end
        for _, p in ipairs(S.Plots:GetChildren()) do if p:GetAttribute("Owner")==LP.Name then return p end end
      end
      local plot=findMyPlot(); if not plot then movingFlag=false; return end
      local plantsFolder=plot:FindFirstChild("Plants"); if not plantsFolder then movingFlag=false; return end
      local targets=getRowEmptyTilesSorted(rowModel); if #targets==0 then notify("Move","Tidak ada tile kosong di row",1.0); movingFlag=false; return end
      local list={}
      for _,p in ipairs(plantsFolder:GetChildren()) do local id=getPlantID(p); local dmg=getPlantDamage(p); local pos=getPlantWorldPos(p); if id and pos then list[#list+1]={inst=p,id=id,dmg=dmg,pos=pos} end end
      table.sort(list,function(a,b) return (a.dmg or 0)>(b.dmg or 0) end)
      local picked={}; local takeN=math.min(CMB_MOVE.maxPlants,#targets,#list); for i=1,takeN do picked[i]={ plant=list[i], target=targets[i] } end
      if #picked==0 then movingFlag=false; return end
      activeMoves[brID]={}
      for _,it in ipairs(picked) do
        local plant,target=it.plant,it.target
        local origTile=nearestTileToPos(plot,plant.pos)
        local ok,tool=pickupPlantByID(plant.id)
        if ok and tool then
          local itemName=plantNameFromTool(tool)
          placePlantToolOnTile(tool,target)
          table.insert(activeMoves[brID],{ id=plant.id, origTile=origTile, origPos=plant.pos, itemName=itemName })
          task.wait(0.12)
        end
      end
      movingFlag=false
    end)
  end
  local function returnMovedPlants(brID)
    local batch=activeMoves[brID]; if not batch or #batch==0 then return end
    task.spawn(function()
      local function findMyPlot()
        for _, p in ipairs(S.Plots:GetChildren()) do if p:GetAttribute("OwnerUserId")==LP.UserId then return p end end
        for _, p in ipairs(S.Plots:GetChildren()) do if p:GetAttribute("Owner")==LP.Name then return p end end
      end
      local plot=findMyPlot(); if not plot then activeMoves[brID]=nil; return end
      local plantsFolder=plot:FindFirstChild("Plants")
      for _,info in ipairs(batch) do
        local instInWorld=nil
        if plantsFolder then for _,p in ipairs(plantsFolder:GetChildren()) do local id=getPlantID(p); if id and tostring(id)==tostring(info.id) then instInWorld=p; break end end end
        if instInWorld then local ok=equipShovel(); if ok then pcall(function() RM.RemoveItem:FireServer(info.id) end) end; task.wait(0.25) end
        local tool=waitToolByID(info.id,6); if tool and info.origTile then placePlantToolOnTile(tool,info.origTile) end
        task.wait(0.12)
      end
      activeMoves[brID]=nil
    end)
  end

  local function getMyPlotIndex()
    local function findMyPlot() for _, p in ipairs(S.Plots:GetChildren()) do if p:GetAttribute("OwnerUserId")==LP.UserId then return p end end for _, p in ipairs(S.Plots:GetChildren()) do if p:GetAttribute("Owner")==LP.Name then return p end end end
    local p=findMyPlot(); return p and tonumber(p.Name) or nil
  end
  local myPlotIndex = getMyPlotIndex()

  if RM.SpawnBR then
    RM.SpawnBR.OnClientEvent:Connect(function(data)
      if not data then return end
      local plotNo = tonumber(data.Plot); if myPlotIndex and plotNo ~= myPlotIndex then return end
      local m = data.Model; if not (m and m:IsA("Model")) then return end
      local isBoss = data.Mutations and data.Mutations.IsBoss == true
      task.wait(0.05)
      local Modules=S.RS:FindFirstChild("Modules")
      local Utility=Modules and Modules:FindFirstChild("Utility")
      local Util=Utility and require(Utility:WaitForChild("Util"))
      local rarity = (function() local stats=m:FindFirstChild("Stats"); if stats and stats:FindFirstChild("Rarity") and stats.Rarity:IsA("TextLabel") then return tostring(stats.Rarity.Text) end return m:GetAttribute("Rarity") or (Util and Util.GetBrainrotEntry and (select(2,pcall(Util.GetBrainrotEntry,Util,(m:GetAttribute("Brainrot") or m.Name))) or {}).Rarity) end)()
      local sizeVal, hpVal = F.readModelSize(m), F.readModelHP(m)
      local id = data.ID or m:GetAttribute("ID") or m.Name
      ACTIVE[id] = m

      if CMB_MOVE.enabled and passMoveTrigger(isBoss, rarity, sizeVal, hpVal) then
        local function findMyPlot() for _, p in ipairs(S.Plots:GetChildren()) do if p:GetAttribute("OwnerUserId")==LP.UserId then return p end end for _, p in ipairs(S.Plots:GetChildren()) do if p:GetAttribute("Owner")==LP.Name then return p end end end
        local plot=findMyPlot(); if plot then local rowModel=getRowModel(plot, data.RowNo); if rowModel then startMoveForRow(id,rowModel) end end
      end
      if passHitFilter(rarity,sizeVal,hpVal) then enqueue(m, id) end
    end)
  end
  if RM.DeleteBR then
    RM.DeleteBR.OnClientEvent:Connect(function(id)
      ACTIVE[id] = nil
      if stick.model and (stick.model:GetAttribute("ID")==id or stick.model.Name==id) then stopHitLoop(); cmbDetachStick(); locked=false; relockFromWorld() end
      returnMovedPlants(id)
    end)
  end

  S.Run.Stepped:Connect(function()
    if locked then
      if not (stick.model and stick.model.Parent) then unlock() return end
      local hasAP, hasAO = false, false
      for _,o in ipairs(stick.cons) do if typeof(o)=="Instance" and o.Parent then if o:IsA("AlignPosition") then hasAP=true end; if o:IsA("AlignOrientation") then hasAO=true end end end
      if (not hasAP) or (not hasAO) then cmbAttachStick(stick.model, stick.id) end
    else
      if CMB_HIT.autoTP_enabled then relockFromWorld() end
    end
  end)

  task.delay(0.25, function()
    local br = S.Scripted:FindFirstChild("Brainrots")
    if br then for _, m in ipairs(br:GetChildren()) do if m:IsA("Model") then ACTIVE[m:GetAttribute("ID") or m.Name] = m end end end
    if CMB_HIT.autoTP_enabled then relockFromWorld() end
  end)
end

-- =============================
-- Tab Deck ▸ Smart Loadout (Shiny > Tier) — All Presets (names only)
-- =============================
do
  local Players           = game:GetService("Players")
  local ReplicatedStorage = game:GetService("ReplicatedStorage")
  local LP                = Players.LocalPlayer

  -- ====== CONFIG / REMOTES ======
  local PlayerData  = require(ReplicatedStorage:WaitForChild("PlayerData"))
  local EquipRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("EquipCard")

  -- ====== PRESET META ======
  local META = {
    ["Wave Clear"]           = { "Doom Bloom","Plant Frenzy","Petal Storm","Meteor Strike","Chain Lightning","Freezing Field","Whirlwind","Spirit Bloom","Overgrowth","Time Blossom" },
    ["Bossing"]              = { "Aura","Doom Bloom","Bloom Ascendant","Freezing Field","Frozen Blast","Frozen Frenzy","Petal Storm","Plant Frenzy","Time Blossom" },
    ["Freeze Synergy"]       = { "Freezing Field","Frozen Blast","Frozen Frenzy","Doom Bloom","Petal Storm","Chain Lightning","Time Blossom","Overgrowth","Meteor Strike" },
    ["AFK Money"]            = { "Bloom Bank","Solar Burst","Brainrot Blessing","Rizzroot Manifestation","Whirlwind","Secret Collection","Secret Slayer" },
    ["Secret Hunt"]          = { "Secret Collection","Secret Slayer","Rizzroot Manifestation","Bloom Bank","Solar Burst","Brainrot Blessing","Whirlwind" },
    ["Row/Tile Synergy"]     = { "Mono-Crop Mindset","Tile Trio","Doom Bloom","Plant Frenzy","Petal Storm","Spirit Bloom","Overgrowth" },
    ["Bat Build"]            = { "Batter Up","Home Run","Whirlwind","Time Blossom","Meteor Strike","Chain Lightning" },
    ["Anti-Rush / Control"]  = { "Whirlwind","Overgrowth","Freezing Field","Time Blossom","Meteor Strike","Chain Lightning" },
    ["Early/Common"]         = { "Doom Bloom","Plant Frenzy","Chain Lightning","Whirlwind","Brainrot Blessing" },
    ["Poison Cloud Clear"]   = { "Toxic Cloud","Petal Storm","Chain Lightning","Meteor Strike","Doom Bloom","Overgrowth","Whirlwind" },
    ["Freeze–Poison Lock"]   = { "Freezing Field","Frozen Blast","Frozen Frenzy","Toxic Cloud","Doom Bloom","Time Blossom","Overgrowth" },
    ["On-Kill Economy Rush"] = { "Solar Burst","Bloom Bank","Brainrot Blessing","Rizzroot Manifestation","Chain Lightning","Whirlwind","Secret Slayer" },
    ["Magma Detonate"]       = { "Inferno Petal","Doom Bloom","Petal Storm","Chain Lightning","Meteor Strike" },
    ["Lane Boss Suppress"]   = { "Aura","Doom Bloom","Bloom Ascendant","Freezing Field","Petal Storm","Frozen Blast" },
    ["Map Reset Spam"]       = { "Whirlwind","Overgrowth","Freezing Field","Time Blossom","Meteor Strike","Chain Lightning" },
    ["Cactus Machinegun"]    = { "Cactus Flurry","Doom Bloom","Plant Frenzy","Tile Trio","Mono-Crop Mindset","Spirit Bloom" },
    ["Sunflower Battery"]    = { "Sunflower Flurry","Doom Bloom","Plant Frenzy","Tile Trio","Mono-Crop Mindset","Spirit Bloom" },
    ["Pumpkin Brawler"]      = { "Pumpkin Flurry","Doom Bloom","Plant Frenzy","Tile Trio","Mono-Crop Mindset" },
    ["Rarity Farming"]       = { "Legendary Collection","Mythic Collection","Godly Collection","Limited Collection","Epic Collection","Rare Collection" },
    ["Hybrid Daily Driver"]  = { "Doom Bloom","Plant Frenzy","Petal Storm","Freezing Field","Solar Burst" },
  }

  -- ====== DATA HELPERS ======
  local function GetReplicaBlocking()
    local data
    repeat
      task.wait(0.05)
      local ok, result = pcall(function() return PlayerData:GetData() end)
      if ok and result then data = result end
    until data and next(data) ~= nil
    return data
  end

  local function Snapshot()
    local replica = GetReplicaBlocking()
    local root = replica.Data or replica
    local cards = (root and root.Cards) or {}
    return cards.Inventory or {}, cards.Equipped or {}, replica
  end

  local function IndexInventory(inv)
    local idx, flat = {}, {}
    local isArray = (#inv > 0) and (typeof(inv[1]) == "table")

    if isArray then
      for i, card in ipairs(inv) do
        local uuid = card.UUID or card.uuid or ("idx_"..i)
        local t    = card.Type or "?"
        local d    = card.Data or {}
        local info = { uuid = uuid, typeName = t, tier = d.Tier or 1, shiny = d.Shiny == true }
        idx[t] = idx[t] or {}
        table.insert(idx[t], info)
        table.insert(flat, info)
      end
    else
      for uuid, card in pairs(inv) do
        local t    = card.Type or "?"
        local d    = card.Data or {}
        local info = { uuid = uuid, typeName = t, tier = d.Tier or 1, shiny = d.Shiny == true }
        idx[t] = idx[t] or {}
        table.insert(idx[t], info)
        table.insert(flat, info)
      end
    end

    local function sorter(a,b)
      if a.shiny ~= b.shiny then return a.shiny end
      if a.tier  ~= b.tier  then return a.tier  > b.tier  end
      if a.typeName ~= b.typeName then return a.typeName < b.typeName end
      return a.uuid < b.uuid
    end
    for _, list in pairs(idx) do table.sort(list, sorter) end
    table.sort(flat, sorter)
    return idx, flat
  end

  local function PickUuid(idx, typeName)
    local list = idx[typeName]
    if not list or #list==0 then return nil end
    return list[1].uuid
  end

  local function BuildLoadoutWithFallback(idx, flat, priority)
    local picked, usedUuid, usedType = {}, {}, {}
    for _, name in ipairs(priority) do
      if #picked >= 5 then break end
      if not usedType[name] then
        local uuid = PickUuid(idx, name)
        if uuid then
          table.insert(picked, { typeName=name, uuid=uuid, fallback=false })
          usedType[name] = true; usedUuid[uuid] = true
        end
      end
    end
    if #picked < 5 then
      for _, cand in ipairs(flat) do
        if #picked >= 5 then break end
        if not usedUuid[cand.uuid] then
          table.insert(picked, { typeName=cand.typeName, uuid=cand.uuid, fallback=true })
          usedUuid[cand.uuid] = true
        end
      end
    end
    return picked
  end

  -- ====== REMOTE HELPERS ======
  local function EquipSlot(slot, uuid)   if uuid then EquipRemote:FireServer(uuid, true,  slot) end end
  local function UnequipSlot(slot, uuid) if uuid then EquipRemote:FireServer(uuid, false, slot) end end
  local function EquipFive(loadout)   for i=1, math.min(5,#loadout) do EquipSlot(i, loadout[i].uuid);   task.wait(0.05) end end
  local function UnequipFive(loadout) for i=1, math.min(5,#loadout) do UnequipSlot(i, loadout[i].uuid); task.wait(0.05) end end

  -- ====== TAB “Deck” ======
  local tabDeck = win:CreateTab({ Name = "Deck" })
  local head = tabDeck:CreateSectionFold({ Title = "Smart Loadout Deck Cards" })
  head:Paragraph("Jika kalian tidak punya cards yang sesuai maka akan di ganti dengan cards lain yang ada di inventory (fallback).")

  local panels = {}
  local currentLoadouts = {}

  local function listToText(load)
    if #load==0 then return "(kosong)" end
    local lines={}
    for _,it in ipairs(load) do
      table.insert(lines, ("• %s%s"):format(it.typeName, it.fallback and " (fallback)" or ""))
    end
    return table.concat(lines, "\n")
  end

  for name, _ in pairs(META) do
    local sec = tabDeck:CreateSectionFold({ Title = name })
    local lblStatus = sec:Label("Status: (loading)")
    local lblList   = sec:Paragraph("(menyiapkan…)")

    sec:Button({
      Name = "Equip",
      Callback = function()
        local L = currentLoadouts[name] or {}
        if #L >= 1 then EquipFive(L) end
      end
    })
    sec:Button({
      Name = "Unequip",
      Callback = function()
        local L = currentLoadouts[name] or {}
        if #L >= 1 then UnequipFive(L) end
      end
    })

    panels[name] = { lblStatus = lblStatus, lblList = lblList }
  end

  local function refreshAll()
    local inv = Snapshot()
    local idx, flat = IndexInventory(inv)
    for name, p in pairs(panels) do
      local picked = BuildLoadoutWithFallback(idx, flat, META[name] or {})
      currentLoadouts[name] = picked
      p.lblList:Set(listToText(picked))
      if #picked == 0 then
        p.lblStatus:Set("Status: Tidak ada kartu di inventory.")
      elseif #picked < 5 then
        p.lblStatus:Set(("Status: Terisi %d/5 (sisanya fallback jika tersedia)."):format(#picked))
      else
        local fallbackCount=0; for _,it in ipairs(picked) do if it.fallback then fallbackCount+=1 end end
        p.lblStatus:Set(fallbackCount>0 and ("Status: Siap (5/5) — %d fallback"):format(fallbackCount) or "Status: Siap (5/5)")
      end
    end
  end

  task.spawn(function()
    local _, _, replica = Snapshot()
    for _, path in ipairs({ {"Cards","Inventory"}, {"Cards","Equipped"}, {"Cards"} }) do
      if typeof(replica.ListenToChange)      == "function" then replica:ListenToChange(path,      refreshAll) end
      if typeof(replica.ListenToArrayInsert) == "function" then replica:ListenToArrayInsert(path, refreshAll) end
      if typeof(replica.ListenToArraySet)    == "function" then replica:ListenToArraySet(path,    refreshAll) end
    end
  end)
  refreshAll()
end

-- =============================
-- TAB: Garden ▸ Auto Cycle (Harvest → Plant 35 → Wait Grow → Harvest → Favorite → Replant)
-- =============================
do
  tabGarden:CreateSectionFold({ Title = "ternak titan plant kalau hoki" })
  tabGarden:Paragraph("cara pakainya ya refresh terus pilih seed di dropdown, terus jalanin dah (btw keknya masih ada bug)")
  local STATUS     = tabGarden:Label("Status: Idle")
  local CYCLE_INFO = tabGarden:Label("—")
  local function setStatus(s) if STATUS and STATUS.Set then STATUS:Set("Status: "..tostring(s)) end end
  local function setInfo(s)   if CYCLE_INFO and CYCLE_INFO.Set then CYCLE_INFO:Set(tostring(s)) end end

  ----------------------------------------------------------------
  -- Helpers (local, tidak bentrok)
  ----------------------------------------------------------------
  local function myPlot()
    for _, p in ipairs(S.Plots:GetChildren()) do
      if p:GetAttribute("OwnerUserId")==LP.UserId or p:GetAttribute("Owner")==LP.Name then
        return p
      end
    end
  end

  local function deepAttr(inst, key)
    if not inst then return nil end
    if inst.GetAttribute then
      local ok, v = pcall(inst.GetAttribute, inst, key)
      if ok and v ~= nil then return v end
    end
    for _, d in ipairs(inst:GetDescendants()) do
      local ok, v = pcall(d.GetAttribute, d, key)
      if ok and v ~= nil then return v end
    end
    return nil
  end

  local function findShovel()
    local function isShovel(t)
      if not (t and t:IsA("Tool")) then return false end
      local n = tostring((t:GetAttribute("ItemName") or t.Name)):lower():gsub("^%b[]%s*","")
      return n:find("shovel", 1, true) ~= nil
    end
    local ch = LP.Character
    if ch then for _,t in ipairs(ch:GetChildren()) do if isShovel(t) then return t end end end
    local bp = LP:FindFirstChild("Backpack")
    if bp then for _,t in ipairs(bp:GetChildren()) do if isShovel(t) then return t end end end
    local pf = workspace:FindFirstChild("Players"); pf = pf and pf:FindFirstChild(LP.Name)
    if pf then for _,t in ipairs(pf:GetChildren()) do if isShovel(t) then return t end end end
    return nil
  end
  local function ensureEquipped(tool)
    if not tool then return false end
    local ch = LP.Character or LP.CharacterAdded:Wait()
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if hum and tool.Parent ~= ch then pcall(function() hum:EquipTool(tool) end) end
    return tool.Parent == ch
  end
  local function ensureShovelEquipped()
    local sh = findShovel()
    if not sh then return false end
    return ensureEquipped(sh)
  end

  local function partCFrame(inst)
    if not inst then return CFrame.new() end
    if inst:IsA("BasePart") then return inst.CFrame end
    if inst:IsA("Model")   then local ok,cf = pcall(inst.GetPivot, inst); return ok and cf or CFrame.new() end
    return CFrame.new()
  end

  local function grassTiles(plot)
    local out = {}
    local rows = plot and plot:FindFirstChild("Rows")
    if not rows then return out end
    for _,r in ipairs(rows:GetChildren()) do
      local g = r:FindFirstChild("Grass")
      if g then for _,t in ipairs(g:GetChildren()) do out[#out+1]=t end end
    end
    return out
  end
  local function tileIsFree(tile)
    if not tile then return false end
    if tile:GetAttribute("Occupied")==true then return false end
    if tile:FindFirstChild("Plant") or tile:FindFirstChild("Crop") then return false end
    return true
  end
  local function emptyTiles(plot, limit)
    local all = grassTiles(plot)
    local free = {}
    for _,t in ipairs(all) do if tileIsFree(t) then free[#free+1]=t end end
    -- acak ringan biar penyebaran
    local rng = Random.new()
    for i=#free,2,-1 do local j=rng:NextInteger(1,i) free[i],free[j]=free[j],free[i] end
    if limit and #free > limit then
      local cut = {}
      for i=1,limit do cut[i]=free[i] end
      return cut
    end
    return free
  end

  -- ====== Remove (pickup) plant by ID, equip shovel dulu
  local function waitPlantGoneByID(id, timeout)
    local plot = myPlot()
    local plants = plot and plot:FindFirstChild("Plants")
    local tEnd = os.clock() + (timeout or 2.0)
    repeat
      local present = false
      if plants then
        for _,m in ipairs(plants:GetChildren()) do
          local ok,v = pcall(m.GetAttribute,m,"ID")
          if ok and v and tostring(v)==tostring(id) then present=true break end
        end
      end
      if not present then return true end
      task.wait(0.05)
    until os.clock() > tEnd
    return false
  end

  local function tryRemoveByID(id)
    if not id or not RM or not RM.RemoveItem then return false end
    if not ensureShovelEquipped() then return false end
    local function fire(payload)
      local r = RM.RemoveItem
      if r:IsA("RemoteEvent") then pcall(function() r:FireServer(payload) end)
      elseif r:IsA("RemoteFunction") then pcall(function() r:InvokeServer(payload) end)
      elseif r.Fire then pcall(function() r:Fire(payload) end) end
    end
    for _,fmt in ipairs({
      function() return tostring(id) end,
      function() return {ID=tostring(id)} end,
      function() return {id=tostring(id)} end,
      function() return {tostring(id)} end,
    }) do
      fire(fmt()); task.wait(0.06)
      if waitPlantGoneByID(id, 0.45) then return true end
    end
    return false
  end

  local function pickupAllPlantsInPlot()
    local plot = myPlot()
    if not plot then return 0 end
    local plants = plot:FindFirstChild("Plants")
    if not plants then return 0 end
    local count = 0
    ensureShovelEquipped()
    for _,m in ipairs(plants:GetChildren()) do
      if m:IsA("Model") then
        local id = deepAttr(m,"ID")
        if id and tryRemoveByID(id) then
          count = count + 1
          task.wait(0.12)
        end
      end
    end
    return count
  end

  -- ====== Seed scanning & equipping
  local SeedsFolder = S.RS:WaitForChild("Assets"):WaitForChild("Seeds")
  local function currentSeedSet()
    local set = {}
    for _,inst in ipairs(SeedsFolder:GetChildren()) do
      local base = inst.Name:gsub("%s+Seed$","")
      set[base] = true
    end
    return set
  end
  local SEED_NAME_WHITELIST = currentSeedSet()

  local function scanBackpackSeeds()
    local bag = LP:WaitForChild("Backpack")
    local byType, seen = {}, {}
    for _,inst in ipairs(bag:GetDescendants()) do
      local id = inst.GetAttribute and inst:GetAttribute("ID")
      if id and not seen[id] then
        local itemName = (inst.GetAttribute and inst:GetAttribute("ItemName")) or inst.Name
        if itemName and itemName:find("Seed") then
          local plant = itemName:gsub("^%b[]%s*",""):gsub("%s*Seed%s*$","")
          if SEED_NAME_WHITELIST[plant] then
            byType[plant] = byType[plant] or { stacks = {} }
            table.insert(byType[plant].stacks, { id = id, inst = inst, name = plant })
            seen[id] = true
          end
        end
      end
    end
    return byType
  end

  local function waitSeedSeenInWorkspaceByID(id, plantName, timeout)
    local pf = workspace:FindFirstChild("Players"); pf = pf and pf:FindFirstChild(LP.Name)
    if not pf then return false end
    local deadline = os.clock() + (timeout or 1.5)
    repeat
      for _,c in ipairs(pf:GetChildren()) do
        local ok,v = pcall(c.GetAttribute,c,"ID")
        if ok and v ~= nil and tostring(v)==tostring(id) then return true end
      end
      if plantName then
        for _,t in ipairs(pf:GetChildren()) do
          if t:IsA("Tool") and t.Name:find("Seed") and t.Name:find(plantName) then return true end
        end
      end
      task.wait(0.04)
    until os.clock() > deadline
    return false
  end

  local function equipSeedStack(stack)
    if not stack then return false end
    local id, inst = stack.id, stack.inst
    local plantName = stack.name
    local ch = LP.Character or LP.CharacterAdded:Wait()
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if hum and inst and inst.Parent then pcall(function() hum:EquipTool(inst) end) end
    pcall(function()
      if RM.EquipItem:IsA("RemoteEvent") then RM.EquipItem:FireServer({ ID=id, Instance=inst })
      elseif RM.EquipItem:IsA("RemoteFunction") then RM.EquipItem:InvokeServer({ ID=id })
      elseif RM.EquipItem.Fire then RM.EquipItem:Fire(inst or id) end
    end)
    return waitSeedSeenInWorkspaceByID(id, plantName, 1.5)
  end

  local function placeSeedAtTile(stack, tile, plantName)
    local payload = { ID = stack.id, CFrame = partCFrame(tile), Item = plantName, Floor = tile }
    pcall(function() RM.PlaceItem:FireServer(payload) end)
  end

  -- ====== Countdown watcher (grow)
  local function allCountdownsDone()
    local root = workspace:FindFirstChild("ScriptedMap")
    root = root and root:FindFirstChild("Countdowns")
    if not root then return true end -- kalau tidak ada, anggap selesai
    for _,o in ipairs(root:GetChildren()) do
      local v = nil
      if o:IsA("NumberValue") or o:IsA("IntValue") then v = o.Value
      elseif o:IsA("StringValue") then
        local num = tonumber(o.Value); v = num or 0
      else
        v = tonumber(deepAttr(o,"Value")) or tonumber(deepAttr(o,"Time")) or 0
      end
      if v and v > 0 then return false end
    end
    return true
  end
  local function waitUntilAllGrown(timeoutSec)
    local t0 = os.clock()
    while true do
      if allCountdownsDone() then return true end
      if timeoutSec and (os.clock()-t0) > timeoutSec then return false end
      task.wait(0.35)
    end
  end

  local function wait_grow_phase()
    setStatus("Menunggu grow (Countdowns)…")
    local ok = waitUntilAllGrown(900) -- timeout 15 menit (aman)
    if not ok then setInfo("Grow: timeout/partial") else setInfo("Grow: selesai") end
  end

  -- ====== Favorite plants in backpack by weight
  local function parseWeightKGFromAny(t)
    for _,k in ipairs({"Weight","KG","kg","Mass","mass"}) do
      local v = deepAttr(t,k)
      if type(v)=="number" then return v end
      if type(v)=="string" then
        local num = tonumber(v:match("[%d%.]+"))
        if num then return num end
      end
    end
    local name = tostring((t:GetAttribute("ItemName") or t.Name) or "")
    local m = name:lower():match("([%d%.]+)%s*kg")
    if m then return tonumber(m) or 0 end
    return 0
  end
  local function isSeedTool(t)
    local nm = tostring((t:GetAttribute("ItemName") or t.Name) or ""):lower()
    return nm:find("seed",1,true) ~= nil
  end
  local function isPlantTool(t)
    if not (t and t:IsA("Tool")) then return false end
    if isSeedTool(t) then return false end
    if deepAttr(t,"Gear")==true or deepAttr(t,"Brainrot")==true then return false end
    local cat = deepAttr(t,"Category"); if type(cat)=="string" and cat:lower()=="plant" then return true end
    return true
  end
  local function favoriteTool(t, favOn)
    if not (RM and RM.Favorite) then return end
    local id = deepAttr(t,"ID")
    local payload = id and { ID = tostring(id), Favorite = favOn } or { Instance = t, Favorite = favOn }
    if RM.Favorite:IsA("RemoteEvent") then pcall(function() RM.Favorite:FireServer(payload) end)
    elseif RM.Favorite:IsA("RemoteFunction") then pcall(function() RM.Favorite:InvokeServer(payload) end)
    elseif RM.Favorite.Fire then pcall(function() RM.Favorite:Fire(payload) end) end
  end
  local function favoriteBackpackByWeight(thresholdKG)
    local bp = LP:FindFirstChild("Backpack")
    if not bp then return {fav=0,un=0} end
    local fav,un = 0,0
    for _,t in ipairs(bp:GetChildren()) do
      if t:IsA("Tool") and isPlantTool(t) then
        local w = parseWeightKGFromAny(t) or 0
        if w > 0 and w > thresholdKG then
          favoriteTool(t, true); fav = fav + 1
        else
          favoriteTool(t, false); un = un + 1
        end
        task.wait(0.04)
      end
    end
    return {fav=fav, un=un}
  end

  ----------------------------------------------------------------
  -- UI: Seed dropdown + refresh + toggle start
  ----------------------------------------------------------------
  local selectedSeeds = {}
  local ddSeeds = tabGarden:Dropdown({
    Name="Pilih Seed (multi, untuk 35 slot)",
    Options={"(Klik 'Refresh Seeds')"},
    MultiSelection=true, Search=true,
    Callback=function(values)
      if typeof(values)=="table" then selectedSeeds = values
      elseif typeof(values)=="string" then selectedSeeds = {values}
      else selectedSeeds = {} end
    end
  })

  local function uiRefreshSeeds()
    local owned = scanBackpackSeeds()
    local names = {}; for k in pairs(owned) do names[#names+1]=k end
    table.sort(names)
    if #names==0 then names = {"(Tidak ada seed di backpack)"} end
    F.updateDropdown(ddSeeds, names)
    notify("Seeds", ("%d jenis ditemukan"):format((names[1]=="(Tidak ada seed di backpack)" and 0) or #names), 1.2)
  end
  tabGarden:Button({ Name="Refresh Seeds (Backpack)", Callback=uiRefreshSeeds })

  local targetPerCycle = 35
  tabGarden:Input({
    Name="Jumlah tanam per siklus",
    PlaceholderText=tostring(targetPerCycle),
    NumbersOnly=true,
    Flag="auto35_target",
    Callback=function(txt)
      local v = tonumber(txt)
      if v and v>0 then targetPerCycle=v; notify("AutoCycle",("Target set: %d"):format(v),1.0) end
    end
  })

  local weightThresholdKG = 4.0
  tabGarden:Input({
    Name="Ambang Favorite (kg)  (> ambang = di-fav; 0 = jangan fav)",
    PlaceholderText=tostring(weightThresholdKG),
    NumbersOnly=true,
    Flag="fav_threshold",
    Callback=function(txt)
      local v = tonumber(txt)
      if v and v>=0 then weightThresholdKG=v; notify("Favorite","Ambang diset: "..v.."kg",1.0) end
    end
  })

  local running = false
  tabGarden:Toggle({
    Name="klik togle di ->",
    Default=false,
    Flag="auto35_cycle",
    Callback=function(on)
      running = on
      if not on then setStatus("Idle"); return end
      task.spawn(function()
        while running do
          ----------------------------------------------------------
          -- 1) Scan plot & PICKUP ALL (harus shovel)
          ----------------------------------------------------------
          setStatus("Pickup semua plant di plot… (equip shovel)")
          local picked = pickupAllPlantsInPlot()
          setInfo(("Picked: %d"):format(picked))
          task.wait(0.25)

          ----------------------------------------------------------
          -- 2) PLANT (35) dari pilihan dropdown
          ----------------------------------------------------------
          if (not selectedSeeds) or (#selectedSeeds==0) or (#selectedSeeds==1 and selectedSeeds[1]:find("Refresh")) then
            uiRefreshSeeds()
            notify("AutoCycle","Pilih seed dulu di dropdown",1.5)
            setStatus("Menunggu pilihan seed…")
            break
          end

          local plot = myPlot()
          if not plot then setStatus("Plot tidak ditemukan"); break end
          local tiles = emptyTiles(plot, targetPerCycle)

          -- Siapkan order seed dari backpack
          local owned = scanBackpackSeeds()
          local order = {}
          for _,name in ipairs(selectedSeeds) do
            if owned[name] then order[#order+1]=name end
          end

          local skipPlant = false
          if #tiles == 0 then
            setStatus("Tidak ada tile kosong")
            task.wait(0.8)
            skipPlant = true
          elseif #order == 0 then
            setStatus("Stok seed kosong untuk semua pilihan")
            task.wait(0.8)
            skipPlant = true
          end

          local planted = 0
          if not skipPlant then
            local sIdx = {}; for _,n in ipairs(order) do sIdx[n]=1 end
            setStatus(("Menanam %d seed…"):format(#tiles))
            for i=1,#tiles do
              if not running then break end
              local seedName = order[((i-1)%#order)+1]
              local bucket = owned[seedName]
              if bucket and #bucket.stacks>0 then
                local idx = sIdx[seedName]; if idx>#bucket.stacks then idx=1 end
                local stack = bucket.stacks[idx]; sIdx[seedName]=(idx%#bucket.stacks)+1
                if equipSeedStack(stack) then
                  placeSeedAtTile(stack, tiles[i], seedName)
                  planted = planted + 1
                  task.wait(0.10)
                end
              end
            end
          end
          setInfo(("Planted: %d"):format(planted))

          ----------------------------------------------------------
          -- 3) WAIT GROW (monitor workspace.ScriptedMap.Countdowns)
          ----------------------------------------------------------
          wait_grow_phase()

          ----------------------------------------------------------
          -- 4) PICKUP ALL lagi
          ----------------------------------------------------------
          setStatus("Pickup semua plant (panen)…")
          local picked2 = pickupAllPlantsInPlot()
          setInfo(("Picked (after grow): %d"):format(picked2))
          task.wait(0.25)

          ----------------------------------------------------------
          -- 5) FAVORITE di backpack (berat > thresholdKG = fav; <= threshold atau 0 = un-fav)
          ----------------------------------------------------------
          if weightThresholdKG > 0 then
            setStatus(("Favorite by weight (> %.2fkg)…"):format(weightThresholdKG))
            local res = favoriteBackpackByWeight(weightThresholdKG)
            setInfo(("Fav: %d  |  Unfav: %d"):format(res.fav, res.un))
          else
            setStatus("Skip favorite (threshold = 0)")
          end

          ----------------------------------------------------------
          -- 6) Tanam lagi sesuai dropdown (loop)
          ----------------------------------------------------------
          setStatus("Siklus selesai. Ulangi…")
          task.wait(0.6)
        end
      end)
    end
  })
end
