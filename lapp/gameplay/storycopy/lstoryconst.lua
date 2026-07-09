---@class LStoryEventState
local LStoryEventState = LxClass("LStoryEventState",nil)

LStoryEventState.BEFORE = 1
LStoryEventState.RUNNING = 2
LStoryEventState.END = 3

---@class LStoryEventType
local LStoryEventType = LxClass("LStoryEventType",nil)

LStoryEventType.EFFECT_HERO = 121
LStoryEventType.EFFECT_SCENE = 122
LStoryEventType.EFFECT_UI_SPINE = 123
LStoryEventType.EFFECT_UI_FX = 124
LStoryEventType.EFFECT_GUIDE = 125 --开始指引

LStoryEventType.EFFECT_BUFF = 127 --buff特效


LStoryEventType.TEXT_SAY = 132
LStoryEventType.TEXT_SCREEN = 133
LStoryEventType.TEXT_INTRO = 134
LStoryEventType.TEXT_NORMAL = 135

LStoryEventType.SELECT = 141

LStoryEventType.CAMERA_SOLID = 151
LStoryEventType.CAMERA_FOLLOW = 152
LStoryEventType.CAMERA_SHAKE = 561
LStoryEventType.CAMERA_TIMELINE = 711



LStoryEventType.BLACK = 161
LStoryEventType.BLACK_END = 162 --结束跳转
LStoryEventType.RED = 163 --红屏
LStoryEventType.RENDER_GREY = 165 --全屏灰化


LStoryEventType.SPINE_BORN = 111
LStoryEventType.SPINE_BORN_SPECIAL = 112
LStoryEventType.SPINE_BUBBLE = 131
LStoryEventType.SPINE_DEAD = 211
LStoryEventType.SPINE_ACT = 311
LStoryEventType.SPINE_SKILL = 312
LStoryEventType.SPINE_MOVE = 411
LStoryEventType.SPINE_TIMELINE = 412
LStoryEventType.SPINE_MATERIAL = 126


LStoryEventType.START_AI = 511

LStoryEventType.EVENT_CLEAR = 611
LStoryEventType.PLAY_BATTLE = 171 --播放战报





---
--LStoryEventType.SPINE_PATH = 11

