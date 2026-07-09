---
--- Created by BY.
--- DateTime: 2023/10/8 18:13:17
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActSubMag:LWnd
local UIActSubMag = LxWndClass("UIActSubMag", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActSubMag:UIActSubMag()
	self._tabTransList = {}
	self._redList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActSubMag:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActSubMag:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActSubMag:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitDate()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIActSubMag:OnActivityConfigData()
	local _sid = self._sid
	local webData = gModelActivity:GetWebActivityDataById(_sid)
	local dataWeb = webData.config
	local bookmark,bookmarkBg = dataWeb.bookmark,dataWeb.bookmarkBg
	if LxUiHelper.IsImgPathValid(bookmarkBg) then
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

function UIActSubMag:OnClickClose()
	local wndName = self._modelWndList[self._modelId]
	GF.OpenWnd(wndName,{sid = self._sid})
	self:WndClose()
end

function UIActSubMag:InitCommand()
	local sid = self:GetWndArg("sid")
	self._page = self:GetWndArg("page")--支持跳转
	local _subPage = self:GetWndArg("subPage")
	if _subPage then
		sid = gModelActivity:GetSidByUniqueJump(_subPage)
	end
	local modelId = gModelActivity:GetActivityModeIdBySid(sid)
	self._modelId = modelId
	self._sid = sid
	self._curPage = nil
	gModelActivity:ReqActivityConfigData(sid)
end

function UIActSubMag:GetModelActivityType64ByPageId(pageId)
	local list = {
		[ModelActivity.TABLE_ENTTY_TYPE_2] = ModelActivity.ST_PATRICK_DAY_2,
		[ModelActivity.TABLE_ENTTY_TYPE_6] = ModelActivity.ST_PATRICK_DAY_4,
	}
	return list[pageId]
end

function UIActSubMag:GetModelActivityType64(pageIdIndex)
	local list = {
		[ModelActivity.ST_PATRICK_DAY_2] = ModelActivity.TABLE_ENTTY_TYPE_2,
		[ModelActivity.ST_PATRICK_DAY_4] = ModelActivity.TABLE_ENTTY_TYPE_6,
	}
	return list[pageIdIndex]
end

function UIActSubMag:InitEvent()
	self:SetWndClick(self.mBtnClose, function(...) self:OnClickClose() end)
end

function UIActSubMag:OnTryTcpReconnect()
	self:WndClose()
end

function UIActSubMag:InitDate()
	self._modelOpenFunc = {
		[ModelActivity.TABLE_ENTTY_TYPE_2] = function(...) self:OpenLuckPrivilege(...) end,
		[ModelActivity.TABLE_ENTTY_TYPE_3] = function(...) self:OpenLuckShop(...) end,
		[ModelActivity.TABLE_ENTTY_TYPE_6] = function(...) self:OpenLuckShed(...) end,
	}
	self._modelWndList = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_64] = "UIActSaintPatrick",
		-- [ModelActivity.FAIRY_FATHER_DAY] 	   = "UIActFairyFatherDay",
	}
	self._modelPageIdList = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_64] = function (...)return self:GetModelActivityType64(...) end,
		-- [ModelActivity.FAIRY_FATHER_DAY] 	   = function (...)return self:GetModelActivityFatherDay(...) end,
	}
	self._modelPageIndexList = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_64] = function (...)return self:GetModelActivityType64ByPageId(...) end,
		-- [ModelActivity.FAIRY_FATHER_DAY] 	   = function (...)return self:GetModelActivityFatherDayByPageId(...) end,
	}
end

function UIActSubMag:ChangeTab(trans,bool)
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

function UIActSubMag:GetModelActivityFatherDayByPageId(pageId)
	local list = {
		[ModelActivity.TABLE_ENTTY_TYPE_2] = ModelActivity.FATHER_DAY_PRIVILEGE,
		[ModelActivity.TABLE_ENTTY_TYPE_6] = ModelActivity.FATHER_DAY_DROP,
	}
	return list[pageId]
end

function UIActSubMag:RefreshData()
	local _sid = self._sid
	local list = self._tabList or {}

	local _page = self._page
	if _page then
		self._page = nil
	else
		_page = list[1].pageId
	end

	if self._curPage ~= _page then
		self:OpenActivityChildWnd(_page)
	end
end

function UIActSubMag:ListItem(list,item, itemdata, itempos)
	local image = CS.FindTrans(item,"Image")
	local icon = CS.FindTrans(item,"Icon")
	local nameText = CS.FindTrans(item,"NameText")
	local redPoint = CS.FindTrans(item,"redPoint")
	local pageId = itemdata.pageId
	self._tabTransList[pageId] = item
	self._redList[pageId] = redPoint
	self:SetWndEasyImage(image,itemdata.icon1,nil,true)
	self:SetWndEasyImage(icon,itemdata.icon2,nil,true)
	self:SetWndText(nameText,itemdata.name)
	self:InitTextLineWithLanguage(nameText, -30)
	self:InitTextSizeWithLanguage(nameText, -2)
	self:SetWndClick(item,function ()
		self:OpenActivityChildWnd(pageId)
	end)
end

function UIActSubMag:OpenLuckPrivilege(entry)
	self:CreateChildWnd(self.mChildRoot,"UISubCHNPrige",{sid = self._sid,entry = entry})
end

function UIActSubMag:OpenLuckShed(entry)
	-- self:CreateChildWnd(self.mChildRoot,"WndChildHalloweenShed",{sid = self._sid,entry = entry})
end

function UIActSubMag:GetModelActivityFatherDay(pageIdIndex)
	local list = {
		[ModelActivity.FATHER_DAY_PRIVILEGE] = ModelActivity.TABLE_ENTTY_TYPE_2,
		[ModelActivity.FATHER_DAY_DROP] 	 = ModelActivity.TABLE_ENTTY_TYPE_6,
	}
	return list[pageIdIndex]
end

---打开子界面
function UIActSubMag:OpenActivityChildWnd(pageIndex)
	if pageIndex == 0 then
		self:OnClickClose()
		return
	end
	local indexFunc = self._modelPageIdList[self._modelId]
	local pageId = indexFunc(pageIndex)
	local openFunc = self._modelOpenFunc[pageId]
	if openFunc then
		self:CloseAllChild()
		for i, v in pairs(self._tabTransList) do
			if i ~= pageIndex then
				self:ChangeTab(v,false)
			else
				self:ChangeTab(v,true)
			end
		end

		self._curPage = pageIndex
		self._page = pageIndex
		local entry = self.pages[pageIndex].entry
		openFunc(entry)

	end
end

function UIActSubMag:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		self:ResetData(pb)
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function (pb)
		self:RefreshData()
	end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:OnActivityConfigData()
	end)
end

function UIActSubMag:OpenLuckShop(entry)
	self:CreateChildWnd(self.mChildRoot,"UISubCHNDian",{sid = self._sid,entry = entry})
end

function UIActSubMag:ResetData(pb)
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
------------------------------------------------------------------
return UIActSubMag


