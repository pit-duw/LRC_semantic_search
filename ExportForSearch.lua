local LrApplication = import 'LrApplication'
local LrTasks = import 'LrTasks'
local LrPathUtils = import 'LrPathUtils'
local LrFileUtils = import 'LrFileUtils'
local LrDialogs = import 'LrDialogs'
local LrExportSession = import 'LrExportSession'
local LrExportSettings = import 'LrExportSettings'
local LrLogger = import 'LrLogger'

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


local LrProgressScope = import 'LrProgressScope'

LrTasks.startAsyncTask(function()
    outputToLog("Exporting ")
    local catalog = LrApplication.activeCatalog()
    local selectedPhotos = catalog:getAllPhotos()

    -- Create a progress indicator
    local progressScope = LrProgressScope {
        title = "Exporting images to build search index...",
        functionContext = functionContext,
    }
    local folder = _PLUGIN.path .. "\\images448\\"
    LrTasks.execute("mkdir " .. folder)
    outputToLog("Exporting ")

    for i, photo in ipairs(selectedPhotos) do
        outputToLog("Exporting " .. i)
        if progressScope:isCanceled() then break end
        outputToLog("Exporting " .. photo:getRawMetadata("uuid"))

        local CatalogID = photo:getRawMetadata("uuid")
        local previewname =  CatalogID .. ".jpg"


        photo:requestJpegThumbnail(448, 448, function(success, failure)
            local f = io.open(folder .. previewname,"wb")
            f:write(success)
            f:close()

            -- Update the progress indicator
            -- progressScope:setPortionComplete(i, #selectedPhotos)
        end)

    end
    LrTasks.sleep(10.0)

    -- LrTasks.sleep(1.5)
    -- Done with the progress indicator
    progressScope:done()

    local progressScopeIndex = LrProgressScope {
        title = "Building search index...",
        functionContext = functionContext,
    }
    local lines = {}
    local cmd = pythonCommand .. fixPath(scriptPath) .. "' > " .. tempFile
    outputToLog("Executing: " .. cmd)
    exitCode = LrTasks.execute(cmd)
    if exitCode ~= 0 then
        LrDialogs.showError("Error building search index.")
        return
    end
    progressScopeIndex:done()
    LrDialogs.message("Search index has been built successfully. You can now search for images using the \"Semantic search\" plugin.")

end)

-- end )