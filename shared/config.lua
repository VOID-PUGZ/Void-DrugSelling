Config = {}

-- NPC Duration Configuration
Config.NPCDuration = {
    stayTime = 30000, -- How long NPC stays before auto-disappearing (30 seconds)
    warningTime = 10000, -- Warning time before disappearing (10 seconds)
    warningMessage = "The dealer is getting impatient and will leave soon..."
}

-- NPC Spawn Configuration
Config.NPCSpawn = {
    spawnDistance = 15.0, -- Distance from player to spawn NPC
    walkSpeed = 1.0, -- Speed NPC walks towards player
    walkToPlayer = true -- Whether NPC should walk towards player
}

-- NPC Walk Away Configuration
Config.NPCWalkAway = {
    minDistance = 50.0, -- Minimum distance NPC walks away (meters)
    maxDistance = 150.0, -- Maximum distance NPC walks away (meters)
    walkSpeed = 1.2, -- Speed NPC walks away (slightly faster than approach)
    disappearDelay = 2000 -- Delay before disappearing after reaching destination (ms)
}

-- Blip Configuration
Config.Blip = { -- Blip for when drug Dealer Walks Towards Player
    enabled = true, -- Enable/disable blip on map
    sprite = 280, -- Blip sprite (280 = person)
    color = 2, -- Blip color (2 = green)
    scale = 0.8, -- Blip scale
    name = "Drug Dealer", -- Blip name
    shortRange = true -- Short range blip
}

-- Selling Configuration
Config.Selling = {
    bulkDiscount = 0.10, -- 10% discount for bulk selling (0.10 = 10%)
    bulkMinAmount = 2, -- Minimum amount for bulk selling
    maxBulkAmount = 10, -- Maximum amount for bulk selling
    singlePrice = 1.0, -- Full price multiplier for single sales (1.0 = 100%)
    bulkPrice = 0.9 -- Bulk price multiplier (0.9 = 90% of base price)
}

-- Drug Seller Configuration
Config.DrugSeller = {
    enabled = true, -- Enable/disable drug seller system
    npcModels = {
        "g_m_m_armlieut_01",
        "g_m_m_armgoon_01", 
        "g_m_m_armgoon_02",
        "g_m_m_armboss_01",
        "g_m_m_chigoon_01",
        "g_m_m_chigoon_02"
    },
    -- Money type options for purchases
    moneyType = "black_money", -- Options: "money" or "black_money"
    -- Fixed locations where drug sellers spawn
    locations = {
        {
            coords = vec3(1247.98, -2579.08, 42.83-1),
            heading = 294.11,
            blip = {
                enabled = false,
                sprite = 280,
                color = 1,
                scale = 0.8,
                name = "Drug Seller"
            }
        },
        -- add more locations as neeed if npc is floating in air put a -1 after the z coordinate
    },
    buying = {
        markup = 0.15, -- 15% markup on base price when buying from player
        minAmount = 1,
        maxAmount = 5
    },
    -- Items that the drug seller sells to players
    sellableItems = {
        {
            item = "resource_empty_jar",
            label = "Empty Jar",
            price = 50,
            stock = 150, -- How many the seller has
            description = "Empty Jar",
            image = "resource_empty_jar.png"
        },
    }
}


Config.Drugs = { -- Sellable Drugs
    {
        name = "marijuana_jar1",
        label = "Marijuana Jar",
        streetName = "Green", 
        basePrice = 400,
        priceRange = {400, 800}
    },
    {
        name = "coke_baggy",
        label = "Cocaine Baggy", 
        streetName = "Snow",
        basePrice = 550,
        priceRange = {500, 600}
    },
    {
        name = "meth_baggy",
        label = "Meth Baggy",
        streetName = "Ice",
        basePrice = 380,
        priceRange = {350, 410}
    },
    {
        name = "mega_death",  
        label = "Mega Death", 
        streetName = "Mega Death",
        basePrice = 450,
        priceRange = {400, 500}
    }
}
