---
--- Created by BY.
--- DateTime: 2023/10/26 11:56:46
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIJNUpPop:LWnd
local UIJNUpPop = LxWndClass("UIJNUpPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIJNUpPop:UIJNUpPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIJNUpPop:OnWndClose()
	self:TweenSeqKill(self._effectKey)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIJNUpPop:OnCreate()
	LWnd.OnCreate(self)
	self._effectKey = "skillUp"
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIJNUpPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIJNUpPop:CreateTitleEffect()
	CS.ShowObject(self.mTitleImag,true)
	self:CreateEffect(self.mTitleEff,"fx_ui_shengxing_1")
end

function UIJNUpPop:SetSkillIcon(trans,ref)
	local icon = CS.FindTrans(trans,"SkillIcon/IconBg/Icon")
	local lvBg = CS.FindTrans(trans,"SkillIcon/SkillBg")
	local level = CS.FindTrans(trans,"SkillIcon/SkillBg/SkillLv")
	self:SetWndEasyImage(icon,ref.icon,function()
		CS.ShowObject(icon,true)
	end)
	CS.ShowObject(lvBg,true)
	self:SetWndText(level,ref.level)
end

function UIJNUpPop:GetSkillRef(skillId)
	local guildSkillRef = gModelGuild:GetGuildSkillRefByRefId(skillId)
	local skillRef = gModelHero:GetSkillByStarId(guildSkillRef.skillId)
	return skillRef
end

function UIJNUpPop:PlayEffect(isUp)
	local seqTween
	self:TweenSeqKill(self._effectKey)
	if not seqTween then
		seqTween = self:TweenSeqCreate(self._effectKey,function(seq)
			local showTopTime = 0
			local showAttrTime = 0.1
			seq:AppendCallback(function ()
				self:CreateTitleEffect()
			end)
			seq:AppendInterval(showTopTime)
			if(isUp)then
				seq:AppendCallback(function ()
					self:CreateSkillEffect(self.mSkillRoot1,1)
				end)
				seq:AppendInterval(showAttrTime)
				--seq:AppendCallback(function ()
				--	self:CreateSkillEffect(self.mSkillRoot2,2)
				--end)
				seq:AppendInterval(showAttrTime)
			else
				seq:AppendCallback(function ()
					self:CreateSkillEffect(self.mSkillRoot1,1)
				end)
				seq:AppendInterval(showAttrTime)
			end
			return seq
		end)
	end
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(self._effectKey)
	end)

end

function UIJNUpPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)

end

function UIJNUpPop:InitCommand()
	self:SetWndText(self.mTipsText,ccClientText(10103))
	self:SetWndText(self.mDesTitleText,ccClientText(17300))
	self:SetWndText(self.mLvText,ccClientText(17301))
	local _oldSkill = self:GetWndArg("oldSkill") or 0
	local _newSkill = self:GetWndArg("newSkill")
	local ref = self:GetSkillRef(_newSkill)
	local isUp = _oldSkill ~= 0
	CS.ShowObject(self.mLvMag,isUp)
	self:SetSkillIcon(self.mSkillRoot1,ref)
	if(isUp)then
		self:SetWndEasyImage(self.mTitleImag,"guild_txt_7", nil, true)
		local _oldRef = self:GetSkillRef(_oldSkill)
		self:SetWndText(self.mLvText1,_oldRef.level)
		self:SetWndText(self.mLvText2,ref.level)
	else
		self:SetWndEasyImage(self.mTitleImag,"guild_txt_6", nil, true)
	end
	self:SetWndText(self.mSkillDesText,ccLngText(ref.description))
	self:PlayEffect(isUp)
end

function UIJNUpPop:InitMessage()

end

function UIJNUpPop:CreateEffect(trans,effectName,effectKey)
	effectKey = effectKey or effectName
	self:CreateWndEffect(trans,effectName,effectKey,100,false,false)
end

function UIJNUpPop:CreateSkillEffect(trans,index)
	local eff = CS.FindTrans(trans,"Eff")
	self:CreateEffect(eff,"fx_ui_shengxing_2",index)
end
------------------------------------------------------------------
return UIJNUpPop


