#!/usr/bin/osascript

on readAndSplitFile(theFile, theDelimiter)
	-- Convert the file to a string
	set theFile to theFile as string

	-- Read the file using a specific delimiter and return the results
	return read POSIX file theFile using delimiter {"=", "\n"}
end readAndSplitFile

on parseConfigFile(thingToFind)
	-- get ~/.config/tabcounter.conf
	set configFileLocation to (((POSIX path of (path to home folder from user domain)) as text) & ".config/tabcounter.conf")
	set configFileSplit to readAndSplitFile(configFileLocation, "\n")
	set configItems to text items of configFileSplit
	repeat with I from 1 to (count of configItems) --loop through each item
		set currentLine to item I of configItems
		if currentLine contains thingToFind then
			return item (I+1) of configItems
		end if
	end repeat
end parseConfigFile

set doBBEdit to 0
set popAlert to 0
set sendToHEC to 1
set hostName to do shell script "/bin/hostname -s"

set baseURL to parseConfigFile("HEC_URL") & "=" & hostName
set hecToken to parseConfigFile("HEC_TOKEN")

tell application "Safari"
	-- Script running variables
	set windowCount to number of windows
	set tabCountTotal to 0
	set docText to ""

	--Repeat for Every Window
	repeat with windowNumber from 1 to windowCount
		set tabcount to number of tabs in window windowNumber
		set tabCountTotal to tabCountTotal + tabcount

		set docText to docText & "Tab count: " & tabcount & linefeed as string

		--set docText to docText & "<ul>" & linefeed as string
		--Repeat for Every Tab in Current Window
		--repeat with y from 1 to tabcount

		--Get Tab Name & URL
		--set tabName to name of tab y of window windowNumber
		--set tabURL to URL of tab y of window windowNumber
		--set docText to docText & "<li><a href=" & "\"" & tabURL & "\">" & tabName & "</a></li>" & linefeed as string
		--end result epeat
		--set docText to docText & "</ul>" & linefeed as string

	end repeat
	log "Tab count: " & tabCountTotal
	set docText to docText & "<br />Total tabs: " & tabCountTotal & linefeed as string
end tell

if (doBBEdit = 1) then
	--Write Document Text
	tell application "BBEdit"
		activate
		make new document
		set the text of the front document to docText
	end tell
end if

if (sendToHEC = 1) then
	--do shell script
	-- hostName
	--\"host\":\"" & hostName & "\",
	set dataValue to "{\"tabs\":" & tabCountTotal & ", \"windows\":" & windowCount & "}"
	set authHeader to "Authorization: Splunk " & hecToken

	set outputValue to do shell script "/usr/bin/curl -v -H " & quoted form of authHeader & " --data " & quoted form of dataValue & " " & quoted form of baseURL
	log "Response from cURL: " & outputValue
end if

if (popAlert = 1) then
	tell application "Script Editor"
		activate
	end tell
	display alert "Total tabs: " & tabCountTotal
end if

-- end