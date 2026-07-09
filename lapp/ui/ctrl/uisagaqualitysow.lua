---
--- Created by Administrator.
--- DateTime: 2023/10/19 17:05:16
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaQualitySow:LWnd
local UISagaQualitySow = LxWndClass("UISagaQualitySow", LWnd)

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaQualitySow:UISagaQualitySow()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaQualitySow:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaQualitySow:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaQualitySow:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitList()
end


function UISagaQualitySow:OnDrawQualityCell(list,item,itemdata,itempos)
	local bgTrans = self:FindWndTrans(item,"bg")

	local QuaImgDivTrans = self:FindWndTrans(bgTrans,"QuaImgDiv")
	local QuaImgTrans = self:FindWndTrans(QuaImgDivTrans,"QuaImg")

	local GameObjectTrans = self:FindWndTrans(bgTrans,"GameObject")
	local descTrans = self:FindWndTrans(GameObjectTrans,"desc")
	local effectTrans = self:FindWndTrans(GameObjectTrans,"effect")

	if QuaImgTrans then
		self:SetWndEasyImage(QuaImgTrans,itemdata.icon,function()
			CS.ShowObject(QuaImgTrans,true)
		end)
	end

	if descTrans then
		local desc = ccLngText(itemdata.desc)
		self:SetWndText(descTrans,desc)
	end

	if effectTrans then
		local effect = ccLngText(itemdata.effect)
		self:SetWndText(effectTrans,effect)
	end
end

function UISagaQualitySow:InitList()
	local list = {}
	for k,v in pairs(GameTable.CharacterQualityDescRef) do
		table.insert(list,v)
	end
	table.sort(list,function(v1,v2)
		return v1.sort < v2.sort
	end)

	local uiList = self:GetUIScroll("quaList")
	uiList:Create(self.mDescList,list,function(...) self:OnDrawQualityCell(...) end)
end

function UISagaQualitySow:InitEvent()
	self:SetWndClick(self.mBg,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
end

------------------------------------------------------------------
return UISagaQualitySow


