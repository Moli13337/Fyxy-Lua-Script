---
--- Created by wzz.
--- DateTime: 2024/7/22 20:15:44
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFishAuto:LWnd
local UIFishAuto = LxWndClass("UIFishAuto", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFishAuto:UIFishAuto()
	self._qualityList = gModelFish:GetFishQualityList()
	self._autoData = gModelFish:GetAutoFishingData()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFishAuto:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFishAuto:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFishAuto:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isAuto = self:GetWndArg("isAuto")
	self._tabIndex = self:GetWndArg("tabIndex") or 1

	self:InitTexts()
	self:InitEvents()
	self:Refresh()
end

-- 点击tog
function UIFishAuto:OnToggleValueChanged()
	if self._tabIndex == 1 then
		self._autoData.selectedQuality = self.mTog1.isOn
	else
		self._autoData.selectedQualityFast = self.mTog1.isOn
	end
end

-- 点击tab
function UIFishAuto:OnClickBtnTab(index)
	if self._tabIndex == index then
		return
	end
	if index == 2 then
		local open = gModelFunctionOpen:CheckIsOpened(gModelFish.FastFishId, true)
		if not open then
			return
		end
	end

	if index == 2 then
		self._autoData.selectedQuality = self.mTog1.isOn
		self._autoData.selectedIllustrated = self.mTog2.isOn
		self._autoData.selectedPowerUp = self.mTog3.isOn
		self._autoData.quality = self._curQuqlity
	else
		self._autoData.selectedQualityFast = self.mTog1.isOn
		self._autoData.selectedPowerUpFast = self.mTog2.isOn
		self._autoData.qualityFast = self._curQuqlity
	end

	gModelFish:SaveAutoFishingData(self._autoData)

	self._tabIndex = index

	self:Refresh()
end

-- 点击确认按钮
function UIFishAuto:OnClickBtnConfirm()
	if self._tabIndex == 1 then
		self._autoData.selectedQuality = self.mTog1.isOn
		self._autoData.selectedIllustrated = self.mTog2.isOn
		self._autoData.selectedPowerUp = self.mTog3.isOn
		self._autoData.quality = self._curQuqlity

		FireEvent(EventNames.FISH_START_AUTO, self._autoData)
	else
		self._autoData.selectedQualityFast = self.mTog1.isOn
		self._autoData.selectedPowerUpFast = self.mTog2.isOn
		self._autoData.qualityFast = self._curQuqlity
		self._autoData.fishAutoHadFast = true

		if not gModelFish:IsAutoFishingEndTime(true) then
			GF.OpenWnd("UIFishAutoFast", { autoData = self._autoData })
		end
	end
	gModelFish:SaveAutoFishingData(self._autoData)

	self:WndClose()
end

-- 显示品质列表
function UIFishAuto:ShowQualityList(isShow)
	local angle = 0
	if isShow then
		angle = 180
	end
	self.mArrow.localEulerAngles = Vector3(0, 0, angle)

	CS.ShowObject(self.mList, isShow)
end

-- 初始事件
function UIFishAuto:InitEvents()
	self:SetWndClick(self.mBg, function() self:WndClose() end)
	self:SetWndClick(self.mBtnConfirm, function() self:OnClickBtnConfirm() end)
	self:SetWndClick(self.mBtnTab1, function() self:OnClickBtnTab(1) end)
	self:SetWndClick(self.mBtnTab2, function() self:OnClickBtnTab(2) end)
	self:SetWndToggleDelegate(self.mTog1, function() self:OnToggleValueChanged() end)

	self:SetWndClick(self.mName.parent, function() self:ShowQualityList(true) end)
	self:SetWndClick(self.mList, function() self:ShowQualityList(false) end)
	self:ShowQualityList(false)
end

-- 绘制列表项
function UIFishAuto:OnDrawItem(uiList, item, data)
	if not uiList then
		uiList = {}
		uiList.name = CS.FindTrans(item, "name")
		uiList.img = LxUiHelper.FindImageCtrl(item)
	end

	local quality = data
	local ref = gModelItem:GetQualityRef(quality)
	local strName = ccClientText(44309, ref.nameColor, ccLngText(ref.heroQualityName))
	self:SetWndText(uiList.name, ccClientText(44307, strName))

	local color
	if quality == self._curQuqlity then
		color = Color.New(1, 1, 1, 0)
	else
		color = Color.New(1, 1, 1, 1)
	end
	uiList.img.color = color

	self:SetWndClick(item, function()
		if quality == self._curQuqlity then
			return
		end
		if self._tabIndex == 1 then
			self._autoData.quality = quality
		else
			self._autoData.qualityFast = quality
		end

		self:Refresh()
		self:ShowQualityList(false)
	end)

	return uiList
end

-- 刷新界面
function UIFishAuto:Refresh()
	local strTog1, strTog2, strTog3, strTitle = "", "", "", ""
	local quality
	if self._tabIndex == 1 then
		self.mTog1.isOn = self._autoData.selectedQuality
		self.mTog2.isOn = self._autoData.selectedIllustrated
		self.mTog3.isOn = self._autoData.selectedPowerUp

		strTog1 = ccClientText(44304)
		strTog2 = ccClientText(44305)
		strTog3 = ccClientText(44306)
		strTitle = ccClientText(44303)
		quality = self._autoData.quality
	else
		strTog1 = ccClientText(44339)
		strTog2 = ccClientText(44338)
		strTitle = ccClientText(44337)
		quality = self._autoData.qualityFast

		self.mTog1.isOn = self._autoData.selectedQualityFast
		self.mTog2.isOn = self._autoData.selectedPowerUpFast
	end

	self._curQuqlity = quality

	self:SetTextTile(self.mTog1.transform, strTog1)
	self:SetTextTile(self.mTog2.transform, strTog2)
	self:SetTextTile(self.mTog3.transform, strTog3)
	self:SetWndText(self.mTitle, strTitle)
	self:SetWndTabStatus(self.mBtnTab1, self._tabIndex == 1 and LWnd.StateOn or LWnd.StateOff)
	self:SetWndTabStatus(self.mBtnTab2, self._tabIndex == 2 and LWnd.StateOn or LWnd.StateOff)

	CS.ShowObject(self.mTog1, self._tabIndex == 1 or self._tabIndex == 2)
	CS.ShowObject(self.mTog2, self._tabIndex == 1 or self._tabIndex == 2)
	CS.ShowObject(self.mTog3, self._tabIndex == 1)


	local ref = gModelItem:GetQualityRef(quality)
	local strName = ccClientText(44309, ref.nameColor, ccLngText(ref.heroQualityName))
	self:SetWndText(self.mName, ccClientText(44307, strName))
	self:SetComList(self.mList, self._qualityList, function(...) return self:OnDrawItem(...) end)

	local showRed = gModelFish:HadRedFishFast()
	self:SetRed(self.mBtnTab2, showRed)
end

-- 初始界面化文本
function UIFishAuto:InitTexts()
	self:SetWndButtonText(self.mBtnConfirm, ccClientText(44308))

	self:SetWndTabText(self.mBtnTab1, ccClientText(44336))
	self:SetWndTabText(self.mBtnTab2, ccClientText(44337))

	local open = gModelFunctionOpen:CheckIsOpened(gModelFish.FastFishId, false)
	CS.ShowObject(self.mBtnLock2, not open)
end

------------------------------------------------------------------
return UIFishAuto