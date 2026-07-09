---
--- Created by BY.
--- DateTime: 2023/10/4 20:58:46
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBlesPop:LWnd
local UIBlesPop = LxWndClass("UIBlesPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBlesPop:UIBlesPop()
	self._commonIconList = {}
	self._btnSelIndex = 1		--当前选中
	self._btn1Index = 1			--列表1枚举
	self._btn1Texts = {}		--列表1数据
	self._btn2Index = 1			--2...
	self._btn2Texts = {}		--2...
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBlesPop:OnWndClose()
	self:ClearCommonIconList(self._commonIconList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBlesPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBlesPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIBlesPop:AwardListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local icon = self:FindWndTrans(root,"Icon")
	local mask = self:FindWndTrans(item,"Mask")

	local isGet = self._blessReward == 1
	local InstanceID = item:GetInstanceID()
	self:InitCommonIcon(InstanceID,icon,itemdata)
	CS.ShowObject(mask,isGet)
end

function UIBlesPop:InitCommonIcon(key,item,itemdata)
	local baseClass = self._commonIconList[key]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._commonIconList[key] = baseClass
		baseClass:Create(item)
		self:SetIconClickScale(item, true)
	end
	baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
	baseClass:DoApply()
	self:SetWndClick(item,function () 	gModelGeneral:OpenItemInfoTipsFormChat(itemdata) end)
end

function UIBlesPop:OnClickBtn(index)
	self._btnSelIndex = index
	self:RefreshData()
end

function UIBlesPop:ListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local text = self:FindWndTrans(root,"UIText")
	local selImg = self:FindWndTrans(root,"SelImg")

	local _btnSelIndex = self._btnSelIndex
	if _btnSelIndex == 1 then
		_btnSelIndex = self._btn1Index
	else
		_btnSelIndex = self._btn2Index
	end
	self:SetWndText(text,itemdata)
	CS.ShowObject(selImg,itempos == _btnSelIndex)
	self:SetWndClick(item,function ()
		self:OnClickTextItem(itemdata,itempos)
	end)
end

function UIBlesPop:OnTryTcpReconnect()
	self:WndClose()
end

function UIBlesPop:InitCommand()
	self:SetWndText(self.mAwardTitleText,ccClientText(24703))
	self:SetWndButtonText(self.mBtnSend,ccClientText(24715))
	local _sid = self:GetWndArg("sid")
	local _page = self:GetWndArg("page") --支持跳转
	local _subPage = self:GetWndArg("subPage")
	if _subPage then
		_sid = gModelActivity:GetSidByUniqueJump(_subPage)
	end
	self._sid = _sid
	gModelActivity:ReqActivityConfigData(_sid)
end

function UIBlesPop:OnActivityConfigData()
	local activityData = gModelActivity:GetWebActivityDataById(self._sid)
	local data = activityData.config

	local blessTitle,blessHead,blessObject,blessWord,sendReward = data.blessTitle,data.blessHead,data.blessObject,data.blessWord,data.sendReward
	self:SetWndText(self.mDesText,blessHead)
	self._blessHead = blessHead

	if LxUiHelper.IsImgPathValid(blessTitle) then
		self:SetWndEasyImage(self.mTitleImg,blessTitle)
	end
	if not string.isempty(blessObject) then
		self._btn1Texts = string.split(blessObject,"|")
	end
	if not string.isempty(blessWord) then
		self._btn2Texts = string.split(blessWord,"|")
	end
	if not string.isempty(sendReward) then
		self._awardList = LxDataHelper.ParseItem(sendReward)
	end

	self:RefreshData()
end

function UIBlesPop:InitEvent()
	self:SetWndClick(self.mBgImage,function () self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end)
	self:SetWndClick(self.mBtn1,function () self:OnClickBtn(1) end)
	self:SetWndClick(self.mBtn2,function () self:OnClickBtn(2) end)
	self:SetWndClick(self.mBtnSend,function () self:OnClickSend() end)
end

function UIBlesPop:OnClickSend()
	local _btn1Index = self._btn1Index
	local _btn2Index = self._btn2Index
	local args = self._blessHead..self._btn1Texts[_btn1Index]..self._btn2Texts[_btn2Index]
	gModelActivity:OnActivitySpecialOpReq(self._sid,0,0,0, args, ModelActivity.SPRING_FESTIVAL_SEND_BLESS)
end

function UIBlesPop:OnClickTextItem(data,pos)
	local _btnSelIndex = self._btnSelIndex
	if _btnSelIndex == 1 then
		self._btn1Index = pos
	else
		self._btn2Index = pos
	end
	self:RefreshData()
end

function UIBlesPop:RefreshData()
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then return end
	local moreInfo = activityData.moreInfo
	local activityMoreInfo = JSON.decode(moreInfo)
	self._blessReward = activityMoreInfo.blessReward

	local _btnSelIndex = self._btnSelIndex
	local list = {}
	if _btnSelIndex == 1 then
		list = self._btn1Texts or {}
	else
		list = self._btn2Texts or {}
	end
	CS.ShowObject(self.mBtn1Sel, _btnSelIndex == 1)
	CS.ShowObject(self.mBtn2Sel, _btnSelIndex == 2)
	self:SetWndText(self.mBtn1Text,self._btn1Texts[self._btn1Index])
	self:SetWndText(self.mBtn2Text,self._btn2Texts[self._btn2Index])

	local _uiCellList = self._uiCellList
	if _uiCellList then
		_uiCellList:RefreshList(list)
	else
		_uiCellList = self:GetUIScroll("UIBlesPop_uiCellList")
		_uiCellList:Create(self.mCellSuper,list,function (...) self:ListItem(...) end,UIItemList.SUPER_GRID)
		_uiCellList:EnableScroll(true,false)
		self._uiCellList = _uiCellList
	end
	_uiCellList:DrawAllItems()

	local list = self._awardList or {}
	local _uiAwardList = self._uiAwardList
	if _uiAwardList then
		_uiAwardList:RefreshList(list)
	else
		_uiAwardList = self:GetUIScroll("UIBlesPop_uiAwardList")
		_uiAwardList:Create(self.mAwardScroll,list,function (...) self:AwardListItem(...) end)
		self._uiAwardList = _uiAwardList
		--_uiAwardList:EnableScroll(false,false)
	end
end

function UIBlesPop:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end self:OnActivityConfigData()
	end)
	self:WndNetMsgRecv(LProtoIds.ActivitySpecialOpResp,function (pb)
		GF.ShowMessage(ccClientText(24704))
		self:WndClose()
	end)
end
------------------------------------------------------------------
return UIBlesPop


