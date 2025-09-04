local QBCore = exports['qb-core']:GetCoreObject()



function GetPlayer(src)
    return QBCore.Functions.GetPlayer(src)
end

function HasDrug(Player, drugName, quantity)
    local item = Player.Functions.GetItemByName(drugName)
    return item and item.amount >= quantity
end

QBCore.Functions.CreateCallback('QBCore:HasItem', function(source, cb, itemName, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb(false, 0) end
    
    amount = amount or 1
    local item = Player.Functions.GetItemByName(itemName)
    
    if item and item.amount >= amount then
        cb(true, item.amount)
    else
        cb(false, item and item.amount or 0)
    end
end)

RegisterServerEvent('void-drugselling:sellSpecificDrug')
AddEventHandler('void-drugselling:sellSpecificDrug', function(drugName)
    local src = source
    local Player = GetPlayer(src)
    
    if Player then
        local itemData = Player.Functions.GetItemByName(drugName)
        if itemData and itemData.amount > 0 then
            print("^2Void Drug Selling: Player " .. src .. " used selldrug button on " .. drugName .. "^7")
            TriggerClientEvent('void-drugselling:sellSpecificDrug', src, drugName)
        else
            TriggerClientEvent('QBCore:Notify', src, 'You don\'t have any ' .. drugName, 'error')
        end
    end
end)

RegisterServerEvent('void-drugselling:completeDrugSale')
AddEventHandler('void-drugselling:completeDrugSale', function(saleData)
    local src = source
    local Player = GetPlayer(src)
    
    if not Player then return end
    
    local drugName = saleData.drugName
    local quantity = tonumber(saleData.quantity) or 1
    local price = tonumber(saleData.price) or 200
    
    print("^2VOID DRUG SALE: " .. drugName .. " x" .. quantity .. " for $" .. price .. "^7")
    
    if not HasDrug(Player, drugName, quantity) then
        print("^1Player missing drugs: " .. drugName .. " x" .. quantity .. "^7")
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t have ' .. quantity .. 'x ' .. drugName, 'error')
        return
    end
    
    Player.Functions.RemoveItem(drugName, quantity)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[drugName], 'remove', quantity)
    Player.Functions.AddItem('black_money', price)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['black_money'], 'add', price)
    
    local playerName = Player.PlayerData.name
    
    print("^2VOID DRUG SALE COMPLETED: " .. playerName .. 
        " - " .. drugName .. " x" .. quantity .. 
        " for $" .. price .. "^7")
end)
RegisterServerEvent('void-drugselling:sellToBuyer')
AddEventHandler('void-drugselling:sellToBuyer', function(saleData)
    local src = source
    local Player = GetPlayer(src)
    
    if not Player then return end
    
    local drugName = saleData.drugName
    local quantity = tonumber(saleData.quantity) or 1
    local price = tonumber(saleData.price) or 0
    
    local hasDrug = HasDrug(Player, drugName, quantity)
    if not hasDrug then
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t have enough drugs', 'error')
        return
    end
    
    Player.Functions.RemoveItem(drugName, quantity)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[drugName], 'remove', quantity)
    
    Player.Functions.AddMoney('cash', price)
    
    local playerName = Player.PlayerData.name
    
    print("^2VOID DRUG SALE TO BUYER: " .. playerName .. 
        " - " .. drugName .. " x" .. quantity .. 
        " for $" .. price .. "^7")
end)

RegisterServerEvent('void-drugselling:buyFromSeller')
AddEventHandler('void-drugselling:buyFromSeller', function(purchaseData)
    local src = source
    local Player = GetPlayer(src)
    
    if not Player then return end
    
    local itemName = purchaseData.item
    local amount = tonumber(purchaseData.amount) or 1
    local price = tonumber(purchaseData.price) or 0
    
    local itemConfig = nil
    for _, item in pairs(Config.DrugSeller.sellableItems) do
        if item.item == itemName then
            itemConfig = item
            break
        end
    end
    
    if not itemConfig then
        TriggerClientEvent('QBCore:Notify', src, 'Item not available', 'error')
        return
    end
    
    if amount > itemConfig.stock then
        TriggerClientEvent('QBCore:Notify', src, 'Not enough stock available', 'error')
        return
    end
    
    if Config.DrugSeller.moneyType == "black_money" then
        local blackMoneyItem = Player.Functions.GetItemByName('black_money')
        local playerBlackMoney = blackMoneyItem and blackMoneyItem.amount or 0
        
        if playerBlackMoney < price then
            TriggerClientEvent('QBCore:Notify', src, 'Not enough black money', 'error')
            return
        end
        
        Player.Functions.RemoveItem('black_money', price)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['black_money'], 'remove', price)
    else
        local playerMoney = Player.PlayerData.money['cash']
        if playerMoney < price then
            TriggerClientEvent('QBCore:Notify', src, 'Not enough money', 'error')
            return
        end
        
        Player.Functions.RemoveMoney('cash', price)
    end
    
    -- Give item to player
    Player.Functions.AddItem(itemName, amount)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'add', amount)
    
    itemConfig.stock = itemConfig.stock - amount
    
    local moneyTypeText = Config.DrugSeller.moneyType == "black_money" and "black money" or "money"
    TriggerClientEvent('QBCore:Notify', src, 'Purchased ' .. amount .. 'x ' .. itemConfig.label .. ' for $' .. price .. ' ' .. moneyTypeText, 'success')
    
    local playerName = Player.PlayerData.name
    
    print("^2VOID DRUG PURCHASE: " .. playerName .. 
        " - Bought " .. itemName .. " x" .. amount .. 
        " for $" .. price .. "^7")
end)


