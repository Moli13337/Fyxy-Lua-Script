---
--- Created by Administrator.
--- DateTime: 2024/11/21 17:23:32
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubDivineLink:LChildWnd
local UISubDivineLink = LxWndClass("UISubDivineLink", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubDivineLink:UISubDivineLink()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubDivineLink:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubDivineLink:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubDivineLink:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
end
function UISubDivineLink:OnCreateEffect(trans,isShow,effName)
	local instance = trans:GetInstanceID()
	local effecTran = self:FindWndEffectByKey(instance)
	if effecTran then
		effecTran:SetVisible(isShow)
	elseif isShow then
		self:CreateWndEffect(trans, effName, instance, 100, false, false)
	end
end

function UISubDivineLink:OnClickPreView()
	local ref = self.ref
	local linkRefId = ref.linkGoal and ref.linkGoal[1]
	GF.OpenWnd("UIDivineWeaponAttachPop",{refId = linkRefId})
end

function UISubDivineLink:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetTextTile(self.mTxtTitle,ccClientText(46120))
	self.refId = self:GetWndArg("refId")
	self.ref = gModelDivineWeapon:GetDivineWeaponRef(self.refId)
	self:SetWndClick(self.mBtnSkillPreview,function() self:OnClickPreView() end)
	self:SetWndClick(self.mBtnUpLv,function() self:OnClickActivate() end)
	self:SetWndText(self.mTxtSkillPreview,ccClientText(46111))
	self:SetWndText(self.mTxtDescTitle,ccClientText(20126))
	self:SetWndClick(self.mRightIcon,function()
		local info = gModelDivineWeapon:GetDivineWeaponByRefId(self.refId)
		if (info and info.linkRefId and info.linkRefId>0) or self.ref.linkType==1 then return end
		GF.OpenWnd("UIDivineAttachSelect",{refId = self.refId})
	end)

	self:WndEventRecv(EventNames.DIVINE_WEAPON_UPDATE,function()
		self:UpdateCard()
		self:OnUpdateSkill()
	end)
	self:UpdateCard()
	self:OnUpdateSkill()
	self:InitEmptyTips()
end
function UISubDivineLink:OnClickActivate()
	local info = gModelDivineWeapon:GetDivineWeaponByRefId(self.refId)
	if not info then
		GF.ShowMessage(ccClientText(46162))
		return
	end
	local ref = self.ref
	local linkState = info and info.linkRefId and info.linkRefId>0
	if linkState then
		gModelDivineWeapon:OnDivineWeaponLinkReq(self.refId, 0)
	else
		if ref.linkType == 1 then
			local linkInfo = ref.linkGoal and gModelDivineWeapon:GetDivineWeaponByRefId(ref.linkGoal[1])
			if not linkInfo then
				GF.ShowMessage(ccClientText(46121))
				return
			end
			local useId = gModelDivineWeapon:GetMainAttachRefId(ref.linkGoal[1])
			if useId >0 then
				GF.ShowMessage(ccClientText(46169))
				return
			end
			gModelDivineWeapon:OnDivineWeaponLinkReq(self.refId, ref.linkGoal[1])
		else
			GF.OpenWnd("UIDivineAttachSelect",{refId = self.refId})
		end
	end
end

-- 空列表提示
function UISubDivineLink:InitEmptyTips()
	local text = self.mEmptyText
	local emptyList = self:GetCommonEmptyList("_empty")
	local data =
	{
		refId = 43002,
		IntroTran = text,
	}
	emptyList:RefreshUI(data)
end
function UISubDivineLink:OnUpdateSkill()
	local ref = self.ref
	local linkRefId = ref.linkGoal and ref.linkGoal[1]
	local info = gModelDivineWeapon:GetDivineWeaponByRefId(ref.refId)
	local linkState = info and info.linkRefId and info.linkRefId>0
	CS.ShowObject(self.mImgLock,not linkState)
	if (ref.linkType ==1 and linkRefId ) or linkState then
		CS.ShowObject(self.mSkill,true)
		CS.ShowObject(self.mNoRecord,false)
		local skillId = gModelDivineWeapon:GetSkillId(linkRefId)
		local skillCfg = GameTable.SnakeSkillRef[skillId]
		self:SetWndEasyImage(self.mSkillItem,skillCfg.icon)
		self:SetWndText(self.mTxtDesc,ccLngText(skillCfg.description))
		self:SetWndText(self.mTxtSkillName,ccLngText(skillCfg.name))
		local ref = gModelDivineWeapon:GetDivineWeaponRef(linkRefId)
		local skillFlagTxt = ref and string.split(ccLngText(ref.logoTxt),"|")
		local skillFlagIcon = ref and string.split(ref.logoIcon,"|")
		local instanceId = self.mSkillFlag:GetInstanceID()
		local itemCache = self:GetComponentCache(instanceId)
		local skillFlags = itemCache and itemCache.skillFlags or {}
		if not itemCache then
			itemCache = {
				skillFlags = skillFlags
			}
			for index, value in ipairs(skillFlagIcon) do
				local obj = CS.InstantObject(self.mSkillFlag.gameObject)
				obj.transform:SetParent(self.mSkillFlag.parent,false)
				skillFlags[index] = obj.transform
			end
		end
		for indx, trans in ipairs(skillFlags) do
			self:SetWndEasyImage(trans,skillFlagIcon[indx])
			self:SetTextTile(trans,ccLngText(skillFlagTxt[indx]))
		end
		CS.ShowObject(self.mSkillFlag,false)

		local curStarCfg = gModelDivineWeapon:GetCurStarRef(linkRefId)
		if not curStarCfg then
			local starCfg = gModelDivineWeapon:GetDiviWeaponStarByRefId(linkRefId)
			curStarCfg = starCfg[1]
		end
		self:SetWndText(self.mTxtTips,string.replace(ccClientText(46114),curStarCfg.linkRate))
	else
		CS.ShowObject(self.mSkill,false)
		CS.ShowObject(self.mNoRecord,true)
	end
end

function UISubDivineLink:UpdateCard()
	local ref = self.ref
	local info = gModelDivineWeapon:GetDivineWeaponByRefId(self.refId)
	local linkState = info and info.linkRefId and info.linkRefId>0
	local linkRefId = linkState and info.linkRefId or nil
	if ref.linkType == 1 then linkRefId = ref.linkGoal[1] end
	local linkRef = linkRefId and gModelDivineWeapon:GetDivineWeaponRef(linkRefId)
	self:SetTextTile(self.mLeftName,ccLngText(ref.name))
	self:SetWndEasyImage(self.mLeftIcon,ref.icon,nil,true)
	self:SetWndButtonText(self.mBtnUpLv, linkState and ccClientText(46164) or ccClientText(46165))-- 取消 启用
	self:SetWndImageGray(self.mLeftIcon,not info)
	CS.ShowObject(self.mLeftIcon,not info)
	CS.ShowObject(self.mRightIcon,not linkState)
	self:SetTextTile(self.mRightName,linkRef and ccLngText(linkRef.name) or "")
	if linkRefId and ref.linkType == 1 then
		CS.ShowObject(self.mRightName,true)
		CS.ShowObject(self.mRightStarBg,true)
		self:SetWndEasyImage(self.mRightIcon,linkRef.icon,nil,true)
		local info = gModelDivineWeapon:GetDivineWeaponByRefId(linkRef.refId)
		self:SetWndImageGray(self.mRightIcon,not info)
	else
		CS.ShowObject(self.mRightName,linkState)
		CS.ShowObject(self.mRightStarBg,linkState)
		self:SetWndEasyImage(self.mRightIcon,linkState and linkRef.icon or "card_add_1",nil,true)
		self.mRightIcon.localScale = linkState and Vector3(0.8,0.8,0.8) or Vector3.one
	end
	self:OnCreateEffect(self.mEffect,linkState,"fx_sw_fuji")
	self:OnCreateEffect(self.mLeftEffect,not not info,ref.effect)
	if ref.linkType ~= 1 then self:DestroyWndEffectByKey(self.mRightEffect:GetInstanceID()) end
	self:OnCreateEffect(self.mRightEffect,linkState,linkRef and linkRef.effect)
	self:UpdateStar()
end
function UISubDivineLink:UpdateStar()
	local sizeDe = self.mLeftStarBg.sizeDelta
	local maxStar = gModelDivineWeapon:GetMaxStar(self.refId)
	sizeDe.x = 40*maxStar
	self.mLeftStarBg.sizeDelta = sizeDe
	self.mRightStarBg.sizeDelta = sizeDe
	sizeDe = self.mLeftStar.sizeDelta
	sizeDe.x = 40* (gModelDivineWeapon:GetCurStar(self.refId) or 0)
	self.mLeftStar.sizeDelta = sizeDe
	local linkRefId = self.ref.linkGoal and self.ref.linkGoal[1]
	sizeDe = self.mRightStar.sizeDelta
	sizeDe.x = 40* (gModelDivineWeapon:GetCurStar(linkRefId) or 0)
	self.mRightStar.sizeDelta = sizeDe
end

------------------------------------------------------------------
return UISubDivineLink