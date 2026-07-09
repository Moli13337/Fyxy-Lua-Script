---
--- Created by Administrator.
--- DateTime: 2023/10/9 17:53:47
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHeartMusic:LWnd
local UIHeartMusic = LxWndClass("UIHeartMusic", LWnd)

local Tweening = DG.Tweening
local LocalAxisAdd = Tweening.RotateMode.LocalAxisAdd

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHeartMusic:UIHeartMusic()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHeartMusic:OnWndClose()

	self:CloseMusic()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHeartMusic:OnCreate()
	LWnd.OnCreate(self)
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHeartMusic:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:InitUIEvent()
	self:SetStaticContent()
	self:OnWndRefresh()

	self:WndEventRecv(EventNames.ON_JUMP,function ()
		self:WndClose()
	end)

end

function UIHeartMusic:InitData()
	local from = self.mStart.position
	local to = self.mEnd.position
	local top = self.mTop.position

	local curveFunc = LCurveUtil.BezierSecond(from,to,top,1)

	self._curveFunc = curveFunc

	self._musicPlayTimeKey = "_musicPlayTimeKey"
end

function UIHeartMusic:CloseMusic()
	gLGameAudio:SetWndMusicPlayTime(0)
	gLGameAudio:OnCloseWndMusic(self:GetWndName())
	gLGameAudio:CancelTempVolume()
end

function UIHeartMusic:OnWndRefresh()
	self._itemData = self:GetWndArg("itemdata")
	local skinId = self._itemData.activateSkin
	local isActMainCitySkin = (not skinId or skinId == 0) or gModelPlayerSpace:GetMainCitySkinByRefId(skinId)

	self:StartPlayMusic()

	local curBack = gModelOneNight:GetBackgroundMusic()
	local isCur = curBack == self._itemData.refId

	CS.ShowObject(self.mBtnSet,not isCur and isActMainCitySkin)
	CS.ShowObject(self.mTag,isCur)



end

function UIHeartMusic:InitUIEvent()
	self:SetWndSliderDelegate(self.mSliderRoot,function (value)
		self:OnValueChange(value)
	end)
	CS.SetOnBeginDrag(self.mSliderRoot.gameObject,function ()
		self:OnBeginDrag()
	end)

	CS.SetOnDrag(self.mSliderRoot.gameObject,function ()
		self:OnDrag()
	end)

	CS.SetOnEndDrag(self.mSliderRoot.gameObject,function ()
		self:OnEndDrag()
	end)

	CS.SetClick(self.mSliderRoot.gameObject,function ()
		self:OnClickSlider()
	end)

	self:SetWndClick(self.mBtnClose,function ()
		self:WndClose()
	end)

	self:SetWndClick(self.mSurface,function ()
		if self._isPlaying then
			self:PauseMusic()
		else
			self:ResumeMusic()
		end
	end)

	self:SetWndClick(self.mBtnSet,function ()
		gModelOneNight:SetBackgroundMusic(self._itemData.refId)
		CS.ShowObject(self.mBtnSet,false)
		CS.ShowObject(self.mTag,true)

		local str =ccClientText(26107)-- "设置成功"
		GF.ShowMessage(str)
	end)

	self:SetWndClick(self.mMask,function ()
		self:WndClose()
	end)
end

function UIHeartMusic:StartPlayMusic()
	local music = self._itemData.musicRes
	if string.isempty(music) then return end

	local wndName = self:GetWndName()
	if self._playMusicName and self._playMusicName ~= music then
		self:CloseMusic()
	end

	local icon = self._itemData.flillRes
	self:SetWndEasyImage(self.mMusicIcon,icon)

	self._playMusicName = music
	gLGameAudio:OnPlayWndMusic(music,wndName)
	gLGameAudio:SetTempVolume(1)

	self:TimerStart(self._musicPlayTimeKey, 1, false,-1)
	self:RefreshSlider()
	self._isPlaying = true
	self:RefreshTotalTimeTxt()
	self:TweenSurface()
end

function UIHeartMusic:PauseMusic()
	self._isPlaying = false
	gLGameAudio:OnPauseWndMusic(self:GetWndName(), true)

	self:PauseTween()

	self:SetWndEasyImage(self.mStateIcon,"activity_music1_icon_btn_4")
end

function UIHeartMusic:SetStaticContent()
	local str =ccClientText(26106)-- "设置成主城音乐")
	self:SetTextTile(self.mBtnSet,str)
end

function UIHeartMusic:OnClickSlider()
	self:ChangeTime()
end

function UIHeartMusic:OnTimer(key)
	if self._musicPlayTimeKey == key then
		self:RefreshSlider()
	end
end

function UIHeartMusic:ResumeMusic()
	self._isPlaying = true
	gLGameAudio:OnPauseWndMusic(self:GetWndName(), false)

	self:TweenSurface()

	self:SetWndEasyImage(self.mStateIcon,"activity_music1_btn_1")

end

function UIHeartMusic:RefreshSlider()
	local musicTime    = gLGameAudio:GetWndMusicPlayTime(self:GetWndName())
	local musicLength  = self:GetMusicLength()
	local progress 	   = 0
	if musicLength and musicLength > 0 then
		progress    = musicTime / musicLength
	end

	self:SetWndSliderPara(self.mSliderRoot,progress)

	local timeStr    = LUtil.FormatTimespanToMin2New(musicTime)
	self:SetWndText(self.mCurTimeTxt, timeStr)

	self:RefreshTotalTimeTxt()
end

function UIHeartMusic:OnEndDrag()
	self:TimerStart(self._musicPlayTimeKey, 1, false,-1)
	self:ChangeTime()
end

function UIHeartMusic:PauseTween()
	local seqCom = self:GetSeqCom()
	local seq = seqCom:FindSeq("tweenSurface")
	if seq then
		seq:Pause()
	end
end

function UIHeartMusic:OnDrag()
	local slider = self:FindWndSlider(self.mSliderRoot)
	local value = slider.value

	local length = self:GetMusicLength()
	local curTime = value * length

	local timeStr    = LUtil.FormatTimespanToMin2New(curTime)
	self:SetWndText(self.mCurTimeTxt, timeStr)
end

function UIHeartMusic:RefreshTotalTimeTxt()
	local musicLength = self:GetMusicLength()
	local timeStr     = LUtil.FormatTimespanToMin2New(musicLength)
	self:SetWndText(self.mTotalTimeTxt, timeStr)
end

function UIHeartMusic:TweenSurface()
	local seqCom = self:GetSeqCom()
	local seq = seqCom:FindSeq("tweenSurface")
	if not seq then
		seq = seqCom:CreateSeq("tweenSurface")
		local tween = self.mSurface.transform:DOLocalRotate(Vector3.New(0,0,-360),15,LocalAxisAdd)
		seq:Append(tween)
		seq:SetLoops(-1)
		seq:PlayForward()
	else
		seq:Play()
	end
end

function UIHeartMusic:GetMusicLength()
	if not self._musicLength or self._musicLength <= 0 then
		self._musicLength = gLGameAudio:GetWndMusicLength(self:GetWndName())
	end

	return self._musicLength
end

function UIHeartMusic:OnValueChange(value)
	local pos = self._curveFunc(value)
	self.mHandleIcon.position = pos
end

function UIHeartMusic:ChangeTime()
	local slider = self:FindWndSlider(self.mSliderRoot)
	local value = slider.value

	local length = self:GetMusicLength()
	local time = value * length
	time = math.min(time,length -0.1)

	gLGameAudio:SetWndMusicPlayTime(time)
end

function UIHeartMusic:OnBeginDrag()
	self:TimerStop(self._musicPlayTimeKey)
end


------------------------------------------------------------------
return UIHeartMusic


