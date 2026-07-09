---
--- Created by Administrator.
--- DateTime: 2023/10/8 19:16:45
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIVdoPer:LWnd
local UIVdoPer = LxWndClass("UIVdoPer", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIVdoPer:UIVdoPer()
	self._skipNum = 3
	self._videoSliderKey = "_videoSliderKey"

	self._waitPlayVideoTimerKey = "_waitPlayVideoTimerKey"
	self._videoPlayTimeKey = "_videoPlayTimeKey"
	self._releaseDragTimeKey = "_releaseDragTimeKey"

	self._canOpenJumpBtnTimeKey = "_canOpenJumpBtnTimeKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIVdoPer:OnWndClose()
	gLGameVideo:StopVideo()
	if self._func then
		self._func()
	end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIVdoPer:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIVdoPer:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:InitView()
end

function UIVdoPer:OnVideoLoadingEnd()
	self:CanSkipTimeStart()
	--加载结束，更新进度条，时间信息
	if self._needSlider then
		self:RefreshTotalTimeTxt()
		self:RefreshSlider()
		self:TimerStart(self._videoPlayTimeKey, 0.1, false,-1)
	end
end

function UIVdoPer:OnSpeedFun()
	if not self._isCanJump then return end

	local num=self._onClickNum
	if(not num)then
		num=0
	end
	num=num+1
	self._onClickNum=num

	if(self._onClickNum >= self._skipNum)then
		self:SetSkipBtnShow(true)
	end
end

function UIVdoPer:RefreshTotalTimeTxt()
	local videoLength = self:GetVideoLength()
	local timeStr     = LUtil.FormatTimespanToMin2New(videoLength)
	self:SetWndText(self.mTotalTimeTxt, timeStr)
end
--#####################################################################################################################
--## Common ###########################################################################################################
--#####################################################################################################################
function UIVdoPer:InitView()
	self:SetSkipBtnShow(false)
	self:SetWndText(self.mSkipBtnTxt, ccClientText(23237))
	self:TimerStart(self._waitPlayVideoTimerKey, 1, false, 1)
end

--#####################################################################################################################
--## Timer ############################################################################################################
--#####################################################################################################################
function UIVdoPer:OnTimer(key)
	if key == self._videoPlayTimeKey then
		if not self._isDragChange then
			self:RefreshSlider()
		end
	elseif key == self._releaseDragTimeKey then
		self._isDragChange = false
	elseif key == self._canOpenJumpBtnTimeKey then
		self:SetCanSkip()
	elseif key == self._waitPlayVideoTimerKey then
		self:VideoPlayStart()
		self:InitSlider()
	end
end

function UIVdoPer:GetVideoLength()
	if not self._videoLength then
		self._videoLength = gLGameVideo:GetVideoLength()
	end

	return self._videoLength
end

function UIVdoPer:RefreshSlider()
	local videoTime    = gLGameVideo:GetVideoTime()
	local videoLength  = self:GetVideoLength()
	local progress	   = videoTime / videoLength
	self._videoSlider:SetUIProgress(progress)
	self:RefreshCurTimeTxt(videoTime)
end

function UIVdoPer:OnVideoSliderValueChange(value)
	if not self._isDragChange then return end

	local videoLength = self:GetVideoLength()
	self._dragChangeVideoTime = math.range(value * videoLength, 0, videoLength)
	self:RefreshCurTimeTxt(self._dragChangeVideoTime)
end

function UIVdoPer:InitMsg()
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:FastCloseWndFunc() end)
	self:WndEventRecv(EventNames.ON_ENTER_BATTLE_MAP,function () self:FastCloseWndFunc() end)
	self:WndEventRecv(EventNames.LOADING_VIDEO_COMPLETE, function (...) self:OnVideoLoadingEnd(...) end)
	self:WndEventRecv(EventNames.LOADING_VIDEO_ERROR, function (...) self:OnVideoLoadingError(...) end)
end


function UIVdoPer:OnLongClickSliderDown()
	self:TimerStop(self._releaseDragTimeKey)
	self._isDragChange = true
	gLGameVideo:PauseVideo()

	if self._videoSlider then
		self._videoSlider:SetInteractable(true)
	end
end

function UIVdoPer:OnSkipBtn()
	self:CloseWndFunc()
end

function UIVdoPer:SetSkipBtnShow(isShow)
	CS.ShowObject(self.mSkipBtnObj, isShow)
	CS.ShowObject(self.mScreenBtnObj, not isShow)
end

function UIVdoPer:RefreshCurTimeTxt(curVideoTime)
	if not curVideoTime then
		curVideoTime = gLGameVideo:GetVideoTime()
	end
	local timeStr     = LUtil.FormatTimespanToMin2New(curVideoTime)
	self:SetWndText(self.mCurTimeTxt, timeStr)
end

function UIVdoPer:SetCanSkip(isMust)
	self._isCanJump = true
	if self._openJumpBtn or isMust then
		self:SetSkipBtnShow(true)
	end
end

--#####################################################################################################################
--## Slider ###########################################################################################################
--#####################################################################################################################
function UIVdoPer:InitSlider()
	CS.ShowObject(self.mSlider, self._needSlider)
	if not self._needSlider then return end

	self._videoSlider = self:UIProgressFind(self.mSliderRoot,self._videoSliderKey,0)
	self._videoSlider:SetSliderDelegate(function (value)
		self:OnVideoSliderValueChange(value)
	end)

	self._videoSlider:SetInteractable(false)
end

function UIVdoPer:OnLongClickSliderUp()
	if self._videoSlider then
		self._videoSlider:SetInteractable(false)
	end

	if self._dragChangeVideoTime then
		gLGameVideo:SetVideoTime(self._dragChangeVideoTime)
	end

	gLGameVideo:ContinueToPlayVideo()
	self._dragChangeVideoTime = nil
	self:TimerStart(self._releaseDragTimeKey, 0.3, false, 1)
end

function UIVdoPer:VideoPlayEndFunc()
	self:CloseWndFunc()
end

function UIVdoPer:CanSkipTimeStart()
	if self:IsTimerExist(self._canOpenJumpBtnTimeKey) then return end
	self:TimerStart(self._canOpenJumpBtnTimeKey, 1.5, false, 1)
end

function UIVdoPer:FastCloseWndFunc()
	self._func = nil
	self:WndClose()
end

function UIVdoPer:OnVideoLoadingError()
	self:SetCanSkip(true)
end

function UIVdoPer:InitData()
	self._videoName = self:GetWndArg("videoName") or "video_op_1"
	self._needSlider= self:GetWndArg("needSlider") or false
	self._openJumpBtn  = self:GetWndArg("openJumpBtn") or false
	self._func      = self:GetWndArg("func")

	self._videoSlider = nil
	self._isDragChange = false
	self._dragChangeVideoTime = nil
	self._isCanJump = false
end


--#####################################################################################################################
--## Video ############################################################################################################
--#####################################################################################################################
function UIVdoPer:VideoPlayStart()
	local videoName = self._videoName
	if not videoName or string.isempty(videoName) then
		GF.ShowMessage(ccClientText(23235))
		self:CloseWndFunc()
		return
	end

	local playEndFunc = function()
		self:VideoPlayEndFunc()
	end

	gLGameVideo:PlayVideoClipUI(videoName, playEndFunc, self.mVideoMan, false)
end

function UIVdoPer:InitEvent()
	self:SetWndClick(self.mScreenBtnObj,function(...) self:OnSpeedFun() end)
	self:SetWndClick(self.mSkipBtnObj,function(...) self:OnSkipBtn() end)

	self:SetWndLongClick(self.mSliderRoot,function()
		self:OnLongClickSliderDown()
	end,0.05,true,0, function()
		self:OnLongClickSliderUp()
	end)
end

function UIVdoPer:CloseWndFunc()
	self:WndClose()
end


------------------------------------------------------------------
return UIVdoPer


