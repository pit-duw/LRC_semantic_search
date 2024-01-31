--[[----------------------------------------------------------------------------

SemanticSearch.lua
Displays a dialog window with options for search similar images in 
the current catalog. The dialog window contains a text field for specifying the
number of search results. 

------------------------------------------------------------------------------]]

-- Access the Lightroom SDK namespaces.
local LrFunctionContext = import 'LrFunctionContext'
local LrApplication = import 'LrApplication'
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrLogger = import 'LrLogger'
local LrView = import 'LrView'
local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'
local LrTasks = import 'LrTasks'
local LrProgressScope = import 'LrProgressScope'

-- Create the logger and enable the print function.
local myLogger = LrLogger( 'exportLogger' )
myLogger:enable( "print" )
-- Write trace information to the logger.
local function outputToLog( message )
	myLogger:trace( message )
end


-- The path to the Python script used for searching images
local scriptPath = LrPathUtils.child(_PLUGIN.path, "ImageSearch.py ")

-- The path to the temporary file used for storing the search result data
local tempFile = LrPathUtils.child(_PLUGIN.path, "temp.dat")

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


--------------------------------------------------------------------------------


local function semanticSearchDialog()
	-- Create an OS-specific view factory
	local f = LrView.osFactory()

	-- Create an edit field for specifying the maximum search results
	local MaxSearchResults = f:edit_field {
		immediate = true,
		value = "10" -- Default value for the maximum search results
	}
			
	-- Create the contents for the dialog.
	local c = f:column {
		spacing = f:dialog_spacing(),
		--[[ This section of code defines a row in a Lightroom plugin dialog box.
		It contains a static text field and an editable text field. ]]

		-- Create a field for specifying the maximum number of search results
		f:row {
			f:static_text {
				alignment = "right",
				width = LrView.share "label_width",
				title = "Number of results: "
			},
			MaxSearchResults,
		},

		-- Display notes on how to use the plugin
		f:static_text {
			alignment = "left",
			width = 400,
			wrap = true,
			height_in_lines = 3,
			title = "The plugin creates a new collection \"Search results\". To get the photos ordered by search ranking, please sort the collection by \"Custom sort\". (This cannot be done automatically)."
		},
	}
	
	-- Presents a modal dialog for semantic search.
	local result = LrDialogs.presentModalDialog {
		title = "Semantic Search",
        actionVerb = "Search", -- label for the action button
		contents = c,
	}
    
    --[[ The action button triggers a search when clicked.
    The search action executes a Python command with the UUID of the currently 
    selected photo and maximum number of search results.
    The output of the Python command is read from a temporary file and displayed 
    in a Lightroom collection "Search results". If the collection does not exist,
    it is created. The collection is then set as the active source in the 
    Lightroom catalog. ]]
    if result == 'ok' then -- action button was clicked
        LrTasks.startAsyncTask(function()
			-- Create a progress indicator
			local progressScope = LrProgressScope {
				title = "Performing search ...",
			}
            outputToLog( "Search button clicked." )
            local catalog = LrApplication.activeCatalog()
            local photo = catalog:getTargetPhoto()
            if photo == nil then
                LrDialogs.showError("Please select exactly one photo.")
                return
            end

            -- Execute the Python script with the specified search term and maximum search results
            -- The results are piped to a temporary file
            local cmd = pythonCommand .. fixPath(scriptPath) .. '"' .. photo:getRawMetadata("uuid") .. '"' .. " " .. MaxSearchResults.value .. "' > " .. tempFile
            outputToLog("Executing: " .. cmd)
            local exitCode = LrTasks.execute(cmd)
			if exitCode ~= 0 then
				LrDialogs.showError("Error searching an image. Make sure that you have properly built the search index. (File > Plug-in extras > Export for search).")
				progressScopeIndex:done()
				return
			end
            outputToLog("Python script exited with code " .. exitCode)
            local cmdOutput = LrFileUtils.readFile(tempFile) -- Read the output from the temp file
            
            -- Creates a new collection in the Lightroom catalog and adds photos to it.
            -- The collection is created with the specified name and is set as the active source.
            -- If the collection creation fails, an error message is displayed.
            catalog:withWriteAccessDo("Create Collection", function()
                local newCollection = catalog:createCollection("Search results", nil, true)
                if newCollection then
                    newCollection:removeAllPhotos()
                    -- Iterate over the lines in the output from the Python script
                    for line in string.gmatch(cmdOutput, '([^\n]+)') do
                        outputToLog("Adding photo " .. line .. " to collection")
                        newCollection:addPhotos({catalog:findPhotoByUuid(line)})
                    end
                    catalog:setActiveSources({newCollection})
                else
                    LrDialogs.showError("Failed to create collection.")
                end
            end)
			progressScope:done()
        end)
    end

end

--------------------------------------------------------------------------------
-- Display the search dialog.
semanticSearchDialog()


