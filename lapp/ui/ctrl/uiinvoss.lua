---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:58:41
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIInvoss:LWnd
local UIInvoss = LxWndClass("UIInvoss", LWnd)

UIInvoss.REWARD = 1
UIInvoss.STRATEGY = 2
local typeHorizontalLayoutGroup = typeof(UnityEngine.UI.HorizontalLayoutGroup)
local typeScrollRect = typeof(CS.ScrollRect)

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIInvoss:UIInvoss()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIInvoss:OnWndClose()
    self:ClearCommonIconList(self._commonIconList)
    if not self:WndCloseAndBack() then
        GF.OpenWndBottom("UIOutts")
    else
        GF.OpenWndBottom("UIOutts",{ childIndex = 1 })
        FireEvent(EventNames.ONLY_CHANGE_MAIN_BTN_ON, { index = LMainBtnIndexConst.OUTSKIRTS })
    end

    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIInvoss:OnCreate()
    LWnd.OnCreate(self)
    FireEvent(EventNames.ON_INVASION_OPEN)
    self._commonIconList = {}
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIInvoss:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    gModelInvasion:SetTipClicked()

    GF.CloseWndByName("UIOutts")

    self._isEnus = gLGameLanguage:IsForeignVersion()
    self._isVie = gLGameLanguage:IsVieVersion()

    if self._isEnus then
        self.mRank_Root.localPosition = self.mRank_Root.localPosition + Vector3.New(-34.5, 0, 0)
    end

    self:InitData()
    self:SetStaticContent()
    self:InitUIEvent()
    self:InitEvent()

    self:OnWndRefresh()
    --self:CheckIsSweep()
    self:SetUIState()
    self:RefreshForeign()
end

function UIInvoss:OnDrawCellItem(list, item, itemData, itemPos)
    local bossIcon = self:FindWndTrans(item, "common/icon")
    --over
    local overTrans = self:FindWndTrans(item, "over")
    local overTxt = self:FindWndTrans(overTrans, "UIText")
    --cur
    local curTrans = self:FindWndTrans(item, "cur")
    local curTxt = self:FindWndTrans(curTrans, "UIText")
    --future
    local futureTrans = self:FindWndTrans(item, "future")
    local futureTxt = self:FindWndTrans(futureTrans, "UIText")

    --设置boss的头像
    self:SetWndEasyImage(bossIcon, itemData.icon)


    --当前的轮次
    local curMapRefId = gModelInvasion:GetCurInvasionRefId()
    if not curMapRefId then
        return
    end
    local map = itemData

    CS.ShowObject(overTrans, curMapRefId > map.refId)

    CS.ShowObject(curTrans, curMapRefId == map.refId)

    CS.ShowObject(futureTrans, curMapRefId < map.refId)

    local isRest = false
    if curMapRefId == map.refId then
        if self:CheckIsOver() then
            CS.ShowObject(overTrans, true)
            CS.ShowObject(curTrans, false)
        else
            if gModelInvasion:IsCurCircleEnd() then
                --本轮结束
                CS.ShowObject(overTrans, true)
                CS.ShowObject(curTrans, false)

            elseif gModelInvasion:IsStopFightTime() then
                --休战中
                CS.ShowObject(curTrans, false)
                CS.ShowObject(futureTrans, true)

                isRest = true
            else
                CS.ShowObject(overTrans, false)
                CS.ShowObject(curTrans, true)
            end
        end
    end





    --设置文本
    local showStr = ccClientText(21073)
    self:SetWndText(overTxt, showStr)
    local showStr = ccClientText(21074)
    self:SetWndText(curTxt, showStr)

    if curMapRefId < map.refId or isRest then
        local startTime = map.openTime + gModelInvasion:GetBigCircleStartTime()
        local str = ""
        local endTime = map.openTime + map.continuedTime + gModelInvasion:GetBigCircleStartTime()

        local startDate = LUtil.OSDate('*t', startTime)
        local endDate = LUtil.OSDate('*t', endTime)

        str = ccClientText(21068)
        str = string.replace(str, startDate['month'], startDate['day'], endDate['month'], endDate['day'])

        self:SetWndText(futureTxt, str)
    end

    --点击方法
    self:SetWndClick(item, function()
        --  GF.ShowMessage("打开了" .. itemdata.functionId .. "对应的功能和方法")

        self:OnClickMap(map.refId)
    end)
end

function UIInvoss:SetBtnText(trans, str)
    local text = self:FindWndTrans(trans, "text")
    self:SetWndText(text, str)
end

--endregion --------------------------------------------------------------------------------------

--region 计时器 --------------------------------------------------------------------------------
function UIInvoss:OnTimer(key)
    if self._countDownKey == key then
        self:ShowCountDown()
    elseif self._delayScrollKey == key then
        if self._delayScrollFun then
            self._delayScrollFun()
        end
    end
end
--endregion --------------------------------------------------------------------------------------


--region 事件回调 --------------------------------------------------------------------------------
--req
function UIInvoss:RefreshUI()
    local bossData = gModelInvasion:GetBossData()
    self._bossData = bossData
    if not bossData then
        return
    end

    if self:ShowCountDown() then
        self:TimerStart(self._countDownKey, 1, false, -1)
    end

    self:SetMyRankInfo()
    local str = ""
    local maxCnt = gModelInvasion:GetInvasionPara("bossMaxNum")
    local leftCnt = bossData.alreadyDareCount
    str = ccClientText(21016) --"挑战次数:%s/%s"
    str = string.replace(str, leftCnt, maxCnt)
    self:SetWndText(self.mFightTimes, str)

    local canSweep = maxCnt - leftCnt > 0
    self:SetWndButtonGray(self.mSweepBtn, not canSweep)

    str = ccClientText(21017) --"每次挑战造成的伤害越高,奖励越多"
    self:SetWndText(self.mTipText, str)
    --str = ccLngText(self._ref.simpleStrategy)
    --self:SetWndText(self.mCookText, str)

    self:InitTextLineWithLanguage(self.mCookText, -40)

    self:RefreshPageContent()

    self:ShowTargetInfo()

    self:SetSimpleStrategyInfo()

    self:SetUIState()
end

function UIInvoss:SetName()
    self:SetWndText(self.mModel_title, ccClientText(21071))
end

function UIInvoss:OnClickMap(k)
    local map = self._mapList[k]
    if not map then
        return
    end

    local curMapRefId = gModelInvasion:GetCurInvasionRefId()
    if not curMapRefId then
        return
    end

    --当前的轮次
    local curMapRefId = gModelInvasion:GetCurInvasionRefId()
    if not curMapRefId then
        return
    end

    if curMapRefId > map.refId then
        local str = ccClientText(21069)--"未开放")
        GF.ShowMessage(str)
        return
    end

    if curMapRefId < map.refId then
        local startTime = map.openTime + gModelInvasion:GetBigCircleStartTime()
        local day = LUtil.GetCurTimeDayNum(startTime - GetTimestamp())
        local str = ccClientText(21070)--"未开放")
        --算个时间
        GF.ShowMessage(string.replace(str, day))
        return
    end

    if gModelInvasion:IsCurCircleEnd() then
        local str = ccClientText(21045)-- "本轮已结束"
        GF.ShowMessage(str)
        return
    end

    if gModelInvasion:IsStopFightTime() then
        local str = ccClientText(21044) --"休战时间..."
        GF.ShowMessage(str)
        return
    end


    --GF.ShowMessage("------------没有操作------")

end

function UIInvoss:InitEvent()
    self:WndNetMsgRecv(LProtoIds.AlienInvasionBossResp, function()
        self:RefreshUI()
    end)
    self:WndNetMsgRecv(LProtoIds.RankResp, function(...)
        self:RefreshRank(...)

    end)
end

----检查下是否为sweep
--function UIInvoss:CheckIsSweep()
--    if self._isSweep then
--        self:OnClickSweep()
--    end
--end

----检查下当前的boss是否已经结束
function UIInvoss:CheckIsOver()

    local endTime = gModelInvasion:GetBossEndTime()
    local timeLeft = endTime - GetTimestamp()
    local isNotEnd = timeLeft > 0

    return not isNotEnd
end

function UIInvoss:InitUIEvent()
    self:SetWndClick(self.mReturnBtn, function()
        --切换下底图场景
        GF.ChangeMap("LCityMap")
        gLGameUI:CloseAllButExcept("UIOutts")
        self:WndClose()
    end)

    self:SetWndClick(self.mFightBtn, function()
        self:OnClickFight()
    end)

    self:SetWndClick(self.mSweepBtn, function()
        self:OnClickSweep()
    end)

    self:SetWndClick(self.mRankBtn, function()
        local rewardList = gModelInvasion:GetCurRankRewardList()
        local endTime = gModelInvasion:GetCircleEndTime() / 1000
        GF.OpenWnd("UIRkPop", { refId = ModelRank.RANK_INVASION, rewardList = rewardList, endTime = endTime })
    end)

    self:SetWndClick(self.mShopBtn, function()
        --
        --local shopJump = gModelInvasion:GetInvasionPara("shopJump")
        --gModelFunctionOpen:Jump(shopJump)
    end)

    self:SetWndClick(self.mClickArea, function()
        local rewardList = gModelInvasion:GetCurRankRewardList()
        local endTime = gModelInvasion:GetCircleEndTime() / 1000
        GF.OpenWnd("UIRkPop", { refId = ModelRank.RANK_INVASION, rewardList = rewardList, endTime = endTime })
    end)

    self:SetWndClick(self.mRewardInfoBtn, function()
        GF.OpenWnd("UIInvasionAwardSow")
    end)

    self:SetWndClick(self.mHelpBtn, function()
        self:OnClickStrategy()
    end)

    self:SetWndClick(self.mHelpTips, function()
        GF.OpenWndUp("UIBzTips", { refId = 72 })
    end)


end

function UIInvoss:InitBossInfo()
    self._mapList = gModelInvasion:GetMapList()
end

--uiEvent
function UIInvoss:OnClickStrategy()
    local desc = ccLngText(self._ref.Strategy)
    local skillDataList = gModelInvasion:GetBossRefValueByKey(self._refId, "showSkill")

    GF.OpenWnd("UIFlandBossStrategy", { desc = desc, skillDataList = skillDataList, wndType = 2 })
end

function UIInvoss:SetUIState()
    if self:CheckIsOver() then
        self:SetWndButtonGray(self.mFightBtn, true)
    else
        self:SetWndButtonGray(self.mFightBtn, false)

        if gModelInvasion:IsCurCircleEnd() then
            self:SetWndButtonGray(self.mFightBtn, true)
        end

        if gModelInvasion:IsStopFightTime() then
            self:SetWndButtonGray(self.mFightBtn, true)
        end
    end

    if gModelInvasion:IsCurCircleEnd() then
        --本轮结束
        CS.ShowObject(self.mBossState, true)
        CS.ShowObject(self.mBossStateImg_StopFight, false)
        CS.ShowObject(self.mBossStateImg_CircleEnd, true)
        self:SetWndText(self.mBossStateTxt, ccClientText(21045))

    elseif gModelInvasion:IsStopFightTime() then
        --休战中
        CS.ShowObject(self.mBossState, true)
        CS.ShowObject(self.mBossStateImg_StopFight, true)
        CS.ShowObject(self.mBossStateImg_CircleEnd, false)
        self:SetWndText(self.mBossStateTxt, ccClientText(21044))
    end
end

function UIInvoss:DelayScrollTo(index, itemCnt)
    local rect = self.mItemList.rect
    local viewLength = rect.width
    rect = self.mContent.rect
    local contentLength = rect.width
    if contentLength <= viewLength then
        return
    end
    local total = itemCnt

    local padding = 0
    local layout = self.mBoxRoot:GetComponent(typeHorizontalLayoutGroup)
    padding = layout.padding.left

    local factor = (padding + (index - 0.5) * contentLength / total - viewLength / 2) / (contentLength - viewLength)
    factor = Mathf.Clamp(factor, 0, 1)

    local scrollRect = self.mItemList:GetComponent(typeScrollRect)
    scrollRect.normalizedPosition = Vector2(factor, 0)
end

--中间的伤害列表奖励设置
function UIInvoss:ShowTargetInfo()
    local _, targetList = gModelInvasion:GetCurBossReward()
    if not targetList then
        return
    end
    self._objPool:ReturnAllObj()

    local index = nil
    self._boxItemUIRecord = {}
    for k, v in ipairs(targetList) do
        local obj = self._objPool:GetObj()
        CS.ShowObject(obj, true)
        CS.SetParentTrans(obj, self.mBoxRoot)

        self:OnDrawBox(obj.transform, v)
        local state = gModelInvasion:GetBossRewardState(v.refId)
        if not index and state == ModelQuest.TASK_FINNISH then
            index = k
        end
    end

    if not index then
        index = 1
    end

    local allHurt = tonumber(self._bossData.allHurt)

    local dataList = {}
    for k, v in ipairs(targetList) do
        table.insert(dataList, tonumber(v.needHurt))
    end

    local progress = LUtil.GetCurPercent(dataList, allHurt)

    progress = Mathf.Clamp(progress, 0, 1)
    LxUiHelper.SetProgress(self.mBoxProgress, progress)

    local itemCnt = #targetList

    self._delayScrollFun = function()
        self:DelayScrollTo(index, itemCnt)
    end
    self:TimerStop(self._delayScrollKey)
    self:TimerStart(self._delayScrollKey, 0, false, 1)

end

function UIInvoss:OnClickFight()
    local endTime = gModelInvasion:GetBossEndTime()
    local timeLeft = endTime - GetTimestamp()
    if timeLeft < 0 then
        local str = ccClientText(21045) --"本轮boss挑战已结束"
        GF.ShowMessage(str)
        return
    end

    if not self._bossData then
        return
    end

    local leftCnt = self._bossData.alreadyDareCount
    if leftCnt <= 0 then
        local str = ccClientText(21013)-- "次数不足"
        GF.ShowMessage(str)
        return
    end

    if gModelInvasion:IsCurCircleEnd() then
        local str = ccClientText(21045)-- "本轮已结束"
        GF.ShowMessage(str)
        return
    end

    if gModelInvasion:IsStopFightTime() then
        local str = ccClientText(21044) --"休战时间..."
        GF.ShowMessage(str)
        return
    end

    self:WndClose()
    gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_INVASION_BOSS)
end

function UIInvoss:OnDrawBox(item, itemdata)
    local Image = self:FindWndTrans(item, "Image")
    local icon = self:FindWndTrans(item, "icon")
    local UIText = self:FindWndTrans(item, "UIText")
    local num = self:FindWndTrans(item, "num")
    local tag = self:FindWndTrans(item, "tag")
    local mark = self:FindWndTrans(item, "mark")

    local refId = itemdata.refId
    local state = gModelInvasion:GetBossRewardState(refId)
    local rewardList = gModelInvasion:GetBossRewardShow(refId)

    local reward = rewardList[1]
    local itemId = reward.itemId
    local iconPath = gModelItem:GetItemImgByRefId(itemId)
    self:SetWndEasyImage(icon, iconPath)

    self:SetWndText(num, LUtil.NumberCoversion(reward.itemNum))

    local hurt = itemdata.needHurt
    local hurtShow = LUtil.NumberCoversion(hurt)
    self:SetWndText(UIText, hurtShow)
    CS.ShowObject(tag, state == 1)
    CS.ShowObject(mark, state == 2)

    self._boxItemUIRecord[refId] = { item, itemdata }

    self:SetWndClick(item, function()
        self:OnClickBox(itemdata)
    end)
end

--region wndFunction --------------------------------------------------------------------------------
--设置活动信息 --name and  time
function UIInvoss:SetDurationTime()
    local time = gModelInvasion:GetBigCircleStartTime()
    local startDate = LUtil.OSDate("*t", time)
    time = gModelInvasion:GetBigCircleEndTime()
    local endDate = LUtil.OSDate("*t", time)

    local str = ccClientText(21027)--"持续时间:%s.%s~%s.%s")
    --第二天凌晨 所以扣减1
    str = string.replace(str, startDate["month"], startDate["day"], endDate["month"], endDate["day"] - 1)

    self:SetWndText(self.mDurationTime, str)
end

--排行榜数据
function UIInvoss:SetMyRankInfo()
    local bossData = self._bossData
    local myRank = bossData.rank

    local isShowMyHurt = myRank > 3

    CS.ShowObject(self.mMy, isShowMyHurt)
    if isShowMyHurt then

        --local hurt = bossData.hurt
        --local str = LUtil.NumberCoversion(hurt)
        local str = gModelPlayer:GetPlayerName()
        str = myRank .. " " .. str
        self:SetWndText(self.mMy_Hurt, str)
    end
end
function UIInvoss:OnWndRefresh()
    self._curPage = self:GetWndArg("page") or 1

    local data = {
        type = 0
    }
    gModelInvasion:OnAlienInvasionBossReq(data)

    self:ShowPart()
end

function UIInvoss:InitData()
    self._countDownKey = "_countDownKey"
    self._delayScrollKey = "_delayScrollKey"
    --self._isSweep = self:GetWndArg("isSweep")

    self._rankTran = {
        self.mRank_Name_1,
        self.mRank_Name_2,
        self.mRank_Name_3,
    }

    self._rankMeTran = {
        self.mMy_Tag_1,
        self.mMy_Tag_2,
        self.mMy_Tag_3,
    }

    self._objPool = UIObjPool:New()
    self._objPool:Create(self.mUnuseRoot, self.mItemTemplate)

    self:InitBossInfo()

    gModelRank:OnRankReq(2, ModelRank.RANK_INVASION, 1, 25, nil)--排行榜请求
end

function UIInvoss:OnClickBox(itemdata)
    local refId = itemdata.refId
    local state = gModelInvasion:GetBossRewardState(refId)
    if state == ModelQuest.TASK_UNFINISH then

        local reward = gModelInvasion:GetBossRewardShow(refId)
        local item = reward[1]
        gModelGeneral:ShowCommonItemTipWnd(item)

    elseif state == ModelQuest.TASK_FINNISH then
        gModelInvasion:OnAlienInvasionBossReq({ type = 3, rewardRefId = refId })
    else
        local str = ccClientText(11209) -- "奖励已领取"
        GF.ShowMessage(str)
    end

end

function UIInvoss:OnClickSweep()
    local endTime = gModelInvasion:GetBossEndTime()
    local timeLeft = endTime - GetTimestamp()
    if timeLeft < 0 then
        local str = ccClientText(21045) -- "本轮boss挑战已结束"
        GF.ShowMessage(str)
        return
    end

    gModelInvasion:OnClickSweep()
end
function UIInvoss:RefreshForeign()
    if self._isVie then
        local typeUIImage = typeof(UnityEngine.UI.Image)
        local imageTran = self:FindCommonComponent(self.mBossStateImg_CircleEnd, typeUIImage)

        local imageTran_2 = self:FindCommonComponent(self.mBossStateImg_StopFight, typeUIImage)
        imageTran.type = imageTran_2.type

        LxUiHelper.SetSizeWithCurAnchor(self.mBossStateImg_CircleEnd, 0, 200)
        LxUiHelper.SetSizeWithCurAnchor(self.mBossStateImg_StopFight, 0, 200)
    end
end

function UIInvoss:SetStaticContent()
    local str = ccClientText(10367)-- "挑战"
    self:SetWndButtonText(self.mFightBtn, str)
    str = ccClientText(21011)-- "扫荡"
    self:SetWndButtonText(self.mSweepBtn, str)

    str = ccClientText(11713)-- "伤害排行"
    self:SetTextTile(self.mInfoTitle1, str)

    str = ccClientText(10361)--"奖励"
    self:SetTextTile(self.mRewardInfoBtn, str)
    str = ccClientText(10360)-- "排行"
    self:SetTextTile(self.mRankBtn, str)

    str = ccClientText(30205)-- "返回"
    self:SetWndText(self.mReturnBtn, str)
    str = ccClientText(21012)-- "全服目标"
    self:SetWndText(self.mTargetText, str)

    str = ccClientText(21038)
    self:SetWndText(self.mEmptyText, str)

    str = ccClientText(21067)
    self:SetWndText(self.mCheckMore, str)

    str = ccClientText(21072)
    self:SetWndText(self.mRankTitle, str)

    local shopTxt = self:FindWndTrans(self.mShopBtn, "UIText")
    str = ccClientText(21066)
    self:SetWndText(shopTxt, str)

    local text = self:FindWndTrans(self.mRewardInfoBtn, "UIText")
    self:InitTextLineWithLanguage(text, -40)

    str = ccClientText(21044)
    self:SetWndText(self.mBossStateTxt, str)

    --屏蔽掉不需要的部分
    CS.ShowObject(self.mShopBtn, false)
end

function UIInvoss:RefreshRank(...)
    local ranks = gModelRank:GetRankListInfo(2, ModelRank.RANK_INVASION)

    local threeList = {}
    for i, v in ipairs(ranks) do
        v.index = i
        if (v.rank >= 1 and v.rank <= 3) then
            table.insert(threeList, v)
        end
    end

    local len = #threeList
    for k = len + 1, 3 do
        table.insert(threeList, { index = k })
    end

    for k = 1, 3 do
        local playerInfo = threeList[k].info
        local isSelf = false
        if playerInfo then
            local nameStr = playerInfo._name
            self:SetWndText(self._rankTran[k], nameStr)

            isSelf = playerInfo._playerId == gModelPlayer:GetPlayerId()
        else
            self:SetWndText(self._rankTran[k], ccClientText(11711))
        end

        CS.ShowObject(self._rankMeTran[k], isSelf)
    end
end

function UIInvoss:SetSimpleStrategyInfo()
    local str = string.split(ccLngText(self._ref.simpleStrategy), "|")

    local uiList = self._uiStrategyList
    if not uiList then
        uiList = self:GetUIScroll("StrategyInfoList")
        uiList:Create(self.mSkillInfo, str, function(...)
            self:OnDrawStrategyInfo(...)
        end, UIItemList.SUPER)
        self._uiStrategyList = uiList


    else
        uiList:RefreshList(str)
    end

    uiList:EnableScroll(false)
end

--设置boss信息
function UIInvoss:SetBossInfo()
    --右侧的boss名字
    local name = self._ref.bossName
    self:SetWndText(self.mTitle, ccLngText(name))
    --boss 背景
    local bgPath = self._ref.bossBg

    self:SetWndEasyImage(self.mBg, bgPath, nil, false, true)

    local skinBg = self._ref.bossSpineBg
    local skinSpineHd = self._ref.bossSpineHd

    local showeBg = not string.isempty(skinBg)
    local showeHd = not string.isempty(skinSpineHd)

    self._roleSpine = self._roleSpine or {}
    if showeBg then
        if not self._roleSpine[skinBg] then

            self._roleSpine[skinBg] = self:CreateWndSpine(self.mRoleSpineBg, skinBg, skinBg, false, function(dpSpine)
            end)
        else
            self._roleSpine[skinBg]:SetVisible(true)
        end
    end
    CS.ShowObject(self.mRoleSpineBg, showeBg)

    --判断下旧的有没有
    if self._oldSpineKey then
        if self._oldSpineKey ~= skinBg then
            self._roleSpine[self._oldSpineKey]:SetVisible(false)

        end
    end
    self._oldSpineKey = skinBg

    if showeHd then
        self:CreateWndSpine(self.mRoleSpineHd, skinSpineHd, skinSpineHd, false, function(dpSpine)
        end)
    end
    CS.ShowObject(self.mRoleSpineHd, showeHd)



    --boss spine
    local spineName = self._ref.bossPrefab
    if not string.isempty(spineName) then
        self:CreateWndSpine(self.mRole, spineName, spineName)
    end

    --奖励列表
    local rewardList = gModelInvasion:GetBossRefValueByKey(self._refId, "bossShowReward")

    local instanceId = self.mRewardList:GetInstanceID()
    local list = self._commonIconList[instanceId]
    if not list then
        list = UIIconEasyList:New()
        list:Create(self, self.mRewardList)
        list:SetIconParentPath("iconRoot")

        self._commonIconList[instanceId] = list
    end

    list:RefreshList(rewardList)

    --左侧boss信息
    self:SetBossList()
end

--设置左侧的boss列表
function UIInvoss:SetBossList()
    if not self._mapList then
        printInfoN("self._mapList is not find")
        return
    end

    local uiList = self:GetUIScroll("UIInvossList")
    if uiList:GetList() then
        uiList:RefreshList(self._mapList)
    else
        uiList:Create(self.mBossInfo, self._mapList, function(...)
            self:OnDrawCellItem(...)
        end, UIItemList.SUPER)
        uiList:EnableScroll(false)
    end
end

function UIInvoss:ShowPart()
    --整理ref的部分
    self._refId = gModelInvasion:GetCurInvasionRefId()
    if not self._refId then
        return
    end
    self._ref = gModelInvasion:GetMapRef(self._refId)

    self:SetBossInfo()

    self:SetDurationTime()
    self:SetName()

    self:RefreshRank()
end

function UIInvoss:RefreshPageContent()
    CS.ShowObject(self.mRewardPage, self._curPage == 1)
    CS.ShowObject(self.mCookPage, self._curPage ~= 1)
end
function UIInvoss:OnDrawStrategyInfo(list, item, itemdata, itempos)
    local showTxt = CS.FindTrans(item, "UIText")

    self:SetWndText(showTxt, itemdata)
end

function UIInvoss:ShowCountDown()
    --local funcList = gModelDailyGameEnter:GetItemInfoFunc(104)

    local endTime = gModelInvasion:GetBossEndTime()
    --local endTime = gModelInvasion:GetBossEndTime()



    local timeLeft = endTime - GetTimestamp()
    local timeStr = ccClientText(11830) --"已结束"
    local isNotEnd = timeLeft > 0
    if isNotEnd then
        timeStr = LUtil.FormatTimespanCn(timeLeft)
    else
        self:TimerStop(self._countDownKey)
    end
    local str = string.replace(ccClientText(21037), timeStr)
    self:SetWndText(self.mCountDown, str)

    return isNotEnd


end
--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIInvoss


