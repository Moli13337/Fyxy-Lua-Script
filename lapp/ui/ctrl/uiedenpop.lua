---
--- Created by Administrator.
--- DateTime: 2023/10/19 16:04:53
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEdenPop:LWnd
local UIEdenPop = LxWndClass("UIEdenPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEdenPop:UIEdenPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEdenPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEdenPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEdenPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetStaticContent()
	self:InitData()
	self:InitUIEvent()
	self:InitWndPara()
	self:RefreshUI()

	self:WndNetMsgRecv(LProtoIds.WonderlandOpsResp,function (pb)
		local type = pb.type
		if type == self._eventType then
			self:WndClose()
		end
	end)
end

function UIEdenPop:BoxConfirm()

	local canSelect = self._data.canSelect
	if not canSelect then
		local str =ccClientText(16727)-- "您还没有找到宝箱所在,无法打开!"
		GF.ShowMessage(str)
		return
	end

	local state = self._data.state
	local gridIndex = self._data.gridIndex
	local layerIndex = self._data.layerIndex
	if state == StructWonderlandGrid.ALLOW then
		gModelWonderland:WonderlandOpsReq(ModelWonderland.EVENT_SELECT_GRID,tostring(gridIndex))
	end

	local eventId = self._data.eventId
	local event = gModelWonderland:GetEventData(layerIndex,gridIndex,eventId)

	if not event then
		return
	end

	local type = event.type
	if self._eventType then
		gModelWonderland:WonderlandOpsReq(self._eventType)
	end

	if type == 1 then
		GF.OpenWnd("UIEdenMonsterPop",{gridIndex= gridIndex,layerIndex = layerIndex ,wndType = 1})
		self:WndClose()
	end
end

function UIEdenPop:OnClickConfirm()
	local wndType = self._wndType
	if wndType == 1 then --宝箱怪
		self:BoxConfirm()
	elseif wndType == 2 then --拾取
		self:NormalConfirm()
	end
end

function UIEdenPop:InitData()
	self._needOperEvent=
	{
		[ModelWonderland.EVENT_POD] = true,--
		[ModelWonderland.EVENT_CLIP] = true,--
		[ModelWonderland.EVENT_BEAN_VINE] = true,--
		[ModelWonderland.EVENT_OCTOPUS] = true,--
		[ModelWonderland.EVENT_FOAM] = true,--
		[ModelWonderland.EVENT_GOLD_HAIR] = true,--
		[ModelWonderland.EVENT_MIRROR] = true,--
		--[ModelWonderland.EVENT_POISON] = true,--
		--[ModelWonderland.EVENT_ARROW_TOWER] = true,--
		[ModelWonderland.EVENT_SINGING] = true,--
		[ModelWonderland.EVENT_WORLD_TREE] = true,--
		[ModelWonderland.EVENT_TIME] = true,--
	}
end

function UIEdenPop:SetStaticContent()
	--local str = ccClientText(19626)
	--self:SetWndButtonText(self.mOk,str)
	self:SetWndText(self.mCloseTip,ccClientText(10103))
	local str = ccClientText(10361)
	self:SetTextTile(self.mTextTitle,str)
end

function UIEdenPop:InitUIEvent()
	self:SetWndClick(self.mMask,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mOk,function () self:OnClickConfirm() end,LSoundConst.CLICK_BUTTON_COMMON)
	self:SetWndClick(self.mCloseTip,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIEdenPop:RefreshUI()
	local canSelect = self._data.canSelect
	self:SetWndImageGray(self.mOk,not canSelect)
	local post = self._textData.desc
	self:SetWndText(self.mPost,post)

	self:SetWndText(self.mMainTitle,self._name)
	local spineKey = self._eventCfg.prefab
	if string.isempty(spineKey) then
		return
	end
	self:CreateWndSpine(self.mRole,spineKey,spineKey,false,function (spine)
		spine:SetScale(2)
		spine:PlayAnimation(0,"idle",true)
	end)
	local eventId = self._data.eventId

	local rewardId = gModelWonderland:GetEventRewardId(eventId)
	local showReward = rewardId ~= nil

	CS.ShowObject(self.mRewardRoot,showReward)

	local str = nil
	if self._data.eventType == ModelWonderland.EVENT_BOX then
		str =ccClientText(16726) --"开 启"
	else
		str = ccClientText(16798)
	end
	self:SetWndButtonText(self.mOk,str)

	if not showReward then
		return
	end
	local layerIndex = self._data.layerIndex

	local rewardLocal = gModelWonderland:GetEventReward(rewardId,layerIndex)


	local rewardList = self._rewardListCls
	if not rewardList then
		rewardList = UIIconEasyList:New()
		self._rewardListCls = rewardList
		rewardList:Create(self, self.mItemList)
		rewardList:SetIconParentPath("iconRoot")

	end
	rewardList:RefreshList(rewardLocal)


end

function UIEdenPop:NormalConfirm()
	local canSelect = self._data.canSelect
	if not canSelect then
		local str =ccClientText(16779) --"您还没有靠近%s"
		str = string.replace(str,self._name)
		GF.ShowMessage(str)
		return
	end

	local state = self._data.state
	local layerIndex = self._data.layerIndex
	local gridIndex = self._data.gridIndex
	if state == StructWonderlandGrid.ALLOW then
		gModelWonderland:WonderlandOpsReq(ModelWonderland.EVENT_SELECT_GRID,tostring(gridIndex))
	end

	local eventType = self._eventType
	if eventType and self._needOperEvent[eventType] then
		gModelWonderland:WonderlandOpsReq(eventType)
	end

	--if eventType == ModelWonderland.EVENT_TIME then
		--GF.ChangeMap("LWonderlordMap",false,{data = self._data })
	--elseif eventType == ModelWonderland.EVENT_MIRROR then
	--	local map = GF.GetCurMap()
	--	if map:IsSameMap("LWonderlandMap") then
	--		local gridPos = map:GetGridPos(layerIndex,gridIndex)
	--		FireEvent(EventNames.ON_GAIN_ITEM,gridPos)
	--	end



	--end

	self:WndClose()
end

function UIEdenPop:InitWndPara()
	self._wndType = self:GetWndArg("wndType")
	local data = self:GetWndArg("data")
	self._eventType = data.eventType
	self._data = data
	local eventCfg = gModelWonderland:GetEventConfig(data.eventId)
	self._name = ccLngText(eventCfg.name)
	local textId = gModelWonderland:GetEventTextId(data.eventId)
	local textData = gModelWonderland:GetDefaultEventText(textId)
	self._eventCfg = eventCfg
	self._textData = textData
end



------------------------------------------------------------------
return UIEdenPop


