---
--- Created by Administrator.
--- DateTime: 2023/10/24 11:33:15
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPkBuyPopBig:LWnd
local UIPkBuyPopBig = LxWndClass("UIPkBuyPopBig", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPkBuyPopBig:UIPkBuyPopBig()
    ---@type UIIconEasyList
    self._rewardListCls1 = nil
    ---@type UIIconEasyList
    self._rewardListClsMax1 = nil
    ---@type UIIconEasyList
    self._rewardListCls2 = nil
    ---@type UIIconEasyList
    self._rewardListClsMax2 = nil

    self._tabTransList = {}


    self._timeLimitTimer = "timeLimitTimer"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPkBuyPopBig:OnWndClose()
    if self._rewardListCls1 then
        self._rewardListCls1:Destroy()
        self._rewardListCls1 = nil
    end

    if self._rewardListClsMax1 then
        self._rewardListClsMax1:Destroy()
        self._rewardListClsMax1 = nil
    end

    if self._rewardListCls2 then
        self._rewardListCls2:Destroy()
        self._rewardListCls2 = nil
    end

    if self._rewardListClsMax2 then
        self._rewardListClsMax2:Destroy()
        self._rewardListClsMax2 = nil
    end

    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPkBuyPopBig:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPkBuyPopBig:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    self:InitEvent()
    self:InitMessage()
    self:InitCommand()
    self:RefreshUI()
    self:RefreshForeign()
end

function UIPkBuyPopBig:OnClickTab(itempos, isFirst)
    if (self._index == itempos and not isFirst) then
        return
    end

    if self._modelActivityType == ModelActivity.MODEL_PASSB
            or self._modelActivityType == ModelActivity.MODEL_PASSD then
        self:ChangeItem(self._tabTransList[self._index], false)
        self:ChangeItem(self._tabTransList[itempos], true)
        self._index = itempos

        local posIdx = itempos
        local curIndex = self:GetWndArg("curIndex")
        if curIndex then
            posIdx = curIndex
        end
        self._canBuy = tonumber(self._bGuys[posIdx]) ~= 1

        local sid = self._sid
        local grade = self._grade

        local show = false
        self:TimerStop(self._timeLimitTimer)
        if gModelActivity:CheckModel13InCRTime(sid,grade) == 0 and self._canBuy then
            self:SetWndText(self.mTimeLimitDesc,ccClientText(14220))
            show = true
            self._cdInfo = {
                endTime = gModelActivity:GetModel13ExtraCREndTime(sid,grade)
            }
            self:StartTimeLimitTimer()
            self:TimerStart(self._timeLimitTimer,1,false,-1)
        end
        CS.ShowObject(self.mTimeLimitDiv,show)





        local itemdata = self._itemdata[itempos]
        local entryCfg1 = gModelActivity:GetWebActivityEntryData(sid, itemdata.pageId, itemdata.entryId)

        local entryMoreInfo = string.split(entryCfg1.moreInfo, "|")
        local rewardList1 = LxDataHelper.ParseItem(entryMoreInfo[1])

        local rewardList2 = {}
        if gModelActivity:CheckModel13InCRTime(sid,grade) == 0 then
            local extraRewardList = gModelActivity:GetModel13ConfigRewardList(sid,grade)
            if extraRewardList and #extraRewardList > 0 then
                for i,v in ipairs(extraRewardList) do
                    table.insert(rewardList2,v)
                end
            end
        end

        --- activityMoreInfo.buyPassReward 字段的，当前的下标拿
        local c_rewardList2 = LxDataHelper.ParseItem(self._buyPassArr[posIdx])
        for i,v in ipairs(c_rewardList2) do
            table.insert(rewardList2,v)
        end


        local changeRewardList1, changeRewardList2 = gModelActivity:GetSelectOpenCommonReward(sid, rewardList1, rewardList2)

        local cfg = gModelActivity:GetWebActivityDataById(sid)
        local strText1 = entryCfg1.description
        if cfg and cfg.config.eModel == ModelActivity.MODEL_PASSC then
            changeRewardList1 = LxDataHelper.ParseItem(cfg.config.popupShowItem)
            strText1 = cfg.config.popupDesc1
        end

        self._rewardList1 = changeRewardList1
        self._rewardList2 = changeRewardList2

        local expend2 = tonumber(entryCfg1.expend2)
        self._buyBtnStr = gModelPay:GetShowByWelfareId(expend2)
        self:SetWndText(self.mText1, strText1)
    elseif self._modelActivityType == ModelActivity.MODEL_PASSE then
        self:ChangeItem(self._tabTransList[self._index], false)
        self:ChangeItem(self._tabTransList[itempos], true)

        self._index = itempos
        local posIdx = itempos
        self._canBuy = tonumber(self._bGuys[posIdx]) ~= 1

        local itemdata = self._itemdata[itempos]
        local entry = itemdata.entry
        local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid, entry.pageId, entry.entryId)

        self._rewardList1 = LxDataHelper.ParseItem(itemdata.popupShowItem)
        self._rewardList2 = LxDataHelper.ParseItem(entryCfg1.reward)
        local expend2 = tonumber(entryCfg1.expend2)
        self._buyBtnStr = gModelPay:GetShowByWelfareId(expend2)
        self:SetWndText(self.mText1, itemdata.title1)
        self:SetWndText(self.mText2, itemdata.title2)

        local popupBuyEnd = itemdata.popupBuyEnd
        if LxUiHelper.IsImgPathValid(popupBuyEnd) then
            self:SetWndEasyImage(self.mBuyEnd, popupBuyEnd, nil, true)
        end
    end

    self:RefreshBuyBtn()
    self:RefreshContent()
end

function UIPkBuyPopBig:RefreshBuyBtn()
    local isShowBuy = self._canBuy
    CS.ShowObject(self.mBuyBtn, isShowBuy)
    CS.ShowObject(self.mBuyEnd, not isShowBuy)

    if isShowBuy then
        self:SetWndButtonText(self.mBuyBtn, self._buyBtnStr)
        local entry = self._entry
        self:SetWndClick(self.mBuyBtn, function(...)
            local entryId
            local expend2
            local pageId
            -- if self._modelActivityType == ModelActivity.Growth_Capital then
            -- 	gModelPay:GiftPayCtrlSpecial(1,self._buyPrice,ModelPay.PAY_TYPE_ACTIVITY,self._sid)
            if self._modelActivityType == ModelActivity.MODEL_PASSA
                    or self._modelActivityType == ModelActivity.MODEL_PASSC then
                entryId = entry.entryId
                expend2 = tonumber(entry.MarketData.expend2)
                pageId = entry.pageId
                gModelPay:GiftPayCtrl(entryId, expend2, ModelPay.PAY_TYPE_ACTIVITY, 0, self._sid, pageId)
            elseif self._modelActivityType == ModelActivity.MODEL_PASSB
                    or self._modelActivityType == ModelActivity.MODEL_PASSD then
                local itempos = self._index
                local itemdata = self._itemdata[itempos]
                entryId = itemdata.entryId
                expend2 = tonumber(itemdata.MarketData.expend2)
                pageId = itemdata.pageId
                gModelPay:GiftPayCtrl(entryId, expend2, ModelPay.PAY_TYPE_ACTIVITY, 0, self._sid, pageId)
            elseif self._modelActivityType == ModelActivity.FREE_ENJOY_FUND then
                entryId = entry.entryId
                expend2 = entry.marketData.expend2
                pageId = entry.pageId
                gModelPay:GiftPayCtrl(entryId, expend2, ModelPay.PAY_TYPE_ACTIVITY, nil, self._sid, pageId)
            elseif self._modelActivityType == ModelActivity.MODEL_PASSE then
                local itempos = self._index
                local itemdata = self._itemdata[itempos]
                local curEntry = itemdata.entry
                entryId = curEntry.entryId
                expend2 = tonumber(curEntry.MarketData.expend2)
                pageId = curEntry.pageId
                gModelPay:GiftPayCtrl(entryId, expend2, ModelPay.PAY_TYPE_ACTIVITY, 0, self._sid, pageId)
            end
        end)
    end
end

function UIPkBuyPopBig:OnDrawUIIconEasyExtra(list,item,itemdata,itempos)
    local ItemTab = self:FindWndTrans(item,"ItemTab")
    if not ItemTab then return end

    local showItemTab = false
    local constData = itemdata.constData
    if constData then
        local descript = constData.descript
        if descript and descript > 0 then
            local imgPath = gModelNormalActivity:GetPrivilegeTabImg(descript)
            if LxUiHelper.IsImgPathValid(imgPath) then
                self:SetWndEasyImage(ItemTab,imgPath)
                showItemTab = true
            end
        end
    end
    CS.ShowObject(ItemTab,showItemTab)
end

function UIPkBuyPopBig:RefreshContent()
    local list = self._rewardList1
    local listNum = list and #list or 0
    local isShow = listNum > 0
    local isMax
    CS.ShowObject(self.mContent1, isShow)
    if isShow then
        isMax = listNum > 4
        CS.ShowObject(self.mRewardList1, not isMax)
        CS.ShowObject(self.mRewardListMax1, isMax)

        local uiList
        if not isMax then
            uiList = self._rewardListCls1
            if not uiList then
                uiList = self:CreateUIIconEasyList(self.mRewardList1)
                self._rewardListCls1 = uiList
            end
        else
            uiList = self._rewardListClsMax1
            if not uiList then
                uiList = self:CreateUIIconEasyList(self.mRewardListMax1)
                self._rewardListClsMax1 = uiList
            end
        end
        uiList:EnableScroll(isMax, true)
        uiList:RefreshList(list, true)
    end

    list = self._rewardList2
    listNum = list and #list or 0
    isShow = listNum > 0
    CS.ShowObject(self.mContent2, isShow)
    if isShow then
        isMax = listNum > 4
        CS.ShowObject(self.mRewardList2, not isMax)
        CS.ShowObject(self.mRewardListMax2, isMax)

        local uiList1
        if not isMax then
            uiList1 = self._rewardListCls2
            if not uiList1 then
                uiList1 = self:CreateUIIconEasyList(self.mRewardList2)
                self._rewardListCls2 = uiList1
            end
        else
            uiList1 = self._rewardListClsMax2
            if not uiList1 then
                uiList1 = self:CreateUIIconEasyList(self.mRewardListMax2)
                self._rewardListClsMax2 = uiList1
            end
        end
        uiList1:EnableScroll(isMax, true)
        uiList1:RefreshList(list, true)
    end
end

function UIPkBuyPopBig:RefreshTab()
    local list = self._itemdata
    local showTab = list and #list > 1 or false
    CS.ShowObject(self.mTabContent, showTab)
    if (not showTab) then
        self:OnClickTab(1, true)
        return
    end

    local defaultIndex = 1
    local index = self._index
    if (index and index > 0) then
        defaultIndex = index
    else
        for i, v in ipairs(self._bGuys) do
            if (v == "0") then
                defaultIndex = i
                break
            end
        end
    end

    local isShowMax = #list > 3
    CS.ShowObject(self.mMaxTabList, isShowMax)
    CS.ShowObject(self.mMinTabList, not isShowMax)
    local uiList1 = self:GetUIScroll("cell")
    if (not isShowMax) then
        uiList1:Create(self.mMinTabList, list, function(...)
            self:TabListItem(...)
        end)
        uiList1:EnableScroll(false)
    else
        uiList1:Create(self.mMaxTabList, list, function(...)
            self:TabListItem(...)
        end, UIItemList.NORMAL)
        uiList1:EnableScroll(true, true)
        local uiList = uiList1:GetList()
        uiList:DelayScrollTo(defaultIndex, UIListEasy.SCROLL_CENTER)
    end

    self:OnClickTab(defaultIndex, true)
end

function UIPkBuyPopBig:ChangeItem(trans, isSel)
    if (not trans) then
        return
    end
    local btnTab3 = CS.FindTrans(trans, "BtnTab3")
    self:SetWndTabStatus(btnTab3, isSel and LWnd.StateOn or LWnd.StateOff)
end

function UIPkBuyPopBig:InitEvent()
    self:SetWndClick(self.mBgImage, function(...)
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mCloseBtn, function(...)
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UIPkBuyPopBig:InitCommand()
    self._sid = self:GetWndArg("sid")
    self._modelActivityType = self:GetWndArg("modelActivityType")
    self._entry = self:GetWndArg("entry")
    self._grade = self:GetWndArg("grade")
    self._index = self:GetWndArg("index")
    self._rewards = self:GetWndArg("rewards")
    self._buyBtnStr = self:GetWndArg("buyBtnStr")
    self._heroImgPath = self:GetWndArg("heroImgPath")
    self._titleName = self:GetWndArg("titleName")
    local bGuys = self:GetWndArg("bGuys")

    local activityData = gModelActivity:GetActivityBySid(self._sid)
    if not activityData then
        self:WndClose()
        return
    end

    local activityMoreInfo = JSON.decode(activityData.moreInfo)
    local webData = gModelActivity:GetWebActivityDataById(self._sid)
    if not webData then
        return
    end

    local cfg = webData.config

    -- if self._modelActivityType == ModelActivity.Growth_Capital then -- 成长基金
    -- 	self._buyPrice = cfg.price
    -- 	self._canBuy = true
    -- 	self._titleStr = ccClientText(15820)
    -- 	self._title1 = ccClientText(15818)

    -- 	local maxEntry = #self._entry
    -- 	local maxLvl = self._entry[maxEntry].needLvl
    -- 	self._title2 = string.replace(ccClientText(15819), maxLvl)
    -- 	local roleLvl = gModelPlayer:GetPlayerLv()

    -- 	local rewardList1 = {}
    -- 	local rewardList2 = {}
    -- 	for k,v in ipairs(self._entry) do
    -- 		if v.needLvl <= roleLvl then
    -- 			table.insert(rewardList1, v.rewards)
    -- 		else
    -- 			table.insert(rewardList2, v.rewards)
    -- 		end
    -- 	end
    -- 	self._rewardList1 = self:GetCombineSameReward(rewardList1)

    -- 	if roleLvl < maxLvl then
    -- 		self._rewardList2 = self:GetCombineSameReward(rewardList2)
    -- 	end

    -- 	--local rmbPayPoint = gModelPay:GetRMBValueByWelfareId(self._buyPrice)
    -- 	--if rmbPayPoint then
    -- 	self._buyBtnStr	=gModelPay:GetShowByWelfareId(self._buyPrice) --  string.replace(ccClientText(15601),rmbPayPoint)
    -- 	--end
    if self._modelActivityType == ModelActivity.Growth_Capital_2 then
        -- 成长基金 2
        self._priceEntry = self:GetWndArg("priceEntry")
        self._buyPrice = self._priceEntry.priceId
        self._canBuy = true
        self._titleStr = ccClientText(15820)
        self._title1 = ccClientText(15818)

        local maxEntry = #self._entry
        local maxLvl = self._entry[maxEntry].needLvl
        self._title2 = string.replace(ccClientText(15819), maxLvl)
        local roleLvl = gModelPlayer:GetPlayerLv()

        local rewardList1 = {}
        local rewardList2 = {}
        for k, v in ipairs(self._entry) do
            if v.needLvl <= roleLvl then
                table.insert(rewardList1, v.rewards)
            else
                table.insert(rewardList2, v.rewards)
            end
        end
        self._rewardList1 = self:GetCombineSameReward(rewardList1)

        if roleLvl < maxLvl then
            self._rewardList2 = self:GetCombineSameReward(rewardList2)
        end
        self._buyBtnStr = gModelPay:GetShowByWelfareId(self._buyPrice)
    elseif self._modelActivityType == ModelActivity.MODEL_PASSA then
        -- 精英战令A
        self._canBuy = activityMoreInfo.buyPassNum == 0
        self._titleStr = ccClientText(12166)
        self._title1 = cfg.popupDesc1
        self._title2 = cfg.popupDesc2
        local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid, self._entry.pageId, self._entry.entryId)
        local expend2 = tonumber(entryCfg1.expend2)
        self._buyBtnStr = gModelPay:GetShowByWelfareId(expend2)
        self._rewardList1 = LxDataHelper.ParseItem(cfg.popupShowItem)
        self._rewardList2 = LxDataHelper.ParseItem(activityMoreInfo.buyPassReward)
    elseif self._modelActivityType == ModelActivity.MODEL_PASSB then
        -- 精英战令B
        self._titleStr = ccClientText(12166)
        self._title2 = cfg.popupDesc2
        self._buyEndImg = cfg.popupBuyEnd
        self._buyPassArr = string.split(activityMoreInfo.buyPassReward, "|")
        self._bGuys = string.split(activityMoreInfo.buyPassNum, ",")
        local list = {}
        for i = 1, self._grade do
            table.insert(list, self._entry[i])
        end

        self._itemdata = list
    elseif self._modelActivityType == ModelActivity.MODEL_PASSC then
        -- 奇境战令C
        self._canBuy = activityMoreInfo.buyPassNum == 0
        self._titleStr = ccClientText(12166)
        self._title1 = cfg.popupDesc1
        self._title2 = cfg.popupDesc2
        self._buyEndImg = cfg.popupBuyEnd
        local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid, self._entry.pageId, self._entry.entryId)
        local expend2 = tonumber(entryCfg1.expend2)
        self._buyBtnStr = gModelPay:GetShowByWelfareId(expend2)
        self._rewardList1 = LxDataHelper.ParseItem(cfg.popupShowItem)
        self._rewardList2 = LxDataHelper.ParseItem(activityMoreInfo.buyPassReward)
    elseif self._modelActivityType == ModelActivity.MODEL_PASSD then
        -- 种族战令D
        self._titleStr = ccClientText(12166)
        self._title2 = cfg.popupDesc2
        self._buyEndImg = cfg.popupBuyEnd
        self._buyPassArr = string.split(activityMoreInfo.buyPassReward, "|")
        if LOG_INFO_ENABLED then
            if activityMoreInfo.buyPassReward then
                printInfoNR("activityMoreInfo.buyPassReward = " .. activityMoreInfo.buyPassReward)
            end
        end
        self._bGuys = string.split(activityMoreInfo.buyPassNum, ",")
        local list = {}
        for i = 1, self._grade do
            table.insert(list, self._entry[i])
        end
        self._itemdata = list
    elseif self._modelActivityType == ModelActivity.FREE_ENJOY_FUND then
        -- 畅享基金
        self._canBuy = true
        self._titleStr = activityData.title
        self._title1 = ccClientText(21403)
        local rewardList1 = self._rewards[1]
        local rewardList2 = self._rewards[2]
        self._rewardList1 = self:GetCombineSameReward(rewardList1)
        if rewardList2 then
            self._title2 = ccClientText(21404)
            self._rewardList2 = self:GetCombineSameReward(rewardList2)
        end
        -- elseif self._modelActivityType == ModelActivity.ACTIVITY_TOWER then -- 音乐节爬塔
        -- 	self._canBuy = tonumber(activityMoreInfo.buyPassNum) == 0
        -- 	self._titleStr = activityData.title
        -- 	local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid,self._entry.pageId,self._entry.entryId)
        -- 	local expend2 = tonumber(entryCfg1.expend2)
        -- 	self._title1 = ccClientText(15818)
        -- 	self._title2 = entryCfg1.description
        -- 	self._buyBtnStr = gModelPay:GetShowByWelfareId(expend2)
        -- 	self._rewardList1 = LxDataHelper.ParseItem(activityMoreInfo.buyPassReward)
        -- 	self._rewardList2 = LxDataHelper.ParseItem(entryCfg1.moreInfo)
        --self._rewardList1 = LxDataHelper.ParseItem(cfg.popupShowItem)
        -- elseif self._modelActivityType == ModelActivity.MODEL_ACTIVITY_TYPE_84 then
        -- 	self._titleStr = ccClientText(12166)
        -- 	self._canBuy = true
        -- 	local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid,self._entry.pageId,self._entry.entryId)
        -- 	self._title1 = ccClientText(15818)
        -- 	self._title2 = entryCfg1.description
        -- 	local expend2 = tonumber(entryCfg1.expend2)
        -- 	self._buyBtnStr = gModelPay:GetShowByWelfareId(expend2)
        -- 	self._rewardList1 = LxDataHelper.ParseItem(entryCfg1.reward)
        -- 	self._rewardList2 = LxDataHelper.ParseItem(entryCfg1.moreInfo)
    elseif self._modelActivityType == ModelActivity.MODEL_PASSE then
        -- 战斗通行证E（精英战令E）
        self._canBuy = activityMoreInfo.buyPassNum == 0
        self._titleStr = ccClientText(38804)
        self._bGuys = bGuys
        local popupMenuSwitch = string.split(cfg.popupMenuSwitch, "|")
        local popupMenuSwitchList = {}
        for k, v in ipairs(popupMenuSwitch) do
            local data = string.split(v, "=")
            popupMenuSwitchList[tonumber(data[1])] = data[2]
        end

        local list = {}
        for i = 1, self._grade do
            local data = {
                entry = self._entry[i],
                popupImage = cfg["popupImage" .. i],
                title1 = cfg["popupDesc" .. ((i - 1) * 2 + 1)],
                title2 = cfg["popupDesc" .. ((i - 1) * 2 + 2)],
                popupShowItem = cfg["popupShowItem" .. i],
                popupBuyEnd = cfg["popupBuyEnd" .. i],
                popupMenuSwitch = popupMenuSwitchList[i],
            }
            table.insert(list, data)
        end
        self._itemdata = list
    end
end

function UIPkBuyPopBig:RefreshUI()
    local addLine = -30
    if gLGameLanguage:IsFrenchVersion() then
        addLine = -50
    end
    if self._titleName then
        local lng = gLGameLanguage:GetLanguageFlag()
        local str = gModelActivity:GetLngNameById(self._titleName, lng)
        self:SetWndText(self.mTitleText, str)
    else
        self:SetWndText(self.mTitleText, self._titleStr)
    end
    if self._isEnus then
        self:InitTextSizeWithLanguage(self.mTitleText, -10)
        self:InitTextLineWithLanguage(self.mTitleText, 25)
    else
        self:InitTextSizeWithLanguage(self.mTitleText, -2)
        self:InitTextLineWithLanguage(self.mTitleText, -50)

    end
    self:SetWndText(self.mText1, self._title1 or "")
    self:InitTextSizeWithLanguage(self.mText1, -2)
    self:InitTextLineWithLanguage(self.mText1, addLine)
    if not string.isempty(self._title2) then
        self:SetWndText(self.mText2, self._title2)
    end
    self:InitTextSizeWithLanguage(self.mText1, -2)
    self:InitTextLineWithLanguage(self.mText2, addLine)

    if self._bugEndImg then
        self:SetWndEasyImage(self.mBuyEnd, self._bugEndImg, nil, true)
    end

    if self._heroImgPath then
        self:SetWndEasyImage(self.mHeroImg, self._heroImgPath, nil, true)
    end

    if self._modelActivityType == ModelActivity.MODEL_PASSA
            or self._modelActivityType == ModelActivity.MODEL_PASSC
            or self._modelActivityType == ModelActivity.FREE_ENJOY_FUND then
        self:RefreshBuyBtn()
        self:RefreshContent()
    elseif self._modelActivityType == ModelActivity.MODEL_PASSB
            or self._modelActivityType == ModelActivity.MODEL_PASSD
            or self._modelActivityType == ModelActivity.MODEL_PASSE then
        self:RefreshTab()
    end
end

function UIPkBuyPopBig:TabListItem(list, item, itemdata, itempos)
    self._tabTransList[itempos] = item
    local btnTab3 = CS.FindTrans(item, "BtnTab3")
    local nameStr
    if self._modelActivityType == ModelActivity.MODEL_PASSE then
        nameStr = itemdata.popupMenuSwitch
    else
        local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid, itemdata.pageId, itemdata.entryId)
        nameStr = entryCfg1.name
    end

    self:SetWndTabText(btnTab3, nameStr)
    self:SetWndClick(item, function(...)
        self:OnClickTab(itempos)
    end)
    self:SetWndTabStatus(btnTab3, self._index == itempos and LWnd.StateOn or LWnd.StateOff)
end

function UIPkBuyPopBig:RefreshForeign()
    if self._isVie then
        self:InitTextSizeWithLanguage(self.mTitleText,-16)
    end
end

function UIPkBuyPopBig:OnTimer(key)
    if key == self._timeLimitTimer then
        self:StartTimeLimitTimer()
    end
end

function UIPkBuyPopBig:StartTimeLimitTimer()
    local cdInfo = self._cdInfo
    if not cdInfo then
        self:TimerStop(self._timeLimitTimer)
        return
    end
    local endTime = cdInfo.endTime
    local curTime = GetTimestamp()
    local timeLeft = endTime - curTime
    local timeStr = ""
    if timeLeft > 0 then
        timeStr = LUtil.GetFormatCDTime(timeLeft)
    else
        self:OnClickTab(self._index,true)
    end
    self:SetWndText(self.mTimeLimitCD,timeStr)
    CS.ShowObject(self.mTimeLimitDiv,true)
end

function UIPkBuyPopBig:GetCombineSameReward(rewardList)
    local itemList = {}
    local oldNum
    for k, v in ipairs(rewardList) do
        for p, q in pairs(v) do
            local itemId = q.itemId
            if not itemList[itemId] then
                local reward = {
                    itemNum = q.itemNum,
                    isShowEff = q.isShowEff,
                    itemType = q.itemType,
                    itemId = q.itemId,
                }

                itemList[itemId] = reward
            else
                oldNum = itemList[itemId].itemNum
                itemList[itemId].itemNum = q.itemNum + oldNum
            end
        end
    end

    local resList = {}
    for k, v in pairs(itemList) do
        table.insert(resList, v)
    end

    return resList
end

function UIPkBuyPopBig:CreateUIIconEasyList(root)
    local uiList = UIIconEasyList:New()
    uiList:Create(self, root,nil,nil,function(...)
        self:OnDrawUIIconEasyExtra(...)
    end)
    uiList:SetIconParentPath("itemRoot/CommonUI/Icon")
    return uiList
end

function UIPkBuyPopBig:InitMessage()
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
        self:WndClose()
    end)
end
------------------------------------------------------------------
return UIPkBuyPopBig