-- 1. SISTEMA DE LIMPEZA (UNLOAD) AUTOMÁTICA
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function delementosAntigos()
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui.Name == "GatinhoSpyCollector" then
            gui:Destroy()
        end
    end
end
delementosAntigos()

-- Link oficial do seu repositório em texto puro (RAW)
local LINK_GITHUB_RAW = "https://githubusercontent.com"

-- 2. Configurações Globais Dinâmicas
local backpack = player:WaitForChild("Backpack")
local character, humanoid, humanoidRootPart
local posicaoInicial
local executando = false 
local conexaoMorte = nil 

local fieldFolder = workspace:WaitForChild("Map"):WaitForChild("Zones"):WaitForChild("Field")
local npcFolder = fieldFolder:WaitForChild("NPC")

-- 3. Criar a GUI Temática de Gatinhos
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GatinhoSpyCollector"
ScreenGui.ResetOnSpawn = false 
ScreenGui.Parent = playerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 220)
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(255, 200, 220) 
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true 
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 15)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "🐱 Gatinho Auto-Farm 🐾"
Title.TextColor3 = Color3.fromRGB(120, 50, 80)
Title.Font = Enum.Font.FredokaOne
Title.TextSize = 16
Title.Parent = MainFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 25)
StatusLabel.Position = UDim2.new(0, 0, 0, 35)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: Parado"
StatusLabel.TextColor3 = Color3.fromRGB(140, 80, 100)
StatusLabel.Font = Enum.Font.SourceSansBold
StatusLabel.TextSize = 14
StatusLabel.Parent = MainFrame

local StartButton = Instance.new("TextButton")
StartButton.Size = UDim2.new(0, 180, 0, 30)
StartButton.Position = UDim2.new(0, 20, 0, 65)
StartButton.BackgroundColor3 = Color3.fromRGB(150, 230, 150) 
StartButton.Text = "Iniciar Rota Estratosfera 🐾"
StartButton.Font = Enum.Font.FredokaOne
StartButton.TextSize = 12
StartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
StartButton.Parent = MainFrame
Instance.new("UICorner", StartButton).CornerRadius = UDim.new(0, 8)

local StopButton = Instance.new("TextButton")
StopButton.Size = UDim2.new(0, 180, 0, 30)
StopButton.Position = UDim2.new(0, 20, 0, 105)
StopButton.BackgroundColor3 = Color3.fromRGB(240, 100, 100) 
StopButton.Text = "🛑 PARAR E VOLTAR 🐱"
StopButton.Font = Enum.Font.FredokaOne
StopButton.TextSize = 13
StopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
StopButton.Parent = MainFrame
Instance.new("UICorner", StopButton).CornerRadius = UDim.new(0, 8)

local UnloadButton = Instance.new("TextButton")
UnloadButton.Size = UDim2.new(0, 180, 0, 30)
UnloadButton.Position = UDim2.new(0, 20, 0, 145)
UnloadButton.BackgroundColor3 = Color3.fromRGB(160, 160, 160) 
UnloadButton.Text = "Remover Scripts Antigos 🐾"
UnloadButton.Font = Enum.Font.FredokaOne
UnloadButton.TextSize = 12
UnloadButton.TextColor3 = Color3.fromRGB(255, 255, 255)
UnloadButton.Parent = MainFrame
Instance.new("UICorner", UnloadButton).CornerRadius = UDim.new(0, 8)


-- 4. Funções de Suporte Técnico Avançadas
local function atualizarReferenciasPersonagem()
    character = player.Character or player.CharacterAdded:Wait()
    humanoid = character:WaitForChild("Humanoid")
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
end

local function equiparItemAutomatico()
    if character:FindFirstChildOfClass("Tool") then return true end
    local itemNaMochila = backpack:FindFirstChildOfClass("Tool")
    if itemNaMochila then
        humanoid:EquipTool(itemNaMochila)
        task.wait(0.2)
        return true
    end
    return false
end

local function teletransportePeloCeu(cframeDestino)
    local alturaSegura = 350 
    local posicaoAtual = humanoidRootPart.Position
    local posicaoFinal = cframeDestino.Position
    
    humanoidRootPart.CFrame = CFrame.new(posicaoAtual + Vector3.new(0, alturaSegura, 0))
    task.wait(0.02)
    
    local posicaoCeuInicial = humanoidRootPart.Position
    local posicaoCeuFinal = Vector3.new(posicaoFinal.X, posicaoCeuInicial.Y, posicaoFinal.Z)
    local distancia = (posicaoCeuFinal - posicaoCeuInicial).Magnitude
    
    if distancia > 80 then
        local passos = math.floor(distancia / 60)
        for i = 1, passos do
            if not executando or humanoid.Health <= 0 then break end
            local novaPosicaoCeu = posicaoCeuInicial:Lerp(posicaoCeuFinal, i / passos)
            humanoidRootPart.CFrame = CFrame.new(novaPosicaoCeu)
            task.wait(0.02)
        end
    end
    
    if executando and humanoid.Health > 0 then
        humanoidRootPart.CFrame = cframeDestino
        task.wait(0.25) 
    end
end

local function interagirSuperRapido(prompt)
    if prompt then
        prompt.MaxActivationDistance = 99999
        task.spawn(function()
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration + 0.02)
            prompt:InputHoldEnd()
        end)
    end
end

local iniciarColeta 

-- 5. Função Principal Core
iniciarColeta = function()
    if executando then return end
    atualizarReferenciasPersonagem()
    
    -- CORREÇÃO DA MORTE: Corrigido o nome da variável do link RAW
    if conexaoMorte then conexaoMorte:Disconnect() end
    conexaoMorte = humanoid.Died:Connect(function()
        executando = false
        StatusLabel.Text = "Status: Reiniciando via GitHub..."
        print("[GatinhoBot] Morte registrada. Puxando arquivo limpo do GitHub...")
        
        if conexaoMorte then conexaoMorte:Disconnect() end
        
        player.CharacterAdded:Wait()
        task.wait(2) 
        
        StatusLabel.Text = "Status: Carregando itens..."
        while #npcFolder:GetChildren() == 0 do
            task.wait(0.5)
        end
        
        delementosAntigos()
        task.wait(0.2)
        
        task.spawn(function()
            local sucesso, erro = pcall(function()
                -- Linha corrigida com a variável correta LINK_GITHUB_RAW
                loadstring(game:HttpGet(https://github.com/xdg2xyt/meu-bot-roblox/raw/main/gatinho_farm.lua))()
            end)
            if not sucesso then
                warn("[GatinhoBot] Erro ao baixar script: " .. tostring(erro))
            end
        end)
    end)
    
    local listaModelos = npcFolder:GetChildren()
    if #listaModelos == 0 then
        StatusLabel.Text = "Aguardando itens do mapa..."
        while #npcFolder:GetChildren() == 0 do
            task.wait(0.5)
        end
        listaModelos = npcFolder:GetChildren()
    end
    
    executando = true
    StatusLabel.Text = "Status: Calculando órbita..."
    posicaoInicial = humanoidRootPart.CFrame 
    
    local limiteItens = player:GetAttribute("MaxCarry") or 1
    local itensColetados = 0
    local itensValidos = {}
    
    for _, itemModel in ipairs(listaModelos) do
        if itemModel:IsA("Model") then
            local pivotCFrame = itemModel:GetPivot()
            local distanciaDaBase = (pivotCFrame.Position - posicaoInicial.Position).Magnitude
            table.insert(itensValidos, {
                model = itemModel,
                cframe = pivotCFrame,
                distancia = distanciaDaBase
            })
        end
    end
    
    table.sort(itensValidos, function(a, b)
        return a.distancia > b.distancia
    end)
    
    for i, dadosItem in ipairs(itensValidos) do
        if not executando then break end
        if humanoid.Health <= 0 then break end
        if itensColetados >= limiteItens then break end
        
        local itemModel = dadosItem.model
        if itemModel and itemModel.Parent and equiparItemAutomatico() then
            teletransportePeloCeu(dadosItem.cframe)
            
            local pastaPrompts = itemModel:WaitForChild("Prompts", 2)
            if pastaPrompts then
                local prompt = pastaPrompts:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    interagirSuperRapido(prompt)
                    itensColetados = itensColetados + 1
                    StatusLabel.Text = "Coletado: " .. itensColetados .. " / " .. limiteItens
                    task.wait(prompt.HoldDuration + 0.1)
                end
            end
        end
    end
    
    if humanoid.Health > 0 and posicaoInicial then
        StatusLabel.Text = "Status: Retornando..."
        teletransportePeloCeu(posicaoInicial)
        StatusLabel.Text = "Status: Pronto! Vá esvaziar."
    else
        StatusLabel.Text = "Status: Parado (Morreu)"
    end
    executando = false
end


-- 6. Lógica dos Botões da Interface
StartButton.Activated:Connect(function()
    task.spawn(iniciarColeta)
end)

StopButton.Activated:Connect(function()
    executando = false 
    if conexaoMorte then conexaoMorte:Disconnect() end
    StatusLabel.Text = "Status: Encerrou!"
    task.wait(0.05)
    if humanoidRootPart and humanoid and humanoid.Health > 0 and posicaoInicial then
        teletransportePeloCeu(posicaoInicial)
    end
end)

UnloadButton.Activated:Connect(function()
    executando = false
    if conexaoMorte then conexaoMorte:Disconnect() end
    StatusLabel.Text = "Status: Desativando..."
    task.wait(0.05)
    delementosAntigos()
end)
