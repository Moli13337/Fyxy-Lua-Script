---
--- Created by Administrator.
--- DateTime: 2023/10/21 16:41:50
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISuBz:LWnd
local UISuBz = LxWndClass("UISuBz", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISuBz:UISuBz()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISuBz:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISuBz:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISuBz:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitUIEvent()

	self._curSelect = 1
	self:OnWndRefresh()
end

--function UISuBz:MoveToCenter(index)
--	local list = self:FindUIScroll("postlist")
--	if list then
--		local uiList = list:GetList()
--		if uiList then
--			uiList:MoveToCenter(index)
--		end
--	end
--end

function UISuBz:OnItemCenter(item, itemdata, itempos)
	self._curSelect = itempos
	local list = self:FindUIScroll("starList")
	if list then
		list:DrawAllItems(false)
	end
end

function UISuBz:OnDrawStar(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootIcon = self:FindWndTrans(AniRoot,"icon")
	local AniRootSelect = self:FindWndTrans(AniRoot,"select")


	local pos = self._curSelect
	if self._isTwo then
		pos = (pos-1)%2 + 1
	end
	local isSelect = pos == itempos
	CS.ShowObject(AniRootSelect,isSelect)


	--self:SetWndClick(AniRoot,function ()
	--	self:MoveToCenter(itempos)
	--end)
end

function UISuBz:OnDrawPost(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootIcon = self:FindWndTrans(AniRoot,"icon")
	local AniRootText = self:FindWndTrans(AniRoot,"text")

	self:SetWndEasyImage(AniRootIcon,itemdata.bg,nil,true)
	self:SetWndEasyImage(AniRootText,itemdata.nameIcon,nil,true)
end

function UISuBz:InitUIEvent()

	self:SetWndClick(self.mMask,function () self:WndClose() end)

	self:SetWndClick(self.mBtnLeft,function ()
		local list = self._postList:GetList()
		if list then
			list:MoveOneStep(false)
		end
	end)

	self:SetWndClick(self.mBtnRight,function ()
		local list = self._postList:GetList()
		if list then
			list:MoveOneStep(true)
		end
	end)
end


function UISuBz:OnWndRefresh()

	local dataList = gModelSimuFight:GetHelpList()


	local tempList = dataList
	self._isTwo = false
	if #dataList == 2 then
		local list = {}
		for k = 0 ,3 do
			local index  = k % 2 + 1
			table.insert(list,dataList[index])
		end

		dataList = list
		self._isTwo = true
	end


	local starList = self:FindUIScroll("starList")
	if not starList then
		starList = self:GetUIScroll("starList")
		starList:Create(self.mItemList,tempList,function (...) self:OnDrawStar(...) end)
	else
		starList:RefreshList(dataList)
	end


	local uiList = self._postList
	uiList = self:GetUIScroll("postlist")
	self._postList = uiList
	uiList:InitListData({
		root = self.mHelpList,
		dataList = dataList,
		setFunc = function (...) self:OnDrawPost(...) end,
		type = UIItemList.CIRCLE,
		onCenterFunc = function (...) self:OnItemCenter(...) end,
		centerPos = self._curSelect,
		speed = 1200,
		--onReturnFunc = function(...) self:OnItemReturn(...) end,
	})

	local cnt = #dataList
	if cnt <= 2 then
		self.mHelpList.sizeDelta = Vector2.New(-40,0)
	else
		self.mHelpList.sizeDelta = Vector2.New(40,0)
	end

	local isMore = cnt>1

	uiList:EnableScroll(isMore)
	CS.ShowObject(self.mItemList,isMore)
end





------------------------------------------------------------------
return UISuBz


