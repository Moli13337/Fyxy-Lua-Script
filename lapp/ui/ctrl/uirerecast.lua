---
--- Created by Administrator.
--- DateTime: 2023/10/7 18:16:59
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIReRecast:LWnd
local UIReRecast = LxWndClass("UIReRecast", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIReRecast:UIReRecast()
	---@type CommonIcon
	self._runeIconCls = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIReRecast:OnWndClose()
	if self._runeIconCls then
		self._runeIconCls:Destroy()
		self._runeIconCls = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIReRecast:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIReRecast:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitData()
	self:InitEvent()
	self:InitMsg()
	self:Refresh()
end

function UIReRecast:RefreshBtn()
	local serverData = self._serverData
	local show = false
	if (not table.isempty(serverData.nextSkillId)) or (not table.isempty(serverData.nextAttrId)) then
		show = true
	end
	CS.ShowObject(self.mSaveBtn,show)
	local saveBtnWay = self.mSaveBtn.localPosition
	if show then
		self.mRecastBtn.localPosition = Vector3(-saveBtnWay.x,saveBtnWay.y,saveBtnWay.z)
	else
		self.mRecastBtn.localPosition = Vector3(0,saveBtnWay.y,saveBtnWay.z)
	end
end

--function UIReRecast:OnDrawAttrCell(list, item, itemdata, itempos, fromHeadTail)
function UIReRecast:OnDrawAttrCell(list,item, itemdata, itempos)
	local runeAttrRef = gModelRune:GetAttrInfoByRefId(itemdata)
	if runeAttrRef then
		local attr = runeAttrRef.attr
		attr = string.split(attr,"=")
		local attrRefId,attrType,attrValue = tonumber(attr[1]),tonumber(attr[2]),tonumber(attr[3])
		local AttrIconTrans = CS.FindTrans(item,"AttrIcon")
		if AttrIconTrans then
			local attrIcon = gModelHero:GetAttributeIconById(attrRefId)
			self:SetWndEasyImage(AttrIconTrans,attrIcon)
		end
		local AttrNameTrans = CS.FindTrans(item,"AttrName")
		if AttrNameTrans then
			local attrName = gModelHero:GetAttributeNameById(attrRefId)
			self:SetWndText(AttrNameTrans,attrName)
		end
		local AttrValueTrans = CS.FindTrans(item,"AttrValue")
		if AttrValueTrans then
			--if attrType == 2 then attrValue = attrValue .. "%" end
			attrValue = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId,attrType,attrValue)
			self:SetWndText(AttrValueTrans,attrValue)
		end
	end
end
------------------------------------------- 属性列表 -------------------------------------------


------------------------------------------- 技能列表 -------------------------------------------
function UIReRecast:RefreshCurSkillList()
	local serverData = self._serverData
	local curAttrList = serverData.skillId

	if self._uiCurSkillList then
		self._uiCurSkillList:RefreshList(curAttrList)
	else
		self._uiCurSkillList = self:GetUIScroll("curSkillList")
		self._uiCurSkillList:Create(self.mCurSkillList,curAttrList,function(...) self:OnDrawSkillCell(...) end,UIItemList.WRAP)
		self._uiCurSkillList:EnableScroll(false)
	end
end

function UIReRecast:InitMsg()
	self:WndNetMsgRecv(LProtoIds.RuneRecastResp, function(pb,ret)
		-- 重铸
		local runeId = pb.runeId
		self._runeId = runeId
		self._serverData = gModelRune:GetServerDataById(runeId)
		self:Refresh(true,true)
		self._sendMsg = false
	end)
	self:WndNetMsgRecv(LProtoIds.RuneRecastSaveResp, function(pb,ret)
		-- 保存
		local runeId = pb.runeId
		self._runeId = runeId
		self._serverData = gModelRune:GetServerDataById(runeId)
		self:Refresh(true)
		self._sendMsg = false
	end)
	self:WndEventRecv(EventNames.On_Item_Change,function()
		self:Refresh(true)
		self._sendMsg = false
	end)
	self:WndEventRecv(EventNames.NET_ERROR_CODE,function(code,error, argList)
		self._sendMsg = false
	end)
end

------------------------------------------- 道具列表 -------------------------------------------
function UIReRecast:InitItemList()
	local uiItemList = self._uiItemList
	if not uiItemList then
		uiItemList = UIListEasy:New()
		uiItemList:Create(self,self.mItemList)
		uiItemList:SetFuncOnItemDraw(function(...)
			self:OnDrawItemCell(...)
		end)
		self._uiItemList = uiItemList
	end
	uiItemList:RemoveAll()
	self._itemNumTransList = {}
	self._itemIconTransList = {}
	local itemList = self:GetItemList()
	self._itemList = itemList
	for i,v in ipairs(itemList) do
		uiItemList:AddData(i,v)
	end
	uiItemList:RefreshList()
end

function UIReRecast:GetItemList()
	local itemList ={}
	local needItemStr = ""
	if self._selectType == 1 then
		needItemStr = self._ref.recastNeedItem
	elseif self._selectType == 2 then
		needItemStr = self._ref.recastNeedItem
		needItemStr = needItemStr .. "," .. self._ref.luckyRecastItem
	elseif self._selectType == 3 then
		needItemStr = self._ref.recastNeedItem
		needItemStr = needItemStr .. "," .. self._ref.godRecastItem
	end
	needItemStr = string.split(needItemStr,",")
	for i,v in ipairs(needItemStr) do
		local temp = string.split(v,"=")
		local data = {itype = tonumber(temp[1]),refId = tonumber(temp[2]),num = tonumber(temp[3])}
		table.insert(itemList,data)
	end
	return itemList
end

function UIReRecast:RuneRecastFunc()
	-- 重铸
	printInfoN("===================== " .. self._selectType)
	if self._sendMsg then return end
	local sendMsg = false
	if self._contentShow then
		if self._lastNum > 0 then
			sendMsg = true
		else
			local accumulateFixedSkill = self._ref.accumulateFixedSkill
			GF.OpenWnd("UIReJNSel",{runeId = self._runeId,selectType = 4,skillList = accumulateFixedSkill})
		end
	else
		sendMsg = true
	end
	if sendMsg then
		local itemList = self._itemList
		if itemList then
			for i,v in ipairs(itemList) do
				local refId = v.refId
				local haveNum = gModelItem:GetNumByRefId(refId)
				if haveNum < v.num then
					gModelGeneral:OpenGetWayWnd({itemId = refId,srcWnd = self:GetWndName()})
					return
				end
			end
		end
		gModelRune:OnRuneRecastReq(self._runeId,self._selectType)
		self._sendMsg = true
	end
end
------------------------------------------- 选择列表 -------------------------------------------

function UIReRecast:RefreshContent(index)
	local serverData = self._serverData
	local recast = serverData.recast
	local contentShow = self._contentShow
	local subNum = contentShow - recast
	local percentage = recast / contentShow
	LxUiHelper.SetProgress(self.mBar,percentage)
	local numStr = string.format("%s/%s",recast,contentShow)
	self:SetWndText(self.mBarNum,numStr)
	if subNum <= 0 then self:SelectEvent(1) end
	self._lastNum = subNum



	local str = (index and self._selectStrList[index]) or ccClientText(13216)
	if subNum == 0 then
		str = ccClientText(13270)
	else
		str = string.replace(str,subNum,"")
	end
	--self:SetWndText(self.mRecastNumTxt,str)


	local uiHyperText = UIHyperText:New()
	uiHyperText:Create(self.mRecastNumTxt)
	local skillTitle = ccClientText(13217)
	skillTitle = uiHyperText:AddHyper(skillTitle,{func = function()
		GF.OpenWnd("UIReJNPreView",{page = 3})
	end})

	str = str..LUtil.FormatColorStr(skillTitle,"darkYellow")
	self:SetWndText(self.mRecastNumTxt,str)

	self:InitTextSizeWithLanguage(self.mRecastNumTxt,-4)
end

--function UIReRecast:OnDrawSelectCell(list, item, itemdata, itempos, fromHeadTail)
function UIReRecast:OnDrawSelectCell(list,item, itemdata, itempos)
	local btnTrans = CS.FindTrans(item,"Btn")
	if btnTrans then
		local GouTrans = CS.FindTrans(btnTrans,"Gou")
		if GouTrans then
			self._gouTransList[itempos] = GouTrans
			self:SetWndClick(btnTrans,function()
				self:SelectEvent(itemdata,true)
			end)
			if self._selectType == itemdata then
				CS.ShowObject(GouTrans,true)
			else
				CS.ShowObject(GouTrans,false)
			end
		end
	end
	local recastNumTxtTrans = CS.FindTrans(item,"RecastNumTxt")
	if recastNumTxtTrans then
		local txtId = self._titleList[itemdata]
		local txt = ccClientText(txtId)
		self:SetWndText(recastNumTxtTrans,txt)
	end
end

function UIReRecast:InitData()
	local runeId = self:GetWndArg("runeId")
	self._runeId = runeId
	local serverData = gModelRune:GetServerDataById(runeId)
	self._serverData = serverData
	if serverData then
		local refId = serverData.refId
		local runeAttrRef = gModelRune:GetRuneInfoByRefId(refId)
		self._ref = runeAttrRef
	end

	self._titleList = {13218,13219,13220}
	self._selectType = nil
	self._gouTransList = {}
	self._contentShow = nil
	self._lastNum = nil
	self._itemList = {}
	self._itemIconTransList = {}
	self._itemNumTransList = {}
	self._selectStrList = {ccClientText(13216),ccClientText(13255),ccClientText(13256)}
end

function UIReRecast:SetRunIcon(runeIconTrans, runeData)
	local runeIconCls = self._runeIconCls
	if not runeIconCls then
		runeIconCls = CommonIcon:New()
		self._runeIconCls = runeIconCls
		runeIconCls:Create(runeIconTrans)
	end
	runeIconCls:SetRuneData(runeData)
	runeIconCls:DoApply()
end
------------------------------------------- 技能列表 -------------------------------------------


------------------------------------------- 选择列表 -------------------------------------------
function UIReRecast:RefreshSelectList()
	local dataList = {}
	local runeRef = self._ref
	if runeRef then
		local recastType = runeRef.recastType
		local recastTypeList = string.split(recastType,",")
		for i = 1,3 do
			local v = tonumber(recastTypeList[i])
			if v ~= 0 then
				if not self._selectType then self._selectType = v end
				table.insert(dataList,i)
			end
		end
		local showContent = tonumber(recastTypeList[4])
		local showRuneDesc = false
		if showContent ~= 0 then
			showRuneDesc = true
			self._contentShow = runeRef.recastNum - 1
		end
		CS.ShowObject(self.mRecastNumTxt,showRuneDesc)
		CS.ShowObject(self.mRuneBarBg,showRuneDesc)
	end
	if self._uiSelectList then
		self._uiSelectList:RefreshList(dataList)
	else
		self._uiSelectList = self:GetUIScroll("uiSelectList")
		self._uiSelectList:Create(self.mSelectList,dataList,function(...) self:OnDrawSelectCell(...) end)
		self._uiSelectList:EnableScroll(false)
	end
end

function UIReRecast:SelectEvent(index,click)
	if self._lastNum == 0 then
		if click then
			GF.ShowMessage(ccClientText(13276))
		end
		return
	end
	local old = self._selectType
	if old == index then return end

	local oldGouTrans = self._gouTransList[old]
	if oldGouTrans then CS.ShowObject(oldGouTrans,false) end

	self._selectType = index
	local nexGouTrans = self._gouTransList[index]
	if nexGouTrans then CS.ShowObject(nexGouTrans,true) end
	self:RefreshContent(index)
	self:InitItemList()
end

------------------------------------------- 属性列表 -------------------------------------------
function UIReRecast:RefreshCurAttrList()
	local serverData = self._serverData
	local curAttrList = serverData.attrId
	if self._uiCurList then
		self._uiCurList:RefreshList(curAttrList)
	else
		self._uiCurList = self:GetUIScroll("curList")
		self._uiCurList:Create(self.mCurAttrList,curAttrList,function(...) self:OnDrawAttrCell(...) end,UIItemList.WRAP)
		self._uiCurList:EnableScroll(false)
	end
end

function UIReRecast:RefreshNextSkillList()
	local dataList = {}
	local serverData = self._serverData
	local refId = serverData.refId
	local ref = gModelRune:GetRuneInfoByRefId(refId)
	if ref then
		local showSkillNum = ref.showSkillNum
		local curAttrList = serverData.nextSkillId
		if table.isempty(curAttrList) then
			for i = 1,showSkillNum do
				table.insert(dataList,curAttrList[i])
			end
		else
			for i,v in ipairs(curAttrList) do
				table.insert(dataList,v)
			end
		end
	end

	if #dataList == 0 then
		local serverData = self._serverData
		local curAttrList = serverData.skillId
		local curAttrNum = #curAttrList
		if curAttrNum > 0 then
			for i = 1, curAttrNum do
				table.insert(dataList, 0)
			end
		end
	end

	if self._uiNewSkillList then
		self._uiNewSkillList:RefreshList(dataList)
	else
		self._uiNewSkillList = self:GetUIScroll("newSkillList")
		self._uiNewSkillList:Create(self.mNewSkillList,dataList,function(...) self:OnDrawSkillCell(...) end,UIItemList.WRAP)
		self._uiNewSkillList:EnableScroll(false)
	end
end

function UIReRecast:RefreshNextAttrList()
	local serverData = self._serverData
	local curAttrList = serverData.nextAttrId

	local isEmpty = table.isempty(curAttrList)
	CS.ShowObject(self.mRandomAttrDiv,isEmpty)

	if self._uiNextList then
		self._uiNextList:RefreshList(curAttrList)
	else
		self._uiNextList = self:GetUIScroll("nextList")
		self._uiNextList:Create(self.mNewAttrList,curAttrList,function(...) self:OnDrawAttrCell(...) end,UIItemList.WRAP)
		self._uiNextList:EnableScroll(false)
	end
end

function UIReRecast:RefreshItemNum(trans,refId,num)
	local haveNum = gModelItem:GetNumByRefId(refId)
	local needNum = num
	local str = ccClientText(13236)
	local color = "139057"
	if haveNum < needNum then color = "c81212" end
	haveNum = LUtil.NumberCoversion(haveNum)
	needNum = LUtil.NumberCoversion(needNum)
	str = string.replace(str,color,haveNum,needNum)
	self:SetWndText(trans,str)
end

function UIReRecast:InitText()
	self:SetWndText(self.mTitle,ccClientText(13212))
	self:SetWndText(self.mAfterRecastTxt,ccClientText(13213))
	self:SetWndText(self.mLastRecastTxt,ccClientText(13214))
	self:SetWndText(self.mBaseTxt1,ccClientText(11307))
	self:SetWndText(self.mBaseTxt2,ccClientText(11307))
	self:SetWndText(self.mSkillTxt1,ccClientText(13209))
	self:SetWndText(self.mSkillTxt2,ccClientText(13209))
	self:SetWndText(self.mEmptyTXT,ccClientText(10103))
	self:SetWndText(self.mRandomAttrTxt,ccClientText(13221))

	self:SetWndButtonText(self.mRecastBtn, ccClientText(13208))
	self:SetWndButtonText(self.mSaveBtn, ccClientText(13260))
end

function UIReRecast:OnDrawItemCell(list, item, itemdata, itempos, fromHeadTail)
	local IconTrans = CS.FindTrans(item,"Icon")
	if IconTrans then
		local iconImg = gModelItem:GetItemIconByRefId(itemdata.refId)
		self._itemIconTransList[itemdata.refId] = iconImg
		self:SetWndEasyImage(IconTrans,iconImg)
		CS.ShowObject(IconTrans,true)
	end
	local RecastNumTxtTrans = CS.FindTrans(item,"RecastNumTxt")
	if RecastNumTxtTrans then
		self._itemNumTransList[itemdata.refId] = RecastNumTxtTrans
		self:RefreshItemNum(RecastNumTxtTrans,itemdata.refId,itemdata.num)
	end
end

function UIReRecast:RefreshTop()
	local serverData = self._serverData
	local refId = serverData.refId
	local data = {
		refId = refId,
		skillId = serverData.skillId,
		attrId = serverData.attrId,
	}
	self:SetRunIcon(self.mRuneIcon, data)

	local runeRef = self._ref
	--local name = ccLngText(runeRef.name)
	local name = gModelRune:GetRuneNameByServerData(serverData)
	self:SetWndText(self.mRuneName,name)
	--local quality = runeRef.quality
	--local color = gModelItem:GetColorByQualityId(quality)
	--self:SetXUITextTransColor(self.mRuneName,color)
end

function UIReRecast:InitEvent()
	self:SetWndClick(self.mReturnBtn,function() self:WndClose() end)
	self:SetWndClick(self.mSaveBtn,function()
		if self._sendMsg then return end
		-- 保存
		gModelRune:OnRuneRecastSaveReq(self._runeId)
		self._sendMsg = true
	end)
	self:SetWndClick(self.mRecastBtn,function() self:RuneRecastFunc()	end)
	self:SetWndClick(self.mHelpBtn,function()
		GF.OpenWnd("UIBzTips",{refId = 26})
	end)
end

--function UIReRecast:OnDrawSkillCell(list, item, itemdata, itempos, fromHeadTail)
function UIReRecast:OnDrawSkillCell(list,item, itemdata, itempos)
	local skillTrans = CS.FindTrans(item,"Skill")
	local SkillIconTrans = CS.FindTrans(skillTrans,"SkillIcon")
	local SkillDescTrans = CS.FindTrans(item,"SkillDesc")
	local SkillNameTrans = CS.FindTrans(item,"SkillName")
	local questinTrans = CS.FindTrans(SkillIconTrans,"Question")
	local haveRefId = itemdata > 0
	CS.ShowObject(questinTrans, not haveRefId)

	local skillData = haveRefId and gModelRune:GetSkillInfoByRefId(itemdata) or nil
	local skill
	if skillData then
		skill = tonumber(skillData.SkillId)
	end

	if skillTrans then
		if SkillIconTrans then
			local baseClass = SkillIcon:New(self)
			baseClass:ShowWenHao(skill == nil)
			baseClass:Create(SkillIconTrans,skill,function()
				if skill ~= nil then
--[[					local lv = skillData.skillLevel
					local other = {lv = lv}
					GF.OpenWnd("UIJNInfo",{skillId = skill,other = other})]]
					local skillType = skillData.skillType
					local refId = skillData.refId
					gModelRune:OpenNewRuneSkillWnd(refId,skillType)
				end
			end)
		end
	end
	if not haveRefId then
		--显示随机技能
		self:SetWndText(SkillDescTrans,"\n "..ccClientText(13262))
		self:SetWndText(SkillNameTrans,"")
		return
	end

	--CS.ShowObject(SkillIconTrans,skillData ~= nil)
	local skillRef = gModelHero:GetSkillByStarId(skill)
	local skillName,desc
	if skillRef then
		skillName = ccLngText(skillRef.name)
		desc = ccLngText(skillRef.description)
	else
		skillName = ""
		desc = ccClientText(13215)
	end
	if SkillNameTrans then
		if skillData.quality == 1 then
			skillName = LUtil.FormatColorStr(skillName,"blue")
		elseif skillData.quality == 3 then
			skillName = LUtil.FormatColorStr(skillName,"orange")
		end
		self:SetWndText(SkillNameTrans,skillName)
	end
	--CS.ShowObject(SkillNameTrans,skillData ~= nil)
	if SkillDescTrans then
		self:SetWndText(SkillDescTrans,desc)
	end
	--CS.ShowObject(SkillDescTrans,skillData ~= nil)
end

function UIReRecast:Refresh(network,noRefreshCur)
	if not self._serverData then
		return
	end
	self:RefreshBtn()

	self:RefreshTop()

	if not noRefreshCur then
		self:RefreshCurAttrList()
		self:RefreshCurSkillList()
	end

	self:RefreshNextAttrList()
	self:RefreshNextSkillList()

	if not network then
		self:RefreshSelectList()
		self:InitItemList()
	else
--[[		for i,v in ipairs(self._itemList) do
			local refId = v.refId
			local trans = self._itemNumTransList[refId]
			if trans then
				self:RefreshItemNum(trans,refId,v.num)
			end
		end]]
		if self._uiItemList then self._uiItemList:RefreshList() end
	end
	if self._contentShow then
		if network then
			self:RefreshContent(self._selectType)
		else
			self:RefreshContent()
		end
	end
end
------------------------------------------- 道具列表 -------------------------------------------


------------------------------------------------------------------
return UIReRecast