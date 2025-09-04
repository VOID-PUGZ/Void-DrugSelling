# Void Drug Selling Script

A comprehensive FiveM drug dealing script with QBCore framework support, featuring both selling drugs to NPCs and buying supplies from drug sellers.

## 🚀 Features

### **Drug Selling System**
- **NPC Dealers**: Spawn drug dealers that walk towards you
- **Multiple Selling Options**: 
  - Single item at full price
  - Bulk selling with 10% discount
  - Custom amount selling
- **Smart Pricing**: Random price ranges with configurable multipliers
- **Inventory Integration**: Full QBCore inventory support
- **Map Blips**: Visual indicators for active dealers
- **NPC Behavior**: Dealers walk away after transactions

### **Drug Seller System**
- **Fixed Locations**: Permanent drug sellers at 4 locations
- **ox_lib Context Menu**: Beautiful item selection with images
- **Flexible Payment**: Choose between money or black money
- **Stock System**: Limited quantities per item
- **Visual Interface**: ox_inventory images in context menu
- **Frozen NPCs**: Sellers stay in place and don't react to players

### **Configuration Options**
- **Customizable Locations**: Set your own coordinates
- **Price Management**: Configure all drug prices and ranges
- **Payment Types**: Switch between money and black money
- **NPC Models**: Choose from various gang member models
- **Selling Options**: Configure bulk discounts and limits

## 📋 Requirements

- **QBCore Framework**
- **ox_lib** (for context menus and input dialogs)
- **ox_target** (for NPC interactions)
- **ox_inventory** (for item images)

## 🛠️ Installation

1. **Download** the script to your `resources` folder
2. **Add to server.cfg**:
   ```
   ensure Void-DrugSelling
   ```
3. **Restart** your server

## ⚙️ Configuration

### **Basic Settings** (`shared/config.lua`)

```lua
-- Enable/disable the entire system
Config.DrugSeller = {
    enabled = true,
    moneyType = "money", -- "money" or "black_money"
    -- ... more options
}
```

### **Drug Seller Locations**
```lua
locations = {
    {
        coords = vec3(109.05, -1948.48, 20.74-1), -- Grove Street
        heading = 27.85,
        blip = {
            enabled = true,
            name = "Drug Seller - Grove Street"
        }
    },
    -- ... more locations
}
```

### **Sellable Items**
```lua
sellableItems = {
    {
        item = "resource_empty_jar",
        label = "Empty Jar",
        price = 50,
        stock = 150,
        description = "High quality marijuana",
        image = "resource_empty_jar.png"
    },
    -- ... more items
}
```

## 🎮 How to Use

### **Selling Drugs to Dealers**
1. **Get Drugs**: Obtain drugs from your inventory
2. **Call Dealer**: Use the command or item to spawn a dealer
3. **Wait**: Dealer will walk towards your location
4. **Interact**: Target the dealer when they arrive
5. **Choose Option**: Select single, bulk, or custom amount
6. **Complete Sale**: Receive black money for your drugs

### **Buying from Drug Sellers**
1. **Visit Location**: Go to any drug seller location (marked on map)
2. **Target NPC**: Use ox_target on the seller
3. **Browse Items**: View available items with prices and stock
4. **Select Item**: Choose what you want to buy
5. **Enter Amount**: Specify how many you want
6. **Confirm Purchase**: Complete the transaction

## 🗺️ Locations

The script includes 4 default drug seller locations:

1. **Grove Street** - `vec3(109.05, -1948.48, 20.74-1)`
2. **East Los Santos** - `vec3(1274.33, -1714.55, 54.77)`
3. **Sandy Shores** - `vec3(1692.62, 3759.50, 34.70)`
4. **Grapeseed** - `vec3(2433.33, 4968.37, 42.35)`

## 💰 Payment System

### **Money Types**
- **Regular Money**: Uses player's cash
- **Black Money**: Uses black_money items from inventory

### **Pricing**
- **Base Prices**: Set in config for each item
- **Bulk Discounts**: 10% off for bulk purchases
- **Random Ranges**: Prices vary within configured ranges

## 🎨 Customization

### **Adding New Items**
```lua
["CUSTOMITEM"] = { -- spawn code
    label = "CUSTOMITEM", -- label
    weight = 50,
    stack = true,
    close = true,
    buttons = {
        {
            label = "Sell Drug",
            action = function(slot)
                TriggerServerEvent('void-drugselling:sellSpecificDrug', 'CUSTOMITEM')-- same as spawncode
            end
        }
    }
},
```

### **Adding New Locations**
```lua
{
    coords = vec3(x, y, z),
    heading = 0.0,
    blip = {
        enabled = true,
        name = "Your Location Name"
    }
}
```

### **Changing NPC Models**
```lua
npcModels = {
    "g_m_m_armlieut_01",
    "g_m_m_armgoon_01",
    -- Add more models
}
```

## 🔧 Commands

- **Spawn Dealer**: Use the configured command to spawn a drug dealer
- **Admin Commands**: Various admin commands for testing and management

## 📱 ox_lib Integration

The script uses ox_lib for:
- **Context Menus**: Beautiful item selection interface
- **Input Dialogs**: Amount selection and confirmation
- **Alert Dialogs**: Purchase confirmations
- **Notifications**: Success and error messages

## 🎯 ox_target Integration

- **NPC Interactions**: Target drug dealers and sellers
- **Distance Checking**: Automatic interaction range
- **Icon Support**: Custom icons for different interactions

## 🖼️ Image Support

- **ox_inventory Images**: Uses images from `ox_inventory/web/images/`
- **Context Menu Icons**: Shows item images in selection menu
- **Custom Images**: Add your own item images

## 🛡️ Security Features

- **Server Validation**: All transactions validated server-side
- **Money Checking**: Verifies player has sufficient funds
- **Stock Management**: Prevents overselling
- **Anti-Exploit**: Prevents duplication and cheating

## 🐛 Troubleshooting

### **Common Issues**
1. **NPCs not spawning**: Check coordinates and model hashes
2. **Images not showing**: Ensure images exist in ox_inventory folder
3. **Payment not working**: Verify money type configuration
4. **Target not working**: Check ox_target installation

### **Debug Mode**
Enable debug prints in the console to troubleshoot issues.

## 📝 Changelog

### **Version 1.0**
- Initial release
- Drug selling system
- Drug seller system
- ox_lib integration
- QBCore support
- Configurable locations and items

## 🤝 Support

For support and updates, please check the script documentation or contact the developer.

## 📄 License

This script is provided as-is for FiveM servers. Please respect the terms of use and don't redistribute without permission.

---

**Enjoy your drug dealing experience!** 💊💰
