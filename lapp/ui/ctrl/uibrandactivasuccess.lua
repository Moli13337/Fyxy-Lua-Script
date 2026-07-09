---
--- Created by Administrator.
--- DateTime: 2025/6/4 11:34:35
---
------------------------------------------------------------------
local LWnd = LWnd
local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder
---@class UIBrandActivaSuccess:LWnd
local UIBrandActivaSuccess = LxWndClass("UIBrandActivaSuccess", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBrandActivaSuccess:UIBrandActivaSuccess()
	self._effectKey = "_PeteffectKey"
	self._starTransList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBrandActivaSuccess:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBrandActivaSuccess:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBrandActivaSuccess:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndClick(self.mMask,function() self:WndClose() end)
	self.refId = self:GetWndArg("refId")
	local oldStar = self:GetWndArg("oldStarId")
	self.oldStarRef = oldStar and GameTable.BadgeStarRef[oldStar]
	self.isActiva = not oldStar
	self:SetWndEasyImage(self.mImgTitle,self.isActiva and "halidom_txt_2" or "draconic_txt_2")
	self:OnUpdatePanel()
	self:OnUpdateAttr()
	self:OnUpdateStar()
	self:PlayEffect()
end
function UIBrandActivaSuccess:OnDrawAttrCell(list,item,itemdata,itempos)
	local AttrArrow = self:FindWndTrans(item,"AttrArrow")
	local AttrLeft = self:FindWndTrans(item,"AttrLeft")
	local AttrValue = self:FindWndTrans(item,"AttrValue")
	local leftStr = ""
	local rightStr = ""
	local str = itempos ==1 and 47521 or 47522
	leftStr = string.replace(ccClientText(str),itemdata.param1)
	rightStr = string.replace(ccClientText(str),itemdata.param2)
	if self.isActiva then
		self:SetWndText(AttrLeft,leftStr)
		CS.ShowObject(AttrValue,false)
		CS.ShowObject(AttrArrow,false)
	else
		self:SetWndText(AttrLeft,leftStr)
		self:SetWndText(AttrValue,rightStr)
	end
	CS.ShowObject(item,false)
	table.insert(self._starTransList,item)
end


function UIBrandActivaSuccess:OnUpdateStar()
	CS.ShowObject(self.mItemStar,not self.isActiva)
	if self.isActiva then return end
	self:SetComStar(self.mComStarLeft, self.oldStarRef.star)
	local info = gModelBadge:GetBadgeInfo(self.refId)
	local starCfg = GameTable.BadgeStarRef[info.star]
	self:SetComStar(self.mComStarRight, starCfg.star)
end
function UIBrandActivaSuccess:OnUpdateAttr()
	---@type BadgeInfo
	local info = gModelBadge:GetBadgeInfo(self.refId)
	local starCfg = info:GetStarRef()
	local attrs = {}
	table.insert(attrs,{param1 = self.isActiva and starCfg.collegeLv or self.oldStarRef.collegeLv,
						param2 = self.isActiva and -1 or starCfg.collegeLv })
	table.insert(attrs,{param1 = self.isActiva and starCfg.wearNum or self.oldStarRef.wearNum,
						param2 = self.isActiva and -1 or (starCfg.wearNum>0 and starCfg.wearNum or ccClientText(47551))})
	local uiAttrList = self:GetUIScroll("PetLvAttrList")
	uiAttrList:Create(self.mListAttrs,attrs,function(...) self:OnDrawAttrCell(...) end)
end
function UIBrandActivaSuccess:CreateEffect(trans,effectName,effectKey,effectSize)
	effectKey = effectKey or effectName
	effectSize = effectSize or 100
	self:CreateWndEffect(trans,effectName,effectKey,effectSize,false,false)
end
function UIBrandActivaSuccess:OnUpdatePanel()
	local ref = GameTable.BadgeRef[self.refId]
	self:SetWndText(self.mTxtName,ccLngText(ref.name))
	local baseClass = self:GetCommonIcon(self.mImgIcon)
	baseClass:Create(self.mImgIcon)
	baseClass:SetCommonReward(LItemTypeConst.TYPE_BADGE, self.refId,1)
	baseClass:EnableShowNum(false)
	baseClass:DoApply()

	---@type BadgeInfo
	local info = gModelBadge:GetBadgeInfo(self.refId)
	local starCfg = info:GetStarRef()
	CS.ShowObject(self.mItemAttr,false)
	CS.ShowObject(self.mTxtDesc,false)

	if starCfg.skill and starCfg.skill>0 then
		CS.ShowObject(self.mTxtDesc,true)
		local skillCfg = gModelSkill:GetSkillRef(starCfg.skill)
		if skillCfg then
			self:SetTextTile(self.mDescLv,"Lv."..skillCfg.level)
			local str = ccLngText(skillCfg.description)
			local num = #str
			if num > 40 then
				self.mTxtDesc.transform.sizeDelta = Vector2(360, self.mTxtDesc.transform.sizeDelta.y)
			end
			self:SetWndText(self.mTxtDesc,"  "..ccLngText(skillCfg.description))
		end
		CS.ShowObject(self.mDescAttrUp,not self.isActiva)
	end
	self:SetWndText(self.mTxtCloseTips,ccClientText(41037))
end

function UIBrandActivaSuccess:PlayEffect()

	local info = gModelBadge:GetBadgeInfo(self.refId)
	local isShowStar = info:GetBadgeStar()>0
	-- CS.ShowObject(self.mImgTitle,false)
	-- CS.ShowObject(self.mImgQuality,false)
	local seqTween
	self:TweenSeqKill(self._effectKey)
	seqTween = self:TweenSeqCreate(self._effectKey,function(seq)
		local showTopTime = 0.2
		local showAttrTime = 0.1

		-- CS.ShowObject(self.mImgTitle,true)
		seq:AppendCallback(function ()
			self:CreateEffect(self.mImgTitle,"fx_ui_shengxing_1")
		end)
		seq:AppendInterval(showTopTime)

		-- CS.ShowObject(self.mImgQuality,true)
		seq:AppendCallback(function ()
			self:CreateEffect(self.mEffRoot,"fx_ui_shengxing_2")
		end)
		seq:AppendInterval(showTopTime)

		if isShowStar then
			-- CS.ShowObject(self.mItemStar,true)
			seq:AppendCallback(function ()
				self:CreateEffect(self.mItemStar,"fx_ui_shengxing_3","itemStarEffect")
			end)
		end
		seq:AppendInterval(showTopTime)

		for i,v in ipairs(self._starTransList) do
			seq:AppendCallback(function ()
				self:CreateEffect(v,"fx_ui_shengxing_3","eff"..i)
				CS.ShowObject(v,true)
			end)
			seq:AppendInterval(showAttrTime)
		end

		-- if starCfg.skillId and starCfg.skillId>0 then
		seq:AppendCallback(function ()
			-- self:CreateEffect(self.mItemAttr,"fx_ui_shengxing_3","itemAttrEffect")
			LayoutRebuilder.ForceRebuildLayoutImmediate(self.mPanel2)
		end)
		seq:AppendInterval(showAttrTime)

		-- if starCfg.attrChangeAdd and  starCfg.attrChangeAdd>0 then
		-- 	seq:AppendCallback(function ()
		-- 		self:CreateEffect(self.mTxtDesc,"fx_ui_shengxing_3")
		-- 	end)
		-- end
		-- seq:AppendInterval(showAttrTime)

		return seq
	end)
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(self._effectKey)
	end)
	gLGameAudio:PlaySound("SoundS_14")
end


------------------------------------------------------------------
return UIBrandActivaSuccess