---
--- Created by Administrator.
--- DateTime: 2023/10/1 14:26:59
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEdenMonsterPop:LWnd
local UIEdenMonsterPop = LxWndClass("UIEdenMonsterPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEdenMonsterPop:UIEdenMonsterPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEdenMonsterPop:OnWndClose()



	if self._data and self._data.beastState == 2 then
		FireEvent(EventNames.ON_FOLLOW_KELAKEN)
	end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEdenMonsterPop:OnCreate()
	LWnd.OnCreate(self)
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEdenMonsterPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	--self:DoWndStartScale(0,self.mPopup)

	self:SetStaticContent()
	self:InitData()
	self:SetPara()

	self:SetWndClick(self.mMask,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)


	if self._wndType == 1 then --遭遇怪，
		self:WndNetMsgRecv(LProtoIds.WonderlandHeroMonsterResp,function(...) self:ShowMonsterPop(...) end)
		self:WndNetMsgRecv(LProtoIds.WonderlandScenePageResp,function(...) self:RefreshEventShow(...) end)
		local layerIndex = self._layerIndex
		local gridIndex = self._gridIndex
		gModelWonderland:WonderlandHeroMonsterReq(1,layerIndex,gridIndex)

	elseif self._wndType == 2 then --魔王惊醒
		self:ShowDevilAwake()
	elseif self._wndType == 3 then --关底boss 未触发情况
		self:ShowDevilContent()
	elseif self._wndType == 4 then
		local isTrigger = self:IsEndBossTrigger()
		local canSelect = self._data.canSelect
		self._isTrigger = isTrigger
		if not isTrigger and canSelect then
			self:WndNetMsgRecv(LProtoIds.WonderlandHeroMonsterResp,function(...) self:SetQueenBattleData(...) end)
			local layerIndex = self._layerIndex
			local gridIndex = self._gridIndex
			gModelWonderland:WonderlandHeroMonsterReq(1,layerIndex,gridIndex)
		end

		self:ShowQueenContent()
	elseif self._wndType == 5 then
		local canSelect = self._data.canSelect
		if canSelect then
			self:WndNetMsgRecv(LProtoIds.WonderlandHeroMonsterResp,function(...) self:SetSpriteBattleData(...) end)
			local layerIndex = self._layerIndex
			local gridIndex = self._gridIndex
			gModelWonderland:WonderlandHeroMonsterReq(1,layerIndex,gridIndex)
		end

		self:ShowSpriteContent()
	elseif self._wndType == 6 then
		local canSelect = self._data.canSelect
		if canSelect then
			self:WndNetMsgRecv(LProtoIds.WonderlandHeroMonsterResp,function(...) self:SetSpriteBattleData(...) end)
			local layerIndex = self._layerIndex
			local gridIndex = self._gridIndex
			gModelWonderland:WonderlandHeroMonsterReq(1,layerIndex,gridIndex)
		end
		self:ShowWitchContent()
	elseif self._wndType == 7 then
		self:WndNetMsgRecv(LProtoIds.WonderlandHeroMonsterResp,function(...) self:SetSpriteBattleData(...) end)
		local beastState = self._data.beastState
        if beastState == 1 then ---被追上触发战斗
            local layerIndex = self._layerIndex
            local gridIndex = self._gridIndex
			self._data.canSelect = true
            gModelWonderland:WonderlandHeroMonsterReq(1,layerIndex,gridIndex)
        elseif beastState == 2 then  ---刚出现
            self:SetWndClick(self.mMask,function () self:WndClose() end)
        elseif beastState == 3 then   ---已沉睡
			self:SetWndClick(self.mMask,function () self:WndClose() end)
        end

		self:ShowBeastContent()
	end


end

function UIEdenMonsterPop:RefreshEventShow()
	local gridIndex = self._gridIndex
	local layerIndex = self._layerIndex

	local data = gModelWonderland:FormatEventData(layerIndex,gridIndex)
	self._data = data
	local eventId = data.eventId

	local choose =gModelWonderland:GetEventTextId(eventId,2)
	local textRef= gModelWonderland:GetEventTextConfig(choose)
	if textRef then
		local str = ccLngText(textRef.dec)
		self:SetWndText(self.mIntro,str)
	end

	self:CreateRoleSpine(eventId)

end

function UIEdenMonsterPop:SetCloseCountDown()
	local timeLeft = self._endTime- GetTimestamp()
	timeLeft = math.ceil(timeLeft)
	if timeLeft<=0 then
		self:WndClose()
		return
	end
	local str = ccClientText(16719)--"%s 秒后自动关闭"
	str = string.replace(str,timeLeft)
	self:SetWndText(self.mCountDown,str)
end

function UIEdenMonsterPop:DoWndDestroy()
	if self._wndType == 2 then
		FireEvent(EventNames.ON_DEVIL_AWAKE)
		gModelWonderland:CheckShowHud(ModelWonderland.EVENT_DEVIL)
	end

	LWnd.DoWndDestroy(self)
end

function UIEdenMonsterPop:StartQueenCountdown()
	CS.ShowObject(self.mCountDown,true)
	local timespan = gModelWonderland:GetWonderlandPara("meetMonster")
	self._endTime = GetTimestamp()+ timespan
	self:SetQueenCountdown()
	self:TimerStart(self._delayQueenBattle,1,false,-1)

	self:SetWndClick(self.mMask,function ()
		self:EnterQueenBattle()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIEdenMonsterPop:ShowDevilAwake()
	local timespan = gModelWonderland:GetWonderlandPara("meetMonster")
	self._endTime = timespan+ GetTimestamp()
	self:SetCloseCountDown()
	self:TimerStart(self._delayClose,1,false,-1)

	CS.ShowObject(self.mButton,false)

	local eventId = 10099
	local textId = gModelWonderland:GetEventTextId(eventId,4)
	local textRef= gModelWonderland:GetEventTextConfig(textId)
	local str = ccLngText(textRef.dec)

	self:SetWndText(self.mIntro,str)



	self:CreateRoleSpine(eventId)
end

function UIEdenMonsterPop:SetSpriteBattleData(pb)
	local eventId = self._data.eventId
	local eventCfg = gModelWonderland:GetEventConfig(eventId)
	local eventName =ccLngText(eventCfg.name)
	self._battleData = gModelWonderland:FormatBattleData(pb,eventName)

	local eventType = eventCfg.type
	if eventType == ModelWonderland.EVENT_BEAST then
		self:StartBeastCountdown()
	else
		self:StartSpriteCountdown()
	end

end

function UIEdenMonsterPop:StartBeastCountdown()
	local isFirst = self:GetWndArg("isFirst")
	CS.ShowObject(self.mCountDown,isFirst)
	CS.ShowObject(self.mButton,not isFirst)
	if isFirst then
		local timespan = gModelWonderland:GetWonderlandPara("meetMonster")
		self._endTime = GetTimestamp()+ timespan
		self:SetBattleCountDown()
		self:TimerStart(self._delayBattle,1,false,-1)

		self:SetWndClick(self.mMask,function ()
			self:EnterBattle()
		end,LSoundConst.CLICK_CLOSE_COMMON)
	else
		self:SetWndClick(self.mButton,function ()
			self:EnterBattle()
		end,LSoundConst.CLICK_CLOSE_COMMON)
	end

end

function UIEdenMonsterPop:InitData()
	self._delayBattle = "_delayBattle"
	self._delayClose = "_delayClose"

	self._roleSpineKey = "_roleSpineKey"
	self._delayQueenBattle = "_delayQueenBattle"
end

function UIEdenMonsterPop:SetQueenCountdown()
	local timeLeft = self._endTime- GetTimestamp()
	timeLeft = math.ceil(timeLeft)
	if timeLeft<=0 then
		self:EnterQueenBattle()
		self:WndClose()
		return
	end
	local str = nil
	if self._isTrigger then
		str = ccClientText(16752) --"%s 秒后自动关闭"
	else
		str = ccClientText(16718) --"%s 秒后自动进入战斗"
	end
	str = string.replace(str,timeLeft)
	self:SetWndText(self.mCountDown,str)
end

function UIEdenMonsterPop:StartSpriteCountdown()
	CS.ShowObject(self.mCountDown,true)
	local timespan = gModelWonderland:GetWonderlandPara("meetMonster")
	self._endTime = GetTimestamp()+ timespan
	self:SetBattleCountDown()
	self:TimerStart(self._delayBattle,1,false,-1)

	self:SetWndClick(self.mMask,function ()
		self:EnterBattle()
	end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIEdenMonsterPop:SetBattleCountDown()
	local timeLeft = self._endTime- GetTimestamp()
	timeLeft = math.ceil(timeLeft)
	if timeLeft<=0 then
		self:TimerStop(self._delayBattle)
		self:EnterBattle()
		return
	end
	local str = ccClientText(16718) --"%s 秒后自动进入战斗"
	str = string.replace(str,timeLeft)
	self:SetWndText(self.mCountDown,str)
end

function UIEdenMonsterPop:IsEndBossTrigger()
	local themeId = gModelWonderland:GetThemeId()
	local isTrigger = gModelWonderland:IsBossTrigger(themeId)
	return isTrigger
end

function UIEdenMonsterPop:ShowSpriteContent()
	local data = self._data
	local eventId = data.eventId
	self:CreateRoleSpine(eventId)
	local eventCfg = gModelWonderland:GetEventConfig(data.eventId)
	local textId = gModelWonderland:GetEventTextId(data.eventId)
	local textData = gModelWonderland:GetDefaultEventText(textId)
	self._eventCfg = eventCfg
	self._textData = textData

	CS.ShowObject(self.mButton,false)
	local post = textData.desc
	self:SetWndText(self.mIntro,post)
end

function UIEdenMonsterPop:CreateRoleSpine(eventId,scale)
	self:DestroyWndSpineByKey(self._roleSpineKey)
	local cfg = gModelWonderland:GetEventConfig(eventId)
	if not cfg then
		return
	end
	local prefab = cfg.prefab
	local scale = scale or 2
	self:CreateWndSpine(self.mRole,prefab,self._roleSpineKey,false,function (spine)
		spine:SetScale(scale)
		spine:PlayAnimation(0,"idle",true)
	end)
end


function UIEdenMonsterPop:InitUIEvent()
	self:SetWndClick(self.mButton,function () self:EnterBattle() end,LSoundConst.CLICK_BUTTON_COMMON)

end


function UIEdenMonsterPop:ShowMonsterPop(pb)
	self:RefreshEventShow()

	local eventCfg = gModelWonderland:GetEventConfig(self._data.eventId)
	local eventName = ccLngText(eventCfg.name)


	self._battleData = gModelWonderland:FormatBattleData(pb,eventName)

	CS.ShowObject(self.mCountDown,true)
	local timespan = gModelWonderland:GetWonderlandPara("meetMonster")
	self._endTime = GetTimestamp()+ timespan
	self:SetBattleCountDown()
	self:TimerStart(self._delayBattle,1,false,-1)

	self:InitUIEvent()
end

function UIEdenMonsterPop:EnterQueenBattle()

	local canSelect = self._data.canSelect
	if not canSelect then
		return
	end

	local state = self._data.state
	local gridIndex = self._data.gridIndex
	if state == StructWonderlandGrid.ALLOW then
		gModelWonderland:WonderlandOpsReq(ModelWonderland.EVENT_SELECT_GRID,tostring(gridIndex))
	end

	if self._isTrigger then
		gModelWonderland:WonderlandOpsReq(ModelWonderland.EVENT_QUEEN,tostring(self._data.moreInfo))
	else
		gModelWonderland:EnterBattle(self._battleData,self:GetWndName())

	end

end

function UIEdenMonsterPop:ShowBeastContent()
	local data = self._data
	local eventId = data.eventId
	self:CreateRoleSpine(eventId,1.5)
	local eventCfg = gModelWonderland:GetEventConfig(data.eventId)
	local index = self._data.beastState
	local textId = gModelWonderland:GetEventTextId(data.eventId,index)
	local textData = gModelWonderland:GetDefaultEventText(textId)
	self._eventCfg = eventCfg
	self._textData = textData

	CS.ShowObject(self.mButton,false)
	local post = textData.desc
	self:SetWndText(self.mIntro,post)

    if self._data.beastState == 1 then
        return
    end
    local timespan = gModelWonderland:GetWonderlandPara("meetMonster")
    self._endTime = timespan+ GetTimestamp()
    self:SetCloseCountDown()
    self:TimerStart(self._delayClose,1,false,-1)
end

function UIEdenMonsterPop:ShowDevilContent()
	local data = self._data

	--self:SetWndImageGray(self.mButton,true)
	self:SetWndButtonGray(self.mButton,true)
	local eventId = data.eventId
	local textId = gModelWonderland:GetEventTextId(eventId,1)

	local textRef= gModelWonderland:GetEventTextConfig(textId)
	if  textRef then
		local str = ccLngText(textRef.dec)
		self:SetWndText(self.mIntro,str)
	end

	CS.ShowObject(self.mCountDown,false)

	self:CreateRoleSpine(eventId)
end

function UIEdenMonsterPop:SetQueenBattleData(pb)
	local eventId = self._data.eventId
	local eventCfg = gModelWonderland:GetEventConfig(eventId)
	local eventName =ccLngText(eventCfg.name)

	self._battleData = gModelWonderland:FormatBattleData(pb,eventName)
	self:StartQueenCountdown()
end

function UIEdenMonsterPop:SetPara()

	local gridIndex = self:GetWndArg("gridIndex")
	local layerIndex = self:GetWndArg("layerIndex")
	local wndType = self:GetWndArg("wndType")
	self._data = self:GetWndArg("data")
	self._eventType = self:GetWndArg("eventType")

	self._wndType = wndType

	self._gridIndex =  gridIndex
	self._layerIndex = layerIndex

	if self._data then
		self._gridIndex =  self._data.gridIndex
		self._layerIndex = self._data.layerIndex
	end
end

function UIEdenMonsterPop:OnTimer(key)
	if key == self._delayBattle then
		self:SetBattleCountDown()
	elseif key == self._delayClose then
		self:SetCloseCountDown()
	elseif key == self._delayQueenBattle then
		self:SetQueenCountdown()

	end
end

function UIEdenMonsterPop:ShowQueenContent()
	local data = self._data
	local eventId = data.eventId
	self:CreateRoleSpine(eventId)
	local canSelect = data.canSelect
	local textId =gModelWonderland:GetEventTextId(eventId,1)
	local isTrigger = self._isTrigger
	if canSelect then
		textId = gModelWonderland:GetEventTextId(eventId,isTrigger and 3 or 2)
	end

	CS.ShowObject(self.mButton,false)
	local textCfg = gModelWonderland:GetEventTextConfig(textId)
	local post = ccLngText(textCfg.dec)
	self:SetWndText(self.mIntro,post)

	if isTrigger and canSelect then
		self:StartQueenCountdown()
	else
		CS.ShowObject(self.mCountDown,false)
		self:SetWndClick(self.mMask,function ()
			self:WndClose()
		end,LSoundConst.CLICK_CLOSE_COMMON)
	end

end

function UIEdenMonsterPop:SetStaticContent()
	local str =ccClientText(16778) --"马上战斗"
	self:SetWndButtonText(self.mButton,str)
	--local text = self:FindWndTrans(self.mButton,"text")
	--self:SetWndText(text,str)
end

function UIEdenMonsterPop:EnterBattle()
	local canSelect = self._data.canSelect
	if not canSelect then
		local str =ccClientText(16720) --"你还没有抵达魔王跟前,不能挑战"
		GF.ShowMessage(str)
	else
		local state = self._data.state
		local gridIndex = self._data.gridIndex
		if state == StructWonderlandGrid.ALLOW  then
			gModelWonderland:WonderlandOpsReq(ModelWonderland.EVENT_SELECT_GRID,tostring(gridIndex))
		end


		gModelWonderland:EnterBattle(self._battleData,self:GetWndName())
	end

	self:WndClose()

end

function UIEdenMonsterPop:ShowWitchContent()
    local data = self._data
    local eventId = data.eventId
    self:CreateRoleSpine(eventId)
    local eventCfg = gModelWonderland:GetEventConfig(data.eventId)

	local isTrigger = self:IsEndBossTrigger()
	local index = 1
	if self._eventType == ModelWonderland.EVENT_WITCH then
		if self._data.canSelect then
			if isTrigger then
				index = 3
			else
				index = 2
			end
		end
	end

    local textId = gModelWonderland:GetEventTextId(data.eventId,index)
    local textData = gModelWonderland:GetDefaultEventText(textId)
    self._eventCfg = eventCfg
    self._textData = textData


    CS.ShowObject(self.mButton,false)
	CS.ShowObject(self.mCountDown,false)
    local post = textData.desc
    self:SetWndText(self.mIntro,post)
end

------------------------------------------------------------------
return UIEdenMonsterPop


