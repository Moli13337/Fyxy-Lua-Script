---
--- Created by LCM.
--- DateTime: 2024/3/28 18:06:04
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIOrdinSowMsg:LWnd
local UIOrdinSowMsg = LxWndClass("UIOrdinSowMsg", LWnd)

local typeofRectTransform = typeof(CS.RectTransform)
local YXUIPointUtil = CS.YXUIPointUtil

local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local Tweening = DG.Tweening
local typeDOTween = Tweening.DOTween
local EaseOutCubic = Tweening.Ease.OutCubic

UIOrdinSowMsg.TYPE_MSG = 1			-- 带背景的文字
UIOrdinSowMsg.TYPE_ICONMSG = 2		-- 带背景 有icon和文字
UIOrdinSowMsg.TYPE_NOBGMSG = 3		-- 仅有文字飘字

local pattern = "#path=([%w_]+)#"
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIOrdinSowMsg:UIOrdinSowMsg()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIOrdinSowMsg:OnWndClose()
	if self._textPool then
		self._textPool:Destroy()
		self._textPool = nil
	end

	if self._itemPool then
		self._itemPool:Destroy()
		self._itemPool = nil
	end

	if self._noTextBgPool then
		self._noTextBgPool:Destroy()
		self._noTextBgPool = nil
	end

	for k,v in pairs(self._seqList or {}) do
		v:Kill(false)
	end
	self._seqList =nil

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIOrdinSowMsg:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIOrdinSowMsg:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:VersionRefresh()
	self:InitMsg()
	self:InitData()
    
end

function UIOrdinSowMsg:OnTimer(key)
	if self._showTimer ==key then
		self:OnRunShowTimer()
	end
end

function UIOrdinSowMsg:CreateMsg(msgInfo)
	if not msgInfo then return end
	local showType = msgInfo.showType
	local itemNew
	if showType == UIOrdinSowMsg.TYPE_MSG then
		itemNew = self:CreateMsgItem(msgInfo)
	elseif showType == UIOrdinSowMsg.TYPE_ICONMSG then
		itemNew = self:CreateIconMsgItem(msgInfo)
	elseif showType == UIOrdinSowMsg.TYPE_NOBGMSG then
		itemNew = self:CreateNoBgMsgItem(msgInfo)
	end

	self:SetPos(itemNew,msgInfo)

	local itemRoot = self.mShowRoot
	itemNew.transform:SetParent(itemRoot.transform, false)

	CS.ShowObject(itemNew.transform,false)
	return {
		item = itemNew,
		msgInfo = msgInfo
	}
end

function UIOrdinSowMsg:DestroyMsgItem(msgItemInfo)
	local item = msgItemInfo.item
	local msgInfo = msgItemInfo.msgInfo
	local showType = msgInfo.showType
	if showType == UIOrdinSowMsg.TYPE_MSG then
		self._textPool:ReturnObj(item)
	elseif showType == UIOrdinSowMsg.TYPE_ICONMSG then
		self._itemPool:ReturnObj(item)
	elseif showType == UIOrdinSowMsg.TYPE_NOBGMSG then
		self._noTextBgPool:ReturnObj(item)
	end
end

function UIOrdinSowMsg:CreateIconMsgItem(msgInfo)
	local itemNew = self._itemPool:GetObj()
	local itemRootTrans = self:FindWndTrans(itemNew,"itemRoot")
	local UITextTrans = self:FindWndTrans(itemNew,"UIText")
	return itemNew
end

function UIOrdinSowMsg:ShowMsg(msgInfo)
	local msgItemInfo = self:CreateMsg(msgInfo)
	self:OnItemShowEx(msgItemInfo)
end

function UIOrdinSowMsg:CreateMsgItem(msgInfo)
	local itemNew = self._textPool:GetObj()
	local msg = msgInfo.msg
	local textTrans = self:FindWndTrans(itemNew,"text")
	self:SetWndText(textTrans,msg)
	return itemNew
end

function UIOrdinSowMsg:OnDisposeMsg(showType,msg,root)
	local data = {
		showType = showType,
		msg = msg,
		root = root,
	}
	if #self._msgWaitList==0 and #self._showingList==0 then
		self:ShowMsg(data)
	else
		table.insert(self._msgWaitList,data)
	end
	if not self:IsTimerExist(self._showTimer) then
		self:TimerStart(self._showTimer,0.5,false,-1)
	end
end

function UIOrdinSowMsg:OnItemShowEx(msgItemInfo)
	if not msgItemInfo then return end
	local item = msgItemInfo.item
	if not item then return end

	local itemTrans = item.transform
	CS.ShowObject(itemTrans,true)

	local seq = typeDOTween.Sequence()
	self._seqList[seq] = seq

	local moveTime = 3
	local moveY = 288
	local pos = itemTrans.localPosition

	local movetween = itemTrans:DOLocalMoveY(pos.y + moveY,moveTime)

	local alphaTime = 2.5
	local canvasGroup = itemTrans:GetComponent(typeofCanvasGroup)
	canvasGroup.alpha =1
	local alphatween = CS.YXDOTweenModuleUI.DOFade(canvasGroup, 0, alphaTime)

	seq:SetAutoKill(true)
	seq:Append(movetween)
	seq:Insert(0.5,alphatween)

	seq:OnComplete(function()
		self._seqList[seq]= nil
		table.remove(self._showingList,1)
		self:CheckStopTimer()
		self:DestroyMsgItem(msgItemInfo)
	end)
	seq:SetUpdate(true)
	seq:PlayForward()
end

function UIOrdinSowMsg:InitData()
	self._msgWaitList = {}
	self._showingList = {}

	self._seqList={}
	self._showTimer = "msgShowTimer"

	local itempool1 = UIObjPool:New()
	itempool1:Create(self.mTemplates,self.mMsgTemplate)
	self._textPool = itempool1

	local itempoo2 = UIObjPool:New()
	itempoo2:Create(self.mTemplates,self.mMsgTemplate2)
	self._itemPool = itempoo2

	local itempool3 = UIObjPool:New()
	itempool3:Create(self.mTemplates,self.mMsgTemplate3)
	self._noTextBgPool = itempool3

	self._screenHeight = self.mShowRoot.rect.height / 2
end

function UIOrdinSowMsg:InitMsg()

	-- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
	 self:WndEventRecv(EventNames.ON_DREAMTRIP_SHOWMSG,function(...) self:OnDisposeMsg(...) end)
end

function UIOrdinSowMsg:CheckStopTimer()
	if #self._msgWaitList ==0 and #self._showingList==0 then
		self:TimerStop(self._showTimer)
	end
end


function UIOrdinSowMsg:VersionRefresh()
	local text = self:FindWndTrans(self.mMsgTemplate,"text")
	self:InitTextLineWithLanguage(text,-30)
end

function UIOrdinSowMsg:CreateNoBgMsgItem(msgInfo)
	local itemNew = self._noTextBgPool:GetObj()
	local UITextTrans = self:FindWndTrans(itemNew,"UIText")
	local msg = msgInfo.msg
	self:SetWndText(UITextTrans,msg)
	return itemNew
end

function UIOrdinSowMsg:SetPos(itemNew,msgInfo)
	local pos = Vector3.New(0,0,0)
	local root = msgInfo.root
	if root then
		local canvasRect = LGameUI.GetUICanvasRoot()
		--local target = self.mShowRoot:GetComponent(typeofRectTransform)
		local targetPos = YXUIPointUtil.GetScreenPoint(canvasRect,root)
		local tarY = targetPos.y
		pos = Vector3(0,tarY,0)
	end
	itemNew.transform.localPosition = pos
end

function UIOrdinSowMsg:OnRunShowTimer()
	local msgInfo = self._msgWaitList[1]
	if msgInfo then
		table.remove(self._msgWaitList,1)
		self:ShowMsg(msgInfo)
	end
	self:CheckStopTimer()
end


------------------------- List -------------------------


------------------------- List -------------------------

------------------------------------------------------------------
return UIOrdinSowMsg



