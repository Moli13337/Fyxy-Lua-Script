---
--- Created by Administrator.
--- DateTime: 2025/7/14 14:55:31
---
------------------------------------------------------------------
local YXTouchManager = CS.YXTouchManager
local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder
local typeXUIText = typeof(CS.YXUIText)
local LWnd = LWnd
---@class UIGameBzerNew:LWnd
local UIGameBzerNew = LxWndClass("UIGameBzerNew", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGameBzerNew:UIGameBzerNew()
    self.cloneObjList = {}
    self.curSpeed = math.max(gModelGameHelper:GetGameSpeed(),1)
    self.rotations = {-42.7,-21.35,0,21.35,42.7}--1-5
end
------------------------------------------------------------------
function UIGameBzerNew:OnWndClose()
    LWnd.OnWndClose(self)
    if gLGameTouch then
        gLGameTouch:TouchUnRegister(LGameTouch.TOUCH_UI)
    end 
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGameBzerNew:OnCreate()
    LWnd.OnCreate(self)
    return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGameBzerNew:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    if self._isEnus then 
        self:SetAnchorPos(self.mSpeedText,Vector2.New(50,16))
        self:SetAnchorPos(self.mHelpBtn,Vector2.New(20,2))
    end
    self.jpj = gLGameLanguage:IsJapanVersion()
    if self.jpj then
        self:SetAnchorPos(self.mHelpBtn,Vector2.New(20,2))
    end
    if not gModelGameHelper:IsInitDoList() then
        gModelGameHelper:InitDoList()
    end
    self:InitCommon()
    self:OnWndRefresh()
    self:UpdateEffect()

    gModelGameHelper:GameHelperSettingReq(1)
    self:InitTouchEvent()
    
end
function UIGameBzerNew:SetRotation(curZ)
    self.mRotationObj.localEulerAngles = Vector3.New(0, 0,curZ);
    self.mTxtMultiple1.localEulerAngles = Vector3.New(0, 0, -curZ);
    self.mTxtMultiple2.localEulerAngles = Vector3.New(0, 0, -curZ);
    self.mTxtMultiple3.localEulerAngles = Vector3.New(0, 0, -curZ);
    self.mTxtMultiple4.localEulerAngles = Vector3.New(0, 0, -curZ);
    self.mTxtMultiple5.localEulerAngles = Vector3.New(0, 0, -curZ);
end
function UIGameBzerNew:ResetRotation()
    local rotations = self.rotations
    local oldInx = self.curSpeed
    local trans = self["mTxtMultiple"..oldInx]-- self.mRotationObj:GetChild(oldInx-1)
    if trans then
        local color = LUtil.ColorByHex_6("7ab1e4")
        self:SetXUITextColor(trans:GetComponent(typeXUIText),color)
    end
    local diffVal = self.rotations[1]-self.rotations[2]
    local num = rotations[oldInx] - self.addRota
    local tem = math.abs(num%diffVal) > 9 --除余-多余滑动距离（>10就向上取整，否则向下取整）
    local indx = (tem and math.ceil(num/diffVal) or math.floor(num/diffVal)) + self.curSpeed
    indx = indx<0 and 1 or (indx>5 and 5 or indx)

    self.curSpeed = indx
    gModelGameHelper:SetGameSpeed(indx)

    trans = self["mTxtMultiple"..self.curSpeed]--self.mRotationObj:GetChild(self.curSpeed-1)
    if trans then
        local color = LUtil.ColorByHex_6("1b62a3")
        self:SetXUITextColor(trans:GetComponent(typeXUIText),color)
    end

    local duration = 0.3
    local seqcom = self:GetSeqCom()
    local seq = seqcom:CreateSeq("movePosition")
    local curPos = self.addRota
    local endPos = rotations[indx]
    local tween = YXTween.TweenFloat(curPos, endPos, duration, function(t)
        self:SetRotation(t)
    end)
    seq:Append(tween)
    seq:PlayForward()
    self:UpdateEffect()
end

function UIGameBzerNew:MoreBoxSel(ref,boxMap)
    local more = ""
    local selList = {}
    for key, value in pairs(boxMap) do
       if value then
            table.insert(selList,key)
       end
    end
    table.sort(selList,function(a,b) return a<b end)
    for indx, value in ipairs(selList) do
        if indx ==1 then
            more = value..more
        else
            more = more.."|"..value
        end
    end
    self:ClickBoxSel(ref,nil,more)
end
function UIGameBzerNew:GetFuncTemplateObj(ref,parent)
	local obj
    local type = tonumber(ref.functionType)
	local desd = string.split(ccLngText(ref.desd),"|")
    local ItemTitle
    local itemCache
	if type ==1 or type == 5 then--开关类型
		obj = CS.InstantObject(self.mOnOffTemplate)
		ItemTitle = CS.FindTrans(obj.transform,"ItemTitle")
		local TxtDesc = CS.FindTrans(obj.transform,"TxtDesc")
		local BoxBg = CS.FindTrans(obj.transform,"BoxBg")
		local BoxSel = CS.FindTrans(obj.transform,"BoxSel")
        itemCache ={
            item = obj.transform,
            itemTitle = ItemTitle,
            onOffDesc = TxtDesc,
            boxBg = BoxBg,
            boxSel = BoxSel
        }
	elseif type==2 or type ==3 then--单选-多选项
		obj = CS.InstantObject(self.mChoiceTemplate)
		local boxs = CS.FindTrans(obj.transform,"Boxs")
		ItemTitle = CS.FindTrans(obj.transform,"ItemTitle")
		local FuncTitle = CS.FindTrans(obj.transform,"FuncTitle")
        itemCache = {
            item = obj.transform,
            boxs = boxs,
            itemTitle = ItemTitle,
            funcTitle = FuncTitle,
        }
		local options = string.split(desd[2],"=")
		for indx, txt in ipairs(options) do
			local box = CS.InstantObject(self.mBoxTemplate)
            CS.ShowObject(box.transform,true)
			box.transform:SetParent(boxs.transform,false)
            itemCache["box"..indx] = box.transform
        end
    elseif type==4 then--消耗类型
        obj = CS.InstantObject(self.mCostTemplate)
        ItemTitle = CS.FindTrans(obj.transform,"ItemTitle")
        local FuncTitle = CS.FindTrans(obj.transform,"FuncTitle")
        local TxtTip = CS.FindTrans(obj.transform,"TxtTip")
        local CostNum = CS.FindTrans(obj.transform,"CostNum")
        local CostTitle = CS.FindTrans(obj.transform,"CostNum/CostTitle")
        local CostIcon = CS.FindTrans(obj.transform,"CostNum/CostIcon")
        local NumObj = CS.FindTrans(obj.transform,"NumObj")
        local Sub = CS.FindTrans(NumObj,"Sub")
        local Add = CS.FindTrans(NumObj,"Add")
        local DiamondNum = CS.FindTrans(NumObj,"DiamondNum")
        itemCache = {
            item = obj.transform,
            itemTitle = ItemTitle,
            funcTitle = FuncTitle,
            txtTip = TxtTip,
            costNum = CostNum,
            costIcon = CostIcon,
            costTitle = CostTitle,
            numObj = NumObj,
            sub = Sub,
            add = Add,
            diamondNum = DiamondNum,
        }
    elseif type == 5 then--全选
        obj = CS.InstantObject(self.mBoxTemplate)
        local BoxBg = CS.FindTrans(obj.transform,"BoxBg")
        local BoxSel = CS.FindTrans(obj.transform,"BoxSel")
        itemCache = {
            item = obj.transform,
            boxBg = BoxBg,
            boxSel = BoxSel,
        }
    end
    if ItemTitle then self:SetWndText(ItemTitle,ccLngText(ref.name)) end
    if obj then
        CS.ShowObject(obj.transform,true )
        obj.transform:SetParent(parent,false)
        LayoutRebuilder.ForceRebuildLayoutImmediate(obj.transform)

        if not self.cloneObjList[type] then
            self.cloneObjList[type] = {}
        end
        table.insert(self.cloneObjList[type],obj)
        return itemCache
	end
end

function UIGameBzerNew:OnWndRefresh()
    -- self:RefreshTop()
end

function UIGameBzerNew:InitCommon()
    ------------------------------------------------------------------
    ---click
    self:SetWndClick(self.mReturnBtn, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mStartBtn, function()
        local openId = GameTable.AssistantConfig.helperLighteningOpen
        local isOpen = gModelFunctionOpen:CheckIsOpened(openId, true)
        if not isOpen then
            --return
        end

        local refIds = {}
        for refId, b in pairs(self.doList) do
            if b == true then
                table.insert(refIds, refId)
            end
        end
        if #refIds > 0 then
            gModelGameHelper:GameHelperExecuteReq(refIds)
        else
            GF.ShowMessage(ccClientText(24245))
        end
    end)

    ------------------------------------------------------------------
    ---text
    self:SetWndText(self.mTxtReturn, ccClientText(20723))
    self:SetWndText(self.mTitleText, ccClientText(24203))--标题
    self:SetWndButtonText(self.mStartBtn, ccClientText(24227))

    ------------------------------------------------------------------
    ---order
    self:InitSpeed()
    local openId = GameTable.AssistantConfig.helperLighteningOpen
    local showStartBtn = true
    if openId and openId > 0 then
        showStartBtn = gModelFunctionOpen:CheckIsShow(openId)
    end
    CS.ShowObject(self.mTabList, showStartBtn)
    CS.ShowObject(self.mStartBtn, showStartBtn)
    CS.ShowObject(self.mListBg, showStartBtn)
    CS.ShowObject(self.mListBg, showStartBtn)
    CS.ShowObject(self.mTxtDesc, showStartBtn)
    local pos = self.mRotationCenter.anchoredPosition
    pos.x = showStartBtn and 50 or 0
    self.mRotationCenter.anchoredPosition = pos
    -- local s = gModelFunctionOpen:GetOpenTips(openId)
    -- self:SetTextTile(self.mUnOpen, s)
    self:SetWndText(self.mTxtDesc,ccClientText(24275))
    ------------------------------------------------------------------
    ---event
    self:WndEventRecv("GameHelperSettingResp", function()
        if not self.initTab then
            self:InitTab()
            self.initTab = true
        else
            self:ClickTabBtn(self.curSelect)
        end
	end)

    ------------------------------------------------------------------
    ---resp
    self:WndNetMsgRecv(LProtoIds.GameHelperExecuteResp, function(pb)
        if pb.syncType == 1 then
            GF.OpenWnd("UIGameBzerDoNew", { pb = pb })
        end
	end)
end
function UIGameBzerNew:DrawTemplate(_, trans, data)
	local listRefId = tonumber(data)
	local listRef = GameTable.AssistantListRef[listRefId]
	local funcList = gModelGameHelperAlleviation:GetLighteningHelperFunctionListByTabId(listRefId)
    table.sort(funcList,function(a,b) return a.refId<b.refId end)
	local instanceID = trans:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			trans = trans,
			title = CS.FindTrans(trans,"ListTitle"),
			btnHelp = CS.FindTrans(trans,"ListTitle/BtnHelp"),
		}
		self:SetComponentCache(instanceID, itemCache)
		if funcList then
            local key = nil
			for _, ref in ipairs(funcList) do
                key = listRefId..ref.refId
				itemCache[key] = self:GetFuncTemplateObj(ref,trans)
			end
		end
	end
    self:SetTextTile(itemCache.title,ccLngText(listRef.name))
    CS.ShowObject(itemCache.btnHelp,not string.isempty(listRef.helpTips))
    self:SetWndClick(itemCache.btnHelp,function()
        GF.OpenWnd("UIBzTips",{refId = tonumber(listRef.helpTips)})
    end)
    if funcList then
        local desd
        local key
        local type = 0
        local setting
        local defualtVal = {}
        for _, ref in ipairs(funcList) do
            type = tonumber(ref.functionType)
            desd = string.split(ccLngText(ref.desd),"|")
            defualtVal = string.split(ref.functionDetails,"|")
            key = listRefId..ref.refId
            local childItemCache = itemCache[key]
            setting = gModelGameHelper:GetSettingById(ref.refId)
            self:SetWndText(childItemCache.itemTitle,ccLngText(ref.name))
            if type == 1 then --1类型  parameter1:0=关闭 1=开启
                self:SetWndText(childItemCache.onOffDesc,desd[1])
                local color = setting.parameter1>0 and "#019404" or "#234770"
                self:SetTextTile(childItemCache.item,string.replace(ccClientText(24278),color, desd[2]))
                local boxSel = childItemCache.boxSel
                CS.ShowObject(boxSel,setting.parameter1>0)
                self:SetWndClick(childItemCache.boxBg,function()
                    self:ClickBoxSel(ref)
                end)
            elseif type ==2 then--2类型 parameter1:0=不选择 其余数字=代表其他选择
                self:SetWndText(childItemCache.funcTitle,desd[1])
                local options = string.split(desd[2],"=")
                local showDatas = setting.clienShowData
                local box = nil
                for index, value in ipairs(options) do
                    box = childItemCache["box"..index]
                    local BoxBg = CS.FindTrans(box.transform,"BoxBg")
                    local BoxSel = CS.FindTrans(box.transform,"BoxSel")
                    local condi = "" ---不區分功能
                    if showDatas and showDatas[index] and not showDatas[index].isOpen then
                        condi = ccClientText(24274)
                    end
                    local color = setting.parameter1 == index  and "#019404" or "#234770"
                    value = string.replace(ccClientText(24278),color,value)
                    self:SetTextTile(box,value..condi)
                    CS.ShowObject(BoxSel,setting.parameter1==index)
                    self:SetWndClick(BoxBg,function()
                        if showDatas then
                            if showDatas[index].isOpen then
                                self:ClickBoxSel(ref,index)
                            end
                        else
                            self:ClickBoxSel(ref,index)
                        end

                    end)
                end
            elseif type ==3 then --类型3 parameter1没有意义，多选数据在moreInfo
                self:SetWndText(childItemCache.funcTitle,desd[1])
                local options = string.split(desd[2],"=")
                local typeOptions = string.split(ref.additionalData,"|")
                local typeLeng = #typeOptions
                local box = nil
                local boxInfo = string.split(setting.moreInfo,"|")
                local boxMap = {}
                for _, value in ipairs(boxInfo) do
                    boxMap[tonumber(value)] = true
                end
                local showDatas = setting.clienShowData
                if typeLeng>0 then--通过addtionalData索引
                    local showDataMap = {}
                    if showDatas then
                        for _, value in ipairs(showDatas) do
                            showDataMap[value.type] = value
                        end
                    end
                    showDatas = showDataMap
                end
                for index, value in ipairs(options) do
                    local showDat = typeLeng>=index and showDatas[tonumber(typeOptions[index])] or showDatas[index]
                    local isOpen = showDat and showDat.isOpen
                    box = childItemCache["box"..index]
                    local BoxBg = CS.FindTrans(box.transform,"BoxBg")
                    local BoxSel = CS.FindTrans(box.transform,"BoxSel")
                    local isSel = (boxMap[typeLeng>=index and tonumber(typeOptions[index] or index)])
                    CS.ShowObject(BoxSel,isSel and isOpen)
                    local condi = ""
                    local titleCol = "#234770"
                    if not isOpen then
                        condi = ccClientText(24274)
                        titleCol = "#616B76"
                    elseif showDat and showDat.remainCount and showDat.remainCount <= 0 and showDat.maxCount>=0 then
                        titleCol = "#616B76"
                        condi = ccClientText(24276)
                    end
                    if isSel and isOpen then titleCol = "#019404" end
                    value = string.replace(ccClientText(24278),titleCol,value)
                    self:SetTextTile(box,value..condi)
                    self:SetWndClick(BoxBg,function()
                        if not isOpen then return end
                        if isSel then
                            boxMap[typeLeng>=index and tonumber(typeOptions[index] or index)] = false
                        else
                            boxMap[typeLeng>=index and tonumber(typeOptions[index] or index)] = true
                        end
                        self:MoreBoxSel(ref,boxMap)
                    end)
                end
            elseif type == 4 then
                local clienData= setting.clienShowData
                local refId = ref.refId
                local diamondNum = childItemCache.diamondNum
                self:SetWndText(childItemCache.funcTitle,desd[1])
                local str = string.split(desd[2],"=")
                local remainCount = clienData and clienData.remainCount or 0
                local maxCount = clienData and clienData.maxCount or 0
                local tipStr = string.replace(str[1],remainCount,maxCount == 0 and "" or maxCount)
                local finishCount = maxCount - remainCount
                local curNum = setting.parameter1 or 0
                local buyNeed = self:GetPayItemByType4(refId,listRefId,clienData,curNum,finishCount)
                local specialShow = false
                local selMaxNum = 0
                local costIcon
                if refId == 1053 then
                    costIcon = gModelItem:GetItemIconByRefId(100120)
                    buyNeed.itemNum = 1
                elseif refId == 1093 then
                    costIcon = gModelItem:GetItemIconByRefId(buyNeed.itemId)
                    if remainCount > 0 then
                        buyNeed.itemNum = 0
                    else
                        specialShow = true
                        selMaxNum = gModelItem:GetNumByRefId(buyNeed.itemId)
                    end
                else
                    costIcon = gModelItem:GetItemIconByRefId(buyNeed.itemId)
                end
                if costIcon then
                    self:SetWndEasyImage(childItemCache.costIcon,costIcon)
                end
                local costNum = 0
                if specialShow then
                    costNum = curNum
                elseif listRefId == 110  then
                    costNum = buyNeed.itemNum
                else
                    costNum = refId == 1072 and self:GetCost107(curNum) or buyNeed.itemNum * curNum
                end
                CS.ShowObject(childItemCache.costNum,(#str>1 and tonumber(str[2]) >0) and true or false)
                self:SetWndText(childItemCache.txtTip,tipStr)
                self:SetWndText(childItemCache.costTitle,ccClientText(11654))
                self:SetWndText(childItemCache.costNum,costNum)
                self:SetWndText(diamondNum,curNum)
                local bGray = false
                if specialShow then
                    bGray = costNum >= selMaxNum
                else
                    bGray = remainCount <= 0 or curNum >= remainCount
                end
                self:SetWndImageGray(childItemCache.add,bGray)
                self:SetWndClick(childItemCache.add,function ()
                    if specialShow then
                        if curNum >= selMaxNum then return end

                        curNum = curNum + 1
                    else
                        if remainCount <= 0 then return end

                        curNum = math.min(remainCount,curNum + 1)
                        if listRefId == 110 then
                            costNum = buyNeed.itemNum
                        else
                            costNum = ref.refId == 1072 and self:GetCost107(curNum) or buyNeed.itemNum * curNum
                        end
                    end
                    self:SetWndText(diamondNum,curNum)
                    self:SetWndText(childItemCache.costNum,costNum)
                    self:ClickBoxSel(ref,curNum)
                end)
                self:SetWndClick(childItemCache.sub,function ()
                    if curNum-1<0 then return end
                    curNum = math.max(curNum-1,0)
                    if listRefId == 110 then
                        costNum = buyNeed.itemNum
                    else
                        costNum = ref.refId == 1072 and self:GetCost107(curNum) or buyNeed.itemNum * curNum
                    end
                    self:SetWndText(diamondNum,curNum)
                    self:SetWndText(childItemCache.costNum,costNum)
                    self:ClickBoxSel(ref,curNum)
                end)
                self:SetWndClick(childItemCache.numObj, function()
                    local func = function(input)
                        if self:IsWndClosed() then return end
                        costNum = ref.refId == 1072 and self:GetCost107(input) or buyNeed.itemNum*input
                        self:SetWndText(diamondNum,input)
                        self:SetWndText(childItemCache.costNum,costNum)
                    end
                    local closeFunc = function(input)
                        if self:IsWndClosed() then return end
                        self:ClickBoxSel(ref,input)
                    end
                    local maxNum = specialShow and selMaxNum or remainCount
                    local para = {
                        minNum = 0,
                        maxNum = maxNum,
                        defaultNum = 0,
                        inputFunc = func,
                        inputTran = childItemCache.numObj,
                        closeFunc = closeFunc
                    }
                    GF.OpenWnd("UINuoardUI", para)
                end)
            elseif type ==5 then
                self:SetTextTile(childItemCache.item,desd[1])
                self:SetWndClick(childItemCache.BoxBg,function()
                    CS.ShowObject(childItemCache.BoxSel,setting.parameter1~=1 and true )

                end)
            end
        end
    end

    LayoutRebuilder.ForceRebuildLayoutImmediate(trans)
end

function UIGameBzerNew:GetPayItemByType4(refId,listRefId,clienData,num,finishCount)
    if clienData then
        if listRefId == 112 or listRefId == 111 then
            --- BOSS鑽石挑戰
            local remainCount = clienData.remainCount
            local maxCount = clienData.maxCount
            local curIdx = maxCount - remainCount + 1
            local needStr = gModelGuildBoss:GetNewGuildDungeonConfigRefByKey("GuildBuyTimeNeed")
            local attrArry = string.split(needStr,"|")
            if curIdx > #attrArry then
                curIdx = #attrArry
            end
            local itemStr = attrArry[curIdx]
            return LxDataHelper.ParseItem_3(itemStr)
        elseif refId == 1093 then
            return {
                itemType = LItemTypeConst.TYPE_ITEM,
                itemId = gModelArena:GetArenaPara("TciketId"),
                itemNum = gModelArena:GetArenaPara("TicketNum"),
            }
        end
    end
    local isDonate = false
    local CfgIndex = 2
    if refId == 1101  then
        CfgIndex = 1
        isDonate = true
    elseif refId == 1102 then
        CfgIndex = 2
        isDonate = true
    elseif refId == 1103 then
        CfgIndex = 3
        isDonate = true
    end
    if isDonate then
        local list = gModelGuild:GetGuildDonateRefDataList()
        local basicsRef = list[CfgIndex]--默认钻石
        local priceArr = {}
        local refPrice = string.split(basicsRef.price, "|")
        for i, v in ipairs(refPrice) do
            local price = gModelGeneral:GetParseItem_3(v)
            table.insert(priceArr, price)
        end
        local len = #priceArr
        local price = num < len and priceArr[num] or priceArr[len]
        local TotalNum = 0
        local startIndex = finishCount + 1
        local index = 1
        for i = startIndex, len do
            if index <= num then
                local value = priceArr[i]
                TotalNum = TotalNum + value.itemNum
                index = index + 1
            end
        end
        local buyNeed = {
            itemType = LItemTypeConst.TYPE_ITEM,
            itemId = checknumber(price.itemId),
            itemNum = TotalNum,
        }
        if num == 0 then
            buyNeed.itemNum = 0
        end
        return buyNeed
    else
        local basicsRef = gModelGoldBuy:GetGoldBuyBasicsRefById(2)--默认钻石
        local buyNeeds = string.split(basicsRef.buyNeed,"=")
        return {
            itemType = LItemTypeConst.TYPE_ITEM,
            itemId = checknumber(buyNeeds[1]),
            itemNum = checknumber(buyNeeds[2]),
        }
    end

end

function UIGameBzerNew:UpdateEffect()
    if self.speedEffect then
        self.speedEffect:SetSpeed(self.curSpeed)
        return
    end
    local instanceId = self.mSpeedEffect:GetInstanceID()
	self.speedEffect = self:CreateWndEffect(self.mSpeedEffect,"fx_ui_jianfujiasu",instanceId,100,nil,nil,nil,nil,nil,nil,nil,function()
		self.speedEffect:SetSpeed(self.curSpeed)
	end)
end

function UIGameBzerNew:ApplySpeed()
    local funcId = GameTable.AssistantConfig["helperAccelerateOpen2"]
    if not gModelFunctionOpen:CheckIsOpened(funcId, true) then
        return
    end
    gModelGameHelper:ApplySpeed()
end
function UIGameBzerNew:ClickTabBtn(data)
    if not data or not data.func then  return end
    local lists = self:OnUpdateAllBox(data)
	if self.templateList then
        self.uiTabList:DrawAllItems()
        self.templateList:ResetList(lists)
        self.templateList:DrawAllItems()
	else
		self.templateList = self:GetUIScroll("SettingList")
		self.templateList:Create(self.mList, lists, function(...) self:DrawTemplate(...) end)
        self.templateList:EnableScroll(true)
	end
    local cfg = GameTable.AssistantTabRef[self.curSelect.id]
	------------------------------------------------------------------
	self:SetWndText(self.mTxtTitle, ccLngText(cfg.name) .. ccClientText(24228))
    CS.ShowObject(self.mRotationCenter,self.curSelect.id == 1)
end


------------------------------------------------------------------
--- ↑ 加速助手部分 ↑ ---
------------------------------------------------------------------

------------------------------------------------------------------
--- ↓ tab list ↓ ---
------------------------------------------------------------------
---WndchildGameHelper
function UIGameBzerNew:InitTab()
    self.doList = gModelGameHelper:GetDolist()

    self.tabList = gModelGameHelper:GetTabList()
    if self.uiTabList then
		self.uiTabList:ResetList(self.tabList)
		self.uiTabList:DrawAllItems()
	else
		self.uiTabList = self:GetUIScroll("tabList")
		self.uiTabList:Create(self.mTabList, self.tabList, function(...) self:DrawTab(...) end, UIItemList.SUPER)
	end
    self.curSelect = self.curSelect or self.tabList[1]
    self:ClickTabBtn(self.curSelect)

end
function UIGameBzerNew:OnUpdateAllBox(data)
    local allListId = 116--全部勾选
    local isAll = false
    local lists = {}
    for _, value in ipairs(data.func) do
        if tonumber(value) == allListId then
            isAll = true
        else
            table.insert(lists,value)
        end
    end
    CS.ShowObject(self.mBoxAll,isAll)
    if isAll then
        local listRef = GameTable.AssistantListRef[allListId]
        local funcList = gModelGameHelperAlleviation:GetLighteningHelperFunctionListByTabId(allListId)
        local data = funcList[1]
        if not data then return end
        local desd = ccLngText(data.desd)
        local setting = gModelGameHelper:GetSettingById(data.refId)
        CS.ShowObject(self.mBoxAllSel,setting.parameter1 and setting.parameter1>0)
        self:SetTextTile(self.mBoxAll,desd)
        self:SetWndClick(self.mBoxAllBg,function()
            -- if not gModelFunctionOpen:CheckIsOpened(listRef.open, true) then return end
            self:ClickBoxSel(data)
        end)
    end
    return lists
end

function UIGameBzerNew:ClickDoBtn(b, data)
    local key = data.id
    self.doList = gModelGameHelper:SetDoList(key, b)
    self.uiTabList:DrawAllItems()
end
function UIGameBzerNew:GetCost107(num)
    local cost = 0
	local guyNum = gModelTower:GetBuySweepNum()
	for i = 0, num do
		if i > 0 then
			local num = gModelTower:GetExpend(guyNum + i)
			cost = cost + num
		end
	end
	return cost
end

function UIGameBzerNew:InitTouchEvent()
    local maxValue = gModelGameHelper:GetUnLockMaxSpeed()
    local op = LGameTouch.TOUCH_UI
    local startX = 0
    local startRota = 0
    local addRota = 0
    local minVal = self.rotations[1]--[#self.rotations]
    local maxVal = self.rotations[maxValue]
    addRota = self.rotations[self.curSpeed]
    self.addRota = addRota
    self:SetRotation(addRota)
    gLGameTouch:TouchRegister(op,LGameTouch.TOUCH_EVT_START,function (screenPos)
        startX = screenPos.x
        startRota = self.mRotationObj.localEulerAngles.z
        self.startRota = startRota

        addRota = self.rotations[self.curSpeed]
        self.addRota = addRota
        self._startMousePos = screenPos
    end)
    gLGameTouch:TouchRegister(op,LGameTouch.TOUCH_EVT_MOVE,function (screenPos)
        local touchObject = YXTouchManager.EventSystemRaycastGameObject(screenPos)
        if touchObject then
            local path = LxUiHelper.GetRelativePath(self:GetWndName(),touchObject.transform)
            if string.find(path,"ImgMask") then
                local offset = self._startMousePos - screenPos
                print("offset:"..offset.x)
                self._startMousePos = screenPos
                local currentAngle = self.mRotationObj.localEulerAngles.z;
                local curZ
                local val = math.ceil(math.abs(offset.x/9))
                if startX>screenPos.x then --左
                    if addRota <= minVal then
                        addRota = minVal
                        return
                    end
                    curZ = currentAngle-val
                    addRota = addRota -val
                    self.addRota = addRota
                else--右
                    if addRota >= maxVal then
                        addRota = maxVal -- ?
                        return
                    end
                    curZ = currentAngle+val
                    addRota = addRota +val
                    self.addRota = addRota
                end
                self:SetRotation(curZ)
                startX = screenPos.x
            end
        end
    end)

    gLGameTouch:TouchRegister(op,LGameTouch.TOUCH_EVT_END,function (screenPos)
        self:ResetRotation()
        self._startMousePos = screenPos
    end)

    gLGameTouch:TouchRegister(op,LGameTouch.TOUCH_EVT_CANCEL,function (screenPos)
        self:ResetRotation()
        self._startMousePos = screenPos
    end)

    self:SetWndClick(self.mHelpBtn, function()
        GF.OpenWnd("UIBzTips", { refId = 104 })
    end)
end

function UIGameBzerNew:DrawTab(_, trans, data)
    local on = CS.FindTrans(trans, "On")
    local lock = CS.FindTrans(trans, "Lock")
    local Box = CS.FindTrans(trans, "Box")
    local BoxSel = CS.FindTrans(Box, "BoxSel")
    local select = CS.FindTrans(trans, "Selct")
    -- local name = CS.FindTrans(trans, "Name")
    -- self:SetWndText(name, ccLngText(data.name))
    -- CS.ShowObject(onNo, not self.doList[key])
    local isOpen = gModelFunctionOpen:CheckIsOpened(data.open)
    local key = data.id
    CS.ShowObject(Box, isOpen)
    CS.ShowObject(lock, not isOpen)
    CS.ShowObject(select, self.curSelect.id == data.id)
    CS.ShowObject(Box,data.id ~= 1 and isOpen)
    CS.ShowObject(BoxSel,data.id ~= 1 and self.doList[key])
    self:SetWndEasyImage(on,data.tabIcon)
    self:SetWndClick(on, function()
        if not gModelFunctionOpen:CheckIsOpened(data.open, true) then return end
        if self.curSelect.id == data.id then return end
        for _, list in pairs(self.cloneObjList) do
            for index, obj in ipairs(list) do
                obj.transform.parent = nil
                LxUnity.Destroy(obj)
            end
            list = nil
        end
        self.cloneObjList = {}
        self:ClearComponentCaches()
        self.curSelect = data
        self:ClickTabBtn(data)
    end)
    self:SetWndClick(BoxSel, function()
        self:ClickDoBtn(false, data)
    end)
    self:SetWndClick(Box, function()
        self:ClickDoBtn(true, data)
    end)
end

------------------------------------------------------------------
--- ↓ 加速助手部分 ↓ ---
------------------------------------------------------------------
function UIGameBzerNew:InitSpeed()
    ------------------------------------------------------------------
    ------------------------------------------------------------------
    ---text
    self:SetTextTile(self.mOnlyBattleTog, ccClientText(24214))

    ------------------------------------------------------------------
    ---toggle
    self:SetWndToggleValue(self.mOnlyBattleTog, gModelGameHelper:GetOnlyBattle())
    self:SetWndToggleDelegate(self.mOnlyBattleTog, function(value)
        gModelGameHelper:SetOnlyBattle(value)
    end)

    local maxValue = gModelGameHelper:GetUnLockMaxSpeed()
    for i = 1, 5 do
        local trans = self["mTxtMultiple"..i]--self.mRotationObj:GetChild(i-1)
        if trans then
            self:SetWndText(trans,string.replace(ccClientText(12343),i))
            local color = LUtil.ColorByHex_6(self.curSpeed==i and "1b62a3" or "7ab1e4")
            self:SetXUITextColor(trans:GetComponent(typeXUIText),color)
            CS.ShowObject(trans,maxValue>=i)
        end
    end
end


function UIGameBzerNew:ClickBoxSel(ref,selIndx,moreInfo)--开关类型
    local refId = ref.refId
    local freeSetting = gModelGameHelper:GetSettingById(refId)
    local num = freeSetting.parameter1
    if selIndx  then
        num = selIndx
    else
        num = freeSetting.parameter1 == 1 and 0 or 1
    end
    local setting = {
		refId = ref.refId,
		parameter1 = num,
        moreInfo = moreInfo
	}
	gModelGameHelper:GameHelperSettingReq(2, setting)--1查看 2设置

end
------------------------------------------------------------------
return UIGameBzerNew