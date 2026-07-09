---
--- Created by Administrator.
--- DateTime: 2023/10/6 20:25:10
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBzPicturePop:LWnd
local UIBzPicturePop = LxWndClass("UIBzPicturePop", LWnd)

local typeUIText = typeof(CS.YXUIText)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBzPicturePop:UIBzPicturePop()

end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBzPicturePop:OnWndClose()
	FireEvent(EventNames.ON_HELP_PICTURE_WND_SHOW, false)

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBzPicturePop:OnCreate()

	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBzPicturePop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitData()
	self:RefreshView()
end

function UIBzPicturePop:GetCurPictureRef()
    local pageIndex = self._pageIndex
    if not pageIndex then
        return nil
    end
    return self._helpPictureRefList[pageIndex]
end

function UIBzPicturePop:RefreshArrowList()
    if not self._pictureNum then return end
    local isShow = self._pictureNum > 1
    CS.ShowObject(self._pictureNum, isShow)

    if not isShow then return end

    CS.ShowObject(self.mArrowLeft, self._pageIndex > 1)
    CS.ShowObject(self.mArrowRight, self._pageIndex < self._pictureNum)
end

function UIBzPicturePop:RefreshCloseBtn()
	self._canClose = self._canClose or self._pageIndex == self._pictureNum
	CS.ShowObject(self.mBtnClose, self._canClose)
end

function UIBzPicturePop:RefreshDesc()
    local ref = self:GetCurPictureRef()
    if not ref then return end

    local helpText = ref.helpText
    local str = ""
    if not string.isempty(helpText) then
        str = ccLngText(helpText)
    end
    self:SetWndText(self.mDescTxt, str)
end

function UIBzPicturePop:OnClickArrowBtn(addIndex)
	local oldIndex = self._pageIndex
	local newIndex = math.range(oldIndex + addIndex, 1, self._pictureNum)
	if newIndex == oldIndex then
		return
	end

	self._pageIndex = newIndex
	self:RefreshViewUI()
end

function UIBzPicturePop:InitData()
	local targetWndName = self:GetWndArg("targetWndName")

	local refId = self:GetWndArg("refId")
	if not refId then
		refId = gModelHelpPicture:GetHelpPrefabRefIdByWndName(targetWndName)
		if not refId then
			printInfoNR2("缺少配置", string.format("GameTable.SupportPrefabRef, wndName = %s",targetWndName or "nil"))
			return
		end
	end
	self._refId = refId
    self._helpPictureRefList = gModelHelpPicture:GetHelpPictureRefListByGroup(refId)
    self._pictureNum = #self._helpPictureRefList

	self._canClose = false
	self._pageIndex = 1

end


function UIBzPicturePop:CloseWndFunc()
	if not self._refId then
		self:WndClose()
		return
	end

	if not self._canClose then return end

	gModelHelpPicture:PubSupOperaReq(2, self._refId)

	self:WndClose()
end

function UIBzPicturePop:RefreshTopDesc()
	if not self._refId then return end

	local prefabRef = gModelHelpPicture:GetHelpPrefabRefByRefId(self._refId)
	if not prefabRef then return end

	local titleText = ccLngText(prefabRef.titleText)
	self:SetWndText(self.mTitleTxt, titleText)
end

function UIBzPicturePop:RefreshTextList()
    local ref = self:GetCurPictureRef()
    if not ref then return end

	local isShow = false
    for i = 1, 3 do
		local textTrans = self["mText"..i]
        local textStr = ref["text"..i]
		isShow = not string.isempty(textStr)
		CS.ShowObject(textTrans, isShow)
		if isShow then
			self:SetWndText(textTrans, ccLngText(textStr))

			local textPos = ref["textPos"..i]
			if not string.isempty(textPos) then
                local pos = LxDataHelper.ParseVector2NotEmpty(textPos)
				self:SetAnchorPos(textTrans, pos)
			end

			local alignment = ref["alignment"..i]
			if alignment and alignment ~= 0 then
				local uiText = self:FindCommonComponent(textTrans,typeUIText)
				local alignmentEnum = LxUiHelper.GetTMPAlignment(alignment)
				if uiText and alignmentEnum then
					uiText.alignment = alignmentEnum
				end
			end
		end
    end
end

function UIBzPicturePop:RefreshPageList()
	if not self._helpPictureRefList then return end

	local listData = self._helpPictureRefList
	local uiBtnList = self._uiBtnList
	if not uiBtnList then
		uiBtnList = UIListEasy:New()
		uiBtnList:Create(self,self.mPageBtnList)
		uiBtnList:EnableScroll(true,true)
		uiBtnList:SetFuncOnItemDraw(function(...)
			self:OnDrawPageBtnCell(...)
		end)
		self._uiBtnList = uiBtnList
	end

	for i,v in ipairs(listData) do
		uiBtnList:AddData(i,v)
	end

	uiBtnList:RefreshList()
	uiBtnList:DelayScrollTo(self._pageIndex - 1)
end


function UIBzPicturePop:OnClickTabBtn(itemRefId)
	self._pageIndex = itemRefId

	self:RefreshViewUI()
end

function UIBzPicturePop:RefreshHelpImg()
    local ref = self:GetCurPictureRef()
    if not ref then return end

    local imgPath = ref.image
    if LxUiHelper.IsImgPathValid(imgPath) then
        self:SetWndEasyImage(self.mHelpImg, imgPath, function()
            self:RefreshTextList()
        end, true)
    end
end

function UIBzPicturePop:InitEvent()
	--self:SetWndClick(self.mMask,function() self:CloseWndFunc() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function() self:CloseWndFunc() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mArrowLeft,function() self:OnClickArrowBtn(-1) end,LSoundConst.CLICK_BUTTON_COMMON)
	self:SetWndClick(self.mArrowRight,function() self:OnClickArrowBtn(1) end,LSoundConst.CLICK_BUTTON_COMMON)
end

--######################################################################################################################
--## View ##############################################################################################################
--######################################################################################################################
function UIBzPicturePop:RefreshView()
	self:RefreshTopDesc()
	self:RefreshViewUI()
end

function UIBzPicturePop:RefreshCenter()
    if not self._helpPictureRefList then return end

    self:RefreshArrowList()
    self:RefreshDesc()
    self:RefreshHelpImg()
end

function UIBzPicturePop:RefreshViewUI()
	self:RefreshCloseBtn()
	self:RefreshCenter()
	self:RefreshPageList()
end

function UIBzPicturePop:OnDrawPageBtnCell(list,item, itemdata, itempos)
	local tab = self:FindWndTrans(item,"BtnTab1")
	local tabState = self._pageIndex == itempos and LWnd.StateOn or LWnd.StateOff
	self:SetWndTabStatus(tab,tabState)

	local ref = itemdata
	local tabName = ccLngText(ref.tipText)
	self:SetWndTabText(tab,tabName, -2, -30)

	self:SetWndClick(item,function ()
		self:OnClickTabBtn(itempos)
	end)
end


------------------------------------------------------------------
return UIBzPicturePop


