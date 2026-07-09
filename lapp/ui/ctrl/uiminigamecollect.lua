---
--- Created by Administrator.
--- DateTime: 2025/3/31 10:08:06
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMiniGameCollect:LWnd
local UIMiniGameCollect = LxWndClass("UIMiniGameCollect", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMiniGameCollect:UIMiniGameCollect()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMiniGameCollect:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMiniGameCollect:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMiniGameCollect:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:InitEvent()
    self:InitMsg()
    self:InitPara()
    self:InitStaticText()
end

--region 事件 --------------------------------------------------------------------------------
function UIMiniGameCollect:InitEvent()
    self:SetWndClick(self.mBg, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mCollectProgressDiv, function()
        GF.OpenWnd("UIMiniGameBox", { sid = self._sid, config = self._config })
    end)
end

--endregion --------------------------------------------------------------------------------------

--region 界面设置 --------------------------------------------------------------------------------
function UIMiniGameCollect:InitStaticText()
    self:SetWndText(self.mCloseTip, ccClientText(17003))

    local Des = CS.FindTrans(self.mCollectProgressDiv, "Des")
    self:SetWndText(Des, ccClientText(46914))
end

function UIMiniGameCollect:InitMsg()
    self:WndEventRecv(EventNames.MINIGAME_ACTIVITY_DATA_UPDATE, function()
        self:RefreshUIData()
    end)
end

--进度部分
function UIMiniGameCollect:SetCollectRewardProgress()
    local progressStr = string.format("<color=#6aff48>%s</color>/%s", self._count, self._maxPlotprog)

    local progressScale = self._count / self._maxPlotprog

    progressScale = progressScale > 1 and 1 or progressScale

    local Fill = CS.FindTrans(self.mCollectProgressDiv, "Bg/Fill")
    Fill.localScale = Vector3.New(progressScale, 1, 1)

    local UIText = CS.FindTrans(self.mCollectProgressDiv, "Bg/UIText")
    self:SetWndText(UIText, progressStr)
end

function UIMiniGameCollect:RefreshUIData()
    self._activity = gModelActivity:GetActivityBySid(self._sid)
    local moreInfo = self._activity.moreInfo
    self._taskList, self._progItemList, self._plotRewardIdList, self._recCollectReward = gModelActivityMiniGame:Parse159ActivityMoreInfo(moreInfo)

    local count = 0
    for k, v in pairs(self._progItemList) do
        count = count + 1
    end
    self._count = count  -- 已经看过的剧情数量


    local plotRewardCount = 0
    for k, v in pairs(self._plotRewardIdList) do
        plotRewardCount = plotRewardCount + 1
    end
    self._plotRewardCount = plotRewardCount  -- 已经看过的剧情数量

    --获取最后一个的剧情
    local expActivityPlotProg = gModelActivity:GetLngNameById(self._config.expActivityPlotProg)
    local plotProg = string.split(expActivityPlotProg, "|")
    self._maxPlotprog = checknumber(plotProg[#plotProg])

    self:SetCollectDiv()
    self:SetCollectRewardProgress()
end

--endregion --------------------------------------------------------------------------------------

--region 数据 --------------------------------------------------------------------------------
function UIMiniGameCollect:InitPara()
    local collectItem = self:GetWndArg("collectItem")
    self._collectItem = string.split(collectItem, ",")
    self._sid = self:GetWndArg("sid")
    self._config = self:GetWndArg("config")

    self:RefreshUIData()
end

function UIMiniGameCollect:SetCollectDiv()
    local showTitleStr = string.replace(ccClientText(46917), self._plotRewardCount)
    self:SetWndText(self.mCollectNum, showTitleStr)

    self:SetWndText()
    for k, v in ipairs(self._collectItem) do
        local tranName = "Collect_" .. k
        local tran = CS.FindTrans(self.mCollectDiv, tranName)
        self:SetCollectItem(tran, v)
    end
end

function UIMiniGameCollect:SetCollectItem(tran, itemdata)
    CS.ShowObject(tran, true)
    local Bg = CS.FindTrans(tran, "Bg")
    local Icon = CS.FindTrans(tran, "Icon")
    local IconName = CS.FindTrans(tran, "IconName")
    local TipsBg = CS.FindTrans(tran, "TipsBg")
    local Tips = CS.FindTrans(tran, "TipsBg/Tips")

    local itemRef = gModelItem:GetRefByRefId(checknumber(itemdata))
    local qualityRef = GameTable.RarityRef[itemRef.quality]
    local iconBgPath = qualityRef.iconBg
    self:SetWndEasyImage(Bg, iconBgPath)
    self:SetWndEasyImage(Icon, itemRef.icon)
    self:SetWndText(IconName, ccLngText(itemRef.name))

    self:SetWndText(Tips, ccClientText(46909))

    local plot = checknumber(itemRef.typeDate)

    local isHave = self._plotRewardIdList[checknumber(itemdata)]

    self:SetWndImageGray(Icon, not isHave)

    if isHave then
        local isGet = self._progItemList[checknumber(itemdata)]

        CS.ShowObject(TipsBg, not isGet)
    else
        CS.ShowObject(TipsBg, false)
    end

    self:SetWndClick(tran, function()
        if isHave then
            gModelActivity:OnActivitySpecialOpReq(self._sid, nil, nil, nil, tostring(itemdata), ModelActivity.ACTIVITY_159_READ_PROG)
            gModelPlot:StartPlotAndCallback(plot, function() end)
        end
    end)
end


--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIMiniGameCollect