--[[
   🐱 Gatinho Auto-Farm Universal v2.0
   - Coleta automática de NPCs no mapa "Field"
   - Venda automática dos NPCs (remoto SellNPC)
   - Coleta de cash do plot (remoto CollectCash)
   - Renascimento automático (remoto Rebirth)
   - GUI fofa, arrastável e temática
   - Reinício automático após morte via GitHub
]]

-- Serviços
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local replicatedStorage = game:GetService("ReplicatedStorage")
local remotes = replicatedStorage:WaitForChild("Remotes")
local plotRemotes = remotes:WaitForChild("Plot")
local remoteFunctions = remotes:WaitForChild("RemoteFunctions")

-- Remotes específicos (patches)
local collectCashRemote = plotRemotes:FindFirstChild("CollectCash") -- RemoteEvent
local sellNPCRemote = plotRemotes:FindFirstChild("SellNPC")         -- RemoteEvent
local rebirthRemote = remoteFunctions:FindFirstChild("Rebirth")    -- RemoteFunction

-- Configurações
local LINK_GITHUB_RAW = "https://github.com/xdg2xyt/meu-bot-roblox/edit/main/gatinho_farm.lua" -- seu link RAW corrigido
local ALTURA_VOO = 350
local TEMPO_ESPERA_VENDA = 0.3
local CASH_PARA_RENASCER = 1000 -- valor mínimo de cash para renascer (ajuste conforme necessário)

-- Variáveis globais
local backpack = player:WaitForChild("Backpack")
local character, humanoid, humanoidRootPart
local posicaoInicial
local executando = false
local conexaoMorte = nil
local autoSell = false
local autoRebirth = false

-- Referências do mapa
local fieldFolder = workspace:WaitForChild("Map"):WaitForChild("Zones"):WaitForChild("Field")
local npcFolder = fieldFolder:WaitForChild("NPC")

-- Função para limpar instâncias antigas do script
local function delementosAntigos()
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui.Name == "GatinhoSpyCollector" then
            gui:Destroy()
        end
    end
end
delementosAntigos()

-- =================== GUI ===================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GatinhoSpyCollector"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 240, 0, 310)  -- altura aumentada para novos botões
MainFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
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

-- Botões principais
local StartButton = Instance.new("TextButton")
StartButton.Size = UDim2.new(0, 200, 0, 32)
StartButton.Position = UDim2.new(0.5, -100, 0, 65)
StartButton.BackgroundColor3 = Color3.fromRGB(150, 230, 150)
StartButton.Text = "Iniciar Rota Estratosfera 🐾"
StartButton.Font = Enum.Font.FredokaOne
StartButton.TextSize = 13
StartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
StartButton.Parent = MainFrame
Instance.new("UICorner", StartButton).CornerRadius = UDim.new(0, 8)

local StopButton = Instance.new("TextButton")
StopButton.Size = UDim2.new(0, 200, 0, 32)
StopButton.Position = UDim2.new(0.5, -100, 0, 105)
StopButton.BackgroundColor3 = Color3.fromRGB(240, 100, 100)
StopButton.Text = "🛑 PARAR E VOLTAR 🐱"
StopButton.Font = Enum.Font.FredokaOne
StopButton.TextSize = 14
StopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
StopButton.Parent = MainFrame
Instance.new("UICorner", StopButton).CornerRadius = UDim.new(0, 8)

local UnloadButton = Instance.new("TextButton")
UnloadButton.Size = UDim2.new(0, 200, 0, 32)
UnloadButton.Position = UDim2.new(0.5, -100, 0, 145)
UnloadButton.BackgroundColor3 = Color3.fromRGB(160, 160, 160)
UnloadButton.Text = "Remover Scripts Antigos 🐾"
UnloadButton.Font = Enum.Font.FredokaOne
UnloadButton.TextSize = 13
UnloadButton.TextColor3 = Color3.fromRGB(255, 255, 255)
UnloadButton.Parent = MainFrame
Instance.new("UICorner", UnloadButton).CornerRadius = UDim.new(0, 8)

-- Toggles de automação
local ToggleSell = Instance.new("TextButton")
ToggleSell.Size = UDim2.new(0, 200, 0, 28)
ToggleSell.Position = UDim2.new(0.5, -100, 0, 185)
ToggleSell.BackgroundColor3 = Color3.fromRGB(255, 180, 180) -- vermelho claro = off
ToggleSell.Text = "Auto Vender NPCs: OFF"
ToggleSell.Font = Enum.Font.FredokaOne
ToggleSell.TextSize = 13
ToggleSell.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleSell.Parent = MainFrame
Instance.new("UICorner", ToggleSell).CornerRadius = UDim.new(0, 8)

local ToggleRebirth = Instance.new("TextButton")
ToggleRebirth.Size = UDim2.new(0, 200, 0, 28)
ToggleRebirth.Position = UDim2.new(0.5, -100, 0, 220)
ToggleRebirth.BackgroundColor3 = Color3.fromRGB(255, 180, 180)
ToggleRebirth.Text = "Auto Renascer: OFF"
ToggleRebirth.Font = Enum.Font.FredokaOne
ToggleRebirth.TextSize = 13
ToggleRebirth.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleRebirth.Parent = MainFrame
Instance.new("UICorner", ToggleRebirth).CornerRadius = UDim.new(0, 8)

-- Botões manuais extras
local SellNowButton = Instance.new("TextButton")
SellNowButton.Size = UDim2.new(0, 200, 0, 28)
SellNowButton.Position = UDim2.new(0.5, -100, 0, 255)
SellNowButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- dourado
SellNowButton.Text = "💰 Vender NPCs Agora"
SellNowButton.Font = Enum.Font.FredokaOne
SellNowButton.TextSize = 13
SellNowButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SellNowButton.Parent = MainFrame
Instance.new("UICorner", SellNowButton).CornerRadius = UDim.new(0, 8)

local RebirthNowButton = Instance.new("TextButton")
RebirthNowButton.Size = UDim2.new(0, 200, 0, 28)
RebirthNowButton.Position = UDim2.new(0.5, -100, 0, 288)
RebirthNowButton.BackgroundColor3 = Color3.fromRGB(180, 130, 255) -- roxo
RebirthNowButton.Text = "🌟 Renascer Agora"
RebirthNowButton.Font = Enum.Font.FredokaOne
RebirthNowButton.TextSize = 13
RebirthNowButton.TextColor3 = Color3.fromRGB(255, 255, 255)
RebirthNowButton.Parent = MainFrame
Instance.new("UICorner", RebirthNowButton).CornerRadius = UDim.new(0, 8)

-- =================== FUNÇÕES AUXILIARES ===================
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
    if not humanoidRootPart or humanoid.Health <= 0 then return end
    local alturaSegura = ALTURA_VOO
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

-- =================== NOVAS FUNÇÕES COM OS REMOTES ===================
local function venderNPCs()
    if not sellNPCRemote then
        StatusLabel.Text = "Remote SellNPC não encontrado!"
        return false
    end

    StatusLabel.Text = "Vendendo NPCs..."
    local ferramentas = backpack:GetChildren()
    local vendidos = 0

    for _, tool in ipairs(ferramentas) do
        if tool:IsA("Tool") and executando then
            humanoid:EquipTool(tool)
            task.wait(0.1)
            -- Dispara o remoto (com o tool como argumento, se necessário)
            local sucesso, erro = pcall(function()
                sellNPCRemote:FireServer(tool) -- alguns jogos esperam o tool; se não, use :FireServer()
            end)
            if sucesso then
                vendidos = vendidos + 1
            else
                warn("Erro ao vender NPC:", erro)
            end
            task.wait(TEMPO_ESPERA_VENDA)
        end
    end

    StatusLabel.Text = vendidos .. " NPC(s) vendido(s)!"
    return vendidos > 0
end

local function coletarCash()
    if not collectCashRemote then
        StatusLabel.Text = "Remote CollectCash não encontrado!"
        return false
    end

    StatusLabel.Text = "Coletando cash..."
    local sucesso, erro = pcall(function()
        collectCashRemote:FireServer()
    end)
    if sucesso then
        StatusLabel.Text = "Cash coletado com sucesso!"
        task.wait(0.5)
        return true
    else
        warn("Erro ao coletar cash:", erro)
        StatusLabel.Text = "Falha ao coletar cash"
        return false
    end
end

local function tentarRenascimento()
    if not rebirthRemote then
        StatusLabel.Text = "Remote Rebirth não encontrado!"
        return false
    end

    -- Verifica se o jogador tem cash suficiente (busca leaderstats)
    local leaderstats = player:FindFirstChild("leaderstats")
    local cashAtual = 0
    if leaderstats then
        local cashStat = leaderstats:FindFirstChild("Cash") or leaderstats:FindFirstChild("Money")
        if cashStat then
            cashAtual = cashStat.Value
        end
    end

    if cashAtual >= CASH_PARA_RENASCER then
        StatusLabel.Text = "Tentando renascer..."
        local sucesso, resultado = pcall(function()
            return rebirthRemote:InvokeServer()
        end)
        if sucesso then
            StatusLabel.Text = "Renascimento concluído!"
            task.wait(1)
            -- Após renascer, o personagem será recriado, devemos aguardar
            player.CharacterAdded:Wait()
            atualizarReferenciasPersonagem()
            return true
        else
            warn("Erro ao renascer:", resultado)
            StatusLabel.Text = "Falha no renascimento"
        end
    else
        StatusLabel.Text = "Cash insuficiente para renascer (" .. cashAtual .. "/" .. CASH_PARA_RENASCER .. ")"
    end
    return false
end

-- =================== LÓGICA PRINCIPAL DE COLETA ===================
local function iniciarColeta()
    if executando then return end
    atualizarReferenciasPersonagem()

    -- Tratamento de morte: reiniciar script via GitHub
    if conexaoMorte then conexaoMorte:Disconnect() end
    conexaoMorte = humanoid.Died:Connect(function()
        executando = false
        StatusLabel.Text = "Status: Reiniciando via GitHub..."
        print("[GatinhoBot] Morte registrada. Puxando arquivo limpo do GitHub...")
        if conexaoMorte then conexaoMorte:Disconnect() end

        player.CharacterAdded:Wait()
        task.wait(2)

        -- Aguarda carregamento dos itens
        while #npcFolder:GetChildren() == 0 do
            task.wait(0.5)
        end

        delementosAntigos()
        task.wait(0.2)

        task.spawn(function()
            local sucesso, erro = pcall(function()
                loadstring(game:HttpGet("https://github.com/xdg2xyt/meu-bot-roblox/raw/main/gatinho_farm.lua"))()
            end)
            if not sucesso then
                warn("[GatinhoBot] Erro ao baixar script: " .. tostring(erro))
            end
        end)
    end)

    -- Verifica se há itens no campo
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
            local distancia = (pivotCFrame.Position - posicaoInicial.Position).Magnitude
            table.insert(itensValidos, {
                model = itemModel,
                cframe = pivotCFrame,
                distancia = distancia
            })
        end
    end

    -- Ordena do mais distante ao mais próximo (coleta do mais longe para o mais perto)
    table.sort(itensValidos, function(a, b) return a.distancia > b.distancia end)

    -- Loop de coleta
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

    -- Retorna ao ponto inicial
    if humanoid.Health > 0 and posicaoInicial then
        StatusLabel.Text = "Status: Retornando..."
        teletransportePeloCeu(posicaoInicial)
    end

    -- Se auto-venda está ativada, vende os NPCs
    if autoSell and executando and humanoid.Health > 0 then
        venderNPCs()
        task.wait(0.5)
        coletarCash()
    end

    -- Se auto-renascimento está ativado e ainda executando
    if autoRebirth and executando and humanoid.Health > 0 then
        tentarRenascimento()
    end

    executando = false
    StatusLabel.Text = "Status: Pronto!"
end

-- =================== CONEXÕES DOS BOTÕES ===================
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

ToggleSell.Activated:Connect(function()
    autoSell = not autoSell
    if autoSell then
        ToggleSell.BackgroundColor3 = Color3.fromRGB(150, 230, 150)
        ToggleSell.Text = "Auto Vender NPCs: ON"
    else
        ToggleSell.BackgroundColor3 = Color3.fromRGB(255, 180, 180)
        ToggleSell.Text = "Auto Vender NPCs: OFF"
    end
end)

ToggleRebirth.Activated:Connect(function()
    autoRebirth = not autoRebirth
    if autoRebirth then
        ToggleRebirth.BackgroundColor3 = Color3.fromRGB(150, 230, 150)
        ToggleRebirth.Text = "Auto Renascer: ON"
    else
        ToggleRebirth.BackgroundColor3 = Color3.fromRGB(255, 180, 180)
        ToggleRebirth.Text = "Auto Renascer: OFF"
    end
end)

SellNowButton.Activated:Connect(function()
    if not executando then
        atualizarReferenciasPersonagem()
        if humanoid.Health > 0 then
            -- Vende os NPCs manuais mesmo sem estar no loop
            local tinhaNpc = venderNPCs()
            if tinhaNpc then
                task.wait(0.3)
                coletarCash()
            end
        end
    else
        StatusLabel.Text = "Pare o farm antes de vender manualmente!"
    end
end)

RebirthNowButton.Activated:Connect(function()
    if not executando then
        atualizarReferenciasPersonagem()
        if humanoid.Health > 0 then
            tentarRenascimento()
        end
    else
        StatusLabel.Text = "Pare o farm antes de renascer!"
    end
end)
