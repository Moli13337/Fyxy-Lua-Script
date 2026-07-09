---
--- Created by Administrator.
--- DateTime: 2023/10/26 9:50:41
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActTenYell:LWnd
local UIActTenYell = LxWndClass("UIActTenYell", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActTenYell:UIActTenYell()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActTenYell:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActTenYell:OnCreate()
    LWnd.OnCreate(self)
    self._tabTransList = {}                -- 页面表
    self._tabIndex = 0                        -- 页面标签下标
    self._cellTransList = {}                -- 天数表
    self._cellIndex = 0                    -- 第几天
    self._selectDay = 0                        -- tab里面选择的第几天

    self._WndTimerKey = "UIActTenYell_Timer"   -- 计时器key
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActTenYell:OnStart()
    LWnd.OnStart(self)
    self._isVie =gLGameLanguage:IsVieVersion()
    self._isFirstSetHero = true
    self:InitUI()
    self:SetWndButtonText(self.mPayBtn, ccClientText(10141))
    --self:DoWndStartScale(0,self.mPop)
    self:InitEvent()
    self:InitMsg()
    self:InitData()

    local effKey = self.mExTraRewardGetEff:GetInstanceID()
    self._stageEff = self:CreateWndEffect(self.mExTraRewardGetEff, "fx_anniu_02", effKey, 100, false, false, 10)

    self._stageEff:SetVisible(false)
    self:RefreshForeign()
end

--region 新增信息 --------------------------------------------------------------------------------
function UIActTenYell:RefreshNewInfo()
    self:SetLeftTime()

    if not self:IsTimerExist(self._WndTimerKey) then
        self:TimerStart(self._WndTimerKey, 1, false, -1)
    end
end

function UIActTenYell:InitEvent()
    self:SetWndClick(self.mBgImage, function(...)
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)

    self:SetWndClick(self.mReturnBtn, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mPayBtn, function()
        self:PayBtnEvent()
    end)

    self:SetWndClick(self.mExTraRewardGetBtn, function()
        self:OnGetExtraRewardClick()
    end)

    self:SetWndClick(self.mExtraRewardItem, function()
        gModelGeneral:ShowCommonItemTipWnd(self._showTipsReward)
    end)
end

--endregion --------------------------------------------------------------------------------------

--region 新增定时器和对应的回调 --------------------------------------------------------------------------------
function UIActTenYell:OnTimer(key)
    if (self._WndTimerKey == key) then

        self:SetLeftTime()
    end
end

--额外奖励的设置
function UIActTenYell:SetExtraReward()
    CS.ShowObject(self.mExtraReward, false)

    if not self._extraReward then
        return
    end
    if self._isExtra == 0 then
        return
    end

    CS.ShowObject(self.mExtraReward, true)

    local key_1 = self._tabIndex > 0 and self._tabIndex or 1
    local key_2 = 1
    local isMax = false
    if self._extraRewardState then
        for _, stateInfo in ipairs(self._extraRewardState) do
            local state = string.split(stateInfo, "=")
            local state_page = tonumber(state[1])
            local state_stage = tonumber(state[2])

            if key_1 == state_page then
                key_2 = state_stage + 1

                if key_2 > #self._extraReward[key_1] then

                    key_2 = #self._extraReward[key_1]
                    isMax = true
                end
            end
        end
    end

    --key_1 和 key_2 的部分
    self._getExtraRewardStr = string.format("%d=%d", key_1, key_2)

    --拿到对应的配置
    local reward = self._extraReward[key_1][key_2]
    local itemData = LUtil.GetRefItemFourData(reward)

    local baseClass = self._extarRewardBaseClass
    if not baseClass then
        baseClass = CommonIcon:New()
        self._extarRewardBaseClass = baseClass
        baseClass:Create(CS.FindTrans(self.mExtraRewardItem, "Root/CommonUI/Icon"))
    end

    baseClass:SetCommonReward(itemData.type, itemData.refId, itemData.count)
    baseClass:DoApply()

    self._extraRewardInfo = {
        type = itemData.type,
        refId = itemData.refId,
        count = itemData.count,
    }
    --self._isHeroActive = gModelHeroBook:FindHeroInfoStatusByHeroRefId(self._extraRewardInfo.refId)

    self._showTipsReward = itemData

    self._key_1 = key_1
    self._key_2 = key_2


end

--额外奖励的上报
function UIActTenYell:OnGetExtraRewardClick()
    if self._extraRewardInfo.type == 2 then
        self._isHeroActive = gModelHeroBook:FindHeroInfoStatusByHeroRefId(self._extraRewardInfo.refId)
        --printInfoN2("----haveHero---", self._isHeroActive)
    end

    gModelActivity:OnActivitySpecialOpReq(self._sid, nil, nil, nil, self._getExtraRewardStr, ModelActivity.TenCall_OPE)
end

function UIActTenYell:PayBtnEvent()
    local status = self._status
    if status == 0 then
        gModelFunctionOpen:Jump(self._jump, self:GetWndName())
        self:WndClose()
    elseif status == 1 then
        local index
        for i, v in ipairs(self._page) do
            if v.pageId == self._tabIndex then
                index = i
            end
        end
        if not index then
            return
        end
        local tabData = self._page[index]
        local dayData = self._dayList[self._selectDay]
        if dayData then
            local pageId, entryId = tabData.pageId, dayData.entryId
            gModelActivity:OnActivityReceiveGoalReq(self._sid, pageId, entryId)
        end
    else
        GF.ShowMessage(ccClientText(15637))
    end
end

function UIActTenYell:CellListItem(list, item, itemdata, itempos)
    self._cellTransList[itemdata.entryId] = item
    local rewardList = CS.FindTrans(item, "ItemScroll")
    local onImage = CS.FindTrans(item, "OnImage")
    local dayText = CS.FindTrans(item, "DayText")
    local endImage = CS.FindTrans(item, "EndImage")
    local mayImage = CS.FindTrans(item, "MayImage")
    local unfinishImage = CS.FindTrans(item, "UnFinishImage")
    local pageId = itemdata.pageId
    local entryId = itemdata.entryId
    local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, pageId, entryId)

    CS.ShowObject(endImage, false)
    CS.ShowObject(mayImage, false)
    CS.ShowObject(unfinishImage, false)
    CS.ShowObject(onImage, false)

    local playEff = false

    if itemdata.goalData.status == 1 then
        CS.ShowObject(mayImage, true)
        CS.ShowObject(onImage, true)
        --self._finishTaskCount = self._finishTaskCount + 1
        playEff = true
    elseif itemdata.goalData.status == 2 then
        CS.ShowObject(endImage, true)
        --self._finishTaskCount = self._finishTaskCount + 1
    else
        CS.ShowObject(unfinishImage, true)
    end

    self:SetWndText(dayText, entryCfg.name)

    local itemDataList = LxDataHelper.ParseItem(entryCfg.reward) -- itemdata.items
    --local InstanceID = item:GetInstanceID()
    --local uiIconEasyList = self._cellList:GetItemCls(InstanceID)
    --if not uiIconEasyList then
    --    uiIconEasyList = UIIconEasyList:New()
    --    self._cellList:SetItemCls(InstanceID, uiIconEasyList)
    --    uiIconEasyList:Create(self, rewardList)
    --    uiIconEasyList:SetShowNum(false)
    --    uiIconEasyList:SetIconParentPath("Root/CommonUI/Icon")
    --    uiIconEasyList:SetShowExtraNum(true, "Root/NumText")
    --end
    --
    --uiIconEasyList:SetItemEff("fx_ui_qiandao_lingqutishi", 100, nil, true)
    --uiIconEasyList:RefreshList(itemDataList, true)

    local showItemData = {}
    for _, value in ipairs(itemDataList) do
        local data = {}
        data.item = value
        data.canPalyEffect = playEff
        table.insert(showItemData, data)
    end
    rewardList = CS.FindTrans(item, "RewardList")
    self:InitRewardList(rewardList, showItemData)
end

--设置剩余时间
function UIActTenYell:SetLeftTime()
    local leftStr = ccClientText(41100)

    local endTime = self._endTime

    if endTime and endTime > 0 then
        local timespan = endTime - GetTimestamp()

        if timespan > 0 then
            local timeStr = LUtil.FormatTimespanCn(timespan)
            leftStr = string.replace(leftStr, timeStr)
            self:SetWndText(self.mLeftTime, leftStr)
        end

    end
end
function UIActTenYell:RefreshForeign()
    if self._isVie then
        self.mTextImage.localScale=Vector3.one * 0.9
    end
end

function UIActTenYell:OnDrawRewardCell(list, item, showitemdata, itempos)

    local itemdata = showitemdata.item
    local playEff = showitemdata.canPalyEffect
    local dataIndex = itemdata.dataIndex

    local CommonUITrans = self:FindWndTrans(item, "CommonUI")
    local IconTrans = self:FindWndTrans(CommonUITrans, "Icon")
    local effTrans = self:FindWndTrans(item, "Eff")

    self:SetIconClickScale(IconTrans, true)
    local instanceID = item:GetInstanceID()
    local baseClass = self:GetCommonIcon(instanceID)
    baseClass:Create(IconTrans)
    baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
    baseClass:DoApply()

    local effectName = "fx_ui_qiandao_lingqutishi"
    self:CreateWndEffect(effTrans, effectName, instanceID, 100, false, false)

    CS.ShowObject(effTrans, playEff)

    self:SetWndClick(IconTrans, function()
        if canGet then
            self:GetActivityReward(itemdata, dataIndex)
        else
            gModelGeneral:ShowCommonItemTipWnd(itemdata)
        end
    end)
end

function UIActTenYell:SetExtraRewardBtnState()

    if not self._itemGetEff then
        self._itemGetEff = {}
    end

    local effKey = self.mExtraRewardItem:GetInstanceID()

    --fx_ui_qiandao_lingqutishi  fx_daoju_orange
    if not self._itemGetEff[effKey] then
        local effRoot = CS.FindTrans(self.mExtraRewardItem, "Root/CommonUI/ExtraItemEff")

        self._itemGetEff[effKey] = self:CreateWndEffect(effRoot, "fx_daoju_orange", "fx_daoju_orange" .. effKey, 100, false, false, 4)
    end

    self._itemGetEff[effKey]:SetVisible(true)

    if self._extraRewardIsGet[self._key_1] and self._extraRewardIsGet[self._key_1][self._key_2] then
        --已领取
        CS.ShowObject(self.mExTraRewardGetBtn, false)
        CS.ShowObject(self.mExTraRewardGotImg, true)
    else
        CS.ShowObject(self.mExTraRewardGetBtn, true)
        CS.ShowObject(self.mExTraRewardGotImg, false)

        if not self._dayList then
            return
        end

        if self._finishTaskCount >= #self._dayList then
            --可领取
            self._stageEff:SetVisible(true)
            self:SetWndEasyImage(self.mExTraRewardGetBtn, "public_btn_2_2")


        else

            self:SetWndEasyImage(self.mExTraRewardGetBtn, "public_btn_ash_1")
        end
    end


end

function UIActTenYell:RefreshData()
    local list = self._page
    if (self._tabList) then
        self._tabList:RefreshList(list)
    else
        self._tabList = self:GetUIScroll("tab")
        self._tabList:Create(self.mTabScroll, list, function(...)
            self:ListItem(...)
        end)
    end

    if self._tabIndex > 0 then
        self:OnClickTab(self._tabIndex)
        return
    end
    for i, v in ipairs(list[1].entry) do
        if v.goalData.status ~= 2 then
            self:OnClickTab(list[1].pageId)
            return
        end
    end
    self:OnClickTab(list[1].pageId)
end

function UIActTenYell:RefreshPayBtn()
    self:SetWndButtonGray(self.mPayBtn, false)
    CS.ShowObject(self.mPayBtn, true)

    local redpointTran = CS.FindTrans(self.mPayBtn, "redPoint")

    local isGray = false
    local btnStr = ""
    local status = self._status
    local show = true
    CS.ShowObject(redpointTran, false)
    if status == 0 then
        btnStr = ccClientText(10141)
        show = not (self._jump == 0)
    elseif status == 1 then
        btnStr = ccClientText(15617)

        CS.ShowObject(redpointTran, true)
    else
        isGray = true
        btnStr = ccClientText(15618)
    end
    self:SetWndButtonGray(self.mPayBtn, isGray)

    self:SetWndButtonText(self.mPayBtn, btnStr)
    CS.ShowObject(self.mPayBtn, show)
end

function UIActTenYell:RefreshTop()
    local sid = self._sid

    local tenCallData = gModelActivity:GetActivityBySid(sid) -- gModelActivity:GetTenCallActivity()

    if not tenCallData then
        self:WndClose()
        return
    end

    local activityCfg = gModelActivity:GetWebActivityDataById(sid)
    if not activityCfg then
        return
    end

    local data = activityCfg.config --JSON.decode(tenCallData.moreInfo)
    self._jump = tonumber(data.jump)

    --背景图的设置
    self._isFullScreen = data.isFullScreen or 0
    CS.ShowObject(self.mBgImage, self._isFullScreen == 0)
    CS.ShowObject(self.mBgImageFullScreen, self._isFullScreen == 1)

    --任务进度的表示
    self._progressShow = data.progressShow or 0

    --剩余时间的位置设置
    if not string.isempty(data.timePos) then
        self._timePos = string.split(data.timePos, "|")
        local x = tonumber(self._timePos[1]) + self.mTimeBg.localPosition.x
        local y = tonumber(self._timePos[2]) + self.mTimeBg.localPosition.y
        self.mTimeBg.localPosition = Vector2.New(x, y)
    end

    --下方页签的显隐
    self._pageSwitch = data.pageSwitch or 0
    CS.ShowObject(self.mTabScroll, self._pageSwitch == 1)

    --额外奖励部分的显隐标识
    self._isExtra = data.isExtra

    if self._isExtra == 1 then
        --额外奖励
        local extarReward_temp_1 = string.split(data.extraReward, ";")
        self._extraReward = {}
        if extarReward_temp_1 then
            for k, v in ipairs(extarReward_temp_1) do
                local extarReward_temp_2 = string.split(v, "|")

                local extarReward_temp_3 = string.split(extarReward_temp_2[1], "=")

                local reward_key_1 = tonumber(extarReward_temp_3[1])
                local reward_key_2 = tonumber(extarReward_temp_3[2])

                if not self._extraReward[reward_key_1] then
                    self._extraReward[reward_key_1] = {}
                end
                self._extraReward[reward_key_1][reward_key_2] = extarReward_temp_2[2]
            end
        end
    end

    local image = string.split(data.image, ";")
    local image1 = string.split(data.image1, ";")
    local image2 = string.split(data.image2, ";")
    local imgList, img1List, img2List = {}, {}, {}
    for i, v in ipairs(image) do
        v = string.split(v, "=")
        local day, dayImg = tonumber(v[1]), v[2]
        imgList[day] = dayImg
    end
    for i, v in ipairs(image1) do
        v = string.split(v, "=")
        local day, dayImg = tonumber(v[1]), v[2]
        img1List[day] = dayImg
    end
    for i, v in ipairs(image2) do
        v = string.split(v, "=")
        local day, dayImg = tonumber(v[1]), v[2]
        img2List[day] = dayImg
    end

    local nameIcon = string.split(data.nameIcon, ";")
    local nameIcon1 = string.split(data.nameIcon1, ";")
    local nameIcon2 = string.split(data.nameIcon2, ";")
    local nameIconList, nameIcon1List, nameIcon2List = {}, {}, {}
    local nameIconPosList, nameIcon1PosList, nameIcon2PosList = {}, {}, {}
    for i, v in ipairs(nameIcon) do
        if not string.isempty(v) then
            v = string.split(v, "=")
            local day, dayImg, daypos = tonumber(v[1]), v[2], v[3]
            nameIconList[day] = dayImg
            nameIconPosList[day] = daypos
        end
    end
    for i, v in ipairs(nameIcon1) do
        if not string.isempty(v) then
            v = string.split(v, "=")
            local day, dayImg, daypos = tonumber(v[1]), v[2], v[3]
            nameIcon1List[day] = dayImg
            nameIcon1PosList[day] = daypos
        end
    end
    for i, v in ipairs(nameIcon2) do
        if not string.isempty(v) then
            v = string.split(v, "=")
            local day, dayImg, daypos = tonumber(v[1]), v[2], v[3]
            nameIcon2List[day] = dayImg
            nameIcon2PosList[day] = daypos
        end
    end

    --figure
    local figure = string.split(data.figure, ";")
    local figure1 = string.split(data.figure1, ";")
    local figure2 = string.split(data.figure2, ";")
    local figureList, figure1List, figure2List = {}, {}, {}
    for i, v in ipairs(figure) do
        if not string.isempty(v) then
            v = string.split(v, "=")
            local day, daytype, dayImg, daypos = tonumber(v[1]), tonumber(v[2]), v[3], v[4]
            figureList[day] = { type = daytype, img = dayImg, pos = daypos }
        end
    end
    for i, v in ipairs(figure1) do
        if not string.isempty(v) then
            v = string.split(v, "=")
            local day, daytype, dayImg, daypos = tonumber(v[1]), tonumber(v[2]), v[3], v[4]
            figure1List[day] = { type = daytype, img = dayImg, pos = daypos }
        end
    end
    for i, v in ipairs(figure2) do
        if not string.isempty(v) then
            v = string.split(v, "=")
            local day, daytype, dayImg, daypos = tonumber(v[1]), tonumber(v[2]), v[3], v[4]
            figure2List[day] = { type = daytype, img = dayImg, pos = daypos }
        end
    end

    self._imgMapList = {}
    table.insert(self._imgMapList, { nameIcon = nameIconList, nameIconPosList = nameIconPosList, image = imgList, figure = figureList })
    table.insert(self._imgMapList, { nameIcon = nameIcon1List, nameIconPosList = nameIcon1PosList, image = img1List, figure = figure1List })
    table.insert(self._imgMapList, { nameIcon = nameIcon2List, nameIconPosList = nameIcon2PosList, image = img2List, figure = figure2List })

    self._pageSort = {}
    local pageSort = data.pageSort
    if pageSort then
        local _pageSort = self._pageSort
        pageSort = string.split(pageSort, ";")
        for i, v in ipairs(pageSort) do
            v = string.split(v, "=")
            local page, entry, sort = tonumber(v[1]), tonumber(v[2]), tonumber(v[3])
            local pageSortList = _pageSort[page]
            if not pageSortList then
                pageSortList = {}
                _pageSort[page] = pageSortList
            end
            pageSortList[entry] = sort
        end
    end
end

function UIActTenYell:OnActivitySpecialOpResp(pb)
    local sid = pb.sid
    if self._sid ~= sid then
        return
    end

    if self._extraRewardInfo and self._extraRewardInfo.type == 2 then
        if self._isHeroActive then
            --激活过了
            --printInfoN2("--激活过了--弹一次窗", "-----")
            local heroList = {}
            table.insert(heroList, { refId = self._extraRewardInfo.refId })
            gModelGeneral:ShowUpHero(heroList, nil, nil, nil, nil, true)
        else


        end
    end

    gModelActivity:OnActivityPageReq(self._sid)
end

function UIActTenYell:OnClickTab(pageId)
    --把当前栏目的任务进度重置下
    self._finishTaskCount = 0
    --点击标签
    for k, v in pairs(self._tabTransList) do
        self:ChangeBtnImage(v, false)
    end
    if self._tabIndex > 0 then
        local trans = self._tabTransList[self._tabIndex]
        self:ChangeBtnImage(trans, false)
    end
    local trans = self._tabTransList[pageId]
    self:ChangeBtnImage(trans, true)
    self._tabIndex = pageId
    self._dayList = {}
    for i, v in ipairs(self._page) do
        if v.pageId == pageId then

            self._dayList = v.entry
        end
    end

    local x = 300 - (#self._dayList) * 100

    if x == 0 then
        x = -8
    end
    local pos = Vector2.New(x, self.mCellScroll.localPosition.y)
    self:SetAnchorPos(self.mCellScroll, pos)

    self:RefreshPayBtn()
    if (self._cellList) then
        self._cellList:RefreshData(self._dayList)
        self._cellList:DrawAllItems(true)
    else
        self._cellList = self:GetUIScroll("cell")
        self._cellList:Create(self.mCellScroll, self._dayList, function(...)
            self:CellListItem(...)
        end, UIItemList.SUPER_GRID)
    end
    self._cellList:EnableScroll(false, true)

    for k, itemdata in ipairs(self._dayList) do
        if itemdata.goalData.status == 1 then
            self._finishTaskCount = self._finishTaskCount + 1
        elseif itemdata.goalData.status == 2 then
            self._finishTaskCount = self._finishTaskCount + 1
        end
    end

    self:RefreshBgShow(pageId)

    self:SetExtraReward()
end

function UIActTenYell:InitMsg()
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
        self:SetPbData(pb)
    end)
    self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
        gModelActivity:OnActivityPageReq(self._sid)
    end)

    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(data, sid)
        if self._sid ~= sid then
            return
        end

        self:RefreshTop()
        gModelActivity:OnActivityPageReq(self._sid)
    end)

    self:WndNetMsgRecv(LProtoIds.ActivitySpecialOpResp, function(pb)
        self:OnActivitySpecialOpResp(pb)
    end)
end

function UIActTenYell:ListItem(list, item, itemdata, itempos)
    self._tabTransList[itemdata.pageId] = item
    local img = CS.FindTrans(item, "Image")
    local text = CS.FindTrans(item, "UIText")
    local redPoint = CS.FindTrans(item, "redPoint")
    local bool = false
    for i, v in ipairs(itemdata.entry) do
        if bool then
            break
        end
        if v.goalData.status == 1 then
            bool = true
        end
    end
    CS.ShowObject(redPoint, bool)
    local entry = itemdata.entry
    if entry and entry[1] then
        local pageId = itemdata.pageId
        local entryId = entry[1].entryId
        local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, pageId, entryId)

        self:SetWndText(text, entryCfg.description)
    end
    self:SetWndClick(item, function(...)
        self:OnClickTab(itemdata.pageId)
    end, LSoundConst.CLICK_PAGE_COMMON)
end

function UIActTenYell:ChangeBtnImage(trans, bool)
    if not trans then
        return
    end
    local color, icon
    local onImage = CS.FindTrans(trans, "Image")
    local text = CS.FindTrans(trans, "UIText")
    if bool then
        color = "734f22ff"
        icon = "public_btn_tab_on_5"
    else
        color = "ffffffff"
        icon = "public_btn_tab_off_5"
    end
    color = LUtil.ColorByHex(color)
    local xuitxt = self:FindWndText(text)
    self:SetXUITextColor(xuitxt, color)
    self:SetWndEasyImage(onImage, icon, nil, true)
end

function UIActTenYell:RefreshBgShow(pageId)
    local data = self._dayList[pageId]
    if data then
        local schedules = data.goalData.schedules[1]
        local schedule, goal = schedules.schedule, schedules.goal
        local str = string.replace(ccClientText(10142), schedule, goal)


        --新增控制文本显示  -- 若为1  则改成当前完成的个数
        if self._progressShow == 1 then
            str = string.replace(ccClientText(10184), self._finishTaskCount, #self._dayList)
        else
            str = string.replace(ccClientText(10142), schedule, goal)
        end

        self:SetWndText(self.mPayNumText, str)

        local entryId = data.entryId
        local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, pageId, entryId)

        --local temp = JSON.decode(data.moreInfo)
        local moreInfo = entryCfg.moreInfo
        moreInfo = string.split(moreInfo, "=")
        local day, index = tonumber(moreInfo[1]), tonumber(moreInfo[2])
        local imgList = self._imgMapList[day]
        local image, nameIcon, figure, nameIconPos = imgList.image[index], imgList.nameIcon[index], imgList.figure[index], imgList.nameIconPosList[index]
        if image then
            self:SetWndEasyImage(self.mBgImageFullScreen, image)
        end
        if nameIcon then
            self:SetWndEasyImage(self.mTextImage, nameIcon, nil, true)

            if nameIconPos then
                local nameIconPos = string.split(nameIconPos, ",")
                self.mTextImage.localPosition = Vector2(self.mTextImage.localPosition.x + tonumber(nameIconPos[1]), self.mTextImage.localPosition.y + tonumber(nameIconPos[2]))
            end

        end

        local figurePos = string.split(figure.pos, ",")

        --解析下信息 spine
        if self._isFirstSetHero then
            self._isFirstSetHero = false

            if figure.type == 2 then
                CS.ShowObject(self.mImage_Hero, false)
                CS.ShowObject(self.mSpine_Hero, true)

                local key = figure.img

                local spine = self:FindWndSpineByKey(key)
                if not spine then
                    self:CreateWndSpine(self.mSpine_Hero, figure.img, key, false, function(dpSpine)
                        --dpSpine:PlayAnimationSolid("animation", true)
                    end)
                else
                    --spine:PlayAnimationSolid("animation", true)
                end

                self.mSpine_Hero.localPosition = Vector2(self.mSpine_Hero.localPosition.x + tonumber(figurePos[1]), self.mSpine_Hero.localPosition.y + tonumber(figurePos[2]))
            else
                -- 1 图片也是默认情况
                CS.ShowObject(self.mImage_Hero, true)
                CS.ShowObject(self.mSpine_Hero, false)

                self:SetWndEasyImage(self.Image_Hero, figure.img)

                self.mImage_Hero.localPosition = Vector2(self.mImage_Hero.localPosition.x + tonumber(figurePos[1]), self.mImage_Hero.localPosition.y + tonumber(figurePos[2]))
            end

            printInfoNR("========= image,nameIcon = ", image, nameIcon)
        end
    end
    local dataList = self._dayList
    local day, status = 0, 0
    local entryId, firshId = 0, 0
    if dataList then
        for i, v in ipairs(dataList) do
            if day ~= 0 then
                break
            end
            local tStatus = v.goalData.status
            if tStatus == 1 then
                if i == 1 then
                    firshId = v.entryId
                end
                entryId = v.entryId
                day = i
            end
        end
        if day == 0 then
            local isNoEntry = entryId == 0
            local maxGetDay = 0
            for i, v in ipairs(dataList) do
                if day ~= 0 then
                    break
                end
                if i == 1 then
                    firshId = v.entryId
                end
                local tStatus = v.goalData.status
                if tStatus == 2 and maxGetDay < i then
                    if isNoEntry then
                        entryId = v.entryId
                    end
                    maxGetDay = i
                end
            end
            if maxGetDay == 0 then
                maxGetDay = 1
            end
            day = maxGetDay
        end
    end
    self._selectDay = day
    self._selectEntryId = entryId
    self._firstEntryId = firshId
    if day == 0 then
        day = 1
    end
    local today = dataList[day]
    if today then
        status = today.goalData.status
    end

    self._status = status
    self:RefreshPayBtn()

    self:SetExtraRewardBtnState()
end

function UIActTenYell:SetPbData(pb)
    local sid = pb.sid
    if self._sid ~= sid then
        return
    end
    for i, v in ipairs(pb.pages) do
        local page = gModelActivity:GenerateActivePageDataFromPb(v)
        self._pageData[v.pageId] = page
    end
    self._page = {}

    local data = {}                    -- 记录天数
    for i, v in ipairs(self._pageData) do
        table.insert(self._page, v)
        local day = 0
        for _i, _v in ipairs(v.entry) do
            if day ~= 0 then
                break
            end
            if _v.goalData.status == 1 then
                day = _i
            end
        end
        if day == 0 then
            day = 1
        end
        data[i] = day
    end
    self._tabTransList = {}
    local tempIndex = 0
    local tempSame = false
    for i, v in ipairs(self._page) do
        if tempSame then
            break
        end
        tempSame = v.pageId == self._tabIndex
        if tempSame then
            tempIndex = self._tabIndex
        end
    end
    self._tabIndex = tempIndex

    if not table.isempty(self._pageSort) then
        table.sort(self._page, function(page1, page2)
            local pageId1, pageId2 = page1.pageId, page2.pageId
            local entryId1, entryId2 = page1.entry[1].entryId, page2.entry[1].entryId
            local sort1, sort2 = self._pageSort[pageId1][entryId1], self._pageSort[pageId2][entryId2]
            return sort1 < sort2
        end)
    end

    --[[		self._tabIndex = 0
        for i,v in ipairs(data) do
            if self._tabIndex ~= 0 then break end
            if v == 1 then self._tabIndex = i end
        end]]



    --这里尝试看下 对应的activydata
    self._activity = gModelActivity:GetActivityBySid(self._sid)

    self._endTime = self._activity.endTime

    local moreInfo = JSON.decode(self._activity .moreInfo)


    --拿下对应的数据 等后面测试的时候在做调整吧 这里看的话 是一个table表
    self._extraRewardState = moreInfo.receiveStages
    --解析一份阶段数据
    self._extraRewardIsGet = {}
    if self._extraRewardState then
        for k, stateInfo in ipairs(self._extraRewardState) do
            local state = string.split(stateInfo, "=")
            local state_page = tonumber(state[1])
            local state_stage = tonumber(state[2])

            if not self._extraRewardIsGet[state_page] then
                self._extraRewardIsGet[state_page] = {}
            end
            self._extraRewardIsGet[state_page][state_stage] = true
        end
    end

    --刷新 新增的信息部分
    self:RefreshNewInfo()
    self:SetExtraReward()

    self:RefreshData()

    self:SetExtraRewardBtnState()
end
function UIActTenYell:InitData()
    self._pageData = {}
    --local tenCallData = self:GetWndArg("activityData") --gModelActivity:GetTenCallActivity()
    local sid = self:GetWndArg("sid")

    local page = self:GetWndArg("page")
    local subpage = self:GetWndArg("subPage") --支持跳转
    if subpage then
        sid = gModelActivity:GetSidByUniqueJump(subpage)
    end

    self._sid = sid

    if self._sid then
        gModelActivity:ReqActivityConfigData(self._sid)
    end

    self:SetWndText(self.mCloseTipObj, ccClientText(15702))

    self:SetTextTile(self.mReturnBtn, ccClientText(15710))

    --[15617]	[領  取]
    --[15618]	[已領取]
    self:SetWndText(self.mExTraRewardGetTxt, ccClientText(15617))
end

function UIActTenYell:InitRewardList(trans, list, playEff)
    local key = trans:GetInstanceID()
    local uiRewardList = self:FindUIScroll(key)
    if uiRewardList then
        uiRewardList:RefreshList(list)
    else
        uiRewardList = self:GetUIScroll(key)
        uiRewardList:Create(trans, list, function(...)
            self:OnDrawRewardCell(...)
        end)
    end
    uiRewardList:EnableScroll(#list > 4, true)
end

--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIActTenYell


