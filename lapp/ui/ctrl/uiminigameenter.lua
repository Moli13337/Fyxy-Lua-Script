---
--- Created by Administrator.
--- DateTime: 2025/3/14 11:11:05
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMiniGameEnter:LWnd
local UIMiniGameEnter = LxWndClass("UIMiniGameEnter", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMiniGameEnter:UIMiniGameEnter()
    self._pageRewardItemTran = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMiniGameEnter:OnWndClose()
    gModelGameHelper:RefreshGameSpeed()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMiniGameEnter:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMiniGameEnter:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:InitMsg()
    self:InitEvent()
    self:InitPara()
    self:InitStaticText()
    self:InitComment()

    gModelGameHelper:TemporaryCloseSpeed()
end

function UIMiniGameEnter:SetTaskDiv()
    local taskRootTran = CS.FindTrans(self.mTaskDiv, "Bg")
    local title = CS.FindTrans(taskRootTran, "Title")
    -- 标题
    self:SetWndText(title, ccClientText(46910))

    for k, itemdata in ipairs(self._taskList) do
        local taskTextName = "Task_" .. k
        local taskTran = CS.FindTrans(taskRootTran, taskTextName)
        local taskData = gModelQuest:GetTaskDataByRefId(itemdata)
        local taskRef = gModelQuest:GetTaskConfig(itemdata)
        local progress = string.format("%s/%s", taskData:GetSchedule(), taskData:GetGoal())
        local progressStr = string.replace(ccClientText(46911), k, progress)
        progressStr = progressStr .. ccLngText(taskRef.description)
        self:SetWndText(taskTran, progressStr)
    end
end

function UIMiniGameEnter:SetMiniGameEnter()
    --先解析数据
    local expActivityEntry = gModelActivity:GetLngNameById(self._webData.config.expActivityEntry)

    local entryData = string.split(expActivityEntry, ",")
    local entriesData = {}
    for k, v in ipairs(entryData) do
        local tempData = string.split(v, "=")

        local entry = {}
        entry.jumpEntryId = checknumber(tempData[1])
        entry.entryBg = tempData[2]
        entry.entryBgPos = LxDataHelper.ParseVector2NotEmpty2(tempData[3])
        entry.entryText = tempData[4]
        entry.entryTextPos = LxDataHelper.ParseVector2NotEmpty2(tempData[5])
        table.insert(entriesData, entry)
    end

    --开始创建
    for i = 1, #entriesData do
        local tranKey = "Enter_" .. i
        local tran = CS.FindTrans(self.mEnterDiv, tranKey)
        self:SetEnter(tran, entriesData[i])
        CS.ShowObject(tran, true)
    end
    self._entriesData = entriesData
end

function UIMiniGameEnter:OnClickHelp()
    local content = self._signHelpTips or ""
    local title = self._title or ""
    GF.OpenWnd("UIBzTips", { title = title, text = content })
end

function UIMiniGameEnter:OnActivityConfigData(data, sid)
    if sid ~= self._sid then
        return
    end

    self._webData = data

    if not self._webData then
        self:WndClose()
        printInfoNR2("UIMiniGameEnter--159", "not webData close wnd")
        return
    end

    gModelActivity:OnActivityPageReq(self._sid)

    --设置对应的helptips
    local HelpTips = self._webData.config.HelpTips
    local HelpTipsPos = self._webData.config.HelpTipsPos
    self._signHelpTips = HelpTips
    self._title = gModelActivity:GetLngNameByActivitySid(sid)
    if not string.isempty(HelpTips) then
        local trans = self.mBtnHelp
        CS.ShowObject(trans, true)
        if not string.isempty(HelpTipsPos) then
            local pos = LxDataHelper.ParseVector2NotEmpty3(HelpTipsPos)
            self:SetAnchorPos(trans, pos)
        end
    end
end

function UIMiniGameEnter:SetExpActivityProgItem()
    local preHeight = 577 / self._expActivityProgMax
    local offsetHeight = -(577 / 2)
    self._expActivityProgItemTran = {}
    --道具
    for k, v in ipairs(self._expActivityProgReward) do
        local itemNew = self._pageRewardItemTran[k]
        if not itemNew then
            itemNew = LxResUtil.NewObject(self.mItemTemplate.gameObject)
            self._pageRewardItemTran[k] = itemNew
        end

        itemNew.transform:SetParent(self.mScheduleRewardDiv, false)
        itemNew.transform.localPosition = Vector3.zero

        local icon = CS.FindTrans(itemNew, "icon")
        local UIText = CS.FindTrans(itemNew, "UIText")
        local height = v.progress * preHeight + offsetHeight
        local typeOfRectTransform = typeof(UnityEngine.RectTransform)
        local rectTran = itemNew.transform:GetComponent(typeOfRectTransform)
        self:SetAnchorPos(rectTran, Vector2.New(0, height))
        local itemRef = gModelItem:GetRefByRefId(checknumber(v.itemId))
        self:SetWndEasyImage(icon, itemRef.icon)
        self:SetWndText(UIText, v.progress)

        CS.ShowObject(itemNew, true)
        self._expActivityProgItemTran[k] = rectTran

        --定义点击
        self:SetWndClick(rectTran, function()
            if self._plotRewardIdList[checknumber(v.itemId)] then
                --已领取过 不做处理
            else
                local expItemId = checknumber(self._webData.config.expActivityProgItem)
                local progress = gModelItem:GetNumByRefId(expItemId)
                local itemProgress = checknumber(v.progress)

                if progress >= itemProgress then
                    --进行领取
                    gModelActivity:OnActivitySpecialOpReq(self._sid, nil, nil, nil, tostring(v.itemId), ModelActivity.ACTIVITY_159_REC_PROG)
                end
            end
        end)


    end
end

function UIMiniGameEnter:InitStaticText()
    self:SetWndText(self.mTxtReturn, ccClientText(41102))
end

function UIMiniGameEnter:SetEnter(tran, data)
    local Bg = CS.FindTrans(tran, "Bg")
    local EnterName = CS.FindTrans(tran, "EnterName")

    self:SetWndEasyImage(Bg, data.entryBg)
    self:SetWndText(EnterName, data.entryText)
    self:SetAnchorPos(tran, data.entryBgPos)
    self:SetAnchorPos(EnterName, data.entryTextPos)

    self:SetWndClick(tran, function()
        --跳转 --直接传入对应的entryId 就完事了
        local wndName = gModelActivityMiniGame:GetMiniGameWndName(data.jumpEntryId)

        if not string.isempty(wndName) then
            GF.OpenWnd(wndName, { entryId = data.jumpEntryId, sid = self._sid })
        end
    end)
end

function UIMiniGameEnter:SetRewardDiv()
    --先解析数据
    local expActivityProgReward = gModelActivity:GetLngNameById(self._webData.config.expActivityProgReward)
    expActivityProgReward = string.split(expActivityProgReward, "|")

    self._expActivityProgReward = {}

    local maxIndex = #expActivityProgReward
    for k, v in ipairs(expActivityProgReward) do
        local tempData = string.split(v, ",")
        self._expActivityProgReward[k] = {}
        self._expActivityProgReward[k].itemId = checknumber(tempData[1])
        self._expActivityProgReward[k].progress = checknumber(tempData[2])

        if k == maxIndex then
            self._expActivityProgMax = checknumber(tempData[2])
        end
    end

    self:SetExpActivityProgItem()
    self:SetExpActivityProg()
end

function UIMiniGameEnter:InitMsg()
    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
        self:OnActivityConfigData(...)
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityResp, function(pb)
        if self._sid ~= pb.activity.sid then
            return
        end
        gModelActivity:ReqActivityConfigData(self._sid)
    end)

    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
        self._activity = gModelActivity:GetActivityBySid(self._sid)
        local moreInfo = self._activity.moreInfo
        self._taskList, self._progItemList, self._plotRewardIdList, self._recCollectReward = gModelActivityMiniGame:Parse159ActivityMoreInfo(moreInfo)

        self:InitActivityPanel()
        FireEvent(EventNames.MINIGAME_ACTIVITY_DATA_UPDATE)
    end)
end

function UIMiniGameEnter:UpdateExpActivityProgItem()
    --进度
    local expItemId = checknumber(self._webData.config.expActivityProgItem)
    local progress = gModelItem:GetNumByRefId(expItemId)

    for k, v in ipairs(self._expActivityProgReward) do
        local rectTran = self._expActivityProgItemTran[k]

        --判断下领取过没有
        local mark = CS.FindTrans(rectTran, "mark")
        local TipsBg = CS.FindTrans(rectTran, "TipsBg")
        local TipsText = CS.FindTrans(rectTran, "TipsBg/Tips")
        CS.ShowObject(mark, false)
        CS.ShowObject(TipsBg, false)
        if self._plotRewardIdList[checknumber(v.itemId)] then
            CS.ShowObject(mark, true)
        else
            --如果没领取过 显示气泡
            local itemProgress = checknumber(v.progress)
            local isCanGetReward = progress >= itemProgress

            CS.ShowObject(TipsBg, isCanGetReward)
            self:SetWndText(TipsText, ccClientText(46913))
        end
    end
end

function UIMiniGameEnter:SetTranPos(Tran, posData)
    local pos = string.split(posData, "|")
    pos = Vector2.New(checknumber(pos[1]), checknumber(pos[2]))
    self:SetAnchorPos(Tran, pos)
end

function UIMiniGameEnter:SetExpActivityProg()
    --进度
    local expItemId = checknumber(self._webData.config.expActivityProgItem)
    local progress = gModelItem:GetNumByRefId(expItemId)
    self:SetWndText(self.mScheduleDes, ccClientText(46912))
    self:SetWndText(self.mScheduleValue, progress)

    --设置进度
    local progressScale = checknumber(progress) / self._expActivityProgMax
    progressScale = progressScale > 1 and 1 or progressScale

    self.mFill.localScale = Vector3.New(1, 1 * progressScale, 1)
end

function UIMiniGameEnter:InitActivityPanel()
    self:SetMiniGameEnter()
    self:SetTaskDiv()
    self:SetRewardDiv()
    self:UpdateExpActivityProgItem()
end
--endregion --------------------------------------------------------------------------------------

--region 界面 --------------------------------------------------------------------------------
function UIMiniGameEnter:InitPara()
    local sid = self:GetWndArg("sid")
    local subpage = self:GetWndArg("subPage") --支持跳转
    if subpage then
        sid = gModelActivity:GetSidByUniqueJump(subpage)
    end

    if not sid then
        local dataList = gModelActivity:GetActivityDataByModelId(ModelActivity.MODEL_ACTIVITY_TYPE_159)
        if dataList[1] then
            sid = dataList[1].sid
        end
    end

    if not sid then
        self:WndClose()
        printInfoNR2("UIMiniGameEnter--159", "not sid close wnd")
        return
    end

    self._sid = sid

    gModelActivity:ReqActivityConfigData(self._sid)
end

function UIMiniGameEnter:InitComment()

end

--region 事件 --------------------------------------------------------------------------------
function UIMiniGameEnter:InitEvent()
    self:SetWndClick(self.mReturnBtn, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mTaskDiv, function()
        GF.OpenWnd("UIMiniGameTask", { taskList = self._taskList })
    end)

    self:SetWndClick(self.mCollectDiv, function()
        GF.OpenWnd("UIMiniGameCollect", { collectItem = self._webData.config.expActivityCollectItem, sid = self._sid, config = self._webData.config })
    end)

    self:SetWndClick(self.mBtnHelp, function(...)
        self:OnClickHelp()
    end, LSoundConst.CLICK_ERROR_COMMON)
end
--endregion --------------------------------------------------------------------------------------


------------------------------------------------------------------
return UIMiniGameEnter