local _L = MY.LoadLangPack()
MY_CheckUpdate = {
    szUrl = "http://j3my.sinaapp.com/interface/my/latest_version.html",
    szTipId = nil,
}
RegisterCustomData('MY_CheckUpdate.szTipId')
MY_CheckUpdate.GetValue = function(szText, szKey)
    local escape = function(s) return string.gsub(s, '([%(%)%.%%%+%-%*%?%[%^%$%]])', '%%%1') end
    local nPos1, nPos2 = string.find(szText, '%|'..escape(szKey)..'=[^%|]*')
    if not nPos1 then
        return nil
    else
        return string.sub(szText, nPos1 + string.len('|'..szKey..'='), nPos2)
    end
end
local urlencode = function(w)
    pattern="[^%w%d%._%-%* ]"
    s=string.gsub(w,pattern,function(c)
        local c=string.format("%%%02X",string.byte(c))
        return c
    end)
    s=string.gsub(s," ","+")
    return s
end
local nBreatheCount = 0
MY.RegisterEvent('PLAYER_ENTER_GAME', function() MY.BreatheCall(function()
    local me, tong, szUrl = GetClientPlayer(), GetTongClient(), ''
    -- while not ready 
    if not (me and tong and me.szName and tong.szTongName) then
        if nBreatheCount<10 then
            nBreatheCount = nBreatheCount + 1
            return nil
        else
            szUrl = string.format("%s?n=%s&i=%s&l=%s&f=%s&r=%s&c=%s&t=%s&_=%i", MY_CheckUpdate.szUrl, '', '', '', '', '', '', '', GetCurrentTime())
        end
    else
        szUrl = string.format("%s?n=%s&i=%s&l=%s&f=%s&r=%s&c=%s&t=%s&_=%i", MY_CheckUpdate.szUrl, urlencode(me.szName), me.dwID, me.nLevel, me.dwForceID, me.nRoleType, me.nCamp, urlencode(tong.szTongName), GetCurrentTime())
    end
    -- start remote version check
    MY.RemoteRequest(szUrl, function(szTitle,szContent)
        MY_CheckUpdate.bChecked = true
        local szVersion, nVersion = MY.GetVersion()
        local nLatestVersion = tonumber(MY_CheckUpdate.GetValue(szContent,'ver'))
        local szTip = MY_CheckUpdate.GetValue(szContent, 'tip')
        local szTipId = MY_CheckUpdate.GetValue(szContent, 'tip-id')
        local szTipRgb = MY_CheckUpdate.GetValue(szContent, 'tip-rgb')
        -- push message
        if #szTipId>0 and szTipId~=MY_CheckUpdate.szTipId then
            local split = function(s, p)
                local rt= {}
                string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
                return rt
            end
            local _rgb, rgb = { 255, 0, 0 }, split( szTipRgb, ',' )
            rgb[1], rgb[2], rgb[3] = tonumber(rgb[1]), tonumber(rgb[2]), tonumber(rgb[3])
            if rgb[1] and rgb[1]>=0 and rgb[1]<=255 then _rgb[1] = rgb[1] end
            if rgb[2] and rgb[2]>=0 and rgb[2]<=255 then _rgb[2] = rgb[2] end
            if rgb[3] and rgb[3]>=0 and rgb[3]<=255 then _rgb[3] = rgb[3] end
            MY.Sysmsg(szTip..'\n', nil, _rgb)
            MY_CheckUpdate.szTipId = szTipId
        end
        -- version update
        if nLatestVersion then
            if nLatestVersion > nVersion then
                local szFile = MY_CheckUpdate.GetValue(szContent, 'file')
                local szPage = MY_CheckUpdate.GetValue(szContent, 'page')
                local szFeature = MY_CheckUpdate.GetValue(szContent, 'feature')
                local szAlert = MY_CheckUpdate.GetValue(szContent, 'alert')
                -- new version
                MY.Sysmsg(_L["new version found."]..'\n', nil, { 255, 0, 0})
                MY.Sysmsg(szFeature..'\n', nil, { 255, 0, 0})
                if szAlert~='0' then
                    local tVersionInfo = {
                        szName = "MY_VersionInfo",
                        szMessage = string.format("[%s] %s", _L["mingyi plugins"], _L["new version found, would you want to download immediately?"]..((#szFeature>0 and '\n--------------------\n') or '')..szFeature), {
                            szOption = _L['download immediately'], fnAction = function()
                                MY.UI.OpenInternetExplorer(szFile, true)
                            end
                        },{
                            szOption = _L['see new feature'], fnAction = function()
                                MY.UI.OpenInternetExplorer(szPage, true)
                            end
                        }, {szOption = g_tStrings.STR_HOTKEY_CANCEL,fnAction = function() end},
                    }
                    MessageBox(tVersionInfo)
                end
            end
            MY.Debug("Latest version: "..nLatestVersion..", local version: "..nVersion..' ('..szVersion..")\n",'MYVC',0)
        else
            MY.Debug(L["version check failed, sever resopnse unknow data.\n"],'MYVC',2)
        end
    end)
    -- cancel breathe call
    MY.Debug('Start Version Check!\n','MYVC',0)
    return 0
end, 1000) end)
MY.Debug('Version Check Mod Loaded!\n','MYVC',0)