---
--- Created by Administrator.
--- DateTime: 2024/5/20 20:03:54
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFlandBossTk:LWnd
local UIFlandBossTk = LxWndClass("UIFlandBossTk", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFlandBossTk:UIFlandBossTk()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFlandBossTk:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFlandBossTk:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFlandBossTk:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    self._isVie =gLGameLanguage:IsVieVersion()
    self.jpj = gLGameLanguage:IsJapanVersion()
    self:InitData()
    self:InitTypeList()

    self:InitPara()
    self:InitEvent()
    self:RefreshForeign()
end

function UIFlandBossTk:SetTypeItem(list, item, itemdata, itempos)
    local BtnTab1 = self:FindWndTrans(item, "BtnTab1")
    local bg = self:FindWndTrans(item, "bg")
    local redPointTrans = self:FindWndTrans(bg, "redPoint")

    local refId = itemdata
    local typeName = self._typeNameList[refId]

    self:SetWndTabText(BtnTab1, typeName, -2, -10)
    self:SetWndClick(bg, function()
        self:OnClickTab(itempos)
    end)

    local state = refId == self._curPageType and LWnd.StateOn or LWnd.StateOff

    self:SetWndTabStatus(BtnTab1, state)

    if not self._typeBtnList then
        self._typeBtnList = {}
    end

    self._typeBtnList[itempos] = item
    self._pageRedPointList[refId] = redPointTrans
    return item
end
--endregion --------------------------------------------------------------------------------------

--region 界面方法 --------------------------------------------------------------------------------
function UIFlandBossTk:ResetActivePageData(pb)
    for k, v in ipairs(pb.pages) do
        if v.pageId == ModelActivity.FAIRYLAND_BOSS_REWARD then
            --仙境迷踪_手动领取奖励
            local page = gModelActivity:GenerateActivePageDataFromPb(v)
            --构建信息
            self:RefreshBossRewardInfo(page)

        elseif v.pageId == ModelActivity.FAIRYLAND_BOSS_REWARD_EMAIL then
            --仙境迷踪_邮件结算
            local page = gModelActivity:GenerateActivePageDataFromPb(v)
            --构建信息
            self:RefreshAccumulateHurtInfo(page)

        end
    end

    --全部构建完之后 进行页面的第一个切换
    self:OnClickTab(1)
end

function UIFlandBossTk:RefreshBossEmailReward()
    --标题部分 title intro
    self:SetWndText(self.mTitle, ccClientText(43113))
    --奖励列表的部分
    local uiList = self._uiBossEmailRewardList
    if not uiList then
        uiList = self:GetUIScroll("BossEmailRewardList_UIFlandBossTk")
        uiList:Create(self.mBossEmailRewardList, self._accumulateHurtInfo, function(...)
            self:CreateEmailListItem(...)
        end, UIItemList.SUPER)
    end

    self._uiBossEmailRewardList = uiList
end

function UIFlandBossTk:OnDrawItemCell(list, item, itemdata, itempos)
    local IconTrans = self:FindWndTrans(item, "itemRoot/CommonUI/Icon")
    local itemId = itemdata.itemId
    local itemNum = itemdata.itemNum
    local itemType = itemdata.itemType
    local instanceId = item:GetInstanceID()
    local baseClass = self:GetCommonIcon(instanceId)
    baseClass:Create(IconTrans)
    baseClass:SetCommonReward(itemType, itemId, itemNum)
    baseClass:DoApply()

    if itemdata.isShowEff then
        local Eff = self:FindWndTrans(item, "Eff")
        local effKey = Eff:GetInstanceID()
        local ref = gModelItem:GetRefByRefId(itemId)
        local bgEff = ref and ref.bgEff
        self:DestroyWndEffectByKey(effKey)
        if not string.isempty(bgEff) then
            self:CreateWndEffect(Eff, bgEff, effKey, 100, false, false)
            CS.ShowObject(Eff, true)
        else
            CS.ShowObject(Eff, false)
        end
    end
    local itemNumTrans = self:FindWndTrans(item, "itemNum")
    CS.ShowObject(itemNumTrans, false)
    self:SetWndText(itemNumTrans, LUtil.NumberCoversion(itemNum))

    self:SetWndClick(IconTrans, function()
        gModelGeneral:ShowCommonItemTipWnd(itemdata)
    end)
end

function UIFlandBossTk:InitEvent()
    self:SetWndClick(self.mBtnClose, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mFullBg, function()
        self:WndClose()
    end)

    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
        self:OnActivityConfigData(...)
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
        self:OnActivityPageResp(pb)
        self:RefreshBossReward()
    end)


end

--初始化 下发的tab页面
function UIFlandBossTk:InitTypeList()
    local typeDataList = self._pageType
    self._pageRedPointList = {}
    local uiList = self:FindUIScroll("uiTypeList")
    if not uiList then
        uiList = self:GetUIScroll("uiTypeList")
        uiList:Create(self.mTypeList, typeDataList, function(...)
            self:SetTypeItem(...)
        end)
    else
        uiList:RefreshList(typeDataList)
    end
    --self._uiTypeList = UIItemList:New(self)
    --self._uiTypeList:Create(self.mTypeList,typeDataList,function (...) self:SetTypeItem(...) end)
end

function UIFlandBossTk:RefreshBossReward()
    --标题部分 title intro
    self:SetWndText(self.mTitle, ccClientText(43111))
    self:SetWndText(self.mIntro, ccClientText(43112))
    if self.jpj then
        self:InitTextSizeWithLanguage(self.mIntro,-4)
    end

    --奖励列表的部分
    local uiList = self._uiBossRewardList
    if not uiList then
        uiList = self:GetUIScroll("BossRewardList_UIFlandBossTk")
        uiList:Create(self.mBossRewardList, self._bossRewardInfo, function(...)
            self:CreateListItem(...)
        end, UIItemList.SUPER)
    else
        uiList:RefreshList(self._bossRewardInfo)
        uiList:DrawAllItems()
    end

    self._uiBossRewardList = uiList
end
--endregion --------------------------------------------------------------------------------------

--region 事件和回调 --------------------------------------------------------------------------------
function UIFlandBossTk:OnActivityConfigData(data, sid)
    if sid ~= self._sid then
        return
    end

    gModelActivity:OnActivityPageReq(self._sid)
end

function UIFlandBossTk:OnClickTab(tabIndex)
    if self._curPageIndex == tabIndex then
        return
    end
    local oldSelect = self._curPageIndex

    if not oldSelect or oldSelect == -1 then
        for k, v in pairs(self._typeBtnList) do
            local BtnTab1 = self:FindWndTrans(v, "BtnTab1")
            self:SetWndTabStatus(BtnTab1, LWnd.StateOff)
        end
    else
        local oldSelectItem = self._typeBtnList[oldSelect]
        if oldSelectItem then
            local BtnTab1 = self:FindWndTrans(oldSelectItem, "BtnTab1")
            self:SetWndTabStatus(BtnTab1, LWnd.StateOff)
        end
    end

    self._curPageIndex = tabIndex
    local newSelectItem = self._typeBtnList[tabIndex]
    if newSelectItem then
        local BtnTab1 = self:FindWndTrans(newSelectItem, "BtnTab1")
        self:SetWndTabStatus(BtnTab1, LWnd.StateOn)
    end

    self:RefreshTabInfo(self._pageType[tabIndex])
end

function UIFlandBossTk:CreateEmailListItem(list, item, itemdata, itempos)
    --节点部分
    local itemRoot = self:FindWndTrans(item, "bg")
    local title = self:FindWndTrans(itemRoot, "title")
    local Slider = self:FindWndTrans(itemRoot, "Slider")
    local progress = self:FindWndTrans(itemRoot, "progress")
    local itemList = self:FindWndTrans(itemRoot, "itemList")
    local UnfinishedImg = self:FindWndTrans(itemRoot, "UnfinishedImg")
    local FinishedImg = self:FindWndTrans(itemRoot, "FinishedImg")
    local StageIcon = self:FindWndTrans(itemRoot, "StageIcon")
    local Stage = self:FindWndTrans(itemRoot, "Stage")

    if self._isEnus then
        progress  = self:FindWndTrans(itemRoot, "progress_enus")
    end

    if self.jpj then
        self:SetAnchorPos(progress,Vector2.New(200,62))
    end

    --当前的伤害进度
    --local hurtValue = itemdata.entryCfg.condResetType == 1 and self._dailyMaxHurt or self._maxHurt
    --local hurtValue = itemdata.entryCfg.condResetType == 1 and  self._settlementCycleMaxHurt or 0
    local hurtValue =itemdata.entryCfg.condResetType == 1 and  self._dailyMaxHurt or self._settlementCycleMaxHurt

    local progressPercent = tonumber(itemdata.webData.goalData.schedules[1].schedule)

    local tempTarget = string.split(itemdata.entryCfg.condition, ",")
    local target = tonumber(tempTarget[2])

    if progressPercent == 0 then
        progressPercent = hurtValue / target
    end

    local curHurt = progressPercent * target
    --local curHurt= tonumber(itemdata.webData.goalData.schedules[1].schedule)
    --local progressPercent =curHurt/target

    if progressPercent > 1 then
        progressPercent = 1
    end

    --设置描述的文本
    self:SetWndText(title, ccLngText(itemdata.entryCfg.description))
    local hurtProgress = string.format("%s/%s", LUtil.NumberCoversion(curHurt), LUtil.NumberCoversion(target))-- 后续改成用文本
    self:SetWndText(progress, hurtProgress)

    --进度
    local slide = self:FindWndSlider(Slider)
    slide.value = progressPercent
    --先创建奖励吧  reward
    self:InitItemList(itemList, itemdata.entryCfg.reward)

    --标签
    self:SetWndEasyImage(StageIcon, itemdata.entryCfg.icon)

    self:SetWndText(Stage, itemdata.entryCfg.name)
    --设置当前的状态
    local isCompletion = false
    if progressPercent >= 1 then
        isCompletion = true
    end

    CS.ShowObject(UnfinishedImg, not isCompletion)
    CS.ShowObject(FinishedImg, isCompletion)
end

function UIFlandBossTk:CreateListItem(list, item, itemdata, itempos)
    --节点部分
    local itemRoot = self:FindWndTrans(item, "bg")
    local title = self:FindWndTrans(itemRoot, "title")
    local Slider = self:FindWndTrans(itemRoot, "Slider")
    local progress = self:FindWndTrans(itemRoot, "progress")
    local itemList = self:FindWndTrans(itemRoot, "itemList")
    local BtnBlue = self:FindWndTrans(itemRoot, "BtnBlue")
    local UnfinishedImg = self:FindWndTrans(itemRoot, "UnfinishedImg")
    local FinishedImg = self:FindWndTrans(itemRoot, "FinishedImg")
    local GotImg = self:FindWndTrans(itemRoot, "GotImg")

    if self._isEnus then
        progress  = self:FindWndTrans(itemRoot, "progress_enus")
    end

    --
    local hurtValue = itemdata.entryCfg.condResetType == 1 and self._dailyMaxHurt or self._maxHurt
    --当前的伤害进度
    local progressPercent = tonumber(itemdata.webData.goalData.schedules[1].schedule)
    local tempTarget = string.split(itemdata.entryCfg.condition, ",")
    local target = tonumber(tempTarget[2])

    if progressPercent == 0 then
        progressPercent = hurtValue / target
    end

    local curHurt = progressPercent * target
    --设置描述的文本
    self:SetWndText(title, ccLngText(itemdata.entryCfg.description))
    local hurtProgress = string.format("%s/%s", LUtil.NumberCoversion(curHurt), LUtil.NumberCoversion(target))-- 后续改成用文本
    self:SetWndText(progress, hurtProgress)

    if self.jpj then
        self:SetAnchorPos(progress,Vector2.New(200,62))
    end

    --进度
    local slide = self:FindWndSlider(Slider)
    slide.value = progressPercent
    --先创建奖励吧  reward
    self:InitItemList(itemList, itemdata.entryCfg.reward)

    --领取部分
    local pageId = itemdata.webData.pageId
    local entryId = itemdata.webData.entryId
    self:SetWndClick(BtnBlue, function(...)
        gModelActivity:OnActivityReceiveGoalReq(self._sid, pageId, entryId)
    end)

    --设置按钮状态   progressPercent<1 未完成
    local isGet = itemdata.webData.goalData.status == 1
    CS.ShowObject(UnfinishedImg, not (progressPercent >= 1))
    CS.ShowObject(BtnBlue, progressPercent >= 1)

    local btnStr = isGet and ccClientText(43114) or ccClientText(43115)

    if progressPercent >= 1 then
        CS.ShowObject(BtnBlue, isGet)
        CS.ShowObject(GotImg, not isGet)
    else
        CS.ShowObject(GotImg, false)
    end
    self:SetWndButtonText(BtnBlue, btnStr)
end

function UIFlandBossTk:InitItemList(root, rewards)
    local instanceId = root:GetInstanceID()
    local uiList = self:FindUIScroll(instanceId)

    local itemList = LxDataHelper.ParseItem(rewards)

    if uiList then
        uiList:RefreshList(itemList)
    else
        uiList = self:GetUIScroll(instanceId)
        uiList:Create(root, itemList, function(...)
            self:OnDrawItemCell(...)
        end)
    end
end

--邮件结算奖励 当前的累计伤害 icon 和奖励仙境迷踪_邮件结算
function UIFlandBossTk:RefreshAccumulateHurtInfo(page)
    if page then
        --伤害奖励部分
        self._accumulateHurtInfo = {}

        for p, q in ipairs(page.entry) do
            local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, q.pageId, q.entryId)
            if not entryCfg then
                return
            end

            local refid = string.split(entryCfg.moreInfo, "|")
            local refId = tonumber(refid[1])

            if self._bossRefId == refId then
                local info = { webData = q, entryCfg = entryCfg }
                table.insert(self._accumulateHurtInfo, info)
                self._schedule = tonumber(q.goalData.schedules[1].schedule)
            end
        end
    end


end

--刷新页面
function UIFlandBossTk:RefreshTabInfo(tabType)
    if tabType == ModelActivity.FAIRYLAND_BOSS_REWARD then
        CS.ShowObject(self.mBossRewardList, true)
        CS.ShowObject(self.mBossEmailRewardList, false)

        self:RefreshBossReward()
    elseif tabType == ModelActivity.FAIRYLAND_BOSS_REWARD_EMAIL then
        CS.ShowObject(self.mBossRewardList, false)
        CS.ShowObject(self.mBossEmailRewardList, true)

        self:RefreshBossEmailReward()
    end
end
------------------------------------------------------------------

--region 初始化 --------------------------------------------------------------------------------
function UIFlandBossTk:InitPara()
    self._sid = self:GetWndArg("sid")
    self._bossRefId = self:GetWndArg("bossRefId")

    self._dailyMaxHurt = self:GetWndArg("dailyMaxHurt")
    self._maxHurt = self:GetWndArg("maxHurt")
    self._settlementCycleMaxHurt = self:GetWndArg("settlementCycleMaxHurt")
    gModelActivity:ReqActivityConfigData(self._sid)
end

function UIFlandBossTk:OnActivityPageResp(pb, ret)
    if self._sid ~= pb.sid then
        return
    end

    self:ResetActivePageData(pb)
    --self:RefreshRed()
    --self:RefreshContent()

end
function UIFlandBossTk:RefreshForeign()
    if self._isVie then
        self:InitTextSizeWithLanguage(self.mTitle,-6)
    end
end

function UIFlandBossTk:InitData()
    local challengeTask = ModelActivity.FAIRYLAND_BOSS_REWARD
    local hitTask = ModelActivity.FAIRYLAND_BOSS_REWARD_EMAIL

    self._curPageIndex = -1

    self._pageType = {
        challengeTask, --手动领取奖励
        hitTask, --挑战伤害
    }
    self._typeNameList = {
        [challengeTask] = ccClientText(43111),
        [hitTask] = ccClientText(43113),
    }
    self._typeDescList = {
        [challengeTask] = ccClientText(43112),
        [hitTask] = ccClientText(43117),
    }
end

function UIFlandBossTk:RefreshBossRewardInfo(page)
    self._bossRewardInfo = {}

    if page then
        --构建伤害列表的信息
        for p, q in ipairs(page.entry) do
            local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, q.pageId, q.entryId)
            if not entryCfg then
                return
            end

            if entryCfg.moreInfo == self._bossRefId then
                local data = {}
                data.entryCfg = entryCfg
                data.webData = q

                table.insert(self._bossRewardInfo, data)
            end
        end
    end

end

--endregion --------------------------------------------------------------------------------------

return UIFlandBossTk