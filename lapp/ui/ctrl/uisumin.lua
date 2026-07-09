---
--- Created by Administrator.
--- DateTime: 2023/10/17 17:35:50
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISuMin:LWnd
local UISuMin = LxWndClass("UISuMin", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISuMin:UISuMin()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISuMin:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISuMin:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISuMin:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:InitUIEvent()

	gModelSimuFight:CheckPopNews()

	self:OnWndRefresh()
end

function UISuMin:OnClickTab(itemdata)
	if self._curPage == itemdata.index then
		return
	end

	--local state = gModelSimuFight:GetState()
	--if itemdata.schedule and itemdata.schedule > state then
	--	local str = ccClientText(25107) --"该赛程未解锁"
	--	GF.ShowMessage(str)
	--	--return
	--end

	self._curPage = itemdata.index

	local list = self:FindUIScroll("tabList")
	if list then
		list:DrawAllItems(false)
	end


	self:OpenPage(itemdata.index)
end


function UISuMin:OnWndRefresh()

	local page = self:GetWndArg("page") or 1
	self._curPage = page
	local pagePara = self:GetWndArg("pagePara")

	--local groupType = self:GetWndArg("groupType")
	self:ShowTabList()
	self:OpenPage(self._curPage,pagePara)
end

function UISuMin:GetHistory()
	local list = LWnd.GetHistory(self)
	local wndArgList = list.wndArgList
	wndArgList.page = self._curPage

	local pagePara = nil
	if self._curPageWnd and self._curPageWnd.GetPara then
		pagePara = self._curPageWnd:GetPara()
	end
	wndArgList.pagePara = pagePara
	return list
end


function UISuMin:OpenPage(index,pagePara)
	local pageName = self._tabDataList[index].pageName
	self:CloseAllChild()
	self._curPageWnd = self:CreateChildWnd(self.mChildRoot,pageName,pagePara)
end

function UISuMin:ShowTabList()
	local tabList = self:FindUIScroll("tabList")
	if not tabList then
		tabList = self:GetUIScroll("tabList")
		tabList:Create(self.mTabScroll,self._tabDataList,function (...)  self:OnDrawTab(...) end)
	else
		tabList:RefreshList(self._tabDataList)
	end
end

function UISuMin:InitUIEvent()
	self:SetWndClick(self.mCloseBtn,function ()
		self:WndClose()
	end)
	self:SetWndText(self.mTxtClose, ccClientText(30205))
end

function UISuMin:InitData()
	self._tabDataList =
	{
		[1] =
		{
			name = ccClientText(25106), --"总决赛",
			index = 5,
			schedule = ModelSimuFight.SCHEDULE_GROUP_BATTLE,
			imageOff = "simulate_tab_5",
			imageOn = "simulate_tab_5",
			pageName = "UISubSuSchedule",
		},
		[2] =
		{
			name = ccClientText(25105), --"半决赛",
			index = 4,
			schedule = ModelSimuFight.SCHEDULE_GROUP_WARM_UP,
			imageOff = "simulate_tab_1",
			imageOn = "simulate_tab_1",
			pageName = "UISubSuBreak",
		},
		[3] =
		{
			name = ccClientText(25104), --"小组赛",
			index = 3,
			pageName = "UISubSuGroup",
			schedule = ModelSimuFight.SCHEDULE_GROUP_INIT,
			imageOff = "simulate_tab_4",
			imageOn = "simulate_tab_4",
		},
		[4] =
		{
			name = ccClientText(25103), --"突围赛",
			index = 2,
			schedule = ModelSimuFight.SCHEDULE_BREAKOUT,
			imageOff = "simulate_tab_3",
			imageOn = "simulate_tab_3",
			pageName = "UISubSSyemi",
		},
		[5] =
		{
			name = ccClientText(25100), --"赛程",
			index = 1,
			imageOff = "simulate_tab_2",
			imageOn = "simulate_tab_2",
			pageName = "UISubSuFinal",
		},

	}
end

function UISuMin:OnDrawTab(list,item,itemdata,index)
	-- local AniRoot = self:FindWndTrans(item,"AniRoot")
	-- local AniRootSelImg = self:FindWndTrans(AniRoot,"SelImg")
	-- local AniRootImageOff = self:FindWndTrans(AniRoot,"ImageOff")
	-- local AniRootImageOn = self:FindWndTrans(AniRoot,"ImageOn")
	-- local AniRootNameText = self:FindWndTrans(AniRoot,"NameText")
	-- --local AniRootRedPoint = self:FindWndTrans(AniRoot,"redPoint")

	-- self:SetWndEasyImage(AniRootImageOff,itemdata.imageOff)
	-- self:SetWndEasyImage(AniRootImageOn,itemdata.imageOn)


	-- local isSelect = itemdata.index == self._curPage
	-- CS.ShowObject(AniRootSelImg,isSelect)
	-- self:SetWndText(AniRootNameText,itemdata.name)
	-- self:InitTextLineWithLanguage(AniRootNameText, -30)
	-- self:SetWndClick(AniRoot,function () self:OnClickTab(itemdata) end)

	local On = self:FindWndTrans(item,"On")
	local Off = self:FindWndTrans(item,"Off")
	local Gray = self:FindWndTrans(item,"Gray")

	self:SetWndTabText(item, itemdata.name)
	self:SetWndEasyImage(On, itemdata.imageOn)
	self:SetWndEasyImage(Off, itemdata.imageOff)
	self:SetWndEasyImage(Gray, itemdata.imageOff)
	local isSelect = itemdata.index == self._curPage
	self:SetWndTabStatus(item, isSelect and 0 or 1)
	self:SetWndClick(item,function () self:OnClickTab(itemdata) end)
end


------------------------------------------------------------------
return UISuMin


