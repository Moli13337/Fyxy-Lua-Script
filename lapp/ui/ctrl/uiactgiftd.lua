---
--- Created by LCM.
--- DateTime: 2024/3/1 11:07:28
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActGiftD:LWnd
local UIActGiftD = LxWndClass("UIActGiftD", LWnd)


UIActGiftD.TYPE_BUY_FREE = 0
UIActGiftD.TYPE_BUY_ITEM = 1
UIActGiftD.TYPE_BUY_RMB = 2

UIActGiftD.SelGiftNum = 3
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActGiftD:UIActGiftD()
    self._timerKey = "_timerKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActGiftD:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActGiftD:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActGiftD:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
    self:SetWndText(self.mTxtClose, ccClientText(42010))
	self:InitEvent()
	--self:InitMsg()
	self:InitData()
    self:RefreshChildWnd()

    ----- 修改为父界面，下面函数不用
    --gModelActivity:ReqActivityConfigData(self._sid)
end

function UIActGiftD:CreateImmobilization(item,itemdata)
    local giftTransName
    for i = 1,UIActGiftD.SelGiftNum do
        local data = itemdata[i]
        local showGift = data ~= nil
        giftTransName = "Gift"..i .. "/BtnRoot"
        local giftTrans = self:FindWndTrans(item,giftTransName)
        if showGift and giftTrans then
            self:CreateGfit(giftTrans,data)
        end
        CS.ShowObject(giftTrans.parent,showGift)
    end
end

function UIActGiftD:OnActivityPageResp(pb)
    if self._sid ~= pb.sid then return end
    local activityData = self._activityData
    if not activityData then
        activityData = {}
        self._activityData = activityData
    end
    local sid = self._sid
    local page,pageId,entryId,items,goalData
    local entryCfg,MarketData
    local moreInfo,personal,personalGoal,buyNum,sellOut
    local pages = pb.pages or {}
    for i,v in ipairs(pages) do
        page = gModelActivity:GenerateActivePageDataFromPb(v)
        pageId = page.pageId
        local pageEntryList = {}
        for idx,val in ipairs(page.entry) do
            entryId = val.entryId
            entryCfg = gModelActivity:GetWebActivityEntryData(sid,val.pageId,entryId)
            if entryCfg then
                MarketData = val.MarketData
                personal,personalGoal = MarketData.personal,MarketData.personalGoal
                buyNum = personalGoal - personal
                sellOut = (buyNum > 0 or personalGoal == -1) and 1 or 0
                moreInfo = entryCfg.moreInfo
                items = LxDataHelper.ParseItem(entryCfg.reward)
                goalData = val.goalData
                table.insert(pageEntryList,{
                    entryId = entryId,
                    pageId = pageId,
                    title = entryCfg.name,
                    desc = entryCfg.description,
                    icon = entryCfg.icon,
                    items = items,
                    goalData = goalData,
                    status = goalData.status,
                    MarketData = MarketData,
                    moreInfo = moreInfo,
                    personalGoal = personalGoal,
                    personal = personal,
                    buyNum = buyNum,
                    sellOut = sellOut,
                    sort = entryCfg.sort,
                    jumpId = entryCfg.jumpId,
                    jumpDesc = entryCfg.jumpDesc,
                })
            end
        end
        activityData[pageId] = pageEntryList
    end

    local sortFunc = function(a,b)
        local sellOutA,sellOutB = a.sellOut,b.sellOut
        if sellOutA ~= sellOutB then
            return sellOutA > sellOutB
        end
        return a.sort < b.sort
    end
    for tPageId,entryList in pairs(activityData) do
        table.sort(entryList,sortFunc)
    end

    self:InitSelGiftList()
end

function UIActGiftD:CreateGfit(item,itemdata)
    local BgImgTrans = self:FindWndTrans(item,"BgImg")
    local BgTrans = self:FindWndTrans(item,"Bg")
    local BuyCountTrans = self:FindWndTrans(item,"BuyCount")
    local titleTrans = self:FindWndTrans(item,"title")

    local btnTrans = self:FindWndTrans(item,"btn")
    local btnTextTrans = self:FindWndTrans(btnTrans,"text")

    local btn1Trans = self:FindWndTrans(item,"btn1")
    local ContentTrans = self:FindWndTrans(btn1Trans,"Content")
    local IconImageTrans = self:FindWndTrans(ContentTrans,"Image")
    local btn1Text1Trans = self:FindWndTrans(ContentTrans,"text1")

    local rewardList1Trans = self:FindWndTrans(item,"rewardList1")
    local rewardList2Trans = self:FindWndTrans(item,"rewardList2")

    local DiscountImgTrans = self:FindWndTrans(item,"DiscountImg")
    local DiscountTxtTrans = self:FindWndTrans(DiscountImgTrans,"DiscountTxt")

    local redPointTrans = self:FindWndTrans(item,"redPoint")

    local EffRootTrans = self:FindWndTrans(item,"EffRoot")

    local ShowZSImgTrans = self:FindWndTrans(item,"ShowZSImg")
    local ZSNumTrans = self:FindWndTrans(ShowZSImgTrans,"ZSNum")

    local maskTrans = self:FindWndTrans(item,"mask")
    local ShowTrans = self:FindWndTrans(item,"Show")

    local buyNum = itemdata.buyNum
    local valuePercent  = itemdata.valuePercent			-- 价格百分比
    local isHave = not string.isempty(valuePercent) and buyNum > 0 or false
    if isHave then
        local show = true
        if valuePercent == "0" then show = false end
        if show then
            self:SetWndText(DiscountTxtTrans,valuePercent)
        end
        isHave = show
    end
    CS.ShowObject(DiscountImgTrans,isHave)

    local dataTableData = string.split(itemdata.moreInfo,";")
    local zsNum = tonumber(dataTableData[5])
    local showZSImg = zsNum and zsNum ~= 0 or false
    if showZSImg then
        self:SetWndText(ZSNumTrans,zsNum)
    end
    CS.ShowObject(ShowZSImgTrans,showZSImg)


    self:SetWndEasyImage(BgTrans,itemdata.desc,function()
        CS.ShowObject(BgTrans,true)
    end,true)

    local buyCountText = string.replace(ccClientText(20810), buyNum)
    self:SetWndText(BuyCountTrans,buyCountText)
    self:SetWndText(titleTrans,itemdata.title)
    CS.ShowObject(BuyCountTrans,itemdata.personalGoal~=-1)
    local itemList = itemdata.commonGiftList
    local showMaxList = #itemList > 3
    local RewardList = showMaxList and rewardList2Trans or rewardList1Trans
    local hideRewardListTrans = showMaxList and rewardList1Trans or rewardList2Trans
    CS.ShowObject(RewardList,true)
    CS.ShowObject(hideRewardListTrans,false)
    self:InitRewardList(RewardList,itemList,showMaxList)

    local itemFunc
    local showBtnTrans = false
    local showBtn1Trans = false
    local buyEmpty = buyNum <= 0 and itemdata.personalGoal~=-1
    if not buyEmpty then
        local expendType
        local expend2 = itemdata.expend2
        if expend2 == "-1" then
            expendType = UIActGiftD.TYPE_BUY_FREE
            showBtnTrans = true
            self:SetWndText(btnTextTrans,ccClientText(11913))
        else
            local expend2List = string.split(expend2,"=")
            if #expend2List > 1 then
                expendType = UIActGiftD.TYPE_BUY_ITEM
                showBtn1Trans = true
                local itemId = tonumber(expend2List[2])
                local itemNum = tonumber(expend2List[3])
                local icon = gModelItem:GetItemImgByRefId(itemId)
                self:SetWndEasyImage(IconImageTrans,icon)
                self:SetWndText(btn1Text1Trans,LUtil.NumberCoversion(itemNum))
            else
                expendType = UIActGiftD.TYPE_BUY_RMB
                showBtnTrans = true
                local payMoney = gModelPay:GetShowByWelfareId(tonumber(expend2))
                self:SetWndText(btnTextTrans,payMoney)
            end
        end

        local InstanceID = EffRootTrans:GetInstanceID()
        self:DestroyWndEffectByKey(InstanceID)
        if expendType == UIActGiftD.TYPE_BUY_FREE then
            local bgEff = "fx_libaomianfeilingqu"
            self:CreateWndEffect(EffRootTrans,bgEff,InstanceID,100,false,false)
        end
        itemFunc = function()
            self:OnClickGiftBtnFunc(itemdata,expendType)
        end
    end

    self:SetWndClick(item,function()
        if itemFunc then itemFunc() end
    end)
    CS.ShowObject(btnTrans,showBtnTrans)
    CS.ShowObject(btn1Trans,showBtn1Trans)
    CS.ShowObject(ShowTrans,buyEmpty)
    CS.ShowObject(maskTrans,buyEmpty)
end

function UIActGiftD:OpenCommonItemTipsWnd(itemdata)
    gModelGeneral:ShowCommonItemTipWnd(itemdata)
end

function UIActGiftD:GetCustomList(customGiftList,status)
    local list = {}
    for i,v in ipairs(customGiftList or {}) do
        v.status = status
        v.customType = true
        table.insert(list,v)
    end
    return list
end

function UIActGiftD:InitEvent()
    self:SetWndClick(self.mReturnBtn,function() self:WndCloseAndBack() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mHelpBtn,function() self:OnClickHelpBtnFunc() end)
end

function UIActGiftD:InitData()
    local sid = self:GetWndArg("sid")
    local subPage = self:GetWndArg("subPage")
    if subPage then
        sid = gModelActivity:GetSidByUniqueJump(subPage)
    end
    self._sid = sid

    self:InitChildList()

    self:InitActData()
end

function UIActGiftD:OnActivityConfigData(data,sid)
    if sid ~= self._sid then return end
    local activityWebData = gModelActivity:GetWebActivityDataById(self._sid)
    if not activityWebData then return end
    local activityData = gModelActivity:GetActivityBySid(self._sid)
    if not activityData then return end

    local config = activityWebData.config

    if(config.itemId)then
        self:SetCurrencyGroup(config.itemId)
    end
    CS.ShowObject(self.mCurrencyGroup,config.itemId~=nil)
    self:TimerStop(self._timerKey)

    local color = config.timeTxtColor or "ffffff"
    self._timeTextColor = "#"..color

    local showEndTime = config.endTime or 0
    local showEnd = showEndTime == 1
    if showEnd then
        local endTime = activityData.endTime
        if endTime == 0 then
            -- 永久生效
            self:SetWndText(self.mCountDonwTxt,"")
            showEnd = false
        else
            self._endTime = endTime
            local para =
            {
                key = self._timerKey,
                interval = 1,
                loopcnt = -1,
                callOnStart = true,
                func =function()
                    self:StarCountDown()
                end
            }
            self:TimerStartImpl(para)
            --self:TimerStart(self._timerKey,1,false,-1)
            --self:CreateTime()
        end
    end


    if not string.isempty(config.endTimePosition) then
        local pos = LxDataHelper.ParseVector2NotEmpty(config.endTimePosition)
        self:SetAnchorPos(self.mCountDownDiv,pos)
    end

    CS.ShowObject(self.mCountDownDiv,showEnd)

    local image = config.image
    if LxUiHelper.IsImgPathValid(image) then
        self:SetWndEasyImage(self.mGiftViewBg,image)
    end

    local descIcon = config.descIcon
    if LxUiHelper.IsImgPathValid(descIcon) then
        self:SetWndEasyImage(self.mGiftTitleImg,descIcon,function()
            CS.ShowObject(self.mGiftTitleImg,true)
        end,true)
    end

    local descIconPosition = config.descIconPosition
    if not string.isempty(descIconPosition) then
        self:SetAnchorPos(self.mGiftTitleImg, LxDataHelper.ParseVector2NotEmpty(descIconPosition))
    end

    local endTimePosition = config.endTimePosition
    if not string.isempty(endTimePosition) then
        self:SetAnchorPos(self.mCountDownDiv, LxDataHelper.ParseVector2NotEmpty(endTimePosition))
    end

    local helpTips = config.helpTips or 0
    local showHelpBtn = helpTips == 1
    if showHelpBtn then
        local helpTipsPosition = config.helpTipsPosition
        if not string.isempty(helpTipsPosition) then
            self:SetAnchorPos(self.mHelpDiv, LxDataHelper.ParseVector2NotEmpty(helpTipsPosition))
        end
    end
    CS.ShowObject(self.mHelpDiv,showHelpBtn)

    self._title = activityData.title
    self._helpTipsContent = config.helpTipsContent

    local isTurnRolepart = config.ImageHeroTurn
    local rolePartScaleX = isTurnRolepart and -1 or 1
    self.mBigGiftIcon.localScale = Vector3(rolePartScaleX , 1, 1)
    self:ShowActivityHero(self.mRolepart,config.ImageHero,config.ImageHeroPos)

    gModelActivity:OnActivityPageReq(sid)
end
------------------------- List -------------------------

function UIActGiftD:StarCountDown()
    if not self._endTime then
        self:SetWndText(self.mCountDonwTxt,"")
        CS.ShowObject(self.mCountDownDiv,false)
        self:TimerStop(self._timerKey)
        return
    end
    local lastTime = self._endTime - GetTimestamp()
    local str = nil
    if lastTime < 0 then
        str = ccClientText(14301)
        self:TimerStop(self._timerKey)
        self._isEnd = true
    else
        local timeStr = LUtil.FormatTimespanCn(lastTime)
        --timeStr = LUtil.FormatColorStr(timeStr,"green")
        --str = string.replace(ccClientText(21405),timeStr)
        str = string.replace(ccClientText(11637),timeStr)
    end
    str = LUtil.FormatColorStr(str,self._timeTextColor)
    self:SetWndText(self.mCountDonwTxt,str)

    CS.ShowObject(self.mCountDownDiv,true)
end

function UIActGiftD:CommonBuyFunc(itemdata,expendType)
    local callFunc,setTextStr,itemId
    local pageId,entryId = itemdata.pageId,itemdata.entryId
    if LOG_INFO_ENABLED then
        printInfoNR("pageId = " .. pageId .. ",entryId = " .. entryId .. ",expendType = " .. expendType)
    end
    if expendType == UIActGiftD.TYPE_BUY_FREE then
        callFunc = function()
            gModelActivity:OnActivityMarkeyBuyReq(self._sid,pageId,entryId)
        end
        setTextStr = ccClientText(11913)
    elseif expendType == UIActGiftD.TYPE_BUY_ITEM then
        local expend2 = itemdata.expend2
        local expend2List =  string.split(expend2,"=")
        itemId = tonumber(expend2List[2])
        local needItemNum = tonumber(expend2List[3])
        callFunc = function()
            local dia = gModelItem:GetNumByRefId(itemId)
            local itemName = gModelItem:GetNameByRefId(itemId)
            -- 钻石购买
            local func = function()
                if dia >= needItemNum then
                    gModelActivity:OnActivityMarkeyBuyReq(self._sid,pageId,entryId)
                else
                    gModelGeneral:OpenGetWayWnd({itemId = itemId})
                end
            end
            GF.OpenWnd("UIOrdinTip",{refId = 110005,func = func,para = {needItemNum .. itemName}, consume = {needItemNum, itemId}})
        end
        setTextStr = needItemNum
    elseif expendType == UIActGiftD.TYPE_BUY_RMB then
        local expendId = tonumber(itemdata.expend2)
        setTextStr = gModelPay:GetShowByWelfareId(expendId)
        callFunc = function()
            gModelPay:GiftPayCtrl(entryId,expendId,ModelPay.PAY_TYPE_ACTIVITY,nil,self._sid,pageId)
        end
    end
    local isFreeBuy = expendType == UIActGiftD.TYPE_BUY_FREE
    local buyNum = itemdata.buyNum
    local buyCountText = string.replace(ccClientText(23803), buyNum)
    local showItemList
    if itemdata.isSel then
        showItemList = itemdata.getItemList
    else
        showItemList = itemdata.fixReward
    end
    GF.OpenWnd("UIGiftBuyPop", {
        title = itemdata.title,
        desc = buyCountText,
        payStr = setTextStr,
        payItemId = not isFreeBuy and itemId or nil,
        payFunc = callFunc,
        itemList = showItemList,
        personalGoal = itemdata.personalGoal
    })
end

function UIActGiftD:OpenCustomSelectWnd(argList)
    GF.OpenWnd("UICumSelectNew",argList)
end

function UIActGiftD:OnActivityResp(pb)
    if self._sid ~= pb.sid then return end
end

function UIActGiftD:OnTimer(key)
    if key == self._timerKey then
        self:StarCountDown()
    end
end

function UIActGiftD:OnDrawSelGiftCell(list,item,itemdata,itempos)
    local CustomTrans = self:FindWndTrans(item,"Custom")
    local ImmobilizationTrans = self:FindWndTrans(item,"Immobilization")
    local isSel = itemdata.isSel
    CS.ShowObject(CustomTrans,isSel)
    CS.ShowObject(ImmobilizationTrans,not isSel)
    local height = item.sizeDelta.y
    LxUiHelper.SetSizeWithCurAnchor(item, 1, height)
    if isSel then
        self:CreateCustom(CustomTrans,itemdata)
    else
        self:CreateImmobilization(ImmobilizationTrans,itemdata)
    end
end

function UIActGiftD:OnClickGiftBtnFunc(itemdata,expendType)
    if self:IsSellOut(itemdata) and itemdata.personalGoal ~= -1 then
        GF.ShowMessage(ccClientText(20811))
        return
    end
    self:CommonBuyFunc(itemdata,expendType)
end

function UIActGiftD:InitActData()
    self._activityServerData = nil
    if not self._sid then return end
    local activityData = gModelActivity:GetActivityBySid(self._sid)
    self._activityServerData = activityData
end

function UIActGiftD:IsSellOut(itemdata)
    local buyNum = itemdata.buyNum
    return buyNum < 1
end

function UIActGiftD:OnDrawItemCell(list,item,itemdata,itempos)
    self:CreateItemShow(item,itemdata,{
        clickFunc = function()
            if itemdata.customType then
                if itemdata.status then
                    gModelGeneral:ShowCommonItemTipWnd(itemdata)
                    return
                end
                self:OpenCustomSelectWnd({
                    sid = self._sid,
                    pageId = itemdata.pageId,
                    entryId = itemdata.entryId,
                    itemIndex = itemdata.index,
                    giftData = itemdata,
                    title = itemdata.title,
                })
            else
                self:OpenCommonItemTipsWnd(itemdata)
            end
        end,
        isChange = not itemdata.isEmpty,
    })
end

function UIActGiftD:GetPayType(expendType,expend2)
    local txt
    local showIconImg = false
    local iconImg
    if expendType == UIActGiftD.TYPE_BUY_FREE then
        txt = ccClientText(11913)
    elseif expendType == UIActGiftD.TYPE_BUY_ITEM then
        showIconImg = true
        local expend2Info =  string.split(expend2,"=")
        local itemId = tonumber(expend2Info[2])
        iconImg = gModelItem:GetItemIconByRefId(itemId)
        txt = tonumber(expend2Info[3])
    elseif expendType == UIActGiftD.TYPE_BUY_RMB then
        txt = gModelPay:GetShowByWelfareId(tonumber(expend2))
    end
    return txt,showIconImg,iconImg
end

function UIActGiftD:SaveWndArg()
    local wndArg = self:GetWndArgList() or {}
    wndArg["sid"] = self._sid
    self:SetWndArg(wndArg)
end

------------------------- List -------------------------
---货币栏
function UIActGiftD:SetCurrencyGroup(itemId)
    local itemIcon = self:FindWndTrans(self.mCurrencyGroup, "Icon")
    local num = self:FindWndTrans(self.mCurrencyGroup, "Num")
    local itemId = tonumber(itemId)
    local icon = gModelItem:GetItemImgByRefId(itemId)
    local itemNum = gModelItem:GetNumByRefId(itemId)
    self:SetWndEasyImage(itemIcon, icon)
    local numStr = LUtil.NumberCoversion(itemNum)
    self:SetWndText(num, numStr)
    -- self:SetWndClick(self.mCurrencyGroup, function()
    --     gModelGeneral:OpenGetWayWnd({ itemId = itemId, srcWnd = "WndChildConstellationStoreGashapon" })
    -- end)
end

function UIActGiftD:OnClickHelpBtnFunc()
    if not self._title or not self._helpTipsContent then return end

    local para =
    {
        title = self._title,
        text = self._helpTipsContent
    }
    GF.OpenWnd("UIBzTips",para)
end

function UIActGiftD:InitRewardList(trans,list,canScroll)
    if canScroll == nil then
        canScroll = false
    end
    local key = trans:GetInstanceID()
    local uiList = self:FindUIScroll(key)
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll(key)
        uiList:Create(trans,list,function(...) self:OnDrawItemCell(...) end)
        uiList:EnableScroll(canScroll,true)
    end
end

function UIActGiftD:InitSelGiftList()
    local list = self:GetSelGiftList()
    local uiSelGiftList = self._uiSelGiftList
    if uiSelGiftList then
        uiSelGiftList:RefreshData(list)
    else
        uiSelGiftList = self:GetUIScroll("uiSelGiftList")
        self._uiSelGiftList = uiSelGiftList
        uiSelGiftList:Create(self.mSelGiftList,list,function(...) self:OnDrawSelGiftCell(...) end,UIItemList.WRAP,false)
        local uiList = uiSelGiftList:GetList()
        uiList:RefreshList(UIListWrap.RefreshMode.Solid)
    end
end

function UIActGiftD:InitChildList()
    self._actModelWndList = {
        [ModelActivity.DAILY_GIFT_D] = function(activityData)
            self:CreateChildWnd(self.mChildRoot,"UISubActGiftD",{sid = activityData.sid})
        end
    }
end

function UIActGiftD:CreateItemShow(trans,itemdata,extraData)
    local IconTrans = self:FindWndTrans(trans,"itemRoot/Icon")
    local itemNumTrans = self:FindWndTrans(trans,"itemNum")
    local ShiftTrans = self:FindWndTrans(trans,"Shift")
    local EffTrans = self:FindWndTrans(trans,"Eff")

    local itemNum = itemdata.itemNum
    local instanceID = IconTrans:GetInstanceID()
    local baseClass = self:GetCommonIcon(instanceID)
    baseClass:Create(IconTrans)
    baseClass:SetCommonReward(itemdata.itemType,itemdata.itemId,itemNum)
    baseClass:EnableShowNum(false)
    baseClass:DoApply()

    local showItemNum = itemNum > 0
    if showItemNum then
        self:SetWndText(itemNumTrans,LUtil.NumberCoversion(itemNum))
    end
    CS.ShowObject(itemNumTrans,showItemNum)

    extraData = extraData or {}
    local isChange = extraData.isChange
    CS.ShowObject(ShiftTrans,isChange)
    CS.ShowObject(EffTrans,false)

    local clickFunc = extraData.clickFunc
    if clickFunc then
        self:SetWndClick(IconTrans,function()
            clickFunc()
        end)
    end

end

------------------------- List -------------------------

function UIActGiftD:GetSelGiftServerDataList()
    local activityData = self._activityData
    if not activityData then return {} end

    local selGiftPageId = ModelActivity.DAILY_GIFT_D_SELGIFTID
    local selGiftList = {}
    local selGiftServerDataList = activityData[selGiftPageId] or {}
    for i,v in ipairs(selGiftServerDataList) do
        local MarketData = v.MarketData
        local customListStr = string.split(MarketData.customList,"|")
        local customList = LxDataHelper.ParseItem(MarketData.customList)
        local len = #customListStr
        local customGiftList = LxDataHelper.ParseItem(MarketData.customGift) or {}
        local entryId = v.entryId
        local title = v.title
        local items = v.items
        local buyNum = v.buyNum
        local sellOut = buyNum > 0 and 1 or 0
        local getItemList = {}
        for idx,val in ipairs(items) do
            table.insert(getItemList,val)
        end
        for idx = 1,len do
            local curData = customGiftList[idx]
            if not curData then
                customGiftList[idx] = {
                    isEmpty = true,
                    itemId = 0,
                    itemNum = -1,
                }
            else
                table.insert(getItemList,curData)
            end
            customGiftList[idx].pageId = selGiftPageId
            customGiftList[idx].entryId = entryId
            customGiftList[idx].title = title
            customGiftList[idx].index = idx
            customGiftList[idx].selList = customList
            customGiftList[idx].MarketData = MarketData
            customGiftList[idx].isSel = true
            customGiftList[idx].canSel = buyNum > 0
        end
        table.insert(selGiftList,{
            isSel = true,
            customGiftList = customGiftList,
            fixReward = items,
            entryId = entryId,
            sort = v.sort,
            title = title,
            pageId = selGiftPageId,
            icon = v.icon,
            personal = v.personal,
            personalGoal = v.personalGoal,
            buyNum = buyNum,
            expend1 = MarketData.expend1,
            expend2 = MarketData.expend2,
            expendType = MarketData.expendType,
            sellOut = sellOut,
            discount = MarketData.discount,
            getItemList = getItemList,
        })
    end

    return selGiftList
end

function UIActGiftD:GetSelGiftList()
    local list = {}

    --- 商品
    local shopList = self:GetShopServerDataList()
    for i,v in ipairs(shopList) do
        table.insert(list,v)
    end

    --- 定制礼包
    local selGiftList = self:GetSelGiftServerDataList()
    for i,v in ipairs(selGiftList) do
        table.insert(list,v)
    end

    return list
end

function UIActGiftD:InitMsg()
    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
    self:WndNetMsgRecv(LProtoIds.ActivityResp,function(pb) self:OnActivityResp(pb) end)
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb) self:OnActivityPageResp(pb) end)
end

function UIActGiftD:CreateCustom(item,itemdata)
    local OverImgTrans = self:FindWndTrans(item,"OverImg")

    --local FixRewardTrans = self:FindWndTrans(item,"FixReward")
    local RewardDivTrans = self:FindWndTrans(item,"RewardDiv")

    local FixRewardListTrans = self:FindWndTrans(RewardDivTrans,"FixRewardList")
    local GameObjectTrans = self:FindWndTrans(RewardDivTrans,"GameObject")
    local RewardListTrans = self:FindWndTrans(RewardDivTrans,"RewardList")

    local AddImgTrans = self:FindWndTrans(item,"Image")

    local DiscountImgTrans = self:FindWndTrans(item,"DiscountImg")
    local DiscountTxtTrans = self:FindWndTrans(DiscountImgTrans,"DiscountTxt")

    local BuyBtnTrans = self:FindWndTrans(item,"BuyBtn")
    local AutoDivTrans = self:FindWndTrans(BuyBtnTrans,"AutoDiv")
    local IconImgTrans = self:FindWndTrans(AutoDivTrans,"Image")
    local BtnTxtTrans = self:FindWndTrans(AutoDivTrans,"Txt")
    local EffTrans = self:FindWndTrans(BuyBtnTrans,"Eff")

    local CountDownTxtTrans = self:FindWndTrans(item,"CountDownTxt")

    local TxtBgTrans = self:FindWndTrans(item,"TxtBg")
    local TxtTrans = self:FindWndTrans(TxtBgTrans,"Txt")

    self:SetWndEasyImage(TxtBgTrans,itemdata.icon)
    self:SetWndText(TxtTrans,itemdata.title)

    local fixReward = itemdata.fixReward or {}
    local fixRewardLen = #fixReward
    local fixRewardEmpty = fixRewardLen < 1
    if not fixRewardEmpty then
        self:InitRewardList(FixRewardListTrans,fixReward)
    end
    CS.ShowObject(FixRewardListTrans,not fixRewardEmpty)
    CS.ShowObject(GameObjectTrans,not fixRewardEmpty)

--[[    local fixFirst = fixReward[1]
    if fixFirst then
        self:CreateItemShow(FixRewardTrans,fixFirst,{
            clickFunc = function()
                self:OpenCommonItemTipsWnd(fixFirst)
            end,
            isChange = false
        })
    end]]

    local buyNum = itemdata.buyNum
    local isEmpty = buyNum < 1
    local show = not isEmpty

    local customGiftList = self:GetCustomList(itemdata.customGiftList,isEmpty)
    local customGiftLen = #customGiftList
    local haveGift = customGiftLen > 0
    CS.ShowObject(AddImgTrans,haveGift)
    CS.ShowObject(RewardListTrans,haveGift)
    if haveGift then
        self:InitRewardList(RewardListTrans,customGiftList)
    end

    local showDis = false
    if show then
        local buyCountText = string.replace(ccClientText(20810), buyNum)
        self:SetWndText(CountDownTxtTrans,buyCountText)

        local expendType = itemdata.expendType
        local expend2 = itemdata.expend2
        local txt,showIconImg,iconImg = self:GetPayType(expendType,expend2)
        if iconImg then
            self:SetWndEasyImage(IconImgTrans,iconImg)
        end
        CS.ShowObject(IconImgTrans,showIconImg)
        self:SetWndText(BtnTxtTrans,txt)

        local isFree = expendType == UIActGiftD.TYPE_BUY_FREE
        if isFree then
            local effKey = EffTrans:GetInstanceID()
            self:CreateWndEffect(EffTrans,"fx_anniu_02",effKey,100,false,false,10)
        end
        CS.ShowObject(EffTrans,isFree)

        local discount = itemdata.discount
        showDis = discount > 0
        if showDis then
            self:SetWndText(DiscountTxtTrans, discount.."%")
        end

        self:SetWndClick(BuyBtnTrans,function()
            self:OnClickCustomBtnFunc(itemdata)
        end)
    end
    CS.ShowObject(DiscountImgTrans,showDis)
    CS.ShowObject(OverImgTrans,isEmpty)
    CS.ShowObject(BuyBtnTrans,show)
    CS.ShowObject(CountDownTxtTrans,show)
end

function UIActGiftD:OnClickCustomBtnFunc(itemdata)
    if self:IsSellOut(itemdata) then
        GF.ShowMessage(ccClientText(20811))
        return
    end
    local fixReward = itemdata.fixReward or {}
    local costomGiftList = itemdata.customGiftList or {}
    local getItemList = itemdata.getItemList or {}
    local fixLen,costomLen,getItemLen = #fixReward,#costomGiftList,#getItemList
    local isSelFull = fixLen + costomLen == getItemLen
    local firstData = costomGiftList[1]
    if not isSelFull and firstData then
        self:OpenCustomSelectWnd({
            sid = self._sid,
            pageId = firstData.pageId,
            entryId = firstData.entryId,
            itemIndex = firstData.index,
            giftData = firstData,
            title = firstData.title,
        })
        return
    else
        self:CommonBuyFunc(itemdata,itemdata.expendType)
    end
end

function UIActGiftD:GetShopServerDataList()
    local activityData = self._activityData
    if not activityData then return {} end

    local player = gModelPlayer:GetPlayerLv()
    local shopPageId = ModelActivity.DAILY_GIFT_D_SHOPID
    local shopAllList = {}
    local shopServerDataList = activityData[shopPageId] or {}
    for i,v in ipairs(shopServerDataList) do
        local moreInfo = string.split(v.moreInfo,";")
        local showLv = tonumber(moreInfo[2]) or 0
        if player >= showLv then
            local valuePercent = moreInfo[3]
            local typeId = tonumber(moreInfo[4])		-- 类型ID=礼包卡底资源图=售卖文本字色=售卖文本描边色
            local MarketData = v.MarketData
            local buyNum = v.buyNum
            local sellOut = buyNum > 0 and 1 or 0

            local commonGiftList = {}
            for idx,val in ipairs(v.items) do
                local curData = {
                    itemId = val.itemId,
                    itemType = val.itemType,
                    itemNum = val.itemNum,
                    notShowTips = true, --点击不显示道具tips，直接打开详情弹窗
                }
                table.insert(commonGiftList,curData)
            end

            table.insert(shopAllList,{
                isSel = false,
                fixReward = v.items,
                entryId = v.entryId,
                sort = v.sort,
                title = v.title,
                pageId = shopPageId,
                expend1 = MarketData.expend1,
                expend2 = MarketData.expend2,
                personal = v.personal,
                personalGoal = v.personalGoal,
                buyNum = buyNum,
                sellOut = sellOut,
                moreInfo = v.moreInfo,
                showLv = showLv,
                valuePercent = valuePercent,
                typeId = typeId,
                desc = v.desc,
                expendType = MarketData.expendType,
                commonGiftList = commonGiftList,
            })
        end
    end

    local shopList = {}
    local index = 1
    for i,v in ipairs(shopAllList) do
        local indexList = shopList[index]
        if not indexList then
            indexList = {}
            shopList[index] = indexList
        end
        table.insert(indexList,v)
        if i % UIActGiftD.SelGiftNum == 0 then
            index = index + 1
        end
    end
    return shopList
end

function UIActGiftD:RefreshChildWnd()
    if not self._activityServerData then return end
    local actModelWndList = self._actModelWndList
    if not actModelWndList then return end
    local activityData = self._activityServerData
    local actModel = activityData.model
    local func = actModelWndList[actModel]
    if not func then return end
    func(activityData)
    self:SaveWndArg()
end

------------------------------------------------------------------
return UIActGiftD



