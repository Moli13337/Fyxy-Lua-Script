---
--- Created by Administrator.
--- DateTime: 2023/10/24 10:43:00
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubPkFinal:LChildWnd
local UISubPkFinal = LxWndClass("UISubPkFinal", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubPkFinal:UISubPkFinal()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubPkFinal:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubPkFinal:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubPkFinal:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()


	self:InitData()
	self:InitView()
	self:InitEvent()
end
function UISubPkFinal:ShowLineEff(trans, idx, bShow)
	if not bShow or CS.IsNullObject(trans) then
		self:DestroyWndEffectByKey(tostring(idx))
		return
	end
	local effCfgs = {
		[1] = {eff = "fx_saicheng_04", pos = Vector3.New(0, -34, 0)},
		[2] = {eff = "fx_saicheng_05", pos = Vector3.New(77, 5.4, 0)},
	}
	local effCfg = nil
	if idx < 5 then
		effCfg = effCfgs[1]
	else
		effCfg = effCfgs[2]
	end

	if effCfg then
		self:CreateWndEffect(trans, effCfg.eff, tostring(idx), 100, false, false, nil, nil, nil, nil, nil,
				function(dpTrans)
					if not dpTrans then
						return
					end
					dpTrans.localPosition = effCfg.pos
				end
		)

	end

end
function UISubPkFinal:SetBtns(btndatas)
	local btnList = self._groupBtns
	local default ={
		isBefore = true
	}

	self:DestroyWndEffectByKey("fx_guanjunsai_shaizi")

	for k,v in ipairs(btnList) do
		local btndata = btndatas[k] or default
		local text = self:FindWndTrans(v,"text")
		if btndata.isAfter then
			self:SetWndEasyImage(v,self._btnPathList[1][1])
			self:SetWndClick(v,function () self:Watch(btndata) end,LSoundConst.CLICK_BUTTON_COMMON)
			self:SetWndText(text,self._btnPathList[1][2])
		elseif btndata.isBetting then
			self:SetWndEasyImage(v,self._btnPathList[2][1])
			self:SetWndClick(v,function () self:OpenBetting() end,LSoundConst.CLICK_BUTTON_COMMON)
			self:SetWndText(text,self._btnPathList[2][2])
			if k == 3 then
				self:CreateWndEffect(v,"fx_guanjunsai_shaizi", "fx_guanjunsai_shaizi",128,false,false)
			else
				self:CreateWndEffect(v,"fx_guanjunsai_shaizi", "fx_guanjunsai_shaizi",100,false,false)
			end
		end

		CS.ShowObject(v,not btndata.isBefore or btndata.isBetting)
	end

end
function UISubPkFinal:OnStateUpdate()
	gModelArena:PinnaclePaceScheduleReq(2)
end

function UISubPkFinal:InitSchedule()
	local lineRoot = self:FindWndTrans(self.mLineGroup,"dynaLine")
	self._groupLines = {}
	for i=1,14 do
		local line = self:FindWndTrans(lineRoot,"line_"..i)
		table.insert(self._groupLines,line)
	end

	local btnRoot = self:FindWndTrans(self.mLineGroup,"btns")
	self._groupBtns = {}
	for i=1,7 do
		local btn = self:FindWndTrans(btnRoot,"midBtn_"..i)
		table.insert(self._groupBtns,btn)
	end

	self._playerTrans = {}
	for i = 1,8 do
		local tran = self:FindWndTrans(self.mPlayerList,"player_"..i)
		table.insert(self._playerTrans,tran)
	end

	self._btnPathList=
	{
		{"public_btn_pass_1",ccClientText(11844)},
		{"actionarena_btn_4",ccClientText(11855)}
	}
end

function UISubPkFinal:FormatScheduleLineData(infos,isGroup)
    local linesData={}
    local cnt = isGroup and 7 or 7
    local result = nil

    local winnerId = {}
    for i =1,cnt do
        local data = infos[i]
        if data then
            local isEnd = gModelArena:GetCombatIsEnd(data.round)
            result = isEnd and data.winner or 0

            if result == 1 then
                winnerId[i] = data.attack.playerId
            elseif result ==2 then
                winnerId[i] = data.defense.playerId
            end
            -- if isGroup then
                if i ==5  then
                    if winnerId[1]~= data.attack.playerId then
                        result = gModelArena:ConvertResult(result)
                    end
                elseif i==6 then
                    if winnerId[3]~= data.attack.playerId then
                        result = gModelArena:ConvertResult(result)
                    end
                elseif i==7 then
                    if winnerId[5] ~=  data.attack.playerId then
                        result = gModelArena:ConvertResult(result)
                    end
                end
            -- else
                -- if i== 3 then
                --     if winnerId[1]~= data.attack.playerId then
                --         result = gModelArena:ConvertResult(result)
                --     end
                -- end
            -- end

        else
            result= 0
        end
        linesData[i]= result
    end
    return linesData
end

function UISubPkFinal:SortFinal(infos)
	local list = {}
	for k,v in ipairs(infos) do
		table.insert(list,v)
	end
	if list[2] and list[4] then
		local temp = list[2]
		list[2] = list[4]
		list[4] = temp
	end
	-- table.sort(list,function (a,b) return a.round <b.round end)
	return list

end
function UISubPkFinal:InitView()
	self:InitSchedule()
	gModelArena:PinnaclePaceScheduleReq(2)
end
function UISubPkFinal:ShowEmpty()
	local playerList = gModelArena:FormatSchedulePlayerList({},false)
	self:InitPlayerList(playerList)
	self:ShowLines({})
	self:SetBtns({})
	self:ShowWinner()
end
function UISubPkFinal:ShowWinner(isGroup,winnerdata)
	local item = self.mWinner
	local bg = self:FindWndTrans(item,"bg")
	local mask = self:FindWndTrans(item,"mask")
	--local maskHead = self:FindWndTrans(mask,"head")
	local text = self:FindWndTrans(item,"text")
	local textE = self:FindWndTrans(item,"textE")
	local textTrans = self._isEnglish and textE or text
	local name = self:FindWndTrans(item,"name")
	--local lvBg = self:FindWndTrans(item,"lvBg")
	--local level = self:FindWndTrans(item,"level")
	local effRoot = self:FindWndTrans(item,"effRoot")
	local unknow = self:FindWndTrans(item,"unKonw")
	self:InitTextSizeWithLanguage(textTrans,-8)

	local isEmpty = not winnerdata
	CS.ShowObject(mask,not isEmpty)
	CS.ShowObject(textTrans,isEmpty)
	CS.ShowObject(name,not isEmpty)
	CS.ShowObject(bg,isEmpty)
	if isEmpty then
		CS.ShowObject(unknow,true)
		self:DestroyWndEffectByKey("winnerEffect")
		--CS.ShowObject(mask,false)
		local str =ccClientText(11892)-- "总冠军")--ccClientText(11856)
		if isGroup then
			str =ccClientText(11856) --"虚位以待"
		end
		self:SetWndText(textTrans,str)
		--CS.ShowObject(textTrans,true)
		--CS.ShowObject(name,false)
		--CS.ShowObject(lvBg,false)
		--CS.ShowObject(level,false)
		return
	end
	CS.ShowObject(unknow,false)
	self:CreateWndEffect(effRoot,"fx_guanjun","winnerEffect",100)


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
		level = winnerdata.player.grade,
	}
	baseClass:SetHeadData(playerData)
	baseClass:RefreshUI()

	self:SetWndClick(headTran, function ()
		gModelGeneral:PlayerShowReq(winnerdata.player.playerId,LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
	end)
end
function UISubPkFinal:OnDrawItem(item,itemdata)
	local bg = self:FindWndTrans(item,"bg")
	local root = self:FindWndTrans(item,"root")
	--local rootHead = self:FindWndTrans(root,"head")
	local rootName = self:FindWndTrans(root,"name")
	--local rootLevel = self:FindWndTrans(root,"level")
	local text = self:FindWndTrans(item,"text")
	local textE = self:FindWndTrans(item,"textE")
	local unknow = self:FindWndTrans(item,"unKonw")
	local textTrans = self._isEnglish and textE or text
	--local textMask = self:FindWndTrans(textTrans,"mask")

	local isEmpty = itemdata.isEmpty
	CS.ShowObject(root,not isEmpty)
	CS.ShowObject(textTrans,isEmpty)
	CS.ShowObject(unknow, isEmpty)
	CS.ShowObject(bg,isEmpty)
	self:InitTextSizeWithLanguage(textTrans,-10)
	if isEmpty then
		local str =ccClientText(11856)-- "虚位以待"
		self:SetWndText(textTrans,str)
		return
	end

	--self:SetWndText(rootLevel,itemdata.grade)
	self:SetWndText(rootName,itemdata.name)

	-- 玩家头像
	local headTran = self:FindWndTrans(root,"HeadIcon")
	local instanceId = headTran:GetInstanceID()
	local baseClass = self:GetHeadIcon(instanceId)
	local playerData =
	{
		trans = headTran,
		icon = itemdata.head,
		headFrame = itemdata.headFrame,
		level = itemdata.grade,
	}
	baseClass:SetHeadData(playerData)
	baseClass:RefreshUI()

	self:SetWndClick(headTran, function ()
		gModelGeneral:PlayerShowReq(itemdata.playerId,LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
	end)

end
function UISubPkFinal:InitData()
	self._isEnglish =  gLGameLanguage:IsForeignVersion()

end
function UISubPkFinal:Watch(data)

	local reportId= data.reportId
	local round = data.round
	if reportId then

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
end
function UISubPkFinal:ShowLines(linesData)
	local lines = self._groupLines
	local cnt = 14


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
function UISubPkFinal:InitEvent()
	self:WndNetMsgRecv(LProtoIds.PinnaclePaceScheduleResp,function (...) self:OnScheduleUpdate(...) end)
	self:WndEventRecv(EventNames.ON_PEAK_STATE_CHANGE,function (...) self:OnStateUpdate(...) end)
end
function UISubPkFinal:OnPlayEnd(pagePara)
	GF.ChangeMap("LCityMap")
	FireEvent(EventNames.ONLY_CHANGE_MAIN_BTN_ON,{index =LMainBtnIndexConst.OUTSKIRTS})

	GF.OpenWndBottom("UIOutts",{childIndex=2})
	GF.OpenWndBottom("UIringPk",{page=pagePara.page,para =pagePara.para})
end

function UISubPkFinal:OnScheduleUpdate(pb)
	local type = pb.type
	if type ~= 2 then
		return
	end

	local sortedList = pb.infos
	if #sortedList==0 then
		self:ShowEmpty()
		return
	end
	sortedList = self:SortFinal(pb.infos)

	local isGroup = false
	local playerdatas = gModelArena:FormatSchedulePlayData(sortedList,isGroup)
	local playerList = gModelArena:FormatSchedulePlayerList(playerdatas,isGroup)
	self:InitPlayerList(playerList)
	-- local linesdata = gModelArena:FormatScheduleLineData(sortedList,isGroup)
	local linesdata = self:FormatScheduleLineData(sortedList,isGroup)
	self:ShowLines(linesdata)
	local winnerData = gModelArena:FormatScheduleWinnerData(sortedList,isGroup)
	self:ShowWinner(isGroup,winnerData)
	local btndatas = gModelArena:FormatScheduleBtnsData(sortedList,pb.guessId,isGroup)
	self:SetBtns(btndatas)

end
function UISubPkFinal:OpenBetting()
	GF.OpenWnd("UIringPkGuess")
end


function UISubPkFinal:InitPlayerList(playerList)
	for k,v in ipairs(playerList) do
		local tran  = self._playerTrans[k]
		self:OnDrawItem(tran,v)
	end
end


function UISubPkFinal:OpenPart()
	gModelArena:PinnaclePaceScheduleReq(2)
end

------------------------------------------------------------------
return UISubPkFinal


