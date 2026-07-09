---
--- Created by Administrator.
--- DateTime: 2024/8/15 18:29:37
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubRegressionBoss:LChildWnd
local UISubRegressionBoss = LxWndClass("UISubRegressionBoss", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubRegressionBoss:UISubRegressionBoss()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubRegressionBoss:OnWndClose()
	LChildWnd.OnWndClose(self)
	self:TimerStop(self.timeKey)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubRegressionBoss:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubRegressionBoss:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsEnglishVersion()
	
	self:OnAddClick()
	gModelRegression:OnRegressionMonsterReq()
end


function UISubRegressionBoss:OnFight()

	local monsters= gModelRegression.monsterList
	local ref = self._bossRefs[self._curBossIndex]
	if monsters[ref.refId].kill ==2 then
		GF.ShowMessage(ccClientText(23514))
		return
	end
	if monsters[ref.refId].kill==1 then
		local showstr =ccClientText(43118)
		GF.ShowMessage(showstr)
		return
	else
		for index = self._curBossIndex-1, 1,-1 do
			local curInfo = self._bossRefs[index]
			if monsters[curInfo.refId].kill==0 then--当前未击杀
				GF.ShowMessage(ccClientText(45119))
				return
			end
		end
	end

	local combatType = LCombatTypeConst.COMBAT_TYPE_23
	local extraData = {
		monster = ref.monster,
		reliefTroopId = ref.ReliefTroopId,
		method = ccLngText(ref.Introduction),
		dungeonId = ref.refId
	}
	gLFightManager:PrepareGoToBattle(combatType,extraData)
end


function UISubRegressionBoss:InitSpine()
	local ref = self._bossRefs[self._curBossIndex]
	local monsterRef = GameTable.MonsterFormationRef[ref.monster]
	if not string.isempty(ref.showHero) then
		self:DestroyWndSpineByKey("regressionBoss")
		local dpSpine = self:CreateWndSpine(self.mHeroObj,ref.showHero,"regressionBoss",true,function (dpLoaded)
			dpLoaded:PlayAnimation(0,"idle",true)
		end,true)
		dpSpine:StartLoad()
	end
    local pos = string.split(ref.heroPos,"|")
    if #pos>0 then self:SetAnchorPos(self.mHeroObj,Vector2(tonumber(pos[1]),tonumber(pos[2]))) end

	self:SetWndEasyImage(self.mView,ref.bg)
	self:SetWndText(self.mBossName, ccLngText(monsterRef.name))
end

function UISubRegressionBoss:InitBossInfoList()
    local uiList = self._uiBossInfoList

    if not uiList then
        uiList = self:GetUIScroll("regression_BossInfoList")
        uiList:Create(self.mBossInfoList, self._bossRefs, function(...)
            self:ListBossInfoItem(...)
        end, UIItemList.SUPER_GRID)
    else
        if self._bossRefs then
            uiList:RefreshList(self._bossRefs)
        end
    end

    self._uiBossInfoList = uiList
	uiList:MoveToPos(math.max(self._curBossIndex-1,1))
    uiList:EnableScroll(true, true)
end
function UISubRegressionBoss:OnAddClick()
	self:SetWndText(self.mBossRewardTitle, ccClientText(43109))
	self:SetWndClick(self.mFightBtn,function() self:OnFight() end)
	self:SetWndClick(self.mStrategyBtn, function(...)
        self:OnClickLookStrategy()
    end)
	self:WndNetMsgRecv(LProtoIds.RegressionMonsterResp,function()
		if not self._curBossIndex then
			self:OnInitData()
			self:OnUpadteRwdList()
			self:InitSpine()
			self:OnStartTime()
		end
		self:InitBossInfoList()
	end)
end

--获取时间的描述
function UISubRegressionBoss:GetTabTimeDes(index)
    local bossRef = self._bossRefs[index]
    local desInfo = ""
    local iscur = false
    local isend = false
    local isfuture = false
    if bossRef then

		if gModelRegression.endTime <= GetTimestamp() then
			desInfo = ccClientText(18752)
			isend = true
        else
			local kill = gModelRegression.monsterList[bossRef.refId].kill
			if kill==2 then
				--击败状态
				desInfo = ccClientText(21073)
				isend = true

			elseif kill==0 then
				--进行中
				desInfo = ccClientText(21074)
				iscur = true
			else
				 --未开启-计算年月日
				 local addTime =gModelRegression.monsterList[bossRef.refId].startTime-- (bossRef.day-curDay) * 86400
				--  local times = gModelRegression.starTime + addTime

				 local _data = LUtil.OSDate("*t", addTime)
				 local m_1 = _data.month
				 local d_1 = _data.day

				 desInfo = m_1 .. "." .. d_1 .. "~" ..ccClientText(24205)
				 isfuture = true
			end
        end
    end
	return desInfo, isend, iscur, isfuture
end
function UISubRegressionBoss:GetCurDay()
	local time = GetTimestamp() - gModelRegression.starTime
    local curDay = math.ceil(math.max(time,0)/86400)
	return curDay
end

--攻略
function UISubRegressionBoss:OnClickLookStrategy()
    local bossData = self._bossRefs[self._curBossIndex]
    if not bossData then
        printInfoNR("self._activityPageDataBoss[self._subPage] is a nil, self._subPage = " .. (self._subPage or "nil"))
        return
    end

    local desc = ccLngText(bossData.Introduction)
	local skillDataList = string.split(bossData.skill, ',')
    GF.OpenWnd("UIFlandBossStrategy", { desc = desc, skillDataList = skillDataList, wndType = 2 })
end

function UISubRegressionBoss:ListBossInfoItem(list, item, itemdata, itempos)
    if not itemdata then
        return
    end

    local common = self:FindWndTrans(item, "common")
    local over = self:FindWndTrans(item, "over")
    local cur = self:FindWndTrans(item, "cur")
    local future = self:FindWndTrans(item, "future")

	if self._isEnus then
		cur = self:FindWndTrans(item, "cur_enus")
	end

    local icon = self:FindWndTrans(common, "icon")
    local ImgSel = self:FindWndTrans(item, "ImgSel")
    self:SetWndEasyImage(icon, itemdata.tabIcon)

    --设置状态
    local desStr, isend, iscur, isfuture = self:GetTabTimeDes(itempos)
    CS.ShowObject(over, isend)
    CS.ShowObject(cur, iscur)
    CS.ShowObject(future, isfuture)
    CS.ShowObject(ImgSel,self._curBossIndex==itempos)
	if self._curBossIndex == itempos then self.curSelTran = ImgSel end
    local textTran
    if isend then
        textTran = self:FindWndTrans(over, "UIText")
    elseif iscur then
        textTran = self:FindWndTrans(cur, "UIText")
    elseif isfuture then
        textTran = self:FindWndTrans(future, "UIText")
    end
    self:SetWndText(textTran, desStr)

    self:SetWndClick(icon, function()
        if self._curBossIndex ~= itempos then
			CS.ShowObject(self.curSelTran,false)
			self._curBossIndex = itempos
			self.curSelTran = ImgSel
			self:InitSpine()
			self:OnUpadteRwdList()
			CS.ShowObject(ImgSel,true)
			local curInof = gModelRegression.monsterList[itemdata.refId]
			self:SetWndImageGray(self.mFightBtn,curInof.kill==1)
		end
    end)
end
function UISubRegressionBoss:OnStartTime()
	self.regressionTime = gModelRegression.endTime--1723564800
    self.timeKey = "timeKey_Boss"
	self:TimerStop(self.timeKey)
	self:TimerStart(self.timeKey, 1, false, -1)
	self:SetTimeTxt()
end

function UISubRegressionBoss:SetTimeTxt()
	local nowTime = GetTimestamp()
	local timeDif = os.difftime(self.regressionTime, nowTime)--boss结束时间=玩法结束时间
	local timeStr = LUtil.FormatTimespanCn(timeDif)
	self:SetWndText(self.mBossLeftTimeTitle,string.replace(ccClientText(45113),timeStr))

	-- timeDif = os.difftime(self.regressionTime, nowTime)
	if timeDif <= 0 then
		self:TimerStop(self.timeKey)
	end
	-- timeStr = LUtil.FormatTimeToCn3(timeDif)
	-- self:SetWndText(self.mTxtEndTime,string.replace(ccClientText(45102),timeStr))
end

function UISubRegressionBoss:OnInitData()
	local bossRefs = {}
	self._bossRefs = bossRefs
	local refs = GameTable.ReturnBackChallengeRef
	local sBossInfo = gModelRegression.monsterList
	self._curBossIndex = 1
	for _, value in pairs(refs) do
		table.insert(bossRefs,value)
	end
	table.sort(bossRefs,function(a, b)
		return a.day<b.day
	end)
	for index, ref in ipairs(bossRefs) do
		local state = sBossInfo[ref.refId].kill
		if state==0 then
			self._curBossIndex = index
			break
		end
	end

	CS.ShowObject(self.mBossInfoListDiv, #self._bossRefs > 1)
end

function UISubRegressionBoss:OnTimer(key)
	if key == self.timeKey then
		self:SetTimeTxt()
	end
end

function UISubRegressionBoss:CreateRewardListItem(list, item, itemdata, itempos)
    local root = CS.FindTrans(item, "itemRoot")

    local InstanceID = root:GetInstanceID()

    local uiCommonList = self._uiCommonList
    if not uiCommonList then
        uiCommonList = {}
    end

    local baseClass = uiCommonList[InstanceID]
    if not baseClass then
        baseClass = CommonIcon:New()
        uiCommonList[InstanceID] = baseClass
        baseClass:Create(root)
    end

    baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
    self:SetWndClick(root, function()
        gModelGeneral:ShowCommonItemTipWnd(itemdata)
    end)
    baseClass:DoApply()

    item.localScale = Vector3.one * 0.8
end
function UISubRegressionBoss:OnUpadteRwdList()
	local ref = self._bossRefs[self._curBossIndex]
	local reward = LxDataHelper.ParseItem(ref.reward)
	local uiList = self._uiList
	if not uiList then
		uiList = self:GetUIScroll("regressionMonsterList")
		uiList:Create(self.mBossRewardrList,reward , function(...)
			self:CreateRewardListItem(...)
		end, UIItemList.SUPER)
		self._uiList = uiList
	else
		uiList:RefreshList(reward)
		uiList:DrawAllItems()
	end

	uiList:EnableScroll(true,true)
end

------------------------------------------------------------------
return UISubRegressionBoss