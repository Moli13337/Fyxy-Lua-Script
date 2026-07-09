---
--- Created by Administrator.
--- DateTime: 2023/10/9 14:59:00
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaAwakenJNSelect:LWnd
local UISagaAwakenJNSelect = LxWndClass("UISagaAwakenJNSelect", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaAwakenJNSelect:UISagaAwakenJNSelect()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaAwakenJNSelect:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaAwakenJNSelect:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaAwakenJNSelect:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitMsg()
	self:SetContent()
end

function UISagaAwakenJNSelect:InitData()
	self._heroId	= self:GetWndArg("heroId")
	self._pointRefId = self:GetWndArg("pointRefId")
	self._heroRefId = self:GetWndArg("heroRefId") --英雄无属性
	self._isFake    = not self._heroId and self._heroRefId  --给预览做的假数据

	self._romeNum = { "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "VX", "X",}
	self._curTypeIndex   = nil

	self._selectId = nil
	self._selectIconList = {}
	self._typeBtnList = {}
end

function UISagaAwakenJNSelect:RefreshSkillList()
	if table.isempty(self._skillDataList) then return end

	local curSkillData = self._skillDataList[self._curTypeIndex]
	local heroSkillIdList = curSkillData.skillList
	if table.isempty(heroSkillIdList) then
		return
	end

	local skillScrollList = self._skillScrollList
	if(skillScrollList)then
		skillScrollList:RefreshList(heroSkillIdList)
	else
		skillScrollList = self:GetUIScroll("_skillScroll")
		skillScrollList:Create(self.mSkillScroll,heroSkillIdList,function (...) self:OnDrawNormalSkill(...) end)
		skillScrollList:EnableScroll(true)
		self._skillScrollList = skillScrollList
	end
end

function UISagaAwakenJNSelect:OnDrawNormalSkill(list,item,itemdata,itempos)
	local skillId = tonumber(itemdata)
	local InstanceID = item:GetInstanceID()
	local skillIconTrans = CS.FindTrans(item,"Skill/SkillIcon")
	if skillIconTrans then
		local baseClass = SkillIcon:New(self)
		baseClass:SetSkillInfo(nil,false,nil,1)
		baseClass:ShowLvl(false)
		baseClass:ShowLock(false)
		baseClass:Create(skillIconTrans,skillId,function()
			self:OnClickNormalSkill(skillId)
		end)
		baseClass:SetIconAndIconBgGray(false)
	end

	local isSelect 	 = self._selectId == skillId
	local selectBg   = self:FindWndTrans(item, "SelectBg")
	local selectIcon = self:FindWndTrans(selectBg, "SelectIcon")
	self._selectIconList[InstanceID] = selectIcon
	CS.ShowObject(selectIcon, isSelect)
	self:SetWndClick(selectBg, function()
		self:OnClickSkillSelect(skillId, InstanceID)
	end)

	local skillRef = gModelHero:GetSkillByStarId(skillId)
	if not skillRef then
		return
	end

	local nameText = CS.FindTrans(item, "NameText")
	if nameText then
		self:SetWndText(nameText, ccLngText(skillRef.name))
	end

	local descText = CS.FindTrans(item, "DescText")
	if descText then
		local descStr = ccLngText(skillRef.description)
		descStr = string.gsub(descStr, "30e005", "139057")
		self:SetWndText(descText, descStr)
		self:InitTextModeWithLanguage(descText, nil, true)
	end
end

function UISagaAwakenJNSelect:RefreshTypeList()
	local skillList = self._skillDataList
	if table.isempty(skillList) then return end

	local uiTypeList = self:FindUIScroll("uiTypeList") --self._uiTypeList
	if not uiTypeList then
		uiTypeList = self:GetUIScroll("uiTypeList") -- UIItemList:New(self)
		uiTypeList:Create(self.mTypeList,skillList,function (...) self:SetTypeItem(...) end)
		--self._uiTypeList = uiTypeList
	else
		uiTypeList:RefreshList(skillList)
	end
	uiTypeList:EnableScroll(#skillList > 4,true)
	--uiTypeList:RefreshList(skillList)
end


function UISagaAwakenJNSelect:SetContent()
	self:RefreshData()
	self:RefreshTypeList()
	self:RefreshSkillList()

	self:SetWndText(self.mTitleText, ccClientText(20147))
	self:SetWndText(self.mDescText, ccClientText(20157))
end

function UISagaAwakenJNSelect:RefreshData()
	self._skillDataList  = {}
	if self._heroId then
		self:RefreshDataWhenHero()
	elseif self._heroRefId then
		self:RefreshDataWhenRefId()
	end
end

function UISagaAwakenJNSelect:OnShiftSkill()
	local heroId = self._heroId
	local pointRefId = self._pointRefId
	local skillId = self._selectId
	gModelHero:OnHeroTreePointSelectSkillReq(heroId,pointRefId, skillId)
end

function UISagaAwakenJNSelect:OnClickType(typeIndex)
	local data = self._skillDataList[typeIndex]
	if not data then
		printInfoNR("self._skillDataList[typeIndex] is not find, typeIndex = "..typeIndex)
		return
	end

	if not data.isActivate then
		GF.ShowMessage(ccClientText(20154))
		return
	end

	if typeIndex == self._curTypeIndex then return end

	local oldRefId  	= self._curTypeIndex
	local oldTabBtn		= self._typeBtnList[oldRefId]
	self:SetWndTabStatus(oldTabBtn,LWnd.StateOff)

	local newTabBtn		= self._typeBtnList[typeIndex]
	self:SetWndTabStatus(newTabBtn,LWnd.StateOn)

	self._curTypeIndex = typeIndex
	self._pointRefId   = data.treePointRefId
	self._selectId 	   = data.curSelectSkillId
	self:RefreshSkillList()
end

function UISagaAwakenJNSelect:SetTypeItem(list, item,itemdata, itempos)
	local BtnTab1 = self:FindWndTrans(item,"BtnTab1")
	local name  = ccClientText(20130)
	name		= name..self._romeNum[itempos]
	local isOpen = itemdata.isActivate

	local isCurSelect = itempos == self._curTypeIndex
	self:SetWndTabText(BtnTab1,name, -6)

	local state = isCurSelect and LWnd.StateOn or LWnd.StateOff
	if not isOpen then
		state   = LWnd.StateGray
	end
	self:SetWndTabStatus(BtnTab1,state)
	self:SetWndClick(BtnTab1,function () self:OnClickType(itempos) end)
	self._typeBtnList[itempos] = BtnTab1
end

function UISagaAwakenJNSelect:OnHeroTreePointSelectSkillResp(pb)
	if pb.heroId == self._heroId then
		self:RefreshData()
	end
end

function UISagaAwakenJNSelect:OnClickNormalSkill(skillId)
	local skillData = gModelHero:GetSkillByStarId(skillId)
	if not skillData then return end

	local lv = skillData.level
	local other = {lv = lv}
	GF.OpenWndTop("UIJNInfo",{skillId = skillId,other = other})
end

function UISagaAwakenJNSelect:InitMsg()
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:WndClose() end)
	self:WndEventRecv(EventNames.ON_ENTER_BATTLE_MAP,function () self:WndClose() end)
	self:WndNetMsgRecv(LProtoIds.HeroTreePointSelectSkillResp,function(pb) self:OnHeroTreePointSelectSkillResp(pb) end)
end

function UISagaAwakenJNSelect:OnClickSkillSelect(skillId, InstanceID)
	if self._isFake then
		GF.ShowMessage(ccClientText(20160))
		return
	end

	if self._selectId == skillId then
		return
	end

	self._selectId = skillId
	for k,v in pairs(self._selectIconList) do
		CS.ShowObject(v, k == InstanceID)
	end

	self:OnShiftSkill()
end

function UISagaAwakenJNSelect:RefreshDataWhenRefId()
	local refId 	= self._heroRefId
	local treeRefId	= gModelHero:GetHeroAwakenByRefId(refId)

	local treePointList = gModelHero:GetHeroTreePointList(treeRefId)
	for k,v in ipairs(treePointList) do
		local treePointRefId = v.refId
		local data = gModelHero:GetHeroTreePointLvList(treePointRefId)
		if data.pointType == ModelHero.TREE_POINT_TYPE_SKILL then
			local lvList	  = data.lvList
			local firstLvRef = lvList[#lvList] --默认满级
			local lvRefId = firstLvRef.refId
			local curPointLvRef = gModelHero:GetHeroTreePointLvRef(lvRefId)
			local skill 		= curPointLvRef.skill
			local skills 		= string.split(skill, '|')
			local skillId 		= tonumber(skills[1])
			local skillData		= {
				treePointRefId	= treePointRefId,
				isActivate		= true,
				curSelectSkillId = skillId,
				skillList		= skills,
			}

			table.insert(self._skillDataList, skillData)

			if not self._curTypeIndex and treePointRefId == self._pointRefId then
				self._curTypeIndex = #self._skillDataList
				self._selectId = skillData.curSelectSkillId
			end
		end
	end
end

function UISagaAwakenJNSelect:RefreshDataWhenHero()
	local heroId = self._heroId
	local serverData = gModelHero:GetHeroServerDataById(heroId)
	if not serverData then
		printInfoNR("UISagaAwakenJNSelect:RefreshData(), hero serverData is not find, heroId = "..heroId)
		return
	end

	local treeInfo	= serverData.treeInfo
	if not treeInfo then
		printInfoNR("UISagaAwakenJNSelect:RefreshData(), treeInfo is a nil")
		return
	end

	local treeRefId	= treeInfo.treeRefId
	if treeRefId == 0 then
		printInfoNR("UISagaAwakenJNSelect:RefreshData(), treeInfo.treeRefId is error")
		return
	end

	local treeInfoPoints = gModelHero:GetHeroServerTreePoints(heroId)
	local treePointList = gModelHero:GetHeroTreePointList(treeRefId)

	for k,v in ipairs(treePointList) do
		local treePointRefId 	= v.refId
		local data				= gModelHero:GetHeroTreePointLvList(treePointRefId)
		if data.pointType == ModelHero.TREE_POINT_TYPE_SKILL then
			local infoPoint	   	= treeInfoPoints[treePointRefId]
			local isActivate	= infoPoint ~= nil

			local skills
			if isActivate then
				local curPointLvRef = gModelHero:GetHeroTreePointLvRef(infoPoint.lvRefId)
				local skill 		= curPointLvRef.skill
				skills 				= string.split(skill, '|')
			end

			local skillData		= {
				treePointRefId	= treePointRefId,
				isActivate		= isActivate,
				curSelectSkillId = isActivate and infoPoint.skillId or 0,
				skillList		= skills,
			}

			table.insert(self._skillDataList, skillData)

			if not self._curTypeIndex and treePointRefId == self._pointRefId then
				self._curTypeIndex = #self._skillDataList
				self._selectId = skillData.curSelectSkillId
			end
		end
	end

end

function UISagaAwakenJNSelect:InitEvent()
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end)
	self:SetWndClick(self.mBgImage,function() self:WndClose() end)
end

------------------------------------------------------------------
return UISagaAwakenJNSelect


