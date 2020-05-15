obs              = obslua
browser_name     = ""
default_template = 1
file             = ""
file_lines       = {}
file_max_lines   = 0   
line_number      = 0
activated        = false
color1           = ""
color2           = ""			     
hotkey_id        = obs.f
hotkey_next      = obs.OBS_INVALID_HOTKEY_ID
hotkey_prev      = obs.OBS_INVALID_HOTKEY_ID

-- Function to set the time text
local char_to_hex = function(c)
  return string.format("%%%02X", string.byte(c))
end

function string:split(sep)
	local sep, fields = sep or ":", {}
	local pattern = string.format("([^%s]+)", sep)
	self:gsub(pattern, function(c) fields[#fields+1] = c end)
	return fields
end

function urlencode(url)
	if url == nil then
		return
	end
	url = url:gsub("\n", "\r\n")
	url = url:gsub("([^%w ])", char_to_hex)
	url = url:gsub(" ", "+")
	return url
end

function changeUrl()
	local url = "https://obs.infor-r.com/lower"
	local lines = string.split(file_lines[line_number], "|")
	local template = default_template
	local line1 = ""
	local line2 = ""
	
	if (lines[1] ~= nil and tonumber(lines[1]) ~= nil) then
		template = tonumber(lines[1])
		
		if (template < 1 or template > 5) then
			template = default_template
		end
	end
	if (lines[2] ~= nil) then
		line1 = urlencode(lines[2])
	end
	if (lines[3] ~= nil) then
		line2 = urlencode(lines[3])
	end
	
	url = string.format("%s?id=%d&line1=%s&line2=%s", url, template, line1, line2)
	
	if (color1 ~= "") then
		url = string.format("%s&color1=%s", url, color1)
	end
	if (color2 ~= "") then
		url = string.format("%s&color2=%s", url, color2)
	end
	
	obs.script_log(obs.LOG_INFO, string.format("URL: %s", url))
	
	local source = obs.obs_get_source_by_name(browser_name)
	if source ~= nil then
		local settings = obs.obs_data_create()
		obs.obs_data_set_string(settings, "url", url)
		obs.obs_source_update(source, settings)
		obs.obs_data_release(settings)
		obs.obs_source_release(source)
	end
end

function nextLine(pressed)
	if not pressed or (line_number + 1) > file_max_lines then
		return
	end

	line_number = line_number + 1
	
	changeUrl()
end

function prevLine(pressed)
	if not pressed or line_number <= 1 then
		return
	end

	line_number = line_number - 1
	
	changeUrl()
end

function reset(pressed)
	if not pressed then
		return
	end

	line_number = 0
end

function reset_button_clicked(props, p)
	line_number = 0
	
	return false
end


function nextLine_button_clicked(props, p)
	if (line_number + 1) > file_max_lines then
		return false
	end
	
	line_number = line_number + 1
	
	changeUrl()
	
	return false
end

function prevLine_button_clicked(props, p)
	if line_number <= 1 then
		return false
	end
	
	line_number = line_number - 1
	
	changeUrl()
	
	return false
end

-- see if the file exists
function file_exists(file)
	local f = io.open(file, "rb")
	if f then f:close() end
	return f ~= nil
end

-- get all lines from a file, returns an empty 
-- list/table if the file does not exist
function lines_from(file)
	if not file_exists(file) then return {} end
	lines = {}
	file_max_lines = 0
	for line in io.lines(file) do 
		lines[#lines + 1] = line
		file_max_lines = file_max_lines + 1
	end
	
	obs.script_log(obs.LOG_INFO, string.format("Number of read lines: %d", file_max_lines))
	
	return lines
end

function int2hex(value)
	local hex = string.format("%x", value)
    return string.format("%s%s%s", string.sub(hex, 7,8), string.sub(hex, 5,6), string.sub(hex, 3,4))
end
----------------------------------------------------------

-- A function named script_properties defines the properties that the user
-- can change for the entire script module itself
function script_properties()
	local props = obs.obs_properties_create()
	local browserName = obs.obs_properties_add_list(props, "BrowserName", "Browser name", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
			source_id = obs.obs_source_get_id(source)
			if source_id == "browser_source" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(browserName, name, name)
			end
		end
	end
	obs.source_list_release(sources)
	obs.obs_properties_add_int_slider(props, "Default template", "Default template", 1, 5, 1)
	obs.obs_properties_add_color(props, "Color1", "Color1")
	obs.obs_properties_add_color(props, "Color2", "Color2")
	obs.obs_properties_add_path(props, "File", "File", obs.OBS_PATH_FILE, "*.txt", NULL)
	obs.obs_properties_add_button(props, "reset_button", "Reset line", reset_button_clicked)
	obs.obs_properties_add_button(props, "nextLine_button", "Next line", nextLine_button_clicked)
	obs.obs_properties_add_button(props, "prevLine_button", "Previous line", prevLine_button_clicked)
	
	obs.obs_data_set_default_int(settings, "Color1", -11645745)
	obs.obs_data_set_default_int(settings, "Color2", -1)
	
	return props
end

-- A function named script_description returns the description shown to
-- the user
function script_description()
	return "Load text lines from a file. Hotkeys can be set for next/previous line and to the reset line position. File template:\nTEMPLATE_ID|LINE_1|LINE_2\nTEMPLATE_ID|LINE_1|LINE_2\n\nMade by\nVasco Cruz"
end

-- A function named script_update will be called when settings are changed
function script_update(settings)
	browser_name = obs.obs_data_get_string(settings, "BrowserName")
	default_template = obs.obs_data_get_int(settings, "Default template")
	local color1Int = obs.obs_data_get_int(settings, "Color1")
	local color2Int = obs.obs_data_get_int(settings, "Color2")
	file = obs.obs_data_get_string(settings, "File")
	
	color1 = int2hex(color1Int)
	color2 = int2hex(color2Int)
		
	obs.script_log(obs.LOG_INFO, "--- script_update ---")
	obs.script_log(obs.LOG_INFO, string.format("Browser name: %s", browser_name))
	obs.script_log(obs.LOG_INFO, string.format("Default template: %d", default_template))
	obs.script_log(obs.LOG_INFO, string.format("Color1: %s", color1))
	obs.script_log(obs.LOG_INFO, string.format("Color2: %s", color2))
	obs.script_log(obs.LOG_INFO, string.format("File: %s", file))
		
	file_lines = lines_from(file)
	
	reset(true)
end

-- A function named script_defaults will be called to set the default settings
function script_defaults(settings)
	obs.script_log(obs.LOG_INFO, "--- script_defaults ---")
	obs.obs_data_set_default_int(settings, "Color1", -11645745)
	obs.obs_data_set_default_int(settings, "Color2", -1)
end

-- A function named script_save will be called when the script is saved
--
-- NOTE: This function is usually used for saving extra data (such as in this
-- case, a hotkey's save data).  Settings set via the properties are saved
-- automatically.
function script_save(settings)
	local hotkey_save_array = obs.obs_hotkey_save(hotkey_id)
	obs.obs_data_set_array(settings, "LowerThirdsReadFile.Reset", hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)
	
	local hotkey_save_array2 = obs.obs_hotkey_save(hotkey_next)
	obs.obs_data_set_array(settings, "LowerThirdsReadFile.nextLine", hotkey_save_array2)
	obs.obs_data_array_release(hotkey_save_array2)
	
	local hotkey_save_array3 = obs.obs_hotkey_save(hotkey_prev)
	obs.obs_data_set_array(settings, "LowerThirdsReadFile.prevLine", hotkey_save_array3)
	obs.obs_data_array_release(hotkey_save_array3)
end

-- a function named script_load will be called on startup
function script_load(settings)
	-- Connect hotkey and activation/deactivation signal callbacks
	--
	-- NOTE: These particular script callbacks do not necessarily have to
	-- be disconnected, as callbacks will automatically destroy themselves
	-- if the script is unloaded.  So there's no real need to manually
	-- disconnect callbacks that are intended to last until the script is
	-- unloaded.
	local sh = obs.obs_get_signal_handler()
	obs.signal_handler_connect(sh, "source_activate", source_activated)
	obs.signal_handler_connect(sh, "source_deactivate", source_deactivated)

	hotkey_id = obs.obs_hotkey_register_frontend("LowerThirdsReadFile.Reset", "LowerThirdsReadFile-Reset", reset)
	hotkey_next = obs.obs_hotkey_register_frontend("LowerThirdsReadFile.nextLine", "LowerThirdsReadFile-Next Line", nextLine)
	hotkey_prev = obs.obs_hotkey_register_frontend("LowerThirdsReadFile.prevLine", "LowerThirdsReadFile-Prev Line", prevLine)
	
	local hotkey_save_array = obs.obs_data_get_array(settings, "LowerThirdsReadFile.Reset")
	obs.obs_hotkey_load(hotkey_id, hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)
	
	local hotkey_save_array1 = obs.obs_data_get_array(settings, "LowerThirdsReadFile.nextLine")
	obs.obs_hotkey_load(hotkey_next, hotkey_save_array1)
	obs.obs_data_array_release(hotkey_save_array1)

	local hotkey_save_array2 = obs.obs_data_get_array(settings, "LowerThirdsReadFile.prevLine")
	obs.obs_hotkey_load(hotkey_prev, hotkey_save_array2)
	obs.obs_data_array_release(hotkey_save_array2)
end

