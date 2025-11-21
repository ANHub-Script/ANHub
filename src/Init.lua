local AnUI = {
    Window = nil,
    Theme = nil,
    Creator = require("./modules/Creator"),
    LocalizationModule = require("./modules/Localization"),
    NotificationModule = require("./components/Notification"),
    Themes = nil,
    Transparent = false,
    
    TransparencyValue = .15,
    
    UIScale = 1,
    
    ConfigManager = nil,
    Version = "0.0.0",
    
    Services = require("./utils/services/Init"),
    
    OnThemeChangeFunction = nil,
    
    cloneref = nil,
}


local cloneref = (cloneref or clonereference or function(instance) return instance end)

AnUI.cloneref = cloneref

local HttpService = cloneref(game:GetService("HttpService"))
local Players = cloneref(game:GetService("Players"))
local CoreGui= cloneref(game:GetService("CoreGui"))

local LocalPlayer = Players.LocalPlayer or nil

local Package = HttpService:JSONDecode(require("../build/package"))
if Package then
    AnUI.Version = Package.version
end

local KeySystem = require("./components/KeySystem")

local ServicesModule = AnUI.Services


local Creator = AnUI.Creator

local New = Creator.New
local Tween = Creator.Tween


local Acrylic = require("./utils/Acrylic/Init")


local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end

local GUIParent = gethui and gethui() or (CoreGui or game.Players.LocalPlayer:WaitForChild("PlayerGui"))


AnUI.ScreenGui = New("ScreenGui", {
    Name = "AnUI",
    Parent = GUIParent,
    IgnoreGuiInset = true,
    ScreenInsets = "None",
}, {
    New("UIScale", {
        Scale = AnUI.Scale,
    }),
    New("Folder", {
        Name = "Window"
    }),
    -- New("Folder", {
    --     Name = "Notifications"
    -- }),
    -- New("Folder", {
    --     Name = "Dropdowns"
    -- }),
    New("Folder", {
        Name = "KeySystem"
    }),
    New("Folder", {
        Name = "Popups"
    }),
    New("Folder", {
        Name = "ToolTips"
    })
})

AnUI.NotificationGui = New("ScreenGui", {
    Name = "AnUI/Notifications",
    Parent = GUIParent,
    IgnoreGuiInset = true,
})
AnUI.DropdownGui = New("ScreenGui", {
    Name = "AnUI/Dropdowns",
    Parent = GUIParent,
    IgnoreGuiInset = true,
})
ProtectGui(AnUI.ScreenGui)
ProtectGui(AnUI.NotificationGui)
ProtectGui(AnUI.DropdownGui)

Creator.Init(AnUI)


function AnUI:SetParent(parent)
    AnUI.ScreenGui.Parent = parent
    AnUI.NotificationGui.Parent = parent
    AnUI.DropdownGui.Parent = parent
end
math.clamp(AnUI.TransparencyValue, 0, 1)

local Holder = AnUI.NotificationModule.Init(AnUI.NotificationGui)

function AnUI:Notify(Config)
    Config.Holder = Holder.Frame
    Config.Window = AnUI.Window
    --Config.AnUI = AnUI
    return AnUI.NotificationModule.New(Config)
end

function AnUI:SetNotificationLower(Val)
    Holder.SetLower(Val)
end

function AnUI:SetFont(FontId)
    Creator.UpdateFont(FontId)
end

function AnUI:OnThemeChange(func)
    AnUI.OnThemeChangeFunction = func
end

function AnUI:AddTheme(LTheme)
    AnUI.Themes[LTheme.Name] = LTheme
    return LTheme
end

function AnUI:SetTheme(Value)
    if AnUI.Themes[Value] then
        AnUI.Theme = AnUI.Themes[Value]
        Creator.SetTheme(AnUI.Themes[Value])
        
        if AnUI.OnThemeChangeFunction then
            AnUI.OnThemeChangeFunction(Value)
        end
        --Creator.UpdateTheme()
        
        return AnUI.Themes[Value]
    end
    return nil
end

function AnUI:GetThemes()
    return AnUI.Themes
end
function AnUI:GetCurrentTheme()
    return AnUI.Theme.Name
end
function AnUI:GetTransparency()
    return AnUI.Transparent or false
end
function AnUI:GetWindowSize()
    return Window.UIElements.Main.Size
end
function AnUI:Localization(LocalizationConfig)
    return AnUI.LocalizationModule:New(LocalizationConfig, Creator)
end

function AnUI:SetLanguage(Value)
    if Creator.Localization then
        return Creator.SetLanguage(Value)
    end
    return false
end

function AnUI:ToggleAcrylic(Value)
	if AnUI.Window and AnUI.Window.AcrylicPaint and AnUI.Window.AcrylicPaint.Model then
		AnUI.Window.Acrylic = Value
		AnUI.Window.AcrylicPaint.Model.Transparency = Value and 0.98 or 1
		if Value then
			Acrylic.Enable()
		else
			Acrylic.Disable()
		end
	end
end



function AnUI:Gradient(stops, props)
    local colorSequence = {}
    local transparencySequence = {}

    for posStr, stop in next, stops do
        local position = tonumber(posStr)
        if position then
            position = math.clamp(position / 100, 0, 1)
            table.insert(colorSequence, ColorSequenceKeypoint.new(position, stop.Color))
            table.insert(transparencySequence, NumberSequenceKeypoint.new(position, stop.Transparency or 0))
        end
    end

    table.sort(colorSequence, function(a, b) return a.Time < b.Time end)
    table.sort(transparencySequence, function(a, b) return a.Time < b.Time end)


    if #colorSequence < 2 then
        error("ColorSequence requires at least 2 keypoints")
    end


    local gradientData = {
        Color = ColorSequence.new(colorSequence),
        Transparency = NumberSequence.new(transparencySequence),
    }

    if props then
        for k, v in pairs(props) do
            gradientData[k] = v
        end
    end

    return gradientData
end


function AnUI:Popup(PopupConfig)
    PopupConfig.AnUI = AnUI
    return require("./components/popup/Init").new(PopupConfig)
end


AnUI.Themes = require("./themes/Init")(AnUI)

Creator.Themes = AnUI.Themes


AnUI:SetTheme("Dark")
AnUI:SetLanguage(Creator.Language)


function AnUI:CreateWindow(Config)
    local CreateWindow = require("./components/window/Init")
    
    if not isfolder("AnUI") then
        makefolder("AnUI")
    end
    if Config.Folder then
        makefolder(Config.Folder)
    else
        makefolder(Config.Title)
    end
    
    Config.AnUI = AnUI
    Config.Parent = AnUI.ScreenGui.Window
    
    if AnUI.Window then
        warn("You cannot create more than one window")
        return
    end
    
    local CanLoadWindow = true
    
    local Theme = AnUI.Themes[Config.Theme or "Dark"]
    
    --AnUI.Theme = Theme
    Creator.SetTheme(Theme)
    
    
    local hwid = gethwid or function()
        return Players.LocalPlayer.UserId
    end
    
    local Filename = hwid()
    
    if Config.KeySystem then
        CanLoadWindow = false
    
        local function loadKeysystem()
            KeySystem.new(Config, Filename, function(c) CanLoadWindow = c end)
        end
    
        local keyPath = (Config.Folder or "Temp") .. "/" .. Filename .. ".key"
        
        if Config.KeySystem.KeyValidator then
            if Config.KeySystem.SaveKey and isfile(keyPath) then
                local savedKey = readfile(keyPath)
                local isValid = Config.KeySystem.KeyValidator(savedKey)
                
                if isValid then
                    CanLoadWindow = true
                else
                    loadKeysystem()
                end
            else
                loadKeysystem()
            end
        elseif not Config.KeySystem.API then
            if Config.KeySystem.SaveKey and isfile(keyPath) then
                local savedKey = readfile(keyPath)
                local isKey = (type(Config.KeySystem.Key) == "table")
                    and table.find(Config.KeySystem.Key, savedKey)
                    or tostring(Config.KeySystem.Key) == tostring(savedKey)
                    
                if isKey then
                    CanLoadWindow = true
                else
                    loadKeysystem()
                end
            else
                loadKeysystem()
            end
        else
            if isfile(keyPath) then
                local fileKey = readfile(keyPath)
                local isSuccess = false
                 
                for _, i in next, Config.KeySystem.API do
                    local serviceData = AnUI.Services[i.Type]
                    if serviceData then
                        local args = {}
                        for _, argName in next, serviceData.Args do
                            table.insert(args, i[argName])
                        end
                        
                        local service = serviceData.New(table.unpack(args))
                        local success = service.Verify(fileKey)
                        if success then
                            isSuccess = true
                            break
                        end
                    end
                end
                    
                CanLoadWindow = isSuccess
                if not isSuccess then loadKeysystem() end
            else
                loadKeysystem()
            end
        end
        
        repeat task.wait() until CanLoadWindow
    end

    local Window = CreateWindow(Config)

    AnUI.Transparent = Config.Transparent
    AnUI.Window = Window
    
    if Config.Acrylic then
        Acrylic.init()
    end
    
    -- function Window:ToggleTransparency(Value)
    --     AnUI.Transparent = Value
    --     AnUI.Window.Transparent = Value
        
    --     Window.UIElements.Main.Background.BackgroundTransparency = Value and AnUI.TransparencyValue or 0
    --     Window.UIElements.Main.Background.ImageLabel.ImageTransparency = Value and AnUI.TransparencyValue or 0
    --     Window.UIElements.Main.Gradient.UIGradient.Transparency = NumberSequence.new{
    --         NumberSequenceKeypoint.new(0, 1), 
    --         NumberSequenceKeypoint.new(1, Value and 0.85 or 0.7),
    --     }
    -- end
    
    return Window
end

return AnUI