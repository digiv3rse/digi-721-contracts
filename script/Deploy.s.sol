// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import {ERC721Drop} from "../src/ERC721Drop.sol";
import {ERC721DropProxy} from "../src/ERC721DropProxy.sol";
import {DiGiNFTCreatorV1} from "../src/DiGiNFTCreatorV1.sol";
import {DiGiNFTCreatorProxy} from "../src/DiGiNFTCreatorProxy.sol";
import {FactoryUpgradeGate} from "../src/FactoryUpgradeGate.sol";
import {DropMetadataRenderer} from "../src/metadata/DropMetadataRenderer.sol";
import {EditionMetadataRenderer} from "../src/metadata/EditionMetadataRenderer.sol";
import {IERC721Drop} from "../src//interfaces/IERC721Drop.sol";

import {DiGiDropsDeployBase} from "./DiGiDropsDeployBase.sol";
import {ChainConfig, DropDeployment} from '../src/DeploymentConfig.sol';

contract Deploy is DiGiDropsDeployBase {
    function run() public returns (string memory) {
        console2.log("Starting --- chainId", chainId());
        ChainConfig memory chainConfig = getChainConfig();
        console2.log(" --- chain config --- ");
        console2.log("Factory Owner", chainConfig.factoryOwner);
        console2.log("Fee Recipient", chainConfig.mintFeeRecipient);
        console2.log("Fee Amount", chainConfig.mintFeeAmount);

        console2.log("Setup contracts ---");

        address deployer = vm.envAddress("DEPLOYER");

        vm.startBroadcast(deployer);

        DropMetadataRenderer dropMetadata = new DropMetadataRenderer();
        EditionMetadataRenderer editionMetadata = new EditionMetadataRenderer();
        FactoryUpgradeGate factoryUpgradeGate = new FactoryUpgradeGate(chainConfig.factoryUpgradeGateOwner);

        ERC721Drop dropImplementation = new ERC721Drop({
            _zoraERC721TransferHelper: address(0x0),
            _factoryUpgradeGate: factoryUpgradeGate,
            _mintFeeAmount: chainConfig.mintFeeAmount,
            _mintFeeRecipient: payable(chainConfig.mintFeeRecipient),
            _protocolRewards: address(chainConfig.protocolRewards)
        });

        DiGiNFTCreatorV1 factoryImpl = new DiGiNFTCreatorV1(address(dropImplementation), editionMetadata, dropMetadata);

        // Sets owner as deployer - then the deployer address can transfer ownership
        DiGiNFTCreatorV1 factory = DiGiNFTCreatorV1(
            address(new DiGiNFTCreatorProxy(address(factoryImpl), abi.encodeWithSelector(DiGiNFTCreatorV1.initialize.selector)))
        );

        DiGiNFTCreatorV1(address(factory)).transferOwnership(chainConfig.factoryOwner);

        console2.log("Factory: ");
        console2.log(address(factory));

        deployTestContractForVerification(factory, deployer);

        vm.stopBroadcast();

        uint256 dropImplementationVersion = dropImplementation.contractVersion();

        return
            getDeploymentJSON(
                DropDeployment({
                    dropMetadata: address(dropMetadata),
                    editionMetadata: address(editionMetadata),
                    dropImplementation: address(dropImplementation),
                    dropImplementationVersion: dropImplementationVersion,
                    factoryUpgradeGate: address(factoryUpgradeGate),
                    factory: address(factory),
                    factoryImpl: address(factoryImpl)
                })
            );
    }
}
