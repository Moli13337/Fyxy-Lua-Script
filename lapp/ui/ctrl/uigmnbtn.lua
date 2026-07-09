---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGMnBtn:LWnd
local UIGMnBtn = LxWndClass("UIGMnBtn", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGMnBtn:UIGMnBtn()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGMnBtn:OnWndClose()
	LWnd.OnWndClose(self)
	if self.mGMBtn and CS.IsValidObject(self.mGMBtn) then
		-- 本地存储
		local x = self.mGMBtn.localPosition.x
		local y = self.mGMBtn.localPosition.y
		local z = self.mGMBtn.localPosition.z
		local str = x..","..y..","..z
		LPlayerPrefs.SetGameGMPos(str)
	end
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGMnBtn:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGMnBtn:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()

	self:SetWndText(self:FindWndTrans(self.mGMBtn,"XUIText"), "GM")

	local width,height
	local bWidth,bHeight
	bWidth,bHeight =  self.mGMBtn.sizeDelta.x/2, self.mGMBtn.sizeDelta.y/2
	width,height = self.mScope.rect.width/2,self.mScope.rect.height/2
	self._maxX = (width or 270) - bWidth
	self._maxY = (height or 530) - bHeight
	self:InitChatFlowPos()
	self:InitDrag()
end

function UIGMnBtn:InitEvent()
	self:WndEventRecv(EventNames.ON_WND_FINISH,function (...) self:OnWndOpen(...) end)
	self:WndEventRecv(EventNames.ON_WND_CLOSE,function (...) self:OnWndClose(...) end)

	self:SetWndClick(self.mGMBtn,function(...) self:OnClickHeadImg() end)
end
--
function UIGMnBtn:UIDragOnDrag(dragKey,eventData)
	if self._isForbiddenDrag then
		return
	end
	if dragKey == "gmBtn" then
		local trans = self.mGMBtn

		local camera = eventData.pressEventCamera
		local pos = camera:ScreenToWorldPoint(eventData.position)
		pos = trans.parent:InverseTransformPoint(pos)

		local localPos = trans.localPosition

		local x = Mathf.Clamp(pos.x,-self._maxX,self._maxX)
		local y = Mathf.Clamp(pos.y,-self._maxY,self._maxY)

		trans.localPosition = Vector3.New(x,y,localPos.z)
	end

end
function UIGMnBtn:DoGMBtnShow(isShow)
	if isShow then
		self._isForbiddenDrag = nil
		self._wndCanvasGroup.alpha = 1
	else
		self._isForbiddenDrag = true
		self._wndCanvasGroup.alpha = 0
		local x = Mathf.Clamp(self._maxX,-self._maxX,self._maxX)
		local y = Mathf.Clamp(self._maxY,-self._maxY,self._maxY)
		self.mGMBtn.localPosition = Vector3.New(x,y,0)
	end
end

function UIGMnBtn:InitChatFlowPos()
	local posStr = LPlayerPrefs.gameGMPos
	if not string.isempty(posStr) then
		local posArr = string.split(posStr,",")
		local x = Mathf.Clamp(tonumber(posArr[1]) or 0,-self._maxX,self._maxX)
		local y = Mathf.Clamp(tonumber(posArr[2]) or 0,-self._maxY,self._maxY)
		self.mGMBtn.localPosition = Vector3.New(x,y,tonumber(posArr[3]) or 0)
	end
end

function UIGMnBtn:TryChangeGmShowState()
	if self._isForbiddenDrag then
		self:DoGMBtnShow(true)
	else
		self:DoGMBtnShow(false)
	end
end

function UIGMnBtn:InitDrag()
	self:UIDragSetItem("gmBtn","Scope/GMBtn",CS.YXUIDrag.DragMode.DragNothing)
end


function UIGMnBtn:OnWndOpen(wndName)
	if gLGameUI:IsVisibleBattleFont() then return end
	if wndName == "UIFightPrepare" or wndName == "UIFight" then
		CS.ShowObject(self.mGMBtn, false)
	end
end

function UIGMnBtn:OnWndClose(wndName)
	if gLGameUI:IsVisibleBattleFont() then return end
	if wndName == "UIFightPrepare" or wndName == "UIFight" then
		CS.ShowObject(self.mGMBtn, true)
	end
end

function UIGMnBtn:OnClickHeadImg()
	if GF.FindFirstWndByName("UIGMand") then
		GF.CloseWndByName("UIGMand")
	else
		GF.OpenWndDebug("UIGMand")
	end
end

------------------------------------------------------------------
return UIGMnBtn


