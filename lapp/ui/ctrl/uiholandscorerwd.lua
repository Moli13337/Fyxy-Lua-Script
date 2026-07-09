---
--- Created by Administrator.
--- DateTime: 2024/4/1 17:33:00
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHoLandScoreRwd:LWnd
local UIHoLandScoreRwd = LxWndClass("UIHoLandScoreRwd", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHoLandScoreRwd:UIHoLandScoreRwd()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHoLandScoreRwd:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHoLandScoreRwd:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHoLandScoreRwd:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndText(self.mTitle,ccClientText(40509))
	self:SetWndText(self.mTxtBtnName,ccClientText(40510))
	self:SetWndClick(self.mBtnOk,function()
		gModelHolyLand:HolyLandRewardReq()
		self:WndClose()
	end)
	self:SetWndClick(self.mBtnClose,function()
		self:WndClose()
	end)
	local totalItem = self:GetWndArg("totalItem")
	local itemPath = gModelItem:GetItemIconByRefId(totalItem.itemId)
	self:SetWndEasyImage(self.mImgIcon,itemPath)
	self:SetWndText(self.mItemNum,totalItem.count)
	self:UpdateRewardList()
end
function UIHoLandScoreRwd:OnDrawRewardItem(list, item, itemData, index)
	local CommonUIIcon = self:FindWndTrans(item,"CommonUI/Icon")
	local ImgIcon = self:FindWndTrans(item,"Eff/ImgIcon")
	local ItemNum = self:FindWndTrans(item,"Eff/ItemNum")
	local instanceId = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(CommonUIIcon)

	-- baseClass:SetCommonReward(LItemTypeConst.TYPE_HERO, itemData.heroRefId)
	baseClass:SetHeroConfShowInfo(itemData.heroRefId,itemData.star)
	baseClass:DoApply()
	local itemPath = gModelItem:GetItemIconByRefId(itemData.itemId)
	self:SetWndEasyImage(ImgIcon,itemPath)
	self:SetWndText(ItemNum,itemData.count)
	self:SetWndClick(CommonUIIcon,function()
        -- gModelGeneral:ShowCommonItemTipWnd(itemData)
		gModelGeneral:OpenHeroStarPre({refId = itemData.heroRefId})
	end)

end

function UIHoLandScoreRwd:UpdateRewardList()
	local list = self:GetUIScroll("ScoreRwdList")
	local listData = self:GetWndArg("rwd")
	list:Create(self.mCommonList,listData,function(...) self:OnDrawRewardItem(...) end)
end


------------------------------------------------------------------
return UIHoLandScoreRwd