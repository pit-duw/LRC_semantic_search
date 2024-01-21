local Require = require "Require".path ("../debuggingtoolkit.lrdevplugin").reload ()

local Debug = require "Debug".init ()

require "strict"

--[[----------------------------------------------------------------------------

SemanticSearch.lua
Displays a dialog window with options for semantic search among the images in 
the current catalog. 

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
myLogger:enable( "print" ) -- Pass either a string or a table of actions.
-- Write trace information to the logger.
local function outputToLog( message )
	myLogger:trace( message )
end


local scriptPath = LrPathUtils.child(_PLUGIN.path, "search_image.py ")
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
		
	local f = LrView.osFactory()

	local updateField = f:edit_field {
		immediate = true,
		value = "Enter search term!"
	}

	local MaxSearchResults = f:edit_field {
		immediate = true,
		value = "4"
	}
			
	-- Create the contents for the dialog.
	local c = f:column {
		spacing = f:dialog_spacing(),
		
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
					
		
					local cmd = pythonCommand .. fixPath(scriptPath) .. '"Photo of ' .. updateField.value .. '"' .. " " .. MaxSearchResults.value .. "' > " .. tempFile
					local lines = {}
					outputToLog("Executing: " .. cmd)
					LrTasks.startAsyncTask(function()
						local exitCode = LrTasks.execute(cmd)
						local cmdOutput = LrFileUtils.readFile(tempFile) -- Read the output from the temp file
						-- LrDialogs.showError("The Python script exited with status: " .. exitCode .. "\n\nOutput was:\n" .. cmdOutput .. "\n\nCommand line was:\n" .. cmd)

						local catalog = LrApplication.activeCatalog()
						local collectionName = "Search results" 
						
						catalog:withWriteAccessDo("Create Collection", function()
							local newCollection = catalog:createCollection(collectionName, nil, true)
							if newCollection then
								newCollection:removeAllPhotos()
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
		}, -- end row

		f:row {
			f:static_text {
				alignment = "right",
				width = LrView.share "label_width",
				title = "Number of results: "
			},
			MaxSearchResults,
		}, -- end row

		f:static_text {
			alignment = "left",
			width = 400,
			wrap = true,
			height_in_lines = 3,
			title = "The plugin creates a new collection \"Search results\". To get the photos ordered by search ranking, please sort the collection by \"Custom sort\". (This cannot be done automatically)."
		},
	} -- end column
	
	LrDialogs.presentModalDialog {
		title = "Semantic Search",
		contents = c,
	}

end

--------------------------------------------------------------------------------
-- Display a dialog.
semanticSearchDialog()


