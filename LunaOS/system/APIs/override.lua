--firstly gets loaded into the global enviroment
--then gets reloaded in to each process enviroment

local isLoading = {}
local toInit = {}
local oldfs = fs

os.pullEvent = coroutine.yield

function os.loadAPI(path, locally)
	if type(path) ~= "string" then error("Error: string expected got " .. type(path), 2) end
	
	local name = fs.getName(path):gmatch("([^.]+)")():gsub(" ", "_")
        
	if isLoading[path] then
			return false
	end
	
	isLoading[path] = true
	log.i("Loading API " .. path)
	
	local env = {}
		
	setmetatable(env, {__index = getfenv(), __metatable = ""})
	local APIFunc, err = loadfile(path)
	
	if APIFunc then
		setfenv(APIFunc, env)
		
		local status, err2 = pcall(APIFunc)
		if not status then
			error("Error loading " .. path .. ": " .. err2)
			log.e("Error loading " .. path .. ": " .. err2)
		end
		
	else
			error("Error loading " .. path .. ": " .. err)
			log.e("Error loading " .. path .. ": " .. err)
			return false, err
	end
	
	local APITable = {}
	for k, v in pairs(env) do
			APITable[k] =  v
	end
	
	if not locally then
		_G[name] = APITable
	end
	
	isLoading[path] = nil
	toInit[#toInit + 1] = name
	log.i("Succsess: loaded " .. path .. " as " .. name)
	return locally and APITable or true
end

function os.unloadAPI(name)
	if name ~= "_G" and type(_G[name] == "table") then
		_G[name] = nil
	end
end

function os.loadAPIList(path)
	if type(path) ~= "string" then error("Error: string expected got " .. type(path), 2) end

	local file = fs.open(path, 'r')
	if file then
		local currentLine
		
		while true do
			currentLine = file.readLine()
			if currentLine == nil then break end
			
			if fs.exists(currentLine) then 
				if fs.isDir(currentLine) then
					os.loadAPIDir(currentLine)
				else 
					os.loadAPI(currentLine)
				end
			end
		end
	
	file.close()
	end
end

function os.loadAPIDir(path)
	if type(path) ~= "string" then error("Error: string expected got " .. type(path), 2) end
	if not fs.isDir(path) then error("Error: " .. path .. " is not a directory", 2) end
	
	for _, file in pairs(fs.list(path)) do
		if not fs.isDir(file) then
			os.loadAPI(fs.combine(path, file))
		end
	end
end

function os.initAPIs()
	for _,v in pairs(toInit) do
		if _G[v].init then _G[v].init() end
		_G[v].init = nil
	end
end

local oldSetComputerLabel = os.setComputerLabel
function os.setComputerLabel(label)
	errorUtils.expect(label, string, false, 2)
	errorUtils.assert(kernel.isSU(), "")
	
	oldSetComputerLabel(label)
end
