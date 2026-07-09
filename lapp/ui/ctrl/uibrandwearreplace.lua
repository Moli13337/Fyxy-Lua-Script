---
--- Created by Administrator.
--- DateTime: 2025/6/6 15:16:14
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBrandWearReplace:LWnd
local UIBrandWearReplace = LxWndClass("UIBrandWearReplace", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBrandWearReplace:UIBrandWearReplace()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBrandWearReplace:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBrandWearReplace:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBrandWearReplace:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self.refId = self:GetWndArg("refId")
	self.wearHero = self:GetWndArg("heroId")
	self.wearIndx= self:GetWndArg("index")
	self:OnClickEvent()
	self:UpdateTop()
	self:InitHeroList()
end

function UIBrandWearReplace:OnDrawHeroCell(list, item, itemdata, itempos)
	CS.ShowObject(item,true)
	local aniRootTrans = self:FindWndTrans(item, "AniRoot")
	local Icon = self:FindWndTrans(aniRootTrans, "Icon")
	local TxtName = self:FindWndTrans(aniRootTrans, "TxtName")
	local BtnReplace = self:FindWndTrans(aniRootTrans, "BtnReplace")
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			TxtName = TxtName,
			Icon = Icon,
			BtnReplace = BtnReplace,
		}
	end
	local heroData = gModelHero:GetHeroById(itemdata.heroId)
	local heroCfg= GameTable.CharacterEffectRef[heroData._refId]
	local baseClass = self:GetCommonIcon(itemCache.Icon)
	baseClass:Create(itemCache.Icon)
	baseClass:SetHeroPlayer(itemdata.heroId)
	baseClass:EnableShowNum(false)
	baseClass:DoApply()

	self:SetWndText(itemCache.TxtName,ccLngText(heroCfg.name))
	self:SetWndButtonText(itemCache.BtnReplace,ccClientText(47566))
	self:SetWndClick(itemCache.BtnReplace,function()
		gModelBadge:BadgeWearReq(1,self.wearHero,{slot = self.wearIndx,refId = self.refId,tarHeroId = itemdata.heroId})--装配
		self:WndClose()
	end)
end

function UIBrandWearReplace:InitHeroList()
	local info = gModelBadge:GetBadgeInfo(self.refId) or {}
	local list = {}
	for slot, wears in pairs(info.slotToHeroWears or {}) do--槽位=英雄ID
		for index, value in ipairs(wears) do
			table.insert(list,{slot = value.slot,heroId = value.heroId})
		end
	end
	local petList = self._heroList
	local superList
	if not petList then
		petList = self:GetUIScroll("mWearReplace")
		self._heroList = petList
		petList:Create(self.mHeroList, list, function(...)
			self:OnDrawHeroCell(...)
		end, UIItemList.SUPER_GRID, false)
		superList = petList:GetList()
	else
		petList:RefreshList(list)
		superList = petList:GetList()
		superList:DrawAllItems()
	end
	-- superList:MoveToPos(moveIndx)
end
function UIBrandWearReplace:UpdateTop()
	local info  = gModelBadge:GetBadgeInfo(self.refId)
	self.star = info and info:GetBadgeStar() or nil
	self.starRef = info and info:GetStarRef()
	local ref = info and info:GetBadgeRef()
	local baseClass = self:GetCommonIcon(self.mCommonUI)
	baseClass:Create(self.mCommonUI)
	baseClass:SetCommonReward(LItemTypeConst.TYPE_BADGE, self.refId,1)
	baseClass:EnableShowNum(false)
	baseClass:DoApply()
	self:SetWndText(self.mTxtTips,ccClientText(47564))
	self:SetWndText(self.mTxtTitle,ccClientText(47565))

	local color = self.starRef.wearNum<0 or self.starRef.wearNum-info.wearNum>0 and "#0f6f23"  or "#b20000"
	self:SetWndText(self.mTxtWearNum,string.replace(ccClientText(47562),color,info.wearNum,self.starRef.wearNum>0 and self.starRef.wearNum or ccClientText(47551)))
	self:SetWndText(self.mBadgeName,ccLngText(ref.name))
	local color = gModelItem:GetColorByQualityId(ref.quality)
	if color then
		local naneTxt = self:FindWndText(self.mBadgeName)
		self:SetXUITextColor(naneTxt, color)
	end

	local skillCfg = GameTable.SnakeSkillRef[self.starRef.skill]
	self:SetWndText(self.mTxtDesc,ccLngText(skillCfg.description))

end

function UIBrandWearReplace:OnClickEvent()
	self:SetWndClick(self.mCloseBtn,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mMask,function()
		self:WndClose()
	end)
end
------------------------------------------------------------------
return UIBrandWearReplace