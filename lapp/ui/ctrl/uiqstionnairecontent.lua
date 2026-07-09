---
--- Created by Administrator.
--- DateTime: 2023/10/20 15:17:27
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIQstionnaireContent:LWnd
local UIQstionnaireContent = LxWndClass("UIQstionnaireContent", LWnd)
local typeofRectTransform = typeof(CS.RectTransform)
local unityScreen = UnityEngine.Screen
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIQstionnaireContent:UIQstionnaireContent()
	self._isLayoutChangeBySet = false;
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIQstionnaireContent:OnWndClose()
	gLSdkImpl:WebViewDestroy()

	if gLGameLanguage:IsHmtRegion() or gLGameLanguage:IsJapanRegion() then --港澳台问卷关闭后直接获得奖励
		FireEvent(EventNames.SDKAIHELP_QUESTIONNAIRE, 0, 0)
	end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIQstionnaireContent:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIQstionnaireContent:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:ShowContent()

	self:SetWndText(self.mTitleText,self._titleStr)
end

function UIQstionnaireContent:CalculateMargin()
	local points={}
	for k=1,2 do
		local name = "point_"..k
		local point = self:FindWndTrans(self.mView,name)
		point = point:GetComponent(typeofRectTransform)
		table.insert(points,point)
	end

	local poses = {}
	local camera = gLGameUI:GetCSUICamera()
	for k= 1, 2 do
		local point = points[k]
		local screenPos =camera:WorldToScreenPoint(point.position)
		print(string.format("margin%s x %s,y %s",k, screenPos.x,screenPos.y))
		table.insert(poses,screenPos)
	end

	local uWidth = unityScreen.width
	local uHeight = unityScreen.height

	local left = poses[1].x
	local bottom = poses[1].y
	local top = uHeight - poses[2].y
	local right = uWidth - poses[2].x

	if CS.IsOSAndroid() then
		local realRect = LNativeHelper.GetDeviceDisplayRect()
		if not string.isempty(realRect) then
			local arrResult = string.split(realRect,"|") or {}
			local rectW = tonumber(arrResult[1]) or 0
			local rectH = tonumber(arrResult[2]) or 0
			print(string.format("unity screen rect=%s|%s , device now rect %s|%s", uWidth, uHeight, rectW,rectH))
			if rectW > 0 and rectH > 0 then
				if rectW ~= uWidth then
					local sx = rectW / uWidth
					left = left * sx
					right = right * sx
				end

				if rectH ~= uHeight then
					local sy = rectH / uHeight
					top = top * sy
					bottom = bottom * sy
				end
			end
		end
	end

	local data ={
		left = math.floor(left),
		top = math.floor(top),
		right = math.floor(right),
		bottom = math.floor(bottom),
	}

	--print(string.format("left %s,right %s,top %s,bottom %s",left,right,top,bottom))
	return data
end

function UIQstionnaireContent:ShowContent()
	local url = self._link
	if not url then return end
	printInfoN("notice url "..url)
	gLSdkImpl:WebViewDestroy()
	local left,top,right,bottom = self._margin.left,self._margin.top,self._margin.right,self._margin.bottom
	gLSdkImpl:WebViewShow(url, left, top, right, bottom)
end

function UIQstionnaireContent:InitData()
	self._link  = self:GetWndArg("link")
	self._sid   = self:GetWndArg("sid")
	self._titleStr = self:GetWndArg("titleStr") or ccClientText(19300)
	self._margin = self:CalculateMargin()
end

function UIQstionnaireContent:OnActivityResp(pb,ret)
	local activity = pb.activity
	if(activity.sid == self._sid and activity.status == 3)then
		self:WndClose()
	end
end

function UIQstionnaireContent:InitEvent()
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function(pb) self:OnActivityResp(pb) end)

	self:SetWndClick(self.mBtnClose,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	--self:SetWndClick(self.mMask,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end



------------------------------------------------------------------
return UIQstionnaireContent


