---
--- Created by BY.
--- DateTime: 2023/10/7 17:42:59
---
------------------------------------------------------------------
local Tweening = DG.Tweening
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local LWnd = LWnd
---@class UIConoryPop:LWnd
local UIConoryPop = LxWndClass("UIConoryPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIConoryPop:UIConoryPop()
	self._uiheadList = {}
	self._rootTweenKey = "rootTweenKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIConoryPop:OnWndClose()
	self:ClearCommonIconList(self._uiheadList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIConoryPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIConoryPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitCommand()
end

function UIConoryPop:SetHeadIcon(item,player)
	CS.ShowObject(item,true)
	local headIcon = CS.FindTrans(item,"HeadIcon")
	local nameText = CS.FindTrans(item,"NameText")
	local info = {
		trans = headIcon,
		icon = player.head,
		headFrame = player.headFrame,
	}
	self:SetWndText(nameText,player.playerName)
	local uiheadlist = self._uiheadList
	local InstanceID = item:GetInstanceID()
	local baseClass = uiheadlist[InstanceID]
	if not baseClass then
		baseClass = HeadIcon:New(self)
		uiheadlist[InstanceID] = baseClass
	end
	baseClass:SetHeadData(info)
	baseClass:RefreshUI()
end

function UIConoryPop:SetTween()
	local seqTween
	self:TweenSeqKill(self._rootTweenKey)
	if not seqTween then
		seqTween = self:TweenSeqCreate(self._rootTweenKey,function(seq)
			local canvasGroup1 = self.mRelo1:GetComponent(typeofCanvasGroup)
			canvasGroup1.alpha = 0
			local canvasGroup2 = self.mRelo2:GetComponent(typeofCanvasGroup)
			canvasGroup2.alpha = 0
			local tweener = self.mRelo1.transform:DOLocalMove(Vector3.New(-163,324,0),0.2)
			seq:Append(tweener)

			local tweener = self.mRelo2.transform:DOLocalMove(Vector3.New(163,324,0),0.2)
			seq:Join(tweener)

			tweener = canvasGroup1:DOFade(1,0.4)
			seq:Join(tweener)

			tweener = canvasGroup2:DOFade(1,0.4)
			seq:Join(tweener)

			local relo2Mask = self:FindWndTrans(self.mRelo2, "Mask")
			local relo2MaskCanvas = relo2Mask:GetComponent(typeofCanvasGroup)
			relo2MaskCanvas.alpha = 0
			tweener = relo2MaskCanvas:DOFade(1,1)
			seq:Join(tweener)

			seq:AppendInterval(0.2)
			tweener = self.mWinText:DOScale(Vector3.New(1,1,1), 0.2)
			seq:Join(tweener)

			seq:AppendInterval(1)
			return seq
		end)
	end
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		CS.ShowObject(self.mRelo1,false)
		CS.ShowObject(self.mRelo2,false)
		CS.ShowObject(self.mEff1,false)
		CS.ShowObject(self.mEff2,false)
		self.mWinText.localScale = Vector3.New(0,0,0)
		self.mRelo1.localPosition = Vector3.New(-360,341,0)
		self.mRelo2.localPosition = Vector3.New(360,341,0)
		local canvasGroup1 = self.mRelo1:GetComponent(typeofCanvasGroup)
		canvasGroup1.alpha = 0
		local canvasGroup2 = self.mRelo2:GetComponent(typeofCanvasGroup)
		canvasGroup2.alpha = 0
		local relo2Mask = self:FindWndTrans(self.mRelo2, "Mask")
		local relo2MaskCanvas = relo2Mask:GetComponent(typeofCanvasGroup)
		relo2MaskCanvas.alpha = 0
		self:TweenSeqKill(self._rootTweenKey)
		self:RefreshData()
	end)
end

function UIConoryPop:InitCommand()
	self:SetWndClick(self.mBgImage,function ()self:WndClose() end)

	local rootCanvas = self.mRoot:GetComponent(typeof(UnityEngine.Canvas))
	rootCanvas.sortingOrder = self:GetWndSortOrder() + 4
	rootCanvas.sortingLayerName = self:GetWndSortLayer()

	local _structGuildMeleeReportInfo = self:GetWndArg("StructGuildMeleeReportInfo")
	self:RefreshEff(_structGuildMeleeReportInfo)
end

function UIConoryPop:RefreshData()
	local _structGuildMeleeReportInfo = gModelGuildMelee:GetContinuousWin()
	if not _structGuildMeleeReportInfo then
		self:WndClose()
		return
	end
	self:RefreshEff(_structGuildMeleeReportInfo)
end

function UIConoryPop:RefreshEff(itemdate)
	local key1 = "fx_zhanbao_liansheng"
	local key2 = "fx_zhanbao_liansheng_xian"
	if self:FindWndEffectByKey(key1) and self:FindWndEffectByKey(key2) then
		CS.ShowObject(self.mEff1,false)
		CS.ShowObject(self.mEff2,false)
		CS.ShowObject(self.mEff1,true)
		CS.ShowObject(self.mEff2,true)
	else
		self:CreateWndEffect(self.mEff1,key1,key1,100,false,false,nil,nil,nil,nil,nil,nil,0)
		self:CreateWndEffect(self.mEff2,key2,key2,100,false,false,nil,nil,nil,nil,nil,nil,4)
	end

	local win = itemdate.win
	local winCount = LUtil.FormatHurtNumSpriteText(itemdate.winCount)
	self:SetWndText(self.mWinText,winCount)

	local infoA = {
		head = itemdate.headA,
		headFrame = itemdate.headFrameA,
		playerName = itemdate.playerNameA,
	}
	local infoB = {
		head = itemdate.headB,
		headFrame = itemdate.headFrameB,
		playerName = itemdate.playerNameB,
	}

	self:SetHeadIcon(self.mRelo1,win == 1 and infoA or infoB)
	self:SetHeadIcon(self.mRelo2,win == 2 and infoA or infoB)
	self:SetTween()
end
------------------------------------------------------------------
return UIConoryPop


