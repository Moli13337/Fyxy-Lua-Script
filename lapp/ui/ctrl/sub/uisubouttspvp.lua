---
--- Created by Administrator.
--- DateTime: 2023/10/22 20:10:19
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubOuttsPVP:LChildWnd
local UISubOuttsPVP = LxWndClass("UISubOuttsPVP", LChildWnd)

local UnityEngine = UnityEngine
local typeUIImage = typeof(UnityEngine.UI.Image)

---定义常量
UISubOuttsPVP.CROSS_LADDER = 204  --跨界天梯
UISubOuttsPVP.CROSS_CHAMPION = 205 --跨界周冠
UISubOuttsPVP.ARENA_RANK = 201     --排位赛
UISubOuttsPVP.ARENA_PEAK = 202     --巅峰赛
UISubOuttsPVP.CROSS_GRADING = 203     --段位赛
UISubOuttsPVP.SIMULATE = 206         -- 奥兹模拟
UISubOuttsPVP.COMING_SOON = 207     --尽请期待

UISubOuttsPVP.MOVE_RIGHT = -1
UISubOuttsPVP.MOVE_LEFT = 1
UISubOuttsPVP.MOVE_CENTER = 0

UISubOuttsPVP.PageType = 2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubOuttsPVP:UISubOuttsPVP()
    self._dragKey = "_dragKey"
    self._topSelectEff = "ui_fx_xuanze"
    self._pageSelectEff = "ui_fx_haibaosaoguang"
    self._topFightEff = "ui_fx_saishiranshao"
    self:SetHideHurdle()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubOuttsPVP:OnWndClose()
    if self._seqCom then
        self._seqCom:Destroy()
        self._seqCom = nil
    end

    LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubOuttsPVP:OnCreate()
    LChildWnd.OnCreate(self)
    self:SetWndSwitchType(LChildWnd.SWITCH_TYPE_CHANGE_BTN)
    self._seqCom = SequenceCom:New()  --tween动画管理

    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubOuttsPVP:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()

    -------------------
    self:InitBtnEvent()
    self:InitMsgEvent()
    self:InitData()
    self:InitView()
end

function UISubOuttsPVP:UIDragOnBegin(dragKey, eventData)
    self._bMove = true
end


function UISubOuttsPVP:SetCommonPageItem(item, moduleData, itempos, showEff)
    if CS.IsNullObject(item) or not moduleData then
        return
    end

    local topTrans = self:FindWndTrans(item, "TopRoot")
    local topContent = self:FindWndTrans(topTrans, "Content")
    local topSelect = self:FindWndTrans(topContent, "select")
    local redPoint = self:FindWndTrans(topContent, "redPoint")

    local moduleTrans = self:FindWndTrans(item, "AniRoot")
    local bg = self:FindWndTrans(moduleTrans, "bg")
    local titleImg = self:FindWndTrans(moduleTrans, "titleImg")
    local title = self:FindWndTrans(moduleTrans, "title")

    local gradingInfo = self:FindWndTrans(moduleTrans, "gradingInfo")
    local dateInfo = self:FindWndTrans(moduleTrans, "dateInfo")
    local dateInfoText = self:FindWndTrans(dateInfo, "dateInfoText")
    local timeInfo = self:FindWndTrans(moduleTrans, "dateInfo")
    local timeInfoText = self:FindWndTrans(timeInfo, "timeInfoText")
    local rankInfo = self:FindWndTrans(moduleTrans, "rankInfo")
    local lock = self:FindWndTrans(moduleTrans, "lock")
    local lockIcon = self:FindWndTrans(moduleTrans, "Icon")
    local lockInfoText = self:FindWndTrans(lock, "lockInfo/lockInfoText")
    local mask = self:FindWndTrans(moduleTrans, "mask")
    local maskImg = mask:GetComponent(typeUIImage)
    local selectEff = self:FindWndTrans(moduleTrans, "selectEff")

    if itempos and not self._itemTemplateList[itempos] then
        local transInfo = {
            itemTemplate = item,
            aniRoot = moduleTrans,
            maskImg = maskImg,
            selectEff = selectEff,
            topTrans = topTrans,
            topContent = topContent,
            topSelect = topSelect,
            timeInfoText = timeInfoText,
            redPoint = redPoint,
        }
        self._itemTemplateList[itempos] = transInfo
    end

    self:SetTopRoot(topContent, moduleData, showEff)

    local refId = moduleData.refId
    self._showFightEffList[refId] = showEff or false
    local bOpen = moduleData.isOpen

    CS.ShowObject(gradingInfo, false)
    CS.ShowObject(dateInfo, bOpen)
    CS.ShowObject(timeInfo, false)
    CS.ShowObject(rankInfo, false)

    local moduleRef = moduleData.cfg
    self:SetWndEasyImage(bg, moduleRef.bg)

    local titleIcon = moduleRef.titleIcon
    local haveTitleIcon = not string.isempty(titleIcon)
    CS.ShowObject(titleImg, haveTitleIcon)
    if haveTitleIcon then
        --self:SetWndEasyImage(titleImg, moduleRef.titleIcon, nil, true)
        local icon = moduleRef.icon
        self:SetWndEasyImage(titleImg, icon)
    end
    --name title
    self:SetWndText(title,ccLngText(moduleRef.name))

    if not bOpen then
        local msg = moduleData.openMsg
        self:SetWndText(lockInfoText, msg)
        CS.ShowObject(lockIcon, true)
    end
    CS.ShowObject(lock, not bOpen)

    local redPointId = self._pageRedList[refId]
    local showRed = false
    if redPointId and bOpen then
        showRed = gModelRedPoint:CheckShowRedPoint(redPointId)
    end
    CS.ShowObject(redPoint, showRed)

    self:SetWndClick(bg, function()
        self:OnClickModuleCell(moduleRef, itempos)
    end, LSoundConst.CLICK_BUTTON_COMMON)

    self:SetWndClick(topContent, function()
        self:OnClickTopContent(itempos)
    end)



end

--endregion --------------------------------------------------------------------------------------

--region 页面的处理 --------------------------------------------------------------------------------
--刷新两块的列表 --pege 和下方的部分
function UISubOuttsPVP:_UpdateAllPage()
    for k,v in ipairs(self._controlItemSiblingList) do
        local itemIndex = v.itemIndex
        local dataIndex = v.dataIndex
        self:RefreshItemPage(itemIndex, dataIndex)
        local item = self:GetItemTemplate(itemIndex)
        item:SetSiblingIndex(k - 1)
    end
end

function UISubOuttsPVP:AutoMove2Root(moveType)
    local nextFunc = function()
        self:AutoMoveRoot(moveType)
    end

    self:AutoMoveRoot(moveType, nextFunc)
end

--每个item的处理方式 --todo 这里应该放到model里边 item 通过functionid 获取
function UISubOuttsPVP:SetLadderItem(item, itemdata, itempos)
    local bOpen = itemdata.isOpen
    -- 【G公共支持】删除跨服天梯和跨服周冠玩法
    -- local isLadderOpen = gModelCrossServer:IsLadderOpen()
    -- local isLadderOpen = false
    -- local showEff = isLadderOpen and bOpen
    -- self:SetCommonPageItem(item, itemdata, itempos, showEff)

    if not bOpen then
        return
    end

    local dateInfo = self:FindWndTrans(item, "AniRoot/dateInfo")
    local dateInfoText = self:FindWndTrans(dateInfo, "dateInfoText")
    local rankInfo = self:FindWndTrans(item, "AniRoot/rankInfo")
    local rankInfoText = self:FindWndTrans(rankInfo, "rankInfoText")

    local cfg = itemdata.cfg
    self:SetWndText(dateInfoText, ccLngText(cfg.desc))
    CS.ShowObject(dateInfo, true)

    -- 我的排名
    local rank
    local rankStr
    -- 【G公共支持】删除跨服天梯和跨服周冠玩法
    -- if isLadderOpen then
    -- 	rank = gModelCrossServer:GetLadderMyRank()
    -- 	rankStr = tostring(rank)
    -- 	if rank <= 0 or not rank then
    -- 		rankStr = ccClientText(11876)
    -- 	end
    -- 	rankStr = string.replace(ccClientText(32404), rankStr)
    -- else
    --历史最高
    local rankData = self._rankList[UISubOuttsPVP.CROSS_LADDER]
    if rankData then
        rank = rankData.historyRank
        if rank <= 0 or not rank then
            rankStr = ccClientText(11876)
        else
            rankStr = rank
        end
        rankStr = LUtil.FormatColorStr(rankStr, "yellow_2")
        rankStr = ccClientText(11814) .. rankStr
    end
    -- end

    local isShowRank = not string.isempty(rankStr)
    if isShowRank then
        self:SetWndText(rankInfoText, rankStr)
    end
    CS.ShowObject(rankInfo, isShowRank)
end

function UISubOuttsPVP:UIDragOnDrag(dragKey, eventData)
    local moveX = self.mItemRoot.localPosition.x

    if moveX >= self._changeDistanceX then
        self:MoveRoot(UISubOuttsPVP.MOVE_RIGHT)
    elseif moveX <= -self._changeDistanceX then
        self:MoveRoot(UISubOuttsPVP.MOVE_LEFT)
    else
        local curPos = Vector3.New(moveX, 0, 0)
        self.mItemRoot.localPosition = curPos
    end
end

function UISubOuttsPVP:InitView()
    self:RefreshModuleData()
    self:_SetCircleDataAndItemIndex()
    self:_UpdateAllPage()
    self:InitDrag()
    self:RefreshItemTemplateInfoPosAndRotation(true)
end



--循环模式中重设item对应的位置映射，数据对应的映射
function UISubOuttsPVP:_SetCircleDataAndItemIndex()
    local curItemIndex  = self._curPageSelect
    local itemMaxNum = self._itemPageMax

    local curDataIndex = self._curDataIndex
    local dataMaxNum = self._moduleMaxNum

    local itemStart = curItemIndex - 3
    local dataStart = curDataIndex - 3

    local itemIndex,dataIndex
    local newControlItemDataList = {}
    local siblingList = {}

    for k, sibling in ipairs(self._siblingIndexList) do
        itemIndex = itemStart
        if itemIndex <= 0 then
            itemIndex = itemMaxNum + itemIndex
        elseif itemIndex > itemMaxNum then
            itemIndex = itemIndex - itemMaxNum
        end

        dataIndex = dataStart
        if dataIndex <= 0 then
            dataIndex = dataMaxNum + dataIndex
        elseif dataIndex > dataMaxNum then
            dataIndex = dataIndex - dataMaxNum
        end

        local data = {
            itemIndex = itemIndex,
            dataIndex = dataIndex
        }
        newControlItemDataList[k] = data
        siblingList[sibling] = data

        itemStart = itemStart + 1
        dataStart = dataStart + 1
    end
    self._controlItemDataList = newControlItemDataList
    self._controlItemSiblingList = siblingList
end

function UISubOuttsPVP:SetRankItem(item, itemdata, itempos)
    self:SetCommonPageItem(item, itemdata, itempos)

    local bOpen = itemdata.isOpen
    if not bOpen then
        return
    end

    local dateInfo = self:FindWndTrans(item, "AniRoot/dateInfo")
    local dateInfoText = self:FindWndTrans(dateInfo, "dateInfoText")
    local timeInfo = self:FindWndTrans(item, "AniRoot/dateInfo")
    local timeInfoText = self:FindWndTrans(timeInfo, "timeInfoText")
    local rankInfo = self:FindWndTrans(item, "AniRoot/rankInfo")
    local rankInfoText = self:FindWndTrans(rankInfo, "rankInfoText")

    local refId = itemdata.refId
    local seasonEndTime = gModelArena:GetRankSeasonTime()
    local openTime = gModelArena:GetServerOpenTime()

    local seasonStartTime = seasonEndTime - 7 * 24 * 60 * 60
    seasonStartTime = math.max(openTime, seasonStartTime)

    local startDate = LUtil.OSDate("*t", seasonStartTime)
    local endDate = LUtil.OSDate("*t", seasonEndTime - 1)

    if startDate and endDate then
        local timeStr = string.format("%02d.%02d-%02d.%02d", startDate["month"], startDate["day"], endDate["month"], endDate["day"])
        timeStr = LUtil.FormatColorStr(timeStr, "lightGreen")
        self:SetWndText(dateInfoText, ccClientText(10302) .. timeStr)
    end

    -- 剩余时间
    local nowTime = GetTimestamp()
    local seasonEndTime = gModelArena:GetRankSeasonTime()
    local timespan = seasonEndTime - nowTime

    local timeStr = LUtil.FormatTimespanCn(timespan)
    timeStr = LUtil.FormatColorStr(timeStr, "lightGreen")
    timeStr = ccClientText(32410) .. timeStr
    self:SetWndText(timeInfoText, timeStr)
    CS.ShowObject(timeInfo, true)

    self._timerTransMap[self._rankTimerKey] = {
        refId = refId,
        transKey = "timeInfoText",
        time = seasonEndTime,
        title = ccClientText(32410),
    }

    self:TimerStop(self._rankTimerKey)
    if timespan < 0 then
        local seq = self._seqCom:CreateSeq("delayReq")
        seq:AppendInterval(1)
        seq:OnComplete(function()
            gModelArena:OnPlayerArenaReq(true)
        end)
        seq:PlayForward()
    else
        self:TimerStart(self._rankTimerKey, 1, false, -1)
    end

    -- 我的排名
    local rank = gModelArena:GetRank()
    local rankStr = tostring(rank)
    if rank <= 0 then
        rankStr = ccClientText(11876)
    end
    rankStr = string.replace(ccClientText(32404), rankStr)
    self:SetWndText(rankInfoText, rankStr)
    CS.ShowObject(rankInfo, true)
end

function UISubOuttsPVP:_RefreshPageListNewPos()
    for k, v in ipairs(self._controlItemDataList) do
        local itemIndex = v.itemIndex
        local item = self:GetItemTemplate(itemIndex)
        if CS.IsValidObject(item) then
            local pos = self._defaultItemTemplatePosDataList[k].rootLocalPos
            item.localPosition = pos
        end
    end

    for k, v in ipairs(self._controlItemSiblingList) do
        local itemIndex = v.itemIndex
        local item = self:GetItemTemplate(itemIndex)
        if CS.IsValidObject(item) then
            item:SetSiblingIndex(k - 1)
        end
    end

    --重置原本节点
    local curPos = Vector3.New(0, 0, 0)
    self.mItemRoot.localPosition = curPos
end

function UISubOuttsPVP:MoveRoot(index)
    if index == UISubOuttsPVP.MOVE_CENTER then
        return
    end
    --index 为 1  -1    --刷新index
    self:_RefreshCurSelectPageWhenMove(index)
    --刷新列表数据
    self:_RefreshPageListWhenMove(index)
    --刷新位置
    self:_RefreshPageListNewPos()
end

--设置顶部信息
function UISubOuttsPVP:SetTopRoot(topTrans, moduleData, showEff)
    local iconTrans = self:FindWndTrans(topTrans, "icon")
    local lockTrans = self:FindWndTrans(topTrans, "lock")
    local effTrans = self:FindWndTrans(topTrans, "Eff")

    local bOpen = moduleData.isOpen
    local moduleRef = moduleData.cfg
    local showIcon = bOpen
    local showLock = not bOpen

    if showIcon then
        local icon = moduleRef.icon
        if LxUiHelper.IsImgPathValid(icon) then
            self:SetWndEasyImage(iconTrans, icon)
        end
    end
    CS.ShowObject(iconTrans, showIcon)

    CS.ShowObject(lockTrans, showLock)

    CS.ShowObject(effTrans, showEff or false)
    if showEff then
        local InstanceID = topTrans:GetInstanceID()
        local key = self._topFightEff .. InstanceID
        self:CreateWndEffect(effTrans, self._topFightEff, key, 145, false, false)
    end
end

--endregion --------------------------------------------------------------------------------------

--region 拖拽的部分 --------------------------------------------------------------------------------
function UISubOuttsPVP:InitDrag()
    --拖动
    self._runTimer = self:TimerStart(self._moveUpdateTime, 0, false, -1)

    self._changeDistanceX = self.mItemTemplate1.rect.width
    self._autoChangeDistanceX = self._changeDistanceX / 2
    self:_SetCircleDataAndItemIndex()

    self:UIDragSetItem(self._dragKey, "AniRoot/PageList2/ItemRoot", CS.YXUIDrag.DragMode.DragOrigin)
end


--RefreshPageListWhenMove  设置方法
function UISubOuttsPVP:RefreshItemPage(itemIndex, dataIndex)
    local data = self._moduleDataList[dataIndex]
    local item = self:GetItemTemplate(itemIndex)
    if CS.IsValidObject(item) then
        self:OnDrawModuleCell(nil, item, data, itemIndex)
    end
end

function UISubOuttsPVP:OnClickTopContent(itemPos)
    local targetIndex
    for k,v in ipairs(self._controlItemDataList) do
        if v.itemIndex == itemPos then
            targetIndex = k
            break
        end
    end

    if targetIndex == 5 then
        --右边第1个
        self:AutoMoveRoot(UISubOuttsPVP.MOVE_LEFT)
    elseif targetIndex == 6 then
        --右边第2个
        self:AutoMove2Root(UISubOuttsPVP.MOVE_LEFT)
    elseif targetIndex == 3 then
        --左边第1个
        self:AutoMoveRoot(UISubOuttsPVP.MOVE_RIGHT)
    elseif targetIndex == 2 then
        --左边第2个
        self:AutoMove2Root(UISubOuttsPVP.MOVE_RIGHT)
    end
end

function UISubOuttsPVP:InitBtnEvent()
    --按钮事件 return left right
    self:SetWndClick(self.mBackBtn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mArrowLeft, function()
        self:AutoMoveRoot(UISubOuttsPVP.MOVE_RIGHT)
    end, LSoundConst.CLICK_BUTTON_COMMON)
    self:SetWndClick(self.mArrowRight, function()
        self:AutoMoveRoot(UISubOuttsPVP.MOVE_LEFT)
    end, LSoundConst.CLICK_BUTTON_COMMON)
end
--RefreshItemPage 获取Item
function UISubOuttsPVP:GetItemTemplate(itemIndex)
   return self._itemTransList[itemIndex]
end
--endregion --------------------------------------------------------------------------------------

--region timer  --------------------------------------------------------------------------------
function UISubOuttsPVP:OnTimer(key)
    local timerItem = self._timerTransMap[key]
    if timerItem then
        local refId = timerItem.refId
        local timeInfoTrans
        local dataIndex
        local transKey = timerItem.transKey
        for k, v in ipairs(self._controlItemDataList) do
            dataIndex = v.dataIndex
            if dataIndex then
                local moduleData = self._moduleDataList[dataIndex]
                if moduleData and moduleData.refId == refId then
                    local itemIndex = v.itemIndex
                    if itemIndex then
                        timeInfoTrans = self:GetItemTargetTransByKey(itemIndex, transKey)
                        if timeInfoTrans and CS.IsValidObject(timeInfoTrans) then
                            local seasonEndTime = timerItem.time
                            local nowTime = GetTimestamp()
                            local timespan = seasonEndTime - nowTime

                            local timeStr = nil
                            if timerItem.formatFun then
                                timeStr = timerItem.formatFun(timespan)
                            else
                                timeStr = LUtil.FormatTimespanCn(timespan)
                            end
                            timeStr = LUtil.FormatColorStr(timeStr, "lightGreen")
                            timeStr = timerItem.title .. timeStr

                            self:SetWndText(timeInfoTrans, timeStr)
                            if timespan <= 0 then
                                self:TimerStop(key)
                            end
                        end
                    end
                end
            end
        end
    elseif key == self._moveUpdateTime then
        self:MoveAnimationUpdate()
    end
end

--endregion --------------------------------------------------------------------------------------

--region 红点控制 --------------------------------------------------------------------------------
function UISubOuttsPVP:RefreshPageRedPoint(redPointType)
    local refId = self._redPageList[redPointType]
    if not refId then
        return
    end

    local moduleIndex
    for k, v in ipairs(self._moduleDataList) do
        if v.refId == refId then
            moduleIndex = k
            break
        end
    end

    if not moduleIndex then
        return
    end

    local isShow = gModelRedPoint:CheckShowRedPoint(redPointType)
    for k, v in ipairs(self._controlItemDataList) do
        if v.dataIndex == moduleIndex then
            local redPointTrans = self:GetItemTargetTransByKey(v.itemIndex, "redPoint")
            if CS.IsValidObject(redPointTrans) then
                CS.ShowObject(redPointTrans, isShow)
            end
        end
    end
end
--GetItemTemplate 找到节点的方法
function UISubOuttsPVP:GetItemTargetTransByKey(itemIndex, transKey)
    local templateInfo = self._itemTemplateList[itemIndex]
    if not templateInfo then
        return nil
    end

    return templateInfo[transKey]
end

function UISubOuttsPVP:SetSimulateItem(item, itemdata, itempos)
    self:SetCommonPageItem(item, itemdata, itempos)
end

function UISubOuttsPVP:SetPeakItem(item, itemdata, itempos)
    local bOpen = itemdata.isOpen
    local state = gModelArena:GetPeakState()
    local isForeign = self._isForeign
    local combatState = gModelArena:GetPeakCombatState()
    local peakStateBefore = state == ModelArena.PEAK_STATE_BEFORE
    local isGaming = state == ModelArena.PEAK_STATE_STARTED and not peakStateBefore
    if isForeign then
        --海外巅峰赛，竞猜阶段，算是前端做的赛前
        peakStateBefore = peakStateBefore or combatState == ModelArena.PEAK_BATTLE_STATE_BETTING
        isGaming = combatState == ModelArena.PEAK_BATTLE_STATE_BETTING
    end

    local showEff = isGaming and bOpen
    self:SetCommonPageItem(item, itemdata, itempos, showEff)

    if not bOpen then
        return
    end

    local dateInfo = self:FindWndTrans(item, "AniRoot/dateInfo")
    local dateInfoText = self:FindWndTrans(dateInfo, "dateInfoText")
    local timeInfo = self:FindWndTrans(item, "AniRoot/dateInfo")
    local timeInfoText = self:FindWndTrans(timeInfo, "timeInfoText")
    local rankInfo = self:FindWndTrans(item, "AniRoot/rankInfo")
    local rankInfoText = self:FindWndTrans(rankInfo, "rankInfoText")

    local curTime = GetTimestamp()
    local timeLeftStr = ""
    local stageStr = ""
    self:TimerStop(self._peakTimerKey)

    local refId = itemdata.refId

    local showPealMaxRank = false
    local needLeftTime = false
    if peakStateBefore then
        local stageStrKey = 32408
        local peakStartTime = gModelArena:GetPeakStartTime()
        showPealMaxRank = true
        if isForeign then
            if state == ModelArena.PEAK_STATE_BEFORE then
                showPealMaxRank = false
            elseif combatState == ModelArena.PEAK_BATTLE_STATE_BETTING then
                --竞猜中（海外）
                peakStartTime = gModelArena:GetNextCombatStateTime()
                local timeLeft = peakStartTime - curTime
                if timeLeft < 0 then
                    timeLeft = 0
                end

                local timeStr = LUtil.FormatTimespanNumber(timeLeft)
                timeLeftStr = LUtil.FormatColorStr(timeStr, "lightGreen")
                timeLeftStr = ccClientText(32407) .. timeLeftStr

                self._timerTransMap[self._peakTimerKey] = {
                    refId = refId,
                    time = peakStartTime,
                    transKey = "timeInfoText",
                    title = ccClientText(32407),
                    formatFun = LUtil.FormatTimespanNumber,
                }
                self:TimerStart(self._peakTimerKey, 1, false, -1)
            end
        end

        local cfg = itemdata.cfg
        stageStr = ccLngText(cfg.desc)
    elseif state == ModelArena.PEAK_STATE_STARTED then
        local peakStage = gModelArena:GetPeakStage()
        local stateStr = self._peakStageStr[peakStage] or ""
        stageStr = string.replace(ccClientText(32405), stateStr)

        local isGuessing = combatState == ModelArena.PEAK_BATTLE_STATE_BETTING
        if isGuessing then
            --竞猜中
            timeLeftStr = ccClientText(32407)
            timeLeftStr = LUtil.FormatColorStr(timeLeftStr, "lightGreen")
        else
            --阶段倒计时
            local nextTime = gModelArena:GetNextCombatStateTime()
            local timeLeft = nextTime - curTime
            if timeLeft < 0 then
                timeLeft = 0
            end
            local timeStr = LUtil.FormatTimespanNumber(timeLeft)
            timeLeftStr = LUtil.FormatColorStr(timeStr, "lightGreen")
            timeLeftStr = ccClientText(32406) .. timeLeftStr

            self._timerTransMap[self._peakTimerKey] = {
                refId = refId,
                time = nextTime,
                transKey = "timeInfoText",
                title = ccClientText(32406),
                formatFun = LUtil.FormatTimespanNumber,
            }

            self:TimerStart(self._peakTimerKey, 1, false, -1)
        end
    elseif state == ModelArena.PEAK_STATE_END then
        stageStr = ccClientText(11812)
    end
    self:SetWndText(dateInfoText, stageStr)
    local isShowTimeLeft = not string.isempty(timeLeftStr)
    CS.ShowObject(timeInfo, isShowTimeLeft)
    if isShowTimeLeft then
        self:SetWndText(timeInfoText, timeLeftStr)
    end

    local rankStr
    if showPealMaxRank then
        --历史最高
        local pealMaxRank = gModelArena:GetPeakMaxRank()
        if not pealMaxRank or pealMaxRank <= 0 then
            rankStr = ccClientText(11876)
        else
            rankStr = tostring(pealMaxRank)
        end

        rankStr = LUtil.FormatColorStr(rankStr, "yellow_2")
        rankStr = ccClientText(11814) .. rankStr
    else
        --巅峰排行
        local peakRank = gModelArena:GetPeakRank()
        if peakRank <= 0 then
            rankStr = ccClientText(11876)
        else
            rankStr = tostring(peakRank)
            rankStr = string.replace(ccClientText(32404), rankStr)
        end
    end
    local isShowRank = not string.isempty(rankStr)
    if isShowRank then
        self:SetWndText(rankInfoText, rankStr)
    end
    CS.ShowObject(rankInfo, isShowRank)
end

function UISubOuttsPVP:AutoMoveRoot(moveType, nextFunc)
    local itemRoot = self.mItemRoot
    if not CS.IsValidObject(itemRoot) then
        return
    end
    self._bMove = true

    local moveX
    if moveType == UISubOuttsPVP.MOVE_RIGHT then
        --自动右移一页
        moveX = self._changeDistanceX
    elseif moveType == UISubOuttsPVP.MOVE_LEFT then
        --自动左移一页
        moveX = -self._changeDistanceX
    else
        --复位到原页
        moveX = 0
    end

    local seqTween
    self:TweenSeqKill(self._autoMoveKey)
    if not seqTween then
        seqTween = self:TweenSeqCreate(self._autoMoveKey, function(seq)
            if CS.IsValidObject(self.mItemRoot) then
                local vec = Vector2.New(moveX, self.mItemRoot.localPosition.y)
                local tweener = self.mItemRoot:DOLocalMove(vec, self._moveTime)
                seq:Join(tweener)
            end
            return seq
        end)
    end
    seqTween:PlayForward()
    seqTween:OnComplete(function()
        self:TweenSeqKill(self._autoMoveKey)
        self:MoveRoot(moveType)
        self._bMove = false
        self:RefreshItemTemplateInfoPosAndRotation(true)
        if nextFunc then
            --给移动两格使用
            nextFunc()
        end
    end)
end

function UISubOuttsPVP:SetCrossGradingItem(item, itemdata, itempos)
    self:SetCommonPageItem(item, itemdata, itempos)
    local bOpen = itemdata.isOpen
    if not bOpen then
        return
    end

    local dateInfo = self:FindWndTrans(item, "AniRoot/dateInfo")
    local gradingInfo = self:FindWndTrans(item, "AniRoot/gradingInfo")
    local gradingInfoText = self:FindWndTrans(gradingInfo, "gradingInfoText")
    local gradingData = self:FindWndTrans(gradingInfo, "gradingData")
    local gradingImg = self:FindWndTrans(gradingData, "gradingImg")
    local gradingEff = self:FindWndTrans(gradingData, "gradingEff")

    CS.ShowObject(dateInfo, false)

    local seasonId = gModelCrossGrading:GetSeasonId()
    if not seasonId or seasonId <= 0 then
        seasonId = 1
    end
    local str = string.replace(ccClientText(32409), seasonId)
    self:SetWndText(gradingInfoText, str)
    CS.ShowObject(gradingInfo, true)

    local curScore = gModelCrossGrading:GetScore()
    local rank = gModelCrossGrading:GetRank()
    local ref = gModelCrossGrading:GetCurCrossGradingIntervalRef(curScore, rank)
    if ref then
        CS.ShowObject(gradingData, true)
        self:SetWndEasyImage(gradingImg, ref.icon, function()
            --看是否要特效哦
            --[[
            local iconEffect = ref.iconEffect
            local effKey = "iconEffect"
            self:DestroyWndEffectByKey(effKey)
            if not string.isempty(iconEffect) then
                self:CreateWndEffect(gradingEff,iconEffect,effKey,100,false,false,nil,function(dpTrans)
                    dpTrans.gameObject:SetActive(true)
                    CS.ShowObject(gradingEff,true)
                end)
            end
            ]]--
        end, true)
    end
end

function UISubOuttsPVP:MoveAnimationUpdate()
    if not self._bMove then
        return
    end

    self:RefreshItemTemplateInfoPosAndRotation()
end

--移动时刷新界面数据
function UISubOuttsPVP:_RefreshPageListWhenMove(index)
    self:_SetCircleDataAndItemIndex()

    local changeItemIndex
    if index > 0 then
        changeItemIndex = 7
    else
        changeItemIndex = 1
    end

    --设置页面上的信息
    local changeData = self._controlItemDataList[changeItemIndex]
    local itemIndex = changeData.itemIndex
    local dataIndex = changeData.dataIndex
    self:RefreshItemPage(itemIndex, dataIndex)
end

function UISubOuttsPVP:InitData()
    --打开界面时候要选择第一个-- 跳转的时候 传入page 参数
    self._curDataIndex = self:GetWndArg("page") or 1
    self._curPageSelect = 4
    self._itemPageMax = 7

    self._uiItemList = {}
    self._uiRewardList = {}

    self._itemTemplateList = {}
    self._showFightEffList = {}
    --条目的文本说明
    self._peakStageStr = {
        ccClientText(11800),
        ccClientText(11801),
        ccClientText(11802),
        ccClientText(11803),
        ccClientText(11804),
        ccClientText(11805),
    }
    --红点的获取对应的功能ID  常量和功能id的对应
    self._pageRedList = {
        [UISubOuttsPVP.CROSS_LADDER] = 13300000,
        [UISubOuttsPVP.CROSS_CHAMPION] = 13800000,
        [UISubOuttsPVP.ARENA_RANK] = 13100000,
        [UISubOuttsPVP.ARENA_PEAK] = 13200000,
        [UISubOuttsPVP.CROSS_GRADING] = 13600000,
    }

    --功能id和常量的对应 _pageRedList 的k 和 v 反过来
    self._redPageList = {}
    for k, v in pairs(self._pageRedList) do
        self._redPageList[v] = k
    end

    --定义定时器的key
    self._rankTimerKey = "rankTimerKey"
    self._peakTimerKey = "peakTimerKey"
    self._moveUpdateTime = "_moveUpdateTime"
    self._crossChampionTimerKey = "_crossChampionTimerKey"


    --move 使用到的定义  --tween的定义
    self._autoMoveKey = "_autoMoveKey"
    self._moveTime = 0.15
    self._changeSiblingValue = 0.85

    self._timerTransMap = {}
    self._itemMaskValue = {
        0.8, 0.8, 0.6, 0, 0.6, 0.8, 0.8
    }

    --多语言使用
    self._isUSARegion = gLGameLanguage:IsUSARegion()
    self._isForeign = self._isUSARegion

    --存储节点的复原位置
    local defaultItemTemplatePosList = {}
    local itemTransList = {}
    local childCount = self._itemPageMax
    for i = 1, childCount do
        local item = self["mItemTemplate" .. i]
        if CS.IsValidObject(item) then
            local aniRoot = self:FindWndTrans(item, "AniRoot")
            local topRoot = self:FindWndTrans(item, "TopRoot")

            local data = {
                rootLocalPos = item.localPosition,
                aniRootLocalPos = aniRoot.localPosition,
                aniRootLocalRot = aniRoot.localEulerAngles,
                topRootLocalPos = topRoot.localPosition,
                topContentSize = i == 4 and 1 or 0.8,
                maskValue = self._itemMaskValue[i],
            }

            defaultItemTemplatePosList[i] = data

            itemTransList[i] = item
        end
    end

    self._defaultItemTemplatePosDataList = defaultItemTemplatePosList
    self._itemTransList = itemTransList

    --假设数据项只有5个
    --1, 2, 3, 4, 5, 6, 7 (index，从左到右固定位置)

    --初始
    --1, 2, 3, 4, 5, 6, 7 (itemIndex项循环下标)
    --3, 4, 5, 1, 2, 3, 4 (dataIndex 数据循环下标)

    --右移动一次
    --7, 1, 2, 3, 4, 5, 6 (itemIndex项循环下标)
    --2, 3, 4, 5, 1, 2, 3 (dataIndex 数据循环下标)

    --左移动一次
    --2, 3, 4, 5, 6, 7, 1 (itemIndex项循环下标)
    --4, 5, 1, 2, 3, 4, 5 (dataIndex 数据循环下标)

    self._controlItemDataList = {}--固定格子对应的 item 下标，和数据下标 列表

    --固定位置对应的项的显示顺序
    self._siblingIndexList = {1, 2, 3, 7, 6, 5, 4}

    --排行榜的数据
    self._rankList = {}
    self._rankGameType = {
        [1] = UISubOuttsPVP.CROSS_LADDER,
        [2] = UISubOuttsPVP.CROSS_CHAMPION,
    }

    --请求子类节点的信息
    gModelArena:ShowPersonalPeakAccount()
    gModelArena:OnPlayerArenaReq(true)
    gModelArena:PinnaclePaceStateReq()

    for k, v in ipairs(self._rankGameType) do
        gModelRank:OnGameRankReq(k)
    end

    --这块也是请求信息  --todo 这个是干什么的
    local formation = gModelFormation:GetFormation(LCombatTypeConst.COMBAT_ARENA_DEFEND)
    if not formation then
        gModelFormation:OnGetFormationReq(LCombatTypeConst.COMBAT_ARENA_DEFEND)
    end

    --跳转的请求！？  --todo 这个是干什么的
    self:SetSecretJumpBtn(self.mBtnSecret, 5)
end

function UISubOuttsPVP:UIDragOnEnd(dragKey, eventData)
    local endMoveX = self.mItemRoot.localPosition.x
    local autoChangeDistanceX = self._autoChangeDistanceX

    local moveType
    if endMoveX > 0 and endMoveX >= autoChangeDistanceX then
        moveType = UISubOuttsPVP.MOVE_RIGHT
    elseif endMoveX < 0 and endMoveX <= -autoChangeDistanceX then
        moveType = UISubOuttsPVP.MOVE_LEFT
    else
        moveType = UISubOuttsPVP.MOVE_CENTER
    end

    self:AutoMoveRoot(moveType)
end

--划到中间的处理
function UISubOuttsPVP:OnPageItemCenter(item, itemdata, itempos)
    local moduleRef = itemdata.cfg
    local refId = moduleRef.refId
    self._curSelect = refId

    --todo 划到中间的处理
    --if self._uiPageList then
    --	self._uiPageList:DrawAllItems()
    --end
end

function UISubOuttsPVP:OnTryRefreshRedPoint(...)
    self:RefreshPageRedPoint(...)
end

--region common data部分--------------------------------------------------------------------------------
--刷新模块数据  --从gModelDailyGameEnter模块 直接获取列表数据
function UISubOuttsPVP:RefreshModuleData()
    self._moduleDataList = {}

    for k, v in ipairs(gModelDailyGameEnter:GetEnterList(UISubOuttsPVP.PageType)) do
        local openId = v.functionId
        local refId = v.refId
        local sortIdx = v.sort
        local data = {
            refId = refId,
            cfg = v,
            isOpen = true,
            openMsg = nil,
            sortId = sortIdx,
        }
        if openId then
            local bOpen, msg = gModelFunctionOpen:CheckIsOpened(openId, false)
            data.isOpen = bOpen
            data.openMsg = msg
        end

        table.insert(self._moduleDataList,  data)
    end

    table.sort(self._moduleDataList, function(a, b)
        return a.sortId < b.sortId
    end)

    for k, v in ipairs(self._moduleDataList) do
        v.index = k
    end

    self._moduleMaxNum = #self._moduleDataList
end

--  每一个Item的绘制处理
function UISubOuttsPVP:OnDrawModuleCell(list, item, itemdata, itempos)
    --todo  会存在不穿Itemdata的情况
    if not itemdata then
        return
    end

    local refId = itemdata.refId
    if not refId then
        return
    end

    if refId == UISubOuttsPVP.CROSS_LADDER then
        --self:SetLadderItem(item, itemdata, itempos) --这个被return了
        self:SetCommonPageItem(item, itemdata, itempos)
    elseif refId == UISubOuttsPVP.CROSS_CHAMPION then
        --self:SetChampionItem(item, itemdata, itempos) --这个被return了
        self:SetCommonPageItem(item, itemdata, itempos)
    elseif refId == UISubOuttsPVP.ARENA_RANK then
        self:SetRankItem(item, itemdata, itempos)
    elseif refId == UISubOuttsPVP.ARENA_PEAK then
        self:SetPeakItem(item, itemdata, itempos)
    elseif refId == UISubOuttsPVP.CROSS_GRADING then
        self:SetCrossGradingItem(item, itemdata, itempos)
    elseif refId == UISubOuttsPVP.SIMULATE then
        self:SetSimulateItem(item, itemdata, itempos)
    elseif refId == UISubOuttsPVP.COMING_SOON then
        --todo 尽请期待的功能
        self:SetComingSoonItem(item, itemdata, itempos)
    else
        self:SetCommonPageItem(item, itemdata, itempos)
    end
end

function UISubOuttsPVP:IsInFight(combatCfg)
    local inFight = false
    local combatTypeArr = string.split(combatCfg, ",")
    local combatType = nil
    for i, v in ipairs(combatTypeArr) do
        combatType = tonumber(v)
        inFight = gLFightManager:IsCombatTypeInFight(combatType)
        if inFight then
            break
        end
    end
    return inFight, combatType
end

function UISubOuttsPVP:SetChampionItem(item, itemdata, itempos)
    local bOpen = itemdata.isOpen
    -- 【G公共支持】删除跨服天梯和跨服周冠玩法
    -- local isShowEff = gModelCrossServer:IsChampOpenOrGuessing() and bOpen
    -- self:SetCommonPageItem(item, itemdata, itempos, isShowEff)

    if not bOpen then
        return
    end

    local dateInfo = self:FindWndTrans(item, "AniRoot/dateInfo")
    local dateInfoText = self:FindWndTrans(dateInfo, "dateInfoText")
    local timeInfo = self:FindWndTrans(item, "AniRoot/dateInfo")
    local timeInfoText = self:FindWndTrans(timeInfo, "timeInfoText")
    local rankInfo = self:FindWndTrans(item, "AniRoot/rankInfo")
    local rankInfoText = self:FindWndTrans(rankInfo, "rankInfoText")

    local cfg = itemdata.cfg
    -- local refId = itemdata.refId

    self:SetWndText(dateInfoText, ccLngText(cfg.desc))
    CS.ShowObject(dateInfo, true)

    -- local curTime = GetTimestamp()
    -- local state = gModelCrossServer:GetChampState()
    -- local combatState = gModelCrossServer:GetCombatState()
    local timeLeftStr = ""
    self:TimerStop(self._crossChampionTimerKey)

    -- local isForeign = self._isForeign
    -- local peakStateBefore = state ==ModelCrossServer.PEAK_STATE_BEFORE
    -- if isForeign then
    -- 	--海外巅峰赛，竞猜阶段，算是前端做的赛前
    -- 	peakStateBefore = peakStateBefore or combatState == ModelCrossServer.PEAK_BATTLE_STATE_BETTING
    -- end

    -- local showPealMaxRank = false
    -- if peakStateBefore then
    -- 	showPealMaxRank = true
    -- 	if isForeign then
    -- 		if state ==ModelCrossServer.PEAK_STATE_BEFORE then
    -- 			showPealMaxRank = false
    -- 		elseif combatState == ModelCrossServer.PEAK_BATTLE_STATE_BETTING then
    -- 			--竞猜中
    -- 			local peakStartTime = gModelCrossServer:GetNextStateTime()
    -- 			local timeLeft = peakStartTime
    -- 			if timeLeft<0 then
    -- 				timeLeft= 0
    -- 			end

    -- 			local timeStr = LUtil.FormatTimespanNumber(timeLeft)
    -- 			timeLeftStr =  LUtil.FormatColorStr(timeStr,"lightGreen")
    -- 			timeLeftStr = ccClientText(32407)..timeLeftStr

    -- 			self._timerTransMap[self._crossChampionTimerKey] = {
    -- 				refId 	= refId,
    -- 				time 	= peakStartTime + curTime,
    -- 				transKey = "timeInfoText",
    -- 				title 	= ccClientText(32407),
    -- 				formatFun = LUtil.FormatTimespanNumber,
    -- 			}
    -- 			self:TimerStart(self._crossChampionTimerKey,1,false,-1)
    -- 		end
    -- 	end
    -- if state == ModelCrossServer.PEAK_STATE_STARTED then
    -- 	local isGuessing = combatState == ModelCrossServer.PEAK_BATTLE_STATE_BETTING
    -- 	if isGuessing then
    -- 		--竞猜中
    -- 		timeLeftStr =  ccClientText(32407)
    -- 		timeLeftStr = LUtil.FormatColorStr(timeLeftStr,"lightGreen")
    -- 	else
    -- 		--阶段倒计时
    -- 		local nextTime = gModelCrossServer:GetNextStateTime()
    -- 		local timeLeft = nextTime
    -- 		if timeLeft<0 then
    -- 			timeLeft= 0
    -- 		end
    -- 		local timeStr = LUtil.FormatTimespanNumber(timeLeft)
    -- 		timeLeftStr =  LUtil.FormatColorStr(timeStr,"lightGreen")

    -- 		self._timerTransMap[self._crossChampionTimerKey] = {
    -- 			refId		= refId,
    -- 			transKey 	= "timeInfoText",
    -- 			time		= nextTime + curTime,
    -- 			title 		= ccClientText(32406),
    -- 			formatFun 	= LUtil.FormatTimespanNumber,
    -- 		}

    -- 		self:TimerStart(self._crossChampionTimerKey,1,false,-1)
    -- 	end

    -- 	timeLeftStr = ccClientText(32406)..timeLeftStr
    -- end

    local isShowTimeLeft = not string.isempty(timeLeftStr)
    CS.ShowObject(timeInfo, isShowTimeLeft)
    if isShowTimeLeft then
        self:SetWndText(timeInfoText, timeLeftStr)
    end

    local rankStr
    local rankData = self._rankList[UISubOuttsPVP.CROSS_CHAMPION]
    if rankData then
        -- if showPealMaxRank then
        -- 	--历史最高
        -- 	local pealMaxRank = rankData.historyRank
        -- 	if pealMaxRank <= 0 then
        -- 		rankStr = ccClientText(11876)
        -- 	else
        -- 		rankStr = tostring(pealMaxRank)
        -- 	end

        -- 	rankStr = LUtil.FormatColorStr(rankStr,"yellow_2")
        -- 	rankStr = ccClientText(11814)..rankStr
        -- else
        --排行
        local peakRank = rankData.currentRank
        if peakRank <= 0 then
            rankStr = ccClientText(11876)
        else
            rankStr = tostring(peakRank)
            rankStr = string.replace(ccClientText(32404), rankStr)
        end
    end
    -- end
    local isShowRank = not string.isempty(rankStr)
    if isShowRank then
        self:SetWndText(rankInfoText, rankStr)
    end
    CS.ShowObject(rankInfo, isShowRank)
end

--item元素的点击方法
function UISubOuttsPVP:OnClickModuleCell(moduleRef, itemPos)
    local curSelectData = self._moduleDataList[self._curDataIndex]
    if not curSelectData then
        return
    end

    local curSelectRefId = curSelectData.cfg.refId
    local refId = moduleRef.refId
    if refId ~= curSelectRefId then
        return
    end
    if self._curPageSelect ~= itemPos then
        return
    end

    local openId = moduleRef.functionId
    local bOpen = gModelFunctionOpen:CheckIsOpened(openId, true)
    if not bOpen then
        return
    end

    gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_PLAY, refId)

    local combatTypeCfg = moduleRef.combatType
    local inFight, combatType = self:IsInFight(combatTypeCfg)
    if inFight then
        gLFightManager:PrepareGoToBattle(combatType, {})
        return
    end
    gModelFunctionOpen:Jump(openId,"UIOutts")
    --if refId == UISubOuttsPVP.CROSS_LADDER then
    --    GF.OpenWndBottom("WndCrossServerLadder")
    --elseif refId == UISubOuttsPVP.CROSS_CHAMPION then
    --    GF.OpenWndBottom("WndCrossServerChampion", { pageIndex = -1, groupIndex = 1 })
    --elseif refId == UISubOuttsPVP.ARENA_RANK then
    --    GF.OpenWndBottom("UIringRk")
    --elseif refId == UISubOuttsPVP.ARENA_PEAK then
    --    GF.OpenWndBottom("UIringPk")
    --elseif refId == UISubOuttsPVP.CROSS_GRADING then
    --    GF.OpenWndBottom("UIKuafuGradMin", { isFromJump = true })
    --elseif refId == UISubOuttsPVP.SIMULATE then
    --    GF.OpenWnd("UISuMin")
    --else
    --    GF.ShowMessage(ccClientText(18219))
    --end
end

function UISubOuttsPVP:RefreshItemTemplateInfoPosAndRotation(isRefresh)
    local oldPos = self._oldItemRootPos
    if not oldPos then
        oldPos = self.mItemRoot.localPosition.x
        self._oldItemRootPos = oldPos
    end

    local newPos = self.mItemRoot.localPosition.x
    local moveDirection = newPos - oldPos
    local moveType
    if moveDirection == 0 then
        moveType = UISubOuttsPVP.MOVE_CENTER
    elseif moveDirection > 0 then
        moveType = UISubOuttsPVP.MOVE_RIGHT
    else
        moveType = UISubOuttsPVP.MOVE_LEFT
    end

    local moveTemplateValue = math.abs(newPos / self._changeDistanceX)
    local itemChangePos, itemChangeRot, maskValue, topChangePos, topChangeSize
    local curData, nextChangeData
    local getChangeDataKey
    local itemIndex
    local effKey
    local changeSiblingValue = self._changeSiblingValue
    local needAsFirstSibling, needItemChangeRot, needMaskChange, needTopSizeChange, needSelectChange = false, false, false, false, false
    for k, v in ipairs(self._controlItemDataList) do
        if moveType == UISubOuttsPVP.MOVE_RIGHT then
            if moveTemplateValue > changeSiblingValue and k == 3 then
                needAsFirstSibling = true
            elseif moveTemplateValue < changeSiblingValue and k == 4 then
                needAsFirstSibling = true
            else
                needAsFirstSibling = false
            end
            getChangeDataKey = k + 1
            if getChangeDataKey > self._itemPageMax then getChangeDataKey = 1 end
        elseif moveType == UISubOuttsPVP.MOVE_LEFT then
            if moveTemplateValue > changeSiblingValue and k == 5 then
                needAsFirstSibling = true
            elseif moveTemplateValue < changeSiblingValue and k == 4 then
                needAsFirstSibling = true
            else
                needAsFirstSibling = false
            end

            getChangeDataKey = k - 1
            if getChangeDataKey <= 0 then getChangeDataKey = self._itemPageMax end
        else
            needAsFirstSibling = k == 4
            getChangeDataKey = k
        end

        curData = self._defaultItemTemplatePosDataList[k]
        nextChangeData = self._defaultItemTemplatePosDataList[getChangeDataKey]

        itemIndex = v.itemIndex
        local itemTemplateInfo = self._itemTemplateList[itemIndex]

        --如果没有对应的item则return
        if nil == itemTemplateInfo then
            return
        end

        --位置和旋转
        local aniRoot = itemTemplateInfo.aniRoot
        itemChangePos = (nextChangeData.aniRootLocalPos - curData.aniRootLocalPos) * moveTemplateValue + curData.aniRootLocalPos
        itemChangeRot = (nextChangeData.aniRootLocalRot - curData.aniRootLocalRot)
        needItemChangeRot = itemChangeRot ~= 0 or isRefresh
        if itemChangeRot then
            itemChangeRot = itemChangeRot * moveTemplateValue + curData.aniRootLocalRot
        end
        if CS.IsValidObject(aniRoot) then
            aniRoot.localPosition = itemChangePos

            if itemChangeRot then
                aniRoot.localRotation = Quaternion.Euler(0, itemChangeRot.y, 0)
            end
        end

        --遮罩mask
        maskValue = nextChangeData.maskValue - curData.maskValue
        needMaskChange = maskValue ~= 0 or isRefresh
        if needMaskChange then
            maskValue = maskValue * moveTemplateValue + curData.maskValue
        end
        if needMaskChange then
            local maskImg = itemTemplateInfo.maskImg
            if CS.IsValidObject(maskImg) then
                maskImg.color = Color.New(1, 1, 1, maskValue)
            end
        end

        --顶部的小图标位置
        topChangePos = (nextChangeData.topRootLocalPos - curData.topRootLocalPos) * moveTemplateValue + curData.topRootLocalPos
        local topTrans = itemTemplateInfo.topTrans
        if CS.IsValidObject(topTrans) then
            topTrans.localPosition = topChangePos
        end

        --顶部小图片缩放
        topChangeSize = nextChangeData.topContentSize - curData.topContentSize
        needTopSizeChange = topChangeSize ~= 0 or isRefresh
        if needTopSizeChange then
            topChangeSize = topChangeSize * moveTemplateValue + curData.topContentSize
        end
        local topContent = itemTemplateInfo.topContent
        if needTopSizeChange then
            if CS.IsValidObject(topContent) then
                topContent.localScale = Vector3.New(topChangeSize, topChangeSize, topChangeSize)
            end
        end


        --顶部小图片中间选择
        local topSelect = itemTemplateInfo.topSelect
        needSelectChange = topSelect.gameObject.activeSelf ~= needAsFirstSibling or isRefresh
        if CS.IsValidObject(topSelect) then
            if needSelectChange then
                CS.ShowObject(topSelect, needAsFirstSibling)
            end

            --选中特效
            if needAsFirstSibling then
                local InstanceID = topTrans:GetInstanceID()
                effKey = self._topSelectEff .. InstanceID
                self:CreateWndEffect(topSelect, self._topSelectEff, effKey, 100, false, false)
            end
        end

        --页正战斗特效
        local selectEff = itemTemplateInfo.selectEff
        if CS.IsValidObject(selectEff) then
            local showEff = false
            local dataIndex = v.dataIndex
            local moduleData = self._moduleDataList[dataIndex]
            if moduleData then
                local refId = moduleData.refId
                showEff = needAsFirstSibling and self._showFightEffList[refId]
            end

            if showEff then
                local InstanceID2 = selectEff:GetInstanceID()
                effKey = self._pageSelectEff .. InstanceID2
                self:CreateWndEffect(selectEff, self._pageSelectEff, effKey, 100, false, false)
            end
            CS.ShowObject(selectEff, showEff)
        end

        if needAsFirstSibling then
            --表示是中间页，要置顶
            local itemTrans = itemTemplateInfo.itemTemplate
            if CS.IsValidObject(itemTrans) then
                if itemTrans:GetSiblingIndex() ~= 6 then
                    itemTrans.transform:SetAsLastSibling()
                end
            end
        end
    end
end
--endregion --------------------------------------------------------------------------------------

--region Server的回调 --------------------------------------------------------------------------------
function UISubOuttsPVP:OnGameRankResp(pb)
    local gameType = pb.GameType
    local data = {
        currentRank = pb.currentRank,
        historyRank = pb.historyRank,
    }

    local rankGameType = self._rankGameType[gameType]
    if not rankGameType then
        if LOG_INFO_ENABLED then
            LogError("self._rankGameType[gameType] is not find, gameType = " .. (gameType or "nil"))
        end
        return
    end

    self._rankList[rankGameType] = data
    self:RefreshPageItem(rankGameType)
end


function UISubOuttsPVP:_RefreshCurSelectPageWhenMove(index)
    local curPageSelect = self._curPageSelect + index

    if curPageSelect < 1 then
        --当抵达左边界 的时候  下一个-1 则应该抵达右边界
        curPageSelect = self._itemPageMax
    elseif curPageSelect > self._itemPageMax then
        --当抵达右边界 的时候  下一个+1 则应该抵达左边界
        curPageSelect = 1
    end
    self._curPageSelect = curPageSelect

    local dataIndex = self._curDataIndex + index
    if dataIndex < 1 then
        dataIndex = self._moduleMaxNum
    elseif dataIndex > self._moduleMaxNum then
        dataIndex = 1
    end
    self._curDataIndex = dataIndex
end

function UISubOuttsPVP:InitMsgEvent()
    self:WndEventRecv(EventNames.ON_PEAK_STATE_CHANGE, function()
        self:RefreshPageItem(UISubOuttsPVP.ARENA_PEAK)
    end)
    self:WndEventRecv(EventNames.ON_CROSS_SERVER_CHAMPION_STATE, function()
        self:RefreshPageItem(UISubOuttsPVP.CROSS_CHAMPION)
    end)
    self:WndEventRecv(EventNames.ON_CROSS_SERVER_LADDER_INFO, function()
        self:RefreshPageItem(UISubOuttsPVP.CROSS_LADDER)
    end)


    self:WndNetMsgRecv(LProtoIds.PlayerArenaResp, function(...)
        self:RefreshPageItem(UISubOuttsPVP.ARENA_RANK)
    end)
    self:WndNetMsgRecv(LProtoIds.GetFormationResp, function(pb)
        if pb.type == LCombatTypeConst.COMBAT_ARENA_DEFEND then
            self:RefreshPageItem(UISubOuttsPVP.ARENA_RANK)
        end
    end)
    self:WndNetMsgRecv(LProtoIds.GameRankResp, function(...)
        self:OnGameRankResp(...)
    end)



    -- if 3 == gModelCrossServer:GetServerMatchTag() then
    -- 	gModelCrossServer:LadderInfoReq()
    -- end
end

function UISubOuttsPVP:SetComingSoonItem(item, itemdata, itempos)
    self:SetCommonPageItem(item, itemdata, itempos)

    local lockIcon = self:FindWndTrans(item, "AniRoot/lock/Icon")
    CS.ShowObject(lockIcon, false)
end

--刷新列表部分
function UISubOuttsPVP:RefreshPageItem(itemType)
    local dataIndex
    for k, v in ipairs(self._controlItemDataList) do
        dataIndex = v.dataIndex
        if dataIndex then
            local moduleData = self._moduleDataList[dataIndex]
            if moduleData and moduleData.refId == itemType then
                local itemIndex = v.itemIndex
                if itemIndex then
                    local itemTemplate = self:GetItemTemplate(itemIndex)
                    if CS.IsValidObject(itemTemplate) then
                        self:OnDrawModuleCell(nil, itemTemplate, moduleData, itemIndex)
                    end
                end
            end
        end
    end
end

--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UISubOuttsPVP
