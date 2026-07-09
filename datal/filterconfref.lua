local _keys = {refId=1,replaceConf=2}
local _mt = {
    __index = function(t, k)
        local idx = _keys[k]
        if not idx then return nil end
        return rawget(t, idx)
    end,
    __newindex = function(t, k)
    end
}
local _set = setmetatable
local _datas = {
FeatureOpenRef=_set({"FeatureOpenRef","FunctionOpenShieldRef"},_mt),
StorylineTriggerRef=_set({"StorylineTriggerRef","StoryTriggerShieldRef"},_mt),
StorylinePlotRef=_set({"StorylinePlotRef","StoryPlotShieldRef"},_mt),
StorySetRef=_set({"StorySetRef","StorySetShieldRef"},_mt),
StoryNewbieRef=_set({"StoryNewbieRef","StoryNewbieShieldRef"},_mt),
StoryTextRef=_set({"StoryTextRef","StoryTextShieldRef"},_mt),
NewPlayerGuidePrologueRef=_set({"NewPlayerGuidePrologueRef","GuidePrologueShieldRef"},_mt),
NewPlayerGuideConditionRef=_set({"NewPlayerGuideConditionRef","GuideConditionShieldRef"},_mt),
NewPlayerGuideEventRef=_set({"NewPlayerGuideEventRef","GuideEventShieldRef"},_mt),
NoviceStepsGuideRef=_set({"NoviceStepsGuideRef","NoviceStepsShieldRef"},_mt),
MainInstanceFunctionRef=_set({"MainInstanceFunctionRef","InstanceFunctionShieldRef"},_mt),
FeaturePreviewAllRef=_set({"FeaturePreviewAllRef","ForeshowAllShieldRef"},_mt),
CharacterStoryRef=_set({"CharacterStoryRef","HeroStoryShieldRef"},_mt)
}

return _datas