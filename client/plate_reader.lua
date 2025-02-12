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

local PLY = require('modules.player')
local utils = require('modules.utils')
local config = lib.load('config')

local GetVehicleClass = GetVehicleClass
local GetOffsetFromEntityInWorldCoords = GetOffsetFromEntityInWorldCoords
local DoesEntityExist = DoesEntityExist
local IsEntityAVehicle = IsEntityAVehicle
local GetEntityHeading = GetEntityHeading
local GetVehicleNumberPlateText = GetVehicleNumberPlateText
local GetVehicleNumberPlateTextIndex = GetVehicleNumberPlateTextIndex
local IsVehiclePreviouslyOwnedByPlayer = IsVehiclePreviouslyOwnedByPlayer
local IsPauseMenuActive = IsPauseMenuActive

READER = {}

--[[----------------------------------------------------------------------------------
	Plate reader variables

	NOTE - This is not a config, do not touch anything unless you know what
	you are actually doing.
----------------------------------------------------------------------------------]] --
READER.vars =
{
	-- Whether or not the plate reader's UI is visible
	displayed = false,

	-- Whether or not the plate reader should be hidden, e.g. the display is active but the player then steps
	-- out of their vehicle
	hidden = false,

	-- The BOLO plate
	boloPlate = "",

	lastScannedFrontPlate = {},
	lastScannedRearPlate = {},

	-- Cameras, this table contains all of the data needed for operation of the front and rear plate reader
	cams = {
		-- Variables for the front camera
		["front"] = {
			plate = "", -- The current plate caught by the reader
			index = "", -- The index of the current plate
			locked = false -- If the reader is locked
		},

		-- Variables for the rear camera
		["rear"] = {
			plate = "", -- The current plate caught by the reader
			index = "", -- The index of the current plate
			locked = false -- If the reader is locked
		}
	}
}


--[[----------------------------------------------------------------------------------
	Plate reader functions
----------------------------------------------------------------------------------]] --
-- Gets the display state
function READER:GetDisplayState()
	return self.vars.displayed
end

-- Toggles the display state of the plate reader system
function READER:ToggleDisplayState()
	-- Toggle the display variable
	self.vars.displayed = not self.vars.displayed

	-- Send the toggle message to the NUI side
	SendNUIMessage({ _type = "setReaderDisplayState", state = self:GetDisplayState() })
end

-- Getter and setter for the display hidden state
function READER:GetDisplayHidden() return self.vars.hidden end

function READER:SetDisplayHidden(state) self.vars.hidden = state end

-- Getter and setter for the given camera's plate
function READER:GetPlate(cam) return self.vars.cams[cam].plate end

function READER:SetPlate(cam, plate) self.vars.cams[cam].plate = plate end

-- Getter and setter for the given camera's plate display index
function READER:GetIndex(cam) return self.vars.cams[cam].index end

function READER:SetIndex(cam, index) self.vars.cams[cam].index = index end

-- Returns the bolo plate
function READER:GetBoloPlate()
	if (self.vars.boloPlate ~= nil) then
		return self.vars.boloPlate
	end
end

-- Sets the bolo plate to the given plate
function READER:SetBoloPlate(plate)
	self.vars.boloPlate = plate
	utils.notify("BOLO plate set to: ~b~" .. plate)
end

-- Clears the BOLO plate
function READER:ClearBoloPlate()
	self.vars.boloPlate = nil
	utils.notify("~b~BOLO plate cleared!")
end

-- Returns if the given reader is locked
function READER:GetCamLocked(cam) return self.vars.cams[cam].locked end

-- Locks the given reader
function READER:LockCam(cam, playBeep, isBolo, override)
	-- Check that plate readers can actually be locked
	if (PLY:VehicleStateValid() and self:CanPerformMainTask() and self:GetPlate(cam) ~= "") then
		-- Toggle the lock state
		self.vars.cams[cam].locked = not self.vars.cams[cam].locked

		-- Play a beep
		if (self:GetCamLocked(cam)) then
			-- Here we check if the override parameter is valid, if so then we set the reader's plate data to the
			-- plate data provided in the override table.
			if (override ~= nil) then
				self:SetPlate(cam, override[1])
				self:SetIndex(cam, override[2])

				self:ForceNUIUpdate(false)
			end

			if (playBeep) then
				SendNUIMessage({ _type = "audio", name = "beep", vol = RADAR:GetSettingValue("plateAudio") })
			end

			if (isBolo) then
				SendNUIMessage({ _type = "audio", name = "plate_hit", vol = RADAR:GetSettingValue("plateAudio") })
			end

			-- Trigger an event so developers can hook into the scanner every time a plate is locked
			TriggerServerEvent("wk:onPlateLocked", cam, self:GetPlate(cam), self:GetIndex(cam))
		end

		-- Tell the NUI side to show/hide the lock icon
		SendNUIMessage({ _type = "lockPlate", cam = cam, state = self:GetCamLocked(cam), isBolo = isBolo })
	end
end

-- Returns if the plate reader system can perform tasks
function READER:CanPerformMainTask()
	return self.vars.displayed and not self.vars.hidden
end

-- Returns if the given relative position value is for front or rear
function READER:GetCamFromNum(relPos)
	if (relPos == 1) then
		return "front"
	elseif (relPos == -1) then
		return "rear"
	end
end

-- Forces an NUI update, used by the passenger control system
function READER:ForceNUIUpdate(lock)
	for cam in utils.values({ "front", "rear" }) do
		local plate = self:GetPlate(cam)
		local index = self:GetIndex(cam)

		if (plate ~= "" and index ~= "") then
			SendNUIMessage({ _type = "changePlate", cam = cam, plate = plate, index = index })

			if (lock) then
				SendNUIMessage({ _type = "lockPlate", cam = cam, state = self:GetCamLocked(cam), isBolo = false })
			end
		end
	end
end

-- Returns a table with both antenna's speed data and directions
function READER:GetCameraDataPacket(cam)
	return {
		self:GetPlate(cam),
		self:GetIndex(cam)
	}
end

RegisterNetEvent("wk:togglePlateLock")
AddEventHandler("wk:togglePlateLock", function(cam, beep, bolo)
	READER:LockCam(cam, beep, bolo)
end)


--[[----------------------------------------------------------------------------------
	Plate reader NUI callbacks
----------------------------------------------------------------------------------]] --
-- Runs when the "Toggle Display" button is pressed on the plate reder box
RegisterNUICallback("togglePlateReaderDisplay", function(data, cb)
	-- Toggle the display state
	READER:ToggleDisplayState()
	cb("ok")
end)

-- Runs when the "Set BOLO Plate" button is pressed on the plate reader box
RegisterNUICallback("setBoloPlate", function(plate, cb)
	-- Set the BOLO plate
	READER:SetBoloPlate(plate)
	cb("ok")
end)

-- Runs when the "Clear BOLO Plate" button is pressed on the plate reader box
RegisterNUICallback("clearBoloPlate", function(plate, cb)
	-- Clear the BOLO plate
	READER:ClearBoloPlate()
	cb("ok")
end)


--[[----------------------------------------------------------------------------------
	Plate reader threads
----------------------------------------------------------------------------------]] --

--- Could probably refactor to use onCache instead of a thread.
-- CreateThread(function()
-- 	while true do
-- 		local vehicle = cache.vehicle
-- 		local vehicleClass = GetVehicleClass(vehicle) == 18

-- 		if vehicle and vehicleClass then
-- 			if READER:CanPerformMainTask() then
-- 				READER:Main()
-- 			end

-- 			READER:RunDisplayValidationCheck()
-- 			Wait(500)
-- 		else
-- 			READER:RunDisplayValidationCheck()
-- 			Wait(1000)
-- 		end
-- 	end
-- end)

local function isPlateAlreadyScanned(plate, cam)
	if cam == "front" then
		return READER.vars.lastScannedFrontPlate[plate]
	else
		return READER.vars.lastScannedRearPlate[plate]
	end
end

---@param title string The title of the notification
---@param description string The description text
---@param type 'success'|'error'|'warning'|'inform' The notification type
---@param icon string The icon name to display
---@param duration? number Optional duration in ms (defaults to 5000)
local function plateNotify(id, title, description, type, icon, duration)
	lib.notify({
		id = id,
		title = title,
		description = description,
		type = type,
		position = 'center-left',
		duration = duration or 5000,
		style = {
			backgroundColor = '#1a1a1a',
			color = '#ffffff',
			borderRadius = '4px',
			border = '1px solid rgba(255,255,255,0.1)',
			padding = '12px',
			boxShadow = '0 2px 4px rgba(0,0,0,0.2)',
			width = '300px',
			['&.description'] = {
				['padding-top'] = '12px',
				['padding-bottom'] = '8px',
				['font-size'] = '1.1em'
			}
		},
		icon = icon,
		alignIcon = 'top',
		iconColor = type == 'error' and '#ff3333' or
			type == 'warning' and '#ffb347' or
			type == 'inform' and '#3399ff',
		iconAnimation = 'spin'
	})
end

---Scans a plate and shows notifications for any issues found
---@param plate string The license plate to scan
local function scanPlate(plate)
	if isPlateAlreadyScanned(plate) then return end

	---@type PlateInfo
	local res = lib.callback.await("wk:scanPlate", false, plate)
	if not res then return end

	local hasWarnings = false
	if res.stolen or res.owner_wanted then
		hasWarnings = true
		plateNotify(
			("(%s1)"):format(plate),
			'🚨 High Priority Alert',
			("Owner: %s\n\n%s%s"):format(
				res.owner,
				res.stolen and "• Vehicle Reported Stolen\n" or "",
				res.owner_wanted and "• Owner Has Active Warrant(s)" or ""
			),
			'error',
			'handcuffs',
			15000
		)
	end
	if (res.insurance and res.insurance_status ~= "ACTIVE") or res.reg_status ~= "ACTIVE" then
		hasWarnings = true
		plateNotify(
			("(%s2)"):format(plate),
			'📄 Documentation Status',
			("Owner: %s\n\n%s%s"):format(
				res.owner,
				res.insurance and res.insurance_status ~= "ACTIVE" and "• Insurance Invalid\n" or "",
				res.reg_status ~= "ACTIVE" and "• Registration Not Active" or ""
			),
			'warning',
			'file-circle-xmark',
			15000
		)
	end
	if res.owner_dl_status ~= "ACTIVE" or res.business then
		hasWarnings = true
		plateNotify(
			("(%s3)"):format(plate),
			'👤 Owner Information',
			("Owner: %s\n\n%s%s"):format(
				res.owner,
				res.owner_dl_status ~= "ACTIVE" and "• License Invalid\n" or "",
				res.business and ("• Commerical Vehicle: %s"):format(res.business) or ""
			),
			'warning',
			'id-card',
			15000
		)
	end
	if hasWarnings then
		plateNotify(
			("(%s4)"):format(plate),
			'🚗 Vehicle Summary',
			("Plate: %s\nOwner: %s"):format(res.plate, res.owner),
			'inform',
			'car',
			15000
		)
	end
end


-- This is the main function that runs and scans all vehicles in front and behind the patrol vehicle
function READER:Main()
	if (PLY:VehicleStateValid() and self:CanPerformMainTask()) then
		-- Loop through front (1) and rear (-1)
		for i = 1, -1, -2 do
			-- Get a start position 5m in front/behind the player's vehicle
			local start = GetOffsetFromEntityInWorldCoords(PLY.veh, 0.0, (5.0 * i), 0.0)

			-- Get the end position 50m in front/behind the player's vehicle
			local offset = GetOffsetFromEntityInWorldCoords(PLY.veh, -2.5, (50.0 * i), 0.0)

			-- Run the ray trace to get a vehicle
			local veh = utils.getVehicleInDirection(PLY.veh, start, offset)

			if not veh then
				goto continue -- Skip to next iteration instead of returning
			end

			-- Get the plate reader text for front/rear
			local cam = self:GetCamFromNum(i)

			-- Only proceed to read a plate if the hit entity is a valid vehicle and the current camera isn't locked
			if (DoesEntityExist(veh) and IsEntityAVehicle(veh) and not self:GetCamLocked(cam)) then
				-- Get the heading of the player's vehicle and the hit vehicle
				local ownH = utils.round(GetEntityHeading(PLY.veh), 0)
				local tarH = utils.round(GetEntityHeading(veh), 0)

				-- Get the relative direction between the player's vehicle and the hit vehicle
				local dir = utils.getEntityRelativeDirection(ownH, tarH)

				-- Only run the rest of the plate check code if we can see the front or rear of the vehicle
				if (dir > 0) then
					-- Get the licence plate text from the vehicle
					local plate = GetVehicleNumberPlateText(veh)

					-- Get the licence plate index from the vehicle
					local index = GetVehicleNumberPlateTextIndex(veh)

					-- Only update the stored plate if it's different, otherwise we'd keep sending a NUI message to update the displayed
					-- plate and image even though they're the same
					if (self:GetPlate(cam) ~= plate) then
						-- Set the plate for the current reader
						self:SetPlate(cam, plate)

						-- Set the plate index for the current reader
						self:SetIndex(cam, index)

						-- Automatically lock the plate if the scanned plate matches the BOLO
						if (plate == self:GetBoloPlate()) then
							self:LockCam(cam, false, true)

							SYNC:LockReaderCam(cam, READER:GetCameraDataPacket(cam))
						end

						-- Send the plate information to the NUI side to update the UI
						SendNUIMessage({ _type = "changePlate", cam = cam, plate = plate, index = index })

						-- If we use Imperial CAD, reduce the plate events to just player's vehicle, otherwise life as normal
						local isPlateScanned = isPlateAlreadyScanned(plate, cam)

						if isPlateScanned then return end

						scanPlate(plate)

						---Put back after testing.
						-- if (utils.isPlayerInVeh(veh) or IsVehiclePreviouslyOwnedByPlayer(veh)) and GetVehicleClass(veh) ~= 18 then
						-- 	scanPlate(plate)
						-- end
					end
				end
			end

			::continue::
		end
	else
		print("Plate reader cannot perform main task")
	end
end

lib.onCache('vehicle', function(value)
	local shouldHide = (not value or (value and GetVehicleClass(value) ~= 18)) and READER:GetDisplayState() and
		not READER:GetDisplayHidden()

	if shouldHide then
		READER:SetDisplayHidden(true)
		SendNUIMessage({ _type = "setReaderDisplayState", state = false })
		return
	end

	if PLY:CanViewRadar() and READER:GetDisplayState() and READER:GetDisplayHidden() then
		READER:SetDisplayHidden(false)
		SendNUIMessage({ _type = "setReaderDisplayState", state = true })
	end
end)

CreateThread(function()
	while true do
		local isPaused = IsPauseMenuActive() and READER:GetDisplayState()

		if isPaused then
			READER:SetDisplayHidden(true)
			SendNUIMessage({ _type = "setReaderDisplayState", state = false })
		end

		Wait(1000)
	end
end)

-- -- This function is pretty much straight from WraithRS, it does the job so I didn't see the point in not
-- -- using it. Hides the radar UI when certain criteria is met, e.g. in pause menu or stepped out ot the
-- -- patrol vehicle
-- function READER:RunDisplayValidationCheck()
-- 	local shouldHide = (not PLY.veh or (PLY.veh and not PLY.vehClassValid)) and self:GetDisplayState() and
-- 		not self:GetDisplayHidden()
-- 	local isPaused = IsPauseMenuActive() and self:GetDisplayState()

-- 	if shouldHide or isPaused then
-- 		self:SetDisplayHidden(true)
-- 		SendNUIMessage({ _type = "setReaderDisplayState", state = false })
-- 		return false
-- 	elseif (PLY:CanViewRadar() and self:GetDisplayState() and self:GetDisplayHidden()) then
-- 		self:SetDisplayHidden(false)
-- 		SendNUIMessage({ _type = "setReaderDisplayState", state = true })
-- 		return true
-- 	end
-- end
