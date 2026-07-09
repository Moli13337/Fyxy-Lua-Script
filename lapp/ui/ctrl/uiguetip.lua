---
--- Created by Administrator.
--- DateTime: 2023/10/9 20:20:17
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGueTip:LWnd
local UIGueTip = LxWndClass("UIGueTip", LWnd)

local typeUIHollowOut = typeof(CS.UIHollowOut)
local typeOfRectTransform = typeof(UnityEngine.RectTransform)
local YXUIPointUtil = CS.YXUIPointUtil


UIGueTip.NORMAL = 1
UIGueTip.INVASION = 2
UIGueTip.WEAK = 3
UIGueTip.TIME = 4
UIGueTip.FORBID = 5
UIGueTip.ACTIVITY = 6

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGueTip:UIGueTip()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGueTip:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGueTip:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGueTip:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	local canvasRect =LGameUI.GetUICanvasRoot()
	local hollowOut = self.mMask.transform:GetComponent(typeUIHollowOut)
	if hollowOut then
		hollowOut.m_Canvas = canvasRect
	end

	self._effectPaths=
	{
		[1]= "fx_ui_shou",
		[2] = "fx_ui_shou_2",
	}
	self._delayTimer = "_delayTimer"
	self._rectTran = self:GetWndArg("targetTran")

	self:InitUIEvent()
	self:InitMsg()
	self:InitWndPara()
	self:RefreshUI()
end


function UIGueTip:GetOffsetByPivot(rectTran)
	local canvasRect =LGameUI.GetUICanvasRoot()
	local size =rectTran.rect.size*canvasRect.localScale.x
	local pivot = rectTran.pivot
	local offset = Vector3.New((0.5-pivot.x)*size.x , (0.5-pivot.y)*size.y,0)
	return offset
end

function UIGueTip:SetTextPos(targetScreenPos,textType)

	local textBgTran = self.mTextBg
	if textType == 2 then
		textBgTran = self.mTextBg_1
	end


	local rectHeight = self.mIcon.rect.height

	local UScreen = UnityEngine.Screen
	local UHeight = UScreen.height
	local UWidth = UScreen.width
	local curScreenHeight = UHeight * LGameQuality.SCREEN_WIDTH_DESIGN /UWidth
	local curScreenWidth = LGameQuality.SCREEN_WIDTH_DESIGN
	local cfgDis = 20
	local textHeight = textBgTran.rect.height
	local offsetY = cfgDis + textHeight/2 + rectHeight/2
	local textPosY =targetScreenPos.y + offsetY
	if textPosY + textHeight/2 > curScreenHeight/2 then
		textPosY = targetScreenPos.y -offsetY
	end

	local textWidth = textBgTran.rect.width
	local rangeXMax = curScreenWidth/2 - textWidth/2 - 20
	local rangeXMin = -curScreenWidth/2 + textWidth/2 + 20

	local textPosX = Mathf.Clamp(targetScreenPos.x,rangeXMin,rangeXMax)
	textBgTran.localPosition = Vector3.New(textPosX,textPosY - 20,0)
end

function UIGueTip:InitMsg()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
end

function UIGueTip:OnActivityRectTrans()
	local wnd = GF.FindFirstWndByName("UIMCity")
	if not wnd then
		return
	end

	if not self._modelId then
		return
	end

	local tran = wnd:GetActivityTranByModel(self._modelId)
	if not CS.IsValidObject(tran) then
		return
	end

	self._rectTran = tran
end

function UIGueTip:SetUI(data)

	local target,type =data.target,data.type
	if not CS.IsValidObject(target) then
		printInfoN("invalic object target")
		return
	end
	local canvasRect =LGameUI.GetUICanvasRoot()
	local uicamera = gLGameUI:GetCSUICamera()
	local offset = Vector2.New(30,30)
	local screenPos = nil
	if type == 1 then --ui界面
		local rectTran = target:GetComponent(typeOfRectTransform)
		local pivotOffset = self:GetOffsetByPivot(rectTran)
		local pos = target.position + pivotOffset
		screenPos =uicamera:WorldToScreenPoint(pos)

		self.mFinger.sizeDelta = target.rect.size+ offset
	end

	local targetPos = uicamera:ScreenToWorldPoint(screenPos)

	self.mFinger.position = targetPos

	self:ShowEffect(screenPos,targetPos)

	self.mIcon.sizeDelta = self.mFinger.sizeDelta



	local text = self._para and self._para.info
	local textType = 1
	local figurePath = "plot_role_4503"
	if self._wndType == UIGueTip.INVASION then
		self._clickFunc = self._para.clickFunc
	elseif self._wndType == UIGueTip.WEAK then
		self._clickFunc = self._para.clickFunc
		textType = 2
	elseif self._wndType == UIGueTip.ACTIVITY then
		self._clickFunc = LxUiHelper.GetClickDelegate(target,1)
		figurePath = self._sidRole

		if LxUiHelper.IsImgPathValid(figurePath) then
			textType = 2
		else
			textType = 1
		end
		text 	   = self._sidTxt
	else
		self._clickFunc = LxUiHelper.GetClickDelegate(target,1)
	end

	local showText = not string.isempty(text)
	if showText then
		if textType == 1 then
			self:SetWndText(self.mText,text)
		else
			self:SetWndText(self.mText_1,text)
		end
	end

	local icon = self:FindWndTrans(self.mFinger,'icon')
	CS.ShowObject(icon,self._wndType ~= UIGueTip.TIME)

	CS.ShowObject(self.mTextBg,showText and textType == 1)
	CS.ShowObject(self.mTextBg_1,showText and textType == 2)

	if showText and textType == 2 then
		local isImgValid = LxUiHelper.IsImgPathValid(figurePath)
		if isImgValid then
			self:SetWndEasyImage(self.mFigure, figurePath, nil, true)
		end
		CS.ShowObject(self.mFigure, isImgValid)
	end

	self.mFinger.transform.localScale = target.transform.localScale
	self:TimerStop(self._delaySkipTimer)

    local targetScreenPos=YXUIPointUtil.GetScreenPoint(canvasRect,self.mFinger)
    self:SetTextPos(targetScreenPos, textType)
end

function UIGueTip:InitWndPara()
	local wndType = self:GetWndArg("wndType") or UIGueTip.NORMAL
	local rectTran = self:GetWndArg("targetTran")
	local para = self:GetWndArg("para")

	self._wndType = wndType
	self._rectTran = rectTran
	self._para = para

	self._infoStr = self._para and self._para.info

	if wndType == UIGueTip.ACTIVITY then
		self._sid = self:GetWndArg("sid")
		gModelActivity:ReqActivityConfigData(self._sid)
	end
end

function UIGueTip:OnTimer(key)
	if key == self._delayTimer then
		self:SetUI(self._targetPara)
	end
end

function UIGueTip:InitUIEvent()
	self:SetWndClick(self.mMask,function () self:OnClickMask() end)
	self:SetWndClick(self.mFinger,function  () self:OnClickFinger() end)
	CS.SetOnBeginDrag(self.mMask.gameObject,function (...) self:OnClickMask() end)
end

function UIGueTip:RefreshUI()
	if self._wndType == UIGueTip.ACTIVITY and not self._modelId then return end

	self._targetPara =
	{
		target = self._rectTran,
		type = 1
	}

	self:TimerStop(self._delayTimer)
	self:TimerStart(self._delayTimer,0.5,false,1)
end
function UIGueTip:OnClickFinger()
	local clickFunc = self._clickFunc

	if clickFunc then
		clickFunc()
	end
	self:WndClose()
end


function UIGueTip:ShowEffect(screenPos,targetPos)
	local UScreen = UnityEngine.Screen
	local rotateY = Vector3.New(0,0,0)
	if screenPos.y-150<0 then
		rotateY = Vector3.New(180,0,0)
	end

	local rotateX = Vector3.New(0,0,0)
	if screenPos.x+ 150 > UScreen.width then
		rotateX = Vector3.New(0,180,0)
	end

	local rotate = rotateX+ rotateY

	local guideEff = self._effectPaths[2]
	self:DestroyWndEffectByKey(guideEff)
	local effect = self._effectPaths[2]
	self:CreateWndEffect(self.mEffectRoot,effect,effect,100)

	self.mEffectRoot.localRotation = Quaternion.Euler(rotate.x,rotate.y,0)
	self.mEffectRoot.position = targetPos

end

function UIGueTip:OnClickMask()

	if self._wndType == UIGueTip.WEAK then
		if self._clickFunc then
			self._clickFunc()
		end
	elseif self._wndType == UIGueTip.FORBID then
		return
	end

	self:WndClose()
end

function UIGueTip:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end


	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if not webData then
		return
	end

	local actData = gModelActivity:GetActivityBySid(sid)
	if not actData then
		return
	end

	local info = webData.config
	self._modelId = actData.model
	local guideRoleText = info.guideRoleText
	if not string.isempty(guideRoleText) then
		local guideTextData = string.split(guideRoleText, '|')
		self._sidGuideType = tonumber(guideTextData[1])
		self._sidRole = guideTextData[2]
		self._sidTxt = guideTextData[3]
	else
		printInfoNR2("活动弱指引配置缺少")
	end

	self:OnActivityRectTrans()
	gModelActivity:ResetGuideMainActivity(sid)
	self:RefreshUI()
end

------------------------------------------------------------------
return UIGueTip


