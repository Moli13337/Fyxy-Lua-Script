---
--- Created by Administrator.
--- DateTime: 2023/10/9 15:55:58
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActVdoPy:LWnd
local UIActVdoPy = LxWndClass("UIActVdoPy", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActVdoPy:UIActVdoPy()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActVdoPy:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActVdoPy:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActVdoPy:OnStart()
	LWnd.OnStart(self)
	self:InitUI()


	self:SetWndClick(self.mSkipBtn,function() self:OnClickSkip() end)
	CS.ShowObject(self.mSkipBtn,false)
	self:PlayVideo()


	local timePara = {
		key = "delayShowEntrance",
		interval = 0.2,
		func = function()
			FireEvent(EventNames.ACT_VIDEO_PLAY_START)
		end,
		loopcnt = 1,
	}
	self:TimerStartImpl(timePara)

end

function UIActVdoPy:StopVideo()
	if self._videoPath then
		gLGameVideo:StopVideo(nil,self._videoPath)
		self._videoPath = nil
	end
end

function UIActVdoPy:OnClickSkip()

	self:StopVideo()

	if self._isNotLook then
		gModelActivity:OnActivitySpecialOpReq(self._sid,nil,nil,nil, nil, ModelActivity.VIDEO_REWARD_85)
	end

	self:WndClose()
end

function UIActVdoPy:OnVideoPlayEnd()
	self:StopVideo()

	if self._isNotLook then
		gModelActivity:OnActivitySpecialOpReq(self._sid,nil,nil,nil, nil, ModelActivity.VIDEO_REWARD_85)
	end

	self:WndClose()
end

function UIActVdoPy:PlayVideo()
	self._sid = self:GetWndArg("sid")
	local video = self:GetWndArg("video")
	self._isNotLook = self:GetWndArg("isNotLook")

	local temps = string.split(video,"=")

	local videoRes = temps[1]
	local skipTime = tonumber(temps[2])

	self._videoPath = videoRes

	local timePara = {
		key = "delayShowSkip",
		interval = skipTime,
		func = function()
			CS.ShowObject(self.mSkipBtn,true)
		end,
		loopcnt = 1,
	}
	self:TimerStartImpl(timePara)

	gLGameVideo:PlayVideoClipUI(videoRes,function ()
		self:OnVideoPlayEnd()
	end ,self.mVideoMan)
end



------------------------------------------------------------------
return UIActVdoPy


