local function crash(reason,message) --the crash error is only for OS crashes

	local function center(y, text )
		w, h = term.getSize()
		term.setCursorPos((w - #text) / 2, y)
		write(text)
	end
	os.pullEvent = os.pullEventRaw
	reasons = {
		["bypass"] = "System Bypassed",
		["security"] = "System Security Issue",
		["crash"] = "System Crashed",
		["unknown"] = "Unknown Error",
		["bios"] = "BIOS Error",
		["seretx"] = "SeretxOS 2 crashed again :C", -- Devs need fun
	}
		term.setBackgroundColor(colors.blue)
		term.clear()
		term.setCursorPos(1,1)
		term.setTextColor(colors.white)
		center(1,"SertexOS 2 Crashed:")
		if not reasons or not reasons[reason] then
			center(2,reasons["crash"])
		else
			center(2,reasons[reason])
		end
		
		if not message then
			center(4,"Undefined Crash")
		else
			print("\n\n"..message)
		end
		local x, y = term.getCursorPos()
		center(y+2,"Please reboot system!")
		center(y+3,"Please report the issue here:")
		center(y+4,"https://github.com/BeaconNet/SertexOS-2/issues")
		while true do
			sleep(0)
		end
end

local function kernel()

local baseDir = fs.getDir(shell.getRunningProgram())
SertexOS.baseDir = baseDir

local function log(text)
  local ftime = textutils.formatTime(os.time(), true)
  local str = "["..string.rep(" ", 5-ftime:len())..ftime.."] "..text
  if not SertexOS.quiet then
    print(str)
  end
  local f = fs.open(fs.combine(baseDir, "SertexOS.log"), "a")
  f.writeLine(str)
  f.close()
end

local function lock()
  os.pullEvent = os.pullEventRaw
end

local function unlock()
  os.pullEvent = ope
end

local function setLogging(val)
  if type(val) == "boolean" then
    SertexOS.quiet = not val
  end
end

SertexOS.configVersion = 3
SertexOS.languageID = "en"
SertexOS.dynamicClock = false

dofile("/.SertexOS/config")

function SertexOS.writeConfig(language, dynamicClock)
	if not language then
		language = SertexOS.languageID
	end
	if dynamicClock == nil then
		dynamicClock = SertexOS.dynamicClock
	end
	
	if dynamicClock == true then
		dynamicClock = "true"
	else
		dynamicClock = "false"	
	end
	local f = fs.open("/.SertexOS/config","w")
	f.write("if not SertexOS then SertexOS = {} end\n")
	f.write("SertexOS.configVersion = "..SertexOS.configVersion.."\n")
	f.write("SertexOS.languageID = \""..language.."\"\n")
	f.write("SertexOS.dynamicClock = "..dynamicClock)
	f.close()
end

log("System Online")

if fs.exists("/.SertexOS/lang/"..SertexOS.languageID..".lang") then
	dofile("/.SertexOS/lang/"..SertexOS.languageID..".lang")
else
	dofile("/.SertexOS/lang/en.lang")
end

if not fs.exists("/.SertexOS/system") then
	fs.makeDir("/.SertexOS/system")
end

local systemDir = "/.SertexOS"
local dbUsersDir = systemDir.."/databaseUsers/"
local folderUsersDir = "/user"

--getLoadedAPIs
local loadedAPIs = {}

local oldLoadAPI = os.loadAPI
local oldUnloadAPI = os.unloadAPI
function os.loadAPI(api)
	oldLoadAPI(api)
	table.insert(loadedAPIs, api)
	function os.getAPIs()
		return loadedAPIs
	end
end

function os.unloadAPI(api)
	oldUnloadAPI(api)
	table.remove(loadedAPIs, api)
end

--getTextColor

local oldTextColor = term.setTextColor
function term.setTextColor(color)
	oldTextColor(color)
	function term.getTextColor()
		return color
	end
end

--getBackgroundColor
local oldBGColor = term.setBackgroundColor
function term.setBackgroundColor(color)
	oldBGColor(color)
	function term.getBackgroundColor()
		return color
	end
end

local function checkVersion()
	local newVersion = http.get("https://raw.githubusercontent.com/BeaconNet/SertexOS-2/master/src/version").readLine()
	if SertexOS.version ~= newVersion then
		local updateS = ui.yesno("Update Sertex?","A new version of Sertex has been released")
		if updateS then
			setfenv(loadstring(http.get("https://raw.github.com/BeaconNet/SertexOS-2/master/upd.lua").readAll()),getfenv())()
		end
	end
end

-- clear

local function clear()
	term.setBackgroundColor(colors.white)
	term.clear()
	term.setCursorPos(1,1)
	term.setTextColor(colors.red)
end

-- header
local function header()
	clear()
	graphics.box(1,1,51,3, colors.red)
	term.setTextColor(colors.white)
	sertextext.center(2, "Sertex")
	term.setBackgroundColor(colors.white)
	term.setTextColor(colors.red)
	term.setCursorPos(1,5)
end

os.forceShutdown = os.shutdown
os.forceReboot = os.reboot

function os.reboot()
	repeat
		if multishell.getCount() < 2 then
			header()
			print("Close all tasks before reboot")
		end
		sleep(0.3)
	until multishell.getCount() < 2
	local function printMsg(color)
		term.setBackgroundColor(color)
		term.setTextColor(colors.white)
		term.clear()
		term.setCursorPos(1, 1)
		sertextext.centerDisplay(SertexOS.language.system_rebooting)
		sleep(0.1)
	end
	printMsg(colors.white)
	printMsg(colors.lightGray)
	printMsg(colors.gray)
	printMsg(colors.black)
	sleep(0.6)
	log("Reboot")
	os.forceReboot()
end

function os.shutdown()
	repeat
		if multishell.getCount() < 2 then
			header()
			print("Close all tasks before shutdown")
		end
		sleep(0.3)
	until multishell.getCount() < 2
	local function printMsg(color)
		term.setBackgroundColor(color)
		term.setTextColor(colors.white)
		term.clear()
		term.setCursorPos(1, 1)
		sertextext.centerDisplay(SertexOS.language.system_shuttingDown)
		sleep(0.1)
	end
	printMsg(colors.white)
	printMsg(colors.lightGray)
	printMsg(colors.gray)
	printMsg(colors.black)
	sleep(0.6)
	log("Shutdown")
	os.forceShutdown()
end


-- copy comgr to multitask
_G.multitask = comgr
multitask = comgr

-- about

local function about()
	header()
	sertextext.center(5, SertexOS.language.about_title)
	sertextext.left(7, "(c) Copyright 2015 SertexOS 2 - All Rights Reserved")
	sertextext.left(8, "Do not distribute!")
	sertextext.left(9, "Firewolf by GravityScore and 1lann")
	local bytes = fs.getFreeSpace("/")
	kbytes = bytes/1024
	bytes = bytes%1024
	mbytes = kbytes/1024
	kbytes = kbytes%1024
	gbytes = mbytes/1024
	mbytes = mbytes%1024
	tbytes = gbytes/1024
	gbytes = gbytes%1024
	 tbytes = tbytes*100
	bytes = gbytes*100
	mbytes = mbytes*100
  kbytes = kbytes*100
  bytes = bytes*100
   
  tbytes = math.floor(tbytes)
  gbytes = math.floor(gbytes)
  mbytes = math.floor(mbytes)
  kbytes = math.floor(kbytes)
  bytes = math.floor(bytes)
   
	tbytes = tbytes/100
  gbytes = gbytes/100
  mbytes = mbytes/100
  kbytes = kbytes/100
  bytes = bytes/100
	
	sertextext.center(11,SertexOS.language.about_freeSpace.." "..mbytes.."MB")
	sertextext.center(13,SertexOS.language.desktop_computerID..os.getComputerID())
	sertextext.center(15, SertexOS.language.pressAnyKey)
	os.pullEvent("key")
	return
end

-- settings

local function settings()
	
	local function changeLang()
		langs = {
			"English", --1
			"Italiano", --2
			"Deutsch", --3
			"Francais", --4
			"Suomi" --5
		}
		lock()
		while true do
			item, id = ui.menu(langs, language_title)
			if id == 1 then
				SertexOS.writeConfig("en")
				break
			elseif id == 2 then
				SertexOS.writeConfig("it")
				break
			elseif id == 3 then
				SertexOS.writeConfig("de")
				break
			elseif id == 4 then
				SertexOS.writeConfig("fr")
				break
			elseif id == 5 then
				SertexOS.writeConfig("fi")
				break
			end
		end
		requestReboot = ui.yesno(SertexOS.language.language_reboot2, SertexOS.language.language_reboot1)
		if requestReboot then
			os.reboot()
			else
				return
			end
	end
	
	local function changePassword()
		clear()
		header()
		sertextext.center(5, SertexOS.language.changePassword_title.." "..SertexOS.u.."\n\n")
		print("  "..SertexOS.language.changePassword_enterCurrentPassword)
		write("  > ")
		currentPW = read("*")
		f = fs.open(dbUsersDir..SertexOS.u, "r")
		pw = f.readLine()
		f.close()
		if sha256.sha256(currentPW) ~= pw then
			print("\n  "..wrongPassword)
			sleep(2)
			changePassword()
		else
			print("  "..SertexOS.language.changePassword_enterNewPassword)
			write("  > ")
			local newPW = read("*")
			print("  "..SertexOS.language.changePassword_repeatNewPassword)
			write("  > ")
			local repeatNewPW = read("*")
			if newPW == repeatNewPW then
				local f = fs.open(dbUsersDir..SertexOS.u, "w")
				f.write(sha256.sha256(newPW))
				f.close()
				print("\n  "..SertexOS.language.done)
				sleep(2)
			else
				print("\n  "..SertexOS.language.wrongPassword)
				sleep(2)
				changePassword()
			end
		end
		return
	end
	
	local function dynamicClock()
		local choose = ui.yesno(SertexOS.language.dynamicClock_enable)
		if choose then
			SertexOS.writeConfig(nil, true)
		else
			SertexOS.writeConfig(nil, true)	
		end
	end
	
	local function update()
		log("System Update")
		setfenv(loadstring(http.get("https://raw.github.com/BeaconNet/SertexOS-2/master/upd.lua").readAll()),getfenv())()
	end
	
	local function exitSettings()
		return
	end
	options = {
		SertexOS.language.settings_changeLang, --1
		SertexOS.language.settings_changePassword, --2
		SertexOS.language.settings_dynamicClock, --3
		SertexOS.language.settings_update, --4
		SertexOS.language.exit, --5
	}
	
	item, id = ui.menu(options, SertexOS.language.settings_title)
	
	if id == 1 then
		changeLang()
	elseif id == 2 then
		changePassword()
	elseif id == 3 then
		dynamicClock()
	elseif id == 4 then	
		update()
	elseif id == 5 then
		exitSettings()
	end
end

-- desktop

local function desktop()

	if SertexOS.u == nil then
		crash("bypass", "Username = nil")
	end

	function desktopHeader()
		local termW, termH = term.getSize()		

		term.setBackgroundColor(colors.white)
		term.clear()
		graphics.box(1,1,termW,1, colors.red)
		term.setBackgroundColor(colors.red)
		term.setCursorPos(1,1)
		term.setTextColor(colors.white)
		sertextext.center(1, "Sertex")
		sertextext.left(1, " "..SertexOS.u)
		sertextext.right(1, textutils.formatTime(os.time(), true))		
		term.setBackgroundColor(colors.white)
		term.setTextColor(colors.red)
	end

	while true do
		local termW, termH = term.getSize()

		local sidebar = {
			{SertexOS.language.mainMenu_shutdown, function()
				checkVersion()
				os.shutdown()
			end},
			{SertexOS.language.mainMenu_reboot, function()
				checkVersion()
				os.reboot()
			end},
			{SertexOS.language.mainMenu_logout, function()
				local function printMsg(color)
					term.setBackgroundColor(color)
					term.setTextColor(colors.white)
					term.clear()
					term.setCursorPos(1, 1)
					sertextext.centerDisplay(SertexOS.language.account_loggingOut)
					log("Logged Out "..SertexOS.u)
					sleep(0.1)
				end
				printMsg(colors.white)
				printMsg(colors.lightGray)
				printMsg(colors.gray)
				printMsg(colors.black)
				sleep(0.6)
				login()
			end},
			{SertexOS.language.mainMenu_settings, function()
				settings()
			end},
			{SertexOS.language.mainMenu_about, function()
				about()
			end},
		}
		
		local function app(name, x, y) -- the max characters are 7
			local applications = {
				["Shell"] = "shell",
				["Frwlf"] = "firewolf",
				["Files"] = "filemanager",
				["Progrms"] = "programs",
				["Links"] = "links",
			}
			
			appDir = "/.SertexOS/apps/"..applications[name]
			if fs.exists(appDir.."/logo") then
				appLogo = paintutils.loadImage(appDir.."/logo")
			else
				appLogo = paintutils.loadImage("/.SertexOS/defaultLogo")	
			end
			
			paintutils.drawImage(appLogo, x, y)
			
			maxX = x + 4
			maxY = y + 5
			
			if tonumber(#name) > 5 then
				term.setCursorPos(x - 1, maxY - 1)
			else
				term.setCursorPos(x, maxY - 1)
			end
			term.setBackgroundColor(colors.white)
			term.setTextColor(colors.red)
			write(name)
		end
		

		local sidebarVisible = false
		local sidebarWidth = 0
		for i, v in ipairs(sidebar) do
			if v[1]:len() > sidebarWidth then
				sidebarWidth = v[1]:len()
			end
		end

		local function redraw()
			desktopHeader()
			app("Shell", 2,3)
			app("Frwlf", 10,3)
			app("Files", 18,3)
			app("Links", 26,3)
			graphics.line(termW, 1, termW, termH, colors.red)
			term.setCursorPos(termW, math.ceil(termH / 2))
			term.setTextColor(colors.white)
			if sidebarVisible then
				graphics.box(termW - sidebarWidth - 4, 1, termW - sidebarWidth - 3, termH, colors.orange)
				graphics.box(termW - sidebarWidth - 2, 1, termW - 1, termH, colors.red)
				write(">")
				for i, v in ipairs(sidebar) do
					term.setCursorPos(termW - sidebarWidth, i + 1)
					write(v[1])
				end
			else
				write("<")
			end
		end
		
			lock()
		
		while true do
			sleep(0)
			redraw()
			if SertexOS.dynamicClock then
				local sTime = os.startTimer(0)
			end
			local ev = {os.pullEventRaw()}
			if ev[1] == "mouse_click" then
				local mx = ev[3]
				local my = ev[4]
				if ev[3] == termW then
					sidebarVisible = not sidebarVisible
				elseif ev[3] >= termW - sidebarWidth and    ev[3] <= termW - 1 and    ev[4] >= 2 and    sidebarVisible then
					if sidebar[ev[4] - 1] then
						sidebar[ev[4] - 1][2]()
					end
				elseif (mx > 2 - 1 and my > 3 - 1) and (mx < 6 + 1 and my < 8 + 1) then
					multishell.setFocus(shell.openTab("/.SertexOS/apps/shell/SertexShell"))
				elseif (mx > 8 - 1 and my > 3 - 1) and (mx < 14 + 1 and my < 8 + 1) then
					multishell.setFocus(shell.openTab("/.SertexOS/apps/firewolf/Firewolf"))
				elseif (mx > 14 - 1 and my > 3 - 1) and (mx < 22 + 1 and my < 8 + 1) then
					multishell.setFocus(shell.openTab("/.SertexOS/apps/filemanager/FileManager"))
				elseif (mx > 20 - 1 and my > 3 - 1) and (mx < 30 + 1 and my < 8 + 1) then
					multishell.setFocus(shell.openTab("/.SertexOS/apps/links/Links"))
				end
			end
			sleep(0)
		end
	end
end
-- login

function login()
	lock()
	clear()
	if not fs.exists("/.SertexOS/.userCreateOk") then
		while true do
			header()
			print( "  "..SertexOS.language.setup_title )
			print( "\n  "..SertexOS.language.setup_enterUsername )
			write( "  > " )
			u = read()
			if u == "" then
				print("  "..SertexOS.language.noUser)	
				log("No User on setup")
				sleep(2)
				login()
			elseif fs.isDir(dbUsersDir..u) or fs.exists(dbUsersDir..u) then
				print("  "..SertexOS.language.setup_existsUser)
				log("Invalid or existing user on setup")
				sleep(2)
				login()
			end
			print( "  "..SertexOS.language.setup_enterPassword )
			write( "  > " )
			p = read( "*" )
			print( "  "..SertexOS.language.setup_repeatEnterPassword )
			write( "  > " )
			rp = read("*")
			if p ~= rp then
				print("  "..SertexOS.language.wrongPassword)
				log("Wrong Password on setup")
				sleep(2)
				login()
			end
			encrtyptedPassword = sha256.sha256(p)
			SertexOS.user = u
			local correct1 =  SertexOS.language.setup_isUsernameCorrect1:gsub("%%username%%",u)
			choose = ui.yesno(SertexOS.language.setup_isUsernameCorrect2, correct1)
			if choose then
				print( "   "..SertexOS.language.writingData )
				f = fs.open( dbUsersDir..u, "w" )
				f.write( sha256.sha256(p) )
				f.close()
				fs.makeDir(folderUsersDir.."/"..u.."/desktop")
				log("Created Account "..u)
				sleep(0.1)
			else
				log("User deleted")
				sleep(0.1)
				login()
			end
			choose = ui.yesno(SertexOS.language.setup_createAnotherUser, "", false)
		
			if choose then
				sleep(0.1)
				log("Creating new user")
				login()
			else
				log("Stop making new users")
				userOk = fs.open(systemDir.."/.userCreateOk", "w")
				userOk.write("ignore me please")
				userOk.close()
				sleep(0.1)
				break
			end
			-- Admin
			if not fs.exists( "/.SertexOS/.userAdminCreateOk" ) then
				f = fs.open( "/.SertexOS/.userAdminCreateOk", "w" )
				f.write( "ignore me please" )
				f.close()
				header()
				print( "  " ..  SertexOS.language.setup_adminTitle )
				print( "\n  " .. SertexOS.language.setup_adminPass )
				write( "  > " )
				ap = read( "*" )
				print( "   " .. SertexOS.language.writingData )
				f = fs.open( dbUsersDir .. "admin", "w" )
				f.write( sha256.sha256( ap ) )
				f.close()
				fs.makeDir( folderUsersDir .. "/" .. "admin" .. "/desktop" )
				log( "Created Admin Account" )
			end
		end	
	end
		clear()
		local list = fs.list(dbUsersDir)
		local users = {}
		
		for i = 1, #list do
			if not fs.isDir(dbUsersDir..list[i]) then
				table.insert(users, list[i])
			end
		end
		
		SertexOS.u = ui.menu(users, SertexOS.language.login_title)
		if not SertexOS.u then
			login()
		end
		clear()
		header()
		
		print("  "..SertexOS.language.login_title)
		print("\n  "..SertexOS.u)
		write( "\n  "..SertexOS.language.login_password.." > " )
		p = read( "*" )
		encryptedPassword = sha256.sha256(p)
		if not fs.exists(dbUsersDir..SertexOS.u) or SertexOS.u == "" or fs.isDir(dbUsersDir..SertexOS.u) then
			print("  "..SertexOS.language.login_notRegistered)
			sleep(2)
			login()
		end
		f = fs.open( dbUsersDir..SertexOS.u, "r" )
		p2 = f.readLine()
		f.close()
		if encryptedPassword == p2 then
			SertexOS.user = SertexOS.u
			welcome = SertexOS.language.login_welcome:gsub("%%username%%",SertexOS.u)
			print( "\n  "..welcome)
			log("Logged In As "..SertexOS.u)
			sleep( 2 )
			SertexOS.user = SertexOS.u
			desktop()
		else
			printError( "  "..SertexOS.language.wrongPassword )
			log("Incorrect Password from "..SertexOS.u.." Password: "..p)
			sleep( 2 )
			SertexOS.u = nil
			login()
		end
			
end

login()
end

local ok, err = pcall(kernel)

if not ok then
	crash("crash", err)	
end
