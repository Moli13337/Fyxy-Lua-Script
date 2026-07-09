---
--- Created by Administrator.
--- DateTime: 2023/10/17 10:12:34
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEqCompound:LWnd
local UIEqCompound = LxWndClass("UIEqCompound", LWnd)

UIEqCompound.RUNE_MAX_NUM = 5
UIEqCompound.RUNE_SHOWCENTER_NUM = 2

UIEqCompound.STATUS_SEL_FULL = 0			-- 材料已满
UIEqCompound.STATUS_SEL_NOTTYPE = 1			-- 类型不同
UIEqCompound.STATUS_SEL_OK = 2				-- 可以选择
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEqCompound:UIEqCompound()
	self._comRuneAniKey = "runeCom" 						-- 符文合成
	self:SetHideHurdle()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEqCompound:OnWndClose()

	if self._func then self._func() end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEqCompound:OnCreate()
	LWnd.OnCreate(self)
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEqCompound:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitData()

	gModelRedPoint:SetRedPointClicked(ModelRedPoint.GOLDHOUSE)

	self:InitEvent()
	self:InitMsg()
	self:InitRuneList()
	self:RefreshBar()
	self:RefreshSelNum()
	self:RefreshPayNum()
end

function UIEqCompound:CheckRuneStatus(id,refId,showMsg)
	local selRuneInfoList = self._selRuneInfoList
	if not selRuneInfoList then
		selRuneInfoList = {}
		self._selRuneInfoList = selRuneInfoList
	end

	local selRuneInfoKeyList = self._selRuneInfoKeyList
	if not selRuneInfoKeyList then
		selRuneInfoKeyList = {}
		self._selRuneInfoKeyList = selRuneInfoKeyList
	end

	-- 符文是否选中状态
	local isSel = selRuneInfoKeyList[id] and true or false

	-- 是否已经放置了5个符文
	local len = #selRuneInfoList
	local faceOptNum = (not isSel) and 1 or -1
	if len + faceOptNum > UIEqCompound.RUNE_MAX_NUM then
		if showMsg then
			GF.ShowMessage(ccClientText(13242))
		end
		return UIEqCompound.STATUS_SEL_FULL
	end

	-- 符文类型是否相同
	if self._selRuneRefId and self._selRuneRefId ~= refId then
		if showMsg then
			GF.ShowMessage(ccClientText(13241))
		end
		return UIEqCompound.STATUS_SEL_NOTTYPE
	end

	return UIEqCompound.STATUS_SEL_OK
end

function UIEqCompound:RefreshInfo(network)
	self:InitRuneList(network)
	self:RefreshTopRune()
	self:RefreshSelNum()
	self:RefreshPayNum()
end

function UIEqCompound:OnClickCompoundFunc()
	if not self._selRuneRefId then return end
	if self._runeCompoundClick then return end
	local selRuneInfoList = self._selRuneInfoList
	if not selRuneInfoList then
		selRuneInfoList = {}
		self._selRuneInfoList = selRuneInfoList
	end
	local len = #selRuneInfoList
	if len < UIEqCompound.RUNE_SHOWCENTER_NUM then
		self:NotEnoughRune()
	else
		local compoundRef = gModelRune:GetRuneComposeRef(self._selRuneRefId,len)
		if not compoundRef then return end
		local list = {}
		local runeDataList = {}
		local tipQuality = gModelRune:GetConfig("tipQuality")
		local isUpQuality = false
		local itemType = LItemTypeConst.TYPE_RUNE
		local selRefId
		for i,v in ipairs(selRuneInfoList) do
			local refId,id = v.refId,v.id
			if not selRefId then selRefId = refId end
			if not isUpQuality then
				local quality = gModelRune:GetRuneQualityByRefId(refId)
				isUpQuality = quality >= tipQuality
			end
			table.insert(list,id)
			table.insert(runeDataList,{
				itype = itemType,
				refId = refId,
				hideNum = true,
				id = id,
				count = 1
			})
		end
		local func = function()
			local itemId = self._payRefId
			local needNum = self._payNum
			local haveNum = gModelItem:GetNumByRefId(itemId)
			if haveNum and needNum and haveNum >= needNum then
				self._runeCompoundClick = true
				gModelRune:OnRuneCompoundReq(list)
			else
				gModelGeneral:OpenGetWayWnd({itemId = itemId,srcWnd = self:GetWndName()})
			end
		end
		local isFull = len == UIEqCompound.RUNE_MAX_NUM
		if isUpQuality and (not isFull) then
			local name = gModelRune:GetRuneNameByRefId(selRefId)
			local rate = compoundRef.rate
			local rateStr = rate * 100 .. "%"
			local color = gModelGeneral:GetCommonItemColor({itemType = itemType,itemId = selRefId})
			local infoName = name .. "*" .. len
			local colorName = LUtil.FormatColorStr(infoName,color)
			printInfoNR("==== 成功率：" .. rateStr)
			gModelGeneral:OpenUIOrdinTips({refId = 52403,func = func,para = {colorName,rateStr},itemList = runeDataList},true)
		else
			func()
		end
	end
end

function UIEqCompound:InitEvent()
	self:SetWndClick(self.mReturnBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mAutoSelBtn,function() self:OnClickAutoSelFunc() end)
	self:SetWndClick(self.mCompoundBtn,function() self:OnClickCompoundFunc() end)
	self:SetWndClick(self.mHelpBtn,function() GF.OpenWnd("UIBzTips",{refId = 25}) end)
	self:SetWndClick(self.mSkillPreBtn,function() GF.OpenWnd("UIReJNPreView") end)
	self:SetWndClick(self.mSubBtn,function() self:OnClickOptFunc(-1) end)
	self:SetWndClick(self.mAddBtn,function() self:OnClickOptFunc(1) end)
	self:SetWndClick(self.mBarBg,function() GF.OpenWnd("UIReMelting") end)
end

function UIEqCompound:RefreshSelNum()
	local selRuneNum = self._selRuneNum
	self:SetWndText(self.mSelRuneNum,selRuneNum)
end

function UIEqCompound:RefreshData()
	self._selRuneInfoList = {}
	self._selRuneInfoKeyList = {}
	self._selRuneRefId = nil
	self._runeCompoundClick = false

	self._payRefId = nil
	self._payNum = nil

	self:RefreshInfo(true)
	self:RefreshBar()
end

function UIEqCompound:InitText()
	self:SetWndText(self.mSkillPreBtnName,ccClientText(13205))
	self:SetWndButtonText(self.mAutoSelBtn,ccClientText(13204))
	self:SetWndButtonText(self.mCompoundBtn,ccClientText(11316))
	self:SetWndText(self.mXHTxt,ccClientText(11320))
	self:SetWndText(self.mTitle,ccClientText(13203))

	local data = {
		refId = 5102,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
	}
	local emptyList = self:GetCommonEmptyList("_empty1")
	emptyList:RefreshUI(data)


	local uiHyperText = UIHyperText:New()
	uiHyperText:Create(self.mGetRuneTxt)
	local text = uiHyperText:AddHyper(ccClientText(13277),{func = function()
		local jumpItem = gModelRune:GetConfig("jumpItem")
		gModelGeneral:OpenGetWayWnd({itemId = jumpItem,srcWnd = self:GetWndName()})
	end})
	text = LUtil.FormatColorStr(text,"green")
	self:SetWndText(self.mGetRuneTxt,text)
end

function UIEqCompound:OnClickOptFunc(optNum)
	local oldNum = self._selRuneNum
	local newNum = optNum + oldNum
	if newNum > UIEqCompound.RUNE_MAX_NUM or newNum < UIEqCompound.RUNE_SHOWCENTER_NUM then
		return
	end
	self._selRuneNum = newNum
	self:RefreshSelNum()
end

function UIEqCompound:RefreshBar()
	local haveNum,needNum = gModelRune:GetHaveNumOrNeedNum()
	local txt = string.format("%s/%s",haveNum,needNum)
	self:SetWndText(self.mMaterialsNumTxt,txt)

	local showBox = true
	local effectKey = "fx_baoxiang_paiweisai01"
	if haveNum >= needNum then
		showBox = false
		self:CreateWndEffect(self.mBoxEffRoot,effectKey,effectKey,100,false,false)
	else
		self:DestroyWndEffectByKey(effectKey)
	end
	CS.ShowObject(self.mBox,showBox)

	local percentage = haveNum/needNum
	LxUiHelper.SetProgress(self.mBar,percentage)
end

function UIEqCompound:SetIconInfo(trans,itemdata,isLongClick,clickFunc)
	if isLongClick == nil then isLongClick = true end

	local iconTrans = self:FindWndTrans(trans,"Icon")

	local instanceID = trans:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceID)
	baseClass:Create(iconTrans)
	local runeData = {
		refId = itemdata.refId,
		skillId = itemdata.skillId,
		attrId = itemdata.attrId,
	}
	baseClass:SetRuneData(itemdata)
	baseClass:DoApply()

	self:SetWndClick(trans, function()
		if clickFunc then
			clickFunc()
		else
			self:SelectRune(itemdata)
		end
	end)

	if isLongClick then
		self:SetWndLongClick(trans,function()
			local data = {
				runeData = itemdata
			}
			gModelGeneral:OpenRuneInfoTip(data)
		end, 0.5, true)
	end
end

function UIEqCompound:SelectRune(runeData)
	local selRuneInfoList = self._selRuneInfoList
	if not selRuneInfoList then
		selRuneInfoList = {}
		self._selRuneInfoList = selRuneInfoList
	end

	local selRuneInfoKeyList = self._selRuneInfoKeyList
	if not selRuneInfoKeyList then
		selRuneInfoKeyList = {}
		self._selRuneInfoKeyList = selRuneInfoKeyList
	end

	local id = runeData.id
	local refId = runeData.refId

	-- 符文选择状态
	local status = self:CheckRuneStatus(id,refId,true)
	if status ~= UIEqCompound.STATUS_SEL_OK then return end

	local isSel = selRuneInfoKeyList[id] and true or false
	if isSel then
		selRuneInfoKeyList[id] = nil
		local list = {}
		for i,v in ipairs(selRuneInfoList) do
			if id ~= v.id then
				table.insert(list,v)
			end
		end

		selRuneInfoList = list
		self._selRuneInfoList = selRuneInfoList

		local tLen = #list
		if tLen < 1 then
			self._selRuneRefId = nil
		end
	else
		local tLen = #selRuneInfoList
		if tLen < 1 then
			self._selRuneRefId = refId
		end
		table.insert(selRuneInfoList,runeData)
		selRuneInfoKeyList[id] = id
	end

	self:RefreshInfo()
end

function UIEqCompound:RuneCompoundFunc(pb)
	self:CreateWndEffect(self.mRuneEff,"fx_fuwenhechen","fx_fuwenhechen",100,true,false)
	self:RefreshData()
	local result = pb.result
	local itemList = {}
	if result == 1 then
		local item = pb.runeId
		local data = {
			itype = LItemTypeConst.TYPE_RUNE,
			itemId = item,
			count = 1,
		}
		table.insert(itemList,data)
	else
		local rewards = pb.rewards
		for i = 1,#rewards do
			local reward = rewards[i]
			local data = {
				itype = reward.type,
				itemId = reward.itemId,
				count = reward.count
			}
			table.insert(itemList,data)
		end
	end
	self._compountRetList = itemList
	self:TimerStart(self._comRuneAniKey,0.5,false,1)
end

function UIEqCompound:InitData()
	self:RefreshData()

	self._func = self:GetWndArg("func")

	self._selRuneNum = UIEqCompound.RUNE_MAX_NUM

	self._selRuneTransList = {
		{
			runeIcon = self.mRuneIcon1,
			notSelTrans = self.mRuneIcon1NotSel,
		},
		{
			runeIcon = self.mRuneIcon2,
			notSelTrans = self.mRuneIcon2NotSel,
		},
		{
			runeIcon = self.mRuneIcon3,
			notSelTrans = self.mRuneIcon3NotSel,
		},
		{
			runeIcon = self.mRuneIcon4,
			notSelTrans = self.mRuneIcon4NotSel,
		},
		{
			runeIcon = self.mRuneIcon5,
			notSelTrans = self.mRuneIcon5NotSel,
		},
	}
	self._centerRuneTransInfo = {
		runeIcon = self.mRuneIconCenter,
		notSelTrans = self.mRuneIconCenterNotSel,
	}
end

function UIEqCompound:NotEnoughRune()
	GF.ShowMessage(ccClientText(13251))
end

function UIEqCompound:OnTcpReconnect()
	self._runeCompoundClick = false
end

function UIEqCompound:RefreshPayNum()
	local selRuneInfoList = self._selRuneInfoList
	if not selRuneInfoList then
		selRuneInfoList = {}
		self._selRuneInfoList = selRuneInfoList
	end
	local needNum = 0
	local rate = 0
	local color
	local len = #selRuneInfoList
	local ref = gModelRune:GetRuneComposeRef(self._selRuneRefId,len)
	if ref then
		rate = ref.rate
		local composeNeedGlod = ref.composeNeedGlod
		local str = string.split(composeNeedGlod,"=")
		local itemRefId = tonumber(str[2])
		local icon = gModelItem:GetItemIconByRefId(itemRefId)
		if icon then
			self:SetWndEasyImage(self.mPayImg,icon)
		end
		local haveNum = gModelItem:GetNumByRefId(itemRefId)
		needNum = tonumber(str[3])
		color = haveNum >= needNum and "green" or "red"

		self._payRefId = itemRefId
		self._payNum = needNum
	end
	local rateStr = string.replace(ccClientText(13257),rate * 100)
	self:SetWndText(self.mSuccessTxt,rateStr)

	needNum = LUtil.NumberCoversion(needNum)
	if color then
		needNum = LUtil.FormatColorStr(needNum,color)
	end
	self:SetWndText(self.mPayNumTxt,needNum)
end

function UIEqCompound:InitMsg()
	self:WndNetMsgRecv(LProtoIds.RuneMeltingResp,function()
		self:InitRuneList(true)
		self:RefreshBar()
	end)
	self:WndNetMsgRecv(LProtoIds.RuneCompoundResp,function(pb,ret)
		self:RuneCompoundFunc(pb)
	end)
	self:WndNetMsgRecv(LProtoIds.ChangeRuneResp,function(pb,ret)
		self:InitRuneList(true)
	end)
	self:WndEventRecv(EventNames.On_Item_Change,function()

		self:RefreshPayNum()
	end)
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function()
		self._func = nil
	end)
end

function UIEqCompound:RefreshTopRune()
	local selRuneTransList = self._selRuneTransList
	if not selRuneTransList then return end
	local selRuneInfoList = self._selRuneInfoList
	if not selRuneInfoList then
		selRuneInfoList = {}
		self._selRuneInfoList = selRuneInfoList
	end

	for i,v in ipairs(selRuneTransList) do
		local runeData = selRuneInfoList[i]
		local isSel = runeData ~= nil or false

		local runeIcon = v.runeIcon
		if isSel then
			self:SetIconInfo(runeIcon,runeData)
		end

		CS.ShowObject(runeIcon,isSel)
		CS.ShowObject(v.notSelTrans,not isSel)
	end

	local len = #selRuneInfoList
	local show = len >= UIEqCompound.RUNE_SHOWCENTER_NUM and self._selRuneRefId
	if show then
		local ref = gModelRune:GetRuneComposeRef(self._selRuneRefId,len)
		if ref then
			local getRefId = ref.get
			self:SetIconInfo(self.mRuneIconCenter,{refId = getRefId},false,function()
				if ref then
					gModelGeneral:OpenRuneInfoTip({runeId = getRefId})
				end
			end)
		end
	end
	CS.ShowObject(self.mRuneIconCenter,show)
	CS.ShowObject(self.mRuneIconCenterNotSel,not show)
end

function UIEqCompound:InitRuneList(network)
	local list = self:GetRuneList()
	local uiRuneList = self._uiRuneList
	if uiRuneList then
		if network then
			uiRuneList:RefreshList(list)
			local uiList = uiRuneList:GetList()
			uiList:RefreshList(UIListWrap.RefreshMode.Solid)
		else
			uiRuneList:RefreshData(list)
		end
	else
		uiRuneList = self:GetUIScroll("uiRuneList")
		self._uiRuneList = uiRuneList
		uiRuneList:Create(self.mRuneList,list,function(...) self:OnDrawRuneCell(...) end,UIItemList.WRAP)
	end
	local showEmpty = #list < 1
	CS.ShowObject(self.mNoRecord2,showEmpty)
end

function UIEqCompound:GetRuneList()
	local list = gModelRune:GetCompoundRuneList()
	table.sort(list,function(a,b)
		local refId1,refId2 = a.refId,b.refId
		local quality1,quality2 = gModelRune:GetRuneQualityByRefId(refId1),gModelRune:GetRuneQualityByRefId(refId2)
		if quality1 ~= quality2 then
			return quality1 < quality2
		else
			return a.score < b.score
		end
	end)
	return list
end

function UIEqCompound:OnClickAutoSelFunc()
	local selRuneInfoList = self._selRuneInfoList
	if not selRuneInfoList then
		selRuneInfoList = {}
		self._selRuneInfoList = selRuneInfoList
	end
	local selRuneInfoKeyList = self._selRuneInfoKeyList
	if not selRuneInfoKeyList then
		selRuneInfoKeyList = {}
		self._selRuneInfoKeyList = selRuneInfoKeyList
	end
	local selRuneNum = self._selRuneNum
	local len = #selRuneInfoList
	if len >= selRuneNum then
		local num = 0
		local list = {}
		local keyList = {}
		for i,v in ipairs(selRuneInfoList) do
			if num >= selRuneNum then break end
			local id = v.id
			table.insert(list,v)
			keyList[id] = id
			num = num + 1
		end
		self._selRuneInfoList = list
		self._selRuneInfoKeyList = keyList
	else
		selRuneInfoList = {}
		selRuneInfoKeyList = {}
		self._selRuneRefId = nil
		len = 0

		local runeList = {}
		local list = self:GetRuneList()
		for i,v in ipairs(list) do
			local refId = v.refId
			local runeRef = gModelRune:GetRuneInfoByRefId(refId)
			if runeRef then
				local quality = runeRef.quality
				local listData = runeList[quality]
				if not listData then
					listData = {}
					runeList[quality] = listData
				end
				local data = {id = v.id , refId = v.refId}
				table.insert(listData,data)
			end
		end

		local minList = {}
		for k,v in pairs(runeList) do
			local haveNum = table.keysize(v)
			minList[k] = haveNum
		end

		local minQua = 99
		for k,v in pairs(minList) do
			if v >= self._selRuneNum and v >= UIEqCompound.RUNE_SHOWCENTER_NUM and minQua > k then
				minQua = k
			end
		end

		if minQua == 99 then
			for k,v in pairs(minList) do
				if v >= UIEqCompound.RUNE_SHOWCENTER_NUM and minQua > k then minQua = k end
			end
		end

		local qualityList = runeList[minQua] or {}
		local qualityLen = #qualityList
		if qualityLen > 0 then
			for i,v in ipairs(qualityList) do
				if len >= selRuneNum then break end
				local id = v.id
				local refId = v.refId
				local notSel = selRuneInfoKeyList[id] == nil
				local status = self:CheckRuneStatus(id,refId)
				if status == UIEqCompound.STATUS_SEL_OK and notSel then
					if not self._selRuneRefId then
						self._selRuneRefId = refId
					end
					local serverData = gModelRune:GetServerDataById(id)
					if serverData then
						table.insert(selRuneInfoList,serverData)
						selRuneInfoKeyList[id] = id
						len = len + 1
					end
				end
			end
		else
			self:NotEnoughRune()
		end
		self._selRuneInfoList = selRuneInfoList
		self._selRuneInfoKeyList = selRuneInfoKeyList
	end
	self:RefreshInfo()
end

function UIEqCompound:OnTimer(key)
	if key == self._comRuneAniKey then
		gModelWndPop:TryOpenPopWnd("UIAward",{itemList = self._compountRetList})
	end
	self:TimerStop(key)
end

function UIEqCompound:OnDrawRuneCell(list,item,itemdata,itempos)
	local CommonUITrans = self:FindWndTrans(item,"CommonUI")
	local MaskTrans = self:FindWndTrans(item,"Mask")

	self:SetIconInfo(CommonUITrans,itemdata)

	local selRuneInfoKeyList = self._selRuneInfoKeyList
	if not selRuneInfoKeyList then
		selRuneInfoKeyList = {}
		self._selRuneInfoKeyList = selRuneInfoKeyList
	end

	local id = itemdata.id
	local isSel = selRuneInfoKeyList[id] and true or false
	CS.ShowObject(MaskTrans,isSel)
end
------------------------------------------------------------------
return UIEqCompound


