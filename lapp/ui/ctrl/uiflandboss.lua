---
--- Created by Administrator.
--- DateTime: 2024/5/15 14:59:42
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFlandBoss:LWnd
local UIFlandBoss = LxWndClass("UIFlandBoss", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFlandBoss:UIFlandBoss()
    self._isFirstShow = true
    self._isOpenUI = true
end
------------------------------------------------------------------
--- 窗口关闭 
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFlandBoss:OnWndClose()
    self._isOpenUI = false
    --清理定时器
    self:ClearAllTimer()

    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFlandBoss:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFlandBoss:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    -------------------------------------

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    if self:CheckIsInFairylandBossBattle() then
        return
    end

    self:InitCommonText()
    self:InitTableData()
    self:InitEvent()
    self:InitPara()
end

function UIFlandBoss:InitData()
    local webData = gModelActivity:GetWebActivityDataById(self._sid)
    if not webData then
        return
    end
    -- 结束时间提前 所以新增的判断
    self._curBossRealEnd = false
    --这里获取活动的开启时间
    self._cfgDataMoreInfo = webData.config
    self._mainActivityData = gModelActivity:GetActivityBySid(self._sid)
    self._startTime = self._mainActivityData.startTime
    self._endTime = self._mainActivityData.endTime

    --解析排行榜的时间
    local tempRankTime = string.split(self._cfgDataMoreInfo.rankClearTime, ":")

    self._rankClearTime = tonumber(tempRankTime[1])


    --設置倒計時
    self:InitActivityOpenDay()
end

--排名信息
function UIFlandBoss:SetMyInfo()
    local curPlayerInfo = self._bossInfo[self._curBossIndex]
    --local showStr = curPlayerInfo.moreInfo.rankPlayer > 0 and tostring(curPlayerInfo.moreInfo.rankPlayer) or ccClientText(43102)
    --self:SetWndText(self.mSelfRank, showStr)
    --self:SetWndText(self.mSelfRecord, LUtil.NumberCoversion(curPlayerInfo.moreInfo.scorePlayer))
    local rankId = tonumber(curPlayerInfo.selfRank)
    gModelRank:OnRankReq(2, rankId, 1, 25, self._sid)--排行榜请求
end

--邮件结算奖励 当前的累计伤害 icon 和奖励仙境迷踪_邮件结算
function UIFlandBoss:RefreshAccumulateHurtInfo(page)
    if page then
        --构建信息 创建列表
        self._accumulateHurtInfo = {}
        self._schedule = {}

        for p, q in ipairs(page.entry) do
            local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, q.pageId, q.entryId)
            if not entryCfg then
                return
            end

            local refid = string.split(entryCfg.moreInfo, "|")
            local refId = tonumber(refid[1])

            if not self._accumulateHurtInfo[refId] then
                self._accumulateHurtInfo[refId] = {}
            end

            if not self._schedule[refId] then
                self._schedule[refId] = {}
            end

            local info = { entry = q, entryCfg = entryCfg }
            table.insert(self._accumulateHurtInfo[refId], info)

            --应该记录的进度是 p 值
            local schedule = tonumber(q.goalData.schedules[1].schedule)

            if schedule == 1 then
                self._schedule[refId].schedule = p

            end
            printInfoN2("cjh------------ModelActivity.ACTIVITY_FAIRYLAND", "UIFlandBoss----仙境迷踪_邮件结算")
        end
    end
    printInfoN2("cjh------------ModelActivity.ACTIVITY_FAIRYLAND", "UIFlandBoss----仙境迷踪_邮件结算")

    self:SetBossHurtRewardInfo()

end

function UIFlandBoss:CreateRewardListItem(list, item, itemdata, itempos)
    local root = CS.FindTrans(item, "itemRoot")

    local InstanceID = root:GetInstanceID()

    local uiCommonList = self._uiCommonList
    if not uiCommonList then
        uiCommonList = {}
    end

    local baseClass = uiCommonList[InstanceID]
    if not baseClass then
        baseClass = CommonIcon:New()
        uiCommonList[InstanceID] = baseClass
        baseClass:Create(root)
    end

    baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
    self:SetWndClick(root, function()
        gModelGeneral:ShowCommonItemTipWnd(itemdata)
    end)
    baseClass:DoApply()

    item.localScale = Vector3.one * 0.8
end

function UIFlandBoss:InitActivityOpenDay()
    local addTime = GetTimestamp() - self._startTime
    self._activityOpenDay = math.ceil((addTime) / 86400)
end

--boss任务
function UIFlandBoss:OnClickLookTask()
    --任务
    if not self._bossInfo then
        return
    end
    local bossData = self._bossInfo[self._curBossIndex]
    if not bossData then
        printInfoNR("self._activityPageDataBoss[self._subPage] is a nil, self._subPage = " .. (self._curBossIndex or "nil"))
        return
    end

    local sid, entryId, dailyMaxHurt, maxHurt, settlementCycleMaxHurt = self._sid, bossData.entryCfg.id, bossData.dailyMaxHurt, bossData.maxHurt, bossData.settlementCycleMaxHurt
    GF.OpenWnd("UIFlandBossTk", { sid = sid, bossRefId = entryId, dailyMaxHurt = dailyMaxHurt, maxHurt = maxHurt, settlementCycleMaxHurt = settlementCycleMaxHurt })
end

-- 创建一个boss立绘
function UIFlandBoss:CreateBossLiHui()

    local show = string.split(self._bossInfo[self._curBossIndex].entryCfg.show, "=")
    local entryCfg = self._bossInfo[self._curBossIndex].entryCfg
    local lihui = show[2]

    if not self._bossLihui then
        self._bossLihui = {}
    end

    local new = self._bossLihui[lihui]
    local old = self._curhight

    if old and new ~= old then
        old:SetVisible(false)
    end
    if new then
        new:SetVisible(true)
    else
        local dp = self:CreateWndSpine(self.mBossLihui, lihui, lihui, false, function()
        end)

        self._bossLihui[lihui] = dp
        new = dp
    end

    self._curhight = new

    --背景图设置
    local bg = self._bossInfo[self._curBossIndex].entryCfg.bgImage
    self:SetWndEasyImage(self.mView, bg)
    CS.ShowObject(self.mTopView, true)

    local spine_1 = self._bossInfo[self._curBossIndex].entryCfg.spineBg
    if not string.isempty(spine_1) then
        self:CreateWndSpine(self.mSpine_1, spine_1, spine_1, false, function()
        end)
    end

    local spine_2 = self._bossInfo[self._curBossIndex].entryCfg.spineBg2

    if not string.isempty(spine_2) then
        self:CreateWndSpine(self.mSpine_2, spine_2, spine_2, false, function()
        end)
    end
    --名字設置
    self:SetWndText(self.mBossName, ccLngText(entryCfg.name))
end

function UIFlandBoss:CreateServerTimer(endTime, monsterId, trans, isOpenBoss)
    if not self._loopTimer then
        self._loopTimer = {}
    end

    self._loopTimer[endTime] = LxTimer.LoopTimeCall(function()
        self:CallBossCountDown(endTime, monsterId, trans, isOpenBoss)
    end, 0, false, -1)
end

function UIFlandBoss:CallBossCountDown(times, monsterId, trans, isOpenBoss)
    local curTime = GetTimestamp()
    local lastTime = times - curTime

    if lastTime <= 0 then
        self:ClearAllTimer()
        --看是否要请求
        --gModelActivity:OnActivityPageReq(self._sid)

        self._curBossRealEnd = true
        return
    end

    local str
    local t1 = ccClientText(10304)  -- 天
    local t2 = ccClientText(10305)  -- 时
    local t3 = ccClientText(10306)  -- 分
    local t4 = ccClientText(10355)  -- 秒

    local t5 = ccClientText(11807)  -- 日
    local t6 = ccClientText(11808)  -- 月
    if isOpenBoss then


        if lastTime > 86400 then
            local d = math.floor(lastTime / 86400)
            local h = math.floor(lastTime / 3600) % 24
            --str = string.replace(ccClientText(18749), d, h)

            str = string.format("%d%s%d%s", d, t1, h, t2)
        elseif lastTime > 60 then
            local h = math.floor(lastTime / 3600)
            local m = math.floor(lastTime / 60) % 60

            str = string.format("%d%s%d%s", h, t2, m, t3)
        else

            local s = math.ceil(lastTime)
            str = string.format("%d%s%d%s", 0, t3, s, t4)
        end

    else
        local _data = LUtil.OSDate("*t", times)
        local m = _data.month
        local d = _data.day

        local t = {
            ["a1"] = LUtil.GetDayShow(tonumber(d)),
            ["a2"] = LUtil.GetMonthShow(tonumber(m)),
        }

        str = string.format("%d%s%d%s", m, t6, d, t5)
        if self._loopTimer then
            LxTimer.DelayTimeStop(self._loopTimer)
        end
    end
    if self._isOpenUI then
        self:SetWndText(trans, str)
    end
end

function UIFlandBoss:InitBossInfoList()
    local uiList = self._uiBossInfoList

    if not uiList then
        uiList = self:GetUIScroll("UIFlandBoss_BossInfoList")
        uiList:Create(self.mBossInfoList, self._bossInfo, function(...)
            self:ListBossInfoItem(...)
        end, UIItemList.SUPER)
    else
        if self._bossInfo then
            uiList:RefreshList(self._bossInfo)
        end
    end

    self._uiBossInfoList = uiList

    uiList:EnableScroll(false, true)
end

function UIFlandBoss:InitRewardList(reward, trans, listKey)
    if not self._rewardList then
        self._rewardList = {}
    end

    local uiList = self._rewardList[listKey]

    if not uiList then
        uiList = self:GetUIScroll(listKey)
        uiList:Create(trans, reward, function(...)
            self:CreateRewardListItem(...)
        end, UIItemList.SUPER)

        self._rewardList[listKey] = uiList
    else
        if self._PVEListData then
            uiList:RefreshList(self.reward)
        end
    end


    return uiList

end

--排行榜
function UIFlandBoss:OnClickLookRank()
    --排行榜
    local curPlayerInfo = self._bossInfo[self._curBossIndex]
    local rankReward = self._selfRankInfo[self._curBossIndex]

    --构建打开排行榜的数据
    if not curPlayerInfo then
        return
    end
    local rankId = tonumber(curPlayerInfo.selfRank)

    --构建排行的奖励
    local rewardList = {}
    for k, v in ipairs(rankReward) do
        local data = {
            rank = v.condition1 .. ',' .. v.condition2,
            reward = v.items,
        }
        table.insert(rewardList, data)
    end

    GF.OpenWndBottom("UIRkPop",
            { refId = tonumber(rankId), rewardList = rewardList, sid = self._sid })
end

function UIFlandBoss:CheckOpenTab()
    --判断第一个有没有开 没有开的话tab页签进行切换
    for k, v in ipairs(self._bossInfo) do
        if v.openData.isOpen then
            self._curBossRealEnd = false
            self:OnTabClick(k)
            return
        end
    end
end

function UIFlandBoss:ResetActivePageData(pb)
    for k, v in ipairs(pb.pages) do
        if v.pageId == ModelActivity.FAIRYLAND_BOSS_BASE then
            --仙境迷踪_BOSS挑战
            local page = gModelActivity:GenerateActivePageDataFromPb(v)
            self:RefreshBossInfo(page)
        elseif v.pageId == ModelActivity.FAIRYLAND_BOSS_REWARD then
            --仙境迷踪_手动领取奖励
            local page = gModelActivity:GenerateActivePageDataFromPb(v)
            self:RefreshBossRewardInfo(page)

        elseif v.pageId == ModelActivity.FAIRYLAND_BOSS_RANK_SELF then
            --仙境迷踪_个人排行
            local page = gModelActivity:GenerateActivePageDataFromPb(v)
            self:RefreshSelfRankInfo(page)

        elseif v.pageId == ModelActivity.FAIRYLAND_BOSS_REWARD_EMAIL then
            --仙境迷踪_邮件结算
            local page = gModelActivity:GenerateActivePageDataFromPb(v)
            self:RefreshAccumulateHurtInfo(page)

        end
    end
end

function UIFlandBoss:InitBossList()
    local uiList = self._uiBossList
    if not uiList then
        uiList = self:GetUIScroll("UIFlandBoss_BossList")
        uiList:Create(self.mBossTypeListNormal, self._bossInfo, function(...)
            self:ListItem(...)
        end, UIItemList.SUPER)
    else
        if self._bossInfo then
            uiList:RefreshList(self._bossInfo)
        end
    end
    self._uiBossList = uiList
end

function UIFlandBoss:OnTabClick(tabIndex)
    if self._curBossIndex ~= tabIndex then
        --
        local tabBossInfo = self._bossInfo[tabIndex]
        local isOpen = tabBossInfo.openData.isOpen
        if isOpen then

            self._curBossIndex = tabIndex

            self:RefreshBossInfoUI()
            self:SetSelfRankReward()
            self:SetBossHurtRewardInfo()
            self:CheckRedPointShow()
        else
            local showstr = tabBossInfo.openData.isEnd and ccClientText(43119) or ccClientText(43118)
            GF.ShowMessage(showstr)
        end
    end
end

function UIFlandBoss:CheckTaskRedPointShow()
    local taskRedpoint = false

    if self._activityPageDataStrategy then
        for k, v in ipairs(self._activityPageDataStrategy[self._curBossIndex]) do
            if v.status == 1 then
                taskRedpoint = true
                return taskRedpoint
            end
        end
    end
    return taskRedpoint
end

function UIFlandBoss:ChangeTabState(oldItem, curItem)
    --if oldItem then
    --    local oldsel = self:FindWndTrans(oldItem, "Sel")
    --    CS.ShowObject(oldsel, false)
    --end
    --
    --local cursel = self:FindWndTrans(curItem, "Sel")
    --CS.ShowObject(cursel, true)
end

function UIFlandBoss:RefreshRank()
    local curPlayerInfo = self._bossInfo[self._curBossIndex]
    ---获取前三
    local rankId = tonumber(curPlayerInfo.selfRank)
    local ranks = gModelRank:GetRankListInfo(2, rankId)

    for i = 1, 3 do
        local rank = ranks[i]
        local rankKey = "Rank" .. i
        local rankTran = self:FindWndTrans(self.mRankRoot, rankKey)
        local text = self:FindWndTrans(rankTran, "UIText")
        local txtStr = ""
        if rank then
            txtStr = rank.info._name
        else
            --虚位以待  42005
            txtStr = ccClientText(42005)
        end

        self:SetWndText(text, txtStr)
    end

    --设置第四个信息
    local showStr = curPlayerInfo.moreInfo.rankPlayer > 0 and tostring(curPlayerInfo.moreInfo.rankPlayer) or ccClientText(43102)
    local isShowMyTxt = not (curPlayerInfo.moreInfo.rankPlayer <= 3)
    CS.ShowObject(self.mRank4, isShowMyTxt)

    if isShowMyTxt then
        local strMeName = gModelPlayer:GetPlayerName()
        self:SetWndText(self.mTxtMeRank, showStr)
        self:SetWndText(self.mTxtMeName, strMeName)
    end
end

--没有奖励的时候也要进行奖励的初始化
function UIFlandBoss:InitRewardListNoGet(reward, trans, listKey)
    if not self._rewardList then
        self._rewardList = {}
    end

    local uiList = self._rewardList[listKey]

    if not uiList then
        uiList = self:GetUIScroll(listKey)
        uiList:Create(trans, reward, function(...)
            self:CreateRewardListItemNoGet(...)
        end, UIItemList.SUPER)

        self._rewardList[listKey] = uiList
    else
        if self._PVEListData then
            uiList:RefreshList(self.reward)
        end
    end

    return uiList
end

--倒计时
function UIFlandBoss:SetLeftTime()
    local curBossInfo = self._bossInfo[self._curBossIndex]

    --算下开始 和 结束的
    if curBossInfo then

        local starDay = curBossInfo.openData.starDay
        local endDay = curBossInfo.openData.endDay
        local isEnd = curBossInfo.openData.isEnd
        local isOpen = curBossInfo.openData.isOpen

        if isEnd then
            --结束状态
        else
            local addDay
            if isOpen then
                addDay = endDay
            else
                --活动还未开启
                addDay = starDay - 1
            end

            if addDay >= 1 then
                addDay = addDay - 1
            end

            local addTime = addDay * 86400 + self._rankClearTime * 3600

            local endTime = self._startTime + addTime
            if self._endTime > 0 then
                endTime = math.min(endTime, self._endTime)
            end

            --开计时器进行显示
            if self._loopTimer then
                LxTimer.DelayTimeStop(self._loopTimer)
            end

            self:CreateServerTimer(endTime, self._curBossIndex, self.mBossLeftTime, isOpen)

            self:CreateServerTimer(self._endTime, self._curBossIndex, self.mActivityLeftTime, isOpen)



            if self._isEnus then
                self:SetAnchorPos(self.mBossLeftTime,Vector2.New(80,-16))
                self:SetAnchorPos(self.mActivityLeftTime,Vector2.New(80,0))
            end
            if self._isVie then
                self:SetAnchorPos(self.mBossLeftTime,Vector2.New(105,-16))
                self:SetAnchorPos(self.mActivityLeftTime,Vector2.New(75,0))
            end
        end
    end
end

function UIFlandBoss:OnActivityPageResp(pb, ret)
    if self._sid ~= pb.sid then
        return
    end

    self:ResetActivePageData(pb)
    self:RefreshUI()
end


--刷新boss页面数据
function UIFlandBoss:RefreshBossInfo(page)
    if page then
        self._bossInfo = {}

        for p, q in ipairs(page.entry) do
            local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, q.pageId, q.entryId)
            if not entryCfg then
                return
            end

            local cfgMoreInfoData = string.split(entryCfg.moreInfo, '=')
            local openTimes = string.split(cfgMoreInfoData[1], ',')
            local starDay = tonumber(openTimes[1])
            local endDay = tonumber(openTimes[2])
            local isOpen = self._activityOpenDay >= starDay and self._activityOpenDay <= endDay
            local isEnd = self._activityOpenDay > endDay
            local openData = { starDay = starDay, endDay = endDay, isOpen = isOpen, isEnd = isEnd }

            --关联的排行榜的类型
            local cfgMoreInfoData = string.split(entryCfg.moreInfo, '=')
            local rankIndexData = string.split(cfgMoreInfoData[2], ',')

            local moreInfo = JSON.decode(q.moreInfo)

            --boss的伤害数据
            local dailyMaxHurt = moreInfo.dailyMacHurt
            local maxHurt = moreInfo.max_boss_hurt
            local settlementCycleMaxHurt = moreInfo.settlementCycleMaxHurt

            local canCombat  = moreInfo.canCombat
            local info = { entryCfg = entryCfg, moreInfo = moreInfo, openData = openData, selfRank = rankIndexData[1], entryId = q.entryId, pageId = q.pageId, dailyMaxHurt = dailyMaxHurt, maxHurt = maxHurt,settlementCycleMaxHurt=settlementCycleMaxHurt,canCombat=canCombat }
            table.insert(self._bossInfo, info)
        end
    end

    if #self._bossInfo > 0 then
        self:InitBossList()

        self:InitBossInfoList()

        self:CheckOpenTab()

        CS.ShowObject(self.mBossInfoListDiv, #self._bossInfo > 1)
    end


    --BOSS信息构建完成 页面的显示
    self:RefreshBossInfoUI()

end
function UIFlandBoss:CreateRewardListItemNoGet(list, item, itemdata, itempos)
    local root = CS.FindTrans(item, "itemRoot")

    local InstanceID = root:GetInstanceID()

    local uiCommonList = self._uiCommonList
    if not uiCommonList then
        uiCommonList = {}
    end

    local baseClass = uiCommonList[InstanceID]
    if not baseClass then
        baseClass = CommonIcon:New()
        uiCommonList[InstanceID] = baseClass
        baseClass:Create(root)
    end

    baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
    self:SetWndClick(root, function()
        gModelGeneral:ShowCommonItemTipWnd(itemdata)
    end)
    baseClass:EnableShowNum(false)
    baseClass:DoApply()

    item.localScale = Vector3.one * 0.8
end

--region 初始化文本 -- 事件 -- 数据 --------------------------------------------------------------------------------
function UIFlandBoss:InitCommonText()

    --self:SetWndText(self.mRankTitle, ccClientText(43100))--[43100]	[個人排行榜]
    self:SetWndText(self.mSelfRankTitle, ccClientText(43101))--[43101]	[我的排名]
    --self:SetWndText(self.mRankTitle, ccClientText(43102))--[43102]	[未上榜]
    self:SetWndText(self.mSelfRecordTitle, ccClientText(43103))--[43103]	[我的記錄]
    self:SetWndText(self.mRewardTitle, ccClientText(43104))--[43104]	[排名獎勵]
    self:SetWndText(self.mRewardDetail, ccClientText(43105))--[43105]	[點擊查看詳情]

    self:SetWndText(self.mBossLeftTimeTitle, ccClientText(43106))--[43106]	[離開時間]
    self:SetWndText(self.mTaskBtnText, ccClientText(43107))--[43107]	[任 務]
    self:SetWndText(self.mStrategyBtnText, ccClientText(43108))    --[43108]	[攻 略]
    self:SetWndText(self.mBossRewardTitle, ccClientText(43109))--[43109]	[獎勵預覽]
    self:SetWndText(self.mFightBtnText, ccClientText(43110))    --[43110]	[挑 戰]

    self:SetTextTile(self.mReturnBtn, ccClientText(30205))-- 返回

    -- 42004
    self:SetWndText(self.mActivityLeftTimeTitle, ccClientText(43120))-- 倒計時
    self:SetWndText(self.mTxtTips1, ccClientText(43100))--[43100]	[個人排行榜]
    --self:SetWndText(self.mRewardDetail, ccClientText(42004))--[42004]	[查看更多]
end

function UIFlandBoss:OnActivityResp(pb, ret)
    if self._sid ~= pb.sid then
        return
    end

    self:RefreshUI()
end
--构建奖励
function UIFlandBoss:SetBossHurtRewardInfo()
    local schedule
    if self._schedule then
        schedule = self._schedule[self._curBossIndex].schedule
    end

    local offset = self._curBossIndex - 1
    if schedule == nil or schedule == 0 then
        --设置奖励
        if self._accumulateHurtInfo then
            local hurtRewardInfos = self._accumulateHurtInfo[self._curBossIndex]
            local hurtRewardInfo = hurtRewardInfos[1].entryCfg
            local uiList = self:InitRewardListNoGet(LxDataHelper.ParseItem(hurtRewardInfo.reward), self.mBossRewardrList, "UIFlandBoss_HurtRewardList")

            uiList:EnableScroll(true,true)
        end
        return
    end

    local hurtRewardInfos = self._accumulateHurtInfo[self._curBossIndex]

    if schedule > #hurtRewardInfos then
        schedule = schedule - offset * (#hurtRewardInfos)
    end

    local hurtRewardInfo = hurtRewardInfos[schedule].entryCfg

    if hurtRewardInfo then
        --设置图标
        self:SetWndEasyImage(self.mBossRewardIcon, hurtRewardInfo.icon)
        self:SetWndText(self.mBossRewardStage, hurtRewardInfo.name)
        --设置奖励
        local uiList = self:InitRewardList(LxDataHelper.ParseItem(hurtRewardInfo.reward), self.mBossRewardrList, "UIFlandBoss_HurtRewardList")

        uiList:EnableScroll(true,true)
    end
end

--帮助文档
function UIFlandBoss:OnClickHelp()
    GF.OpenWnd("UIBzTips", { title = ccClientText(18751), para = { }, text = self._cfgDataMoreInfo.helpTips })
end

function UIFlandBoss:ClearAllTimer()
    if self._loopTimer then
        for key, timer in pairs(self._loopTimer) do
            LxTimer.DelayTimeStop(timer)
        end

        self._loopTimer = {}
    end
end

--判断当天是否可以调整
function UIFlandBoss:CheckCurDayIsOver()
    if self._bossInfo[self._curBossIndex].canCombat == 1 then
        return false
    else
        return true
    end
end
--endregion --------------------------------------------------------------------------------------

--region 界面红点 和第一个页签--------------------------------------------------------------------------------
function UIFlandBoss:CheckRedPointShow()
    CS.ShowObject(self.mTaskRedPoint, self:CheckTaskRedPointShow())
end


--endregion --------------------------------------------------------------------------------------

--region 界面方法 --------------------------------------------------------------------------------

function UIFlandBoss:RefreshUI()
    --刷新页面

end

--攻略
function UIFlandBoss:OnClickLookStrategy()
    local bossData = self._bossInfo[self._curBossIndex]
    if not bossData then
        printInfoNR("self._activityPageDataBoss[self._subPage] is a nil, self._subPage = " .. (self._subPage or "nil"))
        return
    end

    local sid, method, skill = self._sid, bossData.entryCfg.method, bossData.entryCfg.skill
    GF.OpenWnd("UIFlandBossStrategy", { sid = sid, desc = method, skill = skill })
end

function UIFlandBoss:ListBossInfoItem(list, item, itemdata, itempos)
    if not itemdata then
        return
    end

    local common = self:FindWndTrans(item, "common")
    local over = self:FindWndTrans(item, "over")
    local cur = self:FindWndTrans(item, "cur")
    local future = self:FindWndTrans(item, "future")

    local icon = self:FindWndTrans(common, "icon")
    self:SetWndEasyImage(icon, itemdata.entryCfg.tabIcon)

    --设置状态
    local desStr, isend, iscur, isfuture = self:GetTabTimeDes(itempos)
    CS.ShowObject(over, isend)
    CS.ShowObject(cur, iscur)
    CS.ShowObject(future, isfuture)
    local textTran
    if isend then
        textTran = self:FindWndTrans(over, "UIText")
    elseif iscur then
        textTran = self:FindWndTrans(cur, "UIText")
    elseif isfuture then
        textTran = self:FindWndTrans(future, "UIText")
    end
    self:SetWndText(textTran, desStr)

    self:SetWndClick(icon, function()
        self:OnTabClick(itempos)
    end)

    if isend and itempos==#self._bossInfo then
        --self._curBossIndex=itempos

        self._curBossIndex = itempos

        self:RefreshBossInfoUI()
        self:SetSelfRankReward()
        self:SetBossHurtRewardInfo()
        self:CheckRedPointShow()
    end
    self:CheckOpenTab()
end

function UIFlandBoss:SetSelfRankReward()

    local items = self:GetSelRankReward()

    if not items then
        return
    end

    for _, tran in ipairs(self._rankReward) do
        CS.ShowObject(tran, false)
    end

    for k, v in ipairs(items) do
        --local root = k == 1 and self.mReward_1 or self.mReward_2

        local root = self._rankReward[k]

        if not root then
            printInfoNR2("仙境迷踪--RANK奖励配置", "超过四个")
            return
        end

        CS.ShowObject(root, true)

        local uiCommonList = self._uiCommonList
        if not uiCommonList then
            uiCommonList = {}
        end

        local InstanceID = root:GetInstanceID()
        local baseClass = uiCommonList[InstanceID]
        if not baseClass then
            baseClass = CommonIcon:New()
            uiCommonList[InstanceID] = baseClass
            baseClass:Create(root)
        end

        baseClass:SetCommonReward(v.itemType, v.itemId, v.itemNum)
        self:SetWndClick(root, function()
            gModelGeneral:ShowCommonItemTipWnd(v)
        end)
        baseClass:DoApply()
    end


end

function UIFlandBoss:ListItem(list, item, itemdata, itempos)
    if not itemdata then
        return
    end

    --缓存起来做选中效果
    if not self._bossTabItem then
        self._bossTabItem = {}
    end
    self._bossTabItem[itempos] = item

    --背景
    local icon = self:FindWndTrans(item, "Icon")
    local sel = self:FindWndTrans(item, "Sel")
    local redPoint = self:FindWndTrans(item, "redPoint")

    local TimeDes = self:FindWndTrans(item, "TimeDes")

    --设置背景
    self:SetWndEasyImage(icon, itemdata.entryCfg.tabIcon)

    self:SetWndClick(icon, function()
        self:OnTabClick(itempos)
    end)

    local desStr = self:GetTabTimeDes(itempos)
    CS.ShowObject(sel, itempos == self._curBossIndex)

    self:SetWndText(TimeDes, desStr)
    self:CheckOpenTab()
end

function UIFlandBoss:InitEvent()
    self:SetWndClick(self.mReturnBtn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)

    self:SetWndClick(self.mStrategyBtn, function(...)
        self:OnClickLookStrategy()
    end)

    self:SetWndClick(self.mHelpBtn, function()
        self:OnClickHelp()
    end)

    self:SetWndClick(self.mRewardDetail, function()
        self:OnClickLookRank()
    end)

    self:SetWndClick(self.mTaskBtn, function(...)
        self:OnClickLookTask()
    end)

    self:SetWndClick(self.mFightBtn, function(...)
        self:OnClickFight()
    end)

    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
        self:OnActivityConfigData(...)
    end)

    self:WndNetMsgRecv(LProtoIds.ActivityResp, function(pb)
        self:OnActivityResp(pb)
    end)

    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
        self:OnActivityPageResp(pb)
    end)

    self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
        gModelActivity:OnActivityPageReq(self._sid)
    end)

    self:WndEventRecv(EventNames.RANK_UPDATE_END, function(...)
        self:RefreshRank()
    end)
end

function UIFlandBoss:InitTableData()
    self._rankReward = {
        [1] = self.mReward_1,
        [2] = self.mReward_2,
        [3] = self.mReward_3,
        [4] = self.mReward_4,
    }
end

function UIFlandBoss:GetSelRankReward()
    local curPlayerInfo = self._bossInfo[self._curBossIndex]
    local rankIndex = curPlayerInfo.moreInfo.rankPlayer

    local rankReward = nil

    if self._selfRankInfo then
        rankReward = self._selfRankInfo[self._curBossIndex]
    else
        return nil
    end

    for k, v in ipairs(rankReward) do
        if (rankIndex == -1 and (v.condition1 == -1 or v.condition2 == -1)) --未上榜
                or (rankIndex >= v.condition1 and rankIndex <= v.condition2) or (rankIndex >= v.condition1 and v.condition2 == -1) then
            --在该区间内
            return LxDataHelper.ParseItem(v.items)
        end
    end
end

--获取时间的描述
function UIFlandBoss:GetTabTimeDes(index)
    local curBossInfo = self._bossInfo[index]
    local desInfo = ""
    local iscur = false
    local isend = false
    local isfuture = false
    if curBossInfo then
        local starDay = curBossInfo.openData.starDay
        local endDay = curBossInfo.openData.endDay
        local isEnd = curBossInfo.openData.isEnd
        local isOpen = curBossInfo.openData.isOpen

        if isEnd then
            --结束状态
            desInfo = ccClientText(18752)
            isend = true
        else
            local addDay

            local curTime = GetTimestamp()

            if isOpen then
                addDay = endDay

                if addDay >= 1 then
                    addDay = addDay - 1
                end

                local addTime = addDay * 86400 + self._rankClearTime * 3600

                local endTime = self._startTime + addTime
                if self._endTime > 0 then
                    endTime = math.min(endTime, self._endTime)
                end

                --开计时器进行显示

                local lastTime = endTime - curTime

                if lastTime <= 0 then
                    desInfo = ccClientText(18755)
                else
                    desInfo = ccClientText(18749)
                end

                iscur = true
            else
                --计算年月日
                addDay = starDay
                local addTime = addDay * 86400
                local times = self._startTime + addTime

                local _data = LUtil.OSDate("*t", times)
                local m_1 = _data.month
                local d_1 = _data.day

                addDay = endDay
                addTime = addDay * 86400
                local endtimes = self._startTime + addTime
                local _endData = LUtil.OSDate("*t", endtimes)
                local m_2 = _endData.month
                local d_2 = _endData.day

                desInfo = m_1 .. "." .. d_1 .. "~" .. m_2 .. "." .. d_2
                isfuture = true
            end
        end

        return desInfo, isend, iscur, isfuture
    end
end

--仙境迷踪_个人手动奖励领取的信息
function UIFlandBoss:RefreshBossRewardInfo(page)
    if page then
        local moreInfo
        local bossRefId
        local pageData = {}
        for p, q in ipairs(page.entry) do

            local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, q.pageId, q.entryId)
            if not entryCfg then
                return
            end

            moreInfo = JSON.decode(q.moreInfo)
            bossRefId = entryCfg.moreInfo
            if not pageData[bossRefId] then
                pageData[bossRefId] = {}
            end

            local condition = string.split(entryCfg.condition, ',')
            local data = {
                entryId = q.entryId, --序号
                pageId = q.pageId, --条目id
                status = q.goalData.status, --完成状态
                goal = tonumber(condition[2]), --目标值
                sort = entryCfg.sort, --排序
                bossRefId = bossRefId,
            }

            table.insert(pageData[bossRefId], data)
        end
        self._activityPageDataStrategy = pageData
    end

    --刷新一次任务信息
    self:CheckRedPointShow()
end

function UIFlandBoss:RefreshBossInfoUI()
    self:CreateBossLiHui()
    self:SetMyInfo()
    self:SetLeftTime()
end

function UIFlandBoss:GetBossStrategyDataWhenFight(bossRefId)
    local data = {}
    if not self._activityPageDataStrategy then
        return
    end

    for k, v in ipairs(self._activityPageDataStrategy[bossRefId]) do
        if v.status == 0 then
            --未完成
            table.insert(data, v)
        end
    end

    table.sort(data, function(a, b)
        return a.sort < b.sort
    end)

    return data
end

--仙境迷踪_个人排行
function UIFlandBoss:RefreshSelfRankInfo(page)
    if page then
        --构建信息 创建列表
        self._selfRankInfo = {}

        for p, q in ipairs(page.entry) do
            local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, q.pageId, q.entryId)
            if not entryCfg then
                return
            end

            local refId = tonumber(entryCfg.moreInfo)  --属于前面的第几个boss
            if not self._selfRankInfo[refId] then
                self._selfRankInfo[refId] = {}
            end
            local conditionData = string.split(entryCfg.condition, ',')
            local data = {
                entryId = q.entryId,
                title = entryCfg.name, -- 名称
                desc = entryCfg.description, --描述
                items = entryCfg.reward, --道具
                method = entryCfg.method, --攻略文本
                moreInfo = refId, --对应挑战配置表id
                condition1 = tonumber(conditionData[2]), --排行条件，拿到该奖励的最高名次
                condition2 = tonumber(conditionData[3]), --排行条件，拿到该奖励的最低名次
            }

            table.insert(self._selfRankInfo[refId], data)

        end
    end


    --个人排行的数据初始化完 刷新数据
    self:SetSelfRankReward()
end
--endregion --------------------------------------------------------------------------------------

--region 回调方法和计时器 --------------------------------------------------------------------------------
function UIFlandBoss:OnActivityConfigData(data, sid)
    if sid ~= self._sid then
        return
    end

    self:InitData()
    gModelActivity:OnActivityPageReq(self._sid)
end

function UIFlandBoss:InitPara()
    self._sid = self:GetWndArg("sid")

    if not self._sid then
        local activiteData =gModelActivity:GetActivityDataByModelId(ModelActivity.ACTIVITY_FAIRYLAND)
        if activiteData and activiteData[1] then
            self._sid=activiteData[1].sid
        else
            self:WndClose()
            printInfoNR2("UIFlandBoss","activiteData is nil")
        end

    end

    self._curBossIndex = self:GetWndArg("bossIndex") or 1

    gModelActivity:ReqActivityConfigData(self._sid)

end

function UIFlandBoss:OnClickFight()
   if  self:CheckCurDayIsOver() then
       GF.ShowMessage(ccClientText(43119))
       return
   end

    --挑战
    local bossData = self._bossInfo[self._curBossIndex]
    if not bossData then
        printInfoNR("self._activityPageDataBoss[self._subPage] is a nil, self._subPage = " .. (self._curBossIndex or "nil"))
        return
    end

    if bossData.openData.isEnd then
        GF.ShowMessage(ccClientText(18753))
        return
    end

    if self._curBossRealEnd then
        GF.ShowMessage(ccClientText(18753))
        return
    end

    --构建boss的数据
    local mapRefId, monster, method, skill = tonumber(bossData.entryCfg.map), bossData.entryCfg.monster, bossData.entryCfg.method, bossData.entryCfg.skill
    local sid, pageId, entryId = self._sid, bossData.pageId, bossData.entryId
    gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_FAIRYLAND_BOSS, {
        mapRefId = mapRefId,
        bossMonsterId = monster,
        --method = method,
        skill = skill,
        sid = sid,
        pageId = pageId,
        entryId = entryId,
        bossRefId = entryId,
        rewardBoxData = self:GetBossStrategyDataWhenFight(entryId)
    })

    self:WndClose()
end

--判断是否在自己的战斗中
function UIFlandBoss:CheckIsInFairylandBossBattle()

    if gLFightManager:IsCombatTypeInFight(LCombatTypeConst.COMBAT_FAIRYLAND_BOSS) then
        gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_FAIRYLAND_BOSS, {})
        self:WndClose()
        return true
    end

end
--endregion --------------------------------------------------------------------------------------
------------------------------------------------------------------
return UIFlandBoss