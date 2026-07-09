---
--- Created by LCM.
--- DateTime: 2024/3/18 11:57:11
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISpiritSagaPreviewView:LWnd
local UISpiritSagaPreviewView = LxWndClass("UISpiritSagaPreviewView", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISpiritSagaPreviewView:UISpiritSagaPreviewView()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISpiritSagaPreviewView:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISpiritSagaPreviewView:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISpiritSagaPreviewView:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()
end

function UISpiritSagaPreviewView:InitShowAttrList()
    local list = self:GetShowAttrList()
    local uiShowAttrList = self._uiShowAttrList
    if uiShowAttrList then
        uiShowAttrList:RefreshList(list)
    else
        uiShowAttrList = self:GetUIScroll("uiShowAttrList")
        self._uiShowAttrList = uiShowAttrList
        uiShowAttrList:Create(self.mShowAttrList,list,function(...) self:OnDrawShowAttrCell(...) end)
    end
	local enable = #list > 7
	uiShowAttrList:EnableScroll(enable)
end

function UISpiritSagaPreviewView:InitEvent()
    self:SetWndClick(self.mEnterBtn,function() self:OnClickEnterBtnFunc() end)
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    -- self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCancelBtn,function() self:OnClickCancelBtnFunc() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UISpiritSagaPreviewView:InitMsg()
	 self:WndNetMsgRecv(LProtoIds.SpiritHeroLinkResp,function(pb) self:OnSpiritHeroLinkResp(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

------------------------- List -------------------------


function UISpiritSagaPreviewView:GetShowAttrList()
	local list = self._showAttrList
	return list
end

function UISpiritSagaPreviewView:DisposeShowAttrList()
	self._showAttrList = gModelSpiritHero:GetShowAttrList(self._oldSpiritHero,self._newSpiritHero)
end

function UISpiritSagaPreviewView:OnSpiritHeroLinkResp(pb)
	if pb.spiritHeroId ~= self._spiritHeroId then return end
	if pb.heroId ~= self._heroId then return end
	local heroServerData = gModelHero:GetHeroServerDataById(self._heroId)
	local spiritServerData = gModelHero:GetHeroServerDataById(self._spiritHeroId)
	local spiritSer = table.clone(spiritServerData)
	local spiritCurServerData = table.clone(self._firstServerData)
	spiritSer.star = heroServerData.star
	spiritSer.level = heroServerData.level
	spiritSer.star = heroServerData.star
	spiritSer.star = heroServerData.star
	GF.OpenWnd("UISpiritSagaLinkRet",{
		spiritHeroId = self._spiritHeroId,
		heroId = self._heroId,
		oldSpiritHero = self._oldSpiritHero,
		newSpiritHero = self._newSpiritHero,
		showAttrList = self._showAttrList,
		spiritHeroBeforeData = spiritSer,
		spiritCurServerData = spiritCurServerData,
	})
	self:WndClose()
end

function UISpiritSagaPreviewView:CreateHeroIcon(trans,itemdata,changeHeroRefId,spiritHeroId,spiritHeroSkin)
	if not itemdata then return end
	local IconTrans = self:FindWndTrans(trans,"CommonUI/Icon")

	local instanceId = trans:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(IconTrans)

	local refId = itemdata.refId
	if changeHeroRefId then
		refId = changeHeroRefId
	end

	local id = itemdata.id
	if spiritHeroId then
		id = spiritHeroId
	end

	local skin = itemdata.skin
	if spiritHeroSkin then
		skin = spiritHeroSkin
	end

	local herodata = {
		trans = IconTrans,
		id = id,
		refId = refId,
		star = itemdata.star,
		level = itemdata.level,
		skin = skin,
		isResonance = itemdata.resonance,
	}
	baseClass:SetHeroDataSet(herodata)
	baseClass:DoApply()
end

function UISpiritSagaPreviewView:RefreshView()
	self:ShowSpiritHero()
	self:InitShowAttrList()
end

function UISpiritSagaPreviewView:InitData()
	self._spiritHeroId = self:GetWndArg("spiritHeroId")
	self._heroId = self:GetWndArg("heroId")
	self._oldSpiritHero = self:GetWndArg("oldSpiritHero")
	self._newSpiritHero = self:GetWndArg("newSpiritHero")

	local firstServerData = gModelHero:GetHeroServerDataById(self._spiritHeroId)
	self._firstServerData = firstServerData
	self:DisposeShowAttrList()
end

function UISpiritSagaPreviewView:OnClickEnterBtnFunc()
	local sendMsgFunc = function()
		if not self:IsWndValid() then return end
		gModelSpiritHero:OnSpiritHeroLinkReq(self._spiritHeroId,self._heroId)
	end
	local checkTargetHeroLinkStatusFunc = function()
		if not self:IsWndValid() then return end
		local heroServerData = gModelHero:GetHeroServerDataById(self._heroId)
		if heroServerData then
			local targetLinkStatus = gModelSpiritHero:CheckHeroIsHaveLink(heroServerData)
			if targetLinkStatus then
				local targetSpiritHeroId = gModelSpiritHero:GetHeroLinkId(heroServerData)
				if targetSpiritHeroId then
					local targetSpiritHeroServerData = gModelHero:GetHeroServerDataById(targetSpiritHeroId)
					if targetSpiritHeroServerData then
						gModelSpiritHero:RelieveTargetHeroLinkPop(heroServerData,targetSpiritHeroServerData,sendMsgFunc,self:GetWndName())
						return
					end
				end
			end
		end
		sendMsgFunc()
	end
	local firstServerData = self._firstServerData
	local isHaveLink = gModelSpiritHero:CheckSpiritHeroIsHaveLink(firstServerData)
--[[	if isHaveLink then
	else
		local heroServerData = gModelHero:GetHeroServerDataById(self._heroId)
		if heroServerData then
			isHaveLink = gModelSpiritHero:CheckHeroIsHaveLink(heroServerData)
		end
		if isHaveLink then
			showData = firstServerData
		end
	end]]
	if isHaveLink then
		--- 先判断自己是否被连接
		local relieveLinkHeroId = gModelSpiritHero:GetSpiritHeroLinkId(firstServerData)
		local relieveLinkHeroServerData = gModelHero:GetHeroServerDataById(relieveLinkHeroId)
		gModelSpiritHero:RelieveLinkPop(firstServerData,relieveLinkHeroServerData,checkTargetHeroLinkStatusFunc,self:GetWndName())
	else
		checkTargetHeroLinkStatusFunc()
	end
end

function UISpiritSagaPreviewView:ShowSpiritHero()
	local spiritHeroId = self._spiritHeroId
	local spiritServerData = gModelHero:GetHeroServerDataById(spiritHeroId)
	self:CreateHeroIcon(self.mSpiritHero,spiritServerData)

	local spiritRefId = spiritServerData.refId

	local heroId = self._heroId
	local heroServerData = gModelHero:GetHeroServerDataById(heroId)
	self:CreateHeroIcon(self.mLinkHero,heroServerData,spiritRefId,spiritHeroId,spiritServerData.skin)
end

function UISpiritSagaPreviewView:InitText()
	-- self:SetTextTile(self.mRuleTitle,ccClientText(31216))
	self:SetWndText(self.mTitleTxt,ccClientText(31217))
	self:SetWndText(self.mDesc,ccClientText(31218))
	self:SetWndButtonText(self.mEnterBtn,ccClientText(31220))
	self:SetWndButtonText(self.mCancelBtn,ccClientText(31219))
	self:SetWndText(self.mCloseTip, ccClientText(10103))
end

function UISpiritSagaPreviewView:OnDrawShowAttrCell(list,item,itemdata,itempos)
    local BgTrans = self:FindWndTrans(item,"Bg")
    local AttrNameTrans = self:FindWndTrans(BgTrans,"AttrName")
    local BeforeValueTrans = self:FindWndTrans(BgTrans,"BeforeValue")
    local LaterValueTrans = self:FindWndTrans(BgTrans,"LaterValue")

	self:SetWndText(AttrNameTrans,itemdata.attrName)
	self:SetWndText(BeforeValueTrans,itemdata.oldValue)
	self:SetWndText(LaterValueTrans,itemdata.newValue)
end

function UISpiritSagaPreviewView:OnClickCancelBtnFunc()
	self:WndClose()
end

------------------------- List -------------------------

------------------------------------------------------------------
return UISpiritSagaPreviewView



