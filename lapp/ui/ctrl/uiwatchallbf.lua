---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIWatchAllBf:LWnd
local UIWatchAllBf = LxWndClass("UIWatchAllBf", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIWatchAllBf:UIWatchAllBf()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIWatchAllBf:OnWndClose()
	--self:ClearCommonIconList(self._heroIconList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIWatchAllBf:OnCreate()
	LWnd.OnCreate(self)
	self._buffListList = {}
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIWatchAllBf:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIWatchAllBf:OnClickHeroIcon(itemdata)
	local curBattle = gLFightManager:GetCurBattleUnit()
	if not curBattle then
		return
	end

	local combatType = curBattle:GetCombatType()
	if combatType == LCombatTypeConst.COMBAT_BATTLE_VIDEO_SIMULATION then
		local str =ccClientText(16905) --"不可查看英雄信息"
		GF.ShowMessage(str)
		return
	end

	local combatType = curBattle:GetReportCombatType()
	local showTip = true
	local playerId
	local serverId
	local _actOn = itemdata:GetActOn()
	if _actOn == 1 then
		playerId = self._teamA.playerId
		serverId = self._teamA.serverId
	else
		playerId = self._teamB.playerId
		serverId = self._teamB.serverId
		showTip = gModelBattle:CheckShowEnemyTip(combatType)
	end

	if showTip then
		local data = {
			id = itemdata:GetId(),
			refId = itemdata:GetRefId(),
			level = itemdata:GetLevel(),
			star = itemdata:GetStar(),
			grade = itemdata:GetGrade(),
			fightPower = itemdata:GetFightPower() or 0,
			isResonance = itemdata:GetResonanceStatus(),
			skin = itemdata:GetSkinId(),
		}
		gModelHero:ReqShowHeroTipEx({playerId = playerId,heroData = data,serverId = serverId})
	else
		local str = ccClientText(16905)
		GF.ShowMessage(str)
	end


	--if combatType == LCombatTypeConst.COMBAT_BATTLE_VIDEO_SIMULATION then
	--	local str =ccClientText(16905) --"不可查看英雄信息"
	--	GF.ShowMessage(str)
	--	return
	--end
	--if not itemdata:IsMonster() then
	--	local playerId
	--	local serverId
	--	local _actOn = itemdata:GetActOn()
	--	if _actOn == 1 then
	--		playerId = self._teamA.playerId
	--		serverId = self._teamA.serverId
	--	else
	--		playerId = self._teamB.playerId
	--		serverId = self._teamB.serverId
	--	end
	--	local data = {
	--		id = itemdata:GetId(),
	--		refId = itemdata:GetRefId(),
	--		level = itemdata:GetLevel(),
	--		star = itemdata:GetStar(),
	--		grade = itemdata:GetGrade(),
	--		fightPower = itemdata:GetFightPower() or 0,
	--		isResonance = itemdata:GetResonanceStatus(),
	--		skin = itemdata:GetSkinId(),
	--	}
	--	gModelHero:ReqShowHeroTipEx({playerId = playerId,heroData = data,serverId = serverId})
	--else
	--	local str = ccClientText(16905)
	--	GF.ShowMessage(str)
	--end
end

function UIWatchAllBf:InitCommand()
	self._extraData = self:GetWndArg("extraData")
	self:SetWndText(self.mTipsText,ccClientText(10103))
	self:UpdateData()
end

function UIWatchAllBf:InitEvent()
	self:SetWndClick(self.mBg, function (...)
		self:WndClose()
	end)
end

function UIWatchAllBf:InitMessage()
	--数据变化通知刷新
	self:WndEventRecv(EventNames.BUFF_UPDATE,function ()
		self:UpdateData()
	end)
end


--function UIWatchAllBf:InitHeroTrans(rootTrans,formationData,isSelf)
--	local itemListTrans = CS.FindTrans(rootTrans,"ItemList")
--
--end

-- 刷新buff列表
function UIWatchAllBf:InitScrollView(itemListTrans,formationData,isSelf)

	local dataList = {}
	if formationData  then
		for k,v in pairs(formationData) do
			table.insert(dataList,v)
		end
	end

	local key = isSelf and "myList" or "otherList"

	local itemList = self:FindUIScroll(key)
	if not itemList then
		itemList= self:GetUIScroll(key)
		itemList:Create(itemListTrans,dataList,function (...) self:OnDrawItemCell(...) end,UIItemList.SUPER)
	else
		itemList:RefreshList(dataList)
	end

	itemList:DrawAllItems(false)

end

function UIWatchAllBf:UpdateData()
	local battleUnit = gLFightManager:GetCurBattleUnit()
	if not battleUnit then
		return
	end

	self._formationA = battleUnit:GetFormationA()
	self._formationB = battleUnit:GetFormationB()

	self._teamA = battleUnit:GetTeamAData()
	self._teamB = battleUnit:GetTeamBData()

	local leftName = nil
	local rightName = nil
	local comBatType = battleUnit:GetCombatType()
	local extraData = battleUnit:GetCombatExtraData()
	if comBatType == LCombatTypeConst.COMBAT_BATTLE_VIDEO_SIMULATION then
		leftName = extraData.meName
		rightName = extraData.otherName
	else
		local curBattle = gLFightManager:GetCurBattleUnit()
		if curBattle then
			leftName = curBattle:GetFormationName(true)
			rightName = curBattle:GetFormationName(false)
		end
	end

	if string.isempty(leftName) then
		leftName = extraData.meName
	end

	if string.isempty(rightName) then
		rightName = extraData.otherName
	end

	--local meName = self._extraData.meName or ""
	--local otherName = self._extraData.otherName or ""
	--self:InitHeroTrans(self.mPlayer,self._formationA,true)
	--self:InitHeroTrans(self.mEnemy,self._formationB,false)

	self:InitScrollView(self.mLeftItemList,self._formationA,true)
	self:InitScrollView(self.mRightItemList,self._formationB,false)
	self:SetXUITextText(self.mMeNameText, leftName)
	self:SetXUITextText(self.mOtherNameText, rightName)
end

function UIWatchAllBf:OnDrawBuff(list,item,itemdata,itempos)
	local BuffImage = self:FindWndTrans(item,"BuffImage")
	local BuffImageBuffCount = self:FindWndTrans(BuffImage,"BuffCount")

	local buffData = itemdata.buffShowData
	local cnt = #itemdata.buffShowList
	self:SetWndEasyImage(BuffImage,buffData.icon)
	self:SetWndText(BuffImageBuffCount,cnt)
end

function UIWatchAllBf:OnDrawItemCell(list,item, itemdata, itempos)

	--local BG = self:FindWndTrans(item,"BG")
	local MaskImg = self:FindWndTrans(item,"MaskImg")
	--local MaskImgDead = self:FindWndTrans(MaskImg,"Dead")
	local BuffList = self:FindWndTrans(item,"BuffList")
	--local BuffListImageBg = self:FindWndTrans(BuffList,"ImageBg")

	local heroIconTran = self:FindWndTrans(item,"HeroIcon")

	--local instanceId = heroIconTran:GetInstanceID()
	--local commonIcon = self:GetCommonIcon(instanceId)
	local herodata = {}
	herodata.id = itemdata:GetId()
	herodata.refId = itemdata:GetRefId()
	herodata.star = itemdata:GetStar()
	herodata.level = itemdata:GetLevel()
	herodata.isMon = itemdata:IsMonster()
	herodata.isResonance = itemdata:GetResonanceStatus()
	herodata.skin = itemdata:GetSkinId()
	herodata.form = itemdata:GetForm()
	local quality = itemdata:GetQuality()
	if quality and quality>0 then
		herodata.quality = quality
	end
	--commonIcon:Create(heroIconTran)
	--commonIcon:SetHeroDataSet(herodata)
	--commonIcon:DoApply()

	self:CreateHeroIconImpl(heroIconTran,herodata)

	local isDead = itemdata:IsDead() or itemdata:GetHp() == 0

	CS.ShowObject(MaskImg, isDead)

	self:SetWndClick(BuffList,function()
		if isDead then
			return
		end
		GF.OpenWnd("UIBfDetails",{ heroData = itemdata })
	end)

	self:SetWndClick(heroIconTran,function ()
		self:OnClickHeroIcon(itemdata)
	end)

	local buffList = itemdata:GetBuffList()
	local dataList = gModelSkill:FormatBuffShowList(buffList)

	local instanceId = item:GetInstanceID()
	local list = self:FindUIScroll(instanceId)
	if not list then
		list = self:GetUIScroll(instanceId)
		list:Create(BuffList,dataList,function (...) self:OnDrawBuff(...) end,UIItemList.SUPER_GRID)
	else
		list:RefreshList(dataList)
	end
	list:DrawAllItems(false)


end

------------------------------------------------------------------
return UIWatchAllBf


