local Meta = {
    EntitiesSaveVelocity = {},
    EntitiesCaches = {},

    EntityIsTarget = function( self, Ply, Ent, PlayerViewRadius, PlayerViewDistance, DisableDetectorDistance )

        if ( not IsValid( Ply ) or not IsValid( Ent ) ) then
            return nil;
        end;

        local EntToPlayerDistance = Ent:GetPos():Distance( Ply:GetPos() );

        if ( DisableDetectorDistance ~= nil and EntToPlayerDistance <= DisableDetectorDistance ) then
            return true;
        end;

        if ( EntToPlayerDistance > PlayerViewRadius ) then

            local PlayerAimVector = Ply:GetAimVector();
            local PlayerId = Ply:UniqueID();
            local EntityId = Ent:EntIndex();

            if ( self.EntitiesCaches[ PlayerId ] ~= nil and self.EntitiesCaches[ PlayerId ][ EntityId ] ~= nil ) then
                if ( self.EntitiesCaches[ PlayerId ][ EntityId ][ 'PlayerAimVector' ] == PlayerAimVector ) then
                    return self.EntitiesCaches[ PlayerId ][ EntityId ][ 'Boolean' ];
                end;
            end;

            local DirectionAngle = math.pi / PlayerViewRadius;
            local EntityAimVector = Ent:GetPos() - Ply:GetShootPos();
            local PlayerDot = PlayerAimVector:Dot( EntityAimVector ) / EntityAimVector:Length();
            local DotResult = PlayerDot < DirectionAngle;

            self.EntitiesCaches[ PlayerId ] = self.EntitiesCaches[ PlayerId ] or {};
            self.EntitiesCaches[ PlayerId ][ EntityId ] = self.EntitiesCaches[ PlayerId ][ EntityId ] or {};
            self.EntitiesCaches[ PlayerId ][ EntityId ][ 'PlayerAimVector' ] = PlayerAimVector;

            if ( DotResult == true or EntToPlayerDistance > PlayerViewDistance ) then
                self.EntitiesCaches[ PlayerId ][ EntityId ][ 'Boolean' ] = false;
            else
                self.EntitiesCaches[ PlayerId ][ EntityId ][ 'Boolean' ] = true;
            end

            return self.EntitiesCaches[ PlayerId ][ EntityId ][ 'Boolean' ];
        end;

        return true;

    end,

    EntityCacheRemove = function( self, Ent )

        for PlayerId, EntsTable in pairs( self.EntitiesCaches ) do
            if ( EntsTable[ EntityId ] ~= nil ) then
                table.remove( self.EntitiesCaches[ PlayerId ], EntityId );
                break;
            end;
        end;

    end,

    EntityCacheClearOnPlayer = function( self, PlayerId )

        if ( self.EntitiesCaches[ PlayerId ] ~= nil ) then
            table.Empty( self.EntitiesCaches[ PlayerId ] );
        end;

    end,

    EntityCacheClear = function( self )

        table.Empty( self.EntitiesSaveVelocity );
        table.Empty( self.EntitiesCaches );

    end,

    EntitySetNoDraw = function( self, Ent, Boolean )

        if ( not IsValid( Ent ) or ( Ent.ALSR ~= nil and Ent.ALSR.NoDraw ~= nil and Ent.ALSR.NoDraw == Boolean ) ) then
            return
        end;

        if ( Boolean == false ) then
            Ent:SetNoDraw( Boolean );
        elseif ( Boolean == true ) then
            Ent:SetNoDraw( Boolean );
        end;

        Ent.ALSR = Ent.ALSR or {};
        Ent.ALSR.NoDraw = Boolean;

    end,

    EntityEnablePhysics = function( self, Ent, Boolean )

        if ( CLIENT ) then
            return;
        end;

        if ( Boolean == true ) then
            local Rigidbody = Ent:GetPhysicsObject();
            if ( IsValid( Rigidbody ) and not Rigidbody:IsMotionEnabled() ) then
                Rigidbody:EnableMotion( true );

                for i = 1, table.Count( self.EntitiesSaveVelocity ) do
                    local TableObject = self.EntitiesSaveVelocity[ i ];
                    if ( TableObject[ 'Entity' ] == Ent ) then
                        Rigidbody:SetVelocity( TableObject[ 'Velocity' ] );
                        table.remove( self.EntitiesSaveVelocity, i );
                        break;
                    end;
                end;
            end;
        else
            local Rigidbody = Ent:GetPhysicsObject();
            if ( IsValid( Rigidbody ) and Rigidbody:IsMotionEnabled() ) then

                table.insert( self.EntitiesSaveVelocity, {
                    [ 'Entity' ] = Ent,
                    [ 'Velocity' ] = Rigidbody:GetVelocity()
                } );

                Rigidbody:EnableMotion( false );
            end;
        end;

    end,

};

Meta.__index = Meta;
ALSR.Occlusion = {};

setmetatable( ALSR.Occlusion, Meta );