---
--- Created by Administrator.
--- DateTime: 2025/4/2 14:34:26
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMiniGameBox:LWnd
local UIMiniGameBox = LxWndClass("UIMiniGameBox", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMiniGameBox:UIMiniGameBox()
    self._effectKeyList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMiniGameBox:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMiniGameBox:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMiniGameBox:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:InitEvent()
    self:InitMsg()
    self:InitStaticText()
    self:InitPara()

    self:RefreshUI()
end

--region 事件 --------------------------------------------------------------------------------
function UIMiniGameBox:InitEvent()
    self:SetWndClick(self.mBtnClose, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mImgMask, function()
        self:WndClose()
    end)
end

function UIMiniGameBox:OnDrawRwdItem(list, item, itemData, index)
    local instanceId = item:GetInstanceID()
    local Icon = self:FindWndTrans(item, "Icon")
    local baseClass = self:GetCommonIcon(instanceId)
    baseClass:Create(Icon)
    -- itemData.itemId = 100110

    baseClass:SetCommonReward(itemData.itemType, itemData.itemId, itemData.itemNum)
    baseClass:DoApply()
    self:SetWndClick(item, function()
        gModelGeneral:ShowCommonItemTipWnd(itemData)
    end)

end

function UIMiniGameBox:ShowRewardList(listView, itemData)
    self:CreateUIScrollImpl(nil, listView, itemData, function(...)
        self:OnDrawRwdItem(...)
    end, UIItemList.WRAP)
end

--endregion --------------------------------------------------------------------------------------

--region 数据 --------------------------------------------------------------------------------
function UIMiniGameBox:InitPara()
    self._sid = self:GetWndArg("sid")
    self._config = self:GetWndArg("config")

    --解析进度和奖励部分 expActivityProgReward
    self._expActivityProgReward = {}
    local expActivityProgReward = gModelActivity:GetLngNameById(self._config.expActivityProgReward)
    expActivityProgReward = string.split(expActivityProgReward, "|")

    for k, v in ipairs(expActivityProgReward) do
        local tempData = string.split(v, ",")
        self._expActivityProgReward[k] = {}
        self._expActivityProgReward[k].itemId = checknumber(tempData[1])
        self._expActivityProgReward[k].progress = checknumber(tempData[2])
    end

    local expActivityPlotReward = gModelActivity:GetLngNameById(self._config.expActivityPlotReward)
    expActivityPlotReward = string.split(expActivityPlotReward, "|")

    for k, v in ipairs(expActivityPlotReward) do
        self._expActivityProgReward[k].expActivityPlotReward = v
    end

    local expActivityPlotProg = gModelActivity:GetLngNameById(self._config.expActivityPlotProg)
    local plotProg = string.split(expActivityPlotProg, "|")
    for k, v in ipairs(plotProg) do
        self._expActivityProgReward[k].plotProg = checknumber(v)
    end

end

function UIMiniGameBox:RefreshUI()
    --当前已经看过的数量
    self._activity = gModelActivity:GetActivityBySid(self._sid)
    local moreInfo = self._activity.moreInfo
    self._taskList, self._progItemList, self._plotRewardIdList, self._recCollectReward = gModelActivityMiniGame:Parse159ActivityMoreInfo(moreInfo)

    local count = 0
    for k, v in pairs(self._progItemList) do
        count = count + 1
    end

    self._count = count  -- 已经看过的剧情数量

    self:CreateBoxList()
end

function UIMiniGameBox:InitMsg()
    self:WndEventRecv(EventNames.MINIGAME_ACTIVITY_DATA_UPDATE, function()
        self:RefreshUI()
    end)
end

--创建列表
function UIMiniGameBox:CreateBoxList()


    for k, v in ipairs(self._effectKeyList) do
        self:DestroyWndEffectByKey(v)
    end
    self._effectKeyList = {}

    self:CreateUIScrollImpl(nil, self.mListBoxRwd, self._expActivityProgReward, function(...)
        self:OnDrawBoxItem(...)
    end, UIItemList.WRAP)
end

function UIMiniGameBox:OnDrawBoxItem(list, item, itemData, index)
    local rewardList = self:FindWndTrans(item, "ListRewards")
    local txtTitle = self:FindWndTrans(item, "Title/TxtTitle")
    local btnGet = self:FindWndTrans(item, "BtnGet")
    local txtProgress = self:FindWndTrans(item, "Title/TxtProgress")
    local txtGeted = self:FindWndTrans(item, "TxtGeted")
    local txtBtnName = self:FindWndTrans(btnGet, "TxtBtnName")

    local checkCondition = itemData.plotProg

    --奖励设置
    local rwds = itemData.expActivityPlotReward
    rwds = LxDataHelper.ParseItem(rwds)
    self:ShowRewardList(rewardList, rwds)

    --标题部分
    local titleStr = string.replace(ccClientText(46916), index)
    self:SetWndText(txtTitle, titleStr)


    --进度部分  FF0000  02a90b
    local color =  self._count < checkCondition and "#FF0000" or "#02a90b"
    self:SetWndText(txtProgress,string.replace("（<color=#a1#>#a2#</color>/#a3#）",color,(self._count>=checkCondition and checkCondition or self._count),checkCondition))

    --标签部分
    local imgPath = self._count < checkCondition and "activity_turn_txt_16" or "public_txt_13_1" --ComPanel
    self:SetWndEasyImage(txtGeted, imgPath)
    self:SetWndText(txtBtnName, self._count < checkCondition and ccClientText(30003) or ccClientText(30002))


    local isGet = 0
    if self._count >= checkCondition and (not self._recCollectReward[index]) then
        isGet = 2
    end
    CS.ShowObject(btnGet, isGet == 2)
    CS.ShowObject(txtGeted, isGet ~= 2)

    self:SetWndClick(btnGet, function()
        gModelActivity:OnActivitySpecialOpReq(self._sid, nil, nil, nil, tostring(index), ModelActivity.ACTIVITY_159_REC_COLLECT_REWARD)
    end)

    --特效设置
    local key = "task" .. tostring(index)
    table.insert(self._effectKeyList, key)
    self:CreateWndEffect(btnGet, "fx_anniu_02", key, 100, nil, nil, nil, nil, nil, true)
end

--endregion --------------------------------------------------------------------------------------

--region 界面设置 --------------------------------------------------------------------------------
function UIMiniGameBox:InitStaticText()
    self:SetWndText(self.mTxtBiaoti, ccClientText(46915))
    self:SetWndText(self.mCloseInfo, ccClientText(41037))
end
--endregion --------------------------------------------------------------------------------------


------------------------------------------------------------------
return UIMiniGameBox