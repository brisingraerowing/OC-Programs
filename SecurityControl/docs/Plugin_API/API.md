## Required Functions

    * initialize(data:init_data):void - Called on program startup.
    * shutdown():void - Called on program shutdown.
    * getVersionInfo():version_info - Returns plugin version info

## Datatypes

    * init_data - Initialization Data
        * program_version:version_info - Program version info
        * config_path:string - Path to plugin config directory
    * version_info
        * major - Major version number
        * minor - Minor version number
        * patch - Patch version number
        * name - Plugin name
        * author - Plugin author
        * copyright - Plugin copyright
        * license - Plugin license