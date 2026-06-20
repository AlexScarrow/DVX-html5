local config = require("main.config")
local demo = config.DEMO or {}

return {
    DEMO_BUILD = demo.demo_build == true,
    DEMO_ALLOW_TUTORIAL = demo.demo_allow_tutorial ~= false,
    DEMO_LEVEL_SLOT_TO_LEVEL_INDEX = demo.level_slot_to_level_index or {
        [1] = 6,
        [2] = 2,
        [3] = 8
    }
}
