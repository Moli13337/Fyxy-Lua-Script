--- 抽奖返回弹框
--- Created by Ease.
--- DateTime: 2023/10/19 17:19:00
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIOrdinYellAward2:LWnd
local UIOrdinYellAward2 = LxWndClass("UIOrdinYellAward2", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIOrdinYellAward2:UIOrdinYellAward2()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIOrdinYellAward2:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIOrdinYellAward2:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIOrdinYellAward2:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitBtnEvent()
	self:InitMessage()
	self:InitEvent()
	self:InitData()
end

function UIOrdinYellAward2:OnDrawBotBtnCell(list,item,itemdata,itempos)
	local btnTrans = self:FindWndTrans(item,"Btn")
	local light = self:FindWndTrans(btnTrans,"Light")
	local btnPath = itemdata.btnPath
	if btnPath then
		self:SetWndEasyImage(light,itemdata.btnPath)
	end

	self:SetWndButtonText(btnTrans,ccClientText(itemdata.btnTxtIndex))
	self:SetWndClick(btnTrans, function()
		if(not self.isClickBtn)then
			itemdata.btnFunc()
			self.isClickBtn = true
			LxTimer.DelayTimeCall(function()
				self.isClickBtn = false
			end ,0.1,true)
		else
			GF.ShowMessage(ccClientText(10171))
		end
	end)
end
function UIOrdinYellAward2:InitMessage()
end

function UIOrdinYellAward2:SetBtnList()
	if(not self._btnList or #self._btnList<=0)then
		self:SetWndClick(self.mShowBg, function() self:WndClose() end)
		return
	end
	local list = self._btnList
	local listTrans = self.mBtnList
	local listKey = "_botBtnList"
	local uiList =self._uiBotBtnList
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(listKey)
		uiList:Create(listTrans,list,function(...) self:OnDrawBotBtnCell(...) end)
		self._uiBotBtnList = uiList
	end
end

function UIOrdinYellAward2:SetTitle()
	local titleEffectName = self._titleEffectName
	self:CreateWndEffect(self.mTitleRoot,titleEffectName,titleEffectName,100,false,false)
end
function UIOrdinYellAward2:InitBtnEvent()
end

function UIOrdinYellAward2:InitEvent()
end

function UIOrdinYellAward2:OnDrawItemCell(list,item,itemdata,itempos)
	local CommonTrans = self:FindWndTrans(item,"Common")
	local iconTrans = self:FindWndTrans(CommonTrans,"Icon")
	local instanceId = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(iconTrans)
	baseClass:SetRewardDetailItem(itemdata)
	baseClass:DoApply()
	self:DestroyWndEffectByKey(instanceId)
	self:SetWndClick(iconTrans,function()
		gModelGeneral:ShowRewardDetailTip(itemdata)
	end)
end

function UIOrdinYellAward2:SetItemList()
	if(not self._itemList or #self._itemList<=0)then
		return
	end
	local list = self._itemList
	local isMore = #list>5
	CS.ShowObject(self.mMinItemList,not isMore)
	CS.ShowObject(self.mItemList,isMore)
	local listTrans = isMore and self.mItemList or self.mMinItemList
	local listKey = isMore and "_itemList" or "_minItemList"
	local uiList = isMore and self._uiItemList or self._uiMinItemList
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(listKey)
		if(isMore)then
			self._uiItemList = uiList
		else
			self._uiMinItemList = uiList
		end
		uiList:Create(listTrans,list,function(...) self:OnDrawItemCell(...) end)
	end
end

function UIOrdinYellAward2:SetBotDescTips()
	self:SetWndText(self.mBotDescTxt,self._botTipsTxtStr)
end
function UIOrdinYellAward2:InitData()
	self._itemList = self:GetWndArg("itemList")
	self._btnList = self:GetWndArg("btnList")
	self._botTipsTxtStr = self:GetWndArg("botTipsTxtStr")
	self._bgPath = self:GetWndArg("bgPath")
	self._titleEffectName = self:GetWndArg("titleEffectName") or "fx_ui_gongxihuode"
	self._soundEffect = self:GetWndArg("soundEffect") or LSoundConst.TRIGGER_CALL_MIRROR
	self:SetTitle()
	self:SetItemList()
	self:SetBotDescTips()
	self:SetBtnList()
	if(self._bgPath)then
		self:SetWndEasyImage(self.mShowBg,self._bgPath)
	end
	LxUiHelper.PlayAudioSoundName(self._soundEffect)
end
function UIOrdinYellAward2:OnWndRefresh()
	self:InitData()
end
------------------------------------------------------------------
return UIOrdinYellAward2


