---
--- Created by BY.
--- DateTime: 2023/10/12 14:38:05
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubBackflowType2:LChildWnd
local UISubBackflowType2 = LxWndClass("UISubBackflowType2", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubBackflowType2:UISubBackflowType2()
	self._timeKey = "_timeKey_2"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubBackflowType2:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubBackflowType2:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubBackflowType2:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
------------------------------------------------time--------------------------------------------------------------------
function UISubBackflowType2:OnTimer(key)
	if(self._timeKey == key)then
		self:SetTime()
	end
end
function UISubBackflowType2:InitMessage()
	self:WndNetMsgRecv(LProtoIds.RegressionPrivilegeResp,function (pb)
		self:RefreshData()
	end)
end

function UISubBackflowType2:OnClickHelp()
	GF.OpenWnd("UIBzTips",{refId = self._ref.helpId})
end
function UISubBackflowType2:SetTime()--设置时间
	local time = gModelBackflow:GetResidueTime()
	if(time <= 0)then
		self:TimerStop(self._timeKey)
		CS.ShowObject(self.mTimeText,false)
		return
	end
	local timeStr = LUtil.FormatTimespanCn(time)
	self:SetWndText(self.mTimeText,string.replace(ccClientText(23500),timeStr))
end

function UISubBackflowType2:InitEvent()
	self:SetWndClick(self.mBtnHelp, function(...) self:OnClickHelp() end)
end

function UISubBackflowType2:RefreshData()
	local list = gModelBackflow:GetPrivilegesTypeList()
	local _cellSuper = self._uiCellSuper
	if _cellSuper then
		_cellSuper:RefreshList(list)
	else
		_cellSuper = self:GetUIScroll("mCellSuper2")
		_cellSuper:Create(self.mCellSuper,list,function (...) self:ListItem(...) end,UIItemList.SUPER)
		_cellSuper:EnableScroll(true,false)
		self._uiCellSuper = _cellSuper
	end
	_cellSuper:DrawAllItems()
end

function UISubBackflowType2:PrivilegeListItem(list, item, itemdata, itempos)
	local desText = self:FindWndTrans(item,"DesText")
	local sysbuff = itemdata.sysbuff
	local ref = gModelGeneral:GetSysEffectRef(sysbuff)
	self:SetWndText(desText,ccLngText(ref.desc))
	local uiText = LxUiHelper.FindXTextCtrl(desText)
	local height = uiText.preferredHeight
	if height < 24 then
		height = 24
	end
	LxUiHelper.SetSizeWithCurAnchor(item,1,height)
end
function UISubBackflowType2:InitCommand()
	local refId = self:GetWndArg("refId")
	local ref = gModelBackflow:RegressionBackflowRefByRefId(refId)
	self._ref = ref

	CS.ShowObject(self.mBtnHelp,ref.helpId > 0)
	local showIcon,showIconPos,showTitle,showTitlePos = ref.showIcon,ref.showIconPos,ref.showTitle,ref.showTitlePos
	if LxUiHelper.IsImgPathValid(showIcon) then
		CS.ShowObject(self.mIconImg,true)
		self:SetWndEasyImage(self.mIconImg,showIcon,nil,true)
		local showIconPosArr = string.split(showIconPos,"|")
		self.mIconImg.anchoredPosition = Vector2(tonumber(showIconPosArr[1]),tonumber(showIconPosArr[2]))
	end
	if LxUiHelper.IsImgPathValid(showTitle) then
		CS.ShowObject(self.mTextImg,true)
		self:SetWndEasyImage(self.mTextImg,showTitle,nil,true)
		local showTitlePosArr = string.split(showTitlePos,"|")
		self.mTextImg.anchoredPosition = Vector2(tonumber(showTitlePosArr[1]),tonumber(showTitlePosArr[2]))
	end

	local time = gModelBackflow:GetResidueTime()
	CS.ShowObject(self.mTimeText,time > 0)
	if(time > 0)then
		self:SetTime()
		self:TimerStop(self._timeKey)
		self:TimerStart(self._timeKey,1,false,-1)
	end
	local list = gModelBackflow:GetPrivilegesTypeList()
	if #list > 0 then
		self:RefreshData()
	else
		gModelBackflow:RegressionPrivilegeReq()
	end
end

function UISubBackflowType2:ListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local image = self:FindWndTrans(root,"Image")
	local icon = self:FindWndTrans(root,"Icon")
	--local nameText = self:FindWndTrans(root,"NameText")
	local privilegeSuper = self:FindWndTrans(root,"PrivilegeSuper")
	local btnGoTo = self:FindWndTrans(root,"BtnGoTo")
	--local goToText = self:FindWndTrans(root,"BtnGoTo/GoToText")

    local refId = itemdata.type
    local ref = gModelBackflow:RegressionPrivilegesShowRefByType(refId)
	if not ref then
		return
	end

	self:SetWndEasyImage(image,ref.bg)
	self:SetWndEasyImage(icon,ref.icon, nil, true)
	--self:SetWndText(nameText,ccLngText(ref.name))
	--self:SetWndText(goToText,ccClientText(23502))

	local InstanceID = item:GetInstanceID()
	local privilegeList = itemdata.showList
	local 	_cellSuper = self:GetUIScroll(InstanceID)
	if _cellSuper:GetList() then
		_cellSuper:RefreshList(privilegeList)
		_cellSuper:DrawAllItems()
	else
		_cellSuper:Create(privilegeSuper,privilegeList,function (...) self:PrivilegeListItem(...) end,UIItemList.SUPER)
		_cellSuper:EnableScroll(true,false)
	end
	self:SetWndClick(btnGoTo,function ()
		gModelFunctionOpen:Jump(ref.jump)
		GF.CloseWndByName("UIBackin")
	end)
end
------------------------------------------------------------------
return UISubBackflowType2


