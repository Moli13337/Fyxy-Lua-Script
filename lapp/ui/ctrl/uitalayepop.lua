---
--- Created by BY.
--- DateTime: 2023/10/23 20:31:39
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UITaLayePop:LWnd
local UITaLayePop = LxWndClass("UITaLayePop", LWnd)

UITaLayePop.TYPE_TOWER = 1
UITaLayePop.TYPE_BOSSTOWER = 2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UITaLayePop:UITaLayePop()
	self._uiheadList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UITaLayePop:OnWndClose()
	self:ClearCommonIconList(self._uiheadList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UITaLayePop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UITaLayePop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	local openType = self:GetWndArg("openType")
	if not openType then
		openType = UITaLayePop.TYPE_TOWER
	end
	self._openType = openType
	if openType == UITaLayePop.TYPE_TOWER then
		self:InitCommand()
	elseif openType == UITaLayePop.TYPE_BOSSTOWER then
		-- self:InitBossTowerData()
	end
end

function UITaLayePop:ListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local nameText = self:FindWndTrans(root,"TiBgImage/NameText")
	local headIcon = self:FindWndTrans(root,"HeadIcon")
	local serverText = self:FindWndTrans(root,"ServerText")
	local powerText = self:FindWndTrans(root,"PowerBg_1/PowerText")
	local textImg = self:FindWndTrans(root,"TextImg")
	local numText = self:FindWndTrans(root,"NumBg/NumText")

	local num = itemdata.num
	local relationType = itemdata.relationType
	self:SetWndText(serverText,gModelFriend:GetSevenName(itemdata.serverId))
	self:SetWndText(powerText,LUtil.NumberCoversion(itemdata.power))
	self:SetWndText(numText,string.replace(ccClientText(12176),num))
	CS.ShowObject(textImg,false)
	local nameTitle = ""
	if relationType == 1 then
		nameTitle = ccClientText(12172)
	elseif relationType == 2 then
		nameTitle = ccClientText(12173)
	elseif relationType == 3 then
		nameTitle = ccClientText(12174)
	elseif relationType == 4 then
		nameTitle = ccClientText(12175)
	end
	self:SetWndText(nameText,itemdata.playerName..nameTitle)

	local textStr = ""
	for i, v in ipairs(self._numTimes) do
		local min = v.min
		local max = v.max
		local img = v.img
		if min <= num and (num <= max or max == -1) then
			textStr = img
			break
		end
	end
	if textStr ~= "" then
		CS.ShowObject(textImg,true)
		self:SetWndEasyImage(textImg,textStr)
	end

	local playerData = {
		trans = headIcon,
		icon = itemdata.head,
		headFrame = itemdata.headFrame,
		level = itemdata.level,
	}
	local uiheadlist = self._uiheadList
	local InstanceID = item:GetInstanceID()
	local baseClass = uiheadlist[InstanceID]
	if not baseClass then
		baseClass = HeadIcon:New(self)
		uiheadlist[InstanceID] = baseClass
	end
	baseClass:SetHeadData(playerData)
	baseClass:RefreshUI()

	self:SetWndClick(headIcon, function(...) self:OnClickHeadIcon(itemdata.playerId) end)
end

function UITaLayePop:GetShowLayerList()
	local list = {}
	if self._openType == UITaLayePop.TYPE_TOWER then
		list = gModelTower:GetTypeTowerLayersByRefId(self._towerType,self._refId)
		table.sort(list,function (a,b)
			local aMe = a.towerType == 1 and 1 or 0
			local bMe = b.towerType == 1 and 1 or 0
			if aMe ~= bMe then
				return aMe > bMe
			end
			if a.num ~= b.num then
				return a.num > b.num
			end
			return a.playerId < b.playerId
		end)
	elseif self._openType == UITaLayePop.TYPE_BOSSTOWER then
		-- local bossTowerList = gModelBossTower:GetBossTowerInsLayerInfoBySidAndInsRefId(self._sid,self._insLayer) or {}
		-- for k,v in pairs(bossTowerList) do
		-- 	table.insert(list,v)
		-- end
		-- table.sort(list,function(a,b)
		-- 	return a.relationType < b.relationType
		-- end)
	end
	return list
end

function UITaLayePop:InitBossTowerData()
	-- self._sid = self:GetWndArg("sid")
	-- self._insLayer = self:GetWndArg("insLayer")
	-- if not self._sid then return end
	-- gModelBossTower:OnBossTowerInsLayerReq(self._sid)
	-- local name = gModelBossTower:GetBossTowerInsNameByRefId(self._insLayer)
	-- self:SetWndText(self.mLblBiaoti,name)
end

function UITaLayePop:OnClickHeadIcon(playerId)
	gModelGeneral:PlayerShowReq(playerId, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
end

function UITaLayePop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.TowerTypePlayerResp,function (...)
		if self._openType ~= UITaLayePop.TYPE_TOWER then return end
		self:RefreshDate()
	end)
	-- self:WndNetMsgRecv(LProtoIds.BossTowerInsLayerResp,function (...)
	-- 	if self._openType ~= UITaLayePop.TYPE_BOSSTOWER then return end
	-- 	self:RefreshDate()
	-- end)
end

function UITaLayePop:RefreshDate()
	local list = self:GetShowLayerList()

	local onDrawItemFunc
	if self._openType == UITaLayePop.TYPE_TOWER then
		onDrawItemFunc = function(...)
			self:ListItem(...)
		end
	elseif self._openType == UITaLayePop.TYPE_BOSSTOWER then
		-- onDrawItemFunc = function(...)
		-- 	self:OnDrawBossTowerCell(...)
		-- end
	end

	local _cellSuper = self._uiCellSuper
	if _cellSuper then
		_cellSuper:RefreshList(list)
	else
		_cellSuper = self:GetUIScroll("mCellSuper")
		_cellSuper:Create(self.mCellSuper,list,function (...) onDrawItemFunc(...)  end,UIItemList.SUPER)
		UIItemList:EnableScroll(true,false)
		self._uiCellSuper = _cellSuper
	end
	_cellSuper:DrawAllItems()
end

function UITaLayePop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
end

function UITaLayePop:InitCommand()
	self._towerType = self:GetWndArg("towerType") or ModelTower.RACE_COM
	self._refId = self:GetWndArg("refId") or 1
	self:SetWndText(self.mLblBiaoti,ccClientText(12171))

	local numTimes = gModelTower:GetTowerConfigRefByKey("numTimes")
	local arr = string.split(numTimes,";")
	local list = {}
	for i, v in ipairs(arr) do
		local vs = string.split(v,"=")
		local as = string.split(vs[1],",")
		if as[1] then
			table.insert(list,{ min = tonumber(as[1]), max = tonumber(as[2]), img = vs[2], })
		end
	end
	self._numTimes = list
	self:RefreshDate()
end

function UITaLayePop:OnDrawBossTowerCell(list,item,itemdata,itempos)
	-- local root = self:FindWndTrans(item,"Root")
	-- local nameText = self:FindWndTrans(root,"TiBgImage/NameText")
	-- local headIcon = self:FindWndTrans(root,"HeadIcon")
	-- local serverText = self:FindWndTrans(root,"ServerText")
	-- local powerText = self:FindWndTrans(root,"PowerBg_1/PowerText")
	-- local textImg = self:FindWndTrans(root,"TextImg")
	-- local NumBg = self:FindWndTrans(root,"NumBg")
	-- local numText = self:FindWndTrans(NumBg,"NumText")
	-- local relationType = itemdata.relationType
	-- local playerInfo = itemdata.playerInfo

	-- CS.ShowObject(NumBg,false)
	-- self:SetWndText(serverText,gModelFriend:GetSevenName(playerInfo.serverId))
	-- self:SetWndText(powerText,LUtil.NumberCoversion(playerInfo.power))

	-- local nameTitle = ""
	-- if relationType == 1 then
	-- 	nameTitle = ccClientText(12172)
	-- elseif relationType == 2 then
	-- 	nameTitle = ccClientText(12173)
	-- elseif relationType == 3 then
	-- 	nameTitle = ccClientText(12174)
	-- elseif relationType == 4 then
	-- 	nameTitle = ccClientText(12175)
	-- end
	-- self:SetWndText(nameText,playerInfo.name..nameTitle)

	-- local playerData = {
	-- 	trans = headIcon,
	-- 	icon = playerInfo.head,
	-- 	headFrame = playerInfo.headFrame,
	-- 	level = playerInfo.grade,
	-- }
	-- local uiheadlist = self._uiheadList
	-- local InstanceID = item:GetInstanceID()
	-- local baseClass = uiheadlist[InstanceID]
	-- if not baseClass then
	-- 	baseClass = HeadIcon:New(self)
	-- 	uiheadlist[InstanceID] = baseClass
	-- end
	-- baseClass:SetHeadData(playerData)
	-- baseClass:RefreshUI()
end
------------------------------------------------------------------
return UITaLayePop


