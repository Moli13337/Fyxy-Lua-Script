---
--- Created by Administrator.
--- DateTime: 2024/12/3 18:07:12
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDivineWeaponFight:LWnd
local UIDivineWeaponFight = LxWndClass("UIDivineWeaponFight", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDivineWeaponFight:UIDivineWeaponFight()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDivineWeaponFight:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDivineWeaponFight:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDivineWeaponFight:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitCommon()

	gModelDivineWeaponFight:DescendsInfoReq()
end

function UIDivineWeaponFight:DrawRewardIcon(_, item, data)
	local root = self:FindWndTrans(item, "Root")
	local instanceId = root:GetInstanceID()
	local commonIcon = self:GetCommonIcon(instanceId)
	commonIcon:Create(root)
	commonIcon:SetCommonReward(data.itemType, data.itemId, data.itemNum)
	commonIcon._curIconCls:SetFontSize(35)
	commonIcon:DoApply()
	-- LxUiHelper.SetTextFontSize(commonIcon._curIconCls._uiNumTxtTrans, 35)

	self:SetWndClick(root, function()
		gModelGeneral:ShowCommonItemTipWnd(data)
	end)
end

function UIDivineWeaponFight:DrawList(_, trans, data)
	local bg = CS.FindTrans(trans, "Image")
	local name = CS.FindTrans(trans, "Name")
	local rewardText = CS.FindTrans(trans, "RewardText")
	local rewardList = CS.FindTrans(trans, "RewardList")
	local open = CS.FindTrans(trans, "Open")
	local sweepBtn = CS.FindTrans(open, "SweepBtn")
	local fightBtn = CS.FindTrans(open, "FightBtn")
	local starText = CS.FindTrans(open, "StarText")
	local lock = CS.FindTrans(trans, "Lock")
	local lockText = CS.FindTrans(lock, "LockText")
	local lockCond = CS.FindTrans(lock, "LockCond")
	local condText = CS.FindTrans(lock, "CondText")
	local redPoint = CS.FindTrans(trans, "redPoint")
	local sweepRedPoint = CS.FindTrans(sweepBtn, "redPoint")
	local sweepBtnLight = CS.FindTrans(sweepBtn, "Light")
	local sweepBtnIcon = CS.FindTrans(sweepBtnLight, "Icon")

	self:SetWndEasyImage(bg, data.icon)
	self:SetWndText(name, ccLngText(data.name))
	self:SetWndText(rewardText, ccClientText(46201))
	self:SetWndText(lockText, ccClientText(46202))
	self:SetWndText(lockCond, ccClientText(46203))
	local s1 = "<#a1#>" .. ccLngText(data.text1) .. "</color>"
	local s2 = "<#a1#>" .. ccLngText(data.text2) .. "</color>"
    local info = string.split(data.open, "=")
    local type = tonumber(info[1])
    local para = tonumber(info[2])
	local func = gModelFunctionOpen:GetCheckFuns(type)
	local color1 = func(para) and "#139057" or "#9F251B"
	local beforeChapter = gModelDivineWeaponFight:GetChapterInfoById(data.refId - 1)
	local color2 = "#9F251B"
	if beforeChapter then
		local passBarrier = beforeChapter.notFullStarBarriers
		if passBarrier and table.keysize(passBarrier) == 15 then
			local starNum = beforeChapter.starNum
			if starNum >= GameTable.DescendsRef.starNum then
				color2 = "#139057"
			end
		end
	end
	s1 = string.replace(s1, color1)
	s2 = string.replace(s2, color2)
	local s = s1 .. "\n" .. s2
	local pos = string.isempty(data.text2) and 0 or 35
	self:SetAnchorPos(lock, Vector2.New(192.8, pos))
	self:SetWndText(condText, s)

	local starInfo = string.split(data.starProgress, "=")
	local chapterInfo = gModelDivineWeaponFight:GetChapterInfoById(data.refId)
	local isOpen = false
	local isFullStar = false
	if chapterInfo and not table.isempty(chapterInfo) then
		isOpen = chapterInfo.isOpen == 1
		isFullStar = chapterInfo.starNum == tonumber(starInfo[#starInfo])
		self:SetWndText(starText, chapterInfo.starNum .. "/" .. starInfo[#starInfo])
	end
	local sweepBtnStr = ""
	local freeSweepNum = gModelDivineWeaponFight:GetFreeSweepNum()
	local allFreeSweepNum = gModelDivineWeaponFight:GetAllFreeSweepNum()
	local isGary = false
	local showIcon = false
	local needItme = 0
	if freeSweepNum >= allFreeSweepNum then
		local buySweepNum = gModelDivineWeaponFight:GetBuySweepNum()
		local allBuySweepNum = gModelDivineWeaponFight:GetAllBuySweepNum()
		allBuySweepNum = tonumber(allBuySweepNum)
		if buySweepNum < allBuySweepNum then
			local item = gModelDivineWeaponFight:GetSweepItemByTimes(data.refId, buySweepNum + 1)
			local res = gModelGeneral:GetCommonItemImgRef(item)
			self:SetWndEasyImage(sweepBtnIcon, res)
			sweepBtnStr = item.itemNum .. ccClientText(44067)
			showIcon = true
			needItme = item
		else
			sweepBtnStr = ccClientText(44067)
			isGary = true
		end
	else
		sweepBtnStr = ccClientText(44067)
	end

	local reawrds = {}
	if isOpen then
		if isFullStar then
			reawrds = LxDataHelper.ParseItem(data.consumeReward)
		else
			local curBarrier = gModelDivineWeaponFight:GetCurBarrierId()
			local curBarrierCfg = GameTable.DescendsBarrierRef[curBarrier]
			local curBarrierChatper = curBarrierCfg.chapterId
			if curBarrierChatper == data.refId then
				for i = 1, 3 do
					local reward = LxDataHelper.ParseItem_4(curBarrierCfg["reward" .. i])
					table.insert(reawrds, reward)
				end
			else
				for i, v in ipairs(starInfo) do
					local num = tonumber(v)
					if chapterInfo.starNum <= num and #chapterInfo.starChest ~= i then
						reawrds = LxDataHelper.ParseItem(data["Reward" .. i])
						break
					end
				end
			end
		end
	else
		local barrierCfgs = gModelDivineWeaponFight:GetBarrierByChapter(data.refId)
		local cfg = barrierCfgs[1]
		for i = 1, 3 do
			local reward = LxDataHelper.ParseItem_4(cfg["reward" .. i])
			table.insert(reawrds, reward)
		end
	end
	local InstanceID = trans:GetInstanceID()
	if self.rewardIconUIList[InstanceID] then
		self.rewardIconUIList[InstanceID]:RefreshList(reawrds)
		self.rewardIconUIList[InstanceID]:DrawAllItems()
	else
		self.rewardIconUIList[InstanceID] = self:GetUIScroll("rewardIconUIList" .. InstanceID)
		self.rewardIconUIList[InstanceID]:Create(rewardList, reawrds, function(...) self:DrawRewardIcon(...) end, UIItemList.SUPER_GRID)
	end

	self:SetWndButtonText(sweepBtn, sweepBtnStr)
	self:SetWndButtonGray(sweepBtn, isGary)
	UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(sweepBtnLight)
	CS.ShowObject(open, isOpen)
	CS.ShowObject(lock, not isOpen)
	CS.ShowObject(fightBtn, not isFullStar)
	CS.ShowObject(sweepBtn, isFullStar)
	CS.ShowObject(redPoint, gModelDivineWeaponFight:GetChapterRedPointById(data.refId))
	CS.ShowObject(sweepRedPoint, gModelDivineWeaponFight:GetChapterSweepRedPoint(data.refId))
	CS.ShowObject(sweepBtnIcon, showIcon)

	self:SetWndClick(sweepBtn, function()
		-- if isGary then
		-- 	return
		-- end
		if showIcon then
			gModelGeneral:OpenUIOrdinTips({
				refId = 480006,
				para = { needItme.itemNum },
				func = function()
					local own = gModelItem:GetNumByRefId(needItme.itemId)
					if own < needItme.itemNum then
						gModelGeneral:OpenGetWayWnd({ itemId = needItme.itemId, srcWnd = self:GetWndName() })
						return
					end
					gModelDivineWeaponFight:DescendsSweepReq(data.refId, 2)
				end,
			})
		else
			gModelDivineWeaponFight:DescendsSweepReq(data.refId, 1)
		end
	end)
	self:SetWndClick(trans, function()
		if isOpen then
			GF.OpenWnd("UIDivineWeaponChapter", { id = data.refId })
		end
	end)
end

function UIDivineWeaponFight:UpdateChapterList()
	local list = gModelDivineWeaponFight:GetChapterCfgList()
	if self.uiList then
		self.uiList:ResetList(list)
		self.uiList:DrawAllItems()
	else
		self.uiList = self:GetUIScroll("uiList")
		self.uiList:Create(self.mList, list, function(...) self:DrawList(...) end, UIItemList.SUPER)
		local index = gModelDivineWeaponFight:GetCurChapterId()
		local b = true
		for i, v in ipairs(list) do
			if gModelDivineWeaponFight:GetChapterRedPointById(v.refId) then
				index = i
				b = false
				break
			end
		end
		if b then
			for i = #list, 1, -1 do
				if gModelDivineWeaponFight:GetChapterSweepRedPoint(list[i].refId) then
					index = i
					break
				end
			end
		end
		self.uiList:MoveToPos(index)
	end
end

function UIDivineWeaponFight:InitCommon()
	------------------------------------------------------------------
	---member
	self.rewardIconUIList = {}

	------------------------------------------------------------------
	---text
	self:SetTextTile(self.mTitle, ccClientText(46200))
	self:SetWndText(self.mTxtReturn, ccClientText(20723))

	------------------------------------------------------------------
	---click
	self:SetWndClick(self.mReturnBtn, function()
		GF.OpenWndBottom("UIOutts")
		self:WndClose()
	end)
	self:SetWndClick(self.mTips, function()
		GF.OpenWnd("UIBzTips", { refId = 187 })
	end)

	------------------------------------------------------------------
	---event
	self:WndEventRecv("DescendsInfoResp", function()
		self:UpdateChapterList()
	end)
	self:WndEventRecv("DescendsSweepResp", function()
		self:UpdateChapterList()
	end)
	self:WndEventRecv("DescendsStarChestResp", function()
		self:UpdateChapterList()
	end)
	self:WndEventRecv(EventNames.On_Item_Change, function()
		self:UpdateChapterList()
	end)
end



------------------------------------------------------------------
return UIDivineWeaponFight