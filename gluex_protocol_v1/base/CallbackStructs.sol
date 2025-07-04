/**
     * @dev A generic structure defining the parameters for a callback.
     */
    struct CallbackData {
        bytes data; // Encoded data for the callback hook
        uint256 value; // Value to be sent with the callback, if applicable
    }
