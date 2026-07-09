---
--- Created by Administrator.
--- DateTime: 2023/10/27 22:27:38
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEdenMonster:LWnd
local UIEdenMonster = LxWndClass("UIEdenMonster", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEdenMonster:UIEdenMonster()
	---@type UIIconEasyList
	self._rewardListCls = nil
	---@type table<number,CommonIcon>
	self._commonIconTbl = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEdenMonster:OnWndClose()
	self:ClearCommonIconList(self._commonIconTbl)
	self._commonIconTbl = nil
	if self._rewardListCls then
		self._rewardListCls:Destroy()
		self._rewardListCls = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEdenMonster:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEdenMonster:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	--self:DoWndStartScale(0,self.mRoot)

	self:SetStaticContent()
	self:SetPara()
	self:InitUIEvent()
	self:WndNetMsgRecv(LProtoIds.WonderlandHeroMonsterResp,function(...) self:OnWonderlandHeroMonsterResp(...) end)

    local layerIndex = self._data.layerIndex
    local gridIndex = self._data.gridIndex



	gModelWonderland:WonderlandHeroMonsterReq(1,layerIndex,gridIndex,self._data.eventId)
	self:RefreshUI()

	local pattern = gModelWonderland:GetCurPattern()
	local canGiveUp = self._eventCfg.waive == 1
	local isToughMode = pattern == ModelWonderland.TOUGH
	local isThief = self._eventType == ModelWonderland.EVENT_THIEF
	local showCancel =isThief or ( canGiveUp and isToughMode )
	CS.ShowObject(self.mCancelBtn,showCancel)

	self:ShowRefreshPart()
end

function UIEdenMonster:OnClickCancel()
	if not self._canSelect then
		local str =ccClientText(16779) --"您还没有靠近%s"
		str = string.replace(str,self._name)
		GF.ShowMessage(str)
		return
	end

	local data = self._data
	local layerIndex = data.layerIndex
	local gridIndex = data.gridIndex

	local state = data.state


	local moreInfo = string.format("%s|%s",layerIndex,gridIndex)

	local para =
	{
		refId = 70015,
		func = function()
			if state == StructWonderlandGrid.ALLOW then
				gModelWonderland:WonderlandOpsReq(ModelWonderland.EVENT_SELECT_GRID,tostring(gridIndex))
			end

			gModelWonderland:WonderlandOpsReq(ModelWonderland.EVENT_GIVE_UP,moreInfo)
			GF.CloseWndByName("UIEdenMonster")
		end
	}

	gModelGeneral:OpenUIOrdinTips(para)

	--gModelWonderland:WonderlandOpsReq(ModelWonderland.EVENT_GIVE_UP,moreInfo)
	--self:WndClose()
end

function UIEdenMonster:RefreshUI()
	local data = self._data
	local eventId = data.eventId
	local layerIndex = data.layerIndex

	local eventCfg = self._eventCfg
	local rewardId = gModelWonderland:GetEventRewardId(eventId)

	if rewardId then
		local rewardLocal = gModelWonderland:GetEventReward(rewardId,layerIndex)
		local reward = {}
		for i,v in ipairs(rewardLocal) do
			local rewardData = table.clone(v)
			local refId = rewardData.itemId
			local actRewardData = self._actRewardList[refId]
			if actRewardData then
				rewardData.itemNum = math.ceil(rewardData.itemNum * self._actData)
			end
			table.insert(reward,rewardData)
		end

		local rewardList = self._rewardListCls
		if not rewardList then
			rewardList = UIIconEasyList:New()
			self._rewardListCls = rewardList
			rewardList:Create(self, self.mItemList)
		end
		rewardList:RefreshList(reward)
	end



	self._canSelect = data.canSelect

	--local btnType = "blue_1"
	--if self._canSelect then
	--	btnType = "yellow_1"
	--end

	--self:SetColorBtnImg(self.mGotoBtn,btnType)

	self:SetWndButtonGray(self.mGotoBtn,not self._canSelect)
	self:SetWndButtonGray(self.mCancelBtn,not self._canSelect)


	local post = self:GetDesc()
	self:SetWndText(self.mPost,post)

	local spineKey = eventCfg.prefab
	if string.isempty(spineKey) then
		return
	end
	local scale = eventCfg.prefabSize or 1
	if self._eventType == ModelWonderland.EVENT_TIME_LORD then
		local index = self._data.index or 1
		local key = "bossResSize"..index
		scale = gModelWonderland:GetWonderlandPara(key)
	end

	scale = scale or 1

	self:CreateWndSpine(self.mRole,spineKey,spineKey,false,function (spine)
		spine:SetScale(scale)
		spine:PlayAnimation(0,"idle",true)
	end)

	self:SetEventTitle(eventId)

end
function UIEdenMonster:ShowMonsterList()
	local monsterList = self:GetUIScroll("uiList")
	local bossList = self._battleData.bossList
	monsterList:Create(self.mHeroList,bossList,function (...) self:OnDrawHero(...) end)
	self:SetWndClick(self.mGotoBtn,function () self:OnClickGoto() end,LSoundConst.CLICK_BUTTON_COMMON)
end

function UIEdenMonster:OnClickRefresh()
	if not self._canSelect then
		local str =ccClientText(16779) --"您还没有靠近%s"
		str = string.replace(str,self._name)
		GF.ShowMessage(str)
		return
	end

	gModelWonderland:RefreshFormation(self._data)
end


function UIEdenMonster:OnDrawHero(list, item,itemdata,itempos)
	local blood = self:FindWndTrans(item,"blood")

	local value =0
	if itemdata.maxHp>0 then
		value =itemdata.curHp/itemdata.maxHp
	end
	LxUiHelper.SetProgress(blood,value)

	local id,refId,star,level,grade,fightPower = itemdata.id,itemdata.refId,itemdata.star,itemdata.lvl,itemdata.grade,itemdata.power
	local herodata = {}
	herodata.id = id
	herodata.refId = refId
	herodata.star = star
	herodata.level = level
	herodata.isMon = itemdata.heroType == ModelWonderland.ENEMY_MONSTER
	herodata.monsterAddCost = itemdata.monsterAddCost --怪物加成信息
	herodata.skin = itemdata.skin
	local heroTrans = self:FindWndTrans(item,"HeroIcon")

	local instanceId = item:GetInstanceID()
	local heroIconCls = self._commonIconTbl[instanceId]
	if not heroIconCls then
		heroIconCls = CommonIcon:New()
		self._commonIconTbl[instanceId] = heroIconCls
		heroIconCls:Create(heroTrans)
	end
	heroIconCls:SetHeroDataSet(herodata)
	heroIconCls:DoApply()


	local deadTag = self:FindWndTrans(item,"deadTag")
	local hireTag = self:FindWndTrans(item,"hireTag")
	local isDead = itemdata.curHp<= 0
	CS.ShowObject(deadTag,isDead)
	local isHire = itemdata.heroType ==ModelWonderland.HIRE_HERO
	CS.ShowObject(hireTag,isHire)

	self:SetWndClick(heroTrans,function ()
		local str = ccClientText(16905)
		GF.ShowMessage(str)
	end)
end

function UIEdenMonster:OnClickGoto()

	if self:IsWndClosed() then
		return
	end

	if not  self._canSelect then
		local str = ccClientText(16717)
		GF.ShowMessage(str)--"不可前往")
		return
	end

	local data = self._data
	local battleData = self._battleData
	local gridIndex = data.gridIndex
	local layerIndex = data.layerIndex
	local gridData = gModelWonderland:GetGridData(layerIndex,gridIndex)

	local state = gridData:GetStatus()

	local eventType = self._eventType
	local eventId = data.eventId
	local wndName = self:GetWndName()
	local callBack = function()
		if eventType == ModelWonderland.EVENT_TIME_LORD then
			gModelWonderland:EnterBattle(battleData,wndName)
		else
			local event = gModelWonderland:GetEventData(layerIndex,gridIndex,eventId)
			if not event then
				return
			end
			local type = event.type

			if type == 1 then
				local func = function(choose)
					if choose == 1 then
						gModelWonderland:EnterBattle(battleData,wndName)
					elseif choose == 2 then
						gModelWonderland:WonderlandHeroMonsterReq(0,layerIndex,gridIndex)
					end

				end
				GF.OpenWnd("UIEdenSelectPop",{type= 1,func = func,data = data})
				GF.CloseWndByName("UIEdenMonster")
			elseif type == 2 or type == 0 then
				---布阵
				gModelWonderland:EnterBattle(battleData,wndName)
			end
		end

	end


	if state == StructWonderlandGrid.ALLOW then
		gModelWonderland:WonderlandOpsReq(ModelWonderland.EVENT_SELECT_GRID,tostring(gridIndex),callBack)
	else
		callBack()
	end





end

function UIEdenMonster:SetStaticContent()
	local str = ccClientText(10361)
	self:SetWndText(self.mTitle,str)
	local text = self:FindWndTrans(self.mSkipPrepare,"Label")
	local str=ccClientText( 10341)--"跳过战前布阵"
	self:SetWndText(text,str)

	str = ccClientText(10367)
	--text = self:FindWndTrans(self.mGotoBtn,"Text")
	--self:SetWndText(text,str)
	self:SetWndButtonText(self.mGotoBtn,str)

	self:SetWndText(self.mCloseTip,ccClientText(10103))

	str = ccClientText(16782)-- "放弃")
	self:SetWndButtonText(self.mCancelBtn,str)
end

function UIEdenMonster:ShowRefreshPart()
	local pattern = gModelWonderland:GetCurPattern()
	local isToughMode = pattern == ModelWonderland.TOUGH
	local canRefresh = isToughMode and not gModelWonderland:NotAllowRefreshType(self._data.eventType)
	CS.ShowObject(self.mRefreshPart,canRefresh)



	local str = ""
	if canRefresh then
		local layerIndex = self._data.layerIndex
		local gridIndex = self._data.gridIndex
		local eventId = self._data.eventId
		local eventData = gModelWonderland:GetEventData(layerIndex,gridIndex,eventId)

		if eventData then
			local refreshCnt = eventData.refreshCount

			local refreshMax = gModelWonderland:GetWonderlandPara("refreshNum")
			str = ccClientText(16783)
			str = string.replace(str,refreshCnt,refreshMax)
		end

	end



	self:SetWndText(self.mRefreshTxt,str)
	self:InitTextLineWithLanguage(self.mRefreshTxt, -30)
end
function UIEdenMonster:SetPara()
    local data = self:GetWndArg("data")
	local wndType = self:GetWndArg("wndType") or 1
	self._eventType = data.eventType
	self._actData = 1
	local actData = gModelActivity:GetActivityListByModelId(ModelActivity.COMMONRANK,"wonderLand")
	if actData then
		self._actData = actData
	end
	self._actRewardList = {}
	local actReward = gModelActivity:GetActivityListByModelId(ModelActivity.COMMONRANK,"wonderLandReward")
	if actReward then
		actReward = string.split(actReward,",")
		for i,v in ipairs(actReward) do
			local refId = tonumber(v)
			self._actRewardList[refId] = refId
		end
	end
    self._data = data
	self._eventCfg = gModelWonderland:GetEventConfig(self._data.eventId)

	local height = 505
	local intro = ""
	if wndType == 2 then
		height = 537
		local textId = gModelWonderland:GetEventTextId(data.eventId,2)
		local textCfg = gModelWonderland:GetEventTextConfig(textId)
		intro = ccLngText(textCfg.dec)
	end

	LxUiHelper.SetSizeWithCurAnchor(self.mCommonBg_7,1,height)
	LxUiHelper.SetSizeWithCurAnchor(self.mPopup,1,height)

	self:SetWndText(self.mIntro,intro)
	self:InitTextSizeWithLanguage(self.mIntro, -2)
	self:InitTextLineWithLanguage(self.mIntro, -30)
end

function UIEdenMonster:InitUIEvent()
	self:SetWndClick(self.mMask,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseTip,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)

	local isSkip = gModelWonderland:GetSkipPrepare()
	self:SetWndToggleValue(self.mSkipPrepare,isSkip)
	self:SetWndToggleDelegate(self.mSkipPrepare,function (value)
		local isSuc = gModelWonderland:SetSkipPrepare(value)
		if not isSuc then
			self:SetWndToggleValue(self.mSkipPrepare,not value)
		end
	end)

	self:SetWndClick(self.mCancelBtn,function ()
		self:OnClickCancel()
	end)

	self:SetWndClick(self.mRefreshBtn,function ()
		self:OnClickRefresh()
	end)
end

function UIEdenMonster:OnWonderlandHeroMonsterResp(pb)

	local eventId = self._data.eventId
	local eventCfg = gModelWonderland:GetEventConfig(eventId)
	local eventName =ccLngText(eventCfg.name)

	local bossType = self._eventType == ModelWonderland.EVENT_TIME_LORD and 2 or 1

	self._battleData = gModelWonderland:FormatBattleData(pb,eventName,eventId,bossType)

	self:ShowMonsterList()

	self:ShowRefreshPart()
end
function UIEdenMonster:SetEventTitle(eventId)
	local eventCfg = gModelWonderland:GetEventConfig(eventId)
	local name = ccLngText(eventCfg.name)
	self._name = name
	self:SetWndText(self.mMainTitle,name)
end

function UIEdenMonster:GetDesc()
	local post = nil
	local data = self._data
	local eventId = data.eventId
	local textId = nil
	if self._eventType == ModelWonderland.EVENT_DEVIL then
		local themeId = gModelWonderland:GetThemeId()
		local isAwake = gModelWonderland:IsBossTrigger(themeId)
		textId = gModelWonderland:GetEventTextId(eventId,isAwake and 3 or 2)
	elseif self._eventType == ModelWonderland.EVENT_BOX_BOSS then
		textId = gModelWonderland:GetEventTextId(eventId,1)
	elseif self._eventType == ModelWonderland.EVENT_TIME_LORD then
		textId = gModelWonderland:GetEventTextId(eventId,1)
	elseif self._eventType == ModelWonderland.EVENT_THIEF then
		textId = gModelWonderland:GetEventTextId(eventId,1)
	else
		local isTriggered = data.type == 1
		textId = gModelWonderland:GetEventTextId(eventId,isTriggered and 1 or 2)
	end

	if textId then
		local textCfg = gModelWonderland:GetEventTextConfig(textId)
		post = ccLngText(textCfg.dec)

	end

	return post

end


------------------------------------------------------------------
return UIEdenMonster


