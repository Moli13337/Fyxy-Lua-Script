---
--- Created by Administrator.
--- DateTime: 2023/10/27 16:44:39
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaBookRelationPop:LWnd
local UISagaBookRelationPop = LxWndClass("UISagaBookRelationPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaBookRelationPop:UISagaBookRelationPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaBookRelationPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaBookRelationPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaBookRelationPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:RefreshView()
	self:InitText()
end

function UISagaBookRelationPop:RefreshView()
	local relationRefId = self._relationRefId
	local ref = gModelHeroBook:GetHeroRelationRefByRefId(relationRefId)
	if not ref then return end
	local relationStory = ccLngText(ref.relationStory)
	self:SetWndText(self.mStoryText,relationStory)
	self:SetWndText(self.mStoryTitle, ccLngText(ref.name))
end

function UISagaBookRelationPop:InitData()
	self._relationRefId = self:GetWndArg("refId")
end

function UISagaBookRelationPop:InitText()
	self:SetWndText(self.mCloseTip,ccClientText(10103))
end

function UISagaBookRelationPop:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

------------------------------------------------------------------
return UISagaBookRelationPop


