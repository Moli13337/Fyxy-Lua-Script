---
--- Created by Administrator.
--- DateTime: 2023/10/9 11:32:49
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPkAward:LWnd
local UIPkAward = LxWndClass("UIPkAward", LWnd)
local Tweening = DG.Tweening
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPkAward:UIPkAward()
	---@type table<number,CommonIcon>
	self._uicommonList = {}

	self._uiList = nil
	self._uiPassList = nil

end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPkAward:OnWndClose()
	self:ClearTween()
	if self._uicommonList then
		local iconList = self._uicommonList
		for k,v in pairs(iconList) do
			v:Destroy()
			iconList[k] = nil
		end
		self._uicommonList = nil
	end

	local parameters = self._parameters
	if parameters then
		local portId = parameters[1]
		if portId == UIAward.USE_ITEM_UPHEROINFO then
			gModelHero:SelItemUpHeroIdList()
		end
	end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPkAward:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPkAward:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:InitEvent()

	LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_EQUIP_COMMON)
	self:StartTween()
end

function UIPkAward:InitPassScrollRect()
	local list = self._passItemList or {}
	local itemNum = #list
	local uiList = self._uiPassList

	if not uiList then
		local isShowMax = itemNum > 5
		CS.ShowObject(self.mPassList, isShowMax)
		CS.ShowObject(self.mMinPassList, not isShowMax)
		if isShowMax then
			uiList = UIListWrap:New()
			uiList:Create(self, self.mPassList)
			uiList:SetFuncOnItemReturn(function(...)
				self:OnRewardItemReturn(...)
			end)
		else
			uiList = UIListEasy:New()
			uiList:Create(self, self.mMinPassList)
		end

		uiList:EnableScroll(isShowMax, true)
		uiList:SetFuncOnItemDraw(function(...)
			self:uilist_2_onDraw(...)
		end)
		self._uiPassList = uiList
	end
	uiList:RemoveAll()

	for i = 1, itemNum do
		local data = list[i]
		local itemData = {
			itype = data.itemType or data.itype,
			itemId = data.itemId,
			count = data.itemNum or data.count,
			isNeedPlayAni = true,
		}

		uiList:AddData(i, itemData)
	end
	uiList:RefreshList()
end

function UIPkAward:InitText()
	if self._btnTextList then
		for i, text in ipairs(self._btnTextList) do
			if i == 1 then
				self:SetWndButtonText(self.mBtn1, text)
			else
				self:SetWndButtonText(self.mBtn2, text)
			end
		end
	end


	if self._passDesc then
		self:SetWndText(self.mPassDesc, self._passDesc)
	end
end

function UIPkAward:ClearTween()
	if self._seq then
		self._seq:Kill(false)
		self._seq = nil
	end
end

function UIPkAward:TweenItemScale(item,itempos,isNeedPlayAni)
	local nowTime = Time.time
	local timePast =nowTime - self._startTime
	local delay = itempos*self._iconPlayTime

	if timePast>delay then
		item.transform.localScale= Vector3.New(1,1,1)
		return
	end
	local curDelay = delay - timePast
	local instanceId = item:GetInstanceID()
	item.transform.localScale= Vector3.New(0,0,0)
	self:TweenSeqKill(instanceId)
	local seq =self:TweenSeqCreate(instanceId,function (seq)
		local tween = item:DOScale(Vector3.New(1,1,1),self._iconPlayTime)
		seq:AppendInterval(curDelay)

		seq:Append(tween)

		return seq
	end)
	seq:OnComplete(function ()
		self:TweenSeqKill(instanceId)
	end)
	seq:PlayForward()
end

function UIPkAward:InitScrollRect()
	self._startTime = Time.time
	local uiList = self._uiList
	local list = self._itemList or {}
	local itemNum = #list

	if not uiList then
		local isShowMax = itemNum > 3
		CS.ShowObject(self.mMaxList, isShowMax)
		CS.ShowObject(self.mMinList, not isShowMax)
		if isShowMax then
			uiList = UIListWrap:New()
			uiList:Create(self, self.mMaxList)
			uiList:SetFuncOnItemReturn(function(...)
				self:OnRewardItemReturn(...)
			end)
		else
			uiList = UIListEasy:New()
			uiList:Create(self, self.mMinList)
		end

		uiList:EnableScroll(isShowMax, true)
		uiList:SetFuncOnItemDraw(function(...)
			self:uilist_2_onDraw(...)
		end)
		self._uiList = uiList
	end
	uiList:RemoveAll()

	for i = 1, itemNum do
		local data = list[i]
		data.isNeedPlayAni = true
		uiList:AddData(i, data)
	end
	uiList:RefreshList()
end

function UIPkAward:uilist_2_onDraw(list, item, itemdata, itempos)
	local itype = itemdata.itype
	local refId = tonumber(itemdata.itemId)
	local num = itemdata.count
	local setRefId = refId
	if itype == 4 then
		setRefId = nil
		local serverData = gModelRune:GetServerDataById(refId)
		if serverData then
			setRefId = serverData.refId
		end
	end

	local isNeedPlayAni = itemdata.isNeedPlayAni
	itemdata.isNeedPlayAni = false
	self:OnDrawCommonItem(item, itype, setRefId, num, itempos, isNeedPlayAni)

	self:SetWndClick(item,function()
		self._funcList[itype](refId,num)
	end)
end

function UIPkAward:RefreshUI()
	self:InitText()

	self:ShowList()
end

function UIPkAward:ShowList()
	self._playAni = false
	self:InitScrollRect()
	self:InitPassScrollRect()
end

function UIPkAward:StartTween()
	self:ClearTween()

	self._isCreateAni = true
	local contentTrans = self.mContent
	contentTrans.localRotation = Quaternion.Euler(90,0,0)

	local seq =Tweening.DOTween.Sequence()
	self._seq = seq

	local duration = 0.4
	local rotateTween = contentTrans:DORotate(Vector3.New(0,0,0),duration)
	seq:Append(rotateTween)
	seq:InsertCallback(0.1,function()
		self:RefreshUI()
	end)
	seq:OnComplete(function()
		self._seq = nil
		self._isCreateAni = false
	end)
	seq:PlayForward()

end

function UIPkAward:InitEvent()
	self:SetWndClick(self.mBtn1,function()
		self:WndClose()
	end)

	self:SetWndClick(self.mBtn2,function()
		if self._func then
			self._func()
		end
		self:WndClose()
	end)
end

function UIPkAward:InitData()
	self._refId = self:GetWndArg("refId")
	self._itemList = self:GetWndArg("itemList")
	self._parameters = self:GetWndArg("parameters")

	self._func = self:GetWndArg("func")
	self._btnTextList = self:GetWndArg("btnTextList")

	self._passDesc = self:GetWndArg("passDesc")
	self._passItemList = self:GetWndArg("passItemList")

	self._isCreateAni = false

	self._uicommonList = {}
	self._playAni = true
	self._iconPlayTime =0.1
	-- self._playTime = self._playTime
	local itemFunc = function(refId,num)
		--GF.OpenWndUp("UIInip",{refId = refId,showNum = num})
		gModelGeneral:OpenItemInfoTip(refId,num)
	end
	local heroFunc = function(refId, num, id)
		if id then
			local serverData = gModelHero:GetHeroServerDataById(id)
			refId = serverData.refId
		end
		gModelGeneral:OpenHeroSimpleTip(refId)
	end
	local equipFunc = function(refId)
		GF.OpenWndUp("UIEqInfo",{refId = refId,OpenWay = false,noShowBtn = true})
	end
	local runeFunc = function(id)
		local serverData = gModelRune:GetServerDataById(id)
		if serverData then
			local data = {runeData = serverData}
			gModelGeneral:OpenRuneInfoTip(data)
		end
	end
	local outfitFunc = function(refId)
		local curSerData = {
			refId = refId,
			star = 0,
			heroRefId = 0,
			starExp = 0,
			heroId = "0",
			-- score = gModelOutfit:GetOutfitBaseScoreByRefId(refId),
			score = 0,
			nextHeroRefId = 0,
			_type = LItemTypeConst.TYPE_OUTFIT,
		}
		gModelGeneral:OpenOutfitInfoTip({curSerData = curSerData,outfitType = 2},true)
	end
	self._funcList = {
		itemFunc,
		heroFunc,
		equipFunc,
		runeFunc,
		outfitFunc,
	}

	local effectName = "fx_ui_gongxihuode"
	self:CreateWndEffect(self.mTitle,effectName,effectName,100)
end

function UIPkAward:OnClickEmpty()
	if self._isCreateAni then return end
	if self._seq then
		self._seq:Kill(false)
		self._seq = nil
		local contentTrans = self.mContent
		contentTrans.localRotation = Quaternion.Euler(0,0,0)
		--self:ClearBaseClassListAni()
		self:RefreshUI()

	else
		self:WndClose()
	end
end

function UIPkAward:OnDrawCommonItem(item, itype, refId, num, itempos, isNeedPlayAni)
	local uicommonlist = self._uicommonList
	local instanceID = item:GetInstanceID()
	local baseClass = uicommonlist[instanceID]

	local uiCommonTrans = CS.FindTrans(item,"CommonUI")

	if not baseClass then
		baseClass = CommonIcon:New()
		uicommonlist[instanceID] = baseClass
		baseClass:Create(CS.FindTrans(uiCommonTrans,"Icon"))
	end


	baseClass:SetCommonReward(itype, refId, num)
	baseClass:EnableShowNum(true)
	baseClass:DoApply()

	local uiNameTrans = CS.FindTrans(uiCommonTrans, "UIName")
	if uiNameTrans then
		local uiNameText = uiNameTrans and self:FindWndText(uiNameTrans) or nil
		if uiNameText then
			local itemname,itemcolor = baseClass:GetName()
			self:SetXUITextText(uiNameText, itemname or "")
			if itemcolor then
				self:SetXUITextColor(uiNameText, itemcolor)
			end
		end
	end

	self:TweenItemScale(uiCommonTrans,itempos,isNeedPlayAni)
end

function UIPkAward:OnRewardItemReturn(list,item,itemdata,itempos)
	local instanceId = item:GetInstanceID()
	self:TweenSeqKill(instanceId)
end

------------------------------------------------------------------
return UIPkAward


