 ---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMlTipsUI:LWnd
local UIMlTipsUI = LxWndClass("UIMlTipsUI", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMlTipsUI:UIMlTipsUI()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMlTipsUI:OnWndClose()
	if self.timer then
        LxTimer.DelayTimeStop(self.timer)
        self.timer = nil
    end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMlTipsUI:OnCreate()
	LWnd.OnCreate(self)

	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMlTipsUI:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

    --self:DoWndStartScale(0,self.mRoot)

	self:InitEvent()

	self.showRole = self:GetWndArg(2)
	if self.showRole then
		gModelPlayer:OnGetFormationShowReq(gModelPlayer:GetPlayerId(), LCombatTypeConst.COMBAT_MAIN)
	else
		self:InitCommand()
	end
end

function UIMlTipsUI:SpineMove()
	local seqCom = SequenceCom:New()
	local seq = seqCom:CreateSeq("delayFreeze")
	local Tweening = DG.Tweening
	local time = 2
	local downTweener = self.mRole:DOLocalMove(Vector2.New(0, -38), time):SetEase(Tweening.Ease.Linear)
	seq:Insert(0, downTweener)
	seq:InsertCallback(time, function()
		for _, v in ipairs(self.spineList) do
			v:PlayAni("idle", true)
		end
		-- CS.ShowObject(self.mBtnImage,true)
	end)
	seq:PlayForward()
end

function UIMlTipsUI:OnClickBtn()
	--local currBattleNode = gModelInstance:GetRawBattleNode()
	--if(currBattleNode == -1)then
	--	self:WndClose()
	--	return························································
	--end
	GF.OpenWndWait("UIWaitZC", { hideTime = 1 })
	self.timer = LxTimer.DelayTimeCall(function()
		GF.CloseWndByName("UIGolbMlNew")
		self.timer = nil
		self:WndClose()
	end, 0.7)
end

function UIMlTipsUI:InitCommand()
	self:SetWndButtonText(self.mBtnImage.transform, ccClientText(16753))
	local battleNum = self:GetWndArg(1)
	local chapterRef = gModelInstance:GetInstanceChapterRefByRefId(battleNum)
	self:SetWndText(self.mLblBiaoti,ccLngText(chapterRef.name))
	self:SetWndText(self.mDescText,ccLngText(chapterRef.chapterDes))
	local iconStr=chapterRef.chapterPic
	self:SetWndEasyImage(self.mIconImage,iconStr)
	local currChapter = gModelInstance:GetChapterId()
	--local currBattleNode = gModelInstance:GetRawBattleNode()
	local btnStr = ""
	CS.ShowObject(self.mBtnImage,false)
	-- self.canClose = true
	if currChapter == battleNum then
		-- if self.showRole then
		-- 	self.canClose = false
		-- 	CS.ShowObject(self.mBtnImage,false)
		-- else
			CS.ShowObject(self.mBtnImage,true)
		-- end
	elseif currChapter>battleNum then
		btnStr = ccClientText(10607)
	elseif currChapter<battleNum then
		btnStr = ccClientText(10606)
	end
	self:SetWndText(self.mBtnText,btnStr)
end

function UIMlTipsUI:CreateSpine(pb)
	-- local spineScale = GameTable.MainInstanceConfigRef["mapHeroSizeOnHook"] or 1
	local spineScale = 1
	self.spineList = {}
	for i, v in ipairs(pb.heroData.heros) do
		local ref = gModelHero:GetShowEffectById(v.refId)
		local root = CS.FindTrans(self.mRole, "Spine" .. i)
		local spineObj = LUIHeroObject:New(self)
		spineObj:Create(root, root.gameObject.name, ref.prefabName)
		spineObj:SetScale(spineScale)
		spineObj:ShowHero(true)
		spineObj:SetLoadedFunction(function()
			spineObj:PlayAni("run", true)
		end)
		spineObj:StartLoad()
		table.insert(self.spineList, spineObj)
		CS.ShowObject(root, true)
	end
end

function UIMlTipsUI:InitEvent()
	self:SetWndClick(self.mBgImage,function (...)
		-- if self.canClose then
			self:WndClose()
		-- end
	end)
	self:SetWndClick(self.mBtnClose,function (...)
		-- if self.canClose then
			self:WndClose()
		-- end
	end)
	self:SetWndClick(self.mBtnImage,function (...) self:OnClickBtn() end)

	self:WndNetMsgRecv(LProtoIds.GetFormationShowResp, function(pb)
		self:InitCommand()
		self:CreateSpine(pb)
		self:SpineMove()
	end)
end

------------------------------------------------------------------
return UIMlTipsUI


