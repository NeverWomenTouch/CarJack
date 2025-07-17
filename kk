getgenv().MainColor = Color3.fromRGB(15, 15, 15)
getgenv().SecondColor = Color3.fromRGB(15, 15, 15)
getgenv().StrokeColor = Color3.fromRGB(255, 0, 255)
getgenv().DividerColor = Color3.fromRGB(128, 128, 128)
getgenv().TextColor = Color3.fromRGB(255, 255, 255)
getgenv().TextDarkColor = Color3.fromRGB(255, 255, 255)
getgenv().OtherTextColor = Color3.fromRGB(255, 255, 255)
getgenv().WindowWidth = 615
getgenv().WindowHeight = 615
function IC()
	if not getgenv().MainColor then
		getgenv().MainColor = Color3.fromRGB(15, 15, 15)
	end
	if not getgenv().SecondColor then 
		getgenv().SecondColor = Color3.fromRGB(15, 15, 15)
	end
	if not getgenv().StrokeColor then
		getgenv().StrokeColor = Color3.fromRGB(255, 0, 255) 
	end
	if not getgenv().DividerColor then
		getgenv().DividerColor = Color3.fromRGB(128, 128, 128)
	end
	if not getgenv().TextColor then
		getgenv().TextColor = Color3.fromRGB(255, 0, 255)
	end
	if not getgenv().TextDarkColor then
		getgenv().TextDarkColor = Color3.fromRGB(150, 150, 150)
	end
	if not getgenv().OtherTextColor then
		getgenv().OtherTextColor = Color3.fromRGB(255, 0, 255)
	end
end
IC()
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local HttpService = game:GetService("HttpService")
local OrionLib = {
	Elements = {},
	ThemeObjects = {},
	Connections = {},
	Flags = {},
	Themes = {
		Default = {
			Main = getgenv().MainColor,
			Second = getgenv().SecondColor,
			Stroke = getgenv().StrokeColor,
			Divider = getgenv().DividerColor,
			Text = getgenv().TextColor,
			TextDark = getgenv().TextDarkColor,
			OtherText = getgenv().OtherTextColor
		}
	},
	SelectedTheme = "Default",
	Folder = nil,
	SaveCfg = false
} 
function UpdateThemeColors()
	OrionLib.Themes.Default = {
		Main = getgenv().MainColor,
		Second = getgenv().SecondColor,
		Stroke = getgenv().StrokeColor,
		Divider = getgenv().DividerColor,
		Text = getgenv().TextColor,
		TextDark = getgenv().TextDarkColor,
		OtherText = getgenv().OtherTextColor
	}
end
function GetColor(colorName)
	local color = getgenv()[colorName]
	if not color then
		warn("Color " .. colorName .. " not found, using default")
		IC()
		color = getgenv()[colorName]
	end
	return color
end
local Icons = {}
local Success, Response = pcall(function()
	Icons = HttpService:JSONDecode(game:HttpGetAsync("https://raw.githubusercontent.com/evoincorp/lucideblox/master/src/modules/util/icons.json")).icons
end)

if not Success then
	warn("\nOrion Library - Failed to load Feather Icons. Error code: " .. Response .. "\n")
end	

local function GetIcon(IconName)
	if Icons[IconName] ~= nil then
		return Icons[IconName]
	else
		return nil
	end
end   

local Orion = Instance.new("ScreenGui")
Orion.Name = "Orion"
if syn then
	syn.protect_gui(Orion)
	Orion.Parent = game.CoreGui
else
	Orion.Parent = gethui() or game.CoreGui
end

if gethui then
	for _, Interface in ipairs(gethui():GetChildren()) do
		if Interface.Name == Orion.Name and Interface ~= Orion then
			Interface:Destroy()
		end
	end
else
	for _, Interface in ipairs(game.CoreGui:GetChildren()) do
		if Interface.Name == Orion.Name and Interface ~= Orion then
			Interface:Destroy()
		end
	end
end

function OrionLib:IsRunning()
	if gethui then
		return Orion.Parent == gethui()
	else
		return Orion.Parent == game:GetService("CoreGui")
	end

end

local function AddConnection(Signal, Function)
	if (not OrionLib:IsRunning()) then
		return
	end
	local SignalConnect = Signal:Connect(Function)
	table.insert(OrionLib.Connections, SignalConnect)
	return SignalConnect
end

task.spawn(function()
	while (OrionLib:IsRunning()) do
		wait()
	end

	for _, Connection in next, OrionLib.Connections do
		Connection:Disconnect()
	end
end)
function AddDraggingFunctionality(DragPoint, Main)
	pcall(function()
		local Dragging, DragInput, MousePos, FramePos = false

		DragPoint.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				Dragging = true
				MousePos = Input.Position
				FramePos = Main.Position

				Input.Changed:Connect(function()
					if Input.UserInputState == Enum.UserInputState.End then
						Dragging = false
					end
				end)
			end
		end)

		DragPoint.InputChanged:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
				DragInput = Input
			end
		end)

		DragPoint.InputEnded:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				Dragging = false
				DragInput = nil
			end
		end)
		
		UserInputService.InputChanged:Connect(function(Input)
			if (Input == DragInput or Input.UserInputType == Enum.UserInputType.Touch) and Dragging then
				local Delta = Input.Position - MousePos
				TweenService:Create(Main, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					Position = UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)
				}):Play()
			end
		end)
	end)
end
local function Create(Name, Properties, Children)
	local Object = Instance.new(Name)
	for i, v in next, Properties or {} do
		Object[i] = v
	end
	for i, v in next, Children or {} do
		v.Parent = Object
	end
	return Object
end

local function CreateElement(ElementName, ElementFunction)
	OrionLib.Elements[ElementName] = function(...)
		return ElementFunction(...)
	end
end

local function MakeElement(ElementName, ...)
	local NewElement = OrionLib.Elements[ElementName](...)
	return NewElement
end

local function SetProps(Element, Props)
	table.foreach(Props, function(Property, Value)
		Element[Property] = Value
	end)
	return Element
end

local function SetChildren(Element, Children)
	table.foreach(Children, function(_, Child)
		Child.Parent = Element
	end)
	return Element
end

local function Round(Number, Factor)
	if Factor == 0 then return Number end
	local Result = math.floor((Number / Factor) + 0.5) * Factor
	return tonumber(string.format("%.10g", Result))
end

local function ReturnProperty(Object)
	if Object:IsA("Frame") or Object:IsA("TextButton") then
		return "BackgroundColor3"
	end 
	if Object:IsA("ScrollingFrame") then
		return "ScrollBarImageColor3"
	end 
	if Object:IsA("UIStroke") then
		return "Color"
	end 
	if Object:IsA("TextLabel") or Object:IsA("TextBox") then
		return "TextColor3"
	end   
	if Object:IsA("ImageLabel") or Object:IsA("ImageButton") then
		return "ImageColor3"
	end   
end

local function AddThemeObject(Object, Type)
	if not OrionLib.ThemeObjects[Type] then
		OrionLib.ThemeObjects[Type] = {}
	end    
	table.insert(OrionLib.ThemeObjects[Type], Object)
	Object[ReturnProperty(Object)] = OrionLib.Themes[OrionLib.SelectedTheme][Type]
	task.spawn(function()
		while Object and Object.Parent do
			Object[ReturnProperty(Object)] = OrionLib.Themes[OrionLib.SelectedTheme][Type]
			UpdateThemeColors()
			task.wait(0.01)
		end
	end)
	
	return Object
end
local function SetTheme()
	UpdateThemeColors()
	for Name, Type in pairs(OrionLib.ThemeObjects) do
		for _, Object in pairs(Type) do
			Object[ReturnProperty(Object)] = OrionLib.Themes[OrionLib.SelectedTheme][Name]
		end    
	end    
end

local function PackColor(Color)
	return {R = Color.R * 255, G = Color.G * 255, B = Color.B * 255}
end    

local function UnpackColor(Color)
	return Color3.fromRGB(Color.R, Color.G, Color.B)
end

local function LoadCfg(Config)
	local Data = HttpService:JSONDecode(Config)
	table.foreach(Data, function(a,b)
		if OrionLib.Flags[a] then
			spawn(function() 
				if OrionLib.Flags[a].Type == "Colorpicker" then
					OrionLib.Flags[a]:Set(UnpackColor(b))
				else
					OrionLib.Flags[a]:Set(b)
				end    
			end)
		else
			warn("Orion Library Config Loader - Could not find ", a ,b)
		end
	end)
end

local function SaveCfg(Name)
	local Data = {}
	for i,v in pairs(OrionLib.Flags) do
		if v.Save then
			if v.Type == "Colorpicker" then
				Data[i] = PackColor(v.Value)
			else
				Data[i] = v.Value
			end
		end	
	end
	writefile(OrionLib.Folder .. "/" .. Name .. ".txt", tostring(HttpService:JSONEncode(Data)))
end

local WhitelistedMouse = {Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2,Enum.UserInputType.MouseButton3}
local BlacklistedKeys = {Enum.KeyCode.Unknown,Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Up,Enum.KeyCode.Left,Enum.KeyCode.Down,Enum.KeyCode.Right,Enum.KeyCode.Slash,Enum.KeyCode.Tab,Enum.KeyCode.Backspace,Enum.KeyCode.Escape}

local function CheckKey(Table, Key)
	for _, v in next, Table do
		if v == Key then
			return true
		end
	end
end

CreateElement("Corner", function(Scale, Offset)
	local Corner = Create("UICorner", {
		CornerRadius = UDim.new(Scale or 0, Offset or 10)
	})
	return Corner
end)

CreateElement("Stroke", function(Color, Thickness)
	local Stroke = Create("UIStroke", {
		Color = Color or Color3.fromRGB(255, 255, 255),
		Thickness = Thickness or 1
	})
	return Stroke
end)

CreateElement("List", function(Scale, Offset)
	local List = Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(Scale or 0, Offset or 0)
	})
	return List
end)

CreateElement("Padding", function(Bottom, Left, Right, Top)
	local Padding = Create("UIPadding", {
		PaddingBottom = UDim.new(0, Bottom or 4),
		PaddingLeft = UDim.new(0, Left or 4),
		PaddingRight = UDim.new(0, Right or 4),
		PaddingTop = UDim.new(0, Top or 4)
	})
	return Padding
end)

CreateElement("TFrame", function()
	local TFrame = Create("Frame", {
		BackgroundTransparency = 1
	})
	return TFrame
end)

CreateElement("Frame", function(Color)
	local Frame = Create("Frame", {
		BackgroundColor3 = Color or Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0
	})
	return Frame
end)

CreateElement("RoundFrame", function(Color, Scale, Offset)
	local Frame = Create("Frame", {
		BackgroundColor3 = Color or Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0
	}, {
		Create("UICorner", {
			CornerRadius = UDim.new(Scale, Offset)
		})
	})
	return Frame
end)

CreateElement("Button", function()
	local Button = Create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0
	})
	return Button
end)

CreateElement("ScrollFrame", function(Color, Width)
	local ScrollFrame = Create("ScrollingFrame", {
		BackgroundTransparency = 1,
		MidImage = "rbxassetid://7445543667",
		BottomImage = "rbxassetid://7445543667",
		TopImage = "rbxassetid://7445543667",
		ScrollBarImageColor3 = Color,
		BorderSizePixel = 0,
		ScrollBarThickness = Width,
		CanvasSize = UDim2.new(0, 0, 0, 0)
	})
	return ScrollFrame
end)

CreateElement("Image", function(ImageID)
	local ImageNew = Create("ImageLabel", {
		Image = ImageID,
		BackgroundTransparency = 1
	})

	if GetIcon(ImageID) ~= nil then
		ImageNew.Image = GetIcon(ImageID)
	end	

	return ImageNew
end)

CreateElement("ImageButton", function(ImageID)
	local Image = Create("ImageButton", {
		Image = ImageID,
		BackgroundTransparency = 1
	})
	return Image
end)

CreateElement("Label", function(Text, TextSize, Transparency)
	local Label = Create("TextLabel", {
		Text = Text or "",
		TextColor3 = Color3.fromRGB(240, 240, 240),
		TextTransparency = Transparency or 0,
		TextSize = TextSize or 15,
		Font = Enum.Font.Gotham,
		RichText = true,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left
	})
	return Label
end)

local NotificationHolder = SetProps(SetChildren(MakeElement("TFrame"), {
	SetProps(MakeElement("List"), {
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 5)
	})
}), {
	Position = UDim2.new(1, -25, 1, -25),
	Size = UDim2.new(0, 300, 1, -25),
	AnchorPoint = Vector2.new(1, 1),
	Parent = Orion
})

function OrionLib:MakeNotification(NotificationConfig)
	spawn(function()
		NotificationConfig.Name = NotificationConfig.Name or "Notification"
		NotificationConfig.Content = NotificationConfig.Content or "Test"
		NotificationConfig.Image = NotificationConfig.Image or "rbxassetid://4384403532"
		NotificationConfig.Time = NotificationConfig.Time or 15

		local NotificationParent = SetProps(MakeElement("TFrame"), {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = NotificationHolder
		})

		local NotificationFrame = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(15, 15, 15), 0, 10), {
			Parent = NotificationParent, 
			Size = UDim2.new(1, 0, 0, 0),
			Position = UDim2.new(1, -55, 0, 0),
			BackgroundTransparency = 0,
			AutomaticSize = Enum.AutomaticSize.Y
		}), {
			MakeElement("Stroke", Color3.fromRGB(93, 93, 93), 1.2),
			MakeElement("Padding", 12, 12, 12, 12),
			SetProps(MakeElement("Image", NotificationConfig.Image), {
				Size = UDim2.new(0, 20, 0, 20),
				ImageColor3 = Color3.fromRGB(240, 240, 240),
				Name = "Icon"
			}),
			SetProps(MakeElement("Label", NotificationConfig.Name, 15), {
				Size = UDim2.new(1, -30, 0, 20),
				Position = UDim2.new(0, 30, 0, 0),
				Font = Enum.Font.GothamBold,
				Name = "Title"
			}),
			SetProps(MakeElement("Label", NotificationConfig.Content, 14), {
				Size = UDim2.new(1, 0, 0, 0),
				Position = UDim2.new(0, 0, 0, 25),
				Font = Enum.Font.GothamSemibold,
				Name = "Content",
				AutomaticSize = Enum.AutomaticSize.Y,
				TextColor3 = Color3.fromRGB(255, 0, 255),
				TextWrapped = true
			})
		})

		TweenService:Create(NotificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 0, 0, 0)}):Play()

		wait(NotificationConfig.Time - 0.88)
		TweenService:Create(NotificationFrame.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
		TweenService:Create(NotificationFrame, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.6}):Play()
		wait(0.3)
		TweenService:Create(NotificationFrame.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Transparency = 0.9}):Play()
		TweenService:Create(NotificationFrame.Title, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 0.4}):Play()
		TweenService:Create(NotificationFrame.Content, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 0.5}):Play()
		wait(0.05)

		NotificationFrame:TweenPosition(UDim2.new(1, 20, 0, 0),'In','Quint',0.8,true)
		wait(1.35)
		NotificationFrame:Destroy()
	end)
end    

function OrionLib:Init()
	if OrionLib.SaveCfg then	
		pcall(function()
			if isfile(OrionLib.Folder .. "/" .. game.GameId .. ".txt") then
				LoadCfg(readfile(OrionLib.Folder .. "/" .. game.GameId .. ".txt"))
				OrionLib:MakeNotification({
					Name = "Configuration",
					Content = "Auto-loaded configuration for the game " .. game.GameId .. ".",
					Time = 5
				})
			end
		end)		
	end	
end	
local TooltipFrame = nil

local function CreateTooltip()
	if TooltipFrame then
		TooltipFrame:Destroy()
	end
	
	TooltipFrame = Create("Frame", {
		Name = "Tooltip",
		Parent = Orion,
		BackgroundColor3 = Color3.fromRGB(18, 18, 18),
		BorderSizePixel = 0,
		Size = UDim2.new(0, 200, 0, 30),
		Position = UDim2.new(0, 0, 0, 0),
		Visible = false,
		ZIndex = 10000
	})

	Create("UICorner", {
		CornerRadius = UDim.new(0, 8),
		Parent = TooltipFrame
	})

	Create("UIStroke", {
		Color = Color3.fromRGB(255, 0, 255),
		Thickness = 2,
		Transparency = 0,
		Parent = TooltipFrame
	})

	local TooltipText = Create("TextLabel", {
		Name = "TooltipText",
		Size = UDim2.new(1, -20, 1, -12),
		Position = UDim2.new(0, 10, 0, 6),
		BackgroundTransparency = 1,
		Text = "",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 13,
		Font = Enum.Font.Gotham,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		RichText = false,
		TextScaled = false,
		TextTransparency = 0,
		ZIndex = 10001,
		Parent = TooltipFrame
	})

	local Shadow = Create("Frame", {
		Name = "Shadow",
		Size = UDim2.new(1, 8, 1, 8),
		Position = UDim2.new(0, -4, 0, -4),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.75,
		BorderSizePixel = 0,
		ZIndex = 9998,
		Parent = TooltipFrame
	})

	Create("UICorner", {
		CornerRadius = UDim.new(0, 12),
		Parent = Shadow
	})

	local InnerGlow = Create("Frame", {
		Name = "InnerGlow",
		Size = UDim2.new(1, -4, 1, -4),
		Position = UDim2.new(0, 2, 0, 2),
		BackgroundColor3 = Color3.fromRGB(255, 0, 255),
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
		ZIndex = 9999,
		Parent = TooltipFrame
	})

	Create("UICorner", {
		CornerRadius = UDim.new(0, 6),
		Parent = InnerGlow
	})
	
	return TooltipFrame
end

local function ShowTooltip(text, targetFrame)
	if not text or text == "" then return end
	
	if not TooltipFrame then
		CreateTooltip()
	end
	
	local tooltipText = TooltipFrame:FindFirstChild("TooltipText")
	if not tooltipText then 
		CreateTooltip()
		tooltipText = TooltipFrame:FindFirstChild("TooltipText")
	end
	
	tooltipText.Text = tostring(text)
	tooltipText.TextTransparency = 1
	tooltipText.Visible = true
	
	local textService = game:GetService("TextService")
	local textBounds = textService:GetTextSize(
		tostring(text), 
		13, 
		Enum.Font.Gotham, 
		Vector2.new(300, math.huge)
	)
	
	local tooltipWidth = math.min(math.max(textBounds.X + 24, 120), 350)
	local tooltipHeight = math.max(textBounds.Y + 16, 32)
	
	TooltipFrame.Size = UDim2.new(0, tooltipWidth, 0, tooltipHeight)
	
	local mouse = game.Players.LocalPlayer:GetMouse()
	local screenSize = workspace.CurrentCamera.ViewportSize
	
	local tooltipX = mouse.X + 18
	local tooltipY = mouse.Y + 12
	
	if tooltipX + tooltipWidth > screenSize.X - 15 then
		tooltipX = mouse.X - tooltipWidth - 18
	end
	if tooltipY + tooltipHeight > screenSize.Y - 15 then
		tooltipY = mouse.Y - tooltipHeight - 12
	end
	
	tooltipX = math.max(15, math.min(tooltipX, screenSize.X - tooltipWidth - 15))
	tooltipY = math.max(15, math.min(tooltipY, screenSize.Y - tooltipHeight - 15))
	
	TooltipFrame.Position = UDim2.new(0, tooltipX, 0, tooltipY)
	TooltipFrame.Visible = true
	
	TooltipFrame.BackgroundTransparency = 1
	TooltipFrame.UIStroke.Transparency = 1
	TooltipFrame.Shadow.BackgroundTransparency = 1
	TooltipFrame.InnerGlow.BackgroundTransparency = 1
	tooltipText.TextTransparency = 1
	
	TooltipFrame.Size = UDim2.new(0, tooltipWidth * 0.8, 0, tooltipHeight * 0.8)
	
	TweenService:Create(TooltipFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, tooltipWidth, 0, tooltipHeight),
		BackgroundTransparency = 0
	}):Play()
	
	TweenService:Create(TooltipFrame.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Transparency = 0.1
	}):Play()
	
	TweenService:Create(TooltipFrame.Shadow, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.7
	}):Play()
	
	TweenService:Create(TooltipFrame.InnerGlow, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.85
	}):Play()
	
	task.wait(0.15)
	TweenService:Create(tooltipText, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		TextTransparency = 0
	}):Play()
end

local function HideTooltip()
	if TooltipFrame and TooltipFrame.Visible then
		local tooltipText = TooltipFrame:FindFirstChild("TooltipText")
		
		if tooltipText then
			TweenService:Create(tooltipText, TweenInfo.new(0.12, Enum.EasingStyle.Quart), {
				TextTransparency = 1
			}):Play()
		end
		
		TweenService:Create(TooltipFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
			Size = UDim2.new(0, TooltipFrame.Size.X.Offset * 0.7, 0, TooltipFrame.Size.Y.Offset * 0.7)
		}):Play()
		
		TweenService:Create(TooltipFrame.UIStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quart), {
			Transparency = 1
		}):Play()
		
		TweenService:Create(TooltipFrame.Shadow, TweenInfo.new(0.15, Enum.EasingStyle.Quart), {
			BackgroundTransparency = 1
		}):Play()
		
		TweenService:Create(TooltipFrame.InnerGlow, TweenInfo.new(0.15, Enum.EasingStyle.Quart), {
			BackgroundTransparency = 1
		}):Play()
		
		spawn(function()
			wait(0.2)
			if TooltipFrame then
				TooltipFrame.Visible = false
			end
		end)
	end
end

local function AddTooltipToElement(element, tooltipText)
	if not tooltipText or tooltipText == "" then return end
	
	local updateConnection
	local isHovering = false
	local tooltipDelayConnection
	local hoverStartTime = 0
	
	AddConnection(element.MouseEnter, function()
		isHovering = true
		hoverStartTime = tick()
		
		tooltipDelayConnection = spawn(function()
			wait(0.5)
			if isHovering and (tick() - hoverStartTime) >= 0.5 then
				ShowTooltip(tooltipText, element)
				
				updateConnection = AddConnection(RunService.Heartbeat, function()
					if TooltipFrame and TooltipFrame.Visible and isHovering then
						local mouse = game.Players.LocalPlayer:GetMouse()
						local screenSize = workspace.CurrentCamera.ViewportSize
						
						local tooltipWidth = TooltipFrame.Size.X.Offset
						local tooltipHeight = TooltipFrame.Size.Y.Offset
						
						local tooltipX = mouse.X + 18
						local tooltipY = mouse.Y + 12
						
						if tooltipX + tooltipWidth > screenSize.X - 15 then
							tooltipX = mouse.X - tooltipWidth - 18
						end
						if tooltipY + tooltipHeight > screenSize.Y - 15 then
							tooltipY = mouse.Y - tooltipHeight - 12
						end
						
						tooltipX = math.max(15, math.min(tooltipX, screenSize.X - tooltipWidth - 15))
						tooltipY = math.max(15, math.min(tooltipY, screenSize.Y - tooltipHeight - 15))
						
						TweenService:Create(TooltipFrame, TweenInfo.new(0.08, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
							Position = UDim2.new(0, tooltipX, 0, tooltipY)
						}):Play()
					end
				end)
			end
		end)
	end)
	
	AddConnection(element.MouseLeave, function()
		isHovering = false
		HideTooltip()
		
		if updateConnection then
			updateConnection:Disconnect()
			updateConnection = nil
		end
		
		if tooltipDelayConnection then
			pcall(function()
				tooltipDelayConnection:Disconnect()
			end)
		end
	end)
end
function OrionLib:MakeWindow(WindowConfig)
	local FirstTab = true
	local Minimized = false
	local Loaded = false
	local UIHidden = false

	WindowConfig = WindowConfig or {}
	WindowConfig.Name = WindowConfig.Name or "Orion Library"
	WindowConfig.ConfigFolder = WindowConfig.ConfigFolder or WindowConfig.Name
	WindowConfig.SaveConfig = WindowConfig.SaveConfig or false
	WindowConfig.HidePremium = WindowConfig.HidePremium or false
	if WindowConfig.IntroEnabled == nil then
		WindowConfig.IntroEnabled = true
	end
	WindowConfig.IntroText = WindowConfig.IntroText or "Orion Library"
	WindowConfig.CloseCallback = WindowConfig.CloseCallback or function() end
	WindowConfig.ShowIcon = WindowConfig.ShowIcon or false
	WindowConfig.Icon = WindowConfig.Icon or "rbxassetid://8834748103"
	WindowConfig.IntroIcon = WindowConfig.IntroIcon or "rbxassetid://8834748103"
	OrionLib.Folder = WindowConfig.ConfigFolder
	OrionLib.SaveCfg = WindowConfig.SaveConfig

	if WindowConfig.SaveConfig then
		if not isfolder(WindowConfig.ConfigFolder) then
			makefolder(WindowConfig.ConfigFolder)
		end	
	end

	local TabHolder = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255, 0, 255), 4), {
		Size = UDim2.new(1, 0, 1, -50)
	}), {
		MakeElement("List"),
		MakeElement("Padding", 8, 0, 0, 8)
	}), "Divider")

	AddConnection(TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		TabHolder.CanvasSize = UDim2.new(0, 0, 0, TabHolder.UIListLayout.AbsoluteContentSize.Y + 16)
	end)

	local CloseBtn = SetChildren(SetProps(MakeElement("Button"), {
		Size = UDim2.new(0.5, 0, 1, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundTransparency = 1
	}), {
		AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072725342"), {
			Position = UDim2.new(0, 9, 0, 6),
			Size = UDim2.new(0, 18, 0, 18)
		}), "Text")
	})

	local MinimizeBtn = SetChildren(SetProps(MakeElement("Button"), {
		Size = UDim2.new(0.5, 0, 1, 0),
		BackgroundTransparency = 1
	}), {
		AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072719338"), {
			Position = UDim2.new(0, 9, 0, 6),
			Size = UDim2.new(0, 18, 0, 18),
			Name = "Ico"
		}), "Text")
	})

	local DragPoint = SetProps(MakeElement("TFrame"), {
		Size = UDim2.new(1, 0, 0, 50)
	})

	local WindowStuff = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 10), {
		Size = UDim2.new(0, 150, 1, -50),
		Position = UDim2.new(0, 0, 0, 50)
	}), {
		AddThemeObject(SetProps(MakeElement("Frame"), {
			Size = UDim2.new(1, 0, 0, 10),
			Position = UDim2.new(0, 0, 0, 0)
		}), "Second"), 
		AddThemeObject(SetProps(MakeElement("Frame"), {
			Size = UDim2.new(0, 10, 1, 0),
			Position = UDim2.new(1, -10, 0, 0)
		}), "Second"), 
		AddThemeObject(SetProps(MakeElement("Frame"), {
			Size = UDim2.new(0, 1, 1, 0),
			Position = UDim2.new(1, -1, 0, 0)
		}), "Stroke"), 
		TabHolder,
		SetChildren(SetProps(MakeElement("TFrame"), {
			Size = UDim2.new(1, 0, 0, 50),
			Position = UDim2.new(0, 0, 1, -50)
		}), {
			AddThemeObject(SetProps(MakeElement("Frame"), {
				Size = UDim2.new(1, 0, 0, 1)
			}), "Stroke"), 
			AddThemeObject(SetChildren(SetProps(MakeElement("Frame"), {
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.new(0, 32, 0, 32),
				Position = UDim2.new(0, 10, 0.5, 0)
			}), {
				SetProps(MakeElement("Image", "https://www.roblox.com/headshot-thumbnail/image?userId=".. LocalPlayer.UserId .."&width=420&height=420&format=png"), {
					Size = UDim2.new(1, 0, 1, 0)
				}),
				AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://4031889928"), {
					Size = UDim2.new(1, 0, 1, 0),
				}), "Second"),
				MakeElement("Corner", 1)
			}), "Divider"),
			SetChildren(SetProps(MakeElement("TFrame"), {
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.new(0, 32, 0, 32),
				Position = UDim2.new(0, 10, 0.5, 0)
			}), {
				AddThemeObject(MakeElement("Stroke"), "Stroke"),
				MakeElement("Corner", 1)
			}),
			AddThemeObject(SetProps(MakeElement("Label", LocalPlayer.DisplayName, WindowConfig.HidePremium and 14 or 13), {
				Size = UDim2.new(1, -60, 0, 13),
				Position = WindowConfig.HidePremium and UDim2.new(0, 50, 0, 19) or UDim2.new(0, 50, 0, 12),
				Font = Enum.Font.GothamBold,
				ClipsDescendants = true
			}), "Text"),
			AddThemeObject(SetProps(MakeElement("Label", "", 12), {
				Size = UDim2.new(1, -60, 0, 12),
				Position = UDim2.new(0, 50, 1, -25),
				Visible = not WindowConfig.HidePremium
			}), "TextDark")
		}),
	}), "Second")

	local WindowName = AddThemeObject(SetProps(MakeElement("Label", WindowConfig.Name, 14), {
		Size = UDim2.new(1, -30, 2, 0),
		Position = UDim2.new(0, 25, 0, -24),
		Font = Enum.Font.GothamBlack,
		TextSize = 20
	}), "Text")

	local WindowTopBarLine = AddThemeObject(SetProps(MakeElement("Frame"), {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1)
	}), "Stroke")

	local MainWindow = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 10), {
		Parent = Orion,
		Name = "MainWindow",
		Position = UDim2.new(0.5, -307, 0.5, -172),
		Size = UDim2.new(0, getgenv().WindowWidth, 0, getgenv().WindowHeight),
		ClipsDescendants = true
	}), {
		--SetProps(MakeElement("Image", "rbxassetid://3523728077"), {
		--	AnchorPoint = Vector2.new(0.5, 0.5),
		--	Position = UDim2.new(0.5, 0, 0.5, 0),
		--	Size = UDim2.new(1, 80, 1, 320),
		--	ImageColor3 = Color3.fromRGB(33, 33, 33),
		--	ImageTransparency = 0.7
		--}),
		SetChildren(SetProps(MakeElement("TFrame"), {
			Size = UDim2.new(1, 0, 0, 50),
			Name = "TopBar"
		}), {
			WindowName,
			WindowTopBarLine,
			AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 7), {
				Size = UDim2.new(0, 70, 0, 30),
				Position = UDim2.new(1, -90, 0, 10)
			}), {
				AddThemeObject(MakeElement("Stroke"), "Stroke"),
				AddThemeObject(SetProps(MakeElement("Frame"), {
					Size = UDim2.new(0, 1, 1, 0),
					Position = UDim2.new(0.5, 0, 0, 0)
				}), "Stroke"), 
				CloseBtn,
				MinimizeBtn
			}), "Second"), 
		}),
		DragPoint,
		WindowStuff
	}), "Main")

	if WindowConfig.ShowIcon then
		WindowName.Position = UDim2.new(0, 50, 0, -24)
		local WindowIcon = SetProps(MakeElement("Image", WindowConfig.Icon), {
			Size = UDim2.new(0, 20, 0, 20),
			Position = UDim2.new(0, 25, 0, 15)
		})
		WindowIcon.Parent = MainWindow.TopBar
	end	

	AddDraggingFunctionality(DragPoint, MainWindow)

	AddConnection(CloseBtn.MouseButton1Up, function()
		MainWindow.Visible = false
		UIHidden = true
		OrionLib:MakeNotification({
			Name = "Interface Hidden",
			Content = "Tap RightShift to reopen the interface",
			Time = 5
		})
		WindowConfig.CloseCallback()
	end)

	AddConnection(UserInputService.InputBegan, function(Input)
		if Input.KeyCode == Enum.KeyCode.RightShift and UIHidden then
			MainWindow.Visible = true
		end
	end)

	AddConnection(MinimizeBtn.MouseButton1Up, function()
		if Minimized then
			TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, getgenv().WindowWidth, 0, getgenv().WindowHeight)}):Play()
			MinimizeBtn.Ico.Image = "rbxassetid://7072719338"
			wait(.02)
			MainWindow.ClipsDescendants = false
			WindowStuff.Visible = true
			WindowTopBarLine.Visible = true
		else
			MainWindow.ClipsDescendants = true
			WindowTopBarLine.Visible = false
			MinimizeBtn.Ico.Image = "rbxassetid://7072720870"
	
			TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, WindowName.TextBounds.X + 140, 0, 50)}):Play()
			wait(0.1)
			WindowStuff.Visible = false	
		end
		Minimized = not Minimized    
	end)

	spawn(function()
		local lastWidth = getgenv().WindowWidth
		local lastHeight = getgenv().WindowHeight
		
		while wait(0.1) do
			pcall(function()
				local mainWin = Orion:FindFirstChild("MainWindow") 
				if mainWin then
					if lastWidth ~= getgenv().WindowWidth or lastHeight ~= getgenv().WindowHeight then
						mainWin.Size = UDim2.new(0, getgenv().WindowWidth, 0, getgenv().WindowHeight)
						lastWidth = getgenv().WindowWidth
						lastHeight = getgenv().WindowHeight
					end
				end
			end)
		end
	end)

	local function LoadSequence()
		MainWindow.Visible = false
		local LoadSequenceLogo = SetProps(MakeElement("Image", WindowConfig.IntroIcon), {
			Parent = Orion,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.4, 0),
			Size = UDim2.new(0, 28, 0, 28),
			ImageColor3 = Color3.fromRGB(255, 255, 255),
			ImageTransparency = 1
		})

		local LoadSequenceText = SetProps(MakeElement("Label", WindowConfig.IntroText, 14), {
			Parent = Orion,
			Size = UDim2.new(1, 0, 1, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 19, 0.5, 0),
			TextXAlignment = Enum.TextXAlignment.Center,
			Font = Enum.Font.GothamBold,
			TextTransparency = 1
		})

		TweenService:Create(LoadSequenceLogo, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0, Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
		wait(0.8)
		TweenService:Create(LoadSequenceLogo, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -(LoadSequenceText.TextBounds.X/2), 0.5, 0)}):Play()
		wait(0.3)
		TweenService:Create(LoadSequenceText, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
		wait(2)
		TweenService:Create(LoadSequenceText, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
		MainWindow.Visible = true
		LoadSequenceLogo:Destroy()
		LoadSequenceText:Destroy()
	end 

	if WindowConfig.IntroEnabled then
		LoadSequence()
	end	

	local TabFunction = {}
	function TabFunction:MakeTab(TabConfig)
		TabConfig = TabConfig or {}
		TabConfig.Name = TabConfig.Name or "Tab"
		TabConfig.Icon = TabConfig.Icon or ""
		TabConfig.PremiumOnly = TabConfig.PremiumOnly or false

		local TabFrame = SetChildren(SetProps(MakeElement("Button"), {
			Size = UDim2.new(1, 0, 0, 30),
			Parent = TabHolder
		}), {
			AddThemeObject(SetProps(MakeElement("Image", TabConfig.Icon), {
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.new(0, 18, 0, 18),
				Position = UDim2.new(0, 10, 0.5, 0),
				ImageTransparency = 0.4,
				Name = "Ico"
			}), "Text"),
			AddThemeObject(SetProps(MakeElement("Label", TabConfig.Name, 14), {
				Size = UDim2.new(1, -35, 1, 0),
				Position = UDim2.new(0, 35, 0, 0),
				Font = Enum.Font.GothamSemibold,
				TextTransparency = 0.4,
				Name = "Title"
			}), "Text")
		})

		if GetIcon(TabConfig.Icon) ~= nil then
			TabFrame.Ico.Image = GetIcon(TabConfig.Icon)
		end	

		local Container = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255, 255, 255), 5), {
			Size = UDim2.new(1, -150, 1, -50),
			Position = UDim2.new(0, 150, 0, 50),
			Parent = MainWindow,
			Visible = false,
			Name = "ItemContainer"
		}), {
			MakeElement("List", 0, 6),
			MakeElement("Padding", 15, 10, 10, 15)
		}), "Divider")

		AddConnection(Container.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
			Container.CanvasSize = UDim2.new(0, 0, 0, Container.UIListLayout.AbsoluteContentSize.Y + 30)
		end)

		if FirstTab then
			FirstTab = false
			TabFrame.Ico.ImageTransparency = 0
			TabFrame.Title.TextTransparency = 0
			TabFrame.Title.Font = Enum.Font.GothamBlack
			Container.Visible = true
		end    

		AddConnection(TabFrame.MouseButton1Click, function()
			for _, Tab in next, TabHolder:GetChildren() do
				if Tab:IsA("TextButton") then
					Tab.Title.Font = Enum.Font.GothamSemibold
					TweenService:Create(Tab.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 0.4}):Play()
					TweenService:Create(Tab.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0.4}):Play()
				end    
			end
			for _, ItemContainer in next, MainWindow:GetChildren() do
				if ItemContainer.Name == "ItemContainer" then
					ItemContainer.Visible = false
				end    
			end  
			TweenService:Create(TabFrame.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
			TweenService:Create(TabFrame.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
			TabFrame.Title.Font = Enum.Font.GothamBlack
			Container.Visible = true   
		end)

		local function GetElements(ItemParent)
			local ElementFunction = {}
			function ElementFunction:AddLabel(Text)
				local LabelFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundTransparency = 0.7,
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", Text, 15), {
						Size = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content"
					}), "Text"),
					AddThemeObject(MakeElement("Stroke"), "Stroke")
				}), "Second")

				local LabelFunction = {}
				function LabelFunction:Set(ToChange)
					LabelFrame.Content.Text = ToChange
				end
				return LabelFunction
			end
			
			function ElementFunction:AddParagraph(Text, Content)
				Text = Text or "Text"
				Content = Content or "Content"

				local ParagraphFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundTransparency = 0.7,
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", Text, 15), {
						Size = UDim2.new(1, -12, 0, 14),
						Position = UDim2.new(0, 12, 0, 10),
						Font = Enum.Font.GothamBold,
						Name = "Title"
					}), "Text"),
					AddThemeObject(SetProps(MakeElement("Label", "", 13), {
						Size = UDim2.new(1, -24, 0, 0),
						Position = UDim2.new(0, 12, 0, 26),
						Font = Enum.Font.GothamSemibold,
						Name = "Content",
						TextWrapped = true
					}), "TextDark"),
					AddThemeObject(MakeElement("Stroke"), "Stroke")
				}), "Second")

				AddConnection(ParagraphFrame.Content:GetPropertyChangedSignal("Text"), function()
					ParagraphFrame.Content.Size = UDim2.new(1, -24, 0, ParagraphFrame.Content.TextBounds.Y)
					ParagraphFrame.Size = UDim2.new(1, 0, 0, ParagraphFrame.Content.TextBounds.Y + 35)
				end)

				ParagraphFrame.Content.Text = Content

				local ParagraphFunction = {}
				function ParagraphFunction:Set(ToChange)
					ParagraphFrame.Content.Text = ToChange
				end
				return ParagraphFunction
			end    

			function ElementFunction:AddButton(ButtonConfig)
				ButtonConfig = ButtonConfig or {}
				ButtonConfig.Name = ButtonConfig.Name or "Button"
				ButtonConfig.Callback = ButtonConfig.Callback or function() end
				ButtonConfig.Icon = ButtonConfig.Icon or "rbxassetid://3944703587"
				ButtonConfig.ToolTip = ButtonConfig.ToolTip or ""

				local Button = {}

				local Click = SetProps(MakeElement("Button"), {
					Size = UDim2.new(1, 0, 1, 0)
				})

				local ButtonFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
					Size = UDim2.new(1, 0, 0, 33),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", ButtonConfig.Name, 15), {
						Size = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content"
					}), "Text"),
					AddThemeObject(SetProps(MakeElement("Image", ButtonConfig.Icon), {
						Size = UDim2.new(0, 20, 0, 20),
						Position = UDim2.new(1, -30, 0, 7),
					}), "TextDark"),
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					Click
				}), "Second")

				AddConnection(Click.MouseEnter, function()
					TweenService:Create(ButtonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)}):Play()
				end)

				AddConnection(Click.MouseLeave, function()
					TweenService:Create(ButtonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second}):Play()
				end)

				AddConnection(Click.MouseButton1Up, function()
					TweenService:Create(ButtonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)}):Play()
					spawn(function()
						ButtonConfig.Callback()
					end)
				end)

				AddConnection(Click.MouseButton1Down, function()
					TweenService:Create(ButtonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 6, OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 6, OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 6)}):Play()
				end)

				function Button:Set(ButtonText)
					ButtonFrame.Content.Text = ButtonText
				end	

				if ButtonConfig.ToolTip and ButtonConfig.ToolTip ~= "" then
					AddTooltipToElement(ButtonFrame, ButtonConfig.ToolTip)
				end

				return Button
			end
			function ElementFunction:AddToggle(ToggleConfig)
				ToggleConfig = ToggleConfig or {}
				ToggleConfig.Name = ToggleConfig.Name or "Toggle"
				ToggleConfig.Default = ToggleConfig.Default or false
				ToggleConfig.Callback = ToggleConfig.Callback or function() end
				ToggleConfig.Color = Color3.fromRGB(255, 0, 255)
				ToggleConfig.ColorOff = Color3.fromRGB(15, 15, 15)
				ToggleConfig.Flag = ToggleConfig.Flag or nil
				ToggleConfig.Save = ToggleConfig.Save or false
				ToggleConfig.ToolTip = ToggleConfig.ToolTip or ""

				local Toggle = {Value = ToggleConfig.Default, Save = ToggleConfig.Save, Animating = false, Type = "Toggle"}

				local SWITCH_WIDTH = 46
				local SWITCH_HEIGHT = 24
				local CIRCLE_SIZE = 18
				local PADDING = 3

				local Click = SetProps(MakeElement("Button"), {
					Size = UDim2.new(1, 0, 1, 0)
				})

				local ToggleSwitch = Create("Frame", {
					Size = UDim2.new(0, SWITCH_WIDTH, 0, SWITCH_HEIGHT),
					Position = UDim2.new(1, -SWITCH_WIDTH - 12, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Toggle.Value and ToggleConfig.Color or ToggleConfig.ColorOff,
					BorderSizePixel = 0,
					Name = "Switch"
				})

				local switchClickDetector = Create("TextButton", {
					Size = UDim2.new(1, 0, 1, 0),
					Position = UDim2.new(0, 0, 0, 0),
					BackgroundTransparency = 1,
					Text = "",
					Parent = ToggleSwitch
				})

				Create("UICorner", {
					CornerRadius = UDim.new(1, 0),
					Parent = ToggleSwitch
				})

				local switchStroke = Create("UIStroke", {
					Color = ToggleConfig.Color,
					Thickness = 1,
					Transparency = Toggle.Value and 1 or 0.3,
					Parent = ToggleSwitch
				})

				local ToggleCircle = Create("Frame", {
					Size = UDim2.new(0, CIRCLE_SIZE, 0, CIRCLE_SIZE),
					Position = UDim2.new(0, PADDING, 0, PADDING),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BorderSizePixel = 0,
					ZIndex = 2,
					Parent = ToggleSwitch,
					Name = "Circle"
				})

				Create("UICorner", {
					CornerRadius = UDim.new(1, 0),
					Parent = ToggleCircle
				})

				local circleShadow = Create("UIStroke", {
					Color = Color3.fromRGB(0, 0, 0),
					Thickness = 1,
					Transparency = 0.8,
					Parent = ToggleCircle
				})

				local circleGlow = Create("Frame", {
					Size = UDim2.new(0, CIRCLE_SIZE + 8, 0, CIRCLE_SIZE + 8),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = ToggleConfig.Color,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 1,
					Parent = ToggleCircle,
					Name = "Glow"
				})

				Create("UICorner", {
					CornerRadius = UDim.new(1, 0),
					Parent = circleGlow
				})

				if Toggle.Value then
					ToggleCircle.Position = UDim2.new(0, SWITCH_WIDTH - CIRCLE_SIZE - PADDING, 0, PADDING)
				else
					ToggleCircle.Position = UDim2.new(0, PADDING, 0, PADDING)
				end

				local ToggleFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
					Size = UDim2.new(1, 0, 0, 38),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", ToggleConfig.Name, 15), {
						Size = UDim2.new(1, -70, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content"
					}), "Text"),
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					ToggleSwitch,
					Click
				}), "Second")

				local function updateToggle(animate)
					local targetColor = Toggle.Value and ToggleConfig.Color or ToggleConfig.ColorOff
					local targetPos = Toggle.Value and 
						UDim2.new(0, SWITCH_WIDTH - CIRCLE_SIZE - PADDING, 0, PADDING) or 
						UDim2.new(0, PADDING, 0, PADDING)
					local targetStrokeTransparency = Toggle.Value and 1 or 0.3

					if animate and not Toggle.Animating then
						Toggle.Animating = true
						
						local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
						
						TweenService:Create(ToggleSwitch, tweenInfo, {
							BackgroundColor3 = targetColor
						}):Play()
						
						local moveTween = TweenService:Create(ToggleCircle, tweenInfo, {
							Position = targetPos
						})
						moveTween:Play()
						
						TweenService:Create(switchStroke, tweenInfo, {
							Transparency = targetStrokeTransparency
						}):Play()

						if Toggle.Value then
							TweenService:Create(circleGlow, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
								BackgroundTransparency = 0.6,
								Size = UDim2.new(0, CIRCLE_SIZE + 12, 0, CIRCLE_SIZE + 12)
							}):Play()
							
							spawn(function()
								wait(0.1)
								TweenService:Create(circleGlow, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
									BackgroundTransparency = 1,
									Size = UDim2.new(0, CIRCLE_SIZE + 8, 0, CIRCLE_SIZE + 8)
								}):Play()
							end)
						end

						TweenService:Create(ToggleCircle, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
							Size = UDim2.new(0, CIRCLE_SIZE + 3, 0, CIRCLE_SIZE + 3)
						}):Play()
						
						spawn(function()
							wait(0.15)
							TweenService:Create(ToggleCircle, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
								Size = UDim2.new(0, CIRCLE_SIZE, 0, CIRCLE_SIZE)
							}):Play()
						end)

						TweenService:Create(ToggleSwitch, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
							Size = UDim2.new(0, SWITCH_WIDTH + 2, 0, SWITCH_HEIGHT + 1)
						}):Play()
						
						spawn(function()
							wait(0.1)
							TweenService:Create(ToggleSwitch, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
								Size = UDim2.new(0, SWITCH_WIDTH, 0, SWITCH_HEIGHT)
							}):Play()
						end)

						moveTween.Completed:Connect(function()
							Toggle.Animating = false
							ToggleConfig.Callback(Toggle.Value)
						end)
					else
						ToggleSwitch.BackgroundColor3 = targetColor
						ToggleCircle.Position = targetPos
						switchStroke.Transparency = targetStrokeTransparency
						if not animate then
							ToggleConfig.Callback(Toggle.Value)
						end
					end
				end

				local function doToggle()
					if Toggle.Animating then return end
					Toggle.Value = not Toggle.Value
					updateToggle(true)
					
					if ToggleConfig.Save then
						SaveCfg(game.GameId)
					end
				end

				function Toggle:Set(Value)
					if Toggle.Animating then return end
					if Toggle.Value == Value then return end
					
					Toggle.Value = Value
					updateToggle(true)
				end

				AddConnection(switchClickDetector.MouseButton1Click, function()
					doToggle()
				end)

				AddConnection(Click.MouseButton1Click, function()
					doToggle()
				end)

				AddConnection(switchClickDetector.MouseEnter, function()
					if not Toggle.Animating then
						TweenService:Create(ToggleSwitch, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
							BackgroundColor3 = ToggleSwitch.BackgroundColor3:Lerp(Color3.fromRGB(255, 255, 255), 0.15)
						}):Play()
						
						if not Toggle.Value then
							TweenService:Create(switchStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
								Transparency = 0.1
							}):Play()
						end
					end
				end)

				AddConnection(switchClickDetector.MouseLeave, function()
					if not Toggle.Animating then
						TweenService:Create(ToggleSwitch, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
							BackgroundColor3 = Toggle.Value and ToggleConfig.Color or ToggleConfig.ColorOff
						}):Play()
						
						TweenService:Create(switchStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
							Transparency = Toggle.Value and 1 or 0.3
						}):Play()
					end
				end)

				AddConnection(Click.MouseEnter, function()
					TweenService:Create(ToggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)}):Play()
				end)

				AddConnection(Click.MouseLeave, function()
					TweenService:Create(ToggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second}):Play()
				end)

				updateToggle(false)
				
				if ToggleConfig.Flag then
					OrionLib.Flags[ToggleConfig.Flag] = Toggle
				end
				if ToggleConfig.ToolTip and ToggleConfig.ToolTip ~= "" then
					AddTooltipToElement(ToggleFrame, ToggleConfig.ToolTip)
				end
				
				return Toggle
			end
			function ElementFunction:AddSlider(SliderConfig)
				SliderConfig = SliderConfig or {}
				SliderConfig.Name = SliderConfig.Name or "Slider"
				SliderConfig.Min = SliderConfig.Min or 0
				SliderConfig.Max = SliderConfig.Max or 100
				SliderConfig.Increment = SliderConfig.Increment or 1
				SliderConfig.Counter = SliderConfig.Counter or ""
				SliderConfig.Default = SliderConfig.Default or 50
				SliderConfig.Callback = SliderConfig.Callback or function() end
				SliderConfig.ValueName = SliderConfig.ValueName or ""
				SliderConfig.Color = SliderConfig.Color or Color3.fromRGB(255, 0, 255)
				SliderConfig.Flag = SliderConfig.Flag or nil
				SliderConfig.Save = SliderConfig.Save or false
				SliderConfig.ToolTip = SliderConfig.ToolTip or ""

				local Slider = {
					Value = SliderConfig.Default, 
					Save = SliderConfig.Save, 
					Type = "Slider",
					Config = SliderConfig
				}
				local Dragging = false
				local ValueScale = (Slider.Value - SliderConfig.Min) / (SliderConfig.Max - SliderConfig.Min)
				local Editing = false                local function FormatValue()
					local valueText = tostring(Slider.Value)
					
					if Slider.Config.Counter and Slider.Config.Counter ~= "" and Slider.Config.Counter ~= "%" then
						valueText = valueText .. Slider.Config.Counter
					end
					
					if Slider.Config.ValueName and Slider.Config.ValueName ~= "" then
						valueText = valueText .. " " .. Slider.Config.ValueName
					end
					
					return valueText
				end

				local valueText = FormatValue()
				local textWidth = math.max(65, game:GetService("TextService"):GetTextSize(valueText, 14, Enum.Font.GothamBold, Vector2.new(math.huge, 18)).X + 18)

				local ValueDisplay = AddThemeObject(SetProps(MakeElement("Label", valueText, 14), {
					Size = UDim2.new(0, textWidth, 0, 18),
					Position = UDim2.new(1, -textWidth - 10, 0, 28),
					Font = Enum.Font.GothamBold,
					Name = "Value",
					TextXAlignment = Enum.TextXAlignment.Right,
					BackgroundTransparency = 1
				}), "Text")
				
				local ValueTextbox = Create("TextBox", {
					Size = UDim2.new(1, 0, 1, 0),
					Position = UDim2.new(0, 0, 0, 0),
					BackgroundTransparency = 1,
					Text = tostring(Slider.Value),
					Font = Enum.Font.GothamBold,
					TextSize = 14,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					Visible = false,
					Name = "ValueInput",
					Parent = ValueDisplay,
					TextXAlignment = Enum.TextXAlignment.Right,
					ClearTextOnFocus = false,
					ZIndex = 10
				})
				
				local SliderBar = AddThemeObject(SetProps(MakeElement("RoundFrame", Color3.fromRGB(40, 40, 45), 0, 5), {
					Size = UDim2.new(1, -textWidth - 25, 0, 6),
					Position = UDim2.new(0, 12, 0, 34),
					BackgroundTransparency = 0
				}), "Divider")
				
				local function UpdateSliderLayout()
					local newValueText = FormatValue()
					local newTextWidth = math.max(65, game:GetService("TextService"):GetTextSize(newValueText, 14, Enum.Font.GothamBold, Vector2.new(math.huge, 18)).X + 18)
					
					ValueDisplay.Size = UDim2.new(0, newTextWidth, 0, 18)
					ValueDisplay.Position = UDim2.new(1, -newTextWidth - 10, 0, 28)
					SliderBar.Size = UDim2.new(1, -newTextWidth - 25, 0, 6)
				end
				
				local SliderStroke = SetProps(MakeElement("Stroke"), {
					Color = SliderConfig.Color,
					Transparency = 0.2,
					Parent = SliderBar
				})
				
				local SliderFill = SetChildren(SetProps(MakeElement("RoundFrame", SliderConfig.Color, 0, 5), {
					Size = UDim2.new(ValueScale, 0, 1, 0),
					BackgroundTransparency = 0,
					ClipsDescendants = true,
					Name = "Fill"
				}), {
					SetProps(Create("UIGradient", {
						Rotation = 90,
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromRGB(210, 80, 210)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 0, 150))
						})
					}), {Name = "Gradient"})
				})
				SliderFill.Parent = SliderBar
				
				local SliderDot = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 10), {
					Size = UDim2.new(0, 16, 0, 16),
					Position = UDim2.new(ValueScale, 0, 0.5, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 0,
					ZIndex = 3,
					Name = "Dot"
				}), {
					SetProps(MakeElement("Stroke"), {
						Color = SliderConfig.Color,
						Thickness = 1.5,
						Transparency = 0,
						Name = "Rim"
					}),
					SetProps(Create("UIGradient", {
						Rotation = 135,
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromRGB(250, 250, 255)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(240, 220, 240))
						})
					}), {Name = "Gradient"})
				})
				SliderDot.Parent = SliderBar
				
				local SliderFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 4), {
					Size = UDim2.new(1, 0, 0, 55),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", SliderConfig.Name, 15), {
						Size = UDim2.new(1, -12, 0, 14),
						Position = UDim2.new(0, 12, 0, 10),
						Font = Enum.Font.GothamBold,
						Name = "Title"
					}), "Text"),
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					SliderBar,
					ValueDisplay    }), "Second")
				
				ValueDisplay.InputBegan:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Editing then
						Editing = true
						ValueDisplay.Text = ""
						ValueTextbox.Text = tostring(Slider.Value)
						ValueTextbox.Visible = true
						wait(0.1)
						ValueTextbox:CaptureFocus()
					end
				end)
				
				ValueTextbox.Focused:Connect(function()
					Editing = true
					ValueTextbox.Text = tostring(Slider.Value)
				end)
				
				ValueTextbox.FocusLost:Connect(function(enterPressed)
					Editing = false
					ValueTextbox.Visible = false
					
					local inputValue = tonumber(ValueTextbox.Text)
					if inputValue then
						Slider:Set(inputValue)
						if SliderConfig.Save then
							SaveCfg(game.GameId)
						end
					else
						ValueDisplay.Text = FormatValue()
					end
				end)
				
				function Slider:Set(Value)
					local clampedValue = math.clamp(Value, SliderConfig.Min, SliderConfig.Max)
					
					if SliderConfig.Increment > 0 then
						local steps = math.floor((clampedValue - SliderConfig.Min) / SliderConfig.Increment + 0.5)
						self.Value = SliderConfig.Min + (steps * SliderConfig.Increment)
						self.Value = tonumber(string.format("%.10g", self.Value))
					else
						self.Value = clampedValue
					end
					
					local ValueScale = (self.Value - SliderConfig.Min) / (SliderConfig.Max - SliderConfig.Min)
					
					TweenService:Create(SliderFill, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(ValueScale, 0, 1, 0)}):Play()
					TweenService:Create(SliderDot, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(ValueScale, 0, 0.5, 0)}):Play()
					
					ValueDisplay.Text = FormatValue()
					ValueTextbox.Text = tostring(self.Value)
					
					UpdateSliderLayout()
					
					SliderConfig.Callback(self.Value)
				end
				
				SliderBar.InputBegan:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
						if Editing then return end
						Dragging = true
						
						local SizeScale = math.clamp((Input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
						Slider:Set(SliderConfig.Min + ((SliderConfig.Max - SliderConfig.Min) * SizeScale))
						
						TweenService:Create(SliderDot, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 14, 0, 14)}):Play()
						TweenService:Create(SliderDot.Rim, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Thickness = 2}):Play()
						
						if SliderConfig.Save then
							SaveCfg(game.GameId)
						end
					end
				end)
				
				SliderDot.InputBegan:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
						if Editing then return end
						Dragging = true
						
						TweenService:Create(SliderDot, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 14, 0, 14)}):Play()
						TweenService:Create(SliderDot.Rim, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Thickness = 2}):Play()
					end
				end)
				
				UserInputService.InputChanged:Connect(function(Input)
					if Dragging and not Editing and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
						local SizeScale = math.clamp((Input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
						Slider:Set(SliderConfig.Min + ((SliderConfig.Max - SliderConfig.Min) * SizeScale))
						
						if SliderConfig.Save then
							SaveCfg(game.GameId)
						end
					end
				end)
				
				UserInputService.InputEnded:Connect(function(Input)
					if Dragging and (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) then
						Dragging = false
						
						TweenService:Create(SliderDot, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 16, 0, 16)}):Play()
						TweenService:Create(SliderDot.Rim, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Thickness = 1.5}):Play()
					end
				end)
				
				Slider:Set(Slider.Value)
				
				if SliderConfig.Flag then
					OrionLib.Flags[SliderConfig.Flag] = Slider
				end
				
				if SliderConfig.ToolTip and SliderConfig.ToolTip ~= "" then
					AddTooltipToElement(SliderFrame, SliderConfig.ToolTip)
				end
				
				return Slider
			end

			function ElementFunction:AddDropdown(DropdownConfig)
			DropdownConfig = DropdownConfig or {}
			DropdownConfig.Name = DropdownConfig.Name or "Dropdown"
			DropdownConfig.Options = DropdownConfig.Options or {}
			DropdownConfig.Multi = DropdownConfig.Multi or false
			DropdownConfig.Default = DropdownConfig.Default or (DropdownConfig.Multi and {} or "")
			DropdownConfig.Callback = DropdownConfig.Callback or function() end
			DropdownConfig.Flag = DropdownConfig.Flag or nil
			DropdownConfig.Save = DropdownConfig.Save or false
			DropdownConfig.ToolTip = DropdownConfig.ToolTip or ""

			local Dropdown = {
				Value = DropdownConfig.Multi and {} or "",
				Options = DropdownConfig.Options,
				Buttons = {},
				Toggled = false,
				Save = DropdownConfig.Save
			}
			
			local function InitializeDropdownState()
				Dropdown.Toggled = false
				if DropdownFrame then
					DropdownFrame.F.Line.Visible = false
					if DropdownFrame.F.Ico then
						DropdownFrame.F.Ico.Rotation = 0
					end
					local baseSize = 38
					DropdownFrame.Size = UDim2.new(1, 0, 0, baseSize)
				end
			end
			local MaxElements = 5

			if DropdownConfig.Multi then
				for _, v in ipairs(type(DropdownConfig.Default) == "table" and DropdownConfig.Default or {DropdownConfig.Default}) do
					if table.find(Dropdown.Options, v) then
						table.insert(Dropdown.Value, v)
					end
				end
			else
				if DropdownConfig.Default and DropdownConfig.Default ~= "" and table.find(Dropdown.Options, DropdownConfig.Default) then
					Dropdown.Value = DropdownConfig.Default
				end
			end

			local function GetSelectedText()
				if DropdownConfig.Multi then
					local count = #Dropdown.Value
					if count == 0 then
						return "None Selected"
					elseif count == 1 then
						return Dropdown.Value[1]
					else
						return tostring(count) .. " Selected"
					end
				else
					return Dropdown.Value == "" and "Select Option" or Dropdown.Value
				end
			end

			local function GetSmartSelectedText()
				local dropdownNameWidth = game:GetService("TextService"):GetTextSize(DropdownConfig.Name, 15, Enum.Font.GothamBold, Vector2.new(math.huge, 18)).X
				local availableWidth = math.max(80, 280 - 12 - dropdownNameWidth - 20 - 30 - 15)
				
				if DropdownConfig.Multi then
					local count = #Dropdown.Value
					if count == 0 then
						return "..."
					else
						return tostring(count)
					end
				else
					if Dropdown.Value == "" then
						return "..."
					else
						local textWidth = game:GetService("TextService"):GetTextSize(Dropdown.Value, 13, Enum.Font.Gotham, Vector2.new(math.huge, 18)).X
						if textWidth > availableWidth then
							return "..."
						else
							return Dropdown.Value
						end
					end
				end
			end

			function ShouldExpandDropdown()
				if DropdownConfig.Multi then
					return false
				else
					if Dropdown.Value == "" then
						return false
					else
						local dropdownNameWidth = game:GetService("TextService"):GetTextSize(DropdownConfig.Name, 15, Enum.Font.GothamBold, Vector2.new(math.huge, 18)).X
						local availableWidth = math.max(80, 280 - 12 - dropdownNameWidth - 20 - 30 - 15)
						local textWidth = game:GetService("TextService"):GetTextSize(Dropdown.Value, 13, Enum.Font.Gotham, Vector2.new(math.huge, 18)).X
						return textWidth > availableWidth
					end
				end
			end

			local DropdownList = MakeElement("List")
			local DropdownContainer = AddThemeObject(SetProps(SetChildren(MakeElement("ScrollFrame", Color3.fromRGB(255,0,255),4), {DropdownList}), {
				Parent = ItemParent,
				Position = UDim2.new(0,0,0,38),
				Size = UDim2.new(1,0,1,-38),
				ClipsDescendants = true
			}), "Divider")
			
			local ExpandedTextLabel = AddThemeObject(SetProps(MakeElement("Label", "", 13), {
				Size = UDim2.new(1, -24, 0, 0),
				Position = UDim2.new(0, 12, 0, 46),
				Font = Enum.Font.Gotham,
				Name = "ExpandedText",
				TextWrapped = true,
				Visible = false
			}), "OtherText")
			
			local Click = SetProps(MakeElement("Button"), {Size = UDim2.new(1,0,1,0)})
			local DropdownFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255,0,255),0,5), {
				Size = UDim2.new(1,0,0,38),
				Parent = ItemParent,
				ClipsDescendants = true
			}), {
				DropdownContainer,
				SetProps(SetChildren(MakeElement("TFrame"), {
					AddThemeObject(SetProps(MakeElement("Label", DropdownConfig.Name, 15), {
						Size = UDim2.new(1,-12,1,0),
						Position = UDim2.new(0,12,0,0),
						Font = Enum.Font.GothamBold,
						Name = "Content"
					}), "Text"),
					AddThemeObject(SetProps(MakeElement("Image","rbxassetid://7072706796"), {
						Size = UDim2.new(0,20,0,20),
						AnchorPoint = Vector2.new(0,0.5),
						Position = UDim2.new(1,-30,0.5,0),
						ImageColor3 = Color3.fromRGB(255,0,255),
						Name = "Ico"
					}), "OtherText"),
					AddThemeObject(SetProps(MakeElement("Label", GetSmartSelectedText(), 13), {
						Size = UDim2.new(1,-40,1,0),
						Font = Enum.Font.Gotham,
						Name = "Selected",
						TextXAlignment = Enum.TextXAlignment.Right
					}), "OtherText"),
					AddThemeObject(SetProps(MakeElement("Frame"), {
						Size = UDim2.new(1,0,0,1),
						Position = UDim2.new(0,0,1,-1),
						Name = "Line",
						Visible = false
					}), "Stroke"),
					Click
				}), {
					Size = UDim2.new(1,0,0,38),
					ClipsDescendants = true,
					Name = "F"
				}),
				ExpandedTextLabel,
				AddThemeObject(MakeElement("Stroke"), "Stroke"),
				MakeElement("Corner")
			}), "Second")

			AddConnection(DropdownList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
				DropdownContainer.CanvasSize = UDim2.new(0,0,0,DropdownList.AbsoluteContentSize.Y)
			end)

			local function UpdateDropdownLayout()
				local shouldExpand = ShouldExpandDropdown()
				ExpandedTextLabel.Visible = shouldExpand
				
				local baseSize = 38
				if shouldExpand then
					ExpandedTextLabel.Text = Dropdown.Value
					local textHeight = game:GetService("TextService"):GetTextSize(Dropdown.Value, 13, Enum.Font.Gotham, Vector2.new(DropdownFrame.AbsoluteSize.X - 24, math.huge)).Y
					ExpandedTextLabel.Size = UDim2.new(1, -24, 0, textHeight)
					baseSize = 38 + textHeight + 16
					DropdownContainer.Position = UDim2.new(0, 0, 0, baseSize)
				else
					DropdownContainer.Position = UDim2.new(0, 0, 0, 38)
				end
				
				if Dropdown.Toggled then
					local expandedSize = #Dropdown.Options > MaxElements and baseSize + MaxElements*28 or baseSize + DropdownList.AbsoluteContentSize.Y
					DropdownFrame.Size = UDim2.new(1, 0, 0, expandedSize)
				else
					DropdownFrame.Size = UDim2.new(1, 0, 0, baseSize)
				end
				
				DropdownFrame.F.Selected.Text = GetSmartSelectedText()
			end

			function UpdateButtonVisuals(button, option, isSelected, animate)
				local t = animate and 0.15 or 0
				TweenService:Create(button, TweenInfo.new(t), {BackgroundTransparency = isSelected and 0.2 or 1}):Play()
				TweenService:Create(button.Title, TweenInfo.new(t), {TextTransparency = isSelected and 0 or 0.4}):Play()
			end

			function AddOptions(options)
				for _, option in ipairs(options) do
					local isSelected = DropdownConfig.Multi and table.find(Dropdown.Value, option) or Dropdown.Value == option
					local OptionBtn = AddThemeObject(SetProps(SetChildren(MakeElement("Button", Color3.fromRGB(255,0,255)), {
						MakeElement("Corner",0,6),
						AddThemeObject(SetProps(MakeElement("Label", option, 13, isSelected and 0 or 0.4), {
							Position = UDim2.new(0, 8, 0, 0),
							Size = UDim2.new(1, -8, 1, 0),
							Name = "Title"
						}), "Text")
					}), {
						Parent = DropdownContainer,
						Size = UDim2.new(1,0,0,28),
						BackgroundTransparency = isSelected and 0 or 1,
						ClipsDescendants = true
					}), "Divider")

					Dropdown.Buttons[option] = OptionBtn
					UpdateButtonVisuals(OptionBtn, option, isSelected, false)

					AddConnection(OptionBtn.MouseButton1Click, function()
						if DropdownConfig.Multi then
							local i = table.find(Dropdown.Value, option)
							if i then table.remove(Dropdown.Value, i) else table.insert(Dropdown.Value, option) end
						else
							Dropdown.Value = option
							Dropdown.Toggled = false
							DropdownFrame.F.Line.Visible = false
							TweenService:Create(DropdownFrame.F.Ico, TweenInfo.new(0.15), {Rotation = 0}):Play()
							
							local baseSize = ShouldExpandDropdown() and (38 + game:GetService("TextService"):GetTextSize(Dropdown.Value or "", 13, Enum.Font.Gotham, Vector2.new(DropdownFrame.AbsoluteSize.X - 24, math.huge)).Y + 16) or 38
							TweenService:Create(DropdownFrame, TweenInfo.new(0.15), {Size = UDim2.new(1,0,0,baseSize)}):Play()
						end
						for opt, btn in pairs(Dropdown.Buttons) do
							UpdateButtonVisuals(btn, opt, DropdownConfig.Multi and table.find(Dropdown.Value, opt) or Dropdown.Value == opt, true)
						end
						UpdateDropdownLayout()
						DropdownConfig.Callback(Dropdown.Value)
						if DropdownConfig.Save then SaveCfg(game.GameId) end
					end)

					AddConnection(OptionBtn.MouseEnter, function()
						local sel = DropdownConfig.Multi and table.find(Dropdown.Value, option) or Dropdown.Value == option
						TweenService:Create(OptionBtn, TweenInfo.new(0.1), {BackgroundTransparency = sel and 0.2 or 0.7}):Play()
						TweenService:Create(OptionBtn.Title, TweenInfo.new(0.1), {TextTransparency = sel and 0 or 0.2}):Play()
					end)

					AddConnection(OptionBtn.MouseLeave, function()
						UpdateButtonVisuals(OptionBtn, option, DropdownConfig.Multi and table.find(Dropdown.Value, option) or Dropdown.Value == option, true)
					end)
				end
			end

			function Dropdown:Refresh(options, delete)
				local thisDropdownContainer = DropdownContainer
				
				if delete then
					for option, btn in pairs(Dropdown.Buttons) do
						if btn and btn.Parent == thisDropdownContainer then
							btn:Destroy()
						end
					end
					table.clear(Dropdown.Options)
					table.clear(Dropdown.Buttons)
					if DropdownConfig.Multi then 
						table.clear(Dropdown.Value) 
					else
						Dropdown.Value = ""
					end
				end
				
				for _, child in pairs(thisDropdownContainer:GetChildren()) do
					if child:IsA("TextButton") then
						if child.Name ~= "UIListLayout" and child ~= DropdownList then
							child:Destroy()
						end
					end
				end
				
				Dropdown.Options = options or {}
				
				local function AddOptionsToThisDropdown(optionsList)
					for _, option in ipairs(optionsList) do
						local isSelected = DropdownConfig.Multi and table.find(Dropdown.Value, option) or Dropdown.Value == option
						local OptionBtn = AddThemeObject(SetProps(SetChildren(MakeElement("Button", Color3.fromRGB(255,0,255)), {
							MakeElement("Corner",0,6),
							AddThemeObject(SetProps(MakeElement("Label", option, 13, isSelected and 0 or 0.4), {
								Position = UDim2.new(0, 8, 0, 0),
								Size = UDim2.new(1, -8, 1, 0),
								Name = "Title"
							}), "Text")
						}), {
							Parent = thisDropdownContainer,
							Size = UDim2.new(1,0,0,28),
							BackgroundTransparency = isSelected and 0 or 1,
							ClipsDescendants = true
						}), "Divider")

						Dropdown.Buttons[option] = OptionBtn
						UpdateButtonVisuals(OptionBtn, option, isSelected, false)

						AddConnection(OptionBtn.MouseButton1Click, function()
							if DropdownConfig.Multi then
								local i = table.find(Dropdown.Value, option)
								if i then table.remove(Dropdown.Value, i) else table.insert(Dropdown.Value, option) end
							else
								Dropdown.Value = option
								Dropdown.Toggled = false
								DropdownFrame.F.Line.Visible = false
								TweenService:Create(DropdownFrame.F.Ico, TweenInfo.new(0.15), {Rotation = 0}):Play()
								
								local baseSize = ShouldExpandDropdown() and (38 + game:GetService("TextService"):GetTextSize(Dropdown.Value or "", 13, Enum.Font.Gotham, Vector2.new(DropdownFrame.AbsoluteSize.X - 24, math.huge)).Y + 16) or 38
								TweenService:Create(DropdownFrame, TweenInfo.new(0.15), {Size = UDim2.new(1,0,0,baseSize)}):Play()
							end
							for opt, btn in pairs(Dropdown.Buttons) do
								UpdateButtonVisuals(btn, opt, DropdownConfig.Multi and table.find(Dropdown.Value, opt) or Dropdown.Value == opt, true)
							end
							UpdateDropdownLayout()
							DropdownConfig.Callback(Dropdown.Value)
							if DropdownConfig.Save then SaveCfg(game.GameId) end
						end)

						AddConnection(OptionBtn.MouseEnter, function()
							local sel = DropdownConfig.Multi and table.find(Dropdown.Value, option) or Dropdown.Value == option
							TweenService:Create(OptionBtn, TweenInfo.new(0.1), {BackgroundTransparency = sel and 0.2 or 0.7}):Play()
							TweenService:Create(OptionBtn.Title, TweenInfo.new(0.1), {TextTransparency = sel and 0 or 0.2}):Play()
						end)

						AddConnection(OptionBtn.MouseLeave, function()
							UpdateButtonVisuals(OptionBtn, option, DropdownConfig.Multi and table.find(Dropdown.Value, option) or Dropdown.Value == option, true)
						end)
					end
				end
				
				AddOptionsToThisDropdown(Dropdown.Options)
				UpdateDropdownLayout()
			end

			function Dropdown:Set(value)
				if DropdownConfig.Multi then
					table.clear(Dropdown.Value)
					for _, v in ipairs(type(value)=="table" and value or {value}) do
						if table.find(Dropdown.Options, v) then table.insert(Dropdown.Value, v) end
					end
				else
					if table.find(Dropdown.Options, value) then Dropdown.Value = value end
				end
				for opt, btn in pairs(Dropdown.Buttons) do
					UpdateButtonVisuals(btn, opt, DropdownConfig.Multi and table.find(Dropdown.Value, opt) or Dropdown.Value == opt, true)
				end
				UpdateDropdownLayout()
				DropdownConfig.Callback(Dropdown.Value)
			end

			AddConnection(Click.MouseButton1Click, function()
				Dropdown.Toggled = not Dropdown.Toggled
				DropdownFrame.F.Line.Visible = Dropdown.Toggled
				TweenService:Create(DropdownFrame.F.Ico, TweenInfo.new(0.15), {Rotation = Dropdown.Toggled and 180 or 0}):Play()
				
				local baseSize = ShouldExpandDropdown() and (38 + game:GetService("TextService"):GetTextSize(Dropdown.Value or "", 13, Enum.Font.Gotham, Vector2.new(DropdownFrame.AbsoluteSize.X - 24, math.huge)).Y + 16) or 38
				local expandedSize = Dropdown.Toggled and (#Dropdown.Options > MaxElements and baseSize + MaxElements*28 or baseSize + DropdownList.AbsoluteContentSize.Y) or baseSize
				
				TweenService:Create(DropdownFrame, TweenInfo.new(0.15), {Size = UDim2.new(1,0,0,expandedSize)}):Play()
			end)

			Dropdown:Refresh(Dropdown.Options, false)
			UpdateDropdownLayout()

			if DropdownConfig.Default and DropdownConfig.Default ~= "" then
				Dropdown:Set(DropdownConfig.Default)
			end

			InitializeDropdownState() -- Ensure dropdown starts closed

			if DropdownConfig.Flag then OrionLib.Flags[DropdownConfig.Flag] = Dropdown end
			if DropdownConfig.ToolTip ~= "" then AddTooltipToElement(DropdownFrame, DropdownConfig.ToolTip) end

			return Dropdown
		end

function ElementFunction:AddBind(BindConfig)
				BindConfig.Name = BindConfig.Name or "Bind"
				BindConfig.Default = BindConfig.Default or Enum.KeyCode.Unknown
				BindConfig.Hold = BindConfig.Hold or false
				BindConfig.Callback = BindConfig.Callback or function() end
				BindConfig.Flag = BindConfig.Flag or nil
				BindConfig.Save = BindConfig.Save or false
				BindConfig.ToolTip = BindConfig.ToolTip or ""

				local Bind = {Value, Binding = false, Type = "Bind", Save = BindConfig.Save}
				local Holding = false

				local Click = SetProps(MakeElement("Button"), {
					Size = UDim2.new(1, 0, 1, 0)
				})

				local BindBox = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 4), {
					Size = UDim2.new(0, 24, 0, 24),
					Position = UDim2.new(1, -12, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5)
				}), {
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					AddThemeObject(SetProps(MakeElement("Label", BindConfig.Name, 14), {
						Size = UDim2.new(1, 0, 1, 0),
						Font = Enum.Font.GothamBold,
						TextXAlignment = Enum.TextXAlignment.Center,
						Name = "Value"
					}), "Text")
				}), "Main")

				local BindFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
					Size = UDim2.new(1, 0, 0, 38),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", BindConfig.Name, 15), {
						Size = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content"
					}), "Text"),
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					BindBox,
					Click
				}), "Second")

				AddConnection(BindBox.Value:GetPropertyChangedSignal("Text"), function()
					TweenService:Create(BindBox, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, BindBox.Value.TextBounds.X + 16, 0, 24)}):Play()
				end)

				AddConnection(Click.InputEnded, function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 then
						if Bind.Binding then return end
						Bind.Binding = true
						BindBox.Value.Text = ""
					end
				end)

				AddConnection(UserInputService.InputBegan, function(Input)
					if UserInputService:GetFocusedTextBox() then return end
					if (Input.KeyCode.Name == Bind.Value or Input.UserInputType.Name == Bind.Value) and not Bind.Binding then
						if BindConfig.Hold then
							Holding = true
							BindConfig.Callback(Holding)
						else
							BindConfig.Callback()
						end
					elseif Bind.Binding then
						local Key
						pcall(function()
							if not CheckKey(BlacklistedKeys, Input.KeyCode) then
								Key = Input.KeyCode
							end
						end)
						pcall(function()
							if CheckKey(WhitelistedMouse, Input.UserInputType) and not Key then
								Key = Input.UserInputType
							end
						end)
						Key = Key or Bind.Value
						Bind:Set(Key)
						SaveCfg(game.GameId)
					end
				end)

				AddConnection(UserInputService.InputEnded, function(Input)
					if Input.KeyCode.Name == Bind.Value or Input.UserInputType.Name == Bind.Value then
						if BindConfig.Hold and Holding then
							Holding = false
							BindConfig.Callback(Holding)
						end
					end
				end)

				AddConnection(Click.MouseEnter, function()
					TweenService:Create(BindFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)}):Play()
				end)

				AddConnection(Click.MouseLeave, function()
					TweenService:Create(BindFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second}):Play()
				end)

				AddConnection(Click.MouseButton1Up, function()
					TweenService:Create(BindFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)}):Play()
				end)

				AddConnection(Click.MouseButton1Down, function()
					TweenService:Create(BindFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 6, OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 6, OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 6)}):Play()
				end)

				function Bind:Set(Key)
					Bind.Binding = false
					Bind.Value = Key or Bind.Value
					Bind.Value = Bind.Value.Name or Bind.Value
					BindBox.Value.Text = Bind.Value
				end

				Bind:Set(BindConfig.Default)
				if BindConfig.Flag then				
					OrionLib.Flags[BindConfig.Flag] = Bind
				end
				if BindConfig.ToolTip and BindConfig.ToolTip ~= "" then
					AddTooltipToElement(BindFrame, BindConfig.ToolTip)
				end
				
				return Bind
			end
			function ElementFunction:AddTextbox(TextboxConfig)
				TextboxConfig = TextboxConfig or {}
				TextboxConfig.Name = TextboxConfig.Name or "Textbox"
				TextboxConfig.Default = TextboxConfig.Default or ""
				TextboxConfig.TextDisappear = TextboxConfig.TextDisappear or false
				TextboxConfig.Callback = TextboxConfig.Callback or function() end
				TextboxConfig.ToolTip = TextboxConfig.ToolTip or ""

				local Click = SetProps(MakeElement("Button"), {
					Size = UDim2.new(1, 0, 1, 0)
				})

				local TextboxActual = AddThemeObject(Create("TextBox", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					PlaceholderColor3 = Color3.fromRGB(210,210,210),
					PlaceholderText = "Input",
					Font = Enum.Font.GothamSemibold,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextSize = 14,
					ClearTextOnFocus = false
				}), "Text")

				local TextContainer = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 4), {
					Size = UDim2.new(0, 24, 0, 24),
					Position = UDim2.new(1, -12, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5)
				}), {
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					TextboxActual
				}), "Main")


				local TextboxFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
					Size = UDim2.new(1, 0, 0, 38),
					Parent = ItemParent
				}), {
					AddThemeObject(SetProps(MakeElement("Label", TextboxConfig.Name, 15), {
						Size = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content"
					}), "Text"),
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					TextContainer,
					Click
				}), "Second")

				AddConnection(TextboxActual:GetPropertyChangedSignal("Text"), function()
					--TextContainer.Size = UDim2.new(0, TextboxActual.TextBounds.X + 16, 0, 24)
					TweenService:Create(TextContainer, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, TextboxActual.TextBounds.X + 16, 0, 24)}):Play()
				end)

				AddConnection(TextboxActual.FocusLost, function()
					TextboxConfig.Callback(TextboxActual.Text)
					if TextboxConfig.TextDisappear then
						TextboxActual.Text = ""
					end	
				end)

				TextboxActual.Text = TextboxConfig.Default

				AddConnection(Click.MouseEnter, function()
					TweenService:Create(TextboxFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)}):Play()
				end)

				AddConnection(Click.MouseLeave, function()
					TweenService:Create(TextboxFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second}):Play()
				end)

				AddConnection(Click.MouseButton1Up, function()
					TweenService:Create(TextboxFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)}):Play()
					TextboxActual:CaptureFocus()
				end)

				AddConnection(Click.MouseButton1Down, function()
					TweenService:Create(TextboxFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 6, OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 6, OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 6)}):Play()
				end)
					if TextboxConfig.ToolTip and TextboxConfig.ToolTip ~= "" then
					AddTooltipToElement(TextboxFrame, TextboxConfig.ToolTip)
				end
			end	

			function ElementFunction:AddToggleColorPicker(ToggleColorPickerConfig)
				ToggleColorPickerConfig = ToggleColorPickerConfig or {}
				ToggleColorPickerConfig.Name = ToggleColorPickerConfig.Name or "Toggle Color Picker"
				ToggleColorPickerConfig.Default = ToggleColorPickerConfig.Default or false
				ToggleColorPickerConfig.ColorPickerDefault = ToggleColorPickerConfig.ColorPickerDefault or Color3.fromRGB(255,0,0)
				ToggleColorPickerConfig.Callback = ToggleColorPickerConfig.Callback or function() end
				ToggleColorPickerConfig.Flag = ToggleColorPickerConfig.Flag or nil
				ToggleColorPickerConfig.Save = ToggleColorPickerConfig.Save or false
				ToggleColorPickerConfig.ToolTip = ToggleColorPickerConfig.ToolTip or ""

				local ColorH, ColorS, ColorV = 1, 1, 1
				local ToggleColorPicker = {Value = ToggleColorPickerConfig.Default, ColorValue = ToggleColorPickerConfig.ColorPickerDefault, Toggled = false, Type = "ToggleColorPicker", Save = ToggleColorPickerConfig.Save}
				local RainbowMode = false
				local RainbowConnection = nil

				local SWITCH_WIDTH = 46
				local SWITCH_HEIGHT = 24
				local CIRCLE_SIZE = 18
				local PADDING = 3
				local CHECKBOX_SIZE = 20
				local TOTAL_EXPANDED_HEIGHT = 210

				local ColorSelection = Create("ImageLabel", {
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new(select(3, Color3.toHSV(ToggleColorPicker.ColorValue))),
					ScaleType = Enum.ScaleType.Fit,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = "http://www.roblox.com/asset/?id=4805639000"
				})

				local HueSelection = Create("ImageLabel", {
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new(0.5, 0, 1 - select(1, Color3.toHSV(ToggleColorPicker.ColorValue))),
					ScaleType = Enum.ScaleType.Fit,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = "http://www.roblox.com/asset/?id=4805639000"
				})

				local Color = Create("ImageLabel", {
					Size = UDim2.new(1, -25, 0, 100),
					Visible = false,
					Image = "rbxassetid://4155801252"
				}, {
					Create("UICorner", {CornerRadius = UDim.new(0, 5)}),
					ColorSelection
				})

				local Hue = Create("Frame", {
					Size = UDim2.new(0, 20, 0, 100),
					Position = UDim2.new(1, -20, 0, 0),
					Visible = false
				}, {
					Create("UIGradient", {Rotation = 270, Color = ColorSequence.new{
						ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 4)),
						ColorSequenceKeypoint.new(0.20, Color3.fromRGB(234, 255, 0)),
						ColorSequenceKeypoint.new(0.40, Color3.fromRGB(21, 255, 0)),
						ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0, 255, 255)),
						ColorSequenceKeypoint.new(0.80, Color3.fromRGB(0, 17, 255)),
						ColorSequenceKeypoint.new(0.90, Color3.fromRGB(255, 0, 251)),
						ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 4))
					}}),
					Create("UICorner", {CornerRadius = UDim.new(0, 5)}),
					HueSelection
				})

				local RainbowCheckbox = Create("Frame", {
					Size = UDim2.new(0, CHECKBOX_SIZE, 0, CHECKBOX_SIZE),
					Position = UDim2.new(0, 35, 0, 160),
					AnchorPoint = Vector2.new(0, 0),
					BackgroundColor3 = Color3.fromRGB(20, 20, 20),
					BorderSizePixel = 0,
					Name = "RainbowCheckbox",
					Visible = false
				}, {
					Create("UICorner", {CornerRadius = UDim.new(0, 4)})
				})

				local RainbowCheck = Create("ImageLabel", {
					Size = UDim2.new(0, 0, 0, 0),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = "rbxassetid://7072718162",
					ImageColor3 = ToggleColorPicker.ColorValue,
					Visible = false,
					Parent = RainbowCheckbox
				})

				local RainbowClick = Create("TextButton", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = "",
					Parent = RainbowCheckbox
				})

				local RainbowStroke = Create("UIStroke", {
					Color = ToggleColorPicker.ColorValue,
					Thickness = 1,
					Transparency = 0.5,
					Parent = RainbowCheckbox
				})

				local RainbowLabel = Create("TextLabel", {
					Size = UDim2.new(0, 100, 0, 20),
					Position = UDim2.new(1, 10, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundTransparency = 1,
					Text = "Rainbow Mode",
					TextColor3 = Color3.fromRGB(220, 220, 220),
					TextXAlignment = Enum.TextXAlignment.Left,
					Font = Enum.Font.Gotham,
					TextSize = 13,
					Parent = RainbowCheckbox
				})

				local ColorpickerContainer = Create("Frame", {
					Position = UDim2.new(0, 0, 0, 32),
					Size = UDim2.new(1, 0, 0, TOTAL_EXPANDED_HEIGHT - 38),
					BackgroundTransparency = 1,
					ClipsDescendants = true
				}, {
					Hue,
					Color,
					Create("UIPadding", {
						PaddingLeft = UDim.new(0, 35),
						PaddingRight = UDim.new(0, 35),
						PaddingBottom = UDim.new(0, 15),
						PaddingTop = UDim.new(0, 17)
					})
				})

				local Click = SetProps(MakeElement("Button"), {
					Size = UDim2.new(1, 0, 1, 0)
				})

				local ToggleSwitch = Create("Frame", {
					Size = UDim2.new(0, SWITCH_WIDTH, 0, SWITCH_HEIGHT),
					Position = UDim2.new(1, -SWITCH_WIDTH - 12, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = ToggleColorPicker.Value and Color3.fromRGB(255, 0, 255) or Color3.fromRGB(15, 15, 15),
					BorderSizePixel = 0,
					Name = "Switch"
				})

				local switchClickDetector = Create("TextButton", {
					Size = UDim2.new(1, 0, 1, 0),
					Position = UDim2.new(0, 0, 0, 0),
					BackgroundTransparency = 1,
					Text = "",
					Parent = ToggleSwitch
				})

				Create("UICorner", {
					CornerRadius = UDim.new(1, 0),
					Parent = ToggleSwitch
				})

				local switchStroke = Create("UIStroke", {
					Color = Color3.fromRGB(255, 0, 255),
					Thickness = 1,
					Transparency = ToggleColorPicker.Value and 1 or 0.3,
					Parent = ToggleSwitch
				})

				local ToggleCircle = Create("Frame", {
					Size = UDim2.new(0, CIRCLE_SIZE, 0, CIRCLE_SIZE),
					Position = UDim2.new(0, PADDING, 0, PADDING),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BorderSizePixel = 0,
					ZIndex = 2,
					Parent = ToggleSwitch,
					Name = "Circle"
				})

				Create("UICorner", {
					CornerRadius = UDim.new(1, 0),
					Parent = ToggleCircle
				})

				if ToggleColorPicker.Value then
					ToggleCircle.Position = UDim2.new(0, SWITCH_WIDTH - CIRCLE_SIZE - PADDING, 0, PADDING)
				else
					ToggleCircle.Position = UDim2.new(0, PADDING, 0, PADDING)
				end

				local ColorpickerBox = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 4), {
					Size = UDim2.new(0, 24, 0, 24),
					Position = UDim2.new(1, -SWITCH_WIDTH - 20, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5)
				}), {
					AddThemeObject(MakeElement("Stroke"), "Stroke")
				}), "Main")

				local ToggleColorPickerFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
					Size = UDim2.new(1, 0, 0, 38),
					Parent = ItemParent
				}), {
					SetProps(SetChildren(MakeElement("TFrame"), {
						AddThemeObject(SetProps(MakeElement("Label", ToggleColorPickerConfig.Name, 15), {
							Size = UDim2.new(1, -12, 1, 0),
							Position = UDim2.new(0, 12, 0, 0),
							Font = Enum.Font.GothamBold,
							Name = "Content"
						}), "Text"),
						ColorpickerBox,
						Click,
						ToggleSwitch,
						AddThemeObject(SetProps(MakeElement("Frame"), {
							Size = UDim2.new(1, 0, 0, 1),
							Position = UDim2.new(0, 0, 1, -1),
							Name = "Line",
							Visible = false
						}), "Stroke"), 
					}), {
						Size = UDim2.new(1, 0, 0, 38),
						ClipsDescendants = true,
						Name = "F"
					}),
					ColorpickerContainer,
					RainbowCheckbox,
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
				}), "Second")

				local function updateToggle(animate)
					local targetColor = ToggleColorPicker.Value and Color3.fromRGB(255, 0, 255) or Color3.fromRGB(15, 15, 15)
					local targetPos = ToggleColorPicker.Value and 
						UDim2.new(0, SWITCH_WIDTH - CIRCLE_SIZE - PADDING, 0, PADDING) or 
						UDim2.new(0, PADDING, 0, PADDING)
					local targetStrokeTransparency = ToggleColorPicker.Value and 1 or 0.3

					if animate then
						local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
						
						TweenService:Create(ToggleSwitch, tweenInfo, {
							BackgroundColor3 = targetColor
						}):Play()
						
						TweenService:Create(ToggleCircle, tweenInfo, {
							Position = targetPos
						}):Play()
						
						TweenService:Create(switchStroke, tweenInfo, {
							Transparency = targetStrokeTransparency
						}):Play()
					else
						ToggleSwitch.BackgroundColor3 = targetColor
						ToggleCircle.Position = targetPos
						switchStroke.Transparency = targetStrokeTransparency
					end
				end

				local function updateRainbowCheckbox()
					RainbowCheck.Visible = RainbowMode
					
					local targetBgColor = RainbowMode and ToggleColorPicker.ColorValue or Color3.fromRGB(20, 20, 20)
					local targetStrokeTransparency = RainbowMode and 0 or 0.5
					
					TweenService:Create(RainbowCheckbox, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
						BackgroundColor3 = targetBgColor
					}):Play()
					
					TweenService:Create(RainbowStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
						Transparency = targetStrokeTransparency,
						Color = ToggleColorPicker.ColorValue
					}):Play()
					
					if RainbowMode then
						RainbowCheck.Size = UDim2.new(0, 0, 0, 0)
						RainbowCheck.Visible = true
						RainbowCheck.ImageColor3 = ToggleColorPicker.ColorValue
						TweenService:Create(RainbowCheck, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
							Size = UDim2.new(1, -4, 1, -4)
						}):Play()
					else
						TweenService:Create(RainbowCheck, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
							Size = UDim2.new(0, 0, 0, 0)
						}):Play()
						spawn(function()
							wait(0.2)
							if not RainbowMode then
								RainbowCheck.Visible = false
							end
						end)
					end
				end

				local function doToggle()
					ToggleColorPicker.Value = not ToggleColorPicker.Value
					updateToggle(true)
					ToggleColorPickerConfig.Callback(ToggleColorPicker.ColorValue, ToggleColorPicker.Value)
				end

				local function toggleRainbow()
					RainbowMode = not RainbowMode
					updateRainbowCheckbox()
					
					if RainbowMode then
						RainbowConnection = AddConnection(RunService.Heartbeat, function()
							local hue = tick() % 5 / 5
							local color = Color3.fromHSV(hue, 1, 1)
							ToggleColorPicker:SetColor(color)
							ToggleColorPickerConfig.Callback(color, ToggleColorPicker.Value)
						end)
					else
						if RainbowConnection then
							RainbowConnection:Disconnect()
							RainbowConnection = nil
						end
					end
				end

				AddConnection(switchClickDetector.MouseButton1Click, function()
					doToggle()
				end)

				AddConnection(RainbowClick.MouseButton1Click, function()
					toggleRainbow()
				end)

				AddConnection(switchClickDetector.MouseEnter, function()
					TweenService:Create(ToggleSwitch, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
						BackgroundColor3 = ToggleSwitch.BackgroundColor3:Lerp(Color3.fromRGB(255, 255, 255), 0.15)
					}):Play()
					
					if not ToggleColorPicker.Value then
						TweenService:Create(switchStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
							Transparency = 0.1
						}):Play()
					end
				end)

				AddConnection(switchClickDetector.MouseLeave, function()
					TweenService:Create(ToggleSwitch, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
						BackgroundColor3 = ToggleColorPicker.Value and Color3.fromRGB(255, 0, 255) or Color3.fromRGB(15, 15, 15)
					}):Play()
					
					TweenService:Create(switchStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
						Transparency = ToggleColorPicker.Value and 1 or 0.3
					}):Play()
				end)

				AddConnection(RainbowClick.MouseEnter, function()
					TweenService:Create(RainbowCheckbox, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
						BackgroundColor3 = RainbowCheckbox.BackgroundColor3:Lerp(Color3.fromRGB(60, 60, 60), 0.7)
					}):Play()
					TweenService:Create(RainbowStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
						Transparency = 0
					}):Play()
				end)

				AddConnection(RainbowClick.MouseLeave, function()
					TweenService:Create(RainbowCheckbox, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
						BackgroundColor3 = RainbowMode and ToggleColorPicker.ColorValue or Color3.fromRGB(20, 20, 20)
					}):Play()
					TweenService:Create(RainbowStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
						Transparency = RainbowMode and 0 or 0.5
					}):Play()
				end)

				AddConnection(Click.MouseButton1Click, function()
					ToggleColorPicker.Toggled = not ToggleColorPicker.Toggled
					TweenService:Create(ToggleColorPickerFrame,TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{Size = ToggleColorPicker.Toggled and UDim2.new(1, 0, 0, TOTAL_EXPANDED_HEIGHT) or UDim2.new(1, 0, 0, 38)}):Play()
					Color.Visible = ToggleColorPicker.Toggled
					Hue.Visible = ToggleColorPicker.Toggled
					RainbowCheckbox.Visible = ToggleColorPicker.Toggled
					ToggleColorPickerFrame.F.Line.Visible = ToggleColorPicker.Toggled
				end)

				local function UpdateColorPicker()
					ColorpickerBox.BackgroundColor3 = Color3.fromHSV(ColorH, ColorS, ColorV)
					Color.BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1)
					ToggleColorPicker:SetColor(ColorpickerBox.BackgroundColor3)
					
					RainbowStroke.Color = ToggleColorPicker.ColorValue
					RainbowCheck.ImageColor3 = ToggleColorPicker.ColorValue
					if RainbowMode then
						RainbowCheckbox.BackgroundColor3 = ToggleColorPicker.ColorValue
					end
					
					ToggleColorPickerConfig.Callback(ToggleColorPicker.ColorValue, ToggleColorPicker.Value)
					SaveCfg(game.GameId)
				end

				local function UpdateHSV()
					local h, s, v = Color3.toHSV(ToggleColorPicker.ColorValue)
					ColorH = h
					ColorS = s
					ColorV = v
					HueSelection.Position = UDim2.new(0.5, 0, 1 - h, 0)
					ColorSelection.Position = UDim2.new(s, 0, 1 - v, 0)
				end

				ColorH = 1 - (math.clamp(HueSelection.AbsolutePosition.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) / Hue.AbsoluteSize.Y)
				ColorS = (math.clamp(ColorSelection.AbsolutePosition.X - Color.AbsolutePosition.X, 0, Color.AbsoluteSize.X) / Color.AbsoluteSize.X)
				ColorV = 1 - (math.clamp(ColorSelection.AbsolutePosition.Y - Color.AbsolutePosition.Y, 0, Color.AbsoluteSize.Y) / Color.AbsoluteSize.Y)
				
				UpdateHSV()

				AddConnection(Color.InputBegan, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						if ColorInput then
							ColorInput:Disconnect()
						end
						ColorInput = AddConnection(RunService.RenderStepped, function()
							local ColorX = (math.clamp(Mouse.X - Color.AbsolutePosition.X, 0, Color.AbsoluteSize.X) / Color.AbsoluteSize.X)
							local ColorY = (math.clamp(Mouse.Y - Color.AbsolutePosition.Y, 0, Color.AbsoluteSize.Y) / Color.AbsoluteSize.Y)
							ColorSelection.Position = UDim2.new(ColorX, 0, ColorY, 0)
							ColorS = ColorX
							ColorV = 1 - ColorY
							UpdateColorPicker()
						end)
					end
				end)

				AddConnection(Color.InputEnded, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						if ColorInput then
							ColorInput:Disconnect()
						end
					end
				end)

				AddConnection(Hue.InputBegan, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						if HueInput then
							HueInput:Disconnect()
						end;

						HueInput = AddConnection(RunService.RenderStepped, function()
							local HueY = (math.clamp(Mouse.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) / Hue.AbsoluteSize.Y)

							HueSelection.Position = UDim2.new(0.5, 0, HueY, 0)
							ColorH = 1 - HueY

							UpdateColorPicker()
						end)
					end
				end)

				AddConnection(Hue.InputEnded, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						if HueInput then
							HueInput:Disconnect()
						end
					end
				end)

				function ToggleColorPicker:Set(Value)
					ToggleColorPicker.Value = Value
					updateToggle(true)
					ToggleColorPickerConfig.Callback(ToggleColorPicker.ColorValue, ToggleColorPicker.Value)
				end

				function ToggleColorPicker:SetColor(Value)
					ToggleColorPicker.ColorValue = Value
					ColorpickerBox.BackgroundColor3 = ToggleColorPicker.ColorValue
					RainbowStroke.Color = ToggleColorPicker.ColorValue
					RainbowCheck.ImageColor3 = ToggleColorPicker.ColorValue
					if RainbowMode then
						RainbowCheckbox.BackgroundColor3 = ToggleColorPicker.ColorValue
					end
				end

				updateToggle(false)
				ToggleColorPicker:SetColor(ToggleColorPicker.ColorValue)
				if ToggleColorPickerConfig.Flag then                
					OrionLib.Flags[ToggleColorPickerConfig.Flag] = ToggleColorPicker
				end            
				if ToggleColorPickerConfig.ToolTip and ToggleColorPickerConfig.ToolTip ~= "" then
					AddTooltipToElement(ToggleColorPickerFrame, ToggleColorPickerConfig.ToolTip)
				end
				
				return ToggleColorPicker
			end

			function ElementFunction:AddColorpicker(ColorpickerConfig)
				ColorpickerConfig = ColorpickerConfig or {}
				ColorpickerConfig.Name = ColorpickerConfig.Name or "Colorpicker"
				ColorpickerConfig.Default = ColorpickerConfig.Default or Color3.fromRGB(255,255,255)
				ColorpickerConfig.Callback = ColorpickerConfig.Callback or function() end
				ColorpickerConfig.Flag = ColorpickerConfig.Flag or nil
				ColorpickerConfig.Save = ColorpickerConfig.Save or false
				ColorpickerConfig.ToolTip = ColorpickerConfig.ToolTip or ""

				local ColorH, ColorS, ColorV = 1, 1, 1
				local Colorpicker = {Value = ColorpickerConfig.Default, Toggled = false, Type = "Colorpicker", Save = ColorpickerConfig.Save}
				local RainbowMode = false
				local RainbowConnection = nil

				local CHECKBOX_SIZE = 20
				local TOTAL_EXPANDED_HEIGHT = 210

				local ColorSelection = Create("ImageLabel", {
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new(select(3, Color3.toHSV(Colorpicker.Value))),
					ScaleType = Enum.ScaleType.Fit,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = "http://www.roblox.com/asset/?id=4805639000"
				})

				local HueSelection = Create("ImageLabel", {
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new(0.5, 0, 1 - select(1, Color3.toHSV(Colorpicker.Value))),
					ScaleType = Enum.ScaleType.Fit,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = "http://www.roblox.com/asset/?id=4805639000"
				})

				local Color = Create("ImageLabel", {
					Size = UDim2.new(1, -25, 0, 100),
					Visible = false,
					Image = "rbxassetid://4155801252"
				}, {
					Create("UICorner", {CornerRadius = UDim.new(0, 5)}),
					ColorSelection
				})

				local Hue = Create("Frame", {
					Size = UDim2.new(0, 20, 0, 100),
					Position = UDim2.new(1, -20, 0, 0),
					Visible = false
				}, {
					Create("UIGradient", {Rotation = 270, Color = ColorSequence.new{
						ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 4)), 
						ColorSequenceKeypoint.new(0.20, Color3.fromRGB(234, 255, 0)), 
						ColorSequenceKeypoint.new(0.40, Color3.fromRGB(21, 255, 0)), 
						ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0, 255, 255)), 
						ColorSequenceKeypoint.new(0.80, Color3.fromRGB(0, 17, 255)), 
						ColorSequenceKeypoint.new(0.90, Color3.fromRGB(255, 0, 251)), 
						ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 4))
					}}),
					Create("UICorner", {CornerRadius = UDim.new(0, 5)}),
					HueSelection
				})

				local RainbowCheckbox = Create("Frame", {
					Size = UDim2.new(0, CHECKBOX_SIZE, 0, CHECKBOX_SIZE),
					Position = UDim2.new(0, 35, 0, 160),
					AnchorPoint = Vector2.new(0, 0),
					BackgroundColor3 = Color3.fromRGB(20, 20, 20),
					BorderSizePixel = 0,
					Name = "RainbowCheckbox",
					Visible = false
				}, {
					Create("UICorner", {CornerRadius = UDim.new(0, 4)})
				})

				local RainbowCheck = Create("ImageLabel", {
					Size = UDim2.new(0, 0, 0, 0),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = "rbxassetid://7072718162",
					ImageColor3 = Colorpicker.Value,
					Visible = false,
					Parent = RainbowCheckbox
				})

				local RainbowClick = Create("TextButton", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = "",
					Parent = RainbowCheckbox
				})

				local RainbowStroke = Create("UIStroke", {
					Color = Colorpicker.Value,
					Thickness = 1,
					Transparency = 0.5,
					Parent = RainbowCheckbox
				})

				local RainbowLabel = Create("TextLabel", {
					Size = UDim2.new(0, 100, 0, 20),
					Position = UDim2.new(1, 10, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundTransparency = 1,
					Text = "Rainbow Mode",
					TextColor3 = Color3.fromRGB(220, 220, 220),
					TextXAlignment = Enum.TextXAlignment.Left,
					Font = Enum.Font.Gotham,
					TextSize = 13,
					Parent = RainbowCheckbox
				})

				local ColorpickerContainer = Create("Frame", {
					Position = UDim2.new(0, 0, 0, 32),
					Size = UDim2.new(1, 0, 0, TOTAL_EXPANDED_HEIGHT - 38),
					BackgroundTransparency = 1,
					ClipsDescendants = true
				}, {
					Hue,
					Color,
					Create("UIPadding", {
						PaddingLeft = UDim.new(0, 35),
						PaddingRight = UDim.new(0, 35),
						PaddingBottom = UDim.new(0, 15),
						PaddingTop = UDim.new(0, 17)
					})
				})

				local Click = SetProps(MakeElement("Button"), {
					Size = UDim2.new(1, 0, 1, 0)
				})

				local ColorpickerBox = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 4), {
					Size = UDim2.new(0, 24, 0, 24),
					Position = UDim2.new(1, -12, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5)
				}), {
					AddThemeObject(MakeElement("Stroke"), "Stroke")
				}), "Main")

				local ColorpickerFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
					Size = UDim2.new(1, 0, 0, 38),
					Parent = ItemParent
				}), {
					SetProps(SetChildren(MakeElement("TFrame"), {
						AddThemeObject(SetProps(MakeElement("Label", ColorpickerConfig.Name, 15), {
							Size = UDim2.new(1, -12, 1, 0),
							Position = UDim2.new(0, 12, 0, 0),
							Font = Enum.Font.GothamBold,
							Name = "Content"
						}), "Text"),
						ColorpickerBox,
						Click,
						AddThemeObject(SetProps(MakeElement("Frame"), {
							Size = UDim2.new(1, 0, 0, 1),
							Position = UDim2.new(0, 0, 1, -1),
							Name = "Line",
							Visible = false
						}), "Stroke"), 
					}), {
						Size = UDim2.new(1, 0, 0, 38),
						ClipsDescendants = true,
						Name = "F"
					}),
					ColorpickerContainer,
					RainbowCheckbox,
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
				}), "Second")

				local function updateRainbowCheckbox()
					RainbowCheck.Visible = RainbowMode
					
					local targetBgColor = RainbowMode and Colorpicker.Value or Color3.fromRGB(20, 20, 20)
					local targetStrokeTransparency = RainbowMode and 0 or 0.5
					
					TweenService:Create(RainbowCheckbox, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
						BackgroundColor3 = targetBgColor
					}):Play()
					
					TweenService:Create(RainbowStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
						Transparency = targetStrokeTransparency,
						Color = Colorpicker.Value
					}):Play()
					
					if RainbowMode then
						RainbowCheck.Size = UDim2.new(0, 0, 0, 0)
						RainbowCheck.Visible = true
						RainbowCheck.ImageColor3 = Colorpicker.Value
						TweenService:Create(RainbowCheck, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
							Size = UDim2.new(1, -4, 1, -4)
						}):Play()
					else
						TweenService:Create(RainbowCheck, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
							Size = UDim2.new(0, 0, 0, 0)
						}):Play()
						spawn(function()
							wait(0.2)
							if not RainbowMode then
								RainbowCheck.Visible = false
							end
						end)
					end
				end

				local function toggleRainbow()
					RainbowMode = not RainbowMode
					updateRainbowCheckbox()
					
					if RainbowMode then
						RainbowConnection = AddConnection(RunService.Heartbeat, function()
							local hue = tick() % 5 / 5
							local color = Color3.fromHSV(hue, 1, 1)
							Colorpicker:Set(color)
							ColorpickerConfig.Callback(color)
						end)
					else
						if RainbowConnection then
							RainbowConnection:Disconnect()
							RainbowConnection = nil
						end
					end
				end

				AddConnection(RainbowClick.MouseButton1Click, function()
					toggleRainbow()
				end)

				AddConnection(RainbowClick.MouseEnter, function()
					TweenService:Create(RainbowCheckbox, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
						BackgroundColor3 = RainbowCheckbox.BackgroundColor3:Lerp(Color3.fromRGB(60, 60, 60), 0.7)
					}):Play()
					TweenService:Create(RainbowStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
						Transparency = 0
					}):Play()
				end)

				AddConnection(RainbowClick.MouseLeave, function()
					TweenService:Create(RainbowCheckbox, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
						BackgroundColor3 = RainbowMode and Colorpicker.Value or Color3.fromRGB(20, 20, 20)
					}):Play()
					TweenService:Create(RainbowStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
						Transparency = RainbowMode and 0 or 0.5
					}):Play()
				end)

				AddConnection(Click.MouseButton1Click, function()
					Colorpicker.Toggled = not Colorpicker.Toggled
					TweenService:Create(ColorpickerFrame,TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{Size = Colorpicker.Toggled and UDim2.new(1, 0, 0, TOTAL_EXPANDED_HEIGHT) or UDim2.new(1, 0, 0, 38)}):Play()
					Color.Visible = Colorpicker.Toggled
					Hue.Visible = Colorpicker.Toggled
					RainbowCheckbox.Visible = Colorpicker.Toggled
					ColorpickerFrame.F.Line.Visible = Colorpicker.Toggled
				end)

				local function UpdateColorPicker()
					ColorpickerBox.BackgroundColor3 = Color3.fromHSV(ColorH, ColorS, ColorV)
					Color.BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1)
					Colorpicker:Set(ColorpickerBox.BackgroundColor3)
					
					RainbowStroke.Color = Colorpicker.Value
					RainbowCheck.ImageColor3 = Colorpicker.Value
					if RainbowMode then
						RainbowCheckbox.BackgroundColor3 = Colorpicker.Value
					end
					
					ColorpickerConfig.Callback(ColorpickerBox.BackgroundColor3)
					SaveCfg(game.GameId)
				end

				local function UpdateHSV()
					local h, s, v = Color3.toHSV(Colorpicker.Value)
					ColorH = h
					ColorS = s
					ColorV = v
					HueSelection.Position = UDim2.new(0.5, 0, 1 - h, 0)
					ColorSelection.Position = UDim2.new(s, 0, 1 - v, 0)
				end

				ColorH = 1 - (math.clamp(HueSelection.AbsolutePosition.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) / Hue.AbsoluteSize.Y)
				ColorS = (math.clamp(ColorSelection.AbsolutePosition.X - Color.AbsolutePosition.X, 0, Color.AbsoluteSize.X) / Color.AbsoluteSize.X)
				ColorV = 1 - (math.clamp(ColorSelection.AbsolutePosition.Y - Color.AbsolutePosition.Y, 0, Color.AbsoluteSize.Y) / Color.AbsoluteSize.Y)
				
				UpdateHSV()

				AddConnection(Color.InputBegan, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						if ColorInput then
							ColorInput:Disconnect()
						end
						ColorInput = AddConnection(RunService.RenderStepped, function()
							local ColorX = (math.clamp(Mouse.X - Color.AbsolutePosition.X, 0, Color.AbsoluteSize.X) / Color.AbsoluteSize.X)
							local ColorY = (math.clamp(Mouse.Y - Color.AbsolutePosition.Y, 0, Color.AbsoluteSize.Y) / Color.AbsoluteSize.Y)
							ColorSelection.Position = UDim2.new(ColorX, 0, ColorY, 0)
							ColorS = ColorX
							ColorV = 1 - ColorY
							UpdateColorPicker()
						end)
					end
				end)

				AddConnection(Color.InputEnded, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						if ColorInput then
							ColorInput:Disconnect()
						end
					end
				end)

				AddConnection(Hue.InputBegan, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						if HueInput then
							HueInput:Disconnect()
						end;

						HueInput = AddConnection(RunService.RenderStepped, function()
							local HueY = (math.clamp(Mouse.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) / Hue.AbsoluteSize.Y)

							HueSelection.Position = UDim2.new(0.5, 0, HueY, 0)
							ColorH = 1 - HueY

							UpdateColorPicker()
						end)
					end
				end)

				AddConnection(Hue.InputEnded, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						if HueInput then
							HueInput:Disconnect()
						end
					end
				end)

				function Colorpicker:Set(Value)
					Colorpicker.Value = Value
					ColorpickerBox.BackgroundColor3 = Colorpicker.Value
					RainbowStroke.Color = Colorpicker.Value
					RainbowCheck.ImageColor3 = Colorpicker.Value
					if RainbowMode then
						RainbowCheckbox.BackgroundColor3 = Colorpicker.Value
					end
					ColorpickerConfig.Callback(Colorpicker.Value)
				end

				Colorpicker:Set(Colorpicker.Value)
				if ColorpickerConfig.Flag then				
					OrionLib.Flags[ColorpickerConfig.Flag] = Colorpicker
				end
				if ColorpickerConfig.ToolTip and ColorpickerConfig.ToolTip ~= "" then
					AddTooltipToElement(ColorpickerFrame, ColorpickerConfig.ToolTip)
				end
				
				return Colorpicker
			end
			return ElementFunction   
		end	

		local ElementFunction = {}

		function ElementFunction:AddSection(SectionConfig)
			SectionConfig.Name = SectionConfig.Name or "Section"

			local SectionFrame = SetChildren(SetProps(MakeElement("TFrame"), {
				Size = UDim2.new(1, 0, 0, 26),
				Parent = Container
			}), {
				AddThemeObject(SetProps(MakeElement("Label", SectionConfig.Name, 14), {
					Size = UDim2.new(1, -12, 0, 16),
					Position = UDim2.new(0, 0, 0, 3),
					Font = Enum.Font.GothamSemibold
				}), "TextDark"),
				SetChildren(SetProps(MakeElement("TFrame"), {
					AnchorPoint = Vector2.new(0, 0),
					Size = UDim2.new(1, 0, 1, -24),
					Position = UDim2.new(0, 0, 0, 23),
					Name = "Holder"
				}), {
					MakeElement("List", 0, 6)
				}),
			})

			AddConnection(SectionFrame.Holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
				SectionFrame.Size = UDim2.new(1, 0, 0, SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y + 31)
				SectionFrame.Holder.Size = UDim2.new(1, 0, 0, SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y)
			end)

			local SectionFunction = {}
			for i, v in next, GetElements(SectionFrame.Holder) do
				SectionFunction[i] = v 
			end
			return SectionFunction
		end	

		for i, v in next, GetElements(Container) do
			ElementFunction[i] = v 
		end

		if TabConfig.PremiumOnly then
			for i, v in next, ElementFunction do
				ElementFunction[i] = function() end
			end    
			Container:FindFirstChild("UIListLayout"):Destroy()
			Container:FindFirstChild("UIPadding"):Destroy()
			SetChildren(SetProps(MakeElement("TFrame"), {
				Size = UDim2.new(1, 0, 1, 0),
				Parent = ItemParent
			}), {
				AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://3610239960"), {
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new(0, 15, 0, 15),
					ImageTransparency = 0.4
				}), "Text"),
				AddThemeObject(SetProps(MakeElement("Label", "Unauthorised Access", 14), {
					Size = UDim2.new(1, -38, 0, 14),
					Position = UDim2.new(0, 38, 0, 18),
					TextTransparency = 0.4
				}), "Text"),
				AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://4483345875"), {
					Size = UDim2.new(0, 56, 0, 56),
					Position = UDim2.new(0, 84, 0, 110),
				}), "Text"),
				AddThemeObject(SetProps(MakeElement("Label", "Premium Features", 14), {
					Size = UDim2.new(1, -150, 0, 14),
					Position = UDim2.new(0, 150, 0, 112),
					Font = Enum.Font.GothamBold
				}), "Text"),
				AddThemeObject(SetProps(MakeElement("Label", "This part of the script is locked to Sirius Premium users. Purchase Premium in the Discord server (discord.gg/sirius)", 12), {
					Size = UDim2.new(1, -200, 0, 14),
					Position = UDim2.new(0, 150, 0, 138),
					TextWrapped = true,
					TextTransparency = 0.4
				}), "Text")
			})
		end
function ElementFunction:AddSubTab(SubTabConfig)
	SubTabConfig = SubTabConfig or {}
	SubTabConfig.Name = SubTabConfig.Name or "SubTab"
	local isFirstSubTab = #Container:GetChildren() <= 2
	local SubTabsHolder
	if not Container:FindFirstChild("SubTabsHolder") then
		SubTabsHolder = SetChildren(SetProps(MakeElement("TFrame"), {
			Size = UDim2.new(1, 0, 0, 36),
			Name = "SubTabsHolder",
			Parent = Container,
			LayoutOrder = -999
		}), {
			SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255, 0, 255), 4), {
				Size = UDim2.new(1, 0, 1, 0),
				ScrollBarThickness = 0,
				ScrollingDirection = Enum.ScrollingDirection.X,
				Name = "ButtonHolder"
			}), {
				MakeElement("List", 0, 4),
				MakeElement("Padding", 0, 8, 8, 0)
			}),
			AddThemeObject(SetProps(MakeElement("Frame"), {
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.new(0, 0, 1, -1),
				Name = "Divider"
			}), "Stroke")
		})
		
		SubTabsHolder.ButtonHolder.UIListLayout.FillDirection = Enum.FillDirection.Horizontal
		SubTabsHolder.ButtonHolder.UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		SubTabsHolder.ButtonHolder.UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		AddConnection(SubTabsHolder.ButtonHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
			SubTabsHolder.ButtonHolder.CanvasSize = UDim2.new(0, SubTabsHolder.ButtonHolder.UIListLayout.AbsoluteContentSize.X + 16, 0, 0)
		end)
	else
		SubTabsHolder = Container:FindFirstChild("SubTabsHolder")
	end
	
	local SubTabContainer = SetChildren(SetProps(MakeElement("TFrame"), {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = Container,
		Name = "SubTabContainer_" .. SubTabConfig.Name,
		Visible = isFirstSubTab,
		LayoutOrder = 0,
		BackgroundTransparency = 1
	}), {
		MakeElement("List", 0, 6),
		MakeElement("Padding", 0, 0, 0, 5)
	})
	
	local SubTabButton = AddThemeObject(SetChildren(SetProps(MakeElement("Button"), {
		Size = UDim2.new(0, 120, 0, 30),
		Parent = SubTabsHolder.ButtonHolder,
		Name = "SubTab_" .. SubTabConfig.Name
	}), {
		AddThemeObject(SetProps(MakeElement("Label", SubTabConfig.Name, 14), {
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			Font = Enum.Font.GothamSemibold,
			Name = "Title",
			TextTransparency = isFirstSubTab and 0 or 0.4,
			TextXAlignment = Enum.TextXAlignment.Center
		}), "Text"),
		AddThemeObject(SetProps(MakeElement("Frame"), {
			Size = UDim2.new(0.4, 0, 0, 2),
			Position = UDim2.new(0.5, 0, 1, -2),
			AnchorPoint = Vector2.new(0.5, 0),
			Name = "Indicator",
			BackgroundTransparency = isFirstSubTab and 0 or 1
		}), "Stroke"),
		MakeElement("Corner", 0, 4)
	}), "Divider")
	
	local RippleEffect = SetProps(MakeElement("Image", "rbxassetid://2708891598"), {
		ImageTransparency = 0.7,
		ImageColor3 = Color3.fromRGB(255, 255, 255),
		ScaleType = Enum.ScaleType.Fit,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 0),
		Parent = SubTabButton,
		ZIndex = 2,
		Name = "Ripple"
	})
	
	local isSelected = isFirstSubTab
	
	local function UpdateButtonSize()
		local textSize = SubTabButton.Title.TextBounds.X + 24
		SubTabButton.Size = UDim2.new(0, math.max(textSize, 70), 0, 30)
	end
	
	UpdateButtonSize()
	
	local function PlayRippleEffect(targetButton)
		local ripple = targetButton:FindFirstChild("Ripple")
		if ripple then
			ripple.ImageTransparency = 0.7
			ripple.Size = UDim2.new(0, 0, 0, 0)
			TweenService:Create(ripple, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(1.5, 0, 1.5, 0),
				ImageTransparency = 1
			}):Play()
		end
	end
	
	local function SelectSubTab()
		for _, Button in pairs(SubTabsHolder.ButtonHolder:GetChildren()) do
			if Button:IsA("TextButton") and Button ~= SubTabButton then
				TweenService:Create(Button.Title, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0.4}):Play()
				TweenService:Create(Button.Indicator, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					BackgroundTransparency = 1,
					Size = UDim2.new(0, 0, 0, 2)
				}):Play()
				Button:SetAttribute("Selected", false)
			end
		end
		
		for _, Item in pairs(Container:GetChildren()) do
			if Item.Name:find("SubTabContainer_") and Item ~= SubTabContainer then
				Item.Visible = false
			end
		end
		
		isSelected = true
		SubTabButton:SetAttribute("Selected", true)
		
		PlayRippleEffect(SubTabButton)
		
		TweenService:Create(SubTabButton.Title, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
		TweenService:Create(SubTabButton.Indicator, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0,
			Size = UDim2.new(0.4, 0, 0, 2)
		}):Play()
		
		SubTabContainer.Visible = true
		SubTabContainer.BackgroundTransparency = 1
		
		for _, child in pairs(SubTabContainer:GetChildren()) do
			if not (child:IsA("UIListLayout") or child:IsA("UIPadding")) then
				child.BackgroundTransparency = 1
				if child:FindFirstChild("Content") then
					child.Content.TextTransparency = 1
				end
			end
		end
		
		task.spawn(function()
			task.wait(0.05)
			if not SubTabButton:GetAttribute("Selected") then return end
			
			for _, child in pairs(SubTabContainer:GetChildren()) do
				if not (child:IsA("UIListLayout") or child:IsA("UIPadding")) then
					if not child.Name:find("Section") then
						TweenService:Create(child, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {BackgroundTransparency = 0}):Play()
					end
					if child:FindFirstChild("Content") then
						TweenService:Create(child.Content, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
					end
				end
			end
		end)
	end
	
	AddConnection(SubTabButton.MouseEnter, function()
		if not SubTabButton:GetAttribute("Selected") then
			TweenService:Create(SubTabButton.Title, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {TextTransparency = 0.2}):Play()
			TweenService:Create(SubTabButton.Indicator, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
				BackgroundTransparency = 0.6,
				Size = UDim2.new(0.4, 0, 0, 2)
			}):Play()
		end
	end)
	
	AddConnection(SubTabButton.MouseLeave, function()
		if not SubTabButton:GetAttribute("Selected") then
			TweenService:Create(SubTabButton.Title, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {TextTransparency = 0.4}):Play()
			TweenService:Create(SubTabButton.Indicator, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 0, 0, 2)
			}):Play()
		end
	end)
	
	AddConnection(SubTabButton.MouseButton1Down, function()
		TweenService:Create(SubTabButton, TweenInfo.new(0.08, Enum.EasingStyle.Quart), {
			Size = UDim2.new(0, SubTabButton.Size.X.Offset, 0, 28)
		}):Play()
	end)
	
	AddConnection(SubTabButton.MouseButton1Up, function()
		TweenService:Create(SubTabButton, TweenInfo.new(0.08, Enum.EasingStyle.Quart), {
			Size = UDim2.new(0, SubTabButton.Size.X.Offset, 0, 30)
		}):Play()
	end)
	
	AddConnection(SubTabButton.MouseButton1Click, function()
		SelectSubTab()
	end)
	
	if isFirstSubTab then
		SubTabButton:SetAttribute("Selected", true)
		SelectSubTab()
	end
	
	local SubTabFunction = {}
	for i, v in next, GetElements(SubTabContainer) do
		SubTabFunction[i] = v
	end
	
	function SubTabFunction:AddSection(SectionConfig)
		SectionConfig = SectionConfig or {}
		SectionConfig.Name = SectionConfig.Name or "Section"

		local SectionFrame = SetChildren(SetProps(MakeElement("TFrame"), {
			Size = UDim2.new(1, 0, 0, 26),
			Parent = SubTabContainer,
			BackgroundTransparency = 1,
			Name = "Section_" .. SectionConfig.Name
		}), {
			AddThemeObject(SetProps(MakeElement("Label", SectionConfig.Name, 14), {
				Size = UDim2.new(1, -12, 0, 16),
				Position = UDim2.new(0, 0, 0, 3),
				Font = Enum.Font.GothamSemibold,
				BackgroundTransparency = 1
			}), "TextDark"),
			SetChildren(SetProps(MakeElement("TFrame"), {
				AnchorPoint = Vector2.new(0, 0),
				Size = UDim2.new(1, 0, 1, -24),
				Position = UDim2.new(0, 0, 0, 23),
				Name = "Holder",
				BackgroundTransparency = 1
			}), {
				MakeElement("List", 0, 6)
			}),
		})

		AddConnection(SectionFrame.Holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
			SectionFrame.Size = UDim2.new(1, 0, 0, SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y + 31)
			SectionFrame.Holder.Size = UDim2.new(1, 0, 0, SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y)
		end)

		local SectionFunction = {}
		for i, v in next, GetElements(SectionFrame.Holder) do
			SectionFunction[i] = v 
		end
		return SectionFunction
	end
	
	return SubTabFunction
end
		return ElementFunction   
	end  
	return TabFunction
end   
function OrionLib:Destroy()
	Orion:Destroy()
end
function OrionLib:AddConfigurationSystem(Parent)
	local Container
	if type(Parent) == "table" then
		if Parent.AddSection then
			Container = Parent:AddSection({Name = "Configurations"})
		else
			Container = Parent
		end
	else
		warn("Invalid parent for configs.")
		return
	end
	local SelectedConfig = ""
	local function RefreshConfigs()
		local ConfigList = {}
		pcall(function()
			local Files = listfiles(OrionLib.Folder)
			for _, File in pairs(Files) do
				if File:sub(-4) == ".txt" then
					local FileName = File:gsub(OrionLib.Folder .. "\\", "")
					FileName = FileName:gsub(".txt", "")
					if FileName ~= tostring(game.GameId) then
						table.insert(ConfigList, FileName)
					end
				end
			end
		end)
		return ConfigList
	end
	Container:AddLabel("Enter a name and create or select an existing config")
	Container:AddTextbox({
		Name = "Config Name",
		Default = "",
		TextDisappear = false,
		Callback = function(Text)
			SelectedConfig = Text
		end
	})
	local ConfigDropdown = Container:AddDropdown({
		Name = "Saved Configs",
		Default = "",
		Options = RefreshConfigs(),
		Flag = "ConfigDropdown",
		Callback = function(Selected)
			SelectedConfig = Selected
		end
	})
	Container:AddButton({
		Name = "Create Config",
		Callback = function()
			if SelectedConfig ~= "" then
				local Data = {}
				for i, v in pairs(OrionLib.Flags) do
					if v.Save then
						if v.Type == "Colorpicker" then
							Data[i] = PackColor(v.Value)
						else
							Data[i] = v.Value
						end
					end    
				end
				writefile(OrionLib.Folder .. "/" .. SelectedConfig .. ".txt", tostring(HttpService:JSONEncode(Data)))
				OrionLib:MakeNotification({
					Name = "Configuration",
					Content = "Created config: " .. SelectedConfig,
					Time = 5
				})
				ConfigDropdown:Refresh(RefreshConfigs(), true)
			else
				OrionLib:MakeNotification({
					Name = "Configuration",
					Content = "Please enter a config name!",
					Time = 5
				})
			end
		end
	})
	Container:AddButton({
		Name = "Save/Overwrite Config",
		Callback = function()
			if SelectedConfig ~= "" then
				local Data = {}
				for i, v in pairs(OrionLib.Flags) do
					if v.Save then
						if v.Type == "Colorpicker" then
							Data[i] = PackColor(v.Value)
						else
							Data[i] = v.Value
						end
					end    
				end
				writefile(OrionLib.Folder .. "/" .. SelectedConfig .. ".txt", tostring(HttpService:JSONEncode(Data)))
				OrionLib:MakeNotification({
					Name = "Configs",
					Content = "Saved config: " .. SelectedConfig,
					Time = 5
				})
				ConfigDropdown:Refresh(RefreshConfigs(), true)
			else
				OrionLib:MakeNotification({
					Name = "Configs",
					Content = "Please enter a config name!",
					Time = 5
				})
			end
		end
	})
	Container:AddButton({
		Name = "Load Selected Config",
		Callback = function()
			if SelectedConfig == "" then
				OrionLib:MakeNotification({
					Name = "Configuration", 
					Content = "No config selected!",
					Time = 5
				})
				return
			end
			if isfile(OrionLib.Folder .. "/" .. SelectedConfig .. ".txt") then
				local Success, Result = pcall(function()
					return readfile(OrionLib.Folder .. "/" .. SelectedConfig .. ".txt")
				end)
				if Success then
					pcall(function()
						LoadCfg(Result)
						OrionLib:MakeNotification({
							Name = "Configuration",
							Content = "Loaded config: " .. SelectedConfig,
							Time = 5
						})
					end)
				else
					OrionLib:MakeNotification({
						Name = "Configuration",
						Content = "Failed to load config!",
						Time = 5
					})
				end
			else
				OrionLib:MakeNotification({
					Name = "Configuration",
					Content = "Config doesn't exist!",
					Time = 5
				})
			end
		end
	})
	Container:AddButton({
		Name = "Delete Selected Config",
		Callback = function()
			if SelectedConfig == "" then
				OrionLib:MakeNotification({
					Name = "Configuration",
					Content = "No config selected!",
					Time = 5
				})
				return
			end
			if isfile(OrionLib.Folder .. "/" .. SelectedConfig .. ".txt") then
				pcall(function()
					delfile(OrionLib.Folder .. "/" .. SelectedConfig .. ".txt")
				end)
				ConfigDropdown:Refresh(RefreshConfigs(), true)
				OrionLib:MakeNotification({
					Name = "Configuration",
					Content = "Deleted config: " .. SelectedConfig,
					Time = 5
				})
				SelectedConfig = ""
			else
				OrionLib:MakeNotification({
					Name = "Configuration",
					Content = "Config doesn't exist!",
					Time = 5
				})
			end
		end
	})
	Container:AddButton({
		Name = "Refresh Config List",
		Callback = function()
			ConfigDropdown:Refresh(RefreshConfigs(), true)
			OrionLib:MakeNotification({
				Name = "Configuration",
				Content = "Refreshed config list",
				Time = 3
			})
		end
	})
end
return OrionLib
