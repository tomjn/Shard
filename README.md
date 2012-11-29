# Shard

Shard is an engine agnostic RTS AI framework for games. Currently implementing the Spring RTS Engine. It provides a C++ API with wrappers for a writing AI code in a lua environment.

## Building For The Spring Engine

For *nix operating systems, clone into the AI directory giving a Shard folder alongside the other AIs, and build the engine as normal. Shard will be built along with the other AIs automatically if all is set up correctly.

For users of visual studio, a project is provided, but you will need a Spring Engine to test with, and source code with the appropriate libraries and wrappers required for general AI work. In particular you will need to acquire the C++ AI Wrappers which can be generated via the *nix build system.

## Writing AIs With Shard

If you have a prebuilt copy of Shard ( as comes with every install of the Spring Engine ), you don't need to build Shard to use it, you need only a text editor and knowledge of lua.