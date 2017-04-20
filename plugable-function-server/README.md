# Plugable Function Server for OpenComputers

This is an extensible (plugable) server that provides functionality that is not or cannot be provided by the OpenComputers Minecraft mod. The server runs on a host computer and provides an API over a socket connection that allows calling methods and getting results from those methods. The core client library for an OC computer simply provides functions for calling methods on plugins (using the plugin and method names as strings) and getting a list of plugins and their methods. Higher level APIs should be built on top of this API for maximum future compatibility.

Two plugins are provided with the server. These are:

    * Compression Plugin - Compress and Decompress data with different methods
    * Regex Plugin - Various Regular Expression formats (PCRE, POSIX, GNU)