---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHuiYPay:LWnd
local UIHuiYPay = LxWndClass("UIHuiYPay", LWnd)

local typeHorizontalLayoutGroup = typeof(UnityEngine.UI.HorizontalLayoutGroup)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHuiYPay:UIHuiYPay()
    self._btnListKeyStr = "btnList"

    ---@type table<number, CommonIcon>
    self._commonIconTbl = {}

    self:SetHideHurdle()

    ---@type table<number, table>
    self._eightPageList = {}
    self._showToggle = true
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHuiYPay:OnWndClose()
    self:ClearCommonIconList(self._commonIconTbl)
    self._commonIconTbl = nil
    self._uiBtnList = nil
    self._eightPageList = nil
    self:ClearCommonIconList(self._hyperList)
    if self._delayUpdateScrollTimer then
        LxTimer.DelayTimeStop(self._delayUpdateScrollTimer)
        self._delayUpdateScrollTimer = nil
    end

    if self._delaySetXTimer then
        LxTimer.DelayTimeStop(self._delaySetXTimer)
        self._delaySetXTimer = nil
    end

    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHuiYPay:OnCreate()
    LWnd.OnCreate(self)
    self._hyperList = {}
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHuiYPay:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()
    self._isSEA = gLGameLanguage:IsSEALngRegion()
    self._tiShen = gLGameLanguage:IsHmtRegion() and PRODUCT_G_VER and PRODUCT_G_VER ~= 0
    self._isJapaness = gLGameLanguage:IsJapanVersion()
    CS.ShowObject(self.mEveryDayEffect, false)
    --CS.ShowObject(self.mGiftBg,false)
    self:SetWndPara()
    self:InitData()
    self:InitEvent()
    self:InitMsg()

    --self:SetWndEasyImage(self.mTitleImg1,"vip_bg_txt_1")
    --self:SetWndEasyImage(self.mZhuanTxtImg,"vip_txt_2",nil,true)
    self:SetWndEasyImage(self.mVipTitleImg, "vip_txt_11", nil, true)
    self:SetWndText(self.mVipShowText, ccClientText(11925))
    self:SetWndText(self.mVipShowTextEn, ccClientText(11925))
    self:SetWndText(self.mTxtVipPrivilege, ccClientText(11938))
    self:OnClickShowToggle()
    self:ViewCtrl()
    self:InitText()
    self:InitBtnList()

    self:SendTaInfo()
    self:RefreshVipLevel()

    -- self:CreateWndEffect(self.mEveryDayEffect,"fx_VIPchongzhiwupo","fx_VIPchongzhiwupo",100)
    self:CreateWndEffect(self.mImgBox, "fx_tehuishangdian", "fx_tehuishangdian", 100)

    if PRODUCT_G_VER and PRODUCT_G_VER ~= 0 then
        CS.ShowObject(self.mImageRole, false)

        if gLGameLanguage:CheckIsUseSpecialProduct() then
            --获取包的情况
            local packId = gLGameLanguage:GetPackProductInfo()
            local colorInfo = gLGameLanguage:GetVipColorInfo(packId, "vipBg")
            self:SetWndImageColor(self.mGiftBg, Color.New(checknumber(colorInfo[1]) / 255, checknumber(colorInfo[2]) / 255, checknumber(colorInfo[3]) / 255, 1))

            if packId == 1 then
                --self:SetWndImageColor(self.mGiftBg, Color.New(217 / 255, 210 / 255, 14 / 255, 1))
            elseif packId == 2 then
                --self:SetWndImageColor(self.mGiftBg, Color.New(130 / 255, 239 / 255, 112 / 255, 1))
            elseif packId == 3 then
                --self:SetWndImageColor(self.mGiftBg, Color.New(215 / 255, 109 / 255, 234 / 255, 1))
                CS.ShowObject(self.mGameObject, false)
            end

        end
        if self._tiShen then
            self:SetWndImageColor(self.mGiftBg, Color.New(70 / 255, 164 / 255, 207 / 255, 1))
        end

    else
        CS.ShowObject(self.mImageRole, true)
    end

    if gLGameLanguage:IsJapanRegion() then
        CS.ShowObject(self.mBtn1, true)
        CS.ShowObject(self.mBtn2, true)
        CS.ShowObject(self.mImageRole, false)
        self:SetTextTile(self.mBtn1, ccClientText(801))
        self:SetTextTile(self.mBtn2, ccClientText(802))
        self:SetWndClick(self.mBtn1, function()
            local url = GameTable.InnerActivityConfigRef.BusinessLawLink1
            if LGameSettings.platformId == 203 or LGameSettings.platformId == 204 then
                url = GameTable.InnerActivityConfigRef.BusinessLawLink3
            end
            if not string.isempty(url) then
                CS.UApplication.OpenURL(url)
            end
        end)
        self:SetWndClick(self.mBtn2, function()
            local url = GameTable.InnerActivityConfigRef.BusinessLawLink2
            if LGameSettings.platformId == 203 or LGameSettings.platformId == 204 then
                url = GameTable.InnerActivityConfigRef.BusinessLawLink4
            end
            if not string.isempty(url) then
                CS.UApplication.OpenURL(url)
            end
        end)
    else
        CS.ShowObject(self.mBtn1, false)
        CS.ShowObject(self.mBtn2, false)
    end
end

-- function UIHuiYPay:OpenDailyGiftC(sid)
-- self:CreateChildWnd(self.mChildRoot,"UIActGiftC",{sid = sid})
-- end

function UIHuiYPay:OpenSkinShop()
    --gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_SKIN,"open",2)
    self:CreateChildWnd(self.mChildRoot, "UILimitWardrobe")
end

function UIHuiYPay:FindVipRef(vipLv)
    for k, v in pairs(GameTable.PremiumLevelRef) do
        if v.level == vipLv then
            return v
        end
    end
end

function UIHuiYPay:InitEvent()
    self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN, function()
        self:WndClose()
    end)
    --self:WndEventRecv(EventNames.ON_MAIN_CITY_BTN_CHANGE,function () self:WndClose() end)
    self:SetWndClick(self.mReturnBtn, function()
        self:OnClickReturn()
    end)
    for i, v in ipairs(self._btnList) do
        self:SetWndClick(v, function()
            if self._openView == i then
                return
            end
            self._openView = i
            self:ViewCtrl()
            if self._openView == 3 then
                gLxTKData:OnUIBtnClick("UIHuiYPay", 2)
            end
        end)
    end
    self:SetWndClick(self.mVipShowToggleBg, function()
        self:OnClickShowToggle()
    end)
    self:SetWndClick(self.mVipShowToggleBgEn, function()
        self:OnClickShowToggle()
    end)

    self:SetWndClick(self.mBuyTipsBtn, function(...)
        self:OnClickByTips()
    end)
    self:SetWndClick(self.mBuyTipsTextJa, function(...)
        self:OnClickByTipsJapan()
    end)
    self:SetWndClick(self.mBtnCZHelp, function()
        GF.OpenWnd("UIBzTips", { refId = 169 })
    end)
end

function UIHuiYPay:OnClickReturn()
    local func = self._jumpCallback
    if func then
        func()
    end
    self:WndClose()
end
function UIHuiYPay:RefreshVipLevel()
    local vipLv = gModelPlayer:GetVipLevel()
    CS.ShowObject(self._vipShowToggleBgTrans, vipLv > 0)
end

function UIHuiYPay:OnDrawDescItem(list, item, itemdata, itempos)
    local IconShowDiv = self:FindWndTrans(item, "IconShowDiv")
    local NewImgTrans = self:FindWndTrans(IconShowDiv, "NewImg")
    local UpImgTrans = self:FindWndTrans(IconShowDiv, "UpImg")
    local dianImgTrans = self:FindWndTrans(IconShowDiv, "dianImg")
    local TextShowDiv = self:FindWndTrans(item, "TextShowDiv")
    local DescTxtTrans = self:FindWndTrans(TextShowDiv, "DescTxt")
    local up = itemdata.up
    local showDian = true
    CS.ShowObject(NewImgTrans, false)
    CS.ShowObject(UpImgTrans, false)
    if up == 1 then
        if NewImgTrans then
            CS.ShowObject(NewImgTrans, true)
        end
        showDian = false
    else
        local nowValue = itemdata.nowValue
        if nowValue == 1 then
            if UpImgTrans then
                CS.ShowObject(UpImgTrans, true)
            end
            showDian = false
        end
    end
    if dianImgTrans then
        CS.ShowObject(dianImgTrans, showDian)
    end
    if DescTxtTrans then
        local hyperCreateFun = function(tran)
            if not CS.IsValidObject(tran) then
                return
            end
            local instanceId = tran:GetInstanceID()
            local hyper = self._hyperList[instanceId]
            if not hyper then
                hyper = UIHyperText:New()
                self._hyperList[instanceId] = hyper
                hyper:Create(tran)
            end
            return hyper
        end

        local des = ccLngText(itemdata.des)
        des = LUtil.CreateHyperWithValue(DescTxtTrans, des, hyperCreateFun, function(data)
            gModelChat:ClickHyper(data, self:GetWndName())
        end)
        --print(des,itemdata.refId)
        self:SetWndText(DescTxtTrans, des)
    end

end

function UIHuiYPay:GoToActivityWnd()
    --[[	local page,subPage = gModelActivity:GetActivityByModelId()
        GF.OpenWndBottom("UIAct",{page = page,subPage = subPage})
        FireEvent(EventNames.CHANGE_MAIN_BTN,5)]]
    local list = gModelActivity:GetActivityDataByModelId(ModelActivity.MONTH_CARD)

    local isEnjoyCard = false
    if not list or #list == 0 then
        -- list = gModelActivity:GetActivityDataByModelId(ModelActivity.MONTH_ACTIVITY_ENJOY_CARD)
        -- isEnjoyCard = true
    end

    if not list or #list == 0 then
        GF.ShowMessage(ccClientText(16105))
        return
    end

    if not isEnjoyCard then
        gModelFunctionOpen:Jump(10403301)
    else
        -- if gModelActivity:CheckIsShowEnjoyMonthCard(true) then
        -- 	gModelFunctionOpen:Jump(10510002)
        -- else
        gModelFunctionOpen:Jump(10510001)
        -- end
    end
end

function UIHuiYPay:IsBuyCard()
    return gModelPay:IsBuyCard()
end

function UIHuiYPay:OnDrawShopItem(list, item, itemdata, itempos)
    if itemdata.type == 1 then
        self:OnDrawType1(item, itemdata)
    elseif itemdata.type == 2 then
        self:OnDrawType2(item, itemdata)
    elseif itemdata.type == 3 then
        self:OnDrawType3(item, itemdata)
    end

end
---------------------------------------- 礼包 --------------------------------------

function UIHuiYPay:ShowPage(vipPage)
    CS.ShowObject(self.mVipImg1, vipPage)
    CS.ShowObject(self.mVipImg2, vipPage)
    CS.ShowObject(self.mWndBg, vipPage)
    CS.ShowObject(self.mGiftBg, not vipPage or self._openView == 2)

    CS.ShowObject(self.mGiftContent, not vipPage)
    CS.ShowObject(self.mChildRoot, not vipPage)
end
function UIHuiYPay:OnClickShowToggle()
    local bool = not self._showToggle
    CS.ShowObject(self._btnShowNoTrans, bool)
    CS.ShowObject(self.mBtnShowYes, not bool)
    CS.ShowObject(self._vipShowBgRoot, bool)
    self._showToggle = bool
    if not bool then
        return
    end
    self:RefreshVipShowList()
end

function UIHuiYPay:GetHistory()
    local list = LWnd.GetHistory(self)
    local wndArgList = list.wndArgList
    wndArgList.page = self._openView
    wndArgList.subPage = self._subPage
    wndArgList.jumpCallback = self._jumpCallback
    return list
end

function UIHuiYPay:SetWndPara()
    self._openView = self:GetWndArg("page") or 1            -- 页面
    self._subPage = self:GetWndArg("subPage")
    self._jumpCallback = self:GetWndArg("jumpCallback")
    --local actPage = self:GetWndArg("actPage")				-- 活动页面
    --self._actPage = actPage or 1


    local isShow = gModelFunctionOpen:CheckIsShow(15101000)

    if PRODUCT_G_VER == 2 then
        if gLGameLanguage:IsJapanRegion() then
            --日本ios写死屏蔽
            isShow = false
        end
    end

    CS.ShowObject(self.mVipBtn, isShow)

    isShow = gModelFunctionOpen:CheckIsShow(15101040)

    --[[	if PRODUCT_G_VER == 1 then
    end]]
    if PRODUCT_G_VER == 2 then
        --海外ios写死屏蔽
        isShow = false
    end

    CS.ShowObject(self.mGiftBtn, isShow)

    if PRODUCT_G_VER ~= 0 then
        CS.ShowObject(self.mGiftBtn, false)
        CS.ShowObject(self.mVipBtn, false)
    end

    if not isShow then
        -- self.mShopBtn.localPosition = self.mGiftBtn.localPosition
        self._openView = 2
    end

    if self._openView == 3 then
        local isOpen = gModelFunctionOpen:CheckIsOpened(15101030)
        if not isOpen then
            self._openView = 1
        end
    end
end

function UIHuiYPay:OpenOverflowPrivilege(sid)
    self:CreateChildWnd(self.mChildRoot, "UISubOverflowPrige", { sid = sid })
end
--------------------------------- 商店数据 ---------------------------------
function UIHuiYPay:InitShopList()
    local uiList = self._uiShopList
    if not uiList then
        uiList = UIListEasy:New()
        uiList:Create(self, self.mPayMonList)
        uiList:EnableScroll(true, false)
        uiList:SetFuncOnItemDraw(function(...)
            self:OnDrawShopItem(...)
        end)
        self._uiShopList = uiList
    end
    uiList:RemoveAll()

    --添加特殊购买
    local ref = {}
    --for k,v in ipairs(GameTable.RechargeLinkRef) do
    --	local refId = v.refId
    --	local checkFunc = self._specialRechargeCfg[refId]
    --	if checkFunc and checkFunc(v) then
    --		local data = {
    --			data = v,
    --			isEightAct = k == 1,
    --			type = 1,
    --		}
    --
    --		table.insert(ref,data)
    --	end
    --end

    for k, v in pairs(GameTable.TopupRef) do
        local show = v.show or 1
        if show == 1 then
            local data = {
                data = v,
                type = 2
            }
            table.insert(ref, data)
        end
    end

    if not gLGameLanguage:IsForeignRegion() then
        for k, v in pairs(GameTable.TopupPayRef) do
            local welfareId = v.welfareId
            if welfareId and welfareId > 0 and v.show == 1 then
                local data = {
                    data = v,
                    type = 3,
                }
                table.insert(ref, data)
            end
        end
    end

    table.sort(ref, function(ref1, ref2)
        return ref1.data.rank < ref2.data.rank
    end)
    for i, v in ipairs(ref) do
        uiList:AddData(i, v)
    end
    uiList:RefreshList()


end

function UIHuiYPay:CheckEightLoginShow(cfg)
    local jumpId = cfg.jump
    if not jumpId then
        return false
    end
    local isOpen = gModelFunctionOpen:CheckIsOpened(jumpId)
    return isOpen and self._specialEightLoginShow
end

function UIHuiYPay:OpenDailyGiftA(sid)
    self:CreateChildWnd(self.mChildRoot, "UIActGiftA", { sid = sid })
end

function UIHuiYPay:OnDrawGiftCell(list, item, itemdata, itempos)
    local refId = itemdata.refId
    local serverData = self._vipGiftList[refId]
    local state = serverData and serverData.state or 0          -- 判断是否可购买  0-不可购买，1-可购买，2-已购买
    local giftType = itemdata.type
    local buyType = itemdata.buyType
    local buyNeed = itemdata.buyNeed
    local level = itemdata.level
    local type3Data
    -- 月卡礼包和每日礼包绑定
    if giftType == 2 then
        type3Data = self._typeVipGiftList[self._lastbtn]
    end
    local itemListTrans = self:FindWndTrans(item, "itemList")
    if itemListTrans then
        local giftReward = itemdata.giftReward
        self:RefreshGiftCell(itemListTrans, giftReward, giftType)
    end
    local jiageDivTrans = self:FindWndTrans(item, "jiageDiv")
    local jiagetext = self:FindWndTrans(item, "jiagetext")
    local jiagetext2 = self:FindWndTrans(item, "jiagetext2")
    local Texts1 = self:FindWndTrans(item, "jiagetext/Text")
    local Texts2 = self:FindWndTrans(item, "jiagetext2/Text2")
    --self:SetWndText(Texts1, ccClientText(11939,"1688"))
    --self:SetWndText(Texts2, ccClientText(11940,"3688"))
    if jiageDivTrans then
        local oriPrice = itemdata.oriPrice
        if string.isempty(oriPrice) then
            CS.ShowObject(jiageDivTrans, false)
            CS.ShowObject(jiagetext, false)
            CS.ShowObject(jiagetext2, true) --
        else
            CS.ShowObject(jiagetext, true) --
            CS.ShowObject(jiagetext2, false)
            CS.ShowObject(jiageDivTrans, true)
            local TextTrans = self:FindWndTrans(jiageDivTrans, "Text")
            local IconTrans = self:FindWndTrans(jiageDivTrans, "Icon")
            local OriginalTxtTrans = self:FindWndTrans(jiageDivTrans, "OriginalTxt")
            if TextTrans then
                self:SetWndText(TextTrans, ccClientText(11901))
            end
            local temp = string.split(oriPrice, "=")
            if IconTrans then
                local tempIcon = gModelItem:GetItemIconByRefId(tonumber(temp[2]))
                self:SetWndEasyImage(IconTrans, tempIcon)
            end
            if OriginalTxtTrans then
                self:SetWndText(OriginalTxtTrans, temp[3])
            end
        end
    end
    local useAutoBtn = true
    local BtnTrans
    if useAutoBtn then
        BtnTrans = self:FindWndTrans(item, "BtnYellow3New")
    else
        BtnTrans = self:FindWndTrans(item, "BtnYellow3")
    end
    if BtnTrans then
        local redPointTrans = self:FindWndTrans(BtnTrans, "redPoint")
        local buyYueKa, type3RefId, type3States = false
        local SellOutImg = self:FindWndTrans(item, "SellOutImg")
        local ReceiveImg = self:FindWndTrans(item, "ReceiveImg")
        if type3Data then
            type3RefId = type3Data.refId
            local type3ServerData = self._vipGiftList[type3RefId]
            if type3ServerData then
                type3States = type3ServerData.state
                if state ~= 1 then
                    -- 当前每日礼包不可以领取
                    buyYueKa = true
                    state = type3States
                end
                if type3States == 1 then
                    -- 月卡礼包可以领取
                    state = type3States
                    buyYueKa = state == 1
                end
            end
        end
        CS.ShowObject(SellOutImg, state == 2)
        local IconTrans
        local showIcon = false
        local btnStr = ""
        if state == 2 then
            CS.ShowObject(BtnTrans, false)
            CS.ShowObject(ReceiveImg, false)
            self:SetWndButtonGray(BtnTrans, true)
        else
            local isGray = false
            CS.ShowObject(BtnTrans, true)
            CS.ShowObject(ReceiveImg, false)
            showIcon = true
            if buyType == 1 or buyType == 4 then
                showIcon = false
            end
            local txt = ""
            if state == 0 then
                if buyYueKa then
                    txt = ccClientText(15803)
                else
                    txt = ccClientText(11916)
                end
            elseif state == 1 then
                txt = ccClientText(12006)
            end
            if self._vip < level then
                txt = ccClientText(12006)
                buyYueKa = false
                isGray = true
                btnStr = txt
            else
                local isShowReceive = false
                if buyYueKa then
                    if type3States and type3States == 1 then
                        txt = ccClientText(12006)
                    else
                        isShowReceive = gLGameLanguage:IsForeignRegion()
                        txt = ccClientText(15803)
                    end
                end
                btnStr = txt
                CS.ShowObject(ReceiveImg, isShowReceive)
                CS.ShowObject(BtnTrans, not isShowReceive)
            end
            if useAutoBtn then
                if isGray then
                    IconTrans = self:FindWndTrans(BtnTrans, "Gray/GameObject/IconDiv")
                else
                    IconTrans = self:FindWndTrans(BtnTrans, "Light/GameObject/IconDiv")
                end
            else
                IconTrans = self:FindWndTrans(BtnTrans, "Icon")
            end
            self:SetWndButtonGray(BtnTrans, isGray)
        end

        if redPointTrans then
            if giftType == 2 then
                local otherData = self._vipGiftList[refId]
                if otherData then
                    local s = otherData.state
                    CS.ShowObject(redPointTrans, s == 1)
                end
            else
                if not string.isempty(buyNeed) then
                    local buyNeedList = string.split(buyNeed, "=")
                    local needNum = tonumber(buyNeedList[3])
                    CS.ShowObject(redPointTrans, needNum == 0 and state ~= 2)
                end
            end
        end
        if buyType == 2 then
            local buyNeedList = string.split(buyNeed, "=")

            local showFree = false
            local needNum = tonumber(buyNeedList[3])
            if needNum > 0 then
                if IconTrans then
                    local tempIcon = gModelItem:GetItemIconByRefId(tonumber(buyNeedList[2]))
                    self:SetWndEasyImage(IconTrans, tempIcon)
                    local iconDivIconTrans = self:FindWndTrans(BtnTrans, "Icon")
                    if (iconDivIconTrans) then
                        self:SetWndEasyImage(iconDivIconTrans, tempIcon)
                    end
                end

                btnStr = buyNeedList[3]
            else
                showFree = true
                btnStr = ccClientText(11913)
            end
            showIcon = not showFree
        elseif buyType == 4 then
            local need = tonumber(buyNeed)
            btnStr = ccClientText(11913)
            if need > 0 then
                btnStr = gModelPay:GetShowByWelfareId(need)
            end
        end
        CS.ShowObject(IconTrans, showIcon)
        if useAutoBtn then
            local LightTxtTrans = self:FindWndTrans(BtnTrans, "Light/GameObject/Text")
            local GrayTxtTrans = self:FindWndTrans(BtnTrans, "Gray/GameObject/Text")
            self:SetWndText(LightTxtTrans, btnStr)
            self:SetWndText(GrayTxtTrans, btnStr)
        else
            self:SetWndButtonText(BtnTrans, btnStr)
        end

        self:SetWndClick(BtnTrans, function()
            if self._vip < level then
                local msg = string.replace(ccClientText(15908), level)
                GF.ShowMessage(msg)
                return
            end
            self._buyRefId = itemdata.refId
            if buyYueKa then
                if state == 1 then
                    -- 月卡可领取
                    self._buyRefId = type3RefId
                    self:BuyGift(self._buyRefId)
                else
                    -- 前往充值月卡
                    self:GoToActivityWnd()
                end
            else
                -- 购买礼包(每日和特权礼包)
                self:BuyGift(self._buyRefId, buyType)
            end
        end)
    end
    local GiftNameTrans = self:FindWndTrans(item, "GiftName")
    if GiftNameTrans then
        local str = ccClientText(11912)
        if giftType == 1 then
            str = ccClientText(11911)
        elseif giftType == 4 then
            str = ccClientText(11926)
        end
        self:SetWndText(GiftNameTrans, str)
    end
end

function UIHuiYPay:InitMsg()
    self:WndNetMsgRecv(LProtoIds.VipGiftListResp, function(pb, ret)
        if self._openView ~= 1 then
            return
        end
        self._vipGiftList = {}
        local datas = pb.states
        for k, v in pairs(datas) do
            local refId = v.refId
            if refId then
                local data = { refId = refId, state = v.state, }
                self._vipGiftList[refId] = data
            end
        end
        if self._uiBtnList then
            --[[			local uiList = self._uiBtnList:GetList()
                        uiList:RefreshList()
                        uiList:DelayScrollTo(self._lastbtn)]]
            local ref = self:GetBtnData()
            self._uiBtnList:RefreshData(ref)
        else
            self:InitBtnList()
        end
        self:InitText(true)
        if self._buyRefId == nil then
            self:InitBtnList(true)
            self:InitDescList()
        end
        self:InitGiftList()
    end)
    self:WndNetMsgRecv(LProtoIds.FirstChargeInfoResp, function(pb, ret)
        if self._openView ~= 2 then
            return
        end
        self._shopList = {}
        local datas = pb.flags
        for k, v in pairs(datas) do
            local refId = v.refId
            if refId then
                local data = {
                    refId = refId,
                    flag = v.flag,
                }
                self._shopList[refId] = data
            end
        end
        self:InitText(true)
        self:InitShopList()
    end)
    self:WndNetMsgRecv(LProtoIds.VipGiftBuyResp, function(pb, ret)
        self:InitText(true)
        self._buyRefId = nil
    end)
    self:WndEventRecv(EventNames.ON_VIPLEVEL_CHANGE, function(index)
        index = index or 1
        self:ReSet(index)
    end)

    local vipPbId = LProtoHelper.GetProtoId("VipGiftBuyResp")
    self:WndEventRecv(EventNames.NET_ERROR_CODE, function(code, error, argList)
        if code == vipPbId then
            self._buyRefId = nil
        end
    end)

    self:WndEventRecv(EventNames.ON_ACTIVITY_LIST_CHANGE, function()
        self:RefreshGiftActivity()
    end)
    self:WndEventRecv(EventNames.ON_ACTIVITY_SHOW_END, function()
        self:RefreshGiftActivity()
    end)

    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(...)
        self:OnActivityPageResp(...)
    end)
    self:WndNetMsgRecv(LProtoIds.PlayerShieldChangeResp, function(...)
        self:RefreshVipShowList(...)
    end)
    self:WndNetMsgRecv(LProtoIds.PlayerChangeResp, function(...)
        self:RefreshVipLevel(...)
        if self._openView ~= 1 then
            return
        end
        gModelPay:OnVipGiftListReq()
    end)
    self:InitSpecialActivityMsg()
end

function UIHuiYPay:OnClickActivFunc(itemdata)
    if self._curSelectFunc == itemdata.id then
        return
    end
    local old = self._curSelectFunc
    self._curSelectFunc = itemdata.id
    local item
    if old and self._actvFuncList[old] then
        item = self._actvFuncList[old].item
    end
    local select
    local UITextTrans
    local UIText
    if item then
        select = self:FindWndTrans(item, "select")
        self:SetWndEasyImage(select, self._selectIconPath[1])

        UITextTrans = self:FindWndTrans(item, "UIText")
        UIText = self:FindWndText(UITextTrans)
        --self:SetXUITextColor(UIText,self._giftBtnTextColor.common)

        CS.ShowObject(select, false)
    end
    item = self._actvFuncList[self._curSelectFunc].item
    select = self:FindWndTrans(item, "select")
    self:SetWndEasyImage(select, self._selectIconPath[2])
    UITextTrans = self:FindWndTrans(item, "UIText")
    UIText = self:FindWndText(UITextTrans)
    --self:SetXUITextColor(UIText,self._giftBtnTextColor.select)
    CS.ShowObject(select, true)
    self:CloseAllChild()

    self:OpenActivityChildWnd(itemdata)
end
function UIHuiYPay:OnClickVipShowCell(itemdata, boolValue)
    local refId = itemdata.refId
    local arr = gModelPlayer:GetPlayerShieldArr() or {}
    arr[refId] = boolValue == "1" and "0" or "1"
    local shieldInfo = ""
    for i, v in ipairs(arr) do
        if string.isempty(shieldInfo) then
            shieldInfo = v
        else
            shieldInfo = shieldInfo .. "|" .. v
        end
    end
    gModelPlayer:OnPlayerShieldChangeReq(shieldInfo)
end
--------------------------------- 底部按钮 ---------------------------------
--------------------------------- 礼包列表 ---------------------------------
function UIHuiYPay:InitGiftList()
    ---@type UIListEasy
    local uiList = self._uiList
    if not uiList then
        uiList = UIListEasy:New()
        uiList:Create(self, self.mBuyList)
        uiList:EnableScroll(false, false)
        uiList:SetFuncOnItemDraw(function(...)
            self:OnDrawGiftCell(...)
        end)
        self._uiList = uiList
    end
    uiList:RemoveAll()
    local isForeign = gLGameLanguage:IsForeignRegion()
    local allRef = {}
    local type3Reward = ""
    local data = self._vipLvGiftList[self._lastbtn] or {}
    local everyDay = nil
    local cardDay = nil
    for k, v in pairs(data) do
        if v.type == 2 then
            everyDay = v
            --table.insert(allRef,v)
        elseif v.type == 3 then
            if not (gLGameLanguage:IsUSARegion() or gLGameLanguage:IsKoreaRegion()) then
                type3Reward = v.giftReward
                cardDay = v
            end
        else
            table.insert(allRef, v)
        end
    end
    --if everyDay then
    --	if not string.isempty(type3Reward) then
    --		everyDay.giftReward = everyDay.giftReward .. "," .. type3Reward
    --	end
    --end
    table.sort(allRef, function(ref1, ref2)
        local serverData = self._vipGiftList[ref1.refId]
        local aState = serverData and serverData.state or 0    -- 0-不可购买，1-可购买，2-已购买
        serverData = self._vipGiftList[ref2.refId]
        local bState = serverData and serverData.state or 0
        if aState ~= bState then
            return aState < bState
        else
            return ref1.refId < ref2.refId
        end
    end)
    for i, v in ipairs(allRef) do
        --local ref = table.clone(v)
        uiList:AddData(i, v)
    end
    uiList:RefreshList()
    uiList:SetItemRootPosition(nil, 0)
    uiList:EnableScroll(true, false)
    self._everyDay = everyDay
    self._cardDay = cardDay
    self:ShowEveryDaySpine()
end

function UIHuiYPay:CheckDailyGiftBagShow()
    local data = gModelActivity:GetActivityDataByModelId(ModelActivity.MODEL_DAILYGIFTBAG)
    return data and #data > 0
end
--------------------------------- 礼包列表 ---------------------------------
--------------------------------- 窗口打开 ---------------------------------
function UIHuiYPay:OpenPrivilegeShop(sid)
    local extraPara = self:GetWndArg("extra")
    local index = extraPara or 1

    self:CreateChildWnd(self.mChildRoot, "UISubWishPrige", { index = index })
end

-------------------------------- 特殊礼包 ---------------------------------------
function UIHuiYPay:InitSpecialActivityData()
    --特殊限时特惠跳转接口配制
    self._specialRechargeCfg = {
        function(cfg)
            return self:CheckEightLoginShow(cfg)
        end, --八天登录，限时特惠
        function(cfg)
            return true
        end, --特权商城
        function(cfg)
            return self:CheckDailyGiftBagShow()
        end, --每日礼包
    }

    local data = gModelActivity:GetActivityDataByModelId(ModelActivity.EIGHTLOGIN)
    local eightLoginShow = data and #data > 0
    self._specialEightLoginShow = false
    self._specialEightLoginSid = {}
    self._eightDayList = {}
    if not eightLoginShow then
        return
    end

    local activityData
    local moreInfo
    for k, v in ipairs(data) do
        local sid = v.sid
        local webData = gModelActivity:GetWebActivityDataById(sid)
        local showGift = true
        if webData then
            local config = webData.config
            local unlock = tonumber(config.unlock)
            showGift = unlock == 0 or unlock == 2
        end

        if showGift then
            self._specialEightLoginSid[sid] = sid
            activityData = gModelActivity:GetActivityBySid(sid)
            if activityData then
                moreInfo = JSON.decode(activityData.moreInfo)
                self._eightDayList[sid] = tonumber(moreInfo.receiveCount)
            end
        end
    end
end

function UIHuiYPay:OpenDailyGift(sid)
    self:CreateChildWnd(self.mChildRoot, "UISubDTDGift", { sid = sid })
end

function UIHuiYPay:InitText(refresh)
    if not refresh then
        self:SetWndTabText(self.mVipBtn, ccClientText(11903))
        self:SetWndTabText(self.mShopBtn, ccClientText(11915))
        self:SetWndTabText(self.mGiftBtn, ccClientText(11922))
    end

    self._vip = gModelPlayer:GetVipLevel()
    local vip = self._vip
    local curRef = self:FindVipRef(vip)
    local nextVip = vip + 1
    local nextRef = self:FindVipRef(nextVip)
    local isMax = false
    if not nextRef then
        nextVip = vip
        nextRef = self:FindVipRef(nextVip)
        isMax = true
    end
    local serVipExp = gModelPlayer:GetVipExp()
    local nextExp = nextRef.upNeed
    local curExp = curRef.upNeed
    local needExp = nextExp - curExp
    if isMax then
        needExp = nextExp
        CS.ShowObject(self.mTop, false)
        CS.ShowObject(self.mEnTop, false)
        CS.ShowObject(self.mVieTop, false)
        CS.ShowObject(self.mDeTop, false)
        CS.ShowObject(self.mFrTop, false)
        CS.ShowObject(self.mThTop, false)
        CS.ShowObject(self.mKoTop, false)
        CS.ShowObject(self.mJaTop, false)
    else
        local payDiNum = nextExp - serVipExp
        if payDiNum < 0 then
            payDiNum = 1
        end
        payDiNum = LUtil.FormatHurtNumSpriteText(payDiNum, false)
        local languageFlag = gLGameLanguage:GetLanguageFlag()
        local nextStr = LUtil.FormatHurtNumSpriteText(nextVip, false)
        local isForeignEn = languageFlag == "enus"
        local isForeignVie = languageFlag == "vie"
        local isForeignDe = languageFlag == "de"
        local isForeignFr = languageFlag == "fr"
        local isForeignTh = languageFlag == "th"
        local isForeignKo = languageFlag == "kr"
        local isForeignJa = languageFlag == "ja"

        --if isForeignJa then
        --    nextStr = self:GetVipNumFormatSpriteTextOnlyJapan(nextVip)
        --end

        local root = nil
        local isForeignRegion = gLGameLanguage:IsForeignRegion()
        if isForeignRegion then
            root = self.mEnTop
            CS.ShowObject(self.mTop, false)
        else
            root = self.mTop
        end

        local TitleImg1 = self:FindWndTrans(root,"TitleImg1")
        local TitleImg2 = self:FindWndTrans(root,"TitleImg2")
        local payCom = self:FindWndTrans(TitleImg1, "PayNum")
        local nextCom = self:FindWndTrans(TitleImg2, "NextVipNum")
        self:SetWndText(payCom, payDiNum)

        --typeHorizontalLayoutGroup

        self._delaySetXTimer = LxTimer.DelayFrameCall(function()
            local layout = TitleImg1:GetComponent(typeHorizontalLayoutGroup)
            if layout then
                layout.padding.left = TitleImg1.sizeDelta.x
            end
            UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(TitleImg1)
            CS.ShowObject(root, true)
        end, 1)

        self:SetWndText(nextCom, nextStr)
        --self:SetXUITextText(self.mPayNum,payDiNum)
        --self:SetXUITextText(self.mNextVipNum,nextStr)
    end

    local tempCurExp = serVipExp - curExp
    local percentage = tempCurExp / needExp
    LxUiHelper.SetProgress(self.mVipLvBar, percentage)

    local icon = curRef.icon
    self:SetWndEasyImage(self.mVipLvIcon, icon)

    local str = string.format("%s/%s", tempCurExp, needExp)
    self:SetXUITextText(self.mVipLvExpTxt, str)

    --str = ccClientText(11902)
    --str = string.replace(str,vip)
    --self:SetXUITextText(self.mVipLvTxt,str)

    if self._openView == 1 then
        str = ccClientText(11900)
        str = string.replace(str, vip)
        if self._buyRefId == nil then
            self:SetXUITextText(self.mVipTitle, str)
        end
    end

    if self._isJapaness then
        local TitleImg1 = self:FindWndTrans(self.mEnTop, "TitleImg1")
        local group = TitleImg1:GetComponent("HorizontalLayoutGroup")
        local padding = group.padding
        padding.left = 80
        local TitleImg2 = self:FindWndTrans(self.mEnTop, "TitleImg2")
        local Image2 = self:FindWndTrans(self.mEnTop, "TitleImg2/Image (2)")
        local NextVipNum = self:FindWndTrans(self.mEnTop, "TitleImg2/NextVipNum")
        self:SetAnchorPos(TitleImg2,Vector2.New(-250,-14))
        self:SetAnchorPos(Image2,Vector2.New(120,-23))
        self:SetAnchorPos(NextVipNum,Vector2.New(170,-23))
    end

    if PRODUCT_G_VER ~= 2 and gLGameLanguage:IsJapanRegion() then
        --日本地区，添加法律条文一览
        local buyTipsText = ccClientText(36608)
        CS.ShowObject(self.mBuyTipsTextJa, true)
        self:SetWndText(self.mBuyTipsTextJa, buyTipsText)

        local text = ccClientText(36625)
        if not string.isempty(text) then
            self:SetWndText(self.mBuyTipsText, text)
            CS.ShowObject(self.mBuyTipsText, true)
            --self._helpTipsContent = text
            --CS.ShowObject(self.mBuyTipsBtn, true)
        end
    end
end

function UIHuiYPay:OnDrawType3(item, itemdata)
    local Bg = self:FindWndTrans(item, "Bg")
    local BgZSNum = self:FindWndTrans(Bg, "ZSNum")
    local BgGetDiv = self:FindWndTrans(Bg, "GetDiv")
    local GetDivImage = self:FindWndTrans(BgGetDiv, "Image")
    local GetDivGetNum = self:FindWndTrans(BgGetDiv, "GetNum")
    local BgPayNum = self:FindWndTrans(Bg, "PayNum")
    local BgIcon = self:FindWndTrans(Bg, "Icon")
    local BgImg = self:FindWndTrans(Bg, "Img")
    local BgBtn = self:FindWndTrans(Bg, "Btn")

    local data = itemdata.data
    self:SetWndEasyImage(BgIcon, data.icon)
    CS.ShowObject(BgZSNum, false)
    local welfareId = data.welfareId
    local str = gModelPay:GetShowByWelfareId(welfareId)
    self:SetWndText(BgPayNum, str)

    local itemGet = LxDataHelper.ParseItem_3(data.item)
    local img = gModelItem:GetItemIconByRefId(itemGet.itemId)

    str = ccLngText(data.name)

    self:SetWndText(GetDivGetNum, str)

    CS.ShowObject(BgGetDiv, true)
    self:SetWndEasyImage(GetDivImage, img)
    CS.ShowObject(GetDivImage, true)
    CS.ShowObject(BgImg, false)

    self:SetWndClick(BgBtn, function()
        self:OnClickGoods(itemdata)
    end)
    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(GetDivGetNum)
end

function UIHuiYPay:RefreshNewTag()
    local id = self._curSelectFunc
    local item = self._actvFuncList[id].item
    local tag = self:FindWndTrans(item, "tag")
    CS.ShowObject(tag, false)
end

function UIHuiYPay:InitSpecialActivityMsg()
    for k, v in pairs(self._specialEightLoginSid) do
        local pbData = gModelActivity:GetActivityPageBySid(v)
        if pbData then
            self:OnActivityPageResp(pbData)
        else
            gModelActivity:OnActivityPageReq(v)
        end
    end
end

function UIHuiYPay:ShowEveryDaySpine()
    local everyDay = self._everyDay
    local cardDay = self._cardDay
    if not everyDay then
        return
    end
    local serverData = self._vipGiftList[everyDay.refId]
    local state = serverData and serverData.state or 0
    local curServerData = serverData
    -- 月卡礼包和每日礼包绑定
    local type3Data = self._typeVipGiftList[self._lastbtn]
    local buyYueKa = false
    if type3Data then
        local type3RefId = type3Data.refId
        local type3ServerData = self._vipGiftList[type3RefId]
        if type3ServerData then
            local type3States = type3ServerData.state
            if state ~= 1 then
                -- 当前每日礼包不可以领取
                buyYueKa = true
                state = type3States
                curServerData = type3ServerData
            end
            if type3States == 1 then
                -- 月卡礼包可以领取
                state = type3States
                buyYueKa = state == 1
                curServerData = type3ServerData
            end
        end
    end

    if state == 1 then
        self:OpenDayGiftPop()
    end
    local eff = self:FindWndEffectByKey("fx_tehuishangdian")
    if eff then
        eff:SetVisible(state == 1)
    end
    self:SetRed(self.mImgBox, state == 1)
    -- local everyDaySpine = self._everyDaySpine
    -- if everyDaySpine then
    -- 	if state == 1 then self:OpenDayGiftPop() end
    -- 	self:PlayVIPChongzhiSpineAni(state)
    -- else
    -- 	everyDaySpine = self:CreateWndSpine(self.mEveryDaySpine,"VIPchongzhiwupo","VIPchongzhiwupo",false,function (dpSpine)
    -- 		if state == 1 then self:OpenDayGiftPop() end
    -- 		self:PlayVIPChongzhiSpineAni(state)
    -- 	end)
    -- 	self._everyDaySpine = everyDaySpine
    -- end

    self:SetWndClick(self.mImgBox, function()
        local refId = curServerData.refId
        local level = everyDay.level
        local buyType = everyDay.buyType

        if self._vip < level then
            local msg = string.replace(ccClientText(15908), level)
            GF.ShowMessage(msg)
            return
        end
        self:OpenDayGiftPop()
    end)
end

function UIHuiYPay:RefreshRed()
    for k, v in pairs(self._actvFuncList) do
        local item = v.item
        if CS.IsValidObject(item) then
            local redPoint = self:FindWndTrans(item, "redPoint")
            local showRed = gModelRedPoint:CheckActivityShowRed(k)

            if not v.itemdata.isNet then
                showRed =  gModelRedPoint:CheckShowRedPoint(v.itemdata.redPoint)
            end
            CS.ShowObject(redPoint, showRed)
            local tagShow = gModelActivity:IsActivityNew(v.itemdata.id, v.itemdata.isNet)
            local tag = self:FindWndTrans(item, "tag")
            CS.ShowObject(tag, tagShow and not showRed)
        end
    end
    local redType = gModelRedPoint:GetAcvityRedTypeByType(ModelActivity.TYPE_FIVE)
    local showRed = gModelRedPoint:CheckShowRedPoint(redType)
    local giftBtnRedPoint = self:FindWndTrans(self.mGiftBtn, "redPoint")
    CS.ShowObject(giftBtnRedPoint, showRed)
end

function UIHuiYPay:OnDrawType1(item, itemdata)
    local Bg = self:FindWndTrans(item, "Bg")
    local BgZSNum = self:FindWndTrans(Bg, "ZSNum")
    local BgGetDiv = self:FindWndTrans(Bg, "GetDiv")
    local GetDivImage = self:FindWndTrans(BgGetDiv, "Image")
    local GetDivGetNum = self:FindWndTrans(BgGetDiv, "GetNum")
    local BgPayNum = self:FindWndTrans(Bg, "PayNum")
    local BgIcon = self:FindWndTrans(Bg, "Icon")
    local BgImg = self:FindWndTrans(Bg, "Img")
    local BgBtn = self:FindWndTrans(Bg, "Btn")

    local data = itemdata.data
    self:SetWndEasyImage(BgIcon, data.icon1)
    CS.ShowObject(GetDivImage, false)
    CS.ShowObject(BgZSNum, false)

    local str = ccLngText(data.name)
    self:SetWndText(BgPayNum, str)

    str = ccLngText(data.desc)

    self:SetWndText(GetDivGetNum, str)
    local addSize = -2
    if gLGameLanguage:IsGermanVersion() then
        addSize = -6
    end
    self:InitTextSizeWithLanguage(GetDivGetNum, addSize)
    CS.ShowObject(BgGetDiv, true)

    self:SetWndEasyImage(BgImg, data.icon3, nil, true)
    CS.ShowObject(BgImg, true)

    self:SetWndClick(BgBtn, function()
        self:OnClickGoods(itemdata)
    end)
    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(GetDivGetNum)
end
function UIHuiYPay:RefreshVipShowList()
    local list = gModelVip:GetVipShowRef()
    local uiList = self._uiVipShowList
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll("UIHuiYPay_mShowCellScroll")
        self._uiVipShowList = uiList

        if self._isForeign then
            uiList:Create(self.mShowCellScrollEn, list, function(...)
                self:VipShowListItem(...)
            end)
        else
            uiList:Create(self.mShowCellScroll, list, function(...)
                self:VipShowListItem(...)
            end)
        end

        CS.ShowObject(self.mShowCellScroll, not self._isForeign)
        CS.ShowObject(self.mShowCellScrollEn, self._isForeign)
    end
    local len = #list
    uiList:EnableScroll(len > 3, false)
    if len <= 0 then
        return
    end
    -- local h = len <= 3 and len * 41 or 123
    local h = len <= 3 and len * 58 or 144

    if self._isForeign then
        self.mShowYesBgEn.sizeDelta = Vector2.New(342, h)
    else
        self.mShowYesBg.sizeDelta = Vector2.New(200, h)
        -- self.mShowYesBg.sizeDelta = Vector2.New(296,h)
    end
end

-- 页签按钮处理
function UIHuiYPay:OnDrawBtn(list, item, itemdata, itempos)
    local btnTrans = self:FindWndTrans(item, "Btn")
    if btnTrans then
        local index = itemdata.level
        local refId = itemdata.refId
        local VipLvTrans = self:FindWndTrans(btnTrans, "VipLv")
        if VipLvTrans then
            self:SetWndText(VipLvTrans, string.replace(ccClientText(11900), index))-- LUtil.FormatHurtNumSpriteText())
        end
        local BtnNameTrans = self:FindWndTrans(btnTrans, "ImgNameBg/BtnName")
        if BtnNameTrans then
            self:SetWndText(BtnNameTrans, ccLngText(itemdata.tabDesc))
            CS.ShowObject(BtnNameTrans, true)

            if self._isJapaness then
                LxUiHelper.SetSizeWithCurAnchor(BtnNameTrans, 1, 30)
            end
        end

        local btnList = self._btnTabList
        btnList[index] = btnTrans
        self:SetWndClick(btnTrans, function()
            self:BtnEvent(refId, index)
        end)
        local SelImg = self:FindWndTrans(btnTrans, "SelImg")
        local IconImg = self:FindWndTrans(btnTrans, "Icon")
        local ImgLock = self:FindWndTrans(btnTrans, "ImgLock")
        CS.ShowObject(ImgLock, index > self._vip)
        if IconImg then
            local titleIcon = itemdata.titleIcon
            self:SetWndEasyImage(IconImg, titleIcon, nil, true)
        end
        local redPointTrans = self:FindWndTrans(btnTrans, "redPoint")
        if redPointTrans then
            local refData = self._vipLvGiftList[index]
            local status = false
            if refData then
                for k, v in pairs(refData) do
                    if status then
                        break
                    end
                    -- 特权礼包不加红点显示
                    if v.type == 2 or v.type == 3 then
                        if self._vipGiftList[v.refId] then
                            status = self._vipGiftList[v.refId].state == 1
                        end
                    else
                        local buyNeed = v.buyNeed
                        if not string.isempty(buyNeed) then
                            if self._vipGiftList[v.refId] and self._vipGiftList[v.refId].state ~= 2 then
                                buyNeed = string.split(buyNeed, "=")
                                status = tonumber(buyNeed[3]) == 0
                            end
                        else
                            if self._vipGiftList[v.refId] and self._vipGiftList[v.refId].state ~= 2 then
                                status = true
                            end
                        end
                    end
                end
            end
            self._redPointTransList[index] = redPointTrans
            --CS.ShowObject(redPointTrans,self._vipGiftList[refId] and self._vipGiftList[refId].state == 1)
            CS.ShowObject(redPointTrans, status)
        end
        self:ChangeBtnImage(index, SelImg)
    end
end

function UIHuiYPay:OnDrawType2(item, itemdata)
    local Bg = self:FindWndTrans(item, "Bg")
    local BgZSNum = self:FindWndTrans(Bg, "ZSNum")
    local BgGetDiv = self:FindWndTrans(Bg, "GetDiv")
    local BgGetDivExtra = self:FindWndTrans(Bg, "GetDivExtra")
    local GetDivImage = self:FindWndTrans(BgGetDiv, "Image")
    local GetDivGetNum = self:FindWndTrans(BgGetDiv, "GetNum")
    local BgPayNum = self:FindWndTrans(Bg, "PayNum")
    local BgIcon = self:FindWndTrans(Bg, "Icon")
    local BgImg = self:FindWndTrans(Bg, "Img")
    local BgBtn = self:FindWndTrans(Bg, "Btn")
    local exp = self:FindWndTrans(Bg, "Exp")
    local expText = self:FindWndTrans(Bg, "Exp/Text")

    local data = itemdata.data

    if PRODUCT_G_VER and PRODUCT_G_VER ~= 0 then
        if gLGameLanguage:CheckIsUseSpecialProduct() then
            local packId = gLGameLanguage:GetPackProductInfo()
            local colorInfo = gLGameLanguage:GetVipColorInfo(packId, "vipBtnBg")
            self:SetWndImageColor(Bg, Color.New(checknumber(colorInfo[1]) / 255, checknumber(colorInfo[2]) / 255, checknumber(colorInfo[3]) / 255, 1))
            --if packId == 1 then
            --    self:SetWndImageColor(Bg, Color.New(217 / 255, 210 / 255, 14 / 255, 1))
            --elseif packId == 2 then
            --    self:SetWndImageColor(Bg, Color.New(130 / 255, 239 / 255, 112 / 255, 1))
            --elseif packId == 3 then
            --    self:SetWndImageColor(Bg, Color.New(255 / 255, 112 / 255, 234 / 255, 1))
            --end
        end
        if self._tiShen then
            self:SetWndImageColor(Bg, Color.New(77 / 255, 197 / 255, 210 / 255, 1))
        end
    end

    if gLGameLanguage:IsJapanVersion() then
        self:InitTextSizeWithLanguage(GetDivGetNum, -2)
    end
    self:SetWndEasyImage(BgIcon, data.icon)
    CS.ShowObject(GetDivImage, true)
    CS.ShowObject(BgZSNum, false)
    --self:SetWndText(BgZSNum,ccLngText(data.name))
    local welfareId = data.welfareId
    local str = gModelPay:GetShowByWelfareId(welfareId)
    self:SetWndText(BgPayNum, str)

    if data.vip then
        self:SetWndText(expText, "+" .. data.vip)
        CS.ShowObject(exp, true)
    else
        CS.ShowObject(exp, false)
    end

    local first = data.first
    local getDiamonds = data.getDiamonds
    local firstStr = first
    local getDiamondsStr = getDiamonds
    local firstItemData, getDiamondsItemData
    if string.find(first, '=') then
        firstItemData = LxDataHelper.ParseItem_4(first)
        firstStr = firstItemData.itemNum
    end

    if string.find(getDiamonds, '=') then
        getDiamondsItemData = LxDataHelper.ParseItem_4(getDiamonds)
        getDiamondsStr = getDiamondsItemData.itemNum
    end

    local serverData = self._shopList[data.refId]
    local haveExtra = serverData and serverData.flag
    if haveExtra then
        str = ccClientText(11921)
        str = string.replace(str, firstStr)
        str = getDiamondsStr .. str
    else
        str = getDiamondsStr
    end

    CS.ShowObject(BgGetDiv, true)
    -- if gLGameLanguage:IsJapanVersion() then
    --     str = getDiamondsStr
    --     if getDiamondsItemData then
    --         local icon = gModelItem:GetItemIconByRefId(getDiamondsItemData.itemId)
    --         if LxUiHelper.IsImgPathValid(icon) then
    --             self:SetWndEasyImage(GetDivImage, icon)
    --         end
    --     end

    --     local iconSize = self._extraIconSize.COMMON
    --     local iconPos = self._extraIconPos.COMMON
    --     if haveExtra then
    --         local GetDivImageExtra = self:FindWndTrans(BgGetDivExtra, "Image")
    --         local GetDivGetNumExtra = self:FindWndTrans(BgGetDivExtra, "GetNum")
    --         local GetDivGetDescExtra = self:FindWndTrans(BgGetDivExtra, "GetDesc")
    --         self:SetWndText(GetDivGetDescExtra, ccClientText(11933))
    --         self:SetWndText(GetDivGetNumExtra, firstStr)
    --         if firstItemData then
    --             local icon = gModelItem:GetItemIconByRefId(firstItemData.itemId)
    --             if LxUiHelper.IsImgPathValid(icon) then
    --                 self:SetWndEasyImage(GetDivImageExtra, icon)
    --             end
    --         end

    --         iconSize = self._extraIconSize.EXTRA
    --         iconPos = self._extraIconPos.EXTRA
    --     end

    --     CS.ShowObject(BgGetDivExtra, haveExtra)
    --     CS.ShowObject(BgGetDivExtra, haveExtra)
    --     CS.ShowObject(BgGetDiv, not haveExtra)
    --     BgIcon.localScale = iconSize
    --     self:SetAnchorPos(BgIcon, iconPos)
    -- end

    self:SetWndText(GetDivGetNum, str)

    local showImg, imgPth
    local serverData = self._shopList[data.refId]
    if serverData and serverData.flag then
        showImg = true
        imgPth = "vip_txt_3"
    else
        showImg = false
    end

    if showImg then
        self:SetWndEasyImage(BgImg, imgPth, nil, true)
    end

    if PRODUCT_G_VER and PRODUCT_G_VER ~= 0 then
        if self._isSEA then
            local packId = LGameLanguage:GetPackProductInfo()
            if packId == 1 then

            elseif packId == 2 then
                if self._isEnus then
                    showImg = false
                end
            end
        end
    end

    CS.ShowObject(BgImg, showImg)

    self:SetWndClick(BgBtn, function()
        self:OnClickGoods(itemdata)
    end)
    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(GetDivGetNum)
end

function UIHuiYPay:OnClickByTipsJapan()
    local title = ccClientText(36608)
    GF.OpenWnd("UIBzListTips", { title = title, refIdList = { 801, 802 } })
end

function UIHuiYPay:VersionRefresh()
    --- 叶师傅说这个去掉ios送审屏蔽
    local isShow = gModelFunctionOpen:CheckIsShow(15101040)
    --[[	if PRODUCT_G_VER == 1 then --ios 屏蔽
        end]]
    CS.ShowObject(self.mGiftBtn, isShow)
end

function UIHuiYPay:ViewCtrl()
    for i, v in ipairs(self._btnList) do
        local bSel = i == self._openView
        self:SetWndTabStatus(v, bSel and LWnd.StateOn or LWnd.StateOff)
    end

    self:WndRemoveScrllByKey(self._btnListKeyStr)
    self._uiBtnList = nil
    self:CloseAllChild()

    if self._openView == 1 or self._openView == 2 then
        self:ShowPage(true)
        if self._openView == 1 then
            gModelPay:OnVipGiftListReq()
        elseif self._openView == 2 then
            gModelPay:OnFirstChargeInfoReq()
        end
        for i, v in ipairs(self._viewList) do
            CS.ShowObject(v, i == self._openView)
        end
    else
        self._curSelectFunc = nil
        self:ShowPage(false)
        self:InitActivityGiftList()
    end
end

function UIHuiYPay:OpenCustomGift(sid)
    self:CreateChildWnd(self.mChildRoot, "UISubCumGift", { sid = sid })
end

function UIHuiYPay:OpenActivityChildWnd(itemdata)
    local curTime = GetTimestamp()
    gModelActivity:AddRecord(itemdata.id, curTime, itemdata.isNet)
    self:RefreshNewTag()
    local model = nil
    local sid = itemdata.id
    if itemdata.isNet then
        local activityData = gModelActivity:GetActivityBySid(sid)
        if activityData then
            model = activityData.model

            --gLxTKData:OnWebActivityClick(activityData)
        end
    else
        local cfg = gModelActivity:GetActivityFunsById(sid)
        model = cfg.eModel
        --gLxTKData:OnFuncActivityClick(cfg)
    end

    local openFunc = self._modelOpenFunc[model]
    if openFunc then
        self._subPage = itemdata.uniqueJump
        openFunc(sid)
    end

end

function UIHuiYPay:GetVipNumFormatSpriteTextOnlyJapan(num)
    local list = {}
    local fmtStr = "<sprite index=%s>"

    if num >= 10 then
        table.insert(list, "<sprite index=9>")
    end

    local endNum = num % 10
    if endNum > 0 then
        local index = endNum - 1
        local idxStr = string.replace(fmtStr, tostring(index))
        table.insert(list, idxStr)
    end

    return table.concat(list, "")
end

-- 修改底部按钮选中状态时的图片
function UIHuiYPay:ChangeBtnImage(index, SelImg)
    if index then
        local show = false
        if index == self._lastbtn then
            show = true
        end
        if SelImg then
            CS.ShowObject(SelImg, show)
        end
        if self._btnTabList[index] then
            local open = index <= self._vip
            local tabBg = (open and show) and "vip_cell_3" or (open and "vip_cell_1" or "vip_cell_2")
            self:SetWndEasyImage(self._btnTabList[index], tabBg)
        end
    else
        local btnList = self._btnTabList
        for k, v in pairs(btnList) do
            SelImg = self:FindWndTrans(v, "SelImg")
            local show = false
            if k == self._lastbtn then
                show = true
            end
            if SelImg then
                CS.ShowObject(SelImg, show)
            end
            local open = k <= self._vip
            local tabBg = (open and show) and "vip_cell_3" or (open and "vip_cell_1" or "vip_cell_2")
            self:SetWndEasyImage(v, tabBg)
        end
    end
end

function UIHuiYPay:OnClickByTips()
    if not self._helpTipsContent then
        return
    end

    local title = ccClientText(112)
    GF.OpenWnd("UIBzTips", { title = title, text = self._helpTipsContent })
end

function UIHuiYPay:InitData()
    self._vip = gModelPlayer:GetVipLevel()                            -- vip等级
    self._btnTabList = {}                                            -- 按钮列表
    self._vipGiftList = {}                                            -- 礼包列表
    self._shopList = {}                                            -- 商店列表

    self._btnList = { self.mVipBtn, self.mShopBtn, self.mGiftBtn }                    -- 切换按钮

    self._redPointTransList = {}
    self._viewList = { self.mView1, self.mView2, }                                                                -- 界面按钮
    self._btnRefId = 0                                                -- 当前的refId 					（仅VIP界面）
    self._lastbtn = 1                                                -- 当前的底部按钮下标			（仅VIP界面）
    self._buyRefId = nil                                            -- 购买的refId
    self._vipLvGiftList = gModelPay:GetVipLvGiftData()
    self._typeVipGiftList = gModelPay:GetVipTypeData()

    self._actvFuncList = {}

    self._selectIconPath = {
        --[1] = "activity_btn_off_1",
        --[2] = "activity_btn_on_1",

        [1] = "activity_icon_on",
        [2] = "activity_icon_on",
    }
    self._modelOpenFunc = {
        [ModelActivity.PRIVILEGE_SHOP] = function(...)
            self:OpenPrivilegeShop(...)
        end,
        [ModelActivity.MODEL_DAILYGIFTBAG] = function(...)
            self:OpenDailyGift(...)
        end,
        [ModelActivity.DAILY_GIFT_A] = function(...)
            self:OpenDailyGiftA(...)
        end,
        -- [ModelActivity.DAILY_GIFT_C] = function(...) self:OpenDailyGiftC(...) end,
        [ModelActivity.ACTIVITY_CUSTOMGIFT] = function(...)
            self:OpenCustomGift(...)
        end,
        [ModelActivity.TIME_WARDROBE] = function(...)
            self:OpenSkinShop(...)
        end,
        [ModelActivity.DREAM_SECRET] = function(...)
            self:OpenSecret(...)
        end,
        [ModelActivity.MODEL_ACTIVITY_TYPE_78] = function(...)
            self:OpenOverflowPrivilege(...)
        end,
    }

    self._redRefreshFunc = function()
        self:RefreshRed()
    end

    self:InitSpecialActivityData()

    self._giftBtnTextColor = {
        common = LUtil.ColorByHex("BAD0E3FF"),
        select = LUtil.ColorByHex("FFFFFFFF"),
    }


    --local isForeign = gLGameLanguage:IsForeignRegion()
    self._isForeign = isForeign
    self._vipShowToggleBgTrans = isForeign and self.mVipShowToggleBgEn or self.mVipShowToggleBg
    self._btnShowNoTrans = isForeign and self.mBtnShowNoEn or self.mBtnShowNo
    self._vipShowBgRoot = isForeign and self.mVipShowBgRootEn or self.mVipShowBgRoot

    if isForeign then
        CS.ShowObject(self.mVipShowToggleBg, false)
        CS.ShowObject(self.mVipShowBgRoot, false)
    else
        CS.ShowObject(self.mVipShowToggleBgEn, false)
        CS.ShowObject(self.mVipShowBgRootEn, false)
    end

    self._extraIconSize = {
        COMMON = Vector3.New(1, 1, 1),
        EXTRA = Vector3.New(0.9, 0.9, 1)
    }

    self._extraIconPos = {
        COMMON = Vector2.New(0, 42),
        EXTRA = Vector2.New(0, 60)
    }
end

function UIHuiYPay:ReSet(index)
    if PRODUCT_G_VER == 1 then
        index = 2 -- ios写死屏蔽
    end

    self._openView = index
    self._vip = gModelPlayer:GetVipLevel()                            -- vip等级
    self._btnRefId = 0                                                -- 当前的refId 					（仅VIP界面）
    self._lastbtn = 1                                                -- 当前的底部按钮下标			（仅VIP界面）
    self._btnTabList = {}                                            -- 按钮列表
    self._vipGiftList = {}                                            -- 礼包列表
    self._shopList = {}                                            -- 商店列表
    self:ViewCtrl()
    self:InitText()
    self:InitBtnList()
end

function UIHuiYPay:OnDrawGiftActivityItem(list, item, itemdata, itempos)
    local select = self:FindWndTrans(item, "select")
    local icon = self:FindWndTrans(item, "icon")
    local UITextTrans = self:FindWndTrans(item, "UIText")
    local UIText = self:FindWndText(UITextTrans)
    local tag = self:FindWndTrans(item, "tag")
    local redPoint = self:FindWndTrans(item, "redPoint")
    local isNewActivity = false
    local id = itemdata.id
    local isSelect = self._curSelectFunc == id
    local textColor = isSelect and self._giftBtnTextColor.select or self._giftBtnTextColor.common
    self:InitTextSizeWithLanguage(UITextTrans, -2)
    local addLine = -50
    if gLGameLanguage:IsKoreaVersion() then
        addLine = -30
    end
    self:InitTextLineWithLanguage(UITextTrans, addLine)

    if itemdata.isNet then
        local activityData = gModelActivity:GetActivityBySid(id)
        if activityData then
            local title = activityData.title
            self:SetXUITextText(UIText, title)
            local iconPath = activityData.icon
            if LxUiHelper.IsImgPathValid(iconPath) then
                self:SetWndEasyImage(icon, iconPath)
            end
        end

        isNewActivity = gModelActivity:IsActivityNew(id, true, true)
    else
        local cfg = gModelActivity:GetActivityFunsById(id)
        local iconPath = cfg.icon
        if iconPath then
            self:SetWndEasyImage(icon, iconPath)
        end

        local name = ccLngText(cfg.name)
        self:SetXUITextText(UIText, name)
        isNewActivity = gModelActivity:IsActivityNew(id, false, true)
    end

    --self:SetXUITextColor(UIText,textColor)
    CS.ShowObject(tag, isNewActivity)

    local showRed = gModelRedPoint:CheckActivityShowRed(id)


    if not itemdata.isNet then
        showRed =  gModelRedPoint:CheckShowRedPoint(itemdata.redPoint)
    end
    if showRed then
        printInfoN2("-0-","-")

    end
    CS.ShowObject(redPoint, showRed)

    local index = isSelect and 2 or 1

    CS.ShowObject(select, isSelect)

    self:SetWndEasyImage(select, self._selectIconPath[index])
    self:SetWndClick(item, function()
        LxUiHelper.FilterScrollItem(self.mGiftBtnList, itempos - 1)

        self:OnClickActivFunc(itemdata)
        self:SendTaInfo()
    end, LSoundConst.CLICK_PAGE_COMMON)

    self._actvFuncList[id] = { item = item, itemdata = itemdata }
end

function UIHuiYPay:OnClickGoods(itemdata)
    local type = itemdata.type
    local data = itemdata.data
    if type == 1 then
        local eightShowSid = self._specialEightLoginShowSid
        if itemdata.isEightAct then
            --对八天登录做特殊处理，元宵特惠也应能跳
            GF.OpenWndUp("UI8Login", { sid = eightShowSid, page = 2 })
        else
            local jumpId = data.jump
            gModelFunctionOpen:Jump(jumpId, self:GetWndName(), self._jumpCallback)
        end
    elseif type == 2 then
        self:BuyGift(data.refId)
    elseif type == 3 then
        gModelPay:GiftPayCtrl(data.refId, data.welfareId, ModelPay.PAY_TYPE_GOLD_TICKET)
    end

end
function UIHuiYPay:SendTaInfo()
    if not self._curSelectFunc then
        return
    end

    local itemdata = self._actvFuncList and self._actvFuncList[self._curSelectFunc]
    if not itemdata then
        return
    end

    local actData = itemdata.itemdata

    local sid = actData.id
    if actData.isNet then
        local activityData = gModelActivity:GetActivityBySid(sid)
        if activityData then
            gLxTKData:OnWebActivityClick(activityData)
        end
    else
        local cfg = gModelActivity:GetActivityFunsById(sid)
        if cfg then
            gLxTKData:OnFuncActivityClick(cfg)
        end
    end
end

function UIHuiYPay:OnDrawGiftItem(list, item, itemdata, itempos)
    local rootTrans = self:FindWndTrans(item, "Root")
    local rewardList = string.split(itemdata, "=")

    local itype, refId, num = tonumber(rewardList[1]), tonumber(rewardList[2]), tonumber(rewardList[3])

    local iconTrans = self:FindWndTrans(rootTrans, "CommonUI/Icon")
    local instanceId = item:GetInstanceID()
    local baseClass = self._commonIconTbl[instanceId]
    if not baseClass then
        baseClass = CommonIcon:New()
        self._commonIconTbl[instanceId] = baseClass
        baseClass:Create(iconTrans)
    end
    baseClass:SetCommonReward(itype, refId, num)
    --baseClass:EnableShowNum(false)
    baseClass:DoApply()

    self:SetIconClickScale(iconTrans, true)
    self:SetWndClick(iconTrans, function()
        local data = { itemId = refId, itemType = itype, itemNum = num }
        gModelGeneral:ShowCommonItemTipWnd(data)
    end)

    --local NumTxtTrans = self:FindWndTrans(item,"NumTxt")
    --if NumTxtTrans then
    --	self:SetWndText(NumTxtTrans,LUtil.NumberCoversion(num))
    --end
    --local YueKaImgTrans = self:FindWndTrans(item,"YueKaImg")
    --if YueKaImgTrans then
    --	if rewardList[4] then
    --		self:SetWndEasyImage(YueKaImgTrans,"vip_txt_5")
    --		CS.ShowObject(YueKaImgTrans,true)
    --	else
    --		CS.ShowObject(YueKaImgTrans,false)
    --	end
    --end
end

function UIHuiYPay:GetBtnData()
    local ref = {}
    for k, v in pairs(GameTable.PremiumLevelRef) do
        local showNeedVip = v.showNeedVip
        if self._vip >= showNeedVip then
            table.insert(ref, v)
        end
    end
    table.sort(ref, function(ref1, ref2)
        return ref1.sort < ref2.sort
    end)
    return ref
end

function UIHuiYPay:RefreshGiftActivity()
    if self._openView == 3 then
        self:InitActivityGiftList()
    end
end

function UIHuiYPay:OnWndRefresh()
    self:SetWndPara()
    self:ViewCtrl()
end

--------------------------------- 商店数据 ---------------------------------
--------------------------------- 描述数据 ---------------------------------
--------------------------------- 商店数据 ---------------------------------
--------------------------------- 描述数据 ---------------------------------
function UIHuiYPay:InitDescList()
    local uiList = self._uiDescList
    if not uiList then
        uiList = UIListEasy:New()
        uiList:Create(self, self.mDescList)
        uiList:EnableScroll(true, false)
        uiList:SetFuncOnItemDraw(function(...)
            self:OnDrawDescItem(...)
        end)
        self._uiDescList = uiList
    end
    uiList:RemoveAll()
    local list = gModelPay:GetVipDescListByVipLv(self._lastbtn)
    for i, v in ipairs(list) do
        uiList:AddData(i, v)
    end
    uiList:RefreshList()
end

-- 页签按钮列表
function UIHuiYPay:InitBtnList(network)
    --[[	local uiBtnList = self._uiBtnList
        if not uiBtnList then
            uiBtnList = UIListEasy:New()
            uiBtnList:Create(self,self.mTypeBtnList)
            uiBtnList:EnableScroll(true,true)
            uiBtnList:SetFuncOnItemDraw(function(...)
                self:OnDrawBtn(...)
            end)
            self._uiBtnList = uiBtnList
        end
        uiBtnList:RemoveAll()
        local ref = {}
        for k,v in pairs(GameTable.PremiumLevelRef) do
            local showNeedVip = v.showNeedVip
            if self._vip >= showNeedVip then table.insert(ref,v) end
        end
        table.sort(ref,function(ref1,ref2) return ref1.sort < ref2.sort end)
        for i,v in ipairs(ref) do uiBtnList:AddData(v.refId,v) end
        self._lastbtn = self._vip
        self._btnRefId = ref[1].refId
        uiBtnList:RefreshList()
        if not network then
            uiBtnList:DelayScrollTo(self._lastbtn)
        end]]

    local ref = self:GetBtnData()
    self._lastbtn = self._vip
    self._btnRefId = ref[1].refId

    local typeBtnList = self._isEnus and self.mTypeBtnList_En or self.mTypeBtnList

    local uiBtnList = self._uiBtnList
    if not uiBtnList then
        uiBtnList = self:GetUIScroll(self._btnListKeyStr)
        self._uiBtnList = uiBtnList
        uiBtnList:Create(typeBtnList, ref, function(...)
            self:OnDrawBtn(...)
        end, UIItemList.NORMAL, false)
        uiBtnList:EnableScroll(true, false)
    else
        uiBtnList:RefreshData(ref, true)
    end

    CS.ShowObject(typeBtnList, true)

    local uiList = uiBtnList:GetList()
    uiList:RefreshList()
    self._delayUpdateScrollTimer = LxTimer.DelayFrameCall(function()
        uiList:ScrollToIndex(math.max(self._lastbtn, 1))
    end, 1)
end

-- 奖励初始化列表
function UIHuiYPay:RefreshGiftCell(trans, data, giftType)
    local giftRewardList = string.split(data, ",")
    local instanceId = trans:GetInstanceID()
    local key = "_giftCell" .. tonumber(instanceId)
    local uiList = self:FindUIScroll(key)
    if not uiList then
        uiList = self:GetUIScroll(key)
        uiList:Create(trans, giftRewardList, function(...)
            self:OnDrawGiftItem(...)
        end)
        uiList:EnableScroll(true, true)
    else
        uiList:RefreshList(giftRewardList)
    end
end
---------------------------------------- 礼包 --------------------------------------
function UIHuiYPay:InitActivityGiftList()
    self._actvFuncList = {}

    local list = gModelActivity:GetActivityIdByType(ModelActivity.TYPE_FIVE)

    local select = nil
    if self._subPage then
        for k, v in ipairs(list) do
            if self._subPage == v.uniqueJump then
                select = v
                break
            end
        end

    end
    if not select then
        select = list[1]
    end

    if self._activityGiftList then
        self._activityGiftList:RefreshList(list)
    else
        self._activityGiftList = self:GetUIScroll("activityGiftList")
        self._activityGiftList:Create(self.mGiftBtnList, list, function(...)
            self:OnDrawGiftActivityItem(...)
        end)
        self._activityGiftList:EnableScroll(true, true)
    end

    if not self._curSelectFunc and select then
        self:OnClickActivFunc(select)
    end

    if self._redRefreshFunc then
        self:ReleaseRedPointSingleFunc(ModelRedPoint.ACTIVITY_FIVE, self._redRefreshFunc)
        self:RegisterRedPointFunc(ModelRedPoint.ACTIVITY_FIVE, self._redRefreshFunc)
    end
end

function UIHuiYPay:PlayVIPChongzhiSpineAni(state)
    if not self._everyDaySpine then
        return
    end
    local showEff = state == 1
    local idle = showEff and "idle2" or "idle1"
    self._everyDaySpine:PlayAnimationSolid(idle, true)
    CS.ShowObject(self.mEveryDayEffect, showEff)
end
function UIHuiYPay:VipShowListItem(list, item, itemdata, itempos)
    local root = self:FindWndTrans(item, "Root")
    local text = self:FindWndTrans(root, "Text")
    local checkmark = self:FindWndTrans(root, "Toggle/Background/Checkmark")

    local arr = gModelPlayer:GetPlayerShieldArr() or {}
    local boolValue = arr[itemdata.refId] or "0"

    self:SetWndText(text, ccLngText(itemdata.desc))
    CS.ShowObject(checkmark, boolValue == "1")

    self:SetWndClick(root, function()
        self:OnClickVipShowCell(itemdata, boolValue)
    end)
end

function UIHuiYPay:OpenDayGiftPop()
    local everyDay = self._everyDay
    local cardDay = self._cardDay
    if not everyDay then
        return
    end
    local giftReward = LxDataHelper.ParseItem(everyDay.giftReward)
    if not giftReward or #giftReward < 1 then
        if LOG_ERROR_ENABLED then
            printError("vip界面","giftReward 字段为空")
        end
        return
    end

    local serverData = self._vipGiftList[everyDay.refId]
    local state = serverData and serverData.state or 0
    local curServerData = serverData
    -- 月卡礼包和每日礼包绑定
    local type3Data = self._typeVipGiftList[self._lastbtn]
    local buyYueKa = false
    if type3Data then
        local type3RefId = type3Data.refId
        local type3ServerData = self._vipGiftList[type3RefId]
        if type3ServerData then
            local type3States = type3ServerData.state
            if state ~= 1 then
                -- 当前每日礼包不可以领取
                buyYueKa = true
                state = type3States
                curServerData = type3ServerData
            end
            if type3States == 1 then
                -- 月卡礼包可以领取
                state = type3States
                buyYueKa = state == 1
                curServerData = type3ServerData
            end
        end
    end

    local refId = curServerData.refId
    local level = everyDay.level
    local buyType = everyDay.buyType

    if cardDay then
        local cardGiftReward = LxDataHelper.ParseItem(cardDay.giftReward) or {}
        for i, v in ipairs(cardGiftReward) do
            local data = {
                itemType = v.itemType,
                itemId = v.itemId,
                itemNum = v.itemNum,
                isShowEff = v.isShowEff,
                isMask = true
            }
            table.insert(giftReward, data)
        end
    end
    local desFunc = nil
    local isBuyCard = self:IsBuyCard()
    if not isBuyCard then
        desFunc = function()
            self:GoToActivityWnd()
        end
    end
    local getFunc = function()
        if buyYueKa then
            if state == 1 then
                -- 月卡可领取
                self:BuyGift(refId)
            else
                -- 前往充值月卡
                self:GoToActivityWnd()
            end
        else
            -- 购买礼包(每日和特权礼包)
            self:BuyGift(refId, buyType)
        end
    end
    local btnStr = not buyYueKa and ccClientText(12006) or ccClientText(15803)
    local desStr = isBuyCard and ccClientText(11929) or ccClientText(11930)
    local para = {
        title = string.replace(ccClientText(11927), level),
        des = string.replace(ccClientText(11928), desStr),
        rewardList = giftReward,
        desFunc = desFunc,
        getFunc = getFunc,
        btnStr = btnStr,
        isMask = isBuyCard and curServerData.state == 2
    }
    GF.OpenWnd("UIHuiYEveryDayGiftPop", { para = para })
end
--------------------------------- 描述数据 ---------------------------------
--------------------------------- 描述数据 ---------------------------------
--------------------------------- 底部按钮 ---------------------------------
-- 页签按钮事件
function UIHuiYPay:BtnEvent(refId, index)
    if index == self._lastbtn then
        return
    end
    print("---- refId,index = ", refId, index)
    self._btnRefId = refId
    -- 按钮背景换颜色
    self._lastbtn = index

    local str = ccClientText(11900)
    str = string.replace(str, index)
    self:SetXUITextText(self.mVipTitle, str)

    self:InitDescList()
    self:ChangeBtnImage()
    self:InitGiftList()
end

function UIHuiYPay:OnActivityPageResp(pb, ret)
    local sid = pb.sid
    local curDay = self._eightDayList[sid]
    if not curDay then
        return
    end

    local haveActive = self._specialEightLoginSid[sid]
    if not haveActive then
        return
    end

    for k, v in ipairs(pb.pages or {}) do
        local pageId = v.pageId
        if pageId == 2 then
            --八日登录界面的 限时礼包页
            self._eightPageList[sid] = v
        end
    end

    for k, v in pairs(self._eightPageList) do
        for p, q in ipairs(v.entry) do
            local moreInfo = q.moreInfo
            local status = q.status or q.goalData.status  --(0-不可领取, 1-可领取，2-已领取)
            local personalGoal = q.MarketData.personalGoal
            if personalGoal == -1 then
                status = 1
            else
                local tmoreInfo = JSON.decode(moreInfo)
                tmoreInfo = string.split(tmoreInfo.descIcon, ",")
                local day = tonumber(tmoreInfo[3])
                if personalGoal - q.MarketData.personal <= 0 then
                    status = 2
                elseif day > curDay then
                    status = 0
                else
                    status = 1
                end
            end

            if status < 2 then
                --(有可领取 或 未购买)
                self._specialEightLoginShow = true
                self._specialEightLoginShowSid = sid
                break
            end
        end
    end

    if self._openView ~= 2 then
        return
    end
    self:InitShopList()
end

function UIHuiYPay:BuyGift(refId, buyType)
    print("=== refId = ", refId)
    local func = function()
        gModelPay:PayCtrl(refId, self._openView)
    end
    if self._openView == 1 then
        local VipRef = GameTable.PremiumGiftRef[refId]
        local oriPrice = VipRef.buyNeed
        if string.isempty(oriPrice) then
            func()
        else
            if buyType == 4 then
                local need = tonumber(oriPrice)
                local priceStr = ccClientText(11913)
                if need > 0 then
                    priceStr = gModelPay:GetShowByWelfareId(need)
                end
                local rewards = LxDataHelper.ParseItem(VipRef.giftReward)
                local buyFun = function()
                    gModelPay:GiftPayCtrl(refId, need, ModelPay.PAY_TYPE_GIFT, ModelPay.PAY_TYPE_9)
                end
                GF.OpenWndUp("UIGiftBuyPop", {
                    title = ccClientText(11926),
                    --desc = ccClientText(15502)..last,
                    payStr = priceStr,
                    --payItemId = not isFree and itemId or nil,
                    payFunc = buyFun,
                    itemList = rewards,
                })
                return
            end
            local payItemRefId = 102001
            local level = VipRef.level
            local giftReward = VipRef.giftReward
            oriPrice = string.split(oriPrice, "=")
            local payWay = oriPrice[2]
            local payNum = tonumber(oriPrice[3])
            if payNum == 0 then
                func()
            else
                local haveNum = gModelItem:GetNumByRefId(payItemRefId)
                if haveNum < payNum then
                    gModelGeneral:OpenGetWayWnd({ itemId = payItemRefId, srcWnd = self:GetWndName() })
                    return
                end
                if tonumber(payWay) == payItemRefId then
                    local itemList = {}
                    giftReward = string.split(giftReward, ",")
                    for i, v in ipairs(giftReward) do
                        local temp = string.split(v, "=")
                        local data = {
                            itype = tonumber(temp[1]),
                            refId = tonumber(temp[2]),
                            count = tonumber(temp[3]),
                        }
                        table.insert(itemList, data)
                    end
                    local payName = gModelItem:GetNameByRefId(payItemRefId)
                    payName = payNum .. payName
                    GF.OpenWnd("UIOrdinTip", { refId = 51401, func = func, para = { payName, level },
                                                 itemList = itemList, consume = { payNum, payItemRefId } })
                end
            end
        end
    else
        func()
    end
end

--------------------------------------------------------------------------------
return UIHuiYPay


