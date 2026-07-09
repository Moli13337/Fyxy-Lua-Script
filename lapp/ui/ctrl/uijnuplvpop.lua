---
--- Created by BY.
--- DateTime: 2023/10/28 15:10:10
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIJNUpLvPop:LWnd
local UIJNUpLvPop = LxWndClass("UIJNUpLvPop", LWnd)
local typeof = typeof
local typeOfScrollRect = typeof(UnityEngine.UI.ScrollRect)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIJNUpLvPop:UIJNUpLvPop()
	self._delayUpdateScrollTimerList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIJNUpLvPop:OnWndClose()
	self:StopDelayTimer()
	self._delayUpdateScrollTimerList = nil
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIJNUpLvPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIJNUpLvPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitCommand()
end

function UIJNUpLvPop:UpdateResultText(ResultText,ResultNode,text,key,normalized)
	self:SetWndText(ResultText,text)
	self:StartDelayTimer(ResultNode,normalized,key)
end

function UIJNUpLvPop:StartDelayTimer(ResultNode,normalized,key)
	if not ResultNode then
		return
	end
	local resultNode = ResultNode:GetComponent(typeOfScrollRect)
	local _delayUpdateScrollTimerList = self._delayUpdateScrollTimerList or {}
	local _delayUpdateScrollTimer = _delayUpdateScrollTimerList[key]
	if _delayUpdateScrollTimer then
		return
	end
	_delayUpdateScrollTimer = LxTimer.DelayFrameCall(function ()
		if normalized then
			resultNode.verticalNormalizedPosition = normalized
		end
		_delayUpdateScrollTimerList[key] = nil
	end,1)
	_delayUpdateScrollTimerList[key] = _delayUpdateScrollTimer
end

function UIJNUpLvPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)

end

function UIJNUpLvPop:StopDelayTimer()
	for i, v in pairs(self._delayUpdateScrollTimerList) do
		LxTimer.DelayTimeStop(v)
		v = nil
	end
end
function UIJNUpLvPop:InitCommand()
	self:SetWndText(self.mCloseTip,ccClientText(10103))

	local _oldSkill = self:GetWndArg("oldSkill") or 0
	local _newSkill = self:GetWndArg("newSkill")

	local isUp = _oldSkill ~= 0
	local titleStr = ""
	CS.ShowObject(self.mRoot1,not isUp)
	CS.ShowObject(self.mRoot2,isUp)
	if isUp then
		titleStr = "onhook_txt_2_1"
		self:SetSkillIcon(self.mSkillIcon1,_oldSkill)
		self:SetSkillIcon(self.mSkillIcon2,_newSkill)
	else
		titleStr = "onhook_txt_1_1"
		self:SetSkillIcon(self.mSkillIcon,_newSkill)
	end
	self:SetWndEasyImage(self.mTitleBg,titleStr,nil,true)
	self:CreateWndEffect(self.mTitleEff,"fx_ui_shengxing_1","fx_ui_shengxing_1",100,false,false)
end

function UIJNUpLvPop:SetSkillIcon(item, itemdata)
	local skillIcon = self:FindWndTrans(item,"SkillBg/SkillIcon")
	local lvText = self:FindWndTrans(item,"LvBg/LvText")
	local nameText = self:FindWndTrans(item,"NameText")
	local resultNode = self:FindWndTrans(item,"DesBg/ResultNode")
	local desText = self:FindWndTrans(item,"DesBg/ResultNode/DesText")

	local InstanceID = item:GetInstanceID()
	local ref = gModelSorceryCard:GetSorceryCardSkillRefByRefId(itemdata)
	local skillRef = gModelHero:GetSkillByStarId(ref.skill)

	self:SetWndEasyImage(skillIcon,skillRef.icon)
	self:SetWndText(lvText,ref.level)
	local nameStr = string.replace(ccClientText(29542),ccLngText(skillRef.name),ref.level)
	self:SetWndText(nameText,nameStr)
	self:UpdateResultText(desText,resultNode,ccLngText(skillRef.description),InstanceID,1)
end
------------------------------------------------------------------
return UIJNUpLvPop


