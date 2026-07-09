---
--- Created by BY.
--- DateTime: 2023/4/4 17:14:34
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UICrusadeAgainstSweepPop:LWnd
local UICrusadeAgainstSweepPop = LxWndClass("UICrusadeAgainstSweepPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UICrusadeAgainstSweepPop:UICrusadeAgainstSweepPop()
	self._toggle = false
	self._num = 1
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UICrusadeAgainstSweepPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UICrusadeAgainstSweepPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UICrusadeAgainstSweepPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()



	self.jpj = gLGameLanguage:IsJapanVersion()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UICrusadeAgainstSweepPop:RefreshData()
	local toggle = self._toggle and 1 or 0
	local num = self._num or 1
	num = math.max(1,num)
	local allNum = self:GetSweepNum()
	if num > allNum then
		num = allNum
		self._num = num

		local textId = 32361
		if toggle == 1 then
			textId = 32362
		end

		GF.ShowMessage(ccClientText(textId))
	end
	self:SetWndText(self.mNumText,num)

	local singleEnergy = gModelCrusadeAgainst:GetDreamCrusadeConfigRefByKey("singleEnergy")--梦境讨伐单次消耗体力
	local allConsume = singleEnergy * num
	local useNum = 0
	local buyEnergy = gModelCrusadeAgainst:GetDreamCrusadeConfigRefByKey("buyEnergy")
	local buyEnergyItem = LxDataHelper.ParseItem_4(buyEnergy)
	local physical = gModelCrusadeAgainst:GetPhysical()--当前体力
	if allConsume > physical and toggle == 1 then
		local itemRef = gModelItem:GetRefByRefId(buyEnergyItem.itemId)
		local itemHp = tonumber(itemRef.typeDate)--每个道具回复体力
		local needHp = allConsume - physical
		useNum = math.ceil(needHp/itemHp)
	end

	local itemNum = gModelItem:GetNumByRefId(buyEnergyItem.itemId)
	local color
	if useNum >= itemNum then
		color = "red"
	else
		color = "green"
	end
	local str = LUtil.FormatColorStr(useNum,color) .."/"..itemNum
	self:SetWndText(self.mSelNumText,string.replace(ccClientText(32357),str))
end

function UICrusadeAgainstSweepPop:InitEvent()
	self:SetWndClick(self.mBgImage,function() self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end)
	self:SetWndClick(self.mBtnReduce,function() self:OnClickReduce() end)
	self:SetWndClick(self.mBtnAdd,function() self:OnClickAdd() end)
	self:SetWndClick(self.mBtnConfirm,function() self:OnClickConfirm() end)
	self:SetWndClick(self.mBtnCancel,function() self:WndClose() end)
	self:SetWndClick(self.mNumText,function () self:OpenKeyboard() end)
end

function UICrusadeAgainstSweepPop:GetSweepNum()
	local toggle = self._toggle and 1 or 0

	local physical = gModelCrusadeAgainst:GetPhysical()--当前体力
	local singleEnergy = gModelCrusadeAgainst:GetDreamCrusadeConfigRefByKey("singleEnergy")--梦境讨伐单次消耗体力

	local buyEnergy = gModelCrusadeAgainst:GetDreamCrusadeConfigRefByKey("buyEnergy")
	local buyEnergyItem = LxDataHelper.ParseItem_4(buyEnergy)
	local num = gModelItem:GetNumByRefId(buyEnergyItem.itemId)--拥有体力药数量
	local allItemHp = 0
	if toggle == 1 and num > 0 then
		local itemRef = gModelItem:GetRefByRefId(buyEnergyItem.itemId)
		local itemHp = tonumber(itemRef.typeDate)--每个道具回复体力
		allItemHp = itemHp * num
	end
	local allHp = physical + allItemHp
	local allNum = math.floor(allHp/singleEnergy)
	return allNum
end
function UICrusadeAgainstSweepPop:OnClickAdd()
	local num = self._num or 1
	--local allNum = self:GetSweepNum()
	--if num < allNum then
		num = num +1
	--end
	self._num = num
	self:RefreshData()
end

function UICrusadeAgainstSweepPop:OpenKeyboard()

	local max = self:GetSweepNum()
	local func = function(input)
		if self:IsWndClosed() then
			return
		end

		self._num = tonumber(input)

		self._num = math.max(1,self._num)
		self:RefreshData()
	end


	local para = {
		minNum = 1,
		maxNum = max,
		defaultNum = 1,
		inputFunc = func,
		inputTran = self.mNumText
	}


	GF.OpenWnd("UINuoardUI",para)

end
function UICrusadeAgainstSweepPop:OnClickConfirm()
	local num = self._num or 1
	local allNum = self:GetSweepNum()
	if num > allNum then
		GF.ShowMessage(ccClientText(32360))
		return
	end

	LPlayerPrefs.SetCrusadeSweepNum(num)
	local nodeId = self._nodeId
	gModelCrusadeAgainst:OnCrusadeAgainstSweepReq(nodeId,num)
	--LogError(string.format("扫荡关卡%s ，扫荡%s 次",nodeId,num))
end
function UICrusadeAgainstSweepPop:InitMessage()

	self:WndNetMsgRecv(LProtoIds.CrusadeAgainstSweepResp,function(pb) self:WndClose() end)
end

function UICrusadeAgainstSweepPop:OnClickReduce()
	local num = self._num or 1
	--if num > 1 then
		num = num - 1
	--end
	self._num = num
	self:RefreshData()
end
function UICrusadeAgainstSweepPop:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(32353))
	self:SetWndText(self.mDesText,ccClientText(32355))
	self:SetWndText(self.mToggleText,ccClientText(32356))
	self:SetWndText(self.mSelNumText,string.replace(ccClientText(32357),0))
	self:SetWndButtonText(self.mBtnCancel,ccClientText(32358))
	self:SetWndButtonText(self.mBtnConfirm,ccClientText(32359))
	if self.jpj then
		local tog = self.mToggleText.parent
		self:SetAnchorPos(tog,Vector2.New(-80,-60.7))
		self:InitTextSizeWithLanguage(self.mToggleText,-4)
		self:InitTextCharacterWithLanguage(self.mToggleText,-5)
	end
	local nodeId = self:GetWndArg("nodeId")
	self._nodeId = nodeId

	local  ref = gModelCrusadeAgainst:GetDreamCrusadeCheckpointRefByRefId(nodeId)
	local difficulty = ref.difficulty
	local levelNum = ref.levelNum
	local nameStr = string.replace(ccClientText(32354),difficulty.."-"..levelNum)
	self:SetWndText(self.mNameText,nameStr)

	self._toggle = LPlayerPrefs.crusadeUseDrug == "1"
	local recordNum = tonumber(LPlayerPrefs.crusadeSweepNum) or 1
	local allNum = self:GetSweepNum()
	self._num = math.min(recordNum,allNum)

	self:SetWndToggleValue(self.mToggle,self._toggle)

	self:SetWndToggleDelegate(self.mToggle,function (value)
		self._toggle = value
		local saveV = value and "1" or "0"
		LPlayerPrefs.SetCrusadeUseDrug(saveV)
		self:RefreshData()
	end)

	self:RefreshData()
end
------------------------------------------------------------------
return UICrusadeAgainstSweepPop


