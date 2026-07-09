---
--- Created by BY.
--- DateTime: 2023/10/18 11:51:05
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMalCopySweepPop:LWnd
local UIMalCopySweepPop = LxWndClass("UIMalCopySweepPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMalCopySweepPop:UIMalCopySweepPop()
	self._uiCommonList = {}
	self._isSweep = false
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMalCopySweepPop:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMalCopySweepPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMalCopySweepPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UIMalCopySweepPop:InitData()
	self:SetWndText(self.mLblBiaoti,ccClientText(27623))
	self:SetWndText(self.mNumDesText,ccClientText(27625))
	self:SetWndText(self.mToggleText,ccClientText(27626))
	self:SetWndButtonText(self.mBtnCancel,ccClientText(27620))
	self:SetWndButtonText(self.mBtnSweep,ccClientText(27627))

	self._modelOpType = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_72] = ModelActivity.SWEETS_COUNTRY_SWEEP_BOSS ,
	}
	self._modelEnumList = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_72] = {
		-- 	ModelActivity.SWEET_COUNTRY_17,
		-- 	ModelActivity.SWEET_COUNTRY_18,
		-- },
	}
end
function UIMalCopySweepPop:InitMessage()
	self:SetWndToggleDelegate(self.mToggle,function (value)
		self._isSweep = value
		gModelActivity:SetBossSweepPopSignBySid(self._sid,value)
	end)
	--self:WndNetMsgRecv(LProtoIds.ActivitySpecialOpResp,function (pb)
	--	local sid = pb.sid
	--	local opType = pb.opType
	--	if self._sid ~= sid then return end
	--	local _turnBossSweepEnum = self._modelOpType[self._modelId]
	--	if _turnBossSweepEnum ~= opType then return end
	--	self:WndClose()
	--end)
end

function UIMalCopySweepPop:OnTryTcpReconnect()
	self:WndClose()
end

function UIMalCopySweepPop:OnClickSweep()
	local _bossItem = self._bossItem
	local _turnBossSweepEnum = self._modelOpType[self._modelId]
	gModelActivity:OnActivitySpecialOpReq(self._sid,_bossItem.pageId,_bossItem.entryId,0,nil,_turnBossSweepEnum)
end
function UIMalCopySweepPop:InitCommand()
	local sid = self:GetWndArg("sid")
	local bossItem = self:GetWndArg("bossItem")
	local pages = self:GetWndArg("pages")

	local modelId = gModelActivity:GetActivityModeIdBySid(sid)
	self._sid = sid
	self._bossItem = bossItem
	self._modelId = modelId
	local enums = self._modelEnumList[modelId]
	local _turnBossEnum = enums[1]
	local _turnBossRwardEnum = enums[2]

	self:SetWndToggleValue(self.mToggle, self._isSweep)

	local entryCfgB = bossItem.entryCfg
	local moreInfoB = JSON.decode(bossItem.moreInfo)
	local max_boss_hurt = moreInfoB.max_boss_hurt or -1
	local hurtNum = LUtil.NumberCoversion(max_boss_hurt)
	self:SetWndText(self.mHarmText,string.replace(ccClientText(27624),hurtNum))

	local page = pages[_turnBossEnum]
	if not page then return end
	local moreInfoP = JSON.decode(page.moreInfo)
	local list = {}
	if not string.isempty(moreInfoP.max_boss_hurt_reward)then
		local max_boss_hurt_reward = JSON.decode(moreInfoP.max_boss_hurt_reward)
		for i, v in ipairs(max_boss_hurt_reward) do
			list[v] = true
		end
	end


	local pageR = pages[_turnBossRwardEnum]
	if not pageR then return end
	local entrysR = pageR.entry
	local rwardStr = entryCfgB.reward
	for i, v in ipairs(entrysR) do
		local entryId = v.entryId
		if list[entryId] then
			local entryCfg = gModelActivity:GetWebActivityEntryData(sid,v.pageId,v.entryId)
			if string.isempty(rwardStr)then
				rwardStr = entryCfg.reward
			else
				rwardStr = rwardStr ..","..entryCfg.reward
			end
		end
	end
	local rwardList = {}
	if not string.isempty(rwardStr) then
		local reward = LxDataHelper.ParseItem(rwardStr)
		rwardList = LxDataHelper.MergeRewardList(reward)
	end

	local isSuper = #rwardList > 4
	local trUIList = isSuper and self.mRwardSuper or self.mRwardScroll
	CS.ShowObject(trUIList,true)
	local _uiRwardList = self:GetUIScroll("UIMalCopySweepPop_mRwardSuper")
	_uiRwardList:Create(trUIList,rwardList,function(...) self:AwardListItem(...) end,isSuper and UIItemList.SUPER or UIItemList.NORMAL)
end
function UIMalCopySweepPop:InitEvent()
	self:SetWndClick(self.mBg,function () self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end)
	self:SetWndClick(self.mBtnCancel,function () self:WndClose() end)
	self:SetWndClick(self.mBtnSweep,function () self:OnClickSweep() end)
end
function UIMalCopySweepPop:AwardListItem(list, item, itemdata, itempos)
	local root = CS.FindTrans(item,"Root")
	local uiCommonList = self._uiCommonList
	local InstanceID = item:GetInstanceID()
	local baseClass = uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		uiCommonList[InstanceID] = baseClass
		baseClass:Create(root)
		self:SetIconClickScale(root, true)
	end
	baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
	self:SetWndClick(root,function()
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)
	baseClass:DoApply()
end
------------------------------------------------------------------
return UIMalCopySweepPop


