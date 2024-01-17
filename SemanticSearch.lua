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

local function isInTable(t, value)
    for i, v in ipairs(t) do
        if v == value then
            return i
        end
    end
    return nil
end

-- rawData = LrFileUtils.readFile(dataPath)


--------------------------------------------------------------------------------

local function semanticSearchDialog()

	LrFunctionContext.callWithContext( "semanticSearchDialog", function( context )
	
		-- Create a bindable table.  Whenever a field in this table changes then notifications
		-- will be sent.  Note that we do NOT bind this to the UI.
		
		local props = LrBinding.makePropertyTable( context )
		props.mySearchString = "                                                    "
		
		local f = LrView.osFactory()
				
		-- Create the UI components like this so we can access the values as vars.
		
		local staticTextValue = f:static_text {
			title = props.mySearchString,
		}

		local updateField = f:edit_field {
			immediate = true,
			value = "Enter search term!"
		}

		local MaxSearchResults = f:edit_field {
			immediate = true,
			value = "4"
		}
				
		-- This is the function that will run when the value props.myString is changed.
		
		local function myCalledFunction()
			outputToLog( "props.mySearchString has been updated." )
			-- staticTextValue.title = updateField.value
			staticTextValue.text_color = LrColor ( 0, 1, 0 )
		end
		
		-- Add an observer to the property table.  We pass in the key and the function
		-- we want called when the value for the key changes.
		-- Note:  Only when the value changes will there be a notification sent which
		-- causes the function to be invoked.
		
		props:addObserver( "mySearchString", myCalledFunction )
				
		-- Create the contents for the dialog.
		
		local c = f:column {
			spacing = f:dialog_spacing(),
			f:row{
				fill_horizontal  = 1,
				f:static_text {
					alignment = "right",
					-- width = LrView.share "label_width",
					title = "Best image: "
				},
				staticTextValue,
			}, -- end f:row

			f:row {
				f:static_text {
					alignment = "right",
					width = LrView.share "label_width",
					title = "Number of results: "
				},
				MaxSearchResults,
			}, -- end row
			
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
						
						props.mySearchString = updateField.value
            
					-- local cmd = pythonCommand:gsub("__ARGS__", '"' .. fixPath(scriptPath) .. '"')
					local cmd = pythonCommand .. fixPath(scriptPath) .. '"Photo of ' .. props.mySearchString .. '"' .. " " .. MaxSearchResults.value .. "' > " .. tempFile
					local lines = {}
					outputToLog("Executing: " .. cmd)
					LrTasks.startAsyncTask(function()
						exitCode = LrTasks.execute(cmd)
						local cmdOutput = LrFileUtils.readFile(tempFile) -- Read the output from the temp file
						-- LrDialogs.showError("The Python script exited with status: " .. exitCode .. "\n\nOutput was:\n" .. cmdOutput .. "\n\nCommand line was:\n" .. cmd)

						local catalog = LrApplication.activeCatalog()
						local collectionName = "Search results" -- replace with your desired collection name
						
						-- local photosToAdd = {}
						
						catalog:withWriteAccessDo("Create Collection", function()
							local newCollection = catalog:createCollection(collectionName, nil, true)
							if newCollection then
								newCollection:removeAllPhotos()
								-- Find the photo with the given filename
								-- local photos = catalog:getAllPhotos()
								-- -- outputToLog(lines[1])
								-- local start_time = os.clock()
								-- for i, photo in ipairs(photos) do
								-- 	-- isInTable returns the index of the photo in the table if it is found, nil otherwise. The index in the table is equivalent to the search ranking.
								-- 	local photoIDinTable = isInTable(lines, tostring(photo.localIdentifier))
								-- 	if photoIDinTable then
								-- 		photosToAdd[photoIDinTable] = photo 
								-- 		-- break
								-- 	end
								-- end
								-- local end_time = os.clock()
								-- local elapsed_time = end_time - start_time
								-- outputToLog("Time taken: " .. elapsed_time .. " seconds")
								-- for i, photo in ipairs(photosToAdd) do
								-- 	outputToLog("Adding photo " .. photo:getRawMetadata("uuid") .. " to collection")
								-- 	newCollection:addPhotos({photo})
								-- end 
								for line in string.gmatch(cmdOutput, '([^\n]+)') do
									outputToLog("Adding photo " .. line .. " to collection")
									newCollection:addPhotos({catalog:findPhotoByUuid(line)})
								end
								

								-- LrDialogs.showError("Collection '" .. collectionName .. "' created successfully.")
								catalog:setActiveSources({newCollection})
							else
								LrDialogs.showError("Failed to create collection.")
							end
						end)
					end)



				end},
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

	end) -- end main function


end

--------------------------------------------------------------------------------
-- Display a dialog.
semanticSearchDialog()


