if not SertexOS then
	print("This shell is SertexOS 2 only")
	return
end

local multishell = multishell
local parentShell = shell
local parentTerm = term.current()

if multishell then
    multishell.setTitle( multishell.getCurrent(), "SertexShell" )
end

local bExit = false
local sDir = (parentShell and parentShell.dir()) or "/"
local sPath = (parentShell and parentShell.path()) or ".:/rom/programs"
local tAliases = (parentShell and parentShell.aliases()) or {}
local tProgramStack = {}

local shell = {}
local tEnv = {
	[ "shell" ] = shell,
	[ "multishell" ] = multishell,
}

-- Colours
local promptColour, textColour, bgColour
if term.isColour() then
	promptColour = colours.yellow
	textColour = colours.white
	bgColour = colours.black
else
	promptColour = colours.white
	textColour = colours.white
	bgColour = colours.black
end

local function run( _sCommand, ... )
	local sPath = shell.resolveProgram( _sCommand )
	if sPath ~= nil then
		tProgramStack[#tProgramStack + 1] = sPath
		if multishell then
		    multishell.setTitle( multishell.getCurrent(), fs.getName( sPath ) )
		end
   		local result = os.run( tEnv, sPath, ... )
		tProgramStack[#tProgramStack] = nil
		if multishell then
		    if #tProgramStack > 0 then
    		    multishell.setTitle( multishell.getCurrent(), fs.getName( tProgramStack[#tProgramStack] ) )
    		else
    		    multishell.setTitle( multishell.getCurrent(), "SertexShell" )
    		end
		end
		return result
   	else
    	printError( "No such program" )
    	return false
    end
end

local function tokenise( ... )
    local sLine = table.concat( { ... }, " " )
	local tWords = {}
    local bQuoted = false
    for match in string.gmatch( sLine .. "\"", "(.-)\"" ) do
        if bQuoted then
            table.insert( tWords, match )
        else
            for m in string.gmatch( match, "[^ \t]+" ) do
                table.insert( tWords, m )
            end
        end
        bQuoted = not bQuoted
    end
    return tWords
end

-- Install shell API
function shell.run( ... )
	local tWords = tokenise( ... )
	local sCommand = tWords[1]
	if sCommand then
		return run( sCommand, unpack( tWords, 2 ) )
	end
	return false
end

function shell.exit()
    bExit = true
end

function shell.dir()
	return sDir
end

function shell.setDir( _sDir )
	sDir = _sDir
end

function shell.path()
	return sPath
end

function shell.setPath( _sPath )
	sPath = _sPath
end

function shell.resolve( _sPath )
	local sStartChar = string.sub( _sPath, 1, 1 )
	if sStartChar == "/" or sStartChar == "\\" then
		return fs.combine( "", _sPath )
	else
		return fs.combine( sDir, _sPath )
	end
end

function shell.resolveProgram( _sCommand )
	-- Substitute aliases firsts
	if tAliases[ _sCommand ] ~= nil then
		_sCommand = tAliases[ _sCommand ]
	end

    -- If the path is a global path, use it directly
    local sStartChar = string.sub( _sCommand, 1, 1 )
    if sStartChar == "/" or sStartChar == "\\" then
    	local sPath = fs.combine( "/", _sCommand )
    	if fs.exists( sPath ) and not fs.isDir( sPath ) then
			return sPath
    	end
		return nil
    end
    
 	-- Otherwise, look on the path variable
    for sPath in string.gmatch(sPath, "[^:]+") do
    	sPath = fs.combine( shell.resolve( sPath ), _sCommand )
    	if fs.exists( sPath ) and not fs.isDir( sPath ) then
			return sPath
    	end
    end
	
	-- Not found
	return nil
end

function shell.programs( _bIncludeHidden )
	local tItems = {}
	
	-- Add programs from the path
    for sPath in string.gmatch(sPath, "[^:]+") do
    	sPath = shell.resolve( sPath )
		if fs.isDir( sPath ) then
			local tList = fs.list( sPath )
			for n,sFile in pairs( tList ) do
				if not fs.isDir( fs.combine( sPath, sFile ) ) and
				   (_bIncludeHidden or string.sub( sFile, 1, 1 ) ~= ".") then
					tItems[ sFile ] = true
				end
			end
		end
    end	

	-- Sort and return
	local tItemList = {}
	for sItem, b in pairs( tItems ) do
		table.insert( tItemList, sItem )
	end
	table.sort( tItemList )
	return tItemList
end

function shell.getRunningProgram()
	if #tProgramStack > 0 then
		return tProgramStack[#tProgramStack]
	end
	return nil
end

function shell.setAlias( _sCommand, _sProgram )
	tAliases[ _sCommand ] = _sProgram
end

function shell.clearAlias( _sCommand )
	tAliases[ _sCommand ] = nil
end

function shell.aliases()
	-- Add aliases
	local tCopy = {}
	for sAlias, sCommand in pairs( tAliases ) do
		tCopy[sAlias] = sCommand
	end
	return tCopy
end

if multishell then
    function shell.openTab( ... )
        local tWords = tokenise( ... )
        local sCommand = tWords[1]
        if sCommand then
        	local sPath = shell.resolveProgram( sCommand )
        	if sPath == ".SertexOS/apps/shell/app" then
                return multishell.launch( tEnv, sPath, unpack( tWords, 2 ) )
            elseif sPath ~= nil then
                return multishell.launch( tEnv, ".SertexOS/apps/shell/app", sPath, unpack( tWords, 2 ) )
            else
                printError( "No such program" )
            end
        end
    end

    function shell.switchTab( nID )
        multishell.setFocus( nID )
    end
end

shell.setAlias( "shell", "/.SertexOS/apps/shell/app" )

shell.setDir("user/"..SertexOS.u.."/desktop")

local tArgs = { ... }
if #tArgs > 0 then
    -- "shell x y z"
    -- Run the program specified on the commandline
    shell.run( ... )

else
    -- "shell"
    -- Print the header
		term.setTextColor(colors.yellow)
		print(os.version())
		term.setBackgroundColor(colors.black)
		term.setTextColor(colors.white)
    -- Run the startup program
    if parentShell == nil then
        shell.run( "/.SertexOS/SertexOS" )
    end

    -- Read commands and execute them
    local tCommandHistory = {}
    while not bExit do
        term.redirect( parentTerm )
        term.setBackgroundColor( bgColour )
        term.setTextColour( promptColour )
				if shell.dir() == "user/"..SertexOS.u.."/desktop" then
					dir = "Desktop"
				elseif shell.dir() == "user/"..SertexOS.u then
					dir = SertexOS.u
				else
					dir = shell.dir()
				end
				write(dir .. "> " )
        term.setTextColour( textColour )

        local sLine = read( nil, tCommandHistory )
        table.insert( tCommandHistory, sLine )
        shell.run( sLine )
    end
end
