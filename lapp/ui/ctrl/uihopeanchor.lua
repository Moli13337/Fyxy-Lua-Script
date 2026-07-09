---
--- Created by LCM.
--- DateTime: 2024/3/23 20:24:56
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeAnchor:LWnd
local UIHopeAnchor = LxWndClass("UIHopeAnchor", LWnd)
local Tweening = DG.Tweening

local typeRectTransform = typeof(UnityEngine.RectTransform)

--- 0 = 中间
--- 1 = 左边
--- 2 = 右边
UIHopeAnchor.INIT_RUN_DIRECTION_CENTER = 0
UIHopeAnchor.INIT_RUN_DIRECTION_LEFT = 1
UIHopeAnchor.INIT_RUN_DIRECTION_RIGHT = 2

UIHopeAnchor.TYPE_MOVE_STOP = 0           -- 起点
UIHopeAnchor.TYPE_MOVE_DOWN = 1           -- 往下移动
UIHopeAnchor.TYPE_MOVE_UP = 2             -- 往上移动

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeAnchor:UIHopeAnchor()
    self._waitCountDownTimerKey = "waitCountDownTimerKey"           -- 等待3秒后开始
    self._anchorRunTimerKey = "anchorRunTimerKey"                   -- 船锚下移时间
    self._gameRunTimerKey = "gameRunTimerKey"                       -- 船锚下移时间
    self._createQPTimerKey = "createQPTimerKey"                     -- 创建气泡时间
    self._checkQPTimerKey = "checkQPTimerKey"                       -- 检测气泡位置是否被勾住

    self._autoShipRunAniKey = "autoShipRunAniKey"                   -- 船移动 DOTween动画
    self._anchorMoveAniKey = "anchorMoveAniKey"                     -- 钩子移动 DOTween动画
    self._anchorRetMoveAniKey = "anchorRetMoveAniKey"               -- 钩子回去移动 DOTween动画
    self._anchorGetRetMoveAniKey = "anchorGetRetMoveAniKey"         -- 钩子勾到奖励回去移动 DOTween动画

    self._countDownTime = 3                                         -- 倒计时

    self._getNum = 0
    self._anchorStatus = UIHopeAnchor.TYPE_MOVE_STOP
    self._runAnchorStatus = false

    self._isGetQIPAO = false

end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeAnchor:OnWndClose()
    if self._objPool then
        self._objPool:Destroy()
        self._objPool = nil
    end
    self:ClearTimerList()
    GF.CloseWndByName("UIOrdinSowMsg")

    FireEvent(EventNames.ON_FDT_EVENT_CLOSEUI)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeAnchor:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeAnchor:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
    GF.OpenWnd("UIOrdinSowMsg")
    CS.ShowObject(self.mCloseBtn,false)

    --self:CreateWndEffect(self.mEffRoot,"fx_mhailang","fx_mhailang",100)

	self:InitUIObjPool()
	self:InitTransInfo()
	self:InitEvent()
	self:InitMsg()
	self:InitData()

    self:InitTimeList()

    self:CreateTimer(self._waitCountDownTimerKey,1,-1)
end

function UIHopeAnchor:CreateQPTransFunc()
    local itemNew = self._objPool:GetObj()
    return itemNew.transform
end

function UIHopeAnchor:GetRandomIndex(min,max)
    return math.random(min,max)
end

function UIHopeAnchor:ClearTrans(key)
    self:TweenSeqKill(key)
    if self._qpTransList then
        self._qpTransList[key] = nil
    end
    local timer = self._timerList[key]
    if timer then
        LxTimer.DelayTimeStop(timer)
    end
    self._timerList[key] = nil
end

function UIHopeAnchor:InitTransInfo()
    local moveLeftEndRoot = self.mMoveLeftEndRoot
    local moveRightEndRoot = self.mMoveRightEndRoot
    local leftPos = moveLeftEndRoot.localPosition
    local rightPos = moveRightEndRoot.localPosition
    self._leftPosX = leftPos.x                  -- 船能移动到最左边的值
    self._rightPosX = rightPos.x                -- 船能移动到最右边的值
    local ship = gModelFastDreamTrip:GetConfigByKey("ship")
    local allX = math.abs(self._leftPosX) + math.abs(self._rightPosX)
    --- 平均值
    self._averagePos = allX / ship

    --- 初始化钩子的位置
    self._initCordImgPosY = self.mCordImg.position.y

    --- 结束点的位置
    self._moveEndPosY = self.mAnchorEndPos.position.y

    local width,height = 640,1136
    local rectTrans = self.mShowItemArea:GetComponent(typeRectTransform)
    if rectTrans then
        local rect = rectTrans.rect
        width = rect.width
        height = rect.height
    end
    self._width = width
    self._height = height

    local itemWidth,itemHeight = 94,94
    local templateRectTrans = self.mQiPaoTemplate:GetComponent(typeRectTransform)
    if templateRectTrans then
        local rect = templateRectTrans.rect
        itemWidth = rect.width
        itemHeight = rect.height
    end
    self._itemWidth = itemWidth
    self._itemHeight = itemHeight
end

function UIHopeAnchor:SendMsg()
    local strList = {}
    local getRewardList = self._getRewardList or {}
    for rewardId,num in pairs(getRewardList) do
        local str = rewardId .. "=" .. num
        table.insert(strList,str)
    end
    local rewardStr = table.concat(strList, ';')
    if LOG_INFO_ENABLED then
        printInfoNR("勾到的奖励列表 rewardStr = " ..rewardStr)
    end
    gModelFastDreamTrip:OnDreamTripStartEventReq(self._eventId,{rewardStr})
end

function UIHopeAnchor:RunCreateQiPao()
    local createQPNum = self:GetRandomNum(self._refreshShipPathList)
    for i = 1,createQPNum do
        self:SetQPFunc()
    end

    --- 道具刷新时间
    local randomNum = self:GetRandomNum(self._refreshShipTimeList)
    self:CreateTimer(self._createQPTimerKey,randomNum,1)
end

function UIHopeAnchor:MoveAnchorAniFunc()
    local seqKey = self._anchorMoveAniKey
    local seqTween = self:TweenSeqFind(seqKey)
    if seqTween then
        self:TweenSeqKill(seqKey)
        seqTween = nil
    end
    self:CreateTimer(self._checkQPTimerKey,0,-1)
    seqTween = self:TweenSeqCreate(seqKey, function(seq)
        local moveEnd = self.mCordImg:DOMoveY(self._moveEndPosY,self._shipFall)
        seq:Append(moveEnd)
        --seq:AppendInterval(2)

        local moveStart = self.mCordImg:DOMoveY(self._initCordImgPosY,self._shipUp)
        seq:Append(moveStart)
        seq:AppendInterval(0.5)
        return seq
    end)
    seqTween:OnComplete(function()
        if not self._isGetQIPAO then
            --- 没有勾到
            gModelFastDreamTrip:PlayDreamTripSound(305)
        end

        self._runAnchorStatus = false
        self:TimerStop(self._checkQPTimerKey)
        self:TweenSeqKill(seqKey)
        self:ClearHookQPList()
        self:OnAutoRunShipTweenFunc()
    end)
    seqTween:PlayForward()
end

function UIHopeAnchor:OnRunGameTimer()
    self._changeParyTime = self._changeParyTime - 1
    if self._changeParyTime < 1 then
        self:SendMsg()
        self:TimerStop(self._gameRunTimerKey)
    else
        self:InitTimeList()
    end
end

function UIHopeAnchor:InitTransPos(trans)
    local moveX = - self._width / 2 - self._itemWidth
    local moveY = self:GetRandomY()
    trans.anchoredPosition = Vector3(moveX,moveY,0)
end

function UIHopeAnchor:GetRewardIndex()
    local allWeight = self._allWeight
    local ramdonNum = self:GetRandomIndex(1,allWeight)
    local weightList = self._weightList
    for i,v in ipairs(weightList) do
        if v.minW <= ramdonNum and v.maxW >= ramdonNum then
            return i
        end
    end
    return 1
end
------------------------- List -------------------------
function UIHopeAnchor:GetNeedAddItemList()
end

function UIHopeAnchor:InitData()

    ---@type StructDreamTripEventInfo
    local eventInfo = self:GetWndArg("eventInfo")
    self._eventInfo = eventInfo

    self._eventId = eventInfo.eventId
    self._index = eventInfo.index
    self._eventRefId = eventInfo.eventRefId
    self._eventType = eventInfo.eventType


    local gameParams = self:GetWndArg("gameParams")
    self._gameParams = gameParams


    self._initDire = UIHopeAnchor.INIT_RUN_DIRECTION_CENTER

    self._initShowDire = UIHopeAnchor.INIT_RUN_DIRECTION_CENTER

    --- 存放气泡trans列表
    self._qpTransList = {}

    --- 存放被勾住的气泡trans列表
    self._hookQpTransList = {}

    --- 时间列表
    self._timerList = {}

    self._getRewardList = {}

    self:InitConfigData()
end

function UIHopeAnchor:InitNeedAddItemList()
    local list = self:GetNeedAddItemList()
    local uiNeedAddItemList = self._uiNeedAddItemList
    if uiNeedAddItemList then
        uiNeedAddItemList:RefreshList(list)
    else
        uiNeedAddItemList = self:GetUIScroll("uiNeedAddItemList")
        self._uiNeedAddItemList = uiNeedAddItemList
        uiNeedAddItemList:Create(self.mNeedAddItemList,list,function(...) self:OnDrawNeedAddItemCell(...) end)
    end
end

function UIHopeAnchor:GetRandomY()
    local minY = self._itemHeight
    local maxY = self._height - minY
    local randomY = self:GetRandomIndex(minY,maxY)
    return -randomY
end

function UIHopeAnchor:OnCheckQPTimer()
    local qpTransList = self._qpTransList or {}
    local hookPos = self.mHookImg.position
    local hookPosX = hookPos.x
    local hookPosY = hookPos.y

    local hookWorldCorners = self.mHookImg:GetWorldCorners()
    local hookLeft = hookWorldCorners[0]
    local hookRight = hookWorldCorners[2]
    local hookLeftX = hookLeft.x
    local hookRightX = hookRight.x
    local hookTopY = hookLeft.y
    local hookBotY = hookRight.y

    local checkFunc = function(trans)
        local worldCorners = trans:GetWorldCorners()
        local left = worldCorners[0]
        local right = worldCorners[2]

        local transMinX = left.x
        local transMaxX = right.x
        local transMinY = left.y
        local transMaxY = right.y

--[[        if (transMinX <= hookLeftX and transMinX >= hookRightX or transMaxX <= hookLeftX and transMaxX >= hookRightX) and
                (transMinY <= hookTopY and transMinY >= hookBotY or transMaxY <= hookTopY and transMaxY >= hookBotY) then
            return true
        end]]

        if (transMinX <= hookPosX and transMaxX >= hookPosX) and (transMinY <= hookPosY and transMaxY >= hookPosY) then
            return true
        end
    end

    for key,transInfo in pairs(qpTransList) do
        if checkFunc(transInfo.trans) then
            ---- 一次只能勾一个

            self:TimerStop(self._checkQPTimerKey)
            self:OnHookItemFunc(key,transInfo)
            return
        end
    end
end

function UIHopeAnchor:InitUIObjPool()
    local objPool = UIObjPool:New()
    objPool:Create(self.mShowItemArea,self.mQiPaoTemplate)
    self._objPool = objPool
end

function UIHopeAnchor:InitTimeList()
    --- 使用程序字
    local time = self._changeParyTime
    self:SetWndText(self.mTimeStr,time)

--[[    local list = self:GetTimeList()
    local uiTimeList = self._uiTimeList
    if uiTimeList then
        uiTimeList:RefreshList(list)
    else
        uiTimeList = self:GetUIScroll("uiTimeList")
        self._uiTimeList = uiTimeList
        uiTimeList:Create(self.mTimeList,list,function(...) self:OnDrawTimeCell(...) end)
    end]]
end

function UIHopeAnchor:GetQPFunc(key,transInfo)
    local qpTransList = self._qpTransList or {}
    qpTransList[key] = nil
    local trans = transInfo.trans
    if trans then
        trans:SetParent(self.mHookImg)
    end
    if not self._hookQpTransList then
        self._hookQpTransList = {}
    end
    self._hookQpTransList[key] = transInfo
    self:ClearTrans(key)

    self:TweenSeqKill(self._anchorMoveAniKey)

    local seqKey = self._anchorGetRetMoveAniKey
    local seqTween = self:TweenSeqFind(seqKey)
    if seqTween then
        self:TweenSeqKill(seqKey)
        seqTween = nil
    end
    seqTween = self:TweenSeqCreate(seqKey, function(seq)
        local pos = self.mCordImg.position
        local y = pos.y
        local speed = (math.abs(y) + math.abs(self._initCordImgPosY)) / self._shipUpHeight
        local moveStart = self.mCordImg:DOMoveY(self._initCordImgPosY,speed)
        seq:Append(moveStart)
        seq:AppendInterval(0.5)
        return seq
    end)
    seqTween:OnComplete(function()
        self._runAnchorStatus = false
        self:TweenSeqKill(seqKey)
        self:ClearHookQPList()
        self:OnAutoRunShipTweenFunc()
    end)
    seqTween:PlayForward()
end

function UIHopeAnchor:OnDrawNeedAddItemCell(list,item,itemdata,itempos)

    local MaskBgTrans = self:FindWndTrans(item,"MaskBg")
    local IconDivTrans = self:FindWndTrans(item,"IconDiv")
    local IconTrans = self:FindWndTrans(item,"Icon")
    local Interval1Trans = self:FindWndTrans(item,"Interval1")
    local NumTrans = self:FindWndTrans(item,"Num")
    local Interval2Trans = self:FindWndTrans(item,"Interval2")
end

function UIHopeAnchor:OnRunAnchorFunc()

end

function UIHopeAnchor:OnAutoRunShipTweenFunc()
    local seqKey = self._autoShipRunAniKey
    local seqTween = self:TweenSeqFind(seqKey)
    if seqTween then
        seqTween:Kill(true)
        seqTween = nil
    end
    seqTween = self:TweenSeqCreate(seqKey, function(seq)
        local trans = self.mShipRoot
        local curPos = trans.localPosition
        local curPosX = curPos.x
        local initDire = self._initDire
        if curPosX == 0 then
            initDire = UIHopeAnchor.INIT_RUN_DIRECTION_CENTER
        end
        local showShipLeft1,showShipLeft2,showShipLeft3 = false,false,false
        local showShipRight1,showShipRight2,showShipRight3 = false,false,false
        local posX1,posX2
        local dire1,dire2,dire3
        if initDire == UIHopeAnchor.INIT_RUN_DIRECTION_CENTER then
            posX1,posX2 = self._leftPosX,self._rightPosX
            showShipLeft1 = true
            showShipRight2 = true
            showShipLeft3 = true
            dire1 = UIHopeAnchor.INIT_RUN_DIRECTION_RIGHT
            dire2 = UIHopeAnchor.INIT_RUN_DIRECTION_LEFT
            dire3 = UIHopeAnchor.INIT_RUN_DIRECTION_LEFT
        elseif initDire == UIHopeAnchor.INIT_RUN_DIRECTION_LEFT then
            posX1,posX2 = self._leftPosX,self._rightPosX
            showShipLeft1 = true
            showShipRight2 = true
            showShipLeft3 = true
            dire1 = UIHopeAnchor.INIT_RUN_DIRECTION_RIGHT
            dire2 = UIHopeAnchor.INIT_RUN_DIRECTION_LEFT
            dire3 = UIHopeAnchor.INIT_RUN_DIRECTION_LEFT
        elseif initDire == UIHopeAnchor.INIT_RUN_DIRECTION_RIGHT then
            posX1,posX2 = self._rightPosX,self._leftPosX
            showShipRight1 = true
            showShipLeft2 = true
            showShipRight3 = true
            dire1 = UIHopeAnchor.INIT_RUN_DIRECTION_LEFT
            dire2 = UIHopeAnchor.INIT_RUN_DIRECTION_RIGHT
            dire3 = UIHopeAnchor.INIT_RUN_DIRECTION_RIGHT
        end
        local pos1 = Vector3(posX1,curPos.y,curPos.z)
        local pos2 = Vector3(posX2,curPos.y,curPos.z)
        local pos3 = Vector3(curPosX,curPos.y,curPos.z)

        local time1 = math.abs(curPosX - posX1) / self._averagePos
        local time2 = math.abs(posX1 - posX2) / self._averagePos
        local time3 = math.abs(posX2 - curPosX) / self._averagePos

        seq:AppendCallback(function()
            CS.ShowObject(self.mShipLeft,showShipLeft1)
            CS.ShowObject(self.mShipRight,showShipRight1)
        end)
        local move1 = self.mShipRoot:DOLocalMove(pos1, time1)
        seq:Append(move1)
        seq:AppendCallback(function()
            self._initDire = dire1
        end)

        seq:AppendCallback(function()
            CS.ShowObject(self.mShipLeft,showShipLeft2)
            CS.ShowObject(self.mShipRight,showShipRight2)
        end)
        local move2 = self.mShipRoot:DOLocalMove(pos2, time2)
        seq:Append(move2)
        seq:AppendCallback(function()
            self._initDire = dire2
        end)

        seq:AppendCallback(function()
            CS.ShowObject(self.mShipLeft,showShipLeft3)
            CS.ShowObject(self.mShipRight,showShipRight3)
        end)
        local move3 = self.mShipRoot:DOLocalMove(pos3, time3)
        seq:Append(move3)
        seq:AppendCallback(function()
            self._initDire = dire3
        end)

        return seq
    end)
    seqTween:SetLoops(-1)
    seqTween:OnComplete(function()
        self:TweenSeqKill(seqKey)
    end)
    seqTween:PlayForward()
end

function UIHopeAnchor:CreateTimer(key,time,loopCnt)
    self:TimerStop(key)
    self:TimerStart(key,time,false,loopCnt)
end

function UIHopeAnchor:OnClickOnHookBtnFunc()
    if self._runAnchorStatus then return end

    local seqTween = self:TweenSeqFind(self._autoShipRunAniKey)
    if seqTween then
        self:TweenSeqKill(self._autoShipRunAniKey)
        seqTween = nil
    end

    self._isGetQIPAO = false
    self._runAnchorStatus = true
    self:MoveAnchorAniFunc()
end

function UIHopeAnchor:DelayTimer(trans,rewardInfo)
    local timeList = self._refreshShipSpeedList
    local time = self:GetRandomNum(timeList)
    local key = trans:GetInstanceID()

    if not self._qpTransList then
        self._qpTransList = {}
    end
    self._qpTransList[key] = {
        trans = trans,
        rewardInfo = rewardInfo,
    }

    CS.ShowObject(trans,true)
    self:TweenItem(trans,time)
    local timer = nil
    timer = LxTimer.DelayTimeCall(function ()
        if not self:IsWndValid() then return end
        self:ClearTrans(key)
        --- 直接回收
        self._objPool:ReturnObj(trans)
    end,time,false)
    self._timerList[key] = timer
end

function UIHopeAnchor:InitEvent()
    self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mOnHookBtn,function() self:OnClickOnHookBtnFunc() end)
end

--[[function UIHopeAnchor:OnDreamTripStartEventResp(pb)
    if pb.eventId ~= self._eventId then return end
    local endInfo = pb.endInfo
    if not endInfo then return end
    if endInfo.state == StructDreamTripGrid.FINISH then
        self:WndClose()
    end
end]]

function UIHopeAnchor:InitMsg()
    self:WndEventRecv(EventNames.ON_FDT_EVENT_FINISH,function(...) self:OnFDTEventFinish(...) end)
    self:WndEventRecv(EventNames.NET_ERROR_CODE,function(code,error, argList) self:WndClose() end)
end

function UIHopeAnchor:ClearHookQPList()
    local hookQpTransList = self._hookQpTransList
    for key,transInfo in pairs(hookQpTransList) do
        local trans = transInfo.trans
        self:SaveOnHookItemInfo(transInfo.rewardInfo)
        self._objPool:ReturnObj(trans)
        CS.ShowObject(trans,false)
    end
    self._hookQpTransList = {}
end

function UIHopeAnchor:GetShipStone(key,transInfo)
    self:TweenSeqKill(self._anchorMoveAniKey)
    self:TimerStop(self._checkQPTimerKey)

    local seqKey = self._anchorRetMoveAniKey
    local seqTween = self:TweenSeqFind(seqKey)
    if seqTween then
        self:TweenSeqKill(seqKey)
        seqTween = nil
    end
    seqTween = self:TweenSeqCreate(seqKey, function(seq)
        --self._shipResilienceHeight
        local pos = self.mCordImg.position
        local y = pos.y
        local speed = (math.abs(y) + math.abs(self._initCordImgPosY)) / self._shipResilienceHeight
        local moveStart = self.mCordImg:DOMoveY(self._initCordImgPosY,speed)
        seq:Append(moveStart)
        seq:AppendInterval(0.5)
        return seq
    end)
    seqTween:OnComplete(function()
        self._runAnchorStatus = false

        --- 勾到石头
        gModelFastDreamTrip:PlayDreamTripSound(305)
        self:TweenSeqKill(seqKey)
        self:ClearHookQPList()
        self:OnAutoRunShipTweenFunc()
    end)
    seqTween:PlayForward()
end

function UIHopeAnchor:OnRunCountDownTimer()
    local countDownTime = self._countDownTime
    self:SetWndText(self.mCountDownTxt,countDownTime)
--[[    local img = self._countDownImgList[countDownTime]
    self:SetWndEasyImage(self.mCountDownImg,img,function()
        CS.ShowObject(self.mCountDownImg,true)
    end)]]
    self._countDownTime = countDownTime - 1
    if self._countDownTime < 0 then
        CS.ShowObject(self.mCountDownBg,false)
        self:OnRunCreateQiPaoTimer()
        self:TimerStop(self._waitCountDownTimerKey)
        self:CreateTimer(self._gameRunTimerKey,1,-1)
        self:OnAutoRunShipTweenFunc()
    end
end

function UIHopeAnchor:OnRunCreateQiPaoTimer()
    self:RunCreateQiPao()
end

function UIHopeAnchor:OnTimer(key)
    if key == self._waitCountDownTimerKey then
        self:OnRunCountDownTimer()
    elseif key == self._anchorRunTimerKey then
        self:OnRunAnchorFunc()
    elseif key == self._gameRunTimerKey then
        self:OnRunGameTimer()
    elseif key == self._createQPTimerKey then
        self:RunCreateQiPao()
    elseif key == self._checkQPTimerKey then
        self:OnCheckQPTimer()
    end
end

function UIHopeAnchor:SetQPFunc()
    local trans = self:CreateQPTransFunc()
    if not trans then return end

    trans:SetParent(self.mShowItemArea.transform,false)

    self:InitTransPos(trans)

    local rewardIndex = self:GetRewardIndex()
    local rewardList = self._rewardIdList
    local rewardInfo = rewardList[rewardIndex]
    if not rewardInfo then return end

    local showItemAreaTrans = self.mShowItemArea
    trans:SetParent(showItemAreaTrans.transform, false)

    local itemId = rewardInfo.itemId
    local showShowBg = itemId ~= self._shipStoneId
    local BgTrans = self:FindWndTrans(trans,"Bg")
    CS.ShowObject(BgTrans,showShowBg)

    local IconTrans = self:FindWndTrans(trans,"Icon")
    local icon = gModelItem:GetItemIconByRefId(itemId)
    self:SetWndEasyImage(IconTrans,icon,function()
        CS.ShowObject(IconTrans,true)
    end,true)

    local NumTrans = self:FindWndTrans(trans,"Num")
    self:SetWndText(NumTrans,rewardInfo.itemNum)
    CS.ShowObject(NumTrans,showShowBg)

    local BtnTrans = self:FindWndTrans(trans,"Btn")
    self:SetWndClick(BtnTrans,function()

    end)

    self:DelayTimer(trans,rewardInfo)

    return true
end

function UIHopeAnchor:OnHookItemFunc(key,transInfo)
    local itemId = transInfo.rewardInfo.itemId
    if itemId == self._shipStoneId then
        self:GetShipStone(key,transInfo)
    else
        self:GetQPFunc(key,transInfo)
        self._isGetQIPAO = true
        gModelFastDreamTrip:PlayDreamTripSound(304)
    end
end

function UIHopeAnchor:InitConfigData()
    local rewardIdList = {}
    local eventRefId = self._eventRefId
    if eventRefId then
        local eventRef = gModelFastDreamTrip:GetDreamTripEventRefByRefId(eventRefId)
        if eventRef then
            local rewardList = gModelFastDreamTrip:GetDreamTripRewardListByGroup(eventRef.reward)
            for idx,val in ipairs(rewardList) do
                table.insert(rewardIdList,val)
            end
        end
    end
    table.sort(rewardIdList,function(a,b)
        return a.refId < b.refId
    end)
    local allWeight = 0
    local weightList = {}
    for i,v in ipairs(rewardIdList) do
        local weight = v.weight
        local oldWeight = allWeight + 1
        allWeight = allWeight + weight
        table.insert(weightList,{
            minW = oldWeight,
            maxW = allWeight,
        })
    end
    self._weightList = weightList
    self._allWeight = allWeight
    self._rewardIdList = rewardIdList


    local shipResidue = gModelFastDreamTrip:GetConfigByKey("shipResidue")
    self._shipResidue = tonumber(shipResidue)

    --- 抛锚事件：获取上限个数（服务端验证）
    local shipNum = gModelFastDreamTrip:GetConfigByKey("shipNum")
    self._shipNum = shipNum

    --- 抛锚事件：道具刷新间隔时间（随机刷新库，每次间隔时间从库里拿）
    self._refreshShipTimeList = {}
    local shipTime = gModelFastDreamTrip:GetConfigByKey("shipTime")
    shipTime = string.split(shipTime,";")
    for i,v in ipairs(shipTime) do
        table.insert(self._refreshShipTimeList,tonumber(v))
    end

    --- 抛锚事件：每次随机刷新路线个数&刷新道具个数（区间内随机）
    self._refreshShipPathList = {}
    local shipPath = gModelFastDreamTrip:GetConfigByKey("shipPath")
    shipPath = string.split(shipPath,";")
    for i,v in ipairs(shipPath) do
        table.insert(self._refreshShipPathList,tonumber(v))
    end

    --- 抛锚事件：道具位移速度（随机刷新库，每次间隔时间从库里拿）
    self._refreshShipSpeedList = {}
    local shipSpeed = gModelFastDreamTrip:GetConfigByKey("shipSpeed")
    shipSpeed = string.split(shipSpeed,";")
    for i,v in ipairs(shipSpeed) do
        table.insert(self._refreshShipSpeedList,tonumber(v))
    end

    local shipStone = gModelFastDreamTrip:GetConfigByKey("shipStone")
    shipStone = string.split(shipStone,"=")
    self._shipStoneInfo = shipStone
    self._shipStoneId = tonumber(shipStone[2])

    --- 抛锚事件：钩子下落速度
    self._shipFall = gModelFastDreamTrip:GetConfigByKey("shipFall")

    --- 抛锚事件：钩子上升速度
    self._shipUp = gModelFastDreamTrip:GetConfigByKey("shipUp")
    self._shipUpHeight = (math.abs(self._moveEndPosY) + math.abs(self._initCordImgPosY)) / self._shipUp


    --- 抛锚事件：钩子回弹速度
    local shipResilience = gModelFastDreamTrip:GetConfigByKey("shipResilience")
    self._shipResilience = shipResilience
    self._shipResilienceHeight = self._height / shipResilience / 100

    self._changeParyTime = self._shipResidue

    self._countDownImgList = {
        [0] = "activity_music1_num_0",
        [1] = "activity_music1_num_1",
        [2] = "activity_music1_num_2",
        [3] = "activity_music1_num_3",
        [4] = "activity_music1_num_4",
        [5] = "activity_music1_num_5",
        [6] = "activity_music1_num_6",
        [7] = "activity_music1_num_7",
        [8] = "activity_music1_num_8",
        [9] = "activity_music1_num_9",
        [9] = "activity_music1_num_9",
    }
end

function UIHopeAnchor:ClearTimerList()
    for k,v in pairs(self._timerList) do
        LxTimer.DelayTimeStop(v)
    end
    self._timerList = {}
end

function UIHopeAnchor:SaveOnHookItemInfo(rewardInfo)
    if not rewardInfo then return end
    local getRewardList = self._getRewardList
    if not getRewardList then
        getRewardList = {}
        self._getRewardList = getRewardList
    end
    local itemId = rewardInfo.itemId
    if itemId and itemId > 0 then
        local name = gModelItem:GetNameByRefId(itemId)
        local numStr = LUtil.NumberCoversion(rewardInfo.itemNum)
        local str = string.replace(ccClientText(28720),name,numStr)
        FireEvent(EventNames.ON_DREAMTRIP_SHOWMSG,3,str,self.mShowTxtRoot)
    end
    local refId = rewardInfo.refId
    if refId then
        local num = getRewardList[refId] or 0
        getRewardList[refId] = num + 1
    end
    self._getNum = self._getNum + 1
    if self._getNum >= self._shipNum then
        self:SendMsg()
    end
end

function UIHopeAnchor:GetTimeList()
    local countDownImgList = self._countDownImgList
    local list = {}
    local changeParyTime = self._changeParyTime
    local min = 0
    if changeParyTime > 3600 then
        min = math.floor(changeParyTime / 60) % 60
    end
    local zeroImg = countDownImgList[0]
    if min == 0 then
        table.insert(list,zeroImg)
        table.insert(list,zeroImg)
    else
        local tD = math.floor(min / 10)
        local sD = min % 10
        table.insert(list,countDownImgList[tD])
        table.insert(list,countDownImgList[sD])
    end
    table.insert(list,"activity_music1_ui_5")
    local sec = math.floor(changeParyTime) % 60
    if sec == 0 then
        table.insert(list,zeroImg)
        table.insert(list,zeroImg)
    else
        local tD = math.floor(sec / 10)
        local sD = sec % 10
        table.insert(list,countDownImgList[tD])
        table.insert(list,countDownImgList[sD])
    end
    return list
end

function UIHopeAnchor:TweenItem(trans,time)
    local key = trans:GetInstanceID()
    local seqTween = self:TweenSeqFind(key)
    if seqTween then
        self:TweenSeqKill(key)
        seqTween = nil
    end
    local moveX = self._width + self._itemWidth
    seqTween = self:TweenSeqCreate(key, function(seq)
        local tween = trans:DOLocalMoveX(moveX,time)
        seq:Append(tween)
        return seq
    end)
    seqTween:OnComplete(function()
        CS.ShowObject(trans,false)
        self:TweenSeqKill(key)
    end)
    seqTween:PlayForward()
end

function UIHopeAnchor:GetRandomNum(list)
    local min = 1
    local max = #list
    local ramdonNum = self:GetRandomIndex(min,max)
    return list[ramdonNum]
end

function UIHopeAnchor:OnFDTEventFinish(recordFinishMap,pb)
    if not recordFinishMap[self._eventId] then return end
    self:WndClose()
end

function UIHopeAnchor:OnDrawTimeCell(list,item,itemdata,itempos)
    local ImgTrans = self:FindWndTrans(item,"Img")
    self:SetWndEasyImage(ImgTrans,itemdata,function()
        CS.ShowObject(ImgTrans,true)
    end,true)
end

------------------------- List -------------------------

------------------------------------------------------------------
return UIHopeAnchor



