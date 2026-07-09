---
--- Created by Administrator.
--- DateTime: 2023/10/28 15:40:20
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEdenSpring:LWnd
local UIEdenSpring = LxWndClass("UIEdenSpring", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEdenSpring:UIEdenSpring()
	---@type table<number, CommonIcon>
	self._uiIconClsList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEdenSpring:OnWndClose()
	self:ClearCommonIconList(self._uiIconClsList)

	if self._seqCom then
		self._seqCom:Destroy()
		self._seqCom = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEdenSpring:OnCreate()
	LWnd.OnCreate(self)

	self._seqCom = SequenceCom:New()
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEdenSpring:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	--self:DoWndStartScale(0,self.mRoot)

	self:SetStaticContent()

	self:InitData()
	self:InitUIEvent()

	gModelWonderland:ClearHpChange()
	self:WndNetMsgRecv(LProtoIds.WonderlandOpsResp,function (...) self:DelayClose(...)  end)
	--self:WndNetMsgRecv(LProtoIds.WonderlandHeroOpsResp,function () self:DelayClose()  end)
	self:RefreshUI()
end

function UIEdenSpring:OnSelectHero(id)

	if self._wndType == 2 then
		return
	end

	if self._select == id then
		return
	end
	local old =self._heroItemList[self._select]
	if old then
		local item,itemdata = old[1],old[2]
		local mask = self:FindWndTrans(item,"mask")
		local check = self:FindWndTrans(item,"check")

		local isDead = itemdata.curHp<= 0
		CS.ShowObject(check,false)
		CS.ShowObject(mask,isDead or false)

	end

	self._select = id
	local item,itemdata = self._heroItemList[id][1],self._heroItemList[id][2]
	local mask = self:FindWndTrans(item,"mask")
	local check = self:FindWndTrans(item,"check")

	CS.ShowObject(check,true)
	CS.ShowObject(mask,true)
end

function UIEdenSpring:ShowHeroList()
	local heroList,select = gModelWonderland:GetHeroListInReborn()
	self._heroList = heroList

	self._select = nil
	if self._wndType == 1 then
		self._select = select.id
	end

	local uilist = self._heroUiList
	if not uilist then
		uilist = self:GetUIScroll("heroList")
		self._heroUiList = uilist
		uilist:Create(self.mHeroList,heroList,function (...) self:OnDrawHero(...)  end,UIItemList.SUPER_GRID)
	else
		uilist:RefreshData(heroList)
	end

	--local uilist = self:GetUIScroll("heroList")
	--uilist:Create(self.mHeroList,heroList,function (...) self:OnDrawHero(...)  end,UIItemList.WRAP,false)

	--local list = uilist:GetList()
	--list:EnableLoadAnimation(true, 0, 2)
	--list:RefreshList()
end


function UIEdenSpring:SendNetMsg()
	if self:IsWndClosed() then
		return
	end
	local state = self._data.state
	local gridIndex = self._data.gridIndex
	if state == StructWonderlandGrid.ALLOW then
		gModelWonderland:WonderlandOpsReq(ModelWonderland.EVENT_SELECT_GRID,tostring(gridIndex))
	end

	local moreInfo = nil
	if self._wndType == 1 then
		moreInfo = tostring(self._select)
	end
	gModelWonderland:WonderlandOpsReq(self._eventType,moreInfo)

	--self:WndClose()
end

function UIEdenSpring:SpringConfirm()
	if not self._canSelect then
		local str =ccClientText(16740)-- "还没有到达泉水位置!"
		GF.ShowMessage(str)
		return
	end

	local hasHurt = gModelWonderland:CheckHasHeroHurt()

	if not hasHurt then
		local wndId = 70005
		local func = function()
			self:SendNetMsg()
		end
		gModelGeneral:OpenUIOrdinTips({refId = wndId,func = func})

		return
	end

	self:SendNetMsg()
end

function UIEdenSpring:OnClickConfirm()
	local type = self._wndType
	if type == 1 then
		self:RevivalConfirm()
	else
		self:SpringConfirm()
	end
end

function UIEdenSpring:DelayClose(pb)


	if pb.type == ModelWonderland.EVENT_SPRING or pb.type == ModelWonderland.EVENT_REVIVAL then
		self._isClosing = true
		local heros = gModelWonderland:GetHpChangeHeros()
		if table.isempty(heros) then
			self:WndClose()
			return
		end
		self:ShowHeroList()
		local seq = self._seqCom:CreateSeq("delayClose")
		seq:AppendInterval(0.8)
		seq:OnComplete(function()
			self:WndClose()
		end	)
		seq:PlayForward()
	end

end

function UIEdenSpring:OnDrawHero(list,item,itemdata,itempos)
	if not itemdata then
		return
	end


	local blood = self:FindWndTrans(item,"blood")
	--local bloodBackground = self:FindWndTrans(blood,"Background")
	local mask = self:FindWndTrans(item,"mask")
	local death = self:FindWndTrans(item,"death")
	local check = self:FindWndTrans(item,"check")

	local hireTag = self:FindWndTrans(item,"hireTag")

	local heroTrans = self:FindWndTrans(item,"HeroIcon")

	local id,refId,star,level,grade,fightPower = itemdata.id,itemdata.refId,itemdata.star,itemdata.lvl,itemdata.grade,itemdata.power
	local herodata = {
		id = id,
		refId = refId,
		star = star,
		level = level,
		skin = itemdata.skin,
		isResonance = itemdata.resonance
	}

	local instanceId = item:GetInstanceID()
	local baseClass = self._uiIconClsList[instanceId]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._uiIconClsList[instanceId] = baseClass
		baseClass:Create(heroTrans)
		--self:SetIconClickScale(heroTrans, true)
	end
	baseClass:SetHeroDataSet(herodata)
	baseClass:DoApply()

	self:SetWndClick(heroTrans, function()
		self:OnSelectHero(id)
	end)

	local showCheck = self._select == id
	CS.ShowObject(check,showCheck)

	local value =0
	if itemdata.maxHp>0 then
		value =itemdata.curHp/itemdata.maxHp
	end
	LxUiHelper.SetProgress(blood,value)

	local isDead = itemdata.curHp<= 0
	CS.ShowObject(death,isDead)

	CS.ShowObject(mask,isDead or showCheck)


	local isHire = itemdata.heroType == ModelWonderland.HIRE_HERO
	CS.ShowObject(hireTag,isHire)


	local instanceid = item:GetInstanceID()
	local key = tostring(instanceid)
	local isChange =  gModelWonderland:IsHpChangeHero(id)
	if isChange then
		if not self._effRecord then
			self._effRecord = {}
		end
		self._effRecord[key] = true
		self:CreateWndEffect(heroTrans,"fx_qjtx_wupinshuaxin",key,100)
	else
		if self._effRecord then
			self._effRecord[key] = nil
		end
		self:DestroyWndEffectByKey(key)
	end

	self._heroItemList[id] = {item,itemdata}

end

function UIEdenSpring:SetStaticContent()
	local str =ccClientText(16776) --"伙伴情况"
	self:SetWndText(self.mTitle,str)

	self:SetWndText(self.mCloseTip,ccClientText(10103))
end

function UIEdenSpring:InitData()
	self._heroItemList={}
end

function UIEdenSpring:DoWndDestroy()
	gModelWonderland:CheckShowHud(ModelWonderland.EVENT_REVIVAL)
	gModelWonderland:CheckShowHud(ModelWonderland.EVENT_SPRING)

	--if self._wndType == 1 then
    --
	--elseif self._wndType == 2 then
	--end

	LWnd.DoWndDestroy(self)
end

function UIEdenSpring:RevivalConfirm()
	if not self._canSelect then
		local str =ccClientText(16741)-- "请先抵达复活十字架"
		GF.ShowMessage(str)
		return
	end

	--local hasHeadHero = gModelWonderland:CheckHasHeroDead()

	--if not hasHeadHero then
	--	local wndId = 70006
	--	local func = function()
	--		self:SendNetMsg()
	--	end
	--	gModelGeneral:OpenUIOrdinTips({refId = wndId,func = func})
    --
	--	return
	--end
	self:SendNetMsg()
end

function UIEdenSpring:SetEventTitle(eventId)
	local eventCfg = gModelWonderland:GetEventConfig(eventId)
	local name = ccLngText(eventCfg.name)
	self:SetWndText(self.mMainTitle,name)
end

function UIEdenSpring:RefreshUI()
	local wndType = self:GetWndArg("wndType") --1,复活 2,泉水
	local data = self:GetWndArg("data")
	self._eventType = self:GetWndArg("eventType")
	self._eventId = data.eventId
	self._wndType = wndType
	self._data = data


	if self._effRecord then
		for k,v in ipairs(self._effRecord) do
			self:DestroyWndEffectByKey(k)
		end
		self._effRecord = {}
	end


	local canSelect = data.canSelect
	self._canSelect = canSelect

	local btnType = "blue_1"
	if self._canSelect then
		btnType = "yellow_1"
	end

	self:SetColorBtnImg(self.mConfirm,btnType)
	--self:SetWndImageGray(self.mConfirm,not canSelect)
	local text = self:FindWndTrans(self.mConfirm,"Text")
	local str =ccClientText(16737)-- "复苏吧"
	if wndType == 2 then
		str =ccClientText(16738)-- "喝一口"
	end
	self:SetWndText(text,str)
	self:InitTextLineWithLanguage(text,-40)
	--text = self:FindWndTrans(self.mCancel,"text")
	--str =ccClientText(16739)-- "取消"
	--self:SetWndText(text,str)

	self:ShowHeroList()

	local eventId = data.eventId
	local textId = gModelWonderland:GetEventTextId(eventId)
	if textId then
		local textCfg = gModelWonderland:GetEventTextConfig(textId)
		local post = ccLngText(textCfg.dec)
		self:SetWndText(self.mPost,post)
	end
	local eventCfg = gModelWonderland:GetEventConfig(eventId)
	local spineKey = eventCfg.prefab
	local prefabSize = eventCfg.prefabSize or 1
	if string.isempty(spineKey) then
		return
	end
	self:CreateWndSpine(self.mRole,spineKey,spineKey,false,function (spine)
		spine:SetScale(prefabSize)
		spine:PlayAnimation(0,"idle",true)
	end)

	self:SetEventTitle(eventId)
end

function UIEdenSpring:InitUIEvent()
	--self:SetWndClick(self.mCancel,function ()
	--	if self._isClosing then
	--		return
	--	end
	--	self:WndClose()
	--end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mConfirm,function ()
		if self._isClosing then
			return
		end
		self:OnClickConfirm() end,LSoundConst.CLICK_BUTTON_COMMON)
	self:SetWndClick(self.mMask,function ()
		if self._isClosing then
			return
		end
		self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseTip,function ()
		if self._isClosing then
			return
		end
		self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)

end

------------------------------------------------------------------
return UIEdenSpring


