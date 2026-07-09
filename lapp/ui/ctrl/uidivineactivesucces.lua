---
--- Created by Administrator.
--- DateTime: 2024/11/15 11:13:07
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDivineActiveSucces:LWnd
local UIDivineActiveSucces = LxWndClass("UIDivineActiveSucces", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDivineActiveSucces:UIDivineActiveSucces()
	self._effectKey = "divineActive" 
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDivineActiveSucces:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDivineActiveSucces:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDivineActiveSucces:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self.preStarRefId = self:GetWndArg("preStarRefId")
	self.refId = self:GetWndArg("refId")
	self.isActive = self:GetWndArg("isActive")
	self.divineCfg = gModelDivineWeapon:GetDivineWeaponRef(self.refId)
	self:SetWndText(self.mTxtCloseTips,ccClientText(41037))
	self:SetWndEasyImage(self.mLeftIcon,self.divineCfg.icon,nil)
	self:SetWndEasyImage(self.mRightIcon,self.divineCfg.icon,nil)
	self:SetWndClick(self.mMask, function(...) if self._playEndEffect then self:WndClose() end end)
	self:SetWndClick(self.mLeftSkill, function() self:OnClickTips(-1) end)
	self:SetWndClick(self.mRightSkill, function() self:OnClickTips(0) end)
	
	CS.ShowObject(self.mImgTitle, false)
	self:UpdateSkillStar()
	self:UpdateAttr()
end

-- - 播放动画
function UIDivineActiveSucces:PlayEffect()
	local seqTween
	self:TweenSeqKill(self._effectKey)
	seqTween = self:TweenSeqCreate(self._effectKey, function(seq)
		local showTopTime = 0.2
		local showAttrTime = 0.08

		local bgTween = self.mImgTitle:DOScale(Vector3.New(1, 1, 1), 0.2)
		seq:Append(bgTween)
		seq:AppendCallback(function()
			self:CreateTitleEffect()
			LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_UPGRADE_COMMON)
		end)
		seq:AppendInterval(showTopTime)

		for i, trans in ipairs(self.attrTrans or {}) do
			seq:AppendCallback(function()
				CS.ShowObject(trans,true)
				self:CreateEffect(trans, "fx_ui_shengxing_3", "eff" .. i)
				local tween = trans:DOScale(Vector3.New(1, 1, 1), showAttrTime * 0.8)
				tween:Play()
			end)
			seq:AppendInterval(showAttrTime)
		end
		return seq
	end)
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(self._effectKey)
		self._playEndEffect = true
	end)
end

function UIDivineActiveSucces:UpdateAttr()
	local uiAttrList = self._uiAttrList
	local preAttrList
	if self.preStarRefId then
		local preStarRef = GameTable.DivineWeaponStarRef[self.preStarRefId]
		preAttrList = LxDataHelper.ParseAttrList(preStarRef.attr)
	end
	local curAttrList = gModelDivineWeapon:GetStarAttr(self.refId)
	local curAttrMap =  {}
	if not preAttrList then
		preAttrList = curAttrList
		curAttrList = nil
	end
	for _, value in ipairs(curAttrList or {}) do
		if not curAttrMap[value.refId] then curAttrMap[value.refId] = {} end
		curAttrMap[value.refId][value.type] = value.value
	end
	self.curAttrMap = curAttrMap
	self.attrCount = #preAttrList
	self.attrTrans = {}
	if uiAttrList then
		uiAttrList:RefreshList(preAttrList)
	else
		uiAttrList = self:GetUIScroll("childDivineStar")
		self._uiAttrList = uiAttrList
		uiAttrList:Create(self.mListAttrs,preAttrList,function(...) self:OnDrawAttrCell(...) end)
	end
end


function UIDivineActiveSucces:OnDrawAttrCell(list,item,itemdata,itempos)
	local lAttrIcon = self:FindWndTrans(item,"Attrs/LeftAttr/AttrIcon")
	local lAttrName = self:FindWndTrans(item,"Attrs/LeftAttr/AttrName")
	local lAttrValue = self:FindWndTrans(item,"Attrs/LeftAttr/LeftValue")
	local rAttrValue = self:FindWndTrans(item,"Attrs/RightValue")
	local arrow = self:FindWndTrans(item,"Attrs/AttrArrow")
	local numType,refId,value = itemdata.type,itemdata.refId,itemdata.value
	local right = not not self.curAttrMap[refId]
	self.attrTrans[itempos] = item
	CS.ShowObject(item,false)
	local icon = gModelHero:GetAttributeIconById(refId)
	if lAttrIcon then self:SetWndEasyImage(lAttrIcon,icon) end
	local name = gModelHero:GetAttributeNameById(refId)
	if lAttrName then self:SetWndText(lAttrName,name) end
	local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,numType,value)
	-- if type(valueStr) == "number" then
	-- 	valueStr = LUtil.NumberCoversion(valueStr)
	-- end
	if lAttrValue then self:SetWndText(lAttrValue,valueStr) end

	CS.ShowObject(rAttrValue,right)
	CS.ShowObject(arrow,right)
	if right then
		local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,numType,self.curAttrMap[refId][numType])
		-- if type(valueStr) == "number" then
		-- 	valueStr = LUtil.NumberCoversion(valueStr)
		-- end
		self:SetWndText(rAttrValue,"<color=#139057>"..valueStr.."</color>")
	end
	if self.attrCount == itempos then
		self:PlayEffect()
	end
end

function UIDivineActiveSucces:OnClickTips(num)
	local star = gModelDivineWeapon:GetCurStar(self.refId)
	star = star+num
	GF.OpenWnd("UIDivineWeaponTips",{refId = self.refId, starNum = star})
end

-- 创建特效
function UIDivineActiveSucces:CreateEffect(trans, effectName, effectKey, effectSize)
	effectKey = effectKey or effectName
	effectSize = effectSize or 100
	self:CreateWndEffect(trans, effectName, effectKey, effectSize, false, false)
end

-- 创建标题特效
function UIDivineActiveSucces:CreateTitleEffect()
	CS.ShowObject(self.mImgTitle, true)
	self:CreateEffect(self.mImgTitle, "fx_ui_shengxing_1")
end

function UIDivineActiveSucces:UpdateSkillStar()
	local sizeDe = self.mLeftStarBg.sizeDelta
	local maxStar = gModelDivineWeapon:GetMaxStar(self.refId)
	local starCfg = gModelDivineWeapon:GetCurStarRef(self.refId) or {}
	local skillCfg = starCfg.skillId and GameTable.SnakeSkillRef[starCfg.skillId]
	local preStarCfg = self.preStarRefId and GameTable.DivineWeaponStarRef[self.preStarRefId]
	local preSkillCfg = preStarCfg and GameTable.SnakeSkillRef[preStarCfg.skillId]
	self:SetWndEasyImage(self.mLeftSkill,preSkillCfg and preSkillCfg.icon)
	self:SetWndText(self.mLeftSkillLv,starCfg and starCfg.rankNow or "")
	self:SetWndText(self.mRightSkillLv,starCfg and starCfg.rankNow+1)
	self:SetWndEasyImage(self.mImgTitle,self.isActive and "draconic_txt_4" or "draconic_txt_2")
	sizeDe.x = 40*maxStar
	self.mLeftStarBg.sizeDelta = sizeDe
	self.mRightStarBg.sizeDelta = sizeDe
	sizeDe = self.mLeftStar.sizeDelta
	sizeDe.x = 40* (preStarCfg and preStarCfg.rankNow or 0)
	self.mLeftStar.sizeDelta = sizeDe
	sizeDe = self.mRightStar.sizeDelta
	sizeDe.x = 40* (starCfg.rankNow or 0)
	self.mRightStar.sizeDelta = sizeDe
	self:SetWndEasyImage(self.mRightSkill,skillCfg and skillCfg.icon)
	if self.isActive then
		CS.ShowObject(self.mLeftIcon,false)
		CS.ShowObject(self.mLeftSkillBg,false)
		CS.ShowObject(self.mImgArrow,false)
		local pos = self.mRightIcon.anchoredPosition
		pos.x = 0
		self.mRightIcon.anchoredPosition = pos
		local pos = self.mRightSkillBg.anchoredPosition
		pos.x = 0
		self.mRightSkillBg.anchoredPosition = pos
	end
end
------------------------------------------------------------------
return UIDivineActiveSucces