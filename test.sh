#!/usr/bin/env bash

# zig test \
    #     ./src/lang/parser/ChainContext.zig \
    #     --pkg-begin \
    #     '@ioke/ioke_object' 'src/lang/IokeObject.zig' \
    #     --pkg-end \
    #     --pkg-begin \
    #     '@ioke/message' 'src/lang/Message.zig' \
    #     --pkg-end

zig test \
    ./src/lang/parser/IokeParser.zig \
    --pkg-begin \
    '@ioke/ioke_object' 'src/lang/IokeObject.zig' \
    --pkg-end \
    --pkg-begin \
    '@ioke/message' 'src/lang/Message.zig' \
    --pkg-end \
    --pkg-begin \
    '@ioke/runtime' 'src/lang/Runtime.zig' \
    --pkg-end
