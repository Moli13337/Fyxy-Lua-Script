---
--- Created by BY.
--- DateTime: 2023/10/23 16:04:11
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMinLineAwards2:LWnd
local UIMinLineAwards2 = LxWndClass("UIMinLineAwards2", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMinLineAwards2:UIMinLineAwards2()
	self.commonUIList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMinLineAwards2:OnWndClose()
	self:ClearCommonIconList(self.commonUIList)
	if self.timer then
        LxTimer.DelayTimeStop(self.timer)
        self.timer = nil
    end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMinLineAwards2:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMinLineAwards2:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()

	gModelInstance:InstanceFreeTheGirdReq()
end

function UIMinLineAwards2:UpdateDate()
	self.battleNode = gModelInstance:GetRawBattleNode(1)
	self.battleNum = gModelInstance:GetBattleNum(1)
	if self.lockLen < 5 then
		self:UpdateLock()
	else
		self:UpdateOpen()
	end
	CS.ShowObject(self.mLockObj, self.lockLen < 5)
	CS.ShowObject(self.mOpenObj, self.lockLen >= 5)
end

function UIMinLineAwards2:InitMessage()
	self:WndNetMsgRecv(LProtoIds.InstanceRewardResp,function (...)
		gModelInstance:OnPlayerInstanceReq()
	end)
	self:WndNetMsgRecv(LProtoIds.PlayerInstanceResp,function (...)
		gModelInstance:InstanceFreeTheGirdReq()
	end)
	self:WndNetMsgRecv(LProtoIds.InstanceFreeTheGirdResp, function(pb)
		self.canClick = true
		self.lockLen = #pb.position
		self.lockData = {}
		for _, v in ipairs(pb.position) do
			self.lockData[v] = true
		end
		if self._isTriggerRewardPlot and self._isTriggerRewardPlot == 1 then
			if self.lockLen >= 5 then
				self._isTriggerRewardPlot = 2
			end
		end
		self:UpdateDate()
	end)
end

function UIMinLineAwards2:UpdateOpen()
	local curChapterId = gModelInstance:GetChapterId(self.curSeleDiffLvl)
	local isGetRewards = gModelInstance:GetRewardIds()
	if not self.chatperRewardList then
		self.chatperRewardList = {}
		local cfg = GameTable.MainInstanceProRewardRef
		for _, v in pairs(cfg) do
			local stage = tostring(v.refId)
			local index = #stage - 4
			local chatper = tonumber(string.sub(stage, 1, index))
			if v.type ~= 1 then
				self.chatperRewardList[chatper] = self.chatperRewardList[chatper] or {}
				local data = {
					reward = LxDataHelper.ParseItem(v.reward),
					sort = v.sort,
					isBig = v.specialId == 2,
					stageId = v.refId,
				}
				table.insert(self.chatperRewardList[chatper], data)
			else
				self.chatperRewardList[chatper] = {}
			end
		end

		for _, v in pairs(self.chatperRewardList) do
			table.sort(v, function(a, b)
				return a.sort < b.sort
			end)
		end
	end

	local chapterId = curChapterId
	for k, v in ipairs(self.chatperRewardList) do
		local isBreak = false
		for _, v2 in ipairs(v) do
			-- local num = gModelInstance:GetMissionCfg(v2.stageId).num
			-- local isPass = num < self.battleNum or (num <= self.battleNum and self.battleNode == -1)
			-- if k <= curChapterId and isPass and isGetRewards[v2.stageId] == nil then
			-- 	chapterId = k
			-- 	isBreak = true
			-- 	break
			-- end
			if isGetRewards[v2.stageId] == nil then
				chapterId = k
				isBreak = true
				break
			end
		end
		if isBreak then
			break
		end
	end

	local rewards = self.chatperRewardList[chapterId] or self.chatperRewardList[chapterId + 1]
	local index = 1
	local pass = 0
	local bigCfg
	self.showOneKey = false
	for _, v in ipairs(rewards) do
		for _, v2 in ipairs(v.reward) do
			local trans = CS.FindTrans(self.mProBar2, "Item" .. index)
			local data = {
				reward = v2,
				isBig = v.isBig,
				stageId = v.stageId,
				isGet = isGetRewards[v.stageId] ~= nil
			}
			self:SetReward(trans, data)
			index = index + 1

			local num = gModelInstance:GetMissionCfg(v.stageId).num
			local isPass = num < self.battleNum or (num <= self.battleNum and self.battleNode == -1)
			if isPass then
				pass = pass + 1
			end
			if isGetRewards[v.stageId] == nil and isPass then
				self.showOneKey = true
			end
			if v.isBig then
				bigCfg = gModelInstance:GetMissionCfg(v.stageId)
			end
		end
	end
	self.oneKeyBtnEff:SetVisible(self.showOneKey)
	local ImageCom = self.mProBar2:GetComponent(typeof(UnityEngine.UI.Image))
	ImageCom.fillAmount = (pass - 1) / (index - 2)
	for i = 1, 6 do
		local trans = CS.FindTrans(self.mProBar2, "Item" .. i)
		CS.ShowObject(trans, i <= index - 1)
		if i == 1 then
			trans.localPosition = Vector2.New(-215, 0)
		elseif i == index - 1 then
			trans.localPosition = Vector2.New(225, 0)
		else
			local per = 1 / (index - 2) * 440
			local x = per * (i - 1) + -215
			trans.localPosition = Vector2.New(x, 0)
		end
	end

	if bigCfg then
		local num = gModelInstance:GetMissionCfg(bigCfg.refId).num
		local rewardCfg = LxDataHelper.ParseItem_4(GameTable.MainInstanceProRewardRef[bigCfg.refId].reward)
		local isPass = num < self.battleNum or (num <= self.battleNum and self.battleNode == -1)
		local s = string.replace(ccClientText(45007), gModelGeneral:GetCommonItemName(rewardCfg), rewardCfg.itemNum)
		if not isPass then
			local num = math.max(1, num - self.battleNum)
			s = string.replace(ccClientText(45004), num, gModelGeneral:GetCommonItemName(rewardCfg), rewardCfg.itemNum)
		end
		self:SetWndText(self.mTipsText2, s)
	end
end

function UIMinLineAwards2:InitEvent()
	self:SetWndClick(self.mMask, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mOnKeyBtn, function()
		self:OnClickOneKey()
	end)
	self:SetWndClick(self.mLookBtn, function()
		GF.OpenWnd("UIMinLineAwardsTips", { self.lockLen })
	end)

	self:WndEventRecv(EventNames.CLOSE_REWARD_WND, function()
		if self._isTriggerRewardPlot and self._isTriggerRewardPlot == 2  then
			self._isTriggerRewardPlot = nil
			gModelPlot:CheckMainLineTrigger()
		end
	end)
end

function UIMinLineAwards2:OnClickOneKey()
	if self.showOneKey then
		gModelInstance:OnInstanceRewardReq(-1)
	else
		GF.ShowMessage(ccClientText(45005))
	end
end
function UIMinLineAwards2:InitCommand()
	-----------------------------------------------
	---text
	self:SetWndText(self.mCloseTip, ccClientText(17003))
	self:SetWndText(self.mTipsText, ccClientText(45001))
	self:SetWndText(CS.FindTrans(self.mOnKeyBtn, "Text"), ccClientText(16310))

	-----------------------------------------------
	---eff
	self:CreateWndEffect(self.mMask, "fx_ui_xiannv_aixin", "fx_ui_xiannv_aixin", 100)
	self:CreateWndEffect(CS.FindTrans(self.mLockObj, "Title"), "fx_ui_xiannv_biaoti_1", "fx_ui_xiannv_biaoti_1", 100)
	self:CreateWndEffect(CS.FindTrans(self.mOpenObj, "Title"), "fx_ui_xiannv_biaoti_1", "fx_ui_xiannv_biaoti_1", 100)
	self.oneKeyBtnEff = self:CreateWndEffect(self.mOnKeyBtn, "fx_ui_xiannv_yijianlingqu", "fx_ui_xiannv_yijianlingqu", 100)
	self.oneKeyBtnEff:SetVisible(false)

	-----------------------------------------------
	---spine
	---

	 self._handcuffsEffNameAndPos ={
		 [1]={
			 eff=3,
			 pos=Vector2.New(30.1,274.4)
		 },
		 [2]={
			 eff=2,
			 pos=Vector2.New(-101,188)
		 },
		 [3]={
			 eff=4,
			 pos=Vector2.New(-70.3,-69.2)
		 },
		 [4]={
			 eff=1,
			 pos=Vector2.New(17.1,-19)
		 },
		 [5]={
			 eff=5,
			 pos=Vector2.New(178.3,-17.7)
		 },
	 }

	CS.ShowObject(self.mOpenObj,false)
	CS.ShowObject(self.mLockObj,false)

	local spine = GameTable.CharacterEffectRef[1603].heroDrawing
	local spineRoot = self:FindWndTrans(self.mOpenObj, "Role")
	CS.ShowObject(spineRoot,false)
	self:CreateWndSpine(spineRoot, spine, spine,nil,function()
		if not self:IsWndValid() then return end
		CS.ShowObject(spineRoot,true)
	end)

	local imgRoot = self:FindWndTrans(self.mLockObj, "Role")
	CS.ShowObject(imgRoot,false)
	self:SetWndEasyImage(imgRoot,"adventure1_panel4",function()
		if not self:IsWndValid() then return end
		CS.ShowObject(imgRoot,true)
	end,true)
end

function UIMinLineAwards2:OnClickHelp()
	GF.OpenWnd("UIBzTips", {refId = 80})
end

function UIMinLineAwards2:SetReward(trans, data)
	if not trans then
		return
	end
	local root = CS.FindTrans(trans, "ItemRoot")
	local proImg = CS.FindTrans(trans, "Pro")
	local stageText = CS.FindTrans(trans, "StageText")
	local isGet = CS.FindTrans(trans, "IsGet")

	local num = gModelInstance:GetMissionCfg(data.stageId).num
	local isPass = num < self.battleNum or (num <= self.battleNum and self.battleNode == -1)
	local res = isPass and "adventure1_point1" or "adventure1_point2"
	self:SetWndEasyImage(proImg, res)
	local stageCfg = gModelInstance:GetMissionCfg(data.stageId)
	self:SetWndText(stageText, stageCfg.belongChapterId .. "-" .. stageCfg.sort)
	CS.ShowObject(isGet, isPass and data.isGet)

	local scale = data.isBig and 0.68 or 0.6
	root.localScale = Vector2.New(scale, scale)
	isGet.localScale = Vector2.New(scale, scale)
	local instanceId = root:GetInstanceID()
	if not self.commonUIList[instanceId] then
		self.commonUIList[instanceId] = CommonIcon:New()
		self.commonUIList[instanceId]:Create(root)
	end
	self.commonUIList[instanceId]:SetCommonReward(data.reward.itemType, data.reward.itemId, data.reward.itemNum)
	self.commonUIList[instanceId]:DoApply()
	self.commonUIList[instanceId]:SetAnchoredPosition(Vector2.New(0, 0))

	if isPass and not data.isGet then
		self:CreateWndEffect(root, "fx_ui_qiandao_lingqutishi", instanceId, 110, nil, nil, nil, nil, nil, nil, nil, function(dpTrans)
			if dpTrans then
				dpTrans.localPosition = Vector2.New(x, 55)
			end
		end)
	else
		self:DestroyWndEffectByKey(instanceId)
	end

	self:SetWndClick(root, function()
		if isPass and not data.isGet then
			gModelInstance:OnInstanceRewardReq(data.stageId)
			return
		end
		gModelGeneral:ShowCommonItemTipWnd(data.reward)
	end)
	self:SetWndClick(isGet, function()
		gModelGeneral:ShowCommonItemTipWnd(data.reward)
	end)
end

function UIMinLineAwards2:UpdateLock()
	if not self.handcuffsStage then
		self.handcuffsStage = {}
		local cfg = GameTable.MainInstanceProRewardRef
		for _, v in pairs(cfg) do
			if v.type == 1 then
				table.insert(self.handcuffsStage, v.refId)
			end
		end
		table.sort(self.handcuffsStage, function(a, b)
			return a < b
		end)
	end
	local pass = 0
	for i = 1, 5 do
		local trans = CS.FindTrans(self.mHandcuffsObj, "Handcuffs" .. i)
		local eff = CS.FindTrans(trans, "Eff")
        local num = gModelInstance:GetMissionCfg(self.handcuffsStage[i]).num
		local isPass = num < self.battleNum or (num <= self.battleNum and self.battleNode == -1)

		if  gLGameTable:IsSensitive() then
			self:SetAnchorPos(trans,self._handcuffsEffNameAndPos[i].pos)
			--图片也要重新设置
			local Image = CS.FindTrans(trans, "Image")
			local imageName = "adventure1_icon_"..self._handcuffsEffNameAndPos[i].eff
			self:SetWndEasyImage(Image,imageName,nil,true)
		end
		if isPass then
			if not self.lockData[i] then
				if  gLGameTable:IsSensitive() then
					local effName = "fx_ui_xiannv_kejiesuo_"..self._handcuffsEffNameAndPos[i].eff
					self:CreateWndEffect(eff, effName, trans.gameObject.name, 100)
					CS.ShowObject(trans, true)

					local effPos
					if i== 3 then
						effPos= Vector2.New(-18.4,5)
						elseif i==5 then
						effPos= Vector2.New(-4.6,17.1)
					else
						effPos= Vector2.New(0,0)
					end
					self:SetAnchorPos(eff,effPos)
				else
					self:CreateWndEffect(eff, "fx_ui_xiannv_kejiesuo_" .. i, trans.gameObject.name, 100)
					CS.ShowObject(trans, true)
				end

			else
				self:DestroyWndEffectByKey(trans.gameObject.name)
				CS.ShowObject(trans, false)
			end
		else
			CS.ShowObject(trans, true)
			self:DestroyWndEffectByKey(trans.gameObject.name)
		end
		self:SetWndClick(trans, function()
			if isPass and not self.lockData[i] then
				if self.canClick then
					self.canClick = false
					self:DestroyWndEffectByKey(trans.gameObject.name)
					self:CreateWndEffect(eff, "fx_ui_map_world_jiesuo", trans.gameObject.name .. "jiesuo", 100)
					self.timer = LxTimer.DelayTimeCall(function()
						self._isTriggerRewardPlot = 1
						gModelInstance:InstanceFreeTheGirdReq(i)
						self.timer = nil
					end, 1.5)
				end
			else
				GF.ShowMessage(ccClientText(45008))
			end
		end)

		trans = CS.FindTrans(self.mProBar, "Pro" .. i)
		local res = isPass and "adventure1_point1" or "adventure1_point2"
		self:SetWndEasyImage(trans, res)
		if isPass then
			pass = pass + 1
		end
	end

	local ImageCom = self.mProBar:GetComponent(typeof(UnityEngine.UI.Image))
	ImageCom.fillAmount = math.max(pass - 1, 0) / 4

	self:SetWndText(self.mProText, string.replace(ccClientText(45002), self.lockLen, 5))

	if not self.desData then
		local desInfo = GameTable.MainInstanceConfigRef["InstanceRewardText"]
		self.desData = string.split(desInfo, ",")
	end
	local des = self.desData[self.lockLen + 1]
	if des then
		self:SetWndText(self.mDesText, ccClientText(tonumber(des)))
	end
end
------------------------------------------------------------------
return UIMinLineAwards2


