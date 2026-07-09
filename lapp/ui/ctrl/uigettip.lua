---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGetTip:LWnd
local UIGetTip = LxWndClass("UIGetTip", LWnd)

UIGetTip.SELECTTYPE_NOT = 0
UIGetTip.SELECTTYPE_HERO = 1

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGetTip:UIGetTip()
	---@type CommonIcon
	self._itemIconCls = nil
	---@type table<number,CommonIcon>
	self._uiCommonIconList = {}
	---@type UIItemList
	self._uiList = nil -- 仅仅是从基类获取的引用， 不需要destroy
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
-----------------------------------------------------------------
function UIGetTip:OnWndClose()
	self._uiList = nil

	if not self._sendMsg then
		gModelGeneral:ShowCommonItemTipWnd({itemType = self._itemType, itemId = self._refId})
	end
	if self._itemIconCls then
		self._itemIconCls:Destroy()
		self._itemIconCls = nil
	end
	if self._uiCommonIconList then
		self:ClearCommonIconList(self._uiCommonIconList)
		self._uiCommonIconList = nil
	end

	--print("UIGetTip:OnWndClose()")

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGetTip:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGetTip:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEmptyList()
	self:InitData()
	self:InitText()
	self:ShowSelDiv()
	self:InitEvent()
	self:InitMsg()
	self:InitScrollView()
end

function UIGetTip:OnDrawHeroCell(list, item, itemdata, itempos, fromHeadTail)
	local uiTrans = CS.FindTrans(item,"CommonUI")
	local refId = itemdata.id
	local num = itemdata.num
	local InstanceID = item:GetInstanceID()
	if uiTrans then
		local iconTrans = CS.FindTrans(uiTrans, "Icon")
		local uiCommonIconList = self._uiCommonIconList
		local baseClass = uiCommonIconList[InstanceID]
		if not baseClass then
			baseClass = CommonIcon:New()
			uiCommonIconList[InstanceID] = baseClass
			baseClass:Create(iconTrans)
		end
		baseClass:SetCommonReward(LItemTypeConst.TYPE_HERO, refId, num)
		baseClass:DoApply()

		self:SetIconClickScale(uiTrans, true)
		self:SetWndClick(uiTrans,function()
			local optNum = -1
			if self._selHeroIdList[refId] == nil then optNum = 1 end
			self._selHeroFunc(refId,baseClass:GetHeroGouImg(),optNum,baseClass)
		end)

		local uiNameTrans = CS.FindTrans(uiTrans, "UIName")
		local uiNameText = uiNameTrans and self:FindWndText(uiNameTrans) or nil
		if uiNameText and not gLGameLanguage:IsForeignRegion() then
			local itemname,itemcolor = baseClass:GetName()
			self:SetXUITextText(uiNameText, itemname or "")
			if itemcolor then
				self:SetXUITextColor(uiNameText, itemcolor)
			end
		end
	end
end

-- 物品的refId
function UIGetTip:SetRefId(refId)
	self._refId = refId
end

function UIGetTip:OnDrawChooseCell(list, item, itemdata, itempos, fromHeadTail)
	local uiTrans = CS.FindTrans(item,"CommonUI")
	local refId = tonumber(itemdata.refId)
	local num = itemdata.num
	local itype = itemdata.itype
	local heroOnlyShowData = itemdata.heroOnlyShowData
	local selItemRefIdList = self._selItemRefIdList
	if not selItemRefIdList then
		selItemRefIdList = {}
		self._selItemRefIdList = selItemRefIdList
	end
	local InstanceID = item:GetInstanceID()
	if uiTrans then
		local iconTrans = CS.FindTrans(uiTrans, "Icon")
		local uiCommonIconList = self._uiCommonIconList
		local baseClass = uiCommonIconList[InstanceID]
		if not baseClass then
			baseClass = CommonIcon:New()
			uiCommonIconList[InstanceID] = baseClass
			baseClass:Create(iconTrans)
		end



		if not heroOnlyShowData then
			baseClass:SetCommonReward(itype, refId, num)
		else
			baseClass:SetHeroOnlyShow(heroOnlyShowData)
		end

		baseClass:EnableShowNum(true)
		if itype == LItemTypeConst.TYPE_ITEM then
			baseClass:RefreshActiveShow()
		end
		baseClass:DoApply()

		self:SetIconClickScale(uiTrans, true)
		self:SetWndClick(uiTrans,function()
			if itype == LItemTypeConst.TYPE_HERO then
				gModelGeneral:OpenHeroSimpleTip(refId,true)
			else
				gModelGeneral:ShowCommonItemTipWnd(itemdata)
			end
		end)
	end
	local ItemNameTrans = CS.FindTrans(item,"ItemName")
	if ItemNameTrans and not self._USAForeign then
		local name = ""
		if not self._USAForeign then
			name = gModelGeneral:GetItemName(itemdata.itype,refId)
		end

		self:SetWndText(ItemNameTrans,name)
		self:InitTextSizeWithLanguage(ItemNameTrans, -4)
		self:InitTextLineWithLanguage(ItemNameTrans, -30)
	end
	local SubBtn = CS.FindTrans(item,"SubBtn")
	if SubBtn then
		self:SetWndClick(SubBtn,function()
			self:BtnOptEvent(-1,refId,item)
		end)
		-- 长按
		self:SetWndLongClick(SubBtn,function()
			self:BtnOptEvent(-1,refId,item)
		end,0.2,true)
	end
	local AddBtn = CS.FindTrans(item,"AddBtn")
	if AddBtn then
		local addBtnList = self._addBtnList
		local btn = addBtnList[refId]
		if not btn then
			addBtnList[refId] = AddBtn
			local gray = false
			local selNum = 0
			for k,v in pairs(selItemRefIdList) do
				selNum = selNum + v
			end
			gray = selNum >= tonumber(self._serverNum)
			self:SetWndImageGray(AddBtn,gray)
		end
		self:SetWndClick(AddBtn,function()
			self:BtnOptEvent(1,refId,item)
		end)
		-- 长按
		self:SetWndLongClick(AddBtn,function()
			self:BtnOptEvent(1,refId,item)
		end,0.2,true)
	end
	local inputTxt = CS.FindTrans(item,"NumInput")
	if inputTxt then
		local numTxt = CS.FindTrans(inputTxt,"NumTxt")
		if numTxt then
			local xuiTextList = self._xuiTextList
			local xuiText = xuiTextList[refId]
			local selItemRefId = selItemRefIdList[refId]
			if not selItemRefId then
				selItemRefId = 0
				selItemRefIdList[refId] = selItemRefId
			end
			local oldData = selItemRefId
			if not xuiText then
				xuiText = self:FindWndText(numTxt)
				xuiTextList[refId] = xuiText
			end
			self:SetWndClick(inputTxt,function()
				self:CallNumKeyboard(inputTxt,xuiText,refId,item)
			end)
			local NotSelectImgTrans = CS.FindTrans(item,"NotSelectImg")
			local SelImg = CS.FindTrans(item,"SelImg")
			local showSel = oldData and tonumber(oldData) > 0
			self:SetWndText(numTxt,oldData)
			CS.ShowObject(NotSelectImgTrans,not showSel)
			CS.ShowObject(SelImg,showSel)
		end
	end

	--需要图标的设置
	local NeedTag = self:FindWndTrans(item, "NeedTag")
	if self._itemType == 102 or self._itemType == 103 or self._itemType == 104 then
		local NeedTagText = CS.FindTrans(NeedTag, "UIText")
		self:SetWndText(NeedTagText, ccClientText(45727))
		local candleRefId = itemdata.refId
		local isShow = gModelMagic:CheckCandleIdCanLightMagicCircle(candleRefId)
		CS.ShowObject(NeedTag, isShow)
	else
		CS.ShowObject(NeedTag, false)
	end
end

-- exceed:设置按钮是否置灰,false后检查所有的文字是否超过已拥有数量
function UIGetTip:Examine(exceed,numKey)
	local ShowMessage = false
	if not exceed then
		local allNum = self:GetAllNum()
		local serverNum = tonumber(self._serverNum)
		if allNum >= serverNum then
			exceed = true
			ShowMessage = true
		end
	end
	if not numKey then
		local addBtnList = self._addBtnList
		for i,v in pairs(addBtnList) do
			self:SetWndImageGray(v,exceed)
		end
	end
	if exceed and not ShowMessage then
		GF.ShowMessage(ccClientText(10209))
	end
end

function UIGetTip:SetChooseNumTxt()
	local num = self._chooseNum
	local serNum = self._serverNum
	local msg = string.replace(ccClientText(10232), num, serNum)
	self:SetWndText(self.mChooseNum,msg)
end

function UIGetTip:GetAllNum(refId)
	local allNum = 0
	--[[	local xuiTextList = self._xuiTextList
        for k,v in pairs(xuiTextList) do
            if refId and k ~= refId then
                allNum = allNum + v.text
            elseif refId == nil then
                allNum = allNum + v.text
            end
        end]]
	local _selItemRefIdList = self._selItemRefIdList
	for k,v in pairs(_selItemRefIdList) do
		if refId and k ~= refId then
			allNum = allNum + v
		elseif refId == nil then
			allNum = allNum + v
		end
	end
	return allNum
end
------------------------------------------------------------------
--- 按钮事件
------------------------------------------------------------------
function UIGetTip:InitEvent()
	self:SetWndClick(self.mBg,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCancelBtn,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mEnterBtn,function()
		self:EnterBtnEvent()
	end)
	self:SetWndClick(self.mHelpBtn, function()
		self:BtnHelpEvent()
	end)
	local raceBtnList = self._raceBtnList or {}
	for i,v in ipairs(raceBtnList) do
		self:SetWndClick(v,function()
			self:OnClickRaceType(i)
		end)
	end
	self:SetWndClick(self.mAllRaceBtn,function()
		self:OnClickRaceType(0)
	end)
end

function UIGetTip:CallNumKeyboard(inputTrans,numXuiTrans,refId,item)
	if self._itemType and self._invalidKeyboardList[self._itemType] then return end

	local numTxt = CS.FindTrans(item,"NumInput/NumTxt")
	numXuiTrans = self:FindWndText(numTxt)
	local tab = {}
	tab.inputTran = inputTrans
	tab.minNum = 0
	tab.maxNum = tonumber(self._serverNum)
	tab.defaultNum = numXuiTrans.text
	tab.inputFunc = function(numStr,cmd)

		if self:IsWndClosed() then
			return
		end
		local selItemRefIdList = self._selItemRefIdList
		if not selItemRefIdList then
			selItemRefIdList = {}
			self._selItemRefIdList = selItemRefIdList
		end

		local num = tonumber(numStr)
		if num then
			local NotSelectImgTrans = CS.FindTrans(item,"NotSelectImg")
			local SelImg = CS.FindTrans(item,"SelImg")
			local show
			if cmd == "C" then
				self:SetXUITextText(numXuiTrans,0)
				selItemRefIdList[refId] = 0
				show = false
				self:Examine(false)
			elseif cmd == "D" then
				local allNum = self:GetAllNum(refId)
				local temp = allNum + num
				local serverNum = tonumber(self._serverNum)
				if temp > serverNum then
					local have = serverNum - allNum
					self._chooseNum = self._serverNum
					self:SetXUITextText(numXuiTrans,have)
					selItemRefIdList[refId] = have
				else
					self._chooseNum = temp
					self:SetXUITextText(numXuiTrans,num)
					selItemRefIdList[refId] = num
				end
				if tonumber(numXuiTrans.text) == 0 then
					show = false
				else
					show = true
				end
				self:Examine(false)
			else
				self:SetXUITextText(numXuiTrans,num)
				selItemRefIdList[refId] = num
			end
			if show ~= nil then
				CS.ShowObject(SelImg,show)
				CS.ShowObject(NotSelectImgTrans,not show)
			end
			self:SetChooseNumTxt()
			self._xuiTextList[refId] = numXuiTrans
		end
	end
	GF.OpenWndUp("UINuoardUI",tab)

end

function UIGetTip:InitData()
	self._xuiInputList = {}
	self._xuiTextList = {}
	self._selItemRefIdList = {}
	self._sendMsg = false
	self._selHeroIdList = {}
	self._addBtnList = {}
	self._chooseNum = 0
	self._serverNum = 0
	self._refId = self:GetWndArg("refId")
	self._itype = self:GetWndArg("itemType") 		-- 1是普通道具，2是 星级直达卡/等级直达卡
	self._itemType = nil 							-- 使用该道具的类型，判断是否是 105/106

	self._helpRefIdList = {
		[ModelItem.Item_SELECT_TRY_HERO] = 121,
		[ModelItem.Item_SELECT_TRY_SPIRITHERO] = 121,
	}

	self._addOwnClickCheckList = {
		[ModelItem.Item_SELECT_TRY_HERO] = function(id, refId,curNum) return self:CheckTryHeroAdd(id, refId, curNum) end,
		[ModelItem.Item_SELECT_TRY_SPIRITHERO] = function(id, refId,curNum) return self:CheckTryHeroAdd(id, refId, curNum) end,
	}

	self._invalidKeyboardList = {
		[ModelItem.Item_SELECT_TRY_HERO] = true,
		[ModelItem.Item_SELECT_TRY_SPIRITHERO] = true
	}

	self._isForeign =  gLGameLanguage:IsForeignRegion()
	self._USAForeign = gLGameLanguage:IsUSARegion()

	self._selHeroFunc = function(id,gouTrans,_num,baseClass)
		local newNum = self._chooseNum + _num
		local serverNum = tonumber(self._serverNum)
		if newNum < 0 or newNum > serverNum then
			GF.ShowMessage(ccClientText(10209))
			return
		end
		local selHeroIdList = self._selHeroIdList
		local data = selHeroIdList[id]
		if not data then
			self._chooseNum = self._chooseNum + _num
			CS.ShowObject(gouTrans,true)
			data = id
			selHeroIdList[id] = data
			baseClass:ShowGouImg(true)
		else
			self._chooseNum = self._chooseNum + _num
			CS.ShowObject(gouTrans,false)
			data = nil
			selHeroIdList[id] = data
			baseClass:ShowGouImg(false)
		end
		self:SetChooseNumTxt()
	end
	if not self._itype then
		printInfoN("--- 没有设置对应的类型")
		self._itype = 1
	end
	if self._itype == 1 then
		CS.ShowObject(self.mChooseList,true)
	else
		CS.ShowObject(self.mHeroList,true)
	end
	self._showRaceDiv = UIGetTip.SELECTTYPE_NOT
	local refId = self._refId
	if refId then
		local serverData = gModelItem:GetItemServerDataByRefId(refId)
		if not serverData then return	end
		local num = serverData:GetNum()

		local common = CS.FindTrans(self.mItemInfo,"ItemIcon")
		if common then
			local baseClass = self._itemIconCls
			if not baseClass then
				baseClass = CommonIcon:New()
				self._itemIconCls = baseClass
				baseClass:Create(common)
			end
			baseClass:SetCommonReward(LItemTypeConst.TYPE_ITEM, refId, num)
			baseClass:EnableShowNum(true)
			baseClass:DoApply()
		end

		local ref = gModelItem:GetRefByRefId(refId)
		if ref then
			local quaId = ref.quality
			local color = gModelItem:GetColorByQualityId(quaId)
			if color then
				self:SetXUITextColor(self.mNameTxt,color)
			end
			local name = ccLngText(ref.name)
			self:SetXUITextText(self.mNameTxt,name)
			self._showRaceDiv = ref.selectType or 0

			local itemRefType = ref.type
			CS.ShowObject(self.mHelpBtn, self._helpRefIdList[itemRefType] ~= nil)
			self._itemType = itemRefType
		end
		local str = ccClientText(10205)
		if serverData then
			self._serverNum = num
			str = string.replace(str,num)
		else
			str = string.replace(str,0)
		end
		self:SetXUITextText(self.mNumTxt,str)


	end

	self._showSelDivList = {
		[UIGetTip.SELECTTYPE_HERO] = self.mRaceDiv,
	}

	self._raceBtnList = {
		self.mRaceBtn1,
		self.mRaceBtn2,
		self.mRaceBtn3,
		self.mRaceBtn4,
		self.mRaceBtn5,
	}

	self._raceType = 0

	self._dataList = {}
	self:SetChooseNumTxt()
end

function UIGetTip:GetItemType()
	local ref = gModelItem:GetRefByRefId(self._refId)
	if not ref then
		return nil
	end

	return ref.type
end

function UIGetTip:EnterBtnEvent()
	-- 确定按钮事件
	local chooseNum = tonumber(self._chooseNum)
	local serverNum = tonumber(self._serverNum)
	local itype = self._itype
	if chooseNum > serverNum then
		GF.ShowMessage(ccClientText(10209))
		return
	end

	local hasActiveItem = false
	local heroRef = nil

	local str = ""
	if itype == 1 then
		--[[			--local list = self._xuiTextList
                    --for k,v in pairs(list) do
                    --	local num = tonumber(v.text)
                    --	if num ~= 0 then
                    --		local data = k.."="..num
                    --		if string.isempty(str) then
                    --			str = data
                    --		else
                    --			str = str..","..data
                    --		end
                    --	end
                    --end]]
		local itemType = self:GetItemType()
		local list = self._selItemRefIdList


		for k,v in pairs(list) do
			if v > 0 then
				local data
				if itemType == ModelItem.Item_SELECT_TRY_HERO or itemType == ModelItem.Item_SELECT_TRY_SPIRITHERO  then
					data = tostring(k)
				else
					data = k.."="..v

					if itemType == ModelItem.Item_CHOOSE then
						--local isActive,ref = gModelHero:IsSourceItemActive(k)
						--if isActive then
						--	hasActiveItem = true
						--	heroRef = ref
						--end
					end

				end
				if string.isempty(str) then
					str = data
				else
					str = str..","..data
				end
			end
		end
	else
		local list = self._selHeroIdList
		for k,v in pairs(list) do
			if string.isempty(str) then
				str = tostring(v)
			else
				str = str .. "," .. v
			end
		end
	end
	if string.isempty(str) then
		GF.ShowMessage(ccClientText(10241))
	end

	--print("---- str = ",str)

	local info = {}
	table.insert(info,{refId = self._refId,num = chooseNum,params = str})

	local itemType = self._itemType
	local selHeroIdList = self._selHeroIdList

	local func = function()

		if not self:IsWndValid() then
			return
		end

		if itemType and not table.isempty(selHeroIdList) then
			gModelHero:SelItemUpHeroIdList(selHeroIdList,itemType)
		end

		local isReq = false
		for i, v in ipairs(info) do
			if(v.num and v.num~=0)then
				isReq = true
				break
			end
		end
		if(isReq)then
			gModelItem:OnItemUseReq(info) --向服务器发送物品使用请求
			self._sendMsg = true
			self:WndClose()
		end
	end


	if hasActiveItem then
		local para = {
			refId = 10049,
			func= func,
			para = { gModelHero:GetHeroNameByRefId(heroRef.refId)}
		}

		gModelGeneral:OpenUIOrdinTips(para)
	else

		func()
	end

end

function UIGetTip:InitMsg()
	--self:WndNetMsgRecv(LProtoIds.ItemChangeResp,function()
	--self._sendMsg = true
	--self:WndClose()
	--end)
end

function UIGetTip:CheckTryHeroAdd(id, refId, curNum)
	local newNum = curNum + id
	if newNum > 1 then
		GF.ShowMessage(ccClientText(10090))
		return false
	end

	local haveSame = gModelHero:CheckHaveTryHero(tonumber(refId))
	if haveSame then
		local heroName = gModelHero:GetHeroNameByRefId(refId)
		GF.ShowMessage(string.replace(ccClientText(10089), heroName))
	end

	return not haveSame
end

function UIGetTip:OnClickRaceType(raceType)
	self._raceType = raceType
	self:RefreshScroll()
end
-- id正负决定+-
function UIGetTip:BtnOptEvent(id,refId,item)
	local xuiTextList = self._xuiTextList
	local xuiText = xuiTextList[refId]
	local inputTxt = CS.FindTrans(item,"NumInput")
	local numTxt = CS.FindTrans(inputTxt,"NumTxt")
	xuiText = self:FindWndText(numTxt)
	local curNum = tonumber(xuiText.text)
	if id > 0 and self._itemType then
		local type =self._itemType
		local addOwnCheckFunc = self._addOwnClickCheckList[type]
		if addOwnCheckFunc and not addOwnCheckFunc(id, refId, curNum) then
			return
		end
	end

	local selItemRefIdList = self._selItemRefIdList
	if not selItemRefIdList then
		selItemRefIdList = {}
		self._selItemRefIdList = selItemRefIdList
	end
	local NotSelectImgTrans = CS.FindTrans(item,"NotSelectImg")
	local SelImg = CS.FindTrans(item,"SelImg")
	local newNum = curNum + id
	if newNum < 0 then return	end
	local allNum = self:GetAllNum(refId)
	allNum = allNum + newNum
	if allNum < 0 then return end
	local serverNum = tonumber(self._serverNum)
	if allNum > serverNum then
		self:Examine(true)
		return
	end
	if newNum >= 0 then
		self:SetXUITextText(xuiText,newNum)
		self._chooseNum = self._chooseNum + id
		selItemRefIdList[refId] = newNum
	end
	local show = false
	if newNum > 0 then show = true end
	CS.ShowObject(SelImg,show)
	CS.ShowObject(NotSelectImgTrans,not show)
	self:Examine(false)
	self:SetChooseNumTxt()
end

function UIGetTip:InitEmptyList()
	local data = {
		refId = 23002,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end
------------------------------------------------------------------
--- 选择列表
------------------------------------------------------------------
function UIGetTip:InitScrollView()
	local refId = self._refId
	local itype = self._itype
	local datalist
	if itype == 1 then
		datalist = gModelItem:GetTypeDataByRefId(refId)
	else
		local ref = gModelItem:GetRefByRefId(refId)
		local _type
		if ref then
			_type = ref.type
		else
			_type = ModelItem.Item_STARPASS
		end
		self._itemType = _type
		datalist = gModelItem:GetTypeDataByRefId(refId)
		local tmpDataLsit = {}
		for i = 1,#datalist do
			local data = datalist[i]
			local isRandom = data.isRandom
			local card = data.refId
			local lim = data.num
			if isRandom == 1 then
				local list
				if _type == ModelItem.Item_STARPASS then
					list = gModelHero:SelRaceHeroList(card,lim)
				else
					list = gModelHero:SelRaceHeroList(card,nil,lim)
				end
				for k,v in pairs(list) do
					local id = v.id
					table.insert(tmpDataLsit, v)
				end
			else
				local list
				if _type == ModelItem.Item_STARPASS then
					list = gModelHero:SelRefIdHeroList(card,lim)
				else
					list = gModelHero:SelRefIdHeroList(card,nil,lim)
				end
				for k,v in pairs(list) do
					local id = v.id
					table.insert(tmpDataLsit, v)
				end
			end
		end
		datalist = tmpDataLsit
	end
	self._dataList = datalist
	local uiList = self._uiList

	if not uiList then
		uiList = self:GetUIScroll("_key_uiList")
		self._uiList = uiList

		local rootTrans
		if itype == 1 then
			rootTrans = self.mChooseList
		else
			rootTrans = self.mHeroList
		end
		local func
		if itype == 1 then
			func = function (...) self:OnDrawChooseCell(...) end
		else
			func = function (...) self:OnDrawHeroCell(...) end
		end
		CS.ShowObject(rootTrans, true)
		uiList:Create(rootTrans, datalist, func,UIItemList.WRAP,false)
	else
		uiList:RefreshList(datalist)
	end

	local len = #datalist
	local showNoRecord = len <= 0
	CS.ShowObject(self.mNoRecord2,showNoRecord)

	local list = uiList:GetList()
	list:RefreshList(UIListWrap.RefreshMode.Solid)
end

function UIGetTip:ShowSelDiv()
	local showRaceDiv = self._showRaceDiv
	for selType,divTrans in pairs(self._showSelDivList) do
		local show = showRaceDiv == selType
		CS.ShowObject(divTrans,show)
	end
end

function UIGetTip:RefreshScroll()
	local _uiList = self._uiList
	if not _uiList then return end
	local dataList = self._dataList
	if not dataList then return end
	local raceType = self._raceType
	if not raceType then return end
	local btnTrans
	if raceType == 0 then
		btnTrans = self.mAllRaceBtn
	else
		btnTrans = self._raceBtnList and self._raceBtnList[raceType]
	end
	CS.SetParentTrans(self.mRaceSelImg,btnTrans)
	local list = {}
	for i,v in ipairs(dataList) do
		if raceType == 0 then
			table.insert(list,v)
		else
			local refId = v.refId
			if refId then
				local ref,ins
				local itype = v.itype
				if itype then
					if itype == LItemTypeConst.TYPE_ITEM then
						ref = gModelItem:GetRefByRefId(refId)
						ins = ref and ref.itemRace == raceType or false
					elseif itype == LItemTypeConst.TYPE_HERO then
						local race = gModelHero:GetHeroRace(refId)
						ins = race == raceType or false
					end
				else
					ref = gModelItem:GetRefByRefId(refId)
					ins = ref and ref.itemRace == raceType or false
				end
				if ins then
					table.insert(list,v)
				end
			end
		end
	end

	local len = #list
	local showNoRecord = len <= 0
	CS.ShowObject(self.mNoRecord2,showNoRecord)

	if _uiList then
		self._chooseNum = 0
		self._xuiTextList = {}
		self._xuiInputList = {}
		self._selItemRefIdList = {}
		self._addBtnList = {}
		self:SetChooseNumTxt()
		self._dataList = dataList
		_uiList:RefreshList(list,true)
		local uiList = _uiList:GetList()
		uiList:RefreshList(UIListWrap.RefreshMode.Solid)
	end
end

function UIGetTip:BtnHelpEvent()
	local itemRefType = self:GetItemType()
	if not itemRefType then return end
	local refId = self._helpRefIdList[itemRefType]
	GF.OpenWndUp("UIBzTips",{refId = refId})
end

function UIGetTip:InitText()
	self:SetWndTitleByTextId(self.mTitle,10201)
	local str
	if self._itype == 1 then
		local getType = gModelItem:GetType(self._refId)
		if getType == ModelItem.Item_SELECT_TRY_HERO or getType == ModelItem.Item_SELECT_TRY_SPIRITHERO then
			str = 10245
		else
			str = 10202
		end
		self:SetWndTitleByTextId(self.mSecTitle,str)
	else
		local ref = gModelItem:GetRefByRefId(self._refId)
		if ref then
			local typedata = ref.typeDate
			local temp = string.split(typedata,"=")
			typedata = tonumber(temp[3])
			local getType = ref.type
			if getType == ModelItem.Item_STARPASS then
				str = ccClientText(10203)
			else
				str = ccClientText(10210)
			end
			str = string.replace(str,typedata)
			self:SetWndTitleByTitle(self.mSecTitle,str)
		end
	end
	self:SetWndButtonText(self.mCancelBtn,ccClientText(10101))
	self:SetWndButtonText(self.mEnterBtn,ccClientText(10102))
end
------------------------------------------------------------------
return UIGetTip


