---
--- Created by LCM.
--- DateTime: 2024/3/28 15:49:10
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActFB:LWnd
local UIActFB = LxWndClass("UIActFB", LWnd)

UIActFB.LIST_NUM = 3
UIActFB.GET_REWARD_STATUS = 2            --- 1:点击链接，2:领取奖励
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActFB:UIActFB()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActFB:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActFB:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActFB:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:SetWndText(self.mCloseTip, ccClientText(10103))
    self:InitEvent()
    self:InitMsg()
    self:InitData()
    gModelActivity:ReqActivityConfigData(self._sid)

    gModelActivity:SetFbOpenClickTime(GetTimestamp())
end

function UIActFB:SetLinkLBgHeight(maxNum)
    local height = maxNum <= 3 and 623 or 771

    LxUiHelper.SetSizeWithCurAnchor(self.mListBg, 1, height)
end

function UIActFB:InitData()
    self._sid = self:GetWndArg("sid")
    if not self._sid then
        local subpage= self:GetWndArg("subPage") --支持跳转
        if subpage and subpage > 0 then
            self._sid = gModelActivity:GetSidByUniqueJump(subpage)
        end
    end
    self._effName = "fx_ui_qiandao_lingqutishi"
end
------------------------- List -------------------------

function UIActFB:RefreshLinkList()
    local list = self._dataList or {}
    local maxNum = #list
    local uiLinkList = self._uiLinkList
    if uiLinkList then
        uiLinkList:RefreshList(list)
    else
        uiLinkList = self:GetUIScroll("uiLinkList")
        self._uiLinkList = uiLinkList
        uiLinkList:Create(self.mLinkList, list, function(...)
            self:OnDrawLinkCell(...)
        end)
        uiLinkList:EnableScroll(maxNum >= 4, false)
    end

    self:SetLinkLBgHeight(maxNum)
end

function UIActFB:OnActivityConfigData(data, sid)
    if sid ~= self._sid then
        return
    end
    local activityWebData = gModelActivity:GetWebActivityDataById(self._sid)
    if not activityWebData then
        return
    end

    local activityData = gModelActivity:GetActivityBySid(self._sid)
    if not activityData then
        return
    end

    local activityMoreInfo = JSON.decode(activityData.moreInfo)
    self._receiveList = {}

    local config = activityWebData.config

    local image = config.image
    if LxUiHelper.IsImgPathValid(image) then
        self:SetWndEasyImage(self.mBg, image, function()
            CS.ShowObject(self.mBg, true)
        end)
    end

    local list = {}

    local linkKey = "link"
    local titleTxtKey = "titleTxt"
    local btnKey = "btn"
    local btnTextKey = "btnText"
    local rewardKey = "reward"
    local titleTxtImageKey = "titleTxtImage"
    local receiveKey = "receive"

    local linkName
    local titleTxtName
    local btnIconName
    local btnTextName
    local rewardName
    local titleTxtImageName
    local receiveName
    local listNum = config.listNum or UIActFB.LIST_NUM
    for i = 1, listNum do
        linkName = linkKey .. i
        titleTxtName = titleTxtKey .. i
        btnIconName = btnKey .. i
        btnTextName = btnTextKey .. i
        rewardName = rewardKey .. i

        --服务器使用的名字  分享的奖励做额外的处理
        if i == 3 then
            rewardName = "daily1"
        end

        titleTxtImageName = titleTxtImageKey .. i

        if i==3 then
            receiveName = "daily1"
        else
            receiveName = receiveKey .. i

        end
        local itemList = LUtil.ConvertCommonItemStrToList(config[rewardName])
        local itemData = {}

        for k, v in ipairs(itemList) do
            local curData = {
                itemType = v.itemType,
                itemId = v.itemId,
                itemNum = v.itemNum,
                dataIndex = i,
                rewardName = rewardName,
            }

            table.insert(itemData, curData)
        end

        table.insert(list, {
            linkName = linkName,
            rewardName = rewardName,
            linkKey = config[linkName],
            titleTxtKey = config[titleTxtName],
            btnText = config[btnTextName],
            btnKey = config[btnIconName],
            rewardKey = itemData,
            titleTxtImageKey = config[titleTxtImageName],
        })

        self._receiveList[i] = activityMoreInfo[receiveName] or false
    end

    self._dataList = list

    self:RefreshLinkList()
end

function UIActFB:OnClickLinkBtnFunc(itemdata, dataIndex)
    --[[	local args = "1_"..itemdata.linkName
        if UIActFB.GET_REWARD_STATUS == 1 then
            args = "1_"..itemdata.linkName
        else
            args = "2_" .. itemdata.rewardName
        end]]

    if not self._receiveList[dataIndex] then
        gModelActivity:SetFBRewardCanGetList(self._sid, dataIndex, true)
        self:RefreshLinkList()
    end

    if dataIndex == 3 then
        --调用分享
        local shareData = {}
        shareData.forType = LShareConst.SHARE_TY_URL
        shareData.shareParam1 = itemdata.linkKey--ccClientText(14013)
        shareData.shareScene = LShareConst.SCENE_MADFUN
        shareData.shareLocation = "ActivityFB"
        gLSdkImpl:CallMethod(LSdkMethod.Share, shareData)
    else
        CS.UApplication.OpenURL(itemdata.linkKey)
    end
end

function UIActFB:OnActivityPageResp(pb)
    if self._sid ~= pb.sid then
        return
    end
end

function UIActFB:InitRewardList(trans, list)
    local key = trans:GetInstanceID()
    local uiRewardList = self:FindUIScroll(key)
    if uiRewardList then
        uiRewardList:RefreshList(list)
    else
        uiRewardList = self:GetUIScroll(key)
        uiRewardList:Create(trans, list, function(...)
            self:OnDrawRewardCell(...)
        end)
    end
    uiRewardList:EnableScroll(#list > 4, true)
end

function UIActFB:OnDrawLinkCell(list, item, itemdata, itempos)
    local BtnImgTrans = self:FindWndTrans(item, "BtnImg")
    local TitleBg = self:FindWndTrans(item, "TitleBg")
    local TitleNameTrans = self:FindWndTrans(TitleBg, "TitleName")
    local TitleImgTrans = self:FindWndTrans(TitleBg, "TitleImg")
    local RewardListTrans = self:FindWndTrans(item, "RewardList")

    self:SetWndEasyImage(BtnImgTrans, itemdata.btnKey, function()
        CS.ShowObject(BtnImgTrans, true)
    end, true)

    self:SetTextTile(BtnImgTrans, itemdata.btnText)
    self:SetWndText(TitleNameTrans, itemdata.titleTxtKey)

    local titleTxtImageKey = itemdata.titleTxtImageKey
    --local showTitleTxtImg = LxUiHelper.IsImgPathValid(titleTxtImageKey)
    --if showTitleTxtImg then
    --	CS.ShowObject(TitleNameTrans,false)
    --	self:SetWndEasyImage(TitleImgTrans,titleTxtImageKey,function()
    --		CS.ShowObject(TitleImgTrans,true)
    --	end, true)
    --else
    --	CS.ShowObject(TitleImgTrans,false)
    --	CS.ShowObject(TitleNameTrans,true)
    --end

    self:InitRewardList(RewardListTrans, itemdata.rewardKey)

    self:SetWndClick(BtnImgTrans, function()
        self:OnClickLinkBtnFunc(itemdata, itempos)
    end)
end

function UIActFB:InitMsg()

    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
        self:OnActivityConfigData(...)
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityResp, function(pb)
        self:OnActivityResp(pb)
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
        self:OnActivityPageResp(pb)
    end)

    -- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
    -- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UIActFB:OnDrawRewardCell(list, item, itemdata, itempos)
    local dataIndex = itemdata.dataIndex
    local isReceive = self._receiveList[dataIndex]
    local canGet = gModelActivity:GetFBRewardCanGetList(self._sid, dataIndex)

    local CommonUITrans = self:FindWndTrans(item, "CommonUI")
    local IconTrans = self:FindWndTrans(CommonUITrans, "Icon")
    local effTrans = self:FindWndTrans(item, "Eff")
    self:SetIconClickScale(IconTrans, true)
    local instanceID = item:GetInstanceID()
    local baseClass = self:GetCommonIcon(instanceID)
    baseClass:Create(IconTrans)
    baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
    baseClass:SetShowGouImg(isReceive)
    baseClass:DoApply()

    local showEff = canGet  and (not isReceive)
    if showEff then
        --第一次完成时显示特效
        local effectName = self._effName
        self:CreateWndEffect(effTrans, effectName, instanceID, 80, false, false)
    end

    CS.ShowObject(effTrans, showEff)

    self:SetWndClick(IconTrans, function()
        if canGet then
            self:GetActivityReward(itemdata, dataIndex)
        else
            gModelGeneral:ShowCommonItemTipWnd(itemdata)
        end
    end)
end

function UIActFB:OnActivityResp(pb)
    if self._sid ~= pb.sid then
        return
    end
end

function UIActFB:GetActivityReward(itemdata, dataIndex)
    gModelActivity:OnActivitySpecialOpReq(self._sid, nil, nil, nil, itemdata.rewardName, ModelActivity.FB_GROUP_OP)
    self._receiveList[dataIndex] = true
    gModelActivity:SetFBRewardCanGetList(self._sid, dataIndex, false)
    self:RefreshLinkList()
end

function UIActFB:InitEvent()
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
end


------------------------- List -------------------------

------------------------------------------------------------------
return UIActFB



