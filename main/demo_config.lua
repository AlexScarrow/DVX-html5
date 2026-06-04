local M = {}

-- Toggle Steam demo ring-fence behavior.
M.DEMO_BUILD = false

-- Allow tutorial entry from demo mission select.
M.DEMO_ALLOW_TUTORIAL = true

-- Map demo mission slots to concrete level_defs indices.
-- Slot 1 => "Level 1" button, slot 2 => "Level 2", slot 3 => "Level 3".
M.DEMO_LEVEL_SLOT_TO_LEVEL_INDEX = {
    [1] = 6,
    [2] = 7,
    [3] = 8
}

return M
