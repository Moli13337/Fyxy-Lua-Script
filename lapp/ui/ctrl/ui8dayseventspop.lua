---
--- Created by BY.
--- DateTime: 2023/10/15 18:16:19
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UI8DaysEventsPop:LWnd
local UI8DaysEventsPop = LxWndClass("UI8DaysEventsPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UI8DaysEventsPop:UI8DaysEventsPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UI8DaysEventsPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UI8DaysEventsPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UI8DaysEventsPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UI8DaysEventsPop:OnClickClose()
	if self._toggleValue then
		gModelGeneral:SetAlertId(self._sid)
	end
	self:WndClose()
end
function UI8DaysEventsPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:OnClickClose() end)

end

function UI8DaysEventsPop:OnTryTcpReconnect()
	self:WndClose()
end
function UI8DaysEventsPop:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
	self:SetWndToggleDelegate(self.mToggle,function (value)
		self._toggleValue = value
	end)
end
function UI8DaysEventsPop:InitCommand()
	self:SetWndText(self.mToggleText,ccClientText(10155))
	self:SetWndText(self.mCloseTip,ccClientText(10103))

	local sid = self:GetWndArg("sid")
	local type = self:GetWndArg("type")
	self._sid = sid
	self._type = type

	local bool = gModelGeneral:FindAlertId(sid)
	self:SetWndToggleValue(self.mToggle,bool)
	gModelActivity:ReqActivityConfigData(sid)
end
function UI8DaysEventsPop:OnActivityConfigData()
	local _sid = self._sid
	local _type = self._type or 1
	local activityData = gModelActivity:GetWebActivityDataById(_sid)
	if not activityData then return end
	local data = activityData.config
	local previewHero,previewDescIcon,previewDescIconPos
	= data["previewHero".._type],
	data["previewDescIcon".._type],
	data["previewDescIconPos".._type]

	if not string.isempty(previewHero) then
		local imgArr = string.split(previewHero,"=")
		local posParent
		if imgArr[1] == "2" then
			posParent = self.mHeroImg
			self:SetWndEasyImage(posParent,imgArr[2],nil,true)
			if imgArr[4] then
				local scale = tonumber(imgArr[3])
				posParent.localScale = Vector2.New(scale,scale)
			end
		else
			posParent = self.mHeroSpine
			local heroEffectRef = gModelHero:GetShowEffectById(tonumber(imgArr[2]))
			local prefabName = heroEffectRef.heroDrawing
			self:CreateWndSpine(posParent,prefabName,"UI8DaysEventsPop_prefabName",false,function(dpSpine)
				dpSpine:SetIgnoreTimeScale(true)
				dpSpine:SetScale(tonumber(imgArr[4]))
			end)
		end
		CS.ShowObject(posParent,true)
		if not string.isempty(imgArr[3]) then
			local pos = LxDataHelper.ParseVector2NotEmpty2(imgArr[3])
			self:SetAnchorPos(posParent, pos)
		end
	end
	if not string.isempty(previewDescIcon) then
		local posParent = self.mTxtImg
		self:SetWndEasyImage(posParent,previewDescIcon,nil,true)
		CS.ShowObject(posParent,true)
		if not string.isempty(previewDescIconPos) then
			local pos = LxDataHelper.ParseVector2NotEmpty2(previewDescIconPos)
			self:SetAnchorPos(posParent, pos)
		end
	end

	self:CreateWndEffect(self.mEff1,"ui_fx_batianhuodong","mEff1_UI8DaysEventsPop_",125)
	self:CreateWndEffect(self.mEff2,"ui_fx_batianhuodong_02","mEff2_UI8DaysEventsPop_",100)
	self:CreateWndEffect(self.mEff3,"ui_fx_batianhuodong_02","mEff3_UI8DaysEventsPop_",100)
end
------------------------------------------------------------------
return UI8DaysEventsPop


