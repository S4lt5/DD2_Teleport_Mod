local ferryManager = sdk.get_managed_singleton("app.FerrystoneFlowController")


-- ferryManager:call("startDirection(app.FerrystoneFlowController.ResultType)",0);



yaw = ferryManager:get_field('TeleportCameraYaw');
pitch = ferryManager:get_field('TeleportCameraPitch');
pos = ferryManager:get_field('TeleportPosition');
rot = ferryManager:get_field('TeleportRotation');

local config = {}
local currentTPName = "New Teleport Point"
local currentTPPos = Vector3f.new(0.0, 0.0, 0.0)
local currentUPos = Vector3f.new(0.0, 0.0, 0.0)
local currentTPRot = Vector4f.new(0.0,0.0,0.0,1.0)
local config_path = "TeleportPlugin/TeleportPoints.json"
local selectedTPTargetIndex = 1
local tpTable = {}
local tpNameTable = {}
local selectedTPIndex = 1
local noClipEnabled = false


local previousPos = nil
local previousRot = nil

local noclipStep = 0.15
local noclipPos = Vector3f.new(0.0, 0.0, 0.0)
local noclipRot = nil

local noclipPreviousPos = nil
local noclipPreviousRot = nil
--log.debug("",pos.x);
--ferryManager:call("startReal(via.Position, via.Quaternion, System.Nullable`1<System.Single>, System.Nullable`1<System.Single>)",pos,rot,yaw,pitch);

-- We want to set ferrystone teleport position x y z
-- TeleportPosition = new Position(System.Double, System.Double, System.Double)
-- startReal(via.Position, via.Quaternion, System.Nullable`1<System.Single>, System.Nullable`1<System.Single>)
local PlayerManager = sdk.get_managed_singleton("app.CharacterManager")
local function GetPlayerManager()
    if PlayerManager == nil then PlayerManager = sdk.get_managed_singleton("app.CharacterManager") end
	return PlayerManager
end
-- Z is north/s
-- y is up/down
-- X is w/e
LOAD_CONFIG_FILE = true
function loadConfig()
	local config_file = json.load_file(config_path)
	selectedTPIndex = 1
	tpTable = {}
	tpNameTable = {}
	if config_file ~= nil then
		config = config_file
		if config.tpNameTable ~= nil then
			tpNameTable = config.tpNameTable
		end
		tpTable = {}
		if config.tpTable ~= nil then
			for k,v in pairs(config.tpTable) do -- Import tables as vectors
				table.insert(tpTable,{pos = Vector3f.new(v.pos[1],v.pos[2],v.pos[3]),rot = Vector4f.new(v.rot[1],v.rot[2],v.rot[3],v.rot[4])})
			end
		end
		
	else
		
		json.dump_file(config_path, config)
	end
end
if LOAD_CONFIG_FILE then
	loadConfig()
end


function checkTPNameUsage(name)
	if tpNameTable ~= nil then
		for i, value in pairs(tpNameTable) do
			if value == name then
				return true
			end
		end
	end
	return false
end
function get_player_transform(gameObjectName)
    local playerMgr = GetPlayerManager();
    local player = playerMgr:call("get_ManualPlayer()");
	transforms = nil
	if player then
        local tx = player:call('get_Transform()');
		if tx then
            --log.info("Found player transform")
			
			transforms = {
			pos = tx:call("get_Position"),
			rot = tx:call("get_Rotation"),            
			}
			--log.info(string.format("Pos X:%f,Y:%f,Z:%f",transforms.pos.x,transforms.pos.y,transforms.pos.z))
			--log.info(string.format("Rot X:%f,Y:%f,Z:%f,W:%f",transforms.rot.x,transforms.rot.y,transforms.rot.z,transforms.rot.w))	
		end
	end
	return transforms
end


function set_player_transform(pos,rot)	
    local playerMgr = GetPlayerManager();
    local player = playerMgr:call("get_ManualPlayer()");
    if player then
        -- get teleport info
        local tx = player:call('get_Transform()');
        if tx then       
            log.debug('tx found');                            
            player:call("warp");
            tx:call("set_Position",pos);
            -- player:call("warp");
            --tx:call("set_Rotation",rot);
          
        end
	end
end
doit = False
if doit then
    local playerMgr = GetPlayerManager();
    if playerMgr then
        local player = playerMgr:call("get_ManualPlayer()");
        if player then
            -- get teleport info
            local tx = player:call('get_Transform()');
            if tx then
                log.debug("There is a tx");
                local pos = tx:call('get_Position()');
                if pos then
                    local rot = tx:call('get_Rotation()');
                    log.debug('There is a position');
                    -- negative X is north
                    log.debug(string.format("Pos X:%f,Y:%f,Z:%f",pos.x,pos.y,pos.z)) 
                    -- i was alive here Pos X:-108.741844,Y:123.848541,Z:-26.005955
                    local currentTPPos = Vector3f.new(108.741844,123.848541,-26.005955);
                    local newrot = Vector4f.new(0,0,0,0);
                    --player:call("warp")
                    pos.y = 20.00;
                    -- player:call("warp")
                    --log.debug(string.format("currentTPPos X:%f,Y:%f,Z:%f",currentTPPos.x,currentTPPos.y,currentTPPos.z))       
                    set_player_transform(currentTPPos,rot);    
                    log.debug(string.format("Actual Pos X:%f,Y:%f,Z:%f",pos.x,pos.y,pos.z))       
                
                    -- ferryManager:call("startReal()")
                    -- ferryManager:call("startReal(via.Position, via.Quaternion, System.Nullable`1<System.Single>, System.Nullable`1<System.Single>)",currentTPPos,rot,yaw,pitch);
                end
                
            end 
            -- local PlayerBody_Transform = PlayerBody:call("getComponent(System.Type)", sdk.typeof("via.Transform"))
        
            --local tp = player:call('get_StaminaManager()');
            --if mgr then
            --    mgr:call("recoverAll()")
            --end
        end
    end
end


---#UI#---
re.on_draw_ui(function()
	local changed = false
	
	if imgui.tree_node("Teleport Plugin") then	
		if imgui.tree_node("Add New Teleport Point") then
			changed, currentTPName = imgui.input_text("Teleport Point Name", currentTPName)
			imgui.spacing()
			if imgui.button("Get Teleport Target Coordinates") then
				transforms = get_player_transform(teleportTargetGameObject)
				if transforms ~= nil then
					currentTPPos = transforms.pos
					currentTPRot = transforms.rot

				end
			end
			imgui.spacing()
			changed, currentTPPos = imgui.drag_float3("Position", currentTPPos,1.0,-100000000.0, 100000000.0)
			changed, currentTPRot = imgui.drag_float4("Rotation", currentTPRot,0.05,-1.0,1.0)
            changed, currentTPRot = imgui.drag_float4("UPOS", currentTPRot,0.05,-1.0,1.0)
			imgui.spacing()
			if imgui.button("Add Teleport Point") then
				tpEntry = {
				pos = currentTPPos,
				rot = currentTPRot,				
				}
				newTPName = currentTPName
				if checkTPNameUsage(currentTPName) then
					local currentIndex = 1
					newTPName = currentTPName .. " (" .. currentIndex .. ")"
					while(checkTPNameUsage(newTPName)) do
						currentIndex = currentIndex + 1
						newTPName = currentTPName .. " (" .. currentIndex .. ")"
					end
				end
				
				
				table.insert(tpNameTable,newTPName)
				table.insert(tpTable,tpEntry)
			end
			imgui.spacing()
			imgui.tree_pop()
		end
		
		if imgui.tree_node("Teleport List") then
			if imgui.button("Save Teleport Config") then
				if json.load_file(config_path) ~= config then
					config.tpNameTable = tpNameTable
					--config.tpTable = tpTable 
					--Vectors become null, so convert them into a table when saving
					config.tpTable = {}
					for k,v in pairs(tpTable) do
					  table.insert(config.tpTable,{pos={v.pos.x,v.pos.y,v.pos.z},rot={v.rot.x,v.rot.y,v.rot.z,v.rot.w}})
					end
					json.dump_file(config_path, config)
				end
			end
			imgui.same_line()
			if imgui.button("Reload Teleport Config") then
				loadConfig()
			end
			imgui.spacing()
			if imgui.button("Delete Selected Teleport Point") then
				if next(tpNameTable) ~= nil then
					table.remove(tpNameTable,selectedTPIndex)
					table.remove(tpTable,selectedTPIndex)
					selectedTPIndex = selectedTPIndex -1
				end
			end
			if tpNameTable ~= nil and tpTable ~= nil and next(tpNameTable) ~= nil and next(tpTable) ~= nil and selectedTPIndex > 0 then
				imgui.spacing()
				imgui.text(string.format("Position X: %.3f, Y: %.3f, Z: %.3f",tpTable[selectedTPIndex].pos.x,tpTable[selectedTPIndex].pos.y,tpTable[selectedTPIndex].pos.z))
				imgui.spacing()
			else
				imgui.spacing()
				imgui.text("No teleport points set.")--Keep text field there so UI doesn't shift when all points are deleted
				imgui.spacing()
			end
			changed, selectedTPIndex = imgui.combo("Teleport Point", selectedTPIndex, tpNameTable)
			if changed then
			
			end
			imgui.spacing()
			if imgui.button("Teleport") then
				if next(tpNameTable) ~= nil then
					--previousPos,previousRot = get_player_transform()
					transforms = get_player_transform(teleportTargetGameObject)
					if transforms ~= nil then
						previousPos = transforms.pos
						previousRot = transforms.rot
					end
					set_player_transform(tpTable[selectedTPIndex].pos,tpTable[selectedTPIndex].rot,teleportTargetGameObject)
				end
			end
			imgui.same_line()
			if imgui.button("Undo Teleport") then
				if previousPos ~= nil then
					set_player_transform(previousPos,previousRot,teleportTargetGameObject)
				end
			end
			imgui.same_line()
			imgui.tree_pop()			
		end
		if imgui.tree_node("No Clip") then
				changed, noClipEnabled = imgui.checkbox("Enable No Clip (Fly)", noClipEnabled)
				if changed then
					transform = get_player_transform(teleportTargetGameObject)
					if transform ~= nil then
						noclipPos = transform.pos
						noclipRot = transform.rot
						if noClipEnabled then
							noclipPreviousPos = transform.pos
							noclipPreviousRot = transform.rot
						end
					end
				end
				
				imgui.text("Use the No Clip Position sliders to set the player position after enabling No Clip.")
				imgui.spacing()
				changed, noclipStep = imgui.drag_float("Increment (Speed)", noclipStep,0.01, 0.001, 100.0)
				changed, noclipPos = imgui.drag_float3("No Clip Position", noclipPos,noclipStep,-100000000.0, 100000000.0)
				imgui.spacing()
				if imgui.button("Return To No Clip Start Position") then
				if noclipPreviousPos ~= nil then
					noclipPos = noclipPreviousPos
					noclipRot = noclipPreviousRot
					set_player_transform(noclipPreviousPos,noclipPreviousRot)
				end
			end
				imgui.spacing()
			end
			imgui.tree_pop()
	imgui.spacing()
	imgui.spacing()
	imgui.text("DD2 Teleport Plugin")
	imgui.spacing()
	imgui.spacing()
	imgui.tree_pop()
	end
end)


re.on_frame(function()
	if noClipEnabled then
		if noclipPos ~= nil and noclipRot ~= nil then
			set_player_transform(noclipPos,noclipRot)
		end
	end
end)
