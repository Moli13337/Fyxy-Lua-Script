---
--- Created by Administrator.
--- DateTime: 2023/10/26 20:27:26
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIAppsal:LWnd
local UIAppsal = LxWndClass("UIAppsal", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIAppsal:UIAppsal()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIAppsal:OnWndClose()
    gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_RATE_SCORE, "close", self._questId)
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIAppsal:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIAppsal:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    local isHmtRegion = gLGameLanguage:IsHmtRegion()
    self._isHmtRegion = isHmtRegion

    self._questId = self:GetWndArg("questId")
    gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_RATE_SCORE, "open", self._questId)

    self._star = 0

    self:InitUIEvent()

    self._isWXGame = CS.IsWebGL() and LWxHelper.IsWxPlatform()

    self._isRegionDiff = gLGameLanguage:IsForeignRegion()

    self._isChinaRegion = gLGameLanguage:IsChinaRegion()

    if self._isChinaRegion then
        CS.ShowObject(self.mBubble,false)
    end

    if self._isRegionDiff or self._isChinaRegion then
        self:SetStaticContent()
        self:RefreshUI()
        self:InitShowItemList(true)

        CS.ShowObject(self.mRoot_enus, true)
        CS.ShowObject(self.mRoot, false)

        self:SetAnchorPos(self.mShowBtnList, Vector2.New(0, -218))
        return
    else
        CS.ShowObject(self.mRoot, true)
        CS.ShowObject(self.mRoot_enus, false)
    end

    if isHmtRegion then
        self:InitMsg()

        self:SetHMTStaticContent()
        CS.ShowObject(self.mCancelBtn, true)

        self:InitShowItemList()
    else
        self:SetStaticContent()
        self:RefreshUI()
    end
end

function UIAppsal:OnClickStar(itemdata)
    self._star = itemdata
    local list = self:GetUIScroll("starList")
    list:DrawAllItems()

    self:SetWndButtonGray(self.mConfirmBtn, false)


    --这里进行设置
    if self._isRegionDiff or self._isChinaRegion then
        local str
        if self._isWXGame then
            str = ccClientText(22109)
        else
            if self._star > 3 then
                --前往评论
                str = ccClientText(22115)
            else
                str = ccClientText(22109)
            end
        end
        self:SetWndButtonText(self.mConfirmBtn, str)
    end

    FireEvent(EventNames.CLICK_RATING_STAR, self._star)
end

function UIAppsal:OnDrawShowItemCell(list, item, itemdata, itempos)
    local IconTrans = self:FindWndTrans(item, "CommonUI/Icon")

    local instanceID = item:GetInstanceID()
    local baseClass = self:GetCommonIcon(instanceID)
    baseClass:Create(IconTrans)
    baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
    baseClass:DoApply()

    self:SetWndClick(IconTrans, function()
        gModelGeneral:ShowCommonItemTipWnd(itemdata)
    end)
end

function UIAppsal:OnDrawStar(list, item, itemdata, itempos)
    local off = self:FindWndTrans(item, "off")
    local on = self:FindWndTrans(item, "on")

    local isOff = self._star < itemdata

    CS.ShowObject(off, isOff)
    CS.ShowObject(on, not isOff)
    self:SetWndClick(item, function()
        self:OnClickStar(itemdata)
    end)
end

function UIAppsal:OnClickCancelBtnFunc()
    self:WndClose()
end

function UIAppsal:OnPlayerGameRatingResp(pb)
    if pb.finishType == 2 then
        CS.ShowObject(self.mShowBtnList, false)
        CS.ShowObject(self.mIntro, false)
        CS.ShowObject(self.mIntroHMT, true)
    end
end

function UIAppsal:OnClickConfirm()
    --ja服调用外部sdk进行评价
    if self._isRegionDiff and  (not gLGameLanguage:IsJapanRegion()) then
        --- 大于3 才跳转
        local star = self._star
        if star > 3 then
            ---- 2024/12/11:us修改为配置链接
            local appStoreLink = gLGameLogin:GetAppStoreUrl()
            if not string.isempty(appStoreLink) then
                LNativeHelper.OpenAppStore(appStoreLink)
            else
                if LOG_INFO_ENABLED then
                    printInfoNR2("UIAppsal","后台链接为空")
                end
            end
        end
        gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_RATE_SCORE,"score",self._questId,star)
        gModelPlayer:OnPlayerGameRatingReq(self._questId,star,1)
    elseif self._isChinaRegion then
        --- http://192.168.16.2:3002/issues/3696
        --- 大于3 才跳转
        local star = self._star
        if star > 3 then
            gLSdkImpl:CallMethod(LSdkMethod.RateUs, false)
        end
        gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_RATE_SCORE, "score", self._questId, self._star)
        gModelPlayer:OnPlayerGameRatingReq(self._questId, self._star, 1)
    else
        self:OnClickHMTConfireBtnFunc()
    end

    if self._star>=1 then
        self:WndClose()
    end
end

function UIAppsal:RefreshUI()
    CS.ShowObject(self.mItemList, true)

    local dataList = {}
    for k = 1, 5 do
        table.insert(dataList, k)
    end

    local uiList = self:GetUIScroll("starList")
    uiList:Create(self.mItemList, dataList, function(...)
        self:OnDrawStar(...)
    end)

    self:SetWndButtonGray(self.mConfirmBtn, true)

end

function UIAppsal:SetHMTStaticContent()
    local str = ccClientText(22100) --"评分"
    self:SetWndText(self.mTitle, str)

    str = ccClientText(22114)
    self:SetWndButtonText(self.mCancelBtn, str)

    str = ccClientText(22115)
    self:SetWndButtonText(self.mConfirmBtn, str)

    str = ccClientText(22112) --"感谢大大的厚爱，您的好评是我们最大的鼓励哦！"
    self:SetWndText(self.mIntro, str)
    self:InitTextLineWithLanguage(self.mIntro, -30)
    CS.ShowObject(self.mIntro, true)

    ---- 港澳台
    str = ccClientText(22113) --"感谢大大的厚爱，您的好评是我们最大的鼓励哦！"
    self:SetWndText(self.mIntroHMT, str)
    self:InitTextLineWithLanguage(self.mIntroHMT, -30)
    CS.ShowObject(self.mIntroHMT, true)

    str = ccClientText(22111)
    self:SetWndText(self.mBubbleTxt, str)
    self:InitTextLineWithLanguage(self.mBubbleTxt, -30)

end

function UIAppsal:InitMsg()
    self:WndNetMsgRecv(LProtoIds.PlayerGameRatingResp, function(pb)
        self:OnPlayerGameRatingResp(pb)
    end)
end

function UIAppsal:InitShowItemList(isEnus)
    local itemList = isEnus and self.mShowItemList_enus or self.mShowItemList
    CS.ShowObject(itemList, true)

    local list = self:GetShowItemList()
    local uiShowItemList = self._uiShowItemList
    if uiShowItemList then
        uiShowItemList:RefreshList(list)
    else
        uiShowItemList = self:GetUIScroll("uiShowItemList")
        self._uiShowItemList = uiShowItemList
        uiShowItemList:Create(itemList, list, function(...)
            self:OnDrawShowItemCell(...)
        end)
    end
end

function UIAppsal:InitUIEvent()
    self:SetWndClick(self.mBtnClose, function()
        self:WndClose()
    end)

    --self:SetWndClick(self.mMask,function ()
    --	self:WndClose()
    --end)

    self:SetWndClick(self.mCancelBtn, function()
        self:OnClickCancelBtnFunc()
    end)

    self:SetWndClick(self.mConfirmBtn, function()
        self:OnClickConfirm()
    end)

end

function UIAppsal:SetStaticContent()
    local str = ccClientText(22100) --"评分"
    self:SetWndText(self.mTitle, str)
    self:SetWndText(self.mTitle_enus, str)

    str = ccClientText(22109)
    self:SetWndButtonText(self.mConfirmBtn, str)

    str = ccClientText(22101) --"感谢大大的厚爱，您的好评是我们最大的鼓励哦！"
    self:SetWndText(self.mIntro, str)
    self:InitTextLineWithLanguage(self.mIntro, -30)
    CS.ShowObject(self.mIntro, true)

    str = ccClientText(22111)
    self:SetWndText(self.mBubbleTxt, str)
    self:InitTextLineWithLanguage(self.mBubbleTxt, -30)
    self:SetWndText(self.mBubbleTxt_enus, str)
end

function UIAppsal:OnClickHMTConfireBtnFunc()
    --[[	local appStoreLink = gLGameLogin:GetAppStoreUrl()
        local packageName = gModelNormalActivity:GetBIActivityConfigRefByKey("gradeGameName")
        local storeName = gModelNormalActivity:GetBIActivityConfigRefByKey("gradeAppName")
        LNativeHelper.OpenAppStore(appStoreLink,packageName,storeName)

        gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_RATE_SCORE,"score",self._questId,self._star)
        gModelPlayer:OnPlayerGameRatingReq(self._questId,self._star,2)]]
    gLSdkImpl:CallMethod(LSdkMethod.RateUs, false)
    gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_RATE_SCORE, "score", self._questId, self._star)
    gModelPlayer:OnPlayerGameRatingReq(self._questId, self._star, 1)
    FireEvent(EventNames.CLICK_RATING_STORE, self._star)
    self:WndClose()
end

function UIAppsal:GetShowItemList()
    local list = {}
    local shopScoreReward = gModelNormalActivity:GetBIActivityConfigRefByKey("shopScoreReward")
    if not string.isempty(shopScoreReward) then
        list = LxDataHelper.ParseItem(shopScoreReward)
    end
    return list
end
------------------------------------------------------------------
return UIAppsal


