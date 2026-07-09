---
--- Created by BY.
--- DateTime: 2023/10/28 16:29:50
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHuiYEveryDayGiftPop:LWnd
local UIHuiYEveryDayGiftPop = LxWndClass("UIHuiYEveryDayGiftPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHuiYEveryDayGiftPop:UIHuiYEveryDayGiftPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHuiYEveryDayGiftPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHuiYEveryDayGiftPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHuiYEveryDayGiftPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isForeign = gLGameLanguage:IsForeignRegion()
	
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIHuiYEveryDayGiftPop:OnClickGet()
	local getFunc = self._getFunc
	if getFunc then getFunc() end
	self:WndClose()
end

function UIHuiYEveryDayGiftPop:OnClickDes()
	local desFunc = self._desFunc
	if not desFunc then return end
	desFunc()
	self:WndClose()
end
function UIHuiYEveryDayGiftPop:InitCommand()
	local para = self:GetWndArg("para")
	if not para then return end
	local title = para.title or ""
	local des = para.des or ""
	local btnStr = para.btnStr or ""
	local rewardList = para.rewardList or {}
	local isMask = para.isMask
	self._desFunc = para.desFunc
	self._getFunc = para.getFunc

	self:SetWndText(self.mLblBiaoti,title)
	self:SetWndText(self.mDesText,des)
	self:SetWndButtonText(self.mBtnGet,btnStr,nil,nil,14)
	CS.ShowObject(self.mBtnGet,not isMask)
	CS.ShowObject(self.mBtnMask,isMask)

	local uiList = self:GetUIScroll("PopmRewardScroll")
	uiList:Create(self.mRewardScroll,rewardList,function(...) self:ListItem(...) end)
end

function UIHuiYEveryDayGiftPop:ListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local rewardRoot = self:FindWndTrans(root,"RewardRoot")
	local nameText = self:FindWndTrans(root,"NameText")
	local mask = self:FindWndTrans(root,"Mask")

	local name = gModelItem:GetNameByRefId(itemdata.itemId)

	self:SetWndText(nameText,name)

	if self._isForeign then
		CS.ShowObject(nameText,false)
	end


	CS.ShowObject(mask,itemdata.isMask)
	self:CreateCommonIconImpl(rewardRoot,itemdata)
end

function UIHuiYEveryDayGiftPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnDes, function(...) self:OnClickDes() end)
	self:SetWndClick(self.mBtnGet, function(...) self:OnClickGet() end)
end
function UIHuiYEveryDayGiftPop:InitMessage()

end
------------------------------------------------------------------
return UIHuiYEveryDayGiftPop


