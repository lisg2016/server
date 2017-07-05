
require "config.Common"
local Config = {};
--function Config.Load()
Config.CharacterGrowth = require "config.lua.config_data_CharacterGrowth"
Config.CharacterInfo = require "config.lua.config_data_CharacterInfo"
Config.GrowthReward = require "config.lua.config_data_GrowthReward"
Config.LevelupInfo = require "config.lua.config_data_LevelupInfo"
--end

return Config