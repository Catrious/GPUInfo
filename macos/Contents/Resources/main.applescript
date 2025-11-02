-- Detect OpenGL version
set glVersion to "OpenGL not supported"
try
    set glVersionRaw to do shell script "system_profiler SPDisplaysDataType | grep 'OpenGL Version' | awk -F': ' '{print $2}'"
    if glVersionRaw is not "" then
        set AppleScript's text item delimiters to "."
        set itemsList to text items of glVersionRaw
        set glVersion to itemsList's item 1 & "." & itemsList's item 2
        set AppleScript's text item delimiters to ""
    end if
on error
    set glVersion to "OpenGL not supported"
end try

-- Add prefix if not included
if glVersion does not start with "OpenGL" and glVersion is not "OpenGL not supported" then
    set glVersion to "OpenGL " & glVersion
end if

-- Detect Metal version
set metalVersion to "Metal not supported"
try
    set metalInfo to do shell script "system_profiler SPDisplaysDataType | grep 'Metal'"
    if metalInfo contains "Supported" then
        try
            set AppleScript's text item delimiters to ":"
            set parts to text items of metalInfo
            set versionStr to last item of parts
            set versionStr to (do shell script "echo " & quoted form of versionStr & " | sed 's/^[ \t]*//'")
            set AppleScript's text item delimiters to ""
            set metalVersion to versionStr
        on error
            set metalVersion to "1.0"
        end try
    end if
on error
    set metalVersion to "not supported"
end try

-- Add prefix if not included
if metalVersion does not start with "Metal" and metalVersion is not "not supported" then
    set metalVersion to "Metal " & metalVersion
else if metalVersion is "not supported" then
    set metalVersion to "Metal not supported"
end if

-- Display results
display dialog glVersion & return & metalVersion buttons {"OK"} default button "OK"
