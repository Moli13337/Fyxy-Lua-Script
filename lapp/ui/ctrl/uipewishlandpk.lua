---
--- Created by Administrator.
--- DateTime: 2024/6/7 18:11:28
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPeWishLandPk:LWnd
local UIPeWishLandPk = LxWndClass("UIPeWishLandPk", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPeWishLandPk:UIPeWishLandPk()
	---@type StructPetDreamLandPointData
	self._pointData = nil

	---@type StructCombatHeroData
	self._combatHeroData = nil

	---@type StructPetDreamLandPointData
	self._newPointData = nil

	self._cdTimerKey = "_cdTimerKey"

	self._cdInfos = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPeWishLandPk:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPeWishLandPk:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPeWishLandPk:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshJumpBattleState()
	self:ReqPointCheck()
end

function UIPeWishLandPk:OnCombatResultResp(pb)
	local combatType = pb.combatType
	if combatType ~= LCombatTypeConst.COMBAT_TYPE_41 then return end
	if pb.winner == 1 then
		self:WndClose()
		return
	end
end

function UIPeWishLandPk:InitHeroList()
	local list = self:GetHeroList()
	local uiList = self:FindUIScroll("mHeroList")
	if uiList then
        uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("mHeroList")
		uiList:Create(self.mHeroList, list, function(...) self:OnDrawHeroCell(...) end)
	end
end


function UIPeWishLandPk:InitPlayerOutputList(list)
	local uiList = self:FindUIScroll("mPlayerOutputList")
	if uiList then
        uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("mPlayerOutputList")
		uiList:Create(self.mPlayerOutputList, list, function(...) self:OnDrawPlayerOutputCell(...) end)
	end
end

function UIPeWishLandPk:OnItemChange()
	self:RefreshView()
end

---@param pointData StructPetDreamLandPointData
---@param lootRewardList table<StructRewardItem>
function UIPeWishLandPk:RefreshPlayerInfoDiv(pointData,lootRewardList)
	local spineName = pointData:GetShowPlayerInfoFigureSpine()
	if spineName then
		---@param dpSpine LDisplaySpine
		self:CreateWndSpine(self.mPlayerSpineRoot,spineName,spineName,false,function(dpSpine)

		end)
	end

	self:SetWndText(self.mPlayerName,pointData:GetServerAndPlayerName())

	local sortItemMap = {}

	local list = {}
	--- 产出效率
	local refData = gModelPetDreanLand:GetSplitPetDreamlandRefByRefId(self._refId)
	if refData then
		local showWeekHappy = false
		local isWeekOpen = gModelPetDreanLand:CheckIsOpenWeeken()
		if isWeekOpen then
			showWeekHappy = LUtil.CheckIsWeekend(GetTimestamp())
		end

		local weekenBuffNum = 0
		if showWeekHappy then
			weekenBuffNum = gModelPetDreanLand:GetpetDreamlandWeekenBuff() / 100
		end

		local petDreamlandBuff = gModelPetDreanLand:GetPetDreamlandBuffByVip(pointData:GetVipLevel())
		--- 新增战区产出
		local value = gModelPetDreanLand:GetCurBigFightIdPetDreamlandRewardValue() or {}

		local rewardList = {}
		for i,v in ipairs(refData.showRewardList) do
			--- （1+VIP额外加成比例+周末狂欢）
			local itemNum = (1 + petDreamlandBuff + weekenBuffNum) * v.itemNum
			local rate = value[i] or 1
			itemNum = itemNum * rate
			itemNum = math.floor(itemNum)
			local numStr = string.replace(ccClientText(43303),LUtil.NumberCoversion(itemNum))
			table.insert(rewardList,{
				itemId = v.itemId,
				numStr = numStr
			})

			sortItemMap[v.itemId] = i
		end
		table.insert(list,{
			list = rewardList,
			txt = ccClientText(43302),
		})
	end

	--- 占领时间
	table.insert(list,{
		list = {},
		txt = "",
		isNeedCD = true,
		cdData = {
			txtStr = ccClientText(43342),
			startTime = pointData.starOccupyTime,
		}
	})

	--- 当前获得
	table.insert(list,{
		txt = ccClientText(43317),
		list = self:GetCommonRewardList(pointData.itemList,sortItemMap),
	})

	--- 预计获得
	if #lootRewardList > 0 then
		table.insert(list,{
			txt = ccClientText(43318),
			list = self:GetCommonRewardList(lootRewardList,sortItemMap)
		})
	end

	self:InitPlayerOutputList(list)

	self:OnCDTimer()
	self:TimerStop(self._cdTimerKey)
	self:TimerStart(self._cdTimerKey,1,false,-1)
end

function UIPeWishLandPk:OnPetDreamLandPointRewardResp(pb)
	if not self._getRewardState then return end
	if not self._targetPointData then return end

	local targetPointData = self._targetPointData
	if targetPointData.refId ~= pb.refId then return end

	local petDreamlandLoss = gModelPetDreanLand:GetPetDreamlandLossPercentage()
	local itemTypeMap = {}
	local itemMap = {}
	local itemId
	for i,v in ipairs(pb.itemList) do
		itemId = v.itemId
		if not itemTypeMap[itemId] then
			itemTypeMap[itemId] = v.type
		end
		local item = itemMap[itemId] or 0
		itemMap[itemId] = v.count + item
	end
	local itemList = {}
	local tempCount
	for _itemId,itemNum in pairs(itemMap) do
		tempCount = math.floor(itemNum * petDreamlandLoss)
		if tempCount > 0 then
			table.insert(itemList,{
				type = itemTypeMap[_itemId],
				itemId = _itemId,
				count = tempCount
			})
		end
	end

	local atkFunc = self._atkFunc

	self._atkFunc = nil
	self._getRewardState = false

	local name = gModelPetDreanLand:GetPetDreamlandName(targetPointData.refId)
	---@type StructPetDreamLandPointData
	local pointData = targetPointData.pointData
	local petDreamlandLossStr = gModelPetDreanLand:GetConfigPetDreamlandLossStr()
	gModelGeneral:OpenUIOrdinTips({
		refId = 440003,
		--para = {name,pointData:GetHasOccupyTimeStr(),petDreamlandLossStr},
		para = {name,pointData:GetHasOccupyDetailTimeStr(),petDreamlandLossStr},
		func = atkFunc,
		itemList = itemList,
		emptyId = 39004,
	})
	self._targetPointData = nil
end

--- 偷袭
function UIPeWishLandPk:OnClickBtnRaid()
	if not self._newPointData then return end

	local pointData = self._pointData
	if pointData and not gModelPetDreanLand:CheckIsCanSteal(pointData.playerId) then
		GF.ShowMessage(ccClientText(43405))
		return
	end

	local newPointData = self._newPointData
	if newPointData:CheckHasAttackedProtect() then
		GF.ShowMessage(ccClientText(43380))
		return
	end

	if self._delayRaidTime and Time.time - self._delayRaidTime < 1 then
		return
	end

	self._delayRaidTime = Time.time

	---@type boolean 付费进攻
	local isPayGrab = false

	---@type boolean 免费抢夺
	local isFreeGrab = gModelPetDreanLand:CheckIsFreeGrab()
	if not isFreeGrab then
		isPayGrab = gModelPetDreanLand:CheckIsPayGrab()
		if not isPayGrab then
			--- 付费进攻上限
			gModelPetDreanLand:ShowVipUpCommonTips()
			return
		end
	end

	local func = function()
		local fightType = ModelPetDreanLand.TYPE_FIGHT_1
		if self:GetSkipBattle() then
			self:GoToBattle(fightType)
		else
			self:GoToFormation(fightType)
		end
	end
	local itemList = {}
	if isPayGrab then
		itemList = self:GetPayItemList()
	end
	if isPayGrab and #itemList > 0 then
		local payStr = self:GetPayItemsStr(itemList)
		local checkFunc = function()
			if not gModelGeneral:CheckItemListEnough(itemList,self:GetWndName()) then
				return
			end
			func()
		end
		gModelGeneral:OpenUIOrdinTips({
			refId = 440006,
			para = {payStr},
			func = checkFunc
		})
	else
		func()
	end
end

function UIPeWishLandPk:ReqPointCheck()
	gModelPetDreanLand:OnPetDreamLandPointCheckReq(self._refId,self._pointId)
end


function UIPeWishLandPk:InitOutputItemList(listTrans,list)
	list = list or {}
	local key = listTrans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(listTrans,list,function(...) self:OnDrawOutputItemCell(...) end)
	end
end

function UIPeWishLandPk:OnClickBtnJumpBattle()
	local jumpBattle = self:GetSkipBattle()
	local status = not jumpBattle
	gModelPetDreanLand:SetJumpPetDLBattle(status)
	self:RefreshJumpBattleState()
end

function UIPeWishLandPk:AskLosePoint(atkFunc)
	local longestPointData = gModelPetDreanLand:GetPlayerOccupyLongestTimeData()
	if not longestPointData then
		atkFunc()
		return
	end
	if self._getRewardState then  return end

	self._getRewardState = true
	self._atkFunc = atkFunc
	self._targetPointData = longestPointData

	gModelPetDreanLand:OnPetDreamLandPointRewardReq(longestPointData.refId)
end

function UIPeWishLandPk:OnCDTimer()
	for i,v in ipairs(self._cdInfos) do
		local cdData = v.cdData
		local timeLeft = GetTimestamp() - cdData.startTime
		timeLeft = math.floor(timeLeft)
		--self:SetWndText(v.txtTrans,string.replace(cdData.txtStr,LUtil.FormatTimespanNumber(timeLeft)))
		self:SetWndText(v.txtTrans,string.replace(cdData.txtStr,LUtil.FormatTimeStr1(timeLeft)))

		if timeLeft % self._petDreamlandTime == 0 then
			--- 超出时间不更新
			local petDreamlandTimeMax = self._petDreamlandTimeMax
			if petDreamlandTimeMax and petDreamlandTimeMax > 0 and petDreamlandTimeMax - timeLeft > 0 then
				self:ReqPointCheck()
			end
		end
	end
end

--- 抢夺
function UIPeWishLandPk:OnClickBtnLoot()
	if not self._newPointData then return end

	---@type boolean 付费进攻
	local isPayGrab = false

	---@type boolean 免费抢夺
	local isFreeGrab = gModelPetDreanLand:CheckIsFreeGrab()
	if not isFreeGrab then
		isPayGrab = gModelPetDreanLand:CheckIsPayGrab()
		if not isPayGrab then
			--- 付费进攻上限
			gModelPetDreanLand:ShowVipUpCommonTips()
			return
		end
	end

	if self._delayLootTime and Time.time - self._delayLootTime < 1 then
		return
	end

	self._delayLootTime = Time.time

	local itemList = {}
	if isPayGrab then
		itemList = self:GetPayItemList()
	end

	local func = function()
		if isPayGrab and #itemList > 0 then
			if not gModelGeneral:CheckItemListEnough(itemList,self:GetWndName()) then
				return
			end
		end
		local fightType = ModelPetDreanLand.TYPE_FIGHT_0
		if self:GetSkipBattle() then
			self:GoToBattle(fightType)
		else
			self:GoToFormation(fightType)
		end
	end

	local checkNeedAsk = function()
		if gModelPetDreanLand:CheckIsCanOccupy() then
			func()
		else
			self:AskLosePoint(func)
		end
	end

	if isPayGrab and #itemList > 0 then
		local payStr = self:GetPayItemsStr(itemList)
		gModelGeneral:OpenUIOrdinTips({
			refId = 440006,
			para = {payStr},
			func = checkNeedAsk
		})
	else
		checkNeedAsk()
	end
end

function UIPeWishLandPk:GoToBattle(fightType)
	if not self._newPointData then return end

	local combatType = LCombatTypeConst.COMBAT_TYPE_41
	if gModelFormation:IsFormationEmpty(combatType) then
		self:GoToFormation(fightType)
		return
	end

	gModelBattle:OnCombatReq({
		combatType = combatType,
		skipBattle = self:GetSkipBattle(),
		targetId = self._newPointData.id,
		dreamLandId = self._refId,
		fightType = fightType,
	})
end

function UIPeWishLandPk:GetSkipBattle()
	return gModelPetDreanLand:CheckIsCanJumpPetDLBattle()
end


function UIPeWishLandPk:OnTimer(key)
	if key == self._cdTimerKey then
		self:OnCDTimer()
	end
end


function UIPeWishLandPk:InitData()
	---@type number
	self._refId = self:GetWndArg("refId")

	---@type StructPetDreamLandPointData
	local pointData = self:GetWndArg("pointData")
	self._pointData = pointData

	local pointId = self:GetWndArg("pointId")
	if not pointId and pointData then
		pointId = pointData.id
	end
	self._pointId = pointId

	self._isRevenge = self:GetWndArg("isRevenge")


	self._petDreamlandTime = gModelPetDreanLand:GetConfigPetDreamlandTime() or 60

	self._petDreamlandTimeMax = gModelPetDreanLand:GetPetDreamlandTimeMax()

	local bGray = false
	local playerId
	if pointData then
		playerId = pointData.playerId
	else
		playerId = self:GetWndArg("playerId")
	end
	if playerId and not gModelPetDreanLand:CheckIsCanSteal(playerId) then
		bGray = true
	end
	self:SetWndButtonGray(self.mBtnRaid,bGray)
end


function UIPeWishLandPk:RefreshView()
	local showVip = false
	local hasFree = gModelPetDreanLand:CheckIsFreeGrab()
	if hasFree then
		self:SetWndText(self.mFreeTxt,string.replace(ccClientText(43321),gModelPetDreanLand:GetHasFreeGrabNum()))
	else
		local hasPayGrab = gModelPetDreanLand:CheckIsPayGrab()
		showVip = not hasPayGrab

		self:InitPayItemList()
	end
	CS.ShowObject(self.mFreeTxt,hasFree)
	CS.ShowObject(self.mPayDiv,not hasFree)
	CS.ShowObject(self.mUpVipDesc,showVip)
end

function UIPeWishLandPk:InitMsg()
	self:WndEventRecv(EventNames.On_Item_Change,function (...) self:OnItemChange() end)
	self:WndNetMsgRecv(LProtoIds.PetDreamLandPointCheckResp,function(...) self:OnPetDreamLandPointCheckResp(...) end)
	self:WndNetMsgRecv(LProtoIds.PetDreamLandPlayerDataChangeResp,function(...) self:OnPetDreamLandPlayerDataChangeResp(...) end)
	self:WndNetMsgRecv(LProtoIds.CombatResultResp,function(...) self:OnCombatResultResp(...) end)
	self:WndNetMsgRecv(LProtoIds.petDreamLandPointRewardResp,function(...) self:OnPetDreamLandPointRewardResp(...) end)
end

function UIPeWishLandPk:OnDrawHeroCell(list, item, itemdata, itempos)
	local Icon = self:FindWndTrans(item,"CommonUI/Icon")

	local herodata = {
		id = itemdata.id,
		refId = itemdata.refId,
		star = itemdata.star,
		level = itemdata.lv,
		skin = itemdata.skin,
		grade = itemdata.grade,
		fightPower = itemdata.fightPower,
		isResonance = itemdata.isResonance,
		treeInfo = itemdata.treeInfo,
	}
	self:CreateHeroIconImpl(Icon,herodata)

	self:SetWndClick(Icon,function()
		local heroInfo = {
			id = itemdata.id,
			refId = itemdata.refId,
			level = itemdata.lv,
			star = itemdata.star,
			grade = itemdata.grade,
			fightPower = itemdata.fightPower,
			isResonance = itemdata.isResonance,
			skin = itemdata.skin,
		}
		---@type StructPetDreamLandPointData
		local pointData = self._newPointData
		gModelHero:ReqShowHeroTipEx({
			playerId = pointData:GetPlayerId(),
			heroData = heroInfo,
			serverId = pointData:GetServerId()
		})
	end)
end

function UIPeWishLandPk:OnDrawPlayerOutputCell(list, item, itemdata, itempos)
	local OutputDiv = self:FindWndTrans(item,"OutputDiv")

	local OutputTxt = self:FindWndTrans(OutputDiv,"OutputTxt")
	local OutputItemList = self:FindWndTrans(OutputDiv,"OutputItemList")

	if itemdata.isNeedCD then
		table.insert(self._cdInfos,{
			cdData = itemdata.cdData,
			txtTrans = OutputTxt,
		})
	end

	self:SetWndText(OutputTxt,itemdata.txt)
	self:InitOutputItemList(OutputItemList,itemdata.list)
end

function UIPeWishLandPk:OnDrawOutputItemCell(list, item, itemdata, itempos)
	local IconDiv = self:FindWndTrans(item,"IconDiv")
	local Icon = self:FindWndTrans(IconDiv,"Icon")
	local Num = self:FindWndTrans(item,"Num")

	local icon = gModelItem:GetItemIconByRefId(itemdata.itemId)
	self:SetWndEasyImage(Icon,icon,function() CS.ShowObject(Icon,true) end,true)

	self:SetWndText(Num,itemdata.numStr)
end

function UIPeWishLandPk:GoToFormation(fightType)
	if not self._newPointData then return end

	local skipBattle = self:GetSkipBattle()
	local dreamLandId = self._refId
	local targetId = self._newPointData.id
	local combatHeroData = self._combatHeroData
	local otherName = self._newPointData:GetPlayerShowName()

	self:WndClose()

	gModelPetDreanLand:GoToPetDLFormation({
		combatType = LCombatTypeConst.COMBAT_TYPE_41,
		skipBattle = skipBattle,
		fightType = fightType,
		dreamLandId = dreamLandId,
		targetId = targetId,
		combatHeroData = combatHeroData,
		otherName = otherName
	})
end


function UIPeWishLandPk:GetPayItemList()
	local list = gModelPetDreanLand:GetCurGrabExpendItems()
	return list or {}
end

function UIPeWishLandPk:RefreshJumpBattleState()
	CS.ShowObject(self.mJumpBattleBgGou,self:GetSkipBattle())
end


function UIPeWishLandPk:InitPayItemList()
	local list = self:GetPayItemList()
	local uiList = self:FindUIScroll("mPayItemList")
	if uiList then
        uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("mPayItemList")
		uiList:Create(self.mPayItemList, list, function(...) self:OnDrawPayItemCell(...) end)
	end
end

function UIPeWishLandPk:OnPetDreamLandPointCheckResp(pb)
	local refId = pb.refId
	if refId ~= self._refId then return end

	if pb.pointData.id ~= self._pointId then return end

	self._cdInfos = {}

	---@type StructCombatHeroData
	self._combatHeroData = gModelGeneral:SetCombatHeroData(pb.heroData)

	---@type StructPetDreamLandPointData
	local pointData = gModelPetDreanLand:GetPetDreamLandPointData(pb.pointData)
	self._newPointData = pointData

	self:SetWndText(self.mPowerTxt,LUtil.PowerNumberCoversion(pointData:GetMainShowPlayerPower()))

	local lootRewardList = {}
	local rewardItem = pb.rewardItem
	for i,v in ipairs(rewardItem) do
		---@type StructRewardItem
		local rewardData = StructRewardItem:New()
		rewardData:CreateByPb(v)
		table.insert(lootRewardList,rewardData)
	end

	self:RefreshPlayerInfoDiv(pointData,lootRewardList)

	self:InitHeroList()

	self:RefreshView()
end

---@param rewardList table<StructRewardItem> 奖励物品列表
function UIPeWishLandPk:GetCommonRewardList(rewardList,sortItemMap)
	local list = {}
	---@param v StructRewardItem
	for i,v in ipairs(rewardList) do
		table.insert(list,{
			itemId = v.itemId,
			numStr = LUtil.NumberCoversion(v.count)
		})
	end
	table.sort(list,function(a, b)
		local sortA = sortItemMap[a.itemId] or 0
		local sortB = sortItemMap[b.itemId] or 0
		return sortA < sortB
	end)
	return list
end



function UIPeWishLandPk:GetHeroList()
	local list = {}
	if self._combatHeroData then
		list = self._combatHeroData:GetHeros()
	end
	return list
end

function UIPeWishLandPk:InitText()
	self:SetWndText(self.mLblBiaoti,ccClientText(43325))

	self:SetTextTile(self.mDesc,ccClientText(43319))
	self:SetWndText(self.mPayTxt,ccClientText(43326))
	self:SetWndText(self.mPassDesc,ccClientText(43322))

	self:SetWndButtonText(self.mBtnRaid,ccClientText(43323))
	self:SetWndButtonText(self.mBtnLoot,ccClientText(43324))

	self:SetWndText(self.mJumpBattleTxt,ccClientText(43320))

	local hyper = self:GetUIHyperText(self.mUpVipDesc)
	local str = hyper:AddHyper(ccClientText(43327),{func = function ()
		GF.OpenWndBottom("UIHuiYPay",{page = 2})
	end})
	self:SetWndText(self.mUpVipDesc,str)
end

function UIPeWishLandPk:GetPayItemsStr(itemList)
	local itemStrs = {}
	---@param v StructRewardItem
	for i,v in ipairs(itemList) do
		table.insert(itemStrs,string.replace(ccClientText(43362),
				gModelItem:GetNameByRefId(v.itemId),
				LUtil.NumberCoversion(v.itemNum)))
	end
	return table.concat(itemStrs,",")
end

function UIPeWishLandPk:OnDrawPayItemCell(list, item, itemdata, itempos)
	local Icon = self:FindWndTrans(item,"IconDiv/Icon")
	local Num = self:FindWndTrans(item,"Num")
	local itemId = itemdata.itemId
	local icon = gModelItem:GetItemIconByRefId(itemId)
	self:SetWndEasyImage(Icon,icon,function()
		CS.ShowObject(Icon,true)
	end,true)

	self:SetWndText(Num,LUtil.NumberCoversion(itemdata.itemNum))
end

function UIPeWishLandPk:InitEvent()
	--- 返回按钮必备
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnJumpBattle,function() self:OnClickBtnJumpBattle() end)
	self:SetWndClick(self.mBtnRaid,function() self:OnClickBtnRaid() end)
	self:SetWndClick(self.mBtnLoot,function() self:OnClickBtnLoot() end)
	-- self:SetWndClick(self.mXXXBtn,function() self:OnClickXXXBtnFunc() end)
end

function UIPeWishLandPk:OnPetDreamLandPlayerDataChangeResp(pb)
	self:RefreshView()
end

------------------------------------------------------------------
return UIPeWishLandPk