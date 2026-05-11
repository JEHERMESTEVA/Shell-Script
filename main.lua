---@diagnostic disable
-- ═══════════════════════════════════════════════════════════
-- Eminance UI
-- Premium fusion of Electro Sailor Piece styling +
-- Eminance reference (multi-column, fieldset-style)
-- ═══════════════════════════════════════════════════════════

if not game:IsLoaded() then game.Loaded:Wait() end
repeat task.wait() until game:GetService("Players")
repeat task.wait() until game:GetService("Players").LocalPlayer

local TS  = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS  = game:GetService("RunService")
local PL  = game:GetService("Players")
local RPS = game:GetService("ReplicatedStorage")
local HS  = game:GetService("HttpService")
local LP  = PL.LocalPlayer

local gethui = type(gethui) == "function" and gethui or nil

-- Executor file-system APIs (guarded — nil if executor doesn't support them).
local writefile  = type(writefile)  == "function" and writefile  or nil
local readfile   = type(readfile)   == "function" and readfile   or nil
local isfile     = type(isfile)     == "function" and isfile     or nil
local isfolder   = type(isfolder)   == "function" and isfolder   or nil
local makefolder = type(makefolder) == "function" and makefolder or nil
local listfiles  = type(listfiles)  == "function" and listfiles  or nil
local delfile    = type(delfile)    == "function" and delfile    or nil

--// ────────────────────────────  utils  ──────────────────────────── //--
local function Root()
    if gethui then
        local ok, r = pcall(gethui)
        if ok and r then return r end
    end
    local ok, r = pcall(function() return game:GetService("CoreGui") end)
    if ok and r then return r end
    return LP:WaitForChild("PlayerGui")
end

local function inst(class, props)
    local o = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            if k ~= "Parent" then o[k] = v end
        end
        if props.Parent then o.Parent = props.Parent end
    end
    return o
end

local function crn(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 4)
    c.Parent = o
    return c
end

local function strk(o, t, c, tr)
    local s = Instance.new("UIStroke")
    s.Thickness = t or 1
    s.Color = c or Color3.fromRGB(40, 45, 60)
    s.Transparency = tr or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = o
    return s
end

local function pad(o, t, r, b, l)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.PaddingLeft = UDim.new(0, l or 0)
    p.Parent = o
    return p
end

local function tw(o, t, props, es, ed)
    es = es or Enum.EasingStyle.Quint
    ed = ed or Enum.EasingDirection.Out
    local x = TS:Create(o, TweenInfo.new(t, es, ed), props)
    x:Play()
    return x
end

local EminanceRuntime = {
    Alive = true,
    Connections = {},
    ShutdownCallbacks = {},
}

local function IsAlive()
    return EminanceRuntime.Alive == true
end

local function TrackConnection(conn)
    if conn and type(conn.Disconnect) == "function" then
        table.insert(EminanceRuntime.Connections, conn)
    end
    return conn
end

local function OnShutdown(fn)
    if type(fn) == "function" then
        table.insert(EminanceRuntime.ShutdownCallbacks, fn)
    end
end

local function ShutdownRuntime()
    if not EminanceRuntime.Alive then return end
    EminanceRuntime.Alive = false
    for _, fn in ipairs(EminanceRuntime.ShutdownCallbacks) do
        pcall(fn)
    end
    for _, conn in ipairs(EminanceRuntime.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(EminanceRuntime.Connections)
    table.clear(EminanceRuntime.ShutdownCallbacks)
end

local function safe(f, ...)
    if not IsAlive() then return end
    if type(f) == "function" then pcall(f, ...) end
end

local function RuntimeWait(seconds)
    local deadline = os.clock() + math.max(0, seconds or 0)
    while IsAlive() and os.clock() < deadline do
        task.wait(math.min(0.05, deadline - os.clock()))
    end
    return IsAlive()
end

if type(getgenv) == "function" then
    getgenv().EminanceRuntime = EminanceRuntime
end

local GhostTP = {}
do
    local hidden = {}
    local camFrozen = false
    local oldCamType, oldCamSubject, frozenCamCF, activeCamMode
    local bindName = "Eminance_GhostTP_Camera"
    local decoy
    local ghostBusy = false
    local decoyFollowConn

    local function hideCharacter()
        hidden = {}
        local char = LP.Character
        if not char then return end
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("BasePart") then
                table.insert(hidden, {obj, "LocalTransparencyModifier", obj.LocalTransparencyModifier})
                obj.LocalTransparencyModifier = 1
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                table.insert(hidden, {obj, "Transparency", obj.Transparency})
                obj.Transparency = 1
            end
        end
    end

    local function showCharacter()
        for _, item in ipairs(hidden) do
            local obj, prop, value = item[1], item[2], item[3]
            if obj and obj.Parent then
                pcall(function() obj[prop] = value end)
            end
        end
        hidden = {}
    end

    local function destroyDecoy()
        if decoyFollowConn then
            decoyFollowConn:Disconnect()
            decoyFollowConn = nil
        end
        if decoy then
            decoy:Destroy()
            decoy = nil
        end
    end

    local function followDecoy(pivot, hum, startedAt)
        if not decoy or not hum then return end
        if decoyFollowConn then
            decoyFollowConn:Disconnect()
            decoyFollowConn = nil
        end
        decoyFollowConn = TrackConnection(RS.RenderStepped:Connect(function()
            if not IsAlive() then destroyDecoy(); return end
            if not decoy or not decoy.Parent or not hum or not hum.Parent then return end
            local dir = hum.MoveDirection
            local elapsed = math.clamp(os.clock() - startedAt, 0, 0.6)
            local offset = Vector3.zero
            if dir and dir.Magnitude > 0.05 then
                offset = dir.Unit * math.min((hum.WalkSpeed or 16) * elapsed, 8)
            end
            decoy:PivotTo(CFrame.new(pivot.Position + offset) * (pivot - pivot.Position))
        end))
    end

    local function makeDecoy(char, pivot)
        destroyDecoy()
        if not char then return end
        local oldArchivable = char.Archivable
        char.Archivable = true
        local ok, clone = pcall(function() return char:Clone() end)
        char.Archivable = oldArchivable
        if not ok or not clone then return end
        clone.Name = "Eminance_GhostTP_Decoy"
        for _, obj in ipairs(clone:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.Anchored = true
                obj.CanCollide = false
                obj.CanTouch = false
                obj.CanQuery = false
                obj.AssemblyLinearVelocity = Vector3.zero
                obj.AssemblyAngularVelocity = Vector3.zero
                if obj.Name == "HumanoidRootPart" then
                    obj.Transparency = 1
                end
            elseif obj:IsA("Humanoid") then
                obj.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                obj.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
                obj.PlatformStand = true
            elseif obj:IsA("Script") or obj:IsA("LocalScript") then
                obj:Destroy()
            end
        end
        clone:PivotTo(pivot)
        clone.Parent = workspace
        decoy = clone
        return clone
    end

    local function freezeCamera(mode)
        if camFrozen then return end
        local cam = workspace.CurrentCamera
        if not cam then return end
        oldCamType = cam.CameraType
        oldCamSubject = cam.CameraSubject
        frozenCamCF = cam.CFrame
        activeCamMode = mode or "hard"
        if activeCamMode == "soft" and decoy and decoy.Parent then
            local decoyHum = decoy:FindFirstChildOfClass("Humanoid")
            if decoyHum then
                cam.CameraType = Enum.CameraType.Custom
                cam.CameraSubject = decoyHum
                pcall(function()
                    RS:BindToRenderStep(bindName, Enum.RenderPriority.Last.Value, function()
                        local current = workspace.CurrentCamera
                        if current and decoy and decoy.Parent and decoyHum and decoyHum.Parent then
                            if current.CameraType ~= Enum.CameraType.Custom then
                                current.CameraType = Enum.CameraType.Custom
                            end
                            if current.CameraSubject ~= decoyHum then
                                current.CameraSubject = decoyHum
                            end
                        end
                    end)
                end)
                camFrozen = true
                return
            end
        end
        cam.CameraType = Enum.CameraType.Scriptable
        cam.CFrame = frozenCamCF
        pcall(function()
            RS:BindToRenderStep(bindName, Enum.RenderPriority.Last.Value, function()
                local current = workspace.CurrentCamera
                if current and frozenCamCF then
                    current.CFrame = frozenCamCF
                end
            end)
        end)
        camFrozen = true
    end

    local function unfreezeCamera(force)
        if not camFrozen and not force then return end
        pcall(function() RS:UnbindFromRenderStep(bindName) end)
        local cam = workspace.CurrentCamera
        if cam then
            local char = LP.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            cam.CameraType = Enum.CameraType.Custom
            cam.CameraSubject = hum or oldCamSubject
            task.defer(function()
                local current = workspace.CurrentCamera
                local currentChar = LP.Character
                local currentHum = currentChar and currentChar:FindFirstChildOfClass("Humanoid")
                if current then
                    current.CameraType = Enum.CameraType.Custom
                    if currentHum then
                        current.CameraSubject = currentHum
                    end
                end
            end)
        end
        camFrozen = false
        oldCamType = nil
        oldCamSubject = nil
        frozenCamCF = nil
        activeCamMode = nil
    end

    local function zeroVelocity(hrp)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.Velocity = Vector3.zero
    end

    local function applyVelocity(hrp, linear, angular)
        hrp.AssemblyLinearVelocity = linear or Vector3.zero
        hrp.AssemblyAngularVelocity = angular or Vector3.zero
        hrp.Velocity = linear or Vector3.zero
    end

    local function movedReturnCFrame(origin, hum, startedAt, maxStuds)
        if not hum then return origin end
        local dir = hum.MoveDirection
        if not dir or dir.Magnitude <= 0.05 then return origin end
        local duration = math.clamp(os.clock() - startedAt, 0, 0.75)
        local dist = math.min((hum.WalkSpeed or 16) * duration, maxStuds or 10)
        if dist <= 0 then return origin end
        return CFrame.new(origin.Position + dir.Unit * dist) * (origin - origin.Position)
    end

    local function waitAbort(seconds, abort)
        local deadline = os.clock() + math.max(0, seconds or 0)
        while os.clock() < deadline do
            if abort and abort() then return false end
            task.wait(math.min(0.03, deadline - os.clock()))
        end
        return not (abort and abort())
    end

    function GhostTP.Run(targetCFrame, callback, opts)
        if not IsAlive() then return false end
        opts = opts or {}
        if typeof(targetCFrame) == "Vector3" then
            targetCFrame = CFrame.new(targetCFrame)
        end
        if typeof(targetCFrame) ~= "CFrame" then
            return false
        end

        local char = LP.Character or LP.CharacterAdded:Wait()
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp then return false end
        if ghostBusy then return false, "busy" end
        ghostBusy = true

        local origin = hrp.CFrame
        local originLinear = hrp.AssemblyLinearVelocity
        local originAngular = hrp.AssemblyAngularVelocity
        local startedAt = os.clock()
        local arrivalDelay = tonumber(opts.ArrivalDelay or opts.arrivalDelay or 0.15) or 0.15
        local hold = tonumber(opts.Hold or opts.hold or 0) or 0
        local doubleDelay = tonumber(opts.DoubleDelay or opts.doubleDelay or 0.04) or 0.04
        local returnBack = opts.ReturnBack ~= false and opts.returnBack ~= false
        local doubleTP = opts.Double ~= false and opts.double ~= false
        local useDecoy = opts.Decoy == true or opts.decoy == true
        local compensateMove = opts.CompensateMove ~= false and opts.compensateMove ~= false
        local maxCompensate = tonumber(opts.MaxCompensate or opts.maxCompensate or 10) or 10
        local cameraMode = opts.CameraMode or opts.cameraMode or "hard"
        local userAbort = opts.Abort or opts.abort
        local abort = function()
            return not IsAlive() or (userAbort and userAbort())
        end
        local result
        local returned = false

        if abort and abort() then
            ghostBusy = false
            return false, "aborted"
        end
        if useDecoy then
            makeDecoy(char, origin)
            if cameraMode == "soft" then
                followDecoy(origin, hum, startedAt)
            end
        end
        hideCharacter()
        freezeCamera(cameraMode)
        RS.RenderStepped:Wait()

        local ok, err = pcall(function()
            hrp.CFrame = targetCFrame
            zeroVelocity(hrp)
            if doubleTP then
                if not waitAbort(doubleDelay, abort) then return end
                hrp.CFrame = targetCFrame
                zeroVelocity(hrp)
            end
            if arrivalDelay > 0 then
                if not waitAbort(arrivalDelay, abort) then return end
            end
            if (not abort or not abort()) and type(callback) == "function" then
                result = callback(hrp, origin)
            end
            if hold > 0 then
                waitAbort(hold, abort)
            end
            if returnBack then
                local back = compensateMove and movedReturnCFrame(origin, hum, startedAt, maxCompensate) or origin
                hrp.CFrame = back
                applyVelocity(hrp, originLinear, originAngular)
                returned = true
                RS.RenderStepped:Wait()
            end
        end)

        if returnBack and not returned then
            pcall(function()
                hrp.CFrame = origin
                applyVelocity(hrp, originLinear, originAngular)
            end)
            RS.RenderStepped:Wait()
        end
        if returnBack then
            RS.RenderStepped:Wait()
        end
        destroyDecoy()
        showCharacter()
        unfreezeCamera(true)
        ghostBusy = false
        if not ok then
            return false, err
        end
        return true, result
    end

    function GhostTP.Teleport(targetCFrame, opts)
        if not IsAlive() then return false end
        opts = opts or {}
        if typeof(targetCFrame) == "Vector3" then
            targetCFrame = CFrame.new(targetCFrame)
        end
        if typeof(targetCFrame) ~= "CFrame" then
            return false
        end

        local char = LP.Character or LP.CharacterAdded:Wait()
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp then return false end
        if ghostBusy then return false end
        ghostBusy = true

        local origin = hrp.CFrame
        local originLinear = hrp.AssemblyLinearVelocity
        local originAngular = hrp.AssemblyAngularVelocity
        local startedAt = os.clock()
        local hold = tonumber(opts.Hold or opts.hold or 0) or 0
        local doubleDelay = tonumber(opts.DoubleDelay or opts.doubleDelay or 0.04) or 0.04
        local returnBack = opts.ReturnBack == true or opts.returnBack == true
        local doubleTP = opts.Double ~= false and opts.double ~= false
        local useDecoy = opts.Decoy == true or opts.decoy == true
        local compensateMove = opts.CompensateMove ~= false and opts.compensateMove ~= false
        local maxCompensate = tonumber(opts.MaxCompensate or opts.maxCompensate or 10) or 10
        local cameraMode = opts.CameraMode or opts.cameraMode or "hard"
        local userAbort = opts.Abort or opts.abort
        local abort = function()
            return not IsAlive() or (userAbort and userAbort())
        end
        local returned = false

        if abort and abort() then
            ghostBusy = false
            return false
        end
        if useDecoy then
            makeDecoy(char, origin)
            if cameraMode == "soft" then
                followDecoy(origin, hum, startedAt)
            end
        end
        hideCharacter()
        freezeCamera(cameraMode)
        RS.RenderStepped:Wait()

        local ok = pcall(function()
            hrp.CFrame = targetCFrame
            zeroVelocity(hrp)
            if doubleTP then
                if not waitAbort(doubleDelay, abort) then return end
                hrp.CFrame = targetCFrame
                zeroVelocity(hrp)
            end
            if hold > 0 then
                waitAbort(hold, abort)
            end
            if returnBack then
                local back = compensateMove and movedReturnCFrame(origin, hum, startedAt, maxCompensate) or origin
                hrp.CFrame = back
                applyVelocity(hrp, originLinear, originAngular)
                returned = true
                RS.RenderStepped:Wait()
            end
        end)

        if returnBack and not returned then
            pcall(function()
                hrp.CFrame = origin
                applyVelocity(hrp, originLinear, originAngular)
            end)
            RS.RenderStepped:Wait()
        end
        if returnBack then
            RS.RenderStepped:Wait()
        end
        destroyDecoy()
        showCharacter()
        unfreezeCamera(true)
        ghostBusy = false
        return ok
    end

    function GhostTP.Restore()
        ghostBusy = false
        destroyDecoy()
        unfreezeCamera(true)
        showCharacter()
    end
end

if type(getgenv) == "function" then
    getgenv().GhostTP = GhostTP
    getgenv().GhostTPTo = function(targetCFrame, opts)
        return GhostTP.Teleport(targetCFrame, opts)
    end
end

local function ripple(p, col)
    if not p or not p.Parent then return end
    local c = inst("Frame", {
        Parent = p,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(0, 0),
        BackgroundColor3 = col or Color3.fromRGB(140, 120, 230),
        BackgroundTransparency = 0.55,
        BorderSizePixel = 0,
        ZIndex = (p.ZIndex or 1) + 5,
    })
    crn(c, 999)
    tw(c, 0.5, {Size = UDim2.fromScale(2, 2), BackgroundTransparency = 1}, Enum.EasingStyle.Quad)
    task.delay(0.55, function() if c then c:Destroy() end end)
end

local function mkdrag(handle, target)
    local dn, ds, dp
    handle.InputBegan:Connect(function(i)
        if not IsAlive() then return end
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dn = true; ds = i.Position; dp = target.Position
            local conn
            conn = i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then
                    dn = false; if conn then conn:Disconnect() end
                end
            end)
        end
    end)
    TrackConnection(UIS.InputChanged:Connect(function(i)
        if not IsAlive() then return end
        if dn and ds and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            target.Position = UDim2.new(dp.X.Scale, dp.X.Offset + d.X, dp.Y.Scale, dp.Y.Offset + d.Y)
        end
    end))
    TrackConnection(UIS.InputEnded:Connect(function(i)
        if not IsAlive() then return end
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dn = false end
    end))
end

local function keyName(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then return "M1" end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then return "M2" end
    if input.UserInputType == Enum.UserInputType.MouseButton3 then return "M3" end
    if input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown then
        local n = input.KeyCode.Name
        if #n > 3 then return n:sub(1, 3):upper() end
        return n:upper()
    end
    return "..."
end

--// ────────────────────────────  theme  ──────────────────────────── //--
local T = {
    Outer    = Color3.fromRGB(4, 4, 6),
    Panel    = Color3.fromRGB(12, 12, 15),
    PanelHi  = Color3.fromRGB(18, 18, 22),
    Header   = Color3.fromRGB(8, 8, 11),
    Slot     = Color3.fromRGB(24, 24, 28),
    SlotHi   = Color3.fromRGB(34, 34, 40),
    Border   = Color3.fromRGB(24, 24, 30),
    BorderHi = Color3.fromRGB(62, 38, 96),
    Text     = Color3.fromRGB(235, 232, 242),
    TextSoft = Color3.fromRGB(185, 182, 198),
    Muted    = Color3.fromRGB(112, 108, 124),
    Dim      = Color3.fromRGB(72, 68, 84),
    Accent   = Color3.fromRGB(145, 20, 230),
    AccentHi = Color3.fromRGB(190, 80, 255),
    AccentLo = Color3.fromRGB(92, 8, 170),
    Red      = Color3.fromRGB(210, 65, 95),
    Purple   = Color3.fromRGB(150, 110, 230),
    Cyan     = Color3.fromRGB(80, 200, 230),
    Green    = Color3.fromRGB(80, 200, 130),
    Glow     = Color3.fromRGB(120, 28, 210),
}

local F = {
    Bold = Enum.Font.GothamBold,
    Med  = Enum.Font.GothamMedium,
    Reg  = Enum.Font.Gotham,
}

--// ────────────────────────────  theme registry & presets  ──────────────────────────── //--
-- All Electro Sailor-style themed objects are tracked here so a single _SetAccent call
-- repaints every registered Frame/Text/Stroke/Image instantly.
local _themed = {}
local _gradients = {}

local function regBg(o, key)     table.insert(_themed, {type = "bg",     obj = o, key = key}) end
local function regText(o, key)   table.insert(_themed, {type = "text",   obj = o, key = key}) end
local function regImg(o, key)    table.insert(_themed, {type = "image",  obj = o, key = key}) end
local function regStroke(o, key) table.insert(_themed, {type = "stroke", obj = o, key = key}) end
local function regGrad(grad, keys)
    table.insert(_gradients, {grad = grad, keys = keys})
end
-- Stateful widgets (toggle ON, slider drag, etc.) push callbacks that re-apply
-- their visual state after the registry repaints. Without this, the registry
-- forces baseline colors even when the widget should look "active".
local _themeCallbacks = {}
local function regCallback(fn) table.insert(_themeCallbacks, fn) end

-- Shimmer system: brightness-based glint that works on every theme.
-- The gradient multiplies with TextColor3 — base is dimmed (50% of text color),
-- peak is full bright (1.0× → original text color), producing a strong
-- dim→bright→dim glint regardless of accent or background.
local _shimmers = {}
local _shimmerStart = tick()
local function _shimmerColorSeq()
    local dim = Color3.fromRGB(110, 110, 110)   -- ~43% gray, multiplies onto text
    local mid = Color3.fromRGB(180, 180, 180)
    local hi  = Color3.fromRGB(255, 255, 255)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0,    dim),
        ColorSequenceKeypoint.new(0.30, dim),
        ColorSequenceKeypoint.new(0.45, mid),
        ColorSequenceKeypoint.new(0.5,  hi),
        ColorSequenceKeypoint.new(0.55, mid),
        ColorSequenceKeypoint.new(0.70, dim),
        ColorSequenceKeypoint.new(1,    dim),
    })
end
local function makeShimmer(parent, _unusedKey, speed)
    local g = Instance.new("UIGradient")
    g.Color = _shimmerColorSeq()
    g.Rotation = 0
    g.Offset = Vector2.new(-1, 0)
    g.Parent = parent
    table.insert(_shimmers, {grad = g, speed = speed or 0.5, target = parent})
    return g
end
RS.Heartbeat:Connect(function()
    local t = tick() - _shimmerStart
    for i = #_shimmers, 1, -1 do
        local s = _shimmers[i]
        if not s.grad or not s.grad.Parent then
            table.remove(_shimmers, i)
        else
            local cycle = 4 / s.speed
            local phase = (t % cycle) / cycle
            s.grad.Offset = Vector2.new(phase * 2 - 1, 0)
        end
    end
end)

-- Каждый preset описывает ПОЛНУЮ палитру: фон / панели / border / текст / accent.
-- При смене темы плавно перекрашивается весь UI.
local Presets = {
    {
        name = "Light",
        accent   = Color3.fromRGB(120, 100, 220),accentLo = Color3.fromRGB(85, 70, 190),   accentHi = Color3.fromRGB(155, 130, 245),
        Outer    = Color3.fromRGB(238, 240, 246),Panel    = Color3.fromRGB(248, 249, 252), PanelHi  = Color3.fromRGB(255, 255, 255),
        Header   = Color3.fromRGB(228, 230, 238),Slot     = Color3.fromRGB(232, 234, 242), SlotHi   = Color3.fromRGB(220, 224, 234),
        Border   = Color3.fromRGB(196, 202, 218),BorderHi = Color3.fromRGB(150, 158, 184),
        Text     = Color3.fromRGB(28, 32, 44),   TextSoft = Color3.fromRGB(58, 64, 82),    Muted    = Color3.fromRGB(110, 118, 138),
        Dim      = Color3.fromRGB(150, 156, 174),Glow     = Color3.fromRGB(150, 130, 240),
    },
    {
        name = "Dark Moon Purple",
        accent   = Color3.fromRGB(155, 110, 245),accentLo = Color3.fromRGB(110,  72, 210),  accentHi = Color3.fromRGB(195, 155, 255),
        Outer    = Color3.fromRGB(13, 11, 18),   Panel    = Color3.fromRGB(18, 16, 26),    PanelHi  = Color3.fromRGB(24, 20, 34),
        Header   = Color3.fromRGB(10,  8, 14),   Slot     = Color3.fromRGB(28, 24, 38),    SlotHi   = Color3.fromRGB(38, 32, 52),
        Border   = Color3.fromRGB(48, 42, 68),   BorderHi = Color3.fromRGB(90, 75, 130),
        Text     = Color3.fromRGB(232, 224, 248),TextSoft = Color3.fromRGB(196, 188, 222), Muted    = Color3.fromRGB(140, 130, 174),
        Dim      = Color3.fromRGB(100, 90, 130), Glow     = Color3.fromRGB(140, 100, 230),
    },
    {
        name = "Strict Black",
        accent   = Color3.fromRGB(220, 220, 230),accentLo = Color3.fromRGB(170, 170, 180), accentHi = Color3.fromRGB(255, 255, 255),
        Outer    = Color3.fromRGB(0,  0,  0),    Panel    = Color3.fromRGB(8,  8, 10),     PanelHi  = Color3.fromRGB(14, 14, 16),
        Header   = Color3.fromRGB(0,  0,  0),    Slot     = Color3.fromRGB(18, 18, 20),    SlotHi   = Color3.fromRGB(26, 26, 30),
        Border   = Color3.fromRGB(36, 36, 40),   BorderHi = Color3.fromRGB(72, 72, 80),
        Text     = Color3.fromRGB(238, 238, 240),TextSoft = Color3.fromRGB(204, 204, 210),Muted    = Color3.fromRGB(140, 140, 148),
        Dim      = Color3.fromRGB(96,  96, 102), Glow     = Color3.fromRGB(180, 180, 190),
    },
    {
        name = "Indigo",
        accent   = Color3.fromRGB(140, 122, 232), accentLo = Color3.fromRGB(95, 105, 220),  accentHi = Color3.fromRGB(170, 150, 250),
        Outer    = Color3.fromRGB(10, 12, 18),   Panel    = Color3.fromRGB(15, 17, 25),    PanelHi  = Color3.fromRGB(20, 22, 32),
        Header   = Color3.fromRGB(8, 10, 15),    Slot     = Color3.fromRGB(22, 24, 34),    SlotHi   = Color3.fromRGB(30, 33, 46),
        Border   = Color3.fromRGB(38, 42, 58),   BorderHi = Color3.fromRGB(70, 80, 110),
        Text     = Color3.fromRGB(220, 222, 230),TextSoft = Color3.fromRGB(190, 192, 205), Muted    = Color3.fromRGB(135, 140, 158),
        Dim      = Color3.fromRGB(95, 100, 118), Glow     = Color3.fromRGB(120, 110, 220),
    },
    {
        name = "Crimson",
        accent   = Color3.fromRGB(225,  70,  95),accentLo = Color3.fromRGB(180,  40,  70), accentHi = Color3.fromRGB(255, 105, 130),
        Outer    = Color3.fromRGB(16, 10, 12),   Panel    = Color3.fromRGB(22, 14, 18),    PanelHi  = Color3.fromRGB(30, 18, 24),
        Header   = Color3.fromRGB(12, 8, 10),    Slot     = Color3.fromRGB(34, 20, 26),    SlotHi   = Color3.fromRGB(46, 26, 34),
        Border   = Color3.fromRGB(70, 38, 48),   BorderHi = Color3.fromRGB(120, 60, 80),
        Text     = Color3.fromRGB(232, 220, 222),TextSoft = Color3.fromRGB(208, 188, 192), Muted    = Color3.fromRGB(160, 130, 138),
        Dim      = Color3.fromRGB(110, 90, 96),  Glow     = Color3.fromRGB(190, 60, 90),
    },
    {
        name = "Aqua",
        accent   = Color3.fromRGB( 80, 200, 230),accentLo = Color3.fromRGB( 40, 150, 200), accentHi = Color3.fromRGB(140, 230, 255),
        Outer    = Color3.fromRGB(8, 14, 18),    Panel    = Color3.fromRGB(12, 20, 26),    PanelHi  = Color3.fromRGB(16, 26, 34),
        Header   = Color3.fromRGB(6, 12, 16),    Slot     = Color3.fromRGB(18, 30, 38),    SlotHi   = Color3.fromRGB(26, 40, 52),
        Border   = Color3.fromRGB(34, 56, 72),   BorderHi = Color3.fromRGB(60, 110, 140),
        Text     = Color3.fromRGB(218, 232, 238),TextSoft = Color3.fromRGB(186, 210, 218), Muted    = Color3.fromRGB(130, 160, 175),
        Dim      = Color3.fromRGB(90, 116, 130), Glow     = Color3.fromRGB(60, 180, 220),
    },
    {
        name = "Toxic",
        accent   = Color3.fromRGB(120, 230, 110),accentLo = Color3.fromRGB( 70, 180,  80), accentHi = Color3.fromRGB(170, 250, 150),
        Outer    = Color3.fromRGB(10, 16, 10),   Panel    = Color3.fromRGB(14, 22, 14),    PanelHi  = Color3.fromRGB(18, 30, 20),
        Header   = Color3.fromRGB(8, 12, 8),     Slot     = Color3.fromRGB(20, 32, 22),    SlotHi   = Color3.fromRGB(28, 44, 30),
        Border   = Color3.fromRGB(44, 66, 46),   BorderHi = Color3.fromRGB(80, 130, 80),
        Text     = Color3.fromRGB(222, 232, 218),TextSoft = Color3.fromRGB(192, 210, 188), Muted    = Color3.fromRGB(140, 162, 138),
        Dim      = Color3.fromRGB(98, 118, 96),  Glow     = Color3.fromRGB(100, 200, 90),
    },
    {
        name = "Inferno",
        accent   = Color3.fromRGB(255, 140,  40),accentLo = Color3.fromRGB(220,  80,  30), accentHi = Color3.fromRGB(255, 200,  80),
        Outer    = Color3.fromRGB(18, 12, 8),    Panel    = Color3.fromRGB(24, 16, 10),    PanelHi  = Color3.fromRGB(32, 22, 14),
        Header   = Color3.fromRGB(14, 10, 6),    Slot     = Color3.fromRGB(36, 24, 16),    SlotHi   = Color3.fromRGB(50, 32, 20),
        Border   = Color3.fromRGB(76, 50, 30),   BorderHi = Color3.fromRGB(130, 80, 44),
        Text     = Color3.fromRGB(238, 224, 210),TextSoft = Color3.fromRGB(214, 196, 178), Muted    = Color3.fromRGB(170, 144, 122),
        Dim      = Color3.fromRGB(120, 96, 78),  Glow     = Color3.fromRGB(230, 120, 50),
    },
    {
        name = "Midnight",
        accent   = Color3.fromRGB(110, 140, 255),accentLo = Color3.fromRGB(70, 100, 220),  accentHi = Color3.fromRGB(160, 180, 255),
        Outer    = Color3.fromRGB(6, 7, 12),     Panel    = Color3.fromRGB(10, 12, 20),    PanelHi  = Color3.fromRGB(14, 16, 26),
        Header   = Color3.fromRGB(4, 5, 10),     Slot     = Color3.fromRGB(16, 18, 28),    SlotHi   = Color3.fromRGB(22, 24, 38),
        Border   = Color3.fromRGB(28, 32, 50),   BorderHi = Color3.fromRGB(56, 66, 100),
        Text     = Color3.fromRGB(228, 232, 246),TextSoft = Color3.fromRGB(196, 202, 222), Muted    = Color3.fromRGB(140, 148, 176),
        Dim      = Color3.fromRGB(96, 104, 130), Glow     = Color3.fromRGB(90, 120, 240),
    },
}
local PresetNames = {} ; for _, p in ipairs(Presets) do table.insert(PresetNames, p.name) end

local function findPreset(n) for _, p in ipairs(Presets) do if p.name == n then return p end end end

-- Список ключей палитры, которые preset может переопределить.
local _themeKeys = {
    "Outer", "Panel", "PanelHi", "Header", "Slot", "SlotHi",
    "Border", "BorderHi", "Text", "TextSoft", "Muted", "Dim",
    "Accent", "AccentHi", "AccentLo", "Glow",
}

-- map alias пресетных ключей (lowercase) на T-ключи.
local _aliasMap = {accent = "Accent", accentHi = "AccentHi", accentLo = "AccentLo"}

local function _applyPresetToT(p)
    for k, v in pairs(p) do
        if k ~= "name" then
            local tk = _aliasMap[k] or k
            if T[tk] ~= nil then T[tk] = v end
        end
    end
    -- Glow по умолчанию = AccentLo, если не задан.
    if not p.Glow and p.accentLo then T.Glow = p.accentLo end
end

-- Apply default theme (Light) to T BEFORE any UI is built so all widgets
-- inherit the light palette from construction time.
_applyPresetToT(Presets[1])

local function applyThemeAll(animated)
    local dur = animated and 0.35 or 0
    for _, e in ipairs(_themed) do
        pcall(function()
            if not e.obj or not e.obj.Parent then return end
            local target = T[e.key]
            if not target then return end
            local prop = e.type == "bg"     and "BackgroundColor3"
                      or e.type == "text"   and "TextColor3"
                      or e.type == "image"  and "ImageColor3"
                      or e.type == "stroke" and "Color"
            if not prop then return end
            if dur > 0 then
                TS:Create(e.obj, TweenInfo.new(dur, Enum.EasingStyle.Quad), {[prop] = target}):Play()
            else
                e.obj[prop] = target
            end
        end)
    end
    for _, g in ipairs(_gradients) do
        pcall(function()
            if not g.grad or not g.grad.Parent then return end
            local kps = {}
            local n = #g.keys
            for i, k in ipairs(g.keys) do
                table.insert(kps, ColorSequenceKeypoint.new((i - 1) / math.max(n - 1, 1), T[k]))
            end
            -- ColorSequence не tween-ится в TweenService, поэтому ставим напрямую.
            g.grad.Color = ColorSequence.new(kps)
        end)
    end
    -- after baseline colors are applied, re-run stateful widget callbacks
    -- so an ON toggle stays Accent, a focused slider keeps its hover stroke, etc.
    for _, fn in ipairs(_themeCallbacks) do pcall(fn, animated) end
end

--// ────────────────────────────  glass effect / particles  ──────────────────────────── //--
local function applyGlassEffect(parent, transparency)
    transparency = transparency or 0.08
    local glass = inst("Frame", {
        Parent = parent,
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = T.Outer,
        BackgroundTransparency = 1 - transparency,
        BorderSizePixel = 0,
        ZIndex = (parent.ZIndex or 1) + 1,
    })
    crn(glass, 6)
    local g1 = Instance.new("UIGradient")
    g1.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   T.Panel),
        ColorSequenceKeypoint.new(0.5, T.Outer),
        ColorSequenceKeypoint.new(1,   T.PanelHi),
    })
    g1.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,   0.15),
        NumberSequenceKeypoint.new(0.5, 0.35),
        NumberSequenceKeypoint.new(1,   0.6),
    })
    g1.Rotation = 135
    g1.Parent = glass
    regGrad(g1, {"Panel", "Outer", "PanelHi"})

    local accentGlass = inst("Frame", {
        Parent = parent,
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = T.Accent,
        BackgroundTransparency = 0.92,
        BorderSizePixel = 0,
        ZIndex = (parent.ZIndex or 1) + 2,
    })
    crn(accentGlass, 6)
    regBg(accentGlass, "Accent")
    local g2 = Instance.new("UIGradient")
    g2.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,   0.85),
        NumberSequenceKeypoint.new(0.5, 0.97),
        NumberSequenceKeypoint.new(1,   0.85),
    })
    g2.Rotation = 45
    g2.Parent = accentGlass

    local noise = inst("ImageLabel", {
        Parent = parent,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Image = "rbxassetid://4890919580",
        ImageTransparency = 0.92,
        ImageColor3 = T.Muted,
        ScaleType = Enum.ScaleType.Tile,
        TileSize = UDim2.fromOffset(160, 160),
        ZIndex = (parent.ZIndex or 1) + 3,
    })
    regImg(noise, "Muted")
end

local function createParticles(parent, color, count)
    count = count or 10
    local container = inst("Frame", {Parent = parent, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = (parent.ZIndex or 1) + 4, ClipsDescendants = true})
    task.spawn(function()
        for i = 1, count do
            if not IsAlive() then break end
            if not container or not container.Parent then break end
            local p = inst("Frame", {
                Parent = container,
                Size = UDim2.fromOffset(math.random(2, 5), math.random(2, 5)),
                Position = UDim2.new(math.random(), 0, math.random(), 0),
                BackgroundColor3 = color or T.Accent,
                BackgroundTransparency = math.random(70, 90) / 100,
                BorderSizePixel = 0,
                ZIndex = container.ZIndex + 1,
            })
            crn(p, 99)
            local off = UDim2.new(0, math.random(-90, 90), 0, math.random(-90, 90))
            tw(p, math.random(12, 22), {Position = p.Position + off, BackgroundTransparency = 1}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.spawn(function()
                RuntimeWait(math.random(12, 22))
                if p then p:Destroy() end
            end)
            if not RuntimeWait(math.random(40, 110) / 100) then break end
        end
    end)
    return container
end

--// ────────────────────────────  sound helper  ──────────────────────────── //--
local function playSfx(idOrPath, vol, pitch)
    task.spawn(function()
        pcall(function()
            local s = Instance.new("Sound")
            if type(idOrPath) == "number" then
                s.SoundId = "rbxassetid://" .. tostring(idOrPath)
            elseif type(idOrPath) == "string" then
                if string.find(idOrPath, "://", 1, true) then
                    s.SoundId = idOrPath
                else
                    s.SoundId = "rbxassetid://" .. idOrPath
                end
            else return end
            s.Volume = vol or 0.3
            s.PlaybackSpeed = pitch or 1
            s.PlayOnRemove = true
            s.Parent = workspace
            s:Destroy()
        end)
    end)
end

-- Named SFX events use a single Roblox built-in (electronicpingshort.wav,
-- always shipped with the client, so no risk of malformed/unwanted assets)
-- and vary pitch+volume so each action feels distinct. Notification keeps
-- its dedicated bell-like asset id.
local SFX_PING = "rbxasset://sounds/electronicpingshort.wav"
-- volumes scaled +25% from previous tuning. Roblox Sound.Volume can exceed 1.0
-- (engine accepts up to 10) so pushing past 1 gives a real perceived loudness bump.
local SFX = {
    toggle_on  = {id = SFX_PING, vol = 1.06, pitch = 1.10},
    toggle_off = {id = SFX_PING, vol = 1.00, pitch = 0.85},
    click      = {id = SFX_PING, vol = 0.94, pitch = 1.45},
    hover      = {id = SFX_PING, vol = 0.40, pitch = 1.80},
    open       = {id = SFX_PING, vol = 1.25, pitch = 0.70},
    close      = {id = SFX_PING, vol = 1.13, pitch = 0.60},
    notify     = {id = 4590657391, vol = 1.06, pitch = 1.00},
    error      = {id = SFX_PING, vol = 1.25, pitch = 0.55},
    drag       = {id = SFX_PING, vol = 0.60, pitch = 1.30},
}
local function sfx(name)
    local s = SFX[name]
    if s then playSfx(s.id, s.vol, s.pitch) end
end

--// ────────────────────────────  library  ──────────────────────────── //--
local Lib = {}
Lib.__index = Lib

function Lib:MakeWindow(cfg)
    cfg = cfg or {}
    local W = setmetatable({Tabs = {}, Active = nil, Flags = {}, _hidden = false, _ready = false, _popupClosers = {}}, Lib)
    local sidebarW = 180
    local headerH = 60

    local gp = Root()
    pcall(function()
        local old = gp:FindFirstChild("EminanceUI")
        if old then old:Destroy() end
    end)

    local SG = inst("ScreenGui", {
        Name = "EminanceUI",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
        Parent = gp,
    })
    W._sg = SG

    local dim = inst("Frame", {
        Parent = SG,
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = -20,
    })
    W._dim = dim

    -- ─── outer container (carries shadow + accent glow + window) ─────────────
    local Container = inst("Frame", {
        Parent = SG,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(738, 442),
        BackgroundTransparency = 1,
        ZIndex = 1,
    })
    local CScale = inst("UIScale", {Parent = Container, Scale = 1})
    W._container = Container
    W._scale = CScale

    -- soft drop shadow (black)
    local shadow = inst("ImageLabel", {
        Parent = Container,
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 6),
        Size = UDim2.new(1, 70, 1, 70),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6015897753",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.38,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = 0,
    })

    -- accent glow halo (purple)
    local accentGlow = inst("ImageLabel", {
        Parent = Container,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 4),
        Size = UDim2.new(1, 70, 1, 70),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6015897753",
        ImageColor3 = T.Accent,
        ImageTransparency = 0.78,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = -1,
    })
    regImg(accentGlow, "Accent")
    -- gentle pulse of accent halo
    task.spawn(function()
        while IsAlive() and accentGlow and accentGlow.Parent do
            tw(accentGlow, 3, {ImageTransparency = 0.7}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            if not RuntimeWait(3) then break end
            if not IsAlive() or not accentGlow.Parent then break end
            tw(accentGlow, 3, {ImageTransparency = 0.85}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            if not RuntimeWait(3) then break end
        end
    end)

    -- main canvasgroup (so we can fade/scale the entire window as a single layer)
    local Win = inst("CanvasGroup", {
        Parent = Container,
        Name = "Window",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = T.Outer,
        BackgroundTransparency = 0.18,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        ZIndex = 2,
    })
    crn(Win, 2)
    -- stroke starts fully transparent so the hidden window doesn't leak its border
    -- through the loader / minimized state. We tween it together with GroupTransparency.
    local mainStroke = strk(Win, 1, T.Border, 1)
    regBg(Win, "Outer")
    regStroke(mainStroke, "Border")
    W._mainStroke = mainStroke
    -- subtle accent stroke gradient that slowly rotates
    local strokeGrad = Instance.new("UIGradient")
    strokeGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   T.Border),
        ColorSequenceKeypoint.new(0.5, T.Accent),
        ColorSequenceKeypoint.new(1,   T.Border),
    })
    strokeGrad.Rotation = 0
    strokeGrad.Parent = mainStroke
    regGrad(strokeGrad, {"Border", "Accent", "Border"})
    task.spawn(function()
        local r = 0
        while IsAlive() and strokeGrad and strokeGrad.Parent do
            r = (r + 1) % 360
            strokeGrad.Rotation = r
            if not RuntimeWait(0.05) then break end
        end
    end)

    -- glass overlay + faint particles inside Win (under content)
    applyGlassEffect(Win, 0.015)
    createParticles(Win, T.Accent, 2)
    createParticles(Win, T.Glow,  1)

    -- top accent strip (very faint, pulses)
    local topStrip = inst("Frame", {
        Parent = Win,
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = T.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 2,
    })
    crn(topStrip, 6)
    regBg(topStrip, "Accent")
    local stripGrad = Instance.new("UIGradient")
    stripGrad.Rotation = 90
    stripGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,   0.4),
        NumberSequenceKeypoint.new(0.6, 0.92),
        NumberSequenceKeypoint.new(1,   1),
    })
    stripGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, T.Accent),
        ColorSequenceKeypoint.new(1, T.Outer),
    })
    stripGrad.Parent = topStrip
    regGrad(stripGrad, {"Accent", "Outer"})
    task.spawn(function()
        while IsAlive() and topStrip and topStrip.Parent do
            tw(topStrip, 4, {BackgroundTransparency = 0.78}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            if not RuntimeWait(4) then break end
            if not IsAlive() or not topStrip.Parent then break end
            tw(topStrip, 4, {BackgroundTransparency = 0.92}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            if not RuntimeWait(4) then break end
        end
    end)

    -- ─── header bar ─────────────────────────────────────────────────
    local Hdr = inst("Frame", {
        Parent = Win,
        Size = UDim2.new(1, -sidebarW, 0, headerH),
        Position = UDim2.fromOffset(sidebarW, 0),
        BackgroundColor3 = T.Header,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 8,
    })
    crn(Hdr, 6)
    regBg(Hdr, "Header")
    inst("Frame", {Parent = Hdr, Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 1, -6), BackgroundColor3 = T.Header, BorderSizePixel = 0, ZIndex = 8})
    -- three tiny dots instead of any line: discrete decoration, doesn't cut the layout
    local hDots = inst("Frame", {
        Parent = Hdr, AnchorPoint = Vector2.new(0.5, 1),
        Size = UDim2.fromOffset(21, 3),
        Position = UDim2.new(0.5, 0, 1, -2),
        BackgroundTransparency = 1, ZIndex = 9,
    })
    for i = 0, 2 do
        local dot = inst("Frame", {
            Parent = hDots, AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromOffset(i * 9, 1),
            Size = UDim2.fromOffset(3, 3),
            BackgroundColor3 = T.Border, BackgroundTransparency = 0.3,
            BorderSizePixel = 0, ZIndex = 9,
        })
        crn(dot, 99)
        regBg(dot, "Border")
    end

    mkdrag(Hdr, Container)

    -- title group "Eminance | premium" (typewriter on first show)
    local titleHolder = inst("Frame", {
        Parent = Hdr,
        Size = UDim2.fromOffset(260, 38),
        Position = UDim2.fromOffset(14, 9),
        BackgroundTransparency = 1,
        ZIndex = 10,
    })
    inst("UIListLayout", {
        Parent = titleHolder,
        FillDirection = Enum.FillDirection.Vertical,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 0),
    })

    local function tlbl(text, color, order, weight, size)
        return inst("TextLabel", {
            Parent = titleHolder,
            Size = UDim2.new(1, 0, 0, 16),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Font = weight or F.Med,
            Text = text,
            TextColor3 = color,
            TextSize = size or 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = order,
            ZIndex = 11,
        })
    end
    local lblTitle = tlbl("", Color3.fromRGB(255, 255, 255), 1, F.Bold, 15)
    makeShimmer(lblTitle, "Accent", 0.5)
    local lblSep   = tlbl("", T.Dim, 2, F.Reg, 12)
    local lblSub   = tlbl("", T.Muted, 3, F.Reg, 10)
    lblSep.Visible = false
    W._headerTitle = lblTitle
    W._headerSub = lblSub
    local fullTitle = cfg.Title or "Eminance"
    local fullSub   = cfg.Subtitle or "premium"
    local function typewrite()
        if W.Active and W.Active._name then
            lblTitle.Text = tostring(W.Active._name)
            lblSub.Text = "Eminance / " .. tostring(W.Active._name)
            return
        end
        lblTitle.Text = ""; lblSep.Text = ""; lblSub.Text = ""
        for i = 1, #fullTitle do
            if not RuntimeWait(0.025) then return end
            lblTitle.Text = fullTitle:sub(1, i)
        end
        lblSep.Text = ""
        if not RuntimeWait(0.05) then return end
        for i = 1, #fullSub do
            if not RuntimeWait(0.03) then return end
            lblSub.Text = fullSub:sub(1, i)
        end
    end

    local searchWrap = inst("Frame", {
        Parent = Hdr,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -66, 0.5, 0),
        Size = UDim2.fromOffset(180, 24),
        BackgroundColor3 = T.Panel,
        BorderSizePixel = 0,
        ZIndex = 11,
    })
    crn(searchWrap, 5)
    strk(searchWrap, 1, T.Border, 0)
    local searchIcon = inst("ImageLabel", {
        Parent = searchWrap,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 8, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        BackgroundTransparency = 1,
        Image = "rbxassetid://3926305904",
        ImageRectOffset = Vector2.new(964, 324),
        ImageRectSize = Vector2.new(36, 36),
        ImageColor3 = T.Muted,
        ZIndex = 12,
    })
    local searchBox = inst("TextBox", {
        Parent = searchWrap,
        Position = UDim2.fromOffset(26, 0),
        Size = UDim2.new(1, -32, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = F.Reg,
        PlaceholderText = "Search tabs/groups...",
        PlaceholderColor3 = T.Muted,
        Text = "",
        TextColor3 = T.TextSoft,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 12,
    })
    regBg(searchWrap, "Panel")
    regImg(searchIcon, "Muted")
    regText(searchBox, "TextSoft")
    W._searchBox = searchBox
    -- live filter: hide section cards whose title OR any inner widget label
    -- does not match the query. This allows typing function names or any
    -- internal control text (e.g. "fly speed", "fail delay", "bay island").
    local function applySectionFilter()
        if not W.Active or not W.Active._page then return end
        local q = string.lower(tostring(searchBox.Text or ""))
        for _, c in ipairs(W.Active._page:GetDescendants()) do
            if c:IsA("Frame") and c.Name == "_secCard" then
                local visible = true
                if q ~= "" then
                    visible = false
                    for _, d in ipairs(c:GetDescendants()) do
                        if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                            local s = string.lower(tostring(d.Text or ""))
                            if s ~= "" and string.find(s, q, 1, true) then
                                visible = true
                                break
                            end
                        end
                    end
                end
                c.Visible = visible
            end
        end
    end
    W._applySearchFilter = applySectionFilter
    TrackConnection(searchBox:GetPropertyChangedSignal("Text"):Connect(applySectionFilter))

    -- minimize button (−)
    local minBtn = inst("TextButton", {
        Parent = Hdr,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -34, 0.5, 0),
        Size = UDim2.fromOffset(22, 20),
        BackgroundTransparency = 1,
        Font = F.Bold,
        Text = "−",
        TextSize = 14,
        TextColor3 = T.Muted,
        AutoButtonColor = false,
        ZIndex = 11,
    })
    minBtn.MouseEnter:Connect(function() tw(minBtn, 0.15, {TextColor3 = T.AccentHi}) end)
    minBtn.MouseLeave:Connect(function() tw(minBtn, 0.15, {TextColor3 = T.Muted}) end)
    minBtn.MouseButton1Click:Connect(function() ripple(minBtn, T.Accent); W:_Hide() end)

    -- close button (×)
    local closeBtn = inst("TextButton", {
        Parent = Hdr,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(22, 20),
        BackgroundTransparency = 1,
        Font = F.Bold,
        Text = "×",
        TextSize = 16,
        TextColor3 = T.Muted,
        AutoButtonColor = false,
        ZIndex = 11,
    })
    closeBtn.MouseEnter:Connect(function() tw(closeBtn, 0.15, {TextColor3 = T.Red}) end)
    closeBtn.MouseLeave:Connect(function() tw(closeBtn, 0.15, {TextColor3 = T.Muted}) end)
    closeBtn.MouseButton1Click:Connect(function()
        if not IsAlive() then return end
        ripple(closeBtn, T.Red)
        ShutdownRuntime()
        tw(dim, 0.25, {BackgroundTransparency = 1}, Enum.EasingStyle.Quint)
        tw(CScale, 0.25, {Scale = 0.9}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        tw(Win, 0.3, {GroupTransparency = 1}, Enum.EasingStyle.Quint)
        tw(mainStroke, 0.3, {Transparency = 1})
        tw(shadow, 0.25, {ImageTransparency = 1})
        tw(accentGlow, 0.25, {ImageTransparency = 1})
        task.delay(0.35, function() if SG then SG:Destroy() end end)
    end)

    -- ─── tab strip ─────────────────────────────────────────────────
    local TabBar = inst("Frame", {
        Parent = Win,
        Size = UDim2.new(0, sidebarW, 1, 0),
        Position = UDim2.fromOffset(0, 0),
        BackgroundColor3 = T.Panel,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        ZIndex = 8,
    })
    regBg(TabBar, "Panel")
    inst("Frame", {Parent = TabBar, Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BackgroundColor3 = T.Border, BorderSizePixel = 0, ZIndex = 9})
    local logoPlate = inst("Frame", {
        Parent = TabBar,
        Size = UDim2.new(1, -18, 0, 55),
        Position = UDim2.fromOffset(9, 8),
        BackgroundColor3 = T.Outer,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        ZIndex = 9,
    })
    crn(logoPlate, 3)
    regBg(logoPlate, "Outer")
    -- soft radial purple glow underlay for the logo letter
    local logoGlow = inst("ImageLabel", {
        Parent = logoPlate,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 33, 0.5, 0),
        Size = UDim2.fromOffset(78, 70),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6015897753",
        ImageColor3 = T.Accent,
        ImageTransparency = 0.55,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = 9,
    })
    regImg(logoGlow, "Accent")
    task.spawn(function()
        while IsAlive() and logoGlow and logoGlow.Parent do
            tw(logoGlow, 1.6, {ImageTransparency = 0.42}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            if not RuntimeWait(1.6) then break end
            if not IsAlive() or not logoGlow.Parent then break end
            tw(logoGlow, 1.6, {ImageTransparency = 0.62}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            if not RuntimeWait(1.6) then break end
        end
    end)
    -- decorative spray strokes behind the E (graffiti effect, behind the letter)
    local _logoSprays = {}
    local function mkSpray(x, y, w, rot, transp)
        local sp = inst("Frame", {
            Parent = logoPlate,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromOffset(x, y),
            Size = UDim2.fromOffset(w, 2),
            BackgroundColor3 = T.AccentHi,
            BackgroundTransparency = transp,
            Rotation = rot,
            BorderSizePixel = 0,
            ZIndex = 9,
        })
        crn(sp, 1)
        regBg(sp, "AccentHi")
        table.insert(_logoSprays, {obj = sp, base = transp, phase = #_logoSprays * 0.7})
    end
    mkSpray(20, 22, 24,  30, 0.55)
    mkSpray(48, 28, 22, -25, 0.62)
    mkSpray(28, 42, 18,  35, 0.65)
    mkSpray(46, 18, 14, -50, 0.7)
    mkSpray(38, 34, 30,   0, 0.78)

    local logoMark = inst("TextLabel", {
        Parent = logoPlate,
        Size = UDim2.fromOffset(48, 47),
        Position = UDim2.fromOffset(9, 4),
        BackgroundTransparency = 1,
        Font = F.Bold,
        Text = "E",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 44,
        Rotation = -15,
        ZIndex = 10,
    })

    -- decorative crown above the E (rotated to match E's -15°)
    local crown = inst("Frame", {
        Parent = logoPlate,
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.fromOffset(28, 8),
        Size = UDim2.fromOffset(22, 8),
        BackgroundTransparency = 1,
        Rotation = -15,
        ZIndex = 11,
    })
    local crownBase = inst("Frame", {
        Parent = crown,
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = T.Accent,
        BorderSizePixel = 0,
        ZIndex = 11,
    })
    crn(crownBase, 99)
    regBg(crownBase, "Accent")
    local _logoJewels = {}
    local function mkPeak(xs, h)
        local p = inst("Frame", {
            Parent = crown,
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(xs, 0, 1, -2),
            Size = UDim2.fromOffset(2, h),
            BackgroundColor3 = T.Accent,
            BorderSizePixel = 0,
            ZIndex = 11,
        })
        crn(p, 99)
        regBg(p, "Accent")
        local jewel = inst("Frame", {
            Parent = crown,
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(xs, 0, 1, -2 - h),
            Size = UDim2.fromOffset(3, 3),
            Rotation = 45,
            BackgroundColor3 = T.AccentHi,
            BorderSizePixel = 0,
            ZIndex = 12,
        })
        regBg(jewel, "AccentHi")
        table.insert(_logoJewels, {obj = jewel, phase = #_logoJewels * 0.9})
    end
    mkPeak(0.18, 4)
    mkPeak(0.5,  6)
    mkPeak(0.82, 4)

    -- continuous decoration animation: E wobble, graffiti breath, jewel rotation
    do
        local startT = tick()
        local conn
        conn = RS.Heartbeat:Connect(function()
            if not logoMark or not logoMark.Parent then
                if conn then conn:Disconnect() end
                return
            end
            local t = tick() - startT
            -- E wobble: rotation oscillates ±2° around -15° baseline
            logoMark.Rotation = -15 + math.sin(t * 1.3) * 2
            -- crown wobbles in unison with the E for a coordinated tilt
            if crown and crown.Parent then
                crown.Rotation = -15 + math.sin(t * 1.3) * 2
            end
            -- graffiti spray strokes breathe transparency (offset phases)
            for _, s in ipairs(_logoSprays) do
                if s.obj and s.obj.Parent then
                    s.obj.BackgroundTransparency = math.clamp(s.base + math.sin(t * 1.6 + s.phase) * 0.12, 0, 1)
                end
            end
            -- jewels rotate continuously and pulse size 3..4
            for _, j in ipairs(_logoJewels) do
                if j.obj and j.obj.Parent then
                    j.obj.Rotation = (j.obj.Rotation + 0.6) % 360
                    local sz = 3 + (math.sin(t * 2.2 + j.phase) + 1) * 0.5  -- 3..4
                    j.obj.Size = UDim2.fromOffset(sz, sz)
                end
            end
        end)
    end
    inst("UIGradient", {
        Parent = logoMark,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,    T.AccentHi),
            ColorSequenceKeypoint.new(0.55, T.Accent),
            ColorSequenceKeypoint.new(1,    Color3.fromRGB(245, 235, 255)),
        }),
        Rotation = 90,
    })
    local logoTitle = inst("TextLabel", {
        Parent = logoPlate,
        Size = UDim2.fromOffset(100, 16),
        Position = UDim2.fromOffset(50, 19),
        BackgroundTransparency = 1,
        Font = F.Bold,
        Text = "\u{2014} " .. (cfg.Title or "Eminance") .. " \u{2014}",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 10,
    })
    regText(logoMark, "Accent")
    makeShimmer(logoTitle, "Accent", 0.45)

    local TabHolder = inst("Frame", {
        Parent = TabBar,
        Size = UDim2.new(1, -18, 1, -116),
        Position = UDim2.fromOffset(9, 76),
        BackgroundTransparency = 1,
        ZIndex = 9,
    })
    inst("UIListLayout", {
        Parent = TabHolder,
        FillDirection = Enum.FillDirection.Vertical,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
    })
    -- thin separator above the UI Settings button
    inst("Frame", {
        Parent = TabBar,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 14, 1, -42),
        Size = UDim2.new(1, -28, 0, 1),
        BackgroundColor3 = T.Border,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        ZIndex = 9,
    })
    -- UI Settings button (matches tab-button style)
    local uiSettings = inst("TextButton", {
        Parent = TabBar,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 9, 1, -9),
        Size = UDim2.new(1, -18, 0, 28),
        BackgroundColor3 = T.Slot,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Font = F.Med,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 10,
    })
    crn(uiSettings, 6)
    pad(uiSettings, 0, 10, 0, 10)
    regBg(uiSettings, "Slot")
    -- sprite-based gear icon (Material Icons settings)
    local uiSetDot = inst("ImageLabel", {
        Parent = uiSettings,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        BackgroundTransparency = 1,
        Image = "rbxassetid://3926305904",
        ImageRectOffset = Vector2.new(324, 124),
        ImageRectSize = Vector2.new(36, 36),
        ImageColor3 = T.Muted,
        ZIndex = 11,
    })
    regImg(uiSetDot, "Muted")
    local uiSetTxt = inst("TextLabel", {
        Parent = uiSettings,
        Position = UDim2.fromOffset(20, 0),
        Size = UDim2.new(1, -20, 1, 0),
        BackgroundTransparency = 1,
        Font = F.Med,
        Text = "UI Settings",
        TextColor3 = T.Muted,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 11,
    })
    regText(uiSetTxt, "Muted")
    uiSettings.MouseEnter:Connect(function()
        tw(uiSettings, 0.15, {BackgroundTransparency = 0.72})
        tw(uiSetTxt, 0.15, {TextColor3 = T.TextSoft})
    end)
    uiSettings.MouseLeave:Connect(function()
        tw(uiSettings, 0.15, {BackgroundTransparency = 1})
        tw(uiSetTxt, 0.15, {TextColor3 = T.Muted})
    end)
    W._uiSettingsBtn = uiSettings
    W._uiSettingsTxt = uiSetTxt
    W._uiSettingsDot = uiSetDot

    -- ─── pages container ─────────────────────────────────────────────
    local Pages = inst("Frame", {
        Parent = Win,
        Size = UDim2.new(1, -sidebarW, 1, -headerH),
        Position = UDim2.fromOffset(sidebarW, headerH),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 6,
    })

    W._tabHolder = TabHolder
    W._pages = Pages
    W._win = Win
    W._shadow = shadow
    W._accentGlow = accentGlow

    -- ─── notification stack (bottom-right) ────────────────────────────
    local nc = inst("Frame", {
        Parent = SG,
        Size = UDim2.fromOffset(320, 320),
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -16, 1, -16),
        BackgroundTransparency = 1,
        ZIndex = 200,
    })
    inst("UIListLayout", {
        Parent = nc,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
    })
    W._nc = nc

    -- ─── "Open UI" watermark (visible while minimized) ───────────────
    local wm = inst("Frame", {
        Parent = SG,
        Name = "WM",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0, 28),
        Size = UDim2.fromOffset(220, 34),
        BackgroundColor3 = T.Header,
        BackgroundTransparency = 0.02,
        Visible = false,
        ZIndex = 150,
    })
    crn(wm, 8)
    regBg(wm, "Header")
    local wmStroke = strk(wm, 1, T.Border, 0)
    regStroke(wmStroke, "Border")
    local wmScale = inst("UIScale", {Parent = wm, Scale = 0})

    -- ── left zone: drag handle (only this area initiates drag) ──
    local wmDrag = inst("Frame", {
        Parent = wm, AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(24, 34),
        BackgroundTransparency = 1, ZIndex = 151,
    })
    -- 6 dots arranged 2×3 (Material drag_indicator silhouette)
    for _, p in ipairs({
        {0.35, 0.30}, {0.65, 0.30},
        {0.35, 0.50}, {0.65, 0.50},
        {0.35, 0.70}, {0.65, 0.70},
    }) do
        local d = inst("Frame", {
            Parent = wmDrag, AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(p[1], p[2]),
            Size = UDim2.fromOffset(2, 2),
            BackgroundColor3 = T.Muted, BorderSizePixel = 0, ZIndex = 152,
        })
        crn(d, 99)
        regBg(d, "Muted")
    end
    -- thin vertical separator after the handle
    local wmSep1 = inst("Frame", {
        Parent = wm, Position = UDim2.fromOffset(24, 6),
        Size = UDim2.fromOffset(1, 22),
        BackgroundColor3 = T.Border, BorderSizePixel = 0, ZIndex = 151,
    })
    regBg(wmSep1, "Border")

    -- ── center zone: clickable OPEN UI text ──
    local wmBtn = inst("TextButton", {
        Parent = wm, AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromOffset(28, 17),
        Size = UDim2.fromOffset(140, 34),
        BackgroundTransparency = 1,
        Font = F.Bold, Text = "OPEN UI",
        TextColor3 = T.Text, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        AutoButtonColor = false, ZIndex = 152,
    })
    regText(wmBtn, "Text")
    -- second separator before the right decoration zone
    local wmSep2 = inst("Frame", {
        Parent = wm, Position = UDim2.fromOffset(168, 6),
        Size = UDim2.fromOffset(1, 22),
        BackgroundColor3 = T.Border, BorderSizePixel = 0, ZIndex = 151,
    })
    regBg(wmSep2, "Border")

    -- ── right zone: mini E with crown and graffiti spray (matches main logo) ──
    local wmDeco = inst("Frame", {
        Parent = wm, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -2, 0.5, 0),
        Size = UDim2.fromOffset(48, 34),
        BackgroundTransparency = 1, ZIndex = 151,
    })
    -- graffiti spray strokes behind the mini E
    local function mkWmSpray(x, y, w, rot, transp)
        local sp = inst("Frame", {
            Parent = wmDeco, AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromOffset(x, y),
            Size = UDim2.fromOffset(w, 1.5),
            BackgroundColor3 = T.AccentHi, BackgroundTransparency = transp,
            Rotation = rot, BorderSizePixel = 0, ZIndex = 152,
        })
        crn(sp, 1)
        regBg(sp, "AccentHi")
    end
    mkWmSpray(20, 14, 18,  25, 0.55)
    mkWmSpray(28, 22, 14, -30, 0.62)
    mkWmSpray(22, 26, 12,  35, 0.7)
    mkWmSpray(18, 8,  8,  -45, 0.7)
    -- mini E
    local wmE = inst("TextLabel", {
        Parent = wmDeco, AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(24, 19),
        Size = UDim2.fromOffset(28, 28),
        BackgroundTransparency = 1,
        Font = F.Bold, Text = "E",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 22, Rotation = -15,
        ZIndex = 153,
    })
    inst("UIGradient", {
        Parent = wmE,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,    T.AccentHi),
            ColorSequenceKeypoint.new(0.55, T.Accent),
            ColorSequenceKeypoint.new(1,    Color3.fromRGB(245, 235, 255)),
        }),
        Rotation = 90,
    })
    -- mini crown above the E
    local wmCrown = inst("Frame", {
        Parent = wmDeco, AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.fromOffset(20, 7),
        Size = UDim2.fromOffset(14, 5),
        BackgroundTransparency = 1, Rotation = -15, ZIndex = 154,
    })
    local wmCrownBase = inst("Frame", {
        Parent = wmCrown, AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 1.2),
        BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 154,
    })
    crn(wmCrownBase, 99); regBg(wmCrownBase, "Accent")
    local function wmPeak(xs, h)
        local p = inst("Frame", {
            Parent = wmCrown, AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(xs, 0, 1, -1.2),
            Size = UDim2.fromOffset(1.5, h),
            BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 154,
        })
        crn(p, 99); regBg(p, "Accent")
    end
    wmPeak(0.18, 2.5)
    wmPeak(0.5,  4)
    wmPeak(0.82, 2.5)

    local function toggleFromInput()
        if not W._ready then return end
        if W._hidden then W:_Show() else W:_Hide() end
    end

    wmBtn.MouseEnter:Connect(function()
        tw(wmBtn, 0.15, {TextColor3 = T.Accent})
        tw(wmStroke, 0.15, {Color = T.Accent, Thickness = 1.2})
        tw(wmScale, 0.15, {Scale = 1.05}, Enum.EasingStyle.Back)
    end)
    wmBtn.MouseLeave:Connect(function()
        tw(wmBtn, 0.15, {TextColor3 = T.Text})
        tw(wmStroke, 0.15, {Color = T.Border, Thickness = 1})
        if W._hidden then tw(wmScale, 0.15, {Scale = 1}, Enum.EasingStyle.Back) end
    end)
    wmBtn.MouseButton1Click:Connect(toggleFromInput)
    -- drag is bound ONLY to the left handle — clicking the rest of the button doesn't move it
    mkdrag(wmDrag, wm)
    W._wm = wm; W._wmScale = wmScale

    -- ─── loader screen (initial show) ─────────────────────────────────
    local skipLoader = cfg.SkipLoader == true
    local loader
    if not skipLoader then
        -- Matte dark palette hardcoded for the loader (theme-independent: must
        -- look stoic and saturated even when the user's theme is Light).
        local LD_BG     = Color3.fromRGB(14, 14, 18)
        local LD_PANEL  = Color3.fromRGB(20, 20, 26)
        local LD_BORDER = Color3.fromRGB(40, 40, 48)
        local LD_TEXT   = Color3.fromRGB(228, 228, 234)
        local LD_SOFT   = Color3.fromRGB(168, 168, 178)
        local LD_MUTED  = Color3.fromRGB(108, 108, 120)
        local LD_BLADE  = Color3.fromRGB(245, 245, 250)
        local LD_ACCENT = Color3.fromRGB(155, 110, 245)

        loader = inst("CanvasGroup", {
            Parent = SG,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(440, 170),
            BackgroundColor3 = LD_BG,
            BackgroundTransparency = 0.02,
            BorderSizePixel = 0,
            GroupTransparency = 0,
            ZIndex = 250,
        })
        crn(loader, 10)
        local loaderStroke = strk(loader, 1, LD_BORDER, 0)

        -- subtle inner panel highlight (top edge, very faint)
        local lTop = inst("Frame", {
            Parent = loader, Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = LD_BORDER, BackgroundTransparency = 0.2,
            BorderSizePixel = 0, ZIndex = 251,
        })

        -- Single E that "dissolves" into particles when sliced. No clipping —
        -- previous half-clip approach produced two visible Es because rotated
        -- TextLabels with different pivots inside rotated parent clips don't
        -- compose cleanly. Instead: katana hits → bright slash flashes →
        -- E fades+scales → 10 accent particles burst radially outward.
        local eAnchor = inst("Frame", {
            Parent = loader, AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromOffset(36, 85),
            Size = UDim2.fromOffset(72, 72),
            BackgroundTransparency = 1, ZIndex = 251,
        })
        local eGradSeq = ColorSequence.new({
            ColorSequenceKeypoint.new(0,    LD_ACCENT),
            ColorSequenceKeypoint.new(0.55, Color3.fromRGB(170, 120, 250)),
            ColorSequenceKeypoint.new(1,    Color3.fromRGB(255, 245, 255)),
        })
        local eMain = inst("TextLabel", {
            Parent = eAnchor, Size = UDim2.fromOffset(72, 72),
            BackgroundTransparency = 1, Font = F.Bold, Text = "E",
            TextColor3 = LD_BLADE, TextSize = 64,
            Rotation = -15, TextTransparency = 1, ZIndex = 253,
        })
        inst("UIGradient", {Parent = eMain, Color = eGradSeq, Rotation = 90})
        -- UIScale on E for the dissolve (shrink to 0.6 while fading)
        local eScale = inst("UIScale", {Parent = eMain, Scale = 1})

        -- katana blade: thin white vertical line above the E with a darker pommel cap
        local katana = inst("Frame", {
            Parent = loader,
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.fromOffset(72, -90),
            Size = UDim2.fromOffset(2, 90),
            BackgroundColor3 = LD_BLADE,
            BackgroundTransparency = 0,
            BorderSizePixel = 0, ZIndex = 254,
        })
        local katanaGuard = inst("Frame", {
            Parent = katana, AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 0, -1),
            Size = UDim2.fromOffset(14, 3),
            BackgroundColor3 = LD_BORDER, BorderSizePixel = 0, ZIndex = 254,
        })
        crn(katanaGuard, 1)
        local katanaHandle = inst("Frame", {
            Parent = katana, AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 0, -4),
            Size = UDim2.fromOffset(4, 16),
            BackgroundColor3 = Color3.fromRGB(70, 60, 50),
            BorderSizePixel = 0, ZIndex = 254,
        })
        crn(katanaHandle, 1)
        -- thin slash trail behind the blade
        local katanaTrail = inst("Frame", {
            Parent = katana, AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromOffset(1, 90),
            BackgroundColor3 = LD_ACCENT, BackgroundTransparency = 0.6,
            BorderSizePixel = 0, ZIndex = 253,
        })

        local lTitle = inst("TextLabel", {
            Parent = loader, AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.fromOffset(120, 44),
            Size = UDim2.fromOffset(280, 22),
            BackgroundTransparency = 1,
            Font = F.Bold, Text = "Eminance",
            TextColor3 = LD_TEXT, TextSize = 18,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTransparency = 1, ZIndex = 251,
        })
        local lSub = inst("TextLabel", {
            Parent = loader, AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.fromOffset(120, 68),
            Size = UDim2.fromOffset(280, 14),
            BackgroundTransparency = 1,
            Font = F.Reg, Text = "premium · stoic interface",
            TextColor3 = LD_MUTED, TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTransparency = 1, ZIndex = 251,
        })
        local lStat = inst("TextLabel", {
            Parent = loader, AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.fromOffset(120, 96),
            Size = UDim2.fromOffset(280, 12),
            BackgroundTransparency = 1,
            Font = F.Med, Text = "initializing...",
            TextColor3 = LD_SOFT, TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTransparency = 1, ZIndex = 251,
        })
        local lBgPB = inst("Frame", {
            Parent = loader, AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.fromOffset(120, 120),
            Size = UDim2.fromOffset(284, 2),
            BackgroundColor3 = LD_BORDER,
            BorderSizePixel = 0, BackgroundTransparency = 0.4,
            ZIndex = 251,
        })
        crn(lBgPB, 1)
        local lFill = inst("Frame", {
            Parent = lBgPB, Size = UDim2.fromScale(0, 1),
            BackgroundColor3 = LD_ACCENT, BorderSizePixel = 0, ZIndex = 252,
        })
        crn(lFill, 1)

        -- entrance fade-in of text + E
        task.spawn(function()
            tw(eMain, 0.5, {TextTransparency = 0}, Enum.EasingStyle.Sine)
            task.wait(0.1)
            tw(lTitle, 0.4, {TextTransparency = 0}, Enum.EasingStyle.Sine)
            task.wait(0.06)
            tw(lSub, 0.4, {TextTransparency = 0.05}, Enum.EasingStyle.Sine)
            task.wait(0.06)
            tw(lStat, 0.3, {TextTransparency = 0}, Enum.EasingStyle.Sine)
        end)

        -- main loader sequence: katana descends, slices the E, then UI reveals
        task.spawn(function()
            task.wait(0.4) -- let entrance settle
            -- katana descent (from above the loader, down to below the E)
            local katanaDur = 1.0
            local sliceTriggered = false
            local s2 = tick(); local conn
            local msgs = {"steeling the blade...", "drawing katana...", "executing cut...", "ready"}
            conn = RS.RenderStepped:Connect(function()
                local el = tick() - s2
                local pct = math.clamp(el / katanaDur, 0, 1)
                -- katana position interpolates from y=-50 (above) to y=180 (well below E)
                katana.Position = UDim2.fromOffset(72, -50 + pct * 230)
                lStat.Text = msgs[math.clamp(math.floor(pct * #msgs) + 1, 1, #msgs)]
                lFill.Size = UDim2.fromScale(pct, 1)
                -- trigger slice when blade tip crosses the E's vertical center (~ y=85)
                if not sliceTriggered and katana.Position.Y.Offset > 60 then
                    sliceTriggered = true
                    sfx("close")

                    -- 1) horizontal slash flash across the E (bright white, fast scale + fade)
                    local slash = inst("Frame", {
                        Parent = eAnchor, AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.fromOffset(36, 36),
                        Size = UDim2.fromOffset(0, 2),
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        BorderSizePixel = 0, ZIndex = 256,
                    })
                    crn(slash, 1)
                    inst("UIGradient", {
                        Parent = slash,
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0,   1),
                            NumberSequenceKeypoint.new(0.2, 0),
                            NumberSequenceKeypoint.new(0.8, 0),
                            NumberSequenceKeypoint.new(1,   1),
                        }),
                    })
                    tw(slash, 0.18, {Size = UDim2.fromOffset(120, 2)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                    task.delay(0.18, function()
                        if slash and slash.Parent then
                            tw(slash, 0.2, {BackgroundTransparency = 1}, Enum.EasingStyle.Sine)
                            task.delay(0.22, function() if slash then slash:Destroy() end end)
                        end
                    end)

                    -- 2) E dissolve: shrink + fade + slight drift
                    tw(eScale, 0.5, {Scale = 0.55}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                    tw(eMain, 0.5, {TextTransparency = 1, Rotation = -22}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

                    -- 3) particle burst: 10 small accent fragments fly outward radially
                    for pi = 0, 9 do
                        local angle = (pi / 10) * math.pi * 2 + (math.random() - 0.5) * 0.4
                        local dist = 28 + math.random() * 22
                        local size = 2 + math.random(0, 2)
                        local part = inst("Frame", {
                            Parent = eAnchor, AnchorPoint = Vector2.new(0.5, 0.5),
                            Position = UDim2.fromOffset(36, 36),
                            Size = UDim2.fromOffset(size, size),
                            BackgroundColor3 = (pi % 3 == 0) and Color3.fromRGB(255, 245, 255) or LD_ACCENT,
                            Rotation = math.random(0, 360),
                            BorderSizePixel = 0, ZIndex = 255,
                        })
                        crn(part, 1)
                        local ex = 36 + math.cos(angle) * dist
                        local ey = 36 + math.sin(angle) * dist
                        local rotEnd = part.Rotation + math.random(-180, 180)
                        tw(part, 0.6 + math.random() * 0.2, {
                            Position = UDim2.fromOffset(ex, ey),
                            Size = UDim2.fromOffset(0, 0),
                            Rotation = rotEnd,
                            BackgroundTransparency = 1,
                        }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                        task.delay(0.85, function() if part then part:Destroy() end end)
                    end
                end
                if el >= katanaDur then
                    conn:Disconnect()
                    lStat.Text = "ready"
                    lStat.TextColor3 = LD_ACCENT
                    -- fade katana out
                    tw(katana, 0.3, {BackgroundTransparency = 1}, Enum.EasingStyle.Sine)
                    tw(katanaGuard, 0.3, {BackgroundTransparency = 1}, Enum.EasingStyle.Sine)
                    tw(katanaHandle, 0.3, {BackgroundTransparency = 1}, Enum.EasingStyle.Sine)
                    tw(katanaTrail, 0.3, {BackgroundTransparency = 1}, Enum.EasingStyle.Sine)
                    task.wait(0.15)
                    tw(loader, 0.4, {GroupTransparency = 1})
                    tw(loaderStroke, 0.4, {Transparency = 1})
                    task.delay(0.45, function() if loader then loader:Destroy() end end)
                    task.delay(0.1, function()
                        -- reveal the window
                        CScale.Scale = 0.85
                        Win.GroupTransparency = 1
                        mainStroke.Transparency = 1
                        shadow.ImageTransparency = 1
                        accentGlow.ImageTransparency = 1
                        Container.Position = UDim2.new(0.5, 0, 0.55, 0)
                        tw(Container, 0.55, {Position = UDim2.fromScale(0.5, 0.5)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                        tw(CScale, 0.6, {Scale = 1}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                        tw(Win, 0.45, {GroupTransparency = 0}, Enum.EasingStyle.Quint)
                        tw(dim, 0.45, {BackgroundTransparency = 0.32}, Enum.EasingStyle.Quint)
                        tw(mainStroke, 0.45, {Transparency = 0})
                        tw(shadow, 0.5, {ImageTransparency = 0.25})
                        tw(accentGlow, 0.5, {ImageTransparency = 0.78})
                        task.spawn(typewrite)
                        W._ready = true
                    end)
                end
            end)
        end)
    else
        -- direct entrance
        CScale.Scale = 0.85
        Win.GroupTransparency = 1
        mainStroke.Transparency = 1
        shadow.ImageTransparency = 1
        accentGlow.ImageTransparency = 1
        tw(CScale, 0.5, {Scale = 1}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        tw(Win, 0.4, {GroupTransparency = 0}, Enum.EasingStyle.Quint)
        tw(dim, 0.4, {BackgroundTransparency = 0.32}, Enum.EasingStyle.Quint)
        tw(mainStroke, 0.4, {Transparency = 0})
        tw(shadow, 0.5, {ImageTransparency = 0.25})
        tw(accentGlow, 0.5, {ImageTransparency = 0.78})
        task.spawn(typewrite)
        W._ready = true
    end

    -- ─── toggle visibility (default RightShift) ───────────────────────
    local toggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift
    TrackConnection(UIS.InputBegan:Connect(function(input, gp2)
        if gp2 or not IsAlive() then return end
        if input.KeyCode == toggleKey then toggleFromInput() end
    end))

    return W
end

--// ────────────────────────────  hide / show / toggle  ──────────────────────────── //--
-- closes any floating dropdown/picker popups parented to the ScreenGui
local function closeFloatingPopups(sg)
    if not sg then return end
    for _, c in ipairs(sg:GetChildren()) do
        if c:IsA("Frame") and (c.Name == "_ddPopup" or c.Name == "_picker") then
            c.Visible = false
            c.Size = UDim2.fromOffset(c.Size.X.Offset, 0)
        end
    end
end

function Lib:_Hide()
    if self._hidden or not IsAlive() then return end
    self._hidden = true
    sfx("close")
    -- close every dropdown / picker so internal `open` flags reset to match the visual state
    for _, fn in ipairs(self._popupClosers) do pcall(fn) end
    closeFloatingPopups(self._sg)
    pcall(function() self._container.Interactable = false end)
    self._wm.Visible = true
    self._wmScale.Scale = 0
    tw(self._wmScale, 0.3, {Scale = 1}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    tw(self._scale, 0.32, {Scale = 0.92}, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    tw(self._win, 0.28, {GroupTransparency = 1}, Enum.EasingStyle.Quint)
    if self._dim then tw(self._dim, 0.28, {BackgroundTransparency = 1}, Enum.EasingStyle.Quint) end
    if self._mainStroke then tw(self._mainStroke, 0.28, {Transparency = 1}) end
    tw(self._shadow, 0.28, {ImageTransparency = 1})
    tw(self._accentGlow, 0.28, {ImageTransparency = 1})
    task.delay(0.3, function()
        if self._hidden and self._container then
            self._container.Visible = false
        end
    end)
end

function Lib:_Show()
    if not self._hidden or not IsAlive() then return end
    self._hidden = false
    sfx("open")
    if self._container then self._container.Visible = true end
    pcall(function() self._container.Interactable = true end)
    tw(self._wmScale, 0.22, {Scale = 0}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    task.delay(0.24, function() if self._hidden == false then self._wm.Visible = false end end)
    self._scale.Scale = 0.85
    self._win.GroupTransparency = 1
    if self._mainStroke then self._mainStroke.Transparency = 1 end
    self._shadow.ImageTransparency = 1
    self._accentGlow.ImageTransparency = 1
    tw(self._scale, 0.42, {Scale = 1}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    tw(self._win, 0.4, {GroupTransparency = 0}, Enum.EasingStyle.Quint)
    if self._dim then tw(self._dim, 0.4, {BackgroundTransparency = 0.32}, Enum.EasingStyle.Quint) end
    if self._mainStroke then tw(self._mainStroke, 0.4, {Transparency = 0}) end
    tw(self._shadow, 0.4, {ImageTransparency = 0.25})
    tw(self._accentGlow, 0.4, {ImageTransparency = 0.78})
end

function Lib:_Toggle()
    if not IsAlive() then return end
    if self._hidden then self:_Show() else self:_Hide() end
end

--// ────────────────────────────  notifications  ──────────────────────────── //--
function Lib:Notify(title, msg, kind, dur)
    if not IsAlive() then return end
    kind = kind or "info"; dur = dur or 3.5
    title = tostring(title or ""); msg = tostring(msg or "")
    local cmap = {
        success = T.Accent,
        error   = Color3.fromRGB(190, 70, 90),
        warning = Color3.fromRGB(210, 165, 60),
        info    = T.Accent,
    }
    local icons = {success = "✓", error = "×", warning = "!", info = "i"}
    local col = cmap[kind] or T.Accent
    local icon = icons[kind] or "i"
    if kind == "error" or kind == "warning" then sfx("error") else sfx("notify") end

    local nW = math.clamp(math.max(#title * 8 + 96, #msg * 7 + 96), 280, 360)
    -- shell wraps everything in a CanvasGroup so exit can fade all layers in one go
    -- (no leftover progress-bar trace lingering after the body has gone)
    local shell = inst("CanvasGroup", {
        Parent = self._nc,
        Size = UDim2.new(0, nW, 0, 0),
        BackgroundTransparency = 1,
        GroupTransparency = 0,
        ClipsDescendants = false,
        ZIndex = 200,
    })
    local n = inst("Frame", {
        Parent = shell,
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = T.Panel,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 201,
    })
    crn(n, 8)
    regBg(n, "Panel")
    local ns = strk(n, 1, T.Border, 0)
    regStroke(ns, "Border")

    -- right-side circular icon badge: the only color indicator (replaces the
    -- old left strip and the colored left-edge accent the user disliked)
    local circle = inst("Frame", {
        Parent = n, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(28, 28),
        BackgroundColor3 = T.Slot, BackgroundTransparency = 0.2,
        BorderSizePixel = 0, ZIndex = 205,
    })
    crn(circle, 99)
    regBg(circle, "Slot")
    local circleStroke = strk(circle, 1.5, col, 0)
    local circleIcon = inst("TextLabel", {
        Parent = circle, Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1, Font = F.Bold,
        Text = icon, TextColor3 = col, TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 206,
    })

    local titleLbl = inst("TextLabel", {
        Parent = n,
        Size = UDim2.new(1, -64, 0, 14),
        Position = UDim2.fromOffset(14, 12),
        BackgroundTransparency = 1,
        Font = F.Bold, Text = title,
        TextColor3 = T.Text, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 205,
    })
    regText(titleLbl, "Text")

    local msgLbl = inst("TextLabel", {
        Parent = n,
        Size = UDim2.new(1, -64, 0, 30),
        Position = UDim2.fromOffset(14, 28),
        BackgroundTransparency = 1,
        Font = F.Reg, Text = msg,
        TextColor3 = T.TextSoft, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true, ZIndex = 205,
    })
    regText(msgLbl, "TextSoft")

    -- ultra-thin progress bar at the bottom edge (now lives inside the
    -- canvas-group so it fades together with everything else on exit)
    local pbTrack = inst("Frame", {
        Parent = n, Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = T.Border, BackgroundTransparency = 0.4,
        BorderSizePixel = 0, ZIndex = 205,
    })
    local pb = inst("Frame", {
        Parent = pbTrack, Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = 206,
    })

    -- entrance
    shell.Position = UDim2.new(1, 24, 0, 0)
    shell.GroupTransparency = 1
    tw(shell, 0.4, {Size = UDim2.new(0, nW, 0, 64), Position = UDim2.fromOffset(0, 0), GroupTransparency = 0}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    task.spawn(function()
        if not RuntimeWait(0.4) then return end
        if pb and pb.Parent then
            TS:Create(pb, TweenInfo.new(math.max(dur - 0.4, 0.1), Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 1, 0)}):Play()
        end
    end)
    -- exit: clean fade + slight slide-right + small scale-in, all on one CanvasGroup
    task.spawn(function()
        if not RuntimeWait(dur) then return end
        if not shell or not shell.Parent then return end
        tw(shell, 0.35, {
            Position = UDim2.new(1, 24, 0, 0),
            GroupTransparency = 1,
        }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.delay(0.4, function() if shell then shell:Destroy() end end)
    end)
end

--// ────────────────────────────  theme accent swap  ──────────────────────────── //--
function Lib:_SetAccent(name)
    local p = findPreset(name)
    if not p then return end
    _applyPresetToT(p)
    applyThemeAll(true)
    self:Notify("theme", "applied → " .. name, "success", 2)
end

--// ────────────────────────────  config manager  ──────────────────────────── //--
-- File-based config manager (Electro Sailor pattern), restyled to Funpay aesthetic.
local CFG_FOLDER = "EminanceConfigs"
function Lib:_GetConfigPath(n) return CFG_FOLDER .. "/" .. tostring(n) .. ".json" end
function Lib:_EnsureConfigFolder()
    if isfolder and makefolder and not isfolder(CFG_FOLDER) then
        pcall(makefolder, CFG_FOLDER)
    end
end
function Lib:_SaveConfig(name)
    if not name or name == "" or not writefile then
        self:Notify("config", "save unavailable", "error", 2); return false
    end
    self:_EnsureConfigFolder()
    local d = {}
    for k, v in pairs(self.Flags or {}) do
        local vt = typeof(v)
        if vt == "number" or vt == "boolean" or vt == "string" then d[k] = v end
    end
    local ok = pcall(function() writefile(self:_GetConfigPath(name), HS:JSONEncode(d)) end)
    if ok then self:Notify("config", "saved → " .. name, "success", 2) end
    return ok
end
function Lib:_LoadConfig(name)
    if not name or name == "" or not readfile or not isfile then return false end
    local p = self:_GetConfigPath(name)
    if not isfile(p) then return false end
    local ok, d = pcall(function() return HS:JSONDecode(readfile(p)) end)
    if not ok or type(d) ~= "table" then return false end
    for k, v in pairs(d) do self.Flags[k] = v end
    for fn, el in pairs(self._cfgElements or {}) do
        if d[fn] ~= nil and el.Set then pcall(el.Set, d[fn]) end
    end
    self:Notify("config", "loaded → " .. name, "success", 2)
    return true
end
function Lib:_DeleteConfig(name)
    if not name or name == "" or not delfile or not isfile then return false end
    local p = self:_GetConfigPath(name)
    if not isfile(p) then return false end
    pcall(delfile, p)
    self:Notify("config", "deleted", "success", 2)
    return true
end
function Lib:_SetAutoLoad(name)
    if not writefile then return end
    self:_EnsureConfigFolder()
    pcall(function() writefile(CFG_FOLDER .. "/_autoload.txt", tostring(name or "")) end)
end
function Lib:_GetAutoLoadName()
    if not readfile or not isfile then return "" end
    local p = CFG_FOLDER .. "/_autoload.txt"
    if not isfile(p) then return "" end
    local ok, n = pcall(readfile, p)
    return (ok and n) or ""
end
function Lib:_AutoLoadConfig()
    local n = self:_GetAutoLoadName()
    if n ~= "" and isfile and isfile(self:_GetConfigPath(n)) then
        self:_LoadConfig(n)
    end
end
function Lib:_ListConfigs()
    if not listfiles or not isfolder or not isfolder(CFG_FOLDER) then return {} end
    local ok, f = pcall(listfiles, CFG_FOLDER)
    if not ok then return {} end
    local r = {}
    for _, ff in ipairs(f) do
        local s = tostring(ff)
        local name = s:match("([^/\\]+)%.json$")
        if name then table.insert(r, name) end
    end
    table.sort(r)
    return r
end
function Lib:_RefreshConfigList()
    local body = self._cfgListScroll
    if not body then return end
    for _, ch in ipairs(body:GetChildren()) do
        if ch:IsA("Frame") or ch:IsA("TextLabel") then ch:Destroy() end
    end
    local list = self:_ListConfigs()
    if #list == 0 then
        local empty = inst("TextLabel", {
            Parent = body, Size = UDim2.new(1, -4, 0, 24), BackgroundTransparency = 1,
            Text = "  no configs yet", TextColor3 = T.Muted, TextSize = 11, Font = F.Reg,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7,
        })
        regText(empty, "Muted")
        return
    end
    local currentAuto = self:_GetAutoLoadName()
    for i, name in ipairs(list) do
        local row = inst("Frame", {
            Parent = body, Size = UDim2.new(1, -4, 0, 26), BackgroundColor3 = T.Slot,
            BackgroundTransparency = 0.3, BorderSizePixel = 0, LayoutOrder = i, ZIndex = 7,
        })
        crn(row, 4)
        regBg(row, "Slot")
        local rs = strk(row, 1, T.Border, 0)
        regStroke(rs, "Border")
        -- auto-load star toggle
        local star = inst("TextButton", {
            Parent = row, Size = UDim2.fromOffset(20, 22),
            AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0),
            BackgroundTransparency = 1, Font = F.Bold, TextSize = 14,
            Text = (currentAuto == name) and "★" or "☆",
            TextColor3 = (currentAuto == name) and T.Accent or T.Muted,
            AutoButtonColor = false, ZIndex = 8,
        })
        if currentAuto ~= name then regText(star, "Muted") end
        local nameLbl = inst("TextLabel", {
            Parent = row, Position = UDim2.fromOffset(26, 0),
            Size = UDim2.new(1, -100, 1, 0), BackgroundTransparency = 1,
            Font = F.Med, Text = name, TextColor3 = T.Text, TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8,
        })
        regText(nameLbl, "Text")
        -- load button
        local lb = inst("TextButton", {
            Parent = row, Size = UDim2.fromOffset(30, 18),
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -38, 0.5, 0),
            BackgroundColor3 = T.SlotHi, BorderSizePixel = 0,
            Font = F.Med, Text = "load", TextSize = 10, TextColor3 = T.Accent,
            AutoButtonColor = false, ZIndex = 8,
        })
        crn(lb, 3); regBg(lb, "SlotHi")
        local lbs = strk(lb, 1, T.Border, 0); regStroke(lbs, "Border")
        -- delete button
        local db = inst("TextButton", {
            Parent = row, Size = UDim2.fromOffset(30, 18),
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0),
            BackgroundColor3 = T.SlotHi, BorderSizePixel = 0,
            Font = F.Med, Text = "del", TextSize = 10,
            TextColor3 = Color3.fromRGB(190, 70, 90),
            AutoButtonColor = false, ZIndex = 8,
        })
        crn(db, 3); regBg(db, "SlotHi")
        local dbs = strk(db, 1, T.Border, 0); regStroke(dbs, "Border")
        local hub = self
        star.MouseButton1Click:Connect(function()
            sfx("click")
            if hub:_GetAutoLoadName() == name then hub:_SetAutoLoad("") else hub:_SetAutoLoad(name) end
            hub:_RefreshConfigList()
        end)
        lb.MouseButton1Click:Connect(function() sfx("click"); hub:_LoadConfig(name) end)
        db.MouseButton1Click:Connect(function() sfx("click"); if hub:_DeleteConfig(name) then hub:_RefreshConfigList() end end)
    end
end
-- alias: понятнее, что это смена темы целиком
function Lib:_SetTheme(name) return self:_SetAccent(name) end

--// ────────────────────────────  tabs / columns  ──────────────────────────── //--
-- Material Icons sprite (rbxassetid://3926305904) — 36x36 cells.
-- Common rects per icon name (verified from public Roblox community references).
local TAB_ICON_RECTS = {
    main      = Vector2.new(964, 4),    -- home
    home      = Vector2.new(964, 4),
    general   = Vector2.new(964, 4),
    dashboard = Vector2.new(484, 644),  -- dashboard
    misc      = Vector2.new(484, 644),
    extra     = Vector2.new(484, 644),
    settings  = Vector2.new(324, 124),  -- settings (gear)
    config    = Vector2.new(324, 124),
    ["ui settings"] = Vector2.new(324, 124),
    farm      = Vector2.new(884, 444),  -- build / construction
    farming   = Vector2.new(884, 444),
    combat    = Vector2.new(404, 884),  -- whatshot
    visual    = Vector2.new(404, 484),  -- visibility
    visuals   = Vector2.new(404, 484),
    movement  = Vector2.new(844, 4),    -- directions_run
    player    = Vector2.new(124, 484),  -- person
    teleport  = Vector2.new(564, 444),  -- send
    teleports = Vector2.new(564, 444),
    info      = Vector2.new(484, 4),    -- info
}
local TAB_ICON_DEFAULT = Vector2.new(364, 124) -- circle / bullet fallback

function Lib:MakeTab(name, icon)
    local W = self
    local btn = inst("TextButton", {
        Parent = W._tabHolder,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = T.Slot,
        BackgroundTransparency = 1,
        Font = F.Med,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = #W.Tabs + 1,
        ZIndex = 5,
    })
    crn(btn, 6)
    regBg(btn, "Slot")
    pad(btn, 0, 10, 0, 10)

    -- sprite-based tab icon (Material Icons 36x36 sheet)
    local rect = icon or TAB_ICON_RECTS[string.lower(tostring(name or ""))] or TAB_ICON_DEFAULT
    local iconLbl = inst("ImageLabel", {
        Parent = btn,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        BackgroundTransparency = 1,
        Image = "rbxassetid://3926305904",
        ImageRectOffset = rect,
        ImageRectSize = Vector2.new(36, 36),
        ImageColor3 = T.Muted,
        ZIndex = 6,
    })
    regImg(iconLbl, "Muted")

    local txtLbl = inst("TextLabel", {
        Parent = btn,
        Position = UDim2.fromOffset(20, 0),
        Size = UDim2.new(1, -20, 1, 0),
        BackgroundTransparency = 1,
        Font = F.Med,
        Text = tostring(name or "tab"),
        TextColor3 = T.Muted,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
    })
    regText(txtLbl, "Muted")

    local under = inst("Frame", {
        Parent = btn,
        Size = UDim2.new(0, 3, 1, -10),
        Position = UDim2.fromOffset(5, 5),
        BackgroundColor3 = T.Accent,
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        ZIndex = 6,
    })
    crn(under, 99)

    local page = inst("Frame", {
        Parent = W._pages,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 3,
    })
    pad(page, 8, 10, 8, 10)

    local cols = inst("Frame", {Parent = page, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 3})
    inst("UIListLayout", {
        Parent = cols,
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
    })

    local tab = {_name = tostring(name or "tab"), _btn = btn, _icon = iconLbl, _txt = txtLbl, _under = under, _page = page, _cols = cols, _colList = {}, _hub = W}

    function tab:Column()
        local idx = #self._colList + 1
        local col = inst("ScrollingFrame", {
            Parent = self._cols,
            Size = UDim2.fromScale(0.5, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = T.Border,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            LayoutOrder = idx,
            ZIndex = 3,
        })
        inst("UIListLayout", {Parent = col, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder})

        table.insert(self._colList, col)
        local n = #self._colList
        local gap = 8
        local share = 1 / n
        local off = -((n - 1) * gap) / n
        for _, c in ipairs(self._colList) do
            c.Size = UDim2.new(share, off, 1, 0)
        end

        local column = {_col = col, _hub = self._hub, _tab = self}
        function column:AddSection(title)
            return Lib._BuildSection(self, title)
        end
        return column
    end

    local function activate()
        for _, t in ipairs(W.Tabs) do
            t._page.Visible = false
            tw(t._btn, 0.18, {BackgroundColor3 = T.Slot, BackgroundTransparency = 1})
            if t._icon then tw(t._icon, 0.18, {ImageColor3 = T.Muted}) end
            if t._txt then tw(t._txt, 0.18, {TextColor3 = T.Muted}) end
            tw(t._under, 0.18, {BackgroundTransparency = 1})
        end
        page.Visible = true
        if W._headerTitle then W._headerTitle.Text = tostring(name or "tab") end
        if W._headerSub then W._headerSub.Text = "Eminance / " .. tostring(name or "tab") end
        -- stoic minimalist active state: subtle bg + accent left stripe + accent icon
        tw(btn, 0.2, {BackgroundColor3 = T.SlotHi, BackgroundTransparency = 0.55})
        if iconLbl then tw(iconLbl, 0.2, {ImageColor3 = T.Accent}) end
        if txtLbl then tw(txtLbl, 0.2, {TextColor3 = T.Text}) end
        tw(under, 0.2, {BackgroundTransparency = 0})
        -- sync UI Settings floor button highlight (active when a hidden tab is shown)
        if W._uiSettingsBtn then
            if tab._hidden then
                tw(W._uiSettingsBtn, 0.2, {BackgroundColor3 = T.SlotHi, BackgroundTransparency = 0.55})
                if W._uiSettingsDot then tw(W._uiSettingsDot, 0.2, {ImageColor3 = T.Accent}) end
                if W._uiSettingsTxt then tw(W._uiSettingsTxt, 0.2, {TextColor3 = T.Text}) end
            else
                tw(W._uiSettingsBtn, 0.2, {BackgroundColor3 = T.Slot, BackgroundTransparency = 1})
                if W._uiSettingsDot then tw(W._uiSettingsDot, 0.2, {ImageColor3 = T.Muted}) end
                if W._uiSettingsTxt then tw(W._uiSettingsTxt, 0.2, {TextColor3 = T.Muted}) end
            end
        end
        page.Position = UDim2.fromOffset(0, 0)
        -- gentle fade-in of all section cards at once (no stagger, no slide)
        local sections = {}
        for _, c in ipairs(page:GetDescendants()) do
            if c:IsA("Frame") and c.Name == "_secCard" then
                table.insert(sections, c)
            end
        end
        -- single quick fade for all cards together (no stagger)
        for _, c in ipairs(sections) do
            c.BackgroundTransparency = 1
            local sStroke = c:FindFirstChildOfClass("UIStroke")
            if sStroke then sStroke.Transparency = 1 end
            tw(c, 0.22, {BackgroundTransparency = 0}, Enum.EasingStyle.Sine)
            if sStroke then tw(sStroke, 0.22, {Transparency = 0}, Enum.EasingStyle.Sine) end
        end
        W.Active = tab
        -- re-apply header search filter on the newly-activated page
        if W._applySearchFilter then task.defer(W._applySearchFilter) end
    end

    btn.MouseEnter:Connect(function()
        if W.Active ~= tab then
            tw(btn, 0.15, {BackgroundTransparency = 0.72})
            tw(iconLbl, 0.15, {ImageColor3 = T.TextSoft})
            tw(txtLbl, 0.15, {TextColor3 = T.TextSoft})
        end
    end)
    btn.MouseLeave:Connect(function()
        if W.Active ~= tab then
            tw(btn, 0.15, {BackgroundTransparency = 1})
            tw(iconLbl, 0.15, {ImageColor3 = T.Muted})
            tw(txtLbl, 0.15, {TextColor3 = T.Muted})
        end
    end)
    btn.MouseButton1Click:Connect(function() activate(); ripple(btn, T.Accent) end)

    tab._activate = activate
    -- re-apply active-tab highlight after theme repaint (stoic minimalist style)
    regCallback(function()
        if W.Active == tab then
            btn.BackgroundColor3 = T.SlotHi
            btn.BackgroundTransparency = 0.55
            under.BackgroundColor3 = T.Accent
            under.BackgroundTransparency = 0
            if iconLbl then iconLbl.ImageColor3 = T.Accent end
            if txtLbl  then txtLbl.TextColor3   = T.Text end
            if tab._hidden and W._uiSettingsBtn then
                W._uiSettingsBtn.BackgroundColor3 = T.SlotHi
                W._uiSettingsBtn.BackgroundTransparency = 0.55
                if W._uiSettingsDot then W._uiSettingsDot.ImageColor3 = T.Accent end
                if W._uiSettingsTxt then W._uiSettingsTxt.TextColor3  = T.Text end
            end
        end
    end)
    table.insert(W.Tabs, tab)
    if #W.Tabs == 1 then activate() end
    return tab
end

-- Hidden tab: same as MakeTab but the sidebar button is invisible / not in the layout.
-- Use it for panels that are reached through a custom button (e.g. UI Settings).
function Lib:MakeHiddenTab(name)
    local tab = self:MakeTab(name)
    if tab and tab._btn then
        tab._hidden = true
        tab._btn.Visible = false
        tab._btn.Size = UDim2.new(0, 0, 0, 0)
        -- if it became the first/active tab, deactivate it so the next real tab takes over
        if self.Active == tab then
            self.Active = nil
            tab._page.Visible = false
        end
    end
    return tab
end

--// ────────────────────────────  section (fieldset)  ──────────────────────────── //--
function Lib._BuildSection(column, title)
    local sec = inst("Frame", {
        Parent = column._col,
        Name = "_secCard",
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = T.PanelHi,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = false,
        ZIndex = 4,
    })
    crn(sec, 3)
    local sStroke = strk(sec, 1, T.Border, 0)
    regBg(sec, "PanelHi")
    regStroke(sStroke, "Border")
    -- decorative accent gradient on section borders (premium look)
    local secStrokeGrad = inst("UIGradient", {
        Parent = sStroke,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,    T.Border),
            ColorSequenceKeypoint.new(0.45, T.Accent),
            ColorSequenceKeypoint.new(0.55, T.Accent),
            ColorSequenceKeypoint.new(1,    T.Border),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0,    0),
            NumberSequenceKeypoint.new(0.5,  0.55),
            NumberSequenceKeypoint.new(1,    0),
        }),
        Rotation = 25,
    })
    regGrad(secStrokeGrad, {"Border", "Accent", "Accent", "Border"})

    -- subtle accent glow underlay (becomes visible on hover)
    local glow = inst("Frame", {
        Parent = sec,
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = T.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 3,
    })
    crn(glow, 4)
    regBg(glow, "Accent")

    -- inner body holds padding + layout; title chip is sibling (so it can overlap top border)
    local body = inst("Frame", {Parent = sec, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 4})
    pad(body, 26, 12, 10, 12)
    inst("UIListLayout", {Parent = body, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder})

    -- fieldset legend chip overlapping top border (sibling of body so UIPadding doesn't shift it)
    local titleChip = inst("Frame", {
        Parent = sec,
        AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.fromOffset(10, 7),
        Size = UDim2.fromOffset(0, 16),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = T.PanelHi,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 6,
    })
    pad(titleChip, 0, 5, 0, 5)
    regBg(titleChip, "PanelHi")
    -- horizontal layout so the accent bar sits next to the title text
    inst("UIListLayout", {
        Parent = titleChip,
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    })
    -- accent vertical bar replaces the "≡" glyph (always renders, on-brand)
    local titleBar = inst("Frame", {
        Parent = titleChip,
        Size = UDim2.fromOffset(2, 11),
        BackgroundColor3 = T.Accent,
        BorderSizePixel = 0,
        LayoutOrder = 1,
        ZIndex = 7,
    })
    crn(titleBar, 99)
    regBg(titleBar, "Accent")
    local titleLbl = inst("TextLabel", {
        Parent = titleChip,
        Size = UDim2.fromOffset(0, 16),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Font = F.Bold,
        Text = tostring(title or "section"),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 13,
        TextYAlignment = Enum.TextYAlignment.Center,
        LayoutOrder = 2,
        ZIndex = 7,
    })
    -- sweeping shimmer effect: bright peak slides across each section title
    makeShimmer(titleLbl, "Accent", 0.4)

    -- hover-подсветка секций отключена по запросу

    local s = {_sec = sec, _body = body, _stroke = sStroke, _hub = column._hub, _title = tostring(title or "section")}
    function s:AddToggle(name, def, cb, opts)   return Lib._Toggle(self, name, def, cb, opts)   end
    function s:AddSlider(name, mn, mx, def, cb, opts) return Lib._Slider(self, name, mn, mx, def, cb, opts) end
    function s:AddDropdown(name, list, cb, opts) return Lib._Dropdown(self, name, list, cb, opts) end
    function s:AddKeybind(name, def, cb)         return Lib._Keybind(self, name, def, cb)         end
    function s:AddColorPicker(name, def, cb)     return Lib._ColorPicker(self, name, def, cb)     end
    function s:AddButton(name, cb)               return Lib._Button(self, name, cb)               end
    function s:AddLabel(text)                    return Lib._Label(self, text)                    end
    return s
end

--// ────────────────────────────  picker popup helper  ──────────────────────────── //--
local DefaultPresets = nil
local function getDefaultPresets()
    if not DefaultPresets then
        DefaultPresets = {
            T.Accent, T.Red, T.Purple, T.Cyan, T.Green,
            Color3.fromRGB(240, 220, 80),
            Color3.fromRGB(255, 140, 30),
            Color3.fromRGB(255, 255, 255),
        }
    end
    return DefaultPresets
end

-- Attaches a preset color popup to a clickable swatch button.
-- onPick(color) is fired when user picks a color.
-- The popup is parented to ScreenGui so it floats above all sections/rows.
-- hub (optional) registers an external closer used by the window's hide/minimize logic.
local function attachPicker(swatch, presets, onPick, hub)
    presets = presets or getDefaultPresets()
    local sg = swatch:FindFirstAncestorOfClass("ScreenGui")
    local panel = inst("Frame", {
        Parent = sg or swatch,
        AnchorPoint = Vector2.new(1, 0),
        Size = UDim2.fromOffset(120, 0),
        BackgroundColor3 = T.Slot,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 320,
        Name = "_picker",
    })
    crn(panel, 3); strk(panel, 1, T.BorderHi, 0)
    local grid = inst("Frame", {Parent = panel, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 321})
    pad(grid, 6, 6, 6, 6)
    inst("UIGridLayout", {Parent = grid, CellSize = UDim2.fromOffset(20, 14), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder})

    local open = false
    local posConn

    local function snapPos()
        if not swatch.Parent then return end
        local ap = swatch.AbsolutePosition
        local as = swatch.AbsoluteSize
        -- anchor (1,0) -> position is the panel's TOP-RIGHT corner
        -- place panel just above swatch, right edge aligned with swatch right + small offset
        panel.Position = UDim2.fromOffset(ap.X + as.X + 4, ap.Y - 2)
    end

    local function close()
        open = false
        tw(panel, 0.18, {Size = UDim2.fromOffset(120, 0)})
        task.delay(0.2, function()
            if not open then
                panel.Visible = false
                if posConn then posConn:Disconnect(); posConn = nil end
            end
        end)
    end

    swatch.MouseButton1Click:Connect(function()
        open = not open
        if open then
            snapPos()
            if not posConn then posConn = TrackConnection(RS.RenderStepped:Connect(snapPos)) end
            panel.Visible = true
            tw(panel, 0.2, {Size = UDim2.fromOffset(120, 60)})
        else close() end
    end)

    for i, c in ipairs(presets) do
        local b = inst("TextButton", {
            Parent = grid,
            BackgroundColor3 = c,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = i,
            ZIndex = 322,
        })
        crn(b, 2); local bs = strk(b, 1, T.Border, 0)
        b.MouseEnter:Connect(function() tw(bs, 0.12, {Color = T.BorderHi}) end)
        b.MouseLeave:Connect(function() tw(bs, 0.12, {Color = T.Border}) end)
        b.MouseButton1Click:Connect(function()
            swatch.BackgroundColor3 = c
            safe(onPick, c)
            close()
        end)
    end

    if hub and hub._popupClosers then
        table.insert(hub._popupClosers, function() if open then close() end end)
    end

    return {Close = close, _panel = panel}
end

--// ────────────────────────────  toggle  ──────────────────────────── //--
function Lib._Toggle(s, name, def, cb, opts)
    opts = opts or {}
    local v = def == true

    local row = inst("Frame", {Parent = s._body, Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, ZIndex = 5})

    local rightOffset = 0
    -- order from right edge: keybind first (innermost), then color square
    local kbBtn, kbState
    if opts.keybind ~= nil then
        kbState = {key = opts.keybind, capturing = false}
        kbBtn = inst("TextButton", {
            Parent = row,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -rightOffset, 0.5, 0),
            Size = UDim2.fromOffset(28, 16),
            BackgroundColor3 = T.Slot,
            BorderSizePixel = 0,
            Font = F.Med,
            Text = tostring(opts.keybind or "..."),
            TextSize = 10,
            TextColor3 = T.Muted,
            AutoButtonColor = false,
            ZIndex = 6,
        })
        crn(kbBtn, 2)
        regBg(kbBtn, "Slot")
        regText(kbBtn, "Muted")
        local kbStroke = strk(kbBtn, 1, T.Border, 0)
        regStroke(kbStroke, "Border")
        kbBtn.MouseEnter:Connect(function() tw(kbStroke, 0.15, {Color = T.BorderHi}); tw(kbBtn, 0.15, {TextColor3 = T.Text}) end)
        kbBtn.MouseLeave:Connect(function() if not kbState.capturing then tw(kbStroke, 0.15, {Color = T.Border}); tw(kbBtn, 0.15, {TextColor3 = T.Muted}) end end)
        kbBtn.MouseButton1Click:Connect(function()
            kbState.capturing = true
            kbBtn.Text = "..."
            tw(kbStroke, 0.15, {Color = T.Accent})
            tw(kbBtn, 0.15, {TextColor3 = T.Accent})
        end)
        TrackConnection(UIS.InputBegan:Connect(function(input, gp2)
            if gp2 or not IsAlive() or not kbState.capturing then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then return end
            kbState.key = keyName(input)
            kbBtn.Text = kbState.key
            kbState.capturing = false
            tw(kbStroke, 0.15, {Color = T.Border})
            tw(kbBtn, 0.15, {TextColor3 = T.Muted})
        end))
        rightOffset = rightOffset + 28 + 6
    end

    local swatch
    if opts.color ~= nil then
        swatch = inst("TextButton", {
            Parent = row,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -rightOffset, 0.5, 0),
            Size = UDim2.fromOffset(20, 12),
            BackgroundColor3 = opts.color,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 6,
        })
        crn(swatch, 2)
        local swStroke = strk(swatch, 1, T.Border, 0)
        regStroke(swStroke, "Border")
        swatch.MouseEnter:Connect(function() tw(swStroke, 0.15, {Color = T.BorderHi}) end)
        swatch.MouseLeave:Connect(function() tw(swStroke, 0.15, {Color = T.Border}) end)
        attachPicker(swatch, nil, function(c) safe(opts.onColor, c) end, s._hub)
        rightOffset = rightOffset + 20 + 6
    end

    -- capsule toggle (iOS-style pill with circular knob)
    local capsuleW, capsuleH = 26, 14
    local box = inst("TextButton", {
        Parent = row,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -rightOffset, 0.5, 0),
        Size = UDim2.fromOffset(capsuleW, capsuleH),
        BackgroundColor3 = T.Slot,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 5,
    })
    crn(box, 99)
    regBg(box, "Slot")
    local bStroke = strk(box, 1, T.Border, 0)
    regStroke(bStroke, "Border")
    -- accent fill underlay (becomes opaque when ON)
    local fill = inst("Frame", {
        Parent = box,
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = T.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 5,
    })
    crn(fill, 99)
    regBg(fill, "Accent")
    local fillGrad = inst("UIGradient", {
        Parent = fill,
        Color = ColorSequence.new(T.AccentLo, T.AccentHi),
        Rotation = 0,
    })
    regGrad(fillGrad, {"AccentLo", "AccentHi"})
    -- circular knob
    local knobR = capsuleH - 4
    local knob = inst("Frame", {
        Parent = box,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromOffset(2, capsuleH / 2),
        Size = UDim2.fromOffset(knobR, knobR),
        BackgroundColor3 = Color3.fromRGB(220, 220, 230),
        BorderSizePixel = 0,
        ZIndex = 7,
    })
    crn(knob, 99)

    -- label
    local labelBtn = inst("TextButton", {
        Parent = row,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, -(capsuleW + 6) - rightOffset, 1, 0),
        BackgroundTransparency = 1,
        Font = F.Reg,
        Text = name or "toggle",
        TextSize = 12,
        TextColor3 = T.TextSoft,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        ZIndex = 5,
    })
    regText(labelBtn, "TextSoft")

    local function set(nv, fire)
        if not IsAlive() then return end
        local was = v
        v = nv == true
        if v then
            tw(fill, 0.2, {BackgroundTransparency = 0})
            tw(knob, 0.2, {Position = UDim2.fromOffset(capsuleW - knobR - 2, capsuleH / 2), BackgroundColor3 = Color3.fromRGB(255, 255, 255)})
            tw(bStroke, 0.2, {Color = T.Accent})
            tw(labelBtn, 0.2, {TextColor3 = T.Text})
        else
            tw(fill, 0.2, {BackgroundTransparency = 1})
            tw(knob, 0.2, {Position = UDim2.fromOffset(2, capsuleH / 2), BackgroundColor3 = Color3.fromRGB(220, 220, 230)})
            tw(bStroke, 0.2, {Color = T.Border})
            tw(labelBtn, 0.2, {TextColor3 = T.TextSoft})
        end
        if fire ~= false then
            if was ~= v then sfx(v and "toggle_on" or "toggle_off") end
            safe(cb, v)
        end
    end

    box.MouseEnter:Connect(function() if not v then tw(bStroke, 0.15, {Color = T.BorderHi}) end end)
    box.MouseLeave:Connect(function() if not v then tw(bStroke, 0.15, {Color = T.Border}) end end)

    box.MouseButton1Click:Connect(function() if not IsAlive() then return end; set(not v); ripple(box, T.Accent) end)
    labelBtn.MouseButton1Click:Connect(function() if not IsAlive() then return end; set(not v) end)

    if v then set(true, false) end
    -- re-apply ON-state visuals after a theme switch, otherwise the registry
    -- will have just reset bStroke to Border / labelBtn to TextSoft.
    regCallback(function()
        if v then
            bStroke.Color = T.Accent
            labelBtn.TextColor3 = T.Text
        else
            bStroke.Color = T.Border
            labelBtn.TextColor3 = T.TextSoft
        end
    end)

    local api = {Set = function(_, nv) set(nv) end, Get = function() return v end}
    -- register flag in Hub for Config Manager
    if s._hub and name then
        local flag = (s._title and (s._title .. "/" .. name)) or name
        s._hub.Flags[flag] = v
        s._hub._cfgElements = s._hub._cfgElements or {}
        s._hub._cfgElements[flag] = {Set = function(nv) set(nv == true) end}
        local origCb = cb
        cb = function(nv) s._hub.Flags[flag] = nv; if origCb then origCb(nv) end end
    end
    if kbState then
        TrackConnection(UIS.InputBegan:Connect(function(input, gp2)
            if gp2 or not IsAlive() or kbState.capturing then return end
            if input.KeyCode and input.KeyCode.Name == kbState.key then
                set(not v)
                ripple(box, T.Accent)
            end
        end))
        api.GetKey = function() return kbState.key end
    end
    if swatch then
        api.SetColor = function(_, c) if c then swatch.BackgroundColor3 = c end end
        api.GetColor = function() return swatch.BackgroundColor3 end
    end
    return api
end

--// ────────────────────────────  slider  ──────────────────────────── //--
function Lib._Slider(s, name, mn, mx, def, cb, opts)
    opts = opts or {}
    local v = math.clamp(def or mn, mn, mx)

    local row = inst("Frame", {Parent = s._body, Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, ZIndex = 5})

    local lbl = inst("TextLabel", {
        Parent = row,
        Size = UDim2.new(1, -60, 0, 12),
        BackgroundTransparency = 1,
        Font = F.Reg,
        Text = name or "slider",
        TextColor3 = T.TextSoft,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    })
    regText(lbl, "TextSoft")

    local function fmt(val)
        if opts.format then return opts.format(val, mx) end
        if opts.suffix then return ("%d%s/%d%s"):format(val, opts.suffix, mx, opts.suffix) end
        return ("%d/%d"):format(val, mx)
    end

    -- Editable value: TextBox styled to look like a label but accepts focus.
    -- Click → type → Enter applies the new value (clamped to [mn..mx]).
    local valLbl = inst("TextBox", {
        Parent = row,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(60, 12),
        BackgroundTransparency = 1,
        ClearTextOnFocus = true,
        Font = F.Med,
        Text = fmt(v),
        TextColor3 = T.Dim,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 6,
    })
    regText(valLbl, "Dim")

    -- thin pill-shaped track
    local track = inst("Frame", {
        Parent = row,
        Size = UDim2.new(1, 0, 0, 4),
        Position = UDim2.fromOffset(0, 22),
        BackgroundColor3 = T.Slot,
        BorderSizePixel = 0,
        ZIndex = 5,
    })
    crn(track, 99)
    regBg(track, "Slot")
    local tStroke = strk(track, 1, T.Border, 0)
    regStroke(tStroke, "Border")

    local fill = inst("Frame", {
        Parent = track,
        Size = UDim2.fromScale((v - mn) / math.max(mx - mn, 1), 1),
        BackgroundColor3 = T.Accent,
        BorderSizePixel = 0,
        ZIndex = 6,
    })
    crn(fill, 99)
    regBg(fill, "Accent")
    local fillGrad = inst("UIGradient", {
        Parent = fill,
        Color = ColorSequence.new(T.AccentLo, T.Accent),
        Rotation = 0,
    })
    regGrad(fillGrad, {"AccentLo", "Accent"})

    -- circular thumb (knob) at the end of the fill
    local thumbR = 12
    local thumb = inst("Frame", {
        Parent = track,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new((v - mn) / math.max(mx - mn, 1), 0, 0.5, 0),
        Size = UDim2.fromOffset(thumbR, thumbR),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 8,
    })
    crn(thumb, 99)
    local thumbStroke = strk(thumb, 1, T.Accent, 0)
    regStroke(thumbStroke, "Accent")

    local function set(nv, fire)
        if not IsAlive() then return end
        local step = opts.step or 1
        v = math.clamp(math.floor((nv / step) + 0.5) * step, mn, mx)
        local rel = (v - mn) / math.max(mx - mn, 1)
        tw(fill, 0.12, {Size = UDim2.fromScale(rel, 1)})
        tw(thumb, 0.12, {Position = UDim2.new(rel, 0, 0.5, 0)})
        valLbl.Text = fmt(v)
        if fire ~= false then safe(cb, v) end
    end

    local dragging = false
    local function relUpdate(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        set(mn + rel * (mx - mn))
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            tw(tStroke, 0.15, {Color = T.Accent})
            tw(valLbl, 0.15, {TextColor3 = T.Text})
            relUpdate(i.Position.X)
        end
    end)
    track.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            tw(tStroke, 0.15, {Color = T.Border})
            tw(valLbl, 0.15, {TextColor3 = T.Dim})
        end
    end)
    TrackConnection(UIS.InputChanged:Connect(function(i)
        if not IsAlive() then return end
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            relUpdate(i.Position.X)
        end
    end))

    track.MouseEnter:Connect(function() if not dragging then tw(tStroke, 0.15, {Color = T.BorderHi}); tw(valLbl, 0.15, {TextColor3 = T.TextSoft}) end end)
    track.MouseLeave:Connect(function() if not dragging then tw(tStroke, 0.15, {Color = T.Border}); tw(valLbl, 0.15, {TextColor3 = T.Dim}) end end)

    -- Editable value: parse on Enter, revert on cancel
    valLbl.Focused:Connect(function()
        tw(valLbl, 0.12, {TextColor3 = T.Accent})
    end)
    valLbl.FocusLost:Connect(function(enterPressed)
        if not IsAlive() then return end
        if enterPressed and valLbl.Text ~= "" then
            local numText = string.match(valLbl.Text, "%-?%d+%.?%d*")
            local n = tonumber(numText)
            if n then
                set(n)
            else
                valLbl.Text = fmt(v)
            end
        else
            valLbl.Text = fmt(v)
        end
        tw(valLbl, 0.12, {TextColor3 = T.Dim})
    end)

    -- register flag in Hub for Config Manager
    if s._hub and name then
        local flag = (s._title and (s._title .. "/" .. name)) or name
        s._hub.Flags[flag] = v
        s._hub._cfgElements = s._hub._cfgElements or {}
        s._hub._cfgElements[flag] = {Set = function(nv) set(tonumber(nv) or v) end}
        local origCb = cb
        cb = function(nv) s._hub.Flags[flag] = nv; if origCb then origCb(nv) end end
    end
    set(v, false)
    -- restore drag/hover stroke override after theme repaint
    regCallback(function()
        if dragging then
            tStroke.Color = T.Accent
            valLbl.TextColor3 = T.Text
        else
            tStroke.Color = T.Border
            valLbl.TextColor3 = T.Dim
        end
    end)
    return {Set = function(_, nv) set(nv) end, Get = function() return v end}
end

--// ────────────────────────────  dropdown  ──────────────────────────── //--
function Lib._Dropdown(s, name, list, cb, opts)
    opts = opts or {}
    list = list or {}
    local visibleRows = opts.visibleRows or 5
    local rowHeight = opts.rowHeight or 18
    local searchable = opts.search == true

    local row = inst("Frame", {Parent = s._body, Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, ZIndex = 5})

    local nameLbl = inst("TextLabel", {
        Parent = row,
        Size = UDim2.new(1, 0, 0, 12),
        BackgroundTransparency = 1,
        Font = F.Reg,
        Text = name or "dropdown",
        TextColor3 = T.TextSoft,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    })
    regText(nameLbl, "TextSoft")

    local box = inst("TextButton", {
        Parent = row,
        Size = UDim2.new(1, 0, 0, 17),
        Position = UDim2.fromOffset(0, 15),
        BackgroundColor3 = T.Slot,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 5,
    })
    crn(box, 3)
    regBg(box, "Slot")
    local bStroke = strk(box, 1, T.Border, 0)
    regStroke(bStroke, "Border")

    local sel = opts.default or list[1] or ""

    local valLbl = inst("TextLabel", {
        Parent = box,
        Size = UDim2.new(1, -22, 1, 0),
        Position = UDim2.fromOffset(8, 0),
        BackgroundTransparency = 1,
        Font = F.Reg,
        Text = tostring(sel),
        TextColor3 = T.Text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
    })
    regText(valLbl, "Text")

    local arrow = inst("ImageLabel", {
        Parent = box,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -6, 0.5, 0),
        Size = UDim2.fromOffset(12, 12),
        BackgroundTransparency = 1,
        Image = "rbxassetid://3926305904",
        ImageRectOffset = Vector2.new(884, 124),
        ImageRectSize = Vector2.new(36, 36),
        ImageColor3 = T.Muted,
        ZIndex = 6,
    })
    regImg(arrow, "Muted")

    local sg = box:FindFirstAncestorOfClass("ScreenGui")
    local panel = inst("Frame", {
        Parent = sg or box,
        Size = UDim2.fromOffset(0, 0),
        BackgroundColor3 = T.Slot,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 300,
        Name = "_ddPopup",
    })
    regBg(panel, "Slot")
    crn(panel, 3)
    local pStroke = strk(panel, 1, T.BorderHi, 0)
    regStroke(pStroke, "BorderHi")

    local searchBox
    local searchHeight = searchable and 22 or 0
    if searchable then
        searchBox = inst("TextBox", {
            Parent = panel,
            Size = UDim2.new(1, -8, 0, 18),
            Position = UDim2.fromOffset(4, 3),
            BackgroundColor3 = T.PanelHi,
            BorderSizePixel = 0,
            ClearTextOnFocus = false,
            Font = F.Reg,
            PlaceholderText = "search...",
            Text = "",
            TextColor3 = T.Text,
            PlaceholderColor3 = T.Muted,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTransparency = 0,
            BackgroundTransparency = 0,
            ZIndex = 302,
        })
        crn(searchBox, 3)
        regBg(searchBox, "PanelHi")
        regText(searchBox, "Text")
        local sbStroke = strk(searchBox, 1, T.Border, 0)
        regStroke(sbStroke, "Border")
    end

    local plist = inst("ScrollingFrame", {
        Parent = panel,
        Position = UDim2.fromOffset(0, searchHeight),
        Size = UDim2.new(1, 0, 1, -searchHeight),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = T.Border,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 301,
    })
    inst("UIListLayout", {Parent = plist, SortOrder = Enum.SortOrder.LayoutOrder})

    local open = false
    local posConn
    local visibleList = list
    local function filtered()
        if not searchable or not searchBox or searchBox.Text == "" then return list end
        local q = tostring(searchBox.Text):lower()
        local out = {}
        for _, item in ipairs(list) do
            if tostring(item):lower():find(q, 1, true) then
                table.insert(out, item)
            end
        end
        return out
    end
    local function targetHeight()
        visibleList = filtered()
        local rows = math.max(1, #visibleList)
        return math.min(rows * rowHeight, visibleRows * rowHeight) + searchHeight
    end
    local function snapPos()
        if not box.Parent then return end
        local ap = box.AbsolutePosition
        local as = box.AbsoluteSize
        local curH = panel.Size.Y.Offset
        panel.Position = UDim2.fromOffset(ap.X, ap.Y + as.Y + 4)
        panel.Size = UDim2.fromOffset(as.X, curH)
    end

    local function setOpen(force)
        if not IsAlive() then return end
        if force ~= nil then open = force else open = not open end
        if open then
            local as = box.AbsoluteSize
            panel.Size = UDim2.fromOffset(as.X, 0)
            snapPos()
            panel.Visible = true
            if not posConn then posConn = TrackConnection(RS.RenderStepped:Connect(snapPos)) end
            local target = targetHeight()
            tw(panel, 0.2, {Size = UDim2.fromOffset(as.X, target)})
            tw(arrow, 0.2, {Rotation = 180, ImageColor3 = T.Accent})
            tw(bStroke, 0.2, {Color = T.Accent})
            if searchable and searchBox then task.defer(function() searchBox:CaptureFocus() end) end
        else
            tw(panel, 0.2, {Size = UDim2.fromOffset(box.AbsoluteSize.X, 0)})
            tw(arrow, 0.2, {Rotation = 0, ImageColor3 = T.Muted})
            tw(bStroke, 0.2, {Color = T.Border})
            task.delay(0.22, function()
                if not open then
                    panel.Visible = false
                    if posConn then posConn:Disconnect(); posConn = nil end
                end
            end)
        end
    end

    local function rebuild()
        for _, c in ipairs(plist:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        visibleList = filtered()
        for i, item in ipairs(visibleList) do
            local isSelected = (item == sel)
            local b = inst("TextButton", {
                Parent = plist,
                Size = UDim2.new(1, 0, 0, rowHeight),
                BackgroundColor3 = T.Slot,
                BorderSizePixel = 0,
                Font = F.Reg,
                Text = "  " .. tostring(item),
                TextSize = 11,
                TextColor3 = isSelected and T.Accent or T.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false,
                LayoutOrder = i,
                ZIndex = 302,
            })
            b.MouseEnter:Connect(function() tw(b, 0.12, {BackgroundColor3 = T.SlotHi}) end)
            b.MouseLeave:Connect(function() tw(b, 0.12, {BackgroundColor3 = T.Slot}) end)
            b.MouseButton1Click:Connect(function()
                if not IsAlive() then return end
                sel = item
                valLbl.Text = tostring(item)
                safe(cb, item)
                rebuild()
                setOpen(false)
            end)
        end
        if open then
            tw(panel, 0.12, {Size = UDim2.fromOffset(box.AbsoluteSize.X, targetHeight())})
        end
    end

    if searchable and searchBox then
        TrackConnection(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            if IsAlive() then rebuild() end
        end))
    end

    box.MouseButton1Click:Connect(function() if IsAlive() then setOpen() end end)
    box.MouseEnter:Connect(function() if not open then tw(bStroke, 0.15, {Color = T.BorderHi}) end end)
    box.MouseLeave:Connect(function() if not open then tw(bStroke, 0.15, {Color = T.Border}) end end)

    rebuild()
    if sel ~= "" then safe(cb, sel) end

    -- register flag in Hub for Config Manager
    if s._hub and name then
        local flag = (s._title and (s._title .. "/" .. name)) or name
        s._hub.Flags[flag] = sel
        s._hub._cfgElements = s._hub._cfgElements or {}
        s._hub._cfgElements[flag] = {Set = function(nv)
            if not IsAlive() or not nv then return end
            if table.find(list, nv) or table.find(list, tostring(nv)) then
                sel = nv; valLbl.Text = tostring(nv); rebuild(); safe(cb, nv)
            end
        end}
        local origCb = cb
        cb = function(nv) s._hub.Flags[flag] = nv; if origCb then origCb(nv) end end
    end

    -- repaint visible rows on theme switch (rows are short-lived, so direct
    -- registration in _themed would leak; this closure walks current children).
    regCallback(function()
        if not plist or not plist.Parent then return end
        for _, c in ipairs(plist:GetChildren()) do
            if c:IsA("TextButton") then
                c.BackgroundColor3 = T.Slot
                local label = string.sub(c.Text, 3) -- strip leading "  "
                c.TextColor3 = (label == tostring(sel)) and T.Accent or T.Text
            end
        end
    end)

    -- register external closer so window hide / minimize closes us
    if s._hub and s._hub._popupClosers then
        table.insert(s._hub._popupClosers, function() if open then setOpen(false) end end)
    end

    return {
        Set = function(_, v) if IsAlive() and v then sel = v; valLbl.Text = tostring(v); rebuild() end end,
        Get = function() return sel end,
        SetOptions = function(_, newList) if not IsAlive() then return end; list = newList or {}; if not table.find(list, sel) then sel = list[1] or ""; valLbl.Text = tostring(sel) end; rebuild() end,
    }
end

--// ────────────────────────────  keybind (standalone)  ──────────────────────────── //--
function Lib._Keybind(s, name, def, cb)
    local row = inst("Frame", {Parent = s._body, Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, ZIndex = 5})

    local lbl = inst("TextLabel", {
        Parent = row,
        Size = UDim2.new(1, -40, 1, 0),
        BackgroundTransparency = 1,
        Font = F.Reg,
        Text = name or "keybind",
        TextColor3 = T.TextSoft,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    })

    local state = {key = def, capturing = false}
    local kb = inst("TextButton", {
        Parent = row,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(34, 16),
        BackgroundColor3 = T.Slot,
        BorderSizePixel = 0,
        Font = F.Med,
        Text = (def and tostring(def)) or "...",
        TextSize = 10,
        TextColor3 = T.Muted,
        AutoButtonColor = false,
        ZIndex = 6,
    })
    crn(kb, 2); local kbS = strk(kb, 1, T.Border, 0)
    kb.MouseButton1Click:Connect(function()
        state.capturing = true; kb.Text = "..."
        tw(kbS, 0.15, {Color = T.Accent})
    end)
    TrackConnection(UIS.InputBegan:Connect(function(input, gp2)
        if gp2 or not IsAlive() or not state.capturing then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then return end
        state.key = keyName(input)
        kb.Text = state.key
        state.capturing = false
        tw(kbS, 0.15, {Color = T.Border})
        safe(cb, state.key)
    end))
    return {Get = function() return state.key end, Set = function(_, k) state.key = k; kb.Text = tostring(k) end}
end

--// ────────────────────────────  color picker (compact popup)  ──────────────────────────── //--
function Lib._ColorPicker(s, name, def, cb)
    local row = inst("Frame", {Parent = s._body, Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, ZIndex = 5})

    inst("TextLabel", {
        Parent = row,
        Size = UDim2.new(1, -30, 1, 0),
        BackgroundTransparency = 1,
        Font = F.Reg,
        Text = name or "color",
        TextColor3 = T.TextSoft,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    })

    local cur = def or T.Accent
    local sw = inst("TextButton", {
        Parent = row,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(22, 12),
        BackgroundColor3 = cur,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 6,
    })
    crn(sw, 2)
    local swStroke = strk(sw, 1, T.Border, 0)
    sw.MouseEnter:Connect(function() tw(swStroke, 0.15, {Color = T.BorderHi}) end)
    sw.MouseLeave:Connect(function() tw(swStroke, 0.15, {Color = T.Border}) end)

    attachPicker(sw, nil, function(c) cur = c; safe(cb, c) end, s._hub)

    return {Get = function() return cur end, Set = function(_, c) cur = c; sw.BackgroundColor3 = c end}
end

--// ────────────────────────────  button / label  ──────────────────────────── //--
function Lib._Button(s, name, cb)
    local b = inst("TextButton", {
        Parent = s._body,
        Size = UDim2.new(1, 0, 0, 21),
        BackgroundColor3 = T.Slot,
        BorderSizePixel = 0,
        Font = F.Med,
        Text = name or "button",
        TextSize = 12,
        TextColor3 = T.Text,
        AutoButtonColor = false,
        ZIndex = 5,
    })
    crn(b, 2); local bs = strk(b, 1, T.Border, 0)
    regBg(b, "Slot")
    regText(b, "Text")
    regStroke(bs, "Border")
    b.MouseEnter:Connect(function() tw(b, 0.15, {BackgroundColor3 = T.SlotHi}); tw(bs, 0.15, {Color = T.BorderHi}) end)
    b.MouseLeave:Connect(function() tw(b, 0.15, {BackgroundColor3 = T.Slot}); tw(bs, 0.15, {Color = T.Border}) end)
    b.MouseButton1Click:Connect(function() sfx("click"); ripple(b, T.Accent); safe(cb) end)
    return b
end

function Lib._Label(s, text)
    local l = inst("TextLabel", {
        Parent = s._body,
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Font = F.Reg,
        Text = text or "",
        TextColor3 = T.Muted,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    })
    regText(l, "Muted")
    return l
end

local Hub = Lib:MakeWindow({Title = "Eminance", Subtitle = "premium", ToggleKey = Enum.KeyCode.RightShift})

local Main = Hub:MakeTab("main")
local mLeft  = Main:Column()
local mRight = Main:Column()

local AutoFarm = {
    enabled = false,
    debug = false,
    walkGuard = true,
    restartDelay = 0.18,
    failDelay = 0.25,
    replDelay = 0.14,
    invokeLead = 0.02,
    perfectOffset = 0,
    targetSpeed = 16,
    backgroundGhost = true,
    doubleTP = true,
    doubleDelay = 0.02,
    compensateMove = false,
    maxCompensate = 0,
    qte = nil,
    listeners = false,
    walkConn = nil,
    loopRunning = false,
    runToken = 0,
    state = {
        active = false,
        swapId = 0,
        swapTime = 0,
        swapStartLine = 0,
        barSpeed = 0,
        barRotation = 0,
        cancelToken = 0,
        finishedEvt = Instance.new("BindableEvent"),
    },
    spots = {
        {name = "Bay Island",        cf = CFrame.new(72.51, 26.46, 147.94)},
        {name = "Sea Stack Islands", cf = CFrame.new(888.92, 28.43, 1450.31)},
        {name = "Sacred Mountain",   cf = CFrame.new(2633.38, 30.50, 399.93)},
        {name = "Caldera Cay",       cf = CFrame.new(1657.74, 25.76, -1345.05)},
        {name = "Solmere",           cf = CFrame.new(-1481.39, 29.38, -1618.25)},
        {name = "Crescent Shore",    cf = CFrame.new(-1413.13, 30.76, 1519.42)},
    },
}

function AutoFarm:IsStopped(token)
    return not IsAlive() or not self.enabled or (token ~= nil and token ~= self.runToken)
end

function AutoFarm:Sleep(seconds, token)
    local deadline = os.clock() + math.max(0, seconds or 0)
    while not self:IsStopped(token) and os.clock() < deadline do
        task.wait(math.min(0.05, deadline - os.clock()))
    end
    return not self:IsStopped(token)
end

function AutoFarm:GetChar()
    local char = LP.Character or LP.CharacterAdded:Wait()
    return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

function AutoFarm:GetQTE()
    if self.qte then return self.qte end
    local ok, network = pcall(function()
        return require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Communication"):WaitForChild("Network"))
    end)
    if ok and network and network.QTE and network.QTE.queries and network.QTE.packets then
        self.qte = network.QTE
        return self.qte
    end
    return nil
end

function AutoFarm:EnsureTool(token)
    local char, _, hum = self:GetChar()
    if not char or not hum then return false end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and tool:GetAttribute("Type") == "Equipment" then
        return true
    end
    local backpack = LP:FindFirstChildOfClass("Backpack")
    if not backpack then return false end
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") and item:GetAttribute("Type") == "Equipment" then
            if self:IsStopped(token) then return false end
            hum:UnequipTools()
            if not self:Sleep(0.10, token) then return false end
            hum:EquipTool(item)
            if not self:Sleep(0.20, token) then return false end
            return true
        end
    end
    return false
end

function AutoFarm:StartWalkGuard()
    if not self.walkGuard or self.walkConn then return end
    self.walkConn = TrackConnection(RS.Heartbeat:Connect(function()
        if not IsAlive() then self:StopWalkGuard(); return end
        local _, _, hum = self:GetChar()
        if hum then
            if hum.WalkSpeed < self.targetSpeed - 0.5 then
                hum.WalkSpeed = self.targetSpeed
            end
            if hum.JumpPower < 50 then
                hum.JumpPower = 50
            end
            if hum.JumpHeight < 7.2 then
                hum.JumpHeight = 7.2
            end
        end
    end))
end

function AutoFarm:StopWalkGuard()
    if self.walkConn then
        self.walkConn:Disconnect()
        self.walkConn = nil
    end
end

function AutoFarm:PickSpot()
    local _, hrp = self:GetChar()
    if not hrp then return nil end
    local px, pz = hrp.Position.X, hrp.Position.Z
    local best, bestD, bestName = nil, math.huge, nil
    for _, spot in ipairs(self.spots) do
        local dx = spot.cf.X - px
        local dz = spot.cf.Z - pz
        local dist = math.sqrt(dx * dx + dz * dz)
        if dist < bestD then
            best, bestD, bestName = spot.cf, dist, spot.name
        end
    end
    return best, bestD, bestName
end

function AutoFarm:FindDigCFrame(baseCFrame)
    local originPos = baseCFrame.Position
    local params = RaycastParams.new()
    local char = LP.Character
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = char and {char} or {}
    -- expanded offset grid, sorted closest-first so we land on the most central tile
    local offsets = {
        Vector3.new(0, 0, 0),
        Vector3.new(3, 0, 0),  Vector3.new(-3, 0, 0),  Vector3.new(0, 0, 3),  Vector3.new(0, 0, -3),
        Vector3.new(5, 0, 5),  Vector3.new(-5, 0, 5),  Vector3.new(5, 0, -5), Vector3.new(-5, 0, -5),
        Vector3.new(8, 0, 0),  Vector3.new(-8, 0, 0),  Vector3.new(0, 0, 8),  Vector3.new(0, 0, -8),
        Vector3.new(11, 0, 0), Vector3.new(-11, 0, 0), Vector3.new(0, 0, 11), Vector3.new(0, 0, -11),
    }
    for _, off in ipairs(offsets) do
        local castFrom = originPos + off + Vector3.new(0, 30, 0)
        -- shorter raycast (60 studs) so we don't accept sand 80+ studs below — that
        -- usually means we're above a wrong layer and the server will reject the dig
        local hit = workspace:Raycast(castFrom, Vector3.new(0, -60, 0), params)
        if hit and (hit.Material == Enum.Material.Sand or hit.Material == Enum.Material.Salt) then
            -- 2.5 studs ≈ humanoid stand height; the server's own raycast from HRP
            -- downward looks for sand within a small range, so being 3.2+ studs
            -- above the surface frequently fires "No sand to dig in here!"
            local pos = hit.Position + Vector3.new(0, 2.5, 0)
            return CFrame.new(pos, pos + baseCFrame.LookVector), tostring(hit.Material)
        end
    end
    return nil, "no_sand"
end

function AutoFarm:ScheduleClick()
    local qte = self:GetQTE()
    if not qte or not qte.packets or not qte.packets.Click then return end
    local st = self.state
    if not st.barSpeed or st.barSpeed == 0 then return end
    st.cancelToken += 1
    local token = st.cancelToken
    local now = workspace:GetServerTimeNow()
    local elapsed = now - st.swapTime
    local currentLine = (st.swapStartLine + st.barSpeed * elapsed) % 360
    local raw
    if st.barSpeed >= 0 then
        raw = (st.barRotation - currentLine) % 360
    else
        raw = -((currentLine - st.barRotation) % 360)
    end
    if math.abs(raw) < 0.5 then
        raw = (st.barSpeed >= 0) and (raw + 360) or (raw - 360)
    end
    local delay = math.max(0, raw / st.barSpeed + self.perfectOffset)
    task.spawn(function()
        if not RuntimeWait(delay) then return end
        if st.cancelToken ~= token or not st.active or self:IsStopped(self.runToken) then return end
        pcall(function()
            qte.packets.Click.send({swapId = st.swapId, clickTime = workspace:GetServerTimeNow()})
        end)
    end)
end

function AutoFarm:InstallQTE()
    if self.listeners then return self:GetQTE() ~= nil end
    local qte = self:GetQTE()
    if not qte then return false end
    self.listeners = true
    qte.packets.BarSwap.listen(function(packet)
        local st = self.state
        if not st.active then return end
        st.swapId = packet.swapId
        st.swapTime = packet.swapTime
        st.swapStartLine = packet.swapStartLine
        st.barSpeed = packet.barSpeed
        st.barRotation = packet.barRotation
        self:ScheduleClick()
    end)
    if qte.packets.ClickResult then
        qte.packets.ClickResult.listen(function(packet)
            if self.debug then
                print(("[AutoFarm] click status=%s progress=%s"):format(tostring(packet.status), tostring(packet.progress)))
            end
        end)
    end
    qte.packets.FinishQTE.listen(function(packet)
        local st = self.state
        st.active = false
        st.cancelToken += 1
        if self.debug then
            print(("[AutoFarm] finish success=%s"):format(tostring(packet.success)))
        end
        st.finishedEvt:Fire()
    end)
    return true
end

function AutoFarm:StartQTEAt(targetCFrame, token)
    local qte = self:GetQTE()
    if not qte then return nil end
    if self:IsStopped(token) then return nil end
    local got, data = false, nil
    local ok = GhostTP.Run(targetCFrame, function()
        if self:IsStopped(token) then return end
        pcall(function()
            if qte.packets.CancelQTE then
                qte.packets.CancelQTE.send()
            end
        end)
        if not self:Sleep(0.03, token) then return end
        task.spawn(function()
            if self:IsStopped(token) then
                got = true
                return
            end
            local invokeOk, result = pcall(function()
                return qte.queries.StartQTE.invoke()
            end)
            data = invokeOk and result or nil
            got = true
        end)
    end, {
        arrivalDelay = self.replDelay,
        hold = self.invokeLead,
        returnBack = true,
        double = self.doubleTP,
        doubleDelay = self.doubleDelay,
        decoy = false,  -- decoy was the main source of the "after 3-4 digs char goes invisible / teleports back-and-forth" issue; removing it simplifies the lifecycle
        cameraMode = "hard",
        compensateMove = self.compensateMove,
        maxCompensate = self.maxCompensate,
        abort = function() return self:IsStopped(token) end,
    })
    if not ok then return nil end
    local timeout = os.clock() + 5
    while not self:IsStopped(token) and not got and os.clock() < timeout do
        if not self:Sleep(0.03, token) then return nil end
    end
    if self:IsStopped(token) then return nil end
    return data
end

-- Force-clears any leftover transparency from a glitched previous iteration
-- so the character self-heals before each dig. Cheap (~10 parts) and robust.
function AutoFarm:_ForceVisible()
    local char = LP.Character
    if not char then return end
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("BasePart") then
            if obj.LocalTransparencyModifier > 0 then
                pcall(function() obj.LocalTransparencyModifier = 0 end)
            end
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            -- decals don't generally need restoring (they have their own original transparency)
            -- skip to avoid clobbering legitimate semi-transparent decals
        end
    end
end

function AutoFarm:OneDig(token)
    if self:IsStopped(token) then return false end
    if not self:InstallQTE() then
        Hub:Notify("auto farm", "QTE network not found", "error", 3)
        return false
    end
    if self:IsStopped(token) then return false end
    -- defensive: force character visible at the start of every iteration so any
    -- accumulated bug state from a previous glitched dig self-heals
    self:_ForceVisible()
    if not self:EnsureTool(token) then
        if self.debug then warn("[AutoFarm] equipment tool not found") end
        return false
    end
    local cf, dist, name = self:PickSpot()
    if not cf then return false end
    local digCF, src = self:FindDigCFrame(cf)
    if not digCF then
        -- no sand found near the picked spot; back off briefly so we don't spam bad TPs
        if self.debug then warn("[AutoFarm] no sand near", name) end
        self:Sleep(self.failDelay, token)
        return false
    end
    if self.debug then
        print(("[AutoFarm] ghost tp -> %s (%.0f) via %s"):format(name, dist, src))
    end
    local data = self:StartQTEAt(digCF, token)
    if type(data) ~= "table" or data.swapId == nil then
        if self.debug then warn("[AutoFarm] StartQTE refused") end
        return false
    end
    local st = self.state
    st.active = true
    st.swapId = data.swapId
    st.swapTime = data.swapTime
    st.swapStartLine = data.swapStartLine
    st.barSpeed = data.barSpeed
    st.barRotation = data.barRotation
    self:ScheduleClick()
    local finished = false
    local conn = st.finishedEvt.Event:Connect(function()
        finished = true
    end)
    local timeout = os.clock() + 18
    while not self:IsStopped(token) and st.active and not finished and os.clock() < timeout do
        if not self:Sleep(0.05, token) then break end
    end
    if conn then conn:Disconnect() end
    st.active = false
    st.cancelToken += 1
    return finished and not self:IsStopped(token)
end

function AutoFarm:Start()
    if not IsAlive() then return end
    if self.loopRunning then
        if self.enabled then
            self:StartWalkGuard()
            return
        end
        self.loopRunning = false
    end
    self.enabled = true
    pcall(function()
        if syn and syn.set_thread_identity then syn.set_thread_identity(8) end
        if setsimulationradius then setsimulationradius(1000, 1000) end
        if sethiddenproperty then pcall(sethiddenproperty, LP, "SimulationRadius", 1000) end
    end)
    self.runToken += 1
    local token = self.runToken
    self.loopRunning = true
    self:StartWalkGuard()
    Hub:Notify("auto farm", "started", "success", 2)
    task.spawn(function()
        while not self:IsStopped(token) do
            local ok, result = pcall(function()
                return self:OneDig(token)
            end)
            if not ok then
                warn("[AutoFarm] error:", result)
                GhostTP.Restore()
                if not self:Sleep(self.failDelay, token) then break end
            elseif result then
                if not self:Sleep(self.restartDelay, token) then break end
            else
                if not self:Sleep(self.failDelay, token) then break end
            end
        end
        if token == self.runToken then
            self.enabled = false
            self.state.active = false
            self.state.cancelToken += 1
            self.loopRunning = false
            self:StopWalkGuard()
            GhostTP.Restore()
            Hub:Notify("auto farm", "stopped", "info", 2)
        end
    end)
end

function AutoFarm:Stop()
    self.enabled = false
    self.runToken += 1
    self.loopRunning = false
    self.state.active = false
    self.state.cancelToken += 1
    pcall(function() self.state.finishedEvt:Fire() end)
    local qte = self:GetQTE()
    if qte and qte.packets and qte.packets.CancelQTE then
        pcall(function() qte.packets.CancelQTE.send() end)
    end
    GhostTP.Restore()
    self:StopWalkGuard()
    self:_ForceVisible()
end

function AutoFarm:Diag()
    local _, hrp, hum = self:GetChar()
    if not hrp then return end
    print("=== AutoFarm Diag ===")
    print(("HRP: %.2f, %.2f, %.2f"):format(hrp.Position.X, hrp.Position.Y, hrp.Position.Z))
    print("Floor:", hum and tostring(hum.FloorMaterial) or "?")
    local px, pz = hrp.Position.X, hrp.Position.Z
    for _, spot in ipairs(self.spots) do
        local dx = spot.cf.X - px
        local dz = spot.cf.Z - pz
        print(("%-22s %.0f studs"):format(spot.name, math.sqrt(dx * dx + dz * dz)))
    end
    local _, dist, name = self:PickSpot()
    print(("Nearest: %s @ %.0f"):format(name or "?", dist or 0))
    print("=====================")
end

local AutoSell = {
    enabled = false,
    debug = false,
    interval = 25.00,
    failDelay = 1.00,
    minWorth = 1,
    equipDelay = 0.12,
    sellDelay = 0.25,
    confirmDelay = 0.45,
    sellVerifyDelay = 1.25,
    useSellItemsAnywhere = false,
    useHeldSellLoop = false,
    fallbackZoneSellAll = true,
    zoneAssist = true,
    zoneTeleportAssist = true,
    zoneScale = 10,
    zoneSettleDelay = 0.04,
    zoneRestoreDelay = 0.00,
    merchant = nil,
    byteNetIds = nil,
    loopRunning = false,
    runToken = 0,
}

function AutoSell:IsStopped(token)
    return not IsAlive() or (token ~= nil and (not self.enabled or token ~= self.runToken))
end

function AutoSell:Sleep(seconds, token)
    local deadline = os.clock() + math.max(0, seconds or 0)
    while not self:IsStopped(token) and os.clock() < deadline do
        task.wait(math.min(0.05, deadline - os.clock()))
    end
    return not self:IsStopped(token)
end

function AutoSell:GetMerchant()
    if self.merchant then return self.merchant end
    local ok, network = pcall(function()
        return require(RPS:WaitForChild("Modules"):WaitForChild("Communication"):WaitForChild("Network"))
    end)
    if ok and network and network.Merchant and network.Merchant.queries and network.Merchant.packets then
        self.merchant = network.Merchant
        return self.merchant
    end
    return nil
end

function AutoSell:GetByteNetIds(fresh)
    if fresh then self.byteNetIds = nil end
    if self.byteNetIds then return self.byteNetIds end
    local storage = RPS:FindFirstChild("BytenetStorage") or RPS:WaitForChild("BytenetStorage", 5)
    local value = storage and storage:FindFirstChild("Merchant")
    if not value or not value:IsA("StringValue") or value.Value == "" then return nil end
    local ok, decoded = pcall(function()
        return HS:JSONDecode(value.Value)
    end)
    if not ok or type(decoded) ~= "table" then return nil end
    self.byteNetIds = decoded
    return decoded
end

function AutoSell:GetMerchantStorageRaw()
    local storage = RPS:FindFirstChild("BytenetStorage")
    local value = storage and storage:FindFirstChild("Merchant")
    if not value or not value:IsA("StringValue") then return nil end
    return value.Value
end

function AutoSell:MakeByteNetSnapshot(label)
    local raw = self:GetMerchantStorageRaw()
    local decoded = nil
    if raw and raw ~= "" then
        local ok, result = pcall(function()
            return HS:JSONDecode(raw)
        end)
        if ok and type(result) == "table" then
            decoded = result
        end
    end
    return {
        label = label,
        raw = raw,
        ids = decoded,
        allWorth = decoded and decoded.queries and decoded.queries.AllWorth or nil,
        sell = decoded and decoded.queries and decoded.queries.Sell or nil,
        sellAll = decoded and decoded.packets and decoded.packets.SellAll or nil,
    }
end

function AutoSell:PrintIdGroup(name, group)
    print(name .. ":")
    if type(group) ~= "table" then
        print("  nil")
        return
    end
    local keys = {}
    for key in pairs(group) do
        table.insert(keys, key)
    end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    for _, key in ipairs(keys) do
        print(("  %s = %s"):format(key, tostring(group[key])))
    end
end

function AutoSell:PrintBufferInfo(name, id)
    local buff = self:MakeIdBuffer(id)
    if not buff then
        print(name .. " buffer:", "nil", "id:", tostring(id))
        return
    end
    local len = type(buffer) == "table" and type(buffer.len) == "function" and buffer.len(buff) or nil
    local first = type(buffer) == "table" and type(buffer.readu8) == "function" and buffer.readu8(buff, 0) or nil
    print(name .. " buffer:", "typeof=" .. tostring(typeof(buff)), "len=" .. tostring(len), "firstByte=" .. tostring(first), "id=" .. tostring(id))
end

function AutoSell:PrintByteNetSnapshot(snapshot)
    print("--- ByteNet Merchant snapshot:", snapshot and snapshot.label or "nil", "---")
    if not snapshot or not snapshot.raw then
        print("Merchant.Value:", "nil")
        return
    end
    print("Merchant.Value length:", #snapshot.raw)
    print("Merchant.Value head:", snapshot.raw:sub(1, 180))
    print("Merchant.Value tail:", snapshot.raw:sub(math.max(1, #snapshot.raw - 179), #snapshot.raw))
    print("IDs summary:", "AllWorth=" .. tostring(snapshot.allWorth), "Sell=" .. tostring(snapshot.sell), "SellAll=" .. tostring(snapshot.sellAll))
    self:PrintIdGroup("queries", snapshot.ids and snapshot.ids.queries)
    self:PrintIdGroup("packets", snapshot.ids and snapshot.ids.packets)
    self:PrintBufferInfo("AllWorth", snapshot.allWorth)
    self:PrintBufferInfo("Sell", snapshot.sell)
    self:PrintBufferInfo("SellAll", snapshot.sellAll)
end

function AutoSell:PrintByteNetSnapshotDiff(beforeSnapshot, afterSnapshot)
    print("--- ByteNet Merchant diff ---")
    local changed = beforeSnapshot and afterSnapshot and beforeSnapshot.raw ~= afterSnapshot.raw
    print("Merchant.Value changed:", tostring(changed))
    print("AllWorth changed:", tostring(beforeSnapshot and afterSnapshot and beforeSnapshot.allWorth ~= afterSnapshot.allWorth), tostring(beforeSnapshot and beforeSnapshot.allWorth), "->", tostring(afterSnapshot and afterSnapshot.allWorth))
    print("Sell changed:", tostring(beforeSnapshot and afterSnapshot and beforeSnapshot.sell ~= afterSnapshot.sell), tostring(beforeSnapshot and beforeSnapshot.sell), "->", tostring(afterSnapshot and afterSnapshot.sell))
    print("SellAll changed:", tostring(beforeSnapshot and afterSnapshot and beforeSnapshot.sellAll ~= afterSnapshot.sellAll), tostring(beforeSnapshot and beforeSnapshot.sellAll), "->", tostring(afterSnapshot and afterSnapshot.sellAll))
    if changed == false then
        print("Merchant dynamic suffix:", "not detected; IDs are stable in Merchant namespace")
    end
end

function AutoSell:FormatIdGroup(group)
    if type(group) ~= "table" then return "nil" end
    local keys = {}
    for key in pairs(group) do
        table.insert(keys, key)
    end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    local parts = {}
    for _, key in ipairs(keys) do
        table.insert(parts, ("%s=%s"):format(tostring(key), tostring(group[key])))
    end
    local text = table.concat(parts, ", ")
    if #text > 900 then
        text = text:sub(1, 900) .. "..."
    end
    return text
end

function AutoSell:IsLikelySellStateNamespace(name, decoded)
    local lower = tostring(name):lower()
    if lower:find("merchant", 1, true) or lower:find("dialog", 1, true) or lower:find("interact", 1, true) or lower:find("npc", 1, true) or lower:find("prompt", 1, true) or lower:find("talk", 1, true) or lower:find("proximity", 1, true) then
        return true
    end
    for _, groupName in ipairs({"queries", "packets"}) do
        local group = decoded and decoded[groupName]
        if type(group) == "table" then
            for key in pairs(group) do
                local item = tostring(key):lower()
                if item:find("merchant", 1, true) or item:find("dialog", 1, true) or item:find("interact", 1, true) or item:find("npc", 1, true) or item:find("prompt", 1, true) or item:find("talk", 1, true) or item:find("sell", 1, true) then
                    return true
                end
            end
        end
    end
    return false
end

function AutoSell:PrintAllByteNetStorage()
    local storage = RPS:FindFirstChild("BytenetStorage")
    print("--- ByteNetStorage namespaces ---")
    if not storage then
        print("BytenetStorage:", "nil")
        return
    end
    local values = {}
    for _, child in ipairs(storage:GetChildren()) do
        if child:IsA("StringValue") then
            table.insert(values, child)
        end
    end
    table.sort(values, function(a, b) return a.Name < b.Name end)
    print("StringValue count:", #values)
    for _, value in ipairs(values) do
        local raw = value.Value or ""
        local decoded = nil
        local ok = false
        if raw ~= "" then
            ok, decoded = pcall(function()
                return HS:JSONDecode(raw)
            end)
        end
        if not ok or type(decoded) ~= "table" then
            print(("namespace %s len=%d decode=false"):format(value.Name, #raw))
        else
            local likely = self:IsLikelySellStateNamespace(value.Name, decoded)
            print(("namespace %s len=%d likelySellState=%s"):format(value.Name, #raw, tostring(likely)))
            print("  queries:", self:FormatIdGroup(decoded.queries))
            print("  packets:", self:FormatIdGroup(decoded.packets))
            if likely then
                print("  head:", raw:sub(1, 220))
                print("  tail:", raw:sub(math.max(1, #raw - 219), #raw))
            end
        end
    end
end

function AutoSell:FindChildLoose(parent, name)
    if not parent then return nil end
    local direct = parent:FindFirstChild(name)
    if direct then return direct end
    local want = tostring(name):lower()
    for _, child in ipairs(parent:GetChildren()) do
        if child.Name:lower() == want then
            return child
        end
    end
    return nil
end

function AutoSell:GetMerchantZone()
    local npcs = self:FindChildLoose(workspace, "NPCs") or self:FindChildLoose(workspace, "NPCS")
    local zones = self:FindChildLoose(npcs, "Zones")
    local candidates = {}
    local zoneMerchant = self:FindChildLoose(zones, "Merchant")
    local npcMerchant = self:FindChildLoose(npcs, "Merchant")
    local workspaceMerchant = self:FindChildLoose(workspace, "Merchant")
    if zoneMerchant then table.insert(candidates, zoneMerchant) end
    if npcMerchant then table.insert(candidates, npcMerchant) end
    if workspaceMerchant then table.insert(candidates, workspaceMerchant) end
    for _, merchant in ipairs(candidates) do
        if merchant then
            local zone = merchant:FindFirstChild("Zone")
            if zone and zone:IsA("BasePart") then return zone end
            for _, inst in ipairs(merchant:GetDescendants()) do
                if inst.Name == "Zone" and inst:IsA("BasePart") then
                    return inst
                end
            end
        end
    end
    local best = nil
    for _, inst in ipairs(workspace:GetDescendants()) do
        if inst:IsA("BasePart") and inst.Name:lower() == "zone" then
            local parent = inst.Parent
            local grand = parent and parent.Parent
            local path = inst:GetFullName():lower()
            if (parent and parent.Name:lower():find("merchant", 1, true)) or (grand and grand.Name:lower():find("merchant", 1, true)) or path:find("merchant", 1, true) then
                best = inst
                break
            end
        end
    end
    if best then return best end
    return nil
end

function AutoSell:GetRootPart()
    local char = LP.Character
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
end

function AutoSell:PrepareMerchantZone()
    if not self.zoneAssist then return nil end
    local zone = self:GetMerchantZone()
    local root = self:GetRootPart()
    if not zone or not root then return nil end
    local state = {
        zone = zone,
        cframe = zone.CFrame,
        size = zone.Size,
        canCollide = zone.CanCollide,
        canTouch = zone.CanTouch,
        canQuery = zone.CanQuery,
        transparency = zone.Transparency,
        root = root,
        rootCFrame = root.CFrame,
        rootAnchored = root.Anchored,
        teleported = false,
    }
    local scale = math.max(1, tonumber(self.zoneScale) or 10)
    local size = zone.Size * scale
    size = Vector3.new(math.max(size.X, 300), math.max(size.Y, 180), math.max(size.Z, 300))
    pcall(function()
        if self.zoneTeleportAssist then
            root.CFrame = zone.CFrame + Vector3.new(0, math.min(4, math.max(0, zone.Size.Y * 0.25)), 0)
            state.teleported = true
        else
            zone.CFrame = CFrame.new(root.Position)
        end
        zone.Size = size
        zone.CanCollide = false
        zone.CanTouch = true
        zone.CanQuery = true
    end)
    if self.debug then
        print(("[AutoSell] Merchant zone assist path=%s size=%s root=%s teleport=%s"):format(zone:GetFullName(), tostring(size), tostring(root.Position), tostring(state.teleported)))
    end
    return state
end

function AutoSell:RunInMerchantZone(callback, token)
    local zone = self:GetMerchantZone()
    if not zone then return false, "zone missing" end
    local target = zone.CFrame + Vector3.new(0, math.min(4, math.max(0, zone.Size.Y * 0.25)), 0)
    local ok, result = GhostTP.Run(target, function()
        if self:IsStopped(token) then return false end
        if type(callback) == "function" then
            return callback()
        end
        return true
    end, {
        arrivalDelay = self.zoneSettleDelay,
        hold = self.zoneRestoreDelay,
        returnBack = true,
        double = false,
        decoy = true,
        cameraMode = "hard",
        compensateMove = false,
        abort = function() return self:IsStopped(token) end,
    })
    return ok, result
end

function AutoSell:RestoreMerchantZone(state)
    if not state then return end
    pcall(function()
        if state.teleported and state.root and state.root.Parent then
            state.root.CFrame = state.rootCFrame
            state.root.Anchored = state.rootAnchored
        end
        if not state.zone or not state.zone.Parent then return end
        state.zone.CFrame = state.cframe
        state.zone.Size = state.size
        state.zone.CanCollide = state.canCollide
        state.zone.CanTouch = state.canTouch
        state.zone.CanQuery = state.canQuery
        state.zone.Transparency = state.transparency
    end)
end

function AutoSell:PrintMerchantZoneInfo()
    local zone = self:GetMerchantZone()
    local root = self:GetRootPart()
    print("--- Merchant Zone ---")
    if not zone then
        print("Merchant.Zone:", "nil")
        local printed = 0
        for _, inst in ipairs(workspace:GetDescendants()) do
            if inst:IsA("BasePart") and inst.Name:lower():find("zone", 1, true) then
                printed += 1
                print("Zone candidate:", inst:GetFullName(), "Parent:", inst.Parent and inst.Parent.Name or "nil")
                if printed >= 20 then
                    print("Zone candidate list truncated")
                    break
                end
            end
        end
        return
    end
    local inside = false
    local distance = nil
    if root then
        local localPos = zone.CFrame:PointToObjectSpace(root.Position)
        inside = math.abs(localPos.X) <= zone.Size.X * 0.5 and math.abs(localPos.Y) <= zone.Size.Y * 0.5 and math.abs(localPos.Z) <= zone.Size.Z * 0.5
        distance = (root.Position - zone.Position).Magnitude
    end
    print("Path:", zone:GetFullName())
    print("Size:", tostring(zone.Size), "Position:", tostring(zone.Position))
    print("CanTouch:", tostring(zone.CanTouch), "CanQuery:", tostring(zone.CanQuery), "CanCollide:", tostring(zone.CanCollide), "Transparency:", tostring(zone.Transparency))
    print("Root inside zone:", tostring(inside), "Distance:", tostring(distance))
    print("Zone assist:", tostring(self.zoneAssist), "TeleportAssist:", tostring(self.zoneTeleportAssist), "Scale:", tostring(self.zoneScale), "SettleDelay:", tostring(self.zoneSettleDelay), "RestoreDelay:", tostring(self.zoneRestoreDelay))
end

function AutoSell:MakeIdBuffer(id)
    if type(buffer) ~= "table" or type(buffer.create) ~= "function" or type(buffer.writeu8) ~= "function" then return nil end
    id = tonumber(id)
    if not id then return nil end
    local buff = buffer.create(1)
    buffer.writeu8(buff, 0, id)
    return buff
end

function AutoSell:ReadInt32Response(buff, expectedId)
    if type(buffer) ~= "table" or typeof(buff) ~= "buffer" then return nil end
    local ok, value = pcall(function()
        if buffer.len(buff) < 5 then return nil end
        local responseId = buffer.readu8(buff, 0)
        if expectedId and responseId ~= expectedId then return nil end
        return buffer.readi32(buff, 1)
    end)
    if ok then return value end
    return nil
end

function AutoSell:RawQuery(queryName)
    local ids = self:GetByteNetIds(true)
    local queryId = ids and ids.queries and ids.queries[queryName]
    local buff = self:MakeIdBuffer(queryId)
    local remote = RPS:FindFirstChild("ByteNetQuery")
    if not queryId or not buff or not remote then return false, nil, queryId end
    local ok, resultBuff = pcall(function()
        local dumpBuffer = remote:InvokeServer(buff, nil, queryId)
        return dumpBuffer
    end)
    if not ok then return false, nil, queryId end
    return true, self:ReadInt32Response(resultBuff, queryId), queryId
end

function AutoSell:RawInvoke(queryName)
    local ids = self:GetByteNetIds(true)
    local queryId = ids and ids.queries and ids.queries[queryName]
    local buff = self:MakeIdBuffer(queryId)
    local remote = RPS:FindFirstChild("ByteNetQuery")
    if not queryId or not buff or not remote then return false, nil, queryId end
    local ok, resultBuff = pcall(function()
        return remote:InvokeServer(buff, nil, queryId)
    end)
    return ok, resultBuff, queryId
end

function AutoSell:WrapperQuery(queryName)
    local merchant = self:GetMerchant()
    local query = merchant and merchant.queries and merchant.queries[queryName]
    if not query or type(query.invoke) ~= "function" then return false, nil end
    local ok, result = pcall(function()
        return query.invoke()
    end)
    return ok, result
end

function AutoSell:RawReliable(packetName)
    local ids = self:GetByteNetIds(true)
    local packetId = ids and ids.packets and ids.packets[packetName]
    local buff = self:MakeIdBuffer(packetId)
    local remote = RPS:FindFirstChild("ByteNetReliable")
    if not packetId or not buff or not remote then return false, packetId end
    local ok = pcall(function()
        remote:FireServer(buff, nil)
    end)
    return ok, packetId
end

function AutoSell:WrapperReliable(packetName)
    local merchant = self:GetMerchant()
    local packet = merchant and merchant.packets and merchant.packets[packetName]
    if not packet or type(packet.send) ~= "function" then return false end
    return pcall(function()
        packet.send()
    end)
end

function AutoSell:SpyStyleQuery(queryName)
    local ids = self:GetByteNetIds(true)
    local queryId = ids and ids.queries and ids.queries[queryName]
    local remote = RPS:FindFirstChild("ByteNetQuery")
    if not queryId or not remote then return false, nil, queryId end
    local ok, result = pcall(function()
        return remote:InvokeServer(nil, nil, queryId)
    end)
    return ok, result, queryId
end

function AutoSell:SpyStyleReliable()
    local remote = RPS:FindFirstChild("ByteNetReliable")
    if not remote then return false end
    return pcall(function()
        remote:FireServer(nil)
    end)
end

function AutoSell:GetWorth()
    local rawOk, rawWorth = self:RawQuery("AllWorth")
    if rawOk and rawWorth ~= nil then
        return rawWorth
    end
    local merchant = self:GetMerchant()
    if not merchant or not merchant.queries then return nil end
    local query = merchant.queries.AllWorth
    if not query or type(query.invoke) ~= "function" then return nil end
    local ok, result = pcall(function()
        return query.invoke()
    end)
    if not ok then return nil end
    return tonumber(result) or result
end

function AutoSell:PromptSellAll()
    local spyOk, spyWorth = self:SpyStyleQuery("AllWorth")
    local rawOk, rawWorth, rawQueryId = self:RawQuery("AllWorth")
    local wrapperOk, wrapperWorth = self:WrapperQuery("AllWorth")
    local worth = tonumber(wrapperWorth) or tonumber(rawWorth) or tonumber(spyWorth) or wrapperWorth or rawWorth or spyWorth
    return (rawOk or wrapperOk or spyOk), worth, rawQueryId, rawOk, wrapperOk, spyOk
end

function AutoSell:ConfirmSellAll()
    local spyOk = self:SpyStyleReliable()
    local rawOk, packetId = self:RawReliable("SellAll")
    local wrapperOk = self:WrapperReliable("SellAll")
    return (rawOk or wrapperOk or spyOk), packetId, rawOk, wrapperOk, spyOk
end

function AutoSell:SendSellItemsAnywhere(items)
    if type(items) ~= "table" or #items <= 0 then return false end
    local merchant = self:GetMerchant()
    local packet = merchant and merchant.packets and merchant.packets.SellItemsAnywhere
    if not packet or type(packet.send) ~= "function" then return false end
    return pcall(function()
        packet.send({
            Items = items,
        })
    end)
end

function AutoSell:IsSellableTool(tool)
    if not tool or not tool:IsA("Tool") then return false end
    if tool:GetAttribute("Draggable") == false then return false end
    if tool:GetAttribute("Favourite") == true then return false end
    if tool:GetAttribute("Type") ~= "Item" then return false end
    return true
end

function AutoSell:GetSellItems()
    local items = {}
    local char = LP.Character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if self:IsSellableTool(item) then
                table.insert(items, item)
            end
        end
    end
    local backpack = LP:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if self:IsSellableTool(item) then
                table.insert(items, item)
            end
        end
    end
    return items
end

function AutoSell:SellItemsAnywhereOnce(token)
    if self:IsStopped(token) then return false end
    local items = self:GetSellItems()
    if #items <= 0 then return false end
    local beforeWorth = self:GetWorth()
    if type(beforeWorth) == "number" and beforeWorth < self.minWorth then
        if self.debug then print(("[AutoSell] SellItemsAnywhere skipped worth=%s items=%d"):format(tostring(beforeWorth), #items)) end
        return false
    end
    local ok = self:SendSellItemsAnywhere(items)
    if not ok then return false end
    if not self:Sleep(self.sellVerifyDelay, token) then return false end
    local afterWorth = self:GetWorth()
    local changed = beforeWorth ~= nil and afterWorth ~= nil and beforeWorth ~= afterWorth
    if self.debug then
        print(("[AutoSell] SellItemsAnywhere fired ok=%s before=%s after=%s changed=%s items=%d"):format(tostring(ok), tostring(beforeWorth), tostring(afterWorth), tostring(changed), #items))
    end
    return changed
end

function AutoSell:EquipSellTool(tool, token)
    if self:IsStopped(token) or not self:IsSellableTool(tool) then return false end
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    pcall(function()
        hum:UnequipTools()
    end)
    if not self:Sleep(self.equipDelay, token) then return false end
    if not tool.Parent then return false end
    local ok = pcall(function()
        hum:EquipTool(tool)
    end)
    if not ok then return false end
    return self:Sleep(self.equipDelay, token)
end

function AutoSell:SellHeldViaQuery()
    local ok, result = self:WrapperQuery("Sell")
    if ok then return true, result, "wrapper" end
    local rawOk, rawResult, queryId = self:RawInvoke("Sell")
    return rawOk, rawResult, "raw:" .. tostring(queryId)
end

function AutoSell:SellHeldLoopOnce(token)
    if self:IsStopped(token) then return false, 0, nil, nil end
    local items = self:GetSellItems()
    if #items <= 0 then return false, 0, nil, nil end
    local beforeWorth = self:GetWorth()
    if type(beforeWorth) == "number" and beforeWorth < self.minWorth then
        return false, 0, beforeWorth, beforeWorth
    end
    local sold = 0
    for _, item in ipairs(items) do
        if self:IsStopped(token) then break end
        if self:IsSellableTool(item) and self:EquipSellTool(item, token) then
            local ok, result, path = self:SellHeldViaQuery()
            if self.debug then
                print(("[AutoSell] HeldSell item=%s ok=%s path=%s result=%s"):format(item.Name, tostring(ok), tostring(path), tostring(result)))
            end
            if ok then
                sold += 1
            end
            if not self:Sleep(self.sellDelay, token) then break end
        end
    end
    local afterWorth = self:GetWorth()
    local changed = beforeWorth ~= nil and afterWorth ~= nil and beforeWorth ~= afterWorth
    if self.debug then
        print(("[AutoSell] HeldSellLoop soldCalls=%d before=%s after=%s changed=%s"):format(sold, tostring(beforeWorth), tostring(afterWorth), tostring(changed)))
    end
    return changed, sold, beforeWorth, afterWorth
end

function AutoSell:SellAllOnce(token)
    if self:IsStopped(token) then return false end
    if not self:GetMerchant() and not self:GetByteNetIds() then
        Hub:Notify("auto sell", "merchant network not found", "error", 3)
        return false
    end
    if self.useSellItemsAnywhere then
        local anywhereOk = self:SellItemsAnywhereOnce(token)
        if anywhereOk then
            return anywhereOk
        end
    end
    if self.useHeldSellLoop then
        local heldOk = self:SellHeldLoopOnce(token)
        if heldOk or not self.fallbackZoneSellAll then
            return heldOk
        end
    elseif not self.fallbackZoneSellAll then
        return false
    end
    local flowOk = false
    local runOk = self:RunInMerchantZone(function()
        local promptOk, worth, queryId, rawQueryOk, wrapperQueryOk, spyQueryOk = self:PromptSellAll()
        if self:IsStopped(token) then return false end
        if type(worth) == "number" and worth < self.minWorth then
            if self.debug then print(("[AutoSell] AllWorth query=%s nothing to sell"):format(tostring(queryId))) end
            return false
        end
        if not promptOk then
            Hub:Notify("auto sell", "sell all prompt query failed", "error", 3)
            return false
        end
        if not self:Sleep(self.confirmDelay, token) then return false end
        local confirmOk, packetId, rawOk, wrapperOk, spyOk = self:ConfirmSellAll()
        if not confirmOk then
            Hub:Notify("auto sell", "sell packet not found", "error", 3)
            return false
        end
        if self.debug then
            print(("[AutoSell] SellAll flow query=%s packet=%s worth=%s hiddenBlink=%s spyQuery=%s rawQuery=%s wrapperQuery=%s spyConfirm=%s rawConfirm=%s wrapperConfirm=%s"):format(tostring(queryId), tostring(packetId), tostring(worth), tostring(true), tostring(spyQueryOk), tostring(rawQueryOk), tostring(wrapperQueryOk), tostring(spyOk), tostring(rawOk), tostring(wrapperOk)))
        end
        flowOk = confirmOk
        return confirmOk
    end, token)
    return runOk and flowOk
end

function AutoSell:SellOnce(token)
    if self:IsStopped(token) then return false end
    local char = LP.Character
    local held = char and char:FindFirstChildOfClass("Tool")
    if not self:IsSellableTool(held) then
        Hub:Notify("auto sell", "hold an item to sell once", "info", 3)
        return false
    end
    local ok, result, queryId = self:RawInvoke("Sell")
    if not ok then
        local merchant = self:GetMerchant()
        if merchant and merchant.queries and merchant.queries.Sell and type(merchant.queries.Sell.invoke) == "function" then
            ok, result = pcall(function()
                return merchant.queries.Sell.invoke()
            end)
        end
    end
    if self.debug then
        print(("[AutoSell] Sell held query=%s item=%s ok=%s response=%s"):format(tostring(queryId), held.Name, tostring(ok), tostring(result)))
    end
    return ok
end

function AutoSell:Diag(probeSellAll)
    self.byteNetIds = nil
    local beforeSnapshot = self:MakeByteNetSnapshot("before")
    local merchant = self:GetMerchant()
    local ids = self:GetByteNetIds(true)
    local rawOk = false
    local rawWorth = nil
    local rawQueryId = beforeSnapshot and beforeSnapshot.allWorth or nil
    local worth = nil
    if not probeSellAll then
        rawOk, rawWorth, rawQueryId = self:RawQuery("AllWorth")
        worth = self:GetWorth()
    end
    local items = self:GetSellItems()
    local char = LP.Character
    local held = char and char:FindFirstChildOfClass("Tool")
    local backpack = LP:FindFirstChildOfClass("Backpack")
    local storage = RPS:FindFirstChild("BytenetStorage")
    local merchantValue = storage and storage:FindFirstChild("Merchant")
    local reliable = RPS:FindFirstChild("ByteNetReliable")
    local query = RPS:FindFirstChild("ByteNetQuery")
    local spySellAllPossible = reliable ~= nil
    local rawSellAllPossible = ids ~= nil and ids.packets ~= nil and ids.packets.SellAll ~= nil and reliable ~= nil and type(buffer) == "table"
    local rawSellPossible = ids ~= nil and ids.queries ~= nil and ids.queries.Sell ~= nil and query ~= nil and type(buffer) == "table"
    local wrapperSellAllPossible = merchant ~= nil and merchant.packets ~= nil and merchant.packets.SellAll ~= nil and type(merchant.packets.SellAll.send) == "function"
    local wrapperSellItemsAnywherePossible = merchant ~= nil and merchant.packets ~= nil and merchant.packets.SellItemsAnywhere ~= nil and type(merchant.packets.SellItemsAnywhere.send) == "function"
    local wrapperSellPossible = merchant ~= nil and merchant.queries ~= nil and merchant.queries.Sell ~= nil and type(merchant.queries.Sell.invoke) == "function"
    local rawProbeOk = nil
    local wrapperProbeOk = nil
    local probeAnywhereOk = nil
    local probeUsedAnywhere = false
    local probeHeldOk = nil
    local probeHeldSold = nil
    local probeUsedHeldLoop = false
    local probePromptOk = nil
    local probePromptWorth = nil
    local probeQueryId = nil
    local probeRawQueryOk = nil
    local probeWrapperQueryOk = nil
    local probeSpyQueryOk = nil
    local probePacketId = nil
    local probeSpyConfirmOk = nil
    local probeZoneApplied = nil
    local beforeProbeWorth = worth
    local afterProbeWorth = nil
    local afterSnapshot = nil
    if probeSellAll then
        beforeProbeWorth = self:GetWorth()
        rawOk = beforeProbeWorth ~= nil
        rawWorth = beforeProbeWorth
        worth = beforeProbeWorth
        if self.useSellItemsAnywhere and #items > 0 then
            probeUsedAnywhere = true
            probeAnywhereOk = self:SendSellItemsAnywhere(items)
            task.wait(self.sellVerifyDelay)
            afterProbeWorth = self:GetWorth()
        end
        if self.useHeldSellLoop and #items > 0 and (afterProbeWorth == nil or beforeProbeWorth == afterProbeWorth) then
            probeUsedHeldLoop = true
            local heldBefore = nil
            local heldAfter = nil
            probeHeldOk, probeHeldSold, heldBefore, heldAfter = self:SellHeldLoopOnce()
            if heldBefore ~= nil then beforeProbeWorth = heldBefore end
            if heldAfter ~= nil then afterProbeWorth = heldAfter end
        end
        if (not probeUsedAnywhere or (probeAnywhereOk and beforeProbeWorth == afterProbeWorth) or not probeAnywhereOk) and self.fallbackZoneSellAll then
            local runOk = self:RunInMerchantZone(function()
                probeZoneApplied = true
                probePromptOk, probePromptWorth, probeQueryId, probeRawQueryOk, probeWrapperQueryOk, probeSpyQueryOk = self:PromptSellAll()
                rawOk = probeRawQueryOk
                rawWorth = probePromptWorth
                rawQueryId = probeQueryId
                worth = probePromptWorth
                beforeProbeWorth = probePromptWorth
                task.wait(self.confirmDelay)
                _, probePacketId, rawProbeOk, wrapperProbeOk, probeSpyConfirmOk = self:ConfirmSellAll()
                return true
            end)
            if not runOk then
                probeZoneApplied = false
            end
            task.wait(self.sellVerifyDelay)
            afterProbeWorth = self:GetWorth()
        end
        self.byteNetIds = nil
        afterSnapshot = self:MakeByteNetSnapshot("after")
        if afterProbeWorth == nil then
            afterProbeWorth = self:GetWorth()
        end
    else
        afterSnapshot = self:MakeByteNetSnapshot("current")
    end
    print("=== AutoSell Diag ===")
    print("Enabled:", self.enabled, "LoopRunning:", self.loopRunning, "Interval:", self.interval)
    print("Toggle action:", self.fallbackZoneSellAll and "Merchant.Zone blink -> AllWorth prompt -> SellAll confirm -> return" or "no-teleport chain only")
    print("Button action:", "Sell held item once via Merchant.queries.Sell")
    print("Probe action:", probeSellAll and (self.fallbackZoneSellAll and "ACTIVE: zone blink SellAll probe" or "ACTIVE: no-teleport chain probe") or "inactive")
    print("Merchant:", merchant ~= nil, "Network wrapper loaded:", merchant ~= nil)
    print("BytenetStorage:", storage ~= nil, "Merchant StringValue:", merchantValue ~= nil, "ByteNet Merchant IDs:", ids ~= nil)
    print("ByteNetReliable:", reliable ~= nil, "ByteNetQuery:", query ~= nil, "buffer API:", type(buffer) == "table")
    print("Packet SellAll ID:", ids and ids.packets and tostring(ids.packets.SellAll) or "nil")
    print("Query AllWorth ID:", tostring(rawQueryId))
    print("Query Sell ID:", ids and ids.queries and tostring(ids.queries.Sell) or "nil")
    print("Raw AllWorth:", rawOk, tostring(rawWorth))
    print("ByteNetQuery path:", query and query:GetFullName() or "nil")
    print("ByteNetReliable path:", reliable and reliable:GetFullName() or "nil")
    print("SellItemsAnywhere wrapper:", wrapperSellItemsAnywherePossible, "Use:", tostring(self.useSellItemsAnywhere), "HeldLoop:", tostring(self.useHeldSellLoop), "Fallback zone SellAll:", tostring(self.fallbackZoneSellAll))
    print("SellAll wrapper:", wrapperSellAllPossible)
    print("Sell held wrapper:", wrapperSellPossible)
    print("Spy nil-buffer SellAll possible:", spySellAllPossible)
    print("Raw SellAll possible:", rawSellAllPossible)
    print("Raw Sell held possible:", rawSellPossible)
    print("Worth:", tostring(worth), "MinWorth:", self.minWorth)
    print("Character:", char ~= nil, "Backpack:", backpack ~= nil)
    print("Held:", held and held.Name or "nil", "HeldSellable:", self:IsSellableTool(held))
    print("Items:", #items)
    for i, item in ipairs(items) do
        print(("%d) %s type=%s draggable=%s favourite=%s"):format(i, item.Name, tostring(item:GetAttribute("Type")), tostring(item:GetAttribute("Draggable")), tostring(item:GetAttribute("Favourite"))))
    end
    self:PrintMerchantZoneInfo()
    if probeSellAll then
        print("--- AutoSell probe ---")
        print("BeforeWorth:", tostring(beforeProbeWorth))
        print("SellItemsAnywhere used:", tostring(probeUsedAnywhere), "fired:", tostring(probeAnywhereOk), "packet:", ids and ids.packets and tostring(ids.packets.SellItemsAnywhere) or "nil")
        print("Held Sell loop used:", tostring(probeUsedHeldLoop), "changed:", tostring(probeHeldOk), "soldCalls:", tostring(probeHeldSold))
        print("Zone assist applied:", tostring(probeZoneApplied))
        if probeZoneApplied ~= nil then
            print("Spy query call:", "ByteNetQuery:InvokeServer(nil, nil, " .. tostring(probeQueryId) .. ")")
            print("Spy confirm call:", "ByteNetReliable:FireServer(nil)")
            print("Raw query call:", "ByteNetQuery:InvokeServer(buffer[" .. tostring(probeQueryId) .. "], nil, " .. tostring(probeQueryId) .. ")")
            print("Raw confirm call:", "ByteNetReliable:FireServer(buffer[" .. tostring(probePacketId) .. "], nil)")
            print("Prompt AllWorth ok:", tostring(probePromptOk), "Worth:", tostring(probePromptWorth), "QueryID:", tostring(probeQueryId))
            print("Prompt spy nil-buffer query:", tostring(probeSpyQueryOk))
            print("Prompt raw buffer query:", tostring(probeRawQueryOk), "Prompt wrapper query:", tostring(probeWrapperQueryOk))
            print("Confirm packet ID:", tostring(probePacketId))
            print("Confirm spy nil-buffer SellAll fired:", tostring(probeSpyConfirmOk))
            print("Confirm raw buffer SellAll fired:", tostring(rawProbeOk))
            print("Confirm wrapper SellAll fired:", tostring(wrapperProbeOk))
            print("Confirm delay:", tostring(self.confirmDelay))
        end
        print("AfterWorth:", tostring(afterProbeWorth))
        print("WorthChanged:", tostring(beforeProbeWorth ~= afterProbeWorth))
    end
    self:PrintByteNetSnapshot(beforeSnapshot)
    if probeSellAll then
        self:PrintByteNetSnapshot(afterSnapshot)
        self:PrintByteNetSnapshotDiff(beforeSnapshot, afterSnapshot)
        self:PrintAllByteNetStorage()
    end
    print("--- Possible Problems ---")
    if not merchant then print("PROBLEM: Network.Merchant wrapper did not load") end
    if not ids then print("PROBLEM: BytenetStorage.Merchant IDs missing or JSON decode failed") end
    if not reliable then print("PROBLEM: ByteNetReliable remote missing") end
    if not query then print("PROBLEM: ByteNetQuery remote missing") end
    if type(buffer) ~= "table" then print("PROBLEM: executor does not expose Luau buffer API") end
    if not rawOk and not probeSpyQueryOk then print("PROBLEM: AllWorth raw query failed; query ID/buffer/remote path may be wrong") end
    if type(worth) == "number" and worth < self.minWorth then print("PROBLEM: AllWorth is below MinWorth, SellAll is skipped") end
    if #items <= 0 then print("PROBLEM: no sellable Type=Item tools found in Backpack/Character") end
    if held and not self:IsSellableTool(held) then print("PROBLEM: held tool is not sellable for sell held once") end
    if self.useSellItemsAnywhere and not wrapperSellItemsAnywherePossible then print("PROBLEM: SellItemsAnywhere wrapper path not found") end
    if not self.useSellItemsAnywhere and not spySellAllPossible and not wrapperSellAllPossible and not rawSellAllPossible then print("PROBLEM: no usable SellAll path found") end
    if probeSellAll and probeUsedHeldLoop and probeHeldOk then
        print("OK: held Sell loop processed by server; no teleport needed")
    elseif probeSellAll and probeUsedAnywhere and beforeProbeWorth ~= afterProbeWorth then
        print("OK: SellItemsAnywhere no-teleport packet processed by server; worth changed")
    elseif probeSellAll and probeUsedAnywhere and beforeProbeWorth == afterProbeWorth and type(beforeProbeWorth) == "number" and beforeProbeWorth >= self.minWorth then
        print("LIKELY PROBLEM: SellItemsAnywhere fired but server ignored it; probable missing BuyAnywhere permission/gamepass")
        print("NEXT CHECK: held Sell loop also failed if Held Sell loop changed=false; then only zone SellAll/teleport path is accepted")
    elseif probeSellAll and beforeProbeWorth ~= afterProbeWorth then
        print("OK: SellAll zone fallback processed by server; worth changed")
    elseif probeSellAll and self.fallbackZoneSellAll and not probeZoneApplied then
        print("LIKELY PROBLEM: Merchant.Zone assist did not apply; zone path missing or character root missing")
    elseif probeSellAll and beforeProbeWorth == afterProbeWorth and type(beforeProbeWorth) == "number" and beforeProbeWorth >= self.minWorth then
        print("LIKELY PROBLEM: SellAll event fires but server ignores it; probable missing merchant/NPC/dialog/proximity server state")
        print("NEXT CHECK: if zone assist applied=true, server probably checks real server-side distance or a dialogue/interact packet too")
    elseif merchant and ids and reliable and query and rawOk and type(worth) == "number" and worth >= self.minWorth and #items > 0 then
        print("LIKELY PROBLEM: client data is OK; if AutoSell still does not sell, SellAll probably requires server-side merchant interaction state")
        print("NEXT CHECK: compare WorthChanged with Zone assist applied")
    else
        print("LIKELY PROBLEM: see PROBLEM lines above")
    end
    print("=====================")
end

function AutoSell:Start()
    if not IsAlive() then return end
    if self.loopRunning then
        if self.enabled then return end
        self.loopRunning = false
    end
    self.enabled = true
    self.runToken += 1
    local token = self.runToken
    self.loopRunning = true
    Hub:Notify("auto sell", "started", "success", 2)
    task.spawn(function()
        while not self:IsStopped(token) do
            local ok, result = pcall(function()
                return self:SellAllOnce(token)
            end)
            if not ok then
                warn("[AutoSell] error:", result)
                if not self:Sleep(self.failDelay, token) then break end
            elseif result then
                if not self:Sleep(self.interval, token) then break end
            else
                if not self:Sleep(self.interval, token) then break end
            end
        end
        if token == self.runToken then
            self.enabled = false
            self.loopRunning = false
            Hub:Notify("auto sell", "stopped", "info", 2)
        end
    end)
end

function AutoSell:Stop()
    self.enabled = false
    self.runToken += 1
    self.loopRunning = false
end

if type(getgenv) == "function" then
    getgenv().EminanceAutoFarm = AutoFarm
    getgenv().EminanceAutoSell = AutoSell
end

local HermitCrabAuto = {
    enabled = false,
    debug = true,
    loopRunning = false,
    delay = 0.35,
    flags = {
        Luck = false,
        Speed = false,
        Space = false,
        Weight = false,
        Claim = false,
    },
    statNames = {
        Luck = {"Luck"},
        Speed = {"Speed"},
        Space = {"Space"},
        Weight = {"WeightCap"},
    },
    network = nil,
    byteNetIds = nil,
    claimDelay = 25,
    lastClaim = 0,
}

function HermitCrabAuto:GetNetwork()
    if self.network then return self.network end
    local ok, network = pcall(function()
        return require(RPS:WaitForChild("Modules"):WaitForChild("Communication"):WaitForChild("Network"))
    end)
    if ok and network and network.HermitCrab and network.HermitCrab.queries then
        self.network = network.HermitCrab
        return self.network
    end
    return nil
end

function HermitCrabAuto:GetByteNetIds(fresh)
    if fresh then self.byteNetIds = nil end
    if self.byteNetIds then return self.byteNetIds end
    local storage = RPS:FindFirstChild("BytenetStorage") or RPS:WaitForChild("BytenetStorage", 5)
    local value = storage and storage:FindFirstChild("HermitCrab")
    if not value or not value:IsA("StringValue") or value.Value == "" then return nil end
    local ok, decoded = pcall(function()
        return HS:JSONDecode(value.Value)
    end)
    if not ok or type(decoded) ~= "table" then return nil end
    self.byteNetIds = decoded
    return decoded
end

function HermitCrabAuto:Normalize(value)
    value = tostring(value or ""):lower()
    value = value:gsub("[%s_%-]+", "")
    return value
end

function HermitCrabAuto:GetGuiStatNames()
    local playerGui = LP:FindFirstChild("PlayerGui")
    local hermitGui = playerGui and playerGui:FindFirstChild("HermitCrab")
    local main = hermitGui and hermitGui:FindFirstChild("Main")
    local core = main and main:FindFirstChild("Core")
    local info = core and core:FindFirstChild("InfoFrame")
    local statsPage = info and info:FindFirstChild("Stats")
    local statsFolder = statsPage and statsPage:FindFirstChild("StatsFolder")
    if not statsFolder then return nil end
    local names = {}
    for _, child in ipairs(statsFolder:GetChildren()) do
        if child:IsA("Frame") then
            table.insert(names, child.Name)
        end
    end
    return names
end

function HermitCrabAuto:ResolveStat(candidate)
    if type(candidate) ~= "table" then return candidate end
    local guiNames = self:GetGuiStatNames()
    if guiNames then
        for _, wanted in ipairs(candidate) do
            local wantedKey = self:Normalize(wanted)
            for _, actual in ipairs(guiNames) do
                if self:Normalize(actual) == wantedKey then
                    return actual
                end
            end
        end
    end
    return candidate[1]
end

function HermitCrabAuto:MakeIdBuffer(id)
    if type(buffer) ~= "table" or type(buffer.create) ~= "function" or type(buffer.writeu8) ~= "function" then return nil end
    id = tonumber(id)
    if not id then return nil end
    local buff = buffer.create(1)
    buffer.writeu8(buff, 0, id)
    return buff
end

function HermitCrabAuto:MakeStringQueryBuffer(id, text)
    if type(buffer) ~= "table" or type(buffer.create) ~= "function" or type(buffer.writeu8) ~= "function" then return nil end
    id = tonumber(id)
    text = tostring(text or "")
    if not id then return nil end
    local len = #text
    local buff = buffer.create(3 + len)
    buffer.writeu8(buff, 0, id)
    buffer.writeu8(buff, 1, len % 256)
    buffer.writeu8(buff, 2, math.floor(len / 256) % 256)
    for i = 1, len do
        buffer.writeu8(buff, 2 + i, string.byte(text, i))
    end
    return buff
end

function HermitCrabAuto:BufferInfo(buff)
    if typeof(buff) ~= "buffer" then return "nil" end
    local len = buffer.len(buff)
    local bytes = {}
    for i = 0, math.min(len - 1, 15) do
        table.insert(bytes, tostring(buffer.readu8(buff, i)))
    end
    return ("typeof=buffer len=%d bytes=[%s]"):format(len, table.concat(bytes, ","))
end

function HermitCrabAuto:RawQueryNil(queryName, payload)
    local remote = RPS:FindFirstChild("ByteNetQuery")
    local queryId = type(queryName) == "number" and queryName or self:GetQueryId(queryName)
    if not remote or not queryId then return false, nil, queryId end
    local ok, result = pcall(function()
        return remote:InvokeServer(nil, payload, queryId)
    end)
    return ok, result, queryId
end

function HermitCrabAuto:Diagnostic()
    local storage = RPS:FindFirstChild("BytenetStorage")
    local value = storage and storage:FindFirstChild("HermitCrab")
    local ids = self:GetByteNetIds(true)
    local remote = RPS:FindFirstChild("ByteNetQuery")
    local guiNames = self:GetGuiStatNames()
    local claimId = self:GetQueryId("ClaimAllShells")
    local upgradeId = self:GetQueryId("UpgradeStat")
    local claimBuff = self:MakeIdBuffer(claimId)
    local upgradeBuff = self:MakeIdBuffer(upgradeId)
    print("=== HermitCrab Diagnostic ===")
    print("ByteNetQuery:", remote and remote:GetFullName() or "nil", remote and remote.ClassName or "nil")
    print("BytenetStorage:", storage and storage:GetFullName() or "nil")
    print("HermitCrab StringValue exists:", tostring(value ~= nil), "len:", value and #value.Value or "nil")
    if value and value.Value then
        print("HermitCrab raw head:", value.Value:sub(1, 240))
        print("HermitCrab raw tail:", value.Value:sub(math.max(1, #value.Value - 239), #value.Value))
    end
    print("queries:", self:FormatGroup(ids and ids.queries))
    print("packets:", self:FormatGroup(ids and ids.packets))
    print("GUI stats:", guiNames and table.concat(guiNames, ", ") or "nil")
    print("ClaimAllShells id:", tostring(claimId), "buffer:", self:BufferInfo(claimBuff))
    print("UpgradeStat id:", tostring(upgradeId), "buffer:", self:BufferInfo(upgradeBuff))
    print("Raw claim args nil-buffer:", "ByteNetQuery:InvokeServer(nil, nil, " .. tostring(claimId) .. ")")
    print("Raw upgrade args nil-buffer:", "ByteNetQuery:InvokeServer(nil, STAT_NAME, " .. tostring(upgradeId) .. ")")
    for key, names in pairs(self.statNames) do
        print(("Resolved stat %s -> %s"):format(tostring(key), tostring(self:ResolveStat(names))))
    end
    print("Manual safe-ish claim probe:", "getgenv().EminanceHermitCrabAuto:RawQueryNil(\"ClaimAllShells\", nil)")
    print("Manual upgrade probe:", "getgenv().EminanceHermitCrabAuto:RawQueryNil(\"UpgradeStat\", \"STAT_NAME\")")
    print("==============================")
end

function HermitCrabAuto:GetQueryId(queryName)
    local ids = self:GetByteNetIds(true)
    local dynamicId = ids and ids.queries and ids.queries[queryName]
    if dynamicId then return dynamicId end
    if queryName == "ClaimAllShells" then return 5 end
    if queryName == "UpgradeStat" then return 9 end
    return nil
end

function HermitCrabAuto:FormatGroup(group)
    if type(group) ~= "table" then return "nil" end
    local keys = {}
    for key in pairs(group) do
        table.insert(keys, key)
    end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    local parts = {}
    for _, key in ipairs(keys) do
        table.insert(parts, ("%s=%s"):format(tostring(key), tostring(group[key])))
    end
    return table.concat(parts, ", ")
end

function HermitCrabAuto:PrintByteNetIds()
    local ids = self:GetByteNetIds(true)
    print("=== HermitCrab ByteNet ===")
    print("BytenetStorage.HermitCrab:", ids ~= nil)
    print("queries:", self:FormatGroup(ids and ids.queries))
    print("packets:", self:FormatGroup(ids and ids.packets))
    print("UpgradeStat ID:", tostring(ids and ids.queries and ids.queries.UpgradeStat or 9))
    print("ClaimAllShells ID:", tostring(ids and ids.queries and ids.queries.ClaimAllShells or 5))
    print("===========================")
end

function HermitCrabAuto:AnyEnabled()
    for _, enabled in pairs(self.flags) do
        if enabled then return true end
    end
    return false
end

function HermitCrabAuto:RawQuery(queryName, payload)
    local remote = RPS:FindFirstChild("ByteNetQuery")
    local queryId = type(queryName) == "number" and queryName or self:GetQueryId(queryName)
    if not remote or not queryId then return false, nil, queryId end
    local buff = type(payload) == "string" and self:MakeStringQueryBuffer(queryId, payload) or self:MakeIdBuffer(queryId)
    if buff then
        local ok, result = pcall(function()
            return remote:InvokeServer(buff, nil, queryId)
        end)
        if ok then return true, result, queryId, "buffer" end
    end
    local ok, result = pcall(function()
        return remote:InvokeServer(nil, payload, queryId)
    end)
    return ok, result, queryId, "nil-buffer"
end

function HermitCrabAuto:OpenUI()
    local crab = self:GetNetwork()
    local packet = crab and crab.packets and crab.packets.OpenUI
    if packet and type(packet.send) == "function" then
        pcall(function()
            packet.send()
        end)
    end
end

function HermitCrabAuto:UpgradeStat(stat)
    if type(stat) == "table" then
        stat = self:ResolveStat(stat)
    end
    self:OpenUI()
    local crab = self:GetNetwork()
    local query = crab and crab.queries and crab.queries.UpgradeStat
    if query and type(query.invoke) == "function" then
        local ok, result = pcall(function()
            return query.invoke(stat)
        end)
        if self.debug then
            print(("[HermitCrab] UpgradeStat stat=%s ok=%s result=%s id=%s"):format(tostring(stat), tostring(ok), tostring(result), tostring(self:GetQueryId("UpgradeStat"))))
        end
        if ok and result then return true, result, "wrapper" end
    end
    local rawOk, rawResult, queryId, mode = self:RawQuery("UpgradeStat", stat)
    if self.debug then
        print(("[HermitCrab] Raw UpgradeStat stat=%s ok=%s result=%s id=%s mode=%s"):format(tostring(stat), tostring(rawOk), tostring(rawResult), tostring(queryId), tostring(mode)))
    end
    if rawOk and rawResult == true then return true, rawResult, "raw:" .. tostring(queryId) end
    return rawOk and rawResult == true, rawResult, "raw:" .. tostring(queryId)
end

function HermitCrabAuto:ClaimAll()
    self:OpenUI()
    local crab = self:GetNetwork()
    local query = crab and crab.queries and crab.queries.ClaimAllShells
    if query and type(query.invoke) == "function" then
        local ok, result = pcall(function()
            return query.invoke()
        end)
        if self.debug then
            print(("[HermitCrab] ClaimAllShells ok=%s result=%s id=%s"):format(tostring(ok), tostring(result), tostring(self:GetQueryId("ClaimAllShells"))))
        end
        if ok and result then return true, result, "wrapper" end
    end
    local rawOk, rawResult, queryId, mode = self:RawQuery("ClaimAllShells", nil)
    if self.debug then
        print(("[HermitCrab] Raw ClaimAllShells ok=%s result=%s id=%s mode=%s"):format(tostring(rawOk), tostring(rawResult), tostring(queryId), tostring(mode)))
    end
    if rawOk and rawResult ~= false then return true, rawResult, "raw:" .. tostring(queryId) end
    local nilOk, nilResult, nilQueryId = self:RawQueryNil("ClaimAllShells", nil)
    if self.debug then
        print(("[HermitCrab] NilPayload ClaimAllShells ok=%s result=%s id=%s"):format(tostring(nilOk), tostring(nilResult), tostring(nilQueryId)))
    end
    if nilOk and nilResult ~= false then return true, nilResult, "nil-payload:" .. tostring(nilQueryId) end
    return rawOk and rawResult ~= false, rawResult, "raw:" .. tostring(queryId)
end

function HermitCrabAuto:SetFlag(name, value)
    if not IsAlive() then return end
    self.flags[name] = value == true
    if self:AnyEnabled() then
        self:Start()
    end
end

function HermitCrabAuto:SetClaim(value)
    if not IsAlive() then return end
    self.flags.Claim = value == true
    if self.flags.Claim then
        self.lastClaim = 0
        self:Start()
    elseif not self:AnyEnabled() then
        self.enabled = false
    end
end

function HermitCrabAuto:Start()
    if not IsAlive() then return end
    self.enabled = true
    if self.loopRunning then return end
    self.loopRunning = true
    task.spawn(function()
        while IsAlive() and self.enabled do
            if not self:AnyEnabled() then
                self.enabled = false
                break
            end
            if self.flags.Claim and os.clock() - self.lastClaim >= self.claimDelay then
                self.lastClaim = os.clock()
                self:ClaimAll()
                if not RuntimeWait(0.15) then break end
            end
            for key, stat in pairs(self.statNames) do
                if self.flags[key] then
                    self:UpgradeStat(stat)
                    if not RuntimeWait(self.delay) then break end
                end
            end
            if not RuntimeWait(self.delay) then break end
        end
        self.loopRunning = false
    end)
end

function HermitCrabAuto:Stop()
    self.enabled = false
    for key in pairs(self.flags) do
        self.flags[key] = false
    end
end

local IslandTeleport = {
    islands = {
        {"Bay island", CFrame.new(81.02, 38.18, 191.55)},
        {"Crescent shore", CFrame.new(-1363.25, 38.18, 1529.20)},
        {"Sea stack island", CFrame.new(862.56, 38.55, 1443.19)},
        {"Sacred Mountain", CFrame.new(2576.19, 38.18, 375.27)},
        {"Caldera cay", CFrame.new(1652.64, 40.58, -1303.60)},
        {"Solmere", CFrame.new(-1449.86, 34.97, -1591.46)},
    },
}

function IslandTeleport:Go(cf)
    if not IsAlive() then return false end
    GhostTP.Teleport(cf, {
        returnBack = false,
        double = true,
        doubleDelay = 0.02,
        decoy = true,
        cameraMode = "hard",
        compensateMove = false,
    })
end

local ClawTeleport = {
    selected = "Crystal Tideclaw",
    tools = {
        ["Crystal Tideclaw"] = CFrame.new(1000.27295, -51.17433, 1362.11047, 0.99619, -0.08585, -0.01513, 0.08717, 0.98106, 0.17295, -0.00001, -0.17361, 0.98481),
        ["Gold Sifter"] = CFrame.new(109.54417, 45.54300, 35.22266, 0.81915, 0.24242, 0.51984, 0.00001, 0.90629, -0.42265, -0.57358, 0.34622, 0.74239),
        ["Rusted Sifter"] = CFrame.new(105.95302, 45.36655, 51.95873, -0.00000, 0.00000, 1.00000, 0.00000, 1.00000, 0.00000, -1.00000, 0.00000, -0.00000),
        ["Bronze Sifter"] = CFrame.new(107.67882, 45.36191, 45.83107, 0.74153, 0.66943, 0.04476, -0.66286, 0.72068, 0.20306, 0.10368, -0.18024, 0.97814),
        ["Blood Tideclaw"] = CFrame.new(224.29442, 26.88140, -55.32447, 0.96594, -0.00000, -0.25877, 0.25877, 0.00001, 0.96594, 0.00000, -1.00000, 0.00001),
        ["Haunted Tideclaw"] = CFrame.new(155.22102, 121.91089, -80.62851, 0.98481, 0.16772, -0.04498, -0.17365, 0.95124, -0.25491, 0.00003, 0.25885, 0.96592),
        ["Divine Tideclaw"] = CFrame.new(-51.47266, 3141.03369, 1327.17480, 0.86601, 0.00008, -0.50003, -0.00008, 1.00000, 0.00002, 0.50003, 0.00002, 0.86601),
        ["Starter Sifter"] = CFrame.new(101.48770, 45.89111, 43.31085, 0.25879, -0.24999, 0.93302, 0.00001, 0.96593, 0.25880, -0.96593, -0.06697, 0.24998),
        ["Steel Sifter"] = CFrame.new(106.77464, 44.89670, 48.69117, 0.76604, 0.21985, 0.60403, 0.00002, 0.93968, -0.34205, -0.64279, 0.26203, 0.71983),
        ["Rapid Sifter"] = CFrame.new(94.43351, 45.60048, 59.38794, 0.75440, 0.18853, 0.62876, -0.17364, 0.98106, -0.08583, -0.63303, -0.04443, 0.77285),
        ["Blitz Sifter"] = CFrame.new(96.77120, 46.13220, 57.29479, -0.11070, -0.79520, 0.59616, 0.99149, -0.12973, 0.01107, 0.06854, 0.59231, 0.80279),
        ["Frosted Tideclaw"] = CFrame.new(1041.09241, -53.73621, 1415.40393, 1.00000, 0.00000, 0.00000, 0.00000, 0.98481, -0.17362, 0.00000, 0.17362, 0.98481),
        ["Selendris Sceptre"] = CFrame.new(2530.97388, 36.90078, 450.33972, 0.97784, -0.00000, -0.20937, 0.00000, 1.00000, -0.00000, 0.20937, 0.00000, 0.97784),
        ["Silver Sifter"] = CFrame.new(110.18595, 44.86025, 38.27998, 0.65356, 0.64870, -0.38994, -0.14457, 0.61270, 0.77698, 0.74294, -0.45143, 0.49422),
        ["Coral Tideclaw"] = CFrame.new(-1406.35840, 32.99045, 1556.31494, 0.76771, -0.63658, 0.07340, 0.63921, 0.75275, -0.15741, 0.04495, 0.16776, 0.98480),
        ["Simple Tideclaw"] = CFrame.new(-1409.57849, 32.99088, 1549.64612, 1.00000, 0.00000, 0.00000, 0.00000, 0.96593, -0.25880, 0.00000, 0.25880, 0.96593),
        ["RGB Tideclaw"] = CFrame.new(-1412.83545, 36.14275, 1556.27112, 0.95124, -0.17365, -0.25491, 0.16772, 0.98481, -0.04498, 0.25885, 0.00003, 0.96592),
        ["Brineblossom"] = CFrame.new(-1540.44214, 37.78951, -1672.52393, -1.00000, 0.00000, 0.00000, 0.00000, 1.00000, 0.00000, 0.00000, 0.00000, -1.00000),
        ["Solar Tideclaw"] = CFrame.new(1788.26880, 67.46360, -1619.34094, 0.90630, 0.42263, -0.00001, -0.00001, 0.00004, 1.00000, 0.42263, -0.90630, 0.00004),
        ["Sanctum Tideclaw"] = CFrame.new(2704.68359, 38.10104, 403.05029, 0.64282, 0.13298, 0.75439, 0.00002, 0.98481, -0.17362, -0.76602, 0.11163, 0.63305),
        ["Sunveil Tideclaw"] = CFrame.new(2774.13770, 70.00415, 482.68906, 0.64281, 0.06676, 0.76311, 0.00001, 0.99619, -0.08716, -0.76602, 0.05603, 0.64037),
    },
}

function ClawTeleport:GetNames()
    local names = {}
    for name in pairs(self.tools) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

function ClawTeleport:RefreshFromScanner()
    local scanner = type(getgenv) == "function" and getgenv().EminancePurchasableToolsScanner
    if not scanner or type(scanner.GetTeleportList) ~= "function" then return false end
    for _, item in ipairs(scanner:GetTeleportList()) do
        if item.name and item.cframe then
            self.tools[item.name] = item.cframe
        end
    end
    return true
end

function ClawTeleport:Go(name)
    if not IsAlive() then return false end
    local cf = self.tools[name or self.selected]
    if not cf then return false end
    GhostTP.Teleport(cf + Vector3.new(0, 4, 0), {
        returnBack = false,
        double = true,
        doubleDelay = 0.02,
        decoy = true,
        cameraMode = "hard",
        compensateMove = false,
    })
    return true
end

local WorldAssist = {
    waterWalk = false,
    waterPart = nil,
    waterConn = nil,
}

function WorldAssist:GetChar()
    local char = LP.Character
    return char, char and char:FindFirstChild("HumanoidRootPart"), char and char:FindFirstChildOfClass("Humanoid")
end

function WorldAssist:GetPlatform()
    if self.waterPart and self.waterPart.Parent then return self.waterPart end
    local part = Instance.new("Part")
    part.Name = "Eminance_WaterWalk"
    part.Size = Vector3.new(8, 1, 8)
    part.Anchored = true
    part.CanCollide = true
    part.CanTouch = false
    part.CanQuery = false
    part.Transparency = 1
    part.CFrame = CFrame.new(0, -100000, 0)
    part.Parent = workspace
    self.waterPart = part
    return part
end

function WorldAssist:ParkPlatform()
    if self.waterPart and self.waterPart.Parent then
        self.waterPart.CFrame = CFrame.new(0, -100000, 0)
    end
end

function WorldAssist:EnsureLiquidLoop()
    if self.waterConn then return end
    self.waterConn = TrackConnection(RS.Heartbeat:Connect(function()
        if not IsAlive() then self:StopWaterWalk(); return end
        if not self.waterWalk then return end
        local char, hrp = self:GetChar()
        if not hrp then self:ParkPlatform(); return end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = char and {char, self.waterPart} or {self.waterPart}
        params.IgnoreWater = false
        local result = workspace:Raycast(hrp.Position + Vector3.new(0, 5, 0), Vector3.new(0, -18, 0), params)
        if result and result.Material == Enum.Material.Water then
            local platform = self:GetPlatform()
            platform.CFrame = CFrame.new(hrp.Position.X, result.Position.Y + 0.25, hrp.Position.Z)
        else
            self:ParkPlatform()
        end
    end))
end

function WorldAssist:StartWaterWalk()
    self.waterWalk = true
    self:EnsureLiquidLoop()
end

function WorldAssist:StopWaterWalk()
    self.waterWalk = false
    if self.waterConn then self.waterConn:Disconnect(); self.waterConn = nil end
    self:ParkPlatform()
end

TrackConnection(LP.CharacterAdded:Connect(function()
    task.wait(0.25)
    if not IsAlive() then return end
    if WorldAssist.waterWalk then WorldAssist:StartWaterWalk() end
end))

local MiscMovement = {
    fly = false,
    flySpeed = 58,
    flyConn = nil,
    flyBeginConn = nil,
    flyEndConn = nil,
    flyVertical = 0,
    speed = false,
    speedValue = 24,
    speedConn = nil,
    oldWalkSpeed = nil,
    noclip = false,
    noclipConn = nil,
    noclipCache = {},
}

function MiscMovement:GetChar()
    local char = LP.Character
    return char, char and char:FindFirstChild("HumanoidRootPart"), char and char:FindFirstChildOfClass("Humanoid")
end

function MiscMovement:SetFlySpeed(speed)
    self.flySpeed = tonumber(speed) or self.flySpeed
end

function MiscMovement:SetSpeed(speed)
    self.speedValue = tonumber(speed) or self.speedValue
end

function MiscMovement:StartSpeed()
    self.speed = true
    if self.speedConn then return end
    self.speedConn = TrackConnection(RS.Heartbeat:Connect(function()
        if not IsAlive() then self:StopSpeed(); return end
        if not self.speed then return end
        local _, _, hum = self:GetChar()
        if not hum then return end
        if not self.oldWalkSpeed then
            self.oldWalkSpeed = hum.WalkSpeed
        end
        hum.WalkSpeed = self.speedValue
    end))
end

function MiscMovement:StopSpeed()
    self.speed = false
    if self.speedConn then self.speedConn:Disconnect(); self.speedConn = nil end
    local _, _, hum = self:GetChar()
    if hum and self.oldWalkSpeed then
        hum.WalkSpeed = self.oldWalkSpeed
    end
    self.oldWalkSpeed = nil
end

function MiscMovement:StartFly()
    self.fly = true
    if self.flyConn then return end
    self.flyVertical = 0
    self.flyBeginConn = TrackConnection(UIS.InputBegan:Connect(function(input, gp)
        if gp or not IsAlive() or not self.fly then return end
        if input.KeyCode == Enum.KeyCode.Space then
            self.flyVertical = 1
        elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.LeftShift then
            self.flyVertical = -1
        end
    end))
    self.flyEndConn = TrackConnection(UIS.InputEnded:Connect(function(input)
        if not IsAlive() or not self.fly then return end
        if input.KeyCode == Enum.KeyCode.Space and self.flyVertical == 1 then
            self.flyVertical = 0
        elseif (input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.LeftShift) and self.flyVertical == -1 then
            self.flyVertical = 0
        end
    end))
    self.flyConn = TrackConnection(RS.RenderStepped:Connect(function(dt)
        if not IsAlive() then self:StopFly(); return end
        if not self.fly then return end
        local _, hrp, hum = self:GetChar()
        local cam = workspace.CurrentCamera
        if not hrp or not cam then return end
        local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
        if self.flyVertical == 1 then
            dir += Vector3.new(0, 1, 0)
        elseif self.flyVertical == -1 then
            dir -= Vector3.new(0, 1, 0)
        end
        if dir.Magnitude > 0 then dir = dir.Unit end
        if hum then hum:ChangeState(Enum.HumanoidStateType.Freefall) end
        hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity:Lerp(dir * self.flySpeed, math.clamp(dt * 12, 0, 1))
        hrp.AssemblyAngularVelocity = Vector3.zero
    end))
end

function MiscMovement:StopFly()
    self.fly = false
    self.flyVertical = 0
    if self.flyConn then self.flyConn:Disconnect(); self.flyConn = nil end
    if self.flyBeginConn then self.flyBeginConn:Disconnect(); self.flyBeginConn = nil end
    if self.flyEndConn then self.flyEndConn:Disconnect(); self.flyEndConn = nil end
    local _, hrp, hum = self:GetChar()
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
    if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
end

function MiscMovement:StartNoclip()
    self.noclip = true
    if self.noclipConn then return end
    self.noclipConn = TrackConnection(RS.Stepped:Connect(function()
        if not IsAlive() then self:StopNoclip(); return end
        if not self.noclip then return end
        local char = LP.Character
        if not char then return end
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("BasePart") then
                if self.noclipCache[obj] == nil then
                    self.noclipCache[obj] = obj.CanCollide
                end
                obj.CanCollide = false
            end
        end
    end))
end

function MiscMovement:StopNoclip()
    self.noclip = false
    if self.noclipConn then self.noclipConn:Disconnect(); self.noclipConn = nil end
    for part, canCollide in pairs(self.noclipCache) do
        if part and part.Parent then
            pcall(function() part.CanCollide = canCollide end)
        end
    end
    self.noclipCache = {}
end

TrackConnection(LP.CharacterAdded:Connect(function()
    task.wait(0.25)
    if not IsAlive() then return end
    MiscMovement.noclipCache = {}
    if MiscMovement.noclip then MiscMovement:StartNoclip() end
    if MiscMovement.speed then MiscMovement:StartSpeed() end
    if MiscMovement.fly then MiscMovement:StartFly() end
end))

if type(getgenv) == "function" then
    getgenv().EminanceMiscMovement = MiscMovement
    getgenv().EminanceHermitCrabAuto = HermitCrabAuto
    getgenv().EminanceIslandTeleport = IslandTeleport
    getgenv().EminanceClawTeleport = ClawTeleport
    getgenv().EminanceWorldAssist = WorldAssist
end

OnShutdown(function()
    pcall(function() AutoFarm:Stop() end)
    pcall(function() AutoSell:Stop() end)
    pcall(function() HermitCrabAuto:Stop() end)
    pcall(function() WorldAssist:StopWaterWalk() end)
    pcall(function() MiscMovement:StopSpeed() end)
    pcall(function() MiscMovement:StopFly() end)
    pcall(function() MiscMovement:StopNoclip() end)
    pcall(function() GhostTP.Restore() end)
end)

local farm = mLeft:AddSection("auto farm")
farm:AddToggle("enabled", false, function(v)
    if v then
        AutoFarm:Start()
    else
        AutoFarm:Stop()
    end
end, {keybind = "F"})
farm:AddButton("fix camera", function() GhostTP.Restore() end)
farm:AddLabel("F toggles clone-masked auto farm")

local sell = mLeft:AddSection("auto sell")
sell:AddToggle("enabled", false, function(v)
    if v then
        AutoSell:Start()
    else
        AutoSell:Stop()
    end
end, {keybind = "V"})
sell:AddLabel("V uses clone-masked Merchant.Zone blink, sells all, then returns")

local hermit = mLeft:AddSection("auto hermit crab")
hermit:AddToggle("auto luck", false, function(v) HermitCrabAuto:SetFlag("Luck", v) end)
hermit:AddToggle("auto speed", false, function(v) HermitCrabAuto:SetFlag("Speed", v) end)
hermit:AddToggle("auto space", false, function(v) HermitCrabAuto:SetFlag("Space", v) end)
hermit:AddToggle("auto weight", false, function(v) HermitCrabAuto:SetFlag("Weight", v) end)
hermit:AddToggle("auto claim inventory", false, function(v) HermitCrabAuto:SetClaim(v) end)
hermit:AddButton("print bytenet ids", function() HermitCrabAuto:PrintByteNetIds() end)
hermit:AddButton("bytenet diagnostic", function() HermitCrabAuto:Diagnostic() end)

local timing = mRight:AddSection("timing")
timing:AddSlider("replication delay", 20, 250, 140, function(v) AutoFarm.replDelay = v / 1000 end, {format = function(v) return ("%dms"):format(v) end})
timing:AddSlider("restart delay", 0, 2000, 180, function(v) AutoFarm.restartDelay = v / 1000 end, {format = function(v) return ("%dms"):format(v) end})
timing:AddSlider("fail delay", 250, 3000, 250, function(v) AutoFarm.failDelay = v / 1000 end, {format = function(v) return ("%dms"):format(v) end})
timing:AddSlider("move compensation", 0, 25, 0, function(v) AutoFarm.maxCompensate = v end, {format = function(v) return ("%dst"):format(v) end})

local islands = mRight:AddSection("teleport to island")
for _, island in ipairs(IslandTeleport.islands) do
    islands:AddButton(island[1], function()
        IslandTeleport:Go(island[2])
    end)
end

local claw = mRight:AddSection("teleport to claw")
local clawDropdown = claw:AddDropdown("tool", ClawTeleport:GetNames(), function(v)
    ClawTeleport.selected = v
end, {search = true, visibleRows = 12, rowHeight = 20})
claw:AddButton("refresh claw list", function()
    local ok = ClawTeleport:RefreshFromScanner()
    clawDropdown:SetOptions(ClawTeleport:GetNames())
    Hub:Notify("teleport to claw", ok and "scanner list refreshed" or "using saved list", "info", 2)
end)
claw:AddButton("teleport", function()
    local ok = ClawTeleport:Go(ClawTeleport.selected)
    Hub:Notify("teleport to claw", ok and ("teleporting to " .. tostring(ClawTeleport.selected)) or "select a claw first", ok and "success" or "error", 2)
end)

local world = mRight:AddSection("world")
world:AddToggle("water walk", false, function(v)
    if v then
        WorldAssist:StartWaterWalk()
    else
        WorldAssist:StopWaterWalk()
    end
end)

local Misc = Hub:MakeTab("misc")
local miscLeft = Misc:Column()
local miscRight = Misc:Column()
local miscMove = miscRight:AddSection("movement")
miscMove:AddToggle("fly", false, function(v)
    if v then
        MiscMovement:StartFly()
    else
        MiscMovement:StopFly()
    end
end, {keybind = "G"})
miscMove:AddSlider("fly speed", 10, 350, 58, function(v)
    MiscMovement:SetFlySpeed(v)
end, {format = function(v) return ("%dst/s"):format(v) end})
miscMove:AddToggle("speed", false, function(v)
    if v then
        MiscMovement:StartSpeed()
    else
        MiscMovement:StopSpeed()
    end
end, {keybind = "H"})
miscMove:AddSlider("speed value", 16, 350, 24, function(v)
    MiscMovement:SetSpeed(v)
end, {format = function(v) return ("%dst/s"):format(v) end})
miscMove:AddToggle("noclip", false, function(v)
    if v then
        MiscMovement:StartNoclip()
    else
        MiscMovement:StopNoclip()
    end
end, {keybind = "N"})
local miscInfo = miscLeft:AddSection("info")
miscInfo:AddLabel("movement controls are on the side")

local Settings = Hub:MakeHiddenTab("UI Settings")
local sL = Settings:Column()
local sR = Settings:Column()

local theme = sL:AddSection("theme")
theme:AddDropdown("theme preset", PresetNames, function(v) Hub:_SetAccent(v) end, {default = "Light"})
theme:AddLabel("themes fully recolor the entire UI")
theme:AddButton("test notification", function() Hub:Notify("notification", "Eminance interface is ready", "info", 3) end)
theme:AddButton("success toast",     function() Hub:Notify("ok", "system loaded successfully", "success", 2.5) end)
theme:AddButton("warning toast",     function() Hub:Notify("warning", "anti-cheat detected, slowing down", "warning", 2.5) end)
theme:AddButton("error toast",       function() Hub:Notify("error", "failed to bind keybind", "error", 2.5) end)

local info = sR:AddSection("about")
info:AddLabel("• drag header to move")
info:AddLabel("• right-shift toggles ui")
info:AddLabel("• minimize via − button")
info:AddLabel("• auto farm is in main tab")
info:AddLabel("• GhostTP masks teleport blink")

-- Config Manager section (Electro Sailor pattern, restyled)
local cfgSec = sR:AddSection("configs")
local cfgName = "Default"
-- inline name input row
do
    local row = inst("Frame", {Parent = cfgSec._body, Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, ZIndex = 5})
    local lbl = inst("TextLabel", {
        Parent = row, Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1,
        Font = F.Reg, Text = "config name", TextColor3 = T.TextSoft, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5,
    })
    regText(lbl, "TextSoft")
    local box = inst("TextBox", {
        Parent = row, Size = UDim2.new(1, 0, 0, 22), Position = UDim2.fromOffset(0, 14),
        BackgroundColor3 = T.Slot, BorderSizePixel = 0,
        Font = F.Reg, PlaceholderText = "Default", Text = cfgName,
        TextColor3 = T.Text, PlaceholderColor3 = T.Muted, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 6,
    })
    crn(box, 3); regBg(box, "Slot")
    pad(box, 0, 6, 0, 6)
    regText(box, "Text") -- ensure typed text is rendered in T.Text, not gray
    local bs = strk(box, 1, T.Border, 0); regStroke(bs, "Border")
    box:GetPropertyChangedSignal("Text"):Connect(function()
        cfgName = (box.Text ~= "" and box.Text) or "Default"
    end)
end
cfgSec:AddButton("save config", function() if Hub:_SaveConfig(cfgName) then Hub:_RefreshConfigList() end end)
cfgSec:AddButton("refresh list", function() Hub:_RefreshConfigList() end)
-- scrolling list area, registered for _RefreshConfigList()
do
    local listFrame = inst("Frame", {
        Parent = cfgSec._body, Size = UDim2.new(1, 0, 0, 130),
        BackgroundColor3 = T.PanelHi, BackgroundTransparency = 0.4,
        BorderSizePixel = 0, ZIndex = 5,
    })
    crn(listFrame, 4); regBg(listFrame, "PanelHi")
    local lfs = strk(listFrame, 1, T.Border, 0); regStroke(lfs, "Border")
    local scroll = inst("ScrollingFrame", {
        Parent = listFrame, Size = UDim2.new(1, -6, 1, -6),
        Position = UDim2.fromOffset(3, 3), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 2,
        ScrollBarImageColor3 = T.Border,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0), ZIndex = 6,
    })
    inst("UIListLayout", {Parent = scroll, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder})
    Hub._cfgListScroll = scroll
end
cfgSec:AddLabel("★ = auto-load on script start")

-- wire the sidebar floor button to open the UI Settings hidden tab
if Hub._uiSettingsBtn and Settings._activate then
    Hub._uiSettingsBtn.MouseButton1Click:Connect(function()
        Settings._activate()
    end)
end

-- Initial config list build + auto-load (after all widgets registered their flags)
task.defer(function()
    task.wait(0.3)
    Hub:_RefreshConfigList()
    Hub:_AutoLoadConfig()
end)

task.delay(1.8, function() Hub:Notify("welcome", "Auto farm ready", "success", 3) end)

return Hub
