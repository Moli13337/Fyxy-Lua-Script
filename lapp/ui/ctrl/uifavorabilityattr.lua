---
--- Created by Administrator.
--- DateTime: 2024/4/23 21:25:55
---
------------------------------------------------------------------
local typeofRenderer = typeof(UnityEngine.Renderer)
local typeofCanvas = typeof(UnityEngine.Canvas)
local LWnd = LWnd
---@class UIFavorabilityAttr:LWnd
local UIFavorabilityAttr = LxWndClass("UIFavorabilityAttr", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFavorabilityAttr:UIFavorabilityAttr()
	self.nextAttrMap = {}
	self.levelAttr = {}
	self.index = 0
	local refs = GameTable.CharacterFavorabilityAttrRef
	for _, ref in pairs(refs) do
		if ref.lvAttr and ref.lvAttr~="" then
			table.insert(self.levelAttr,{refId = ref.refId,attrs = LxDataHelper.ParseAttrList(ref.lvAttr)})
			if gModelHero._loveTotalLevel>=ref.refId then self.index = self.index+1 end
		end
	end
	table.sort(self.levelAttr,function(a,b)
		return a.refId<b.refId
	end)
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFavorabilityAttr:OnWndClose()
	LWnd.OnWndClose(self)
	self._rendererList = nil
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFavorabilityAttr:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFavorabilityAttr:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndClick(self.mImgMask,function() self:WndClose() end)
	self:SetWndText(self.mTextTitle,ccClientText(41309))
	self:SetWndText(self.mTextLvTitle,ccClientText(41310))
	self:SetWndText(self.mTxtDesc,ccClientText(41312))
	self:SetWndText(self.mTxtTips,ccClientText(41037))
	self:OnUpdatePanel()
	self:InitLoveLvOrder()
end

function UIFavorabilityAttr:OnDrawLvAttrCell(list,item,itemdata,itempos)
	local AttrLv = self:FindWndTrans(item,"AttrLv")
	local IconLeft = self:FindWndTrans(item,"IconLeft")
	local IconRight = self:FindWndTrans(item,"IconRight")
	local AttrLeft = self:FindWndTrans(item,"AttrLeft")
	local AttrRight = self:FindWndTrans(item,"AttrRight")
	local lv = itemdata.refId
	local attrs = itemdata.attrs
	local color = gModelHero._loveTotalLevel >= lv and "139056ff" or "734F22ff"
	if AttrLv then
		self:SetWndText(AttrLv,"Lv"..lv..":")
		self:SetXUITextTransColor( AttrLv,color)
	end
	if IconLeft then
		CS.ShowObject(IconLeft,attrs[1] and true or false)
		if attrs[1] then
			local icon = gModelHero:GetAttributeIconById(attrs[1].refId)
			self:SetWndEasyImage(IconLeft,icon)
		end
	end
	if IconRight then
		CS.ShowObject(IconRight,attrs[2] and true or false)
		if attrs[2] then
			local icon = gModelHero:GetAttributeIconById(attrs[2].refId)
			self:SetWndEasyImage(IconRight,icon)
		end
	end

	if AttrLeft then
		if attrs[1] then
			local name = gModelHero:GetAttributeNameById(attrs[1].refId)
			local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(attrs[1].refId,attrs[1].type,attrs[1].value)
			self:SetWndText(AttrLeft,name.."+"..valueStr)
			self:SetXUITextTransColor(AttrLeft,color)
		end
	end

	if AttrRight then
		if attrs[2] then
			local name = gModelHero:GetAttributeNameById(attrs[2].refId)
			local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(attrs[2].refId,attrs[2].type,attrs[2].value)
			self:SetWndText(AttrRight,name.."+"..valueStr)
			self:SetXUITextTransColor(AttrRight,color)
		end
	end
end

function UIFavorabilityAttr:OnUpdateEffectLove()
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

function UIFavorabilityAttr:OnDrawAttrCell(list,item,itemdata,itempos)
	local AttrIcon = self:FindWndTrans(item,"AttrIcon")
	local AttrName = self:FindWndTrans(item,"AttrName")
	local AttrValue = self:FindWndTrans(item,"AttrValue")
	local AttrNextValue = self:FindWndTrans(item,"AttrNextValue")
	local numType,refId,value = itemdata.type,itemdata.refId,itemdata.value
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
		self:SetWndText(AttrValue,"+"..valueStr)
	end

	if AttrNextValue then
		local nextAttr = self.nextAttrMap[refId.."-"..numType]
		local nextStr = nextAttr and string.replace(ccClientText(41313),nextAttr.value) or "满级"
		self:SetWndText(AttrNextValue,nextStr)
	end
end

function UIFavorabilityAttr:UpdateLevelAttrs()
	-- local curlist = gModelHero:GetTotalLoveAttrs()
	local uiAttrList = self._uiLvAttrList
	if uiAttrList then
		uiAttrList:RefreshList(self.levelAttr)
	else
		-- uiAttrList = self:CreateUIScrollImpl("LoveAttrScroll",self.mListLvAttrs,self.levelAttr,function (...)
		-- 	self:OnDrawLvAttrCell(...)
		-- end)--UIItemList.WRAP
		self._uiLvAttrList = self:GetUIScroll("IconList")
		self._uiLvAttrList:Create(self.mListLvAttrs,self.levelAttr,function (...) self:OnDrawLvAttrCell(...) end,UIItemList.SUPER_GRID)
	end
	self._uiLvAttrList:MoveToPos(self.index-1)
end
function UIFavorabilityAttr:InitLoveLvOrder()
    local canvas = self.mTxtLv:GetComponent(typeofCanvas)
    if not canvas then
        canvas = self.mTxtLv.gameObject:AddComponent(typeofCanvas)
    end
    canvas.overrideSorting = true
    canvas.sortingLayerName = self:GetWndSortLayer()
    canvas.sortingOrder = self:GetWndSortOrder()+2
end
function UIFavorabilityAttr:UpdateAttrs()
	local curlist = gModelHero:GetTotalLoveAttrs()
	local uiAttrList = self._uiAttrList
	if uiAttrList then
		uiAttrList:RefreshList(curlist)
	else
		uiAttrList = self:GetUIScroll("TotalAttrList")
		---@type UIItemList
		self._uiAttrList = uiAttrList
		uiAttrList:Create(self.mListAttrs,curlist,function(...) self:OnDrawAttrCell(...) end)
	end
end

function UIFavorabilityAttr:OnUpdatePanel()
	local lv = gModelHero._loveTotalLevel
	local nextRef = GameTable.CharacterFavorabilityAttrRef[lv+1]
	self.nextAttrMap = {}
	local nextLvExp = GameTable.CharacterFavorabilityAttrRef[lv].exp
    if nextRef then
		local list = LxDataHelper.ParseAttrList(nextRef.attr)
		for _, attr in pairs(list) do
			self.nextAttrMap[attr.refId.."-"..attr.type] = attr
		end
		nextLvExp = nextRef.exp
	end

	self:SetWndText(self.mTxtLv,lv)
	self:SetWndText(self.mTxtProgress,string.replace(ccClientText(41308),gModelHero._loveTotalValue,nextLvExp))
	self:UpdateAttrs()
	self:UpdateLevelAttrs()
	self:OnUpdateEffectLove()
end

------------------------------------------------------------------
return UIFavorabilityAttr