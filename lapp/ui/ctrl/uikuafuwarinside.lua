---
--- Created by Administrator.
--- DateTime: 2024/6/12 16:11:17
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIKuafuWarInside:LWnd
local UIKuafuWarInside = LxWndClass("UIKuafuWarInside", LWnd)
local seasonOpenTimeS = GameTable.BattleTempleConfigRef.seasonOpenTime
local seasonOpenTime = string.split(seasonOpenTimeS, ",")
local openWeek = tonumber(seasonOpenTime[1])
local openHour = tonumber(seasonOpenTime[2])
local openTick = openHour * 60 * 60
local seasonEndTimeS = GameTable.BattleTempleConfigRef.seasonEndTime
local seasonEndTime = string.split(seasonEndTimeS, ",")
local endHour = tonumber(seasonEndTime[2])
local endTick = endHour * 60 * 60
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIKuafuWarInside:UIKuafuWarInside()
	self.needItemList = {
		{
			itemType = 1,
			itemId = 112009
		},
		{
			itemType = 1,
			itemId = 112010
		}
	}
	self.itemList = {}
	self.getItem = {}
	self.spineData = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIKuafuWarInside:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIKuafuWarInside:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIKuafuWarInside:OnStart()
	LWnd.OnStart(self)
	self:InitUI()


	self._isVie = gLGameLanguage:IsVieVersion()
	self:InitEvent()
	self:InitText()
	self:InitEff()
	self:InitNeedItem()
	self:UpdateRedPoint()
	self:UpdateCanvas()

	gModelCrossWar:CrossWarTempleInfoReq()
end

function UIKuafuWarInside:UpdateCanvas()
	local typeofCanvas = typeof(UnityEngine.Canvas)
	local wndSortOrder = self:GetWndSortOrder()
	local tran = CS.FindTrans(self.mMasterObj, "Bg")
    local canvas = tran:GetComponent(typeofCanvas)
    canvas.sortingOrder = wndSortOrder + 1
	tran = CS.FindTrans(self.mMasterObj, "Obj")
	canvas = tran:GetComponent(typeofCanvas)
    canvas.sortingOrder = wndSortOrder + 2
end

function UIKuafuWarInside:DrawRetinue(_, item, data, pos)
	local spine = self:FindWndTrans(item, "Spine")
	local add = self:FindWndTrans(item, "Add")
	local text = self:FindWndTrans(item, "Text")
	local timeText = self:FindWndTrans(item, "TimeText")
	local me = self:FindWndTrans(item, "Me")

	local isMe = false
	if data.playerInfo then
		self:SetWndText(text, "[" .. data.playerInfo._serverName .. "]" .. data.playerInfo._name)
		isMe = data.playerInfo._playerId == gModelPlayer:GetPlayerId()
		local ref = gModelPlayer:GetRoleAdventureImage(data.playerInfo._figure)
		local key = item:GetInstanceID()
		if ref then
			if self.spineData[key] ~= ref.spine then
				self:DestroyWndSpineByKey(key)
				self.spineData[key] = ref.spine
				self:CreateWndSpine(spine, ref.spine, key, false)
			end
		end
	end

	self.itemList["1_" .. pos] = {item = item, data = data}
	local endTime = data.endTime or 0
	local leftTime = endTime - GetTimestamp()
	if leftTime > 0 then
		self:SetTimeText(item, leftTime)
		CS.ShowObject(timeText, true)
	else
		CS.ShowObject(timeText, false)
	end

	CS.ShowObject(me, isMe)
	CS.ShowObject(spine, data.playerInfo ~= nil)
	CS.ShowObject(text, data.playerInfo ~= nil)
	CS.ShowObject(timeText, data.playerInfo ~= nil)
	CS.ShowObject(add, data.playerInfo == nil)

	self:SetWndClick(item, function()
		if data.playerInfo then
			gModelGeneral:PlayerShowReq(data.playerInfo._playerId, LCombatTypeConst.COMBAT_MAIN, LPlayerShowConst.OTHER_SYSTEM)
		end
	end)
end

function UIKuafuWarInside:OnDrawNeedItemCell(_, item, data)
	local IconTrans = self:FindWndTrans(item, "Icon")
	local NumTrans = self:FindWndTrans(item, "Num")
	local AddBtnTrans = self:FindWndTrans(item, "BtnDiv/AddBtn")
	local refId = data.itemId
	if IconTrans then
		local icon = gModelItem:GetItemIconByRefId(refId)
		self:SetWndEasyImage(IconTrans, icon)
	end
	if NumTrans then
		local haveNum = gModelItem:GetNumByRefId(refId)
		haveNum = LUtil.NumberCoversion(haveNum)
		self:SetWndText(NumTrans, haveNum)
	end
	if AddBtnTrans then
		self:SetWndClick(AddBtnTrans, function()
			gModelGeneral:OpenGetWayWnd({ itemId = refId, srcWnd = self:GetWndName() })
		end)
	end
end

function UIKuafuWarInside:DrawFollow(_, item, data, pos)
	local timeImage = self:FindWndTrans(item, "Image")
	local headIcon = self:FindWndTrans(item, "HeadIcon")
	local add = self:FindWndTrans(item, "Add")
	local serverText = self:FindWndTrans(item, "ServerText")
	local nameText = self:FindWndTrans(item, "NameText")
	local timeText = self:FindWndTrans(item, "TimeText")
	local me = self:FindWndTrans(item, "Me")

	local isMe = false
	if data.playerInfo then
		self:SetWndText(serverText, data.playerInfo._serverName)
		self:SetWndText(nameText, data.playerInfo._name)
		isMe = data.playerInfo._playerId == gModelPlayer:GetPlayerId()

		local instanceId = item:GetInstanceID()
		local baseClass = self:GetHeadIcon(instanceId)
		local playerData =
		{
			trans = headIcon,
			icon = data.playerInfo._head,
			headFrame = data.playerInfo._headFrame,
			level = data.playerInfo._grade,
		}
		baseClass:SetHeadData(playerData)
		baseClass:RefreshUI()

		self:SetWndClick(headIcon, function()
			gModelGeneral:PlayerShowReq(data.playerInfo._playerId, LCombatTypeConst.COMBAT_MAIN, LPlayerShowConst.OTHER_SYSTEM)
		end)
	end

	self.itemList["2_" .. pos] = {item = item, data = data}
	local endTime = data.endTime or 0
	local leftTime = endTime - GetTimestamp()
	if leftTime > 0 then
		self:SetTimeText(item, leftTime)
		CS.ShowObject(timeText, true)
	else
		CS.ShowObject(timeText, false)
	end

	CS.ShowObject(me, isMe)
	CS.ShowObject(timeImage, data.playerInfo ~= nil)
	CS.ShowObject(headIcon, data.playerInfo ~= nil)
	CS.ShowObject(serverText, data.playerInfo ~= nil)
	CS.ShowObject(nameText, data.playerInfo ~= nil)
	CS.ShowObject(timeText, data.playerInfo ~= nil)
	CS.ShowObject(add, data.playerInfo == nil)
end

function UIKuafuWarInside:UpdateRedPoint()
	local isClick = gModelRedPoint:CheckRankRedClicked(13900050)
	self:FindWndTrans(self.mApprovalBtn, "redPoint")
	CS.ShowObject(isClick, false)
end

function UIKuafuWarInside:InitEvent()
	self:SetWndClick(self.mCloseBtn, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mHelpBtn, function()
		GF.OpenWnd("UIBzTips", { refId = 174 })
	end)
	self:SetWndClick(self.mApplyBtn, function()
		self:ClickApplyBtn()
	end)
	self:SetWndClick(self.mCancelBtn, function()
		self:ClickCancelBtn()
	end)
	self:SetWndClick(self.mApprovalBtn, function()
		GF.OpenWnd("UIKuafuWarApproval")
	end)
	self:SetWndClick(self.mRecruitBtn, function()
		self:ClickRecruitBtn()
	end)
	self:SetWndClick(self.mSettingBtn, function()
		GF.OpenWnd("UIKuafuWarSetting")
	end)

	self:WndEventRecv("CrossWarTempleInfoResp", function()
		self:OnUpdate()
	end)
end

function UIKuafuWarInside:InitEff()
	self:CreateWndEffect(CS.FindTrans(self.mMasterObj, "Bg"), "fx_ui_nszz_biankuangliuguang", "mMasterObj", 100, nil, nil, nil, nil, nil, nil, nil,
		function(dpTrans)
			dpTrans.localPosition = Vector2.New(-2.6, -6.9)
		end
	)
	self:CreateWndEffect(self.mTopBg, "fx_ui_nszz_yunwugundong", "mTopBg", 100, nil, nil, nil, nil, nil, nil, nil,
		function(dpTrans)
			dpTrans.localPosition = Vector2.New(0, -195)
		end
	)
end

function UIKuafuWarInside:SetTotalReward(text, reward)
	if not self.insideInfo then
		return
	end
	if self.roleType == 1 then
		local unitNum = reward.count + (reward.count * gModelCrossWar:GetVipAdd())
		local nowTime = GetTimestamp()
		local nowWeek = tonumber(os.date("%w", nowTime))
		nowWeek = nowWeek == 0 and 8 or nowWeek
		local nowH = tonumber(os.date("%H", nowTime))
		local nowM = tonumber(os.date("%M", nowTime))
		local nowS = tonumber(os.date("%S", nowTime))
		local nowTick = (nowH * 60 * 60) + (nowM * 60) + nowS
		if nowWeek == openWeek and nowTick < endTick then
			local totalTime = (nowTick - openTick) / 60
			local totalNum = math.floor(unitNum * math.floor(totalTime))
			totalNum = math.max(totalNum, 0)
			self:SetWndText(text, ccClientText(43810) .. totalNum)
		else
			local totalTime
			if endTick < nowTick then
				totalTime = nowTick - endTick
			else
				totalTime = 86400 - endTick + nowTick
			end
			totalTime = totalTime / 60
			local totalNum = math.floor(unitNum * math.floor(totalTime))
			totalNum = math.max(totalNum, 0)
			self:SetWndText(text, ccClientText(43810) .. totalNum)
		end
	else
		local unitNum = reward.count + (reward.count * gModelCrossWar:GetVipAdd())
		local allTiem = gModelCrossWar:GetAllFowOrRetTime()
		local leftTime = gModelCrossWar:GetFowOrRetEndTime() - GetTimestamp()
		local totalTime = leftTime > 0 and (allTiem * 60 - leftTime) / 60 or allTiem
		local totalNum = math.floor(unitNum * math.floor(totalTime))
		totalNum = math.max(totalNum, 0)
		self:SetWndText(text, ccClientText(43810) .. totalNum)
	end
end

function UIKuafuWarInside:ShowBtn()
	if not self.insideInfo then
		return
	end
	CS.ShowObject(self.mApprovalBtn, self.roleType == 1)
	CS.ShowObject(self.mRecruitBtn, self.roleType == 1)
	CS.ShowObject(self.mSettingBtn, self.roleType == 1)
	CS.ShowObject(self.mApplyBtn, self.roleType == 3)
	CS.ShowObject(self.mCancelBtn, self.roleType ~= 1)
	local str = self.roleType == 3 and ccClientText(43808) or ccClientText(43809)
	self:SetWndText(self:FindWndTrans(self.mCancelBtn, "Text"), str)
end

function UIKuafuWarInside:OnUpdate()
	self:TimerStop("itemRunTime")
	self:TimerStart("itemRunTime", 1, false, -1)

	self.insideInfo = gModelCrossWar:GetInnerTempleInfo()
	self.roleType = gModelCrossWar:GetSelfInsideInfo().roleType or 0
	self:ShowBtn()
	self:SetGetInfo()
	self:SetMaster()
	self:SetRetinueList()
	self:SetFollowList()
end

function UIKuafuWarInside:InitText()
	self:SetWndText(self.mTitleText, ccClientText(43803))
	self:SetWndText(self.mGetTitle, ccClientText(43852))
	self:SetWndText(self:FindWndTrans(self.mCloseBtn, "Text"), ccClientText(30205))
	self:SetWndText(self:FindWndTrans(self.mApplyBtn, "Text"), ccClientText(43804))
	self:SetWndText(self:FindWndTrans(self.mApprovalBtn, "Text"), ccClientText(43805))
	self:SetWndText(self:FindWndTrans(self.mRecruitBtn, "Text"), ccClientText(43806))
	self:SetWndText(self:FindWndTrans(self.mSettingBtn, "Text"), ccClientText(43807))
	if self._isVie then
		self:SetAnchorPos(self.mHelpBtn,Vector2.New(120,0))
		self:InitTextCharacterWithLanguage(self.mTitleText,-5)
	end
end

function UIKuafuWarInside:SetMaster()
	if not self.insideInfo then
		return
	end
	local masterInfo = self.insideInfo.playerInfoList[1][1]
	local spine = self:FindWndTrans(self.mMasterObj, "Obj/Spine")
	local serverText = self:FindWndTrans(self.mMasterObj, "Obj/ServerText")
	local nameText = self:FindWndTrans(self.mMasterObj, "Obj/NameText")
	local powerText = self:FindWndTrans(self.mMasterObj, "Obj/PowerBg/PowerText")


	if not spine then
		--如果为空 那么去以前的部分寻找
		 spine = self:FindWndTrans(self.mMasterObj, "Obj/Spine")
		 serverText = self:FindWndTrans(self.mMasterObj, "Obj/ServerText")
		 nameText = self:FindWndTrans(self.mMasterObj, "Obj/NameText")
		 powerText = self:FindWndTrans(self.mMasterObj, "Obj/PowerBg/PowerText")
	end

	local ref = gModelPlayer:GetRoleAdventureImage(masterInfo.playerInfo._figure)
	if ref then
		if self.spineData["masterSpine"] ~= ref.spine then
			self.spineData["masterSpine"] = ref.spine
			self:CreateWndSpine(spine, ref.spine, "masterSpine", false, function(dpSpine)
				dpSpine:SetScale(1.5)
			end)
		end
	end
	self:SetWndText(serverText, masterInfo.playerInfo._serverName)
	local name = masterInfo.playerInfo.robot and gModelCrossWar:GetRobotName() or masterInfo.playerInfo._name
	self:SetWndText(nameText, name)
	self:SetWndText(powerText, LUtil.NumberCoversion(masterInfo.power))
end

function UIKuafuWarInside:SetGetInfo()
	if not self.insideInfo then
		return
	end
	local reward = gModelCrossWar:GetTimeReward()
	self:TimerStop("getRunItem")
	self:TimerStart("getRunItem", 30, false, -1)
	for i = 1, 2 do
		local item = self["mGet" .. i]
		local icon = self:FindWndTrans(item, "Icon")
		local text1 = self:FindWndTrans(item, "Text1")
		local text2 = self:FindWndTrans(item, "Text2")
		local text3 = self:FindWndTrans(item, "Text3")
		if reward[i] then
			local img = gModelGeneral:GetCommonItemImgRef(reward[i])
			self:SetWndEasyImage(icon, img)
			self:SetWndText(text1, reward[i].count .. "/m")
			local add = gModelCrossWar:GetVipAdd()
			local str = add > 0 and "+" .. add * 100 .. "%" or ""
			self:SetWndText(text2, str)
			self:SetTotalReward(text3, reward[i])
			self.getItem[i] = {text = text3, reward = reward[i]}
		end
		CS.ShowObject(item, not table.isempty(reward[i]))
	end
end

function UIKuafuWarInside:ClickCancelBtn()
	local allTiem = gModelCrossWar:GetAllFowOrRetTime()
	local leftTime = gModelCrossWar:GetFowOrRetEndTime() - GetTimestamp()
	local minTime = gModelCrossWar:GetMinFowOrRetTime()
	local rewards, id
	if (allTiem * 60) - leftTime < minTime * 60 then
		id = 150015
	else
		rewards = gModelCrossWar:GetTimeReward()
		id = self.roleType == 2 and 150012 or 150013
		for i = 1, #rewards do
			local unitNum = rewards[i].count + (rewards[i].count * gModelCrossWar:GetVipAdd())
			local totalTime = leftTime > 0 and (allTiem * 60 - leftTime) / 60 or allTiem
			local totalNum = math.floor(unitNum * math.floor(totalTime))
			rewards[i].count = totalNum
		end
	end

	local refId = self.insideInfo.innerTempleRank
	gModelGeneral:OpenUIOrdinTips({
		refId = id,
		func = function()
			if self.roleType == 2 then
				gModelCrossWar:CrossWarTempleRetinueApplyReq(3, refId)
			else
				gModelCrossWar:CrossWarTempleFollowReq(2, refId)
			end
		end,
		para = { minTime },
		itemList = rewards
	})
end

function UIKuafuWarInside:SetTimeText(item, leftTime)
	if item then
		local timeText = self:FindWndTrans(item, "TimeText")
		self:SetWndText(timeText, LUtil.FormatTimespanDetail(leftTime))
	end
end

function UIKuafuWarInside:SetRetinueList()
	if not self.insideInfo then
		return
	end
	local masterRank = self.insideInfo.innerTempleRank
	local retinueAllNum = gModelCrossWar:GetWarDomainRefById(masterRank).protectNum
	local list = self.insideInfo.playerInfoList[2] or {}
	self:SetWndText(self:FindWndTrans(self.mRetinueNumObj, "Text"), #list .. "/" .. retinueAllNum)
	table.sort(list, function(a, b)
		return a.endTime < b.endTime
	end)
	for i = 1, retinueAllNum do
		if not list[i] then
			list[i] = {}
		end
	end
	if not self.retinueList then
		self.retinueList = self:GetUIScroll("mRetinueList")
		self.retinueList:Create(self.mRetinueList, list, function(...) self:DrawRetinue(...) end, UIItemList.SUPER_GRID)
	else
		self.retinueList:ResetList(list)
		self.retinueList:DrawAllItems()
	end
end

function UIKuafuWarInside:InitNeedItem()
	if self.needList then
		self.needList:RefreshData(self.needItemList)
	else
		self.needList = self:GetUIScroll("uiNeedList")
		self.needList:Create(self.mNeedItemList, self.needItemList, function(...) self:OnDrawNeedItemCell(...) end)
	end
end

function UIKuafuWarInside:OnTimer(key)
	if key == "itemRunTime" then
		for _, v in pairs(self.itemList) do
			local endTime = v.data.endTime or 0
			local leftTime = endTime - GetTimestamp()
			if leftTime > 0 then
				self:SetTimeText(v.item, leftTime)
			else
				if v.data.playerInfo then
					gModelCrossWar:CrossWarTempleInfoReq()
					self:TimerStop("itemRunTime")
				end
			end
		end
	end

	if key == "getRunItem" then
		for _, v in ipairs(self.getItem) do
			self:SetTotalReward(v.text, v.reward)
		end
	end
end

function UIKuafuWarInside:ClickApplyBtn()
	-- local refId = gModelCrossWar:GetInnerTempleInfo().innerTempleRank
	-- gModelCrossWar:CrossWarTempleRetinueApplyReq(1, refId)
	-- GF.ShowMessage(ccClientText(12502))
	GF.OpenWnd("UIKuafuWarInsideList", { showTab = false })
end

function UIKuafuWarInside:SetFollowList()
	if not self.insideInfo then
		return
	end
	local masterRank = self.insideInfo.innerTempleRank
	local followAllNum = gModelCrossWar:GetWarDomainRefById(masterRank).followNum
	local list = self.insideInfo.playerInfoList[3] or {}
	self:SetWndText(self:FindWndTrans(self.mFollowNumObj, "Text"), #list .. "/" .. followAllNum)
	table.sort(list, function(a, b)
		return a.endTime < b.endTime
	end)
	for i = 1, followAllNum do
		if not list[i] then
			list[i] = {}
		end
	end
	if not self.followList then
		self.followList = self:GetUIScroll("mFollowList")
		self.followList:Create(self.mFollowList, list, function(...) self:DrawFollow(...) end, UIItemList.SUPER_GRID)
	else
		self.followList:ResetList(list)
		self.followList:DrawAllItems()
	end
end

function UIKuafuWarInside:ClickRecruitBtn()
	gModelGeneral:OpenUIOrdinTips({
		refId = 150010,
		func = function()
			local cd = GameTable.BattleTempleConfigRef.recruitCd
			local recruitTime = tonumber(self.insideInfo.recruitTime / 1000) or 0
			local t = GetTimestamp() - recruitTime
			if t < cd then
				GF.ShowMessage(string.replace("#a1#秒后可再次发布招募", math.ceil(cd - t)))
				return
			end
			gModelCrossWar:CrossWarTempleRetinueRecruitReq()
		end,
	})
end


------------------------------------------------------------------
return UIKuafuWarInside