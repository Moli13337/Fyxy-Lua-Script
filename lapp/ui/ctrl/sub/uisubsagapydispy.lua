---
--- Created by BY.
--- DateTime: 2023/10/14 18:14:54
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubSagaPyDisPy:LChildWnd
local UISubSagaPyDisPy = LxWndClass("UISubSagaPyDisPy", LChildWnd)
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
local LUISkillCtrl = LxRequire("LApp.UI.Display.LUISkillCtrl")
local typeof = typeof
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local Time = Time
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubSagaPyDisPy:UISubSagaPyDisPy()
	self._heroKey = "_heroKey"
	self._heroEffKey = "_heroEffKey"
	self._effectKey = "_effectKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubSagaPyDisPy:OnWndClose()
	self:TweenSeqKill(self._effectKey)
	self:TimerStop(self._heroEffKey)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubSagaPyDisPy:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubSagaPyDisPy:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UISubSagaPyDisPy:InitCommand()
	local para = self:GetWndArg("para")

	local adHeroSpine = para.adHeroSpine
	local adPerformance = para.adPerformance
	local adPosChange = para.adPosChange
	local adSkill = para.adSkill
	local adBgChange = para.adBgChange
	local adEffect1 = para.adEffect1
	local adEffect2 = para.adEffect2
	if not string.isempty(adPerformance)then
		local adPerformanceArr = string.split(adPerformance,"|")
		local list = {}
		for i, v in ipairs(adPerformanceArr) do
			local arr = string.split(v,"=")
			local data = {
				pos = LxDataHelper.ParseVector2NotEmpty(arr[1]),
				scale = Vector3.New(tonumber(arr[2]),tonumber(arr[2]),tonumber(arr[2]))
			}
			table.insert(list,data)
		end
		self._adPerformance = list
	end
	self._adPosChange = adPosChange or 2
	self._adSkill = adSkill or 2
	self._adBgChange = adBgChange or 2
	if not string.isempty(adEffect1)then
		self:CreateWndEffect(self.mEff1,adEffect1,adEffect1,100,false,false)
	end
	if not string.isempty(adEffect2)then
		self:CreateWndEffect(self.mEff2,adEffect2,adEffect2,100,false,false)
	end

	self:InitHeroPb(adHeroSpine)
	self:TimerStop(self._heroKey)
	self:TimerStart(self._heroKey,2, false, -1)

	self:PlayEffect()
end
function UISubSagaPyDisPy:InitEvent()

end

--设置小人控件
function UISubSagaPyDisPy:InitHeroPb(refId)
	local pbName = gModelHero:GetPrefabNameById(refId)
	local uiHeroObjList = self._uiHeroObjList
	if not uiHeroObjList then
		uiHeroObjList = {}
		self._uiHeroObjList = uiHeroObjList
	end
	if self._uiSkillCtrl then
		self._uiSkillCtrl:Destroy()
		self._uiSkillCtrl = nil
	end
	local newUIHeroObj = uiHeroObjList[pbName]
	local oldUIHeroObj = self._curUIHeroObj
	if oldUIHeroObj and newUIHeroObj ~= oldUIHeroObj then
		oldUIHeroObj:ShowHero(false)
	end
	if not newUIHeroObj then
		newUIHeroObj = LUIHeroObject:New(self)
		uiHeroObjList[pbName] = newUIHeroObj
		self._curUIHeroObj = newUIHeroObj
		newUIHeroObj:Create(self.mHeroPb,pbName,pbName)
		newUIHeroObj:SetScale(1.2)
		local star = gModelHero:GetHeroInitStarByRefId(refId)
		newUIHeroObj:SetHeroData(nil, refId, star, nil,true)
		newUIHeroObj:ShowHero(true)
		newUIHeroObj:StartLoad()
	else
		self._curUIHeroObj = newUIHeroObj
		local star = gModelHero:GetHeroInitStarByRefId(refId)
		newUIHeroObj:SetHeroData(nil, refId, star, nil, true)
		newUIHeroObj:ShowHero(true)
	end

	self:TimerStop(self._heroEffKey)
	self:TimerStart(self._heroEffKey,0, false, -1)
end

function UISubSagaPyDisPy:PlayEffect()
	local mHeroSpint = self.mHeroSpint
	local mBgImage = self.mBgImage
	local bgImageGroup = mBgImage:GetComponent(typeofCanvasGroup)
	local _effectKey = self._effectKey
	local skillTime = self._adPosChange
	local alphaTime = self._adBgChange
	local adPerformance = self._adPerformance

	self:SetAnchorPos(mHeroSpint, adPerformance[1].pos)
	mHeroSpint.localScale = adPerformance[1].scale
	bgImageGroup.alpha = 1
    CS.ShowObject(mBgImage,true)

	local seqTween
	self:TweenSeqKill(_effectKey)
	if not seqTween then
		seqTween = self:TweenSeqCreate(_effectKey,function(seq)
			seq:AppendCallback(function ()
				self:OnClickHeroSpine(self._adSkill)
			end)
			seq:AppendInterval(skillTime)
			seq:AppendCallback(function ()
				if self._uiSkillCtrl then
					self._uiSkillCtrl:Destroy()
					self._uiSkillCtrl = nil
				end
			end)
			local moveTween = mHeroSpint:DOLocalMove(adPerformance[2].pos,alphaTime)
			seq:Join(moveTween)
			local scaleTween = mHeroSpint:DOScale(adPerformance[2].scale,alphaTime)
			seq:Join(scaleTween)
			--seq:Insert(skillTime,scaleTween)
			local _bgTemp = YXTween.TweenFloat(1, 0, alphaTime, function(ival)
				bgImageGroup.alpha = ival
			end)
			seq:Join(_bgTemp)
			return seq
		end)
	end
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(_effectKey)
        CS.ShowObject(mBgImage,false)
	end)
end
function UISubSagaPyDisPy:OnClickHeroSpine(index)
	if(not self._curUIHeroObj)then
		return
	end
	local heroObj = self._curUIHeroObj
	local spine = heroObj:GetDpObject()
	if not spine then return end
	local nowPlayAniName = spine:GetCurTrackEntryName()
	if nowPlayAniName ~= "idle" and nowPlayAniName ~= nil then
		return
	end
	local panelPlayEff = heroObj:SeqOneSkill(index)
	if not panelPlayEff then
		heroObj:PlayAttackAni()
		return
	end
	local skillCtr = self._uiSkillCtrl
	if skillCtr then
		skillCtr:Destroy()
		skillCtr = nil
	end

	skillCtr = LUISkillCtrl:New(self)
	self._uiSkillCtrl = skillCtr

	skillCtr:InitData(heroObj, panelPlayEff, self.mHeroEff, 0, 3, 120)
	skillCtr:PreLoadPlaySkill()
end

function UISubSagaPyDisPy:OnTimer(key)
	if(key == self._heroKey)then
		self:OnClickHeroSpine()
	elseif(key == self._heroEffKey)then
		local time = Time.unscaledTime
		if self._curUIHeroObj then
			self._curUIHeroObj:OnRun(time)
		end
		if self._uiSkillCtrl then
			self._uiSkillCtrl:OnRun(time)
		end
	end
end
function UISubSagaPyDisPy:InitMessage()

end
------------------------------------------------------------------
return UISubSagaPyDisPy


