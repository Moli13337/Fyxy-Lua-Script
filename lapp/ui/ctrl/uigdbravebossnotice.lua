---
--- Created by BY.
--- DateTime: 2023/10/8 14:54:59
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdBraveBossNotice:LWnd
local UIGdBraveBossNotice = LxWndClass("UIGdBraveBossNotice", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdBraveBossNotice:UIGdBraveBossNotice()
	self._timeKey = "_UIGdBraveBossNoticeTime"
	self._heroIconList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdBraveBossNotice:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdBraveBossNotice:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdBraveBossNotice:OnStart()
	LWnd.OnStart(self)
	self:InitUI()


	self.jpj = gLGameLanguage:IsJapanVersion()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UIGdBraveBossNotice:SetTime()
	local endTime = self._endTime
	local timespan = endTime/1000 - GetTimestamp()
	if timespan < 1 then
		self:TimerStop(self._timeKey)
		CS.ShowObject(self.mTimeBg,false)
		return
	end

	local timeStr = LUtil.FormatTimespanCn(timespan)
	timeStr = string.replace(ccClientText(32740),timeStr)

	self:SetWndText(self.mTimeText,timeStr)
	if self.jpj then
		self:InitTextSizeWithLanguage(self.mTimeText,-2)
	end
	CS.ShowObject(self.mTimeBg,true)
end

function UIGdBraveBossNotice:OnTimer(key)
	if(key == self._timeKey)then
		self:SetTime()
	end
end

function UIGdBraveBossNotice:SetHeroIcon(iconTrans, instanceId, heroData)
	local baseClass = self._heroIconList[instanceId]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._heroIconList[instanceId] = baseClass
		baseClass:Create(iconTrans)
		self:SetIconClickScale(iconTrans, true)
	end
	baseClass:SetHeroDataSet(heroData)
	baseClass:DoApply()
end
function UIGdBraveBossNotice:InitCommand()
	self:SetWndText(self.mCloseTip,ccClientText(10103))
	self:SetWndText(self.mAddText,ccClientText(32714))
	if self.jpj then
		self:InitTextSizeWithLanguage(self.mAddText,-6)
	end
	self:RefreshData()
end

function UIGdBraveBossNotice:RefreshData()
	local info = gModelGuildBoss:GetGuildBraveInfo()
	if not info then
		gModelGuildBoss:OnGuildBraveReq()
		return
	end
	local refId = info.braveId
	local ref = gModelGuildBoss:GetNewGuildDungeonMonsterRefByRefId(refId)
	local nextId = ref.nextId
	local nexRef = gModelGuildBoss:GetNewGuildDungeonMonsterRefByRefId(nextId)

	-- CS.ShowObject(self.mBossBg,true)
	-- self:SetWndEasyImage(self.mBossBg,nexRef.bgImage)
	self:SetWndText(self.mTitleText,ccLngText(nexRef.name))
	self:CreateWndSpine(self.mBossSpine,nexRef.show,"mBossSpine",false,function(dpSpine)
		local pos = LxDataHelper.ParseVector2NotEmpty(nexRef.trailerXY)
		self:SetAnchorPos(self.mBossSpine, pos)
		dpSpine:SetScale(nexRef.trailerScale)
	end)

	if not string.isempty(info.endTime)then
		self._endTime = tonumber(info.endTime)
		self:TimerStop(self._timeKey)
		self:TimerStart(self._timeKey,1,false,-1)
		self:SetTime()
	end
	if not string.isempty(info.scoreWordNext) then
		local list = string.split(info.scoreWordNext,"|")

		-- local addUiList = self._addUiList
		-- if addUiList then
		-- 	addUiList:RefreshList(list)
		-- else
		-- 	addUiList = self:GetUIScroll("addUiList")
		-- 	addUiList:Create(self.mAddScroll,list,function(...) self:ListItem(...) end)
		-- 	self._addUiList = addUiList
		-- end

		for i = 1, #list do
			self:ListItem(_, self["mAddRoot" .. i], list[i])
			CS.ShowObject(self["mAddRoot" .. i], true)
		end
	end
	if not string.isempty(nexRef.skillShow)then
		local list = string.split(nexRef.skillShow,"|")

		local skillUiList = self._skillUiList
		if skillUiList then
			skillUiList:RefreshList(list)
		else
			skillUiList = self:GetUIScroll("skillUiList")
			skillUiList:Create(self.mSkillScroll,list,function(...) self:SkillListItem(...) end)
			self._skillUiList = skillUiList
		end
	end
end
function UIGdBraveBossNotice:InitMessage()
	self:WndNetMsgRecv(LProtoIds.GuildBraveResp,function(pb) self:RefreshData() end)
end

function UIGdBraveBossNotice:InitEvent()
	self:SetWndClick(self.mBgImage,function () self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end)
end

function UIGdBraveBossNotice:OnClickAddItem(root,des)
	GF.OpenWnd("UIBosAddT",{root = root,other = des})
end
function UIGdBraveBossNotice:SkillListItem(list, item, itemdata, itempos)
	local skillIcon = self:FindWndTrans(item,"SkillIcon")

	local skillId = tonumber(itemdata)
	local ref = gModelGuildBoss:GetSkillRefByRefId(skillId)
	self:SetWndEasyImage(skillIcon,ref.icon)
	self:SetWndClick(item,function ()
		gModelGeneral:OpenSkillWnd({curSkillId = skillId,wndType = 2})
	end)
end

function UIGdBraveBossNotice:ListItem(list, item, itemdata, itempos)
	-- local root = self:FindWndTrans(item,"Root")
	local root = item
	local raceIcon = self:FindWndTrans(root,"RaceIcon")
	local jobIcon = self:FindWndTrans(root,"JobIcon")
	local heroIcon = self:FindWndTrans(root,"HeroIcon")
	local numText = self:FindWndTrans(root,"NumText")

	local InstanceID = item:GetInstanceID()
	local scoreWordId = tonumber(itemdata)
	local ref = gModelGuildBoss:GetNewGuildDungeonBonusRefByRefId(scoreWordId)
	local type,para,bonus = ref.type,string.split(ref.para,"="),ref.bonus
	local desStr = ""
	CS.ShowObject(raceIcon ,type == 1)
	CS.ShowObject(jobIcon ,type == 2)
	CS.ShowObject(heroIcon ,type == 3)
	CS.ShowObject(numText ,type ~= 3)
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

		local heroData = {
			refId = tonumber(heroRefId),
			star = tonumber(star),
		}
		self:SetHeroIcon(heroIcon, InstanceID, heroData)
	end
	self:SetWndText(numText,para[2])
	desStr = desStr --.. string.replace(ccClientText(32724),(bonus*100 .. "%"))
	self:SetWndClick(root,function ()
		-- self:OnClickAddItem(root,desStr)
		GF.ShowMessage(desStr .. "#posY=-302#")
	end)
	self:SetWndClick(heroIcon,function ()
		-- self:OnClickAddItem(root,desStr)
		GF.ShowMessage(desStr .. "#posY=-302#")
	end)
end
------------------------------------------------------------------
return UIGdBraveBossNotice


