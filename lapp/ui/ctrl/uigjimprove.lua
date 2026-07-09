---
--- Created by Administrator.
--- DateTime: 2023/10/28 11:40:30
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGjImprove:LWnd
local UIGjImprove = LxWndClass("UIGjImprove", LWnd)
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGjImprove:UIGjImprove()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGjImprove:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGjImprove:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGjImprove:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:RefreshUI()

	local delayTime = gModelInstance:GetInstancePara("OnHookRewardTips")
	self:TimerStart("delayHide",delayTime,false,1)


	self:WndEventRecv(EventNames.ON_GUIDE_START,function() self:WndClose() end)
end

function UIGjImprove:OnDrawReward(list,item,itemdata,itempos)
	local bg = self:FindWndTrans(item,"bg")
	local bgIcon = self:FindWndTrans(bg,"icon")
	local bgName = self:FindWndTrans(bg,"name")
	local bgOldNum = self:FindWndTrans(bg,"oldNum")
	--local bgArrow = self:FindWndTrans(bg,"arrow")
	local bgNewNum = self:FindWndTrans(bg,"newNum")

	local iconPath = gModelItem:GetItemImgByRefId(itemdata.itemId)
	self:SetWndEasyImage(bgIcon,iconPath)
	local itemName = gModelGeneral:GetCommonItemName(itemdata)
	self:SetWndText(bgName,itemName)
	self:InitTextLineWithLanguage(bgName, -30)
	self:SetWndText(bgOldNum,tostring(itemdata.oldItemNum)..ccClientText(10714))
	local isImprove = itemdata.oldItemNum~= itemdata.newItemNum
	local color = "#5f6d7b"
	if isImprove then
		color = "lightGreen"
	end
	local str = tostring(itemdata.newItemNum)..ccClientText(10714)
	str = LUtil.FormatColorStr(str,color)
	self:SetWndText(bgNewNum,str)

end


function UIGjImprove:RefreshUI()
	local name = gModelInstance:GetCurBattleNodeName()
	self:SetWndText(self.mTitle,name)

	local dataList = self:GetWndArg("dataList")

	local uiList = self:GetUIScroll("itemList")

	local itemListTrans = gLGameLanguage:IsForeignVersion() and self.mItemListEn or self.mItemList
	CS.ShowObject(itemListTrans, true)
	uiList:Create(itemListTrans,dataList,function(...) self:OnDrawReward(...) end)
end

function UIGjImprove:DelayHide()
	local wndTrans = self:GetWndTrans()
	--local canvasGroup = wndTrans:GetComponent(typeofCanvasGroup)
	--self:TweenSeqCreate("fade",function (seq)
	--	local alphaTween = canvasGroup:DOFade(0,1)
	--	seq:Append(alphaTween)
	--	seq:OnComplete(function ()
	--		self:WndClose()
	--	end)
	--	seq:PlayForward()
	--	return seq
	--end)

	self:WndClose()

end

function UIGjImprove:OnTimer(key)
	self:DelayHide()
end




------------------------------------------------------------------
return UIGjImprove


