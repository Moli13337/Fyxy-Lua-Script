---
--- Created by Administrator.
--- DateTime: 2023/10/25 10:55:07
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISecretAwardPop:LWnd
local UISecretAwardPop = LxWndClass("UISecretAwardPop", LWnd)

UISecretAwardPop.STATE_COMMON = 0
UISecretAwardPop.STATE_CAN_GET= 1
UISecretAwardPop.STATE_RECEIVE = 2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISecretAwardPop:UISecretAwardPop()
	---@type table<number,CommonIcon>
	self._uicommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISecretAwardPop:OnWndClose()
	if self._uicommonList then
		local iconList = self._uicommonList
		for k,v in pairs(iconList) do
			v:Destroy()
			iconList[k] = nil
		end
		self._uicommonList = nil
	end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISecretAwardPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISecretAwardPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitPara()
	self:InitEvent()
	self:InitMsg()

	gModelActivity:ReqActivityConfigData(self._sid)
end

function UISecretAwardPop:OnDrawCommonItem(item,itemdata,itempos)
	local uicommonlist = self._uicommonList
	local instanceID = item:GetInstanceID()
	local baseClass = uicommonlist[instanceID]

	local itype = itemdata.itemType
	local refId = itemdata.itemId
	local num = itemdata.itemNum

	local uiCommonTrans = CS.FindTrans(item,"CommonUI")

	if not baseClass then
		baseClass = CommonIcon:New()
		uicommonlist[instanceID] = baseClass
		baseClass:Create(CS.FindTrans(uiCommonTrans,"Icon"))
	end

	baseClass:SetCommonReward(itype, refId, num)
	baseClass:EnableShowNum(true)
	baseClass:DoApply()

	local effectName = self._getEffect
	if effectName and self._getState == 1 then
		local effTrans = self:FindWndTrans(uiCommonTrans,"Eff")
		self:CreateWndEffect(effTrans,effectName,effectName..instanceID,100)
	else
		self:DestroyWndEffectByKey(effectName..instanceID)
	end

	local getImg = self:FindWndTrans(uiCommonTrans, "GetImg")
	CS.ShowObject(getImg, self._getState == 2)
end

function UISecretAwardPop:RefreshRewardGetState()
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then return end
	local moreInfo 	= JSON.decode(activityData.moreInfo)

	local receive = moreInfo.receive
	local click   = moreInfo.click

	if receive == true then
		self._getState = self.STATE_RECEIVE
	elseif click == true then
		self._getState = self.STATE_CAN_GET
	else
		self._getState = self.STATE_COMMON
	end
end


function UISecretAwardPop:OnActivityListResp(pb)
	local activities = pb.activities
	for i, v in ipairs(activities) do
		local sid = v.sid
		if self._sid == sid then
			self:RefreshRewardGetState()
			self:RefreshRewardList()
			break
		end
	end
end

function UISecretAwardPop:OnClickGoBtn()
	local link = self._link
	if string.isempty(link) then return end

	CS.UApplication.OpenURL(link)
	gModelActivity:OnActivitySpecialOpReq(self._sid,0,nil,ModelActivity.PLAY_INFORMATION, "1")
end

function UISecretAwardPop:InitPara()
	self._sid = self:GetWndArg("sid")

	self._getState = 0

	self:SetWndButtonText(self.mGoBtn, ccClientText(29900))
end

function UISecretAwardPop:InitEvent()
	self:SetWndClick(self.mBgImage,function ()
		self:WndClose()
	end)
	self:SetWndClick(self.mCloseBtn,function ()
		self:WndClose()
	end)
	self:SetWndClick(self.mGoBtn, function()
		self:OnClickGoBtn()
	end)
end

function UISecretAwardPop:RefreshUI()
	local activityCfgData = gModelActivity:GetWebActivityDataById(self._sid)
	local activityCfg = activityCfgData.config

	local path = activityCfg.artImage
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mTitleImg, path, function()
			CS.ShowObject(self.mTitleImg, true)
		end , true)
	end

	path = activityCfg.platformImage
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mTagImg, path, function()
			CS.ShowObject(self.mTagImg, true)
		end ,true)
	end

	local str = activityCfg.text
	if not string.isempty(str) then
		self:SetWndText(self.mDesc, str)
	end

	self._getEffect = activityCfg.effect
	self._rewardList = LxDataHelper.ParseItem(activityCfg.reward)
	self._link = activityCfg.link

	self:RefreshRewardGetState()
	self:RefreshRewardList()
end

function UISecretAwardPop:UIlLstOnDraw(list, item, itemdata, itempos)
	local refId = tonumber(itemdata.itemId)
	local num = itemdata.itemNum
	self:OnDrawCommonItem(item, itemdata, itempos)

	self:SetWndClick(item,function()
		if  self._getState == 1 then
			gModelActivity:OnActivitySpecialOpReq(self._sid,0,nil,ModelActivity.PLAY_INFORMATION, "2")
		else
			gModelGeneral:ShowCommonItemTipWnd(itemdata)
		end
	end)
end

function UISecretAwardPop:InitMsg()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function(data,sid)
		if sid ~= self._sid then
			return
		end
		self:RefreshUI()
	end)

	self:WndNetMsgRecv(LProtoIds.ActivitySpecialOpResp,function (pb) self:OnActivitySpecialOpResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function (pb) self:OnActivityListResp(pb) end)
end

function UISecretAwardPop:OnActivitySpecialOpResp(pb)
	if pb.sid ~= self._sid then return end
	local opType = pb.opType
	if opType ~= ModelActivity.PLAY_INFORMATION then return end

	--self._getState = self.STATE_RECEIVE
end

function UISecretAwardPop:RefreshRewardList()
	local rewardList = self._rewardList
	local uiList = self._uiItemList
	if uiList then
		uiList:RefreshList(rewardList)
	else
		uiList = self:GetUIScroll("_uiItemList")
		self._uiItemList = uiList
		uiList:Create(self.mItemList,rewardList,function(...) self:UIlLstOnDraw(...) end)
		uiList:EnableScroll(true, true)
	end
end

------------------------------------------------------------------
return UISecretAwardPop


