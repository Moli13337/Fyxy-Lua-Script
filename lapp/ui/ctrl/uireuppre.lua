---
--- Created by LCM.
--- DateTime: 2024/3/31 15:57:46
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIReUpPre:LWnd
local UIReUpPre = LxWndClass("UIReUpPre", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIReUpPre:UIReUpPre()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIReUpPre:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIReUpPre:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIReUpPre:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()
end

function UIReUpPre:CreateCommonItem(trans,itemdata)
	local InstanceID = trans:GetInstanceID()
	local baseClass = self:GetCommonIcon(InstanceID)
	local iconTrans = self:FindWndTrans(trans,"CommonUI/Icon")
	baseClass:Create(iconTrans)
	self:SetIconClickScale(iconTrans, true)
	local itype,refId,count = itemdata.itemType,itemdata.itemId,itemdata.itemNum
	baseClass:SetCommonReward(itype,refId,count)
	baseClass:EnableShowNum(false)
	baseClass:DoApply()
end

function UIReUpPre:RefreshView()
	self:RefreshRuneIcon()
	self:ShowUpDiv()
	self:CreateDesc()
	self:CreateQuenchingPayItemList()
end

function UIReUpPre:RefreshRuneIcon()
	self:CreateRuneIcon(self.mBeforeRune,self._preRune)
	self:CreateRuneIcon(self.mLaterRune,self._newRune)
end

function UIReUpPre:InitData()
	local runeData = self:GetWndArg("runeData")
	local preRune = table.clone(runeData)
	local newRune = table.clone(runeData)
	local preClassRefId = preRune.clazzRefId
	local classRef = gModelRune:GetInitRuneQuenchingClassRefByRefId(preClassRefId)
	if classRef then
		newRune.clazzRefId = classRef.nextClass
		newRune.refId = classRef.upQuality
	end
	self._preRune = preRune
	self._newRune = newRune

	local selRuneIdList = self:GetWndArg("selRuneIdList")
	self._selRuneIdList = selRuneIdList or {}

	local selUseRuneItemList = self:GetWndArg("selUseRuneItemList")
	self._selUseRuneItemList = selUseRuneItemList or {}

	self._exitWndFunc = self:GetWndArg("exitWndFunc")
end

function UIReUpPre:OnDrawQuenchingAttrCell(list,item,itemdata,itempos)
	local AttrIconTrans = self:FindWndTrans(item,"AttrIcon")
	local AttrNameTrans = self:FindWndTrans(item,"AttrName")
	local AttrBeforeNumTrans = self:FindWndTrans(item,"AttrBeforeNum")
	local AttrLaterNumTrans = self:FindWndTrans(item,"AttrLaterNum")
	local attrRefId,attrType,beforeAttrVal,laterAttrVal = itemdata.attrRefId,itemdata.attrType,itemdata.beforeAttrVal,itemdata.laterAttrVal
	local attrIcon = gModelHero:GetAttributeIconById(attrRefId)
	self:SetWndEasyImage(AttrIconTrans,attrIcon)
	local attrName = gModelHero:GetAttributeNameById(attrRefId)
	self:SetWndText(AttrNameTrans,attrName)
	local value = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId,attrType,beforeAttrVal)
	self:SetWndText(AttrBeforeNumTrans,value)
	local nextValue = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId,attrType,laterAttrVal)
	self:SetWndText(AttrLaterNumTrans,nextValue)
end

function UIReUpPre:ExitWnd()
	local exitWndFunc = self._exitWndFunc
	self._exitWndFunc = nil
	if exitWndFunc then
		exitWndFunc(self._selRuneIdList,self._selUseRuneItemList)
	end
	self:WndClose()
end

function UIReUpPre:OnClickEnterBtnFunc()
	local preRune = self._preRune
	if not preRune then return end
	local selRuneIdList = self._selRuneIdList
	if not selRuneIdList then
		selRuneIdList = {}
		self._selRuneIdList = selRuneIdList
	end
	local selUseRuneItemList = self._selUseRuneItemList
	if not selUseRuneItemList then
		selUseRuneItemList = {}
		self._selUseRuneItemList = selUseRuneItemList
	end
	local selRuneIdNum = #selRuneIdList + #selUseRuneItemList
	local isSelRuneEnough = true
	local noEnoughItem = nil
	local list = gModelRune:GetQuenchingPayList(preRune)
	for i,v in ipairs(list) do
		local itemType = v.itemType
		if itemType == LItemTypeConst.TYPE_RUNE then
			isSelRuneEnough = selRuneIdNum >= v.itemNum
		else
			local itemId = v.itemId
			local haveNum = gModelItem:GetNumByRefId(itemId)
			if haveNum < v.itemNum then
				noEnoughItem = itemId
				break
			end
		end
	end
	if not isSelRuneEnough then
		-- 选择的符文不够
		GF.ShowMessage(ccClientText(24927))
		return
	end
	if noEnoughItem then
		gModelGeneral:OpenGetWayWnd({itemId = noEnoughItem,srcWnd = self:GetWndName()})
		return
	end
	self:GetWearRuneIdList()
	self:CheckWearRuneIdList()
end

function UIReUpPre:CreateClassDiv(data)
	self:SetWndText(self.mClassName,ccClientText(24833))
	if not data then return end
	local curStarNum = data.curStarNum
	local nextStarNum = data.nextStarNum
	self:CreateStarList(self.mBeforeStarList,curStarNum,self.mBNoClassTxt)
	self:CreateStarList(self.mLaterStarList,nextStarNum,self.mLNoClassTxt)
end

function UIReUpPre:SendRuneQuenchingClazzReq()
	local preRune = self._preRune
	if not preRune then return end
	local selRuneIdList = self._selRuneIdList
	if not selRuneIdList then
		selRuneIdList = {}
		self._selRuneIdList = selRuneIdList
	end
	local selUseRuneItemList = self._selUseRuneItemList
	if not selUseRuneItemList then
		selUseRuneItemList = {}
		self._selUseRuneItemList = selUseRuneItemList
	end
	local refId
	local itemKeyList = {}
	for k,v in pairs(selUseRuneItemList) do
		refId = v.refId
		local itemSelNum = itemKeyList[refId] or 0
		itemKeyList[refId] = itemSelNum + 1
	end
	local itemList = {}
	for itemId,num in pairs(itemKeyList) do
		table.insert(itemList,{
			refId = itemId,
			num = num,
		})
	end
	local runeId = preRune.id
	gModelRune:OnRuneQuenchingClazzReq(runeId,selRuneIdList,itemList)
end

function UIReUpPre:OpenRuneTip(serverData)
	local data = {
		runeData = serverData
	}
	gModelGeneral:OpenRuneInfoTip(data)
end

function UIReUpPre:OnDrawStarCell(list,item,itemdata,itempos)
	local star = self:FindWndTrans(item,"Star")
	CS.ShowObject(star,itemdata.show)
end

function UIReUpPre:CreateDesc()
	local preRune = self._preRune
	if not preRune then return end
	local clazzRefId = preRune.clazzRefId
	local classRef = gModelRune:GetInitRuneQuenchingClassRefByRefId(clazzRefId)
	if classRef then
		local desc = ccLngText(classRef.desc)
		self:SetWndText(self.mDescTxt,desc)
	end
end

function UIReUpPre:GetQuenchingPayItemList()
	local serverData = self._preRune
	--local list = {}
	local list = gModelRune:GetQuenchingPayList(serverData)
	return list
end

function UIReUpPre:CreateRuneIcon(trans,runeData)
	if not runeData then return end
	local InstanceID = trans:GetInstanceID()
	local baseClass = self:GetCommonIcon(InstanceID)
	local iconTrans = self:FindWndTrans(trans,"Icon")
	baseClass:Create(iconTrans)
	self:SetIconClickScale(iconTrans, true)
	baseClass:SetRuneData(runeData)
	baseClass:DoApply()

--[[	self:SetWndClick(iconTrans,function()
		self:OpenRuneTip(runeData)
	end)]]
end

function UIReUpPre:CreateLevelDiv(data)
	self:SetWndText(self.mLvName,ccClientText(24853))
	if not data then return end
	self:SetWndText(self.mLvBeforeNum,data.curLevelNum)
	self:SetWndText(self.mLvLaterNum,data.nextLevelNum)
end

function UIReUpPre:CreateAttrDiv()
	local preRune,newRune = self._preRune,self._newRune
	-- local list = gModelRune:GetUpClassAllAttrList(preRune,newRune)
	local list = gModelRune:GetRuneUpAttrList(self._preRune.attrId, false)
	self:InitQuenchingList(list)
end

function UIReUpPre:GetWearRuneIdList()
	local selRuneIdList = self._selRuneIdList
	if not selRuneIdList then
		selRuneIdList = {}
		self._selRuneIdList = selRuneIdList
	end
	local wearRuneIdList = {}
	for i,v in ipairs(selRuneIdList) do
		local serverData = gModelRune:GetServerDataById(v)
		if serverData then
			local heroId = serverData.heroId
			local isWear = heroId ~= "0"
			if isWear then
				table.insert(wearRuneIdList,{
					heroId = heroId,
					runeId = serverData.id,
				})
			end
		end
	end
	self._wearRuneIdList = wearRuneIdList
end

function UIReUpPre:GetClassAndLevelList()
	local list = {}
	local preRune,newRune = self._preRune,self._newRune
	if preRune and newRune then
		local starData,levelData = {},{}
		local preClazzRefId = preRune.clazzRefId
		local preClassRef = gModelRune:GetInitRuneQuenchingClassRefByRefId(preClazzRefId)
		--local curUpQuality = curClassRef and curClassRef.upQuality or preRune.refId
		local curUpQuality = preRune.refId
		local newUpQuality = preClassRef and preClassRef.upQuality or preRune.refId
		local curStar,nextStar = gModelRune:GetShowStarByRefId(curUpQuality),gModelRune:GetShowStarByRefId(newUpQuality)
		starData.curStarNum = curStar
		starData.nextStarNum = nextStar

		local curLevelRefId = preRune.levelRefId
		local nextLevelRefId = newRune.levelRefId
		local curLevelRef = gModelRune:GetRuneQuenchingRefByRefId(curLevelRefId)
		local nextLevelRef = gModelRune:GetRuneQuenchingRefByRefId(nextLevelRefId)
		local curLevelNum = curLevelRef and curLevelRef.level or 1
		local nextLevelNum = nextLevelRef and nextLevelRef.level or 1
		levelData.curLevelNum = curLevelNum
		levelData.nextLevelNum = nextLevelNum

		table.insert(list,starData)
		table.insert(list,levelData)
	end
	return list
end

function UIReUpPre:InitText()
	self:SetWndText(self.mLblBiaoti,ccClientText(24821))
	self:SetTextTile(self.mText1,ccClientText(24818))
	self:SetTextTile(self.mText2,ccClientText(24819))
	self:SetTextTile(self.mText3,ccClientText(24820))
	self:SetWndButtonText(self.mCancelBtn,ccClientText(10101))
	self:SetWndButtonText(self.mEnterBtn,ccClientText(10102))
end

function UIReUpPre:ShowUpDiv()
	self:CreateClassAndLevelDiv()
	self:CreateAttrDiv()
end

function UIReUpPre:OnDrawPayItemCell(list,item,itemdata,itempos)
	local ItemIconRoot = self:FindWndTrans(item,"ItemIconRoot")
	local CommonUI = self:FindWndTrans(ItemIconRoot,"CommonUI")
	local Icon = self:FindWndTrans(CommonUI,"Icon")
	local PayDiv = self:FindWndTrans(item,"GameObject/PayDiv")
	local ItemName = self:FindWndTrans(PayDiv,"ItemName")
	local ItemNum = self:FindWndTrans(PayDiv,"ItemNum")

	self:CreateCommonItem(ItemIconRoot,itemdata)
	CS.ShowObject(CommonUI,true)
	local itemType,itemId,itemNum = itemdata.itemType,itemdata.itemId,itemdata.itemNum

	local nameStr,numStr
	local haveNum
	if itemType == LItemTypeConst.TYPE_RUNE then
		nameStr = gModelRune:GetRuneNameByServerData(itemdata)
		local selRuneIdList = self._selRuneIdList
		if not selRuneIdList then
			selRuneIdList = {}
			self._selRuneIdList = selRuneIdList
		end
		local selUseRuneItemList = self._selUseRuneItemList
		if not selUseRuneItemList then
			selUseRuneItemList = {}
			self._selUseRuneItemList = selUseRuneItemList
		end
		haveNum = #selRuneIdList + #selUseRuneItemList
		self:SetWndClick(Icon,function()
--[[			local selRuneId = selRuneIdList[1]
			if selRuneId then
				local serverData = gModelRune:GetServerDataById(selRuneId)
				if serverData then
					self:OpenRuneTip(serverData)
				end
			end]]
			GF.OpenWnd("UIReSelMals",{
				openType = 1,
				needRuneRefId = itemId,
				needRuneNum = itemNum,
				selRuneList = self._selRuneIdList,
				selRuneItemList = self._selUseRuneItemList,
				selRuneData = self._preRune,
				openPage = self._page,
				callFunc = function(selList,selRuneItemList)
					if not self:IsWndValid() then return end
					self._selRuneIdList = {}
					for i,v in ipairs(selList) do
						table.insert(self._selRuneIdList,v)
					end
					self._selUseRuneItemList = {}
					for k,v in pairs(selRuneItemList) do
						table.insert(self._selUseRuneItemList,v)
					end
					self:CreateQuenchingPayItemList()
				end,
			})
		end)
	else
		nameStr = gModelItem:GetNameByRefId(itemId)
		haveNum = gModelItem:GetNumByRefId(itemId)
		self:SetWndClick(Icon,function()
			--gModelGeneral:ShowCommonItemTipWnd(itemdata)
			gModelGeneral:OpenGetWayWnd({itemId = itemId,srcWnd = self:GetWndName()})
		end)
	end
	local isEnough = haveNum >= itemNum
	local color = isEnough and "green" or "red"
	local haveNumStr = LUtil.FormatColorStr(LUtil.NumberCoversion(haveNum),color)
	local itemNumStr = LUtil.NumberCoversion(itemNum)
	numStr = string.format("%s/%s",haveNumStr,itemNumStr)

	self:SetWndText(ItemName,nameStr)
	self:SetWndText(ItemNum,numStr)
end

function UIReUpPre:CreateClassAndLevelDiv()
	local list = self:GetClassAndLevelList()
	self:CreateClassDiv(list[1])
	self:CreateLevelDiv(list[2])
end

function UIReUpPre:CreateStarList(trans,starNum,notTextTrans)
	local list = {}
	for i = 1,starNum do
		table.insert(list,{
			show = true,
		})
	end

	local isNotStar = starNum == 0
	if isNotStar then
		self:SetWndText(notTextTrans,ccClientText(24923))
	end

	local key = trans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(trans,list,function(...) self:OnDrawStarCell(...) end)
	end
end

function UIReUpPre:InitMsg()
	self:WndNetMsgRecv(LProtoIds.RuneQuenchingClazzResp,function() self:WndClose() end)
	self:WndNetMsgRecv(LProtoIds.RuneUnloadResp,function() self:CheckWearRuneIdList() end)
end

function UIReUpPre:CheckWearRuneIdList()
	local wearRuneIdList = self._wearRuneIdList
	if not wearRuneIdList then
		wearRuneIdList = {}
		self._wearRuneIdList = wearRuneIdList
	end
	local len = #wearRuneIdList
	if len < 1 then
		self:SendRuneQuenchingClazzReq()
	else
		local runeData = table.remove(wearRuneIdList)
		if runeData then
			local heroId = runeData.heroId
			gModelHero:SetNeedHeroPowerTips(true, heroId)
			gModelRune:OnRuneUnloadReq(heroId,runeData.runeId)
		end
	end
end

function UIReUpPre:InitQuenchingList(list)
	list = list or {}
	local uiQuenchingAttrList = self._uiQuenchingAttrList
	if uiQuenchingAttrList then
		uiQuenchingAttrList:RefreshList(list)
	else
		uiQuenchingAttrList = self:GetUIScroll("uiQuenchingAttrList")
		self._uiQuenchingAttrList = uiQuenchingAttrList
		uiQuenchingAttrList:Create(self.mQuenchAttrList,list,function(...) self:OnDrawQuenchingAttrCell(...) end)
	end
end

function UIReUpPre:InitEvent()
	self:SetWndClick(self.mMask,function() self:ExitWnd() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function() self:ExitWnd() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCancelBtn,function() self:ExitWnd() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mEnterBtn,function() self:OnClickEnterBtnFunc() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIReUpPre:CreateQuenchingPayItemList()
	local list = self:GetQuenchingPayItemList()
	local uiPayItemList = self._uiPayItemList
	if uiPayItemList then
		uiPayItemList:RefreshList(list)
	else
		uiPayItemList = self:GetUIScroll("uiPayItemList")
		self._uiPayItemList = uiPayItemList
		uiPayItemList:Create(self.mPayItemList,list,function(...) self:OnDrawPayItemCell(...) end)
	end
	local isEnable = #list > 2
	uiPayItemList:EnableScroll(isEnable,true)
end

------------------------------------------------------------------
return UIReUpPre