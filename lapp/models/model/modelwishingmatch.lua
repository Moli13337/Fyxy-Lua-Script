--- 愿望火柴配置
--- Created by Ease.
--- DateTime: 2023/10/18 16:24
local LModel = LModel
------------------------------------------------------------------
---@class ModelWishingMatch:LModel
local ModelWishingMatch = LxClass("ModelWishingMatch", LModel)
ModelWishingMatch.Main = 0
ModelWishingMatch.Item = 1
ModelWishingMatch.Cell = 2

function ModelWishingMatch:OnModelInit()
	self:ModelNetMsgRecv(LProtoIds.ItemExtraInfoResp, function(pb)
		if(pb)then
			local info = gModelGeneral:GetStructItemExtraInfoByPb(pb)
			self:SetItemExtraInfo(info)
		end
	end)
end
--在协议数据处理完之后需要调用finish
function ModelWishingMatch:OnModelRequest()
	self:InitData()
	self:ModelFinish()
end

function ModelWishingMatch:InitData()
end

function ModelWishingMatch:GetConfigByType(type)
	local configName
	if(type == ModelWishingMatch.Main)then
		configName = "WishingLampConfigRef"
	elseif(type == ModelWishingMatch.Item)then
		configName = "WishingLampItemRef"
	elseif(type == ModelWishingMatch.Cell)then
		configName = "WishingLampCallRef"
	end
	if(configName)then
		return gModelWishingMatch:GetModelConfig(configName)
	end
end
function ModelWishingMatch:GetMainCityTipsEndTime()
	local mainCfg = self:GetConfigByType(ModelWishingMatch.Main)
	return mainCfg.reminder
end
function ModelWishingMatch:GetConfigByTypeAndKey(type,key)
	local config = self:GetConfigByType(type)
	if(config)then
		return config[key]
	end
end
function ModelWishingMatch:GetItemInDataTimeStr(itemRefId)
	local cfg = self:GetConfigByTypeAndKey(ModelWishingMatch.Item,itemRefId)
	local time = cfg.time
	return self:GetInDataStrByTime(time)
end
function ModelWishingMatch:GetInDataStrByTime(time)
	local day = math.floor(time/86400)
	if(day>=1)then
		return string.format("%s%s",day,ccClientText(37806))
	end
	local hour = math.floor(time/3600)
	if(hour>=1)then
		return string.format("%s%s",hour,ccClientText(37807))
	end
	local min = math.floor(time/60)
	if(min>=1)then
		return string.format("%s%s",min,ccClientText(37808))
	end
	local sec = math.floor(time)
	if(sec>=1)then
		return string.format("%s%s",sec,ccClientText(37809))
	end
	return string.format("<color=#c81212>%s</color>",ccClientText(10254))
end
function ModelWishingMatch:GetInDataStrByTime2(time)
	local day = math.floor(time/86400)
	local hour = math.floor(time/3600)
	local min = math.floor(time/60)
	local second = time
	local dataList = {[1] = day,[2]= hour,[3] = min,[4] = second}
	local first,firstNum
	local sec,secNum
	for i = 1, 4 do
		if(dataList[i] and dataList[i]>=1)then
			first = i
			firstNum = dataList[i]
			if(dataList[i+1] and dataList[i+1]>=1)then
				sec = i+1
				local rate
				if i == 1 then
					rate = 24
				elseif i == 2 then
					rate = 60
				elseif i == 3 then
					rate = 60
				end
				if(rate)then
					secNum = dataList[i+1] - (firstNum*rate)
					break
				end
			end
		end
	end
	local timeStrFirst = first and firstNum..ccClientText(37805+first) or nil
	local timeStrSec = (sec and secNum and secNum>0) and secNum..ccClientText(37805+sec) or nil
	if(timeStrFirst)then
		local timeStr = timeStrSec and timeStrFirst..timeStrSec or timeStrFirst
		return timeStr
	end
	return string.format("<color=#c81212>%s</color>",ccClientText(10254))
end
function ModelWishingMatch:GetItemDropList(itemId)
	local ref = self:GetConfigByType(ModelWishingMatch.Cell)
	local list = {}
	for i, v in pairs(ref) do
		if(v.bagId== itemId)then
			table.insert(list,v)
		end
	end
	table.sort(list, function(a,b)
		return a.sort < b.sort
	end)
	return list
end
function ModelWishingMatch:GetCallRewardData(rewardList)
	local rewardCfg = self:GetConfigByTypeAndKey(ModelWishingMatch.Item,self._itemExtraInfo.refId)
	local mainCfg = self:GetConfigByType(ModelWishingMatch.Main)
	local dayNum = tonumber(self._itemExtraInfo.extra.dayNum + 1)
	local dayLastNum = rewardCfg.dayDropNum - dayNum
	local tipsTxtStr = string.replace(ccClientText(37815),dayLastNum)
	local allNum = tonumber(self._itemExtraInfo.extra.allNum + 1)
	local allLastNum = rewardCfg.allDropNum - allNum
	local showAgainBtn = dayLastNum>0 and allLastNum>0
	local data = {
		itemList = rewardList,
		btnList = self:GetCallRewardBtnList(showAgainBtn),
		botTipsTxtStr = tipsTxtStr,
		bgPath = mainCfg.showBg
	}
	return data
end
function ModelWishingMatch:GetCallRewardBtnList(showAgainBtn)
	local data = {}
	local btnCnt = showAgainBtn and 2 or 1
	for i = 1, btnCnt do
		local btnTxtIndex = 37809+i
		local btnFunc
		if(i == 1)then
			btnFunc = function()
				local wndIns = GF.FindFirstWndByName("UIOrdinYellAward2")
				if(wndIns)then
					GF.CloseWndByName("UIOrdinYellAward2")
				end
			end
		else
			btnFunc = function()
				local refId = self._itemExtraInfo.refId
				local id = self._itemExtraInfo.id
				local itemUseInfos = self:GetItemUseInfos(refId,id)
				gModelItem:OnItemUseReq(itemUseInfos)
				gModelItem:OnItemExtraInfoReq(id)
			end
		end
		local btnPath = "public_btn_3_"..i
		table.insert(data,{btnTxtIndex = btnTxtIndex,btnFunc = btnFunc,btnPath = btnPath})
	end
	return data
end
function ModelWishingMatch:SetItemExtraInfo(pb)
	self._itemExtraInfo = pb
end
function ModelWishingMatch:GetItemUseInfos(refId,id)
	local itemUseInfos = {}
	local itemUseInfo = {
		refId = refId,
		num = 1,
		params = tostring(id),
	}
	table.insert(itemUseInfos,itemUseInfo)
	return itemUseInfos
end
function ModelWishingMatch:IsWishingMatchItem(refId)
	local itemRef = gModelItem:GetRefByRefId(refId)
	return itemRef.type == ModelItem.ITEM_WISH_MATCH
end
function ModelWishingMatch:CheckCanDraw(refId,dayNum,allNum,endTime,showTipsTxt)
	local rewardCfg = gModelWishingMatch:GetConfigByTypeAndKey(ModelWishingMatch.Item,refId)
	local dayDrawLimit = rewardCfg.dayDropNum
	local allDrawLimit = rewardCfg.allDropNum
	local nowTime = GetTimestamp()
	local timeDif = os.difftime(endTime/1000, nowTime)
	if(dayNum<dayDrawLimit and allNum<allDrawLimit and timeDif>0)then
		return true
	end
	if(showTipsTxt)then
		if(timeDif<=0)then
			GF.ShowMessage(ccClientText(37812))
		elseif(allNum>=allDrawLimit)then
			GF.ShowMessage(ccClientText(37813))
		elseif(dayNum>=dayDrawLimit)then
			GF.ShowMessage(ccClientText(37814))
		end
	end
end
return ModelWishingMatch