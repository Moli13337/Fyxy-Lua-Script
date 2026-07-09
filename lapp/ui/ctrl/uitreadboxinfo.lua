---
--- Created by Administrator.
--- DateTime: 2023/10/15 14:58:32
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UITreadBoxInfo:LWnd
local UITreadBoxInfo = LxWndClass("UITreadBoxInfo", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UITreadBoxInfo:UITreadBoxInfo()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UITreadBoxInfo:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UITreadBoxInfo:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UITreadBoxInfo:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:RefreshUI()
end

function UITreadBoxInfo:RefreshUI()
	local str =ccClientText(19400) --"奖励详情"
	self:SetWndText(self.mTitle,str)

	local boxCfg = gModelTreaFind:GetBoxRewardConfig()
	if not boxCfg then
		return
	end
	local need = boxCfg.need
	local itemdata = LxDataHelper.ParseItem_3(need)
	local nameCfg = gModelGeneral:GetCommonItemName(itemdata)

	local str =ccClientText(19424) -- "每消耗%sX%s,可领取"
	local own = gModelItem:GetNumByRefId(itemdata.itemId)
	local showStr = string.replace(str,itemdata.itemNum,nameCfg,own,nameCfg)
	self:SetWndText(self.mIntro,showStr)
	self:SetWndClick(self.mMask,function () self:WndClose() end)
	self:SetWndClick(self.mBtnYellow2,function () self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end)

	self:SetWndButtonText(self.mBtnYellow2,ccClientText(19402))
	local rewardStr = boxCfg.reward
	local dataList = LxDataHelper.ParseItem_3List(rewardStr)
	self._uiList = UIIconEasyList:New()
	self._uiList:Create(self,self.mItemList)
	self._uiList:SetIconParentPath("ItemIcon")
	self._uiList:RefreshList(dataList)

end



------------------------------------------------------------------
return UITreadBoxInfo


