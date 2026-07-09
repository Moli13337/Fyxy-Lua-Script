---
--- Created by BY.
--- DateTime: 2023/10/22 18:37:57
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdLogPop:LWnd
local UIGdLogPop = LxWndClass("UIGdLogPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdLogPop:UIGdLogPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdLogPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdLogPop:OnCreate()
	LWnd.OnCreate(self)
	self._tabBtnList={}
	self._oldIndex=nil
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdLogPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIGdLogPop:RefreshData()
	local loglist=gModelGuild:GetGuildLogByType(self._oldIndex)
	local list = {}
	if #loglist > 0 then
		for i, v in ipairs(loglist) do
			table.insert(list,{type = 1,time = v.time})
			for i, v in ipairs(v.list) do
				local logDes = gModelGuild:GetGuildLogDesByLog(v)
				table.insert(list,{type = 2,logDes = logDes})
			end
		end
	end
	CS.ShowObject(self.mNoRecord,#list<=0)
	local logRefId = 4002
	if self._oldIndex == 3 then
		logRefId = 4001
	end
	self:CreateEmptyShow(logRefId)
	if(self._uiList)then
		self._uiList:RefreshSimpleList(list)
	else
		self._uiList = self:GetUIScroll("_uiList")
		self._uiList:Create(self.mCellScroll,list,function (...) self:ListItem(...) end,UIItemList.WRAP)
	end
end

function UIGdLogPop:ListItem(list,item, itemdata, itempos)
	local root1 = CS.FindTrans(item,"Root1")
	local root2 = CS.FindTrans(item,"Root2")

	local type = itemdata.type
	CS.ShowObject(root1,type == 1)
	CS.ShowObject(root2,type == 2)
	if type == 1 then
		self:SetRoot1(root1,itemdata.time)
	elseif type == 2 then
		self:SetRoot2(root2,itemdata.logDes)
	end
end

function UIGdLogPop:OnTimer(key)
	local list = self._uiList:GetList()
	list:RefreshList()
end

function UIGdLogPop:InitCommand()
	self._tabIndex = self:GetWndArg("tabIndex") or 1
	self:SetWndText(self.mTitleText,ccClientText(12454))
	self:SetWndText(self.mTipsText,ccClientText(12559))
	local list = gModelGuild:GetGuildLogTypeRef()
	if(self._tabList)then
		self._tabList:RefreshList(list)
	else
		self._tabList = self:GetUIScroll("tabList")
		self._tabList:Create(self.mTypeBtnList,list,function (...) self:TabListItem(...) end)
		self._tabList:EnableScroll(true,true)
	end
	local uiList = self._tabList:GetList()
	uiList:DelayScrollTo(self._tabIndex,UIListEasy.SCROLL_CENTER)
	self:OnClickTab(list[self._tabIndex].type)
end

function UIGdLogPop:CreateEmptyShow(refId)
	local data = {
		refId = refId,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end

function UIGdLogPop:SetRoot1(item,time)
	local nameText = CS.FindTrans(item,"DayBg/DayText")

	self:SetWndText(nameText,time)
end

function UIGdLogPop:ChangeType(trans,bool)
	local status = bool and 0 or 1
	self:SetWndTabStatus(trans,status)
end

function UIGdLogPop:OnClickTab(index)
	if(index~=self._oldIndex)then
		if(self._oldIndex)then
			local oldTrans=self._tabBtnList[self._oldIndex]
			self:ChangeType(oldTrans,false)
		end
		local trans= self._tabBtnList[index]
		self:ChangeType(trans,true)
		self._oldIndex=index
	end
	gModelGuild:OnGuildLogListReq(index)
end

function UIGdLogPop:SetRoot2(item,itemdata)
	local nameText = CS.FindTrans(item,"NameText")
	local timeText = CS.FindTrans(item,"NameText/TimeText")
	local desText = CS.FindTrans(item,"DesText")

	local addSize = -2
	if gLGameLanguage:IsThaiVersion() then
		addSize = -6
	end
	self:SetWndText(nameText,itemdata.name)
	self:InitTextSizeWithLanguage(nameText, addSize)
	self:SetWndText(timeText,itemdata.time)
	self:SetWndText(desText,itemdata.str)
end

function UIGdLogPop:TabListItem(list,item, itemdata, itempos)
	local btnTab1= CS.FindTrans(item,"BtnTab1")
	self._tabBtnList[itemdata.type] = btnTab1
	self:SetWndTabText(btnTab1,ccLngText(itemdata.name), nil, -30)
	self:SetWndTabStatus(btnTab1,1)
	self:SetWndClick(item, function(...) self:OnClickTab(itemdata.type) end)
end

function UIGdLogPop:InitEvent()
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
end

function UIGdLogPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.GuildLogListResp,function (...)
		self:RefreshData()
	end)
end
------------------------------------------------------------------
return UIGdLogPop


