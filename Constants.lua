local GT = LibStub("AceAddon-3.0"):GetAddon("GatheringTracker")

local expansions = {
    ["Classic"] = 1,
    ["BC"] = 2,
    ["Wrath"] = 3,
    ["Cata"] = 4,
    ["MoP"] = 5,
    ["WoD"] = 6,
    ["Legion"] = 7,
    ["BFA"] = 8,
    ["SL"] = 9
}
GT.expansions = expansions

local categories = {
    ["Herb"] = 1,
    ["Ore"] = 2,
    ["Cloth"] = 3,
    ["Leather"] = 4,
    ["Meat"] = 5,
    ["Fish"] = 6,
    ["Elemental"] = 7,
    ["Gem"] = 8,
    ["Enchanting"] = 9,
}
GT.categories = categories

local ItemData = {
    Classic = {
        Herb = {
            {id = 2447, name = "Peacebloom", order = 1},
            {id = 765, name = "Silverleaf", order = 2},
            {id = 22710, name = "Bloodthistle", order = 3},
            {id = 2449, name = "Earthroot", order = 4},
            {id = 785, name = "Mageroyal", order = 5},
            {id = 2450, name = "Briarthorn", order = 6},
            {id = 2452, name = "Swiftthistle", order = 7},
            {id = 3820, name = "Stranglekelp", order = 8},
            {id = 2453, name = "Bruiseweed", order = 9},
            {id = 3369, name = "Grave Moss", order = 10},
            {id = 3355, name = "Wild Steelbloom", order = 11},
            {id = 3356, name = "Kingsblood", order = 12},
            {id = 3357, name = "Liferoot", order = 13},
            {id = 3818, name = "Fadeleaf", order = 14},
            {id = 3821, name = "Goldthorn", order = 15},
            {id = 3358, name = "Khadgar's Whisker", order = 16},
            {id = 3819, name = "Dragon's Teeth", order = 17},
            {id = 4625, name = "Firebloom", order = 18},
            {id = 8831, name = "Purple Lotus", order = 19},
            {id = 8153, name = "Wildvine", order = 20},
            {id = 8838, name = "Sungrass", order = 21},
            {id = 8839, name = "Blindweed", order = 22},
            {id = 8845, name = "Ghost Mushroom", order = 23},
            {id = 8846, name = "Gromsblood", order = 24},
            {id = 13464, name = "Golden Sansam", order = 25},
            {id = 13463, name = "Dreamfoil", order = 26},
            {id = 13465, name = "Mountain Silversage", order = 27},
            {id = 13466, name = "Sorrowmoss", order = 28},
            {id = 13467, name = "Icecap", order = 29},
            {id = 13468, name = "Black Lotus", order = 30}
        },
        Ore = {
            {id = 2770, name = "Copper Ore", order = 1},
            {id = 2771, name = "Tin Ore", order = 2},
            {id = 2775, name = "Silver Ore", order = 3},
            {id = 2772, name = "Iron Ore", order = 4},
            {id = 2776, name = "Gold Ore", order = 5},
            {id = 3858, name = "Mithril Ore", order = 6},
            {id = 7911, name = "Truesilver Ore", order = 7},
            {id = 10620, name = "Thorium Ore", order = 8},
            {id = 11370, name = "Dark Iron Ore", order = 9}
        },
        Cloth = {
            {id = 2589, name = "Linen Cloth", order = 1},
            {id = 2592, name = "Wool Cloth", order = 2},
            {id = 4306, name = "Silk Cloth", order = 3},
            {id = 4338, name = "Mageweave Cloth", order = 4},
            {id = 14047, name = "Runecloth", order = 5},
            {id = 14256, name = "Felcloth", order = 6},
            {id = 3182, name = "Spider's Silk", order = 7},
            {id = 4337, name = "Thick Spider's Silk", order = 8},
            {id = 10285, name = "Shadow Silk", order = 9},
            {id = 14227, name = "Ironweb Spider Silk", order = 10}
        },
        Leather = {
            {id = 2318, name = "Light Leather", order = 1},
            {id = 2319, name = "Medium Leather", order = 2},
            {id = 4234, name = "Heavy Leather", order = 3},
            {id = 4304, name = "Thick Leather", order = 4},
            {id = 8170, name = "Rugged Leather", order = 5},
            {id = 783, name = "Light Hide", order = 6},
            {id = 4232, name = "Medium Hide", order = 7},
            {id = 4235, name = "Heavy Hide", order = 8},
            {id = 8169, name = "Thick Hide", order = 9},
            {id = 8171, name = "Rugged Hide", order = 10},
            {id = 8165, name = "Worn Dragonscale", order = 11},
            {id = 15416, name = "Black Dragonscale", order = 12},
            {id = 8154, name = "Scorpid Scale", order = 13},
            {id = 15410, name = "Scale of Onyxia", order = 14}
        },
        Meat = {
            {id = 3173, name = "Bear Meat", order = 1},
            {id = 3730, name = "Big Bear Meat", order = 2},
            {id = 2677, name = "Boar Ribs", order = 3},
            {id = 769, name = "Chunk of Boar Meat", order = 4},
            {id = 5503, name = "Clam Meat", order = 5},
            {id = 2673, name = "Coyote Meat", order = 6},
            {id = 2674, name = "Crawler Meat", order = 7},
            {id = 12207, name = "Giant Egg", order = 8},
            {id = 1015, name = "Lean Wolf Flank", order = 9},
            {id = 3731, name = "Lion Meat", order = 10},
            {id = 12037, name = "Mystery Meat", order = 11},
            {id = 3685, name = "Raptor Egg", order = 12},
            {id = 12184, name = "Raptor Flesh", order = 13},
            {id = 12203, name = "Red Wolf Meat", order = 14},
            {id = 20424, name = "Sandworm Meat", order = 15},
            {id = 6889, name = "Small Egg", order = 16},
            {id = 2672, name = "Stringy Wolf Meat", order = 17},
            {id = 5504, name = "Tangy Clam Meat", order = 18},
            {id = 12208, name = "Tender Wolf Meat", order = 19},
            {id = 12202, name = "Tiger Meat", order = 20},
            {id = 3712, name = "Turtle Meat", order = 21},
            {id = 12205, name = "White Spider Meat", order = 22},
            {id = 7974, name = "Zesty Clam Meat", order = 23}
        },
        Fish = {
            {id = 6303, name = "Raw Slitherskin Mackerel", order = 1},
            {id = 6291, name = "Raw Brilliant Smallfish", order = 2},
            {id = 6289, name = "Raw Longjaw Mud Snapper", order = 3},
            {id = 6361, name = "Raw Rainbow Fin Albacore", order = 4},
            {id = 6317, name = "Raw Loch Frenzy", order = 5},
            {id = 21071, name = "Raw Sagefish", order = 6},
            {id = 6308, name = "Raw Bristle Whisker Catfish", order = 7},
            {id = 8365, name = "Raw Mithril Head Trout", order = 8},
            {id = 6362, name = "Raw Rockscale Cod", order = 9},
            {id = 21153, name = "Raw Greater Sagefish", order = 10},
            {id = 13759, name = "Raw Nightfin Snapper", order = 11},
            {id = 4603, name = "Raw Spotted Yellowtail", order = 12},
            {id = 13754, name = "Raw Glossy Mightfish", order = 13},
            {id = 13888, name = "Darkclaw Lobster", order = 14},
            {id = 13760, name = "Raw Sunscale Salmon", order = 15},
            {id = 13758, name = "Raw Redgill", order = 16},
            {id = 13756, name = "Raw Summer Bass", order = 17},
            {id = 13889, name = "Raw Whitescale Salmon", order = 18},
            {id = 124669, name = "Darkmoon Daggermaw", order = 19}
        },
        Elemental = {
            {id = 7081, name = "Breath of Wind", order = 1},
            {id = 7075, name = "Core of Earth", order = 2},
            {id = 7069, name = "Elemental Air", order = 3},
            {id = 7067, name = "Elemental Earth", order = 4},
            {id = 7068, name = "Elemental Fire", order = 5},
            {id = 7070, name = "Elemental Water", order = 6},
            {id = 7082, name = "Essence of Air", order = 7},
            {id = 7076, name = "Essence of Earth", order = 8},
            {id = 7078, name = "Essence of Fire", order = 9},
            {id = 12808, name = "Essence of Undeath", order = 10},
            {id = 7080, name = "Essence of Water", order = 11},
            {id = 7079, name = "Globe of Water", order = 12},
            {id = 7077, name = "Heart of Fire", order = 13},
            {id = 10286, name = "Heart of the Wild", order = 14},
            {id = 7972, name = "Ichor of Undeath", order = 15},
            {id = 12803, name = "Living Essence", order = 16}
        },
        Gem = {
        
        },
        Enchanting = {
        
        }
    },
    BC = {
        Herb = {
            {id = 22785, name = "Felweed", order = 1},
            {id = 22786, name = "Dreaming Glory", order = 2},
            {id = 22787, name = "Ragveil", order = 3},
            {id = 22789, name = "Terocone", order = 4},
            {id = 22790, name = "Ancient Lichen", order = 5},
            {id = 22791, name = "Netherbloom", order = 6},
            {id = 22792, name = "Nightmare Vine", order = 7},
            {id = 22793, name = "Mana Thistle", order = 8},
            {id = 22794, name = "Fel Lotus", order = 9}
        },
        Ore = {
            {id = 23425, name = "Adamantite Ore", order = 1},
            {id = 23427, name = "Eternium Ore", order = 2},
            {id = 23424, name = "Fel Iron Ore", order = 2},
            {id = 23426, name = "Khorium Ore", order = 4}
        },
        Cloth = {
            {id = 21877, name = "Netherweave Cloth", order = 1},
            {id = 21881, name = "Netherweb Spider Silk", order = 2}
        },
        Leather = {
            {id = 21887, name = "Knothide Leather", order = 1},
            {id = 25707, name = "Fel Hide", order = 2},
            {id = 29539, name = "Cobra Scales", order = 3},
            {id = 25700, name = "Fel Scales", order = 4},
            {id = 29547, name = "Wind Scales", order = 5},
            {id = 29548, name = "Nether Dragonscales", order = 6}
        },
        Meat = {
            {id = 27669, name = "Bat Flesh", order = 1},
            {id = 35562, name = "Bear Flank", order = 2},
            {id = 27671, name = "Buzzard Meat", order = 3},
            {id = 27677, name = "Chunk o' Basilisk", order = 4},
            {id = 27678, name = "Clefthoof Meat", order = 5},
            {id = 22644, name = "Crunchy Spider Leg", order = 6},
            {id = 24477, name = "Jaggal Clam Meat", order = 7},
            {id = 27668, name = "Lynx Meat", order = 8},
            {id = 23676, name = "Moongraze Stag Tenderloin", order = 9},
            {id = 31670, name = "Raptor Ribs", order = 10},
            {id = 27674, name = "Ravager Flesh", order = 11},
            {id = 31671, name = "Serpent Flesh", order = 12},
            {id = 27682, name = "Talbuk Venison", order = 13},
            {id = 27681, name = "Warped Flesh", order = 14}
        },
        Fish = {
            {id = 27422, name = "Barbed Gill Trout", order = 1},
            {id = 33823, name = "Bloodfin Catfish", order = 2},
            {id = 33824, name = "Crescent-Tail Skullfish", order = 3},
            {id = 27435, name = "Figluster's Mudfish", order = 4},
            {id = 27439, name = "Furious Crawdad", order = 5},
            {id = 35285, name = "Giant Sunfish", order = 6},
            {id = 27438, name = "Golden Darter", order = 7},
            {id = 27437, name = "Icefin Bluefish", order = 8},
            {id = 27425, name = "Spotted Feltail", order = 9},
            {id = 27429, name = "Zangarian Spore fish", order = 10}
        },
        Elemental = {
            {id = 22572, name = "Mote of Air", order = 1},
            {id = 22573, name = "Mote of Earth", order = 2},
            {id = 22574, name = "Mote of Fire", order = 3},
            {id = 22575, name = "Mote of Life", order = 4},
            {id = 22576, name = "Mote of Mana", order = 5},
            {id = 22577, name = "Mote of Shadow", order = 6},
            {id = 22578, name = "Mote of Water", order = 7},
            {id = 22451, name = "Primal Air", order = 8},
            {id = 22452, name = "Primal Earth", order = 9},
            {id = 21884, name = "Primal Fire", order = 10},
            {id = 21886, name = "Primal Life", order = 11},
            {id = 22457, name = "Primal Mana", order = 12},
            {id = 22456, name = "Primal Shadow", order = 13},
            {id = 21885, name = "Primal Water", order = 14}
        },
        Gem = {
        
        },
        Enchanting = {
        
        }
    },
    Wrath = {
        Herb = {
            {id = 36901, name = "Goldclover", order = 1},
            {id = 39970, name = "Fire Leaf", order = 2},
            {id = 36904, name = "Tiger Lily", order = 3},
            {id = 36907, name = "Talandra's Rose", order = 4},
            {id = 36903, name = "Adder's Tongue", order = 5},
            {id = 37921, name = "Deadnettle", order = 6},
            {id = 36905, name = "Lichbloom", order = 7},
            {id = 36906, name = "Icethorn", order = 8},
            {id = 36908, name = "Frost Lotus", order = 9}
        },
        Ore = {
            {id = 36909, name = "Cobalt Ore", order = 1},
            {id = 36912, name = "Saronite Ore", order = 2},
            {id = 36910, name = "Titanium Ore", order = 3}
        },
        Cloth = {
            {id = 33470, name = "Frostweave Cloth", order = 1},
            {id = 42253, name = "Iceweb Spider Silk", order = 2}
        },
        Leather = {
            {id = 33568, name = "Borean Leather", order = 1},
            {id = 44128, name = "Arctic Fur", order = 2},
            {id = 38557, name = "Icy Dragonscale", order = 3},
            {id = 38561, name = "Jormungar Scale", order = 4},
            {id = 38558, name = "Nerubian Chitin", order = 5}
        },
        Meat = {
            {id = 43013, name = "Chilled Meat", order = 1},
            {id = 34736, name = "Chunk o' Mammoth", order = 2},
            {id = 43012, name = "Rhino Meat", order = 3},
            {id = 43009, name = "Shoveltusk Flank", order = 4},
            {id = 43011, name = "Worg Haunch", order = 5},
            {id = 43010, name = "Worm Meat", order = 6}
        },
        Fish = {
            {id = 41812, name = "Barrelhead Goby", order = 1},
            {id = 41808, name = "Bonescale Snapper", order = 2},
            {id = 41805, name = "Borean Man O' War", order = 3},
            {id = 41800, name = "Deep Sea Monsterbelly", order = 4},
            {id = 41807, name = "Dragonfin Angelfish", order = 5},
            {id = 41810, name = "Fangtooth Herring", order = 6},
            {id = 41814, name = "Glassfin Minnow", order = 7},
            {id = 41802, name = "Imperial Manta Ray", order = 8},
            {id = 43572, name = "Magic Eater", order = 9},
            {id = 41801, name = "Moonglow Cuttlefish", order = 10},
            {id = 41806, name = "Musselback Sculpin", order = 11},
            {id = 41813, name = "Nettlefish", order = 12},
            {id = 41803, name = "Rockfin Grouper", order = 13},
            {id = 43571, name = "Sewer Carp", order = 14},
            {id = 43647, name = "Shimmering Minnow", order = 15},
            {id = 43652, name = "Slippery Eel", order = 16},
            {id = 53067, name = "Striped Lurker", order = 17}
        },
        Elemental = {
            {id = 37700, name = "Crystallized Air", order = 1},
            {id = 37701, name = "Crystallized Earth", order = 2},
            {id = 37702, name = "Crystallized Fire", order = 3},
            {id = 37704, name = "Crystallized Life", order = 4},
            {id = 37703, name = "Crystallized Shadow", order = 5},
            {id = 37705, name = "Crystallized Water", order = 6},
            {id = 35623, name = "Eternal Air", order = 7},
            {id = 35624, name = "Eternal Earth", order = 8},
            {id = 36860, name = "Eternal Fire", order = 9},
            {id = 35625, name = "Eternal Life", order = 10},
            {id = 35627, name = "Eternal Shadow", order = 11},
            {id = 35622, name = "Eternal Water", order = 12}
        },
        Gem = {
        
        },
        Enchanting = {
        
        }
    },
    Cata = {
        Herb = {
            {id = 52983, name = "Cinderbloom", order = 1},
            {id = 52985, name = "Azshara's Veil", order = 2},
            {id = 52984, name = "Stormvine", order = 3},
            {id = 52986, name = "Heartblossom", order = 4},
            {id = 52988, name = "Whiptail", order = 5},
            {id = 52987, name = "Twilight Jasmine", order = 6}
        },
        Ore = {
            {id = 53038, name = "Obsidium Ore", order = 1},
            {id = 52185, name = "Elementium Ore", order = 2},
            {id = 52183, name = "Pyrite Ore", order = 3}
        },
        Cloth = {
            {id = 53010, name = "Embersilk Cloth", order = 1}
        },
        Leather = {
            {id = 52976, name = "Savage Leather", order = 1},
            {id = 52979, name = "Blackened Dragonscale", order = 2},
            {id = 52982, name = "Deepsea Scale", order = 3}
        },
        Meat = {
            {id = 62784, name = "Crocolisk Tail", order = 1},
            {id = 62785, name = "Delicate Wing", order = 2},
            {id = 62782, name = "Dragon Flank", order = 3},
            {id = 62781, name = "Giant Turtle Tongue", order = 4},
            {id = 62780, name = "Snake Eye", order = 5},
            {id = 67229, name = "Stag Flank", order = 6},
            {id = 62778, name = "Toughened Flesh", order = 7}
        },
        Fish = {
            {id = 53065, name = "Albino Cavefish", order = 1},
            {id = 53071, name = "Algaefin RockFfish", order = 2},
            {id = 53066, name = "Blackbelly Mudfish", order = 3},
            {id = 62791, name = "Blood Shrimp", order = 4},
            {id = 53072, name = "Deepsea Sagefish", order = 5},
            {id = 53070, name = "Fathom Eel", order = 6},
            {id = 53064, name = "Highland Guppy", order = 7},
            {id = 53068, name = "Lavascale Catfish", order = 8},
            {id = 53063, name = "Mountain Trout", order = 9},
            {id = 53069, name = "Murglesnout", order = 10},
            {id = 53062, name = "Sharptooth", order = 11},
            {id = 53067, name = "Striped Lurker", order = 12}
        },
        Elemental = {
            {id = 52328, name = "Volatile Air", order = 1},
            {id = 52327, name = "Volatile Earth", order = 2},
            {id = 52325, name = "Volatile Fire", order = 3},
            {id = 52329, name = "Volatile Life", order = 4},
            {id = 52326, name = "Volatile Water", order = 5}
        },
        Gem = {
        
        },
        Enchanting = {
        
        }
    },
    MoP = {
        Herb = {
            {id = 72234, name = "Green Tea Leaf", order = 1},
            {id = 72237, name = "Rain Poppy", order = 2},
            {id = 72235, name = "Silkweed", order = 3},
            {id = 79010, name = "Snow Lily", order = 4},
            {id = 79011, name = "Fool's Cap", order = 5},
            {id = 72238, name = "Golden Lotus", order = 6}
        },
        Ore = {
            {id = 72092, name = "Ghost Iron Ore", order = 1},
            {id = 72093, name = "Kyparite", order = 2},
            {id = 72094, name = "Black Trillium Ore", order = 3},
            {id = 72103, name = "White Trillium Ore", order = 4}
        },
        Cloth = {
            {id = 72988, name = "Windwool Cloth", order = 1}
        },
        Leather = {
            {id = 72162, name = "Sha-Touched Leather", order = 1},
            {id = 72120, name = "Exotic Leather", order = 2},
            {id = 79101, name = "Prismatic Scale", order = 3}
        },
        Meat = {
            {id = 74834, name = "Mushan Ribs", order = 1},
            {id = 74838, name = "Raw Crab Meat", order = 2},
            {id = 75014, name = "Raw Crocolisk Belly", order = 3},
            {id = 74833, name = "Raw Tiger Steak", order = 4},
            {id = 74837, name = "Raw Turtle Meat", order = 5},
            {id = 85506, name = "Viseclaw Meat", order = 6}
        },
        Fish = {
            {id = 74859, name = "Emperor Salmon", order = 1},
            {id = 74857, name = "Giant Mantis Shrimp", order = 2},
            {id = 74866, name = "Golden Carp", order = 3},
            {id = 74856, name = "Jade Lungfish", order = 4},
            {id = 74863, name = "Jewel Danio", order = 5},
            {id = 74865, name = "Krasarang Paddlefish", order = 6},
            {id = 74860, name = "Redbelly Mandarin", order = 7},
            {id = 74864, name = "Reef Octopus", order = 8},
            {id = 74861, name = "Tiger Gourami", order = 9}
        },
        Elemental = {
            {id = 89112, name = "Mote of Harmony", order = 1},
            {id = 76061, name = "Spirit of Harmony", order = 2}
        },
        Gem = {
        
        },
        Enchanting = {
        
        }
    },
    WoD = {
        Herb = {
            {id = 109124, name = "Frostweed", order = 1},
            {id = 109127, name = "Starflower", order = 2},
            {id = 109125, name = "Fireweed", order = 3},
            {id = 109126, name = "Gorgrond Flytrap", order = 4},
            {id = 109129, name = "Talador Orchid", order = 5},
            {id = 109128, name = "Nagrand Arrowbloom", order = 6}
        },
        Ore = {
            {id = 109118, name = "Blackrock Ore", order = 1},
            {id = 109119, name = "True Iron Ore", order = 2}
        },
        Cloth = {
            {id = 111557, name = "Sumptuous Fur", order = 1}
        },
        Leather = {
            {id = 110609, name = "Raw Beast Hide", order = 1}
        },
        Meat = {
            {id = 109136, name = "Raw Boar Meat", order = 1},
            {id = 109131, name = "Raw Clefthoof Meat", order = 2},
            {id = 109134, name = "Raw Elekk Meat", order = 3},
            {id = 109135, name = "Raw Riverbeast Meat", order = 4},
            {id = 109132, name = "Raw Talbuk Meat", order = 5}
        },
        Fish = {
            {id = 111664, name = "Abyssal Gulper Eel", order = 1},
            {id = 111663, name = "Blackwater Whiptail", order = 2},
            {id = 111667, name = "Blind Lake Sturgeon", order = 3},
            {id = 111595, name = "Crescent Saberfish", order = 4},
            {id = 111668, name = "Fat Sleeper", order = 5},
            {id = 111666, name = "Fire Ammonite", order = 6},
            {id = 111669, name = "Jawless Skulker", order = 7},
            {id = 118565, name = "Savage Piranha", order = 8},
            {id = 111665, name = "Sea Scorpion", order = 9}
        },
        Elemental = {
        
        },
        Gem = {
        
        },
        Enchanting = {
        
        }
    },
    Legion = {
        Herb = {
            {id = 124101, name = "Aethril", order = 1},
            {id = 151565, name = "Astral Glory", order = 2},
            {id = 124102, name = "Dreamleaf", order = 3},
            {id = 124104, name = "Fjarnskaggl", order = 4},
            {id = 124103, name = "Foxflower", order = 5},
            {id = 124105, name = "Starlight Rose", order = 6},
            {id = 124106, name = "Felwort", order = 7}
        },
        Ore = {
            {id = 123919, name = "Felslate", order = 1},
            {id = 123918, name = "Leystone Ore", order = 2},
            {id = 151564, name = "Empyrium", order = 3}
        },
        Cloth = {
            {id = 151567, name = "Lightweave Cloth", order = 1},
            {id = 124437, name = "Shal'dorei Silk", order = 2}
        },
        Leather = {
            {id = 124113, name = "Stonehide Leather", order = 1},
            {id = 151566, name = "Fiendish Leather", order = 2},
            {id = 124115, name = "Stormscale", order = 3}
        },
        Meat = {
            {id = 124119, name = "Big Gamy Ribs", order = 1},
            {id = 124118, name = "Fatty Bearsteak", order = 2},
            {id = 124117, name = "Lean Shank", order = 3},
            {id = 124120, name = "Leyblood", order = 4},
            {id = 124121, name = "Wildfowl Egg", order = 5}
        },
        Fish = {
            {id = 124112, name = "Black Barracuda", order = 1},
            {id = 124107, name = "Cursed Queenfish", order = 2},
            {id = 124109, name = "Highmountain Salmon", order = 3},
            {id = 124108, name = "Mossgill Perch", order = 4},
            {id = 124111, name = "Runescale Koi", order = 5},
            {id = 133607, name = "Silver Mackerel", order = 6},
            {id = 124110, name = "Stormray", order = 7}
        },
        Elemental = {
        
        },
        Gem = {
        
        },
        Enchanting = {
        
        }
    },
    BFA = {
        Herb = {
            {id = 152507, name = "Akunda's Bite", order = 1},
            {id = 152505, name = "Riverbud", order = 2},
            {id = 152511, name = "Sea Stalk", order = 3},
            {id = 152509, name = "Siren's Pollen", order = 4},
            {id = 152506, name = "Star Moss", order = 5},
            {id = 152508, name = "Winter's Kiss", order = 6},
            {id = 152510, name = "Anchor Weed", order = 7},
            {id = 168487, name = "Zin'anthid", order = 8},
            {id = 168822, name = "Thin Jelly", order = 9},
            {id = 168825, name = "Rich Jelly", order = 10},
            {id = 168828, name = "Royal Jelly", order = 11}
        },
        Ore = {
            {id = 152512, name = "Monelite Ore", order = 1},
            {id = 152579, name = "Storm Silver Ore", order = 2},
            {id = 152513, name = "Platinum Ore", order = 3},
            {id = 168185, name = "Osmenite Ore", order = 4}
        },
        Cloth = {
            {id = 152576, name = "Tidespray Linen", order = 1},
            {id = 152577, name = "Deep Sea Satin", order = 2},
            {id = 167738, name = "Gilded Seaweave", order = 3}
        },
        Leather = {
            {id = 152541, name = "Coarse Leather", order = 1},
            {id = 154722, name = "Tempest Hide", order = 2},
            {id = 168649, name = "Dredged Leather", order = 3},
            {id = 153050, name = "Shimmerscale", order = 4},
            {id = 154164, name = "Blood-Stained Bone", order = 5},
            {id = 168650, name = "Cragscale", order = 6},
            {id = 153051, name = "Mistscale", order = 7}
        },
        Meat = {
            {id = 152631, name = "Briny Flesh", order = 1},
            {id = 163782, name = "Cursed Haunch", order = 2},
            {id = 154898, name = "Meaty Haunch", order = 3},
            {id = 168645, name = "Moist Fillet", order = 4},
            {id = 174353, name = "Questionable Meat", order = 5},
            {id = 168303, name = "Rubbery Flank", order = 6},
            {id = 154899, name = "Thick Paleo Steak", order = 7}
        },
        Fish = {
            {id = 174328, name = "Aberrant Voidfin", order = 1},
            {id = 152545, name = "Frenzied Fangtooth", order = 2},
            {id = 152547, name = "Great Sea Catfish", order = 3},
            {id = 152546, name = "Lane Snapper", order = 4},
            {id = 174327, name = "Malformed Gnasher", order = 5},
            {id = 168646, name = "Mauve Stinger", order = 6},
            {id = 162515, name = "Midnight Salmon", order = 7},
            {id = 152549, name = "Redtail Loach", order = 8},
            {id = 152543, name = "Sand Shifter", order = 9},
            {id = 152544, name = "Slimy Mackerel", order = 10},
            {id = 152548, name = "Tiragarde Perch", order = 11},
            {id = 168302, name = "Viper Fish", order = 12}
        },
        Elemental = {
        
        },
        Gem = {
        
        },
        Enchanting = {
        
        }
    },
    SL = {
        Herb = {
            {id = 169701, name = "Death Blossom", order = 1},
            {id = 168589, name = "Marrowroot", order = 2},
            {id = 168586, name = "Rising Glory", order = 3},
            {id = 170554, name = "Vigils Torch", order = 4},
            {id = 168583, name = "Widowbloom", order = 5},
            {id = 171315, name = "Nightshade", order = 6}
        },
        Ore = {
            {id = 171828, name = "Laestrite Ore", order = 1},
            {id = 171830, name = "Oxxein Ore", order = 2},
            {id = 171831, name = "Phaedrum Ore", order = 3},
            {id = 171832, name = "Sinvyr Ore", order = 4},
            {id = 171829, name = "Solenium Ore", order = 5},
            {id = 171833, name = "Elethium Ore", order = 6},
            {id = 171840, name = "Porous Stone", order = 7},
            {id = 171841, name = "Shaded Stone", order = 8}
        },
        Cloth = {
            {id = 173202, name = "Shrouded Cloth", order = 1},
            {id = 173204, name = "Lightless Silk", order = 2}
        },
        Leather = {
            {id = 172089, name = "Desolate Leather", order = 1},
            {id = 172094, name = "Desolate Hide", order = 2},
            {id = 172096, name = "Heavy Desolate Leather", order = 3},
            {id = 172097, name = "Heavy Desolate Hide", order = 4},
            {id = 172332, name = "Necrotic Leather", order = 5},
            {id = 172333, name = "Purified Leather", order = 6},
            {id = 172331, name = "Sinful Leather", order = 7},
            {id = 172330, name = "Unseelie Leather", order = 8},
            {id = 172090, name = "Sorrowscale Fragment", order = 9},
            {id = 177281, name = "Dnt Reuse Me Mtmm", order = 10},
            {id = 172092, name = "Pallid Bone", order = 11},
            {id = 177279, name = "Gaunt Sinew", order = 12}
        },
        Meat = {
            {id = 172052, name = "Aethereal Meat", order = 1},
            {id = 172055, name = "Phantasmal Haunch", order = 2},
            {id = 172054, name = "Seraphic Wing", order = 3},
            {id = 179315, name = "Shadowy Shank", order = 4},
            {id = 172053, name = "Tenebrous Ribs", order = 5}
        },
        Fish = {
            {id = 173033, name = "Iridescent Amberjack", order = 1},
            {id = 173032, name = "Lost Sole", order = 2},
            {id = 173035, name = "Pocked Bonefish", order = 3},
            {id = 173034, name = "Silvergill Pike", order = 4},
            {id = 173036, name = "Spinefin Piranha", order = 5},
            {id = 173037, name = "Elysian Thade", order = 6}
        },
        Elemental = {
        
        },
        Gem = {
        
        },
        Enchanting = {
        
        }
    },
}

GT.ItemData = ItemData
