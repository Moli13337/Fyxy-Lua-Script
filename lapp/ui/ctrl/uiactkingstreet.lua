---
--- Created by BY.
--- DateTime: 2023/10/6 11:31:01
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActKingStreet:LWnd
local UIActKingStreet = LxWndClass("UIActKingStreet", LWnd)

UIActKingStreet.Entry_1 = 1		--入口
UIActKingStreet.Entry_2 = 2
UIActKingStreet.Entry_3 = 3
UIActKingStreet.Entry_4 = 4

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActKingStreet:UIActKingStreet()
	self._tabTransList = {}
	self._redList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActKingStreet:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActKingStreet:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActKingStreet:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitDate()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIActKingStreet:OnClickClose()
	self:WndClose()
end

function UIActKingStreet:RefreshData()
	local list = self._tabList or {}

	local _page = self._page
	if _page then
		if _page > 0 then
			self:OpenActivityChildWnd(list[_page].pageId)
			self._page = nil
		else
			self:OpenActivityChildWnd(list[1].pageId)
		end
	end
	local _redTrList = self._redList
	local entryRed1 = self:GetReturnRed(ModelActivity.KING_STREET_1) or self:GetReturnRed(ModelActivity.KING_STREET_2)
	local entryRed3 = self:GetReturnRed(ModelActivity.KING_STREET_4) or self:GetReturnRed(ModelActivity.KING_STREET_5) or self:GetReturnRed(ModelActivity.KING_STREET_9)
	CS.ShowObject(_redTrList[UIActKingStreet.Entry_3],entryRed1)
	CS.ShowObject(_redTrList[UIActKingStreet.Entry_1],self:GetReturnRed(ModelActivity.KING_STREET_3))
	CS.ShowObject(_redTrList[UIActKingStreet.Entry_2],entryRed3)
end
function UIActKingStreet:OpenTask(entry)
	self:CreateChildWnd(self.mChildRoot,"UISubLikingTk",{sid = self._sid,entry = entry,pages = self.pages})
end

function UIActKingStreet:GetReturnRed(pageId)
	return gModelRedPoint:GetActivityRedPointPage(self._sid,pageId)
end
function UIActKingStreet:OpenCall(entry)
	self:CreateChildWnd(self.mChildRoot,"UISubKingStreetSummon",{sid = self._sid,entry = entry,pages = self.pages})
end

function UIActKingStreet:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		self:ResetData(pb)
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function (pb)
		self:RefreshData()
	end)
	self:WndEventRecv(EventNames.ON_RED_CHANGE, function(...) self:RefreshData() end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:OnActivityConfigData()
	end)
	self:WndEventRecv(EventNames.ON_JUMP, function(...) self:WndClose() end)
end

function UIActKingStreet:InitCommand()
	local sid = self:GetWndArg("sid")
	self._page = self:GetWndArg("page") or 1--支持跳转
	local _subPage = self:GetWndArg("subPage")
	if _subPage then
		sid = gModelActivity:GetSidByUniqueJump(_subPage)
	end
	local modelId = gModelActivity:GetActivityModeIdBySid(sid)
	self._modelId = modelId
	self._sid = sid
	gModelActivity:ReqActivityConfigData(sid)
end

function UIActKingStreet:OnTryTcpReconnect()
	self:WndClose()
end

function UIActKingStreet:OpenGift(entry)
	self:CreateChildWnd(self.mChildRoot,"UISubFixedOptionalGift",{sid = self._sid,entry = entry,pages = self.pages})
end

function UIActKingStreet:ChangeTab(trans,bool)
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
end

---打开子界面
function UIActKingStreet:OpenActivityChildWnd(pageId)
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
		local entry = self.pages[pageId].entry
		openFunc(entry)
	end
end

function UIActKingStreet:ResetData(pb)
	local sid = pb.sid
	if(self._sid ~= sid)then
		return
	end
	local list = self.pages
	if not list then
		list = {}
	end
	for i, v in ipairs(pb.pages) do
		local page = gModelActivity:GenerateActivePageDataFromPb(v)
		list[page.pageId] = page
	end
	self.pages = list
	self:RefreshData()
end

function UIActKingStreet:InitDate()
	self._modelOpenFunc = {
		[ModelActivity.KING_STREET_1] = function(...) self:OpenGift(...) end,
		[ModelActivity.KING_STREET_2] = function(...) self:OpenGift(...) end,
		[ModelActivity.KING_STREET_3] = function(...) self:OpenCall(...) end,
		[ModelActivity.KING_STREET_4] = function(...) self:OpenTask(...) end,
		[ModelActivity.KING_STREET_5] = function(...) self:OpenTask(...) end,
	}

end

function UIActKingStreet:InitEvent()
	self:SetWndClick(self.mBtnClose, function(...) self:OnClickClose() end)
end

function UIActKingStreet:OnActivityConfigData()
	local _sid = self._sid
	local webData = gModelActivity:GetWebActivityDataById(_sid)
	local dataWeb = webData.config
	local bookmark,bookmarkBg = dataWeb.menuSwitch,dataWeb.menuBg
	if LxUiHelper.IsImgPathValid(bookmarkBg) then
		CS.ShowObject(self.mBg,true)
		self:SetWndEasyImage(self.mBg,bookmarkBg)
	end
	local list = {}
	if not string.isempty(bookmark) then
		local bookmarkArr = string.split(bookmark,"|")
		for i, v in ipairs(bookmarkArr) do
			local arr = string.split(v,"=")
			local data =
			{
				pageId = tonumber(arr[1]),
				icon1 = arr[2],
				icon2 = arr[3],
				name = arr[4],
			}
			table.insert(list,data)
		end
	end

	local _uiTabList = self._uiTabList
	if _uiTabList then
		_uiTabList:RefreshList(list)
	else
		_uiTabList = self:GetUIScroll("tabList")
		_uiTabList:Create(self.mTabScroll,list,function (...) self:ListItem(...) end)
		self._uiTabList = _uiTabList
	end
	self._tabList = list

	gModelActivity:OnActivityPageReq(_sid)
end

function UIActKingStreet:ListItem(list,item, itemdata, itempos)
	local image = CS.FindTrans(item,"Image")
	local icon = CS.FindTrans(item,"Icon")
	local nameText = CS.FindTrans(item,"NameText")
	local redPoint = CS.FindTrans(item,"redPoint")
	local pageId = itemdata.pageId
	self._tabTransList[pageId] = item
	self._redList[itempos] = redPoint
	self:SetWndEasyImage(image,itemdata.icon1,nil,true)
	self:SetWndEasyImage(icon,itemdata.icon2,nil,true)
	self:SetWndText(nameText,itemdata.name)
	self:InitTextLineWithLanguage(nameText, -30)
	self:InitTextSizeWithLanguage(nameText, -2)
	self:SetWndClick(item,function ()
		self:OpenActivityChildWnd(pageId)
	end)
end
------------------------------------------------------------------
return UIActKingStreet


