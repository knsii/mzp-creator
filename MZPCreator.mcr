macroScript MZPCreator
category:"NepreTool"
tooltip:"Create mzp package from .ms/mcr/mse/py file"
buttontext:"MZP"
icon:#("MZPCreator" ,1)
-- iconname:"NepreTool/MZPCreator"
(
    
    fn add_line &ref str inline:off = (
        ref += str as string
        if not inline do ref += "\n"
        return true
    )
    fn get_file_content path = (
        str = ""
        file = openfile path
        while not eof file do str += readline file + "\n"
        close file
        str
    )

    fn put_file_content str path = (
        local folder = getfilenamepath path
        if not doesfileexist folder do makedir folder all:true
        if not doesfileexist path do deletefile path
        local file = createfile path
        format str to:file
        close file
    )

    fn string_match str reg option:0 = (
        local results = #()
        local rx = dotnetclass "system.text.regularexpressions.regex"
        local matches = if option==0 then rx.match str reg else rx.match str reg option

        if not matches.success do  return undefined

        while matches.success do (
            local groups = for i = 1 to matches.groups.count - 1 collect matches.groups.item[i].value
            matches = matches.nextmatch()
            append results groups
        )
        results
    )

    fn empty_folder path = (
        local files = getfiles (pathconfig.appendpath path "*")
        for f in files do (
            -- avoid readonly file can't be deleted
            setfileattribute f #readonly false
            deletefile f
        )
    )

    local mzp_fl
    local opened = false
    fn update_floater_height statu rtl = (
        if opened do (
            local offset = (if statu then 1 else -1)*rtl.height
            mzp_fl.size = [mzp_fl.size.x,mzp_fl.size.y+offset]
        )
    )
    rollout setting_rl "setting" (
        edittext toolbar_txt "toolbar:" text:"Main Toolbar"
        on setting_rl rolledup state do (
            update_floater_height state setting_rl
        )
    )

    rollout mzp_creator_rl "mzp creator" (
        local __icon_image = undefined
        local __script_file = undefined
        local c_width = mzp_creator_rl.width - 20
        button choose_script_btn "choose script file" width:(c_width-40) height:30 align:#left across:2
        button choose_icon_btn "icon" width:30  height:30 align:#right

        label version_lab "version:" align:#left offset:[0, 2] across:2
        edittext version_txt "" width:(c_width - 80) align:#right

        label author_lab "author:" align:#left offset:[0, 2] across:2
        edittext author_txt "" width:(c_width - 80) align:#right
    
        label name_lab "script name:" align:#left offset:[0, 2] across:2
        edittext name_txt "" width:(c_width - 80) align:#right

        label button_text_lab "button text:" align:#left offset:[0, 2] across:2
        edittext button_text_txt "" width:(c_width - 80) align:#right
    
        label tooltip_lab "tooltip:" align:#left offset:[0, 2] across:2
        edittext tooltip_txt "" width:(c_width - 80) align:#right
    
        label category_lab "category:" align:#left offset:[0, 2] across:2
        edittext category_txt "" width:(c_width - 80) align:#right
    
        label extra_maxscript_lab "extra script:" align:#left offset:[0, 2] across:2
        edittext extra_maxscript_txt "" width:(c_width - 80) height:60 align:#right
        
        button create_btn "create" width:c_width
        on mzp_creator_rl rolledup state do (
            update_floater_height state mzp_creator_rl
        )
        on mzp_creator_rl open do (
            -- button images need manual clear
            choose_icon_btn.images = undefined
            __icon_image = undefined
        )
        on choose_script_btn pressed do (
            local script_path = getopenfilename caption:"choose script file:" types:"script file(*.ms,*.mcr,*.mse,*.py)|*.ms;*.mcr;*.mse;*.py)|all|*.*|"
            if script_path != undefined do (
                __script_file = script_path
                local script_name = getfilenamefile script_path
                local macro_name = ""
                local category = ""
                local tooltip = ""
                local button_name = ""

                local ignorecase = (dotnetclass "system.text.regularexpressions.regexoptions").ignorecase
                if (getfilenametype script_path) == ".mcr" then (
                    local script_string = get_file_content script_path
                    local script_string = get_file_content script_path
                    
                    local _mat = string_match script_string "macroscript\s+(\w+)\s" option:ignorecase
                    if _mat != undefined then macro_name = _mat[1][1]
                    
                    _mat = string_match script_string "buttontext:\s*\"(.*)\"" option:ignorecase
                    if _mat != undefined then button_name = _mat[1][1]
                    else button_name = macro_name
                    
                    _mat = string_match script_string "tooltip:\s*\"(.*)\"" option:ignorecase
                    if _mat != undefined then tooltip = _mat[1][1]
                   
                    _mat = string_match script_string "category:\s*\"(.*)\"" option:ignorecase
                    if _mat != undefined then category = _mat[1][1]
                    else category = macro_name
                )
                else (
                    macro_name = (dotnetobject "system.text.regularexpressions.regex" @"(\s)").replace script_name "_"
                    local _mat = string_match macro_name "([a-zA-Z]+[a-zA-Z0-9_]+)" option:ignorecase
                    if _mat != undefined do macro_name = _mat[1][1]
                    category = tooltip = button_name = script_name
                )

                choose_script_btn.text = filenamefrompath script_path
                name_txt.text = macro_name
                button_text_txt.text = button_name
                tooltip_txt.text = tooltip
                category_txt.text = category

            )
        )
        on choose_script_btn rightclick do (
            choose_script_btn.text = "choose script file"
            __script_file = undefined
        )
        on choose_icon_btn pressed do (
            img = selectbitmap  caption:"choose image for icon:"
            if img != undefined then (
                choose_icon_btn.images = #(img, undefined, 1,1,1,1,1 )
                __icon_image = img
            )
            else (
                choose_icon_btn.images = undefined
                __icon_image = undefined
            )
        )
        on choose_icon_btn rightclick do (
            choose_icon_btn.images = undefined
            __icon_image = undefined
        )
        
        on create_btn pressed do (
            -- check values
            local script_name = name_txt.text
            local error_text = ""
            if script_name == "" do (
                messageBox "script name is required" beep:false
                return false
            )

            local script_path = __script_file
            local script_file_name = ""
            local script_type = ""
            if __script_file != undefined do (
                local script_file_name = filenamefrompath script_path
                local script_type = getfilenametype script_path
            )

            local script_content = ""

            local mzp_run = ""

            local install_script = ""

            local temp_folder = pathconfig.appendpath (pathconfig.getdir #temp) "mzp_creator"

            -- clean temp folder
            empty_folder temp_folder


            local mcr_only = false
            if finditem  #(".ms",".py",".mse") script_type != 0 then (
                if script_type == ".py" then (
                    add_line &script_content ("python.ExecuteFile (pathconfig.appendpath (getdir #userscripts) \"" + script_file_name + "\")")

                )
                else (
                    add_line &script_content ("filein (pathconfig.appendpath (getdir #userscripts) \"" + script_file_name + "\")")
                )
                copyfile script_path (pathconfig.appendpath temp_folder script_file_name)
            )
            else if script_type == ".mcr" do (
                mcr_only = true
                local script_string = get_file_content script_path
                local _mat = string_match script_string "[^#]\((.*)\)" option:(dotnetclass "system.text.regularexpressions.regexoptions").singleline
                if _mat != undefined do script_content = _mat[1][1]
            )



            -- create icon
            local has_icon = false
            local has_icon_alpha = false
            if __icon_image != undefined do (
                has_icon = true
                local bmp_aspect = __icon_image.aspect
                local bmp_16i = bitmap 16 16 filename:(pathconfig.appendpath temp_folder (script_name+"_16i.bmp"))
                local bmp_24i = bitmap 24 24 filename:(pathconfig.appendpath temp_folder (script_name+"_24i.bmp"))
                copy __icon_image bmp_16i
                copy __icon_image bmp_24i
                save bmp_16i
                save bmp_24i
                if __icon_image.hasalpha do(
                    has_icon_alpha = true
                    local bmp_16a = bitmap 16 16 filename:(pathconfig.appendpath temp_folder (script_name+"_16a.bmp"))
                    local bmp_24a = bitmap 24 24 filename:(pathconfig.appendpath temp_folder (script_name+"_24a.bmp"))
                    fn mergealpha  c1 p1 c2 p2 = (
                        c2.v = c1.v
                        c2
                    )
                    pastebitmap bmp_16i bmp_16a  [0,0] [0,0] type:#function function:mergealpha
                    pasteBitmap bmp_24i bmp_24a  [0,0] [0,0] type:#function function:mergealpha
                    save bmp_16a
                    save bmp_24a
                )
            )


            -- create mcr file
            -- macro script info
            local macro_script = "-- author " + author_txt.text + "\n"
            add_line &macro_script ("macroscript " + name_txt.text + "\n")
            add_line &macro_script ("category:\"" + category_txt.text + "\"")
            add_line &macro_script ("tooltip:\"" + tooltip_txt.text + "\"")
            add_line &macro_script ("buttontext:\"" + button_text_txt.text + "\"")    
            if has_icon do (
                add_line &macro_script ("icon:#(\"" + name_txt.text + "\" ,1)")
            )  
            -- append extra script
            add_line &script_content ("\n" + extra_maxscript_txt.text)
            -- macro main script
            add_line &macro_script ("(\n" + script_content + ")")
            -- write macro script
            put_file_content macro_script (pathconfig.appendpath temp_folder "macro.mcr")
            

            -- create install.ms file
            -- add to toolbar code refenced from Titus[https://gumroad.com/l/B2MAX]
            add_line &install_script ("(
-- save ui first
local cui_file = cui.getConfigFile()
cui.saveConfigAs (if cui_file == undefined then (getdir #maxData + \"UI\Workspaces\usersave\Workspace__usersave__.cuix\") else cui_file)

filein \"macro.mcr\"

"+(if not has_icon_alpha then(
"local ico_16a = (pathconfig.appendpath (getdir #usericons) \""+name_txt.text+"_16a.bmp\")
local ico_24a = (pathconfig.appendpath (getdir #usericons) \""+name_txt.text+"_24a.bmp\")
if doesFileExist ico_16a do deletefile ico_16a
if doesFileExist ico_24a do deletefile ico_24a")
else "")+"

cui_file = cui.getconfigfile()

dotnet.loadassembly \"system.xml\"

local cui_xml = dotnetobject \"system.xml.xmldocument\"

cui_xml.load cui_file

local root_node = (cui_xml.selectnodes \"//ADSK_CUI/CUIWindows\").itemof[0]

local to_main_toolbar = "+ (if (finditem #("Main Toolbar","") setting_rl.toolbar_txt.text > 0) then "true" else "false")+"
local toolbar_node = undefined
local items_node = undefined
if to_main_toolbar then (
    toolbar_node = (cui_xml.selectnodes \"//ADSK_CUI/CUIWindows/Window[@objectName='Main Toolbar']\").itemof[0]
    items_node = toolbar_node.ChildNodes.itemof[0]
)
else (
    toolbar_node = cui_xml.createelement \"Window\"
    toolbar_node.setattribute \"objectName\" \"" + setting_rl.toolbar_txt.text + "\"
    toolbar_node.setattribute \"name\" \"" + setting_rl.toolbar_txt.text + "\"
    toolbar_node.setattribute \"type\" \"T\"
    toolbar_node.setattribute \"cType\" \"1\"
    toolbar_node.setattribute \"toolbarRows\" \"1\"
    root_node.appendChild toolbar_node
    items_node = cui_xml.createelement \"Items\"
    toolbar_node.appendChild items_node
)
local item_node = cui_xml.createelement \"Item\"
item_node.setattribute \"typeID\" \"2\"
item_node.setattribute \"type\" \"CTB_MACROBUTTON\"
item_node.setattribute \"width\" \""+((if has_icon then 0 else (button_text_txt.text.count*5 + 12)) as string)+"\"
item_node.setattribute \"height\" \"0\"
item_node.setattribute \"controlID\" \"0\"
item_node.setattribute \"macroTypeID\" \"3\"
item_node.setattribute \"macroType\" \"MB_TYPE_ACTION\"
item_node.setattribute \"actionTableID\" \"647394\"
item_node.setattribute \"imageID\" \"-1\" 
item_node.setattribute \"imageName\" \"\"
item_node.setattribute \"actionID\" \""+ name_txt.text + "`" + category_txt.text + "\"
items_node.appendChild item_node

cui_xml.save cui_file
cui.loadConfig cui_file
if to_main_toolbar do cui.showToolbar \"" + category_txt.text + "\"
colorMan.reinitIcons()
messagebox \"installed~\" beep:false
)
")
            -- write install.ms
            put_file_content install_script (pathconfig.appendpath temp_folder "install.ms")



            -- create mzp.run file
            add_line &mzp_run ("name \"" + name_txt.text + "\"")
            add_line &mzp_run ("version " + (if version_txt.text=="" then "1.0" else version_txt.text) )
            add_line &mzp_run "run \"install.ms\""
            add_line &mzp_run "drop \"install.ms\""
            if not mcr_only do (
                add_line &mzp_run ("copy \""+script_file_name+"\" to \"$userscripts\"")
            )
            if has_icon do add_line &mzp_run ("copy \"*.bmp\" to \"$usericons\"")
            add_line &mzp_run "clear temp"
            -- write mzp.run
            put_file_content mzp_run (pathconfig.appendpath temp_folder "mzp.run")



            -- create mzp package
            local mzp_file_name = getsavefilename caption:"save to:" filename:name_txt.text types:"mzp package(.mzp)|(*.mzp)"
            if mzp_file_name != undefined do (
                sysinfo.currentdir = temp_folder -- redirect currentdir, so when passing file array to maz function can use relative path
                local files_to_zip = #()
                for f in getfiles (pathconfig.appendpath temp_folder "*") do (
                    append files_to_zip (filenamefrompath f)
                )
                local mzp_file_path = mzp_file_name + (if (tolower (getfilenametype mzp_file_name) == ".mzp") then "" else ".mzp")
                local stat = maz mzp_file_path files_to_zip
                gc() -- use gc to release maz file handler


                if stat then (
                    local _qb = querybox "mzp packed~\nshow mzp installer in explorer?" beep:false
                    if _qb do (
                        shellLaunch "explorer"  ("/select,\"" + mzp_file_path + "\"")
                    )
                )
                else messagebox "writting mzp package file failed T_T\nplease check target path is writable"

                -- clean temp folder
                empty_folder temp_folder
            )
        )
    )

    on execute do (
        try (closerolloutfloater mzp_fl) catch()
        opened = false
        local mzp_fl = newrolloutfloater "mzp creator" 250 315
        addrollout setting_rl mzp_fl rolledup:on
        addrollout mzp_creator_rl mzp_fl
        opened = true
    )

)
