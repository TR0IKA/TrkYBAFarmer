--[[ TRK YBA Farmer v3 ]]

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

-- Raw-ссылка на этот файл (pastebin / GitHub raw) для автозапуска после серверхопа
local SCRIPT_URL = "https://raw.githubusercontent.com/TR0IKA/TrkYBAFarmer/refs/heads/main/TRK_YBA_Farmer.lua"

-- Базовый список предметов. Остальные подтягиваются кнопкой "Обновить список"
local BASE_ITEMS = {
	-- Стрелы
	"Mysterious Arrow", "Lucky Arrow", "Requiem Arrow",
	-- Рокакака
	"Rokakaka", "Rokakaka Fruit", "Pure Rokakaka", "Pure Rokakaka Fruit",
	-- Части Святого трупа
	"Rib Cage of The Saint's Corpse", "Rib Cage of the Saint's Corpse",
	"Left Arm of The Saint's Corpse", "Left Arm of the Saint's Corpse",
	"Heart of The Saint's Corpse", "Heart of the Saint's Corpse",
	"Pelvis of The Saint's Corpse", "Pelvis of the Saint's Corpse",
	"Saint's Corpse Parts",
	-- Остальное
	"DIO's Diary", "DIO's Bone", "Green Baby", "Jotaro Disc", "Gold Coin", "Diamond",
	"Stone Mask", "Lucky Stone Mask", "Steel Ball", "Quinton's Glove", "Ancient Scroll",
	"Bottle Of Blood", "Mysterious Bow", "Christmas Present", "Horse Feed", "SBR Money Bags",
	"Revolver",
	-- Redeemed (из кодов)
	"Redeemed Mysterious Arrow", "Redeemed Rokakaka", "Redeemed Pure Rokakaka",
	-- Хэллоуин 2026 (точное название конфеты проверь через сканер)
	"Candy", "Candy Corn",
}

local FLY_SPEED = 140        -- studs/sec
local HOVER_HEIGHT = 4       -- висим над предметом
local ACCENT_ORDER = { "Orange", "Cyan", "Purple", "Green", "Red", "Pink" }
local ACCENTS = {
	Orange = Color3.fromRGB(255, 170, 0),
	Cyan = Color3.fromRGB(0, 200, 255),
	Purple = Color3.fromRGB(170, 90, 255),
	Green = Color3.fromRGB(80, 220, 110),
	Red = Color3.fromRGB(255, 70, 70),
	Pink = Color3.fromRGB(255, 100, 180),
}
local BG = Color3.fromRGB(24, 26, 34)
local BG2 = Color3.fromRGB(38, 41, 54)
local TXT = Color3.fromRGB(255, 255, 255)

local L = {
	ru = {
		tabFunc = "Функции", tabSet = "Настройки", autoFarm = "Автосбор вещей",
		serverHop = "Автосбор с серверхопом", items = "Предметы для фарма", scan = "Обновить список предметов",
		accent = "Акцентный цвет", lang = "Язык GUI", lock = "Заблокировать перемещение",
		configs = "Конфиги", cfgName = "Название конфига", save = "Сохранить",
		load = "Загрузить", delete = "Удалить",
		idle = "Статус: ожидание", farming = "Статус: фарм", hopping = "Статус: смена сервера...",
		waiting = "Статус: жду новые вещи на земле", hopFail = "Не вышло сменить сервер, повтор через несколько сек",
		noCfg = "Конфигов пока нет", cfgSaved = "Конфиг сохранён", cfgLoaded = "Конфиг загружен",
		cfgDeleted = "Конфиг удалён", noSelect = "Сначала выбери конфиг", noName = "Введи название",
		scanned = "Найдено новых предметов: ",
		speed = "Скорость полёта: ", tpMode = "Телепорт вместо полёта",
	},
	en = {
		tabFunc = "Functions", tabSet = "Settings", autoFarm = "Auto collect items",
		serverHop = "Auto collect with server hop", items = "Items to farm", scan = "Rescan item list",
		accent = "Accent color", lang = "GUI language", lock = "Lock movement",
		configs = "Configs", cfgName = "Config name", save = "Save",
		load = "Load", delete = "Delete",
		idle = "Status: idle", farming = "Status: farming", hopping = "Status: hopping server...",
		waiting = "Status: waiting for new items on the ground", hopFail = "Server hop failed, retrying in a few seconds",
		noCfg = "No configs yet", cfgSaved = "Config saved", cfgLoaded = "Config loaded",
		cfgDeleted = "Config deleted", noSelect = "Select a config first", noName = "Enter a name",
		scanned = "New items found: ",
		speed = "Flight speed: ", tpMode = "Teleport instead of flying",
	},
}

-- ================= SESSION SETTINGS (живут до закрытия клиента) =================
local genv = (getgenv and getgenv()) or _G
local S = genv.TRK_YBA_S
if not S then
	S = { AutoFarm = false, ServerHop = false, Lang = "ru", Accent = "Orange", LockMove = false, Items = {} }
	genv.TRK_YBA_S = S
end
S.FlySpeed = tonumber(S.FlySpeed) or FLY_SPEED
S.Teleport = S.Teleport == true
local runId = tostring(tick())
genv.TRK_YBA_RUN = runId

-- Список имён предметов (базовые + найденные сканом)
local itemNames = {}
local seenName = {}
local function addItemName(n)
	if n and n ~= "" and not seenName[n] then
		seenName[n] = true
		table.insert(itemNames, n)
		return true
	end
	return false
end
for _, n in ipairs(BASE_ITEMS) do addItemName(n) end

-- ================= UI HELPERS =================
local accentObjs, labels, refreshers = {}, {}, {}

local function T(key) return L[S.Lang][key] end

local function make(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end

local function round(o, r)
	make("UICorner", { CornerRadius = UDim.new(0, r or 8) }, o)
	return o
end

local function stroke(o, thick)
	local s = make("UIStroke", { Thickness = thick or 2 }, o)
	table.insert(accentObjs, { s, "Color" })
	return s
end

local function accentProp(obj, prop)
	table.insert(accentObjs, { obj, prop })
	obj[prop] = ACCENTS[S.Accent]
	return obj
end

local function tr(obj, key)
	table.insert(labels, { obj, key })
	if obj:IsA("TextBox") then obj.PlaceholderText = T(key) else obj.Text = T(key) end
	return obj
end

local function applyLang()
	for _, e in ipairs(labels) do
		if e[1]:IsA("TextBox") then e[1].PlaceholderText = T(e[2]) else e[1].Text = T(e[2]) end
	end
end

local function refreshAll()
	for _, f in ipairs(refreshers) do f() end
	applyLang()
end

local function applyAccent()
	for _, e in ipairs(accentObjs) do e[1][e[2]] = ACCENTS[S.Accent] end
	for _, f in ipairs(refreshers) do f() end
end

local function button(parent, key, size, pos)
	local b = make("TextButton", {
		Size = size, Position = pos or UDim2.new(0, 0, 0, 0), BackgroundColor3 = BG2, TextColor3 = TXT,
		Font = Enum.Font.GothamBold, TextSize = 13, Text = "", AutoButtonColor = true,
	}, parent)
	round(b, 8)
	stroke(b, 1)
	if key then tr(b, key) end
	return b
end

local function toggle(parent, x, y, w, key, getter, setter)
	local row = make("Frame", {
		Size = UDim2.new(0, w, 0, 34), Position = UDim2.new(0, x, 0, y), BackgroundTransparency = 1,
	}, parent)
	local lbl = make("TextLabel", {
		Size = UDim2.new(1, -56, 1, 0), BackgroundTransparency = 1, TextColor3 = TXT,
		Font = Enum.Font.GothamBold, TextSize = 12, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	tr(lbl, key)
	local sw = make("TextButton", {
		Size = UDim2.new(0, 46, 0, 24), Position = UDim2.new(1, -46, 0.5, -12),
		BackgroundColor3 = BG, Text = "",
	}, row)
	round(sw, 12)
	stroke(sw, 1)
	local knob = make("Frame", { Size = UDim2.new(0, 18, 0, 18), BorderSizePixel = 0 }, sw)
	round(knob, 9)
	local function draw()
		local on = getter()
		knob.Position = on and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
		knob.BackgroundColor3 = on and ACCENTS[S.Accent] or Color3.fromRGB(120, 120, 130)
	end
	sw.Activated:Connect(function()
		setter(not getter())
		draw()
	end)
	table.insert(refreshers, draw)
	draw()
	return row
end

local function draggable(handle, target)
	local dragging, startPos, startFrame = false, nil, nil
	handle.InputBegan:Connect(function(i)
		if S.LockMove then return end
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPos = i.Position
			startFrame = target.Position
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and not S.LockMove and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - startPos
			target.Position = UDim2.new(startFrame.X.Scale, startFrame.X.Offset + d.X, startFrame.Y.Scale, startFrame.Y.Offset + d.Y)
		end
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

-- Камера не крутится, пока пользователь трогает GUI (мобилки)
local CAM_ACTION = "TRK_FreezeCamera"
local function freezeCam(on)
	if on then
		CAS:BindActionAtPriority(CAM_ACTION, function()
			return Enum.ContextActionResult.Sink
		end, false, 3000, Enum.UserInputType.Touch)
	else
		CAS:UnbindAction(CAM_ACTION)
	end
end

-- ================= GUI =================
local parentGui = (gethui and gethui()) or CoreGui
local old = parentGui:FindFirstChild("TRK_YBA_Farmer")
if old then old:Destroy() end

local gui = make("ScreenGui", {
	Name = "TRK_YBA_Farmer", ResetOnSpawn = false, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, parentGui)

local main = make("Frame", {
	Size = UDim2.new(0, 500, 0, 300), Position = UDim2.new(0.5, -250, 0.5, -150),
	BackgroundColor3 = BG,
}, gui)
round(main, 14)
stroke(main, 3)

local title = make("TextLabel", {
	Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 12, 0, 6), BackgroundTransparency = 1,
	Text = "TRK YBA Farmer", Font = Enum.Font.GothamBlack, TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Left,
}, main)
accentProp(title, "TextColor3")
draggable(title, main)

local tabF = button(main, "tabFunc", UDim2.new(0, 150, 0, 28), UDim2.new(0, 12, 0, 38))
local tabS = button(main, "tabSet", UDim2.new(0, 150, 0, 28), UDim2.new(0, 170, 0, 38))
local activeTab = "func"
local function paintTabs()
	tabF.BackgroundColor3 = activeTab == "func" and ACCENTS[S.Accent] or BG2
	tabS.BackgroundColor3 = activeTab == "set" and ACCENTS[S.Accent] or BG2
	tabF.TextColor3 = activeTab == "func" and BG or TXT
	tabS.TextColor3 = activeTab == "set" and BG or TXT
end
table.insert(refreshers, paintTabs)

local funcPage = make("Frame", {
	Size = UDim2.new(1, -24, 1, -80), Position = UDim2.new(0, 12, 0, 74), BackgroundTransparency = 1,
}, main)
local setPage = make("Frame", {
	Size = UDim2.new(1, -24, 1, -80), Position = UDim2.new(0, 12, 0, 74), BackgroundTransparency = 1,
	Visible = false,
}, main)

local function showTab(name)
	activeTab = name
	funcPage.Visible = name == "func"
	setPage.Visible = name == "set"
	paintTabs()
end
tabF.Activated:Connect(function() showTab("func") end)
tabS.Activated:Connect(function() showTab("set") end)

-- ----- Функции -----
local statusLbl = make("TextLabel", {
	Size = UDim2.new(0, 230, 0, 30), BackgroundTransparency = 1, TextColor3 = TXT,
	Font = Enum.Font.Gotham, TextSize = 11, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
}, funcPage)
local statusEntry = { statusLbl, "idle" }
table.insert(labels, statusEntry)
local function setStatus(k)
	statusEntry[2] = k
	statusLbl.Text = T(k)
end
statusLbl.Text = T("idle")

toggle(funcPage, 0, 36, 230, "autoFarm", function() return S.AutoFarm end, function(v)
	S.AutoFarm = v
	setStatus(v and "farming" or "idle")
end)
toggle(funcPage, 0, 80, 230, "serverHop", function() return S.ServerHop end, function(v)
	S.ServerHop = v
end)

local itemHeader = button(funcPage, "items", UDim2.new(0, 230, 0, 30), UDim2.new(0, 240, 0, 0))
local itemBox = make("ScrollingFrame", {
	Size = UDim2.new(0, 230, 1, -40), Position = UDim2.new(0, 240, 0, 36), BackgroundColor3 = BG,
	ScrollBarThickness = 4, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0),
	Visible = false, BorderSizePixel = 0,
}, funcPage)
round(itemBox, 8)
stroke(itemBox, 1)
make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, itemBox)
make("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, itemBox)
itemHeader.Activated:Connect(function() itemBox.Visible = not itemBox.Visible end)

local scanBtn
local rebuildItemRows

-- Сканирует workspace по ProximityPrompt: предметы на земле обычно с ними.
-- Так подтянутся новые/ивентовые названия (конфеты Хэллоуина и т.д.)
local function inCharacter(d)
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character and d:IsDescendantOf(p.Character) then return true end
	end
	return false
end

local BAD_NAMES = {
	Workspace = true, workspace = true, Casino = true, casino = true, Terrain = true, Camera = true,
	Dialogues = true, ["Item Machine"] = true, Pluck = true, ["Boxing Gloves"] = true,
}
local skipped = {}

-- Есть ли у объекта или его родителей Humanoid (персонаж/NPC) или имя из чёрного списка (казино и т.п.)
local function hasHumanoidAncestor(d)
	local p = d
	while p and p ~= workspace and p ~= game do
		if BAD_NAMES[p.Name] or p:FindFirstChildOfClass("Humanoid") then return true end
		p = p.Parent
	end
	return false
end

-- Владелец предмета по его интерактивному объекту (TouchInterest / ProximityPrompt / ClickDetector)
local function ownerOf(d)
	if d:IsA("Tool") then return d end
	if d:IsA("TouchTransmitter") then
		return d.Parent
	end
	if d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
		local o = d.Parent
		if o and o:IsA("Attachment") then o = o.Parent end
		return o
	end
	return nil
end

local function scanItems()
	local added = 0
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsDescendantOf(workspace) then
			local owner = ownerOf(d)
			if owner and (owner:IsA("BasePart") or owner:IsA("Model") or owner:IsA("Tool"))
				and owner:IsDescendantOf(workspace) and not inCharacter(owner)
				and not hasHumanoidAncestor(owner) then
				if addItemName(owner.Name) then
					added += 1
					print("[TRK] предмет:", owner.Name, "|", owner:GetFullName())
				end
			end
		end
	end
	return added
end

rebuildItemRows = function()
	for _, c in ipairs(itemBox:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	scanBtn = button(itemBox, "scan", UDim2.new(1, -8, 0, 26), nil)
	scanBtn.Activated:Connect(function()
		local n = scanItems()
		rebuildItemRows()
		setStatus("idle")
		statusLbl.Text = T("scanned") .. tostring(n)
	end)
	for _, name in ipairs(itemNames) do
		local row = button(itemBox, nil, UDim2.new(1, -8, 0, 26), nil)
		row.TextXAlignment = Enum.TextXAlignment.Left
		local function draw()
			row.Text = (S.Items[name] and "[✓]  " or "[  ]  ") .. name
		end
		draw()
		row.Activated:Connect(function()
			S.Items[name] = (not S.Items[name]) or nil
			draw()
		end)
	end
end

-- ----- Настройки -----
local function sectionLbl(parent, key, x, y, w)
	local l = make("TextLabel", {
		Size = UDim2.new(0, w, 0, 18), Position = UDim2.new(0, x, 0, y), BackgroundTransparency = 1,
		TextColor3 = TXT, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
	}, parent)
	tr(l, key)
	return l
end

sectionLbl(setPage, "accent", 0, 0, 230)
local swatchRow = make("Frame", { Size = UDim2.new(0, 230, 0, 26), Position = UDim2.new(0, 0, 0, 22), BackgroundTransparency = 1 }, setPage)
make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
}, swatchRow)
for _, name in ipairs(ACCENT_ORDER) do
	local sw = make("TextButton", { Size = UDim2.new(0, 26, 0, 26), BackgroundColor3 = ACCENTS[name], Text = "" }, swatchRow)
	round(sw, 13)
	sw.Activated:Connect(function()
		S.Accent = name
		applyAccent()
	end)
end

local langBtn = button(setPage, nil, UDim2.new(0, 230, 0, 28), UDim2.new(0, 0, 0, 56))
local function paintLang()
	langBtn.Text = S.Lang == "ru" and "Язык GUI: RU" or "GUI language: EN"
end
langBtn.Activated:Connect(function()
	S.Lang = S.Lang == "ru" and "en" or "ru"
	refreshAll()
	paintLang()
end)
table.insert(refreshers, paintLang)

toggle(setPage, 0, 96, 230, "lock", function() return S.LockMove end, function(v)
	S.LockMove = v
end)

local speedLbl = make("TextLabel", {
	Size = UDim2.new(0, 230, 0, 18), Position = UDim2.new(0, 0, 0, 136), BackgroundTransparency = 1,
	TextColor3 = TXT, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
}, setPage)
local function paintSpeed()
	speedLbl.Text = T("speed") .. tostring(S.FlySpeed)
end
table.insert(refreshers, paintSpeed)
paintSpeed()
local spMinus = button(setPage, nil, UDim2.new(0, 60, 0, 26), UDim2.new(0, 0, 0, 156))
spMinus.Text = "-"
local spPlus = button(setPage, nil, UDim2.new(0, 60, 0, 26), UDim2.new(0, 170, 0, 156))
spPlus.Text = "+"
spMinus.Activated:Connect(function()
	S.FlySpeed = math.max(40, S.FlySpeed - 20)
	paintSpeed()
end)
spPlus.Activated:Connect(function()
	S.FlySpeed = math.min(400, S.FlySpeed + 20)
	paintSpeed()
end)
toggle(setPage, 0, 186, 230, "tpMode", function() return S.Teleport end, function(v)
	S.Teleport = v
end)

-- Конфиги
sectionLbl(setPage, "configs", 240, 0, 230)
local cfgBox = make("TextBox", {
	Size = UDim2.new(0, 230, 0, 26), Position = UDim2.new(0, 240, 0, 22), BackgroundColor3 = BG2,
	TextColor3 = TXT, Text = "", Font = Enum.Font.Gotham, TextSize = 12, ClearTextOnFocus = false,
}, setPage)
round(cfgBox, 8)
tr(cfgBox, "cfgName")

local cfgBtns = make("Frame", { Size = UDim2.new(0, 230, 0, 26), Position = UDim2.new(0, 240, 0, 52), BackgroundTransparency = 1 }, setPage)
make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder,
}, cfgBtns)
local saveBtn = button(cfgBtns, "save", UDim2.new(0.34, -3, 1, 0), nil)
local loadBtn = button(cfgBtns, "load", UDim2.new(0.33, -3, 1, 0), nil)
local delBtn = button(cfgBtns, "delete", UDim2.new(0.33, -3, 1, 0), nil)
for _, b in ipairs({ saveBtn, loadBtn, delBtn }) do b.TextSize = 11 end

local msgLbl = make("TextLabel", {
	Size = UDim2.new(0, 230, 0, 16), Position = UDim2.new(0, 240, 0, 82), BackgroundTransparency = 1,
	TextColor3 = TXT, Font = Enum.Font.Gotham, TextSize = 11, Text = "", TextXAlignment = Enum.TextXAlignment.Left,
}, setPage)

local cfgList = make("ScrollingFrame", {
	Size = UDim2.new(0, 230, 1, -100), Position = UDim2.new(0, 240, 0, 100), BackgroundColor3 = BG,
	ScrollBarThickness = 4, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0),
	BorderSizePixel = 0,
}, setPage)
round(cfgList, 8)
stroke(cfgList, 1)
make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, cfgList)
make("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, cfgList)

-- ================= CONFIG LOGIC (файлы: workspace/TRK_YBA_Farmer/Configs) =================
local ROOT_DIR = "TRK_YBA_Farmer"
local CFG_DIR = ROOT_DIR .. "/Configs"
local canFile = writefile ~= nil and readfile ~= nil and isfile ~= nil and isfolder ~= nil and makefolder ~= nil
local memCfg = genv.TRK_YBA_MEMCFG or {}
genv.TRK_YBA_MEMCFG = memCfg
local selectedCfg = nil

if canFile then
	if not isfolder(ROOT_DIR) then makefolder(ROOT_DIR) end
	if not isfolder(CFG_DIR) then makefolder(CFG_DIR) end
end

local function cfgPath(name) return CFG_DIR .. "/" .. name .. ".json" end

local function cfgNames()
	local names = {}
	if canFile and listfiles then
		for _, path in ipairs(listfiles(CFG_DIR)) do
			local n = path:match("([^/\\]+)%.json$")
			if n then table.insert(names, n) end
		end
	else
		for n in pairs(memCfg) do table.insert(names, n) end
	end
	table.sort(names)
	return names
end

local function cfgWrite(name, data)
	local s = HttpService:JSONEncode(data)
	if canFile then writefile(cfgPath(name), s) else memCfg[name] = s end
end

local function cfgRead(name)
	local s
	if canFile then
		if isfile(cfgPath(name)) then s = readfile(cfgPath(name)) end
	else
		s = memCfg[name]
	end
	if not s then return nil end
	local ok, d = pcall(function() return HttpService:JSONDecode(s) end)
	return ok and d or nil
end

local function cfgDelete(name)
	if canFile then
		if isfile(cfgPath(name)) and delfile then delfile(cfgPath(name)) end
	else
		memCfg[name] = nil
	end
end

local function setMsg(k) msgLbl.Text = T(k) end

local function applyData(d)
	if type(d) ~= "table" then return false end
	S.AutoFarm = d.AutoFarm == true
	S.ServerHop = d.ServerHop == true
	S.LockMove = d.LockMove == true
	S.FlySpeed = math.clamp(tonumber(d.FlySpeed) or FLY_SPEED, 40, 400)
	S.Teleport = d.Teleport == true
	S.Accent = ACCENTS[d.Accent] and d.Accent or "Orange"
	S.Lang = d.Lang == "en" and "en" or "ru"
	S.Items = type(d.Items) == "table" and d.Items or {}
	for n in pairs(S.Items) do addItemName(n) end
	setStatus(S.AutoFarm and "farming" or "idle")
	return true
end

local rebuildList
rebuildList = function()
	for _, c in ipairs(cfgList:GetChildren()) do
		if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
	end
	local names = cfgNames()
	if #names == 0 then
		make("TextLabel", {
			Size = UDim2.new(1, -8, 0, 26), BackgroundTransparency = 1, TextColor3 = TXT,
			Font = Enum.Font.Gotham, TextSize = 12, Text = T("noCfg"),
		}, cfgList)
		return
	end
	for _, n in ipairs(names) do
		local b = button(cfgList, nil, UDim2.new(1, -8, 0, 26), nil)
		b.Text = n
		b.TextXAlignment = Enum.TextXAlignment.Left
		local function draw()
			local sel = selectedCfg == n
			b.BackgroundColor3 = sel and ACCENTS[S.Accent] or BG2
			b.TextColor3 = sel and BG or TXT
		end
		draw()
		b.Activated:Connect(function()
			selectedCfg = n
			for _, f in ipairs(refreshers) do f() end
		end)
		table.insert(refreshers, draw)
	end
end

saveBtn.Activated:Connect(function()
	local name = cfgBox.Text:gsub('[/\\:*?"<>|]', ""):gsub("^%s+", ""):gsub("%s+$", "")
	if name == "" then return setMsg("noName") end
	cfgWrite(name, {
		AutoFarm = S.AutoFarm, ServerHop = S.ServerHop, LockMove = S.LockMove,
		FlySpeed = S.FlySpeed, Teleport = S.Teleport,
		Accent = S.Accent, Lang = S.Lang, Items = S.Items,
	})
	selectedCfg = name
	rebuildList()
	setMsg("cfgSaved")
end)

loadBtn.Activated:Connect(function()
	if not selectedCfg then return setMsg("noSelect") end
	if applyData(cfgRead(selectedCfg)) then
		rebuildItemRows()
		applyAccent()
		refreshAll()
		paintLang()
		setMsg("cfgLoaded")
	end
end)

delBtn.Activated:Connect(function()
	if not selectedCfg then return setMsg("noSelect") end
	cfgDelete(selectedCfg)
	selectedCfg = nil
	rebuildList()
	setMsg("cfgDeleted")
end)

-- ================= КНОПКА МЕНЮ СЛЕВА =================
local openBtn = make("TextButton", {
	Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0, 14, 0.5, -25),
	BackgroundColor3 = ACCENTS[S.Accent], TextColor3 = BG, Text = "≡",
	Font = Enum.Font.GothamBlack, TextSize = 26,
}, gui)
round(openBtn, 25)
table.insert(accentObjs, { openBtn, "BackgroundColor3" })
stroke(openBtn, 2)
openBtn.Activated:Connect(function()
	main.Visible = not main.Visible
end)
draggable(openBtn, openBtn)

local function bindCamGuard(o)
	o.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
			freezeCam(true)
		end
	end)
end
bindCamGuard(main)
bindCamGuard(openBtn)
UIS.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
		freezeCam(false)
	end
end)

-- ================= FARM LOGIC =================
local function getHRP()
	local char = LP.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

-- Предметы на земле: workspace, не персонажи игроков, не NPC, не из рюкзака
local function findTargets()
	local res = {}
	local hrp = getHRP()
	if not hrp then return res end
	for _, d in ipairs(workspace:GetDescendants()) do
		if S.Items[d.Name] and (d:IsA("Model") or d:IsA("BasePart") or d:IsA("Tool")) then
			if not inCharacter(d) and not Players:GetPlayerFromCharacter(d) and not hasHumanoidAncestor(d) and not skipped[d] then
				local part = d:IsA("BasePart") and d or d:FindFirstChildWhichIsA("BasePart", true)
				if part and part.Parent then
					table.insert(res, { obj = d, part = part, dist = (part.Position - hrp.Position).Magnitude })
				end
			end
		end
	end
	table.sort(res, function(a, b) return a.dist < b.dist end)
	return res
end

-- Плавный полёт персонажа к точке
local function flyTo(pos)
	local hrp = getHRP()
	if not hrp then return false end
	if S.Teleport then
		hrp.CFrame = CFrame.new(pos)
		hrp.AssemblyLinearVelocity = Vector3.zero
		task.wait(0.1)
		return genv.TRK_YBA_RUN == runId and S.AutoFarm
	end
	local dist = (pos - hrp.Position).Magnitude
	local steps = math.max(2, math.floor(dist / 10))
	local dur = dist / S.FlySpeed
	local start = hrp.CFrame
	local target = CFrame.new(pos)
	for i = 1, steps do
		if genv.TRK_YBA_RUN ~= runId or not S.AutoFarm then return false end
		hrp = getHRP()
		if not hrp then return false end
		hrp.CFrame = start:Lerp(target, i / steps)
		hrp.AssemblyLinearVelocity = Vector3.zero
		task.wait(dur / steps)
	end
	return true
end

local function collectTarget(t)
	if not t.part or not t.part.Parent then return end
	-- Подлетаем сверху предмета
	if not flyTo(t.part.Position + Vector3.new(0, HOVER_HEIGHT, 0)) then return end
	-- Висим над предметом, пока он не исчезнет (подобран), максимум ~6 сек
	local tries = 0
	while genv.TRK_YBA_RUN == runId and S.AutoFarm and t.obj.Parent and t.part.Parent and tries < 20 do
		tries += 1
		local hrp = getHRP()
		if not hrp then return end
		hrp.CFrame = CFrame.new(t.part.Position + Vector3.new(0, HOVER_HEIGHT, 0))
		hrp.AssemblyLinearVelocity = Vector3.zero
		local prompt = t.obj:FindFirstChildWhichIsA("ProximityPrompt", true)
		if prompt and fireproximityprompt then fireproximityprompt(prompt) end
		if firetouchinterest then
			firetouchinterest(hrp, t.part, 0)
			firetouchinterest(hrp, t.part, 1)
		end
		task.wait(0.3)
	end
	if t.obj.Parent and t.part.Parent then skipped[t.obj] = true end
end

-- Точка на земле рядом, чтобы встать и ждать новые вещи
local function findGroundSpot()
	local hrp = getHRP()
	if not hrp then return nil end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { LP.Character }
	for _ = 1, 15 do
		local off = Vector3.new(math.random(-120, 120), 0, math.random(-120, 120))
		local r = workspace:Raycast(hrp.Position + off + Vector3.new(0, 80, 0), Vector3.new(0, -400, 0), params)
		if r then return r.Position + Vector3.new(0, 3, 0) end
	end
	return nil
end

local hopping = false
local function hop()
	if hopping then return end
	hopping = true
	setStatus("hopping")

	local target
	local ok, res = pcall(function()
		local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
		return HttpService:JSONDecode(game:HttpGet(url))
	end)
	if ok and res and res.data then
		local pool = {}
		for _, sv in ipairs(res.data) do
			if sv.id ~= game.JobId and sv.playing < sv.maxPlayers then table.insert(pool, sv.id) end
		end
		if #pool > 0 then target = pool[math.random(1, #pool)] end
	end

	if queue_on_teleport and SCRIPT_URL ~= "" then
		queue_on_teleport(('loadstring(game:HttpGet("%s"))()'):format(SCRIPT_URL))
	end

	if target then
		pcall(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, target, LP)
		end)
	end

	task.delay(8, function()
		hopping = false
		if S.AutoFarm and S.ServerHop then setStatus("hopFail") end
	end)
end

TeleportService.TeleportInitFailed:Connect(function()
	task.delay(5, function() hopping = false end)
	setStatus("hopFail")
end)

-- Основной цикл
task.spawn(function()
	local idleSpot = nil
	while genv.TRK_YBA_RUN == runId do
		if S.AutoFarm and getHRP() then
			local targets = findTargets()
			if #targets > 0 then
				idleSpot = nil
				statusLbl.Text = T("farming") .. " (" .. #targets .. ")"
				collectTarget(targets[1])
			else
				if S.ServerHop then
					idleSpot = nil
					if not hopping then hop() end
				else
					setStatus("waiting")
					if not idleSpot then
						idleSpot = findGroundSpot()
						if idleSpot then flyTo(idleSpot) end
					end
				end
			end
			task.wait(0.2)
		else
			task.wait(0.5)
		end
	end
end)

-- ================= INIT =================
scanItems()
rebuildItemRows()
rebuildList()
applyAccent()
applyLang()
paintTabs()
paintLang()
showTab("func")
if S.AutoFarm then setStatus("farming") end
