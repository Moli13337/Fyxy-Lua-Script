---
--- Created by Administrator.
--- DateTime: 2023/10/22 15:05:11
---
------------------------------------------------------------------
local LWnd = LWnd
local UnityEngine = UnityEngine
local typeof = typeof
local typeUISlider = typeof(UnityEngine.UI.Slider)
---@class UISpSye:LWnd
local UISpSye = LxWndClass("UISpSye", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISpSye:UISpSye()
	---@type CommonIcon
	self._itemIconCls = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISpSye:OnWndClose()
	if self._itemIconCls then
		self._itemIconCls:Destroy()
		self._itemIconCls = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISpSye:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISpSye:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndText(self.mUseBtnName,ccClientText(10230))
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:InitTxt()
end

function UISpSye:InitTxt()
	local refId = self._refId
	local ref = self._ref
	if ref then
		self:SetXUITextText(self.mNameTxt,ccLngText(ref.name))

		local numStr = string.replace(ccClientText(10205),self._propCount)
		self:SetXUITextText(self.mNumTxt,numStr)

		self:SetWndText(self.mDescTxt,ccLngText(ref.description))

		local quaId = ref.quality
		local heroMessage = gModelItem:GetHeroMessQualityById(quaId)
		if heroMessage then self:SetWndEasyImage(self.mHeadImg,heroMessage) end

		local common = CS.FindTrans(self.mItemInfo,"ItemIcon")
		if common then
			local baseClass = self._itemIconCls
			if not baseClass then
				baseClass = CommonIcon:New(self)
				self._itemIconCls = baseClass
				baseClass:Create(common)
			end
			baseClass:SetCommonReward(LItemTypeConst.TYPE_ITEM, refId , 0)
			baseClass:EnableShowNum(false)
			baseClass:DoApply()
		end
	end

	local color = gModelItem:GetItemNameColor(refId)
	if color then
		self:SetXUITextColor(self.mNameTxt,color)
	end

	self:SetWndText(self.mTitle1,ccClientText(10218))
	self:SetWndText(self.mTitle2,ccClientText(10229))
	self:SetWndText(self.mGetDesc,ccClientText(10227))
end

function UISpSye:OptNum(opt)
	local curNum = tonumber(self._propUseCount)
	local allNum = tonumber(self._propCount)
	local newNum = curNum + opt
	local isOpt = false
	if newNum <= allNum and newNum >= 0 then
		isOpt = true
	end
	if isOpt then
		self._propUseCount = newNum
		self:UpdateSliderValue(true)
	end
end

--刷新Slider
function UISpSye:UpdateSliderValue(updata)
	if self._sliderComponent then
		if updata then
			self._sliderComponent.value = self._propUseCount
		end
		self:SetValueNum()
	end
	self._isUpdate = true
end

function UISpSye:SetValueNum(limit)
	local num = self._propUseCount
	if limit then
		num = limit
	end

	self:SetWndText(self.mCurUseTxt ,num)
	local getNum = math.ceil(num * self._rewardOneNum)

	getNum = LUtil.NumberCoversion(getNum)
	self:SetWndText(self.mGetNum,getNum)
end

function UISpSye:InitMsg()
	self:WndNetMsgRecv(LProtoIds.ItemUseResp,function() self:WndClose() end)
end

function UISpSye:InitEvent()
	self:SetWndClick(self.mICloseBtn,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBg,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mAddBtn,function()
		self:OptNum(1)
	end)
	self:SetWndClick(self.mSubBtn,function()
		self:OptNum(-1)
	end)
	self:SetWndClick(self.mUseBtn,function()
		local info = {}
		table.insert(info,{refId = self._refId,num = self._propUseCount})
		gModelItem:OnItemUseReq(info)
	end)

	self:SetWndClick(self.mUseImage,function()
		local tab = {}
		tab.inputTran = self.mUseImage
		tab.minNum = 0
		tab.maxNum = gModelItem:GetNumByRefId(self._refId)

		tab.defaultNum = tonumber(self.mCurUseTxt.text)
		tab.inputFunc = function(numStr,cmd)
			if self:IsWndClosed() then return end
			local num = tonumber(numStr)
			if num then
				if cmd == "C" then
					self:SetValueNum(0)
				elseif cmd == "D" then
					local temp = num
					if temp == 0 then temp = 1 end
					self._propUseCount = temp
					self:UpdateSliderValue(true)
				else
					self:SetWndText(self.mCurUseTxt ,num)
				end
				--print("拥有数量,使用数量,输入数量 = ",self._propCount,self._propUseCount,num)
			end
		end
		GF.OpenWndUp("UINuoardUI",tab)
	end)
end

--刷新物品数量
function UISpSye:UpdatePropValue(sliderValue,updata)
	if self._isUpdate then
		if not sliderValue then return end
		if self._propCount == 1 or self._propCount == "1" then
			sliderValue = 1
			updata = true
		end
		if sliderValue == 0 then
			sliderValue = 1 / self._propCount
		end
		local curPropCount = sliderValue
		self._propUseCount = math.ceil(curPropCount)
		self:UpdateSliderValue(updata)
	end
end

function UISpSye:InitSlider()
	self._sliderComponent = self.mSlider:GetComponent(typeUISlider)
	if (not self._sliderComponent) then
		self._sliderComponent = self.mSlider:AddComponent(typeUISlider)
	end
	self:RefreshSlider()
	LxUiHelper.SetProgress_ValueChanged(self.mSlider, function()
		local value = self._sliderComponent.value
		self:UpdatePropValue(value)
	end)
end

function UISpSye:RefreshSlider()
	local minValue = 1
	local propCount = tonumber(self._propCount)
	if propCount / 10 < 1 then
		minValue = 0
	end
	self._sliderComponent.minValue = minValue
	self._sliderComponent.maxValue = self._propCount
end

function UISpSye:InitData()
	local refId = self:GetWndArg("refId")
	local num = self:GetWndArg("num")
	if not num then
		num = gModelItem:GetNumByRefId(refId)
	end
	self._refId = refId
	self._propCount = num
	local ref = gModelItem:GetRefByRefId(refId)
	self._ref = ref
	local itemRewardList = {}
	local CurMissionCfg = gModelInstance:GetCurMissionCfg()
	if CurMissionCfg then
		local itemReward = string.split(CurMissionCfg.itemReward,",")
		for i,v in ipairs(itemReward) do
			v = string.split(v,"=")
			local tRefId,tNum = tonumber(v[2]),tonumber(v[3])
			itemRewardList[tRefId] = tNum
		end
	end

	local typeDate = string.split(ref.typeDate,"=")
	self._rewardRefId = tonumber(typeDate[1])
	local rewardTime = tonumber(typeDate[2])
	local rewardNum = itemRewardList[self._rewardRefId] or 1
	self._rewardOneNum = rewardNum * rewardTime

	local iconImg = gModelItem:GetItemIconByRefId(self._rewardRefId)
	if iconImg then
		self:SetWndEasyImage(self.mGetIcon,iconImg)
	end

	self._isUpdate = true						--刷新的优先级
	self:InitSlider()
	self:UpdatePropValue(self._propCount,true)
end

------------------------------------------------------------------
return UISpSye