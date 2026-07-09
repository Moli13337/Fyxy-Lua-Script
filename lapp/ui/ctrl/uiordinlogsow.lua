---
--- Created by LCM.
--- DateTime: 2024/3/30 12:08:51
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIOrdinLogSow:LWnd
local UIOrdinLogSow = LxWndClass("UIOrdinLogSow", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIOrdinLogSow:UIOrdinLogSow()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIOrdinLogSow:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIOrdinLogSow:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIOrdinLogSow:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEmptyList()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
    self:InitText()
    self:RefreshView()
end

function UIOrdinLogSow:InitData()
    self._logTitle = self:GetWndArg("logTitle")
    self._logTips = self:GetWndArg("logTips")

    self._logList = self:GetWndArg("logList")
end


------------------------- List -------------------------


function UIOrdinLogSow:GetLogList()
    local list = self._logList or {}
    return list
end

function UIOrdinLogSow:InitText()
    local title = self._logTitle or ccClientText(34905)
    self:SetWndText(self.mLblBiaoti,title)

    self:SetWndText(self.mText1,ccClientText(34907))
    self:SetWndText(self.mText2,ccClientText(34908))
    self:SetWndText(self.mText3,ccClientText(34909))

    local logTips = self._logTips or ""
    self:SetWndText(self.mSaveTxt,logTips)
end

function UIOrdinLogSow:InitLogList()
    local list = self:GetLogList()
    local uiLogList = self._uiLogList
    if uiLogList then
        uiLogList:RefreshList(list)
    else
        uiLogList = self:GetUIScroll("uiLogList")
        self._uiLogList = uiLogList
        uiLogList:Create(self.mLogList,list,function(...) self:OnDrawLogCell(...) end,UIItemList.WRAP)
    end
    local isEmpty = #list < 1
    CS.ShowObject(self.mNoRecord2,isEmpty)
end

function UIOrdinLogSow:InitEmptyList()
    local data = {
        refId = 14008,
        IntroTran = self.mEmptyText,
        TextBgTran = self.mEmptyTextBg,
        IconTran = self.mEmptyIcon,
    }
    local emptyList = self:GetCommonEmptyList("_empty")
    emptyList:RefreshUI(data)
end

function UIOrdinLogSow:OnDrawLogCell(list,item,itemdata,itempos)
    local CommonUITrans = self:FindWndTrans(item,"CommonUI")
    local IconTrans = self:FindWndTrans(CommonUITrans,"Icon")

    local ShowIconDivTrans = self:FindWndTrans(item,"ShowIconDiv")
    local IconDivTrans = self:FindWndTrans(ShowIconDivTrans,"IconDiv")
    local IconImgTrans = self:FindWndTrans(IconDivTrans,"Icon")
    local NumTrans = self:FindWndTrans(ShowIconDivTrans,"Num")

    local TimeTrans = self:FindWndTrans(item,"Time")


    local showIconInfo = itemdata.showIconInfo
    if showIconInfo then
        local itemType,itemId,itemNum = showIconInfo.itemType,showIconInfo.itemId,showIconInfo.itemNum
        local instanceID = item:GetInstanceID()
        local baseClass = self:GetCommonIcon(instanceID)
        baseClass:Create(IconTrans)
        baseClass:SetCommonReward(itemType,itemId,itemNum)
        baseClass:DoApply()
        self:SetWndClick(IconTrans,function()
            gModelGeneral:ShowCommonItemTipWnd({
                itemType = itemType,
                itemId = itemId,
                itemNum = itemNum,
            })
        end)
    end

    local showPayInfo = itemdata.showPayInfo
    local showPayInfoStatus = showPayInfo ~= nil
    if showPayInfoStatus then
        local itemId = showPayInfo.itemId
        local icon = gModelItem:GetItemIconByRefId(itemId)
        self:SetWndEasyImage(IconImgTrans,icon,function()
            CS.ShowObject(IconDivTrans,true)
            CS.ShowObject(IconImgTrans,true)
        end,true)
        self:SetWndText(NumTrans,LUtil.NumberCoversion(showPayInfo.itemNum))
    end
    CS.ShowObject(ShowIconDivTrans,showPayInfoStatus)

    local createTime = itemdata.createTime
    local showCreateTime = createTime ~= nil
    if showCreateTime then
        local timeConstStr = string.replace(ccClientText(34912),ccClientText(34910),ccClientText(34911))
        local timeStr = LUtil.FormatTimeStr(createTime,timeConstStr)
        self:SetWndText(TimeTrans,timeStr)
    end
    CS.ShowObject(TimeTrans,showCreateTime)
end

function UIOrdinLogSow:InitEvent()
    self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIOrdinLogSow:RefreshView()
    self:InitLogList()
end


function UIOrdinLogSow:InitMsg()

	-- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

------------------------- List -------------------------

------------------------------------------------------------------
return UIOrdinLogSow



