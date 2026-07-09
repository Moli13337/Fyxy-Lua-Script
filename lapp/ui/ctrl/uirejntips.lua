---
--- Created by Administrator.
--- DateTime: 2023/10/4 21:04:58
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIReJNTips:LWnd
local UIReJNTips = LxWndClass("UIReJNTips", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIReJNTips:UIReJNTips()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIReJNTips:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIReJNTips:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIReJNTips:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:Refresh()
end

function UIReJNTips:Refresh()
	local skillId = self._skillId
	local skillRef = gModelHero:GetSkillByStarId(skillId)
	if skillRef then
		local baseClass = SkillIcon:New(self)
		baseClass:Create(self.mSkillIcon,skillId)

		local skillName = ccLngText(skillRef.name)
		self:SetWndText(self.mSkillName,skillName)

		local skillType = skillRef.type
		local str
		if skillType == 1 then
			str = ccClientText(10039)
		else
			str = ccClientText(10040)
		end
		self:SetWndText(self.mSkillType,str)

		local desc = ccLngText(skillRef.description)
		self:SetWndText(self.mSkillDescTxt,desc)

		local desc2 = ccLngText(skillRef.description2)
		self:SetWndText(self.mSkillDesc2Txt,desc2)
	end
end

function UIReJNTips:InitEvent()
	self:SetWndClick(self.mBg,function() self:WndClose() end)
end

function UIReJNTips:InitData()
	self._skillId = self:GetWndArg("skillId")
end



------------------------------------------------------------------
return UIReJNTips


