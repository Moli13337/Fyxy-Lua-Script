---
--- Created by BY.
--- DateTime: 2023/10/11 9:55:47
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdeAwardPop:LWnd
local UIGdeAwardPop = LxWndClass("UIGdeAwardPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdeAwardPop:UIGdeAwardPop()
	self._uiIconEasyList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdeAwardPop:OnWndClose()
	self:ClearCommonIconList(self._uiIconEasyList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdeAwardPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdeAwardPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIGdeAwardPop:OnClickGet()
	gModelGrade:OnGradeRewardReq(self._gradeLevel)
end

function UIGdeAwardPop:InitCommand()
	self:SetWndText(self.mTitleText,ccClientText(18213))
	self:SetWndButtonText(self.mGetBtn,ccClientText(18214))
	CS.ShowObject(self.mUpImage,false)

	local _gradeLevel = self:GetWndArg("refId")
	self._gradeLevel = _gradeLevel
	local ref = gModelGrade:GetGradeLvRefByRefId(_gradeLevel)

	local itemList = LxDataHelper.ParseItem(ref.rewardDaily)
	local uiIconEasyList = self._uiIconEasyList["Award"]
	if(not uiIconEasyList)then
		uiIconEasyList = UIIconEasyList:New()
		uiIconEasyList:Create(self, self.mAwardScroll)
		uiIconEasyList:SetShowNum(true)
		uiIconEasyList:SetIconClickPath("CommonUI")
		self._uiIconEasyList["Award"] = uiIconEasyList
	end
	uiIconEasyList:RefreshList(itemList)

	local nextRef = gModelGrade:GetGradeLvRefByRefId(_gradeLevel + 1)
	if(not nextRef)then
		return
	end
	CS.ShowObject(self.mUpImage,true)
	self:SetWndText(self.mUpDesText,string.replace(ccClientText(18215),ccLngText(nextRef.name)))
	local itemList = LxDataHelper.ParseItem(nextRef.rewardDaily)
	local uiIconEasyList = self._uiIconEasyList["UpAward"]
	if(not uiIconEasyList)then
		uiIconEasyList = UIIconEasyList:New()
		uiIconEasyList:Create(self, self.mUpAwardScroll)
		uiIconEasyList:SetShowNum(true)
		uiIconEasyList:SetIconClickPath("CommonUI")
		self._uiIconEasyList["UpAward"] = uiIconEasyList
	end
	uiIconEasyList:RefreshList(itemList)
end

function UIGdeAwardPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.GradeRewardResp,function (...)
		self:WndClose()
	end)
end

function UIGdeAwardPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
	self:SetWndClick(self.mGetBtn, function(...) self:OnClickGet() end)
end
------------------------------------------------------------------
return UIGdeAwardPop


