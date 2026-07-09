---
--- Created by Administrator.
--- DateTime: 2024/11/15 11:29:20
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubDivineResonance:LChildWnd
local UISubDivineResonance = LxWndClass("UISubDivineResonance", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubDivineResonance:UISubDivineResonance()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubDivineResonance:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubDivineResonance:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubDivineResonance:OnStart()
	LChildWnd.OnStart(self)
	self._sliderMax = self.mSlider.parent.sizeDelta.x
	self.maxLvs = {}
	self:SetWndText(self.mTxtTitle,ccClientText(46101))
	self:SetWndText(self.mEmptyText,ccClientText(43753))
	self:SetTextTile(self.mBtnReset,ccClientText(13318))
	self:CheckOpenReward()
	self:SetWndClick(self.mBtnHelp,function() GF.OpenWnd("UIBzTips",{refId = 184}) end)
	self:SetWndClick(self.mBtnReset,function() self:OnReset() end)
	self:WndEventRecv(EventNames.DIVINE_WEAPON_TECHNOLOGY,function()
		self:UpdateSlider()
		self:UpdateList()
	end)
	self:WndEventRecv(EventNames.DIVINE_WEAPON_RESONANCE,function(reset)
		if reset then self:UpdateList() end
	end)
	self:WndEventRecv(EventNames.On_Item_Change,function()
		if not gLGameUI:FindFirstWndByName("UIDivineResonancePop") then self:UpdateList() end
	end)
	self:WndEventRecv(EventNames.ON_WND_CLOSE,function(uiname)
		if uiname ~= "UIDivineResonancePop" then return end
		self:UpdateList()
	end)
	self:InitUI()
	self:UpdateSlider()
	self:UpdateList()
end

function UISubDivineResonance:OnReset()
	local resonance = gModelDivineWeapon.resonanceMap
	local has = false
	for _, value in pairs(resonance) do
		if value and value>0 then
			has = true
			break
		end
	end
	if not has then
		GF.ShowMessage(ccClientText(46157))
		return
	end
	local resetCost = LxDataHelper.ParseItem_4(GameTable.DivineWeaponConfigRef.resetCount)
	local curNum = gModelItem:GetNumByRefId(resetCost.itemId)
	local isOk = curNum>=resetCost.itemNum
	local name = gModelItem:GetNameByRefId(resetCost.itemId)
	gModelGeneral:OpenUIOrdinTips({
		refId = 480003,
		para = {resetCost.itemNum..name},
		func = function()
			if not isOk then
				GF.ShowMessage(string.replace(ccClientText(43761),name))
			end
			gModelDivineWeapon:OnDivineWeaponResonanceResetReq()
		end,
	})
end

function UISubDivineResonance:UpdateList()
	self._IllustratedRefList = self._IllustratedRefList or {}
	local pos = nil
	if not self._uiIllustratList then
		local uiList = self:GetUIScroll("divineLinkList")
		self._uiIllustratList = uiList
		local dataList = {}
		local refs = GameTable.DivineWeaponTechnologyRef
		local group = nil
		for _, value in pairs(refs) do
			local indx = math.ceil(value.group/3)
			group = dataList[indx]
			if not group then
				group = {}
				dataList[indx] = group
			end
			table.insert(group,value)
		end
		for _, list in pairs(dataList) do
			table.sort(list,function(a, b) return a.refId<b.refId end)
		end
		--红点定位
		for index, list in ipairs(dataList) do
			local red = false
			for _, value in ipairs(list) do
				if gModelDivineWeapon:DivineWeaponTechnologyRed(value.refId) then
					pos = index
					red = true
					break
				end
			end
			if red then break end
		end

		self.listCount = #dataList
		self._IllustratedRefList = dataList
		uiList:Create(self.mCardList, dataList, function(...)
			self:OnDrawBookItem(...)
		end, UIItemList.SUPER_GRID, true)
	else
		self._uiIllustratList:DrawAllItems()
	end
	if pos and pos>1 then
		self._uiIllustratList:MoveToPos(pos)
	end
end
function UISubDivineResonance:UpdateSlider()
	local lv = 0
	local curMaxNum = 0
	local lvRefId = gModelDivineWeapon.resonanceLvRefId
	local isFull = false
	local attrStr = ""
	if lvRefId and lvRefId>0 then
		local ref = GameTable.DivineWeaponResonanceRef[lvRefId]
		isFull = ref.rankNext<=0
		local nexRef = GameTable.DivineWeaponResonanceRef[ref.rankNext]
		curMaxNum =  nexRef and nexRef.upNeed or 0
		lv = ref.level
		attrStr = ref.attr
	else
		local divineResonanceLvRef = gModelDivineWeapon:GetResonanceLvRef()
		local minLvRef = divineResonanceLvRef[1]
		lv = minLvRef.level
		curMaxNum = minLvRef.upNeed
		attrStr = minLvRef.attr
	end

	self:SetWndText(self.mTxtLv,string.replace(ccClientText(46132),lv))
	local progress = tonumber(gModelDivineWeapon.expNums or 0)
	self:SetWndText(self.mTxtProgress,isFull and ccClientText(42021) or progress.."/"..curMaxNum)
	-- progress = math.min(progress, self._sliderMax)
	local size = self.mSlider.sizeDelta
	local rate = progress/math.max(curMaxNum,progress)
	self.mSlider.sizeDelta = Vector2( rate* self._sliderMax, size.y)

	self:UpdateAttrs(attrStr)
end

-- 图鉴 item
function UISubDivineResonance:OnDrawBookItem(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		local itemTran = {}
		for i = 1, 9 do
			local iconBg  = self:FindWndTrans(item, "Items/IconBg".. i)
			itemTran[i] = {
				iconBg = iconBg,
				Icon = CS.FindTrans(iconBg, "Icon"),
				UIText = self:FindWndTrans(iconBg, "UIText"),
				redPoint = self:FindWndTrans(iconBg,"RedPoint")
			}
		end
		local imgBg = self:FindWndTrans(item,"ImgBg")
		itemCache = {
			imgBg = imgBg,
			items = itemTran
		}
		self:SetComponentCache(instanceID, itemCache)
		self:SetWndEasyImage(itemCache.imgBg,itempos~=self.listCount and "weapon_skill_tree" or "weapon_skill_tree_1",nil,true)
	end

	local ref = itemdata
	for i, itemTran in ipairs(itemCache.items) do
		local data = ref[i]
		if data then
			local curLv = gModelDivineWeapon:GetDivineCurResonanceLv(data.refId) or 0
			local maxLv = self.maxLvs[data.refId]
			if not maxLv then
				local cfgs = gModelDivineWeapon:GetDiviWeaponResonanceLvRef(data.refId)
				maxLv = cfgs[#cfgs].level
				self.maxLvs[data.refId] = maxLv
			end
			if itemTran.UIText then self:SetWndText(itemTran.UIText,curLv.."/"..maxLv) end
			LxUiHelper.SetXTextColor(itemTran.UIText,LUtil.ColorByHex(curLv >0 and "51FF00ff" or "ffffffff"))
			self:SetWndEasyImage(itemTran.Icon,data.icon,nil,i==1)
			self:SetWndEasyImage(itemTran.iconBg,data.iconBg)
			local image = self:FindWndImage(itemTran.iconBg)
			image.enabled = not string.isempty(ref.iconBg)
			CS.ShowObject(itemTran.redPoint,gModelDivineWeapon:DivineWeaponTechnologyRed(data.refId))
			self:SetWndClick(itemTran.Icon,function()
				GF.OpenWnd("UIDivineResonancePop",{refId =data.refId})
			end)
		else
			CS.ShowObject(itemTran.iconBg,false)
		end
	end
end


function UISubDivineResonance:UpdateAttrs(attr)
	local uiAttrList = self._uiAttrList
	local attrList = LxDataHelper.ParseAttrList(attr) --gModelDivineWeapon:GetResonanceAttr()
	if uiAttrList then
		uiAttrList:RefreshList(attrList)
	else
		uiAttrList = self:GetUIScroll("DivineResonance")
		self._uiAttrList = uiAttrList
		uiAttrList:Create(self.mListAttrs,attrList,function(...) self:OnDrawAttrCell(...) end)
	end
	CS.ShowObject(self.mEmptyText,#attrList<1)
end
function UISubDivineResonance:OnWndRefresh()
	LWnd.OnWndRefresh(self)
	self:CheckOpenReward()
end

function UISubDivineResonance:CheckOpenReward()
	local rwds = gModelDivineWeapon.resonanceRewards
	if #rwds>0 then
		local itemList = {}
		local itemId = GameTable.DivineWeaponConfigRef.resonanceId
		local totalNum = 0
		for k, v in ipairs(rwds) do
			local ref = GameTable.DivineWeaponResonanceCountRef[v]
			totalNum = totalNum+ref.divineWeaponNum
			table.insert(itemList, ref)
		end
		local totalItem = {itemId = itemId,count = totalNum}
		GF.OpenWnd("UIDivineScoreRwd",{totalItem = totalItem ,ScoreRwdList = itemList})
	end
end

function UISubDivineResonance:OnDrawAttrCell(list,item,itemdata,itempos)
	local AttrIcon = self:FindWndTrans(item,"AttrIcon")
	local AttrName = self:FindWndTrans(item,"AttrName")
	local AttrValue = self:FindWndTrans(item,"AttrValue")
	local numType,refId,value = itemdata.attrtType or itemdata.type,itemdata.attrRefId or itemdata.refId,itemdata.attrNum or itemdata.value
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
		-- if type(valueStr) == "number" then
		-- 	valueStr = LUtil.NumberCoversion(valueStr)
		-- end
		self:SetWndText(AttrValue,"+"..valueStr)
	end
end

------------------------------------------------------------------
return UISubDivineResonance