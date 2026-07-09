---
--- Created by Administrator.
--- DateTime: 2023/10/4 11:51:47
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISSyendFlower:LWnd
local UISSyendFlower = LxWndClass("UISSyendFlower", LWnd)

UISSyendFlower.GROUP = 1
UISSyendFlower.CHAMPION = 2

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISSyendFlower:UISSyendFlower()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISSyendFlower:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISSyendFlower:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISSyendFlower:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()

	self:InitEvent()
	self:InitUIEvent()
	self:SetStaticContent()

	self:OnWndRefresh()
end

function UISSyendFlower:SetBottomPlayer(item,playerData,flowerNum)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootHeadRoot = self:FindWndTrans(AniRoot,"headRoot")
	local AniRootName = self:FindWndTrans(AniRoot,"name")
	local AniRootPower = self:FindWndTrans(AniRoot,"power")
	local AniRootFlower = self:FindWndTrans(AniRoot,"flower")

	local headTran = self:FindWndTrans(AniRootHeadRoot,"HeadIcon")
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


	local serverName =  string.replace(ccClientText(25287),playerData.serverName,playerData.name)
	self:SetWndText(AniRootName,serverName)

	local flowerStr = string.replace(ccClientText(25285),flowerNum)
	self:SetWndText(AniRootFlower,flowerStr)

	local powerStr = string.replace(ccClientText(25284),LUtil.NumberCoversion(playerData.power))
	self:SetWndText(AniRootPower,powerStr)
end

function UISSyendFlower:OnSelectPlayer(playerId)
	if playerId == self._curPlayerId then
		self._curPlayerId = nil
	else
		self._curPlayerId = playerId
	end

	local list = self:FindUIScroll("playerList")
	if list then
		list:DrawAllItems(false)
	end
end

function UISSyendFlower:OnClickOption(itemdata)

	self:ShowOption(false)

	if itemdata.index == self._curOption then
		return
	end

	self._curOption = itemdata.index

	local list = self:FindUIScroll("optionList")
	if list then
		list:DrawAllItems(false)
	end



	self:SetWndText(self.mSortName,itemdata.name)

	self:RefreshChamList()

end

function UISSyendFlower:OnClickChampionSend()
	local state = gModelSimuFight:GetState()
	local isIng = true
	if state > ModelSimuFight.SCHEDULE_GROUP_WARM_UP then
		isIng = false
	end

	local combatState = gModelSimuFight:GetCombatState()
	if combatState > ModelSimuFight.BATTLE_READY then
		isIng = false
	end

	local endTime = gModelSimuFight:GetNextStageTime()

	local timeLeft = endTime - GetTimestamp()
	if timeLeft < 0 then
		isIng = false
	end

	if not isIng then
		local str =ccClientText(25183)-- "当前非献花阶段"
		GF.ShowMessage(str)
		return
	end

	if not self._curPlayerId then
		local str = ccClientText(25182)--"请选择献花的梦境者"
		GF.ShowMessage(str)
		return
	end

	local emo = self:GetEmo()
	if not emo then
		local str = ccClientText(25184)--"请选择打气表情"
		GF.ShowMessage(str)
		return
	end

	gModelSimuFight:OnSimulateFlowerReq(self._curPlayerId,2,self._curGroup,emo)

end

function UISSyendFlower:SaveEmo(emo)
	if not self._record then
		self._record= {}
	end

	local group = self._curGroup
	self._record[group] = emo
end

function UISSyendFlower:InitEvent()
	self:WndNetMsgRecv(LProtoIds.SimulateFlowerResp,function (pb)
		self:OnSimulateFlowerResp(pb)
	end)

	self:WndNetMsgRecv(LProtoIds.SimulateLikeListResp,function (pb)
		self:OnSimulateLikeListResp(pb)
	end)

end

function UISSyendFlower:RefreshGroupSel()
	local item = self.mLeft
	local select = self:FindWndTrans(item,"select")
	local selectBg = self:FindWndTrans(select,"bg")
	local selectIsOn = self:FindWndTrans(select,"isOn")

	CS.ShowObject(selectIsOn,self._curPlayerId == self._leftPlayerId )

	local item = self.mRight
	local select = self:FindWndTrans(item,"select")
	local selectBg = self:FindWndTrans(select,"bg")
	local selectIsOn = self:FindWndTrans(select,"isOn")

	CS.ShowObject(selectIsOn,self._curPlayerId == self._rightPlayerId)
end

function UISSyendFlower:ShowCountDown()
	local isIng = gModelSimuFight:IsCurGroupBattleReady(self._battleInfo)

	if not isIng then
		local str =  ccClientText(25180)--"本次献花已结束"
		self:SetWndText(self.mTimeInfo,str)
		return false
	end

	local endTime = gModelSimuFight:GetNextStageTime()

	local timeLeft = endTime - GetTimestamp()
	if timeLeft>=0 then
		local timeStr = string.replace( ccClientText(25181),LUtil.FormatTimespanNumber(timeLeft))
		self:SetWndText(self.mTimeInfo,timeStr)
		return true
	else
		self:SetWndText(self.mTimeInfo, ccClientText(25180))
		return false
	end
end


function UISSyendFlower:ReqPlayerList()
	gModelSimuFight:OnSimulateLikeListReq(self._curGroup)
end

function UISSyendFlower:RefreshFlowerNumShow()
	local groupFlowerNum = gModelSimuFight:GetFlowerNum(1,self._curGroup)
	local layout = self:FindWndTrans(self.mBtnGroupSend,"layout")
	local layoutNum = self:FindWndTrans(layout,"num")
	self:SetWndText(layoutNum,groupFlowerNum)

	local groupFlowerNum = gModelSimuFight:GetFlowerNum(2,self._curGroup)
	local layout = self:FindWndTrans(self.mBtnChamSend,"layout")
	local layoutNum = self:FindWndTrans(layout,"num")
	self:SetWndText(layoutNum,groupFlowerNum)
end

function UISSyendFlower:SortByOption()
	local sortFun = nil
	if self._curOption == 1 then
		sortFun = function(a,b)
			return a.rank< b.rank
		end
	elseif self._curOption == 2 then
		sortFun = function(a,b)
			return a.power > b.power
		end
	elseif self._curOption == 3 then
		sortFun = function(a,b)
			return a.flower > b.flower
		end
	end

	if not sortFun then
		return
	end

	table.sort(self._playerDataList,sortFun)
end

function UISSyendFlower:ShowOption(isShow)
	CS.ShowObject(self.mSortFilterbg,isShow)
	if not isShow then
		return
	end

	local dataList =
	{
		[1] =
		{
			index = 1,
			name = ccClientText(25177), --"默认",
		},
		[2] =
		{
			index = 2,
			name = ccClientText(25185), --"战力",
		},
		[3]=
		{
			index = 3,
			name = ccClientText(25186),  --"献花"
		}
	}

	self._curOption = self._curOption or 1

	local list = self:FindUIScroll("optionList")
	if not list then
		list= self:GetUIScroll("optionList")
		list:Create(self.mSelSortList,dataList,function (...) self:OnDrawOption(...) end)
	else
		list:DrawAllItems(false)
	end

end

function UISSyendFlower:OnHasSendFlowerGroup()
	local pb = self._flowerInfo
	local attack = StructPlayerData:New()
	attack:CreateByPb(pb.attackInfo)
	local defence = StructPlayerData:New()
	defence:CreateByPb(pb.defenceInfo)
	self._curSelect = 0
	local targetPlayer = nil
	if pb.targetId == attack.playerId then
		self._curSelect = 1
		targetPlayer = attack
	elseif pb.targetId == defence.playerId then
		self._curSelect = 2
		targetPlayer = defence
	end

	local hasSend = tonumber(pb.targetId) > 0
	if hasSend then
		attack.flower = pb.attackFlower
		defence.flower = pb.defenceFlower

		self:SetBottomPlayer(self.mGroupPlayer,targetPlayer,targetPlayer.flower)


		self:SetPlayerInfo(self.mLeft,attack,pb.attackFlower)
		self:SetPlayerInfo(self.mRight,defence,pb.defenceFlower)
	end



	CS.ShowObject(self.mPart_1,not hasSend)
	CS.ShowObject(self.mPart_2,hasSend)


end

function UISSyendFlower:InitData()
	self._timeKey = "_timeKey"

	self._championTimer = "_championTimer"
end

function UISSyendFlower:GetEmo()
	if not self._record then
		return
	end

	local group = self._curGroup
	return self._record[group]
end

function UISSyendFlower:SetStaticContent()
	local str = ccLngText(gModelSimuFight:GetPara("groupName1"))
	self:SetWndTabText(self.mBtnPeak,str, -6, 20)
	local str = ccLngText(gModelSimuFight:GetPara("groupName2"))
	self:SetWndTabText(self.mBtnElite,str,-6, 20)

	str = ccClientText(25177)--"默认"
	self:SetWndText(self.mSortName,str)

	str =ccClientText(25303) --"列表详情"
	self:SetWndText(self.mListDetail,str)
end

function UISSyendFlower:OnWndRefresh()
	local battleInfo = self:GetWndArg("battleInfo")
	local flowerInfo = self:GetWndArg("flowerInfo")
	local groupType = self:GetWndArg("groupType")
	local wndType = self:GetWndArg("wndType") or UISSyendFlower.GROUP

	self._wndType = wndType
	self._battleInfo = battleInfo
	self._flowerInfo = flowerInfo

	CS.ShowObject(self.mChampionPart,wndType == 2)
	CS.ShowObject(self.mGroupPart,wndType ==1)

	if wndType == UISSyendFlower.GROUP then
		self._curGroup = groupType
		self:ShowGroupPart(battleInfo)
	else
		self._curGroup = groupType
		self._curOption = 1
		self:ShowChampionPart()
	end
end

function UISSyendFlower:ShowChampionCd()

	local state = gModelSimuFight:GetState()
	local isIng = true
	if state > ModelSimuFight.SCHEDULE_GROUP_WARM_UP then
		isIng = false
	end

	local combatState = gModelSimuFight:GetCombatState()
	if combatState > ModelSimuFight.BATTLE_READY then
		isIng = false
	end

	if not isIng then
		local str = ccClientText(25180)--"本次献花已结束"
		self:SetWndText(self.mTimeInfo,str)
		return false
	end

	local endTime = gModelSimuFight:GetNextStageTime()

	local timeLeft = endTime - GetTimestamp()
	if timeLeft>=0 then
		local timeStr = string.replace(ccClientText(25181),LUtil.FormatTimespanNumber(timeLeft))
		self:SetWndText(self.mTimeInfo,timeStr)
		return true
	else
		self:SetWndText(self.mTimeInfo,ccClientText(25180))
		return false
	end
end

function UISSyendFlower:InitUIEvent()

	self:SetWndClick(self.mBtnGroupSend,function ()
		self:OnClickGroupSend()
	end)

	self:SetWndClick(self.mBtnPeak,function ()
		self:OnClickGroup(1)
	end)

	self:SetWndClick(self.mBtnElite,function ()
		self:OnClickGroup(2)
	end)

	self:SetWndClick(self.mBtnEmo,function ()
		local isShow = not self._isShowEmo
		self:ShowEmoList(isShow)
	end)

	self:SetWndClick(self.mEmoBg,function ()
		self._isShowEmo = false
		self:ShowEmoList(false)
	end)



	self:SetWndClick(self.mBtnClose,function ()
		self:WndClose()
	end)

	self:SetWndClick(self.mShowListBtn,function ()
		self:ShowOption(true)
	end)

	self:SetWndClick(self.mSortFilterbg,function ()
		self:ShowOption(false)
	end)

	self:SetWndClick(self.mBtnChamSend,function ()
		self:OnClickChampionSend()
	end)

	self:SetWndClick(self.mMask,function ()
		self:WndClose()
	end)
end


function UISSyendFlower:OnDrawPlayer(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootImage = self:FindWndTrans(AniRoot,"Image")
	local AniRootHeadRoot = self:FindWndTrans(AniRoot,"headRoot")
	local AniRootName = self:FindWndTrans(AniRoot,"name")
	local AniRootPower = self:FindWndTrans(AniRoot,"power")
	local AniRootFlower = self:FindWndTrans(AniRoot,"flower")
	local AniRootBg = self:FindWndTrans(AniRoot,"bg")
	local bgIsOn = self:FindWndTrans(AniRootBg,"isOn")




	local headTran = self:FindWndTrans(AniRootHeadRoot,"HeadIcon")
	local playerInfo =
	{
		trans = headTran,
		icon = itemdata.head,
		headFrame = itemdata.headFrame,
		level = itemdata.grade,
		func = function()
			gModelGeneral:PlayerShowReq(itemdata.playerId,LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
		end,
	}

	self:CreateHeadIconImpl(playerInfo)

	local powerStr = string.replace(ccClientText(25193),LUtil.NumberCoversion(itemdata.power))
	self:SetWndText(AniRootPower,powerStr)
	local nameStr = string.replace(ccClientText(25287),itemdata.serverName,itemdata.name)
	self:SetWndText(AniRootName,nameStr)

	local flowerStr = string.replace(ccClientText(25285),itemdata.flower)
	self:SetWndText(AniRootFlower,flowerStr)

	self:SetWndClick(AniRoot,function ()
		self:OnSelectPlayer(itemdata.playerId)
	end)

	local isOn = self._curPlayerId == itemdata.playerId
	CS.ShowObject(bgIsOn,isOn)


	local hasSend = self._targetId and tonumber(self._targetId) > 0 or false

	CS.ShowObject(AniRootBg,not hasSend)
end

function UISSyendFlower:OnDrawEmo(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootImage = self:FindWndTrans(AniRoot,"Image")
	local AniRootSelect = self:FindWndTrans(AniRoot,"select")


	local emo = self:GetEmo()
	local isSel = emo == itemdata.refId
	CS.ShowObject(AniRootSelect,isSel)

	self:SetWndEasyImage(AniRootImage,itemdata.icon)
	self:SetWndClick(AniRoot,function ()
		self:SaveEmo(itemdata.refId)

		self:ShowEmoList(false)
		self:RefreshEmoSel()
	end)
end

function UISSyendFlower:ShowChampionPart()
	--self._curGroup = 1

	local imag= "simulate_txt_3"
	self:SetWndEasyImage(self.mTitle,imag)

	self:RefreshGroupBtnShow()
	self:ReqPlayerList()

	self:TimerStop(self._championTimer)
	if self:ShowChampionCd() then
		self:TimerStart(self._championTimer,1,false,-1)
	end

	self:RefreshFlowerNumShow()
	self:RefreshEmoSel()
end

function UISSyendFlower:RefreshEmoSel()
	local emo = self:GetEmo()
	if emo then
		local ref = gModelSimuFight:GetEmoRef(emo)
		self:SetWndEasyImage(self.mSelEmo,ref.icon)
	end
	CS.ShowObject(self.mEmoAdd,emo == nil)
	CS.ShowObject(self.mSelEmo,emo~= nil)

	local list = self:FindUIScroll("emoList")
	if list then
		list:DrawAllItems(false)
	end
end



--function UISSyendFlower:OnSelectPlayer(value,isLeft)
--	local index = isLeft and 1 or 2
--	self._curSelect = value and index or 0
--	self:RefreshToggle()
--
--	if value then
--		local str = "在下方进行献花"
--		GF.ShowMessage(str)
--	end
--end

function UISSyendFlower:SetPlayerInfo(item,playerData,flowerNum)
	local headRoot = self:FindWndTrans(item,"headRoot")
	local name = self:FindWndTrans(item,"name")
	local server = self:FindWndTrans(item,"server")
	local flower = self:FindWndTrans(item,"flower")
	local power = self:FindWndTrans(item,"power")
	local select = self:FindWndTrans(item,"select")
	local selectBg = self:FindWndTrans(select,"bg")
	local selectIsOn = self:FindWndTrans(select,"isOn")

	CS.ShowObject(selectIsOn,self._curPlayerId == playerData.playerId)


	local headTran = self:FindWndTrans(headRoot,"HeadIcon")
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


	local serverName =  string.format("[%s]",playerData.serverName)
	self:SetWndText(server,serverName)

	local flowerStr = string.replace(ccClientText(25285),flowerNum)
	self:SetWndText(flower,flowerStr)

	local powerStr = string.replace(ccClientText(25193),LUtil.NumberCoversion(playerData.power))
	self:SetWndText(power,powerStr)

	self:SetWndText(name,playerData.name)

	self:SetWndClick(select,function ()
		self._curPlayerId = playerData.playerId

		self:RefreshGroupSel()
	end)
end

function UISSyendFlower:OnDrawOption(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootImage = self:FindWndTrans(AniRoot,"Image")
	local AniRootSelImg = self:FindWndTrans(AniRoot,"SelImg")
	local AniRootName = self:FindWndTrans(AniRoot,"Name")
	local AniRootSelName = self:FindWndTrans(AniRoot,"SelName")


	local isSel = self._curOption == itemdata.index
	CS.ShowObject(AniRootSelImg,isSel)
	CS.ShowObject(AniRootName,not isSel)
	CS.ShowObject(AniRootSelName,isSel)

	self:SetWndClick(AniRoot,function ()
		self:OnClickOption(itemdata)
	end)

	self:SetWndText(AniRootName,itemdata.name)
	self:SetWndText(AniRootSelName,itemdata.name)

end

function UISSyendFlower:OnClickGroupSend()
	if self._wndType ~= UISSyendFlower.GROUP then
		return
	end

	local playerId = self._curPlayerId
	if self._curPlayerId == 0 then
		local str =ccClientText(25182)-- "请选择献花的梦境者"
		GF.ShowMessage(str)
		return
	end

	gModelSimuFight:OnSimulateFlowerReq(playerId,1,self._curGroup,nil,self._battleInfo.id)


end


function UISSyendFlower:ShowEmoList(isShow)

	CS.ShowObject(self.mEmoBg,isShow)

	if not isShow then
		return
	end
	local uiList = self:FindUIScroll("emoList")
	if not uiList then
		local dataList = gModelSimuFight:GetEmoList()
		uiList = self:GetUIScroll("emoList")
		uiList:Create(self.mEmoList,dataList,function (...) self:OnDrawEmo(...) end)
	end
end

function UISSyendFlower:RefreshChamList()
	self:SortByOption()

	local uiList = self:FindUIScroll("playerList")
	if not uiList then
		uiList = self:GetUIScroll("playerList")
		uiList:Create(self.mItemList,self._playerDataList,function (...) self:OnDrawPlayer(...) end,UIItemList.SUPER)
	else
		uiList:RefreshList(self._playerDataList)
	end

	uiList:DrawAllItems(false)
end

function UISSyendFlower:OnSimulateFlowerResp(pb)
	local flowerInfo = pb.info
	if self._wndType ~= flowerInfo.type then
		return
	end



	if self._wndType == UISSyendFlower.GROUP then
		self._flowerInfo = flowerInfo
		self:OnHasSendFlowerGroup()
	else
		self._targetId = flowerInfo.targetId
		self:OnHasSendCham(flowerInfo.attackFlower)

		local list = self:FindUIScroll("playerList")
		if list then
			list:DrawAllItems(false)
		end
	end

	local str = ccClientText(25178)--"献花成功"
	GF.ShowMessage(str)
end


function UISSyendFlower:OnHasSendCham(flowerNum)
	local targetId = self._targetId
	local playerData =self._playerMap and self._playerMap[targetId]

	local hasSend = playerData~= nil
	if hasSend then
		if flowerNum then
			playerData.flower = flowerNum
		end
		self:SetBottomPlayer(self.mPlayer,playerData,playerData.flower)
	end

	CS.ShowObject(self.mPart_3,not hasSend)
	CS.ShowObject(self.mPart_4,hasSend)

end

function UISSyendFlower:OnTimer(key)
	if key == self._timeKey then
		self:ShowCountDown()
	elseif key == self._championTimer then
		self:ShowChampionCd()
	end
end


function UISSyendFlower:ShowGroupPart(battleInfo)
    local groupName = nil
    if self._curGroup == ModelSimuFight.GROUP_PINNACLE then
        groupName = ccLngText(gModelSimuFight:GetPara("groupName1"))
    else
        groupName = ccLngText(gModelSimuFight:GetPara("groupName2"))
    end

    local str = string.replace(ccClientText(25304),groupName,gModelSimuFight:GetRoundStr(battleInfo.round))

    self:SetWndText(self.mStageInfo,str)
	self:SetWndEasyImage(self.mTitle,"simulate_txt_7")

	local str =  ccClientText(25179)--"选择其中一位参赛者献上鲜花~"
	self:SetWndText(self.mIntro,str)

	self:OnHasSendFlowerGroup()

	self._curPlayerId = 0

	self._leftPlayerId = battleInfo.attack.playerId
	self._rightPlayerId = battleInfo.defense.playerId

	self:SetPlayerInfo(self.mLeft,battleInfo.attack,battleInfo.attackFlower)
	self:SetPlayerInfo(self.mRight,battleInfo.defense,battleInfo.defenceFlower)

	self:TimerStop(self._timeKey)
	if self:ShowCountDown() then
		self:TimerStart(self._timeKey,1,false,-1)
	end

	self:RefreshFlowerNumShow()
end

function UISSyendFlower:RefreshGroupBtnShow()
	local state = self._curGroup == 1 and LWnd.StateOn or LWnd.StateOff
	self:SetWndTabStatus(self.mBtnPeak,state)
	local state = self._curGroup == 2 and LWnd.StateOn or LWnd.StateOff
	self:SetWndTabStatus(self.mBtnElite,state)
end

function UISSyendFlower:OnSimulateLikeListResp(pb)
	if self._curGroup ~= pb.group then
		return
	end

	local playerDataList = {}

	self._targetId = pb.targetId

	local playerMap = {}
	for k,v in ipairs(pb.infos) do
		local data = StructPlayerData:New()
		data:CreateByPb(v)
		data.flower = pb.flowers[k]

		--data.default = k

		table.insert(playerDataList,data)

		playerMap[data.playerId] = data
	end

	self._playerDataList = playerDataList

	self._playerMap = playerMap

	self:RefreshChamList()

	self:OnHasSendCham()

	self:RefreshEmoSel()

end

function UISSyendFlower:OnClickGroup(index)

	if index == self._curGroup then
		return
	end

	self._curGroup = index

	self:RefreshGroupBtnShow()
	self:RefreshFlowerNumShow()
	self:ReqPlayerList()
end

------------------------------------------------------------------
return UISSyendFlower


