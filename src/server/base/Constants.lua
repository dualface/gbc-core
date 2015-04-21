
local Constants = {}

-- request type
Constants.HTTP_REQUEST_TYPE      = "http"
Constants.WEBSOCKET_REQUEST_TYPE = "websocket"
Constants.CLI_REQUEST_TYPE       = "cli"
Constants.WORKER_REQUEST_TYPE    = "worker"

-- action
Constants.ACTION_PACKAGE_NAME                   = 'actions'
Constants.DEFAULT_ACTION_MODULE_SUFFIX          = 'Action'
Constants.MESSAGE_FORMAT_JSON                   = "json"
Constants.MESSAGE_FORMAT_TEXT                   = "text"
Constants.DEFAULT_MESSAGE_FORMAT                = Constants.MESSAGE_FORMAT_JSON

-- redis keys
Constants.NEXT_CONNECT_ID_KEY                   = "_NEXT_CONNECT_ID"
Constants.CONNECT_CHANNEL_PREFIX                = "_C"

-- websocket
Constants.WEBSOCKET_TEXT_MESSAGE_TYPE           = "text"
Constants.WEBSOCKET_BINARY_MESSAGE_TYPE         = "binary"
Constants.WEBSOCKET_SUBPROTOCOL_PATTERN         = "quickserver%-([%w%d%-]+)"
Constants.WEBSOCKET_DEFAULT_TIME_OUT            = 10 * 1000 -- 10s
Constants.WEBSOCKET_DEFAULT_MAX_PAYLOAD_LEN     = 16 * 1024 -- 16KB
Constants.WEBSOCKET_DEFAULT_MAX_RETRY_COUNT     = 5 -- 5 times
Constants.WEBSOCKET_DEFAULT_MAX_SUB_RETRY_COUNT = 10 -- 10 times

return Constants
