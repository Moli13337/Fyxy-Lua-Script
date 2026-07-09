---
--- Created by Administrator.
--- DateTime: 2026/3/4 16:57:21
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIAddDesktop:LWnd
local UIAddDesktop = LxClass("UIAddDesktop", LWnd)
------------------------------------------------------------------

local accountBindId = 8

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIAddDesktop:UIAddDesktop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIAddDesktop:OnWndClose()
	FireEvent(EventNames.ON_ACTIVITY_LIST_CHANGE)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIAddDesktop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIAddDesktop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitTexts()

	---@type boolean 是否可领取奖励
	self._getReward = false
	
	---@type boolean 是否自动领奖励
	self._autoGetReward = false
	--if CS.IsWebGL() and LWxHelper.IsInIos() then
	--	self._autoGetReward = true
	--end
	
	gModelActivity:SetClickModel10005()
	
	self:InitEvents()
	self:InitMsgs()
	self:RefreshView()
end

function UIAddDesktop:InitTexts()
	self:SetWndText(self.mDescTxt,ccClientText(47900))
	self:SetWndText(self.mTitleTxt,ccClientText(47901))
end

function UIAddDesktop:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end, LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBntAddDesktop,function() self:OnClickBtnAddDesktop() end)
end

function UIAddDesktop:OnClickBtnAddDesktop()
	if self._getReward then
		gModelPlayer:OnAuthOnetimeStateReq(accountBindId)
	else
		gLSdkImpl:CallMethod(LSdkMethod.AddShortCut)
	end
end

function UIAddDesktop:InitMsgs()
	self:WndEventRecv(EventNames.ON_ADD_SHORTCUT_RESULT,function(...) self:OnAddShortcutResult(...) end)
	self:WndNetMsgRecv(LProtoIds.AuthOnetimeStateResp, function() self:WndClose() end)
end

function UIAddDesktop:OnAddShortcutResult(bStatus)
	--- 添加失败
	if not bStatus then return end

	if gModelPlayer:InAccoutBindingReward(accountBindId) then
		--- 已领取过奖励的关闭界面即可
		self:WndClose()
		FireEvent(EventNames.ON_ACTIVITY_LIST_CHANGE)
	else
		if self._autoGetReward then
			gModelPlayer:OnAuthOnetimeStateReq(accountBindId)
		else
			self:RefreshBntAddDesktop()
		end
	end
end

function UIAddDesktop:RefreshView()
	self:RefreshBntAddDesktop()
	
	---@type V_InnerActivityNameAndInnerndRef
	local cfg = gModelActivity:GetVerifyConfig(accountBindId)
	if not cfg then return end
	local list = LxDataHelper.ParseItem(cfg.reward)
	self:InitRewardList(list)
end


function UIAddDesktop:RefreshBntAddDesktop()
	self._getReward = false
	local existShortCut = gLSdkImpl:CallMethod(LSdkMethod.CheckIsExistShortCut)
	local btnStr = ccClientText(47902)
	if existShortCut and not self._autoGetReward and not gModelPlayer:InAccoutBindingReward(accountBindId) then
		self._getReward = true
		btnStr = ccClientText(47903)
	end
	self:SetWndButtonText(self.mBntAddDesktop,btnStr)
end



function UIAddDesktop:InitRewardList(rewardList)
	rewardList = rewardList or {}
	
	local bGet = gModelPlayer:InAccoutBindingReward(accountBindId)
	local list = {}
	for i,v in ipairs(rewardList) do
		table.insert(list,{
			itemType = v.itemType,
			itemId = v.itemId,
			itemNum = v.itemNum,
			isShowEff = v.isShowEff,
			bGet = bGet,
		})
	end
	local uiRewardList = self._uiRewardList
	if uiRewardList then
		uiRewardList:RefreshList(list)
	else
		uiRewardList = self:GetUIScroll("uiRewardList")
		self._uiRewardList = uiRewardList
		uiRewardList:Create(self.mRewardList, list, function(...) self:OnDrawRewardCell(...) end)
	end
end

function UIAddDesktop:OnDrawRewardCell(list, item, itemdata, itempos)
	local instanceId = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceId)
	if not itemCache then
	    itemCache = {
			Icon = self:FindWndTrans(item,"CommonUI/Icon")
		}
	    self:SetComponentCache(instanceId,itemCache)
	end
	local IconTrans = itemCache.Icon
	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(IconTrans)
	baseClass:SetCommonReward(itemdata.itemType,itemdata.itemId,itemdata.itemNum)
	baseClass:ShowGouImg(itemdata.bGet)
	baseClass:DoApply()
	
	self:SetWndClick(IconTrans,function()
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)
end

------------------------------------------------------------------
return UIAddDesktop