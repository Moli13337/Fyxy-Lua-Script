---
--- Created by BY.
--- DateTime: 2022/7/25 20:59:21
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISorceryCardAddPop:LWnd
local UISorceryCardAddPop = LxWndClass("UISorceryCardAddPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISorceryCardAddPop:UISorceryCardAddPop()
	self._heroIconList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISorceryCardAddPop:OnWndClose()
	self:ClearCommonIconList(self._heroIconList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISorceryCardAddPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISorceryCardAddPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitCommand()
end

function UISorceryCardAddPop:CreateEmptyShow(refId)
	local data = {
		refId = refId,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty1")
	emptyList:RefreshUI(data)
end
function UISorceryCardAddPop:HeroListItem(list,item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local heroRoot = self:FindWndTrans(root,"HeroRoot")

	local InstanceID = item:GetInstanceID()

	local baseClass = self._heroIconList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New(self)
		self._heroIconList[InstanceID] = baseClass
		baseClass:Create(heroRoot)
	end
	baseClass:SetHeroPlayer(itemdata.id)
	baseClass:DoApply()

	self:SetWndClick(root, function()
		gModelHero:ReqShowHeroTip(gModelPlayer:GetPlayerId(), itemdata, nil, nil, nil, gModelPlayer:GetServerId())
	end)
end
function UISorceryCardAddPop:ArrtListItem(list,item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local icon = self:FindWndTrans(root,"Icon")
	local nameText = self:FindWndTrans(root,"NameText")
	local addText = self:FindWndTrans(root,"AddText")

	local iconStr = gModelHero:GetAttributeIconById(itemdata.refId)
	local nameStr = gModelHero:GetAttributeNameById(itemdata.refId)
	local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(itemdata.refId,itemdata.numType,itemdata.value)
	self:SetWndEasyImage(icon,iconStr)
	self:SetWndText(nameText,nameStr)
	self:SetWndText(addText,valueStr)
end
function UISorceryCardAddPop:GetHeroList()
	local _refId = self._refId
	local ref = gModelSorceryCard:GetSorceryCardRefByRefId(_refId)
	local _equipLimit = ref.attrBonusObj
	local _raceType = 0
	local heroKeys = gModelSorceryCard:GetHeroKeys()
	if not _raceType or not heroKeys then return end
	local limitRef = gModelSorceryCard:GetSorceryCardUseLimitRefByRefId(_equipLimit)
	if not limitRef then return end
	local suitRace,suitCareer,suitHeroInitQuality,suitGender,suitHero
	= limitRef.suitRace,limitRef.suitCareer,limitRef.suitHeroInitQuality,limitRef.suitGender,limitRef.suitHero
	local suitRaceList,suitCareerList,suitHeroInitQualityList,suitGenderList,suitHeroList
	if not string.isempty(suitRace) then
		local arr = string.split(suitRace,"|")
		suitRaceList = {}
		for i, v in ipairs(arr) do
			suitRaceList[tonumber(v)] = true
		end
	end
	if not string.isempty(suitCareer) then
		local arr = string.split(suitCareer,"|")
		suitCareerList = {}
		for i, v in ipairs(arr) do
			suitCareerList[tonumber(v)] = true
		end
	end
	if not string.isempty(suitHeroInitQuality) then
		local arr = string.split(suitHeroInitQuality,"|")
		suitHeroInitQualityList = {}
		for i, v in ipairs(arr) do
			suitHeroInitQualityList[tonumber(v)] = true
		end
	end
	if not string.isempty(suitGender) then
		local arr = string.split(suitGender,"|")
		suitGenderList = {}
		for i, v in ipairs(arr) do
			suitGenderList[tonumber(v)] = true
		end
	end
	if not string.isempty(suitHero) then
		local arr = string.split(suitHero,"|")
		suitHeroList = {}
		for i, v in ipairs(arr) do
			suitHeroList[tonumber(v)] = true
		end
	end

	local list = {}
	local heroList = gModelHero:GetHeroList()
	for i, v in pairs(heroList) do
		local hero = v:GetServerData()
		local refId = hero.refId
		local heroRef = gModelHero:GetHeroRef(refId)
		local raceType = heroRef.raceType
		local careerType = heroRef.careerType
		local quality = heroRef.quality
		local genderType = heroRef.genderType
		--种族限制
		if _raceType == 0 or raceType == _raceType then
			--条件限制:	种族限制 职业限制 品质限制 性别限制 英雄refId限制
			if ((not suitRaceList or suitRaceList[raceType])
					and (not suitCareerList or suitCareerList[careerType])
					and (not suitHeroInitQualityList or suitHeroInitQualityList[quality])
					and (not suitGenderList or suitGenderList[genderType]))
					or (suitHeroList and suitHeroList[refId])
			then
				table.insert(list,hero)
			end
		end
	end
	table.sort(list,function (a,b)
		local aCardId = heroKeys[a.id] or 0
		local bCardId = heroKeys[b.id] or 0
		local isAWear = aCardId == _refId and 1 or 0
		local isBWear = bCardId == _refId and 1 or 0
		if isAWear ~= isBWear then
			return isAWear > isBWear
		end
		local alv = a.lv
		local blv = b.lv
		if alv ~= blv then
			return alv > blv
		end
		local astar = a.star
		local bstar = b.star
		if astar ~= bstar then
			return astar > bstar
		end
		return a.id > b.id
	end)
	return list
end
function UISorceryCardAddPop:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(29538))
	self:SetWndText(self.mArrtTitleText,ccClientText(29514))
	self:SetWndText(self.mHeroDesText,ccClientText(29515))
	self:SetWndText(self.mCloseTip,ccClientText(10103))

	local refId = self:GetWndArg("refId")
	self._refId = refId
	self:RefreshData()
end

function UISorceryCardAddPop:InitEvent()
	self:SetWndClick(self.mBgImage,function ()self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function ()self:WndClose() end)
end

function UISorceryCardAddPop:RefreshData()
	local cardList = gModelSorceryCard:GetCardList()
	if not cardList then return end
	local _refId = self._refId
	local cardInfo = cardList[_refId]
	local curLv = cardInfo and cardInfo.level or 0
	local lvRef = gModelSorceryCard:GetSorceryCardUpgradeRef(_refId,curLv)
	local arrtList = LUtil.GetRefAttrData(lvRef.attr)

	local arrUiList = self._arrUiList
	if arrUiList then
		arrUiList:RefreshList(arrtList)
	else
		arrUiList = self:GetUIScroll("mArrtSuper_UISorceryCardAddPop")
		self._arrUiList = arrUiList
		arrUiList:Create(self.mArrtScroll,arrtList,function(...) self:ArrtListItem(...) end)
		arrUiList:EnableScroll(#arrtList > 4,false)
	end

	local list = self:GetHeroList() or {}
	local len = #list
	CS.ShowObject(self.mNoRecord2,len <= 0)
	if len <= 0 then
		self:CreateEmptyShow(10009)
	end
	local _heroUiList = self._heroUiList
	if _heroUiList then
		_heroUiList:RefreshList(list)
		_heroUiList:DrawAllItems()
	else
		_heroUiList = self:GetUIScroll("mHeroSuper_UISorceryCardAddPop")
		self._heroUiList = _heroUiList
		_heroUiList:Create(self.mHeroSuper,list,function (...) self:HeroListItem(...) end,UIItemList.SUPER_GRID)
		_heroUiList:EnableScroll(true,false)
	end
end
------------------------------------------------------------------
return UISorceryCardAddPop


