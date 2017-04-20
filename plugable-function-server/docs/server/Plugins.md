# Plugable Function Server for OpenComputers - Plugins Reference

# TOC

    * [Section 1 - Implementation Details](#sec1)
        * [Section 1.1 - Required Functions](#sec11)
        * [Section 1.2 - Optional Functions](#sec12)
        * [Section 1.3 - Data Structures](#sec13)
            * [Section 1.3.1 - Plugin Method Information Table](#sec131)
        * [Section 1.4 - Versions](#sec14)

## <a name="sec1"></a>Section 1 - Implementation Details

### <a name="sec11"></a>Section 1.1 - Required Functions

    * initialize() - Initializes the plugin.
    * getName():string - Gets the name of the plugin.
    * getApiVersion():number - Gets the required API version of the plugin.
    * getVersion():string - Gets the version of the plugin.
    * executeMethod(method_name: string, ...) - Executes a plugin method.
    * getMethods():table - Gets a table of method information. See Section 1.3 for details.
    * shutdown() - Shuts down the plugin.

### <a name="sec12"></a>Section 1.2 - Optional Functions

Reserved for future use.

### <a name="sec13"></a>Section 1.3 - Data Structures

#### <a name="sec131"></a>Section 1.3.1 - Plugin Method Information Table

The Plugin Method Information Table (returned by the getMethods function) is a list of tables with the following structure:
    
    * name:string - The name of the method.
    * doc:string - A brief description of the method.
    * numArgs:number - A number specifying the number of required arguments.
    * optArgs:number - A number specifying the number of optional arguments.
    * arguments:table - A list of tables specifying the arguments to the method.
        * type:string - The type of the argument.
        * index:number - The index of the argument.
        * doc:string - A brief description of the argument.
        * optional:boolean - Whether the argument is optional.