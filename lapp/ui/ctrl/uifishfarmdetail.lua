---
--- Created by wzz.
--- DateTime: 2024/7/10 17:50:00
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFishFarmDetail:LWnd
local UIFishFarmDetail = LxWndClass("UIFishFarmDetail", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFishFarmDetail:UIFishFarmDetail()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFishFarmDetail:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFishFarmDetail:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFishFarmDetail:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsForeignVersion()
	
	if self._isEnus then 
		self.mTitle_Second_Bg.sizeDelta=Vector2.New(420,45)
	end 
	
	
	local refId = self:GetWndArg("refId")
	self._ref = gModelFish:GetRef(refId)
	self._viewSize = self.mPanel.sizeDelta

	self:InitTexts()
	self:InitEvents()
	self:Refresh()
end

-- 初始事件
function UIFishFarmDetail:InitEvents()
	self:SetWndClick(self.mBtnGoto, function() self:OnClickBtnGoto() end)
	self:SetWndClick(self.mMask, function() self:WndClose() end)
end

-- 刷新界面
function UIFishFarmDetail:Refresh()
	local ref = self._ref

	self:SetWndText(self.mTitle, ccLngText(ref.name))
	self:SetWndText(self.mTxtDesc, ccLngText(ref.desc))
	self:SetWndEasyImage(self.mBg, ref.cell)


	local curRef = gModelFish:GetCurRef()
	local maxUnlockRefId = gModelFish:GetMaxUnlockRefId()
	local showGoTog = ref.refId <= maxUnlockRefId and curRef.refId ~= ref.refId
	CS.ShowObject(self.mBtnGoto, showGoTog)
	if not showGoTog then
		self.mPanel.sizeDelta = Vector2(self._viewSize.x, self._viewSize.y - 60)
	end
	if not self._uiList then
		local uiList = self:GetUIScroll("mList")
		self._uiList = uiList
		local dataList = gModelFish:GetAllFishByRefId(ref.refId)
		uiList:Create(self.mList, dataList, function(...)
			self:OnDrawListItem(...)
		end, UIItemList.SUPER_GRID)
	else
		self._uiList:DrawAllItems()
	end
end

-- 点击前往
function UIFishFarmDetail:OnClickBtnGoto()
	gModelFish:SwitchFishSceneReq(self._ref.refId)

	GF.CloseWndByName("UIFishList")
	self:WndClose()
end

-- 绘制列表item项
function UIFishFarmDetail:OnDrawListItem(list, item, data, itemPos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			itemRoot = CS.FindTrans(item, "itemRoot"),
		}
		self:SetComponentCache(instanceID, itemCache)
	end

	local itemData = { itemId = data.refId, itemType = CommonIcon.ICON_TYPE_FISH }
	self:CreateCommonIconImpl(itemCache.itemRoot, itemData, { showNum = false,
		clickFunc = function()
			GF.OpenWnd("UIFishTips", { refId = data.refId, isTips = true })
		end
	})
end

-- 初始界面化文本
function UIFishFarmDetail:InitTexts()
	self:SetWndButtonText(self.mBtnGoto, ccClientText(44222))
	self:SetWndText(self.mTxtTitle, ccClientText(44230))
end

------------------------------------------------------------------
return UIFishFarmDetail