
-- Mobile Neon GUI | Roblox Lua
-- Mobile-first interface with Combat / Move / Visual tabs
-- UI and settings are functional; gameplay handlers are placeholders.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("MobileNeonUI")
if old then old:Destroy() end

local C = {
    bg = Color3.fromRGB(13, 15, 24),
    panel = Color3.fromRGB(21, 24, 37),
    element = Color3.fromRGB(30, 34, 51),
    accent = Color3.fromRGB(0, 220, 190),
    purple = Color3.fromRGB(143, 95, 255),
    white = Color3.fromRGB(239, 242, 255),
    muted = Color3.fromRGB(139, 148, 171),
    red = Color3.fromRGB(255, 92, 115)
}

local settings = {
    TargetStrafe = false,
    Speed = 16,
    Distance = 2,
    NoPush = false,
    Players = true
}

local gui = Instance.new("ScreenGui")
gui.Name = "MobileNeonUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.Parent = playerGui

local function corner(obj, radius)
    local v = Instance.new("UICorner")
    v.CornerRadius = UDim.new(0, radius or 12)
    v.Parent = obj
end

local function stroke(obj, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or C.accent
    s.Thickness = thickness or 1
    s.Transparency = 0.25
    s.Parent = obj
end

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local main = make("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromScale(0.88, 0.72),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    ClipsDescendants = true
}, gui)

main.Size = UDim2.new(
    0.88, 0,
    0, math.min(510, workspace.CurrentCamera.ViewportSize.Y * 0.78)
)
corner(main, 18)
stroke(main, C.purple, 1.5)

make("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.bg),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 20, 42))
    }),
    Rotation = 35
}, main)

-- Header
local header = make("Frame", {
    Size = UDim2.new(1, 0, 0, 65),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0
}, main)

local title = make("TextLabel", {
    Position = UDim2.new(0, 16, 0, 7),
    Size = UDim2.new(1, -65, 0, 29),
    BackgroundTransparency = 1,
    Text = "N E O N   /   M O B I L E",
    TextColor3 = C.white,
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, header)

make("TextLabel", {
    Position = UDim2.new(0, 17, 0, 35),
    Size = UDim2.new(1, -70, 0, 18),
    BackgroundTransparency = 1,
    Text = "UNIVERSAL INTERFACE  •  V1.0",
    TextColor3 = C.muted,
    TextSize = 9,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left
}, header)

local close = make("TextButton", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -12, 0.5, 0),
    Size = UDim2.fromOffset(34, 34),
    BackgroundColor3 = Color3.fromRGB(54, 30, 47),
    Text = "×",
    TextColor3 = C.red,
    TextSize = 24,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false
}, header)
corner(close, 10)

close.Activated:Connect(function()
    gui:Destroy()
end)

-- Drag header with mouse or touch
local dragging, dragStart, startPos

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Tabs
local tabBar = make("Frame", {
    Position = UDim2.new(0, 10, 0, 76),
    Size = UDim2.new(1, -20, 0, 43),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0
}, main)
corner(tabBar, 12)

local tabNames = {"Combat", "Move", "Visual"}
local tabButtons = {}
local pages = {}

local body = make("Frame", {
    Position = UDim2.new(0, 10, 0, 128),
    Size = UDim2.new(1, -20, 1, -140),
    BackgroundTransparency = 1
}, main)

for i, name in ipairs(tabNames) do
    local button = make("TextButton", {
        Position = UDim2.new((i - 1) / 3, 3, 0, 3),
        Size = UDim2.new(1 / 3, -6, 1, -6),
        BackgroundColor3 = C.panel,
        Text = name,
        TextColor3 = C.muted,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false
    }, tabBar)
    corner(button, 9)
    tabButtons[name] = button

    local page = make("ScrollingFrame", {
        Name = name .. "Page",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.accent,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false
    }, body)

    make("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, page)

    make("UIPadding", {
        PaddingTop = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 2),
        PaddingRight = UDim.new(0, 5)
    }, page)

    pages[name] = page
end

local function selectTab(name)
    for tab, page in pairs(pages) do
        local active = tab == name
        page.Visible = active
        tabButtons[tab].BackgroundColor3 =
            active and C.accent or C.panel
        tabButtons[tab].TextColor3 =
            active and C.bg or C.muted
    end
end

for name, button in pairs(tabButtons) do
    button.Activated:Connect(function()
        selectTab(name)
    end)
end

local function section(page, text)
    local label = make("TextLabel", {
        Size = UDim2.new(1, -4, 0, 27),
        BackgroundTransparency = 1,
        Text = "  " .. string.upper(text),
        TextColor3 = C.accent,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    }, page)
    return label
end

local function card(page, height)
    local f = make("Frame", {
        Size = UDim2.new(1, -4, 0, height or 58),
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0
    }, page)
    corner(f, 12)
    stroke(f, C.element, 1)
    return f
end

local function toggle(page, label, initial, callback)
    local f = card(page, 58)

    make("TextLabel", {
        Position = UDim2.new(0, 13, 0, 0),
        Size = UDim2.new(1, -85, 1, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = C.white,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left
    }, f)

    local b = make("TextButton", {
        Position = UDim2.new(1, -60, 0.5, -13),
        Size = UDim2.fromOffset(47, 26),
        BackgroundColor3 = initial and C.accent or C.element,
        Text = "",
        AutoButtonColor = false
    }, f)
    corner(b, 13)

    local knob = make("Frame", {
        Position = initial and UDim2.new(1, -22, 0, 4)
            or UDim2.new(0, 4, 0, 4),
        Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = C.white,
        BorderSizePixel = 0
    }, b)
    corner(knob, 10)

    local state = initial

    local function update(value)
        state = value
        b.BackgroundColor3 = state and C.accent or C.element
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = state and UDim2.new(1, -22, 0, 4)
                or UDim2.new(0, 4, 0, 4)
        }):Play()
        callback(state)
    end

    b.Activated:Connect(function()
        update(not state)
    end)

    return {
        Set = update,
        Get = function() return state end
    }
end

local function slider(page, label, min, max, initial, callback)
    local f = card(page, 80)

    local valueLabel = make("TextLabel", {
        Position = UDim2.new(0, 13, 0, 7),
        Size = UDim2.new(0.65, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = C.white,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left
    }, f)

    local number = make("TextLabel", {
        Position = UDim2.new(1, -75, 0, 7),
        Size = UDim2.new(0, 60, 0, 22),
        BackgroundTransparency = 1,
        TextColor3 = C.accent,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right
    }, f)

    local track = make("Frame", {
        Position = UDim2.new(0, 13, 0, 47),
        Size = UDim2.new(1, -26, 0, 6),
        BackgroundColor3 = C.element,
        BorderSizePixel = 0
    }, f)
    corner(track, 6)

    local fill = make("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = C.accent,
        BorderSizePixel = 0
    }, track)
    corner(fill, 6)

    local knob = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = C.white,
        BorderSizePixel = 0
    }, track)
    corner(knob, 10)
    stroke(knob, C.accent, 1)

    local value = initial
    local active = false

    local function setValue(v)
        value = math.clamp(math.floor(v + 0.5), min, max)
        local alpha = (value - min) / (max - min)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        number.Text = tostring(value)
        callback(value)
    end

    local function fromX(x)
        local alpha = math.clamp(
            (x - track.AbsolutePosition.X) / track.AbsoluteSize.X,
            0, 1
        )
        setValue(min + alpha * (max - min))
    end

    local hit = make("TextButton", {
        Position = UDim2.new(0, 0, 0, 32),
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false
    }, f)

    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            active = true
            fromX(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if active and (
            input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseMovement
        ) then
            fromX(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            active = false
        end
    end)

    setValue(initial)
end

-- COMBAT TAB
local combat = pages.Combat
section(combat, "Combat modules")

local combatToggle = toggle(combat, "Combat module", false, function(v)
    print("Combat module:", v)
end)

local aimToggle = toggle(combat, "Aim assist UI", false, function(v)
    print("Aim assist setting:", v)
end)

local note = card(combat, 66)
make("TextLabel", {
    Position = UDim2.new(0, 12, 0, 6),
    Size = UDim2.new(1, -24, 1, -12),
    BackgroundTransparency = 1,
    Text = "Combat controls are interface placeholders.\nConnect only to mechanics in your own experience.",
    TextWrapped = true,
    TextColor3 = C.muted,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left
}, note)

-- MOVE TAB
local move = pages.Move
section(move, "Movement")

toggle(move, "TargetStrafe", settings.TargetStrafe, function(v)
    settings.TargetStrafe = v
    print("TargetStrafe setting:", v)
end)

slider(move, "Speed (studs)", 1, 50, settings.Speed, function(v)
    settings.Speed = v
    print("Speed setting:", v)
end)

slider(move, "Distance (studs)", 0, 5, settings.Distance, function(v)
    settings.Distance = v
    print("Distance setting:", v)
end)

section(move, "Collision")

toggle(move, "NoPush", settings.NoPush, function(v)
    settings.NoPush = v
    print("NoPush setting:", v)
end)

toggle(move, "Players", settings.Players, function(v)
    settings.Players = v
    print("Players setting:", v)
end)

-- VISUAL TAB
local visual = pages.Visual
section(visual, "Interface")

toggle(visual, "Accent animation", true, function(v)
    print("Accent animation setting:", v)
end)

toggle(visual, "Show status", true, function(v)
    title.Visible = v
end)

local info = card(visual, 62)
make("TextLabel", {
    Position = UDim2.new(0, 12, 0, 0),
    Size = UDim2.new(1, -24, 1, 0),
    BackgroundTransparency = 1,
    Text = "NEON UI  /  MOBILE\nTouch-friendly • Draggable • Resizable layout",
    TextColor3 = C.muted,
    TextSize = 11,
    Font = Enum.Font.GothamMedium,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left
}, info)

selectTab("Move")
print("Mobile Neon GUI loaded.")
