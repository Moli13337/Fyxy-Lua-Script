---
--- Created by Administrator.
--- DateTime: 2023/10/3 21:13:35
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIReWear:LWnd
local UIReWear = LxWndClass("UIReWear", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIReWear:UIReWear()
	---@type table<number,CommonIcon>
	self._runeUIIconList = {}
	self._heroUIIconList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIReWear:OnWndClose()
	self:ClearCommonIconList(self._runeUIIconList)
	self:ClearCommonIconList(self._heroUIIconList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIReWear:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIReWear:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self._isVie = gLGameLanguage:IsVieVersion()
	self:InitEmptyList()
	self:InitData()
	self:InitEvent()
	self:InitMsg()
	if self._isRefId then
		self:SetWndText(self.mWearBtnName,ccClientText(11302))
		self:RuneReplaceView()
	else
		self:RuneWearView()
	end
	self:SetWndText(self.mDescTxt,ccClientText(13202))
	local wnd = GF.FindFirstWndByName("UIReInfoTip")
	if wnd then
		GF.CloseWndByName("UIReInfoTip")
	end
	self:Refresh()
end

function UIReWear:SetIconInfo(data,trans, instanceID)

	local refId = data.refId
	local runeData = {
		refId = refId,
		skillId = data.skillId,
		attrId = data.attrId,
	}

	local baseClass = self._runeUIIconList[instanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._runeUIIconList[instanceID] = baseClass
		baseClass:Create(trans)
		self:SetIconClickScale(trans, true)
	end
	baseClass:SetRuneData(data)
	baseClass:DoApply()

	self:SetWndClick(trans, function()
		local rune = {runeData = data}
		gModelGeneral:OpenRuneInfoTip(rune)
	end)
end

function UIReWear:SetNameInfoNew(serverData,RuneName)
	local runeName = gModelRune:GetRuneNameByServerData(serverData)
	self:SetWndText(RuneName,runeName)
	local color = gModelRune:GetRuneColorByRefId(serverData.refId)
	self:SetXUITextTransColor(RuneName,color)
end


function UIReWear:CreateAttrList(trans,list)
	local key = trans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(trans,list,function(...) self:OnDrawAttrCell(...) end)
	end
	local isEnable = #list > 4
	uiList:EnableScroll(isEnable)
end

function UIReWear:SendMsg(runeId,wear,wearHeroId)
	local heroId = self._heroId
	if heroId then
		if wear then
			local isWear = wearHeroId ~= "0"
			local func = function()
				gModelRune:OnRuneWearReq(heroId,runeId,self._pos)
			end
			if isWear then
				local wearHeroName = gModelHero:GetHeroNameById(wearHeroId)
				local heroName = gModelHero:GetHeroNameById(heroId)

				local serverData = gModelRune:GetServerDataById(runeId)
				local refId = serverData.refId
				local color = gModelRune:GetRuneColorByRefId(refId)
				--local runeName = gModelRune:GetRuneNameByRefId(refId)
				local runeName = gModelRune:GetRuneNameByServerData(serverData)
				gModelGeneral:OpenUIOrdinTips({refId = 52601,func = func,para = {wearHeroName,color,runeName,heroName}})
			else
				func()
			end
		else
			gModelRune:OnRuneUnloadReq(heroId,runeId,self._pos)
		end
	end
end

function UIReWear:SetSkillInfo(data,trans)
	local isBaseInfo = trans == nil
	local haveServerData = self._serverData ~= nil
	local skillList = self._wearTypeList
--[[	if haveServerData then
		skillList = self._serverData.skillId
	end]]
	trans = trans or self._skillTransList
	local skillIdList = data.skillId
	for i = 1,2 do
		local skillId = skillIdList[i]
		local skillTrans = trans[i]
		if skillId then
			local skillNameTrans = CS.FindTrans(skillTrans,"SkillName")
			if skillNameTrans then
				local skillData = gModelRune:GetSkillInfoByRefId(skillId)
				if skillData then
					local skill = tonumber(skillData.SkillId)
					local skillRef = gModelHero:GetSkillByStarId(skill)
					local skillName = "没有名字"
					if skillRef then skillName = ccLngText(skillRef.name) end
					skillName = "[" .. skillName .. "]"
					local uiHyperText = UIHyperText:New()
					uiHyperText:Create(skillNameTrans)
					local clickFunc = function()
						--[[
							printInfoN("======= skillName,skillId = ",skillName,skillId)
                           	GF.OpenWndUp("UIReJNTips",{skillId = skill})
							local lv = skillData.skillLevel
                            local other = {lv = lv}
                            GF.OpenWnd("UIJNInfo",{skillId = skill,other = other})
                        --]]

						local skillType = skillData.skillType
						local refId = skillData.refId
						gModelRune:OpenNewRuneSkillWnd(refId,skillType)
					end
					skillName = uiHyperText:AddHyper(skillName,{func = clickFunc})
					self:SetWndText(skillNameTrans,skillName)
					local skillType = skillData.skillType
					local skillLevel = skillData.skillLevel
					local skillNameColor = "139057ff"
					if (skillList and (not isBaseInfo)) or (not haveServerData) then
						--for index,sId in pairs(skillList) do
							if self._wearTypeList[skillType] and self._wearTypeList[skillType] >= skillLevel then
								skillNameColor = "5f6d7bff"
							end
						--end
					end
					self:SetXUITextTransColor(skillNameTrans,skillNameColor)
					self:InitTextModeWithLanguage(skillNameTrans, clickFunc)
				end
			end
			CS.ShowObject(skillTrans,true)
		else
			CS.ShowObject(skillTrans,false)
		end
	end
end

function UIReWear:CreateHeroIcon(heroId,InstanceID,HeroIconRootTrans,UseTxtTrans)
	local showHeroIcon = heroId ~= "" and heroId ~= "0"
	if showHeroIcon then
		local baseClass = self._heroUIIconList[InstanceID]
		if not baseClass then
			baseClass = CommonIcon:New(self)
			self._heroUIIconList[InstanceID] = baseClass
			baseClass:Create(CS.FindTrans(HeroIconRootTrans, "Icon"))
		end
		baseClass:SetHeroPlayer(heroId)
		baseClass:DoApply()
		if showHeroIcon then
			self:SetWndText(UseTxtTrans,ccClientText(18334))
		end
	end
	CS.ShowObject(HeroIconRootTrans,showHeroIcon)
	CS.ShowObject(UseTxtTrans,showHeroIcon)

	self:InitTextLineWithLanguage(UseTxtTrans,-40)
	self:InitTextSizeWithLanguage(UseTxtTrans, -4)
end

function UIReWear:SeAttrInfo(data,trans)
	local isBaseInfo = trans == nil
	trans = trans or self._wearAttrList
	local attrList = data.attrId
	for i = 1,8 do
		local attrTrans
		if isBaseInfo then
			attrTrans = trans[i]
		else
			attrTrans = CS.FindTrans(trans,"Attr"..i)
		end
		if attrTrans then
			local attrId = attrList[i]
			if attrId then
				local txtTrans = CS.FindTrans(attrTrans,"Attr")
				if txtTrans then
					local attrRef = gModelRune:GetAttrInfoByRefId(attrId)
					if attrRef then
						local attr = attrRef.attr
						local first = attr[1]
						if not first then return end
						local attrRefId,attrType,attrValue = first.attrRefId,first.attrType,first.attrVal
						local attrName = gModelHero:GetAttributeNameById(attrRefId)
						local value = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId,attrType,attrValue)
						local str = string.replace(ccClientText(13264),attrName,value)
						--local str = attrName .. ":" .. value
						self:SetWndText(txtTrans,str)
					end
				end
				CS.ShowObject(attrTrans,true)
			else
				CS.ShowObject(attrTrans,false)
			end
		end
	end
end

function UIReWear:GetRuneList()
	local list = {}
	local allRuneList = gModelRune:GetAllRuneList()
	if allRuneList then
		for k,v in pairs(allRuneList) do
			if self._heroId and self._heroId ~= v._heroId then
				if not v:CheckIsTry() then
					table.insert(list,v:GetServerData())
				end
			end
		end
		table.sort(list,function(a,b)
			local isHaveHeroA = a.heroId ~= "0" and 1 or 0
			local isHaveHeroB = b.heroId ~= "0" and 1 or 0
			if isHaveHeroA ~= isHaveHeroB then
				return isHaveHeroA < isHaveHeroB
			else
				return a.score > b.score
			end
		end)
	end
	return list
end

-- 符文替换
function UIReWear:RuneReplaceView()
	self:SetWndText(self.mTitle,ccClientText(13201))
	CS.ShowObject(self.mView2,true)
	local serverData = self._serverData
	if serverData then
		self:SetIconInfo(serverData, self.mRuneIcon, self.mRuneIcon:GetInstanceID())
		--self:SeAttrInfo(serverData)
		--self:SetSkillInfo(serverData)

		self:CreateAttrList(self.mWearAttrNewList,serverData.attrId)
		self:CreateSkillList(self.mWearSkillList,serverData.skillId)
		self:SetScoreNum(serverData)
--[[		local refId = serverData.refId
		self:SetNameInfo(refId,self.mRuneName)]]
		self:SetNameInfoNew(serverData,self.mRuneName)
		local heroId = serverData.heroId
		local trans = self.mHeroIconRoot
		local InstanceID = trans:GetInstanceID()
		self:CreateHeroIcon(heroId,InstanceID,trans,self.mUseTxt)
	end
end

function UIReWear:InitMsg()
	self:WndNetMsgRecv(LProtoIds.RuneWearResp, function() self:WndClose() end)
	self:WndNetMsgRecv(LProtoIds.RuneUnloadResp, function() self:WndClose() end)
	self:WndNetMsgRecv(LProtoIds.ChangeRuneResp, function() self:Refresh() end)
end

-- 符文穿戴
function UIReWear:RuneWearView()
	self:SetWndText(self.mTitle,ccClientText(13200))
	CS.ShowObject(self.mView1,true)
end

function UIReWear:SaveEquipWearData(refId,chang)
	self._refId = refId
	local runeRef = gModelRune:GetRuneInfoByRefId(refId)
	local isRefId = true
	if not runeRef then
		isRefId = false
	else
		self._runeRef = runeRef
	end
	self._isRefId = isRefId
end

function UIReWear:Refresh()
	local isRefId = self._isRefId
	local uiList = self._uiList
	if not uiList then
		uiList = UIListWrap:New()
		if isRefId then
			uiList:Create(self,self.mWearList2)
		else
			uiList:Create(self,self.mWearList1)
		end
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrawRuneCell(...)
		end)
		self._uiList = uiList
	end
	uiList:RemoveAll()
	local runeList = self:GetRuneList()
	local len = #runeList
	local isEmpty = len < 1
	if not isEmpty then
		for i,v in ipairs(runeList) do
			uiList:AddData(i,v)
		end
	end
	CS.ShowObject(self.mNoRecord,isEmpty)
	CS.ShowObject(self.mDescTxt,not isEmpty)
	CS.ShowObject(self.mOriginBtn,isEmpty)
	uiList:RefreshList()
end

function UIReWear:SetNameInfo(refId,RuneName)
	local name = gModelRune:GetRuneNameByRefId(refId)
	self:SetWndText(RuneName,name)
	local color = gModelRune:GetRuneColorByRefId(refId)
	self:SetXUITextTransColor(RuneName,color)
end

function UIReWear:InitEmptyList()
	local data = {
		refId = 5101,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
		GetBtn = self.mOriginBtn,
		GetBtnText = self.mOriginBtnName,
		ButtonRoot = self.mOriginBtn,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end

function UIReWear:OnDrawAttrCell(list,item,itemdata,itempos)
	local Attr = self:FindWndTrans(item,"Attr")
	local attrRef = gModelRune:GetAttrInfoByRefId(itemdata)
	if attrRef then
		local attr = attrRef.attr
		local first = attr[1]
		if not first then return end
		local attrRefId,attrType,attrValue = first.attrRefId,first.attrType,first.attrVal
		local attrName = gModelHero:GetAttributeNameById(attrRefId)
		local value = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId,attrType,attrValue)
		local str = string.replace(ccClientText(13264),attrName,value)
		self:SetWndText(Attr,str)
	end
end

function UIReWear:OnDrawSkillCell(list,item,itemdata,itempos)
	local SkillNameTrans = self:FindWndTrans(item,"SkillName")
	local skillData = gModelRune:GetSkillInfoByRefId(itemdata)
	if skillData then
		local isBaseInfo = SkillNameTrans == nil
		local haveServerData = self._serverData ~= nil
		local skillList = self._wearTypeList
		local skill = tonumber(skillData.SkillId)
		local skillRef = gModelHero:GetSkillByStarId(skill)
		local skillName = "没有名字"
		if skillRef then skillName = ccLngText(skillRef.name) end
		skillName = "[" .. skillName .. "]"
		local uiHyperText = UIHyperText:New()
		uiHyperText:Create(SkillNameTrans)
		local clickFunc = function()
			local skillType = skillData.skillType
			local refId = skillData.refId
			gModelRune:OpenNewRuneSkillWnd(refId,skillType)
		end
		skillName = uiHyperText:AddHyper(skillName,{func = clickFunc})
		self:SetWndText(SkillNameTrans,skillName)
		local skillType = skillData.skillType
		local skillLevel = skillData.skillLevel
		local skillNameColor = "139057ff"
		if (skillList and (not isBaseInfo)) or (not haveServerData) then
			if skillList[skillType] and skillList[skillType] >= skillLevel then
				skillNameColor = "5f6d7bff"
			end
		end
		self:SetXUITextTransColor(SkillNameTrans,skillNameColor)
		self:InitTextModeWithLanguage(SkillNameTrans, clickFunc)
	end
end

function UIReWear:InitEvent()
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end)
	self:SetWndClick(self.mBg,function() self:WndClose() end)
	self:SetWndClick(self.mWearBtn,function()
		local serverData = self._serverData
		if serverData then
			local id = serverData.id
			self:SendMsg(id)
		end
	end)
--[[	self:SetWndClick(self.mOriginBtn,function()
		GF.ShowMessage("")
	end)]]
end

function UIReWear:SetScoreNum(data,trans)
	trans = trans or self.mWearScoreTxt
	local score = math.floor(data.score + 0.5)
	local str = string.replace(ccClientText(13263) or "%s",score)
	self:SetWndText(trans,str)
end

function UIReWear:OnDrawRuneCell(list, item, itemdata, itempos, fromHeadTail)
	local InstanceID = item:GetInstanceID()
	local heroId = itemdata.heroId
	local runeTrans = CS.FindTrans(item,"Rune")
	if runeTrans then
		local runeIconTrans = CS.FindTrans(runeTrans,"RuneIcon")
		if runeIconTrans then
			self:SetIconInfo(itemdata,runeIconTrans,item:GetInstanceID())
		end
	end
	local UseTxtTrans = self:FindWndTrans(item,"UseTxt")
	local HeroIconRootTrans = self:FindWndTrans(item,"HeroIconRoot")
	if HeroIconRootTrans then
		self:CreateHeroIcon(heroId,InstanceID,HeroIconRootTrans,UseTxtTrans)
	end
	local attrListTrans = CS.FindTrans(item,"AttrList")
	if attrListTrans then
		--self:SeAttrInfo(itemdata,attrListTrans)
		self:CreateAttrList(attrListTrans,itemdata.attrId)
	end
--[[	local skillTransList = {}
	for i = 1,2 do
		local skillTrans = CS.FindTrans(item,"Skill"..i)
		if skillTrans then table.insert(skillTransList,skillTrans) end
	end
	self:SetSkillInfo(itemdata,skillTransList)]]
	local SkillListTrans = self:FindWndTrans(item,"SkillList")
	if SkillListTrans then
		self:CreateSkillList(SkillListTrans,itemdata.skillId)
	end

	local WearBtnTrans = CS.FindTrans(item,"WearBtn")
	if WearBtnTrans then
		local runeId = itemdata.id
		self:SetWndClick(WearBtnTrans,function()
			self:SendMsg(runeId,true,heroId)
		end)
		local WearBtnNameTrans = CS.FindTrans(WearBtnTrans,"btnName")
		if WearBtnNameTrans then
			self:SetWndText(WearBtnNameTrans,ccClientText(11301))
		end

		if self._isVie then
			self:InitTextSizeWithLanguage(WearBtnNameTrans,-5)
		end
	end
	local AutoDivTrans = self:FindWndTrans(item,"AutoDiv")
	local ScoreTxtTrans = CS.FindTrans(AutoDivTrans,"ScoreTxt")
	if ScoreTxtTrans then
		self:SetScoreNum(itemdata,ScoreTxtTrans)
	end
	local UpImgTrans = CS.FindTrans(item,"UpImg")
	if UpImgTrans then
		if table.isempty(self._serverData) then
			CS.ShowObject(UpImgTrans,true)
		else
			local showUpImg = false
			if itemdata.score > self._serverData.score then showUpImg = true end
			CS.ShowObject(UpImgTrans,showUpImg)
		end
	end
	local RuneName = self:FindWndTrans(AutoDivTrans,"RuneName")
	if RuneName then
--[[		local refId = itemdata.refId
		self:SetNameInfo(refId,RuneName)]]
		self:SetNameInfoNew(itemdata,RuneName)
	end
end

function UIReWear:CreateSkillList(trans,list)
	local key = trans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(trans,list,function(...) self:OnDrawSkillCell(...) end)
	end
	local isEnable = #list > 2
	uiList:EnableScroll(isEnable)
end

function UIReWear:InitData()
	self._runeId = self:GetWndArg("runeId")
	self._heroId = self:GetWndArg("heroId")
	self._pos = self:GetWndArg("pos")
	self._wearList = self:GetWndArg("wearList")
	self._wearTypeList = {}
	for i,v in pairs(self._wearList) do
		local serverData = v:GetServerData()
		local skillId = serverData.skillId
		for _i,_v in ipairs(skillId) do
			local skillRef = gModelRune:GetSkillInfoByRefId(_v)
			if skillRef then
				local skillType = skillRef.skillType
				local skillLevel = skillRef.skillLevel
				if not self._wearTypeList[skillType] then
					self._wearTypeList[skillType] = skillLevel
				elseif self._wearTypeList[skillType] < skillLevel then
					self._wearTypeList[skillType] = skillLevel
				end
			end
		end
	end
	local runeData = gModelRune:GetRuneDataById(self._runeId)
	local serverData,refId
	if runeData then
		serverData = runeData:GetServerData()
		refId = serverData.refId
	else
		refId = self._runeId
	end
--[[	if table.isempty(serverData) then
		local serData = table.clone(serverData)
		local score = gModelRune:GetRuneScore(serData.attrId,serData.skillId)
		serData.score = score
		serverData = serData
	end]]
	self._serverData = serverData
	if not refId then return end
	self._wearAttrList = {
		self.mWearAttr1,
		self.mWearAttr2,
		self.mWearAttr3,
		self.mWearAttr4,
		self.mWearAttr5,
		self.mWearAttr6,
		self.mWearAttr7,
		self.mWearAttr8,
	}
	self._skillTransList = {
		self.mWearSkill1,
		self.mWearSkill2,
	}
	self:SaveEquipWearData(refId)
end
------------------------------------------------------------------
return UIReWear