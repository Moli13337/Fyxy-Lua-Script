---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISelFightSaga:LWnd
local UISelFightSaga = LxWndClass("UISelFightSaga", LWnd)
local typeof = typeof
local typeSpineClick = typeof(CS.SpineClick)

UISelFightSaga.HANG = 1
UISelFightSaga.TIMECORRIDOR = 2
UISelFightSaga.INVASION = 3
UISelFightSaga.SPRING_FESTIVAL = 4	--春节活动2022
UISelFightSaga.OUTFIT_SELEXCLUSIVE = 5	-- 装备选择专属

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISelFightSaga:UISelFightSaga()
	self._emptyId = 6002
	self:DelaySendDetail(true)
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISelFightSaga:OnWndClose()
	if self._uiList then
		self._uiList:OnWndClose()
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISelFightSaga:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISelFightSaga:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitWndPara()

	local wndType = self._wndType
	if wndType ~= UISelFightSaga.OUTFIT_SELEXCLUSIVE then
		self:DelaySendDetail(false)
		self:SendWndOpenDetailInfo()
	end

	if wndType == UISelFightSaga.OUTFIT_SELEXCLUSIVE then
		self:RefreshSpecialTypeView()
	else
		self:RefreshCommonTypeView()
	end

	self:InitData()
	self:InitEvent()
	self:InitMsg()


	if wndType == UISelFightSaga.OUTFIT_SELEXCLUSIVE then
		self:InitScrollView()
		self:ShowRole()
	else
		if not gModelPlayer:ReqFigureData(wndType) then
			self:RefreshUI()
		end
	end

end

function UISelFightSaga:SetDesc(str)
	self:SetWndText(self.mDescTxt,str)
end

function UISelFightSaga:InitScrollView()
	local dataList = self:GetHeroList()

	local isEmpty = #dataList == 0
	CS.ShowObject(self.mNoRecord,isEmpty)
	CS.ShowObject(self.mHeroList,not isEmpty)
	if isEmpty then
		return
	end

	local uiList = self._uiList
	if uiList then
		uiList:RefreshData(dataList,true)
	else
		uiList = self:GetUIScroll("heroList")
		self._uiList = uiList
		uiList:Create(self.mHeroList,dataList,function (...) self:OnDrawHeroCell(...) end,UIItemList.WRAP,false)
	end
	local list = uiList:GetList()
	list:EnableLoadAnimation(true, 0, 5)
	list:RefreshList(UIListWrap.RefreshMode.Solid)
end

function UISelFightSaga:GetPlayerHeroIcon(heroTrans,itemdata,itempos)
	local heroId = itemdata.id
	local gouShow = self._selHeroId == heroId

	local instanceId = heroTrans:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(heroTrans)
	baseClass:SetHeroPlayer(heroId)
	baseClass:SetShowGouImg(gouShow)
	baseClass:DoApply()

	self:SetWndClick(heroTrans,function()
		self:OnClickHero(heroId,itempos)
	end)
end

function UISelFightSaga:OnClickCommonEnterBtnFunc()
	if string.isempty(self._selHeroId) and self._wndType == UISelFightSaga.HANG then
		GF.ShowMessage(ccClientText(10127))
		return
	end
	local data =
	{
		imageType = self._wndType,
		heroId = string.isempty(self._selHeroId) and -1 or self._selHeroId
	}
	gModelPlayer:OnPlayerMapImageReq(data)
	self:WndClose()
end

function UISelFightSaga:GetCurOutfitId()
	local outfit = self:GetWndArg("outfit")
	if not outfit then return end
	return outfit.id
end

function UISelFightSaga:OnClickEnterBtnFunc()
	if self._wndType == UISelFightSaga.OUTFIT_SELEXCLUSIVE then
		self:OnClickSpecialEnterBtnFunc()
	else
		self:OnClickCommonEnterBtnFunc()
	end
end

function UISelFightSaga:InitMsg()
	--self:WndNetMsgRecv(LProtoIds.SetFormationResp, function(pb)
	--	if pb.formationType == self._combatType and pb.teamIndex == self._teamIndex then
	--		local str= ccClientText(10769)
	--		GF.ShowMessage(str)
	--		if self._teamIndex == 0 then
	--			FireEvent(EventNames.ON_HOOK_HERO_CHANGE)
	--		elseif self._teamIndex == 1 then
	--			FireEvent(EventNames.ON_CHANGE_TIME_CORRIDOR_FIGURE)
	--		end
	--		self:WndClose()
	--	end
	--end)

	--self:WndNetMsgRecv(LProtoIds.GetFormationResp,function () self:RefreshUI() end)


	self:WndEventRecv(EventNames.ON_PLAY_FIGURE_CHANGE,function (imageType)

		if self._wndType ~= imageType then
			return
		end

		self:RefreshUI()
	end)
	self:WndNetMsgRecv(LProtoIds.OutfitRecastResp,function(pb)
		local outfitInfo = pb.outfitInfo
		local id = outfitInfo.id
		local curSelOutfitId = self:GetCurOutfitId()
		if id ~= curSelOutfitId then return end
		self:WndClose()
	end)
end

function UISelFightSaga:OnSpineLoaded(dpSpine)
	dpSpine:SetScale(1.5)
	dpSpine:PlayAnimation(0,"idle",true)
	local spineTrans = dpSpine:GetSpineTrans()
	local spineClick = spineTrans:GetComponent(typeSpineClick)
	if not spineClick then
		spineClick = spineTrans.gameObject:AddComponent(typeSpineClick)
		spineClick.isUISpine = true
	end
	spineClick.onClick = function()
		-- 下阵
		self._selHeroId = ""
		self._uiList:DrawAllItems()
		self:ShowRole()
	end
end

function UISelFightSaga:SetEmptyList()
	local item = self.mNoRecord
	local EmptyIcon = self:FindWndTrans(item,"EmptyIcon")
	local EmptyTextBg = self:FindWndTrans(item,"EmptyTextBg")
	local EmptyText = self:FindWndTrans(item,"EmptyText")
	local EmptyBtn = self:FindWndTrans(item,"EmptyBtn")
	local EmptyBtnEmptyBtnText = self:FindWndTrans(EmptyBtn,"EmptyBtnText")

	local emptyList = self:GetCommonEmptyList("_empty")
	local data = {
		refId = self._emptyId,
		IntroTran = EmptyText,
		TextBgTran = EmptyTextBg,
		IconTran = EmptyIcon,
		GetBtn = EmptyBtn,
		GetBtnText = EmptyBtnEmptyBtnText
	}
	emptyList:RefreshUI(data)


end

function UISelFightSaga:GetCommonHeroList()
	local list = {}
	local selType = self._selType - 1
	local heroList = gModelHero:GetHeroSortList()
	for k,v in ipairs(heroList) do
		local hero = v:GetServerData()
		local refId = hero.refId
		if selType == 0 then
			table.insert(list,hero)
		else
			local race = gModelHero:GetHeroRace(refId)
			if selType == race then
				table.insert(list,hero)
			end
		end
	end
	return list
end

function UISelFightSaga:ShowRole()
	self:DestroyWndSpineByKey(self._spineKey)
	local imgPath = "fight_ui_0"
	if not string.isempty(self._selHeroId) then
		local pbName
		if self._wndType == UISelFightSaga.OUTFIT_SELEXCLUSIVE then
			pbName = gModelHero:GetHeroPrefabNameByRefId(self._selHeroId)
		else
			pbName = gModelHero:GetHeroPrefabNameById(self._selHeroId)
		end
		if not string.isempty(pbName) then
			self:CreateWndSpine(self.mPbHero,pbName,self._spineKey,false,function(dpSpine)
				dpSpine:MatchRectTransform()
				self:OnSpineLoaded(dpSpine)
			end)

			if self._wndType == UISelFightSaga.OUTFIT_SELEXCLUSIVE then
				local quaId = gModelHero:GetRegionHeroQuality(self._selHeroId)
				if quaId then
					imgPath = gModelHero:GetHeroTacticalBg(quaId)
				end
			else
				imgPath = gModelHero:GetHeroTacticalBgByQualityId(self._selHeroId)
			end

			CS.ShowObject(self.mNoHeroImg,false)
		else
			self:ShowNoHero()
		end

	else
		self:ShowNoHero()
	end

	self:SetWndEasyImage(self.mHeroBotImg,imgPath)
end

function UISelFightSaga:GetOutfitSelExclusiveHeroList()
	local list = {}
	local selType = self._selType - 1
	local refId
	-- local useAllHero = gModelOutfit:GetOutfitConfigByKey("useAllHero")
	local useAllHero = false
	if not useAllHero then
		if LOG_INFO_ENABLED then
			printInfoNR("OutfitConfigRef表 useAllHero 字段用来表示是否使用全英雄，默认使用，useAllHero = 1")
		end
		useAllHero = 1
	end

	local outfitRecasRaceList = {}
	-- local outfitRecasRace = gModelOutfit:GetOutfitConfigByKey("outfitRecasRace")
	local outfitRecasRace = false
	if outfitRecasRace then
		outfitRecasRace = string.split(outfitRecasRace,",")
		for i,v in ipairs(outfitRecasRace) do
			v = tonumber(v)
			outfitRecasRaceList[v] = v
		end
	end

	local ignoreRaceList = {}
	for k,v in pairs(GameTable.CharacterRaceRef) do
		if not outfitRecasRaceList[k] then
			CS.ShowObject(self._typeBtnList[k + 1],false)
		end
	end

	local checkIsInsFunc = function(heroRefId)
		if selType == 0 then
			return true
		else
			local race = gModelHero:GetHeroRace(heroRefId)
			return selType == race
		end
	end
	local outfit = self:GetWndArg("outfit")
	local outfitRefId = outfit and outfit.refId
	local showMask = false
	local isRedFull = false
	local isIns = false
	if useAllHero == 1 then
		local ref = GameTable.CharacterRef
		for k,v in pairs(ref) do
			if outfitRecasRaceList[v.raceType] and v.outfitRecastRate > 0 then
				refId = k
				isIns = checkIsInsFunc(refId)
				if isIns then
					-- showMask = outfitRefId and gModelOutfit:CheckRefIdIsHaveFullOutfit(outfitRefId,k) or false
					-- isRedFull = outfitRefId and gModelOutfit:CheckIsHaveRedOutfit(k,outfitRefId) or false
					showMask = false
					isRedFull = false
					table.insert(list,{
						refId = refId,
						showMask = showMask,
						isRedFull = isRedFull,
					})
				end
			end
		end
	else
		local heroRefId
		local heroList = gModelHero:GetHaveRefIdHeroList()
		for i,v in ipairs(heroList) do
			refId = v.refId
			isIns = checkIsInsFunc(refId)
			if isIns then
				heroRefId = v.refId
				-- showMask = outfitRefId and gModelOutfit:CheckRefIdIsHaveFullOutfit(outfitRefId,heroRefId) or false
				-- isRedFull = outfitRefId and gModelOutfit:CheckIsHaveRedOutfit(heroRefId,outfitRefId) or false
				showMask = false
				isRedFull = false
				table.insert(list,{
					refId = refId,
					showMask = showMask,
					isRedFull = isRedFull,
				})
			end
		end
	end

	table.sort(list,function(a,b)
		return a.refId < b.refId
	end)
	return list
end

function UISelFightSaga:RefreshSpecialTypeView()
	if self._wndType == UISelFightSaga.OUTFIT_SELEXCLUSIVE then
		self:SetTitle(ccClientText(24626))
		self:SetDesc(ccClientText(24636))
		self:SetWndText(self.mEnterBtnName,ccClientText(24626))
		CS.ShowObject(self.mHelpBtn,false)
	end
	self:SetEmptyList()
end

function UISelFightSaga:InitData()
	self._typeBtnList = {
		self.mAllBtn,
		self.mBtn1,
		self.mBtn2,
		self.mBtn3,
		self.mBtn4,
		self.mBtn5,
		self.mBtn6,
	}

	self._selBtnList = {
		self.mAllBtnSel,
		self.mBtn1Sel,
		self.mBtn2Sel,
		self.mBtn3Sel,
		self.mBtn4Sel,
		self.mBtn5Sel,
		self.mBtn6Sel,
	}

	self._selType = 1
	self._selHeroId = ""
	--self._spineKey = nil
	--self._serverHeroId = ""
	--self._combatType = LCombatTypeConst.COMBAT_ON_HOOK_DEFEND

	self._spineKey = "showHero"
end

function UISelFightSaga:ShowNoHeroImg()
	local showNoHeroImg = false
	if string.isempty(self._selHeroId) then showNoHeroImg = true end
	CS.ShowObject(self.mNoHeroImg,showNoHeroImg)
end

function UISelFightSaga:RefreshUI()
	self:InitFigureData()
	self:InitScrollView()
	self:ShowRole()
end

function UISelFightSaga:InitFigureData()
	if self._wndType == UISelFightSaga.OUTFIT_SELEXCLUSIVE then return end
	local figureData = gModelPlayer:GetPlayFigureData(self._wndType)

	if figureData then
		self._selHeroId = figureData.heroId
		self._curEffectId = figureData.heroImageRefId
	end
end

function UISelFightSaga:TypeBtnEvent(i)
	if i == self._selType then return end
	local selBtnList = self._selBtnList
	local old = self._selType
	CS.ShowObject(selBtnList[old],false)
	self._selType = i
	CS.ShowObject(selBtnList[i],true)
	self:InitScrollView()
end

function UISelFightSaga:OnClickSpecialEnterBtnFunc()
	if string.isempty(self._selHeroId) then
		GF.ShowMessage(ccClientText(24636))
		return
	end
	local selOutfitId = self:GetCurOutfitId()
	if not selOutfitId then return end
	-- gModelOutfit:OnOutfitRecastReq(selOutfitId,nil,3,nil,nil,nil,self._selHeroId)
end

function UISelFightSaga:ShowNoHero()
	local wndType = self._wndType
	if wndType == UISelFightSaga.HANG then
		CS.ShowObject(self.mNoHeroImg,true)
	elseif wndType == UISelFightSaga.OUTFIT_SELEXCLUSIVE then
		CS.ShowObject(self.mNoHeroImg,true)
	else
		self:DestroyWndSpineByKey(self._spineKey)
		local spineName = gModelPlayer:GetPlayerDefaultPrefab() or self._defaultPrefab
		self:CreateWndSpine(self.mPbHero,spineName,self._spineKey,false,function(dpSpine)
			dpSpine:MatchRectTransform()
			self:OnSpineLoaded(dpSpine)
		end)
	end
end

function UISelFightSaga:SetTitle(str)
	self:SetWndText(self.mTitle,str)
end

function UISelFightSaga:GetHeroList()
	local list = {}
	if self._wndType == UISelFightSaga.OUTFIT_SELEXCLUSIVE then
		list = self:GetOutfitSelExclusiveHeroList()
	else
		list = self:GetCommonHeroList()
	end
	return list
end

function UISelFightSaga:OnDrawHeroCell(list, item, itemdata, itempos)
	local heroTrans = CS.FindTrans(item,"HeroIcon")
	if heroTrans then
		self:CreateIcon(heroTrans,itemdata,itempos)
	end

	local FullClassTrans = self:FindWndTrans(item,"FullClass")
	local showFullClass = false
	if self._wndType == UISelFightSaga.OUTFIT_SELEXCLUSIVE then
		-- showFullClass = gModelOutfit:CheckHeroRefIdIsHaveFullClass(itemdata.refId)
	end
	CS.ShowObject(FullClassTrans,showFullClass)
end

function UISelFightSaga:RefreshCommonTypeView()
	if self._wndType == UISelFightSaga.HANG then
		self:SetTitle(ccClientText(10124))
		self:SetDesc(ccClientText(10126))
		CS.ShowObject(self.mHelpBtn,true)
	elseif self._wndType == UISelFightSaga.SPRING_FESTIVAL then
		self:SetTitle(ccClientText(24720))
		self:SetDesc(ccClientText(24721))
		CS.ShowObject(self.mHelpBtn,false)
		self._emptyId = 14007
	else
		self:SetTitle(ccClientText(19116))
		self:SetDesc(ccClientText(19117))
		CS.ShowObject(self.mHelpBtn,false)
	end
	self:SetEmptyList()
	self:SetWndText(self.mEnterBtnName,ccClientText(10125))
	self:SetWndText(self.mCloseTip,ccClientText(10103))
end

function UISelFightSaga:CreateIcon(heroTrans,itemdata,itempos)
	if self._wndType == UISelFightSaga.OUTFIT_SELEXCLUSIVE then
		self:GetHeroRefIdIcon(heroTrans,itemdata,itempos)
	else
		self:GetPlayerHeroIcon(heroTrans,itemdata,itempos)
	end
	self:SetIconClickScale(heroTrans, true)
end

function UISelFightSaga:GetHeroRefIdIcon(heroTrans,itemdata,itempos)
	local refId = itemdata.refId
	local gouShow = refId == self._selHeroId
	local instanceId = heroTrans:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(heroTrans)
	baseClass:SetHeroIcon(refId)
	baseClass:SetShowGouImg(gouShow)

	local showMask = itemdata.showMask
	local isRedFull = itemdata.isRedFull
	local limitStr = ""
	if showMask then
		limitStr = ccClientText(20162)
	elseif isRedFull then
		limitStr = ccClientText(18367)
	end
	baseClass:SetLimitTxt(limitStr)
	baseClass:DoApply()

	self:SetWndClick(heroTrans,function()
		self:OnClickHero(refId,itempos)
	end)
end

function UISelFightSaga:InitWndPara()
	self._wndType = self:GetWndArg("wndType") or UISelFightSaga.HANG
	self._defaultPrefab = self:GetWndArg("defaultPrefab")
end

function UISelFightSaga:InitEvent()
	for i,v in ipairs(self._typeBtnList) do
		self:SetWndClick(v,function() self:TypeBtnEvent(i) end)
	end
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end)
	self:SetWndClick(self.mBg,function() self:WndClose() end)
	self:SetWndClick(self.mEnterBtn,function()
		self:OnClickEnterBtnFunc()
	end)
	self:SetWndClick(self.mHelpBtn,function()
		GF.OpenWnd("UIBzTips",{refId = 19})
	end)
end

function UISelFightSaga:OnClickHero(id)
	if self._selHeroId == id then
		self._selHeroId = ""
	else
		self._selHeroId = id
	end

	self._uiList:DrawAllItems()

	self:ShowRole()

end
------------------------------------------------------------------
return UISelFightSaga


