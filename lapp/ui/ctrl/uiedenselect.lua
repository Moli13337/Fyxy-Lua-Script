---
--- Created by Administrator.
--- DateTime: 2023/10/1 11:33:38
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEdenSelect:LWnd
local UIEdenSelect = LxWndClass("UIEdenSelect", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEdenSelect:UIEdenSelect()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEdenSelect:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEdenSelect:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEdenSelect:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	--self:DoWndStartScale(0,self.mRoot)

	self:InitData()
	self:SetStaticContent()
	self:InitWndPara()
	self:RefreshUI()
	self:InitUIEvent()

	self:WndNetMsgRecv(LProtoIds.WonderlandOpsResp,function (pb)
		local type = pb.type
		if type == self._eventType then
			self:WndClose()
		end
	end)

end

function UIEdenSelect:InitUIEvent()
	self:SetWndClick(self.mCancel,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mMask,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mOk,function () self:OnClickConfirm() end,LSoundConst.CLICK_BUTTON_COMMON)
	self:SetWndClick(self.mCloseTip,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIEdenSelect:FourConfirm()
	local canSelect = self._data.canSelect
	if not canSelect then
		local str =ccClientText(16779)-- "您还没有靠近%s")
		str = string.replace(str,self._name)
		GF.ShowMessage(str)
		return
	end

	local select = self._select
	if select == 2 then
		self:WndClose()
	elseif select== 0 then
		local str =ccClientText(16729)-- "请先选择其中一项")
		GF.ShowMessage(str)
	elseif select == 1 then
		local state = self._data.state
		local gridIndex = self._data.gridIndex
		if state == StructWonderlandGrid.ALLOW then
			gModelWonderland:WonderlandOpsReq(ModelWonderland.EVENT_SELECT_GRID,tostring(gridIndex))
		end

		if self._needOperEvent[self._eventType] then
			gModelWonderland:WonderlandOpsReq(self._eventType)
		end


		self:WndClose()
	end
end

function UIEdenSelect:BoxConfirm()
	local select = self._select
	if select == 2 then
		self:WndClose()
	elseif select == 0 then
		local str =ccClientText(16729)-- "请先选择其中一项"
		GF.ShowMessage(str)
	else
		local canSelect = self._data.canSelect
		if not canSelect then
			local str =ccClientText(16727)-- "您还没有找到宝箱所在,无法打开!"
			GF.ShowMessage(str)
			return
		end

		local state = self._data.state
		local gridIndex = self._data.gridIndex
		local layerIndex = self._data.layerIndex
		if state == StructWonderlandGrid.ALLOW then
			gModelWonderland:WonderlandOpsReq(ModelWonderland.EVENT_SELECT_GRID,tostring(gridIndex))
		end

		local eventId = self._data.eventId
		local event = gModelWonderland:GetEventData(layerIndex,gridIndex,eventId)

		if not event then
			return
		end

		local type = event.type
		if type == 1 then
			gModelWonderland:WonderlandOpsReq(self._eventType)
			GF.OpenWnd("UIEdenMonsterPop",{gridIndex= gridIndex,layerIndex = layerIndex ,wndType = 1})
			self:WndClose()
		else
			gModelWonderland:WonderlandOpsReq(self._eventType)
			--self:WndClose()
		end
	end
end



function UIEdenSelect:ShowSelectContent(itemData)
	self._select = itemData.select
	local itemList = self:GetUIScroll("selectList")
	itemList:Create(self.mChooseList,itemData.itemdatas,function (...) self:OnDrawItem(...) end)
end

function UIEdenSelect:InitWndPara()
	self._wndType = self:GetWndArg("wndType")
	local data = self:GetWndArg("data")
	self._eventType = self:GetWndArg("eventType")
	self._data = data
	local eventCfg = gModelWonderland:GetEventConfig(data.eventId)
	self._name = ccLngText(eventCfg.name)
	local textId = gModelWonderland:GetEventTextId(data.eventId)
	local textData = gModelWonderland:GetDefaultEventText(textId)
	self._eventCfg = eventCfg
	self._textData = textData

	self._selectList = {}
	for k,v in ipairs(textData.answer) do
		local data = {
			title = v,
			index = k
		}

		table.insert(self._selectList,data)
	end

end

function UIEdenSelect:OnClickConfirm()
	local wndType = self._wndType
	if wndType == 1 then --宝箱怪
		self:BoxConfirm()
	elseif wndType == 2 then --拾取
		self:GoldHairConfirm()
	elseif wndType == 4 then --
		self:FourConfirm()
	end
end



function UIEdenSelect:OnDrawItem(list,item,itemdata,itempos)
	--local bg = self:FindWndTrans(item,"bg")
	local select = self:FindWndTrans(item,"select")
	local intro = self:FindWndTrans(item,"intro")

	local index = itemdata.index
	local isSelect = index == self._select
	CS.ShowObject(select,isSelect)
	self:SetWndText(intro,itemdata.title)
	self:SetWndClick(item,function () self:OnClickChoose(index) end,LSoundConst.CLICK_BUTTON_COMMON)

	self._chooseUIList[index] = item
end

function UIEdenSelect:InitData()
	self._chooseUIList ={}

	self._needOperEvent=
	{
		[ModelWonderland.EVENT_POD] = true,
		[ModelWonderland.EVENT_CLIP] = true,
		[ModelWonderland.EVENT_BEAN_VINE] = true,
		[ModelWonderland.EVENT_OCTOPUS] = true,
		[ModelWonderland.EVENT_FOAM] = true,
		--[ModelWonderland.EVENT_POISON] = true,
		--[ModelWonderland.EVENT_ARROW_TOWER] = true,
	}
end


function UIEdenSelect:OnClickChoose(index)
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

	if self._wndType == 3 then
		self:OnSelect(index)
	end
end
function UIEdenSelect:SetStaticContent()
	local str =ccClientText(19626) --"确定"
	self:SetWndButtonText(self.mOk,str)
	local str =ccClientText(16764) --"点击选择"
	self:SetWndText(self.mTitle,str)
	self:SetWndText(self.mCloseTip,ccClientText(10103))
end

function UIEdenSelect:GoldHairConfirm()
	local canSelect = self._data.canSelect
	if not canSelect then
		local str =ccClientText(16779)-- "您还没有靠近%s"
		str = string.replace(str,self._name)
		GF.ShowMessage(str)
		return
	end

	local select = self._select
	if select == 2 then
		self:WndClose()
	elseif select== 0 then
		local str =ccClientText(16729)-- "请先选择其中一项")
		GF.ShowMessage(str)
	elseif select == 1 then

		local state = self._data.state
		local gridIndex = self._data.gridIndex
		if state == StructWonderlandGrid.ALLOW then
			gModelWonderland:WonderlandOpsReq(ModelWonderland.EVENT_SELECT_GRID,tostring(gridIndex))
		end

		gModelWonderland:WonderlandOpsReq(self._eventType)
		self:WndClose()
	end
end

function UIEdenSelect:RefreshUI()
	local canSelect = self._data.canSelect
	self:SetWndImageGray(self.mOk,not canSelect)

	local selectData = {
		itemdatas = self._selectList,
		select = 0,
	}
	self:ShowSelectContent(selectData)

	local showConfirm = self._wndType ~=3
	CS.ShowObject(self.mOk,showConfirm)

	local post = self._textData.desc
	self:SetWndText(self.mPost,post)


	local spineKey = self._eventCfg.prefab
	if string.isempty(spineKey) then
		return
	end
	self:CreateWndSpine(self.mRole,spineKey,spineKey,false,function (spine)
		spine:SetScale(2)
		spine:PlayAnimation(0,"idle",true)
	end)

	self:SetWndText(self.mMainTitle,self._name)
end

function UIEdenSelect:OnSelect(index)
	if index == 1 then
		local state = self._data.state
		local gridIndex = self._data.gridIndex
		if state == StructWonderlandGrid.ALLOW then
			gModelWonderland:WonderlandOpsReq(ModelWonderland.EVENT_SELECT_GRID,tostring(gridIndex))
		end
		self:WndClose()
	elseif index == 2 then
		self:WndClose()
	end
end




------------------------------------------------------------------
return UIEdenSelect


