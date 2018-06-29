## MiniMoos Sorter Plugins

### API

#### Required Methods

    * initialize(config) - Initializes the plugin. Passed the plugin_config data structure below.
    * shutdown() - Terminates the plugin
    * getPluginInfo() - Returns a table, defined as plugin_info in the Data Structures section

#### Data Structures

    * plugin_config
        * config - The plugin defined configuration values from the mmsort.d directory
        * methods - various utility methods
            * verifyCoreVersion(minver, maxver) - Verifies that the core version is between minver (inclusive) and maxver (exclusive)
            * getCoreVersion() - Gets the core version.
            * getFluidList() - Gets a list of all allowed fluids.
            * log(plugin_name, msg) - Logs a message to the log file.
    * plugin_info
        * version - The version of the plugin. Required.
        * name - The name of the plugin. Required.
        * author - The author of the plugin. Required.
        * license - The license of the plugin. Required.
        * copyright - The copyright statement of the plugin. Required.