local QBCore = exports['qb-core']:GetCoreObject()

local currentDrugDealer = nil
local isDealerActive = false
local npcTimer = nil 
local warningShown = false 
local dealerBlip = nil


local drugSellers = {} 
local sellerBlips = {}


-- Event handlers
RegisterNetEvent('void-drugselling:sellSpecificDrug')
AddEventHandler('void-drugselling:sellSpecificDrug', function(drugName)
    SellSpecificDrug(drugName)
end)


AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Citizen.SetTimeout(2000, function()
            InitializeDrugSellers()
        end)
    end
end)


AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        RemoveDealerBlip()
        if currentDrugDealer and DoesEntityExist(currentDrugDealer) then
            DeleteEntity(currentDrugDealer)
        end
        CleanupDrugSellers()
    end
end)

function SellSpecificDrug(drugName)
    if isDealerActive then
        QBCore.Functions.Notify('You already have a dealer waiting', 'error')
        return
    end
    

    local drugData = nil
    for _, drug in pairs(Config.Drugs) do
        if drug.name == drugName then
            drugData = drug
            break
        end
    end
    
    if drugData then
        SpawnDrugDealer(drugData)
    else
        QBCore.Functions.Notify('Drug not found in config', 'error')
    end
end

function SpawnDrugDealer(drugData)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    

    local angle = math.random(0, 360) * math.pi / 180
    local spawnCoords = vector3(
        playerCoords.x + math.cos(angle) * Config.NPCSpawn.spawnDistance,
        playerCoords.y + math.sin(angle) * Config.NPCSpawn.spawnDistance,
        playerCoords.z
    )
    

    local groundZ = spawnCoords.z
    local found, groundZ = GetGroundZFor_3dCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z + 10.0, false)
    if not found then
        groundZ = spawnCoords.z
    end
    

    local dealerModel = GetHashKey('a_m_m_business_01')
    RequestModel(dealerModel)
    while not HasModelLoaded(dealerModel) do
        Wait(1)
    end
    
    currentDrugDealer = CreatePed(4, dealerModel, spawnCoords.x, spawnCoords.y, groundZ, 0.0, false, true)
    SetEntityAsMissionEntity(currentDrugDealer, true, true)
    SetPedDiesWhenInjured(currentDrugDealer, false)
    SetPedCanPlayAmbientAnims(currentDrugDealer, true)
    SetPedCanRagdollFromPlayerImpact(currentDrugDealer, false)
    SetEntityInvincible(currentDrugDealer, true)
    FreezeEntityPosition(currentDrugDealer, false) -- Allow movement
    

    PlaceObjectOnGroundProperly(currentDrugDealer)
    
    isDealerActive = true
    

    if Config.Blip.enabled then
        CreateDealerBlip()
    end
    

    if Config.NPCSpawn.walkToPlayer then
        TaskGoToCoordAnyMeans(currentDrugDealer, playerCoords.x, playerCoords.y, playerCoords.z, Config.NPCSpawn.walkSpeed, 0, 0, 786603, 0xbf800000)
        

        Citizen.CreateThread(function()
            while isDealerActive and DoesEntityExist(currentDrugDealer) do
                local npcCoords = GetEntityCoords(currentDrugDealer)
                local distance = #(npcCoords - playerCoords)
                
                if distance <= 3.0 then

                    ClearPedTasks(currentDrugDealer)
                    TaskTurnPedToFaceEntity(currentDrugDealer, playerPed, 2000)
                    break
                end
                Wait(500)
            end
        end)
    else

        TaskTurnPedToFaceEntity(currentDrugDealer, playerPed, 2000)
    end
    
    
    exports.ox_target:addLocalEntity(currentDrugDealer, {
        {
            name = 'sell_drug_to_dealer',
            label = 'Sell ' .. drugData.label,
            icon = 'fas fa-hand-holding-usd',
            distance = 2.0,
            onSelect = function()
                ShowSellingOptions(drugData)
            end
        }
    })
    
    
    StartNPCDurationTimer()
end

function ShowSellingOptions(drugData)
    local playerPed = PlayerPedId()
    
    
    QBCore.Functions.TriggerCallback('QBCore:HasItem', function(hasItem, amount)
        if not hasItem or not amount or amount < 1 then
            QBCore.Functions.Notify('You don\'t have any ' .. drugData.label, 'error')
            return
        end
        
        
        local input = lib.inputDialog('Sell ' .. drugData.label, {
            {
                type = 'select',
                label = 'Selling Type',
                description = 'Choose how to sell your drugs',
                options = {
                    { value = 'single', label = 'Sell 1x (Full Price)', description = '$' .. math.floor(drugData.basePrice * Config.Selling.singlePrice) .. ' per item' },
                    { value = 'bulk', label = 'Sell Bulk (10% Discount)', description = 'Sell ' .. math.min(amount, Config.Selling.maxBulkAmount) .. 'x for 10% off' },
                    { value = 'custom', label = 'Sell Custom Amount', description = 'Choose exact amount' }
                },
                default = 'single'
            }
        })
        
        if not input or not input[1] then return end
        
        local sellType = input[1]
        
        if sellType == 'single' then
            CompleteDrugSale(drugData, 1, Config.Selling.singlePrice)
        elseif sellType == 'bulk' then
            local maxBulk = math.min(amount, Config.Selling.maxBulkAmount)
            CompleteDrugSale(drugData, maxBulk, Config.Selling.bulkPrice)
        elseif sellType == 'custom' then
            ShowCustomAmountDialog(drugData, amount)
        end
        
    end, drugData.name, 1)
end

function ShowCustomAmountDialog(drugData, maxAmount)
    local input = lib.inputDialog('Sell Custom Amount', {
        {
            type = 'number',
            label = 'Amount to sell',
            description = 'Enter amount (1-' .. maxAmount .. ')',
            min = 1,
            max = maxAmount,
            default = 1
        }
    })
    
    if input and input[1] then
        local amount = tonumber(input[1])
        if amount and amount > 0 and amount <= maxAmount then
            local isBulk = amount >= Config.Selling.bulkMinAmount
            local priceMultiplier = isBulk and Config.Selling.bulkPrice or Config.Selling.singlePrice
            CompleteDrugSale(drugData, amount, priceMultiplier)
        else
            QBCore.Functions.Notify('Invalid amount', 'error')
        end
    end
end

function SellDrugToDealer(drugData)
    local playerPed = PlayerPedId()
    
    -- Check if player has the drug
    QBCore.Functions.TriggerCallback('QBCore:HasItem', function(hasItem, amount)
        if hasItem and amount >= 1 then
            CompleteDrugSale(drugData, 1, Config.Selling.singlePrice)
        else
            QBCore.Functions.Notify('You don\'t have any ' .. drugData.label, 'error')
        end
    end, drugData.name, 1)
end

function CompleteDrugSale(drugData, quantity, priceMultiplier)
    local playerPed = PlayerPedId()
    
    
    quantity = quantity or 1
    priceMultiplier = priceMultiplier or Config.Selling.singlePrice
    
    
    RequestAnimDict("mp_common")
    while not HasAnimDictLoaded("mp_common") do
        Wait(10)
    end
    
    TaskPlayAnim(playerPed, "mp_common", "givetake1_a", 8.0, -8.0, 2000, 0, 0, false, false, false)
    
    if currentDrugDealer then
        TaskPlayAnim(currentDrugDealer, "mp_common", "givetake1_b", 8.0, -8.0, 2000, 0, 0, false, false, false)
    end
    
    Wait(2000)
    
    
    local minPrice = drugData.priceRange[1]
    local maxPrice = drugData.priceRange[2]
    local basePrice = math.random(minPrice, maxPrice)
    local finalPrice = math.floor(basePrice * priceMultiplier * quantity)
    
    
    TriggerServerEvent('void-drugselling:completeDrugSale', {
        drugName = drugData.name,
        quantity = quantity,
        price = finalPrice
    })
    
    
    npcTimer = nil
    isDealerActive = false -- Reset dealer active state immediately
    MakeDealerWalkAway()
    
    
    local priceType = (priceMultiplier < 1.0) and " (Bulk Discount)" or ""
    QBCore.Functions.Notify('Deal completed! You received $' .. finalPrice .. ' black money for ' .. quantity .. 'x ' .. drugData.label .. priceType, 'success')
end

function CreateDealerBlip()
    if not currentDrugDealer or not DoesEntityExist(currentDrugDealer) then return end
    
    
    if dealerBlip then
        RemoveBlip(dealerBlip)
        dealerBlip = nil
    end
    
    
    dealerBlip = AddBlipForEntity(currentDrugDealer)
    SetBlipSprite(dealerBlip, Config.Blip.sprite)
    SetBlipDisplay(dealerBlip, 4)
    SetBlipScale(dealerBlip, Config.Blip.scale)
    SetBlipColour(dealerBlip, Config.Blip.color)
    SetBlipAsShortRange(dealerBlip, Config.Blip.shortRange)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Blip.name)
    EndTextCommandSetBlipName(dealerBlip)
    
    print("^2Void Drug Selling: Dealer blip created^7")
end

function RemoveDealerBlip()
    if dealerBlip then
        RemoveBlip(dealerBlip)
        dealerBlip = nil
        print("^2Void Drug Selling: Dealer blip removed^7")
    end
end

function StartNPCDurationTimer()
    if npcTimer then return end -- Prevent multiple timers
    
    warningShown = false
    npcTimer = true
    
    

    

    Citizen.SetTimeout(Config.NPCDuration.stayTime, function()
        if currentDrugDealer and DoesEntityExist(currentDrugDealer) and isDealerActive then
            MakeDealerWalkAway()
        end
        npcTimer = nil
    end)
end

function MakeDealerWalkAway()
    if currentDrugDealer and DoesEntityExist(currentDrugDealer) then
        exports.ox_target:removeLocalEntity(currentDrugDealer, 'sell_drug_to_dealer')
        

        RemoveDealerBlip()
        

        RequestAnimDict("mp_common")
        while not HasAnimDictLoaded("mp_common") do
            Wait(10)
        end
        

        TaskPlayAnim(currentDrugDealer, "mp_common", "givetake1_b", 8.0, -8.0, 1000, 0, 0, false, false, false)
        

        Citizen.SetTimeout(1000, function()
            if currentDrugDealer and DoesEntityExist(currentDrugDealer) then
                print("^2Void Drug Selling: Starting NPC walk-away sequence^7")
                

                FreezeEntityPosition(currentDrugDealer, false)
                ClearPedTasks(currentDrugDealer)
                
                MakeNPCWalkAwayAndDisappear()
            else
                print("^1Void Drug Selling: NPC not found for walk-away after timeout^7")
            end
        end)
    else
        isDealerActive = false
        npcTimer = nil 
        RemoveDealerBlip()
    end
end

function MakeNPCWalkAwayAndDisappear()
    if not currentDrugDealer or not DoesEntityExist(currentDrugDealer) then 
        print("^1Void Drug Selling: NPC not found for walk-away^7")
        return 
    end
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local npcCoords = GetEntityCoords(currentDrugDealer)
    

    local walkDistance = math.random(Config.NPCWalkAway.minDistance, Config.NPCWalkAway.maxDistance)
    

    local angle = math.random(0, 360) * math.pi / 180
    local walkAwayCoords = vector3(
        npcCoords.x + math.cos(angle) * walkDistance,
        npcCoords.y + math.sin(angle) * walkDistance,
        npcCoords.z
    )
    

    local groundZ = walkAwayCoords.z
    local found, groundZ = GetGroundZFor_3dCoord(walkAwayCoords.x, walkAwayCoords.y, walkAwayCoords.z + 10.0, false)
    if not found then
        groundZ = walkAwayCoords.z
    end
    
    print("^2Void Drug Selling: NPC walking away to distance: " .. walkDistance .. " meters^7")
    print("^2Void Drug Selling: Destination coords: " .. walkAwayCoords.x .. ", " .. walkAwayCoords.y .. ", " .. groundZ .. "^7")
    

    TaskGoToCoordAnyMeans(currentDrugDealer, walkAwayCoords.x, walkAwayCoords.y, groundZ, Config.NPCWalkAway.walkSpeed, 0, 0, 786603, 0xbf800000)
    

    Citizen.SetTimeout(1000, function()
        if DoesEntityExist(currentDrugDealer) then
            local taskStatus = GetScriptTaskStatus(currentDrugDealer, 0x667C0FC4) -- TASK_GO_TO_COORD_ANY_MEANS
            print("^2Void Drug Selling: Task status: " .. taskStatus .. "^7")
        end
    end)
    

    Citizen.CreateThread(function()
        local startTime = GetGameTimer()
        local maxWalkTime = 30000 -- Maximum 30 seconds to walk
        
        while isDealerActive and DoesEntityExist(currentDrugDealer) do
            local currentCoords = GetEntityCoords(currentDrugDealer)
            local distanceToDestination = #(currentCoords - walkAwayCoords)
            local timeElapsed = GetGameTimer() - startTime
            

            if distanceToDestination <= 5.0 or timeElapsed > maxWalkTime then

                Citizen.SetTimeout(Config.NPCWalkAway.disappearDelay, function()
                    if DoesEntityExist(currentDrugDealer) then

                        SetEntityAlpha(currentDrugDealer, 0, false)
                        Wait(500)
                        DeleteEntity(currentDrugDealer)
                    end
                    currentDrugDealer = nil
                    isDealerActive = false
                    npcTimer = nil
                end)
                break
            end
            
            Wait(1000)
        end
    end)
end


function InitializeDrugSellers()
    if not Config.DrugSeller.enabled then return end
    
    for i, location in pairs(Config.DrugSeller.locations) do
        SpawnDrugSellerAtLocation(i, location)
    end
end

function SpawnDrugSellerAtLocation(locationId, location)
    local modelName = Config.DrugSeller.npcModels[math.random(1, #Config.DrugSeller.npcModels)]
    local modelHash = GetHashKey(modelName)
    
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(1)
    end
    
    local seller = CreatePed(4, modelHash, location.coords.x, location.coords.y, location.coords.z, location.heading, false, true)
    
    if DoesEntityExist(seller) then
        SetEntityAsMissionEntity(seller, true, true)
        SetPedDiesWhenInjured(seller, false)
        SetPedCanPlayAmbientAnims(seller, false)
        SetPedCanRagdollFromPlayerImpact(seller, false)
        SetEntityInvincible(seller, true)
        FreezeEntityPosition(seller, true)
        SetPedCanBeTargetted(seller, false)
        SetPedCanBeDraggedOut(seller, false)
        SetPedCanBeTargettedByPlayer(seller, PlayerId(), false)
        SetBlockingOfNonTemporaryEvents(seller, true)
        SetPedFleeAttributes(seller, 0, false)
        SetPedCombatAttributes(seller, 17, false) 
        SetPedCombatAttributes(seller, 5, false)
        SetPedCombatAttributes(seller, 46, false)
        SetPedRelationshipGroupHash(seller, GetHashKey("CIVMALE"))

        drugSellers[locationId] = {
            ped = seller,
            location = location,
            active = true
        }
        

        CreateSellerBlip(locationId, location)
        

        AddSellerInteraction(locationId, seller)
        
        print("^2Void Drug Selling: Drug seller spawned at location " .. locationId .. "^7")
    else
        print("^1Void Drug Selling: Failed to spawn seller at location " .. locationId .. "^7")
    end
end

function CreateSellerBlip(locationId, location)
    if not location.blip.enabled then return end
    
    local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
    SetBlipSprite(blip, location.blip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, location.blip.scale)
    SetBlipColour(blip, location.blip.color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(location.blip.name)
    EndTextCommandSetBlipName(blip)
    
    sellerBlips[locationId] = blip
end

function AddSellerInteraction(locationId, seller)
    if not seller or not DoesEntityExist(seller) then return end
    
    exports.ox_target:addLocalEntity(seller, {
        {
            name = 'buy_from_drug_seller_' .. locationId,
            label = 'Buy from Drug Seller',
            icon = 'fas fa-shopping-cart',
            distance = 2.0,
            onSelect = function()
                ShowBuyingOptions()
            end
        }
    })
end

function CleanupDrugSellers()
    for locationId, sellerData in pairs(drugSellers) do
        if sellerData.ped and DoesEntityExist(sellerData.ped) then
            exports.ox_target:removeLocalEntity(sellerData.ped, 'buy_from_drug_seller_' .. locationId)
            DeleteEntity(sellerData.ped)
        end
    end
    
    for locationId, blip in pairs(sellerBlips) do
        if blip then
            RemoveBlip(blip)
        end
    end
    
    drugSellers = {}
    sellerBlips = {}
end

function ShowBuyingOptions()
    local options = {}
    

    for _, item in pairs(Config.DrugSeller.sellableItems) do
        table.insert(options, {
            title = item.label,
            description = item.description .. ' - $' .. item.price .. ' (Stock: ' .. item.stock .. ')',
            icon = 'nui://ox_inventory/web/images/' .. item.image,
            onSelect = function()
                ShowItemPurchaseDialog(item)
            end
        })
    end
    
    if #options == 0 then
        QBCore.Functions.Notify('No items available for purchase', 'error')
        return
    end
    
    lib.registerContext({
        id = 'drug_seller_menu',
        title = 'Drug Seller Inventory',
        options = options
    })
    
    lib.showContext('drug_seller_menu')
end

function ShowItemPurchaseDialog(item)
    local input = lib.inputDialog('Purchase ' .. item.label, {
        {
            type = 'number',
            label = 'Amount',
            description = 'How many to buy (Max: ' .. item.stock .. ')',
            min = 1,
            max = item.stock,
            default = 1
        }
    })
    
    if not input or not input[1] then return end
    
    local amount = tonumber(input[1])
    if not amount or amount < 1 or amount > item.stock then
        QBCore.Functions.Notify('Invalid amount', 'error')
        return
    end
    
    local totalPrice = item.price * amount
    
    local confirm = lib.alertDialog({
        header = 'Confirm Purchase',
        content = 'Buy ' .. amount .. 'x ' .. item.label .. ' for $' .. totalPrice .. '?',
        centered = true,
        cancel = true
    })
    
    if confirm == 'confirm' then
        CompleteItemPurchase(item, amount, totalPrice)
    end
end

function CompleteItemPurchase(item, amount, totalPrice)
    TriggerServerEvent('void-drugselling:buyFromSeller', {
        item = item.item,
        amount = amount,
        price = totalPrice
    })
end

