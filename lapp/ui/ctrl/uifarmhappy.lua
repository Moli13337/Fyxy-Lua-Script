---
--- Created by Administrator.
--- DateTime: 2024/10/15 10:33:06
---
------------------------------------------------------------------
local typeSpineClick = typeof(CS.SpineClick)
local LWnd = LWnd
local Tweening = DG.Tweening
---@class UIFarmHappy:LWnd
local UIFarmHappy = LxWndClass("UIFarmHappy", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFarmHappy:UIFarmHappy()
	self.activityData = nil
	self._rankId = 0 
	self._playerId = 0
	self.dogState = 0--0休息 1巡逻
	self._farmTimeKey = "_farmTimeKey"
	self._seedTimeKey = "_seedTimeKey"
	self._spineStarPos = Vector3.one
	self._cropSpine = {}
	self._currencyTran = {}
	self.landTrans = {}
	self._fertiliering = false --施肥中停止计时器
	self.landGrowState = {} --记录生长过的地块
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFarmHappy:OnWndClose()
	LWnd.OnWndClose(self)
	if self.bubbleSequence then 
		self.bubbleSequence:Destroy()
		self.bubbleSequence = nil
	end
	if self.dogSequence then
		self.dogSequence:Destroy()
		self.dogSequence = nil
	end
	self:DestroyWndSpineByKey("farmDog")
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFarmHappy:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFarmHappy:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:OnEventClick()
	self:InitData()
	if not self.activityData then return end
	gModelActivity:OnActivityPageReq(self.activityData.sid)
	gModelFarm:OnFarmInfoReq(self.activityData.sid,self._playerId)
	self:OnRankReq()
	self:SetDefaultUI()
	self:InitLand()
	self:OnUpdateFarm()
	self:RefreshRank()
	self:SetCurrencyList()
end

function UIFarmHappy:ClearCropSpine()
	for i = 1, ModelFarm.MaxLandNum do
		local key = "cropGrow"..i
		self:DestroyWndSpineByKey(key)
	end
end

function UIFarmHappy:OnWndRefresh()
	LWnd.OnWndRefresh(self)
	self:ClearCropSpine()
	self:TimerStop(self._seedTimeKey)
	self:TimerStop(self._farmTimeKey)
	self:InitData()
	self:InitLand()
	if not self.isMyFarm then self.farmChange = true end
	if not self.activityData then return end
	gModelFarm:OnFarmInfoReq(self.activityData.sid,self._playerId)
	self:OnUpdateFarm()
end

function UIFarmHappy:FertilizerOneKey()
	local canOneKey, costNum,itemId = gModelFarm:OneKeyFertilizerRed(self.activityData.sid)
	if not canOneKey then
		if costNum>0 then
			GF.ShowMessage(ccClientText(45932))
		else
			GF.ShowMessage(ccClientText(45943))
		end
		return
	end
	local func = function()
		local lands = self._farmInfo.lands
		local landId = {}
		for _, value in pairs(lands) do
			table.insert(landId,value.index)
		end
		self._fertiliering = true
		gModelFarm:OnHappyFarmPlantFertilizationReq(self.activityData.sid,landId,costNum)
	end
	local costName = gModelItem:GetNameByRefId(itemId)
	gModelGeneral:OpenUIOrdinTips({refId = 470301,func = func,para = {costNum,costName},consume ={costNum,itemId}})
end
function UIFarmHappy:UpdateZhanling()
	if not self._mainCfg then self._mainCfg = gModelActivity:GetWebActivityDataById(self.activityData.sid).config end
	local param = gModelFunctionOpen:ModifyWndPara(self._mainCfg.jump)
	local isBuy = false
	if param and param.subPage then
		local sid = gModelActivity:GetSidByUniqueJump(param.subPage)
		local activityData = gModelActivity:GetActivityBySid(sid)
		if activityData and not string.isempty(activityData.moreInfo) then
			local moreInfo = JSON.decode(activityData.moreInfo)
			local buyPassNum = string.split(moreInfo.buyPassNum,",")
			for i,v in ipairs(buyPassNum) do
				v = tonumber(v)
				if v>0 then
					isBuy = true
					break
				end
			end
		end
	end
	CS.ShowObject(self.mImgAct,isBuy)
end

function UIFarmHappy:PlantSpine(lands)--播种
	for _, landIndx in pairs(lands) do
		if self.landTrans[landIndx] then CS.ShowObject(self.landTrans[landIndx].bubbleTran,false) end
		local key = "plantKey"..landIndx
		self:DestroyWndSpineByKey(key)
		local landTran = self.landTrans[landIndx]
		local dpSpine = self:CreateWndSpine(landTran.imgPlant,"Farm_zhongzi01",key,true,
		function(dpLoaded)
			dpLoaded:PlayAnimation(0,"idle01",false)
			dpLoaded:SetAnimationCompleteFunc(function(aniName)
				self:DestroyWndSpineByKey(key)
				self:CropGrowSpine(landIndx,true)--生长幼苗--静态
			end)
		end,true)
		dpSpine:StartLoad()
	end
end
function UIFarmHappy:GetRankRewardList()
	local modelId = gModelActivity:GetActivityModeIdBySid(self.activityData.sid)
	if (modelId == ModelActivity.MODEL_ACTIVITY_TYPE_156) then
		local pageList = self._pbDataList
		for i, v in ipairs(pageList) do
			local page = v
			if (page.pageType == 4) then
				local entry = page.entry
				local rewardList = {}
				for j, k in ipairs(entry) do
					local rewardData = {}
					local entryCfg = gModelActivity:GetWebActivityEntryData(self.activityData.sid, k.pageId, k.entryId)
					if not entryCfg then
						return
					end
					local entryId = k.entryId
					local items = LxDataHelper.ParseItem(entryCfg.reward)
					rewardData.index = entryId
					rewardData.reward = items
					local str = string.split(entryCfg.name, "~")
					local left = tonumber(str[1])
					local right = (str[2] and tonumber(str[2])) or left
					local rank = {}
					table.insert(rank, left)
					table.insert(rank, right)
					rewardData.rank = rank
					table.insert(rewardList, rewardData)
				end
				self._rewardList = rewardList
				return rewardList
			end
		end
	end
end

---state 1空地  2成长 3成熟
function UIFarmHappy:OnUpdateLandState(index,state)
	local itemTran = self.landTrans[index]
	local icon = "activity_156_btn_icon_7"
	if self.isMyFarm then
		 icon = state==1 and "activity_156_btn_icon_7" or "activity_156_btn_icon_8"
		 CS.ShowObject(itemTran.bubbleRed,state==3)
	else
		CS.ShowObject(itemTran.bubbleRed,false)
		local landInfo = self._farmInfo and self._farmInfo.lands[index]
		if state==3 and not landInfo.steal and landInfo.stealCount< self._mainCfg.stealingMax then
			icon = "activity_156_btn_icon_9"
			CS.ShowObject(itemTran.bubbleTran,true)
		else
			CS.ShowObject(itemTran.bubbleTran,false)
		end
	end
	self:SetWndEasyImage(itemTran.bubbleIcon,icon)
	local txtState = self.isMyFarm and ccClientText(45928) or ""
	if state==2 then
		txtState = self.isMyFarm and ccClientText(45929) or ""
	elseif state==3 then
		local landInfo = self._farmInfo and self._farmInfo.lands[index]
		local isSteal = landInfo.steal or landInfo.stealCount>=self._mainCfg.stealingMax
		txtState = self.isMyFarm and ccClientText(45930) or (isSteal and "" or ccClientText(45947))
	end
	self:SetWndText(itemTran.txtState,txtState or "")
end
function UIFarmHappy:OnRankReq()
	if self._rankId>0 then
		gModelRank:OnRankReq(2, self._rankId, 1, 3, self.activityData.sid)
	end
end
function UIFarmHappy:OnStartTime()
	if not self._farmInfo then return end
	local curTime = GetTimestamp()
	if self._endTime> curTime or self._farmInfo.patrolDogTime>curTime or self.timeLeng>0 then
		self:TimerStart(self._farmTimeKey,1,false,-1)
		self:SetFarmTime()
	end
	for _, recoverTime in pairs(self._farmInfo.seedRecoverTime) do
		if recoverTime > curTime  then
			self:TimerStart(self._seedTimeKey,1,false,-1)
			self:SetSeedTime()
			break
		end
	end

	CS.ShowObject(self.mDogTime,self._farmInfo.patrolDogTime>curTime)
end

function UIFarmHappy:OpenRankWnd()
	if self._rankId then
		local rankClear = self._mainCfg.rankClear
		local endTimeData = rankClear == 1 and self._mainCfg.rankClearTime or nil
		local wndData = {
			refId = self._rankId,
			sid = self.activityData.sid,
			page = 1,
			rewardList = self._rewardList,
			endTimeData = endTimeData,
			endTime = self.activityData.endTime
		}
		GF.OpenWndBottom("UIRkPop", wndData)
	end
end

function UIFarmHappy:OnClickZhanling()
	local functionId = self._mainCfg.jump
	if functionId and not gModelFunctionOpen:CheckIsOpened(functionId, true) then
		return
	end
	gModelFunctionOpen:Jump(functionId, self:GetWndName(),function(isBuy)
		if isBuy then gModelFarm:OnFarmInfoReq(self.activityData.sid,gModelPlayer:GetPlayerId()) end
	end)
end

function UIFarmHappy:OnEventClick()
	self:WndNetMsgRecv(LProtoIds.ItemChangeResp, function(pb)
		self:SetCurrencyList()
	end)
	self:WndEventRecv(EventNames.FARM_INFO_UPDATE,function()
		self:InitData()
		if self.farmChange and self._farmInfo then --防止多次刷新
			self.farmChange = false
			self:InitLand()
		end
		self:OnUpdateFarm()
	end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function(data,sid)
		if  self.activityData and sid == self.activityData.sid then
			self:InitData()
			self:OnRankReq()
			self:SetDefaultUI()
			self:OnUpdateFarm()
			self:SetCurrencyList()
		end
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
		local sid = pb.sid
		if self.activityData and sid ~= self.activityData.sid then
			return
		end
		if self._mainCfg and self._mainCfg.rankReward==1 then
			self:SetPageList(pb)
			self:GetRankRewardList()
		end
	end)

	self:WndEventRecv(EventNames.RANK_UPDATE_END, function(rankType, rankRefId)
		if rankRefId ~= self._rankId then
			return
		end
		self:RefreshRank()
	end)
	self:SetWndClick(self.mReturnBtn,function()
		if not self.isMyFarm then
			-- GF.OpenWnd("UIFarmHappy",{activityData = self.activityData,playerId = gModelPlayer:GetPlayerId()})
			self:OnEffectLoaded()
		else
			self:WndClose()
		end
	end)
	self:SetWndClick(self.mBtnZhanling,function()
		self:OnClickZhanling()
	end)
	self:SetWndClick(self.mRankClick,function()
		self:OpenRankWnd()
	end)
	self:SetWndClick(self.mHelpBtn, function()
		self:OnClickHelpBtn()
	end) --帮助按钮

	self:SetWndClick(self.mBtnOneStealing,function()
		self:OneKeyStealing()
	end)
	self:SetWndClick(self.mBtnOnePlant,function()
		GF.OpenWnd("UIFarmPlantOneKey",{activityData = self.activityData})
	end)
	self:SetWndClick(self.mBtnBatchPlant,function()
		GF.OpenWnd("UIFarmPlantBatch",{activityData = self.activityData})
	end)
	self:SetWndClick(self.mBtnOneFertilizer,function()
		self:FertilizerOneKey()
	end)
	self:SetWndClick(self.mBtnStealing,function()
		GF.OpenWnd("UIFarmList",{activityData = self.activityData,playerId =self._playerId})
	end)
	self:SetWndClick(self.mBtnLog,function()
		GF.OpenWnd("UIFarmLog",{activityData = self.activityData})
	end)
	self:SetWndClick(self.mBtnShop,function()
		GF.OpenWndBottom("UIDian",{page = ModelShop.ACTIVITY,subPage = self.activityData.sid})
	end)
	self:SetWndClick(self.mImgHouse,function()
		if self.isMyFarm then GF.OpenWnd("UIFarmDogButler",{activityData = self.activityData}) end
	end)
	self:SetWndClick(self.mImgScore,function()
		if self.isMyFarm and self._farmInfo.dropScore>0 then
			gModelFarm:OnHappyFarmTakeDropScoreReq(self.activityData.sid)
		end
	end)
	self:SetWndClick(self.mBtnOneGet,function()
		local matrueCount,lands = gModelFarm:GetFarmLands(self._playerId)
		if matrueCount<=0 then
			GF.ShowMessage(ccClientText(45944))
			return
		end
		gModelFarm:OnHappyFarmPickCropsReq(self.activityData.sid,0,self._playerId,lands)
	end)
	self:WndEventRecv(EventNames.FARM_DOGTIME_UPDATE,function(isWake)
		if isWake then
			self.dogState = 1
			self:DogSpine(true)
			self:DogFoodSpine(true)
		end
		CS.ShowObject(self.mImgFoodRed,self.isMyFarm and gModelFarm:ActivateDogRed(self.activityData.sid))
	end)
	self:WndEventRecv(EventNames.FARM_PLANT_RESULIT,function(lands)--种植
		self:PlantSpine(lands)
	end)
	self:WndEventRecv(EventNames.FARM_HARVEST_RESULIT,function(params)--收获
		self:HarvestSpine(params.lands,params.pb)
		self:OnRankReq()
	end)
	self:WndEventRecv(EventNames.FARM_FERTILIZATION,function(lands)--施肥
		self:FertilizerSpine(lands)
		self._fertiliering = false
	end)
end

function UIFarmHappy:GetRankId(activityData)
	if not activityData then return end
	local modelId = gModelActivity:GetActivityModeIdBySid(self.activityData.sid)
	if (modelId == ModelActivity.MODEL_ACTIVITY_TYPE_156) then
		local chuck = activityData.chunk
		local rankCfg
		for i, v in ipairs(chuck) do
			if (v.type == 4) then
				rankCfg = v
				break
			end
		end
		if (rankCfg) then
			local entryData = rankCfg.entries[1]
			local condition = entryData.condition
			local conditionArr = string.split(condition, ",")
			local eventArr = string.split(conditionArr[1], "=")
			local id = tonumber(eventArr[3])
			return id
		end
	end
end

function UIFarmHappy:OnCurrencyScroll(list, item, itemdata, itempos)
	local itemIcon = self:FindWndTrans(item, "Icon")
	local num = self:FindWndTrans(item, "Num")
	local btnDiv = self:FindWndTrans(item, "BtnDiv")
	local Time = self:FindWndTrans(item, "Time")
	local TxtTime = self:FindWndTrans(item, "Time/TxtTime")
	local itemId = tonumber(itemdata)
	local icon = gModelItem:GetItemImgByRefId(itemId)
	local itemNum = 0
	itemNum = gModelItem:GetNumByRefId(itemId)
	self:SetWndEasyImage(itemIcon, icon)
	local numStr = LUtil.NumberCoversion(itemNum)
	self:SetWndText(num, numStr)
	local _seedInfo = self._seedItem[itemId]
	self:SetWndClick(item, function()
		local itemData = {
			itemId = itemId,
			itemNum = itemNum,
			itemType = 1,
		}
		gModelGeneral:ShowCommonItemTipWnd(itemData)
	end)
	local ref = gModelItem:GetRefByRefId(itemId)
	CS.ShowObject(btnDiv,ref and not string.isempty(ref.jump))
	CS.ShowObject(Time,false)
	if _seedInfo and _seedInfo.num>itemNum then
		self._currencyTran[itemId] = {Time = Time,TxtTime = TxtTime}
		CS.ShowObject(Time,true)
	end
end

function UIFarmHappy:SetCurrencyList()
	if not self._mainCfg then return end
	local list = string.split(self._mainCfg.dropItemId,"|")
	local seedGets = string.split(self._mainCfg.seedGet,';')
	self._seedItem = {}
	for _, seedGet in ipairs(seedGets) do
		local info = string.split(seedGet,"=")
		self._seedItem[tonumber(info[1])] = {time = tonumber(info[2]),num = tonumber(info[3])}
	end
	local _uiCellList = self._uiCellList
	if _uiCellList then
		_uiCellList:RefreshList(list)
	else
		_uiCellList = self:GetUIScroll("_CurrencyScroll")
		_uiCellList:Create(self.mCurrencyList, list, function(...)
			self:OnCurrencyScroll(...)
		end)
		self._uiCellList = _uiCellList
	end
end

function UIFarmHappy:OnEffectLoaded()
	local instanceId = self.mEffectCloud:GetInstanceID()
	self:CreateWndEffect(self.mEffectCloud,"guochangdonghua_2",instanceId,100,nil,nil,nil,nil,nil,nil,nil,function()
		local seq = self:GetSeqCom()
		local instanceId = self.mEffectCloud:GetInstanceID()
		local sequence = seq:CreateSeq(instanceId)
		sequence:AppendInterval(0.8)
		sequence:OnComplete(function()
			seq:DeleteSeq(instanceId)
			self:ClearSeqCom()
			GF.OpenWnd("UIFarmHappy",{activityData = self.activityData,playerId = gModelPlayer:GetPlayerId()})
			self:DestroyWndEffectByKey(instanceId)
		end)
		sequence:PlayForward()
	end)
end

function UIFarmHappy:RefreshRank()
	if self._rankId <=0 then return end
	local list = self:GetRankList()
	local listTrans = self.mRankList
	local key = listTrans:GetInstanceID()
	local uiRankList = self:FindUIScroll(key)
	if uiRankList then
		uiRankList:RefreshList(list)
	else
		uiRankList = self:GetUIScroll(key)
		uiRankList:Create(listTrans, list, function(...)
			self:OnDrawRankCell(...)
		end)
	end

	local meRank = gModelRank:GetMeRank()
	local showMe = false
	if meRank and meRank.rank > 3 then
		self:SetWndText(self.mMeRankTxt, meRank.rank)
		self:SetWndText(self.mMeRankScore, "")--meRank.score
		self:SetWndText(self.mMeRankName, meRank.info:GetName())
		showMe = true
	end
	CS.ShowObject(self.mMeRankRoot, showMe)

end

function UIFarmHappy:SetSeedTime()
	local curTime = GetTimestamp()
	local isStop = true
	local isReq = false
	for seedId, recoverTime in pairs(self._farmInfo.seedRecoverTime) do
		local currencyTran = self._currencyTran[seedId]
		if currencyTran then
			local timeDif = os.difftime(recoverTime+3, curTime)
			if timeDif>=0 then
				local timeStr = LUtil.FormatTimeToCn3(timeDif)
				self:SetWndText(currencyTran.TxtTime, timeStr)
				isStop = false
			else
				CS.ShowObject(currencyTran.Time,false)
				self._currencyTran[seedId] = nil
				isReq = true
			end
		end
	end

	if isReq then gModelFarm:OnFarmInfoReq(self.activityData.sid,gModelPlayer:GetPlayerId()) end
	if isStop then self:TimerStop(self._seedTimeKey) end
end
function UIFarmHappy:InitLand()--初始进入或者变更农场时只能刷新一次
	local childNum = self.mLandGroup.childCount
	for i = 1, childNum do
		local item = self.mLandGroup:GetChild(i-1)
		local effTran = self.mLandEffects:GetChild(i-1)
		local itemTran = self.landTrans[i]
		if item and not itemTran then
			itemTran = {}
			self.landTrans[i] = itemTran
			itemTran.itemtran = item
			itemTran.effectTran = effTran
			itemTran.imgPlant = self:FindWndTrans(item,"ImgPlant")
			itemTran.txtState = self:FindWndTrans(item,"UIText")
			local SliderTran = self:FindWndTrans(item,"Slider")
			itemTran.slider = self:FindWndSlider(SliderTran,"Slider")
			itemTran.txtProBar = self:FindWndTrans(item,"Slider/TxtProBar")
			itemTran.bubbleTran = self:FindWndTrans(item,"ImgBubble")
			itemTran.bubbleIcon = self:FindWndTrans(item,"ImgBubble/ImgIcon")
			itemTran.bubbleRed = self:FindWndTrans(item,"ImgBubble/ImgRed")
			self:SetWndClick(item,function()
				self:OnLandClick(i)
			end)
		end
		--除首次外，以下状态通过动画更新
		CS.ShowObject(itemTran.slider.transform,false)
		local landInfo = self._farmInfo and self._farmInfo.lands[i]
		local isShow = not landInfo or landInfo:IsMatureCrop()
		CS.ShowObject(itemTran.bubbleTran,isShow)
		self:CropGrowSpine(i,true)
	end
	self:BubbleDoTween()
end

function UIFarmHappy:UpdateLands()
	if not self._farmInfo then return end
	local timeList = {}
	self.landTime = timeList
	self.timeLeng = 0
	local landInfos = self._farmInfo.lands
	---@type StructFarmLand
	local landData = nil
	for indx = 1, gModelFarm.MaxLandNum do
		local itemTran = self.landTrans[indx]
		landData = landInfos[indx]
		local state = 1
		if landData then
			if not landData:IsMatureCrop() then --生长
				self:SetWndText(itemTran.txtProBar,"")
				table.insert(timeList,indx)
				self.timeLeng = self.timeLeng+1
				state = 2
			else--成熟
				state = 3
			end
		end
		self:OnUpdateLandState(indx,state)
	end
	CS.ShowObject(self.mBtnOneFertilizer,#self._farmInfo.lands>0)
end

function UIFarmHappy:OnUpdatePanel()
	if not self._farmInfo then return end
	local remain = 0
	local isSteal = false
	if not self.isMyFarm then
		remain = gModelFarm:GetFarmStealNum(self.activityData.sid,gModelPlayer:GetPlayerId())
		for _, landInfo in pairs(self._farmInfo.lands) do
			if not landInfo.steal and self._mainCfg.stealingMax>landInfo.stealCount and landInfo:IsMatureCrop() then
				isSteal = true
			end
		end
	end
	--玩家名稱農場
	self:SetWndText(self.mFarmName,string.replace(ccClientText(45931),self._farmInfo.roleInfo.name))
	self:SetWndText(self.mTxtDogState, self.dogState>0 and ccClientText(45958) or ccClientText(45959))
	CS.ShowObject(self.mCurrencyList,self.isMyFarm)
	CS.ShowObject(self.mBtnZhanling,self.isMyFarm)
	CS.ShowObject(self.mRankGroup,self.isMyFarm)
	CS.ShowObject(self.mBtnOneStealing,not self.isMyFarm and remain>0 and isSteal)
	CS.ShowObject(self.mBtnStealing,self.isMyFarm)
	CS.ShowObject(self.mBtnLog,self.isMyFarm)
	CS.ShowObject(self.mBtnShop,self.isMyFarm)
	CS.ShowObject(self.mBtnOneGet,self.isMyFarm and gModelFarm:CropMatureRed())
	CS.ShowObject(self.mBtnOneFertilizer,self.isMyFarm and self.timeLeng>0)
	CS.ShowObject(self.mBtnOnePlant,self.isMyFarm and self._farmInfo.hasNilLand)
	CS.ShowObject(self.mBtnBatchPlant,self.isMyFarm and self._farmInfo.hasNilLand)
	CS.ShowObject(self.mImgScore,self.isMyFarm and self._farmInfo.dropScore>0)
	CS.ShowObject(self.mImgFoodRed,self.isMyFarm and gModelFarm:ActivateDogRed(self.activityData.sid))
	self:SetRed(self.mBtnOneGet,self.isMyFarm and gModelFarm:CropMatureRed())
	self:SetRed(self.mBtnStealing,self.isMyFarm and gModelFarm:GetFarmStealNum(self.activityData.sid)>0)
	local isRed = gModelFarm:ZhanlingRed(self.activityData.sid)
	self:SetRed(self.mBtnZhanling,isRed)
end
function UIFarmHappy:InitData()
	self._spineStarPos = Vector3(218,144,0)
	self.activityData = self:GetWndArg("activityData")
	self._playerId = self:GetWndArg("playerId")
	self.isMyFarm = self._playerId == gModelPlayer:GetPlayerId()
	---@type StructFarm
	self._farmInfo = gModelFarm:GetFarmDataByPlayerId(self._playerId)
	if self._farmInfo then
		self.dogState = self._farmInfo.patrolDogTime>GetTimestamp() and 1 or 0
	end
	if not self.activityData then return end
	self._endTime = self.activityData.endTime
	local _activityWebData = gModelActivity:GetWebActivityDataById(self.activityData.sid)
	if not _activityWebData then return end
	self._cropGrowTime = gModelFarm:GetCropGrowInfo(self.activityData.sid)
	self._rankId = self:GetRankId(_activityWebData)
	self._mainCfg = _activityWebData.config
	local crops = string.split(self._mainCfg.fx,",")
	for _, value in ipairs(crops) do
		local crop = string.split(value,"=")
		self._cropSpine[tonumber(crop[1])] = crop[2]
	end
	if gLGameLanguage:IsEnglishVersion()  then
		local btns = {self.mBtnOnePlant,
		self.mBtnBatchPlant,
		self.mBtnOneFertilizer,
		self.mBtnOneStealing,
		self.mBtnOneGet}
		for _, btn in ipairs(btns) do
			local uiText = LxUiHelper.FindXTextCtrl(CS.FindTrans(btn,"UIText"))
			uiText.characterSpacing = 4
		end
	end
end

function UIFarmHappy:OneKeyStealing()
	local myPlayerId = gModelPlayer:GetPlayerId()
	if not self.isMyFarm then
		local stealNum = gModelFarm:GetFarmStealNum(self.activityData.sid,myPlayerId)
		if stealNum<=0 then
			GF.ShowMessage(ccClientText(45956))
			return
		end
		local matureLand = {}
		local num = 0
		for _, landInfo in pairs(self._farmInfo.lands) do
			if not landInfo.steal and self._mainCfg.stealingMax>landInfo.stealCount and landInfo:IsMatureCrop() then
				table.insert(matureLand,landInfo.index)
				num = num+1
				if num >= stealNum then break end
			end
		end
		gModelFarm:OnHappyFarmPickCropsReq(self.activityData.sid,1,self._farmInfo.playerId,matureLand)
	end
end
function UIFarmHappy:GetRankList()
	local list = {}
	local rankList = gModelRank:GetRankListInfo(2, self._rankId)
	local showRankNum = 3
	local insNum = 0
	local rank
	for k, v in ipairs(rankList) do
		rank = v.rank
		if rank <= showRankNum then
			insNum = insNum + 1
			table.insert(list, {
				name = v.info._name,
				rank = rank,
				score = v.score,
				playerId = v.info._playerId,
			})
		end
	end
	if insNum < showRankNum then
		for i = insNum + 1, showRankNum do
			table.insert(list, {
				name = ccClientText(25203),
				rank = i,
				score = "",
				playerId = "-1",
			})
		end
	end
	return list
end
function UIFarmHappy:DogTween()
	self.mSpine.localScale = Vector3.one
	self.mTxtDogState.localScale = Vector3.one
	self.mSpine.localPosition = self._spineStarPos
	if self.dogSequence then
		self.dogSequence:Kill(false)
		self.dogSequence:Destroy()
	end
	if self.dogState>0 then
		self:SetWndText(self.mTxtDogState,ccClientText(45958))
		self.dogSequence = YXTween.TweenSequenceIns()
		local dtMoveTo = self.mSpine:DOLocalMove(Vector3.New(-90,0,0), 1.5):SetRelative():SetEase(Tweening.Ease.Linear)
		self.dogSequence:Append(dtMoveTo)
		local dtMoveTo2 = self.mSpine:DOLocalMove(Vector3.New(-260,100,0), 4.8):SetRelative():SetEase(Tweening.Ease.Linear)
		self.dogSequence:Append(dtMoveTo2)
		self.dogSequence:SetLoops(-1,Tweening.LoopType.Yoyo)
		self.dogSequence:OnStepComplete(function()
			if not self.mSpine then return end
			local scale = self.mSpine.localScale
			scale.x = scale.x>0 and -1 or 1
			self.mSpine.localScale = scale
			self.mTxtDogState.localScale = scale
			if self.dogState==0 and scale.x==1 then --休息状态时--回到狗窝-进入休息状态
				self:DogSpine()
				self.dogSequence:Kill(false)
				self.dogSequence:Destroy()
				scale.x = 1
				self.mSpine.localScale = scale
				self.mTxtDogState.localScale = scale
				self:SetWndText(self.mTxtDogState,ccClientText(45959))
			end
		end)
		self.dogSequence:Play()
	end
end

function UIFarmHappy:OnTimer(key)
	if self._farmTimeKey== key then
		self:SetFarmTime()
	end
	if self._seedTimeKey == key then
		self:SetSeedTime()
	end
end

function UIFarmHappy:DogSpine(isWake)
	if not self._farmInfo then return end
	self:DestroyWndSpineByKey("farmDog")
	local isWork = self.dogState >0
	local action = isWork and (isWake and "wake" or "walk") or "sleep"
	local func = function (dpLoaded)
		dpLoaded:PlayAnimationSolid(action,true)
		if not dpLoaded or not dpLoaded:IsDpValid() then return end--加点击事件
		local spineTrans = dpLoaded:GetSpineTrans()
		if not spineTrans then return end
		self._clickCom = spineTrans.gameObject:AddComponent(typeSpineClick)
		self._clickCom.isUISpine = true
		self._clickCom.onClick = function()
			if self.isMyFarm then
				GF.OpenWnd("UIFarmDogButler",{activityData = self.activityData})
			end
        end
		dpLoaded:SetAnimationCompleteFunc(function(ainName)
			if ainName == "wake" then
				dpLoaded:PlayAnimationSolid("walk", true)
			end
		end)
		self:DogTween()
	end
	local dpSpine = self:CreateWndSpine(self.mDogSpine,"Keji_01","farmDog",true,
	func,true)
	dpSpine:StartLoad()
end

function UIFarmHappy:OnClickHelpBtn()
	local helpTxt = self._mainCfg.signHelpTips
	local para = {
		title = gModelActivity:GetLngNameByActivitySid(self.activityData.sid),
		text = helpTxt
	}
	GF.OpenWnd("UIBzTips", para)
end
function UIFarmHappy:OnDrawRankCell(list, item, itemdata, itempos)
	local RankImgTrans = self:FindWndTrans(item, "RankImg")
	local NameTrans = self:FindWndTrans(item, "Name")
	local ScoreTrans = self:FindWndTrans(item, "Score")
	local Me = self:FindWndTrans(item, "Me")
	local rank = itemdata.rank
	local name = itemdata.name
	local score = itemdata.score
	local playerId = itemdata.playerId
	local myPlayerId = gModelPlayer:GetPlayerId()
	local color = myPlayerId == playerId and "#FFE094" or "#ffffff"
	-- name = LUtil.FormatColorStr(name, color)
	self:SetWndText(NameTrans, name)
	-- self:SetWndText(ScoreTrans, score)
	local rankScoreImgList = {"public_num_1","public_num_2","public_num_3"}
	local img = rankScoreImgList[rank]
	if img and RankImgTrans then
		self:SetWndEasyImage(RankImgTrans, img)
	end
	CS.ShowObject(Me, myPlayerId == playerId)
end

function UIFarmHappy:DogFoodSpine(isWake)
	self:DestroyWndSpineByKey("farmDogFood")
	local action = isWake and "idle01" or (self.dogState>0 and "man" or "kong")
	local dpSpine = self:CreateWndSpine(self.mImgFood,"Farm_gouliang01","farmDogFood",true,
	function(dpLoaded)
		dpLoaded:PlayAnimationSolid(action,false)
		local spineTrans = dpLoaded:GetSpineTrans()
		if not spineTrans then return end
		self._clickCom = spineTrans.gameObject:AddComponent(typeSpineClick)
		self._clickCom.isUISpine = true
		self._clickCom.onClick = function()
			if self.isMyFarm then
				GF.OpenWnd("UIFarmDogButler",{activityData = self.activityData})
			end
        end
	end,true)
	dpSpine:StartLoad()
end
function UIFarmHappy:SetFarmTime()
	local curTime = GetTimestamp()
	if self.timeLeng and self.timeLeng>0 and self.isMyFarm then
		local itemTran,landInfos= nil,nil
		for i, landIdx in pairs(self.landTime) do
			itemTran = self.landTrans[landIdx]
			landInfos = self._farmInfo and self._farmInfo.lands[landIdx] or {}
			local timespan = (landInfos.endTime or 0) - curTime
			if (timespan <= 0) then--成熟
				self:OnUpdateLandState(landIdx,3)
				self:CropGrowSpine(landIdx)
				self.timeLeng = self.timeLeng-1
				table.remove(self.landTime,i)
				self.landGrowState[landIdx] = nil
				CS.ShowObject(self.mBtnOneGet,true)
				CS.ShowObject(self.mBtnOneFertilizer,self.timeLeng>0)
			end
			local growTime = self._cropGrowTime and self._cropGrowTime[landInfos.crop]
			local value = timespan/(growTime and growTime.growTime or 0)
			if value<=0.7 and not self.landGrowState[landIdx] and not self._fertiliering then --自然生长，施肥除外
				self:CropGrowSpine(landIdx)
				self.landGrowState[landIdx] = true
			end
			itemTran.slider.value = value
			local timeStr = LUtil.FormatTimeToCn3(timespan)
			self:SetWndText(itemTran.txtProBar, timeStr)
		end
	end

    local timeDif = os.difftime(self._endTime, curTime)
	local patrolDogTime = self._farmInfo and self._farmInfo.patrolDogTime or 0
    local timeDif2 = os.difftime(patrolDogTime, curTime)

    if timeDif < 0 and self.timeLeng<=0 and timeDif2 < 0 then
        self:TimerStop(self._farmTimeKey)
        return
    end
    if timeDif>=-1 then
		local timeStr = LUtil.FormatTimeToCn3(timeDif)
		timeStr = string.replace(ccClientText(39002), timeStr)
		self:SetWndText(self.mTxtTime, timeStr)
		CS.ShowObject(self.mImgTime,timeDif>=0)
	end
    if timeDif2>=-1 then
		local timeStr = LUtil.FormatTimeToCn3(timeDif2)
		timeStr = string.replace(ccClientText(45940), timeStr)
		self:SetWndText(self.mWorkTime, timeStr)
		CS.ShowObject(self.mDogTime,timeDif2>=0)
		if timeDif2<0 then --巡邏結束
			self.dogState = 0
			self:DogFoodSpine()
			self:SetWndText(self.mTxtDogState,ccLngText(45959))
		end
	end
end
function UIFarmHappy:SetPageList(pb)
	local pbDataList = self._pbDataList or {}
	for i, v in ipairs(pb.pages) do
		local page = {}
		page = gModelActivity:GenerateActivePageDataFromPb(v)
		local isIns = false
		for k, j in pairs(pbDataList) do
			if (page.pageId == j.pageId) then
				pbDataList[k] = page
				isIns = true
			end
		end
		if isIns == false then
			table.insert(pbDataList, page)
		end
	end
	self._pbDataList = pbDataList
end

function UIFarmHappy:OnUpdateFarm()
	self:UpdateLands()
	self:OnStartTime()
	self:OnUpdatePanel()
	self:DogSpine()
	self:DogFoodSpine()
end

function UIFarmHappy:FertilizerSpine(lands)--施肥
	for _, landIndx in pairs(lands) do
		local key = "fertilizerKey"..landIndx
		self:DestroyWndSpineByKey(key)
		local landTran = self.landTrans[landIndx]
		local dpSpine = self:CreateWndSpine(landTran.imgPlant,"Farm_feiliao01",key,true,
		function(dpLoaded)
			dpLoaded:PlayAnimation(0,"idle01",false)
			dpLoaded:SetAnimationCompleteFunc(function(aniName)
				self:DestroyWndSpineByKey(key)
				local landInfo = self._farmInfo.lands[landIndx]
				local isMature,growState = false,0
				if landInfo then
					isMature,growState = landInfo:IsMatureCrop(self.activityData.sid)
				end
				if isMature then self.landGrowState[landIndx] = nil end
				self:CropGrowSpine(landIndx,growState==1)--生长成熟
			end)
		end,true)
		dpSpine:StartLoad()
	end
end

function UIFarmHappy:OnLandClick(index)
	local landInfo = self._farmInfo.lands[index]
	if self.isMyFarm then
		if not landInfo then--种植
			GF.OpenWnd("UIFarmPlant",{activityData = self.activityData,index = index})
		elseif landInfo:IsMatureCrop() then
			--收取
			gModelFarm:OnHappyFarmPickCropsReq(self.activityData.sid,0,self._playerId,{index})
		else
			GF.OpenWnd("UIFarmCropDetail",{activityData = self.activityData,index = index,func = function()
				self._fertiliering = true
			end})
			--详情施肥
		end
	else
		if landInfo and landInfo:IsMatureCrop() then
			if landInfo.steal or self._mainCfg.stealingMax<=landInfo.stealCount then return end
			local remainCount = gModelFarm:GetFarmStealNum(self.activityData.sid,gModelPlayer:GetPlayerId())
			if remainCount >0 then
				--偷取
				gModelFarm:OnHappyFarmPickCropsReq(self.activityData.sid,1,self._playerId,{index})
			else
				GF.ShowMessage(ccClientText(45956))
			end
		end
	end
end

function UIFarmHappy:BubbleDoTween()
	if self.bubbleSequence then return end
	self.bubbleSequence = YXTween.TweenSequenceIns()
	local isDestroy = false
	for _, landTran in pairs(self.landTrans) do
		local bubbleTran = landTran.bubbleTran
		local dtMoveTo = bubbleTran:DOLocalMoveY(10, 1):SetRelative():SetEase(Tweening.Ease.Linear)
		self.bubbleSequence:Join(dtMoveTo)
		isDestroy = true
	end
	self.bubbleSequence:SetLoops(-1,Tweening.LoopType.Yoyo)
	self.bubbleSequence:Play()
	-- if not isDestroy then self.bubbleSequence:Destroy() end
end

function UIFarmHappy:SetDefaultUI()
	if not self._mainCfg then return end
	--背景图
	local imgBg = self._mainCfg.image
	if not string.isempty(imgBg) then self:SetWndEasyImage(self.mBgImg,imgBg) end
	--帮助按钮
	local signHelpTipsPos = self._mainCfg.signHelpTipsPos
	if not string.isempty(signHelpTipsPos) then
		self:SetAnchorPos(self.mHelpBtn, LxDataHelper.ParseVector2NotEmpty(signHelpTipsPos))
	end
	CS.ShowObject(self.mHelpBtn,not string.isempty(self._mainCfg.signHelpTips))
	--标题
	local farmTitle = self._mainCfg.txt
	self:SetWndEasyImage(self.mTitleImg,farmTitle)
	local txtPos = self._mainCfg.txtPos
	if not string.isempty(txtPos) then
		self:SetAnchorPos(self.mTitleImg, LxDataHelper.ParseVector2NotEmpty(txtPos))
	end
	--战令按钮
	local btnIcon = self:FindWndTrans(self.mBtnZhanling, "Icon")
	local btnIconStr = self._mainCfg.giftIcon
	self:SetWndEasyImage(btnIcon, btnIconStr)
	local btnZhanlingPos =self._mainCfg.giftPos
	if (not string.isempty(btnZhanlingPos)) then
		self:SetAnchorPos(self.mBtnZhanling, LxDataHelper.ParseVector2NotEmpty(btnZhanlingPos))
	end
	local btnTxt = self:FindWndTrans(self.mBtnZhanling, "Txt")
	self:SetWndText(btnTxt, self._mainCfg.giftName)

	local scoreIcon = gModelItem:GetItemIconByRefId(self._mainCfg.itemId)
	if not string.isempty(scoreIcon) then
		self:SetWndEasyImage(self.mImgScoreIcon,scoreIcon,nil,false)
	end
	if self._rankId then
		self:SetWndText(self.mTxtRankTitle, ccClientText(36305))
		self:SetWndText(self.mDetailsRankTxt, ccClientText(36306))
	end
	local rankSwitch = self._mainCfg.rankSwitch
	CS.ShowObject(self.mRankGroup, self._rankId and rankSwitch == 1)

	self:SetTextTile(self.mBtnOnePlant,ccClientText(45913))
	self:SetTextTile(self.mBtnBatchPlant,ccClientText(45925))
	self:SetTextTile(self.mBtnOneFertilizer,ccClientText(45933))
	self:SetTextTile(self.mBtnOneStealing,ccClientText(45934))
	self:SetTextTile(self.mBtnStealing,ccClientText(45935))
	self:SetTextTile(self.mBtnLog,ccClientText(45905))
	self:SetTextTile(self.mBtnShop,ccClientText(45936))
	self:SetWndText(self.mTxtReturn,ccClientText(20723))
	self:SetTextTile(self.mBtnOneGet,ccClientText(45945))
end

function UIFarmHappy:HarvestSpine(lands,pb)--收割
	local leng = lands and #lands
	if not leng or leng<=0 then return end
	local finallyIndx = lands[leng].landIdx
	for _, land in ipairs(lands) do
		local landIndx = land.landIdx
		local cropId = land.crop
		if self.landTrans[landIndx] then
			CS.ShowObject(self.landTrans[landIndx].bubbleTran,false)
			CS.ShowObject(self.landTrans[landIndx].txtState,false)
		end
		local cropSpineName = self._cropSpine[cropId]
		if not string.isempty(cropSpineName) then
			local key = "cropGrow"..landIndx
			local spine = self:FindWndSpineByKey(key)
			local landTran = self.landTrans[landIndx]
			if not spine then
				local dpSpine = self:CreateWndSpine(landTran.imgPlant,cropSpineName,key,true,
				function(dpLoaded)
					dpLoaded:PlayAnimation(0,"harvest01",false)
					dpLoaded:SetAnimationCompleteFunc(function(ainName)
						dpLoaded:PlayAnimation(0,"harvest02",false)
						if ainName =="harvest02" then
							if self.isMyFarm then
								self:DestroyWndSpineByKey(key)
							else
								self:CropGrowSpine(landIndx,true)
							end
							if self.landTrans[landIndx] and self.isMyFarm then
								CS.ShowObject(self.landTrans[landIndx].bubbleTran,true)
								CS.ShowObject(self.landTrans[landIndx].txtState,true)
							end
							--奖励弹窗
							if finallyIndx == landIndx then
								if pb and pb.type == 1 then
									gModelFarm:OpenCommonTips(pb)
								else
									if pb.rewardInfo and  pb.rewardInfo.items[1] then gModelDraconic:ShowComReward(pb.rewardInfo) end
								end
							end
						end
					end)
				end,true)
				dpSpine:StartLoad()
			else
				spine:PlayAnimation(0,"harvest01",false)
				spine:SetAnimationCompleteFunc(function(ainName)
					spine:PlayAnimation(0,"harvest02",false)
					if ainName =="harvest02" then
						if self.isMyFarm then
							self:DestroyWndSpineByKey(key)
						else
							self:CropGrowSpine(landIndx,true)
						end
						if self.landTrans[landIndx] and self.isMyFarm then
							CS.ShowObject(self.landTrans[landIndx].bubbleTran,true)
							CS.ShowObject(self.landTrans[landIndx].txtState,true)
						end
						--奖励弹窗
						if finallyIndx == landIndx then
							if pb and pb.type == 1 then
								gModelFarm:OpenCommonTips(pb)
							else
								if pb.rewardInfo and  pb.rewardInfo.items[1] then gModelDraconic:ShowComReward(pb.rewardInfo) end
							end
						end
					end
				end)
			end
		end
	end
end

function UIFarmHappy:OnTryRefreshRedPoint(redPointType)
	local isRed = gModelFarm:ZhanlingRed(self.activityData.sid)
	self:SetRed(self.mBtnZhanling,isRed)
end

function UIFarmHappy:CropGrowSpine(landIndx,isIdle)--作物生长   --非idle状态时播完要回到idle
	if not self._farmInfo then return end
	local landInfo = self._farmInfo.lands[landIndx]
	local key = "cropGrow"..landIndx
	if not landInfo then
		self:DestroyWndSpineByKey(key)
		CS.ShowObject(self.landTrans[landIndx].slider.transform,false)
		return
	end
	local cropSpineName = self._cropSpine[landInfo.crop]
	if string.isempty(cropSpineName) then return end
	local spine = self:FindWndSpineByKey(key)
	local landTran = self.landTrans[landIndx]
	local isMature,growState = self._farmInfo.lands[landIndx]:IsMatureCrop(self.activityData.sid)
	local growAction = growState==3 and "grow02" or "grow01"
	local idleAction = isMature and "idle03" or ((growState and growState==2) and "idle02" or "idle01")

	local action = nil
	if isIdle then
		CS.ShowObject(self.landTrans[landIndx].slider.transform,not isMature and self.isMyFarm)
		action = idleAction
	else
		action = growAction
	end
	if not spine then
		local dpSpine = self:CreateWndSpine(landTran.imgPlant,cropSpineName,key,true,
		function(dpLoaded)
			dpLoaded:PlayAnimation(0,action,false)
			dpLoaded:SetAnimationCompleteFunc(function(aniName)
				if aniName == growAction then
					if not isIdle and isMature and self.landTrans[landIndx] then
						CS.ShowObject(self.landTrans[landIndx].bubbleTran,true)
						CS.ShowObject(self.landTrans[landIndx].slider.transform,false)
					elseif not isIdle then
						CS.ShowObject(self.landTrans[landIndx].bubbleTran,false)
						CS.ShowObject(self.landTrans[landIndx].slider.transform,true)
					end
					if not isIdle then --回到idle --- (可能是导致一闪原因)
						dpLoaded:PlayAnimation(0,idleAction,true)
					end
				end
			end)
		end,true)
		dpSpine:StartLoad()
	else
		spine:PlayAnimation(0,action,false)
		spine:SetAnimationCompleteFunc(function(aniName)
			if aniName == growAction then
				if not isIdle and isMature and self.landTrans[landIndx] then
					CS.ShowObject(self.landTrans[landIndx].bubbleTran,true)
					CS.ShowObject(self.landTrans[landIndx].slider.transform,false)
				elseif not isIdle then
					CS.ShowObject(self.landTrans[landIndx].bubbleTran,false)
					CS.ShowObject(self.landTrans[landIndx].slider.transform,true)
				end
				if not isIdle then --回到idle
					spine:PlayAnimation(0,idleAction,true)
				end
			end
		end)
	end
end
------------------------------------------------------------------
return UIFarmHappy