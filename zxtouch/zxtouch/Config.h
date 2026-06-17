//
//  Config.h
//  zxtouch
//
//  Created by Jason on 2021/1/16.
//

#ifndef Config_h
#define Config_h

#define SCRIPTS_PATH @"/var/mobile/Library/ZXTouch/scripts/"
#define EXAMPLE_SCRIPTS_PATH @"/var/mobile/Library/ZXTouch/scripts/examples/"
#define SCRIPT_REGISTRY_PATH @"/var/mobile/Library/ZXTouch/config/tweak/script_registry.plist"
#define RUNTIME_OUTPUT_PATH @"/var/mobile/Library/ZXTouch/coreutils/ScriptRuntime/output"

#define SPRINGBOARD_CONFIG_PATH @"/var/mobile/Library/ZXTouch/config/tweak/config.plist"

#define SCRIPT_PLAY_CONFIG_PATH @"/var/mobile/Library/ZXTouch/config/tweak/script_play_settings.plist"

#define TOUCH_INDICATOR_DEFAULT_ALPHA 0.7

// Activator is not used in this rootless build; define path to avoid compile errors
#define ACTIVATOR_CONFIG_PATH @"/var/mobile/Library/ZXTouch/config/tweak/activator_config.plist"

#endif /* Config_h */
