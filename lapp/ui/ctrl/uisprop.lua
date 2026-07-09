---
--- Created by Administrator.
--- DateTime: 2023/10/22 20:45:04
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISProp:LWnd
local UISProp = LxWndClass("UISProp", LWnd)
local UnityEngine = UnityEngine
local typeof = typeof
local typeUISlider = typeof(UnityEngine.UI.Slider)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISProp:UISProp()
	---@type CommonIcon
	self._commonIconItem = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISProp:OnWndClose()
	if self._commonIconItem then
		self._commonIconItem:Destroy()
		self._commonIconItem = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISProp:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISProp:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndText(self.mLblBiaoti,ccClientText(10221))
	self:SetWndText(self.mItemOneSellTxt,ccClientText(10222))
	self:SetWndText(self.mAllTxt,ccClientText(10223))
	local text = CS.FindTrans(self.mTextTitle,"UIText")
	self:SetWndText(text,ccClientText(10224))
	self:SetWndButtonText(self.mCancelBtn,ccClientText(10101))
	self:SetWndButtonText(self.mEnterBtn,ccClientText(10102))
	self:InitEvent()
	self:InitMsg()
	self:InitData()
end

--刷新Slider
function UISProp:UpdateSliderValue(updata)
	if self._sliderComponent then
		if updata then
			self._sliderComponent.value = self._sellItemNum
		end
		self:SetValueNum()
	end
	self._isUpdate = true
end

function UISProp:SetValueNum(limit)
	local num = self._sellItemNum
	if limit then num = limit end
	self:SetWndText(self.mValue ,num)

--[[	local pay = self._sellPayNum * self._sellItemNum
	pay = LUtil.NumberCoversion(pay)
	self:SetWndText(self.mSellNumTxt,pay)]]

	self:CreateOneSellList("sellList",self.mSellItemList)
end

function UISProp:SubEvent()
	local curNum = self._sellItemNum - 1
	if curNum > 0 then
		self._sellItemNum = self._sellItemNum - 1
		self._isUpdate = false
		self:UpdateSliderValue(true)
	end
end

function UISProp:UpdatePropValue(sliderValue,updata)
	if self._isUpdate then
		if not sliderValue then return end
		if self._haveNum == 1 or self._haveNum == "1" then
			sliderValue = 1
			updata = true
		end
		if sliderValue == 0 then
			sliderValue = 1/self._haveNum
		end
		local curPropCount = sliderValue
		self._sellItemNum = math.ceil(curPropCount)
		self:UpdateSliderValue(updata)
	end
end

function UISProp:AddEvent()
	local useNum,allNum  = tonumber(self._sellItemNum),tonumber(self._haveNum)
	if useNum < allNum then
		self._sellItemNum = self._sellItemNum + 1
		self._isUpdate = false
		self:UpdateSliderValue(true)
	end
end

function UISProp:OnDrawSellItem(list,item, itemdata, itempos)
	local SellIconTrans = self:FindWndTrans(item,"SellIcon")
	if SellIconTrans then
		local iconImg = gModelItem:GetItemIconByRefId(itemdata.itemId)
		self:SetWndEasyImage(SellIconTrans,iconImg,function()
			CS.ShowObject(SellIconTrans,true)
		end)
	end
	local SellValueTrans = self:FindWndTrans(item,"SellValue")
	if SellValueTrans then
		local num = LUtil.NumberCoversion(itemdata.itemNum)
		self:SetWndText(SellValueTrans,num)
	end
end

function UISProp:InitSlider()
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

function UISProp:RefreshSlider()
	local minValue = 1
	local propCount = self._haveNum
	if propCount / 10 < 1 then
		minValue = 0
	end
	self._sliderComponent.minValue = minValue
	self._sliderComponent.maxValue = self._haveNum
end

function UISProp:SendMsg()
	if self._sendMsg then return end
	self._sendMsg = true
	local data = {}
	local itype,refId,num,sellType = self._type,self._refId,self._sellItemNum,1
	-- 【G公共支持】删除伙伴晶石功能相关数据
	-- if(itype == ModelItem.ITEM_CRYSTAL_DRAWING)then
	-- 	refId = self._ref.refId
	-- 	sellType = 7
	-- end
	if itype == 3 then
		sellType = 3
	end
	table.insert(data,{itype = sellType,refId = refId,num = num})
	gModelGeneral:OnSellGoodsReq(data)
	-- 【G公共支持】删除伙伴晶石功能相关数据
	-- local itemRef = gModelItem:GetRefByRefId(refId)
	-- if(itemRef and (itemRef.type == ModelItem.ITEM_WISH_MATCH or itemRef.type == ModelItem.ITEM_CRYSTAL_DRAWING))then
	-- 	data[1].id = self._id
	-- end

end

function UISProp:InitMsg()
	self:WndNetMsgRecv(LProtoIds.SellGoodsResp, function()
		GF.ShowMessage(ccClientText(10225))
		self:WndClose()
	end)
end

function UISProp:Refresh()
	local ref = self._ref
	if ref then
		-- UICommon
		--ModelItem.ITEM_CRYSTAL_DRAWING
		local itype,refId = self._type,self._refId
		local baseClass = self._commonIconItem
		if not baseClass then
			baseClass = CommonIcon:New()
			self._commonIconItem = baseClass
			baseClass:Create(CS.FindTrans(self.mCommonUI,"Icon"))
		end
		-- if(itype == ModelItem.ITEM_CRYSTAL_DRAWING)then
		-- 	itype = LItemTypeConst.ICON_TYPE_CRYSTAL_DRAWING
		-- end
		baseClass:SetCommonReward(itype,refId, 1)
		baseClass:EnableShowNum(false)
		baseClass:DoApply()

		-- 名字
		--local name = ccLngText(ref.name)
		local nameStr, des
		if itype == LItemTypeConst.TYPE_EQUIP then
			nameStr = ref.name
			des = ref.des
		else
			nameStr = gModelGeneral:GetCommonItemColorNameNoNum({itemId = ref.refId,itemType = LItemTypeConst.TYPE_ITEM})
			des = ref.description
		end
		self:SetWndText(self.mItemName,nameStr)
		self:SetWndText(self.mDesText,ccLngText(des))
		-- 数量
		local str = string.replace(ccClientText(10205),self._haveNum)
		self:SetWndText(self.mItemValue,str)

--[[		-- 出售单价
		local sell = ref.sell
		sell = string.split(sell,"=")
		local itemType,itemRefId,itemNum = tonumber(sell[1]),tonumber(sell[2]),tonumber(sell[3])
		self._sellPayNum = itemNum 						-- 出售花费
		local payStr = LUtil.NumberCoversion(itemNum)
		self:SetWndText(self.mItemOneSellValue,payStr)

		local iconImg
		if itemType == 1 then
			iconImg = gModelItem:GetItemIconByRefId(itemRefId)
		end
		if iconImg then
			-- 顶部出售价格的图标
			self:SetWndEasyImage(self.mOneSellIcon,iconImg,function()
				CS.ShowObject(self.mOneSellIcon,true)
			end)

			-- 总价出售价格的图标
			self:SetWndEasyImage(self.mSellIcon,iconImg,function()
				CS.ShowObject(self.mSellIcon,true)
			end)
		end]]

		local sellItemList = {}
		local sell = string.split(ref.sell,",")
		for i,v in ipairs(sell) do
			v = string.split(v,"=")
			table.insert(sellItemList,{
				itemType = tonumber(v[1]),
				itemId = tonumber(v[2]),
				itemNum = tonumber(v[3]),
			})
		end
		self._sellItemList = sellItemList

		self:CreateOneSellList("topSellList",self.mTSellItemList)

		self:CreateOneSellList("sellList",self.mSellItemList)


		self:InitSlider()
		self:SetValueNum()
	end
end

function UISProp:InputEvent()
	local tab = {}
	tab.inputTran = self.mInputBg
	tab.minNum = 0
	tab.maxNum = self._haveNum
	tab.defaultNum = self._sellItemNum
	tab.inputFunc = function(numStr,cmd)
		if self:IsWndClosed() then return end
		local num = tonumber(numStr)
		if num then
			if cmd == "C" then
				self:SetValueNum(0)
			elseif cmd == "D" then
				local temp = num
				self._sellItemNum = temp
				self:UpdateSliderValue(true)
			else
				self:SetWndText(self.mValue,num)
			end
			print("拥有数量,使用数量,输入数量 = ",self._haveNum,self._sellItemNum,num)
		end
	end
	GF.OpenWndUp("UINuoardUI",tab)
end

function UISProp:CreateOneSellList(key,trans)
	local list = {}
	if key == "topSellList" then
		list = self._sellItemList
	else
		for i,v in ipairs(self._sellItemList) do
			table.insert(list,{
				itemType = v.itemType,
				itemId = v.itemId,
				itemNum = v.itemNum * self._sellItemNum,
			})
		end
	end
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshData(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(trans,list,function(...) self:OnDrawSellItem(...) end)
	end
end

function UISProp:InitData()
	local itype = self:GetWndArg("itype")
	local refId = self:GetWndArg("refId")
	local id = self:GetWndArg("id")
	local isUsing = self:GetWndArg("isUsing")
	self._type = itype
	self._refId = refId
	self._id = id
	local ref
	local haveNum = 0
	if itype == 1 then
		ref = gModelItem:GetRefByRefId(refId)
		haveNum = gModelItem:GetNumByRefId(refId)
	elseif itype == 3 then
		ref = gModelEquip:GetEquipRefByRefId(refId)
		haveNum = gModelEquip:GetEquipStructByRefId(refId):GetNum()
	--【G公共支持】删除伙伴晶石功能相关数据
	-- elseif itype == ModelItem.ITEM_CRYSTAL_DRAWING then
	-- 	local drawingRef = gModelCrystalShard:GetCrystalCfgByType(ModelCrystalShard.CrystalDrawingRef)
	-- 	local dRef =  drawingRef[refId]
	-- 	ref = gModelItem:GetRefByRefId(tonumber(dRef.itemRefId))
	-- 	haveNum = 1
	-- 	if(not isUsing)then
	-- 		local pbDataList = gModelCrystalShard:GetPbBagData()
	-- 		local drawList = gModelCrystalShard:GetShardDataListByType(pbDataList, 1, 1,true)
	-- 		for i, v in pairs(drawList) do
	-- 			if(not v.usingHero and v.refId == refId )then
	-- 				haveNum = v.num
	-- 			end
	-- 		end
	-- 	end
	else
		printInfoNR("========== 暂无配置，请添加")
	end
	if(self._id and ref.type == 144)then
		haveNum = 1
	end
	self._isUpdate = true						-- 刷新的优先级
	self._ref = ref								-- 表格数据
	self._haveNum = haveNum 					-- 拥有数量
	self._sellItemNum = haveNum 				-- 默认全部出售
	self._sendMsg = false						-- 发送事件

	self:Refresh()
	self:UpdatePropValue(self._sellItemNum,true)
end

function UISProp:InitEvent()
	self:SetWndClick(self.mMask,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCancelBtn,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mEnterBtn,function()
		self:SendMsg()
	end)
	self:SetWndClick(self.mAddBtn,function()
		self:AddEvent()
	end)
	self:SetWndClick(self.mSubBtn,function()
		self:SubEvent()
	end)
	self:SetWndClick(self.mValueBg,function()
		self:InputEvent()
	end)
end
------------------------------------------------------------------
return UISProp


