---
--- Created by LCM.
--- DateTime: 2024/3/28 10:52:01
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaTreeExtraJNAct:LWnd
local UISagaTreeExtraJNAct = LxWndClass("UISagaTreeExtraJNAct", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaTreeExtraJNAct:UISagaTreeExtraJNAct()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaTreeExtraJNAct:OnWndClose()
	self:ClearCommonIconList(self._skillIconList)
	gModelHero:ClearUpLvTreeSelHeroList()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaTreeExtraJNAct:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaTreeExtraJNAct:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()
end

function UISagaTreeExtraJNAct:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UISagaTreeExtraJNAct:SetTitleImg(img,func)
	self:SetWndEasyImage(self.mTitle,img,function()
		if func then func() end
		CS.ShowObject(self.mTitle,true)
	end, true)
end

function UISagaTreeExtraJNAct:InitText()
	self:SetWndText(self.mAwakenWearSucTxt,ccClientText(37614))
	self:SetWndButtonText(self.mAwakenWearBtn,ccClientText(37613))
	self:SetWndText(self.mCloseTips,ccClientText(10103))
end

function UISagaTreeExtraJNAct:CreateSkillIcon(trans,skillRef)
	local SkillIconTrans = self:FindWndTrans(trans,"CommonUI/Icon/SkillIcon")

	local skillId = skillRef.refId
	local skillIconList = self._skillIconList
	if not skillIconList then
		skillIconList = {}
		self._skillIconList = skillIconList
	end
	local InstanceID = SkillIconTrans:GetInstanceID()
	local baseClass = skillIconList[InstanceID]
	if not baseClass then
		baseClass = SkillIcon:New(self)
		skillIconList[InstanceID] = baseClass
	end
	baseClass:SetSkillInfo(nil,false,nil,1)
	baseClass:ShowLvl(false)
	baseClass:ShowLock(false)
	baseClass:Create(SkillIconTrans,skillId,function()
	end)
	baseClass:SetIconAndIconBgGray(false)

	CS.ShowObject(trans,true)

	local nameText = ccLngText(skillRef.name)
	self:SetWndText(self.mAwakenSkillName, nameText)
end

function UISagaTreeExtraJNAct:CreateCommonTitleEff(effName)
	effName = effName or "fx_ui_shengxing_1"
	self:CreateWndEffect(self.mShowEffRoot,effName,effName,100,false,false,nil,function(dpTrans)
		dpTrans.gameObject:SetActive(true)
		CS.ShowObject(self.mShowEffRoot,true)
	end)
end

function UISagaTreeExtraJNAct:OnHeroTreePointSelectSkillResp(pb)
	self:WndClose()
end

function UISagaTreeExtraJNAct:InitData()
	self._heroId = self:GetWndArg("heroId")
	self._awakenTreePointId = self:GetWndArg("awakenTreePointId")
	self._extraSkillCostRefId = self:GetWndArg("extraSkillCostRefId")

	local heroServerData
	if self._heroId then
		heroServerData = gModelHero:GetHeroServerDataById(self._heroId)
	end
	self._heroServerData = heroServerData

	self._skillIconList = {}
end

function UISagaTreeExtraJNAct:RefreshAwakenUpSkillView()
	local heroId = self._heroId
	if not heroId then return end

	local awakenTreePointId = self._awakenTreePointId
	if not awakenTreePointId then return end

	local extraSkillCostRefId = self._extraSkillCostRefId
	if not extraSkillCostRefId then return end

	local heroServerData = self._heroServerData
	if not heroServerData then return end

	local treeInfo = gModelHero:GetServerHeroTreePointInfo(heroId,awakenTreePointId)
	if not treeInfo then return end

	local ref = gModelHero:GetHeroTreePointLvRef(treeInfo.lvRefId)
	if not ref then return end

	local curWearSkill = treeInfo.skillId
	local skillId = treeInfo.skillId
	local skillRef = gModelHero:GetSkillByStarId(skillId)
	if skillRef then
		self:CreateSkillIcon(self.mAwakenSkillRoot,skillRef)
	end
	local showWearBtn = curWearSkill ~= skillId
	CS.ShowObject(self.mAwakenWearBtn,showWearBtn)
	CS.ShowObject(self.mAwakenWearSucTxt,not showWearBtn)
end

function UISagaTreeExtraJNAct:RefreshView()
	self:CreateCommonTitleEff()
	self:SetTitleImg("heroup_txt_2",function()
	end)
	self:RefreshAwakenUpSkillView()
end

function UISagaTreeExtraJNAct:InitMsg()
	self:WndNetMsgRecv(LProtoIds.HeroTreePointSelectSkillResp,function(pb) self:OnHeroTreePointSelectSkillResp(pb) end)

	-- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

------------------------- List -------------------------


------------------------- List -------------------------

------------------------------------------------------------------
return UISagaTreeExtraJNAct



