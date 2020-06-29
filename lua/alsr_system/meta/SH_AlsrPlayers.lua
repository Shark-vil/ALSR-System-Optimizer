ALSR.Players = {
    player_list = {},
    current_player_index = 1,
    player_count = 0,
};

local Meta = {
    Calculation = function( self, PlayerList )
        self.player_list = PlayerList;

        self.player_count = table.Count( self.player_list );

        if ( self.current_player_index > self.player_count ) then
            self.current_player_index = 1;
        end;
    end,
    GetCurrentPlayerIndex = function( self )
        return self.current_player_index;
    end,
    GetPlayerCount = function( self )
        return self.player_count;
    end,
    GetCurrentPlayer = function( self )        
        return self.player_list[ self.current_player_index ];
    end,
    GetNextPlayer = function( self )       
        self.current_player_index =  self.current_player_index + 1;
        if ( self.current_player_index > self.player_count ) then
            self.current_player_index = 1;
        end;

        return self.player_list[ self.current_player_index ];
    end
};

Meta.__index = Meta;

setmetatable( ALSR.Players, Meta );