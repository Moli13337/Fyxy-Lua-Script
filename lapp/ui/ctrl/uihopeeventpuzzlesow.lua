---
--- Created by LCM.
--- DateTime: 2024/3/21 14:35:58
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeEventPuzzleSow:LWnd
local UIHopeEventPuzzleSow = LxWndClass("UIHopeEventPuzzleSow", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeEventPuzzleSow:UIHopeEventPuzzleSow()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeEventPuzzleSow:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeEventPuzzleSow:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeEventPuzzleSow:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:InitPuzzleList()
end

function UIHopeEventPuzzleSow:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIHopeEventPuzzleSow:OnDrawPuzzleCell(list,item,itemdata,itempos)
    local BgTrans = self:FindWndTrans(item,"Bg")
	self:SetWndEasyImage(BgTrans,itemdata,function()
		CS.ShowObject(BgTrans,true)
	end)
end
------------------------- List -------------------------
function UIHopeEventPuzzleSow:GetPuzzleList()
	return self._rightImgList
end

function UIHopeEventPuzzleSow:InitText()
	self:SetWndText(self.mTitle,ccClientText(28706))
end

function UIHopeEventPuzzleSow:InitData()
	self._rightImgList = self:GetWndArg("rightImgList")
end

function UIHopeEventPuzzleSow:InitPuzzleList()
    local list = self:GetPuzzleList()
    local uiPuzzleList = self._uiPuzzleList
    if uiPuzzleList then
        uiPuzzleList:RefreshList(list)
    else
        uiPuzzleList = self:GetUIScroll("uiPuzzleList")
        self._uiPuzzleList = uiPuzzleList
        uiPuzzleList:Create(self.mPuzzleList,list,function(...) self:OnDrawPuzzleCell(...) end)
    end
end

function UIHopeEventPuzzleSow:InitMsg()
	-- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

------------------------- List -------------------------

------------------------------------------------------------------
return UIHopeEventPuzzleSow



