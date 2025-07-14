import {HyperCoreWriterCaller} from "./utils/HyperCoreWriterCaller.sol";
import {GluexSettler} from "../../utils/GluexSettler.sol";

contract GluexHyperEVMToHyperCore is GluexSettler, HyperCoreWriterCaller {

    address immutable nativeToken;

    constructor(address _router, address _settlementTrigger, address _nativeToken) GluexSettler(_router, _settlementTrigger) {
        nativeToken = _nativeToken;
    }

    function executeStructuredSettlement(
        bytes calldata settlementParams
    ) external payable override {

        (bool success, ) = gluexRouter.call{value: 0}(settlementParams);
        require(success, "GlueX: router call failed");

        // TODO:
        // Add events to simplify GlueX integrators to track margins, types of settlements, and other relevant data
    }

    function executePostRouteCallback(
        bytes calldata data
    ) external payable override onlyGluexRouter {

        // Data must contain parameters to execute a transfer to hyperCore and a sendSpot call to CoreWriter 
        (address asset, address assetSystemAddress, uint256 amount, uint64 _tokenId, uint64 _amount, address _hyperCoreReceiver) = abi.decode(data, (address, uint256, uint64, uint16));
        
        // Determine the balance received from Router (including positive slippage and all fees) while handling native token transfer
        uint256 effectiveOutput = unibalanceof(asset, address(this));

        // Transfer to hyperCore
        if (address(asset) != nativeToken) {
            IERC20(asset).transfer(assetSystemAddress, effectiveOutput);
        } else {
            // If the asset is the native token, we use assembly to transfer it directly
            assembly {
                let success := call(gas(), assetSystemAddress, effectiveOutput, 0, 0, 0, 0)
                if iszero(success) {
                    revert(0, 0)
                }
            }  
        }

        // Transfer to effective receiver within HyperCore
        sendSpot(
            _hyperCoreReceiver,
            _tokenId,
            _amount
        );


        // TODO:
        // Add events to simplify GlueX integrators to track borrowed amounts and assets to render total positions to users

    }

    /**
     * @notice Retrieves the balance of a specified token for a given account.
     * @param token The ERC20 token to check.
     * @param account The account address to query the balance for.
     * @return The balance of the token for the account.
     */
    function uniBalanceOf(IERC20 token, address account)
        internal
        view
        returns (uint256)
    {
        if (address(token) == nativeToken) {
            uint256 contractBalance;
            assembly {
                contractBalance := balance(account)
            }
            return contractBalance;
        } else {
            return token.balanceOf(account);
        }
    }
}