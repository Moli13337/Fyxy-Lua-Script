---
--- Created by Administrator.
--- DateTime: 2023/10/20 17:59:56
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDungeonDTD:LWnd
local UIDungeonDTD = LxWndClass("UIDungeonDTD", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDungeonDTD:UIDungeonDTD()
	self:SetHideHurdle()
	self._timeList = {}
	self._timeKey = "dungeonDailyTimeKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDungeonDTD:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDungeonDTD:OnCreate()
	LWnd.OnCreate(self)
	self._uiCommonList = {}
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDungeonDTD:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
	GF.CloseWndByName("UIBags")
end

function UIDungeonDTD:GetResidueTimeByRefId(refId,str)
	if not self._infoList then
		return ""
	end
	local info = self._infoList[refId]
	local timeText = info and info.timeText or ""
	if timeText == "" then
		return ""
	end
	local timespan = tonumber(timeText/1000 - GetTimestamp())
	if timespan < 0 then
		return ""
	end
	local textStr = ccLngText(str)
	if refId == 105 then
		local isEnd = gModelDreamTrip:IsEndMapIdx()
		if isEnd then
			textStr = ccClientText(20496)
		end
	end
	local timeStr = LUtil.FormatTimespanCn(timespan)
	return string.replace(textStr,timeStr)
end

function UIDungeonDTD:InitCommand()
	self:SetWndText(self.mTitleText,ccClientText(12800))
	self:RefreshData()
	self:RefreshReq()
end

function UIDungeonDTD:SetTime()
	for i, v in pairs(self._timeList) do
		local timeStr =self:GetResidueTimeByRefId(i,v.str)
		self:SetWndText(v.text,timeStr)
	end
end

function UIDungeonDTD:GetDreamTripText1(text1,str)
	if text1 == "" then
		return string.replace(str,ccClientText(12820))
	end
	local mapId = tonumber(text1)
	local ref = gModelDreamTrip:GetMapRefByMapId(mapId)
	if not ref then
		return string.replace(str,ccClientText(12821))
	end
	return string.replace(str,ccLngText(ref.name))
end

function UIDungeonDTD:GetDreamTripText2(text1,text2,str)
	if text1 == "" then
		return string.replace(str,ccClientText(12820))
	end
	local ref = gModelDreamTrip:GetMapRefByMapId(tonumber(text1))
	if text2 == "" then
		return string.replace(str,ccClientText(12820))
	end

	if not ref then
		return ""
	end

    if gModelDreamTrip:IsEndMapIdx() then
        return string.replace(str,ccClientText(20494))
    end

	return string.replace(str,tonumber(text2)+1 .."/"..ref.count)
end

function UIDungeonDTD:SetSpine(paintTans,key,name,scale)--设置Spine
	local spine = self:FindWndSpineByKey(key)
	if(spine)then
		self:DestroyWndSpineByKey(key)
	end
	self:CreateWndSpine(paintTans,name,key,false,function(dpSpine)
		dpSpine:SetScale(scale)
	end)
end

function UIDungeonDTD:OnDailyGameInfoResp(pb)
	self._infoList = gModelGeneral:GetDailyGameInfoResp(pb)
	self:RefreshData()
end

function UIDungeonDTD:GetWonderText2(text1,text2,str)
	if text2 == "" then
		return string.replace(str,ccClientText(12820))
	end
	return string.replace(str,text2.."/"..ModelWonderland.LAYER)
end

function UIDungeonDTD:OnTimer(key)
	if(self._timeKey == key)then
		self:SetTime()
	end
end


function UIDungeonDTD:OnClickItem(itemdata)
	--if(itemdata.combatType=="")then
	--	return
	--end

	local functionId = itemdata.functionId
	local fightType = 0
	local combatTypeArr = string.split(itemdata.combatType,",")
	for i, v in ipairs(combatTypeArr) do
		local combatType = tonumber(v)
		local isFight= gLFightManager:IsCombatTypeInFight(combatType)
		if isFight then
			fightType = combatType
			break
		end
	end

	if not gModelFunctionOpen:CheckIsOpened(functionId) then
		return
	end

	gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_PLAY,itemdata.refId)

	if fightType > 0 then
		gLFightManager:PrepareGoToBattle(fightType,{})
	else
		if itemdata.refId == 102 then --无尽试炼
			gModelFunctionOpen:Jump(functionId,self:GetWndName())
		elseif itemdata.refId == 104 then -- 奇境探险
			gModelGeneral:WonderlandEntrance()
			self:WndClose()
		elseif itemdata.refId == 105 then --梦境之旅
			gModelDreamTrip:GoToMap(function()
                if not self:IsWndValid() then return end
                self:WndClose()
            end)
		else
			gModelFunctionOpen:Jump(functionId,self:GetWndName())
		end
	end

end

function UIDungeonDTD:InitEvent()
	--self:SetWndClick(self.mBgImage, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn, function(...) self:WndCloseAndBack() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIDungeonDTD:OnDrawGame(list,item,itemdata)
	local bg = self:FindWndTrans(item,"Image")
	local timeText = self:FindWndTrans(item,"TimeText")
	local otherText1 = self:FindWndTrans(item,"OtherText1")
	local otherText2 = self:FindWndTrans(item,"OtherText2")
	--local titleBg = self:FindWndTrans(item,"TitleBg")
	local name = self:FindWndTrans(item,"TitleText")
	local desText = self:FindWndTrans(item,"DesText")
	local icon = self:FindWndTrans(item,"Icon")
	local iconEn = self:FindWndTrans(item,"IconEn")
	local itemList = self:FindWndTrans(item,"ItemList")

	local itemdataList = LxDataHelper.ParseItem(itemdata.reward) or {}
	local InstanceID = item:GetInstanceID()
	local uiItemList = self:GetUIScroll(InstanceID)
	if(uiItemList:GetList())then
		uiItemList:RefreshList(itemdataList)
	else
		uiItemList:Create(itemList,itemdataList,function (...) self:OnDrawItem(...) end)
	end

	self:SetWndEasyImage(bg,itemdata.bg)
	self:SetWndEasyImage(icon,itemdata.icon,nil,true)

	local desTextCn = self:FindWndTrans(icon, "DesText")

	--self:SetWndEasyImage(iconEn,itemdata.icon,nil,true)

	local isForeign = gLGameLanguage:IsForeignVersion()
	if isForeign then
		self:SetWndText(desTextCn,"")
		self:SetWndText(desText,ccLngText(itemdata.desc))
	else
		self:SetWndText(desTextCn,ccLngText(itemdata.desc))
		self:SetWndText(desText,"")
	end

	--CS.ShowObject(iconEn,isForeign)
	--CS.ShowObject(icon,not isForeign)
	self:SetWndText(name,ccLngText(itemdata.name))

	local functionId = itemdata.functionId
	local isOpen = gModelFunctionOpen:CheckIsOpened(functionId,false)
	CS.ShowObject(timeText,isOpen)
	CS.ShowObject(otherText1,isOpen)
	CS.ShowObject(otherText2,isOpen)
	local refId,timeTextR,text1,text2 = itemdata.refId,itemdata.timeText,itemdata.text1,itemdata.text2
	if isOpen then
		local timeStr = self:GetResidueTimeByRefId(refId,timeTextR)
		local text1Str = self:GetText1ByRefId(refId,text1)
		local text2Str = self:GetText2ByRefId(refId,text2)
		self:SetWndText(timeText,timeStr)
		self:SetWndText(otherText1,text1Str)
		self:SetWndText(otherText2,text2Str)
		self._timeList[itemdata.refId] = {text = timeText,str = timeTextR}
	end


	local mask = self:FindWndTrans(item,"Mask")
	local maskText = self:FindWndTrans(item,"Mask/MaskText")
	local loockIcon = self:FindWndTrans(item,"Mask/MaskText/LoockIcon")
	local combatSpint = self:FindWndTrans(item,"Mask/MaskText/CombatSpint")
	local textEff = self:FindWndTrans(item,"Mask/MaskText/TextEff")
	local textTransList = {}

	for i = 1, 6 do
		local image = self:FindWndTrans(textEff,"Image"..i)
		table.insert(textTransList,image)

		if isForeign then
			self:SetWndEasyImage(image,"trialcopy_ui_1",nil,true)
		end

		if i>3 then
			CS.ShowObject(image,not isForeign)
		end
	end
	--self:SetWndEasyImage(titleBg,itemdata.titleIcon)

	CS.ShowObject(mask,not isOpen)
	CS.ShowObject(loockIcon,not isOpen)

	--CS.ShowObject(combatSpint,not isOpen)
	--CS.ShowObject(textEff,not isOpen)

	if(not isOpen)then
		local text = gModelFunctionOpen:GetOpenTips(functionId)
		self:SetWndText(maskText,text)
		self:SetWndClick(item,function ()
			gModelFunctionOpen:CheckIsOpened(functionId,true)
		end)
	else
--[[		if(itemdata.combatType=="")then
			return
		end
		local inFight = false
		local combatTypeArr = string.split(itemdata.combatType,",")
		for i, v in ipairs(combatTypeArr) do
			local combatType = tonumber(v)
			inFight = gLFightManager:IsCombatTypeInFight(combatType)
			if inFight then
				break
			end
		end

		CS.ShowObject(mask,inFight)
		CS.ShowObject(combatSpint,inFight)
		CS.ShowObject(textEff,inFight)
		if inFight then
			self:SetSpine(combatSpint,InstanceID,"jian",1)
			self:SetTextEff(textTransList,InstanceID)
		else
			self:SetTextEff(nil,InstanceID)
		end]]
		self:SetWndClick(item,function ()
			self:OnClickItem(itemdata)
		end)
	end


    local RunMask = self:FindWndTrans(item,"RunMask")
	local showRunMask = self:ShowRunMask(itemdata,RunMask)
	CS.ShowObject(RunMask,showRunMask)

	self:InitTextSizeWithLanguage(name,-2)
end

function UIDungeonDTD:GetEndlesText2(text1,text2,str)
	if text2 == "" then
		return ""
	end
	local text = ""
	if text2 == "0" then
		text = ccClientText(12819)
	else
		text = ccClientText(12818)
	end
	return string.replace(str,text)
end

function UIDungeonDTD:ShowRunMask(itemdata,RunMask)
	local showRunMask = false
	local isOpen = gModelFunctionOpen:CheckIsOpened(itemdata.functionId,false)
	if isOpen then
		local InstanceID = RunMask:GetInstanceID()
		local DreamTripDiv = self:FindWndTrans(RunMask,"DreamTripDiv")
		local FightDiv = self:FindWndTrans(RunMask,"FightDiv")
		local showDreamTripDiv = false
		local showFightDiv = false
		local refId = itemdata.refId
		if refId == 105 then 									--梦境之旅
			-- 开始梦境之旅，未达终点、不在战斗中时，显示进行状态
			local selHero = gModelDreamTrip:IsSelHero()
			if selHero then
				local isEnd = gModelDreamTrip:IsEndMapIdx()
				if not isEnd then
					local isFight = gLFightManager:IsCombatTypeInFight(LCombatTypeConst.COMBAT_DREAMTRIP)
					if not isFight then
						showRunMask = true
						showDreamTripDiv = true
						local RunMaskText = self:FindWndTrans(DreamTripDiv,"RunMaskText")
						self:SetWndText(RunMaskText,ccClientText(13419) .. "...")
					end
				end
			end
			local Image = self:FindWndTrans(DreamTripDiv,"Image")
			if showDreamTripDiv then
				self:SetTextEff({Image},InstanceID,{
					moveTime = 0.6,moveH = 10
				})
			else
				self:SetTextEff(nil,InstanceID)
			end
		else
			local combatType = itemdata.combatType
			if combatType ~= "" then
				local inFight = false
				local combatTypeArr = string.split(combatType,",")
				for i, v in ipairs(combatTypeArr) do
					inFight = gLFightManager:IsCombatTypeInFight(tonumber(v))
					if inFight then
						break
					end
				end
				if inFight then
					local EffectRoot = self:FindWndTrans(FightDiv,"EffectRoot/Root")
					self:SetSpine(EffectRoot,InstanceID,"jian",1)

					local RunMaskText = self:FindWndTrans(FightDiv,"RunMaskText")
					self:SetWndText(RunMaskText,ccClientText(24212))
					showRunMask = true
				end
				showFightDiv = inFight
			end
		end
		CS.ShowObject(DreamTripDiv,showDreamTripDiv)
		CS.ShowObject(FightDiv,showFightDiv)
	end
	return showRunMask
end

function UIDungeonDTD:GetTimeCorridorText2(text1,text2,str)
	if text2 == "" then
		return string.replace(str,ccClientText(12820))
	end
	return string.replace(str,text2.."%")
end

function UIDungeonDTD:InitMessage()
	self:WndNetMsgRecv(LProtoIds.DailyGameInfoResp,function (pb)
		self:OnDailyGameInfoResp(pb)
	end)
	self:WndEventRecv(EventNames.ON_TIME_ZERO,function()
		self:RefreshReq()
	end)

	self:WndEventRecv(EventNames.ON_BATTLE_END,function()
		self:RefreshData()
	end)

    self:WndEventRecv(EventNames.ON_ENDLESS_FIGHT_STATE,function ()
        self:RefreshData()
    end)

end

function UIDungeonDTD:GetText2ByRefId(refId,str)
	if not self._infoList then
		return ""
	end
	local info = self._infoList[refId]
	local text1 = info and info.text1 or ""
	local text2 = info and info.text2 or ""

	local funcList = self._func2List
	if not funcList then
		funcList = {
			[102] =function(...) return self:GetEndlesText2(...) end,
			[103] =function(...) return self:GetTimeCorridorText2(...) end,
			[104] =function(...) return self:GetWonderText2(...) end,
			[105] =function(...) return self:GetDreamTripText2(...) end,
			[107] =function(...) return self:GetInvasionText2(...) end,
			[108] =function(...) return self:GetFairyTaleTDText2(...) end,
		}
		self._func2List = funcList
	end
	local func = funcList[refId]
	if func then
		return func(text1,text2,ccLngText(str))
	end
end

function UIDungeonDTD:GetInvasionText1(text1,str)
	if text1 == "" then
		return string.replace(str,ccClientText(12820))
	end
	local ref = ModelInvasion:GetMapRef(tonumber(text1))
	return string.replace(str,ccLngText(ref.bossName))
end

function UIDungeonDTD:OnDrawItem(list,item,itemdata)
	local root = CS.FindTrans(item,"Root")
	local uiCommonList = self._uiCommonList
	local InstanceID = item:GetInstanceID()
	local baseClass = uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		uiCommonList[InstanceID] = baseClass
		baseClass:Create(root)
	end
	local itype,itemId,itemNum = itemdata.itemType, itemdata.itemId, -1
	baseClass:SetCommonReward(itype, itemId, itemNum)
	self:SetWndClick(root,function()
		gModelGeneral:ShowCommonItemTipWnd({itemType = itype,itemId = itemId,itemNum = itemNum})
	end)
	baseClass:DoApply()
end

function UIDungeonDTD:SetTextEff(transs,key,aniInfo)
	local seqTween
	self:TweenSeqKill(key)
	if(not transs or #transs <1)then
		return
	end
	if not seqTween then
		seqTween = self:TweenSeqCreate(key,function(seq)
			local moveTime = aniInfo.moveTime or 0.2
			local moveH = aniInfo.moveH or 10
			for i, v in ipairs(transs) do
				local pos = Vector2.New(v.localPosition.x,v.localPosition.y + moveH)
				local moveTween = v:DOLocalMove(pos,moveTime)
				seq:Append(moveTween)
			end
			for i, v in ipairs(transs) do
				local pos = Vector2.New(v.localPosition.x,v.localPosition.y)
				local moveTween = v:DOLocalMove(pos,moveTime)
				seq:Append(moveTween)
			end
			seq:SetLoops(-1)
			seq:Play()
			return seq
		end)
	end
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(key)

	end)
end

function UIDungeonDTD:GetEndlesText1(text1,str)
	if text1 == "" then
		return ""
	end
	local text = ""
	local text1Arr = string.split(text1,"|")
	for i, v in ipairs(text1Arr) do
		local arr = string.split(v,"=")
		local titleStr = ccClientText((12812 + tonumber(arr[1])))
		local ref = gModelEndles:GetEndlessCheckpointRefByRefId(tonumber(arr[2]))
		if i == 1 then
			text = string.replace(titleStr,ref and ref.id or arr[2])
		else
			text = text .."/" .. string.replace(titleStr,ref and ref.id or arr[2])
		end
	end
	return string.replace(str,text)
end

function UIDungeonDTD:RefreshData()
	local refList = gModelDungeonDaily:GetGameTypes()
	local itemList = self._uiItemList
	if itemList then
		itemList:RefreshList(refList)
		--itemList:DrawAllItems()
	else
		itemList = self:GetUIScroll("itemList")
		itemList:Create(self.mItemList,refList,function(...)  self:OnDrawGame(...) end)
		itemList:EnableScroll(true,false)
		self._uiItemList = itemList
	end

	local isStart = false
	local _timeKey = self._timeKey
	for i, v in pairs(self._timeList) do
		isStart = true
		break
	end
	if isStart then
		if not self:IsTimerExist(_timeKey) then
			self:TimerStart(_timeKey,1,false,-1)
		end
	else
		self:TimerStop(_timeKey)
	end
end

function UIDungeonDTD:GetInvasionText2(text1,text2,str)
	if text2 == "" then
		return string.replace(str,ccClientText(12820))
	end
	return string.replace(str,text2)
end

function UIDungeonDTD:RefreshReq()
	local refList = gModelDungeonDaily:GetGameTypes()
	local list = {}
	for i, v in pairs(refList) do
		table.insert(list,v.refId)
	end
	gModelGeneral:OnDailyGameInfoReq(list)
end

function UIDungeonDTD:GetFairyTaleTDText1(text1, str)
	--local sort = gModelTowerDefence:GetBattleCurrentShowNum() or 0
	--return string.replace(str,tostring(sort))
end

function UIDungeonDTD:GetWonderText1(text1,str)
	if text1 == "" then
		return string.replace(str,ccClientText(12821))
	end
	local ref = gModelWonderland:GetThemeConfig(tonumber(text1))
	local pattern = ref.pattern
	local patternName = nil
	if pattern == ModelWonderland.NORMAL then
		patternName = ccClientText(16793)
	elseif pattern == ModelWonderland.HARD then
		patternName = ccClientText(16794)
	else
		patternName = ccClientText(16795)
	end
	local name = string.format("%s[%s]",ccLngText(ref.name),patternName)
	return string.replace(str,name)
end

function UIDungeonDTD:GetText1ByRefId(refId,str)
	if not self._infoList then
		return ""
	end
	local info = self._infoList[refId]
	local text1 = info and info.text1 or ""
	local funcList = self._funcList
	if not funcList then
		funcList = {
			[102] =function(...) return self:GetEndlesText1(...) end,
			[103] =function(...) return self:GetTimeCorridorText1(...) end,
			[104] =function(...) return self:GetWonderText1(...) end,
			[105] =function(...) return self:GetDreamTripText1(...) end,
			[107] =function(...) return self:GetInvasionText1(...) end,
			[108] =function(...) return self:GetFairyTaleTDText1(...) end,
		}
		self._funcList = funcList
	end
	local func = funcList[refId]
	if func then
		return func(text1,ccLngText(str))
	end
	return ""
end

function UIDungeonDTD:GetFairyTaleTDText2(text1,text2,str)
	return str
end

function UIDungeonDTD:GetTimeCorridorText1(text1,str)
	--if text1 == "" then
		return string.replace(str,ccClientText(12820))
	--end
	--local ref = gModelTimeCorridor:GetCheckpointRef(tonumber(text1))
	--local nameStr = nil
	--if ref.isShow == 0 then
	--	nameStr = string.format("%s-%s",ccClientText(19141),ccLngText(ref.name))
	--else
	--	nameStr = string.format("%s-%s",ccClientText(19142),ccLngText(ref.name))
	--
	--end
	--return string.replace(str,nameStr)
end
------------------------------------------------------------------
return UIDungeonDTD