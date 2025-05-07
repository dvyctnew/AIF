-- Base ESP Framework
local ESPFramework = {
    Players = {},
    Objects = {},
    Chams = {},
    Enabled = true,
    TeamCheck = true,
    ObjectTypes = {} -- Will be populated with game-specific objects
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

-- Configuration
local Config = {
    Players = {
        Box = {
            Enabled = true,
            Color = Color3.new(1, 1, 1),
            Thickness = 1,
            Transparency = 0,
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0)
        },
        Name = {
            Enabled = true,
            Color = Color3.new(1, 1, 1),
            Size = 14,
            Font = Drawing.Fonts.UI,
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0)
        },
        Distance = {
            Enabled = true,
            Color = Color3.new(1, 1, 1),
            Size = 14,
            Font = Drawing.Fonts.UI
        },
        HealthBar = {
            Enabled = true,
            Color = Color3.fromRGB(0, 255, 0),
            Width = 3,
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0)
        },
        Chams = {
            Enabled = false,
            Color = Color3.new(1, 0, 0),
            Transparency = 0.5,
            SizeOffset = Vector3.new(0.2, 0.2, 0.2)
        }
    },
    Objects = {
        Box = {
            Enabled = true,
            Color = Color3.new(0, 1, 1),
            Thickness = 1,
            Transparency = 0,
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0)
        },
        Name = {
            Enabled = true,
            Color = Color3.new(1, 1, 1),
            Size = 14,
            Font = Drawing.Fonts.UI,
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0)
        },
        Distance = {
            Enabled = true,
            Color = Color3.new(1, 1, 1),
            Size = 14,
            Font = Drawing.Fonts.UI
        },
        Chams = {
            Enabled = false,
            Color = Color3.new(0, 1, 1),
            Transparency = 0.3,
            SizeOffset = Vector3.new(0.1, 0.1, 0.1)
        }
    }
}

-- Utility Functions
local function WorldToViewport(position)
    local vector, onScreen = Camera:WorldToViewportPoint(position)
    return Vector2.new(vector.X, vector.Y), onScreen, vector.Z
end

local function GetMagnitude(position)
    return (Camera.CFrame.Position - position).Magnitude
end

-- Core ESP Functions
function ESPFramework:CreateChams(parent, config)
    if not parent or not parent:IsA("BasePart") then return end
    
    local chams = {
        Box = Instance.new("BoxHandleAdornment"),
        Label = Drawing.new("Text"),
        Distance = Drawing.new("Text")
    }
    
    -- Configure BoxHandleAdornment
    chams.Box.Name = "ESPChams"
    chams.Box.AlwaysOnTop = true
    chams.Box.ZIndex = 4
    chams.Box.Adornee = parent
    chams.Box.Color3 = config.Color
    chams.Box.Transparency = config.Transparency
    chams.Box.Size = parent.Size + config.SizeOffset
    chams.Box.Parent = parent
    
    -- Configure Name Label
    chams.Label.Text = parent.Name
    chams.Label.Visible = false
    chams.Label.Color = config.Name.Color
    chams.Label.Size = config.Name.Size
    chams.Label.Font = config.Name.Font
    chams.Label.Outline = config.Name.Outline
    chams.Label.OutlineColor = config.Name.OutlineColor
    chams.Label.Center = true
    
    -- Configure Distance Label
    chams.Distance.Visible = false
    chams.Distance.Color = config.Distance.Color
    chams.Distance.Size = config.Distance.Size
    chams.Distance.Font = config.Distance.Font
    chams.Distance.Outline = config.Distance.Outline
    chams.Distance.OutlineColor = config.Distance.OutlineColor
    chams.Distance.Center = true
    
    -- Store reference
    self.Chams[parent] = chams
    
    return chams
end

function ESPFramework:CreateESP(parent, config, isPlayer)
    if not parent or not parent:IsA("BasePart") then return end
    
    local esp = {
        Box = Drawing.new("Square"),
        BoxOutline = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        HealthBar = isPlayer and Drawing.new("Square") or nil,
        HealthBarOutline = isPlayer and Drawing.new("Square") or nil
    }
    
    -- Box setup
    esp.Box.Visible = false
    esp.Box.Filled = false
    esp.Box.Color = config.Box.Color
    esp.Box.Thickness = config.Box.Thickness
    esp.Box.Transparency = 1 - config.Box.Transparency
    
    -- Box outline setup
    esp.BoxOutline.Visible = false
    esp.BoxOutline.Filled = false
    esp.BoxOutline.Color = config.Box.OutlineColor
    esp.BoxOutline.Thickness = config.Box.Thickness + 1
    esp.BoxOutline.Transparency = 1 - config.Box.Transparency
    
    -- Name setup
    esp.Name.Visible = false
    esp.Name.Text = parent.Name
    esp.Name.Color = config.Name.Color
    esp.Name.Size = config.Name.Size
    esp.Name.Font = config.Name.Font
    esp.Name.Outline = config.Name.Outline
    esp.Name.OutlineColor = config.Name.OutlineColor
    esp.Name.Center = true
    
    -- Distance setup
    esp.Distance.Visible = false
    esp.Distance.Color = config.Distance.Color
    esp.Distance.Size = config.Distance.Size
    esp.Distance.Font = config.Distance.Font
    esp.Distance.Outline = config.Distance.Outline
    esp.Distance.OutlineColor = config.Distance.OutlineColor
    esp.Distance.Center = true
    
    -- Health bar setup (players only)
    if isPlayer then
        esp.HealthBar.Visible = false
        esp.HealthBar.Filled = true
        esp.HealthBar.Color = config.HealthBar.Color
        esp.HealthBar.Transparency = 1 - config.Box.Transparency
        
        esp.HealthBarOutline.Visible = false
        esp.HealthBarOutline.Filled = false
        esp.HealthBarOutline.Color = config.HealthBar.OutlineColor
        esp.HealthBarOutline.Thickness = 1
        esp.HealthBarOutline.Transparency = 1 - config.Box.Transparency
    end
    
    -- Store reference
    if isPlayer then
        self.Players[parent.Parent] = esp
    else
        self.Objects[parent] = esp
    end
    
    return esp
end

function ESPFramework:UpdateESP(esp, parent, config, isPlayer)
    if not esp or not parent or not parent.PrimaryPart then return end
    
    local rootPart = parent.PrimaryPart
    local rootPos, onScreen, depth = WorldToViewport(rootPart.Position)
    
    if onScreen and self.Enabled then
        -- Calculate box dimensions
        local headPos = WorldToViewport(rootPart.Position + Vector3.new(0, 2, 0))
        local legPos = WorldToViewport(rootPart.Position - Vector3.new(0, 2, 0))
        local boxHeight = math.abs(headPos.Y - legPos.Y)
        local boxWidth = boxHeight * 0.6
        
        -- Update box
        esp.Box.Visible = config.Box.Enabled
        esp.BoxOutline.Visible = config.Box.Enabled and config.Box.Outline
        esp.Box.Size = Vector2.new(boxWidth, boxHeight)
        esp.BoxOutline.Size = Vector2.new(boxWidth, boxHeight)
        esp.Box.Position = Vector2.new(rootPos.X - boxWidth/2, rootPos.Y - boxHeight/2)
        esp.BoxOutline.Position = esp.Box.Position
        
        -- Update name
        esp.Name.Visible = config.Name.Enabled
        esp.Name.Position = Vector2.new(esp.Box.Position.X + boxWidth/2, esp.Box.Position.Y - 20)
        
        -- Update distance
        esp.Distance.Visible = config.Distance.Enabled
        esp.Distance.Text = string.format("%.1f studs", GetMagnitude(rootPart.Position))
        esp.Distance.Position = Vector2.new(esp.Box.Position.X + boxWidth/2, esp.Box.Position.Y + boxHeight + 5)
        
        -- Update health bar (players only)
        if isPlayer and esp.HealthBar then
            local humanoid = parent:FindFirstChildOfClass("Humanoid")
            if humanoid then
                local healthPercentage = humanoid.Health / humanoid.MaxHealth
                
                esp.HealthBar.Visible = config.HealthBar.Enabled
                esp.HealthBarOutline.Visible = config.HealthBar.Enabled and config.HealthBar.Outline
                esp.HealthBar.Size = Vector2.new(config.HealthBar.Width, boxHeight * healthPercentage)
                esp.HealthBarOutline.Size = Vector2.new(config.HealthBar.Width + 2, boxHeight)
                esp.HealthBarOutline.Position = Vector2.new(esp.Box.Position.X - config.HealthBar.Width - 4, esp.Box.Position.Y)
                esp.HealthBar.Position = Vector2.new(esp.Box.Position.X - config.HealthBar.Width - 3, 
                                                   esp.Box.Position.Y + (boxHeight - esp.HealthBar.Size.Y))
            end
        end
        
        -- Team check for players
        if isPlayer and self.TeamCheck then
            local player = Players:GetPlayerFromCharacter(parent)
            if player and player.Team == Players.LocalPlayer.Team then
                esp.Box.Visible = false
                esp.BoxOutline.Visible = false
                esp.Name.Visible = false
                esp.Distance.Visible = false
                if esp.HealthBar then esp.HealthBar.Visible = false end
                if esp.HealthBarOutline then esp.HealthBarOutline.Visible = false end
            end
        end
    else
        esp.Box.Visible = false
        esp.BoxOutline.Visible = false
        esp.Name.Visible = false
        esp.Distance.Visible = false
        if esp.HealthBar then esp.HealthBar.Visible = false end
        if esp.HealthBarOutline then esp.HealthBarOutline.Visible = false end
    end
end

function ESPFramework:UpdateChams(chams, parent, config)
    if not chams or not parent or not parent:IsA("BasePart") then return end
    
    -- Update chams visibility
    chams.Box.Visible = config.Chams.Enabled
    chams.Box.Color3 = config.Chams.Color
    chams.Box.Transparency = config.Chams.Transparency
    chams.Box.Size = parent.Size + config.Chams.SizeOffset
    
    -- Update labels
    local rootPos, onScreen = WorldToViewport(parent.Position)
    if onScreen and config.Name.Enabled then
        chams.Label.Visible = true
        chams.Label.Position = Vector2.new(rootPos.X, rootPos.Y - 30)
        chams.Label.Text = parent.Name
        
        if config.Distance.Enabled then
            chams.Distance.Visible = true
            chams.Distance.Position = Vector2.new(rootPos.X, rootPos.Y - 15)
            chams.Distance.Text = string.format("%.1f studs", GetMagnitude(parent.Position))
        else
            chams.Distance.Visible = false
        end
    else
        chams.Label.Visible = false
        chams.Distance.Visible = false
    end
end

-- Player Handling
function ESPFramework:AddPlayer(player)
    if player == Players.LocalPlayer then return end
    
    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        local rootPart = character:WaitForChild("HumanoidRootPart")
        
        -- Create ESP
        local esp = self:CreateESP(rootPart, Config.Players, true)
        
        -- Create chams if enabled
        local chams
        if Config.Players.Chams.Enabled then
            chams = self:CreateChams(rootPart, Config.Players)
            self.Chams[character] = chams
        end
        
        -- Update loop
        local connection
        connection = RunService.RenderStepped:Connect(function()
            if not character or not character.Parent then
                connection:Disconnect()
                return
            end
            
            self:UpdateESP(esp, character, Config.Players, true)
            
            if chams then
                self:UpdateChams(chams, rootPart, Config.Players)
            end
        end)
    end)
    
    if player.Character then
        self:AddPlayer(player.Character)
    end
end

-- Object Handling
function ESPFramework:AddObject(object, objectType)
    if not object.PrimaryPart then return end
    
    -- Create ESP
    local esp = self:CreateESP(object.PrimaryPart, Config.Objects, false)
    
    -- Create chams if enabled
    local chams
    if Config.Objects.Chams.Enabled then
        chams = self:CreateChams(object.PrimaryPart, Config.Objects)
        self.Chams[object] = chams
    end
    
    -- Update loop
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not object or not object.Parent then
            connection:Disconnect()
            return
        end
        
        self:UpdateESP(esp, object, Config.Objects, false)
        
        if chams then
            self:UpdateChams(chams, object.PrimaryPart, Config.Objects)
        end
    end)
end

-- Initialization
function ESPFramework:Init()
    -- Setup existing players
    for _, player in ipairs(Players:GetPlayers()) do
        self:AddPlayer(player)
    end
    
    -- Setup player connections
    Players.PlayerAdded:Connect(function(player)
        self:AddPlayer(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        if player.Character and self.Players[player.Character] then
            for _, drawing in pairs(self.Players[player.Character]) do
                if drawing.Remove then drawing:Remove() end
            end
            self.Players[player.Character] = nil
        end
    end)
    
    -- Setup object tracking (game-specific)
    -- Example: workspace:GetDescendants() and check for specific objects
    -- This should be customized per game
end

-- Cleanup
function ESPFramework:Destroy()
    -- Clean up player ESP
    for _, esp in pairs(self.Players) do
        for _, drawing in pairs(esp) do
            if drawing and drawing.Remove then
                drawing:Remove()
            end
        end
    end
    
    -- Clean up object ESP
    for _, esp in pairs(self.Objects) do
        for _, drawing in pairs(esp) do
            if drawing and drawing.Remove then
                drawing:Remove()
            end
        end
    end
    
    -- Clean up chams
    for _, chams in pairs(self.Chams) do
        if chams.Box then chams.Box:Destroy() end
        if chams.Label then chams.Label:Remove() end
        if chams.Distance then chams.Distance:Remove() end
    end
    
    -- Clear tables
    self.Players = {}
    self.Objects = {}
    self.Chams = {}
end

return ESPFramework
