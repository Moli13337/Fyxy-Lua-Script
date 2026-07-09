---
--- Created by LCM.
--- DateTime: 2024/3/18 16:20:52
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISpiritSagaLinkRet:LWnd
local UISpiritSagaLinkRet = LxWndClass("UISpiritSagaLinkRet", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISpiritSagaLinkRet:UISpiritSagaLinkRet()
	self._seqKey = "_seqKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISpiritSagaLinkRet:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISpiritSagaLinkRet:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISpiritSagaLinkRet:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	CS.ShowObject(self.mTitleEff,false)
	self:CreateWndEffect(self.mTitleEff,"fx_ui_shengxing_1","fx_ui_shengxing_1",100,false,false)
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()
	self:PlayAni()
end

function UISpiritSagaLinkRet:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UISpiritSagaLinkRet:InitShowAttrList()
    local list = self:GetShowAttrList()
    local uiShowAttrList = self._uiShowAttrList
    if uiShowAttrList then
        uiShowAttrList:RefreshList(list)
    else
        uiShowAttrList = self:GetUIScroll("uiShowAttrList")
        self._uiShowAttrList = uiShowAttrList
        uiShowAttrList:Create(self.mShowAttrList,list,function(...) self:OnDrawShowAttrCell(...) end)
    end
	local enable = #list > 5
	uiShowAttrList:EnableScroll(enable)
end

function UISpiritSagaLinkRet:InitData()
	self._spiritHeroId = self:GetWndArg("spiritHeroId")
	self._heroId = self:GetWndArg("heroId")
	self._oldSpiritHero = self:GetWndArg("oldSpiritHero")
	self._newSpiritHero = self:GetWndArg("newSpiritHero")
	self._showAttrList = self:GetWndArg("showAttrList")
	self._spiritHeroBeforeData = self:GetWndArg("spiritHeroBeforeData")
	self._spiritCurServerData = self:GetWndArg("spiritCurServerData")

	self._uiAttrTransList = {}
end

function UISpiritSagaLinkRet:RefreshView()
	self:ShowSpiritHero()
	self:InitShowAttrList()
end

function UISpiritSagaLinkRet:PlayAni()
	local contentTrans = self.mContent
	contentTrans.localRotation = Quaternion.Euler(90,0,0)

	local seqKey = self._seqKey
	self:TweenSeqKill(seqKey)

	local seqTween
	seqTween = self:TweenSeqCreate(seqKey, function(seq)
		local duration = 0.4
		local rotateTween = contentTrans:DORotate(Vector3.New(0,0,0),duration)
		seq:Append(rotateTween)

		local showTopTime = 0.2
		seq:AppendInterval(showTopTime)
		seq:AppendCallback(function()
			LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_UPGRADE_COMMON)
			CS.ShowObject(self.mTitleEff,true)
		end)

		seq:AppendInterval(showTopTime)
		seq:AppendCallback(function()
			CS.ShowObject(self.mShowHeroDiv,true)
			CS.ShowObject(self.mShowAttrListDiv,true)
		end)

		local showAttrCellTim = 0.1
		seq:AppendInterval(showAttrCellTim)
		local uiAttrTransList = self._uiAttrTransList
		for i,v in ipairs(uiAttrTransList) do
			seq:AppendCallback(function ()
				CS.ShowObject(v,true)
			end)
			seq:AppendInterval(showAttrCellTim)
		end

		return seq
	end)
	seqTween:OnComplete(function()
		self:TweenSeqKill(seqKey)
	end)
	seqTween:PlayForward()
end
------------------------- List -------------------------
function UISpiritSagaLinkRet:GetShowAttrList()
	return self._showAttrList
end

function UISpiritSagaLinkRet:ShowSpiritHero()
--[[	local spiritHeroId = self._spiritHeroId
	local spiritServerData = gModelHero:GetHeroServerDataById(spiritHeroId)
	self:CreateHeroIcon(self.mSpiritHero,spiritServerData)

	local heroId = self._heroId
	local heroServerData = gModelHero:GetHeroServerDataById(heroId)
	self:CreateHeroIcon(self.mLinkHero,heroServerData)]]


	local spiritHeroId = self._spiritHeroId
	local spiritHeroBeforeData = self._spiritCurServerData
	if not spiritHeroBeforeData then
		spiritHeroBeforeData = gModelHero:GetHeroServerDataById(spiritHeroId)
	end
	self:CreateHeroIcon(self.mSpiritHero,spiritHeroBeforeData)

	local spiritServerData = gModelHero:GetHeroServerDataById(spiritHeroId)
	self:CreateHeroIcon(self.mLinkHero,spiritServerData)
end

function UISpiritSagaLinkRet:InitMsg()
	self:SetWndText(self.mCloseTip, ccClientText(10103))
	-- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UISpiritSagaLinkRet:OnDrawShowAttrCell(list,item,itemdata,itempos)
	local BgTrans = self:FindWndTrans(item,"Bg")
	local AttrNameTrans = self:FindWndTrans(BgTrans,"AttrName")
	local BeforeValueTrans = self:FindWndTrans(BgTrans,"BeforeValue")
	local LaterValueTrans = self:FindWndTrans(BgTrans,"LaterValue")

	CS.ShowObject(BgTrans,false)

	local uiAttrTransList = self._uiAttrTransList
	if not uiAttrTransList then
		uiAttrTransList = {}
		self._uiAttrTransList = uiAttrTransList
	end
	table.insert(uiAttrTransList,BgTrans)

	local key = item:GetInstanceID()
	self:CreateWndEffect(BgTrans,"fx_ui_shengxing_3",key,100,false,false)

	self:SetWndText(AttrNameTrans,itemdata.attrName)
	self:SetWndText(BeforeValueTrans,itemdata.oldValue)
	self:SetWndText(LaterValueTrans,itemdata.newValue)
end

function UISpiritSagaLinkRet:CreateHeroIcon(trans,itemdata)
	if not itemdata then return end
	local IconTrans = self:FindWndTrans(trans,"CommonUI/Icon")

	local instanceId = trans:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(IconTrans)

	local herodata = {
		trans = IconTrans,
		id = itemdata.id,
		refId = itemdata.refId,
		star = itemdata.star,
		level = itemdata.level,
		skin = itemdata.skin,
		isResonance = itemdata.resonance,
	}
	baseClass:SetHeroDataSet(herodata)
	baseClass:DoApply()
end

------------------------- List -------------------------

------------------------------------------------------------------
return UISpiritSagaLinkRet



