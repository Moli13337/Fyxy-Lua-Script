---
--- Created by BY.
--- DateTime: 2023/10/20 17:07:53
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActUpStarGift:LWnd
local UIActUpStarGift = LxWndClass("UIActUpStarGift", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActUpStarGift:UIActUpStarGift()
	self._tabTransList = {}
	self._redTrList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActUpStarGift:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActUpStarGift:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActUpStarGift:OnStart()
	LWnd.OnStart(self)
	self:SetWndText(self.mCloseText, ccClientText(42010))
	self:InitUI()
	self:InitDate()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UIActUpStarGift:GetRedByList(list)
	for i, v in ipairs(list) do
		local red = gModelRedPoint:GetActivityRedPointPage(self._sid,v)
		if red then
			return true
		end
	end
	return false
end

function UIActUpStarGift:ListItem(list,item, itemdata, itempos)
	local redPoint = CS.FindTrans(item,"redPoint")

	self:SetWndTabText(item,itemdata.name,nil,true)
	self:SetWndTabIcon(item,itemdata.icon2,itemdata.icon2)

	local pageId = itemdata.pageId
	self._tabTransList[pageId] = item
	self._redTrList[pageId] = redPoint
	self:SetWndClick(item,function ()
		self:OpenActivityChildWnd(pageId,itempos)
	end)
end

function UIActUpStarGift:OnTryTcpReconnect()
	self:WndClose()
end
function UIActUpStarGift:InitDate()
	self._modelOpenFunc = {
		[ModelActivity.UpStarGift_1] = function(...) self:OpenGift(...) end,
		[ModelActivity.UpStarGift_3] = function(...) self:OpenUpStar(...) end,
	}

end
function UIActUpStarGift:OnActivityConfigData()
	local sid = self._sid
	local activityData = gModelActivity:GetWebActivityDataById(sid)
	local data = activityData.config

	local image = data.image
	self._btnIcon = data.btnIcon

	if LxUiHelper.IsImgPathValid(image) then
		self:SetWndEasyImage(self.mBg,image)
	end
	self:RefreshData()
end
function UIActUpStarGift:SaveWndArg()
	local wndArg = self:GetWndArgList() or {}
	wndArg["page"] = self._pos or 1
	self:SetWndArg(wndArg)
end
function UIActUpStarGift:RefreshRed()
	local _redTrList = self._redTrList or {}
	local list1 = {
		ModelActivity.UpStarGift_1,
		ModelActivity.UpStarGift_2,
	}
	local list2 = {
		ModelActivity.UpStarGift_3,
		ModelActivity.UpStarGift_4,
	}
	local entry1Red = self:GetRedByList(list1)
	local entry2Red = self:GetRedByList(list2)

	CS.ShowObject(_redTrList[ModelActivity.UpStarGift_1],entry1Red)
	CS.ShowObject(_redTrList[ModelActivity.UpStarGift_3],entry2Red)
end
function UIActUpStarGift:ChangeTab(trans,bool)
	-- local image = CS.FindTrans(trans,"Image")
	-- local icon = CS.FindTrans(trans,"Icon")
	-- local onImage = CS.FindTrans(trans,"OnImage")
	-- local nameText = CS.FindTrans(trans,"NameText")
	-- local color
	-- if bool then
	-- 	color = "ffffffff"
	-- else
	-- 	color = "b9c9ebff"
	-- end
	-- color = LUtil.ColorByHex(color)
	-- local xuitxt = self:FindWndText(nameText)
	-- self:SetXUITextColor(xuitxt,color)
	-- CS.ShowObject(onImage,bool)
	-- CS.ShowObject(icon,bool)
	-- CS.ShowObject(image,not bool)
end
function UIActUpStarGift:OpenUpStar(entry,pages)
	self:CreateChildWnd(self.mChildRoot,"UISubUpStar",{sid = self._sid})
end
function UIActUpStarGift:RefreshData()
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
function UIActUpStarGift:InitEvent()
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end
function UIActUpStarGift:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:OnActivityConfigData()
	end)
	self:WndEventRecv(EventNames.ON_RED_CHANGE, function(...) self:RefreshRed() end)
	self:WndEventRecv(EventNames.ON_JUMP, function(...) self:WndClose() end)
end

function UIActUpStarGift:OpenGift(entry,pages)
	self:CreateChildWnd(self.mChildRoot,"UISubActGiftD",{sid = self._sid})
end
function UIActUpStarGift:InitCommand()
	local _sid = self:GetWndArg("sid")
	self._page = self:GetWndArg("page") or 1 --支持跳转
	local _subPage = self:GetWndArg("subPage")
	if _subPage then
		_sid = gModelActivity:GetSidByUniqueJump(_subPage)
	end
	self._sid = _sid
	gModelActivity:ReqActivityConfigData(_sid)
end
---打开子界面
function UIActUpStarGift:OpenActivityChildWnd(pageId,pos)
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
			self:SetWndTabStatus(v, i== pageId and 0 or 1)
		end
		self._pageId = pageId
		openFunc()
		self._pos = pos
		self:SaveWndArg()
	end
end
------------------------------------------------------------------
return UIActUpStarGift


