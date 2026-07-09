---
--- Created by Administrator.
--- DateTime: 2024/11/27 15:38:54
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGameHelperDo:LWnd
local UIGameHelperDo = LxWndClass("UIGameHelperDo", LWnd)
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGameHelperDo:UIGameHelperDo()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGameHelperDo:OnWndClose()
	LxTimer.LoopTimeStop(self.timer)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGameHelperDo:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGameHelperDo:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitCommon()
	self:DoMove(true)

	local pb = self:GetWndArg("pb")
	self.dataList = pb.results
	self:UpdateList()
end

function UIGameHelperDo:DrawList(_, trans, data, pos)
	local yes = CS.FindTrans(trans, "Yes")
	local no = CS.FindTrans(trans, "No")
	local name = CS.FindTrans(trans, "Name")
	local type1 = CS.FindTrans(trans, "Type1")
	local type2 = CS.FindTrans(trans, "Type2")
	local proText = CS.FindTrans(type2, "ProText")
	local ok = CS.FindTrans(type2, "Ok")

	local cfg = GameTable.AssistantListRef[data.refId]
	self:SetWndText(name, ccLngText(cfg.name))

	local isOk = self.finishList[data.refId] ~= nil
	local isType1 = self.useType1[data.refId]
	if isType1 then
		self:SetType1(type1, data)
	else
		-- self:SetType2(type2, data, isOk)
	end
	if isOk and not self.doTimeList[data.refId] then
		self.doTimeList[data.refId] = 0
	end
	self.transList[pos] = {
		refId = data.refId,
		proText = proText,
		ok = ok,
		yes = yes,
		no = no,
		data = data
	}

	-- CS.ShowObject(yes, isOk)
	-- CS.ShowObject(no, not isOk)
	CS.ShowObject(type1, isType1)
	CS.ShowObject(type2, not isType1)
end

function UIGameHelperDo:UpdateList(pb)
	local movePos
	local getReward
	if pb then
		for i = #self.dataList, 1, -1 do
			if pb.results[1] and self.dataList[i].refId == pb.results[1].refId then
				if pb.results[1].refId == 109 then
					if not self.dataList[i].fightReports[1] then
						self.dataList[i] = pb.results[1]
						movePos = i
					else
						table.insert(self.dataList, i + 1, pb.results[1])
						movePos = i + 1
					end
				else
					self.dataList[i] = pb.results[1]
					movePos = i
				end
				self.curId = pb.results[1].refId
				break
			end
		end
		if pb.results[1] then
			if pb.results[1].refId == 108 then
				self.finishList[pb.results[1].refId] = pb.results[1]
				-- getReward = true
			else
				if pb.results[1].state == 2 then
					self.finishList[pb.results[1].refId] = pb.results[1]
					-- getReward = true
				end
			end
			local rewardInfo = gModelGeneral:GetThingsDetailInfoByPb(pb.results[1].reward)
			local rewardNum = rewardInfo:GetThingsDetailRewardNum()
			getReward = rewardNum > 0
			if not self.haveReward then
				self.haveReward = rewardNum > 0
			end
		end
		if pb.executeState == 2 then
			self.isFinish = true
			local str = self.haveReward and ccClientText(12207) or ccClientText(24273)
			self:SetWndButtonText(self.mBtn, str)
			CS.ShowObject(self.mFinish, true)
			self:DoMove(false)
		end
	else
		self.curId = self.dataList[1].refId
	end
	if getReward then
		if self.eff then
			self.eff:SetVisible(false)
			self.eff:SetVisible(true)
		else
			self.eff = self:CreateWndEffect(self.mEffRoot, "fx_ui_jianfuzhixing", "bg", 100)
		end
	end
	-- if self.dataList[self.curIndex] then
	if self.curId ~= 0 then
		local cfg = GameTable.AssistantListRef[self.curId]
		self:SetWndText(self.mTips, ccLngText(cfg.text))
		-- self.curIndex = self.curIndex + 1
	end
	local list = self.dataList
	for i, v in ipairs(list) do
		local itemName = "item" .. i
		local item = CS.FindTrans(self.mContent, itemName)
		if not item then
			local gameObj = LxUnity.InstantObject(self.mItemTemplate.gameObject)
			gameObj.name = itemName
			item = gameObj.transform
			LxUnity.SetParentTrans(item, self.mContent)
			CS.ShowObject(item, true)
		end
		self:DrawList(nil, item, v, i)
	end
	if movePos then
		local pos = 150 * (movePos - 1)
		local hight = self.mContent.rect.height
		if hight <= 533 then
			pos = 0
		else
			pos = math.min(pos, (hight - 533))
		end
		if not self.seqCom then
			self.seqCom = SequenceCom:New()
		end
		local seq = self.seqCom:CreateSeq("listMove")
		local pos = Vector2.New(0, pos)
		local speed = 0.5
		local downTweener = self.mContent:DOLocalMove(pos, speed):SetEase(DG.Tweening.Ease.Linear)
		seq:Insert(0, downTweener)
		seq:PlayForward()
	end
end

function UIGameHelperDo:ClickClose()
	if not self.isFinish and not self.isStop then
		gModelGameHelper:GameHelperStopExecuteReq(1)
	end
	local list = {}
	for _, v in pairs(self.finishList) do
		table.insert(list, v)
	end
	table.sort(list, function(a, b)
		return a.refId < b.refId
	end)
	if #list > 0 then
		GF.OpenWnd("UIGameHelperReward", { list = list })
	end
	self:WndClose()
end

function UIGameHelperDo:OnTimer(key)
	if key == "key" then
		for _, v in pairs(self.transList) do
			local times = self.doTimeList[v.refId]
			local showOk, showYes, showNo = false, false, false
			if times then
				local str = string.replace(ccClientText(24252, self.doTimeList[v.refId]))
				if v.refId == 108 then
					local moreInfo = v.data.moreInfos
					if not string.isempty(moreInfo) then
						local data = string.split(moreInfo, "=")
						local name = ccLngText(GameTable.SnakeTowerPatternRef[tonumber(data[1])].name)
						str = string.replace(ccClientText(24253), name, data[2])
					end
					showOk, showYes, showNo = v.data.state == 2, v.data.state == 2, v.data.state ~= 2
				else
					if times >= 100 then
						showOk, showYes, showNo = true, true, false
					else
						self.doTimeList[v.refId] = times + 10
						showOk, showYes, showNo = false, false, true
					end
				end
				self:SetWndText(v.proText, str)
			else
				local str = string.replace(ccClientText(24252, 0))
				if v.refId == 108 then
					local moreInfo = v.data.moreInfos
					if not string.isempty(moreInfo) then
						local data = string.split(moreInfo, "=")
						local name = ccLngText(GameTable.SnakeTowerPatternRef[tonumber(data[1])])
						str = string.replace(ccClientText(24253), name, data[2])
					end
				end
				self:SetWndText(v.proText, str)
				showOk, showYes, showNo = false, false, true
			end
			CS.ShowObject(v.ok, showOk)
			CS.ShowObject(v.yes, showYes)
			CS.ShowObject(v.no, showNo)
		end
	end
end

function UIGameHelperDo:SetType1(trans, data)
	local headIcon1 = CS.FindTrans(trans, "Head1/HeadIcon")
	local headIcon2 = CS.FindTrans(trans, "Head2/HeadIcon")
	local vs = CS.FindTrans(trans, "Image")
	local win = CS.FindTrans(trans, "Win")
	local lose = CS.FindTrans(trans, "Lose")

	if not data.fightReports or not data.fightReports[1] then
		CS.ShowObject(headIcon1, false)
		CS.ShowObject(headIcon2, false)
		CS.ShowObject(vs, false)
		CS.ShowObject(win, false)
		CS.ShowObject(lose, false)
		return
	end

	local data1 = {
		playerId = gModelPlayer:GetPlayerId(),
		icon = gModelPlayer:GetPlayerHead(),
		headFrame = gModelPlayer:GetPlayerHeadFrame(),
		level = gModelPlayer:GetPlayerLv(),
		id = gModelPlayer:GetPlayerId(),
	}
	self:SetHeadIcon(headIcon1, data1)
	local data2 = {
		playerId = data.fightReports[1].playerId,
		icon = data.fightReports[1].head,
		headFrame = data.fightReports[1].headFrame,
		level = data.fightReports[1].playerLvl,
		id = data.fightReports[1].playerId,
	}
	self:SetHeadIcon(headIcon2, data2)

	local isWin = data.fightReports[1].win == 1
	CS.ShowObject(win, isWin)
	CS.ShowObject(lose, not isWin)
	CS.ShowObject(vs, true)
end

function UIGameHelperDo:SetType2(trans, data, isOk)
	local ok = CS.FindTrans(trans, "Ok")
	local ProText = CS.FindTrans(trans, "ProText")

	local str = isOk and ccClientText(24251) or ccClientText(24252)
	if data.refId == 108 then
		str = isOk and ccClientText(24251) or ccClientText(24253) .. data.moreInfos
	end
	self:SetWndText(ProText, str)
	CS.ShowObject(ok, isOk)
end

function UIGameHelperDo:InitCommon()
	------------------------------------------------------------------
	---member
	self.isStop = false
	self.finishList = {}
	-- self.curIndex = 1
	self.curId = 0
	self.useType1 = {
		[109] = true,
	}
	self.transList = {}
	self.doTimeList = {}
	self.haveReward = false

	------------------------------------------------------------------
	---text
	self:SetWndText(self.mLblBiaoti, ccClientText(24247))
	self:SetWndButtonText(self.mBtn, self.isStop and ccClientText(24248) or ccClientText(24249))

	------------------------------------------------------------------
	---click
	self:SetWndClick(self.mBtnClose, function()
		self:ClickClose()
	end)
	self:SetWndClick(self.mMask, function()
		self:ClickClose()
	end)
	self:SetWndClick(self.mBtn, function()
		if self.isFinish then
			self:ClickClose()
		else
			self.isStop = not self.isStop
			self:DoMove(not self.isStop)
			self:SetWndButtonText(self.mBtn, self.isStop and ccClientText(24248) or ccClientText(24249))
			gModelGameHelper:GameHelperStopExecuteReq(self.isStop and 1 or 2)
		end
	end)

	------------------------------------------------------------------
	---spine
	self.lUIHeroObject = LUIHeroObject:New(self)
	local figure = gModelPlayer:GetPlayerFigure()
	local cfg = gModelPlayer:GetRoleAdventureImage(figure)
	self.lUIHeroObject:Create(self.mRoot, "spine", cfg.spine)
	self.lUIHeroObject:SetLoadedFunction(function()
		self.lUIHeroObject:PlayAni("run", true)
	end)
	self.lUIHeroObject:StartLoad()

	------------------------------------------------------------------
	---resp
	self:WndNetMsgRecv(LProtoIds.GameHelperExecuteResp, function(pb)
		self:UpdateList(pb)
	end)

	------------------------------------------------------------------
	---timer
	self:TimerStart("key", 0.1, false, -1)
end

function UIGameHelperDo:DoMove(b)
	if b then
		self.timer = LxTimer.LoopTimeCall(function()
			local movePos = Vector3.New(5, 0, 0)
			for i = 1, 2 do
				local trans = self["mBg" .. i]
				local pos = trans.localPosition
				local endPos = pos - movePos
				if endPos.x <= -568 then
					local ortherTrans = i == 1 and self["mBg" .. 2] or self["mBg" .. 1]
					local addPos = i == 1 and Vector3.New(568 - 5, 0, 0) or Vector3.New(568, 0, 0)
					endPos = ortherTrans.localPosition + addPos
				end
				trans.localPosition = endPos
			end
		end, 0.01, true, -1)
		if self.lUIHeroObject then
			self.lUIHeroObject:PlayAni("run", true)
		end
	else
		LxTimer.LoopTimeStop(self.timer)
		if self.lUIHeroObject then
			self.lUIHeroObject:PlayIdleAni()
		end
	end
end

function UIGameHelperDo:SetHeadIcon(trans, data)
	local instanceId = trans:GetInstanceID()
	local playerInfo = {
		trans = trans,
		playerId = data.playerId,
		icon = data.icon,
		headFrame = data.headFrame,
		level = data.level,
	}
	local headIconCls = self:GetHeadIcon(instanceId)
	headIconCls:SetHeadData(playerInfo)
	CS.ShowObject(trans, true)

	self:SetWndClick(trans, function()
		gModelGeneral:PlayerShowReq(data.playerId, LCombatTypeConst.COMBAT_MAIN, LPlayerShowConst.OTHER_SYSTEM)
	end)
end


------------------------------------------------------------------
return UIGameHelperDo