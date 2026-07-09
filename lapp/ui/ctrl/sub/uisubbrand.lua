---
--- Created by Administrator.
--- DateTime: 2025/6/3 15:14:59
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubBrand:LChildWnd
local UISubBrand = LxWndClass("UISubBrand", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------

local callEffectKey1 = "fx_ui_qizhen_1"
function UISubBrand:UISubBrand()

end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubBrand:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubBrand:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubBrand:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:DoBoxImgAni()
	self:InitData()
	self:OnClickEvent()
	self:UpdateAttrs()
	self:InitBtnList()
	self:InitCommnoList()
	self:WndCreateEffect()
end

function UISubBrand:DoBoxImgAni()
	local trans = self.mBoxImg
	local curPos = trans.localPosition
	local x = curPos.x
	local z = curPos.z
	local curPosY = curPos.y
	local fromPos = Vector3(x,curPosY - 10,z)
	local toPos = Vector3(x,curPosY + 10,z)
	self:TweenSeq_MoveAndBack("move_back",trans,fromPos,toPos,1.5,nil,nil,nil,nil,true,false)
end

function UISubBrand:InitData()
	if not self._btnPageList then
		local _,pages = gModelBadge:GetBadgeRefList()
		self._btnPageList = pages
	end
	self.curBtnIndx = 1
	self._btnList = {}
	self.qualityNum = gModelBadge:BadgeQualityNum()

	local badgeShowAttr = GameTable.BadgeConfigRef.badgeShowAttr
	self.showAttr = LxDataHelper.ParseAttrList(badgeShowAttr)
end
function UISubBrand:OnClickEvent()
	self:SetWndClick(self.mBtnAttr, function(...)
		GF.OpenWnd("UIBrandLvPop")
	end)
	self:SetWndText(self.mTxtShop,ccClientText(47536))
	self:SetWndClick(self.mBtnShop, function(...)
		local functionId = 14600151
		if not gModelFunctionOpen:CheckIsOpened(functionId, true) then return end
		gModelFunctionOpen:Jump(functionId)
	end)

	self:WndEventRecv(EventNames.BADGE_BAG_UPDATE,function(strengthe)
		if strengthe then
			self:UpdateAttrs()
			self:InitBtnList()
			self:InitCommnoList()
		end
	end)
	self:WndEventRecv(EventNames.On_Item_Change,function()
		self.qualityNum = gModelBadge:BadgeQualityNum()
		self:InitBtnList()
		self:InitCommnoList()
	end)
end
function UISubBrand:WndCreateEffect()
	self:CreateWndEffect(self.mEffectRoot,callEffectKey1,nil,100,false,false,nil,function(dpTrans)
		dpTrans.gameObject:SetActive(true)
	end)
end
function UISubBrand:UpdateAttrs()
	local curlist,exitAtrr = gModelBadge:GetBadgeLvAttrs(true)
	for _, value in pairs(self.showAttr) do
		if not exitAtrr[value.refId..value.type] then
			table.insert(curlist,value)
		end
	end
	if gLGameLanguage:IsRussiaVersion() then
		self:InitTextSizeWithLanguage(self.mBadgeLv, -4)
	end
	self:SetWndText(self.mBadgeLv,string.replace(ccClientText(47546),gModelBadge:GetBadgeLv()))
	local uiAttrList = self._uiAttrList
	if uiAttrList then
		uiAttrList:RefreshList(curlist)
	else
		uiAttrList = self:GetUIScroll("ChildBadgeAttrList")
		self._uiAttrList = uiAttrList
		uiAttrList:Create(self.mListAttrs,curlist,function(...) self:OnDrawAttrCell(...) end)
	end
end

function UISubBrand:OnDrawAttrCell(list,item,itemdata,itempos)
	local AttrIcon = self:FindWndTrans(item,"AttrIcon")
	local AttrName = self:FindWndTrans(item,"AttrName")
	local AttrValue = self:FindWndTrans(item,"AttrValue")
	local numType,refId,value = itemdata.type,itemdata.refId,itemdata.value
	local target = itemdata.target
	local showTarget = target ~= nil or false
	if AttrIcon then
		local icon = gModelHero:GetAttributeIconById(refId)
		self:SetWndEasyImage(AttrIcon,icon)
	end

	if AttrName then
		local name = gModelHero:GetAttributeNameById(refId)
		self:SetWndText(AttrName,name)
	end
	self:SetWndText(AttrValue,"")
	if AttrValue then
		local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,numType,value)
		self:SetWndText(AttrValue,valueStr)
	end
end

function UISubBrand:InitCommnoList(isRefresh)
	local page = self._btnPageList[self.curBtnIndx]
	local allListData = gModelBadge:GetBadgeRefList(page)

	local qualityNum = self.qualityNum
	local moveToPos
	local bJump = false
	local badgeInfo,tempRefId
	for i,v in ipairs(allListData) do
		bJump = false
		tempRefId = v.refId
		badgeInfo = gModelBadge:GetBadgeInfo(tempRefId)
		if badgeInfo then
			if badgeInfo:UpStarRedPoint(qualityNum) then
				bJump = true
			end
		else
			if self:IsCanActive(tempRefId) then
				bJump = true
			end
		end
		if bJump then
			moveToPos = i
			break
		end
	end

	---@type UIItemList
	local uiList = self._uiAllList
	if uiList then
		uiList:RefreshList(allListData)

		local superList = uiList:GetList()
		if isRefresh then
			superList:DrawAllItems(false)
		else
			superList:DrawAllItems(true)
		end
	else
		uiList = self:GetUIScroll("BadgeAllList")
		self._uiAllList = uiList
		uiList:Create(self.mCommonList, allListData, function(...)
			self:OnDrawAllItemCell(...)
		end, UIItemList.SUPER_GRID, false)
		local superList = uiList:GetList()
		superList:EnableLoadAnimation(true)
		superList:SetLoadAnimationScale(0.2, 0.15)
		superList:RefreshList(isRefresh)
	end
	if moveToPos and moveToPos > 0 then
		uiList:MoveToPos(moveToPos)
	end
end

function UISubBrand:OnDrawAllItemCell(list, item, itemdata, itempos, fromHeadTail)
	local aniNode = CS.FindTrans(item, "AniRoot")
	item = aniNode
	local uiIconRoot = CS.FindTrans(item, "IconRoot")
	local refId = itemdata.refId
	local itype = LItemTypeConst.TYPE_BADGE
	-- local TypeImg = CS.FindTrans(item, "TypeImg")
	local ImgMask = CS.FindTrans(item, "ImgMask")
	local redPointTrans = CS.FindTrans(item, "redPoint")
	local canActiva = self:FindWndTrans(aniNode, "CanActive")
	local badgeInfo = gModelBadge:GetBadgeInfo(itemdata.refId)
	local isActiva = not badgeInfo and self:IsCanActive(itemdata.refId)
	local instanceID = item:GetInstanceID()
	local baseClass, isNew = self:GetCommonIcon(instanceID)
	if isNew then
		baseClass:Create(self:FindWndTrans(uiIconRoot, "Icon"))
		-- baseClass:EnableSupportMulti(true) --格子支持多类型重用
	end
	-- self:CheckDrawItemEffect(item, instanceID, itype, refId, itempos) --物品格子光效创建检测
	baseClass:EnableShowNum(false)
	baseClass:SetCommonReward(itype, refId, itemdata.num)
	baseClass:RefreshActiveShow()
	baseClass:SetNoShowLv(false)
	self:SetWndClick(uiIconRoot, function()
		if isActiva then
			gModelBadge:BadgeStrengthenStarReq(refId,"")
		else
			GF.OpenWnd("UIBrandTips",{refId = itemdata.refId})
		end
	end)
	baseClass:DoApply()
	local starRed = badgeInfo and badgeInfo:UpStarRedPoint(self.qualityNum)
	CS.ShowObject(canActiva, isActiva)
	CS.ShowObject(redPointTrans, isActiva or starRed)
	CS.ShowObject(ImgMask, not badgeInfo)
	self:SetTextTile(canActiva,ccClientText(19741))

	local itemNameTrans = CS.FindTrans(item, "ItemName")
	if itemNameTrans then
		local name = ""
		if not gLGameLanguage:IsForeignRegion() then
			name = ccLngText(itemdata.name)
		end
		self:SetWndText(itemNameTrans, name)
		CS.ShowObject(itemNameTrans,true)
	end

end

function UISubBrand:IsCanActive(badgeId,isTips)
	local config = GameTable.BadgeRef[badgeId]
	if config then
		local cost = LxDataHelper.ParseItem_4(config.activateCost)
		if cost and gModelGeneral:CheckItemEnough(cost.itemId,cost.itemNum,isTips) then
			return true
		end
	end
end


-- 页签按钮列表
function UISubBrand:InitBtnList()
	local uiBtnList = self._uiBtnList
	if not uiBtnList then
		uiBtnList = UIListEasy:New()
		uiBtnList:Create(self, self.mTypeBtnList)
		uiBtnList:EnableScroll(true, true)
		uiBtnList:SetFuncOnItemDraw(function(...)
			self:OnDrawBtn(...)
		end)
		self._uiBtnList = uiBtnList
	end

	for i, v in ipairs(self._btnPageList) do
		uiBtnList:AddData(i, v)
	end

	uiBtnList:RefreshList()

end
-- 页签按钮处理
function UISubBrand:OnDrawBtn(list, item, itemdata, itempos)
	local btnTrans = CS.FindTrans(item, "BtnTab1")
	if not btnTrans then
		return
	end
	local index =itempos
	local ref = GameTable.BadgePageRef[itemdata]
	local name = ccLngText(ref.name)
	local btnList = self._btnList
	local curBtn = btnList[index]
	if not curBtn then
		curBtn = btnTrans
		btnList[index] = curBtn
	end
	self:SetWndClick(curBtn, function()
		if self.curBtnIndx == itempos then return end
		LxUiHelper.FilterScrollItem(self.mTypeBtnList, itempos - 1)
		self.curBtnIndx = itempos
		self:InitBtnList()
		self:InitCommnoList()
	end, LSoundConst.CLICK_PAGE_COMMON)
	local addSize = 0
	local addLine = 0
	if gLGameLanguage:IsRussiaVersion() then
		addSize = -6
		addLine = 10
	end
	self:SetWndTabTextChild(btnTrans, name,addSize,addLine)

	local show = index == self.curBtnIndx and 0 or 1
	self:SetWndTabStatus(btnTrans, show)

	local redPointTrans = CS.FindTrans(btnTrans, "redPoint")
	if redPointTrans then
		local isShow = gModelBadge:GetBadgeActivaUpStarRedByPage(self.qualityNum,itemdata)
		CS.ShowObject(redPointTrans, isShow)
	end
end



function UISubBrand:SetWndTabTextChild(buttonTrans, str, addFontSize, addFontLine)
	if CS.IsNullObject(buttonTrans) then
		return
	end
	addFontSize = addFontSize or -2
	local offTrans = CS.FindTrans(buttonTrans, "Off/Text")
	local onTrans = CS.FindTrans(buttonTrans, "On/Text")
	local grayTrans = CS.FindTrans(buttonTrans, "Gray/Text")
	self:SetWndText(offTrans, ccLngText(str))
	self:SetWndText(onTrans, ccLngText(str))
	self:SetWndText(grayTrans, ccLngText(str))

	self:InitTextSizeWithLanguage(offTrans, addFontSize)
	self:InitTextSizeWithLanguage(onTrans, addFontSize)
	self:InitTextSizeWithLanguage(grayTrans, addFontSize)

	if addFontLine then
		self:InitTextLineWithLanguage(offTrans, addFontLine)
		self:InitTextLineWithLanguage(onTrans, addFontLine)
		self:InitTextLineWithLanguage(grayTrans, addFontLine)
	end
end

------------------------------------------------------------------
return UISubBrand