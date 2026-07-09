---
--- Created by Administrator.
--- DateTime: 2024/4/7 14:46:34
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIModelAct151:LWnd
local UIModelAct151 = LxWndClass("UIModelAct151", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIModelAct151:UIModelAct151()

    self._getTimes = 0 --抽取次数

    self._activity = nil -- 当前活动的服务器数据

    self._webData = nil  -- 配置表的数据

    self._rewardPool = nil  -- 奖槽池的数据
    self._rewardPoolCanGetTimes = nil  --奖槽池的数据 剩余可抽取的次数 -- 0的时候 显示 遮罩 和 √
    self._rewardPoolCanPlayGetEffect = nil --奖槽池 获取奖励的时候 能够播放的index
    self._rewardPoolIsOptional = nil   --奖槽池 是否为自选池
    self._rewardPoolOptional = nil  -- 奖槽池 自选情况 -1 无自选 0 有自选但无选择   >0 选择道具的index
    self._needLoopRewards = nil  -- 需要轮播奖励的奖励槽的信息 

    self._moreInfos = nil  --  奖槽池的MoreInfos 数据的解析

    self._rewards = nil   -- 奖励表的归类  key 为表中的moreInfo字段
    self._rewardsById = nil  -- 奖励表的归类  key 为id 
    self._rewardItems = nil -- 奖励item展示的gameobject的引用

    self._guaRewardItemData = nil -- 保底道具的信息

    self._WndTimerKey = "UIModelAct151_Timer"   -- 计时器key

    self._wndConfirmEventString = string.format(EventNames.WNDOPTIONITEM_CONFIRM, "UIModelAct151")

    self._wndAnimTimerKey = "WndAnimTimerKey" --获取奖励时候的动画计时器
    self._isPlayingAnim = false  -- 是否正在播放动画
    self._playTimes = 0  -- 每替换一次 都算一次
    self._curPlayIndex = 0 -- 当前播放的是第几个动画
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIModelAct151:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIModelAct151:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIModelAct151:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._firstInit = true
    --第一次设置Pool的状态
    self._firstInitPool = true
    self.jpj = gLGameLanguage:IsJapanVersion()
    self:InitText()
    self:InitCommon()

    self:InitEvent()
    self:InitMsg()

    self:InitPara()

    self:RefreshView()
end

function UIModelAct151:RefreshView()
    self:SetLeftTime()
end

function UIModelAct151:RefreshAfterGetWebConfig()
    self:ParseWebDataChunkOne()
    self:ParseWebDataChunkTwo()
    self:ParseWebDataCostItem()

    self:InitRewardData()

    self:SetCostItem()

    self:SetImgTxtAndOffset()

    self:SetHelpTxt()

    CS.ShowObject(self.mBubbleTips, not string.isempty(self._webData.config.frameText))
    self:SetWndText(self.mBubbleText, self._webData.config.frameText)

    --设置按钮的状态和文本的状态
    self:SetCostButtonAndTextState()
end

--设置坐标和偏移那些
function UIModelAct151:SetImgTxtAndOffset()
    --底图
    self:SetWndEasyImage(self.mActivity151_Bg, self._webData.config.callBg)

    --标题文本 内容和偏移
    self:SetWndEasyImage(self.mTitle, self._webData.config.headline)
    if self._webData.config.headlinePos then
        self:SetTransPos(self.mTitle, self._webData.config.headlinePos)
    end

    --底部的保底的文本提示
    self:SetWndEasyImage(self.mDes, self._webData.config.guaTxt)
    if self._webData.config.guaRewardTxtPos then
        self:SetTransPos(self.mDes, self._webData.config.guaRewardTxtPos)
    end

    --道具的部分
    if self._webData.config.guaRewardPos then
        self:SetTransPos(self.mGuaRewardItem, self._webData.config.guaRewardPos)
    end




    --英雄立绘 --判断下 是否为立绘  如果是spine 还有其他的操作
    local heroLihui = string.split(self._webData.config.ImageHero, '=')

    if tonumber(heroLihui[1]) == 1 then


        self:SetWndEasyImage(self.mHeroImg, heroLihui[2])
    elseif tonumber(heroLihui[1]) == 2 then
        --创建spine动画这里 后面在加逻辑
        local dp = self:CreateWndSpine(self.mHeroSpine, heroLihui[2], heroLihui[2], false, function()
        end)

    end

    CS.ShowObject(self.mHeroImg, tonumber(heroLihui[1]) == 1)
    CS.ShowObject(self.mHeroSpine, tonumber(heroLihui[1]) == 2)

    --位置
    if self._webData.config.ImageHeroPos then
        self:SetTransPos(self.mHeroInfo, self._webData.config.ImageHeroPos)
    end
    --翻转
    if self._webData.config.privilegeHeroTurn then
        local x = self._webData.config.privilegeHeroTurn == 1 and -1 or 1

        local scale = Vector3(x, 1, 1)

        self.mHeroInfo.localScale = scale
    end


    --设置按钮的文字
    --self:SetWndText(self.mRewardTxt, ccClientText(41101))

    if self._webData.config.callBtnPos then
        self:SetTransPos(self.mGetReward, self._webData.config.callBtnPos)
    end

    --设置剩余时间
    if self._webData.config.timePos then
        self:SetTransPos(self.mLeftTimeBg, self._webData.config.timePos)
    end

    --設置首次免費
end

--判断是否进行显示
function UIModelAct151:CheckIsShowShift(index)
    local isShow = true
    --检查是否为池子
    isShow = self._rewardPoolIsOptional[index]

    if not isShow then
        return isShow
    end

    --检查是否选过了
    local selectId = self._rewardPoolOptional[index]

    isShow = selectId > 0

    if not isShow then
        return isShow
    end

    --检查池子是否抽过了
    isShow = self._getTimes == 0

    return isShow
end

function UIModelAct151:LoopReward()
    if not self._needLoopRewards or #self._needLoopRewards == 0 then
        return
    end

    for k, v in ipairs(self._needLoopRewards) do
        --判断是否 被选择过了 选择过的 不参与轮换
        if not self:CheckRewardPoolIsSelectReward(v.id) or not self._rewardPoolIsOptional[v.id] then

            v.curIndex = v.curIndex + 1

            if v.curIndex > v.maxIndex then
                v.curIndex = 1
            end

            local itemData = self:CheckIsInSelectReward(v.id) and nil or LUtil.GetRefItemFourData(v.rewards[v.curIndex].reward)

            --这里判断是否是自选池 是的话 屏蔽掉生成
            v.baseClass:SetCommonReward(itemData.type, itemData.refId, itemData.count)
            v.baseClass:DoApply()

        end
    end
end

function UIModelAct151:InitCommon()
    self._rewardItems = {}

    for i = 1, 10 do
        local rewardItem = self:CreateRewardItem()
        CS.ShowObject(rewardItem, true)
        self._rewardItems[i] = rewardItem
    end

    if not self:IsTimerExist(self._WndTimerKey) then
        self:TimerStart(self._WndTimerKey, 1, false, -1)
    end
end

function UIModelAct151:InitMsg()
    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
        self:OnActivityConfigData(...)
    end)

    self:WndEventRecv(self._wndConfirmEventString, function(...)
        self:OnConfirmOption(...)
    end)

    self:WndNetMsgRecv(LProtoIds.ActivityResp, function(pb)
        local activity = pb.activity
        if activity.sid == self._sid then
            self._activity = gModelActivity:GetActivityBySid(self._sid)
            self:RefreshAfterGetActivityData()

        end
    end)

    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
        self:OnSetPageData(pb)

        if self._isSelectOption then
            self._activity = gModelActivity:GetActivityBySid(self._sid)

        end
    end)

    self:WndNetMsgRecv(LProtoIds.ActivityListResp, function(pb)
        self._activity = gModelActivity:GetActivityBySid(self._sid)
        local activities = pb.activities

        for i, v in ipairs(activities) do
            local sid = v.sid
            if sid == self._sid then


                if self._isSelectOption then
                    self._isPlayingAnim = false
                    self._isSelectOption = false

                    self._activity = gModelActivity:GetActivityBySid(self._sid)

                    self:SetRewardPoolGetStatus()
                    self:SetRewardPoolOptionStatus()
                    self:SetCostItem()
                    self:SetGuaranteeInfo()
                    self:SetCostButtonAndTextState()
                    self:SetShiftStatus()
                else
                    self._isPlayingAnim = true
                    CS.ShowObject(self.mSkipImg, true)
                    self._activity = gModelActivity:GetActivityBySid(self._sid)

                    self:RefreshAfterGetActivityData()
                    self:CreateAniEffectInfo_1()
                end


            end
        end
    end)


    --拿到奖励之后，进行特效部分
    self:WndEventRecv(EventNames.WNDOPTIONITEM_GETREWARD_PLAY_ANI, function(rewardList)
        self:OnGetDetailMsg(rewardList)
    end)
end

--设置消耗道具
function UIModelAct151:SetCostItem()
    if not self._costItem then
        return
    end

    local cosItemIndex = self._getTimes + 1 > #self._costItem and #self._costItem or self._getTimes + 1

    local costItemData = self._costItem[cosItemIndex]
    local itemIconPath = gModelItem:GetItemImgByRefId(costItemData.itemRefId)
    local itemCount = costItemData.itemCount
    local haveCount = gModelItem:GetNumByRefId(costItemData.itemRefId)
    self:SetWndEasyImage(self.mIcon_Need, itemIconPath)
    self:SetWndEasyImage(self.mIcon_Have, itemIconPath)
    self:SetWndText(self.mNum_Need, itemCount)

    self:SetWndText(self.mNum_Have, LUtil.NumberCoversion(haveCount))

    --判断是否为0

    self:SetCostButtonAndTextState()
end

function UIModelAct151:SetRewardPoolGetStatus()
    for k, v in ipairs(self._rewardPoolCanGetTimes) do
        if self._rewardItems[k] then
            local mask = CS.FindTrans(self._rewardItems[k], "RewardMask")
            CS.ShowObject(mask, v == 0)
        end
    end
end

function UIModelAct151:OnConfirmOption(index)

    self._isSelectOption = true
    if index and index > 0 then
        if self._poolIndex > 0 then
            local moreInfo = self._moreInfos[self._poolIndex]
            if moreInfo then
                local rewards = self._rewards[tonumber(moreInfo[2])]
                local reward = rewards[index]

                if reward then
                    --构建上报的信息
                    local args = string.format("1|%s", reward.id)
                    gModelActivity:OnActivitySpecialOpReq(self._sid, self._webData.chunk[1].id, self._poolIndex, nil, args, ModelActivity.ACTIVITY_LOTTERY_151)
                end
            end
        end
    end


end

function UIModelAct151:SetPlayRewardStatus()
    self:SetPlayRewardShowOrHideStatus(self._curPlayIndex, false)

    self._curPlayIndex = self._curPlayIndex + 1

    if self._curPlayIndex > #self._playEffectList then
        self._curPlayIndex = 1
    end
    self._playTimes = self._playTimes + 1
    self:SetPlayRewardShowOrHideStatus(self._curPlayIndex, true)

    if self._playTimes >= 2 * #self._playEffectList + self._stopEffectPool then
        if self._curPlayIndex == self._stopEffectPool then

            self:TimerStop(self._wndAnimTimerKey)
            self._isPlayingAnim = false
            CS.ShowObject(self.mSkipImg, false)

            self:SetPlayRewardShowOrHideStatus(self._stopEffectPool, true, true)

            --获取奖励
            gModelWndPop:TryOpenPopWnd("UIAward", self._curGetRewardList)
        end
    end
end

function UIModelAct151:CheckRewardPoolIsAllSelectReward_Click()

    if not self._selectRewards or #self._selectRewards == 0 then
        return true
    end

    for k, v in ipairs(self._selectRewards) do
        if not self:CheckRewardPoolIsSelectReward(v) then
            return self:CheckRewardPoolIsSelectReward(v)
        end
    end

    return true
end

function UIModelAct151:SetShiftStatus()
    for k, v in ipairs(self._shiftTrans) do

        local isShow = self:CheckIsShowShift(k)

        CS.ShowObject(v, isShow)
    end
end

function UIModelAct151:SetPlayRewardShowOrHideStatus(index, isShow, isOver)
    local getEffect
    local k

    if self._playEffectList then
        k = self._playEffectList[index]
    end

    if k then
        if self._rewardItems[k] then
            getEffect = CS.FindTrans(self._rewardItems[k], "GetEffect")
            CS.ShowObject(getEffect, isShow)
        end
    end

    if isOver then
        self._isOver = true
        gModelActivity:OnActivityPageReq(self._sid)
    end
end

function UIModelAct151:SetCostButtonAndTextState()
    local txt = self._webData.config.callBtnTxt
    if self:CheckRewardPoolIsAllSelectReward_Click() then
        self:SetWndImageGray(self.mGetReward, false)
        local redpoint = CS.FindTrans(self.mGetReward, "redPoint")

        if self:CheckIsEnoughtCostItem() then
            if self:CheckIsCanGet() then
                CS.ShowObject(redpoint, true)
            else
                CS.ShowObject(redpoint, false)
            end

            -- color = "#2D3550"
        else
            CS.ShowObject(redpoint, false)

            -- color = "#FF0000"
        end

        self:SetWndEasyImage(self.mGetReward, "activity_luckymagic_btn_1")
    else

        self:SetWndEasyImage(self.mGetReward, "activity_luckymagic_btn_1_off")
        txt = string.format("<color=#ffffff>%s</color>", txt)
    end

    self:SetWndText(self.mRewardTxt, txt)
end

function UIModelAct151:OnGetClick()
    if self._isPlayingAnim then
        return
    end

    if not self:CheckRewardPoolIsAllSelectReward_Click() then
        GF.ShowMessage(ccClientText(41103))
        return
    end

    if not self:CheckIsEnoughtCostItem(true) then

        return
    end

    --self._isReqReward = false
    --self:PlayGetEffect()
    self._isOver = false
    --构建上报的信息
    --直接领取
    local args = "2|1"
    gModelActivity:OnActivitySpecialOpReq(self._sid, nil, nil, nil, args, ModelActivity.ACTIVITY_LOTTERY_151)


end

function UIModelAct151:InitPara()
    local sid = self:GetWndArg("sid")
    local subpage = self:GetWndArg("subPage") --支持跳转
    if subpage then
        sid = gModelActivity:GetSidByUniqueJump(subpage)
    end
    self._sid = sid
    local modelId = gModelActivity:GetActivityModeIdBySid(sid)
    self._modelId = modelId

    local webData = gModelActivity:GetWebActivityDataById(sid)

    self:RefreshAfterGetActivityData()

    if not webData then
        gModelActivity:ReqActivityConfigData(sid)
        return
    end

    self._webData = webData

    self:RefreshAfterGetWebConfig()

    local pbData = gModelActivity:GetActivityPageBySid(sid)
    if pbData then

    else
        gModelActivity:OnActivityPageReq(sid)
    end


end

--设置剩余时间
function UIModelAct151:SetLeftTime()
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

function UIModelAct151:SetTransPos(tran, posString)
    local pos = string.split(posString, '|')

    if pos[1] and pos[2] then
        tran.localPosition = Vector2(tran.localPosition.x + tonumber(pos[1]), tran.localPosition.y + tonumber(pos[2]))
    end
end

function UIModelAct151:OnGetDetailMsg(rewardList)
    self._curGetRewardList = rewardList
end

--设置保底的道具
function UIModelAct151:SetGuaRewardItem()
    --not self._guaRewardItemData 设置背景的底图
    local itemData = LUtil.GetRefItemFourData(self._guaRewardItemData)

    local iconRootTrans = CS.FindTrans(self.mGuaRewardItem, "itemRoot")
    local baseClass = self._guaRewardBaseClass
    if not baseClass then
        baseClass = CommonIcon:New()
        self._guaRewardBaseClass = baseClass
        baseClass:Create(CS.FindTrans(iconRootTrans, "Icon"))
    end

    baseClass:SetCommonReward(itemData.type, itemData.refId, itemData.count)
    baseClass:DoApply()

end

--生成奖励预制  要维持好预制的引用
function UIModelAct151:CreateRewardItem()
    local rewardItem = LxResUtil.NewObject(self.mRewardItem)
    CS.SetParentTrans(rewardItem, self.mRewardPool)

    return rewardItem
end

function UIModelAct151:SetRewardPool()
    self._needLoopRewards = {}
    self._rewardPoolIsOptional = {}
    self._selectRewards = {}
    for k, v in ipairs(self._rewardPool) do
        local moreInfo = self._moreInfos[v.id]
        local rewards = self._rewards[tonumber(moreInfo[2])]

        self._rewardPoolIsOptional[v.id] = tonumber(moreInfo[1]) == 1


        --rewards[index].reward   初始化 从1 开始
        local itemData
        local isSelect = tonumber((self._moreInfos[v.id][1])) == 1

        if not isSelect then
            itemData = LUtil.GetRefItemFourData(rewards[1].reward)
        else
            itemData = {}
        end

        local iconRootTrans = CS.FindTrans(self._rewardItems[k], "itemRoot")
        local uicommonlist = self._uicommonList
        local baseClass = uicommonlist[k]
        if not baseClass then
            baseClass = CommonIcon:New()
            uicommonlist[k] = baseClass
            baseClass:Create(CS.FindTrans(iconRootTrans, "Icon"))
        end

        baseClass:SetCommonReward(itemData.type, itemData.refId, itemData.count)
        baseClass:DoApply()

        --拿对应的shift部分
        local shift = CS.FindTrans(self._rewardItems[k], "shift")

        --缓存一份状态设置完之后 在设置显隐
        self._shiftTrans = self._shiftTrans or {}
        self._shiftTrans[k] = shift

        --设置点击方法
        self:SetWndClick(self._rewardItems[k], function()
            self:OnRewardPoolItemClick(k, rewards)
        end)

        self:SetWndClick(shift, function()
            self:OnRewardPoolItemClick(k, rewards, true)
        end)

        --设置缩放
        local scale = tonumber(moreInfo[4])
        self._rewardItems[k].localScale = Vector2.New(scale, scale)

        --位置设置
        local pos = string.split(moreInfo[5], ",")
        self._rewardItems[k].localPosition = Vector2.New(tonumber(pos[1]), tonumber(pos[2]))

        if #rewards > 1 and not isSelect then
            --该pool 为需要轮播
            local needLoopData = {}
            needLoopData.id = v.id
            needLoopData.rewards = rewards
            needLoopData.maxIndex = #rewards
            needLoopData.baseClass = baseClass
            needLoopData.curIndex = 1
            needLoopData.isSelect = false
            table.insert(self._needLoopRewards, needLoopData)
        end

        if isSelect then
            table.insert(self._selectRewards, v.id)
        end
    end

end

function UIModelAct151:OnSetPageData(pb)
    local sid = pb.sid
    if self._sid ~= sid then
        return
    end

    --判断一次

    --分页数据[1]的处理  moreInfo 为每个槽位 剩余可抽取的数量  分页数据[2] 不需要处理
    self._rewardPoolCanGetTimes = {}
    self._rewardPoolOptional = {}
    self._rewardPoolCanPlayGetEffect = {}

    local templist = {}
    for k, v in ipairs(pb.pages) do
        local page = gModelActivity:GenerateActivePageDataFromPb(v)
        table.insert(templist, page)
    end

    if nil == templist or nil == templist[1] then
        --0点之后 活动结束 不下发数据
        return
    end

    for k, v in ipairs(templist[1].entry) do
        local info = JSON.decode(v.moreInfo)

        self._rewardPoolCanGetTimes[k] = info.quantitative
        self._rewardPoolOptional[k] = info.optional

        if info.quantitative > 0 then
            table.insert(self._rewardPoolCanPlayGetEffect, k)
        end
    end

    self:SetRewardPoolOptionStatus()
    self:SetShiftStatus()
    self:SetCostButtonAndTextState()

    --第一次或者奖励播放完之后
    if self._firstInitPool or self._isOver then
        self._firstInitPool = false
        --那完了获取信息 应该进行mask的部分 设置
        self:SetRewardPoolGetStatus()
        self:SetRewardPoolOptionStatus()
        self:SetCostItem()
        self:SetGuaranteeInfo()
        self:SetCostButtonAndTextState()
        self:SetShiftStatus()
    end

    if self._isCreateAniEffect then
        self._isCreateAniEffect = false

        self:CreateAniEffectInfo_2()

    end
end

function UIModelAct151:InitText()
    self:SetWndText(self.mTxtClose, ccClientText(41102))
    if self.jpj then
        self:InitTextSizeWithLanguage(self.mLeftTime,-2)
    end

end

function UIModelAct151:SetRewardPoolOptional()

end

--判断还有没有抽取次数
function UIModelAct151:CheckIsCanGet()
    if not self._rewardPoolCanGetTimes then
        return false
    end

    for k, v in ipairs(self._rewardPoolCanGetTimes) do
        if v > 0 then
            return true
        end
    end
    return false
end

function UIModelAct151:CreateAniEffectInfo_2()
    local islast = false

    local playEffectList = {}
    self._stopEffectPool = 1
    --记录停止的pool的index
    for k, v in ipairs(self._rewardPoolCanPlayGetEffect) do
        if self._lotteryEntry < v then

            self._stopEffectPool = k
            break
        end
        if k == #self._rewardPoolCanPlayGetEffect then

            if self._lotteryEntry > v then
                islast = true
                self._stopEffectPool = k
            end
        end
    end
    --构建可播放的信息
    for tempkey, tempvalue in ipairs(self._rewardPoolCanPlayGetEffect) do
        table.insert(playEffectList, tempvalue)
    end
    if islast then
        table.insert(playEffectList, self._lotteryEntry)
        self._stopEffectPool = #playEffectList
    else
        table.insert(playEffectList, self._stopEffectPool, self._lotteryEntry)
    end

    local rewardPoolCanGetTimes = {}
    for rewardKey, value in ipairs(self._rewardPoolCanGetTimes) do
        table.insert(rewardPoolCanGetTimes, value)
    end

    self._playEffectList = playEffectList
    self._rewardPoolCanGetTimesTemp = rewardPoolCanGetTimes

    self._isPlayingAnim = true
    CS.ShowObject(self.mSkipImg, true)
    self:PlayGetEffect()
end

function UIModelAct151:InitEvent()
    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)

    self:SetWndClick(self.mGetReward, function()
        self:OnGetClick()
    end, LSoundConst.CLICK_BUTTON_COMMON)

    self:SetWndClick(self.mTips, function()
        self:OnClickHelp()
    end, LSoundConst.CLICK_BUTTON_COMMON)

    self:SetWndClick(self.mGuaRewardItem, function(...)
        if self._guaRewardItemData then
            local itemData = LUtil.GetRefItemFourData(self._guaRewardItemData)
            gModelGeneral:ShowCommonItemTipWnd(itemData)
        end
    end)

    self:SetWndClick(self.mIcon_Need, function(...)
        local cosItemIndex = self._getTimes + 1 > #self._costItem and #self._costItem or self._getTimes + 1
        local itemData = { itemId = self._costItem[cosItemIndex].itemRefId, itemType = 1, count = 0 }
        gModelGeneral:ShowCommonItemTipWnd(itemData)
    end)

    self:SetWndClick(self.mCostItem_Have, function(...)
        local cosItemIndex = self._getTimes + 1 > #self._costItem and #self._costItem or self._getTimes + 1
        local itemData = { itemId = self._costItem[cosItemIndex].itemRefId, itemType = 1, count = 0 }
        gModelGeneral:ShowCommonItemTipWnd(itemData)
    end)

    self:SetWndClick(self.mSkipImg, function()
        self:StopAnim()
    end)

end

function UIModelAct151:StopAnim()
    self:TimerStop(self._wndAnimTimerKey)
    self._isPlayingAnim = false
    CS.ShowObject(self.mSkipImg, false)

    self:SetPlayRewardShowOrHideStatus(self._curPlayIndex, false)
    self:SetPlayRewardShowOrHideStatus(self._stopEffectPool, true, true)

    --获取奖励
    gModelWndPop:TryOpenPopWnd("UIAward", self._curGetRewardList)
end

--endregion --------------------------------------------------------------------------------------

--region 获取动画 --------------------------------------------------------------------------------
function UIModelAct151:CreateAniEffectInfo_1()
    --播放停止的index    然后映射过 对应的 index 一样
    local moreInfo = JSON.decode(self._activity.moreInfo)
    self._lotteryEntry = moreInfo.lotteryEntry

    --这里进行一次请求
    self._isCreateAniEffect = true

    gModelActivity:OnActivityPageReq(self._sid)
end

function UIModelAct151:InitRewardData()

    self._uicommonList = {}

    self:SetRewardPool()
end

function UIModelAct151:CheckIsInSelectReward(id)
    if not self._rewardPoolOptional then
        return false
    end

    return not (self._rewardPoolOptional[id] == -1)
end

--消耗道具的解析--抽第几次 的消耗判断
function UIModelAct151:ParseWebDataCostItem()
    self._costItem = {}

    if self._webData == nil then
        printInfoNR2("modelActivity151--SetCostItem", "后台配置没有")
        return
    end

    local costs = string.split(self._webData.config.costNum, '|')

    for k, v in ipairs(costs) do
        local tempItemData = string.split(v, '=')
        local itemData = {}

        itemData.itemRefId = tonumber(tempItemData[2])
        itemData.itemCount = tonumber(tempItemData[3])
        --k 为抽取的次数
        self._costItem[k] = itemData
    end


end

function UIModelAct151:OnRewardPoolItemClick(poolIndex, rewards, isShift)
    local isShowItemTips = false
    local loopIndex = 0
    local selectIndex = 0
    --是否为loop池子
    for k, v in ipairs(self._needLoopRewards) do
        if v.id == poolIndex then
            loopIndex = v.curIndex > v.maxIndex and 1 or v.curIndex
            isShowItemTips = true
            break
        end
    end

    if not self._rewardPoolIsOptional[poolIndex] then
        isShowItemTips = true
    end


    --是否选择过了
    if self:CheckRewardPoolIsSelectReward(poolIndex) then
        selectIndex = self._rewardPoolOptional[poolIndex]
        isShowItemTips = true
    end

    if isShowItemTips then
        local rewards = self._rewards[poolIndex]
        local index = 0

        local reward
        if loopIndex > 0 then
            index = loopIndex
            reward = rewards[index].reward
        elseif selectIndex > 0 then
            index = selectIndex
            --
            --这里循环去取
            for k, v in ipairs(rewards) do
                if index == v.id then
                    reward = v.reward
                    break
                else
                    reward = self._guaRewardItemData --这个是保底道具只有一个的  设置一个保底
                end
            end
        else
            index = 1
            reward = rewards[index].reward
        end
        --构建itemData
        if not isShift then
            local itemData = LUtil.GetRefItemFourData(reward)
            gModelGeneral:ShowCommonItemTipWnd(itemData)
            return

        end
    end

    local tempReward = {}

    for k, v in ipairs(rewards) do
        table.insert(tempReward, v.reward)
    end

    local para = {
        title = gModelActivity:GetLngNameById(self._webData.config.name),
        rewards = tempReward,
        confirmEventString = self._wndConfirmEventString,
    }
    --这里记录下 打开弹窗的是哪个槽位
    self._poolIndex = poolIndex

    GF.OpenWnd("UIOptem", { para = para })
end

function UIModelAct151:OnClickHelp()
    local _wishCallHelpTxt = self._wishCallHelpTxt
    if _wishCallHelpTxt then
        _wishCallHelpTxt = string.gsub(_wishCallHelpTxt, "\\n", "\n")
        GF.OpenWnd("UIBzTips", { title = gModelActivity:GetLngNameById(self._webData.config.name), text = _wishCallHelpTxt })
    end
end

--奖池表 根据  moreInfo  的信息 进行归类
function UIModelAct151:ParseWebDataChunkTwo()
    if self._webData == nil then
        printInfoNR2("modelActivity151--InitRewardData", "后台配置没有")
        return
    end

    self._rewards = {}
    self._rewardsById = {}
    for k, v in ipairs(self._webData.chunk[2].entries) do
        local tempInfo = tonumber(v.moreInfo)
        if not self._rewards[tempInfo] then
            self._rewards[tempInfo] = {}
        end
        table.insert(self._rewards[tempInfo], v)
        self._rewardsById[v.id] = v
    end

    --设置保底奖励的信息
    self:SetGuaranteeInfo()
end

--  构建self._guaRewardItemData
function UIModelAct151:SetGuaranteeInfo()
    local reward
    if self._guarantee.isSelfSelect then
        --自选
        if self._rewardPoolOptional and self._rewardPoolOptional[self._guarantee.guaranteeId] > 0 then
            local poolEntryId = self._rewardPoolOptional[self._guarantee.guaranteeId]
            reward = self._rewardsById[poolEntryId].reward
        end
    else
        --非自选
        reward = self._rewards[self._guarantee.guaranteeId][1].reward
    end

    self._guaRewardItemData = reward
    self:SetGuaRewardItem()
end

--一进来也要调用一次 因为外部已经获取过了
function UIModelAct151:RefreshAfterGetActivityData()
    if not self._activity then
        --只有一个buynum
        self._activity = gModelActivity:GetActivityBySid(self._sid)
    end

    local moreInfo = JSON.decode(self._activity.moreInfo)

    self._getTimes = moreInfo.buyNum

    self:SetCostItem()

    self._endTime = self._activity.endTime

    if self._firstInit then
        self._firstInit = false
    end


end

function UIModelAct151:CheckRewardPoolIsAllSelectReward()
    --只有参与轮播的 才是有可能出现自选的情况 所以判断这个列表
    if not self._needLoopRewards and #self._needLoopRewards == 0 then
        return true
    end

    for k, v in ipairs(self._needLoopRewards) do
        if not self:CheckRewardPoolIsSelectReward(v.id) then
            return self:CheckRewardPoolIsSelectReward(v.id)
        end
    end

    return true
end

--endregion --------------------------------------------------------------------------------------

--region 计时器 --------------------------------------------------------------------------------
--开计时器
function UIModelAct151:OnTimer(key)
    if (self._WndTimerKey == key) then
        self:LoopReward()
        self:SetLeftTime()
    end

    if (self._wndAnimTimerKey == key) then
        self:SetPlayRewardStatus()
    end
end

function UIModelAct151:PlayGetEffect()

    self:HideAllEffect()

    self._curPlayIndex = 1
    self._playTimes = 1

    self:SetPlayRewardShowOrHideStatus(self._curPlayIndex, true)
    --开个定时器
    if not self:IsTimerExist(self._wndAnimTimerKey) then
        self:TimerStart(self._wndAnimTimerKey, 0.125, false, -1)
    else
        self:TimerStop(self._wndAnimTimerKey)
        self:TimerStart(self._wndAnimTimerKey, 0.125, false, -1)
    end
end
--抽奖前判断道具数量
function UIModelAct151:CheckIsEnoughtCostItem(isShowMesg)
    local cosItemIndex = self._getTimes + 1 > #self._costItem and #self._costItem or self._getTimes + 1

    local costItemData = self._costItem[cosItemIndex]

    local itemCount = costItemData.itemCount
    local haveCount = gModelItem:GetNumByRefId(costItemData.itemRefId)

    if haveCount < itemCount then
        if isShowMesg then
            GF.ShowMessage(string.replace(ccClientText(41104), gModelItem:GetNameByRefId(costItemData.itemRefId)))

        end
    end

    return haveCount >= itemCount
end

function UIModelAct151:SetRewardPoolOptionStatus()
    if not self._rewardPoolOptional then
        return
    end

    for k, v in ipairs(self._rewardPoolOptional) do
        if v > 0 then
            local tempReward = self._rewardsById[v].reward
            local itemData = LUtil.GetRefItemFourData(tempReward)

            local uicommonlist = self._uicommonList
            local baseClass = uicommonlist[k]

            baseClass:SetCommonReward(itemData.type, itemData.refId, itemData.count)
            baseClass:DoApply()
        end
    end
end

function UIModelAct151:SetHelpTxt()
    self._wishCallHelpTxt = self._webData.config.wishCallHelpTxt
end

function UIModelAct151:HideAllEffect()
    if self._rewardPoolCanPlayGetEffect then
        for k, v in ipairs(self._rewardItems) do
            local getEffect = CS.FindTrans(v, "GetEffect")
            CS.ShowObject(getEffect, false)

        end
    end
end

--endregion --------------------------------------------------------------------------------------

--region wndFunction --------------------------------------------------------------------------------
-- 奖槽表moreInfo解析  chunkone的数据进行归类
function UIModelAct151:ParseWebDataChunkOne()
    if self._webData == nil then
        printInfoNR2("modelActivity151--InitRewardData", "后台配置没有")
        return
    end

    self._moreInfos = {}
    self._rewardPool = {}

    for k, v in ipairs(self._webData.chunk[1].entries) do
        self._moreInfos[v.id] = string.split(v.moreInfo, '|')
        self._rewardPool[v.id] = v

        if v.isGuarantee == 1 then
            local data = {}
            data.guaranteeId = v.id
            data.isSelfSelect = tonumber(self._moreInfos[v.id][1]) == 1
            data.isCurSelect = 0

            self._guarantee = data
        end
    end
end


--endregion --------------------------------------------------------------------------------------

--region checkfunction --------------------------------------------------------------------------------
--抽奖前 判断有无自选池子   自选池子是否已经选择
function UIModelAct151:CheckRewardPoolIsSelectReward(id)
    --先判断是否为自选
    if self._rewardPoolIsOptional[id] then
        if not self._rewardPoolOptional then
            return true
        end

        if self._rewardPoolOptional[id] then
            return self._rewardPoolOptional[id] > 0
        else
            return false
        end
    else
        return self._rewardPoolIsOptional[id]
    end

    --以上情况都不是 默认return true
    return true
end

--region 事件回调处理 --------------------------------------------------------------------------------
function UIModelAct151:OnActivityConfigData(data, sid)
    if sid ~= self._sid then
        return
    end

    self._webData = data

    self:RefreshAfterGetWebConfig()
    gModelActivity:OnActivityPageReq(self._sid)
end

--endregion --------------------------------------------------------------------------------------
------------------------------------------------------------------
return UIModelAct151