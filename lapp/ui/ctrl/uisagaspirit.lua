---
--- Created by Administrator.
--- DateTime: 2023/10/17 17:24:03
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaSpirit:LWnd
local UISagaSpirit = LxWndClass("UISagaSpirit", LWnd)

local typeSpineClick = typeof(CS.SpineClick)

UISagaSpirit.TYPE_PAGE4_SHOW_PAY = 0
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaSpirit:UISagaSpirit()
    self:SetHideHurdle()
    ---@type table<number, CommonIcon>
    self._commonUIList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaSpirit:OnWndClose()
    self:ClearCommonIconList(self._commonUIList)
    self._commonUIList = nil
    gModelHero:SetAutoSacrificeStatus(self._autoSacrifice)
    gModelHero:ClearUpStarSelHeroList()
    if self._uiList then
        self._uiList:OnWndClose()
    end
    if self._uiSelHeroList then
        self._uiSelHeroList:OnWndClose()
    end
    -- FireEvent(EventNames.ON_HOROSCOPE_JOIN)

    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaSpirit:OnCreate()
    LWnd.OnCreate(self)

    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaSpirit:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    local jumpCallback = self:GetWndArg("jumpCallback")
    if jumpCallback then
        jumpCallback()
    end

    self:InitNoHeroList()
    local subPage = self:InitData()
    self:SetTxt()
    self:InitEvent()
    self:InitMsg()
    self:InitBotBtnList()
    self:ChangPageData(self._page, true, subPage)
    CS.ShowObject(self.mSacrificeSelGou, self._autoSacrifice)
    self:Refresh()
    self:RefreshBtnHelp()
end
--------------------------------------- 英雄种族事件注册 ---------------------------------------
function UISagaSpirit:HeroRaceBtnEvent(index, refresh)
    if self._page == 3 and self._pageIndex == 1 and self:NoChangeHero() then
        return
    end
    self:ReSetData()
    if self._page == 2 then
        CS.ShowObject(self.mNoSelDiv2, self._page == 2)
        CS.ShowObject(self.mPage2ShowDiv, false)
        self._selectHeroList = {}
        self._selectHeroId = nil
    end
    local trans = self._heroRaceBtnSelList[self._raceType]
    if self._raceType == 0 then
        trans = self.mAllRaceBtnSel
    end
    CS.ShowObject(trans, false)
    self._raceType = index
    trans = self._heroRaceBtnSelList[self._raceType]
    if self._raceType == 0 then
        trans = self.mAllRaceBtnSel
    end
    CS.ShowObject(trans, true)
    if not refresh then
        self:InitScrollView()
    end
end
function UISagaSpirit:Page2Event()
    if self._isLimit then
        local limitStar = string.replace(ccClientText(14724), self._upStarLimit)
        GF.ShowMessage(limitStar)
    else
        if table.isempty(self._selectHeroList) then
            GF.ShowMessage(ccClientText(14425))
        else
            if self._sendMsg then
                return
            end
            local id = self._selectHeroId
            local data = self._selectHeroList[id]
            if id and data then
                local appointedlist, rangelist, rangItemList = data.appointList, data.rangList, data.rangItemList
                local appNeedInfo, rangNeedInfo, itemNeedInfo = data.appNeedInfo, data.rangNeedInfo, data.itemNeedInfo
                for i, v in ipairs(appointedlist) do
                    local needNum = appNeedInfo[i].needNum
                    local selNum = table.keysize(v)
                    if selNum < needNum then
                        GF.ShowMessage(ccClientText(10054))
                        return
                    end
                end
                for i, v in ipairs(rangelist) do
                    local selItemNum = 0
                    local temp = rangItemList[i] or {}
                    for _k, _v in pairs(temp) do
                        selItemNum = selItemNum + _v
                    end
                    local needNum = rangNeedInfo[i].needNum
                    local selNum = table.keysize(v) + selItemNum
                    if selNum < needNum then
                        GF.ShowMessage(ccClientText(10054))
                        return
                    end
                end
                for i, v in ipairs(itemNeedInfo) do
                    local itemRefId, needNum = v.itemRefId, v.needNum
                    local haveNum = gModelItem:GetNumByRefId(itemRefId)
                    if haveNum < needNum then
                        self:OpenGetWayWnd(itemRefId)
                        return
                    end
                end
                local upStarFunc = function()
                    self._sendMsg = true
                    gModelHero:CheckHeroHightHero(appointedlist, rangelist, function()
                        --gModelHero:OnHeroMergeReq(id,appointedlist,rangelist,rangItemList)
                        --gModelHero:OnHeroUpStarReqByHeroInfoWnd(id,appointedlist,rangelist,rangItemList)
                        local list = {
                            { id = id, appointedlist = appointedlist, rangelist = rangelist, rangItemList = rangItemList }
                        }
                        gModelHero:OnHeroUpStarReq(list)
                    end, function()
                        self._sendMsg = false
                    end, id)
                end
                if gModelHeroExtra:CheckUpStarIsSelRare(rangelist, rangItemList, rangNeedInfo) then
                    local winData = { refId = 10046, func = upStarFunc }
                    gModelGeneral:OpenUIOrdinTips(winData)
                else
                    upStarFunc()
                end
            end
        end
    end
end
function UISagaSpirit:OnDrawHeroCell(list, item, itemdata, itempos, fromHeadTail)
    local iconTrans = CS.FindTrans(item, "CommonUI/Icon")
    local id = itemdata.id
    if self._page == 4 then
        local heroAttrList, heroWearEquipList, heroWearRuneList, heroWearTalentList = gModelHero:GetHeroAttrAndEquipInfoById(id)
        if table.isempty(heroAttrList) then
            gModelHero:OnHeroAttributeReq(id)
        end
    end
    local upStar = itemdata.upStar
    local isFuse = itemdata.isFuse == 1
    local sel = self._selectHeroList[id] ~= nil
    local instanceId = item:GetInstanceID()

    local bShowMask = false
    if not sel and self._page == 2 and upStar == 2 then
        bShowMask = upStar == 2
    end

    self:SetPlayerHeroIcon(iconTrans, instanceId, id, false, sel, self._page ~= 2, bShowMask)

    self:SetWndClick(iconTrans, function()
        if LOG_INFO_ENABLED then
            printInfoNR("================ 打印而已，莫慌   该英雄的refId为：" .. itemdata.refId .. ",id = " .. id)
        end
        self:DisposeHero(itemdata)
    end)
    local FuseImgTrans = CS.FindTrans(item, "FuseImg")
    if FuseImgTrans then
        if self._page == 2 then
            if upStar == 2 then
                CS.ShowObject(FuseImgTrans, false)
            else
                CS.ShowObject(FuseImgTrans, isFuse)
            end
        else
            CS.ShowObject(FuseImgTrans, false)
        end
    end
end
function UISagaSpirit:GetNameAndTypeImg(id, typeImgTrans, nameTrans, star, starTrans, nextRefId)
    local typeId, name
    if nextRefId then
        typeId = gModelHero:GetHeroType(nextRefId)
        name = gModelHero:GetHeroNameByRefId(nextRefId, star)
    else
        typeId = gModelHero:GetTypeById(id)
        name = gModelHero:GetHeroNameById(id)
    end
    if not typeId then
        gModelHero:GetHeroRef(id)
    end
    local typeImg = gModelHero:GetRaceImgByRefId(typeId)
    if typeImg then
        self:SetWndEasyImage(typeImgTrans, typeImg)
    end
    if not name then
        name = gModelHero:GetHeroNameByRefId(id, star)
    end
    self:SetWndText(nameTrans, name)
    self:InitTextSizeWithLanguage(nameTrans, -4)
    local serverData = gModelHero:GetHeroServerDataById(id)
    if serverData then
        local color = gModelHero:GetHeroNameColorTableByRefId(serverData.refId, serverData.star, true)
        if color then
            self:SetXUITextTransColor(nameTrans, color)
        end
    end
    local img, showNum = gModelHero:GetHeroStarImg(star)
    for starI, starT in ipairs(starTrans) do
        if starI <= showNum then
            self:SetWndEasyImage(starT, img)
        end
        CS.ShowObject(starT, starI <= showNum)
    end
end

function UISagaSpirit:RefreshBtnHelp()
    CS.ShowObject(self.mBtnProb, false)
    CS.ShowObject(self.mHelpBtn, true)
    local showProb = false
    local showBtnHelp = true
    if self._page == 3 then

        local config = GameTable.CharacterConfigRef
        local flag = config.probabilityOff or nil
        if flag == 0 or nil then
            showProb = false
        else
            showProb =true
        end
        showBtnHelp = not showProb
        CS.ShowObject(self.mBtnProb, showProb)
        CS.ShowObject(self.mHelpBtn, showBtnHelp)
    end
end
function UISagaSpirit:IsEnough(refId, num)
    local haveNum = gModelItem:GetNumByRefId(refId)
    return haveNum >= num
end
function UISagaSpirit:OnDrawPage2ItemCell(list, item, itemdata, itempos, fromHeadTail)
    local keyName = itemdata.keyName
    local rootTrans = self:FindWndTrans(item, "Root")
    local CommonUITrans = CS.FindTrans(rootTrans, "CommonUI")
    local redPointTrans = CS.FindTrans(item, "redPoint")
    local selLen
    local index, needRefId, needNum, needStar, id = itemdata.index, itemdata.needRefId, itemdata.needNum, itemdata.needStar, self._selectHeroId
    if CommonUITrans then
        local iconTrans = CS.FindTrans(CommonUITrans, "Icon")
        local instanceId = item:GetInstanceID()

        local typeCom = 1
        local baseClass
        if keyName ~= "item" then
            typeCom = 2

            local appList, bRace
            if keyName == "appoint" then
                appList = self._selectHeroList[id].appointList[index]
            elseif keyName == "range" then
                appList = self._selectHeroList[id].rangList[index]
                bRace = true
            end
            selLen = table.keysize(appList)
            baseClass = self:SetConsumeHeroIcon(iconTrans, instanceId, needRefId, needStar, selLen ~= needNum, bRace, needNum, selLen)
        else
            baseClass = self:SetConsumeItemIcon(iconTrans, instanceId, typeCom, needRefId, needNum)
        end

        self:SetWndClick(iconTrans, function()
            if keyName == "appoint" then
                local tab = { refId = needRefId, num = needNum, star = needStar, race = -1,
                              selHeorId = id, selHeroList = self._selectHeroList[id].appointList[index],
                              func = function(appointList)
                                  if not self:IsWndValid() then
                                      return
                                  end
                                  local selNum = table.keysize(appointList)
                                  if not table.isempty(appointList) then
                                      --[[									 local oldData = self._selectHeroList[id].appointList[index] or {}
									 for _k,_v in pairs(oldData) do
										 local b = gModelHero:IsHeroIdSel(_k)
										 if b then
											 gModelHero:SetSelHeroId(_k)
										 end
									 end]]
                                      local tempList = {}
                                      self._selectHeroList[id].appointList[index] = tempList
                                      for _k, _v in pairs(appointList) do
                                          --gModelHero:SetSelHeroId(_k)
                                          tempList[_v] = _v
                                      end
                                      baseClass:SetSelHeroNum(selNum, needNum)
                                  else
                                      self._selectHeroList[id].appointList[index] = appointList
                                      baseClass:SetSelHeroNum(0, needNum)
                                  end
                                  baseClass:ShowMaskOnly(selNum ~= needNum)
                                  if redPointTrans then
                                      local showRed = selNum < needNum
                                      if showRed then
                                          local dataList = gModelHero:FilterHero(needRefId, needStar, nil, id, {})
                                          local tempLen = table.keysize(dataList)
                                          local tempNum = needNum - selNum
                                          showRed = tempLen >= tempNum
                                      end
                                      CS.ShowObject(redPointTrans, showRed)
                                  end
                              end
                }
                GF.OpenWnd("UISagaSelect", tab)
            elseif keyName == "range" then
                --应该是只有  1 和 2 的情况
                local otherIndex = index == 1 and 2 or 1

                if not self._selectHeroList[id].rangItemList[otherIndex] then
                    self._selectHeroList[id].rangItemList[otherIndex] = {}
                end

                local tab = { refId = needRefId, num = needNum, star = needStar, race = needRefId,
                              selHeorId = id, selHeroList = self._selectHeroList[id].rangList[index], selItemList = table.clone(self._selectHeroList[id].rangItemList[index]),
                              selfItemOtherList = table.clone(self._selectHeroList[id].rangItemList[otherIndex]),
                              func = function(rangList, rangItemList)
                                  if not self:IsWndValid() then
                                      return
                                  end
                                  self._selectHeroList[id].rangItemList[index] = {}
                                  local selNum = table.keysize(rangList)
                                  for k, v in pairs(rangItemList) do
                                      if v > 0 then
                                          self._selectHeroList[id].rangItemList[index][k] = v
                                      else
                                          self._selectHeroList[id].rangItemList[index][k] = nil
                                      end
                                      selNum = selNum + v
                                  end
                                  if not table.isempty(rangList) then
                                      --[[									 local oldData = self._selectHeroList[id].rangList[index] or {}
									 for _k,_v in pairs(oldData) do
										 local b = gModelHero:IsHeroIdSel(_k)
										 if b then
											 gModelHero:SetSelHeroId(_k)
										 end
									 end]]
                                      local tempList = {}
                                      self._selectHeroList[id].rangList[index] = tempList
                                      for _k, _v in pairs(rangList) do
                                          --gModelHero:SetSelHeroId(_k)
                                          tempList[_v] = _v
                                      end
                                      baseClass:SetSelHeroNum(selNum, needNum)
                                  else
                                      self._selectHeroList[id].rangList[index] = rangList
                                      baseClass:SetSelHeroNum(selNum, needNum)
                                  end
                                  baseClass:ShowMaskOnly(selNum ~= needNum)
                                  for idxNum, idxData in ipairs(self._appSelHeroList) do
                                      if not self._selectHeroList[id] then
                                          break
                                      end
                                      local appointList = self._selectHeroList[id].appointList[idxNum] or {}
                                      local appRedPointTrans = self._page2RedPointTransList[idxNum]
                                      local curSelNum, haveSelNum = 0, table.keysize(idxData)
                                      local appData = self._appHeroList[idxNum]
                                      local appNeedNum = appData.needNum
                                      for idxKey, idxVal in pairs(idxData) do
                                          if rangList[idxKey] then
                                              curSelNum = curSelNum + 1
                                          end
                                      end
                                      local isShow = curSelNum < haveSelNum
                                      local selListLen = table.keysize(appointList)
                                      if selListLen ~= 0 then
                                          isShow = selListLen < appNeedNum
                                          if isShow then
                                              local tempNeedNum = appNeedNum - selListLen
                                              local tempFilterList = gModelHero:FilterHero(appData.needRefId, appData.needStar, nil, id, {})
                                              local tempFileterNum = table.keysize(tempFilterList)
                                              isShow = tempFileterNum >= tempNeedNum
                                          end
                                      else
                                          local tempFilterList = gModelHero:FilterHero(appData.needRefId, appData.needStar, nil, id, {})
                                          local tempFileterNum = table.keysize(tempFilterList)
                                          isShow = tempFileterNum >= appNeedNum
                                      end
                                      CS.ShowObject(appRedPointTrans, isShow)
                                  end
                                  if redPointTrans then
                                      local redShow = selNum ~= needNum
                                      if redShow then
                                          local dataList = gModelHero:FilterHero(needRefId, needStar, needRefId, id, {})
                                          local len = table.keysize(dataList)
                                          local tempNum = needNum - selNum
                                          redShow = len >= tempNum
                                      end
                                      CS.ShowObject(redPointTrans, redShow)
                                  end
                              end
                }
                GF.OpenWnd("UISagaSelect", tab)
            else
                self:OpenGetWayWnd(needRefId)
            end
        end)


        --printInfoN("==== keyName = "..keyName)
    end
    local canCompound = itemdata.canCompound
    if canCompound ~= nil then
        if redPointTrans then
            if keyName == "appoint" then
                table.insert(self._page2RedPointTransList, redPointTrans)
            end
            if keyName == "appoint" then
                local show = selLen < needNum
                if show then
                    local data = self._appSelHeroList[index] or {}
                    local dataNum = table.keysize(data)
                    show = dataNum >= needNum
                end
                if redPointTrans then
                    CS.ShowObject(redPointTrans, show)
                end
            else
                CS.ShowObject(redPointTrans, canCompound)
            end
        end
    else
        CS.ShowObject(redPointTrans, false)
    end
end
function UISagaSpirit:CreatePage2ItemList(itemData)
    self._page2RedPointTransList = {}
    local uiList = self._uiPage2ItemList
    if not uiList then
        uiList = UIListEasy:New()
        uiList:Create(self, self.mPage2ItemList)
        uiList:EnableScroll(true, true)
        uiList:SetFuncOnItemDraw(function(...)
            self:OnDrawPage2ItemCell(...)
        end)
        self._uiPage2ItemList = uiList
    end
    uiList:RemoveAll()
    self._appHeroList = {}
    for i, v in ipairs(itemData) do
        for key, value in pairs(v) do
            for _i, _v in ipairs(value) do
                printInfoNR("===== key,_i,_v = ", key, _i, _v)
                _v.keyName = key
                if key == "appoint" then
                    table.insert(self._appHeroList, _v)
                end
                _v.index = _i
                local kayName = key .. _i
                uiList:AddData(kayName, _v)
            end
        end
    end
    uiList:RefreshList()
end
--------------------------------------- 献祭获得道具列表 ---------------------------------------
function UISagaSpirit:RefreshSelectHeroRewardList()
    local uiList = self._uiHeroRewardList
    if not uiList then
        uiList = UIListEasy:New()
        uiList:Create(self, self.mSacrificeItemList)
        uiList:EnableScroll(false, true)
        uiList:SetFuncOnItemDraw(function(...)
            self:OnDrawSelHeroRewardCell(...)
        end)
        self._uiHeroRewardList = uiList
    end
    uiList:RemoveAll()
    local rewardList = self:GetSelectReward()
    for k, v in pairs(rewardList) do
        local data = { refId = k, num = v }
        uiList:AddData(k, data)
    end
    uiList:RefreshList()
end
function UISagaSpirit:OnClickSelBtnEvent()
    --[[		self._selThreeStar = not self._selThreeStar
            CS.ShowObject(self.mSacrificeSelGou,self._selThreeStar)
            self._selectHeroList = {}
            self:SelectHeroList(0)
            self:InitScrollView()]]
    self._autoSacrifice = not self._autoSacrifice
    CS.ShowObject(self.mSacrificeSelGou, self._autoSacrifice)
end
--------------------------------------- 中间按钮事件 ---------------------------------------
function UISagaSpirit:OptBtn()
    if self._page == 1 then
        self:Page1Event()
    end
    if self._page == 2 then
        self:Page2Event()
    end
    if self._page == 3 then
        self:Page3Event()
    end
    if self._page == 4 then
        self:Page4Event()
    end
end
function UISagaSpirit:Page3SelectHero()
    local selectId = self._selectHeroId
    local selectHeroList = self._selectHeroList
    local data = selectHeroList[selectId]
    if data then
        local heroNum = data.needHeroNum
        --[[		选择类型后重新打开则显示对应类型的英雄
		local race,refId
		if table.isempty(data.selectList) then
			race = gModelHero:GetHeroType(data.refId)
			refId = race
		else
			for k,v in pairs(data.selectList) do
				if refId then break end
				refId = gModelHero:GetRefIdById(k)
			end
		end]]
        local race = gModelHero:GetHeroType(data.refId)
        local tab = { refId = race, num = heroNum, star = data.needStar, race = race,
                      selHeorId = selectId, selHeroList = data.selectList, sameRefId = true, replaceRefId = true,
                      func = function(selectList)
                          local selNum = 0
                          local _selectHeroList = self._selectHeroList[selectId]
                          if not table.isempty(selectList) then
                              local list = {}
                              _selectHeroList.selectList = list
                              selNum = table.keysize(selectList)
                              local selectRefId
                              for k, v in pairs(selectList) do
                                  if not selectRefId then
                                      selectRefId = gModelHero:GetRefIdById(v)
                                  end
                                  list[v] = v
                              end
                              if selectRefId then
                                  if _selectHeroList.func then
                                      _selectHeroList.func(true, selectRefId)
                                  end
                              end
                          else
                              if _selectHeroList.func then
                                  _selectHeroList.func(false)
                              end
                              _selectHeroList.selectList = selectList
                          end
                          self:ShowSelectHeroNumTxt(selNum, heroNum)
                      end
        }
        GF.OpenWnd("UISagaSelect", tab)
    end
end
--------------------------------------- 页面3、4的道具显示 ---------------------------------------
function UISagaSpirit:GetHeroDiSplaceShow()
    local refId, iconTrans, numTrans = self._heroChangeShowItem
    if self._page == 3 then
        if self._pageIndex == 2 then
            refId = self._heroDiSplaceShowItem
        end
        iconTrans, numTrans = self.mItemIcon, self.mItemNum
        CS.ShowObject(self.mPage3PayDiv, true)
    elseif self._page == 4 then
        refId = self._pageIndex == 2 and self._heroReturnShowItem or self._heroReturnShowItem1
        iconTrans, numTrans = self.mPage4ItemIcon, self.mPage4ItemNum
        CS.ShowObject(self.mPage4PayDiv, self._pageIndex == 2 or self._pageIndex == 3)
    end
    self:ChangeItemInfo(refId, iconTrans, numTrans)
end
--------------------------------------- 页面3、页面4事件 ---------------------------------------
function UISagaSpirit:ChangeTabData(index)
    if index > 2 then
        if self._pageIndex == index - 2 then
            return
        end
    else
        if self._pageIndex == index then
            return
        end
    end
    self:DestroyWndSpinetAll()
    self:CreatePageIndexPb(index)
    local starNum, endNum, descList
    if index <= 2 then
        starNum, endNum = 1, 2
        self._pageIndex = index
        descList = self._page3DescList
    elseif index > 2 then
        starNum, endNum = 3, 5
        self._pageIndex = index - 2
        descList = self._page4DescList
    end
    if not table.isempty(self._selectHeroList) then
        CS.ShowObject(self.mSelectHeroChange1Show, false)
        CS.ShowObject(self.mSelectHeroChange2Show, false)
        self._selectHeroList = {}
        self._selectHeroId = nil
        CS.ShowObject(self.mNoSelDiv1, true)
    end
    local txt = self._btnTxtList[self._page][self._pageIndex]
    self:SetWndButtonText(self.mSacrificeBtn, txt)
    local desc = descList[self._pageIndex]
    self:SetWndText(self.mNoSelDesc, desc)
    for i = starNum, endNum do
        local show = i == index and 0 or 1
        self:SetWndTabStatus(self._page34BtnList[i], show)
    end
    self:SetWndButtonGray(self.mSacrificeBtn, true)
    CS.ShowObject(self.mSacrificeBtn, true)
    if self._page == 3 then
        CS.ShowObject(self.mPage3CancelBtn, false)
        CS.ShowObject(self.mPage3EnterBtn, false)
        CS.ShowObject(self.mChangePayItemIcon, false)
        CS.ShowObject(self.mChangPayItemNum, false)
    else
        if self._pageIndex == 1 then
            self:SetWndText(self.mPage4yulanTxt, ccClientText(14419))
            CS.ShowObject(self.mPage4FreeTxt, self._isOpenDay)
        else
            self:SetWndText(self.mPage4yulanTxt, ccClientText(14436))
            CS.ShowObject(self.mPage4FreeTxt, false)
        end
        CS.ShowObject(self.mRebirthNum, self._pageIndex == 1)
        CS.ShowObject(self.mPage4PayDiv, self._pageIndex ~= 1)
        CS.ShowObject(self.mPage4Show, false)
        CS.ShowObject(self.mPage4PayIcon, false)
        CS.ShowObject(self.mPage4PayNum, false)
    end
    self:GetHeroDiSplaceShow()
    self:InitScrollView()
end
--------------------------------------- 英雄事件处理 ---------------------------------------
function UISagaSpirit:DisposeHero(itemdata)
    if self._sendMsg then
        return
    end
    if self._page ~= 2 then
        if itemdata.status == 0 then
            if self._page == 1 then
                self:ClickHeroIcon1(itemdata)
            end
            if self._page == 4 then
                self:ClickHeroIcon4(itemdata)
            end
            if self._page == 3 then
                self:ClickHeroIcon3(itemdata)
            end
        else
            local id = itemdata.id
            local lock, isCombat, isResonance = itemdata.lock, itemdata.isCombat, itemdata.isResonance
            if isCombat == 1 then
                self:HeroUnCombat(id)
            elseif isResonance == 1 then
                self:HeroUnResonance(id)
            elseif lock == 1 then
                self:HeroUnLock(id)
            end
        end
    elseif self._page == 2 then
        if itemdata.upStar == 2 then
            GF.ShowMessage(ccClientText(14437))
            return
        end
        gModelHero:ClearUpStarSelHeroList()
        self:ClickHeroIcon2(itemdata)
    end
end
--------------------------------------- 事件注册 ---------------------------------------
function UISagaSpirit:OnClickSelectBtnFunc()
    --self:SelectHeroList(1)
    GF.OpenWnd("UISagaSetRepatriate")
end
function UISagaSpirit:ClickHeroUI(spine, refId)
    local spineTrans = spine:GetSpineTrans()
    local spineClick = spineTrans:GetComponent(typeSpineClick)
    if not spineClick then
        spineClick = spineTrans.gameObject:AddComponent(typeSpineClick)
        spineClick.isUISpine = true
    end
    spineClick.onClick = function()
        gModelGeneral:OpenHeroSimpleTip(refId, true)
    end
end
function UISagaSpirit:OpenGetWayWnd(refId)
    local wndArg = self:GetWndArgList()
    wndArg.page = self._page
    wndArg.subPage = self._pageIndex
    self:SetWndArg(wndArg)
    gModelGeneral:OpenGetWayWnd({ itemId = refId, srcWnd = self:GetWndName() })
end
function UISagaSpirit:CreatePageIndexPb(index)
    local pb = self._showLHTabList[index]
    if not string.isempty(pb) then
        self:CreateWndSpine(self.mHeroLHPos, pb, pb, false)
    end
end
function UISagaSpirit:ShowSelectHeroNumTxt(selectNum, heroNum)
    local str = string.format("%s/%s", selectNum, heroNum)
    self:SetWndText(self.mPage3SelectHeroNum, str)
end

function UISagaSpirit:RefreshAutoUpStarRedPoint()
    local status = gModelHeroSpirit:CheckAutoUpStarHeroStatus()
    CS.ShowObject(self.mAutoUpStarBtnRedPoint, status)
end
function UISagaSpirit:HeroUnCombat(heroId)
    gModelFormation:OnHeroRemoveFormationReq(heroId, self._pageIndex)
    --[[	local func = function()
		self._clickHeroId = heroId
		gModelFormation:OnHeroRemoveFormationReq(heroId)
	end
	gModelHeroSpirit:HeroUnCombatOpt({func = func})]]
end
function UISagaSpirit:OnDrwaBtnItem(list, item, itemdata, itempos, fromHeadTail)
    local name, index = itemdata.name, itemdata.index
    --[[	local NoSelImgTrans = CS.FindTrans(item,"NoSelImg")
	if NoSelImgTrans then
		local NoSelNameTrans = CS.FindTrans(NoSelImgTrans,"NoSelName")
		if NoSelNameTrans then self:SetWndText(NoSelNameTrans,name) end
	end
	local SelImgTrans = CS.FindTrans(item,"SelImg")
	if SelImgTrans then
		local BtnNameTrans = CS.FindTrans(SelImgTrans,"BtnName")
		if BtnNameTrans then self:SetWndText(BtnNameTrans,name) end
		CS.ShowObject(SelImgTrans,index == self._page)
	end]]
    local btnTrans = self:FindWndTrans(item, "Btn")
    if btnTrans then
        self:SetWndTabText(btnTrans, name, -4, -30)
        self:SetWndTabStatus(btnTrans, index == self._page and 0 or 1)
        self._botBtnList[index] = btnTrans
        self:SetWndClick(btnTrans, function()
            self:ChangPageData(index)
        end, LSoundConst.CLICK_PAGE_COMMON)
    end
    local redPointTrans = CS.FindTrans(item, "redPoint")
    if redPointTrans then
        if index == 2 then
            --local upStarStatus = gModelHero:GetHeroUpStarStatus(nil,true) or false
            CS.ShowObject(redPointTrans, false)
        else
            CS.ShowObject(redPointTrans, false)
        end
    end
end
function UISagaSpirit:OpenItemTips(refId, num)
    gModelGeneral:OpenItemInfoTip(refId, num)
end
--------------------------------------- 空白列表 ---------------------------------------
function UISagaSpirit:InitNoHeroList()
    local data = { refId = 1002, IntroTran = self.mNoHeroDesc, GetBtnText = self.mNoHeroBtnName, GetBtn = self.mNoHeroBtn }
    local emptyList = self:GetCommonEmptyList("_empty")
    emptyList:RefreshUI(data)
end
function UISagaSpirit:Page3Event(index)
    local heroId = self._selectHeroId
    local list = self._selectHeroList[heroId]
    if not list then
        GF.ShowMessage(ccClientText(14425))
        return
    end
    if heroId then
        if self._sendMsg then
            return
        end
        if self._pageIndex == 1 then
            self._sendMsg = true
            index = index or 1
            if index == 2 then
                gModelHero:CheckChangeHeroHightHero({ heroId }, function()
                    gModelHero:OnHeroTransformReq(heroId, index)
                end, function()
                    self._sendMsg = false
                end)
            else
                local func = function()
                    gModelHero:OnHeroTransformReq(heroId, index)
                end
                if index ~= 3 then
                    local itemRefId, itemNum = list.itemRefId, list.itemNum
                    local isEnough = self:IsEnough(itemRefId, itemNum)
                    if not isEnough then
                        self._sendMsg = false
                        self:OpenGetWayWnd(itemRefId)
                        return
                    end
                end
                if index == 3 then
                    local serverData = gModelHero:GetHeroServerDataById(heroId)
                    if serverData then
                        local nextRefId = serverData.nextRefId
                        local quality = gModelHero:GetHeroInitQualityByRefId(nextRefId)

                        --printInfoNR(" ==== nextRefId = " .. nextRefId)
                        --printInfoNR(" ==== quality = " .. quality)
                        if quality and quality >= 7 then
                            local leftFunc = function()
                                self._sendMsg = false
                            end
                            gModelGeneral:OpenUIOrdinTips({ refId = 10012, func = func, leftFunc = leftFunc, closeFunc = leftFunc })
                        else
                            if func then
                                func()
                            end
                        end
                    else
                        if func then
                            func()
                        end
                    end
                else
                    if func then
                        func()
                    end
                end
            end
        elseif self._pageIndex == 2 then
            local selectList = list.selectList
            local needHeroNum = list.needHeroNum
            local selectNum = table.keysize(selectList) or 0
            if selectNum < needHeroNum then
                self._sendMsg = false
                GF.ShowMessage(ccClientText(14426))
            else
                local func = function()
                    self._sendMsg = true
                    gModelHero:OnHeroDisplaceReq(heroId, selectList)
                end
                local selectInfo = {
                    needHeroNum = list.needHeroNum,
                    needItemRefId = list.needItemRefId,
                    needItemNum = list.needItemNum,
                    needStar = list.needStar,
                    func = func,
                    selectList = selectList,
                    heroId = heroId,
                    refId = list.refId
                }
                GF.OpenWnd("UISagaDisplace", { heroId = heroId, selectInfo = selectInfo })
            end
            printInfoNR("===========")
        end
    else
        GF.ShowMessage(ccClientText(14425))
    end
end
function UISagaSpirit:ClearPage2Data(id, network)
    printInfoNR("================== 清空")
    local isempty = table.isempty(self._selectHeroList[id])
    CS.ShowObject(self.mPage2ShowDiv, isempty)
    CS.ShowObject(self.mPage4Show, isempty)
    local trans
    if self._page == 2 then
        trans = self.mNoSelDiv2
    end
    if self._page == 3 or self._page == 4 then
        trans = self.mNoSelDiv1
        if self._page == 3 then
            CS.ShowObject(self.mSelectHeroChange1Show, self._pageIndex == 1)
            CS.ShowObject(self.mSelectHeroChange2Show, self._pageIndex == 2)
            CS.ShowObject(self.mChangePayItemIcon, isempty)
            CS.ShowObject(self.mChangPayItemNum, isempty)
        end
    end
    if network and self._page == 3 and self._pageIndex == 2 then
        CS.ShowObject(trans, false)
    else
        CS.ShowObject(trans, not isempty)
    end
    self:SetWndButtonGray(self.mSacrificeBtn, not isempty)
    self._selectHeroList = {}
    self._selectHeroId = nil
    return isempty
end
function UISagaSpirit:InitHeroUpStarInfo(id, isUseOldData)
    id = id or self._selectHeroId
    if not id then
        return
    end
    local structHero = gModelHero:GetHeroById(id)
    if not structHero then
        return
    end
    --local heroRefId,star = structHero:GetRefId(),structHero:GetStar()
    local starRef = gModelHero:GetStarRefById(id)  --gModelHero:GetHeroStarRefByHeroRefIdAndStar(heroRefId,star)
    if not starRef then
        return
    end
    local itemData = { [1] = {}, [2] = {}, [3] = {} }
    local upStarAppoint, upStarRange, upStarItem = starRef.upStarAppoint, starRef.upStarRange, starRef.upStarItem
    local selHeroList = {}
    self._appSelHeroList = {}
    self._rangSelHeroList = {}
    if not self._selectHeroList[id].appointList then
        self._selectHeroList[id].appointList = {}
    end
    if not self._selectHeroList[id].appNeedInfo then
        self._selectHeroList[id].appNeedInfo = {}
    end
    if not string.isempty(upStarAppoint) then
        itemData[1].appoint = {}
        local appoint = string.split(upStarAppoint, ",")
        for i, v in ipairs(appoint) do
            local oldData
            local tAppointList = self._selectHeroList[id].appointList[i]
            if not tAppointList then
                tAppointList = {}
                self._selectHeroList[id].appointList[i] = tAppointList
            else
                oldData = tAppointList
            end
            v = string.split(v, "=")
            local needRefId, needStar, needNum = tonumber(v[1]), tonumber(v[2]), tonumber(v[3])
            if not self._selectHeroList[id].appNeedInfo[i] then
                self._selectHeroList[id].appNeedInfo[i] = { needNum = needNum }
            end
            local dataList = gModelHero:FilterHero(needRefId, needStar, nil, id, {})
            local haveNum = table.keysize(dataList)
            local tempList = {}
            local aaa = 0
            if isUseOldData and oldData then
                for key, value in pairs(oldData) do
                    if aaa >= needNum then
                        break
                    end
                    tempList[key] = value
                    aaa = aaa + 1
                end
            else
                for key, value in pairs(dataList) do
                    if aaa >= needNum then
                        break
                    end
                    tempList[key] = value
                    aaa = aaa + 1
                end
            end
            table.insert(selHeroList, tempList)
            table.insert(self._appSelHeroList, dataList)
            local canCompound = haveNum >= needNum
            itemData[1].appoint[i] = { needRefId = needRefId, needStar = needStar, needNum = needNum, canCompound = canCompound }
            if isUseOldData and oldData then
                local selList = tAppointList
                for key, value in pairs(oldData) do
                    selList[key] = key
                    gModelHero:SetSelHeroId(key)
                end
            else
                -- 自动填充
                local sortSelList = gModelHero:SortFillHeroList(dataList)
                if #sortSelList ~= 0 then
                    local selList = tAppointList
                    for selIdx, selHeroData in ipairs(sortSelList) do
                        if selIdx > needNum then
                            break
                        end
                        local autoSelId = selHeroData._id
                        selList[autoSelId] = autoSelId
                        gModelHero:SetSelHeroId(autoSelId)
                    end
                end
            end
        end
    end
    if not self._selectHeroList[id].rangList then
        self._selectHeroList[id].rangList = {}
    end
    if not self._selectHeroList[id].rangItemList then
        self._selectHeroList[id].rangItemList = {}
    end
    if not self._selectHeroList[id].rangNeedInfo then
        self._selectHeroList[id].rangNeedInfo = {}
    end
    if not string.isempty(upStarRange) then
        itemData[2].range = {}
        local range = string.split(upStarRange, ",")
        for i, v in ipairs(range) do
            local oldData
            local tRangList = self._selectHeroList[id].rangList[i]
            if not tRangList then
                tRangList = {}
                self._selectHeroList[id].rangList[i] = tRangList
            else
                oldData = tRangList
            end
            local tRangItemList = self._selectHeroList[id].rangItemList[i]
            if not tRangItemList then
                tRangItemList = {}
                self._selectHeroList[id].rangItemList[i] = tRangItemList
            end
            v = string.split(v, "=")
            local needRefId, needStar, needNum = tonumber(v[1]), tonumber(v[2]), tonumber(v[3])
            if not self._selectHeroList[id].rangNeedInfo[i] then
                self._selectHeroList[id].rangNeedInfo[i] = {
                    needRefId = needRefId, needStar = needStar, needNum = needNum,
                }
            end
            local dataList, yinghunItemList = gModelHero:FilterHero(needRefId, needStar, needRefId, id, {})
            local haveNum = table.keysize(dataList) + table.keysize(yinghunItemList)
            local selHeroNum = 0
            --[[				for index,value in ipairs(selHeroList) do
                                for key,heroData in pairs(value) do
                                    if dataList[key] then selHeroNum = selHeroNum + 1 end
                                end
                            end]]
            local rangList = {}
            for key, appData in pairs(self._selectHeroList[id].appointList) do
                if not dataList[key] then
                    rangList[key] = appData
                end
            end
            table.insert(self._rangSelHeroList, rangList)
            local canCompound
            if needStar <= 3 then
                local sortSelList = gModelHero:SortFillHeroList(dataList)
                local tempSelNum = 0
                local selList = tRangList
                if isUseOldData and oldData then
                    for key, value in pairs(oldData) do
                        tempSelNum = tempSelNum + 1
                        selList[key] = key
                        gModelHero:SetSelHeroId(key)
                    end
                else
                    -- 自动填充
                    if #sortSelList ~= 0 then
                        for selIdx, selHeroData in ipairs(sortSelList) do
                            if selIdx > needNum then
                                break
                            end
                            tempSelNum = tempSelNum + 1
                            local autoSelId = selHeroData._id
                            selList[autoSelId] = autoSelId
                            gModelHero:SetSelHeroId(autoSelId)
                        end
                    end
                end
                local showRed = tempSelNum < needNum
                if showRed then
                    local sortSelLen = #sortSelList
                    showRed = sortSelLen >= needNum
                end
                canCompound = showRed
            else
                haveNum = haveNum - selHeroNum
                canCompound = haveNum >= needNum
            end
            itemData[2].range[i] = { needRefId = needRefId, needStar = needStar, needNum = needNum, canCompound = canCompound }
        end
    end
    if not self._selectHeroList[id].itemNeedInfo then
        self._selectHeroList[id].itemNeedInfo = {}
    end
    if not string.isempty(upStarItem) then
        itemData[3].item = {}
        upStarItem = string.split(upStarItem, "=")
        local itype, itemRefId, num = tonumber(upStarItem[1]), tonumber(upStarItem[2]), tonumber(upStarItem[3])
        if not self._selectHeroList[id].itemNeedInfo[1] then
            self._selectHeroList[id].itemNeedInfo[1] = { itemRefId = itemRefId, needNum = num }
        end
        itemData[3].item[1] = { itype = itype, needRefId = itemRefId, needNum = num }
    end
    self:CreatePage2ItemList(itemData)
end
function UISagaSpirit:Refresh(network)
    self:RefreshPage(network)
end
------------------------------------------------------------------
function UISagaSpirit:GetSelectReward()
    local rewardList = {}
    for k, v in pairs(self._selectHeroList) do
        local sacrificeGetItem = v.sacrificeGetItem
        if sacrificeGetItem then
            sacrificeGetItem = string.split(sacrificeGetItem, ",")
            for index, value in pairs(sacrificeGetItem) do
                value = string.split(value, "=")
                local itemRefId, itemNum = tonumber(value[2]), tonumber(value[3])
                if not rewardList[itemRefId] then
                    rewardList[itemRefId] = 0
                end
                rewardList[itemRefId] = rewardList[itemRefId] + itemNum
            end
        end
        local heroData = { lv = v.lv, grade = v.grade, refId = v.refId }
        local data = gModelHero:GetPayItemNum(heroData)
        for _i, _v in ipairs(data) do
            local itemRefId, itemNum = _v.refId, _v.num
            if itemNum ~= 0 then
                if not rewardList[itemRefId] then
                    rewardList[itemRefId] = 0
                end
                rewardList[itemRefId] = rewardList[itemRefId] + itemNum
            end
        end
    end
    local getRewardList = {}
    for k, v in pairs(rewardList) do
        table.insert(getRewardList, { itype = 1, refId = k, count = v })
    end
    self._xianjiRewardList = getRewardList
    return rewardList
end
function UISagaSpirit:Page4Event()
    if self._sendMsg then
        return
    end
    if self._pageIndex == 1 then
        if GameTable.CharacterConfigRef["heroLevelRebornNum"] ~= -1 then
            if self._rebornNum >= GameTable.CharacterConfigRef["heroLevelRebornNum"] then
                GF.ShowMessage(ccClientText(14429))
                return
            end
        end
    end
    local heroId = self._selectHeroId
    if heroId then
        local data = self._selectHeroList[heroId]
        if not data then
            return
        end
        local returnStar = data.returnStar
        local need = data.need
        local _refId, _num = need.refId, need.num
        local isEnough = self:IsEnough(_refId, _num)
        if not isEnough then
            if not self._isOpenDay and self._pageIndex == 1 then
                self._sendMsg = false
                self:OpenGetWayWnd(_refId)
                return
            end
        end
        local heroStruct = gModelHero:GetHeroById(heroId)
        local showStar, showLv
        if self._pageIndex == 1 then
            showLv = 1
        else
            showStar = returnStar
            showLv = data.maxLv
        end
        if not showStar then
            showStar = heroStruct:GetStar()
        end
        local tempList = data.fixReward
        local itemList = {}
        --- 2024/6/7：弹窗去掉英雄显示
        --[[        table.insert(itemList, { heroData = {
                    id = heroId,
                    refId = heroStruct:GetRefId(),
                    star = showStar or heroStruct:GetStar(),
                    level = showLv or heroStruct:GetLv(),
                    skin = heroStruct:GetSkin(),
                    isResonance = heroStruct:GetResonanceStatus(),
                    grade = heroStruct:GetGrade(),
                    fightPower = heroStruct:GetPower(),
                }, itype = LItemTypeConst.TYPE_HERO })]]

        for i, v in ipairs(tempList) do
            if v.itype == 2 then
                for index = 1, v.num do
                    table.insert(itemList, { itemId = v.refId, count = v.num, itype = v.itype })
                end
            else
                table.insert(itemList, { itemId = v.refId, count = v.num, itype = v.itype or 1, id = v.id })
            end
        end

        local wndId = 50904
        if self._isOpenDay then
            wndId = 50905
        end
        if self._pageIndex ~= 1 then
            if self._pageIndex == 2 then
                wndId = 50907
            else
                wndId = 50910
            end
        end
        local isMapping = gModelResonance:GetMappingOtherId(heroId)
        if (isMapping) then
            local para = {
                refId = 10046,
                func = function()
                    GF.OpenWnd("UISagaReeNew", { page = 4 })
                end,
            }
            gModelGeneral:OpenUIOrdinTips(para)
            return
        end
        self:DOPage4EventOpenWnCommonTips(heroId, isEnough, _refId, _num, showStar, heroStruct, wndId, itemList, returnStar, heroStruct:GetStar())
    else
        GF.ShowMessage(ccClientText(14425))
    end
end
function UISagaSpirit:ClearPage4Txt()
    CS.ShowObject(self.mPage4PayIcon, false)
    CS.ShowObject(self.mPage4PayNum, false)
    local strId = 14404
    if self._pageIndex == 1 then
        if self._isOpenDay then
            strId = 11913
        end
    elseif self._pageIndex == 2 then
        strId = 14417
    elseif self._pageIndex == 3 then
        strId = 14449
    end
    self:SetWndButtonText(self.mSacrificeBtn, ccClientText(strId))
    --self:SetWndText(self.mSacrificeBtnName,ccClientText(strId))
end
function UISagaSpirit:HeroUnResonance(heroId)
    local func = function()
        local pos = gModelResonance:GetResonanceHeroPos(heroId)
        self._clickHeroId = heroId
        if pos then
            gModelResonance:OnResonanceHeroReq(heroId, pos, 2)
        end
    end
    gModelHeroSpirit:HeroUnResonanceOpt({ func = func })
end

function UISagaSpirit:RefreshListById(id, mode)
    local uiHeroList = self._uiHeroList
    if not uiHeroList then
        return
    end
    local uiList = uiHeroList:GetList()
    if mode ~= nil then
        if mode == 1 then
            uiList:DrawAllItems()
        else
            uiList:RefreshList(UIListWrap.RefreshMode.Solid)
        end
    elseif id ~= nil then
        local dataKeyList = self._dataKeyList
        if not dataKeyList then
            return
        end
        local key = dataKeyList[id]
        if key then
            uiList:DrawItemByKey(key)
        end
    end
end

function UISagaSpirit:InitEvent()
    --self:WndEventRecv(EventNames.ON_MAIN_CITY_BTN_CHANGE,function () self:WndClose() end)
    self:SetWndClick(self.mAllRaceBtn, function()
        self:HeroRaceBtnEvent(0)
    end, LSoundConst.CLICK_PAGE_COMMON)
    for i, v in ipairs(self._heroRaceBtnList) do
        self:SetWndClick(v, function()
            self:HeroRaceBtnEvent(i)
        end, LSoundConst.CLICK_PAGE_COMMON)
    end
    self:SetWndClick(self.mReturnBtn, function()
        self:WndCloseAndBack()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mSacrificeBtn, function()
        self:OptBtn()
    end)
    self:SetWndClick(self.mSelectBtn, function()
        self:OnClickSelectBtnFunc()
    end)
    self:SetWndClick(self.mNoSelectBtn, function()
        self:SelectHeroList(0)
    end)
    for i, v in ipairs(self._page34BtnList) do
        self:SetWndClick(v, function()
            self:ChangeTabData(i)
        end)
    end
    self:SetWndClick(self.mSacrificeSelBtn, function()
        self:OnClickSelBtnEvent()
    end)
    self:SetWndClick(self.mYulanBtn, function()
        local data = self._selectHeroList[self._selectHeroId]
        local refId, star, skin = data.refId, data.star, data.skin
        gModelGeneral:OpenHeroTipByRefId(refId, star, skin)
    end)
    self:SetWndClick(self.mPage3CancelBtn, function()
        self:Page3Event(3)
    end)
    self:SetWndClick(self.mPage3EnterBtn, function()
        self:Page3Event(2)
    end)
    self:SetWndClick(self.mNoChangHeroIcon, function()
        self:Page3SelectHero()
    end)
    self:SetWndClick(self.mHelpBtn, function()
        local refId
        if self._page == 1 then
            refId = 28
        end
        if self._page == 2 then
            refId = 29
        end
        if self._page == 3 then
            if self._pageIndex == 1 then
                refId = 31
            else
                refId = 30
            end
        end
        if self._page == 4 then
            if self._pageIndex == 1 then
                refId = 32
            elseif self._pageIndex == 2 then
                refId = 33
            elseif self._pageIndex == 3 then
                refId = 94
            end
        end
        if refId then
            GF.OpenWnd("UIBzTips", { refId = refId })
        end
    end)
    self:SetWndClick(self.mHeroShopBtn, function()
        gModelFunctionOpen:Jump(tonumber(GameTable.CharacterConfigRef["heroShopJump"]))
    end)
    self:SetWndClick(self.mItemAddBtn, function()
        local refId = self._heroChangeShowItem
        if self._pageIndex == 2 then
            refId = self._heroDiSplaceShowItem
        end
        self:OpenGetWayWnd(refId)
    end)
    self:SetWndClick(self.mPage4ItemAddBtn, function()
        local itemId = self._pageIndex == 2 and self._heroReturnShowItem or self._heroReturnShowItem1
        self:OpenGetWayWnd(itemId)
    end)
    self:SetWndClick(self.mAutoUpStarBtn, function()
        self:OnClickAutoUpStarFunc()
    end)
    self:SetWndClick(self.mBtnProb, function()
         GF.OpenWnd("UIYellHRew", {viewType = 7})
    end)
end
function UISagaSpirit:OnClickAutoUpStarFunc()
    local allSelHeroList, status = gModelHeroSpirit:GetAutoUpStarHeroList()
    if status then
        local func = function()
            gModelHero:OnHeroUpStarReq(allSelHeroList, 1)
        end

        local refId = 50909
        local alertId = refId
        local isAlert = gModelGeneral:FindAlertId(alertId)
        if isAlert then
            if func then
                func()
            end
        else
            GF.OpenWnd("UIOnetarTip", { refId = refId, func = func })
        end
    else
        GF.ShowMessage(ccClientText(14451))
    end
end
function UISagaSpirit:Page1Event()
    if table.isempty(self._selectHeroList) then
        GF.ShowMessage(ccClientText(14425))
    else
        if self._sendMsg then
            return
        end
        local func = function()
            self:ShowCommonTip()
        end
        local haveMaxStar = false
        local maxStarHeroList = {}
        for k, v in pairs(self._selectHeroList) do
            if v.star >= self._heroSacrificeCautionStar then
                if not haveMaxStar then
                    haveMaxStar = true
                end
                local heroData = {
                    id = v.id,
                    refId = v.refId,
                    star = v.star,
                    grade = v.grade,
                    lv = v.lv,
                    fightPower = v.fightPower,
                    skin = v.skin,
                }
                --{star = star,refId = v.refId,id = id,sacrificeGetItem = v.sacrificeGetItem,grade = grade,lv = lv,refId = refId,fightPower = v.fightPower,skin = v.skin}
                table.insert(maxStarHeroList, { itype = 2, heroData = heroData, num = 1 })
                --table.insert(maxStarHeroList,{itype = 2,heroId = k,num = 1})
            end
        end
        if haveMaxStar then
            local wndId = 50908
            gModelGeneral:OpenUIOrdinTips({ func = func, refId = wndId, itemList = maxStarHeroList, para = { self._heroSacrificeCautionStar } })
            --local openFunc = function()
            --	GF.OpenWnd("UIOrdinTip",{func = func,refId = wndId,itemList = maxStarHeroList,para = {self._heroSacrificeCautionStar}})
            --end
            --gModelGeneral:ShowUIOrdinTip(wndId,func,openFunc)
        else
            func()
        end
    end
end
function UISagaSpirit:OnDrawSelHeroRewardCell(list, item, itemdata, itempos, fromHeadTail)
    local refId = itemdata.refId
    local num = itemdata.num
    local iconTrans = CS.FindTrans(item, "CommonUI/Icon")
    local instanceId = item:GetInstanceID()
    self:CreateConsumeIcon(iconTrans, instanceId, LItemTypeConst.TYPE_ITEM, refId, num)
    self:SetWndClick(iconTrans, function()
        self:OpenItemTips(refId, num)
    end)
end
function UISagaSpirit:OnDrawSelHeroCell(list, item, itemdata, itempos, fromHeadTail)
    local id = itemdata.id
    local iconTrans = CS.FindTrans(item, "CommonUI/Icon")
    local instanceId = item:GetInstanceID()

    self:SetPlayerHeroIcon(iconTrans, instanceId, id, false, false, false, false)

    self:SetWndClick(iconTrans, function()
        local index = table.keysize(self._selectHeroList)
        if self._uiSelHeroList then
            self._uiSelHeroList:DelDataByKey(id)
        end
        self._selectHeroList[id] = nil
        index = index - 1
        if index <= 0 then
            self:RefreshSelectList(index)
        end
        self:ShowSelectTxt(index)
        if self._uiSelHeroList then
            self._uiSelHeroList:RefreshList()
        end
        self:RefreshSelectHeroRewardList()
        self:RefreshListById(id)
    end)
end
function UISagaSpirit:CreateSpineFunc(refId, id, spinePos, scaleNum, star, other)
    if self._pbKey ~= nil and self._pbKey ~= refId and other ~= 2 then
        local curPb = self:FindWndSpineByKey(self._pbKey)
        if curPb then
            CS.ShowObject(curPb:GetDisplayTrans(), false)
        end
    end
    if other ~= 2 then
        self._pbKey = refId
        local spine = self:FindWndSpineByKey(refId)
        if not spine then
            local pbName = gModelHero:GetHeroPrefabNameById(id)
            if not pbName then
                LogError("---- 没有找到动画")
                pbName = "Jianshi"
            end
            self:CreateWndSpine(spinePos, pbName, refId, false, function(spine)
                spine:PlayAnimation(0, "idle", true)
                spine:SetScale(scaleNum)
                if self._page == 3 then
                    self:ClickHeroUI(spine, refId)
                end
            end)
        else
            CS.ShowObject(spine:GetDisplayTrans(), true)
            if self._page == 3 then
                self:ClickHeroUI(spine, refId)
            end
        end
    else
        local pbName = gModelHero:GetHeroPrefabNameByRefId(refId, star)
        if not pbName then
            LogError("---- 没有找到动画 refId = " .. refId .. ", star = " .. star)
            pbName = "Jianshi"
        end
        self:CreateWndSpine(spinePos, pbName, "otherHeroPbName", false, function(spine)
            spine:PlayAnimation(0, "idle", true)
            spine:SetScale(scaleNum)
            if self._page == 3 then
                self:ClickHeroUI(spine, refId)
            end
        end)
    end
end
function UISagaSpirit:ReSetData()
    gModelHero:ClearUpStarSelHeroList()
    self._selectHeroList = {}
    self._sacrificeData = {}
    self._fuseData = {}
    self._convertData = {}
    self._rebirthData = {}
end
function UISagaSpirit:InitMsg()
    self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
        gModelHero:OnHeroRebornInfoReq()
    end)
    self:WndEventRecv(EventNames.NET_ERROR_CODE, function(code, error, argList)
        local heroReturnPbId = LProtoHelper.GetProtoId("HeroReturnResp")
        local heroRebornPbId = LProtoHelper.GetProtoId("HeroRebornResp")

        self._sendMsg = false
    end)
    self:WndNetMsgRecv(LProtoIds.HeroSacrificeResp, function()
        self._sendMsg = false
        self:SelectHeroList(3)
    end)
    --[[	self:WndNetMsgRecv(LProtoIds.HeroMergeResp,function()
		self._sendMsg = false
		GF.ShowMessage(ccClientText(10019))
		local tab = {optType = 1,id = self._selectHeroId}
		GF.OpenWnd("UISagaUpOpt",tab)
		self:ClearPage2Data(self._selectHeroId)
		if self._uiBtnList then self._uiBtnList:RefreshList() end
		self:InitScrollView(true)
	end)]]
    self:WndNetMsgRecv(LProtoIds.HeroUpStarResp, function(pb, ret)
        self._sendMsg = false
        GF.ShowMessage(ccClientText(10019))
        local type = pb.type
        if type == 0 then
            local heroIds = pb.heroIds
            local first = heroIds[1]
            if first then
                local tab = { optType = 1, id = first }
                GF.OpenWnd("UISagaUpOpt", tab)
            end
        end
        if self._selectHeroId then
            self:ClearPage2Data(self._selectHeroId)
        end
        if self._uiBtnList then
            self._uiBtnList:RefreshList()
        end
        self:InitScrollView(true)
        if self._page == 2 then
            self:RefreshAutoUpStarRedPoint()
        end
    end)
    self:WndNetMsgRecv(LProtoIds.HeroTransformResp, function(pb)
        if pb.operate == 2 then
            GF.ShowMessage(ccClientText(14433))
        end
        self._sendMsg = false
        local heroId = pb.heroId
        local serverData = gModelHero:GetHeroServerDataById(heroId)
        if serverData then
            local nextRefId = serverData.nextRefId
            if nextRefId == 0 then
                local effectKey = "fx_huobanzhuanhuan"
                self:DestroyWndEffectByKey(effectKey)
                self._selectHeroList[self._selectHeroId] = {}
                self:ClickHeroIcon3(serverData, true)
            else
                self._selectHeroList[self._selectHeroId].nextRefId = nextRefId
                self:RefreshPage3Card(serverData.id, serverData.refId, serverData.star, nextRefId, serverData.lv, true)
            end
        end
        self:InitScrollView(true)
    end)
    self:WndNetMsgRecv(LProtoIds.HeroRebornInfoResp, function()
        self._sendMsg = false
        self:ShowRebornTxt()
    end)
    self:WndNetMsgRecv(LProtoIds.HeroDisplaceResp, function(pb)
        GF.ShowMessage(ccClientText(14434))
        self._sendMsg = false
        --[[		self:ClearPage2Data(self._selectHeroId,true)
		self._selectHeroId = nil
		self._selectHeroList = {}]]
        local heroId = pb.heroId
        local serverData = gModelHero:GetHeroServerDataById(heroId)
        if serverData then
            self:RefreshPage3Card(serverData.id, serverData.refId, serverData.star, serverData.nextRefId, serverData.lv)
        end
        CS.ShowObject(self.mChangHeroIcon, false)
        CS.ShowObject(self.mNoChangHeroIcon, true)
        CS.ShowObject(self.mPage3NoHeroPb2, true)
        self:RefreshListById(heroId)
    end)
    self:WndNetMsgRecv(LProtoIds.HeroRebornResp, function(pb)
        self._sendMsg = false
        self:ClearPage4Txt()
        self:ClearPage2Data(self._selectHeroId)
        self._selectHeroId = nil
        self._selectHeroList = {}
        self:Refresh(true)
    end)
    self:WndNetMsgRecv(LProtoIds.HeroReturnResp, function(pb)
        self._sendMsg = false
        self:ClearPage4Txt()
        self:ClearPage2Data(self._selectHeroId)
        self._selectHeroId = nil
        self._selectHeroList = {}
        self:Refresh(true)
    end)
    self:WndNetMsgRecv(LProtoIds.HeroRebirthResp, function(pb)
        self._sendMsg = false
        self:ClearPage4Txt()
        self:ClearPage2Data(self._selectHeroId)
        self._selectHeroId = nil
        self._selectHeroList = {}
        self:Refresh(true)
    end)
    self:WndNetMsgRecv(LProtoIds.HeroRemoveFormationResp, function()
        self._sendMsg = false
        self:InitScrollView(true)
        self._clickHeroId = nil
    end)
    self:WndNetMsgRecv(LProtoIds.ResonanceHeroResp, function()
        self._sendMsg = false
        self:InitScrollView(true)
        self._clickHeroId = nil
    end)
    self:WndNetMsgRecv(LProtoIds.HeroLockResp, function()
        self._sendMsg = false
        self._clickHeroId = nil
        local id = self._selectHeroId
        if id and self._selectHeroList[id] then
            gModelHero:ClearUpStarSelHeroList()
            self:InitScrollView(true)
            self._selectHeroList[id].appointList = nil
            self._selectHeroList[id].appNeedInfo = nil
            self._selectHeroList[id].rangList = nil
            self._selectHeroList[id].rangItemList = nil
            self._selectHeroList[id].rangNeedInfo = nil
            self._selectHeroList[id].itemNeedInfo = nil
            self:InitHeroUpStarInfo(id, true)
        else
            self:InitScrollView(true)
        end
        --[[		if self._clickHeroId then if self._uiList then self._uiList:DrawItemByKey(self._clickHeroId) end end
		self._clickHeroId = nil]]
    end)
    self:WndNetMsgRecv(LProtoIds.ItemChangeResp, function()
        if self._page == 3 or self._page == 4 then
            self:GetHeroDiSplaceShow()
        end
        self:RefreshPage2List()
    end)
    self:WndNetMsgRecv(LProtoIds.HeroCoreInfoResp, function(pb)
        if self._page ~= 4 then
            return
        end
        local heroId = pb.heroId
        if self._selectHeroId ~= heroId then
            return
        end
        local serverData = gModelHero:GetHeroServerDataById(heroId)
        if not serverData then
            return
        end
        self:RefreshHeroIcon4(serverData)
    end)
    --[[	self:WndNetMsgRecv(LProtoIds.HeroAttributeResp,function(pb,ret)
		self._sendMsg = false
		if self._page == 4 and self._pageIndex == 2 then
			local heroId = pb.id
			if pb.playerId == gLGameLogin:GetPlayerId() and self._selectHeroId == heroId then
				local serverData = gModelHero:GetHeroServerDataById(heroId)
				if serverData then self:ClickHeroIcon4(serverData,true) end
			end
		end
	end)]]
end
--------------------------------------- 英雄列表头像点击事件 ---------------------------------------
function UISagaSpirit:ClickHeroIcon1(itemdata)
    local id = itemdata.id
    local index = table.keysize(self._selectHeroList)
    if self._selectHeroList[id] ~= nil then
        self._selectHeroList[id] = nil
        index = index - 1
        if self._uiSelHeroList then
            self._uiSelHeroList:DelDataByKey(id)
        end
    else
        if index >= self._selectHeroMaxNum then
            self:SelHeroMaxMsg()
            return
        end
        local star, refId, sacrificeGetItem, grade, lv, refId = itemdata.star, itemdata.refId, itemdata.sacrificeGetItem, itemdata.grade, itemdata.lv, itemdata.refId
        local data = { star = star, refId = refId, id = id, sacrificeGetItem = sacrificeGetItem, grade = grade, lv = lv, refId = refId, fightPower = itemdata.fightPower, skin = itemdata.skin }
        self._selectHeroList[id] = data
        index = index + 1
        if self._uiSelHeroList then
            self._uiSelHeroList:AddData(id, data)
        end
    end
    self:RefreshListById(id)
    if self._uiSelHeroList and index > 1 then
        self:ShowSelectTxt(index)
        self._uiSelHeroList:RefreshList()
        self:RefreshSelectHeroRewardList()
    else
        self:RefreshSelectList(index)
    end
end
function UISagaSpirit:SetTxt()
    self:SetWndText(self.mSacrificeSelTxt, ccClientText(14410))
    self:InitTextLineWithLanguage(self.mSacrificeSelTxt, -30)
    self:SetWndButtonText(self.mSelectBtn, ccClientText(14460))
    self:SetWndButtonText(self.mNoSelectBtn, ccClientText(14406))
    self:SetWndText(self.mXianjihuodeTxt, ccClientText(14409))
    self:SetWndText(self.mHeroShopBtnName, ccClientText(14411))
    self:SetWndText(self.mAutoUpStarBtnName, ccClientText(14452))
    ---------------------------------------- 第三页取消分页功能，暂时不改 ----------------------------------------
    self:SetWndText(self.mPage3NoSelBtn1Name, ccClientText(14403))
    self:SetWndText(self.mPage3SelBtn1Name, ccClientText(14403))
    self:SetWndText(self.mPage3NoSelBtn2Name, ccClientText(14412))
    self:SetWndText(self.mPage3SelBtn2Name, ccClientText(14412))
    ---------------------------------------- 第三页取消分页功能，暂时不改 ----------------------------------------
    self:SetWndTabText(self.mPage4NoSelBtn1, ccClientText(14404))
    self:SetWndTabText(self.mPage4NoSelBtn2, ccClientText(14417))
    self:SetWndTabText(self.mPage4NoSelBtn3, ccClientText(14449))

    self:SetWndText(self.mYulanBtnName, ccClientText(10106))
    self:SetWndButtonText(self.mPage3CancelBtn, ccClientText(14422))
    self:SetWndButtonText(self.mPage3EnterBtn, ccClientText(14423))
    self:SetWndText(self.mPage4yulanTxt, ccClientText(14419))
    self:SetTextTile(self.mBtnProb, ccClientText(21813))
    --self:SetWndText(self.mPage2DescTxt,ccClientText(14447))

    --[[    local tItemId = 180005
        local name = gModelItem:GetNameByRefId(tItemId)
        local uiHyperText = UIHyperText:New()
        uiHyperText:Create(self.mPage2DescTxt)
        local text = uiHyperText:AddHyper(name, { func = function()
            self:OpenGetWayWnd(tItemId)
        end })
        text = string.replace(ccClientText(14453), text)
        self:SetWndText(self.mPage2DescTxt, text)]]

    self:SetWndText(self.mPage3DescTxt, ccClientText(14448))
    if self._isOpenDay then
        local str = string.replace(ccClientText(14418), GameTable.CharacterConfigRef["heroLevelRebornFree"])
        self:SetWndText(self.mPage4FreeTxt, str)
    end
    local show = self._isOpenDay and self._page == 4 and self._pageIndex == 1
    CS.ShowObject(self.mPage4FreeTxt, show)

    self:InitTextLineWithLanguage(self.mPage4FreeTxt, -30)
end

function UISagaSpirit:SetPlayerHeroIcon(iconTrans, instanceId, itemId, bNotShowLv, bShowGou, bShowStatus, bShowMask)
    local commonUIList = self._commonUIList
    local uiIconClass = commonUIList[instanceId]
    if not uiIconClass then
        uiIconClass = CommonIcon:New()
        commonUIList[instanceId] = uiIconClass
        uiIconClass:Create(iconTrans)
        self:SetIconClickScale(iconTrans, true)
    end

    uiIconClass:SetHeroPlayer(itemId)

    uiIconClass:SetNoShowLv(bNotShowLv)
    uiIconClass:SetShowGouImg(bShowGou)
    uiIconClass:SetShowStatus(bShowStatus)
    uiIconClass:SetShowMaskOnly(bShowMask)

    uiIconClass:DoApply()

    return uiIconClass
end

function UISagaSpirit:SetConsumeHeroIcon(iconTrans, instanceId, refId, star, showMask, bRace, needNum, selNum)
    local commonUIList = self._commonUIList
    local uiIconClass = commonUIList[instanceId]
    if not uiIconClass then
        uiIconClass = CommonIcon:New()
        commonUIList[instanceId] = uiIconClass
        uiIconClass:Create(iconTrans)
        self:SetIconClickScale(iconTrans, true)
    end

    if bRace then
        uiIconClass:SetRaceData({ id = refId, refId = refId, star = star, race = refId, needNum = needNum, num = selNum,hideTree = true })
    else
        uiIconClass:SetHeroDataSet({ id = refId, refId = refId, star = star, level = 1,hideTree = true })
        if needNum and selNum then
            uiIconClass:SetSelHeroNum(selNum, needNum)
        end
    end
    uiIconClass:SetShowMaskOnly(showMask)
    uiIconClass:EnableShowNum(true)
    uiIconClass:DoApply()

    return uiIconClass
end
function UISagaSpirit:CreatePage4ItemList(itemData)
    local uiList = self._uiPage4ItemList
    if not uiList then
        uiList = UIListEasy:New()
        uiList:Create(self, self.mPage4ItemList)
        uiList:EnableScroll(true, true)
        uiList:SetFuncOnItemDraw(function(...)
            self:OnDrawPage4ItemCell(...)
        end)
        self._uiPage4ItemList = uiList
    end
    uiList:RemoveAll()
    local index = 1
    for i, v in ipairs(itemData) do
        if v.itype == 2 then
            for _i = 1, v.num do
                uiList:AddData(index, v)
                index = index + 1
            end
        else
            uiList:AddData(index, v)
            index = index + 1
        end
    end
    uiList:RefreshList()
end
function UISagaSpirit:ClickHeroIcon2(itemdata)
    local oldId = self._selectHeroId
    local id, star, starRef = itemdata.id, itemdata.star, itemdata.starRef
    local isempty = self:ClearPage2Data(id)                -- 已选中的，取消选中
    if oldId then
        self:RefreshListById(oldId)
    end
    if not isempty then
        return
    end
    self._selectHeroId = id
    self:RefreshListById(id)
    self._selectHeroList[id] = {}
    self._selectHeroList[id].refId = itemdata.refId
    self._selectHeroList[id].skin = itemdata.skin
    if starRef then
        local maxStar = itemdata.maxStar
        local nextStar = star + 1
        local upStarLimit
        if maxStar < nextStar then
            upStarLimit = self._heroUpStarLimit[star]
        else
            upStarLimit = self._heroUpStarLimit[nextStar]
        end
        if upStarLimit then
            local isLimit = self._resonanceLevel < upStarLimit
            self._isLimit = isLimit
            self._upStarLimit = upStarLimit
            CS.ShowObject(self.mSacrificeBtn, not isLimit)
            CS.ShowObject(self.mNoUpHeroStatusTxt, isLimit)
            if isLimit then
                local limitStar = string.replace(ccClientText(14724), self._upStarLimit)
                self:SetWndText(self.mNoUpHeroStatusTxt, limitStar)
            end
            self:SetWndImageGray(self.mSacrificeBtn, isLimit)
        else
            self._isLimit = false
            CS.ShowObject(self.mSacrificeBtn, true)
            CS.ShowObject(self.mNoUpHeroStatusTxt, false)
            self:SetWndImageGray(self.mSacrificeBtn, false)
        end
        self._selectHeroList[id].star = nextStar

        self:SetPlayerHeroIcon(self.mHeroIconCur, self.mHeroIconCur:GetInstanceID(), id, false, false, false, false)

        self:InitHeroUpStarInfo()
        self:GetNameAndTypeImg(id, self.mPage2TypeImg, self.mPage2HeroName, nextStar, self._page2HeroStarList)

        --这里判断下 显示哪个
        if nextStar > 10 then
            CS.ShowObject(self.mPage2StarList, false)
            CS.ShowObject(self.mHightStarNewHeroInfo_Page2, true)
            self:SetWndText(self.mHightStarNewHeroInforText_Page2, nextStar - 10)
        else
            CS.ShowObject(self.mPage2StarList, true)
            CS.ShowObject(self.mHightStarNewHeroInfo_Page2, false)
        end

        local refId = starRef.type
        self:CreateSpineFunc(refId, id, self.mPage2PbPos, 1.5, nextStar, 1)
        self:RefreshListById(id)
    end

    --  增加提示语的地方

    local isEnought207, msg_207 = gModelHero:CheckHeroConditon207(id)

    CS.ShowObject(self.mNeedStarHeroTips, not isEnought207)
    self:SetWndText(self.mNeedStarHeroTips, msg_207)
end

function UISagaSpirit:SetHeroDataIcon(iconTrans, instanceId, heroData)
    local commonUIList = self._commonUIList
    local uiIconClass = commonUIList[instanceId]
    if not uiIconClass then
        uiIconClass = CommonIcon:New()
        commonUIList[instanceId] = uiIconClass
        uiIconClass:Create(iconTrans)
        self:SetIconClickScale(iconTrans, true)
    end

    uiIconClass:SetHeroDataSet(heroData)
    uiIconClass:DoApply()

    return uiIconClass
end
--------------------------------------- 按钮列表 ---------------------------------------
function UISagaSpirit:InitBotBtnList()
    local uiList = self._uiBtnList
    if not uiList then
        uiList = UIListEasy:New()
        uiList:Create(self, self.mTypeBtnList)
        uiList:EnableScroll(false, true)
        uiList:SetFuncOnItemDraw(function(...)
            self:OnDrwaBtnItem(...)
        end)
        self._uiBtnList = uiList
    end
    uiList:RemoveAll()
    for i, v in ipairs(self._botTxtList) do
        if v then
            uiList:AddData(i, { index = i, name = v })
        end
    end
    for i, v in ipairs(self._bgList) do
        CS.ShowObject(v, self._page == i)
    end
    uiList:RefreshList()
end
function UISagaSpirit:HideBuildRedPoint()
    if self._page == 2 then
        gModelRedPoint:OnClickFunc(16200200)
    end
end
--------------------------------------- 动画处理 ---------------------------------------
function UISagaSpirit:CreateAni()

end
function UISagaSpirit:OnDrawPage4ItemCell(list, item, itemdata, itempos, fromHeadTail)
    local rootTrans = self:FindWndTrans(item, "Root")
    local itemIconTrans = CS.FindTrans(rootTrans, "CommonUI")
    if itemIconTrans then
        local itype, refId, num = itemdata.itype, itemdata.refId, itemdata.num
        --printInfoNR("============ refId = "..refId)
        if not itype then
            itype = 1
        end
        local iconTrans = CS.FindTrans(itemIconTrans, "Icon")
        local instanceId = item:GetInstanceID()

        self:CreateConsumeIcon(iconTrans, instanceId, itype, refId, num)

        self:SetWndClick(iconTrans, function()
            if itype == 1 then
                self:OpenItemTips(refId, num)
            end
            if itype == 2 then
                gModelGeneral:OpenHeroSimpleTip(refId, true)
            end
            if itype == 4 then
                local serverData = gModelRune:GetServerDataById(itemdata.id)
                if serverData then
                    local data = { runeData = serverData }
                    gModelGeneral:OpenRuneInfoTip(data)
                end
            end
        end)
    end
end
function UISagaSpirit:RefreshPage3Card(id, refId, star, nextRefId, lv, isNetWork)
    local curTypeTrans, curNameTrans, curStarList, curLvTrans, curPbPos
    local nextTypeTrans, nextNameTrans, nextStarList, nextLvTrans, nextPbPos
    if self._pageIndex == 1 then
        curStarList = { self.mHeroStar11, self.mHeroStar12, self.mHeroStar13, self.mHeroStar14, self.mHeroStar15 }
        curTypeTrans, curNameTrans, curLvTrans, curPbPos = self.mTypeImg1, self.mHeroCardName1, self.mHeroCardLv1, self.mHeroPb1
        nextStarList = { self.mHeroStar21, self.mHeroStar22, self.mHeroStar23, self.mHeroStar24, self.mHeroStar25 }
        nextTypeTrans, nextNameTrans, nextLvTrans, nextPbPos = self.mTypeImg2, self.mHeroCardName2, self.mHeroCardLv2, self.mHeroPb2
    else
        curStarList = { self.mHeroStar31, self.mHeroStar32, self.mHeroStar33, self.mHeroStar34, self.mHeroStar35 }
        curTypeTrans, curNameTrans, curLvTrans, curPbPos = self.mTypeImg3, self.mHeroCardName3, self.mHeroCardLv3, self.mHeroPb3
        nextStarList = { self.mHeroStar41, self.mHeroStar42, self.mHeroStar43, self.mHeroStar44, self.mHeroStar45 }
        nextTypeTrans, nextNameTrans, nextLvTrans, nextPbPos = self.mTypeImg4, self.mHeroCardName4, self.mHeroCardLv4, self.mHeroPb4
    end
    self:GetNameAndTypeImg(id, curTypeTrans, curNameTrans, star, curStarList)
    self:CreateSpineFunc(refId, id, curPbPos, 1.3, star, 1)
    LxResUtil.DestroyChildImmediate(nextPbPos)
    local str = ccClientText(14421)
    local temp = string.replace(str, lv)
    self:SetWndText(curLvTrans, temp)
    for i, v in ipairs(self._page3SendMsgBtnList) do
        CS.ShowObject(v, nextRefId ~= 0)
    end
    if self._pageIndex == 1 then
        CS.ShowObject(self.mSacrificeBtn, nextRefId == 0)
        CS.ShowObject(self.mPage3PayDiv, nextRefId == 0)
    end
    local starData
    if self._pageIndex == 1 then
        starData = self._zhuanhuanData.star
    else
        starData = self._zhihuanData.star
    end
    local itemRefId, itemNum
    for i, v in ipairs(starData) do
        if itemRefId and itemNum then
            break
        end
        if v.heroStar == star then
            itemRefId, itemNum = v.refId, v.num
        end
    end
    if itemRefId and itemNum then
        local itemImg = gModelItem:GetItemIconByRefId(itemRefId)
        self:SetWndEasyImage(self.mChangePayItemIcon, itemImg)
        self:SetWndText(self.mChangPayItemNum, itemNum)
        if self._pageIndex == 1 then
            CS.ShowObject(self.mChangePayItemIcon, nextRefId == 0)
            CS.ShowObject(self.mChangPayItemNum, nextRefId == 0)
        else
            CS.ShowObject(self.mChangePayItemIcon, true)
            CS.ShowObject(self.mChangPayItemNum, true)
        end
    end
    self._selectHeroList[id].itemNum = itemNum
    self._selectHeroList[id].itemRefId = itemRefId
    local tempList = { nextTypeTrans, nextNameTrans, nextPbPos, nextLvTrans }
    for i, v in ipairs(tempList) do
        CS.ShowObject(v, nextRefId ~= 0)
    end
    for i, v in ipairs(nextStarList) do
        CS.ShowObject(v, nextRefId ~= 0)
    end
    CS.ShowObject(self.mPage3NoHeroPb1, nextRefId == 0)
    if nextRefId ~= 0 then
        self:GetNameAndTypeImg(id, nextTypeTrans, nextNameTrans, star, nextStarList, nextRefId)
        local effectKey = "fx_huobanzhuanhuan"
        self:DestroyWndEffectByKey(effectKey)
        if isNetWork then
            self:CreateWndEffect(self.mHeroPbEff2, effectKey, effectKey, 100)
        end
        self:CreateSpineFunc(nextRefId, id, nextPbPos, 1.3, star, 2)
        temp = string.replace(str, lv)
        self:SetWndText(nextLvTrans, temp)
    else
        self:GetNameAndTypeImg(id, nextTypeTrans, nextNameTrans, star, nextStarList, nextRefId)
        if self._pageIndex == 1 then
            local typeId = gModelHero:GetTypeById(id)
            local typeImg = gModelHero:GetRaceImgByRefId(typeId)
            if typeImg then
                self:SetWndEasyImage(self.mTypeImg2, typeImg)
            end
            CS.ShowObject(self.mTypeImg2, true)
            self:SetWndText(self.mHeroCardName2, ccClientText(14435))
            CS.ShowObject(self.mHeroCardName2, true)
        else
            self:SetWndText(self.mHeroCardName4, ccClientText(14435))
            CS.ShowObject(self.mHeroCardName4, true)
        end
    end
    if self._pageIndex == 2 then
        self._selectHeroList[id] = { refId = refId, star = star, needStar = 5, selectList = {} }
        local dataList = self._selectHeroList[id]
        for i, v in ipairs(self._zhihuanData.star) do
            if v.heroStar == star then
                dataList.needItemRefId, dataList.needItemNum, dataList.needHeroNum = v.refId, v.num, v.heroNum
            end
        end
        dataList.func = function(show, selectRefId)
            --for i,v in ipairs(tempList) do CS.ShowObject(v,show) end
            CS.ShowObject(nextTypeTrans, show)
            if not show then
                self:SetWndText(nextNameTrans, ccClientText(14435))
            end
            CS.ShowObject(self.mHeroPb4, show)
            CS.ShowObject(self.mPage3NoHeroPb2, not show)
            LxResUtil.DestroyChildImmediate(nextPbPos)
            CS.ShowObject(self.mNoChangHeroIcon, not show)
            CS.ShowObject(self.mChangHeroIcon, show)
            if show then
                self:GetNameAndTypeImg(selectRefId, tempList[1], tempList[2], star, nextStarList, selectRefId)
                self:CreateSpineFunc(selectRefId, id, self.mHeroPb4, 1.3, star, 2)
                local lvStr = string.replace(ccClientText(14421), lv)
                self:SetWndText(nextLvTrans, lvStr)

                self:CreateConsumeIcon(self.mChangHeroIcon, self.mChangHeroIcon:GetInstanceID(), LItemTypeConst.TYPE_HERO, selectRefId, 1)

                self:SetWndClick(self.mChangHeroIcon, function()
                    self:Page3SelectHero()
                end)
            else
                --for i,v in ipairs(nextStarList) do CS.ShowObject(v,false) end
            end
        end
        self:ShowSelectHeroNumTxt(0, dataList.needHeroNum)
    end
end
function UISagaSpirit:HeroUnLock(heroId)
    local func = function()
        self._clickHeroId = heroId
        gModelHero:OnHeroLockReq(heroId, 1)
    end
    gModelHeroSpirit:HeroUnLockOpt({ func = func })
end
function UISagaSpirit:RefreshPage2List()
    if self._page == 2 then
        local selectHeroList = self._selectHeroList
        if not selectHeroList then
            return
        end
        local selectHeroId = self._selectHeroId
        if not selectHeroId then
            return
        end
        local selectInfo = selectHeroList[selectHeroId]
        if not selectInfo then
            return
        end
        local appointList = selectInfo.appointList
        local rangList = selectInfo.rangList
        if not appointList or not rangList then
            return
        end
        local uiList = self._uiPage2ItemList
        if uiList then
            uiList:RefreshList()
        end
    end
end
function UISagaSpirit:ClickHeroIcon3(itemdata, refresh)
    local id, refId, star, nextRefId, lv = itemdata.id, itemdata.refId, itemdata.star, itemdata.nextRefId, itemdata.lv
    if self:NoChangeHero(refresh) then
        return
    end
    self:DestroyWndSpinetAll()
    CS.ShowObject(self.mSelectHeroChange1Show, self._pageIndex == 1)
    CS.ShowObject(self.mSelectHeroChange2Show, self._pageIndex == 2)
    local oldId = self._selectHeroId
    local isempty = self:ClearPage2Data(id)                -- 已选中的，取消选中
    if oldId then
        self:RefreshListById(oldId)
    end
    if self._pageIndex == 2 then
        if isempty then
            CS.ShowObject(self.mNoChangHeroIcon, true)
            CS.ShowObject(self.mPage3NoHeroPb2, true)
        else
            CS.ShowObject(self.mSelectHeroChange2Show, false)
        end
    else
        CS.ShowObject(self.mSelectHeroChange1Show, isempty)
        CS.ShowObject(self.mChangePayItemIcon, isempty)
        CS.ShowObject(self.mChangPayItemNum, isempty)
    end
    gModelHero:ClearUpStarSelHeroList()
    CS.ShowObject(self.mChangHeroIcon, false)
    CS.ShowObject(self.mNoChangHeroIcon, true)
    if not isempty then
        self:CreatePageIndexPb(self._pageIndex)
        return
    end
    self._selectHeroId = id
    self._selectHeroList[id] = {}
    self._selectHeroList[id].nextRefId = nextRefId
    self:RefreshPage3Card(id, refId, star, nextRefId, lv)
    self:RefreshListById(id)
end
function UISagaSpirit:RefreshHeroIcon4(itemdata)
    local id, refId, star, lv = itemdata.id, itemdata.refId, itemdata.star, itemdata.lv
    self._selectHeroId = id
    self._selectHeroList[id] = {}
    self._selectHeroList[id].lv = lv
    self._selectHeroList[id].star = star
    local heroStruct = gModelHero:GetHeroById(id)
    local rebornNeed, maxLv, returnStar = {}
    if self._pageIndex == 1 then
        rebornNeed = gModelHero:GetPayItemNum(itemdata)
        self._selectHeroList[id].fixReward = rebornNeed
    elseif self._pageIndex == 2 or self._pageIndex == 3 then
        local race = gModelHero:GetTypeById(id)
        local returnType = self._pageIndex == 2 and ModelHeroSpirit.RETURN_TYPE_1 or ModelHeroSpirit.RETURN_TYPE_2
        local heroRefId = gModelHero:GetRefIdById(id)
        local heroRef = gModelHero:GetHeroRef(heroRefId)
        local superHero = heroRef.superHero

        local reData = gModelHeroSpirit:GetHeroReturnData(race, star, returnType, superHero)
        if not table.isempty(reData) then
            local tItemList = table.clone(reData.fixReward)
            local itemKeyList = {}
            local itemType, itemId
            for i, v in ipairs(tItemList) do
                itemType, itemId = v.itemType, v.refId
                local itemTypeInfo = itemKeyList[itemType]
                if not itemTypeInfo then
                    itemTypeInfo = {}
                    itemKeyList[itemType] = itemTypeInfo
                end
                local itemIdInfo = itemTypeInfo[itemId] or 0
                itemTypeInfo[itemId] = itemIdInfo + v.num
            end
            rebornNeed = {}
            for tItemType, tItemTypeInfo in pairs(itemKeyList) do
                for tItemId, tItemNum in pairs(tItemTypeInfo) do
                    table.insert(rebornNeed, {
                        itemType = tItemType,
                        refId = tItemId,
                        num = tItemNum,
                    })
                end
            end

            returnStar = reData.returnStar
            table.insert(rebornNeed, { itype = 2, refId = refId, num = reData.getNoumenonNum, returnStar = returnStar })
        else
            LogError("============= HeroReturnRef没有找到对应的数据  :" .. race .. "," .. star)
            local heroReturnReachStarList = string.split(GameTable.CharacterConfigRef["heroReturnReachStar"], ",")
            returnStar = tonumber(heroReturnReachStarList[1]) or 6
            rebornNeed = {}
        end
        local retStarRef = gModelHero:GetStarRefById(id, returnStar)
        local retMaxLevel = retStarRef.maxLevel
        local payLvData = {}
        if retMaxLevel <= lv then
            maxLv = retMaxLevel
            payLvData = gModelHero:GetPayItemNumByStarAndEndLv(id, retMaxLevel, lv, maxLv, returnStar)
        else
            maxLv = lv
            payLvData = gModelRune:GetRuneUpItemList(id, maxLv, returnStar)
        end
        for i, v in ipairs(payLvData) do
            table.insert(rebornNeed, v)
        end

        --添加觉醒回退，并排序
        local awakenData = gModelHero:GetAwakenFixReward(id)
        if #awakenData > 0 then
            for i, v in ipairs(awakenData) do
                table.insert(rebornNeed, v)
            end

            local itemReward = {}
            local tempReward = {}
            for k, v in ipairs(rebornNeed) do
                local itemType = v.itype
                if not itemType or itemType == 1 then
                    local itemRefId = v.refId
                    if not itemReward[itemRefId] then
                        itemReward[itemRefId] = v
                    else
                        local oldNum = itemReward[itemRefId].num
                        itemReward[itemRefId].num = oldNum + v.num
                    end
                else
                    table.insert(tempReward, v)
                end
            end

            local resItemReward = {}
            for k, v in pairs(itemReward) do
                table.insert(resItemReward, v)
            end

            table.sort(resItemReward, function(a, b)
                return a.refId > b.refId
            end)

            for k, v in ipairs(tempReward) do
                table.insert(resItemReward, v)
            end

            rebornNeed = resItemReward
        end

        self._selectHeroList[id].need = reData.need
        self._selectHeroList[id].fixReward = rebornNeed
        self._selectHeroList[id].returnStar = returnStar
        self._selectHeroList[id].maxLv = maxLv
    end

    local showStar
    local showLv
    if self._pageIndex == 1 then
        showLv = 1
    else
        if maxLv then
            showLv = maxLv
        end
        local heroReturnReachStarList = string.split(GameTable.CharacterConfigRef["heroReturnReachStar"], ",")
        showStar = returnStar or tonumber(heroReturnReachStarList[1])
    end

    local heroSetData = {
        id = id,
        refId = heroStruct:GetRefId(),
        star = showStar or heroStruct:GetStar(),
        level = showLv or heroStruct:GetLv(),
        skin = heroStruct:GetSkin(),
        form = heroStruct:GetForm(),
        isResonance = heroStruct:GetResonanceStatus(),
    }
    self:SetHeroDataIcon(self.mPage4HeroIcon, self.mPage4HeroIcon:GetInstanceID(), heroSetData)

    local show = UISagaSpirit.TYPE_PAGE4_SHOW_PAY == 1 and true or false
    CS.ShowObject(self.mPage4PayIcon, show)
    CS.ShowObject(self.mPage4PayNum, show)
    if self._pageIndex == 1 and self._rebornNum ~= -1 then
        local curData = self._chongshengData.rebornNeed[self._rebornNum + 1]
        if not curData then
            local len = #self._chongshengData.rebornNeed
            curData = self._chongshengData.rebornNeed[len]
        end
        if curData then
            local curRefId, curNum = curData.refId, curData.num
            self._selectHeroList[id].need = { refId = curRefId, num = curNum }
            if self._isOpenDay then
                CS.ShowObject(self.mPage4PayIcon, false)
                CS.ShowObject(self.mPage4PayNum, false)
                self:SetWndButtonText(self.mSacrificeBtn, ccClientText(11913))
                --self:SetWndText(self.mSacrificeBtnName,ccClientText(11913))
            else
                self:ChangeItemInfo(curRefId, self.mPage4PayIcon, self.mPage4PayNum, curNum)
                CS.ShowObject(self.mPage4PayIcon, show)
                CS.ShowObject(self.mPage4PayNum, show)
                if show then
                    self:SetWndButtonText(self.mSacrificeBtn, "")
                end
                --self:SetWndText(self.mSacrificeBtnName,"")
            end
        else
            CS.ShowObject(self.mPage4PayIcon, false)
            CS.ShowObject(self.mPage4PayNum, false)
            --self:SetWndText(self.mSacrificeBtnName,ccClientText(14404))
        end
    elseif self._pageIndex == 2 then
        local curData = self._selectHeroList[id].need
        local curRefId, curNum = curData.refId, curData.num
        self:ChangeItemInfo(curRefId, self.mPage4PayIcon, self.mPage4PayNum, curNum, false)
        if show then
            self:SetWndButtonText(self.mSacrificeBtn, "")
        end
    end
    self:CreatePage4ItemList(rebornNeed)
    self:CreateSpineFunc(refId, id, self.mPage4PbPos, 1.3, star, 1)
    local starList = { self.mPage4Star1, self.mPage4Star2, self.mPage4Star3, self.mPage4Star4, self.mPage4Star5 }

    self:GetNameAndTypeImg(id, self.mPage4TypeImg, self.mPage4HeroName, star, starList)

    --这里判断下 显示哪个
    if star > 10 then
        CS.ShowObject(self.mPage4StarList, false)
        CS.ShowObject(self.mHightStarNewHeroInfo_Page4, true)
        self:SetWndText(self.mHightStarNewHeroInforText_Page4, star - 10)
    else
        CS.ShowObject(self.mPage4StarList, true)
        CS.ShowObject(self.mHightStarNewHeroInfo_Page4, false)
    end

    local lvStr = string.format("Lv.%s", lv)
    self:SetWndText(self.mPage4HeroLv, lvStr)
    self:RefreshListById(id)
end
function UISagaSpirit:GetHistory()
    local list = LWnd.GetHistory(self)
    local wndArgList = list.wndArgList
    wndArgList.page = self._page
    wndArgList.subPage = self._pageIndex
    return list
end
--------------------------------------- 献祭已选择的英雄列表 ---------------------------------------
function UISagaSpirit:RefreshSelectList(index)
    self:ShowSelectTxt(index)
    CS.ShowObject(self.mPage1SelDiv, index ~= 0)
    CS.ShowObject(self.mNoSelDiv1, index == 0)
    CS.ShowObject(self.mNoSelectBtn, index ~= 0)
    self:SetWndButtonGray(self.mSacrificeBtn, index == 0)
    local uiList = self._uiSelHeroList
    if not uiList then
        uiList = UIListEasy:New()
        uiList:Create(self, self.mSacrificeHeroList)
        uiList:EnableScroll(false, true)
        uiList:SetFuncOnItemDraw(function(...)
            self:OnDrawSelHeroCell(...)
        end)
        --uiList:EnableLoadAnimation(true, 0, 1)
        self._uiSelHeroList = uiList
    end
    uiList:RemoveAll()
    for k, v in pairs(self._selectHeroList) do
        uiList:AddData(k, v)
    end
    uiList:RefreshList()
    self:RefreshSelectHeroRewardList()
end
--------------------------------------- 文字显示 ---------------------------------------
function UISagaSpirit:SelHeroMaxMsg()
    GF.ShowMessage(string.replace(ccClientText(14420), self._selectHeroMaxNum))
end
function UISagaSpirit:ShowRebornTxt()
    local num = gModelHero:GetReborunNum()
    if not num then
        gModelHero:OnHeroRebornInfoReq()
    else
        self._rebornNum = num
        local allTimes = GameTable.CharacterConfigRef["heroLevelRebornNum"]
        local str = ""
        if allTimes ~= -1 then
            str = string.replace(ccClientText(14416), "0fb93f", allTimes - num)
        end
        self:SetWndText(self.mRebirthNum, str)
        CS.ShowObject(self.mRebirthNum, allTimes ~= -1)
    end
end
function UISagaSpirit:ChangPageData(index, init, subPage)
    gModelHero:ClearUpStarSelHeroList()
    self._isLimit = false
    self._selectHeroList = {}
    self._pbKey = nil
    self:HeroRaceBtnEvent(0, true)
    local changIndex = index or self._page
    local notDescList = self._notDescList
    local desc = notDescList[changIndex]
    self:SetWndText(self.mNoSelDesc, desc)
    if index then
        local trans = self._botBtnList[self._page]
        if trans then
            self:SetWndTabStatus(trans, 1)
        end
        --CS.ShowObject(self._botBtnList[self._page],false)
        self._page = index
        self:HideBuildRedPoint()
        trans = self._botBtnList[self._page]
        if trans then
            self:SetWndTabStatus(trans, 0)
        end
        --CS.ShowObject(self._botBtnList[self._page],true)
        for i, v in ipairs(self._bgList) do
            CS.ShowObject(v, self._page == i)
        end
    end
    local isOpen = gModelFunctionOpen:CheckIsOpened(16200500) or true
    local showBtn = isOpen and self._page == 2
    CS.ShowObject(self.mAutoUpStarBtn, showBtn)
    if showBtn then
        self:RefreshAutoUpStarRedPoint()
    end
    CS.ShowObject(self.mPage4PayIcon, false)
    CS.ShowObject(self.mPage4PayNum, false)
    CS.ShowObject(self.mNoUpHeroStatusTxt, false)
    if self._page ~= 3 and self._page ~= 4 then
        self:SetWndButtonText(self.mSacrificeBtn, self._btnTxtList[self._page])
    else
        self._pageIndex = 1
        if self._page == 4 then
            CS.ShowObject(self.mPage4PayDiv, false)
        end
        self:SetWndButtonText(self.mSacrificeBtn, self._btnTxtList[self._page][self._pageIndex])
        if subPage then
            local temp = subPage
            if self._page == 4 then
                temp = subPage + 2
            end
            self:ChangeTabData(temp)
        end
    end
    if self._page == 3 then
        self:GetHeroDiSplaceShow()
        CS.ShowObject(self.mChangePayItemIcon, false)
        CS.ShowObject(self.mChangPayItemNum, false)
    elseif self._page == 4 then
        self:ShowRebornTxt()
    end
    CS.ShowObject(self.mNoSelDiv1, self._page ~= 2)
    CS.ShowObject(self.mNoSelDiv2, self._page == 2)
    if not init then
        self:Refresh()
    end
    self:RefreshBtnHelp()
end
function UISagaSpirit:ShowSelectTxt(index)
    self:SetWndText(self.mYixuanzeTxt, string.replace(ccClientText(14408), index, self._selectHeroMaxNum))
end
function UISagaSpirit:DOPage4EventOpenWnCommonTips(heroId, isEnough, _refId, _num, showStar, heroStruct, wndId, itemList, returnStar, curStart)
    local func = function()
        if not self:IsWndValid() then
            return
        end
        if self._pageIndex == 1 then
            self._sendMsg = true
            gModelHero:OnHeroRebornReq(heroId)
        else
            if not isEnough then
                self._sendMsg = false
                self:OpenGetWayWnd(_refId)
            else
                self._sendMsg = true
                if self._pageIndex == 2 then
                    gModelHero:OnHeroReturnReq(heroId)
                elseif self._pageIndex == 3 then
                    gModelHeroSpirit:OnHeroRebirthReq(heroId)
                end
            end
        end
    end
    local leftFunc = function()

    end
    --local openFunc = function()
    --[[			local name = gModelItem:GetNameByRefId(_refId)
				local para
				if self._pageIndex == 1 then
					para = _num .. name
				else
					para = name .. "*" .. _num
				end]]
    --GF.OpenWnd("UIOrdinTip",{refId = wndId,itemList = itemList,func = func,leftFunc = leftFunc,closeFunc = leftFunc,para = {para,returnStar}})
    --end

    local consume = { _num, _refId }
    local name = gModelItem:GetNameByRefId(_refId)
    local para
    if self._pageIndex == 1 then
        para = _num .. name
        if self._isOpenDay then
            consume = nil
        end
    end
    --[[    if wndId == 50907 and _refId and _refId > 0 then
        end]]
    if _refId and _refId > 0 then
        curStart = gModelItem:GetNameByRefId(_refId) .. "*" .. LUtil.NumberCoversion(_num)
    end
    gModelGeneral:OpenUIOrdinTips({ refId = wndId, itemList = itemList, func = func, leftFunc = leftFunc, closeFunc = leftFunc,
                                      para = { curStart, returnStar }, consume = consume })
    --gModelGeneral:ShowUIOrdinTip(wndId,func,openFunc)
end
function UISagaSpirit:ClickHeroIcon4(itemdata, refresh)
    local id, refId, star, lv = itemdata.id, itemdata.refId, itemdata.star, itemdata.lv
    local heroAttrList, heroWearEquipList, heroWearRuneList, heroWearTalentList = gModelHero:GetHeroAttrAndEquipInfoById(id)
    if table.isempty(heroAttrList) then
        self._sendMsg = true
        self._selectHeroId = id
        gModelHero:OnHeroAttributeReq(id)
        return
    end
    local oldId = self._selectHeroId
    local isempty = self:ClearPage2Data(id)                -- 已选中的，取消选中
    if oldId then
        self:RefreshListById(oldId)
    end
    if refresh then
        isempty = true
    end
    if not isempty then
        self:ClearPage4Txt()
        return
    end
    self:RefreshHeroIcon4(itemdata)
end
------------------------------------------------------------------
function UISagaSpirit:CreateConsumeIcon(trans, instanceId, itemType, itemId, itemNum)
    local commonUIList = self._commonUIList
    local uiIconClass = commonUIList[instanceId]
    if not uiIconClass then
        uiIconClass = CommonIcon:New()
        commonUIList[instanceId] = uiIconClass
        uiIconClass:Create(trans)
        self:SetIconClickScale(trans, true)
    end

    uiIconClass:SetCommonReward(itemType, itemId, itemNum)
    uiIconClass:EnableShowNum(true)
    uiIconClass:DoApply()
    return uiIconClass
end
function UISagaSpirit:InitData()
    self._page = self:GetWndArg("page") or 1
    local subPage = self:GetWndArg("subPage")
    self._pageIndex = 1
    self:HideBuildRedPoint()
    self._botTxtList = { ccClientText(14401), ccClientText(14402), ccClientText(14403), ccClientText(14404) }
    --self._botTxtList = {ccClientText(14401),ccClientText(14402),ccClientText(14403)}
    self._btnTxtList = { ccClientText(14401), ccClientText(14402), { ccClientText(14403), ccClientText(14412) }, { ccClientText(14404), ccClientText(14417), ccClientText(14449) } }
    self._heroRaceBtnList = { self.mRaceBtn1, self.mRaceBtn2, self.mRaceBtn3, self.mRaceBtn4, self.mRaceBtn5 }
    self._heroRaceBtnSelList = { self.mRaceBtn1Sel, self.mRaceBtn2Sel, self.mRaceBtn3Sel, self.mRaceBtn4Sel, self.mRaceBtn5Sel, }
    self._notDescList = { ccClientText(14439), "", ccClientText(14440), ccClientText(14441) }
    self._page3DescList = { ccClientText(14440), ccClientText(14443) }
    self._page4DescList = { ccClientText(14441), ccClientText(14442), ccClientText(14450) }
    self._showLHList = { GameTable.CharacterConfigRef["heroSacrificeShowIcon"], "", GameTable.CharacterConfigRef["heroChangeShowIcon"], GameTable.CharacterConfigRef["heroLevelReborneShowIcon"] }
    self._showLHTabList = { GameTable.CharacterConfigRef["heroChangeShowIcon"], GameTable.CharacterConfigRef["heroDiSplaceShowIcon"], GameTable.CharacterConfigRef["heroLevelReborneShowIcon"], GameTable.CharacterConfigRef["heroReturnShowIcon"], GameTable.CharacterConfigRef["heroReturnShowIcon1"] }
    local heroChangeShowItem = GameTable.CharacterConfigRef["heroChangeShowItem"]
    heroChangeShowItem = string.split(heroChangeShowItem, "=")
    self._heroChangeShowItem = tonumber(heroChangeShowItem[2])
    local heroDiSplaceShowItem = GameTable.CharacterConfigRef["heroDiSplaceShowItem"]
    heroDiSplaceShowItem = string.split(heroDiSplaceShowItem, "=")
    self._heroDiSplaceShowItem = tonumber(heroDiSplaceShowItem[2])
    local heroReturnShowItem = GameTable.CharacterConfigRef["heroReturnShowItem"]
    heroReturnShowItem = string.split(heroReturnShowItem, "=")
    self._heroReturnShowItem = tonumber(heroReturnShowItem[2])
    local heroReturnShowItem1 = GameTable.CharacterConfigRef["heroReturnShowItem1"]
    heroReturnShowItem1 = string.split(heroReturnShowItem1, "=")
    self._heroReturnShowItem1 = tonumber(heroReturnShowItem1[2])
    self._xianjiData, self._rongheData, self._zhuanhuanData, self._zhihuanData, self._chongshengData, self._huituiData, self._zhuanshengData = gModelHeroSpirit:GetHeroSpiritData()
    self._heroRaceData = { self._xianjiData.race, self._rongheData.race, self._zhuanhuanData.race, self._chongshengData.race, }
    self._pageTransList = { self.mPage1, self.mPage2, self.mPage3, self.mPage4 }
    self._showPageList = { self.mPage1ShowDiv, self.mPage2BotShowDiv, self.mPage3ShowDiv, self.mPage4ShowDiv, }
    self._bgList = { self.mBg1, self.mBg2, self.mBg3, self.mBg4 }
    self._page34BtnList = { self.mPage3NoSelBtn1, self.mPage3NoSelBtn2, self.mPage4NoSelBtn1, self.mPage4NoSelBtn2, self.mPage4NoSelBtn3 }

    self._page2HeroStarList = { self.mPage2HeroStar1, self.mPage2HeroStar2, self.mPage2HeroStar3, self.mPage2HeroStar4, self.mPage2HeroStar5 }
    self._pageNoShowDiv = { self.mPage1SelDiv, self.mPage2ShowDiv, self.mSelectHeroChange1Show, self.mSelectHeroChange2Show, self.mPage4Show }
    self._page3SendMsgBtnList = { self.mPage3CancelBtn, self.mPage3EnterBtn }
    self._raceRedPointList = { self.mRace1redPoint, self.mRace2redPoint, self.mRace3redPoint, self.mRace4redPoint, self.mRace5redPoint }
    self._raceType = 0
    self._botBtnList = {}
    self._selThreeStar = true                -- 一键选择3星的
    self._autoSacrifice = gModelHero:GetAutoSacrificeStatus()
    self._selectHeroMaxNum = GameTable.CharacterConfigRef["heroSacrificeNum"]
    self._heroSacrificeCautionStar = GameTable.CharacterConfigRef["heroSacrificeCautionStar"]
    self._selectHeroList = {}
    self._selectHeroId = nil
    self._pbKey = nil
    self._clickHeroId = nil
    self._sendMsg = false            -- 防止手速党
    self._xianjiRewardList = {}
    self._rebornNum = 0
    self._isOpenDay = not gModelFunctionOpen:CheckServerOpen(GameTable.CharacterConfigRef["heroLevelRebornFree"], true) -- gLGameLogin:IsNew(GameTable.CharacterConfigRef["heroLevelRebornFree"])
    self._heroUpStarLimit = gModelHeroSpirit:GetUpStarLimit()
    self._resonanceLevel = gModelResonance:GetResonanceLv()
    self:ReSetData()
    return subPage
end

function UISagaSpirit:SetConsumeItemIcon(iconTrans, instanceId, iType, refId, needNum)
    local commonUIList = self._commonUIList
    local uiIconClass = commonUIList[instanceId]
    if not uiIconClass then
        uiIconClass = CommonIcon:New()
        commonUIList[instanceId] = uiIconClass
        uiIconClass:Create(iconTrans)
        self:SetIconClickScale(iconTrans, true)
    end
    uiIconClass:SetCommonReward(iType, refId, needNum or 1)
    uiIconClass:EnableShowNum(true)
    uiIconClass:ShowNeedNumStatus(true, true)
    uiIconClass:DoApply()

    return uiIconClass
end
--------------------------------------- 一键选择，一键取消，协议下发更新 ---------------------------------------
function UISagaSpirit:SelectHeroList(notSel)
    local index = 0
    local curNum = table.keysize(self._selectHeroList)
    if notSel == 1 then
        if curNum == self._selectHeroMaxNum then
            self:SelHeroMaxMsg()
            return
        else
            index = curNum
            if not table.isempty(self._heroData) then
                for i, v in ipairs(self._heroData) do
                    if index >= self._selectHeroMaxNum then
                        break
                    end
                    local id, star, status, grade, lv, refId = v.id, v.star, v.status, v.grade, v.lv, v.refId
                    if status == 0 then
                        if not self._selectHeroList[id] then
                            if self._selThreeStar then
                                if star <= 3 then
                                    index = index + 1
                                    self._selectHeroList[id] = { star = star, refId = v.refId, id = id, sacrificeGetItem = v.sacrificeGetItem, grade = grade, lv = lv, refId = refId, fightPower = v.fightPower, skin = v.skin }
                                    self:RefreshListById(id)
                                end
                            else
                                self._selectHeroList[id] = { star = star, refId = v.refId, id = id, sacrificeGetItem = v.sacrificeGetItem, grade = grade, lv = lv, refId = refId, fightPower = v.fightPower, skin = v.skin }
                                index = index + 1
                                self:RefreshListById(id)
                            end
                        end
                    end
                end
            end
        end
    elseif notSel == 0 then
        self._selectHeroList = {}
        self:RefreshListById(nil, 2)
    elseif notSel == 3 then
        self._selectHeroList = {}
        self:InitScrollView()
    end
    if index == 0 and notSel ~= 0 then
        self:RefreshListById(nil, 1)
    end
    if index == 0 and notSel == 1 then
        GF.ShowMessage(ccClientText(14430))
    end
    self:RefreshSelectList(index)
end
function UISagaSpirit:NoChangeHero(refresh)
    if self._pageIndex == 1 and self._selectHeroId and (not table.isempty(self._selectHeroList[self._selectHeroId])) and self._selectHeroList[self._selectHeroId].nextRefId ~= 0 then
        if not refresh then
            -- 策划说不给切换
            GF.ShowMessage(ccClientText(14431))
        end
        return true
    end
    return false
end
function UISagaSpirit:ShowCommonTip()
    if self._sendMsg then
        return
    end
    local wndId = 50903
    local func = function()
        self._sendMsg = true
        gModelHero:OnHeroSacrificeReq(self._selectHeroList)
        FireEvent(EventNames.ON_HERO_SACRIFICE)
    end
    gModelGeneral:OpenUIOrdinTips({ func = func, refId = wndId, itemList = self._xianjiRewardList, para = { table.keysize(self._selectHeroList) } })
    --local openFunc = function()
    --	GF.OpenWnd("UIOrdinTip",{func = func,refId = wndId,itemList = self._xianjiRewardList,para = {table.keysize(self._selectHeroList)}})
    --end
    --gModelGeneral:ShowUIOrdinTip(wndId,func,openFunc)
end
function UISagaSpirit:ChangeItemInfo(refId, iconTrans, numTrans, num, showStatus)
    if showStatus == nil then
        showStatus = true
    end
    local itemIcon = gModelItem:GetItemIconByRefId(refId)
    printInfoNR("itemIcon = " .. itemIcon .. ",refId = " .. refId)
    self:SetWndEasyImage(iconTrans, itemIcon)
    local haveNum = num or gModelItem:GetNumStrByRefId(refId)
    self:SetWndText(numTrans, haveNum)
    CS.ShowObject(iconTrans, showStatus)
    CS.ShowObject(numTrans, showStatus)
end
--------------------------------------- 英雄列表 ---------------------------------------
function UISagaSpirit:InitScrollView(network)
    --[[	local uiList = self._uiList
	if not uiList then
		uiList = UIListWrap:New()
		uiList:Create(self,self.mHeroList)
		uiList:SetItemOverflowRange(2000)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrawHeroCell(...)
		end)
		uiList:EnableLoadAnimation(true, 0, 1)
		self._uiList = uiList
	end
	uiList:RemoveAll()]]
    local heroRaceData = self._heroRaceData
    local pageRace = heroRaceData[self._page]
    if self._page == 3 then
        if self._pageIndex == 2 then
            pageRace = self._zhihuanData.race
        end
    elseif self._page == 4 then
        if self._pageIndex == 2 then
            pageRace = self._huituiData.race
        end
        if self._pageIndex == 3 then
            pageRace = self._zhuanshengData.race
        end
    end
    for i, v in ipairs(self._heroRaceBtnList) do
        CS.ShowObject(v, pageRace[i] ~= nil)
    end
    local heroList
    local data
    if self._page == 1 then
        --if self._selThreeStar then data = 3 end
        heroList = gModelHeroSpirit:GetHeroSortListBySpiritPage1(pageRace, data)
    elseif self._page == 2 then
        heroList = gModelHeroSpirit:GetHeroSortListBySpiritPage2(pageRace)
    elseif self._page == 3 then
        data = {}
        local list
        if self._pageIndex == 1 then
            list = self._zhuanhuanData.star
        end
        if self._pageIndex == 2 then
            list = self._zhihuanData.star
        end
        for k, v in pairs(list) do
            data[v.heroStar] = v.heroStar
        end
        heroList = gModelHeroSpirit:GetHeroSortListBySpiritPage3(pageRace, data)
    elseif self._page == 4 then
        if self._pageIndex == 1 then
            data = GameTable.CharacterConfigRef["heroLevelRebornMin"]
        end
        if self._pageIndex == 2 then
            data = string.split(GameTable.CharacterConfigRef["heroReturnReachStar"], ",")
        end
        if self._pageIndex == 3 then
            data = string.split(GameTable.CharacterConfigRef["heroReturnReachStar1"], ",")
        end
        --if data then data = tonumber(data) end
        heroList = gModelHeroSpirit:GetHeroSortListBySpiritPage4(pageRace, data, self._pageIndex)
    end
    self._heroData = {}
    self._dataKeyList = {}
    local noHero = {}
    local nextData
    local canCompoundList = {}
    local dataList = {}
    local dataKeyList = {}
    local keyIdx = 1
    local refId, id, hero, star
    local isInsDataList = false
    local isInsHeroDataList = false
    if heroList then
        local isAllRace = self._raceType == 0
        local index = 0
        for k, v in ipairs(heroList) do
            local isTry = v:IsTryHero()
            if not isTry then
                refId, id = v:GetRefId(), v:GetId()
                local ref = gModelHero:GetHeroRef(refId)
                local race = ref.raceType
                isInsDataList = false
                isInsHeroDataList = false
                hero = nil
                if self._page ~= 1 and self._page ~= 2 then
                    if self._raceType == 0 then
                        isInsDataList = true
                        dataKeyList[id] = keyIdx
                        keyIdx = keyIdx + 1
                        table.insert(noHero, k)
                    elseif race == self._raceType then
                        isInsDataList = true
                        dataKeyList[id] = keyIdx
                        keyIdx = keyIdx + 1
                        table.insert(noHero, k)
                    end
                    if isInsDataList then
                        hero = v:GetServerData()
                        table.insert(dataList, hero)
                    end
                    if v:GetNextRefId() ~= 0 then
                        nextData = v:GetServerData()
                    end
                else
                    isInsDataList = false
                    isInsHeroDataList = false
                    star = v:GetStar()
                    --local starId = gModelHero:GetStarId(starType,star)
                    local starRef = gModelHero:GetStarRefById(id)
                    if ref and starRef then
                        if isAllRace then
                            isInsDataList = true
                            isInsHeroDataList = true

                            dataKeyList[id] = keyIdx
                            keyIdx = keyIdx + 1
                            index = index + 1
                            table.insert(noHero, k)
                        elseif race == self._raceType then
                            isInsDataList = true
                            isInsHeroDataList = true

                            dataKeyList[id] = keyIdx
                            keyIdx = keyIdx + 1
                            index = index + 1
                            table.insert(noHero, k)
                        end
                        if isInsDataList or isInsHeroDataList then
                            hero = v:GetServerData()
                            local sacrificeGetItem = starRef.sacrificeGetItem
                            hero.maxStar = ref.maxStar
                            hero.sacrificeGetItem = sacrificeGetItem
                            hero.starRef = starRef
                        end
                        if isInsDataList then
                            table.insert(dataList, hero)
                        end
                        if isInsHeroDataList then
                            table.insert(self._heroData, hero)
                        end
                    end
                    if self._page == 2 then
                        if hero then
                            local isFuse, upStar = hero.isFuse, hero.upStar
                            if isFuse == 1 and upStar == 1 and not canCompoundList[race] then
                                canCompoundList[race] = true
                                if not canCompoundList[0] then
                                    canCompoundList[0] = true
                                end
                            end
                        else
                            if not isAllRace and self._raceType ~= race and not canCompoundList[race] then
                                local tHero = v:GetServerData()
                                if tHero.isFuse == 1 and tHero.upStar == 1 then
                                    canCompoundList[race] = true
                                    if not canCompoundList[0] then
                                        canCompoundList[0] = true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if self._page == 1 then
            self:SetWndText(self.mSacrificeNum, string.replace(ccClientText(14407), index))
            self:InitTextLineWithLanguage(self.mSacrificeNum, -30,false)
        end
        if self._page == 3 and (not table.isempty(nextData)) then
            self:ClickHeroIcon3(nextData)
        end
    end
    if self._page == 2 then
        for i, v in ipairs(self._raceRedPointList) do
            local isShow = canCompoundList[i] or false
            CS.ShowObject(v, isShow)
        end
        local allShow = canCompoundList[0] or false
        CS.ShowObject(self.mAllRaceredPoint, allShow)
    else
        for i, v in ipairs(self._raceRedPointList) do
            CS.ShowObject(v, false)
        end
        CS.ShowObject(self.mAllRaceredPoint, false)
    end
    local showNo = table.isempty(noHero)
    CS.ShowObject(self.mHeroList, not showNo)
    CS.ShowObject(self.mNoHeroBtn, showNo)
    CS.ShowObject(self.mNoHeroDesc, showNo)
    self._dataKeyList = dataKeyList
    local uiHeroList = self._uiHeroList
    if uiHeroList then
        local len = #dataList
        local isPage4 = self._page == 4
        local isPage2 = self._page == 2
        if network and len > 0 and not isPage4 and not isPage2 then
            uiHeroList:RefreshData(dataList)
        else
            uiHeroList:RefreshList(dataList)
            local uiList = uiHeroList:GetList()
            uiList:RefreshList(UIListWrap.RefreshMode.Solid)
        end
    else
        uiHeroList = self:GetUIScroll("uiHeroList")
        self._uiHeroList = uiHeroList
        uiHeroList:Create(self.mHeroList, dataList, function(...)
            self:OnDrawHeroCell(...)
        end, UIItemList.WRAP, false)
        uiHeroList:EnableLoadAnimation(true, 0, 1)
        local uiList = uiHeroList:GetList()
        uiList:RefreshList()
    end
end
--------------------------------------- 刷新 ---------------------------------------
function UISagaSpirit:RefreshPage(network)
    self:DestroyWndSpinetAll()
    CS.ShowObject(self.mPage3CancelBtn, false)
    CS.ShowObject(self.mPage3EnterBtn, false)
    CS.ShowObject(self.mSacrificeBtn, true)
    for i, v in ipairs(self._pageTransList) do
        CS.ShowObject(v, self._page == i)
    end
    CS.ShowObject(self.mSelectBtn, true)
    local data
    if self._page == 1 then
        data = self._sacrificeData
    elseif self._page == 2 then
        data = self._fuseData
    elseif self._page == 3 then
        data = self._convertData
    elseif self._page == 4 then
        data = self._rebirthData
    end
    for i, v in pairs(self._showPageList) do
        CS.ShowObject(v, i == self._page)
    end
    for i, v in ipairs(self._page34BtnList) do
        if i > 2 then
            local show = i - 2 == self._pageIndex and 0 or 1
            self:SetWndTabStatus(v, show)
        else
            local show = i == self._pageIndex and 0 or 1
            self:SetWndTabStatus(v, show)
        end
    end
    for i, v in ipairs(self._pageNoShowDiv) do
        CS.ShowObject(v, false)
    end
    local show = true
    if table.isempty(data) then
        show = false
    end
    self:SetWndButtonGray(self.mSacrificeBtn, not show)
    CS.ShowObject(self.mNoSelectBtn, show)
    CS.ShowObject(self.mHeroLHPos, not show)
    if not show then
        local pb = self._showLHList[self._page]
        if not string.isempty(pb) then
            self:CreateWndSpine(self.mHeroLHPos, pb, pb, false)
        end
    end
    self:InitScrollView(network)
end
------------------------------------------------------------------
function UISagaSpirit:OnTcpReconnect()
    self._sendMsg = false
    self:ReSetData()
    self:ChangPageData(self._page, true)
    self:Refresh()
end

return UISagaSpirit