--!nocheck
-- luacheck: globals cloneref isfile isfolder makefolder writefile readfile listfiles delfile Color3 Enum game UDim2 Vector2 Rect
-- Dendrite UI (Rebuilt)
-- Modern top-tab UI library with per-game configs, clean structure, and backwards-compatible API aliases.

local cloneref = cloneref or function(x) return x end

-- Service helper (always via cloneref)
local function SRV(name) return cloneref(game:GetService(name)) end

local CoreGui = SRV("CoreGui")
local Players = SRV("Players")
local TweenService = SRV("TweenService")
local UserInputService = SRV("UserInputService")
local RunService = SRV("RunService")
local HttpService = SRV("HttpService")
local MarketplaceService = SRV("MarketplaceService")

-- Safe file API wrappers across executors
local _isfile = (isfile or function() return false end)
local _isfolder = (isfolder or function() return false end)
local _makefolder = (makefolder or function() end)
local _writefile = (writefile or function() end)
local _readfile = (readfile or function() return "" end)
local _listfiles = (listfiles or function() return {} end)
local _delfile = (delfile or function() end)

-- Utility
local function Create(className, props, children)
    local inst = Instance.new(className)
    if props then
        for k, v in pairs(props) do
            inst[k] = v
        end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = inst
        end
    end
    return inst
end

local function Round(num, increment)
    increment = increment or 1
    return math.floor(num / increment + 0.5) * increment
end

local function Clamp(v, minV, maxV)
    return (v < minV and minV) or (v > maxV and maxV) or v
end

-- Theme
local Theme = {
    Bg = Color3.fromRGB(18, 18, 20),
    Panel = Color3.fromRGB(24, 24, 28),
    Stroke = Color3.fromRGB(38, 38, 42),
    Accent = Color3.fromRGB(105, 125, 255),
    Accent2 = Color3.fromRGB(90, 110, 255),
    Text = Color3.fromRGB(230, 230, 235),
    SubText = Color3.fromRGB(160, 160, 172),
    Hover = Color3.fromRGB(32, 32, 36),
    Button = Color3.fromRGB(32, 34, 40),
    Good = Color3.fromRGB(85, 195, 95),
    Warn = Color3.fromRGB(255, 178, 55),
    Bad = Color3.fromRGB(255, 85, 98),
    Scrollbar = Color3.fromRGB(46, 46, 52),
}

local Fonts = {
    Regular = Enum.Font.Gotham,
    Medium = Enum.Font.GothamMedium,
    Bold = Enum.Font.GothamBold
}

-- Tween helper
local function T(i, t, p) return TweenService:Create(i, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p) end

-- Drop shadow helper
local function DropShadow(parent, transparency)
    transparency = transparency or 0.4
    local shadow = Create("Frame", {
        Name = "Shadow",
        BackgroundColor3 = Color3.new(0,0,0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1,1),
        ZIndex = parent.ZIndex - 1,
        Parent = parent.Parent
    })
    local layers = 3
    for i=1,layers do
        local s = Create("ImageLabel", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5,0.5),
            Position = UDim2.fromScale(0.5,0.5),
            Size = UDim2.new(1, 20 + (i-1)*6, 1, 20 + (i-1)*6),
            Image = "rbxassetid://6014261993", -- blurred circle
            ImageTransparency = transparency + (i-1)*0.08,
            ImageColor3 = Color3.new(0,0,0),
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(64,64,64,64),
            ZIndex = parent.ZIndex - 1,
            Parent = shadow
        })
    end
    shadow.LayoutOrder = (parent.LayoutOrder or 1) - 1
    return shadow
end

-- Config Manager
local Config = {}
do
    local function sanitize(s)
        s = tostring(s or "Game")
        s = s:gsub("[^%w%s%-_]", "_")
        s = s:gsub("%s+", "_")
        return s
    end

    local function getGameKey()
        local ok, info = pcall(function()
            return MarketplaceService:GetProductInfo(game.PlaceId)
        end)
        if ok and info and info.Name and #info.Name > 0 then
            return sanitize(info.Name)
        end
        return "Place_" .. tostring(game.PlaceId)
    end

    local BaseFolder = "DendriteUI"
    local GameFolder = BaseFolder .. "/" .. getGameKey()

    function Config.Ensure()
        if not _isfolder(BaseFolder) then _makefolder(BaseFolder) end
        if not _isfolder(GameFolder) then _makefolder(GameFolder) end
    end

    function Config.Path(name)
        Config.Ensure()
        return GameFolder .. "/" .. sanitize(name) .. ".json"
    end

    function Config.Save(name, data)
        local path = Config.Path(name)
        local ok, encoded = pcall(function() return HttpService:JSONEncode(data or {}) end)
        if ok then _writefile(path, encoded) end
        return ok
    end

    function Config.Load(name)
        local path = Config.Path(name)
        if _isfile(path) then
            local ok, decoded = pcall(function()
                return HttpService:JSONDecode(_readfile(path))
            end)
            if ok and type(decoded) == "table" then return decoded end
        end
        return {}
    end

    function Config.List()
        Config.Ensure()
        local files = {}
        for _, f in ipairs(_listfiles(GameFolder) or {}) do
            local n = f:match("([^/\\]+)$") or f
            local base = n:gsub("%.json$", "")
            table.insert(files, base)
        end
        table.sort(files)
        return files
    end

    function Config.Delete(name)
        local path = Config.Path(name)
        if _isfile(path) then _delfile(path) end
    end
end

local function Signal()
    local handlers = {}
    return {
        Connect = function(_, fn)
            local conn = { Connected = true }
            handlers[#handlers + 1] = { fn = fn, conn = conn }
            function conn:Disconnect()
                self.Connected = false
            end
            return conn
        end,
        Fire = function(_, ...)
            for i = 1, #handlers do
                local h = handlers[i]
                if h.conn.Connected then
                    task.spawn(h.fn, ...)
                end
            end
        end
    }
end

-- Library
local Library = {
    _windows = {},
    _controls = {},
    _theme = Theme,
    _fonts = Fonts,
    _version = "3.0.0",
}

-- Root Gui
local RootGui = (function()
    local gui = Create("ScreenGui", {
        Name = "DendriteUI",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        Parent = CoreGui
    })
    return gui
end)()

-- Control registry helpers
function Library:_registerControl(control)
    self._controls[control.id] = control
end

function Library:_setValue(id, value, silent)
    local c = self._controls[id]
    if c and c.Set then
        c:Set(value, silent)
    end
end

function Library:_getSnapshot()
    local snapshot = {}
    for id, c in pairs(self._controls) do
        if c.Get then snapshot[id] = c:Get() end
    end
    return snapshot
end

function Library:SaveConfig(name)
    return Config.Save(name, self:_getSnapshot())
end

function Library:LoadConfig(name)
    local data = Config.Load(name)
    for id, value in pairs(data) do
        self:_setValue(id, value, true)
    end
end

function Library:ListConfigs()
    return Config.List()
end

-- Window
function Library:NewWindow(opts)
    opts = opts or {}
    local title = tostring(opts.Name or "Dendrite UI")
    local size = opts.Size or UDim2.fromOffset(640, 420)
    local closeCb = opts.CloseCallback

    local Window = {
        _tabs = {},
        _selectedTab = nil,
        Name = title
    }

    local z = 100
    local root = Create("Frame", {
        Name = "Window",
        Size = size,
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = z,
        Parent = RootGui
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 10) }),
        Create("UIStroke", { Color = Theme.Stroke, Thickness = 1, Transparency = 0.3 }),
    })
    DropShadow(root, 0.5)

    -- Draggable header
    local header = Create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.Bg,
        BorderSizePixel = 0,
        ZIndex = z + 1,
        Parent = root
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 10) }),
        Create("UIStroke", { Color = Theme.Stroke, Thickness = 1, Transparency = 0.2 })
    })
    local titleLabel = Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.fromOffset(16, 0),
        Text = title,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Fonts.Bold,
        TextSize = 16,
        ZIndex = z + 2,
        Parent = header
    })

    local closeBtn = Create("TextButton", {
        Name = "Close",
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, -12 - 28, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Button,
        Text = "✕",
        Font = Fonts.Medium,
        TextSize = 16,
        TextColor3 = Theme.Text,
        AutoButtonColor = false,
        ZIndex = z + 2,
        Parent = header
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
        Create("UIStroke", { Color = Theme.Stroke, Thickness = 1, Transparency = 0.3 })
    })
    closeBtn.MouseEnter:Connect(function() T(closeBtn, 0.12, {BackgroundColor3 = Theme.Bad}):Play() end)
    closeBtn.MouseLeave:Connect(function() T(closeBtn, 0.12, {BackgroundColor3 = Theme.Button}):Play() end)
    closeBtn.MouseButton1Click:Connect(function()
        root.Visible = false
        if typeof(closeCb) == "function" then
            pcall(closeCb)
        end
    end)

    -- Top Tab Bar
    local tabBar = Create("ScrollingFrame", {
        Name = "TabBar",
        BackgroundColor3 = Theme.Panel,
        Size = UDim2.new(1, -24, 0, 36),
        Position = UDim2.fromOffset(12, 48),
        BorderSizePixel = 0,
        ScrollBarImageColor3 = Theme.Scrollbar,
        ScrollBarThickness = 2,
        CanvasSize = UDim2.fromOffset(0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        ScrollingDirection = Enum.ScrollingDirection.X,
        ZIndex = z + 1,
        Parent = root
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Create("UIStroke", { Color = Theme.Stroke, Thickness = 1, Transparency = 0.3 }),
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8)
        }),
        Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })
    })

    -- Content region
    local content = Create("Frame", {
        Name = "Content",
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -24, 1, - (48 + 36 + 24)),
        Position = UDim2.new(0, 12, 0, 48 + 36 + 12),
        ZIndex = z,
        Parent = root
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Create("UIStroke", { Color = Theme.Stroke, Thickness = 1, Transparency = 0.3 })
    })

    -- Dragging
    do
        local dragging, dragStart, startPos
        header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = root.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        header.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
                local delta = input.Position - dragStart
                root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

    -- Tab API
    function Window:AddTab(tabOpts)
        tabOpts = tabOpts or {}
        local tabName = tostring(tabOpts.Name or "Tab")
        local icon = tabOpts.Icon

        local Tab = {
            Name = tabName,
            _pages = {},
            _selectedPage = nil
        }

        -- Button
        local btn = Create("TextButton", {
            Name = "Tab_" .. tabName,
            BackgroundColor3 = Theme.Button,
            AutoButtonColor = false,
            Text = "",
            Size = UDim2.fromOffset(120, 28),
            ZIndex = z + 2,
            Parent = tabBar
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
            Create("UIStroke", { Color = Theme.Stroke, Thickness = 1, Transparency = 0.3 })
        })

        local iconImg
        if icon then
            iconImg = Create("ImageLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(18,18),
                Position = UDim2.fromOffset(10, 5),
                Image = icon,
                ZIndex = z + 3,
                Parent = btn
            })
        end

        local btnLabel = Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -(icon and 34 or 16), 1, 0),
            Position = UDim2.fromOffset(icon and 32 or 8, 0),
            Text = tabName,
            Font = Fonts.Medium,
            TextSize = 14,
            TextColor3 = Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = z + 3,
            Parent = btn
        })

        btn.MouseEnter:Connect(function() T(btn, 0.12, {BackgroundColor3 = Theme.Hover}):Play() end)
        btn.MouseLeave:Connect(function()
            if Window._selectedTab ~= Tab then
                T(btn, 0.12, {BackgroundColor3 = Theme.Button}):Play()
            end
        end)

        -- Content container for tab
        local tabPageContainer = Create("Frame", {
            Name = "TabContainer_" .. tabName,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1,1),
            Visible = false,
            ZIndex = z,
            Parent = content
        })

        function Tab:Select()
            if Window._selectedTab and Window._selectedTab._button then
                T(Window._selectedTab._button, 0.12, {BackgroundColor3 = Theme.Button}):Play()
            end
            Window._selectedTab = Tab
            for _, child in ipairs(content:GetChildren()) do
                if child:IsA("Frame") then child.Visible = false end
            end
            tabPageContainer.Visible = true
            T(btn, 0.12, {BackgroundColor3 = Theme.Accent2}):Play()
            btnLabel.TextColor3 = Theme.Text
            -- select first page if any
            if not Tab._selectedPage and #Tab._pages > 0 then
                Tab._pages[1]:Select()
            end
        end

        btn.MouseButton1Click:Connect(function() Tab:Select() end)

        -- Page API (SubTab)
        function Tab:AddPage(pageOpts)
            pageOpts = pageOpts or {}
            local pageName = tostring(pageOpts.Name or "Page")
            local columns = tonumber(pageOpts.Columns) or 2
            columns = Clamp(columns, 1, 3)

            local Page = {
                Name = pageName,
                _groups = {},
                _columns = columns
            }

            local pageFrame = Create("Frame", {
                Name = "Page_" .. pageName,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1,1),
                Visible = false,
                Parent = tabPageContainer
            })

            local colHolders = {}
            do
                local padding = 10
                local colWidthScale = 1 / columns
                for i=1, columns do
                    local col = Create("ScrollingFrame", {
                        Name = "Col_" .. i,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(colWidthScale, -(padding * (columns + 1)) / columns, 1, -10),
                        Position = UDim2.new((i-1)*colWidthScale, padding * i - (padding / columns), 0, 5),
                        ScrollBarThickness = 2,
                        ScrollBarImageColor3 = Theme.Scrollbar,
                        CanvasSize = UDim2.fromOffset(0,0),
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        ScrollingDirection = Enum.ScrollingDirection.Y,
                        Parent = pageFrame
                    }, {
                        Create("UIListLayout", {
                            Padding = UDim.new(0, 8),
                            HorizontalAlignment = Enum.HorizontalAlignment.Center,
                            SortOrder = Enum.SortOrder.LayoutOrder
                        }),
                        Create("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8) })
                    })
                    colHolders[i] = col
                end
            end

            function Page:Select()
                -- hide others
                for _, p in ipairs(tabPageContainer:GetChildren()) do
                    if p:IsA("Frame") then p.Visible = false end
                end
                pageFrame.Visible = true
                Tab._selectedPage = Page
            end

            function Page:AddGroup(groupOpts)
                groupOpts = groupOpts or {}
                local gName = tostring(groupOpts.Name or "Group")
                local desc = groupOpts.Description
                local side = tonumber(groupOpts.Side) or 1
                side = Clamp(side, 1, columns)

                local Group = {
                    Name = gName,
                    _controls = {},
                }

                local gFrame = Create("Frame", {
                    Name = "Group_" .. gName,
                    BackgroundColor3 = Theme.Bg,
                    Size = UDim2.new(1, -10, 0, 60),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BorderSizePixel = 0,
                    ZIndex = z + 1,
                    Parent = colHolders[side]
                }, {
                    Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
                    Create("UIStroke", { Color = Theme.Stroke, Thickness = 1, Transparency = 0.3 }),
                    Create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10) }),
                })

                local titleLbl = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 18),
                    Text = gName,
                    Font = Fonts.Bold,
                    TextSize = 14,
                    TextColor3 = Theme.Text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = z + 2,
                    Parent = gFrame
                })

                local y = 22
                if desc and #desc > 0 then
                    local d = Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 16),
                        Position = UDim2.fromOffset(0, y),
                        Text = desc,
                        Font = Fonts.Regular,
                        TextSize = 12,
                        TextColor3 = Theme.SubText,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = z + 2,
                        Parent = gFrame
                    })
                    y = y + 20
                end

                local function nextY(h) local old = y; y = y + h + 8; return old end

                -- Small helpers
                function Group:AddLabel(opts)
                    opts = opts or {}
                    local text = tostring(opts.Text or opts.Name or "Label")
                    local h = tonumber(opts.Height) or 18
                    local lbl = Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, h),
                        Position = UDim2.fromOffset(0, nextY(h)),
                        Text = text,
                        Font = Fonts.Medium,
                        TextSize = 13,
                        TextColor3 = Theme.Text,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = gFrame
                    })
                    local Label = {
                        id = ("%s/%s/%s/%s/%s"):format(Window.Name, Tab.Name, Page.Name, Group.Name, text),
                        Set = function(_, v) lbl.Text = tostring(v) end
                    }
                    Library:_registerControl(Label)
                    table.insert(Group._controls, Label)
                    return Label
                end

                function Group:AddSeparator()
                    local h = 8
                    local line = Create("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, h),
                        Position = UDim2.fromOffset(0, nextY(h)),
                        Parent = gFrame
                    })
                    local bar = Create("Frame", {
                        BackgroundColor3 = Theme.Stroke,
                        Size = UDim2.new(1, 0, 0, 1),
                        Position = UDim2.fromScale(0, 0.5),
                        AnchorPoint = Vector2.new(0, 0.5),
                        Parent = line
                    })
                    return line
                end

                function Group:AddParagraph(opts)
                    opts = opts or {}
                    local title = tostring(opts.Name or "Paragraph")
                    local body = tostring(opts.Text or opts.Content or "")
                    local t = Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 18),
                        Position = UDim2.fromOffset(0, nextY(18)),
                        Text = title,
                        Font = Fonts.Bold,
                        TextSize = 13,
                        TextColor3 = Theme.Text,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = gFrame
                    })
                    local p = Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 0),
                        Position = UDim2.fromOffset(0, t.Position.Y.Offset + 20),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        TextWrapped = true,
                        Text = body,
                        Font = Fonts.Regular,
                        TextSize = 12,
                        TextColor3 = Theme.SubText,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = gFrame
                    })
                    local Para = {
                        id = ("%s/%s/%s/%s/%s"):format(Window.Name, Tab.Name, Page.Name, Group.Name, title),
                        Set = function(_, text) p.Text = tostring(text or "") end
                    }
                    Library:_registerControl(Para)
                    table.insert(Group._controls, Para)
                    return Para
                end

                -- Controls
                function Group:AddToggle(opts)
                    opts = opts or {}
                    local label = tostring(opts.Name or "Toggle")
                    local default = (opts.Default == true)
                    local callback = opts.Callback

                    local id = ("%s/%s/%s/%s/%s"):format(Window.Name, Tab.Name, Page.Name, Group.Name, label)

                    local row = Create("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 28),
                        Position = UDim2.fromOffset(0, nextY(28)),
                        Parent = gFrame
                    })

                    local text = Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, -40, 1, 0),
                        Text = label,
                        Font = Fonts.Medium,
                        TextSize = 13,
                        TextColor3 = Theme.Text,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = row
                    })

                    local button = Create("TextButton", {
                        BackgroundColor3 = Theme.Button,
                        AutoButtonColor = false,
                        Size = UDim2.fromOffset(36, 22),
                        Position = UDim2.new(1, -4 - 36, 0.5, 0),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Text = "",
                        Parent = row
                    }, {
                        Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                        Create("UIStroke", { Color = Theme.Stroke, Thickness = 1, Transparency = 0.3 })
                    })

                    local knob = Create("Frame", {
                        Size = UDim2.fromOffset(18, 18),
                        Position = UDim2.fromOffset(2, 2),
                        BackgroundColor3 = Theme.Text,
                        Parent = button
                    }, {
                        Create("UICorner", { CornerRadius = UDim.new(1, 0) })
                    })

                    local Toggle = {
                        id = id,
                        _value = default,
                        _signal = Signal(),
                        Get = function(self) return self._value end,
                        Set = function(self, v, silent)
                            v = (v == true)
                            self._value = v
                            if v then
                                T(button, 0.15, {BackgroundColor3 = Theme.Good}):Play()
                                T(knob, 0.15, {Position = UDim2.fromOffset(36-2-18, 2)}):Play()
                            else
                                T(button, 0.15, {BackgroundColor3 = Theme.Button}):Play()
                                T(knob, 0.15, {Position = UDim2.fromOffset(2, 2)}):Play()
                            end
                            if not silent then
                                if typeof(callback) == "function" then pcall(callback, v) end
                                self._signal:Fire(v)
                            end
                        end,
                        OnChanged = function(self, fn) return self._signal:Connect(fn) end
                    }

                    button.MouseButton1Click:Connect(function() Toggle:Set(not Toggle._value) end)

                    Toggle:Set(default, true)
                    Library:_registerControl(Toggle)
                    table.insert(Group._controls, Toggle)
                    return Toggle
                end

                function Group:AddButton(opts)
                    opts = opts or {}
                    local label = tostring(opts.Name or "Button")
                    local callback = opts.Callback
                    local compact = opts.Compact == true

                    local h = compact and 26 or 30
                    local row = Create("TextButton", {
                        BackgroundColor3 = Theme.Button,
                        AutoButtonColor = false,
                        Size = UDim2.new(1, 0, 0, h),
                        Position = UDim2.fromOffset(0, nextY(h)),
                        Text = label,
                        Font = Fonts.Medium,
                        TextSize = 13,
                        TextColor3 = Theme.Text,
                        Parent = gFrame
                    }, {
                        Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                        Create("UIStroke", { Color = Theme.Stroke, Thickness = 1, Transparency = 0.3 })
                    })
                    row.MouseEnter:Connect(function() T(row, 0.12, {BackgroundColor3 = Theme.Hover}):Play() end)
                    row.MouseLeave:Connect(function() T(row, 0.12, {BackgroundColor3 = Theme.Button}):Play() end)
                    row.MouseButton1Click:Connect(function() if typeof(callback) == "function" then pcall(callback) end end)

                    local Button = { id = ("%s/%s/%s/%s/%s"):format(Window.Name, Tab.Name, Page.Name, Group.Name, label) }
                    Library:_registerControl(Button)
                    table.insert(Group._controls, Button)
                    return Button
                end

                function Group:AddSlider(opts)
                    opts = opts or {}
                    local label = tostring(opts.Name or "Slider")
                    local min = tonumber(opts.Min) or 0
                    local max = tonumber(opts.Max) or 100
                    local default = tonumber(opts.Default or min)
                    local step = tonumber(opts.Step or 1)
                    local callback = opts.Callback

                    local id = ("%s/%s/%s/%s/%s"):format(Window.Name, Tab.Name, Page.Name, Group.Name, label)

                    local row = Create("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 44),
                        Position = UDim2.fromOffset(0, nextY(44)),
                        Parent = gFrame
                    })
                    local top = Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 18),
                        Text = label,
                        Font = Fonts.Medium,
                        TextSize = 13,
                        TextColor3 = Theme.Text,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = row
                    })

                    local valueLabel = Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0, 80, 0, 18),
                        Position = UDim2.new(1, -80, 0, 0),
                        Text = tostring(default),
                        Font = Fonts.Medium,
                        TextSize = 13,
                        TextColor3 = Theme.SubText,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        Parent = row
                    })

                    local bar = Create("Frame", {
                        BackgroundColor3 = Theme.Button,
                        Size = UDim2.new(1, 0, 0, 8),
                        Position = UDim2.fromOffset(0, 26),
                        Parent = row
                    }, {
                        Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
                        Create("UIStroke", { Color = Theme.Stroke, Thickness = 1, Transparency = 0.4 })
                    })

                    local fill = Create("Frame", {
                        BackgroundColor3 = Theme.Accent,
                        Size = UDim2.new(0, 0, 1, 0),
                        Parent = bar
                    }, {
                        Create("UICorner", { CornerRadius = UDim.new(0, 4) })
                    })

                    local Slider = {
                        id = id,
                        _value = default,
                        Get = function(self) return self._value end,
                        Set = function(self, v, silent)
                            v = Clamp(Round(v, step), min, max)
                            self._value = v
                            local pct = (v - min) / (max - min)
                            T(fill, 0.1, {Size = UDim2.new(pct, 0, 1, 0)}):Play()
                            valueLabel.Text = tostring(v)
                            if not silent and typeof(callback) == "function" then pcall(callback, v) end
                        end,
                    }

                    -- Mouse input
                    local dragging = false
                    bar.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragging = true
                            local rel = (UserInputService:GetMouseLocation().X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
                            Slider:Set(min + rel * (max - min))
                        end
                    end)
                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                    end)
                    UserInputService.InputChanged:Connect(function(input)
                        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                            local rel = (UserInputService:GetMouseLocation().X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
                            Slider:Set(min + rel * (max - min))
                        end
                    end)

                    Slider:Set(default, true)
                    Library:_registerControl(Slider)
                    table.insert(Group._controls, Slider)
                    return Slider
                end

                function Group:AddDropdown(opts)
                    opts = opts or {}
                    local label = tostring(opts.Name or "Dropdown")
                    local list = opts.Options or {}
                    local default = opts.Default
                    local callback = opts.Callback

                    local id = ("%s/%s/%s/%s/%s"):format(Window.Name, Tab.Name, Page.Name, Group.Name, label)

                    local row = Create("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 30),
                        Position = UDim2.fromOffset(0, nextY(30)),
                        Parent = gFrame
                    })
                    local text = Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0.5, -8, 1, 0),
                        Text = label,
                        Font = Fonts.Medium,
                        TextSize = 13,
                        TextColor3 = Theme.Text,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = row
                    })

                    local box = Create("TextButton", {
                        BackgroundColor3 = Theme.Button,
                        AutoButtonColor = false,
                        Size = UDim2.new(0.5, -4, 1, 0),
                        Position = UDim2.new(0.5, 4, 0, 0),
                        Text = "",
                        Parent = row
                    }, {
                        Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                        Create("UIStroke", { Color = Theme.Stroke, Thickness = 1, Transparency = 0.3 })
                    })
                    local valueLbl = Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, -24, 1, 0),
                        Position = UDim2.fromOffset(8, 0),
                        Text = default and tostring(default) or "Select...",
                        Font = Fonts.Medium,
                        TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextColor3 = Theme.SubText,
                        Parent = box
                    })
                    local arrow = Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.fromOffset(18, 18),
                        Position = UDim2.new(1, -18, 0.5, 0),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Text = "▾",
                        Font = Fonts.Medium,
                        TextSize = 14,
                        TextColor3 = Theme.Text,
                        Parent = box
                    })

                    local listFrame = Create("Frame", {
                        BackgroundColor3 = Theme.Bg,
                        BorderSizePixel = 0,
                        Size = UDim2.new(0, box.AbsoluteSize.X, 0, 0),
                        Position = UDim2.new(1, -4, 0, 0),
                        Visible = false,
                        ZIndex = (z + 100),
                        Parent = gFrame
                    }, {
                        Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                        Create("UIStroke", { Color = Theme.Stroke, Thickness = 1, Transparency = 0.3 })
                    })
                    local listScroll = Create("ScrollingFrame", {
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        Size = UDim2.new(1, -8, 1, -8),
                        Position = UDim2.new(0, 4, 0, 4),
                        CanvasSize = UDim2.fromOffset(0,0),
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        ScrollingDirection = Enum.ScrollingDirection.Y,
                        ScrollBarThickness = 2,
                        ScrollBarImageColor3 = Theme.Scrollbar,
                        ZIndex = (z + 101),
                        Parent = listFrame
                    }, {
                        Create("UIListLayout", {
                            Padding = UDim.new(0, 4),
                            SortOrder = Enum.SortOrder.LayoutOrder
                        })
                    })

                    local Dropdown = {
                        id = id,
                        _value = default,
                        _options = {},
                        Get = function(self) return self._value end,
                        Set = function(self, v, silent)
                            if v == nil then self._value = nil; valueLbl.Text = "Select..."; valueLbl.TextColor3 = Theme.SubText; return end
                            if not self._options or not table.find(self._options, v) then return end
                            self._value = v
                            valueLbl.Text = tostring(v)
                            valueLbl.TextColor3 = Theme.Text
                            if not silent and typeof(callback) == "function" then pcall(callback, v) end
                        end,
                        SetOptions = function(self, newList)
                            self._options = {}
                            for _, child in ipairs(listScroll:GetChildren()) do
                                if child:IsA("TextButton") then child:Destroy() end
                            end
                            for _, val in ipairs(newList or {}) do
                                table.insert(self._options, val)
                                local item = Create("TextButton", {
                                    BackgroundColor3 = Theme.Button,
                                    AutoButtonColor = false,
                                    Size = UDim2.new(1, 0, 0, 24),
                                    Text = tostring(val),
                                    Font = Fonts.Medium,
                                    TextSize = 12,
                                    TextColor3 = Theme.Text,
                                    Parent = listScroll,
                                    ZIndex = (z + 102)
                                }, {
                                    Create("UICorner", { CornerRadius = UDim.new(0, 6) })
                                })
                                item.MouseEnter:Connect(function() T(item, 0.12, {BackgroundColor3 = Theme.Hover}):Play() end)
                                item.MouseLeave:Connect(function() T(item, 0.12, {BackgroundColor3 = Theme.Button}):Play() end)
                                item.MouseButton1Click:Connect(function()
                                    Dropdown:Set(val)
                                    listFrame.Visible = false
                                end)
                            end
                            listFrame.Size = UDim2.new(0, math.max(140, box.AbsoluteSize.X), 0, math.min(160, #self._options * 28 + 8))
                        end
                    }

                    box.MouseButton1Click:Connect(function()
                        listFrame.Visible = not listFrame.Visible
                    end)

                    Dropdown:SetOptions(list)
                    if default ~= nil then Dropdown:Set(default, true) end

                    Library:_registerControl(Dropdown)
                    table.insert(Group._controls, Dropdown)
                    return Dropdown
                end

                function Group:AddTextbox(opts)
                    opts = opts or {}
                    local label = tostring(opts.Name or "Text")
                    local placeholder = tostring(opts.Placeholder or "")
                    local default = tostring(opts.Default or "")
                    local callback = opts.Callback

                    local id = ("%s/%s/%s/%s/%s"):format(Window.Name, Tab.Name, Page.Name, Group.Name, label)

                    local row = Create("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 30),
                        Position = UDim2.fromOffset(0, nextY(30)),
                        Parent = gFrame
                    })
                    local text = Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0.4, -8, 1, 0),
                        Text = label,
                        Font = Fonts.Medium,
                        TextSize = 13,
                        TextColor3 = Theme.Text,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = row
                    })
                    local box = Create("TextBox", {
                        BackgroundColor3 = Theme.Button,
                        Size = UDim2.new(0.6, 0, 1, 0),
                        Position = UDim2.new(0.4, 8, 0, 0),
                        ClearTextOnFocus = false,
                        PlaceholderText = placeholder,
                        Text = default,
                        Font = Fonts.Medium,
                        TextSize = 13,
                        TextColor3 = Theme.Text,
                        PlaceholderColor3 = Theme.SubText,
                        Parent = row
                    }, {
                        Create("UICorner", { CornerRadius = UDim.new(0,6) }),
                        Create("UIStroke", { Color = Theme.Stroke, Thickness = 1, Transparency = 0.3 }),
                        Create("UIPadding", { PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8) })
                    })

                    local Textbox = {
                        id = id,
                        _value = default,
                        Get = function(self) return self._value end,
                        Set = function(self, v, silent)
                            v = tostring(v or "")
                            self._value = v
                            box.Text = v
                            if not silent and typeof(callback) == "function" then pcall(callback, v) end
                        end
                    }
                    box.FocusLost:Connect(function(enterPressed)
                        Textbox:Set(box.Text)
                    end)

                    Library:_registerControl(Textbox)
                    table.insert(Group._controls, Textbox)
                    return Textbox
                end

                function Group:AddKeybind(opts)
                    opts = opts or {}
                    local label = tostring(opts.Name or "Keybind")
                    local default = opts.Default -- Enum.KeyCode or nil
                    local callback = opts.Callback

                    local id = ("%s/%s/%s/%s/%s"):format(Window.Name, Tab.Name, Page.Name, Group.Name, label)

                    local row = Create("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 30),
                        Position = UDim2.fromOffset(0, nextY(30)),
                        Parent = gFrame
                    })
                    local text = Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0.5, -8, 1, 0),
                        Text = label,
                        Font = Fonts.Medium,
                        TextSize = 13,
                        TextColor3 = Theme.Text,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = row
                    })

                    local box = Create("TextButton", {
                        BackgroundColor3 = Theme.Button,
                        AutoButtonColor = false,
                        Size = UDim2.new(0.5, -4, 1, 0),
                        Position = UDim2.new(0.5, 4, 0, 0),
                        Text = default and default.Name or "Press a key...",
                        Font = Fonts.Medium,
                        TextSize = 13,
                        TextColor3 = Theme.SubText,
                        Parent = row
                    }, {
                        Create("UICorner", { CornerRadius = UDim.new(0,6) }),
                        Create("UIStroke", { Color = Theme.Stroke, Thickness = 1, Transparency = 0.3 })
                    })

                    local waiting = false
                    local Keybind = {
                        id = id,
                        _value = default,
                        Get = function(self) return self._value end,
                        Set = function(self, keycode, silent)
                            self._value = keycode
                            box.Text = keycode and keycode.Name or "None"
                            box.TextColor3 = keycode and Theme.Text or Theme.SubText
                            if keycode ~= nil and not silent and typeof(callback) == "function" then
                                pcall(callback, keycode)
                            end
                        end
                    }
                    box.MouseButton1Click:Connect(function()
                        box.Text = "Press any key..."
                        box.TextColor3 = Theme.Text
                        waiting = true
                    end)
                    UserInputService.InputBegan:Connect(function(input, gpe)
                        if waiting and input.UserInputType == Enum.UserInputType.Keyboard then
                            waiting = false
                            Keybind:Set(input.KeyCode)
                        end
                    end)

                    Library:_registerControl(Keybind)
                    table.insert(Group._controls, Keybind)
                    return Keybind
                end

                -- Return group
                table.insert(Page._groups, Group)
                return Group
            end

            -- Alias: Page:AddSection -> Page:AddGroup
            -- Will be assigned on Page object after definition, see below when returning Page

            -- Return page
            table.insert(Tab._pages, Page)
            -- Alias on Page
            Page.AddSection = Page.AddGroup
            return Page
        end

        -- Aliases on Tab
        Tab.AddSubTab = Tab.AddPage

        Tab._button = btn
        Tab._container = tabPageContainer
        table.insert(Window._tabs, Tab)
        if not Window._selectedTab then
            Tab:Select()
        end
        return Tab
    end

    -- Alias on Window
    Window.MakeTab = Window.AddTab

    return Window
end

-- Backward-compatible aliases with improved names
-- New API: NewWindow, AddTab, AddPage, AddGroup
-- Old API compatibility:
function Library:MakeWindow(o) return self:NewWindow(o) end
-- Window:MakeTab(o) -> Window:AddTab(o) [set on window]
-- Tab:AddSubTab(o) -> Tab:AddPage(o) [set on tab]
-- SubTab:AddSection(o) -> Page:AddGroup(o) [set on page]
-- Control names (AddToggle, AddSlider, etc.) stay the same.

-- Optional: expose theme update
function Library:SetTheme(themeTable)
    for k, v in pairs(themeTable or {}) do
        if Theme[k] ~= nil then Theme[k] = v end
    end
end

return Library
