---
--- Created by Administrator.
--- DateTime: 2024/6/13 14:20:13
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubPeList:LChildWnd
local UISubPeList = LxWndClass("UISubPeList", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubPeList:UISubPeList()
	self.allPet = {}
	self.maxNum = 0
	for index, value in pairs(GameTable.MagicPetRef or {}) do
		table.insert(self.allPet,value)
		self.maxNum = self.maxNum+1
	end
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubPeList:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubPeList:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubPeList:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsForeignVersion()
	
	self:SetWndText(self.mTxtName,ccClientText(43702))
	self:SetWndText(self.mTxtTitleAttr,ccClientText(43707))
	self:OnAddClick()
	self:OnUpdatePanel()
	self:InitHeroShenList()
	self:OnUpdateTotalAttrAdd()
	self:UpdateAttrs()
	self:InitEmptyTips()
end
function UISubPeList:OnUpdateTotalAttrAdd()
	self.totalAttrAdd = gModelPet:GetTotalAttrAdd()
end
function UISubPeList:OnUpdatePanel()
	local activeNum,totalStar = self:GetActiveNumAndStar()
	self:SetWndText(self.mTxtActiveNum,string.replace(ccClientText(43706),activeNum,self.maxNum))
	self:SetWndText(self.mTxtTotalLv,string.replace(ccClientText(43767),totalStar))
	local allAttrAdd = GameTable.MagicPetConfigRef.petAttrChange
	self:SetWndText(self.mTxtDesc,string.replace(ccClientText(43708),allAttrAdd))
end
function UISubPeList:OnDrawHeroShenCell(list, item, itemdata, itempos)
	CS.ShowObject(item,true)
    local aniRootTrans = self:FindWndTrans(item, "AniRoot")
    local QualityImg = self:FindWndTrans(aniRootTrans, "PetItem/QualityImg")
    local PetMapImg = self:FindWndTrans(aniRootTrans, "PetItem/PetMapImg")
    local PetFrontBg = self:FindWndTrans(aniRootTrans, "PetItem/PetFrontBg")
    local PetName = self:FindWndTrans(aniRootTrans, "PetItem/PetName")
    local ImgTxtQuality = self:FindWndTrans(aniRootTrans, "PetItem/ImgTxtQuality")
    local ImgStar = self:FindWndTrans(aniRootTrans, "PetItem/ImgStar")
    local PetSpine = self:FindWndTrans(aniRootTrans, "PetItem/PetSpine")

    local ImgCanActive = self:FindWndTrans(aniRootTrans, "PetItem/ImgCanActive")
    local TxtCanActive = self:FindWndTrans(aniRootTrans, "PetItem/ImgCanActive/TxtCanActive")
    local TxtLeve = self:FindWndTrans(aniRootTrans, "PetItem/TxtLeve")
    local redPointTrans = self:FindWndTrans(aniRootTrans, "redPoint")
    local ImgMask = self:FindWndTrans(aniRootTrans, "PetItem/ImgMask")

    local SliderTrans = self:FindWndTrans(aniRootTrans, "Slider")
	local TxtProBar = self:FindWndTrans(aniRootTrans,"Slider/TxtProBar")
    local ImgFull = self:FindWndTrans(aniRootTrans, "ImgFull")
    local TxtFull = self:FindWndTrans(aniRootTrans, "ImgFull/TxtFull")
	local Slider = self:FindWndSlider(SliderTrans)
	---@type StructPet
	local petInfo = gModelPet:GetPetById(itemdata.refId)
	local state = petInfo:GetPetState()
	local quality = itemdata.quality or 1

	--多语言设置文本
	if self._isEnus then
		self:InitTextSizeWithLanguage(TxtFull,-4)
		ImgFull.sizeDelta = Vector2.New(120,30)

		ImgCanActive.sizeDelta = Vector2.New(120,26)
	end





    if quality then
        local listBgBig = gModelItem:GetListBgBigByQuality(quality)
        self:SetWndEasyImage(PetFrontBg, listBgBig)
        local heorBook1Bg = gModelItem:GetHeorBook1BgByQuality(quality)
        self:SetWndEasyImage(QualityImg, heorBook1Bg)
    end
	local iconBig = itemdata.icon
	if string.isempty(itemdata.spine) then
		self:SetWndEasyImage(PetMapImg,iconBig,function()
			CS.ShowObject(PetMapImg,true)
		end)
		CS.ShowObject(PetSpine,false)
	else
		CS.ShowObject(PetSpine,true)
		CS.ShowObject(PetMapImg,false)
		local instanceId = item:GetInstanceID()
		self:DestroyWndSpineByKey(instanceId)
		local dpSpine = self:CreateWndSpine(PetSpine,itemdata.spine,instanceId,true,function (dpLoaded)
			dpLoaded:PlayAnimation(0,"idle",true)
		end,true)
		dpSpine:StartLoad()
	end

	gModelPet:SetStar(ImgStar,itemdata.refId,nil,function(starPath)
		self:SetWndEasyImage(ImgStar, starPath)
	end)
	self:SetWndText(PetName, ccLngText(itemdata.name))
	local starCfg = petInfo:GetPetStarCfg()
	if starCfg.rankNext<=0 then
		CS.ShowObject(SliderTrans,false)
		CS.ShowObject(ImgFull,true)
		self:SetWndText(TxtFull,ccClientText(43718))
	else
		CS.ShowObject(SliderTrans,true)
		CS.ShowObject(ImgFull,false)
		local cost = petInfo.isActive and GameTable.MagicPetStarRef[starCfg.rankNext].upNeed or starCfg.upNeed
		local costItem = LxDataHelper.ParseItem_4(cost)
		if costItem then
			local hasNum = gModelItem:GetNumByRefId(costItem.itemId)
			Slider.value = hasNum/costItem.itemNum
			self:SetWndText(TxtProBar,LUtil.NumberCoversion(hasNum).."/"..costItem.itemNum)
		end
	end

	CS.ShowObject(ImgCanActive,state==2)
	self:SetWndText(TxtCanActive,ccClientText(43709))
	self:SetWndText(TxtLeve,"Lv."..petInfo._level)
	CS.ShowObject(ImgMask,state==3)
	local qualityCfg = GameTable.RarityRef[itemdata.quality]
	self:SetWndEasyImage(ImgTxtQuality,qualityCfg.qualityText)
	CS.ShowObject(redPointTrans,state==2 or petInfo:IsCanUpLevel() or petInfo:IsCanUpStar() or petInfo:IsCanEquip())

    self:SetWndClick(item, function()
		if state==2 then
			gModelPet:OnPetUpSatrReq(itemdata.refId)
		else
			GF.OpenWnd("UIPeWin",{refId = itemdata.refId,index = itempos,allPet = self.allPet})
		end
    end)
end
function UISubPeList:InitHeroShenList()
    local petList = self._uiPetList
	table.sort(self.allPet,function (a,b)
		local aPet = gModelPet:GetPetById(a.refId)
		local bPet = gModelPet:GetPetById(b.refId)
		local aState = aPet:GetPetState()
		local bState = bPet:GetPetState()
		local aCfg = aPet:GetPetConfig()
		local bCfg = bPet:GetPetConfig()
		if aState ~= bState then
			return aState<bState
		else
			if aCfg.quality ~= bCfg.quality then
				return aCfg.quality > bCfg.quality
			else
				if aPet._level ~= bPet._level then
					return aPet._level>bPet._level
				else
					return aCfg.refId<bCfg.refId
				end
			end
		end
	end)
    if not petList then
        petList = self:GetUIScroll("mListPet")
        self._uiPetList = petList
        petList:Create(self.mListPet, self.allPet, function(...)
            self:OnDrawHeroShenCell(...)
        end, UIItemList.SUPER_GRID, false)
        local superList = petList:GetList()
        superList:EnableLoadAnimation(true)
        superList:SetLoadAnimationScale(0.2, 0.15)
        superList:RefreshList()
    else
        petList:RefreshList(self.allPet)
		-- petList:RefreshData(self.allPet)
        local superList = petList:GetList()
		-- superList:MoveToPos(1,0)
		superList:DrawAllItems(true)
    end
end

function UISubPeList:UpdateAttrs()
	self.totalAttrs = gModelPet:GetTotalAttr()
	for _, attr in ipairs(self.totalAttrs) do
		attr.attrNum =  attr.attrNum+ math.floor(self.totalAttrAdd*0.01*attr.attrNum)
	end
	local uiAttrList = self._uiAttrList
	if uiAttrList then
		uiAttrList:RefreshList(self.totalAttrs)
	else
		uiAttrList = self:GetUIScroll("childPetList")
		self._uiAttrList = uiAttrList
		uiAttrList:Create(self.mListAttrs,self.totalAttrs,function(...) self:OnDrawAttrCell(...) end)
	end
	CS.ShowObject(self.mEmptyText, #self.totalAttrs == 0)
end
function UISubPeList:GetActiveNumAndStar()
	local num = 0
	---@type StructPet
	local pet = nil
	local total = 0
	for _, value in pairs(GameTable.MagicPetRef or {}) do
		pet = gModelPet:GetPetById(value.refId)
		if pet.isActive then
			num = num+1
			total = total+pet._star
		end
	end
	return num,total
end

function UISubPeList:OnDrawAttrCell(list,item,itemdata,itempos)
	local AttrIcon = self:FindWndTrans(item,"AttrIcon")
	local AttrName = self:FindWndTrans(item,"AttrName")
	local AttrValue = self:FindWndTrans(item,"AttrValue")
	local numType,refId,value = itemdata.attrType,itemdata.attrRefId,itemdata.attrNum
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
		if type(valueStr) == "number" then
			valueStr = LUtil.NumberCoversion(valueStr)
		end
		self:SetWndText(AttrValue,valueStr)
	end
end

function UISubPeList:OnAddClick()
	self:SetWndClick(self.mImgHelp, function()
		GF.OpenWnd("UIBzTips",{refId = 170})
    end)
	self:SetWndClick(self.mImgTotal, function()
		GF.OpenWnd("UIPeStarSagaNum")
    end)

	self:SetWndClick(self.mImgAttrHelp,function()
		local converAttr = {}
		if #self.totalAttrs<=0 then
			GF.ShowMessage(ccClientText(43753))
			return
		end
		local attrAdd = GameTable.MagicPetConfigRef.petAttrChange
		for _, attr in ipairs(self.totalAttrs) do
			table.insert(converAttr,{attrRefId = attr.attrRefId,attrNum = attr.attrNum*attrAdd*0.01,attrType = attr.attrType})
		end
		GF.OpenWnd("UIPeConversionAttr",{attrList = converAttr,title = ccClientText(43720),desc = ccClientText(43721)})
	end)

	self:WndEventRecv(EventNames.On_Item_Change,function ()
		self:InitHeroShenList()
	end)
	self:WndEventRecv(EventNames.PET_CHANGE_LEVEL,function ()
		self:InitHeroShenList()
		self:UpdateAttrs()
	end)
	self:WndEventRecv(EventNames.PET_CHANGE_STAR,function (isActive)
		self:OnUpdatePanel()
		self:InitHeroShenList()
		self:OnUpdateTotalAttrAdd()
		self:UpdateAttrs()
	end)

	self:WndNetMsgRecv(LProtoIds.PetEquipWearResp, function()
		self:UpdateAttrs()
		self:InitHeroShenList()
	end)
	self:WndNetMsgRecv(LProtoIds.PetEquipUnloadResp, function()
		self:UpdateAttrs()
		self:InitHeroShenList()
	end)

end
-- 空列表提示
function UISubPeList:InitEmptyTips()
	local emptyList = self:GetCommonEmptyList("_empty")
	local data =
	{
		refId = 36006,
		IntroTran = self.mEmptyText,
	}
	emptyList:RefreshUI(data)
end


------------------------------------------------------------------
return UISubPeList