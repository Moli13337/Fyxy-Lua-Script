---
--- Created by Administrator.
--- DateTime: 2023/10/24 21:39:49
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaRee:LWnd
local UISagaRee = LxWndClass("UISagaRee", LWnd)

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaRee:UISagaRee()
	self:SetHideHurdle()

--[[	---@type UIIconEasyList
	self._itemIconEasyList = nil]]

	---@type table<number,CommonIcon>
	self._iconHeroClsList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaRee:OnWndClose()
--[[	if self._itemIconEasyList then
		self._itemIconEasyList:Destroy()
		self._itemIconEasyList = nil
	end]]
	self:ClearCommonIconList(self._iconHeroClsList)
	self:ClearAllTimer()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaRee:OnCreate()
	LWnd.OnCreate(self)
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaRee:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	--gModelRedPoint:ShowPointRed(ModelRedPoint.HERO_RESONANCE,false)


	self:SetWndText(self.mTitle,ccClientText(14705))
	self:InitData()
	self:SetWndText(self.mJiachengTxt,ccClientText(14716))
	self:SetWndButtonText(self.mUpLvBtn,ccClientText(10000))

	self:SetWndText(self.mLNoLvTxt,ccClientText(14736))
	self:SetWndText(self.mLMaxLvTxt,ccClientText(14737))

	local str = ccClientText(14716)
	local hyper = UIHyperText:New()
	hyper:Create(self.mJiachengTxt)
	str = hyper:AddHyper(str,{func = function ()
		GF.OpenWnd("UIReeAdd",{selectList = self._selectMaxStarList,addLv = self._addLv})
	end})
	self:SetWndText(self.mJiachengTxt,str)

	self:InitEvent()
	self:InitMsg()
	self:InitBtnList()
	self:Refresh()
	self:RefreshPayDiv()
end

function UISagaRee:ClearAllTimer()
    local timeList = self._timeList
    if timeList then
        for k,v in pairs(timeList) do
            self:ClearTime(k)
        end
    end
end

function UISagaRee:ChangPageData(index,refresh)



	if index == self._page and (not refresh) then return end
	if index then
		local trans = self._botBtnList[self._page]
		if trans then self:SetWndTabStatus(trans,1) end
		--CS.ShowObject(self._botBtnList[self._page],false)
		self._page = index
		trans = self._botBtnList[self._page]
		if trans then self:SetWndTabStatus(trans,0) end
		--CS.ShowObject(self._botBtnList[self._page],true)


	end
	--local redPointTrans = self._btnRedPoint[index]
	--if redPointTrans then
	--	if self._page == 2 then
	--		local show = gModelResonance:CheckBreakRedPoint()
	--		CS.ShowObject(redPointTrans,show)
	--	else
	--		CS.ShowObject(redPointTrans,false)
	--	end
	--end

	if self._page == 1 then
		local funcId = 16501000
		gModelRedPoint:OnClickFunc(funcId)
	end

	for i,v in ipairs(self._pageList) do CS.ShowObject(v,i == self._page) end
	self:RefreshPayDiv()
	self:Refresh()
end

function UISagaRee:RefreshAttrList()
	local curLv = self._resonanceLevel
	local curAttrList = GameTable.LevelShareBreachRef[curLv] and GameTable.LevelShareBreachRef[curLv].attr or ""

	local nextAttrList
	local maxLv = gModelResonance:GetBreakUpMaxLv()
	local next = curLv + 1
	if next > maxLv then
		next = maxLv
		nextAttrList = ""
	else
		nextAttrList = GameTable.LevelShareBreachRef[next] and GameTable.LevelShareBreachRef[next].attr or ""
	end
	curAttrList = string.split(curAttrList,",")
	nextAttrList = string.split(nextAttrList,",")
	local curAttrCList = {}
	for i,v in ipairs(curAttrList)do
		v = string.split(v,"=")
		table.insert(curAttrCList,{
			numType = tonumber(v[2]),
			refId = tonumber(v[1]),
			value = tonumber(v[3]),
		})
	end
	local nextAttrCList = {}
	for i,v in ipairs(nextAttrList)do
		v = string.split(v,"=")
		table.insert(nextAttrCList,{
			numType = tonumber(v[2]),
			refId = tonumber(v[1]),
			value = tonumber(v[3]),
		})
	end
	local curHaveAttr = #curAttrCList > 0
	local str = ""
	local curAttrListTrans = self.mCurAttrList
	if curHaveAttr then
		str = string.replace(ccClientText(14734),curLv)
		self:CreateAttrList("cur",curAttrListTrans,curAttrCList)
	end
	self:SetWndText(self.mLCurLvTxt,str)
	CS.ShowObject(curAttrListTrans,curHaveAttr)
	CS.ShowObject(self.mLNoLvTxt,not curHaveAttr)

	local nextHaveAttr = #nextAttrCList > 0
	str = ""
	local NextAttrListTrans = self.mNextAttrList
	if nextHaveAttr then
		str = string.replace(ccClientText(14735),next)
		self:CreateAttrList("next",NextAttrListTrans,nextAttrCList)
	end
	self:SetWndText(self.mLNextLvTxt,str)
	CS.ShowObject(NextAttrListTrans,nextHaveAttr)
	CS.ShowObject(self.mLMaxLvTxt,not nextHaveAttr)
end

function UISagaRee:OnDrawItemCell(list, item, itemdata, itempos)
	local instanceId = item:GetInstanceID()
	local ItemIconTrans = self:FindWndTrans(item,"ItemIcon")
	if ItemIconTrans then
		local refId = itemdata.itemId
		local baseClass = self._iconHeroClsList[instanceId]
		if not baseClass then
			baseClass = CommonIcon:New(self)
			self._iconHeroClsList[instanceId] = baseClass
			baseClass:Create(ItemIconTrans)
		end
		baseClass:SetCommonReward(itemdata.itemType, refId)
		baseClass:EnableShowNum(false)
		baseClass:DoApply()
		self:SetWndClick(ItemIconTrans,function()
			gModelGeneral:OpenGetWayWnd({itemId = refId,srcWnd = self:GetWndName()})
		end)
	end
	local NumTrans = self:FindWndTrans(item,"Num")
	if NumTrans then
		local haveNum,num = itemdata.haveNum,itemdata.itemNum
		local colorKey = "green"
		if haveNum < num then colorKey = "red"	end
		haveNum = LUtil.NumberCoversion(haveNum)
		local haveNumStr = LUtil.FormatColorStr(haveNum,colorKey)
		num = LUtil.NumberCoversion(num)
		local str = string.format("%s/%s",haveNumStr,num)
		self:SetWndText(NumTrans,str)
	end
end

function UISagaRee:InitItemList(itemList)
    --[[	local uiList = self._itemIconEasyList
        if not uiList then
            uiList = UIIconEasyList:New()
            self._itemIconEasyList = uiList
            uiList:Create(self, self.mItemList)
            uiList:SetShowNum(false)
            uiList:SetIconParentPath("ItemIcon")
            uiList:ShowNeedNumStatus(true, true)
        end

        self._lostItemList = {}

        local dataList = {}
        itemList = string.split(itemList,",")
        for i,v in ipairs(itemList) do
            v = string.split(v,"=")
            local refId = tonumber(v[2])
            local num = tonumber(v[3])
            local haveNum = gModelItem:GetNumByRefId(refId)
            if haveNum < num then
                table.insert(self._lostItemList,{refId = refId})
            end

            table.insert(dataList, {itemId=refId, itemNum=num, itemType=tonumber(v[1])})
        end

        uiList:RefreshList(dataList)]]

	self._lostItemList = {}
    local list = {}
    local show = itemList ~= "-1"
    CS.ShowObject(self.mItemList,show)
    if show then
        itemList = string.split(itemList,",")
        for i,v in ipairs(itemList) do
            v = string.split(v,"=")
            local refId = tonumber(v[2])
            local num = tonumber(v[3])
            local haveNum = gModelItem:GetNumByRefId(refId)
            if haveNum < num then
                table.insert(self._lostItemList,{refId = refId})
            end
            table.insert(list, {itemId = refId,itemNum = num,itemType = tonumber(v[1]),haveNum = haveNum})
        end
        local uiList = self._itemIconEasyList
        if uiList then
            uiList:RefreshList(list)
        else
            uiList = self:GetUIScroll("_itemIconEasyList")
            self._itemIconEasyList = uiList
            uiList:Create(self.mItemList,list,function(...) self:OnDrawItemCell(...) end)
        end
    end
end

function UISagaRee:CreateAttrList(key,trans,list)
	CS.ShowObject(trans,true)
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(trans,list,function(...) self:OnDrawAttrCell(...) end)
	end
	local isEnable = #list > 2
	uiList:EnableScroll(isEnable)
end

function UISagaRee:RefreshPage2()
	local heroList = gModelHero:GetHeroList()
	local addLv = 0
	local maxList = {}
	for k,v in pairs(heroList) do
		local serverData = v:GetServerData()
		local refId,star,id = serverData.refId,serverData.star,serverData.id
		if self._maxStarAddList[star] then
			if not maxList[refId] then
				maxList[refId] = {star = star,id = id}
			else
				if maxList[refId].star < star then
					maxList[refId].star = star
					maxList[refId].id = id
				end
			end
		end
	end
	self._selectMaxStarList = {}
	for k,v in pairs(maxList) do
		addLv = addLv + self._maxStarAddList[v.star]
		table.insert(self._selectMaxStarList,v.id)
	end
	--addLv = addLv + self._resonanceLevel
	--addLv = gModelResonance:GetResonanceMaxLv()
	self._addLv = addLv
	local str = string.replace(ccClientText(14717),addLv)
	self:SetWndText(self.mLvlimitTxt,str)
	local maxLv = gModelResonance:GetResonanceMaxLv()
	str = string.replace(ccClientText(14719),self._resonanceLevel,maxLv)
	self:SetWndText(self.mCurLvTxt,str)

	self:RefreshAttrList()

	local gray = self._resonanceLevel >= maxLv
	self:SetWndButtonGray(self.mUpLvBtn,gray)

	local ref = GameTable.LevelShareBreachRef[self._resonanceLevel]
	if ref then
		local upNeed = ref.upNeed
		if string.isempty(upNeed) then
			CS.ShowObject(self.mItemList,false)
		else
			self:InitItemList(upNeed)
		end
	end
end

function UISagaRee:InitData()
	self._page = self:GetWndArg("page") or 1
	self._heroResonanceList,self._resonanceLevel,self._heroResonancePosList = gModelResonance:GetResonanceData()
	self._heroList = {self.mHero1,self.mHero2,self.mHero3,self.mHero4,self.mHero5}
	self._heroPbList = {self.mHeroPb1,self.mHeroPb2,self.mHeroPb3,self.mHeroPb4,self.mHeroPb5}
	self._heroLvTxtList = {self.mHeroLv1Txt,self.mHeroLv2Txt,self.mHeroLv3Txt,self.mHeroLv4Txt,self.mHeroLv5Txt}
	self._botTxtList = {ccClientText(14703),ccClientText(14704)}
	self._pageList = {self.mPage1,self.mPage2}
	self._botBtnList = {}
	self._resonanceSlotNum = GameTable.LevelShareConfigRef["resonanceSlotNum"]
	self._resonanceShowItem = GameTable.LevelShareConfigRef["resonanceShowItem"]
	self._resonanceBreachShowItme = GameTable.LevelShareConfigRef["resonanceBreachShowItme"]
	self._resonanceTime = GameTable.LevelShareConfigRef["resonanceTime"]
	self._resonanceBreachLevel = GameTable.LevelShareConfigRef["resonanceBreachLevel"]

	self._maxStarAddList = {}
	self._pbList = {}
	self._effList = {}
	self._lostItemList = {}
	self._pbKeyList = {}

	self._maskTransList = {
		self.mMask1,
		self.mMask2,
		self.mMask3,
		self.mMask4,
		self.mMask5,
	}
	self._heroEffList = {}
	self._heroAddList = {}
	for k,v in ipairs(self._heroList) do
		table.insert(self._heroEffList, CS.FindTrans(v, "eff"))
		table.insert(self._heroAddList, CS.FindTrans(v, "Add"))
	end
	local resonanceStarAddLevel = GameTable.LevelShareConfigRef["resonanceStarAddLevel"]
	resonanceStarAddLevel = string.split(resonanceStarAddLevel,",")
	for i,v in ipairs(resonanceStarAddLevel) do
		v = string.split(v,"=")
		self._maxStarAddList[tonumber(v[1])] = tonumber(v[2])
	end
	self._payItemList = {self._resonanceShowItem,self._resonanceBreachShowItme}
	self._haveNum = 0
	self._timeList = {}
	self._btnRedPoint = {}
	self:ChangPageData(nil,true)

	self._spineKey = nil
	self:CreateSpine()
end

function UISagaRee:CreateSpine()
	local spineKey
	if self._resonanceBreachLevel <= self._resonanceLevel then
		spineKey = "Gongmingshuijing_liebian"
	else
		spineKey = "Gongmingshuijing_putong"
	end
	if self._spineKey then
		if self._spineKey == spineKey then
			return
		else
			self:DestroyWndSpineByKey(self._spineKey)
		end
	end
	self:CreateWndSpine(self.mShuijingEff,spineKey,spineKey,false,function(spine)
		--spine:SetScale(2)
		spine:PlayAnimation(0,"idle",true)
		self._spineKey = spineKey
	end)
	local showEff = gModelResonance:GetTuPoEffStatue()
	if showEff == 1 then
		self:CreateWndEffect(self.mShuijingEff,"fx_gongmingshuijing_tupo","fx_gongmingshuijing_tupo",100,false)
		gModelResonance:SetTuPoEffStatue()
	end
end

function UISagaRee:ClearTime(refId,refresh)
	local timeList = self._timeList
    if not timeList then return end
	local timer = timeList[refId]
	if timer then
		LxTimer.DelayTimeStop(timer)
		timeList[refId] = nil
	end
	if refresh then
		gModelResonance:OnResonanceInfoReq()
	end
end

function UISagaRee:CreateTime(itemdata,txtTrans)
	local refId = itemdata.refId
	self:ClearTime(refId)
	self:SetHourTimer(itemdata,txtTrans)
	self._timeList[refId] = LxTimer.LoopTimeCall(function()
		self:SetHourTimer(itemdata,txtTrans)
	end, 1, false, -1)
end
------------------------------------------------------------------
function UISagaRee:RefreshTop()
	local lvStr = "<color=#%s>%s</color>"
	lvStr = string.replace(lvStr,LUtil.GetResonanceColor(1),self._resonanceLevel)
	local isBreak = self._resonanceBreachLevel <= self._resonanceLevel
	local textId = isBreak and 14739 or 14738
	self:SetWndText(self.mHeroResonanceDesc,ccClientText(textId))

	if isBreak then
		local maxLv = gModelResonance:GetResonanceMaxLv()
		local upMaxLv = gModelResonance:GetBreakUpMaxLv()
		if upMaxLv < maxLv then
			maxLv = upMaxLv
		end
		lvStr = lvStr .. "/" .. maxLv
	end
	local str = string.replace(ccClientText(14701),lvStr)
	self:SetWndText(self.mLvTxt,str)

	if not isBreak then
		table.sort(self._heroResonanceList,function(heroId1,heroId2)
			local serverData1,serverData2 = gModelHero:GetHeroServerDataById(heroId1),gModelHero:GetHeroServerDataById(heroId2)
			local lv1,lv2 = serverData1.lv,serverData2.lv
			return lv1 < lv2
		end)
		--self:DestroyWndSpinetAll()
		for k,v in pairs(self._pbKeyList) do
			self:DestroyWndSpineByKey(v)
		end

		for k,v in ipairs(self._heroEffList) do
			local effKey = "Eff_Resoun_"..k
			local eff = self:FindWndEffectByKey(effKey)
			if not eff then
				self:CreateWndEffect(v,"fx_ui_gmsj_guanghuan", effKey,100,false,false)
			end
		end

		for k,v in ipairs(self._heroAddList) do
			CS.ShowObject(v, true)
		end

		for k,v in ipairs(self._maskTransList) do
			CS.ShowObject(v, false)
		end

		self._pbKeyList = {}
		str = ccClientText(14701)
		local heroLvList = self._heroLvTxtList
		local heroTransList = self._heroList
		local heroPbList = self._heroPbList
		local bShowMask = false
		for i,v in ipairs(self._heroResonanceList) do
			local serverData = gModelHero:GetHeroServerDataById(v)
			bShowMask = false
			if serverData then
				bShowMask = true
				local lv = serverData.lv
				local lvstr = string.replace(str,lv)
				self:SetWndText(heroLvList[i],lvstr)
				local pbName = gModelHero:GetHeroPrefabNameById(v)
				local spine = self:FindWndSpineByKey(v)
				if not spine then
					self._pbKeyList[i] = v
					self._pbList[i] = self:CreateWndSpine(heroPbList[i],pbName,v,false)
				end
			end
			CS.ShowObject(self._maskTransList[i], bShowMask)
			CS.ShowObject(self._heroAddList[i], not bShowMask)
		end
	else
		local heroList = self._heroList
		for i,v in ipairs(heroList) do
			CS.ShowObject(v,false)
		end
	end

end

function UISagaRee:OnDrawAttrCell(list, item, itemdata, itempos)
	local attrIcon = self:FindWndTrans(item,"attrIcon")
	local attrName = self:FindWndTrans(item,"attrName")
	local attrValue = self:FindWndTrans(item,"attrValue")
	local refId,numType,value = itemdata.refId,itemdata.numType,itemdata.value
	if attrIcon then
		local icon = gModelHero:GetAttributeIconById(refId)
		self:SetWndEasyImage(attrIcon,icon,function()
			CS.ShowObject(attrIcon,true)
		end)
	end
	if attrName then
		local name = gModelHero:GetAttributeNameById(refId)
		local nameStr = string.replace(ccClientText(18315),name)
		self:SetWndText(attrName,nameStr)
	end
	if attrValue then
		local baseStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,numType,value)
		self:SetWndText(attrValue,baseStr)
	end
end

function UISagaRee:GetList()
    local retList = {}
    self._allData = {}
    local heroResonancePosList = self._heroResonancePosList
    local usePosNum = 0
    local noBreak = self._resonanceBreachLevel <= self._resonanceLevel
    local allNum,haveNum = table.keysize(heroResonancePosList),0
    local gongfenNum = 0
    local refList = {}
    for k,v in pairs(GameTable.LevelSharePosRef) do
        local hide = v.hide
        if hide == 1 then gongfenNum = gongfenNum + 1 end
        if not noBreak then
            if hide == 0 then table.insert(refList,v) end
        else
            table.insert(refList,v)
        end
    end
    if noBreak then allNum = allNum end
    table.sort(refList,function(ref1,ref2)
        return ref1.sort < ref2.sort
    end)
    for i,v in ipairs(refList) do
        local refId = v.refId
		local hide = v.hide
        local serverData = heroResonancePosList[refId]
        local data = {
			refId = refId,
			nextId = v.nextId,
			openType = v.openType,
			sort = v.sort,
			hide = hide,
			unlockNeedItem = v.unlockNeedItem,
			unlockNeedDiamonds = v.unlockNeedDiamonds,
		}
        if serverData ~= nil then
            if hide == 0 then haveNum = haveNum + 1 end
            if not string.isempty(serverData.heroId) then usePosNum = usePosNum + 1 end
            data.heroId,data.coolTime = serverData.heroId,serverData.coolTime
        end
        if hide == 0 then table.insert(self._allData,data) end
        table.insert(retList,data)
    end
    self._haveNum = haveNum
    local str = string.format("%s/%s",usePosNum,allNum)
    self:SetWndText(self.mDiv1ItemNum,str)
    return retList
end

function UISagaRee:InitMsg()
	self:WndNetMsgRecv(LProtoIds.ResonanceInfoResp, function()
		self._heroResonanceList,self._resonanceLevel,self._heroResonancePosList = gModelResonance:GetResonanceData()
--[[		if self._resonanceBreachLevel <= self._resonanceLevel then
		end]]
		self:CreateSpine()
		if self._uiBtnList then self._uiBtnList:RefreshList() end
		self:Refresh()
	end)
	self:WndNetMsgRecv(LProtoIds.ResonancePosUnlockResp, function()
		GF.ShowMessage(ccClientText(14727))
	end)
	self:WndNetMsgRecv(LProtoIds.ResonancePosCoolTimeResp, function()
		GF.ShowMessage(ccClientText(14726))
	end)
	self:WndNetMsgRecv(LProtoIds.ResonanceHeroResp, function(pb,ret)
		if pb.opera == 2 then
			GF.ShowMessage(ccClientText(14728))
		end
	end)
	self:WndNetMsgRecv(LProtoIds.ItemChangeResp,function()
		self:Refresh()
	end)
end

function UISagaRee:SetHourTimer(itemdata,txtTrans)
	local coolTime = itemdata.coolTime / 1000
	local curTime = tonumber(GetTimestamp())
	local mulTime = coolTime - curTime
	--printInfoNR("======== coolTime = " .. coolTime.. ",curTime = " ..curTime .. ",mulTime = " .. mulTime)
	itemdata.mulTime = mulTime
	if mulTime < 0 then
		self:ClearTime(itemdata.refId,true)
		gModelResonance:OnResonanceInfoReq()
	else
		mulTime = LUtil.FormatTimespanNumber(mulTime)
		self:SetWndText(txtTrans,mulTime)
	end
end

function UISagaRee:OnDrawHeroCell(list,item,itemdata,itempos)
	local heroId = itemdata.heroId
	local show = heroId and not string.isempty(heroId)
	local heroIconTrans = CS.FindTrans(item,"HeroIcon")
	if heroIconTrans then
		CS.ShowObject(heroIconTrans,show)
		if show then
			local instanceId = item:GetInstanceID()
			local baseClass = self._iconHeroClsList[instanceId]
			if not baseClass then
				baseClass = CommonIcon:New(self)
				self._iconHeroClsList[instanceId] = baseClass
				baseClass:Create(heroIconTrans)
				self:SetIconClickScale(heroIconTrans, true)
			end
			baseClass:SetHeroPlayer(heroId)
			baseClass:DoApply()

			self:SetWndClick(heroIconTrans,function()
				self:Operate(itemdata,1,function(itemType)
					gModelResonance:OnResonanceHeroReq(heroId,itemdata.refId,2)
				end,2,heroId)
			end)
		end
	end
	local BgTrans = CS.FindTrans(item,"Bg")
	if BgTrans then
		local AddImgTrans = CS.FindTrans(BgTrans,"AddImg")
		local ClockImgTrans = CS.FindTrans(BgTrans,"ClockImg")
		local TimeTxtTrans = CS.FindTrans(BgTrans,"TimeTxt")
		local img
		if heroId ~= nil then
			if string.isempty(heroId) then
				img = "public_item_bg_1"
				local coolTime = tonumber(itemdata.coolTime)
				local noShowAdd = coolTime > 0
				CS.ShowObject(ClockImgTrans,noShowAdd)
				CS.ShowObject(TimeTxtTrans,noShowAdd)
				CS.ShowObject(AddImgTrans,not noShowAdd)
				if noShowAdd then
					self:CreateTime(itemdata,TimeTxtTrans)
				end
			else
				CS.ShowObject(BgTrans,false)
			end
		else
			img = "public_item_bg_lock"
			CS.ShowObject(AddImgTrans,false)
			CS.ShowObject(ClockImgTrans,false)
			CS.ShowObject(TimeTxtTrans,false)
		end
		if img then
			CS.ShowObject(BgTrans,true)
			self:SetWndEasyImage(BgTrans,img)
		end
		self:SetWndClick(BgTrans,function() self:OptEvent(itemdata) end)
	end
	local redPointTrans = CS.FindTrans(item,"redPoint")
	if redPointTrans then
		local showRedPoint = false
		if heroId then
			showRedPoint = string.isempty(itemdata.heroId)
			if showRedPoint then
				showRedPoint = tonumber(itemdata.coolTime) == 0
			end
			if showRedPoint then
				-- 英雄为空且冷却时间为0
				showRedPoint = self:ShowRedPoint()
			end
		else
			showRedPoint = self._haveNum + 1 == itemdata.refId
			if showRedPoint then
				local unlockNeedItem = itemdata.unlockNeedItem
				unlockNeedItem = string.split(unlockNeedItem,"=")
				local haveNum = gModelItem:GetNumByRefId(self._resonanceShowItem)
				local needNum = tonumber(unlockNeedItem[3])
				showRedPoint = haveNum >= needNum
--[[			-- 没解锁的不用判断是否有英雄入住
				if showRedPoint then
					-- 满足材料后再判断是否有可共鸣的英雄
					showRedPoint = self:ShowRedPoint()
				end]]
			end
		end
		CS.ShowObject(redPointTrans,showRedPoint)
	end
end
------------------------------------------------------------------
function UISagaRee:InitBtnList()
	local uiList = self._uiBtnList
	if not uiList then
		uiList = UIListEasy:New()
		uiList:Create(self,self.mTypeBtnList)
		uiList:EnableScroll(false,true)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrwaBtnItem(...)
		end)
		self._uiBtnList = uiList
	end
	uiList:RemoveAll()
	local list = {}
	for i,v in ipairs(self._botTxtList) do
		local ins = true
		if i == 2 then
			ins = self._resonanceBreachLevel <= self._resonanceLevel
		end
		if ins then
			local data = {index = i,name = v}
			table.insert(list,data)
		end
	end
	for i,v in ipairs(list) do
		uiList:AddData(i,v)
	end
	uiList:RefreshList()
end

function UISagaRee:OnDrwaBtnItem(list, item, itemdata, itempos, fromHeadTail)
	local name,index = itemdata.name,itemdata.index

--	local redPointTrans = CS.FindTrans(item,"redPoint")
--	if redPointTrans then
--		self._btnRedPoint[index] = redPointTrans
--		local show
--		if index == 1 then
--			show = gModelResonance:CheckResonanceRedPoint()
----[[			if show then
--				show = self:ShowRedPoint()
--			end]]
--		else
--			show = gModelResonance:CheckBreakRedPoint()
--		end
--		CS.ShowObject(redPointTrans,show)
--	end

	local btnTrans = self:FindWndTrans(item,"Btn")
	if btnTrans then
		if index == 2 then
			local show = false
			if self._resonanceBreachLevel <= self._resonanceLevel then show = true end
			CS.ShowObject(btnTrans,show)
		end
		self:SetWndTabText(btnTrans,name,-2)
		self:SetWndTabStatus(btnTrans,index == self._page and 0 or 1)
		self._botBtnList[index] = btnTrans
		self:SetWndClick(btnTrans,function()
			self:ChangPageData(index)
		end,LSoundConst.CLICK_PAGE_COMMON)
	end

--[[	local NoSelImgTrans = CS.FindTrans(item,"NoSelImg")
	if NoSelImgTrans then
		local NoSelNameTrans = CS.FindTrans(NoSelImgTrans,"NoSelName")
		if NoSelNameTrans then self:SetWndText(NoSelNameTrans,name) end
	end
	local SelImgTrans = CS.FindTrans(item,"SelImg")
	if SelImgTrans then
		local BtnNameTrans = CS.FindTrans(SelImgTrans,"BtnName")
		if BtnNameTrans then self:SetWndText(BtnNameTrans,name) end
		CS.ShowObject(SelImgTrans,index == self._page)
	end
	if NoSelImgTrans and SelImgTrans then
		if index == 2 then
			local show = true
			if self._resonanceBreachLevel > self._resonanceLevel then show = false end
			CS.ShowObject(NoSelImgTrans,show)
			if show then
				CS.ShowObject(SelImgTrans,index == self._page)
			else
				CS.ShowObject(NoSelImgTrans,show)
			end
		end
		self._botBtnList[index] = SelImgTrans
		self:SetWndClick(NoSelImgTrans,function()
			self:ChangPageData(index)
		end,LSoundConst.CLICK_PAGE_COMMON)
	end]]
end

function UISagaRee:ShowRedPoint()
	-- 满足材料后再判断是否有可共鸣的英雄
	local resonanceList = gModelResonance:SelResonanceHeroList()
	local heroList = gModelHero:GetHeroList()
	for k,v in pairs(heroList) do
		local hero = v:GetServerData()
		local id = hero.id
		if not resonanceList[id] then
			local lv = hero.lv
			if lv < self._resonanceLevel then
				return true
			end
		end
	end
	return false
end

function UISagaRee:RefreshPayDiv()
	local refId = self._payItemList[self._page]
	local icon = gModelItem:GetItemIconByRefId(refId)
	self:SetWndEasyImage(self.mDiv2ItemIcon,icon)
	local num = gModelItem:GetNumByRefId(refId)
	num = LUtil.NumberCoversion(num)
	self:SetWndText(self.mDiv2ItemNum,num)
end

function UISagaRee:InitHeroList()
--[[	local uiList = self._uiList
	if not uiList then
		uiList = UIListWrap:New()
		uiList:Create(self,self.mHeroList)
		uiList:SetItemOverflowRange(2000)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrawHeroCell(...)
		end)
		self._uiList = uiList
	end
	uiList:RemoveAll()
    local list = self:GetList()
	uiList:RefreshList()]]

    local list = self:GetList()
    if self._uiList then
        --local uiList = self._uiList:GetList()
        self._uiList:RefreshData(list)
    else
        self._uiList = self:GetUIScroll("heroList")
        self._uiList:Create(self.mHeroList,list,function(...)
            self:OnDrawHeroCell(...)
        end,UIItemList.WRAP,false)
        local uiList = self._uiList:GetList()
        uiList:EnableLoadAnimation(true, 0, 2)
        uiList:RefreshList(UIListWrap.RefreshMode.Solid)
    end
end

function UISagaRee:OptEvent(itemdata)
	if itemdata.heroId then
		if string.isempty(itemdata.heroId) then
			if tonumber(itemdata.coolTime) == 0 then
				local resonanceList = gModelResonance:SelResonanceHeroList()
				-- 已解锁
				GF.OpenWnd("UISagaResSel",{resonanceList = resonanceList,resonanceLevel = self._resonanceLevel,pos = itemdata.refId})
			else
				-- 冷却中
				printInfoN("冷却中")
				self:Operate(itemdata,2,function(itemType)
					gModelResonance:OnResonancePosCoolTimeReq(itemdata.refId,itemType)
				end)
			end
		else
			-- 共鸣中
			printInfoN("共鸣中")
		end
	else
		-- 未解锁
		printInfoN("未解锁")
		if self._haveNum + 1 == itemdata.refId then
			self:Operate(itemdata,1,function(itemType)
				gModelResonance:OnResonancePosUnlockReq(itemdata.refId,itemType)
			end)
		else
			local data = self._allData[self._haveNum + 1]
			if data then
				self:Operate(data,1,function(itemType)
					gModelResonance:OnResonancePosUnlockReq(data.refId,itemType)
				end)
			end
			--GF.ShowMessage("先解锁前面的")
		end
	end
end

function UISagaRee:InitEvent()
	--self:WndEventRecv(EventNames.ON_MAIN_CITY_BTN_CHANGE,function () self:WndClose() end)
	self:SetWndClick(self.mReturnBtn,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mHelpBtn,function()
		local refId = 34
		if self._page == 2 then refId = 35 end
		GF.OpenWnd("UIBzTips",{refId = refId})
	end)
	self:SetWndClick(self.mDiv1ItemAddBtn,function()
		local data = self._allData[self._haveNum + 1]
		if data then
			self:Operate(data,1,function(itemType)
				gModelResonance:OnResonancePosUnlockReq(data.refId,itemType)
			end)
		else
			GF.ShowMessage(ccClientText(14732))
		end
	end)
	self:SetWndClick(self.mDiv2ItemAddBtn,function()
		local refId = self._payItemList[self._page]
		gModelGeneral:OpenGetWayWnd({itemId = refId})
	end)
	self:SetWndClick(self.mUpLvBtn,function()
		local lostItemList = self._lostItemList or {}
		local len = #lostItemList
		if len == 0 then
			gModelResonance:OnResonanceBreachReq()
		else
			local maxLv = gModelResonance:GetResonanceMaxLv()
			if self._resonanceLevel >= maxLv then
				gModelResonance:OnResonanceBreachReq()
			else
				local data = self._lostItemList[1]
				if data then
					local refId = data.refId
					gModelGeneral:OpenGetWayWnd({itemId = refId})
				end
			end
		end
	end)
end

function UISagaRee:Operate(itemdata,itype,func,viewPage,heroId)
	local data = {}
	if itype == 1 then
		local unlockNeedItem = itemdata.unlockNeedItem
		local unlockNeedDiamonds = itemdata.unlockNeedDiamonds
		table.insert(data,unlockNeedItem)
		table.insert(data,unlockNeedDiamonds)
	else
		local mulTime = itemdata.mulTime or 0
		local maxRefId,maxTime = 0,0
		for k,v in pairs(GameTable.LevelShareCoolRef) do
			local time = v.time
			if mulTime >= time then
				if maxTime < time then
					maxRefId,maxTime = v.refId,time
				end
				if maxTime == 0 then
					maxRefId,maxTime = v.refId,time
				end
			end
		end
		if maxRefId ~= 0 then
			local ref = GameTable.LevelShareCoolRef[maxRefId]
			table.insert(data,ref.NeedItem)
			table.insert(data,ref.NeedDiamonds)
		end
	end
	printInfoN("===========")
	GF.OpenWnd("UIReeOpt",{view = viewPage,itype = itype,data = data,func = func,heroId = heroId})
end

function UISagaRee:Refresh()
	self:RefreshTop()
	self:RefreshPayDiv()
	if self._page == 1 then
		self:InitHeroList()
	else
		self:GetList()
		self:RefreshPage2()
	end
end
------------------------------------------------------------------
return UISagaRee