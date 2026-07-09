---
--- Created by Administrator.
--- DateTime: 2024/12/10 14:36:06
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDivineResonanceUpPop:LWnd
local UIDivineResonanceUpPop = LxWndClass("UIDivineResonanceUpPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDivineResonanceUpPop:UIDivineResonanceUpPop()
	self._effectKey = "resonanceEffect"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDivineResonanceUpPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDivineResonanceUpPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDivineResonanceUpPop:OnStart()
	LWnd.OnStart(self)


	self.jpj = gLGameLanguage:IsJapanVersion()
	self:InitUI()
	self:SetWndClick(self.mMask, function(...)
		self:TweenSeqKill(self._effectKey)
		 self:WndClose()
		end)
	self:SetWndText(self.mTxtCloseTips,ccClientText(41037))
	self:SetWndText(self.mTxtTitle,ccClientText(46176))
	CS.ShowObject(self.mImgTitle, false)
	self:UpdateAttr()
	self:UpdateList()
end

function UIDivineResonanceUpPop:UpdateAttr()
	local uiAttrList = self._uiAttrList
	local oldAttrList
	local oldRefId = self:GetWndArg("oldRefId")
	local oldLv = 0
	if oldRefId then
		local ref = GameTable.DivineWeaponResonanceRef[oldRefId]
		oldLv = ref.level
		if not string.isempty(ref.attr) then oldAttrList = LxDataHelper.ParseAttrList(ref.attr) end
	end

	local curRef = GameTable.DivineWeaponResonanceRef[gModelDivineWeapon.resonanceLvRefId]
	local curAttrList = curRef and LxDataHelper.ParseAttrList(curRef.attr)
	local curAttrMap =  {}
	for _, value in ipairs(curAttrList or {}) do
		if not curAttrMap[value.refId] then curAttrMap[value.refId] = {} end
		curAttrMap[value.refId][value.type] = value.value
		if not oldAttrList then value.value = 0 end
	end
	if not oldAttrList then oldAttrList = curAttrList end
	table.insert(oldAttrList,1,{oldRefId = oldLv,newRefId = curRef.level})
	self.curAttrMap = curAttrMap
	self.attrCount = #oldAttrList
	self.attrTrans = {}
	if uiAttrList then
		uiAttrList:RefreshList(oldAttrList)
	else
		uiAttrList = self:GetUIScroll("childDivineStar")
		self._uiAttrList = uiAttrList
		uiAttrList:Create(self.mListAttrs,oldAttrList,function(...) self:OnDrawAttrCell(...) end)
	end
end
function UIDivineResonanceUpPop:UpdateList()
	local uiAttrList = self._uiList
	local size = 0
	local _,divineResonanceLvRef = gModelDivineWeapon:GetResonanceLvRef()
	local dataList = divineResonanceLvRef
	if uiAttrList then
		uiAttrList:RefreshList(dataList)
	else
		uiAttrList = self:GetUIScroll("resonanceUp")
		self._uiList = uiAttrList
		uiAttrList:Create(self.mList,dataList,function(list,item,itemdata,itempos)
			if self.jpj then
				size =- 10
			end
			self:SetTextTile(item,string.replace(ccClientText(46175),itemdata.level),nil,size)
		end)
	end
end


function UIDivineResonanceUpPop:OnDrawAttrCell(list,item,itemdata,itempos)
	local lAttrIcon = self:FindWndTrans(item,"Attrs/LeftAttr/Icon")
	local lAttrName = self:FindWndTrans(item,"Attrs/LeftAttr/Name")
	local lAttrValue = self:FindWndTrans(item,"Attrs/LeftAttr/CurValue")
	local rAttrValue = self:FindWndTrans(item,"Attrs/NextValue")
	CS.ShowObject(lAttrIcon,itempos~=1)
	self.attrTrans[itempos] = item
	if itempos==1 then
		self:SetWndText(lAttrName,ccClientText(46177))
		self:SetWndText(lAttrValue,itemdata.oldRefId)
		self:SetWndText(rAttrValue,itemdata.newRefId)
		return
	end
	local numType,refId,value = itemdata.type,itemdata.refId,itemdata.value
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

	local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,numType,self.curAttrMap[refId] and self.curAttrMap[refId][numType] or 0)
	-- if type(valueStr) == "number" then
	-- 	valueStr = LUtil.NumberCoversion(valueStr)
	-- end
	self:SetWndText(rAttrValue,"<color=#139057>"..valueStr.."</color>")
	if self.attrCount == itempos then
		self:PlayEffect()
	end
	self:SetTextTile(rAttrValue,"xxxxxxxx")
end

-- - 播放动画
function UIDivineResonanceUpPop:PlayEffect()
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
		-- self._playEndEffect = true
	end)
end

-- 创建标题特效
function UIDivineResonanceUpPop:CreateTitleEffect()
	CS.ShowObject(self.mImgTitle, true)
	self:CreateEffect(self.mImgTitle, "fx_ui_shengxing_1")
end

-- 创建特效
function UIDivineResonanceUpPop:CreateEffect(trans, effectName, effectKey, effectSize)
	effectKey = effectKey or effectName
	effectSize = effectSize or 100
	self:CreateWndEffect(trans, effectName, effectKey, effectSize, false, false)
end

------------------------------------------------------------------
return UIDivineResonanceUpPop