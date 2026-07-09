---
--- Created by Administrator.
--- DateTime: 2024/6/11 14:40:54
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIKuafuWar:LWnd
local UIKuafuWar = LxWndClass("UIKuafuWar", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIKuafuWar:UIKuafuWar()
	self.tabBtnData = {
		{
			name = ccClientText(43800),
			icon = "wardomain_btn_5",
			func = function()
				if not table.isempty(gModelCrossWar:GetSelfInsideInfo()) then
					GF.OpenWnd("UIKuafuWarInside")
					return
				end
				local innerTempleInfo = gModelCrossWar:GetInnerTempleInfo()
				if #innerTempleInfo.applyInfoList > 0 then
					GF.OpenWnd("UIKuafuWarInsideList", { showTab = true })
				else
					GF.ShowMessage(ccClientText(43802))
				end
			end,
			isOpen = function()
				local innerTempleInfo = gModelCrossWar:GetInnerTempleInfo()
				return #innerTempleInfo.applyInfoList > 0 or not table.isempty(gModelCrossWar:GetSelfInsideInfo())
			end,
			redPointId = 13900020
		},
		{
			name = ccClientText(43801),
			icon = "wardomain_btn_6",
			isOpen = function()
				return true
			end,
			redPointId = 13900010
		}
	}
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
	self.spineData = {}
	self.tabTrans = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIKuafuWar:OnWndClose()
	self:TimerStop("runLeftTime")
	self:TimerStop("wndRunTime")
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIKuafuWar:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIKuafuWar:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self._isVie = gLGameLanguage:IsVieVersion()
	self._isEnus = gLGameLanguage:IsEnglishVersion()
	self._nameMoveSeqKey = "_nameMoveSeqKey"
	self._nameMoveTimeKey = "_nameMoveTimeKey"
	local layoutEnWidth = 142
	self._nameTxtDefaultX = -layoutEnWidth / 2
	self._layoutNameTextPath = "NameText"
	self._layoutNameTextPathEn = "NameMask/NameText"
	self._nameMoveCache={}
	
	
	self:InitEvent()
	self:InitText()
	self:UpdateCanvas()
	self:InitNeedItem()

	self:TimerStart("wndRunTime", 30, false, -1)
	gModelCrossWar:CrossWarTempleStateReq()
	self:RefreshForeign()
end

function UIKuafuWar:SetChallengeList()
	local challengeList = gModelCrossWar:GetChallengeList()
	table.sort(challengeList, function(a, b)
		return a.rank < b.rank
	end)
	self.challengeListData = challengeList
	self.listLen = #challengeList
	if not self.isCreateCellBg then
		self.isCreateCellBg = true
		self:CreateCellBg()
	end


	self._challengeRoot={}

	for i, v in ipairs(challengeList) do
		local itemName = "item" .. i
		local item = CS.FindTrans(self.mContent, itemName)
		if not item then
			local gameObj = LxUnity.InstantObject(self.mItemTemplate.gameObject)
			gameObj.name = itemName
			item = gameObj.transform
			LxUnity.SetParentTrans(item, self.mContent)
			CS.ShowObject(item, true)
		end
		self:DrawChallenge(item, v, i)
	end

	local movePos = #challengeList
	local selfInfo = gModelCrossWar:GetSelfOutsideInfo()
	if not table.isempty(selfInfo) then
		movePos = selfInfo.rank
	end
	if self.oldMovePos ~= movePos then
		self.oldMovePos = movePos
		local screenHeight = self.mBg.rect.height
		local point = screenHeight - 105
		local len = 382 + (162 * movePos)
		if not self.seqCom then
			self.seqCom = SequenceCom:New()
		end
		local seq = self.seqCom:CreateSeq("delayFreeze")
		local pos = Vector2.New(0, len - point)
		local speed = movePos * 2 / 30
		local downTweener = self.mContent:DOLocalMove(pos, speed):SetEase(DG.Tweening.Ease.Linear)
		seq:Insert(0, downTweener)
		seq:PlayForward()
	end

	--开一个计时器
	self:TimerStop(self._nameMoveTimeKey)
	self:TimerStart(self._nameMoveTimeKey, 0.5, false, 1)
end

function UIKuafuWar:InitNeedItem()
	if self.needList then
		self.needList:RefreshData(self.needItemList)
	else
		self.needList = self:GetUIScroll("uiNeedList")
		self.needList:Create(self.mNeedItemList, self.needItemList, function(...) self:OnDrawNeedItemCell(...) end)
	end
end

--处理名字的移动
function UIKuafuWar:SetChallengeNameMove(itemTrans)
	local instanceId = itemTrans:GetInstanceID()
	local curSeqTweenKey = self._nameMoveSeqKey .. instanceId
	if self._nameMoveCache[curSeqTweenKey] == nil then
		return
	end
	local nameTrans = self:FindWndTrans(itemTrans, "layoutEn/" .. self._layoutNameTextPathEn)
	if not CS.IsValidObject(nameTrans) then
		self._nameMoveCache[curSeqTweenKey] = false
		return
	end

	local defaultPosY = nameTrans.localPosition.y
	local fromPos = Vector3.New(self._nameTxtDefaultX, defaultPosY, 0)
	local isMove = self._nameMoveCache[curSeqTweenKey]
	self:TweenSeqKill(curSeqTweenKey)

	if not isMove then
		--还原
		nameTrans.localPosition = fromPos
		self._nameMoveCache[curSeqTweenKey] = false
		return
	end

	local sizeDeltaX = nameTrans.sizeDelta.x
	local toPosX = -self._nameTxtDefaultX - sizeDeltaX
	if toPosX >= self._nameTxtDefaultX then
		--长度足够显示内容，不需要滑动
		nameTrans.localPosition = fromPos
		self._nameMoveCache[curSeqTweenKey] = false
		return
	end

	local toPos = Vector3.New(toPosX, defaultPosY, 0)

	if not self._rollTime then
		self._rollTime = 2
		self._rollingTime = 2
	end

	self:TweenSeq_MoveAndBack(curSeqTweenKey, nameTrans, fromPos, toPos, self._rollingTime,
			self._rollTime, self._rollTime, nil, nil, true, false)

	self._nameMoveCache[curSeqTweenKey] = true
end


function UIKuafuWar:ShowSpine(rankingId, root)
	local spine = self:FindWndTrans(root, "Spine")
	local ref = gModelPlayer:GetRoleAdventureImage(rankingId)
	local key = root:GetInstanceID()
	if ref then
		if self.spineData[key] == ref.spine then
			return
		end
		self:DestroyWndSpineByKey(key)
		self.spineData[key] = ref.spine
		self:CreateWndSpine(spine, ref.spine, key, false)
	end
end

function UIKuafuWar:UpdateTimeText()
	if not self.leftTime or not self.leftTimeStr then
		local s, time = gModelCrossWar:GetStateAndLeftTime()
		self.leftTimeStr = s
		self.leftTime = time
	else
		self.leftTime = math.round2(math.max(self.leftTime - 1, 0))
	end
	local color = self.leftTime > 86400 and "<#68E6AC>" or "<#c81313>"
	local str = color .. string.replace(self.leftTimeStr, LUtil.FormatTimeStr1(self.leftTime)) .. "</color>"
	self:SetWndText(self.mTimeText, str)
	if self.leftTime < 0 then
		self:TimerStop("runLeftTime")
		self.leftTime = nil
		self.leftTimeStr = nil
	end
end

function UIKuafuWar:OnTryRefreshRedPoint(...)
	self:UpdateRedPoint()
end

function UIKuafuWar:OnTimer(key)
	if key == "runLeftTime" then
		self:UpdateTimeText()
	end
	if key == "wndRunTime" then
		gModelCrossWar:CrossWarTempleStateReq()
	end

	if key  == self._nameMoveTimeKey then
		if self._isEnus then
			self:ShowChallengeNameTextMove()
		end
	end
end

function UIKuafuWar:UpdateRedPoint()
	for _, v in ipairs(self.tabTrans) do
		local b = false
		local redPoint = CS.FindTrans(v.trans, "redPoint")
		if v.redPointId then
			b = gModelRedPoint:CheckShowRedPoint(v.redPointId)
		end
		if redPoint then
			CS.ShowObject(redPoint, b)
		end
	end
end

function UIKuafuWar:InitEvent()
	self:SetWndClick(self.mCloseBtn, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mHelpBtn, function()
		GF.OpenWnd("UIBzTips", { refId = 173 })
	end)
	self:SetWndClick(self.mGroupBtn, function()
		gModelCrossWar:CrossWarTempleGroupInfoReq()
	end)
	self:SetWndClick(self.mReportBtn, function()
		GF.OpenWnd("UIKuafuWarReport")
	end)
	self:SetWndClick(self.mRewardBtn, function()
		GF.OpenWnd("UIKuafuWarAward")
	end)
	self:SetWndClick(self.mTeamBtn, function()
		self:ClickTeamBtn()
	end)
	self:SetWndClick(self.mShopBtn, function()
		GF.OpenWndBottom("UIDian", { shopId = 2011 })
	end)

	self:WndEventRecv(EventNames.On_Item_Change, function()
		self:InitNeedItem()
	end)
	self:WndEventRecv("CrossWarTempleChallengeListResp", function()
		self:SetChallengeList()
	end)
	self:WndEventRecv("CrossWarTempleStateResp", function()
		if gModelCrossWar:GetState() == 0 then
			GF.ShowMessage(ccClientText(43830))
			self:WndClose()
			return
		end
		self:TimerStop("runLeftTime")
		self:TimerStart("runLeftTime", 1, false, -1)
		self:UpdateTimeText()
		gModelCrossWar:CrossWarTempleInfoReq()
		gModelCrossWar:CrossWarTempleChallengeListReq()
		gModelWarTemple:WarTempleInfoReq()
	end)
	self:WndEventRecv("CrossWarTempleInfoResp", function()
		self:InitTabList()
		self:UpdateRedPoint()
	end)
end


--记录名字移动的缓存
function UIKuafuWar:SetChallengeNameMoveData(itemTrans,isMove)
	if not self._nameMoveCache then
		self._nameMoveCache = {}
	end

	local instanceId = itemTrans:GetInstanceID()
	local curSeqTweenKey = self._nameMoveSeqKey .. instanceId
	self._nameMoveCache[curSeqTweenKey] = isMove
end

function UIKuafuWar:InitText()
	self:SetWndText(self.mTitleText, ccClientText(43803))
	self:SetWndText(self:FindWndTrans(self.mCloseBtn, "TxtClose"), ccClientText(30205))
	self:SetWndText(self:FindWndTrans(self.mGroupBtn, "Text"), ccClientText(17982))
	self:SetWndText(self:FindWndTrans(self.mReportBtn, "Text"), ccClientText(10359))
	self:SetWndText(self:FindWndTrans(self.mRewardBtn, "Text"), ccClientText(10361))
	self:SetWndText(self:FindWndTrans(self.mTeamBtn, "Text"), ccClientText(21810))
	self:SetWndText(self:FindWndTrans(self.mShopBtn, "Text"), ccClientText(21803))
end

function UIKuafuWar:DrawChallenge(item, data, index)
	local root = self:FindWndTrans(item, "Root")
	local rankIcon = self:FindWndTrans(root, "Rank/RankIcon")
	local rankText = self:FindWndTrans(root, "Rank")
	local name = self:FindWndTrans(root, "Name")
	local power = self:FindWndTrans(root, "Power")
	local clickImg = self:FindWndTrans(root, "ClickImg")
	local leftStep = self:FindWndTrans(root, "LeftStep")
	local rightStep = self:FindWndTrans(root, "RightStep")

	self._challengeRoot[index]=root
	--根据多语言处理
	local layoutEn  = self:FindWndTrans(root, "layoutEn")
	local nameTextEn = self:FindWndTrans(layoutEn, "NameMask/NameText")
	if self._isEnus then
		name  = nameTextEn
	end

	local isLeft = index % 2 == 1
	local x = isLeft and 417 or 122
	root.localPosition = Vector2.New(x, 0)
	CS.ShowObject(leftStep, isLeft and index ~= self.listLen)
	CS.ShowObject(rightStep, not isLeft and index ~= self.listLen)

	self:SetWndText(rankText, data.rank)
	CS.ShowObject(rankIcon, data.rank <= 3)
	CS.ShowObject(rankBg, data.rank > 3)

	local nameStr, powerStr = "", ""
	if data.npcId ~= 0 then
		local cfg = gModelCrossWar:GetWarDomainRefById(data.rank)
		local monsterCfg = gModelHero:GetMonsterFormationRefByRefId(data.npcId)
		local heroId = cfg.monsterShow
		local rankingId = GameTable.CharacterEffectRef[heroId].rankingId
		self:ShowSpine(rankingId, root)
		nameStr = ccLngText(monsterCfg.name)
		powerStr = LUtil.PowerNumberCoversion(monsterCfg.monsterPower)
	else
		self:ShowSpine(data.playerInfo._figure, root)
		local str = "[#a1#]#a2#"
		nameStr = string.replace(str, data.playerInfo._serverName, data.playerInfo._name)
		powerStr = LUtil.PowerNumberCoversion(data.power)
	end
	self:SetWndText(name, nameStr)
	self:SetWndText(power, powerStr)

	self:SetWndClick(clickImg, function()
		GF.OpenWnd("UIKuafuWarChall", data)
	end)

	--nameStr
	if self._isEnus or self._isVie then
		self:SetChallengeNameMoveData(root,true)
		if self._isVie then
			self.mTimeBg.sizeDelta=Vector2.New(420,33)
			local text = self:FindWndTrans(self.mRewardBtn, "Text")
			text.sizeDelta = Vector2.New(80,30)
			local textTran = LxUiHelper.FindXTextCtrl(text)
			textTran.enableWordWrapping = true

			self:SetAnchorPos(self.mHelpBtn,Vector2.New(120,0))
			self:InitTextCharacterWithLanguage(self.mTitleText,-5)

		else
			self.mTimeBg.sizeDelta=Vector2.New(400,33)
		end
	end
end

function UIKuafuWar:RefreshForeign()

end

function UIKuafuWar:InitTabList()
	self.tabBtn = {}
	if self.tabList then
		self.tabList:DrawAllItems()
	else
		self.tabList = self:GetUIScroll("TabScroll")
		self.tabList:Create(self.mTabScroll, self.tabBtnData, function(...) self:OnDrawTab(...) end)
	end
end

function UIKuafuWar:ShowChallengeNameTextMove()
	for k, v in pairs(self._challengeRoot) do
		local item = v
		self:SetChallengeNameMove(item)
	end
end

function UIKuafuWar:ClickTeamBtn()
	local para = {
		setTargetType = LCombatTypeConst.COMBAT_CROSS_WAR,
		returnFunc = function()
			FireEvent(EventNames.CHANGE_MAIN_BTN, LMainBtnIndexConst.OUTSKIRTS)
			GF.ChangeMap("LCityMap")
			GF.OpenWndBottom("UIOutts", {childIndex = 2})
			GF.OpenWndBottom("UIKuafuWar")
		end,
		retAfterSet = true,
	}
	gModelFormation:OpenSetFormationWnd(para)
	self:WndClose()
end

function UIKuafuWar:OnDrawNeedItemCell(_, item, data)
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

function UIKuafuWar:CreateCellBg()
	local contentH = (self.listLen * 162) + 382 + 105 - 490.5
	local cellBgCt = math.ceil(contentH / 1400)
	for i = 1, cellBgCt do
		local name = "CellBg" .. i
		local cellBg = CS.FindTrans(self.mContent, name)
		if not cellBg then
			local gameObj = LxUnity.InstantObject(self.mCellBg.gameObject)
			gameObj.name = name
			cellBg = gameObj.transform
			LxUnity.SetParentTrans(cellBg, self.mContent)
			cellBg.localPosition = Vector2.New(0, -(490.5 + ((i - 1) * 1400)))
			CS.ShowObject(cellBg, true)
		end
		self:CreateWndEffect(cellBg, "fx_nszz_changjingyunwu", name, 100, nil, nil, nil, nil, nil, nil, nil,
			function(dpTrans)
				dpTrans.localPosition = Vector2.New(320, -668)
			end
		)

	end
end

function UIKuafuWar:UpdateCanvas()
	local typeofCanvas = typeof(UnityEngine.Canvas)
	local wndSortOrder = self:GetWndSortOrder()
    local canvas = self.mCellBg:GetComponent(typeofCanvas)
    canvas.sortingOrder = wndSortOrder + 1
	canvas = self.mItemTemplate:GetComponent(typeofCanvas)
    canvas.sortingOrder = wndSortOrder + 2
	canvas = self.mTop:GetComponent(typeofCanvas)
    canvas.sortingOrder = wndSortOrder + 3
	canvas = self.mBtnTabList:GetComponent(typeofCanvas)
    canvas.sortingOrder = wndSortOrder + 3
end

function UIKuafuWar:OnDrawTab(_, item, data, index)
	local lock = self:FindWndTrans(item, "Lock")
	self:SetWndTabText(item, data.name)
	self:SetWndTabStatus(item, index == 2 and 0 or 1)
	if data.icon then
		local On = self:FindWndTrans(item,"On")
		local Off = self:FindWndTrans(item,"Off")
		self:SetWndEasyImage(On, data.icon)
		self:SetWndEasyImage(Off, data.icon)
	end
	CS.ShowObject(lock, not data.isOpen())
	self:SetWndClick(item, function()
		if data.func then
			data.func()
		end
	end)
	if not self.tabTrans[index] then
		self.tabTrans[index] = {
			trans = item,
			redPointId = data.redPointId
		}
	end
end



------------------------------------------------------------------
return UIKuafuWar