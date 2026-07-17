let workspace = undefined;

function setClipboardText(text) {
    var textarea = document.createElement("textarea");
    textarea.value = text;

    // 将 textarea 元素添加到页面上
    document.body.appendChild(textarea);

    // 选择 textarea 中的文本
    textarea.select();

    // 复制文本到剪切板
    document.execCommand("copy");

    // 删除 textarea 元素
    document.body.removeChild(textarea);
}

function FormatGoogleBlock(block) {
    if (block.output) {
        block.output = null;
    } else {
        block.output = undefined;
    }
    if (block.previousStatement) {
        block.previousStatement = null;
    } else {
        block.previousStatement = undefined;
    }
    if (block.nextStatement) {
        block.nextStatement = null;
    } else {
        block.nextStatement = undefined;
    }
    return block;
}

function LoadNplToGoogleBlocklyConfig(npl_to_google_blockly_config)
{
    console.log(npl_to_google_blockly_config);
    if (!npl_to_google_blockly_config) return ;
    const block_map = {}
    const blocks_size = npl_to_google_blockly_config.blocks.length;
    for (let i = 0; i < blocks_size; i++) {
        const block = FormatGoogleBlock(npl_to_google_blockly_config.blocks[i]);
        block_map[block.type] = block;
    }
    window.google_block_map = block_map;
    workspace = Blockly.inject('GoogleBlockly', {
        media: 'https://unpkg.com/blockly/media/',
        toolbox: npl_to_google_blockly_config.toolbox
    });

    npl_to_google_blockly_config.workspace.blocks.blocks = npl_to_google_blockly_config.workspace.blocks.blocks || [];
    Blockly.defineBlocksWithJsonArray(npl_to_google_blockly_config.blocks);
    Blockly.serialization.workspaces.load(npl_to_google_blockly_config.workspace, workspace);

    window.save_workspace = function () {
        const state = Blockly.serialization.workspaces.save(workspace);
        // const json_state = JSON.stringify(state);
        // setClipboardText(json_state);
        console.log(state);
        if (window.NPLJSInstance) {
            window.NPLJSInstance.SendMsg("SaveGoogleWorkspace", { google_workspace : state});
        }
    }

    let save_workspace_timer = undefined;
    workspace.addChangeListener(function (event) {
        if (event.type == "toolbox_item_select") return ;
        if (save_workspace_timer) {
            clearTimeout(save_workspace_timer);
        }
        save_workspace_timer = setTimeout(function () {
            save_workspace_timer = undefined;
            save_workspace();
        }, 200);
    });
}

window.addEventListener("load", function () {
    if (window.NPLJSInstance) {
        NPLJSInstance.OnMsg("LoadNplToGoogleBlocklyConfig", (msgdata, msgid) => {
            LoadNplToGoogleBlocklyConfig(msgdata.google_blockly_config);
        });
    }
});


// window.addEventListener("load", function(){

// });


// <html>
// <?npl
// if (is_ajax()) then
//     local GoogleNplBlockly = NPL.load("script/ide/System/UI/Blockly/GoogleNplBlockly.lua");
//     add_action('wp_ajax_LoadNplToGoogleBlocklyConfig', function()	
//         wp_send_json({google_blockly_config = GoogleNplBlockly.m_google_blockly_config});
//     end)

//     add_action('wp_ajax_SaveGoogleWorkspace', function()
//     end)

//     return;
// end
// ?>

// <head>
//     <meta charset="utf-8"/>
//     <title>Google Blockly</title>
//     <!-- Load Blockly core -->
//     <script src="https://unpkg.com/blockly/blockly_compressed.js"></script>
//     <!-- Load the default blocks -->
//     <script src="https://unpkg.com/blockly/blocks_compressed.js"></script>
//     <!-- Load a generator -->
//     <script src="https://unpkg.com/blockly/javascript_compressed.js"></script>
//     <!-- Load a message file -->
//     <script src="https://unpkg.com/blockly/msg/en.js"></script>
// </head>

// <body>
//     <div id="GoogleBlockly" style="width: 100%; height: 100%;"></div>

//     <script>
// let workspace = undefined;

// function setClipboardText(text) {
//     var textarea = document.createElement("textarea");
//     textarea.value = text;

//     // 将 textarea 元素添加到页面上
//     document.body.appendChild(textarea);

//     // 选择 textarea 中的文本
//     textarea.select();

//     // 复制文本到剪切板
//     document.execCommand("copy");

//     // 删除 textarea 元素
//     document.body.removeChild(textarea);
// }

// function FormatGoogleBlock(block) {
//     if (block.output) {
//         block.output = null;
//     } else {
//         block.output = undefined;
//     }
//     if (block.previousStatement) {
//         block.previousStatement = null;
//     } else {
//         block.previousStatement = undefined;
//     }
//     if (block.nextStatement) {
//         block.nextStatement = null;
//     } else {
//         block.nextStatement = undefined;
//     }
//     return block;
// }

// function LoadNplToGoogleBlocklyConfig(npl_to_google_blockly_config)
// {
//     console.log(npl_to_google_blockly_config);
//     if (!npl_to_google_blockly_config) return ;
//     const block_map = {}
//     const blocks_size = npl_to_google_blockly_config.blocks.length;
//     for (let i = 0; i < blocks_size; i++) {
//         const block = FormatGoogleBlock(npl_to_google_blockly_config.blocks[i]);
//         block_map[block.type] = block;
//     }
//     window.google_block_map = block_map;
//     workspace = Blockly.inject('GoogleBlockly', {
//         media: 'https://unpkg.com/blockly/media/',
//         toolbox: npl_to_google_blockly_config.toolbox
//     });

//     npl_to_google_blockly_config.workspace.blocks.blocks = npl_to_google_blockly_config.workspace.blocks.blocks || [];
//     Blockly.defineBlocksWithJsonArray(npl_to_google_blockly_config.blocks);
//     Blockly.serialization.workspaces.load(npl_to_google_blockly_config.workspace, workspace);

//     window.save_workspace = function () {
//         const state = Blockly.serialization.workspaces.save(workspace);
//         // const json_state = JSON.stringify(state);
//         // setClipboardText(json_state);
//         console.log(state);
//         if (window.NPLJSInstance) {
//             window.NPLJSInstance.SendMsg("SaveGoogleWorkspace", { google_workspace : state});
//         }
//     }

//     let save_workspace_timer = undefined;
//     workspace.addChangeListener(function (event) {
//         if (save_workspace_timer) {
//             clearTimeout(save_workspace_timer);
//         }
//         save_workspace_timer = setTimeout(function () {
//             save_workspace_timer = undefined;
//             save_workspace();
//         }, 1000);
//     });
// }
// window.addEventListener("load", function () {
//     console.log($)        
// });
//     </script>
// </body>
// </html>