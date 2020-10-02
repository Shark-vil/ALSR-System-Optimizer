if ( SERVER ) then
    return;
end;

CreateConVar( "alsr_client_enable", 1, FCVAR_ARCHIVE, 
    "Enable or disable alsr system." );

CreateConVar( "alsr_client_prop_calc_delay", 1, FCVAR_ARCHIVE, 
    "Frequency of updating the number of props for calculations on the client." );

CreateConVar( "alsr_client_visibility_delay", 0.1, FCVAR_ARCHIVE, 
    "Visibility check refresh rate." );

CreateConVar( "alsr_max_props_visibility_one_rate", 10, FCVAR_ARCHIVE, 
    "How many objects will the system process in one rate?" );

CreateConVar( "alsr_client_sort_enable", 1, FCVAR_ARCHIVE, 
    "Enable sorting for more correct rendering (1). Attention! This may decrease performance." );

CreateConVar( "alsr_client_prop_sort_delay", 1, FCVAR_ARCHIVE, 
    "Frequency of updating sorting of objects on the client." );

local CacheProps = {};
local IgnoreEntityList = {};

local IsClientOnly = false;

local PlayerViewRadius, PlayerViewDistance, PlayerDisableDetectorDistance, MaxRateObjects;

net.Receive( 'Net.DrawPropOcclusion.PropViewController', function( Length )

    local Ent = Entity( net.ReadInt( 32 ) );
    local Boolean = net.ReadBool();

    ALSR.Occlusion:EntitySetNoDraw( Ent, Boolean );
    Ent.NoDraw = Boolean;

end );

net.Receive( 'Net.OnPhysgunPickup.PropViewController', function( Length )

    local Ent = Entity( net.ReadInt( 32 ) );

    if ( not table.HasValue( IgnoreEntityList , Ent ) ) then
        table.insert( IgnoreEntityList, Ent );
        ALSR.Occlusion:EntitySetNoDraw( Ent, false );
    end;

end );

net.Receive( 'Net.PhysgunDrop.PropViewController', function( Length )

    local Ent = Entity( net.ReadInt( 32 ) );
    
    for i = 1, table.Count( IgnoreEntityList ) do
        local TableEnt = IgnoreEntityList[ i ];

        if ( TableEnt == Ent ) then
            IgnoreEntityList[ i ] = nil;

            Ent.NoDraw = Ent.NoDraw or false;
            ALSR.Occlusion:EntitySetNoDraw( Ent, Ent.NoDraw );
        end;
    end;

end );

net.Receive( 'Net.OnPhysgunFreeze.PropViewController', function( Length )

    local Ent = Entity( net.ReadInt( 32 ) );
    
    for i = 1, table.Count( IgnoreEntityList ) do
        local TableEnt = IgnoreEntityList[ i ];

        if ( TableEnt == Ent ) then
            IgnoreEntityList[ i ] = nil;

            Ent.NoDraw = Ent.NoDraw or false;
            ALSR.Occlusion:EntitySetNoDraw( Ent, Ent.NoDraw );
        end;
    end;

end );

net.Receive( 'Net.PlayerSpawnedEntity.PropViewController', function( Length )

    local Ent = Entity( net.ReadInt( 32 ) );
    local Ply = LocalPlayer();

    table.insert( CacheProps, Ent );
    Ent.NoDraw = Ent.NoDraw or false;

end );

net.Receive( 'Net.EntityRemoved.PropViewController', function( Length )

    local Ent = Entity( net.ReadInt( 32 ) );
    
    for i = 1, table.Count( CacheProps ) do
        if ( CacheProps[ i ] == Ent ) then
            table.remove( CacheProps, i );
            break;
        end;
    end;

end );

net.Receive( 'Net.PostCleanupMap.PropViewController', function( Length )

    table.Empty( IgnoreEntityList );
    table.Empty( CacheProps );

end );

net.Receive( 'Net.PlayerFinalizateSpawn.PropViewController', function( Length )

    LocalPlayer().ALSR = LocalPlayer().ALSR or {};
    LocalPlayer().ALSR.FirstSpawn = true;

end );

local function DrawPropOcclusion()

    local Ents = ALSR.Props:GetNextProp( MaxRateObjects );

    if ( Ents == nil or table.Count( Ents ) == 0 ) then return; end;

    local PlayersOcclusionIsTarget = false;

    for _, Ent in pairs( Ents ) do
        local IsTarget = ALSR.Occlusion:EntityIsTarget( LocalPlayer(), Ent, PlayerViewRadius, PlayerViewDistance, PlayerDisableDetectorDistance );
        
        if ( IsTarget ~= nil and IsTarget == true ) then
            PlayersOcclusionIsTarget = true;
        end;
        
        if ( not table.HasValue( IgnoreEntityList, Ent ) ) then
            if ( PlayersOcclusionIsTarget ) then

                ALSR.Occlusion:EntitySetNoDraw( Ent, false );
                Ent.NoDraw = false;

            else
                
                ALSR.Occlusion:EntitySetNoDraw( Ent, true );
                Ent.NoDraw = true;

            end;
        end;
    end;
end;

local function PropsCalculation()
    ALSR.Props:Calculation( CacheProps );
end;

local function PropsSortCalculation()
    local PlayerPos = LocalPlayer():GetPos();
    table.sort( CacheProps, 
        function( a, b )
            if ( IsValid( a ) and IsValid( b ) ) then
                return a:GetPos():Distance( PlayerPos ) < b:GetPos():Distance( PlayerPos );
            end;
        end 
    );
end;

local function Cmd_StartOrReloadSystem()
    local AlsrIsEnableValue = GetConVar( "alsr_client_enable" ):GetInt();

    if ( IsClientOnly && AlsrIsEnableValue == 1 ) then
        local PropCalcDelay = GetConVar( 'alsr_client_prop_calc_delay' ):GetFloat();
        local PropSortDelay = GetConVar( 'alsr_client_prop_sort_delay' ):GetFloat();
        local PropVisibilityDelay = GetConVar( 'alsr_client_visibility_delay' ):GetFloat();
        local PropSortIsEnable = GetConVar( 'alsr_client_sort_enable' ):GetInt();

        MaxRateObjects = GetConVar( 'alsr_max_props_visibility_one_rate' ):GetInt();

        timer.Create( "ALSR_Timer.PropsCalculation", PropCalcDelay, 0, PropsCalculation );
        if ( PropSortIsEnable == 1 ) then
            timer.Create( "ALSR_Timer.PropsSortCalculation", PropSortDelay, 0, PropsSortCalculation );
        end;
        timer.Create( "ALSR_Timer.DrawPropOcclusion.PropViewController", PropVisibilityDelay, 0, DrawPropOcclusion );
    end;
end;
concommand.Add( "alsr_client_system_start_or_reload", Cmd_StartOrReloadSystem, nil, "Activate or reboot the system.");

local function Cmd_StopSystem()
    if ( timer.Exists( "ALSR_Timer.PropsCalculation" ) ) then
        timer.Remove( "ALSR_Timer.PropsCalculation" );
    end;

    if ( timer.Exists( "ALSR_Timer.PropsSortCalculation" ) ) then
        timer.Remove( "ALSR_Timer.PropsSortCalculation" );
    end;

    if ( timer.Exists( "ALSR_Timer.DrawPropOcclusion.PropViewController" ) ) then
        timer.Remove( "ALSR_Timer.DrawPropOcclusion.PropViewController" );
    end;

    for _, Ent in pairs( CacheProps ) do
        ALSR.Occlusion:EntitySetNoDraw( Ent, false );
        Ent.NoDraw = false;
    end;
end;
concommand.Add( "alsr_client_system_stop", Cmd_StopSystem, nil, "Stop the system.");

net.Receive( 'Net.Alsr.SystemAuthority', function( Length )

    local IsServerOnly = net.ReadBool();

    PlayerViewRadius = net.ReadFloat();
    PlayerViewDistance = net.ReadFloat();
    PlayerDisableDetectorDistance = net.ReadFloat();

    if ( not IsServerOnly ) then
        IsClientOnly = true;
    else
        IsClientOnly = false;
    end;

    Cmd_StartOrReloadSystem();
    
end );