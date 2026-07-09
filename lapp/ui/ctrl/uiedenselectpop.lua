---
--- Created by Administrator.
--- DateTime: 2023/10/29 16:53:36
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEdenSelectPop:LWnd
local UIEdenSelectPop = LxWndClass("UIEdenSelectPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEdenSelectPop:UIEdenSelectPop()
	---@type table<number,UIIconEasyList>
	self._iconListClsTbl = {}
	--self._uiCommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEdenSelectPop:OnWndClose()
	self:ClearCommonIconList(self._iconListClsTbl)
	--self:ClearCommonIconList(self._uiCommonList)

	if self._seqCom  then
		self._seqCom:Destroy()
		self._seqCom= nil
	end


	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEdenSelectPop:OnCreate()
	LWnd.OnCreate(self)

	self._seqCom = SequenceCom:New()
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEdenSelectPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	--self:DoWndStartScale(0,self.mRoot)

	self:SetStaticContent()
	self:InitWndPara()
	self:RefreshUI()
end





function UIEdenSelectPop:OnClickChoose(index)
	if self._select == index then
		return
	end

	local item = self._chooseUIList[self._select]
	if item then
		local select = self:FindWndTrans(item,"select")
		CS.ShowObject(select,false)
	end
	item = self._chooseUIList[index]
	if item then
		local select = self:FindWndTrans(item,"select")
		CS.ShowObject(select,true)
	end
	self._select = index

end

function UIEdenSelectPop:OnTreasureConfirm()
	if self._wait then
		return
	end
	if not self._data.canSelect then
		local str =ccClientText(16765) --"您还未抵达宝箱"
		GF.ShowMessage(str)
		return
	end

	local para= nil
	if self._select == 1 then
		para = tostring(1)
	end

	local state = self._data.state
	local gridIndex = self._data.gridIndex
	local layerIndex = self._data.layerIndex
	if state == StructWonderlandGrid.ALLOW then
		gModelWonderland:WonderlandOpsReq(ModelWonderland.EVENT_SELECT_GRID,tostring(gridIndex))
	end

	gModelWonderland:WonderlandOpsReq(self._eventType,para)

	if self._select == 1 then
		self._wait = true
		gModelWonderland:WonderlandHeroMonsterReq(1,layerIndex,gridIndex)
	else
		self:WndClose()
	end

end

function UIEdenSelectPop:SetEventTitle()
	local eventCfg = self._eventCfg
	local name = ccLngText(eventCfg.name)
	self:SetWndText(self.mMainTitle,name)
end


function UIEdenSelectPop:RefreshUI()

	if self._type == 1 then
		self:ShowMonsterWnd()
	elseif self._type == 2 then
		self:ShowTreasureWnd()
	end


end


function UIEdenSelectPop:InitWndPara()
	local type = self:GetWndArg("type")
	self._func = self:GetWndArg("func")
	local data = self:GetWndArg("data")
	local eventId = data.eventId
	self._layerIndex = data.layerIndex
	self._eventId = eventId
	self._type = type
	self._data = data

	local eventCfg = gModelWonderland:GetEventConfig(data.eventId)
	local eventType = eventCfg.type
	self._eventType = eventType
	local textId = gModelWonderland:GetEventTextId(data.eventId)
	local textData = gModelWonderland:GetDefaultEventText(textId)
	self._eventCfg = eventCfg
	self._textData = textData
end

function UIEdenSelectPop:ShowCommonContent()
	self:SetWndText(self.mPost,self._textData.desc)

	local eventCfg = self._eventCfg
	local spineKey = eventCfg.prefab
	local prefabSize = eventCfg.prefabSize or 1
	if string.isempty(spineKey) then
		return
	end
	self:CreateWndSpine(self.mRole,spineKey,spineKey,false,function (spine)
		spine:SetScale(prefabSize)
		spine:PlayAnimation(0,"idle",true)
	end)

	self:SetEventTitle()
end

function UIEdenSelectPop:ShowTreasureList()
	local eventId = self._data.eventId
	local reward = gModelWonderland:GetEventRewardId(eventId)
	local parameter = self._eventCfg.parameter
	eventId = tonumber(parameter)
	local bigReward = gModelWonderland:GetEventRewardId(eventId)

	local data =
	{
		[1] =
		{
			title =self._textData.answer[1],
			index = 1,
			reward = bigReward,
		},
		[2] =
		{
			title =self._textData.answer[2],
			index = 2,
			reward = reward,
		}
	}
	self._select = 1
	self._chooseUIList = {}
	local itemList = self:GetUIScroll("uiList")
	itemList:Create(self.mChooseList,data,function (...) self:OnDrawChoose(...)  end)

	self:SetWndClick(self.mConfirmBtn,function () self:OnTreasureConfirm() end,LSoundConst.CLICK_BUTTON_COMMON)
	self:SetWndClick(self.mMask,function ()
		if self._wait then
			return
		end
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)


end


function UIEdenSelectPop:ShowMonsterSelect(reward,ratio)
	local data =
	{
		[1] =
		{
			title =ccClientText(16730),-- "正面挑战",
			index = 1,
			reward = reward,
		},
		[2] =
		{
			title =ccClientText(16731),-- "绕开它",
		 	index = 2,
			reward = reward,
			ratio = ratio,
		}
	}
	self._select = 1
	self._chooseUIList = {}
	local itemList = self:GetUIScroll("uiList")
	itemList:Create(self.mChooseList,data,function (...) self:OnDrawChoose(...)  end)

	self:SetWndClick(self.mConfirmBtn,function () self:OnClickConfirm() end,LSoundConst.CLICK_BUTTON_COMMON)
	--self:SetWndClick(self.mCancelBtn,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mMask,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end


function UIEdenSelectPop:OnWonderlandHeroMonsterResp(pb)
	--GF.CloseWndByName("UIEden")
	--self:WndClose()

	local eventCfg = self._eventCfg
	local eventName =ccLngText(eventCfg.name)


	local battleData = gModelWonderland:FormatBattleData(pb,eventName)
	--gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_WONDERLAND,battleData)
	gModelWonderland:EnterBattle(battleData,self:GetWndName())
end

function UIEdenSelectPop:ShowTreasureWnd()
	self:ShowCommonContent()
	self:SetWndImageGray(self.mConfirmBtn,not self._data.canSelect)
	self:WndNetMsgRecv(LProtoIds.WonderlandHeroMonsterResp,function(...) self:OnWonderlandHeroMonsterResp(...) end)
	self:ShowTreasureList()
end

function UIEdenSelectPop:SetStaticContent()
	local str =ccClientText(19626)-- "确定"
	self:SetWndButtonText(self.mConfirmBtn,str)
	str =ccClientText(16764) --"点击选择"
	self:SetWndText(self.mTitle,str)

	self:SetWndText(self.mCloseTip,ccClientText(10103))
end

function UIEdenSelectPop:OnClickCancel()
	self:WndClose()
end

function UIEdenSelectPop:ShowMonsterWnd()
	local reward,ratio = gModelWonderland:GetMonsterEventReward(self._eventId)
	self:ShowMonsterSelect(reward,ratio)
	self:ShowCommonContent()
end

function UIEdenSelectPop:OnDrawChoose(list, item,itemdata,itempos)
	local bg = self:FindWndTrans(item,"bg")
	local select = self:FindWndTrans(item,"select")
	local itemList = self:FindWndTrans(item,"itemList")
	local intro = self:FindWndTrans(item,"intro")

	self:SetWndText(intro,itemdata.title)
	local isSelect = self._select == itemdata.index
	CS.ShowObject(select,isSelect)

	local reward = itemdata.reward
	local dataList = gModelWonderland:GetEventReward(reward,self._layerIndex)
	if itemdata.ratio then
		local newDatas ={}
		for k,v in ipairs(dataList) do
			local data =
			{
				itemId = v.itemId,
				itemNum = math.ceil(v.itemNum*itemdata.ratio),
				itemType = v.itemType
			}
			table.insert(newDatas,data)
		end
		dataList = newDatas
	end

	local instanceId = item:GetInstanceID()
	local list = self._iconListClsTbl[instanceId]
	if not list then
		list = UIIconEasyList:New()
		self._iconListClsTbl[instanceId] = list
		list:Create(self, itemList)
		list:SetIconParentPath("root/Icon")
	end

	list:RefreshList(dataList)
	if #dataList>3 then
        local key = "delay"..instanceId
		local seq = self._seqCom:CreateSeq(key)
		seq:AppendInterval(0.02)
		seq:OnComplete(function ()
            list:EnableScroll(true, true)
			self._seqCom:DeleteSeq(key)
		end)
		seq:PlayForward()
	end


	self._chooseUIList[itemdata.index] = item
	self:SetWndClick(item,function () self:OnClickChoose(itemdata.index) end)
end

function UIEdenSelectPop:OnClickConfirm()
	local func = self._func


	self:WndClose()
	if func then
		func(self._select)
	end
end

------------------------------------------------------------------
return UIEdenSelectPop


