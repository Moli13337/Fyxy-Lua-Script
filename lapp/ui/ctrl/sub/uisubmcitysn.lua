---
--- Created by Administrator.
--- DateTime: 2024/7/4 17:06:55
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubMCitySn:LChildWnd
local UISubMCitySn = LxWndClass("UISubMCitySn", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubMCitySn:UISubMCitySn()
	self.skinItem = {}
	self.curSelItem = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubMCitySn:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubMCitySn:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubMCitySn:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	
	gModelPlayerSpace:OnMainCitySkinListReq()
end

function UISubMCitySn:SetTimeText(item, refId)
	local time = CS.FindTrans(item, "TimeBg")
	local timeText = CS.FindTrans(time, "TimeText")

	local str = self.activeSkins[refId]
	if str and tonumber(str) > 0 then
		local leftTime = self.activeSkins[refId] - GetTimestamp()
		self:SetWndText(timeText, LUtil.FormatTimeStr1(leftTime))
		CS.ShowObject(time, true)
	else
		CS.ShowObject(time, false)
	end
end

function UISubMCitySn:ClickLookBtn()
	if not self.showState then
        self.showState = true
    else
        self.showState = not self.showState
    end
    local img = "activity_skin_btn_1"
    if self.showState then
        img = "public_btn_icon_33_1"
        self:HideUI()
    else
        self:ShowUI()
    end
    self:SetWndEasyImage(self.mLookBtn, img)
end

function UISubMCitySn:HideUI()
    local tweenSeq = YXTween.TweenSequenceIns()
	local moveFunc = function(value)
		self:SetAnchorPos(self.mTop, Vector2.New(0, 0 + value))
		self:SetAnchorPos(self.mBottom, Vector2.New(0, 519 - value))
	end
	local moveTween = YXTween.TweenFloat(0, 600, 0.5, moveFunc):SetEase(DG.Tweening.Ease.InSine)
	tweenSeq:Append(moveTween)
	tweenSeq:PlayForward()
end

function UISubMCitySn:InitEvent()
	self:SetWndClick(self.mActiveBtn, function()
		self:ClickActiveBtn()
	end)
	self:SetWndClick(self.mLookBtn, function()
		self:ClickLookBtn()
	end)

	self:WndNetMsgRecv(LProtoIds.MainCitySkinListResp, function()
		self.activeSkins = gModelPlayerSpace:GetMainCitySkinList()
		self:InitSkinList()
		self:TimerStop("itemRunTime")
		self:TimerStart("itemRunTime", 1, false, -1)
	end)

	self:WndNetMsgRecv(LProtoIds.MainCitySkinChangeResp, function()
		self.activeSkins = gModelPlayerSpace:GetMainCitySkinList()
		self:InitSkinList()
		self:TimerStop("itemRunTime")
		self:TimerStart("itemRunTime", 1, false, -1)
	end)
end

function UISubMCitySn:InitSkinList()
	local list = {}

	local curSel = self.curSelItem
	local selData
	for _, v in pairs(GameTable.CastleSkinRef) do
		if v.typeShow == 1 then
			table.insert(list, v)
			if curSel and curSel == v.refId then
				selData = v
				self.curSelItem = nil
			end
		end
	end

	table.sort(list, function(a, b)
		return a.range < b.range
	end)

	if not selData then
		selData = list[1]
	end
	self:ClickItem(selData)

	if self.skinList then
		self.skinList:RefreshList(list)
		self.skinList:DrawAllItems()
	else
		self.skinList = self:GetUIScroll("mSkinList")
		self.skinList:Create(self.mSkinList, list, function(...) self:DrawSkin(...) end, UIItemList.SUPER_GRID)
	end
end

function UISubMCitySn:DrawSkin(_, item, data, pos)
	local image = CS.FindTrans(item, "Image")
	local nameText = CS.FindTrans(item, "NameText")
	local useTag = CS.FindTrans(item, "UseTag")
	local no = CS.FindTrans(item, "No")
	local isSel = CS.FindTrans(item, "IsSel")
	local redPoint = CS.FindTrans(item, "redPoint")

	self:SetWndEasyImage(image, data.showIcon)
	self:SetWndText(nameText, ccLngText(data.name))
	self:SetTimeText(item, data.refId)
	self.skinItem[pos] = {item = item, refId = data.refId}

	local mainCitySkin = gModelPlayer:GetMainCitySkin()
	local selfSkinType = GameTable.CastleSkinRef[mainCitySkin].type
	local type = GameTable.CastleSkinRef[data.refId].type
	CS.ShowObject(no, self.activeSkins[data.refId] == nil)
	CS.ShowObject(useTag, selfSkinType == type)
	CS.ShowObject(isSel, self.curSelItem == data.refId)

	if not string.isempty(data.item) then
		local item = LUtil.GetRefItemData(data.item)
		local isEnough = item.count <= gModelItem:GetNumByRefId(item.refId)
		CS.ShowObject(redPoint, isEnough)
	else
		CS.ShowObject(redPoint, false)
	end

	self:SetWndClick(item, function()
		self:ClickItem(data)
	end)
end

function UISubMCitySn:ClickItem(data)
	local refId = data.refId
	if self.curSelItem == refId then
		return
	end
	self.curSelItem = refId
	if self.skinList then
		self.skinList:DrawAllItems()
	end
	local cfg = GameTable.CastleSkinRef[refId]
	if cfg then
		self:SetWndEasyImage(self.mSkinImg, cfg.showIcon)
		self:SetWndText(self.mTitleText, ccLngText(cfg.name))
		if not self.activeSkins[self.curSelItem] then
			-- local item = LUtil.GetRefItemData(cfg.item)
			-- local isEnough = item.count <= gModelItem:GetNumByRefId(item.refId)
			self:SetWndButtonText(self.mActiveBtn, ccClientText(43737))
			self:SetWndButtonGray(self.mActiveBtn, false)
		else
			local mainCitySkin = gModelPlayer:GetMainCitySkin()
			local selfType = GameTable.CastleSkinRef[mainCitySkin].type
			local curType = GameTable.CastleSkinRef[self.curSelItem].type
			if selfType == curType then
				self:SetWndButtonText(self.mActiveBtn, ccClientText(18334))
				self:SetWndButtonGray(self.mActiveBtn, true)
			else
				self:SetWndButtonText(self.mActiveBtn, ccClientText(10230))
				self:SetWndButtonGray(self.mActiveBtn, false)
			end
		end

		if not string.isempty(cfg.description) then
			self:SetWndText(self.mDesText, ccLngText(cfg.description))
		end
		CS.ShowObject(self.mDes, not string.isempty(cfg.description))
		UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.mDes)
	end
end

function UISubMCitySn:ClickActiveBtn()
	if not self.activeSkins[self.curSelItem] then
		local cfg = GameTable.CastleSkinRef[self.curSelItem]
		if not string.isempty(cfg.item) then
			local item = LUtil.GetRefItemData(cfg.item)
			local isEnough = item.count <= gModelItem:GetNumByRefId(item.refId)
			if isEnough then
				local t = { { refId = item.refId, num = 1 } }
				gModelItem:OnItemUseReq(t)
			else
				GF.ShowMessage(string.replace(ccClientText(30314), ccLngText(cfg.name)))
				gModelGeneral:OpenGetWayWnd({ itemId = item.refId, srcWnd = "UIPersonAreaWin" })
			end
		end
	else
		local mainCitySkin = gModelPlayer:GetMainCitySkin()
		local selfType = GameTable.CastleSkinRef[mainCitySkin].type
		local curType = GameTable.CastleSkinRef[self.curSelItem].type
		if selfType == curType then
			return
		end
		gModelPlayerSpace:OnMainCitySkinChangeReq(self.curSelItem)
	end
end

function UISubMCitySn:OnTimer(key)
	if key == "itemRunTime" then
		for _, v in pairs(self.skinItem) do
			self:SetTimeText(v.item, v.refId)
		end
	end
end

function UISubMCitySn:ShowUI()
    local tweenSeq = YXTween.TweenSequenceIns()
	local moveFunc = function(value)
		self:SetAnchorPos(self.mTop, Vector2.New(0, 600 - value))
		self:SetAnchorPos(self.mBottom, Vector2.New(0, -81 + value))
	end
	local moveTween = YXTween.TweenFloat(0, 600, 0.5, moveFunc):SetEase(DG.Tweening.Ease.InSine)
	tweenSeq:Append(moveTween)
	tweenSeq:PlayForward()
end



------------------------------------------------------------------
return UISubMCitySn