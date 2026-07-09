---
--- Created by Administrator.
--- DateTime: 2024/11/14 15:21:49
---
------------------------------------------------------------------
local typeofUISorting = typeof(CS.YXUISorting)
local LChildWnd = LChildWnd
---@class UISubDivineList:LChildWnd
local UISubDivineList = LxWndClass("UISubDivineList", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubDivineList:UISubDivineList()
	self.effectDiZuo = gModelDivineWeapon.effectDiZuo
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubDivineList:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubDivineList:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubDivineList:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitStatic()	
	self:UpdateList()
	self:UpdateAttrs()
end

function UISubDivineList:OnClickCard(refId)
	GF.OpenWnd("UIDivineWeaponInfoWin",{refId = refId})
end


-- 卡片item
function UISubDivineList:OnDrawSpeechCard(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		local Title = CS.FindTrans(item, "Title")
		local ItemCardList = CS.FindTrans(item, "ItemCardList")
		itemCache = {
			uiTitle      = Title,
			ItemCardList = ItemCardList,
			Weapon1 = CS.FindTrans(ItemCardList, "Weapon1"),
			Weapon2 = CS.FindTrans(ItemCardList, "Weapon2"),
			Weapon3 = CS.FindTrans(ItemCardList, "Weapon3"),
			titleSize    = Title.sizeDelta,
			cardListSize = ItemCardList.sizeDelta,
		}
		self:SetComponentCache(instanceID, itemCache)
	end

	local isTitle = itemdata.quality ~= nil
	CS.ShowObject(itemCache.uiTitle, isTitle)
	CS.ShowObject(itemCache.ItemCardList, not isTitle)

	local size
	if isTitle then
		size = itemCache.titleSize
		local path = "weapon_title"..itemdata.quality.refId
		self:SetWndEasyImage(itemCache.uiTitle,path)
		self:SetTextTile(itemCache.uiTitle,string.replace(ccClientText(46106,"#"..itemdata.quality.nameColor,ccLngText(itemdata.quality.heroQualityName))))
	else
		size = itemCache.cardListSize
		for indx =1,3 do
			local data = itemdata[indx]
			local itemCard = itemCache["Weapon" .. indx]
			CS.ShowObject(itemCard, data ~= nil)
			if data then
				local icon = self:FindWndTrans(itemCard,"icon")
				local redPoint = self:FindWndTrans(itemCard,"redPoint")
				local nameTran = self:FindWndTrans(itemCard,"nameBg/UIText")
				local starRoot = self:FindWndTrans(itemCard,"starRoot")
				local SliderTrans = self:FindWndTrans(itemCard, "Slider")
				local activate = self:FindWndTrans(itemCard, "activate")
				local TxtProBar = self:FindWndTrans(itemCard,"Slider/TxtProBar")
				local level = self:FindWndTrans(itemCard,"ImgLv")
				local effect = self:FindWndTrans(itemCard,"effect")
				local iconBg = self:FindWndTrans(itemCard,"iconBg")
				local Slider = self:FindWndSlider(SliderTrans)

				local info = gModelDivineWeapon:GetDivineWeaponByRefId(data.refId)
				local starCfg = gModelDivineWeapon:GetDiviWeaponStarByRefId(data.refId)
				local quality = GameTable.RarityRef[data.quality]
				local isActivate = not not info
				self:SetWndEasyImage(icon,data.icon,nil,true)
				self:SetWndImageGray(icon,not info)
				self:SetWndText(nameTran,ccLngText(data.name))
				self:SetTextTile(activate,ccClientText(30206))
				self:SetTextTile(level,info and info.level or 0)
				LxUiHelper.SetXTextColor(nameTran,LUtil.ColorByHex(quality.nameColor))
				local curStar = info and info.star or 0
				for i = 1, starRoot.childCount do
					local starTran = starRoot:GetChild(i-1)
					local path = curStar>=i and "hero_icon_star3" or "hero_icon_star2_1"
					self:SetWndEasyImage(starTran,path)
				end
				local upStar = gModelDivineWeapon:DivineWeaponStarRedById(data.refId)
				self:SetWndClick(itemCard, function()
					if upStar and not info then
						gModelDivineWeapon:OnDivineWeaponUpStarReq(data.refId)
					else
						self:OnClickCard(data.refId)
					end
				end)
				local isRed = false
				if self.dataListRed[data.refId] == nil then
					isRed = upStar or gModelDivineWeapon:DivineWeaponUpRedById(data.refId)
					self.dataListRed[data.refId] = isRed
				else
					isRed = self.dataListRed[data.refId]
				end
				CS.ShowObject(redPoint,isRed)
				CS.ShowObject(activate,not info and upStar)
				CS.ShowObject(level,isActivate)
				CS.ShowObject(icon,not info)
				self:DestroyWndEffectByKey(effect:GetInstanceID())
				local uiSorting = effect.gameObject:GetComponent(typeofUISorting)
				if uiSorting then
					uiSorting:Destroy()
				end
				self:ActivateEffect(effect,isActivate,data.effect)
				self:DestroyWndEffectByKey(iconBg:GetInstanceID())
				local dizuoEff = self.effectDiZuo[data.quality] or  self.effectDiZuo[1]
				self:ActivateEffect(iconBg,isActivate,dizuoEff)
				if info then
					CS.ShowObject(SliderTrans,false)
					CS.ShowObject(starRoot,true)
				else
					CS.ShowObject(starRoot,false)
					CS.ShowObject(SliderTrans,true)
					local cost = starCfg[1].upNeed
					local costItem = LxDataHelper.ParseItem_4(cost)
					if costItem then
						local hasNum = gModelItem:GetNumByRefId(costItem.itemId)
						Slider.value = hasNum/costItem.itemNum
						local color = hasNum>=costItem.itemNum and "#4BFF45" or "#FF2010"
						self:SetWndText(TxtProBar,string.replace("<color=#a1#>#a2#</color>/#a3#",color,LUtil.NumberCoversion(hasNum),costItem.itemNum))
					end
				end
			end
		end
	end
	item.sizeDelta = size
end

function UISubDivineList:UpdateList()
	local pos = nil
	if not self._uiDataList then
		local refs = gModelDivineWeapon:GetDivineWeaponRef()
		local dataList = {}
		local indx = 0
		for i = 9, 1 ,-1 do
			local list = refs[i]
			if list then
				indx = indx+1
				table.insert(dataList, { quality = GameTable.RarityRef[i] })
				local tab = nil
				for i, v in ipairs(list or {}) do
					if i%3==1 then
						tab = {}
						table.insert(dataList,tab)
						indx = indx+1
					end
					table.insert(tab,v)
					if not pos and (gModelDivineWeapon:DivineWeaponStarRedById(v.refId) or gModelDivineWeapon:DivineWeaponUpRedById(v.refId)) then
						pos = math.max(indx-1,1)
					end
				end
			end
		end
		self._uiDataList = dataList
	end

	self.dataListRed = {}
	if not self._uiList then
		local uiList = self:GetUIScroll("DivineCardList")
		self._uiList = uiList

		uiList:Create(self.mCardList, self._uiDataList, function(...)
			self:OnDrawSpeechCard(...)
		end, UIItemList.SUPER, true)

		if pos then
			self._uiList:MoveToPos(pos)
		end
	else
		self._uiList:RefreshData(self._uiDataList, true)
		if pos then
			self._uiList:MoveToPos(pos)
		else
			self._uiList:DrawAllItems()
		end
	end
end


function UISubDivineList:UpdateAttrs()
	local uiAttrList = self._uiAttrList
	local divineList = gModelDivineWeapon:GetDivineWeaponByRefId()
	local attrStr = nil
	local add = 0
	local lvAttr = {}
	for _, info in pairs(divineList) do
		add = gModelDivineWeapon:GetDivineLevelAttrAdd(info.refId)
		local starRef = gModelDivineWeapon:GetCurStarRef(info.refId)
		if starRef and starRef.attr then
			attrStr = not attrStr and starRef.attr or  attrStr..","..starRef.attr
		end
		local lvRef = gModelDivineWeapon:GetCurLevelRef(info.refId)
		if lvRef and lvRef.attr then
		-- 	attrStr = not attrStr and lvRef.attr or  attrStr..","..lvRef.attr
			self:ConvertCommonAttrStrToMap(lvRef.attr,lvAttr,add)
		end

	end
	local totalAttrMap = LUtil.ConvertCommonAttrStrToMap(attrStr)
	for attrRefId, attrTypeInfo in pairs(lvAttr) do
        for attrType, attrNum in pairs(attrTypeInfo) do
			if not totalAttrMap[attrRefId] then
				totalAttrMap[attrRefId] = {}
			end
			if totalAttrMap[attrRefId][attrType] then
				totalAttrMap[attrRefId][attrType] = totalAttrMap[attrRefId][attrType]+attrNum
			else
				totalAttrMap[attrRefId][attrType] = attrNum
			end
        end
    end
	local attrs = LUtil.MapAttrToListAttr(totalAttrMap)
	if uiAttrList then
		uiAttrList:RefreshList(attrs)
	else
		uiAttrList = self:GetUIScroll("childPetList")
		self._uiAttrList = uiAttrList
		uiAttrList:Create(self.mListAttrs,attrs,function(...) self:OnDrawAttrCell(...) end)
	end
	CS.ShowObject(self.mEmptyText, #attrs == 0)
end
function UISubDivineList:ConvertCommonAttrStrToMap(str,attrList,add)
    str = str or ""
    attrList = attrList or {}
    local strList = string.split(str, ",")
    for i, v in ipairs(strList) do
        v = string.split(v, "=")
        local id = tonumber(v[1])
        local type = tonumber(v[2])
        if not attrList[id] then
            attrList[id] = {}
        end
		local value = tonumber(v[3]) + (add>0 and math.floor(tonumber(v[3])*(add/100)) or 0)
        attrList[id][type] = value + (attrList[id][type] or 0)
    end
    return attrList
end
function UISubDivineList:OnDrawAttrCell(list,item,itemdata,itempos)
	local AttrIcon = self:FindWndTrans(item,"AttrIcon")
	local AttrName = self:FindWndTrans(item,"AttrName")
	local AttrValue = self:FindWndTrans(item,"AttrValue")
	local numType,refId,value = itemdata.attrType,itemdata.attrRefId,itemdata.attrNum
	if AttrIcon then
		local icon = gModelHero:GetAttributeIconById(refId)
		self:SetWndEasyImage(AttrIcon,icon)
	end

	if AttrName then
		local name = gModelHero:GetAttributeNameById(refId)
		self:SetWndText(AttrName,name)
	end

	if AttrValue then
		local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,numType,value)
		-- if type(valueStr) == "number" and valueStr>100000 then
		-- 	valueStr = LUtil.NumberCoversion(valueStr)
		-- end
		self:SetWndText(AttrValue,"+"..valueStr)
	end
end
function UISubDivineList:InitStatic()
	self:SetTextTile(self.mImgTitle,ccClientText(46100))
	self:SetWndText(self.mAttrTitle,ccClientText(46104))
	self:SetTextTile(self.mBtnFormation,ccClientText(46105))
	self:SetWndText(self.mEmptyText,ccClientText(43753))
	self:SetWndClick(self.mBtnHelp,function() GF.OpenWnd("UIBzTips",{refId = 182}) end)
	self:SetWndClick(self.mBtnFormation,function()
		local para = {
			setTargetType = LCombatTypeConst.COMBAT_MAIN,
			returnFunc = function()
				GF.ChangeMap("LCityMap")
				GF.OpenWndBottom("UIExptrance")
				GF.OpenWndBottom("UIDivineWeaponWin",{name = "UISubDivineList"})
			end,
			retAfterSet = true,
		}
		gModelFormation:OpenSetFormationWnd(para)
	end)
	self:WndEventRecv(EventNames.DIVINE_WEAPON_UPDATE,function(isActivate)
		if isActivate then
			self:UpdateList()
			self:UpdateAttrs()
		end
	end)
	self:WndEventRecv(EventNames.On_Item_Change,function()
		local wnd = GF.FindFirstWndByName("UIDivineWeaponInfoWin")
		if wnd then return end
		self:UpdateList()
	end)
	self:WndEventRecv(EventNames.ON_WND_CLOSE,function(uiName)
		if uiName == "UIDivineWeaponInfoWin" then
			self:UpdateList()
			self:UpdateAttrs()
		end
	end)
end

function UISubDivineList:ActivateEffect(trans,isShow,effName,endFunc)
	local instance = trans:GetInstanceID()
	local effecTran = self:FindWndEffectByKey(instance)
	if effecTran then
		effecTran:SetVisible(isShow)
	elseif isShow then
		self:CreateWndEffect(trans, effName, instance, 100, false, false,nil,nil,nil,nil,nil,endFunc)
	end
end
------------------------------------------------------------------
return UISubDivineList