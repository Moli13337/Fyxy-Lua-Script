---
---活动100 活动特权
--- Created by Ease.
--- DateTime: 2023/10/26 21:06:25
---
------------------------------------------------------------------
local LWnd = LWnd

---@class UIActPrige:LWnd
local UIActPrige = LxWndClass("UIActPrige", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActPrige:UIActPrige()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActPrige:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActPrige:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActPrige:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitBtnEvent()
	self:InitMessage()
	self:InitDate()
end
function UIActPrige:ResetData(pb)
	local sid = pb.sid
	if (self._sid ~= sid) then
		return
	end
	self._page = gModelActivity:GenerateActivePageDataFromPb(pb.pages[1])
	self._entry = self._page.entry
	self:RefreshData()
end
function UIActPrige:SetPageBtn()
	local btnCfg = self._config.btnIcon
	local cfgArr = string.split(btnCfg, "=")
	local btnTxtTrans = self:FindWndTrans(self.mPageBtn, "NameText")
	local btnTrans = self:FindWndTrans(self.mPageBtn, "Icon")
	self:SetWndText(btnTxtTrans, cfgArr[4])
	self:SetBgImgAndPos(btnTrans, cfgArr[3])
end
--设置伙伴立绘/spine
function UIActPrige:SetHeroGroup()
	local heroCfgArr = string.split(self._config.privilegeHero,"=")
	CS.ShowObject(self.mHeroImg, heroCfgArr[1] == "1")
	CS.ShowObject(self.mShowSpine, heroCfgArr[1] == "2")
	local assetName = heroCfgArr[2]
	if(heroCfgArr[1] == "1")then
		self:SetBgImgAndPos(self.mHeroImg, assetName, self._config.privilegeHeroPos)
	elseif(heroCfgArr[1] == "2")then
		self:CreateSpine("TopSpine",self.mShowSpine,assetName,self._config.privilegeHeroPos,self._config.privilegeHeroTurn)
	else
		self:SetBgImgAndPos(self.mHeroImg, self._config.privilegeHero, self._config.privilegeHeroPos)
	end
end
function UIActPrige:OnActivityConfigData()
	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	self._config = webData.config
	self:SetWndText(self.mDesText, self._config.privilegeHeroTxt)
	local descTxtPos = self._config.privilegeTipsPos
	if not string.isempty(descTxtPos) then
		self:SetAnchorPos(self.mDesText, LxDataHelper.ParseVector2NotEmpty(descTxtPos))
	end
	self:SetBgImgAndPos(self.mBg, self._config.privilegeImage)
	self:SetBgImgAndPos(self.mTextImg, self._config.privilegeTitle, self._config.privilegeTitlePos)
	self:SetHeroGroup()
	--self:SetBgImgAndPos(self.mHeroImg, self._config.privilegeHero, self._config.privilegeHeroPos)
	--self:SetBgImgAndPos(self.mTextImg, self._config.privilegeTitle, self._config.privilegeTitlePos)
	if(self._config.btnIconShow and self._config.btnIconShow == 1)then
		self:SetPageBtn()
	end
	CS.ShowObject(self.mPageBtn,self._config.btnIconShow and self._config.btnIconShow == 1)
	gModelActivity:OnActivityPageReq(self._sid)
	local closeBtnArr = string.split(self._config.closeBtn,"=")
	if(closeBtnArr[2])then
		self:SetWndEasyImage(self.mBtnClose,closeBtnArr[2])
	end
	local closeBtnPos = closeBtnArr[3]
	if not string.isempty(closeBtnPos) then
		self:SetAnchorPos(self.mBtnClose, LxDataHelper.ParseVector2NotEmpty(closeBtnPos))
	end
	local closeTextArr = string.split(self._config.closeText,"=")
	local closeStr = (closeTextArr and closeTextArr[1]) and closeTextArr[1] or ""-- or ccClientText(25922)
	if((closeTextArr and closeTextArr[2]))then
		local closeTxtPos = closeTextArr[2]
		if not string.isempty(closeTxtPos) then
			self:SetAnchorPos(self.mCloseText, LxDataHelper.ParseVector2NotEmpty(closeTxtPos))
		end
	end
	self:SetWndText(self.mCloseText, closeStr)
	CS.ShowObject(self.mBtnClose,true)
end
function UIActPrige:ListItem(list, item, itemdata, itempos)
	local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid, itemdata.pageId, itemdata.entryId)
	local icon = CS.FindTrans(item, "Icon")
	local nameText = CS.FindTrans(item, "NameText")
	local descScroll = CS.FindTrans(item, "DescScroll")
	local desText = CS.FindTrans(descScroll, "DesText")
	local image = CS.FindTrans(item, "Image")
	local gotoImg = self:FindWndTrans(item,"GotoImg")
	local imagePath = self._config.privilegeCellImage or "activity_nationalday_bg_2"
	self:SetBgImgAndPos(image, imagePath,self._config.privilegeCellImagePos)
	self:SetWndEasyImage(icon, entryCfg1.icon, nil, true)
	self:SetWndText(nameText, entryCfg1.name)
	local str = string.gsub(entryCfg1.description, "\\n", "\n")
	self:SetWndText(desText, str)
	local desTxtPos = self._config.privilegeDescPos
	if not string.isempty(desTxtPos) then
		self:SetAnchorPos(descScroll, LxDataHelper.ParseVector2NotEmpty(desTxtPos))
	end
	local nameTxtPos = self._config.privilegeNamePos
	if not string.isempty(nameTxtPos) then
		self:SetAnchorPos(nameText, LxDataHelper.ParseVector2NotEmpty(nameTxtPos))
	end
	if not string.isempty(entryCfg1.moreInfo) then
		self:SetAnchorPos(icon,LxDataHelper.ParseVector2(entryCfg1.moreInfo))
	end
	local gotoPath = self._config.clickJumpImg
	local showGotoImg = string.isempty(gotoPath)
	self:SetWndClick(gotoImg, function()
		local functionId = entryCfg1.jumpId
		if functionId and not gModelFunctionOpen:CheckIsOpened(functionId, true) then
			return
		end
		gModelFunctionOpen:Jump(functionId, self:GetWndName())
	end)
	local gotoImgPos = self._config.clickJumpImgPos
	if not string.isempty(gotoImgPos) then
		self:SetAnchorPos(gotoImg, LxDataHelper.ParseVector2NotEmpty(gotoImgPos))
	end
	if(gotoPath)then
		self:SetWndEasyImage(gotoImg,gotoPath)
	end
	CS.ShowObject(gotoImg,not showGotoImg)
end
function UIActPrige:CreateSpine(key, spineRoot, spineName,pos,isTurn)
	self:DestroyWndSpineByKey(spineName)
	self:CreateWndSpine(spineRoot,spineName,key,false, function(dpSpine)
		dpSpine:SetIgnoreTimeScale(true)
	end)
	local scaleX = (isTurn and isTurn == 1) and -1 or 1
	if(pos)then
		self:SetAnchorPos(spineRoot, LxDataHelper.ParseVector2NotEmpty2(pos))
	end
	spineRoot.localScale = Vector3.New(scaleX,1,1)
end
function UIActPrige:RefreshData()
	local list = self._entry or {}
	if self._uiCellList then
		self._uiCellList:RefreshList(list)
	else
		self._uiCellList = self:GetUIScroll("privileList")
		self._uiCellList:Create(self.mCellScroll, list, function(...)
			self:ListItem(...)
		end)
		self._uiCellList:EnableScroll(true, false)
	end
end
function UIActPrige:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
		self:ResetData(pb)
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp, function(pb)
		self:ResetData()
	end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(data, sid)
		if sid ~= self._sid then
			return
		end
		self:OnActivityConfigData()
	end)
end
function UIActPrige:SetBgImgAndPos(imgTrans, imgPath, offset)
	if (imgPath) then
		self:SetWndEasyImage(imgTrans, imgPath)
		if (offset and not string.isempty(offset)) then
			local pos = LxDataHelper.ParseVector2NotEmpty2(offset)
			self:SetAnchorPos(imgTrans, pos)
		end
	end
	CS.ShowObject(imgTrans, imgPath ~= nil)
end
function UIActPrige:InitDate()
	self._sid = self:GetWndArg("sid")
	self._modelId = gModelActivity:GetActivityModeIdBySid(self._sid)
	gModelActivity:ReqActivityConfigData(self._sid)
end
function UIActPrige:InitBtnEvent()
	self:SetWndClick(self.mBtnClose, function(...)
		self:WndClose()
	end)
end
------------------------------------------------------------------
return UIActPrige


