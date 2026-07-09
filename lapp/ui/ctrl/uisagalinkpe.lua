---
--- Created by Administrator.
--- DateTime: 2024/9/25 10:56:20
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaLinkPe:LWnd
local UISagaLinkPe = LxWndClass("UISagaLinkPe", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaLinkPe:UISagaLinkPe()
	self._equipIconList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaLinkPe:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaLinkPe:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaLinkPe:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:SetWndClick(self.mCloseBtn,function()
		self:WndClose()
	end)
	self:WndNetMsgRecv(LProtoIds.PetLinkByHeroResp,function()
		self:WndClose()
	end)
	self:InitEquipList()
end

function UISagaLinkPe:OnDrawItemCell(list, item, itemdata, itempos, fromHeadTail)
	---@type StructPet
	local pet = itemdata
	local PetIconTrans = CS.FindTrans(item, "IconRoot")
	local Icon = CS.FindTrans(PetIconTrans, "Icon")
	local PetNameTrans = CS.FindTrans(item, "PetName")
	local TxtDesc = CS.FindTrans(item, "ScrollView/Viewport/TxtDesc")
	local LinkBtn = CS.FindTrans(item, "WearBtn")
	local btnName = CS.FindTrans(item, "WearBtn/btnName")

    local InstanceID = item:GetInstanceID()
    if PetIconTrans then
        local baseClass = self._equipIconList[InstanceID]
        if not baseClass then
            baseClass = CommonIcon:New(self)
            self._equipIconList[InstanceID] = baseClass
            baseClass:Create(Icon)
        end
		baseClass:SetPetInfoSet(pet:GetServerData())
        self:SetIconClickScale(PetIconTrans, true)

        self:SetWndClick(PetIconTrans, function()
			GF.OpenWnd("UIPeView",{refId = pet._petRefId,playerId = gModelPlayer:GetPlayerId()})
        end)
        baseClass:DoApply()
        -- baseClass._curIconCls._iconInst.transform.localScale = Vector3.New(0.77, 0.77, 0.77)

    end
	local quality = pet.petCfg.quality
	local name = ccLngText(pet.petCfg.name)
	self:SetWndText(PetNameTrans, name)
	-- 名字设置颜色
	local color = gModelItem:GetColorByQualityId(quality)
	self:SetXUITextTransColor(PetNameTrans, color)
	local skillDesc,condiDesc,isCondi = pet:GetLinkSkillDesc()
	self:SetWndText(TxtDesc,isCondi and skillDesc.." <color=#c81212>("..condiDesc..")</color>" or skillDesc)
	self:SetWndText(btnName,ccClientText(43775))
	self:SetWndClick(LinkBtn,function()
		gModelPet:OnPetLinkByHeroReq(self._heroId,0,pet._petRefId)

	end)
end

function UISagaLinkPe:InitEquipList()

	local petList = gModelPet:GetCanLinkPetList(self._heroId)
	table.sort(petList,function(a,b)
		local aCfg = a:GetPetConfig()
		local bCfg = b:GetPetConfig()
		if aCfg.quality ~= bCfg.quality then
			return aCfg.quality > bCfg.quality
		else
			if a._star ~= b._star then
				return a._star > b._star
			else
				return a._level>b._level
			end
		end
	end)

	CS.ShowObject(self.mNoRecord,false)
	local key = self.mWearList:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(petList)
	else
		uiList = self:GetUIScroll(key)
		local listType = UIItemList.WRAP
		uiList:Create(self.mWearList,petList,function(...) self:OnDrawItemCell(...) end,listType)
	end
	if #petList==0 then
		CS.ShowObject(self.mNoRecord,true)
		local GetBtnText = self:FindWndTrans(self.mGetBtn,"Light/Text")
		local data = { refId = 36007, IntroTran = self.mEmptyText, TextBgTran = self.mEmptyTextBg, IconTran = self.mEmptyIcon,GetBtn = self.mGetBtn ,GetBtnText =GetBtnText }
		local emptyList = self:GetCommonEmptyList("_empty")
		emptyList:RefreshUI(data)
	end
end
function UISagaLinkPe:InitData()
    self._heroId = self:GetWndArg("heroId")

	self:SetWndText(self.mTitle,ccClientText(43773))
	self:SetWndText(self.mTxtTips,ccClientText(43774))

end

------------------------------------------------------------------
return UISagaLinkPe