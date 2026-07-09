---
--- Created by BY.
--- DateTime: 2023/10/25 21:26:03
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubAreaCareer:LChildWnd
local UISubAreaCareer = LxWndClass("UISubAreaCareer", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubAreaCareer:UISubAreaCareer()
	self._tabList = {}
	self._headBaseClass = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubAreaCareer:OnWndClose()
	self:ClearCommonIconList(self._headBaseClass)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubAreaCareer:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubAreaCareer:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UISubAreaCareer:OnClickPlayer(playerInfo)
	gModelGeneral:PlayerShowReq(playerInfo._playerId, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
end

function UISubAreaCareer:RefreshCareer()
	if self._isOneCareer then
		local _playerInfo = self._playerInfo
		gModelPlayerSpace:OnAdventureCareerInfoReq(_playerInfo._playerId)
		self._isOneCareer = false
		return
	end
	local careerInfo = gModelPlayerSpace:GetCareerInfo()
	local careerList = careerInfo.careerList or {}
	self._shieldList = careerInfo.shieldList
	local list = {}
	for i, v in pairs(careerList) do
		table.insert(list,{type = 1,refId = i})
		for j, k in pairs(v) do
			table.insert(list,{type = 2,list = k})
		end
	end
	local _uiList = self._careerList
	if _uiList then
		_uiList:RefreshList(list)
		local _uiListSuper = _uiList:GetList()
		_uiListSuper:DrawAllItems()
	else
		_uiList = self:GetUIScroll("careerCell")
		_uiList:Create(self.mCareerSuper,list,function (...) self:CareerListItem(...) end,UIItemList.SUPER)
		self._careerList = _uiList
	end
end

function UISubAreaCareer:SubListItem(list,item, itemdata, itempos)
	local desText = CS.FindTrans(item,"DesText")
	local numText = CS.FindTrans(item,"Image2/NumText")

	local ref = itemdata.careerRef
	local showType = ref.showType
	local desStr,numStr = "",""
	if showType == 1 then
		local params = tonumber(itemdata.params)
		local sign = ref.sign
		if sign == 1 then
			local ref = gModelHero:GetCareerRefByRefId(params)
			numStr = ccLngText(ref.name)
		elseif sign == 2 then
			local ref = gModelHero:GetHeroRaceRefByRefId(params)
			numStr = ccLngText(ref.name)
		elseif sign == 3 then
			numStr = params/10 .. "%"
		elseif sign == 4 then
			local ref = gModelGrade:GetGradeLvRefByRefId(params)
			numStr = ccLngText(ref.name)
		elseif sign == 5 then
			local ref = gModelCrossGrading:GetCrossGradingIntervalByRefId(params)
			numStr = ccLngText(ref.name)
		elseif sign == 6 then
			if not string.isempty(itemdata.params)then
				local arr = string.split(itemdata.params,"|")
				local name = ccLngText(arr[1])
				local rank = arr[2]
				local desc = ccLngText(ref.desc)
				if not string.isempty(desc) then
					numStr = string.replace(desc,name,rank)
				else
					numStr = string.format("%s%s",name,rank)
				end
			else
				numStr = ccClientText(11837)
			end
		elseif sign == 7 then
			if itemdata.params == "0" then
				numStr = ccClientText(11837)
			else
				local desc = ccLngText(ref.desc)
				numStr = string.replace(desc,itemdata.params)
			end
		else
			numStr = LUtil.NumberCoversion(tonumber(itemdata.params))
		end
		desStr = ccLngText(ref.description)

	else
		if itemdata.params ~= "" then
			local itemInfo = LxDataHelper.ParseItem_3(itemdata.params)
			desStr = string.replace(ccLngText(ref.description),gModelItem:GetItemNameRichText(itemInfo.itemId))
			numStr = LUtil.NumberCoversion(itemInfo.itemNum)
		else
			desStr = ""
			numStr = ""
		end
	end
	self:SetWndText(desText,desStr)
	self:SetWndText(numText,numStr)
end

function UISubAreaCareer:ListItem(list,item, itemdata, itempos)
	local btnTab2 = CS.FindTrans(item,"BtnTab9")
	self._tabList[itemdata.type] = btnTab2
	self:SetWndTabText(btnTab2,itemdata.title)
	self:SetWndTabStatus(btnTab2, 1)
	self:SetWndClick(item,function ()
		self:OnClickTab(itemdata.type)
	end)
end

--设置头像
function UISubAreaCareer:SetHeadIcon(item,playerInfo)
	local InstanceID = item:GetInstanceID()
	local baseClass = self._headBaseClass[InstanceID]
	if baseClass then
		baseClass:SetHeadData(playerInfo)
		baseClass:RefreshUI()
	else
		baseClass = HeadIcon:New(self)
		baseClass:SetHeadData(playerInfo)
		baseClass:RefreshUI()
		self._headBaseClass[InstanceID] = baseClass
	end
end

function UISubAreaCareer:LogListItem(list,item, itemdata, itempos)
	local image = CS.FindTrans(item,"Image")
	local titleText = CS.FindTrans(item,"Image/TitleText")
	local desText = CS.FindTrans(item,"DesText")

	CS.ShowObject(image,true)
	CS.ShowObject(desText,true)
	local timeStr,desStr = "",""
	if itemdata.type and itemdata.type == 1 then
		timeStr = ccClientText(21157)
		desStr = ccClientText(21158)
	elseif itemdata.type and itemdata.type == 2 then
		CS.ShowObject(image,false)
		CS.ShowObject(desText,false)
		LxUiHelper.SetSizeWithCurAnchor(item,1,100)
		return
	else
		local y,m,d = LUtil.GetYmdByTimestamp(itemdata.time)
		timeStr = string.format("%s.%s.%s",y,m,d)
		local ref = gModelPlayerSpace:GetRoleAdventureLogRefByRefId(itemdata.refId)
		desStr = LUtil.GetReplacedContent(ccLngText(ref.description),itemdata.params,ref.shiftNumIndex)
	end
	self:SetWndText(desText,desStr)
	self:SetWndText(titleText,timeStr)
	self:SetWndText(self.mTestText,desStr)

	local height = self.mTestText.preferredHeight
	LxUiHelper.SetSizeWithCurAnchor(item,1,(height + 50))
end

function UISubAreaCareer:SetPlayer(item,itemdata)
	local headIcon = CS.FindTrans(item,"HeadIcon")
	local vipBg = CS.FindTrans(item,"VipBg")
	local vipText = CS.FindTrans(item,"VipBg/VipText")
	local nameText = CS.FindTrans(item,"NameText")
	local numText = CS.FindTrans(item,"NumText")
	local click = CS.FindTrans(item,"Click")
	CS.ShowObject(vipBg,false)
	local ref = itemdata.careerRef
	local player = itemdata.playerInfo
	local shieldInfo = player.shieldInfo or "0|0"
	shieldInfo = string.split(shieldInfo,"|")
	local isShowVip = shieldInfo[1] and shieldInfo[1] == "0"

	if not player or player._playerId == 0 then
		self:SetWndClick(click,function ()

		end)
		self:SetWndText(nameText,ccClientText(12137))
		return
	end
	self:SetHeadIcon(item,{
		trans = headIcon,
		icon = player._head,
		headFrame = player._headFrame,
		level = player._grade,
	})
	local _vipLevel = player._vipLevel
	if _vipLevel > 0 then
		local vipStr = ""
		if isShowVip then
			local vipLvRef = gModelVip:GetRefByVipLv(_vipLevel)
			if vipLvRef then
			else
				self:SetWndEasyImage(vipBg,"mainui_bg_vip",function()
					CS.ShowObject(vipBg,true)
				end,true)
				vipStr = LUtil.FormatHurtNumSpriteText(player._vipLevel)
			end
		else
			self:SetWndEasyImage(vipBg,"mainui_bg_vip_v",function()
				CS.ShowObject(vipBg,true)
			end,true)
		end
		self:SetWndText(vipText,vipStr)
	end
	self:SetWndText(nameText,player._name)
	self:SetWndText(numText,string.replace(ccLngText(ref.description),itemdata.params))
	self:SetWndClick(click,function ()
		self:OnClickPlayer(player)
	end)
end

function UISubAreaCareer:InitMessage()
	self:WndNetMsgRecv(LProtoIds.AdventureLogInfoResp,function (...)
		self:RefreshLog(...)
	end)
	self:WndNetMsgRecv(LProtoIds.AdventureCareerInfoResp,function (...)
		self:RefreshCareer(...)
	end)
	self:WndNetMsgRecv(LProtoIds.AdventureCareerShieldResp,function (pb)
		local type = pb.type
		local refId = pb.refId
		if type == 1 then
			local ref = gModelPlayerSpace:GetRoleAdventureCareerSubtypeRefByRefId(refId)
			GF.ShowMessage(string.replace(ccClientText(21178),ccLngText(ref.name)))
		end
		self:RefreshCareer()
	end)
end

function UISubAreaCareer:OnClickTab(type)
	if self._type then
		if self._type == type then
			return
		end
		self:SetWndTabStatus(self._tabList[self._type], 1)
	end
	self._type = type
	self:SetWndTabStatus(self._tabList[type], 0)

	CS.ShowObject(self.mCareerMar,false)
	CS.ShowObject(self.mLogMar,false)
	if type == 1 then
		CS.ShowObject(self.mCareerMar,true)
		self:RefreshCareer()
		self:SetWndEasyImage(self.mTitleImg,"role_career_txt_1",nil,true)
	else
		CS.ShowObject(self.mLogMar,true)
		self:RefreshLog()
		self:SetWndEasyImage(self.mTitleImg,"role_career_txt_2", nil, true)
	end
end

function UISubAreaCareer:InitEvent()

end

function UISubAreaCareer:InitCommand()
	local page = self:GetWndArg("page") or 1
	local _currInfo = gModelPlayerSpace:GetCurrSpaceInfo()
	if _currInfo then
		self._isMe = _currInfo.isMe
		self._playerInfo = _currInfo.playerInfo
	else
		return
	end

	self._isOneCareer = true
	self._isOneLog = true

	local list = {
		{type = 1 ,title = ccClientText(21125)},
		{type = 2 ,title = ccClientText(21126)}
	}
	local _uiList = self:GetUIScroll("CareerType")
	_uiList:Create(self.mTabScroll,list,function (...) self:ListItem(...) end)
	self:OnClickTab(list[page].type)
	local serverName = gModelFriend:GetSevenName(self._playerInfo._serverId)
	self:SetWndText(self.mPlayerNameText,string.replace(ccClientText(21160),serverName,self._playerInfo._name))
end

function UISubAreaCareer:CareerListItem(list,item, itemdata, itempos)
	local root1 = CS.FindTrans(item,"Root1")
	local root2 = CS.FindTrans(item,"Root2")
	local InstanceID = item:GetInstanceID()

	CS.ShowObject(root1,false)
	CS.ShowObject(root2,false)

	local type = itemdata.type
	if type == 1 then
		CS.ShowObject(root1,true)
		local titleText = CS.FindTrans(root1,"TitleBg/TitleText")
		local ref = gModelPlayerSpace:GetRoleAdventureCareerTypeRefByRefId(itemdata.refId)
		self:SetWndText(titleText,ccLngText(ref.name))
		LxUiHelper.SetSizeWithCurAnchor(item,1,36)
	else
		CS.ShowObject(root2,true)
		local titleText = CS.FindTrans(root2,"TitleBg/TitleText")
		local showToggle = CS.FindTrans(root2,"ShowToggle")
		local checkmark = CS.FindTrans(root2,"ShowToggle/Background/Checkmark")
		local toggleText = CS.FindTrans(root2,"ShowToggle/ToggleText")
		local player1 = CS.FindTrans(root2,"Player1")
		local player2 = CS.FindTrans(root2,"Player2")
		local player3 = CS.FindTrans(root2,"Player3")
		local cellSuper = CS.FindTrans(root2,"CellSuper")
		local showBg = CS.FindTrans(root2,"ShowBg")
		local showText = CS.FindTrans(root2,"ShowBg/ShowText")
		local _playerList = {
			[1] = player1,
			[2] = player2,
			[3] = player3
		}
		for i, v in ipairs(_playerList) do
			CS.ShowObject(v,false)
		end
		local list = itemdata.list
		local ref = gModelPlayerSpace:GetRoleAdventureCareerSubtypeRefByRefId(list.typeId)
		local hide = ref.hide == 1 and self._isMe
		CS.ShowObject(showToggle,hide)

		if hide then
			self:SetWndText(toggleText,ccClientText(21150))
		end
		local titleName = ccLngText(ref.name)
		self:SetWndText(titleText,titleName)

		local isHide = self._shieldList[ref.refId]
		CS.ShowObject(checkmark,isHide)
		CS.ShowObject(showBg,isHide and not self._isMe)
		self:SetWndClick(showToggle,function ()
			gModelPlayerSpace:OnAdventureCareerShieldReq(isHide and 0 or 1,ref.refId)
		end)
		CS.ShowObject(cellSuper,not isHide or self._isMe )
		if isHide and not self._isMe then
			self:SetWndText(showText,ccClientText(21151))
			LxUiHelper.SetSizeWithCurAnchor(item,1,80)
			return
		end

		local _rankList = {}
		local _itemList = {}
		for i, v in ipairs(list) do
			local careerRef = v.careerRef
			if careerRef.showType == 2 then
				table.insert(_rankList,v)
			else
				table.insert(_itemList,v)
			end
		end
		local h = 0
		local isShowRank = #_rankList > 0
		if isShowRank then
			h = h + 288
			for i, v in ipairs(_rankList) do
				CS.ShowObject(_playerList[i],true)
				self:SetPlayer(_playerList[i],v)
			end
		end
		if #_itemList > 0 then
			local list = {}
			for i, v in ipairs(_itemList) do
				local ref = v.careerRef
				if ref.showType == 3 then
					local paramsArr = string.split(v.params,",")
					for j, k in ipairs(paramsArr) do
						table.insert(list,{careerRef = ref,params = k,refId = v.refId})
					end
				else
					table.insert(list,v)
				end
			end
			_itemList = list
			if isShowRank then
				h = h - 43
			end
			local num = #_itemList
			local listH = 0
			if num > 0 then
				listH = num * 44 - 10
			end
			h = h + 45 + listH
		end
		table.sort(_itemList,function (a,b)
			return a.careerRef.sort < b.careerRef.sort
		end)
		cellSuper.anchoredPosition = Vector2.New(0,isShowRank and -290 or -45)
		local _uiList = self:GetUIScroll(InstanceID)
		local _uiListSuper = _uiList:GetList()
		if _uiListSuper then
			_uiList:RefreshList(_itemList)
			--_uiListSuper:DrawAllItems()
		else
			_uiList:Create(cellSuper,_itemList,function (...) self:SubListItem(...) end)
			_uiList:EnableScroll(false)
		end

		LxUiHelper.SetSizeWithCurAnchor(item,1,h)
	end
end

function UISubAreaCareer:RefreshLog()
	if self._isOneLog then
		local _playerInfo = self._playerInfo
		gModelPlayerSpace:OnAdventureLogInfoReq(_playerInfo._playerId)
		self._isOneLog = false
		return
	end
	local list = gModelPlayerSpace:GetLogList()
	table.sort(list,function(a,b)
		return a.time < b.time
	end)
	table.insert(list,{type = 1})
	table.insert(list,{type = 2})
	local _uiList = self._logList
	if _uiList then
		_uiList:RefreshList(list)
		--local _uiListSuper = _uiList:GetList()
		--_uiListSuper:DrawAllItems()

	else
		_uiList = self:GetUIScroll("LogCell")
		_uiList:Create(self.mLogSuper,list,function (...) self:LogListItem(...) end,UIItemList.SUPER)
		self._logList = _uiList
	end
	local _uiListSuper = _uiList:GetList()
	_uiListSuper:MoveToPos(#list)
end
------------------------------------------------------------------
return UISubAreaCareer


