---
--- Created by Administrator.
--- DateTime: 2024/6/13 15:03:59
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubPeEq:LChildWnd
local UISubPeEq = LxWndClass("UISubPeEq", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubPeEq:UISubPeEq()
	self._commonUIList = {}
	self.equipCount = 4
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubPeEq:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubPeEq:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubPeEq:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:OnAddClick()
	self.argList = self:GetWndArgList()
	self.listLeng = self.argList.allPet and #self.argList.allPet or 0
	self:SetWndButtonText(self.mBtnEquipComp, ccClientText(43705))
	self:OnUpdatePet()
	self:PetEquipCompoundRed()
end
function UISubPeEq:OnShare()
	local data = {
        root = self.mBtnShare,
        shareType = ModelChat.CHAT_SHARE_41,
        shareData = tostring(self.argList.refId),
    }
    gModelGeneral:OpenShareTip(data)
end
function UISubPeEq:OnAddClick()
	self:SetWndClick(self.mBtnLeft,function()
		self:OnLeftClick()
	end)

	self:SetWndClick(self.mBtnRight,function()
		self:OnRightClick()
	end)

	self:SetWndClick(self.mBtnShare,function()
		self:OnShare()
	end)

	self:SetWndClick(self.mBtnCommon,function()
		self:OnUpStarLv()
	end)
	self:SetWndClick(self.mAutoWearEquipBtn, function()
        self:ClickAutoWearEquipBtn()
    end)

	self:SetWndClick(self.mBtnEquipComp, function()
		GF.OpenWnd("UIMid", { page = 3 })
		local redPoint = self:FindWndTrans(self.mBtnEquipComp, "redPoint")
		if redPoint.gameObject.activeSelf then
			gModelPet.compoundRed = false
			CS.ShowObject(redPoint,false)
		end
    end)
	self:SetWndClick(self.mImgAttrHelp,function()
		GF.OpenWnd("UIPeLinkJN",{refId = self.argList.refId})
	end)

	self:WndEventRecv(EventNames.PET_CHANGE_LEVEL,function ()
		local pet = gModelPet:GetPetById(self.argList.refId)
		self:SetWndText(self.mTxtLevel,string.replace(ccClientText(43766),pet._level,pet.maxLevel))
	end)
	self:WndNetMsgRecv(LProtoIds.PetEquipWearResp,function()
		self:RefreshEquipPage()
	end)
	self:WndNetMsgRecv(LProtoIds.PetEquipUnloadResp,function()
		self:RefreshEquipPage()
	end)
	self:WndEventRecv(EventNames.PET_CHANGE_STAR,function ()
		self:OnUpdateStar()
		self:OnSkillDesc()
	end)

	self:WndNetMsgRecv(LProtoIds.PetEquipCompoundResp, function()
		self:PetEquipCompoundRed()
	end)
end
function UISubPeEq:OnRightClick()
	self.argList.index = self.argList.index+1
	self.argList.refId = self.argList.allPet[self.argList.index].refId
	self:OnUpdatePet()
	FireEvent(EventNames.PET_INFO_CHANGE)
end
function UISubPeEq:OnLeftClick()
	self.argList.index = self.argList.index-1
	self.argList.refId = self.argList.allPet[self.argList.index].refId
	self:OnUpdatePet()
	FireEvent(EventNames.PET_INFO_CHANGE)
end
function UISubPeEq:OnUpdateArrow()
	CS.ShowObject(self.mBtnLeft,self.argList.index>1)
    CS.ShowObject(self.mBtnRight,self.argList.index<self.listLeng)
end
function UISubPeEq:ClickAutoWearEquipBtn()
	---@type StructPet
	local pet = gModelPet:GetPetById(self.argList.refId)
	if not pet.isActive then
		GF.ShowMessage(ccClientText(43758))
		return
	end
    local equipList =pet:GetPetWearEquips() or {}--穿戴列表
    if self._autoWearEquipBtnType ==1 then
        local refIdList = {}
        local changeList = {}
		local isNull = true
        for i = 1, self.equipCount do
            local equip = gModelPet:GetStrongestEquipByPart(i)
            if equip ~= nil then
                if equipList[i] then
                    if equipList[i]._score < equip._score then
                        table.insert(changeList, equip:GetRefId())
                    end
                else
                    table.insert(refIdList, equip:GetRefId())
                end
            end
        end
        if #changeList > 0 then
			isNull = false
            gModelPet:OnPetEquipWearReq(self.argList.refId, changeList, 1)
        end
        if #refIdList > 0 then
			isNull = false
            gModelPet:OnPetEquipWearReq(self.argList.refId, refIdList)
        end
		if isNull then GF.ShowMessage(ccClientText(43765)) end
    elseif self._autoWearEquipBtnType == -1 then
        local refIdList = {}
        for i = 1, self.equipCount do
            if equipList[i] ~= nil then
                table.insert(refIdList, equipList[i]._refId)
            end
        end
        gModelPet:OnPetEquipUnloadReq(self.argList.refId, refIdList)
    end
end

function UISubPeEq:OnSkillDesc()
	---@type StructPet
	local pet = gModelPet:GetPetById(self.argList.refId)
	local desc,conditionDesc,isCondition = pet:GetLinkSkillDesc()
	self:SetWndText(self.mTxtLinkDesc,desc or "")
	self:SetWndText(self.mTxtLinkCond,conditionDesc or "")
	CS.ShowObject(self.mTxtLinkCond,isCondition)

	local petStarCfg = pet:GetPetStarCfg(0)
	local attrAdd = petStarCfg.attrChangeAdd
	local attrStar = pet._star
	while((pet._star>petStarCfg.rankNow and petStarCfg.rankNext>0) or attrAdd<=0) do
		petStarCfg = GameTable.MagicPetStarRef[petStarCfg.rankNext]
		attrAdd = petStarCfg.attrChangeAdd>0 and petStarCfg.attrChangeAdd or attrAdd
		attrStar = petStarCfg.rankNow
	end
	local nexStarCfg = pet:GetPetStarCfg(pet._star+1)
	local nexAttrAdd
	if nexStarCfg and nexStarCfg.attrChangeAdd>0 and pet._star>=attrStar then
		nexAttrAdd = " <color=#139057>(+"..(nexStarCfg.attrChangeAdd-attrAdd).."%)</color>"
	end
	local color = (pet._star>=attrStar and pet.isActive) and "#D2730F" or "#C81212"
	self:SetWndText(self.mTxtWholeAttr,string.replace(ccClientText(43714),color,nexAttrAdd and attrAdd.."%"..nexAttrAdd or attrAdd.."%"))
	self:SetWndText(self.mTxtWholeCond,string.replace(ccClientText(43713),attrStar))
	CS.ShowObject(self.mTxtWholeCond,pet._star~=attrStar or not pet.isActive)
end

function UISubPeEq:PetEquipCompoundRed()
	if gModelPet.compoundRed then
		local petRed = gModelPet:GetEquipCompoundRedPointByPart()
		local redPoint = self:FindWndTrans(self.mBtnEquipComp, "redPoint")
		CS.ShowObject(redPoint,petRed)
	end
end
function UISubPeEq:OnUpStarLv()
	---@type StructPet
	local pet = gModelPet:GetPetById(self.argList.refId)
	local lvCfg = pet:GetLvCfg()
	if lvCfg and lvCfg.lvNext<=0 then
		GF.ShowMessage(ccClientText(43717))
		return
	end
	if pet.isActive then
		gModelPet:OnPetUpLevelReq(self.argList.refId,1)
	else
		gModelPet:OnPetUpSatrReq(self.argList.refId)
	end
end
function UISubPeEq:OnWndRefresh()
	LChildWnd.OnWndRefresh(self)
	self:OnUpdatePet()
end

function UISubPeEq:RefreshEquipPage()
	---@type StructPet
	local pet = gModelPet:GetPetById(self.argList.refId)
    local equipList = pet:GetPetWearEquips() or {}--穿戴列表
    local wearEquipNum = 0
    local wearRedPoints, strongerRedPoints = false, false
	local partRef = GameTable.MagicPetArticleTypeRef
    for _, value in pairs(partRef) do
		local i = value.refId
		local equipRoot = self["mEquipRoot" .. i]
        local instanceId = equipRoot:GetInstanceID()
        local commonUI = self:FindWndTrans(equipRoot, "CommonUI")
        local root = self:FindWndTrans(commonUI, "Root")
        local equipNameTex = self:FindWndTrans(equipRoot, "EquipName")
        local redPoint = self:FindWndTrans(equipRoot, "redPoint")
        local wearRedPoint, strongerRedPoint = false, false
        self:SetIconClickScale(commonUI, true)
		---@type StructPetEquip
		local equipData = equipList[i]
        self:SetWndClick(commonUI, function()
            if equipData then--装备中-打开装备信息界面
                gModelGeneral:OpenEquipInfoTip(equipData._refId, self.argList.refId, 2, false,nil,nil,nil,LItemTypeConst.TYPE_PET_EQUIP)
            else
				if not pet.isActive then
					GF.ShowMessage(ccClientText(43758))
					return
				end
                GF.OpenWndUp("UIPeEqWear", { petRefId = self.argList.refId, part = i, refId = nil })
            end
        end)
		local icon = self._commonUIList[instanceId]
        if not icon then
			icon = CommonIcon:New()
            self._commonUIList[instanceId] = icon
            icon:Create(root)
        end
        icon:SetPetEquipIcon(equipData and equipData._refId or nil, nil, i)
        icon:DoApply()

        if equipData == nil and pet.isActive and gModelPet:GetWearRedPointByPart(i) then
            wearRedPoint = true
            wearRedPoints = true
        end
        if equipData ~= nil then
            wearEquipNum = wearEquipNum + 1
            if pet.isActive and gModelPet:GetStrongerEquipByPart(equipData, i) ~= nil then
                strongerRedPoint = true
                strongerRedPoints = true
            end
        end
        CS.ShowObject(redPoint, wearRedPoint or strongerRedPoint)
        CS.ShowObject(equipNameTex, equipData ~= nil)
		local equipCfg = equipData and gModelPet:GetPetEquipRef(equipData._refId)
        self:SetWndText(equipNameTex, equipData and ccLngText(equipCfg.name) or "")
    end
    CS.ShowObject(self.mAutoWearEquipRedPoint, wearRedPoints)

    -- CS.ShowObject(self.mOutfitBotBtnRedPoint, wearRedPoints or strongerRedPoints)
    -- local equipRedpoint = CS.FindTrans(self._tabList[UINewSagaInfo.BTN_TYPE_EQUIP], "redPoint")
    -- CS.ShowObject(equipRedpoint, wearRedPoints or strongerRedPoints)

    local isOneKeyUnload = wearEquipNum >= 1 and not strongerRedPoints and not wearRedPoints
    local btnStr = isOneKeyUnload and ccClientText(11328) or ccClientText(11327)
    local btnImg = isOneKeyUnload and "public_btn_3_3" or "public_btn_3_2"
    self:SetWndButtonText(self.mAutoWearEquipBtn, btnStr)
    self:SetWndButtonImg(self.mAutoWearEquipBtn, btnImg)
    self._autoWearEquipBtnType = isOneKeyUnload and -1 or 1
end

function UISubPeEq:OnUpdateStar()
	gModelPet:SetStar(self.mImgStar,self.argList.refId,nil,function(starPath)
		self:SetWndEasyImage(self.mImgStar, starPath)
	end)
end
function UISubPeEq:OnUpdatePet()
	local petCfg = GameTable.MagicPetRef[self.argList.refId]
	local pet = gModelPet:GetPetById(self.argList.refId)
	self:SetWndText(self.mTxtName,ccLngText(petCfg.name))
	self:SetWndText(self.mTxtLevel,string.replace(ccClientText(43766),pet._level,pet.maxLevel))
	self:SetWndText(self.mTxtTitleLink,ccClientText(43715))
	self:SetWndText(self.mTxtTitleAttr,ccClientText(43716))
	local qualityIcon = GameTable.RarityRef[petCfg.quality]

    self:SetWndEasyImage(self.mImgType, qualityIcon.qualityText, function()
        CS.ShowObject(self.mImgType, true)
    end)
	if petCfg and string.isempty(petCfg.spine) then
		self:SetWndEasyImage(self.mImgSpine,petCfg.icon,function()
			CS.ShowObject(self.mImgSpine,true)
			local img = self:FindWndImage(self.mImgSpine)
			img:SetNativeSize()
		end)
		CS.ShowObject(self.mPetSpine,false)
	else
		CS.ShowObject(self.mPetSpine,true)
		CS.ShowObject(self.mImgSpine,false)
		self:DestroyWndSpineByKey("PetDrawing")
		local dpSpine = self:CreateWndSpine(self.mPetSpine,petCfg.spine,"PetDrawing",true,function (dpLoaded)
			dpLoaded:PlayAnimation(0,"idle",true)
		end,true)
		dpSpine:StartLoad()
	end

	self:OnUpdateArrow()
	self:OnUpdateStar()
	self:OnSkillDesc()
	self:RefreshEquipPage()
end
------------------------------------------------------------------
return UISubPeEq