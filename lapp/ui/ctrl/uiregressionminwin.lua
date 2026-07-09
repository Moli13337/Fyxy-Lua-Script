---
--- Created by Administrator.
--- DateTime: 2024/8/8 14:43:51
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIRegressionMinWin:LWnd
local UIRegressionMinWin = LxWndClass("UIRegressionMinWin", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIRegressionMinWin:UIRegressionMinWin()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIRegressionMinWin:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIRegressionMinWin:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIRegressionMinWin:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end)
	self:SetWndText(self.mTxtClose,ccClientText(10320))
	self:InitDatas()
	self:InitTabList()
	self:OpenChildCtrl()
end

function UIRegressionMinWin:DoChangeTab(index)
    if self._curTabIndex == index then return end
	local itemData = self._tabDatas[index].cfg
	if itemData.functionId and not gModelFunctionOpen:CheckIsOpened(itemData.functionId,true) then return end
    local oldIndex = self._curTabIndex
    self._curTabIndex = index
	self:SetWndTabStatus(self._tabList[oldIndex],1,oldIndex)
	self:SetWndTabStatus(self._tabList[index],0,index)

	local uiname = self._tabDatas[index].data.uiName
	local params = self:GetWndArgList()
	params.refId = self._tabDatas[index].cfg.refId
    self:CreateChildWnd(self.mChildRoot,uiname,params)
	local childPetRelation = self:FindChild("UISubRegressionYell")
	if childPetRelation and childPetRelation._wndTrans then
		CS.ShowObject(childPetRelation._wndTrans,childPetRelation._wndName==uiname)
	end
	local UISubRegressionPuzzle = self:FindChild("UISubRegressionPuzzle")
	if UISubRegressionPuzzle and UISubRegressionPuzzle._wndTrans then
		UISubRegressionPuzzle:DestroyWndEffectByKey("fx_ui_pintu_jihuo_wancheng")
		UISubRegressionPuzzle:DestroyWndEffectByKey("fx_ui_pintu_jihuo")
		CS.ShowObject(UISubRegressionPuzzle._wndTrans,UISubRegressionPuzzle._wndName==uiname)
	end
end

function UIRegressionMinWin:RefreshSelectTable(newIndex,oldIndex)
    self:SetWndTabStatus(self._tabList[oldIndex],1,oldIndex)
	self:SetWndTabStatus(self._tabList[newIndex],0,newIndex)

	local params = self:GetWndArgList()
	params.refId = self._tabDatas[newIndex].cfg.refId
    self:CreateChildWnd(self.mChildRoot,self._tabDatas[newIndex].data.uiName,params )
end


function UIRegressionMinWin:InitDatas()
   local panelInfo = {
		[1] = {uiName="UISubRegressionYell",icon ="regression_btn_5"},
		[2] = {uiName="UISubRegressionSign",icon ="regression_btn_3"},
		[3] = {uiName="UISubRegressionPuzzle",icon ="regression_btn_2"},
		[4] = {uiName="UISubRegressionBoss",icon ="regression_btn_1"},
		[5] = {uiName="UISubRegressionGift",icon ="regression_btn_4"},
    }
	self._tabDatas = {}
	self._tabList = {}
	local cfgs = GameTable.ReturnBackBackflowRef
	for _, value in pairs(cfgs) do
		local data = panelInfo[value.type]
		if data then table.insert(self._tabDatas,{cfg = value,data = data}) end
	end
	table.sort(self._tabDatas,function(a,b)
		return a.cfg.type>b.cfg.type
	end)

    local type = self:GetWndArg("funcType") or self:GetWndArg("page")
    self._curTabIndex = #self._tabDatas
    if type then
		for k,v in ipairs(self._tabDatas) do
			if v.cfg.type == type then
				if not v.cfg.functionId or (v.cfg.functionId and gModelFunctionOpen:CheckIsOpened(v.cfg.functionId,true)) then
					self._curTabIndex = k
				end
				break
			end
		end
	end

end

function UIRegressionMinWin:OpenChildCtrl()
    local uiName = self._tabDatas[self._curTabIndex].data.uiName
    if string.isempty(uiName) then return end
	local params = self:GetWndArgList()
	params.refId = self._tabDatas[self._curTabIndex].cfg.refId
	self:CreateChildWnd(self.mChildRoot,self._tabDatas[self._curTabIndex].data.uiName,params)
	self:SetWndTabStatus(self._tabList[self._curTabIndex],0,self._curTabIndex)
end

function UIRegressionMinWin:OnDrawTab(list, item, itemData, index)
	self:SetWndTabText(item,ccLngText(itemData.cfg.name),nil,true)
	--
	local isLock = itemData.cfg.functionId and not gModelFunctionOpen:CheckIsOpened(itemData.cfg.functionId,false)
	self:SetWndTabStatus(item, isLock and 2 or 1)
	self:SetWndTabIcon(item,itemData.data.icon,itemData.data.icon)
	self._tabList[index] = item
	self:SetWndClick(item, function (...)
		self:DoChangeTab(index) end)

	local funcRed =function (isShow)
		local RedPoint=self:FindWndTrans(item,"redPoint")
		CS.ShowObject(RedPoint,isShow)
	end
	local redId = gModelRedPoint:GetRedIdByFuncId(itemData.cfg.functionId)
	if redId and redId>0 then self:RegisterRedPointFunc(redId,funcRed) end
end

function UIRegressionMinWin:InitTabList()
    local uiList = self:GetUIScroll("badgeTab")
	uiList:Create(self.mTabScroll,self._tabDatas,function(...) self:OnDrawTab(...) end)
    self._tabUiList = uiList
end


------------------------------------------------------------------
return UIRegressionMinWin