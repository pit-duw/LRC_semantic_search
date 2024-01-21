local LrApplication = import 'LrApplication'
local LrTasks = import 'LrTasks'
local LrPathUtils = import 'LrPathUtils'
local LrFileUtils = import 'LrFileUtils'
local LrDialogs = import 'LrDialogs'
local LrLogger = import 'LrLogger'
local LrProgressScope = import 'LrProgressScope'

local myLogger = LrLogger( 'exportLogger' )
myLogger:enable( "print" ) -- Pass either a string or a table of actions.
-- Write trace information to the logger.
local function outputToLog( message )
	myLogger:trace( message )
end

local scriptPath = LrPathUtils.child(_PLUGIN.path, "encode_images.py ")
local tempFile = LrPathUtils.child(_PLUGIN.path, "encode.dat")

local pythonCommand = "/usr/local/bin/python3 "
if WIN_ENV then
  -- Run Python through the Linux sub-system on Windows
  pythonCommand = "bash -c 'DISPLAY=:0 python3 "
end

function fixPath(winPath)
    -- Do nothing on OSX
    if MAC_ENV then
      return winPath
    end
  
    -- Replace Windows drive with mount point in Linux subsystem
    local path = winPath:gsub("^(.+):", function(c)
    return "/mnt/" .. c:lower()
    end)
  
    -- Flip slashes the right way
    return path:gsub("%\\", "/")
end

function countFiles(dir_path)
    local count = 0
    for file in LrFileUtils.files(dir_path) do
        count = count + 1
    end
    return count
end


local refObjTable = {}

LrTasks.startAsyncTask(function()
    
    outputToLog("Exporting ")
    local catalog = LrApplication.activeCatalog()
    local selectedPhotos = catalog:getAllPhotos()

    -- Create a progress indicator
    local progressScope = LrProgressScope {
        title = "Exporting images to build search index...",
    }

    local folder = _PLUGIN.path .. "\\images448\\"
    LrTasks.execute("mkdir " .. folder)
    -- make sure the folder is empty
    -- LrTasks.execute("del /Q " .. folder .. "*")
    -- LrTasks.execute("rm -rf " .. folder .. "*")

    outputToLog("Exporting ")
    local everythingExported = false
    for _, photo in ipairs( selectedPhotos ) do
        if progressScope:isCanceled() then
            break
        end
        local previewname =  photo:getRawMetadata("uuid") .. ".jpg"

        table.insert(refObjTable,  photo:requestJpegThumbnail(720, 720, function( success, failure )
            local f = io.open(folder .. previewname,"wb")
            f:write(success)
            f:close()
            outputToLog("Exported " .. previewname)
        end ))	
    end

    local fileCount = countFiles(folder)
    local totalNumPhotos = #selectedPhotos
    while fileCount < totalNumPhotos and not progressScope:isCanceled() do
        progressScope:setPortionComplete(fileCount, totalNumPhotos)	
        outputToLog("Waiting for export ")
        LrTasks.sleep(2)
        fileCount = countFiles(folder)
    end

    if not progressScope:isCanceled() then

        progressScope:done()

        local progressScopeIndex = LrProgressScope {
            title = "Building search index...",
        }
        local lines = {}
        local cmd = pythonCommand .. fixPath(scriptPath) .. "' > " .. tempFile
        outputToLog("Executing: " .. cmd)
        local exitCode = LrTasks.execute(cmd)
        if exitCode ~= 0 then
            LrDialogs.showError("Error building search index.")
            return
        end
        progressScopeIndex:done()
        LrDialogs.message("Search index has been built successfully. You can now search for images using the \"Semantic search\" plugin.")

    end

end)