---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBf:LWnd
local UIBf = LxWndClass("UIBf", LWnd)

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBf:UIBf()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBf:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBf:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBf:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self._isVie = gLGameLanguage:IsVieVersion()
	self._isJapaness  =gLGameLanguage:IsJapanVersion()
	self:InitEvent()
	self:InitData()

	-- CS.ShowObject(self.mType6Txt,self._starNum == ModelFormation.TYPE_BUFF_FUSION)

	self:SetStaticContent()

	-- self:InitRaceTypeList()
	-- self:InitCampList()

	local data = gModelFormation:GetCombatCampById(self._starNum)
	if data then
		local ref
		if self._starNum == ModelFormation.TYPE_BUFF_FUSION then
			ref = gModelHero:GetRestrainDetailsEffByRefId(1)
		elseif data.hero == ModelSpiritHero.SPIRITHERO_RACE then
			--- 应策划需求，特殊处理
			ref = gModelHero:GetRestrainDetailsEffByRefId(1)
		else
			ref = gModelHero:GetRestrainDetailsEffByRefId(self._starNum)
		end
		if ref then
			local str = ccClientText(10104)
			local addStr = self:GetStr(ref, true, true)
			str = string.replace(str, addStr)
			self:SetWndText(self.mHurtTxt, str)
			self:InitTextLineWithLanguage(self.mHurtTxt, -30)
			self:InitTextSizeWithLanguage(self.mHurtTxt, -2)
		end
	end

	self:InitAttrList()
	
	if gLGameLanguage:IsJapanVersion() then 
		local content=CS.FindTrans(self.mScrollView,"Viewport/Content") 
		LxUiHelper.SetSizeWithCurAnchor(content,1,750)
		local moveRoot = CS.FindTrans(content,"MoveRoot")
		self:SetAnchorPos(moveRoot,Vector2.New(0,40))
		-- self:SetAnchorPos(self.mImg_MoveLine,Vector2.New(0,-180))
		-- self:SetAnchorPos(self.mAttrRoot4,Vector2.New(-191.3,-257))
	end 
end

function UIBf:GetStr(ref, isShow, ignore)
	local temp = "#a1# +#a2#"
	if ignore then
		if isShow ~= nil then
			if isShow == true then
				temp = "#a1# <color=#139057>+#a2#</color>"
			elseif isShow == 1 then
				temp = "<color=#5f6d7b>#a1# +#a2#</color>"
			end
		end
	end
	local addStr = ""
	local restrainList = string.split(ref, ",")
	for i = 1, #restrainList do
		local data = restrainList[i]
		local dataList = string.split(data, "=")
		local attr, campType, num = tonumber(dataList[1]), tonumber(dataList[2]), tonumber(dataList[3])
		local attrName = gModelHero:GetAttributeNameById(attr)
		local value = num * 100 .. "%"

		local str1 = string.replace(temp, attrName, value)
		if string.isempty(addStr) then
			addStr = str1
		else
			addStr = addStr .. "  " .. str1
		end
	end
	return addStr
end

function UIBf:GetCampList()
	local list = {}
	local ref = gModelFormation:GetCombatCampEffBySelType(self._starNum)
	table.sort(ref, function(ref1, ref2)
		return ref1.refId < ref2.refId
	end)
	if self._starNum == ModelFormation.TYPE_BUFF_FUSION then
		local raceActNumList = self._raceActNumList
		local info = raceActNumList[ModelFormation.TYPE_BUFF_FUSION_RACE]
		local refId
		if info then
			refId = info.refId
		else
			refId = ref[1].refId
		end
		for i, v in ipairs(ref) do
			if v.refId == refId then
				table.insert(list, v)
			end
		end
	else
		for i, v in ipairs(ref) do
			table.insert(list, v)
		end
	end
	return list
end

function UIBf:OnDrawRaceCell(list, item, itemdata, itempos, fromHeadTail)
	local icon = itemdata.icon
	local refId = itemdata.refId
	local raceTypeList = self._raceTypeList
	if table.isempty(raceTypeList) then
		raceTypeList = {}
	end
	local raceActNumList = self._raceActNumList
	local keyActList = self._keyActList
	local iconTrans = CS.FindTrans(item, "Icon")
	if iconTrans then
		self:SetWndEasyImage(iconTrans, icon)
		self:SetWndClick(iconTrans, function()
			self:IconClick(itemdata)
		end)
	end
	local selImgTrans = CS.FindTrans(item, "SelImg")
	if selImgTrans then
		local isShow = false
		if refId == self._starNum then
			isShow = true
		end
		CS.ShowObject(selImgTrans, isShow)
	end
	local NumTxtTrans = CS.FindTrans(item, "NumTxt")
	if NumTxtTrans then
		local data = keyActList[itemdata.hero]
		if not data then
			CS.ShowObject(NumTxtTrans, false)
		else
			if itemdata.hero == ModelFormation.TYPE_BUFF_FUSION_RACE then
				self:SetWndText(NumTxtTrans, 1)
			else
				self:SetWndText(NumTxtTrans, raceActNumList[itemdata.hero].actLevel)
			end
			CS.ShowObject(NumTxtTrans, true)
		end
	end
end

function UIBf:SetAttr(node, ref, heroMap)
	local str = ccLngText(ref.conDec)
	local str2, attrMap = self:AttrStrFormat(ref.value)

	local xuitxt = self:FindWndText(node)
	local color
	local tab = string.split(ref.condition, "=")
	local num = checknumber(tab[2])

	local addNum = 0
	for _, hero in pairs(heroMap) do
		if num == self._raceTypeList[hero] and not self._hadUse[hero] then
			addNum = addNum + 1
			self._hadUse[hero] = addNum
		end
	end

	if addNum > 0 then
		color = "139057"
		self:AddAttrMap(attrMap, addNum)
	else
		color = "787878"
	end
	color = LUtil.ColorByHex_6(color)
	self:SetXUITextColor(xuitxt, color)
	self:SetWndText(node, str .. str2)
end

--
function UIBf:InitAttrList()
	local refList = gModelFormation:GetCombatCampRef()
	for k, v in ipairs(refList) do
		local root = self["mIcon" .. k]
		local icon = CS.FindTrans(root, "Icon")
		local txtBg = CS.FindTrans(root, "TxtBg")
		self:SetWndEasyImage(icon, v.icon)

		local num = self._raceTypeList[v.hero] or 0
		self:SetTextTile(txtBg, num)
		CS.ShowObject(txtBg, num > 0)
	end

	local root = self["mIcon" .. 7]
	local icon = CS.FindTrans(root, "Icon")
	local txtBg = CS.FindTrans(root, "TxtBg")
	self:SetWndEasyImage(icon, refList[7].icon)

	local num = self._raceTypeList[refList[7].hero] or 0
	self:SetTextTile(txtBg, num)
	CS.ShowObject(txtBg, num > 0)

	self._totalAttrMap = {}
	self._hadUse = {}
	-- 取相应种类的一个做显示即可
	local list1, list2, heroMap1, heroMap2, list3, heroMap3 = gModelFormation:GetFormationBuffUiShow()
	for k, v in ipairs(list1) do
		local obj = LxUnity.InstantObject(self.mTxtAttrObj)
		obj:SetActive(true)
		obj.transform:SetParent(self.mAttrRoot1, false)
		if self._isVie or self._isJapaness then
            self:InitTextSizeWithLanguage(obj, -5)
        end
		self:SetAttr(obj.transform, v, heroMap1)
	end
	for k, v in ipairs(list2) do
		local obj = LxUnity.InstantObject(self.mTxtAttrObj)
		obj:SetActive(true)
		obj.transform:SetParent(self.mAttrRoot2, false)
		if self._isVie or self._isJapaness  then
            self:InitTextSizeWithLanguage(obj, -4)
        end
		self:SetAttr(obj.transform, v, heroMap2)
	end
	for k, v in ipairs(list3) do
		local obj = LxUnity.InstantObject(self.mTxtAttrObj)
		obj:SetActive(true)
		obj.transform:SetParent(self.mAttrRoot4, false)
		self:SetAttr(obj.transform, v, heroMap3)
	end

	local obj = LxUnity.InstantObject(self.mTxtAttrObj)
	obj:SetActive(true)
	obj.transform:SetParent(self.mAttrRoot3, false)
	self:SetWndText(obj.transform, ccClientText(19793))
	self:SetWndText(self.mTxtYoahui,self.yaohui)
	CS.ShowObject(self.mTxtBgYaohui,self.yaohui>0)
    if self._isVie or self._isJapaness  then
        LxUiHelper.SetSizeWithCurAnchor(obj.transform, 0, 500)
        self:InitTextLineWithLanguage(obj, 0)
    end
	self:RefreshTotalAttrl()
end

function UIBf:AddAttrMap(fromMap, multiple)
	for k, v in pairs(fromMap) do
		if not self._totalAttrMap[v.attr] then
			self._totalAttrMap[v.attr] = v
			v.num = v.num * multiple
		else
			self._totalAttrMap[v.attr].num = self._totalAttrMap[v.attr].num + v.num  * multiple
		end
	end
end

function UIBf:InitCampList()
	--[[	local uiCampList = self._uiCampList
	if not uiCampList then
		uiCampList = UIListEasy:New()
		uiCampList:Create(self,self.mCampList)
		uiCampList:SetFuncOnItemDraw(function(...)
			self:OnDrawCampCell(...)
		end)
		self._uiCampList = uiCampList
	end
	uiCampList:RemoveAll()
	local ref = gModelFormation:GetCombatCampEffBySelType(self._starNum)
	table.sort(ref,function(ref1,ref2)
		return ref1.refId < ref2.refId
	end)
	for i,v in ipairs(ref) do
		uiCampList:AddData(i,v)
	end
	uiCampList:RefreshList()]]
	local list = self:GetCampList()
	local uiCampList = self._uiCampList
	if uiCampList then
		uiCampList:RefreshList(list)
	else
		uiCampList = self:GetUIScroll("uiCampList")
		self._uiCampList = uiCampList
		uiCampList:Create(self.mCampList, list, function(...) self:OnDrawCampCell(...) end, UIItemList.WRAP)
	end
	--[[	local enable = #list > 4
	uiCampList:EnableScroll(enable)]]
end

function UIBf:InitEvent()
	self:SetWndClick(self.mMaskBg, function()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn, function()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mHelpBtn, function()
		GF.OpenWnd("UIGuePost", { refId = 1001, notTriggerGuide = true })
	end)
	CS.ShowObject(self.mHelpBtn, false)
end

function UIBf:OnDrawCampCell(list, item, itemdata, itempos, fromHeadTail)
	local selImgTrans = CS.FindTrans(item, "SelImg")
	local starImg = "risk_star_9"
	local isShow = false
	if selImgTrans then
		local raceActNumList = self._raceActNumList
		local raceTypeList = self._raceTypeList
		local raceType = itemdata.hero
		local rafeData = raceTypeList[raceType]
		if rafeData then
			local level = itemdata.level
			local raceActData = raceActNumList[raceType]
			if raceActData and raceActData.actLevel == level and self._keyActList[raceType] then
				isShow = true
				starImg = "risk_star_10"
			end
		end
		self:SetWndEasyImage(selImgTrans, starImg)
	end

	local DescTrans = CS.FindTrans(item, "DescTxt")
	local str = ccClientText(10104)
	if DescTrans then
		local desc = ccLngText(itemdata.conDec)
		local data = itemdata.value
		local addStr = self:GetStr(data, isShow, isShow)
		local CTUIText = self:FindWndText(DescTrans)
		if CTUIText then
			if isShow then
				str = string.format("<color=#734f22>%s %s</color>", desc, addStr)
			else
				str = string.format("<color=#9f835c>%s %s</color>", desc, addStr)
			end
			self:SetXUITextText(CTUIText, str)
		end
	end
end

function UIBf:InitData()
	self._refIdList = self:GetWndArg("refIdList")

	self._starNum = 10
	local raceTypeList,yaohui = gModelFormation:GetRaceList(self._refIdList)
	self._raceTypeList = raceTypeList or {}
	-- local haveRaceNum = table.keysize(self._raceTypeList)
	-- if haveRaceNum == 5 then
	-- 	self._raceTypeList[ModelFormation.TYPE_BUFF_FUSION_RACE] = 1
	-- end

	self.yaohui = yaohui
	local str = ""
	local raceActNumList, sortRaceActList, isStandard = gModelFormation:GetActivityData(raceTypeList)
	local len = #sortRaceActList
	if isStandard then
		local type6RefId = sortRaceActList[1].refId
		local ref = gModelFormation:GetCombatCampEffByRefId(type6RefId)
		str = ref.value
	else
		for i, v in ipairs(sortRaceActList) do
			local ref = gModelFormation:GetCombatCampEffByRefId(v.refId)
			if string.isempty(str) then
				str = ref.value
			else
				str = str .. "," .. ref.value
			end
		end
	end
	self._raceActNumList = raceActNumList

	local actList = gModelFormation:GetActRefIdlist(raceTypeList)
	local effRefId
	local smallRace = nil
	for i, v in ipairs(actList) do
		local raceActData = raceActNumList[v]
		if raceActData then
			if not smallRace then
				smallRace = raceActData.raceType
				effRefId = raceActData.effRefId
			else
				smallRace = math.min(raceActData.raceType, smallRace)
				effRefId = raceActData.effRefId
			end
		end
		--if raceActData and (not smallRace) then
		--	smallRace = raceActData.raceType
		--elseif raceActData.raceType < smallRace then
		--	smallRace = raceActData.raceType
		--end
	end
	if not smallRace then smallRace = 1 end
	if not effRefId then effRefId = 1 end
	local combatCampRef = gModelFormation:GetCombatCampById(effRefId)
	if combatCampRef then
		self._starNum = tonumber(combatCampRef.group)
	end
	self._actList = actList

	self._keyActList = {}
	for i, v in ipairs(actList) do
		self._keyActList[v] = true
	end

	-- local allAttr = {}
	-- if not string.isempty(str) then
	-- 	local strList = string.split(str, ",")
	-- 	for i = 1, #strList do
	-- 		local data = strList[i]
	-- 		local dataList = string.split(data, "=")
	-- 		local attr, campType, num = tonumber(dataList[1]), tonumber(dataList[2]), tonumber(dataList[3])
	-- 		local attrList = allAttr[attr]
	-- 		if not attrList then
	-- 			attrList = {}
	-- 			allAttr[attr] = attrList
	-- 		end
	-- 		local campList = attrList[campType]
	-- 		if not campList then
	-- 			campList = 0
	-- 			attrList[campType] = campList
	-- 		end
	-- 		attrList[campType] = attrList[campType] + num
	-- 	end
	-- end

	-- str = ccClientText(10105)
	-- local addStr = ""
	-- local temp = ccClientText(20121)
	-- for k, v in pairs(allAttr) do
	-- 	local attr = gModelHero:GetAttributeNameById(k)
	-- 	local value
	-- 	for _k, _v in pairs(v) do
	-- 		value = _v * 100 .. "%"
	-- 	end
	-- 	local str1 = string.replace(temp, attr, value)
	-- 	if string.isempty(addStr) then
	-- 		addStr = str1
	-- 	else
	-- 		addStr = addStr .. "  " .. str1
	-- 	end
	-- end
	-- if string.isempty(addStr) then
	-- 	addStr = ccClientText(18317)
	-- end
	-- str = string.replace(str, addStr)
	-- self:SetWndText(self.mAllCampTxt, str)
	-- self:InitTextSizeWithLanguage(self.mAllCampTxt, -4)
	-- self:InitTextLineWithLanguage(self.mAllCampTxt, -30)


	if self._starNum == 10 then
		self._starNum = 1
	end
end

function UIBf:InitRaceTypeList()
	--[[	local uiRaceList = self._uiRaceList
	if not uiRaceList then
		uiRaceList = UIListWrap:New()
		uiRaceList:Create(self,self.mRaceList)
		uiRaceList:EnableScroll(false)
		uiRaceList:SetFuncOnItemDraw(function(...)
			self:OnDrawRaceCell(...)
		end)
		self._uiRaceList = uiRaceList
	end
	uiRaceList:RemoveAll()
	local campRef = gModelFormation:GetCombatCampRef()
	for i,v in ipairs(campRef) do
		uiRaceList:AddData(i,v)
	end]]

	local list = self:GetRaceTypeList()
	local uiRaceList = self._uiRaceList
	if uiRaceList then
		uiRaceList:RefreshList(list)
	else
		uiRaceList = self:GetUIScroll("uiRaceList")
		self._uiRaceList = uiRaceList
		uiRaceList:Create(self.mRaceList, list, function(...) self:OnDrawRaceCell(...) end)
	end
end

function UIBf:RefreshTotalAttrl()
	local list = {}
	for k, v in pairs(self._totalAttrMap) do
		table.insert(list, v)
	end
	table.sort(list, function(a, b)
		if a.index ~= b.index then
			return a.index < b.index
		end
		return a.attr < b.attr
	end)

	local str = ccClientText(10105)
	local addStr = ""
	local temp = ccClientText(20121)

	for k, v in ipairs(list) do
		local name = gModelHero:GetAttributeNameById(v.attr)
		local value = v.num * 100 .. "%"
		local str1 = string.replace(temp, name, value)
		if string.isempty(addStr) then
			addStr = str1
		else
			addStr = addStr .. "  " .. str1
		end
	end
	if string.isempty(addStr) then
		addStr = ccClientText(18317)
	end
	str = string.replace(str, addStr)
	self:SetWndText(self.mAllCampTxt, str)
	self:InitTextSizeWithLanguage(self.mAllCampTxt, -4)
	self:InitTextLineWithLanguage(self.mAllCampTxt, -30)
end

function UIBf:SetStaticContent()
	self:SetWndText(self.mTitleText, ccClientText(20120))
	self:SetTextTile(self.mImg2, ccClientText(19792))
	-- self:SetWndText(self.mType6Txt,ccClientText(10143))
	-- self:InitTextSizeWithLanguage(self.mType6Txt, -4)
	-- self:InitTextLineWithLanguage(self.mType6Txt, -30)
end

function UIBf:IconClick(data)
	local old = self._starNum

	--self._starNum = data.refId

	self._starNum = data.group

	local show = data.hero ~= ModelFormation.TYPE_BUFF_FUSION_RACE and data.hero ~= ModelSpiritHero.SPIRITHERO_RACE
	if show then
		local ref = gModelHero:GetRestrainDetailsEffByRefId(data.hero)
		if ref then
			local str = ccClientText(10104)
			local addStr = self:GetStr(ref, true, true)
			str = string.replace(str, addStr)
			self:SetWndText(self.mHurtTxt, str)
			self:InitTextLineWithLanguage(self.mHurtTxt, -30)
			self:InitTextSizeWithLanguage(self.mHurtTxt, -2)
		end
	end

	-- CS.ShowObject(self.mType6Txt,data.hero == ModelFormation.TYPE_BUFF_FUSION_RACE)


	self:InitCampList()

	local uiRaceList = self._uiRaceList
	if uiRaceList then
		local uiList = uiRaceList:GetList()
		uiList:RefreshList()
	end
end

function UIBf:AttrStrFormat(attrStr)
	local strList = string.split(attrStr, ",")
	local list = {}
	for i = 1, #strList do
		local data = strList[i]
		local dataList = string.split(data, "=")
		local attr, campType, num = tonumber(dataList[1]), tonumber(dataList[2]), tonumber(dataList[3])
		table.insert(list, { attr = attr, campType = campType, num = num })
	end

	local str = ""
	local map = {}
	for k, v in ipairs(list) do
		if k > 1 then
			str = str .. ", "
		end
		local name = gModelHero:GetAttributeNameById(v.attr)
		str = str .. name .. "+" .. v.num * 100 .. "%"

		if not map[v.attr] then
			map[v.attr] = { attr = v.attr, num = v.num, campType = v.campType, index = k }
		else
			map[v.attr].num = map[v.attr].num + v.num
		end
	end
	return str, map
end

function UIBf:GetRaceTypeList()
	local list = {}
	local campRef = gModelFormation:GetCombatCampRef()
	for k, v in pairs(campRef) do
		table.insert(list, v)
	end
	table.sort(list, function(a, b)
		return a.sort < b.sort
	end)
	return list
end

------------------------------------------------------------------
return UIBf