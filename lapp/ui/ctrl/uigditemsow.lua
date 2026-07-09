---
--- Created by Administrator.
--- DateTime: 2023/10/13 16:01:58
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdItemSow:LWnd
local UIGdItemSow = LxWndClass("UIGdItemSow", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdItemSow:UIGdItemSow()
	---@type table<number,CommonIcon>
	self._uiCommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdItemSow:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	self._uiCommonList = nil

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdItemSow:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdItemSow:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitTxt()
	self:InitEvent()
	self:InitItemList()
end

function UIGdItemSow:InitItemList()

	-- local list = gModelTreasure:GetItemShowList()

	-- local uiItemList = self._uiItemList
	-- if uiItemList then
	-- 	uiItemList:RefreshList(list)
	-- else
	-- 	uiItemList = self:GetUIScroll("uiItemList")
	-- 	self._uiItemList = uiItemList
	-- 	uiItemList:Create(self.mItemList,list,function(...) self:OnDrawItemCell(...) end,UIItemList.WRAP)
	-- end
end

function UIGdItemSow:InitTxt()
	self:SetWndText(self.mTitleText,ccClientText(13016))
	self:SetWndText(self.mDescTxt,ccClientText(13017))
end

function UIGdItemSow:OnDrawItemCell(list,item,itemdata,itempos)
	local Root = self:FindWndTrans(item,"Root")
	if Root then
		local itype,refId,num = itemdata.itemType,itemdata.itemId,itemdata.itemNum
		local InstanceID = item:GetInstanceID()
		local uiCommonList = self._uiCommonList
		local baseClass = uiCommonList[InstanceID]
		if not baseClass then
			baseClass = CommonIcon:New()
			uiCommonList[InstanceID] = baseClass
			baseClass:Create(Root)
		end
		baseClass:SetCommonReward(itype, refId, num)
		baseClass:DoApply()

		self:SetWndClick(item,function()
			gModelGeneral:OpenItemInfoTipTop(refId,num)
		end)
	end
end

function UIGdItemSow:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIGdItemSow:InitData()
end

------------------------------------------------------------------
return UIGdItemSow


