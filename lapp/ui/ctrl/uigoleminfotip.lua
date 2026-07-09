---
--- Created by LCM.
--- DateTime: 2022/10/28 15:59:31
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGolemInfoTip:LWnd
local UIGolemInfoTip = LxWndClass("UIGolemInfoTip", LWnd)

UIGolemInfoTip.VIEW_TYPE_HEROWEAR = 1      --- 查看英雄身上
UIGolemInfoTip.VIEW_TYPE_OTHER = 2         --- 查看别人的魔偶
UIGolemInfoTip.VIEW_TYPE_BAG = 3           --- 查看背包的魔偶
UIGolemInfoTip.VIEW_TYPE_COMMON = 4        --- 通用查看

UIGolemInfoTip.RECASTBTN_FUNCTIONOPEN = 31000004 --32000002
UIGolemInfoTip.RECASTBTN_CODE = 1042 
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGolemInfoTip:UIGolemInfoTip()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGolemInfoTip:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGolemInfoTip:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGolemInfoTip:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:InitText()
    self:InitEvent()
    self:InitMsg()
    self:InitData()
    self:RefreshView()
end

function UIGolemInfoTip:OnClickJumpFunc(itemdata)
    local functionId = itemdata.functionId
    if not functionId then return end
    if not gModelFunctionOpen:CheckIsOpened(functionId,true) then return end
    gModelFunctionOpen:Jump(functionId,self:GetWndName())
end

function UIGolemInfoTip:OnClickAttrPreViewBtnFunc(itemdata,BtnTrans)
    local golemTipsArrow = gModelGolem:GetGolemConfigRefByKey("golemTipsArrow")
    if not golemTipsArrow then
        golemTipsArrow = 0
    end
    local showgolemTipsArrow = golemTipsArrow == 1

    local golemTipsFollowRoot = gModelGolem:GetGolemConfigRefByKey("golemTipsFollowRoot")
    if not golemTipsFollowRoot then
        golemTipsFollowRoot = 0
    end

    local trans
    if golemTipsFollowRoot == 0 then
        trans = self.mAttrTipsRoot
    elseif golemTipsFollowRoot == 1 then
        trans = BtnTrans
    end

    local golemTipsOffsetPos = gModelGolem:GetGolemConfigRefByKey("golemTipsOffsetPos")
    if not golemTipsOffsetPos then
        if golemTipsFollowRoot == 1 then
            golemTipsOffsetPos = "0,-0.03,0"
        else
            golemTipsOffsetPos = "0,0,0"
        end
    end
    local golemTipsOffsetPosInfo = string.split(golemTipsOffsetPos,",")
    local offsetX = tonumber(golemTipsOffsetPosInfo[1]) or 0
    local offsetY = tonumber(golemTipsOffsetPosInfo[2]) or 0
    local offsetZ = tonumber(golemTipsOffsetPosInfo[3]) or 0
    local offset = Vector3(offsetX,offsetY,offsetZ)
    gModelGolem:OpenGolemPreviewAttr({
        viewType = 1,
        golemInfo = self._golemData,
        attrType = itemdata.attrType,
        followRoot = trans,
        offsetPos = offset,
        showArrow = showgolemTipsArrow,
    })
end

function UIGolemInfoTip:OnClickLockBtnFunc()
    local golemData = gModelGolem:GetGolemServerDataById(self._golemData.id)
    gModelGolem:ChangeGolemLockStatusByGolemInfo(golemData)
end

function UIGolemInfoTip:RefreshTop()
    local golemData = self._golemData
    if not golemData then return end
    local trans = self.mGolemRoot
    local viewType = self._viewType

    local iconTrans = self:FindWndTrans(trans,"CommonUI/Icon")
    local instanceID = trans:GetInstanceID()
    local baseClass = self:GetCommonIcon(instanceID)
    baseClass:Create(iconTrans)
    if viewType == UIGolemInfoTip.VIEW_TYPE_COMMON then
        baseClass:SetGolemIcon(golemData.refId or golemData.itemId)
    else
        baseClass:SetGolemData({
            refId = gModelGolem:GetGolemRefIdByGolemInfo(golemData),
            lvlRefId = gModelGolem:GetGolemLvlRefIdByGolemInfo(golemData),
            lvl = gModelGolem:GetGolemLvlByGolemInfo(golemData),
            displayPos = gModelGolem:GetGolemElementGolemDrawingIconByGolemInfo(golemData),
        })
    end
    baseClass:DoApply()

    local refId
    if viewType == UIGolemInfoTip.VIEW_TYPE_COMMON then
        refId = golemData.refId or golemData.itemId
    else
        refId = gModelGolem:GetGolemRefIdByGolemInfo(golemData)
    end


    local quality = gModelGolem:GetGolemElementQualityByRefId(refId)
    local heroMessage = gModelItem:GetHeroMessQualityById(quality)
    if heroMessage then
        self:SetWndEasyImage(self.mHeadImg,heroMessage)
    end

    local golemName = gModelGolem:GetGolemElementNameByRefId(refId)
    self:SetWndText(self.mGolemName,golemName)
    local color = gModelGolem:GetGolemElementColorByRefId(refId)
    LxUiHelper.SetXTextColor(self.mGolemName,LUtil.ColorByHex(color))

    local type = gModelGolem:GetGolemElementTypeByRefId(refId)
    local typeStr = string.replace(ccClientText(33254),type)
    self:SetWndText(self.mGolemType,typeStr)

    local score
    if viewType == UIGolemInfoTip.VIEW_TYPE_COMMON then
        local lvrGroupId = gModelGolem:GetGolemElementLvrGroupIdByRefId(refId)
        local lvlRef = gModelGolem:GetGolemLvInfoByLvrGroupIdAndLv(lvrGroupId,0)
        if lvlRef then

            score = gModelGolem:GetGolemScoreByLevelRefId(lvlRef.refId)
        end
    else
        score = gModelGolem:GetGolemScoreByGolemInfo(golemData)
    end
    local scoreStr = string.replace(ccClientText(33255),score)
    self:SetWndText(self.mGolemScore,scoreStr)

    local showBack = viewType == UIGolemInfoTip.VIEW_TYPE_BAG or viewType == UIGolemInfoTip.VIEW_TYPE_HEROWEAR
    CS.ShowObject(self.mBackDiv,showBack)
end

function UIGolemInfoTip:InitViewTypeHeroWearData()

end

function UIGolemInfoTip:GetOriginConfigList(botBtnCodeList)
    local list = {}
    local originRef
    for i,v in ipairs(botBtnCodeList) do
        originRef = gModelGeneral:GetOriginConfigRef(v)
        if originRef then
            table.insert(list,originRef)
        else
            if LOG_INFO_ENABLED then
                printInfoNR("OriginConfigRef 表没有配置 refId = " .. v)
            end
        end
    end
    return list
end
------------------------- List -------------------------

function UIGolemInfoTip:OnWndRefresh()
    self:InitData()
    self:RefreshView()
end

function UIGolemInfoTip:InitViewTypeOhterData()

end

function UIGolemInfoTip:OnClickBotBtnFunc(itemdata)
    local code = itemdata.code
    if code == UIGolemInfoTip.RECASTBTN_CODE then
        if not gModelFunctionOpen:CheckIsOpened(UIGolemInfoTip.RECASTBTN_FUNCTIONOPEN,true) then
            return
        end
    end

    local golemData = self._golemData
    if not golemData then return end
    local refId = gModelGolem:GetGolemRefIdByGolemInfo(golemData)
    local index = gModelGolem:GetGolemElementGolemDrawingByRefId(refId)
    local curSelGolemId = gModelGolem:GetGolemIdByGolemInfo(golemData)
    local optStatus
    local wearStatus
    local page
    local viewType = self._intensifyType
    if code == 1041 then
        wearStatus = ModelGolem.OPSTYPE_TYPE_REPLACE
        optStatus = ModelGolem.OPTSTATUS_WAREHOUSE_REPLACE
    elseif code == 1042 then
        page = 3
        if self._viewType == UIGolemInfoTip.VIEW_TYPE_BAG then
            viewType = 2
        else
            viewType = 1
        end
    elseif code == 1028 then
        viewType = self._heroServerData ~= nil and 1 or 2
    elseif code == 1037 then
        page = 4
    end
    local params = {
        curSelGolemId = curSelGolemId,
        wearStatus = wearStatus,
        index = index,
        golemInfo = golemData,
        golemId = curSelGolemId,--gModelGolem:GetGolemIdByGolemInfo(golemData),
        heroServerData = self._heroServerData,
        viewType = viewType,
        optStatus = optStatus,
        page = page
    }
    gModelGeneral:RunOriginConfigCode(code, params)

    self:WndClose()
end

function UIGolemInfoTip:InitEvent()
    self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mShareBtn,function() self:OnClickShareBtnFunc() end)
    self:SetWndClick(self.mLockBtn,function() self:OnClickLockBtnFunc() end)
    self:SetWndClick(self.mIntensifyBtn,function() self:OnClickIntensifyBtnFunc() end)
    self:SetWndClick(self.mBtnBack,function ()
        self:OnClickGoloemBack()
    end)
end

function UIGolemInfoTip:InitData()
    local viewType = self:GetWndArg("viewType")
    self._viewType = viewType

    self._golemData = self:GetWndArg("golemData")

    self._heroServerData = self:GetWndArg("heroServerData")

    self._intensifyType = self:GetWndArg("intensifyType")

    self._golemList = self:GetWndArg("golemList")
    self._showRedPoint = self:GetWndArg("showRedPoint")

    if viewType == UIGolemInfoTip.VIEW_TYPE_HEROWEAR then
        self:InitViewTypeHeroWearData()
    elseif viewType == UIGolemInfoTip.VIEW_TYPE_OTHER then
        self:InitViewTypeOhterData()
    elseif viewType == UIGolemInfoTip.VIEW_TYPE_BAG then
        self:InitViewTypeBagData()
    elseif viewType == UIGolemInfoTip.VIEW_TYPE_COMMON then
        self:InitViewTypeCommmonData()
    end
end

function UIGolemInfoTip:InitViewTypeBagData()

end

function UIGolemInfoTip:InitDeputyAttrList(list)
    local uiDeputyAttrList = self._uiDeputyAttrList
    if uiDeputyAttrList then
        uiDeputyAttrList:RefreshList(list)
    else
        uiDeputyAttrList = self:GetUIScroll("uiDeputyAttrList")
        self._uiDeputyAttrList = uiDeputyAttrList
        uiDeputyAttrList:Create(self.mDeputyAttrList,list,function(...) self:OnDrawCommonAttrCell(...) end)
    end
end

function UIGolemInfoTip:RefreshLockStatus(show)
    CS.ShowObject(self.mLockBtn,show)
    if not show then return end
    local golem = gModelGolem:GetGolemServerDataById(self._golemData.id)
    if not golem then
        return
    end
    local lockStatus = golem:IsLock()
    CS.ShowObject(self.mLockStatus,lockStatus)
    CS.ShowObject(self.mUnLockStatus,not lockStatus)
end

function UIGolemInfoTip:OnClickIntensifyBtnFunc()
    local golemData = self._golemData
    if not golemData then return end
    local heroServerData = self._heroServerData
    local viewType = heroServerData ~= nil and 1 or 2
    gModelGeneral:RunOriginConfigCode(1028, {
        golemInfo = golemData,
        golemId = gModelGolem:GetGolemIdByGolemInfo(golemData),
        heroServerData = heroServerData,
        viewType = viewType,
    })
    self:WndClose()
end

function UIGolemInfoTip:RefreshCommonShow()
    CS.ShowObject(self.mTopBtnList,false)
    CS.ShowObject(self.mBotBtnDiv,false)
    CS.ShowObject(self.mWearStatus,false)

    local golemData = self._golemData
    if not golemData then return end

    self:SetTextTile(self.mGolemSuitEffTitle,ccClientText(33259))
    local golemRefId = golemData.refId or golemData.itemId

    local suit = gModelGolem:GetGolemElementSuitByRefId(golemRefId)

    local suitName = gModelGolem:GetGolemSuitNameByRefId(suit)
    self:SetWndText(self.mGolemSuitEffTxt,suitName)

    local icon = gModelGolem:GetGolemSuitIconByRefId(suit)
    self:SetWndEasyImage(self.mGolemSuitEffIcon,icon)

    local suitText,suitText1 = gModelGolem:GetGolemSuitSuitTextAndSuitText1ByRefId(suit)
    local twoEffDesc = string.replace(ccClientText(33258),ModelGolem.SUIT_WEAR_1)
    local twoEffTxt = string.replace(ccClientText(33257),twoEffDesc,suitText)

    local fourEffDesc = string.replace(ccClientText(33258),ModelGolem.SUIT_WEAR_2)
    local fourEffTxt = string.replace(ccClientText(33257),fourEffDesc,suitText1)

    local suitEffDesc = string.replace(ccClientText(33253),twoEffTxt,fourEffTxt)
    self:SetWndText(self.mGolemSuitEffDesc,suitEffDesc)

    local itemId = gModelGolem:GetGolemElementItemIdByRefId(golemRefId)
    if not itemId then
        CS.ShowObject(self.mDaoJuJumpDiv,false)
        return
    end
    local ref = gModelItem:GetRefByRefId(itemId)
    if not ref then
        CS.ShowObject(self.mDaoJuJumpDiv,false)
        return
    end
    local jumpDataList = gModelItem:ParseJump(ref.jump)
    if #jumpDataList < 1 then
        CS.ShowObject(self.mDaoJuJumpDiv,false)
        return
    end
    self:SetTextTile(self.mDaoJuJumpTitle,ccClientText(33224))

    local list = {}
    for i,v in ipairs(jumpDataList) do
        local jumpCfg = gModelGeneral:GetJumpConfig(v.jumpId)
        if jumpCfg then
            local data = {}
            data.name = ccLngText(jumpCfg.name)
            data.btnTxt = ccClientText(33269)
            data.functionId = jumpCfg.functionId
            data.isOpen = gModelFunctionOpen:CheckIsOpened(data.functionId)
            table.insert(list,data)
        end
    end
    self:InitJumpList(list)

    CS.ShowObject(self.mDaoJuJumpDiv,true)
end

function UIGolemInfoTip:RefreshAttrShow()
    if self._viewType == UIGolemInfoTip.VIEW_TYPE_COMMON then
        return
    end
    local golemData = self._golemData
    if not golemData then return end
    --[[    local mainAttrGroup = gModelGolem:GetGolemMainAttrGroupByGolemInfo(golemData)
        local mainAttrList = gModelGolem:GetGolemAttrListByGolemInfo(mainAttrGroup)]]

    local mainAttrList = gModelGolem:GetGolemMainAttrListByGolemInfo(golemData)
    self:InitPrimeAttrList(mainAttrList)

    --[[    local viceAttrGroup = gModelGolem:GetGolemMainAttrGroupByGolemInfo(golemData)
        local viceAttrList = gModelGolem:GetGolemAttrListByGolemInfo(viceAttrGroup)]]

    local viceAttrList = gModelGolem:GetGolemViceAttrListByGolemInfo(golemData)
    self:InitDeputyAttrList(viceAttrList)
end

function UIGolemInfoTip:OnDrawJumpCell(list,item,itemdata,itempos)
    local JumpNameTrans = self:FindWndTrans(item,"JumpName")
    local JumpTxtTrans = self:FindWndTrans(item,"JumpTxt")
    self:SetWndText(JumpNameTrans,itemdata.name)

    local hyper = self:GetUIHyperText(JumpTxtTrans)
    local str = hyper:AddHyper(itemdata.btnTxt,{func = function() self:OnClickJumpFunc(itemdata) end})
    self:SetWndText(JumpTxtTrans,str)
end

function UIGolemInfoTip:RefreshHeroWearShow()
    CS.ShowObject(self.mShareBtn,true)
    self:RefreshLockStatus(true)
    CS.ShowObject(self.mTopBtnList,true)

    CS.ShowObject(self.mWearStatus,gModelGolem:CheckGolemIsWearByGolemInfo(self._golemData))
    self:ShowBotBtnDiv(true)
    local botBtnCodeList = {1038,1041}
    local list =  self:GetOriginConfigList(botBtnCodeList)
    self:InitBotBtnList(list)
end

function UIGolemInfoTip:CreateAttrPreViewDiv(trans,info)
    local DescTrans = self:FindWndTrans(trans,"Desc")
    local BtnTrans = self:FindWndTrans(trans,"Btn")

    self:SetWndText(DescTrans,info.desc)
    self:SetWndClick(BtnTrans,function()
        self:OnClickAttrPreViewBtnFunc(info,BtnTrans)
    end)
end

function UIGolemInfoTip:RefreshOtherShow()
    CS.ShowObject(self.mTopBtnList,false)

    self:ShowBotBtnDiv(false)
    CS.ShowObject(self.mWearStatus,false)
end
function UIGolemInfoTip:OnOpenGolemMainWin()

end

function UIGolemInfoTip:OnGolemWearResp(pb)
    local golemData = self._golemData
    if not golemData then return end
    if self._heroServerData and pb.opsType == ModelGolem.OPSTYPE_TYPE_DEMOUNT then
        local heroId = self._heroServerData.id
        if pb.heroId == heroId then
            self:WndClose()
        end
    end
    local heroId = golemData.heroId
    if pb.heroId == heroId then
        self:WndClose()
    end
end

function UIGolemInfoTip:InitMsg()
    self:WndNetMsgRecv(LProtoIds.GolemWearResp,function(pb) self:OnGolemWearResp(pb) end)
    self:WndNetMsgRecv(LProtoIds.GolemLockResp,function(pb) self:OnGolemLockResp(pb) end)
    self:WndNetMsgRecv(LProtoIds.GolemBagResp,function(pb) self:RefreshView() end)

    -- self:WndNetMsgRecv("xxx",function(pb) self:Onxxx(pb) end)
    -- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UIGolemInfoTip:InitShowAttrBtnList(list)
    local uiShowAttrBtnList = self._uiShowAttrBtnList
    if uiShowAttrBtnList then
        uiShowAttrBtnList:RefreshList(list)
    else
        uiShowAttrBtnList = self:GetUIScroll("uiShowAttrBtnList")
        self._uiBotBtnList = uiShowAttrBtnList
        uiShowAttrBtnList:Create(self.mShowAttrBtnList,list,function(...) self:OnDrawBotBtnCell(...) end)
    end
end

function UIGolemInfoTip:InitText()
    self:SetTextTile(self.mPrimeAttrTitle,ccClientText(33218))
    self:SetTextTile(self.mDeputyAttrTitle,ccClientText(33219))
    self:SetTextTile(self.mSuitEffTitle,ccClientText(33259))

    local str =ccClientText(34849)-- "锁 定"
    self:SetTextTile(self.mLockBtn,str)
    str =ccClientText(34850)-- "回 退"
    self:SetTextTile(self.mBtnBack,str)
    str =ccClientText(34851)-- "分 享"
    self:SetTextTile(self.mShareBtn,str)

--[[    local originRef = gModelGeneral:GetOriginConfigRef(1028)
    if originRef then
        self:SetWndButtonText(self.mIntensifyBtn,ccLngText(originRef.name))
    end]]
end

function UIGolemInfoTip:InitViewTypeCommmonData()

end

function UIGolemInfoTip:RefreshSuitShow()
    if self._viewType == UIGolemInfoTip.VIEW_TYPE_COMMON then
        return
    end
    local golemData = self._golemData
    if not golemData then return end
    local suitName = gModelGolem:GetGolemSuitNameByGolemInfo(golemData)
    local golemList = self._golemList
    if golemList then
        local wearSuitRefId = gModelGolem:GetGolemElementSuitByGolemInfo(golemData)
        local wearGolemNum = 0
        for k,v in pairs(golemList) do
            if gModelGolem:GetGolemElementSuitByGolemInfo(v) == wearSuitRefId then
                wearGolemNum = wearGolemNum + 1
            end
        end
        local wearNumStr = string.replace(ccClientText(33256),wearGolemNum,ModelGolem.SUIT_WEAR_2)
        suitName = suitName .. wearNumStr
    end
    self:SetWndText(self.mSuitEffTxt,suitName)

    local icon = gModelGolem:GetGolemSuitIconByGolemInfo(golemData)
    self:SetWndEasyImage(self.mSuitEffIcon,icon,function()
        CS.ShowObject(self.mSuitEffIcon,true)
    end)

    local suitText,suitText1 = gModelGolem:GetGolemSuitSuitTextAndSuitText1ByGolemInfo(golemData)
    local twoEffDesc = string.replace(ccClientText(33258),ModelGolem.SUIT_WEAR_1)
    local twoEffTxt = string.replace(ccClientText(33257),twoEffDesc,suitText)

    local fourEffDesc = string.replace(ccClientText(33258),ModelGolem.SUIT_WEAR_2)
    local fourEffTxt = string.replace(ccClientText(33257),fourEffDesc,suitText1)

    local suitEffDesc = string.replace(ccClientText(33253),twoEffTxt,fourEffTxt)
    self:SetWndText(self.mSuitEffDesc,suitEffDesc)
end

function UIGolemInfoTip:InitBotBtnList(list)
    local uiBotBtnList = self._uiBotBtnList
    if uiBotBtnList then
        uiBotBtnList:RefreshList(list)
    else
        uiBotBtnList = self:GetUIScroll("uiBotBtnList")
        self._uiBotBtnList = uiBotBtnList
        uiBotBtnList:Create(self.mBotBtnList,list,function(...) self:OnDrawBotBtnCell(...) end)
    end
end

function UIGolemInfoTip:OnDrawCommonAttrCell(list,item,itemdata,itempos)
    local AttrIconTrans = self:FindWndTrans(item,"AttrIcon")
    local AttrNameTrans = self:FindWndTrans(item,"AttrName")
    local AttrValueTrans = self:FindWndTrans(item,"AttrValue")

    local attrRefId,attrType,attrNum = itemdata.attrRefId,itemdata.attrType,itemdata.attrNum

    local attrIcon = gModelHero:GetAttributeIconById(attrRefId)
    self:SetWndEasyImage(AttrIconTrans,attrIcon)

    local attrName = gModelHero:GetAttributeNameById(attrRefId)
    self:SetWndText(AttrNameTrans,attrName)

    local value = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId,attrType,attrNum)
    self:SetWndText(AttrValueTrans,value)
end

function UIGolemInfoTip:OnClickShareBtnFunc()
    local golemData = self._golemData
    if not golemData then return end
    local golemDataStr = gModelGolem:ServerDataChangeToShareData(golemData)
    local data = {
        root = self.mShareBtn,
        shareType = ModelChat.CHAT_SHARE_36,
        shareData = golemDataStr
    }
    gModelGeneral:OpenShareTip(data)
end

function UIGolemInfoTip:RefreshView()
    self:RefreshTop()
    self:RefreshAttrShow()
    self:RefreshSuitShow()

    local viewType = self._viewType
    local showItem = viewType == UIGolemInfoTip.VIEW_TYPE_COMMON
    CS.ShowObject(self.mDaoJuGolemDiv,showItem)
    CS.ShowObject(self.mDaoJuJumpDiv,showItem)
    CS.ShowObject(self.mShowAttrDiv,not showItem)
    CS.ShowObject(self.mSuitEffDiv,not showItem)

    local showAttrPre = false
    local showIntensifyBtnDiv = false
    if viewType == UIGolemInfoTip.VIEW_TYPE_HEROWEAR then
        showIntensifyBtnDiv = true
        self:RefreshHeroWearShow()
        showAttrPre = true
    elseif viewType == UIGolemInfoTip.VIEW_TYPE_OTHER then
        self:RefreshOtherShow()
        showAttrPre = true
    elseif viewType == UIGolemInfoTip.VIEW_TYPE_BAG then
        showIntensifyBtnDiv = true
        self:RefreshBagShow()
        showAttrPre = true
    elseif viewType == UIGolemInfoTip.VIEW_TYPE_COMMON then
        self:RefreshCommonShow()
        showAttrPre = true
    end
    if showAttrPre then
        self:CreateAttrPreViewDiv(self.mPrimeAttrPreViewDiv,{
            desc = ccClientText(34842),
            attrType = ModelGolem.GOLEM_DIV_ATTR_PRIME,
        })

        self:CreateAttrPreViewDiv(self.mDeputyAttrPreViewDiv,{
            desc = ccClientText(34842),
            attrType = ModelGolem.GOLEM_DIV_ATTR_DEPUTY,
        })
    end
    CS.ShowObject(self.mPrimeAttrPreViewDiv,showAttrPre)
    CS.ShowObject(self.mDeputyAttrPreViewDiv,showAttrPre)

    CS.ShowObject(self.mIntensifyBtnDiv,false)
    if showIntensifyBtnDiv then
        local botBtnCodeList = {}
        local functionId = UIGolemInfoTip.RECASTBTN_FUNCTIONOPEN
        local golemInfo = self._golemData
        if golemInfo then
            local golemStar = gModelGolem:GetGolemElementStarByGolemInfo(golemInfo)
            local golemStars = gModelGolem:GetGolemStars()
            if golemStar >= golemStars then
                local isShow = gModelFunctionOpen:CheckIsShow(functionId)
                --local  isOpen = gModelFunctionOpen:CheckIsOpened(functionId)
                --if not isOpen then
                --    isIns = gModelFunctionOpen:GetIsShowStatus(functionId)
                --end
                if isShow then
                    table.insert(botBtnCodeList,UIGolemInfoTip.RECASTBTN_CODE)
                end
            end
        end
--[[        if gModelFunctionOpen:CheckIsOpened(functionId) then
            local golemInfo = self._golemData
            if golemInfo then
                local golemStar = gModelGolem:GetGolemElementStarByGolemInfo(golemInfo)
                local golemStars = gModelGolem:GetGolemStars()
                if golemStar >= golemStars then
                    table.insert(botBtnCodeList,1033)
                end
            end
        end]]
        table.insert(botBtnCodeList,1037)
        local list =  self:GetOriginConfigList(botBtnCodeList)
        self:InitShowAttrBtnList(list)
    end
    CS.ShowObject(self.mShowAttrBtnList,showIntensifyBtnDiv)
end

function UIGolemInfoTip:RefreshBagShow()
    CS.ShowObject(self.mShareBtn,true)
    self:RefreshLockStatus(true)
    CS.ShowObject(self.mTopBtnList,true)

    self:ShowBotBtnDiv(true)
    CS.ShowObject(self.mWearStatus,false)
    local botBtnCodeList = {1040,1039}
    local list =  self:GetOriginConfigList(botBtnCodeList)
    self:InitBotBtnList(list)
end

function UIGolemInfoTip:OnDrawBotBtnCell(list,item,itemdata,itempos)
    local BtnTrans = self:FindWndTrans(item,"Btn")
    local redPointTrans = self:FindWndTrans(item,"redPoint")
    local name = ccLngText(itemdata.name)
    local btnIcon = itemdata.btnIcon

    -- local outLineRes = LUtil.GetOutlineMatByImg(btnIcon)
    -- self:SetWndButtonTextMat(BtnTrans,outLineRes)
    self:SetWndButtonImg(BtnTrans,btnIcon)
    self:SetWndButtonText(BtnTrans,name)

    local isGray = false
    local code = itemdata.code
    if code == UIGolemInfoTip.RECASTBTN_CODE then
        isGray = not gModelFunctionOpen:CheckIsOpened(UIGolemInfoTip.RECASTBTN_FUNCTIONOPEN)
        --if not gModelFunctionOpen:CheckIsOpened(UIGolemInfoTip.RECASTBTN_FUNCTIONOPEN) then
        --    if gModelFunctionOpen:GetIsShowStatus(UIGolemInfoTip.RECASTBTN_FUNCTIONOPEN) then
        --        isGray = true
        --    end
        --end
    end
    self:SetWndButtonGray(BtnTrans,isGray)
    if itemdata.code == 1037 then
        CS.ShowObject(redPointTrans,self._showRedPoint)
    end
    self:SetWndClick(BtnTrans,function()
        self:OnClickBotBtnFunc(itemdata)
    end)
end

function UIGolemInfoTip:OnClickGoloemBack()
    local id = self._golemData.id
    local golemData = gModelGolem:GetGolemServerDataById(id)
    if not golemData then
        return
    end

    if gModelGolem:IsStrengthed(id) then

        if golemData.isLock then
            local para = {
                refId = 310029,
            }
            gModelGeneral:OpenUIOrdinTips(para)
            return
        end
        local params = {
            golemInfo = golemData,
            golemId = id,
            heroServerData = self._heroServerData,
            page = 2
        }
        GF.OpenWnd("UIGolemMainWin",params)
        self:WndClose()
    else
        local totalExp = golemData.exp
        if totalExp == 0 then
            local str =ccClientText(34848)-- "当前魔偶未被强化无法回退"
            GF.ShowMessage(str)
        end
    end
end

------------------------- List -------------------------
function UIGolemInfoTip:InitPrimeAttrList(list)
    local uiPrimeAttrList = self._uiPrimeAttrList
    if uiPrimeAttrList then
        uiPrimeAttrList:RefreshList(list)
    else
        uiPrimeAttrList = self:GetUIScroll("uiPrimeAttrList")
        self._uiPrimeAttrList = uiPrimeAttrList
        uiPrimeAttrList:Create(self.mPrimeAttrList,list,function(...) self:OnDrawCommonAttrCell(...) end)
    end
end

function UIGolemInfoTip:ShowBotBtnDiv(show)
    CS.ShowObject(self.mBotBtnDiv,show)
    CS.ShowObject(self.mTipBg2,show)
    CS.ShowObject(self.mTipBg3,not show)
end

function UIGolemInfoTip:OnGolemLockResp(pb)
    local viewType = self._viewType
    if viewType == UIGolemInfoTip.VIEW_TYPE_HEROWEAR or viewType == UIGolemInfoTip.VIEW_TYPE_BAG then
        self:RefreshLockStatus(true)
    end
end

function UIGolemInfoTip:InitJumpList(list)
    local uiJumpList = self._uiJumpList
    if uiJumpList then
        uiJumpList:RefreshList(list)
    else
        uiJumpList = self:GetUIScroll("uiJumpList")
        self._uiJumpList = uiJumpList
        uiJumpList:Create(self.mJumpList,list,function(...) self:OnDrawJumpCell(...) end)
    end

end
------------------------------------------------------------------
return UIGolemInfoTip


