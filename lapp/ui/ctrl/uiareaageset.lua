---
--- Created by BY.
--- DateTime: 2023/10/2 14:59:09
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIAreaAgeSet:LWnd
local UIAreaAgeSet = LxWndClass("UIAreaAgeSet", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIAreaAgeSet:UIAreaAgeSet()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIAreaAgeSet:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIAreaAgeSet:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIAreaAgeSet:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIAreaAgeSet:OnClickCut()
	local _isShowS = self._isShowS or false
	self._isShowS = not _isShowS
	CS.ShowObject(self.mAgeSuper,not _isShowS)

	if _isShowS then
		return
	end
	local list = gModelPlayerSpace:GetRoleAgeListRef()

	local uiList = self._ageList
	if uiList then
		uiList:RefreshList(list)
		local _uiListSuper = uiList:GetList()
		_uiListSuper:DrawAllItems()
	else
		local uiList = self:GetUIScroll("ageList")
		uiList:Create(self.mAgeSuper,list,function (...) self:ListItem(...) end,UIItemList.SUPER)
        self._ageList = uiList
	end
end

function UIAreaAgeSet:OnClickAge(refId)
	CS.ShowObject(self.mAgeSuper,false)
	self._ageId = refId
	self:RefreshAge()
	self._isShowS = false
end

function UIAreaAgeSet:RefreshAge()
	local _ageId = not self._ageId and 0 or self._ageId
	-- local ref = gModelPlayerSpace:GetRoleAgeListRefByRefId(tonumber(_ageId))
	local s = _ageId == 0 and ccClientText(21186) or _ageId
	-- self:SetWndText(self.mNumText,ccLngText(ref.name))
	self:SetWndText(self.mAgeText,ccClientText(21129) .. "<color=#f9b164>" .. s .. "</color>")
end

function UIAreaAgeSet:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(21127))
	self:SetWndText(self.mDesText,ccClientText(21128))
	self:SetWndText(self.mAgeText,ccClientText(21129))
	self:SetWndButtonText(self.mBtnYellow2,ccClientText(21130))
	local _ageId = gModelPlayer:GetPlayerAgeRefId()
	self._ageId = _ageId == "" and 1 or _ageId
	self._oldAgeId = self._ageId
	self:RefreshAge()
end

function UIAreaAgeSet:OnClickClose()
	if self._oldAgeId == self._ageId then
		self:WndClose()
		return
	end
	gModelGeneral:OpenUIOrdinTips({refId = 50008,leftFunc = function () self:WndClose() end ,func = function () self:OnClickReq() end})
end

function UIAreaAgeSet:OnClickReq()
	if self._oldAgeId == self._ageId then
		self:WndClose()
		return
	end
	gModelPlayerSpace:OnPlayerChangeInfoReq(2,tostring(self._ageId))
end

function UIAreaAgeSet:InitMessage()
	self:WndNetMsgRecv(LProtoIds.PlayerChangeInfoResp,function (...)
		GF.ShowMessage(ccClientText(21147))
		self:WndClose()
	end)
end

function UIAreaAgeSet:ListItem(list,item, itemdata, itempos)
	local img = CS.FindTrans(item,"SelImg")
	local text = CS.FindTrans(item,"UIText")

	CS.ShowObject(img,tonumber(self._ageId) == itemdata.refId)
	local str = itemdata.refId == 0 and ccClientText(21186) or itemdata.refId
	if tonumber(self._ageId) == itemdata.refId then
		str = LUtil.FormatColorStr(str,"white")
	end
	self:SetWndText(text,str)
	self:SetWndClick(item,function ()
		self:OnClickAge(itemdata.refId)
	end)
end

function UIAreaAgeSet:InitEvent()
	self:SetWndClick(self.mBgImage, function (...) self:OnClickClose() end)
	self:SetWndClick(self.mBtnClose, function (...) self:OnClickClose() end)
	self:SetWndClick(self.mBtnCut, function (...) self:OnClickCut() end)
	self:SetWndClick(self.mBtnYellow2, function (...) self:OnClickReq() end)
end
------------------------------------------------------------------
return UIAreaAgeSet


