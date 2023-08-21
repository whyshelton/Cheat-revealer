panorama = require('libs.panorama')

js = panorama.loadstring([[
    // @ the guy trying to see what panorama i got (again?), chill bruh
    let entity_panels = {}
    let entity_data = {}
    let event_callbacks = {}
        let SLOT_LAYOUT = `
            <root>
                <Panel style="min-width: 3px; padding-top: 2px; padding-left: 0px;" scaling='stretch-to-fit-y-preserve-aspect'>
                    <Image id="smaller" textureheight="15" style="horizontal-align: center; opacity: 0.01; transition: opacity 0.1s ease-in-out 0.0s, img-shadow 0.12s ease-in-out 0.0s; overflow: noclip; padding: 3px 5px; margin: -3px -5px;"	/>
                    <Image id="small" textureheight="17" style="horizontal-align: center; opacity: 0.01; transition: opacity 0.1s ease-in-out 0.0s, img-shadow 0.12s ease-in-out 0.0s; overflow: noclip; padding: 3px 5px; margin: -3px -5px;" />
                    <Image id="image" textureheight="21" style="opacity: 0.01; transition: opacity 0.1s ease-in-out 0.0s, img-shadow 0.12s ease-in-out 0.0s; padding: 3px 5px; margin: -3px -5px; margin-top: -5px;" />
                </Panel>
            </root>
        `
        let _DestroyEntityPanel = function (key) {
            let panel = entity_panels[key]
            if(panel != null && panel.IsValid()) {
                var parent = panel.GetParent()
                let musor = parent.GetChild(0)
                musor.visible = true
                if(parent.FindChildTraverse("id-sb-skillgroup-image") != null) {
                    parent.FindChildTraverse("id-sb-skillgroup-image").style.margin = "0px 0px 0px 0px"
                }
                panel.DeleteAsync(0.0)
            }
            delete entity_panels[key]
        }
        let _DestroyEntityPanels = function() {
            for(key in entity_panels){
                _DestroyEntityPanel(key)
            }
        }
        let _GetOrCreateCustomPanel = function(xuid) {
            if(entity_panels[xuid] == null || !entity_panels[xuid].IsValid()){
                entity_panels[xuid] = null
                let scoreboard_context_panel = $.GetContextPanel().FindChildTraverse("ScoreboardContainer").FindChildTraverse("Scoreboard") || $.GetContextPanel().FindChildTraverse("id-eom-scoreboard-container").FindChildTraverse("Scoreboard")
                if(scoreboard_context_panel == null){
                    _Clear()
                    _DestroyEntityPanels()
                    return
                }
                scoreboard_context_panel.FindChildrenWithClassTraverse("sb-row").forEach(function(el){
                    let scoreboard_el
                    if(el.m_xuid == xuid) {
                        el.Children().forEach(function(child_frame){
                            let stat = child_frame.GetAttributeString("data-stat", "")
                            if(stat == "rank")
                                scoreboard_el = child_frame.GetChild(0)
                        })
                        if(scoreboard_el) {
                            let scoreboard_el_parent = scoreboard_el.GetParent()
                            let custom_icons = $.CreatePanel("Panel", scoreboard_el_parent, "revealer-icon", {
                            })
                            if(scoreboard_el_parent.FindChildTraverse("id-sb-skillgroup-image") != null) {
                                scoreboard_el_parent.FindChildTraverse("id-sb-skillgroup-image").style.margin = "0px 0px 0px 0px"
                            }
                            scoreboard_el_parent.MoveChildAfter(custom_icons, scoreboard_el_parent.GetChild(1))
                            let prev_panel = scoreboard_el_parent.GetChild(0)
                            prev_panel.visible = false
                            let panel_slot_parent = $.CreatePanel("Panel", custom_icons, `icon`)
                            panel_slot_parent.visible = false
                            panel_slot_parent.BLoadLayoutFromString(SLOT_LAYOUT, false, false)
                            entity_panels[xuid] = custom_icons
                            return custom_icons
                        }
                    }
                })
            }
            return entity_panels[xuid]
        }
        let _UpdatePlayer = function(entindex, path_to_image) {
            if(entindex == null || entindex == 0)
                return
            entity_data[entindex] = {
                applied: false,
                image_path: path_to_image
            }
        }
        let _ApplyPlayer = function(entindex) {
            let xuid = GameStateAPI.GetPlayerXuidStringFromEntIndex(entindex)
            let panel = _GetOrCreateCustomPanel(xuid)
            if(panel == null)
                return
            let panel_slot_parent = panel.FindChild(`icon`)
            panel_slot_parent.visible = true
            let panel_slot = panel_slot_parent.FindChild("image")
            panel_slot.visible = true
            panel_slot.style.opacity = "1"
            panel_slot.SetImage(entity_data[entindex].image_path)
            return true
        }
        let _ApplyData = function() {
            for(entindex in entity_data) {
                entindex = parseInt(entindex)
                let xuid = GameStateAPI.GetPlayerXuidStringFromEntIndex(entindex)
                if(!entity_data[entindex].applied || entity_panels[xuid] == null || !entity_panels[xuid].IsValid()) {
                    if(_ApplyPlayer(entindex)) {
                        entity_data[entindex].applied = true
                    }
                }
            }
        }
        let _Create = function() {
            event_callbacks["OnOpenScoreboard"] = $.RegisterForUnhandledEvent("OnOpenScoreboard", _ApplyData)
            event_callbacks["Scoreboard_UpdateEverything"] = $.RegisterForUnhandledEvent("Scoreboard_UpdateEverything", function(){
                _ApplyData()
            })
            event_callbacks["Scoreboard_UpdateJob"] = $.RegisterForUnhandledEvent("Scoreboard_UpdateJob", _ApplyData)
        }
        let _Clear = function() { entity_data = {} }
        let _Destroy = function() {
            // clear entity data
            _Clear()
            _DestroyEntityPanels()
            for(event in event_callbacks){
                $.UnregisterForUnhandledEvent(event, event_callbacks[event])
                delete event_callbacks[event]
            }
        }
        return {
            create: _Create,
            destroy: _Destroy,
            clear: _Clear,
            update: _UpdatePlayer,
            destroy_panel: _DestroyEntityPanels
        }
]], "CSGOHud")()

js.create()

function on_detected_cheat(id, cheat) 
  a = 'file://{images}/icons/revealer/' .. tostring(cheat) .. '.png'

  js.update(id, a) 
end

function on_unload() 
  js.destroy()
end

client.set_event_callback('on_detected_cheat', on_detected_cheat)
client.set_event_callback('unload', on_unload)