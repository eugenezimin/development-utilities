-- Map Mail's flag index to meaningful category names
on flagCategoryName(idx)
	-- Customize these to match how you actually use flag colors in Mail
	set categoryNames to {"Finance", "Attention", "So-So", "College", "Blue", "Innodata", "Other"}
	if idx ≥ 0 and idx < (count of categoryNames) then
		return item (idx + 1) of categoryNames
	else
		return "Unknown"
	end if
end flagCategoryName

set colorCounts to {0, 0, 0, 0, 0, 0, 0} -- counts for indices 0-6

tell application "Mail"
	repeat with acct in accounts
		repeat with mbox in mailboxes of acct
			try
				set flaggedMsgs to (messages of mbox whose flagged status is true)
				repeat with m in flaggedMsgs
					try
						set fIdx to flag index of m
						if fIdx ≥ 0 and fIdx < 7 then
							set item (fIdx + 1) of colorCounts to (item (fIdx + 1) of colorCounts) + 1
						end if
					end try
				end repeat
			end try
		end repeat
	end repeat
end tell

-- Build today's date at 9:00am
set dueDateTime to (current date)
set time of dueDateTime to (9 * 60 * 60) -- 9:00:00 AM, seconds since midnight

-- Push counts into Reminders, one reminder per category, replacing yesterday's
tell application "Reminders"
	if not (exists list "Reminders") then
		make new list with properties {name:"Reminders"}
	end if
	set reminderList to list "Reminders"
	
	repeat with i from 0 to 6
		set cName to my flagCategoryName(i)
		set cCount to item (i + 1) of colorCounts
		-- clear out any previous reminder for this category (matches "Finance:", "Attention:", etc.)
		delete (every reminder of reminderList whose name starts with (cName & ":"))
		if cCount > 0 then
			tell reminderList
				make new reminder with properties {name:cName & ": " & cCount & " Messages", body:"As of " & (current date), due date:dueDateTime, remind me date:dueDateTime}
			end tell
		end if
	end repeat
end tell