---
--- Created by Administrator.
--- DateTime: 2024/5/13 16:02:13
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaBaoYiDisPy:LWnd
local UISagaBaoYiDisPy = LxWndClass("UISagaBaoYiDisPy", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaBaoYiDisPy:UISagaBaoYiDisPy()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaBaoYiDisPy:OnWndClose()

    FireEvent(EventNames.UP_STAR_REFRESH_CLOTH)
    gModelGameHelper:RefreshGameSpeed()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaBaoYiDisPy:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaBaoYiDisPy:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:InitData()
    self:InitPanel()

    self:InitEvent()

    LxUiHelper.PlayAudioSoundName(36)
    gModelGameHelper:TemporaryCloseSpeed()
end

function UISagaBaoYiDisPy:InitEvent()
    self:SetWndClick(self.mMask, function(...)
        self:OnCloseClick()
    end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UISagaBaoYiDisPy:EndAni()
    self:TimerStop(self._effEndTimeKey)

    self:CreateSpine(self._newHeroEffect)
    local ref = gModelHero:GetShowEffectById(self._newHeroEffect)
    if ref and not string.isempty(ref.heroStarUpSound) then
        gLGameAudio:PlaySingleSound(ref.heroStarUpSound)
    end
end

function UISagaBaoYiDisPy:CreateSpine(refId)
    local effRef = gModelHero:GetShowEffectById(refId)
    if not effRef then
        return
    end

    local heroDrawing = effRef.heroDrawing
    local spine = self:FindWndSpineByKey(heroDrawing)

    self._isFirst = false
    if self._oldSpine then
        self._oldSpine:SetVisible(false)

    else
        --空的话 是第一次 那么就调用一次特效生成
        self._isFirst = true
    end

    if not spine then
        self._oldSpine = self:CreateWndSpine(self.mHeroLiHuiPos, heroDrawing, heroDrawing, false, function(spine)
            if self._isFirst then
                self:DestroyWndEffectByKey("fx_baoyi")
                self:CreateWndEffect(self.mRefreshClothEffectRoot, "fx_baoyi", "fx_baoyi", 100, false, false, 1, function(dpTrans)
                    dpTrans.gameObject:SetActive(true)
                    --刷新立绘
                    self:TimerStart(self._effEndTimeKey, 1, false, 1)
                end)
            end
        end)
    else
        spine:SetVisible(true)
    end
end

function UISagaBaoYiDisPy:InitData()
    self._oldHeroEffect = self:GetWndArg("oldRefId") or 1703
    self._newHeroEffect = self:GetWndArg("newRefId") or 170301

    self._effEndTimeKey = "_effEndTimeKey_UISagaBaoYiDisPy"
end

function UISagaBaoYiDisPy:OnCloseClick()
    self:WndClose()
end

function UISagaBaoYiDisPy:OnTimer(key)
    if key == self._effEndTimeKey then
        self:EndAni()

    end
end

function UISagaBaoYiDisPy:InitPanel()

    --加载第一个效果
    self:CreateSpine(self._oldHeroEffect)

end
------------------------------------------------------------------
return UISagaBaoYiDisPy