---
--- Created by Administrator.
--- DateTime: 2024/3/20 21:11:16
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBadgeGameChapter:LWnd
local UIBadgeGameChapter = LxWndClass("UIBadgeGameChapter", LWnd)
------------------------------------------------------------------
local ClickListener = typeof(CS.YXUIClickListener)
--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBadgeGameChapter:UIBadgeGameChapter()
    local starRef = LxDataHelper.ParseNumber_Sign(GameTable.BadgeGameConfigRef.boxStar)
	self.maxStar = starRef[#starRef]
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBadgeGameChapter:OnWndClose()
	LWnd.OnWndClose(self)
    if self._cacheComponents then self._cacheComponents = nil end
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBadgeGameChapter:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBadgeGameChapter:OnStart()
	LWnd.OnStart(self)
	self:InitUI()


    self._isVie = gLGameLanguage:IsVieVersion()
    self:addEventMsg()
    --界面创建结束，加载完成，处理逻辑
    self:SetWndText(self.mLblBiaoti,ccClientText(40208))
    self:SetWndText(self.mCloseInfo,ccClientText(41037))
    self:CrestChapterList()
end

function UIBadgeGameChapter:addEventMsg()
    self:WndEventRecv(EventNames.BADGE_GAME_UPDATE,function(...) self:UpadteList() end)
    self:SetWndClick(self.mBtnHelp,function()
        GF.OpenWnd("UIBzTips",{refId = 164})
    end)
    self:SetWndClick(self.mImgMask,function()
        self:WndClose()
    end)
    self:SetWndClick(self.mBtnClose,function()
        self:WndClose()
    end)
end

function UIBadgeGameChapter:CrestChapterList()
    local chapterType = self:GetWndArg("chapterType")
    local list = {}
    local chapterRef = GameTable.BadgeGameChapRef
    ---@type V_BadgeGameChapRef[]
    local refList = {}
    local refsCnt = 0
    for _, value in pairs(chapterRef) do
        if value.type == chapterType then
            table.insert(refList,value)
            refsCnt = refsCnt + 1
        end
    end
    table.sort(refList,function(a,b) return a.refId < b.refId end)

    local minRefId,maxRefId
    if refsCnt > 0 then
        minRefId = refList[1].refId
        maxRefId = refList[refsCnt].refId
    end

    local starInfo = ModelBadgeGame.StarImgMap[chapterType]
    if starInfo then
        self._starImg = starInfo.Act
    end


    local chapterInfo = nil
    local refId
    for i,v in ipairs(refList) do
        refId = v.refId
        chapterInfo = gModelBadgeGame:GetChapterById(refId)
        local state = chapterInfo and chapterInfo:GetChapterState() or 2
        if state == 2 then
            table.insert(list,{chapterRef = v,state = state,refId = refId,minRefId = minRefId,maxRefId = maxRefId})
            break
        else
            table.insert(list,{chapterRef = v,state = state,refId = refId,minRefId = minRefId,maxRefId = maxRefId})
        end
    end

    table.sort(list,function(a,b)
        if a.state ~= b.state then
            return a.state < b.state
        else
            return a.refId < b.refId
        end
    end)

    local redIndex = nil
    for index, value in ipairs(list) do
        chapterInfo = gModelBadgeGame:GetChapterById(value.refId)
        if chapterInfo and chapterInfo:GetChapterRed() then
            redIndex = index
            break
        end
    end
    self.listChpater = self:CreateUIScrollImpl(nil,self.mListChapter,list,function(...)
        self:OnDrawChapterItem(...)
    end,UIItemList.SUPER_GRID)
    if redIndex and redIndex > 0 then
        self.listChpater:MoveToPos(redIndex)
    end
end
function UIBadgeGameChapter:OnDrawChapterItem(list,item,itemData,index)
    local instanceID = item:GetInstanceID()
    local itemCache = self._cacheComponents and self._cacheComponents[instanceID]
    if not itemCache then
        itemCache ={
            imgPassed = self:FindWndTrans(item,"ImgPassed"),
            txtPassed = self:FindWndTrans(item,"TxtPassed"),
            txtchaperNum = self:FindWndTrans(item,"TxtchaperNum"),
            txtChatper = self:FindWndTrans(item,"TxtChatper"),
            txtStar = self:FindWndTrans(item,"TxtStar"),
            btnGift = self:FindWndTrans(item,"BtnGift"),
            btnChapter = self:FindWndTrans(item),
            imgMask = self:FindWndTrans(item,"ImgMask"),
            imgLock = self:FindWndTrans(item,"TxtNotPassed/ImgLock"),
            imgChapter = self:FindWndTrans(item,"ImgBg/ImgChapter"),
            imgRed = self:FindWndTrans(item,"ImgRed"),
            txtNotPassed =self:FindWndTrans(item,"TxtNotPassed"),
            slider = self:FindWndTrans(item,"Slider"),
            imgTxt = self:FindWndTrans(item,"ImgTxt"),
            txtBtnGo = self:FindWndTrans(item,"BtnGo/TxtBtnGo"),
            btnGo = self:FindWndTrans(item,"BtnGo"),
            txtBtnGift = self:FindWndTrans(item,"BtnGift/TxtBtnGift"),
            canvasGroup = self:GetCanvasGroup(item)
        }
        if self._starImg then
            self:SetWndEasyImage(self:FindWndTrans(item,"ImgStar"),self._starImg)
        end
        self:SetComponentCache(instanceID,itemCache)
    end
    local chapterInfo = gModelBadgeGame:GetChapterById(itemData.refId)
    local state = itemData.state or 2
    local color = state==4 and "139057ff" or "c81212ff"
    ----未全部通关章节，未解锁章节，未完美通关，已完美通关=1、2、3、4
    CS.ShowObject(itemCache.imgPassed.gameObject,state==4)
    self:SetWndText(itemCache.txtPassed,state==4 and ccClientText(40207) or "")

    local chapterRef = itemData.chapterRef
    self:SetWndText(itemCache.txtchaperNum,ccLngText(chapterRef.name))
    self:SetWndText(itemCache.txtChatper,ccClientText(40208))
    self:SetWndText(itemCache.txtStar,(chapterInfo and chapterInfo.starNum or 0).."/"..self.maxStar)
    self:SetWndText(itemCache.txtBtnGo,ccClientText(40225))
    self:SetWndText(itemCache.txtBtnGift,ccClientText(40224))
    self:SetXUITextTransColor(itemCache.txtStar,color)
    local sliderComp = self:FindWndSlider(itemCache.slider)
    sliderComp.value = (chapterInfo and chapterInfo.starNum or 0)/self.maxStar
    CS.ShowObject(itemCache.slider,state~=4)
    CS.ShowObject(itemCache.imgMask.gameObject,state==2)
    local curLv = gModelPlayer:GetPlayerLv()
    local cRef = GameTable.BadgeGameChapRef[math.max(itemData.minRefId,itemData.refId-1)]
    local conStr = ""
    if chapterRef.needLevel>curLv then
        conStr = string.replace(ccClientText(40210),chapterRef.needLevel)
    else
        if chapterRef.needStar>0 then
            conStr = string.replace(ccClientText(40209),ccLngText(cRef.name),chapterRef.needStar)
        else
            conStr = string.replace(ccClientText(40219),ccLngText(cRef.name))
        end
    end
    self:SetWndText(itemCache.txtNotPassed,state==2 and conStr or ccClientText(40211))
    CS.ShowObject(itemCache.txtNotPassed,state==2 )--or state==3
    CS.ShowObject(itemCache.imgTxt,state==2 )--or state==3
    CS.ShowObject(itemCache.imgLock,state==2)
    -- itemCache.canvasGroup.blocksRaycasts = not (state == 2);
    -- self:SetWndEasyImage(itemCache.imgChapter,state==4 and "badgeGame_img2" or "badgeGame_img1")--BadgeGame/
    CS.ShowObject(itemCache.imgRed,self:GetBoxRed(chapterInfo))

    if self._isVie then
        itemCache.txtBtnGift.sizeDelta = Vector2.New(100,30)
        local textTran = LxUiHelper.FindXTextCtrl(itemCache.txtBtnGift)
        textTran.enableWordWrapping = true
    end

    self:SetWndClick(itemCache.btnGift,function ()
        GF.OpenWnd("UIBrandGameBox",{chapterId = chapterRef.refId})
    end)
    self:SetWndClick(itemCache.btnGo,function ()
        local chapterId = chapterRef.refId
        GF.OpenWnd("UIBrandGameWin",{
            chapterId = chapterId,
            chapterType = gModelBadgeGame:GetBadgeGameChapRefType(chapterId),
            isSel = true,
            isJump = true,
        })
        self:WndClose()
    end)
end

function UIBadgeGameChapter:GetBoxRed(chapterinfo)
    if not chapterinfo then return false end
    local boxRef = LxDataHelper.ParseNumber_Sign(GameTable.BadgeGameConfigRef.boxStar)
    for indx, value in ipairs(boxRef) do
        if chapterinfo:GetBoxState(indx)==2 then return true end
    end
    return false
end

function UIBadgeGameChapter:UpadteList()
    local uiList = self.listChpater
    if uiList then
        uiList:DrawAllItems()
    end
end

function UIBadgeGameChapter:SetComponentCache(instanceID,itemCache)
    if not self._cacheComponents then self._cacheComponents = {} end
    self._cacheComponents[instanceID] = itemCache
end

------------------------------------------------------------------
return UIBadgeGameChapter