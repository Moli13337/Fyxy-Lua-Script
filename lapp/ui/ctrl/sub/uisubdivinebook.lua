---
--- Created by Administrator.
--- DateTime: 2024/11/14 16:45:55
---
------------------------------------------------------------------
local typeofUISorting = typeof(CS.YXUISorting)
local LChildWnd = LChildWnd
---@class UISubDivineBook:LChildWnd
local UISubDivineBook = LxWndClass("UISubDivineBook", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubDivineBook:UISubDivineBook()
	self.effectDiZuo = gModelDivineWeapon.effectDiZuo
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubDivineBook:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubDivineBook:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubDivineBook:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:SetWndText(self.mTxtDesc,ccClientText(46107))
	self:SetTextTile(self.mTxtTitle,ccClientText(46108))
	self:SetTextTile(self.mBtnPreview,ccClientText(46023))
	self:SetWndClick(self.mBtnPreview,function() self:OnClickPreView() end)
	self:SetWndClick(self.mBtnHelp,function() self:OnHelp() end)
	self:WndEventRecv(EventNames.DIVINE_WEAPON_BOOK,function() self:UpdateList() end)
	self:WndEventRecv(EventNames.DIVINE_WEAPON_UPDATE,function() self:UpdateList() end)
	self:UpdateList()
end

function UISubDivineBook:OnHelp()
	GF.OpenWnd("UIBzTips",{refId = 185})
end

-- 图鉴 item
function UISubDivineBook:OnDrawBookItem(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			txtTitle  = CS.FindTrans(item, "TitleBg/TxtTitle"),
			card1     = CS.FindTrans(item, "Card1"),
			card2     = CS.FindTrans(item, "Card2"),
			attrItem  = CS.FindTrans(item, "Attr/AttrItem"),
			txtUpTips = CS.FindTrans(item, "TxtUpTips"),
			btnUp     = CS.FindTrans(item, "BtnUp"),
			Image     = CS.FindTrans(item, "Image"),

		}
		self:SetComponentCache(instanceID, itemCache)
	end

	local ref = itemdata
	self:SetWndText(itemCache.txtTitle, ccLngText(ref.name))

	local enough = true
	local isUpLv = true
	local refIds = string.split(ref.divineWeaponId,"|")
	local isFull = ref.upNeed<0
	for i = 1, 2 do
		local cardTran = itemCache["card" .. i]
		CS.ShowObject(cardTran,not not refIds[i])
		if refIds[i] then
			local swRef = GameTable.DivineWeaponRef[tonumber(refIds[i])]
			self:SetTextTile(cardTran,ccLngText(swRef.name))
			local icon = self:FindWndTrans(cardTran,"Icon")
			local Effect = self:FindWndTrans(cardTran,"Effect")
			self:SetWndClick(icon,function() GF.OpenWnd("UIDivineWeaponInfoWin",{refId = swRef.refId}) end)
			local info = gModelDivineWeapon:GetDivineWeaponByRefId(swRef.refId)
			local curStar = info and info.star or 0
			local starBgTran = self:FindWndTrans(cardTran,"StarBg")
			local starTran = self:FindWndTrans(starBgTran,"ImgStar")
			local sizeDe = starTran.sizeDelta
			sizeDe.x = 40*curStar
			starTran.sizeDelta = sizeDe
			sizeDe = starBgTran.sizeDelta
			sizeDe.x = 40*gModelDivineWeapon:GetMaxStar(swRef.refId)
			starBgTran.sizeDelta = sizeDe
			self:SetWndEasyImage(icon,swRef.icon)
			self:SetWndImageGray(icon,not info)
			self:DestroyWndEffectByKey(Effect:GetInstanceID())
			local eff = self.effectDiZuo[swRef.quality] or self.effectDiZuo[1]
			self:ActivateEffect(Effect,not not info,eff)
			self:DestroyWndEffectByKey(icon:GetInstanceID())
			local uiSorting = icon.gameObject:GetComponent(typeofUISorting)
			if uiSorting then
				uiSorting:Destroy()
			end
			self:ActivateEffect(icon,not not info,swRef.effect)
			if not info then enough = false end
			if not info or info.star < ref.upNeed or isFull then isUpLv = false end
		end
	end
	self:ActivateEffect(itemCache.Image,enough,"fx_sw_taozhuangjihuo_bg")
	local isActivate = gModelDivineWeapon:GetBookGroupLv(ref.group)
	local canActiva = enough and not isActivate
	self:SetWndButtonGray(itemCache.btnUp,  not (canActiva or isUpLv or isFull))
	self:SetWndButtonText(itemCache.btnUp,not isActivate and ccClientText(46117) or (isFull and ccClientText(42021) or ccClientText(43710)) )
	local color = (canActiva or isUpLv) and "#139057" or "#F62929"
	local strUpTips = (not isActivate and ccClientText(46115) or (not isFull and string.replace(ccClientText(46116),color,ref.upNeed) or ""))
	self:SetWndText(itemCache.txtUpTips, strUpTips)
	self:SetRed(itemCache.btnUp,canActiva or isUpLv)
	self:RefreshBookAttr(itemCache, ref)
	self:SetWndClick(itemCache.btnUp,function()
		if not enough then
			GF.ShowMessage(ccClientText(46118))
		elseif isFull then
			GF.ShowMessage(ccClientText(42021))
		elseif canActiva then
			gModelDivineWeapon:OnDivineWeaponRelationLevelUpReq(ref.group)
		else
			if not isUpLv then
				GF.ShowMessage(string.replace(ccClientText(46119),ref.upNeed))
			else
				gModelDivineWeapon:OnDivineWeaponRelationLevelUpReq(ref.group)
			end
		end
	end)
end

function UISubDivineBook:ActivateEffect(trans,isShow,effName)
	local instance = trans:GetInstanceID()
	local effecTran = self:FindWndEffectByKey(instance)
	if effecTran then
		effecTran:SetVisible(isShow)
	elseif isShow then
		self:CreateWndEffect(trans, effName, instance, 100, false, false)
	end
end
function UISubDivineBook:OnClickPreView()
	local title = ccClientText(41519)
	local desc = ""
	local activateList = gModelDivineWeapon.divineWeaponBook or {}
	local attrStr = nil
	local refs = GameTable.DivineWeaponHandbookRef
	for group, lvRefId in pairs(activateList) do
		local attr = refs[lvRefId] and refs[lvRefId].attr
		if not string.isempty(attr) then
			if not attrStr then
				attrStr = attr
			else
				attrStr = attrStr..","..attr
			end
		end
	end
	local totalAttrMap = LUtil.ConvertCommonAttrStrToMap(attrStr)
	local attrs = LUtil.MapAttrToListAttr(totalAttrMap)
	if #attrs == 0 then
		GF.ShowMessage(ccClientText(43753))
		return
	end
	GF.OpenWnd("UIPeConversionAttr",{title=title,desc=desc,attrList = attrs})
end

function UISubDivineBook:UpdateList()
	self._IllustratedRefList = self._IllustratedRefList or {}
	local dataList = {}
	local refs = gModelDivineWeapon:GetDiviWeaponBookRef()
	local cfgs = GameTable.DivineWeaponHandbookRef
	for group, list in pairs(refs) do
		local lvRefId = gModelDivineWeapon:GetBookGroupLv(group)
		if not lvRefId or lvRefId<=0 then
			table.insert(dataList,list[1])
		else
			table.insert(dataList,cfgs[lvRefId])
		end
	end
	table.sort(dataList,function(a, b)  return a.refId<b.refId end)
	if not self._uiIllustratList then
		local uiList = self:GetUIScroll("divineBookList")
		self._uiIllustratList = uiList
		self._IllustratedRefList = dataList
		uiList:Create(self.mBookList, dataList, function(...)
			self:OnDrawBookItem(...)
		end, UIItemList.SUPER, true)

		local pos = 1
		if pos then
			for index, ref in ipairs(dataList) do
				local refIds = string.split(ref.divineWeaponId,"|")
				local info
				local enough = true
				local isUpLv = true
				local isFull = ref.upNeed<0
				for _, refId in ipairs(refIds) do
					info = gModelDivineWeapon:GetDivineWeaponByRefId(tonumber(refId))
					if not info then enough = false end
					if not info or info.star < ref.upNeed or isFull then isUpLv = false end
				end
				local isActivate = gModelDivineWeapon:GetBookGroupLv(ref.group)
				local canActiva = enough and not isActivate
				if canActiva or isUpLv then
					pos = index
					break
				end
			end
			self._uiIllustratList:MoveToPos(pos)
		end
	else
		self._uiIllustratList:RefreshList(dataList)
		self._uiIllustratList:DrawAllItems()
	end
end

function UISubDivineBook:RefreshBookAttr(itemCache, ref)
	itemCache._uiAttrList = itemCache._uiAttrList or {}
	local dataList = LxDataHelper.ParseAttrList(ref.attr)
	for i, data in ipairs(dataList) do
		local tab = itemCache._uiAttrList[i]
		if not tab then
			local obj = CS.InstantObject(itemCache.attrItem.gameObject)
			local trans = obj.transform
			trans:SetParent(itemCache.attrItem.parent, false)
			tab                      = {}
			tab.obj                  = obj
			tab.trans                = trans
			tab.icon                 = CS.FindTrans(trans, "AttrIcon")
			tab.txt                  = CS.FindTrans(trans, "AttrValue")
			tab.name                 = CS.FindTrans(trans, "AttrName")
			itemCache._uiAttrList[i] = tab
		end

		CS.ShowObject(tab.trans, true)

		local iconPath = gModelHero:GetAttributeIconById(data.refId)
		self:SetWndEasyImage(tab.icon, iconPath)

		local name = gModelHero:GetAttributeNameById(data.refId)
		self:SetWndText(tab.name, name)

		local val = gModelHero:GetAttributeValueNoNameByIdAndVal(data.refId, data.type, data.value)
		self:SetWndText(tab.txt, val)
	end
	CS.ShowObject(itemCache.attrItem,false)
	for i = #dataList + 1, #itemCache._uiAttrList do
		CS.ShowObject(itemCache._uiAttrList[i].trans, false)
	end
end

------------------------------------------------------------------
return UISubDivineBook