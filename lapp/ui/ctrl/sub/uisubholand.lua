---
--- Created by Administrator.
--- DateTime: 2024/3/28 19:59:11
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubHoLand:LChildWnd
local UISubHoLand = LxWndClass("UISubHoLand", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubHoLand:UISubHoLand()
	self.nextAttrMap = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubHoLand:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubHoLand:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubHoLand:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	self._isVie = gLGameLanguage:IsVieVersion()
	
	if self._isVie then
		self:SetAnchorPos(self.mImgHelp,Vector2.New(120,-75))
	end 
	
	self:AddEventMsg()
	self:UpdateAttrs()
	self:UpdateCost()
	self:OnUpdateNode()
end

function UISubHoLand:OnDrawAttrCell(list,item,itemdata,itempos)
	local AttrIcon = self:FindWndTrans(item,"AttrIcon")
	local AttrName = self:FindWndTrans(item,"AttrName")
	local AttrValue = self:FindWndTrans(item,"AttrValue")
	local numType,refId,value = itemdata.type,itemdata.refId,itemdata.value
	local target = itemdata.target
	local showTarget = target ~= nil or false
	if AttrIcon then
		local icon = gModelHero:GetAttributeIconById(refId)
		self:SetWndEasyImage(AttrIcon,icon)
	end

	if AttrName then
		local name = gModelHero:GetAttributeNameById(refId)
		self:SetWndText(AttrName,name)
	end
	self:SetWndText(AttrValue,"")
	local nexAttr = self.nextAttrMap[refId..numType]
	if AttrValue then--and self.nextAttrMap[refId..numType]
		local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,numType,value)
		local preStr = nexAttr and "+"..gModelHero:GetAttributeValueNoNameByIdAndVal(refId,numType,nexAttr.value)  or ""
		self:SetWndText(AttrValue,"<color=#D2730F>"..valueStr.."</color>"..preStr)
	end
end

function UISubHoLand:OnDrawCostItem(list,item, itemdata, itempos)
	local SellIconTrans = self:FindWndTrans(item,"SellIcon")
	if SellIconTrans then
		local iconImg = gModelItem:GetItemIconByRefId(itemdata.itemId)
		self:SetWndEasyImage(SellIconTrans,iconImg,function()
			CS.ShowObject(SellIconTrans,true)
		end)
	end
	local SellValueTrans = self:FindWndTrans(item,"SellValue")
	if SellValueTrans then
		local haveCount = gModelItem:GetNumByRefId(itemdata.itemId)
		local color = haveCount>=itemdata.itemNum and "#139057" or "#FB1E12"
		local str = string.format("<color=%s>%s</color>/%s",color, LUtil.NumberCoversion(haveCount),LUtil.NumberCoversion(itemdata.itemNum))
		self:SetWndText(SellValueTrans,str)
	end
end

function UISubHoLand:OnUpdateNode()
	local refList = GameTable.HolyLandRankRef
	local uiList = self:FindUIScroll("holyLandNode")
	if uiList then
		uiList:RefreshData(refList)
	else
		uiList = self:GetUIScroll("holyLandNode")
		uiList:Create(self.mListGrade,refList,function(...) self:OnDrawNodeItem(...) end)
	end
	uiList:MoveToPos((gModelHolyLand.holyLandInfo.rank or 0)-1)
end

function UISubHoLand:OnCheckCost()
    local ref = GameTable.HolyLandLvRef[gModelHolyLand.holyLandInfo.level]
	if not ref or ref.lvNext<=0 then GF.ShowMessage(ccClientText(12611))
	return end
	local list = LxDataHelper.ParseItem(ref.upNeed) or {}
	local gotoUp, lackRefId = true
    for i, v in ipairs(list) do
        local tRefId = v.itemId
        local haveNum = gModelItem:GetNumByRefId(tRefId)
        if haveNum < v.itemNum then
            gotoUp = false
            lackRefId = tRefId
            break
        end
    end
    if gotoUp then
		gModelHolyLand.HolyLandLevelUpReq()
    else
        gModelGeneral:OpenGetWayWnd({ itemId = lackRefId })
    end
end
function UISubHoLand:UpdateAttrs()
	local refId = gModelHolyLand.holyLandInfo.level>0 and gModelHolyLand.holyLandInfo.level or 1
	local ref = GameTable.HolyLandLvRef[refId]
	local curlist,nextAttrMap = gModelHolyLand:GetHolyLandAttrByLv(refId)
	self:SetWndText(self.mTxtLevel,string.replace(ccClientText(32716),ref.lvNow))
	self.nextAttrMap = nextAttrMap
	local uiAttrList = self._uiAttrList
	if uiAttrList then
		uiAttrList:RefreshList(curlist)
	else
		uiAttrList = self:GetUIScroll("HolyLandAttrList")
		self._uiAttrList = uiAttrList
		uiAttrList:Create(self.mListAttrs,curlist,function(...) self:OnDrawAttrCell(...) end)
	end
end

function UISubHoLand:OnDrawNodeItem(list,item,itemdata,index)
	local ImgBg = self:FindWndTrans(item,"ImgBg")
	local ImgPress = self:FindWndTrans(item,"ImgPress")
	local TxtGrade = self:FindWndTrans(item,"TxtGrade")
	local imgLine = self:FindWndTrans(item,"ImgLine")
	local curRank = gModelHolyLand.holyLandInfo.rank or 0
	local active = curRank>=itemdata.rankNow
	local imgPath = active and "holyhand_icon_3" or (curRank+1==itemdata.rankNow and "holyhand_icon_4" or "holyhand_icon_2")
	local linePath = curRank>=itemdata.rankNow-1 and "holyhand_bar_5" or "holyhand_bar_4"
	self:SetWndEasyImage(ImgBg,imgPath,nil,true)
	self:SetWndEasyImage(imgLine,linePath,nil,true)
	CS.ShowObject(ImgPress,false)
	CS.ShowObject(imgLine,index~=1)
	if curRank+1==itemdata.rankNow then
		CS.ShowObject(ImgPress,true)
		local img = self:FindWndImage(ImgPress)
		local frontRef = GameTable.HolyLandRankRef[itemdata.rankNow-1]
		local ref = GameTable.HolyLandLvRef[gModelHolyLand.holyLandInfo.level]
		local curlv = ref and ref.lvNow or 0
		local total = itemdata.needLv
		if frontRef then
			curlv = curlv - frontRef.needLv
			total = total - frontRef.needLv
		end
		img.fillAmount = curlv / total
	end
	self:SetWndText(TxtGrade,string.replace(ccClientText(40500),itemdata.rankNow))
	self:SetWndClick(item,function()
		local attrs = LxDataHelper.ParseAttrList(itemdata.attr)
		self:ShowGradeDescDiv(attrs,itemdata.needLv)
	end)
end
function UISubHoLand:OnUpdateRedPoint(trans,isShow)
	local RedPoint=self:FindWndTrans(trans,"redPoint")
	CS.ShowObject(RedPoint,isShow)
end

function UISubHoLand:ShowGradeDescDiv(attrs,grade)
    CS.ShowObject(self.mGradeDescMask, true)
    local str = string.replace(ccClientText(40506), grade)
    self:SetWndText(self.mCurGradeDesc, str)
	local childTrans = nil
	local AttrIcon,AttrName = nil,nil
	for index, attr in ipairs(attrs) do
		childTrans = self.mItemRoot:GetChild(index-1)
		if childTrans then
			CS.ShowObject(childTrans,true)
			AttrIcon = self:FindWndTrans(childTrans,"AttrIcon")
			AttrName = self:FindWndTrans(childTrans,"AttrName")
			self:SetWndEasyImage(AttrIcon,gModelHero:GetAttributeIconById(attr.refId))
			local str = gModelHero:GetAttributeNameById(attr.refId)
			str = str.." <color=#68e6ac>"..gModelHero:GetAttributeValueNoNameByIdAndVal(attr.refId,attr.type,attr.value).."</color>"
			self:SetWndText(AttrName,str)
		end
	end
	self:SetWndText(self.mYaoqiuDesc, str)
end

function UISubHoLand:AddEventMsg()
	if PRODUCT_G_VER ~= 0 then -- 提审
		self:SetWndEasyImage(self.mBgImage, "holyhand_bg_11", nil,nil, true)
	end
	self:SetWndText(self.mTxtAttrTitle,ccClientText(40502))
	self:SetWndButtonText(self.mUpLvBtn,ccClientText(40501))
	self:SetWndText(self.mTxtPray,ccClientText(40503))
	gModelHolyLand.HolyLandInfoReq()
	self:SetWndClick(self.mBtnPray,function()
		GF.OpenWnd("UIHoLandPray")
	end)
	self:SetWndClick(self.mUpLvBtn,function()
		self:OnCheckCost()
	end)
	self:SetWndClick(self.mImgHelp,function()
		GF.OpenWnd("UIBzTips",{refId = 164})
	end)
	self:SetWndClick(self.mGradeDescMask, function()
        CS.ShowObject(self.mGradeDescMask, false)
		for i = 1, self.mItemRoot.childCount do
			local trans = self.mItemRoot:GetChild(i-1)
			CS.ShowObject(trans,false)
		end
    end)
	self:RegisterRedPointFunc(ModelRedPoint.HOLY_LAND_PRAY_ENTRANCE,function(isShow) self:OnUpdateRedPoint(self.mBtnPray,isShow) end)
	self:RegisterRedPointFunc(ModelRedPoint.HOLY_LAND_UPGRADGE,function(isShow) self:OnUpdateRedPoint(self.mUpLvBtn,isShow) end)
	self:WndEventRecv(EventNames.HOLYLAND_UPDATE,function() self:OnUpdatePanel() end)
	self:WndEventRecv(EventNames.On_Item_Change,function() self:UpdateCost() end)
end

function UISubHoLand:OnUpdatePanel()
	self:UpdateAttrs()
	self:UpdateCost()
	self:OnUpdateNode()
end

function UISubHoLand:UpdateCost()
	local ref = GameTable.HolyLandLvRef[gModelHolyLand.holyLandInfo.level or 1]
	if not ref then return end
	self:SetWndButtonGray(self.mUpLvBtn,ref.lvNext<=0)
	self:SetWndButtonText(self.mUpLvBtn,ref.lvNext<=0 and ccClientText(12611) or ccClientText(40501))
	local list = LxDataHelper.ParseItem(ref.upNeed) or {}
	local uiList = self:FindUIScroll("holyLandCost")
	if uiList then
		uiList:RefreshData(list)
	else
		uiList = self:GetUIScroll("holyLandCost")
		uiList:Create(self.mSellItemList,list,function(...) self:OnDrawCostItem(...) end)
	end
end
------------------------------------------------------------------
return UISubHoLand