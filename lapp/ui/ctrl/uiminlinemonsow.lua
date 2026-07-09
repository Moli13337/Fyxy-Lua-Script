---
--- Created by Administrator.
--- DateTime: 2023/10/11 18:08:01
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMinLineMonSow:LWnd
local UIMinLineMonSow = LxWndClass("UIMinLineMonSow", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMinLineMonSow:UIMinLineMonSow()
	---@type UIIconEasyList
	self._iconList = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMinLineMonSow:OnWndClose()
	gLFightIdleManager:OnChallengeUIShow(false)
	
	if self._iconList then
		self._iconList:Destroy()
		self._iconList = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMinLineMonSow:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMinLineMonSow:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:InitUIEvent()
	self:SetStaticContent()
	self:InitRewardList()
	self:CreateRole()

	--local battleNode =gModelInstance:GetBattleNode()
	--FireEvent(EventNames.TRIGGER_PLOT_BY_MAIN,battleNode)
end

function UIMinLineMonSow:InitData()
	self._missionRefId = self:GetWndArg("mission")

	self._battleNum = 0
	local missionRef = gModelInstance:GetMissionCfg(self._missionRefId)
	if missionRef then
		self._battleNum = missionRef.num
		local tasRewardDatalist= LxDataHelper.ParseItem(missionRef.winReward)
		self._rewardDataList = tasRewardDatalist

		local mainSceneMonId3 = missionRef.mainSceneMonId3
		local bossMonList = LxDataHelper.ParseIntParam_Semicolon(mainSceneMonId3)
		local monRef
		local aniShowEffRef

		if(bossMonList and #bossMonList > 0) then

			monRef = GameTable.MonsterAttrRef[bossMonList[1]]
		end

		if monRef then
			local effectId = monRef.effectId

			aniShowEffRef = GameTable.CharacterEffectRef[effectId]
		end

		if aniShowEffRef then
			self._spineName = aniShowEffRef.prefabName
			--self._spinePos = LxDataHelper.ParseVector(aniShowEffRef.heroInsPos, "|")
			self._spinePos = Vector3(0, 0, 0)
		end
	end
end

function UIMinLineMonSow:SetStaticContent()
	self:SetWndText(self.mCloseTip,ccClientText(10103))

	local text

	self:SetWndButtonText(self.mFormationBtn,ccClientText(10778))
	self:SetWndButtonText(self.mFightBtn,ccClientText(10779))

	text = self:FindWndTrans(self.mTextBg,"post")
	self:SetWndText(text,ccClientText(10774))

end

function UIMinLineMonSow:GotoFight()
	self:WndClose()
	local heorCombatTips = gModelInstance:GetInstancePara("heorCombatTips")
	local cfg = gModelInstance:GetMissionCfg(heorCombatTips)
	local battleNum = gModelInstance:GetBattleNum()
	local heroCnt = gModelFormation:GetFormationHerosNum(LCombatTypeConst.COMBAT_MAIN)
	local skipBattleFunc = function()
		gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_MAIN)
	end
	local prepareFunc = function()
		gModelBattle:TryGotoMainBattle()
	end
	if battleNum >= cfg.num and  heroCnt > 0 and heroCnt < 5 then
		local para =
		{
			refId = 30010,
			func = prepareFunc,
			leftFunc = skipBattleFunc,
		}
		gModelGeneral:OpenUIOrdinTips(para)
	else
		if prepareFunc then
			prepareFunc()
		end
	end
end

function UIMinLineMonSow:InitUIEvent()
	self:SetWndClick(self.mMask,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mFightBtn,function ()
		self:GotoFight()
	end, LSoundConst.CLICK_FIGHT)

	self:SetWndClick(self.mFormationBtn,function ()
		self:GotoPrepare()
	end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UIMinLineMonSow:InitRewardList()
	local uiIconEasyList = self._iconList
	if not uiIconEasyList then
		uiIconEasyList = UIIconEasyList:New()
		self._iconList = uiIconEasyList
		uiIconEasyList:Create(self, self.mItemList)
	end
	local rewardDataList = self._rewardDataList or {}
	uiIconEasyList:RefreshList(rewardDataList)
	self._iconList:EnableScroll(#rewardDataList > 5,true)
end


function UIMinLineMonSow:CreateRole()
	local spineName = self._spineName
	if string.isempty(spineName) then return end
	self:CreateWndSpine(self.mRole,spineName,"rolekey",false,function (spine)
		spine:SetScale(2)
		spine:PlayAnimation(0,"idle",true)
	end)

	if self._spinePos then
		local pos = self.mRole.localPosition
		pos.x = self._spinePos.x + pos.x
		pos.y = self._spinePos.y + pos.y
		self.mRole.localPosition = pos
	end
end

function UIMinLineMonSow:GotoPrepare()
	self:WndClose()


	gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_MAIN,{isAutoOneKeyUp=self._isAutoOneKeyUp})
end

------------------------------------------------------------------
return UIMinLineMonSow


