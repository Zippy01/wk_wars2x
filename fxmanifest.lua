--[[---------------------------------------------------------------------------------------

	Wraith ARS 2X
	Created by WolfKnight

	For discussions, information on future updates, and more, join
	my Discord: https://discord.gg/fD4e6WD

	MIT License

	Copyright (c) 2020-2021 WolfKnight

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

---------------------------------------------------------------------------------------]] --

-- Define the FX Server version and game type
fx_version "cerulean"
game "gta5"

-- Define the resource metadata
name "Wraith ARS 2X"
description "Police radar and plate reader system for FiveM"
use_experimental_fxv2_oal 'yes'
nui_callback_strict_mode 'true'
lua54 'yes'

author "WolfKnight, modified to work with Imperial CAD."
version "1.3.1"

ui_page "nui/radar.html"

shared_script { "@ox_lib/init.lua" }

client_scripts {
	"client/radar.lua",
	"client/plate_reader.lua",
	"client/sync.lua"
}


server_scripts {
	"server/exports.lua",
	"server/plate_reader.lua",
	"server/sync.lua"
}


serer_export "TogglePlateLock"

files {
	"config.lua",
	"modules/*.lua",

	"nui/radar.html",
	"nui/radar.css",
	"nui/radar.js",
	"nui/images/*.png",
	"nui/images/plates/*.png",
	"nui/fonts/*.ttf",
	"nui/fonts/Segment7Standard.otf",
	"nui/sounds/*.ogg"
}
