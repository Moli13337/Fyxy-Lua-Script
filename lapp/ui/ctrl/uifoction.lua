---
--- Created by Administrator.
--- DateTime: 2023/10/1 19:41:07
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFoction:LWnd
local UIFoction = LxWndClass("UIFoction", LWnd)

local Tweening = DG.Tweening

UIFoction.BOX_TYPE_IMG = 1
UIFoction.BOX_TYPE_EFF = 2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFoction:UIFoction()
	self._textFormat = "%s<br>%s"
	self._boxEffKey = "_boxEffKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFoction:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFoction:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFoction:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetStaticContent()
	self:InitEvent()

	self:OnWndRefresh()
end


function UIFoction:OnClickBox(itemdata)
	if itemdata.state == 1 then
		--todo 领取奖励
		gModelFunctionOpen:OnForeRewardReq(itemdata.conf.refId)
	elseif itemdata.state == 2 then
		--todo 打开奖励预览弹窗
		local itemList = LxDataHelper.ParseItem(itemdata.conf.reward)
		local intro =ccClientText(31900) --"达成新功能解锁条件，即可获得以下奖励"
		GF.OpenWnd('UIAwardDetail',{itemList = itemList,intro = intro})
	else
		local str =ccClientText(31901) --"奖励已领取"
		GF.ShowMessage(str)
	end
end

function UIFoction:SetStaticContent()
	local str = ccClientText(10103)
	self:SetWndText(self.mCloseTip,str)

	local emptyList = self:GetCommonEmptyList("empty")
	local data =
	{
		refId = 23003,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	emptyList:RefreshUI(data)
end

function UIFoction:OnDrawItem(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootBg = self:FindWndTrans(AniRoot,"bg")
	local AniRootTextName = self:FindWndTrans(AniRoot,"textName")
	local AniRootTextBg = self:FindWndTrans(AniRoot,"textBg")
	local textBgText1 = self:FindWndTrans(AniRootTextBg,"text1")
	local textBgText2 = self:FindWndTrans(AniRootTextBg,"text2")
	local AniRootBox = self:FindWndTrans(AniRoot,"BtnBox")
	local AniRootBoxEff = self:FindWndTrans(AniRoot,"boxEff")

	local instanceId = item:GetInstanceID()
	local ref = itemdata.conf
	self:SetWndEasyImage(AniRootBg,ref.bg,nil,true)
	self:SetWndEasyImage(AniRootTextName,ref.title,nil,true)
	self:SetWndClick(AniRootBox,function ()
		self:OnClickBox(itemdata)
	end)
	self:SetWndClick(AniRootBoxEff,function ()
		self:OnClickBox(itemdata)
	end)


	local state = itemdata.state
	local effKey	 = self._boxEffKey..instanceId
	self:DestroyWndEffectByKey(effKey)
	if state == 1 then
		self:CreateWndEffect(AniRootBoxEff, "fx_richangbaoxiang", effKey,130,false,false)
	end

	CS.ShowObject(AniRootBox, state ~= 1)
	CS.ShowObject(AniRootBoxEff, state == 1)

	local helpTxt1 = gModelFunctionOpen:GetOpenTips(ref.functionOpen)--ccLngText(ref.helpTxt1)
	self:SetWndText(textBgText1,helpTxt1)
	self:SetWndText(textBgText2,ccLngText(ref.helpTxt2))

	-- local rootInstanceId = AniRootBox:GetInstanceID()
	-- local seqCom = self:GetSeqCom()
	-- seqCom:DeleteSeq(rootInstanceId)
	-- AniRootBox.localRotation = Quaternion.Euler(0,0,0)
	-- if itemdata.state == 1 and boxImgType == UIFoction.BOX_TYPE_IMG then
	-- 	local seq = seqCom:CreateSeq(rootInstanceId)

	-- 	local tween = AniRootBox:DORotate(Vector3.New(0,0,10),0.04):SetEase(Tweening.Ease.OutBounce)
	-- 	seq:Append(tween)
	-- 	tween = AniRootBox:DORotate(Vector3.New(0,0,-10),0.08):SetEase(Tweening.Ease.InOutBounce)
	-- 	seq:Append(tween)
	-- 	tween = AniRootBox:DORotate(Vector3.New(0,0,0),0.04):SetEase(Tweening.Ease.InBounce)
	-- 	seq:Append(tween)
	-- 	seq:AppendInterval(1)
	-- 	seq:SetLoops(-1)
	-- 	seq:Play()
	-- end

end

function UIFoction:InitEvent()
	self:SetWndClick(self.mMask,function () self:WndClose() end)
	self:WndEventRecv(EventNames.REFRESH_FUNCTION_STATE,function ()
		self:OnWndRefresh()
	end)

	self:WndEventRecv(EventNames.ON_FORE_FUNCTION_REWARDED,function ()
		self:OnWndRefresh()
	end)
end

function UIFoction:OnWndRefresh()
	local dataList = gModelFunctionOpen:GetSortForeList()

	local isEmpty = #dataList == 0
	CS.ShowObject(self.mNoRecord2,isEmpty)
	CS.ShowObject(self.mItemList,not isEmpty)
	if isEmpty then
		return
	end
	local list = self:CreateUIScrollImpl('itemList',self.mItemList,dataList,function (...)
		self:OnDrawItem(...)
	end,UIItemList.SUPER)
	list:MoveToPos(1)
end


------------------------------------------------------------------
return UIFoction