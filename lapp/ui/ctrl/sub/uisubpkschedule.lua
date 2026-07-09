---
--- Created by Administrator.
--- DateTime: 2023/10/23 17:38:02
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubPkSchedule:LChildWnd
local UISubPkSchedule = LxWndClass("UISubPkSchedule", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubPkSchedule:UISubPkSchedule()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubPkSchedule:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubPkSchedule:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubPkSchedule:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:InitView()
	self:InitEvent()
end
function UISubPkSchedule:WndOnGuessChange(groupIndex)
	-- guess
	local guess = nil
	for k,v in ipairs(self._btnList) do
		guess = self:FindWndTrans(v,"guess")
		if groupIndex == k then
			CS.ShowObject(guess,true)
		else
			CS.ShowObject(guess,false)
		end

	end
end

function UISubPkSchedule:OnScheduleUpdate(pb)
	local type = pb.type
	if type ~= 1 then
		return
	end

	local group = pb.group
	if self._curSelect.index == -1 then
		local select = {type = type,index = group}
		self:WndOnSelectChange(select)
	else
		if self._curSelect.type ~=type or self._curSelect.index ~=group then
			return
		end
	end

	local isGroup = true

	local sortedList = pb.infos
	if #sortedList==0 then
		self:ShowEmpty(isGroup)
		return
	end

	sortedList = self:SortCombatResult(pb.infos) --调整顺序

	local playerdatas = gModelArena:FormatSchedulePlayData(sortedList,isGroup)
	local playerList = gModelArena:FormatSchedulePlayerList(playerdatas,isGroup)
	self:InitPlayerList(playerList)
	local linesdata = gModelArena:FormatScheduleLineData(sortedList,isGroup)
	self:ShowLines(linesdata)
	local winnerData = gModelArena:FormatScheduleWinnerData(sortedList,isGroup)
	self:ShowWinner(isGroup,winnerData)
	local btndatas = gModelArena:FormatScheduleBtnsData(sortedList,pb.guessId,isGroup)
	self:SetBtns(btndatas)

end
function UISubPkSchedule:InitSchedule()
	local lineRoot = self:FindWndTrans(self.mLineGroup,"dynaLine")
	self._groupLines = {}
	for i=1,14 do
		local line = self:FindWndTrans(lineRoot,"line_"..i)
		table.insert(self._groupLines,line)
	end

	local btnRoot = self:FindWndTrans(self.mLineGroup,"btns")
	self._groupBtns = {}
	for i=1,8 do
		local btn = self:FindWndTrans(btnRoot,"midBtn_"..i)
		table.insert(self._groupBtns,btn)
	end

	self._btnPathList=
	{
		{"public_btn_pass_1",ccClientText(11844)},
		{"actionarena_btn_4",ccClientText(11855)}
	}
end
function UISubPkSchedule:OpenPart(selData)
	local changed = self:WndOnSelectChange(selData)
	if not changed then
		return
	end

	local wnd = GF.FindFirstWndByName("UIringPk")
	if wnd then
		wnd:SavePagePara(selData.index)
	end
	gModelArena:PinnaclePaceScheduleReq(selData.type,selData.index)
end
function UISubPkSchedule:InitEvent()
	self:WndNetMsgRecv(LProtoIds.PinnaclePaceScheduleResp,function (...) self:OnScheduleUpdate(...) end)
	self:WndEventRecv(EventNames.ON_PEAK_STATE_CHANGE,function (...) self:OnStateUpdate(...) end)
end
function UISubPkSchedule:OpenBetting()
	GF.OpenWnd("UIringPkGuess")
end
function UISubPkSchedule:ShowEmpty(isGroup)
	local playerList = gModelArena:FormatSchedulePlayerList({},isGroup)
	self:InitPlayerList(playerList,isGroup)
	self:ShowLines({},isGroup)
	self:SetBtns({},isGroup)
	self:ShowWinner(isGroup)
end
function UISubPkSchedule:InitPlayerList(playerList,isGroup)
	isGroup = true
	local uiList = self._uiList
	if not uiList then
		uiList = UIListEasy:New()
		uiList:Create(self,self.mChartPlayerList)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrawItem(...)
		end)
		self._uiList = uiList
	end
	uiList:RemoveAll()
	for k,v in ipairs(playerList) do
		uiList:AddData(k,v)
	end
	uiList:RefreshList()

end
function UISubPkSchedule:InitGroupBtn()
	local btnCount = self.mGroupBtns.childCount
	for i = 1, btnCount do
		local btn = self:FindWndTrans(self.mGroupBtns,"group"..i)
		self._btnList[i] = btn
		self:SetWndClick(btn,function()
			local selectData = {}
			selectData.type = 1
			selectData.index = i

			self:OpenPart(selectData)
		end)
		CS.ShowObject(btn, true)
	end
end
function UISubPkSchedule:ShowLineEff(trans, idx, bShow)
	if not bShow or CS.IsNullObject(trans) then
		self:DestroyWndEffectByKey(tostring(idx))
		return
	end
	local effCfgs = {
		[1] = {eff = "fx_saicheng_01", pos = Vector3.New(26, -34, 0)},
		[2] = {eff = "fx_saicheng_02", pos = Vector3.New(21, -67, 0)},
		[3] = {eff = "fx_saicheng_03", pos = Vector3.New(-30, 0, 0)}
	}
	local effCfg = nil
	if idx < 9 then
		effCfg = effCfgs[1]
	elseif idx < 13 then
		effCfg = effCfgs[2]
	else
		effCfg = effCfgs[3]
	end

	if effCfg then
		self:CreateWndEffect(trans, effCfg.eff, tostring(idx), 100, false, false, nil, nil, nil, nil, nil,
				function(dpTrans)
					if CS.IsNullObject(dpTrans) then
						return
					end

					dpTrans.localPosition = effCfg.pos
				end
		)
	end

end
function UISubPkSchedule:SetBtns(btndatas,isGroup)
	local btnList = self._groupBtns
	isGroup = true
	local default ={
		isBefore = true
	}

	self:DestroyWndEffectByKey("fx_guanjunsai_shaizi")

	for k,v in ipairs(btnList) do
		local btndata = btndatas[k] or default
		local text = self:FindWndTrans(v,"text")
		if btndata.isAfter then
			self:SetWndEasyImage(v,self._btnPathList[1][1])
			self:SetWndClick(v,function () self:Watch(btndata) end)
			self:SetWndText(text,self._btnPathList[1][2])
		elseif btndata.isBetting then
			self:SetWndEasyImage(v,self._btnPathList[2][1])
			self:SetWndClick(v,function () self:OpenBetting() end)
			self:SetWndText(text,self._btnPathList[2][2])
			if k == 7 then
				self:CreateWndEffect(v,"fx_guanjunsai_shaizi", "fx_guanjunsai_shaizi",128,false,false)
			else
				self:CreateWndEffect(v,"fx_guanjunsai_shaizi", "fx_guanjunsai_shaizi",100,false,false)
			end
		end

		CS.ShowObject(v,not btndata.isBefore or btndata.isBetting)
	end

end
function UISubPkSchedule:Watch(data)

	local reportId= data.reportId
	local round = data.round
	if not reportId then
		printInfoNR("reportId is a nil, round = "..(round or "nil"))
		return
	end

	local arenaCombatInfo = data.arenaCombatInfo
	local canSkip = gModelArena:GetCombatIsEnd(round)
	local wnd = GF.FindFirstWndByName("UIringPk")
	local pagePara = wnd:GetPagePara()
	local state = gModelArena:GetPeakCombatState()
	local curRound = gModelArena:GetPeakRound()
	local passTime
	if state == ModelArena.PEAK_BATTLE_STATE_FIGHTING and curRound == round then
		passTime = math.ceil(gModelArena:GetNextCombatStateTime() - GetTimestamp()) + 1
	end

	local combatExtraDatas = {
		battleEndfun = function() self:OnPlayEnd(pagePara)  end,
		canSkip = canSkip,
		meName = data.leftName,
		otherName =data.rightName,
		videoType = LVideoTypeConst.PEAK,
		waitEndPassTime = passTime or 0,
	}

	GF.OpenWnd("UIVdoPop",
			{videoInfo = arenaCombatInfo, openEnum = ModelVideoCenter.OpenEnumArena, combatExtraDatas = combatExtraDatas})

	--gLFightManager:OnPlayBattleVideo(reportId,combatExtraDatas,LCombatTypeConst.COMBAT_BATTLE_VIDEO)
	--GF.CloseWndByName("UIringPk")
end
function UISubPkSchedule:OnDrawItem(list,item,itemdata,itempos)
	local bg = self:FindWndTrans(item,"bg")
	local root = self:FindWndTrans(item,"root")
	local rootName = self:FindWndTrans(root,"name")
	--local rootInfo = self:FindWndTrans(root,"info")
	--local infoMask = self:FindWndTrans(rootInfo,"mask")
	--local rootLvBg = self:FindWndTrans(root,"lvBg")
	--local rootLevel = self:FindWndTrans(root,"level")
	local text = self:FindWndTrans(item,"text")
	local unknow = self:FindWndTrans(item,"unKonw")
	--local textMask = self:FindWndTrans(text,"mask")




	CS.ShowObject(root,not itemdata.isEmpty)
	CS.ShowObject(unknow, itemdata.isEmpty)
	CS.ShowObject(text,itemdata.isEmpty)
	CS.ShowObject(bg,itemdata.isEmpty)
	--CS.ShowObject(rootLvBg,not itemdata.isEmpty)
	self:InitTextSizeWithLanguage(text,-10)
	if itemdata.isEmpty then
		local str =ccClientText(11856)-- "虚位以待"
		self:SetWndText(text,str)
		return
	end
	--self:SetWndText(rootLevel,itemdata.grade)
	self:SetWndText(rootName,itemdata.name)

	local headTran = self:FindWndTrans(root,"HeadIcon")
	local instanceId =headTran:GetInstanceID()
	local headClass = self:GetHeadIcon(instanceId)
	local playerData={
		trans=headTran,
		icon=itemdata.head,
		headFrame=itemdata.headFrame,
		level = itemdata.grade,
	}
	headClass:SetHeadData(playerData)
	headClass:RefreshUI()

	self:SetWndClick(headTran, function ()
		gModelGeneral:PlayerShowReq(itemdata.playerId,LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
	end)


end
function UISubPkSchedule:InitView()

	self:InitGroupBtn()
	self:InitSchedule()

	local groupIndex = self._groupIndex or 1
	local selectData = {}

	selectData.type = 1
	selectData.index = groupIndex

	self:OpenPart(selectData)
end
function UISubPkSchedule:ShowWinner(isGroup,winnerdata)
	local item = self.mWinner
	local bg = self:FindWndTrans(item,"bg")
	local mask = self:FindWndTrans(item,"mask")
	--local maskHead = self:FindWndTrans(mask,"head")
	local crown = self:FindWndTrans(item,"crown")
	local crownEnd = self:FindWndTrans(item,"crownEnd")
	local text = self:FindWndTrans(item,"text")
	local name = self:FindWndTrans(item,"name")
	local unknow = self:FindWndTrans(item,"unKonw")
	--local lvBg = self:FindWndTrans(item,"lvBg")
	--local level = self:FindWndTrans(item,"level")
	self:InitTextSizeWithLanguage(text,-10)

	local isEmpty = not winnerdata
	CS.ShowObject(bg,isEmpty)
	CS.ShowObject(mask,not isEmpty)
	CS.ShowObject(text,isEmpty)
	CS.ShowObject(name,not isEmpty)
	if isEmpty then
		CS.ShowObject(mask,false)
		CS.ShowObject(unknow,true)
		local str =ccClientText(11892)-- "总冠军")--ccClientText(11856)
		if isGroup then
			str =ccClientText(11856) --"虚位以待"
		end
		self:SetWndText(text,str)
		--CS.ShowObject(text,true)
		--CS.ShowObject(name,false)
		--CS.ShowObject(lvBg,false)
		--CS.ShowObject(level,false)
		return
	end

	CS.ShowObject(unknow,false)
	CS.ShowObject(crown, isGroup)
	-- CS.ShowObject(crownEnd, not isGroup)

	--CS.ShowObject(text,false)
	--CS.ShowObject(mask,true)
	--CS.ShowObject(name,true)
	--CS.ShowObject(lvBg,true)
	--CS.ShowObject(level,true)
	self:SetWndText(name,winnerdata.player.name)
	--self:SetWndText(level,winnerdata.player.grade)


	local headTran = self:FindWndTrans(mask,"HeadIcon")
	local instanceId = headTran:GetInstanceID()
	local baseClass = self:GetHeadIcon(instanceId)
	local playerData =
	{
		trans = headTran,
		icon = winnerdata.player.head,
		headFrame = winnerdata.player.headFrame,
		level= winnerdata.player.grade,
	}
	baseClass:SetHeadData(playerData)
	baseClass:RefreshUI()

	self:SetWndClick(headTran, function ()
		gModelGeneral:PlayerShowReq(winnerdata.player.playerId,LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
	end)

end
function UISubPkSchedule:SortCombatResult(infos)
	local t = {}
	local priority =nil
	local index = nil
	local leftPlayerIds ={}
	for k,v in ipairs(infos) do
		priority = 2

		if k >=1 and k<=4 then
			if k==1 or k==3 then
				local playerId = v.attack.playerId
				leftPlayerIds[playerId] = true
				playerId = v.defense.playerId
				leftPlayerIds[playerId] = true
			end
			index =k
			if k==2 then
				index =3
			elseif k==3 then
				index = 2
			end
		elseif k ==5 or k==6 then
			local playerId = v.attack.playerId
			if leftPlayerIds[playerId] then
				priority = 1
			end
			index = 5
		elseif k== 7 then
			index = 7
		end



		local data = {}
		data.index = index
		data.priority = priority
		data.combatResult = v

		table.insert(t,data)
	end
	table.sort(t,function(a,b)
		if a.index~=b.index then
			return a.index<b.index
		else
			return a.priority<b.priority
		end
	end)

	local ret ={}
	for k,v in ipairs(t) do
		table.insert(ret,v.combatResult)
	end

	return ret
end
function UISubPkSchedule:ShowLines(linesData,isGroup)
	isGroup = true
	local lines = self._groupLines
	local cnt = 7
	if isGroup then
		lines = self._groupLines
		cnt = 7
	end

	CS.ShowObject(self.mLineGroup, true)
	local isUp =nil
	local showUp = nil
	local showDown = nil
	for i = 1,cnt do
		showUp = false
		showDown = false
		isUp = linesData[i] or 0
		if isUp==1 then
			showUp= true
		elseif isUp ==2 then
			showDown = true
		end
		local upIndex = 2*i-1
		local downIndex = 2*i
		CS.ShowObject(lines[upIndex],showUp)
		CS.ShowObject(lines[downIndex],showDown)

		-- self:ShowLineEff(lines[upIndex], upIndex, showUp)
		-- self:ShowLineEff(lines[downIndex], downIndex, showDown)
	end
end
function UISubPkSchedule:OnStateUpdate()
	local oldSelect = self._curSelect
	self._curSelect = nil
	self:OpenPart(oldSelect)
end
function UISubPkSchedule:InitData()
	self._btnList = {}
	self._groupIndex = self:GetWndArg("groupIndex")

end
function UISubPkSchedule:OnPlayEnd(pagePara)
	GF.ChangeMap("LCityMap")
	GF.OpenWndBottom("UIringPk",{page=pagePara.page,para =pagePara.para})
end
function UISubPkSchedule:WndOnSelectChange(selectData)
	if not self._btnList then
		return false
	end
	local oldSelect = self._curSelect
	if oldSelect then
		if oldSelect.type ==selectData.type and oldSelect.index == selectData.index then
			return false
		end
	end
	self._curSelect = selectData
	local select =nil
	if oldSelect and oldSelect.type == 1 then
		if oldSelect.index == -1 then
			for k,v in ipairs(self._btnList) do
				select = self:FindWndTrans(v,"select")
				CS.ShowObject(select,false)
			end
		else
			local root = self._btnList[oldSelect.index]
			select = self:FindWndTrans(root,"select")
			CS.ShowObject(select,false)
		end
	else
		for k,v in ipairs(self._btnList) do
			select = self:FindWndTrans(v,"select")
			CS.ShowObject(select,false)
		end
	end

	if selectData.type == 1 then
		local root = self._btnList[selectData.index]
		if root then
			select = self:FindWndTrans(root,"select")
		end
	end
	CS.ShowObject(select,true)

	return true
end




------------------------------------------------------------------
return UISubPkSchedule


