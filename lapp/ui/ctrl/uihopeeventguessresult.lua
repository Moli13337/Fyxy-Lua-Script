---
--- Created by Administrator.
--- DateTime: 2023/10/15 10:37:12
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeEventGuessResult:LWnd
local UIHopeEventGuessResult = LxWndClass("UIHopeEventGuessResult", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeEventGuessResult:UIHopeEventGuessResult()
	self._gotoBattleKey = "_gotoBattleKey"
	self._headIconList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeEventGuessResult:OnWndClose()
	if self._func then self._func() end
	if self._rewardFunc then self._rewardFunc() end
	self:ClearCommonIconList(self._headIconList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeEventGuessResult:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeEventGuessResult:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndText(self.mLeftTitle,ccClientText(20425))
	self:SetWndText(self.mRightTitle,ccClientText(20426))
	self:InitEvent()
	self:InitData()
	self:InitView()
	self:RefreshView()
end

function UIHopeEventGuessResult:CreateHeadIcon(headInfo,isLeft)
	local trans = headInfo.headTrans
	local headIconTran = self:FindWndTrans(trans,"HeadIcon")
	if headIconTran then
		local instanceId = trans:GetInstanceID()
		local headIcon = self._headIconList[instanceId]
		if not headIcon then
			headIcon = HeadIcon:New(self)
			self._headIconList[instanceId] = headIcon
		end
		local headData = {
			trans = headIconTran,
			headFrameStr = headInfo.headFrameStr,
			headStr = headInfo.headStr,
			noLv = true
		}
		if isLeft then
			headData = {
				trans = headIconTran,
				headFrame = headInfo.headFrameStr,
				headStr = headInfo.headStr,
				noLv = true
			}
		end
		headIcon:SetHeadData(headData)
		headIcon:RefreshUI()
	end
	CS.ShowObject(trans,true)
end

function UIHopeEventGuessResult:RefreshView()
	local leftInfo = self._leftInfo
	local rightInfo = self._rightInfo
	if not leftInfo then
		self._closeWnd = true
		return
	end
	if not rightInfo then
		self._closeWnd = true
		return
	end
	self:TimerStop(self._gotoBattleKey)
	self:TimerStart(self._gotoBattleKey,0.9,false,1)
end

function UIHopeEventGuessResult:OnTimer(key)
	if key == self._gotoBattleKey then
		self:ShowResult()
	end
end

function UIHopeEventGuessResult:InitView()
	local leftInfo = self._leftInfo
	local rightInfo = self._rightInfo
	if not leftInfo then return end
	if not rightInfo then return end

	local isForeign = gLGameLanguage:IsForeignRegion()
	local leftName = leftInfo.name
	local leftNameTextTrans = isForeign and self.mLeftNameTextEn or self.mLeftNameText
	CS.ShowObject(leftNameTextTrans, true)
	self:SetWndText(leftNameTextTrans,leftName)

	local rightName = rightInfo.name
	local rightNameTextTrans = isForeign and self.mRightNameTextEn or self.mRightNameText
	CS.ShowObject(rightNameTextTrans, true)
	self:SetWndText(rightNameTextTrans,rightName)

	local leftResult = leftInfo.result
	local leftSpName = self._spineShow[leftResult].spineName
	local leftAniName = self._spineShow[leftResult].leftAniName

	local rightResult = rightInfo.result
	local rightSpName = self._spineShow[rightResult].spineName
	local rightAniName = self._spineShow[rightResult].rightAniName

	local leftHeadInfo = {
		headTrans = self.mLeftHeadIcon,
		headStr = leftInfo.headImg,
		headFrameStr = leftInfo.headFrameImg,
	}
	self:CreateHeadIcon(leftHeadInfo,true)
	local rightHeadInfo = {
		headTrans = self.mRightHeadIcon,
		headStr = rightInfo.headImg,
		headFrameStr = rightInfo.headFrameImg,
	}
	self:CreateHeadIcon(rightHeadInfo)

	CS.ShowObject(self.mLeftSpPos,true)
	self:CreateWndSpine(self.mLeftSpPos,leftSpName,self._leftKey,false,function(spine)
		spine:PlayAnimationSolid(leftAniName,false)
		CS.ShowObject(self.mLeftSpPos,true)
	end)

	CS.ShowObject(self.mRightSpPos,true)
	self:CreateWndSpine(self.mRightSpPos,rightSpName,self._rightKey,false,function(spine)
		spine:PlayAnimationSolid(rightAniName,false)
		CS.ShowObject(self.mRightSpPos,true)
	end)

	self:CreateWndSpine(self.mResultSpPos,"Mengjingzhilv_jieguo",self._resultKey)
end

function UIHopeEventGuessResult:ShowResult()
	local resultSp = self:FindWndSpineByKey(self._resultKey)
	if resultSp then
		CS.ShowObject(self.mResultSpPos,true)
		local spName = self._resultShow[self._result]
		resultSp:PlayAnimation(0,spName,false)
		self._closeWnd = true
	end
end

function UIHopeEventGuessResult:InitData()
	self._leftInfo = self:GetWndArg("leftInfo")
	self._rightInfo = self:GetWndArg("rightInfo")
	self._result = self:GetWndArg("result")
	self._func = self:GetWndArg("func")
	self._rewardFunc = self:GetWndArg("rewardFunc")
	self._closeWnd = false

	self._spineShow = {
		[ModelDreamTrip.CQ_JIANDAO] = {
			leftAniName = "jiandao2",
			rightAniName = "jiandao",
			spineName = "Mengjingzhilv_jiandao",
		},
		[ModelDreamTrip.CQ_SHITOU] = {
			leftAniName = "shitou2",
			rightAniName = "shitou",
			spineName = "Mengjingzhilv_shitou",
		},
		[ModelDreamTrip.CQ_BU] = {
			leftAniName = "bu2",
			rightAniName = "bu",
			spineName = "Mengjingzhilv_bu",
		},
	}

	self._resultShow = {
		[-1] = "bai",
		[0] = "ping",
		[1] = "sheng",
	}

	self._leftKey = "left"
	self._rightKey = "right"
	self._resultKey = "result"
end

function UIHopeEventGuessResult:InitEvent()
	self:SetWndClick(self.mMask,function()
		if not self._closeWnd then return end
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBg,function()
		if not self._closeWnd then return end
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
end
------------------------------------------------------------------
return UIHopeEventGuessResult


