---
--- Created by Administrator.
--- DateTime: 2024/11/14 18:18:59
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubDivineInfo:LChildWnd
local UISubDivineInfo = LxWndClass("UISubDivineInfo", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubDivineInfo:UISubDivineInfo()
	---@type StructDivineWeapon
	self.divineCfg = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubDivineInfo:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubDivineInfo:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubDivineInfo:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	local refId = self:GetWndArg("refId")
	self.refId = refId
	self.divineCfg = gModelDivineWeapon:GetDivineWeaponRef(refId)
	self:InitStatic()
	self:UpdatePanel()
end
function UISubDivineInfo:UpdateRed()
	local isActivate = gModelDivineWeapon:GetDivineWeaponByRefId(self.refId)
	local isShow = false
	if isActivate then
		isShow = gModelDivineWeapon:DivineWeaponUpRedById(self.refId)
	else
		isShow = gModelDivineWeapon:DivineWeaponStarRedById(self.refId)
	end
	self:SetRed(self.mBtnUp,isShow)
end

function UISubDivineInfo:UpdateAttrs()
	local info = gModelDivineWeapon:GetDivineWeaponByRefId(self.refId)
	local level = info and info.level
	self:SetWndText(self.mTxtLv,level and string.replace(ccClientText(14734),level) or ccClientText(46109))
	local SliderTrans = self:FindWndSlider(self.mSlider)
	if info then
		CS.ShowObject(self.mSliderTran,false)
		self:SetWndButtonText(self.mBtnUp,ccClientText(43710))
	else
		self:SetWndButtonText(self.mBtnUp,ccClientText(46117))
		CS.ShowObject(self.mSliderTran,true)
		local starCfg = gModelDivineWeapon:GetDiviWeaponStarByRefId(self.refId)
		local cost = starCfg[1].upNeed
		local costItem = LxDataHelper.ParseItem_4(cost)
		if costItem then
			self.costItem = costItem
			local hasNum = gModelItem:GetNumByRefId(costItem.itemId)
			SliderTrans.value = hasNum/costItem.itemNum
			local color = hasNum>=costItem.itemNum and "#4BFF45" or "#FF2010"
			self:SetWndText(self.mTxtProBar,string.replace("<color=#a1#>#a2#</color>/#a3#",color,LUtil.NumberCoversion(hasNum),costItem.itemNum))
		end
	end

	local uiAttrList = self._uiAttrList
	local attrList = gModelDivineWeapon:GetLevelAttr(self.refId)
	if attrList and info and info.level>0 then
		self.add = gModelDivineWeapon:GetDivineLevelAttrAdd(self.refId)
	end
	if not attrList then --最高級預覽
		local lvRefs = gModelDivineWeapon:GetDiviWeaponLvRefByRefId(self.refId)
		attrList = LxDataHelper.ParseAttrList(lvRefs[#lvRefs].attr)
	end
	if uiAttrList then
		uiAttrList:RefreshList(attrList)
	else
		uiAttrList = self:GetUIScroll("childDivineInfo")
		self._uiAttrList = uiAttrList
		uiAttrList:Create(self.mListAttrs,attrList,function(...) self:OnDrawAttrCell(...) end)
	end
end
function UISubDivineInfo:UpdateStar()
	local sizeDe = self.mStarBg.sizeDelta
	local maxStar = gModelDivineWeapon:GetMaxStar(self.refId)
	sizeDe.x = 40*maxStar
	self.mStarBg.sizeDelta = sizeDe
	sizeDe = self.mImgStar.sizeDelta
	sizeDe.x = 40* (gModelDivineWeapon:GetCurStar(self.refId) or 0)
	self.mImgStar.sizeDelta = sizeDe
end

function UISubDivineInfo:OnClickUp()
	local info = gModelDivineWeapon:GetDivineWeaponByRefId(self.refId)
	local SliderTrans = self:FindWndSlider(self.mSlider)
	if not info then
		if SliderTrans.value>=1 then
			gModelDivineWeapon:OnDivineWeaponUpStarReq(self.refId)
		else
			if self.costItem then gModelGeneral:OpenGetWayWnd({ itemId = self.costItem.itemId ,jumpBackCB = function()
				GF.CloseWndByName("UIDivineWeaponInfoWin")
			end}) end
		end
	else
		GF.OpenWnd("UIDivineUpLvPop",{refId = self.refId})
	end
end

function UISubDivineInfo:OnDrawAttrCell(list,item,itemdata,itempos)
	local AttrIcon = self:FindWndTrans(item,"AttrIcon")
	local AttrName = self:FindWndTrans(item,"AttrName")
	local AttrValue = self:FindWndTrans(item,"AttrValue")
	local numType,refId,value = itemdata.type,itemdata.refId,itemdata.value
	if AttrIcon then
		local icon = gModelHero:GetAttributeIconById(refId)
		self:SetWndEasyImage(AttrIcon,icon)
	end

	if AttrName then
		local name = gModelHero:GetAttributeNameById(refId)
		self:SetWndText(AttrName,name)
	end
	if self.add and self.add >0 then value = value + math.floor(value*(self.add/100)) end
	if AttrValue then
		local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,numType,value)
		-- if type(valueStr) == "number" then
		-- 	valueStr = LUtil.NumberCoversion(valueStr)
		-- end
		self:SetWndText(AttrValue,valueStr)
	end
end
function UISubDivineInfo:InitStatic()
	self:SetWndClick(self.mBtnUp,function() self:OnClickUp() end)
	self:SetWndClick(self.mBtnSkillPreview,function() self:OnClickPreView() end)
	self:SetWndText(self.mTxtSkillPreview,ccClientText(46111))
	self:SetWndButtonText(self.mBtnUp,ccClientText(43710))
	self:SetWndText(self.mTxtDescTitle,ccClientText(20126))
	self:SetWndText(self.mTxtTitle,ccLngText(self.divineCfg.name))
	local quality = GameTable.RarityRef[self.divineCfg.quality]
	local info = gModelDivineWeapon:GetDivineWeaponByRefId(self.refId)
	LxUiHelper.SetXTextColor(self.mTxtTitle,LUtil.ColorByHex(quality.nameColor))
	self:SetWndEasyImage(self.mDivineItem,self.divineCfg.icon,nil,true)
	self:SetWndImageGray(self.mDivineItem,not info)
	if info then self:ActivateEffect(self.mDivineItem,true,self.divineCfg.effect) end
	self:WndEventRecv(EventNames.On_Item_Change, function(...)
		self:UpdateAttrs()
		self:UpdateRed()

	end)
	self:WndEventRecv(EventNames.DIVINE_WEAPON_UPDATE,function(isActive)
		self:UpdatePanel()
		if isActive then self:ActivateEffect(self.mDivineItem,true,self.divineCfg.effect) end
	end)
	self:WndEventRecv(EventNames.ON_WND_CLOSE,function(uiname)
		if uiname ~= "UIDivineUpLvPop" then return end
		self:UpdateAttrs()
	end)

end

function UISubDivineInfo:UpdateLinkDivineWeapon()
	CS.ShowObject(self.mLinkDivineWeapon ,self.divineCfg.linkGoal)
	local info = gModelDivineWeapon:GetDivineWeaponByRefId(self.divineCfg.refId)
	if (self.divineCfg.linkType == 1 and self.divineCfg.linkGoal) or (info and info.linkRefId and info.linkRefId>0) then
		local linkId = self.divineCfg.linkGoal[1]
		if info and info.linkRefId and info.linkRefId>0 then linkId = info.linkRefId end
		local ref = gModelDivineWeapon:GetDivineWeaponRef(linkId)
		local linkInfo = gModelDivineWeapon:GetDivineWeaponByRefId(linkId)
		local qualityCfg = GameTable.RarityRef[ref.quality]
		local skillid = gModelDivineWeapon:GetSkillId(linkId)
		local skillCfg = GameTable.SnakeSkillRef[skillid]
		local isLink = info and info.linkRefId and info.linkRefId > 0
		self:SetWndText(self.mLinkNum,linkInfo and linkInfo.level or 0)
		self:SetWndText(self.mLinkSkillLv,skillCfg and skillCfg.level or 0)
		self:SetWndEasyImage(self.mLinkIconBg,qualityCfg.iconBg)
		self:SetWndEasyImage(self.mLinkIcon,ref.icon)
		self:SetWndEasyImage(self.mLinkSkillIcon,skillCfg.icon)
		CS.ShowObject(self.mDivineLock,not linkInfo)
		CS.ShowObject(self.mImgLock, not isLink)
		CS.ShowObject(self.mTxtTips, false)
		CS.ShowObject(self.mLinkSkill, true)
		CS.ShowObject(self.mItem, true)
		if not isLink then
			self:SetWndText(self.mTxtSkillRate,string.replace(ccClientText(46113),ccLngText(ref.name)))
		else
			self:SetWndText(self.mTxtSkillRate,string.replace(ccClientText(46114),linkInfo.skillRate))
		end
		self:SetWndClick(self.mLinkSkillIcon,function()
			local star = gModelDivineWeapon:GetCurStar(linkId) or 0
			GF.OpenWnd("UIDivineWeaponTips",{refId = linkId,starNum = star})
		end)
		self:SetWndClick(self.mLinkIcon,function()
			GF.OpenWnd("UIDivineWeaponPopTips",{refId = linkId})
		end)
	else
		CS.ShowObject(self.mTxtTips, true)
		CS.ShowObject(self.mLinkSkill, false)
		CS.ShowObject(self.mItem, false)
		self:SetWndText(self.mTxtTips,string.replace(ccClientText(46161),ccLngText(self.divineCfg.name)))
	end
	if not self.divineCfg.linkGoal then
		local sizeDe = self.mListAttrs.sizeDelta
		sizeDe.y = 156
		self.mListAttrs.sizeDelta = sizeDe
		local pos = self.mBtns.anchoredPosition
		pos.y = -96
		self.mBtns.anchoredPosition = pos
	end
end
function UISubDivineInfo:OnClickPreView()
	local info = gModelDivineWeapon:GetDivineWeaponByRefId(self.refId)
	local star = not info and gModelDivineWeapon:GetMaxStar(self.refId)
	GF.OpenWnd("UIDivineWeaponTips",{refId = self.refId,starNum = star})
end

function UISubDivineInfo:OnUpdateSkill()
	local skillId = gModelDivineWeapon:GetSkillId(self.refId)
	local skillCfg = GameTable.SnakeSkillRef[skillId]
	self:SetWndEasyImage(self.mSkillItem,skillCfg.icon)
	self:SetWndText(self.mTxtDesc,ccLngText(skillCfg.description))
	self:SetWndText(self.mTxtSkillName,ccLngText(skillCfg.name))
	local ref = GameTable.DivineWeaponRef[self.refId]
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
end
function UISubDivineInfo:UpdatePanel()
	self:OnUpdateSkill()
	self:UpdateAttrs()
	self:UpdateStar()
	self:UpdateLinkDivineWeapon()
	self:UpdateRed()
end
function UISubDivineInfo:ActivateEffect(trans,isShow,effName)
	local instance = trans:GetInstanceID()
	local effecTran = self:FindWndEffectByKey(instance)
	if effecTran then
		effecTran:SetVisible(isShow)
	elseif isShow then
		self:CreateWndEffect(trans, effName, instance, 100, false, false)
	end
end
------------------------------------------------------------------
return UISubDivineInfo