---
--- Created by Administrator.
--- DateTime: 2023/10/2 20:41:10
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEdenBook:LWnd
local UIEdenBook = LxWndClass("UIEdenBook", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEdenBook:UIEdenBook()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEdenBook:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEdenBook:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEdenBook:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	--self:DoWndStartMove(0, LWnd.StartMoveLeft, self.mRoot)


	self:InitData()
	self:SetStaticContent()

	self._curIndex = 1
	self:InitWndPara()

	self:RefreshUI()

	self:SetWndClick(self.mBtnClose,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mMask,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIEdenBook:ShowEventBook(themeId)
	local cfg = gModelWonderland:GetThemeConfig(themeId)
	if not cfg then
		return
	end
	local desc = cfg.description
	desc = ccLngText(desc)
	self:SetWndText(self.mPost,desc)
	local bgPath = cfg.strategyIcon
	self:SetWndEasyImage(self.mThemeBg,bgPath)
	local eventList = gModelWonderland:GetBookEventList(themeId)
	local list = self._eventUiList
	if not list then
		list = self:GetUIScroll("eventList")
		list:Create(self.mEventList,eventList,function(...) self:OnDrawEvent(...) end,UIItemList.WRAP,false)
		self._eventUiList = list
	else
		list:RefreshList(eventList,true)
	end
	local uiList= list:GetList()
	uiList:RefreshList(UIListWrap.RefreshMode.Solid)

end

function UIEdenBook:OnDrawBtn(list,item,itemdata,itempos)
	local BtnTab1 = self:FindWndTrans(item,"BtnTab1")

	local index = itemdata.index
	local isSelect = index == self._curIndex
	local state = isSelect and LWnd.StateOn or LWnd.StateOff
	self:SetWndTabStatus(BtnTab1,state)
	local name = itemdata.name
	self:SetWndTabText(BtnTab1,name)

	self:SetWndClick(item,function () self:OnClickType(index) end,LSoundConst.CLICK_PAGE_COMMON)
	self._btnItemList[index] = item
end

function UIEdenBook:ShowContent(index)
	local itemdata = self._btnDataList[index]
	local type = itemdata.type
	CS.ShowObject(self.mEventBook,type == 1)
	CS.ShowObject(self.mTsBook,type == 2)
	if type == 1 then
		self:ShowEventBook(itemdata.themeId)
	elseif type == 2 then
		self:ShowTsBook()
	end
end

function UIEdenBook:InitWndPara()
	self._themeList = self:GetWndArg("themeList")

	local btnDataList = {}
	local index = 1
	for k,v in ipairs(self._themeList) do
		local themeCfg = gModelWonderland:GetThemeConfig(v)
		local name = ""
		if themeCfg then
			name = ccLngText(themeCfg.name)
		end
		local data =
		{
			name = name,
			type = 1,
			themeId = v,
			index = index,
		}
		table.insert(btnDataList,data)
		index = index + 1
	end

	local data =
	{
		name =ccClientText(16707),  -- "奇境宝物",
		type= 2,
		index = index,
	}

	table.insert(btnDataList,data)

	self._btnDataList = btnDataList
end

function UIEdenBook:OnDrawEvent(list,item,itemdata,itempos)
	local bg = self:FindWndTrans(item,"bg")
	local iconBg = self:FindWndTrans(item,"iconBg")
	local iconBgIcon = self:FindWndTrans(iconBg,"icon")
	local name = self:FindWndTrans(item,"name")
	local desc = self:FindWndTrans(item,"descScroll/desc")

	local iconPath = itemdata.res
	self:SetWndEasyImage(iconBgIcon,iconPath)
	local eventName = itemdata.name
	eventName= ccLngText(eventName)
	self:SetWndText(name,eventName)
	local eventDesc = itemdata.description
	eventDesc = ccLngText(eventDesc)
	self:SetWndText(desc,eventDesc)
	self:InitTextLineWithLanguage(desc,-20)
end

function UIEdenBook:OnDrawTreasure(list,item,itemdata,itempos)
	local aniRoot = self:FindWndTrans(item,"AniRoot")
	local treasure = self:FindWndTrans(aniRoot,"TreasureIcon")
	local data =
	{
		refId = itemdata.refId,
		lv = itemdata.lv
	}

	TreasureIcon.SetIcon(treasure,data,self)
end

function UIEdenBook:ShowTsBook()
	local dataList= gModelWonderland:GetTreasureList()

	local list = self:GetUIScroll("treasureList")
	list:Create(self.mTsList,dataList,function (...) self:OnDrawTreasure(...) end,UIItemList.WRAP,false)
	local uiList= list:GetList()
	uiList:EnableLoadAnimation(true, 0.02, 3)
	uiList:RefreshList()
end

function UIEdenBook:InitData()
	self._btnItemList ={}

end

function UIEdenBook:RefreshUI()
	local itemList = self:GetUIScroll("btnList")
	itemList:Create(self.mBtnList,self._btnDataList,function (...) self:OnDrawBtn(...) end)

	self:ShowContent(self._curIndex)
end

function UIEdenBook:OnClickType(index)
	if self._curIndex == index then
		return
	end

	local item = self._btnItemList[self._curIndex]
	if item then
		local BtnTab1 = self:FindWndTrans(item,"BtnTab1")
		self:SetWndTabStatus(BtnTab1,LWnd.StateOff)

	end
	item = self._btnItemList[index]
	if item then
		local BtnTab1 = self:FindWndTrans(item,"BtnTab1")
		self:SetWndTabStatus(BtnTab1,LWnd.StateOn)
	end
	self._curIndex = index

	self:ShowContent(index)
end



function UIEdenBook:SetStaticContent()
	local str =ccClientText(16708)  -- "奇境手册"
	self:SetWndText(self.mTitle,str)
	str =ccClientText(16709)  -- "场景攻略"
	self:SetWndText(self.mTitle_1,str)

end
------------------------------------------------------------------
return UIEdenBook


