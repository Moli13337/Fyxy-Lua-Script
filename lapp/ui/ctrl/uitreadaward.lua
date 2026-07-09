---
--- Created by Administrator.
--- DateTime: 2023/10/15 11:18:01
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UITreadAward:LWnd
local UITreadAward = LxWndClass("UITreadAward", LWnd)
local typeofAnimator = typeof(UnityEngine.Animator)
local Tweening = DG.Tweening
local EaseOutQuad = Tweening.Ease.OutQuad

UITreadAward.FINDTREA_STATUS = 1			--- 新版
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UITreadAward:UITreadAward()
	---@type table<number, CommonIcon>
	self._commonIconTbl = {}


	self._planeSpineKey = "_planeSpineKey"


end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UITreadAward:OnWndClose()
	self:ClearCommonIconList(self._commonIconTbl)
	self._commonIconTbl = nil
	if self._seqCom then
		self._seqCom:Destroy()
		self._seqCom = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UITreadAward:OnCreate()
	LWnd.OnCreate(self)

	self._seqCom = SequenceCom:New()
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UITreadAward:OnStart()
	LWnd.OnStart(self)
	self:InitUI()


	self:InitData()
	self:SetStaticContent()
	self:InitUIEvent()
	self:InitMsg()

	self._planeEffect = "_planeEffect"


	self:OnWndRefresh()
end

function UITreadAward:SetStaticContent()
	local str =ccClientText(19402) -- "确定"
	self:SetWndButtonText(self.mOk,str)
end

function UITreadAward:StartAniNew()
	CS.ShowObject(self.mUpper,false)
	local isOpen = gModelTreaFind:GetTreaHotOpen()

	local showBg = isOpen and "treasure1_bg_big_4" or "treasure1_bg_big_3"
	self:SetWndEasyImage(self.mMask,showBg)

	local idleName = isOpen and "huang" or "lan"
	local spine = self:FindWndSpineByKey(self._planeSpineKey)
	if spine then
		self:ShowItemTween()
		spine:PlayAnimationSolid(idleName,false)
		spine:OnAniamationComplete(function()
			self:ShowSkipTween()
		end)
	end
	CS.ShowObject(self.mPlaneEff,true)
end

function UITreadAward:OnClickMask()
	if not self._isFirstEnd then
		self:ShowSkipTween()
		return
	end

end

function UITreadAward:RefreshUI()
	local data = self._data
	local type = data.type

	self:ShowRewardIntro()

	CS.ShowObject(self.mContentMul,type == 2)
	CS.ShowObject(self.mContentOne,type ==1)
	CS.ShowObject(self.mEffectMul,type == 2)
	CS.ShowObject(self.mEffectOne,type ==1)
	local  root = type == 1 and self.mContentOne or self.mContentMul
	self:ShowItemList(root)
	self:ShowBuyItem()
	local effectName = "fx_ui_gongxihuode"
	self:CreateWndEffect(self.mTitle,effectName,effectName,100)

	local isShow = not (gLGameLanguage:IsUSARegion() or gLGameLanguage:IsKoreaRegion())
	CS.ShowObject(self.mDescTxt, isShow)
	if isShow then
		local str =ccClientText(19415) -- "<#d2730f>橙色</color>宝物最多还需要<#feeba7>%s</color>次"
		local para = gModelTreaFind:GetPara("objectForeshow1")
		local leftTimes = gModelTreaFind:GetLeftTimes({para})
		local showStr = string.replace(str,leftTimes)
		self:SetWndText(self.mDropIntro,showStr)
	end

	local effect = "fx_xunbao_jiesuanbeijing"
	self:CreateWndEffect(self.mBgEffect,effect,effect,100)
end

function UITreadAward:ShowRewardIntro()
	local rewardList = self._data.rewardFix
	if #rewardList==0 then
		return
	end
	local reward = rewardList[1]
	local itemdata =
	{
		itemId = reward.itemId,
		itemNum = reward.count,
		itemType = reward.type,
	}

	local itemName = gModelGeneral:GetCommonItemName(itemdata)
	local str =ccClientText(19410) -- "成功购买道具X%s,赠送:%sX%s"
	local showStr = string.replace(str,itemName,itemdata.itemNum)
	self:SetWndText(self.mRewardIntro,showStr)
end

function UITreadAward:ShowSkipTween()
	gLGameAudio:StopSound()

	local isNew = self:GetIsNewStatus()
	if not isNew then
		self:DestroyWndEffectByKey(self._planeEffect)
	else
		CS.ShowObject(self.mPlaneEff,false)
	end

	local seq = self._seqCom:CreateSeq("showAni")
	seq:AppendCallback(function ()
		CS.ShowObject(self.mUpper,true)
		self._isFirstEnd = true
	end)

	local isFirst = true
	for k,v in ipairs(self._itemList) do
		v.itemEff.localScale = Vector3.zero
		CS.ShowObject(v.itemEff,true)
		CS.ShowObject(v.item,false)
		local tween = v.itemEff:DOScale(Vector3.New(1,1,1),0.5):SetEase(EaseOutQuad)
		if isFirst then
			seq:Append(tween)
		else
			seq:Join(tween)
		end

		isFirst = false
	end

	seq:AppendCallback(function ()
		local effect = "fx_xunbao_wupinshangguang"
		for k,v in ipairs(self._itemList) do
			self:CreateWndEffect(v.item,effect,effect..k,100)
			CS.ShowObject(v.item,true)
		end
		gLGameAudio:PlaySound("SoundS_19")
	end)



	seq:OnComplete(function ()
		self._isTweenEnd = true
	end)
	seq:PlayForward()
end

function UITreadAward:ShowItem(item,itemdata,index)
	local spine = self:FindWndTrans(item,"spine")
	local icon = self:FindWndTrans(item,"icon")
	local iconItem = self:FindWndTrans(icon,"item")
	local itemImage = self:FindWndTrans(iconItem,"Image")
	local itemNum = self:FindWndTrans(iconItem,"num")


	local treaId = gModelTreaFind:GetTreaIdByItemId(itemdata.itemId)
	local effect = nil
	local isSpine = false
	if treaId>0 then
		isSpine = true
		--local objRef = gModelTreasure:GetTreasureObjectRefByRefId(treaId)
		--local type = objRef.type
		--local treaRef = gModelTreasure:GetTreasureRefByRefId(type)
		--iconBgPath = treaRef.iconBgDrop
		--effect = treaRef.iconBgEffect
		--local spineName = objRef.spine
		--local aniname = objRef.idle
		local key = "spine_"..index
		--if not string.isempty(spineName) then
		--	self:CreateWndSpine(spine,spineName,key,false,function (spine)
		--		local scale = gModelTreaFind:GetPara("objectScaleOther")
		--
		--		spine:SetScale(scale)
		--		if not string.isempty(aniname) then
		--			spine:PlayAnimationSolid(aniname)
		--		end
		--	end)
		--end
		self:SetIconClickScale(spine,true)

		self:SetWndClick(spine,function()
			gModelGeneral:ShowCommonItemTipWnd(itemdata)
		end)
	else
		effect = "fx_xunbao_baise"
		local itemCfg = gModelGeneral:GetCommonItemShowInfo(itemdata)
		self:SetWndEasyImage(itemImage,itemCfg.icon)
		self:SetWndText(itemNum,"X"..itemdata.itemNum)

		local hotItemData,hotEff = self._hotItemdata,self._hotItemEff
		if hotItemData and hotEff and hotItemData.itemId == itemdata.itemId then
			effect = hotEff
		end

		self:SetIconClickScale(icon,true)
		self:SetWndClick(icon,function()
			gModelGeneral:ShowCommonItemTipWnd(itemdata)
		end)

	end
	CS.ShowObject(spine,isSpine)
	CS.ShowObject(icon,not isSpine)
	local root = self._data.type == 1 and self.mEffectOne or self.mEffectMul
	local effectRoot = self:FindWndTrans(root,"item_"..index)
	local key = "effect"..index
	self:DestroyWndEffectByKey(key)
	self:CreateWndEffect(effectRoot,effect,key,80)

	self._itemList[index] ={item= item,itemEff = effectRoot}

end

function UITreadAward:InitData()
	local hotItemData,hotEff = gModelActivity:GetTreasureHotItem()
	self._hotItemdata = hotItemData
	self._hotItemEff = hotEff
end
function UITreadAward:FormatTween(item)
	item.transform.localScale = Vector3.zero
	local tween = item.transform:DOScale(Vector3.one,0.1)
	return tween
end

function UITreadAward:SetWndData()
	local data = self:GetWndArg("data")
	self._data = data
end

function UITreadAward:ShowItemTween()

	local isNew = self:GetIsNewStatus()
	if not isNew then
		local effect = self:FindWndEffectByKey(self._planeEffect)
		local dpTrans = effect:GetDisplayTrans()
		local animator = dpTrans:GetComponent(typeofAnimator)
		animator.enabled = true
	end


	gLGameAudio:PlaySound("SoundS_42")

	local seq = self._seqCom:CreateSeq("showAni")
	CS.ShowObject(self.mUpper,false)
	seq:AppendInterval(2.6)
	seq:AppendCallback(function ()
		CS.ShowObject(self.mUpper,true)
		self._isFirstEnd = true
	end)
	seq:AppendInterval(0.5)

	local isFirst = true
	for k,v in ipairs(self._itemList) do
		v.itemEff.localScale = Vector3.zero
		CS.ShowObject(v.itemEff,true)
		CS.ShowObject(v.item,false)
		local tween = v.itemEff:DOScale(Vector3.New(1,1,1),0.5):SetEase(EaseOutQuad)
		if isFirst then
			seq:Append(tween)
		else
			seq:Join(tween)
		end

		isFirst = false
	end

	seq:AppendCallback(function ()
		local effect = "fx_xunbao_wupinshangguang"
		for k,v in ipairs(self._itemList) do
			self:CreateWndEffect(v.item,effect,effect..k,100)
			CS.ShowObject(v.item,true)
		end
		gLGameAudio:PlaySound("SoundS_19")
	end)

	seq:OnComplete(function ()
		self._isTweenEnd = true
	end)
	seq:PlayForward()

end

function UITreadAward:InitUIEvent()
	self:SetWndClick(self.mMask,function () self:OnClickMask() end )
	self:SetWndClick(self.mOk,function () self:WndClose() end)
	self:SetWndClick(self.mContinue,function () self:OnClickBuy() end)
end

function UITreadAward:StartAni()

	self:DestroyWndEffectByKey(self._planeEffect)

	local effect = "fx_xunbao_zhuanpan"
	local data =
	{
		trans = self.mPlaneEff,
		effName = effect,
		effKey = self._planeEffect,
		endFunc = function() self:ShowItemTween()  end,
	}
	self:CreateWndEffect_Ex(data)


end

function UITreadAward:InitMsg()
	self:WndEventRecv(EventNames.On_Item_Change,function()
		self:ShowBuyItem()
	end)
end

function UITreadAward:GetIsNewStatus()
	return UITreadAward.FINDTREA_STATUS == 1
end

function UITreadAward:OnClickBuy()

	local type = self._data.type
	gModelTreaFind:SendFindReq(type,self:GetWndName())

	--if type == 1 then
	--	local freeCnt = gModelTreaFind:GetFreeFindCnt()
	--	if freeCnt>0 then
	--		gModelTreaFind:OnFindTreasureReq(type)
	--		return
	--	end
	--end
    --
    --
	--local cost = gModelTreaFind:GetFindCost(type)
	--local itemId = cost.itemId
	--local own = gModelItem:GetNumByRefId(itemId)
	--if own>=cost.itemNum then
	--	gModelTreaFind:ShowItemCostTipWnd(type)
	--	return
	--end
    --
	--local diaCost = gModelTreaFind:GetFindDiaCost(type)
	--own = gModelItem:GetNumByRefId(diaCost.itemId)
	--if own >= diaCost.itemNum then
	--	gModelTreaFind:ShowDiaTipWnd(type)
	--	return
	--end
    --
	--gModelGeneral:OpenGetWayWnd({itemId = diaCost.itemId,srcWnd = self:GetWndName()})

	--GF.OpenWnd("UITreadBuy")

end

function UITreadAward:OnWndRefresh()
	self._itemList = {}
	self._isFirstEnd = false
	self._isTweenEnd = false
	self:SetWndData()
	self:RefreshUI()
	local spine = self:FindWndSpineByKey(self._planeSpineKey)
	if spine then
		local isNew = self:GetIsNewStatus()
		if isNew then
			local curPos = self.mPlaneEff.localPosition
			self.mPlaneEff.localPosition = Vector3(curPos.x,135,curPos.z)
			self:StartAniNew()
		else
			CS.ShowObject(self.mPlaneEff,true)
			self:StartAni()
		end
	else
		self:CreateWndSpine(self.mPlaneEff,"Lingwuzhaohuan",self._planeSpineKey,false,function()
			local isNew = self:GetIsNewStatus()
			if isNew then
				local curPos = self.mPlaneEff.localPosition
				self.mPlaneEff.localPosition = Vector3(curPos.x,135,curPos.z)
				self:StartAniNew()
			else
				CS.ShowObject(self.mPlaneEff,true)
				self:StartAni()
			end
		end)
	end
end

function UITreadAward:ShowItemList(root)
	local itemList = {}
	for k,v in ipairs(self._data.rewardRand) do
		local item =
		{
			itemId= v.itemId,
			itemType = v.type,
			itemNum = v.count,
		}
		table.insert(itemList,item)
	end
	for k,v in ipairs(itemList) do
		local key = "spine_"..k
		self:DestroyWndSpineByKey(key)
		local item = self:FindWndTrans(root,"item_"..k)
		if item then
			self:ShowItem(item,v,k)
		end
	end
end

function UITreadAward:ShowBuyItem()
	local type = self._data.type
	local freeCnt = gModelTreaFind:GetFreeFindCnt()
	local isFree  = false
	local str
	if type ==1 and freeCnt> 0 then
		str = ccClientText(19426)
		isFree = true
	else
		local findCost = gModelTreaFind:GetFindCost(type)
		local itemId = findCost.itemId
		local itemNum = findCost.itemNum

		local own = gModelItem:GetNumByRefId(itemId)
		local color = "lightGreen"
		if own<itemNum then
			local diaCost = gModelTreaFind:GetFindDiaCost(type)
			itemId = diaCost.itemId
			itemNum = diaCost.itemNum
			own = gModelItem:GetNumByRefId(itemId)
			if own < itemNum then
				color = "red"
			end
		end

		local iconPath = gModelItem:GetItemImgByRefId(itemId)
		self:SetWndEasyImage(self.mIcon,iconPath)

		str = string.format("%s/%s",own,itemNum)
		str = LUtil.FormatColorStr(str,color)
		self:SetWndText(self.mNum,str)
		str =ccClientText(19429) -- "寻宝%s次"
		if type ==2 then
			str = ccClientText(19430)
		end
	end

	CS.ShowObject(self.mIcon, not isFree)
	CS.ShowObject(self.mNum, not isFree)
	self:SetWndButtonText(self.mContinue,str)
end




------------------------------------------------------------------
return UITreadAward


