---
--- Created by wzz.
--- DateTime: 2024/4/1 15:10:41
---
------------------------------------------------------------------

local LWnd = LWnd
---@class UIMinEntrance:LWnd
local UIMinEntrance = LxWndClass("UIMinEntrance", LWnd)

UIMinEntrance.MOVE_RIGHT = -1
UIMinEntrance.MOVE_LEFT = 1
UIMinEntrance.MOVE_CENTER = 0


------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMinEntrance:UIMinEntrance()
    self._pageIndex = 1

    --move 使用到的定义  --tween的定义
    self._autoMoveKey = "_autoMoveKey"
    self._moveTime = 0.2
    self._effectList = {}
    self.showDataList = {}

    self:InitHandler()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMinEntrance:OnWndClose()
    LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMinEntrance:OnCreate()
    LWnd.OnCreate(self)
    return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMinEntrance:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:InitList()


    self:RefreshList()
    self:StartScroll()

    local timePara = {
        func = function()
            self:UpDataItemTime()
        end,
        callOnStart = true,
        loopcnt = -1,
        interval = 1,
        key = "UpDataItemTime"
    }
    self:TimerStartImpl(timePara)
end

function UIMinEntrance:UIDragOnDrag(dragKey, eventData)
    local moveX = self.mItemRoot.localPosition.x

    if moveX >= self._changeDistanceX then
        self:MoveRoot(UIMinEntrance.MOVE_RIGHT)
    elseif moveX <= -self._changeDistanceX then
        self:MoveRoot(UIMinEntrance.MOVE_LEFT)
    else
        local curPos = Vector3.New(moveX, 0, 0)
        self.mItemRoot.localPosition = curPos
    end
end

function UIMinEntrance:RefreshCurSelectPageWhenMove(index)
    local pageIndex = self._pageIndex
    pageIndex = pageIndex + index

    if pageIndex < 1 then
        --当抵达左边界 的时候  下一个-1 则应该抵达右边界
        pageIndex = self._dataMaxNum
    elseif pageIndex > self._dataMaxNum then
        --当抵达右边界 的时候  下一个+1 则应该抵达左边界
        pageIndex = 1
    end
    self._pageIndex = pageIndex
end

function UIMinEntrance:AutoScroll()
    self:AutoMoveRoot(UIMinEntrance.MOVE_LEFT)
end

function UIMinEntrance:InitPoint()
    local allListData = self.originalDataList or {}
    self._pointList = self._pointList or {}
    for k, v in ipairs(allListData) do
        local trans = self._pointList[k]
        if not trans then
            local obj = CS.InstantObject(self.mPointRoot.gameObject)
            trans = obj.transform
            trans:SetParent(self.mPointParent, false)
            self._pointList[k] = trans
        end
        CS.ShowObject(trans, true)
    end

    for i = #allListData + 1, #self._pointList do
        CS.ShowObject(self._pointList[i], false)
    end

    CS.ShowObject(self.mPointParent.gameObject, #allListData > 1)
end

function UIMinEntrance:UIDragOnEnd(dragKey, eventData)
    local endMoveX = self.mItemRoot.localPosition.x
    local autoChangeDistanceX = self._autoChangeDistanceX

    local moveType
    if endMoveX > 0 and endMoveX >= autoChangeDistanceX then
        moveType = UIMinEntrance.MOVE_RIGHT
    elseif endMoveX < 0 and endMoveX <= -autoChangeDistanceX then
        moveType = UIMinEntrance.MOVE_LEFT
    else
        moveType = UIMinEntrance.MOVE_CENTER
    end

    self:AutoMoveRoot(moveType)
end

function UIMinEntrance:RefreshList()
    self.originalDataList = gModelFunctionOpen:GetForeshowList()
    self._dataMaxNum = #self.originalDataList
    if self._dataMaxNum == 0 then
        self:WndClose()
        return
    end


    self:UIDragSetItem("myDraw", "AniRoot/Img1/PageList/ItemRoot", CS.YXUIDrag.DragMode.DragOrigin, self._dataMaxNum > 1)

    self:CalculateDataList()
    self:UpDataItem()
    self:InitPoint()
    self:RefreshPoint()
end

--region 滚动列表 --------------------------------------------------------------------------------
-- 实始化滚动列表 ,防：UISubOuttsPVP.lua
function UIMinEntrance:InitList()
    self._itemList = {}
    for i = 1, 3 do
        local tab         = {}
        tab.item          = self["mItemTemplate" .. i]
        tab.icon          = self:FindWndTrans(tab.item, "Icon")
        tab.txtBg         = self:FindWndTrans(tab.item, "bg")
        tab.txtTime       = self:FindWndTrans(tab.item, "bg/txtTime")
        self._itemList[i] = tab
    end
    self._changeDistanceX = self.mItemTemplate1.rect.width
    self._autoChangeDistanceX = self._changeDistanceX / 4
    self._pageIndex = 1

    local trans = self["mItemTemplate" .. 1].parent.parent
    self:ShowEff(trans, trans, true)
end

-- 初始化协议
function UIMinEntrance:InitHandler()
    self:WndEventRecv(EventNames.ON_CHANGE_MAIN_BTN, function(index)
        self:Show(index == 1)
    end)

    self:WndEventRecv(EventNames.ON_PRE_FUNC_PLAY, function()
        self:RefreshList()
    end)
end

-- 计算数据列表
function UIMinEntrance:CalculateDataList()
    local pageIndex = self._pageIndex

    self.showDataList = {}
    if pageIndex == 1 then
        self.showDataList[1] = self.originalDataList[self._dataMaxNum]
        self.showDataList[2] = self.originalDataList[pageIndex]
        self.showDataList[3] = self.originalDataList[pageIndex + 1] or self.originalDataList[pageIndex]
    elseif pageIndex == self._dataMaxNum then
        self.showDataList[1] = self.originalDataList[pageIndex - 1]
        self.showDataList[2] = self.originalDataList[pageIndex]
        self.showDataList[3] = self.originalDataList[1]
    else
        self.showDataList[1] = self.originalDataList[pageIndex - 1]
        self.showDataList[2] = self.originalDataList[pageIndex]
        self.showDataList[3] = self.originalDataList[pageIndex + 1]
    end
end

function UIMinEntrance:RefreshPoint()
    for k, v in ipairs(self._pointList) do
        self:SetWndButtonGray(v, k ~= self._pageIndex)
    end
end

function UIMinEntrance:OnDrawItem(tab, itemdata, index)
    local icon = tab.icon
    local imgPath = itemdata.data.icon
    self:SetWndEasyImage(icon, imgPath)
    self:SetWndClick(tab.item, function() self:OnClickItem(index) end)

    local showRed = false
    if itemdata.pb then
        showRed = gModelMainCity:CheckMainActivityRed(itemdata.pb)
    end
    self:SetRed(tab.item, not not showRed)
end

function UIMinEntrance:UpDataItemTime()
    local curTime = GetTimestamp()
    local leftTime = 0
    for k, v in ipairs(self._itemList) do
        local data = self.showDataList[k]

        if data then
            if data.pb then
                leftTime = math.max(0, data.pb.endTime - curTime)
            else
                local serverData = gModelFunctionOpen:GetForeshowData(data.data.refId)
                if serverData and serverData.endTime > 0 then
                    leftTime = math.max(0, serverData.endTime - curTime)
                end
            end
        end
        if leftTime > 0 then
            local strTime = LUtil.FormatTimespanCn(leftTime)
            self:SetWndText(v.txtTime, strTime)
        end

        CS.ShowObject(v.txtBg, leftTime > 0)
    end
end

function UIMinEntrance:StartScroll()
    self:StopScroll()

    if #self.originalDataList < 2 then
        return
    end

    local tab = {
        -- callOnStart = true,
        func = function() self:AutoScroll() end,
        loopcnt = -1,
        interval = gModelFunctionOpen:GetForeshowScrollTime(),
        key = "AutoScroll"
    }

    self:TimerStartImpl(tab)
end

function UIMinEntrance:MoveRoot(index)
    if index == UIMinEntrance.MOVE_CENTER then
        return
    end
    --index 为 左1  右-1    --刷新index
    self:RefreshCurSelectPageWhenMove(index)
    --刷新列表数据
    self:CalculateDataList()
    --刷新位置
    self:RetSetRootPos()
    self:UpDataItem()
    self:RefreshPoint()
end

-- 点击item
function UIMinEntrance:OnClickItem(index)
    GF.OpenWnd("UIMinEntranceList", { index = index, list = self.originalDataList })
end

function UIMinEntrance:UpDataItem()
    for k, v in ipairs(self._itemList) do
        local data = self.showDataList[k]
        if data then
            self:OnDrawItem(v, data, k)
        end
    end
    self:UpDataItemTime()
end

function UIMinEntrance:AutoMoveRoot(moveType, nextFunc)
    local itemRoot = self.mItemRoot
    if not CS.IsValidObject(itemRoot) then
        return
    end
    self._bMove = true

    local moveX
    if moveType == UIMinEntrance.MOVE_RIGHT then
        --自动右移一页
        moveX = self._changeDistanceX
    elseif moveType == UIMinEntrance.MOVE_LEFT then
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
        -- 刷新item
        self:RetSetRootPos()
        self:StartScroll()
        if nextFunc then
            --给移动两格使用
            nextFunc()
        end
    end)
end

-- 显示特效
function UIMinEntrance:ShowEff(trans, key, isShow)
    local effName = "fx_ui_gunping_2"

    if isShow then
        if self._effectList and self._effectList[key] then
            return
        end
        self:CreateWndEffect(trans, effName, key, 100, nil, nil, nil, nil, nil, true)
    else
        self:DestroyWndEffectByKey(key)
    end
end

function UIMinEntrance:StopScroll()
    self:TimerStop("AutoScroll")
end

function UIMinEntrance:UIDragOnBegin(dragKey, eventData)
    self._bMove = true
    self:StopScroll()
end

function UIMinEntrance:RetSetRootPos()
    --重置原本节点
    local curPos = Vector3.New(0, 0, 0)
    self.mItemRoot.localPosition = curPos
end

--endregion --------------------------------------------------------------------------------


return UIMinEntrance