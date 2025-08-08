// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {EthReceiver} from "./lib/EthReceiver.sol";
import {Interaction, RouteDescription, ShareCalculation, CallbackData} from "./base/DataTypes.sol";
import {IExecutor} from "./interfaces/IExecutor.sol";
import {IGluexSettler} from "./interfaces/IGluexSettler.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {SafeERC20} from "./lib/SafeERC20.sol";

/*
    * @title GlueX Protocol
    * @notice This contract implements GlueX Protocol's approach to "structured settlements".
    * The most simple structure settlement is a spot token swap. However, GlueX settlements are capable of 
    * embedding more complex logic into the settlement flow into so-called "structured settlement" via 
    * GluxSettlers that define the logic of a structured settlement and ensure they are safe to execute. 
    * A GluexSettlers can be unsafe if not implemented correctly. Please, restrain
    * from using GluexSettlers that have not been officially released by the GlueX team.
    * @dev The contract is designed to be used in conjunction with official GluexSettlers only.
*/
contract GluexProtocolSettlement is EthReceiver {
    using SafeERC20 for IERC20;

    // Errors
    error InsufficientBalance();
    error NativeTransferFailed();
    error OnlyGluexTreasury();
    error OnlyGluexSafe();
    error ZeroAddress();
    error NegativeSlippageLimit();
    error RoutingFeeTooHigh();
    error RoutingFeeTooLow();
    error PartnerSurplusShareTooHigh();
    error ProtocolSurplusShareTooLow();
    error PartnerSlippageShareTooHigh();
    error ProtocolSlippageShareTooLow();
    error InvalidSlippage();
    error SlippageLimitTooLarge();
    error InvalidNativeTokenInputAmount();
    error MaxFeeLimitExceeded();
    error MinFeeLimitExceeded();
    error MinFeeTooHigh();

    // Events
    /**
     * @notice Emitted when a routing operation is completed.
     * @param uniquePID The unique identifier for the partner.
     * @param userAddress The address of the user who initiated the route.
     * @param outputReceiver The address of the receiver of the output token.
     * @param inputToken The ERC20 token used as input.
     * @param inputAmount The amount of input token used for routing.
     * @param outputToken The ERC20 token received as output.
     * @param finalOutputAmount The actual output amount received after routing.
     * @param partnerFee The fee charged for the partner.
     * @param routingFee The fee charged for the routing operation.
     * @param partnerShare The share of surplus and slippage given to the partner.
     * @param protocolShare The share of surplus and slippage given to the GlueX protocol.
     */
    event Routed(
        bytes32 indexed uniquePID,
        address indexed userAddress,
        address outputReceiver,
        IERC20 inputToken,
        uint256 inputAmount,
        IERC20 outputToken,
        uint256 finalOutputAmount,
        uint256 partnerFee,
        uint256 routingFee,
        uint256 partnerShare,
        uint256 protocolShare
    );

    // Constants
    uint256 public _RAW_CALL_GAS_LIMIT = 5500;
    uint256 public _MAX_FEE = 15; // 15 bps (0.15%)
    uint256 public _MIN_FEE = 0; // 0 bps (0.00%)
    uint256 public _MAX_PARTNER_SURPLUS_SHARE_LIMIT = 5000; // 50% (5000 bps)
    uint256 public _MAX_PARTNER_SLIPPAGE_SHARE_LIMIT = 3300; // 33% (3300 bps)
    uint256 public _MIN_PROTOCOL_SURPLUS_SHARE_LIMIT = 5000; // 50% (5000 bps)
    uint256 public _MIN_PROTOCOL_SLIPPAGE_SHARE_LIMIT = 3000; // 30% (3000 bps)

    // State Variables
    address public immutable _nativeToken; // Address of the native token (e.g., Ether on Ethereum)
    address public immutable _gluexSafe; // Safe address for GlueX protocol
    address internal _gluexTreasury; // Address of the GlueX treasury contract

    /**
     * @dev Initializes the contract with the treasury address and native token address.
     * @param gluexSafe Safe address for GlueX protocol
     * @param gluexTreasury The address of the Glue treasury contract.
     * @param nativeToken The address of the native token.
     */
    constructor(address gluexSafe, address gluexTreasury, address nativeToken) {
        // Ensure the addresses are not zero
        checkZeroAddress(gluexSafe);
        checkZeroAddress(gluexTreasury);
        checkZeroAddress(nativeToken);

        _gluexSafe = gluexSafe;
        _gluexTreasury = gluexTreasury;
        _nativeToken = nativeToken;
    }

    /**
     * @dev Modifier to restrict access to treasury-only functions.
     */
    modifier onlyTreasury() {
        checkTreasury();
        _;
    }

    /**
     * @dev Modifier to restrict access to safe-only functions.
     */
    modifier onlySafe() {
        checkSafe();
        _;
    }

    /**
     * @notice Verifies the caller is the Glue treasury.
     * @dev Reverts with `OnlyGlueTreasury` if the caller is not the treasury.
     */
    function checkTreasury() internal view {
        if (msg.sender != _gluexTreasury) revert OnlyGluexTreasury();
    }

    /**
     * @notice Verifies the caller is the Glue treasury.
     * @dev Reverts with `OnlyGlueTreasury` if the caller is not the treasury.
     */
    function checkSafe() internal view {
        if (msg.sender != _gluexSafe) revert OnlyGluexSafe();
    }

    /**
     * @notice Verifies the given address is not zero.
     * @param addr The address to verify.
     * @dev Reverts with `ZeroAddress` if the address is zero.
     */
    function checkZeroAddress(address addr) internal pure {
        if (addr == address(0)) revert ZeroAddress();
    }

    /**
     * @notice Sets the GlueX treasury address.
     * @param gluexTreasury The new GlueX treasury address.
     * @dev Only callable by the GlueX safe.
     */
    function setGluexTreasury(address gluexTreasury) external onlySafe {
        // Ensure the new treasury address is valid
        checkZeroAddress(gluexTreasury);
        _gluexTreasury = gluexTreasury;
    }

    /**
     * @notice Executes a structured settlement using the provided callbacks, executor and interactions.
     * @notice This contract is not meant to hold fees under any circumstance. Any fees collected during the 
     * settlement should be transferred to the GlueX and partner treasuries directly.
     * @param preRouteCallbackParams The parameters for the pre-route callback, including value and data.
     * @param executor The executor contract that performs the interactions.
     * @param desc The route description containing input, output, and fee details.
     * @param interactions The interactions encoded for execution by the executor.
     * @param postRouteCallbackParams The parameters for the post-route callback, including value and data.
     * @return finalOutputAmount The final amount of output token received.
     * @dev Ensures strict validation of slippage, routing fees, and input/output parameters.
    */
    function settle(
        CallbackData calldata preRouteCallbackParams,
        IExecutor executor,
        RouteDescription calldata desc,
        Interaction[] calldata interactions,
        CallbackData calldata postRouteCallbackParams
    ) external payable returns (uint256 finalOutputAmount) {
        
        // Execute pre-route callback
        if (preRouteCallbackParams.data.length != 0) {
            IGluexSettler(msg.sender).executePreRouteCallback{value: preRouteCallbackParams.value}(preRouteCallbackParams.data);
        }

        // Validate the route description
        validateSwap(desc);

        // Token transfer
        if (address(desc.inputToken) == _nativeToken) {
            if (msg.value != desc.inputAmount) revert InvalidNativeTokenInputAmount();
        } else {
            if (msg.value != 0) revert InvalidNativeTokenInputAmount();
            desc.inputToken.safeTransferFromUniversal(
                msg.sender,
                desc.inputReceiver,
                desc.inputAmount,
                desc.isPermit2
            );
        }

        // Execute the interactions using executor
        finalOutputAmount = executeInteractions(desc, executor, interactions);

        // Calculate final output amount
        uint256 partnerFee = desc.partnerFee;
        uint256 routingFee = 0;
        if (finalOutputAmount > desc.effectiveOutputAmount + desc.routingFee) {
            finalOutputAmount = finalOutputAmount - desc.routingFee;
            routingFee = desc.routingFee;
        } else if (finalOutputAmount > desc.effectiveOutputAmount) {
            routingFee = finalOutputAmount - desc.effectiveOutputAmount;
            finalOutputAmount = desc.effectiveOutputAmount;
        } else {
            finalOutputAmount = finalOutputAmount;
        }

        // Surplus and Slippage calculation
        uint256 surplus = 0;
        uint256 slippage = 0;
        if (finalOutputAmount >= desc.outputAmount && desc.outputAmount >= desc.effectiveOutputAmount) {
            surplus = desc.outputAmount - desc.effectiveOutputAmount;
            slippage = finalOutputAmount - desc.outputAmount;
        } else if (desc.outputAmount > finalOutputAmount && finalOutputAmount > desc.effectiveOutputAmount) {
            surplus = finalOutputAmount - desc.effectiveOutputAmount;
            slippage = 0;
        } else {
            surplus = 0;
            slippage = 0;
        }

        uint256 partnerShare = 0;
        uint256 protocolShare = 0;
        if (surplus != 0 || slippage != 0) {
            // Calculate and transfer partner surplus
            uint256 partnerSurplus = (surplus * desc.partnerSurplusShare) / 10000;
            uint256 partnerSlippage = (slippage * desc.partnerSlippageShare) / 10000;
            partnerShare = partnerSurplus + partnerSlippage;

            // Calculate and transfer routing surplus
            uint256 protocolSurplus = surplus - partnerSurplus;
            uint256 protocolSlippage = (slippage * desc.protocolSlippageShare) / 10000;
            protocolShare = protocolSurplus + protocolSlippage;

            finalOutputAmount -= (partnerShare + protocolShare);

            if (partnerShare != 0) {
                if (desc.partnerAddress != address(0)) {
                    uniTransfer(
                        desc.outputToken,
                        desc.partnerAddress,
                        partnerShare
                    );
                } else {
                    protocolShare += partnerShare; // If no partner address, add to protocol share
                }
            }

            uniTransfer(
                desc.outputToken,
                payable(_gluexTreasury),
                protocolShare
            );
        }

        // Ensure final output amount meets the minimum required
        if (finalOutputAmount < desc.minOutputAmount) revert NegativeSlippageLimit();

        // Transfer the final output amount to the output receiver
        uniTransfer(
            desc.outputToken,
            desc.outputReceiver,
            finalOutputAmount
        );

        emit Routed(
            desc.uniquePID,
            tx.origin,
            desc.outputReceiver,
            desc.inputToken,
            desc.inputAmount,
            desc.outputToken,
            finalOutputAmount,
            partnerFee,
            routingFee,
            partnerShare,
            protocolShare
        );

        // Execute post-hook callback
        if (postRouteCallbackParams.data.length != 0) {
            IGluexSettler(msg.sender).executePostRouteCallback{value: postRouteCallbackParams.value}(postRouteCallbackParams.data);
        }
    }

    /**
     * @notice Validates the parameters of a swap operation.
     * @param desc The route description containing swap details.
     * @dev Ensures that routing fees, partner surplus shares, and slippage limits are within acceptable ranges.
     */
    function validateSwap(
        RouteDescription calldata desc
    ) internal view {
        // Validate routing fee
        if (desc.routingFee > (desc.outputAmount * _MAX_FEE) / 10000) revert RoutingFeeTooHigh();
        if (desc.routingFee < (desc.outputAmount * _MIN_FEE) / 10000) revert RoutingFeeTooLow();

        // Validate surplus sharing
        if (desc.partnerSurplusShare > _MAX_PARTNER_SURPLUS_SHARE_LIMIT) revert PartnerSurplusShareTooHigh();
        if (desc.protocolSurplusShare < _MIN_PROTOCOL_SURPLUS_SHARE_LIMIT) revert ProtocolSurplusShareTooLow();

        // Validate slippage sharing
        if (desc.partnerSlippageShare > _MAX_PARTNER_SLIPPAGE_SHARE_LIMIT) revert PartnerSlippageShareTooHigh();
        if (desc.protocolSlippageShare < _MIN_PROTOCOL_SLIPPAGE_SHARE_LIMIT) revert ProtocolSlippageShareTooLow();

        // Validate non-zero addresses
        checkZeroAddress(desc.inputReceiver);
        checkZeroAddress(desc.outputReceiver);

        // Validate route parameters
        if (desc.minOutputAmount > desc.outputAmount) revert SlippageLimitTooLarge();
    }

    /**
     * @notice Executes the interactions defined in the route description using the specified executor.
     * @param desc The route description containing input, output, and interaction details.
     * @param executor The executor contract that will perform the interactions.
     * @param interactions The interactions to be executed.
     * @return finalOutputAmount The final amount of output token received after executing the interactions.
     */
    function executeInteractions(
        RouteDescription calldata desc,
        IExecutor executor,
        Interaction[] calldata interactions
    ) internal returns (uint256 finalOutputAmount) {

        // Execute interactions through the executor
        IERC20 outputToken = desc.outputToken;
        uint256 outputBalanceBefore = uniBalanceOf(outputToken, address(this));

        executor.executeRoute{value: msg.value}(
                interactions,
                desc.outputToken
            );

        uint256 outputBalanceAfter = uniBalanceOf(outputToken, address(this));

        finalOutputAmount = outputBalanceAfter - outputBalanceBefore;
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
        if (address(token) == _nativeToken) {
            uint256 contractBalance;
            assembly {
                contractBalance := balance(account)
            }
            return contractBalance;
        } else {
            return token.balanceOf(account);
        }
    }

    /**
     * @notice Transfers a specified amount of a token to a given address.
     * @param token The ERC20 token to transfer.
     * @param to The address to transfer the token to.
     * @param amount The amount of the token to transfer.
     * @dev Handles both native token and ERC20 transfers.
     */
    function uniTransfer(
        IERC20 token,
        address payable to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (address(token) == _nativeToken) {
                uint256 contractBalance;
                assembly {
                    contractBalance := selfbalance()
                }
                if (contractBalance < amount) revert InsufficientBalance();
                (bool success, ) = to.call{
                    value: amount,
                    gas: _RAW_CALL_GAS_LIMIT
                }("");
                if (!success) revert NativeTransferFailed();
            } else {
                token.safeTransfer(to, amount);
            }
        } else {
            revert InsufficientBalance();
        }
    }

    /**
     * @notice Updates the gas limit for raw calls made by the contract.
     * @param gasLimit The new gas limit to be set.
     * @dev This function is restricted to the treasury.
     */
    function setGasLimit(uint256 gasLimit) external onlyTreasury {
        _RAW_CALL_GAS_LIMIT = gasLimit;
    }

    /**
     * @notice Updates the maximum fee that can be charged by the contract.
     * @param maxFee The new maximum fee to be set.
     * @dev This function is restricted to the treasury.
     */
    function setMaxFee(uint256 maxFee) external onlyTreasury {
        if (maxFee > 10000) revert MaxFeeLimitExceeded();
        _MAX_FEE = maxFee;
    }

    /**
     * @notice Updates the minimum fee that can be charged by the contract.
     * @param minFee The new minimum fee to be set.
     * @dev This function is restricted to the treasury.
     */
    function setMinFee(uint256 minFee) external onlyTreasury {
        if (minFee > 10000) revert MinFeeLimitExceeded();
        if (minFee > _MAX_FEE) revert MinFeeTooHigh();
        _MIN_FEE = minFee;
    }

    /**
     * @notice Updates the partner surplus share limit.
     * @param partnerSurplusShareLimit The new limit for partner surplus share.
     * @dev This function is restricted to the treasury.
     */
    function setPartnerSurplusShareLimit(uint256 partnerSurplusShareLimit)
        external
        onlyTreasury
    {
        _MAX_PARTNER_SURPLUS_SHARE_LIMIT = partnerSurplusShareLimit;
    }

    /**
     * @notice Updates the partner slippage share limit.
     * @param partnerSlippageShareLimit The new limit for partner slippage share.
     * @dev This function is restricted to the treasury.
     */
    function setPartnerSlippageShareLimit(uint256 partnerSlippageShareLimit)
        external
        onlyTreasury
    {        
        _MAX_PARTNER_SLIPPAGE_SHARE_LIMIT = partnerSlippageShareLimit;
    }
}