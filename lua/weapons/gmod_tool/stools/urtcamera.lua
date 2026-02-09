TOOL.Category = "Render"
TOOL.Name = "#tool.urtcamera.name"

TOOL.Information = {
    { name = "left" },
    { name = "right" }
}

TOOL.ClientConVar[ "showid" ] = "0"
TOOL.ClientConVar[ "id" ] = "default"
TOOL.ClientConVar[ "model" ] = "models/props_c17/tv_monitor01.mdl"
TOOL.ClientConVar[ "fov" ] = "80"
TOOL.ClientConVar[ "screenfx" ] = "none"
TOOL.ClientConVar[ "idmode" ] = "1"

CreateConVar( "sbox_maxurtcameras", 5, FCVAR_NOTIFY )
CreateConVar( "sbox_maxurtmonitors", 20, FCVAR_NOTIFY )

cleanup.Register( "urtcamera" )
cleanup.Register( "urtmonitor" )

local ConVarsDefault = TOOL:BuildConVarList()

function TOOL.BuildCPanel( CPanel )

    CPanel:AddControl( "ComboBox", { MenuButton = 1, Folder = "improved_rt_cameras", Options = { [ "#preset.default" ] = ConVarsDefault }, CVars = table.GetKeys( ConVarsDefault ) } )
    CPanel:TextEntry( "#tool.urtcamera.id", "urtcamera_id" )

    local idMode = CPanel:ComboBox( "#tool.urtcamera.idmode", "urtcamera_idmode")
    idMode:SetSortItems( false )
    idMode:AddChoice( "#tool.urtcamera.idmode.global", urtcam.ID_MODE_GLOBAL )
    idMode:AddChoice( "#tool.urtcamera.idmode.private", urtcam.ID_MODE_PRIVATE )
    idMode:AddChoice( "#tool.urtcamera.idmode.local", urtcam.ID_MODE_LOCAL )
    CPanel:ControlHelp( "#tool.urtcamera.idmode.help" )

    CPanel:CheckBox( "#tool.urtcamera.showid", "urtcamera_showid" )
    CPanel:ControlHelp( "#tool.urtcamera.showid.help" )

    CPanel:NumSlider( "#tool.urtcamera.fov", "urtcamera_fov", 10, 120, false )
    CPanel:ControlHelp( "#tool.urtcamera.fov.help" )

    local fx = CPanel:ComboBox( "#tool.urtcamera.screenfx", "urtcamera_screenfx" )
    fx:SetSortItems( false )

    for k, v in SortedPairsByMemberValue( list.GetForEdit( "RTScreenFX" ), "order" ) do
        fx:AddChoice( "#rt.screenfx." .. k, k )
    end

    -- CPanel:AddControl( "PropSelect", { Label = "#tool.urtcamera.model", ConVar = "urtcamera_model", Height = 5, Models = list.Get( "RTMonitorModels" ) } )
    local models = {}

    for k, v in pairs( list.GetForEdit( "RTMonitorModels" ) ) do
        models[ k ] = {}
    end

    CPanel:PropSelect( "#tool.urtcamera.model", "urtcamera_model", models, 4 )

    CPanel:Help( "#tool.urtcamera.performancesettings" ):SetFont( "DermaDefaultBold" )

    CPanel:CheckBox( "#tool.urtcamera.drawscreens", "urtcamera_drawscreens" )
    CPanel:ControlHelp( "#tool.urtcamera.drawscreens.help" )

    CPanel:NumSlider( "#tool.urtcamera.refreshrate", "urtcamera_refreshrate", 10, 60, false )
    CPanel:ControlHelp( "#tool.urtcamera.refreshrate.help" )

    CPanel:NumSlider( "#tool.urtcamera.drawrange", "urtcamera_drawrange", 200, 10000, false )
    CPanel:ControlHelp( "#tool.urtcamera.drawrange.help" )

    CPanel:NumSlider( "#tool.urtcamera.resolution", "urtcamera_resolution", 256, 1024, false )
    CPanel:ControlHelp( "#tool.urtcamera.resolution.help" )

end

if CLIENT then
    language.Add( "tool.urtcamera.name", "Ultimate RT Camera" )
    language.Add( "tool.urtcamera.model", "RT Display Model" )

    language.Add( "tool.urtcamera.id", "RT Camera ID" )

    language.Add( "tool.urtcamera.idmode", "ID Mode" )
    language.Add( "tool.urtcamera.idmode.help",
[[-Global: IDs are shared between all players
-Private: IDs are specific to each player
-Local: IDs are specific to contraption when duping. Acts like private when not duped. Allows you to spawn multiple of the same contraption without ID conflicts]] )
    language.Add( "tool.urtcamera.idmode.global", "Global" )
    language.Add( "tool.urtcamera.idmode.private", "Private" )
    language.Add( "tool.urtcamera.idmode.local", "Local" )

    language.Add( "tool.urtcamera.showid", "Show Camera ID" )
    language.Add( "tool.urtcamera.showid.help", "Display the camera\'s id on screens" )

    language.Add( "tool.urtcamera.screenfx", "Screen effects" )
    -- language.Add( "tool.urtcamera.screenfx.help", "RT Camera ID" )

    language.Add( "tool.urtcamera.performancesettings", "Performance settings" )

    --Hide screens
    language.Add( "tool.urtcamera.drawscreens", "Render Screens" )
    language.Add( "tool.urtcamera.drawscreens.help", "Disable for performance" )

    --FOV Slider
    language.Add( "tool.urtcamera.fov", "Field of View" )
    language.Add( "tool.urtcamera.fov.help", "Sets the Field Of View of new cameras" )

    --RefreshRate Slider
    language.Add( "tool.urtcamera.refreshrate", "Refresh Rate" )
    language.Add( "tool.urtcamera.refreshrate.help", "Sets the Hz rate of screens\n(Performance Heavy!)" )

    --Draw Range Slider
    language.Add( "tool.urtcamera.drawrange", "Draw Range" )
    language.Add( "tool.urtcamera.drawrange.help", "Sets the range that screens will render\n(Performance Heavy!)" )

    --Resolution Slider
    language.Add( "tool.urtcamera.resolution", "Monitor Resolution" )
    language.Add( "tool.urtcamera.resolution.help", "Sets the display resolution of screens\n(Requires restart!)" )

    --Help display
    language.Add( "tool.urtcamera.desc", "Allows you to place RT Cameras and their displays" )
    language.Add( "tool.urtcamera.left", "Create a RT Camera")
    language.Add( "tool.urtcamera.right", "Place a Monitor")
end

local SendNotification
if SERVER then
    util.AddNetworkString( "rtcamera.alert" )
    function SendNotification( ply, message )
        net.Start( "rtcamera.alert" )
        net.WriteString( message )
        net.Send( ply )
    end
else
    function SendNotification()
    end

    net.Receive( "rtcamera.alert", function()
        local message = net.ReadString()
        Derma_Message( message, "RT Camera", "Ok" )
    end )
end


local function isCameraIDAcceptable( id, ply )
    if IsValid( urtcam.CamByID[ id ] ) then
        if IsValid( ply ) then
            ply:ChatPrint( "Couldn't spawn RT camera: camera ID is already in use" )
        end
        return false
    end

    return true
end

local function MakeCamera( ply, pos, ang, actualID, idmode, fov, data )
    if IsValid( ply ) and not ply:CheckLimit( "urtcameras" ) then return end

    idmode = idmode or urtcam.ID_MODE_GLOBAL
    actualID = actualID or "default"

    local id = urtcam.GetIDByMode( actualID, idmode, ply )

    -- if we're duplicating, we will set the ID in ENT:PostEntityPaste()
    local awaitingID = idmode == urtcam.ID_MODE_LOCAL and data or idmode == urtcam.ID_MODE_WIRE

    if not awaitingID and not isCameraIDAcceptable( id, ply ) then return end

    local ent = ents.Create( "gmod_ultimate_rtcam" )

    if not IsValid( ent ) then return end

    -- for the love of god, do NOT paste the ID
    if data and data.DT then
        data.DT.ID = nil
    end

    duplicator.DoGeneric( ent, data )

    if awaitingID then
        ent:SetID( "" )
    else
        ent:SetID( id )
    end
    ent:SetIDMode( idmode )
    ent:SetActualID( actualID )

    ent:SetPos( pos )
    ent:SetAngles( ang )

    if fov then
        ent:SetFOV( math.Clamp( fov, 10, 120 ) )
    end

    if IsValid( ply ) then
        ply:AddCount( "urtcamera", ent )
        ply:AddCleanup( "urtcamera", ent )
        ent:SetPlayer( ply )
    end

    ent:Spawn()

    duplicator.DoGenericPhysics( ent, ply, data )
    DoPropSpawnedEffect( ent )

    return ent
end

duplicator.RegisterEntityClass( "gmod_ultimate_rtcam", MakeCamera, "Pos", "Ang", "ActualID", "IDMode", "FOV", "Data" )

-- compatibility with multiple advanced rt cameras
duplicator.RegisterEntityClass( "gmod_rtcameraprop", function( ply, locked, id, fov, data )
    return MakeCamera( ply, data.Pos, data.Ang, id, urtcam.ID_MODE_GLOBAL, fov, data )
end, "locked", "ID", "FOV", "Data" )

local function MakeMonitor( ply, pos, ang, model, actualID, idmode, showID, screenFX, data )
    if IsValid( ply ) and not ply:CheckLimit( "urtmonitors" ) then return end

    idmode = idmode or urtcam.ID_MODE_GLOBAL
    actualID = actualID or "default"

    local id = urtcam.GetIDByMode( actualID, idmode, ply )

    local ent = ents.Create( "gmod_ultimate_rttv" )

    if not IsValid( ent ) then return end

    duplicator.DoGeneric( ent, data )

    ent:SetPos( pos )
    ent:SetAngles( ang )

    ent:SetID( id )
    ent:SetIDMode( idmode )
    ent:SetActualID( actualID )

    if model then
        ent:SetModel( model )
    end

    if showID then
        ent:SetShowID( showID )
    end

    if screenFX then
        ent:SetScreenFX( screenFX )
    end

    if IsValid( ply ) then
        ply:AddCount( "urtmonitor", ent )
        ply:AddCleanup( "urtmonitor", ent )
        ent:SetPlayer( ply )

        timer.Simple( 1, function()
            if not IsValid( ply ) then return end
            if not IsValid( ent ) then return end
            ent:Use( ply, ply, SIMPLE_USE )
        end)
    end

    ent:Spawn()

    duplicator.DoGenericPhysics( ent, ply, data )
    DoPropSpawnedEffect( ent )

    return ent
end

duplicator.RegisterEntityClass( "gmod_ultimate_rttv", MakeMonitor, "Pos", "Ang", "Model", "ActualID", "IDMode", "ShowID", "ScreenFX", "Data" )

-- compatibility with multiple advanced rt cameras
duplicator.RegisterEntityClass( "gmod_rttv", function( ply, trace, model, id, data )
    return MakeMonitor( ply, data.Pos, data.Ang, model, id, urtcam.ID_MODE_GLOBAL, false, "None", data )
end, "trace", "Model", "ID", "Data" )

function TOOL:LeftClick( trace )
    if CLIENT then return true end
    local id = self:GetClientInfo( "id" )
    local idmode = self:GetClientNumber( "idmode" )
    local fov = self:GetClientNumber( "fov" )

    local ply = self:GetOwner()

    local ent = MakeCamera( ply, trace.StartPos, ply:EyeAngles(), id, idmode, fov, nil )

    if not IsValid( ent ) then return false end

    local phys = ent:GetPhysicsObject()

    if IsValid( phys ) then
        phys:EnableMotion( false )
    end

    undo.Create( "RT Camera" )
        undo.AddEntity( ent )
        undo.SetPlayer( ply )
    undo.Finish()

    return true
end

function TOOL:RightClick( trace )
    if trace.Entity and trace.Entity:IsPlayer() then return false end
    if not trace.Hit then return false end
    if CLIENT then return true end

    local pos = trace.HitPos
    local ang = trace.HitNormal:Angle()
    local model = self:GetClientInfo( "model" )

    if not list.HasEntry( "RTMonitorModels", model ) then return false end

    local ply = self:GetOwner()
    local id = self:GetClientInfo( "id" )
    local idmode = self:GetClientNumber( "idmode" )
    local showID = self:GetClientBool( "showid" )
    local screenFX = self:GetClientInfo( "screenfx" )

    -- if not list.HasEntry( "RTMonitorFX", screenFX ) then return false end

    local ent = MakeMonitor( ply, pos, ang, model, id, idmode, showID, screenFX )

    if not IsValid( ent ) then return false end

    local phys = ent:GetPhysicsObject()

    if IsValid( phys ) then
        phys:EnableMotion( false )
    end

    ent:SetPos( trace.HitPos - trace.HitNormal * ent:OBBMins().z )
    ent:SetAngles( trace.HitNormal:Angle() )

    undo.Create( "RT Monitor" )
        undo.AddEntity( ent )
        undo.SetPlayer( ply )
    undo.Finish()

    return true
end


function TOOL:UpdateGhost( ent, ply )

    if !IsValid( ent ) then return end

    local trace = ply:GetEyeTrace()

    local ang = trace.HitNormal:Angle()

    local min = ent:OBBMins()
    ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
    ent:SetAngles( ang )

    ent:SetNoDraw( false )

end

function TOOL:Think()
    local mdl = self:GetClientInfo( "model" )

    if ( !IsValid( self.GhostEntity ) || self.GhostEntity:GetModel() != mdl ) then
        self:MakeGhostEntity( mdl, vector_origin, angle_zero )
    end

    self:UpdateGhost( self.GhostEntity, self:GetOwner() )
end