---
--- Created by Administrator.
--- DateTime: 2024/4/17 11:35:34
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UITaSweepTips:LWnd
local UITaSweepTips = LxWndClass("UITaSweepTips", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UITaSweepTips:UITaSweepTips()
	self._uicommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UITaSweepTips:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UITaSweepTips:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UITaSweepTips:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsForeignVersion()

	if self._isEnus then
		local pos = self.mPrivilegeTips.localPosition + Vector3.New(0,-30,0)
		self.mPrivilegeTips.localPosition = pos
		local pos_2 = self.mBtnVip.localPosition + Vector3.New(0,20,0)
		self.mBtnVip.localPosition = pos_2
	end
	

	self.sysEffectType = 14
	gModelNormalActivity:OnSystemBuffInfoReq(gModelNormalActivity.SystemBuffSourceType_Grade,{self.sysEffectType})
	self:SetWndText(self.mTxtTitle,ccClientText(12186))
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end)
	self:SetWndClick(self.mPublic_btn_1,function() self:WndClose() end)
	self:SetWndClick(self.mPublic_btn_2,function() self:WndClose() end)
	self:SetWndClick(self.mMaskCell,function() self:WndClose() end)
	self:WndEventRecv(EventNames.TOWER_FLOORUPDATE,function() self:OnUpdateState() end)
	self:WndNetMsgRecv(LProtoIds.SystemBuffInfoResp,function(...) self:RefreshPrivilegeTips(...) end)----系统增益数据 
	self:OnUpdateState()
	
end

function UITaSweepTips:OnUpdateState()
	--当前扫荡关卡
	CS.ShowObject(self.mPublic_btn_1,false)
	CS.ShowObject(self.mPublic_btn_2,false)
	CS.ShowObject(self.mTxtBtn_1,false)
	CS.ShowObject(self.mTxtBtn_2,false)
	CS.ShowObject(self.mTxtVip,false)
	CS.ShowObject(self.mRedPoint,false)
	local _towerType = self:GetWndArg("towerType")
	local _towerInfo = gModelTower:GetTowerInfoByTowerType(_towerType)
	if not _towerInfo then
		return
	end
	local itemdata = gModelTower:GetTowerRefByLayer(_towerType,_towerInfo.historyMaxFloor)
	local tasLayer = _towerInfo.historyMaxFloor
	if tasLayer <= 0 then --没历史通关
		itemdata = gModelTower:GetTowerRefByLayer(_towerType,math.max(_towerInfo.floor,1))
	end
	self:SetWndText(self.mContent2,ccClientText(12189))
	local ref = gModelTower:GetTowerLayer(_towerType,itemdata.refId)
    local  rewards = gModelTower:SetAawardDataList(ref.reward)
	self:InitScrollView(rewards)

	if tasLayer<=0 then
		self:SetWndText(self.mContent,ccClientText(12188))
		CS.ShowObject(self.mPublic_btn_1,true)
		self:SetWndButtonText(self.mPublic_btn_1,ccClientText(12190))
		self:SetWndClick(self.mPublic_btn_1, function(...)
			self:WndClose()
		end)
		return
	end
	local func = function()
		local ref = gModelTower:GetTowerLayer(_towerType,itemdata.refId)
		gModelTower:OnTowerSweepReq(ref.floorNum)--扫荡
	end

	local num = gModelTower:GetCurrNum(_towerType)
	local vipNum = gModelTower:GetVipGoBuy()
	local guyNum = gModelTower:GetBuySweepNum(_towerType)
	self:SetWndText(self.mContent,string.replace(ccClientText(12187),_towerInfo.historyMaxFloor))
	if(num <= 0)then
		local guyStr = gModelTower:GetExpend(guyNum + 1)
		self:SetWndButtonText(self.mPublic_btn_2,guyStr..ccClientText(12106))
		CS.ShowObject(self.mPublic_btn_2,true)
		self:SetWndClick(self.mPublic_btn_2, function(...)
			-- gModelTower:OnClickLayerBtn(_towerType,itemdata.refId)
			func()
		end)
		if(vipNum <= guyNum)then
			CS.ShowObject(self.mTxtVip,true)
			self:SetWndText(self.mTxtVip,ccClientText(12142))
			self:SetWndClick(self.mBtnVip, function(...)
				self:OnClickGoVip()
			end)
			return
		end
		CS.ShowObject(self.mTxtBtn_2,true)
		self:SetWndText(self.mTxtBtn_2,string.replace(ccClientText(12168),vipNum - guyNum))--设置免费次数
	else
		CS.ShowObject(self.mRedPoint,true)
		CS.ShowObject(self.mPublic_btn_1,true)
		CS.ShowObject(self.mTxtBtn_1,true)
		self:SetWndButtonText(self.mPublic_btn_1,ccClientText(12105))
		self:SetWndText(self.mTxtBtn_1,string.replace(ccClientText(12141),num))--设置免费次数
		self:SetWndClick(self.mPublic_btn_1, function(...)
			-- gModelTower:OnClickLayerBtn(_towerType,itemdata.refId)
			func()
		end)
	end

end
function UITaSweepTips:InitScrollView(rewards)
	local uiList = self._uiList
	if not uiList then
		local list = self.mRewardList
		uiList = UIListEasy:New()
		uiList:Create(self,list)
		uiList:EnableScroll(true,true)
		uiList:SetFuncOnItemDraw(function(...)
			self:uilist_OnDrad(...)
		end)
		self._uiList = uiList
	end
	uiList:RemoveAll()
	local rewardList = rewards or {}
	for k,v in ipairs(rewardList) do
		uiList:AddData(k,v)
	end
    uiList:RefreshList()
end

function UITaSweepTips:uilist_OnDrad(list, item, itemdata, itempos)
	local itype = itemdata.itype or itemdata.type
	if itype == nil then itype = itemdata.itemType end

	local refId = itemdata.heroId or tonumber(itemdata.itemId or itemdata.refId)
	local num = itemdata.count or itemdata.itemNum

	local instanceId = item:GetInstanceID()
	local iconRootTrans = CS.FindTrans(item,"CommonUI/IconRoot")
	local uicommonlist = self._uicommonList
	local baseClass = uicommonlist[instanceId]
	if not baseClass then
		baseClass = CommonIcon:New()
		uicommonlist[instanceId] = baseClass
		baseClass:Create(CS.FindTrans(iconRootTrans,"Icon"))
	end
	if itype == LItemTypeConst.TYPE_HERO and itemdata.heroId then
		baseClass:SetHeroPlayer(itemdata.heroId)
	elseif itype == LItemTypeConst.TYPE_HERO and itemdata.heroData then
		baseClass:SetHeroDataSet(itemdata.heroData)
	else
		baseClass:SetCommonReward(itype, refId, num)
	end
	local _towerType = self:GetWndArg("towerType")
	local _towerInfo = gModelTower:GetTowerInfoByTowerType(_towerType)
	if not _towerInfo or _towerInfo.historyMaxFloor<=0 then
		baseClass:EnableShowNum(false)
	else
		baseClass:EnableShowNum(true)
	end

	baseClass:DoApply()

	self:SetWndClick(iconRootTrans, function()
		if itype == LItemTypeConst.TYPE_ITEM then
			gModelGeneral:OpenItemInfoTip(refId)

		elseif itype == LItemTypeConst.TYPE_HERO then
			local heroData = itemdata.heroData
			if itemdata.heroId then
				local heroRefId = gModelHero:GetRefIdById(itemdata.heroId)
				gModelGeneral:OpenHeroSimpleTip(heroRefId)
			elseif heroData then
				local id = heroData.id
				local lv = heroData.level
				local serverData = gModelHero:GetHeroServerDataById(id)
				if serverData then lv = serverData.lv end
				local data = {
					id = id,
					refId = heroData.refId,
					level = lv,
					star = heroData.star,
					grade = heroData.grade,
					fightPower = heroData.fightPower,
					isResonance = heroData.isResonance,
					skin = heroData.skin,
				}
				gModelHero:ReqShowHeroTip("",data)
			end
		elseif itype == LItemTypeConst.TYPE_EQUIP then
			gModelGeneral:OpenEquipInfoTip(refId,nil,1,true)

		elseif itype == LItemTypeConst.TYPE_RUNE then
			local runeId = itemdata.id
			local serverData = gModelRune:GetServerDataById(runeId)
			if serverData then
				local data = {runeData = serverData}
				gModelGeneral:OpenRuneInfoTip(data)
			end
		end
	end)
	self:SetIconClickScale(iconRootTrans, true)

	local uiNameTrans = CS.FindTrans(iconRootTrans, "UIName")
	local uiNameText = uiNameTrans and self:FindWndText(uiNameTrans) or nil
	if uiNameText then
		local itemname,itemcolor = baseClass:GetName()
		self:SetXUITextText(uiNameText, itemname or "")
		if itemcolor then
			self:SetXUITextColor(uiNameText, itemcolor)
		end
		--self:InitTextModeWithLanguage(uiNameTrans)

		self:InitTextShowWithLanguage(uiNameText)
	end
end
function UITaSweepTips:RefreshPrivilegeTips(pb)
	local infos = pb.infos
	local effectValues =nil
	local isNull = true
	for _, value in ipairs(infos) do
		if value.effectType == self.sysEffectType then
			isNull = false
			effectValues = string.split(value.effectValue,"|")
			break
		end
	end
	CS.ShowObject(self.mPrivilegeTips,not isNull )
	local effValue = 0
	for _, value in ipairs(effectValues or {}) do
		effValue = effValue+tonumber(value)
	end
	self:SetWndText(self.mTxtPrivilege,string.replace(ccClientText(12193),effValue*100))


end

function UITaSweepTips:OnClickGoVip()
	if(not gModelTower:GetVipBoolGoBuy())then
		GF.ShowMessage(ccClientText(12143))
		return
	end
	GF.OpenWnd("UIOrdinTip",{refId=80004,func=function (...)
		local wndInst = GF.FindFirstWndByName("UIHuiYPay")
		if not wndInst then
			GF.OpenWndBottom("UIHuiYPay",{page=2})
		else
			FireEvent(EventNames.ON_VIPLEVEL_CHANGE)
		end
		self:WndClose()
	end } )
end

------------------------------------------------------------------
return UITaSweepTips