local _keys = {refId=1,NextChapterId=2,type=3,chapterNum=4,chapteNum1=5,name=6,chapterDes=7,chapterPic=8,firstInstanceId=9,storyId=10,coordinate=11,trafficType=12}
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
[1]=_set({1,2,1,"maininstancechapter_0_1",1,"maininstancechapter_1_1","maininstancechapter_2_1","chapter_bg_cb_202",10010,0,"",1},_mt),
[2]=_set({2,3,1,"maininstancechapter_0_2",2,"maininstancechapter_1_2","maininstancechapter_2_2","chapter_bg_cb_203",20010,0,"",1},_mt),
[3]=_set({3,4,1,"maininstancechapter_0_3",3,"maininstancechapter_1_3","maininstancechapter_2_3","chapter_bg_cb_201",30010,0,"",1},_mt),
[4]=_set({4,5,1,"maininstancechapter_0_4",4,"maininstancechapter_1_4","maininstancechapter_2_4","chapter_bg_cb_202",40010,0,"",1},_mt),
[5]=_set({5,6,1,"maininstancechapter_0_5",5,"maininstancechapter_1_5","maininstancechapter_2_5","chapter_bg_cb_205",50010,0,"",1},_mt),
[6]=_set({6,7,1,"maininstancechapter_0_6",6,"maininstancechapter_1_6","maininstancechapter_2_6","chapter_bg_cb_205",60010,0,"",1},_mt),
[7]=_set({7,8,1,"maininstancechapter_0_7",7,"maininstancechapter_1_7","maininstancechapter_2_7","chapter_bg_cb_202",70010,0,"",1},_mt),
[8]=_set({8,9,1,"maininstancechapter_0_8",8,"maininstancechapter_1_8","maininstancechapter_2_8","chapter_bg_cb_203",80010,0,"",1},_mt),
[9]=_set({9,10,1,"maininstancechapter_0_9",9,"maininstancechapter_1_9","maininstancechapter_2_9","chapter_bg_cb_201",90010,0,"",1},_mt),
[10]=_set({10,11,1,"maininstancechapter_0_10",10,"maininstancechapter_1_10","maininstancechapter_2_10","chapter_bg_cb_202",100010,0,"",1},_mt),
[11]=_set({11,12,1,"maininstancechapter_0_11",11,"maininstancechapter_1_11","maininstancechapter_2_11","chapter_bg_cb_205",110010,0,"",1},_mt),
[12]=_set({12,13,1,"maininstancechapter_0_12",12,"maininstancechapter_1_12","maininstancechapter_2_12","chapter_bg_cb_205",120010,0,"",1},_mt),
[13]=_set({13,14,1,"maininstancechapter_0_13",13,"maininstancechapter_1_13","maininstancechapter_2_13","chapter_bg_cb_202",130010,0,"",1},_mt),
[14]=_set({14,15,1,"maininstancechapter_0_14",14,"maininstancechapter_1_14","maininstancechapter_2_14","chapter_bg_cb_203",140010,0,"",1},_mt),
[15]=_set({15,16,1,"maininstancechapter_0_15",15,"maininstancechapter_1_15","maininstancechapter_2_15","chapter_bg_cb_201",150010,0,"",1},_mt),
[16]=_set({16,17,1,"maininstancechapter_0_16",16,"maininstancechapter_1_16","maininstancechapter_2_16","chapter_bg_cb_202",160010,0,"",1},_mt),
[17]=_set({17,18,1,"maininstancechapter_0_17",17,"maininstancechapter_1_17","maininstancechapter_2_17","chapter_bg_cb_205",170010,0,"",1},_mt),
[18]=_set({18,19,1,"maininstancechapter_0_18",18,"maininstancechapter_1_18","maininstancechapter_2_18","chapter_bg_cb_205",180010,0,"",1},_mt),
[19]=_set({19,20,1,"maininstancechapter_0_19",19,"maininstancechapter_1_19","maininstancechapter_2_19","chapter_bg_cb_202",190010,0,"",1},_mt),
[20]=_set({20,21,1,"maininstancechapter_0_20",20,"maininstancechapter_1_20","maininstancechapter_2_20","chapter_bg_cb_203",200010,0,"",1},_mt),
[21]=_set({21,22,1,"maininstancechapter_0_21",21,"maininstancechapter_1_21","maininstancechapter_2_21","chapter_bg_cb_201",210010,0,"",1},_mt),
[22]=_set({22,23,1,"maininstancechapter_0_22",22,"maininstancechapter_1_22","maininstancechapter_2_22","chapter_bg_cb_202",220010,0,"",1},_mt),
[23]=_set({23,24,1,"maininstancechapter_0_23",23,"maininstancechapter_1_23","maininstancechapter_2_23","chapter_bg_cb_205",230010,0,"",1},_mt),
[24]=_set({24,25,1,"maininstancechapter_0_24",24,"maininstancechapter_1_24","maininstancechapter_2_24","chapter_bg_cb_205",240010,0,"",1},_mt),
[25]=_set({25,26,1,"maininstancechapter_0_25",25,"maininstancechapter_1_25","maininstancechapter_2_25","chapter_bg_cb_202",250010,0,"",1},_mt),
[26]=_set({26,27,1,"maininstancechapter_0_26",26,"maininstancechapter_1_26","maininstancechapter_2_26","chapter_bg_cb_203",260010,0,"",1},_mt),
[27]=_set({27,28,1,"maininstancechapter_0_27",27,"maininstancechapter_1_27","maininstancechapter_2_27","chapter_bg_cb_201",270010,0,"",1},_mt),
[28]=_set({28,-1,1,"maininstancechapter_0_28",28,"maininstancechapter_1_28","maininstancechapter_2_28","chapter_bg_cb_202",280010,0,"",1},_mt)
}

return _datas