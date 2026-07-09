---
--- Created by Administrator.
--- DateTime: 2023/10/1 16:34:47
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIWishSecretPop:LWnd
local UIWishSecretPop = LxWndClass("UIWishSecretPop", LWnd)
local typeofRectTransform = typeof(CS.RectTransform)
local unityScreen = UnityEngine.Screen
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIWishSecretPop:UIWishSecretPop()
	self._isLayoutChangeBySet = false;
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIWishSecretPop:OnWndClose()
	gLSdkImpl:WebViewDestroy()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIWishSecretPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIWishSecretPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:ShowContent()
end


function UIWishSecretPop:CalculateMargin()
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

function UIWishSecretPop:ShowContent()
	local url = self._link
	if not url then return end

	if LOG_INFO_ENABLED then
		printInfoN("notice url "..url)
	end

	gLSdkImpl:WebViewDestroy()
	local left,top,right,bottom = self._margin.left,self._margin.top,self._margin.right,self._margin.bottom

	--韩国sdk引导配置
	local extraParam = {
		flag = "chaseol.com",
		ignore = "www.chaseol.com/event/activityPop/index.html",
	}

	gLSdkImpl:WebViewShow(url, left, top, right, bottom, extraParam)
end

function UIWishSecretPop:InitEvent()
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mMask,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIWishSecretPop:InitData()
	self._link  = self:GetWndArg("link")
	self._margin = self:CalculateMargin()
end


------------------------------------------------------------------
return UIWishSecretPop


