AddCSLuaFile()

ENT.Base = WireLib and "base_wire_entity" or "base_gmodentity"

ENT.PrintName = "Ultimate RT Camera"
ENT.Type = "anim"
ENT.Spawnable = false

urtcam = urtcam or {}
urtcam.CamByID = {}

if SERVER then
    ENT.ActualID = "G_Default"
    ENT.IDMode = 0
    ENT.ContraptionID = 0

    function ENT:SetActualID( id )
        self.ActualID = tostring( id )
    end

    function ENT:GetActualID()
        return self.ActualID
    end

    function ENT:SetIDMode( mode )
        self.IDMode = mode
    end

    function ENT:GetIDMode()
        return self.IDMode
    end
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

function ENT:SetupDataTables()
    self:NetworkVar( "String", "ID" )
    self:NetworkVar( "Int", "FOV" )
    -- self:NetworkVar( "String", "ActualID" )
    -- self:NetworkVar( "Entity", "Player" )

    self:NetworkVarNotify( "ID", self.OnIDChanged )
end

function ENT:OnIDChanged( name, old, new )
    if old then
        urtcam.CamByID[ old ] = nil
    end
    if new == "" then return end
    urtcam.CamByID[ new ] = self
end

function ENT:Initialize()
    urtcam.CamByID[ self:GetID() ] = self
    if SERVER then
        self:SetModel( "models/maxofs2d/camera.mdl" )
        self:PhysicsInit( SOLID_VPHYSICS )
        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:SetSolid( SOLID_VPHYSICS )
        self:DrawShadow( false )

        -- Don't collide with the player
        self:SetCollisionGroup( COLLISION_GROUP_WEAPON )

        if !WireLib then return end
        WireLib.CreateSpecialInputs( self, { "FOV", "CameraID", "IDMode" }, { "NORMAL", "STRING", "NORMAL" }, { "", "", "0 = Global; 1 = Private; 2 = Local" } )
    end
end

if SERVER then
    -- only do it on the server, because on client you can't be sure if it's actually removed
    function ENT:OnRemove()
        if urtcam.CamByID[ self:GetID() ] == self then
            urtcam.CamByID[ self:GetID() ] = nil
        end
    end
end

function ENT:TriggerInput( name, value )
    if name == "FOV" then
        self:SetFOV( math.Clamp( value, 10, 120 ) )
    elseif name == "CameraID" then
        if self:GetIDMode() == urtcam.ID_MODE_WIRE then return end
        local id = urtcam.GetIDByMode( value, self:GetIDMode(), self:GetPlayer() )
        if IsValid( urtcam.CamByID[ id ] ) then return end
        self:SetActualID( value )
        self:SetID( id )
    elseif name == "IDMode" then
        if self:GetIDMode() == urtcam.ID_MODE_WIRE then return end
        value = math.Round( math.Clamp( value, 0, 2 ) )
        local id = urtcam.GetIDByMode( self:GetActualID(), value, self:GetPlayer() )
        if IsValid( urtcam.CamByID[ id ] ) then return end
        self:SetIDMode( value )
        self:SetID( id )
    end
end

function ENT:Draw()

    self:DrawModel()

end

-- First x contraption ids are reserved for entities owned by players that were not duped
local freeContraptionID = game.MaxPlayers() + 1

function ENT:PostEntityPaste( ply, ent, createdEntities )
    if self:GetIDMode() != urtcam.ID_MODE_LOCAL then return end
    if self.DuplicationHandled then return end

    local contraptionID = freeContraptionID
    freeContraptionID = freeContraptionID + 1

    self:SetID( "C_" .. contraptionID .. "_" .. self:GetActualID() )

    for k, v in pairs( createdEntities ) do
        local class = v:GetClass()

        if class != "gmod_ultimate_rtcam" and class != "gmod_ultimate_rttv" then continue end
        if v:GetIDMode() != urtcam.ID_MODE_LOCAL then continue end

        v.DuplicationHandled = true

        v:SetID( "C_" .. contraptionID .. "_" .. v:GetActualID() )
    end
end