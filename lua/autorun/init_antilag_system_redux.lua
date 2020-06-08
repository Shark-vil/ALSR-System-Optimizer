ALSR = {};

print( '[ALSR] Initialization of the addon...' );

local function GetAddonFilelist( DirectoryPath )
    local FileList = {};
    local Files, Dirs = file.Find( DirectoryPath .. '/*', 'LUA' );

    for _, FileName in pairs( Files ) do
        local FileType = string.lower( string.sub( FileName, 1, 2 ) );
        FileList[ string.lower( DirectoryPath .. '/' .. FileName ) ] = FileType;
    end;

    for _, DirName in pairs( Dirs ) do
        local FileListTemp = GetAddonFilelist( DirectoryPath .. '/' .. DirName );

        for FilePath, Type in pairs( FileListTemp ) do
            FileList[ FilePath ] = Type;
        end;
    end;

    return FileList;
end;

local AddonFileList = GetAddonFilelist( 'alsr_system' );

for FilePath, Type in pairs( AddonFileList ) do
    print( '[ALSR] Loading script -> ' .. FilePath );

    if ( SERVER ) then
        if ( Type ~= 'sv' ) then
            AddCSLuaFile( FilePath );
        end;
        
        if ( Type == 'sv' or Type == 'sh' ) then
            include( FilePath );
            print( '[ALSR] Execute script ---> ' .. FilePath );
        end;
    elseif ( CLIENT ) then
        if ( Type == 'cl' or Type == 'sh' ) then
            include( FilePath );
            print( '[ALSR] Execute script ---> ' .. FilePath );
        end;
    end;
end;

print( '[ALSR] Addon is initialized!' );

AddonFileList = nil;
GetAddonFilelist = nil;

print( '[ALSR] Clearing memory from unnecessary lua functions.' );