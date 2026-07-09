---
--- Created by luofuwen.
--- DateTime: 2023/10/4 16:31:48
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISetguage:LWnd
local UISetguage = LxWndClass("UISetguage", LWnd)
------------------------------------------------------------------


--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISetguage:UISetguage()
	self._lngTag = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISetguage:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISetguage:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISetguage:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	--self:SetAutoLangFont(false)
	
	self:InitView()
	self:InitUIEvent()
end

function UISetguage:ListItem(list , item, itemdata, itempos)
	local nameIcon = self:FindWndTrans(item, "UIImg")
	local refId = itemdata.refId

	local iconPath = itemdata.icon
	if LxUiHelper.IsImgPathValid(iconPath) then
		self:SetWndEasyImage(nameIcon, iconPath, nil, true)
	end

	self:SetWndToggleValue(item, refId == self._lngTag)
	self:SetWndToggleDelegate(item,function (value)
		if value then
			self:SelLang(refId)
		end
	end)
end

function UISetguage:InitView()
	self._lngTag = gLGameLanguage:GetLanguageFlag()
	self._showLanguageList= gLGameLanguage:GetShowLanguageList()
	self:InitLangView()

	self:SetXUITextText(self.mTitleText, ccClientText(15022))
	self:SetWndButtonText(self.mBtnCancel,ccClientText(10101))
	self:SetWndButtonText(self.mBtnOK,ccClientText(10102))
end

function UISetguage:OnClickOK()
	local curFlag = gLGameLanguage:GetLanguageFlag()
	if curFlag == self._lngTag then
		GF.ShowMessage(ccClientText(15023))
		return
	end
	local lngRef = GameTable.MulLanguageShowRef[self._lngTag]
	local paraStr = self._lngTag
	if lngRef then
		paraStr = lngRef.name
	end

	gModelGeneral:OpenUIOrdinTips({refId = 40019,para = {paraStr}, func = function ()
		gModelPlayer:OnSettingLanguageReq(self._lngTag)
		local oldLng = gLGameLanguage:GetLanguageFlag()
		--gLGameLanguage:SetLanguageFlag(self._lngTag)
		PJXCenter.GameMgr:SetGameEnvVar("lngFlag", self._lngTag)
		if CS.IsWebGL() then
			gLGameLanguage:SetLanguageFlag(self._lngTag)
		end
		if gLxTKData then gLxTKData:OnLanguageTAReq(oldLng) end
		-- 多语言不走分包了，去掉强制热更
		--gLGameUpdate:SetForceUpdate(true)
		LPlayerPrefs.SetChat50009pop("true")
		self:WndClose()
		RestartGame()
	end})
end

function UISetguage:InitUIEvent()
	self:SetWndClick(self.mMaskObj,function ()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mBtnClose,function ()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mBtnCancel,function ()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mBtnOK,function ()
		self:OnClickOK()
	end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UISetguage:InitLangView()
	local list	  = self._showLanguageList
	local uiList = self._uiList
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("LangList")
		self._uiList = uiList
		uiList:Create(self.mLangRoot,list,function (...) self:ListItem(...) end)
	end

	if #list > 6 then
		uiList:EnableScroll(true,false)
	end
end

function UISetguage:SelLang(lngTag)
	self._lngTag = lngTag
	self:InitLangView()
end
------------------------------------------------------------------
return UISetguage


