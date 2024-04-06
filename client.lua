local inHandMode = false
local chosenHand = PedBoneId['SKEL_R_Hand']

-- Player Controls
local keyboardW = 32
local keyboardA = 34
local keyboardS = 33
local keyboardD = 35
local keyboardQ = 44
local keyboardE = 38

-- Hand Controls
local numpad4 = 108
local numpad5 = 110
local numpad6 = 107
local numpad8 = 111
local numpadPlus = 96
local numpadMinus = 97

local handModeKey = 47 -- G Key

local handCamera = nil
local handObject = nil

-- Debug
DEBUG = true
local cameraModeKey = 236 -- V Key
local cameraMode = false

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if inHandMode then
			Control()
		end


		if IsControlJustPressed(0, handModeKey) or IsDisabledControlJustPressed(0, handModeKey) then
			inHandMode = not inHandMode
			if inHandMode then
				StartHandControl()
			else
				StopHandControl()
			end
		end


		if DEBUG and IsDisabledControlJustPressed(0, cameraModeKey) then
			cameraMode = not cameraMode
			SetCamActive(handCamera, cameraMode)
			RenderScriptCams(cameraMode, false, 0, true, true)
		end
	end
end)

local playerRotation
local invertedHeading

function StartHandControl()
	inHandMode = true

	if handCamera then
		DestroyCam(handCamera, false)
	end

	handCamera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
	AttachCamToPedBone(handCamera, PlayerPedId(), chosenHand, 0.0, 0.45, 1.35, true)

	local gpCameraHeading = GetEntityHeading(PlayerPedId())
	playerRotation = GetEntityRotation(PlayerPedId(), 2)
	print(playerRotation.z)

	SetCamRot(handCamera, -75.0, 0.0, gpCameraHeading, 2)
	RenderScriptCams(true, false, 0, true, true)

	local pedCoords = GetEntityCoords(PlayerPedId())
	local pedHeading = GetEntityPhysicsHeading(PlayerPedId())
	local spawnCoords = GetObjectOffsetFromCoords(pedCoords.x, pedCoords.y, pedCoords.z, pedHeading, 0.45, 0.45, 0.0)

	handObject = CreateObject(GetHashKey("w_ex_snowball"), spawnCoords.x, spawnCoords.y, spawnCoords.z, true, true, true)


	invertedHeading = (pedHeading + 180.0) % 360.0

	SetEntityRotation(handObject, 0.0, 90.0, invertedHeading - 30, 2, true)

	SetEntityAlpha(handObject, DEBUG and 255 or 0, false)
	if DEBUG then
		Citizen.CreateThreadNow(function()
			while true do
				Citizen.Wait(0)
				-- Draw line from the handobject going forward
				local handCoords = GetEntityCoords(handObject)
				local forwardVector = GetEntityForwardVector(handObject)
				local endCoords = vector3(handCoords.x + forwardVector.x, handCoords.y + forwardVector.y,
					handCoords.z + forwardVector.z)
				DrawLine(handCoords.x, handCoords.y, handCoords.z, endCoords.x, endCoords.y, endCoords.z, 255, 0, 0, 255)
			end
		end)
	end
	FreezeEntityPosition(PlayerPedId(), true)
end

function StopHandControl()
	inHandMode = false

	if handCamera then
		DestroyCam(handCamera, false)
		handCamera = nil
	end

	RenderScriptCams(false, false, 0, true, true)

	FreezeEntityPosition(PlayerPedId(), false)

	if handObject then
		DeleteEntity(handObject)
		handObject = nil
	end
end

function HandleCustomMovementPlayer()
	if not handObject then return end
	DisableAllControlActions(0)

	local fowardVector = GetEntityForwardVector(PlayerPedId())

	local move = vector3(0.0, 0.0, 0.0)

	if IsDisabledControlPressed(0, keyboardW) then move = move + fowardVector * 0.01 end
	if IsDisabledControlPressed(0, keyboardS) then move = move - fowardVector * 0.01 end
	if IsDisabledControlPressed(0, keyboardA) then move = move + vector3(-fowardVector.y, fowardVector.x, 0.0) * 0.01 end
	if IsDisabledControlPressed(0, keyboardD) then move = move + vector3(fowardVector.y, -fowardVector.x, 0.0) * 0.01 end
	if IsDisabledControlPressed(0, keyboardQ) then move = move + vector3(0.0, 0.0, 0.01) end
	if IsDisabledControlPressed(0, keyboardE) then move = move + vector3(0.0, 0.0, -0.01) end

	if move.x == 0.0 and move.y == 0.0 and move.z == 0.0 then return end

	local pedCoords = GetEntityCoords(PlayerPedId())
	local offset = vector3(pedCoords.x + move.x, pedCoords.y + move.y, pedCoords.z + move.z)
	SetEntityCoordsNoOffset(PlayerPedId(), offset.x, offset.y, offset.z, true, true, true)


	local handCoords = GetEntityCoords(handObject)
	local offset = vector3(handCoords.x + move.x, handCoords.y + move.y, handCoords.z + move.z)
	SetEntityCoordsNoOffset(handObject, offset.x, offset.y, offset.z, true, true, true)
end

function Control()
	if handObject == nil or not DoesEntityExist(handObject) then return StopHandControl() end
	SetPedCanArmIk(PlayerPedId(), true)
	SetIkTarget(PlayerPedId(), 4, handObject, 18308, 0.05, 0.0, 0.0, 64, 0, 0)
	HandleCustomMovementPlayer()
	HandleCustomMovementArm()
end

function HandleCustomMovementArm()
	if not handObject then return end
	local rotation = vector3(0.0, 0.0, 0.0)

	-- These control the axis: Z
	if IsDisabledControlPressed(0, numpad4) then rotation = rotation + vector3(0.0, 0.0, 1.0) end
	if IsDisabledControlPressed(0, numpad6) then rotation = rotation + vector3(0.0, 0.0, -1.0) end
	-- These control the axis: X
	if IsDisabledControlPressed(0, numpad8) then rotation = rotation + vector3(1.0, 0.0, -0.25) end
	if IsDisabledControlPressed(0, numpad5) then rotation = rotation + vector3(-1.0, 0.0, 0.25) end
	-- These control the axis: Y
	if IsDisabledControlPressed(0, numpadPlus) then rotation = rotation + vector3(0.0, 1.0, 0.25) end
	if IsDisabledControlPressed(0, numpadMinus) then rotation = rotation + vector3(0.0, -1.0, 0.25) end


	if rotation.x == 0.0 and rotation.y == 0.0 and rotation.z == 0.0 then return end

	local handRotation = GetEntityRotation(handObject, 2)
	local offset = vector3(handRotation.x + rotation.x, handRotation.y + rotation.y, handRotation.z + rotation.z)

	local x = offset.x
	local y = offset.y
	local z = offset.z

	-- Clamp the rotation Z: +-30
	local zClamp = 30
	local zNormal = z - invertedHeading + 30

	if zNormal > zClamp then z = handRotation.z end
	if zNormal < -zClamp then z = handRotation.z end

	-- Clamp the rotation X: -54.0 to 80.0
	local xUpClamp = -54.0
	local xDownClamp = 80.0
	if x < xUpClamp then x = xUpClamp end
	if x > xDownClamp then x = xDownClamp end

	-- Clamp the rotation Y: -175.0 to 175.0
	local yNormal = (y + 90.0) % 360.0 - 180

	if yNormal < -175.0 then y = handRotation.y end
	if yNormal > 175.0 then y = handRotation.y end

	SetEntityRotation(handObject, x, y, z, 2, true)
end

AddEventHandler('onResourceStop', function(resourceName)
	if resourceName == GetCurrentResourceName() then
		StopHandControl()

		if handObject then
			DeleteEntity(handObject)
			handObject = nil
		end

		SetEntityCollision(PlayerPedId(), true, true)
	end
end)
