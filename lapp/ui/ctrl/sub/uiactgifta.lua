---
--- Created by BY.
--- DateTime: 2023/10/1 14:59:05
---
---活动5-通用礼包5
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UIActGiftA:LChildWnd
local UIActGiftA = LxWndClass("UIActGiftA", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActGiftA:UIActGiftA()
    ---@type table<number,CommonIcon>
    self._uiCommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActGiftA:OnWndClose()
    if self._timer then
        for key, timer in pairs(self._timer) do
            LxTimer.DelayTimeStop(timer)
        end
        self._timer = {}
    end
    self:ClearCommonIconList(self._uiCommonList)
    self._uiCommonList = nil

    LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActGiftA:OnCreate()
    LChildWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActGiftA:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()
    self.jpj = gLGameLanguage:IsJapanVersion()
    self._isVie =gLGameLanguage:IsVieVersion()
    self:InitEvent()
    self:InitMsg()
    self:InitPara()
end

function UIActGiftA:CreateTimer(key, times, trans, strText, isEnd)
    self:ClearTimer(key)
    self:SetTimeStr(times, trans, strText, key, isEnd)
    self._timer[key] = LxTimer.LoopTimeCall(function()
        self:SetTimeStr(times, trans, strText, key, isEnd)
    end, 1, false, -1)
    self:InitTextSizeWithLanguage(trans, -2)
end

function UIActGiftA:SetTimeStr(times, trans, strText, key, isEnd)
    local time = times - GetTimestamp()
    if time > 0 then
        local timeStr = LUtil.FormatTimeToCn4(time)
        local text = strText .. timeStr
        self:SetWndText(trans, text)
    else
        self:ClearTimer(key)
    end
end

function UIActGiftA:ClearTimer(key)
    local timer = self._timer[key]
    if timer then
        LxTimer.DelayTimeStop(timer)
        self._timer[key] = nil
    end
end

function UIActGiftA:OnDrawItemFunc(list, item, itemdata, itempos)
    local itemRefId, itemType, itemCount = itemdata.itemId, itemdata.itemType, itemdata.itemNum
    --local itemNum = self:FindWndTrans(item,"itemNum")
    --self:SetWndText(itemNum,LUtil.NumberCoversion(itemCount))


    --[[	local baseClass = UICommon:New()
        local formatData =
        {
            itemId = itemRefId,
            itemType = itemType,
            itemNum = itemCount,
        }
        local data =
        {
            showName = false,
            showTip = true,
            itemType = itemType,
            itemId = itemRefId,
            itemNum = -1,
            parentTran = item,
            clickFunc =function() gModelGeneral:ShowCommonItemTipWnd(formatData) end
        }

        baseClass:Show(data)]]

    local itemRoot = self:FindWndTrans(item, "itemRoot")
    local icon = self:FindWndTrans(itemRoot, "Icon")
    if itemRoot then
        local formatData = {
            itemId = itemRefId,
            itemType = itemType,
            itemNum = itemCount,
        }
        local uiCommonList = self._uiCommonList
        local InstanceID = item:GetInstanceID()
        local baseClass = uiCommonList[InstanceID]
        if not baseClass then
            baseClass = CommonIcon:New()
            uiCommonList[InstanceID] = baseClass
            baseClass:Create(icon)
        end
        baseClass:SetCommonReward(itemType, itemRefId, itemCount)
        --self:SetWndClick(itemRoot, function()
        --gModelGeneral:ShowCommonItemTipWnd(formatData)
        --end)
        baseClass:DoApply()
    end

    local instanceId = item:GetInstanceID()
    if itemdata.isShowEff then
        local quality = gModelGeneral:GetCommonItemQualityRef(itemdata)
        local eff = GameTable.RarityRef[quality].itemFx
        if not string.isempty(eff) then
            self:CreateWndEffect(icon, eff, instanceId, 100, false, false)
        end
    else
        self:DestroyWndEffectByKey(instanceId)
    end
end

function UIActGiftA:SetContent()
    local webData = gModelActivity:GetWebActivityDataById(self._sid)
    if not webData then
        return
    end

    self._activityList = gModelActivity:GetActivityBySid(self._sid)

    local data = webData.config
    self._activityEndTime = self._activityList.endTime

    local activityMoreInfo = JSON.decode(self._activityList.moreInfo)
    self._activityResetTime = activityMoreInfo.remainTime

    -- banner区，cell图
    self._image = data.image or "dailysign_bg_ad"

    -- banner区，活动描述文本美术字
    self._descIcon = data.descIcon or ""

    -- banner区，活动描述文本美术字坐标位置：以宣传图左上角为坐标原点，以图片中心为计量点--举例“1,0”
    self._descIconPosition = data.descIconPosition or "1,0"

    -- banner区，是否显示规则说明按钮：1=是，0=否；一般默认=0
    self._helpTips = tonumber(data.helpTips) or 0

    -- banner区，活动说明按钮坐标位置：以宣传图左上角为坐标原点，以图片中心为计量点--举例“1,0”
    self._helpTipsPosition = data.helpTipsPosition or "1,0"
    self._helpTipsContent = data.helpTipsContent or ""
    --local specialActivity = gModelActivity:GetActivityBySid(self._sid)
    self._helpTipsTitle = self._activityList.title or ccClientText(15507)

    -- banner区，活动剩余时间：是否显示倒计时，1=是，0=否，填1时读取活动有效时间，倒计时显示
    self._endTime = tonumber(data.endTime) or 0

    -- banner区，活动剩余时间坐标位置：以宣传图左上角为坐标原点，以图片中心为计量点--举例“1,0”
    self._endTimePosition = data.endTimePosition or "1,0"

    -- banner区，重置剩余时间：是否显示倒计时，1=是，0=否，填1时读取距离下次重置的时间，倒计时显示
    self._resetTime = tonumber(data.resetTime) or 0

    -- banner区，重置剩余时间坐标位置：以宣传图左上角为坐标原点，以图片中心为计量点--举例“1,0”
    self._resetTimePosition = data.resetTimePosition or "1,0"

    -- banner区，活动说明，支持富文本；允许留空，不显示
    self._textStr = data.text or ""

    -- banner区，活动说明，支持富文本；允许留空，不显示
    self._textPos = data.textPosition

    -- banner区，限购重置类型，到达时间点时，重置礼包状态，刷新界面
    -- 类型=1：活动期间于每天晚上23点59分59秒重置
    -- 类型=3：活动期间于周日晚上23点59分59秒重置
    -- 类型=2：活动期间于每个自然月最后一天晚上23点59分59秒重置
    -- 类型=4：活动显示结束时重置（即活动期间不会重置）
    self._resetType = tonumber(data.resetType) or 0

    self:SetBannerImage()
end

function UIActGiftA:SetBannerImage()
    CS.ShowObject(self.mTop, true)
    self:SetWndEasyImage(self.mTop, self._image, function()
        CS.ShowObject(self.mTop, true)
    end)

    if not string.isempty(self._descIcon) then
        self:SetWndEasyImage(self.mTextImg, self._descIcon, function()
            CS.ShowObject(self.mTextImg, true)
        end, true)
    end
    self:SetAnchorPos(self.mHelpBtn, LxDataHelper.ParseVector2NotEmpty(self._helpTipsPosition))
    self:SetAnchorPos(self.mTextImg, LxDataHelper.ParseVector2NotEmpty(self._descIconPosition))
    self:SetAnchorPos(self.mTimeBg, LxDataHelper.ParseVector2NotEmpty(self._endTimePosition))
    self:SetAnchorPos(self.mTimeBg2, LxDataHelper.ParseVector2NotEmpty(self._resetTimePosition))
    self:SetAnchorPos(self.mHelpDesc, LxDataHelper.ParseVector2NotEmpty(self._textPos))

    CS.ShowObject(self.mHelpBtn, self._helpTips == 1)
    CS.ShowObject(self.mTimeBg, self._endTime == 1)
    CS.ShowObject(self.mTimeBg2, self._resetTime == 1)

    -- 活动剩余时间
    local curTime = GetTimestamp()
    local time = self._activityEndTime - curTime
    self:CreateTimer("actEndTime", self._activityEndTime, self.mTimeText, ccClientText(15506), true)

    if time <= 0 then
        CS.ShowObject(self.mTimeBg, false)
    end

    -- 活动重置时间
    local time = self._activityResetTime - curTime
    self:CreateTimer("actResetTime", self._activityResetTime, self.mTimeText2, ccClientText(15505), false)
    if self.jpj then
        self:InitTextSizeWithLanguage(self.mTimeText2,-4)
        self:SetAnchorPos(self.mTimeText2,Vector2.New(-30,0))
    end

    if self._isVie then
        self:SetAnchorPos(self.mTimeText2,Vector2.New(-30,0))
    end

    if time <= 0 then
        CS.ShowObject(self.mTimeBg2, false)
    end

    local itemFunc = function(refId, num)
        gModelGeneral:OpenItemInfoTip(refId, num)
    end
    local heroFunc = function()
    end
    local equipFunc = function(refId)
        gModelGeneral:OpenEquipInfoTip(refId, nil, 1, true)
    end
    self._funcList = {
        [1] = itemFunc,
        [2] = heroFunc,
        [3] = equipFunc,
    }

    self:SetWndText(self.mHelpDesc, self._textStr)
    self:InitTextSizeWithLanguage(self.mHelpDesc, -2)
    self:InitTextLineWithLanguage(self.mHelpDesc, -30)
end

function UIActGiftA:InitPara()
    self._sid = self:GetWndArg("sid")
    local subpage = self:GetWndArg("subPage") --支持跳转
    if subpage then
        self._sid = gModelActivity:GetSidByUniqueJump(subpage)
    end

    self._uiCommonList = {}
    self._timer = {}

    gModelActivity:ReqActivityConfigData(self._sid)
end

function UIActGiftA:InitEvent()

    self:SetWndClick(self.mHelpBtn, function()
        GF.OpenWnd("UIBzTips", { title = self._helpTipsTitle, para = { }, text = self._helpTipsContent })
    end, LSoundConst.CLICK_ERROR_COMMON)

end

function UIActGiftA:OnActivityConfigData(data, sid)
    if sid ~= self._sid then
        return
    end

    self:SetContent()
    gModelActivity:OnActivityPageReq(self._sid)
end

function UIActGiftA:Reset(pb)

    local sid = pb.sid
    if self._sid ~= sid then
        return
    end
    self._pages = {}
    for i, v in ipairs(pb.pages) do
        local page = gModelActivity:GenerateActivePageDataFromPb(v)
        self._pages[page.pageId] = page
    end
    if not self._pages or not self._pages[1] then
        return
    end

    -- 分页id
    self._pageId = self._pages[1].pageId

    -- 活动条目
    local firstPage = self._pages[1]
    self._activityEntryList = {}
    for k, v in pairs(firstPage.entry) do
        local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, v.pageId, v.entryId)
        if not entryCfg then
            return
        end
        local entryData = {
            entryId = v.entryId,
            title = entryCfg.name,
            desc = entryCfg.description,
            items = LxDataHelper.ParseItem(entryCfg.reward),
            MarketData = v.MarketData,
            moreInfo = entryCfg.moreInfo,
            sort = entryCfg.sort,
        }

        table.insert(self._activityEntryList, entryData)
    end

    table.sort(self._activityEntryList, function(a, b)
        return a.entryId < b.entryId
    end)

    -- 物品List
    self._iconList = {}

    self:InitGiftScrollView()
end

function UIActGiftA:InitMsg()
    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
        self:OnActivityConfigData(...)
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
        self:Reset(pb)
    end)

    -- 道具购买返回
    self:WndNetMsgRecv(LProtoIds.ActivityMarkeyBuyResp, function(pb)

    end)

    self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
        gModelActivity:OnActivityPageReq(self._sid)
    end)
end

function UIActGiftA:InitGiftScrollView()
    -- 排序优先展示有购买次数的礼包
    table.sort(self._activityEntryList, function(a, b)
        local aCount = a.MarketData.personalGoal - a.MarketData.personal > 0 and 1 or 0
        local bCount = b.MarketData.personalGoal - b.MarketData.personal > 0 and 1 or 0
        if (aCount ~= bCount) then
            return aCount > bCount
        end
        return a.sort < b.sort
    end)

    if (self._giftUIList) then
        self._giftUIList:RefreshList(self._activityEntryList)
    else
        self._giftUIList = self:GetUIScroll("cell")
        local uiList = self._giftUIList
        uiList:Create(self.mItemList, self._activityEntryList, function(...)
            self:OnDrawGiftFunc(...)
        end, UIItemList.WRAP)
        uiList:EnableScroll(true, false)

        local superList = uiList:GetList()
        superList:EnableLoadAnimation(true)
        superList:SetLoadAnimationScale(0.2, 0.15)
        superList:RefreshList()
    end
end

function UIActGiftA:OnDrawGiftFunc(list, item, itemdata, itempos)
    CS.ShowObject(item, true)
    local contentTrans = self:FindWndTrans(item, "Content")
    local giftBgTrans = self:FindWndTrans(contentTrans, "BgImg")
    local bgTrans = self:FindWndTrans(contentTrans, "Bg")
    local titleTrans = self:FindWndTrans(contentTrans, "title")

    local btn = self:FindWndTrans(contentTrans, "btn")
    local text = self:FindWndTrans(btn, "text")
    local btn1 = self:FindWndTrans(contentTrans, "btn1")
    local itemImage = self:FindWndTrans(btn1, "Content/Image")
    local text1 = self:FindWndTrans(btn1, "Content/text1")
    local buyCount = self:FindWndTrans(contentTrans, "BuyCount")
    local redPointTrans = self:FindWndTrans(contentTrans, "redPoint")
    local UpRedImgTrans = self:FindWndTrans(contentTrans, "UpRedImg")
    local maskTrans = self:FindWndTrans(contentTrans, "mask")
    local ShowZSImg = self:FindWndTrans(contentTrans, "ShowZSImg")
    local ZSNum = self:FindWndTrans(ShowZSImg, "ZSNum")
    local EffRoot = self:FindWndTrans(contentTrans, "EffRoot")

    local entryId = tonumber(itemdata.entryId)
    local title = itemdata.title or ""
    local itemsList = itemdata.items
    local marketData = itemdata.MarketData
    local dataTable = itemdata.moreInfo
    local dataTableData = string.split(dataTable, ";")
    local needShowLv = tonumber(dataTableData[2]) or 0 --显示等级
    local valuePercent = dataTableData[3]            -- 价格百分比
    local _typeId = tonumber(dataTableData[4])        -- 类型ID=礼包卡底资源图=售卖文本字色=售卖文本描边色
    local personal = tonumber(marketData.personal)  -- 已使用个人限购次数
    local personalGoal = tonumber(marketData.personalGoal)  -- 个人可购买次数
    local expend2List = string.split(marketData.expend2 or "", "=")  -- 商品现价,若无通用奖励格式表示可直接道具购买，否则为RMB购买
    local count = personalGoal - personal

    local zsNum = tonumber(dataTableData[5])
    local showZSImg = zsNum and zsNum ~= 0 or false
    CS.ShowObject(ShowZSImg, showZSImg)
    if showZSImg then
        self:SetWndText(ZSNum, zsNum)
    end

    -- 可视化等级判断
    local player = gModelPlayer:GetPlayerLv()
    if player < needShowLv then
        CS.ShowObject(item, false)
        return
    end

    self:SetActivityTitleImage(giftBgTrans, _typeId)
    self:SetWndEasyImage(bgTrans, itemdata.desc)
    self:SetWndText(titleTrans, title)
    self:InitTextModeWithLanguage(titleTrans)
    self:InitTextSizeWithLanguage(titleTrans, -2)

    if UpRedImgTrans then
        if string.isempty(valuePercent) then
            CS.ShowObject(UpRedImgTrans, false)
        else
            local show = true
            if count <= 0 then
                show = false
            end
            if valuePercent == "0" then
                show = false
            end

            local AutoDiv = self:FindWndTrans(UpRedImgTrans, "AutoDiv")
            if AutoDiv and show then
                local UpRedTxt = self:FindWndTrans(AutoDiv, "UpRedTxt")
                if UpRedTxt then
                    local str = valuePercent
                    self:SetWndText(UpRedTxt, str)
                    self:InitTextSizeWithLanguage(UpRedTxt, -2)
                end
            end
            CS.ShowObject(UpRedImgTrans, show)
        end
    end

    local buyCountText = ccClientText(15502) .. count
    self:SetWndText(buyCount, buyCountText)

    -- 零元购
    local isFreeBuy = false
    local btnTrans
    local setText
    local setTextStr
    local buyBtn, isUseItemBuy, itemId, needNum, expendId, noText, btnText, name
    if #expend2List > 1 then
        -- 道具购买
        buyBtn = btn1
        btnText = text1
        itemId = tonumber(expend2List[2])
        needNum = tonumber(expend2List[3])
        isUseItemBuy = true
        local image = gModelItem:GetItemImgByRefId(itemId)
        noText = self:FindWndTrans(buyBtn, "Content/noText")
        setText = count <= 0 and noText or text1
        setTextStr = LUtil.NumberCoversion(needNum)
        self:SetWndText(setText, setTextStr)
        self:SetWndEasyImage(itemImage, image)
        CS.ShowObject(btn, not isUseItemBuy)
        CS.ShowObject(btn1, isUseItemBuy)
        btnTrans = btn1
    else
        expendId = tonumber(expend2List[1])
        buyBtn = btn
        btnText = text
        noText = self:FindWndTrans(buyBtn, "noText")
        setText = count <= 0 and noText or text
        if expendId > 0 then
            -- rmb购买
            isUseItemBuy = false
            --local rmb = gModelPay:GetRMBValueByWelfareId(expendId)
            --local str = rmb .. ccClientText(15501)
            local str = gModelPay:GetShowByWelfareId(expendId) --string.replace(ccClientText(15601),rmb)
            self:SetWndText(setText, str)
            setTextStr = str
            CS.ShowObject(btn, not isUseItemBuy)
            CS.ShowObject(btn1, isUseItemBuy)
            btnTrans = btn
        else
            itemId = 102001
            needNum = 0
            name = ccClientText(15501)
            isUseItemBuy = true
            isFreeBuy = true
            setTextStr = ccClientText(11913)
            self:SetWndText(setText, setTextStr)
            CS.ShowObject(btn, true)
            CS.ShowObject(btn1, false)
            btnTrans = btn
        end
    end

    --if setText then
    --    self:SetActivityTextColor(setText, _typeId)
    --end

    local ShowTrans = CS.FindTrans(contentTrans, "Show")
    -- 按钮置灰
    local isBuyCount = count <= 0 and true or false
    CS.ShowObject(btnText, not isBuyCount)
    CS.ShowObject(noText, isBuyCount)
    if itemImage then
        self:SetWndImageGray(itemImage, isBuyCount)
    end
    --if buyBtn then self:SetWndImageGray(buyBtn, isBuyCount) end

    if redPointTrans then
        local isShow = isFreeBuy
        if count <= 0 then
            isShow = false
        end
        CS.ShowObject(redPointTrans, isShow)
    end


    --if EffRoot then
    --	local InstanceID = EffRoot:GetInstanceID()
    --	self:DestroyWndEffectByKey(InstanceID)
    --	local isShow = isFreeBuy
    --	if count <= 0 then
    --		isShow = false
    --	end
    --	if isShow then
    --		self:CreateWndEffect_Ex({
    --			trans = EffRoot,
    --			effKey = InstanceID,
    --			effName = "fx_libaomianfeilingqu",
    --			scale = Vector3(100,100,100)
    --		})
    --
    --
    --	end
    --end

    CS.ShowObject(btnTrans, not isBuyCount)

    if ShowTrans then
        CS.ShowObject(ShowTrans, isBuyCount)
    end

    if maskTrans then
        CS.ShowObject(maskTrans, isBuyCount)
    end

    -- 购买按钮
    if isBuyCount then
        self:SetWndClick(contentTrans, function()
            GF.ShowMessage(ccClientText(15517))
        end, LSoundConst.CLICK_BUTTON_COMMON)
    else
        self:SetWndClick(contentTrans, function()
            local clickFunc = function()
                if isFreeBuy then
                    gModelActivity:OnActivityMarkeyBuyReq(self._sid, self._pageId, entryId)
                    return
                end

                if isUseItemBuy then
                    local dia = gModelItem:GetNumByRefId(itemId)
                    local itemName = name or gModelItem:GetNameByRefId(itemId)
                    local value = needNum
                    -- 钻石购买
                    local func = function()
                        if dia >= value then
                            gModelActivity:OnActivityMarkeyBuyReq(self._sid, self._pageId, entryId)
                        else
                            gModelGeneral:OpenGetWayWnd({ itemId = itemId })
                        end
                    end
                    GF.OpenWnd("UIOrdinTip", { refId = 110005, func = func, para = { value .. itemName }, consume = { value, itemId } })
                else
                    -- 付费购买
                    gModelPay:GiftPayCtrl(entryId, tonumber(expendId), ModelPay.PAY_TYPE_ACTIVITY, nil, self._sid, self._pageId)
                end
            end

            GF.OpenWnd("UIGiftBuyPop", {
                title = title,
                desc = buyCountText,
                payStr = setTextStr,
                payItemId = not isFreeBuy and itemId or nil,
                payFunc = clickFunc,
                itemList = itemsList,
            })
        end, LSoundConst.CLICK_BUTTON_COMMON)
    end

    -- 礼包奖励
    local Reard = self:FindWndTrans(contentTrans, "Reard")
    local Content_1 = self:FindWndTrans(Reard, "Content_1")
    local Content_2 = self:FindWndTrans(Reard, "Content_2")
    local rewardNum = #itemsList
    local pointCenter = rewardNum < 3

    for i = 1, 4 do
        local rewardRoot = i > 2 and Content_2 or Content_1

        local k = i
        if k > 2 then
            k = k - 2
        end

        local rewardKey = "ItemTemplate_" .. k

        local rewardTran = self:FindWndTrans(rewardRoot, rewardKey)

        local rewardData = itemsList[i]

        if not rewardData then
            CS.ShowObject(rewardTran, false)
        else
            CS.ShowObject(rewardTran, true)
            self:OnDrawItemFunc(nil, rewardTran, rewardData, i)
        end

    end

    if pointCenter then
        --少于 两个奖励 列表拉高 50px
        self:SetAnchorPos(Content_1, Vector2.New(50, -100))
        CS.ShowObject(Content_2, false)
    else
        self:SetAnchorPos(Content_1, Vector2.New(50, -135))
        CS.ShowObject(Content_2, true)
    end

end
------------------------------------------------------------------
return UIActGiftA


