---
--- Created by BY.
--- DateTime: 2022/9/21 20:47:53
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDreamCrusadeAgainstNodePop:LWnd
local UIDreamCrusadeAgainstNodePop = LxWndClass("UIDreamCrusadeAgainstNodePop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDreamCrusadeAgainstNodePop:UIDreamCrusadeAgainstNodePop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDreamCrusadeAgainstNodePop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDreamCrusadeAgainstNodePop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDreamCrusadeAgainstNodePop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UIDreamCrusadeAgainstNodePop:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(32303))
	self:SetWndText(self.mCloseTip,ccClientText(10103))

	local bossRefId = self:GetWndArg("bossRefId")
	self._bossRefId = bossRefId
	local bossRef = gModelCrusadeAgainst:GetDreamCrusadeDifficultyRefByRefId(bossRefId)
	local bossInfo = gModelCrusadeAgainst:GetCrusadeAgainstInfosByBossRefId(bossRefId)
	if not bossInfo then return end
	local nodeId = bossInfo.nodeId
	local difficultyLimit = bossRef.difficultyLimit
	local difficulty = 1
	local nodeRef = nil
	local curLevelNum = 0
	if bossInfo.nodeId == 0 then
		local nodeList = gModelCrusadeAgainst:GetDreamCrusadeCheckpointRefBoosTypeAndDifficulty(bossRefId,1)
		nodeRef = nodeList[1]
	else
		nodeRef = gModelCrusadeAgainst:GetDreamCrusadeCheckpointRefByRefId(nodeId)
		curLevelNum = nodeRef.levelNum
	end
	if nodeRef.nextRefid == 0 then
		if nodeRef.difficulty < difficultyLimit then
			difficulty = nodeRef.difficulty + 1
			curLevelNum = 0
		else
			difficulty = difficultyLimit
		end
	else
		difficulty = nodeRef.difficulty
	end

	local nodeList = gModelCrusadeAgainst:GetDreamCrusadeCheckpointRefBoosTypeAndDifficulty(bossRefId,difficulty)

	self._nodeId = nodeId
	self._difficulty = difficulty
	self._levelNum = curLevelNum
	self._len = #nodeList
	self:RefreshData()
end

function UIDreamCrusadeAgainstNodePop:OnClickJump(difficulty)
	FireEvent(EventNames.ON_JUMP_DIFFICULTY,difficulty)
	self:WndClose()
end
function UIDreamCrusadeAgainstNodePop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.CrusadeAgainstInfoResp,function(pb)
		self:WndClose()
	end)
end

function UIDreamCrusadeAgainstNodePop:RefreshData()
	local bossRefId = self._bossRefId

	local bossRef = gModelCrusadeAgainst:GetDreamCrusadeDifficultyRefByRefId(bossRefId)
	local difficultyLimit = bossRef.difficultyLimit
	local list = {}
	for i = 1, difficultyLimit do
		local refList = gModelCrusadeAgainst:GetDreamCrusadeCheckpointRefBoosTypeAndDifficulty(bossRefId,i)
		table.insert(list,refList)
	end

	local uiList = self:GetUIScroll("mCellSuper")
	if uiList:GetList() then
		uiList:RefreshList(list)
		uiList:DrawAllItems()
	else
		uiList:Create(self.mCellSuper,list,function (...) self:ListItem(...) end,UIItemList.SUPER)
	end
end

function UIDreamCrusadeAgainstNodePop:InitEvent()
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end)
	self:SetWndClick(self.mBgImage,function () self:WndClose() end)
end

function UIDreamCrusadeAgainstNodePop:ListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local difficultyText = self:FindWndTrans(root,"DifficultyText")
	local nodeText = self:FindWndTrans(root,"NodeText")
	local nodeBar = self:FindWndTrans(root,"NodeBar")
	local barText = self:FindWndTrans(root,"NodeBar/BarText")
	local btnJump = self:FindWndTrans(root,"BtnJump")
	local nodeValueBar = self:FindWndSlider(nodeBar)

	local curDifficulty = self._difficulty
	local curLevelNum = self._levelNum


	local refList = itemdata
	local len = #refList
	local ref1 = refList[1]
	local difficulty = ref1.difficulty
	local barValue = curLevelNum
	local isOpent = difficulty <= curDifficulty or (difficulty == curDifficulty + 1 and curLevelNum == self._len)
	if difficulty == curDifficulty then
		barValue = curLevelNum
	elseif difficulty < curDifficulty then
		barValue = len
	elseif difficulty > curDifficulty then
		barValue = 0
	end
	self:SetWndText(difficultyText,string.replace(ccClientText(32304),difficulty))

	if gLGameLanguage:IsEnglishVersion() or gLGameLanguage:IsVieVersion() then
		self:InitTextSizeWithLanguage(difficultyText, -2)
	else
		self:InitTextLineWithLanguage(difficultyText, -30)
	end

	self:SetWndText(nodeText,ccClientText(32318))
	self:InitTextLineWithLanguage(nodeText, -30)
	nodeValueBar.maxValue = len
	nodeValueBar.value = barValue
	self:SetWndText(barText,string.format("%s/%s",barValue,len))
	self:SetWndButtonText(btnJump,isOpent and ccClientText(32319) or ccClientText(32320))
	self:SetWndButtonGray(btnJump,not isOpent)
	self:SetWndClick(btnJump,function ()
		if not isOpent then
			GF.ShowMessage(ccClientText(32320))
			return
		end
		self:OnClickJump(difficulty)
	end)
end
------------------------------------------------------------------
return UIDreamCrusadeAgainstNodePop


