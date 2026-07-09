---
--- Created by Administrator.
--- DateTime: 2023/10/31 11:40:16
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFightRecordMulti:LWnd
local UIFightRecordMulti = LxWndClass("UIFightRecordMulti", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFightRecordMulti:UIFightRecordMulti()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFightRecordMulti:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFightRecordMulti:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFightRecordMulti:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:SetStaticContent()
	self:OnWndRefresh()
end

function UIFightRecordMulti:OnTimer(key)
	if key == self._battleRefreshTimer then
		self:RefreshBattleState()
	end
end

function UIFightRecordMulti:RefreshBattleState()
	if not self._uiItemMap then
		return
	end

	local isAllEnd = true

	for k,v in pairs(self._uiItemMap) do
		local isEnd = nil
		local isStart= nil
		if self._infoType == 2 then
			local endTime = gModelSimuFight:GetInterFightEnd(self._battleInfo.startTime)
			isEnd =  endTime < GetTimestamp()
			local startTime = gModelSimuFight:GetInterFightStart(self._battleInfo.startTime)
			isStart = startTime < GetTimestamp()
		else
			isEnd = gModelSimuFight:CheckSingleBattleIsEnd(self._battleInfo,k)
			isStart = gModelSimuFight:CheckSingleBattleIsStart(self._battleInfo,k)
		end

		local hasEmpty = self._reportInfoRecord and self._reportInfoRecord[k]

		local AniRoot = self:FindWndTrans(v,"AniRoot")
		local AniRootDepart = self:FindWndTrans(AniRoot,"depart")
		local btnVideo = self:FindWndTrans(AniRootDepart,"btnVideo")
		local btnDetail = self:FindWndTrans(AniRootDepart,"btnDetail")

		local left = self:FindWndTrans(AniRootDepart,"left")
		local leftTag = self:FindWndTrans(left,"tag")

		local right = self:FindWndTrans(AniRootDepart,"right")
		local rightTag = self:FindWndTrans(right,"tag")

		local showTag = isEnd or (isStart and hasEmpty)
		CS.ShowObject(leftTag,showTag)
		CS.ShowObject(rightTag,showTag)

		CS.ShowObject(btnVideo,isStart and not hasEmpty)
		CS.ShowObject(btnDetail,isStart and not hasEmpty)

		if not isEnd then
			isAllEnd = false
		end
	end

	if isAllEnd then

		local battleInfo = self._battleInfo
		local tag = self:FindWndTrans(self.mLeftPlayer,"tag")
		local res = battleInfo.winner == 1 and "settlement_txt_2" or "settlement_txt_3"
		self:SetWndEasyImage(tag, res)
		CS.ShowObject(tag,battleInfo.winner ~= 3 and isAllEnd)
		tag = self:FindWndTrans(self.mRightPlayer,"tag")
		local res = battleInfo.winner == 2 and "settlement_txt_2" or "settlement_txt_3"
		self:SetWndEasyImage(tag, res)
		CS.ShowObject(tag,battleInfo.winner ~= 3 and isAllEnd)
		CS.ShowObject(self.mEqual,battleInfo.winner == 3 and isAllEnd)


		self:TimerStop(self._battleRefreshTimer)
	end
end

function UIFightRecordMulti:GetHistory()
	local list = LWnd.GetHistory(self)
	local wndArgList = list.wndArgList
	wndArgList.showRecord = self._showRecord
	return list
end

function UIFightRecordMulti:SetStaticContent()
	local str =ccClientText(25306) --"战斗记录"
	self:SetWndText(self.mLblBiaoti,str)

	self:SetWndClick(self.mBtnClose,function ()
		self:WndClose()
	end)

	self:SetWndClick( self.mBtnShare,function ()
		self:OpenShare()
	end)

	self:SetWndClick(self.mMask,function ()
		self:WndClose()
	end)

	str =ccClientText(25148) -- "分享"
	self:SetWndButtonText(self.mBtnShare,str)
end

function UIFightRecordMulti:OnWndRefresh()
	local battleInfo = self:GetWndArg("battleInfo")
	--local infoType = self:GetWndArg("type") or 1
	local showRecord = self:GetWndArg("showRecord") or {}
	local isShare = self:GetWndArg("isShare")
	CS.ShowObject(self.mBtnShare,not isShare)

	self._battleInfo = battleInfo
	--self._infoType = infoType

	self:SetPlayerContent(self.mLeftPlayer,battleInfo.attack)
	self:SetPlayerContent(self.mRightPlayer,battleInfo.defense)

	local isInteract = battleInfo.schedule == ModelSimuFight.SCHEDULE_INTERACT
	self._infoType = isInteract and 2 or 1
	local isAllEnd = true
	if self._infoType == 2 then --互动赛
		local endTime = gModelSimuFight:GetInterFightEnd(battleInfo.startTime)
		isAllEnd = endTime < GetTimestamp()

		printInfoN(string.format("battle start time %s ,cur time %s",battleInfo.startTime,GetTimestamp()))
	else
		for k,v in ipairs(self._battleInfo.reportId) do
			local isEnd = gModelSimuFight:CheckSingleBattleIsEnd(self._battleInfo,k)
			if not isEnd then
				isAllEnd = false
				break
			end
		end
	end

	local tag = self:FindWndTrans(self.mLeftPlayer,"tag")
	local res = battleInfo.winner == 1 and "settlement_txt_2" or "settlement_txt_3"
	self:SetWndEasyImage(tag, res)
	CS.ShowObject(tag,battleInfo.winner ~= 3 and isAllEnd)
	tag = self:FindWndTrans(self.mRightPlayer,"tag")
	local res = battleInfo.winner == 2 and "settlement_txt_2" or "settlement_txt_3"
	self:SetWndEasyImage(tag, res)
	CS.ShowObject(tag,battleInfo.winner ~= 3 and isAllEnd)

	CS.ShowObject(self.mEqual,battleInfo.winner == 3 and isAllEnd)

	local reportInfoList = {}
	local index = 1
	for k,v in ipairs(battleInfo.reportId) do
		local data =
		{
			index = index,
			reportId = v,
			serverId = battleInfo.serverId,
			isEmpty = string.find(v,"EMPTY"),
			schedule = battleInfo.schedule
		}

		table.insert(reportInfoList,data)

		if index == 1 then
			showRecord[index] = true
		end

		index = index + 1
	end

	self._showRecord = showRecord


	self._reportInfoRecord = {}
	local uiList = self:FindUIScroll("uiList")
	if not uiList then
		uiList = self:GetUIScroll("uiList")
		uiList:Create(self.mReportList,reportInfoList,function (...) self:OnDrawReport(...) end)
		uiList:EnableScroll(true,false)
	else
		uiList:RefreshList(reportInfoList)
	end


	self:TimerStop(self._battleRefreshTimer)
	self:TimerStart(self._battleRefreshTimer,1,false,-1)

end

function UIFightRecordMulti:InitData()
	self._battleRefreshTimer = "_battleRefreshTimer"
end


function UIFightRecordMulti:ShowTreasureList(root,formation,reverse)

	-- local treasure = formation:GetTreasureData()
	-- local skillList = nil
	-- if treasure then
	-- 	local campSkillIdList = treasure.data or {}
	-- 	skillList = campSkillIdList.skillList or {}
	-- end
	-- skillList = skillList or {}

	-- local dataList = {}
	-- for _,v in ipairs(skillList) do
	-- 	if v.skillRefId > 0 then
	-- 		dataList[v.index] = v
	-- 	end
	-- end



	-- local treasureList = {}
	-- for k = 1,4 do
	-- 	local data = dataList[k]
	-- 	if not data then
	-- 		data = {
	-- 			isEmpty = true
	-- 		}
	-- 	end
	-- 	table.insert(treasureList,data)
	-- end

	-- if reverse then
	-- 	treasureList = table.reverse(treasureList)
	-- end

	-- self:InitTreasureList(root,treasureList)

	local combatUnits = formation.combatUnits or {}
    local combatUnitsList = combatUnits[1] or {}
    local campSkillIdList = combatUnitsList.data or {}
    local skillList = combatUnitsList.type == 801 and campSkillIdList.skillList or {}
	local dataList = {}

    for _, v in ipairs(skillList) do
        if v.skillRefId > 0 then
            dataList[v.index] = v
        end
    end
	local treasureList = {}
    for k = 1, 4 do
        local data = dataList[k]
        if not data then
            data = {
                isEmpty = true
            }
        end
        table.insert(treasureList, data)
    end
	self:InitTreasureList(root, treasureList)
end

function UIFightRecordMulti:OpenShare()
	local jsonStr
	if self._battleInfo.ToJson ~= nil then
		jsonStr = self._battleInfo:ToJson()
	else
		jsonStr = JSON.encode(self._battleInfo)
	end

	local data = {
		root = self.mBtnShare,
		shareType = ModelChat.CHATSHARE_27,
		shareData = jsonStr
	}
	gModelGeneral:OpenShareTip(data)
end

---@param formation LFightFormationData
function UIFightRecordMulti:ShowDivineWeaponList(root,formation,reverse)
	local divineWeapon = formation:GetDivineWeaponData()
	local skillList = nil
	if divineWeapon then
		local campSkillIdList = divineWeapon.data or {}
		skillList = campSkillIdList.skillList or {}
	end
	skillList = skillList or {}

	local dataList = {}
	for _,v in ipairs(skillList) do
		if v.skillRefId > 0 then
			dataList[v.index] = v
		end
	end

	local divineWeaponList = {}
	for k = 1,4 do
		local data = dataList[k]
		if not data then
			data = {
				isEmpty = true
			}
		end
		table.insert(divineWeaponList,data)
	end

	if reverse then
		divineWeaponList = table.reverse(divineWeaponList)
	end
end

function UIFightRecordMulti:SetPlayerContent(item,playerData)
	local Head = self:FindWndTrans(item,"Head")
	local name = self:FindWndTrans(item,"name")
	--local server = self:FindWndTrans(item,"server")
	--local icon = self:FindWndTrans(item,"icon")
	local power = self:FindWndTrans(item,"PowerBg/PowerText")
	--local tag = self:FindWndTrans(item,"tag")

	local headTran = self:FindWndTrans(Head,"HeadIcon")
	local playerInfo =
	{
		trans = headTran,
		icon = playerData.head,
		headFrame = playerData.headFrame,
		level = playerData.grade,
		func = function()
			gModelGeneral:PlayerShowReq(playerData.playerId,LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
		end,
	}

	self:CreateHeadIconImpl(playerInfo)

	local nameStr = string.replace(ccClientText(25286),playerData.serverName,playerData.name)
	self:SetWndText(name,nameStr)
	self:SetWndText(power,LUtil.NumberCoversion(playerData.power))
	--self:SetWndText(server,string.format("[%s]",playerData.serverName))

end

function UIFightRecordMulti:OnClickSpread(index)
	local isShow = self._showRecord[index] or false
	self._showRecord[index]  = not isShow
	local list = self:FindUIScroll("uiList")
	if list then
		list:DrawItemByIndex(index)
		local uiCom = list:GetList()
		uiCom:DelayScrollTo(index,UIListEasy.SCROLL_TOP)
	end
end

function UIFightRecordMulti:ShowEmptyItem(item,isEmpty)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local emptyPart = self:FindWndTrans(AniRoot,"emptyPart")
	CS.ShowObject(emptyPart,isEmpty)
	self:SetTextTile(emptyPart,ccClientText(25308))
end

function UIFightRecordMulti:OnClickVideo(reportTable)
	local reportId = reportTable.id
	local combatType = LCombatTypeConst.COMBAT_BATTLE_VIDEO
	local extraData =
	{
		combatType = reportTable.combatType,
		videoType = LVideoTypeConst.SIMULATE_FIGHT,

		battleEndfun = function()
			gModelGeneral:RecoverGameState()
		end
	}

	local playExtraFun = self:GetWndArg("playExtraFun")
	if playExtraFun then
		playExtraFun()
	end

	gModelGeneral:RecordGameState()
	gLFightManager:StartBattle(reportId, combatType,extraData, reportTable)
end

function UIFightRecordMulti:InitTreasureList(trans,list)
	local key = trans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(trans,list,function(...) self:OnDrawTreasureCell(...) end)
	end
end

function UIFightRecordMulti:OnDrawReportPart(item,reportTable,itemdata)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootDepart = self:FindWndTrans(AniRoot,"depart")

	local left = self:FindWndTrans(AniRootDepart,"left")
	local leftPower = self:FindWndTrans(left,"PowerBg/PowerText")
	local leftTag = self:FindWndTrans(left,"tag")
	local leftTactics = self:FindWndTrans(left,"tactics")
	local leftTreasureList = self:FindWndTrans(left,"treasureList")
	local leftHeroList = self:FindWndTrans(left,"heroList")

	local right = self:FindWndTrans(AniRootDepart,"right")
	local rightPower = self:FindWndTrans(right,"PowerBg/PowerText")
	local rightTag = self:FindWndTrans(right,"tag")
	local rightTactics = self:FindWndTrans(right,"tactics")
	local rightTreasureList = self:FindWndTrans(right,"treasureList")
	local rightHeroList = self:FindWndTrans(right,"heroList")

	local layout = self:FindWndTrans(AniRootDepart,"layout")
	local layoutBtnVideo = self:FindWndTrans(layout,"btnVideo")
	local btnVideoUIText = self:FindWndTrans(layoutBtnVideo,"UIText")
	local layoutBtnDetail = self:FindWndTrans(layout,"btnDetail")
	local btnDetailUIText = self:FindWndTrans(layoutBtnDetail,"UIText")


	local index = itemdata.index

	local reportData  = LFightReportData:New()
	reportData:CreateNoRound(reportTable)

	local isEmpty = #reportData.formationA.grids == 0 and #reportData.formationB.grids == 0
	itemdata.isEmpty = isEmpty
	local isShow = self._showRecord[itemdata.index] or false
	self:ShowEmptyItem(item,isEmpty and isShow)
	CS.ShowObject(AniRootDepart,not isEmpty and isShow)

	if isEmpty then
		return
	end

	local isEnd = nil
	local isStart= nil
	if self._infoType == 2 then
		local endTime = gModelSimuFight:GetInterFightEnd(self._battleInfo.startTime)
		isEnd =  endTime < GetTimestamp()
		local startTime = gModelSimuFight:GetInterFightStart(self._battleInfo.startTime)
		isStart = startTime < GetTimestamp()
	else
		isEnd = gModelSimuFight:CheckSingleBattleIsEnd(self._battleInfo,index)
		isStart = gModelSimuFight:CheckSingleBattleIsStart(self._battleInfo,index)
	end

	local winPath = "settlement_txt_2"
	local failPath = "settlement_txt_3"

	self:SetWndEasyImage(leftTag,reportData.winner == 1 and winPath or failPath)
	self:SetWndEasyImage(rightTag,reportData.winner == 1 and failPath or winPath)


	local powerStr = LUtil.NumberCoversion(math.floor(reportData.formationA.power))
    self:SetWndText(leftPower,powerStr)
    powerStr = LUtil.NumberCoversion(math.floor(reportData.formationB.power))
    self:SetWndText(rightPower,powerStr)

	self:ShowTreasureList(leftTreasureList,reportData.formationA,true)
    self:ShowTreasureList(rightTreasureList,reportData.formationB)

	--- 战斗圣武：先写这里，后续在调用
	--self:ShowDivineWeaponList(leftTreasureList,reportData.formationA,true)
    --self:ShowDivineWeaponList(rightTreasureList,reportData.formationB)

    self:ShowHeroList(leftHeroList,reportData.formationA)
    self:ShowHeroList(rightHeroList,reportData.formationB)

	local hasEmpty = #reportData.formationA.grids == 0 or #reportData.formationB.grids == 0

	self._reportInfoRecord[index] = hasEmpty

	local showTag = (hasEmpty and isStart) or isEnd

	CS.ShowObject(leftTag,showTag)
	CS.ShowObject(rightTag,showTag)


	CS.ShowObject(layoutBtnVideo,isStart and not hasEmpty)
	CS.ShowObject(layoutBtnDetail,isEnd and not hasEmpty)

	self:ShowTactic(leftTactics,reportData.formationA.tacticsId)
	self:ShowTactic(rightTactics,reportData.formationB.tacticsId)

	self:SetIconClickScale(layoutBtnVideo,true)

    self:SetWndClick(layoutBtnVideo,function ()
		self:OnClickVideo(reportTable)
	end)

	self:SetWndText(btnVideoUIText,ccClientText(25309))

	self:SetWndClick(layoutBtnDetail,function ()
		self:OpenDetail(reportData)
	end)

	self:SetWndText(btnDetailUIText,ccClientText(25310))
end

function UIFightRecordMulti:SetHeroListInfo(trans,heroGridList)
	local gridMax = LCombatFormationConst.GRID_MAX
    for k=1,gridMax do
        local transName = "pos" .. k
        local heroTrans = self:FindWndTrans(trans,transName)
        if heroTrans then
            self:SetHeroInfo(heroTrans,heroGridList[k])
        end
    end
end

function UIFightRecordMulti:ShowTactic(item,tacticId)
	local Image = self:FindWndTrans(item,"Image")
	local Icon = self:FindWndTrans(item,"Icon")


	local ref = gModelSimuFight:GetSimulateGameSkill(tacticId)
	if ref then
		self:SetWndEasyImage(Icon,ref.icon)
	end
	self:SetWndClick(item,function ()
		if not ref then
			return
		end
		self:ShowTacticTips(ref.skill)
	end)

	CS.ShowObject(Icon,ref ~= nil)
	self:SetIconClickScale(item,true)
end



function UIFightRecordMulti:ShowHeroList(root,formation)
    local playerId = formation.playerId
    local heroList = {}
    local grids = formation.grids
    for i,v in ipairs(grids) do
        local index = v.index
        heroList[index] = {
            heroData = v,
            playerId = playerId,
            serverId = formation.serverId,
        }
    end
    self:SetHeroListInfo(root,heroList)
end

function UIFightRecordMulti:SetHeroInfo(trans,data)
    -- local CommonUI = self:FindWndTrans(trans,"CommonUI")
    -- local Icon = self:FindWndTrans(CommonUI,"Icon")
	local Icon = trans

    local showIcon = data ~= nil
	if showIcon then
		local playerId = data.playerId
		local serHeroData = data.heroData

		local id = serHeroData.id
		local refId = serHeroData.refId
		local star = serHeroData.star
		local level = serHeroData.level
		local resonance = serHeroData.resonance
		local skin = serHeroData.skinId
		local power = serHeroData.fightPower
		local grade = serHeroData.grade

		local instance = Icon:GetInstanceID()
		local baseClass = self:GetCommonIcon(instance)
		baseClass:Create(Icon)
		local heroData = {}
		heroData.trans = Icon
		heroData.id = id
		heroData.refId = refId
		heroData.star = star
		heroData.level = level
		heroData.isResonance = resonance
		heroData.skin = skin
		heroData.power = power,
		baseClass:SetHeroDataSet(heroData)
		baseClass:DoApply()


		self:SetWndClick(trans,function()
			local heroInfo = {
				id = id,
				refId = refId,
				level = level,
				star = star,
				grade = grade,
				fightPower = power,
				isResonance = resonance,
				skin = skin,
			}
			gModelHero:ReqShowHeroTipEx({playerId = playerId,heroData = heroInfo,serverId = data.serverId})
		end)
	else
		self:SetWndClick(trans,function() end)
	end

	self:SetIconClickScale(trans,showIcon)
    -- CS.ShowObject(Icon,showIcon)
end

function UIFightRecordMulti:OnDrawTreasureCell(list,item,itemdata,itempos)
	local EmptyBg = self:FindWndTrans(item,"EmptyBg")
	local IconBg = self:FindWndTrans(item,"IconBg")
	local Icon = self:FindWndTrans(IconBg,"Icon")
	local isEmpty = itemdata.isEmpty
	local notEmpty = not isEmpty
	CS.ShowObject(EmptyBg,isEmpty)
	CS.ShowObject(IconBg,notEmpty)
	if notEmpty then
		-- local skillRefId = itemdata.skillRefId
		-- -- local info = gModelTreasure:GetSkillInfo(skillRefId)
		-- local has = false
		-- -- if info then
		-- -- 	has = true
		-- -- 	self:SetWndEasyImage(IconBg,info.iconBg,nil,true)

		-- -- 	local iconPath = gModelTreasure:GetTreasureIconByRefId(info.refId, itemdata.exhibitionInfo and itemdata.exhibitionInfo.skin or nil)
		-- -- 	self:SetWndEasyImage(Icon,iconPath,nil,true)
		-- -- end
		-- CS.ShowObject(IconBg,has)




		-- self:SetWndClick(item, function()
		-- 	gModelGeneral:OpenOnlyTreasureTip({treasureData = itemdata.exhibitionInfo})
		-- end)

		local skillRefId = itemdata.skillRefId
        local info = gModelSkill:GetSkillRef(skillRefId)
        local has = false
        if info then
            has = true
            self:SetWndEasyImage(IconBg, info.iconBg, nil, true)

            --local iconPath = gModelTreasure:GetTreasureIconByRefId(info.refId, itemdata.exhibitionInfo and itemdata.exhibitionInfo.skin or nil)
            local iconPath = info.icon
            self:SetWndEasyImage(Icon, iconPath, nil, true)
        end
        CS.ShowObject(IconBg, has)

        self:SetWndClick(item, function()
            --gModelGeneral:OpenOnlyTreasureTip({ treasureData = itemdata.exhibitionInfo })
            local ref, upRef = gModelDraconic:GetDraconicRefBySkillId(skillRefId)
            GF.OpenWnd("UIDraconicUpStar", { refId = upRef.type, starNum = upRef.rankNow, tips = true })
        end)
    end
end

function UIFightRecordMulti:OpenDetail(reportTable)
	local extraData =
	{
		serverId = self._battleInfo.serverId,
		combatType = LCombatTypeConst.COMBAT_TYPE_25,
		playExtraFun = self:GetWndArg("playExtraFun"),
		closeAfterVideo = function()
			gModelGeneral:RecoverGameState()
		end
	}
	gModelGeneral:RecordGameState()

	gLFightManager:ShowBattleDetailByReportTable(reportTable,extraData)
end

function UIFightRecordMulti:ShowTacticTips(refId)
	local skillid = tonumber(refId)
	if not skillid then
		return
	end

	--GF.OpenWnd("UINewJNTip",{curSkillId = skillid,wndType = 2})
	gModelGeneral:OpenSkillWnd({curSkillId = skillid,wndType = 2})
end

function UIFightRecordMulti:OnDrawReport(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootToppart = self:FindWndTrans(AniRoot,"toppart")
	local toppartTitle = self:FindWndTrans(AniRootToppart,"title")
	local toppartBtnSpread = self:FindWndTrans(AniRootToppart,"btnSpread")
	local btnSpreadImage = self:FindWndTrans(toppartBtnSpread,"Image")
	local AniRootDepart = self:FindWndTrans(AniRoot,"depart")

	--local empty = self:FindWndTrans(AniRoot,"emptyPart")

	if not self._uiItemMap then
		self._uiItemMap = {}
	end

	self._uiItemMap[itemdata.index] = item

	local isShow = self._showRecord[itemdata.index] or false
	local isEmpty = itemdata.isEmpty

	local angle = Quaternion.Euler(0,0,270)
	if isShow then
		angle = Quaternion.Euler(0,0,90)
	end

	btnSpreadImage.localRotation = angle

	local isInteract = itemdata.schedule == ModelSimuFight.SCHEDULE_INTERACT

	local str = nil
	if isInteract then
		str = string.replace(ccClientText(25307),itemdata.index)
	else
		local teamCnt = gModelSimuFight:GetTeamCnt(itemdata.schedule)
		if itemdata.index > teamCnt  then
			str =ccClientText(25311) --"加 赛"
		else
			str = string.replace(ccClientText(25307),itemdata.index)
		end
	end

	self:SetWndText(toppartTitle,str)

	self:SetWndClick(AniRootToppart,function ()
		self:OnClickSpread(itemdata.index)
	end)

	CS.ShowObject(AniRootDepart,not isEmpty and isShow)
	self:ShowEmptyItem(item,isEmpty and isShow)

	if not isShow then
		return
	end

	if isEmpty then
		return
	end


	local reqInfo =
	{
		reportId = itemdata.reportId,
		serverId = itemdata.serverId,
		callback = function(reportTable)
			self:OnDrawReportPart(item,reportTable,itemdata)
		end
	}

	self:GetReportTable(reqInfo)

end

------------------------------------------------------------------
return UIFightRecordMulti


