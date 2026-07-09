---
--- Created by Administrator.
--- DateTime: 2024/5/27 15:39:25
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubNewAct18Rk:LChildWnd
local UISubNewAct18Rk = LxWndClass("UISubNewAct18Rk", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubNewAct18Rk:UISubNewAct18Rk()
	self.uiHeadList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubNewAct18Rk:OnWndClose()
	self:ClearCommonIconList(self.uiHeadList)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubNewAct18Rk:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubNewAct18Rk:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitData()
end

function UISubNewAct18Rk:InitData()
	local cfg = self:GetWndArg("cfg")
	self.cfg = cfg
	self.sid = self:GetWndArg("sid")
	self.rankId = cfg.rankId
	local rankLimitMap = {}
	if cfg then
		local rankLimit = cfg.rankLimit
		local rankTxt = cfg.rankTxt
		if not string.isempty(rankLimit) and not string.isempty(rankTxt) then
			rankLimit = string.split(rankLimit,"|")
			for i,v in ipairs(rankLimit) do
				v = string.split(v,"=")
				rankLimitMap[checknumber(v[1])] = string.replace(rankTxt,checknumber(v[2]))
			end
		end
	end
	self._rankLimitMap = rankLimitMap
	gModelRank:OnRankReq(2, self.rankId, 1, 25, self.sid)
end

function UISubNewAct18Rk:GetEmptyTxt(index,isMe)
	if not isMe then
		local rankLimitMap = self._rankLimitMap
		if rankLimitMap and rankLimitMap[index] then
			return rankLimitMap[index]
		end
	end
	return string.replace("【#a1#】", ccClientText(11707))
end

function UISubNewAct18Rk:SetHeadIcon(trans, data)
	local icon = self:FindWndTrans(trans, "IconBg/Icon")
	local headFrame = self:FindWndTrans(trans, "headFrame")

	if not data or (data._playerId and data._playerId == 0) then
		self:SetWndEasyImage(icon, "icon_role_chat_0")
		CS.ShowObject(headFrame, false)
		return
	end
	local InstanceID = trans:GetInstanceID()

	local playerInfo = {
		trans = trans,
		playerId = data._playerId,
		icon = data._head,
		headFrame = data._headFrame,
		level = data._grade,
	}
	if not self.uiHeadList[InstanceID] then
		self.uiHeadList[InstanceID] = HeadIcon:New(self)
	end
	self.uiHeadList[InstanceID]:SetHeadData(playerInfo)
	self:SetWndClick(trans, function()
		if data and data._playerId ~= 0 then
			gModelGeneral:PlayerShowReq(
				data._playerId,
				LCombatTypeConst.COMBAT_MAIN,
				LPlayerShowConst.OTHER_SYSTEM
			)
		end
	end)
end

function UISubNewAct18Rk:ShowRank()
	local ranks = gModelRank:GetRankListInfo(2, self.rankId)
	local topThree = {}
	local rankList = {}
	local selfInfo = gModelRank:GetMeRank()
	for i, v in ipairs(ranks) do
		v.index = i
		if (v.rank > 3) then
			table.insert(rankList, v)
		elseif (v.rank >= 1 and v.rank <= 3) then
			topThree[v.rank] = v
		end
	end

	for i = 1, 3 do
		if not topThree[i] then
			topThree[i] = {}
			topThree[i].index = i
		end
	end

	for i = 4, 10 do
		if not rankList[i - 3] then
			rankList[i - 3] = {}
			rankList[i - 3].index = i
		end
	end

	for i = 1, 3 do
		self:SetTopThree(self["mRank" .. i], topThree[i])
	end

	if not self.rankList then
		self.rankList = self:GetUIScroll("mRankList")
		self.rankList:Create(self.mRankList, rankList, function(...) self:DrawRank(...) end, UIItemList.SUPER)
	else
		self.rankList:ResetList(rankList)
		self.rankList:DrawAllItems()
	end

	selfInfo.index = selfInfo.rank
	self:SetRankItem(self.mMyRank, selfInfo, true)
end

function UISubNewAct18Rk:SetTopThree(trans, data)
	local spineRoot = self:FindWndTrans(trans, "Spine/SpineRoot")
	local have = self:FindWndTrans(trans, "Have")
	local nameText = self:FindWndTrans(trans, "Have/NameText")
	local guildText = self:FindWndTrans(trans, "Have/GuildText")
	local powerText = self:FindWndTrans(have, "PowerBg/PowerText")
	local no = self:FindWndTrans(trans, "No")

	if data.info then
		self:SetWndText(nameText, data.info._name)
		self:SetWndText(guildText, data.info._guildName)
		self:SetWndText(powerText, LUtil.NumberCoversion(data.score))
		self:SetHeroPaint(trans, data.info)

		CS.ShowObject(no, false)
		CS.ShowObject(have, true)
		CS.ShowObject(spineRoot, true)
	else
		self:SetWndText(no, self:GetEmptyTxt(data.index))
		CS.ShowObject(no, true)
		CS.ShowObject(have, false)
		CS.ShowObject(spineRoot, false)
	end

	self:SetWndClick(trans, function()
		if data.info then
			gModelGeneral:PlayerShowReq(
				data.info._playerId,
				LCombatTypeConst.COMBAT_MAIN,
				LPlayerShowConst.OTHER_SYSTEM
			)
		end
	end)
end

function UISubNewAct18Rk:SetHeroPaint(trans, info)
	local paintTans = self:FindWndTrans(trans, "Spine/SpineRoot")
	local ref = gModelPlayer:GetRoleAdventureImage(info._figure)
	if not ref then return end
	local key = trans.gameObject.name

	local paintFlip = ref.paintFlip2 == 1
	local paintMultiple = ref.paintMultiple2
	local offset = LxDataHelper.ParseVector2(ref.paintPaint2, ',')
	self:CreateWndSpine(paintTans, ref.spine, key, false, function(dpSpine)
		dpSpine:SetScale(paintMultiple)
		dpSpine:SetFlipX(paintFlip)
		local dpTrans = dpSpine:GetDisplayTrans()
		if dpTrans then
			dpTrans.anchorMin = Vector2.New(0.5, 0.5)
			dpTrans.anchorMax = Vector2.New(0.5, 0.5)
			dpTrans.localPosition = offset
		end
	end)
end

function UISubNewAct18Rk:InitEvent()
	self:WndEventRecv(EventNames.RANK_UPDATE_END, function() self:ShowRank() end)
end

function UISubNewAct18Rk:SetRankItem(item, data, isMe)
	local aniRoot = self:FindWndTrans(item, "AniRoot")
	local rankIcon = self:FindWndTrans(aniRoot, "RankIcon")
	local rankObj = self:FindWndTrans(aniRoot, "RankObj")
	local rankText = self:FindWndTrans(aniRoot, "RankObj/RankText")
	local headIcon = self:FindWndTrans(aniRoot, "HeadIcon")
	local have = self:FindWndTrans(aniRoot, "Have")
	local nameText = self:FindWndTrans(aniRoot, "Have/NameText")
	local guildText = self:FindWndTrans(aniRoot, "Have/GuildText")
	local no = self:FindWndTrans(aniRoot, "No")
	local powerBg = self:FindWndTrans(aniRoot, "PowerBg")
	local powerText = self:FindWndTrans(aniRoot, "PowerBg/PowerText")
	local IsMe = self:FindWndTrans(aniRoot, "IsMe")
	local IsMeText = self:FindWndTrans(aniRoot, "IsMe/Text")

	if data.index then
		if isMe then
			CS.ShowObject(rankIcon, data.index <= 3 and data.index > 0)
			CS.ShowObject(rankObj, data.index > 3)
			self:SetWndText(rankText, data.index)
			if data.index <= 3 and data.index > 0 then
				self:SetWndEasyImage(rankIcon, "public_num_" .. data.index)
			end
		else
			self:SetWndText(rankText, data.rank or data.index)
			CS.ShowObject(rankIcon, false)
		end
	else
		CS.ShowObject(rankIcon, false)
		CS.ShowObject(rankObj, false)
	end

	if data.info and data.rank > 0 then
		self:SetWndText(nameText, data.info._name)
		self:SetWndText(guildText, data.info._guildName)
		self:SetWndText(powerText, LUtil.NumberCoversion(data.score))

		CS.ShowObject(no, false)
		CS.ShowObject(have, true)
		CS.ShowObject(powerBg, true)
	else
		self:SetWndText(no, self:GetEmptyTxt(data.index,isMe))
		CS.ShowObject(no, true)
		CS.ShowObject(have, false)
		CS.ShowObject(powerBg, false)
	end

	self:SetHeadIcon(headIcon, data.info)

	CS.ShowObject(IsMe, isMe)
	self:SetWndText(IsMeText, ccClientText(11726))
end

function UISubNewAct18Rk:DrawRank(_, item, data)
	self:SetRankItem(item, data, false)
end



------------------------------------------------------------------
return UISubNewAct18Rk