---
--- Created by BY.
--- DateTime: 2023/10/4 20:04:53
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIUpLvhjgyPop:LWnd
local UIUpLvhjgyPop = LxWndClass("UIUpLvhjgyPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIUpLvhjgyPop:UIUpLvhjgyPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIUpLvhjgyPop:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIUpLvhjgyPop:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIUpLvhjgyPop:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    self._isVie =gLGameLanguage:IsVieVersion()

    self.jpj = gLGameLanguage:IsJapanVersion()
    self:InitData()
    self:InitUIEvent()
    self:InitEvent()
    self:SetStaticContent()
    self:InitIosShowUI()
    --self:RefreshUI()
    gModelNormalActivity:OnPrivilegeGiftReq()
    gModelInstance:OnPlayerInstanceReq()
end

function UIUpLvhjgyPop:InitUIEvent()
    self:SetWndClick(self.mBgImage, function(...)
        self:WndClose()
    end)
    self:SetWndClick(self.mBtnClose, function(...)
        self:WndClose()
    end)

    local btn = self:FindWndTrans(self.mPageMag1, "BtnPageGo")
    self:SetWndClick(btn, function()
        self:OnClickGo1()
    end)
    btn = self:FindWndTrans(self.mPageMag2, "BtnPageGo")
    self:SetWndClick(btn, function()
        self:OnClickGo2()
    end)

    btn = self:FindWndTrans(self.mPageMag1, "Page/BtnGo")
    self:SetWndClick(btn, function()
        self:GoToVip()
    end)

    btn = self:FindWndTrans(self.mPageMag2, "Page/BtnGo")
    self:SetWndClick(btn, function()
        self:GoToPrivi()
    end)

end

function UIUpLvhjgyPop:InitData()
    self._countDownKey = "_countDownKey"
end

function UIUpLvhjgyPop:InitEvent()
    self:WndNetMsgRecv(LProtoIds.PlayerInstanceResp, function()
        self:SetInstanceInfo()
    end)

    self:WndEventRecv(EventNames.PLAYER_VIP_LEVEL_CHANGE, function()
        self:SetVipInfo()
    end)

    self:WndNetMsgRecv(LProtoIds.PrivilegeGiftResp, function()
        self:RefreshUI()
    end)
    self:WndNetMsgRecv(LProtoIds.PlayerChangeResp, function()
        gModelInstance:OnPlayerInstanceReq()
    end)
end

function UIUpLvhjgyPop:SetVipInfo()
    local vipLv, value = gModelVip:GetAddOnHookLv()
    local curVipLv = gModelPlayer:GetVipLevel()
    local isLimit = vipLv == curVipLv
    local btn = self:FindWndTrans(self.mPageMag1, "Page/BtnGo")
    CS.ShowObject(btn, not isLimit)

    local iconPath = "vip_icon_bg_" .. vipLv
    local img = self:FindWndTrans(self.mPageMag1, "Page/Icon")

    self:SetWndEasyImage(img, iconPath)

    printInfoN(string.format("vipLv %s value %s", vipLv, value))

    local str = string.replace(ccClientText(19904), vipLv, math.floor(value * 100))

    local text = self:FindWndTrans(self.mPageMag1, "Page/DesText")
    self:SetWndText(text, str)
    self:InitTextLineWithLanguage(text, -30)
    if gLGameLanguage:IsJapanRegion() then
        self:InitTextLineWithLanguage(text, -2)
    end
end

function UIUpLvhjgyPop:SetTimeContent()
    --local timeTotal = GetTimestamp()- gModelInstance:GetPlaceTime()
    --if timeTotal<0 then
    --	timeTotal =0
    --end
    --local timeMax = gModelInstance:GetBoxTimeLimit()*60
    --if timeTotal > timeMax then
    --	timeTotal = timeMax
    --end
    --
    --local color = 'green'
    --if timeTotal == timeMax then
    --	color = 'red'
    --end
    --local totalTimeStr= LUtil.FormatTimespanNumber(timeTotal)
    --local str  = ccClientText(19907)..LUtil.FormatColorStr(cdStr,color)
    local cd = gModelInstance:GetUpLevelCD()
    local cdStr = math.floor(tonumber(cd) / 60 * 10) / 10
    if cdStr <= 0 then
        cdStr = 0.1
    end
    local str = string.replace(ccClientText(19907), cdStr)
    local text = self:FindWndTrans(self.mPageMag1, "DesText")
    self:SetWndText(text, str)
    self:InitTextLineWithLanguage(text, -30)
    if gLGameLanguage:IsJapanRegion() then
        self:InitTextLineWithLanguage(text, -2)
    end
    if self._isVie then
        self:InitTextLineWithLanguage(text, 0)
        self:SetAnchorPos(text,Vector2.New(-143,-60))
    end
end

function UIUpLvhjgyPop:OnClickGo2()
    gModelFunctionOpen:Jump(10200010)
end

function UIUpLvhjgyPop:GoToVip()
    local vipLv = gModelPlayer:GetVipLevel()
    local max = gModelVip:GetMaxVipLv()
    if vipLv >= max then
        return
    end

    gModelFunctionOpen:Jump(15000000)
end

function UIUpLvhjgyPop:OnClickGo1()
    --gModelFunctionOpen:Jump(10210001)
    GF.OpenWnd("UIGjAward")
end

function UIUpLvhjgyPop:OnTryTcpReconnect()
end

function UIUpLvhjgyPop:OnTimer(key)
    if key == self._countDownKey then
        self:SetTimeContent()
    end
end

function UIUpLvhjgyPop:RefreshUI()


    self:SetInstanceInfo()

    self:SetVipInfo()
    self:SetPriviInfo()

end

function UIUpLvhjgyPop:SetStaticContent()
    local str = ccClientText(19900)
    local text = self:FindWndTrans(self.mPageMag1, "desc_1")
    self:SetWndText(text, str)
    if self._isEnus then
        self:InitTextCharacterWithLanguage(text, 10)
    else
        self:InitTextLineWithLanguage(text, -30)
    end

    if self._isVie then
        self:InitTextLineWithLanguage(text, 10)
    end

    str = ccClientText(19901)
    text = self:FindWndTrans(self.mPageMag1, "desc_2")
    self:SetWndText(text, str)
    if self._isEnus then
        self:InitTextCharacterWithLanguage(text, 10)
    else
        self:InitTextLineWithLanguage(text, -30)
    end

    if self._isVie then
        self:InitTextLineWithLanguage(text, 10)
    end

    str = ccClientText(19902)
    text = self:FindWndTrans(self.mPageMag2, "desc_1")
    self:SetWndText(text, str)
    if self._isEnus then
        self:InitTextCharacterWithLanguage(text, 10)
    else
        self:InitTextLineWithLanguage(text, -30)
    end

    if self._isVie then
        self:InitTextLineWithLanguage(text, 10)
    end

    str = ccClientText(19903)
    text = self:FindWndTrans(self.mPageMag2, "desc_2")
    self:SetWndText(text, str)
    if self._isEnus then
        self:InitTextCharacterWithLanguage(text, 10)
    else
        self:InitTextLineWithLanguage(text, -30)
    end

    if self._isVie then
        self:InitTextLineWithLanguage(text, 10)
    end

    str = ccClientText(15017)
    text = self:FindWndTrans(self.mPageMag1, "TitleText")
    self:SetWndText(text, str)
    str = ccClientText(10765)
    text = self:FindWndTrans(self.mPageMag2, "TitleText")
    self:SetWndText(text, str)

    --str = ccClientText(19904)
    --text = self:FindWndTrans(self.mPageMag1,"Page/DesText")
    --self:SetWndText(text,str)
    str = ccClientText(19909)
    text = self:FindWndTrans(self.mPageMag2, "Page/DesText")
    self:SetWndText(text, str)
    if self._isEnus then
        self:InitTextCharacterWithLanguage(text, 10)
    else
        self:InitTextLineWithLanguage(text, -30)
    end
    self:InitTextSizeWithLanguage(text, -2)

    str = ccClientText(19905)
    text = self:FindWndTrans(self.mPageMag1, "Page/BtnGo/BtnText")
    self:SetWndText(text, str)
    self:InitTextLineWithLanguage(text, -2)

    str = ccClientText(19912)
    local btn = self:FindWndTrans(self.mPageMag1, "BtnPageGo")
    self:SetWndButtonText(btn, str)
    local btn = self:FindWndTrans(self.mPageMag2, "BtnPageGo")
    self:SetWndButtonText(btn, str)
end

function UIUpLvhjgyPop:GoToPrivi()
    local isPrivilege = gModelNormalActivity:IsPrivilegeTypeActive(ModelActivity.PRIVILEGE_QUICK)
    if isPrivilege then
        local str = ccClientText(14213) --"特权已激活"
        GF.ShowMessage(str)
        return
    end

    gModelFunctionOpen:Jump(10401111)
end

function UIUpLvhjgyPop:SetPriviInfo()
    local isPrivilege = gModelNormalActivity:IsPrivilegeTypeActive(ModelActivity.PRIVILEGE_QUICK)
    local str = ccClientText(19910)
    if isPrivilege then
        str = ccClientText(19906)
    end
    local text = self:FindWndTrans(self.mPageMag2, "Page/BtnGo/BtnText")
    self:SetWndText(text, str)
    self:InitTextLineWithLanguage(text, -2)
end

function UIUpLvhjgyPop:SetQuickContent()
    local totalCnt = gModelInstance:GetTotalQuickCnt()
    local usedCnt = gModelInstance:GetUsedCnt()
    local leftCnt = totalCnt - usedCnt
    leftCnt = math.max(leftCnt, 0)
    local color = "green"
    if leftCnt == 0 then
        color = "red"
    end
    local str = string.format("%s/%s", leftCnt, totalCnt)
    str = LUtil.FormatColorStr(str, color)
    str = ccClientText(19908) .. str
    local text = self:FindWndTrans(self.mPageMag2, "DesText")
    self:SetWndText(text, str)
    self:InitTextLineWithLanguage(text, -30)
    if gLGameLanguage:IsJapanRegion() then
        self:InitTextLineWithLanguage(text, -2)
    end
end

function UIUpLvhjgyPop:InitIosShowUI()
    if PRODUCT_G_VER == 2 or PRODUCT_G_VER == 3 then
        local btn = self:FindWndTrans(self.mPageMag2, "Page/BtnGo")
        CS.ShowObject(btn, false)
    end
    if self.jpj then
        local btn = self:FindWndTrans(self.mPageMag1, "Page/BtnGo")
        btn.sizeDelta = Vector2.New(150,30)
        local DesText = self:FindWndTrans(self.mPageMag1, "DesText")
        DesText.sizeDelta = Vector2.New(170,30)
        local btn2 = self:FindWndTrans(self.mPageMag2, "Page/BtnGo")
        btn2.sizeDelta = Vector2.New(150,30)
    end
end

function UIUpLvhjgyPop:SetInstanceInfo()
    self:SetTimeContent()
    self:SetQuickContent()
    --self:TimerStop(self._countDownKey)
    --self:TimerStart(self._countDownKey,1,false,-1)
end

------------------------------------------------------------------
return UIUpLvhjgyPop


