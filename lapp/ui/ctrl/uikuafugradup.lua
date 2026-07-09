---
--- Created by LCM.
--- DateTime: 2024/3/17 18:01:31
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIKuafuGradUp:LWnd
local UIKuafuGradUp = LxWndClass("UIKuafuGradUp", LWnd)
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)

UIKuafuGradUp.OPENTYPE_UP = 1 			--- 升段
UIKuafuGradUp.OPENTYPE_SHARE = 2 		--- 分享

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIKuafuGradUp:UIKuafuGradUp()
	self._effectKey = "_effectKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIKuafuGradUp:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIKuafuGradUp:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIKuafuGradUp:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	--self:CreateWndEffect(self.mTitleImg,"fx_ui_duanweitisheng","fx_ui_duanweitisheng",100,false,false)
	self:SetWndText(self.mCloseTip,ccClientText(10103))
	--self:SetTextTile(self.mTextTitle,ccClientText(21839))
	self:SetWndText(self.mAwardText,ccClientText(21839))
	self:InitEvent()

	self._oepnWndType = self:GetWndArg("oepnWndType") or UIKuafuGradUp.OPENTYPE_UP
	self._oepnWndType = tonumber(self._oepnWndType)
	self:RefreshShareShow()

	if self._oepnWndType == UIKuafuGradUp.OPENTYPE_UP then
		CS.ShowObject(self.mUpDiv,true)
		self:InitData()
		self:SetUI()
	elseif self._oepnWndType == UIKuafuGradUp.OPENTYPE_SHARE then
		CS.ShowObject(self.mShareDiv,true)
		self:InitShareData()
		self:SetShareUI()
	end
	self:RunAni()
end

------------------------------------------------- UIKuafuGradUp.OPENTYPE_UP -------------------------------------------------
function UIKuafuGradUp:InitData()
	self._beforeRankRefId = self:GetWndArg("beforeRankRefId")
	self._afterRankRefId = self:GetWndArg("afterRankRefId")

	self._timer = GetTimestamp()
end

function UIKuafuGradUp:InitEvent()
	self:SetWndClick(self.mMask,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mShareBtn,function() self:OnClickShare() end)
end

function UIKuafuGradUp:RefreshShareShow()
	local show = false
	if self._oepnWndType == UIKuafuGradUp.OPENTYPE_UP then
		local afterRankRefId = self:GetWndArg("afterRankRefId")
		local rankShare = gModelCrossGrading:GetConfigByKey("rankShare")
		show = afterRankRefId >= rankShare
	end
	CS.ShowObject(self.mShareBtn,show)
end

function UIKuafuGradUp:InitItemList(list)
	list = list or {}

	local uiItemList = self._uiItemList
	if uiItemList then
		uiItemList:RefreshList(list)
	else
		uiItemList = self:GetUIScroll("uiItemList")
		self._uiItemList = uiItemList
		uiItemList:Create(self.mItemList,list,function(...) self:OnDrawItemCell(...) end)
	end
end

function UIKuafuGradUp:RunAni()
	local seqTween
	self:TweenSeqKill(self._effectKey)

	local contentTrans = self.mCommonBg_5.transform
	contentTrans.localRotation = Quaternion.Euler(90,0,0)

	local rotateY = 180
	local oldTrans = self.mOldRankRoot.transform
	oldTrans.localRotation = Quaternion.Euler(0,rotateY,0)

	local newTrans = self.mNewRankRoot.transform
	newTrans.localRotation = Quaternion.Euler(0,rotateY,0)

	local shareTrans = self.mShareRankRoot.transform
	shareTrans.localRotation = Quaternion.Euler(0,rotateY,0)

	if not seqTween then
		seqTween = self:TweenSeqCreate(self._effectKey,function(seq)
			local showTopTime = 0.2
			local rotateTween = contentTrans:DORotate(Vector3.New(0,0,0),showTopTime)
			seq:Append(rotateTween)

			seq:AppendCallback(function ()
				CS.ShowObject(self.mTitleImg,true)
			end)
			seq:AppendInterval(showTopTime)

			local rotateTime = 0.2
			local alphaTime = 0.3
			local jiangeTime = 0.1
			local Ease = DG.Tweening.Ease.OutCubic

			if self._oepnWndType == UIKuafuGradUp.OPENTYPE_UP then
				local oldCanvasGroup = oldTrans:GetComponent(typeofCanvasGroup)
				if oldCanvasGroup then
					CS.ShowObject(oldTrans,true)

					local _temp = YXTween.TweenFloat(0, 1, alphaTime, function(ival)
						oldCanvasGroup.alpha = ival
					end):SetEase(Ease)

					local oldRotateTween = oldTrans:DORotate(Vector3.New(0,0,0),rotateTime)
					seq:Append(oldRotateTween)
					seq:Join(_temp)
				end

				seq:AppendCallback(function ()
					CS.ShowObject(self.mArrow,true)
				end)
				seq:AppendInterval(jiangeTime)

				local newCanvasGroup = newTrans:GetComponent(typeofCanvasGroup)
				if newCanvasGroup then
					CS.ShowObject(newTrans,true)
					local _temp = YXTween.TweenFloat(0, 1, alphaTime, function(ival)
						newCanvasGroup.alpha = ival
					end):SetEase(Ease)
					local newRotateTween = newTrans:DORotate(Vector3.New(0,0,0),rotateTime)
					seq:Append(_temp)
					seq:Join(newRotateTween)
				end
			elseif self._oepnWndType == UIKuafuGradUp.OPENTYPE_SHARE then
				local shareCanvasGroup = shareTrans:GetComponent(typeofCanvasGroup)
				if shareCanvasGroup then
					CS.ShowObject(shareTrans,true)
					local _temp = YXTween.TweenFloat(0, 1, alphaTime, function(ival)
						shareCanvasGroup.alpha = ival
					end):SetEase(Ease)
					local newRotateTween = shareTrans:DORotate(Vector3.New(0,0,0),rotateTime)
					seq:Append(_temp)
					seq:Join(newRotateTween)
				end
				seq:AppendInterval(jiangeTime)
				seq:AppendCallback(function ()
					self:SetWndText(self.mSharePlayerName,self._shareName)
					local shareTime = LUtil.FormatTimeStr(self._shareTime * 1000,"%Y-%m-%d %H:%M:%S")
					self:SetWndText(self.mSharePlayerTime,shareTime)
				end)

			end

			seq:AppendCallback(function ()
				CS.ShowObject(self.mItemListRoot,true)
			end)
			seq:AppendInterval(jiangeTime)

			return seq
		end)
	end
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(self._effectKey)
	end)
end

function UIKuafuGradUp:OnClickShare()
	local list = {
		shareRankRefId = self._afterRankRefId,
		shareName = gModelPlayer:GetPlayerName(),
		shareTime = self._timer,
	}
	local str = gModelCrossGrading:PackShareStr(list)
	printInfoNR(str)
	local data = {
		root = self.mShareBtn,
		shareType = ModelChat.CHATSHARE_24,
		shareData = str
	}
	gModelGeneral:OpenShareTip(data)
end

function UIKuafuGradUp:SetShareUI()
	local shareRankRefId = self._shareRankRefId
	if not shareRankRefId then return end
	local shareRef = gModelCrossGrading:GetCrossGradingIntervalSplitByRefId(shareRankRefId)
	if not shareRef then return end

	self:SetWndEasyImage(self.mShareRankImg,shareRef.icon,nil ,true)

	self:SetWndText(self.mShareRankName,ccLngText(shareRef.name))

	self:InitItemList(shareRef.rewardList)
end

function UIKuafuGradUp:SetUI()
	local beforeRankRefId,afterRankRefId = self._beforeRankRefId,self._afterRankRefId

	local beforeRef = gModelCrossGrading:GetCrossGradingIntervalSplitByRefId(beforeRankRefId)
	local afterRef = gModelCrossGrading:GetCrossGradingIntervalSplitByRefId(afterRankRefId)
	if beforeRef and afterRef then
		self:SetWndEasyImage(self.mOldRankImg,beforeRef.icon,nil ,true)
		self:SetWndEasyImage(self.mNewRankImg,afterRef.icon,nil ,true)

		self:SetWndText(self.mOldRankName,ccLngText(beforeRef.name))
		self:SetWndText(self.mNewRankName,ccLngText(afterRef.name))

		local rewardList = afterRef.rewardList
		self._rewardList = rewardList
		self:InitItemList(self._rewardList)
	end
end

------------------------------------------------- UIKuafuGradUp.OPENTYPE_SHARE -------------------------------------------------
function UIKuafuGradUp:InitShareData()
	local shareRankRefId = self:GetWndArg("shareRankRefId")
	self._shareRankRefId = tonumber(shareRankRefId)
	self._shareName = self:GetWndArg("shareName")
	local shareTime = self:GetWndArg("shareTime")
	self._shareTime = tonumber(shareTime)
end

function UIKuafuGradUp:OnDrawItemCell(list,item,itemdata,itempos)
	local CommonUI = self:FindWndTrans(item,"CommonUI")
	local Icon = self:FindWndTrans(CommonUI,"Icon")

	local itemType,itemId,itemNum = itemdata.itemType,itemdata.itemId,itemdata.itemNum
	local instanceId = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(Icon)
	baseClass:SetCommonReward(itemType,itemId,itemNum)
	baseClass:DoApply()

	self:SetWndClick(Icon,function()
		if itemType == LItemTypeConst.TYPE_ITEM then
			local ref = gModelItem:GetRefByRefId(itemId)
			if not ref then
				LogError("请检查配置，不存在itemId = " .. itemId)
			else
				gModelGeneral:OpenItemInfoTip(itemId,itemNum)
			end
		else
			gModelGeneral:ShowCommonItemTipWnd(itemdata)
		end
	end)
end
------------------------------------------------------------------
return UIKuafuGradUp


