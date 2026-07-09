---
--- Created by Administrator.
--- DateTime: 2024/11/14 16:47:31
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubDivineCall:LChildWnd
local UISubDivineCall = LxWndClass("UISubDivineCall", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubDivineCall:UISubDivineCall()
	self.SummonSpineKey = "divineCallSpine"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubDivineCall:OnWndClose()
	LChildWnd.OnWndClose(self)
	self:ClearTimer()
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubDivineCall:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubDivineCall:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitStatic()
	self:RefreshSummon()
end
function UISubDivineCall:InitStatic()
	self:SetTextTile(self.mBtnDetails, ccClientText(41082))
	self:SetWndText(self.mTxtSummonFree, ccClientText(41020))
	self:SetTextTile(self.mBtnWish, ccClientText(46140))
	self:SetTextTile(self.mBtnPrivilege, ccClientText(46141))
	self:SetTextTile(self.mBtnOne, ccClientText(46142))
	self:SetTextTile(self.mBtnTen, ccClientText(46143))
	local ref = gModelNormalActivity:GetBIActivityPrivilegeGiftRefByRefId(11)
	self:SetWndEasyImage(self.mBtnPrivilege,ref.iconSmall)
	self:SetWndClick(self.mBtnOne, function() self:OnClickBtnOne() end)
	self:SetWndClick(self.mBtnTen, function() self:OnClickBtnTen() end)
	self:SetWndClick(self.mBtnWish, function() self:OnClickBtnWish() end)
	self:SetWndClick(self.mBtnPrivilege, function() self:OnClickBtnPrivilege() end)
	self:SetWndClick(self.mBtnDetails, function() self:OnClickBtnSummonDetails() end)
	self:SetWndClick(self.mBtnHelp,function() GF.OpenWnd("UIBzTips",{refId = 183}) end)
	self:WndEventRecv(EventNames.On_Item_Change, function(...) self:RefreshSummon() end)
	self:WndEventRecv(EventNames.DIVINE_WEAPON_CALL,function(thingsDetail)
		if thingsDetail and thingsDetail.items[1] then
			gModelDraconic:ShowComReward(thingsDetail,{effect = "fx_sw_zh_zhaohuan_js"})
		end
		self:RefreshSummon()
	end)
	self:WndEventRecv(EventNames.DIVINE_WEAPON_CALL_RWD,function()
		self:RefreshSummonProgress()
	end)
	self:WndEventRecv(EventNames.DIVINE_WEAPON_CALL_WISH,function()
		self:RefreshWish()
	end)
	self:WndEventRecv(EventNames.DIVINE_WEAPON_UPDATE,function()
		self:RefreshWish()
	end)

	self.heroSpine = GameTable.CharacterEffectRef[GameTable.DivineWeaponConfigRef.summonShowcase].prefabName
	self:CreateWndSpine(self.mSummonSpine, self.heroSpine, self.heroSpine, false, function(dpSpine)
	end)
end

-- 获取召唤宝箱已领取的位置 Map
function UISubDivineCall:GetSummonBoxReceivedPosMap()
    local map = {}
    for k, v in pairs(gModelDivineWeapon.progressRewardIdxs) do
        map[v] = true
    end
    return map
end

-- 播放召唤动画
function UISubDivineCall:PlaySummonEff(effName,callNum)
	local instance = self.mSummonEff:GetInstanceID()
	self:DestroyWndEffectByKey(instance)
	local isEff = effName == "fx_sw_zh_zhaohuan"
	if isEff then
		self._playingSummonEff = true
		self:ClearTimer()
		self._timer = LxTimer.DelayTimeCall(function()
			gModelDivineWeapon:OnDivineWeaponDropReq(callNum)
			self._playingSummonEff = nil
			gModelGameHelper:RefreshGameSpeed()
			self:PlaySummonEff("fx_sw_zh_bg")
		end,1.5)
	end
	self:CreateWndEffect(self.mSummonEff, effName, instance, 100, false, false,nil,nil,nil,nil,nil,function(tranEff)
		if isEff then return end
		tranEff.localPosition = Vector3(0,-60,0)
	end)

	local spine = self:FindWndSpineByKey(self.heroSpine)
	if spine then
		spine:SetAnimationCompleteFunc(function(aniName)
			spine:PlayAnimation(0, "idle", true)
		end)
		spine:PlayAnimation(0, "skill1")
	end
end

-- 召唤10次
function UISubDivineCall:OnClickBtnTen()
	if self._playingSummonEff then
		return
	end

	local enough, isItem, itemRefId, needNum = self:EnoughSummonTen(true)
	if not enough then
		return
	end
	self:SendSummonMsg(isItem, 10, itemRefId, needNum)
end

-- 点击宝箱
function UISubDivineCall:OnClickBox(boxTrans, pos)
	local progress = gModelDivineWeapon.dropProgress
	local refList = self:GetSummonProgressRef()
	local needProgress = refList[pos].progress
	local map = self:GetSummonBoxReceivedPosMap()
	if needProgress <= progress and not map[pos] then
		-- 可领取
		gModelDivineWeapon:OnDivineWeaponGetProgressRewardReq(pos)
		return
	end

	local itemList = {}
	for k, v in ipairs(refList[pos].items) do
		table.insert(itemList, { itemId = v.refId, itemNum = v.count, itemType = v.type })
	end
	local on = CS.FindTrans(boxTrans, "On")
	GF.OpenWnd("UIringBoxDetail", { on, itemList })
end

-- 召唤进度
function UISubDivineCall:RefreshSummonProgress()
	local progress =  gModelDivineWeapon.dropProgress
	self:SetWndText(self.mTxtScore, progress)

	local refList = self:GetSummonProgressRef()
	if not self._uiBoxList then
		self._uiBoxList = {}
		self._sliderW = self.mSlider.sizeDelta.x
		self._sliderMax = refList[#refList].progress

		local rootObj = self.mBox.gameObject
		local parent = self.mBox.parent
		local y = self.mBox.anchoredPosition.y
		for k, v in ipairs(refList) do
			local obj = CS.InstantObject(rootObj)
			local boxTrans = obj.transform
			boxTrans:SetParent(parent, false)
			obj:SetActive(true)
			self:SetTextTile(boxTrans, v.progress)
			boxTrans.anchoredPosition = Vector2(v.progress / self._sliderMax * self._sliderW - 30, y)
			self._uiBoxList[k] = boxTrans

			self:SetWndClick(boxTrans, function() self:OnClickBox(boxTrans, k) end)
		end
		CS.ShowObject(self.mBox,false)
	end

	progress = math.min(progress, self._sliderMax)
	local size = self.mSlider.sizeDelta
	self.mSlider.sizeDelta = Vector2(progress / self._sliderMax * self._sliderW, size.y)

	local map = self:GetSummonBoxReceivedPosMap()
	for pos, trans in ipairs(self._uiBoxList) do
		local needProgress = refList[pos].progress

		local state
		local showRed = false
		if needProgress > progress then
			-- 不可领取
			state = LWnd.StateOff
		else
			if map[pos] then
				-- 已领取
				state = LWnd.StateOn
			else
				-- 可领取
				state = LWnd.StateOff
				showRed = true
			end
		end

		self:SetWndTabStatus(trans, state)
		self:SetRed(trans, showRed)
	end
end

-- 刷新许愿
function UISubDivineCall:RefreshWish()
	local wishDraconicId = gModelDivineWeapon.wishWeaponId
	local had = wishDraconicId ~= 0
	if had then
		local ref = GameTable.DivineWeaponSummonRef[wishDraconicId]
		local item = LUtil.GetRefItemData(ref.reward)
		local iconPath = GameTable.PlayerItemRef[item.refId].icon
		self:SetWndEasyImage(self.mItemIcon, iconPath)
	end

	CS.ShowObject(self.mAdd, not had)
	CS.ShowObject(self.mItemIcon, had)

	local canWish = gModelDivineWeapon.isCanWish

	self:SetRed(self.mBtnWish, not had and canWish)

	CS.ShowObject(self.mBtnWish, canWish)
	CS.ShowObject(self.mBtnPrivilege, not canWish)
end

-- 点击召唤详情
function UISubDivineCall:OnClickBtnSummonDetails()
	local list = gModelDivineWeapon:GetSummonDetail()
	GF.OpenWnd("UIDraconicSummonRule",{rwdList = list})
end

-- 发送召唤
function UISubDivineCall:SendSummonMsg(isItem, times, refId, itemNum)
	local item = LUtil.GetRefItemData(GameTable.DivineWeaponConfigRef.rewardFix)
	local needItemName = gModelItem:GetNameByRefId(refId)
	local itemName = gModelItem:GetNameByRefId(item.refId) or ""
	local wndId = 480001
	if isItem then
		wndId = 480002
	end

	local para =
	{
		refId = wndId,
		para = { itemNum .. needItemName, times .. itemName, times },
		func = function()
			self:PlaySummonEff("fx_sw_zh_zhaohuan",times==10 and 2 or 1)
			gModelGameHelper:TemporaryCloseSpeed()
			LxUiHelper.PlayAudioSoundName(29)
		end,
	}

	gModelGeneral:OpenUIOrdinTips(para)
end

-- 召唤成功返回
function UISubDivineCall:OnDropReturn(func)
	self._summonSuccessedFunc = func
end
-- region 召唤 --------------------------------------------------
function UISubDivineCall:RefreshSummon()
	local leftFreeTimes = gModelDivineWeapon.freeDropNum

	local leftDiamond = gModelDivineWeapon.diamondDropNum
	self:SetWndText(self.mTxtSummonTips1, string.replace(ccClientText(46144), leftDiamond))

	self:SetRed(self.mBtnOne, leftFreeTimes > 0)
	self:ShowBtnEff(self.mBtnOneEff, "mBtnOne", leftFreeTimes > 0, "fx_ui_putongzhaohuan_04")

	-- 按钮
	CS.ShowObject(self.mSummonCostValue1, leftFreeTimes <= 0)
	CS.ShowObject(self.mTxtSummonFree, leftFreeTimes > 0)
	local constList = self:GetSummonCost()
	for k, v in ipairs({ "one", "ten" }) do
		local refId = constList[1][v].refId
		local haveNum = gModelItem:GetNumByRefId(refId)
		local needNum = constList[1][v].count
		if haveNum < needNum then
			refId = constList[2][v].refId
			haveNum = gModelItem:GetNumByRefId(refId)
			needNum = constList[2][v].count
		end
		local color = "68e6ac"
		if haveNum < needNum then
			color = "c81212"
		end


		needNum = string.replace(ccClientText(41021), color, needNum)
		self:SetWndText(self["mSummonCostValue" .. k], needNum)

		local iconPath = gModelItem:GetItemImgByRefId(refId)
		self:SetWndEasyImage(self["mSummonCostIcon" .. k], iconPath)
	end

	local tenRed, isItem = self:EnoughSummonTen()
	self:SetRed(self.mBtnTen, tenRed and isItem)
	self:ShowBtnEff(self.mBtnTenEff, "mBtnTen", tenRed, "fx_ui_putongzhaohuan_05")

	self:RefreshSummonProgress()
	self:RefreshTopAsset()
	self:RefreshWish()
	self:PlaySummonEff("fx_sw_zh_bg")
end

function UISubDivineCall:ClearTimer()
    local timer = self._timer
    if timer then
        LxTimer.DelayTimeStop(timer)
        self._timer = nil
    end
end

-- 获取召唤进度配置
function UISubDivineCall:GetSummonProgressRef()
    if not self._summonProgressRef then
        local str = GameTable.DivineWeaponConfigRef.rewardAdd
        local tab = string.split(str, ";")
        local list = {}
        for k, v in ipairs(tab) do
            local datas = string.split(v, "|")
            table.insert(list, {
                progress = tonumber(datas[1]),
                items = { LUtil.GetRefItemData(datas[2]) }
            })
        end

        self._summonProgressRef = list
    end

    return self._summonProgressRef
end

-- 顶部资产
function UISubDivineCall:RefreshTopAsset()
	local assetIdList = GameTable.DivineWeaponConfigRef.showItem

	self:SetTopAssetList(self.mTopAsset, assetIdList)
end
-- true: 满足召唤10次
function UISubDivineCall:EnoughSummonTen(showTips)
    local leftDiamond = gModelDivineWeapon.diamondDropNum
    local constList = self:GetSummonCost()
    local refId = constList[1].ten.refId
    local haveNum = gModelItem:GetNumByRefId(refId)
    local needNum = constList[1].ten.count
    local isItem = true
    if haveNum < needNum then
        refId = constList[2].ten.refId
        haveNum = gModelItem:GetNumByRefId(refId)
        needNum = constList[2].ten.count
        isItem = false

        if leftDiamond < 10 then
            if showTips then
                GF.ShowMessage(ccClientText(46145))
            end
            return false
        end
    end

    if haveNum < needNum then
        if showTips then
            gModelGeneral:OpenGetWayWnd({ itemId = refId })
        end
        return false
    end
    return true, isItem, refId, needNum
end
-- 获取召唤消耗
function UISubDivineCall:GetSummonCost()
    if not self._summonCostRef then
        self._summonCostRef = {}
        self._summonCostRef[1] = {}
        self._summonCostRef[1].one = LUtil.GetRefItemData(GameTable.DivineWeaponConfigRef.callUseItem)
        self._summonCostRef[1].ten = LUtil.GetRefItemData(GameTable.DivineWeaponConfigRef.callUseItemMore)

        self._summonCostRef[2] = {}
        self._summonCostRef[2].one = LUtil.GetRefItemData(GameTable.DivineWeaponConfigRef.callUseDiamond)
        self._summonCostRef[2].ten = LUtil.GetRefItemData(GameTable.DivineWeaponConfigRef.callUseDiamondMore)
    end

    return self._summonCostRef
end

-- 召唤1次
function UISubDivineCall:OnClickBtnOne()
	if self._playingSummonEff then
		return
	end

	local leftFreeTimes = gModelDivineWeapon.freeDropNum
	local leftDiamond = gModelDivineWeapon.diamondDropNum
	if leftFreeTimes <= 0 then
		local constList = self:GetSummonCost()
		local refId = constList[1].one.refId
		local haveNum = gModelItem:GetNumByRefId(refId)
		local needNum = constList[1].one.count
		local isItem = true
		if haveNum < needNum then
			refId = constList[2].one.refId
			haveNum = gModelItem:GetNumByRefId(refId)
			needNum = constList[2].one.count
			isItem = false
			if leftDiamond <= 0 then
				GF.ShowMessage(ccClientText(46145))
				return
			end
		end

		if haveNum < needNum then
			gModelGeneral:OpenGetWayWnd({ itemId = refId })
			return
		end
		self:SendSummonMsg(isItem, 1, refId, needNum)
		return
	end
	-- gModelDivineWeapon:OnDivineWeaponDropReq(1)
	self:PlaySummonEff("fx_sw_zh_zhaohuan",1)
	gModelGameHelper:TemporaryCloseSpeed()
	LxUiHelper.PlayAudioSoundName(29)
end

-- 点击特权
function UISubDivineCall:OnClickBtnPrivilege()
	if not gModelFunctionOpen:CheckIsOpened(10401162, true) then
		return
	end
	GF.OpenWnd("UIWishPrigeBuyPop", {
		extra = 11,
		callfunc = function()
			gModelDivineWeapon:OnDivineWeaponInfoReq()
		end
	})
end

-- 点击许愿
function UISubDivineCall:OnClickBtnWish()
	GF.OpenWnd("UIDivineSummonPool")
end

------------------------------------------------------------------
return UISubDivineCall