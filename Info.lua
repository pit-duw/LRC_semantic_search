--[[----------------------------------------------------------------------------

Info.lua
Summary information for Semantic search plug-in.

Adds menu items to Lightroom.
- 	"Export for search" in the File menu exports thumbnails for all photos in the
	current catalog and encodes them with open_clip to build the search index.
- 	"Search by text" in the Library menu displays a dialog window for searching
	images by text.
- 	"Search similar images" in the Library menu displays a dialog window for
	searching images similar to the selected image.

------------------------------------------------------------------------------]]

return {
	
	LrSdkVersion = 13.0,
	LrSdkMinimumVersion = 5.0, -- minimum SDK version required by this plug-in

	LrToolkitIdentifier = "com.pit.plugin.open_clipSearch",
	LrPluginInfoUrl = "Add github link here",

	LrPluginName = "Semantic Search",
	
	-- Add the "Export for search" menu item to the File menu.
	LrExportMenuItems = {
		{
			title = "Export for search",	
			file = "ExportForSearch.lua",
		},
	},

	-- Add the "Search by text" and "Search similar images" menu items to the Library menu.
	LrLibraryMenuItems = {
		{
			title = "Search by text",
			file = "SemanticSearch.lua",
		},
		{
			title = "Search similar images",
			file = "SimilarImageSearch.lua",
		},
	},
	VERSION = { major=13, minor=0, revision=0, build="202309270914-5a1c6485", },

}


	
