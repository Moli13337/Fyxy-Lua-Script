---
--- Created by Administrator.
--- DateTime: 2023/10/20 16:18:05
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPermanentPrigeWin:LWnd
local UIPermanentPrigeWin = LxWndClass("UIPermanentPrigeWin", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPermanentPrigeWin:UIPermanentPrigeWin()
	self._uiListTbl = {}
	self._uiCommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPermanentPrigeWin:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPermanentPrigeWin:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPermanentPrigeWin:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitData()
	self:InitList()
	self:InitView()
	self:InitMessage()
end

function UIPermanentPrigeWin:InitList()
	local rewardList = self._rewardList
	if(self._uiRewardList) then
		self._uiRewardList:RefreshList(rewardList)
	else
		self._uiRewardList = self:GetUIScroll("_uiRewardList")
		self._uiRewardList:Create(self.mRewardScroll,rewardList,function (...) self:ListItem(...) end,UIItemList.WRAP)
		self._uiRewardList:EnableScroll(false,false)
	end
end

function UIPermanentPrigeWin:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mBuyBtn, function ()
		gModelNormalActivity:BuyPrivi(self._giftData.ref.refId)
	end)
end

function UIPermanentPrigeWin:OnDrawRewardItem(list, item, itemdata, itempos)
	local itemBg=CS.FindTrans(item,"ItemBg")
	local icon=CS.FindTrans(item,"Icon")
	local itemNum=CS.FindTrans(icon,"ItemNum")
	local eff = CS.FindTrans(item, "Eff")
	local eff2 = CS.FindTrans(item, "Eff2")

	local iconType = itemdata.iconType
	local iconIndex = 1
	if iconType == 0 then
		iconIndex = 2
	end
	self:SetWndEasyImage(itemBg, "privilege1_star_"..iconIndex)
	CS.ShowObject(itemBg, false)

	local effName1 = "fx_ui_zhongshentequan_"..iconIndex.."_down"
	local instanceId = eff:GetInstanceID()
	self:DestroyWndEffectByKey(instanceId)
	self:CreateWndEffect(eff, effName1, instanceId, 80, false)
	local effName2 = "fx_ui_zhongshentequan_"..iconIndex
	local instanceId2 = eff2:GetInstanceID()
	self:DestroyWndEffectByKey(instanceId2)
	self:CreateWndEffect(eff2, effName2, instanceId2, 80, false)

	local reward = string.split(itemdata.reward, "=")
	--local itemIcon =
	self:SetWndText(itemNum, "X"..reward[3])
	local rewardType = tonumber(reward[1])
	local iconPath = ""
	if rewardType == LItemTypeConst.TYPE_ITEM then --道具
		iconPath = gModelItem:GetItemImgByRefId(tonumber(reward[2]))
	elseif rewardType == LItemTypeConst.TYPE_HERO then --英雄
		iconPath = gModelHero:GetHeroImgByRefId(tonumber(reward[2]))
	elseif rewardType == LItemTypeConst.TYPE_EQUIP then--装备
		iconPath = gModelEquip:GetEquipImgByRefId(tonumber(reward[2]))
	elseif rewardType == LItemTypeConst.TYPE_RUNE then--符文
		iconPath = gModelRune:GetRuneImgByRefId(tonumber(reward[2]))
	end

	self:SetWndEasyImage(icon, iconPath)


	local rewardData = {
		itemId = tonumber(reward[2]),
		itemType = tonumber(reward[1]),
		count = tonumber(reward[3])
	}
	self:SetWndClick(icon,function()
		gModelGeneral:ShowCommonItemTipWnd(rewardData)
	end)


end

function UIPermanentPrigeWin:InitView()
	self:CreateWndSpine(self.mBgSpine, "fx_zhongshentequan", "fx_zhongshentequan", false, function (spine)
		self._bgSpine = spine
	end)

	self:SetWndText(self.mTextTip, ccClientText(14221))
	self:SetWndText(self.mTextTip1, ccClientText(14222))
	self:SetWndText(self.mCloseInfo, ccClientText(10103))
	local ref = gModelNormalActivity:GetBIActivityPrivilegeGiftRefByRefId(4);
	local infos = gModelNormalActivity:GetPrivilegeGiftList()
	local giftData
	for i, v in ipairs(infos) do
		local ref = gModelNormalActivity:GetBIActivityPrivilegeDataRefByRefId(v.refId)
		if ref and ref.type == 4 then
			giftData = {ref = ref,info = v}
		end
	end
	self._giftData = giftData

	local expend = giftData.ref.expend
	local expendId = tonumber(expend)
	local setTextStr = gModelPay:GetShowByWelfareId(expendId)
	--self:SetWndButtonText(self.mBuyBtn, ccLngText(giftData.ref.btnText))
	self:SetWndButtonText(self.mBuyBtn, setTextStr)

	self:SetBtnStatus()
end

function UIPermanentPrigeWin:InitItemList(root, rewards, iconType)

	local key = root:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if not uiList then
		uiList = self:GetUIScroll(key)
		local listType = UIItemList.NORMAL
		uiList:Create(root,rewards,function(...) self:OnDrawRewardItem(...) end,listType)
		if listType then
			uiList:EnableScroll(false,true)
		end
	else
		uiList:RefreshList(rewards)
	end
	--local euiList= uiList:GetList()
	--euiList:RefreshList(UIListWrap.RefreshMode.Solid)
end

function UIPermanentPrigeWin:ListItem(list,item, itemdata, itempos)
	local typeImg=CS.FindTrans(item,"TypeImg")
	local nameBg=CS.FindTrans(item,"NameBg")
	local rewardList=CS.FindTrans(item,"RewardList")
	local rewardList1=CS.FindTrans(item,"RewardList1")


	local iconType = itemdata.iconType
	local rewards = itemdata.rewards

	local length = #rewards
	CS.ShowObject(rewardList, length <= 2)
	CS.ShowObject(rewardList1, length > 2)
	local tempRewardList = rewardList
	if length > 2 then
		tempRewardList = rewardList1
	end
	if rewards then
		self:InitItemList(tempRewardList,rewards, iconType)
	end
	if iconType == 0 then
		self:SetWndEasyImage(typeImg, "privilege1_bg_1")
		self:SetWndEasyImage(nameBg, "privilege1_txt_2")
	else
		self:SetWndEasyImage(typeImg, "privilege1_bg_2")
		if iconType == 1 then
			self:SetWndEasyImage(nameBg, "privilege1_txt_3")
		else
			self:SetWndEasyImage(nameBg, "privilege1_txt_4")
		end
	end
end

function UIPermanentPrigeWin:InitData()
	local ref = gModelNormalActivity:GetBIActivityPrivilegeGiftRefByRefId(4)
	local rewards = string.split(ref.showReward, ",")
	local descriptionIcons = string.split(ref.descriptionIcon, "=")
	local rewardList1 = {}
	local rewardList2 = {}
	local rewardList3 = {}
	for i,v in ipairs(rewards) do
		local iconType = tonumber(descriptionIcons[i])
		if iconType == 0 then
			table.insert(rewardList1, {iconType = iconType, reward = v})
		elseif iconType == 1 then
			table.insert(rewardList2, {iconType = iconType, reward = v})
		else
			table.insert(rewardList3, {iconType = iconType, reward = v})
		end
	end
	local rewardList = {};
	table.insert(rewardList, {iconType= 1, rewards = rewardList2})
	table.insert(rewardList, {iconType= 2, rewards = rewardList3})
	table.insert(rewardList, {iconType= 0, rewards = rewardList1})

	self._rewardList = rewardList
end

function UIPermanentPrigeWin:SetBtnStatus()
	local isActive = gModelNormalActivity:IsPrivilegeActive(5)
	if isActive then
		CS.ShowObject(self.mBuyBtn, false)
		CS.ShowObject(self.mBuyImg, true)
	else
		CS.ShowObject(self.mBuyBtn, true)
		CS.ShowObject(self.mBuyImg, false)
	end
end

function UIPermanentPrigeWin:InitMessage()
	self:WndNetMsgRecv(LProtoIds.PrivilegeGiftResp, function(...)
		self:SetBtnStatus()
	end)
	self:WndNetMsgRecv(LProtoIds.BuyPrivilegeGiftResp, function(...)
		self:SetBtnStatus()
	end)
end



------------------------------------------------------------------
return UIPermanentPrigeWin


