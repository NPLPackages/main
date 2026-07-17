
NPL.export({
    version = "0.0.0",
    language = "npl_junior",
    toolbox_xmltext = [[
        <toolbox>
        <category name="运动">
            <block type="NPL_moveForward"/>
            <block type="NPL_turn"/>
            <block type="NPL_turnTo"/>
            <block type="NPL_turnToTarget"/>
            <block type="NPL_walkForward"/>
            <block type="NPL_getX"/>
            <block type="NPL_getY"/>
            <block type="NPL_getZ"/>
        </category>
        <category name="外观">
            <block type="NPL_sayAndWait"/>
            <block type="NPL_tip"/>
            <block type="NPL_anim"/>
            <block type="NPL_play"/>
            <block type="NPL_playLoop"/>
            <block type="NPL_stop"/>
            <block type="NPL_scale"/>
            <block type="NPL_scaleTo"/>
            <block type="NPL_focus"/>
            <block type="NPL_camera"/>
            <block type="NPL_playMovie"/>
            <block type="NPL_window"/>
        </category>
        <category name="事件">
            <block type="NPL_registerClickEvent"/>
            <block type="NPL_registerKeyPressedEvent"/>
            <block type="NPL_registerBlockClickEvent"/>
            <block type="NPL_registerBroadcastEvent"/>
            <block type="NPL_broadcast"/>
            <block type="NPL_cmd"/>
        </category>
        <category name="控制">
            <block type="NPL_wait"/>
            <block type="NPL_repeat"/>
            <block type="NPL_forever"/>
            <block type="NPL_repeat_count_step"/>
            <block type="NPL_if_else"/>
            <block type="NPL_becomeAgent"/>
        </category>
        <category name="声音">
            <block type="NPL_playNote"/>
            <block type="NPL_playSound"/>
            <block type="NPL_playText"/>
        </category>
        <category name="感知">
            <block type="NPL_isTouching"/>
            <block type="NPL_askAndWait"/>
            <block type="NPL_answer"/>
            <block type="NPL_isKeyPressed"/>
            <block type="NPL_getBlock"/>
            <block type="NPL_setBlock"/>
        </category>
        <category name="运算">
            <block type="NPL_math_op"/>
            <block type="NPL_math_op_compare_number"/>
            <block type="NPL_random"/>
            <block type="NPL_math_compared"/>
            <block type="NPL_math_oneop"/>
        </category>
        <category name="数据">
            <block type="NPL_getLocalVariable"/>
            <block type="NPL_set"/>
            <block type="NPL_registerCloneEvent"/>
            <block type="NPL_clone"/>
            <block type="NPL_setActorValue"/>
            <block type="NPL_getString"/>
            <block type="NPL_getBoolean"/>
            <block type="NPL_getNumber"/>
            <block type="NPL_getColor"/>
            <block type="NPL_showVariable"/>
        </category>
    </toolbox>      
    ]]
})