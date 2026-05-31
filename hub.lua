local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

-- Определяем безопасное место для GUI
local TargetGui = LocalPlayer:WaitForChild("PlayerGui")

-- Функция для полной очистки ESP перед удалением хаба
local function clearAllESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then
            local hl = p.Character:FindFirstChild("Ultimate_ESP")
            if hl then hl:Destroy() end
        end
    end
    local gunDrop = workspace:FindFirstChild("GunDrop")
    if gunDrop then
        local hl = gunDrop:FindFirstChild("Gun_Highlight")
        if hl then hl:Destroy() end
    end
end

-- [ИСПРАВЛЕНО] Если запущен второй раз — старый полностью отключается и удаляется
if TargetGui:FindFirstChild("MM2_Ultimate_Hub_V3") then
    clearAllESP() -- Сносим старый ESP
    TargetGui["MM2_Ultimate_Hub_V3"]:Destroy() -- Удаляем старый интерфейс
    task.wait(0.1)
end

-- Создание интерфейса
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2_Ultimate_Hub_V3"
ScreenGui.Parent = TargetGui
ScreenGui.ResetOnSpawn = false

-- УВЕЛИЧЕННЫЙ ФРЕЙМ МЕНЮ (Ширина 330)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.Position = UDim2.new(0.3, 0, 0.15, 0)
MainFrame.Size = UDim2.new(0, 330, 0, 580)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

-- НАСТРОЙКИ: ВСЕ ВЫКЛЮЧЕНО ПО УМОЛЧАНИЮ
local Binds = { HideGui = Enum.KeyCode.RightControl, ToggleFly = Enum.KeyCode.F }
local States = { Murd = false, Sheriff = false, Innocents = false, Gun = false, Aim = false, Fly = false }
local FlySpeed = 50 
local SelectedFlingPlayer, SelectedTpPlayer = nil, nil
local ScriptActive = true -- Флаг работы скрипта

-- [ИСПРАВЛЕНО] КНОПКА ЗАКРЫТИЯ С ПОЛНЫМ ОТКЛЮЧЕНИЕМ ВСЕХ ФУНКЦИЙ
local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = MainFrame
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -34, 0, 10)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 20
CloseBtn.Font = Enum.Font.SourceSansBold

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(1, 0)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    ScriptActive = false -- Останавливаем все циклы
    States.Fly = false   -- Выключаем полет
    States.Aim = false   -- Выключаем аим
    clearAllESP()        -- Чистим карту от подсветки
    ScreenGui:Destroy()  -- Удаляем GUI
end)

-- ПЛАВАЮЩАЯ КНОПКА ДЛЯ ТЕЛЕФОНОВ
local MobileBtn = Instance.new("TextButton")
MobileBtn.Name = "MobileToggle"
MobileBtn.Parent = ScreenGui
MobileBtn.Size = UDim2.new(0, 50, 0, 50)
MobileBtn.Position = UDim2.new(0.02, 0, 0.15, 0)
MobileBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MobileBtn.BackgroundTransparency = 0.2
MobileBtn.Text = "⚔️"
MobileBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MobileBtn.TextSize = 22
MobileBtn.Active = true
MobileBtn.Draggable = true

local MobileCorner = Instance.new("UICorner")
MobileCorner.CornerRadius = UDim.new(1, 0)
MobileCorner.Parent = MobileBtn

MobileBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Заголовок меню
local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Size = UDim2.new(0.7, 0, 0, 44)
Title.Position = UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "MM2 ULTIMATE V3"
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.TextSize = 16
Title.Font = Enum.Font.SourceSansBold
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Скролл-контейнер функций
local MainScroll = Instance.new("ScrollingFrame")
MainScroll.Parent = MainFrame
MainScroll.Size = UDim2.new(1, 0, 1, -50)
MainScroll.Position = UDim2.new(0, 0, 0, 44)
MainScroll.BackgroundTransparency = 1
MainScroll.ScrollBarThickness = 4
MainScroll.CanvasSize = UDim2.new(0, 0, 0, 640)

local function styleButton(btn, text, pos, color, size, parent)
    btn.Parent = parent or MainScroll
    btn.Size = size or UDim2.new(0.92, 0, 0, 32)
    btn.Position = pos
    btn.Text = text
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
end

-- Кнопки ESP и Аима
local ToggleMurd = Instance.new("TextButton")
local ToggleSheriff = Instance.new("TextButton")
local ToggleInnocents = Instance.new("TextButton")
local ToggleGun = Instance.new("TextButton")
local ToggleAim = Instance.new("TextButton")

styleButton(ToggleMurd, "Убийца (Красный) [ВЫКЛ]", UDim2.new(0.04, 0, 0, 5), Color3.fromRGB(50, 50, 50))
styleButton(ToggleSheriff, "Шериф (Синий) [ВЫКЛ]", UDim2.new(0.04, 0, 0, 42), Color3.fromRGB(50, 50, 50))
styleButton(ToggleInnocents, "Мирные (Зеленый) [ВЫКЛ]", UDim2.new(0.04, 0, 0, 79), Color3.fromRGB(50, 50, 50))
styleButton(ToggleGun, "Пистолет на полу [ВЫКЛ]", UDim2.new(0.04, 0, 0, 116), Color3.fromRGB(50, 50, 50))
styleButton(ToggleAim, "Аимбот (ПКМ) [ВЫКЛ]", UDim2.new(0.04, 0, 0, 153), Color3.fromRGB(50, 50, 50))

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Parent = MainScroll 
InfoLabel.Position = UDim2.new(0.04, 0, 0, 190) 
InfoLabel.Size = UDim2.new(0.92, 0, 0, 25) 
InfoLabel.Text = "Сканирование ролей..." 
InfoLabel.TextColor3 = Color3.fromRGB(200, 200, 200) 
InfoLabel.BackgroundTransparency = 1 
InfoLabel.TextSize = 13 
InfoLabel.Font = Enum.Font.SourceSansItalic

local function toggleState(btn, key, text, onColor)
    if not ScriptActive then return end
    States[key] = not States[key]
    btn.Text = text .. (States[key] and " [ВКЛ]" or " [ВЫКЛ]")
    btn.BackgroundColor3 = States[key] and onColor or Color3.fromRGB(50, 50, 50)
end
ToggleMurd.MouseButton1Click:Connect(function() toggleState(ToggleMurd, "Murd", "Убийца (Красный)", Color3.fromRGB(150, 30, 30)) end)
ToggleSheriff.MouseButton1Click:Connect(function() toggleState(ToggleSheriff, "Sheriff", "Шериф (Синий)", Color3.fromRGB(30, 60, 150)) end)
ToggleInnocents.MouseButton1Click:Connect(function() toggleState(ToggleInnocents, "Innocents", "Мирные (Зеленый)", Color3.fromRGB(30, 120, 50)) end)
ToggleGun.MouseButton1Click:Connect(function() toggleState(ToggleGun, "Gun", "Пистолет на полу", Color3.fromRGB(130, 110, 20)) end)
ToggleAim.MouseButton1Click:Connect(function() toggleState(ToggleAim, "Aim", "Аимбот (ПКМ)", Color3.fromRGB(100, 45, 130)) end)

-- Блок НАСТРАИВАЕМОГО ПОЛЁТА
local LineMove = Instance.new("Frame")
LineMove.Parent = MainScroll 
LineMove.Size = UDim2.new(0.92, 0, 0, 1) 
LineMove.Position = UDim2.new(0.04, 0, 0, 225) 
LineMove.BackgroundColor3 = Color3.fromRGB(50, 50, 55) 
LineMove.BorderSizePixel = 0

local FlyStatus = Instance.new("TextLabel")
FlyStatus.Parent = MainScroll 
FlyStatus.Size = UDim2.new(0.5, 0, 0, 32) 
FlyStatus.Position = UDim2.new(0.04, 0, 0, 235) 
FlyStatus.Text = "Полёт: ВЫКЛ" 
FlyStatus.TextColor3 = Color3.fromRGB(200,200,200) 
FlyStatus.BackgroundTransparency = 1 
FlyStatus.Font = Enum.Font.SourceSansBold 
FlyStatus.TextSize = 14
FlyStatus.TextXAlignment = Enum.TextXAlignment.Left

local BindFlyBtn = Instance.new("TextButton") 
styleButton(BindFlyBtn, "Бинд: F", UDim2.new(0.56, 0, 0, 235), Color3.fromRGB(45, 45, 50), UDim2.new(0.4, 0, 0, 32))

local FlySpeedLabel = Instance.new("TextLabel")
FlySpeedLabel.Parent = MainScroll 
FlySpeedLabel.Size = UDim2.new(0.5, 0, 0, 32) 
FlySpeedLabel.Position = UDim2.new(0.04, 0, 0, 272) 
FlySpeedLabel.Text = "Скорость флая: 50" 
FlySpeedLabel.TextColor3 = Color3.fromRGB(200,200,200) 
FlySpeedLabel.BackgroundTransparency = 1 
FlySpeedLabel.Font = Enum.Font.SourceSansBold 
FlySpeedLabel.TextSize = 14
FlySpeedLabel.TextXAlignment = Enum.TextXAlignment.Left

local SpeedMinus = Instance.new("TextButton") 
styleButton(SpeedMinus, "-", UDim2.new(0.56, 0, 0, 272), Color3.fromRGB(55, 55, 60), UDim2.new(0.18, 0, 0, 32))
local SpeedPlus = Instance.new("TextButton") 
styleButton(SpeedPlus, "+", UDim2.new(0.78, 0, 0, 272), Color3.fromRGB(55, 55, 60), UDim2.new(0.18, 0, 0, 32))

SpeedMinus.MouseButton1Click:Connect(function() FlySpeed = math.max(20, FlySpeed - 10) FlySpeedLabel.Text = "Скорость флая: " .. FlySpeed end)
SpeedPlus.MouseButton1Click:Connect(function() FlySpeed = math.min(150, FlySpeed + 10) FlySpeedLabel.Text = "Скорость флая: " .. FlySpeed end)

-- Блок Флинга
local LineFling = Instance.new("Frame")
LineFling.Parent = MainScroll 
LineFling.Size = UDim2.new(0.92, 0, 0, 1) 
LineFling.Position = UDim2.new(0.04, 0, 0, 315) 
LineFling.BackgroundColor3 = Color3.fromRGB(50, 50, 55) 
LineFling.BorderSizePixel = 0

local FlingSelectBtn = Instance.new("TextButton") 
styleButton(FlingSelectBtn, "🎯 Выбрать цель для флинга", UDim2.new(0.04, 0, 0, 325), Color3.fromRGB(35, 35, 40))
local FlingButton = Instance.new("TextButton") 
styleButton(FlingButton, "УНИЧТОЖИТЬ ЦЕЛЬ", UDim2.new(0.04, 0, 0, 362), Color3.fromRGB(180, 35, 35))

-- Блок Телепортации
local LineTp = Instance.new("Frame")
LineTp.Parent = MainScroll 
LineTp.Size = UDim2.new(0.92, 0, 0, 1) 
LineTp.Position = UDim2.new(0.04, 0, 0, 405) 
LineTp.BackgroundColor3 = Color3.fromRGB(50, 50, 55) 
LineTp.BorderSizePixel = 0

local TpSelectBtn = Instance.new("TextButton") 
styleButton(TpSelectBtn, "👤 Выбрать игрока для ТП", UDim2.new(0.04, 0, 0, 415), Color3.fromRGB(35, 35, 40))
local TpButton = Instance.new("TextButton") 
styleButton(TpButton, "ТЕЛЕПОРТИРОВАТЬСЯ", UDim2.new(0.04, 0, 0, 452), Color3.fromRGB(35, 120, 150))

-- Блок Вейпоинтов
local LineWP = Instance.new("Frame")
LineWP.Parent = MainScroll 
LineWP.Size = UDim2.new(0.92, 0, 0, 1) 
LineWP.Position = UDim2.new(0.04, 0, 0, 495) 
LineWP.BackgroundColor3 = Color3.fromRGB(50, 50, 55) 
LineWP.BorderSizePixel = 0

local WPInput = Instance.new("TextBox")
WPInput.Parent = MainScroll 
WPInput.Size = UDim2.new(0.92, 0, 0, 32) 
WPInput.Position = UDim2.new(0.04, 0, 0, 505) 
WPInput.BackgroundColor3 = Color3.fromRGB(35, 35, 40) 
WPInput.TextColor3 = Color3.fromRGB(255, 255, 255) 
WPInput.PlaceholderText = "Название точки..." 
WPInput.Text = ""
WPInput.Font = Enum.Font.SourceSans 
WPInput.TextSize = 14
local WPiC = Instance.new("UICorner") WPiC.CornerRadius = UDim.new(0, 6) WPiC.Parent = WPInput

local WPAddBtn = Instance.new("TextButton") 
styleButton(WPAddBtn, "+ Создать вейпоинт", UDim2.new(0.04, 0, 0, 542), Color3.fromRGB(45, 110, 65))

local WPScroll = Instance.new("ScrollingFrame")
WPScroll.Parent = MainScroll 
WPScroll.Size = UDim2.new(0.92, 0, 0, 85) 
WPScroll.Position = UDim2.new(0.04, 0, 0, 580) 
WPScroll.BackgroundTransparency = 1 
WPScroll.CanvasSize = UDim2.new(0, 0, 0, 0) 
WPScroll.ScrollBarThickness = 3

local WPListLayout = Instance.new("UIListLayout")
WPListLayout.Padding = UDim.new(0, 4)
WPListLayout.Parent = WPScroll

-- ============================================================================
-- [ОКНО ВЫБОРА ИГРОКОВ (DROP-DOWN LIST)]
-- ============================================================================
local DropdownGui = Instance.new("Frame")
DropdownGui.Parent = ScreenGui
DropdownGui.Size = UDim2.new(0, 240, 0, 220)
DropdownGui.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
DropdownGui.BorderSizePixel = 1
DropdownGui.BorderColor3 = Color3.fromRGB(60, 60, 70)
DropdownGui.Visible = false
local DdCorner = Instance.new("UICorner") DdCorner.CornerRadius = UDim.new(0, 8) DdCorner.Parent = DropdownGui

local DropdownTitle = Instance.new("TextLabel")
DropdownTitle.Parent = DropdownGui
DropdownTitle.Size = UDim2.new(1, 0, 0, 25) 
DropdownTitle.Text = "  Выберите цель:" 
DropdownTitle.TextColor3 = Color3.fromRGB(200, 200, 200) 
DropdownTitle.Font = Enum.Font.SourceSansBold 
DropdownTitle.BackgroundTransparency = 1 
DropdownTitle.TextSize = 13 
DropdownTitle.TextXAlignment = Enum.TextXAlignment.Left

local DropdownScroll = Instance.new("ScrollingFrame")
DropdownScroll.Parent = DropdownGui
DropdownScroll.Size = UDim2.new(1, -10, 1, -30) 
DropdownScroll.Position = UDim2.new(0, 5, 0, 25) 
DropdownScroll.BackgroundTransparency = 1 
DropdownScroll.ScrollBarThickness = 4

local DropdownList = Instance.new("UIListLayout")
DropdownList.Padding = UDim.new(0, 4)
DropdownList.Parent = DropdownScroll

local currentDropdownMode = ""
local function openDropdown(mode, buttonTrigger)
    if not ScriptActive then return end
    currentDropdownMode = mode 
    DropdownGui.Position = UDim2.new(0, buttonTrigger.AbsolutePosition.X, 0, buttonTrigger.AbsolutePosition.Y + buttonTrigger.AbsoluteSize.Y + 5)
    
    for _, item in pairs(DropdownScroll:GetChildren()) do 
        if item:IsA("TextButton") then item:Destroy() end 
    end
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local pBtn = Instance.new("TextButton")
            pBtn.Parent = DropdownScroll
            pBtn.Size = UDim2.new(0.95, 0, 0, 26) 
            pBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50) 
            pBtn.Text = p.DisplayName .. " (@" .. p.Name .. ")" 
            pBtn.TextColor3 = Color3.fromRGB(255, 255, 255) 
            pBtn.Font = Enum.Font.SourceSans 
            pBtn.TextSize = 13 
            local pbc = Instance.new("UICorner") pbc.CornerRadius = UDim.new(0, 4) pbc.Parent = pBtn
            
            pBtn.MouseButton1Click:Connect(function()
                if currentDropdownMode == "Fling" then 
                    SelectedFlingPlayer = p 
                    FlingSelectBtn.Text = "🎯: " .. p.DisplayName
                elseif currentDropdownMode == "TP" then 
                    SelectedTpPlayer = p 
                    TpSelectBtn.Text = "👤: " .. p.DisplayName 
                end
                DropdownGui.Visible = false
            end)
        end
    end
    DropdownScroll.CanvasSize = UDim2.new(0, 0, 0, DropdownList.AbsoluteContentSize.Y + 5) 
    DropdownGui.Visible = true
end
FlingSelectBtn.MouseButton1Click:Connect(function() openDropdown("Fling", FlingSelectBtn) end)
TpSelectBtn.MouseButton1Click:Connect(function() openDropdown("TP", TpSelectBtn) end)

-- ============================================================================
-- [ПОЛЁТ (CFRAME FLY)]
-- ============================================================================
local Camera = workspace.CurrentCamera
RunService.Heartbeat:Connect(function(dt)
    if not ScriptActive or not States.Fly then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    root.Velocity = Vector3.new(0,0,0)
    
    local direction = Vector3.new(0,0,0)
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction = direction + Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction = direction - Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction = direction - Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction = direction + Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction = direction + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then direction = direction - Vector3.new(0, 1, 0) end
    
    if direction.Magnitude > 0 then
        root.CFrame = CFrame.new(root.Position + (direction.Unit * FlySpeed * dt), root.Position + Camera.CFrame.LookVector)
    end
end)

-- ============================================================================
-- [РАБОЧИЙ ESP С УСЛОВИЕМ АКТИВНОСТИ]
-- ============================================================================
local function updateESP(character, color, enabled)
    if not ScriptActive or not character then return end
    local hl = character:FindFirstChild("Ultimate_ESP")
    if not enabled then if hl then hl:Destroy() end return end
    
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "Ultimate_ESP"
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.4
        hl.Parent = character
    end
    hl.FillColor = color
end

RunService.Heartbeat:Connect(function()
    if not ScriptActive then return end
    
    local Murderer, Sheriff = nil, nil
    for _, p in pairs(Players:GetPlayers()) do
        local bp = p:FindFirstChild("Backpack") 
        local char = p.Character
        if (bp and bp:FindFirstChild("Knife")) or (char and char:FindFirstChild("Knife")) then Murderer = p end
        if (bp and bp:FindFirstChild("Gun")) or (char and char:FindFirstChild("Gun")) then Sheriff = p end
    end
    InfoLabel.Text = "⚔️ Убийца: " .. (Murderer and Murderer.DisplayName or "Неизвестен") .. "  |  ⭐ Шериф: " .. (Sheriff and Sheriff.DisplayName or "Неизвестен")

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if p == Murderer then updateESP(p.Character, Color3.fromRGB(255, 0, 0), States.Murd)
            elseif p == Sheriff then updateESP(p.Character, Color3.fromRGB(0, 0, 255), States.Sheriff)
            else updateESP(p.Character, Color3.fromRGB(0, 255, 0), States.Innocents) end
        end
    end
    
    local gunDrop = workspace:FindFirstChild("GunDrop")
    if gunDrop and gunDrop:IsA("BasePart") then
        local hl = gunDrop:FindFirstChild("Gun_Highlight")
        if States.Gun then 
            if not hl then 
                hl = Instance.new("Highlight") 
                hl.Name = "Gun_Highlight" 
                hl.FillColor = Color3.fromRGB(255, 230, 0)
                hl.Parent = gunDrop
            end 
        else 
            if hl then hl:Destroy() end 
        end
    end
end)

-- ============================================================================
-- ЛОГИКА ТП, ФЛИНГА И ХРАНЕНИЯ ТОЧЕК
-- ============================================================================
TpButton.MouseButton1Click:Connect(function()
    if not ScriptActive then return end
    if SelectedTpPlayer and SelectedTpPlayer.Character and SelectedTpPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if myRoot then myRoot.CFrame = SelectedTpPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 2, 0) end
    end
end)

FlingButton.MouseButton1Click:Connect(function()
    if not ScriptActive then return end
    local char = LocalPlayer.Character local root = char and char:FindFirstChild("HumanoidRootPart") local hum = char and char:FindFirstChild("Humanoid")
    if not root or hum.Health <= 0 or not SelectedFlingPlayer or not SelectedFlingPlayer.Character or not SelectedFlingPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local targetHRP = SelectedFlingPlayer.Character.HumanoidRootPart local originalCFrame = root.CFrame
    local bAV = Instance.new("BodyAngularVelocity", root) bAV.MaxTorque = Vector3.new(math.huge,math.huge,math.huge) bAV.AngularVelocity = Vector3.new(0, 999999, 0)
    local bV = Instance.new("BodyVelocity", root) bV.MaxForce = Vector3.new(math.huge,math.huge,math.huge) bV.Velocity = Vector3.new(0, 0, 0)
    hum.Sit = true local startTime = tick() local loop
    loop = RunService.Heartbeat:Connect(function()
        if not ScriptActive or tick() - startTime > 2.0 or not targetHRP.Parent or (SelectedFlingPlayer.Character:FindFirstChild("Humanoid") and SelectedFlingPlayer.Character.Humanoid.Health <= 0) then
            loop:Disconnect() bAV:Destroy() bV:Destroy() root.Velocity, root.RotVelocity = Vector3.new(0,0,0), Vector3.new(0,0,0) root.CFrame = originalCFrame hum.Sit = false return
        end
        for _, part in pairs(char:GetChildren()) do if part:IsA("BasePart") then part.CanCollide = false part.Velocity = Vector3.new(999,999,999) end end
        root.CFrame = targetHRP.CFrame * CFrame.new(math.sin(tick() * 50) * 1.2, 0, math.cos(tick() * 50) * 1.2)
    end)
end)

local Waypoints = {} local FileName = "mm2_waypoints.txt"
local function saveWaypointsToPC() if writefile then local rawData = {} for name, pos in pairs(Waypoints) do rawData[name] = {pos.X, pos.Y, pos.Z} end pcall(function() writefile(FileName, HttpService:JSONEncode(rawData)) end) end end
local function loadWaypointsFromPC() if readfile and isfile and isfile(FileName) then local success, content = pcall(function() return readfile(FileName) end) if success and content then local success2, decoded = pcall(function() return HttpService:JSONDecode(content) end) if success2 and type(decoded) == "table" then for name, coords in pairs(decoded) do Waypoints[name] = Vector3.new(coords[1], coords[2], coords[3]) end end end end end

local function updateWPScroll() WPScroll.CanvasSize = UDim2.new(0, 0, 0, WPListLayout.AbsoluteContentSize.Y + 5) end
local function renderWaypoints()
    for _, c in pairs(WPScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    for name, pos in pairs(Waypoints) do
        local ItemFrame = Instance.new("Frame")
        ItemFrame.Parent = WPScroll
        ItemFrame.Size = UDim2.new(0.95, 0, 0, 28) 
        ItemFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45) 
        local ifc = Instance.new("UICorner") ifc.CornerRadius = UDim.new(0, 5) ifc.Parent = ItemFrame
        
        local TeleportBtn = Instance.new("TextButton")
        TeleportBtn.Parent = ItemFrame
        TeleportBtn.Size = UDim2.new(0.8, 0, 1, 0) 
        TeleportBtn.BackgroundTransparency = 1 
        TeleportBtn.Text = "  📍 " .. name 
        TeleportBtn.TextColor3 = Color3.fromRGB(220, 220, 220) 
        TeleportBtn.TextSize = 13 
        TeleportBtn.TextXAlignment = Enum.TextXAlignment.Left
        
        local DelBtn = Instance.new("TextButton")
        DelBtn.Parent = ItemFrame
        DelBtn.Size = UDim2.new(0.2, 0, 1, 0) 
        DelBtn.Position = UDim2.new(0.8, 0, 0, 0) 
        DelBtn.BackgroundTransparency = 1 
        DelBtn.Text = "×" 
        DelBtn.TextColor3 = Color3.fromRGB(200, 80, 80)
        DelBtn.TextSize = 16
        
        TeleportBtn.MouseButton1Click:Connect(function() if ScriptActive and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos) end end)
        DelBtn.MouseButton1Click:Connect(function() if ScriptActive then Waypoints[name] = nil ItemFrame:Destroy() saveWaypointsToPC() task.wait(0.05) updateWPScroll() end end)
    end
    updateWPScroll()
end
WPAddBtn.MouseButton1Click:Connect(function()
    if not ScriptActive then return end
    local text = WPInput.Text:gsub("^%s*(.-)%s*$", "%1") local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if text ~= "" and hrp then Waypoints[text] = hrp.Position WPInput.Text = "" saveWaypointsToPC() renderWaypoints() end
end)
WPListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateWPScroll)
loadWaypointsFromPC() renderWaypoints()

-- Система Биндов
local ListeningForBind = nil
local function listenForNewBind(actionName, button) ListeningForBind = actionName button.Text = "[Кликни клавишу]" button.BackgroundColor3 = Color3.fromRGB(100, 80, 30) end
BindFlyBtn.MouseButton1Click:Connect(function() listenForNewBind("ToggleFly", BindFlyBtn) end)

UserInputService.InputBegan:Connect(function(input, processed)
    if not ScriptActive then return end
    if ListeningForBind and input.UserInputType == Enum.UserInputType.Keyboard then
        Binds[ListeningForBind] = input.KeyCode
        local btn = BindFlyBtn
        btn.Text = "Бинд: " .. input.KeyCode.Name
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50) ListeningForBind = nil return
    end
    if processed then return end
    if input.KeyCode == Binds.ToggleFly then States.Fly = not States.Fly FlyStatus.Text = States.Fly and "Полёт: ВКЛ" or "Полёт: ВЫКЛ" FlyStatus.TextColor3 = States.Fly and Color3.fromRGB(45, 200, 85) or Color3.fromRGB(200, 200, 200) end
end)

-- Аимбот
local Mouse = LocalPlayer:GetMouse() local Aiming = false local Smoothness, MaxFovRadius = 0.22, 300
UserInputService.InputBegan:Connect(function(i, p) if not p and i.UserInputType == Enum.UserInputType.MouseButton2 and States.Aim then Aiming = true end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then Aiming = false end end)
RunService.RenderStepped:Connect(function()
    if ScriptActive and States.Aim and Aiming and LocalPlayer.Character then
        local closest, shortest = nil, MaxFovRadius
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                local head = p.Character:FindFirstChild("Head")
                if head then
                    local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                    if onScreen and dist < shortest then shortest = dist closest = p end
                end
            end
        end
        local tPart = closest and closest.Character and closest.Character:FindFirstChild("Head")
        if tPart then Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, tPart.Position), Smoothness) end
    end
end)
