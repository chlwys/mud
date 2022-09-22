// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;
import "solecs/System.sol";
import { IWorld } from "solecs/interfaces/IWorld.sol";
import { IUint256Component } from "solecs/interfaces/IUint256Component.sol";
import { IComponent } from "solecs/interfaces/IComponent.sol";
import { getAddressById, addressToEntity } from "solecs/utils.sol";

import { PositionComponent, ID as PositionComponentID, Coord } from "../components/PositionComponent.sol";
import { CollectableComponent, ID as CollectableComponentID } from "../components/CollectableComponent.sol";

uint256 constant ID = uint256(keccak256("ember.system.spawnCoin"));

contract SpawnCoinSystem is System {
  uint256 public count = 1;

  constructor(IUint256Component _components, IWorld _world) System(_components, _world) {}

  function execute(bytes memory arguments) public returns (bytes memory) {
    Coord memory coords = abi.decode(arguments, (Coord));

    PositionComponent position = PositionComponent(getAddressById(components, PositionComponentID));
    CollectableComponent collectable = CollectableComponent(getAddressById(components, CollectableComponentID));

    collectable.set(count, 1);
    position.set(count, coords);

    count++;
  }

  function executeTyped(Coord memory coords) public returns (bytes memory) {
    return execute(abi.encode(coords));
  }
}
