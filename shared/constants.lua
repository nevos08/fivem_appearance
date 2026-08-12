-- ! DO NOT EDIT ANYTHING IF YOU DON'T KNOW WHAT YOU'RE DOING.
Appearance = Appearance or {}

local const = {}
Appearance.const = const

const.VERSION = 1

-----------------------------------------------------------------------------
-- Models
-----------------------------------------------------------------------------
const.MODEL_MALE = "mp_m_freemode_01"
const.MODEL_FEMALE = "mp_f_freemode_01"

-- Head blend, face features, overlays, hair colour and eye colour only exist on
-- these. Everything else gets components/props/decorations only.
const.FREEMODE = {
    [`mp_m_freemode_01`] = "male",
    [`mp_f_freemode_01`] = "female"
}

-----------------------------------------------------------------------------
-- Components
-----------------------------------------------------------------------------
-- Component 0 (head) and 2 (hair) are handled by the head/hair subsystems, so
-- they are deliberately absent here.
const.COMPONENTS = {
    mask = 1,
    arms = 3,
    pants = 4,
    bags = 5,
    shoes = 6,
    accessory = 7,
    shirt = 8,
    armor = 9,
    badge = 10,
    torso = 11
}

const.COMPONENT_NAMES = {}
for name, id in pairs(const.COMPONENTS) do
    const.COMPONENT_NAMES[id] = name
end

const.COMPONENT_HAIR = 2

const.PROPS = {
    hats = 0,
    glasses = 1,
    ears = 2,
    watches = 6,
    bracelets = 7
}

const.PROP_NAMES = {}
for name, id in pairs(const.PROPS) do
    const.PROP_NAMES[id] = name
end

-----------------------------------------------------------------------------
-- Face features (index 0-19, value -1.0 .. 1.0)
-----------------------------------------------------------------------------
const.FACE_FEATURES = {
    "noseWidth",
    "nosePeak",
    "noseLength",
    "noseBoneCurve",
    "noseTip",
    "noseBoneTwist",
    "eyebrowHeight",
    "eyebrowForward",
    "cheekBones",
    "cheekSideBones",
    "cheekBonesWidth",
    "eyeOpening",
    "lipThickness",
    "jawBoneWidth",
    "jawBoneShape",
    "chinBone",
    "chinBoneLength",
    "chinBoneShape",
    "chinHole",
    "neckThickness"
}

const.FACE_FEATURE_INDEX = {}
for i = 1, #const.FACE_FEATURES do
    const.FACE_FEATURE_INDEX[const.FACE_FEATURES[i]] = i - 1
end

-----------------------------------------------------------------------------
-- Head overlays (index 0-11)
-----------------------------------------------------------------------------
const.HEAD_OVERLAYS = {
    "blemishes",
    "beard",
    "eyebrows",
    "ageing",
    "makeUp",
    "blush",
    "complexion",
    "sunDamage",
    "lipstick",
    "moleAndFreckles",
    "chestHair",
    "bodyBlemishes"
}

const.HEAD_OVERLAY_INDEX = {}
for i = 1, #const.HEAD_OVERLAYS do
    const.HEAD_OVERLAY_INDEX[const.HEAD_OVERLAYS[i]] = i - 1
end

-- SetPedHeadOverlayColor colour palettes:
--   0 = none / default
--   1 = hair palette   (beard, eyebrows, chest hair)
--   2 = makeup palette (make-up, blush, lipstick)
const.OVERLAY_COLOR_TYPE = {
    blemishes = 0,
    beard = 1,
    eyebrows = 1,
    ageing = 0,
    makeUp = 2,
    blush = 2,
    complexion = 0,
    sunDamage = 0,
    lipstick = 2,
    moleAndFreckles = 0,
    chestHair = 1,
    bodyBlemishes = 0
}

-- "No overlay" is 255, not -1.
const.OVERLAY_NONE = 255

-----------------------------------------------------------------------------
-- Collections
-----------------------------------------------------------------------------
-- The base game collection. Local and global indices are identical here
-- because no DLC collection precedes it.
const.BASE_COLLECTION = ""

--! Credits to the creator of illenium-appearance
const.HAIR_DECORATIONS = {
    male = {
        [0] = { `mpbeach_overlays`, `FM_Hair_Fuzz` },
        [1] = { `multiplayer_overlays`, `NG_M_Hair_001` },
        [2] = { `multiplayer_overlays`, `NG_M_Hair_002` },
        [3] = { `multiplayer_overlays`, `NG_M_Hair_003` },
        [4] = { `multiplayer_overlays`, `NG_M_Hair_004` },
        [5] = { `multiplayer_overlays`, `NG_M_Hair_005` },
        [6] = { `multiplayer_overlays`, `NG_M_Hair_006` },
        [7] = { `multiplayer_overlays`, `NG_M_Hair_007` },
        [8] = { `multiplayer_overlays`, `NG_M_Hair_008` },
        [9] = { `multiplayer_overlays`, `NG_M_Hair_009` },
        [10] = { `multiplayer_overlays`, `NG_M_Hair_013` },
        [11] = { `multiplayer_overlays`, `NG_M_Hair_002` },
        [12] = { `multiplayer_overlays`, `NG_M_Hair_011` },
        [13] = { `multiplayer_overlays`, `NG_M_Hair_012` },
        [14] = { `multiplayer_overlays`, `NG_M_Hair_014` },
        [15] = { `multiplayer_overlays`, `NG_M_Hair_015` },
        [16] = { `multiplayer_overlays`, `NGBea_M_Hair_000` },
        [17] = { `multiplayer_overlays`, `NGBea_M_Hair_001` },
        [18] = { `multiplayer_overlays`, `NGBus_M_Hair_000` },
        [19] = { `multiplayer_overlays`, `NGBus_M_Hair_001` },
        [20] = { `multiplayer_overlays`, `NGHip_M_Hair_000` },
        [21] = { `multiplayer_overlays`, `NGHip_M_Hair_001` },
        [22] = { `multiplayer_overlays`, `NGInd_M_Hair_000` },
        [24] = { `mplowrider_overlays`, `LR_M_Hair_000` },
        [25] = { `mplowrider_overlays`, `LR_M_Hair_001` },
        [26] = { `mplowrider_overlays`, `LR_M_Hair_002` },
        [27] = { `mplowrider_overlays`, `LR_M_Hair_003` },
        [28] = { `mplowrider2_overlays`, `LR_M_Hair_004` },
        [29] = { `mplowrider2_overlays`, `LR_M_Hair_005` },
        [30] = { `mplowrider2_overlays`, `LR_M_Hair_006` },
        [31] = { `mpbiker_overlays`, `MP_Biker_Hair_000_M` },
        [32] = { `mpbiker_overlays`, `MP_Biker_Hair_001_M` },
        [33] = { `mpbiker_overlays`, `MP_Biker_Hair_002_M` },
        [34] = { `mpbiker_overlays`, `MP_Biker_Hair_003_M` },
        [35] = { `mpbiker_overlays`, `MP_Biker_Hair_004_M` },
        [36] = { `mpbiker_overlays`, `MP_Biker_Hair_005_M` },
        [37] = { `multiplayer_overlays`, `NG_M_Hair_001` },
        [38] = { `multiplayer_overlays`, `NG_M_Hair_002` },
        [39] = { `multiplayer_overlays`, `NG_M_Hair_003` },
        [40] = { `multiplayer_overlays`, `NG_M_Hair_004` },
        [41] = { `multiplayer_overlays`, `NG_M_Hair_005` },
        [42] = { `multiplayer_overlays`, `NG_M_Hair_006` },
        [43] = { `multiplayer_overlays`, `NG_M_Hair_007` },
        [44] = { `multiplayer_overlays`, `NG_M_Hair_008` },
        [45] = { `multiplayer_overlays`, `NG_M_Hair_009` },
        [46] = { `multiplayer_overlays`, `NG_M_Hair_013` },
        [47] = { `multiplayer_overlays`, `NG_M_Hair_002` },
        [48] = { `multiplayer_overlays`, `NG_M_Hair_011` },
        [49] = { `multiplayer_overlays`, `NG_M_Hair_012` },
        [50] = { `multiplayer_overlays`, `NG_M_Hair_014` },
        [51] = { `multiplayer_overlays`, `NG_M_Hair_015` },
        [52] = { `multiplayer_overlays`, `NGBea_M_Hair_000` },
        [53] = { `multiplayer_overlays`, `NGBea_M_Hair_001` },
        [54] = { `multiplayer_overlays`, `NGBus_M_Hair_000` },
        [55] = { `multiplayer_overlays`, `NGBus_M_Hair_001` },
        [56] = { `multiplayer_overlays`, `NGHip_M_Hair_000` },
        [57] = { `multiplayer_overlays`, `NGHip_M_Hair_001` },
        [58] = { `multiplayer_overlays`, `NGInd_M_Hair_000` },
        [59] = { `mplowrider_overlays`, `LR_M_Hair_000` },
        [60] = { `mplowrider_overlays`, `LR_M_Hair_001` },
        [61] = { `mplowrider_overlays`, `LR_M_Hair_002` },
        [62] = { `mplowrider_overlays`, `LR_M_Hair_003` },
        [63] = { `mplowrider2_overlays`, `LR_M_Hair_004` },
        [64] = { `mplowrider2_overlays`, `LR_M_Hair_005` },
        [65] = { `mplowrider2_overlays`, `LR_M_Hair_006` },
        [66] = { `mpbiker_overlays`, `MP_Biker_Hair_000_M` },
        [67] = { `mpbiker_overlays`, `MP_Biker_Hair_001_M` },
        [68] = { `mpbiker_overlays`, `MP_Biker_Hair_002_M` },
        [69] = { `mpbiker_overlays`, `MP_Biker_Hair_003_M` },
        [70] = { `mpbiker_overlays`, `MP_Biker_Hair_004_M` },
        [71] = { `mpbiker_overlays`, `MP_Biker_Hair_005_M` },
        [72] = { `mpgunrunning_overlays`, `MP_Gunrunning_Hair_M_000_M` },
        [73] = { `mpgunrunning_overlays`, `MP_Gunrunning_Hair_M_001_M` },
        [74] = { `mpVinewood_overlays`, `MP_Vinewood_Hair_M_000_M` },
        [75] = { `mptuner_overlays`, `MP_Tuner_Hair_001_M` },
        [76] = { `mpsecurity_overlays`, `MP_Security_Hair_001_M` },
    },
    female = {
        [0] = { `mpbeach_overlays`, `FM_Hair_Fuzz` },
        [1] = { `multiplayer_overlays`, `NG_F_Hair_001` },
        [2] = { `multiplayer_overlays`, `NG_F_Hair_002` },
        [3] = { `multiplayer_overlays`, `NG_F_Hair_003` },
        [4] = { `multiplayer_overlays`, `NG_F_Hair_004` },
        [5] = { `multiplayer_overlays`, `NG_F_Hair_005` },
        [6] = { `multiplayer_overlays`, `NG_F_Hair_006` },
        [7] = { `multiplayer_overlays`, `NG_F_Hair_007` },
        [8] = { `multiplayer_overlays`, `NG_F_Hair_008` },
        [9] = { `multiplayer_overlays`, `NG_F_Hair_009` },
        [10] = { `multiplayer_overlays`, `NG_F_Hair_010` },
        [11] = { `multiplayer_overlays`, `NG_F_Hair_011` },
        [12] = { `multiplayer_overlays`, `NG_F_Hair_012` },
        [13] = { `multiplayer_overlays`, `NG_F_Hair_013` },
        [14] = { `multiplayer_overlays`, `NG_M_Hair_014` },
        [15] = { `multiplayer_overlays`, `NG_M_Hair_015` },
        [16] = { `multiplayer_overlays`, `NGBea_F_Hair_000` },
        [17] = { `multiplayer_overlays`, `NGBea_F_Hair_001` },
        [18] = { `multiplayer_overlays`, `NG_F_Hair_007` },
        [19] = { `multiplayer_overlays`, `NGBus_F_Hair_000` },
        [20] = { `multiplayer_overlays`, `NGBus_F_Hair_001` },
        [21] = { `multiplayer_overlays`, `NGBea_F_Hair_001` },
        [22] = { `multiplayer_overlays`, `NGHip_F_Hair_000` },
        [23] = { `multiplayer_overlays`, `NGInd_F_Hair_000` },
        [25] = { `mplowrider_overlays`, `LR_F_Hair_000` },
        [26] = { `mplowrider_overlays`, `LR_F_Hair_001` },
        [27] = { `mplowrider_overlays`, `LR_F_Hair_002` },
        [28] = { `mplowrider2_overlays`, `LR_F_Hair_003` },
        [29] = { `mplowrider2_overlays`, `LR_F_Hair_003` },
        [30] = { `mplowrider2_overlays`, `LR_F_Hair_004` },
        [31] = { `mplowrider2_overlays`, `LR_F_Hair_006` },
        [32] = { `mpbiker_overlays`, `MP_Biker_Hair_000_F` },
        [33] = { `mpbiker_overlays`, `MP_Biker_Hair_001_F` },
        [34] = { `mpbiker_overlays`, `MP_Biker_Hair_002_F` },
        [35] = { `mpbiker_overlays`, `MP_Biker_Hair_003_F` },
        [36] = { `multiplayer_overlays`, `NG_F_Hair_003` },
        [37] = { `mpbiker_overlays`, `MP_Biker_Hair_006_F` },
        [38] = { `mpbiker_overlays`, `MP_Biker_Hair_004_F` },
        [39] = { `multiplayer_overlays`, `NG_F_Hair_001` },
        [40] = { `multiplayer_overlays`, `NG_F_Hair_002` },
        [41] = { `multiplayer_overlays`, `NG_F_Hair_003` },
        [42] = { `multiplayer_overlays`, `NG_F_Hair_004` },
        [43] = { `multiplayer_overlays`, `NG_F_Hair_005` },
        [44] = { `multiplayer_overlays`, `NG_F_Hair_006` },
        [45] = { `multiplayer_overlays`, `NG_F_Hair_007` },
        [46] = { `multiplayer_overlays`, `NG_F_Hair_008` },
        [47] = { `multiplayer_overlays`, `NG_F_Hair_009` },
        [48] = { `multiplayer_overlays`, `NG_F_Hair_010` },
        [49] = { `multiplayer_overlays`, `NG_F_Hair_011` },
        [50] = { `multiplayer_overlays`, `NG_F_Hair_012` },
        [51] = { `multiplayer_overlays`, `NG_F_Hair_013` },
        [52] = { `multiplayer_overlays`, `NG_M_Hair_014` },
        [53] = { `multiplayer_overlays`, `NG_M_Hair_015` },
        [54] = { `multiplayer_overlays`, `NGBea_F_Hair_000` },
        [55] = { `multiplayer_overlays`, `NGBea_F_Hair_001` },
        [56] = { `multiplayer_overlays`, `NG_F_Hair_007` },
        [57] = { `multiplayer_overlays`, `NGBus_F_Hair_000` },
        [58] = { `multiplayer_overlays`, `NGBus_F_Hair_001` },
        [59] = { `multiplayer_overlays`, `NGBea_F_Hair_001` },
        [60] = { `multiplayer_overlays`, `NGHip_F_Hair_000` },
        [61] = { `multiplayer_overlays`, `NGInd_F_Hair_000` },
        [62] = { `mplowrider_overlays`, `LR_F_Hair_000` },
        [63] = { `mplowrider_overlays`, `LR_F_Hair_001` },
        [64] = { `mplowrider_overlays`, `LR_F_Hair_002` },
        [65] = { `mplowrider2_overlays`, `LR_F_Hair_003` },
        [66] = { `mplowrider2_overlays`, `LR_F_Hair_003` },
        [67] = { `mplowrider2_overlays`, `LR_F_Hair_004` },
        [68] = { `mplowrider2_overlays`, `LR_F_Hair_006` },
        [69] = { `mpbiker_overlays`, `MP_Biker_Hair_000_F` },
        [70] = { `mpbiker_overlays`, `MP_Biker_Hair_001_F` },
        [71] = { `mpbiker_overlays`, `MP_Biker_Hair_002_F` },
        [72] = { `mpbiker_overlays`, `MP_Biker_Hair_003_F` },
        [73] = { `multiplayer_overlays`, `NG_F_Hair_003` },
        [74] = { `mpbiker_overlays`, `MP_Biker_Hair_006_F` },
        [75] = { `mpbiker_overlays`, `MP_Biker_Hair_004_F` },
        [76] = { `mpgunrunning_overlays`, `MP_Gunrunning_Hair_F_000_F` },
        [77] = { `mpgunrunning_overlays`, `MP_Gunrunning_Hair_F_001_F` },
        [78] = { `mpVinewood_overlays`, `MP_Vinewood_Hair_F_000_F` },
        [79] = { `mptuner_overlays`, `MP_Tuner_Hair_000_F` },
        [80] = { `mpsecurity_overlays`, `MP_Security_Hair_000_F` },
    },
}

const.NAKED_DATA = {
    male = {
        { componentId = 1,  drawable = 0,  texture = 0 },
        { componentId = 3,  drawable = 15, texture = 0 },
        { componentId = 4,  drawable = 21, texture = 0 },
        { componentId = 5,  drawable = 0,  texture = 0 },
        { componentId = 6,  drawable = 34, texture = 0 },
        { componentId = 7,  drawable = 0,  texture = 0 },
        { componentId = 8,  drawable = 15, texture = 0 },
        { componentId = 9,  drawable = 0,  texture = 0 },
        { componentId = 10, drawable = 0,  texture = 0 },
        { componentId = 11, drawable = 15, texture = 0 },
    },
    female = {
        { componentId = 1,  drawable = 0,  texture = 0 },
        { componentId = 3,  drawable = 15, texture = 0 },
        { componentId = 4,  drawable = 15, texture = 0 },
        { componentId = 5,  drawable = 0,  texture = 0 },
        { componentId = 6,  drawable = 35, texture = 0 },
        { componentId = 7,  drawable = 0,  texture = 0 },
        { componentId = 8,  drawable = 15, texture = 0 },
        { componentId = 9,  drawable = 0,  texture = 0 },
        { componentId = 10, drawable = 0,  texture = 0 },
        { componentId = 11, drawable = 15, texture = 0 },
    }
}

-- Name-keyed view of NAKED_DATA so the schema and the naked fallback can look
-- components up the same way everything else does.
const.NAKED = {}
for sex, entries in pairs(const.NAKED_DATA) do
    const.NAKED[sex] = {}
    for i = 1, #entries do
        local entry = entries[i]
        local name = const.COMPONENT_NAMES[entry.componentId]
        if name then
            const.NAKED[sex][name] = { drawable = entry.drawable, texture = entry.texture }
        end
    end
end
