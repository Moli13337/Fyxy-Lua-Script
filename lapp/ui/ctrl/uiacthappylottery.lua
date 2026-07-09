---
--- Created by BY.
--- DateTime: 2023/10/20 16:46:08
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActHappyLottery:LWnd
local UIActHappyLottery = LxWndClass("UIActHappyLottery", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActHappyLottery:UIActHappyLottery()
	self._tabTransList = {}
	self._redTrList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActHappyLottery:OnWndClose()

	if self._feedOpen then
		GF.OpenWnd("UIMinEntranceList")
		local targetId = self:GetWndArg("targetId")
		if targetId then
			targetId = tostring(targetId)
			local parentUniJump = string.gsub(targetId,"^120","85")
			parentUniJump = checknumber(parentUniJump)
			local sid = gModelActivity:GetSidByUniqueJump(parentUniJump)
			if sid then
				gModelActivity:CommonActJump(sid)
			end
		end
		FireEvent(EventNames.ON_CHECK_SUBSCRIBE_FEED_CLEANTAR)
	end
	
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActHappyLottery:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActHappyLottery:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitDate()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UIActHappyLottery:OpenHappy(entry,pages)
	self:CreateChildWnd(self.mChildRoot,"WndChildHappyLottery",{sid = self._sid})
end
function UIActHappyLottery:InitCommand()
	local feedOpen = self:GetWndArg("feedOpen")
	self._feedOpen = feedOpen
	if feedOpen then
		LogWarn("正在直流")
	else
		LogWarn("bu 在直流")
	end

	local _sid = self:GetWndArg("sid")
	self._page = self:GetWndArg("page") or 1 --支持跳转
	local _subPage = self:GetWndArg("subPage")
	if _subPage then
		_sid = gModelActivity:GetSidByUniqueJump(_subPage)
	end
	self._sid = _sid
	gModelActivity:ReqActivityConfigData(_sid)
end
function UIActHappyLottery:InitDate()
	self._modelOpenFunc = {
		[ModelActivity.HappyLottery_1] = function(...) self:OpenExclusive(...) end,
		[ModelActivity.HappyLottery_2] = function(...) self:OpenHappy(...) end,
	}
	self._anchors = {
		[1] = Vector2(0,1),
		[2] = Vector2(0.5,1),
		[3] = Vector2(1,1),
		[4] = Vector2(0,0.5),
		[5] = Vector2(0.5,0.5),
		[6] = Vector2(1,0.5),
		[7] = Vector2(0,0),
		[8] = Vector2(0.5,0),
		[9] = Vector2(1,0),
	}

	self:SetTextTile(self.mReturnBtn, ccClientText(30205))-- 返回
end

function UIActHappyLottery:OnTryTcpReconnect()
	self:WndClose()
end
function UIActHappyLottery:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:OnActivityConfigData()
	end)
	self:WndEventRecv(EventNames.ON_JUMP, function(...) self:WndClose() end)
	self:WndEventRecv(EventNames.ON_RED_CHANGE, function(...) self:RefreshRed() end)
end
---打开子界面
function UIActHappyLottery:OpenActivityChildWnd(pageId,pos)
	local oldPageId = self._pageId
	if oldPageId and oldPageId == pageId then
		return
	end
	if pageId == 0 then
		self:OnClickClose()
		return
	end
	local openFunc = self._modelOpenFunc[pageId]
	if openFunc then
		self:CloseAllChild()
		for i, v in pairs(self._tabTransList) do
			if i ~= pageId then
				self:ChangeTab(v,false)
			else
				self:ChangeTab(v,true)
			end
		end
		self._pageId = pageId
		openFunc()
		self._pos = pos
		self:SaveWndArg()
	end
end
function UIActHappyLottery:RefreshRed()
	local _redTrList = self._redTrList or {}
	local list1 = {
		ModelActivity.HappyLottery_1,
	}
	local list2 = {
		ModelActivity.HappyLottery_2,
	}
	local entry1Red = self:GetRedByList(list1)
	local entry2Red = self:GetRedByList(list2)

	CS.ShowObject(_redTrList[ModelActivity.HappyLottery_1],entry1Red)
	CS.ShowObject(_redTrList[ModelActivity.HappyLottery_2],entry2Red)
end

function UIActHappyLottery:ListItem(list,item, itemdata, itempos)
	local image = CS.FindTrans(item,"Image")
	local icon = CS.FindTrans(item,"Icon")
	local nameText = CS.FindTrans(item,"NameText")
	local redPoint = CS.FindTrans(item,"redPoint")
	local pageId = itemdata.pageId
	self._tabTransList[pageId] = item
	self._redTrList[pageId] = redPoint
	self:SetWndEasyImage(image,itemdata.icon1,nil,true)
	self:SetWndEasyImage(icon,itemdata.icon2,nil,true)
	self:SetWndText(nameText,itemdata.name)
	self:SetWndClick(item,function ()
		self:OpenActivityChildWnd(pageId,itempos)
	end)
end
function UIActHappyLottery:InitEvent()
	self:SetWndClick(self.mReturnBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIActHappyLottery:OpenExclusive(entry,pages)
	self:CreateChildWnd(self.mChildRoot,"UISubExclusiveLottery",{sid = self._sid})
end
function UIActHappyLottery:SaveWndArg()
	local wndArg = self:GetWndArgList() or {}
	wndArg["page"] = self._pos or 1
	self:SetWndArg(wndArg)
end
function UIActHappyLottery:ChangeTab(trans,bool)
	local image = CS.FindTrans(trans,"Image")
	local icon = CS.FindTrans(trans,"Icon")
	local onImage = CS.FindTrans(trans,"OnImage")
	local nameText = CS.FindTrans(trans,"NameText")
	local color
	if bool then
		color = "ffffffff"
	else
		color = "b9c9ebff"
	end
	color = LUtil.ColorByHex(color)
	local xuitxt = self:FindWndText(nameText)
	self:SetXUITextColor(xuitxt,color)
	CS.ShowObject(onImage,bool)
	CS.ShowObject(icon,bool)
	CS.ShowObject(image,not bool)
end
function UIActHappyLottery:RefreshData()
	local btnIcon = self._btnIcon
	if string.isempty(btnIcon) then return end

	local btnArr = string.split(btnIcon,"|")
	local list = {}
	for i, v in ipairs(btnArr) do
		local switchArr = string.split(v,"=")
		local _data =
		{
			pageId = tonumber(switchArr[1]),
			icon1 = switchArr[2],
			icon2 = switchArr[3],
			name = switchArr[4],
		}
		table.insert(list,_data)
	end

	local _uiTabList = self._uiTabList
	if _uiTabList then
		_uiTabList:RefreshList(list)
	else
		_uiTabList = self:GetUIScroll("tabList")
		self._uiTabList = _uiTabList
		_uiTabList:Create(self.mTabScroll,list,function (...) self:ListItem(...) end)
	end
	self:RefreshRed()

	local _page = self._page
	if _page then
		self._pageId = nil
		if _page > 0 then
			self:OpenActivityChildWnd(list[_page].pageId,_page)
		else
			self:OpenActivityChildWnd(list[1].pageId,1)
		end
		self._page = nil
	end
end
function UIActHappyLottery:GetRedByList(list)
	for i, v in ipairs(list) do
		local red = gModelRedPoint:GetActivityRedPointPage(self._sid,v)
		if red then
			return true
		end
	end
	return false
end
function UIActHappyLottery:OnActivityConfigData()
	local sid = self._sid
	local activityData = gModelActivity:GetWebActivityDataById(sid)
	local data = activityData.config

	local GeneralBg = data.generalBg
	self._btnIcon = data.btnIcon
	local closeBtn,closeText,btnIconShow
	= data.closeBtn,data.closeText,data.btnIconShow

	if LxUiHelper.IsImgPathValid(GeneralBg) then
		self:SetWndEasyImage(self.mBg,GeneralBg)
	end
	if not string.isempty(closeBtn) then
		local paint
		local arr = string.split(closeBtn,"=")
		local anchorType = tonumber(arr[1]) or 0
		local imgStr = arr[2]
		local posStr = arr[3]
		if not posStr then
			posStr = arr[2]
			imgStr = arr[1]
			anchorType = 5
		end
		if LxUiHelper.IsImgPathValid(imgStr) then
			paint = self.mBtnClose
			self:SetWndEasyImage(paint,imgStr,function ()
				CS.ShowObject(paint,true)
			end ,true)
		end
		if anchorType >= 1 and anchorType <= 9 and paint then
			local anchorV = self._anchors[anchorType]
			self:SetTrAnchors(paint,anchorV)
		end
		if not string.isempty(posStr) and paint then
			local pos = LxDataHelper.ParseVector2NotEmpty3(posStr)
			self:SetAnchorPos(paint, pos)
		end
	else
		CS.ShowObject(self.mBtnClose,true)
	end
	if not string.isempty(closeText) then
		local paint = self.mCloseText
		local arr = string.split(closeText,"=")
		local text = arr[1]
		local posStr = arr[2]
		self:SetWndText(paint,text)
		CS.ShowObject(paint,true)
		if not string.isempty(posStr)then
			local pos = LxDataHelper.ParseVector2NotEmpty3(posStr)
			self:SetAnchorPos(paint, pos)
		end
	end
	self:RefreshData()
	if btnIconShow and btnIconShow == 0 then
		CS.ShowObject(self.mTabScroll,false)
	end
end
------------------------------------------------------------------
return UIActHappyLottery


