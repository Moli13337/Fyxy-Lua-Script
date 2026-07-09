---
--- Created by BY.
--- DateTime: 2023/10/9 12:02:35
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdBraveBossInformation:LWnd
local UIGdBraveBossInformation = LxWndClass("UIGdBraveBossInformation", LWnd)
local typeof = typeof
local typeOfScrollRect = typeof(UnityEngine.UI.ScrollRect)

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdBraveBossInformation:UIGdBraveBossInformation()
	self._tabTrList = {}
	self._delayUpdateScrollTimerList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdBraveBossInformation:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdBraveBossInformation:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdBraveBossInformation:OnStart()
	LWnd.OnStart(self)
	self:InitUI()


	self.jpj = gLGameLanguage:IsJapanVersion()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIGdBraveBossInformation:OnClickTab(type)
	local _type = self._type
	local _tabTrList = self._tabTrList
	if _type then
		local tab = _tabTrList[_type]
		self:SetWndTabStatus(tab, 1)
	end
	local tab = _tabTrList[type]
	self:SetWndTabStatus(tab, 0)
	self._type = type
	self:RefreshData()
end

function UIGdBraveBossInformation:StartDelayTimer(ResultNode, key, normalized)
	if not ResultNode then
		return
	end
	local resultNode = ResultNode:GetComponent(typeOfScrollRect)
	local _delayUpdateScrollTimerList = self._delayUpdateScrollTimerList
	local _delayUpdateScrollTimer = _delayUpdateScrollTimerList[key]
	if _delayUpdateScrollTimer then
		return
	end
	_delayUpdateScrollTimer = LxTimer.DelayFrameCall(function()
		if normalized then
			resultNode.verticalNormalizedPosition = normalized
		end
		_delayUpdateScrollTimer = nil
	end, 1)
	self._delayUpdateScrollTimerList[key] = _delayUpdateScrollTimer
end
function UIGdBraveBossInformation:RefreshSkillMag()
	local info = gModelGuildBoss:GetGuildBraveInfo()
	local refId = info.braveId
	local ref = gModelGuildBoss:GetNewGuildDungeonMonsterRefByRefId(refId)

	if not string.isempty(ref.HeadIconShow)then
		CS.ShowObject(self.mBossIcon,true)
		self:SetWndEasyImage(self.mBossIcon,ref.HeadIconShow)
		local levelRef = gModelGuildBoss:GetNewGuildDungeonLevelRefByRefId(info.level)
		self:SetWndText(self.mBossLvText,levelRef.level)
		self:SetWndText(self.mBossNameText,ccLngText(ref.name))
		local scoreLevelRef = gModelGuildBoss:GetNewGuildDungeonRatingRefByRefId(info.scoreLevel)
		self:SetWndEasyImage(self.mBossRating,scoreLevelRef.ratingIcon)
	end
	if string.isempty(ref.skillShow)then return end
	local list = string.split(ref.skillShow,"|")

	local skillUiList = self._skillUiList
	if skillUiList then
		skillUiList:RefreshList(list)
		skillUiList:DrawAllItems()
	else
		skillUiList = self:GetUIScroll("skillUiList")
		skillUiList:Create(self.mSkillSuper,list,function(...) self:SkillListItem(...) end,UIItemList.SUPER)
		self._skillUiList = skillUiList
	end
end
function UIGdBraveBossInformation:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(32707))
	self:UpdateResultText(self.mAddDesText, self.mAddResultNode, ccClientText(32708), "mAddResultNode",1)
	--self:SetWndText(self.mAddDesText,ccClientText(32708))

	local list = {
		{type = 1,title = ccClientText(32710)},
		{type = 2,title = ccClientText(32709)},
	}
	local uiList = self:GetUIScroll("TabScroll")
	uiList:Create(self.mTabScroll,list,function(...) self:ListItem(...) end)
	self:OnClickTab(list[1].type)
end
function UIGdBraveBossInformation:RefreshAddMag()
	local info = gModelGuildBoss:GetGuildBraveInfo()
	local scoreWord = info.scoreWord
	if string.isempty(scoreWord)then return end
	local list = string.split(scoreWord,"|")

	local addUiList = self._addUiList
	if addUiList then
		addUiList:RefreshList(list)
		addUiList:DrawAllItems()
	else
		addUiList = self:GetUIScroll("addUiList")
		addUiList:Create(self.mAddSuper,list,function(...) self:AddListItem(...) end,UIItemList.SUPER)
		self._addUiList = addUiList
	end
end

function UIGdBraveBossInformation:UpdateResultText(ResultText, ResultNode, text, key, normalized)
	self:SetWndText(ResultText, text)
	self:StartDelayTimer(ResultNode, key, normalized)
end
function UIGdBraveBossInformation:SkillListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local titleText = self:FindWndTrans(root,"TitleText")
	local skillIcon = self:FindWndTrans(root,"SkillBg/SkillIcon")
	local resultNode = self:FindWndTrans(root,"ResultNode")
	local desText = self:FindWndTrans(root,"ResultNode/DesText")

	local InstanceID = item:GetInstanceID()
	local skillId = tonumber(itemdata)
	local ref = gModelGuildBoss:GetSkillRefByRefId(skillId)
	self:SetWndText(titleText,ccLngText(ref.name))
	self:SetWndEasyImage(skillIcon,ref.icon)
	--self:SetWndText(desText,ccLngText(ref.description))

	self:UpdateResultText(desText, resultNode, ccLngText(ref.description), InstanceID)
end

function UIGdBraveBossInformation:RefreshData()
	local _type = self._type
	CS.ShowObject(self.mAddMag,_type == 1)
	CS.ShowObject(self.mSkillMag,_type == 2)
	if _type == 1 then
		self:RefreshAddMag()
	else
		self:RefreshSkillMag()
	end
end
function UIGdBraveBossInformation:InitMessage()
	self:WndNetMsgRecv(LProtoIds.GuildBraveResp,function(pb) self:RefreshData() end)
end

function UIGdBraveBossInformation:ListItem(list, item, itemdata, itempos)
	local btnTab = self:FindWndTrans(item,"BtnTab1")
	local type = itemdata.type
	local title = itemdata.title
	self._tabTrList[type] = btnTab
	local size = 0
	local line = 0
	if self.jpj then
		size = -2
		line = -30
	end
	self:SetWndTabText(btnTab,title,size,line)
	self:SetWndTabStatus(btnTab, 1)
	self:SetWndClick(item,function  ()
		self:OnClickTab(type)
	end)
end
function UIGdBraveBossInformation:AddListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local raceIcon = self:FindWndTrans(root,"RaceIcon")
	local jobIcon = self:FindWndTrans(root,"JobIcon")
	local heroBg = self:FindWndTrans(root,"HeroBg")
	local heroIcon = self:FindWndTrans(root,"HeroBg/HeroIcon")
	local resultNode = self:FindWndTrans(root,"ResultNode")
	local desText = self:FindWndTrans(root,"ResultNode/DesText")

	local InstanceID = item:GetInstanceID()
	local scoreWordId = tonumber(itemdata)
	local ref = gModelGuildBoss:GetNewGuildDungeonBonusRefByRefId(scoreWordId)
	local type,para,bonus = ref.type,string.split(ref.para,"="),ref.bonus
	local desStr = ""
	CS.ShowObject(raceIcon ,type == 1)
	CS.ShowObject(jobIcon ,type == 2)
	CS.ShowObject(heroBg ,type == 3)
	if type == 1 then
		local race = para[1]
		local num = para[2]
		local raceRef = gModelHero:GetHeroRaceRefByRefId(tonumber(race))
		desStr = string.replace(ccClientText(32721),num,ccLngText(raceRef.name),(bonus*100 .. "%"))
		self:SetWndEasyImage(raceIcon,raceRef.icon)
	elseif type == 2 then
		local job = para[1]
		local num = para[2]
		local careerRef = gModelHero:GetCareerRefByRefId(tonumber(job))
		desStr = string.replace(ccClientText(32722),num,ccLngText(careerRef.name),(bonus*100 .. "%"))
		self:SetWndEasyImage(jobIcon,careerRef.jobIcon)
	elseif type == 3 then
		local heroRefId = para[1]
		local star = para[2]
		local effRef = gModelHero:GetHeroShowRefByRefId(tonumber(heroRefId), tonumber(star))
		desStr = string.replace(ccClientText(32723),star,ccLngText(effRef.name),(bonus*100 .. "%"))
		self:SetWndEasyImage(heroIcon,effRef.icon)
	end
	desStr = desStr --.. string.replace(ccClientText(32724),(bonus*100 .. "%"))
	--self:SetWndText(desText,desStr)
	self:UpdateResultText(desText, resultNode, desStr, InstanceID)
end

function UIGdBraveBossInformation:InitEvent()
	self:SetWndClick(self.mBgImage,function () self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end)
end
------------------------------------------------------------------
return UIGdBraveBossInformation


