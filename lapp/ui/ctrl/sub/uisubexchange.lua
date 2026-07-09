---
--- Created by Administrator.
--- DateTime: 2023/9/17 14:47:31
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubExchange:LChildWnd
local UISubExchange = LxWndClass("UISubExchange", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubExchange:UISubExchange()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubExchange:OnWndClose()
    self:Clear()

    LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubExchange:OnCreate()
    LChildWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubExchange:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()

    self._regionDiff = gLGameLanguage:IsAmericaRegion()
    self._isVie = gLGameLanguage:IsVieVersion()
    self:SetPara()


    local isChina = gLGameLanguage:IsChinaRegion()
    self._isChina = isChina

    -- 手机绑定
    -- --不展示奖励且无奖励的渠道：oppo、vivo、华为、小米、荣耀、B站、微小（作废）
    -- --不展示奖励的渠道：oppo、vivo、华为、小米、荣耀、B站、微小（2025.11.20更新）
    -- --除了上面提到的硬核渠道，其他渠道均展示奖励
    -- --有奖励展示的渠道，如果绑定信息返回已绑定过，玩家可直接领取奖励
    local showReward = true
    local authType = self._authType
    if isChina and authType and authType == ModelPlayer.AUTH_ACCOUNT_BIND then
        if CS.IsWebGL() and LWxHelper.IsMiniGamePlatform() then
            showReward = false
        else
            local sdkPlatform = gLSdkImpl and gLSdkImpl:CallMethod(LSdkMethod.GetSdkPlatform)
            if not string.isempty(sdkPlatform) then
                if sdkPlatform == "OPPO_CN" or sdkPlatform == "VIVO_CN" or
                        sdkPlatform == "HUAWEI_CN" or sdkPlatform == "XIAOMI_CN" or
                        sdkPlatform == "BILIBILI_CN" or sdkPlatform == "HONOR_CN" then
                    showReward = false
                end
            end
        end
    end
    self._showReward = showReward

    self:WndNetMsgRecv(LProtoIds.AuthOnetimeStateResp, function()
        self:RefreshBtn_1()
    end)

    self:WndEventRecv(EventNames.SDK_ACCOUNTBIND_RESULT, function(isOk)
        if self._isChina and isOk then
            local hasReward = true
            local reward = hasReward and 0 or 1
            gModelPlayer:OnAuthOnetimeStateReq(1,reward)
            --FireEvent(EventNames.ON_ACTIVITY_SHOW_END)
            self:WndClose()
            return
        end
        self:RefreshBtn_1()
    end)

    self:RefreshUI()
end

function UISubExchange:RefreshUI()
    local authType = self._authType

    local cfg = gModelActivity:GetVerifyConfig(authType)
    if not cfg then return end

    local desc = ccLngText(cfg.description)
    self:SetTextTile(self.mTitle, desc)

    local func = nil
    if authType == ModelPlayer.AUTH_ACCOUNT_BIND then
        self:RefreshBtn_1()
        func = function()
            self:OnClickButton_1()
        end
    end

    self:SetWndEasyImage(self.mBg, cfg.bg, function()
        CS.ShowObject(self.mBg, true)
    end)
    self:SetWndEasyImage(self.mFigure, cfg.bg1, function()
        CS.ShowObject(self.mFigure, true)
    end)
    self:SetWndEasyImage(self.mFigure_text, cfg.textResource, function()
        CS.ShowObject(self.mFigure_text, true)

        if self._isVie then
            self:SetAnchorPos(self.mFigure_text, Vector2.New(-90, -41))
        end
    end, true)

    local showReward = self._showReward
    if showReward then
        local items = LxDataHelper.ParseItem(cfg.reward)
        local uiIconEasyList = self._iconList
        if not uiIconEasyList then
            uiIconEasyList = UIIconEasyList:New()
            self._iconList = uiIconEasyList
            uiIconEasyList:Create(self, self.mItemList)
            uiIconEasyList:SetShowNum(false)
            uiIconEasyList:SetShowExtraNum(true, "itemNum")
        end
        uiIconEasyList:RefreshList(items)
    else
        CS.ShowObject(self.mTitle,false)
        if self._isChina then
            self:SetWndText(self.mTitle_2_Enus, ccClientText(47612))
        end
    end

    CS.ShowObject(self.mBtnButton, true)
    self:SetWndClick(self.mBtnButton, func, LSoundConst.CLICK_BUTTON_COMMON)

    --enus
    if self._regionDiff then
        self:RefreshEnus()
    end
end

function UISubExchange:SetPara()
    self._authType = self:GetWndArg("authType")
end

function UISubExchange:RefreshBindRewardEnus()
    GF.OpenWndTop("UIVerifyPopUp")

end

function UISubExchange:Clear()
    if self._iconList then
        self._iconList:Destroy()
        self._iconList = nil
    end
end

function UISubExchange:OnClickButton_Chine()
    local isBind = gModelActivity:IsAccountBindTarget("bindMobile")
    if isBind then
        --- 已绑定，但是没有领奖励
        FireEvent(EventNames.SDK_ACCOUNTBIND_RESULT,true)
        return
    end
    if CS.IsWebGL() and LWxHelper.IsMiniGamePlatform() then
        GF.OpenWnd("UIPhoneBinding")
    else
        gLSdkImpl:CallMethod(LSdkMethod.BindMobile)
    end
end

function UISubExchange:RefreshEnus()
    CS.ShowObject(self.mItemList, false)
    CS.ShowObject(self.mDiv_Enus, true)

    self:SetWndText(self.mTitle_2_Enus, ccClientText(15069))

    if CS.IsOSIos() then
        --ios 要显示四个
        CS.ShowObject(self.mBind_apple, true)
    else
        CS.ShowObject(self.mBind_apple, false)
    end

    local isUseConfigPackType, result = gLGameLanguage:CheckIsUseConfigControlBindAccount()
    if isUseConfigPackType then
        CS.ShowObject(self.mBind_email, false)
        CS.ShowObject(self.mBind_facebook, false)
        CS.ShowObject(self.mBind_discord, false)
        CS.ShowObject(self.mBind_apple, false)
        for k, v in ipairs(result) do
            if v == 2 then
                CS.ShowObject(self.mBind_email, true)
            elseif v == 3 then
                CS.ShowObject(self.mBind_facebook, true)
            elseif v == 4 then
                CS.ShowObject(self.mBind_discord, true)
            elseif v == 5 then
                CS.ShowObject(self.mBind_apple, true)
            end
        end
    end

    if gLGameLanguage:CheckIsCanGoogleBindAccount() then
        CS.ShowObject(self.mBind_discord, true)
    else
        CS.ShowObject(self.mBind_discord, false)
    end
end

function UISubExchange:OnClickButton_Normal()
    if self._regionDiff then
        self:RefreshBindRewardEnus()
        return
    end

    local isAccountBind = gModelActivity:IsAccountBind()
    if not isAccountBind then
        gLSdkImpl:CallMethod(LSdkMethod.ShowUserCenter)
        return
    end
    local isRewarded = gModelPlayer:InAccoutBindingReward()
    if not isRewarded then
        gModelPlayer:OnAuthOnetimeStateReq(1)
    else
        GF.ShowMessage(ccClientText(11209))
    end
end

function UISubExchange:OnClickButton_1()
    if self._isChina then
        self:OnClickButton_Chine()
    else
        self:OnClickButton_Normal()
    end
end

function UISubExchange:RefreshBtn_1()
    local isAccountBind = gModelActivity:IsAccountBind()
    local str = ccClientText(15066) --"賬號綁定"
    if self._isChina then
        local isBind = gModelActivity:IsAccountBindTarget("bindMobile")
        if isBind then
            str = ccClientText(15064)
        else
            str = ccClientText(47611)
        end
    else
        if isAccountBind and not self._regionDiff then
            local isRewarded = gModelPlayer:InAccoutBindingReward()
            if isRewarded then
                str = ccClientText(15618) --"已领取"
            else
                str = ccClientText(15064) --"領取獎勵"
            end
        end
    end
    self:SetWndButtonText(self.mBtnButton, str)
end

------------------------------------------------------------------
return UISubExchange


