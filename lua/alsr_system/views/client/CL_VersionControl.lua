local version = "1.0";
local filename = "alsr_version.txt";

timer.Simple( 5, function()

    if ( file.Exists( filename, "DATA" ) ) then
        local getVersion = file.Read( filename, "DATA" );
        if ( getVersion == version ) then return; end;
    end;
    file.Write( filename, version );

    surface.CreateFont( "ALSR_Font", {
        font = "Default",
        extended = false,
        size = 16,
        weight = 1000,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        underline = false,
        italic = false,
        strikeout = false,
        symbol = false,
        rotary = false,
        shadow = false,
        additive = false,
        outline = false,
    })

    local lang;

    local ru_lang = {
        ['title'] = "SYSTEM UPDATE - ALSR Version 1.0",
        ['html_button'] = "Перейти по ссылке",
        ['html_button_back'] = "Вернуться на главную",
        ['link'] = "https://itpony.ru/alsr/update/1.0/ru.html"
    };

    local en_lang = {
        ['title'] = "SYSTEM UPDATE - ALSR Version 1.0",
        ['html_button'] = "Go to the link",
        ['html_button_back'] = "Go back to the main",
        ['link'] = "https://itpony.ru/alsr/update/1.0/en.html"
    };

    if ( language.GetPhrase( "limit_physgun" ) == "Ограниченная физпушка" ) then
        lang = ru_lang;
    else
        lang = en_lang;
    end;

    local Width = ScrW() - 25;
    local Height = ScrH() - 25;

    local MainWindow, ParentUrlField, ParentUrlButton, ParentUrlButtonBack, ParnetHtmlPanel;

    MainWindow = vgui.Create( "DFrame" );
    MainWindow:SetSize( Width, Height );
    MainWindow:SetTitle( lang['title'] );
    MainWindow:Center();
    MainWindow:MakePopup();

    ParentUrlField = vgui.Create( "DTextEntry", MainWindow )
    ParentUrlField:SetPos( 10, 30 )
    ParentUrlField:SetTall( 25 )
    ParentUrlField:SetWide( Width - 300 - 10 )
    ParentUrlField:SetEnterAllowed( true )
    ParentUrlField:SetText( lang['link'] );
    ParentUrlField.OnEnter = function()
        ParnetHtmlPanel:OpenURL( ParentUrlField:GetValue() );
    end

    ParentUrlButton = vgui.Create( "DButton", MainWindow );
    ParentUrlButton:SetPos( Width - 295, 30 );
    ParentUrlButton:SetSize( 140, 25 );
    ParentUrlButton:SetText( lang['html_button'] );

    ParentUrlButtonBack = vgui.Create( "DButton", MainWindow );
    ParentUrlButtonBack:SetPos( Width - 150, 30 );
    ParentUrlButtonBack:SetSize( 140, 25 );
    ParentUrlButtonBack:SetText( lang['html_button_back'] );
    ParentUrlButtonBack.DoClick = function ()
        ParnetHtmlPanel:OpenURL( lang['link'] );
    end

    ParnetHtmlPanel = vgui.Create( "DHTML", MainWindow );
    ParnetHtmlPanel:SetPos( 10, 60 );
    ParnetHtmlPanel:SetSize( Width - 20, Height - 70 );
    ParnetHtmlPanel:OpenURL( lang['link'] );
    ParnetHtmlPanel.OnBeginLoadingDocument = function( panel, link )
        ParentUrlField:SetText( link );
    end;
    ParentUrlButton.DoClick = function()
        ParnetHtmlPanel:OpenURL( ParentUrlField:GetValue() );
    end;

end );