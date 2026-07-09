---
--- Created by Administrator.
--- DateTime: 2023/10/15 21:32:21
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEdenEnter:LWnd
local UIEdenEnter = LxWndClass("UIEdenEnter", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEdenEnter:UIEdenEnter()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEdenEnter:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEdenEnter:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEdenEnter:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

    self:SetStaticContent()

    self:InitWndPara()
    gModelWonderland:OnWonderlandRaceReq(0)

    self:InitUIEvent()
    self:InitEvent()

    self:RefreshUI()

end

function UIEdenEnter:ShowBuffList(themeBuff)
    local buffList = self._buffList
    if not buffList then
        buffList = self:GetUIScroll("buffList")
        self._buffList = buffList
        buffList:Create(self.mBuffList,themeBuff,function (...) self:OnDrawBuff(...) end)
    else
        buffList:RefreshList(themeBuff)
    end


end

function UIEdenEnter:OnClickStart()
    local enterFunc = self:GetWndArg("enterFunc")
    if enterFunc then
        enterFunc()
    end
    self:WndClose()
end

function UIEdenEnter:OnClickRefresh()

    if self._refreshCnt and self._refreshCnt > 0 then
        local curIndex = self._maxRefreshCnt - self._refreshCnt + 1
        local cost = gModelWonderland:GetRefreshCost("originRefreshExpend",curIndex)
        if cost then
            local itemNum = cost.itemNum
            if itemNum== 0 then
                gModelWonderland:OnWonderlandRaceReq(1)
            else
                local para =
                {
                    refId = 70013,
                    func = function()
                        gModelWonderland:OnWonderlandRaceReq(1)
                    end,
                    para = {itemNum},
                    consume = itemNum,
                }

                gModelGeneral:OpenUIOrdinTips(para)
            end

        end



    else
        local str =ccClientText(16784) --"没有次数了"
        GF.ShowMessage(str)
    end
end

function UIEdenEnter:InitEvent()
    self:WndNetMsgRecv(LProtoIds.WonderlandRaceResp,function (pb)
        self:OnWonderlandRaceResp(pb)

    end)
end

function UIEdenEnter:ShowRaceList(raceList)

    local raceUiList = self._raceUiList
    if not raceUiList then
        raceUiList = self:GetUIScroll("raceList")
        self._raceUiList = raceUiList
        raceUiList:Create(self.mRaceList,raceList,function (...) self:OnDrawRace(...) end)
    else
        raceUiList:RefreshList(raceList)
    end

end

function UIEdenEnter:OnDrawBuff(list,item,itemdata,itempos)
    local bg = self:FindWndTrans(item,"bg")
    local icon = self:FindWndTrans(item,"icon")


    local ref = gModelSkill:GetSkillRef(itemdata)
    if not ref then
        return
    end
    local iconPath = ref.icon
    self:SetWndEasyImage(icon,iconPath)

    self:SetWndClick(icon,function ()
        --GF.OpenWnd("UINewJNTip",{curSkillId = itemdata,wndType = 2})
        --GF.OpenWnd("UIBfTip",{refId = itemdata})
        gModelGeneral:OpenSkillWnd({curSkillId = itemdata,wndType = 2})
    end)

    local instanceId = item:GetInstanceID()
    self:CreateWndEffect(item,"ui_fx_jinengshaoguang",instanceId,80)
end

function UIEdenEnter:InitUIEvent()
    self:SetWndClick(self.mMask,function ()
        self:WndClose()
    end)

    self:SetWndClick(self.mBtnClose,function ()
        self:WndClose()
    end)

    self:SetWndClick(self.mStartBtn,function ()
        self:OnClickStart()
    end)

    self:SetWndClick(self.mRefresh,function ()
        self:OnClickRefresh()
    end)
end

function UIEdenEnter:InitWndPara()
    self._themeId = self:GetWndArg("themeId")
    self._themeCfg = gModelWonderland:GetThemeConfig(self._themeId)
end


function UIEdenEnter:SetStaticContent()
	local str =ccClientText(16786) --"深渊厄运"
    self:SetTextTile(self.mTitle1,str)
    str =ccClientText(16787) -- "种族限定"
    self:SetTextTile(self.mTitle2,str)

    str =ccClientText(16788) -- "前往探险"
    self:SetWndButtonText(self.mStartBtn,str,nil,-4)

    str = ccClientText(16789) --"通关深渊模式领取更多奖励!"
    self:SetWndText(self.mIntro,str)
end

function UIEdenEnter:OnWonderlandRaceResp(pb)
    self:ShowRaceList(pb.race)
    self:ShowBuffList(pb.themeBuff)

    local refreshCnt = pb.refreshCount or 0
    self._maxRefreshCnt = gModelWonderland:GetWonderlandPara("originRefreshNum")
    local text = self:FindWndTrans(self.mRefresh,"UIText")
    local maxRefreshCnt = gModelWonderland:GetWonderlandPara("originRefreshNum")
    local str = string.format("%s/%s",refreshCnt,maxRefreshCnt)
    self:SetWndText(text,str)

    self._refreshCnt = refreshCnt
    self._maxRefreshCnt = maxRefreshCnt
end

function UIEdenEnter:RefreshUI()
    local str =ccClientText(16785) --"梦境者，你当前选择的是%s-深渊模式,是否已经做好挑战准备"
    local themeCfg = self._themeCfg
    str = string.replace(str,ccLngText(themeCfg.name))
    self:SetWndText(self.mPost,str)
end

function UIEdenEnter:OnDrawRace(list,item,itemdata,itempos)
    local Image = self:FindWndTrans(item,"Image")

    local iconPath = gModelHero:GetRaceImgByRefId(itemdata)
    self:SetWndEasyImage(Image,iconPath)
end

------------------------------------------------------------------
return UIEdenEnter


