--[[----------------------------------------------------------------------------

SemanticSearch.lua
Displays a dialog window with options for semantic search among the images in 
the current catalog. The dialog window contains a text field for specifying the
search term and one for specifying the maximum number of search results. 

------------------------------------------------------------------------------]]

-- Access the Lightroom SDK namespaces.
local LrFunctionContext = import 'LrFunctionContext'
local LrApplication = import 'LrApplication'
local catalog = import "LrApplication".activeCatalog()
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrLogger = import 'LrLogger'
local LrView = import 'LrView'
local LrFileUtils = import("LrFileUtils")
local LrPathUtils = import("LrPathUtils")
local LrTasks = import("LrTasks")

-- Create the logger and enable the print function.
local myLogger = LrLogger( 'exportLogger' )
myLogger:enable( "print" )
-- Write trace information to the logger.
local function outputToLog( message )
	myLogger:trace( message )
end


-- The path to the Python script used for searching images
local scriptPath = LrPathUtils.child(_PLUGIN.path, "search_image.py ")

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

	-- Create an edit field for updating the search term
	local updateField = f:edit_field {
		immediate = true,
		value = "Enter search term!" -- Default value for the search term
	}

	-- Create an edit field for specifying the maximum search results
	local MaxSearchResults = f:edit_field {
		immediate = true,
		value = "4" -- Default value for the maximum search results
	}
			
	-- Create the contents for the dialog.
	local c = f:column {
		spacing = f:dialog_spacing(),
		--[[ This section of code defines a row in a Lightroom plugin dialog box.
		It contains a static text field, an editable text field, and a push button.
		The push button triggers a search action when clicked.
		The search action executes a Python command with the specified search term and maximum search results.
		The output of the Python command is read from a temporary file and displayed in a Lightroom collection.
		If the collection does not exist, it is created.
		The collection is then set as the active source in the Lightroom catalog. ]]
		f:row {
			f:static_text {
				alignment = "right",
				width = LrView.share "label_width",
				title = "Search term: "
			},
			updateField,
			f:push_button {
				title = "Search",
				
				-- When the 'Update' button is clicked.
				action = function()
					outputToLog( "Search button clicked." )
					-- Execute the Python script with the specified search term and maximum search results
					-- The results are piped to a temporary file
					local cmd = pythonCommand .. fixPath(scriptPath) .. '"Photo of ' .. updateField.value .. '"' .. " " .. MaxSearchResults.value .. "' > " .. tempFile
					outputToLog("Executing: " .. cmd)
					LrTasks.startAsyncTask(function()
						local exitCode = LrTasks.execute(cmd)
						outputToLog("Python script exited with code " .. exitCode)
						local cmdOutput = LrFileUtils.readFile(tempFile) -- Read the output from the temp file
						local catalog = LrApplication.activeCatalog()
						
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
					end)
				end
			},
		},

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
	LrDialogs.presentModalDialog {
		title = "Semantic Search",
		contents = c,
	}

end

--------------------------------------------------------------------------------
-- Display the search dialog.
semanticSearchDialog()


