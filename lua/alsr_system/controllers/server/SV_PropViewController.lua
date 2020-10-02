util.AddNetworkString( 'Net.Alsr.SystemAuthority' );
util.AddNetworkString( 'Net.OnPhysgunPickup.PropViewController' );
util.AddNetworkString( 'Net.PhysgunDrop.PropViewController' );
util.AddNetworkString( 'Net.OnPhysgunFreeze.PropViewController' );
util.AddNetworkString( 'Net.PlayerSpawnedEntity.PropViewController' );
util.AddNetworkString( 'Net.PostCleanupMap.PropViewController' );
util.AddNetworkString( 'Net.PlayerFinalizateSpawn.PropViewController' );
util.AddNetworkString( 'Net.DrawPropOcclusion.PropViewController' );
util.AddNetworkString( 'Net.EntityRemoved.PropViewController' );

CreateConVar( "alsr_enable", 1, FCVAR_ARCHIVE, 
    "Enable or disable alsr system." );

CreateConVar( "alsr_server_only", 1, FCVAR_ARCHIVE, 
    "Enable server-side optimization (1) or client-side (0)" );

CreateConVar( "alsr_visibility_delay", 0.2, FCVAR_ARCHIVE, 
    "Visibility check refresh rate." );

CreateConVar( "alsr_players_calcualtion_delay", 1, FCVAR_ARCHIVE, 
    "Frequency of updating the number of players for calculations on the server." );
    
CreateConVar( "alsr_player_view_radius", 90, FCVAR_ARCHIVE, 
    "The radius of view that the detection covers." );

CreateConVar( "alsr_player_view_distance", 1500, FCVAR_ARCHIVE, 
    "The maximum distance at which detection begins to work." );

CreateConVar( "alsr_player_disable_detector_distance", 500, FCVAR_ARCHIVE, 
    "The maximum distance at which detection stops working." );

CreateConVar( "alsr_physics_constraint", 0, FCVAR_ARCHIVE, 
    "Enable physics constraint. (1 - Enable, 0 - Disable)" );

-- Is server rendering authority
local IsServerOnly = false;
-- List of all active players on the server.
local PlayerList = {};
-- List of ignored players during connection.
local PlayersIgnore = {};
-- List of objects ignored by the system.
local IgnoreEntityList = {};
-- List of cached objects.
local CacheProps = {};
-- Variables
local PhysicsConstraint, PlayerViewRadius, PlayerViewDistance, PlayerDisableDetectorDistance;

if ( GetConVar( "alsr_server_only" ):GetInt() == 1 ) then
    IsServerOnly = true;
else
    IsServerOnly = false;
end;

--- Adds a player-raised prop to the cache.
-- @param Ply the player entity
-- @param Ent the prop entity 
local function OnPhysgunPickup( Ply, Ent )

    if ( not table.HasValue( IgnoreEntityList , Ent ) ) then
        table.insert( IgnoreEntityList, Ent );

        net.Start( 'Net.OnPhysgunPickup.PropViewController' );
        net.WriteInt( Ent:EntIndex(), 32 );
        net.SendOmit( PlayersIgnore );
    end;

end;
hook.Add( 'OnPhysgunPickup', 'ALSR.Hook.OnPhysgunPickup.PropViewController', OnPhysgunPickup );

--- Deletes a player-raised prop from the cache.
-- @param Ply the player entity
-- @param Ent the prop entity 
local function PhysgunDrop( Ply, Ent )

    for i = 1, table.Count( IgnoreEntityList ) do
        local TableEnt = IgnoreEntityList[ i ];

        if ( TableEnt == Ent ) then
            net.Start( 'Net.PhysgunDrop.PropViewController' );
            net.WriteInt( Ent:EntIndex(), 32 );
            net.SendOmit( PlayersIgnore );

            IgnoreEntityList[ i ] = nil;
        end;
    end;

end;
hook.Add( 'PhysgunDrop', 'ALSR.Hook.PhysgunDrop.PropViewController', PhysgunDrop );

--- Removes prop from the cache when a player freezes it with a physical gun.
-- @param Weapon the player current weapon
-- @param Rigidbody the physical object
-- @param Ent the prop entity 
-- @param Ply the player entity
local function OnPhysgunFreeze( Weapon, Rigidbody, Ent, Ply )

    for i = 1, table.Count( IgnoreEntityList ) do
        local TableEnt = IgnoreEntityList[ i ];

        if ( TableEnt == Ent ) then
            net.Start( 'Net.OnPhysgunFreeze.PropViewController' );
            net.WriteInt( Ent:EntIndex(), 32 );
            net.SendOmit( PlayersIgnore );

            IgnoreEntityList[ i ] = nil;
        end;
    end;

end;
hook.Add( 'OnPhysgunFreeze', 'ALSR.Hook.OnPhysgunFreeze.PropViewController', OnPhysgunFreeze );

--- Adds a player-generated prop to the cache.
-- @param Ply the player entity
-- @param Ent the npc entity 
local function PlayerSpawnedEntity( Ply, Ent )

    CacheProps[ Ply ] = CacheProps[ Ply ] or {};

    local EntityIndex = Ent:EntIndex();

    for _, FPly in pairs( PlayerList ) do
        table.insert( FPly.ALSR.Entities, {
            Index = EntityIndex,
            NoDraw = false
        } );
    end;

    table.insert( CacheProps[ Ply ], Ent );

    timer.Simple( 1, function()
        if ( not IsValid( Ent ) ) then
            return;
        end;

        net.Start( 'Net.PlayerSpawnedEntity.PropViewController' );
        net.WriteInt( EntityIndex, 32 );
        net.SendOmit( PlayersIgnore );
    end );

end;
hook.Add( 'PlayerSpawnedNPC', 'ALSR.Hook.PlayerSpawnedNPC.PropViewController', PlayerSpawnedEntity );
hook.Add( 'PlayerSpawnedSENT', 'ALSR.Hook.PlayerSpawnedSENT.PropViewController', PlayerSpawnedEntity );
hook.Add( 'PlayerSpawnedVehicle', 'ALSR.Hook.PlayerSpawnedVehicle.PropViewController', PlayerSpawnedEntity );

--- Adds a player-generated prop to the cache.
-- @param Ply the player entity
-- @param Model the prop model
-- @param Ent the prop entity 
local function PlayerSpawnedEntityModel( Ply, Model, Ent )
    PlayerSpawnedEntity( Ply, Ent );
end;
hook.Add( 'PlayerSpawnedProp', 'ALSR.Hook.PlayerSpawnedProp.PropViewController', PlayerSpawnedEntityModel );

--- When an entity is destroyed, it deletes it from the cache.
-- @param Ent the any entity 
local function EntityRemoved( Ent )

    for Ply, EntTable in pairs( CacheProps ) do

        for i = 1, table.Count( EntTable ) do

            local EntT = EntTable[ i ];

            if ( EntT == Ent ) then

                local EntityIndex = Ent:EntIndex();

                for _, FPly in pairs( PlayerList ) do
                    if ( FPly.ALSR ~= nil and FPly.ALSR.Entities ~= nil ) then
                        for Key, EntTab in pairs( FPly.ALSR.Entities ) do
                            if ( EntTab.Index == EntityIndex ) then
                                table.remove( FPly.ALSR.Entities, Key );
                                break;
                            end;
                        end;
                    end;
                end;

                ALSR.Occlusion:EntityCacheRemove( EntityIndex );

                net.Start( 'Net.EntityRemoved.PropViewController' );
                net.WriteInt( EntityIndex, 32 );
                net.SendOmit( PlayersIgnore );

                table.remove( CacheProps[ Ply ], i );
                break;
            end;

        end;

    end;

end;
hook.Add( 'EntityRemoved', 'ALSR.Hook.EntityRemoved.PropViewController', EntityRemoved );

--- Adds the player to the hook ignore list until he boots up.
-- @param Ply the player entity 
-- @param Transition check that the player is loading after changing the map.
local function PlayerInitialSpawn( Ply, Transition )
    table.insert( PlayersIgnore, Ply );
end;
hook.Add( 'PlayerInitialSpawn', 'ALSR.Hook.PlayerInitialSpawn.PropViewController', PlayerInitialSpawn );

--- Removes a player from the ignore list when disconnected.
-- @param Ply the player entity
local function PlayerDisconnected( Ply )
    for i = 1, table.Count( PlayersIgnore ) do
        if ( PlayersIgnore[ i ] == Ply ) then
            table.remove( PlayersIgnore, i );
            break;
        end;
    end;

    for i = 1, table.Count( PlayerList ) do
        if ( PlayerList[ i ] == Ply ) then
            table.remove( PlayerList, i );
            break;
        end;
    end;

    ALSR.Occlusion:EntityCacheClearOnPlayer( Ply:UniqueID() );
end;
hook.Add( 'PlayerDisconnected', 'ALSR.Hook.PlayerDisconnected.PropViewController', PlayerDisconnected );

--- Sends information about all entities on the map to the client.
-- @param Ply the player entity
local function PlayerSpawn( Ply )

    if ( Ply:IsBot() ) then return; end;

    Ply.ALSR = Ply.ALSR or {};
    Ply.ALSR.Entities = Ply.ALSR.Entities or {};

    if ( Ply.ALSR.FirstSpawn == nil ) then
        Ply.ALSR.FirstSpawn = false;
    end;
    
    if ( not Ply.ALSR.FirstSpawn ) then
        local EntsList = {};

        for _, Ent in pairs( ents.GetAll() ) do
            local EntClass = Ent:GetClass();
            if ( EntClass == 'prop_physics' or Ent:IsNPC() ) then
                local EntityIndex = Ent:EntIndex();
  
                table.insert( Ply.ALSR.Entities, {
                    Index = EntityIndex,
                    NoDraw = false
                } );
                
                table.insert( EntsList, EntityIndex );
            end;
        end;

        timer.Simple( 5, function()
            table.insert( PlayerList, Ply );

            for i = 1, table.Count( PlayersIgnore ) do
                if ( PlayersIgnore[ i ] == Ply ) then
                    table.remove( PlayersIgnore, i );
                    break;
                end;
            end;

            net.Start( 'Net.PlayerFinalizateSpawn.PropViewController' );
            net.Send( Ply );

            net.Start( 'Net.Alsr.SystemAuthority' );
            net.WriteBool( IsServerOnly );
            net.WriteFloat( GetConVar( "alsr_player_view_radius" ):GetFloat() );
            net.WriteFloat( GetConVar( "alsr_player_view_distance" ):GetFloat() );
            net.WriteFloat( GetConVar( "alsr_player_disable_detector_distance" ):GetFloat() );
            net.Send( Ply );

            Ply:PrintMessage( HUD_PRINTTALK, '[ALSR] Prop view controller is initializate!' );
        end );

        Ply.ALSR.FirstSpawn = true;
    end;

end;
hook.Add( 'PlayerSpawn', 'ALSR.Hook.PlayerSpawn.PropViewController', PlayerSpawn );

--- Reboots the system after clearing the map.
local function PostCleanupMap()

    timer.Simple( 1, function()
        table.Empty( CacheProps );
        table.Empty( IgnoreEntityList );

        for _, Ply in pairs( PlayerList ) do
            net.Start( 'Net.PostCleanupMap.PropViewController' );
            net.Send( Ply );
        end;

        ALSR.Occlusion:EntityCacheClear();

        PrintMessage( HUD_PRINTTALK, '[ALSR] Prop view controller is reloading!' );
    end );

end;
hook.Add( 'PostCleanupMap', 'ALSR.Hook.PostCleanupMap.PropViewController', PostCleanupMap );

--- Handles the visibility of objects, and sends information to the players.
local function DrawPropOcclusion()

    if ( ALSR.Occlusion ~= nil ) then

        local Ply = ALSR.Players:GetNextPlayer();

        if ( Ply == nil ) then return; end;

        for EntPly, EntTable in pairs( CacheProps ) do

            for i = 1, table.Count( EntTable ) do

                local Ent = EntTable[ i ];
                if ( Ent == nil or not IsValid( Ent ) ) then
                    table.remove( CacheProps[ EntPly ], i );
                    break;
                end;
                
                if ( Ply.ALSR ~= nil and Ply.ALSR.FirstSpawn and Ply:Alive() ) then

                    local PlayersOcclusionIsTarget = false;

                    local IsTarget = ALSR.Occlusion:EntityIsTarget( Ply, Ent, PlayerViewRadius, PlayerViewDistance, PlayerDisableDetectorDistance );
                    
                    if ( IsTarget ~= nil and IsTarget == true ) then
                        PlayersOcclusionIsTarget = true;
                    end;
                    
                    local EntityIndex = Ent:EntIndex();

                    if ( PlayersOcclusionIsTarget ) then
                        for Key, EntTab in pairs( Ply.ALSR.Entities ) do
                            if ( EntTab.Index == EntityIndex and EntTab.NoDraw and not table.HasValue( IgnoreEntityList, Ent ) ) then
                                Ply.ALSR.Entities[ Key ].NoDraw = false;

                                if ( PhysicsConstraint ) then
                                    ALSR.Occlusion:EntityEnablePhysics( Ent, true );
                                end;

                                net.Start( 'Net.DrawPropOcclusion.PropViewController' );
                                net.WriteInt( EntityIndex, 32 );
                                net.WriteBool( false );
                                net.Send( Ply );

                                break;
                            end;
                        end;
                    else
                        for Key, EntTab in pairs( Ply.ALSR.Entities ) do
                            if ( EntTab.Index == EntityIndex and not EntTab.NoDraw and not table.HasValue( IgnoreEntityList, Ent ) ) then
                                Ply.ALSR.Entities[ Key ].NoDraw = true;

                                if ( PhysicsConstraint ) then
                                    ALSR.Occlusion:EntityEnablePhysics( Ent, false );
                                end;

                                net.Start( 'Net.DrawPropOcclusion.PropViewController' );
                                net.WriteInt( EntityIndex, 32 );
                                net.WriteBool( true );
                                net.Send( Ply );

                                break;
                            end;
                        end;
                    end;

                else
                    break;
                end;

            end;

        end;

    end;

end;

--- Stops the system.
local function StopSystem()
    if ( timer.Exists( "ALSR_Timer.DrawPropOcclusion.PropViewController" ) ) then
        timer.Stop( "ALSR_Timer.DrawPropOcclusion.PropViewController" );
    end;

    if ( timer.Exists( "ALSR_Timer.Players.Calculation" ) ) then
        timer.Stop( "ALSR_Timer.Players.Calculation" );
    end;

    for EntPly, EntTable in pairs( CacheProps ) do
        for i = 1, table.Count( EntTable ) do

            local Ent = EntTable[ i ];
            if ( Ent ~= nil and IsValid( Ent ) ) then
                net.Start( 'Net.DrawPropOcclusion.PropViewController' );
                net.WriteInt( Ent:EntIndex(), 32 );
                net.WriteBool( false );
                net.Send( player.GetAll() );
            end;

        end;
    end;
end;

--- Start the system.
local function StartSystem()
    PhysicsConstraint = false;
    if ( GetConVar( "alsr_physics_constraint" ):GetInt() >= 1 ) then
        PhysicsConstraint = true;
    end;

    PlayerViewRadius = GetConVar( "alsr_player_view_radius" ):GetFloat();
    PlayerViewDistance = GetConVar( "alsr_player_view_distance" ):GetFloat();
    PlayerDisableDetectorDistance = GetConVar( "alsr_player_disable_detector_distance" ):GetFloat();

    timer.Create( "ALSR_Timer.DrawPropOcclusion.PropViewController", 
        GetConVar( "alsr_visibility_delay" ):GetFloat(), 0, DrawPropOcclusion );

    timer.Create( "ALSR_Timer.Players.Calculation",
        GetConVar( "alsr_players_calcualtion_delay" ):GetFloat(), 0,
        function()
            ALSR.Players:Calculation( PlayerList );
        end
    );
end;

--- Console command to start the system.
--- As arguments, a numerical value of 0 or 1 is used.
-- @param Ply the player entity
-- @param Cmd the console command name
-- @param Args the console command arguments
local function Cmd_AlsrSystemStart( ply, cmd, args )
    if ( not ply:IsAdmin() and not ply:IsSuperAdmin() ) then
        return;
    end;
    RunConsoleCommand( "alsr_enable", 1 );
    timer.Simple( 1, StartSystem );
end;
concommand.Add( "alsr_system_start", Cmd_AlsrSystemStart );

--- Console command to stop the system.
--- As arguments, a numerical value of 0 or 1 is used.
-- @param Ply the player entity
-- @param Cmd the console command name
-- @param Args the console command arguments
local function Cmd_AlsrSystemStop( ply, cmd, args )
    if ( not ply:IsAdmin() and not ply:IsSuperAdmin() ) then
        return;
    end;
    RunConsoleCommand( "alsr_enable", 0 );
    timer.Simple( 1, StopSystem );
end;
concommand.Add( "alsr_system_stop", Cmd_AlsrSystemStop );

--- Console command to reboot the system.
-- @param Ply the player entity
-- @param Cmd the console command name
-- @param Args the console command arguments
local function Cmd_AlsrSystemReload( ply, cmd, args )
    ply:ConCommand( "alsr_system_stop" );
    ply:ConCommand( "alsr_system_start" );
end;
concommand.Add( "alsr_system_reload", Cmd_AlsrSystemReload );

--[[
--  ==========================================
--  System startup.
--  ==========================================
--]]

--- Starts or does not start the system, based on the cvar parameters.
local function SystemStartup()
    local Index = GetConVar( "alsr_enable" ):GetInt();

    if ( not IsServerOnly ) then return; end;

    if ( Index == 1 ) then
        StartSystem();
    else
        StopSystem();
    end;
end;

local function InitializeSystemMap()
    SystemStartup();
    hook.Remove( 'Initialize', 'ALSR.Hook.InitializeSystemMap.PropViewController' );
end;
hook.Add( 'Initialize', 'ALSR.Hook.InitializeSystemMap.PropViewController', InitializeSystemMap );