---
--- Created by Administrator.
--- DateTime: 2023/10/1 16:02:53
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEdenKey:LWnd
local UIEdenKey = LxWndClass("UIEdenKey", LWnd)

local typeLayoutElement = typeof(UnityEngine.UI.LayoutElement)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEdenKey:UIEdenKey()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEdenKey:OnWndClose()
	if self._seqCom then
		self._seqCom:Destroy()
		self._seqCom = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEdenKey:OnCreate()
	LWnd.OnCreate(self)

	self._seqCom = SequenceCom:New()

	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEdenKey:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	--self:DoWndStartScale(0,self.mRoot)

	self:SetStaticContent()
	self:InitWndPara()

	self:RefreshUI()
	self:InitUIEvent()
end

function UIEdenKey:InitWndPara()
	local data = self:GetWndArg("data")
	self._eventType = data.eventType
	self._data = data
	self._eventId = data.eventId
	self._eventCfg = gModelWonderland:GetEventConfig(data.eventId)
	local textId = gModelWonderland:GetEventTextId(self._eventId)
	local textData = gModelWonderland:GetDefaultEventText(textId)
	self._textConfig = textData
end

function UIEdenKey:OnDrawOrgan(list,item,itemdata,itempos)
	--local bg = self:FindWndTrans(item,"bg")
	local select = self:FindWndTrans(item,"select")
	local intro = self:FindWndTrans(item,"intro")
	local hair = self:FindWndTrans(item,"hair")

	local isSelect = self._select== itempos
	CS.ShowObject(select,isSelect)
	CS.ShowObject(hair,false)
	self:SetWndText(intro,itemdata.text)
	self:InitTextLineWithLanguage(intro, -30)

	self._chooseUIList[itempos] = item

	self:SetWndClick(item,function () self:OnClickAnswer(itempos,itemdata) end,LSoundConst.CLICK_BUTTON_COMMON)
end

function UIEdenKey:OnOtherConfirm()
	local canSelect = self._data.canSelect
	local eventcfg = self._eventCfg
	local eventName = ccLngText(eventcfg.name)
	if not canSelect then
		local str =ccClientText(16704) --"您还没有找到%s,不可回答!"
		str = string.replace(str,eventName)
		GF.ShowMessage(str)
		return
	end

	local answerIndex = self._answerIndex
	if self._isNoSelect then
		answerIndex = 0
	end


	if not answerIndex then
		local str =ccClientText(16705) --"请先选择其中一项"
		GF.ShowMessage(str)
	else
		local state = self._data.state
		local gridIndex = self._data.gridIndex
		if state == StructWonderlandGrid.ALLOW then
			gModelWonderland:WonderlandOpsReq(ModelWonderland.EVENT_SELECT_GRID,tostring(gridIndex))
		end

		gModelWonderland:WonderlandOpsReq(self._eventType,tostring(answerIndex))

		self:WndClose()
	end

end

function UIEdenKey:InitUIEvent()
	self:SetWndClick(self.mCancel,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mMask,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseTip,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end


function UIEdenKey:ShowCommonContent()
	local eventCfg = self._eventCfg
	local name = ccLngText(eventCfg.name)
	self:SetWndText(self.mMainTitle,name)

	local canSelect = self._data.canSelect
	self:SetWndImageGray(self.mOk,not canSelect)

	self:SetWndText(self.mPost,self._textConfig.desc)

	local spineKey = eventCfg.prefab
	if string.isempty(spineKey) then
		return
	end
	local scale = eventCfg.prefabSize or 1
	self:CreateWndSpine(self.mRole,spineKey,spineKey,false,function (spine)
		spine:SetScale(scale)
		spine:PlayAnimation(0,"idle",true)
	end)

end

function UIEdenKey:ShowAnswerList()
	local textData = self._textConfig
	local eventcfg = self._eventCfg
	local para = eventcfg.parameter
	local tempStrs = string.split(para,"=")
	local itemId =nil
	if #tempStrs>0 then
		itemId = tonumber(tempStrs[1])
	end
	local itemNum = gModelWonderland:GetItemNum(itemId)
	if itemNum> 0 then
		self._itemEnough= true
	end

	self._itemId = itemId
	self._select = 0
	self._correct = tonumber(self._data.moreInfo)

	local selectList = {}
	for k,v in ipairs(textData.answer) do
		local data =
		{
			text = v,
			answer = k-1
		}
		table.insert(selectList,data)
	end


	self._chooseUIList ={}
	local list = self:GetUIScroll("uiList")
	list:Create(self.mChooseList,selectList,function (...) self:OnDrawAnswer(...) end)
	local cnt = #selectList
	if cnt>2 then
		list:EnableScroll(true,false)
	end

	--CS.ShowObject(self.mChooseList,false)
	--CS.ShowObject(self.mChooseList,true)
	--self:SetContentHeight(cnt)
end

function UIEdenKey:ShowLeaveList()
	local eventPara = self._eventCfg.parameter
	local relaList = LxDataHelper.ParseNumber_Sign(eventPara,";")


	local selectList = {}
	for k,v in ipairs(relaList) do

		local eventCfg = gModelWonderland:GetEventConfig(v)
		local name =ccLngText(eventCfg.name)

		local data =
		{
			text = name,
			answer = k
		}
		table.insert(selectList,data)

	end


	CS.ShowObject(self.mIntro,false)
	CS.ShowObject(self.mChooseList,true)
	self._chooseUIList ={}
	local list = self:GetUIScroll("uiList")
	list:Create(self.mChooseList,selectList,function (...) self:OnDrawLeaves(...) end)
	local cnt = #selectList
	if cnt>2 then
		list:EnableScroll(true,false)
	end

	--self:SetContentHeight(cnt)
end

function UIEdenKey:OnDrawLeaves(list,item,itemdata,itempos)
	local select = self:FindWndTrans(item,"select")
	local intro = self:FindWndTrans(item,"intro")
	local hair = self:FindWndTrans(item,"hair")

	local isSelect = self._select== itempos
	CS.ShowObject(select,isSelect)
	CS.ShowObject(hair,false)
	self:SetWndText(intro,itemdata.text)
	self:InitTextLineWithLanguage(intro, -30)

	self._chooseUIList[itempos] = item

	self:SetWndClick(item,function () self:OnClickAnswer(itempos,itemdata) end,LSoundConst.CLICK_BUTTON_COMMON)
end

function UIEdenKey:OnDrawAnswer(list, item,itemdata,itempos)
	--local bg = self:FindWndTrans(item,"bg")
	local select = self:FindWndTrans(item,"select")
	local intro = self:FindWndTrans(item,"intro")
	local hair = self:FindWndTrans(item,"hair")

	local isSelect = self._select== itempos
	CS.ShowObject(select,isSelect)
	local isCorrect = itemdata.answer == self._correct
	local showHair = isCorrect and self._itemEnough
	local iconPath = gModelItem:GetItemImgByRefId(self._itemId)
	self:SetWndEasyImage(hair,iconPath,nil,true)
	CS.ShowObject(hair,showHair)
	self:SetWndText(intro,itemdata.text)
	self:InitTextLineWithLanguage(intro, -30)
	self._chooseUIList[itempos] = item

	self:SetWndClick(item,function () self:OnClickAnswer(itempos,itemdata) end,LSoundConst.CLICK_BUTTON_COMMON)
end

function UIEdenKey:OnClickLeavesConfirm()
	local canSelect = self._data.canSelect
	local eventcfg = self._eventCfg
	local eventName = ccLngText(eventcfg.name)
	if not canSelect then
		local str =ccClientText(16704) --"您还没有找到%s,不可回答!"
		str = string.replace(str,eventName)
		GF.ShowMessage(str)
		return
	end

	local answerIndex = self._answerIndex
	if self._isNoSelect then
		answerIndex = 0
	end


	if not answerIndex then
		local str =ccClientText(16705) --"请先选择其中一项"
		GF.ShowMessage(str)
	else
		local state = self._data.state
		local gridIndex = self._data.gridIndex
		if state == StructWonderlandGrid.ALLOW then
			gModelWonderland:WonderlandOpsReq(ModelWonderland.EVENT_SELECT_GRID,tostring(gridIndex))
		end

		gModelWonderland:WonderlandOpsReq(self._eventType,tostring(answerIndex))

		self:WndClose()
	end
end

function UIEdenKey:SetContentHeight(selectCnt)
	local height = 0
	if selectCnt == 0 then
		height = 430
	else
		local contentMin = selectCnt*100
		contentMin = math.min(contentMin,500)
		if self._eventType == ModelWonderland.EVENT_PROTECTOR or self._eventType == ModelWonderland.EVENT_WORLD_LEAVES then
			contentMin = contentMin + 60
		end
		contentMin = math.max(contentMin,200)
		height = contentMin + 70
	end



	local layoutEle = self.mContentBg:GetComponent(typeLayoutElement)
	if layoutEle then
		layoutEle.minHeight = height
		layoutEle.preferredHeight = height
	end

end

function UIEdenKey:SetStaticContent()
	local str = ccClientText(19626)
	local text =self:FindWndTrans(self.mOk,"text")
	self:SetWndText(text,str)

	self:SetWndText(self.mCloseTip,ccClientText(10103))
end

function UIEdenKey:RefreshUI()
	if self._eventType == ModelWonderland.EVENT_PROTECTOR then
		self:ShowAnswerWnd()
	elseif self._eventType == ModelWonderland.EVENT_ORGAN then
		self:ShowOrganWnd()
	elseif self._eventType == ModelWonderland.EVENT_WORLD_LEAVES then
		self:ShowWorldLeaves()
	end

	CS.ShowObject(self.mChooseList,false)
	local seq = self._seqCom:CreateSeq("layoutDelay")
	seq:AppendInterval(0.02)
	seq:OnComplete(function ()
		CS.ShowObject(self.mChooseList,true)
	end)
	seq:PlayForward()
end

function UIEdenKey:ShowOrganWnd()
	self:ShowCommonContent()
	self:ShowOrganList()
	CS.ShowObject(self.mTitle,false)
	self:SetWndClick(self.mOk,function () self:OnOtherConfirm() end,LSoundConst.CLICK_BUTTON_COMMON)
end

function UIEdenKey:ShowAnswerWnd()
	self:ShowCommonContent()
	self:ShowAnswerList()
	CS.ShowObject(self.mIntro,false)
	local str = ccClientText(16756)
	self:SetWndText(self.mTitle,str)
	CS.ShowObject(self.mTitle,true)
	self:SetWndClick(self.mOk,function () self:OnClickConfirm() end,LSoundConst.CLICK_BUTTON_COMMON)
end

function UIEdenKey:ShowWorldLeaves()
	self:ShowCommonContent()
	self:ShowLeaveList()
	local str =ccClientText(16791) --"世界树叶子可以指定平台为以下任意事件"
	self:SetWndText(self.mTitle,str)
	CS.ShowObject(self.mTitle,true)
	self:SetWndClick(self.mOk,function () self:OnOtherConfirm() end,LSoundConst.CLICK_BUTTON_COMMON)


end

function UIEdenKey:OnClickConfirm()
	local canSelect = self._data.canSelect
	local eventcfg = self._eventCfg
	local eventName = ccLngText(eventcfg.name)
	if not canSelect then
		local str =ccClientText(16704) --"您还没有找到%s,不可回答!"
		str = string.replace(str,eventName)
		GF.ShowMessage(str)
		return
	end

	local answerIndex = self._answerIndex
	if not answerIndex then
		local str =ccClientText(16705) --"请先选择其中一项"
		GF.ShowMessage(str)
	else

		local state = self._data.state
		local gridIndex = self._data.gridIndex
		if state == StructWonderlandGrid.ALLOW then
			gModelWonderland:WonderlandOpsReq(ModelWonderland.EVENT_SELECT_GRID,tostring(gridIndex))
		end


		local isCorrect = answerIndex == self._correct
		gModelWonderland:WonderlandOpsReq(self._eventType,tostring(answerIndex))
		if not isCorrect then
			local layerIndex = self._data.layerIndex
			GF.OpenWnd("UIEdenMonsterPop",{layerIndex =layerIndex,gridIndex = gridIndex,wndType = 1 })
		end
		self:WndClose()
	end
end

function UIEdenKey:ShowOrganList()
	local eventPara = self._eventCfg.parameter
	local relaList = LxDataHelper.ParseNumber_Sign(eventPara,";")
	local checkList = {}
	for k,v in ipairs(relaList) do
		local data =
		{
			index = k,
			typeId = v,
		}
		checkList[v] = data
	end
	local exist = gModelWonderland:CheckRelativeEvents(checkList)

	local textData = self._textConfig

	local selectList = {}
	for k,v in ipairs(textData.answer) do
		local eventType = exist[k]
		if eventType then
			local data =
			{
				text = v,
				answer = eventType
			}
			table.insert(selectList,data)
		end
	end

	if #selectList == 0 then
		local str =ccClientText(16792) --"当前没有可以破解的机关了"
		self:SetWndText(self.mIntro,str)
		CS.ShowObject(self.mIntro,true)
		CS.ShowObject(self.mChooseList,false)
		self._isNoSelect = true
		return
	end
    CS.ShowObject(self.mIntro,false)
	CS.ShowObject(self.mChooseList,true)
	self._chooseUIList ={}
	local list = self:GetUIScroll("uiList")
	list:Create(self.mChooseList,selectList,function (...) self:OnDrawOrgan(...) end)
	local cnt = #selectList
	if cnt>2 then
		list:EnableScroll(true,false)
	end

	--self:SetContentHeight(cnt)
end



function UIEdenKey:OnClickAnswer(index,itemdata)
	if self._select == index then
		return
	end
	local item = self._chooseUIList[self._select]
	if item then
		local select = self:FindWndTrans(item,"select")
		CS.ShowObject(select,false)
	end
	item = self._chooseUIList[index]
	if item then
		local select = self:FindWndTrans(item,"select")
		CS.ShowObject(select,true)
	end

	self._select = index

	self._answerIndex = itemdata.answer
end



------------------------------------------------------------------
return UIEdenKey


