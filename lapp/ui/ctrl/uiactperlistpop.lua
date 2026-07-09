---
--- Created by BY.
--- DateTime: 2023/10/5 15:51:12
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActPerListPop:LWnd
local UIActPerListPop = LxWndClass("UIActPerListPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActPerListPop:UIActPerListPop()
	self._uiheadList = {}
	self._model = 0
	self._listIndex = 1
	self._listNum = 30
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActPerListPop:OnWndClose()
	self:ClearCommonIconList(self._uiheadList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActPerListPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActPerListPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIActPerListPop:ListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local headIcon = self:FindWndTrans(root,"HeadIcon")
	local nameText = self:FindWndTrans(root,"NameText")

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
	local nameStr = ""
	if itemdata.gender == 1 then
		nameStr = string.replace(ccClientText(11148),itemdata.name)
	else
		nameStr = string.replace(ccClientText(11147),itemdata.name)
	end
	self:SetWndText(nameText,nameStr)
	self:SetWndClick(headIcon,function ()
		gModelGeneral:PlayerShowReq(itemdata.pid, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
	end)
end

function UIActPerListPop:InitMessage()
	--self:WndNetMsgRecv(LProtoIds.ActivityFigurePositionListResp,function (pb)
	--	local model = pb.model      --活动模板
	--	local index = pb.index      --列表下标（1开始）
	--	local infos = pb.infos      --列表数据
	--
	--	local list = self._playerList or {}
	--	for i, v in ipairs(infos) do
	--		local info = gModelActivity:GenerateStructActivityVillainPositionInfoDataFromPb(v)
	--		table.insert(list,info)
	--	end
	--	local len = #list
	--	self._listIndex = len + 1
	--	self._playerList = list
	--	self:RefreshData()
	--end)
	self:WndEventRecv(EventNames.ON_JUMP, function(...) self:WndClose() end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:OnActivityConfigData()
	end)
end

function UIActPerListPop:NexReqList()
	gModelActivity:OnActivityFigurePositionListReq(self._model,self._listIndex,self._listNum)
end

function UIActPerListPop:OnTryTcpReconnect()
	self:WndClose()
end

function UIActPerListPop:InitCommand()
	self:SetWndText(self.mTitleText,ccClientText(24709))
	local _sid = self:GetWndArg("sid")
	local _page = self:GetWndArg("page") --支持跳转
	local _subPage = self:GetWndArg("subPage")
	if _subPage then
		_sid = gModelActivity:GetSidByUniqueJump(_subPage)
	end
	self._sid = _sid
	local activityData = gModelActivity:GetActivityBySid(_sid)
	if not activityData then return end
	local sum = gModelActivity:GetActivitySumByModel(activityData.model)
	self:SetWndText(self.mDesText,string.replace(ccClientText(24708),sum))
	local model = activityData.model
	self._model = model
	self:NexReqList()
	gModelActivity:ReqActivityConfigData(_sid)
end

function UIActPerListPop:RefreshData()
	local list = self._playerList or {}

	local _uiCellList = self._uiCellList
	if _uiCellList then
		_uiCellList:RefreshList(list)
	else
		_uiCellList = self:GetUIScroll("UIActPerListPop")
		_uiCellList:Create(self.mCellSuper,list,function (...) self:ListItem(...) end,UIItemList.SUPER_GRID)
		_uiCellList:EnableScroll(true,false)
		self._uiCellList = _uiCellList
	end
	_uiCellList:DrawAllItems()
	local uiList = _uiCellList:GetList()
	uiList:SetFuncOnItemReachTail(function (bool)
		if bool then
			self:NexReqList()
		end
	end)
end

function UIActPerListPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)

end

function UIActPerListPop:OnActivityConfigData()
	local activityData = gModelActivity:GetWebActivityDataById(self._sid)
	local data = activityData.config

	local meetHeroImg = data.meetHeroImg
	local meetHeroPos = data.meetHeroPos
	if not string.isempty(meetHeroImg)then
		local _parent
		local arr = string.split(meetHeroImg,"=")
		if arr[1] == "1" then
			_parent = self.mHeroImg
			self:SetWndEasyImage(_parent,arr[2],nil,true)
		elseif arr[1] == "2" then
			_parent = self.mHeroLiHui
			self:CreateWndSpine(_parent,arr[2],"HeroLiHui",false)
		end
		CS.ShowObject(_parent,true)
		if not string.isempty(meetHeroPos)then
			local arr = string.split(meetHeroPos,"|")
			_parent.anchoredPosition = Vector3(tonumber(arr[1]),tonumber(arr[2]),0)
		end
	end
end
------------------------------------------------------------------
return UIActPerListPop


