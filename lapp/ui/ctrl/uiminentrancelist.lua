---
--- Created by wzz.
--- DateTime: 2024/4/2 17:45:05
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMinEntranceList:LWnd
local UIMinEntranceList = LxWndClass("UIMinEntranceList", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMinEntranceList:UIMinEntranceList()
	self._effectList = {}
	self._itemDataList = {}
	FireEvent(EventNames.ONLY_CHANGE_MAIN_BTN_ON, { index = LMainBtnIndexConst.CITY })
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMinEntranceList:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMinEntranceList:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMinEntranceList:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitHandler()
	gModelDYFeed:CheckFeedSubscribeImportance()
	local showImg = true
	CS.ShowObject(self.mSpineImg,showImg)
	if not showImg then
		self:InitSpine()
	end

	self._itemSpacing = 0 --item间距
	self._itemH = self.mItemTemplate.rect.height
	self._layoutH = self.mLayout.rect.height
	self._itemTimeList = {}

	self:SetWndText(self.mTxtCloseTips, ccClientText(41037))

	local argList = self:GetWndArgList() or {}
	self._index = argList.index or 1

	local timePara = {
		func = function()
			self:UpDateMainEntrace()
		end,
		callOnStart = false,
		loopcnt = -1,
		interval = 1,
		key = "UpDatekey"
	}
	self:TimerStartImpl(timePara)

	self:RefreshList()
end

-- 点击item
function UIMinEntranceList:OnClickItem(itemData)
	if not itemData.pb then
		gModelFunctionOpen:Jump(itemData.data.functionOpen)
		return
	end
	local model = itemData.pb.model
	local func = gModelActivity:GetShowActivityFun(model)
	if func then
		func(itemData.pb)
	end
end

function UIMinEntranceList:InitHandler()
	self:SetWndClick(self.mBtnClose, function() self:WndClose() end, LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mMask, function() self:WndClose() end, LSoundConst.CLICK_CLOSE_COMMON)

	self:WndEventRecv(EventNames.ON_PRE_FUNC_PLAY, function()
		self:RefreshList()
	end)

	self:WndEventRecv(EventNames.ON_INVASION_OPEN,function()
		self:WndClose()
	end)
end

-- 显示特效
function UIMinEntranceList:ShowEff(trans, key, isShow)
	local effName = "fx_ui_gunping_1"

	if isShow then
		if self._effectList and self._effectList[key] then
			return
		end
		self:CreateWndEffect(trans, effName, key, 100, nil, nil, nil, nil, nil, true)
	else
		self:DestroyWndEffectByKey(key)
	end
end

-- 立绘
function UIMinEntranceList:InitSpine()

	self:CreateWndSpine(self.mSpine, "LH_Jinglingnvpu01", "1", false, function(dpSpine)
		-- dpSpine:SetScale(paintMultiple)
		-- dpSpine:SetFlipX(paintFlip)
		-- local dpTrans = dpSpine:GetDisplayTrans()
		-- if dpTrans then
		-- 	dpTrans.anchorMin = Vector2.New(0.5, 0.5)
		-- 	dpTrans.anchorMax = Vector2.New(0.5, 0.5)
		-- 	dpTrans.localPosition = offset
		-- end
		CS.ShowObject(self.mSpine,true)
	end)
end

-- update
function UIMinEntranceList:UpDateMainEntrace()
	local list = gModelFunctionOpen:GetForeshowList()
	if #list ~= #self._itemDataList then
		self:RefreshList()
		return
	end

	for txtTime, tab in pairs(self._itemTimeList) do
		self:UpDateItemTxtTime(txtTime, tab)
	end
end

-- 更新item时间
function UIMinEntranceList:UpDateItemTxtTime(txtTime, tab)
	local curTime = GetTimestamp()
	local data = tab.data
	local item = tab.item

	if data.data.refId == 105 then
		CS.ShowObject(txtTime.parent, true)
		self:SetWndText(txtTime, gModelSimuFight:GetCurScheduleName())
	else
		local leftTime = 0
		if data.pb then
			leftTime = math.max(0, data.pb.endTime - curTime)
		else
			local serverData = gModelFunctionOpen:GetForeshowData(data.data.refId)
			if serverData and serverData.endTime > 0 then
				leftTime = math.max(0, serverData.endTime - curTime)
			end
		end

		if leftTime > 0 then
			local strTime = LUtil.FormatTimespanCn(leftTime)
			self:SetWndText(txtTime, strTime)
		end
		CS.ShowObject(txtTime.parent, leftTime > 0)
	end


	local showRed = false
	if data.pb then
		showRed = gModelMainCity:CheckMainActivityRed(data.pb)
	elseif data.data then
		local redId = gModelRedPoint:GetRedIdByFuncId(data.data.functionOpen)
		if redId then showRed = gModelRedPoint:CheckShowRedPoint(redId) end
	end
	self:SetRed(item, not not showRed)
end

-- 绘制item
function UIMinEntranceList:OnDrawCell(list, item, itemdata, itempos)
	local icon = self:FindWndTrans(item, "icon")
	local iconTxt = self:FindWndTrans(item, "iconTxt")
	local desc = self:FindWndTrans(item, "desc")
	local txtTime = self:FindWndTrans(item, "Img0/txtTime")

	local cellBg = itemdata.data.cellBg
	local strDesc = itemdata.data.cellNameDec
	local cellBgTxt = itemdata.data.cellBgTxt

	if not itemdata.pb then
		strDesc = ccLngText(strDesc)
	end

	self._itemTimeList[txtTime] = {data = itemdata, item = item}
	self:UpDateItemTxtTime(txtTime, {data = itemdata, item = item})

	self:SetWndEasyImage(icon, cellBg)
	self:SetWndEasyImage(iconTxt, cellBgTxt)
	self:SetWndText(desc, strDesc)

	self:SetWndClick(item, function()
		self:OnClickItem(itemdata)
	end)

	self:ShowEff(icon, itempos, true)
end

-- 刷新列表
function UIMinEntranceList:RefreshList()
	self._itemDataList = gModelFunctionOpen:GetForeshowList(true)
	local num = #self._itemDataList
	if num == 0 then
		self:WndClose()
		return
	end

	local layOutY
	local listH = 0
	if num >= 3 then
		num = 3
		listH = self._layoutH + (num - 1) * self._itemH + (num - 1) * self._itemSpacing + self._itemH * 0.5
		layOutY = -168
	else
		listH = self._layoutH + (num - 1) * self._itemH + (num - 1) * self._itemSpacing
	end
	LxUiHelper.SetSizeWithCurAnchor(self.mLayout, 1, listH)
	if layOutY then
		local pos = self.mLayout.localPosition
		self.mLayout.localPosition = Vector2(pos.x,layOutY)
	end

	local uiList = self.uiList
	if not uiList then
		uiList = self:GetUIScroll("mList")
		self.uiList = uiList
		uiList:Create(self.mList, self._itemDataList, function(...)
			self:OnDrawCell(...)
		end, UIItemList.SUPER)

		uiList:MoveToPos(self._index)
	else
		uiList:RefreshList(self._itemDataList)
	end
end

------------------------------------------------------------------
return UIMinEntranceList