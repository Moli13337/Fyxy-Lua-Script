---
--- Created by BY.
--- DateTime: 2022/10/27 18:20:39
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBossStrategyPop:LWnd
local UIBossStrategyPop = LxWndClass("UIBossStrategyPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBossStrategyPop:UIBossStrategyPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBossStrategyPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBossStrategyPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBossStrategyPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitCommand()
end
function UIBossStrategyPop:OnDrawInvasionSkill(list,item,itemdata,itempos)
	local Image = self:FindWndTrans(item,"Image")
	local Skill = self:FindWndTrans(item,"Skill")
	local SkillSkillIcon = self:FindWndTrans(Skill,"SkillIcon")
	local NameText = self:FindWndTrans(item,"NameText")
	local DescText = self:FindWndTrans(item,"DescText")

	local skillId = tonumber(itemdata)

	local skillIconTrans = CS.FindTrans(item,"Skill/SkillIcon")
	if skillIconTrans then
		local data =
		{
			trans = SkillSkillIcon,
			level = 1,
			refId = skillId,
			tipFunc = function()
				--GF.OpenWnd("UINewJNTip",{curSkillId = skillId,wndType = 2})
				gModelGeneral:OpenSkillWnd({curSkillId = skillId,wndType = 2})
			end,
		}
		local skillIcon = SkillIcon:New(self)
		skillIcon:Show(data)
	end

	local skillRef = gModelSkill:GetSkillRef(skillId)
	if not skillRef then
		return
	end
	self:SetWndText(NameText, ccLngText(skillRef.name))

	local descStr = ccLngText(skillRef.description)
	descStr = string.gsub(descStr, "30e005", "139057")
	self:SetWndText(DescText, descStr)
end

function UIBossStrategyPop:RefreshSkillList()
	local heroSkillIdList = self._skillDataList

	local skillScrollList = self._skillScrollList
	if(skillScrollList)then
		skillScrollList:RefreshList(heroSkillIdList)
	else
		skillScrollList = self:GetUIScroll("_skillScroll")
		self._skillScrollList = skillScrollList
		skillScrollList:Create(self.mSkillScroll,heroSkillIdList,function (...) self:OnDrawInvasionSkill(...) end)
		skillScrollList:EnableScroll(true)
	end
end
function UIBossStrategyPop:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(18739))

	local bossRefId = self:GetWndArg("bossRefId")
	local bossRef = gModelCrusadeAgainst:GetDreamCrusadeDifficultyRefByRefId(bossRefId)

	self:SetWndEasyImage(self.mDesTextBg,bossRef.strategyBg)
	self:SetWndText(self.mDesText, ccLngText(bossRef.strategyText))

	if string.isempty(bossRef.skillData) then return end
	local skillData = string.split(bossRef.skillData,",")
	self._skillDataList = skillData
	self:RefreshSkillList()
end

function UIBossStrategyPop:InitEvent()
	self:SetWndClick(self.mBgImage,function () self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end)

end
------------------------------------------------------------------
return UIBossStrategyPop


