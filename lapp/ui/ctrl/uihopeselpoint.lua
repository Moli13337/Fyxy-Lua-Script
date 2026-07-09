---
--- Created by LCM.
--- DateTime: 2024/3/28 10:30:29
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeSelPoint:LWnd
local UIHopeSelPoint = LxWndClass("UIHopeSelPoint", LWnd)

UIHopeSelPoint.SHOW_POINT = 1					-- 点数展示
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeSelPoint:UIHopeSelPoint()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeSelPoint:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeSelPoint:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeSelPoint:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitViewType()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()
end

function UIHopeSelPoint:OnDrawBtnCell(list,item,itemdata,itempos)
	local Btn = self:FindWndTrans(item,"Btn")
	self:SetWndButtonText(Btn,itemdata.name)
	self:SetWndClick(Btn,function()
		self:OnClickBtnFunc(itemdata)
	end)
end

function UIHopeSelPoint:OnClickPointImgFunc(itemdata)
	if not itemdata then return end
	local point = itemdata.point
	if self._selId == point then return end
	self._selId = point

	self:RefreshUIPointList()
end

function UIHopeSelPoint:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIHopeSelPoint:RefreshUIPointList()
	local uiPointList = self._uiPointList
	if not uiPointList then return end
	local uiList = uiPointList:GetList()
	uiList:RefreshList()
end

function UIHopeSelPoint:RefreshShowPointView()
	local refId = self._refId
	if not refId then return end
	local pointConfig = self:GetWndArg("pointConfig")
	local list = {}
	local minPoint,maxPoint = pointConfig.minPoint,pointConfig.maxPoint
	if minPoint and maxPoint then
		for i = minPoint,maxPoint do
			table.insert(list,{
				point = i,
				img = "dreamTrip_icon_" .. i,
			})
		end
	end
	self:InitPointList(list)

	local btnList = {
		{
			name = ccClientText(10230),
			func = function()
				self:OnClickUseBtnFunc()
			end
		}
	}
	self:InitBtnList(btnList)
end

function UIHopeSelPoint:RefreshBaseInfo()
	local refId = self._refId
	if not refId then return end

	local itemIconTrans = self:FindWndTrans(self.mItemInfo,"ItemIcon")
	if itemIconTrans then
		local instanceId = itemIconTrans:GetInstanceID()
		local baseClass = self:GetCommonIcon(instanceId)
		baseClass:Create(itemIconTrans)
		baseClass:SetCommonReward(LItemTypeConst.TYPE_ITEM, refId, -1)
		baseClass:EnableShowNum(true)
		baseClass:DoApply()
	end

	local name = gModelItem:GetNameByRefId(refId)
	self:SetWndText(self.mNameTxt,name)

	local num = gModelItem:GetNumByRefId(refId)
	local numStr = string.replace(ccClientText(10205),num)
	self:SetWndText(self.mNumTxt,numStr)

	local desc = gModelItem:GetDescByRefId(refId)
	local noEmpty = not string.isempty(desc)
	if noEmpty then
		self:SetWndText(self.mDescTxt,desc)
	end
	CS.ShowObject(self.mDaoJuMiaoShuDiv,noEmpty)

	local quality = gModelItem:GeQualityByRefId(refId)
	local heroMessage = gModelItem:GetHeroMessQualityById(quality)
	if heroMessage then self:SetWndEasyImage(self.mHeadImg,heroMessage) end
end

function UIHopeSelPoint:InitViewType()
	local viewType = self:GetWndArg("viewType")
	if not viewType then
		viewType = ModelCommonDreamTrip.MAP_TYPE_NORMAL
	end
	self._viewType = viewType
end

function UIHopeSelPoint:InitData()
	self._showType = self:GetWndArg("showType") or UIHopeSelPoint.SHOW_POINT

	self._refId = self:GetWndArg("refId")
end

function UIHopeSelPoint:OnDrawPointCell(list,item,itemdata,itempos)
	local PointImg = self:FindWndTrans(item,"PointImg")
	local SelImg = self:FindWndTrans(item,"SelImg")
	local isSel = self._selId == itemdata.point
	CS.ShowObject(SelImg,isSel)

	local img = itemdata.img
	self:SetWndEasyImage(PointImg,img,function() CS.ShowObject(PointImg,true) end)

	self:SetWndClick(PointImg,function()
		self:OnClickPointImgFunc(itemdata)
	end)
end

function UIHopeSelPoint:InitMsg()
	self:WndNetMsgRecv(LProtoIds.DreamTripItemUseResp,function(pb,ret)
		local itemId = pb.itemId
		if self._refId == itemId then
			GF.ShowMessage(ccClientText(20482))
			self:WndClose()
		end
	end)
	self:WndNetMsgRecv(LProtoIds.ActivitySpecialOpResp,function(pb,ret)
		local curSid = self:GetWndArg("sid")
		local sid = pb.sid
		local opType = pb.opType
		if curSid == sid and opType == ModelActivity.DREAM_TRIP_ITEM then
			GF.ShowMessage(ccClientText(20482))
			self:WndClose()
		end
	end)
end

function UIHopeSelPoint:OnClickBtnFunc(dataInfo)
	local func = dataInfo.func
	if func then func() end
end

function UIHopeSelPoint:OnClickNormalUseBtnFunc()
	local itemId = self._refId
	local targetId = self._selId
	if itemId and targetId then
		gModelDreamTrip:OnDreamTripItemUseReq(itemId,tostring(targetId))
	else
		GF.ShowMessage(ccClientText(20483))
	end
end

function UIHopeSelPoint:InitBtnList(list)
	list = list or {}
	local len = #list
	local showBtnDiv = len > 0
	local showMaxTrans = len > 4 and self.mBtnList or self.mBtnList1

	local uiBtnList = self._uiBtnList
	if uiBtnList then
		uiBtnList:RefreshList(list)
	else
		uiBtnList = self:GetUIScroll("uiBtnList")
		self._uiBtnList = uiBtnList
		uiBtnList:Create(showMaxTrans,list,function(...) self:OnDrawBtnCell(...) end)
	end

	CS.ShowObject(self.mBtnBg,showBtnDiv)
end

function UIHopeSelPoint:OnClickUseBtnFunc()
	local viewType = self._viewType
	if viewType == ModelCommonDreamTrip.MAP_TYPE_NORMAL then
		self:OnClickNormalUseBtnFunc()
	else
		self:OnClickActivityUseBtnFunc()
	end
end

function UIHopeSelPoint:InitText()
	self:SetWndText(self.mDaoJuMiaoShuTxt,ccClientText(10240))
	self:SetWndText(self.mPointShowTxt,ccClientText(20484))
end

function UIHopeSelPoint:OnClickActivityUseBtnFunc()
	local itemId = self._refId
	local targetId = self._selId
	if itemId and targetId then
		local sid = self:GetWndArg("sid")
		local arg = itemId .. "|" .. targetId
		gModelActivityDreamTrip:OnActivityDreamTripItemReq(sid,arg)
	else
		GF.ShowMessage(ccClientText(20483))
	end
end

function UIHopeSelPoint:InitPointList(list,onDrawPointFunc)
	list = list or {}
	local len = #list
	local showDiv = len > 0

	onDrawPointFunc = onDrawPointFunc or function(...)
		self:OnDrawPointCell(...)
	end

	local uiPointList = self._uiPointList
	if uiPointList then
		uiPointList:RefreshList(list)
	else
		uiPointList = self:GetUIScroll("uiPointList")
		self._uiPointList = uiPointList
		uiPointList:Create(self.mPointShowList,list,function(...) onDrawPointFunc(...) end)
	end

	CS.ShowObject(self.mPointShowDiv,showDiv)
end

function UIHopeSelPoint:RefreshView()
	self:RefreshBaseInfo()

	local showType = self._showType
	if showType == UIHopeSelPoint.SHOW_POINT then
		self:RefreshShowPointView()
	end
end

------------------------------------------------------------------
return UIHopeSelPoint


