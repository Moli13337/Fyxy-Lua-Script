---
--- Created by Administrator.关闭
--- DateTime: 2024/11/27 15:38:54
---
------------------------------------------------------------------
local URenderTexture = LxUnity.URenderTexture
local LWnd = LWnd
---@class UIGameBzerDoNew:LWnd
local UIGameBzerDoNew = LxWndClass("UIGameBzerDoNew", LWnd)
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGameBzerDoNew:UIGameBzerDoNew()
	self.rewardIconUIList = {} 
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGameBzerDoNew:OnWndClose()
	if self._sceneCsCamera then 
		local orthgraphicSize,designOrthgraphicSize = LUtil.GetCameraSize()
		self._sceneCsCamera.orthographicSize = orthgraphicSize
	end
	if (self._sceneCsCamera.targetTexture) then
		local rt = self._sceneCsCamera.targetTexture
		rt:Release()
		self._sceneCsCamera.targetTexture = nil
		--LxUnity.Destroy(rt)
		--LRTHelper.ReleaseTemporary(rt)
	end
	local trans =  gLFightIdleManager:GetObjectRootTrans()
	CS.ShowObject(trans,true)
	GF.ChangeMap("LCityMap")
	self._sceneCsCamera = nil
	self.rewardIconUIList = nil
	LxTimer.LoopTimeStop(self.timer)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGameBzerDoNew:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGameBzerDoNew:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	GF.ChangeMap("LFightIdleMap")
	self:InitCommon()
	self:DoMove(true)

	local pb = self:GetWndArg("pb")
	self.dataList = pb.results
	self:UpdateList()
end

function UIGameBzerDoNew:InitCommon()
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
	self.haveReward = {}

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
			if not self.isStop then
				gLFightIdleManager:StartIdleRun()
			else
				gLFightIdleManager:StopIdleRun()
			 end
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
	CS.ShowObject(self.mRoleRoot,false)
	------------------------------------------------------------------
	---resp
	self:WndNetMsgRecv(LProtoIds.GameHelperExecuteResp, function(pb)
		self:UpdateList(pb)
	end)

	------------------------------------------------------------------
	---timer
	self:TimerStart("key", 0.1, false, -1)
end

function UIGameBzerDoNew:DrawRewardIcon(_, item, data)
	local root = self:FindWndTrans(item, "Root")
	local reward = data.serverData
	local instanceId = root:GetInstanceID()
	local commonIcon = self:GetCommonIcon(instanceId)
	commonIcon:Create(root)
	local type = reward.itemType or reward.itype
	local id = reward.itemId or reward.refId
	commonIcon:SetCommonReward(type, id, reward.itemNum)
	commonIcon:DoApply()

	self:SetWndClick(root, function()
		gModelGeneral:ShowCommonItemTipWnd(reward)
	end)
end

function UIGameBzerDoNew:UpdateList(pb)
	local movePos
	local getReward
	if pb then
		local pbFirstResult = pb.results[1]
		for i = #self.dataList, 1, -1 do--新数据替换
			if pbFirstResult and self.dataList[i].refId == pbFirstResult.refId then
				local funcRef = GameTable.AssistantFunctionRef[pbFirstResult.refId]
				if funcRef.tabId == 109 then --pb.results[1].refId == 109
					if not self.dataList[i].fightReports[1] then
						self.dataList[i] = pbFirstResult
						movePos = i
					else
						table.insert(self.dataList, i + 1, pbFirstResult)
						movePos = i + 1
					end
				else
					self.dataList[i] = pbFirstResult
					movePos = i
				end
				self.curId = pbFirstResult.refId
				break
			end
		end
		if pbFirstResult then
			local funcRef = GameTable.AssistantFunctionRef[pbFirstResult.refId]
			if funcRef.tabId == 107 then --pb.results[1].refId == 107
				self.finishList[pbFirstResult.refId] = pbFirstResult
				-- getReward = true
			else
				if pbFirstResult.state == 2 then--单个完成状态记录- 1=进行中 2=已完成
					self.finishList[pbFirstResult.refId] = pbFirstResult
					-- getReward = true
				end
			end
			local rewardInfo = gModelGeneral:GetThingsDetailInfoByPb(pbFirstResult.reward)--执行获得的奖励
			local rewardNum = rewardInfo:GetThingsDetailRewardNum()
			getReward = rewardNum > 0
			if getReward then self.haveReward[pbFirstResult.refId] = rewardNum end
		end
		if pb.executeState == 2 then--全部完成
			self.isFinish = true
			local str = ccClientText(36401)--#self.haveReward>0 and ccClientText(12207) or ccClientText(24273)
			self:SetWndButtonText(self.mBtn, str)
			-- CS.ShowObject(self.mFinish, true)
			CS.ShowObject(self.mRoleRoot,true)
			local trans =  gLFightIdleManager:GetObjectRootTrans()
			CS.ShowObject(trans,false)
			gLFightIdleManager:StopIdleRun()
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
	if self.curId ~= 0 then--当前执行提示气泡语
		local funcRef = GameTable.AssistantFunctionRef[self.curId]
		local cfg = GameTable.AssistantListRef[funcRef.tabId]
		-- self:SetWndText(self.mTips,string.replace(ccClientText(24277),ccLngText(cfg.name),ccLngText(funcRef.name)))
		local tipStr = string.replace(ccClientText(24277),ccLngText(cfg.name),ccLngText(funcRef.name))
		self:SetWndText(self.mExcuteTips,(pb and pb.executeState == 2) and ccClientText(24251) or tipStr )
		-- self:SetWndText(self.mTips, ccLngText(cfg.text))
		-- self.curIndex = self.curIndex + 1
	end
	local list = self.dataList
	for i, v in ipairs(list) do--根据数据创建条目
		local itemName = "item" .. i
		local item = CS.FindTrans(self.mContent, itemName)
		if not item then
			local gameObj = LxUnity.InstantObject(self.mItemTemplate.gameObject)
			gameObj.name = itemName
			item = gameObj.transform
			LxUnity.SetParentTrans(item, self.mContent)
			CS.ShowObject(item, true)
		end
		self:DrawList(nil, item, v, i)--初始化条目数据
	end
	if movePos then
		local pos = 150 * (movePos - 1)
		local hight = self.mContent.rect.height
		if hight <= 280 then
			pos = 0
		else
			pos = math.min(pos, (hight - 280))
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
	if pb and pb.executeState == 2 then
		self:CannotExecuteTime(pb.results)
	end
end
function UIGameBzerDoNew:DrawList(_, trans, data, pos)
	local yes = CS.FindTrans(trans, "Yes")
	local no = CS.FindTrans(trans, "No")
	local name = CS.FindTrans(trans, "Name")
	local type1 = CS.FindTrans(trans, "Type1")
	local type2 = CS.FindTrans(trans, "Type2")
	local proText = CS.FindTrans(type2, "ProText")
	local ok = CS.FindTrans(type2, "Ok")
	local uiRewardList = CS.FindTrans(trans, "Type2/RewardList")
	local uiRewardTip = CS.FindTrans(trans, "Type2/RewardTip")

	local cfg = GameTable.AssistantFunctionRef[data.refId] --GameTable.AssistantListRef[data.refId]
	self:SetWndText(name, ccLngText(cfg.executeName))
	self:SetTextTile(name, ccLngText(cfg.titleDescription))

	local isOk = self.finishList[data.refId] ~= nil
	local isType1 = self.useType1[cfg.tabId]--data.refId  vs
	if isType1 then
		self:SetType1(type1, data)--vs
	end
	if isOk and not self.doTimeList[data.refId] then
		self.doTimeList[data.refId] = 0
	end
	self.transList[pos] = {
		refId = data.refId,
		listRefId = cfg.tabId,
		proText = proText,
		ok = ok,
		yes = yes,
		no = no,
		uiRewardList = uiRewardList,
		uiRewardTip = uiRewardTip,
		data = data,
	}
	local ShowType2 = true
	if isType1 and data.state == 2 then
		ShowType2 = false
	end
	CS.ShowObject(type2, ShowType2)--进度
	CS.ShowObject(type1, isType1 and not ShowType2)--vs
	if isOk and self.haveReward[data.refId] then self:SetItem(trans,self.finishList[data.refId]) end
end

function UIGameBzerDoNew:DoMove(b)
	if b then
		-- local indx = 0
		-- self.timer = LxTimer.LoopTimeCall(function()
		-- 	local movePos = Vector3.New(5, 0, 0)
		-- 	indx = indx+1
		-- 	if indx >10 then return end
		-- 	for i = 1, 2 do
		-- 		local trans = self["mBg" .. i]
		-- 		local pos = trans.localPosition
		-- 		local endPos = pos - movePos
		-- 		if endPos.x <= -568 then
		-- 			local ortherTrans = i == 1 and self["mBg" .. 2] or self["mBg" .. 1]
		-- 			local addPos = i == 1 and Vector3.New(568 - 5, 0, 0) or Vector3.New(568, 0, 0)
		-- 			endPos = ortherTrans.localPosition + addPos
		-- 		end
		-- 		trans.localPosition = endPos
		-- 	end
		-- end, 0.01, true, -1)
		-- if self.lUIHeroObject then
		-- 	self.lUIHeroObject:PlayAni("run", true)
		-- end
        local rt = URenderTexture.New(546,310,16)
        rt.name = "DynamicRT"
        -- 绑定到相机
		self._sceneCsCamera = gLGameScene:GetCurrentSceneCamera()
        self._sceneCsCamera.targetTexture = rt
		self.mRImgBg.texture = self._sceneCsCamera.targetTexture
		self._sceneCsCamera.orthographicSize = 1.9

	else
		LxTimer.LoopTimeStop(self.timer)
		if self.lUIHeroObject then
			self.lUIHeroObject:PlayIdleAni()
		end
	end
end

function UIGameBzerDoNew:OnTimer(key)
	if key == "key" then
		for _, v in pairs(self.transList) do--完成的做滚动效果
			local times = self.doTimeList[v.refId]
			local showOk, showYes, showNo = false, false, false
			if times then
				local str = string.replace(ccClientText(24252, self.doTimeList[v.refId]))
				if v.listRefId == 107 then--v.refId == 108
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
				if v.listRefId == 107 then--if这段逻辑应该是多余的
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
			local rwdNum = self.haveReward[v.refId]
			-- CS.ShowObject(v.ok, showOk)
			CS.ShowObject(v.yes, showYes)
			CS.ShowObject(v.no, showNo)
			CS.ShowObject(v.proText, not showOk)
			CS.ShowObject(v.uiRewardList,showOk and rwdNum)
			CS.ShowObject(v.uiRewardTip,showOk and rwdNum and rwdNum>4)

			if showOk and not self.haveReward[v.refId] then
				CS.ShowObject(v.proText, true)
				local error = v.data.error
				if error.code ~= 0 then
					self:SetWndText(v.proText, gModelGameHelper:GetGameHelperErrorStr(error))
				else
					--[[					local funcRef = GameTable.AssistantFunctionRef[v.refId]
                                        self:SetWndText(v.proText, ccLngText(funcRef.desd1))--未执行描述]]

					--- 默认是成功，其他由服务端返回错误码
					self:SetWndText(v.proText, ccClientText(36409))
				end
			end
		end
	end
end
function UIGameBzerDoNew:CannotExecuteTime(results)
	local result
	for index, value in ipairs(self.dataList) do
		if not self.finishList[value.refId] then
			self.doTimeList[value.refId] = 100
		end
		result = results[index]
		if result and self.transList[index] then
			if self.transList[index].refId == result.refId then
				self.transList[index].data = result
			end
		end
	end

	return true
end

function UIGameBzerDoNew:SetHeadIcon(trans, data)
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

function UIGameBzerDoNew:SetItem(trans, data)
	local uiRewardList = CS.FindTrans(trans, "Type2/RewardList")
	local RewardTip = CS.FindTrans(trans, "Type2/RewardTip")
	local RewardMulti = CS.FindTrans(trans, "Type2/RewardTip/RewardMulti")
	data = self.finishList[data.refId]--功能数据
	local rewardInfo = gModelGeneral:GetThingsDetailInfoByPb(data.reward)
	local rewardList = rewardInfo:GetThingsDetailAllRewardList()
	self:SetWndText(RewardMulti,"...")
	self:SetWndText(RewardTip,ccClientText(42004))
	-- if rewardNum == 0 then
	-- 	if data.error.code ~= 0 then
	-- 		self:SetWndText(no, ccServerText(data.error.code))
	-- 	else
	-- 		self:SetWndText(no, ccLngText(cfg.desd2))--未执行描述
	-- 	end
	-- end

	uiRewardList.sizeDelta = Vector2.New(math.min(#rewardList * 70, 290), 70)
	local InstanceID = trans:GetInstanceID()
	if self.rewardIconUIList[InstanceID] then
		self.rewardIconUIList[InstanceID]:RefreshList(rewardList)
		self.rewardIconUIList[InstanceID]:DrawAllItems()
	else
		self.rewardIconUIList[InstanceID] = self:GetUIScroll("rewardIconUIList" .. InstanceID)
		self.rewardIconUIList[InstanceID]:Create(uiRewardList, rewardList, function(...) self:DrawRewardIcon(...) end, UIItemList.SUPER_GRID)
	end
	local rewardNum = self.haveReward[data.refId]
	if rewardNum and rewardNum>3 then
		self:SetWndClick(RewardTip,function()
			local itemList = {}
			for _, data in ipairs(rewardList) do
				data.serverData.count = tonumber(data.serverData.itemNum)
				table.insert(itemList,data.serverData)
			end
			gModelWndPop:TryOpenPopWnd("UIAward", {
				itemList = itemList
			})
		end)
	end
end

function UIGameBzerDoNew:SetType1(trans, data)
	local headIcon1 = CS.FindTrans(trans, "Head1/HeadIcon")
	local headIcon2 = CS.FindTrans(trans, "Head2/HeadIcon")
	local vs = CS.FindTrans(trans, "Image")
	local win = CS.FindTrans(trans, "Win")
	local winImage = CS.FindTrans(win, "Image")
	local lose = CS.FindTrans(trans, "Lose")
	local loseImage = CS.FindTrans(lose, "Image")
	self:SetWndEasyImage(winImage,"settlement_txt_2",nil,true)
	self:SetWndEasyImage(loseImage,"settlement_txt_3",nil,true)
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

function UIGameBzerDoNew:ClickClose()
	if not self.isFinish and not self.isStop then
		gModelGameHelper:GameHelperStopExecuteReq(1)
	end
	gModelGameHelper:GameHelperSettingReq(1)--请求最新数据
	self:WndClose()
end


------------------------------------------------------------------
return UIGameBzerDoNew