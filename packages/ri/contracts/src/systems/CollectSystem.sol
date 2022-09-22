// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;
import "solecs/System.sol";
import { IWorld } from "solecs/interfaces/IWorld.sol";
import { IUint256Component } from "solecs/interfaces/IUint256Component.sol";
import { IComponent } from "solecs/interfaces/IComponent.sol";
import { getAddressById, addressToEntity } from "solecs/utils.sol";

import { PositionComponent, ID as PositionComponentID, Coord } from "../components/PositionComponent.sol";
import { CollectableComponent, ID as CollectableComponentID } from "../components/CollectableComponent.sol";
import { WalletComponent, ID as WalletComponentID } from "../components/WalletComponent.sol";

uint256 constant ID = uint256(keccak256("ember.system.collect"));

contract CollectSystem is System {
  constructor(IUint256Component _components, IWorld _world) System(_components, _world) {}

  function execute(bytes memory arguments) public returns (bytes memory) {
    uint256 entity = abi.decode(arguments, (uint256));

    PositionComponent position = PositionComponent(getAddressById(components, PositionComponentID));
    WalletComponent wallet = WalletComponent(getAddressById(components, WalletComponentID));

    // Sender must be on target position
    Coord memory senderPosition = position.getValue(entity);

    // Sender must have wallet
    //require(wallet.has(entity), "entity no wallet");
    uint256 currentBalance;
    if (wallet.has(entity)) {
      currentBalance = wallet.getValue(entity);
    }

    uint256[] memory entities = position.getEntitiesWithValue(senderPosition);
    require(entities.length > 0, "no entities at this position");

    CollectableComponent collectable = CollectableComponent(getAddressById(components, CollectableComponentID));

    // remove all collectables at position
    uint256 count;
    for (uint256 i; i < entities.length; i++) {
      if (collectable.has(entities[i])) {
        position.remove(entities[i]);
        count++;
      }
    }

    wallet.set(entity, currentBalance + count);
  }

  function executeTyped(uint256 entity) public returns (bytes memory) {
    return execute(abi.encode(entity));
  }
}
