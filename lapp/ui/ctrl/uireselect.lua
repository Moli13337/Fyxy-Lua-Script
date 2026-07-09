---
--- Created by Administrator.
--- DateTime: 2023/10/5 21:02:39
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIReSelect:LWnd
local UIReSelect = LxWndClass("UIReSelect", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIReSelect:UIReSelect()
	---@type table<number,CommonIcon>
	self._runeUIIconList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIReSelect:OnWndClose()
	self:ClearCommonIconList(self._runeUIIconList)
	self:CallBackFunc()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIReSelect:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIReSelect:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	local data = {refId = 5102,IntroTran = self.mEmptyText,TextBgTran = self.mEmptyTextBg,IconTran = self.mEmptyIcon}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)

	self:SetWndText(self.mTitle,ccClientText(13210))
	self:SetWndText(self.mDesc,ccClientText(13261))

	self:InitData()
	self:RefreshSelectNum()
	self:InitEvent()
	self:InitScrollView()
end

function UIReSelect:InitData()
	self._maxNum = self:GetWndArg("MaxNum")
	self._func = self:GetWndArg("func")
	local selectList = self:GetWndArg("selectList")
	self._selectList = {}
	local selectRefId
	for k,v in pairs(selectList) do
		local id = v.id
		local refId = v.refId
		if not selectRefId then
			selectRefId = refId
		end
		self._selectList[id] = refId
	end
	self._selectRefId = selectRefId
end

function UIReSelect:OnDrawRuneCell(list, item, itemdata, itempos, fromHeadTail)
	local runeIconTrans = CS.FindTrans(item,"RuneIcon")
	local GouTrans = CS.FindTrans(item,"GouTrans")
	if runeIconTrans then
		self:SetIconInfo(itemdata,runeIconTrans, item:GetInstanceID(), GouTrans)
	end
	local id = itemdata.id
	if GouTrans then
		local showGou = self._selectList[id] ~= nil
		CS.ShowObject(GouTrans,showGou)
	end
end

function UIReSelect:InitEvent()
	self:SetWndClick(self.mBg,function() self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end)
end

function UIReSelect:CallBackFunc()
	if self._func then
		local list = {}
		for k,v in pairs(self._selectList) do
			local data = {id = k,refId = v}
			table.insert(list,data)
		end
		self._func(list)
	end
end

function UIReSelect:SelectRune(itemdata,GouTrans)
	local selectId = itemdata.id
	local selectRefId = itemdata.refId
	local isAdd = self._selectList[selectId] == nil
	local curNUM = table.keysize(self._selectList)
	local optNum = -1
	if isAdd then optNum = 1 end
	if curNUM + optNum > self._maxNum then
		GF.ShowMessage(ccClientText(13242))
		return
	end
	if self._selectRefId then
		if self._selectRefId ~= selectRefId then
			GF.ShowMessage(ccClientText(13241))
			return
		end
	end
	if curNUM + optNum > self._maxNum then
		GF.ShowMessage(ccClientText(13242))
		return
	end
	if not self._selectRefId then self._selectRefId = selectRefId end
	CS.ShowObject(GouTrans,isAdd)
	if isAdd then
		self._selectList[selectId] = selectRefId
	else
		if curNUM + optNum == 0 then self._selectRefId = nil end
		self._selectList[selectId] = nil
	end
	self:RefreshSelectNum()
end

function UIReSelect:SetIconInfo(itemdata,trans, instanceId, GouTrans)
	local refId = itemdata.refId
	local runeData = {
		refId = refId,
		skillId = itemdata.skillId,
		attrId = itemdata.attrId,
	}

	local baseClass = self._runeUIIconList[instanceId]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._runeUIIconList[instanceId] = baseClass
		baseClass:Create(trans)
		self:SetIconClickScale(trans, true)
	end
	baseClass:SetRuneData(itemdata)
	baseClass:DoApply()

	self:SetWndClick(trans, function()
		self:SelectRune(itemdata,GouTrans)
	end)

	self:SetWndLongClick(trans,function()
		self:SelectRune(itemdata,GouTrans)
		local data = {
			runeData = itemdata
		}
		gModelGeneral:OpenRuneInfoTip(data)
		--GF.OpenWnd("UIReInfoTip",{runeData = data})
	end, 0.5, true)

	if GouTrans then
		self:SetWndClick(GouTrans,function()
			self:SelectRune(itemdata,GouTrans)
		end)

		self:SetWndLongClick(GouTrans,function()
			self:SelectRune(itemdata,GouTrans)
			local data = {
				runeData = itemdata
			}
			gModelGeneral:OpenRuneInfoTip(data)
			--GF.OpenWnd("UIReInfoTip",{runeData = data})
		end, 0.5, true)
	end
end

function UIReSelect:InitScrollView()
	local uiList = self._uiList
	if not uiList then
		uiList = UIListWrap:New()
		uiList:Create(self,self.mRuneList)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrawRuneCell(...)
		end)
		self._uiList = uiList
	end
	uiList:RemoveAll()
	local runeList = gModelRune:GetCompoundRuneList()
	if not table.isempty(runeList) then
		table.sort(runeList,function(rune1,rune2)
			local ref1,ref2 = gModelRune:GetRuneInfoByRefId(rune1.refId),gModelRune:GetRuneInfoByRefId(rune2.refId)
			local qua1,qua2 = ref1.quality,ref2.quality
			if qua1 ~= qua2 then
				return qua1 < qua2
			else
				return rune1.score < rune2.score
			end
		end)
		for i,v in ipairs(runeList) do
			uiList:AddData(i,v)
		end
	end
	local isempty = table.isempty(runeList)
	CS.ShowObject(self.mNoRecord,isempty)
	uiList:RefreshList()
end

function UIReSelect:RefreshSelectNum()
	local selectNum = table.keysize(self._selectList)
	local str = string.replace(ccClientText(13211),selectNum,self._maxNum)
	self:SetWndText(self.mSelectTxt,str)
end
------------------------------------------------------------------
return UIReSelect


