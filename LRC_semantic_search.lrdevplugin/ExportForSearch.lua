--[[----------------------------------------------------------------------------

ExportForSearch.lua
Exports thumbnails for all photos in the current catalog and encodes them with
open_clip to build the search index. 

------------------------------------------------------------------------------]]

-- Access the Lightroom SDK namespaces.
local LrApplication = import 'LrApplication'
local LrTasks = import 'LrTasks'
local LrPathUtils = import 'LrPathUtils'
local LrFileUtils = import 'LrFileUtils'
local LrDialogs = import 'LrDialogs'
local LrLogger = import 'LrLogger'
local LrProgressScope = import 'LrProgressScope'

-- Create the logger and enable the print function.
local myLogger = LrLogger( 'exportLogger' )
myLogger:enable( "print" )
-- Write trace information to the logger.
local function outputToLog( message )
	myLogger:trace( message )
end

local scriptPath = LrPathUtils.child(_PLUGIN.path, "EncodeImages.py ")
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



LrTasks.startAsyncTask(function()
    outputToLog("Exporting ")
    -- Get the list of photos in the catalog and build a set of their UUIDs
    local catalog = LrApplication.activeCatalog()
    local catalogPhotos = catalog:getAllPhotos()
    local catalogPhotoUUIDSet = {}
    for _, photo in ipairs(catalogPhotos) do
        catalogPhotoUUIDSet[photo:getRawMetadata("uuid")] = true
    end
    
    -- Get the list of photos that have already been exported
    local existingPhotos = LrFileUtils.files(_PLUGIN.path .. "\\images320\\")
    -- Delete all photos from the export folder that are not in the catalog, i.e. photos that have been deleted from the catalog, or photos from another catalog
    local existingPhotoUUIDSet = {}
    for filename in existingPhotos do
        local uuid = LrPathUtils.removeExtension(LrPathUtils.leafName(filename))
        -- If an file corresponds to a photo is in the catalog, add it to the set of existing photos so that it is not exported again 
        if catalogPhotoUUIDSet[uuid] then
            existingPhotoUUIDSet[uuid] = true
        else
            -- If it is not in the catalog, delete it
            outputToLog("Deleting " .. filename)
            LrFileUtils.delete(filename)
        end
    end

    local photosToExport = {}
    -- Build a list of photos that need to be exported
    for _, photo in ipairs(catalogPhotos) do
        -- If a photo is not already exported, add it to the list
        if not existingPhotoUUIDSet[photo:getRawMetadata("uuid")] then
            outputToLog("Adding to export list: " .. photo:getRawMetadata("uuid"))
            table.insert(photosToExport, photo)
        else 
            outputToLog("Skipping " .. photo:getRawMetadata("uuid"))
        end
    end

    local totalNumPhotos = #photosToExport

    -- Create a progress indicator
    local progressScope = LrProgressScope {
        title = "Exporting " .. totalNumPhotos  .. " new images to build search index...",
    }

    local folder = _PLUGIN.path .. "\\images320\\"
    LrTasks.execute("mkdir " .. folder)

    outputToLog("Exporting ")
    -- Keep count of the number of photos already exported 
    local completions = 0
    -- Keep a reference to each request, so that it is not garbage collected before the export is complete
    local refTable = {}
    for _, photo in ipairs( photosToExport ) do
        if progressScope:isCanceled() then
            break
        end

        local previewname =  photo:getRawMetadata("uuid") .. ".jpg"
        -- Call requestJpegThumbnail to export each photo. The function returns a reference object, which is stored in the refTable to prevent it from being garbage collected before the file is written.
        table.insert(refTable,  photo:requestJpegThumbnail(320, 320, function( success, failure )
            local f = io.open(folder .. previewname,"wb")
            f:write(success)
            f:close()
            completions = completions + 1
            outputToLog("Exported " .. previewname)
        end ))	
    end

    -- Wait for all photos to be exported
    while completions < totalNumPhotos and not progressScope:isCanceled() do
        progressScope:setPortionComplete(completions, totalNumPhotos)	
        outputToLog("Waiting for export ")
        LrTasks.sleep(2)
    end

    -- Build the search index, only if the export was not canceled
    if not progressScope:isCanceled() then
        progressScope:done()

        local progressScopeIndex = LrProgressScope {
            title = "Building search index...",
        }
        
        -- TODO: Ensure that this works on macOS
        local cmd = pythonCommand .. fixPath(scriptPath) .. "'"
        outputToLog("Executing: " .. cmd)
        local exitCode = LrTasks.execute(cmd)
        if exitCode ~= 0 then
            LrDialogs.showError("Error building search index.")
            progressScopeIndex:done()
            return
        end

        progressScopeIndex:done()
        LrDialogs.message("Search index has been built successfully. You can now search for images using the \"Semantic search\" plugin.")
    end

end)