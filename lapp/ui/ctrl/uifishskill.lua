---
--- Created by wzz.
--- DateTime: 2024/7/15 21:03:10
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFishSkill:LWnd
local UIFishSkill = LxWndClass("UIFishSkill", LWnd)

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFishSkill:UIFishSkill()
	if gModelFish:HadRedSkill() then
		gModelFish:SaveLookSkill()
		FireEvent(EventNames.FISH_BASE_INFO)
	end
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFishSkill:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFishSkill:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFishSkill:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitTexts()
	self:InitEvents()
	self:Refresh()
end

-- 绘制列表item项
function UIFishSkill:OnDrawListItem(list, item, itemData, itemPos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			icon        = CS.FindTrans(item, "AniRoot/IconBg/Icon"),
			lv          = CS.FindTrans(item, "AniRoot/IconBg/Lv"),
			txtDesc     = CS.FindTrans(item, "AniRoot/TxtDesc"),
			txtValue    = CS.FindTrans(item, "AniRoot/TxtValue"),
			btnStrength = CS.FindTrans(item, "AniRoot/BtnStrength"),
			costIcon    = CS.FindTrans(item, "AniRoot/BtnStrength/Cost/1/CostIcon"),
			costNum     = CS.FindTrans(item, "AniRoot/BtnStrength/Cost/CostNum"),
			hadMax      = CS.FindTrans(item, "AniRoot/HadMax"),
		}
		self:SetComponentCache(instanceID, itemCache)
		self:SetWndButtonText(itemCache.btnStrength, ccClientText(44259))
		self:SetTextTile(itemCache.hadMax, ccClientText(44258))
	end

	self:SetWndText(itemCache.txtDesc, itemData.desc)
	self:SetWndEasyImage(itemCache.icon, itemData.icon)

	local curLev = gModelFish:GetFishSkillLevByType(itemData.type)
	local curRef = gModelFish:GetFishSkillRef(itemData.type, curLev)
	local nextRef = gModelFish:GetFishSkillRef(itemData.type, curLev + 1)
	local canUp, isMax, costItem = gModelFish:CanUpSkill(itemData.type)

	CS.ShowObject(itemCache.hadMax, isMax)
	CS.ShowObject(itemCache.btnStrength, not isMax)

	self:SetWndText(itemCache.lv, ccClientText(44260, curRef.lv))
	self:SetWndText(itemCache.txtValue, "+" .. math.round(curRef.attr * 100, 2) .. "%")

	if isMax then
		return
	end
	--self:SetWndText(itemCache.txtValue, "+" .. math.round(nextRef.attr * 100, 2) .. "%")

	self:SetWndClick(itemCache.btnStrength, function()
		self:OnClickBtnStrength(itemData.type)
	end)

	local iconPath = gModelItem:GetItemImgByRefId(costItem.itemId)
	self:SetWndEasyImage(itemCache.costIcon, iconPath)
	self:SetWndText(itemCache.costNum, costItem.itemNum)
end

-- 初始事件
function UIFishSkill:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)

	self:WndEventRecv(EventNames.FISH_SKILL_RETURN, function(...) self:Refresh(...) end)
end

-- 刷新界面
function UIFishSkill:Refresh()
	local assetIdList = gModelFish:GetFishSkillTopAssetList()
	self:SetTopAssetList(self.mTopAsset, assetIdList)

	local skillDataList = gModelFish:GetFishSkillList()
	if not self._uiList then
		local uiList = self:GetUIScroll("mList")
		self._uiList = uiList
		uiList:Create(self.mList, skillDataList, function(...)
			self:OnDrawListItem(...)
		end, UIItemList.SUPER_GRID)
	else
		self._uiList:ResetList(skillDataList)
		self._uiList:DrawAllItems()
	end
end

-- 初始界面化文本
function UIFishSkill:InitTexts()
	self:SetWndText(self.mTitle, ccClientText(44257))
	self:SetWndText(self.mTxtCloseTips, ccClientText(41037))
end

-- 点击强化按钮
function UIFishSkill:OnClickBtnStrength(type)
	if not gModelFish:CanUpSkill(type, true) then
		return
	end

	gModelFish:FishingSkillReq(type)
end

------------------------------------------------------------------
return UIFishSkill