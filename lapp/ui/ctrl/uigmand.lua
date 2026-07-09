---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGMand:LWnd
local UIGMand = LxWndClass("UIGMand", LWnd)
local typeof = typeof
local typeGridLayoutGroup = typeof(CS.GridLayoutGroup)

local HISTORY_PATH = CS.AppPersistentDataPath() .. "gm_history.json"
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGMand:UIGMand()
	self._resultList = {}
	self._typeToNameMap = {}

	self._delayUpdateScrollTimer = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGMand:OnWndClose()
	self:StopMessageTimer()
	self:WriteHistoryToFile()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGMand:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGMand:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitMessage()
	self:InitGroupList()
	self:InitShowCmd()
end


function UIGMand:ChangeCloudInfo(arrCmd)
	local effId = checknumber(arrCmd[1])
	local info = arrCmd[2] or ""
	local infos = string.split(info,"|")
	gModelHeroExtra:SetHeroDrawingAllAgesData(effId,infos)
	printInfoNR("修改云朵数据成功")
end

function UIGMand:OnClickBtnExcute(needSend)
	local cmd = self._selCmdStr
	if string.isempty(cmd) then return end
	local args = self.mQuickNumInput.text
	local cmdStr = cmd .. " "..args
	self:ShowDebugReturn("S:"..cmdStr)

	local cmdData = self._selCmdData

	if gModelGM then
		gModelGM:RecordLastGMCmd(cmdData.command)
	end
	self:AddGmCmdHistory(cmdData.type, cmdData.command, args)

	local arrCmd = string.split(args, " ")
	local cmdFunc = cmdData.execute
	local func = cmdFunc
	if func ~= nil and not needSend then
		func(self, arrCmd)
	else

		self:OnMsgSend(cmdStr,self._nameToType[cmd] or cmdData.type)
	end
end

function UIGMand:TestClientTextLog()
	local openClientTextLog = LPlayerPrefs.openClientTextLog
	if openClientTextLog == "0" then
		LPlayerPrefs.SetOpenClientTextLog("1")
	else
		LPlayerPrefs.SetOpenClientTextLog("0")
	end
end

function UIGMand:ChangeResVersion(arrCmd)
	local resVersion = checknumber(arrCmd[1]) or 1
	LPlayerPrefs.GMSetLocalization(resVersion)
end

function UIGMand:ReportStatistic(arrCmd)
	local reportId = arrCmd[1]

	gLFightManager:ReportStatistic(reportId)

end
function UIGMand:StartDebugTimeCorridor(arrCmd)

end

function UIGMand:ChangeDTMoveTime(arrCmd)
	local direType = tonumber(arrCmd[1])
	local time = tonumber(arrCmd[2])
	if direType and time then
		gModelFastDreamTrip:SetGameMoveToTime(direType,time)
		if LOG_INFO_ENABLED then
			printInfoNR2("梦境之旅：","修改梦境之旅信息 地图骰子类型：" .. direType .. "，移动时间：" .. time)
		end
	else
		if LOG_INFO_ENABLED then
			printInfoNR2("梦境之旅：","数据出错，重新输入，格式 1 0.1")
		end
	end
end

function UIGMand:ReSetNotch()
	if gLGameUI then
		gLGameUI:DoAdjustNotchWndAnchor()
	end
end

function UIGMand:OpenUITest(arrCmd)
	local toNum = tonumber(arrCmd[1])
	if toNum and toNum > 0 then
		GF.ChangeToAnyScene("LTestScene","devtest")
	else
		if GF.FindFirstWndByName("UI_CTDevTest") then
			GF.CloseWndByName("UI_CTDevTest")
		else
			GF.OpenWnd("UI_CTDevTest")
		end

	end
end

function UIGMand:SetReConnectTime(arrCmd)
	local time = tonumber(arrCmd[1])
	if not time then return end
	LPlayerPrefs.SetEdtReconnect(time)
end


function UIGMand:OpenNotch(arrCmd)
	local bottomHeight = tonumber(arrCmd[1]) or 0
	LNotchUtil.DebugiPhone12(bottomHeight)
	self:ReSetNotch()
end

function UIGMand:TestTranslate(arrCmd)
	local str = arrCmd[1]
	gLGameTranslator:GetTranslate(str,function (code,text)
		printErrorN(string.format("translated text: %s",text))
	end)
end

function UIGMand:ChangeJDInfo(arrCmd)
	local effId = checknumber(arrCmd[1])
	local info = arrCmd[2] or ""
	local infos = string.split(info,"|")
	gModelHeroExtra:SetLHDrawingAllAgesData(effId,infos)
	printInfoNR("修改胶带数据成功")
end

function UIGMand:OnDrawCommandItem(list, item, itemdata, itempos, fromHeadTail)
	self:OnDrawCommandTextItem(list, item, itemdata, itempos, fromHeadTail)
	self:SetWndClick(item,function (...)
		self:OnClickCommand(itemdata)
	end)
end

function UIGMand:ResetNewbie(arrCmd)
	--gLGpManager:FindNewbieGp():OnExitMap()
	GF.CloseWndByName("UINeie")
	GF.CloseWndByName("UIPerCreateName")
	local id = tonumber(arrCmd[1]) or 0
	if id == 0 then
		local refTblList = gModelPlot:GetModelConfig(ModelPlot.NewPlayerGuidePrologueRef)
		id = 1056
		for k,v in pairs(refTblList) do
			if v.beginType == 2 then
				id = v.begin
			end
		end
	end

	self:WndClose()

	gLGpManager:FindNewbieGp():StartNewbie(id)
end

function UIGMand:OnQuickSearch(searchStr)
	local dataList = self._quickData.datas
	if(#dataList == 0) then return end
	local retDataList = {}
	if string.isempty(searchStr) then
		retDataList = dataList
	else
		for k,v in ipairs(dataList) do
			if string.find(v.text, searchStr) then
				table.insert(retDataList, v)
			end
		end
	end
	local uiList = self._uiQuickDataList
	uiList:RefreshList(retDataList)
	uiList:DrawAllItems()
end

function UIGMand:TestRewardWnd()
	GF.CloseWndByName("UIGMand")
end

function UIGMand:OnDrawGroup(list,item,itemdata,itempos)
	local btnTrans = self:FindWndTrans(item,"Btn")
	local data = self._groupMaps[itemdata]
	if not data then
		return
	end
	self:SetWndButtonText(btnTrans,data.name)
	self:SetWndClick(item,function ()
		self:OnClickGroup(itemdata)
	end)
	local isOn = self._curGroup == itemdata
	self:SetWndButtonGray(btnTrans, not isOn)
end

-- 播放模拟战斗
function UIGMand:OnReportPlayGM(arrCmd)

	local refId = tonumber(arrCmd[1])
	gModelBattle:OnClickShamBattle(refId)
	GF.CloseWndByName("UIGMand")
end

function UIGMand:TestShare()

end

function UIGMand:GameBackGround(arrCmd)
	local focus = toboolean(arrCmd[1])
	gLFightManager:OnApplicationPause(focus)
	GF.CloseWndByName("UIGMand")

end

function UIGMand:OnDrawLogItem(list, item, itemdata, itempos)
	local textTrans = self:FindWndTrans(item, "UIText")
	self:SetWndText(textTrans, itemdata)
	local text = LxUiHelper.FindXTextCtrl(textTrans)
	local height = text.preferredHeight
	LxUiHelper.SetSizeWithCurAnchor(textTrans,1,height + 5)
	LxUiHelper.SetSizeWithCurAnchor(item,1,height + 5)
end

function UIGMand:ShowHeroRewardWnd(arrCmd)
	local heroList = {}
	if string.isempty(arrCmd[1]) then
		for k,v in pairs(GameTable.CharacterRef) do
			table.insert(heroList,k)
		end
	else
		local refIds = string.split(arrCmd[1],",")
		for i,v in ipairs(refIds) do
			table.insert(heroList,tonumber(v))
		end
	end
	self:WndClose()
	gModelGeneral:OpenGMUpStarHeroShow({
		heroList = heroList,
		callRefId = tonumber(arrCmd[2]),
		wndType = tonumber(arrCmd[3]),
	})

end

function UIGMand:OnTriggerGuideGM(arrCmd)
	local guideId = tonumber(arrCmd[1])
	gModelGuide:StartGuide(guideId)
	GF.CloseWndByName("UIGMand")
end

function UIGMand:testHttpsRequest(arrCmd)
	local url = arrCmd[1]
	if string.isempty(url) then
		return
	end
	if not string.startswith(url, "https://") then
		GF.ShowMessage("输入正确的https地址")
		return
	end
	LxHttpHelper.DoWebRequestURL(false, {url}, "", function (ret, result, url)
		if (ret ~= CS.YXWebRet.ok) then
			LogError("获取不到数据 |" ..tostring(ret) .. " | " .. tostring(result))
			return
		end

		LXFW.LxLog.WEB(result)
	end)
end

function UIGMand:SkipStoryScene()
	gModelPlot:GMSkip()
end

function UIGMand:InitMessage()
	local waitRecvMsgId = LProtoHelper.GetProtoId("DebugResp")
	self:WndEventRecv(EventNames.NET_ERROR_CODE, function (msgId, errCode ,errArgs, errorStr)
		if msgId == waitRecvMsgId then
			self:ShowDebugReturn("R:"..tostring(errorStr))
			self:ShowMessage(errorStr)
		end
	end)

	self:WndNetMsgRecv(LProtoIds.DebugResp,function (...)
		self:OnDebugResp(...)
	end)
end

function UIGMand:TestRemoteRes(arrCmd)
	local resName = arrCmd[1]
	if string.isempty(resName) then
		resName = "video_op_sd_1.mp4"
	end

	local remoteData = LRemoteResData:New()
	remoteData:Create(resName)
end

--发送or接收 消息列表
function UIGMand:ShowDebugReturn(msg)
	table.insert(self._resultList,msg)
	if #self._resultList > 200 then
		local count = #self._resultList
		while count > 200 do
			table.remove(self._resultList,1)
			count = count -1
		end
	end
end

function UIGMand:InitGMArg()
	local data = nil
	local initType = self:GetWndArg("initType")
	for k,v in pairs(self._groupMaps) do
		if v.datas then
			for key,dataInfo in pairs(v.datas) do
				if dataInfo.type == initType then
					data = dataInfo
					break
				end
			end
		end
	end
	local isInit = data ~= nil
	if isInit then
		self:OnClickCommand(data)
	end
	return isInit
end

function UIGMand:ShowBloodDetail(arrCmd)
	local isShow = tonumber(arrCmd[1]) == 1
	gModelBattle:SetGMShowBlood(isShow)
end

function UIGMand:SimulateSysShot()
	GF.CloseWndByName("UIGMand")
	FireEvent(EventNames.SYS_SCREEN_SHOT)
end

function UIGMand:EnterInvasion(arrCmd)
	GF.OpenWndBottom("UIInvoss")
end

function UIGMand:TestSdkShare(arrCmd)
	local shareType = checknumber(arrCmd[1])
	local shareData = {}
	shareData.forType = shareType
	shareData.shareLocation = "测试"
	if shareType == 1 then
		shareData.shareParam1 = "this is test share"
		gLSdkImpl:CallMethod(LSdkMethod.Share, shareData)
	elseif shareType == 3 then
		shareData.shareParam1 = "https://www.baidu.com"
		gLSdkImpl:CallMethod(LSdkMethod.Share, shareData)
	end
end

function UIGMand:SetGameSpeed(arrCmd)
	local speed = arrCmd[1]
	if string.isempty(speed) then
		return
	end
	gModelGameHelper:GMSetGameSpeed(tonumber(speed))
end

function UIGMand:CancelGuideRecord(arrCmd)
	local guideKey = arrCmd[1]
	if guideKey then
		gModelGuide:GMRepeatTrigger(tonumber(guideKey))
	end
end

function UIGMand:WriteHistoryToFile()
	local path = HISTORY_PATH
	local dataList = self._gmCmdHistoryList or {}
	if string.isempty(path) then return end
	local content = JSON.encode(dataList)
	if string.isempty(content) then return end
	LFileHelper.WriteAllTextToCache(path,content)
end

function UIGMand:InitShowCmd()
	CS.ShowObject(self.mResultNodeObj, false)
	CS.ShowObject(self.mQuickNode, false)

	self:ReadHistoryFromFile()

	local historyList = self._gmCmdHistoryList or {}
	local gpKey
	local cmdData
	if #historyList > 0 then
		gpKey = "history"
	else
		gpKey, cmdData = self:FindLastCmdData()
	end
	if not gpKey then
		gpKey = "common"
	end
	self:OnSelectGroup(gpKey)

	self:InitGMArg()
end

function UIGMand:OnClickSearchCmd()
	if not self._searchCmd then
		return
	end

	if self:RunSpecialCom() then
		return
	end


	local allCmds = self._cmdDataFinder
	local list = {}
	for k,v in ipairs(allCmds) do
		if string.find(v.showname,self._searchCmd) then
			table.insert(list,v)
		end
	end

	table.sort(list,function (a,b)
		return a.type<b.type
	end)

	self:ShowCmdList(list)
end

function UIGMand:OnMsgSend(cmd,type)
	local pb = LProtoHelper.CreateProto(LProtoIds.DebugReq)
	pb.commandStr = cmd
	pb.type = type or 0
	SendMessage(pb,LProtoIds.DebugReq)
end

function UIGMand:OnDrawQuickDataItem(list, item, itemdata, itempos, fromHeadTail)
	local imgSel = CS.FindTrans(item, "ImageSel")
	CS.ShowObject(imgSel, itemdata.id == self._quickData.id)
	local textTrans = CS.FindTrans(item,"UIText")
	self:SetWndText(textTrans,itemdata.text)
	self:SetWndClick(item, function ()
		self._quickData.id = itemdata.id
		self._uiQuickDataList:DrawAllItems()
		local args = string.split(self.mQuickNumInput.text," ")
		args[1] = itemdata.id
		self.mQuickNumInput.text = table.concat(args, " ")
	end)
end

function UIGMand:HideAllUI()
	local isVisible = not gLGameUI:IsVisibleAllUI()
	gLGameUI:SetVisibleAllUI(isVisible)
end

function UIGMand:ShowInfoView()
	local infoDatas,nums = self:GetInfoDatas()
	local cmdData = self._selCmdData
	CS.ShowObject(self.mQuickNode, true)

	self:SetWndText(self.mQuickTitle, cmdData.showname)
	self:SetWndText(self.mQuickName, self._selCmdStr)
	self:SetWndText(self.mQuickNameDesc, cmdData.annotation)

	if not string.isempty(cmdData.args) then
		self._selArgs = string.split(string.trim(cmdData.args), " ")
	end
	self.mQuickNumInput.text = table.concat(self._selArgs, " ")

	local list = self._uiQuickNumList
	if not list then
		list = self:GetUIScroll("_uiQuickNumList")
		self._uiQuickNumList = list
		list:Create(self.mQuickNumList,nums,function (...) self:OnDrawQuickNumItem(...) end,UIItemList.SUPER_GRID)
	else
		list:RefreshList(nums)
	end
	list:DrawAllItems()

	list = self._uiQuickDataList
	if not list then
		list = self:GetUIScroll("_uiQuickDataList")
		self._uiQuickDataList = list
		list:Create(self.mQuickDataList,infoDatas,function (...) self:OnDrawQuickDataItem(...) end,UIItemList.SUPER_GRID)
	else
		list:RefreshList(infoDatas)
	end
	local pos = 0
	self._quickData = {}
	local id = tonumber(self._selArgs[1]) or 0
	self._quickData.id = id
	self._quickData.datas = infoDatas

	for k,v in ipairs(infoDatas) do
		if v.id == id then
			pos = k
			break
		end
	end
	if pos > 1 then
		list:MoveToPos(pos)
	end
	list:DrawAllItems()
end

function UIGMand:SetTargetFrameRate(arrCmd)
	local toNum = tonumber(arrCmd[1])
	if toNum and toNum > 0 then
		if gLGameQuality then
			gLGameQuality:SetFrameRate(toNum)
		end
	end
	CS.ShowFPS(true)
end

function UIGMand:OnDebugResp(pb,ret)
	if(ret ~= 0) then return end
	local str = pb.result
	local arrResult = string.split(str,"\n")
	for k,str in ipairs(arrResult) do
		local st,se,str1,str2 = string.find(str,"获得道具：(.+)，数量：(.+)")
		if str1 and str2 then
			local itemid = string.gsub(str1,"item_name_","")
			local itemName = ccLngText(str1)
			str = string.format("获得道具：%s(%s) x %s",itemName,itemid,str2)
		else
			st,se,str1,str2 = string.find(str,"获得少女{(.+),(.+)}")
			if str1 and str2 then
				local heroId = tonumber(str1)
				local HeroRef = gModelHero:GetHeroRef(heroId)
				local heroName = HeroRef and gModelHero:GetHeroNameByRefId(heroId,HeroRef.initStar) or ""
				str = string.format("获得少女：%s(%s) x %s",heroName,heroId,str2)
			end
		end

		self:ShowDebugReturn("R:"..str)
		self:ShowMessage(str)
	end


	local cmdName = self._typeToNameMap[pb.type or 0] or ""
	if cmdName == "removeInstance" then
		gModelInstance:OnPlayerInstanceReq()
	elseif cmdName == "removeAllItem" then
		gModelItem:OnItemListReq()
	elseif cmdName == "removeAllHero" then
		gModelHero:OnHeroListReq()
	elseif cmdName == "setInstance" then
		gModelInstance:OnPlayerInstanceReq()
		LxTimer.DelayTimeCall(function()
			if self:IsDestroy() then return end
			gModelFunctionOpen:OnFunctionOpenStateChange()
		end, 1)
	elseif cmdName == "changePlayerLevel" then
		gModelFunctionOpen:OnFunctionOpenStateChange()
	end
end

function UIGMand:TestPreEffect(arrCmd)
	local refId = tonumber(arrCmd[1])
	GF.CloseWndByName("UIGMand")
	GF.OpenWndUp("UISowEffect",{wndType = 3,refId = refId})
end

function UIGMand:InitData()
	local groupKeys = {"history", "common", "custom1", "custom2", "remote", "log"}
	self._groupKeys = groupKeys
	self._groupMaps = {}

	self._groupMaps["log"] = {excludeFinder=true, key = "log" , name = "日志", execute = self.ShowLogNode}

	local remoteList = gModelGM:GetCommandList()
	self._groupMaps["remote"] = {key = "remote" , name = "后端", datas = remoteList}
	local customs = {
		{ type = 999,showname = "进入自定义测试战斗", command = "testBattle", annotation = "testBattle 战斗id", execute = self.OnTestBattleGM},
		{ type = 1000,showname = "跳过引导步骤", command = "nextGuide", annotation ="nextGuide",execute = self.OnNextGuideGM},
		{ type = 1001,showname = "结束引导", command = "endGuide", annotation = "endGuide", execute = self.OnEndGuideGM},
		{ type = 1002, showname = "触发指引", command = "triggerGuide", annotation = "riggerGuide" , execute = self.OnTriggerGuideGM},
		{ type = 1010, showname = "功能开放跳转", command = "jump", annotation = "jump",execute = self.OnJumpGM},
		{ type = 1011, showname = "播放剧情", command = "playPlot", annotation = "playPlot",execute = self.OnPlayPlotGM},
		{ type = 1012, showname = "播放模拟战斗", command = "warReportPlay", annotation = "warReportPlay 1001", execute = self.OnReportPlayGM},
		{ type = 1015, showname = "显示血量详细", command = "showBlood", annotation = "showBlood",execute = self.ShowBloodDetail},
		{ type = 1017, showname = "开启剧情副本", command = "startStoryScene", annotation = "startStoryScene 1001", execute = self.StartStoryScene},
		{ type = 1018, showname = "开启时光之巅调试", command = "startDebugTimeCorridor", annotation = "startDebugTimeCorridor 1001",execute = self.StartDebugTimeCorridor},
		{ type = 1019, showname = "获取来源测试", command = "getWayTest", annotation = "getWayTest [num]",execute = self.TestGetWay},
		{ type = 1020, showname = "打开测试界面", command = "openUITest", annotation = "openUITest wndName",execute = self.OpenUITest},
		{ type = 1021, showname = "修改帧率", command = "SetTargetFrameRate", annotation = "SetTargetFrameRate 60", execute = self.SetTargetFrameRate},
		{ type = 1022, showname = "测试战报", command = "testReport", annotation = "testReport reportId",execute = self.TestReport},
		{ type = 1024, showname = "编辑器模式重连时间", command = "SetReConnectTime", annotation = "SetReConnectTime 5", execute = self.SetReConnectTime},
		{ type = 1026, showname = "清除满星少女弹窗", command = "clearUpStar", annotation = "clearUpStar",execute = self.ClearUpStar},
		{ type = 1027, showname = "打开教学小报", command = "openTeach", annotation = "openTeach 1001", execute = self.OpenTeach},
		{ type = 1030, showname = "一键加群", command = "joinQQGroup", annotation = "joinQQGroup",execute = self.JoinQQGroup},
		{ type = 1031, showname = "跳过开场剧情", command = "skipStoryScene", annotation = "skipStoryScene",execute = self.SkipStoryScene},
		{ type = 1032, showname = "开启iphone12刘海屏(1170*2532)", command = "openNotch", annotation = "openNotch 10", execute = self.OpenNotch},
		{ type = 1033, showname = "关闭刘海屏", command = "closeNotch", annotation = "closeNotch",execute = self.CloseNotch},
		--{ type = 1034, showname = "账号管理", command = "accountmgr", annotation = "accountmgr",execute = self.OpenAccountMgr},
		{ type = 1035, showname = "测试服务器战报", command = "testServerBattle", annotation = "testServerBattle",execute = self.TestServerBattle},
		{ type = 1036, showname = "适配测试", command = "testNotch", annotation = "testNotch (model=manufacturer)",execute = self.TestNotch},
		{ type = 1037, showname = "微信分享", command = "testshare", annotation = "testshare",execute = self.TestShare},
		{ type = 1038, showname = "测试分享奖励领取", command = "testsharereward", annotation = "testsharereward",execute = self.TestGameShareReward},
		{ type = 1040, showname = "完成指引", command = "finishGuide", annotation = "finishGuide 1080", execute = self.FinishGuide},
		{ type = 1041, showname = "打开消息调试", command = "openNetDebug", annotation = "openNetDebug",execute = self.OpenNetDebug},
		{ type = 1042, showname = "富文本ID打印", command = "testClientTextLog", annotation = "testClientTextLog",execute = self.TestClientTextLog},
		{ type = 1043, showname = "系统截屏观测",  command = "openSysShotObserver", annotation = "openSysShotObserver 1", execute = self.OpenSysShotObserver},
		{ type = 1044, showname = "系统截屏模拟", command = "simulateSysShot", annotation = "simulateSysShot",execute = self.SimulateSysShot},
		{ type = 1045, showname = "测试功能开放特效", command = "testFuncOpen", annotation = "testFuncOpen",execute = self.TestPreEffect},
		{ type = 1046, showname = "测试段位赛赛季结算效果", command = "testCrossGradingEff", annotation = "testCrossGradingEff",execute = self.TestCrossGradingEff},
		{ type = 1047, showname = "热切账号", command = "hotSwitchAccount", annotation = "hotSwitchAccount",execute = self.HotSwitchAccount},
		{ type = 1048, showname = "设置游戏加速", command = "setGameSpeed", annotation = "setGameSpeed num",execute = self.SetGameSpeed},
		{ type = 1049, showname = "打开窗口", command = "openTestWnd", annotation = "openTestWnd",execute = self.OpenTestWnd},
		{ type = 1050, showname = "测试屏蔽字", command = "TestWordMask", annotation = "TestWordMask 词",execute = self.TestWordMask},
		{ type = 1051, showname = "取消指引触发记录", command = "cancelGuideRecord", annotation = "cancelGuideRecord",execute = self.CancelGuideRecord},
		{ type = 1052, showname = "测试翻译接口", command = "testTranslate", annotation = "testTranslate",execute = self.TestTranslate},
		{ type = 1053, showname = "测试远程数据下载", command = "testRemoteDownload", annotation = "testRemoteDownload",execute = self.TestRemoteRes},
		{ type = 1059, showname = "少女获得展示界面",  command = "showHeroRewardWnd", annotation = "showHeroRewardWnd",execute = self.ShowHeroRewardWnd},
		{ type = 1060, showname = "召唤少女获得列表界面", command = "showCallHeroRewardWnd", annotation = "showCallHeroRewardWnd",execute = self.ShowCallHeroRewardWnd},
		{ type = 1063, showname = "模拟购买兑换券(recharge 计费点ID|4|代金券RefID)", command = "recharge", annotation = "recharge 计费点ID|4|代金券RefID", execute = self.FakePayCoinCertificate},
		{ type = 1069, showname = "隐藏战斗界面文字", command = "hideBattleFont", annotation = "hideBattleFont",execute = self.HideBattleFont},
		{ type = 1070, showname = "隐藏所有UI", command = "hideAllUI", annotation = "hideAllUI",execute = self.HideAllUI},
		{ type = 1070, showname = "隐藏GM按钮", command = "hideGmBtn", annotation = "hideGmBtn",execute = self.HideGmBtn},
		{ type = 1071, showname = "播放远程战报", command = "StartServerBattle", annotation = "StartServerBattle",execute = self.StartServerBattle},
		{ type = 1072, showname = "图文帮助", command = "OpenHelpPicture", annotation = "OpenHelpPicture 1001", execute = self.OpenHelpPictureWnd},
		{ type = 1073, showname = "崩溃C#", command = "CrashSelf", annotation = "CrashSelf", execute = self.CrashSelf},
		{ type = 1074, showname = "分享", command = "TestSdkShare", annotation = "TestSdkShare", execute = self.TestSdkShare},
		{ type = 1075, showname = "打开爱欲小径", command = "OpenDesireTrail", annotation = "OpenDesireTrail", execute = self.OpenDesireTrail},
		{ type = 1076, showname = "修改云朵数据", command = "ChangeCloudInfo", annotation = "ChangeCloudInfo", execute = self.ChangeCloudInfo},
		{ type = 1077, showname = "国服皮肤立绘生效窗口", command = "ChangeLHCloudHX", annotation = "ChangeLHCloudHX", execute = self.ChangeLHCloudHX},
		{ type = 1078, showname = "修改胶带数据", command = "ChangeJDInfo", annotation = "ChangeJDInfo", execute = self.ChangeJDInfo},
		{ type = 1080, showname = "修改资源和谐版本(0,1,2)", command = "ChangeResVersion", annotation = "ChangeResVersion", execute = self.ChangeResVersion},
		{ type = 1081, showname = "设置归因信息（归因（1=Organic），包id，黑名单（1：黑名单））", command = "SetAfStatus", annotation = "SetAfStatus", execute = self.SetAfStatus},
		{ type = 1082, showname = "触发订阅", command = "TriggerSubscription", annotation = "TriggerSubscription", execute = self.TriggerSubscription},
		{ type = 1083, showname = "重置feed订阅红点", command = "ResetFeedRP", annotation = "ResetFeedRP", execute = self.ResetFeedRP},
	}
	self._groupMaps["custom2"] = {key = "custom2" , name = "本地2", datas = customs}

	customs = {
		{ type = 20019, showname = "修改梦境之旅移动时间", command = "changeDTMoveTime", annotation = "changeDTMoveTime",execute = self.ChangeDTMoveTime},
		{ type = 20020, showname = "修改梦境之旅跳跃高度", command = "changeDTJumpHeight", annotation = "changeDTJumpHeight",execute = self.changeDTJumpHeight},
		{ type = 20021, showname = "播放奖励动画", command = "showUISdAward", annotation = "showUISdAward",execute = self.showUISdAward},
		{ type = 20022, showname = "测试战斗结果播放", command = "showBattleResult", annotation = "showBattleResult",execute = self.showBattleResult},
		{ type = 20022, showname = "测试https访问", command = "testHttpsRequest", annotation = "testHttpsRequest",execute = self.testHttpsRequest},
	}
	self._groupMaps["custom1"] = {key = "custom1", name= "本地1", datas = customs}

	local quicks = {
		{type = 10001, showname = "过关卡", command = "setInstance", annotation = "setInstance", sel = 100200},
		{type = 10002, showname = "等级", command = "changePlayerLevel", annotation = "changePlayerLevel", sel = 100},
		{type = 10003, showname = "金币", command = "addItem refId num", annotation = "addItem id 数量", sel = ModelItem.ITEM_GOLD},
		{type = 10004, showname = "水晶", command = "addItem refId num", annotation = "addItem id 数量", sel = ModelItem.ITEM_DIAMOND},
		{type = 10005, showname = "现金券", command = "addItem refId num", annotation = "addItem id 数量", sel = ModelItem.ITEM_PAYMONEY},
		{type = 10006, showname = "少女", command = "addHero refId num", annotation = "addHero id 数量", sel = 5506},
		{type = 10007, showname = "满星少女", command = "addHeroMax refId num", annotation = "addHeroMax id 数量", sel = 5506},
		{type = 10008, showname = "物品", command = "addItem refId num", annotation = "addItem id 数量", sel = 1},
		{type = 10009, showname = "测试战斗", command = "testBattle", annotation = "testBattle 战斗id", execute = self.OnTestBattleGM},
		{type = 10010, showname = "战报回放", command="playBattleData inst-player-1215192662032705", annotation="playBattleData [num]", execute = self.OnPlayBattleDataGM},
		{type = 10011, showname = "怪物战斗", command = "testBattle", annotation = "testBattle 1001|1001", execute = self.OnTestBattleGM ,sel="1001|1001"},
		{type = 10012, showname = "跳过开场剧情", command = "skipStoryScene", annotation = "skipStoryScene", execute = self.SkipStoryScene},
		{type = 10013, showname = "结束引导", command = "endGuide", annotation = "endGuide", execute = self.OnEndGuideGM},
		{type = 10014, showname = "触发指引", command = "triggerGuide", annotation = "triggerGuide", execute = self.OnTriggerGuideGM},
		{type = 10015, showname = "打开窗口", command = "openTestWnd", annotation = "openTestWnd",execute = self.OpenTestWnd},
		{type = 10016, showname = "新手剧场", command = "resetNewbie", annotation = "resetNewbie",execute = self.ResetNewbie},
		{type = 10017, showname = "隐藏所有UI", command = "hideAllUI", annotation = "hideAllUI",execute = self.HideAllUI},
		{type = 10018, showname = "隐藏GM按钮", command = "hideGmBtn", annotation = "hideGmBtn",execute = self.HideGmBtn},
		{type = 10019, showname = "完成指引", command = "finishGuide", annotation = "finishGuide 1090", execute = self.FinishGuide},
		{type = 10023, showname = "检测EventNames重复", command = "EvtIdMoreCheck", annotation="EvtIdMoreCheck", execute = self.CheckEventNamesDuplication},
	}
	self._groupMaps["common"] = {key = "common", name= "常用", datas = quicks}

	self._groupMaps["history"] = {excludeFinder = true, key = "history", name= "历史", dataExecute = self.GetHistoryCommandList}

	local cmdDataFinder = {}
	local typeData = {}
	for k,v in pairs(self._groupMaps) do
		local isFinder = not v.excludeFinder
		if v.datas then
			for m, data in ipairs(v.datas) do
				if isFinder then table.insert(cmdDataFinder, data) end
				typeData[data.type] = data
			end
		end
	end

	self._cmdDataFinder = cmdDataFinder
	self._cmdTypeToData = typeData

	local nameToType = {}
	for k,v in pairs(remoteList) do
		self._typeToNameMap[v.type] = v.command
		nameToType[v.command] = v.type
	end
	self._nameToType = nameToType

end

function UIGMand:CrashSelf(arrCmd)
	CS.YXDebugManager.CrashSelf()
end

function UIGMand:OnDrawQuickNumItem(list, item, itemdata, itempos, fromHeadTail)
	local textTrans = CS.FindTrans(item,"UIText")
	self:SetWndText(textTrans,itemdata.name)
	self:SetWndClick(item, function ()
		local args = string.split(self.mQuickNumInput.text," ")
		if #args > 1 then
			args[#args] = itemdata.name
		else
			args[1] = itemdata.name
		end
		self.mQuickNumInput.text = table.concat(args, " ")
	end)
end

function UIGMand:FinishGuide(arrCmd)
	local guideKey = tonumber(arrCmd[1])
	gModelGuide:GMFinishGuide(guideKey)
	GF.CloseWndByName("UIGMand")
end
---@region GM 历史记录

function UIGMand:InitGroupList()
	---@type UIItemList
	local groupList = self._uiGroupList
	if not groupList then
		groupList = self:GetUIScroll("_uiGroupList")
		self._uiGroupList = groupList
		groupList:Create(self.mCmdGroupList, {},function (...) self:OnDrawGroup(...) end,UIItemList.SUPER)
	end
	local uiList = groupList:GetList()
	uiList:RemoveAllData()
	for k,v in ipairs(self._groupKeys) do
		uiList:AddData(k, v)
	end
	uiList:RefreshList()
	groupList:DrawAllItems()
end

function UIGMand:TestReport(arrCmd)
	local reportId = tostring(arrCmd[1])
	local combatType =  LCombatTypeConst.COMBAT_TEST_BATTLE

	local endExtraData = {}

	local combatExtraData = {
		combatType = combatType,
		offlineTime = 0,
		isBattleToBackground = false,
		meName = gModelPlayer:GetPlayerName(),
		otherName = gModelPlayer:GetPlayerName(),
		isNew = true,
		skip = true,
		battleEndfun = function()
			gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_TEST_BATTLE,endExtraData)
		end
	}
	gModelBattle:StartFromReportId(reportId,combatType,combatExtraData)
end

--（归因（1=Organic），包id，黑名单（1：黑名单））
function UIGMand:SetAfStatus(arrCmd)
	LPlayerPrefs.LimitResType(false)
	local value = checknumber(arrCmd[1]) or 1
	gModelGM:SetAfStatus(value)
	gModelGM:SetPackId(arrCmd[2])
	local blackType = checknumber(arrCmd[3]) or 0
	gModelGM:SetIsBlackType(blackType)
	if gLSdkImpl then
		gLSdkImpl:CallMethod(LSdkMethod.GetABTestRes)
	end
end

function UIGMand:StartServerBattle(arrCmd)
	local url = arrCmd[1]

	local match = string.match(url,"(https://.+/)")
	local reportId = string.sub(url,#match+1,-6)

	local getter = LFightServerReportGetter:New()
	local combatType = LCombatTypeConst.COMBAT_TEST_BATTLE
	local reportInfo = {
		url = url,
		reportId = reportId,
		combatType = combatType,
		callback = function(reportTable)
			self:WndClose()
			gLFightManager:StartBattle(reportId, combatType, {}, reportTable)
		end
	}

	getter:Start(reportInfo);

end

function UIGMand:OnJumpGM(arrCmd)
	local id = tonumber(arrCmd[1])
	gModelFunctionOpen:Jump(id)
	GF.CloseWndByName("UIGMand")
end

function UIGMand:OnNextGuideGM(arrCmd)
	gModelGuide:NextGuide()
	GF.CloseWndByName("UIGMand")
end

function UIGMand:OnClickCommand(cmdData)
	self._selCmdData = cmdData
	local cmd = string.split(cmdData.command, " ")[1]
	local args = string.gsub(cmdData.command, cmd, "")
	args = string.split(string.trim(args), " ")
	self._selCmdStr = cmd
	self._selArgs = args
	self._selId = cmdData.sel
	self:ShowInfoView()
end

function UIGMand:OpenDesireTrail()
	gModelGeneral:DesireTrailEntrance()
	self:WndClose()
end


function UIGMand:OnTestBattleGM(arrCmd)

	GF.CloseWndByName("UIGMand")

	local monsterList = {}
	if arrCmd then
		monsterList = LxDataHelper.ParseNumber_Sign(arrCmd[1])
	end

	local monsterA = nil
	local monsterB = nil
	local cnt = #monsterList
	if cnt == 1 then
		monsterB = monsterList[1]
	elseif cnt == 2 then
		monsterA = monsterList[1]
		monsterB = monsterList[2]
	end

	gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_TEST_BATTLE,{monsterA = monsterA,monsterB = monsterB})
end
------------------------------- client GM Func -----------------------------
function UIGMand:OnPlayBattleDataGM(arrCmd)
	GF.CloseWndByName("UIGMand")


	local combatExtraData =
	{
		battleEndfun = function ()
			GF.ChangeMap("LCityMap")
		end
	}

	local reportId = arrCmd[1]
	local s,e = string.find(reportId,"pb")
	if s and e then
		gLFightManager:StartLocalPbReportBattle(reportId, combatExtraData)
	else
		gLFightManager:StartLocalCacheReportBattle(reportId, combatExtraData)
	end
end

function UIGMand:OnBattleMainBraveGM(arrCmd)
	gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_TYPE_30, {curTeam = 0})	--切换到布阵界面
	GF.CloseWndByName("UIGMand")
end

function UIGMand:InitEvent()
	self:SetWndClick(self.mBtnClose, function (...)
		self:WndClose()
	end)

	self:SetWndInputDelegate(self.mSearchCmdInput,function (value)
		self._searchCmd = value
	end)

	self:SetWndClick(self.mSearchCmdBtn,function ()
		self:OnClickSearchCmd()
	end)

	self:SetWndClick(self.mBtnQuickCloseObj, function ()
		CS.ShowObject(self.mQuickNode, false)
	end)

	self:SetWndClick(self.mBtnQuickGoObj, function ()
		self:OnClickBtnExcute()
	end)
	self:SetWndClick(self.mQuickBtnSearch, function ()
		self:OnQuickSearch(self.mQuickSearchInput.text)
	end)

	self:SetWndClick(self.mBtnResultClose, function()
		CS.ShowObject(self.mResultNodeObj, false)
	end)
end

function UIGMand:TestCrossGradingEff(arrCmd)
	local useGroup = arrCmd[1]
	if not string.isempty(useGroup) then
		useGroup = tonumber(useGroup)
	else
		useGroup = 0
	end
	GF.CloseWndByName("UIGMand")
	GF.OpenWnd("UIKuafuGradSeasonIdSow",{test = true,useGroup = useGroup})
end

function UIGMand:GenerateHeroDataList()
	if self._heroDataList then
		return self._heroDataList
	end
	local dataList = {}

	for k,v in pairs(GameTable.CharacterRef) do
		local data = {id=v.refId,name="",text=""}
		local initStar = v.initStar
		local starType = v.starType
		local starId = gModelHero:GetStarId(starType,initStar)
		local starRef = gModelHero:GetHeroStarById(starId)
		if starRef then
			local showId = starRef.effectId
			local effectRef = gModelHero:GetShowEffectById(showId)
			if effectRef then
				data.name=ccLngText(effectRef.name)
			end
		end
		data.text = data.id.."\n"..data.name
		table.insert(dataList,data)
	end
	self._heroDataList = dataList
	table.sort(dataList,function (a,b)
		return a.id < b.id
	end)
	return dataList
end

function UIGMand:OpenTheater()
	--GF.OpenWnd("WndTheater")
	--GF.CloseWndByName("UIGMand")
end

function UIGMand:OnPlayPlotGM(arrCmd)
	local plotId = tonumber(arrCmd[1])
	if not plotId then
		return
	end
	gModelPlot:StartPlotAndCallback(plotId)
	GF.CloseWndByName("UIGMand")
end

function UIGMand:StopMessageTimer()
	if self._messageDelayTimer then
		LxTimer.DelayTimeStop(self._messageDelayTimer)
		self._messageDelayTimer = nil
	end
end

function UIGMand:OnEndGuideGM(arrCmd)
	gModelGuide:EndGuide()
	GF.CloseWndByName("UIGMand")
end



function UIGMand:FakePayCoinCertificate(arrCmd)
	self:OnClickBtnExcute(true)
	GF.CloseWndByName("UIGMand")
end

function UIGMand:TestServerBattle(arrCmd)
	local reportId = arrCmd[1]
	local serverId = arrCmd[2]
	if string.isempty(reportId) then
		return
	end

	local extraData =
	{
		serverId = serverId,
		battleEndfun = function ()
			GF.ChangeMap("LCityMap")
		end
	}

	gModelBattle:StartFromReportId(reportId,LCombatTypeConst.COMBAT_BATTLE_VIDEO,extraData)
	GF.CloseWndByName("UIGMand")
end
function UIGMand:OnBattleMainHeroGM(arrCmd)
	gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_TYPE_31, {curTeam = 0})	--切换到布阵界面
	GF.CloseWndByName("UIGMand")
end

------------------------------- create GM command -----------------------------
function UIGMand:GetAllCmd()
	return self._cmdDataFinder
end

function UIGMand:OpenSysShotObserver(arrCmd)

	if gLSdkImpl then
		local open = tonumber(arrCmd[1])
		LNativeHelper.CallMethod(LNativeMethod.DoSysShotWatch,open == 1 and true or false)
	end
end

function UIGMand:TestNotch(arrCmd,defaultCmd)
	local s,e,model,manufacturer = string.find(defaultCmd,"%((.-)=(.-)%)")
	LNotchUtil.DebugCfgNotch(model,manufacturer)
	GF.CloseWndByName("UIGMand")
end

function UIGMand:OnDrawCommandTextItem(list, item, itemdata, itempos, fromHeadTail)
	local textTrans = CS.FindTrans(item,"UIText")
	self:SetWndText(textTrans,itemdata.showname)
end

function UIGMand:CloseNotch()
	--LNotchUtil.changeBottomY = 0
	LNotchUtil.InitNotch()
	self:ReSetNotch()
end

function UIGMand:ClearUpStar()
	gModelGeneral:ClearUpHeroShowGM()
end
function UIGMand:ShowCmdList(cmdList)

	local list = self._uicmdList
	if not list then
		list = self:GetUIScroll("_uiCmdList")
		self._uicmdList = list
		list:Create(self.mListCommander,cmdList,function (...) self:OnDrawCommandItem(...) end,UIItemList.SUPER_GRID)
	else
		list:RefreshList(cmdList)
	end
	list:DrawAllItems()
end
function UIGMand:OpenTestWnd(arrCmd)
	local arg = {}
	local wndName = arrCmd[1]
	if not wndName then
		printInfoNR("没有窗口名字")
		return
	end
	local argStr = arrCmd[2]
	if not string.isempty(argStr) then
		argStr = string.split(argStr,",")
		for i,v in ipairs(argStr) do
			v = string.split(v,"=")
			arg[v[1]] = v[2]
		end
	end
	GF.CloseWndByName("UIGMand")
	GF.OpenWnd(wndName,arg)
end


function  UIGMand:OpenNetDebug()
	if GF.FindFirstWndByName("UINetDbg") then
		GF.CloseWndByName("UINetDbg")
	else
		GF.OpenWndDebug("UINetDbg")
		GF.CloseWndByName("UIGMand")
	end
end

function UIGMand:HideGmBtn()
	local wnd = GF.FindFirstWndByName("UIGMnBtn")
	if wnd then
		wnd:TryChangeGmShowState()
	end
end

function UIGMand:TriggerSubscription()
	gModelSubscriber:TriggerSubscription()
end

function UIGMand:ResetFeedRP()
	LPlayerPrefs.SetTTFreedSubscriberRP(tostring(0))
	self:WndClose()
	FireEvent(EventNames.REFRESH_FUNCTION_STATE)
	GF.ShowMessage(ccClientText(10356))
end

function UIGMand:SettingLanguage(arrCmd)
	local languageFlag = arrCmd[1]
	gModelPlayer:OnSettingLanguageReq(languageFlag)
	gLGameLanguage:SetLanguageFlag(languageFlag)
	LPlayerPrefs.SetChat50009pop("true")
	self:WndClose()
	RestartGame()
end

function UIGMand:HideBattleFont()
	local isVisible = not gLGameUI:IsVisibleBattleFont()
	gLGameUI:SetVisibleBattleFont(isVisible)
end

function UIGMand:RunSpecialCom()
	local str = self._searchCmd
	str = string.lower(str)
	if str == "openlog" then
		ccLog.logEnabled = true
		return true
	end
	if str == "closelog" then
		ccLog.logEnabled = false
		return true
	end
	if str == "minigamelog" then
		MiniGameLog = true
		return true
	end

	local strList = string.split(str," ")
	local value = tonumber(strList[2]) or 0

	if strList[1] == "downleftorrighty" and value > 0 then
		BlockMiniGameDownLeftOrRightY = value
		GF.ShowMessage("设置左右+下滑的高度成功：" .. value)
		self:WndClose()
		return true
	end
	if strList[1] == "downleftorrightx" and value > 0 then
		BlockMiniGameDownLeftOrRightX = value
		GF.ShowMessage("设置左右+下滑的宽度成功：" .. value)
		self:WndClose()
		return true
	end
	if strList[1] == "leftorright" and value > 0 then
		BlockMiniGameLeftOrRight = value
		GF.ShowMessage("设置左右宽度成功：" .. value)
		self:WndClose()
		return true
	end
	if strList[1] == "down" and value > 0 then
		BlockMiniGameDown = value
		GF.ShowMessage("设置下滑高度成功：" .. value)
		self:WndClose()
		return true
	end

	return false
end

function UIGMand:FindLastCmdData()
	local cmd = gModelGM and gModelGM:GetLastGmCmd() or nil
	if not cmd then return end
	for k,v in ipairs(self._groupKeys) do
		local gpData = self._groupMaps[v]
		local datas = gpData and gpData.datas or {}
		for m,data in ipairs(datas) do
			if data.command == cmd then
				return v, data
			end
		end
	end
end

----
---@region GM 历史记录
function UIGMand:ReadHistoryFromFile()
	local path = HISTORY_PATH
	local strContent = LFileHelper.ReadAllTextFromCache(path)
	local iniContent
	if not string.isempty(strContent) then
		iniContent = JSON.decode(strContent)
	end
	iniContent = iniContent or {}
	self._gmCmdHistoryList = iniContent
end

function UIGMand:OpenAccountMgr()
	--GF.OpenWnd("WndAccount")
end

function UIGMand:ShowSceneObjectList(arrCmd)
	local uSceneObj = CS.GetSceneAt(0)
	local rootObjList = uSceneObj:GetRootGameObjects()
	local cnt, i
	cnt = rootObjList.Length
	local obj = nil
	local tblStr = {}
	LogWarn("start list scene object ................")
	for i = 1, cnt do
		obj = rootObjList[i - 1]
		LogWarn("root name =" .. obj.name)
		local rendererList = obj:GetComponentsInChildren(typeof(UnityEngine.SpriteRenderer))
		local rendererLen = rendererList.Length
		for k=1, rendererLen do
			local renderer = rendererList[k-1]
			local parentName = ""
			if renderer.transform.parent then
				parentName = renderer.transform.parent.name
			end
			local sprite = "miss"
			local spriteName = nil
			if renderer.sprite then
				sprite = "exist"
				spriteName = sprite.name
			end
			local message = "Object renderer " .. renderer.gameObject.name .." |parent name="..tostring(parentName)
			table.insert(tblStr, message)
			LogWarn(message)
		end
	end
	LogWarn("end list scene object ................")
	local path = CS.AppPersistentDataPath() .. "scene_object_renderer_list.txt"
	CS.FileWriteText(path,table.concat(tblStr,"\n"))
	return nil
end

function UIGMand:OpenHelpPictureWnd(arrCmd)
	local refId = tonumber(arrCmd[1])
	GF.OpenWnd("UIBzPicturePop",{refId = refId})
end

function UIGMand:AddGmCmdHistory(type, cmd, para)
	if not self._gmCmdHistoryList then
		self._gmCmdHistoryList = {}
	end
	local len = #self._gmCmdHistoryList
	for k=len ,1 , - 1 do
		local history = self._gmCmdHistoryList[k]
		if history.type == type then
			table.remove(self._gmCmdHistoryList, k)
		end
	end
	table.insert(self._gmCmdHistoryList, {type= type, cmd=cmd, para=para})
	if #self._gmCmdHistoryList > 30 then
		table.remove(self._gmCmdHistoryList, 1)
	end
end

function UIGMand:showBattleResult(arrCmd)
	local heroEffectId = tonumber(arrCmd[1])
	if not heroEffectId or heroEffectId < 1 then return end
	self:WndClose()
	GF.OpenWnd("UIOrdinResult",{
		openType = 4,
		heroEffectId = heroEffectId,
		gmCb = function()
			GF.OpenWndDebug("UIGMand",{initType = 20022})
		end
	})
end

function UIGMand:TestWordMask(arrCmd)
	local strList = {}
	for k,v in ipairs(arrCmd) do
		table.insert(strList,v)
	end
	local str = table.concat(strList," ")
	LWordMaskUtil.ClearShieldWordEx(str,true,false,1,function (retCode,retText)
		printErrorN(string.format("retCode %s , retText %s ",retCode,retText))
	end)
end

function UIGMand:OpenTeach(arrCmd)

	local isOpen = gModelNormalActivity:IsAllowDinyue()
	print(string.format("IsAllowDinyue  %s",isOpen))

	local refId = tonumber(arrCmd[1]) or 1001
	GF.OpenWnd("UIGuePost",{refId = refId})
	GF.CloseWndByName("UIGMand")
end

function UIGMand:TestGameShareReward(arrCmd)
	local sid = tonumber(arrCmd[1])
	if not sid then return end
	gModelActivity:OnActivityInvitationReq(ModelActivity.INVITATION_DAY_SHARE,sid)
end

function UIGMand:ShowCallHeroRewardWnd(arrCmd)
	local heroIdList = arrCmd[1]
	local itemList = {}
	if string.isempty(heroIdList) then
		for k,v in pairs(GameTable.CharacterRef) do
			if v.initStar >= 4 then
				table.insert(itemList,{
					itemId = k,
					itype = 2,
					count = 1
				})
			end
		end
	else
		heroIdList = string.split(heroIdList,",")
		for i,v in ipairs(heroIdList) do
			table.insert(itemList,{
				itemId = tonumber(v),
				itype = 2,
				count = 1
			})
		end
	end
	local callRefId = 1001
	GF.CloseWndByName("UIGMand")
	local para =
	{
		itemList = itemList,
		refId = callRefId,
		callNum = 1,
		gmOpen = true
	}
	GF.OpenWndTop("UIYellSagaAwardNew",para)

end

function UIGMand:OnSelectGroup(groupKey)
	self._curGroup = groupKey
	if self._uiGroupList then
		self._uiGroupList:DrawAllItems()
	end
	local gpData = self._groupMaps[groupKey]
	local cmdList
	local func = gpData.dataExecute
	if func then
		cmdList = func(self)
	else
		cmdList = gpData.datas
	end

	self:ShowCmdList(cmdList or {})
end

function UIGMand:ShowLogNode()
	CS.ShowObject(self.mResultNodeObj, true)
	local uiList = self:FindUIScroll("_logList")
	if not uiList then
		uiList = self:GetUIScroll("_logList")
		uiList:Create(self.mResultTextList, { },function (...) self:OnDrawLogItem(...) end,UIItemList.SUPER)
	end
	uiList:RefreshList(self._resultList)
	uiList:DrawAllItems()
	uiList:MoveToPos(#self._resultList)
end

function UIGMand:GenerateInstanceMissionDataList()
	if self._missionDataList then
		return self._missionDataList
	end
	local dataList = {}

	for k,v in pairs(GameTable.MainInstanceMissionRef) do
		local data = {id=v.refId,name=ccLngText(v.nameWorld),text=""}
		data.text = data.id.."\n"..data.name
		table.insert(dataList,data)
	end
	self._missionDataList = dataList
	table.sort(dataList,function (a,b)
		return a.id < b.id
	end)
	return dataList
end

function UIGMand:TestGetWay(arrCmd)
	local itemId = tonumber(arrCmd[1])
	gModelGeneral:OpenGetWayWnd({itemId = itemId})
	GF.CloseWndByName("UIGMand")
end

function UIGMand:GetInfoDatas()
	local datas = {}
	local nums = {}
	local hasNum = false
	local cmd = self._selCmdStr
	if cmd == "addItem" then
		datas = self:GenerateItemDataList()
		hasNum = true
	elseif cmd == "addAllItem" then
		hasNum = true
	elseif cmd == "changePlayerLevel" then
		hasNum = true
	elseif cmd == "addHero" or cmd == "addHeroMax" then
		datas = self:GenerateHeroDataList()
		hasNum = true
	elseif cmd == "setInstance" then
		datas = self:GenerateInstanceMissionDataList()
	end

	local id = self._selId
	if not id then
		id = datas[1] and datas[1].id or ""
	end

	if hasNum then
		if #self._selArgs > 1 then
			self._selArgs[1] = tostring(id)
			self._selArgs[2] = tostring(1)
		else
			self._selArgs[1] = tostring(1)
		end

		table.insert(nums, {id=1, name="1"})
		table.insert(nums, {id=10, name="10"})
		table.insert(nums, {id=100, name="100"})
		table.insert(nums, {id=1000, name="1000"})
		table.insert(nums, {id=10000, name="10000"})
		table.insert(nums, {id=100000, name="100000"})
	end

	return datas, nums
end

function UIGMand:GetHistoryCommandList()
	local historyList = self._gmCmdHistoryList or {}
	local len = #historyList
	local retList = {}
	local typeToData = self._cmdTypeToData or {}
	local addRecord = {}
	for k=len , 1, -1 do
		local historyData = historyList[k]
		local type = historyData.type
		if not addRecord[type] then
			addRecord[type] = true
			local data = typeToData[historyData.type]
			if data then
				table.insert(retList, data)
				data.args = historyData.para
			end
		end
	end
	return retList
end
function UIGMand:HotSwitchAccount(arrCmd)
	local account = arrCmd[1]
	if string.isempty(account) then
		return
	end
	gLGameLogin:SetLoginIdentityId(account)
	MgrCenter.NetworkMgr:ReNewConnect()
end

function UIGMand:CheckEventNamesDuplication()
	local eventNames = EventNames
	local maps = {}
	for k,v in pairs(eventNames) do
		local data = maps[v] or {}
		table.insert(data, k)
		maps[v] = data
	end
	for k,v in pairs(maps) do
		if #v > 1 then
			LogError(string.format("id : %s , names : %s", tostring(k), table.concat(v , ", ")))
		end
	end
end

function UIGMand:JoinQQGroup()

	if CS.IsOSIos() then
		local uid = "865735847"
		local key = "4d7155c97b9f3552fae27d19aa51b8672dc52583684a8bd9f3d327298d9212ea"
		local path = "mqqapi://card/show_pslcard?src_type=internal&version=1&uin="..uid.."&key="..key.."&card_type=group&source=external&jump_from=webapi"
		gLSdkImpl:CallMethod(LSdkMethod.CallSdkJoinQQGroup,path)
	else
		local key = "0mIkAJ8sxP1kAy0qccnWULp4Dnc73shO"
		local path = "mqqopensdkapi://bizAgent/qm/qr?url=http%3A%2F%2Fqm.qq.com%2Fcgi-bin%2Fqm%2Fqr%3Ffrom%3Dapp%26p%3Dandroid%26jump_from%3Dwebapi%26k%3D"..key
		gLSdkImpl:CallMethod(LSdkMethod.CallSdkJoinQQGroup,path)
	end

end

function UIGMand:OnClickGroup(groupKey)
	local data = self._groupMaps[groupKey]
	if not string.isempty(data.execute) then
		local func = data.execute
		if func ~= nil then
			func(self)
		end
		return
	end
	self:OnSelectGroup(groupKey)
end

function UIGMand:ChangeLHCloudHX(arrCmd)
	local info = arrCmd[1] or ""
	local infos = string.split(info,"|")
	gModelHeroExtra:SetConfigHeroLHCloudHX(infos)
	printInfoNR("国服皮肤立绘生效窗口")
end

function UIGMand:showUISdAward()
	local info = {
		itemType = 1,
		itemId = 101001,
		itemNum = 10000,
	}
	local rewardList = {}
	for i = 1,100 do
		table.insert(rewardList,{
			reward = info
		})
	end
	local luckyItem = {}
	table.insert(luckyItem,{
		itemType = 1,
		itemId = 101001,
		itemNum = 10000,
	})
	table.insert(luckyItem,{
		itemType = 1,
		itemId = 100100,
		itemNum = 10000,
	})
	table.insert(luckyItem,{
		itemType = 1,
		itemId = 100105,
		itemNum = 10000,
	})
	self:WndClose()
	GF.OpenWndTop("UISdAward",{
		rewardList = rewardList,
		luckyItem = luckyItem,
	})
end

function UIGMand:changeDTJumpHeight(arrCmd)
	local jumpHeight = tonumber(arrCmd[1]) or 0
	if jumpHeight > 0 then
		gModelFastDreamTrip:SetGameJumpHeight(jumpHeight)
		if LOG_INFO_ENABLED then
			printInfoNR2("梦境之旅：","修改梦境之旅信息 跳跃高度：" .. jumpHeight)
		end
	else
		if LOG_INFO_ENABLED then
			printInfoNR2("梦境之旅：","数据出错，重新输入，必须大于0")
		end
	end
end


function UIGMand:GenerateItemDataList()
	if self._itemDataList then
		return self._itemDataList
	end
	local dataList = {}

	for k,v in pairs(GameTable.PlayerItemRef) do
		local data = {id=v.refId,name=ccLngText(v.name),text=""}
		data.text = data.id.."\n"..data.name
		table.insert(dataList,data)
	end
	self._itemDataList = dataList
	table.sort(dataList,function(a,b)
		return a.id < b.id
	end)

	return dataList
end

function UIGMand:ShowMessage(str)
	CS.ShowObject(self.mMsgNode, true)
	self:SetWndText(self.mMsgTxt, str)
	self:StopMessageTimer()
	self._messageDelayTimer = LxTimer.DelayTimeCall(function()
			CS.ShowObject(self.mMsgNode, false)
		self._messageDelayTimer = nil
	end, 1.5)
end

function UIGMand:StartStoryScene(arrCmd)
	local storyId = tonumber(arrCmd[1])
	gLGpManager:FindStoryCopyGp():Clear()
	gLGpManager:FindStoryCopyGp():StartStory(storyId)
	GF.CloseWndByName("UIGMand")
end

function UIGMand:IsAutoLangFont()
	return false
end

------------------------------------------------------------------
return UIGMand