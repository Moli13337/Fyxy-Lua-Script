---
--- Created by Administrator.
--- DateTime: 2024/6/13 14:23:21
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubPeRelation:LChildWnd
local UISubPeRelation = LxWndClass("UISubPeRelation", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubPeRelation:UISubPeRelation()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubPeRelation:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubPeRelation:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubPeRelation:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:SetWndClick(self.mImgHelp, function()
		GF.OpenWnd("UIBzTips",{refId = 170})
    end)
	self:SetWndClick(self.mBtnAttr,function()
		local attrs = gModelPet:GetPetRelationAttr()
		if #attrs<=0 then
			GF.ShowMessage(ccClientText(43753))
			return
		end
		
		GF.OpenWnd("UIPeConversionAttr",{attrList =attrs ,title = ccClientText(43723),desc = ccClientText(43721)})
	end)

	self.jpj = gLGameLanguage:IsJapanVersion()
	self:WndNetMsgRecv(LProtoIds.PetActRelationResp,function() self:OnUpdateList()  end)
	self:WndEventRecv(EventNames.PET_CHANGE_STAR,function(isActive)
		if isActive then self:OnUpdateList() end
	end)
	self:SetWndText(self.mTxtAttr,ccClientText(43723))
	self:SetWndText(self.mTxtDesc,ccClientText(43722))
	self:OnUpdateList()
end
function UISubPeRelation:OnDrawHeroShenCell(list, item, itemdata, itempos)
	CS.ShowObject(item,true)
    local aniRootTrans = self:FindWndTrans(item, "AniRoot")
    local TxtName = self:FindWndTrans(aniRootTrans, "ImgTitleBg/TxtName")
    local ImgTitleBg = self:FindWndTrans(aniRootTrans, "ImgTitleBg")
    local ListAttrs = self:FindWndTrans(aniRootTrans, "ListAttrs")
    local ListHero = self:FindWndTrans(aniRootTrans, "ListHero")
    local ImgActivated = self:FindWndTrans(aniRootTrans, "ImgActivated")
    local TxtActivated = self:FindWndTrans(aniRootTrans, "ImgActivated/TxtActivated")
    local BtnActive = self:FindWndTrans(aniRootTrans, "BtnActive")
    local TxtBtnActive = self:FindWndTrans(aniRootTrans, "BtnActive/TxtBtnActive")
	local red = self:FindWndTrans(BtnActive,"redPoint")
	---@type StructPet
	self:SetWndText(TxtName,ccLngText(itemdata.name))
	self:SetWndEasyImage(ImgTitleBg, itemdata.bg, function()
		CS.ShowObject(ImgTitleBg, true)
	end, true)
	local isActivated = gModelPet.petRelation[itemdata.refId] and true or false --self.relationState[itemdata.refId]
	CS.ShowObject(ImgActivated,isActivated)
	self:SetWndText(TxtActivated,ccClientText(43724))
	local petlist = LxDataHelper.ParseIntParam_Comma(itemdata.petId)
	self:OnUpdateAttr(ListAttrs,itemdata.attr,isActivated,itempos)
	self:OnUpdatePetList(ListHero,petlist,itempos)
	local canActiva = self:CanActiveRelation(itemdata.refId)
	CS.ShowObject(BtnActive,canActiva)
	CS.ShowObject(red,canActiva)
	local key = "itempet"..tostring(itempos)
	if canActiva then
		local eff = self:FindWndEffectByKey(key)
		if eff then
			local effTrans = eff:GetDisplayTrans()
			CS.SetParentTrans(effTrans,BtnActive)
			effTrans.localScale = Vector3(100,100,100)

		else
			self:CreateWndEffect(BtnActive,"fx_anniu_02",key,100,nil,nil,nil,nil,nil,true)
		end
	else
		self:DestroyWndEffectByKey(key)
	end
	self:SetWndText(TxtBtnActive,ccClientText(43725))
    self:SetWndClick(BtnActive,function()
		gModelPet:OnPetActRelationReq(itemdata.refId)
	end)
end

function UISubPeRelation:OnUpdatePetList(uiList,petList,index)
	-- local uiAttrList = self:GetUIScroll("petList"..index)
	-- uiAttrList:Create(uiList,petList,function(...) self:OnPetCell(...) end)
	self:CreateUIScrollImpl(nil,uiList,petList,function(...) self:OnPetCell(...) end)
end

function UISubPeRelation:OnPetCell(list,item,itemdata,itempos)
	local IconBg = self:FindWndTrans(item,"IconBg")
	local Icon = self:FindWndTrans(item,"Icon")
	local ImgMask = self:FindWndTrans(item,"ImgMask")
	local petCfg = GameTable.MagicPetRef[itemdata]
	local qualityCfg = GameTable.RarityRef[petCfg.quality]
	self:SetWndEasyImage(IconBg,qualityCfg.iconBg)
	self:SetWndEasyImage(Icon,petCfg.icon)
	local pet = gModelPet:GetPetById(itemdata)
	CS.ShowObject(ImgMask,not pet.isActive)
	self:SetWndClick(item, function()
		if pet.isActive then
			GF.OpenWnd("UIPeView",{refId = itemdata,playerId = gLGameLogin:GetPlayerId()})
		else
			gModelGeneral:OpenGetWayWnd({ itemId = itemdata })
		end
    end)
end

function UISubPeRelation:OnUpdateList()
	local cfgs = GameTable.MagicPetRelationRef
	local relationList = {}
	local moveIndx = 0
	self.relationState = {}
	for _, value in pairs(cfgs or {}) do
		table.insert(relationList,value)
	end
	table.sort(relationList,function(a,b)
		local aquality = tonumber(string.sub(a.bg,#a.bg))
		local bquality = tonumber(string.sub(b.bg,#b.bg))
		if aquality~=bquality then
			return aquality>bquality
		else
			return a.refId<b.refId
		end
	end)
	for index, value in ipairs(relationList) do
		self.relationState[value.refId] = self:CanActiveRelation(value.refId)
		if moveIndx==0 and self.relationState[value.refId] then moveIndx =index end
	end
	local petList = self._uiPetList
	local superList
	if not petList then
        petList = self:GetUIScroll("mListPetRelation")
        self._uiPetList = petList
        petList:Create(self.mListPet, relationList, function(...)
            self:OnDrawHeroShenCell(...)
        end, UIItemList.SUPER_GRID, false)
		superList = petList:GetList()
    else
        petList:RefreshList(relationList)
		superList = petList:GetList()
		superList:DrawAllItems()
	end

	superList:MoveToPos(moveIndx)
end

function UISubPeRelation:OnUpdateAttr(uiList,attr,isActiva,index)
	local attrList = LxDataHelper.ParseAttrList(attr)
	for _, value in ipairs(attrList) do
		value.color = isActiva and "#139057" or "#d2730f"
	end
	-- local _uiPetList = self:GetUIScroll("petAttrList"..index)
	-- _uiPetList:Create(uiList,attrList,function(...) self:OnDrawAttrCell(...) end)
	self:CreateUIScrollImpl(nil,uiList,attrList,function(...) self:OnDrawAttrCell(...) end)
end

function UISubPeRelation:CanActiveRelation(refId)
	local cfg = GameTable.MagicPetRelationRef[refId]
	local isActivated = gModelPet:isActivePetRelation(refId)
	if isActivated then return false end
	local petlist = LxDataHelper.ParseIntParam_Comma(cfg.petId)
	for _, id in ipairs(petlist) do
		local pet = gModelPet:GetPetById(id)
		if not pet.isActive then
			return false
		end
	end
	return true
end

function UISubPeRelation:OnDrawAttrCell(list,item,itemdata,itempos)
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

	if self.jpj then
		self:SetAnchorPos(AttrName,Vector2.New(60,0))
	end

	if AttrValue then
		local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,numType,value)
		self:SetWndText(AttrValue,string.replace("<color=#a1#>#a2#</color>",itemdata.color, valueStr))
	end
end
------------------------------------------------------------------
return UISubPeRelation