---
--- Created by Administrator.
--- DateTime: 2024/6/24 17:04:12
---
------------------------------------------------------------------
local LWnd = LWnd
local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder
---@class UIAreaSetting:LWnd
local UIAreaSetting = LxWndClass("UIAreaSetting", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIAreaSetting:UIAreaSetting()
    self.toggleValue = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIAreaSetting:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIAreaSetting:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIAreaSetting:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    self._isVie = gLGameLanguage:IsVieVersion()

    self:InitEvent()
    self:InitMessage()
    self:InitCommand()

    self:RefreshForeign()
end

function UIAreaSetting:InitNotifySetting()
    local hideToggleCnt = 0

    --挂机奖励
    -- self:SetWndToggleValue(self.mToggle5,toboolean(LPlayerPrefs.notifyIdleReward))
    -- self:SetWndToggleDelegate(self.mToggle5,function (value)
    -- 	LPlayerPrefs.SetNotifyIdleReward(value)
    -- 	LxAlarmHelper.SetInstanceNotify(value)
    -- end)
    self:SetToggleValue(self.mToggle5, toboolean(LPlayerPrefs.notifyIdleReward))
    self:SetWndClick(self.mToggle5, function()
        self:SetToggleValue(self.mToggle5, not self.toggleValue[self.mToggle5.gameObject.name])
        LxAlarmHelper:SetInstanceNotify(self.toggleValue[self.mToggle5.gameObject.name])
    end)

    --公会战
    -- self:SetWndToggleValue(self.mToggle6,toboolean(LPlayerPrefs.notifyGuildBattle))
    -- self:SetWndToggleDelegate(self.mToggle6,function (value)
    -- 	LPlayerPrefs.SetNotifyGuildBattle(value)
    -- 	LxAlarmHelper.SetGuildBattleNotify(value)
    -- end)
    self:SetToggleValue(self.mToggle6, toboolean(LPlayerPrefs.notifyGuildBattle))
    self:SetWndClick(self.mToggle6, function()
        self:SetToggleValue(self.mToggle6, not self.toggleValue[self.mToggle6.gameObject.name])
        LPlayerPrefs.SetNotifyGuildBattle(self.toggleValue[self.mToggle6.gameObject.name])
        LxAlarmHelper.SetGuildBattleNotify(self.toggleValue[self.mToggle6.gameObject.name])
    end)
    CS.ShowObject(self.mToggle6, false)
    hideToggleCnt = hideToggleCnt + 1

    --公会boss
    -- self:SetWndToggleValue(self.mToggle7,toboolean(LPlayerPrefs.notifyGuildBoss))
    -- self:SetWndToggleDelegate(self.mToggle7,function (value)
    -- 	LPlayerPrefs.SetNotifyGuildBoss(value)
    -- 	LxAlarmHelper.SetGuildBossNotify(value)
    -- end)
    self:SetToggleValue(self.mToggle7, toboolean(LPlayerPrefs.notifyGuildBoss))
    self:SetWndClick(self.mToggle7, function()
        self:SetToggleValue(self.mToggle7, not self.toggleValue[self.mToggle7.gameObject.name])
        LPlayerPrefs.SetNotifyGuildBoss(self.toggleValue[self.mToggle7.gameObject.name])
        LxAlarmHelper.SetGuildBossNotify(self.toggleValue[self.mToggle7.gameObject.name])
    end)

    CS.ShowObject(self.mToggle7, false)


    --巅峰对决
    -- self:SetWndToggleValue(self.mToggle8,toboolean(LPlayerPrefs.notifyArenaPeak))
    -- self:SetWndToggleDelegate(self.mToggle8,function (value)
    -- 	LPlayerPrefs.SetNotifyArenaPeak(value)
    -- 	LxAlarmHelper.SetPeakArenaNotify(value)
    -- end)
    self:SetToggleValue(self.mToggle8, toboolean(LPlayerPrefs.notifyArenaPeak))
    self:SetWndClick(self.mToggle8, function()
        self:SetToggleValue(self.mToggle8, not self.toggleValue[self.mToggle8.gameObject.name])
        LPlayerPrefs.SetNotifyArenaPeak(self.toggleValue[self.mToggle8.gameObject.name])
        LxAlarmHelper.SetPeakArenaNotify(self.toggleValue[self.mToggle8.gameObject.name])
    end)


    ----梦境魔泉
    --self:SetWndToggleValue(self.mToggle9,toboolean(LPlayerPrefs.notifyDreamFountain))
    --self:SetWndToggleDelegate(self.mToggle9,function (value)
    --	LPlayerPrefs.SetNotifyDreamFountain(value)
    --	LxAlarmHelper.SetPeakDreamFountain(value)
    --end)
    --
    CS.ShowObject(self.mToggle9, false)

    self:SetWndClick(self.mNotifyHelp, function()
        GF.OpenWnd("UIBzTips", { refId = 23 })
    end, LSoundConst.CLICK_ERROR_COMMON)

    self._notifyMinusHeight = 0
    if hideToggleCnt >= 2 then
        local col = math.floor(hideToggleCnt / 2)
        self._notifyMinusHeight = col * 60
    end
end

function UIAreaSetting:ClickGiftBtn()
    if not self._isClick then
        self._isClick = true
        local giftCard = self.mGiftCodeText.text
        gModelActivity:OnUseGiftCardReq(giftCard)
        self:TimerStart("countDownKey", 5, false, -1)
    else
        GF.ShowMessage(ccClientText(14008))
    end
end

function UIAreaSetting:InitDisplaySetting()
    local quality = gLGameQuality:GetQualityLv()
    local bHeight = quality == LGameQuality.QUALITY_LV_NORMAL

    local hideToggleCnt = 0
    local totalToggle = 5

    --画质
    -- self:SetWndToggleValue(self.mToggle1,bHeight)
    -- self:SetWndToggleDelegate(self.mToggle1,function (value)
    -- 	if value then
    -- 		gLGameQuality:SetQualityLv(LGameQuality.QUALITY_LV_NORMAL)
    -- 	else
    -- 		gLGameQuality:SetQualityLv(LGameQuality.QUALITY_LV_LOW)
    -- 	end
    -- end)
    self:SetToggleValue(self.mToggle1, bHeight)
    self:SetWndClick(self.mToggle1, function()
        self:SetToggleValue(self.mToggle1, not self.toggleValue[self.mToggle1.gameObject.name])
        if self.toggleValue[self.mToggle1.gameObject.name] then
            gLGameQuality:SetQualityLv(LGameQuality.QUALITY_LV_NORMAL)
        else
            gLGameQuality:SetQualityLv(LGameQuality.QUALITY_LV_LOW)
        end
    end)

    --生命槽
    -- self:SetWndToggleValue(self.mToggle2,toboolean(LPlayerPrefs.gameHpBar))
    -- self:SetWndToggleDelegate(self.mToggle2,function (value)
    -- 	LPlayerPrefs.SetGameHpBar(value)
    -- end)
    self:SetToggleValue(self.mToggle2, toboolean(LPlayerPrefs.gameHpBar))
    self:SetWndClick(self.mToggle2, function()
        self:SetToggleValue(self.mToggle2, not self.toggleValue[self.mToggle2.gameObject.name])
        LPlayerPrefs.SetGameHpBar(self.toggleValue[self.mToggle2.gameObject.name])
    end)
    CS.ShowObject(self.mToggle2, false)
    hideToggleCnt = hideToggleCnt + 1

    --战斗文本
    -- self:SetWndToggleValue(self.mToggle3,toboolean(LPlayerPrefs.gameBtIdleShowText))
    -- self:SetWndToggleDelegate(self.mToggle3,function (value)
    -- 	LPlayerPrefs.SetGameBtIdleShowText(value)
    -- end)
    self:SetToggleValue(self.mToggle3, toboolean(LPlayerPrefs.gameBtIdleShowText))
    self:SetWndClick(self.mToggle3, function()
        self:SetToggleValue(self.mToggle3, not self.toggleValue[self.mToggle3.gameObject.name])
        LPlayerPrefs.SetGameBtIdleShowText(self.toggleValue[self.mToggle3.gameObject.name])
    end)
    CS.ShowObject(self.mToggle3, false)
    hideToggleCnt = hideToggleCnt + 1

    --公频红点
    -- self:SetWndToggleValue(self.mToggle4,toboolean(LPlayerPrefs.chatCommonRed))
    -- self:SetWndToggleDelegate(self.mToggle4,function (value)
    -- 	LPlayerPrefs.SetChatCommonRed(value)
    -- end)
    self:SetToggleValue(self.mToggle4, toboolean(LPlayerPrefs.chatCommonRed))
    self:SetWndClick(self.mToggle4, function()
        self:SetToggleValue(self.mToggle4, not self.toggleValue[self.mToggle4.gameObject.name])
        LPlayerPrefs.SetChatCommonRed(self.toggleValue[self.mToggle4.gameObject.name])
    end)
    CS.ShowObject(self.mToggle4, false)
    hideToggleCnt = hideToggleCnt + 1

    --省电模式
    -- self:SetWndToggleValue(self.mToggle101,(tonumber(LPlayerPrefs.highFrameRate) or 0) ~= 1)
    -- self:SetWndToggleDelegate(self.mToggle101,function (value)
    -- 	gLGameQuality:SetHighFrameRate(not value)
    -- end)
    self:SetToggleValue(self.mToggle101, (tonumber(LPlayerPrefs.highFrameRate) or 0) ~= 1)
    self:SetWndClick(self.mToggle101, function()
        self:SetToggleValue(self.mToggle101, not self.toggleValue[self.mToggle101.gameObject.name])
        gLGameQuality:SetHighFrameRate(not self.toggleValue[self.mToggle101.gameObject.name])
    end)

    self:SetWndClick(self.mDisplayHelp, function()
        GF.OpenWnd("UIBzTips", { refId = 22 })
    end, LSoundConst.CLICK_ERROR_COMMON)

    self._displayMinusHeight = math.ceil(totalToggle / 2) * 60
    local showDisplayToggle = totalToggle - hideToggleCnt
    if showDisplayToggle > 0 then
        local col = math.ceil(showDisplayToggle / 2)
        self._displayMinusHeight = self._displayMinusHeight - col * 60
    end
end

function UIAreaSetting:OnTimer(key)
    if key == "countDownKey" then
        self._isClick = false
    end
end

function UIAreaSetting:OnChangeAccount()
    gLSdkImpl:DoChangeAccount()
end

function UIAreaSetting:InitServiceSetting()
    CS.ShowObject(self.mScServiceObj, gModelNormalActivity:CheckShowCustomerBtn())
    self:SetRed(self.mBtnService,gLSdkImpl:CallMethod(LSdkMethod.GetUnreadMsgRP))

    self:SetWndClick(self.mBtnService, function()
        if LGameCommon.ShowCustomerBtnRegion() then
            local customerLink = LGameCommon.GetCustomerLink()
            if not string.isempty(customerLink) then
                CS.UApplication.OpenURL(customerLink)
                return
            end
        end
        gLSdkImpl:CallMethod(LSdkMethod.OpenCustomerService)
    end)

    local showid, showIdPrex = self:GetShowIdForCopy()
    self:SetWndText(self.mGUIDUIText, showIdPrex .. showid)

    self:SetWndClick(self.mBtnCopyGUID, function()
        self:OnCopyGuid()
    end)

    self:SetWndClick(self.mBtnExitGame, function()
        self:OnExitGame()
    end)

    self:SetWndClick(self.mBtnLangGame, function()
        self:OnChangeLanguage()
    end)

    self:SetWndClick(self.mBtnOtherAudio, function()
        self:OnSwitchOtherAudio()
    end)

    self:SetWndClick(self.mBtnOtherAudio)

    self:SetWndClick(self.mBtnPrivacy, function()
        gLSdkImpl:CallMethod(LSdkMethod.OpenPrivacyPolicy)
    end)

    self:SetWndClick(self.mBtnGM, function()
        if GF.FindFirstWndByName("UIGMand") then
            GF.CloseWndByName("UIGMand")
        else
            GF.OpenWndDebug("UIGMand")
        end
    end)

    self:SetWndClick(self.mBtnGiftCode, function()
        GF.OpenWnd("WndGiftCode")
    end)

    self:SetWndClick(self.mBtnUserCenter, function()
        gLSdkImpl:CallMethod(LSdkMethod.ShowUserCenter)
    end)

    self:SetWndClick(self.mBtnCancelAccount, function()
        gLSdkImpl:CallMethod(LSdkMethod.ShowCancellationAccount)
    end)

    self:SetWndClick(self.mBtnLogUpload, function()
        if self._lastUploadTime and self._lastUploadTime > Time.RawUnityEngineTime.realtimeSinceStartup then
            GF.ShowMessage(ccClientText(120))
            return
        end
        self._lastUploadTime = Time.RawUnityEngineTime.realtimeSinceStartup + 10
        gLSdkImpl:CallMethod(LSdkMethod.LoganUpload)
    end)

    --【G公共支持】删除一批海外关联参数及功能
    --self:SetWndClick(self.mBtnFacebook, function()
    --	local url = gModelPlayer:GetRoleConfigRefByKey("FacebookLink")
    --	if string.isempty(url) then return end
    --	CS.UApplication.OpenURL(url)
    --end)
    if CS.IsOSIos() then
        CS.ShowObject(self.mScExitGameObj, false)
    else
        CS.ShowObject(self.mScExitGameObj, true)
    end

    local languageList = gLGameLanguage:GetShowLanguageList()

    CS.ShowObject(self.mScUserCenterObj, gLSdkImpl:CallMethod(LSdkMethod.IsShowUserCenterButton))

    CS.ShowObject(self.mScPrivacyObj, gLGameLogin:IsOpenPrivacy())
    if gLGameLanguage:IsChinaRegion() and CS.IsWebGL() and LWxHelper.IsMiniGamePlatform() then
        if PRODUCT_G_VER ~= 0 then
            CS.ShowObject(self.mScPrivacyObj,false)
        end
    end

    CS.ShowObject(self.mScCopyGUIDObj, gLGameLogin:IsOpenCopyUuid())

    if CS.IsWebGL()  then
        if gLGameLanguage:IsJapanRegion()  then
            --CS.ShowObject(self.mScCopyGUIDObj, false)
        end
    end

    CS.ShowObject(self.mScLangGameObj, #languageList > 1)
    -- CS.ShowObject(self.mScGiftCodeObj, gLGameLogin:IsOpenGift())
    CS.ShowObject(self.mScGiftCodeObj, false)
    CS.ShowObject(self.mScGMObj, gModelGM:IsGMOpenInSettingWnd())
    CS.ShowObject(self.mScFaceBookObj, gLGameLogin:IsOpenFacebook())

    CS.ShowObject(self.mScOtherAudioObj, gModelFunctionOpen:CheckIsOpened(18006000, false))
    CS.ShowObject(self.mScLogUploadObj, LGameSettings.showLogUpload)

    if gLGameTable:IsSensitive() then
        CS.ShowObject(self.mScResSelObj, false) --资源版本
    else
        if gLGameLanguage:IsChinaRegion() then
            CS.ShowObject(self.mScResSelObj, false) --资源版本
        else
            CS.ShowObject(self.mScResSelObj, gLGameLogin:IsOpenHarmonious()) --资源版本
            self:SetWndClick(self.mBtnResSel, function()
                GF.OpenWnd("UISettingRes")
            end)
        end
    end

    if PRODUCT_G_VER and PRODUCT_G_VER > 0 then
        --提审隐藏
        CS.ShowObject(self.mScFaceBookObj, false) --facebook
        CS.ShowObject(self.mScGiftCodeObj, false) --礼包码
        CS.ShowObject(self.mScUserCenterObj, false)--账号中心
        CS.ShowObject(self.mScResSelObj, false) --资源版本
    end

    if gLGameLanguage:IsAmericaRegion() then
        --欧美地区账号中心一直要
        CS.ShowObject(self.mScUserCenterObj, true)--账号中心
    end
    if gLGameLanguage:IsJapanRegion() then
        CS.ShowObject(self.mScUserCenterObj, true)--账号中心
        CS.ShowObject(self.mScCancelAccountObj, true)--注销账号
        CS.ShowObject(self.mScExitGameObj, false)
        CS.ShowObject(self.mScPrivacyObj, false)
    end

    if PRODUCT_G_VER and PRODUCT_G_VER ~= 0 then
        CS.ShowObject(self.mScExitGameObj, false)
    end


    local activeCount = 0
    local childCount = self.mScGrid.childCount
    for i = 1, childCount do
        local trans = self.mScGrid:GetChild(i - 1)

        local activeSelf = trans.gameObject.activeSelf
        if activeSelf then
            activeCount = activeCount + 1
        end
    end
    local width = 596
    local height = 816
    if activeCount > 0 then
        if activeCount > 6 and activeCount < 9 then
            height = 900
        elseif activeCount > 9 then
            height = 960
        end
    end

    if gLGameLanguage:IsJapanVersion() then
        height = height + 20
    end
    if self.mScCopyGUIDObj.activeSelf then
        height = height + 20
    end

    self.mCommonBg_3.sizeDelta = Vector2.New(width, height)

end

function UIAreaSetting:GetShowIdForCopy()
    local id = ""
    local idprex = ""
    id = tostring(gModelPlayer:GetPlayerId())
    idprex = "id:"
    return id, idprex
end

function UIAreaSetting:OnChangeLanguage()
    GF.OpenWnd("UISetguage")
end

function UIAreaSetting:InitAudioSetting()
    local isForeign = gLGameLanguage:IsForeignVersion()
    self._rtMusic = self:UIProgressFind(self.mBarMusic, "barMusic", gLGameAudio:GetMusicVolume())
    local width = isForeign and 350 or 400
    self.mBarMusic.sizeDelta = Vector2(width, self.mBarMusic.rect.height)
    self._rtMusic:SetSliderDelegate(function(value)
        value = math.floor(value * 1000) / 1000
        gLGameAudio:SetMusicVolume(value)
    end)
    if not isForeign then
        local pos = self.mMusicToggle.anchoredPosition
        pos.x = -128
        self.mMusicToggle.anchoredPosition = pos

        local pos = self.mSoundToggle.anchoredPosition
        pos.x = -128
        self.mSoundToggle.anchoredPosition = pos
    end
    self:SetToggleValue(self.mMusicToggle, gLGameAudio:GetMusicVolume() ~= 0)
    self:SetWndClick(self.mMusicToggle, function()
        self:SetToggleValue(self.mMusicToggle, not self.toggleValue[self.mMusicToggle.gameObject.name])
        local is = self.toggleValue[self.mMusicToggle.gameObject.name]
        local value = is and 0.5 or 0
        -- gLGameAudio:SetMusicVolume(value)
        self._rtMusic:SetUIProgress(value)
    end)

    self._rtSound = self:UIProgressFind(self.mBarSound, "barSound", gLGameAudio:GetSoundVolume())
    self.mBarSound.sizeDelta = Vector2(width, self.mBarSound.rect.height)
    self._rtSound:SetSliderDelegate(function(value)
        value = math.floor(value * 1000) / 1000
        gLGameAudio:SetSoundVolume(value)
        gLGameAudio:SetSingleSoundVolume(value)
    end)
    self:SetToggleValue(self.mSoundToggle, gLGameAudio:GetSoundVolume() ~= 0)
    self:SetWndClick(self.mSoundToggle, function()
        self:SetToggleValue(self.mSoundToggle, not self.toggleValue[self.mSoundToggle.gameObject.name])
        local is = self.toggleValue[self.mSoundToggle.gameObject.name]
        local value = is and 0.5 or 0
        -- gLGameAudio:SetSoundVolume(value)
        -- gLGameAudio:SetSingleSoundVolume(value)
        self._rtSound:SetUIProgress(value)
    end)
end

function UIAreaSetting:InitMessage()
    if gLGameLanguage:IsForeignRegion() then
        --查询拥有的服务器列表
        gLGameLogin:Step_QueryUserPlayerInfoFromWeb()
    end
end

function UIAreaSetting:OnExitGame()
    gLSdkImpl:DoShowExitView()
end

function UIAreaSetting:InitCommand()
    CS.ShowObject(self.mContent, true)
    self._contentSize = self.mContent.sizeDelta
    self:SetXUITextText(self.mCurServeLabel, ccClientText(15001))
    self:SetXUITextText(self.mCurWorldLv, ccClientText(15025))
    self:SetWndText(self.mCurIp, ccClientText(15044))
    self:SetXUITextText(self.mAudioText, ccClientText(15002))
    self:SetXUITextText(self.mDisplayText, ccClientText(15003))
    self:SetXUITextText(self.mNotifyText, ccClientText(15004))
    self:SetXUITextText(self.mServiceText, ccClientText(15005))

    self:SetXUITextText(self.mMusicText, ccClientText(15011))
    self:SetXUITextText(self.mSoundText, ccClientText(15012))

    self:SetXUITextText(self.mScreenShareText, ccClientText(15040))
    self:SetWndButtonText(self.mGiftBtn, ccClientText(14007))
    self:SetWndText(CS.FindTrans(self.mGiftCodeText, "TextArea/Placeholder"), ccClientText(14012))

    if gLGameLanguage:IsForeignRegion() then
        --服务器列表选择界面，只有全球版sdk才会根据后台控制显示这个按钮
        self:SetWndButtonText(self.mBtnChangeAccount, ccClientText(15027))
    else
        self:SetWndButtonText(self.mBtnChangeAccount, ccClientText(15006))
    end

    self:SetWndButtonText(self.mBtnGiftCode, ccClientText(15038))
    self:SetWndButtonText(self.mBtnUserCenter, ccClientText(15028))
    self:SetWndButtonText(self.mBtnCancelAccount, ccClientText(36615))
    self:SetWndButtonText(self.mBtnPrivacy, ccClientText(15026))
    self:SetWndButtonText(self.mBtnService, ccClientText(15007))

    self:SetWndButtonText(self.mBtnCopyGUID, ccClientText(15009))
    self:SetWndButtonText(self.mBtnExitGame, ccClientText(15010))
    self:SetWndButtonText(self.mBtnLangGame, ccClientText(15022))
    self:SetWndButtonText(self.mBtnGM, "GM")
    self:SetWndButtonText(self.mBtnFacebook, "Facebook")
    self:SetWndButtonText(self.mBtnOtherAudio, ccClientText(15052))
    self:SetWndButtonText(self.mBtnLogUpload, ccClientText(15063))

    self:SetWndButtonText(self.mBtnResSel, ccClientText(15072))

    self:SetWndText(self:FindWndTrans(self.mToggle1, "UIText"), ccClientText(15013))
    self:SetWndText(self:FindWndTrans(self.mToggle2, "UIText"), ccClientText(15014))
    self:SetWndText(self:FindWndTrans(self.mToggle3, "UIText"), ccClientText(15015))
    self:SetWndText(self:FindWndTrans(self.mToggle4, "UIText"), ccClientText(15016))
    self:SetWndText(self:FindWndTrans(self.mToggle101, "UIText"), ccClientText(15024))
    self:SetWndText(self:FindWndTrans(self.mToggle5, "UIText"), ccClientText(15017))
    self:SetWndText(self:FindWndTrans(self.mToggle6, "UIText"), ccClientText(15018))
    self:SetWndText(self:FindWndTrans(self.mToggle7, "UIText"), ccClientText(15019))
    self:SetWndText(self:FindWndTrans(self.mToggle8, "UIText"), ccClientText(15020))
    self:SetWndText(self:FindWndTrans(self.mToggle9, "UIText"), ccClientText(15021))
    self:SetWndText(self:FindWndTrans(self.mScreenShareToggle, "UIText"), ccClientText(10146))
    for i = 1, 9 do
        local tran = self:FindWndTrans(self["mToggle" .. i], "UIText")
        LayoutRebuilder.ForceRebuildLayoutImmediate(tran)
    end
    local tran = self:FindWndTrans(self.mToggle101, "UIText")
    LayoutRebuilder.ForceRebuildLayoutImmediate(tran)

    self:SetWndText(self.mLblBiaoti, ccClientText(15065))

    --中文版不显示这个按钮在这里
    CS.ShowObject(self.mBtnChangeAccount, false)

    CS.ShowObject(self.mBtnReselServer, gLSdkImpl:CallMethod(LSdkMethod.IsForbidNewSelServer))

    local curServerName = gLGameLogin:GetServerName()
    self:SetXUITextText(self.mCurServerText, curServerName)
    local worldLv = gModelPlayer:GetWorldLevel()
    self:SetXUITextText(self.mCurWorldLvText, worldLv)
    local isForeignEn = gLGameLanguage:IsOtherLngRegion()
    local showIp = not isForeignEn
    if gLGameLanguage:IsChinaRegion() then
        showIp = false
    end
    CS.ShowObject(self.mIp, showIp)
    if showIp then
        local ipCountry, ipProvince = gModelPlayer:GetIpConfig()
        local ipStr = gModelPlayer:GetIpShowText(ipCountry, ipProvince)
        self:SetWndText(self.mIpText, ipStr)
    end

    if PRODUCT_G_VER and PRODUCT_G_VER > 0 then
        --提审隐藏礼包码
        CS.ShowObject(self.mGiftCodeText.gameObject, false)
        CS.ShowObject(self.mGiftBtn.gameObject, false)
        self.mScrollRect.offsetMax = Vector2(self.mScrollRect.offsetMax.x, -263)
    end

    self:InitAudioSetting()
    self:InitDisplaySetting()
    self:InitNotifySetting()
    self:InitServiceSetting()

    self:InitScreenShareSetting()

    self:UpdateContentSize()
end

function UIAreaSetting:OnCopyGuid()
    local str = self:GetShowIdForCopy()
    if string.isempty(str) then
        return
    end

    if LNativeHelper.CopyToClipboard(str) then
        if CS.IsOSAndroid() then
            LNativeHelper.ShowToast(str)
        else
            GF.ShowMessage(str)
        end
    end
end

function UIAreaSetting:InitEvent()
    self:WndEventRecv(EventNames.SDK_LOGAN_UPLOAD_RESULT, function(...)
        self._lastUploadTime = nil
    end)

    if gLSdkImpl:CallMethod(LSdkMethod.IsForbidNewSelServer) then
        self:SetWndClick(self.mBtnReselServer, function()
            ReLoginGame()
        end)
    end

    self:SetWndClick(self.mBtnChangeAccount, function()
        if gLGameLanguage:IsForeignRegion() then
            GF.OpenWnd("UISelSer", {
                callFunc = function(itemData)
                    if self:IsWndClosed() then
                        return
                    end
                    LPlayerPrefs.SetServerAccount("")
                    LPlayerPrefs.SetServerName(itemData.name)
                    LPlayerPrefs.SetServerId(itemData.id)
                    gLSdkImpl:CallMethod(LSdkMethod.DoResetRelogin)
                    ReLoginGame()
                end,
                curServer = gLGameLogin:GetLoginServer()
            })
        else
            --if gLGameLogin:IsOpenAccount() then
            --	self:OnChangeAccount()
            --end
        end
    end)
    self:SetWndClick(self.mWorldLvHelp, function()
        local worldLvNum = gModelPlayer:GetRoleConfigRefByKey("worldLvNum")
        GF.OpenWnd("UIBzTips", { refId = 3, para = { worldLvNum } })
    end, LSoundConst.CLICK_ERROR_COMMON)
    self:SetWndClick(self.mBtnClose, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mBg, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mGiftBtn, function()
        self:ClickGiftBtn()
    end)
end

function UIAreaSetting:UpdateContentSize()
    local minusHeight = 0
    if self._displayMinusHeight then
        minusHeight = self._displayMinusHeight + minusHeight
        if self._displayMinusHeight > 0 then
            local dpSizeDelta = self.mGameDisplay.sizeDelta
            self.mGameDisplay.sizeDelta = Vector2(dpSizeDelta.x, dpSizeDelta.y - self._displayMinusHeight)
        end
    end

    if self._notifyMinusHeight then
        minusHeight = self._notifyMinusHeight + minusHeight

        if self._notifyMinusHeight > 0 then
            local dpSizeDelta = self.mNotify.sizeDelta
            self.mNotify.sizeDelta = Vector2(dpSizeDelta.x, dpSizeDelta.y - self._notifyMinusHeight)
        end
    end

    --if minusHeight > 120 then
    --	self.mContent.sizeDelta = Vector2(self._contentSize.x, self._contentSize.y - minusHeight - 120)
    --end
end

function UIAreaSetting:OnSwitchOtherAudio()
    local nowAudioFlag = tonumber(gLGameLanguage:GetOtherAudioFlag()) or 0
    --1 是 日文配音 ，0 是中文配音
    local nowName = nowAudioFlag == 1 and ccClientText(15054) or ccClientText(15053)
    gModelGeneral:OpenUIOrdinTips({ refId = 120006, para = { nowName }, func = function()
        if nowAudioFlag == 0 then
            LPlayerPrefs.SetOtherAudioFlag("1")
            GF.ShowMessage(ccClientText(15055))
        end
    end, leftFunc = function()
        if nowAudioFlag == 1 then
            LPlayerPrefs.SetOtherAudioFlag("0")
            GF.ShowMessage(ccClientText(15055))
        end
    end })
end

function UIAreaSetting:RefreshForeign()
    if self._isVie then
        local typeGridLayoutGroup = typeof(CS.GridLayoutGroup)
        local layoutTran = CS.FindTrans(self.mNotify, "GameObject")
        local layout = layoutTran:GetComponent(typeGridLayoutGroup)
        layout.spacing = Vector2.New(130, 26.3)

        layoutTran = CS.FindTrans(self.mGameDisplay, "GameObject")
        layout = layoutTran:GetComponent(typeGridLayoutGroup)
        layout.spacing = Vector2.New(130, 26.3)
    end
end

function UIAreaSetting:SetToggleValue(tran, value)
    local On = self:FindWndTrans(tran, "Img/On")
    local Off = self:FindWndTrans(tran, "Img/Off")
    CS.ShowObject(On, value)
    CS.ShowObject(Off, not value)
    self.toggleValue[tran.gameObject.name] = value
end

function UIAreaSetting:InitScreenShareSetting()
    local isOpen = false

    if gLGameLogin:IsOpenScreenShotShare() and gLSdkImpl:CallMethod(LSdkMethod.IsSupportShareChannel, LShareConst.MADFUN_SYSTEM) then
        isOpen = gModelFunctionOpen:CheckIsOpened(18000020)
    end

    CS.ShowObject(self.mScreenShare, isOpen)

    if not isOpen then
        return
    end
    local isShare = toboolean(LPlayerPrefs.screenShare)
    if isShare and not LNativeHelper.CheckPermissionForObserverScreenShot() then
        isShare = false
    end
    self:SetToggleValue(self.mScreenShareToggle, isShare)
    self:SetWndClick(self.mScreenShareToggle, function()
        local value = not self.toggleValue[self.mScreenShareToggle.gameObject.name]
        self:SetToggleValue(self.mScreenShareToggle, value)
        if not isOpen then
            LPlayerPrefs.SetScreenShare(false)
            return
        end
        if not value then
            LPlayerPrefs.SetScreenShare(false)
            LNativeHelper.CallMethod(LNativeMethod.DoSysShotWatch, value)
            return
        end
        if (isOpen) then
            ---开启需要权限
            if not LNativeHelper.CheckPermissionForObserverScreenShot() then
                self:SetWndToggleValue(self.mScreenShareToggle, false)
                LNativeHelper.RequestPermissionForObserverScreenShot(ccClientText(19763), ccClientText(19788), ccClientText(19789))
                return
            end
        end
        LPlayerPrefs.SetScreenShare(true)
        LNativeHelper.CallMethod(LNativeMethod.DoSysShotWatch, value)
    end)
    -- self:SetWndToggleValue(self.mScreenShareToggle,isShare)
    -- self:SetWndToggleDelegate(self.mScreenShareToggle,function (value)
    -- 	if not isOpen then
    -- 		LPlayerPrefs.SetScreenShare(false)
    -- 		return
    -- 	end
    -- 	if not value then
    -- 		LPlayerPrefs.SetScreenShare(false)
    -- 		LNativeHelper.CallMethod(LNativeMethod.DoSysShotWatch,value)
    -- 		return
    -- 	end
    -- 	if(isOpen) then
    -- 		---开启需要权限
    -- 		if not LNativeHelper.CheckPermissionForObserverScreenShot() then
    -- 			self:SetWndToggleValue(self.mScreenShareToggle, false)
    -- 			LNativeHelper.RequestPermissionForObserverScreenShot(ccClientText(19763), ccClientText(19788), ccClientText(19789))
    -- 			return
    -- 		end
    -- 	end
    -- 	LPlayerPrefs.SetScreenShare(true)
    -- 	LNativeHelper.CallMethod(LNativeMethod.DoSysShotWatch,value)
    -- end)

    self:SetWndClick(self.mScreenShareHelp, function()
        GF.OpenWnd("UIBzTips", { refId = 96 })
    end)
end

------------------------------------------------------------------
return UIAreaSetting