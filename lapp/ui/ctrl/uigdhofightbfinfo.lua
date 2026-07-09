---
--- Created by Administrator.
--- DateTime: 2024/6/20 19:44:37
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdHoFightBfInfo:LWnd
local UIGdHoFightBfInfo = LxWndClass("UIGdHoFightBfInfo", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdHoFightBfInfo:UIGdHoFightBfInfo()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdHoFightBfInfo:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdHoFightBfInfo:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdHoFightBfInfo:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    self:InitText()
    self:InitEvent()
    self:InitData()
    self:OpenReq()
    self:InitEffectShuichi()
end

function UIGdHoFightBfInfo:InitEffectShuichi()
    local instanceId = self.mImgChizi:GetInstanceID()
    self:CreateWndEffect(self.mImgChizi,"fx_ui_shengqizhufu_shuichi",instanceId,100,false,false,nil,nil,nil,nil,nil,nil,1)
 end

--region 页面初始化 --------------------------------------------------------------------------------
function UIGdHoFightBfInfo:InitEvent()
    self:WndEventRecv(gModelGuildHolyBattle.EventArgs.ChallengeDataChange, function()
        self:OnSelfInfo()
    end)


    --ui
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mClose, function()
        self:WndClose()
    end)
end

function UIGdHoFightBfInfo:OpenReq()

end

function UIGdHoFightBfInfo:SetBgSize(count)
    local countDownHight = count * 20
    local height =  self.mBuffBG.rect.height
    LxUiHelper.SetSizeWithCurAnchor(self.mBuffBG, 1, height - countDownHight)
    height =  self.mAttrBg.rect.height
    LxUiHelper.SetSizeWithCurAnchor(self.mAttrBg, 1, height - countDownHight)
end

function UIGdHoFightBfInfo:SetAttrShow(tran, des, icon, title)
    local titleTran = CS.FindTrans(tran, "Info_Title")
    self:SetWndText(titleTran, title)

    local count = 0
    for i = 1, 4 do
        local attrKey = "GameObject/Attr_" .. i
        local attrTran = CS.FindTrans(tran, attrKey)

        if des[i] then
            CS.ShowObject(attrTran, true)

            local iconTran = CS.FindTrans(attrTran, "Icon")
            self:SetWndEasyImage(iconTran, icon[i], nil, false)
            local baseAttrTran = CS.FindTrans(attrTran, "BaseAttr")
            self:SetWndText(baseAttrTran, des[i])

            if self._isVie then
                self:InitTextSizeWithLanguage(baseAttrTran, -10)
            else
                self:InitTextSizeWithLanguage(baseAttrTran, -6)
            end

            count = count + 1
        else
            CS.ShowObject(attrTran, false)
        end
    end
    self:SetBgSize(count)
end


--region 事件的回调 --------------------------------------------------------------------------------
--buff等级
function UIGdHoFightBfInfo:OnSelfInfo()
    --buffLevel 为 对应buff的 refid  相对应的等级为
    self._buffLevel = gModelGuildHolyBattle:GetBuff()
    local ref = gModelGuildHolyBattle:GetBuffRef(self._buffLevel)
    self._buffRealLevel = ref. level
    local buffCount = gModelGuildHolyBattle:GetBuffCount()

    self._isBuffLevelMax = self._buffLevel >= buffCount

    self:SetBuffShow()
end

function UIGdHoFightBfInfo:InitText()
    self:SetWndText(self.mTitle, ccClientText(44034))  --[44034] [聖騎祝福]
    self:SetWndText(self.mRewardTitle, ccClientText(44023))  --[44023] [獎勵預覽]
    self:SetWndText(self.mInfo_Title_1, ccClientText(18223))  --[18223]	[屬性加成]
    self:SetWndText(self.mRewardInfo, ccClientText(44033))  --[44033] [己方據點無法進攻]

end
--endregion --------------------------------------------------------------------------------------

--region 页面设置 --------------------------------------------------------------------------------
function UIGdHoFightBfInfo:SetBuffShow()
    CS.ShowObject(self.mNoFull, not self._isBuffLevelMax)
    CS.ShowObject(self.mFull, self._isBuffLevelMax)
    if self._isBuffLevelMax then
        local des, icon = gModelGuildHolyBattle:GetBuffDes(self._buffLevel)
        local title = string.replace(ccClientText(44035), self._buffRealLevel)-- [44035] [等級:#a1#（已達到最高等級）]
        self:SetAttrShow(self.mFull, des, icon, title)
    else


        local des, icon = gModelGuildHolyBattle:GetBuffDes(self._buffLevel)
        local title = string.replace(ccClientText(44036), self._buffRealLevel)-- [44036] [當前等級:#a1#]
        self:SetAttrShow(self.mCur, des, icon, title)

        local des, icon = gModelGuildHolyBattle:GetBuffDes(self._buffLevel + 1)
        local title = string.replace(ccClientText(44037), (self._buffRealLevel + 1))-- [44037] [下一等級:#a1#]
        self:SetAttrShow(self.mNext, des, icon, title)

    end
end

function UIGdHoFightBfInfo:InitData()
    self:OnSelfInfo()
end
--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIGdHoFightBfInfo