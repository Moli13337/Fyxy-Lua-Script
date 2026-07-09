---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---

local WAIT_SERVER_ENUMS = {
    None = 0,
    preNotEnter = 1,
    SeverInfo = 2,
    ShortName = 3,

}
------------------------------------------------------------------
local LWnd = LWnd
---@class UILon:LWnd
local UILon = LxWndClass("UILon", LWnd)

------------------------------------------------------------------
--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UILon:UILon()
    self._curServer = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UILon:OnWndClose()
    self:StopQueryServerRetryTimer()
    self:StopDelayGuestStartGame()

    LxTimer.DelayTimeStop(self._delayShowAdsWallTimer)

    LWnd.OnWndClose(self)

end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UILon:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UILon:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isAmerica = LGameLanguage:IsAmericaRegion()
    self._isVie = gLGameLanguage:IsVieVersion()
    self:InitData()
    self:OnRegisterEvent()
    self:InitDrag()

    CS.ShowObject(self.mBtnCustomer,LGameCommon.CheckShowCustomerBtn())

    self:InitLocalServerData()
    self:InitRegionData()

    self:InitFirstShowUI()
    self:InitDevEvn()
    self:InitLogUploadUI()

    self:UpdateServer(false)

    --适龄初始化
    self:InitAge()

    --播放按钮刷新
    --self:RefreshMuteState()

    --海外屏蔽
    self:ShowVersionRela()

    --海外
    self:VersionRefresh()

    --数据打点
    self:SendAnalysis()

    --开服倒计时界面
    self:CheckShowOpenTimeTips()

    self:DoSdkLogin()

    if LGameSettings.platformRegion == LRegionConst.JAPAN then

    else
        self:DoGuestAutoLogin()
    end

    gLSdkImpl:CallMethod(LSdkMethod.ReqNotificationPermission, false)

    self:RefreshForeign()

    if CS.IsWebGL() and LGameSettings.isNotBootBackground then
        if self:GetWndArg("isInitGame") then
            FireEvent(EventNames.LOGIN_UI_READY)
        end
    end

    self:SetUnreadMsgRP()
    self:PlayVideo()
end

-- isOnlyState 只是更新服务器状态 火爆、正常这些
function UILon:UpdateServer(isOnlyState)

    local isShowNoticeBtn = gLGameLogin:HasNotice()

    CS.ShowObject(self.mNoticeBtn, isShowNoticeBtn)

    self:InitCurrentServerData()
    self:UpdateCurrentServerUI()

    self:CheckServerBtnShow()
    self:TryReqServerPlayerInfo()
end


function UILon:SetUnreadMsgRP()
    self:SetRed(self.mCustomerServiceBtn,gLSdkImpl:CallMethod(LSdkMethod.GetUnreadMsgRP))
end

function UILon:InitLogUploadUI()
    if LGameSettings.showLogUpload then
        self:SetWndText(self.mBtnLogUploadName, ccClientText(15063))
        CS.ShowObject(self.mBtnLogUpload, true)
        self:SetWndClick(self.mBtnLogUpload, function()
            if self._lastUploadTime and self._lastUploadTime > Time.RawUnityEngineTime.realtimeSinceStartup then
                GF.ShowMessage(ccClientText(120))
                return
            end
            self._lastUploadTime = Time.RawUnityEngineTime.realtimeSinceStartup + 10
            gLSdkImpl:CallMethod(LSdkMethod.LoganUpload)
        end)
    else
        CS.ShowObject(self.mBtnLogUpload, false)
    end
end

function UILon:InitAge()
    gLSdkImpl:CallMethod(LSdkMethod.CallSdkGetAgeLevel)
    if CS.IsUnityEdit() then
        self:InitAgeLevelUi("-2")
    end
end

------------------------------------------------------------------
---年龄限制标记
function UILon:InitAgeLevelUi(ageLevel)
    local sAgelevel = ageLevel

    local ageLevelSize = 0.4
    local ageLevelPos
    local sAgeImagePath = ""

    local ageLevelTrans = self.mAgeLevel
    local ageLevelGo = ageLevelTrans.gameObject
    if string.isempty(sAgeImagePath) then
        CS.ShowObject(ageLevelGo, false)
        return
    end

    CS.ShowObject(ageLevelGo, true)

    self:SetWndEasyImage(ageLevelTrans, sAgeImagePath, function()
        ageLevelTrans.localScale = Vector3(ageLevelSize, ageLevelSize, 1)

        if ageLevelPos then
            self:SetAnchorPos(ageLevelTrans, ageLevelPos)
        end
    end, true, true)

    self:SetWndClick(ageLevelTrans, function()
        if gLSdkImpl then
            gLSdkImpl:CallMethod(LSdkMethod.CallSdkOpenAgeAppropriatenessView)
        end
    end)

    self:ShowVersionRela()

end

--港澳台自动弹窗公告
function UILon:HmtPopNotice()
    if not self:IsCountDownLikeHmt() then
        return
    end --- 不是港澳台不从这个函数里弹出公告

    if GF.FindFirstWndByName("UISistemTip") then
        return
    end
    if gLGameLogin:HasNotice() then
        if not self._bPopNotice then
            self._bPopNotice = true
            self:ShowNotice()
        end
    end
end

function UILon:TryQueryServerShortNameForEnter()
    GF.StartWait()
    LServerUtil.QueryServerNameListFromWeb(function(bOk, ret, result, url)
        GF.StopWait()
        self:UpdateStartText("")

        if self:IsWndClosed() then
            return
        end

        if not bOk then
            GF.ShowMessage(ccClientText(139))
        end

        if self._waitServerStatus == WAIT_SERVER_ENUMS.ShortName then
            self._waitServerStatus = WAIT_SERVER_ENUMS.None
            if bOk then
                result = result or {}
                local mapData = {}
                for k, v in ipairs(result) do
                    mapData[v.id] = v
                end
                self._serverShortNameList = mapData
                self:OnEnterGame()
            else
                self:PlayDengLuAni(true)
            end
        end

    end, self._curServer.id)
end

function UILon:CheckStartArrowShow()
    local bShow = true
    if PRODUCT_G_VER > 0 then
        bShow = false
    end

    ---修改成和提审一样的静态图 20240829
    bShow = false

    if not gLSdkImpl:CallMethod(LSdkMethod.IsLogin) then
        self._isStartGameArrow = bShow
        CS.ShowObject(self.mStartGameArrow, bShow)
        return
    end
    --if self._isGuestLogin then
    --	bShow = true
    --end
    --if self._isForbidNewSelServer and gLGameLogin:IsPlayerInfoEmpty() then
    --	if not gLGameLogin:IsPlayerInfoReqing() then
    --		bShow = true
    --	end
    --end

    self._isStartGameArrow = bShow
    CS.ShowObject(self.mStartGameArrow, bShow)
end

function UILon:SetStateInfo(sState, serverId, trans, stateNameTrans)
    local img, name
    local statesTrans = trans            -- 状态节点

    -- 检查服务器列表里的状态是否是1  1：良好，2：维护，3：秘籍
    if sState ~= 1 then
        img, name = self:GetStateIcon(sState)
    else
        --良好 还需要根据服务器的状态 拥挤 爆满 顺畅 显示
        local serState = gLGameLogin:GetServerStateById(serverId)
        img, name = self:GetServerItemStatusImgAndName(serState)
    end
    self:SetWndEasyImage(statesTrans, img)

    if (stateNameTrans) then
        self:SetXUITextText(stateNameTrans, name)
        self:InitTextSizeWithLanguage(stateNameTrans, -4)
    end
end

-----------------------------------------------------------------
function UILon:OnShowServerList()
    if PRODUCT_G_VER ~= 0 then
        if gLGameLanguage:CheckIsUseSpecialProduct() then
            local packId = gLGameLanguage:GetPackProductInfo()
            if packId == 1 then

            elseif packId == 2 then
            elseif packId == 3 then
                return
            end
        end
    end

    if GF.FindFirstWndByName("UIBulin") then
        self._needWaitOpenShowServerList = true
        return
    end

    CS.ShowObject(self.mSelServerObj, false)
    GF.OpenWnd("UISelSer", {
        callFunc = function(itemdata)
            if self:IsWndClosed() then
                return
            end
            GF.CloseWndByName("UISelSer")
            CS.ShowObject(self.mSelServerObj, true)

            self._curServer = itemdata
            self:UpdateCurrentServerUI()
        end,
        hideFunc = function()
            if self:IsWndClosed() then
                return
            end
            CS.ShowObject(self.mSelServerObj, true)
        end,
        curServer = self._curServer,
        default = self._isServerDataFromDefault,
        bSelMaxPlayerLv = self._isSelHasMaxPlayerLv,
    })

    self._needWaitOpenShowServerList = false
end
-----------------------------------------------------------------
function UILon:OnLoginServerStep(step)
    local stepTextList = self._stepTextList
    if not stepTextList then
        stepTextList = {
            [LStepLoginConst.STEP_PLATFORM_AUTH] = 125,
            [LStepLoginConst.STEP_GAME_SERVER_CONNECT] = 126,
            [LStepLoginConst.STEP_GAME_SERVER_AUTH] = 127,
            [LStepLoginConst.STEP_SERVER_TIME] = 128,
            [LStepLoginConst.STEP_SERVER_PLAYER_GET] = 129,
            [LStepLoginConst.STEP_SERVER_PLAYER_CREATE] = 130,
            [LStepLoginConst.STEP_SERVER_PLAYER_INFO] = 131,
            [LStepLoginConst.STEP_SERVER_MODEL_DATA] = 132,
            [LStepLoginConst.STEP_LOGIN_OK_SEND] = 133,
            [LStepLoginConst.STEP_LOGIN_FINISH] = 134,
        }
        self._stepTextList = stepTextList
    end
    local textId = stepTextList[step]
    if not textId then
        return
    end
    self:UpdateStartText(ccClientText(textId))
end

function UILon:CheckNeedAutoLogin()
    if not self._isJaRegion then return end
    if gLGameLogin:IsPlayerInfoEmpty() then
        if not gLGameLogin:IsPlayerInfoReqing() then
            self._isGuestLogin = true
            CS.ShowObject(self.mServerBtnObj, false)
            CS.ShowObject(self.mStartGameArrow, false)
            self:DoGuestAutoLogin()
        end
    end
end

--数据打点
function UILon:SendAnalysis()
    local isUpdate = gLxPatchCtrl:IsReload()
    local updateResVer = gLxServerList.activePackageVersion
    gLxTKData:StepLoginUI(isUpdate, updateResVer)
end

function UILon:OpenHmtCountDownWnd(countDownTimeValue)
    self:StopDelayGuestStartGame()
    local para = {
        countDownTimeValue = countDownTimeValue / 1000,
    }
    GF.OpenWnd("UISerOpenCountDown", para)
end

function UILon:OnSdkLoginFailure()
    self:UpdateAccountBtnName()

    self:SetStartGameShow(true)
    gLGameLogin:ClearPlayerInfoList()
    if self._isForbidNewSelServer then
        self:CheckServerBtnShow()
    end
end

function UILon:PopNotice()
    if self:IsCountDownLikeHmt() then
        return
    end --- 港澳台不从这个函数里弹出公告

    if GF.FindFirstWndByName("UISistemTip") then
        return
    end

    if gLGameLogin:HasNotice() then
        local needShow = gModelNotice:CheckPopPlatformNotice()

        if needShow and not self._bPopNotice then
            self._bPopNotice = true
            self:ShowNotice()
        end
    end
end

function UILon:OpenCommonCountDownWnd(countDownTimeValue)
    self:StopDelayGuestStartGame()
    local para = {
        refId = 40022,
        leftFunc = function()
            RestartGame()
        end,
        countDownTimeValue = countDownTimeValue / 1000,
    }

    CS.ShowObject(self.mStartGameBtn, false)
    gModelGeneral:OpenUIOrdinTips(para, true)
end

function UILon:_InnerQueryServerInfoForShow(serverId)
    self:StopQueryServerRetryTimer()

    local callFunc = function(bOk, ret, result, url)
        if self:IsWndClosed() then
            return
        end

        local oldQueryServerId = self._queryServerId
        if self._queryServerId == serverId then
            if ret == CS.YXWebRet.ok and not bOk and result == "null" then
                --服务器信息信息过期
                --选一个推荐服
                local defaultServerList = gLGameLogin:GetDefaultServerList()
                if defaultServerList and #defaultServerList > 0 then
                    self._curServer = defaultServerList[math.random(#defaultServerList)]
                end
                if self._curServer then
                    self._isServerDataFromDefault = true
                    self:UpdateCurrentServerUI()
                end
            else
                --服务器信息请求错误，重新多请求几次
                if not bOk and self._forShowReTry < 3 then
                    self._forShowReTry = self._forShowReTry + 1
                    self:StopQueryServerRetryTimer()
                    self._queryServerRetryTimer = LxTimer.DelayTimeCall(function()
                        self:_InnerQueryServerInfoForShow(serverId)
                    end, 5)
                    return
                end
            end
            --上面的不跑了 才清空
            self._queryServerId = nil
        end
        if not bOk then
            if not self._curServer then
                --找不到就显示自动弹出服务器列表选择
                self:OnShowServerList()
            end
            return
        end
        if result.id ~= oldQueryServerId then
            return
        end

        if self._curServer and self._curServer.id ~= result.id then
            return
        end

        self._curServer = result

        self:UpdateCurrentServerUI()

    end
    LServerUtil.QueryServerDetailFromWeb(callFunc, serverId)
end

---登录sdk账号才显示服务器列表
function UILon:CheckServerBtnShow()
    local bShow = true
    if not gLSdkImpl:CallMethod(LSdkMethod.IsLogin) then
        bShow = false
    end
    if self._isGuestLogin then
        bShow = false
    end
    --if self._isForbidNewSelServer and gLGameLogin:IsPlayerInfoEmpty() then
    --	bShow = false
    --end
    CS.ShowObject(self.mServerBtnObj, bShow)
    self:CheckStartArrowShow()
end

function UILon:ShowNotice()
    if GF.FindFirstWndByName("UISelSer") then
        self._needWaitOpenShowNotice = true
        return
    end

    self._needWaitOpenShowNotice = false
    if gLGameLogin:HasNotice() then
        local dataList = gLGameLogin:GetPlatformNotices()
        GF.OpenWndTop("UIBulin", { type = 2, list = dataList })
        local time = os.time()
        LPlayerPrefs.SetPlatformNotice(tostring(time))
    end
end

function UILon:ShowRepairRes()
    gLxPatchCtrl:GotoRepairRes()
end

function UILon:ShowVersionRela()
    local showAge1 = false
    local showVersion, showAge = true, true
    if gLGameLanguage:IsKoreaRegion() then
        showVersion = false
    elseif gLGameLanguage:IsOtherLngRegion() then
        showVersion = false
        showAge = false
    elseif gLGameLanguage:IsChinaRegion() then
        showAge = false
        showVersion = false
        --showAge1 = gLSdkImpl:CallMethod(LSdkMethod.IsXiaomiPlatform)
        showAge1 = true
        --- 微信小程序需要显示 16+
        local isWX = gLGameLanguage:IsChinaRegion() and CS.IsWebGL() and LWxHelper.IsMiniGamePlatform()
        if isWX then
            showAge1 = true
            showVersion = true
        end
        if showAge1 then
            local refId = 804
            if isWX then
                refId = 805
            end
            self:SetWndEasyImage(self.mAgeLevelCH,"login_txt_age")
            self:SetWndClick(self.mAgeLevelCH,function()
                GF.OpenWndUp("UIBzTips", { refId = refId })
            end)
        end
    end
    CS.ShowObject(self.mDescBg, showVersion)
    CS.ShowObject(self.mAgeLevel, showAge)
    CS.ShowObject(self.mAgeLevelCH, showAge1)

    if PRODUCT_G_VER ~= 0 then
        if gLGameLanguage:CheckIsUseSpecialProduct() then
            local packId = gLGameLanguage:GetPackProductInfo()
             local starBtn  = gLGameLanguage:GetStarBtnInfo(packId)
            local startGameBtnImg = CS.FindTrans(self.mStartGameBtn, "startGameBtnImg")
            self:SetWndEasyImage(startGameBtnImg, starBtn)

            if packId == 1 then

            elseif packId == 2 then
            elseif packId == 3 then
                local choseService = CS.FindTrans(self.mServerBtnObj, "ChooseService")
                CS.ShowObject(choseService, false)
            end
        end
    end
end

function UILon:InitRegionData()
    --游客模式登陆
    self._isGuestLogin = false
    self._showCustomerServiceBtn = false
    self._showAccountSwitchesBtn = false
    self._showMuteMusicBtn = true
    self._showAdsWall = false
    self._isOsIos = CS.IsOSIos()
    self._isForbidNewSelServer = true --gLSdkImpl:CallMethod(LSdkMethod.IsForbidNewSelServer) or false
    self._isJaRegion = gLGameLanguage:IsJapanRegion()
    if self._isJaRegion then
        --self._isGuestLogin = true
    end
end

function UILon:InitCurrentServerData()
    local oldServer = self._curServer
    local serverId = tonumber(LPlayerPrefs.serverId) or 0
    local serverMap = gLGameLogin:GetServerKeyList()
    local server = serverMap[serverId]
    self._curServer = server

    if gLGameLogin:IsExclusiveMode() then
        if not server then
            local exclusiveList = gLGameLogin:GetExclusiveList()
            server = exclusiveList[1]
            self._curServer = server
        end
        return
    end

    if oldServer and not oldServer.isLocalCache then
        --如果不是缓存的继续用之前选的
        self._curServer = oldServer
        return
    end

    if server then
        return
    end

    --推荐列表里也没有之前登陆服务器信息 重新请求
    if serverId > 0 and not server then
        self._curServer = oldServer
        self:TryQueryServerInfoForShow(serverId)
        return
    end

    local defaultServerList = gLGameLogin:GetDefaultServerList()
    if defaultServerList and #defaultServerList > 0 then
        local serverLen = #defaultServerList
        if serverLen > 1 then
            local rand = math.random(1, serverLen * 10000)
            rand = rand % serverLen + 1
            server = defaultServerList[rand]
        else
            server = defaultServerList[1]
        end
        self._isServerDataFromDefault = true
    end
    self._curServer = server

    if not server then
        --找不到就显示自动弹出服务器列表选择
        self:OnShowServerList()
        return
    end
end

function UILon:CheckShowOpenTimeTips()
    local serverTimeStamp = gLGameLogin:GetTimeStamp()
    local openTime = gLGameLogin:GetChannelOpenTime()
    if not (openTime and serverTimeStamp) then
        self._isShowOpenTimeTips = false
        return
    end

    local countDownTimeValue = openTime - serverTimeStamp
    if countDownTimeValue <= 0 then
        self._isShowOpenTimeTips = false
        return
    end

    self._isShowOpenTimeTips = true
    self._countDownTimeValue = countDownTimeValue
end

-----------------------------------------------------------------
function UILon:OnTcpLost()
    self._bLogin = false

    self:DoGuestAutoLogin(true)
end

function UILon:OnTargetWndClose(wndName)
    if wndName == "UIBulin" then
        if self._needWaitOpenShowServerList then
            self:OnShowServerList()
        end
    elseif wndName == "UISelSer" then
        if self._needWaitOpenShowNotice then
            self:ShowNotice()
        end
    elseif wndName == "UISerOpenCountDown" or wndName == "UISerOpenCountDownJapan" then
        if self:IsCountDownLikeHmt() then
            self:HmtPopNotice()
        end
    end
end

function UILon:GetServerItemStatusImgAndName(state)
    local icon, name
    local ref = GameTable.GameServerStateRef[state]
    if ref then
        icon = ref.icon
        name = ccLngText(ref.name)
    end
    return icon, name
end

function UILon:OnEnterGame()
    if self._isPlayEnterGame then
        return
    end
    if not self._isAgree then
        GF.ShowMessage(ccClientText(115))
        self:PlayDengLuAni(true)
        return
    end

    if self._isJaRegion then
        if not CS.IsWebGL()  then
            if checknumber(LPlayerPrefs.isJaAgreeRule) == 0 then
                GF.OpenWnd("UIHelpListJa")
                self:PlayDengLuAni(true)
                return
            end
        end
    end

    if self._bLogin then
        GF.ShowMessage(ccClientText(102))
        self:PlayDengLuAni(true)
        return
    end

    if not gLSdkImpl:CallMethod(LSdkMethod.IsLogin) then
        self:DoSdkLogin()
        self:PlayDengLuAni(true)
        return
    end

    local curServer = self._curServer
    if not curServer then
        if self._queryServerId ~= nil then
            GF.ShowMessage(ccClientText(101))
        else
            self:OnShowServerList()
        end
        return
    end

    if self._waitServerStatus and self._waitServerStatus > WAIT_SERVER_ENUMS.None then
        GF.ShowMessage(ccClientText(102))
        return
    end

    self._waitServerStatus = WAIT_SERVER_ENUMS.None

    -- 是否是白名单
    local isWhiteName = gLGameLogin:IsWhiteUser()
    if curServer.state ~= 1 and isWhiteName ~= 1 then
        GF.OpenWnd("UISistemTip", { refId = 40012, notClose = false, content = curServer.maintenanceText,
                                     leftFunc = function()
                                         GF.CloseWndByName("UISistemTip");
                                         self:ShowNotice()
                                         self:PlayDengLuAni(true)
                                     end,
                                     func = function()
                                         self._waitServerStatus = WAIT_SERVER_ENUMS.preNotEnter
                                         self:TryQueryServerInfoForEnter()
                                     end,
                                     closeFunc = function()
                                         self:TryQueryServerInfoForShow(curServer.id)
                                     end
        })
        return
    end

    if string.isempty(curServer.ip) or string.isempty(curServer.port) then
        self._waitServerStatus = WAIT_SERVER_ENUMS.SeverInfo
        self:TryQueryServerInfoForEnter()
        self:UpdateStartText(ccClientText(137))
        return
    end

    if not self._serverShortNameList then
        self._waitServerStatus = WAIT_SERVER_ENUMS.ShortName
        self:TryQueryServerShortNameForEnter()
        self:UpdateStartText(ccClientText(137))
        return
    end

    gLGameLogin:SetServerShortName(self._serverShortNameList)

    self._bLogin = true

    self:UpdateStartText(ccClientText(124))

    gLGameLogin:SetWaitEnterGame(false)

    if gLGameLogin:IsExclusiveMode() then
        --独占时候不存服务器id和名字到缓存
        --LPlayerPrefs.SetServerName("")
        --LPlayerPrefs.SetServerId("")
    else
        gLGameLogin:SetLastServerName(LPlayerPrefs.serverName)
        LPlayerPrefs.SetServerName(curServer.name)
        LPlayerPrefs.SetServerId(curServer.id)
    end
    gLGameLogin:SetLoginServer(curServer)
    gLGameLogin:Step_AuthPlatform()
    gLxTKData:BeginLoginGame()

    if gLSdkImpl then
        gLSdkImpl:CallMethod(LSdkMethod.OnSelGameServer)
    end
end

function UILon:OnClickCustomerService()
    gModelGeneral:OpenUIOrdinTips({ refId = 40020 })
end

function UILon:ChangeMuteLoginMusic()
    local bMute = toboolean(LPlayerPrefs.muteLoginMusic)
    bMute = not bMute
    LPlayerPrefs.SetMuteLoginMusic(tostring(bMute))
    if bMute then
        if gLGameAudio then
            --gLGameAudio:CloseWndMusic()
            --gLGameAudio:CloseMapMusic()
            gLGameAudio:CloseAllMusic()
        end
    else
        if gLGameScene:IsCurrentScene("LLoginScene") then
            local scene = gLGameScene:GetCurrentScene()
            if scene and scene.PlayLoginMusic then
                scene:PlayLoginMusic()
            end
        end
    end
    self:RefreshMuteState()
end

function UILon:InitDrag()
    self._arrowRightPos = self.mArrowRight.localPosition
    self._arrowLeftPos = self.mArrowLeft.localPosition
    self._arrowRightEndPos = self.mArrowREnd.localPosition
    self._arrowLeftEndPos = self.mArrowLEnd.localPosition
    self._arrowPos = self.mStartGameArrow.localPosition
    --拖动
    self:UIDragSetItem("_startGameArrowRight", "ContentLogin/SelServer/startGameArrow/arrowRClick", CS.YXUIDrag.DragMode.DragNothing)
    self:UIDragSetItem("_startGameArrowLeft", "ContentLogin/SelServer/startGameArrow/arrowLClick", CS.YXUIDrag.DragMode.DragNothing)
    self:UIDragSetItem("_startGameArrow", "ContentLogin/SelServer/startGameArrow", CS.YXUIDrag.DragMode.DragNothing)
end

function UILon:OnTimer(key)
    if key == "_delayEnterGameTimer" then
        self:TimerStop("_delayEnterGameTimer")
        self._isPlayEnterGame = false
        FireEvent(EventNames.LOGIN_SPINE_HIDE, true)
        CS.ShowObject(self.mStartGameBtn, false)

        self:OnEnterGame()
    end
end

function UILon:SetStartGameShow(bShow)
    if self._isGuestLogin then
        return
    end
    CS.ShowObject(self.mStartGameBtn, bShow)
end

function UILon:TryQueryServerInfoForShow(serverId, bRetry)
    self._queryServerId = serverId
    self._forShowReTry = 0
    self:_InnerQueryServerInfoForShow(serverId)
end

function UILon:UIDragOnDrag(dragKey, eventData)
    if dragKey == "_startGameArrowRight" then
        local trans = self.mStartGameArrow
        local camera = eventData.pressEventCamera
        local pos = camera:ScreenToWorldPoint(eventData.position)
        pos = trans.parent:InverseTransformPoint(pos)
        local localPos = self._arrowRightPos
        if math.abs(pos.x - localPos.x) > 10 then
            self._isGameArrowRightMoving = true
        end
    elseif dragKey == "_startGameArrowLeft" then
        local trans = self.mStartGameArrow
        local camera = eventData.pressEventCamera
        local pos = camera:ScreenToWorldPoint(eventData.position)
        pos = trans.parent:InverseTransformPoint(pos)
        local localPos = self._arrowLeftPos
        if math.abs(pos.x - localPos.x) > 10 then
            self._isGameArrowLeftMoving = true
        end
    elseif dragKey == "_startGameArrow" then
        local trans = self.mStartGameArrow
        local camera = eventData.pressEventCamera
        local pos = camera:ScreenToWorldPoint(eventData.position)
        pos = trans.parent:InverseTransformPoint(pos)
        local localPos = self._arrowPos
        if math.abs(pos.x - localPos.x) > 10 or math.abs(pos.y - localPos.y) > 10 then
            self._isGameArrowLeftMoving = true
            self._isGameArrowRightMoving = true
        end
    end

end

function UILon:StopQueryServerRetryTimer()
    if self._queryServerRetryTimer then
        LxTimer.DelayTimeStop(self._queryServerRetryTimer)
        self._queryServerRetryTimer = nil
    end
end

function UILon:StartLoopCheckAutoLogin()
    self:StopDelayGuestStartGame()
    self._waitAutoLoginTime = 0
    self._delayGuestStartTimer = LxTimer.LoopTimeCall(function()
        if not gLSdkImpl:CallMethod(LSdkMethod.IsLogin) then
            self._waitAutoLoginTime = self._waitAutoLoginTime + 1
            if self._waitAutoLoginTime > 150 then
                self:StopDelayGuestStartGame()
                CS.ShowObject(self.mStartGameBtn, true)
            end
            return
        end
        self:StopDelayGuestStartGame()

        if gLSdkImpl:CallMethod(LSdkMethod.IsSdkSwitchAccount) then
            GF.OpenWnd("UISelSer", {
                callFunc = function(itemdata)
                    if self:IsWndClosed() then
                        return
                    end
                    GF.CloseWndByName("UISelSer")
                    CS.ShowObject(self.mSelServerObj, true)
                    self._curServer = itemdata
                    self:UpdateCurrentServerUI()

                    if not gLGameLogin:IsExclusiveMode() then
                        --独占时候不存服务器id和名字到缓存
                        LPlayerPrefs.SetServerName(itemdata.name)
                        LPlayerPrefs.SetServerId(itemdata.id)
                    end
                    self:OnEnterGame()
                end,
                hideFunc = function()

                end,
                curServer = self._curServer,
                default = self._isServerDataFromDefault,
                isSwitchAccount = true,
                bSelMaxPlayerLv = self._isSelHasMaxPlayerLv,
            })
        else
            self:OnEnterGame()
        end
    end, 0.3, false, -1)
end

function UILon:OnBackLogin()
    if not gLSdkImpl:CallMethod(LSdkMethod.IsLogin) then
        gLSdkImpl:CallMethod(LSdkMethod.Login)
    end
    self:UpdateAccountBtnName()

    self._bLogin = false
    gLGameLogin:SetWaitEnterGame(true)

    self:UpdateStartText("")
    self:UpdateServer(false)
    self._serverShortNameList = nil

    self:PlayDengLuAni(true)

    self:DoGuestAutoLogin(true)

    if self:IsCountDownLikeHmt() and self._isShowOpenTimeTips then
        self:CheckShowOpenTimeTips()
        ---上面函数会修改self._isShowOpenTimeTips的值， 因此需要重新检查
        if self._isShowOpenTimeTips then
            self:OpenHmtCountDownWnd(self._countDownTimeValue)
        end
    end
end

function UILon:IsCountDownLikeHmt()
    --- 后台控制，这边不做拦截
    --if LGameSettings.platformRegion == LRegionConst.SEA or LGameSettings.platformRegion == LRegionConst.AMERICA or LGameSettings.platformRegion == LRegionConst.HMT
    --        or LGameSettings.platformRegion == LRegionConst.JAPAN or LGameSettings.platformRegion == LRegionConst.VIETNAM
    --then
    --    return true
    --end
    --return false
    return true
end

function UILon:InitDevEvn()
    if not CS.IsOsWinOrEdit() then
        return
    end
    if not LDevEnvironment or
            not LDevEnvironment.datalist or
            #LDevEnvironment.datalist <= 0 then
        return
    end
    CS.ShowObject(self.mDevEnvBtn, true)
    self:SetWndClick(self.mDevEnvBtn, function(...)
        if not CS.IsOsWinOrEdit() then
            return
        end
        if not LDevEnvironment or
                not LDevEnvironment.datalist or
                #LDevEnvironment.datalist <= 0 then
            return
        end
        GF.OpenWnd("UI_CTDevEnvironment")
    end)
end

function UILon:DoSdkLogin()
    self:SetStartGameShow(false)

    --等待sdk登录
    GF.StartWaitMask()
    self:StopWaitPlatformOk()

    local isDisableSdkLogin = PJXCenter.GameMgr:GetGameEnvVar("GameDisableSdkLogin")
    if isDisableSdkLogin == "true" then
        PJXCenter.GameMgr:SetGameEnvVar("GameDisableSdkLogin", "false")
        return
    end

    self._delaySdkTimer = LxTimer.DelayTimeCall(function()
        self:StopWaitPlatformOk()
    end, 2, false)

    FireEvent(EventNames.SDK_LOGIN_START)
    gLSdkImpl:CallMethod(LSdkMethod.Login)
end

function UILon:InitLocalServerData()
    local serverId = tonumber(LPlayerPrefs.serverId) or 0
    if serverId > 0 then
        self._curServer = {
            id = serverId,
            name = LPlayerPrefs.serverName,
            state = 2,
            isLocalCache = true,
        }
    end
end

function UILon:InitData()
    self._recommendIcon = GameTable.GameServerConfigRef["recommendIcon"]            -- 推荐服图标
    self._newIcon = GameTable.GameServerConfigRef["newIcon"]                        -- 新服图标
    self._newValue = GameTable.GameServerConfigRef["newValue"]                        -- 新服图标

    self._isAgree = true
    self:SetXUITextText(self.mNoticeBtnName, ccClientText(112))
    self:SetXUITextText(self.mRepairBtnName, ccClientText(113))
    self:SetXUITextText(self.mCustomerServiceName, ccClientText(141))
    --self:SetXUITextText(self.mChooseService,ccClientText(108))
    self:SetXUITextText(self.mStartGameBtnName, ccClientText(110))
    self:SetXUITextText(self.mProtocolTxt, ccClientText(111))

    self:SetXUITextText(self.mHtmAccountBtnName, ccClientText(160))

    self:SetXUITextText(self.mHmtFBBtnName, ccClientText(161))

    self:SetXUITextText(self.mHmtDisCardBtnName, ccClientText(32809))

    self:SetXUITextText(self.mDescTxt, self:GetGameDescStr())

    self:InitTextSizeAndLineAndStr(self.mShunchangTxt, ccClientText(116))
    self:InitTextSizeAndLineAndStr(self.mYongjiTxt, ccClientText(117))
    self:InitTextSizeAndLineAndStr(self.mBaomanTxt, ccClientText(118))
    self:InitTextSizeAndLineAndStr(self.mWeihuTxt, ccClientText(119))

    -- 显示版本信息
    self:SetXUITextText(self.mVersion, gLxServerList:GetVersionStr())

    self:SetXUITextText(self.mBtnCustomerName, ccClientText(141))

    local isKr = gLGameLanguage:IsKoreaRegion()
    if isKr then
        self:SetXUITextText(self.mBtnNaverLoungeName, ccClientText(32810))
        self:SetXUITextText(self.mBtnFBName, ccClientText(32808))
        self:SetXUITextText(self.mBtnDiscordName, ccClientText(32809))

        self:SetWndClick(self.mBtnNaverLounge,function()
            CS.UApplication.OpenURL("https://game.naver.com/lounge/Tales_of_Angels/home")
        end)
        self:SetWndClick(self.mBtnFB,function()
            CS.UApplication.OpenURL("https://www.facebook.com/tales.of.angels.korea/")
        end)
        self:SetWndClick(self.mBtnDiscord,function()
            CS.UApplication.OpenURL("https://discord.gg/2px5zUrPn8")
        end)
    end
    CS.ShowObject(self.mBtnNaverLounge,isKr)
    CS.ShowObject(self.mBtnFB,isKr)
    CS.ShowObject(self.mBtnDiscord,isKr)
end

function UILon:VersionRefresh()
    self:InitTextLineWithLanguage(self.mMuteMusicBtnName, -50)
    self:InitTextLineWithLanguage(self.mCustomerServiceName, -50)
end

function UILon:PlayDengLuAni(bShowUi)
    CS.ShowObject(self.mServerBtnObj, bShowUi)
    CS.ShowObject(self.mStartGameArrow, false)--CS.ShowObject(self.mStartGameArrow, bShowUi)
    CS.ShowObject(self.mLeftFuncNode, bShowUi)

    --改成和提审一样的静态图 20240829
    --local isIosVerify = PRODUCT_G_VER > 0
    if true then
        --if isIosVerify then
        if bShowUi then
            CS.ShowObject(self.mStartGameBtn, true)
        end
        return
    end

    if bShowUi then
        FireEvent(EventNames.LOGIN_SPINE_PLAY_ANI, "idle", 1)
        CS.ShowObject(self.mStartGameBtn, true)
        FireEvent(EventNames.LOGIN_SPINE_HIDE, false)
    else
        FireEvent(EventNames.LOGIN_SPINE_PLAY_ANI, "denglu", 1)
    end
    if self._isStartGameArrow then
        if bShowUi then
            self:GetSeqCom():DeleteSeq("_arrowShowOpenSeq")
            CS.ShowObject(self.mArrowShow, false)
        else
            self.mArrowLeft.localPosition = self._arrowLeftPos
            self.mArrowRight.localPosition = self._arrowRightPos
            CS.ShowObject(self.mArrowShow, true)
            self:GetSeqCom():DeleteSeq("_arrowShowOpenSeq")
            local seq = self:GetSeqCom():CreateSeq("_arrowShowOpenSeq")
            local moveTime = 0.6
            seq:Append(self.mArrowLeft:DOLocalMove(self._arrowLeftEndPos, moveTime))
            seq:Insert(0, self.mArrowRight:DOLocalMove(self._arrowRightEndPos, moveTime))
            seq:SetEase(DG.Tweening.Ease.OutCubic)
            seq:OnComplete(function()
                self:GetSeqCom():DeleteSeq("_arrowShowOpenSeq")
                CS.ShowObject(self.mArrowShow, false)
            end)
            seq:PlayForward()
        end
    end
end

function UILon:TryReqServerPlayerInfo()
    if not gLSdkImpl:CallMethod(LSdkMethod.IsLogin) then
        return
    end
    gLGameLogin:Step_QueryUserPlayerInfoFromWeb()
end

function UILon:DoGuestAutoLogin(bLost)
    if not self._isGuestLogin then
        return
    end

    if bLost then
        CS.ShowObject(self.mStartGameBtn, true)
        return
    end
    CS.ShowObject(self.mStartGameBtn, false)

    self:StopDelayGuestStartGame()
    self._delayGuestStartTimer = LxTimer.DelayTimeCall(function()
        self:StartLoopCheckAutoLogin()
    end, 0.7)
end

function UILon:InitFirstShowUI()
    CS.ShowObject(self.mTestCartoonBtn, false)
    CS.ShowObject(self.mDevEnvBtn, false)
    CS.ShowObject(self.mLoginRootObj, false)

    CS.ShowObject(self.mSelServerObj, true)
    CS.ShowObject(self.mNoticeBtn, false)
    CS.ShowObject(self.mCustomerServiceBtn, self._showCustomerServiceBtn)
    CS.ShowObject(self.mAccountSwitchesBtn, self._showAccountSwitchesBtn)
    --CS.ShowObject(self.mMuteMusicBtn, self._showMuteMusicBtn)

    CS.ShowObject(self.mHmtAccountBtn, true)

    if PRODUCT_G_VER ~= 0 then
        --CS.ShowObject(self.mStartGameBtnBg, false)
    end

    local isShow = false
    if gLGameLanguage:IsHmtRegion() or self._isAmerica then
        isShow = true
        if gLSdkImpl:CallMethod(LSdkMethod.IsNotSupportFB) then
            isShow = false
        end
        if PRODUCT_G_VER ~= 0 then
            --提审不显示
            isShow = false
        end
        self._hmtFbBtnRegPoint = self:FindWndTrans(self.mHmtFBBtn, "redPoint")
        if LPlayerPrefs.loginFBRed and LPlayerPrefs.loginFBRed == "1" and self._hmtFbBtnRegPoint then
            CS.ShowObject(self._hmtFbBtnRegPoint, false)
        end
    end
    CS.ShowObject(self.mHmtFBBtn, isShow)
    CS.ShowObject(self.mHmtDisCardBtn, isShow and self._isAmerica)

    if self._isJaRegion then
        CS.ShowObject(self.mJaAgreeBtn, true)
        self:SetWndText(self.mJaAgreeBtnName, ccClientText(803))
    else
        CS.ShowObject(self.mJaAgreeBtn, false)
    end
    --提审模式不显示
    if PRODUCT_G_VER ~= 0 then
        CS.ShowObject(self.mRepairBtn, false)
        if LGameSettings.platformRegion == LRegionConst.SEA then
            CS.ShowObject(self.mHmtAccountBtn, false)
        end
    else
        CS.ShowObject(self.mRepairBtn, not CS.IsWebGL())
    end

    if LGameSettings.platformRegion == LRegionConst.VIETNAM then
        if CS.IsOSIos() then
            CS.ShowObject(self.mHmtAccountBtn, false)
        end
    end

    if CS.IsWebGL()  then
        if gLGameLanguage:IsJapanRegion()  then
            CS.ShowObject(self.mHmtAccountBtn, false)
            CS.ShowObject(self.mJaAgreeBtn, false)
        end
    end
    if gLSdkImpl:CallMethod(LSdkMethod.IsNotSupportAccountBtn) then
        CS.ShowObject(self.mHmtAccountBtn, false)
    end

    if gLGameLanguage:IsChinaRegion() and CS.IsWebGL() and LWxHelper.IsMiniGamePlatform() then
        CS.ShowObject(self.mHmtAccountBtn, false)
    end

    CS.ShowObject(self.mAgeLevel, false)

end

--sdk 登录成功
function UILon:OnSdkLoginOk()
    self:UpdateAccountBtnName()

    self:SetStartGameShow(true)

    self:StopWaitPlatformOk()
    gLGameLogin:ClearPlayerInfoList()
    self:TryReqServerPlayerInfo()
    self:CheckServerBtnShow()
    self:PopNotice()
    self:ShowAdsWall()

    --港澳台是sdk登录后显示开服倒数
    if self:IsCountDownLikeHmt() then
        if self._isShowOpenTimeTips then
            if self:IsCountDownLikeHmt() then
                self:OpenHmtCountDownWnd(self._countDownTimeValue)
            end
        else
            self:HmtPopNotice()
        end
    end

    if self._isJaRegion then
        if not CS.IsWebGL()  then
            if checknumber(LPlayerPrefs.isJaAgreeRule) == 0 then
                GF.OpenWnd("UIHelpListJa")
            end
        end
    end
end

function UILon:InitTextSizeAndLineAndStr(textTrans, str)
    if not (CS.IsValidObject(textTrans) and str) then
        return
    end

    self:SetXUITextText(textTrans, str)
    self:InitTextLineWithLanguage(textTrans, -30)
    self:InitTextSizeWithLanguage(textTrans, -2)
end

function UILon:TryQueryServerInfoForEnter()
    if not self._curServer then
        return
    end
    GF.StartWait()
    LServerUtil.QueryServerDetailFromWeb(function(bOk, ret, result, url)
        GF.StopWait()
        self:UpdateStartText("")

        if self:IsWndClosed() then
            return
        end

        if not bOk then
            GF.ShowMessage(ccClientText(139))
        end

        if bOk then
            self._curServer = result
            self:UpdateCurrentServerUI()
        end

        if self._waitServerStatus == WAIT_SERVER_ENUMS.preNotEnter then
            self._waitServerStatus = WAIT_SERVER_ENUMS.None
            self._serverShortNameList = nil
            self:OnEnterGame()
            return
        end

        if self._waitServerStatus == WAIT_SERVER_ENUMS.SeverInfo then
            self._waitServerStatus = WAIT_SERVER_ENUMS.None
            if bOk and self._curServer and (not string.isempty(self._curServer.ip) and not string.isempty(self._curServer.port)) then
                self:OnEnterGame()
            else
                self:PlayDengLuAni(true)
            end
        end
    end, self._curServer.id)
end

function UILon:ShowAdsWall()
    if not self._showAdsWall then
        return
    end
    LxTimer.DelayTimeStop(self._delayShowAdsWallTimer)
    self._delayShowAdsWallTimer = LxTimer.DelayFrameCall(function()
        self._delayShowAdsWallTimer = nil
        gLSdkImpl:CallMethod(LSdkMethod.CallSdkAdsWall)
        gLSdkImpl:CallMethod(LSdkMethod.CallSdkAppComment, "level", "10", true)
    end, 1)
end

function UILon:UpdateCurrentServerUI()
    if self._curServer then
        self:SetWndText(self.mServiceName, self._curServer.name)
        self:SetStateInfo(self._curServer.state, self._curServer.id, self.mStatuImg, self.mStatuName)
    else
        self:SetWndText(self.mServiceName, "")
        self:SetStateInfo(1, 0, self.mStatuImg, self.mStatuName)
    end
end

function UILon:GetStateIcon(state)
    local icon, name
    if state == 2 then
        icon = "login_ui_4"
        name = ccClientText(121)
    else
        icon = "login_ui_3"
        name = ccClientText(122)
    end
    return icon, name
end

function UILon:ClickEnterGame()
    if self._isPlayEnterGame then
        return
    end

    FireEvent(EventNames.CLICK_ENTER_GAME)

    if not gLSdkImpl:CallMethod(LSdkMethod.IsLogin) then
        self:DoSdkLogin()
        return
    end
    ---使用静态图 20240829
    if true then
        -- if PRODUCT_G_VER > 0 then
        self._isPlayEnterGame = false
        self:PlayDengLuAni(false)
        CS.ShowObject(self.mStartGameBtn, false)
        self:OnEnterGame()
    else
        self._isPlayEnterGame = true
        self:PlayDengLuAni(false)
        self:TimerStart("_delayEnterGameTimer", 2.2, true, 1)
    end
end


function UILon:RefreshForeign()
    if self._isVie then
        self:InitTextLineWithLanguage(self.mRepairBtnName,0)
        self:InitTextLineWithLanguage(self.mBtnLogUploadName,0)
        self:InitTextLineWithLanguage(self.mHtmAccountBtnName,0)
    end
end
-----------------------------------------------------------------

-----------------------------------------------------------------
function UILon:OnRegisterEvent()
    self:WndEventRecv(EventNames.GET_AGE_LEVEL_RET, function(ageLevel)
        self:InitAgeLevelUi(ageLevel)
    end)

    self:WndEventRecv(EventNames.LOGIN_SERVER_STEP, function(step)
        self:OnLoginServerStep(step)
    end)
    self:WndEventRecv(EventNames.LOGIN_BACK_LOGIN, function(...)
        self:OnBackLogin(...)
    end)
    self:WndEventRecv(EventNames.LOGIN_SERVERLIST_OK, function(...)
        self:UpdateServer(false)
    end)

    self:WndEventRecv(EventNames.LOGIN_SERVERLISTSTATE_OK, function(...)
        self:UpdateCurrentServerUI()
    end)

    self:WndEventRecv(EventNames.SDK_LOGIN_OK, function(...)
        self:OnSdkLoginOk(...)
    end)

    self:WndEventRecv(EventNames.SDK_LOGIN_FAILURE, function(...)
        self:OnSdkLoginFailure()
    end)

    self:WndEventRecv(EventNames.SDK_LOGAN_UPLOAD_RESULT, function(...)
        self._lastUploadTime = nil
    end)

    self:WndEventRecv(EventNames.LOGIN_SERVERLIST_PLAY_OK, function(...)
        self._isSelHasMaxPlayerLv = false
        if self._isServerDataFromDefault then
            local myPlayerServerList = gLGameLogin:GetMyPlayerServerList()
            if myPlayerServerList and #myPlayerServerList > 0 then
                local maxPlayerLv,playerLevel
                local playerLvMap = {}
                for i,v in ipairs(myPlayerServerList) do
                    playerLevel = v.playerLevel
                    if not maxPlayerLv or maxPlayerLv < playerLevel then
                        maxPlayerLv = playerLevel
                    end
                    local playerLvList = playerLvMap[playerLevel]
                    if not playerLvList then
                        playerLvList = {}
                        playerLvMap[playerLevel] = playerLvList
                    end
                    table.insert(playerLvList,v)
                end
                local playerLvList = maxPlayerLv and playerLvMap[maxPlayerLv]
                if playerLvList and #playerLvList > 0 then
                    self._isSelHasMaxPlayerLv = true
                    table.sort(playerLvList,function(a,b) return a.id > b.id end)
                    self._curServer = playerLvList[1]
                    self:UpdateCurrentServerUI()
                end
            end
        end

        if self._isForbidNewSelServer then
            self:CheckServerBtnShow()
        end

        if self._isJaRegion then
            self:CheckNeedAutoLogin()
        end
        if self._curServer then
            if gLSdkImpl and gLSdkImpl:CallMethod(LSdkMethod.IsLogin) then
                if gLSdkImpl:CallMethod(LSdkMethod.CheckIsFeedScene) then
                    self:ClickEnterGame()
                end
            end
        end
    end)

    self:WndEventRecv(EventNames.ON_WND_CLOSE, function(...)
        self:OnTargetWndClose(...)
    end)

    self:SetWndClick(self.mStartGameBtn, function(...)
        self:ClickEnterGame()
    end, LSoundConst.CLICK_LOGIN)

    self:SetWndClick(self.mStartGameArrow, function(...)
        self:ClickEnterGame()
    end, LSoundConst.CLICK_LOGIN)

    self:SetWndClick(self.mServerBtnObj, function(...)
        self:OnShowServerList()
    end)

    self:SetWndClick(self.mAgreeBtn, function(...)
        self._isAgree = not self._isAgree
        CS.ShowObject(self.mGouImg, self._isAgree)
    end)

    self:SetWndClick(self.mNoticeBtn, function(...)
        self:ShowNotice()
    end)

    self:SetWndClick(self.mRepairBtn, function(...)
        self:ShowRepairRes()
    end)

    self:SetWndClick(self.mCustomerServiceBtn, function()
        self:OnClickCustomerService()
    end)

    self:SetWndClick(self.mHmtAccountBtn, function()
        if not gLSdkImpl:CallMethod(LSdkMethod.IsLogin) then
            gLSdkImpl:CallMethod(LSdkMethod.Login)
            return
        end
        if gLSdkImpl:CallMethod(LSdkMethod.IsShowLogoutButton) then
            gLSdkImpl:CallMethod(LSdkMethod.Logout)
            return
        end
        gLSdkImpl:CallMethod(LSdkMethod.ShowUserCenter)
    end)

    self:SetWndClick(self.mHmtFBBtn, function()
        if gLGameLanguage:IsHmtRegion() then
            if self._hmtFbBtnRegPoint then
                CS.ShowObject(self._hmtFbBtnRegPoint, false)
                LPlayerPrefs.SetLoginFBRed("1")
            end
            local url = "https://www.facebook.com/profile.php?id=61559484607788"

            if self._isAmerica then
                url = gModelNormalActivity:GetBIActivityConfigRefByKey("facebookLink")
            end

            if not string.isempty(url) then
                CS.UApplication.OpenURL(url)
            end
        end
    end)

    self:SetWndClick(self.mJaAgreeBtn, function()
        if not self._isJaRegion then
            return
        end
        GF.OpenWnd("UIHelpListJa")
    end)

    self:SetWndClick(self.mHmtDisCardBtn, function()
        if self._isAmerica then
            local url = gModelNormalActivity:GetBIActivityConfigRefByKey("discordLink")
            if string.isempty(url) then
                return
            end
            CS.UApplication.OpenURL(url)
        end
    end)

    self:SetWndClick(self.mMuteMusicBtn, function(...)
        --self:ChangeMuteLoginMusic()
    end)

    self._versionBtnClickCnt = 0
    self:SetWndClick(self.mVersionBtn, function(...)
        self._versionBtnClickCnt = self._versionBtnClickCnt + 1
        if self._versionBtnClickCnt == 5 then
            self._versionBtnClickCnt = 0
            -- 显示版本信息
            self:SetXUITextText(self.mVersion,gLxServerList:GetVersionPID())
        else
            -- 显示版本信息
            self:SetXUITextText(self.mVersion,gLxServerList:GetVersionStr())
        end
    end)

    self:SetWndClick(self.mAccountSwitchesBtn, function()
        self:OnClickAccountSwitches()
    end)

    self:SetWndClick(self.mBtnCustomer,function()
        if LGameCommon.ShowCustomerBtnRegion() then
            local customerLink = LGameCommon.GetCustomerLink()
            if not string.isempty(customerLink) then
                CS.UApplication.OpenURL(customerLink)
                return
            end
        end
        gLSdkImpl:CallMethod(LSdkMethod.OpenCustomerService)
    end)

    self:WndEventRecv(EventNames.SDK_UNREADMSG_RESULT,function() self:SetUnreadMsgRP() end)
end

function UILon:UpdateAccountBtnName()
    ---是否显示注销按钮状态
    if not gLSdkImpl:CallMethod(LSdkMethod.IsShowLogoutButton) then
        return
    end

    if gLSdkImpl:CallMethod(LSdkMethod.IsLogin) then
        self:SetXUITextText(self.mHtmAccountBtnName, ccClientText(168))
    else
        self:SetXUITextText(self.mHtmAccountBtnName, ccClientText(160))
    end
end

function UILon:OnClickAccountSwitches()
    gLSdkImpl:CallMethod(LSdkMethod.Login)
end

function UILon:RefreshMuteState()
    local bMute = toboolean(LPlayerPrefs.muteLoginMusic)
    if bMute then
        self:SetWndEasyImage(self.mMuteMusicImage, "public_btn_icon_25_1")
        self:SetWndText(self.mMuteMusicBtnName, ccClientText(143))
    else
        self:SetWndEasyImage(self.mMuteMusicImage, "public_btn_icon_25_2")
        self:SetWndText(self.mMuteMusicBtnName, ccClientText(144))
    end
end

function UILon:PlayVideo()
    local loginVideo = GameTable.GameServerConfigRef.loginVideo
    local hasVideo = not string.isempty(loginVideo)
    if not hasVideo then
        CS.ShowObject(self.mVideoBg,false)
        return
    end

    CS.ShowObject(self.mVideoBg,true)
    gLGameVideo:PlayVideoClipUI(loginVideo,function()
        CS.ShowObject(self.mVideoBg,false)
    end,self.mVideoBg)
end

--健康提示，资质信息显示文本
function UILon:GetGameDescStr()
    local gameHeathTips = ccClientText(107)

    if gLGameLanguage:IsOtherLngRegion() then
        return ""
    end

    local appName = LNativeHelper.GetAppName()

    local ref
    for k, v in pairs(GameTable.SdkInfoQualifications) do
        if v.name == appName then
            ref = v
            break
        end
    end

    local chubanStr = ""
    local zhuzuoStr = ""
    local wangwen1Str = ""
    local wangwen2Str = ""
    local wenwangyoubeiziStr = ""
    local isbnStr = ""

    if ref then
        local copyright = ref.copyright or ""
        local arrCopyRight = string.split(copyright, "=")
        if arrCopyRight then
            chubanStr = arrCopyRight[1] or ""
            zhuzuoStr = arrCopyRight[2] or ""
        end

        local webNum = ref.webNum or ""
        local arrWebNum = string.split(webNum, "=")
        if arrWebNum then
            wangwen1Str = arrWebNum[1] or ""
            wangwen2Str = arrWebNum[2] or ""
        end

        local webWord = ref.webWord or ""
        local arrWebWord = string.split(webWord, "=")
        if arrWebWord then
            wenwangyoubeiziStr = arrWebWord[1] or ""
            isbnStr = arrWebWord[2] or ""
        end
    else
        if gLGameLanguage:IsChinaRegion() and CS.IsWebGL() and LWxHelper.IsMiniGamePlatform() then
            gameHeathTips = ""
            local useOther = false
            if CS.IsWebGL() and LWxHelper.IsWxPlatform() then
                local packageId = gLSdkImpl:CallMethod(LSdkMethod.GetSdkPackageId) or "0"
                packageId = checknumber(packageId)
                if packageId == 505 then
                    useOther = true
                    isbnStr = GameTable.SdkInfoConfigRef.SDKDefaultIWXmj or ""
                end
            end
            if not useOther then
                isbnStr = GameTable.SdkInfoConfigRef.SDKDefaultIWX or ""
            end
        else
            isbnStr = GameTable.SdkInfoConfigRef.SDKDefaultISBN or ""
        end
    end

    local descStr = {}

    if not string.isempty(wenwangyoubeiziStr) then
        table.insert(descStr, wenwangyoubeiziStr)
        table.insert(descStr, " ")
    end

    if not string.isempty(isbnStr) then
        table.insert(descStr, isbnStr)
    end

    local line2Str = table.concat(descStr, "")

    descStr = {}
    if not string.isempty(wangwen1Str) then
        table.insert(descStr, wangwen1Str)
        table.insert(descStr, " ")
    end

    if not string.isempty(wangwen2Str) then
        table.insert(descStr, wangwen2Str)
        table.insert(descStr, " ")
    end

    local line3Str = table.concat(descStr, "")

    descStr = {}
    if not string.isempty(zhuzuoStr) then
        table.insert(descStr, zhuzuoStr)
        table.insert(descStr, " ")
    end

    if not string.isempty(chubanStr) then
        table.insert(descStr, chubanStr)
    end

    local line4Str = table.concat(descStr, "")
    descStr = { gameHeathTips, line2Str, line3Str, line4Str }

    local realStrTbl = {}
    for k, v in ipairs(descStr) do
        if not string.isempty(v) then
            table.insert(realStrTbl, v)
        end
    end
    return table.concat(realStrTbl, "\n")
end

function UILon:StopDelayGuestStartGame()
    if self._delayGuestStartTimer then
        LxTimer.DelayTimeStop(self._delayGuestStartTimer)
        self._delayGuestStartTimer = nil
    end
end

function UILon:UpdateStartText(str)
    if self.mStartInfo then
        self:SetXUITextText(self.mStartInfo, str or "")
    end
end

function UILon:UIDragOnEnd(dragKey, eventData)
    if dragKey == "_startGameArrowRight" then
        if self._isGameArrowRightMoving then
            self._isGameArrowRightMoving = false
            self:ClickEnterGame()
        end
    elseif dragKey == "_startGameArrowLeft" then
        if self._isGameArrowLeftMoving then
            self._isGameArrowLeftMoving = false
            self:ClickEnterGame()
        end
    elseif dragKey == "_startGameArrow" then
        if self._isGameArrowLeftMoving and self._isGameArrowRightMoving then
            self._isGameArrowLeftMoving = false
            self._isGameArrowRightMoving = false
            self:ClickEnterGame()
        end
    end
end

function UILon:StopWaitPlatformOk()
    if self._delaySdkTimer then
        LxTimer.DelayTimeStop(self._delaySdkTimer)
        self._delaySdkTimer = nil
    end
    GF.StopWait()
end
-------------------------------------------------------------------
return UILon