---
--- Created by BY.
--- DateTime: 2023/10/6 10:59:36
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeEvent1:LWnd
local UIHopeEvent1 = LxWndClass("UIHopeEvent1", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeEvent1:UIHopeEvent1()
	---@type table<number,CommonIcon>
	self._heroIconList = {}
	self._isSkipCheck = false
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeEvent1:OnWndClose()
	self:ClearCommonIconList(self._heroIconList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeEvent1:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeEvent1:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitTxt()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
	self:InitRewardList()
	self:RefreshView()

	gModelFastDreamTrip:OnDreamTripMonsterInfoReq(self._eventId)
end

function UIHopeEvent1:OnDrawRewardCell(list,item,itemdata,itempos)
	local CommonUI = self:FindWndTrans(item,"CommonUI")
	local Icon = self:FindWndTrans(CommonUI,"Icon")

	local instanceID = item:GetInstanceID()
	local heroIconList = self._heroIconList
	local baseClass = heroIconList[instanceID]
	if not baseClass then
		baseClass = CommonIcon:New(self)
		heroIconList[instanceID] = baseClass
		baseClass:Create(Icon)
	end
	baseClass:SetCommonReward(itemdata.itemType,itemdata.itemId,itemdata.itemNum)
	baseClass:DoApply()
	self:SetWndClick(Icon,function()
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)
end

function UIHopeEvent1:RefreshView()
	local eventData = self._eventInfo

	if eventData then
		local eventRefId = eventData.eventRefId

		local name = gModelFastDreamTrip:GetDreamTripEventNameByRefId(eventRefId)
		self._name = name
		self:SetWndText(self.mLblBiaoti,name)

		local choose = gModelFastDreamTrip:GetDreamTripEventChooseByRefId(eventRefId)
		choose = tonumber(choose) or 0
		local textRef = gModelFastDreamTrip:GetDreamTripTextRefByRefId(choose)
		if textRef then
			self:SetWndText(self.mDesText,ccLngText(textRef.dec))
		end

		CS.ShowObject(self.mBtnList, true)

		local isSkipCheck = gModelFastDreamTrip:GetIsSkipOpen()
		self:SetWndToggleValue(self.mSkipBattle,isSkipCheck)
	end
end

function UIHopeEvent1:InitEvent()
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnChallenge, function(...) self:OnClickChallenge() end)
	self:SetWndClick(self.mBtnGiveUp, function(...) self:OnClickGiveUp() end)
	self:SetWndToggleDelegate(self.mSkipBattle,function (value)
		self._isSkipCheck = value
		if not gModelFastDreamTrip:SetIsSkipOpen(value,true) then
			self._isSkipCheck = false
		end

		self:RefreshToggleState()
	end)
end

function UIHopeEvent1:CreateSpine()
	local eventData = self._eventInfo
	if not eventData then return end
	self._monsterAddCost = nil
	local moreInfo = eventData.moreInfo or {}
	local monster_add_cost = moreInfo.monster_add_cost
	if monster_add_cost and monster_add_cost[1] then
		local monsterAddCost = monster_add_cost[1].monsterAddCost
		self._monsterAddCost = monsterAddCost
	end

	local prefab = gModelFastDreamTrip:GetDreamTripEventPrefabByRefId(self._eventRefId)
	if prefab then
		local prefabSize = gModelFastDreamTrip:GetDreamTripEventPrefabSizeByRefId(self._eventRefId)
		self:CreateWndSpine(self.mSpine,prefab,prefab,false,function(dpSpine)
			dpSpine:SetScale(prefabSize or 1)
		end)
	end
end

function UIHopeEvent1:GetRewardList()
	local rewardList = gModelFastDreamTrip:GetDreamTripRewardListByByEventRefId(self._eventRefId)
	return rewardList
end

function UIHopeEvent1:RefreshToggleState()
	self:SetWndToggleValue(self.mSkipBattle,self._isSkipCheck)
end

function UIHopeEvent1:InitCommand()
	---@type StructDreamTripEventInfo
	local eventInfo = self:GetWndArg("eventInfo")
	self._eventInfo = eventInfo

	local gameParams = self:GetWndArg("gameParams")
	self._gameParams = gameParams

	self._eventId = eventInfo.eventId
	self._index = eventInfo.index
	self._eventRefId = eventInfo.eventRefId
	self._eventType = eventInfo.eventType

	self:RefreshToggleState()
end

function UIHopeEvent1:OnDrawMonsterCell(list,item,itemdata,itempos)
	local CommonUI = self:FindWndTrans(item,"CommonUI")
	local Icon = self:FindWndTrans(CommonUI,"Icon")
	local instanceID = item:GetInstanceID()
	local id = itemdata.id
	local baseClass = self:GetCommonIcon(instanceID)
	baseClass:Create(Icon)
	local refId = itemdata.refId
	local monsterAddCost = self._monsterAddCost
	local herodata = {
		trans = Icon,
		id = id,
		refId = refId,
		star = itemdata.star,
		level = itemdata.lvl,
		isResonance = itemdata.resonance,
		skin = itemdata.skin,
		isMon = true,
		monsterAddCost = monsterAddCost
	}
	baseClass:SetHeroDataSet(herodata)
	baseClass:DoApply()

	self:SetWndClick(Icon,function()
		GF.ShowMessage(ccClientText(20450))
	end)

	local curHp,maxHp = itemdata.curHp,itemdata.maxHp
	local isDead = curHp <= 0
	local deadTag = self:FindWndTrans(item,"deadTag")
	if deadTag then
		CS.ShowObject(deadTag,isDead)
	end

	local BarBg = self:FindWndTrans(item,"BarBg")
	local Bar = self:FindWndTrans(BarBg,"Bar")
	local percentage = curHp/maxHp
	LxUiHelper.SetProgress(Bar,percentage)
end

function UIHopeEvent1:InitRewardList()
	local list = self:GetRewardList()
	local uiRewardList = self._uiRewardList
	if uiRewardList then
		uiRewardList:RefreshData(list)
	else
		uiRewardList = self:GetUIScroll("uiRewardList")
		self._uiRewardList = uiRewardList
		uiRewardList:Create(self.mRewardList1,list,function(...) self:OnDrawRewardCell(...) end)
	end
	uiRewardList:EnableScroll(#list > 3,true)
end

function UIHopeEvent1:GetMonsterRefId(monsterFormationRef)
	local gridMax = LCombatFormationConst.GRID_MAX
	for j = 1, gridMax do
		local monsterId = monsterFormationRef["monster"..j]
		if monsterId > 0 then
			return monsterId
		end
	end
end

function UIHopeEvent1:OnClickGiveUp()
	gModelFastDreamTrip:OnDreamTripStartEventReq(self._eventId,{0})
	self:WndClose()
end

function UIHopeEvent1:OnClickChallenge()
--[[	local combatRefId = 7
	local combatPos = gModelFormation:GetFormationPosByRefId(combatRefId)
	local grids = {}
	for k,v in pairs(combatPos) do
		local data = {}
		data.id = self._selHeroId
		data.grid = v
		table.insert(grids,data)
	end
	local combatType = LCombatTypeConst.COMBAT_DREAMTRIP
	local isSkip = self._isSkipCheck
	local combatData = {
		formationRefId = combatRefId,
		combatType = combatType,
		targetId = self._eventId,
		--formationA = data,
		skipBattle = isSkip,
	}
	gModelBattle:StartAfterSetFormation(combatData)]]
	--gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_ARENA_ATTACK,combatExtraData)

	if self._isSkipCheck then
		self:SkipBattle()
	else
		self:GoToFormation()
	end
end


function UIHopeEvent1:OnFDTEventFinish(recordFinishMap,pb)
	if not recordFinishMap[self._eventId] then return end
	self:WndClose()
end

function UIHopeEvent1:InitMonsterList(list,onDrawFunc)
	local uiMonsterList = self._uiMonsterList
	if uiMonsterList then
		uiMonsterList:RefreshData(list)
	else
		uiMonsterList = self:GetUIScroll("uiMonsterList")
		self._uiMonsterList = uiMonsterList
		uiMonsterList:Create(self.mMonsterList,list,function(...) onDrawFunc(...) end,UIItemList.WRAP,false)
		local uiList = uiMonsterList:GetList()
		uiList:RefreshList(UIListWrap.RefreshMode.Solid)
	end
end

function UIHopeEvent1:GoToFormation()
	local combatType = LCombatTypeConst.COMBAT_DREAMTRIP
	local monster_ref_id = gModelFastDreamTrip:GetDreamTripEventMoreInfoByKey(self._eventInfo,StructDreamTripEventInfo.MONSTER_REF_ID)
	if monster_ref_id and #monster_ref_id > 0 then
		local serMonster = monster_ref_id[1].monsterId
		local monsterFormationRef = gModelHero:GetMonsterFormationRefByRefId(serMonster)
		local monsterName = monsterFormationRef and ccLngText(monsterFormationRef.name) or ""
		local monsterPower = 0
		local formation = monsterFormationRef and monsterFormationRef.formation or 1
		local monsterId = self:GetMonsterRefId(monsterFormationRef)
		if monsterFormationRef then
			monsterPower = monsterFormationRef.monsterPower
		end
		local bossIdList = {}
		table.insert(bossIdList,serMonster)

		local powerList = {}
		table.insert(powerList,monsterPower)
		local cExtraData = {
			--bossId = {monsterId = serMonster},
			bossIdList = bossIdList,
			monsterPower = monsterPower,
			monsterId = monsterId,
			bossId = serMonster,
			formation = formation,
			targetId = self._eventId,
			otherName = monsterName,
			skipBattle = self._isSkipCheck,
			monsterAddCost = self._monsterAddCost,
			returnFunc = function()
				gModelGeneral:RecoverGameState()
			end
		}
		gModelGeneral:RecordGameState()
		gLFightManager:PrepareGoToBattle(combatType,cExtraData)
	end
end

function UIHopeEvent1:SkipBattle()
	local combatType = LCombatTypeConst.COMBAT_DREAMTRIP
	if gModelFormation:IsFormationEmpty(combatType) then
		self:GoToFormation()
		return
	end
	gModelBattle:OnCombatReq({
		combatType = combatType,
		skipBattle = true,
		targetId = self._eventId,
	})
end

function UIHopeEvent1:OnDrawMonsterNormalCell(list,item,itemdata,itempos)
	local CommonUI = self:FindWndTrans(item,"CommonUI")
	local Icon = self:FindWndTrans(CommonUI,"Icon")
	local instanceID = item:GetInstanceID()
	local id = itemdata.id
	local baseClass = self:GetCommonIcon(instanceID)
	baseClass:Create(Icon)
	local refId = itemdata.refId
	local monsterAddCost = self._monsterAddCost
	local herodata = {
		trans = Icon,
		id = id,
		refId = refId,
		star = itemdata.star,
		level = itemdata.level,
		isResonance = itemdata.resonance,
		skin = itemdata.skin,
		isMon = true,
		monsterAddCost = monsterAddCost
	}
	baseClass:SetHeroDataSet(herodata)
	baseClass:DoApply()

	self:SetWndClick(Icon,function()
		GF.ShowMessage(ccClientText(20450))
	end)

	local deadTag = self:FindWndTrans(item,"deadTag")
	CS.ShowObject(deadTag,false)

	local BarBg = self:FindWndTrans(item,"BarBg")
	CS.ShowObject(BarBg,false)
end

function UIHopeEvent1:InitTxt()
	self:SetTextTile(self.mTextTitle1,ccClientText(20407))
	self:SetWndButtonText(self.mBtnChallenge,ccClientText(20424))
	self:SetWndButtonText(self.mBtnGiveUp,ccClientText(21018))

	local text = self:FindWndTrans(self.mSkipBattle,"Label")
	self:SetWndText(text,ccClientText(10341))
	self:InitTextSizeWithLanguage(text, -4)
end

function UIHopeEvent1:OnCommonStartEventResp(pb)
	if pb.eventId ~= self._eventId then return end
	local endInfo = pb.endInfo
	if not endInfo then return end
	if endInfo.state == 2 then
		self._sendEvent = true
		self:WndClose()
	end
end

function UIHopeEvent1:InitMessage()
	self:WndNetMsgRecv(LProtoIds.DreamTripMonsterInfoResp,function(pb,ret)
		if tonumber(pb.eventId) ~= self._eventId then return end
		local monster = pb.monster
		self:CreateSpine()

		local monsterAddCost = self._monsterAddCost

		local addCostLv
		local tMonsterRef
		local monsters = {}
		if monsterAddCost then
			local addCostRef = gModelHeroExtra:GetMonsterAttrCostRef(monsterAddCost)
			if addCostRef then
				addCostLv = addCostRef.lv
			end
		end
		if #monsters < 1 then
			local infoList = gModelFastDreamTrip:GetDreamTripEventMoreInfoByKey(self._eventInfo,StructDreamTripEventInfo.MONSTER_REF_ID)
			if infoList and #infoList > 0 then
				local tList = {}
				for i,v in ipairs(infoList) do
					tList = gModelHero:GetMonsterList(v.monsterId)
					if tList and #tList > 0 then
						for idx,val in ipairs(tList) do
							tMonsterRef = GameTable.MonsterAttrRef[val]
							if tMonsterRef then
								table.insert(monsters,{
									id = tMonsterRef.heroId,
									refId = tMonsterRef.refId,
									star = tMonsterRef.starLv,
									level = addCostLv or tMonsterRef.lv,
									resonance = 0,
								})
							end
						end
					end
				end
			end
		end

		self:InitMonsterList(monsters,function(...) self:OnDrawMonsterNormalCell(...) end)
	end)
	self:WndEventRecv(EventNames.ON_FDT_EVENT_FINISH,function(...) self:OnFDTEventFinish(...) end)
	self:WndNetMsgRecv(LProtoIds.DreamTripItemUseResp,function(pb,ret)
		GF.ShowMessage(ccClientText(20495))
	end)
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:WndClose() end)
end


------------------------------------------------------------------
return UIHopeEvent1


