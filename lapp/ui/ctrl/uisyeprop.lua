---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
local CS = CS
local UnityEngine = UnityEngine
local typeof = typeof
local typeUISlider = typeof(UnityEngine.UI.Slider)

---@class UISyeProp:LWnd
local UISyeProp = LxWndClass("UISyeProp", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISyeProp:UISyeProp()
	---@type CommonIcon
	self._itemIconCls = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISyeProp:OnWndClose()
	if self._itemIconCls then
		self._itemIconCls:Destroy()
		self._itemIconCls = nil
	end
	if self._func then self._func() end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISyeProp:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISyeProp:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitMsg()
end

--合成英雄
function UISyeProp:GetHero()
	local dataTable = gModelItem:GetTypeDataByRefId(self._propID)
	for i, v in ipairs(dataTable) do
		if self._propUseCount >= v.num then
			local usePropCount = self._propUseCount
			local surplusValue = self._propUseCount % v.num
			local value = math.ceil(self._propUseCount / v.num)
			if surplusValue > 0 then value = value - 1 end --如果有余数则要减少一份的使用单位
			self._propCount = self._propCount - self._propUseCount + surplusValue
			self._propUseCount = self._propCount
			if value > 0 then
				local info = {}
				table.insert(info,{refId = self._propID,num = usePropCount}) --向服务器发送物品使用请求
				gModelItem:OnItemUseReq(info)
				return value
			end
		else
			self._needCount = v.num
			return false
		end
	end

	return false
end

function UISyeProp:InitData()
	self._sliderComponent = nil					--slider组件
	self._isUpdate = true						--刷新的优先级
	self._needCount = nil						--道具合成需要的数量

	if not self._propCount then
		local refId = self:GetWndArg("refId")
		local maxValue = self:GetWndArg("maxValue")
		self._itype = self:GetWndArg("itype")
		self._defaultNum = self:GetWndArg("defaultNum")
		self._callFunc = self:GetWndArg("callFunc")
		if not maxValue then
			maxValue = gModelItem:GetNumByRefId(refId)
		end
		if not self._defaultNum then
			self._defaultNum = 0
		end
		self:SetData(refId,maxValue)
		local ref = gModelItem:GetRefByRefId(refId)
		if ref then
			self._useMoreTxt = ccLngText(ref.useMoreTxt)
			self._ref = ref
		end
		self._refId = refId
	end
	self._func = self:GetWndArg("func")

	if self._itype and self._itype == ModelItem.Item_DROPITEMTYPE and self._refId then
		gModelItem:OnItemDropReplaceInfoReq(self._refId)
	end

	self:InitImage()
	self:InitSlider()

	if self._defaultNum == 1 then
		self:UpdatePropValue(self._propCount,true)
	end

	----------------------------------------------------------
	---检查修正，临时数据赋值
	----------------------------------------------------------
	local str = ccClientText(10205)
	local num = gModelItem:GetNumByRefId(self._propID)
	str = string.replace(str,num)
	self:SetXUITextText(self.mItemValue,str)
	self:SetValueNum()
	----------------------------------------------------------
end

--判断是否达到使用要求（目前只做了合成英雄，使用物品功能暂未完善）
function UISyeProp:IsCanUse()
	--if self._itype == 107 then
	--	if self:GetHero() then return true end
	--else
	if self:BatchUseProp() then return true end
	--end
	return false
end

--刷新物品数量
function UISyeProp:UpdatePropValue(sliderValue,updata)
	if self._isUpdate then
		if not sliderValue then return end
		if self._propCount == 1 or self._propCount == "1" then
			sliderValue = 1
			updata = true
		end
		if sliderValue == 0 then
			sliderValue = 1/self._propCount
		end
		-- local curPropCount = sliderValue * self._propCount
		local curPropCount = sliderValue
		self._propUseCount = math.ceil(curPropCount)
		self:UpdateSliderValue(updata)
	end
end

--退出
function UISyeProp:Exit()
	self:WndClose()
end

function UISyeProp:SetValueNum(limit)
	local num = self._propUseCount
	if self._needNum then
		num = num * self._needNum
	end
	if limit then num = limit end
	self:SetXUITextText(self.mValue ,num)
end

function UISyeProp:InitSlider()
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

--批量使用道具（未完善）
function UISyeProp:BatchUseProp()
	-- 102
	self._heroBagFull = false
	-- 145
	-- self._petBagFull = false
	local usePropCount = tonumber(self._propUseCount)
	if self._itype == ModelItem.Item_DEBRIS then
	--if gModelItem:CheckIsDebrisByIType(self._itype) then
		local heroBagNum,heroNum = gModelHero:GetHoerBagNum(),gModelHero:GetHeroNum()
		if heroBagNum < heroNum + usePropCount then
			self._heroBagFull = true
			return false
		end
		usePropCount = self._needNum * usePropCount
	elseif self._itype == ModelItem.DEBRIS_COMPOUND then
		usePropCount = self._needNum * usePropCount
	elseif self._itype == ModelItem.TTEM_TYPE_SORCERY then
		usePropCount = self._needNum * usePropCount
	-- 【C宠物系统】删掉宠物系统相关
	-- elseif self._itype == ModelItem.ITEM_PET_DEBRIS then
	-- 	local petBagLimit = gModelPetSpace:GetPetBagLimit()
	-- 	local curPetBagNum  =gModelPetSpace:GetCurPetBagNum()
	-- 	if(curPetBagNum>=petBagLimit)then
	-- 		local leftFunc = function()
	-- 			GF.OpenWnd("WndPetBag")
	-- 		end
	-- 		gModelGeneral:OpenUIOrdinTips({refId = 380010,leftFunc = leftFunc,func = leftFunc})
	-- 		return true
	-- 	elseif(curPetBagNum+usePropCount>=petBagLimit)then
	-- 		local needNum,propCount,propUseCount,propID = self._needNum,self._propCount,self._propUseCount,self._propID
	-- 		local leftFunc = function()
	-- 			self._propCount = propCount - propUseCount
	-- 			self:DOItemUseReq(needNum * usePropCount,propID)
	-- 		end
	-- 		gModelGeneral:OpenUIOrdinTips({refId = 380001,leftFunc = leftFunc,func = leftFunc})
	-- 		return true
	-- 	end
	-- 	usePropCount = self._needNum * usePropCount
	end
	self._propCount = self._propCount - self._propUseCount
	print("---  ",type(self._propID),type(usePropCount))

	if self._itype == ModelItem.TTEM_TYPE_EQUIP_STRENGTH_3 then
		local typeData = gModelItem:GetTypeDataByRefId(self._propID)
		local needNum = 0
		for i, v in ipairs(typeData) do
			needNum = v.num
		end
		usePropCount=usePropCount*needNum

	end

	self:DOItemUseReq(usePropCount,self._propID)
	return true
end

function UISyeProp:SetData(ID,value)
	--if self._itype == ModelItem.Item_DEBRIS then
	if gModelItem:CheckIsDebrisByIType(self._itype) then
		local typeData = gModelItem:GetTypeDataByRefId(ID)
		local needNum = 0
		for i, v in ipairs(typeData) do
			needNum = v.num
		end
		self._propCount = math.floor(value/needNum)

		self._needNum = needNum
	else
		self._propCount = value --道具数量(玩家拥有最大数)
	end
	if self._defaultNum == 1 then
		self._propUseCount = self._propCount --道具使用数量
	else
		self._propUseCount = 1
	end
	self._propID = ID --道具ID

	self._propName = gModelItem:GetNameByRefId(self._propID) --道具名称
	self._propDescribe = gModelItem:GetDescByRefId(self._propID) --道具描述
end

function UISyeProp:InitMsg()
	self:WndNetMsgRecv(LProtoIds.ItemDropReplaceInfoResp, function(pb,ret)
		if not self._refId then return end
		local dropInfo = pb.dropInfo
		if not dropInfo then return end
		local refId = dropInfo.refId
		if self._refId and self._refId ~= refId then return end
		self:RefreshDropDesc(dropInfo)
	end)
end

function UISyeProp:RefreshDropDesc(dropInfo)
	local refId = self._refId
	if not refId then return end
	local ref = gModelItem:GetRefByRefId(refId)
	if not ref then return end
	local itype = ref.type
	if itype ~= ModelItem.Item_DROPITEMTYPE then return end
	local group = dropInfo.group
	local typeDate = string.split(ref.typeDate,"|")
	local refGroup = tonumber(typeDate[1])
	if group ~= refGroup then return end
	local description = ccLngText(ref.description)
	description = string.replace(description,dropInfo.num)
	self:SetXUITextText(self.mDescribeText,description)
end

function UISyeProp:InitImage()
	local title = ccClientText(10207)
	--if self._itype == ModelItem.Item_DEBRIS then
	if gModelItem:CheckIsDebrisByIType(self._itype) then
		title = ccClientText(10212)
	end
	self:SetXUITextText(self.mLblBiaoti,title)

	local text = CS.FindTrans(self.mTextTitle,"UIText")
	self:SetWndText(text,ccClientText(10208))
	self:SetWndButtonText(self.mCancel,ccClientText(10101))
	self:SetWndButtonText(self.mDetermine,ccClientText(10102))

	local refId = self._propID
	if refId then
		local num = self._propCount
		if not num then
			num = 0
			self._propCount = num
		end
		local common = CS.FindTrans(self.mItem,"ItemIcon")
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

		local color = gModelItem:GetItemNameColor(refId)
		if color then
			self:SetXUITextColor(self.mItemName,color)
			self:SetXUITextText(self.mItemName,self._propName)
		end
		local str = ccClientText(10205)
		num = gModelItem:GetNumByRefId(refId)
		str = string.replace(str,num)
		self:SetXUITextText(self.mItemValue,str)
		if self._propDescribe then
			self:SetXUITextText(self.mDescribeText,self._propDescribe)
		end
	end
end

--刷新Slider
function UISyeProp:UpdateSliderValue(updata)
	if self._sliderComponent then
		if updata then
			-- self._sliderComponent.value = self._propUseCount / self._propCount
			self._sliderComponent.value = self._propUseCount
		end
		local useMoreTxt = self._useMoreTxt
		if not string.isempty(useMoreTxt) then
			local str = string.replace(useMoreTxt,self._propUseCount)

			--if self._ref and self._ref.type==158 then
			--	local typeDate = string.split(self._ref.typeDate,"=")
			--	local useNum = tonumber(typeDate[3])
			--
			--
			--	local num = math.floor(self._propUseCount/useNum)
			--	str = self._propUseCount
			--end
			--
			if self._ref and self._ref.btn == "1017" then
				local itemRewardList = self:GetItemRewardList()
				local typeDate = string.split(self._ref.typeDate,"=")
				local rewardRefId = tonumber(typeDate[1])
				local rewardTime = tonumber(typeDate[2])

				local baseNum = 1
				local battleNode = gModelInstance:GetBattleNode(1)
				if battleNode then
					if LOG_INFO_ENABLED then
						printInfoNR("当前关卡 ： " .. battleNode)
					end
					local instanceMissionRef = gModelInstance:GetMissionCfg(battleNode)
					if instanceMissionRef then
						local itemReward = instanceMissionRef.itemReward
						if not string.isempty(itemReward) then
							local itemList = LUtil.ConvertCommonItemStrToList(itemReward)
							for i,v in ipairs(itemList) do
								if v.itemId == rewardRefId then
									baseNum = v.itemNum
									if LOG_INFO_ENABLED then
										printInfoNR("基础道具奖励 ： " .. baseNum)
									end
									break
								end
							end
						end
					end
				end

				local rewardNum = baseNum
				local _rewardOneNum = rewardNum * rewardTime
				local getNum = math.floor(_rewardOneNum) * self._propUseCount
				if LOG_INFO_ENABLED then
					printInfoNR("rewardRefId = " .. rewardRefId .. ",单个道具奖励 ： " .. _rewardOneNum .. "，总道具奖励 ： " .. getNum)
				end
				str = string.replace(useMoreTxt,LUtil.NumberCoversion(getNum))
			end
			self:SetWndText(self.mMoreTxt,str)
		end
		self:SetValueNum()
	end
	self._isUpdate = true
end

function UISyeProp:RefreshSlider()
	local minValue = 1
	local propCount = tonumber(self._propCount)
	if propCount/10 < 1 then
		minValue = 0
	end
	self._sliderComponent.minValue = minValue
	self._sliderComponent.maxValue = self._propCount
end

function UISyeProp:InitEvent()
	self:SetWndClick(self.mPlus, function()
		self:PlusPropValue()
	end)

	self:SetWndClick(self.mReduce, function()
		self:ReducePropValue()
	end)

	self:SetWndClick(self.mCancel, function()
		self:Exit()
	end,LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mMask,function() self:Exit() end,LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mDetermine, function()
		self:UseProp()
	end)

	self:SetWndClick(self.mBtnClose, function()
		self:Exit()
	end,LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mValueBg,function()
		local tab = {}
		tab.inputTran = self.mInputBgObj.transform
		--tab[2] = self._propID
		tab.minNum = 0
		tab.maxNum = gModelItem:GetNumByRefId(self._propID)
		tab.defaultNum = tonumber(self.mValue.text)
		tab.inputFunc = function(numStr,cmd)
			if self:IsWndClosed() then
				return
			end
			local num = tonumber(numStr)
			if num then
				if cmd == "C" then
					self:SetValueNum(0)
				elseif cmd == "D" then
					local temp = num
					if self._needNum then
						temp = math.floor(num / self._needNum)
						if temp == 0 then temp = 1 end
					end
					self._propUseCount = temp
					self:UpdateSliderValue(true)
				else
					self:SetXUITextText(self.mValue,num)
				end
				print("拥有数量,使用数量,输入数量 = ",self._propCount,self._propUseCount,num)
			end
		end
		GF.OpenWndUp("UINuoardUI",tab)
	end)
end

function UISyeProp:GetItemRewardList()
	local itemRewardList = self._itemRewardList
	if not itemRewardList then
		itemRewardList = {}
		local CurMissionCfg = gModelInstance:GetCurMissionCfg()
		if CurMissionCfg then
			local itemReward = string.split(CurMissionCfg.itemReward,",")
			for i,v in ipairs(itemReward) do
				v = string.split(v,"=")
				local tRefId,tNum = tonumber(v[2]),tonumber(v[3])
				itemRewardList[tRefId] = tNum
			end
		end
		self._itemRewardList = itemRewardList
	end
	return itemRewardList
end

--增加物品数量
function UISyeProp:PlusPropValue()
	local useNum,allNum  = tonumber(self._propUseCount),tonumber(self._propCount)
	if useNum < allNum then
		self._propUseCount = self._propUseCount + 1
		self._isUpdate = false
		self:UpdateSliderValue(true)
	end
end

--减少物品数量
function UISyeProp:ReducePropValue()
	local curNum = self._propUseCount - 1
	if curNum > 0 then
		self._propUseCount = self._propUseCount - 1
		self._isUpdate = false
		self:UpdateSliderValue(true)
	end
end
function UISyeProp:DOItemUseReq(usePropCount,propID)
	local info = {}
	table.insert(info,{refId = propID,num = usePropCount}) --向服务器发送物品使用请求
	gModelItem:OnItemUseReq(info)

	if self._itype == ModelItem.Item_DEBRIS then
		FireEvent(EventNames.ON_ITEM_DEBRIS_USE)
	end
end

--使用道具
function UISyeProp:UseProp()
	if self._callFunc then
		local usePropCount = tonumber(self._propUseCount)
		self._callFunc(usePropCount)
		self:WndClose()
		return
	end
	local value = self:IsCanUse()
	if value then
		self._func = nil
		self:WndClose()
	else
		if self._heroBagFull then
			GF.ShowMessage(ccClientText(10061))
		else
			print("当前使用物品ID为：" .. tostring(self._propID))
			GF.ShowMessage("需要" .. tostring(self._needCount) .. "份材料才能合成")
		end
	end
end
------------------------------------------------------------------
return UISyeProp


