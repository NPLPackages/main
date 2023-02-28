

local ToolBoxXmlText = NPL.export();

local npl_0_0_0 = [[
    <toolbox>
	<category name="运动">
		<block type="NPL_moveForward"/>
		<block type="NPL_turn"/>
		<block type="NPL_turnTo"/>
		<block type="NPL_turnToTarget"/>
		<block type="NPL_move"/>
		<block type="NPL_moveTo"/>
		<block type="NPL_moveToTarget"/>
		<block type="NPL_walk"/>
		<block type="NPL_walkForward"/>
		<block type="NPL_attachTo"/>
		<block type="NPL_velocity"/>
		<block type="NPL_bounce"/>
		<block type="NPL_getX"/>
		<block type="NPL_getY"/>
		<block type="NPL_getZ"/>
		<block type="NPL_getPos"/>
		<block type="NPL_setPos"/>
		<block type="NPL_getFacing"/>
		<block type="NPL_getPlayerPos"/>
		<block type="NPL_rotate"/>
		<block type="NPL_rotateTo"/>
	</category>
	<category name="外观">
		<block type="NPL_sayAndWait"/>
		<block type="NPL_say"/>
		<block type="NPL_tip"/>
		<block type="NPL_show"/>
		<block type="NPL_hide"/>
		<block type="NPL_anim"/>
		<block type="NPL_play"/>
		<block type="NPL_playAndWait"/>
		<block type="NPL_playLoop"/>
		<block type="NPL_playBone"/>
		<block type="NPL_playSpeed"/>
		<block type="NPL_stop"/>
		<block type="NPL_scale"/>
		<block type="NPL_scaleTo"/>
		<block type="NPL_focus"/>
		<block type="NPL_camera"/>
		<block type="NPL_get_camera"/>
		<block type="NPL_getScale"/>
		<block type="NPL_getPlayTime"/>
		<block type="NPL_setMovie"/>
		<block type="NPL_isMatchMovie"/>
		<block type="NPL_playMatchedMovie"/>
		<block type="NPL_playMovie"/>
		<block type="NPL_playMovieLoop"/>
		<block type="NPL_stopMovie"/>
		<block type="NPL_setMovieProperty"/>
		<block type="NPL_window"/>
	</category>
	<category name="事件">
		<block type="NPL_registerClickEvent"/>
		<block type="NPL_registerKeyPressedEvent"/>
		<block type="NPL_registerBlockClickEvent"/>
		<block type="NPL_registerTickEvent"/>
		<block type="NPL_registerAnimationEvent"/>
		<block type="NPL_registerBroadcastEvent"/>
		<block type="NPL_broadcast"/>
		<block type="NPL_broadcastAndWait"/>
		<block type="NPL_broadcastTo"/>
		<block type="NPL_registerStopEvent"/>
		<block type="NPL_registerAgentEvent"/>
		<block type="NPL_registerNetworkEvent"/>
		<block type="NPL_broadcastNetworkEvent"/>
		<block type="NPL_sendNetworkEvent"/>
		<block type="NPL_cmd"/>
	</category>
	<category name="控制">
		<block type="NPL_wait"/>
		<block type="NPL_repeat"/>
		<block type="NPL_forever"/>
		<block type="NPL_repeat_count"/>
		<block type="NPL_repeat_count_step"/>
		<block type="NPL_repeat_until"/>
		<block type="NPL_waitUntil"/>
		<block type="NPL_while_if"/>
		<block type="NPL_control_if"/>
		<block type="NPL_if_else"/>
		<block type="NPL_forKeyValue"/>
		<block type="NPL_forIndexValue"/>
		<block type="NPL_run"/>
		<block type="NPL_runForActor"/>
		<block type="NPL_exit"/>
		<block type="NPL_restart"/>
		<block type="NPL_becomeAgent"/>
		<block type="NPL_setOutput"/>
		<block type="NPL_break"/>
	</category>
	<category name="声音">
		<block type="NPL_playNote"/>
		<block type="NPL_playMusic"/>
		<block type="NPL_playSound"/>
		<block type="NPL_playSoundAndWait"/>
		<block type="NPL_stopSound"/>
		<block type="NPL_playText"/>
	</category>
	<category name="感知">
		<block type="NPL_isTouching"/>
		<block type="NPL_setName"/>
		<block type="NPL_setPhysicsRaidus"/>
		<block type="NPL_setPhysicsHeight"/>
		<block type="NPL_registerCollisionEvent"/>
		<block type="NPL_broadcastCollision"/>
		<block type="NPL_distanceTo"/>
		<block type="NPL_calculatePushOut"/>
		<block type="NPL_askAndWait"/>
		<block type="NPL_answer"/>
		<block type="NPL_isKeyPressed"/>
		<block type="NPL_isMouseDown"/>
		<block type="NPL_getMousePoint"/>
		<block type="NPL_mousePickBlock"/>
		<block type="NPL_getBlock"/>
		<block type="NPL_setBlock"/>
		<block type="NPL_timer"/>
		<block type="NPL_resetTimer"/>
		<block type="NPL_setMode"/>
		<block type="NPL_getMode"/>
	</category>
	<category name="运算">
		<block type="NPL_math_op"/>
		<block type="NPL_math_op_compare_number"/>
		<block type="NPL_math_op_compare"/>
		<block type="NPL_random"/>
		<block type="NPL_math_compared"/>
		<block type="NPL_not"/>
		<block type="NPL_join"/>
		<block type="NPL_string_contain"/>
		<block type="NPL_string_char"/>
		<block type="NPL_lengthOf"/>
		<block type="NPL_mod"/>
		<block type="NPL_round"/>
		<block type="NPL_math_oneop"/>
	</category>
	<category name="数据">
		<block type="NPL_getLocalVariable"/>
		<block type="NPL_assign"/>
		<block type="NPL_set"/>
		<block type="NPL_createLocalVariable"/>
		<block type="NPL_registerCloneEvent"/>
		<block type="NPL_clone"/>
		<block type="NPL_delete"/>
		<block type="NPL_setActorValue"/>
		<block type="NPL_getActorEntityValue"/>
		<block type="NPL_getActorValue"/>
		<block type="NPL_getActor"/>
		<block type="NPL_getString"/>
		<block type="NPL_getMultiLineString"/>
		<block type="NPL_getBoolean"/>
		<block type="NPL_getNumber"/>
		<block type="NPL_getColor"/>
		<block type="NPL_newEmptyTable"/>
		<block type="NPL_getTableValue"/>
		<block type="NPL_getArrayValue"/>
		<block type="NPL_defineFunction"/>
		<block type="NPL_callFunction"/>
		<block type="NPL_callFunctionWithReturn"/>
		<block type="NPL_showVariable"/>
		<block type="NPL_hideVariable"/>
		<block type="NPL_log"/>
		<block type="NPL_echo"/>
		<block type="NPL_include"/>
		<block type="NPL_gettable"/>
		<block type="NPL_inherit"/>
		<block type="NPL_saveUserData"/>
		<block type="NPL_loadUserData"/>
		<block type="NPL_saveWorldData"/>
		<block type="NPL_loadWorldData"/>
		<block type="NPL_code_block"/>
		<block type="NPL_code_comment"/>
		<block type="NPL_code_comment_full"/>
		<block type="NPL_List_Create"/>
		<block type="NPL_List_Insert"/>
		<block type="NPL_List_DeleteByIndex"/>
		<block type="NPL_List_DeleteAll"/>
		<block type="NPL_List_InsertByIndex"/>
		<block type="NPL_List_ReplaceByIndex"/>
		<block type="NPL_List_GetByIndex"/>
		<block type="NPL_List_GetIndexByItem"/>
		<block type="NPL_List_GetSize"/>
		<block type="NPL_List_ContainItem"/>
		<block type="NPL_List_Get"/>
	</category>
</toolbox>
]]

local cad_0_0_0 = [[
<toolbox>
<category name="Shapes">
    <block type="createNode"/>
    <block type="pushNode"/>
    <block type="pushNodeByName"/>
    <block type="cube"/>
    <block type="box"/>
    <block type="sphere"/>
    <block type="cylinder"/>
    <block type="cone"/>
    <block type="torus"/>
    <block type="prism"/>
    <block type="ellipsoid"/>
    <block type="wedge"/>
    <block type="trapezoid"/>
    <block type="importStl"/>
    <block type="importStl_2"/>
    <block type="plane"/>
    <block type="circle"/>
    <block type="ellipse"/>
    <block type="regularPolygon"/>
    <block type="polygon"/>
    <block type="text3d"/>
</category>
<category name="ShapeOperators">
    <block type="move"/>
    <block type="rotate"/>
    <block type="rotateFromPivot"/>
    <block type="moveNode"/>
    <block type="rotateNode"/>
    <block type="rotateNodeFromPivot"/>
    <block type="cloneNodeByName"/>
    <block type="cloneNode"/>
    <block type="deleteNode"/>
    <block type="fillet"/>
    <block type="getEdgeCount"/>
    <block type="chamfer"/>
    <block type="extrude"/>
    <block type="revolve"/>
    <block type="mirror"/>
    <block type="mirrorNode"/>
    <block type="deflection"/>
</category>
<category name="Control">
    <block type="repeat_count"/>
    <block type="control_if"/>
    <block type="if_else"/>
</category>
<category name="Math">
    <block type="math_op"/>
    <block type="random"/>
    <block type="math_compared"/>
    <block type="not"/>
    <block type="mod"/>
    <block type="round"/>
    <block type="math_oneop"/>
</category>
<category name="Data">
    <block type="getLocalVariable"/>
    <block type="createLocalVariable"/>
    <block type="assign"/>
    <block type="getString"/>
    <block type="getBoolean"/>
    <block type="getNumber"/>
    <block type="newEmptyTable"/>
    <block type="getTableValue"/>
    <block type="defineFunction"/>
    <block type="callFunction"/>
    <block type="code_comment"/>
    <block type="setMaxTrianglesCnt"/>
    <block type="jsonToObj"/>
    <block type="objToJson"/>
</category>
<category name="Skeleton">
    <block type="createJointRoot"/>
    <block type="createJoint"/>
    <block type="bindNodeByName"/>
    <block type="boneNames"/>
    <block type="rotateJoint"/>
    <block type="startBoneNameConstraint"/>
    <block type="setBoneConstraint_Name"/>
    <block type="setBoneConstraint_min"/>
    <block type="setBoneConstraint_max"/>
    <block type="setBoneConstraint_offset"/>
    <block type="setBoneConstraint_2"/>
    <block type="setBoneConstraint_3"/>
    <block type="setBoneConstraint_4"/>
    <block type="setBoneConstraint_5"/>
    <block type="setBoneConstraint_6"/>
</category>
<category name="Animation">
    <block type="createAnimation"/>
    <block type="addChannel"/>
    <block type="setAnimationTimeValue_Translate"/>
    <block type="setAnimationTimeValue_Scale"/>
    <block type="setAnimationTimeValue_Rotate"/>
    <block type="animationiNames"/>
</category>
</toolbox>
]]

local cad_1_0_0 = [[
<toolbox>
<category name="Shapes">
    <block type="createNode"/>
    <block type="pushNode"/>
    <block type="cube"/>
    <block type="box"/>
    <block type="sphere"/>
    <block type="cylinder"/>
    <block type="cone"/>
    <block type="torus"/>
    <block type="prism"/>
    <block type="ellipsoid"/>
    <block type="wedge"/>
    <block type="trapezoid"/>
    <block type="plane"/>
    <block type="circle"/>
    <block type="ellipse"/>
    <block type="regularPolygon"/>
    <block type="polygon"/>
    <block type="text3d"/>
    <block type="importStl"/>
</category>
<category name="ShapeOperators">
    <block type="move"/>
    <block type="rotate"/>
    <block type="rotateFromPivot"/>
    <block type="moveNode"/>
    <block type="rotateNode"/>
    <block type="rotateNodeFromPivot"/>
    <block type="cloneNodeByName"/>
    <block type="cloneNode"/>
    <block type="deleteNode"/>
    <block type="fillet"/>
    <block type="filletNode"/>
    <block type="getEdgeCount"/>
    <block type="chamfer"/>
    <block type="extrude"/>
    <block type="revolve"/>
    <block type="mirror"/>
    <block type="mirrorNode"/>
    <block type="deflection"/>
</category>
<category name="Control">
    <block type="repeat_count"/>
    <block type="control_if"/>
    <block type="if_else"/>
</category>
<category name="Math">
    <block type="math_op"/>
    <block type="random"/>
    <block type="math_compared"/>
    <block type="not"/>
    <block type="mod"/>
    <block type="round"/>
    <block type="math_oneop"/>
</category>
<category name="Data">
    <block type="getLocalVariable"/>
    <block type="createLocalVariable"/>
    <block type="assign"/>
    <block type="getString"/>
    <block type="getBoolean"/>
    <block type="getNumber"/>
    <block type="newEmptyTable"/>
    <block type="getTableValue"/>
    <block type="defineFunction"/>
    <block type="callFunction"/>
    <block type="code_comment"/>
    <block type="code_comment_full"/>
    <block type="setMaxTrianglesCnt"/>
    <block type="jsonToObj"/>
</category>
<category name="Skeleton">
    <block type="createJointRoot"/>
    <block type="createJoint"/>
    <block type="bindNodeByName"/>
    <block type="rotateJoint"/>
    <block type="startBoneNameConstraint"/>
    <block type="setBoneConstraint"/>
    <block type="setBoneConstraint_rotAxis"/>
    <block type="setBoneConstraint_hidden"/>
</category>
<category name="Animation">
    <block type="createAnimation"/>
    <block type="addChannel"/>
    <block type="setAnimationTimeValue_Translate"/>
    <block type="setAnimationTimeValue_Scale"/>
    <block type="setAnimationTimeValue_Rotate"/>
    <block type="animationiNames"/>
</category>
</toolbox>
]]

local npl_junior_1_0_0 = [[
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

local __xml_text_map__ = {
	["0.0.0"] = {
		["npl"] = npl_0_0_0,
		["cad"] = cad_0_0_0,
		["npl_junior"] = npl_junior_1_0_0,
	},
	
	["1.0.0"] = {
		["npl"] = npl_0_0_0,
		["cad"] = cad_1_0_0,
		["npl_junior"] = npl_junior_1_0_0,
	},
}

function ToolBoxXmlText.GetXmlText(language, version)
	language = string.lower(language or "");
	version = version or "1.0.0";  -- 默认使用最新版本
	local __xml_text_version_map__ = __xml_text_map__[version] or {};
    return __xml_text_version_map__[language] or "";
end
