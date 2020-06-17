if ( SERVER ) then
    return;
end;

local CacheProps = {};
local IgnoreEntityList = {};

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

    -- table.insert( CacheProps, Ent );
    Ent.NoDraw = Ent.NoDraw or false;

end );

net.Receive( 'Net.PostCleanupMap.PropViewController', function( Length )

    table.Empty( IgnoreEntityList );

end );

net.Receive( 'Net.PlayerFinalizateSpawn.PropViewController', function( Length )

    LocalPlayer().ALSR = LocalPlayer().ALSR or {};
    LocalPlayer().ALSR.FirstSpawn = true;

end );