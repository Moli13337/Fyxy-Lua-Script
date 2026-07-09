---
--- Created by Administrator.
--- DateTime: 2023/10/20 15:42:31
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISuBalanceTip:LWnd
local UISuBalanceTip = LxWndClass("UISuBalanceTip", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISuBalanceTip:UISuBalanceTip()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISuBalanceTip:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISuBalanceTip:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISuBalanceTip:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:OnWndRefresh()
end


function UISuBalanceTip:OnDrawItem(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootBg = self:FindWndTrans(AniRoot,"bg")
	local AniRootTitle = self:FindWndTrans(AniRoot,"title")
	local AniRootContent = self:FindWndTrans(AniRoot,"content")

	local format = ccClientText(25110)
	local roundtr = string.replace(format,itemdata.refId)
	self:SetWndText(AniRootTitle,roundtr)
	self:InitTextSizeWithLanguage(AniRootTitle, -2)
	self:SetWndText(AniRootContent,ccLngText(itemdata.description))
end


function UISuBalanceTip:OnWndRefresh()
	local str =ccClientText(25108) --"天平系统"
	self:SetWndText(self.mTitleText,str)
	str = ccClientText(25109) --"    开局双方上阵伙伴增加天平状态，每回合状态的效果不同"
	self:SetWndText(self.mIntro,str)
	str = ccClientText(10103)
	self:SetWndText(self.mCloseTip,str)

	self:SetWndClick(self.mMask,function ()
		self:WndClose()
	end)

	local datalist = gModelSimuFight:GetBalanceList()

	local uilist = self:FindUIScroll("uiList")
	if not uilist then
		uilist = self:GetUIScroll("uiList")
		uilist:Create(self.mItemList,datalist,function (...) self:OnDrawItem(...) end)
	else
		uilist:RefreshList(datalist)
	end
end

------------------------------------------------------------------
return UISuBalanceTip


