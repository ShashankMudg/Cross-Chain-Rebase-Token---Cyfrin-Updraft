// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {CCIPLocalSimulatorFork, Register} from "../lib/chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol";
import {Rebase_Token} from "../src/Rebase_Token.sol";
import {RebaseTokenPool} from "../src/RebaseTokenPool.sol";
import {vault} from "../src/vault.sol";
import {RegistryModuleOwnerCustom} from "../lib/ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {TokenAdminRegistry} from "../lib/ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";
import {TokenPool} from "../lib/ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {RateLimiter} from "../lib/ccip/contracts/src/v0.8/ccip/libraries/RateLimiter.sol";
//import {Router} from "../lib/ccip/contracts/src/v0.8/ccip/Router.sol";


import {IERC20} from "../lib/ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

import {IRebase_Token} from "../src/interfaces/IRebase_Token.sol";

contract CrossChainRebase is Test {
    address owner = makeAddr("owner");
    // forks
    uint sepoliafork;
    uint arbsepoliafork;
    //simulator

    CCIPLocalSimulatorFork simulatorfork;

    //erc20 tokens
    Rebase_Token sepolia_token;
    Rebase_Token arbsepolia_token;

    //vault
    vault Vault;

    //pool contracts 
    RebaseTokenPool sepolia_pool;
    RebaseTokenPool arbsepolia_pool;

    //network details
    Register.NetworkDetails sepolia_network_details;
    Register.NetworkDetails arbsepolia_network_details;

    function setUp() public {
        sepoliafork = vm.createSelectFork("sepolia-eth");
        arbsepoliafork = vm.createFork("arbitrum-sepolia");


        simulatorfork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(simulatorfork));

        //sepolia
        vm.startPrank(owner);
        sepolia_token = new Rebase_Token();
        Vault = new vault(IRebase_Token(address(sepolia_token)));
        sepolia_network_details = simulatorfork.getNetworkDetails(block.chainid); 

        //constructor(IERC20 token, address[] memory allowlist, address rmnProxy, address router)
        sepolia_pool = new RebaseTokenPool(IERC20(address(sepolia_token)),new address[] (0), sepolia_network_details.rmnProxyAddress,sepolia_network_details.routerAddress);
        RegistryModuleOwnerCustom(sepolia_network_details.registryModuleOwnerCustomAddress).registerAdminViaOwner(address(sepolia_token));
        TokenAdminRegistry(sepolia_network_details.tokenAdminRegistryAddress).acceptAdminRole(address(sepolia_token));
        TokenAdminRegistry(arbsepolia_network_details.tokenAdminRegistryAddress).setPool(address(sepolia_token), address(sepolia_pool));
        configPools(sepoliafork,address(sepolia_pool),sepolia_network_details.chainSelector,address(arbsepolia_pool),address(arbsepolia_token));
        vm.stopPrank();

/////////////////////////////////////////////////Arbitrum sepolia/////////////////////////////////////////////////
        //arbitrum sepolia
        vm.selectFork(arbsepoliafork);
        vm.startPrank(owner);
        arbsepolia_token = new Rebase_Token();
        Vault = new vault(IRebase_Token(address(arbsepolia_token)));
        arbsepolia_network_details = simulatorfork.getNetworkDetails(block.chainid); 
        arbsepolia_pool = new RebaseTokenPool(IERC20(address(arbsepolia_token)),new address[] (0), arbsepolia_network_details.rmnProxyAddress,arbsepolia_network_details.routerAddress);
        RegistryModuleOwnerCustom(arbsepolia_network_details.registryModuleOwnerCustomAddress).registerAdminViaOwner(address(arbsepolia_token));
        TokenAdminRegistry(arbsepolia_network_details.tokenAdminRegistryAddress).acceptAdminRole(address(arbsepolia_token));
        TokenAdminRegistry(arbsepolia_network_details.tokenAdminRegistryAddress).setPool(address(arbsepolia_token), address(arbsepolia_pool));
        
        configPools(arbsepoliafork,address(arbsepolia_pool),arbsepolia_network_details.chainSelector,address(sepolia_pool),address(sepolia_token));
        
        vm.stopPrank();
        //deploy the vault contract for the sepolia and arbitrum sepolia
    }

    function configPools(uint fork,address pool, uint64 chainId, address remotePool, address remoteToken) public {
        vm.selectFork(fork);
        vm.prank(owner);

        TokenPool.ChainUpdate[] memory chainUpdates = new TokenPool.ChainUpdate[](1);
        

        chainUpdates[0] = TokenPool.ChainUpdate({
            remoteChainSelector: chainId,
            allowed: true,
            remotePoolAddress: abi.encode(remotePool),
            remoteTokenAddress: abi.encode(remoteToken),
            outboundRateLimiterConfig: RateLimiter.Config({isEnabled: false, capacity: 0, rate: 0}),
            inboundRateLimiterConfig: RateLimiter.Config({isEnabled: false, capacity: 0, rate: 0})
        });


        TokenPool(pool).applyChainUpdates(chainUpdates);
    
    
    }

//     struct ChainUpdate {
//     uint64 remoteChainSelector; // ──╮ Remote chain selector
//     bool allowed; // ────────────────╯ Whether the chain should be enabled
//     bytes remotePoolAddress; //        Address of the remote pool, ABI encoded in the case of a remote EVM chain.
//     bytes remoteTokenAddress; //       Address of the remote token, ABI encoded in the case of a remote EVM chain.
//     RateLimiter.Config outboundRateLimiterConfig; // Outbound rate limited config, meaning the rate limits for all of the onRamps for the given chain
//     RateLimiter.Config inboundRateLimiterConfig; // Inbound rate limited config, meaning the rate limits for all of the offRamps for the given chain
//   }

// struct Config {
//     bool isEnabled; // Indication whether the rate limiting should be enabled
//     uint128 capacity; // ────╮ Specifies the capacity of the rate limiter
//     uint128 rate; //  ───────╯ Specifies the rate of the rate limiter
//   }


// chainUpdates[0].remoteChainSelector = chainId;
        // chainUpdates[0].allowed = true;
        // chainUpdates[0].remotePoolAddress = abi.encode(pool);
        // chainUpdates[0].remoteTokenAddress = abi.encode(remoteToken);
        // chainUpdates[0].outboundRateLimiterConfig = RateLimiter.Config({
        //     isEnabled: true,
        //     capacity: 0, 
        //     rate: 0
        // });
        // chainUpdates[0].inboundRateLimiterConfig = RateLimiter.Config({
        //    isEnabled: true,
        //    capacity: 0, 
        //    rate: 0
        // });



    // function config pools
}