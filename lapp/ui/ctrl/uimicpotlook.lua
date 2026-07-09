---
--- Created by Administrator.
--- DateTime: 2024/9/23 21:09:13
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMicPotLook:LWnd
local UIMicPotLook = LxWndClass("UIMicPotLook", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMicPotLook:UIMicPotLook()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMicPotLook:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMicPotLook:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMicPotLook:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._lastbtn = 1
	self.jpj = gLGameLanguage:IsJapanVersion()
	self._btnList = {}
	local TextNum = self:GetWndArg("TextNum")
	self.TextNum = TextNum
	local ind = self:GetIndex(self.TextNum)
	self._lastbtn = ind
	self:InitCommon()
	self:InitList()
	self:InitList2()
end

function UIMicPotLook:BtnEvent(refId,index)
	self._btnRefId = refId
	self._lastbtn = index
	self:ChangeBtnImage()
	--self._changeBtn = true
	self:InitList()
end

function UIMicPotLook:InitList()

	local list = gModelMagicPot:GetLookData2()
	local showList={}
	for k, v in ipairs(list) do
		if v.refId == self._lastbtn then
			table.insert(showList, v)
		end
	end
	if self.list then
		self.list:RefreshList(showList)
		self.list:DrawAllItems()
	else
		self.list = self:GetUIScroll("mTaskList")
		self.list:Create(self.mList, showList, function(...) self:SetItem(...) end, UIItemList.SUPER)
	end
end
function UIMicPotLook:GetIndex(num)
	local index = 1
	if num>=0 and num <16 then
		index=1
	elseif num >=16 and num <31 then
		index=2
	elseif num >=31 and num <61 then
		index=3
	elseif num >=61 and num <91 then
		index=4
	elseif num >=91 and num <121 then
		index=5
	elseif num >=121 and num <151 then
		index=6
	elseif num >=151 and num <181 then
		index=7
	elseif num >=181 and num <211 then
		index=8
	elseif num >=211 and num <241 then
		index=9
	elseif num >=241 and num <361 then
		index=10
	elseif num >=361 and num <481 then
		index=11
	elseif num >=481 and num <601 then
		index=12
	elseif num >=601 and num <721 then
		index=12
	elseif num >=721 then
		index=14
	end
	return index
end

function UIMicPotLook:InitCommon()
	-----------------------------------------------
	---text
	self:SetWndText(self.mLblBiaoti, ccClientText(45817))
	self:SetWndText(self.mTipsText, ccClientText(45811))
	self:SetWndText(self.mCloseTip, ccClientText(10103))

	-----------------------------------------------
	---Click
	self:SetWndClick(self.mMask, function()
		self:WndClose()
	end)
end

function UIMicPotLook:SetIcon(item, data, isMust)
	local root = CS.FindTrans(item, "Root")
	local must = CS.FindTrans(item, "Must")
	local mustText = CS.FindTrans(must, "Text")
	local ProbabilityTxt = CS.FindTrans(item, "ProbabilityTxt")
	local instanceId = root:GetInstanceID()
	local commonIcon = self:GetCommonIcon(instanceId)
	commonIcon:Create(root)
	commonIcon:SetCommonReward(data.itemType, data.itemId, data.itemNum)
	commonIcon:DoApply()

	self:SetWndText(mustText, ccClientText(45813))
	if self.jpj then
		self:InitTextSizeWithLanguage(mustText,-8)
	end
	CS.ShowObject(must, isMust)
	self.UTxt = nil
	local str = data.probabilityShow
	if str ~= nil  then
		str = math.ceil(str*100000)
		str = str/100000
		str = str * 100 .."%"
	else
		str = "100%"
	end

	self:SetWndText(ProbabilityTxt,str)
	if data.rateShow == 0 then
		CS.ShowObject(ProbabilityTxt,false)
	else
		CS.ShowObject(ProbabilityTxt,true)
	end
	self:SetWndClick(root, function()
		gModelGeneral:ShowCommonItemTipWnd(data)
	end)
end

function UIMicPotLook:SetTypeBtn(_,item, data)
	local btnTab1 = CS.FindTrans(item, "BtnTab1")
	local refId = data.refId
	local str = data.endNum == 0 and data.startNum .. "+" or string.replace(ccClientText(45812), data.startNum, data.endNum)
	--self:SetWndTabText(btnTab1, str)
	if btnTab1 then
		self._btnList[refId] = btnTab1
		self:SetWndClick(btnTab1,function()
			self:BtnEvent(refId,refId)
		end)
		local status = self._lastbtn == refId and 0 or 1
		self:SetWndTabStatus(btnTab1,status)
		self:SetWndTabText(btnTab1,str)
	end
end

function UIMicPotLook:ChangeBtnImage()
	local btnList = self._btnList or {}
	for k,v in pairs(btnList) do
		local status = self._lastbtn == k and 0 or 1
		self:SetWndTabStatus(v,status)
	end
end

function UIMicPotLook:SetItem(_,item, data)
	if not item then return end
	local itemObj = CS.FindTrans(item, "ItemObj")
	local text = CS.FindTrans(item, "Image/Text")
	local str = data.endNum == 0 and data.startNum .. "+" or string.replace(ccClientText(45812), data.startNum, data.endNum)
	self:SetWndText(text, str)
	local t = {
		data.mustRewards,
		data.rewards
	}
	local a, b = true, true
	local i = 1
	while a or b do
		local item = CS.FindTrans(itemObj, "MustIcon" .. i)
		if item then
			CS.ShowObject(item, false)
		else
			a = false
		end
		item = CS.FindTrans(itemObj, "Icon" .. i)
		if item then
			CS.ShowObject(item, false)
		else
			b = false
		end
		i = i + 1
	end

		for i, v in ipairs(t) do
			for i2, v2 in ipairs(v) do
				local name = i == 1 and "MustIcon" .. i2 or "Icon" .. i2
				local item = CS.FindTrans(itemObj, name)
				if not item then
					local gameObj = LxUnity.InstantObject(self.mIconTemplate.gameObject)
					gameObj.name = name
					item = gameObj.transform
					LxUnity.SetParentTrans(item, itemObj)
				end
				--if self._btnRefId == data.refId then
				self:SetIcon(item, v2, i == 1)
				CS.ShowObject(item, true)
				--end
			end
		end



	local step = math.ceil((#data.mustRewards + #data.rewards) / 5)
	item.sizeDelta = Vector2.New(576, 60 + (step * 99) + ((step - 1) * 30))
end

function UIMicPotLook:InitList2()
	local list = gModelMagicPot:GetNum()
	if self._mTypeBtnList then
		self._mTypeBtnList:RefreshList(list)
		self._mTypeBtnList:DrawAllItems()
	else
		self._mTypeBtnList = self:GetUIScroll("mTypeBtnList")
		self._mTypeBtnList:Create(self.mTypeBtnList, list, function(...) self:SetTypeBtn(...) end)
		self._mTypeBtnList:EnableScroll(true,true)
	end
	self._mTypeBtnList:MoveToPos(self._lastbtn)
	self._btnRefId = list[1].refId
	self:ChangeBtnImage()
end

------------------------------------------------------------------
return UIMicPotLook