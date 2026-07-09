---
--- Created by Administrator.
--- DateTime: 2023/10/27 17:51:19
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIReeOpt:LWnd
local UIReeOpt = LxWndClass("UIReeOpt", LWnd)

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIReeOpt:UIReeOpt()
	---@type CommonIcon
	self._iconHeroCurCls = nil
	---@type CommonIcon
	self._iconHeroLastCls = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIReeOpt:OnWndClose()
	if self._iconHeroCurCls then
		self._iconHeroCurCls:Destroy()
		self._iconHeroCurCls = nil
	end
	if self._iconHeroLastCls then
		self._iconHeroLastCls:Destroy()
		self._iconHeroLastCls = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIReeOpt:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIReeOpt:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitMsg()

    CS.ShowObject(self.mCloseTip1,self._view == 1)
    CS.ShowObject(self.mCloseTip2,self._view == 2)
    CS.ShowObject(self.mView1,self._view == 1)
    CS.ShowObject(self.mView2,self._view == 2)
	if self._view == 1 then
		self:RefreshView1()
	else
        self:RefreshView2()
	end
end

function UIReeOpt:SendMsg()
	if self._click then return end
	self._click = true
	if self._func then self._func(self._selectType) end
end

function UIReeOpt:InitMsg()
	self:WndNetMsgRecv(LProtoIds.ResonancePosUnlockResp, function() self:WndClose() end)
	self:WndNetMsgRecv(LProtoIds.ResonancePosCoolTimeResp, function() self:WndClose() end)
	self:WndNetMsgRecv(LProtoIds.ResonanceHeroResp, function() self:WndClose() end)
    self:WndEventRecv(EventNames.NET_ERROR_CODE,function(code,error, argList)
		self._click = false
		local refId = self._needRefIdList[self._selectType]
		gModelGeneral:OpenGetWayWnd({itemId = refId})
	end)
end

function UIReeOpt:OnDrawBtnCell(list,item,itemdata,itempos)
	local SelBtnDiv = self:FindWndTrans(item,"SelBtnDiv")
	local SelBtn = self:FindWndTrans(SelBtnDiv,"SelBtn")
	local Gou = self:FindWndTrans(SelBtn,"Gou")
	local ShowItem = self:FindWndTrans(item,"ShowItem")
	local ItemIcon = self:FindWndTrans(ShowItem,"ItemIcon")
	local NumDiv = self:FindWndTrans(ShowItem,"NumDiv")
	local ItemNum = self:FindWndTrans(NumDiv,"ItemNum")

	local index = itemdata.index
	CS.ShowObject(Gou,self._selectType == index)

	local itemType,itemId,itemNum = itemdata.itemType,itemdata.itemId,itemdata.itemNum

	local icon = gModelItem:GetItemIconByRefId(itemId)
	self:SetWndEasyImage(ItemIcon,icon)

	local haveNum = gModelItem:GetNumByRefId(itemId)
	local enough = haveNum >= itemNum
	local color = enough and "lightGreen" or "lightRed"
	haveNum = LUtil.NumberCoversion(haveNum)
	itemNum = LUtil.NumberCoversion(itemNum)

	haveNum = LUtil.FormatColorStr(haveNum,color)
	local numStr = string.format("%s/%s",haveNum,itemNum)
	self:SetWndText(ItemNum,numStr)

	self:SetWndClick(item,function()
		self:SelectType(index)
	end)
end

function UIReeOpt:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end)
    self:SetWndClick(self.mCancelBtn,function() self:WndClose() end)
    self:SetWndClick(self.mEnterBtn,function() self:SendMsg() end)
    ----------------------------------------------------------------------
    self:SetWndClick(self.mCancelBtn2,function() self:WndClose() end)
    self:SetWndClick(self.mEnterBtn2,function() self:SendMsg() end)
    self:SetWndClick(self.mCloseBtn2,function() self:WndClose() end)
end

function UIReeOpt:RefreshView2()
    self:SetWndText(self.mTitle2,ccClientText(14722))
	self:SetWndButtonText(self.mCancelBtn2, ccClientText(10101))
	self:SetWndButtonText(self.mEnterBtn2, ccClientText(10102))
    self:SetWndText(self.mCloseTip2,ccClientText(10103))

    self:SetWndText(self.mDescTxt2,ccClientText(14712))
    self:SetWndText(self.mHuanyuanTxt,ccClientText(14713))
    local resonanceTime = GameTable.LevelShareConfigRef["resonanceTime"]
	local subTime = gModelGrade:GetHeroResonanceEffectValue()
	resonanceTime = resonanceTime - subTime
	printInfoNR("==== 特权减少的时间 = " .. subTime .. ",剩余时间 = " .. resonanceTime)
    local hour = math.floor(resonanceTime/3600)
    hour = hour .. ccClientText(10305)
    local str = string.replace(ccClientText(14714),hour)
    self:SetWndText(self.mCoolTimeTxt,str)

    local baseClass = self._iconHeroCurCls
	if not baseClass then
		baseClass = CommonIcon:New()
		self._iconHeroCurCls = baseClass
		baseClass:Create(self.mHeroIconCur)
	end
	baseClass:SetHeroPlayer(self._heroId)
	baseClass:DoApply()


    local heroStruct = self._heroStruct
    if heroStruct then

        baseClass = self._iconHeroLastCls
		if not baseClass then
			baseClass = CommonIcon:New()
			self._iconHeroLastCls = baseClass
			baseClass:Create(self.mHeroIconLast)
		end

		local heroData = {
			id = self._heroId,
			refId = heroStruct:GetRefId(),
			star = heroStruct:GetStar(),
			level = heroStruct:GetRealLevel(),
			skin = heroStruct:GetSkin(),
			isResonance = 0
		}
		baseClass:SetHeroDataSet(heroData)
		baseClass:DoApply()
    end

end

function UIReeOpt:SelectType(index,refresh)
	if index == self._selectType and refresh == nil then return end
	self._selectType = index

	local uiBtnList = self._uiBtnList
	if uiBtnList then
		local uiList = uiBtnList:GetList()
		uiList:RefreshList()
	end
end

function UIReeOpt:InitData()
	self._view = self:GetWndArg("view") or 1 			-- 类型1：解锁和清除冻结时间，类型2：还原英雄
	self._type = self:GetWndArg("itype") 				-- 1：解锁，2：清除冻结时间
	self._data = self:GetWndArg("data") 					-- 类型1：所需消耗材料
	self._func = self:GetWndArg("func")					-- 回调函数
    self._heroId = self:GetWndArg("heroId")
    if self._heroId then
        self._heroStruct = gModelHero:GetHeroById(self._heroId)
    end
	self._needRefIdList = {}
	self._selectType = 1
	self._click = false
end

function UIReeOpt:RefreshView1()
    self:SetWndText(self.mTitle,ccClientText(14722))
	self:SetWndButtonText(self.mCancelBtn, ccClientText(10101))
	self:SetWndButtonText(self.mEnterBtn, ccClientText(10102))
    self:SetWndText(self.mCloseTip1,ccClientText(10103))

	local descId
	if self._type == 1 then
		descId = 14708
	else
		descId = 14709
	end
	self:SetWndText(self.mDescTxt,ccClientText(descId))

--[[	local data = self._data
	for i,v in ipairs(data) do
		v = string.split(v,"=")
		local refId,needNum = tonumber(v[2]),tonumber(v[3])
		self._needRefIdList[i] = refId
		local iconTrans,numTrans = itemIconList[i],itemNumList[i]
		local icon = gModelItem:GetItemIconByRefId(refId)
		self:SetWndEasyImage(iconTrans,icon)
		self:SetWndText(numTrans,needNum)
	end]]


	local data = self._data
	local list = {}
	for i,v in ipairs(data) do
		v = string.split(v,"=")
		local itemType,itemId,itemNum = tonumber(v[1]),tonumber(v[2]),tonumber(v[3])
		self._needRefIdList[i] = itemId
		table.insert(list,{
			itemType = itemType,
			itemId = itemId,
			itemNum = itemNum,
			index = i,
		})
	end
	local uiBtnList = self._uiBtnList
	if uiBtnList then
		uiBtnList:RefreshList(list)
	else
		uiBtnList = self:GetUIScroll("uiBtnList")
		self._uiBtnList = uiBtnList
		uiBtnList:Create(self.mBtnList,list,function(...) self:OnDrawBtnCell(...) end)
	end

	self:SelectType(1,true)
end
------------------------------------------------------------------
return UIReeOpt


