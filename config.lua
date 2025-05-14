local function saveConfig(filePath, table)
	local directoryPath = filePath:match("^(.*\\)[^\\]*$")
	if directoryPath and not doesDirectoryExist(directoryPath) then
		createDirectory(directoryPath)
	end
	local file = io.open(filePath, "w")
	if file then
		for section, values in pairs(table) do
			file:write("[" .. section .. "]\n")
			for key, value in pairs(values) do
				if type(value) == "string" then
					file:write(key .. " = " .. value .. "\n")
				else
					file:write(key .. " = " .. tostring(value) .. "\n")
				end
			end
			file:write("\n")
		end
		file:close()
	end
end


local function loadConfig(filePath, table)
	local function trim(s)
		return s:match("^%s*(.-)%s*$")
	end
	local file = io.open(filePath, "r")
	if file then
		local currentSection = nil
		for line in file:lines() do
			line = trim(line)
			if line ~= "" then
				local section = line:match("^%[([^%]]+)%]$")
				if section then
					currentSection = section
					if not table[currentSection] then
						table[currentSection] = {}
					end
				else
					local key, value = line:match("^([^=]+)=(.+)$")
					if key and value and currentSection then
						key = trim(key)
						value = trim(value)
						if value == "true" then
							value = true
						elseif value == "false" then
							value = false
						else
							local numberValue = tonumber(value)
							if numberValue then
								value = numberValue
							end
						end

						if table[currentSection] then
							table[currentSection][key] = value
						end
					end
				end
			end
		end
		file:close()
	else
		saveConfig(filePath, table)
	end
end

local function pathConfig(folder, file)
    folder = folder or ''
    return getWorkingDirectory() .. "\\config\\" .. folder .. "\\" .. file
end

return {
    save = saveConfig,
    load = loadConfig,
    path = pathConfig
}