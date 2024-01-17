--[[----------------------------------------------------------------------------

ADOBE SYSTEMS INCORPORATED
 Copyright 2007 Adobe Systems Incorporated
 All Rights Reserved.

NOTICE: Adobe permits you to use, modify, and distribute this file in accordance
with the terms of the Adobe license agreement accompanying it. If you have received
this file from a source other than Adobe, then your use, modification, or distribution
of it requires the prior written permission of Adobe.

--------------------------------------------------------------------------------

Info.lua
Summary information for Hello World sample plug-in.

Adds menu items to Lightroom.

------------------------------------------------------------------------------]]

return {
	
	LrSdkVersion = 3.0,
	LrSdkMinimumVersion = 1.3, -- minimum SDK version required by this plug-in

	LrToolkitIdentifier = 'com.adobe.lightroom.sdk.helloworld',

	LrPluginName = "$$$/HelloWorld/PluginName=Hello World Sample",
	
	-- Add the menu item to the File menu.
	
	LrExportMenuItems = {
		title = "Hello 1World1 Dialog",
		file = "ExportMenuItem.lua",
	},

	-- Add the menu item to the Library menu.
	
	LrLibraryMenuItems = {
	    {
		    title = "Hello World Custom1 Dialog",
		    file = "ShowCustomDialog.lua",
		},
		{
		    title = LOC "$$$/HelloWorld/MultiBind=Hello World Custom Dialog with MultipleBind",
		    file = "CustomDialogWithMultipleBind.lua",
		},
		{
		    title = LOC "$$$/HelloWorld/RadioButtons=Hello World RadioButtons",
		    file = "RadioButtons.lua",
		},
		{
		    title = LOC "$$$/HelloWorld/DialogObserver=Hello World Custom Dialog with Observer",
		    file = "CustomDialogWithObserver.lua",
		},
		{
			title = "Semantic search",
			file = "SemanticSearch.lua",
		},
		{
			title = "Export for search",	
			file = "ExportForSearch.lua",
		}

	},
	VERSION = { major=13, minor=0, revision=0, build="202309270914-5a1c6485", },

}


	
