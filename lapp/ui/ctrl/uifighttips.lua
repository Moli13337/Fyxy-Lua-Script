---
--- Created by BY.
--- DateTime: 2023/10/11 16:27:06
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFightTips:LWnd
local UIFightTips = LxWndClass("UIFightTips", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFightTips:UIFightTips()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFightTips:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFightTips:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFightTips:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIFightTips:OnClickLeftRight(index)
	local _tipsIndex = self._tipsIndex
	if index == 1 and _tipsIndex > 1 then
		_tipsIndex = _tipsIndex - 1
	elseif index == 2 and _tipsIndex < #self._tipsList then
		_tipsIndex = _tipsIndex + 1
	end
	if _tipsIndex == self._tipsIndex then
		return
	end
	self._tipsIndex = _tipsIndex
	self:RefreshData()
end

function UIFightTips:InitMessage()

end

function UIFightTips:InitEvent()
	self:SetWndClick(self.mMask,function () self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end)
	self:SetWndClick(self.mBtnLeft,function () self:OnClickLeftRight(1) end)
	self:SetWndClick(self.mBtnRight,function () self:OnClickLeftRight(2) end)
end

function UIFightTips:InitCommand()
	local targetId = self:GetWndArg("targetId")
	self:SetWndText(self.mTitleText,ccClientText(20911))

	local ref = gModelCareSchool:GetCollegeLibraryCheckpointRefByRefId(targetId)
	local tipsArr = string.split(ref.Tips,",")
	self._tipsList = {}
	for i, v in ipairs(tipsArr) do
		table.insert(self._tipsList,tonumber(v))
	end
	self._tipsIndex = 1
	local len = #self._tipsList
	CS.ShowObject(self.mBtnLeft,len > 1)
	CS.ShowObject(self.mBtnRight,len > 1)
	if len > 0 then
		self:RefreshData()
	end
end

function UIFightTips:RefreshData()
	local tipsRefId = self._tipsList[self._tipsIndex]
	local ref = gModelCareSchool:GetCollegeLibraryTxtRefByRefId(tipsRefId)
	self:SetWndText(self.mDesText,ccLngText(ref.text))
	if LxUiHelper.IsImgPathValid(ref.icon) then
		self:SetWndEasyImage(self.mTitleImg,ref.icon,nil,true)
		local iconSize = string.split(ref.iconSize,",")
		local iconPos = ref.IconPos
		self.mTitleImg.localPosition = Vector2.New(tonumber(iconSize[1]),tonumber(iconSize[2]))
		self.mTitleImg.localScale = Vector2.New(iconPos,iconPos)
	end
end
------------------------------------------------------------------
return UIFightTips


