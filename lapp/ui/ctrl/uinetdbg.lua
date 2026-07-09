---
--- Created by luofuwen.
--- DateTime: 2023/10/15 10:50:46
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UINetDbg:LWnd
local UINetDbg = LxWndClass("UINetDbg", LWnd)

------------------------------------------------------------------
local InputFieldContentType = CardEHT.YXTMP_InputField.ContentType
local IntegerNumberContentType = InputFieldContentType.IntegerNumber
local DecimalNumberContentType = InputFieldContentType.DecimalNumber
local StandardContentType = InputFieldContentType.Standard

local descriptor = require "protobuf.descriptor"
local FieldDescriptor = descriptor.FieldDescriptor

---填充消息函数
local SetTableToPbFunc

SetTableToPbFunc = function(pbMsg, valueTable, fields)
	if (pbMsg) then
		for index, field in ipairs(fields) do
			local setValue  = valueTable[field.name]
			if setValue ~= nil then
				if field.label == FieldDescriptor.LABEL_REPEATED then
					local pbMsgField = pbMsg[field.name]
					if field.type == FieldDescriptor.TYPE_MESSAGE then
						local messageTypeFields = field.message_type.fields
						for i, v in ipairs(setValue) do
							SetTableToPbFunc(pbMsgField:add(), v, messageTypeFields)
						end
					else
						for i, v in ipairs(setValue) do
							table.insert(pbMsgField, v)
						end
					end
				else
					if field.type == FieldDescriptor.TYPE_MESSAGE then
						SetTableToPbFunc(pbMsg[field.name], setValue, field.message_type.fields)
					else
						pbMsg[field.name] = setValue
					end

				end
			end
		end
	end
end

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UINetDbg:UINetDbg()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UINetDbg:OnWndClose()
	LWnd.OnWndClose(self)
	
	gModelNetDebug:SetNetDebug(false)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UINetDbg:OnCreate()
	LWnd.OnCreate(self)
	gModelNetDebug:SetNetDebug(CS.IsOsWinOrEdit())
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UINetDbg:OnStart()
	LWnd.OnStart(self)
	if not gModelGM:IsGMOpen() then
		self:WndClose()
		return
	end
	self:InitUI()
	self:InitEvent()
	self:InitData()
	self:InitView()

end

function UINetDbg:UpdateMsgListViewShow()

	local msgDataList
	if self._msgListViewMode == 1 then
		msgDataList = gModelNetDebug:GetRecordSendMsgList() or {}
	else
		msgDataList = gModelNetDebug:GetSaveMsgList() or {}
	end

	self._curMsgDataList = msgDataList

	local msgList = self._uiSendMsgItemList
	if not msgList then
		msgList = self:GetUIScroll("_uiSendMsgItemList")
		msgList:Create(self.mSendMsgList,msgDataList,function (...)
			self:OnDrawSendMsgItem(...)
		end,UIItemList.SUPER_GRID,true)

		self._uiSendMsgItemList = msgList
	else
		msgList:RefreshList(msgDataList)
		msgList:DrawAllItems(false)
	end
end

function UINetDbg:UpdateMsgListTabUIState()
	if self._msgListViewMode == 1 then
		self:SetWndTabStatus(self.mBtnTabSend,LWnd.StateOn)
		self:SetWndTabStatus(self.mBtnTabSave,LWnd.StateOff)
	else
		self:SetWndTabStatus(self.mBtnTabSend,LWnd.StateOff)
		self:SetWndTabStatus(self.mBtnTabSave,LWnd.StateOn)
	end
end

function UINetDbg:UpdateDragShowNum()
	local msgList = gModelNetDebug:GetRecordSendMsgList() or {}
	local cnt = #msgList
	if cnt > 99 then
		cnt = "99+"
	end
	self:SetWndText(self.mDrawShowNum, cnt)
end

function UINetDbg:OnBtnDrag()
	self._isViewShow = true
	self:OnMaxMinChange()
	self:RefreshView()
end

function UINetDbg:OnBtnRecord()
	local isRecord = gModelNetDebug:IsNetOpenRecord()
	gModelNetDebug:OpenNetRecord(not isRecord)
	self:UpdateBreakPointAndRecordBtn()
end

function UINetDbg:OnMaxMinChange()
	self.mBtnDrag.localPosition = self._dragBtnOrgPos
	CS.ShowObject(self.mMasImage, self._isViewShow)
	CS.ShowObject(self.mAniRoot, self._isViewShow)
	CS.ShowObject(self.mDragNode,  not self._isViewShow)
end

function UINetDbg:OnEditObjOk()
	local input = self.mEditObjInput.text
	local obj = JSON.decode(input) or {}
	self._curEditObject.value = obj
	self._curEditMsgStreamObj[self._curEditObjectName] = obj

	self:OnEditObjClose()
end

function UINetDbg:OnBtnMin()
	self._isViewShow = false
	self:OnMaxMinChange()
	self:RefreshView()
end

function UINetDbg:OnBtnBreakPoint()
	local bOpenBreakpoint = gModelNetDebug:IsNetBreakpoint()
	bOpenBreakpoint = not bOpenBreakpoint
	gModelNetDebug:OpenNetBreakpoint(bOpenBreakpoint)
	self:UpdateBreakPointAndRecordBtn()
end

function UINetDbg:OnEditObjClose()
	CS.ShowObject(self.mEditorObjView, false)
	self._curEditObject = nil
	self._curEditObjectName = nil
end
------------------------------------------------------------------
function UINetDbg:UIDragOnDrag(dragKey,eventData)
	if dragKey == self._DebugDragKey then
		local trans = self.mBtnDrag

		local camera = eventData.pressEventCamera
		local pos = camera:ScreenToWorldPoint(eventData.position)
		pos = trans.parent:InverseTransformPoint(pos)

		local localPos = trans.localPosition

		local x = Mathf.Clamp(pos.x,-self._maxX,self._maxX)
		local y = Mathf.Clamp(pos.y,-self._maxY,self._maxY)

		trans.localPosition = Vector3.New(x,y,localPos.z)
	end

end

function UINetDbg:UpdateBreakPointAndRecordBtn()
	CS.ShowObject(self.mBreakPointCheckSel, gModelNetDebug:IsNetBreakpoint())
	CS.ShowObject(self.mRecordCheckSel, gModelNetDebug:IsNetOpenRecord())
end

function UINetDbg:OnBtnEditSend()
	local curMsgItem = self._curEditMsgItem
	curMsgItem.msgMode = 2
	curMsgItem.streamTable = self._curEditMsgStreamObj

	local sendCount = tonumber(self.mOnceSendCountInput.text) or 1

	local pbStream = LProtoHelper.CreateProto(curMsgItem.msgId)
	curMsgItem.pbStream = pbStream
	local _descriptor = getmetatable(pbStream)._descriptor
	for k = 1 , sendCount do
		--填充修改后的值
		SetTableToPbFunc(pbStream, self._curEditMsgStreamObj, _descriptor.fields)
		--发送
		gModelNetDebug:SendDebugMessageItem(curMsgItem, true)
	end
end

function UINetDbg:InitEvent()
	self:SetWndClick(self.mBtnClose, function() self:WndClose() end)
	self:SetWndClick(self.mBtnMin, function() self:OnBtnMin() end)
	self:SetWndClick(self.mMasImage, function() self:OnBtnMin()  end)

	self:SetWndClick(self.mBtnBreakPoint, function() self:OnBtnBreakPoint() end)
	self:SetWndClick(self.mBtnRecord, function() self:OnBtnRecord() end)

	self:SetWndClick(self.mBtnDrag, function() self:OnBtnDrag() end)

	--协议编辑
	self:SetWndClick(self.mBtnEditorClose, function() self:OnEditorClose()  end)
	self:SetWndClick(self.mBtnEditObjClose, function() self:OnEditObjClose()  end)
	self:SetWndClick(self.mBtnEditSend, function() self:OnBtnEditSend()  end)
	self:SetWndClick(self.mBtnEditSave, function() self:OnBtnEditSave()  end)
	self:SetWndClick(self.mBtnEditObjOk, function() self:OnEditObjOk() end)

	self:SetWndClick(self.mBtnTabSend, function()
		self._msgListViewMode = 1
		self:UpdateMsgListTabUIState()
		self:UpdateMsgListViewShow()
	end)

	self:SetWndClick(self.mBtnTabSave, function()
		self._msgListViewMode = 2
		self:UpdateMsgListTabUIState()
		self:UpdateMsgListViewShow()
	end)

	self._DebugDragKey = "netDebugDrag"
	self:UIDragSetItem(self._DebugDragKey,"DragNode/BtnDrag",CS.YXUIDrag.DragMode.DragNothing)

	self:WndEventRecv("net_debug_add_message", function()
		self:RefreshView()
	end)
end
------------------------------------------------------------------

---region 协议编辑
function UINetDbg:ShowEditorView(msgItem)
	CS.ShowObject(self.mEditorView, true)

	self._curEditMsgItem = msgItem
	--- self._curEditMsgStreamObj 用来存储修改后的pb数据
	if not msgItem.streamTable then
		msgItem.streamTable = LProtoHelper.ProtoToPureTable(msgItem.pbStream)
	end
	self._curEditMsgStreamObj = table.clone(msgItem.streamTable)

	self:RefreshMsgFieldList()
end

function UINetDbg:OnDrawMsgFieldItem(list, item, itemdata, itempos, fromHeadTail)
	local NameText = self:FindWndTrans(item , "NameText")
	local ValueInputTextTrans = self:FindWndTrans(item, "ValueInputText")
	local valueInputText = self:FindTextInput(ValueInputTextTrans)
	local btnEditTrans = self:FindWndTrans(item, "BtnEdit")

	local data = itemdata.value
	local dataType = itemdata.dataType
	local name = itemdata.key
	local isShowBtn = false
	if dataType == 1 then
		name = string.format("%s (数字)", name)
	elseif dataType == 2 then
		name = string.format("%s (结构)", name)
		isShowBtn = true
	elseif dataType == 3 then
		name = string.format("%s (true or false)", name)
		--isShowBtn = true
	else
		name = string.format("%s (字符串)", name)
	end
	self:SetWndText(NameText, name)
	if isShowBtn then
		CS.ShowObject(btnEditTrans, true)
		CS.ShowObject(valueInputText, false)
		self:SetWndClick(btnEditTrans, function()
			self:ShowEditObjView(itemdata)
		end)
	else
		CS.ShowObject(btnEditTrans, false)
		CS.ShowObject(valueInputText, true)
		if dataType == 3 then
			valueInputText.text = tostring(data)
		else
			valueInputText.text = data
		end
		if dataType == 1 then
			valueInputText.contentType = DecimalNumberContentType
		else
			valueInputText.contentType = StandardContentType
		end
		self:SetWndInputDelegate(ValueInputTextTrans, function(value)
			if dataType == 1 then
				itemdata.value = tonumber(value)
			elseif dataType == 3 then
				itemdata.value = checkbool(value)
			else
				itemdata.value = value
			end
			self._curEditMsgStreamObj[itemdata.key] = itemdata.value
		end)
	end

end

function UINetDbg:OnBtnEditSave()
	gModelNetDebug:AddSaveMsg(self._curEditMsgItem)
end

function UINetDbg:ShowEditObjView(itemData)
	CS.ShowObject(self.mEditorObjView, true)
	self:SetWndText(self.mEditObjName, itemData.key)
	self._curEditObject = itemData
	self._curEditObjectName = itemData.key
	local decodeData = JSON.encode(itemData.value)
	self.mEditObjInput.text = decodeData
end

function UINetDbg:InitView()
	CS.ShowObject(self.mDragNode, false)
	CS.ShowObject(self.mEditorView, false)
	CS.ShowObject(self.mEditorObjView, false)

	self.mOnceSendCountInput.text = 1

	self:UpdateBreakPointAndRecordBtn()

	self:SetWndTabText(self.mBtnTabSave, "保存列表")
	self:SetWndTabText(self.BtnTabSend, "发送列表")
	self:SetWndButtonText(self.mBtnEditObjOk, "确定修改")
	self:SetWndButtonText(self.mBtnEditSend, "发送")
	self:SetWndButtonText(self.mBtnEditSave, "保存")

	self._msgListViewMode = 1
	self:UpdateMsgListTabUIState()
	self:UpdateMsgListViewShow()
end

function UINetDbg:InitData()
	self._pageIndex = 1
	self._isDebug = CS.IsOsWinOrEdit()
	self._isViewShow = true

	self._dragBtnOrgPos = self.mBtnDrag.localPosition
	local width,height =  self.mDragNode.rect.width/2,self.mDragNode.rect.height/2
	local bWidth,bHeight = self.mBtnDrag.sizeDelta.x/2, self.mBtnDrag.sizeDelta.y/2
	self._maxX = (width or 270) - bWidth
	self._maxY = (height or 530) - bHeight
end

function UINetDbg:RefreshView()
	if self._isViewShow then
		self:UpdateMsgListViewShow()
	else
		self:UpdateDragShowNum()
	end
end

function UINetDbg:OnEditorClose()
	CS.ShowObject(self.mEditorView, false)
	CS.ShowObject(self.mEditorObjView, false)
	self._curEditMsgItem = nil
	self._curEditMsgStreamObj = nil
end

function UINetDbg:OnDrawSendMsgItem(list, item, itemdata, itempos, fromHeadTail)
	local ImageBreak = self:FindWndTrans(item, "ImageBreak")
	local IdText = self:FindWndTrans(item, "IdNode/IdText")
	local NameText = self:FindWndTrans(item, "NameText")
	local TimeText = self:FindWndTrans(item, "TimeText")
	local BtnOp = self:FindWndTrans(item, "BtnOp")

	if self._msgListViewMode == 1 then
		if gModelNetDebug:IsSaveMsg(itemdata) then
			CS.ShowObject(BtnOp, false)
		else
			CS.ShowObject(BtnOp, true)
			self:SetWndButtonText(BtnOp, "保存")
			self:SetWndClick(BtnOp, function()
				gModelNetDebug:AddSaveMsg(itemdata)
				CS.ShowObject(BtnOp, false)
			end)
		end
		CS.ShowObject(ImageBreak, gModelNetDebug:IsBreakSendMsg(itemdata))
	else
		CS.ShowObject(BtnOp, true)
		self:SetWndButtonText(BtnOp, "删除")
		self:SetWndClick(BtnOp, function()
			gModelNetDebug:RemoveSaveMsg(itemdata)
			self:UpdateMsgListViewShow()
		end)

		CS.ShowObject(ImageBreak, false)
	end

	self:SetWndClick(item, function()
		self:ShowEditorView(itemdata)
	end)

	self:SetWndText(IdText, ""..itemdata.recordId)
	self:SetWndText(NameText, string.format("%s (%s)", itemdata.msgName, itemdata.msgId))
	self:SetWndText(TimeText, LUtil.FormatTimeStr(itemdata.time * 1000, "%H:%M:%S"))
end

function UINetDbg:RefreshMsgFieldList()
	local listData = {}
	for k,v in pairs(self._curEditMsgStreamObj) do
		local dataType = 0
		local typeStr = type(v)
		if typeStr == "table" then
			dataType = 2
		elseif typeStr == "number" then
			dataType = 1
		elseif typeStr == "boolean" then
			dataType = 3
		end
		table.insert(listData,{key=k, value = v, dataType = dataType})
	end

	local msgFieldList  = self._uiMsgFieldList
	if not msgFieldList then
		msgFieldList = self:GetUIScroll("_uiMsgFieldList")
		msgFieldList:Create(self.mMsgFieldList, listData ,function (...)
			self:OnDrawMsgFieldItem(...)
		end,UIItemList.SUPER_GRID,true)

		self._uiMsgFieldList = msgFieldList
	else
		msgFieldList:RefreshList(listData)
		msgFieldList:DrawAllItems(false)
	end
end


---endregion 协议编辑
------------------------------------------------------------------
return UINetDbg


