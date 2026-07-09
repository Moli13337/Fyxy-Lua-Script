---
--- Created by Administrator.
--- DateTime: 2023/10/8 11:46:21
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPkBuyPop:LWnd
local UIPkBuyPop = LxWndClass("UIPkBuyPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPkBuyPop:UIPkBuyPop()
	---@type UIIconEasyList
	self._rewardListCls = nil
	---@type UIIconEasyList
	self._rewardListClsMax = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPkBuyPop:OnWndClose()
	if self._rewardListCls then
		self._rewardListCls:Destroy()
		self._rewardListCls = nil
	end

	if self._rewardListClsMax then
		self._rewardListClsMax:Destroy()
		self._rewardListClsMax = nil
	end
	if self._seqCom  then
		self._seqCom:Destroy()
		self._seqCom= nil
	end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPkBuyPop:OnCreate()
	LWnd.OnCreate(self)
	self._seqCom = SequenceCom:New()
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPkBuyPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	--self:DoWndStartScale(0,self.mPop)
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
	self:RefreshUI()
end

function UIPkBuyPop:InitCommand()
	self._sid = self:GetWndArg("sid")
	self._entry = self:GetWndArg("entry")
	local index = self:GetWndArg("index")
	self._descStr = self:GetWndArg("descStr")
	self._buyBtnStr = self:GetWndArg("buyBtnStr")
	self._passType = self:GetWndArg("passType")
	self._defaultIndex = self:GetWndArg("defaultIndex")
	self._titleName = self:GetWndArg("titleName")

	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then
		self:WndClose()
		return
	end

	local data = JSON.decode(activityData.moreInfo)

	local buyPassNum
	local buyPassArr
	if not self._passType then --战令
		buyPassNum = data.buyPassNum
		buyPassArr = string.split(data.buyPassReward ,"|")
	-- elseif self._passType == ModelActivity.ACTIVITY_FAIRY_TALE then --梦境童话书
	-- 	if index == 1 then
	-- 		buyPassNum = data.buyPassNum
	-- 		buyPassArr =data.buyPassReward
	-- 	else
	-- 		buyPassNum = data.buyPassLuxuryNum
	-- 		buyPassArr = data.buyPassLuxuryReward
	-- 	end
	else
		local entryData = self._entry[self._defaultIndex]
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,entryData.pageId,entryData.entryId)
		buyPassArr=entryCfg.reward
		self._titleName = entryCfg.name
	end

	self._buyPassArr = buyPassArr
	if buyPassNum then
		self._bGuys =string.split(buyPassNum,",")
	end


	if not self._defaultIndex then
		local defaultIndex = 1
		if(index and index>0)then
			defaultIndex = index
		else
			for i, v in ipairs(self._bGuys) do
				if(v == "0")then
					defaultIndex = i
					break
				end
			end
		end

		self._defaultIndex = defaultIndex
	end

	self:InitTitleName()
end

function UIPkBuyPop:OnClickBuy(entryId,expend2,pageId)--购买
	gModelPay:GiftPayCtrl(entryId,expend2,ModelPay.PAY_TYPE_ACTIVITY,0,self._sid,pageId)
end

function UIPkBuyPop:InitTitleName()
	if self._titleName then
		self:SetWndText(self.mTitleText, self._titleName)
	else
		self:SetWndText(self.mTitleText, ccClientText(10154))
	end
end

function UIPkBuyPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		self:WndClose()
	end)
end

function UIPkBuyPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIPkBuyPop:RefreshUI()
	local index = self._defaultIndex
	local itemdata = self._entry[index]

	local list
	if not self._passType then --战令
		list = LxDataHelper.ParseItem(self._buyPassArr[index])
	else
		list= LxDataHelper.ParseItem(self._buyPassArr)
	end

	local listNum = #list
	local isMax   = listNum > 4
	CS.ShowObject(self.mItemScroll, not isMax)
	CS.ShowObject(self.mItemScrollMax, isMax)

	local uiList
	if not isMax then
		uiList = self._rewardListCls
		if not uiList then
			uiList = UIIconEasyList:New()
			uiList:Create(self,self.mItemScroll)
			uiList:SetIconParentPath("Root/CommonUI/Icon")
			self._rewardListCls = uiList
			uiList:SetShowNum(false)
			uiList:SetShowExtraNum(true, "NumText")
		end
	else
		uiList = self._rewardListClsMax
		if not uiList then
			uiList = UIIconEasyList:New()
			uiList:Create(self,self.mItemScrollMax)
			uiList:SetIconParentPath("Root/CommonUI/Icon")
			self._rewardListClsMax = uiList
			uiList:SetShowNum(false)
			uiList:SetShowExtraNum(true, "NumText")
		end
	end
	if isMax then
		local key = "delay"
		local seq = self._seqCom:CreateSeq(key)
		seq:AppendInterval(0.02)
		seq:OnComplete(function ()
			uiList:EnableScroll(true, true)
			self._seqCom:DeleteSeq(key)
		end)
		seq:PlayForward()
	else
		uiList:EnableScroll(isMax, true)
	end
	uiList:RefreshList(list)


	self:SetWndText(self.mPayText,self._buyBtnStr)
	self:SetWndClick(self.mPayBtn, function(...)
		self:OnClickBuy(itemdata.entryId,tonumber(itemdata.MarketData.expend2),itemdata.pageId)
	end)

	local descStr = self._descStr
	local haveDesc = descStr ~= nil
	CS.ShowObject(self.mDescBg, haveDesc)
	if haveDesc then
		self:SetWndText(self.mDescText, descStr)
	end
end

------------------------------------------------------------------
return UIPkBuyPop


