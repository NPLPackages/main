
NPL.export({
    version = "1.0.1",
    language = "cad",
    toolbox_xmltext = [[
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
            <block type="scale"/>
            <block type="rotate"/>
            <block type="rotateFromPivot"/>
            <block type="moveNode"/>
            <block type="scaleNode"/>
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
})