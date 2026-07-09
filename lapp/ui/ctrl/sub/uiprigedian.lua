---
--- Created by BY.
--- DateTime: 2023/10/13 14:22:05
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UIPrigeDian:LChildWnd
local UIPrigeDian = LxWndClass("UIPrigeDian", LChildWnd)

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPrigeDian:UIPrigeDian()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPrigeDian:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPrigeDian:OnCreate()
	LChildWnd.OnCreate(self)
	self._uiCommonList = {}
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPrigeDian:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitMsg()
	gModelNormalActivity:OnPrivilegeGiftReq()
end

function UIPrigeDian:OnDrawBuyBtnFunc(dataList)
	local btnCount = #dataList
	for i = 1, 3 do
		local item = self.mPayBtnList
		local str = "Btn"..i
		local Btn = CS.FindTrans(item,str)
		local itemdata = dataList[i]

		if i <= btnCount then
			local BtnImage = CS.FindTrans(Btn,"BtnImage")
			local Title = CS.FindTrans(Btn,"Title")

			local giftRef = gModelNormalActivity:GetBIActivityPrivilegeDataRefByRefId(itemdata.refId)
			local btnText = ccLngText(giftRef.btnText)
			local btnPng = giftRef.btnPng
			local titleText = ccLngText(giftRef.moreText)
			local expend = giftRef.expend
			local strList = string.split(expend,"=") or {}
			local isUseItemBuy = #strList > 1
			local refid = giftRef.type
			local giftRef = gModelNormalActivity:GetBIActivityPrivilegeGiftRefByRefId(refid)
			local isGray = itemdata.remainTime <= 0
			local textPos = self._btnTextPos.common
			if isUseItemBuy then
				local strNum = tonumber(btnText)
				if strNum < 1000 then	-- 小于4位数
					textPos = self._btnTextPos.showIcon1
				else					-- 大于4位数
					textPos = self._btnTextPos.showIcon2
				end
			end

			self:SetWndButtonText(Btn, btnText, textPos)
			CS.ShowObject(BtnImage,isUseItemBuy)
			--self:SetWndButtonImg(Btn,btnPng)
			self:SetWndButtonGray(Btn, isGray)

			if titleText and not string.isempty(titleText) then
				self:SetWndText(Title,titleText)
				CS.ShowObject(Title,true)
			else
				CS.ShowObject(Title,false)
			end

			if isUseItemBuy then
				self:SetWndImageGray(BtnImage,isGray)
			end

			if not isGray then
				-- 购买按钮
				self:SetWndClick(Btn,function()
					if isUseItemBuy then
						local dia = gModelItem:GetNumByRefId(102001)
						local value = tonumber(strList[3])
						-- 钻石购买
						local func = function()
							if dia >= value then
								gModelNormalActivity:OnBuyPrivilegeGiftReq(itemdata.refId)
							else
								gModelGeneral:OpenGetWayWnd({itemId = 102001})
							end
						end
						GF.OpenWnd("UIOrdinTip",{refId = 110002,func = func,para = {value,ccLngText(giftRef.name)}})
					else
						-- 付费购买
						gModelPay:GiftPayCtrl(itemdata.refId,tonumber(expend),ModelPay.PAY_TYPE_GIFT,ModelPay.PAY_GIFT_PRIVILEGE)
					end
				end)
			else
				self:SetWndClick(Btn,function()
					GF.ShowMessage(ccClientText(14207))
				end)
			end

			CS.ShowObject(Btn,true)
		else
			CS.ShowObject(Btn,false)
		end
	end

end

function UIPrigeDian:IsBuy(refId)
	local dataList = self:GetGiftData(refId)
	-- 剩余购买次数,-1=无限次
	local isBuy = true
	for i, v in ipairs(dataList) do
		if v.remainTime and v.remainTime > 0 then
			isBuy = false
		end
	end
	return isBuy
end

-- 根据礼包ID去获取服务器下发的对应礼包数据ID
function UIPrigeDian:GetGiftData(refid)
	local giftDataList = {}
	for i, v in ipairs(self._privilegeGiftList) do
		local ref = gModelNormalActivity:GetBIActivityPrivilegeDataRefByRefId(v.refId)
		local type = ref.type
		if(type == refid)then
			table.insert(giftDataList,v)
		end
	end
	return giftDataList
end

-- 显示礼包内容
function UIPrigeDian:OnClickGiftBtn(index,refId,itemdata,clickEffTrans)
	if self._curBtnIndex then
		local trans = self._PayBtnList[self._curBtnIndex]
		local isClick = CS.FindTrans(trans,"IsClick")
		CS.ShowObject(isClick,false)
	end
	self._curBtnIndex = index
	CS.ShowObject(clickEffTrans,true)
	self:OnPrivilegeBtnClick(itemdata)
end

function UIPrigeDian:InitMsg()
	-- 礼包数据
	self:WndNetMsgRecv(LProtoIds.PrivilegeGiftResp, function(...)
		self:Reset()
	end)
end

function UIPrigeDian:OnDrawTextFunc(list,item,itemdata,itempos)
	local DescriptionImage = CS.FindTrans(item,"DescriptionImage")
	local DescriptionText = CS.FindTrans(DescriptionImage,"DescriptionText")
	self:SetWndText(DescriptionText,itemdata)
	CS.ShowObject(DescriptionImage,true)
end

function UIPrigeDian:InitEvent()

end

function UIPrigeDian:InitData()

	-- 跳转过来打开的礼包项
	self._openGiftRefid = self:GetWndArg("index")

	-- 特权列表
	self._PrivilegeList = {}

	-- 特权描述列表
	self._PrivilegeDescriptionList = {}

	-- 特权购买列表
	self._PayBtnList = {}

	-- 当前按钮
	self._curBtnIndex = nil

	-- 上一个按钮
	self._lastBtnIndex = nil

	-- 当前礼包的数据表ID
	self._lastGiftRefID = nil

	self._buyTypeText = {
		[-1] = ccClientText(14205), -- 永久限购
		[1] = ccClientText(14204), -- 每日限购
		[7] = ccClientText(14202), -- 每周限购
		[30] = ccClientText(14203), -- 每月限购
	}

	local itemFunc = function(refId,num) gModelGeneral:OpenItemInfoTip(refId,num) end
	local heroFunc = function() end
	local equipFunc = function(refId) gModelGeneral:OpenEquipInfoTip(refId,nil,1,true) end
	self._funcList = {
		[1] = itemFunc,
		[2] = heroFunc,
		[3] = equipFunc,
	}
	self._isSort = true

	self._btnTextPos = {
		common = Vector3.zero,
		showIcon1 = Vector3.New(7,0,0),
		showIcon2 = Vector3.New(22,0,0),
	}
end

function UIPrigeDian:InitPrivilegeList()
	local jumpPara = self:GetWndArg(1) --跳转参数
	if(not self._centerPos)then
		self._centerPos = 1
	end
	local dataList = gModelNormalActivity:GetBIActivityPrivilegeGiftRef()
	table.sort(dataList , function(a , b)
		--if(self._isSort)then
		--	if(a.isBuy ~= b.isBuy)then
		--		return a.isBuy < b.isBuy
		--	end
		--end
		return a.sort < b.sort
	end)
	for i, v in ipairs(dataList) do
		local isBuy = self:IsBuy(v.refId) and 1 or 0
		v.isBuy = isBuy
		v.index = i
		if(i~=1 and isBuy == 0 and self._isSort)then
			self._centerPos = 2
		end
	end

	if jumpPara then
		self._centerPos = jumpPara
	end


	self._isSort = false
	if(#dataList <= 3)then
		if(self._privilegeList)then
			self._privilegeList:RefreshList(dataList)
		elseif(#dataList <= 3)then
			CS.ShowObject(self.mLeft,false)
			CS.ShowObject(self.mRight,false)
			self._privilegeList = self:GetUIScroll("privilegeList")
			self._privilegeList:Create(self.mPrivilegeList,dataList,function (...) self:OnDrawPrivilegeFunc(...) end)

		end
	else
		CS.ShowObject(self.mLeft,true)
		CS.ShowObject(self.mRight,true)
		self._privilegeList = self:GetUIScroll("privilegeList")
		self._privilegeList:InitListData({
			root = self.mPrivilegeList,
			dataList = dataList,
			setFunc = function (...) self:OnDrawPrivilegeFunc(...) end,
			type = UIItemList.CIRCLE,
			onCenterFunc = function (...) self:OnItemCenter(...) end,
			centerPos = self._centerPos
		})
		local uilist= self._privilegeList:GetList()
		self:SetWndClick(self.mLeft, function(...)
			uilist:MoveOneStep(false)
		end)
		self:SetWndClick(self.mRight, function(...)
			uilist:MoveOneStep(true)
		end)
	end
end

function UIPrigeDian:OnPrivilegeBtnClick(itemdata)
	local dataList = self:GetGiftData(itemdata.refId)
	local giftRef = itemdata
	local ruleContent = giftRef.rule
	local description1 = ccLngText(giftRef.description1)
	description1 = string.split(description1,"=") or {}
	ruleContent = ruleContent and tonumber(ruleContent) or ""
	self:AwardListItem(itemdata)
	-- 查看特权规则
	if ruleContent and not string.isempty(ruleContent) and ruleContent > 0 then
		local uiHyperText = UIHyperText:New()
		uiHyperText:Create(self.mLookRuleText)
		local str = ccClientText(14201)
		str = uiHyperText:AddHyper(str,{func = function()
			GF.OpenWnd("UIBzTips",{refId = ruleContent})
		end})
		self:SetWndText(self.mLookRuleText,str)

		CS.ShowObject(self.mLookRuleText,true)
	else
		CS.ShowObject(self.mLookRuleText,false)
	end
	-- 购买按钮
	self:OnDrawBuyBtnFunc(dataList)
	-- 礼包描述
	if(self._desList)then
		self._desList:RefreshList(description1)
	else
		self._desList = self:GetUIScroll("desList")
		self._desList:Create(self.mDescription1List,description1,function (...) self:OnDrawTextFunc(...) end)
	end
end

function UIPrigeDian:OnDrawPrivilegeFunc(list,item,itemdata,itempos,isBool)
	local dataList = self:GetGiftData(itemdata.refId)

	-- 特权商城数据表refId，相同类型只取一个
	--if(not dataList[1])then
	--	return
	--end
	local refId = dataList[1].refId

	-- 结束时间，单位秒,-1=永久
	local endTime = 0
	local curTime = GetTimestamp()
	for i, v in ipairs(dataList) do
		local time = tonumber(v.endTime)
		if time > 0 then
			--time = time / 1000
			time = time - curTime
			endTime = endTime + time
		end
	end

	-- 是否有剩余购买次数
	local isBuy = self:IsBuy(itemdata.refId)

	local giftDataRef = gModelNormalActivity:GetBIActivityPrivilegeDataRefByRefId(refId)
	local giftRef = itemdata
	local buyType = self._buyTypeText[giftDataRef.time]

	local privilege = self:FindWndTrans(item,"Privilege")
	local IsClick = self:FindWndTrans(privilege,"IsClick")

	local PrivilegeNameImage = self:FindWndTrans(privilege,"PrivilegeNameImage")
	local Description2 = self:FindWndTrans(PrivilegeNameImage,"Description2")

	local DownCountTime = self:FindWndTrans(privilege,"DownCountTime")
	local BuyType = self:FindWndTrans(privilege,"BuyType")

	local PrivilegeIcon = self:FindWndTrans(privilege,"PrivilegeIcon")
	local SoldOut = self:FindWndTrans(PrivilegeIcon,"SoldOut")

	local btnList = self._PayBtnList
	local index = tonumber(itemdata.index)
	if privilege then
		btnList[index] = privilege
	end

	self:SetWndEasyImage(PrivilegeNameImage,giftRef.namePng or "")
	self:SetWndEasyImage(PrivilegeIcon,giftRef.signPng or "",nil, true)
	self:SetWndText(Description2,ccLngText(giftRef.description2))

	if endTime and endTime > 0 then
		local str = LUtil.FormatTimespanToMin(endTime)
		self:SetWndText(DownCountTime,str)
		CS.ShowObject(DownCountTime,true)
	else
		CS.ShowObject(DownCountTime,false)
	end
	-- 只要有购买次数，即为未售罄
	CS.ShowObject(SoldOut,isBuy)

	if buyType then
		self:SetWndText(BuyType,buyType)
		CS.ShowObject(BuyType,true)
	else
		CS.ShowObject(BuyType,false)
	end
	CS.ShowObject(IsClick,false)
	CS.ShowObject(privilege,true)
	self:SetWndClick(item,function()
		self:OnClickGiftBtn(index,refId,itemdata,IsClick)
	end)
	-- 默认显示第一个礼包内容
	if self._openGiftRefid and self._openGiftRefid == index then
		self._openGiftRefid = nil
		self:OnClickGiftBtn(index,refId,itemdata,IsClick)
	elseif self._curBtnIndex then
		if self._curBtnIndex == index then
			self:OnClickGiftBtn(index,refId,itemdata,IsClick)
		end
	elseif not self._openGiftRefid and index == 1 then
		self:OnClickGiftBtn(index,refId,itemdata,IsClick)
	end
	if(isBool)then
		self:OnClickGiftBtn(index,refId,itemdata,IsClick)
	end
end

function UIPrigeDian:OnItemCenter( item, itemdata, itempos)
	self:OnDrawPrivilegeFunc(self._privilegeList:GetList(),item,itemdata,itempos,true)
	self._centerPos = itempos
end

function UIPrigeDian:AwardListItem(info)--礼包物品
	local itemList = LxDataHelper.ParseItem(info.showReward)
	local tabLis = string.split(info.descriptionIcon,"=") or {}
	if(not self._ItemTransList)then
		self._ItemTransList = {}
		for i = 1, 4 do
			local item = CS.FindTrans(self.mItemList,"Item" .. i)
			self._ItemTransList[i] = item
		end
	end
	local len = #itemList
	for i = len, 4 do
		local item = self._ItemTransList[i]
		CS.ShowObject(item,false)
	end
	for i, v in ipairs(itemList) do
		local item = self._ItemTransList[i]
		local itemdata = v
		local tabIndex = tabLis[i] or 0
		CS.ShowObject(item,true)
		local root = CS.FindTrans(item,"Root/Icon")
		local tab = CS.FindTrans(item,"Root/Tab")

		local formatData = {
			itemId = itemdata.itemId,
			itemType = itemdata.itemType,
			itemNum = itemdata.itemNum,
		}
		local uiCommonList = self._uiCommonList
		local InstanceID = item:GetInstanceID()
		local baseClass = uiCommonList[InstanceID]
		if not baseClass then
			baseClass = CommonIcon:New()
			uiCommonList[InstanceID] = baseClass
			baseClass:Create(root)
		end
		baseClass:SetCommonReward(formatData.itemType, formatData.itemId, formatData.itemNum)
		baseClass:DoApply()
		self:SetIconClickScale(root, true)
		self:SetWndClick(root, function() gModelGeneral:ShowCommonItemTipWnd(formatData) end)
		--self:SetWndText(numText, LUtil.NumberCoversion(itemdata.itemNum))
		CS.ShowObject(tab,tabIndex ~= "0")
		local tabStr
		if(tabIndex == "1")then
			tabStr = "privilegeshop_txt_5"
		elseif(tabIndex == "2")then
			tabStr = "privilegeshop_txt_6"
		end
		self:SetWndEasyImage(tab,tabStr)
	end
end

function UIPrigeDian:Reset()
	self._privilegeGiftList = gModelNormalActivity:GetPrivilegeGiftList()

	self:InitPrivilegeList()
end
------------------------------------------------------------------
return UIPrigeDian