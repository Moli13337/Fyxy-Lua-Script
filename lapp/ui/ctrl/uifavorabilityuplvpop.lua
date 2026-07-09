---
--- Created by Administrator.
--- DateTime: 2024/4/24 18:04:35
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFavorabilityUpLvPop:LWnd
local typeofRenderer = typeof(UnityEngine.Renderer)
local typeofCanvas = typeof(UnityEngine.Canvas)
local UIFavorabilityUpLvPop = LxWndClass("UIFavorabilityUpLvPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFavorabilityUpLvPop:UIFavorabilityUpLvPop()
	self._effectKey = "_effectKey_uplv"
	self._starTransList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFavorabilityUpLvPop:OnWndClose()
	LWnd.OnWndClose(self)
	self._rendererList = nil
	self:TweenSeqKill(self._effectKey)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFavorabilityUpLvPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFavorabilityUpLvPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitTexts()
	self:InitEvents()
	self:UpdateAttrs()
	self:InitLoveLvOrder()
end

-- 初始事件
function UIFavorabilityUpLvPop:InitEvents()
	self:SetWndClick(self.mMask, function(...) self:WndClose() end)
	self:SetWndClick(self.mTxtCloseTips, function(...) self:WndClose()  end)
	CS.ShowObject(self.mImgTitle,false)
	self:SetWndEasyImage(self.mImgTitle,"herobook_txt_2",nil,true)
	CS.ShowObject(self.mImgLove,false)
	CS.ShowObject(self.mAttrAdd,false)
	CS.ShowObject(self.mTxtTips,false)
end

function UIFavorabilityUpLvPop:OnUpdateEffectLove()
    local curTotalLv = gModelHero._loveTotalLevel
    local totalRef = GameTable.CharacterFavorabilityAttrRef[curTotalLv + 1]
    local nexTotalExp = totalRef and totalRef.exp or GameTable.CharacterFavorabilityAttrRef[curTotalLv].exp

    self:CreateWndEffect(self.mEffectLove,"fx_haogandu_yeti","haogandulove_yeti",100,nil,nil,nil,nil,nil,true,nil,nil)
	self:CreateWndEffect(self.mImgLove,"fx_haogandu","haogandulove",100,nil,nil,nil,nil,nil,true,nil,function()
        if not self._rendererList then
            local rendererList = self.mEffectLove:GetComponentsInChildren(typeofRenderer, true)
            self._rendererList = rendererList:ToTable()
        end-- 初0.25
        local temp = (gModelHero._loveTotalValue/nexTotalExp)*0.4
        for k,v in ipairs(self._rendererList) do
            local material = v.material
            if material then
                material.mainTextureOffset = Vector2(0,0.26-temp)
            end
        end
    end)
end
function UIFavorabilityUpLvPop:InitLoveLvOrder()
    local canvas = self.mTxtLv:GetComponent(typeofCanvas)
    if not canvas then
        canvas = self.mTxtLv.gameObject:AddComponent(typeofCanvas)
    end
    canvas.overrideSorting = true
    canvas.sortingLayerName = self:GetWndSortLayer()
    canvas.sortingOrder = self:GetWndSortOrder()+2
end


function UIFavorabilityUpLvPop:UpdateAttrs()
	local loveLv = gModelHero._loveTotalLevel
	self:SetWndText(self.mTxtLv,loveLv)
	local curRef = GameTable.CharacterFavorabilityAttrRef[loveLv]
	self.nextAttrMap = {}
    if curRef then
		local list = LxDataHelper.ParseAttrList(curRef.attr)
		for _, attr in pairs(list) do
			self.nextAttrMap[attr.refId.."-"..attr.type] = attr
		end
	end

	local curlist = gModelHero:GetTotalLoveAttrs(loveLv-1)
	self.listLeng = #curlist
	local uiAttrList = self._uiAttrList
	if uiAttrList then
		uiAttrList:RefreshList(curlist)
	else
		uiAttrList = self:GetUIScroll("TotalAttrList")
		self._uiAttrList = uiAttrList
		uiAttrList:Create(self.mListAttrs,curlist,function(...) self:OnDrawAttrCell(...) end)
	end

	local lvAttr = nil
	local isTips = false
	local length = #GameTable.CharacterFavorabilityAttrRef
	while loveLv <= length do
		lvAttr = GameTable.CharacterFavorabilityAttrRef[loveLv].lvAttr
		if #lvAttr >0 then
			lvAttr = LxDataHelper.ParseAttrList(lvAttr)
			isTips = loveLv == gModelHero._loveTotalLevel and 0 or loveLv
			break end
		loveLv = loveLv+1
	end
	if lvAttr then
		local path = gModelHero:GetAttributeNameById(lvAttr[1].refId)
		self:SetWndEasyImage(self.mIconLeft,path)
		local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(lvAttr[1].refId,lvAttr[1].type,lvAttr[1].value)
		local name = gModelHero:GetAttributeNameById(lvAttr[1].refId)
		self:SetWndText(self.mTxtAttrLeft,name.." <color=#139056>+"..valueStr.."</color>")
		local path = gModelHero:GetAttributeNameById(lvAttr[2].refId)
		self:SetWndEasyImage(self.mIconRight,path)
		name = gModelHero:GetAttributeNameById(lvAttr[2].refId)
		local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(lvAttr[2].refId,lvAttr[2].type,lvAttr[2].value)
		self:SetWndText(self.mTxtAttrRight,name.." <color=#139056>+"..valueStr.."</color>")
	end
	self:SetWndText(self.mTxtLockTips,string.replace(ccClientText(41625),isTips))
	CS.ShowObject(self.mTxtLockTips,isTips~=0)

end
function UIFavorabilityUpLvPop:CreateEffect(trans,effectName,effectKey,effectSize)
	effectKey = effectKey or effectName
	effectSize = effectSize or 100
	self:CreateWndEffect(trans,effectName,effectKey,effectSize,false,false)
end

function UIFavorabilityUpLvPop:OnDrawAttrCell(list,item,itemdata,itempos)
	local AttrIcon = self:FindWndTrans(item,"AttrIcon")
	local AttrName = self:FindWndTrans(item,"AttrName")
	local AttrValue = self:FindWndTrans(item,"AttrValue")
	local AttrNextValue = self:FindWndTrans(item,"AttrNextValue")
	local numType,refId,value = itemdata.type,itemdata.refId,itemdata.value
	CS.ShowObject(item,false)
	if AttrIcon then
		local icon = gModelHero:GetAttributeIconById(refId)
		self:SetWndEasyImage(AttrIcon,icon)
	end

	if AttrName then
		local name = gModelHero:GetAttributeNameById(refId)
		self:SetWndText(AttrName,name)
	end

	if AttrValue then
		local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,numType,value)
		self:SetWndText(AttrValue, valueStr)
	end

	if AttrNextValue then
		local nextAttr = self.nextAttrMap[refId.."-"..numType]
		self:SetWndText(AttrNextValue,nextAttr.value+value)
	end

	table.insert(self._starTransList,item)
	if itempos>=self.listLeng then
		self:PlayEffect()
	end
end
function UIFavorabilityUpLvPop:PlayEffect()
	table.insert(self._starTransList,self.mAttrAdd)
	local seqTween
	self:TweenSeqKill(self._effectKey)
	seqTween = self:TweenSeqCreate(self._effectKey,function(seq)
		local showTopTime = 0.2
		local showAttrTime = 0.1

		CS.ShowObject(self.mImgTitle,true)
		seq:AppendCallback(function ()
			self:CreateEffect(self.mImgTitle,"fx_ui_shengxing_1")
		end)
		seq:AppendInterval(showTopTime)

		CS.ShowObject(self.mImgLove,true)
		seq:AppendCallback(function ()
			self:OnUpdateEffectLove()
			self:CreateEffect(self.mImgLove,"fx_ui_shengxing_4")
		end)
		seq:AppendInterval(showTopTime)

		CS.ShowObject(self.mTxtTips,true)
		for i,v in ipairs(self._starTransList) do
			seq:AppendCallback(function ()
				CS.ShowObject(v,true)
				self:CreateEffect(v,"fx_ui_shengxing_3","eff"..i)
			end)
			seq:AppendInterval(showAttrTime)
		end
		return seq
	end)
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(self._effectKey)
	end)
	LxUiHelper.PlayAudioSoundName(LSoundConst.SoundId117)
end


-- 初始界面化文本
function UIFavorabilityUpLvPop:InitTexts()
	self:SetWndText(self.mTxtCloseTips, ccClientText(41037))
	self:SetWndText(self.mTxtLove, ccClientText(41305))
	self:SetWndText(self.mTxtTips, ccClientText(41624))
	self:SetWndText(self.mTxtTitle, ccClientText(23712))
end
------------------------------------------------------------------
return UIFavorabilityUpLvPop