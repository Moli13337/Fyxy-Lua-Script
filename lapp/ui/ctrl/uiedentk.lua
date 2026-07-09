---
--- Created by Administrator.
--- DateTime: 2023/10/28 11:20:54
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEdenTk:LWnd
local UIEdenTk = LxWndClass("UIEdenTk", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEdenTk:UIEdenTk()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEdenTk:OnWndClose()
	self:Clear()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEdenTk:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEdenTk:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	--self:DoWndStartScale(0,self.mRoot)
	--self:DoWndStartMove(0, LWnd.StartMoveLeft, self.mPopup)

	self:InitData()
	self:WndNetMsgRecv(LProtoIds.WonderlandQuestResp,function(...) self:OnWonderlandQuestResp(...) end)
	gModelWonderland:WonderlandQuestReq(0)
	self:InitUIEvent()
end

function UIEdenTk:InitUIEvent()

	self:SetWndClick(self.mMask,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseTip,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)

end

function UIEdenTk:Clear()
	if self._iconList then
		self._iconList:Destroy()
		self._iconList = nil
	end
end

function UIEdenTk:OnWonderlandQuestResp(pb)
	self._questId = pb.questId
	self._schedule = pb.schedule
	self._status =pb.status

	self:RefreshUI()
end


function UIEdenTk:OnClickGet()
	local taskCfg = gModelWonderland:GetTaskConfig(self._questId)
	local goal = taskCfg.condition
	if self._schedule< goal then
		--local str =ccClientText(12210)-- "任务未完成"
		--GF.ShowMessage(str)

		self:WndClose()
		return
	end

	local status = self._status
	if status == 0 then
		local str =ccClientText(12210)-- "任务未完成"
		GF.ShowMessage(str)
	elseif status == 1 then
		gModelWonderland:WonderlandQuestReq(1)
	elseif status == 2 then
		local str =ccClientText(12211)-- "奖励已领取"
		GF.ShowMessage(str)
	end
end

function UIEdenTk:RefreshUI()
	local taskCfg = gModelWonderland:GetTaskConfig(self._questId)
	local taskName = ccLngText(taskCfg.name)
	self:SetWndText(self.mMainTitle,taskName)
	local spineKey = taskCfg.prefabName
	self:CreateWndSpine(self.mRole,spineKey,spineKey,false,function (spine)
		spine:SetScale(2)
		spine:PlayAnimation(0,"idle",true)
	end)

	local text = ccLngText(taskCfg.text)
	local keyTable = {}

	local wndType = self:GetWndArg("wndType") or 1
	local themIdList = gModelWonderland:GetThemeSelections()
	if not themIdList then
		return
	end
	if wndType == 2 then
		local themeId = gModelWonderland:GetThemeId()
		themIdList = {themeId}
	end

	local nameList = {}
	for k,v in ipairs(themIdList) do
		local themeCfg = gModelWonderland:GetThemeConfig(v)
		if themeCfg then
			local name = ccLngText(themeCfg.name)
			table.insert(nameList,name)
		end

	end

	keyTable["a1"] = table.concat(nameList,",")

	local str = string.gsub(text,"#(%w+)#",keyTable)

	self:SetWndText(self.mPost,str)

	local goal = taskCfg.condition
	local color = "red"
	if self._schedule>= goal then
		color = "yellow"
	end
	local scheduleStr = LUtil.FormatColorStr(self._schedule,color)

	local desc = ccLngText(taskCfg.description)

	str = string.format("%s  (%s/%s)",desc,scheduleStr,goal)
	self:SetWndText(self.mTaskDesc,str)

	str =ccClientText(16742)-- "任务要求"
	self:SetWndText(self.mTitle1,str)
	str = ccClientText(16743)--"概率奖励"
	self:SetWndText(self.mTitle2,str)
	str = self._stateStr[self._status]
	local text = self:FindWndTrans(self.mGotoBtn,'Text')
	self:SetWndText(text,str)
	self:InitTextSizeWithLanguage(text, -2)
	str =ccClientText(10103)-- "点击空白处关闭界面"
	self:SetWndText(self.mCloseTip,str)

	local btnType = nil
	if self._status == 0 then
		btnType= "blue_1"
	elseif self._status == 1 then
		btnType = "yellow_1"
	else
		btnType = "ash_1"
	end
	self:SetColorBtnImg(self.mGotoBtn,btnType)

	local rewardId = gModelWonderland:GetTaskRewardId(self._questId)
	local reward = gModelWonderland:GetEventReward(rewardId)


	local list = {}
	for k,v in pairs(reward) do
		local trewardData = table.clone(v)
		local rewardData = self._actRewardList[trewardData.itemId]
		if rewardData then
			trewardData.itemNum = math.ceil(trewardData.itemNum * self._actData)
		end
		table.insert(list,trewardData)
	end

	local refs = gModelGrade:GetPrivilegeEffRefs(40)
	local gradeList = {}
	for i, v in ipairs(refs) do
		local itemlist = LxDataHelper.ParseItem(v.effectValue)
		for j, k in ipairs(itemlist) do
			local item = gradeList[k.itemId]
			if item then
				item.itemNum = item.itemNum + k.itemNum
				gradeList[item.itemId] = item
			else
				gradeList[k.itemId] = k
			end
		end
	end
	for i, v in ipairs(list) do
		local item = gradeList[v.itemId]
		if item then
			v.itemNum = v.itemNum + item.itemNum
			gradeList[v.itemId] = nil
		end
	end
	for i, v in pairs(gradeList) do
		table.insert(list,v)
	end

	local uiIconEasyList = self._iconList
	if not uiIconEasyList then
		uiIconEasyList = UIIconEasyList:New()
		self._iconList = uiIconEasyList
		uiIconEasyList:Create(self, self.mItemList)
		--uiIconEasyList:EnableIconAni(true)
	end
	uiIconEasyList:RefreshList(list)

	if #list>4 then
		uiIconEasyList:EnableScroll(true,true)
	end

	self:SetWndClick(self.mGotoBtn,function () self:OnClickGet() end,LSoundConst.CLICK_BUTTON_COMMON)
end

function UIEdenTk:InitData()
	self._stateStr =
	{
		[0]=ccClientText(16733),--"前往",
		[1]=ccClientText(12207),--"领取",
		[2]=ccClientText(12208),--"已领取",
	}
	self._actData = 1
	local actData = gModelActivity:GetActivityListByModelId(ModelActivity.COMMONRANK,"wonderLand")
	if actData then
		self._actData = actData
	end
	self._actRewardList = {}
	local actReward = gModelActivity:GetActivityListByModelId(ModelActivity.COMMONRANK,"wonderLandReward")
	if actReward then
		actReward = string.split(actReward,",")
		for i,v in ipairs(actReward) do
			local refId = tonumber(v)
			self._actRewardList[refId] = refId
		end
	end
end

------------------------------------------------------------------
return UIEdenTk


