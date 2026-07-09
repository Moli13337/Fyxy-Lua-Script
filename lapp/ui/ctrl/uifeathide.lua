---
--- Created by Administrator.
--- DateTime: 2023/10/23 20:54:08
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFeatHide:LWnd
local UIFeatHide = LxWndClass("UIFeatHide", LWnd)
local YXUIPointUtil = CS.YXUIPointUtil
local UnityEngine = UnityEngine
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFeatHide:UIFeatHide()
	self._showTextImgTweenKey = "_showTextImgTweenKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFeatHide:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFeatHide:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFeatHide:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	--self:DoWndStartScale(0,self.mTopView)
	self:InitData()
	self:InitMsg()
	self:InitEvent()
	self:InitContent()
	self:InitEffect()
	self:ShowTextImg()
	LxUiHelper.PlayAudioSoundName(32)

	self:SetWndButtonText(self.mCloseBtn, ccClientText(19537))
	self:SetWndButtonText(self.mShareBtn, ccClientText(19510))
end

function UIFeatHide:OnClickShare()
	local achievementData = gModelAchievement:GetAchievementDataByRefId(self._refId)
	if not achievementData then
		LogError("achievementData is not find, refId = "..(self._refId or "nil"))
		return
	end

	local shareData = {
		achievementRefId = self._refId,
		achievementState = achievementData:GetState(),
		achievementDate = achievementData:GetFinishTime(),
		achievementRate = achievementData:GetServerVal(),
		fightPower 	 	= gModelPlayer:GetPlayerFightPower(),
		playerLevel  	= gModelPlayer:GetPlayerLv(),
	}

	local jsonStr = JSON.encode(shareData)
	local data = {
		root 	  = self.mShareBtn,
		shareType = ModelChat.CHATSHARE_ACHIEVEMENT,
		shareData = jsonStr
	}

	gModelGeneral:OpenShareTip(data)
end


function UIFeatHide:OnTargetWndClose(wndName)
	if self._needHideWndList[wndName] then
		CS.ShowObject(self.mTopView, true)
	end
end

function UIFeatHide:InitEffect()
	self:CreateWndEffect(self.mEffectRoot,self._effectKey,self._effectKey,100,false,false)
end

function UIFeatHide:ShowTextImg()
	self._canvasGroupSeq = self:TweenSeq_AlphaCanvasTrans(self._showTextImgTweenKey, self.mTextImg, 0, 1, 0.5)
end

function UIFeatHide:InitEvent()
	self:SetWndClick(self.mMask, function(...) self:OnClickClose()  end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn, function(...) self:OnClickClose()  end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mShareBtn, function(...) self:OnClickShare() end)
end

function UIFeatHide:InitContent()
	local cfg			= gModelAchievement:GetAchievementConfig(self._refId)
	if not cfg then
		return
	end

	local achievementName = ccLngText(cfg.name)
	local achievementDesc = ccLngText(cfg.description)
	self:SetWndText(self.mTitleText, achievementName)
	self:SetWndText(self.mText, achievementDesc)
end

function UIFeatHide:InitMsg()
	self:WndEventRecv(EventNames.ON_WND_FINISH,function (...) self:OnTargetWndOpen(...) end)
	self:WndEventRecv(EventNames.ON_WND_CLOSE,function (...) self:OnTargetWndClose(...) end)
end

function UIFeatHide:InitRefId()
	self._refId = gModelAchievement:GetNextPopupRefId()
end

function UIFeatHide:OnTargetWndOpen(wndName)
	if self._needHideWndList[wndName] then
		CS.ShowObject(self.mTopView, false)
	end
end

function UIFeatHide:OnClickClose()
	if not gModelAchievement:CheckHavePopup() then
		self:WndClose()
		return
	end

	self:InitRefId()
	self:InitContent()
end

function UIFeatHide:InitData()
	self._refId 		= self:GetWndArg("refId")
	self._effectKey = "effect_yincangchengjiu"

	if not self._refId then
		self:InitRefId()
	end

	self._needHideWndList = {
		["UIPtTwo"] = true,
	}

	self._canvasGroupSeq= nil
end



------------------------------------------------------------------
return UIFeatHide


