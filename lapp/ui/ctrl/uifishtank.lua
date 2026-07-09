---
--- Created by wzz.
--- DateTime: 2024/7/16 11:44:20
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFishTank:LWnd
local UIFishTank = LxWndClass("UIFishTank", LWnd)
------------------------------------------------------------------

local Tweening = DG.Tweening

local TabDataList = {
	--- 属性
	[3] = { onIcon = "fish_btn_icon_9", offIcon = "fish_btn_icon_9", title = ccClientText(44271), index = 3 },
	--- 升级
	[2] = { onIcon = "fish_btn_icon_11", offIcon = "fish_btn_icon_11", title = ccClientText(44272), index = 2 },
	--- 详情
	[1] = { onIcon = "fish_btn_icon_12", offIcon = "fish_btn_icon_12", title = ccClientText(44273), index = 1 },
}

local table = table

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFishTank:UIFishTank()
	self._fishSpineMap = {}

	self._runIdMap = gModelFish:GetFishRunTypeMap()
	self._curRunIdMap = table.clone(self._runIdMap)
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFishTank:OnWndClose()
	LWnd.OnWndClose(self)

	for k, v in pairs(self._fishSpineMap) do
		if v.seqMove then
			v.seqMove:Kill(false)
		end
	end
	self._fishSpineMap = {}
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFishTank:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFishTank:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsForeignVersion()
	
	self:InitTexts()
	self:InitEvents()
	self:InitTabList()
	self:InitTimer()
	self:Refresh()
end

-- 弹出游动id
function UIFishTank:PopRunId(type)
	local list = self._curRunIdMap[type]
	if #list == 0 then
		self._curRunIdMap[type] = table.clone(self._runIdMap[type])
		list = self._curRunIdMap[type]
	end

	local index = math.random(1, #list)
	return table.remove(list, index)
end

-- 刷新界面
function UIFishTank:Refresh()
	self._bottomTabList:DrawAllItems()

	local fishObjMap = gModelFish:GetFishTankAllObjs()
	local fishRefIdMap = {}
	for k, fishObj in pairs(fishObjMap) do
		local fishRefId = fishObj.refId
		local fishRef = gModelFish:GetFishRef(fishRefId)
		local runType = fishRef.runId
		local fishRunRefId = self:PopRunId(runType)
		fishRefIdMap[fishRefId] = fishRefId
		if not self._fishSpineMap[fishRefId] then
			local spine = self:CreateWndSpine(self.mFishSpineRoot, fishRef.spine, fishRefId, false,
				function(dpSpine)
					dpSpine:SetScale(2)
					dpSpine:PlayAnimation(0, "run", true)
					self:StartRun(fishRefId, fishRunRefId)
				end, true)
			if spine then
				self._fishSpineMap[fishRefId] = {spine = spine, runType = runType, initRunRefId = fishRunRefId }
				spine:StartLoad()
			end
		end
	end
	self._checkFishRefIdMap = fishRefIdMap
end

-- Update
function UIFishTank:Update()
	for _, v in pairs(self._fishSpineMap or {}) do
		if v.needStartRun then
			self:StartRun(v.needStartRun.fishRefId, v.needStartRun.nextRefId)
			v.needStartRun = nil
		end
	end

	if self._checkFishRefIdMap then
		local map = self._checkFishRefIdMap
		for fishRefId, v in pairs(self._fishSpineMap) do
			if not map[fishRefId] then
				self:DestroyWndSpineByKey(fishRefId)
				if v.seqMove then
					v.seqMove:Kill(false)
				end
				self:PutRunId(v.initRunRefId, v.runType)
				self._fishSpineMap[fishRefId] = nil
			end
		end

		self._checkFishRefIdMap = nil
	end
end

-- 点击tab
function UIFishTank:OnClickTab(index)
	if self._curView == index then
		return
	end
	self._curView = index

	local uiList = self:GetUIScroll("UIFishTank")
	uiList:DrawAllItems()

	local function callFunc()
		self._curView = nil
		uiList:DrawAllItems()
	end


	if index == 1 then
		-- 详情
		GF.OpenWnd("UIFishTankDetail", { callFunc = callFunc, })
		return
	end

	if index == 2 then
		-- 升级
		GF.OpenWnd("UIFishTankUp", { callFunc = callFunc, })
		return
	end

	if index == 3 then
		-- 属性
		local attrList = {}
		for k, v in ipairs(gModelFish:FishTankAttrList()) do
			local value = gModelFish:CheckAttrValue(v.refId, v.type, v.value)
			attrList[k] = {
				attrRefId = v.refId,
				attrType = v.type,
				attrNum = value
			}
		end
		GF.OpenWnd("UISdAttrOverView", { callFunc = callFunc, attrList = attrList })
		return
	end
end

-- 初始时间
function UIFishTank:InitTimer()
	local timePara = {
		key = 1,
		loopcnt = -1,
		interval = 1,
		timescale = false,
		callOnStart = true,
		func = function()
			self:Update()
		end
	}
	self:TimerStartImpl(timePara)
end

-- 初始事件
function UIFishTank:InitEvents()
	self:SetWndClick(self.mCloseBtn, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mBtnHelp, function() GF.OpenWnd("UIBzTips", { refId = 177 }) end)

	self:WndEventRecv(EventNames.FISH_BASE_INFO, function(...) self:Refresh(...) end)
end

-- 压入游动id
function UIFishTank:PutRunId(id, type)
	table.insert(self._curRunIdMap[type], id)
end

-- 底部tab列表
function UIFishTank:InitTabList()
	local uiList = self:GetUIScroll("UIFishTank")
	uiList:Create(self.mTabScroll, TabDataList, function(...)
		self:OnDrawTab(...)
	end)
	self._bottomTabList = uiList
end

-- 开始运行
function UIFishTank:StartRun(fishRefId, fishRunRefId)
	if not self._fishSpineMap then
		return
	end

	if not self._fishSpineMap[fishRefId] then
		return
	end

	local dpSpine = self._fishSpineMap[fishRefId].spine
	if not dpSpine then
		return
	end

	local dpTrans = dpSpine:GetDisplayTrans()
	if not dpTrans then
		return
	end

	local fishRunRef = gModelFish:GetFishRunRef(fishRunRefId)
	local seqMove = Tweening.DOTween.Sequence()
	local time = fishRunRef.time
	local delay = fishRunRef.delay
	local nextRefId = fishRunRef.next

	if fishRunRef.fromPos == "" then
		seqMove:AppendInterval(delay)
	else
		local list1 = string.split(fishRunRef.fromPos, "|")
		local list2 = string.split(fishRunRef.toPos, "|")
		local fromPos = Vector3(tonumber(list1[1]), tonumber(list1[2]), 0)
		local toPos = Vector3(tonumber(list2[1]), tonumber(list2[2]), 0)
		dpSpine:SetFlipX(fromPos.x > toPos.x)

		dpTrans.localPosition = fromPos
		local moveTw = dpTrans:DOLocalMove(toPos, time)
		seqMove:Append(moveTw)
		seqMove:AppendInterval(delay)
	end
	seqMove:Play()
	seqMove:SetAutoKill(true)
	seqMove:OnComplete(function()
		-- seqMove:Kill(false)
		-- self:StartRun(fishRefId, nextRefId)
		if self._fishSpineMap[fishRefId] then
			self._fishSpineMap[fishRefId].needStartRun = { fishRefId = fishRefId, nextRefId = nextRefId }
		end
		self._fishSpineMap[fishRefId].seqMove = nil
	end)
	self._fishSpineMap[fishRefId].seqMove = seqMove
end

-- 底部tab列表 item
function UIFishTank:OnDrawTab(list, item, itemData, index)
	if self._isEnus then
		self:SetWndTabText(item, itemData.title,-4)
	else
		self:SetWndTabText(item, itemData.title)
	end

	self:SetWndTabStatus(item, self._curView == itemData.index and 0 or 1)

	self:SetWndClick(item, function(...)
		self:OnClickTab(itemData.index)
	end)

	local offTrans = CS.FindTrans(item, "Off")
	local onTrans = CS.FindTrans(item, "On")
	self:SetWndEasyImage(offTrans, itemData.offIcon)
	self:SetWndEasyImage(onTrans, itemData.onIcon)

	local showRed = false
	if index == 2 then
		local canUp, costItem, isMax = gModelFish:CanLvUpFishTank(false)
		showRed = canUp
	end
	self:SetRed(item, showRed)
end

-- 初始界面化文本
function UIFishTank:InitTexts()
	self:SetWndText(self.mTitle, ccClientText(44270))
	self:SetWndText(self.mTxtClose, ccClientText(42010))
end

------------------------------------------------------------------
return UIFishTank