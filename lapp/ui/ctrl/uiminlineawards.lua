---
--- Created by BY.
--- DateTime: 2023/10/12 15:45:20
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMinLineAwards:LWnd
local UIMinLineAwards = LxWndClass("UIMinLineAwards", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMinLineAwards:UIMinLineAwards()
	self._uiCommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMinLineAwards:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMinLineAwards:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMinLineAwards:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIMinLineAwards:OnClickHelp()
	GF.OpenWnd("UIBzTips",{refId = 80})
end

function UIMinLineAwards:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnHelp, function(...) self:OnClickHelp() end,LSoundConst.CLICK_ERROR_COMMON)
	self:SetWndClick(self.mCloseTip, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mOneClickGetBtn, function(...) self:OnClickOneClickBtn() end,LSoundConst.CLICK_BUTTON_COMMON)
end

function UIMinLineAwards:InitCommand()
	self:SetWndText(self.mCloseTip,ccClientText(17003))
	self:SetWndText(self.mOneClickGetText, ccClientText(16310))
	self._itemList = {
		self.mRewardContent1,
		self.mRewardContent2
	}

	self:RefreshData()
end

function UIMinLineAwards:OnClickOneClickBtn()
	--一键领取
	self:OnClickGet(-1)
end

function UIMinLineAwards:InitMessage()
	self:WndNetMsgRecv(LProtoIds.InstanceRewardResp,function (...)
		self:RefreshData()
		self:SendGuideReadyEvent(self:GetWndName())
	end)
end

function UIMinLineAwards:ListItem( list,item, itemdata, itempos)--cell
	local image = CS.FindTrans(item,"Image")
	local titleText = CS.FindTrans(item,"Image/TitleText")
	local itemScroll = CS.FindTrans(item,"ItemScroll")
	local isImg = CS.FindTrans(item,"isImg")

	local InstanceID = item:GetInstanceID()
	local imgStr = "pass_bg_2"
	self:SetWndEasyImage(isImg,"pass_line_"..itempos)

	local chapterId = gModelInstance:GetChapterId()
	local battleNode = gModelInstance:GetRawBattleNode()
	local isGet = chapterId >= itemdata.chapter and (battleNode > itemdata.refId or battleNode == -1)

	local itemDateRef = itemdata.ref
	local reward1List = LxDataHelper.ParseItem(itemDateRef.reward)
	local uiList1 = self._uiCellList:GetItemCls(InstanceID)
	if not uiList1 then
		uiList1 = UIIconEasyList:New(self)
		self._uiCellList:SetItemCls(InstanceID, uiList1)
		uiList1:Create(self, itemScroll)
		uiList1:SetIconParentPath("Root/CommonUI/Icon")
	end

	CS.ShowObject(isImg,isGet)
	if isGet then
		--uiList1:SetItemClickFunc(function(...) self:OnClickGet(itemdata.refId) end)
		uiList1:SetItemEff("fx_ui_qiandao_lingqutishi",95,InstanceID)
		imgStr = "pass_bg_7"
	else
		uiList1:SetItemClickFunc(nil)
		uiList1:SetItemEff(nil,nil)
	end
	self:SetWndEasyImage(image,imgStr)
	uiList1:RefreshList(reward1List)
	self:SetWndText(titleText,string.replace(ccClientText(16307), itemdata.chapter,itemdata.number))
	self:SetWndClick(isImg,function ()
		self:OnClickGet(itemdata.refId)
	end)
end

function UIMinLineAwards:SetItems(item,itemdata)
	if not item or not itemdata then
		CS.ShowObject(item,false)
		return
	end
	CS.ShowObject(item,true)
	local InstanceID = item:GetInstanceID()
	local iconTrans = CS.FindTrans(item, "CommonUI/Icon")
	local eff = CS.FindTrans(item, "CommonUI/Eff")
	local baseClass = self._uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._uiCommonList[InstanceID] = baseClass
		baseClass:Create(iconTrans)
	end

	baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
	baseClass:DoApply()

	self:SetIconClickScale(iconTrans ,true)
	self:SetWndClick(iconTrans, function()
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)
	self:CreateWndEffect(eff,"fx_daoju_orange",InstanceID,110,false,false)
end

function UIMinLineAwards:OnClickGet(refId)
	gModelInstance:OnInstanceRewardReq(refId)
end

function UIMinLineAwards:RefreshData()
	local list = {}
	local chapterId = gModelInstance:GetChapterId()
	local battleNode = gModelInstance:GetRawBattleNode()
	local alist = gModelInstance:GetBGetAwardChapterId()
	local daAward = nil
	local canGetNum = 0
	local isShowOneClickGet = false
	for i, v in ipairs(alist) do
		if i <= 3 then
			table.insert(list,v)
		end
		if v.specialId and v.specialId == 1 and not daAward then
			daAward = v
		end

		local isGet = chapterId >= v.chapter and (battleNode > v.refId or battleNode == -1)
		if isGet then
			canGetNum = canGetNum + 1
			isShowOneClickGet = canGetNum >= 2
		end

		if i > 3 and daAward and isShowOneClickGet then
			break
		end
	end
	if(#list <= 0)then
		self:WndClose()
		return
	end

	self._chapterId = chapterId
	self._battleNode = battleNode

	if not self._uiCellList then
		self._uiCellList = self:GetUIScroll("cell")
		self._uiCellList:Create(self.mCellScroll,list,function (...) self:ListItem(...) end)
	else
		self._uiCellList:RefreshList(list)
	end

	if daAward then
		local daAwardRef = daAward.ref
		self:SetWndText(self.mTitleText,string.replace(ccClientText(16306),ccLngText(daAwardRef.rewardName)))
		self:SetWndText(self.mNumText,string.replace(ccClientText(16307), daAward.chapter,daAward.number))
		local reward = LxDataHelper.ParseItem(daAwardRef.reward)
		self:SetItems(self._itemList[1],reward[1])
		self:SetItems(self._itemList[2],reward[2])
	end

	CS.ShowObject(self.mOneClickGetBtn, isShowOneClickGet)
end
------------------------------------------------------------------
return UIMinLineAwards


