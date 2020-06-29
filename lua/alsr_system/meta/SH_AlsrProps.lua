ALSR.Props = {
    prop_list = {},
    current_prop_index = 1,
    prop_count = 0,
};

local Meta = {
    Calculation = function( self, PropList )
        self.prop_list = PropList;

        self.prop_count = table.Count( self.prop_list );

        if ( self.current_prop_index > self.prop_count ) then
            self.current_prop_index = 1;
        end;
    end,
    GetCurrentPropIndex = function( self )
        return self.current_prop_index;
    end,
    GetPropCount = function( self )
        return self.prop_count;
    end,
    GetCurrentProp = function( self )        
        return self.prop_list[ self.current_prop_index ];
    end,
    GetNextProp = function( self, count )
        local function CurrentPropAdd()
            self.current_prop_index =  self.current_prop_index + 1;
            if ( self.current_prop_index > self.prop_count ) then
                self.current_prop_index = 1;
            end;    
        end;

        if ( count == nil or count <= 0 ) then
            CurrentPropAdd();
            return { self.prop_list[ self.current_prop_index ] };
        else
            local Result = {};
            for i = 1, count do
                CurrentPropAdd();
                table.insert( Result, self.prop_list[ self.current_prop_index ] )
            end;
            return Result;
        end;
    end
};

Meta.__index = Meta;

setmetatable( ALSR.Props, Meta );