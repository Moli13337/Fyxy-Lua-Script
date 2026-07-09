---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIRkAwardPop:LWnd
local UIRkAwardPop = LxWndClass("UIRkAwardPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIRkAwardPop:UIRkAwardPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIRkAwardPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIRkAwardPop:OnCreate()
	LWnd.OnCreate(self)
	self._uiheadList={}
	self._destStr=""--里程碑cell字体样式
	self._uicommonList={}
	self._uiCellList=nil
	self._uiPopCellList=nil
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIRkAwardPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()


	self._isVie =gLGameLanguage:IsVieVersion()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIRkAwardPop:SetPopCellListItem(list,item, itemdata, itempos)
	local headIcon=CS.FindTrans(item,"HeadIcon")
	local nameText=CS.FindTrans(item,"NameText")
	local timeText=CS.FindTrans(item,"TimeText")
	local numImage=CS.FindTrans(item,"NumImage")
	local numXUIText=CS.FindTrans(item,"NumXUIText")
	local leve =CS.FindTrans(item,"HeadIcon/lvBg/level")
	if self._isVie then
		self:SetAnchorPos(leve,Vector2.New(0,-8))
	end
	if(itempos>3)then
		CS.ShowObject(numImage,false)
		CS.ShowObject(numXUIText,true)
		self:SetWndText(numXUIText, string.replace(ccClientText(11725), itempos))
	else
		CS.ShowObject(numImage,true)
		CS.ShowObject(numXUIText,false)
		self:SetWndEasyImage(numImage,"public_num_"..itempos)
	end
	local playerData=itemdata.info--玩家数据
	if(not playerData)then
		return
	end
	local playerInfo={
		trans=headIcon,
		icon=playerData._head,
		headFrame=playerData._headFrame,
		level=playerData._grade
	}
	self:SetWndText(nameText,playerData._name)
	self:SetWndText(timeText,ccClientText(11709)..LUtil.OSDate(" %Y-%m-%d  %H:%M:%S", tonumber(itemdata.completeTime)/1000))
	local uiheadlist = self._uiheadList
	local InstanceID = item:GetInstanceID()
	local baseClass = uiheadlist[InstanceID]
	if not baseClass then
		baseClass = HeadIcon:New(self)
		uiheadlist[InstanceID] = baseClass
	end
	baseClass:SetHeadData(playerInfo)
	baseClass:RefreshUI()
end

function UIRkAwardPop:InitCommand()
	self:SetWndText(self.mTitleText,ccClientText(11705))
	local uiList = self:GetUIScroll("cell")
	local list=gModelRank:GetMilestoneShowList()
	table.sort(list, function(a,b)
		return a.completeTime < b.completeTime
	end)
	uiList:Create(self.mCellScroll,list,function (...) self:SetPopCellListItem(...) end)
end

function UIRkAwardPop:InitMessage()--接协议
end

function UIRkAwardPop:InitEvent()
	self:SetWndClick(self.mBgImage, function (...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end
------------------------------------------------------------------
return UIRkAwardPop


