---
--- Created by Administrator.
--- DateTime: 2025/1/2 20:37:11
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaTreeCGjeJN:LWnd
local UISagaTreeCGjeJN = LxWndClass("UISagaTreeCGjeJN", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaTreeCGjeJN:UISagaTreeCGjeJN()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaTreeCGjeJN:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaTreeCGjeJN:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaTreeCGjeJN:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitTexts()
	self:InitDatas()
	self:InitClicks()
	self:InitEvents()
	self:RefreshView()
end

function UISagaTreeCGjeJN:OnHeroTreePointSelectSkillResp(pb)
	self:RefreshView()
end

function UISagaTreeCGjeJN:InitClicks()
	self:SetWndClick(self.mBtnClose, function() self:WndClose() end)
	self:SetWndClick(self.mMask, function() self:WndClose() end)
end

function UISagaTreeCGjeJN:OnDrawAwakenSkillCell(list,item,itemdata,itempos)
	local CommonUITrans = self:FindWndTrans(item,"CommonUI")
	local RootTrans = self:FindWndTrans(CommonUITrans,"Root")
	local SkillIconTrans = self:FindWndTrans(RootTrans,"SkillIcon")

	local skillId = itemdata.skillId
	local baseClass = SkillIcon:New(self)
	if skillId then
		baseClass:SetSkillInfo(nil,false,nil,1)
		baseClass:Create(SkillIconTrans,skillId,function()
			local skillData = gModelHero:GetSkillByStarId(skillId)
			if not skillData then return end

			local heroData = gModelHero:GetHeroServerDataById(self._heroId)
			if not heroData then return end

			gModelGeneral:OpenSkillWnd({
				wndType = 5,
				curSkillId = skillId,
				skill = skillId,
				pointActivate = true,
			})
		end)
	else
		baseClass:SetShowIcon(false,false)
		baseClass:SetSkillInfo(nil,nil,nil,1)
		baseClass:Create(SkillIconTrans,0,function() end)
		baseClass:SetIconAndIconBgGray(false)
	end

	--local Name = self:FindWndTrans(item,"Name")
	--local name = ""
	--local skillRef = skillId and GameTable.SnakeSkillRef[skillId]
	--if skillRef then
	--	name = ccLngText(skillRef.name)
	--end
	--self:SetWndText(Name,name)

	local SelectBg = self:FindWndTrans(item,"SelectBg")
	local canChangeSkill = itemdata.canChangeSkill
	if canChangeSkill then
		local SelectYesIcon = self:FindWndTrans(SelectBg,"SelectYesIcon")
		CS.ShowObject(SelectYesIcon,self._curSelSkill == skillId)
		self:SetWndClick(SelectBg,function()
			self:OnClickSkillSelBg(itemdata)
		end)
	end
	CS.ShowObject(SelectBg,canChangeSkill)
end


function UISagaTreeCGjeJN:InitAwakenSkillList(list)
	local uiAwakenSkillList = self._uiAwakenSkillList
	if uiAwakenSkillList then
		uiAwakenSkillList:RefreshList(list)
	else
		uiAwakenSkillList = self:GetUIScroll("uiAwakenSkillList")
		self._uiAwakenSkillList = uiAwakenSkillList
		uiAwakenSkillList:Create(self.mAwakenSkillList,list,function(...) self:OnDrawAwakenSkillCell(...) end)
	end
end

function UISagaTreeCGjeJN:InitEvents()
    --self:AddMsgHandler(LxProtoIds.HeroUpLevelResp, self.OnHeroUpLevelResp, self)
    --self:AddEventHandler(EventNames.ITEM_CHANGED, self.OnItemChange, self)
	self:WndNetMsgRecv(LProtoIds.HeroTreePointSelectSkillResp,function(pb) self:OnHeroTreePointSelectSkillResp(pb) end)

end

function UISagaTreeCGjeJN:InitDatas()
	self._heroId = self:GetWndArg("heroId")
	self._actLvRefId = self:GetWndArg("actLvRefId")
	self._pointRefId = self:GetWndArg("pointRefId")
end

function UISagaTreeCGjeJN:RefreshView()
	if not self._heroId then return end

	local heroServerData = gModelHero:GetHeroServerDataById(self._heroId)
	if not heroServerData then return end

	local actLvRefId = self._actLvRefId
	if not actLvRefId or actLvRefId < 1 then return end

	local ref = gModelHero:GetHeroTreePointLvRef(actLvRefId)
	if not ref then return end

	local pointRefId = self._pointRefId
	if not pointRefId then return end


	local skill = ref.skill
	if skill and skill ~= "" then
		local curSelSkill
		if pointRefId and pointRefId > 0 then
			---@type StructHeroTreeInfo
			local treeInfo = heroServerData.treeInfo
			if treeInfo and treeInfo.pointMap[pointRefId] then
				---@type StructHeroTreePointInfo
				local point = treeInfo.pointMap[pointRefId]
				curSelSkill = point.skillId
			end
		end
		self._curSelSkill = curSelSkill
		local list = {}
		local tSkill = string.split(skill,"|")
		local isCanChangeSkill = #tSkill > 1
		for i,v in ipairs(tSkill) do
			table.insert(list,{
				skillId = checknumber(v),
				canChangeSkill = isCanChangeSkill,
			})
		end
		self:InitAwakenSkillList(list)
	end
end


function UISagaTreeCGjeJN:OnClickSkillSelBg(itemdata)
	local skillId = itemdata.skillId
	if self._curSelSkill == skillId then return end

	local heroId = self._heroId
	gModelHero:OnHeroTreePointSelectSkillReq(heroId,self._pointRefId,skillId)
end

function UISagaTreeCGjeJN:InitTexts()
	self:SetXUITextText(self.mLblBiaoti,ccClientText(24817))
end
------------------------------------------------------------------
return UISagaTreeCGjeJN