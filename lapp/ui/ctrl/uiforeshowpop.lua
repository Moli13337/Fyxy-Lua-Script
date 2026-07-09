---
--- Created by Administrator.
--- DateTime: 2025/7/7 15:25:47
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIForeshowPop:LWnd
local UIForeshowPop = LxWndClass("UIForeshowPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIForeshowPop:UIForeshowPop()
	self._timeKey = "WndforeshowPopTimeKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIForeshowPop:OnWndClose()
	if self.config.tip>0 and self.mToggleGou.gameObject.activeSelf then 
		gModelFunctionOpen:OnForeshowPopRecrodReq(self.info.refId) 
	end
	self:TimerStop(self._timeKey)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIForeshowPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIForeshowPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvntClick()
	self.info = self:GetWndArg("info")
	if not self.info then return end
	self.config = GameTable.ForeshowPopRef[self.info.refId]
	self:RefreshView()
	self:StartTimer()
end

function UIForeshowPop:RefreshView()
	if self.config then
		local bgPath = self.config.image
		self:SetWndEasyImage(self.mImgBg,bgPath,nil,true)

		local pathStr = self.config.cellBgTxt
		if not string.isempty(pathStr) then
			local paths = string.split(pathStr,"|")
			local pathPos = string.split(self.config.cellBgTxtPos)
			local trans = self.mImgTitle
			local parent = self.mImgTitle.parent
			for index, path in ipairs(paths) do
				if index>1 then
					local obj = CS.InstantObject(self.mImgTitle.gameObject)
					trans = obj.transform
					trans:SetParent(parent)
				end
				self:SetWndEasyImage(trans,path,nil,true)
				local pos = LxDataHelper.ParseVector2NotEmpty2(pathPos[index])
				self:SetAnchorPos(trans, pos)
			end
			CS.ShowObject(self.mImgTitle,true)
		else
			CS.ShowObject(self.mImgTitle,false)
		end

		if self.info.endTime<=0 then
			self:SetWndText(self.mTxtDesc,ccLngText(self.config.cellNameDec))
		end
		local pos = LxDataHelper.ParseVector2NotEmpty2(self.config.cellNameDecPos)
		self:SetAnchorPos(self.mTxtDesc,pos)

		local btnIcon = self.config.jumpBtnIcon
		if not string.isempty(btnIcon) then
			local btnImg = self:FindChild(self.mBtnJump,"Light")
			self:SetWndEasyImage(btnImg,btnIcon,nil,true)
		end
		local btnPos = LxDataHelper.ParseVector2NotEmpty2(self.config.jumpBtnPos)
		self:SetAnchorPos(self.mBtnJump,btnPos)
		self:SetWndButtonText(self.mBtnJump,ccLngText(self.config.jumpBtnText))

		if self.config.tip>0 then
			CS.ShowObject(self.mToggle,true)
			local tipPos = LxDataHelper.ParseVector2NotEmpty2(self.config.tipPos)
			self:SetAnchorPos(self.mToggleGou,tipPos)
			local showGou = self.config.tipInitial>0
			CS.ShowObject(self.mToggleGou,showGou)
			self:SetWndText(self.mToggleText,ccLngText(self.config.tipDesc))
		else
			CS.ShowObject(self.mToggle,false)
		end


	end
end

function UIForeshowPop:SetTime()
	local time = GetTimestamp()
	local timespan = (self.info.endTime/1000) - time
	local  timeStr = ""
	if(timespan < 0)then
		timeStr = ccClientText(14301)
		self:TimerStop(self._timeKey)
	else
		local timeF = ccLngText(self.config.cellNameDec)
		timeStr = LUtil.FormatTimespanCn(timespan)
		timeStr = string.replace(timeF,timeStr)
	end
	self:SetWndText(self.mTxtDesc,timeStr)
end

function UIForeshowPop:InitEvntClick()
	self:SetWndClick(self.mBtnJump,function ()
		self:OnJumpClick()
	end)
	self:SetWndClick(self.mMask,function ()
		self:WndClose()
	end)

	self:SetWndClick(self.mToggle,function()
		CS.ShowObject(self.mToggleGou,not self.mToggleGou.gameObject.activeSelf)
	end)
end

function UIForeshowPop:OnTimer(key)
	if(key == self._timeKey)then
		self:SetTime()
	end
end
function UIForeshowPop:OnJumpClick()
	local jumpId = self.config.functionOpen
	if jumpId>0 then
		gModelFunctionOpen:Jump(jumpId)
		self:WndClose()
	end
end

function UIForeshowPop:StartTimer()
	if self.info.endTime and self.info.endTime> 0 then
		self:SetTime()
		self:TimerStop(self._timeKey)
    	self:TimerStart(self._timeKey, 1, false, -1)
	end
end

------------------------------------------------------------------
return UIForeshowPop