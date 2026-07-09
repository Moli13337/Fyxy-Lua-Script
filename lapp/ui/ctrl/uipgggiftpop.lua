---
--- Created by Administrator.
--- DateTime: 2023/10/7 14:48:02
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPggGiftPop:LWnd
local UIPggGiftPop = LxWndClass("UIPggGiftPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPggGiftPop:UIPggGiftPop()
	---@type table<number,CommonIcon>
	self._uicommonList = {}

end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPggGiftPop:OnWndClose()
	if self._uicommonList then
		local list = self._uicommonList
		for k,v in pairs(list) do
			v:Destroy()
			list[k] = nil
		end
		self._uicommonList = nil
	end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPggGiftPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPggGiftPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitData()
	self:RefreshUIView()
	self:InitStaticContent()
end

function UIPggGiftPop:RefreshUIView()
	local activityWedData = gModelActivity:GetWebActivityDataById(self._sid)
	if not activityWedData then
		gModelActivity:ReqActivityConfigData(self._sid)
	else
		self:InitTop()
	end

	self:InitItemScrollView()
end

function UIPggGiftPop:InitTop()
	local activityWedData = gModelActivity:GetWebActivityDataById(self._sid)
	if not activityWedData then return end

	local config = activityWedData.config

	local path = config.pictureOne or GameTable.CityMapConfRef["pictureOne"]
	if LxUiHelper.IsImgPathValid(path) then
		local pos = config.pictureOnePos or GameTable.CityMapConfRef["pictureOnePos"]

		self:SetWndEasyImage(self.mPicture, path,function()
			if not string.isempty(pos) then
				self:SetAnchorPos(self.mPicture, LxDataHelper.ParseVector2NotEmpty(pos))
			end

			CS.ShowObject(self.mPicture, true)
		end, true)
	end
end

function UIPggGiftPop:OnClickCloseButton()
	if self._closeFunc then self._closeFunc() end
	self:WndClose()
end

--#####################################################################################################################
--## Server ###########################################################################################################
--#####################################################################################################################
function UIPggGiftPop:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end

	self:InitTop()
end

function UIPggGiftPop:OnClickOkBtn()
	local args = string.format("%s_%s", 1, self._eggRefId)
	gModelActivity:OnActivitySpecialOpReq(self._sid,0,0,nil,args,ModelActivity.EGG_REWARD)
	self:OnClickCloseButton()
end

function UIPggGiftPop:InitStaticContent()
	self:SetWndButtonText(self.mOkBtn, ccClientText(26700))
	self:SetWndText(self.mTitleText, ccClientText(26701))
end

function UIPggGiftPop:InitOnItemDraw(list, item, itemdata, itempos)
	local itype = itemdata.itype or itemdata.type
	if itype == nil then itype = itemdata.itemType end

	local refId = itemdata.heroId or tonumber(itemdata.itemId or itemdata.refId)
	local num = itemdata.count or itemdata.itemNum

	local instanceId = item:GetInstanceID()
	local iconRootTrans = CS.FindTrans(item,"Root/CommonUI")
	local uicommonlist = self._uicommonList
	local baseClass = uicommonlist[instanceId]
	if not baseClass then
		baseClass = CommonIcon:New()
		uicommonlist[instanceId] = baseClass
		baseClass:Create(CS.FindTrans(iconRootTrans,"Icon"))
	end
	if itype == LItemTypeConst.TYPE_HERO and itemdata.heroId then
		baseClass:SetHeroPlayer(itemdata.heroId)
	elseif itype == LItemTypeConst.TYPE_HERO and itemdata.heroData then
		baseClass:SetHeroDataSet(itemdata.heroData)
	else
		baseClass:SetCommonReward(itype, refId, num)
	end
	if itemdata.hideNum then
		baseClass:EnableShowNum(false)
	else
		baseClass:EnableShowNum(true)
	end
	baseClass:DoApply()

	self:SetWndClick(iconRootTrans, function()
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)
	self:SetIconClickScale(iconRootTrans, true)

	local uiNameTrans = CS.FindTrans(item, "NumText")
	local uiNameText = uiNameTrans and self:FindWndText(uiNameTrans) or nil
	if uiNameText then
		local itemname,itemcolor = baseClass:GetName()
		self:SetXUITextText(uiNameText, itemname or "")
		if itemcolor then
			self:SetXUITextColor(uiNameText, itemcolor)
		end
		self:InitTextModeWithLanguage(uiNameTrans)
	end
end

function UIPggGiftPop:InitData()
	self._sid = self:GetWndArg("sid") 				-- 活动的sid
	self._eggRefId = self:GetWndArg("eggRefId")		-- 彩蛋
	self._closeFunc = self:GetWndArg("closeFunc")		-- 关闭按钮的回调
	self._ref 		= self:GetWndArg("eggRef")		-- 彩蛋配置


end

function UIPggGiftPop:InitItemScrollView()
	local ref = self._ref
	if not ref then return end

	local reward = ref.reward
	local itemList = LxDataHelper.ParseItem(reward)
	local rewardNum = #itemList

	local uiList = self._uiList
	if not uiList then
		local isEnable = false
		local list
		if rewardNum < 5 then
			isEnable = false
			list = self.mItemScroll
		else
			isEnable = true
			list = self.mItemScrollMax
		end
		uiList = UIListEasy:New()
		uiList:Create(self,list)
		uiList:EnableScroll(isEnable,true)
		uiList:SetFuncOnItemDraw(function(...)
			self:InitOnItemDraw(...)
		end)
		self._uiList = uiList
		CS.ShowObject(list, true)
	end
	uiList:RemoveAll()
	local rewardList = itemList or {}
	for k,v in ipairs(rewardList) do
		uiList:AddData(k,v)
	end
	uiList:RefreshList()
end

function UIPggGiftPop:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
end

function UIPggGiftPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:OnClickCloseButton() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn, function(...) self:OnClickCloseButton() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mOkBtn,function () self:OnClickOkBtn() end, LSoundConst.CLICK_BUTTON_COMMON)
end

------------------------------------------------------------------
return UIPggGiftPop


