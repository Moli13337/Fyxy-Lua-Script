---
--- Created by BY.
--- DateTime: 2023/10/18 15:43:55
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActGoodLuck:LWnd
local UIActGoodLuck = LxWndClass("UIActGoodLuck", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActGoodLuck:UIActGoodLuck()
	self:SetHideHurdle()
	self._tabTransList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActGoodLuck:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActGoodLuck:OnCreate()
	LWnd.OnCreate(self)
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActGoodLuck:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	--self:DoWndStartMove(0, LWnd.StartMoveLeft, self.mView)
	self:InitEvent()
	self:InitMessage()
	self:InitDate()
	self:InitCommand()
end

function UIActGoodLuck:InitCommand()
	self._sid = self:GetWndArg("sid")
	self._page = self:GetWndArg("page")or ModelActivity.NEWYEAR_LUCK_PRIVILEGE --支持跳转
	local _subPage = self:GetWndArg("subPage")
	if _subPage then
		self._sid = gModelActivity:GetSidByUniqueJump(_subPage)
	end
	gModelActivity:ReqActivityConfigData(self._sid)
end

function UIActGoodLuck:OnClickClose()
	-- GF.OpenWnd("UIActNewYear",{sid = self._sid})
	self:WndClose()
end

function UIActGoodLuck:OpenLuckGift(entry)
	self:CreateChildWnd(self.mChildRoot,"UISubLuckGift",{sid = self._sid,entry = entry})
end

function UIActGoodLuck:ResetData(pb)
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

function UIActGoodLuck:RefreshData()
	local _sid = self._sid
	local activityData = gModelActivity:GetActivityBySid(_sid)
	if not activityData then
		return
	end
	local webData = gModelActivity:GetWebActivityDataById(_sid)
	local dataWeb = webData.config
	local luckySwitch = dataWeb.luckySwitch
	local luckyArr = string.split(luckySwitch,"|")
	local list = {
		{pageId = 0,icon = "spring_btn_back",name = ccClientText(30205)}
	}
	local isOpenPage = false
	local _page = self._page
	local pageIdList = {}
	for i, v in ipairs(luckyArr) do
		local switchArr = string.split(v,"=")
		if switchArr[2] == "1" then
			local pageId = tonumber(switchArr[1])
			if _page == pageId then
				isOpenPage = true
			end
			table.insert(pageIdList,pageId)
			local data = self.pages[pageId]
			if data then
				data.icon = switchArr[3]
				data.name = switchArr[4]
				data.isRed = gModelRedPoint:GetActivityRedPointPage(_sid,pageId)
				table.insert(list,data)
			end
		end
	end

	if not isOpenPage and not self._initPage then
		_page = pageIdList[1]
		self._page = _page
	end

	if self._uiTabList then
		self._uiTabList:RefreshList(list)
	else
		self._uiTabList = self:GetUIScroll("tabList")
		self._uiTabList:Create(self.mTabScroll,list,function (...) self:ListItem(...) end)
	end

	if _page and not self._initPage then
		self._initPage = true
		if _page > 0 then
			self:OpenActivityChildWnd(_page)
		else
			self:OpenActivityChildWnd(list[2].pageId)
		end
		self._page = nil
	end
end

function UIActGoodLuck:OpenLuckRushBuy(entry)
	self:CreateChildWnd(self.mChildRoot,"UISubLuckRushBuy",{sid = self._sid,entry = entry})
end

function UIActGoodLuck:ListItem(list,item, itemdata, itempos)
	local icon = CS.FindTrans(item,"Icon")
	local nameText = CS.FindTrans(item,"NameText")
	local redPoint = CS.FindTrans(item,"redPoint")
	local pageId = itemdata.pageId
	self._tabTransList[pageId] = item
	CS.ShowObject(redPoint,itemdata.isRed)
	self:SetWndEasyImage(icon,itemdata.icon,nil,true)
	self:SetWndText(nameText,itemdata.name)
	self:SetWndClick(item,function ()
		self:OpenActivityChildWnd(pageId)
	end)
end

function UIActGoodLuck:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		self:ResetData(pb)
	end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then
			return
		end
		self:OnActivityConfigData()
	end)
end

function UIActGoodLuck:OnTryTcpReconnect()
	self:WndClose()
end

function UIActGoodLuck:InitEvent()
	--self:SetWndClick(self.mCloseBtn, function(...) self:OnClickClose() end)
end

---打开子界面
function UIActGoodLuck:OpenActivityChildWnd(pageId)
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

function UIActGoodLuck:OnActivityConfigData()
	gModelActivity:OnActivityPageReq(self._sid)
end

function UIActGoodLuck:InitDate()
	self._modelOpenFunc = {
		[0] = function() self:WndClose() end,
		[ModelActivity.NEWYEAR_LUCK_PRIVILEGE] = function(...) self:OpenLuckPrivilege(...) end,
		[ModelActivity.NEWYEAR_LUCK_SECKILL] = function(...) self:OpenLuckRushBuy(...) end,
		[ModelActivity.NEWYEAR_LUCK_SHOP] = function(...) self:OpenLuckShop(...) end,
		[ModelActivity.NEWYEAR_LUCK_GIFT] = function(...) self:OpenLuckGift(...) end,
	}
end

function UIActGoodLuck:OpenLuckPrivilege(entry)
	self:CreateChildWnd(self.mChildRoot,"UISubLuckPrige",{sid = self._sid,entry = entry})
end

function UIActGoodLuck:ChangeTab(trans,bool)
	local onImage = CS.FindTrans(trans,"OnImage")
	local nameText = CS.FindTrans(trans,"NameText")
	local color
	if bool then
		color = "ffffffff"
	else
		color = "feeba7ff"
	end
	color = LUtil.ColorByHex(color)
	local xuitxt = self:FindWndText(nameText)
	self:SetXUITextColor(xuitxt,color)
	CS.ShowObject(onImage,bool)
end

function UIActGoodLuck:OpenLuckShop(entry)
	self:CreateChildWnd(self.mChildRoot,"UISubLuckDian",{sid = self._sid,entry = entry})
end
------------------------------------------------------------------
return UIActGoodLuck


