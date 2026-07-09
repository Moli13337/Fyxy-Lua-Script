---
--- Created by wzz.
--- DateTime: 2024/7/9 22:22:35
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFishTips:LWnd
local UIFishTips = LxWndClass("UIFishTips", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFishTips:UIFishTips()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFishTips:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFishTips:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFishTips:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsForeignVersion()
	
	local refId = self:GetWndArg("refId")
	self._isTips = not not self:GetWndArg("isTips")
	self._ref = gModelFish:GetFishRef(refId)

	self:InitTexts()
	self:InitEvents()
	self:Refresh()
end

-- 刷新界面
function UIFishTips:Refresh()
	local ref = self._ref

	self:SetWndText(self.mNameTxt, ccLngText(ref.name))
	local color = gModelItem:GetColorByQualityId(ref.quality)
	self:SetXUITextColor(self.mNameTxt, color)
	local heroMessage = gModelItem:GetHeroMessQualityById(ref.quality)
	self:SetWndEasyImage(self.mHeadImg, heroMessage)
	self:SetWndText(self.mTxtDesc, ccLngText(ref.desc))
	self:SetWndEasyImage(self.mItemIcon, ref.icon, nil, false)

	local showWeight = gModelFish:InFishTankTypeList(ref.refId)
	if showWeight then
		local weight = gModelFish:GetFishWeightMax(ref.refId)
		local strWeight
		if weight == 0 then
			strWeight = ccClientText(44291)
		else
			strWeight = gModelFish:WeightToString(weight)
		end
		self:SetWndText(self.mTxtKg, strWeight)
	end
	CS.ShowObject(self.mTxtKg.parent, showWeight)
	CS.ShowObject(self.mTxtTips3.parent, showWeight)

	local strGet = ""
	for k, v in ipairs(string.split(ref.get, ",") or {}) do
		local fishRef = gModelFish:GetRef(tonumber(v))
		if k > 1 then
			strGet = strGet .. "、"
		end
		strGet = strGet .. ccLngText(fishRef.name)
	end
	self:SetWndText(self.mTxtGet, strGet)

	-- 收藏属性
	local list = gModelFish:GetFishCollectAttr(ref.refId)
	self:SetComList(self.mAttrList, list, function(...) return self:OnDrawCollectAttr(...) end)
	CS.ShowObject(self.mTxtTips2.parent, #list > 0)

	-- 奖励
	if not self._isTips then
		local hadGet = gModelFish:HadFishCollectAttrReward(ref.refId)
		local canGet = gModelFish:CanFishCollectAttrReward(ref.refId)
		CS.ShowObject(self.mCanGet, canGet)
		CS.ShowObject(self.mHadGet, hadGet)

		local itemData = LUtil.GetRefItemData(ref.reward)
		self:CreateCommonIconImpl(self.mActiveItemRoot, itemData, {
			clickFunc = function()
				if canGet then
					-- 发送领取
					gModelFish:FishHandBookActiveReq(2, ref.refId)
				else
					gModelGeneral:ShowCommonItemTipWnd(itemData)
				end
			end
		})
	end
	CS.ShowObject(self.mActiveAward, not self._isTips)

end

-- 绘制收藏属性
function UIFishTips:OnDrawCollectAttr(uiList, root, data, index)
	if not uiList then
		uiList           = {}
		uiList.icon      = CS.FindTrans(root, "icon")
		uiList.name      = CS.FindTrans(root, "name")
		uiList.value     = CS.FindTrans(root, "name/value")
		uiList.times     = CS.FindTrans(root, "times")
		uiList.hadActive = CS.FindTrans(root, "hadActive")
		uiList.btnActive = CS.FindTrans(root, "btnActive")
		self:SetWndButtonText(uiList.btnActive, ccClientText(44217))

		----默认的多语言图片替换不生效
		--if self._isEnus then
		--	self:SetWndEasyImage(uiList.hadActive,"public_txt_1_1_enus",nil,true)
		--end
		--
		--if gLGameLanguage:IsJapanVersion() then
		--	self:SetWndEasyImage(uiList.hadActive,"public_txt_1_1_ja",nil,true)
		--end
		self:SetWndEasyImage(uiList.hadActive,"public_txt_1_1",nil,true)
	end

	if not self._isTips then
		local hadActive = gModelFish:HadFishCollectAttrActive(self._ref.refId, index)
		local canActive = gModelFish:CanFishCollectAttrActive(self._ref.refId, index)

		if canActive and index > 1 then
			canActive = gModelFish:HadFishCollectAttrActive(self._ref.refId, index - 1)
		end

		CS.ShowObject(uiList.hadActive, hadActive)
		CS.ShowObject(uiList.btnActive, canActive)
		self:ShowBtnEff(uiList.btnActive, uiList.btnActive:GetInstanceID(), canActive, "fx_anniu_02")

		if canActive then
			self:SetWndClick(uiList.btnActive, function()
				self:OnClickBtnActive(index)
			end)
		end

		local numMax = data.num
		local numCur = gModelFish:GetFishTimes(self._ref.refId)
		self:SetWndText(uiList.times, ccClientText(44228, numCur, numMax))
	end

	-- 属性
	local attrData = data.attr
	local numType, refId, value = attrData.type, attrData.refId, attrData.value

	local icon = gModelHero:GetAttributeIconById(refId)
	self:SetWndEasyImage(uiList.icon, icon)

	local name = gModelHero:GetAttributeNameById(refId)
	self:SetWndText(uiList.name, name .. "：")

	value = gModelFish:CheckAttrValue(refId,numType,  value)
	local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId, numType, value)
	self:SetWndText(uiList.value, valueStr)

	return uiList
end

-- 初始事件
function UIFishTips:InitEvents()
	self:SetWndClick(self.mBg, function() self:WndClose() end)

	self:WndEventRecv(EventNames.FISH_BASE_INFO, function(...) self:Refresh(...) end)
end

-- 初始界面化文本
function UIFishTips:InitTexts()
	self:SetWndText(self.mTxtTips1, ccClientText(44224))
	self:SetWndText(self.mTxtTips2, ccClientText(44225))
	self:SetWndText(self.mTxtTips3, ccClientText(44226))
	self:SetWndText(self.mTxtTips4, ccClientText(44227))
	self:SetTextTile(self.mActiveAward, ccClientText(44223))
end

-- 点击激活按钮
function UIFishTips:OnClickBtnActive(index)
	local ref = self._ref

	gModelFish:FishHandBookActiveReq(0, ref.refId)
end

------------------------------------------------------------------
return UIFishTips