---
--- Created by Administrator.
--- DateTime: 2024/6/13 15:10:01
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPeActiSuccess:LWnd
local UIPeActiSuccess = LxWndClass("UIPeActiSuccess", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPeActiSuccess:UIPeActiSuccess()
	self._effectKey = "_PeteffectKey"
	self._starTransList = {}
	
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPeActiSuccess:OnWndClose()
	LWnd.OnWndClose(self)
	self:TweenSeqKill(self._effectKey)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPeActiSuccess:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPeActiSuccess:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndClick(self.mMask,function() self:WndClose() end)
	self.refId = self:GetWndArg("refId")
	self.isActive = self:GetWndArg("isActive")
	self:SetWndEasyImage(self.mImgTitle,self.isActive and "halidom_txt_2" or "draconic_txt_2",function() CS.ShowObject(self.mImgTitle,true)  end)
	self:OnUpdatePanel()
	self:OnUpdateAttr()
	self:OnUpdateStar()
	self:PlayEffect()
end


function UIPeActiSuccess:OnUpdateStar()
	---@type StructPet
	local petInfo = gModelPet:GetPetById(self.refId)
	CS.ShowObject(self.mItemStar,petInfo._star>0)
	if petInfo._star<=0 then return end
	local petStarCfg = petInfo:GetPetStarCfg()
	CS.ShowObject(self.mStarRight,petStarCfg.rankNext>0)
	CS.ShowObject(self.mImgStarFull,petStarCfg.rankNext<=0)

	local starLeft = petInfo._star-1
	local starImg = gModelPet:GetStarPath(starLeft)
	if starImg then
		if starLeft<=0 then starImg = "hero_icon_star1_1" end
		self:SetWndEasyImage(self.mStarLeft, starImg)
		local del = self.mStarLeft.sizeDelta
		local num = (starLeft>0 and starLeft%5==0) and 5 or starLeft%5
		if starLeft<=0 then num=1 end
		del.x = 40*num
		self.mStarLeft.sizeDelta = del

	end
	starImg = gModelPet:GetStarPath(petInfo._star)
	if starImg then
		self:SetWndEasyImage(self.mStarRight, starImg)
		local del = self.mStarRight.sizeDelta
		local num = (petInfo._star>0 and petInfo._star%5==0) and 5 or petInfo._star%5
		del.x = 40*num
		self.mStarRight.sizeDelta = del
	end

end
function UIPeActiSuccess:CreateEffect(trans,effectName,effectKey,effectSize)
	effectKey = effectKey or effectName
	effectSize = effectSize or 100
	self:CreateWndEffect(trans,effectName,effectKey,effectSize,false,false)
end

function UIPeActiSuccess:PlayEffect()
	local petInfo = gModelPet:GetPetById(self.refId)
	local isShowStar = petInfo._star>0
	local starCfg = petInfo:GetPetStarCfg()
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
			self:CreateEffect(self.mImgQuality,"fx_ui_shengxing_2")
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
				-- CS.ShowObject(v,true)
			end)
			seq:AppendInterval(showAttrTime)
		end

		if starCfg.skillId and starCfg.skillId>0 then
			seq:AppendCallback(function ()
				self:CreateEffect(self.mItemAttr,"fx_ui_shengxing_3","itemAttrEffect")
			end)
		end
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
function UIPeActiSuccess:OnUpdateAttr()
	---@type StructPet
	local pet = gModelPet:GetPetById(self.refId)
	if not self.isActive and pet._star-1>=0 then
		local frontAttr = pet:GetPetStarCfg(pet._star-1).attr
		self.frontAttr = LUtil.ConvertCommonAttrStrToMap(frontAttr)
	end
	local attrs = pet:GetStarAttr()
	local uiAttrList = self:GetUIScroll("PetLvAttrList")
	uiAttrList:Create(self.mListAttrs,attrs,function(...) self:OnDrawAttrCell(...) end)
end
function UIPeActiSuccess:OnUpdatePanel()
	local petCfg = GameTable.MagicPetRef[self.refId]
	local qualityCfg = GameTable.RarityRef[petCfg.quality]
	self:SetWndEasyImage(self.mImgQuality,qualityCfg.iconBg)
	self:SetWndEasyImage(self.mImgIcon,petCfg.icon)
	self:SetWndText(self.mTxtName,ccLngText(petCfg.name))

	---@type StructPet
	local pet = gModelPet:GetPetById(self.refId)
	local starCfg = pet:GetPetStarCfg()
	CS.ShowObject(self.mItemAttr,false)
	CS.ShowObject(self.mTxtDesc,false)

	if starCfg.skillId and starCfg.skillId>0 then
		CS.ShowObject(self.mTxtDesc,true)
		local skillCfg = GameTable.SnakeSkillRef[starCfg.skillId]
		self:SetWndText(self.mTxtDesc,"<color=#d2730f>Lv."..starCfg.skillILv.."</color>："..ccLngText(skillCfg.description))
		local oldStarCfg = pet:GetPetStarCfg(math.max(pet._star-1,0))
		CS.ShowObject(self.mDescAttrUp,oldStarCfg.skillILv~=starCfg.skillILv)
	end
	if starCfg.attrChangeAdd and  starCfg.attrChangeAdd>0 then
		local frontAttrAdd = 0
		local starCfgs = gModelPet.petStarCfg[self.refId] or {}
		for _, value in ipairs(starCfgs) do
			if value.rankNow < pet._star then
				frontAttrAdd = value.attrChangeAdd>0 and value.attrChangeAdd or frontAttrAdd
			else
				break
			end
		end
		self:SetWndText(self.mAttrName,ccClientText(43750))
		CS.ShowObject(self.mItemAttr,true)
		self:SetWndText(self.mAttrCurr,(frontAttrAdd or 0).."%")
		self:SetWndText(self.mAttrValue,starCfg.attrChangeAdd.."%")
	end
	self:SetWndText(self.mTxtCloseTips,ccClientText(41037))
end
function UIPeActiSuccess:OnDrawAttrCell(list,item,itemdata,itempos)
	local AttrIcon = self:FindWndTrans(item,"AttrIcon")
	local AttrName = self:FindWndTrans(item,"AttrIcon/AttrName")
	local AttrLeft = self:FindWndTrans(item,"AttrLeft")
	local AttrValue = self:FindWndTrans(item,"AttrValue")
	local numType,refId,value = itemdata.type,itemdata.refId,itemdata.value
	if AttrIcon then
		if self.isActive then
			local anchorPos = AttrIcon.anchoredPosition
			anchorPos.x = 144
			AttrIcon.anchoredPosition = anchorPos
		end
		local icon = gModelHero:GetAttributeIconById(refId)
		self:SetWndEasyImage(AttrIcon,icon)
	end

	if AttrName then
		local name = gModelHero:GetAttributeNameById(refId)
		self:SetWndText(AttrName,name)
	end

	if AttrLeft and self.frontAttr then
		local valueLeft = self.frontAttr[refId][numType] or 0
		local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,numType,valueLeft)
		self:SetWndText(AttrLeft,valueStr)
	end

	if AttrValue then
		local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,numType,value)
		self:SetWndText(AttrValue,valueStr)
	end
	-- CS.ShowObject(item,false)
	table.insert(self._starTransList,item)
end
------------------------------------------------------------------
return UIPeActiSuccess