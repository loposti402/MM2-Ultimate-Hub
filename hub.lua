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
MainFrame.Size = UDim2.new(0, 330, 0, 580) -- Немного увеличил размер под новые кнопки
MainFrame.Active = true
MainFrame.Draggable = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

-- НАСТРОЙКИ ПО УМОЛЧАНИЮ
local Binds = { HideGui = Enum.KeyCode.RightControl, ToggleFly = Enum.KeyCode.F }
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

-- Переменные для контроля плавного полета
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
end)

-- ПЛАВАЮЩАЯ КНОПКА СВЕРТЫВАНИЯ
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

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Size = UDim2.new(0.5, 0, 0, 44)
Title.Position = UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "MM2 HUB V3"
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.TextSize = 16
Title.Font = Enum.Font.SourceSansBold
Title.TextXAlignment = Enum.TextXAlignment.Left

-- НАСТРАИВАЕМЫЙ БИНД СКРЫТИЯ МЕНЮ
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

local MainScroll = Instance.new("ScrollingFrame")
MainScroll.Parent = MainFrame
MainScroll.Size = UDim2.new(1, 0, 1, -50)
MainScroll.Position = UDim2.new(0, 0, 0, 44)
MainScroll.BackgroundTransparency = 1
MainScroll.ScrollBarThickness = 4
MainScroll.CanvasSize = UDim2.new(0, 0, 0, 800) -- Увеличил прокрутку под спектатор

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

-- Кнопки ESP и функций
local ToggleMurd = Instance.new("TextButton")
local ToggleSheriff = Instance.new("TextButton")
local ToggleInnocents = Instance.new("TextButton")
local ToggleAim = Instance.new("TextButton")

styleButton(ToggleMurd, "Убийца (Красный) [ВЫКЛ]", UDim2.new(0.04, 0, 0, 5), Color3.fromRGB(50, 50, 50))
styleButton(ToggleSheriff, "Шериф (Синий) [ВЫКЛ]", UDim2.new(0.04, 0, 0, 42), Color3.fromRGB(50, 50, 50))
styleButton(ToggleInnocents, "Мирные (Зеленый) [ВЫКЛ]", UDim2.new(0.04, 0, 0, 79), Color3.fromRGB(50, 50, 50))
styleButton(ToggleAim, "Аимбот (ПКМ) [ВЫКЛ]", UDim2.new(0.04, 0, 0, 116), Color3.fromRGB(50, 50, 50))

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Parent = MainScroll InfoLabel.Position = UDim2.new(0.04, 0, 0, 153) InfoLabel.Size = UDim2.new(0.92, 0, 0, 25) InfoLabel.Text = "Сканирование ролей..." InfoLabel.TextColor3 = Color3.fromRGB(200, 200, 200) InfoLabel.BackgroundTransparency = 1 InfoLabel.TextSize = 13 InfoLabel.Font = Enum.Font.SourceSansItalic

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

-- Настройки полёта
local LineMove = Instance.new("Frame")
LineMove.Parent = MainScroll LineMove.Size = UDim2.new(0.92, 0, 0, 1) LineMove.Position = UDim2.new(0.04, 0, 0, 185) LineMove.BackgroundColor3 = Color3.fromRGB(50, 50, 55) LineMove.BorderSizePixel = 0

local FlyStatus = Instance.new("TextLabel")
FlyStatus.Parent = MainScroll FlyStatus.Size = UDim2.new(0.5, 0, 0, 32) FlyStatus.Position = UDim2.new(0.04, 0, 0, 195) FlyStatus.Text = "Полёт: ВЫКЛ" FlyStatus.TextColor3 = Color3.fromRGB(200,200,200) FlyStatus.BackgroundTransparency = 1 FlyStatus.Font = Enum.Font.SourceSansBold FlyStatus.TextSize = 14 FlyStatus.TextXAlignment = Enum.TextXAlignment.Left

local BindFlyBtn = Instance.new("TextButton") 
styleButton(BindFlyBtn, "Бинд: F", UDim2.new(0.56, 0, 0, 195), Color3.fromRGB(45, 45, 50), UDim2.new(0.4, 0, 0, 32))

-- МОБИЛЬНАЯ КНОПКА ДЛЯ ПОЛЁТА
local MobileFlyTouchBtn = Instance.new("TextButton")
styleButton(MobileFlyTouchBtn, "[ ВКЛ / ВЫКЛ ПОЛЁТ ]", UDim2.new(0.04, 0, 0, 232), Color3.fromRGB(60, 60, 65))

local function updateFlyVisuals()
    FlyStatus.Text = States.Fly and "Полёт: ВКЛ" or "Полёт: ВЫКЛ" 
    FlyStatus.TextColor3 = States.Fly and Color3.fromRGB(45, 200, 85) or Color3.fromRGB(200, 200, 200)
    MobileFlyTouchBtn.BackgroundColor3 = States.Fly and Color3.fromRGB(45, 130, 75) or Color3.fromRGB(60, 60, 65)
end

MobileFlyTouchBtn.MouseButton1Click:Connect(function()
    if not ScriptActive then return end
    if States.Fly then stopFlying() else States.Fly = true end
    updateFlyVisuals()
end)

-- Поле скорости полёта
local FlySpeedInput = Instance.new("TextBox")
FlySpeedInput.Parent = MainScroll
FlySpeedInput.Size = UDim2.new(0.92, 0, 0, 32)
FlySpeedInput.Position = UDim2.new(0.04, 0, 0, 270)
FlySpeedInput.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
FlySpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
FlySpeedInput.Font = Enum.Font.SourceSansBold
FlySpeedInput.TextSize = 14
FlySpeedInput.Text = "50"
FlySpeedInput.PlaceholderText = "Введите скорость полёта..."
local Fsic = Instance.new("UICorner") Fsic.CornerRadius = UDim.new(0, 6) Fsic.Parent = FlySpeedInput

FlySpeedInput.FocusLost:Connect(function(enterPressed)
    local val = tonumber(FlySpeedInput.Text)
    if val then
        FlySpeed = math.clamp(val, 1, 500)
        FlySpeedInput.Text = tostring(FlySpeed)
    else
        FlySpeedInput.Text = tostring(FlySpeed)
    end
end)

local ToggleNoClipFly = Instance.new("TextButton")
styleButton(ToggleNoClipFly, "Ноуклип в флае [ВЫКЛ]", UDim2.new(0.04, 0, 0, 308), Color3.fromRGB(50, 50, 50))

ToggleNoClipFly.MouseButton1Click:Connect(function()
    if not ScriptActive then return end
    States.NoClipInFly = not States.NoClipInFly
    ToggleNoClipFly.Text = "Ноуклип в флае " .. (States.NoClipInFly and "[ВКЛ]" or "[ВЫКЛ]")
    ToggleNoClipFly.BackgroundColor3 = States.NoClipInFly and Color3.fromRGB(45, 110, 85) or Color3.fromRGB(50, 50, 50)
    if not States.NoClipInFly and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetChildren()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- Флинг
local LineFling = Instance.new("Frame")
LineFling.Parent = MainScroll LineFling.Size = UDim2.new(0.92, 0, 0, 1) LineFling.Position = UDim2.new(0.04, 0, 0, 355) LineFling.BackgroundColor3 = Color3.fromRGB(50, 50, 55) LineFling.BorderSizePixel = 0

local FlingSelectBtn = Instance.new("TextButton") 
styleButton(FlingSelectBtn, "🎯 Выбрать цель для флинга", UDim2.new(0.04, 0, 0, 365), Color3.fromRGB(35, 35, 40))
local FlingButton = Instance.new("TextButton") 
styleButton(FlingButton, "УНИЧТОЖИТЬ ЦЕЛЬ", UDim2.new(0.04, 0, 0, 402), Color3.fromRGB(180, 35, 35))

-- Телепортация
local LineTp = Instance.new("Frame")
LineTp.Parent = MainScroll LineTp.Size = UDim2.new(0.92, 0, 0, 1) LineTp.Position = UDim2.new(0.04, 0, 0, 445) LineTp.BackgroundColor3 = Color3.fromRGB(50, 50, 55) LineTp.BorderSizePixel = 0

local TpSelectBtn = Instance.new("TextButton") 
styleButton(TpSelectBtn, "👤 Выбрать игрока для ТП", UDim2.new(0.04, 0, 0, 455), Color3.fromRGB(35, 35, 40))
local TpButton = Instance.new("TextButton") 
styleButton(TpButton, "ТЕЛЕПОРТИРОВАТЬСЯ", UDim2.new(0.04, 0, 0, 492), Color3.fromRGB(35, 120, 150))

-- СЕКЦИЯ СЛЕДЖЕНИЯ (SPECTATE)
local LineSpec = Instance.new("Frame")
LineSpec.Parent = MainScroll LineSpec.Size = UDim2.new(0.92, 0, 0, 1) LineSpec.Position = UDim2.new(0.04, 0, 0, 535) LineSpec.BackgroundColor3 = Color3.fromRGB(50, 50, 55) LineSpec.BorderSizePixel = 0

local SpecSelectBtn = Instance.new("TextButton")
styleButton(SpecSelectBtn, "👁️ Выбрать игрока для слежки", UDim2.new(0.04, 0, 0, 545), Color3.fromRGB(35, 35, 40))
local SpecButton = Instance.new("TextButton")
styleButton(SpecButton, "НАЧАТЬ СЛЕДИТЬ", UDim2.new(0.04, 0, 0, 582), Color3.fromRGB(110, 85, 35))

-- Вейпоинты (сдвинуты вниз по списку)
local LineWP = Instance.new("Frame")
LineWP.Parent = MainScroll LineWP.Size = UDim2.new(0.92, 0, 0, 1) LineWP.Position = UDim2.new(0.04, 0, 0, 625) LineWP.BackgroundColor3 = Color3.fromRGB(50, 50, 55) LineWP.BorderSizePixel = 0

local WPInput = Instance.new("TextBox")
WPInput.Parent = MainScroll WPInput.Size = UDim2.new(0.92, 0, 0, 32) WPInput.Position = UDim2.new(0.04, 0, 0, 635) WPInput.BackgroundColor3 = Color3.fromRGB(35, 35, 40) WPInput.TextColor3 = Color3.fromRGB(255, 255, 255) WPInput.PlaceholderText = "Название точки..."
WPInput.Text = "" WPInput.Font = Enum.Font.SourceSans WPInput.TextSize = 14
local WPiC = Instance.new("UICorner") WPiC.CornerRadius = UDim.new(0, 6) WPiC.Parent = WPInput

local WPAddBtn = Instance.new("TextButton") 
styleButton(WPAddBtn, "+ Создать вейпоинт", UDim2.new(0.04, 0, 0, 672), Color3.fromRGB(45, 110, 65))

local WPScroll = Instance.new("ScrollingFrame")
WPScroll.Parent = MainScroll WPScroll.Size = UDim2.new(0.92, 0, 0, 85) WPScroll.Position = UDim2.new(0.04, 0, 0, 710) WPScroll.BackgroundTransparency = 1 WPScroll.CanvasSize = UDim2.new(0, 0, 0, 0) WPScroll.ScrollBarThickness = 3

local WPListLayout = Instance.new("UIListLayout")
WPListLayout.Padding = UDim.new(0, 4)
WPListLayout.Parent = WPScroll

-- ОПРЕДЕЛЕНИЕ ИГРОВОГО СТАТУСА И РОЛИ
local function getPlayerStatus(p)
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
    
    if isInLobbyZone then
        return "В ЛОББИ", Color3.fromRGB(200, 180, 110)
    end
    
    return "МИРНЫЙ", Color3.fromRGB(100, 200, 100)
end

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
DropdownTitle.Parent = DropdownGui DropdownTitle.Size = UDim2.new(1, -30, 0, 30) DropdownTitle.Text = "   Выберите цель:" DropdownTitle.TextColor3 = Color3.fromRGB(200, 200, 200) DropdownTitle.Font = Enum.Font.SourceSansBold DropdownTitle.BackgroundTransparency = 1 DropdownTitle.TextSize = 13 DropdownTitle.TextXAlignment = Enum.TextXAlignment.Left

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
    
    if DropdownGui.Visible and currentDropdownMode == mode then
        DropdownGui.Visible = false
        return
    end
    
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
                if currentDropdownMode == "Fling" then 
                    SelectedFlingPlayer = p FlingSelectBtn.Text = "🎯: " .. p.DisplayName
                elseif currentDropdownMode == "TP" then 
                    SelectedTpPlayer = p TpSelectBtn.Text = "👤: " .. p.DisplayName 
                elseif currentDropdownMode == "Spec" then
                    SelectedSpecPlayer = p SpecSelectBtn.Text = "👁️: " .. p.DisplayName
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
SpecSelectBtn.MouseButton1Click:Connect(function() openDropdown("Spec", SpecSelectBtn) end)

-- ЛОГИКА РАБОТЫ СПЕКТАТОРA (СЛЕДЖЕНИЯ)
SpecButton.MouseButton1Click:Connect(function()
    if not ScriptActive then return end
    
    if IsSpectating then
        -- Отключаем слежку
        IsSpectating = false
        SpecButton.Text = "НАЧАТЬ СЛЕДИТЬ"
        SpecButton.BackgroundColor3 = Color3.fromRGB(110, 85, 35)
        local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if myHum then Camera.CameraSubject = myHum end
    else
        -- Включаем слежку
        if SelectedSpecPlayer and SelectedSpecPlayer.Character and SelectedSpecPlayer.Character:FindFirstChild("Humanoid") then
            IsSpectating = true
            SpecButton.Text = "ОТПУСТИТЬ КАМЕРУ"
            SpecButton.BackgroundColor3 = Color3.fromRGB(35, 110, 65)
            Camera.CameraSubject = SelectedSpecPlayer.Character.Humanoid
        end
    end
end)

-- Авто-возврат камеры, если наблюдаемый игрок умер или вышел
RunService.RenderStepped:Connect(function()
    if ScriptActive and IsSpectating then
        if not SelectedSpecPlayer or not SelectedSpecPlayer.Parent or not SelectedSpecPlayer.Character or not SelectedSpecPlayer.Character:FindFirstChild("Humanoid") or SelectedSpecPlayer.Character.Humanoid.Health <= 0 then
            IsSpectating = false
            SpecButton.Text = "НАЧАТЬ СЛЕДИТЬ"
            SpecButton.BackgroundColor3 = Color3.fromRGB(110, 85, 35)
            local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if myHum then Camera.CameraSubject = myHum end
        else
            -- Держим принудительный фокус
            if Camera.CameraSubject ~= SelectedSpecPlayer.Character.Humanoid then
                Camera.CameraSubject = SelectedSpecPlayer.Character.Humanoid
            end
        end
    end
end)

-- ПЛАВНЫЙ ФЛАЙ
RunService.RenderStepped:Connect(function()
    if not ScriptActive or not States.Fly then return end
    local char = LocalPlayer.Character local root = char and char:FindFirstChild("HumanoidRootPart") local hum = char and char:FindFirstChild("Humanoid")
    if not root or not hum then return end
    
    hum.PlatformStand = true
    if States.NoClipInFly then
        for _, part in pairs(char:GetChildren()) do if part:IsA("BasePart") then part.CanCollide = false end end
    end
    
    if not FlyVelocity then
        FlyVelocity = Instance.new("BodyVelocity")
        FlyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        FlyVelocity.Parent = root
    end
    if not FlyGyro then
        FlyGyro = Instance.new("BodyGyro")
        FlyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        FlyGyro.D = 100 P = 10000
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
    
    if moveDir.Magnitude > 0 then
        FlyVelocity.Velocity = moveDir.Unit * FlySpeed
    else
        FlyVelocity.Velocity = Vector3.new(0,0,0)
    end
end)

-- Обновление ESP игроков сквозь стены
local function updateESP(character, color, enabled)
    if not ScriptActive or not character then return end
    local hl = character:FindFirstChild("Ultimate_ESP")
    if not enabled then if hl then hl:Destroy() end return end
    if not hl then
        hl = Instance.new("Highlight") hl.Name = "Ultimate_ESP" hl.OutlineColor = Color3.fromRGB(255, 255, 255) hl.FillTransparency = 0.4 hl.Parent = character
    end
    hl.FillColor = color
end

-- ЕДИНЫЙ ЦИКЛ ОБНОВЛЕНИЯ РОЛЕЙ
RunService.Heartbeat:Connect(function()
    if not ScriptActive then return end
    local Murderer, Sheriff = nil, nil
    for _, p in pairs(Players:GetPlayers()) do
        local role = getPlayerStatus(p)
        if role == "УБИЙЦА" then Murderer = p elseif role == "ШЕРИФ" then Sheriff = p end
    end
    InfoLabel.Text = "⚔️ Убийца: " .. (Murderer and Murderer.DisplayName or "Неизвестен") .. "  |  ⭐ Шериф: " .. (Sheriff and Sheriff.DisplayName or "Неизвестен")

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local role = getPlayerStatus(p)
            if role == "УБИЙЦА" then updateESP(p.Character, Color3.fromRGB(255, 0, 0), States.Murd)
            elseif role == "ШЕРИФ" then updateESP(p.Character, Color3.fromRGB(0, 0, 255), States.Sheriff)
            else updateESP(p.Character, Color3.fromRGB(0, 255, 0), States.Innocents) end
        end
    end
end)

-- Логика ТП
TpButton.MouseButton1Click:Connect(function()
    if not ScriptActive then return end
    if SelectedTpPlayer and SelectedTpPlayer.Character and SelectedTpPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if myRoot then myRoot.CFrame = SelectedTpPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 2, 0) end
    end
end)

-- УЛЬТРА-ФЛИНГ ИСПРАВЛЕННЫЙ (ПРОТИВ МАЛЕНЬКИХ АВАТАРОВ)
FlingButton.MouseButton1Click:Connect(function()
    if not ScriptActive then return end
    local char = LocalPlayer.Character 
    local root = char and char:FindFirstChild("HumanoidRootPart") 
    local hum = char and char:FindFirstChild("Humanoid")
    
    if not root or hum.Health <= 0 or not SelectedFlingPlayer or not SelectedFlingPlayer.Character or not SelectedFlingPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local targetHRP = SelectedFlingPlayer.Character.HumanoidRootPart 
    local originalCFrame = root.CFrame
    
    -- Увеличиваем скорость вращения в 10 раз
    local bAV = Instance.new("BodyAngularVelocity", root) 
    bAV.MaxTorque = Vector3.new(math.huge, math.huge, math.huge) 
    bAV.AngularVelocity = Vector3.new(0, 9999999, 0) -- МАКСИМАЛЬНОЕ ВРАЩЕНИЕ
    
    local bV = Instance.new("BodyVelocity", root) 
    bV.MaxForce = Vector3.new(math.huge, math.huge, math.huge) 
    bV.Velocity = Vector3.new(0, 0, 0)
    
    hum.Sit = true 
    local startTime = tick() 
    local loop
    
    -- Фиксируем позицию цели в момент захвата (для ФейкЛага)
    local targetPositionFake = targetHRP.Position
    
    loop = RunService.Heartbeat:Connect(function()
        if not ScriptActive or tick() - startTime > 0.6 or not targetHRP.Parent or (SelectedFlingPlayer.Character:FindFirstChild("Humanoid") and SelectedFlingPlayer.Character.Humanoid.Health <= 0) then
            loop:Disconnect() 
            bAV:Destroy() 
            bV:Destroy() 
            root.Velocity = Vector3.new(0,0,0)
            root.RotVelocity = Vector3.new(0,0,0) 
            root.CFrame = originalCFrame 
            hum.Sit = false 
            return
        end
        
        if targetHRP and targetHRP.Parent then
            targetPositionFake = targetPositionFake:Lerp(targetHRP.Position, 0.4)
        end
        
        for _, part in pairs(char:GetChildren()) do 
            if part:IsA("BasePart") then 
                part.CanCollide = false 
                part.Velocity = Vector3.new(999, 999, 999) 
            end 
        end
        
        -- Жесткий хаотичный спам ПРЯМО В ЦЕНТРЕ цели (пробивает маленьких)
        local randomOffset = Vector3.new(math.random(-5, 5) / 10, math.random(-2, 2) / 10, math.random(-5, 5) / 10)
        root.CFrame = CFrame.new(targetPositionFake + randomOffset) * CFrame.Angles(math.rad(math.random(0,360)), math.rad(math.random(0,360)), math.rad(math.random(0,360)))
    end)
end)

-- Система вейпоинтов С ПОЛНЫМ СОХРАНЕНИЕМ CFRAME (УГОЛ ПОВОРОТА)
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
                    if data[7] and data[7] ~= "None" then
                        pcall(function() WpBinds[name] = Enum.KeyCode[data[7]] end)
                    end
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
        ItemFrame.Parent = WPScroll
        ItemFrame.Size = UDim2.new(0.95, 0, 0, 30) 
        ItemFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45) 
        local ifc = Instance.new("UICorner") ifc.CornerRadius = UDim.new(0, 5) ifc.Parent = ItemFrame
        
        local TeleportBtn = Instance.new("TextButton")
        TeleportBtn.Parent = ItemFrame
        TeleportBtn.Size = UDim2.new(0.42, 0, 1, 0) 
        TeleportBtn.BackgroundTransparency = 1 
        TeleportBtn.Text = " 📍 " .. name 
        TeleportBtn.TextColor3 = Color3.fromRGB(220, 220, 220) 
        TeleportBtn.TextSize = 12 
        TeleportBtn.TextXAlignment = Enum.TextXAlignment.Left
        
        local WpBindBtn = Instance.new("TextButton")
        WpBindBtn.Parent = ItemFrame
        WpBindBtn.Size = UDim2.new(0.24, 0, 1, -6)
        WpBindBtn.Position = UDim2.new(0.42, 0, 0, 3)
        WpBindBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
        WpBindBtn.Text = WpBinds[name] and WpBinds[name].Name or "[Задать]"
        WpBindBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        WpBindBtn.Font = Enum.Font.SourceSansBold
        WpBindBtn.TextSize = 10
        local Wpbc = Instance.new("UICorner") Wpbc.CornerRadius = UDim.new(0, 4) Wpbc.Parent = WpBindBtn
        
        local ResetBindBtn = Instance.new("TextButton")
        ResetBindBtn.Parent = ItemFrame
        ResetBindBtn.Size = UDim2.new(0, 24, 1, -6)
        ResetBindBtn.Position = UDim2.new(0.67, 2, 0, 3)
        ResetBindBtn.BackgroundColor3 = Color3.fromRGB(70, 50, 50)
        ResetBindBtn.Text = "🔄"
        ResetBindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        ResetBindBtn.TextSize = 11
        local Rbbc = Instance.new("UICorner") Rbbc.CornerRadius = UDim.new(0, 4) Rbbc.Parent = ResetBindBtn

        local DelBtn = Instance.new("TextButton")
        DelBtn.Parent = ItemFrame
        DelBtn.Size = UDim2.new(0.2, -4, 1, 0) 
        DelBtn.Position = UDim2.new(0.8, 4, 0, 0) 
        DelBtn.BackgroundTransparency = 1 
        DelBtn.Text = "×" 
        DelBtn.TextColor3 = Color3.fromRGB(200, 80, 80)
        DelBtn.TextSize = 16
        
        TeleportBtn.MouseButton1Click:Connect(function() 
            if ScriptActive and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then 
                LocalPlayer.Character.HumanoidRootPart.CFrame = cf 
            end 
        end)
        
        WpBindBtn.MouseButton1Click:Connect(function()
            if not ScriptActive then return end
            ListeningForBind = "Waypoint"
            TargetWpBindName = name
            WpBindBtn.Text = "..."
            WpBindBtn.BackgroundColor3 = Color3.fromRGB(100, 80, 30)
        end)
        
        ResetBindBtn.MouseButton1Click:Connect(function()
            if not ScriptActive then return end
            WpBinds[name] = nil
            saveWaypointsToPC()
            renderWaypoints()
        end)
        
        DelBtn.MouseButton1Click:Connect(function() 
            if ScriptActive then 
                Waypoints[name] = nil 
                WpBinds[name] = nil
                ItemFrame:Destroy() 
                saveWaypointsToPC() 
                task.wait(0.05) 
                updateWPScroll() 
            end 
        end)
    end
    updateWPScroll()
end

WPAddBtn.MouseButton1Click:Connect(function()
    if not ScriptActive then return end
    local text = WPInput.Text:gsub("^%s*(.-)%s*$", "%1") local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if text ~= "" and hrp then Waypoints[text] = hrp.CFrame WPInput.Text = "" saveWaypointsToPC() renderWaypoints() end
end)
WPListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateWPScroll)
loadWaypointsFromPC() renderWaypoints()

-- Обработка биндов клавиатуры
BindFlyBtn.MouseButton1Click:Connect(function() ListeningForBind = "ToggleFly" BindFlyBtn.Text = "..." BindFlyBtn.BackgroundColor3 = Color3.fromRGB(100, 80, 30) end)
BindHideBtn.MouseButton1Click:Connect(function() ListeningForBind = "HideGui" BindHideBtn.Text = "..." BindHideBtn.BackgroundColor3 = Color3.fromRGB(100, 80, 30) end)

UserInputService.InputBegan:Connect(function(input, processed)
    if not ScriptActive then return end
    
    if ListeningForBind and input.UserInputType == Enum.UserInputType.Keyboard then
        local key = input.KeyCode
        if ListeningForBind == "ToggleFly" then
            Binds.ToggleFly = key
            BindFlyBtn.Text = "Бинд: " .. key.Name
            BindFlyBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        elseif ListeningForBind == "HideGui" then
            Binds.HideGui = key
            BindHideBtn.Text = "Бинд: " .. key.Name
            BindHideBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        elseif ListeningForBind == "Waypoint" and TargetWpBindName then
            WpBinds[TargetWpBindName] = key
            TargetWpBindName = nil
            saveWaypointsToPC()
            renderWaypoints()
        end
        ListeningForBind = nil
        return
    end
    
    if input.KeyCode == Binds.HideGui then
        MainFrame.Visible = not MainFrame.Visible
    end
    
    if input.KeyCode == Binds.ToggleFly then 
        if States.Fly then stopFlying() else States.Fly = true end
        updateFlyVisuals()
    end
    
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        for name, key in pairs(WpBinds) do
            if input.KeyCode == key and Waypoints[name] then
                LocalPlayer.Character.HumanoidRootPart.CFrame = Waypoints[name]
                break
            end
        end
    end
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
