local ffi = require("ffi")

local function sampGetVersion()
	local version = "unknown"
	local versions = {
		[0xFDB60] = "dl",
		[0x31DF13] = "r1",
		[0x3195DD] = "r2",
		[0xCC4D0] = "r3",
		[0xCBCB0] = "r4",
		[0xCBC90] = "r5"
	}
	local sampHandle = sampGetBase()
	if sampHandle then
		local e_lfanew = ffi.cast("long*", (sampHandle + 60))
		local ntHeader = (sampHandle + e_lfanew[0])
		local pEntryPoint = ffi.cast("uintptr_t*", (ntHeader + 40))
		if versions[pEntryPoint[0]] then version = versions[pEntryPoint[0]] end
	end
	return version
end

local addresses = {
    -- chat
    ["refCDialog"] = { ["r1"] = 0x21A0B8, ["r3"] = 0x26E898, ["r5"] = 0x26EB50, ["dl"] = 0x2AC9E0 }, -- 1
    ["refCConfig"] = { ["r1"] = 0x21A0E0, ["r3"] = 0x26E8C4, ["r5"] = 0x26EB7C, ["dl"] = 0x2ACA0C }, -- 2
    ["CConfig::GetIntValue"] = { ["r1"] = 0x62250, ["r3"] = 0x656A0, ["r5"] = 0x65E10, ["dl"] = 0x65890 }, -- 3
    ["CConfig::WriteIntValue"] = { ["r1"] = 0x624C0, ["r3"] = 0x65910, ["r5"] = 0x66080, ["dl"] = 0x65B00 }, -- 4
    ["CChat::AddEntry"] = { ["r1"] = 0x64010, ["r3"] = 0x67460, ["r5"] = 0x67BE0, ["dl"] = 0x67650 }, -- 5
    ["CChat::Draw"] = { ["r1"] = 0x64230, ["r3"] = 0x67680, ["r5"] = 0x67E00, ["dl"] = 0x67870 }, -- 6
    ["CInput::Open"] = { ["r1"] = 0x657E0, ["r3"] = 0x68D10, ["r5"] = 0x69480, ["dl"] = 0x68EC0 }, -- 7
    ["CInput::Close"] = { ["r1"] = 0x658E0, ["r3"] = 0x68E10, ["r5"] = 0x69580, ["dl"] = 0x68FC0 }, -- 8
    ["CDXUTEditBox"] = { ["r1"] = 0x80F60, ["r3"] = 0x84E70, ["r5"] = 0x85580, ["dl"] = 0x85000 }, -- 9
    -- texts
    ["CChatBubble*"] = { ["r1"] = 0x21A0DC, ["r3"] = 0x26E8C0, ["r5"] = 0x26EB78, ["dl"] = 0x2ACA08 }, -- 10
    ["CChatBubble::Draw"] = { ["r1"] = 0x63310, ["r3"] = 0x66760, ["r5"] = 0x66ED0, ["dl"] = 0x66950 }, -- 11
    ["CLabelPool::Draw"] = { ["r1"] = 0x1340, ["r3"] = 0x1340, ["r5"] = 0x1350, ["dl"] = 0x1350 }, -- 12
    ["CDeathWindow*"] = { ["r1"] = 0x21A0F8, ["r3"] = 0x26E8DC, ["r5"] = 0x26EB88, ["dl"] = 0x2ACA18 }, -- 13
    ["CDeathWindow::GetSpriteId"] = { ["r1"] = 0x661B0, ["r3"] = 0x696E0, ["r5"] = 0x69E50, ["dl"] = 0x69890 }, -- 14
    -- dialogs
    ["CDialog::Show"] = { ["r1"] = 0x6B9C0, ["r3"] = 0x6F8C0, ["dl"] = 0x6FA50, ["r5"] = 0x6FFB0 }, -- 15
    ["CDialog::Draw"] = { ["r1"] = 0x6B240, ["r3"] = 0x6F140, ["dl"] = 0x6F2D0, ["r5"] = 0x6F890 }, -- 16
    ["CGame::SetCursorMode"] = { ["r1"] = 0x9BD30, ["r3"] = 0x9FFE0, ["dl"] = 0xA0530, ["r5"] = 0xA06F0 }, -- 17
    ["CDialog::Close"] = { ["r1"] = 0x6C040, ["r3"] = 0x6FF40, ["dl"] = 0x700D0, ["r5"] = 0x70630 }, -- 18 
    ["CDXUTControl::GetControl"] = {["r1"] = 0x82C50, ["r3"] = 0x86B60, ["dl"] = 0x86CF0, ["r5"] = 0x87270}
    -- 72 адреса :(
}

function getAddress(name)
    local version = sampGetVersion()
    local versionTable = addresses[name]
    if versionTable and versionTable[version] then
        return versionTable[version]
    else
        return nil
    end
end

local function refCConfig()
	return ffi.cast("void**", sampGetBase() + getAddress("refCConfig"))[0]
end

local function CConfig__GetIntValue(szKey)
	return ffi.cast("int(__thiscall*)(void*, const char*)", sampGetBase() + getAddress("CConfig::GetIntValue"))(refCConfig(), szKey);
end

local function CConfig__WriteIntValue(szKey, nValue, bReadOnly)
	return ffi.cast("void(__thiscall*)(void*, const char*, int, int)", sampGetBase() + getAddress("CConfig::WriteIntValue"))(refCConfig(), szKey, nValue, bReadOnly)
end

return {
    sampGetVer = sampGetVersion,
    getAddr = getAddress,
    getIntValueCfg = CConfig__GetIntValue,
    writeIntValueCfg = CConfig__WriteIntValue,
}