---
--- Created by Administrator.
--- DateTime: 2023/10/31 15:41:30
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEdenTsure:LWnd
local UIEdenTsure = LxWndClass("UIEdenTsure", LWnd)

local Tweening = DG.Tweening
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEdenTsure:UIEdenTsure()
	---@type table<number,CommonIcon>
	self._uiIconClsList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEdenTsure:OnWndClose()
	self:ClearCommonIconList(self._uiIconClsList)
	self:ClearTween()
	self:CheckShowPower()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEdenTsure:OnCreate()
	LWnd.OnCreate(self)
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEdenTsure:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:SetStaticContent()
	self:InitUIEvent()
	self:RefreshUI()

	local oldPower = gModelWonderland:GetCurFormationPower()
	self._oldPower = oldPower

end

function UIEdenTsure:OnClickItem(index)
	if self._select == index then
		return
	end

	local item = self._itemUIList[self._select]
	if item then
		local treasure = self:FindWndTrans(item,"TreasureIcon")
		self:SetTreaSelect(treasure,false)
	end


	--TreasureIcon.ShowSelect(treasure,false)
	item = self._itemUIList[index]
	local treasure = self:FindWndTrans(item,"TreasureIcon")
	--TreasureIcon.ShowSelect(treasure,true)
    self:SetTreaSelect(treasure,true)

	self._select = index

	--local effectKey = self._selectEffKey
	--self:DestroyWndEffectByKey(effectKey)
	--self:CreateWndEffect(treasure,"fx_ui_qjmx_kapai",effectKey,100)

	--local list = self:GetUIScroll("heroList")
	--list:DrawAllItems()

	self:RefreshAllHero()
end

function UIEdenTsure:SetTreaSelect(item,isSelect)
    local select = self:FindWndTrans(item,"select")
    CS.ShowObject(select,isSelect)
	--local instanceId = item:GetInstanceID()

	if isSelect then
        item.localPosition = Vector3.New(0,30,0)
        item.localScale = Vector3.New(1.1,1.1,1.1)
		--self:CreateWndEffect(item,"ui_fx_mokashaoguang",instanceId,100)
	else
        item.localPosition = Vector3.New(0,0,0)
        item.localScale = Vector3.New(1,1,1)
		--self:DestroyWndEffectByKey(instanceId)
	end

end

function UIEdenTsure:RefreshAllHero()
	for k,v in pairs(self._heroItemList) do
		local item = v.item
		local itemdata = v.itemdata
		local frame = self:FindWndTrans(item,"frame")
		local refId = itemdata.refId
		local showFrame = self:CheckShowFrame(refId)
		CS.ShowObject(frame,showFrame)
	end
end

function UIEdenTsure:GetSelectInfo()
	local defaultPara =
	{
		type = -2
	}
	if self._select ==0 then
		return defaultPara
	end
	local treasureInfo = self._treasureList[self._select]
	local treasureId = treasureInfo.id
	local para = gModelWonderland:GetTreasureRange(treasureId) or {defaultPara}

	return para
end

function UIEdenTsure:InitUIEvent()
	self:SetWndClick(self.mMask,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mConfirmBtn,function () self:OnClickConfirm() end,LSoundConst.CLICK_BUTTON_COMMON)
end

function UIEdenTsure:CheckShowFrame(refId)
	local rangeList = self:GetSelectInfo()

	for k,v in ipairs(rangeList) do
		local type = v.type
		local para = v.para
		local isOn = false
		if type == -2 then
			isOn = false
		elseif type == -1 then
			isOn = true
		elseif type == 1 then
			isOn = para == refId
		elseif type == 2 then
			local career = gModelHero:GetHeroCareerType(refId)
			isOn = para == career
		elseif type == 3 then
			local race = gModelHero:GetHeroRace(refId)
			isOn = para == race
		end
		if isOn then
			return true
		end
	end

	return false
end

function UIEdenTsure:OnDrawItem(list,item,itemdata,itempos)
	local treasure = self:FindWndTrans(item,"TreasureIcon")

	local id = itemdata.id

	local canLv,newId,level = gModelWonderland:CanTreasureLvUp(id)
	local data ={
		refId = newId,
		lv = level,
		canLvUp = canLv,
	}



	TreasureIcon.SetIcon(treasure,data,self)
	self:SetWndClick(item,function () self:OnClickItem(itempos) end)

	self._itemUIList[itempos] = item
end

function UIEdenTsure:TweenTreasure(item,itemdata)
	local canLv,newId,level = gModelWonderland:CanTreasureLvUp(itemdata.id)
	local data =
	{
		refId = newId,
		lv = level,
		canLvUp = canLv,
	}


	local treasure = self:FindWndTrans(self.mFlyRoot,"TreasureIcon")
	TreasureIcon.SetIcon(treasure,data,self)

	treasure.localPosition = Vector3.New(0,30,0)
	treasure.localScale = Vector3.New(1.1,1.1,1.1)
	--local effectKey = self._selectEffKey
	--self:DestroyWndEffectByKey(effectKey)
	--self:CreateWndEffect(treasure,"fx_ui_qjmx_kapai",effectKey,100)
	local startPos = item.transform.position
	self.mFlyRoot.transform.position = startPos
	CS.ShowObject(self.mAniRoot,false)
	CS.ShowObject(self.mFlyRoot,true)

	local wnd= GF.FindFirstWndByName("UIEden")
	if not wnd then
		return
	end
	local endPos = wnd:GetTreasureBtnPos()

	local seqCom = self:GetSeqCom()
	local seq =seqCom:CreateSeq("cardFly")
	self._moveTweenSeq = seq
	seq:SetAutoKill(true)
	local duration = 0.6
	local tween = self.mFlyRoot.transform:DOMove(endPos,duration)
	local scaleTween = self.mFlyRoot.transform:DOScale(Vector3.New(0.5,0.5,0.5),duration)
	local rotateTween = self.mFlyRoot.transform:DORotate(Vector3.New(0,0,30),duration)
	if canLv then
		seq:AppendCallback(function ()
			self:CreateWndEffect(treasure,"ui_fx_mokashengji","lvEff",100)
		end)
		seq:AppendInterval(1)
	end
	seq:Append(tween)
	seq:Join(scaleTween)
	seq:Join(rotateTween)
	seq:OnComplete(function ()
		self._moveTweenSeq = nil
		wnd:TweenTreasureBtn()
		self:WndClose()
	end)
	seq:PlayForward()
end

function UIEdenTsure:RefreshUI()
	local data = self:GetWndArg("data")
	self._data = data
	self._eventType = data.eventType
	self._canSelect = data.canSelect
	self._eventId = data.eventId

	local dataList ={}

	self._eventCfg = gModelWonderland:GetEventConfig(data.eventId)
	local cardStr = nil
	if self._eventType == ModelWonderland.EVENT_TREA_HARD or self._eventType == ModelWonderland.EVENT_TREA_TOUGH then
		cardStr = data.fixedTreasure
	else
		cardStr = data.moreInfo

	end

	local strs = string.split(cardStr,'|')

	for k,v in ipairs(strs) do
		local temp = string.split(v,"=")
		local data =
		{
			id = tonumber(temp[1]),
		}

		table.insert(dataList,data)
	end

	self._select = 0

	self._treasureList = dataList
	self._itemUIList={}
	local list = self:GetUIScroll("uiList")
	list:Create(self.mItemList,dataList,function (...) self:OnDrawItem(...) end)

	self._heroItemList ={}
	local heroList = gModelWonderland:GetHeroListOnTs()
	list = self:GetUIScroll("heroList")
	list:Create(self.mHeroList,heroList,function (...) self:OnDrawHero(...) end,UIItemList.WRAP,false)

	local uiList = list:GetList()

	uiList:EnableLoadAnimation(true, 0, 2)
	uiList:SetFuncOnItemReturn(function (...) self:OnItemReturn(...) end)
	uiList:RefreshList()


end

function UIEdenTsure:InitData()

	self._selectEffKey = "_selectEffKey"
end

function UIEdenTsure:OnDrawHero(list,item,itemdata,itempos)
	local heroTrans = self:FindWndTrans(item,"HeroIcon")
	local frame = self:FindWndTrans(item,"frame")
	local blood = self:FindWndTrans(item,'blood')

	local id,refId,star,level,grade,fightPower = itemdata.id,itemdata.refId,itemdata.star,itemdata.lvl,itemdata.grade,itemdata.power
	local isHire = itemdata.heroType == ModelWonderland.HIRE_HERO
	local heroType = isHire and 2 or 1
	local herodata = {
		id = id,
		refId = refId,
		star = star,
		level = level,
		skin = itemdata.skin,
		isResonance = itemdata.resonance
	}

	self:SetWndClick(heroTrans,function()
		local data = {
			id = id,
			refId = refId,
			level = level,
			star = star,
			grade = grade,
			fightPower = fightPower,
			--isWonderHero = isHire,
			heroType = heroType,
			isResonance = itemdata.resonance,
			skin = itemdata.skin,
		}
		gModelHero:ReqShowHeroTip("",data)
	end)

	local instanceId = item:GetInstanceID()
	local baseClass = self._uiIconClsList[instanceId]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._uiIconClsList[instanceId] = baseClass
		baseClass:Create(heroTrans)
		self:SetIconClickScale(heroTrans, true)
	end
	baseClass:SetHeroDataSet(herodata)
	baseClass:DoApply()


	local showFrame = self:CheckShowFrame(refId)
	CS.ShowObject(frame,showFrame)



	local deadTag = self:FindWndTrans(item,"deadTag")
	local hireTag = self:FindWndTrans(item,"hireTag")
	local isDead = itemdata.curHp<= 0
	CS.ShowObject(deadTag,isDead)

	CS.ShowObject(hireTag,isHire)

	local percent = 0
	if itemdata.maxHp>0 then
		percent = itemdata.curHp/itemdata.maxHp
	end

	LxUiHelper.SetProgress(blood,percent)

	self._heroItemList[id] = {item= item,itemdata = itemdata}

end

function UIEdenTsure:OnItemReturn(list,item,itemdata,itempos)
	if itemdata then
		local id = itemdata.id
		if self._heroItemList then
			self._heroItemList[id] =nil
		end
	end
end


function UIEdenTsure:OnClickConfirm()
	if not self._canSelect then
		local str = ccClientText(16744)
		GF.ShowMessage(str)
		return
	end

	if self._select == 0  then
		local str = ccClientText(16745)--请先选择一件宝物
		GF.ShowMessage(str)
		return
	end

	local state = self._data.state
	local gridIndex = self._data.gridIndex
	if state == StructWonderlandGrid.ALLOW then
		gModelWonderland:WonderlandOpsReq(ModelWonderland.EVENT_SELECT_GRID,tostring(gridIndex))
	end


	local index = self._select-1
	gModelWonderland:WonderlandOpsReq(self._eventType,tostring(index))

	local item = self._itemUIList[self._select]
	local data = self._treasureList[self._select]
	self:TweenTreasure(item,data)
end

function UIEdenTsure:CheckShowPower()
	local newPower = gModelWonderland:GetCurFormationPower()
	if not newPower or not self._oldPower then
		return
	end
	if newPower> self._oldPower then
		GF.CloseWndByName("UIPowps")
		GF.OpenWndDebug("UIPowps",{oldPower = self._oldPower,power = newPower,wndType = 2})
	end

end

function UIEdenTsure:ClearTween()
	if self._moveTweenSeq then
		self._moveTweenSeq:Kill(false)
		self._moveTweenSeq = nil
	end


end

function UIEdenTsure:SetStaticContent()
	local str =ccClientText(16748) --"请选择一个宝物"
	self:SetWndText(self.mUIText,str)
	str =ccClientText(16747)
	self:SetWndText(self.mIntro,str)
	--local text = self:FindWndTrans(self.mConfirmBtn,"text")
	str = ccClientText(16749)
	--self:SetWndText(text,str)

	self:SetWndButtonText(self.mConfirmBtn,str)
end

------------------------------------------------------------------
return UIEdenTsure


