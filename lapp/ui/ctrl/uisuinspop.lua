---
--- Created by Administrator.
--- DateTime: 2023/10/6 12:00:34
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISuInsPop:LWnd
local UISuInsPop = LxWndClass("UISuInsPop", LWnd)

UISuInsPop.EFFNAME_WIN = "bestronger_txt_1"

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISuInsPop:UISuInsPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISuInsPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISuInsPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISuInsPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitEvent()
	self:InitUIEvent()
	self._type = self:GetWndArg("page") or 1

	self:SetStaticContent()



	gModelSimuFight:OnSimulateShowGameListReq()
	--local date  = LUtil.OSDate("*t", GetTimestamp())

	--printInfoN(string.format("curTime %s:%s",date.hour,date.min))
end

function UISuInsPop:InitUIEvent()
	self:SetWndClick(self.mBtnClose,function ()
		self:WndClose()
	end)
    self:SetWndClick(self.mMask,function ()
        self:WndClose()
    end)
end

function UISuInsPop:InitEvent()
	self:WndNetMsgRecv(LProtoIds.SimulateShowGameListResp,function (pb)
		self:OnSimulateShowGameListResp(pb)
	end)
end

function UISuInsPop:OnClickDetail(itemdata)
	GF.OpenWnd("UIFightRecordMulti",{battleInfo = itemdata})
end

function UISuInsPop:RefreshList()

	if not self._dataList then
		local dataList = {}

		for k,v in ipairs(self._interactInfo.infos) do
			local data = StructSimulateBattleInfo:New()
			data:CreateByPb(v)
			table.insert(dataList,data)
		end

		self._dataList = dataList

		local flowerRecord = {}
		for k,v in ipairs(self._interactInfo.flowerInfos) do
			local battleId = v.id
			local targetId = v.targetId
			flowerRecord[battleId] = targetId
		end

		self._flowerRecord = flowerRecord
	end


	local showDataList = {}
	for k,v in ipairs(self._dataList) do
		local battleId = v.id
		local targetId = self._flowerRecord[battleId]
		local isLeft = false
		local isRight = false
		if targetId then
			if targetId == v.attack.playerId then
				isLeft = true
			elseif targetId == v.defense.playerId then
				isRight = true
			end
		end

		if self._type == 1 or (isRight or isLeft) then
			local data =
			{
				battleInfo = v,
				isLeft = isLeft,
				isRight = isRight
			}

			table.insert(showDataList,data)
		end
	end

	table.sort(showDataList,function (a,b)
		return a.battleInfo.startTime > b.battleInfo.startTime
	end)



	local isEmpty = #showDataList == 0

	CS.ShowObject(self.mNoRecord,isEmpty)
	CS.ShowObject(self.mItemList,not isEmpty)
	if isEmpty then
		return
	end

	local uiList = self:FindUIScroll("uiList")
	if not uiList then
		uiList= self:GetUIScroll("uiList")
		uiList:Create(self.mItemList,showDataList,function (...) self:OnDrawItem(...) end,UIItemList.SUPER)
	else
		uiList:RefreshList(showDataList)
	end

	uiList:DrawAllItems(false)
end

function UISuInsPop:SetPlayer(item,playerData)
	local headTran = self:FindWndTrans(item,"HeadIcon")
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
end

function UISuInsPop:OnDrawTab(list,item,itemdata,itempos)
	local BtnTab = self:FindWndTrans(item,"BtnTab")

	local addFontSize = nil
	local addFontLine = nil
	if gLGameLanguage:IsGermanVersion() then
		addFontSize = -4
		addFontLine = -30
	end

	self:SetWndTabText(BtnTab,itemdata.name, addFontSize, addFontLine)
	local isSelect = self._type == itemdata.type

	local state = isSelect and LWnd.StateOn or LWnd.StateOff

	self:SetWndTabStatus(BtnTab,state)

	self:SetWndClick(BtnTab,function ()
		self._type = itemdata.type
		self:RefreshList()

		local list = self:FindUIScroll("tabList")
		if list then
			list:DrawAllItems(false)
		end
	end)

end

function UISuInsPop:OnDrawItem(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootImage = self:FindWndTrans(AniRoot,"Image")
	local AniRootPlayer_1 = self:FindWndTrans(AniRoot,"player_1")
	local player_1HeadRoot = self:FindWndTrans(AniRootPlayer_1,"headRoot")
	local player_1Name = self:FindWndTrans(AniRootPlayer_1,"name")
	local player_1Tag = self:FindWndTrans(AniRootPlayer_1,"tag")
	local player_1Eff = self:FindWndTrans(AniRootPlayer_1,"Eff")
	local AniRootPlayer_2 = self:FindWndTrans(AniRoot,"player_2")
	local player_2HeadRoot = self:FindWndTrans(AniRootPlayer_2,"headRoot")
	local player_2Name = self:FindWndTrans(AniRootPlayer_2,"name")
	local player_2Tag = self:FindWndTrans(AniRootPlayer_2,"tag")
	local player_2Eff = self:FindWndTrans(AniRootPlayer_2,"Eff")
	local AniRootVs = self:FindWndTrans(AniRoot,"vs")
	local AniRootPing = self:FindWndTrans(AniRoot,"ping")
	local AniRootNumIntro = self:FindWndTrans(AniRoot,"numIntro")
	local AniRootGameTime = self:FindWndTrans(AniRoot,"gameTime")
	local AniRootShareBtn = self:FindWndTrans(AniRoot,"ShareBtn")
	local ShareBtnUIText = self:FindWndTrans(AniRootShareBtn,"UIText")
	local AniRootReportBtn = self:FindWndTrans(AniRoot,"ReportBtn")
	local ReportBtnUIText = self:FindWndTrans(AniRootReportBtn,"UIText")


	local battleInfo = itemdata.battleInfo

	self:SetPlayer(player_1HeadRoot,battleInfo.attack)
	self:SetPlayer(player_2HeadRoot,battleInfo.defense)

	self:SetWndText(player_1Name,battleInfo.attack.name)
	self:SetWndText(player_2Name,battleInfo.defense.name)
	self:InitTextModeWithLanguage(player_1Name, nil, self._isForeign)
	self:InitTextModeWithLanguage(player_2Name, nil, self._isForeign)

	local showTag = false
	local winner = battleInfo.winner
	local tag1Win = winner == 1
	local tag2Win = winner == 2

	local tag1 = showTag and tag1Win or false
	local tag2 = showTag and tag2Win or false
	CS.ShowObject(player_1Tag,tag1)
	CS.ShowObject(player_2Tag,tag2)
	CS.ShowObject(AniRootPing,winner == 0)
	CS.ShowObject(AniRootVs,winner ~= 0)

	local showEff = not showTag
	local eff1 = showEff and tag1Win or false
	local eff2 = showEff and tag2Win or false
	if eff1 then
		local winKey = player_1Eff:GetInstanceID()
		self:CreateWndEffect(player_1Eff,UISuInsPop.EFFNAME_WIN,winKey,100,false,false,10)
	end
	if eff2 then
		local winKey = player_2Eff:GetInstanceID()
		self:CreateWndEffect(player_2Eff,UISuInsPop.EFFNAME_WIN,winKey,100,false,false,10)
	end
	CS.ShowObject(player_1Eff,eff1)
	CS.ShowObject(player_2Eff,eff2)


	local date  = LUtil.OSDate("*t", battleInfo.startTime/1000)

	local str = string.replace(ccClientText(25146) ,fixedTimeToTwo(date.hour),fixedTimeToTwo(date.min))

	self:SetWndText(AniRootGameTime,str)
	--str = ccClientText(25147) --"献花数"
	--self:SetWndText(AniRootNumIntro,str)

	local strFormat = ccClientText(25300)
	if itemdata.isLeft then
		strFormat =ccClientText(25317) --"支持数 <#feeba7>%s</color>:%s"
	elseif itemdata.isRight then
		strFormat =ccClientText(25318) --"支持数 %s:<#feeba7>%s</color>"
	end

	str = string.replace(strFormat,battleInfo.attackFlower,battleInfo.defenceFlower)
	self:SetWndText(AniRootNumIntro,str)

	str = ccClientText(25148) --"分享"
	self:SetWndText(ShareBtnUIText,str)
	str = ccClientText(25114) --"详情"
	self:SetWndText(ReportBtnUIText,str)

	self:SetWndClick(AniRootShareBtn,function () self:OnClickShare(battleInfo,AniRootShareBtn) end)
	self:SetWndClick(AniRootReportBtn,function () self:OnClickDetail(battleInfo) end)

end

function UISuInsPop:OnClickShare(itemdata,root)
	local jsonStr = itemdata:ToJson()
	local data = {
		root = root,
		shareType = ModelChat.CHATSHARE_30,
		shareData = jsonStr
	}
	gModelGeneral:OpenShareTip(data)
end

function UISuInsPop:OnSimulateShowGameListResp(pb)
	self._interactInfo = pb

	self:RefreshList()
end

function UISuInsPop:SetStaticContent()
	local str = ccClientText(25299)
	self:SetWndText(self.mLblBiaoti,str)

	str = ccClientText(25325)
	self:SetWndText(self.mIntro,str)

	local data = {
		refId = 25006,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)

	local dataList =
	{
		[1] =
		{
			type = 1,
			name = ccClientText(25315) --
		},
		[2] =
		{
			type = 2,
			name = ccClientText(25316) --"我的支持",
		},
	}

	self._isForeign = gLGameLanguage:IsForeignRegion()

	--self._type = 1
	local list = self:GetUIScroll("tabList")
	list:Create(self.mTabList,dataList,function(...)  self:OnDrawTab(...) end)
end

------------------------------------------------------------------
return UISuInsPop


