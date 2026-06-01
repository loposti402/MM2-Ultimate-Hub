local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

-- Определяем безопасное место для GUI
local TargetGui = LocalPlayer:WaitForChild("PlayerGui")

-- Папка для хранения ников вне персонажей (для оптимизации и плавности)
local EspFolder = TargetGui:FindFirstChild("MM2_EspContainer") or Instance.new("Folder")
EspFolder.Name = "MM2_EspContainer"
EspFolder.Parent = TargetGui

-- Функция для полной очистки ESP и ников перед удалением хаба
local function clearAllESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then
            local hl = p.Character:FindFirstChild("Ultimate_ESP")
            if hl then hl:Destroy() end
        end
    end
    EspFolder:ClearAllChildren()
end

-- Перезапуск скрипта при повторном инжекте
if TargetGui:FindFirstChild("mm2_hub") then
    clearAllESP()
    TargetGui["mm2_hub"]:Destroy()
    task.wait(0.1)
end

-- Создание интерфейса
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "mm2_hub"
ScreenGui.Parent = TargetGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.Position = UDim2.new(0.3, 0, 0.15, 0)
MainFrame.Size = UDim2.new(0, 340, 0, 550)
MainFrame.Active = true
MainFrame.Draggable = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

-- === ИЗМЕНЕНИЕ РАЗМЕРА ХАБА ===
local ResizeBtn = Instance.new("ImageButton")
ResizeBtn.Name = "ResizeBtn"
ResizeBtn.Parent = MainFrame
ResizeBtn.Size = UDim2.new(0, 16, 0, 16)
ResizeBtn.Position = UDim2.new(1, -16, 1, -16)
ResizeBtn.BackgroundTransparency = 1
ResizeBtn.Image = "rbxassetid://6031302940"
ResizeBtn.ImageColor3 = Color3.fromRGB(100, 100, 110)

local resizing = false
local StartSize, StartInputPos

ResizeBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        StartSize = MainFrame.Size
        StartInputPos = input.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then resizing = false end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - StartInputPos
        local newWidth = math.clamp(StartSize.X.Offset + delta.X, 280, 600)
        local newHeight = math.clamp(StartSize.Y.Offset + delta.Y, 400, 900)
        MainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
    end
end)

-- НАСТРОЙКИ ПО УМОЛЧАНИЮ И СОСТОЯНИЯ
local Binds = { HideGui = Enum.KeyCode.RightControl, ToggleFly = Enum.KeyCode.F, KillSheriff = nil, KillInnocents = nil, Aim = nil }
local States = { Murd = false, Sheriff = false, Innocents = false, Aim = false, Fly = false, NoClipInFly = false }
local FlySpeed = 50 
local SelectedFlingPlayer, SelectedTpPlayer, SelectedSpecPlayer = nil, nil, nil
local ScriptActive = true 
local ListeningForBind = nil
local TargetWpBindName = nil
local IsSpectating = false

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

local FlyVelocity = nil
local FlyGyro = nil
local Camera = workspace.CurrentCamera

local function stopFlying()
    States.Fly = false
    if FlyVelocity then FlyVelocity:Destroy() FlyVelocity = nil end
    if FlyGyro then FlyGyro:Destroy() FlyGyro = nil end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if hum then hum.PlatformStand = false end
end

CloseBtn.MouseButton1Click:Connect(function()
    ScriptActive = false
    stopFlying()
    States.Aim = false
    States.NoClipInFly = false
    IsSpectating = false
    Camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    local char = LocalPlayer.Character
    if char then
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
    clearAllESP()
    ScreenGui:Destroy()
    EspFolder:Destroy()
end)

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Size = UDim2.new(0.5, 0, 0, 44)
Title.Position = UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "MM2 HUB V3.3 OPTIMIZED"
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.TextSize = 16
Title.Font = Enum.Font.SourceSansBold
Title.TextXAlignment = Enum.TextXAlignment.Left

local BindHideBtn = Instance.new("TextButton")
BindHideBtn.Parent = MainFrame
BindHideBtn.Size = UDim2.new(0, 75, 0, 24)
BindHideBtn.Position = UDim2.new(1, -115, 0, 10)
BindHideBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
BindHideBtn.Text = "Бинд: RCtrl"
BindHideBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
BindHideBtn.Font = Enum.Font.SourceSansBold
BindHideBtn.TextSize = 11
local Bhc = Instance.new("UICorner") Bhc.CornerRadius = UDim.new(0, 4) Bhc.Parent = BindHideBtn

BindHideBtn.MouseButton1Click:Connect(function()
    ListeningForBind = "HideGui"
    BindHideBtn.Text = "Нажми..."
end)

local MainScroll = Instance.new("ScrollingFrame")
MainScroll.Parent = MainFrame
MainScroll.Size = UDim2.new(1, 0, 1, -50)
MainScroll.Position = UDim2.new(0, 0, 0, 44)
MainScroll.BackgroundTransparency = 1
MainScroll.ScrollBarThickness = 4
MainScroll.CanvasSize = UDim2.new(0, 0, 0, 1300)

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

-- Кнопки ESP
local ToggleMurd = Instance.new("TextButton")
local ToggleSheriff = Instance.new("TextButton")
local ToggleInnocents = Instance.new("TextButton")
local ToggleAim = Instance.new("TextButton")

styleButton(ToggleMurd, "Убийца (Красный) [ВЫКЛ]", UDim2.new(0.04, 0, 0, 10), Color3.fromRGB(50, 50, 50))
styleButton(ToggleSheriff, "Шериф (Синий) [ВЫКЛ]", UDim2.new(0.04, 0, 0, 47), Color3.fromRGB(50, 50, 50))
styleButton(ToggleInnocents, "Мирные (Зеленый) [ВЫКЛ]", UDim2.new(0.04, 0, 0, 84), Color3.fromRGB(50, 50, 50))
styleButton(ToggleAim, "Аимбот (ПКМ) [ВЫКЛ]", UDim2.new(0.04, 0, 0, 121), Color3.fromRGB(50, 50, 50))

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Parent = MainScroll InfoLabel.Position = UDim2.new(0.04, 0, 0, 158) InfoLabel.Size = UDim2.new(0.92, 0, 0, 25) InfoLabel.Text = "Сканирование ролей..." InfoLabel.TextColor3 = Color3.fromRGB(200, 200, 200) InfoLabel.BackgroundTransparency = 1 InfoLabel.TextSize = 13 InfoLabel.Font = Enum.Font.SourceSansItalic

local function toggleState(btn, key, text, onColor)
    if not ScriptActive then return end
    States[key] = not States[key]
    btn.Text = text .. (States[key] and " [ВКЛ]" or " [ВЫКЛ]")
    btn.BackgroundColor3 = States[key] and onColor or Color3.fromRGB(50, 50, 50)
end
ToggleMurd.MouseButton1Click:Connect(function() toggleState(ToggleMurd, "Murd", "Убийца (Красный)", Color3.fromRGB(150, 30, 30)) end)
ToggleSheriff.MouseButton1Click:Connect(function() toggleState(ToggleSheriff, "Sheriff", "Шериф (Синий)", Color3.fromRGB(30, 60, 150)) end)
ToggleInnocents.MouseButton1Click:Connect(function() toggleState(ToggleInnocents, "Innocents", "Мирные (Зеленый)", Color3.fromRGB(30, 120, 50)) end)
ToggleAim.MouseButton1Click:Connect(function() toggleState(ToggleAim, "Aim", "Аимбот (ПКМ)", Color3.fromRGB(100, 45, 130)) end)

-- Полёт
local LineMove = Instance.new("Frame")
LineMove.Parent = MainScroll LineMove.Size = UDim2.new(0.92, 0, 0, 1) LineMove.Position = UDim2.new(0.04, 0, 0, 195) LineMove.BackgroundColor3 = Color3.fromRGB(50, 50, 55) LineMove.BorderSizePixel = 0

local FlyStatus = Instance.new("TextLabel")
FlyStatus.Parent = MainScroll FlyStatus.Size = UDim2.new(0.5, 0, 0, 32) FlyStatus.Position = UDim2.new(0.04, 0, 0, 205) FlyStatus.Text = "Полёт: ВЫКЛ" FlyStatus.TextColor3 = Color3.fromRGB(200,200,200) FlyStatus.BackgroundTransparency = 1 FlyStatus.Font = Enum.Font.SourceSansBold FlyStatus.TextSize = 14 FlyStatus.TextXAlignment = Enum.TextXAlignment.Left

local BindFlyBtn = Instance.new("TextButton") 
styleButton(BindFlyBtn, "Бинд: F", UDim2.new(0.56, 0, 0, 205), Color3.fromRGB(45, 45, 50), UDim2.new(0.4, 0, 0, 32))
BindFlyBtn.MouseButton1Click:Connect(function() ListeningForBind = "ToggleFly" BindFlyBtn.Text = "Нажми..." end)

local FlySpeedInput = Instance.new("TextBox")
FlySpeedInput.Parent = MainScroll FlySpeedInput.Size = UDim2.new(0.92, 0, 0, 32) FlySpeedInput.Position = UDim2.new(0.04, 0, 0, 242) FlySpeedInput.BackgroundColor3 = Color3.fromRGB(35, 35, 40) FlySpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255) FlySpeedInput.Font = Enum.Font.SourceSansBold FlySpeedInput.TextSize = 14 FlySpeedInput.Text = "50" FlySpeedInput.PlaceholderText = "Введите скорость полёта..."
local Fsic = Instance.new("UICorner") Fsic.CornerRadius = UDim.new(0, 6) Fsic.Parent = FlySpeedInput

FlySpeedInput.FocusLost:Connect(function(enterPressed)
    local val = tonumber(FlySpeedInput.Text)
    if val then FlySpeed = math.clamp(val, 1, 500) FlySpeedInput.Text = tostring(FlySpeed) else FlySpeedInput.Text = tostring(FlySpeed) end
end)

local ToggleNoClipFly = Instance.new("TextButton")
styleButton(ToggleNoClipFly, "Ноуклип в флае [ВЫКЛ]", UDim2.new(0.04, 0, 0, 280), Color3.fromRGB(50, 50, 50))

local function toggleFlyLogic()
    if not ScriptActive then return end
    if States.Fly then
        stopFlying()
        FlyStatus.Text = "Полёт: ВЫКЛ" FlyStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
    else
        States.Fly = true
        FlyStatus.Text = "Полёт: ВКЛ" FlyStatus.TextColor3 = Color3.fromRGB(45, 200, 85)
    end
end

ToggleNoClipFly.MouseButton1Click:Connect(function()
    if not ScriptActive then return end
    States.NoClipInFly = not States.NoClipInFly
    ToggleNoClipFly.Text = "Ноуклип в флае " .. (States.NoClipInFly and "[ВКЛ]" or "[ВЫКЛ]")
    ToggleNoClipFly.BackgroundColor3 = States.NoClipInFly and Color3.fromRGB(45, 110, 85) or Color3.fromRGB(50, 50, 50)
    if not States.NoClipInFly and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetChildren()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
end)

-- Секция Флинга
local LineFling = Instance.new("Frame")
LineFling.Parent = MainScroll LineFling.Size = UDim2.new(0.92, 0, 0, 1) LineFling.Position = UDim2.new(0.04, 0, 0, 327) LineFling.BackgroundColor3 = Color3.fromRGB(50, 50, 55) LineFling.BorderSizePixel = 0

local FlingSelectBtn = Instance.new("TextButton") 
styleButton(FlingSelectBtn, "🎯 Выбрать цель для флинга", UDim2.new(0.04, 0, 0, 337), Color3.fromRGB(35, 35, 40))
local FlingButton = Instance.new("TextButton") 
styleButton(FlingButton, "УНИЧТОЖИТЬ ЦЕЛЬ", UDim2.new(0.04, 0, 0, 374), Color3.fromRGB(180, 35, 35))

local FlingMurdButton = Instance.new("TextButton")
styleButton(FlingMurdButton, "🔥 УНИЧТОЖИТЬ МАРДЕРА", UDim2.new(0.04, 0, 0, 411), Color3.fromRGB(210, 80, 20))

-- Телепортация
local LineTp = Instance.new("Frame")
LineTp.Parent = MainScroll LineTp.Size = UDim2.new(0.92, 0, 0, 1) LineTp.Position = UDim2.new(0.04, 0, 0, 454) LineTp.BackgroundColor3 = Color3.fromRGB(50, 50, 55)

local TpSelectBtn = Instance.new("TextButton") 
styleButton(TpSelectBtn, "👤 Выбрать игрока для ТП", UDim2.new(0.04, 0, 0, 464), Color3.fromRGB(35, 35, 40))
local TpButton = Instance.new("TextButton") 
styleButton(TpButton, "ТЕЛЕПОРТИРОВАТЬСЯ", UDim2.new(0.04, 0, 0, 501), Color3.fromRGB(35, 120, 150))

-- Слежение (Spectate)
local LineSpec = Instance.new("Frame")
LineSpec.Parent = MainScroll LineSpec.Size = UDim2.new(0.92, 0, 0, 1) LineSpec.Position = UDim2.new(0.04, 0, 0, 544) LineSpec.BackgroundColor3 = Color3.fromRGB(50, 50, 55) LineSpec.BorderSizePixel = 0

local SpecSelectBtn = Instance.new("TextButton")
styleButton(SpecSelectBtn, "👁️ Выбрать игрока для слежки", UDim2.new(0.04, 0, 0, 554), Color3.fromRGB(35, 35, 40))
local SpecButton = Instance.new("TextButton")
styleButton(SpecButton, "НАЧАТЬ СЛЕДИТЬ", UDim2.new(0.04, 0, 0, 591), Color3.fromRGB(110, 85, 35))

-- Кнопки преследования
local LineFastBinds = Instance.new("Frame")
LineFastBinds.Parent = MainScroll LineFastBinds.Size = UDim2.new(0.92, 0, 0, 1) LineFastBinds.Position = UDim2.new(0.04, 0, 0, 634) LineFastBinds.BackgroundColor3 = Color3.fromRGB(50, 50, 55) LineFastBinds.BorderSizePixel = 0

local FastKillSBtn = Instance.new("TextButton") styleButton(FastKillSBtn, "🔪 Преследовать Шерифа", UDim2.new(0.04, 0, 0, 644), Color3.fromRGB(40, 80, 180))
local FastKillIBtn = Instance.new("TextButton") styleButton(FastKillIBtn, "🔪 Преследовать Мирного", UDim2.new(0.04, 0, 0, 681), Color3.fromRGB(40, 150, 80))

function getPlayerStatus(p)
    if not p or not p.Parent then return "НЕТ В ИГРЕ", Color3.fromRGB(120,120,120) end
    local char = p.Character
    local hum = char and char:FindFirstChild("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if not char or not hum or hum.Health <= 0 or not root then
        return "МЕРТВ", Color3.fromRGB(150, 100, 100)
    end
    
    local bp = p:FindFirstChild("Backpack")
    local hasKnife = (bp and bp:FindFirstChild("Knife")) or (char and char:FindFirstChild("Knife"))
    local hasGun = (bp and bp:FindFirstChild("Gun")) or (char and char:FindFirstChild("Gun"))
    
    if hasKnife then return "УБИЙЦА", Color3.fromRGB(255, 50, 50) end
    if hasGun then return "ШЕРИФ", Color3.fromRGB(50, 100, 255) end
    
    local isInLobbyZone = false
    local lobbyWorkspace = workspace:FindFirstChild("Lobby")
    
    if lobbyWorkspace then
        local lobbySpawns = lobbyWorkspace:FindFirstChild("Spawns") or lobbyWorkspace
        local primary = lobbySpawns:FindFirstChildWhichIsA("BasePart", true)
        if primary and (root.Position - primary.Position).Magnitude < 130 then
            isInLobbyZone = true
        end
    else
        if math.abs(root.Position.X) < 150 and math.abs(root.Position.Z) < 150 then
            isInLobbyZone = true
        end
    end
    
    if isInLobbyZone then return "В ЛОББИ", Color3.fromRGB(200, 180, 110) end
    return "МИРНЫЙ", Color3.fromRGB(100, 200, 100)
end

local function findActiveInGamePlayer(roleName)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local role, _ = getPlayerStatus(p)
            if role == roleName then return p end
        end
    end
    return nil
end

local function chaseAndKill(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    local targetHum = targetPlayer.Character:FindFirstChild("Humanoid")
    if not myRoot or not targetRoot or (targetHum and targetHum.Health <= 0) then return end
    
    local knife = LocalPlayer.Backpack:FindFirstChild("Knife") or myChar:FindFirstChild("Knife")
    if not knife then return end
    
    local originalCFrame = myRoot.CFrame
    knife.Parent = myChar
    
    local tween = TweenService:Create(myRoot, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {
        CFrame = targetRoot.CFrame * CFrame.new(0, 0, 1.0)
    })
    tween:Play()
    tween.Completed:Wait()
    
    for i = 1, 3 do
        if targetRoot and targetRoot.Parent then
            myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 0.8)
            knife:Activate()
            task.wait(0.1)
        end
    end
    
    task.wait(0.05)
    myRoot.CFrame = originalCFrame
end

local function actionKillSheriff() local t = findActiveInGamePlayer("ШЕРИФ") if t then chaseAndKill(t) end end
local function actionKillInnocents() local t = findActiveInGamePlayer("МИРНЫЙ") if t then chaseAndKill(t) end end

FastKillSBtn.MouseButton1Click:Connect(actionKillSheriff)
FastKillIBtn.MouseButton1Click:Connect(actionKillInnocents)

local BindKillSBtn = Instance.new("TextButton") styleButton(BindKillSBtn, "Бинд Шерифа: [НЕТ]", UDim2.new(0.04, 0, 0, 718), Color3.fromRGB(35, 35, 40))
local BindKillIBtn = Instance.new("TextButton") styleButton(BindKillIBtn, "Бинд Мирных: [НЕТ]", UDim2.new(0.04, 0, 0, 755), Color3.fromRGB(35, 35, 40))

BindKillSBtn.MouseButton1Click:Connect(function() ListeningForBind = "KillSheriff" BindKillSBtn.Text = "Нажми..." end)
BindKillIBtn.MouseButton1Click:Connect(function() ListeningForBind = "KillInnocents" BindKillIBtn.Text = "Нажми..." end)

-- Вейпоинты
local LineWP = Instance.new("Frame")
LineWP.Parent = MainScroll LineWP.Size = UDim2.new(0.92, 0, 0, 1) LineWP.Position = UDim2.new(0.04, 0, 0, 799) LineWP.BackgroundColor3 = Color3.fromRGB(50, 50, 55) LineWP.BorderSizePixel = 0

local WPInput = Instance.new("TextBox")
WPInput.Parent = MainScroll WPInput.Size = UDim2.new(0.92, 0, 0, 32) WPInput.Position = UDim2.new(0.04, 0, 0, 809) WPInput.BackgroundColor3 = Color3.fromRGB(35, 35, 40) WPInput.TextColor3 = Color3.fromRGB(255, 255, 255) WPInput.PlaceholderText = "Название точки..."
WPInput.Text = "" WPInput.Font = Enum.Font.SourceSans WPInput.TextSize = 14
local WPiC = Instance.new("UICorner") WPiC.CornerRadius = UDim.new(0, 6) WPiC.Parent = WPInput

local WPAddBtn = Instance.new("TextButton") 
styleButton(WPAddBtn, "+ Создать вейпоинт", UDim2.new(0.04, 0, 0, 846), Color3.fromRGB(45, 110, 65))

local WPScroll = Instance.new("ScrollingFrame")
WPScroll.Parent = MainScroll WPScroll.Size = UDim2.new(0.92, 0, 0, 85) WPScroll.Position = UDim2.new(0.04, 0, 0, 884) WPScroll.BackgroundTransparency = 1 WPScroll.CanvasSize = UDim2.new(0, 0, 0, 0) WPScroll.ScrollBarThickness = 3

local WPListLayout = Instance.new("UIListLayout")
WPListLayout.Padding = UDim.new(0, 4)
WPListLayout.Parent = WPScroll

-- Списки игроков (Dropdown)
local DropdownGui = Instance.new("Frame")
DropdownGui.Parent = ScreenGui
DropdownGui.Size = UDim2.new(0, 260, 0, 220)
DropdownGui.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
DropdownGui.BorderSizePixel = 1
DropdownGui.BorderColor3 = Color3.fromRGB(60, 60, 70)
DropdownGui.Visible = false
local DdCorner = Instance.new("UICorner") DdCorner.CornerRadius = UDim.new(0, 8) DdCorner.Parent = DropdownGui

local DropdownTitle = Instance.new("TextLabel")
DropdownTitle.Parent = DropdownGui DropdownTitle.Size = UDim2.new(1, -30, 0, 30) DropdownTitle.Text = "    Выберите цель:" DropdownTitle.TextColor3 = Color3.fromRGB(200, 200, 200) DropdownTitle.Font = Enum.Font.SourceSansBold DropdownTitle.BackgroundTransparency = 1 DropdownTitle.TextSize = 13 DropdownTitle.TextXAlignment = Enum.TextXAlignment.Left

local DropdownClose = Instance.new("TextButton")
DropdownClose.Parent = DropdownGui DropdownClose.Size = UDim2.new(0, 20, 0, 20) DropdownClose.Position = UDim2.new(1, -25, 0, 5) DropdownClose.BackgroundColor3 = Color3.fromRGB(60, 30, 30) DropdownClose.Text = "×" DropdownClose.TextColor3 = Color3.fromRGB(255, 100, 100) DropdownClose.Font = Enum.Font.SourceSansBold DropdownClose.TextSize = 16
local DdcCorner = Instance.new("UICorner") DdcCorner.CornerRadius = UDim.new(1, 0) DdcCorner.Parent = DropdownClose
DropdownClose.MouseButton1Click:Connect(function() DropdownGui.Visible = false end)

local DropdownScroll = Instance.new("ScrollingFrame")
DropdownScroll.Parent = DropdownGui DropdownScroll.Size = UDim2.new(1, -10, 1, -35) DropdownScroll.Position = UDim2.new(0, 5, 0, 30) DropdownScroll.BackgroundTransparency = 1 DropdownScroll.ScrollBarThickness = 4

local DropdownList = Instance.new("UIListLayout")
DropdownList.Padding = UDim.new(0, 4)
DropdownList.Parent = DropdownScroll

local currentDropdownMode = ""
local function openDropdown(mode, buttonTrigger)
    if not ScriptActive then return end
    if DropdownGui.Visible and currentDropdownMode == mode then DropdownGui.Visible = false return end
    
    currentDropdownMode = mode 
    DropdownGui.Position = UDim2.new(0, buttonTrigger.AbsolutePosition.X, 0, buttonTrigger.AbsolutePosition.Y + buttonTrigger.AbsoluteSize.Y + 5)
    for _, item in pairs(DropdownScroll:GetChildren()) do if item:IsA("TextButton") then item:Destroy() end end
    
    local sortedPlayers = Players:GetPlayers()
    table.sort(sortedPlayers, function(a, b)
        local statusA = getPlayerStatus(a)
        local statusB = getPlayerStatus(b)
        local scoreA = (statusA == "УБИЙЦА" or statusA == "ШЕРИФ") and 3 or (statusA == "МИРНЫЙ" and 2) or (statusA == "В ЛОББИ" and 1) or 0
        local scoreB = (statusB == "УБИЙЦА" or statusB == "ШЕРИФ") and 3 or (statusB == "МИРНЫЙ" and 2) or (statusB == "В ЛОББИ" and 1) or 0
        if scoreA ~= scoreB then return scoreA > scoreB end
        return a.Name < b.Name
    end)
    
    for _, p in pairs(sortedPlayers) do
        if p ~= LocalPlayer then
            local roleText, roleColor = getPlayerStatus(p)
            local pBtn = Instance.new("TextButton")
            pBtn.Parent = DropdownScroll
            pBtn.Size = UDim2.new(0.95, 0, 0, 28) 
            pBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50) 
            pBtn.Text = " " .. p.DisplayName .. " [" .. roleText .. "]"
            pBtn.TextColor3 = roleColor
            pBtn.Font = Enum.Font.SourceSansBold 
            pBtn.TextSize = 13 
            pBtn.TextXAlignment = Enum.TextXAlignment.Left
            local pbc = Instance.new("UICorner") pbc.CornerRadius = UDim.new(0, 4) pbc.Parent = pBtn
            
            pBtn.MouseButton1Click:Connect(function()
                if currentDropdownMode == "Fling" then SelectedFlingPlayer = p FlingSelectBtn.Text = "🎯: " .. p.DisplayName
                elseif currentDropdownMode == "TP" then SelectedTpPlayer = p TpSelectBtn.Text = "👤: " .. p.DisplayName 
                elseif currentDropdownMode == "Spec" then SelectedSpecPlayer = p SpecSelectBtn.Text = "👁️: " .. p.DisplayName end
                DropdownGui.Visible = false
            end)
        end
    end
    DropdownScroll.CanvasSize = UDim2.new(0, 0, 0, DropdownList.AbsoluteContentSize.Y + 5) 
    DropdownGui.Visible = true
end
FlingSelectBtn.MouseButton1Click:Connect(function() openDropdown("Fling", FlingSelectBtn) end)
TpSelectBtn.MouseButton1Click:Connect(function() openDropdown("TP", TpSelectBtn) end)
SpecSelectBtn.MouseButton1Click:Connect(function() openDropdown("Spec", SpecSelectBtn) end)

-- Слежение логика
SpecButton.MouseButton1Click:Connect(function()
    if not ScriptActive then return end
    if IsSpectating then
        IsSpectating = false
        SpecButton.Text = "НАЧАТЬ СЛЕДИТЬ"
        SpecButton.BackgroundColor3 = Color3.fromRGB(110, 85, 35)
        local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if myHum then Camera.CameraSubject = myHum end
    else
        if SelectedSpecPlayer and SelectedSpecPlayer.Character and SelectedSpecPlayer.Character:FindFirstChild("Humanoid") then
            IsSpectating = true
            SpecButton.Text = "ОТПУСТИТЬ КАМЕРУ"
            SpecButton.BackgroundColor3 = Color3.fromRGB(35, 110, 65)
            Camera.CameraSubject = SelectedSpecPlayer.Character.Humanoid
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if ScriptActive and IsSpectating then
        if not SelectedSpecPlayer or not SelectedSpecPlayer.Parent or not SelectedSpecPlayer.Character or not SelectedSpecPlayer.Character:FindFirstChild("Humanoid") or SelectedSpecPlayer.Character.Humanoid.Health <= 0 then
            IsSpectating = false
            SpecButton.Text = "НАЧАТЬ СЛЕДИТЬ"
            SpecButton.BackgroundColor3 = Color3.fromRGB(110, 85, 35)
            local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if myHum then Camera.CameraSubject = myHum end
        else
            if Camera.CameraSubject ~= SelectedSpecPlayer.Character.Humanoid then Camera.CameraSubject = SelectedSpecPlayer.Character.Humanoid end
        end
    end
end)

-- Полёт логика
RunService.RenderStepped:Connect(function()
    if not ScriptActive or not States.Fly then return end
    local char = LocalPlayer.Character local root = char and char:FindFirstChild("HumanoidRootPart") local hum = char and char:FindFirstChild("Humanoid")
    if not root or not hum then return end
    
    hum.PlatformStand = true
    if States.NoClipInFly then for _, part in pairs(char:GetChildren()) do if part:IsA("BasePart") then part.CanCollide = false end end end
    
    if not FlyVelocity then
        FlyVelocity = Instance.new("BodyVelocity")
        FlyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        FlyVelocity.Parent = root
    end
    if not FlyGyro then
        FlyGyro = Instance.new("BodyGyro")
        FlyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        FlyGyro.D = 100 FlyGyro.P = 10000
        FlyGyro.Parent = root
    end
    FlyGyro.CFrame = Camera.CFrame
    
    local moveDir = Vector3.new(0,0,0)
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end
    if moveDir.Magnitude > 0 then FlyVelocity.Velocity = moveDir.Unit * FlySpeed else FlyVelocity.Velocity = Vector3.new(0,0,0) end
end)

-- === ПЛАВНАЯ И ВЫСОКООПТИМИЗИРОВАННАЯ СИСТЕМА ESP ===
local function updateESP(playerInstance, character, color, enabled)
    if not ScriptActive then return end
    
    -- 1. Обработка Highlight (внутри персонажа)
    local hl = character:FindFirstChild("Ultimate_ESP")
    if not enabled then 
        if hl then hl:Destroy() end 
    else
        if not hl then 
            hl = Instance.new("Highlight") 
            hl.Name = "Ultimate_ESP" 
            hl.OutlineColor = Color3.fromRGB(255, 255, 255) 
            hl.FillTransparency = 0.4 
            hl.Parent = character 
        end
        hl.FillColor = color
    end

    -- 2. Обработка ников (Вне персонажа, во внешней папке)
    local nameGuiName = "NameGui_" .. playerInstance.Name
    local nameGui = EspFolder:FindFirstChild(nameGuiName)
    
    local head = character:FindFirstChild("Head")
    if not enabled or not head or not character:FindFirstChild("HumanoidRootPart") then 
        if nameGui then nameGui:Destroy() end 
        return 
    end

    if not nameGui then
        nameGui = Instance.new("BillboardGui")
        nameGui.Name = nameGuiName
        nameGui.AlwaysOnTop = true
        nameGui.Size = UDim2.new(0, 180, 0, 40)
        nameGui.MaxDistance = 450 -- Ограничение дистанции рендера ников спасает FPS
        nameGui.Parent = EspFolder

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.Parent = nameGui
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.SourceSansBold
        nameLabel.TextSize = 13
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    end

    -- Прямая привязка Adornee (без пересоздания) гарантирует нулевой делей движения
    if nameGui.Adornee ~= head then
        nameGui.Adornee = head
    end

    local roleText, _ = getPlayerStatus(playerInstance)
    local displayName = playerInstance.DisplayName or playerInstance.Name
    
    -- Сравниваем старый текст, чтобы лишний раз не обновлять свойства (сильно снижает лаги)
    local targetText = displayName .. " [" .. roleText .. "]"
    if nameGui.NameLabel.Text ~= targetText then
        nameGui.NameLabel.Text = targetText
        nameGui.NameLabel.TextColor3 = color
    end
end

-- Основной поток рендеринга (Синхронизирован с частотой кадров дисплея)
RunService.RenderStepped:Connect(function()
    if not ScriptActive then return end
    
    -- Чистим ники вышедших игроков
    for _, gui in pairs(EspFolder:GetChildren()) do
        local pName = string.sub(gui.Name, 9)
        local p = Players:FindFirstChild(pName)
        if not p or not p.Character or not p.Character:FindFirstChild("Head") then
            gui:Destroy()
        end
    end

    -- Обновляем данные для каждого активного игрока
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local role, _ = getPlayerStatus(p)
            if role == "УБИЙЦА" then 
                updateESP(p, p.Character, Color3.fromRGB(255, 50, 50), States.Murd)
            elseif role == "ШЕРИФ" then 
                updateESP(p, p.Character, Color3.fromRGB(50, 100, 255), States.Sheriff)
            else 
                updateESP(p, p.Character, Color3.fromRGB(100, 200, 100), States.Innocents) 
            end
        end
    end
end)

-- Легкий фоновый цикл только для текста инфо-панели (чтобы не грузить рендер)
task.spawn(function()
    while ScriptActive do
        local Murderer, Sheriff = nil, nil
        for _, p in pairs(Players:GetPlayers()) do
            local role, _ = getPlayerStatus(p)
            if role == "УБИЙЦА" then Murderer = p elseif role == "ШЕРИФ" then Sheriff = p end
        end
        InfoLabel.Text = "⚔️ Убийца: " .. (Murderer and Murderer.DisplayName or "Неизвестен") .. "  |  ⭐ Шериф: " .. (Sheriff and Sheriff.DisplayName or "Неизвестен")
        task.wait(0.5)
    end
end)

TpButton.MouseButton1Click:Connect(function()
    if not ScriptActive then return end
    if SelectedTpPlayer and SelectedTpPlayer.Character and SelectedTpPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if myRoot then myRoot.CFrame = SelectedTpPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 2, 0) end
    end
end)

-- === УЛЬТИМАТИВНЫЙ БЕЗОПАСНЫЙ ФЛИНГ С ПОЛНЫМ ГАШЕНИЕМ ИНЕРЦИИ ===
local function runFlingLogic(targetPlayer)
    if not ScriptActive or not targetPlayer or not targetPlayer.Character then return end
    
    local char = LocalPlayer.Character 
    local root = char and char:FindFirstChild("HumanoidRootPart") 
    local hum = char and char:FindFirstChild("Humanoid")
    local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    local targetHum = targetPlayer.Character:FindFirstChild("Humanoid")
    
    if not root or hum.Health <= 0 or not targetHRP or (targetHum and targetHum.Health <= 0) then return end
    
    local originalCFrame = root.CFrame
    
    local noclipLoop = RunService.Stepped:Connect(function()
        if char then
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end)
    
    local bAV = Instance.new("BodyAngularVelocity") 
    bAV.MaxTorque = Vector3.new(0, math.huge, 0) 
    bAV.AngularVelocity = Vector3.new(0, 95000, 0)
    bAV.Parent = root
    
    local bV = Instance.new("BodyVelocity")
    bV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bV.Velocity = Vector3.new(0, 0, 0)
    bV.Parent = root
    
    hum.Sit = true 
    local startTime = tick() 
    local flingLoop
    
    flingLoop = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        
        if not ScriptActive or elapsed > 0.5 or not targetHRP.Parent or (targetHum and targetHum.Health <= 0) then
            flingLoop:Disconnect() 
            noclipLoop:Disconnect()
            bAV:Destroy() 
            bV:Destroy()
            
            root.Velocity = Vector3.new(0,0,0)
            root.RotVelocity = Vector3.new(0,0,0)
            hum.PlatformStand = true 
            
            root.Anchored = true
            
            -- Буфер гашения скорости на 15 кадров
            for i = 1, 15 do
                root.CFrame = originalCFrame
                root.Velocity = Vector3.new(0,0,0)
                root.RotVelocity = Vector3.new(0,0,0)
                RunService.Heartbeat:Wait()
            end
            
            root.Anchored = false
            hum.PlatformStand = false
            hum.Sit = false
            
            if char then
                for _, part in pairs(char:GetChildren()) do
                    if part:IsA("BasePart") then part.CanCollide = true end
                end
            end
            return
        end
        
        local targetVelocity = targetHRP.Velocity
        local leadPosition = targetHRP.Position + (targetVelocity * 0.05)
        
        root.CFrame = CFrame.new(leadPosition)
        root.Velocity = Vector3.new(targetVelocity.X * 1.3, 0, targetVelocity.Z * 1.3)
    end)
end

FlingButton.MouseButton1Click:Connect(function() if SelectedFlingPlayer then runFlingLogic(SelectedFlingPlayer) end end)
FlingMurdButton.MouseButton1Click:Connect(function() local tm = findActiveInGamePlayer("УБИЙЦА") if tm then runFlingLogic(tm) end end)

-- Система вейпоинтов
local Waypoints = {} 
local WpBinds = {} 
local FileName = "mm2_waypoints_v3.txt"

local function saveWaypointsToPC() 
    if writefile then 
        local rawData = {} 
        for name, cf in pairs(Waypoints) do 
            local bindName = WpBinds[name] and WpBinds[name].Name or "None"
            local x, y, z = cf:ToEulerAnglesXYZ()
            rawData[name] = {cf.X, cf.Y, cf.Z, x, y, z, bindName} 
        end 
        pcall(function() writefile(FileName, HttpService:JSONEncode(rawData)) end) 
    end 
end

local function loadWaypointsFromPC() 
    if readfile and isfile and isfile(FileName) then 
        local success, content = pcall(function() return readfile(FileName) end) 
        if success and content then 
            local success2, decoded = pcall(function() return HttpService:JSONDecode(content) end) 
            if success2 and type(decoded) == "table" then 
                for name, data in pairs(decoded) do 
                    Waypoints[name] = CFrame.new(data[1], data[2], data[3]) * CFrame.Angles(data[4], data[5], data[6])
                    if data[7] and data[7] ~= "None" then pcall(function() WpBinds[name] = Enum.KeyCode[data[7]] end) end
                end 
            end 
        end 
    end 
end

local function updateWPScroll() WPScroll.CanvasSize = UDim2.new(0, 0, 0, WPListLayout.AbsoluteContentSize.Y + 5) end

local function renderWaypoints()
    for _, c in pairs(WPScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    for name, cf in pairs(Waypoints) do
        local ItemFrame = Instance.new("Frame")
        ItemFrame.Parent = WPScroll ItemFrame.Size = UDim2.new(0.95, 0, 0, 30) ItemFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45) 
        local ifc = Instance.new("UICorner") ifc.CornerRadius = UDim.new(0, 5) ifc.Parent = ItemFrame
        
        local TeleportBtn = Instance.new("TextButton")
        TeleportBtn.Parent = ItemFrame TeleportBtn.Size = UDim2.new(0.42, 0, 1, 0) TeleportBtn.BackgroundTransparency = 1 TeleportBtn.Text = " 📍 " .. name TeleportBtn.TextColor3 = Color3.fromRGB(220, 220, 220) TeleportBtn.TextSize = 12 TeleportBtn.TextXAlignment = Enum.TextXAlignment.Left
        
        local WpBindBtn = Instance.new("TextButton")
        WpBindBtn.Parent = ItemFrame WpBindBtn.Size = UDim2.new(0.24, 0, 1, -6) WpBindBtn.Position = UDim2.new(0.42, 0, 0, 3) WpBindBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 60) WpBindBtn.Text = WpBinds[name] and WpBinds[name].Name or "[Задать]" WpBindBtn.TextColor3 = Color3.fromRGB(200, 200, 200) WpBindBtn.Font = Enum.Font.SourceSansBold WpBindBtn.TextSize = 10
        local Wpbc = Instance.new("UICorner") Wpbc.CornerRadius = UDim.new(0, 4) Wpbc.Parent = WpBindBtn
        
        local ResetBindBtn = Instance.new("TextButton")
        ResetBindBtn.Parent = ItemFrame ResetBindBtn.Size = UDim2.new(0, 24, 1, -6) ResetBindBtn.Position = UDim2.new(0.67, 2, 0, 3) ResetBindBtn.BackgroundColor3 = Color3.fromRGB(70, 50, 50) ResetBindBtn.Text = "🔄" ResetBindBtn.TextColor3 = Color3.fromRGB(255, 255, 255) ResetBindBtn.TextSize = 11
        local Rbbc = Instance.new("UICorner") Rbbc.CornerRadius = UDim.new(0, 4) Rbbc.Parent = ResetBindBtn

        local DelBtn = Instance.new("TextButton")
        DelBtn.Parent = ItemFrame DelBtn.Size = UDim2.new(0.2, -4, 1, 0) DelBtn.Position = UDim2.new(0.8, 4, 0, 0) DelBtn.BackgroundTransparency = 1 DelBtn.Text = "×" DelBtn.TextColor3 = Color3.fromRGB(200, 80, 80) DelBtn.TextSize = 16
        
        TeleportBtn.MouseButton1Click:Connect(function() 
            if ScriptActive and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.CFrame = cf end 
        end)
        
        WpBindBtn.MouseButton1Click:Connect(function() TargetWpBindName = name ListeningForBind = "Waypoint" WpBindBtn.Text = "..." end)
        ResetBindBtn.MouseButton1Click:Connect(function() WpBinds[name] = nil saveWaypointsToPC() renderWaypoints() end)
        DelBtn.MouseButton1Click:Connect(function() Waypoints[name] = nil WpBinds[name] = nil saveWaypointsToPC() renderWaypoints() end)
    end
    updateWPScroll()
end

WPAddBtn.MouseButton1Click:Connect(function()
    local text = WPInput.Text
    if text ~= "" and not Waypoints[text] and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        Waypoints[text] = LocalPlayer.Character.HumanoidRootPart.CFrame
        WPInput.Text = "" saveWaypointsToPC() renderWaypoints()
    end
end)

-- ГЛОБАЛЬНЫЙ СКАНЕР БИНДОВ И КЛАВИАТУРЫ
UserInputService.InputBegan:Connect(function(input, gpe)
    if not ScriptActive then return end
    
    if ListeningForBind then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if ListeningForBind == "HideGui" then Binds.HideGui = input.KeyCode BindHideBtn.Text = "Бинд: " .. input.KeyCode.Name
            elseif ListeningForBind == "ToggleFly" then Binds.ToggleFly = input.KeyCode BindFlyBtn.Text = "Бинд: " .. input.KeyCode.Name
            elseif ListeningForBind == "KillSheriff" then Binds.KillSheriff = input.KeyCode BindKillSBtn.Text = "Бинд Шерифа: [" .. input.KeyCode.Name .. "]"
            elseif ListeningForBind == "KillInnocents" then Binds.KillInnocents = input.KeyCode BindKillIBtn.Text = "Бинд Мирных: [" .. input.KeyCode.Name .. "]"
            elseif ListeningForBind == "Waypoint" and TargetWpBindName then WpBinds[TargetWpBindName] = input.KeyCode TargetWpBindName = nil saveWaypointsToPC() renderWaypoints() end
            ListeningForBind = nil
        end
        return
    end
    
    if gpe then return end
    
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Binds.HideGui then MainFrame.Visible = not MainFrame.Visible
        elseif input.KeyCode == Binds.ToggleFly then toggleFlyLogic()
        elseif Binds.KillSheriff and input.KeyCode == Binds.KillSheriff then actionKillSheriff()
        elseif Binds.KillInnocents and input.KeyCode == Binds.KillInnocents then actionKillInnocents()
        else
            for name, key in pairs(WpBinds) do
                if key == input.KeyCode and Waypoints[name] and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = Waypoints[name]
                    break
                end
            end
        end
    end
end)

-- АИМБОТ
RunService.RenderStepped:Connect(function()
    if not ScriptActive or not States.Aim or not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
    local currentTarget = findActiveInGamePlayer("УБИЙЦА")
    if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("HumanoidRootPart") then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, currentTarget.Character.HumanoidRootPart.Position)
    end
end)

-- МОБИЛЬНАЯ КНОПКА
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
if isMobile then
    local MobileBtn = Instance.new("TextButton")
    MobileBtn.Name = "MobileToggle"
    MobileBtn.Parent = ScreenGui
    MobileBtn.Size = UDim2.new(0, 50, 0, 50)
    MobileBtn.Position = UDim2.new(0, 10, 0, 150)
    MobileBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    MobileBtn.Text = "МЕНЮ"
    MobileBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MobileBtn.TextSize = 12
    MobileBtn.Font = Enum.Font.SourceSansBold
    MobileBtn.Draggable = true
    MobileBtn.Active = true
    local MobCorner = Instance.new("UICorner") MobCorner.CornerRadius = UDim.new(0, 8) MobCorner.Parent = MobileBtn
    MobileBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)
end

pcall(loadWaypointsFromPC)
pcall(renderWaypoints)
