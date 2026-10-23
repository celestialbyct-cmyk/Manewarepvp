--[[
    Maneware Target Module (all-in-one, Delta mobile)
    Target Strafe | Strafe | Target ESP (Circle + Cube) | No Push
    Свой красивый GUI внутри. Кнопка "M" открывает/закрывает меню.
    Настройки доступны из других скриптов через getgenv().ManeTarget
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

-- повторный запуск: убираем старую копию
local env = (getgenv and getgenv()) or _G
if env.ManeTargetCleanup then pcall(env.ManeTargetCleanup) end

local settings = {
    TargetStrafe = false, Distance = 8, Speed = 20,
    Strafe = false, StrafeSpeed = 32,
    TargetESP_Circle = false, TargetESP_CircleSpeed = 5,
    TargetESP_Cube = false, TargetESP_Speed = 5,
    NoPush = false,
}
env.ManeTarget = settings

local conns = {}
local function keep(c) conns[#conns + 1] = c return c end

local gui
local autoRotateChanged = false

-- ==========================================
-- TARGET ESP OBJECTS
-- ==========================================
local ESP_COLOR = Color3.fromRGB(255, 60, 90)
local BEADS, RING_RADIUS = 20, 2.2

local espFolder = Instance.new("Folder")
espFolder.Name = "TargetESP"
espFolder.Parent = Workspace.CurrentCamera

local function newPart(size, shape)
    local p = Instance.new("Part")
    p.Size = size
    if shape then p.Shape = shape end
    p.Material = Enum.Material.Neon
    p.Color = ESP_COLOR
    p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
    return p
end

local circleObj, cubeObj
local function ensureCircle()
    if circleObj then return end
    local f = Instance.new("Folder")
    f.Name = "Circle"
    local beads = {}
    for i = 1, BEADS do
        local b = newPart(Vector3.new(0.35, 0.35, 0.35), Enum.PartType.Ball)
        b.Parent = f
        beads[i] = b
    end
    circleObj = {Folder = f, Beads = beads}
end
local function ensureCube()
    if cubeObj then return end
    local p = newPart(Vector3.new(1.6, 1.6, 1.6))
    p.Transparency = 0.35
    local sb = Instance.new("SelectionBox")
    sb.Adornee = p
    sb.LineThickness = 0.04
    sb.Color3 = ESP_COLOR
    sb.SurfaceTransparency = 1
    sb.Parent = p
    cubeObj = p
end
local function killCircle() if circleObj then circleObj.Folder:Destroy() circleObj = nil end end
local function killCube() if cubeObj then cubeObj:Destroy() cubeObj = nil end end

local function getClosestPlayer(myPos)
    local closest, minDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local h = p.Character:FindFirstChild("HumanoidRootPart")
            local hm = p.Character:FindFirstChildOfClass("Humanoid")
            if h and hm and hm.Health > 0 then
                local d = (h.Position - myPos).Magnitude
                if d < minDist then minDist, closest = d, p end
            end
        end
    end
    return closest
end

-- ==========================================
-- CLEANUP
-- ==========================================
env.ManeTargetCleanup = function()
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    killCircle() killCube()
    if espFolder then espFolder:Destroy() end
    if gui then gui:Destroy() end
    local ch = player.Character
    local hm = ch and ch:FindFirstChildOfClass("Humanoid")
    if hm and autoRotateChanged then hm.AutoRotate = true end
end

-- ==========================================
-- GUI
-- ==========================================
local BG = Color3.fromRGB(18, 18, 27)
local BG2 = Color3.fromRGB(28, 28, 42)
local ACCENT = Color3.fromRGB(150, 110, 255)
local ACCENT2 = Color3.fromRGB(90, 60, 200)
local TEXT = Color3.fromRGB(235, 235, 245)
local MUTED = Color3.fromRGB(150, 150, 172)
local OFF = Color3.fromRGB(52, 52, 74)

gui = Instance.new("ScreenGui")
gui.Name = "ManeTarget"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
local okParent = pcall(function()
    gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
end)
if not okParent or not gui.Parent then
    gui.Parent = player:WaitForChild("PlayerGui")
end

local function corner(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = o
    return c
end
local function stroke(o, color, tr, th)
    local s = Instance.new("UIStroke")
    s.Color = color or ACCENT
    s.Transparency = tr or 0.6
    s.Thickness = th or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = o
    return s
end
local function label(parent, txt, size, color, font, align)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextSize = size
    l.TextColor3 = color
    l.Font = font or Enum.Font.GothamMedium
    l.TextXAlignment = align or Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end
local function tween(o, t, props)
    TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function isPress(i)
    return i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1
end
local function isMove(i)
    return i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement
end

-- перетаскивание (+ onTap, если это был просто тап)
local function draggable(handle, frame, onTap)
    local dragging, dragStart, startPos, moved = false, nil, nil, false
    keep(handle.InputBegan:Connect(function(i)
        if isPress(i) then
            dragging, moved = true, false
            dragStart, startPos = i.Position, frame.Position
        end
    end))
    keep(UserInputService.InputChanged:Connect(function(i)
        if dragging and isMove(i) then
            local d = i.Position - dragStart
            if d.Magnitude > 8 then moved = true end
            if moved then
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end
    end))
    keep(UserInputService.InputEnded:Connect(function(i)
        if dragging and isPress(i) then
            dragging = false
            if not moved and onTap then onTap() end
        end
    end))
end

-- окно
local window = Instance.new("Frame")
window.Name = "Window"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.new(0.5, 0, 0.5, 0)
window.Size = UDim2.fromOffset(290, 330)
window.BackgroundColor3 = BG
window.BorderSizePixel = 0
window.ClipsDescendants = true
window.Parent = gui
corner(window, 14)
local winStroke = stroke(window, ACCENT, 0.2, 1.5)
local strokeGrad = Instance.new("UIGradient")
strokeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, ACCENT),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 90, 150)),
    ColorSequenceKeypoint.new(1, ACCENT),
})
strokeGrad.Parent = winStroke
local winScale = Instance.new("UIScale")
winScale.Parent = window

-- шапка
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
header.BorderSizePixel = 0
header.Parent = window
local hg = Instance.new("UIGradient")
hg.Color = ColorSequence.new(ACCENT, ACCENT2)
hg.Rotation = 20
hg.Parent = header

local title = label(header, "MANEWARE  •  Target", 15, Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold)
title.Position = UDim2.new(0, 14, 0, 0)
title.Size = UDim2.new(1, -60, 1, 0)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(28, 28)
closeBtn.Position = UDim2.new(1, -36, 0.5, -14)
closeBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
closeBtn.BackgroundTransparency = 0.7
closeBtn.Text = "–"
closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.AutoButtonColor = false
closeBtn.Parent = header
corner(closeBtn, 8)

-- список
local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.new(0, 0, 0, 42)
scroll.Size = UDim2.new(1, 0, 1, -42)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = ACCENT
scroll.CanvasSize = UDim2.new()
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = window
local pad = Instance.new("UIPadding")
pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 10), UDim.new(0, 10)
pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 10), UDim.new(0, 12)
pad.Parent = scroll
local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 8)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = scroll

local order = 0
local function add(f) order += 1 f.LayoutOrder = order end

local function section(txt)
    local l = label(scroll, txt, 11, ACCENT, Enum.Font.GothamBold)
    l.Size = UDim2.new(1, 0, 0, 18)
    add(l)
end

local function makeToggle(txt, key)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 42)
    f.BackgroundColor3 = BG2
    f.BorderSizePixel = 0
    f.Parent = scroll
    corner(f, 10)
    stroke(f, ACCENT, 0.8)
    add(f)

    local l = label(f, txt, 14, TEXT)
    l.Position = UDim2.new(0, 12, 0, 0)
    l.Size = UDim2.new(1, -70, 1, 0)

    local track = Instance.new("Frame")
    track.Size = UDim2.fromOffset(44, 22)
    track.Position = UDim2.new(1, -56, 0.5, -11)
    track.BackgroundColor3 = OFF
    track.BorderSizePixel = 0
    track.Parent = f
    corner(track, 11)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(18, 18)
    knob.Position = UDim2.new(0, 2, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = track
    corner(knob, 9)

    local function refresh()
        local on = settings[key]
        tween(track, 0.15, {BackgroundColor3 = on and ACCENT or OFF})
        tween(knob, 0.15, {Position = on and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)})
    end
    refresh()

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = f
    keep(btn.Activated:Connect(function()
        settings[key] = not settings[key]
        refresh()
    end))
end

local function makeSlider(txt, key, min, max, step)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 56)
    f.BackgroundColor3 = BG2
    f.BorderSizePixel = 0
    f.Parent = scroll
    corner(f, 10)
    stroke(f, ACCENT, 0.8)
    add(f)

    local l = label(f, txt, 13, TEXT)
    l.Position = UDim2.new(0, 12, 0, 6)
    l.Size = UDim2.new(0.6, 0, 0, 18)
    local val = label(f, "", 13, ACCENT, Enum.Font.GothamBold, Enum.TextXAlignment.Right)
    val.Position = UDim2.new(0.5, 0, 0, 6)
    val.Size = UDim2.new(0.5, -12, 0, 18)

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -28, 0, 6)
    track.Position = UDim2.new(0, 14, 0, 36)
    track.BackgroundColor3 = OFF
    track.BorderSizePixel = 0
    track.Parent = f
    corner(track, 3)
    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = ACCENT
    fill.BorderSizePixel = 0
    fill.Parent = track
    corner(fill, 3)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(16, 16)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 2
    knob.Parent = track
    corner(knob, 8)

    local function set(v)
        v = math.clamp(math.floor(v / step + 0.5) * step, min, max)
        settings[key] = v
        local r = (v - min) / (max - min)
        fill.Size = UDim2.new(r, 0, 1, 0)
        knob.Position = UDim2.new(r, 0, 0.5, 0)
        val.Text = tostring(math.floor(v * 100 + 0.5) / 100)
    end
    set(settings[key])

    local dragging = false
    local function fromX(x)
        local r = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        set(min + (max - min) * r)
    end
    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 0, 30)
    hit.Position = UDim2.new(0, 0, 1, -30)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.Parent = f
    keep(hit.InputBegan:Connect(function(i)
        if isPress(i) then
            dragging = true
            scroll.ScrollingEnabled = false
            fromX(i.Position.X)
        end
    end))
    keep(UserInputService.InputChanged:Connect(function(i)
        if dragging and isMove(i) then fromX(i.Position.X) end
    end))
    keep(UserInputService.InputEnded:Connect(function(i)
        if dragging and isPress(i) then
            dragging = false
            scroll.ScrollingEnabled = true
        end
    end))
end

section("TARGET STRAFE")
makeToggle("Target Strafe", "TargetStrafe")
makeSlider("Дистанция", "Distance", 3, 25, 0.5)
makeSlider("Скорость орбиты", "Speed", 5, 80, 1)

section("STRAFE")
makeToggle("Strafe", "Strafe")
makeSlider("Скорость Strafe", "StrafeSpeed", 16, 120, 1)

section("TARGET ESP")
makeToggle("Circle (голова → ноги)", "TargetESP_Circle")
makeSlider("Скорость круга", "TargetESP_CircleSpeed", 1, 20, 0.5)
makeToggle("Cube", "TargetESP_Cube")
makeSlider("Скорость куба", "TargetESP_Speed", 1, 20, 0.5)

section("MISC")
makeToggle("No Push", "NoPush")

-- кнопка "M"
local fab = Instance.new("TextButton")
fab.Size = UDim2.fromOffset(46, 46)
fab.Position = UDim2.new(0, 14, 0, 90)
fab.BackgroundColor3 = ACCENT
fab.Text = "M"
fab.TextSize = 20
fab.TextColor3 = Color3.fromRGB(255, 255, 255)
fab.Font = Enum.Font.GothamBold
fab.AutoButtonColor = false
fab.Parent = gui
corner(fab, 23)
stroke(fab, Color3.fromRGB(255, 255, 255), 0.6, 1.5)
local fg = Instance.new("UIGradient")
fg.Color = ColorSequence.new(ACCENT, ACCENT2)
fg.Rotation = 45
fg.Parent = fab

local isOpen = true
local function setOpen(v)
    isOpen = v
    if v then
        window.Visible = true
        winScale.Scale = 0.9
        tween(winScale, 0.18, {Scale = 1})
    else
        window.Visible = false
    end
end
keep(closeBtn.Activated:Connect(function() setOpen(false) end))
draggable(fab, fab, function() setOpen(not isOpen) end)
draggable(header, window)

-- ==========================================
-- LOGIC
-- ==========================================
local target, acc = nil, 0
local cubeAngle, circleAngle, scanTime, strafeAngle = 0, 0, 0, 0
local noPushApplied = false

keep(RunService.Heartbeat:Connect(function(dt)
    -- анимация рамки меню
    strokeGrad.Rotation = (tick() * 60) % 360

    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then
        killCircle() killCube()
        return
    end

    -- цель обновляем 4 раза в секунду
    acc += dt
    if acc >= 0.25 then
        acc = 0
        if settings.TargetStrafe or settings.TargetESP_Circle or settings.TargetESP_Cube then
            target = getClosestPlayer(hrp.Position)
        else
            target = nil
        end

        if settings.NoPush then
            noPushApplied = true
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
                end
            end
        elseif noPushApplied then
            noPushApplied = false
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CustomPhysicalProperties = nil end
            end
        end
    end

    local tChar = target and target.Character
    local tHRP = tChar and tChar:FindFirstChild("HumanoidRootPart")
    local tHead = tChar and tChar:FindFirstChild("Head")
    local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
    local valid = tHRP and tHead and tHum and tHum.Health > 0

    -- TARGET STRAFE
    if settings.TargetStrafe and valid then
        strafeAngle += dt * (settings.Speed / 10)
        local goal = tHRP.Position + Vector3.new(math.cos(strafeAngle), 0, math.sin(strafeAngle)) * settings.Distance
        local goalCF = CFrame.lookAt(goal, tHRP.Position)
        hum.AutoRotate = false
        autoRotateChanged = true
        hrp.CFrame = hrp.CFrame:Lerp(goalCF, math.min(1, dt * 20))
        hrp.AssemblyLinearVelocity = Vector3.zero
    else
        if autoRotateChanged then
            hum.AutoRotate = true
            autoRotateChanged = false
        end
        -- STRAFE
        if settings.Strafe then
            local md = hum.MoveDirection
            if md.Magnitude > 0.05 then
                local v = hrp.AssemblyLinearVelocity
                local sp = settings.StrafeSpeed
                hrp.AssemblyLinearVelocity = Vector3.new(md.X * sp, v.Y, md.Z * sp)
            end
        end
    end

    -- TARGET ESP: CIRCLE (макушка → пятки)
    if settings.TargetESP_Circle then
        ensureCircle()
        if valid then
            circleAngle += dt * settings.TargetESP_CircleSpeed
            scanTime += dt * (settings.TargetESP_CircleSpeed / 3)

            local topY = tHead.Position.Y + tHead.Size.Y / 2
            local bottomY
            if tHum.RigType == Enum.HumanoidRigType.R15 then
                bottomY = tHRP.Position.Y - tHRP.Size.Y / 2 - tHum.HipHeight
            else
                bottomY = tHRP.Position.Y - 3
            end
            local alpha = (math.sin(scanTime) + 1) / 2
            local y = bottomY + (topY - bottomY) * alpha

            local cx, cz = tHRP.Position.X, tHRP.Position.Z
            for i, b in ipairs(circleObj.Beads) do
                local a = circleAngle + (i / BEADS) * math.pi * 2
                b.Position = Vector3.new(cx + math.cos(a) * RING_RADIUS, y, cz + math.sin(a) * RING_RADIUS)
            end
            circleObj.Folder.Parent = espFolder
        else
            circleObj.Folder.Parent = nil
        end
    else
        killCircle()
    end

    -- TARGET ESP: CUBE
    if settings.TargetESP_Cube then
        ensureCube()
        if valid then
            cubeAngle += dt * settings.TargetESP_Speed
            local pos = Vector3.new(
                tHead.Position.X,
                tHead.Position.Y + tHead.Size.Y / 2 + 2.2 + math.sin(tick() * 2) * 0.3,
                tHead.Position.Z
            )
            cubeObj.CFrame = CFrame.new(pos) * CFrame.Angles(cubeAngle, cubeAngle * 0.7, 0)
            cubeObj.Parent = espFolder
        else
            cubeObj.Parent = nil
        end
    else
        killCube()
    end
end))
