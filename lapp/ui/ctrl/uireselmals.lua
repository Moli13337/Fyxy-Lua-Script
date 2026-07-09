---
--- Created by LCM.
--- DateTime: 2024/3/30 15:08:25
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIReSelMals:LWnd
local UIReSelMals = LxWndClass("UIReSelMals", LWnd)

UIReSelMals.TYPE_SMV = 1			-- 材料选择
UIReSelMals.TYPE_RSV = 2			-- 符文选择

UIReSelMals.TYPE_WEAR = 1 			-- 已穿戴
UIReSelMals.TYPE_BAG = 2 			-- 背包

UIReSelMals.SKILL_ENABLE_NUM = 3	-- 技能可滑动数量
UIReSelMals.ATTR_ENABLE_NUM = 5		-- 属性可滑动数量

UIReSelMals.ICON_LONG_CLICK_TIME = 0.5
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIReSelMals:UIReSelMals()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIReSelMals:OnWndClose()

	self:ExitWndFunc()

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIReSelMals:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIReSelMals:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndText(self.mDesc,ccClientText(24809))
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:InitTabBtnList()
	self:RefreshView()
end

function UIReSelMals:GetSelRuneNum()
	local selRuneKeyList = self._selRuneKeyList
	if not selRuneKeyList then
		selRuneKeyList = {}
		self._selRuneKeyList = selRuneKeyList
	end
	local selNum = 0
	for id,v in pairs(selRuneKeyList) do
		selNum = selNum + 1
	end
	return selNum
end

function UIReSelMals:OnDrawRSVRuneCell(list,item,itemdata,itempos)
	local Rune = self:FindWndTrans(item,"Rune")
	local AutoDiv = self:FindWndTrans(item,"AutoDiv")
	local AttrList = self:FindWndTrans(item,"AttrList")
	local SkillList = self:FindWndTrans(item,"SkillList")
	local UseBtn = self:FindWndTrans(item,"UseBtn")
	local btnNameTrans = self:FindWndTrans(UseBtn,"btnName")
	local HeroIconRoot = self:FindWndTrans(item,"HeroIconRoot")
	local UseTxt = self:FindWndTrans(item,"UseTxt")

	self:CreateRuneIcon(Rune,itemdata)
	self:CreateAutoDiv(AutoDiv,itemdata)
	self:CreateHeroIcon(HeroIconRoot,UseTxt,itemdata)
	self:CreateSkillList(SkillList,itemdata.skillId)
	self:CreateAttrList(AttrList,itemdata.attrId)
	self:SetWndText(btnNameTrans,ccClientText(24925))
	self:SetWndClick(UseBtn,function()
		self:OnClickRSVUseBtnFunc(itemdata)
	end)
end

function UIReSelMals:OnDrawSMVRuneCell(list,item,itemdata,itempos)
	local ItemDivTrans = self:FindWndTrans(item,"ItemDiv")
	local RuneDivTrans = self:FindWndTrans(item,"RuneDiv")
	local itemType = itemdata.itemType
	local isShowItemDiv = itemType == LItemTypeConst.TYPE_ITEM
	local isShowRuneDiv = itemType == LItemTypeConst.TYPE_RUNE
	CS.ShowObject(ItemDivTrans,isShowItemDiv)
	CS.ShowObject(RuneDivTrans,isShowRuneDiv)
	if isShowItemDiv then
		self:CreateSMVItemDiv(ItemDivTrans,itemdata)
	end
	if isShowRuneDiv then
		self:CreateSMVRuneDiv(RuneDivTrans,itemdata)
	end
end

function UIReSelMals:CreateSMVItemDiv(item,itemdata)
	local Item = self:FindWndTrans(item,"Item")
	local ItemName = self:FindWndTrans(item,"AutoDiv/ItemName")
	local ItemDescScroll = self:FindWndTrans(item,"ItemDescScroll")
	local ItemDesc = self:FindWndTrans(ItemDescScroll,"ItemDesc")
	local UseBtn = self:FindWndTrans(item,"UseBtn")
	local btnNameTrans = self:FindWndTrans(UseBtn,"btnName")
	CS.ShowObject(UseBtn,true)

	local refId = itemdata.refId
	local itemName = gModelItem:GetNameByRefId(refId)
	self:SetWndText(ItemName,itemName)

	CS.ShowObject(ItemDescScroll,false)
	local desc = gModelItem:GetDescByRefId(refId)
	self:SetWndText(ItemDesc,desc)

	self:CreateItemIcon(Item,itemdata)

	local id = itemdata.id
	local isSel = self:CheckRuneItemIsSel(id)

	local btnType = isSel and "red_2" or "yellow_2"
	local imgPath = LUtil.GetBtnImg(btnType)
	--self:SetBtnImageAndMat(UseBtn,imgPath,btnNameTrans)
	self:SetWndEasyImage(UseBtn,imgPath)

	local btnName = isSel and ccClientText(24926) or ccClientText(24925)
	self:SetWndText(btnNameTrans,btnName)
	self:SetWndClick(UseBtn,function()
		self:OnClickSMVItemUseBtnFunc(itemdata)
	end)
end

function UIReSelMals:InitTabBtnList()
	local list = self._botBtnTransList
	local uiBotBtnList = self._uiBotBtnList
	if uiBotBtnList then
		uiBotBtnList:RefreshList(list)
	else
		uiBotBtnList = self:GetUIScroll("uiBotBtnList")
		self._uiBotBtnList = uiBotBtnList
		uiBotBtnList:Create(self.mBotBtnList,list,function(...) self:OnDrawBotBtnCell(...) end)
	end
end

function UIReSelMals:CheckSMVOpenViewPage()
	local needRuneRefId = self._needRuneRefId
	if not needRuneRefId then return end
	local selRuneData = self._selRuneData
	local isSel = selRuneData ~= nil
	local selRuneList = self._selRuneList
	local isSelConsume = #selRuneList > 0
	local pageIndex
	if isSelConsume then
--[[		local heroId = selRuneData.heroId
		local isBag = heroId == "0"
		pageIndex = isBag and UIReSelMals.TYPE_BAG or UIReSelMals.TYPE_WEAR]]

		local isBag = false
		local serverData
		for i,v in ipairs(selRuneList) do
			if isBag then break end
			serverData = gModelRune:GetServerDataById(v)
			if serverData then
				isBag = serverData.heroId == "0"
			end
		end
		pageIndex = isBag and UIReSelMals.TYPE_BAG or UIReSelMals.TYPE_WEAR
	else
		local list = gModelRune:GetSMVRuneListByRuneRefIdAndStatus(needRuneRefId,2,selRuneData,self._openPage)
		local isHaveRune = #list > 0
		if isHaveRune then
			pageIndex = UIReSelMals.TYPE_BAG
		end
	end
	if pageIndex and self._page ~= pageIndex then
		self:OnClickTabBtnFunc(pageIndex)
	end
end

function UIReSelMals:InitRSVRuneList()
--[[	local list = self:GetRSVRuneList()
	local uiRSVRuneList = self._uiRSVRuneList
	if uiRSVRuneList then
		uiRSVRuneList:RefreshList(list)
	else
		uiRSVRuneList = self:GetUIScroll("uiRSVRuneList")
		self._uiRSVRuneList = uiRSVRuneList
		uiRSVRuneList:Create(self.mRSVRuneList,list,function(...) self:OnDrawRSVRuneCell(...) end,UIItemList.WRAP,false)
	end
	local isEmpty = #list < 1
	CS.ShowObject(self.mRSVNoRecord2,isEmpty)
	local uiList = uiRSVRuneList:GetList()
	uiList:RefreshList(UIListWrap.RefreshMode.Solid)]]
	local list = self:GetRSVRuneList()
	local uiRSVRuneList = self._uiRSVRuneList
	if uiRSVRuneList then
		uiRSVRuneList:RefreshList(list)
	else
		uiRSVRuneList = self:GetUIScroll("uiRSVRuneList")
		self._uiRSVRuneList = uiRSVRuneList
		uiRSVRuneList:Create(self.mRSVRuneList, list, function(...)
			self:OnDrawRSVRuneCell(...)
		end, UIItemList.SUPER,false)
	end
	local isEmpty = #list < 1
	CS.ShowObject(self.mRSVNoRecord2,isEmpty)
	uiRSVRuneList:DrawAllItems()
end

function UIReSelMals:InitSMVData()
	self._needRuneRefId = self:GetWndArg("needRuneRefId")
	self._needRuneNum = self:GetWndArg("needRuneNum")
	local selRuneList = self:GetWndArg("selRuneList")
	self._selRuneList = selRuneList or {}
	local selRuneItemList = self:GetWndArg("selRuneItemList")
	self._selRuneItemList = selRuneItemList or {}

	local selRuneKeyList = {}
	for i,v in ipairs(selRuneList) do
		selRuneKeyList[v] = v
	end
	self._selRuneKeyList = selRuneKeyList

	local selRuneItemKeyList = {}
	for i,v in ipairs(selRuneItemList) do
		selRuneItemKeyList[v.id] = v
	end
	self._selRuneItemKeyList = selRuneItemKeyList
end

function UIReSelMals:OnDrawBotBtnCell(list,item,itemdata,itempos)
	local TabBtn = self:FindWndTrans(item,"TabBtn")
	local btnIndex = itemdata.btnIndex
	local isSel = btnIndex == self._page and LWnd.StateOn or LWnd.StateOff
	self:SetWndTabStatus(TabBtn,isSel)
	self:SetWndTabText(TabBtn,itemdata.btnName)
	self:SetWndClick(TabBtn,function()
		self:OnClickTabBtnFunc(btnIndex)
	end)
end

function UIReSelMals:OnDrawSkillCell(list,item,itemdata,itempos)
	local SkillName = self:FindWndTrans(item,"SkillName")
	local skillId = itemdata
	local runeSkillRef = gModelRune:GetSkillInfoByRefId(skillId)
	if runeSkillRef then
		local skill = tonumber(runeSkillRef.SkillId)
		local skillRef = gModelHero:GetSkillByStarId(skill)
		local skillName = "没有名字"
		if skillRef then skillName = ccLngText(skillRef.name) end
		skillName = "[" .. skillName .. "]"
		local uiHyperText = UIHyperText:New()
		uiHyperText:Create(SkillName)
		local clickFunc = function()
			local skillType = runeSkillRef.skillType
			local refId = runeSkillRef.refId
			gModelRune:OpenNewRuneSkillWnd(refId,skillType)
		end
		skillName = uiHyperText:AddHyper(skillName,{func = clickFunc})
		self:SetWndText(SkillName,skillName)
		local skillNameColor = "139057ff"
		self:SetXUITextTransColor(SkillName,skillNameColor)

		self:InitTextModeWithLanguage(SkillName,clickFunc)
	end


end

function UIReSelMals:OnClickSMVUseBtnFunc(itemdata)
	local runeId = itemdata.id
	local selRuneKeyList = self._selRuneKeyList
	if not selRuneKeyList then
		selRuneKeyList = {}
		self._selRuneKeyList = selRuneKeyList
	end

	local refreshFunc = function()
		if not self:IsWndValid() then return end
		self:RefreshSMVSelNum()
		self:InitSMVRuneList(true)
	end

	local func = function()
		if not self:IsWndValid() then return end
		--if isWear then
		--	gModelRune:OnRuneUnloadReq(heroId,runeId)
		--end
		local isSel = selRuneKeyList[runeId] ~= nil
		if isSel then
			selRuneKeyList[runeId] = nil
		else
			local isSelFull = self:CheckIsSelFull(true)
			if isSelFull then
				return
			end
			selRuneKeyList[runeId] = runeId
		end
		self._selRuneKeyList = selRuneKeyList
		refreshFunc()
	end

	local isSel = self:CheckRuneIsSel(runeId)
	if isSel then
		selRuneKeyList[runeId] = nil
		self._selRuneKeyList = selRuneKeyList
		refreshFunc()
	else
		local isSelFull = self:CheckIsSelFull(true)
		if not isSelFull then
			local serverData = gModelRune:GetServerDataById(runeId)
			local heroId = serverData.heroId
			local isWear = heroId ~= "0"
			if isWear then
				local heroServerData = gModelHero:GetHeroServerDataById(heroId)
				if heroServerData then
					local name = gModelHero:GetHeroNameByRefId(heroServerData.refId)
					gModelGeneral:OpenUIOrdinTips({refId = 52406,func = func,para = {name}})
				else
					func()
				end
			else
				func()
			end
		end
	end
end

function UIReSelMals:CreateItemIcon(trans,itemdata)
	local InstanceID = trans:GetInstanceID()
	local baseClass = self:GetCommonIcon(InstanceID)
	local ItemIcon = self:FindWndTrans(trans,"ItemIcon")
	baseClass:Create(ItemIcon)
	baseClass:SetCommonReward(itemdata.itemType,itemdata.refId,itemdata.num)
	baseClass:EnableShowNum(false)
	self:SetIconClickScale(ItemIcon, true)
	baseClass:DoApply()

	if self._longClick then
		self:SetWndLongClick(ItemIcon,function()
			gModelGeneral:ShowCommonItemTipWnd(itemdata)
		end,UIReSelMals.ICON_LONG_CLICK_TIME,false)
	else
		self:SetWndClick(ItemIcon,function()
			gModelGeneral:ShowCommonItemTipWnd(itemdata)
		end)
	end
end

function UIReSelMals:CreateRuneIcon(trans,runeData)
	local InstanceID = trans:GetInstanceID()
	local baseClass = self:GetCommonIcon(InstanceID)
	local RuneIcon = self:FindWndTrans(trans,"RuneIcon")
	baseClass:Create(RuneIcon)
	self:SetIconClickScale(RuneIcon, true)
	baseClass:SetRuneData(runeData)
	baseClass:DoApply()
	if self._longClick then
		self:SetWndLongClick(RuneIcon,function()
			local data = {runeData = runeData}
			gModelGeneral:OpenRuneInfoTip(data)
		end,UIReSelMals.ICON_LONG_CLICK_TIME,false)
	else
		self:SetWndClick(RuneIcon,function()
			local data = {runeData = runeData}
			gModelGeneral:OpenRuneInfoTip(data)
		end)
	end
end

function UIReSelMals:CreateSMVRuneDiv(item,itemdata)
	local Rune = self:FindWndTrans(item,"Rune")
	local AutoDiv = self:FindWndTrans(item,"AutoDiv")
	local AttrList = self:FindWndTrans(item,"AttrList")
	local SkillList = self:FindWndTrans(item,"SkillList")
	local UseBtn = self:FindWndTrans(item,"UseBtn")
	local btnNameTrans = self:FindWndTrans(UseBtn,"btnName")
	local UseImg = self:FindWndTrans(item,"UseImg")
	CS.ShowObject(UseImg,false)
	CS.ShowObject(UseBtn,true)
	local HeroIconRoot = self:FindWndTrans(item,"HeroIconRoot")
	local UseTxt = self:FindWndTrans(item,"UseTxt")

	self:CreateRuneIcon(Rune,itemdata)
	self:CreateAutoDiv(AutoDiv,itemdata)
	self:CreateHeroIcon(HeroIconRoot,UseTxt,itemdata)
	self:CreateSkillList(SkillList,itemdata.skillId)
	self:CreateAttrList(AttrList,itemdata.attrId)

	local id = itemdata.id
	local isSel = self:CheckRuneIsSel(id)
	local btnType = isSel and "red_2" or "yellow_2"
	local imgPath = LUtil.GetBtnImg(btnType)
	--self:SetBtnImageAndMat(UseBtn,imgPath,btnNameTrans)
	self:SetWndEasyImage(UseBtn,imgPath)

	local btnName = isSel and ccClientText(24926) or ccClientText(24925)
	self:SetWndText(btnNameTrans,btnName)
	self:SetWndClick(UseBtn,function()
		self:OnClickSMVUseBtnFunc(itemdata)
	end)
end

function UIReSelMals:InitRSVData()
end

function UIReSelMals:CreateAutoDiv(trans,runeData)
	local RuneName = self:FindWndTrans(trans,"RuneName")
	local name = gModelRune:GetRuneNameByServerData(runeData)
	self:SetWndText(RuneName,name)
	local color = gModelRune:GetRuneColorByRefId(runeData.refId)
	self:SetXUITextTransColor(RuneName,color)

	local ScoreTxt = self:FindWndTrans(trans,"ScoreTxt")
	local score = math.floor(runeData.score + 0.5)
	local str = string.replace(ccClientText(13263) or "%s",score)
	self:SetWndText(ScoreTxt,str)
end

function UIReSelMals:RefreshSMVSelNum()
	local needRuneNum = self._needRuneNum or 1
	local selNum = self:GetSelAllNum()
	local isSelFull = selNum >= needRuneNum
	local color = isSelFull and "lightGreen" or "lightRed"
	local selNumStr = LUtil.FormatColorStr(selNum,color)
	local str = string.replace(ccClientText(24812),selNumStr,needRuneNum)
	self:SetTextTile(self.mSMVText,str)
end
---------------------------------------------------------
function UIReSelMals:RefreshRuneList()
	local openType = self._openType
	if openType == UIReSelMals.TYPE_SMV then
		self:InitSMVRuneList()
	elseif openType == UIReSelMals.TYPE_RSV then
		self:InitRSVRuneList()
	end
end

function UIReSelMals:CheckRuneItemIsSel(id)
	local selRuneItemKeyList = self._selRuneItemKeyList
	if not selRuneItemKeyList then
		selRuneItemKeyList = {}
		self._selRuneItemKeyList = selRuneItemKeyList
	end
	return selRuneItemKeyList[id] ~= nil
end

function UIReSelMals:InitSMVEmptyList()
	local data = {
		refId = 5104,
		IntroTran = self.mSMVEmptyText,
		TextBgTran = self.mSMVEmptyTextBg,
		IconTran = self.mSMVEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("SMVEmpty")
	emptyList:RefreshUI(data)
end

function UIReSelMals:OnClickSMVItemUseBtnFunc(itemdata)
	local id = itemdata.id
	local selRuneItemKeyList = self._selRuneItemKeyList
	if not selRuneItemKeyList then
		selRuneItemKeyList = {}
		self._selRuneItemKeyList = selRuneItemKeyList
	end

	local refreshFunc = function()
		if not self:IsWndValid() then return end
		self:RefreshSMVSelNum()
		self:InitSMVRuneList(true)
	end

	local func = function()
		if not self:IsWndValid() then return end
		selRuneItemKeyList[id] = itemdata
		self._selRuneItemKeyList = selRuneItemKeyList
		refreshFunc()
	end

	local isSel = self:CheckRuneItemIsSel(id)
	if isSel then
		selRuneItemKeyList[id] = nil
		self._selRuneItemKeyList = selRuneItemKeyList
		refreshFunc()
	else
		local isSelFull = self:CheckIsSelFull(true)
		if not isSelFull then
			func()
		end
	end
end

function UIReSelMals:ExitWndFunc()
	local callFunc = self._callFunc
	if callFunc then
		local openType = self._openType
		if openType == UIReSelMals.TYPE_SMV then
			local selRuneKeyList = self._selRuneKeyList
			if not selRuneKeyList then
				selRuneKeyList = {}
				self._selRuneKeyList = selRuneKeyList
			end
			local selRuneItemKeyList = self._selRuneItemKeyList
			if not selRuneItemKeyList then
				selRuneItemKeyList = {}
				self._selRuneItemKeyList = selRuneItemKeyList
			end
			local list = {}
			for id,v in pairs(selRuneKeyList) do
				table.insert(list,id)
			end
			local itemList = {}
			for id,v in pairs(selRuneItemKeyList) do
				table.insert(itemList,v)
			end
			callFunc(list,itemList)
		elseif openType == UIReSelMals.TYPE_RSV then
			local selRuneData = self._selRuneData
			if selRuneData ~= nil then
				callFunc(selRuneData)
			end
		end
	end
	self._callFunc = nil
end

function UIReSelMals:OnClickTabBtnFunc(btnIndex)
	if btnIndex == self._page then return end
	self._page = btnIndex
	self:RefreshTabBtnFunc()
end

function UIReSelMals:CreateSkillList(trans,list)
	local key = trans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(trans,list,function(...) self:OnDrawSkillCell(...) end)
	end
	local len = #list
	local isEnable = len >= UIReSelMals.SKILL_ENABLE_NUM
	uiList:EnableScroll(isEnable)
end

function UIReSelMals:InitData()
	local openType = self:GetWndArg("openType")
	if not openType then
		openType = UIReSelMals.TYPE_SMV
	end
	self._openType = openType
	self._openPage = self:GetWndArg("openPage")
	self._callFunc = self:GetWndArg("callFunc")

	local selRuneData = self:GetWndArg("selRuneData")
	self._selRuneData = selRuneData

	local page = self:GetWndArg("page")
	if not page then
		page = UIReSelMals.TYPE_WEAR
	end
	self._page = page

	self._botBtnTransList = {
		[UIReSelMals.TYPE_WEAR] = {
			btnName = ccClientText(24810),
			btnIndex = UIReSelMals.TYPE_WEAR,
			refreshFunc = function()
				self:RefreshRuneList()
			end,
		},
		[UIReSelMals.TYPE_BAG] = {
			btnName = ccClientText(24811),
			btnIndex = UIReSelMals.TYPE_BAG,
			refreshFunc = function()
				self:RefreshRuneList()
			end,
		},
	}

	local longClick = gModelRune:GetConfig("longClick")
	if not longClick then
		longClick = 0
	end
	local isLongClick = longClick == 1
	self._longClick = isLongClick
end
---------------------------------------------------------
function UIReSelMals:RefreshView()
	local openType = self._openType
	if openType == UIReSelMals.TYPE_SMV then
		self:RefreshSMV()
	elseif openType == UIReSelMals.TYPE_RSV then
		self:RefreshRSV()
	end
end

function UIReSelMals:InitSMVRuneList(isClick)
--[[	local list = self:GetSMVRuneList()
	local uiSMVRuneList = self._uiSMVRuneList
	if uiSMVRuneList then
		if isClick then
			uiSMVRuneList:RefreshData(list)
		else
			uiSMVRuneList:RefreshList(list)
		end
	else
		uiSMVRuneList = self:GetUIScroll("uiSMVRuneList")
		self._uiSMVRuneList = uiSMVRuneList
		uiSMVRuneList:Create(self.mSMVRuneList,list,function(...) self:OnDrawSMVRuneCell(...) end,UIItemList.WRAP,false)
	end
	local isEmpty = #list < 1
	CS.ShowObject(self.mSMVNoRecord,isEmpty)
	if isClick then
		return
	end
	local uiList = uiSMVRuneList:GetList()
	uiList:RefreshList(UIListWrap.RefreshMode.Solid)]]


	local list = self:GetSMVRuneList()
	local uiSMVRuneList = self._uiSMVRuneList
	if uiSMVRuneList then
		if isClick then
			uiSMVRuneList:RefreshData(list)
		else
			uiSMVRuneList:RefreshList(list)
		end
	else
		uiSMVRuneList = self:GetUIScroll("uiSMVRuneList")
		self._uiSMVRuneList = uiSMVRuneList
		uiSMVRuneList:Create(self.mSMVRuneList,list,function(...) self:OnDrawSMVRuneCell(...) end,UIItemList.SUPER,false)
	end
	local isEmpty = #list < 1
	CS.ShowObject(self.mSMVNoRecord,isEmpty)
	--if isClick then
		--return
	--end
	uiSMVRuneList:DrawAllItems()
end
---------------------------------------------------------
function UIReSelMals:RefreshRSVTop()
	local selRuneData = self._selRuneData
	if not selRuneData then return end
	local trans = self.mRSVTop
	local Rune = self:FindWndTrans(trans,"Rune")
	local AutoDiv = self:FindWndTrans(trans,"AutoDiv")
	local AttrList = self:FindWndTrans(trans,"AttrList")
	local SkillList = self:FindWndTrans(trans,"SkillList")
	local HeroIconRoot = self:FindWndTrans(trans,"HeroIconRoot")
	local UseTxt = self:FindWndTrans(trans,"UseTxt")
	self:CreateRuneIcon(Rune,selRuneData)
	self:CreateAutoDiv(AutoDiv,selRuneData)
	self:CreateHeroIcon(HeroIconRoot,UseTxt,selRuneData)
	self:CreateSkillList(SkillList,selRuneData.skillId)
	self:CreateAttrList(AttrList,selRuneData.attrId)
end

function UIReSelMals:InitRSVEmptyList()
	local data = {
		refId = 5103,
		IntroTran = self.mRSVEmptyText,
		TextBgTran = self.mRSVEmptyTextBg,
		IconTran = self.mRSVEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("RSVEmpty")
	emptyList:RefreshUI(data)
end

function UIReSelMals:RefreshSMV()
	self:SetWndText(self.mSMVlblBiaoti,ccClientText(24805))
	CS.ShowObject(self.mSelMaterialsView,true)

	self:InitSMVEmptyList()
	self:InitSMVData()
	self:CheckSMVOpenViewPage()
	self:RefreshSMVSelNum()
	self:InitSMVRuneList()
end

function UIReSelMals:CheckIsSelFull(showTip)
	local isSelFull = self:IsSelFull()
	if showTip and isSelFull then
		GF.ShowMessage(ccClientText(10031))
	end
	return isSelFull
end

function UIReSelMals:CreateHeroIcon(trans,useTxtTrans,runeData)
	local heroIconTrans = self:FindWndTrans(trans,"Icon")
	local heroId = runeData.heroId
	local showHeroIcon = heroId ~= "" and heroId ~= "0"
	if showHeroIcon then
		local InstanceID = trans:GetInstanceID()
		local baseClass = self:GetCommonIcon(InstanceID)
		baseClass:Create(heroIconTrans)
		baseClass:SetHeroPlayer(heroId)
		baseClass:DoApply()
	end
	CS.ShowObject(heroIconTrans,showHeroIcon)
	CS.ShowObject(useTxtTrans,showHeroIcon)
	self:SetWndText(useTxtTrans,ccClientText(18334))
	self:InitTextLineWithLanguage(useTxtTrans,-40)
end

function UIReSelMals:RefreshRSV()
	self:SetWndText(self.mRSVlblBiaoti,ccClientText(24903))
	CS.ShowObject(self.mRuneSelView,true)

	self:InitRSVEmptyList()
	self:InitRSVData()
	self:RefreshRSVTop()
	self:InitRSVRuneList()
end

function UIReSelMals:InitMsg()

end

function UIReSelMals:CheckRuneIsSel(id)
	local selRuneKeyList = self._selRuneKeyList
	if not selRuneKeyList then
		selRuneKeyList = {}
		self._selRuneKeyList = selRuneKeyList
	end
	return selRuneKeyList[id] ~= nil
end

function UIReSelMals:GetSelRuneItemNum()
	local selRuneItemKeyList = self._selRuneItemKeyList
	if not selRuneItemKeyList then
		selRuneItemKeyList = {}
		self._selRuneItemKeyList = selRuneItemKeyList
	end
	local selRuneItemNum = 0
	for k,v in pairs(selRuneItemKeyList) do
		selRuneItemNum = selRuneItemNum + 1
	end
	return selRuneItemNum
end

function UIReSelMals:IsSelFull()
	local selNum = self:GetSelAllNum()
	local needRuneNum = self._needRuneNum or 1
	return selNum >= needRuneNum
end

function UIReSelMals:OnDrawAttrCell(list,item,itemdata,itempos)
	local Attr = self:FindWndTrans(item,"Attr")
	local runeAttrRef = gModelRune:GetAttrInfoByRefId(itemdata)
	if runeAttrRef then
		local attr = runeAttrRef.attr
		local first = attr[1] or {}
		local attrRefId,attrType,attrValue = first.attrRefId,first.attrType,first.attrVal
		local attrName = gModelHero:GetAttributeNameById(attrRefId)
		local value = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId,attrType,attrValue)
		local str = string.replace(ccClientText(13264),attrName,value)
		self:SetWndText(Attr,str)
	end
end

function UIReSelMals:GetRSVRuneList()
	local list = gModelRune:GetRSVRuneListByRuneRefIdAndStatus(self._page,self._selRuneData,self._openPage)
	return list
end

function UIReSelMals:RefreshTabBtnFunc()
	local uiBotBtnList = self._uiBotBtnList
	if uiBotBtnList then
		local uiList = uiBotBtnList:GetList()
		uiList:RefreshList()
	end
	local botBtnTransList = self._botBtnTransList
	if not botBtnTransList then return end
	local btnInfo = botBtnTransList[self._page]
	if not btnInfo then return end
	local refreshFunc = btnInfo.refreshFunc
	if refreshFunc then refreshFunc() end
end

function UIReSelMals:GetSelAllNum()
	local selRuneNum = self:GetSelRuneNum()
	local selRuneItemNum = self:GetSelRuneItemNum()
	local selNum = selRuneNum + selRuneItemNum
	return selNum
end

function UIReSelMals:CreateAttrList(trans,list)
	local key = trans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(trans,list,function(...) self:OnDrawAttrCell(...) end)
	end
	local len = #list
	local isEnable = len >= UIReSelMals.ATTR_ENABLE_NUM
	uiList:EnableScroll(isEnable)
end

function UIReSelMals:OnClickRSVUseBtnFunc(runeData)
	self._selRuneData = runeData
	self:WndClose()
end
---------------------------------------------------------
function UIReSelMals:GetSMVRuneList()
	local list = {}
	local needRuneRefId = self._needRuneRefId
	if needRuneRefId then
		list = gModelRune:GetSMVRuneListByRuneRefIdAndStatus(needRuneRefId,self._page,self._selRuneData,self._openPage)
	end
	return list
end

function UIReSelMals:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mSMVBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mRSVBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end
------------------------------------------------------------------
return UIReSelMals


