---
--- Created by LCM.
--- DateTime: 2024/3/20 21:20:52
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeDivination:LWnd
local UIHopeDivination = LxWndClass("UIHopeDivination", LWnd)

UIHopeDivination.REWARD_NUM = 5					-- 转盘个数
UIHopeDivination.TURNCOUNT = 5					-- 圈数
UIHopeDivination.MULTIPLE = 2						-- 圈数
UIHopeDivination.ANGLE = -72						-- 角度
UIHopeDivination.IDLEPLAYTIME = 0.8				-- 动画闲置时间

UIHopeDivination.KEY_START = "0"					-- 开始占卜
UIHopeDivination.KEY_ENTER = "1"					-- 确定效果
UIHopeDivination.KEY_AGAIN = "2"					-- 重新占卜

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeDivination:UIHopeDivination()
	self._downCountTimerKey = "downCountTimerKey"		-- 抽奖动画key
	self._intervalTimerKey = "intervalTimerKey"			-- 间隔动画key
	self._idleTimerKey = "idleTimerKey"					-- 闲置动画key
	self._waitTimerKey = "waitTimerKey"					-- 等待n秒后计算

	self._sendMsg = false
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeDivination:OnWndClose()
	--gModelCommonDreamTrip:CheckSendSpeedUpEvent(self:GetExtraData())
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeDivination:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeDivination:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	CS.ShowObject(self.mCloseBtn,false)
	self:InitText()
	self:InitTextTransList()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
    self:InitEff()
    self:ShowIdleAni()
    self:RefreshView()
end

function UIHopeDivination:OnClickStartBtnFunc()
	if self._sendMsg then return end
	self._sendMsg = true
	local extraData = self:GetExtraData()
	gModelCommonDreamTrip:OnDreamTripStartEventProcessor(self._eventId,{
		mapType = extraData.mapType,
		sid = extraData.sid,
		argList = {UIHopeDivination.KEY_START},
	})
end

function UIHopeDivination:PlayBloodAni(bloodTrans,info)
	local key = bloodTrans:GetInstanceID()

	local seqTween = self:TweenSeqFind(key)
	if seqTween then
		self:TweenSeqKill(key)
		seqTween = nil
	end

	local EffRootTrans = info.EffRootTrans
	local oldHp = info.oldHp
	local newHp = info.newHp
	local isAdd = newHp > oldHp
	if isAdd then
		self:CreateWndEffect(EffRootTrans,"fx_qjtx_wupinshuaxin",key,100,false)
	end
	CS.ShowObject(EffRootTrans,isAdd)

	local func = function()
		if not self:IsWndValid() then return end
		seqTween = self:TweenSeqCreate(key, function(seq)
			local tween = YXTween.TweenFloat(oldHp,newHp,0.3,function (t)
				local progress = t / info.maxHp
				LxUiHelper.SetProgress(bloodTrans,progress)
			end)
			seq:Append(tween)
			return seq
		end)
		seqTween:OnComplete(function()
			self:TweenSeqKill(key)
		end)
		seqTween:PlayForward()
	end

	local KouTrans = info.KouTrans
	CS.ShowObject(KouTrans,false)
	local isHit = newHp < oldHp
	if isHit then
		local kouKey = KouTrans:GetInstanceID()
		self:TweenSeq_RootAlphaInOut({
			aniKey = kouKey,
			trans = KouTrans,
			beforeFunc = function()
				if not self:IsWndValid() then return end
				CS.ShowObject(KouTrans,true)
			end,
			endFunc = function()
				if not self:IsWndValid() then return end
				CS.ShowObject(KouTrans,false)
				func()
			end,
			initAlpha = true,
			loopNum = 2,
			fromAlpha = 0,
			toAlpha = 1,
			toTime = 1,
		})
	else
		func()
	end
end
------------------------- List -------------------------
function UIHopeDivination:GetItemList()
	local list = {}
	local serverData = gModelCommonDreamTrip:GetPlatformEventInfo(self._eventId,self._index,self:GetExtraData())
	if serverData then
		list = serverData.reward
	end
	return list
end

function UIHopeDivination:InitItemList()
	CS.ShowObject(self.mItemList,true)
	CS.ShowObject(self.mHeroList,false)

	local list = self:GetItemList()
	local uiItemList = self._uiItemList
	if uiItemList then
		uiItemList:RefreshList(list)
	else
		uiItemList = self:GetUIScroll("uiItemList")
		self._uiItemList = uiItemList
		uiItemList:Create(self.mItemList,list,function(...) self:OnDrawItemCell(...) end)
	end
end

function UIHopeDivination:GetHeroStatusInfo(heroId)
	return self._heroStatusList[heroId]
end

function UIHopeDivination:CheckHeroIsDel(heroId)
	local info = self:GetHeroStatusInfo(heroId)
	if not info then return true end
	return info.isDel
end

function UIHopeDivination:GetHeroData(hero,effectType,effectData)
	if not hero then return {} end
	local newHp
	local curHp = hero.curHp
	local maxHp = hero.maxHp
	if not self:CheckHeroIsDel(hero.id) then
		if effectType == ModelDreamTrip.DIVINATION_EFFECTTYPE_1 then
			newHp = curHp - maxHp * effectData
			newHp = math.floor(newHp)
		elseif effectType == ModelDreamTrip.DIVINATION_EFFECTTYPE_2 then
			newHp = curHp + maxHp * effectData
		elseif effectType == ModelDreamTrip.DIVINATION_EFFECTTYPE_NOEFF then
			newHp = curHp
		end
	else
		newHp = 0
	end
	local heroData = {
		id = hero.id,
		refId = hero.refId,
		heroType = hero.heroType,
		lvl = hero.lvl,
		star = hero.star,
		maxHp = maxHp,
		oldHp = curHp,
		newHp = newHp,
		power = hero.power,
		grade = hero.grade,
		resonance = hero.resonance,
		skin = hero.skin,
		treeInfo = hero.treeInfo,
	}
	return heroData
end

function UIHopeDivination:OnClickAgainBtnFunc()
	if self._sendMsg then return end
	local func = function()
		self._sendMsg = true
		self:SaveOldHeroDataList()
		local extraData = self:GetExtraData()
		gModelCommonDreamTrip:OnDreamTripStartEventProcessor(self._eventId,{
			mapType = extraData.mapType,
			sid = extraData.sid,
			argList = {UIHopeDivination.KEY_AGAIN},
		})
	end
	gModelGeneral:OpenUIOrdinTips({refId = 230007,func = func,para = {self._againItemNum}})
end

function UIHopeDivination:OnDrawHeroCell(list,item,itemdata,itempos)
	local CommonUITrans = self:FindWndTrans(item,"CommonUI")
	local IconTrans = self:FindWndTrans(CommonUITrans,"Icon")
	local EffRootTrans = self:FindWndTrans(CommonUITrans,"EffRoot")
	local KouTrans = self:FindWndTrans(CommonUITrans,"Kou")
	local bloodTrans = self:FindWndTrans(item,"blood")
	local deadTagTrans = self:FindWndTrans(item,"deadTag")
	CS.ShowObject(EffRootTrans,false)
	CS.ShowObject(bloodTrans,true)
	local InstanceID = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(InstanceID)
	baseClass:Create(IconTrans)

	local herodata = {
		trans = IconTrans,
		id = itemdata.id,
		refId = itemdata.refId,
		star = itemdata.star,
		level = itemdata.lvl,
		isResonance = itemdata.resonance,
		skin = itemdata.skin,
	}
	baseClass:SetHeroDataSet(herodata)
	baseClass:DoApply()

	local newHp = itemdata.newHp
	local oldHp = itemdata.oldHp
	local isDel = newHp <= 0
	CS.ShowObject(deadTagTrans,isDel)

	if isDel then
		LxUiHelper.SetProgress(bloodTrans,0)
	else
		self:PlayBloodAni(bloodTrans,{
			oldHp = oldHp,
			newHp = newHp,
			maxHp = itemdata.maxHp,
			EffRootTrans = EffRootTrans,
			KouTrans = KouTrans,
			id = itemdata.id,
		})
	end
end

function UIHopeDivination:GetHeroList()
--[[	local extraData = self:GetExtraData()

	local oldHeroList = self._oldHeroDataList or {}
	local oldKeyList = {}
	for i,v in ipairs(oldHeroList) do
		oldKeyList[v.id] = v
	end

	local indexList = {}
	local newHeroList = gModelCommonDreamTrip:GetSelHeroList(extraData)
	local newKeyList = {}
	for i,v in ipairs(newHeroList) do
		newKeyList[v.id] = v
		indexList[v.id] = 1
	end

	local newHeroInfo
	local list = {}
	for id,v in pairs(oldKeyList) do
		newHeroInfo = oldKeyList[id]
		if newHeroInfo then
			table.insert(list,{
				id = id,
				refId = newHeroInfo.refId,
				heroType = newHeroInfo.heroType,
				lvl = newHeroInfo.lvl,
				star = newHeroInfo.star,
				maxHp = newHeroInfo.maxHp,
				oldHp = v.curHp,
				newHp = newHeroInfo.curHp,
				power = newHeroInfo.power,
				grade = newHeroInfo.grade,
				resonance = newHeroInfo.resonance,
				skin = newHeroInfo.skin,
				treeInfo = newHeroInfo.treeInfo,
			})
		end
	end
	table.sort(list,function(a,b)
]]--[[
		local powerA,powerB = a.power,b.power
		if powerA ~= powerB then
			return powerA > powerB
		end
]]--[[

		local indexA = indexList[a.id] or 0
		local indexB = indexList[b.id] or 0
		return indexA < indexB
	end)]]

	local list = {}
	local extraData = self:GetExtraData()
	local newHeroList = gModelCommonDreamTrip:GetSelHeroList(extraData)
	if newHeroList then
		local divination_result = gModelCommonDreamTrip:GetDreamTripEventIdMoreInfoKey({
			mapType = extraData.mapType,
			sid = extraData.sid,
			eventId = self._eventId,
			index = self._index,
			key = StructDreamTripEventInfo.DIVINATION_RESULT,
		})
		local len = #divination_result
		local lastData = divination_result[len]
		if lastData then
			local divinationEffRefId = lastData.divinationEffRefId
			local ref = gModelDreamTrip:GetDreamTripDivinationResultRef(divinationEffRefId)
			if ref then
				local range = ref.range
				local effectType = ref.effectType
				local effectDate = ref.effectDate
				local showTips = false
				local isNotLimit = string.isempty(range)
				if isNotLimit then
					showTips = true
					for i,v in ipairs(newHeroList) do
						table.insert(list,self:GetHeroData(v,effectType,effectDate))
					end
				else
					local checkFunc = function(rangeType,effectValue,hero)
						local heroRefId = hero.refId
						if rangeType == ModelDreamTrip.DIVINATION_TAKEEFF_1 then
							return heroRefId == effectValue
						elseif rangeType == ModelDreamTrip.DIVINATION_TAKEEFF_2 then
							local heorCareerType = gModelHero:GetHeroCareerType(heroRefId)
							return heorCareerType == effectValue
						elseif rangeType == ModelDreamTrip.DIVINATION_TAKEEFF_3 then
							local heroRaceType = gModelHero:GetHeroRace(heroRefId)
							return heroRaceType == effectValue
						end
					end
					local rangeList = {}
					local rangeKeyList = {}
					range = string.split(range,"|")
					local rangeType
					local effectValue
					local rangeTypeNum = 0
					for i,v in ipairs(range) do
						v = string.split(v,"=")
						rangeType = tonumber(v[1])
						effectValue = tonumber(v[2])
						local rangeKeyInfo = rangeKeyList[rangeType]
						if not rangeKeyInfo then
							rangeTypeNum = rangeTypeNum + 1
							rangeKeyInfo = {}
							rangeKeyList[rangeType] = rangeKeyInfo
						end
						table.insert(rangeKeyInfo,{
							rangeType = rangeType,
							effectValue = effectValue,
						})
						table.insert(rangeList,{
							rangeType = rangeType,
							effectValue = effectValue,
						})
					end
					for i,v in ipairs(newHeroList) do
						local isEnough = false
						local meetStatusList = {}
						for tRangeType,tRangeValueList in pairs(rangeKeyList) do
							if not meetStatusList[tRangeType] then
								meetStatusList[tRangeType] = 0
							end
							for idx,val in ipairs(tRangeValueList) do
								if meetStatusList[tRangeType] == 1 then break end
								if checkFunc(val.rangeType,val.effectValue,v) then
									meetStatusList[tRangeType] = 1
								end
							end
						end
						local statusLen = 0
						for tRangeType,tRangeStatus in pairs(meetStatusList) do
							if tRangeStatus == 1 then statusLen = statusLen + 1 end
						end
						if rangeTypeNum == statusLen then
							isEnough = true
						end

--[[						for idx,val in ipairs(rangeList) do
							if not isEnough then break end
							LogError("val.rangeType = " .. val.rangeType .. ",val.effectValue = " .. val.effectValue)
							isEnough = checkFunc(val.rangeType,val.effectValue,v)
						end]]

						if isEnough then
							showTips = true
							table.insert(list,self:GetHeroData(v,effectType,effectDate))
						else
							table.insert(list,self:GetHeroData(v,ModelDreamTrip.DIVINATION_EFFECTTYPE_NOEFF,effectDate))
						end
					end
				end
				if showTips then
					GF.ShowMessage(ccLngText(ref.tips))
				end
			end
		end
	end
	return list
end

-- 轮盘格子旋转动画
function UIHopeDivination:PlayTurnAnimation()
	local index = self._curGridIndex
	if index > UIHopeDivination.REWARD_NUM then
		index = 1
	end
	local newIndex = index + 1
	if newIndex > UIHopeDivination.REWARD_NUM then
		newIndex = 1
	end
	self._curGridIndex = newIndex

	local z = index * UIHopeDivination.ANGLE

	local rotation = Quaternion.Euler(0,0,z)

	self.mArrowRoot.localRotation = rotation
end

function UIHopeDivination:OnTimer(key)
	if key == self._downCountTimerKey then
		self:PlayTurnAnimation()
		--self:ShowEffAni()
	elseif key == self._intervalTimerKey then
		self:RunIntervalAni()
	elseif key == self._idleTimerKey then
		self:PlayTurnAnimation()
	elseif key == self._waitTimerKey then
		self:RunEffectFunc()
	end
end

function UIHopeDivination:OnDreamTripStartEventResp(pb)
	if pb.eventId ~= self._eventId then return end
	local endInfo = pb.endInfo
	if not endInfo then
		self:ShowLog("没有找到 endInfo")
		gModelDreamTrip:OnDreamTripHeroInfoReq()
		gModelCommonDreamTrip:CheckSendSpeedUpEvent(self:GetExtraData())
		self:WndClose()
		return
	end
	if endInfo.state == StructDreamTripGrid.FINISH then
		self:ShowLog("事件已完成")
		gModelDreamTrip:OnDreamTripHeroInfoReq()
		gModelCommonDreamTrip:CheckSendSpeedUpEvent(self:GetExtraData())
		self:WndClose()
		return
	end
	local extraData = self:GetExtraData()
	local divination_result = gModelCommonDreamTrip:GetDreamTripEventIdMoreInfoKey({
		mapType = extraData.mapType,
		sid = extraData.sid,
		eventId = self._eventId,
		index = self._index,
		key = StructDreamTripEventInfo.DIVINATION_RESULT,
	})
	local len = #divination_result
	local data = divination_result[len]
	if not data then
		self:ShowLog("divination_result 数据没有找到")
		self._sendMsg = false
		return
	end
	local effectFunc = function()
		self:CreateZBEff(true)
		self:RefreshView()
		--self:ShowIdleAni()
		self._sendMsg = false
	end
	self._effectFunc = effectFunc
	local divinationRefId = data.divinationRefId
	local transInfoList = self._transInfoList
	local transInfo = transInfoList[divinationRefId]
	if not transInfo then
		self:ShowLog("transform 节点数据没有找到")
		self._sendMsg = false
		return
	end
	self:TimerStop(self._idleTimerKey)
	self:StartPlayTurnTable(transInfo.index - 1)
end

function UIHopeDivination:RunIntervalAni()
	-- 转盘动画3.0
	if self._curAnimation < #self._timeInterval then
		if self._curGridIndex  == self._targetItemIndex  then
			self._targetIndex = self._targetIndex - 1
			if self._targetIndex == 0 then
				self._curAnimation = self._curAnimation + 1
			else
				self._targetItemIndex = self._targetList[self._targetIndex]
			end

			-- 倍数递增来做降速效果
			self._speed = self._speed * UIHopeDivination.MULTIPLE

			-- 转动速度
			self:OnTimerStart(self._downCountTimerKey,self._speed)
		end
		-- 避免检测失误
		self:OnTimerStart(self._intervalTimerKey,0.01)
	elseif self._curAnimation == #self._timeInterval then
		if self._curGridIndex  == self._targetItemIndex then
			self._curAnimation = 1
			self._turnTableAnimationEnd = true
			self:TimerStop(self._downCountTimerKey)
			self:TimerStop(self._intervalTimerKey)
			self:OnTimerStart(self._waitTimerKey,0.5,1)
		end
	end
end

function UIHopeDivination:ShowIdleAni()
	self:OnTimerStart(self._idleTimerKey,UIHopeDivination.IDLEPLAYTIME)
end

-- 开启时间计时
function UIHopeDivination:OnTimerStart(key,time,loopCnt)
	self:TimerStop(key)
	if loopCnt == nil then
		loopCnt = -1
	end
	self:TimerStart(key,time,false,loopCnt)
end

function UIHopeDivination:InitTextTransList()
	local textTransList = {
		[1] = {
			trans = self.mText1,
			index = 1,
		},				-- 大吉
		[2] = {
			trans = self.mText2,
			index = 2
		},				-- 中吉
		[4] = {
			trans = self.mText3,
			index = 5
		},				-- 吉
		[3] = {
			trans = self.mText4,
			index = 3
		},				-- 小吉
		[5] = {
			trans = self.mText5,
			index = 4
		},				-- 欠佳
	}
	local typeInfo = {}
	local infoList = {}
	local tList = {}
	local divinationType
	for k,v in pairs(GameTable.DreamTripDivinationRef) do
		divinationType = v.type
		local tTypeInfo = typeInfo[divinationType]
		if not tTypeInfo then
			tTypeInfo = {}
			typeInfo[divinationType] = tTypeInfo
		end
		table.insert(tTypeInfo,{
			name = ccLngText(v.name),
			type = divinationType,
			refId = k,
		})
		if not tList[divinationType] then
			tList[divinationType] = true
			table.insert(infoList,{
				name = ccLngText(v.name),
				type = divinationType,
				refId = k,
			})
		end
	end
	table.sort(infoList,function(a,b)
		return a.type < b.type
	end)

	local transInfoList = {}
	local refId,type
	for i,v in ipairs(infoList) do
		refId = v.refId
		type = v.type
		local textTransInfo = textTransList[type]
		local textIndex = 1
		local textTrans
		if textTransInfo then
			textIndex = textTransInfo.index
			textTrans = textTransInfo.trans
			self:SetWndText(textTrans,v.name)
		end
		transInfoList[refId] = {
			trans = textTrans,
			type = type,
			refId = refId,
			index = textIndex
		}
		local typeInfoList = typeInfo[type]
		if typeInfoList then
			local tRefId
			for idx,val in ipairs(typeInfoList) do
				tRefId = val.refId
				if not transInfoList[tRefId] then
					transInfoList[tRefId] = {
						trans = textTrans,
						type = type,
						refId = tRefId,
						index = textIndex
					}
				end
			end
		end
	end

--[[	local transInfoList = {}
	local refId
	local tRefId
	for i,trans in ipairs(textTransList) do
		local info = infoList[i]
		if info then
			self:SetWndText(trans,info.name)
			refId = info.refId
			transInfoList[refId] = {
				trans = trans,
				type = info.type,
				refId = refId,
				index = i
			}
		end
		local tTypeInfo = typeInfo[i]
		if tTypeInfo then
			for idx,val in ipairs(tTypeInfo) do
				tRefId = val.refId
				if not transInfoList[tRefId] then
					transInfoList[tRefId] = {
						trans = trans,
						type = info.type,
						refId = tRefId,
						index = i
					}
				end
			end
		end
	end]]
	self._transInfoList = transInfoList
end

function UIHopeDivination:RecordHeroStatus()
	local oldHeroList = self._oldHeroDataList or {}
	local oldKeyList = {}
	local curHp
	local isDel
	for i,v in ipairs(oldHeroList) do
		curHp = v.curHp
		isDel = math.floor(curHp) <= 0
		oldKeyList[v.id] = {
			curHp = curHp,
			isDel = isDel
		}
	end
	self._heroStatusList = oldKeyList
end

-- 开始转动抽奖轮盘
function UIHopeDivination:StartPlayTurnTable(targetItemIndex)

	self._turnTableAnimationEnd = false

	self._targetItemIndex = targetItemIndex

	self:GetTurnTableAnimationData(targetItemIndex)

	-- 转动速度
	self:OnTimerStart(self._downCountTimerKey,self._speed)

	-- 下一个阶段转速
	self:OnTimerStart(self._intervalTimerKey,self._timeInterval[self._curAnimation])

end

-- 计算轮盘动画数据
function UIHopeDivination:GetTurnTableAnimationData(targetGridIndex)
	self._targetList = {}

	local gridCount = UIHopeDivination.TURNCOUNT * UIHopeDivination.REWARD_NUM
	self._speed = self._timeInterval[1] / gridCount
	self._targetIndex = self._decelerationGridCount

	local targetGridIndex1 = targetGridIndex - self._decelerationGridCount
	targetGridIndex1 = targetGridIndex1 < 0 and UIHopeDivination.REWARD_NUM + targetGridIndex1 or targetGridIndex1

	for i = 1, self._decelerationGridCount do
		local value = targetGridIndex1 + 1
		targetGridIndex1 = value > UIHopeDivination.REWARD_NUM and 1 or value
		table.insert(self._targetList,1,targetGridIndex1)
	end

	self._targetItemIndex = self._targetList[#self._targetList]
end

function UIHopeDivination:InitMsg()
	self:WndNetMsgRecv(LProtoIds.DreamTripStartEventResp,function(pb) self:OnDreamTripStartEventResp(pb) end)

	self:WndEventRecv(EventNames.NET_ERROR_CODE,function(code,error, argList)
		self._sendMsg = false
		local extraData = self:GetExtraData()
		gModelCommonDreamTrip:CancelEventIdStatus({
			mapType = extraData.mapType,
			sid = extraData.sid,
			eventId = self._eventId
		})
		--self:WndClose()
	end)
	-- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UIHopeDivination:InitData()
	self._eventId = self:GetWndArg("eventId")
	self._index = self:GetWndArg("index")
	self._extraData = self:GetWndArg("extraData")

	local eventRefId
	local extraData = self:GetExtraData()
	if self._eventId and self._index then
		local serverData = gModelCommonDreamTrip:GetPlatformEventInfo(self._eventId,self._index,extraData)
		if serverData then
			eventRefId = serverData.eventRefId
		end
	end
	local itemId,itemNum
	if eventRefId then
		local eventRef = gModelDreamTrip:GetDreamTripEventInfoByRefId(eventRefId)
		if eventRef then
			local parameter = string.split(eventRef.parameter,"=")
			itemId = tonumber(parameter[2])
			itemNum = tonumber(parameter[3])
		end
	end
	self._againItemId = itemId
	self._againItemNum = itemNum


	-- 轮盘阶段间隔
	self._timeInterval = {
		[1] = 0.8,
		[2] = 0.01,
	}

	self._effIndex = 1

	-- 当前轮盘动画阶段
	self._curAnimation = 1

	-- 动画控制参数：几个格子起降速
	self._decelerationGridCount = 2

	self._curGridIndex = 1

	self:SaveOldHeroDataList()
	self:RecordHeroStatus()
end

function UIHopeDivination:ShowEffAni()
	local effInfoList = self._effInfoList
	for i,v in ipairs(effInfoList) do
		CS.ShowObject(v.effRoot,self._effIndex == i)
	end
	local newIndex = self._effIndex + 1
	if newIndex > self._effInfoLen then
		newIndex = 1
	end
	self._effIndex = newIndex
end

function UIHopeDivination:GetExtraData()
	return self._extraData
end

function UIHopeDivination:InitText()
	self:SetWndButtonText(self.mStartBtn,ccClientText(28732))
	self:SetWndButtonText(self.mEnterBtn,ccClientText(28707))
	self:SetWndButtonText(self.mAgainBtn,ccClientText(28710), nil, -2, -30)
end

function UIHopeDivination:ShowLog(str)
	if LOG_INFO_ENABLED then
		printInfoNR(str)
	end
end

function UIHopeDivination:RunEffectFunc()
	if self._effectFunc then
		self._effectFunc()
	end
	self._effectFunc = nil
end

function UIHopeDivination:InitEff()
	self:CreateZBEff()
	local effInfoList = {
		{
			effName = "fx_xin",
			effKey = "fx_xin",
			effRoot = self.mXinEffRoot,
		},
		{
			effName = "fx_mofaqiu",
			effKey = "fx_mofaqiu",
			effRoot = self.mMoFaQiuEffRoot,
		},
		{
			effName = "fx_lazhu",
			effKey = "fx_lazhu",
			effRoot = self.mLaZhuEffRoot,
		},
		{
			effName = "fx_jinbi",
			effKey = "fx_jinbi",
			effRoot = self.mJinBiEffRoot,
		},
	}

	for i,v in ipairs(effInfoList) do
		self:CreateWndEffect(v.effRoot,v.effName,v.effKey,100,false,false)
	end

	self._effInfoList = effInfoList
	self._effInfoLen = #effInfoList
end

function UIHopeDivination:CreateZBEff(showRoot)
	showRoot = showRoot or false
	self:CreateWndEffect(self.mRetEffRoot,"fx_mjxk_zhanbu","fx_mjxk_zhanbu",100,false,false,nil,nil,nil,nil,nil,function()
		CS.ShowObject(self.mRetEffRoot,showRoot)
	end)
end

function UIHopeDivination:InitEvent()
    self:SetWndClick(self.mStartBtn,function() self:OnClickStartBtnFunc() end)
    self:SetWndClick(self.mEnterBtn,function() self:OnClickEnterBtnFunc() end)
    self:SetWndClick(self.mAgainBtn,function() self:OnClickAgainBtnFunc() end)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end)
end

function UIHopeDivination:SaveOldHeroDataList()
	local extraData = self:GetExtraData()
	self._oldHeroDataList = gModelCommonDreamTrip:GetSelHeroList(extraData)
end

function UIHopeDivination:OnDrawItemCell(list,item,itemdata,itempos)
	local IconTrans = self:FindWndTrans(item,"CommonUI/Icon")
	local InstanceID = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(InstanceID)
	baseClass:Create(IconTrans)
	baseClass:SetCommonReward(itemdata.itemType,itemdata.itemId,itemdata.itemNum)
	baseClass:DoApply()
end

function UIHopeDivination:RefreshView()
	local extraData = self:GetExtraData()
	local divination_result = gModelCommonDreamTrip:GetDreamTripEventIdMoreInfoKey({
		mapType = extraData.mapType,
		sid = extraData.sid,
		eventId = self._eventId,
		index = self._index,
		key = StructDreamTripEventInfo.DIVINATION_RESULT,
	})
	if not divination_result then return end

	local itemId = self._againItemId
	local itemNum = self._againItemNum
	local icon = gModelItem:GetItemIconByRefId(itemId)
	self:SetWndEasyImage(self.mPayItemIcon,icon)
	self:SetWndText(self.mPayItemNum,LUtil.NumberCoversion(itemNum))

	local len = #divination_result
	local lastData = divination_result[len]
	local divinationEffRefId = lastData and lastData.divinationEffRefId
	local isEmpty = not divinationEffRefId
	CS.ShowObject(self.mStartBtn,isEmpty)
	CS.ShowObject(self.mBtnList,not isEmpty)
	local ref = gModelDreamTrip:GetDreamTripDivinationResultRef(divinationEffRefId)
	if ref then
		self:SetTextTile(self.mRewardEffTxt,ccLngText(ref.tips))
	end
	if divinationEffRefId then
		local textRefId = lastData.textRefId
		local textRef = gModelDreamTrip:GetDreamTripTextRefByRefId(textRefId)
		if textRef then
			self:SetTextTile(self.mRewardStrTxt,ccLngText(textRef.dec))
		end
		local showHeroList = false
		if divinationEffRefId and divinationEffRefId > 0 then
			showHeroList = true
			self:InitHeroList()
		end
		if not showHeroList then
			self:InitItemList()
		end
	end
end

function UIHopeDivination:ShowTextRunAni()
	self:TimerStop(self._idleTimerKey)
	local random = math.random(1,UIHopeDivination.REWARD_NUM)
	self:StartPlayTurnTable(random)
end

function UIHopeDivination:OnClickEnterBtnFunc()
	if self._sendMsg then return end
	self._sendMsg = true
	local extraData = self:GetExtraData()
	gModelCommonDreamTrip:OnDreamTripStartEventProcessor(self._eventId,{
		mapType = extraData.mapType,
		sid = extraData.sid,
		argList = {UIHopeDivination.KEY_ENTER},
	})
end

function UIHopeDivination:InitHeroList()
	CS.ShowObject(self.mHeroList,true)
	CS.ShowObject(self.mItemList,false)

	local list = self:GetHeroList()
	local uiHeroList = self._uiHeroList
	if uiHeroList then
		uiHeroList:RefreshList(list)
	else
		uiHeroList = self:GetUIScroll("uiHeroList")
		self._uiHeroList = uiHeroList
		uiHeroList:Create(self.mHeroList,list,function(...) self:OnDrawHeroCell(...) end)
	end
end

------------------------- List -------------------------

------------------------------------------------------------------
return UIHopeDivination


