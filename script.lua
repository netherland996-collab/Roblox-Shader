-- // Universal Mobile Cinematic Shader & Graphics Engine v3.4 (Final & Signed by Kadir)
-- // State-free drag · Re-execution safe · Fully wrapped · Anti-Crash Pairs

local Lighting         = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")

-- // --- GUI parent: gethui → CoreGui → PlayerGui ---
local function getGuiParent()
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    local ok, cg = pcall(function() return CoreGui end)
    if ok and cg then return cg end
    return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end

-- // --- Cleanup previous instance ---
local guiParent = getGuiParent()
if guiParent:FindFirstChild("MobileShaderGUI") then
    guiParent.MobileShaderGUI:Destroy()
end
for _, v in ipairs(Lighting:GetChildren()) do
    if v.Name:match("^UShader_") then
        v:Destroy()
    end
end

-- // --- Re-execution-safe original preservation ---
_G.UShader = _G.UShader or {}

if not _G.UShader.originalAtmos then
    _G.UShader.originalAtmos = {}
    setmetatable(_G.UShader.originalAtmos, { __mode = "k" })
end

if _G.UShader.active and _G.UShader.originalLighting then
    pcall(function()
        Lighting.GlobalShadows  = _G.UShader.originalLighting.GlobalShadows
        Lighting.OutdoorAmbient = _G.UShader.originalLighting.OutdoorAmbient
    end)
    if _G.UShader.originalAtmos then
        pcall(function()
            for atm, dens in pairs(_G.UShader.originalAtmos) do
                if atm and atm.Parent then atm.Density = dens end
            end
        end)
    end
    _G.UShader.active = false
end

_G.UShader.originalLighting = {
    GlobalShadows  = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient,
}
local originalLighting = _G.UShader.originalLighting

for _, v in ipairs(Lighting:GetChildren()) do
    if v:IsA("Atmosphere") and v.Name ~= "UShader_Atmos" then
        if _G.UShader.originalAtmos[v] == nil then
            _G.UShader.originalAtmos[v] = v.Density
        end
    end
end
local existingAtmos = _G.UShader.originalAtmos

-- // --- Build GUI ---
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MobileShaderGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = guiParent

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 160, 0, 90)
mainFrame.Position = UDim2.new(0, 20, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", mainFrame)
stroke.Color = Color3.fromRGB(60, 60, 60)
stroke.Thickness = 1.5

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -20, 0, 40)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 13
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Text = "SHADER: OFF"
toggleButton.AutoButtonColor = false
toggleButton.Selectable = false
toggleButton.Parent = mainFrame
Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0, 8)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, 58)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.Text = "By Kadir"
statusLabel.Parent = mainFrame

-- // --- Drag: Saf ve Hatasız Mantık ---
do
    local dragging, dragStart, startPos
    local buttonInteracting = false

    toggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 
        or input.UserInputType == Enum.UserInputType.Touch then
            buttonInteracting = true
        end
    end)
    
    toggleButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 
        or input.UserInputType == Enum.UserInputType.Touch then
            buttonInteracting = false
        end
    end)

    mainFrame.InputBegan:Connect(function(input)
        if buttonInteracting then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then return end

        dragging  = true
        dragStart = input.Position
        startPos  = mainFrame.Position
    end)

    mainFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            buttonInteracting = false
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            buttonInteracting = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- // --- Post-Processing effects ---
local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "UShader_CC"
cc.Parent = Lighting

local bloom = Instance.new("BloomEffect")
bloom.Name = "UShader_Bloom"
bloom.Enabled = false
bloom.Parent = Lighting

local dof = Instance.new("DepthOfFieldEffect")
dof.Name = "UShader_DOF"
dof.Enabled = false
dof.Parent = Lighting

local atmos = Instance.new("Atmosphere")
atmos.Name = "UShader_Atmos"
atmos.Density = 0
atmos.Parent = Lighting

local shaderActive = false

-- // --- Toggle ---
local function setShader(on)
    local ok, err = pcall(function()
        if on then
            toggleButton.Text = "SHADER: ULTRA"
            toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 80)
            statusLabel.Text = "By Kadir | Active"
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)

            Lighting.GlobalShadows  = true
            Lighting.OutdoorAmbient = Color3.fromRGB(40, 45, 55)

            cc.Brightness = 0.03
            cc.Contrast   = 0.22
            cc.Saturation = 0.25
            cc.TintColor  = Color3.fromRGB(245, 240, 230)

            bloom.Intensity = 0.6
            bloom.Size      = 24
            bloom.Threshold = 0.75
            bloom.Enabled   = true

            dof.FarIntensity  = 0.05
            dof.FocusDistance = 35
            dof.InFocusRadius = 25
            dof.Enabled       = true

            pcall(function()
                for atm in pairs(existingAtmos) do
                    if atm and atm.Parent then atm.Density = 0 end
                end
            end)

            atmos.Density = 0.25
            atmos.Offset  = 0.25
            atmos.Color   = Color3.fromRGB(200, 210, 225)
            atmos.Decay   = Color3.fromRGB(90, 100, 115)
            atmos.Glare   = 0.3
            atmos.Haze    = 1.5
        else
            toggleButton.Text = "SHADER: OFF"
            toggleButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
            statusLabel.Text = "By Kadir"
            statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)

            Lighting.GlobalShadows  = originalLighting.GlobalShadows
            Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient

            cc.Brightness = 0
            cc.Contrast   = 0
            cc.Saturation = 0
            cc.TintColor  = Color3.new(1, 1, 1)

            bloom.Enabled = false
            dof.Enabled   = false

            pcall(function()
                for atm, orig in pairs(existingAtmos) do
                    if atm and atm.Parent then atm.Density = orig end
                end
            end)

            atmos.Density = 0
        end
    end)

    if not ok then
        warn("[MobileShader] setShader:", err)
        shaderActive = false
        _G.UShader.active = false
        toggleButton.Text = "SHADER: OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        statusLabel.Text = "By Kadir | Error"
        statusLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
        return
    end

    shaderActive = on
    _G.UShader.active = on
end

toggleButton.Activated:Connect(function()
    setShader(not shaderActive)
end)

print("[MobileShader] v3.4 By Kadir — Yüklendi.")
