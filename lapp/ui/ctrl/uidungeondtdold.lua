---
--- Created by Administrator.
--- DateTime: 2023/10/20 17:59:56
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDungeonDTDOld:LWnd
local UIDungeonDTDOld = LxWndClass("UIDungeonDTDOld", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDungeonDTDOld:UIDungeonDTDOld()
	self:SetHideHurdle()

end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDungeonDTDOld:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDungeonDTDOld:OnCreate()
	LWnd.OnCreate(self)
	self._uiCommonList = {}
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDungeonDTDOld:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitCommand()
end

function UIDungeonDTDOld:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mCloseBtn, function(...) self:WndClose() end)
end

function UIDungeonDTDOld:InitCommand()
	self:SetWndText(self.mTitleText,ccClientText(12800))

	local refList = gModelDungeonDaily:GetGameTypes()
	local itemList = self:GetUIScroll("itemList")
	itemList:Create(self.mItemList,refList,function(...)  self:OnDrawGame(...) end)
end

function UIDungeonDTDOld:SetSpine(paintTans,key,name,scale)--设置Spine
	local spine = self:FindWndSpineByKey(key)
	if(spine)then
		self:DestroyWndSpineByKey(key)
	end
	self:CreateWndSpine(paintTans,name,key,false,function(dpSpine)
		dpSpine:SetScale(scale)
	end)
end

function UIDungeonDTDOld:SetTextEff(transs,key)
	local seqTween
	self:TweenSeqKill(key)
	if(not transs or #transs <1)then
		return
	end
	if not seqTween then
		seqTween = self:TweenSeqCreate(key,function(seq)
			local moveTime = 0.2
			local moveH = 10
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

function UIDungeonDTDOld:OnDrawItem(list,item,itemdata)
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

function UIDungeonDTDOld:OnDrawGame(list,item,itemdata)
	local bg = self:FindWndTrans(item,"Image")
	local titleBg = self:FindWndTrans(item,"TitleBg")
	local name = self:FindWndTrans(item,"TitleBg/TitleText")
	local desText = self:FindWndTrans(item,"DesText")
	local icon = self:FindWndTrans(item,"Icon")
	local itemList = self:FindWndTrans(item,"ItemList")
	local mask = self:FindWndTrans(item,"Mask")
	local maskText = self:FindWndTrans(item,"Mask/MaskText")
	local loockIcon = self:FindWndTrans(item,"Mask/MaskText/LoockIcon")
	local combatSpint = self:FindWndTrans(item,"Mask/MaskText/CombatSpint")
	local textEff = self:FindWndTrans(item,"Mask/MaskText/TextEff")
	local textTransList = {}
	for i = 1, 6 do
		local image = self:FindWndTrans(textEff,"Image"..i)
		table.insert(textTransList,image)
	end
	self:SetWndEasyImage(bg,itemdata.bg)
	self:SetWndEasyImage(titleBg,itemdata.titleIcon)
	self:SetWndEasyImage(icon,itemdata.icon,nil,true)
	self:SetWndText(name,ccLngText(itemdata.name))
	self:SetWndText(desText,ccLngText(itemdata.desc))

	local itemdataList = LxDataHelper.ParseItem(itemdata.reward)
	local InstanceID = item:GetInstanceID()
	local list = self:GetUIScroll(InstanceID)
	if(list:GetList())then
		list:RefreshList(itemdataList)
	else
		list:Create(itemList,itemdataList,function (...) self:OnDrawItem(...) end)
	end
	local functionId = itemdata.functionId
	local isOpen = gModelFunctionOpen:CheckIsOpened(functionId,false)
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
		if(itemdata.combatType=="")then
			return
		end
		local fightType = 0
		local combatTypeArr = string.split(itemdata.combatType,",")
		for i, v in ipairs(combatTypeArr) do
			local combatType = tonumber(v)
			local isFight= gLFightManager:IsCombatTypeInFight(combatType)
			if(isFight)then
				fightType = combatType
			end
		end


		local inFight = false
		if itemdata.refId == 102 then
			inFight = fightType>0 or gModelEndles:HaveNewSelectBuff()
		else
			inFight = fightType>0
		end
		CS.ShowObject(mask,inFight)
		CS.ShowObject(combatSpint,inFight)
		CS.ShowObject(textEff,inFight)
		if inFight then
			self:SetSpine(combatSpint,InstanceID,"jian",1)
			self:SetTextEff(textTransList,InstanceID)
		else
			self:SetTextEff(nil,InstanceID)
		end
		self:SetWndClick(item,function ()
			self:OnClickItem(itemdata)
		end)
	end
end


function UIDungeonDTDOld:OnClickItem(itemdata)
	if(itemdata.combatType=="")then
		return
	end
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

	if fightType > 0 then
		gLFightManager:PrepareGoToBattle(fightType,{})
	else
		if itemdata.refId == 102 then --无尽试炼
			if gModelEndles:HaveNewSelectBuff() then
				local combatData = gModelEndles:FormatEndlessCombatData()
				GF.OpenWndBottom("UIUendBfPop",{combatData = combatData})
			else
				self:WndClose()
				gModelFunctionOpen:Jump(functionId,self:GetWndName())
			end
		elseif itemdata.refId == 103 then -- 时光回廊
			GF.OpenWndBottom("WndTimeCorridorMain")
		elseif itemdata.refId == 104 then -- 奇境探险
			local isInMap = gModelWonderland:IsInMap()
			if isInMap then
				local isFight = gLFightManager:IsCombatTypeInFight(LCombatTypeConst.COMBAT_WONDERLAND)
				if isFight then
					gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_WONDERLAND)
					return
				end
				GF.OpenWndBottom("UIEden")
				GF.ChangeMap("LWonderlandMap")
			else
				GF.OpenWndBottom("UIEdenFront")
			end
			self:WndClose()
		else
			gModelFunctionOpen:Jump(functionId,self:GetWndName())
		end
	end

end
------------------------------------------------------------------
return UIDungeonDTDOld