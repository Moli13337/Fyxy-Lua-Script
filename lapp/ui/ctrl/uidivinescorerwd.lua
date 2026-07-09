---
--- Created by Administrator.
--- DateTime: 2024/12/9 21:40:46
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDivineScoreRwd:LWnd
local UIDivineScoreRwd = LxWndClass("UIDivineScoreRwd", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDivineScoreRwd:UIDivineScoreRwd()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDivineScoreRwd:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDivineScoreRwd:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
function UIDivineScoreRwd:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndText(self.mTitle,ccClientText(46174))
	self:SetWndText(self.mTxtBtnName,ccClientText(40510))
	self:SetWndClick(self.mBtnOk,function()
		gModelDivineWeapon:OnDivineWeaponResonanceRewardReq()
		self:WndClose()
	end)
	self:SetWndClick(self.mBtnClose,function()
		self:WndClose()
	end)
	local totalItem = self:GetWndArg("totalItem")
	self.itemId = totalItem.itemId
	local itemPath = gModelItem:GetItemIconByRefId(self.itemId)
	self:SetWndEasyImage(self.mImgIcon,itemPath)
	self:SetWndText(self.mItemNum,totalItem.count)
	self:UpdateRewardList()
end
function UIDivineScoreRwd:OnDrawRewardItem(list, item, itemData, index)
	local instanceId = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceId)
	if not itemCache then
		itemCache = {
			iconBg = self:FindWndTrans(item,"ImgDivine"),
			icon = self:FindWndTrans(item,"ImgDivine/icon"),
			star = self:FindWndTrans(item,"ImgDivine/star"),
			level = self:FindWndTrans(item,"ImgDivine/level"),
			ImgIcon = self:FindWndTrans(item,"Eff/ImgIcon"),
			ItemNum = self:FindWndTrans(item,"Eff/ItemNum"),

		}
	end
	local divineWeaponId = itemData.divineWeaponId
	local divineRef = GameTable.DivineWeaponRef[divineWeaponId]
	local qualityCfg = GameTable.RarityRef[divineRef.quality]
	self:SetWndEasyImage(itemCache.iconBg,qualityCfg.iconBg)
	self:SetWndEasyImage(itemCache.icon,divineRef.icon)
	local condiStr = string.split(itemData.precondition,",")
	local star
	local level
	for _, value in ipairs(condiStr) do
		local condi = string.split(value,"=")
		if tonumber(condi[1]) == 1 then
			star = tonumber(condi[2])
		else
			level = tonumber(condi[2])
		end
	end
	local sizeDe = itemCache.star.sizeDelta
	sizeDe.x = 40*(star or 0)
	itemCache.star.sizeDelta = sizeDe
	CS.ShowObject(itemCache.star,not not star)
	CS.ShowObject(itemCache.level,not not level)
	self:SetWndText(itemCache.level,level or 0)

	local itemPath = gModelItem:GetItemIconByRefId(self.itemId)
	self:SetWndEasyImage(itemCache.ImgIcon,itemPath)
	self:SetWndText(itemCache.ItemNum,itemData.divineWeaponNum)
	self:SetWndClick(itemCache.iconBg,function()
		GF.OpenWnd("UIDivineWeaponPopTips",{refId = divineWeaponId})
	 end)
end

function UIDivineScoreRwd:UpdateRewardList()
	local list = self:GetUIScroll("ScoreRwdList")
	local listData = self:GetWndArg("ScoreRwdList")
	list:Create(self.mCommonList,listData,function(...) self:OnDrawRewardItem(...) end)
end

------------------------------------------------------------------
return UIDivineScoreRwd