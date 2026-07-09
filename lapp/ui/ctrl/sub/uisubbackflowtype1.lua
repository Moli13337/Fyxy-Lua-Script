---
--- Created by BY.
--- DateTime: 2023/10/11 20:49:53
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubBackflowType1:LChildWnd
local UISubBackflowType1 = LxWndClass("UISubBackflowType1", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubBackflowType1:UISubBackflowType1()
	self._timeKey = "_timeKey_1"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubBackflowType1:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubBackflowType1:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubBackflowType1:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UISubBackflowType1:InitMessage()
	self:WndNetMsgRecv(LProtoIds.RegressionLoginAwardResp,function (pb)
		self:RefreshData()
	end)
	self:WndEventRecv(EventNames.ON_TIME_ZERO,function()
		gModelBackflow:RegressionLoginAwardReq(0)
	end)
end

function UISubBackflowType1:InitEvent()
	self:SetWndClick(self.mBtnHelp, function(...) self:OnClickHelp() end)
end
------------------------------------------------time--------------------------------------------------------------------
function UISubBackflowType1:OnTimer(key)
	if(self._timeKey == key)then
		self:SetTime()
	end
end
function UISubBackflowType1:InitCommand()
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

	gModelBackflow:RegressionLoginAwardReq(0)
end

function UISubBackflowType1:OnClickHelp()
	GF.OpenWnd("UIBzTips",{refId = self._ref.helpId})
end

function UISubBackflowType1:ListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local numText = self:FindWndTrans(root,"NumText")
	local titleText = self:FindWndTrans(root,"TitleBg/TitleText")
	local awardRoot = self:FindWndTrans(root,"AwardRoot")
	local btnGet = self:FindWndTrans(root,"BtnGet")
	local status_Off = self:FindWndTrans(root,"Status_Off")
	local status_On = self:FindWndTrans(root,"Status_On")

	local InstanceID = item:GetInstanceID()
	local state = itemdata.state
	local day = itemdata.day
	local fixedRefId = itemdata.fixedRefId
	local onHookRefId = itemdata.onHookRefId
	local schedule = state == 0 and 0 or 1

	self:SetWndText(numText,string.replace(ccClientText(23513),schedule,1))
	self:SetWndText(titleText,string.replace(ccClientText(23510),day))
	self:SetWndButtonText(btnGet,ccClientText(23501))
	self:InitTextLineWithLanguage(titleText,-50)
	self:InitTextSizeWithLanguage(titleText, -2)

	local itemList = {}
	if fixedRefId > 0 then
		local ref = gModelBackflow:RegressionFixedRewardRefByRefId(fixedRefId)
		local awards = LxDataHelper.ParseItem(ref.reward)
		for i, v in ipairs(awards) do
			table.insert(itemList,v)
		end
	end
	local _rewardAddition = gModelBackflow:GetRewardAddition()
	if onHookRefId > 0 then
		local ref = gModelBackflow:RegressionOnhookRewardRefByRefId(onHookRefId)
		local awards = LxDataHelper.ParseItem(ref.reward)
		for i, v in ipairs(awards) do
			v.itemNum = math.floor(v.itemNum * _rewardAddition)
			table.insert(itemList,v)
		end
	end
	self:InitItemList(InstanceID,awardRoot,itemList)

	CS.ShowObject(btnGet,state == 1)
	CS.ShowObject(status_Off,state == 0)
	CS.ShowObject(status_On,state == 2)
	self:SetWndClick(btnGet,function ()
		gModelBackflow:RegressionLoginAwardReq(day)
	end)
end

function UISubBackflowType1:InitItemList(InstanceID,awardRoot,itemList)
	local uiIconEasyList = self._uiCellSuper:GetItemCls(InstanceID)
	if(not uiIconEasyList)then
		uiIconEasyList = UIIconEasyList:New()
		self._uiCellSuper:SetItemCls(InstanceID, uiIconEasyList)
		uiIconEasyList:Create(self, awardRoot)
		--uiIconEasyList:SetIconParentPath("itemRoot")
		uiIconEasyList:EnableScroll(true,true)
	end
	uiIconEasyList:RefreshList(itemList)
end

function UISubBackflowType1:RefreshData()
	local list = gModelBackflow:GetAwardInfos()
	table.sort(list,function (a,b)
		local aS = a.state == 1 and -1 or a.state
		local bS = b.state == 1 and -1 or b.state
		if aS ~= bS then
			return aS < bS
		end
		return a.day < b.day
	end)
	local _cellSuper = self._uiCellSuper
	if _cellSuper then
		_cellSuper:RefreshList(list)
	else
		_cellSuper = self:GetUIScroll("mCellSuper1")
		_cellSuper:Create(self.mCellSuper,list,function (...) self:ListItem(...) end,UIItemList.SUPER)
		_cellSuper:EnableScroll(true,false)
		self._uiCellSuper = _cellSuper
	end
	_cellSuper:DrawAllItems()
end
function UISubBackflowType1:SetTime()--设置时间
	local time = gModelBackflow:GetResidueTime()
	if(time <= 0)then
		self:TimerStop(self._timeKey)
		CS.ShowObject(self.mTimeText,false)
		return
	end
	local timeStr = LUtil.FormatTimespanCn(time)
	self:SetWndText(self.mTimeText,string.replace(ccClientText(23500),timeStr))
end
------------------------------------------------------------------
return UISubBackflowType1


