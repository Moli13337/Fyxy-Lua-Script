---
--- Created by y.
--- DateTime: 2025/2/13 17:02:51
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIWGLDebugBtn:LWnd
local UIWGLDebugBtn = LxWndClass("UIWGLDebugBtn", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIWGLDebugBtn:UIWGLDebugBtn()
end
-----------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIWGLDebugBtn:OnWndClose()
	LWnd.OnWndClose(self)
	if self.mBtn and CS.IsValidObject(self.mBtn) then
		local x = self.mBtn.localPosition.x
		local y = self.mBtn.localPosition.y
		local z = self.mBtn.localPosition.z
		local str = x..","..y..","..z
		LPlayerPrefs.SetGameGMPos(str)
	end
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIWGLDebugBtn:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIWGLDebugBtn:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()

	self:SetWndText(self:FindWndTrans(self.mBtn,"XUIText"), "Debug")

	local width,height
	local bWidth,bHeight
	bWidth,bHeight =  self.mBtn.sizeDelta.x/2, self.mBtn.sizeDelta.y/2
	width,height = self.mScope.rect.width/2,self.mScope.rect.height/2
	self._maxX = (width or 270) - bWidth
	self._maxY = (height or 530) - bHeight
	self:InitDrag()
end

function UIWGLDebugBtn:OnWndOpen(wndName)
	if gLGameUI:IsVisibleBattleFont() then return end
	if wndName == "UIFightPrepare" or wndName == "UIFight" then
		CS.ShowObject(self.mBtn, false)
	end
end

function UIWGLDebugBtn:OnWndClose(wndName)
	if gLGameUI:IsVisibleBattleFont() then return end
	if wndName == "UIFightPrepare" or wndName == "UIFight" then
		CS.ShowObject(self.mBtn, true)
	end
end
--
function UIWGLDebugBtn:UIDragOnDrag(dragKey,eventData)
	if self._isForbiddenDrag then
		return
	end
	if dragKey == "debugBtn" then
		local trans = self.mBtn

		local camera = eventData.pressEventCamera
		local pos = camera:ScreenToWorldPoint(eventData.position)
		pos = trans.parent:InverseTransformPoint(pos)

		local localPos = trans.localPosition

		local x = Mathf.Clamp(pos.x,-self._maxX,self._maxX)
		local y = Mathf.Clamp(pos.y,-self._maxY,self._maxY)

		trans.localPosition = Vector3.New(x,y,localPos.z)
	end

end

function UIWGLDebugBtn:InitEvent()
	self:WndEventRecv(EventNames.ON_WND_FINISH,function (...) self:OnWndOpen(...) end)
	self:WndEventRecv(EventNames.ON_WND_CLOSE,function (...) self:OnWndClose(...) end)
	self:WndEventRecv(EventNames.TMP_FONT_UPDATE,function () self:OnTmpFontUpdate() end)

	self:SetWndClick(self.mBtn,function(...) self:OnClickHeadImg() end)
end
function UIWGLDebugBtn:DoDebugBtnShow(isShow)
	if isShow then
		self._isForbiddenDrag = nil
		self._wndCanvasGroup.alpha = 1
	else
		self._isForbiddenDrag = true
		self._wndCanvasGroup.alpha = 0
		local x = Mathf.Clamp(self._maxX,-self._maxX,self._maxX)
		local y = Mathf.Clamp(self._maxY,-self._maxY,self._maxY)
		self.mBtn.localPosition = Vector3.New(x,y,0)
	end
end

function UIWGLDebugBtn:TryChangeGmShowState()
	if self._isForbiddenDrag then
		self:DoDebugBtnShow(true)
	else
		self:DoDebugBtnShow(false)
	end
end

function UIWGLDebugBtn:OnTmpFontUpdate()
	local trans = self:FindWndTrans(self.mBtn,"XUIText")
	local text = self:FindCommonComponent(trans, typeof(CS.YXUIText))
	text:ForceMeshUpdate()
end

function UIWGLDebugBtn:InitDrag()
	self:UIDragSetItem("debugBtn","Scope/btn",CS.YXUIDrag.DragMode.DragNothing)
end

function UIWGLDebugBtn:OnClickHeadImg()
	if GF.FindFirstWndByName("UIWGLDebug") then
		GF.CloseWndByName("UIWGLDebug")
	else
		GF.OpenWndDebug("UIWGLDebug")
	end
end

------------------------------------------------------------------
return UIWGLDebugBtn


